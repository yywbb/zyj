"""普通/金光神器；在角色工作副本上准备养成、实际消耗和安全返还。"""

from collections import Counter
import copy
from fractions import Fraction
import random

from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint, pb_set_varint

QUERIES = (5509,)
MUTATIONS = (5501, 5502, 5503, 5504, 5505, 5506, 5507, 5508, 5515, 5516, 5517, 5518, 5519, 5520,
             5540, 5541, 5542, 5543, 5544, 5545, 5546)
OPCODES = QUERIES + MUTATIONS
GROWTH = set(MUTATIONS) - {5501, 5503, 5508, 5515, 5516}
FIELDS = {"atk": 6, "def": 7, "hp": 8, "speed": 9, "critical": 10, "dodge": 11,
          "resilience": 13, "hit": 14, "criticaldmg": 16}
MAX_RETURN_ARTIFACTS = 10000


def iid(raw):
    first = next((v for n, w, v in iter_pb_fields(raw) if (n, w) == (1, 2)), b"")
    value = pb_get_varint(first, 1)
    if type(value) is not int or not 0 < value < (1 << 31):
        raise ValueError("神器缺少有效IID")
    return value


def values(raw):
    result = []
    for n, w, data in iter_pb_fields(raw):
        if (n, w) != (1, 2):
            continue
        text = next((v for f, t, v in iter_pb_fields(data) if (f, t) == (2, 2)), None)
        number = pb_get_varint(data, 1) or 0
        result.append(text.decode("utf-8") if text is not None else number - (1 << 64) if number >= (1 << 63) else number)
    if len(result) < 29:
        raise ValueError("神器存档缺少原生属性")
    return result + [0] * max(0, 33 - len(result))


def record(data):
    return b"".join(encode_pb_field(1, 2, encode_pb_field(2, 2, v.encode("utf-8")) if isinstance(v, str)
                                    else encode_pb_field(1, 0, v & ((1 << 64) - 1))) for v in data)


def replace(raw, changes):
    index, result = 0, b""
    for n, w, data in iter_pb_fields(raw):
        if (n, w) == (1, 2):
            index += 1
            if index in changes:
                value = changes[index]
                data = (encode_pb_field(2, 2, value.encode("utf-8")) if isinstance(value, str)
                        else encode_pb_field(1, 0, value & ((1 << 64)-1))) + b"".join(
                            encode_pb_field(f, t, v) for f, t, v in iter_pb_fields(data) if f not in (1, 2))
        result += encode_pb_field(n, w, data)
    for position in range(index+1, max(changes, default=index)+1):
        result += record([changes.get(position, 0)])
    return result


def read_world(save, config):
    from . import formation

    world = bytes.fromhex(save["world_state"]["1002"])
    items, gems = {}, set()
    for n, w, raw in iter_pb_fields(world):
        if (n, w) == (17, 2):
            gem = [v for f, t, v in iter_pb_fields(raw) if (f, t) == (1, 0)]
            if (len(gem) != 2 or gem[0] in gems or str(gem[0]) not in config["trump_gem"]
                    or not 0 <= gem[1] < (1 << 31) or any(f == 1 and t != 0 for f, t, _ in iter_pb_fields(raw))):
                raise ValueError("神器宝石库存记录无效或重复")
            gems.add(gem[0])
        if (n, w) != (16, 2):
            continue
        key, data = iid(raw), values(raw)
        if (key in items or str(data[1]) not in config["trump"] or not isinstance(data[2], str)
                or any(type(data[i]) is not int or not 0 <= data[i] < (1 << 31) for i in (3, 4, 5, 6, 7, 8, 13, 14, 27, 28))
                or data[5] not in (0, 1) or data[27] not in (0, 1)):
            raise ValueError("神器存档属性或IID无效")
        validate(raw, config)
        items[key] = raw
    slots = formation.records(world, 4, 1)
    worn = set()
    for slot in slots.values():
        key = pb_get_varint(slot, 26) or 0
        if key:
            if key not in items or key in worn or values(items[key])[5] != 1:
                raise ValueError("神器穿戴记录无效")
            worn.add(key)
    return items, slots


def get_state(save, config):
    items, _ = read_world(save, config)
    state = save.get("artifact_state", {"serial": max([6000000, *items]), "checked_at": 0})
    if (not isinstance(state, dict) or type(state.get("serial")) is not int
            or not max([0, *items]) <= state["serial"] < (1 << 31)
            or type(state.get("checked_at")) is not int or not 0 <= state["checked_at"] < (1 << 63)):
        raise ValueError("神器序号或时钟无效")
    entries = state.get("items", {})
    if not isinstance(entries, dict):
        raise ValueError("神器养成记录无效")
    for key, entry in entries.items():
        if not isinstance(key, str) or not key.isdecimal() or int(key) not in items or not isinstance(entry, dict):
            raise ValueError("神器养成对象无效")
        data = values(items[int(key)])
        row = config["trump"][str(data[1])]
        if "strength" in entry:
            growth = entry["strength"]
            if (not isinstance(growth, dict) or type(growth.get("level")) is not int
                    or growth["level"] != values(items[int(key)])[13]):
                raise ValueError("神器强化消耗记录与等级不一致")
            checked_pairs(growth.get("costs"), config, returns=True)
            if not growth["costs"] or any(cid != row["return"] for cid, _ in growth["costs"]):
                raise ValueError("神器强化返还物与种类不匹配")
        holes = entry.get("holes", {})
        if not isinstance(holes, dict) or any(p not in ("1", "2", "3", "4") for p in holes):
            raise ValueError("神器开孔消耗记录无效")
        for position, costs in holes.items():
            checked_pairs(costs, config)
            if data[8+int(position)] < 0 or costs != [list(p) for p in deck(row[f"hole_cost{position}"])]:
                raise ValueError("神器开孔记录与当前孔位不匹配")
        rolls = entry.get("rolls", [0, 0])
        if not isinstance(rolls, list) or len(rolls) != 2 or any(type(v) is not int or not 0 <= v < (1 << 31) for v in rolls):
            raise ValueError("神器洗炼次数记录无效")
        if "pending" in entry:
            pending = entry["pending"]
            if (not isinstance(pending, list) or len(pending) != 3 or not any(pending)
                    or pending != values(items[int(key)])[18:21]):
                raise ValueError("神器洗炼预览记录无效")
            skill_effects(str(config["trump"][str(values(items[int(key)])[1])]["type"]), pending, config)
    return state


