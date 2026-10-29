"""本地换将/布阵；基于已保存属性增减装备与缘分，保留原有培养差值。"""

from fractions import Fraction

from . import battle
from .protocol import encode_pb_field, iter_pb_fields, parse_ids_pb, pb_get_varint, pb_set_varint


def records(body, field, key):
    return {pb_get_varint(v, key): v for n, w, v in iter_pb_fields(body) if n == field and w == 2}


def bonuses(raw, slot, members, equips, config):
    row = config["general"][str(pb_get_varint(raw, 1))]
    level = pb_get_varint(raw, 3)
    values = {field: 0 for field in range(6, 17)}
    equipped, relations = set(), b""
    for field in range(4, 10):
        iid = pb_get_varint(slot, field)
        if not iid:
            continue
        if iid not in equips:
            raise ValueError("阵位装备不存在")
        item = parse_ids_pb(equips[iid])
        if len(item) < 3 or any(item[3:]):
            raise ValueError("此装备的进阶属性暂不支持换阵")
        gear = config["equip"][str(item[1])]
        equipped.add(item[1])
        for index in (1, 2):
            name = gear[f"attr{index}"]
            if not name:
                continue
            if name not in battle.GENERAL_FIELDS or gear[f"method{index}"] != "value":
                raise ValueError("不支持的装备加成")
            values[battle.GENERAL_FIELDS[name]] += int(Fraction(str(gear[f"init{index}"])) + Fraction(str(gear[f"grow_{index}"])) * (item[2] - 1))
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
                base = Fraction(str(row[name])) + Fraction(str(row.get(f"{name}-grow", 0))) * (level - 1)
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

    if opcode == 1009:
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
    for iid in sorted(before.keys() | after.keys()):
        raw = generals[iid]
        previous, _ = bonuses(raw, before.get(iid, b""), old_members, equips, config)
        current, relations = bonuses(raw, after.get(iid, b""), new_members, equips, config)
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
