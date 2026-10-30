"""配置宝物碎片的本地 NPC 单次/批量挑战与合成；不抢真实玩家。"""

import json
import random

from . import battle, formation, recharge, recruit
from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint


QUERIES = (1110, 1112)
MUTATIONS = (1108, 1111, 1114, 1125)
OPCODES = QUERIES + MUTATIONS
NPC_BASE = 2146483648
MAX_ATTEMPTS = 100


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
        return b"\x08\x00", [], []
    if not save.get("has_role") or save["role_state"]["level"] < config["build"]["25"]["level"]:
        raise ValueError("碎片挑战尚未解锁")
    inventory = formation.records(bytes.fromhex(save["world_state"]["1107"]), 1, 1)
    if opcode == 1108:
        if len(values) not in (1, 2) or (len(values) == 2 and not 1 <= values[1] <= 100):
            raise ValueError("碎片合成数量无效")
        equip, count = values[0], values[1] if len(values) == 2 else 1
        fragments = sorted((row["id"], 1) for row in config["treasure2_fragment"].values() if row["equip"] == equip)
        if not fragments:
            fragments = sorted((row["id"], row["num"]) for row in config["equip_fragment"].values() if row["equip"] == equip)
        if not fragments or str(equip) not in config["equip"]:
            raise ValueError("没有此装备的合成配置")
        costs = [(cid, num * count) for cid, num in fragments]
        if any((pb_get_varint(inventory.get(cid, b""), 2) or 0) < num for cid, num in costs):
            raise ValueError("合成碎片不足")
        reward = recruit.build_reward(save, [(equip, count)], config)
        return reward, costs, [reward]
    automatic = False
    if opcode == 1125:
        if len(values) < 2 or values[0] not in (0, 1) or len(set(values[1:])) != len(values) - 1:
            raise ValueError("一键挑战需要消耗选项及不重复的缺少碎片")
        automatic, targets = bool(values[0]), values[1:]
        if (save["role_state"]["level"] < int(config["global_kv"]["artifact_fast_level"]["value"])
                and save["role_state"]["vip"] < int(config["global_kv"]["artifact_fast_vip"]["value"])):
            raise ValueError("一键挑战等级或贵族等级不足")
        index, limit = 0, MAX_ATTEMPTS
    elif opcode == 1110:
        if len(values) != 1:
            raise ValueError("请选择一个宝物碎片")
        targets = values
    elif opcode == 1114:
        if len(values) != 1:
            raise ValueError("十连挑战需要一个本地对手编号")
        cid, index = divmod(values[0] - NPC_BASE, 3)
        targets, limit = [cid], 10
    else:
        if len(values) != 2 or values[1] not in (0, 999):
            raise ValueError("碎片挑战需要本地对手编号及方式")
        cid, index = divmod(values[0] - NPC_BASE, 3)
        targets, limit = [cid], 1
    rows = [config["treasure2_fragment"].get(str(cid)) for cid in targets]
    if not all(rows) or len({row["equip"] for row in rows}) != 1:
        raise ValueError("请选择同一宝物的配置碎片，不支持抢夺玩家")
    if any(pb_get_varint(inventory.get(cid, b""), 2) for cid in targets):
        raise ValueError("已拥有该碎片，请选择缺少的碎片")
    point = config["copy"]["42102"]["1"]
    attack, defense = battle.rosters(save, point, config)
    power = sum(unit["atk"] + unit["def"] + unit["hp"] // 10 + unit["speed"] for unit in defense.values())
    if opcode == 1110:
        cid = targets[0]
        players = []
        for index, name in enumerate(("本地守卫甲", "本地守卫乙", "本地守卫丙")):
            raw = (encode_pb_field(1, 0, NPC_BASE + cid * 3 + index) + encode_pb_field(2, 2, name.encode("utf-8"))
                   + b"".join(encode_pb_field(n, 0, v) for n, v in
                              ((3, point["level"]), (4, 0), (5, next(iter(defense.values()))["cid"]), (7, power))))
            players.append(encode_pb_field(1, 2, raw))
        return b"".join(players), [], []
    energy = save["role_state"]["energy"]
    props = formation.records(bytes.fromhex(save["world_state"]["1200"]), 1, 1)
    pills = {cid: pb_get_varint(props.get(cid, b""), 2) or 0 for cid in (20015, 20020)}
    used = {20015: 0, 20020: 0}
    recovered, rewards, reports, found = 0, [], [], set()
    for attempt in range(limit):
        if len(found) == len(targets):
            break
        if energy == 0 and automatic:
            pill = next((cid for cid in (20015, 20020) if pills[cid] > used[cid]), None)
            if pill:
                row = config["props"][str(pill)]
                if row["type"] != "value" or row["function"] != "attr" or row["param2"] != "enery" or row["use_limit"]:
                    raise ValueError("精力丹配置无效")
                amount = int(row["param1"])
                if not 0 < amount < (1 << 31):
                    raise ValueError("精力丹恢复量无效")
                used[pill] += 1
                energy += amount
                recovered += amount
        if energy == 0:
            break
        cid = next(cid for cid in targets if cid not in found)
        report, gets = fight(save, cid, index, attack, defense, point, config, seed + attempt)
        energy -= 1
        found.update(item for item, _ in gets if item in targets)
        rewards.append(recruit.build_reward(save, gets, config))
        reports.append(report)
    if not rewards:
        raise ValueError("精力不足")
    attempts = len(rewards)
    save["last_rob"] = {"seed": seed, "fragment": targets[0], "result": reports[-1]["result"],
                        "round": reports[-1]["round"], "attempts": attempts,
                        "wins": sum(int(report["result"]) for report in reports)}
    costs = [(1003, attempts - recovered)] + [(cid, num) for cid, num in used.items() if num]
    if opcode == 1111:
        report = reports[0]
        response = (encode_pb_field(1, 0, int(report["result"])) + encode_pb_field(2, 0, report["star"])
                    + encode_pb_field(4, 2, rewards[0])
                    + encode_pb_field(5, 2, json.dumps(report, ensure_ascii=False, separators=(",", ":")).encode("utf-8")))
    else:
        counts = [attempts, used[20020], used[20015]] if opcode == 1125 else [attempts]
        response = b"".join(encode_pb_field(1, 2, encode_pb_field(1, 0, i + 1) + encode_pb_field(2, 2, data))
                            for i, data in enumerate([recharge.ids(counts), *rewards]))
    return response, costs, rewards


def fight(save, cid, index, attack, defense, point, config, seed):
    report = battle.simulate(attack, defense, config, seed)
    report["meta"]["attack"]["n"] = save["role_name"]
    report["meta"]["defense"]["n"] = ("本地守卫甲", "本地守卫乙", "本地守卫丙")[index]
    gets = []
    if report["result"]:
        equip = config["treasure2_fragment"][str(cid)]["equip"]
        loot = config["loot"][str(config["equip"][str(equip)]["quality"])]
        rng = random.Random(seed ^ 0xD09)
        guide = save.get("guide", {}).get("sections", {}).get("52", {})
        guaranteed = cid == 28010 and guide.get("status") == 1 and guide.get("step") in (1, 2)
        rate = max(loot["npc_min"], min(loot["npc_max"], loot["npc_basic"]
                   + loot["npc_more"] * (point["level"] - save["role_state"]["level"])))
        gets = [(1000, save["role_state"]["level"] * loot["coin_param"])]
        if guaranteed or rng.random() < rate:
            gets.append((cid, 1))
        extras = [tuple(map(int, entry.split(","))) for entry in loot["extra"].split(";") if entry]
        if save["role_state"]["level"] >= loot["drop_lv"]:
            extras.extend(tuple(map(int, entry.split(","))) for entry in loot["drop_extra"].split(";") if entry)
        extra = rng.choices(extras, weights=[entry[2] for entry in extras])[0]
        gets.append(extra[:2])
    return report, gets
