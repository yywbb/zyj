"""伙伴觉醒、进修和飞升；只在玩家事务副本上准备变化。"""

import random

from .protocol import encode_pb_field, iter_pb_fields, parse_ids_pb, pb_get_varint, pb_set_varint

QUERIES = (5511, 5512)
MUTATIONS = (1025, 5513, 7001)
FAIRY = {"g_hp": 24, "g_def": 25, "g_atk": 26, "g_critical": 27, "g_dodge": 28,
         "g_parry": 29, "g_resilience": 30, "g_hit": 31, "g_arp": 32, "g_criticaldmg": 33}


def pairs(text):
    return [tuple(map(int, entry.split(","))) for entry in text.split(";") if entry]


def state(save, config):
    result = save.get("partner_growth_state", {"research": {}, "serial": 0, "checked_at": 0})
    if (not isinstance(result, dict) or not isinstance(result.get("research"), dict)
            or any(type(result.get(k)) is not int or not 0 <= result[k] < 1 << (31 if k == "serial" else 63) for k in ("serial", "checked_at"))):
        raise ValueError("伙伴成长存档无效")
    for iid, values in result["research"].items():
        if (not isinstance(iid, str) or not iid.isdecimal() or not 0 < int(iid) < 1 << 31
                or not isinstance(values, list) or len(values) != 10
                or any(type(v) is not int or not 0 <= v < 1 << 31 for v in values)):
            raise ValueError("伙伴进修存档无效")
        for offset, kind in ((0, "1"), (5, "2")):
            row = config["Immortal_level"][kind].get(str(values[offset]))
            if not row or values[offset+4] != sum(values[offset+1:offset+4]) or values[offset+4] > row["character"]:
                raise ValueError("伙伴进修等级或心性无效")
    return result


def research(save, iid, config):
    return state(save, config)["research"].get(str(iid), [0] * 10)[:]


def remove(save, iid):
    current = save.get("partner_growth_state")
    if current and str(iid) in current["research"]:
        if current["serial"] >= (1 << 31)-1:
            raise ValueError("伙伴进修序号已达上限，未移除或重生")
        del current["research"][str(iid)]
        current["serial"] += 1


def validate(raw, config):
    row = config["general"].get(str(pb_get_varint(raw, 1)), {})
    if (not row.get("battle") or not row.get("init_cid") or row.get("actor") == "lead"
            or row.get("partner_id") or row.get("quality") not in range(3, 8)
            or not 0 <= (pb_get_varint(raw, 4) or 0) <= min(16, row.get("breach_upper_limit", 10))
            or any(pb_get_varint(raw, n) for n in (21, 22, 38, 39))
            or any(any(parse_ids_pb(v)) for n, w, v in iter_pb_fields(raw) if (n, w) == (41, 2))):
        raise ValueError("此伙伴包含尚未接通的升星、幻化或高级属性")
    awake = pb_get_varint(raw, 18) or 0
    if awake and (str(awake) not in config["general_awaken"] or not row.get("awaken")):
        raise ValueError("伙伴觉醒等级无效")
    expected = fairy(raw, config)
    if any((pb_get_varint(raw, f) or 0) != expected[f] for f in FAIRY.values()):
        raise ValueError("伙伴仙属性与实际成长不一致")
    if (pb_get_varint(raw, 34) or 0) != expected[25]+expected[26]+expected[24]//10:
        raise ValueError("伙伴仙战力与实际成长不一致")
    stages = max(0, (pb_get_varint(raw, 4) or 0)-13)
    packed = sum((pb_get_varint(raw, 35+i) or 0)*10**(2-i) for i in range(3))
    camp = config["jinjiangkezhiguanxi"].get(str(packed), {}).get("camp", 0)
    if (any(pb_get_varint(raw, n) for n in range(35+stages, 38))
            or (pb_get_varint(raw, 40) or 0) != camp):
        raise ValueError("伙伴彩金技能记录无效")
    return row


def awakened(raw, config):
    row = config["general"][str(pb_get_varint(raw, 1))]
    level = pb_get_varint(raw, 18) or 0
    data = config["general_awakenattr"].get(str(row.get("awaken")), {}).get(str(level), {})
    return {f: data.get("awaken_"+name, 0) for name, f in (("atk", 6), ("def", 7), ("hp", 8), ("hit", 14))}


