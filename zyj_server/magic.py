"""31级法宝：真实条件解锁、付费候选、版本确认及凡/仙锻造。"""

from fractions import Fraction
import random

from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint, pb_set_varint

QUERIES = (1360,)
MUTATIONS = (1361, 1362, 1363, 1364, 1365)
OPCODES = QUERIES + MUTATIONS
FIELDS = {"atk": 6, "def": 7, "hp": 8, "critical": 10, "dodge": 11, "parry": 12,
          "resilience": 13, "hit": 14, "arp": 15, "criticaldmg": 16}
COUNTERS = ("stone_copy", "blackmarketgoldbuycount")
# 自动锻造不再读取 global_kv.automatic_artifact_number（原值 1000）作为业务次数上限：
# 次数由玩家实际资源决定，这里只保留协议/内存安全阀，打包客户端注入同一个值。
MAX_AUTOMATIC_ROLLS = 100000


def values(row, prefix):
    result = []
    for i in range(1, 5):
        name = row[f"attr{i}"].removeprefix("g_")
        if name not in (*FIELDS, "adddmg", "subdmg"):
            raise ValueError("法宝属性配置无效")
        value = Fraction(str(row[f"{prefix}{i}"])) * (100 if name in FIELDS and FIELDS[name] >= 10 else 1)
        if value.denominator != 1 or not 0 <= value < (1 << 31):
            raise ValueError("法宝属性单位或数值无效")
        result.append(int(value))
    return result


def get_state(save, config):
    state = save.get("magic_state", {"serial": 0, "items": {}, "pending": {}, "counts": dict.fromkeys(COUNTERS, 0)})
    if (not isinstance(state, dict) or type(state.get("serial")) is not int or not 0 <= state["serial"] < (1 << 31)
            or any(not isinstance(state.get(k), dict) for k in ("items", "pending", "counts"))
            or set(state["counts"]) != set(COUNTERS)
            or any(type(v) is not int or not 0 <= v < (1 << 31) for v in state["counts"].values())
            or set(state["items"]) != {str(i) for i in range(1, len(state["items"])+1)}
            or len(state["items"]) > 9 or not set(state["pending"]) <= set(state["items"])):
        raise ValueError("法宝存档或累计记录无效")
    tokens = set()
    for cid, item in state["items"].items():
        if not isinstance(item, dict) or type(item.get("stage")) is not int or item["stage"] not in (0, 1):
            raise ValueError("法宝突破阶段无效")
        for key, row in (("normal", config["artifact"][cid]), ("fairy", config["artifact_xian_config"][cid]["1"])):
            data, caps = item.get(key), values(row, "init")
            if (not isinstance(data, list) or len(data) != 4
                    or any(type(v) is not int or not 0 <= v <= cap for v, cap in zip(data, caps))
                    or key == "fairy" and not item["stage"] and any(data)
                    or key == "normal" and item["stage"] and data != caps):
                raise ValueError("法宝属性或突破条件无效")
        pending = state["pending"].get(cid)
        if pending is not None:
            row = config["artifact_xian_config"][cid]["1"] if item["stage"] else config["artifact"][cid]
            if (not isinstance(pending, dict) or type(pending.get("token")) is not int
                    or not 0 < pending["token"] <= state["serial"] or pending["token"] in tokens
                    or type(pending.get("method")) is not int or pending["method"] not in (1, 2, 3)
                    or type(pending.get("count")) is not int or pending["count"] not in (1, 10, 50)
                    or not isinstance(pending.get("base"), list) or any(type(v) is not int for v in pending["base"])
                    or pending.get("base") != [item["stage"], *item["normal"], *item["fairy"]]
                    or not isinstance(pending.get("values"), list) or len(pending["values"]) != 4
                    or any(type(v) is not int or not 0 <= v <= cap for v, cap in zip(pending["values"], values(row, "init")))):
                raise ValueError("法宝预览与当前法宝不一致")
            tokens.add(pending["token"])
    return state


