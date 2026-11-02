"""守卫：目标、时限、连击与分数均由服务器保存，拒绝上传总分。"""

import copy
import random
import secrets

OPCODES = tuple(range(5150, 5157))
MUTATIONS = (5151, 5152, 5153, 5154, 5156)


def get_state(save, now):
    from .guild_games import integer

    state = save.setdefault("guild_guard", {"day": (now + 28800) // 86400, "high": 0, "total": 0, "used": 0, "claimed": [], "run": None})
    state.setdefault("serial", 0)
    for key in ("day", "high", "total", "used", "serial"):
        integer(state[key], high=(1 << 31) - 1)
    if (not isinstance(state["claimed"], list) or any(type(v) is not int or v not in range(1, 6) for v in state["claimed"])
            or len(set(state["claimed"])) != len(state["claimed"])):
        raise ValueError("守卫宝箱存档无效")
    run = state["run"]
    if run is not None:
        for key in ("score", "combo", "hp", "next_at", "end"):
            integer(run[key])
        if (not isinstance(run["targets"], dict) or len(run["targets"]) > 9 or not isinstance(run["boxes"], list)
                or len(run["boxes"]) > 4 or any(type(v) is not int or v not in range(1, 5) for v in run["boxes"])):
            raise ValueError("守卫对局无效")
        for pos, target in run["targets"].items():
            if pos not in tuple(map(str, range(1, 10))):
                raise ValueError("守卫位置无效")
            integer(target["kind"], 1, 4)
            integer(target["until"])
            integer(target["token"], 1)
    if (now + 28800) // 86400 > state["day"]:
        state.update(day=(now + 28800) // 86400, total=0, used=0, claimed=[], run=None)
    return state


def prepare(opcode, body, row, save, saves, viewer, config, now, stamp):
    from . import guild
    from .guild_games import award, integer, pairs, public_player

    state = get_state(save, now)
    day = (now + 28800) // 86400
    scores = row.setdefault("guard_scores", {})
    pending = row.setdefault("guard_pending", {})
    for date, entries in list(scores.items()):
        if int(date) < day:
            entries = sorted(((a, s) for a, s in entries.items() if s["score"] > 0), key=lambda item: (-item[1]["score"], int(item[0])))
            for rank, (a, record) in enumerate(entries, 1):
                if row["members"].get(a, {}).get("identity") != record["identity"]:
                    continue
                setting = next((r for r in sorted(config["guild_rank"].values(), key=lambda r: r["rank"]) if rank <= r["rank"]), None)
                if setting:
                    prize = pending.setdefault(a, {"identity": record["identity"], "items": {}})
                    if prize["identity"] != record["identity"]:
                        prize.update(identity=record["identity"], items={})
                    for cid, count in pairs(setting["reward"]).items():
                        prize["items"][str(cid)] = prize["items"].get(str(cid), 0) + count
            del scores[date]
    automatic = b""
    if opcode == 5150 and str(viewer) in pending:
        entry = pending.pop(str(viewer))
        if entry["identity"] == save["created_at"]:
            automatic = award(save, row, {int(cid): n for cid, n in entry["items"].items()}, config, now)
    if opcode == 5150:
        guild.request_ids(body, 0)
        return guild.ids([state["high"], state["total"], state["used"], guild.progress(row, config)[0],
            *[2 if i in state["claimed"] else int(state["total"] >= config["guild_box"][str(i)]["files"]) for i in range(1, 6)], int(state["run"] is not None)]), [], automatic
    if opcode == 5155:
        kind, = guild.request_ids(body, 1)
        if kind not in (0, 1):
            raise ValueError("守卫榜单类型无效")
        entries = [(int(a), get_state(copy.deepcopy(saves[int(a)]), now)) for a in (row["members"] if kind == 0 else saves)]
        key = "high" if kind == 0 else "total"
        entries.sort(key=lambda item: (-item[1][key], item[0]))
        return b"".join(public_player(a, viewer, saves, s[key]) for a, s in entries) + public_player(viewer, viewer, saves, state[key]), [], b""
    if opcode == 5154:
        index, = guild.request_ids(body, 1)
        box = config["guild_box"].get(str(index))
        if not box or index in state["claimed"] or state["total"] < box["files"]:
            raise ValueError("守卫宝箱未达标或已领取")
        reward = award(save, row, pairs(box["box"]), config, now)
        state["claimed"].append(index)
        return reward, [], reward
    if opcode == 5151:
        method, = guild.request_ids(body, 1)
        if method not in (0, 1) or guild.progress(row, config)[0] < int(config["global_kv"]["guide_open"]["value"]):
            raise ValueError("守卫尚未解锁或开始参数无效")
        if not config["guild_time"][str((state["day"] + 3) % 7 + 1)]["open"]:
            raise ValueError("守卫每周二、四、六开放")
        if state["run"] is not None:
            raise ValueError("请先结束当前守卫对局")
        cost = []
        if state["used"] >= config["gang2_level"][str(guild.progress(row, config)[0])]["topy"]:
            raise ValueError("今日守卫次数已用完")
        if method == 1 and not config["vip"][str(save["role_state"]["vip"])]["guild_start"]:
            cost = list(pairs(config["global_kv"]["guide_consume"]["value"]).items())
        state["used"] += 1
        state["run"] = {"score": state["high"] if method else 0, "combo": 0, "hp": int(config["global_kv"]["guild_box_life"]["value"]),
                        "next_at": stamp, "end": stamp + 180000, "targets": {}, "boxes": []}
        return guild.ids([0, state["run"]["score"]]), cost, b""
    run = state["run"]
    if run is None:
        raise ValueError("请先开始守卫")
    for pos, target in list(run["targets"].items()):
        if stamp > target["until"]:
            if target["kind"] == 1:
                run["hp"] = max(0, run["hp"] - 1)
                run["combo"] = 0
            del run["targets"][pos]
    if opcode == 5156:
        guild.request_ids(body, 0)
        previous = state["high"]
        state["high"] = max(state["high"], run["score"])
        state["total"] += run["score"]
        scores.setdefault(str(day), {})[str(viewer)] = {"identity": save["created_at"], "score": state["total"]}
        gets = {}
        for box in run["boxes"]:
            for cid, count in pairs(config["guild_box_total"][str(box)]["type"]).items():
                gets[cid] = gets.get(cid, 0) + count
        reward = award(save, row, gets, config, now)
        state["run"] = None
        return guild.message(0, guild.ids([int(run["score"] > previous), run["score"], *run["boxes"]])) + guild.message(1, reward), [], reward
    if opcode == 5152:
        guild.request_ids(body, 0)
        if stamp >= run["end"] or not run["hp"]:
            return guild.ids([3, 0]), [], b""
        if stamp < run["next_at"]:
            return guild.ids([0, 0]), [], b""
        setting = next(r for r in config["guild_play"].values() if r["lower"] <= run["score"] <= r["upper"])
        rng = random.Random(secrets.randbits(64))
        positions = [i for i in range(1, 10) if str(i) not in run["targets"]]
        chosen = rng.sample(positions, min(setting["blame"], len(positions)))
        state["serial"] = integer(state["serial"] + 1, 1, (1 << 31) - 1)
        targets = []
        for pos in chosen:
            weights = [setting[f"devil{i}"] if i != 4 or len(run["boxes"]) < 4 else 0 for i in range(1, 5)]
            kind = rng.choices(range(1, 5), weights)[0]
            run["targets"][str(pos)] = {"kind": kind, "until": stamp + int(setting["speed"]) * 10 + 500, "token": state["serial"]}
            targets.extend([pos, kind, state["serial"]])
        run["next_at"] = stamp + int(setting["interval"]) * 10
        return guild.ids([0, len(chosen), *targets]), [], b""
    pos, hit, token = guild.request_ids(body, 3)
    if pos not in range(1, 10) or hit not in (0, 1):
        raise ValueError("守卫命中参数无效")
    target = run["targets"].get(str(pos))
    if target is not None and token != target["token"]:
        raise ValueError("守卫目标已变化，旧点击不能命中新目标")
    run["targets"].pop(str(pos), None)
    if target is None or stamp >= run["end"] or not run["hp"]:
        return guild.ids([3 if not run["hp"] else 2, 0, run["combo"], 0, run["hp"]]), [], b""
    score = 0
    if target["kind"] in (1, 2) and hit:
        run["combo"] += 1
        score = config["guild_integral"][str(target["kind"])]["second" + str(min(run["combo"], int(config["global_kv"]["guide_even_up"]["value"])))]
        run["score"] += score
    elif target["kind"] == 4 and hit and len(run["boxes"]) < 4:
        setting = next(r for r in config["guild_play"].values() if r["lower"] <= run["score"] <= r["upper"])
        run["boxes"].append(setting["box"])
        run["combo"] += 1
    elif target["kind"] == 3 and hit or target["kind"] == 1 and not hit:
        run["hp"] = max(0, run["hp"] - 1)
        run["combo"] = 0
    return guild.ids([0, score, run["combo"], 0, run["hp"]]), [], b""
