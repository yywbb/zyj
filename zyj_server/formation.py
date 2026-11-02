"""本地换将/布阵/装备；增减装备与缘分，保留原有培养差值。"""

from fractions import Fraction

from . import battle, equip_baptize, godstone, pets, sigil, treasure_refine
from .protocol import encode_pb_field, iter_pb_fields, parse_ids_pb, pb_get_varint, pb_set_varint


def records(body, field, key):
    return {pb_get_varint(v, key): v for n, w, v in iter_pb_fields(body) if n == field and w == 2}


def bonuses(raw, slot, members, equips, config):
    row = config["general"][str(pb_get_varint(raw, 1))]
    level = pb_get_varint(raw, 3)
    values = {field: 0 for field in range(6, 17)}
    if slot:
        values.update({field: int(value) for field, value in godstone.attributes(slot, config).items()})
    equipped, relations = set(), b""
    for field in range(4, 10):
        iid = pb_get_varint(slot, field)
        if not iid:
            continue
        if iid not in equips:
            raise ValueError("阵位装备不存在")
        item = parse_ids_pb(equips[iid])
        gear = equip_baptize.validate(item, config)
        equipped.add(item[1])
        for index in (1, 2):
            name = gear[f"attr{index}"]
            if not name:
                continue
            if name not in battle.GENERAL_FIELDS or gear[f"method{index}"] != "value":
                raise ValueError("不支持的装备加成")
            values[battle.GENERAL_FIELDS[name]] += int(Fraction(str(gear[f"init{index}"])) + Fraction(str(gear[f"grow_{index}"])) * (item[2] - 1))
        for name, value in zip(("atk", "def", "hp"), (item + [0] * 13)[5:8]):
            values[battle.GENERAL_FIELDS[name]] += value
        if gear["type"] in ("horse", "treasure"):
            for field, value in treasure_refine.attributes(raw, item, config).items():
                values[field] += value
    for index in range(1, 30):
        required = {int(v) for v in row.get(f"cond{index}ids", "").split(";") if v}
        if not required:
            continue
        present = required & (members if row[f"cond{index}type"] == "person" else equipped)
        active = bool(slot) and required <= present
        relation = encode_pb_field(1, 0, 2 if active else int(bool(present) and bool(slot)))
        relations += encode_pb_field(3, 2, relation + b"".join(encode_pb_field(2, 0, cid) for cid in sorted(present) if slot))
        if active:
            for entry in row[f"cond{index}buf"].split(";"):
                if not entry:
                    continue
                name, amount = entry.split(":")
                base = battle.general_base(row, name, level, pb_get_varint(raw, 4) or 0, config)
                values[battle.GENERAL_FIELDS[name]] += int(base * Fraction(amount) / 100)
    return values, relations


