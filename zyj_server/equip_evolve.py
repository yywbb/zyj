"""普通装备进阶/升星、配置套装与真实材料；不启用注灵或宝物升星。"""

from collections import Counter
from fractions import Fraction

from .protocol import encode_pb_field, iter_pb_fields, parse_ids_pb, pb_get_varint

OPCODES = (1122, 1123)
KINDS = ("weapon", "armor", "accessory", "head")
FIELDS = {"atk": 6, "def": 7, "hp": 8, "speed": 9, "critical": 10, "dodge": 11,
          "parry": 12, "resilience": 13, "hit": 14, "arp": 15, "criticaldmg": 16}


def get_version(save):
    version = save.get("equip_evolve_version", 0)
    if type(version) is not int or version not in (0, 1):
        raise ValueError("装备进阶属性版本无效")
    return version


def validate(data, row, config):
    profile = config.get("equip_evolve", {}).get(str(data[1]))
    if data[3] and (not profile or data[3] > profile["level"]):
        raise ValueError("装备进阶等级或配置无效")
    if data[11] and (data[11] > row["up_star"] or str(data[11]) not in config.get("equip_star", {})
                     or not config["equip_star"][str(data[11])].get(f'cost_{row["quality"]}')):
        raise ValueError("装备星级或配置无效")


def score(item, config):
    row = config["equip"][str(item[1])]
    return (item[3] if len(item) > 3 else 0) + {5: 0, 6: 30, 7: 80}.get(row["quality"], 0)


def chain(cid, config):
    result = {cid}
    while config.get("equip_evolve", {}).get(str(cid), {}).get("evolve"):
        cid = config["equip_evolve"][str(cid)]["evolve"]
        if cid in result or str(cid) not in config["equip"]:
            raise ValueError("装备进阶转换链无效")
        result.add(cid)
    return result


def related(cid, config):
    result = set()
    while cid and cid not in result:
        result.add(cid)
        cid = config["equip"][str(cid)].get("relative") or 0
    return result


def rebirth_fee(item, config):
    data = item + [0] * (13 - len(item))
    row, prices = config["equip"][str(data[1])], config["renascence"]
    fee = prices[str(data[2])]["strengthencost"] + prices[str(data[3])]["equipevolvecost"] + prices[str(data[11])]["star_cost"]
    if data[10]:
        fee += int(config["global_kv"]["equip_baptize_cost"]["value"])
    if row["quality"] == 6 and row.get("relative"):
        fee += prices["30"]["equipevolvecost"]
    elif row["quality"] == 7 and row.get("relative"):
        fee += prices["50"]["equipevolvecost"]
        if not row.get("init_eid"):
            fee += prices["30"]["equipevolvecost"]
    return fee


def attributes(raw, slot, equips, config):
    from . import battle, equip_baptize

    values, groups = {f: Fraction(0) for f in range(6, 17)}, {}
    general = config["general"][str(pb_get_varint(raw, 1))]
    for field in range(4, 8):
        iid = pb_get_varint(slot, field)
        if not iid:
            continue
        item = parse_ids_pb(equips[iid])
        row = equip_baptize.validate(item, config)
        if row["type"] != KINDS[field-4]:
            raise ValueError("装备穿戴部位无效")
        data = item + [0] * (13 - len(item))
        if data[11]:
            name = row["attr1"]
            if name not in FIELDS or row["method1"] != "value":
                raise ValueError("装备升星属性不支持")
            base = int(Fraction(str(row["init1"])) + Fraction(str(row["grow_1"])) * (data[2] - 1))
            values[FIELDS[name]] += int(base * Fraction(str(config["equip_star"][str(data[11])][f'add_{row["quality"]}'])))
        profile = config.get("equip_evolve", {}).get(str(data[1]))
        if not profile:
            continue
        name = profile["attr"]
        if name not in ("atk", "def", "hp"):
            raise ValueError("装备进阶属性不支持")
        values[FIELDS[name]] += int(Fraction(str(profile[f"init{data[3]}"])))
        for i in range(1, 14):
            text = profile[f"trigger_attr{i}"]
            if not text or data[3] < profile[f"trigger{i}"]:
                continue
            name, number = text.split(";")
            if name not in FIELDS:
                raise ValueError("装备进阶隐藏属性不支持")
            amount = Fraction(number)
            if FIELDS[name] < 10:
                base = battle.general_base(general, name, pb_get_varint(raw, 3), pb_get_varint(raw, 4) or 0, config)
                values[FIELDS[name]] += int(base * amount / 100)
            else:
                values[FIELDS[name]] += amount
        if row["suit"]:
            groups.setdefault(row["suit"], []).append(data)
    for sid, items in groups.items():
        row = config["suit"][str(sid)]
        levels = []
        for item in items:
            for part in range(1, 5):
                if item[1] in (row[f"id{part}"], row[f"6id{part}"], row[f"7id{part}"]):
                    base_quality = config["equip"][str(row[f"id{part}"])]["quality"]
                    level = score(item, config) - {5: 0, 6: 30, 7: 80}[base_quality]
                    levels.append(level)
                    break
        levels.sort(reverse=True)
        for count in (2, 3, 4):
            if len(levels) < count:
                continue
            tier = max((i for i in range(1, 14) if row[f"equip_evolve_{i}"] and levels[count-1] >= row[f"equip_evolve_{i}"]), default=0)
            text = row.get(f"{count}attr_{tier}") if tier else ""
            for entry in (text or row[f"{count}attr"]).split(";"):
                if not entry:
                    continue
                name, number = entry.split(",")
                if name not in FIELDS:
                    raise ValueError("装备套装属性不支持")
                values[FIELDS[name]] += Fraction(number) * (100 if FIELDS[name] >= 10 else 1)
    return values


