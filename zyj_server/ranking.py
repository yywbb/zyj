"""真实本地排行榜及有界首期活动；历史只来自启用后原子保存的成绩。"""

import copy
import json
from pathlib import Path

from . import formation, magic, mieshendian, player, recharge, recruit, storage
from .protocol import encode_pb_field, get_comb_messages, iter_pb_fields, pb_get_varint, pb_set_field, pb_set_varint


EVENTS = {1: (11, "toplevel"), 2: (104, "combat_rank"), 5: (126, "wing_rank"),
          6: (124, "copy_rank"), 7: (125, "mozhao_rank"), 18: (128, "friend_rank"),
          11: (106, "combat_grow"), 12: (105, "sigil_rank"), 13: (114, "combat_grow_x1"),
          14: (115, "combat_grow_x2"), 15: (127, "soul_rank"), 16: (123, "artifact_rank"),
          17: (129, "localTrump_rank")}


def parameters(values):
    return b"".join(encode_pb_field(1, 2, encode_pb_field(1, 0, value)) for value in values)


def temple_query(body, saves, viewer, config):
    if body:
        raise ValueError("灭神殿排行榜不接受参数")
    rows = []
    for account, snapshot in saves.items():
        save = copy.deepcopy(snapshot)
        temple = mieshendian.get_state(save, config)
        if not temple["maxfloor"]:
            continue
        state = player.get_role_state(save, config)
        role = bytes.fromhex(save["role_snapshot"])
        rid = pb_get_varint(role, 1) if account == viewer else 1000000 + account
        if not rid or not 0 < rid < (1 << 31):
            raise ValueError("灭神殿排行榜角色编号无效")
        raw = (encode_pb_field(1, 0, rid) + encode_pb_field(2, 2, save["role_name"].encode("utf-8"))
               + b"".join(encode_pb_field(n, 0, v) for n, v in ((3, state["level"]), (4, state["vip"]), (5, state["profile"]), (7, state["power"])))
               + encode_pb_field(8, 2, parameters([0, 0, pb_get_varint(role, 23) or 35001, pb_get_varint(role, 24) or 35501, temple["maxfloor"]])))
        rows.append((-temple["maxfloor"], -temple["maxstar"], account, raw))
    return b"".join(encode_pb_field(1, 2, row[3]) for row in sorted(rows))


def artifact(save, config):
    records = []
    for n, w, raw in iter_pb_fields(bytes.fromhex(save["world_state"]["1002"])):
        if (n, w) != (16, 2):
            continue
        params = [v for f, t, v in iter_pb_fields(raw) if (f, t) == (1, 2)]
        if len(params) < 29 or str(pb_get_varint(params[1], 1)) not in config["trump"]:
            raise ValueError("神器存档缺少有效属性或配置")
        iid, score = pb_get_varint(params[0], 1), pb_get_varint(params[28], 1)
        if not iid or type(score) is not int or not 0 <= score < (1 << 31):
            raise ValueError("神器编号或积分无效")
        records.append((score, -iid, raw))
    return max(records)[2] if records else b""