def fairy(raw, config):
    row = config["general"][str(pb_get_varint(raw, 1))]
    origin = config["general"][str(row["init_cid"])]
    level = pb_get_varint(raw, 23) or 0
    result = {f: 0 for f in FAIRY.values()}
    if level:
        data = config["partner_soaring"].get(str(level))
        if not data or not row.get("soaring") or str(origin["basic"])+"consume" not in data:
            raise ValueError("伙伴飞升等级无效")
        for name, f in (("xianhp", 24), ("xiandef", 25), ("xianadk", 26)):
            result[f] += data[str(origin["basic"])+name]
    for stage in range(1, max(0, (pb_get_varint(raw, 4) or 0)-13)+1):
        choice = pb_get_varint(raw, 34+stage) or 0
        if choice not in (1, 2, 3) or not row.get(f"gold{stage}_will_skills_{choice}"):
            raise ValueError("彩金突破技能选择无效")
        for entry in row[f"gold{stage}_will_attribute"].split(";"):
            if entry:
                name, amount = entry.split(",")
                result[FAIRY[name]] += int(amount)
    return result


def skills(raw, config):
    row = config["general"][str(pb_get_varint(raw, 1))]
    return [row[f'gold{i}_will_skills_{pb_get_varint(raw, 34+i)}']
            for i in range(1, max(0, (pb_get_varint(raw, 4) or 0)-13)+1)]


def check_combat(raw, config):
    from . import battle
    row = config["general"][str(pb_get_varint(raw, 1))]
    unit = {name: pb_get_varint(raw, f) or 0 for name, f in battle.GENERAL_FIELDS.items()}
    unit.update(skill=row["skillid"], skilllevel=0, partner_skills=skills(raw, config))
    battle._prepare_teams({True: {2: unit.copy()}, False: {2: unit.copy()}}, config)


def rebase(save, raw, changed, config):
    from . import battle, cheer, development, formation
    world = bytes.fromhex(save["world_state"]["1002"])
    iid = pb_get_varint(raw, 2)
    slots, equips = formation.records(world, 4, 2), formation.records(world, 2, 1)
    members, tiers = cheer.members(save, config), cheer.tiers(save, config)
    changes = {f: 0 for f in range(6, 17)}
    for before, sign in ((raw, -1), (changed, 1)):
        row = config["general"][str(pb_get_varint(before, 1))]
        level, advance = pb_get_varint(before, 3), pb_get_varint(before, 4) or 0
        bonuses, _ = formation.bonuses(before, slots.get(iid, b""), members, equips, config, cheer_tiers=tiers)
        permanent = battle.self_stats(row, level, advance, config)
        wake = awakened(before, config)
        for name, f in (("atk", 6), ("def", 7), ("hp", 8), ("speed", 9)):
            changes[f] += sign * int(battle.general_base(row, name, level, advance, config))
        for f in changes:
            changes[f] += sign * (bonuses[f] + permanent[f] + wake.get(f, 0))
    return development.adjust(changed, changes)[0]


def breakthrough(save, raw, scope, config, *, preview=False):
    row = validate(raw, config)
    target = (pb_get_varint(raw, 4) or 0)+1
    if target > min(16, row.get("breach_upper_limit", 10)):
        raise ValueError("此伙伴已达突破上限")
    cid = pb_get_varint(raw, 1)
    if target == 11 and row["quality"] < 6:
        cid = row.get("break_id", 0)
    if target == 14 and row["quality"] < 7:
        cid = row.get("gold_id", 0)
    new = config["general"].get(str(cid), {})
    if not new or new.get("init_cid") != row["init_cid"] or target >= 11 and new["quality"] != (7 if target >= 14 else 6):
        raise ValueError("此伙伴没有对应的红将或彩金转换配置")
    step = config["general_awake"][str(target)]
    if not preview:
        if ((pb_get_varint(raw, 3) or 0) < step["level"] or (pb_get_varint(raw, 18) or 0) < step["awaken_lv"]
                or (pb_get_varint(raw, 23) or 0) < step["soaring_limit"]):
            raise ValueError("伙伴等级、觉醒或飞升不足以突破")
    changed = pb_set_varint(pb_set_varint(raw, 1, cid), 4, target)
    if target >= 14:
        stage = target-13
        options = [i for i in (1, 2, 3) if new.get(f"gold{stage}_will_skills_{i}")]
        if preview:
            scope = options[0] if options else 0
        if scope not in options:
            raise ValueError("请选择本阶有效的彩金突破技能")
        changed = pb_set_varint(changed, 34+stage, scope)
        packed = sum((pb_get_varint(changed, 35+i) or 0)*10**(2-i) for i in range(3))
        changed = pb_set_varint(changed, 40, config["jinjiangkezhiguanxi"][str(packed)]["camp"])
    elif scope:
        raise ValueError("普通或红将突破不接受彩金技能选择")
    for f, value in fairy(changed, config).items():
        changed = pb_set_varint(changed, f, value)
    changed = rebase(save, raw, changed, config)
    quality = new["quality"]
    costs = [(1000, step[f"coin{quality}"]), (20017, step[f"{quality}prop"])]
    if step[f"{quality}piece"]:
        fragment = next(r["id"] for r in config["general_fragment"].values() if r["general"] == row["init_cid"])
        costs.append((fragment, step[f"{quality}piece"]))
    if step["red_item"]:
        red = cid if new["quality"] == 6 else new.get("red_id")
        fragment = next((r["id"] for r in config["redl_awake_item"].values() if r["red_id"] == red), None)
        if fragment is None:
            raise ValueError("伙伴精华配置缺失")
        costs.append((fragment, step["red_item"]))
    costs += [(20354, step["red_cost"]), (20551, step["red_cost2"]), *pairs(step["gold_cost"])]
    if not preview:
        check_combat(changed, config)
    return changed, [(cid, count) for cid, count in costs if count]