def record_count(save, name, count, config):
    state = get_state(save, config)
    if name not in COUNTERS or type(count) is not int or not 0 <= count < (1 << 31) - state["counts"][name]:
        raise ValueError("法宝累计计数超出范围")
    state["counts"][name] += count
    save["magic_state"] = state


def progress(save, cid, config):
    from . import formation, godstone

    world = bytes.fromhex(save["world_state"]["1002"])
    generals = formation.records(world, 1, 2)
    protagonist = pb_get_varint(bytes.fromhex(save.get("protagonist_snapshot", "")), 1)
    partners = [raw for iid, raw in generals.items() if iid != protagonist
                and config["general"][str(pb_get_varint(raw, 1))]["battle"]]
    counts = get_state(save, config)["counts"]
    result = []
    for i in range(1, 6):
        task = config["artifact"][str(cid)][f"task{i}"]
        if not task:
            result.extend((0, 1))
            continue
        row = config["task"][str(task)]
        target = list(map(int, row["target"].split(",")))
        name, required = row["type"], target[-1]
        if name in COUNTERS:
            current = counts[name]
        elif name == "level":
            current = save["role_state"]["level"]
        elif name == "battle_power":
            current = save["role_state"]["power"]
        elif name == "general":
            current = sum(config["general"][str(pb_get_varint(raw, 1))]["quality"] >= target[0] for raw in partners)
        elif name == "generalbreak":
            current = sum((pb_get_varint(raw, 4) or 0) >= target[0] for raw in partners)
        elif name == "copy":
            maps = formation.records(bytes.fromhex(save["world_state"]["1300"]), 1, 1)
            points = formation.records(maps.get(target[0], b""), 7, 1)
            current, required = int((pb_get_varint(points.get(target[1], b""), 3) or 0) > 0), 1
        elif name == "magicstonelevellimit":
            slots = formation.records(world, 4, 1)
            number = min(7, config["role_exp"][str(save["role_state"]["level"])]["slotnum"])
            current = min(min(godstone.levels(slots.get(sid, b""), config)) for sid in range(1, number+1))
        else:
            raise ValueError("法宝解锁任务类型暂不支持")
        result.extend((current, int(current >= required)))
    return result


def bonuses(save, config):
    stats, flat = {f: Fraction(0) for f in range(6, 17)}, [Fraction(0), Fraction(0)]
    # shortcut: 仙属性仅折算普通v2，接入仙将/仙界战斗时再建立独立仙属性通道。
    for cid, item in get_state(save, config)["items"].items():
        for row, data, factor in ((config["artifact"][cid], item["normal"], Fraction(1)),
                                  (config["artifact_xian_config"][cid]["1"], item["fairy"], Fraction(config["global_kv"]["fairy_turn_every"]["value"]))):
            if not 0 < factor <= 1:
                raise ValueError("仙法宝折算比例无效")
            for i, amount in enumerate(data, 1):
                name = row[f"attr{i}"].removeprefix("g_")
                if name in FIELDS:
                    stats[FIELDS[name]] += amount * factor
                else:
                    flat[int(name == "subdmg")] += amount * factor
    return stats, [int(v) for v in flat]


def differences(save, before, config):
    from . import development, formation

    old, old_flat = before
    current, flat = bonuses(save, config)
    changes = {f: int(current[f])-int(old[f]) for f in current if int(current[f]) != int(old[f])}
    fixed = sum(flat)-sum(old_flat)
    if not changes and not fixed:
        return b"", 0
    world = bytes.fromhex(save["world_state"]["1002"])
    generals, slots = formation.records(world, 1, 2), formation.records(world, 4, 2)
    update, power = b"", 0
    for iid in sorted(i for i in slots if i):
        raw, delta = development.adjust(generals[iid], changes)
        value = (pb_get_varint(raw, 20) or 0) + fixed
        if not 0 <= value < (1 << 31):
            raise ValueError("法宝增加后的伙伴战力超出范围")
        update += encode_pb_field(1, 2, pb_set_varint(raw, 20, value))
        power += delta + fixed
    return update, power


