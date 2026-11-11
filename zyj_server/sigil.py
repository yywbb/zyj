"""魔符镶嵌、同类吞噬与重登自动合成；使用原生SlotS库存和八组印位。"""

from fractions import Fraction

from .protocol import encode_pb_field, iter_pb_fields, parse_ids_pb, pb_get_varint, pb_set_varint

QUERIES = (6405,)
MUTATIONS = (1140, 1141, 6406)
OPCODES = QUERIES + MUTATIONS
AUTO_LEVELS = (5, 7, 9, 11, 13)
FIELDS = {"atk": 6, "def": 7, "hp": 8, "critical": 10}


def ids(body):
    fields = list(iter_pb_fields(body))
    if any(n != 1 or w != 0 or not 0 <= v < (1 << 31) for n, w, v in fields):
        raise ValueError("魔符参数必须为完整整数列表")
    return [v for _, _, v in fields]


def read_world(save, config):
    gems, groups = {}, [[0] * 6 for _ in range(8)]
    seen = set()
    for n, w, raw in iter_pb_fields(bytes.fromhex(save["world_state"]["1002"])):
        if n == 7:
            if w != 2:
                raise ValueError("魔符库存格式无效")
            item = ids(raw)
            row = config["sigil"].get(str(item[1])) if len(item) == 4 else None
            if (not row or not item[0] or item[0] in gems or item[2] != row["level"]
                    or row["type"] != 6 and row["nextid"] and item[3] >= row["exp"]):
                raise ValueError("魔符库存等级、经验或编号无效")
            gems[item[0]] = item
        elif 8 <= n <= 15:
            if w != 2 or n in seen or any(f != 1 or t != 0 for f, t, v in iter_pb_fields(raw)):
                raise ValueError("魔符印位格式无效")
            values = parse_ids_pb(raw)
            if len(values) != 6 or any(not 0 <= v < (1 << 31) for v in values[:5]) or not (0 <= values[5] < (1 << 31) or values[5] == (1 << 64) - 1):
                raise ValueError("魔符印位数量或编号无效")
            groups[n - 8] = [max(0, v - (1 << 64) if v >= (1 << 63) else v) for v in values]
            seen.add(n)
    occupied = set()
    maximum = config["role_exp"][str(save.get("role_state", {}).get("level", 1))]["cheernum"]
    for index, group in enumerate(groups, 1):
        for position, iid in enumerate(group, 1):
            if not iid:
                continue
            if (index > maximum or iid not in gems or iid in occupied
                    or config["sigil"][str(gems[iid][1])]["type"] != config["sigilposition"][str(index)][f"type{position}"]):
                raise ValueError("魔符印位未解锁、类型不符或重复镶嵌")
            occupied.add(iid)
        if group[5] and minimum(group, gems) < int(config["global_kv"]["6_sigil_requirement"]["value"]):
            raise ValueError("符之王缺少五枚达到开启等级的外围魔符")
    return gems, groups


def minimum(group, gems):
    return min((gems[iid][2] if iid else 0 for iid in group[:5]), default=0)


def get_state(save, config):
    state = save.setdefault("sigil_state", {"auto_state": 0, "auto_level": 5})
    if (not isinstance(state, dict) or type(state.get("auto_state")) is not int or state["auto_state"] not in (0, 1)
            or type(state.get("auto_level")) is not int or state["auto_level"] not in AUTO_LEVELS):
        raise ValueError("魔符自动合成设置无效")
    read_world(save, config)
    return state


def _bonuses(gems, groups, config):
    values, flat = {field: Fraction(0) for field in range(6, 17)}, [0, 0]
    for group in groups:
        for iid in group:
            if not iid:
                continue
            row = config["sigil"][str(gems[iid][1])]
            for i in range(1, 5):
                name = row[f"attr{i}"]
                if not name:
                    continue
                value = Fraction(str(row[f"init{i}"]))
                if name not in (*FIELDS, "adddmg", "subdmg") or row[f"method{i}"] != "value" or value < 0:
                    raise ValueError("魔符属性配置无效")
                if name in FIELDS:
                    values[FIELDS[name]] += value * (100 if name == "critical" else 1)
                elif value.denominator == 1:
                    flat[int(name == "subdmg")] += int(value)
                else:
                    raise ValueError("魔符固定伤害配置无效")
    return values, flat


