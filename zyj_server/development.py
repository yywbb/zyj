"""主角魔晶培养/预览与普通伙伴突破；在事务副本上准备属性和消耗。"""

from . import battle, formation
from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint, pb_set_field, pb_set_varint

QUERIES = (1023, 1056)
MUTATIONS = (1017, 1055)


def ids(body):
    fields = list(iter_pb_fields(body))
    if any(n != 1 or w != 0 or not 0 <= v < (1 << 31) for n, w, v in fields):
        raise ValueError("培养/突破参数格式错误")
    return [v for _, _, v in fields]


def adjust(raw, changes):
    increase = 0
    for field, delta in changes.items():
        previous = pb_get_varint(raw, field) or 0
        value = previous + delta
        if not 0 <= value < (1 << 31):
            raise ValueError("培养/突破属性超出范围")
        increase += value // 10 - previous // 10 if field == 8 else delta if field in (6, 7, 9) else 0
        raw = pb_set_varint(raw, field, value)
    power = (pb_get_varint(raw, 20) or 0) + increase
    if not 0 <= power < (1 << 31):
        raise ValueError("培养/突破战力超出范围")
    return pb_set_varint(raw, 20, power), increase


def prepare(opcode, save, body, config):
    values = ids(body)
    if not save.get("has_role"):
        raise ValueError("角色尚未创建")
    world = bytes.fromhex(save["world_state"]["1002"])
    generals = formation.records(world, 1, 2)
    slots = formation.records(world, 4, 2)
    costs, update, increase = [], b"", 0
    if opcode in (1055, 1056):
        snapshot = bytes.fromhex(save.get("protagonist_snapshot", ""))
        iid, stage = pb_get_varint(snapshot, 1), pb_get_varint(snapshot, 3)
        if iid not in generals or stage is None:
            raise ValueError("主角状态缺失，请重新登录")
        raw = generals[iid]
        row = config["protagonist_grow"].get(str(stage + 1))
        if opcode == 1056:
            if values:
                raise ValueError("进阶预览不接受参数")
            choice = save.get("selected_general_id")
            if choice not in (1, 2, 3):
                raise ValueError("主角选项未记录")
            previews = []
            # shortcut: 只预览普通形态至23阶；金将分支需飞升/觉醒业务后接入。
            for target in range(stage + 1, 24):
                grow = config["protagonist_grow"][str(target)]
                changes = {field: grow[name] + grow[f"{name}_grow"]
                           - ((pb_get_varint(snapshot, field - 2) or 0) if target == stage + 1 else 0)
                           for field, name in ((6, "atk"), (7, "def"), (8, "hp"))}
                changes[9] = grow["speed_grow"]
                raw, _ = adjust(raw, changes)
                raw = pb_set_varint(pb_set_varint(raw, 1, grow[f"general{choice}"]), 4, target)
                previews.append(encode_pb_field(1, 2, raw))
            return b"".join(previews), costs, update
        if len(values) != 2 or values[0] not in (1, 2, 3) or not 1 <= values[1] <= 1000:
            raise ValueError("魔晶培养需要属性类型和1–1000点数量")
        kind, count = values
        attribute = {1: "atk", 2: "def", 3: "hp"}[kind]
        trained = pb_get_varint(snapshot, kind + 3) or 0
        if not row or trained + count > row[attribute] or row[f"{attribute}_cost"] <= 0:
            raise ValueError("已超过本阶培养上限")
        costs = [(row[f"{attribute}_cost"], count * row[f"{attribute}_stone"])]
        raw, increase = adjust(raw, {kind + 5: count})
        snapshot = pb_set_varint(snapshot, kind + 3, trained + count)
        reply = pb_set_field(snapshot, 10, 2, raw)
        save["protagonist_snapshot"] = reply.hex()
        update = encode_pb_field(1, 2, raw) + encode_pb_field(6, 2, reply)
    else:
        if save["role_state"]["level"] < config["build"]["52"]["level"]:
            raise ValueError("伙伴突破尚未解锁")
        if opcode == 1023:
            if len(values) != 1 or values[0] not in generals:
                raise ValueError("伙伴预览需要本账号武将IID")
            iid = values[0]
        else:
            if len(values) not in (1, 2) or len(values) == 2 and values[1] != 0:
                raise ValueError("普通伙伴突破参数无效")
            matches = [i for i, raw in generals.items() if pb_get_varint(raw, 1) == values[0]]
            if len(matches) != 1:
                raise ValueError("伙伴不存在或CID不唯一")
            iid = matches[0]
        raw = generals[iid]
        cid, level, previous = (pb_get_varint(raw, n) or 0 for n in (1, 3, 4))
        general = config["general"][str(cid)]
        target = previous + 1
        # shortcut: 普通+1–10；红/金将转换需觉醒、好感和飞升业务一并实现。
        if (not general["battle"] or general["quality"] not in (3, 4, 5, 6) or not general["init_cid"]
                or target > 10 or any(pb_get_varint(raw, n) for n in range(21, 41))
                or iid in formation.records(world, 5, 2)):
            raise ValueError("尚不支持此伙伴的高级/助阵突破")
        row = config["general_awake"][str(target)]
        if opcode == 1017:
            if level < row["level"]:
                raise ValueError("伙伴等级不足以突破")
            quality = general["quality"]
            costs = [(1000, row[f"coin{quality}"]), (20017, row[f"{quality}prop"])]
            if row[f"{quality}piece"]:
                fragment = next(r["id"] for r in config["general_fragment"].values() if r["general"] == general["init_cid"])
                costs.append((fragment, row[f"{quality}piece"]))
        changed = pb_set_varint(raw, 4, target)
        members = {config["general"][str(pb_get_varint(generals[i], 1))]["init_cid"] for i in slots if i}
        equips = formation.records(world, 2, 1)
        old, _ = formation.bonuses(raw, slots.get(iid, b""), members, equips, config)
        new, _ = formation.bonuses(changed, slots.get(iid, b""), members, equips, config)
        changes = {battle.GENERAL_FIELDS[name]: int(battle.general_base(general, name, level, target, config))
                   - int(battle.general_base(general, name, level, previous, config)) for name in ("atk", "def", "hp", "speed")}
        for field in new:
            changes[field] = changes.get(field, 0) + new[field] - old[field]
        changed, increase = adjust(changed, changes)
        reply = encode_pb_field(1, 2, changed)
        if opcode == 1023:
            return reply, costs, update
        update = reply
    if iid in slots:
        for key in ("power", "power_all"):
            value = save["role_state"][key] + increase
            if not 0 <= value < (1 << 31):
                raise ValueError("角色战力超出范围")
            save["role_state"][key] = value
    return reply, [(cid, count) for cid, count in costs if count], update