def settle(save, config):
    """旧本地版本未计入的高阶装备属性，只在成功工作副本中补一次。"""
    from . import cheer, development, formation, player

    version = get_version(save)
    if version or not save.get("has_role"):
        return b""
    world = bytes.fromhex(save.get("world_state", {}).get("1002", ""))
    generals, equips, slots = formation.records(world, 1, 2), formation.records(world, 2, 1), formation.records(world, 4, 2)
    members, tiers = cheer.members(save, config), cheer.tiers(save, config)
    update, total = b"", 0
    for iid, slot in slots.items():
        if not iid:
            continue
        previous, old_relations = formation.bonuses(generals[iid], slot, members, equips, config, cheer_tiers=tiers, equip_growth=False)
        current, relations = formation.bonuses(generals[iid], slot, members, equips, config, cheer_tiers=tiers)
        changes = {field: current[field] - previous[field] for field in current if current[field] != previous[field]}
        if changes:
            raw, power = development.adjust(generals[iid], changes)
            total += power
            update += encode_pb_field(1, 2, raw)
            player.record_protagonist_general(save, raw)
        if relations != old_relations:
            updated_slot = b"".join(encode_pb_field(n, w, value) for n, w, value in iter_pb_fields(slot) if n != 3) + relations
            update += encode_pb_field(4, 2, updated_slot)
    if update:
        player.record_slot_update(save, update)
        player.record_slot_update(save, encode_pb_field(6, 2, bytes.fromhex(save["protagonist_snapshot"])))
        for key in ("power", "power_all"):
            save["role_state"][key] += total
            if not 0 <= save["role_state"][key] < (1 << 31):
                raise ValueError("装备进阶迁移后的角色战力超出范围")
    save["equip_evolve_version"] = 1
    return update


def costs(text):
    result = Counter()
    for entry in text.split(";"):
        if not entry:
            continue
        cid, count = map(int, entry.split(","))
        if not 0 < cid < (1 << 31) or not 0 < count < (1 << 31):
            raise ValueError("装备养成费用配置无效")
        result[cid] += count
    return result


