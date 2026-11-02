"""真实助阵成员、满员档位及基础成长加成；不把助阵加入战斗阵位。"""

from fractions import Fraction

from .protocol import encode_pb_field, iter_pb_fields, parse_ids_pb, pb_get_varint


def assigned(save, config):
    world = bytes.fromhex(save["world_state"]["1002"])
    generals = {pb_get_varint(v, 2): v for n, w, v in iter_pb_fields(world) if (n, w) == (1, 2)}
    main = {pb_get_varint(v, 2) for n, w, v in iter_pb_fields(world) if (n, w) == (4, 2)}
    maximum = config["role_exp"][str(save.get("role_state", {}).get("level", 1))]["cheernum"]
    result, seen, positions = {}, set(), set()
    for n, w, slot in iter_pb_fields(world):
        if (n, w) != (5, 2):
            continue
        sid, iid = pb_get_varint(slot, 1), pb_get_varint(slot, 2) or 0
        if sid not in range(1, 9) or sid in positions:
            raise ValueError("助阵位置无效或重复")
        positions.add(sid)
        if not iid:
            continue
        raw = generals.get(iid)
        row = config["general"].get(str(pb_get_varint(raw or b"", 1)), {})
        if (sid > maximum or not raw or iid in seen or iid in main or not row.get("battle")
                or row.get("actor") == "lead" or not row.get("init_cid") or row.get("quality") not in range(2, 7)
                or (pb_get_varint(raw, 4) or 0) > 10 or any(pb_get_varint(raw, f) for f in range(21, 41))
                or any(any(parse_ids_pb(v)) for n, w, v in iter_pb_fields(raw) if (n, w) == (41, 2))):
            raise ValueError("助阵伙伴未解锁、不属于本人、重复占用或含未实现的高级属性")
        if any(config["general"][str(pb_get_varint(g, 1))]["init_cid"] == row["init_cid"]
               for g in (*result.values(), *(generals[i] for i in main if i in generals))):
            raise ValueError("同源伙伴不能重复上阵或助阵")
        seen.add(iid)
        result[sid] = raw
    return result


def members(save, config):
    world = bytes.fromhex(save["world_state"]["1002"])
    generals = {pb_get_varint(v, 2): v for n, w, v in iter_pb_fields(world) if (n, w) == (1, 2)}
    iids = {pb_get_varint(v, 2) for n, w, v in iter_pb_fields(world) if n in (4, 5) and w == 2} - {None, 0}
    if not iids <= generals.keys():
        raise ValueError("阵容或助阵伙伴不存在")
    return {config["general"][str(pb_get_varint(generals[i], 1))]["init_cid"] for i in iids}


def tiers(save, config, *, generals=None):
    generals = list(assigned(save, config).values()) if generals is None else generals
    if save.get("role_state", {}).get("level", 1) < config["build"]["189"]["level"] or len(generals) != 8:
        return ()
    return tuple(max((row for row in config["cheer"][str(kind)].values() if row["type_coefficient"] <= minimum),
                     key=lambda row: row["type_coefficient"])
                 for kind, minimum in ((1, min(pb_get_varint(g, 3) for g in generals)),
                                       (2, min(pb_get_varint(g, 4) or 0 for g in generals))))


def attributes(raw, rows, config):
    from . import battle

    values = {6: 0, 7: 0, 8: 0}
    general = config["general"][str(pb_get_varint(raw, 1))]
    for row in rows:
        for i in range(1, 5):
            name, method = row[f"attr{i}"], row[f"method{i}"]
            if name not in ("atk", "def", "hp") or method not in ("value", "percent"):
                raise ValueError("小伙伴加成配置不受支持")
            value = Fraction(str(row[f"init{i}"]))
            if method == "percent":
                value *= battle.general_base(general, name, pb_get_varint(raw, 3), pb_get_varint(raw, 4) or 0, config)
            values[battle.GENERAL_FIELDS[name]] += int(value)
    return values


def growth(save, previous, config):
    from . import development, formation

    old, new = tiers(previous, config), tiers(save, config)
    if old == new:
        return b"", 0
    world = bytes.fromhex(save["world_state"]["1002"])
    generals, slots = formation.records(world, 1, 2), formation.records(world, 4, 2)
    update, power = b"", 0
    for iid in sorted(i for i in slots if i):
        raw = generals[iid]
        before, after = attributes(raw, old, config), attributes(raw, new, config)
        changed, delta = development.adjust(raw, {f: after[f] - before[f] for f in after})
        update += encode_pb_field(1, 2, changed)
        power += delta
    return update, power


def combat(save, config):
    return [pb_get_varint(raw, 1) for _, raw in sorted(assigned(save, config).items())]
