"""客栈好感：配置经验/属性、实际赠礼、永久成就与付费互换。"""

import random

from . import development, formation, recharge
from .protocol import encode_pb_field, iter_pb_fields, parse_ids_pb, pb_get_varint

QUERIES = (3670, 3671, 3673)
MUTATIONS = (3672, 3674, 3675)
OPCODES = QUERIES + MUTATIONS
GIFTS = (20201, 20208, 20211, 20220)


def get_state(save, config):
    state = save.setdefault("favorite_state", {"generals": {}, "claimed": []})
    if (not isinstance(state, dict) or not isinstance(state.get("generals"), dict)
            or not isinstance(state.get("claimed"), list)):
        raise ValueError("客栈存档无效")
    for cid, row in state["generals"].items():
        if (cid not in config["favorable"] or not isinstance(row, list) or len(row) != 2
                or any(type(v) is not int or not 0 <= v < (1 << 31) for v in row)
                or row[0] > config["favorable"][cid]["level"]):
            raise ValueError("伙伴好感等级或经验无效")
        quality = config["general"][cid]["quality"]
        if (row[0] == config["favorable"][cid]["level"] and row[1]
                or row[0] < config["favorable"][cid]["level"]
                and row[1] >= config["favorable_level"][str(row[0] + 1)][f"exp{quality}"]):
            raise ValueError("伙伴好感经验超出当前等级")
    total = sum(row[0] for row in state["generals"].values())
    if (any(type(cid) is not int or str(cid) not in config["favorable_task"]
            or total < config["favorable_task"][str(cid)]["favorable"] for cid in state["claimed"])
            or len(set(state["claimed"])) != len(state["claimed"])):
        raise ValueError("客栈成就领取记录无效")
    return state


def general_ids(raw, config):
    cid = pb_get_varint(raw, 1)
    row = config["general"][str(cid)]
    return {value for value in (cid, *(row.get(key, 0) for key in ("init_cid", "orange_id", "generalid2", "partner_id")))
            if str(value) in config["favorable"]}


def owned(save, config):
    result = {}
    for raw in formation.records(bytes.fromhex(save["world_state"]["1002"]), 1, 2).values():
        for cid in general_ids(raw, config):
            result.setdefault(cid, []).append(raw)
    return result


def stats(cid, level, config):
    result = {6: 0, 7: 0, 8: 0}
    for index in range(1, level + 1):
        for entry in config["favorable"][str(cid)][f"att{index}"].split(";"):
            if entry:
                name, value = entry.split(",")
                if name not in ("atk", "def", "hp") or int(value) <= 0:
                    raise ValueError("不支持的好感属性配置")
                result[{"atk": 6, "def": 7, "hp": 8}[name]] += int(value)
    return result


def add_bonus(raw, save, config):
    if not save.get("favorite_state", {}).get("generals"):
        return raw
    values = {6: 0, 7: 0, 8: 0}
    for cid in general_ids(raw, config):
        level = save.get("favorite_state", {}).get("generals", {}).get(str(cid), [0, 0])[0]
        for field, amount in stats(cid, level, config).items():
            values[field] += amount
    return development.adjust(raw, values)[0]


def capacity_bonus(save, config, name):
    return sum(config["favorable_task"][str(cid)][name] for cid in save.get("favorite_state", {}).get("claimed", []))


def unlocked(save, config):
    return (save.get("has_role") and save["role_state"]["level"] >= config["build"]["138"]["level"]
            and save.get("guide", {}).get("sections", {}).get("1", {}).get("status") == 2)


def detail(cid, state, config):
    level, exp = state["generals"].get(str(cid), [0, 0])
    values = stats(cid, level, config)
    return recharge.ids([cid, exp, level, values[8], values[6], values[7]] + [0] * 12)


def query(opcode, save, body, config):
    fields = list(iter_pb_fields(body))
    if (opcode != 3670 and body or len(fields) > 1
            or any(n != 1 or w != 0 or not 0 < v < (1 << 31) for n, w, v in fields)):
        raise ValueError("客栈查询只接受空参数，伙伴详情可指定一个CID")
    if not unlocked(save, config):
        if opcode == 3671:
            return b""  # 原生新号初始化也预加载伙伴好感列表，未解锁时保持空表。
        raise ValueError("客栈尚未解锁，请先完成新手引导并达到24级")
    state = get_state(save, config)
    if opcode == 3673:
        total = sum(row[0] for row in state["generals"].values())
        return recharge.ids([v for cid in sorted(map(int, config["favorable_task"])) for v in
                             (cid, 2 if cid in state["claimed"] else int(total >= config["favorable_task"][str(cid)]["favorable"]))])
    current = owned(save, config)
    candidates = sorted(set(current) | set(map(int, state["generals"])))
    if opcode == 3671:
        return recharge.ids([v for cid in candidates for v in (cid, state["generals"].get(str(cid), [0, 0])[0])])
    cid = fields[0][2] if fields else next(iter(sorted(current) or candidates), None)
    if cid not in candidates:
        raise ValueError("当前没有可查看好感度的伙伴，或该伙伴不属于本账号")
    return detail(cid, state, config)