def query(body, saves, viewer, config, state=None, opcode=3500):
    fields = list(iter_pb_fields(body))
    if (len(fields) not in (3, 4) or any(n != 1 or w != 0 or not 0 <= v < (1 << 31) for n, w, v in fields)
            or any(v == 0 for _, _, v in fields[1:])):
        raise ValueError("排行榜需要类型、起始名次和数量")
    method, start, count = [v for _, _, v in fields[:3]]
    if start > 1000 or count > 1000:
        raise ValueError("排行榜类型或分页范围暂不支持")
    if len(fields) == 4:
        if method not in EVENTS or EVENTS[method][0] != fields[3][2] or state is None:
            raise ValueError("活动榜类型与活动编号不符")
        rows = event_rows(state, method, opcode == 3503)
        return b"".join(encode_pb_field(1, 2, event_player(row, viewer, method)) for row in rows[start - 1:start - 1 + count])
    if opcode == 3503 or method not in (0, 1, 2, 5, 6, 7, 8, 19):
        raise ValueError("历史榜需要明确的活动编号")
    # shortcut: 翅膀/面具尚无本地成长记录，保持空榜；实现对应系统时再接入真实数值。
    if method in (5, 7):
        return b""
    rows = []
    for account, save in saves.items():
        state = player.get_role_state(save, config)
        role = bytes.fromhex(save.get("role_snapshot", ""))
        params = [0, 0, pb_get_varint(role, 23) or 35001, pb_get_varint(role, 24) or 35501]
        score, secondary = state["power"], state["level"]
        params_raw = b""
        if method == 0:
            params_raw = artifact(save, config)
            if not params_raw:
                continue
            values = [v for n, w, v in iter_pb_fields(params_raw) if (n, w) == (1, 2)]
            score = pb_get_varint(values[28], 1)
        elif method == 1:
            score, secondary = state["level"], state["power"]
        elif method == 6:
            copies = bytes.fromhex(save["world_state"]["1300"])
            score = sum(pb_get_varint(point, 3) or 0 for n, w, copy in iter_pb_fields(copies) if (n, w) == (1, 2)
                        for f, t, point in iter_pb_fields(copy) if (f, t) == (7, 2))
            params.append(score)
        elif method == 8:
            generals = formation.records(bytes.fromhex(save["world_state"]["1002"]), 1, 2)
            if not generals:
                continue
            general = max(generals.values(), key=lambda raw: (pb_get_varint(raw, 20) or 0, -(pb_get_varint(raw, 2) or 0)))
            score = pb_get_varint(general, 20) or 0
            params.extend((pb_get_varint(general, 1), pb_get_varint(general, 2), score))
        elif method == 19:
            score = state["g_power"]
        # shortcut: 旧本地角色共用录制 RID；本人保留原 RID，其他账号用隔离编号，接入跨角色交互时统一迁移。
        rid = pb_get_varint(role, 1) if account == viewer else 1000000 + account
        if not rid or not 0 < rid < (1 << 31):
            raise ValueError("排行榜角色编号无效")
        raw = (encode_pb_field(1, 0, rid) + encode_pb_field(2, 2, save["role_name"].encode("utf-8"))
               + b"".join(encode_pb_field(n, 0, v) for n, v in
                          ((3, state["level"]), (4, state["vip"]), (5, state["profile"]),
                           (7, state["g_power"] if method == 19 else state["power"])))
               + encode_pb_field(8, 2, parameters(params) + params_raw))
        rows.append((-score, -secondary, account, raw))
    return b"".join(encode_pb_field(1, 2, row[3]) for row in sorted(rows)[start - 1:start - 1 + count])