def checked_pairs(pairs, config, *, returns=False):
    if (not isinstance(pairs, list) or len(pairs) > 100 or any(
            not isinstance(p, (list, tuple)) or len(p) != 2 or type(p[0]) is not int or type(p[1]) is not int
            or not 0 < p[1] < (1 << 31)
            or str(p[0]) not in (config["trump"] if returns else config["props"])
            or returns and config["trump"][str(p[0])]["appraiseMethod"]
            for p in pairs) or len({p[0] for p in pairs}) != len(pairs)):
        raise ValueError("神器实际消耗记录无效")
    if returns and sum(n for _, n in pairs) > MAX_RETURN_ARTIFACTS:
        raise ValueError("神器单次返还数量超出安全范围")
    return pairs


def choose(entries, rng):
    weights = [Fraction(str(w)) for _, w in entries]
    if not entries or any(w < 0 or w.denominator != 1 for w in weights) or sum(weights) <= 0:
        raise ValueError("神器随机权重配置无效")
    ticket = rng.randrange(int(sum(weights)))
    for (value, _), weight in zip(entries, weights):
        ticket -= weight
        if ticket < 0:
            return value


def deck(text):
    if not text:
        return []
    entries = [tuple(map(int, v.split(","))) for v in text.strip(";").split(";")]
    if any(len(v) != 2 or v[0] <= 0 for v in entries):
        raise ValueError("神器属性/费用配置无效")
    return entries


def time_status(config, now):
    durations = [config["trump_timeweight"][str(i)]["min"] * 60 for i in range(1, 13)]
    if any(type(v) is not int or v <= 0 for v in durations):
        raise ValueError("神器时辰配置无效")
    elapsed = (now + 28800) % sum(durations)
    for i, duration in enumerate(durations, 1):
        if elapsed < duration:
            return i, duration - elapsed
        elapsed -= duration


def skills(raw, config):
    data = values(raw)
    kind = str(config["trump"][str(data[1])]["type"])
    return skill_effects(kind, data[6:9], config)


def skill_effects(kind, ids, config):
    pool = config.get("trump_washing_skill", config["trump_skillRnd"])[kind]
    allowed = {row[f"skill{i}"]: (row, i) for row in pool.values() for i in range(1, 7)}
    result, mutex = {}, set()
    for sid in ids:
        if sid == 0:
            continue
        if type(sid) is not int or sid not in allowed:
            raise ValueError("神器特性不属于当前类型")
        row, _ = allowed[sid]
        if row["metux"] in mutex:
            raise ValueError("神器特性互斥")
        mutex.add(row["metux"])
        result[row["name"]] = config["breakskill"][str(sid)]
    return result


def combat_effects(data, config):
    if data is None:
        return {}
    if (not isinstance(data, dict) or type(data.get("cid")) is not int or str(data["cid"]) not in config["trump"]
            or type(data.get("level")) is not int or not 0 <= data["level"] <= 30
            or type(data.get("stats_applied", False)) is not bool
            or not isinstance(data.get("skills"), list) or len(data["skills"]) > 3
            or any(type(sid) is not int or sid <= 0 for sid in data["skills"])):
        raise ValueError("战斗神器数据无效")
    if not 0 <= Fraction(str(data.get("shield_damage", 0))) <= 2:
        raise ValueError("神器魔罩增伤无效")
    return skill_effects(str(config["trump"][str(data["cid"])]["type"]), data["skills"], config)


def strength_row(data, config, level=None):
    row = config["trump"][str(data[1])]
    return config["trump_Godstrengthen" if row["goldTrump"] else "trump_strengthen"][str(row["type"])].get(
        str(data[13] if level is None else level))


def strength_attributes(data, config):
    row = strength_row(data, config)
    return {name: Fraction(row[f"attr{i}Value"] * data[3], 100) if row else Fraction(0)
            for i, name in enumerate(("atk", "def", "hp"), 1)}


def resonance(ids, config):
    rows = config.get("resonance_attribute", {})
    pairs = sorted((r for r in rows.get("1", {}).values() if r["skills1"] in ids and r["skills2"] in ids),
                   key=lambda r: (r["sorting"], r["id"]))
    count = sum(config["breakskill"][str(s)]["quality"] >= 6 for s in ids if s)
    return pairs, rows.get("2", {}).get(str(count))


