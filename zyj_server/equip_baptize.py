"""普通装备洗炼：付费预览持久化，确认绑定装备与版本；未确认属性不生效。"""

from fractions import Fraction
import random

from .protocol import encode_pb_field, iter_pb_fields, parse_ids_pb, pb_get_varint


OPCODES = (1120, 1121, 1124)
ATTRS = ("atk", "def", "hp", "adddmg", "subdmg")
KINDS = ("weapon", "armor", "head", "accessory")


def limits(row, level):
    result = {name: 0 for name in ATTRS}
    for i in range(1, 5):
        name = row[f"baptize_attr{i}"]
        if name:
            if name not in ATTRS or result[name]:
                raise ValueError("装备洗炼属性配置无效")
            cap = row[f"attrlimit{i}"] + row[f"attrlimitup_{i}"] * (level - 1)
            if type(cap) is not int or not 0 < cap < (1 << 31):
                raise ValueError("装备洗炼上限配置无效")
            result[name] = cap
    return result


def validate(item, config):
    if len(item) < 3 or len(item) > 13 or any(type(v) is not int or not 0 <= v < (1 << 31) for v in item):
        raise ValueError("装备洗炼数据无效")
    row = config["equip"].get(str(item[1]))
    if not row or not item[0] or not 1 <= item[2] <= row["maxlevel"]:
        raise ValueError("装备编号或等级无效")
    data = item + [0] * (13 - len(item))
    if row["type"] in KINDS:
        if any(data[i] for i in (3, 4, 11, 12)):
            raise ValueError("装备进阶、注灵或升星暂不支持")
        caps = limits(row, data[2])
        if any(value > caps[name] for name, value in zip(ATTRS, data[5:10])) or row["quality"] < 3 and data[10]:
            raise ValueError("装备洗炼属性超出上限")
    elif row["type"] in ("horse", "treasure"):
        if data[3] or any(data[5:]):
            raise ValueError("宝物高级属性暂不支持")
    else:
        raise ValueError("装备类型暂不支持")
    return row


def flat(slot, equips, config):
    added, reduced = 0, 0
    for field in range(4, 8):
        iid = pb_get_varint(slot, field)
        if not iid:
            continue
        if iid not in equips:
            raise ValueError("阵位装备不存在")
        item = parse_ids_pb(equips[iid])
        validate(item, config)
        data = item + [0] * (13 - len(item))
        added += data[8]
        reduced += data[9]
    return added, reduced


def get_state(save, config):
    state = save.setdefault("equip_baptize_state", {"serial": 0, "pending": {}})
    if (not isinstance(state, dict) or type(state.get("serial")) is not int or not 0 <= state["serial"] < (1 << 31)
            or not isinstance(state.get("pending"), dict)):
        raise ValueError("装备洗炼预览存档无效")
    tokens = set()
    for iid, item in state["pending"].items():
        if (not isinstance(iid, str) or not iid.isdecimal() or str(int(iid)) != iid or not 0 < int(iid) < (1 << 31)
                or not isinstance(item, dict) or type(item.get("token")) is not int
                or not 0 < item["token"] <= state["serial"] or item["token"] in tokens
                or type(item.get("cid")) is not int or str(item["cid"]) not in config["equip"]):
            raise ValueError("装备洗炼预览身份无效")
        tokens.add(item["token"])
        row = config["equip"][str(item["cid"])]
        caps = limits(row, row["maxlevel"])
        for key in ("base", "values"):
            values = item.get(key)
            if (not isinstance(values, list) or len(values) != 5 or row["type"] not in KINDS or row["quality"] < 3
                    or any(type(v) is not int or not 0 <= v <= caps[name] for name, v in zip(ATTRS, values))):
                raise ValueError("装备洗炼预览属性无效")
    return state


def roll(values, row, level, method, config, rng, count):
    values = list(values)
    caps, table = limits(row, level), config["equip_baptize"][str(method)]
    chance = Fraction(config["global_kv"][f"baptize_equip_{method}"]["value"])
    if not 0 <= chance <= 100:
        raise ValueError("洗炼附加属性概率配置无效")
    names = [row[f"baptize_attr{i}"] for i in range(1, 5)]
    for _ in range(count):
        locked = [name for name in names[2:] if name and not values[ATTRS.index(name)]]
        opened = rng.choice(locked) if locked and rng.randrange(100) < chance else None
        for index, name in enumerate(names):
            if not name:
                continue
            pos = ATTRS.index(name)
            if index >= 2 and not values[pos] and name != opened:
                continue
            ratio = Fraction(values[pos], caps[name])
            band = next((i for i in range(1, 11) if ratio <= Fraction(str(table[f"upper{i}"]))), None)
            if band is None:
                raise ValueError("洗炼随机区间配置无效")
            low, high = table[f"{name}down{band}"], table[f"{name}up{band}"]
            if type(low) is not int or type(high) is not int or low > high:
                raise ValueError("洗炼随机波动配置无效")
            values[pos] = min(caps[name], max(1 if name == opened else 0, values[pos] + rng.randint(low, high)))
    return values


def score(values):
    return values[0] + values[1] + values[2] // 10 + values[3] + values[4]


def accepts(before, after, row, flags):
    names = [row[f"baptize_attr{i}"] for i in range(1, 5)]
    selected = [ATTRS.index(name) for name, flag in zip(names, flags) if name and flag]
    if selected or flags[4]:
        return before != after and all(after[i] >= before[i] for i in selected) and (not flags[4] or score(after) >= score(before))
    return any(new > old for old, new in zip(before, after))


