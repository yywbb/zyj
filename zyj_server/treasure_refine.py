"""宝物/坐骑精炼及升星：真实费用、穿戴属性、被动与实际成本收据。"""

from fractions import Fraction

from .protocol import encode_pb_field, iter_pb_fields, parse_ids_pb, pb_get_varint

OPCODES = (1119, 1127)


def validate(item, config):
    row = config["equip"][str(item[1])]
    data = item + [0] * max(0, 13 - len(item))
    if (row["quality"] not in range(2, 7) or data[3] > min(row["maxlevel2"], max(map(int, config["treasure2_refine"])))
            or any(data[5:11]) or data[12] or not 0 <= data[11] <= row["up_star"]
            or data[11] and str(data[11]) not in config["treasure2_star"] or not row["adorn"] and (data[3] or data[11])):
        raise ValueError("宝物精炼等级、洗炼或升星数据暂不支持")


def star_skills(item, config):
    stars = item[11] if len(item) > 11 else 0
    if not stars:
        return []
    kind = config["equip"][str(item[1])]["type"]
    return [config["treasure2_star"][str(min(stars, row["id"] + 4))][kind + "_activated"]
            for row in sorted(config["treasure2_star"].values(), key=lambda r: r["id"])
            if row["show"] and row["id"] <= stars]


def attributes(raw, item, config):
    from . import battle

    row = config["equip"][str(item[1])]
    level = item[3] if len(item) > 3 else 0
    values = {field: 0 for field in range(6, 17)}
    stars = item[11] if len(item) > 11 else 0
    general = config["general"][str(pb_get_varint(raw, 1))]
    if stars:
        for name in ("atk", "def", "hp"):
            values[battle.GENERAL_FIELDS[name]] += config["treasure2_star"][str(stars)][name]
        for sid in star_skills(item, config):
            skill = config["breakskill"][str(sid)]
            name = skill["attr"]
            if skill["type"] or name == "dmg":
                continue
            if skill["target"] != "3" or skill["method"] != "percent" or name not in battle.GENERAL_FIELDS:
                raise ValueError("宝物升星常驻属性配置无效")
            amount = Fraction(str(skill["value"]))
            if name in ("atk", "def", "hp"):
                amount *= battle.general_base(general, name, pb_get_varint(raw, 3), pb_get_varint(raw, 4) or 0, config)
            values[battle.GENERAL_FIELDS[name]] += int(amount)
    if not level:
        return values
    field = battle.GENERAL_FIELDS.get(row["refine"])
    if field not in (6, 7, 8):
        raise ValueError("宝物精炼成长属性配置无效")
    values[field] += sum(row[f"refine-grow{i}"] for i in range(1, level + 1))
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


def prepare(save, body, config, opcode=1119):
    from . import equip_baptize, formation, recharge, training

    fields = list(iter_pb_fields(body))
    if (not 1 <= len(fields) <= (1 if opcode == 1127 else 11)
            or any(n != 1 or w != 0 or not 0 < v < (1 << 31) for n, w, v in fields)):
        raise ValueError("精炼需要宝物IID及完整的同名材料IID列表")
    selected = [v for _, _, v in fields]
    if len(set(selected)) != len(selected):
        raise ValueError("精炼目标和材料不能重复")
    if (not save.get("has_role") or save["role_state"]["level"] < config["build"]["666" if opcode == 1127 else "137"]["level"]
            or save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2):
        raise ValueError("宝物升星尚未解锁" if opcode == 1127 else "宝物精炼尚未解锁")
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
    if opcode == 1127:
        target += [0] * max(0, 13 - len(target))
        level = target[11] + 1
        recipe = config["treasure2_star"].get(str(level))
        if not recipe or level > row["up_star"] or not recipe.get(f'cost_{row["quality"]}'):
            raise ValueError("此宝物品质或星级不能继续升星")
        if target[3] < recipe["num"]:
            raise ValueError("宝物精炼等级不足以升星")
        costs = [tuple(map(int, entry.split(","))) for entry in recipe[f'cost_{row["quality"]}'].split(";") if entry]
    else:
        level = target[3] + 1
        if level > min(row["maxlevel2"], max(map(int, config["treasure2_refine"]))):
            raise ValueError("宝物精炼已达上限")
        recipe = config["treasure2_refine"][str(level)]
        if len(foods) != recipe[f'oneself{row["quality"]}']:
            raise ValueError("精炼同名宝物数量不符合配置")
        costs = [tuple(map(int, entry.split(","))) for entry in recipe[f'num{row["quality"]}'].split(";") if entry]
    slots, cheers = formation.records(world, 4, 1), formation.records(world, 5, 1)
    occupied = {pb_get_varint(slot, n) for slot in (*slots.values(), *cheers.values()) for n in range(4, 10)}
    if any(pb_get_varint(slot, n) == target[0] for slot in cheers.values() for n in range(4, 10)):
        raise ValueError("暂不支持助阵宝物精炼")
    if any(item[0] in occupied or item[1] != target[1] or any(item[3:4]) or any(item[5:]) for item in foods):
        raise ValueError("精炼材料必须是未穿戴、未精炼且未升星的同名宝物")
    props = formation.records(bytes.fromhex(save["world_state"]["1200"]), 1, 1)
    if (len(costs) != (3 if opcode == 1127 else 2) or {cid for cid, count in costs} != ({1000, 192153, 192154} if opcode == 1127 else {1000, 20256})
            or any(not 0 < count < (1 << 31) for cid, count in costs)):
        raise ValueError("宝物精炼费用配置无效")
    if any((save["role_state"]["coin"] if cid == 1000 else pb_get_varint(props.get(cid, b""), 2) or 0) < count for cid, count in costs):
        raise ValueError("宝物升星银币或材料不足" if opcode == 1127 else "精炼银币或精炼石不足")
    target[11 if opcode == 1127 else 3] = level
    replacement = iter(target)
    changed = b"".join(encode_pb_field(n, w, next(replacement) if (n, w) == (1, 0) else v) for n, w, v in iter_pb_fields(equips[target[0]]))
    changed += recharge.ids(replacement)
    generals, power = training.equip_differences(save, equips, {target[0]: changed}, config)
    record_costs(save, equips[target[0]], changed, costs, foods)
    save["world_state"]["1002"] = b"".join(encode_pb_field(n, w, v) for n, w, v in iter_pb_fields(world)
        if not ((n, w) == (2, 2) and pb_get_varint(v, 1) in selected[1:])).hex()
    return encode_pb_field(6, 2, changed) + generals, costs, power