def entry(account, save, config, previous=None):
    state = player.get_role_state(save, config)
    role = bytes.fromhex(save.get("role_snapshot", ""))
    world = bytes.fromhex(save["world_state"]["1002"])
    general = max(formation.records(world, 1, 2).values(), key=lambda raw: pb_get_varint(raw, 20) or 0, default=b"")
    copies = bytes.fromhex(save["world_state"]["1300"])
    stars = sum(pb_get_varint(point, 3) or 0 for n, w, raw in iter_pb_fields(copies) if (n, w) == (1, 2)
                for f, t, point in iter_pb_fields(raw) if (f, t) == (7, 2))
    souls = sum(pb_get_varint(raw, 3) or 0 for raw in formation.records(world, 3, 1).values()
                if pb_get_varint(raw, 2) != 70000)
    sigils = 0
    for raw in formation.records(world, 7, 1).values():
        values = [v for n, w, v in iter_pb_fields(raw) if (n, w) == (1, 0)]
        row = config["sigil"][str(values[1])]
        sigils += sum(int(row[f"init{i}"] / (10 if row[f"attr{i}"] == "hp" else 1)) for i in range(1, 5)
                      if row[f"attr{i}"] in ("atk", "def", "hp", "speed"))
    best = artifact(save, config)
    params = [v for n, w, v in iter_pb_fields(best) if (n, w) == (1, 2)]
    score = pb_get_varint(params[28], 1) if params else 0
    identity = save["created_at"]
    baseline = previous["baseline"] if previous and previous["identity"] == identity else state["power"]
    growth = max(0, state["power"] - baseline)
    if previous and previous["identity"] == identity:
        growth = max(growth, previous["scores"]["11"])
    scores = {1: state["level"], 2: state["power"], 5: 0, 6: stars, 7: 0, 18: pb_get_varint(general, 20) or 0,
              11: growth, 12: sigils, 13: growth, 14: growth, 15: souls, 16: magic.rank_score(save, config), 17: score}
    if any(type(value) is not int or not 0 <= value < (1 << 31) for value in scores.values()):
        raise ValueError("本地榜单成绩超出范围")
    return {"account": account, "identity": identity, "baseline": baseline, "name": save["role_name"],
            "rid": pb_get_varint(role, 1), "level": state["level"], "power": state["power"], "vip": state["vip"],
            "profile": state["profile"], "icon": pb_get_varint(role, 23) or 35001, "title": pb_get_varint(role, 24) or 35501,
            "general": [pb_get_varint(general, 1) or 0, pb_get_varint(general, 2) or 0, scores[18]],
            "artifact_cid": pb_get_varint(params[1], 1) if params else 0,
            "scores": {str(k): v for k, v in scores.items()}}