def validate(raw, config):
    data = values(raw)
    if (data[13] not in range(31) or not 0 <= data[14] <= 1000
            or len(data) > 33 and (type(data[33]) is not int or not 0 <= data[33] < (1 << 31))
            or any(v not in (0, "0", "") for v in data[34:])
            or any(type(v) is not int or v < -1 or v >= (1 << 31) for v in data[9:13]+data[18:27])
            or any(v not in (-1, 0, 1, 2) for v in data[21:24])
            or any(data[21+i] == 2 and not data[6+i] for i in range(3))
            or any(v > 100 for v in data[24:27])):
        raise ValueError("神器养成属性无效")
    if data[13] and not strength_row(data, config):
        raise ValueError("神器强化等级配置不存在")
    try:
        cached = [Fraction(str(v)) for v in data[15:18]]
    except (ValueError, ZeroDivisionError):
        raise ValueError("神器强化属性无效") from None
    if any(v < 0 or v > 100 for v in cached):
        raise ValueError("神器强化属性超出范围")
    if data[5]:
        skills(raw, config)
    elif any(data[i] for i in (3, 4, 6, 7, 8, 13, 14)):
        raise ValueError("未鉴定神器不能含有成长属性")
    kinds = set()
    for cid in data[9:13]:
        if cid <= 0:
            continue
        row = config["trump_gem"].get(str(cid))
        if not row or row["type"] in kinds:
            raise ValueError("神器宝石无效或同类重复镶嵌")
        kinds.add(row["type"])
    return data


def canonical(raw, config, *, bump=False):
    data = values(raw)
    changes = {}
    for i, name in enumerate(("hp", "atk", "def"), 16):
        changes[i] = format(float(strength_attributes(data, config)[name]), ".12g")
    for i in range(3):
        if data[6+i] and data[21+i] <= 0:
            changes[22+i] = 1
        if data[24+i] == 0:
            changes[25+i] = int(Fraction(config["trump_config"][f"skill_success_{i+1}"]["value"])*100)
    pairs, reds = resonance(data[6:9], config)
    for i in range(3):
        changes[30+i] = pairs[i]["id"] if i < len(pairs) else 0
    changes[33] = reds["id"] if reds else 0
    if data[5]:
        score = sum(config["trump_rank"].get(str(v), {}).get("score", 0) for v in data[3:5])
        selected = [s for s in data[6:9] if s]
        score += int(sum(config["breakskill"][str(s)]["integral"] for s in selected)
                     * Fraction(str(config["trump_numskill"][str(len(selected)+1)]["weight"])))
        changes[29] = score + sum(r["score"] for r in pairs)
        if not 0 <= changes[29] < (1 << 31):
            raise ValueError("神器积分超出范围")
    if bump:
        changes[34] = (data[33] if len(data) > 33 else 0)+1
        if changes[34] >= (1 << 31):
            raise ValueError("神器状态序号超出范围")
    return replace(raw, changes)


def shield_damage(raw, config):
    return sum((Fraction(str(config["trump_gem"][str(cid)]["attrValue"]))/100
                for cid in values(raw)[9:13] if cid > 0
                and config["trump_gem"][str(cid)]["attr"] == "mozhao_resilience"), Fraction(0))


def attributes(raw, item, config):
    from . import battle

    result = dict.fromkeys(FIELDS.values(), 0)
    if not item:
        return result
    data = values(item)
    row = config["trump"][str(data[1])]
    if not data[5]:
        return result
    general = config["general"][str(pb_get_varint(raw, 1))]
    for i in (1, 2):
        name, method = row[f"attr{i}"], row[f"attr{i}Type"]
        if name not in FIELDS or method not in ("percent", "value"):
            raise ValueError("神器基础属性配置无效")
        base = battle.general_base(general, name, pb_get_varint(raw, 3), pb_get_varint(raw, 4) or 0, config)
        result[FIELDS[name]] += base * data[i+2] // 100 if method == "percent" else data[i+2]
    for name, percent in strength_attributes(data, config).items():
        base = battle.general_base(general, name, pb_get_varint(raw, 3), pb_get_varint(raw, 4) or 0, config)
        result[FIELDS[name]] += base * percent // 100
    for cid in data[9:13]:
        if cid > 0:
            gem = config["trump_gem"][str(cid)]
            if gem["attr"] in FIELDS:
                result[FIELDS[gem["attr"]]] += int(Fraction(str(gem["attrValue"])))
    for effect in skills(item, config).values():
        if effect["type"] == 0:
            if effect["attr"] not in FIELDS or effect["method"] != "value":
                raise ValueError("神器静态特性配置无效")
            result[FIELDS[effect["attr"]]] += int(Fraction(str(effect["value"])))
    pairs, reds = resonance(data[6:9], config)
    for row in [*pairs, *([reds] if reds else [])]:
        if row["type2"] not in FIELDS:
            raise ValueError("神器共鸣属性配置无效")
        result[FIELDS[row["type2"]]] += row["attribute"]
    return result


def assigned(save, config):
    items, slots = read_world(save, config)
    return {pb_get_varint(slot, 2): items[pb_get_varint(slot, 26)] for slot in slots.values()
            if pb_get_varint(slot, 2) and pb_get_varint(slot, 26)}


