"""好友副本的本地 NPC 助战；临时阵容、配置掉落与每日次数一起结算。"""

import json
import random

from . import activities, battle, cheer, pets, recharge
from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint


QUERIES = (1323,)
MUTATIONS = (1324, 1325)
HELPERS = {990000001: 10517, 990000002: 10610, 990000003: 10507}


def get_state(save, config):
    state = save.setdefault("friend_copy_state", {"day": 0, "cleared": 43000, "attempts": 0, "wins": {}, "used": []})
    limit = int(config["global_kv"]["friendcopy_challenge"]["value"])
    if (not isinstance(state, dict) or type(state.get("day")) is not int or not 0 <= state["day"] < (1 << 31)
            or type(state.get("cleared")) is not int or state["cleared"] not in (43000, *map(int, config["expedition2"]))
            or type(state.get("attempts")) is not int or not 0 <= state["attempts"] <= limit
            or not isinstance(state.get("wins"), dict) or not isinstance(state.get("used"), list)):
        raise ValueError("好友副本存档无效")
    if (any(type(rid) is not int or rid not in HELPERS for rid in state["used"])
            or len(set(state["used"])) != len(state["used"]) or len(state["used"]) > state["attempts"]):
        raise ValueError("好友副本助战记录无效")
    for mid, count in state["wins"].items():
        if (mid not in config["expedition2"] or int(mid) > state["cleared"]
                or type(count) is not int or not 0 < count <= limit):
            raise ValueError("好友副本胜利记录无效")
    if sum(state["wins"].values()) > state["attempts"]:
        raise ValueError("好友副本挑战次数无效")
    return state


def settle(save, config, now):
    state = get_state(save, config)
    day = (now + 28800) // 86400
    if day > state["day"]:
        state.update(day=day, attempts=0, wins={}, used=[])
    return state


def helper(save, rid, config):
    cid = HELPERS[rid]
    row = config["general"][str(cid)]
    level = save["role_state"]["level"]
    unit = {name: int(battle.general_base(row, name, level, 0, config))
            for name in ("atk", "def", "hp", "speed", "critical", "dodge", "parry", "resilience", "hit", "arp", "criticaldmg")}
    unit.update(iid=rid, cid=cid, level=level, advance=0, skill=row["skillid"], skilllevel=0,
                name="本地NPC·" + row["name"], npc=True)
    return unit


def query(save, state, config):
    values = [int(config["global_kv"]["friendcopy_challenge"]["value"]) - state["attempts"]]
    for mid in sorted(config["expedition2"], key=int):
        if int(mid) <= state["cleared"] + 1:
            values.extend((int(mid), state["wins"].get(mid, 0) if int(mid) <= state["cleared"] else (1 << 64) - 1))
    friends = encode_pb_field(2, 0, len(HELPERS))
    for rid in HELPERS:
        unit = helper(save, rid, config)
        power = unit["atk"] + unit["def"] + unit["hp"] // 10 + unit["speed"]
        row = (encode_pb_field(1, 0, rid) + encode_pb_field(2, 2, unit["name"].encode("utf-8"))
               + encode_pb_field(3, 0, unit["level"]) + encode_pb_field(4, 0, unit["cid"])
               + encode_pb_field(5, 0, 0) + encode_pb_field(6, 0, 0) + encode_pb_field(7, 0, int(rid in state["used"]))
               + encode_pb_field(10, 2, encode_pb_field(1, 2, encode_pb_field(1, 0, power))))
        friends += encode_pb_field(1, 2, row)
    # 本地可选字段2不改变原Ids地图序列；旧客户端会忽略，NPC只进专用缓存。
    return recharge.ids(values) + encode_pb_field(2, 2, friends)