def end_at(state, method, config):
    days = config["activity_time"][str(EVENTS[method][0])]["continued_time"]
    return (((state["opened_at"] + 28800) // 86400) + days) * 86400 - 28800


def event_rows(state, method, historical=False):
    if historical or str(method) in state["closed"]:
        return state["closed"].get(str(method), [])
    rows = [row for row in state["players"].values() if row["scores"][str(method)] > 0]
    return sorted(rows, key=lambda row: (-row["scores"][str(method)], -row["power"], row["account"]))


def observe(path, saves, config, now, previous=None):
    path = Path(path)
    if not path.exists() and any(save.get("rank_mail_state") for save in saves.values()):
        raise ValueError("本地榜单记录丢失，请恢复 rankings.json 备份，不能重建期次")
    try:
        state = json.loads(path.read_bytes()) if path.exists() else {"opened_at": now, "checked_at": now, "players": {}, "closed": {}}
        if (not isinstance(state, dict) or set(state) != {"opened_at", "checked_at", "players", "closed"}
                or any(type(state[k]) is not int or state[k] < 0 for k in ("opened_at", "checked_at"))
                or not isinstance(state["players"], dict) or not isinstance(state["closed"], dict)
                or not set(state["closed"]) <= {str(mid) for mid in EVENTS}):
            raise ValueError
        for row in [*state["players"].values(), *(row for rows in state["closed"].values() for row in rows)]:
            if (type(row["account"]) is not int or not 1 <= row["account"] <= 1000
                    or not isinstance(row["name"], str) or not isinstance(row["identity"], (int, float))
                    or any(type(row[k]) is not int or not 0 <= row[k] < (1 << 31)
                           for k in ("baseline", "rid", "level", "power", "vip", "profile", "icon", "title", "artifact_cid"))
                    or set(row["scores"]) != {str(mid) for mid in EVENTS}
                    or any(type(v) is not int or not 0 <= v < (1 << 31) for v in row["scores"].values())):
                raise ValueError
    except (ValueError, TypeError, KeyError, UnicodeError):
        raise ValueError("本地榜单记录损坏，请保留原文件并恢复备份") from None
    before = copy.deepcopy(state)
    for mid in EVENTS:
        if now >= end_at(state, mid, config) and str(mid) not in state["closed"]:
            state["closed"][str(mid)] = copy.deepcopy(event_rows(state, mid))
    if now >= state["checked_at"]:
        for account, save in saves.items():
            key = str(account)
            old = state["players"].get(key)
            if old is None and previous and account in previous and previous[account].get("role_snapshot"):
                old = entry(account, previous[account], config)
            state["players"][key] = entry(account, save, config, old)
        state["players"] = {str(account): state["players"][str(account)] for account in saves}
        state["checked_at"] = now
    if not path.exists() or state != before:
        storage.atomic_write(path, json.dumps(state, ensure_ascii=False).encode("utf-8"))
    return state


def event_player(row, viewer, method):
    score = row["scores"][str(method)]
    extra = row["general"] if method == 18 else [row["artifact_cid"], score] if method == 17 else [score, 0]
    rid = row["rid"] if row["account"] == viewer else 1000000 + row["account"]
    return (b"".join(encode_pb_field(n, 0, v) for n, v in
                    ((1, rid), (3, row["level"]), (4, row["vip"]), (5, row["profile"]), (7, score)))
            + encode_pb_field(2, 2, row["name"].encode("utf-8"))
            + encode_pb_field(8, 2, parameters([0, 0, row["icon"], row["title"], *extra])))


def summary(body, state, viewer):
    fields = list(iter_pb_fields(body))
    if len(fields) != 2 or any((n, w) != (1, 0) for n, w, _ in fields):
        raise ValueError("活动榜需要类型与当前/历史选项")
    method, mode = [v for _, _, v in fields]
    if method not in EVENTS or mode not in (1, 2):
        raise ValueError("活动榜类型或选项无效")
    rows = event_rows(state, method, mode == 2)
    my = next((row for row in rows if row["account"] == viewer), None)
    rank = next((i for i, row in enumerate(rows, 1) if row["account"] == viewer), 0)
    values = [(row["scores"][str(method)], row["name"]) for row in rows[:3]]
    values.append((my["scores"][str(method)] if my else 0, str(rank)))
    params = b""
    for score, name in values:
        params += encode_pb_field(1, 2, encode_pb_field(1, 0, score) + encode_pb_field(2, 2, name.encode("utf-8")))
        if method == 5:
            params += parameters([0])
    baseline = state["players"].get(str(viewer), {}).get("baseline", 0)
    return b"".join(encode_pb_field(1, 2, encode_pb_field(1, 0, mid) + encode_pb_field(2, 2, raw))
                    for mid, raw in ((1, params), (2, recharge.ids([baseline]))))


def rewrite_activities(body, state, config, now):
    groups = dict(get_comb_messages(body))
    raw = groups.get(1, b"")
    for mid, (activity, _) in EVENTS.items():
        row = next((v for n, w, v in iter_pb_fields(raw) if (n, w) == (1, 2) and pb_get_varint(v, 1) == activity), b"")
        row = pb_set_varint(pb_set_varint(row, 1, activity), 2, 1)
        raw = player.merge_pb_records(raw, encode_pb_field(1, 2, row), {1: 1})
    groups[1] = raw
    values = recharge.ids([v for activity in EVENTS.values() for v in
                           (activity[0], 1, max(1, (max(now, state["checked_at"]) + 28800) // 86400 - (state["opened_at"] + 28800) // 86400 + 1))])
    if 2 in groups:
        fields = list(iter_pb_fields(groups[2]))
        old = [v for n, w, v in fields if (n, w) == (1, 0)]
        if len(old) % 3:
            raise ValueError("活动期次列表缺少完整的三值组")
        controlled = {v[0] for v in EVENTS.values()}
        groups[2] = (recharge.ids([v for i in range(0, len(old), 3) if old[i] not in controlled for v in old[i:i + 3]]) + values
                     + b"".join(encode_pb_field(n, w, v) for n, w, v in fields if (n, w) != (1, 0)))
    else:
        groups[2] = values
    groups[5601] = recharge.ids([state["opened_at"]])
    out, written = bytearray(), set()
    for n, w, value in iter_pb_fields(body):
        if (n, w) == (1, 2):
            mid = pb_get_varint(value, 1)
            if mid in groups:
                value = pb_set_field(value, 2, 2, groups[mid])
                written.add(mid)
        out.extend(encode_pb_field(n, w, value))
    for mid, raw in groups.items():
        if mid not in written:
            out.extend(encode_pb_field(1, 2, encode_pb_field(1, 0, mid) + encode_pb_field(2, 2, raw)))
    return bytes(out)


def reward_mails(state, viewer, identity, config):
    mails = {}
    for key, rows in state["closed"].items():
        method = int(key)
        rank = next((i for i, row in enumerate(rows, 1) if row["account"] == viewer and row["identity"] == identity), 0)
        table = config[EVENTS[method][1]]
        bucket = next((i for i in sorted(map(int, table)) if i >= rank), None) if rank else None
        if bucket is None:
            continue
        row = table[str(bucket)]
        gets = [(row[f"propsid{i}"], row[f"nmb{i}"]) for i in range(1, 5) if row[f"propsid{i}"] and row[f"nmb{i}"]]
        name = config["activity_time"][str(EVENTS[method][0])]["name"]
        mails[700000000 + method] = {"gets": gets, "title": "本地" + name + "奖励",
                                   "content": f"本地首期{name}已结算，您获得第{rank}名。附件按配置发放，仅可领取一次。",
                                   "second": end_at(state, method, config)}
    return mails


def prepare_mail(opcode, save, body, state, viewer, config):
    claims = save.setdefault("rank_mail_state", {"period": state["opened_at"], "claimed": [], "deleted": []})
    if (not isinstance(claims, dict) or claims.get("period") != state["opened_at"]
            or any(not isinstance(claims.get(k), list) or len(claims[k]) != len(set(claims[k]))
                   or any(type(v) is not int or v - 700000000 not in EVENTS for v in claims[k]) for k in ("claimed", "deleted"))
            or not set(claims["deleted"]) <= set(claims["claimed"])):
        raise ValueError("本地排名邮件领取记录无效")
    mails = {mid: row for mid, row in reward_mails(state, viewer, save["created_at"], config).items() if mid not in claims["deleted"]}
    if opcode == 3100:
        if body:
            raise ValueError("邮件查询不接受参数")
        result = b""
        for mid, row in sorted(mails.items()):
            raw = b"".join(encode_pb_field(n, 0, v) for n, v in
                           ((1, mid), (2, 0), (3, 0), (4, 2 if mid in claims["claimed"] else 0), (8, row["second"])))
            attachment = {}
            for cid, num in row["gets"]:
                attachment[str(cid)] = attachment.get(str(cid), 0) + num
            for field, text in ((5, row["title"]), (6, row["content"]), (7, json.dumps(attachment))):
                raw += encode_pb_field(field, 2, text.encode("utf-8"))
            result += encode_pb_field(2, 2, raw)
        return result, b""
    fields = list(iter_pb_fields(body))
    if not fields or len(fields) > len(EVENTS) or any((n, w) != (1, 0) for n, w, _ in fields):
        raise ValueError("邮件操作需要有效的邮件编号")
    ids = [v for _, _, v in fields]
    if ids == [(1 << 64) - 1]:
        ids = [mid for mid in mails if (mid in claims["claimed"]) == (opcode == 3102)]
    if not ids or len(ids) != len(set(ids)) or any(mid not in mails for mid in ids):
        raise ValueError("没有可处理的本地排名邮件")
    if opcode == 3102:
        if any(mid not in claims["claimed"] for mid in ids):
            raise ValueError("请先领取附件，不能删除未领取奖励")
        claims["deleted"].extend(ids)
        return b"\x08\x01", b""
    if any(mid in claims["claimed"] for mid in ids):
        raise ValueError("邮件奖励已领取")
    reward = recruit.build_reward(save, [get for mid in ids for get in mails[mid]["gets"]], config)
    claims["claimed"].extend(ids)
    return reward, reward