def prepare(opcode, save, body, config, seed):
    if opcode in QUERIES:
        return query(opcode, save, body, config), [], b""
    fields = list(iter_pb_fields(body))
    if any(n != 1 or w != 0 or not 0 < v < (1 << 31) for n, w, v in fields):
        raise ValueError("客栈操作参数无效")
    values = [v for _, _, v in fields]
    if not unlocked(save, config):
        raise ValueError("客栈尚未解锁")
    state = get_state(save, config)
    if opcode == 3674:
        if len(values) != 1 or str(values[0]) not in config["favorable_task"]:
            raise ValueError("客栈成就编号无效")
        row = config["favorable_task"][str(values[0])]
        if values[0] in state["claimed"] or sum(r[0] for r in state["generals"].values()) < row["favorable"]:
            raise ValueError("客栈成就尚未达成或已领取")
        for name in ("maxstamina", "maxenergy"):
            value = save["role_state"][name] + row[name]
            if type(row[name]) is not int or row[name] < 0 or not 0 <= value < (1 << 31):
                raise ValueError("客栈成就资源上限无效")
            save["role_state"][name] = value
        state["claimed"].append(values[0])
        return recharge.ids([1]), [], b""
    if (opcode == 3672 and (not 3 <= len(values) <= 9 or len(values) % 2 != 1)
            or opcode == 3675 and (len(values) != 2 or values[0] == values[1])):
        raise ValueError("送礼或好感互换参数无效")
    current = owned(save, config)
    targets = values[:1] if opcode == 3672 else values
    for cid in targets:
        rows = current.get(cid, [])
        if not rows and opcode == 3675 and str(cid) in state["generals"]:
            continue
        if (len(rows) != 1 or len(general_ids(rows[0], config)) != 1
                or any(pb_get_varint(rows[0], n) for n in range(21, 41))
                or any(any(parse_ids_pb(v)) for n, w, v in iter_pb_fields(rows[0]) if (n, w) == (41, 2))):
            raise ValueError("请选择实际拥有且不重复的普通伙伴")
    before = {cid: row[:] for cid, row in state["generals"].items()}
    costs, critical = [], 0
    if opcode == 3672:
        cid = values[0]
        pairs = list(zip(values[1::2], values[2::2]))
        props = formation.records(bytes.fromhex(save["world_state"]["1200"]), 1, 1)
        if (any(prop not in GIFTS or count > 50 or (pb_get_varint(props.get(prop, b""), 2) or 0) < count for prop, count in pairs)
                or len({prop for prop, _ in pairs}) != len(pairs) or sum(count for _, count in pairs) > 50):
            raise ValueError("礼物不足、重复或超过每批50件")
        row = state["generals"].setdefault(str(cid), [0, 0])
        maximum = config["favorable"][str(cid)]["level"]
        quality = config["general"][str(cid)]["quality"]
        rng = random.Random(seed)
        for prop, count in pairs:
            used = 0
            for _ in range(count):
                if row[0] >= maximum:
                    break
                level = config["favorable_level"][str(row[0] + 1)]
                if pb_get_varint(current[cid][0], 3) < level["general_lv"]:
                    break
                needed = level[f"exp{quality}"]
                chance = level[f"probability{quality}"] + level[f"critical_level{quality}"] * (row[1] * 10 // needed)
                if not 0 <= chance <= 1:
                    raise ValueError("好感暴击概率配置无效")
                # 本地暴击规则：沿用原生展示概率，命中直接升一级并清本级经验。
                if rng.random() < chance:
                    row[0] += 1
                    row[1] = 0
                    critical += 1
                else:
                    row[1] += int(config["props"][str(prop)]["param1"])
                    if row[1] >= needed:
                        row[0] += 1
                        row[1] -= needed
                if row[0] == maximum:
                    row[1] = 0
                used += 1
            if used:
                costs.append((prop, used))
        if not costs:
            raise ValueError("好感已满或伙伴等级不足")
    else:
        left, right = (state["generals"].setdefault(str(cid), [0, 0]) for cid in values)
        if left[0] == right[0]:
            raise ValueError("好感等级相同，不能互换")
        for cid, row in zip(values, (right, left)):
            if cid not in current and any(row):
                raise ValueError("已离开的伙伴不能接收好感，请选择实际拥有的伙伴")
            if (row[0] > config["favorable"][str(cid)]["level"] or row[0]
                    and pb_get_varint(current[cid][0], 3) < config["favorable_level"][str(row[0])]["general_lv"]):
                raise ValueError("互换后超过好感上限或伙伴等级不足")
        costs = [tuple(map(int, entry.split(","))) for entry in config["favorable_level"][str(max(left[0], right[0]))]["favor_exchange_price"].split(";") if entry]
        if len(costs) != 1 or len(costs[0]) != 2 or costs[0][0] != 1001 or costs[0][1] < 0:
            raise ValueError("好感互换费用配置无效")
        state["generals"][str(values[0])], state["generals"][str(values[1])] = right, left
    active = formation.records(bytes.fromhex(save["world_state"]["1002"]), 4, 2)
    update, power = b"", 0
    for cid in targets:
        if cid not in current:
            continue
        old = stats(cid, before.get(str(cid), [0, 0])[0], config)
        new = stats(cid, state["generals"][str(cid)][0], config)
        raw, increase = development.adjust(current[cid][0], {field: new[field] - old[field] for field in new})
        update += encode_pb_field(1, 2, raw)
        if pb_get_varint(raw, 2) in active:
            power += increase
    for key in ("power", "power_all"):
        value = save["role_state"][key] + power
        if not 0 <= value < (1 << 31):
            raise ValueError("好感变更后的战力超出范围")
        save["role_state"][key] = value
    get_state(save, config)
    reply = update
    if opcode == 3672:
        reply = b"".join(encode_pb_field(1, 2, encode_pb_field(1, 0, mid) + encode_pb_field(2, 2, raw)) for mid, raw in
                         ((0, detail(values[0], state, config)), (1, update),
                          (2, recharge.ids([critical, *(v for pair in costs for v in pair)]))))
    return reply, costs, update