def bonuses(save, config):
    return _bonuses(*read_world(save, config), config)


def can_level(item, gems, groups, config):
    row = config["sigil"][str(item[1])]
    if not row["nextid"]:
        return False
    if row["type"] != 6:
        return True
    group = next((group for group in groups if group[5] == item[0]), None)
    return group is not None and minimum(group, gems) >= config["kingofmofu_lv"][str(item[2])]["limit_lv"]


def advance(item, gems, groups, config, limit=15):
    while item[2] < limit and can_level(item, gems, groups, config):
        row = config["sigil"][str(item[1])]
        if item[3] < row["exp"]:
            break
        following = config["sigil"].get(str(row["nextid"]))
        if not following or following["type"] != row["type"] or following["level"] != item[2] + 1 or row["exp"] <= 0:
            raise ValueError("魔符升级链配置无效")
        item[1], item[2], item[3] = following["id"], following["level"], item[3] - row["exp"]


def _finish(save, gems, groups, before, config):
    from . import development, formation

    old, old_flat = before
    current, flat = _bonuses(gems, groups, config)
    changes = {f: int(current[f]) - int(old[f]) for f in current if int(current[f]) != int(old[f])}
    fixed = sum(flat) - sum(old_flat)
    world = bytes.fromhex(save["world_state"]["1002"])
    generals, slots = formation.records(world, 1, 2), formation.records(world, 4, 2)
    updates, power = b"", 0
    if changes or fixed:
        for iid in sorted(i for i in slots if i):
            raw, increase = development.adjust(generals[iid], changes)
            value = (pb_get_varint(raw, 20) or 0) + fixed
            if not 0 <= value < (1 << 31):
                raise ValueError("魔符加成后的战力超出范围")
            updates += encode_pb_field(1, 2, pb_set_varint(raw, 20, value))
            power += increase + fixed
    inventory = b"".join(encode_pb_field(7, 2, b"".join(encode_pb_field(1, 0, v) for v in item)) for _, item in sorted(gems.items()))
    positions = b""
    for index, group in enumerate(groups, 8):
        values = group[:]
        if not values[5] and minimum(group, gems) < int(config["global_kv"]["6_sigil_requirement"]["value"]):
            values[5] = (1 << 64) - 1
        positions += encode_pb_field(index, 2, b"".join(encode_pb_field(1, 0, v) for v in values))
    save["world_state"]["1002"] = (b"".join(encode_pb_field(n, w, v) for n, w, v in iter_pb_fields(world) if not 7 <= n <= 15) + inventory + positions).hex()
    return updates + inventory + positions, power