def research_stats(values, config):
    stats = {"hp": 0, "atk": 0, "def": 0, "adddmg": 0, "subdmg": 0}
    for offset, kind in ((0, "1"), (5, "2")):
        for i in range(1, 4):
            name, scale = config["Immortal_type"][kind][f"attr{i}"].split(",")
            stats[name] += values[offset+i] * int(scale)
        for level in range(values[offset]):
            row = config["Immortal_level"][kind][str(level)]
            for i in range(1, 4):
                name, amount = row[f"stageAttr{i}"].split(",")
                stats[name] += int(amount)
    return stats


def power(save, raw, changed):
    from . import formation
    score = sum(pb_get_varint(changed, f) or 0 for f in (25, 26)) + (pb_get_varint(changed, 24) or 0)//10
    changed = pb_set_varint(changed, 34, score)
    active = formation.records(bytes.fromhex(save["world_state"]["1002"]), 4, 2)
    if pb_get_varint(raw, 2) in active:
        ordinary = (pb_get_varint(changed, 20) or 0)-(pb_get_varint(raw, 20) or 0)
        fairy_delta = score-(pb_get_varint(raw, 34) or 0)
        for key, delta in (("power", ordinary), ("g_power", fairy_delta), ("power_all", ordinary+fairy_delta)):
            value = save["role_state"][key]+delta
            if not 0 <= value < 1 << 31:
                raise ValueError("伙伴成长后的角色战力超出范围")
            save["role_state"][key] = value
    if not 0 <= score < 1 << 31 or not 0 <= (pb_get_varint(changed, 20) or 0) < 1 << 31 or score+(pb_get_varint(changed, 20) or 0) >= 1 << 31:
        raise ValueError("伙伴成长战力超出范围")
    return changed


