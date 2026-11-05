"""地狱副本：永久顺序首通、每日成功次数与每图一次通关箱。"""

import json

from . import activities, battle, cheer, formation, pets, recharge
from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint


QUERIES = (1370,)
MUTATIONS = (1371, 1372)
OPCODES = (*QUERIES, *MUTATIONS)


def get_state(save, config):
    state = save.get("hades_copy_state", {"day": 0, "used": 0, "cleared": 0, "claimed": [], "checked_at": 0})
    maps = sorted(config["hades_map"], key=int)
    total = sum(len(config["hades_copy"][mid]) for mid in maps)
    if (not isinstance(state, dict)
            or any(type(state.get(k)) is not int or not 0 <= state[k] < (1 << 63) for k in ("day", "used", "cleared", "checked_at"))
            or state["day"] >= (1 << 31) or state["cleared"] > total
            or state["used"] > min(state["cleared"], int(config["global_kv"]["hades_copy_times"]["value"]))
            or not isinstance(state.get("claimed"), list)
            or any(type(mid) is not int or str(mid) not in maps[:state["cleared"] // 5] for mid in state["claimed"])
            or len(set(state["claimed"])) != len(state["claimed"])):
        raise ValueError("地狱副本存档无效")
    return state


def available_maps(save, config, state):
    copies = formation.records(bytes.fromhex(save["world_state"]["1300"]), 1, 1)
    available = set()
    for index, mid in enumerate(sorted(config["hades_map"], key=int)):
        condition = config["hades_map"][mid]["condition"]
        points = formation.records(copies.get(condition, b""), 7, 1)
        if index * 5 <= state["cleared"] and all(pb_get_varint(points.get(int(pid), b""), 3) for pid in config["copy"][str(condition)]):
            available.add(mid)
    return available


def query(save, config, state):
    available = available_maps(save, config, state)
    rows = [(0, [state["used"]])]
    for index, mid in enumerate(sorted(config["hades_map"], key=int)):
        progress = max(0, min(5, state["cleared"] - index * 5))
        unlocked = mid in available or progress > 0
        box = 2 if int(mid) in state["claimed"] else int(progress == 5)
        values = [int(mid), int(progress == 5) if unlocked else -1, box]
        if unlocked:
            for pid in range(1, min(5, progress + 1) + 1):
                values.extend((pid, 1 if pid <= progress else -1, 0))
        rows.append((int(mid), values))
    return b"".join(encode_pb_field(1, 2, encode_pb_field(1, 0, mid)
                                 + encode_pb_field(2, 2, recharge.ids(v & ((1 << 64) - 1) for v in values)))
                    for mid, values in rows)


def prepare(opcode, save, body, config, now, seed):
    if not save.get("has_role") or save["role_state"]["level"] < config["build"]["430"]["level"]:
        raise ValueError("地狱副本60级解锁")
    fields = list(iter_pb_fields(body))
    length = {1370: 0, 1371: 2, 1372: 1}[opcode]
    if len(fields) != length or any(n != 1 or w != 0 or not 0 < v < (1 << 31) for n, w, v in fields):
        raise ValueError("地狱副本参数无效")
    state = get_state(save, config)
    if type(now) is not int or not 0 <= now < (1 << 63):
        raise ValueError("地狱副本时间无效")
    day = (now + 28800) // 86400
    if opcode in MUTATIONS and (now < state["checked_at"] or day < state["day"]):
        raise ValueError("地狱副本时钟回拨，请稍后重试")
    if day > state["day"]:
        state.update(day=day, used=0)
    state["checked_at"] = max(now, state["checked_at"])
    save["hades_copy_state"] = state
    if opcode == 1370:
        return query(save, config, state), b""
    mid = str(fields[0][2])
    maps = sorted(config["hades_map"], key=int)
    if mid not in maps:
        raise ValueError("地狱副本地图不存在")
    index = maps.index(mid)
    if opcode == 1372:
        if state["cleared"] < (index + 1) * 5 or int(mid) in state["claimed"]:
            raise ValueError("地狱副本通关箱未满足或已领取")
        reward = activities.build_reward(save, config["hades_map"][mid]["reward"], config)
        state["claimed"].append(int(mid))
        return reward, reward
    pid = fields[1][2]
    point = config["hades_copy"][mid].get(str(pid))
    if not point or index * 5 + pid != state["cleared"] + 1 or mid not in available_maps(save, config, state):
        raise ValueError("地狱副本须依次挑战未通关关卡，并先通关对应普通地图")
    if state["used"] >= int(config["global_kv"]["hades_copy_times"]["value"]):
        raise ValueError("地狱副本今日成功次数已用完")
    attack, defense = battle.rosters(save, {**point, "level": point["monster_level"]}, config)
    report = battle.simulate(attack, defense, config, seed, attack_pet=pets.combat(save, config), attack_cheer=cheer.combat(save, config))
    report["meta"]["attack"]["n"], report["meta"]["defense"]["n"] = save["role_name"], point["name"]
    reward = activities.build_reward(save, point["reward"] if report["result"] else "", config)
    if report["result"]:
        state["cleared"] += 1
        state["used"] += 1
    save["last_hades_battle"] = {"rules": report["rules"], "seed": seed, "map": int(mid), "point": pid,
                                  "won": report["result"], "rounds": report["round"]}
    response = (encode_pb_field(1, 0, int(report["result"])) + encode_pb_field(2, 0, report["star"])
                + encode_pb_field(4, 2, reward)
                + encode_pb_field(5, 2, json.dumps(report, ensure_ascii=False, separators=(",", ":")).encode()))
    return response, reward