def prepare(opcode, save, body, config):
    from .recharge import ids as encode_ids

    if (not save.get("has_role") or save["role_state"]["level"] < config["build"]["158"]["level"]
            or save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2):
        raise ValueError("魔符尚未解锁")
    state, values = get_state(save, config), ids(body)
    if opcode == 6405:
        if body:
            raise ValueError("魔符自动合成查询不接受参数")
        return encode_ids([state["auto_state"], state["auto_level"]]), 0
    if opcode == 6406:
        if (len(values) != 2 or values[0] not in (0, 1) or values[1] not in AUTO_LEVELS
                or save["role_state"]["level"] < int(config["global_kv"]["sigil_autosynthetic_lv"]["value"])):
            raise ValueError("魔符自动合成尚未解锁或设置无效")
        state.update(auto_state=values[0], auto_level=values[1])
        return encode_ids([state["auto_state"]]), 0
    gems, groups = read_world(save, config)
    before = _bonuses(gems, groups, config)
    occupied = {iid for group in groups for iid in group if iid}
    if opcode == 1141:
        if len(values) != 2 or values[0] // 10 not in range(1, 9) or values[0] % 10 not in range(1, 7):
            raise ValueError("请选择有效的魔符印位及编号")
        index, position = values[0] // 10, values[0] % 10
        iid = values[1]
        if index > config["role_exp"][str(save["role_state"]["level"])]["cheernum"]:
            raise ValueError("魔符印位尚未解锁")
        group = groups[index - 1]
        if iid and (iid not in gems or config["sigil"][str(gems[iid][1])]["type"] != config["sigilposition"][str(index)][f"type{position}"]
                    or iid in occupied and group[position - 1] != iid):
            raise ValueError("魔符不属于本人、类型不符或已在其他印位镶嵌")
        group[position - 1] = iid
        if group[5] and minimum(group, gems) < int(config["global_kv"]["6_sigil_requirement"]["value"]):
            raise ValueError("请先卸下符之王，或补齐五枚开启等级的外围魔符")
    else:
        if not 1 <= len(values) <= 9 or len(set(values)) != len(values) or values[0] not in gems or values[0] not in occupied:
            raise ValueError("升级需要已镶嵌魔符及至多八枚不同的闲置材料")
        item = gems[values[0]]
        if not can_level(item, gems, groups, config):
            raise ValueError("魔符已满级或符之王外围等级不足")
        original = item[:]
        advance(item, gems, groups, config)
        foods = values[1:]
        if not foods and item == original:
            # 未指定材料且本级自升级没有消耗时：自动挑选同类型的闲置魔符作材料。
            target_type = config["sigil"][str(item[1])]["type"]
            candidates = []
            for iid in sorted(gems, key=lambda i: (gems[i][2], gems[i][3], i)):
                if (iid != item[0] and iid not in occupied
                        and config["sigil"][str(gems[iid][1])]["type"] == target_type
                        and config["sigil"][str(gems[iid][1])]["nextid"]):
                    candidates.append(iid)
                    if len(candidates) == 8:
                        break
            foods = candidates
        for iid in foods:
            # 到达满级／符之王门槛后立刻停止吞噬：一键添加的后续材料既不消耗，
            # 也不再参与校验，原样留在库存。若先校验再 break，多余材料里的满级、
            # 异类或未拥有 IID 会把整批已结算结果回滚，客户端只显示「无效请求」。
            if not can_level(item, gems, groups, config):
                break
            if (iid not in gems or iid in occupied
                    or config["sigil"][str(gems[iid][1])]["type"] != config["sigil"][str(item[1])]["type"]
                    or not config["sigil"][str(gems[iid][1])]["nextid"]):
                raise ValueError("魔符材料无效、正在镶嵌或类型不符")
            food = gems.pop(iid)
            item[3] += config["sigil"][str(food[1])]["self_exp"] + food[3]
            if not 0 <= item[3] < (1 << 31):
                raise ValueError("魔符经验超出范围")
            advance(item, gems, groups, config)
        if item == original:
            raise ValueError("魔符没有可结算的经验或材料")
    return _finish(save, gems, groups, before, config)


def auto_compose(save, config, limit):
    state = get_state(save, config)
    if (not limit or not state["auto_state"] or not save.get("has_role")
            or save["role_state"]["level"] < int(config["global_kv"]["sigil_autosynthetic_lv"]["value"])):
        return b"", 0
    gems, groups = read_world(save, config)
    before = _bonuses(gems, groups, config)
    occupied = {iid for group in groups for iid in group if iid}
    changed = False
    while True:
        consumed = False
        for iid in sorted(gems, key=lambda i: (i not in occupied, gems[i][2], i)):
            item = gems[iid]
            if item[2] >= limit or not can_level(item, gems, groups, config):
                continue
            original = item[:]
            advance(item, gems, groups, config, limit)
            changed |= original != item
            if item[2] >= limit or not can_level(item, gems, groups, config):
                continue
            food_id = next((i for i in sorted(gems) if i != iid and i not in occupied and gems[i][1] == item[1]), None)
            if food_id is not None:
                food = gems.pop(food_id)
                item[3] += config["sigil"][str(food[1])]["self_exp"] + food[3]
                if item[3] >= (1 << 31):
                    raise ValueError("自动合成魔符经验超出范围")
                advance(item, gems, groups, config, limit)
                consumed = changed = True
                break
        if not consumed:
            break
    return _finish(save, gems, groups, before, config) if changed else (b"", 0)
