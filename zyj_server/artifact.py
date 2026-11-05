"""58级神器打造、鉴定和穿戴；后续强化/洗练/镶嵌不在此批开放。"""

from fractions import Fraction
import random

from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint, pb_set_varint

QUERIES = (5509,)
MUTATIONS = (5501, 5503, 5508, 5515, 5516)
OPCODES = QUERIES + MUTATIONS
FIELDS = {"atk": 6, "def": 7, "hp": 8, "speed": 9}


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
                data = encode_pb_field(1, 0, changes[index])
        result += encode_pb_field(n, w, data)
    return result


def read_world(save, config):
    from . import formation

    world = bytes.fromhex(save["world_state"]["1002"])
    items = {}
    for n, w, raw in iter_pb_fields(world):
        if (n, w) != (16, 2):
            continue
        key, data = iid(raw), values(raw)
        if (key in items or str(data[1]) not in config["trump"] or not isinstance(data[2], str)
                or any(type(data[i]) is not int or not 0 <= data[i] < (1 << 31) for i in (3, 4, 5, 6, 7, 8, 13, 14, 27, 28))
                or data[5] not in (0, 1)):
            raise ValueError("神器存档属性或IID无效")
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
    return state


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
    allowed = {row[f"skill{i}"]: (row, i) for row in config["trump_skillRnd"][kind].values() for i in range(1, 7)}
    result, mutex = {}, set()
    for sid in ids:
        if not sid:
            continue
        if sid not in allowed:
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
            or type(data.get("level")) is not int or data["level"] != 0
            or not isinstance(data.get("skills"), list) or len(data["skills"]) > 3
            or any(type(sid) is not int or sid <= 0 for sid in data["skills"])):
        raise ValueError("战斗神器数据无效或含未接通强化")
    return skill_effects(str(config["trump"][str(data["cid"])]["type"]), data["skills"], config)


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
    return result


def assigned(save, config):
    items, slots = read_world(save, config)
    return {pb_get_varint(slot, 2): items[pb_get_varint(slot, 26)] for slot in slots.values()
            if pb_get_varint(slot, 2) and pb_get_varint(slot, 26)}


def require_plain(data):
    if (data[13] or data[14] or any(v not in (0, "0") for v in data[15:18])
            or any(v > 0 for v in data[9:13]) or any(data[18:21]) or any(data[24:28]) or any(data[29:33])):
        raise ValueError("此神器的高级养成数据尚未接通")


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
    return replace(raw, changes)


def prepare(opcode, save, body, config, now, seed):
    from . import general_foster, recharge

    fields = list(iter_pb_fields(body))
    if any(n != 1 or w != 0 or not 0 <= v < (1 << 31) for n, w, v in fields):
        raise ValueError("神器请求必须为完整整数列表")
    request = [v for _, _, v in fields]
    if (not save.get("has_role") or save["role_state"]["level"] < config["build"]["396"]["level"]
            or save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2):
        raise ValueError("神器尚未解锁")
    if opcode == 5509:
        if request:
            raise ValueError("神器时辰查询不接受参数")
        return recharge.ids(time_status(config, now)), [], b""
    state = dict(get_state(save, config))
    if now < state["checked_at"]:
        raise ValueError("服务器时钟回拨，神器操作已停止")
    items, slots = read_world(save, config)
    costs, update, rng = [], b"", random.Random(seed)
    if opcode in (5501, 5515):
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
            state["serial"] += 1
            if state["serial"] >= (1 << 31):
                raise ValueError("神器IID超出范围")
            row = choose([(r, r["weight"]) for r in candidates], rng)
            data = [state["serial"], row["id"], save["role_name"], 0, 0, 0, 0, 0, 0, 0, -1, -1, -1,
                    0, 0, "0", "0", "0", 0, 0, 0, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0]
            outputs.append(record(data))
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
    else:
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
                require_plain(data)
                skills(items[item], config)
        if key and any(i != sid and pb_get_varint(slot, 26) == key for i, slot in slots.items()):
            raise ValueError("神器已被其他伙伴穿戴，请先卸下")
        update = encode_pb_field(4, 2, pb_set_varint(slots[sid], 26, key))
        reply = general_foster.comb(((1, update),))
    if any(c not in (20627, 20628, 20629, 20630, 20671, 20672) or n <= 0 or n >= (1 << 31) for c, n in costs) or len({c for c, _ in costs}) != len(costs):
        raise ValueError("神器费用配置无效")
    state["checked_at"] = now
    save["artifact_state"] = state
    return reply, costs, update