def change(save, opcode, body, config):
    if not save.get("has_role") or save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2:
        raise ValueError("请先完成新手引导后自由上阵")
    world = bytes.fromhex(save["world_state"]["1002"])
    generals, slots, equips = records(world, 1, 2), records(world, 4, 1), records(world, 2, 1)
    old = dict(slots)
    maximum = config["role_exp"][str(save["role_state"]["level"])]["slotnum"]

    def validate_slot(index):
        if not 1 <= index <= min(7, maximum):
            raise ValueError("阵位不存在或尚未解锁")

    if opcode == 1005:
        fields = list(iter_pb_fields(body))
        values = {n: v for n, w, v in fields}
        if (len(fields) != 2 or set(values) != {1, 2}
                or any(w != 0 or not 0 < v < (1 << 31) for n, w, v in fields)):
            raise ValueError("换装需要阵位及装备编号")
        dest, iid = values[1], values[2]
        validate_slot(dest)
        if pb_get_varint(slots.get(dest, b""), 2) not in generals:
            raise ValueError("请先上阵武将再装备")
        if iid not in equips:
            raise ValueError("装备不存在或不属于当前账号")
        item = parse_ids_pb(equips[iid])
        kinds = ("weapon", "armor", "accessory", "head", "treasure", "horse")
        kind = config["equip"].get(str(item[1]), {}).get("type") if len(item) >= 3 else None
        if kind not in kinds:
            raise ValueError("装备部位不受支持")
        field = 4 + kinds.index(kind)
        if any(pb_get_varint(v, f) == iid for v in records(world, 5, 1).values() for f in range(4, 10)):
            raise ValueError("请先将装备从助阵位撤下")
        origins = [(index, f) for index, v in old.items() for f in range(4, 10) if pb_get_varint(v, f) == iid]
        if len(origins) > 1 or any(f != field for _, f in origins):
            raise ValueError("装备穿戴记录无效，请刷新后重试")
        if origins and origins[0][0] != dest:
            origin = origins[0][0]
            validate_slot(origin)
            slots[origin] = pb_set_varint(old[origin], field, pb_get_varint(old[dest], field) or 0)
        slots[dest] = pb_set_varint(old[dest], field, iid)
    elif opcode == 1007:
        fields = list(iter_pb_fields(body))
        if len(fields) != 8 or any(n != 1 or w != 0 or not 0 <= v < (1 << 31) for n, w, v in fields):
            raise ValueError("一键装备需要阵位、方式及六个装备编号")
        dest, method, *items = [v for _, _, v in fields]
        validate_slot(dest)
        if method != 1:
            raise ValueError("暂只支持一键装备，武魂穿戴尚未实现")
        if pb_get_varint(slots.get(dest, b""), 2) not in generals:
            raise ValueError("请先上阵武将再装备")
        occupied = {pb_get_varint(v, f) for i, v in old.items() if i != dest for f in range(4, 10)}
        occupied.update(pb_get_varint(v, f) for v in records(world, 5, 1).values() for f in range(4, 10))
        kinds = ("weapon", "armor", "accessory", "head", "treasure", "horse")
        for field, iid, kind in zip(range(4, 10), items, kinds):
            if not iid:
                continue
            if iid not in equips:
                raise ValueError("装备不存在或不属于当前账号")
            if iid in occupied:
                raise ValueError("装备已被其他阵位使用，请刷新后重试")
            item = parse_ids_pb(equips[iid])
            if len(item) < 3 or config["equip"].get(str(item[1]), {}).get("type") != kind:
                raise ValueError("装备部位不匹配")
            slots[dest] = pb_set_varint(slots[dest], field, iid)
    elif opcode == 1009:
        fields = list(iter_pb_fields(body))
        if len(fields) != 7 or any(n != 1 or w != 0 or not 0 <= v <= 7 for n, w, v in fields):
            raise ValueError("布阵参数无效")
        source = [v or i for i, (_, _, v) in enumerate(fields, 1)]
        if sorted(source) != list(range(1, 8)):
            raise ValueError("布阵必须为不重复的阵位排列")
        for dest, origin in enumerate(source, 1):
            if dest != origin:
                validate_slot(dest)
                validate_slot(origin)
                slots[dest] = pb_set_varint(old.get(origin, encode_pb_field(1, 0, origin)), 1, dest)
    else:
        fields = list(iter_pb_fields(body))
        values = {n: v for n, _, v in fields}
        if (len(fields) != 2 or set(values) not in ({1, 2}, {1, 3})
                or any(w != 0 or not 0 <= v < (1 << 31) for n, w, v in fields)):
            raise ValueError("换将参数无效")
        dest = values[1]
        validate_slot(dest)
        if 2 in values:
            origin = values[2]
            validate_slot(origin)
            slots[dest] = pb_set_varint(old.get(origin, b""), 1, dest)
            slots[origin] = pb_set_varint(old.get(dest, b""), 1, origin)
        else:
            iid = values[3]
            if iid and (iid not in generals or not config["general"][str(pb_get_varint(generals[iid], 1))]["battle"]):
                raise ValueError("武将不存在或不能上阵")
            if iid and any(pb_get_varint(v, 2) == iid for v in records(world, 5, 1).values()):
                raise ValueError("请先将武将从助阵位撤下")
            origin = next((i for i, v in old.items() if pb_get_varint(v, 2) == iid), None) if iid else None
            if origin is not None:
                slots[dest] = pb_set_varint(old[origin], 1, dest)
                slots[origin] = pb_set_varint(old.get(dest, b""), 1, origin)
            else:
                slots[dest] = pb_set_varint(pb_set_varint(old.get(dest, b""), 1, dest), 2, iid)
    return apply_slots(save, slots, config)


