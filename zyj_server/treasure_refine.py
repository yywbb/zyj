"""普通宝物/坐骑精炼：配置费用、同名实例材料、穿戴属性及可验证的成本收据。"""

from fractions import Fraction

from .protocol import encode_pb_field, iter_pb_fields, parse_ids_pb, pb_get_varint

OPCODES = (1119,)


def validate(item, config):
    row = config["equip"][str(item[1])]
    data = item + [0] * max(0, 5 - len(item))
    if (row["quality"] not in range(2, 7) or data[3] > min(row["maxlevel2"], max(map(int, config["treasure2_refine"])))
            or any(data[5:]) or not row["adorn"] and data[3]):
        raise ValueError("宝物精炼等级、洗炼或升星数据暂不支持")


def attributes(raw, item, config):
    from . import battle

    row = config["equip"][str(item[1])]
    level = item[3] if len(item) > 3 else 0
    values = {field: 0 for field in range(6, 17)}
    if not level:
        return values
    field = battle.GENERAL_FIELDS.get(row["refine"])
    if field not in (6, 7, 8):
        raise ValueError("宝物精炼成长属性配置无效")
    values[field] = sum(row[f"refine-grow{i}"] for i in range(1, level + 1))
    general = config["general"][str(pb_get_varint(raw, 1))]
    for i in range(1, 11):
        entry = row[f"refine-attr{i}"]
        if not entry or level < row[f"refine-level{i}"]:
            continue
        name, amount = entry.replace("；", ";").split(";")
        amount = Fraction(amount)
        field = battle.GENERAL_FIELDS.get(name)
        if field not in (6, 7, 8, 10, 12, 13, 14) or not 0 < amount <= 1:
            raise ValueError("宝物精炼隐藏属性配置无效")
        base = battle.general_base(general, name, pb_get_varint(raw, 3), pb_get_varint(raw, 4) or 0, config) if field in (6, 7, 8) else 100
        values[field] += int(base * amount)
    return values


def record_costs(save, before, after, costs, foods):
    from . import qiankun

    original = parse_ids_pb(before)
    receipts = qiankun.get_state(save)["receipts"]
    if all(item[2] == 1 and not any(item[3:]) for item in foods):
        qiankun.record_training(save, "equip", before, after, costs + [(item[1], 1) for item in foods], original[2] == 1 and not any(original[3:]))
    else:
        # shortcut: 已强化材料不估算退款，保存实例级材料历史后才开放这类重生。
        receipts.pop(f"equip:{original[0]}", None)
    for item in foods:
        receipts.pop(f"equip:{item[0]}", None)


def prepare(save, body, config):
    from . import equip_baptize, formation, recharge, training

    fields = list(iter_pb_fields(body))
    if not 1 <= len(fields) <= 11 or any(n != 1 or w != 0 or not 0 < v < (1 << 31) for n, w, v in fields):
        raise ValueError("精炼需要宝物IID及完整的同名材料IID列表")
    selected = [v for _, _, v in fields]
    if len(set(selected)) != len(selected):
        raise ValueError("精炼目标和材料不能重复")
    if (not save.get("has_role") or save["role_state"]["level"] < config["build"]["137"]["level"]
            or save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2):
        raise ValueError("宝物精炼尚未解锁")
    world = bytes.fromhex(save["world_state"]["1002"])
    equips = formation.records(world, 2, 1)
    if any(iid not in equips for iid in selected):
        raise ValueError("精炼宝物或材料不存在、不属于当前账号")
    items = [parse_ids_pb(equips[iid]) for iid in selected]
    for item in items:
        row = equip_baptize.validate(item, config)
        if row["type"] not in ("horse", "treasure") or not row["adorn"]:
            raise ValueError("请选择可穿戴的宝物或坐骑，不是普通装备或经验材料")
    target, *foods = items
    row = config["equip"][str(target[1])]
    target = target + [0] * max(0, 5 - len(target))
    level = target[3] + 1
    if level > min(row["maxlevel2"], max(map(int, config["treasure2_refine"]))):
        raise ValueError("宝物精炼已达上限")
    recipe = config["treasure2_refine"][str(level)]
    if len(foods) != recipe[f'oneself{row["quality"]}']:
        raise ValueError("精炼同名宝物数量不符合配置")
    slots, cheers = formation.records(world, 4, 1), formation.records(world, 5, 1)
    occupied = {pb_get_varint(slot, n) for slot in (*slots.values(), *cheers.values()) for n in range(4, 10)}
    if any(pb_get_varint(slot, n) == target[0] for slot in cheers.values() for n in range(4, 10)):
        raise ValueError("暂不支持助阵宝物精炼")
    if any(item[0] in occupied or item[1] != target[1] or any(item[3:4]) or any(item[5:]) for item in foods):
        raise ValueError("精炼材料必须是未穿戴、未精炼且未升星的同名宝物")
    costs = [tuple(map(int, entry.split(","))) for entry in recipe[f'num{row["quality"]}'].split(";") if entry]
    props = formation.records(bytes.fromhex(save["world_state"]["1200"]), 1, 1)
    if (len(costs) != 2 or {cid for cid, count in costs} != {1000, 20256}
            or any(not 0 < count < (1 << 31) for cid, count in costs)):
        raise ValueError("宝物精炼费用配置无效")
    if any((save["role_state"]["coin"] if cid == 1000 else pb_get_varint(props.get(cid, b""), 2) or 0) < count for cid, count in costs):
        raise ValueError("精炼银币或精炼石不足")
    target[3] = level
    replacement = iter(target)
    changed = b"".join(encode_pb_field(n, w, next(replacement) if (n, w) == (1, 0) else v) for n, w, v in iter_pb_fields(equips[target[0]]))
    changed += recharge.ids(replacement)
    generals, power = training.equip_differences(save, equips, {target[0]: changed}, config)
    record_costs(save, equips[target[0]], changed, costs, foods)
    save["world_state"]["1002"] = b"".join(encode_pb_field(n, w, v) for n, w, v in iter_pb_fields(world)
        if not ((n, w) == (2, 2) and pb_get_varint(v, 1) in selected[1:])).hex()
    return encode_pb_field(6, 2, changed) + generals, costs, power
