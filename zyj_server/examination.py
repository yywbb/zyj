"""三界联考：原题库、服务端计时与真实本地排名，公开记录用角色收据发布。"""

import copy
from fractions import Fraction
import json
import random
import re
import secrets

from . import friends, guild, storage
from .guild_games import integer, pairs, param
from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint, pb_set_field, pb_set_varint

QUERIES = (7002, 7005)
MUTATIONS = (7003, 7004)
OPCODES = QUERIES + MUTATIONS
RANK_COUNTERS = ("question_week_one", "question_monthtop50", "question_month_three", "question_month_two", "question_month_one")


def window(kind, now, opened_day, config):
    row = config["sanjie_answer"][str(kind)]
    day = (now + 28800) // 86400
    if kind == 2:
        day -= ((day + 3) % 7 - 5) % 7
    elif kind == 3:
        first = opened_day + 9
        first += (6 - (first + 3) % 7) % 7
        day = first + max(0, (day - first) // row["days"]) * row["days"]
    times = [tuple(map(int, row[key].strip(";").split(","))) for key in ("time_open", "time_close")]
    start, end = (day * 86400 - 28800 + h * 3600 + m * 60 + s for h, m, s in times)
    return start, end + int(kind == 1)


def opened_day(save):
    stamp = pb_get_varint(bytes.fromhex(save.get("role_snapshot", "")), 22)
    stamp = int(save["created_at"]) if stamp is None else stamp
    return (stamp + 28800) // 86400


def score(kind, elapsed, config):
    row = config["sanjie_answer"][str(kind)]
    seconds = Fraction(elapsed, 1000)
    return max(0, int((Fraction(str(row["parameter_a"])) * seconds ** 2
                      + Fraction(str(row["parameter_b"])) * seconds + Fraction(str(row["parameter_c"]))) * 10))


def get_state(save, config):
    state = save.get("examination_state", {"records": {}, "checked_at": 0, "receipt": "", "claimed": [], "deleted": []})
    try:
        integer(state["checked_at"])
        if not isinstance(state["records"], dict) or not set(state["records"]) <= {"1", "2", "3"}:
            raise ValueError
        if not isinstance(state["receipt"], str) or state["receipt"] and not re.fullmatch(r"[a-f0-9]{32}", state["receipt"]):
            raise ValueError
        for name in ("claimed", "deleted"):
            values = state[name]
            if not isinstance(values, list) or len(set(values)) != len(values):
                raise ValueError
            for mid in values:
                integer(mid, 500000001, 599999999)
        if not set(state["deleted"]) <= set(state["claimed"]):
            raise ValueError
        for kind, row in state["records"].items():
            cfg = config["sanjie_answer"][kind]
            for key in ("start", "end", "issued", "deadline", "level"):
                integer(row[key])
            if row["end"] <= row["start"] or row["issued"] and not row["start"] * 1000 <= row["issued"] < row["deadline"] <= row["end"] * 1000:
                raise ValueError
            ids, answers = row["ids"], row["answers"]
            if (not isinstance(ids, list) or len(ids) != cfg["num"] or len(set(ids)) != len(ids)
                    or any(type(cid) is not int or str(cid) not in config["sanjie_subject_config"]
                           or kind not in config["sanjie_subject_config"][str(cid)]["type"].split(";") for cid in ids)
                    or not isinstance(answers, list) or len(answers) > len(ids) or str(row["level"]) not in config["role_exp"]):
                raise ValueError
            for cid, answer in zip(ids, answers):
                if not isinstance(answer, list) or len(answer) != 6:
                    raise ValueError
                for value in answer:
                    integer(value, high=(1 << 31) - 1)
                subject = config["sanjie_subject_config"][str(cid)]
                if answer[0] not in [subject[f"answer{i}"] for i in range(1, 5)] or answer[1] > cfg["answer_time"] * 1000:
                    raise ValueError
                right = int(answer[0] == subject["answer1"] and answer[1] < cfg["answer_time"] * 1000)
                if answer[2] != right or answer[3] != (score(int(kind), answer[1], config) if right else 0):
                    raise ValueError
    except (KeyError, TypeError, ValueError, AttributeError):
        raise ValueError("联考答题、时钟或邮件存档无效") from None
    return state


def totals(row, count=None):
    answers = row["answers"][:count]
    return [sum(a[i] for a in answers) for i in (5, 4, 1, 3, 2)]


def query(save, config, now, opened=None):
    state = get_state(save, config)
    values = []
    for kind in (1, 2, 3):
        start, end = window(kind, now, opened_day(save) if opened is None else opened, config)
        row = state["records"].get(str(kind))
        active = start <= now < end and save.get("has_role") and save.get("role_state", {}).get("level", 1) >= config["build"]["468"]["level"]
        if not row or row["start"] != start:
            status = int(bool(active))
            entrance = config["sanjie_answer"][str(kind)]["entrance_time"]
            if entrance and save.get("has_role") and save.get("role_state", {}).get("level", 1) >= config["build"]["468"]["level"]:
                h, m, s = map(int, entrance.strip(";").split(","))
                day_start = ((start + 28800) // 86400) * 86400 - 28800
                if day_start + h * 3600 + m * 60 + s <= now < start:
                    status = 4
            values.extend([kind, status, 0, 0, 0, 0, 0, end])
        else:
            done = len(row["answers"])
            complete = done == len(row["ids"]) or now >= end
            _, _, elapsed, points, right = totals(row)
            values.extend([kind, 3 if complete else 2, min(done + 1, len(row["ids"])), right,
                           0 if complete else row["ids"][done], elapsed, points, end])
    return guild.ids(values)


def rank_rows(period):
    return sorted(((int(a), row) for a, row in period["players"].items() if period["kind"] == 2 or row["points"]),
                  key=lambda item: (-item[1]["points"], -Fraction(item[1]["right"], item[1]["count"] or 1), item[1]["elapsed"], item[0]))


def validate(state, config):
    try:
        if set(state) != {"version", "opened_day", "checked_at", "next_mail", "periods", "mails", "pending"} or type(state["version"]) is not int or state["version"] != 1:
            raise ValueError
        for key in ("opened_day", "checked_at"):
            integer(state[key])
        integer(state["next_mail"], 500000001, 600000000)
        if not isinstance(state["periods"], dict) or not isinstance(state["mails"], dict):
            raise ValueError
        for key, row in state["periods"].items():
            integer(row["kind"], 2, 3)
            for field in ("start", "end"):
                integer(row[field])
            if key != f'{row["kind"]}:{row["start"]}' or row["start"] >= row["end"] or type(row["frozen"]) is not bool:
                raise ValueError
            if window(row["kind"], row["start"], state["opened_day"], config) != (row["start"], row["end"]):
                raise ValueError
            if not isinstance(row["players"], dict) or len(row["players"]) > 1000:
                raise ValueError
            for account, entry in row["players"].items():
                friends.account_id(account)
                friends.identity(entry["identity"])
                for field in ("points", "right", "elapsed", "count"):
                    integer(entry[field], high=(1 << 31) - 1)
                if entry["right"] > entry["count"] or entry["points"] > entry["right"] * 100 or entry["count"] > config["sanjie_answer"][str(row["kind"])]["num"]:
                    raise ValueError
                if pb_get_varint(bytes.fromhex(entry["profile"]), 1) != int(account) + 1000000:
                    raise ValueError
        for mid, row in state["mails"].items():
            integer(int(mid), 500000001, state["next_mail"] - 1)
            integer(row["account"], 1, 1000)
            friends.identity(row["identity"])
            integer(row["second"])
            if mid != str(int(mid)) or not pairs(row["reward"]) or not isinstance(row["title"], str) or not isinstance(row["content"], str):
                raise ValueError
        pending = state["pending"]
        if pending is not None:
            integer(pending["account"], 1, 1000)
            friends.identity(pending["identity"])
            if not re.fullmatch(r"[a-f0-9]{32}", pending["token"]) or pending["after"]["pending"] is not None:
                raise ValueError
            validate(pending["after"], config)
    except (ValueError, KeyError, TypeError, AttributeError):
        raise ValueError("联考公开记录损坏，请恢复examinations.json与角色配套备份") from None


def load(path, saves, config, now):
    # shortcut: 完整保留历届排名用于邮件及成就；历史文件过大时需成组归档并保留终身名次计数。
    if path.exists():
        try:
            state = json.loads(path.read_bytes())
        except (ValueError, UnicodeError):
            raise ValueError("联考公开记录损坏，不能重新发奖") from None
    else:
        if any(save.get("examination_state") for save in saves.values()):
            raise ValueError("联考公开记录丢失，请恢复examinations.json")
        state = {"version": 1, "opened_day": min([opened_day(s) for s in saves.values()] or [(now + 28800) // 86400]),
                 "checked_at": now, "next_mail": 500000001, "periods": {}, "mails": {}, "pending": None}
    validate(state, config)
    return state


def write(path, state, config):
    validate(state, config)
    storage.atomic_write(path, json.dumps(state, ensure_ascii=False, allow_nan=False).encode())


def recover(state, saves, config):
    pending = state["pending"]
    if pending:
        save = saves.get(pending["account"], {})
        if save.get("created_at") == pending["identity"] and get_state(save, config)["receipt"] == pending["token"]:
            after = pending["after"]
            state.clear()
            state.update(after)
        state["pending"] = None
    for account, save in saves.items():
        if save.get("examination_state"):
            for mid in get_state(save, config)["claimed"]:
                entry = state["mails"].get(str(mid), {})
                if entry.get("account") != account or entry.get("identity") != save["created_at"]:
                    raise ValueError("联考邮件与角色身份不一致，请恢复配套备份")


def stage(state, before, account, save):
    token = secrets.token_hex(16)
    after = copy.deepcopy(state)
    state.clear()
    state.update(copy.deepcopy(before))
    state["pending"] = {"account": account, "identity": save["created_at"], "token": token, "after": after}
    save["examination_state"]["receipt"] = token


def settle(state, config, now):
    for period in state["periods"].values():
        if period["frozen"] or now < period["end"]:
            continue
        rows = config["sanjie_reward" if period["kind"] == 2 else "span_sanjie_reward"]
        for rank, (account, entry) in enumerate(rank_rows(period), 1):
            brackets = [r for r in sorted(rows.values(), key=lambda r: r["rank"]) if rank <= r["rank"]]
            reward = (brackets[0] if brackets else rows["0"])["reward"]
            if state["next_mail"] >= 600000000:
                raise ValueError("联考邮件编号已用尽，请维护归档")
            state["mails"][str(state["next_mail"])] = {"account": account, "identity": entry["identity"], "reward": reward,
                "title": "本地三界联考排名奖励", "content": f'{"周试" if period["kind"] == 2 else "月试"}，实际排名{rank}。', "second": period["end"]}
            state["next_mail"] += 1
        period["frozen"] = True


def reward_mails(state, viewer, identity):
    return {int(mid): {"title": row["title"], "content": row["content"], "second": row["second"], "gets": list(pairs(row["reward"]).items())}
            for mid, row in state["mails"].items() if row["account"] == viewer and row["identity"] == identity}


def rank_counts(state, viewer, identity):
    counts = dict.fromkeys(RANK_COUNTERS, 0)
    for period in state["periods"].values():
        if not period["frozen"]:
            continue
        for rank, (account, entry) in enumerate(rank_rows(period), 1):
            if account == viewer and entry["identity"] == identity:
                if period["kind"] == 2:
                    counts["question_week_one"] += int(rank == 1)
                else:
                    counts["question_monthtop50"] += int(rank <= 50)
                    for position, name in ((1, "one"), (2, "two"), (3, "three")):
                        counts["question_month_" + name] += int(rank == position)
    return counts


def question_reward(kind, level, right, config):
    rows = config["sanjie_answer_reward"][str(kind)].values()
    selected = max((row for row in rows if row["level"] <= level), key=lambda r: r["level"])
    result = pairs(selected["answer_reward" if right else "wrong_reward"])
    if set(result) != {1000, 1017}:
        raise ValueError("联考答题奖励配置无效")
    return result[1000], result[1017]


def prepare(opcode, body, state, save, account, config, now_ms, seed):
    from . import achievements, development
    now = now_ms // 1000
    values = development.ids(body)
    own = get_state(save, config)
    if opcode == 7002:
        if values:
            raise ValueError("联考状态查询不接受参数")
        return query(save, config, now, state["opened_day"]), 0, 0
    if not save.get("has_role") or save["role_state"]["level"] < config["build"]["468"]["level"]:
        raise ValueError("三界联考尚未解锁")
    if len(values) != (4 if opcode == 7004 else 1) or values[0] not in ((2, 3) if opcode == 7005 else (1, 2, 3)):
        raise ValueError("联考类型、题目或答案参数无效")
    kind = values[0]
    start, end = window(kind, now, state["opened_day"], config)
    key = f"{kind}:{start}"
    if opcode == 7005:
        periods = [p for p in state["periods"].values() if p["kind"] == kind]
        period = max(periods, key=lambda p: p["start"]) if periods else {"kind": kind, "players": {}}
        rows, my_score = [], 0
        for rank, (member, row) in enumerate(rank_rows(period), 1):
            profile = bytes.fromhex(row["profile"])
            if member == account and row["identity"] == save["created_at"]:
                profile = pb_set_varint(profile, 1, pb_get_varint(bytes.fromhex(save["role_snapshot"]), 1))
                my_score = row["points"]
            metadata = next(raw for n, w, raw in iter_pb_fields(profile) if (n, w) == (8, 2))
            prefix = [pb_get_varint(v, 1) or 0 for n, w, v in iter_pb_fields(metadata) if (n, w) == (1, 2)][:4]
            profile = pb_set_field(profile, 8, 2, param(prefix + [row["points"], row["right"], row["elapsed"], rank]))
            rows.append(encode_pb_field(1, 2, profile))
        # 原生窗口把最后一行固定解释为本人积分，不是参赛者。
        rows.append(encode_pb_field(1, 2, encode_pb_field(8, 2, param([0, 0, 35001, 35501, my_score]))))
        return b"".join(rows), 0, 0
    if now_ms < own["checked_at"] or now < state["checked_at"]:
        raise ValueError("联考时钟发生回拨，请稍后重试")
    if not start <= now < end:
        raise ValueError("不在本次联考答题时间内")
    cfg = config["sanjie_answer"][str(kind)]
    row = own["records"].get(str(kind))
    if not row or row["start"] != start:
        if opcode != 7003:
            raise ValueError("请先开始本次考试")
        eligible = sorted(int(cid) for cid, r in config["sanjie_subject_config"].items() if str(kind) in r["type"].split(";"))
        row = {"start": start, "end": end, "ids": random.Random(seed).sample(eligible, cfg["num"]), "answers": [],
               "issued": 0, "deadline": 0, "level": save["role_state"]["level"]}
        own["records"][str(kind)] = row
        if kind in (2, 3):
            achievements.record(save, "question_weekcount" if kind == 2 else "question_monthcount", 1, config)
    coin, exp = 0, 0
    done = len(row["answers"])
    if opcode == 7003:
        if done == len(row["ids"]):
            raise ValueError("本次联考已经完成")
        if not row["issued"]:
            row.update(issued=now_ms, deadline=min(end * 1000, now_ms + cfg["answer_time"] * 1000), level=save["role_state"]["level"])
        xp, silver, elapsed, points, right = totals(row)
        reply = guild.ids([row["ids"][done], row["deadline"], xp, silver, elapsed, points, done + 1, right])
    else:
        _, cid, answer, _client_time = values
        if cid not in row["ids"]:
            raise ValueError("题目不属于本次考试")
        index = row["ids"].index(cid)
        if index < done:
            previous = row["answers"][index]
            if previous[0] != answer:
                raise ValueError("该题已经提交，不能改答案")
            xp, silver, elapsed, points, right = totals(row, index + 1)
            return guild.ids([previous[2], xp, silver, elapsed, points, index + 1, right]), 0, 0
        subject = config["sanjie_subject_config"][str(cid)]
        if index != done or not row["issued"] or answer not in [subject[f"answer{i}"] for i in range(1, 5)]:
            raise ValueError("题目尚未下发、顺序错误或答案无效")
        elapsed = min(now_ms - row["issued"], cfg["answer_time"] * 1000) if now_ms < row["deadline"] else cfg["answer_time"] * 1000
        right = int(answer == subject["answer1"] and now_ms < row["deadline"])
        coin, exp = question_reward(kind, row["level"], right, config)
        row["answers"].append([answer, elapsed, right, score(kind, elapsed, config) if right else 0, coin, exp])
        row.update(issued=0, deadline=0)
        xp, silver, elapsed, points, correct = totals(row)
        done += 1
        reply = guild.ids([right, xp, silver, elapsed, points, done, correct])
        if kind == 1 and done == len(row["ids"]) and correct == done:
            achievements.record(save, "question_fullmarks", 1, config)
    own["checked_at"] = now_ms
    save["examination_state"] = own
    if kind in (2, 3):
        period = state["periods"].setdefault(key, {"kind": kind, "start": start, "end": end, "frozen": False, "players": {}})
        _, _, elapsed, points, right = totals(row)
        profile = friends.player_body(account, 0, {account: save})
        period["players"][str(account)] = {"identity": save["created_at"], "points": points, "right": right,
            "elapsed": elapsed, "count": len(row["answers"]), "profile": profile.hex()}
    return reply, coin, exp
