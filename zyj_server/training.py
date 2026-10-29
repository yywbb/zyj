"""经验丹与普通装备强化；只准备变化，扣费和落盘由 player 统一提交。"""

import random
from fractions import Fraction

from . import battle, formation
from .protocol import encode_pb_field, iter_pb_fields, parse_ids_pb, pb_get_varint, pb_set_varint


OPCODES = (1038, 1101, 1109)
EXP_PROPS = (20196, 20197, 20198, 20199)


def grow_general(raw, gained, slot, members, equips, config, maximum=None):
    unit = {name: pb_get_varint(raw, field) or 0 for name, field in battle.GENERAL_FIELDS.items()}
    values, increase, up = battle.grown_general(unit, gained, config, maximum)
    if up:
        previous, _ = formation.bonuses(raw, slot, members, equips, config)
        current, _ = formation.bonuses(pb_set_varint(raw, 3, values[3]), slot, members, equips, config)
        for field in range(6, 17):
            delta = current[field] - previous[field]
            if not delta:
                continue
            value = values.get(field, pb_get_varint(raw, field) or 0)
            values[field] = value + delta
            increase += (value + delta) // 10 - value // 10 if field == 8 else delta if field in (6, 7, 9) else 0
        growth = Fraction(str(config["general"][str(unit["cid"])]["potential-grow"]))
        values[17] = (pb_get_varint(raw, 17) or 0) + int(growth * (values[3] - 1)) - int(growth * (unit["level"] - 1))
    values[20] = (pb_get_varint(raw, 20) or 0) + increase
    if any(not 0 <= value < (1 << 31) for value in values.values()):
        raise ValueError("武将成长或战力超出范围")
    for field, value in values.items():
        raw = pb_set_varint(raw, field, value)
    return raw, increase, up


def use_exp(save, body, config):
    fields = list(iter_pb_fields(body))
    iids = [v for n, w, v in fields if n == 1]
    counts = [v for n, w, v in fields if n == 2]
    if (len(iids) != 1 or len(counts) != 4 or len(fields) != 5 or not iids[0]
            or any(w != 0 or not 0 <= v < (1 << 31) for n, w, v in fields) or not any(counts)):
        raise ValueError("经验丹参数无效")
    if not save.get("has_role") or save["role_state"]["level"] < config["build"]["135"]["level"]:
        raise ValueError("角色等级尚未解锁经验丹升级")
    world = bytes.fromhex(save["world_state"]["1002"])
    generals, slots, equips = formation.records(world, 1, 2), formation.records(world, 4, 2), formation.records(world, 2, 1)
    iid = iids[0]
    if iid not in generals:
        raise ValueError("武将不存在")
    raw = generals[iid]
    row = config["general"][str(pb_get_varint(raw, 1))]
    if (not row["battle"] or any(pb_get_varint(raw, n) for n in range(21, 41))
            or any(any(parse_ids_pb(v)) for n, w, v in iter_pb_fields(raw) if n == 41 and w == 2)
            or iid in formation.records(world, 5, 2)):
        raise ValueError("暂不支持此武将的高级或助阵成长")
    level, experience = pb_get_varint(raw, 3), pb_get_varint(raw, 5) or 0
    maximum = min(save["role_state"]["level"] * int(config["global_kv"]["general_level"]["value"]),
                  max(map(int, config["general_exp"])))
    if not level or level >= maximum:
        raise ValueError("武将已达当前等级上限")
    amounts = [int(config["props"][str(cid)]["param1"]) for cid in EXP_PROPS]
    gained = sum(amount * count for amount, count in zip(amounts, counts))
    needed = sum(config["general_exp"][str(lv)][f'{row["quality"]}exp'] for lv in range(level, maximum)) - experience
    # 客户端允许最后一颗丹溢出经验，禁止满级后继续吞丹。
    if gained - max(amount for amount, count in zip(amounts, counts) if count) >= needed:
        raise ValueError("经验丹数量超过当前等级上限所需")
    members = {config["general"][str(pb_get_varint(generals[i], 1))]["init_cid"] for i in slots if i}
    raw, increase, _ = grow_general(raw, gained, slots.get(iid, b""), members, equips, config, maximum)
    costs = [(cid, count) for cid, count in zip(EXP_PROPS, counts) if count]
    return encode_pb_field(8, 2, raw), costs, increase if iid in slots else 0