def drops(save, mid, count, config, seed):
    row, rewards, rng = config["expedition_map"][str(mid)], {}, random.Random(seed ^ 0xD09)
    coin = row["coin"]
    if type(coin) is not int or not 0 <= coin < (1 << 31):
        raise ValueError("好友副本银币配置无效")
    rewards[1000] = coin * count
    for _ in range(count):
        for i in range(1, 7):
            cid, number, probability = row[f"drop{i}"], row[f"number{i}"], row[f"drop{i}prob"]
            if (type(cid) is not int or not 0 <= cid < (1 << 31) or type(probability) is not int
                    or not 0 <= probability <= 100 or cid and (type(number) is not int or not 0 < number < (1 << 31))):
                raise ValueError("好友副本掉落配置无效")
            if cid and rng.randrange(100) < probability:
                rewards[cid] = rewards.get(cid, 0) + number
    return activities.build_reward(save, ";".join(f"{cid},{num}" for cid, num in rewards.items() if num), config)


def prepare(opcode, save, body, config, now, seed):
    if not save.get("has_role") or save["role_state"]["level"] < config["build"]["19"]["level"]:
        raise ValueError("好友副本尚未解锁")
    state = settle(save, config, now)
    if opcode == 1323:
        if body:
            raise ValueError("好友副本查询不接受参数")
        return query(save, state, config), b""
    fields = list(iter_pb_fields(body))
    if len(fields) != 2 or any(n != 1 or w != 0 or not 0 < v < (1 << 31) for n, w, v in fields):
        raise ValueError("好友副本挑战参数无效")
    mid, option = (v for _, _, v in fields)
    if str(mid) not in config["expedition2"] or str(mid) not in config["expedition_map"] or mid > state["cleared"] + 1:
        raise ValueError("好友副本关卡尚未解锁")
    count = option if opcode == 1325 else 1
    if not 1 <= count <= 100 or state["attempts"] + count > int(config["global_kv"]["friendcopy_challenge"]["value"]):
        raise ValueError("好友副本今日挑战次数不足")
    if opcode == 1325:
        kv, role = config["global_kv"], save["role_state"]
        if mid > state["cleared"]:
            raise ValueError("好友副本通关后才能一键完成")
        if (role["level"] < int(kv["friendcopy_quick_complete_level"]["value"])
                and role["vip"] < int(kv["friendcopy_quick_complete_vip"]["value"])):
            raise ValueError("好友副本一键完成等级或VIP不足")
        reward = drops(save, mid, count, config, seed)
        state["attempts"] += count
        state["wins"][str(mid)] = state["wins"].get(str(mid), 0) + count
        return reward, reward
    if option not in HELPERS or option in state["used"]:
        raise ValueError("请选择今日尚未使用的本地NPC助战")
    attack, defense = battle.rosters(save, config["expedition2"][str(mid)], config)
    position = next((pos for pos in battle.POSITIONS if pos not in attack), None)
    if position is None:
        protagonist = pb_get_varint(bytes.fromhex(save["protagonist_snapshot"]), 1)
        position = next(pos for pos in reversed(battle.POSITIONS) if attack[pos]["iid"] != protagonist)
    attack[position] = helper(save, option, config)
    report = battle.simulate(attack, defense, config, seed, attack_pet=pets.combat(save, config), attack_cheer=cheer.combat(save, config))
    report["meta"]["attack"]["n"] = save["role_name"]
    report["meta"]["defense"]["n"] = config["expedition_map"][str(mid)]["name"]
    reward = drops(save, mid, 1, config, seed) if report["result"] else b""
    state["attempts"] += 1
    state["used"].append(option)
    if report["result"]:
        state["cleared"] = max(state["cleared"], mid)
        state["wins"][str(mid)] = state["wins"].get(str(mid), 0) + 1
    save["last_friend_battle"] = {"rules": report["rules"], "seed": seed, "map": mid, "helper": option,
                                "won": report["result"], "star": report["star"], "rounds": report["round"]}
    response = (encode_pb_field(1, 0, int(report["result"])) + encode_pb_field(2, 0, report["star"])
                + encode_pb_field(4, 2, reward)
                + encode_pb_field(9, 2, json.dumps(report, ensure_ascii=False, separators=(",", ":")).encode("utf-8")))
    return response, reward