def prepare(opcode, save, body, config, now, seed):
    from . import development, formation, general_foster, recharge
    values = development.ids(body)
    current = state(save, config)
    world = bytes.fromhex(save["world_state"]["1002"])
    generals = formation.records(world, 1, 2)
    if opcode == 5511:
        if values:
            raise ValueError("伙伴进修等级查询不接受参数")
        if not save.get("has_role"):
            return b"", [], b""
        return recharge.ids(v for iid in sorted(generals) for v in (iid, *research(save, iid, config)[::5])), [], b""
    if not save.get("has_role") or not values or values[0] not in generals:
        raise ValueError("伙伴不存在或不属于当前账号")
    iid, raw = values[0], generals[values[0]]
    row = validate(raw, config)
    progress = research(save, iid, config)
    if opcode == 5512:
        if len(values) != 1:
            raise ValueError("伙伴进修查询只接受IID")
        return recharge.ids([*progress, current["serial"]]), [], b""
    if (not save.get("has_role") or save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2
            or now < current["checked_at"]):
        raise ValueError("请完成引导并校准时间后培养伙伴")
    changed, costs = raw, []
    if opcode == 1025:
        awake = pb_get_varint(raw, 18) or 0
        if values != [iid, awake] or not row.get("awaken"):
            raise ValueError("觉醒目标已变化，请重新打开当前伙伴")
        origin = config["general"][str(row["init_cid"])]
        base = int(config["global_kv"].get(f'general_awaken{origin["basic"]}', {"value": "0"})["value"])
        target = max(awake, base)+1
        step = config["general_awaken"].get(str(target))
        if (save["role_state"]["level"] < config["build"]["174"]["level"] or not step
                or pb_get_varint(raw, 3) < step["lv"] or (pb_get_varint(raw, 4) or 0) < step["breach"]):
            raise ValueError("伙伴觉醒已满级或等级、突破条件不足")
        costs = pairs(step["consume1"])+pairs(step.get(f'consume_{origin["basic"]}', ""))
        if step["number"]:
            fragment = next(r["id"] for r in config["general_fragment"].values() if r["general"] == row["init_cid"])
            costs.append((fragment, step["number"]))
        changed = rebase(save, raw, pb_set_varint(raw, 18, target), config)
    elif opcode == 7001:
        level = pb_get_varint(raw, 23) or 0
        step = config["partner_soaring"].get(str(level+1))
        if values != [iid, level] or not step or not row.get("soaring"):
            raise ValueError("飞升目标已变化或已满级")
        if (save["role_state"]["level"] < config["build"]["449"]["level"] or pb_get_varint(raw, 4) < step["breach"]
                or min(progress[0], progress[5]) < step["immortal"]):
            raise ValueError("飞升需要对应突破等级及文理科进修")
        origin = config["general"][str(row["init_cid"])]
        costs = pairs(step[str(origin["basic"])+"consume"])
        changed = pb_set_varint(raw, 23, level+1)
        for f, value in fairy(changed, config).items():
            changed = pb_set_varint(changed, f, value)
        previous = config["partner_soaring"][str(level)][str(origin["basic"])+"speed"]
        changed = development.adjust(changed, {9: step[str(origin["basic"])+"speed"]-previous})[0]
    elif opcode == 5513:
        if len(values) != 6 or values[1] not in (1, 2) or values[2] not in (0, 1):
            raise ValueError("进修需要类型、方式、显示等级、心性和序号")
        _, kind, method, level, heart, serial = values
        offset = (kind-1)*5
        step = config["Immortal_level"][str(kind)][str(progress[offset])]
        if (save["role_state"]["level"] < config["build"]["378"]["level"] or pb_get_varint(raw, 3) < step["generalLevel"]
                or [level, heart, serial] != [progress[offset], progress[offset+4], current["serial"]]
                or method != int(heart == step["character"])):
            raise ValueError("进修条件不足或目标已变化，请刷新")
        before = research_stats(progress, config)
        costs = pairs(step["extraConsume"] if method else step["consumeEveryTimes"])
        if method:
            if str(level+1) not in config["Immortal_level"][str(kind)]:
                raise ValueError("伙伴进修已满级")
            progress[offset:offset+5] = [level+1, 0, 0, 0, 0]
        else:
            rng = random.Random(seed)
            attributes = config["Immortal_type"][str(kind)]
            for _ in range(dict(costs)[int(step["consumeItem"])]):
                disparity = max(progress[offset+1:offset+4])-min(progress[offset+1:offset+4])
                table = max((r for r in config["Immortal_probability"].values() if r["disparity"] <= disparity), key=lambda r: r["disparity"])
                points = rng.choices(range(10), [table[f"pro2_{i}"] for i in range(10)])[0]
                points = min(points, step["character"]-progress[offset+4])
                attr = rng.choices((1, 2, 3), [attributes[f"attr{i}_weight"] for i in (1, 2, 3)])[0]
                progress[offset+attr] += points
                progress[offset+4] += points
        after = research_stats(progress, config)
        changes = {f: after[name]-before[name] for name, f in (("atk", 6), ("def", 7), ("hp", 8))}
        changed = development.adjust(raw, changes)[0]
        changed = pb_set_varint(changed, 20, (pb_get_varint(changed, 20) or 0)+sum(after[n]-before[n] for n in ("adddmg", "subdmg")))
        current["research"][str(iid)] = progress
    if opcode == 5513:
        current["serial"] += 1
    current["checked_at"] = now
    save["partner_growth_state"] = current
    state(save, config)
    changed = power(save, raw, changed)
    update = encode_pb_field(1, 2, changed)
    reply = general_foster.comb(((0, update), (1, recharge.ids([*progress, current["serial"]])))) if opcode == 5513 else update
    return reply, costs, update