def strengthen(save, opcode, body, config, seed):
    if not save.get("has_role"):
        raise ValueError("角色尚未创建")
    fields = list(iter_pb_fields(body))
    if any(w != 0 or not 0 <= v < (1 << 31) for n, w, v in fields):
        raise ValueError("强化参数无效")
    world = bytes.fromhex(save["world_state"]["1002"])
    generals, slots, equips = formation.records(world, 1, 2), formation.records(world, 4, 2), formation.records(world, 2, 1)
    if opcode == 1101:
        values = {n: v for n, w, v in fields}
        if (len(fields) != len(values) or set(values) not in ({1}, {1, 2})
                or values.get(2, 0) not in (0, 1) or values[1] not in equips):
            raise ValueError("强化装备或方式无效")
        selected = [values[1]]
        steps = 5 if values.get(2, 0) else 1
    else:
        iids = [v for n, w, v in fields]
        if (not 1 <= len(iids) <= 7 or len(set(iids)) != len(iids)
                or any(n != 1 for n, w, v in fields) or any(i not in generals or i not in slots for i in iids)):
            raise ValueError("一键强化武将参数无效")
        selected = [pb_get_varint(slots[iid], n) for iid in iids for n in range(4, 8) if pb_get_varint(slots[iid], n)]
        steps = None
    if not selected or len(selected) != len(set(selected)):
        raise ValueError("没有可强化装备或装备重复")
    if any(pb_get_varint(slot, n) in selected for slot in formation.records(world, 5, 1).values() for n in range(4, 10)):
        raise ValueError("暂不支持助阵装备强化")
    items, targets, prices = {}, {}, {}
    for iid in selected:
        if iid not in equips:
            raise ValueError("强化装备不存在")
        item = parse_ids_pb(equips[iid])
        if len(item) < 3 or any(item[3:]):
            raise ValueError("此装备的进阶属性尚未支持强化")
        row = config["equip"][str(item[1])]
        if row["type"] not in ("weapon", "armor", "head", "accessory"):
            raise ValueError("暂不支持此装备类型强化")
        if any(row[f"attr{i}"] and (row[f"method{i}"] != "value" or row[f"attr{i}"] not in battle.GENERAL_FIELDS) for i in (1, 2)):
            raise ValueError("暂不支持此装备的强化属性")
        maximum = min(save["role_state"]["level"] * int(config["global_kv"]["equip_level"]["value"]), row["maxlevel"],
                      max(map(int, config["equip_strengthen"])))
        if item[2] < 1:
            raise ValueError("装备等级无效")
        items[iid] = item
        targets[iid] = min(maximum, item[2] + 5) if steps == 5 else maximum
        prices[iid] = f'quality{row["quality"]}'
    vip = config["vip"][str(save["role_state"].get("vip", 0))]
    deck = [entry.split(",") for i in (1, 2, 3) for entry in vip[f"p_equipex_{i}"].split(";") if entry]
    rng = random.Random(seed)
    coin, spent, critical = save["role_state"]["coin"], 0, {}
    while True:
        available = [i for i in items if items[i][2] < targets[i]
                     and config["equip_strengthen"][str(items[i][2])][prices[i]] <= coin - spent]
        if not available:
            break
        # 自研：一键优先补最低等级装备；五级按钮以原等级+5为目标。
        iid = min(available, key=lambda i: (items[i][2], i))
        cost = config["equip_strengthen"][str(items[iid][2])][prices[iid]]
        if cost <= 0:
            raise ValueError("强化费用配置无效")
        rolled = rng.choices([int(v) for v, weight in deck], [float(weight) for v, weight in deck])[0]
        increase = min(rolled, targets[iid] - items[iid][2])
        if increase < 1:
            raise ValueError("强化暴击配置无效")
        items[iid][2] += increase
        spent += cost
        critical[iid] = critical.get(iid, 0) + increase - 1
        if steps == 1:
            break
    if not spent:
        raise ValueError("装备已到等级上限或银币不足")
    updated = dict(equips)
    reward = encode_pb_field(1, 0, (-spent) & ((1 << 64) - 1))
    for iid in sorted(critical):
        updated[iid] = b"".join(encode_pb_field(1, 0, v) for v in items[iid])
        reward += encode_pb_field(6, 2, updated[iid])
    reward += encode_pb_field(12, 2, b"".join(encode_pb_field(1, 0, critical[i]) for i in sorted(critical)))
    members = {config["general"][str(pb_get_varint(generals[i], 1))]["init_cid"] for i in slots if i}
    power_delta = 0
    for iid, slot in slots.items():
        if not iid or not any(pb_get_varint(slot, n) in critical for n in range(4, 10)):
            continue
        raw = generals[iid]
        previous, _ = formation.bonuses(raw, slot, members, equips, config)
        current, _ = formation.bonuses(raw, slot, members, updated, config)
        increase = 0
        for field in range(6, 17):
            value = pb_get_varint(raw, field) or 0
            changed = value + current[field] - previous[field]
            if not 0 <= changed < (1 << 31):
                raise ValueError("强化后的武将属性超出范围")
            increase += changed // 10 - value // 10 if field == 8 else changed - value if field in (6, 7, 9) else 0
            raw = pb_set_varint(raw, field, changed)
        power = (pb_get_varint(raw, 20) or 0) + increase
        if not 0 <= power < (1 << 31):
            raise ValueError("强化后的武将战力超出范围")
        reward += encode_pb_field(8, 2, pb_set_varint(raw, 20, power))
        power_delta += increase
    return reward, power_delta