def roll(data, row, table, count, rng):
    after, actual, caps = data[:], 0, values(row, "init")
    for _ in range(count):
        if after == caps:
            break
        for i, (amount, cap) in enumerate(zip(after, caps), 1):
            band = next((j for j in range(1, 11) if Fraction(amount, cap) <= Fraction(str(table[f"upper{j}"]))), None)
            if band is None:
                raise ValueError("法宝锻造区间配置无效")
            name = row[f"attr{i}"]
            scale = 100 if name.removeprefix("g_") in FIELDS and FIELDS[name.removeprefix("g_")] >= 10 else 1
            low, high = (Fraction(str(table[f"{name}{key}{band}"]))*scale for key in ("down", "up"))
            if low.denominator != 1 or high.denominator != 1 or low > high:
                raise ValueError("法宝随机波动配置无效")
            after[i-1] = min(cap, max(0, amount+rng.randint(int(low), int(high))))
        actual += 1
    return after, actual


def score(data, row):
    return sum(value//10 if row[f"attr{i}"].removeprefix("g_") == "hp" else value
               for i, value in enumerate(data, 1) if row[f"attr{i}"].removeprefix("g_") in ("atk", "def", "hp", "adddmg", "subdmg"))


def rank_score(save, config):
    stats, flat = bonuses(save, config)
    return int(stats[6]) + int(stats[7]) + int(stats[8])//10 + sum(flat)