def require_plain(data):
    if (data[13] or data[14] or any(v not in (0, "0") for v in data[15:18])
            or any(v > 0 for v in data[9:13]) or any(v > 0 for v in data[18:21]) or any(data[29:33])):
        raise ValueError("未鉴定神器不能含有高级养成数据")


def differences(save, previous, config):
    from . import development, formation

    old, new = assigned(previous, config), assigned(save, config)
    before = formation.records(bytes.fromhex(previous["world_state"]["1002"]), 1, 2)
    current = formation.records(bytes.fromhex(save["world_state"]["1002"]), 1, 2)
    active = {pb_get_varint(v, 2) for v in formation.records(bytes.fromhex(save["world_state"]["1002"]), 4, 1).values()}
    update, power = b"", 0
    for key in sorted((old.keys() | new.keys()) & current.keys()):
        a = attributes(before[key], old.get(key), config)
        b = attributes(current[key], new.get(key), config)
        changes = {f: b[f] - a[f] for f in a}
        if not any(changes.values()):
            continue
        raw, delta = development.adjust(current[key], changes)
        receipt = save.get("qiankun_state", {}).get("receipts", {}).get(f"general:{key}")
        if receipt and receipt["after"] == current[key].hex():
            baseline = bytes.fromhex(receipt["before"])
            a, b = attributes(baseline, old.get(key), config), attributes(baseline, new.get(key), config)
            baseline, _ = development.adjust(baseline, {f: b[f]-a[f] for f in a})
            receipt.update(before=baseline.hex(), after=raw.hex())
        update += encode_pb_field(1, 2, raw)
        if key in active:
            power += delta
    return update, power


def appraise(raw, prop, config, now, rng):
    data = values(raw)
    row = config["trump"][str(data[1])]
    if data[5] or str(prop) not in config["trump_autweight"] or row["goldTrump"] and prop != int(row["appraiseMethod"]):
        raise ValueError("神器已鉴定或鉴定符类型不符")
    require_plain(data)
    weight = config["trump_autweight"][str(prop)]
    hour = config["trump_timeweight"][str(time_status(config, now)[0])]
    def weighted(prefix, indices):
        return choose([(i, Fraction(str(weight[f"{prefix}{i}"])) + (Fraction(str(hour[f"{prefix}{i}"])) if weight["ifTimeBuff"] else 0)) for i in indices], rng)
    changes = {4: choose(deck(row["attr1Value"]), rng), 5: choose(deck(row["attr2Value"]), rng), 6: 1}
    count = weighted("weight", range(4))
    candidates = sorted(config["trump_skillRnd"][str(row["type"])].values(), key=lambda r: r["id"])
    for i in range(1, 4):
        changes[6+i] = 0
        if i <= count:
            selected = choose([(r, r["weight"]) for r in candidates], rng)
            changes[6+i] = selected[f"skill{weighted('weight_', range(1, 7))}"]
            candidates = [r for r in candidates if r["metux"] != selected["metux"]]
    base = config["trump_rank"][str(changes[4])]["score"] + config["trump_rank"][str(changes[5])]["score"]
    integral = sum(config["breakskill"][str(changes[6+i])]["integral"] for i in range(1, count+1))
    factor = Fraction(str(config["trump_numskill"][str(count+1)]["weight"]))
    changes[29] = base + int(integral * factor)
    if not 0 <= changes[29] < (1 << 31):
        raise ValueError("神器积分超出范围")
    return canonical(replace(raw, changes), config, bump=True)