def prepare(opcode, save, body, config, seed):
    from . import formation, qiankun, recharge, training

    fields = list(iter_pb_fields(body))
    if len(fields) != (8 if opcode == 1124 else 3) or any(n != 1 or w != 0 or not 0 <= v < (1 << 31) for n, w, v in fields):
        raise ValueError("洗炼需要完整的装备、方式和次数/预览编号")
    values = [v for _, _, v in fields]
    iid = values[1] if opcode == 1121 else values[0]
    if (not save.get("has_role") or save["role_state"]["level"] < config["build"]["53"]["level"]
            or save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2):
        raise ValueError("装备洗炼尚未解锁")
    world = bytes.fromhex(save["world_state"]["1002"])
    equips = formation.records(world, 2, 1)
    if iid not in equips:
        raise ValueError("洗炼装备不存在或不属于当前账号")
    if any(n != 1 or w != 0 for n, w, v in iter_pb_fields(equips[iid])):
        raise ValueError("装备洗炼数据无效")
    item = parse_ids_pb(equips[iid])
    row = validate(item, config)
    if row["type"] not in KINDS or row["quality"] < int(config["global_kv"]["baptize_equip_quality"]["value"]):
        raise ValueError("请选择可洗炼的普通蓝色及以上装备")
    if any(pb_get_varint(slot, f) == iid for slot in formation.records(world, 5, 1).values() for f in range(4, 10)):
        raise ValueError("暂不支持助阵装备洗炼")
    data = item + [0] * (13 - len(item))
    state = get_state(save, config)
    pending = state["pending"].get(str(iid))
    if pending and (pending["cid"] != data[1] or pending["base"] != data[5:10]):
        raise ValueError("装备洗炼预览与当前装备不匹配")
    if opcode == 1120 and values[1:] == [0, 0]:
        preview = data[:]
        if pending:
            preview[5:10] = pending["values"]
            validate(preview, config)
        return recharge.ids([*preview, pending["token"] if pending else 0]), [], b"", 0, 0
    costs, replaced, status = [], 0, []
    if opcode == 1121:
        method, _, token = values
        if method not in (0, 1) or not pending or token != pending["token"]:
            raise ValueError("洗炼预览已变化，请重新打开装备查看后确认")
        if method:
            replaced = int(data[5:10] != pending["values"])
            data[5:10] = pending["values"]
        del state["pending"][str(iid)]
    else:
        _, method, count, *flags = values
        level, vip = save["role_state"]["level"], config["vip"][str(save["role_state"].get("vip", 0))]
        large = level >= int(config["global_kv"]["baptize_leve_limit"]["value"])
        if method not in (1, 2, 3):
            raise ValueError("洗炼方式无效")
        if opcode == 1120:
            if count not in ((1, 10, 50) if large else (1, 10)):
                raise ValueError("洗炼次数尚未解锁")
        elif (level < int(config["global_kv"]["free_automatic_level"]["value"]) and not vip["vip_baptize"]
              or count < 10 or count % 10 or count > (int(config["global_kv"]["automatic_baptize_number"]["value"]) if large else 200)
              or any(v not in (0, 1) for v in flags) or pending):
            raise ValueError("自动洗炼未解锁、次数/筛选无效或尚有待确认预览")
        if all(data[5 + ATTRS.index(name)] == cap for name, cap in limits(row, data[2]).items() if cap):
            raise ValueError("洗炼属性已达上限，请先强化装备")
        props = formation.records(bytes.fromhex(save["world_state"]["1200"]), 1, 1)
        for entry in config["global_kv"][f"baptize_consume_{method}"]["value"].split(";"):
            if not entry:
                continue
            cid, number = map(int, entry.split(","))
            available = save["role_state"][{1000: "coin", 1001: "gold"}[cid]] if cid in (1000, 1001) else pb_get_varint(props.get(cid, b""), 2) or 0
            if cid not in (1000, 1001, 20222) or number <= 0 or available < number * count:
                raise ValueError("洗炼费用配置无效或资源不足")
            costs.append((cid, number * count))
        stones = sum(n for cid, n in costs if cid == 20222)
        if not stones or data[10] + stones >= (1 << 31):
            raise ValueError("洗炼石消耗记录超出范围")
        data[10] += stones
        rng = random.Random(seed)
        if opcode == 1120:
            if state["serial"] + 1 >= (1 << 31):
                raise ValueError("洗炼预览编号超出范围")
            state["serial"] += 1
            pending = {"cid": data[1], "token": state["serial"], "base": data[5:10],
                       "values": roll(data[5:10], row, data[2], method, config, rng, count)}
            state["pending"][str(iid)] = pending
        else:
            names = [row[f"baptize_attr{i}"] for i in range(1, 5)]
            for _ in range(count // 10):
                before = data[5:10]
                after = roll(before, row, data[2], method, config, rng, 10)
                keep = accepts(before, after, row, flags)
                status.extend([int(keep), *(after[ATTRS.index(name)] - before[ATTRS.index(name)] if name else 0 for name in names)])
                if keep:
                    data[5:10] = after
                    replaced += 1
    validate(data, config)
    changed = recharge.ids(data)
    clean = item[2] == 1 and not any(item[3:])
    qiankun.record_training(save, "equip", equips[iid], changed, [(cid, n) for cid, n in costs if cid == 20222], clean)
    generals, power = training.equip_differences(save, equips, {iid: changed}, config)
    reward = encode_pb_field(6, 2, changed) + generals
    if opcode == 1120:
        preview = data[:]
        preview[5:10] = pending["values"]
        reply = recharge.ids([*preview, pending["token"]])
    elif opcode == 1124:
        reply = b"".join(encode_pb_field(1, 2, encode_pb_field(1, 0, mid) + encode_pb_field(2, 2, raw))
                         for mid, raw in ((1, reward), (2, recharge.ids(v & ((1 << 64) - 1) for v in status))))
    else:
        reply = reward
    return reply, costs, reward, power, replaced