def prepare(opcode, save, body, config):
    from . import cheer, equip_baptize, formation, qiankun, recharge, training

    fields = list(iter_pb_fields(body))
    if len(fields) != 1 or fields[0][:2] != (1, 0) or not 0 < fields[0][2] < (1 << 31):
        raise ValueError("装备养成需要唯一的目标IID")
    if (not save.get("has_role") or save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2
            or save["role_state"]["level"] < config["build"][str(150 if opcode == 1122 else 199)]["level"]):
        raise ValueError("装备进阶或升星尚未解锁")
    world = bytes.fromhex(save["world_state"]["1002"])
    equips, slots, cheers = formation.records(world, 2, 1), formation.records(world, 4, 1), formation.records(world, 5, 1)
    iid = fields[0][2]
    if iid not in equips:
        raise ValueError("装备不存在或不属于本人")
    item = parse_ids_pb(equips[iid])
    row = equip_baptize.validate(item, config)
    if row["type"] not in KINDS or not row["adorn"]:
        raise ValueError("请选择普通可穿戴装备，不是宝物或坐骑")
    if any(pb_get_varint(slot, n) == iid for slot in cheers.values() for n in range(4, 10)):
        raise ValueError("请先将装备从助阵位撤下")
    if str(iid) in equip_baptize.get_state(save, config)["pending"]:
        raise ValueError("请先处理本装备的洗炼预览")
    data, materials = item + [0] * (13 - len(item)), Counter()
    if opcode == 1123:
        following = config["equip_star"].get(str(data[11] + 1))
        if not following or data[11] >= row["up_star"] or not following.get(f'cost_{row["quality"]}'):
            raise ValueError("此装备不能继续升星")
        if data[2] < following["num"]:
            raise ValueError("装备强化等级不足以升星")
        price = costs(following[f'cost_{row["quality"]}'])
        data[11] += 1
    else:
        profile = config["equip_evolve"].get(str(data[1]))
        if not profile:
            raise ValueError("此装备没有进阶配置")
        level, cid = data[3] + 1, data[1]
        if data[3] >= profile["level"]:
            if not profile["evolve"]:
                raise ValueError("装备已达最高进阶")
            cid, level = profile["evolve"], 1
        target = config["equip"][str(cid)]
        gate = config["equip_evolvelv"][str(level)][f'lv{target["quality"]}']
        if gate <= 0 or save["role_state"]["level"] < gate:
            raise ValueError("队伍等级不足以进阶或转换此装备")
        rule = config["equip_evolvesuffix"][str(level)]
        if target["quality"] >= 6:
            suffix = "1" if target["quality"] == 7 else ""
            if data[11] < rule[f"star{suffix}_lv"] or data[2] < rule[f"intentify{suffix}_lv"]:
                raise ValueError("装备星级或强化等级不满足进阶条件")
        if target["quality"] == 7:
            worn = [(n, pb_get_varint(slot, n)) for slot in slots.values() if pb_get_varint(slot, 2) for n in range(4, 8)]
            if len(worn) != rule["num"] or len({e for n, e in worn}) != len(worn):
                raise ValueError("全阵28件实际穿戴装备尚未满足金装进阶门槛")
            for n, e in worn:
                if not e or e not in equips:
                    raise ValueError("全阵28件实际穿戴装备尚未满足金装进阶门槛")
                worn_item = parse_ids_pb(equips[e])
                worn_row = equip_baptize.validate(worn_item, config)
                if worn_row["type"] != KINDS[n-4] or score(worn_item, config) - 30 < rule["evolve_lv"]:
                    raise ValueError("全阵28件实际穿戴装备尚未满足金装进阶门槛")
        recipe = config["equip_evolveconsume"][str(cid)]
        if not recipe[f"consume{level}"]:
            raise ValueError("此进阶没有有效费用配置")
        price, materials = costs(recipe[f"consume{level}"]), costs(recipe[f"equip{level}"])
        data[1], data[3] = cid, level
    if not price or any(cid != 1000 and str(cid) not in config["props"] for cid in price):
        raise ValueError("装备养成货币/材料配置无效")
    props = formation.records(bytes.fromhex(save["world_state"]["1200"]), 1, 1)
    if any((save["role_state"]["coin"] if cid == 1000 else pb_get_varint(props.get(cid, b""), 2) or 0) < count for cid, count in price.items()):
        raise ValueError("装备养成银币或材料不足")
    occupied = {pb_get_varint(slot, n) for slot in (*slots.values(), *cheers.values()) for n in range(4, 10)}
    foods = []
    for cid, count in materials.items():
        available = [e for e, raw in sorted(equips.items()) if 0 < e < (1 << 31) and e != iid and e not in occupied
                     and all((n, w) == (1, 0) for n, w, value in iter_pb_fields(raw))
                     and (values := parse_ids_pb(raw))[1:3] == [cid, 1] and not any(values[3:])]
        if len(available) < count:
            raise ValueError("同名材料必须闲置且未经强化、洗炼、进阶、升星或注灵")
        foods.extend(available[:count])
    equip_baptize.validate(data, config)
    replacement = iter(data)
    changed = b"".join(encode_pb_field(n, w, next(replacement) if (n, w) == (1, 0) else value)
                       for n, w, value in iter_pb_fields(equips[iid])) + recharge.ids(replacement)
    generals, power = training.equip_differences(save, equips, {iid: changed}, config)
    qiankun.record_training(save, "equip", equips[iid], changed, [*price.items(), *materials.items()], item[2] == 1 and not any(item[3:]))
    for food in foods:
        qiankun.get_state(save)["receipts"].pop(f"equip:{food}", None)
        equip_baptize.get_state(save, config)["pending"].pop(str(food), None)
    current_equips = {**equips, iid: changed}
    current_generals = formation.records(generals, 8, 2)
    relations_update = {}
    for sid, slot in slots.items():
        if pb_get_varint(slot, 2) and any(pb_get_varint(slot, n) == iid for n in range(4, 8)):
            raw = current_generals[pb_get_varint(slot, 2)]
            _, relations = formation.bonuses(raw, slot, cheer.members(save, config), current_equips, config, cheer_tiers=cheer.tiers(save, config))
            relations_update[sid] = b"".join(encode_pb_field(n, w, value) for n, w, value in iter_pb_fields(slot) if n != 3) + relations
    save["world_state"]["1002"] = b"".join(encode_pb_field(n, w, relations_update.get(pb_get_varint(raw, 1), raw) if (n, w) == (4, 2) else raw)
        for n, w, raw in iter_pb_fields(world) if not ((n, w) == (2, 2) and pb_get_varint(raw, 1) in foods)).hex()
    return encode_pb_field(6, 2, changed) + generals + encode_pb_field(9, 2, recharge.ids(foods)), list(price.items()), power