def strengthen_stones(save, body, config):
    fields = list(iter_pb_fields(body))
    if (len(fields) != 2 or any(n != 1 or w != 0 for n, w, v in fields)
            or fields[1][2] not in (0, 1)):
        raise ValueError("神石强化需要阵位及单次/一键方式")
    sid, method = [v for n, w, v in fields]
    if (not save.get("has_role") or save["role_state"]["level"] < config["build"]["3"]["level"]
            or save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2):
        raise ValueError("阵容神石尚未解锁")
    world = bytes.fromhex(save["world_state"]["1002"])
    slots, generals = records(world, 4, 1), records(world, 1, 2)
    if (not 1 <= sid <= min(7, config["role_exp"][str(save["role_state"]["level"])]["slotnum"])
            or pb_get_varint(slots.get(sid, b""), 2) not in generals):
        raise ValueError("请选择已解锁且有武将的阵位")
    props = records(bytes.fromhex(save["world_state"]["1200"]), 1, 1)
    slots[sid], cost = godstone.strengthen(slots[sid], method, save["role_state"]["level"],
                                          pb_get_varint(props.get(20223, b""), 2) or 0, config)
    return apply_slots(save, slots, config), [(20223, cost)]


def apply_slots(save, slots, config):
    world = bytes.fromhex(save["world_state"]["1002"])
    generals, old, equips = records(world, 1, 2), records(world, 4, 1), records(world, 2, 1)
    before = {pb_get_varint(v, 2): v for v in old.values() if pb_get_varint(v, 2)}
    after = {pb_get_varint(v, 2): v for v in slots.values() if pb_get_varint(v, 2)}
    protagonist = pb_get_varint(bytes.fromhex(save.get("protagonist_snapshot", "")), 1)
    if not after or protagonist and protagonist not in after:
        raise ValueError("主角必须留在阵中")
    if len(after) != sum(bool(pb_get_varint(v, 2)) for v in slots.values()):
        raise ValueError("武将不能重复上阵")
    old_members = {config["general"][str(pb_get_varint(generals[i], 1))]["init_cid"] for i in before}
    new_members = {config["general"][str(pb_get_varint(generals[i], 1))]["init_cid"] for i in after}
    update = b""
    pet_bonus = pets.attributes(save, config)
    sigil_bonus, sigil_flat = sigil.bonuses(save, config)
    for iid in sorted(before.keys() | after.keys()):
        raw = generals[iid]
        previous, _ = bonuses(raw, before.get(iid, b""), old_members, equips, config)
        current, relations = bonuses(raw, after.get(iid, b""), new_members, equips, config)
        for field, value in pet_bonus.items():
            previous[field] += int(value) if iid in before else 0
            current[field] += int(value) if iid in after else 0
        for field, value in sigil_bonus.items():
            previous[field] += int(value) if iid in before else 0
            current[field] += int(value) if iid in after else 0
        power_delta = 0
        for field in range(6, 17):
            value = pb_get_varint(raw, field) or 0
            changed = value + current[field] - previous[field]
            if not (1 if field in (6, 8, 9) else 0) <= changed < (1 << 31):
                raise ValueError("换阵后的武将属性超出范围")
            if field in (6, 7, 9):
                power_delta += changed - value
            elif field == 8:
                power_delta += changed // 10 - value // 10
            raw = pb_set_varint(raw, field, changed)
        power_delta += sum(equip_baptize.flat(after.get(iid, b""), equips, config)) - sum(equip_baptize.flat(before.get(iid, b""), equips, config))
        power_delta += sum(sigil_flat) * (int(iid in after) - int(iid in before))
        power = (pb_get_varint(raw, 20) or 0) + power_delta
        if not 0 <= power < (1 << 31):
            raise ValueError("换阵后的武将战力超出范围")
        raw = pb_set_varint(raw, 20, power)
        generals[iid] = raw
        update += encode_pb_field(1, 2, raw)
        if iid in after:
            sid = pb_get_varint(after[iid], 1)
            slots[sid] = b"".join(encode_pb_field(n, w, v) for n, w, v in iter_pb_fields(slots[sid]) if n != 3) + relations
    # 空阵位也明确回 general=0，客户端据此删除旧将；装备留在阵位，换将继承。
    update += b"".join(encode_pb_field(4, 2, pb_set_varint(v, 2, pb_get_varint(v, 2) or 0)) for _, v in sorted(slots.items()))
    power = sum(pb_get_varint(generals[iid], 20) or 0 for iid in after)
    if power >= (1 << 31) or power + save["role_state"]["g_power"] >= (1 << 31):
        raise ValueError("阵容战力超出范围")
    save["role_state"].update(power=power, power_all=power + save["role_state"]["g_power"])
    return update