def new_item(row, name, state, config, *, returned=False):
    state["serial"] += 1
    if state["serial"] >= (1 << 31):
        raise ValueError("神器IID超出范围")
    data = [state["serial"], row["id"], name, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1,
            0, 0, "0", "0", "0", 0, 0, 0, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    if returned:
        data[3:6] = [deck(row["attr1Value"])[0][0], deck(row["attr2Value"])[0][0], 1]
    return canonical(record(data), config)


def growth_request(opcode, request, items):
    # 新养成请求携带每个对象的显示版本；旧页/跨重连重放不能再次扣料。
    if len(request) < 2 or request[0] != 0 or not 0 <= request[1] <= 30:
        raise ValueError("神器页面版本过旧，请更新客户端")
    count = request[1]
    if len(request) < 2+2*count:
        raise ValueError("神器显示状态不完整")
    pairs = request[2:2+2*count]
    versions = dict(zip(pairs[::2], pairs[1::2]))
    args = request[2+2*count:]
    if len(versions) != count:
        raise ValueError("神器对象重复")
    expected = (args if opcode in (5502, 5519) else args[:-1] if opcode == 5517
                else args[:2] if opcode in (5545, 5546) else [] if opcode == 5507 else args[:1])
    if len(set(expected)) != len(expected) or set(versions) != set(expected):
        raise ValueError("神器对象与显示版本不匹配")
    for key, version in versions.items():
        if key not in items or version != (values(items[key])+[0])[33]:
            raise ValueError("神器已变化，请重新打开页面")
    return args


def wash(data, entry, mode, config, rng):
    if mode not in (1, 2, 3) or entry.get("pending") or any(v > 0 for v in data[18:21]):
        raise ValueError("请选择洗炼方式，并先处理上次预览")
    opened = [i for i in range(3) if data[21+i] == 1]
    locked = [i for i in range(3) if data[21+i] == 2]
    if not opened:
        raise ValueError("没有可洗炼的神技孔位")
    kind = str(config["trump"][str(data[1])]["type"])
    pool = sorted(config["trump_washing_skill"][kind].values(), key=lambda r: r["id"])
    by_skill = {r[f"skill{i}"]: r for r in pool for i in range(1, 7)}
    selected = [data[6+i] if i in locked else 0 for i in range(3)]
    used = {by_skill[s]["metux"] for s in selected if s}
    rolls = list(entry.get("rolls", [0, 0]))
    if mode == 1:
        rolls = [v+1 for v in rolls]
        if max(rolls) >= (1 << 31):
            raise ValueError("神器洗炼次数超出范围")
    forced = 6 if mode == 2 or mode == 1 and rolls[1] >= int(config["trump_config"]["ordinary_level6_num"]["value"]) else (
        5 if mode == 1 and rolls[0] >= int(config["trump_config"]["ordinary_level5_num"]["value"]) else 0)
    if mode == 3:
        if sum(bool(s) for s in data[6:9]) < 2:
            raise ValueError("共鸣洗炼至少需要两条神技")
        candidates = sorted({other for r in config["resonance_attribute"]["1"].values()
                             for source, other in ((r["skills1"], r["skills2"]), (r["skills2"], r["skills1"]))
                             if source in selected and other not in data[6:9] and other in by_skill
                             and by_skill[other]["metux"] not in used})
        if not candidates:
            raise ValueError("请锁定可共鸣神技，并保留可替换孔位")
        chosen = choose([(s, by_skill[s]["weight"]) for s in candidates], rng)
        selected[opened[0]] = chosen
        used.add(by_skill[chosen]["metux"])
        opened = opened[1:]
    for i in opened:
        row = choose([(r, r["weight"]) for r in pool if r["metux"] not in used], rng)
        levels = range(2 if config["trump"][str(data[1])]["goldTrump"] else 1, 7)
        if forced:
            levels = range(max(min(levels), forced), 7)
            forced = 0
        quality = choose([(q, Fraction(str(row[f"weight{q}"])) + (rolls[1]*int(config["trump_config"][f"washing_lv_{q}"]["value"]) if mode == 1 else 0))
                          for q in levels], rng)
        selected[i] = row[f"skill{quality}"]
        used.add(row["metux"])
    qualities = [config["breakskill"][str(selected[i])]["quality"] for i in range(3) if i not in locked and selected[i]]
    if mode == 1:
        if 6 in qualities and config["trump_config"]["level6_reset"]["value"] == "1":
            rolls = [0, 0]
        elif 5 in qualities and config["trump_config"]["level5_reset"]["value"] == "1":
            rolls[0] = 0
    entry.update(rolls=rolls, pending=selected)
    return selected, deck(config["trump_config"][f"washing_{mode}_{min(2, len(locked))}"]["value"])


def prepare_growth(opcode, save, args, config, state, items, slots, rng):
    from . import activities, general_foster, recharge

    costs, gets, outputs, removed = [], Counter(), [], set()
    entries = state.setdefault("items", {})
    worn = {pb_get_varint(s, 26) for s in slots.values()} - {None, 0}

    def item(key, *, idle=False, unlocked=False, pending=False):
        if key not in items:
            raise ValueError("神器不存在")
        raw = canonical(items[key], config)
        data = values(raw)
        entry = entries.setdefault(str(key), {})
        if opcode != 5518 and not data[5] or idle and key in worn or unlocked and data[27]:
            raise ValueError("神器未鉴定、已穿戴或被锁定")
        if not pending and (entry.get("pending") or any(v > 0 for v in data[18:21])):
            raise ValueError("请先替换或放弃神器洗炼预览")
        return raw, data, entry

    def consume(key):
        raw = items[key]
        data = values(raw)
        if key in worn or data[27] or any(v > 0 for v in data[18:21]):
            raise ValueError("不能消耗穿戴、锁定或有洗炼预览的神器")
        if data[13] or data[14] or any(v >= 0 for v in data[10:13]) or entries.get(str(key), {}).get("strength", {}).get("costs"):
            raise ValueError("强化或开过宝石孔的材料请先安全重生")
        for cid in data[9:13]:
            if cid > 0:
                gets[cid] += 1
        removed.add(key)

    def changed(raw):
        outputs.append(canonical(raw, config, bump=True))

    if opcode in (5502, 5517):
        keys, mode = (args, 0) if opcode == 5502 else (args[:-1], args[-1] if args else -1)
        if (opcode == 5502 and len(keys) != 3 or not keys or len(keys) % 3
                or len(keys) > int(config["trump_config"]["compose_max"]["value"]) or mode not in (0, 1)):
            raise ValueError("重铸需要每组三件唯一神器")
        for key in keys:
            consume(key)
        for at in range(0, len(keys), 3):
            golds = sum(config["trump"][str(values(items[k])[1])]["goldTrump"] for k in keys[at:at+3])
            row = config["trump_compose"][str(golds)]
            gold = choose([(0, row["normalweight"]), (1, row["goldweight"])], rng)
            candidates = sorted((r for r in config["trump"].values() if r["goldTrump"] == gold and r["appraiseMethod"]), key=lambda r: r["id"])
            outputs.append(new_item(choose([(r, r["weight"]) for r in candidates], rng), save["role_name"], state, config))
        reply = outputs[0] if opcode == 5502 else general_foster.comb(enumerate(outputs, 1))
    elif opcode == 5507:
        if len(args) != 2 or str(args[0]) not in config["trump_gem"] or not 1 <= args[1] <= 10000:
            raise ValueError("宝石合成参数无效")
        row = config["trump_gem"][str(args[0])]
        next_row = config["trump_gem"].get(str(row["per_cid"]))
        if not next_row or save["role_state"]["level"] < next_row["gem_lvbet"]:
            raise ValueError("宝石已满级或队伍等级不足")
        costs = [(c, n*args[1]) for c, n in deck(row["gem_lv"])]
        count = sum(rng.randrange(10000) < int(Fraction(str(row["weight_lv"]))*10000) for _ in range(args[1]))
        gets[row["per_cid"]] += count
        reply = None
    else:
        lengths = {5504: 2, 5505: 3, 5506: 2, 5518: 2, 5520: 1, 5540: 3, 5541: 2,
                   5542: 1, 5543: 2, 5544: 1, 5545: 2, 5546: 2}
        if opcode == 5519:
            if not 2 <= len(args) <= 7:
                raise ValueError("强化材料数量无效")
        elif len(args) != lengths[opcode]:
            raise ValueError("神器养成参数无效")
        key = args[0]
        raw, data, entry = item(key, idle=opcode == 5520, unlocked=opcode in (5520, 5545, 5546), pending=opcode in (5542, 5544))
        row = config["trump"][str(data[1])]
        if opcode == 5518:
            if args[1] not in (0, 1) or args[1] == data[27]:
                raise ValueError("神器锁定状态已变化")
            changed(replace(raw, {28: args[1]}))
        elif opcode == 5519:
            step = strength_row(data, config, data[13]+1)
            if not step or len(args)-1 != step["num"]:
                raise ValueError("神器已满级或强化材料数量不符")
            refund = entry.get("strength")
            if refund is None:
                if data[13] or data[14]:
                    raise ValueError("此神器缺少完整强化消耗记录")
                refund = {"level": 0, "costs": []}
            total = Counter(dict(refund["costs"]))
            for food in args[1:]:
                material = values(items[food])
                if not material[5] or material[1] not in (data[1], row["consumption"]):
                    raise ValueError("强化材料必须是同种同品质的已鉴定神器")
                consume(food)
                total[config["trump"][str(material[1])]["return"]] += 1
            refund["costs"] = checked_pairs([[c, n] for c, n in sorted(total.items())], config, returns=True)
            success = rng.randrange(1000) < min(1000, step["basics_success"]+data[14])
            refund["level"] = data[13]+int(success)
            entry["strength"] = refund
            changed(replace(raw, {14: refund["level"], 15: 0 if success else min(1000, data[14]+step["promote_success"])}))
        elif opcode in (5504, 5505, 5506):
            pos = args[-1]
            if pos not in range(1, 5):
                raise ValueError("宝石孔位无效")
            current = data[8+pos]
            if opcode == 5504:
                if current >= 0 or save["role_state"]["level"] < row[f"hole_lv{pos}"]:
                    raise ValueError("宝石孔已开启或队伍等级不足")
                costs = deck(row[f"hole_cost{pos}"])
                entry.setdefault("holes", {})[str(pos)] = [[c, n] for c, n in costs]
                changed(replace(raw, {9+pos: 0}))
            elif opcode == 5505:
                cid = args[1]
                if current < 0 or cid and current or not cid and current <= 0:
                    raise ValueError("请先开启孔位或卸下原宝石")
                if cid:
                    gem = config["trump_gem"].get(str(cid))
                    if (not gem or save["role_state"]["level"] < gem["gem_lvbet"]
                            or any(c > 0 and config["trump_gem"][str(c)]["type"] == gem["type"] for c in data[9:13])):
                        raise ValueError("宝石等级不足或已经镶嵌同类宝石")
                    costs = [(cid, 1)]
                else:
                    gets[current] += 1
                changed(replace(raw, {9+pos: cid}))
            else:
                gem = config["trump_gem"].get(str(current))
                step = config["trump_gem"].get(str(gem["per_cid"])) if gem else None
                if not step or save["role_state"]["level"] < step["gem_lvbet"]:
                    raise ValueError("孔内宝石已满级或队伍等级不足")
                costs = [(c, n-int(c == current)) for c, n in deck(gem["gem_lv"]) if n-int(c == current)]
                success = rng.randrange(10000) < int(Fraction(str(gem["weight_lv"]))*10000)
                changed(replace(raw, {9+pos: step["id"] if success else current}))
        elif opcode == 5540:
            pos, mode = args[1:]
            if pos not in (1, 2, 3) or mode not in (1, 2, 3):
                raise ValueError("神技开孔/锁孔参数无效")
            hole = data[20+pos]
            changes = {}
            if mode == 1:
                if hole > 0 or pos > 1 and data[19+pos] <= 0:
                    raise ValueError("神技孔已开启或前一孔尚未开启")
                costs = deck(config["trump_config"][f"skill_position_{pos}"]["value"])
                success = rng.randrange(100) < data[23+pos]
                gain = int(Fraction(config["trump_config"][f"skill_promote_{pos}"]["value"] or "0")*100)
                changes = {21+pos: 1 if success else -1, 24+pos: data[23+pos] if success else min(100, data[23+pos]+gain)}
            elif mode == 2:
                if hole != 1 or not data[5+pos]:
                    raise ValueError("只能锁定已有神技的开放孔位")
                changes[21+pos] = 2
            else:
                if hole != 2:
                    raise ValueError("神技孔并未锁定")
                changes[21+pos] = 1
            changed(replace(raw, changes))
        elif opcode == 5541:
            selected, costs = wash(data, entry, args[1], config, rng)
            changed(replace(raw, {19+i: s for i, s in enumerate(selected)}))
        elif opcode in (5542, 5544):
            pending = entry.pop("pending", None)
            if not pending or pending != data[18:21]:
                raise ValueError("洗炼预览不存在或已变化")
            changes = {19+i: -1 for i in range(3)}
            if opcode == 5542:
                changes.update({7+i: s for i, s in enumerate(pending)})
            changed(replace(raw, changes))
        elif opcode == 5543:
            pos = args[1]
            if pos not in (1, 2, 3) or not data[5+pos]:
                raise ValueError("请选择已有的橙色神技")
            kind = str(row["type"])
            step = next((r["skill6"] for r in config["trump_washing_skill"][kind].values() if r["skill5"] == data[5+pos]), None)
            if not step or config["trump_config"]["skill_up_lv"]["value"] != "5":
                raise ValueError("仅开放有真实后继配置的橙升红点化")
            costs = deck(config["trump_config"]["skill_cost_5"]["value"])
            changed(replace(raw, {6+pos: step}))
        elif opcode in (5545, 5546):
            other_raw, other, other_entry = item(args[1], unlocked=True)
            if opcode == 5545:
                if data[6:9] == other[6:9]:
                    raise ValueError("两件神器神技相同，无需互换")
                selected = [s for d in (data, other) for s in d[6:9] if s]
                price = sum(int(config["trump_config"][f"quality_swap_price_{config['breakskill'][str(s)]['quality']}"]["value"]) for s in selected)
                price += int(config["trump_config"][f"number_swap_price_{len(selected)}"]["value"])
                positions = (*range(7, 10), *range(22, 28))
                left, right = entry.pop("rolls", [0, 0]), other_entry.pop("rolls", [0, 0])
                entry["rolls"], other_entry["rolls"] = right, left
            else:
                if other[1] not in (data[1], row["consumption"]) or data[13:15] == other[13:15]:
                    raise ValueError("强化互换需要同种同品质且强化状态不同的神器")
                for d, e in ((data, entry), (other, other_entry)):
                    if (d[13] or d[14]) and "strength" not in e:
                        raise ValueError("强化互换对象缺少实际消耗记录")
                price = int(config["trump_transfer"][str(max(data[13], other[13]))]["price"])
                positions = (14, 15)
                left, right = entry.pop("strength", None), other_entry.pop("strength", None)
                if right:
                    entry["strength"] = right
                if left:
                    other_entry["strength"] = left
            costs = [(1001, price)] if price else []
            changed(replace(raw, {p: other[p-1] for p in positions}))
            changed(replace(other_raw, {p: data[p-1] for p in positions}))
        elif opcode == 5520:
            strength = entry.get("strength")
            if (data[13] or data[14]) and strength is None:
                raise ValueError("此神器缺少完整强化消耗记录，未扣款、未重生")
            for pos in range(2, 5):
                if data[8+pos] >= 0 and str(pos) not in entry.get("holes", {}):
                    raise ValueError("此神器缺少完整宝石开孔消耗记录，未重生")
            if not (strength and strength["costs"] or entry.get("holes") or any(c > 0 for c in data[9:13])):
                raise ValueError("神器没有可重生的强化或宝石")
            fee = config["trump_rebirth"].get(str(data[13]), {}).get("strengthen", 0)
            fee += config["trump_rebirth"][str(sum(c >= 0 for c in data[9:13]))]["gem"]
            costs = [(1001, fee)] if fee else []
            for cid, count in (strength or {}).get("costs", []):
                for _ in range(count):
                    outputs.append(new_item(config["trump"][str(cid)], save["role_name"], state, config, returned=True))
            for pairs in entry.get("holes", {}).values():
                gets.update(dict(pairs))
            for cid in data[9:13]:
                if cid > 0:
                    gets[cid] += 1
            entry.pop("strength", None)
            entry.pop("holes", None)
            changed(replace(raw, {10: 0, 11: -1, 12: -1, 13: -1, 14: 0, 15: 0}))
        reply = None
    for key in removed:
        entries.pop(str(key), None)
    if removed:
        save["world_state"]["1002"] = b"".join(encode_pb_field(n, w, v) for n, w, v in iter_pb_fields(bytes.fromhex(save["world_state"]["1002"]))
                                               if not ((n, w) == (16, 2) and iid(v) in removed)).hex()
    reward = activities.build_reward(save, ";".join(f"{c},{n}" for c, n in sorted(gets.items()) if n), config) if any(gets.values()) else b""
    if reply is None:
        if opcode == 5507:
            reply = reward
        elif opcode == 5518:
            reply = recharge.ids([args[0], args[1]])
        elif opcode == 5541:
            reply = recharge.ids(values(outputs[0])[18:21])
        elif opcode in (5540, 5542, 5543, 5544):
            reply = outputs[0]
        elif opcode == 5520:
            reply = general_foster.comb([(0, reward), *enumerate(outputs, 1)])
        elif opcode in (5545, 5546):
            reply = general_foster.comb(enumerate(outputs, 1))
        else:
            reply = general_foster.comb(((0, outputs[0]),))
    update = b"".join(encode_pb_field(16, 2, raw) for raw in outputs)
    return reply, costs, reward, update


def prepare(opcode, save, body, config, now, seed):
    from . import general_foster, recharge

    fields = list(iter_pb_fields(body))
    if len(fields) > 200 or any(n != 1 or w != 0 or not 0 <= v < (1 << 31) for n, w, v in fields):
        raise ValueError("神器请求必须为完整整数列表")
    request = [v for _, _, v in fields]
    if (not save.get("has_role") or save["role_state"]["level"] < config["build"]["396"]["level"]
            or save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2):
        raise ValueError("神器尚未解锁")
    if opcode == 5509:
        if request:
            raise ValueError("神器时辰查询不接受参数")
        return recharge.ids(time_status(config, now)), [], b"", b""
    state = copy.deepcopy(get_state(save, config))
    if now < state["checked_at"]:
        raise ValueError("服务器时钟回拨，神器操作已停止")
    items, slots = read_world(save, config)
    costs, reward, update, rng = [], b"", b"", random.Random(seed)
    if opcode in GROWTH:
        request = growth_request(opcode, request, items)
        reply, costs, reward, update = prepare_growth(opcode, save, request, config, state, items, slots, rng)
    elif opcode in (5501, 5515):
        if len(request) != (1 if opcode == 5501 else 2) or request[0] not in (0, 1):
            raise ValueError("神器打造方式无效")
        mode, count = request[0], 1 if opcode == 5501 else request[1]
        if not 1 <= count <= int(config["trump_config"]["make_max"]["value"]):
            raise ValueError("神器打造次数超出配置上限")
        costs = deck(config["global_kv"]["trump_forging_cost"]["value"])
        if mode:
            costs += deck(config["global_kv"]["godtrump_forging_cost"]["value"])
        costs = [(c, n*count) for c, n in costs]
        candidates = sorted((r for r in config["trump"].values() if r["goldTrump"] == mode and r["appraiseMethod"]), key=lambda r: r["id"])
        outputs = []
        for _ in range(count):
            row = choose([(r, r["weight"]) for r in candidates], rng)
            outputs.append(new_item(row, save["role_name"], state, config))
        reply = outputs[0] if opcode == 5501 else general_foster.comb((i, raw) for i, raw in enumerate(outputs, 1))
        update = b"".join(encode_pb_field(16, 2, raw) for raw in outputs)
    elif opcode in (5508, 5516):
        if len(request) != 2 and opcode == 5508 or not 2 <= len(request) <= int(config["trump_config"]["clear_max"]["value"]) + 1:
            raise ValueError("神器鉴定参数或数量无效")
        keys, prop = request[:-1], request[-1]
        if len(set(keys)) != len(keys) or any(key not in items for key in keys):
            raise ValueError("请选择唯一且实际拥有的神器")
        outputs = [appraise(items[key], prop, config, now, rng) for key in keys]
        costs = [(prop, config["trump_autweight"][str(prop)]["itemNum"] * len(keys))]
        reply = outputs[0] if opcode == 5508 else general_foster.comb((i, raw) for i, raw in enumerate(outputs, 1))
        update = b"".join(encode_pb_field(16, 2, raw) for raw in outputs)
    elif opcode == 5503:
        if len(request) != 3 or request[2] != 1:
            raise ValueError("神器穿戴参数无效")
        sid, key, _ = request
        maximum = min(7, config["role_exp"][str(save["role_state"]["level"])]["slotnum"])
        if not 1 <= sid <= maximum or not pb_get_varint(slots.get(sid, b""), 2):
            raise ValueError("请选择已解锁且有伙伴的阵位")
        previous = pb_get_varint(slots[sid], 26) or 0
        for item in (previous, key):
            if item:
                if item not in items or values(items[item])[5] != 1:
                    raise ValueError("神器不存在或尚未鉴定")
                data = values(items[item])
                if any(v > 0 for v in data[18:21]):
                    raise ValueError("请先处理神器洗炼预览")
                skills(items[item], config)
        if key and any(i != sid and pb_get_varint(slot, 26) == key for i, slot in slots.items()):
            raise ValueError("神器已被其他伙伴穿戴，请先卸下")
        update = encode_pb_field(4, 2, pb_set_varint(slots[sid], 26, key))
        reply = general_foster.comb(((1, update),))
    else:
        raise ValueError("未知神器操作")
    if any(type(c) is not int or type(n) is not int
           or c != 1001 and str(c) not in config["props"] and str(c) not in config["trump_gem"]
           or not 0 < n < (1 << 31) for c, n in costs) or len({c for c, _ in costs}) != len(costs):
        raise ValueError("神器费用配置无效")
    state["checked_at"] = now
    save["artifact_state"] = state
    return reply, costs, reward, update
