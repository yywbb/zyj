"""搜神记碎片的本地 NPC 挑战与合成；战斗复用自研 v2，不抢真实玩家。"""

import json
import random

from . import battle, formation, recruit
from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint


QUERIES = (1110, 1112)
MUTATIONS = (1108, 1111)
OPCODES = QUERIES + MUTATIONS
NPC_BASE = 2146483648
# shortcut: 仅实现搜神记单次本地 NPC 闭环；开放其他宝物或十连时再接入对应规则。
FRAGMENTS = (28010, 28011, 28012)


def ids(body):
    fields = list(iter_pb_fields(body))
    if any(n != 1 or w != 0 or not 0 <= v < (1 << 31) for n, w, v in fields):
        raise ValueError("碎片挑战参数无效")
    return [v for _, _, v in fields]


def prepare(opcode, save, body, config, seed):
    values = ids(body)
    if opcode == 1112:
        if values:
            raise ValueError("保护时间查询不接受参数")
        return b"\x08\x00", [], b""
    if not save.get("has_role") or save["role_state"]["level"] < config["build"]["25"]["level"]:
        raise ValueError("碎片挑战尚未解锁")
    inventory = formation.records(bytes.fromhex(save["world_state"]["1107"]), 1, 1)
    if opcode == 1108:
        if values != [26102]:
            raise ValueError("本地碎片合成暂只支持搜神记")
        if any((pb_get_varint(inventory.get(cid, b""), 2) or 0) < 1 for cid in FRAGMENTS):
            raise ValueError("搜神记碎片不足")
        reward = recruit.build_reward(save, [(26102, 1)], config)
        return reward, [(cid, 1) for cid in FRAGMENTS], reward
    if opcode == 1110:
        if len(values) != 1:
            raise ValueError("请选择一个宝物碎片")
        cid = values[0]
    else:
        if len(values) != 2 or values[1] not in (0, 999):
            raise ValueError("碎片挑战需要本地对手编号及方式")
        cid, index = divmod(values[0] - NPC_BASE, 3)
    if cid not in FRAGMENTS:
        raise ValueError("本地挑战暂只支持搜神记三个碎片，不支持抢夺玩家")
    if pb_get_varint(inventory.get(cid, b""), 2):
        raise ValueError("已拥有该碎片，请选择缺少的碎片")
    point = config["copy"]["42102"]["1"]
    attack, defense = battle.rosters(save, point, config)
    power = sum(unit["atk"] + unit["def"] + unit["hp"] // 10 + unit["speed"] for unit in defense.values())
    if opcode == 1110:
        players = []
        for index, name in enumerate(("本地守卫甲", "本地守卫乙", "本地守卫丙")):
            raw = (encode_pb_field(1, 0, NPC_BASE + cid * 3 + index) + encode_pb_field(2, 2, name.encode("utf-8"))
                   + b"".join(encode_pb_field(n, 0, v) for n, v in
                              ((3, point["level"]), (4, 0), (5, next(iter(defense.values()))["cid"]), (7, power))))
            players.append(encode_pb_field(1, 2, raw))
        return b"".join(players), [], b""
    if save["role_state"]["energy"] < 1:
        raise ValueError("精力不足")
    report = battle.simulate(attack, defense, config, seed)
    report["meta"]["attack"]["n"] = save["role_name"]
    report["meta"]["defense"]["n"] = ("本地守卫甲", "本地守卫乙", "本地守卫丙")[index]
    gets = []
    if report["result"]:
        loot = config["loot"][str(config["equip"]["26102"]["quality"])]
        rng = random.Random(seed ^ 0xD09)
        guide = save.get("guide", {}).get("sections", {}).get("52", {})
        guaranteed = guide.get("status") == 1 and guide.get("step") in (1, 2)
        rate = max(loot["npc_min"], min(loot["npc_max"], loot["npc_basic"]
                   + loot["npc_more"] * (point["level"] - save["role_state"]["level"])))
        gets = [(1000, save["role_state"]["level"] * loot["coin_param"])]
        if guaranteed or rng.random() < rate:
            gets.append((cid, 1))
        extras = [tuple(map(int, entry.split(","))) for entry in loot["extra"].split(";") if entry]
        extra = rng.choices(extras, weights=[entry[2] for entry in extras])[0]
        gets.append(extra[:2])
    reward = recruit.build_reward(save, gets, config)
    save["last_rob"] = {"seed": seed, "fragment": cid, "result": report["result"], "round": report["round"]}
    response = (encode_pb_field(1, 0, int(report["result"])) + encode_pb_field(2, 0, report["star"])
                + encode_pb_field(4, 2, reward)
                + encode_pb_field(5, 2, json.dumps(report, ensure_ascii=False, separators=(",", ":")).encode("utf-8")))
    return response, [(1003, 1)], reward