def prepare(opcode, save, body, config, seed):
    from . import formation, general_foster, recharge

    fields = list(iter_pb_fields(body))
    if any(n != 1 or w != 0 or not 0 <= v < (1 << 31) for n, w, v in fields):
        raise ValueError("法宝参数必须为完整整数列表")
    request = [v for _, _, v in fields]
    if (len(request) != {1360: 0, 1361: 1, 1362: 3, 1363: 3, 1364: 8, 1365: 1}[opcode]
            or not save.get("has_role") or save["role_state"]["level"] < config["build"]["149"]["level"]
            or save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2):
        raise ValueError("法宝尚未解锁或请求参数不完整")
    state = get_state(save, config)
    save["magic_state"] = state
    next_id = len(state["items"])+1 if len(state["items"]) < len(config["artifact"]) else 0
    if opcode == 1360:
        data = [v for cid, item in sorted(state["items"].items(), key=lambda p: int(p[0]))
                for v in (int(cid), *item["normal"], item["stage"], *item["fairy"])]
        return recharge.ids([*data, next_id, *(progress(save, next_id, config) if next_id else [0]*10)]), [], 0
    cid = request[1] if opcode == 1363 else request[0]
    if opcode == 1361:
        if cid != next_id or not cid or not all(progress(save, cid, config)[1::2]):
            raise ValueError("法宝解锁条件未满足或不是下一件法宝")
        state["items"][str(cid)] = {"normal": values(config["artifact"][str(cid)], "initial"), "stage": 0, "fairy": [0]*4}
        return b"", [], 0
    if str(cid) not in state["items"]:
        raise ValueError("此法宝尚未解锁")
    item, pending = state["items"][str(cid)], state["pending"].get(str(cid))
    row = config["artifact_xian_config"][str(cid)]["1"] if item["stage"] else config["artifact"][str(cid)]
    key = "fairy" if item["stage"] else "normal"
    data, costs, actual = item[key], [], 0
    if opcode == 1363:
        keep, _, token = request
        if keep not in (0, 1) or not pending or token != pending["token"]:
            raise ValueError("法宝预览已变化，请重新打开当前法宝后确认")
        if keep:
            item[key] = pending["values"]
        del state["pending"][str(cid)]
        reply = b""
    elif opcode == 1362 and request[1:] == [0, 0]:
        return recharge.ids([*(pending["values"] if pending else data), pending["token"] if pending else 0, 0,
                             pending["method"] if pending else 1, pending["count"] if pending else 1, item["stage"]]), [], 0
    elif opcode == 1365:
        target = config["artifact_xian_config"][str(cid)].get(str(item["stage"]+1))
        if pending or not target or save["role_state"]["level"] < target["level"] or data != values(row, "init"):
            raise ValueError("请先确认预览并满足等级和全部普通属性上限后突破")
        costs = [tuple(map(int, entry.split(","))) for entry in target["breach_consume"].split(";") if entry]
        if not costs or len({c for c, _ in costs}) != len(costs) or any(c not in (20270, 1025) or n <= 0 for c, n in costs):
            raise ValueError("法宝突破费用配置无效")
        item.update(stage=item["stage"]+1, fairy=values(target, "initial"))
        reply = recharge.ids([1])
    else:
        _, method, count, *flags = request
        level = save["role_state"]["level"]
        large = level >= int(config["global_kv"]["artifact_leve_limit"]["value"])
        if method not in (1, 2, 3):
            raise ValueError("法宝锻造方式无效")
        if opcode == 1362:
            if count not in ((1, 10, 50) if large else (1, 10)):
                raise ValueError("法宝锻造次数尚未解锁")
        elif (level < int(config["global_kv"]["automatic_forging"]["value"]) and not config["vip"][str(save["role_state"]["vip"])]["vip_automatic_forging"]
              or not 1 <= count <= MAX_AUTOMATIC_ROLLS
              or any(v not in (0, 1) for v in flags) or pending):
            raise ValueError("自动锻造未解锁、次数/筛选无效或仍有待确认预览")
        if data == values(row, "init"):
            raise ValueError("法宝锻造属性已达上限")
        consume = row[f"forging_consume{method}"] if item["stage"] else config["global_kv"][f"artifact_consume_{method}"]["value"]
        unit_costs = [tuple(map(int, entry.split(","))) for entry in consume.split(";") if entry]
        props = formation.records(bytes.fromhex(save["world_state"]["1200"]), 1, 1)
        for currency, amount in unit_costs:
            available = save["role_state"][{1000: "coin", 1001: "gold", 1025: "g_gold"}[currency]] if currency in (1000, 1001, 1025) else pb_get_varint(props.get(currency, b""), 2) or 0
            if currency not in (1000, 1001, 1025, 20270) or amount <= 0 or available < amount*count:
                raise ValueError("法宝锻造资源不足或费用配置无效")
        if not unit_costs or len({c for c, _ in unit_costs}) != len(unit_costs):
            raise ValueError("法宝锻造费用配置无效")
        table = config["artifact_baptize_xian"][str((cid-1)*3+method)] if item["stage"] else config["artifact_baptize"][str(cid)][str(method)]
        rng, after, status, counts = random.Random(seed), data[:], [], []
        while actual < count and after != values(row, "init"):
            candidate, done = roll(after, row, table, min(10, count-actual), rng)
            keep = opcode == 1362 or (candidate != after and all(b >= a for a, b, flag in zip(after, candidate, flags) if flag)
                    and (score(candidate, row) >= score(after, row) if flags[4] else True)
                    and (any(b > a for a, b in zip(after, candidate)) if not any(flags) else True))
            status.extend([int(keep), *(b-a for a, b in zip(after, candidate))])
            counts.append(done)
            actual += done
            if keep:
                after = candidate
        costs = [(c, n*actual) for c, n in unit_costs]
        if opcode == 1362:
            if state["serial"]+1 >= (1 << 31):
                raise ValueError("法宝预览编号超出范围")
            state["serial"] += 1
            pending = {"token": state["serial"], "method": method, "count": count,
                       "base": [item["stage"], *item["normal"], *item["fairy"]], "values": after}
            state["pending"][str(cid)] = pending
            reply = recharge.ids([*after, pending["token"], actual, method, count, item["stage"]])
        else:
            item[key] = after
            reply = general_foster.comb(((2, recharge.ids(v & ((1 << 64)-1) for v in status)), (3, recharge.ids([actual, *counts]))))
    get_state(save, config)
    return reply, costs, actual
