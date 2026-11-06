"""伙伴潜力培养：付费候选、版本确认及有界自动结算；只转移本地记录的培养属性。"""

from fractions import Fraction
import random

from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint

OPCODES = (1013, 1014, 1126)
FIELDS = (6, 8, 7)
NAMES = ("atk", "hp", "def")


def get_state(save, config):
    state = save.setdefault("general_foster_state", {"serial": 0, "records": {}, "pending": {}})
    if (not isinstance(state, dict) or type(state.get("serial")) is not int or not 0 <= state["serial"] < (1 << 31)
            or any(not isinstance(state.get(key), dict) for key in ("records", "pending"))):
        raise ValueError("伙伴培养存档无效")
    tokens = set()
    for key in ("records", "pending"):
        for iid, entry in state[key].items():
            if (not isinstance(iid, str) or not iid.isdecimal() or str(int(iid)) != iid or not 0 < int(iid) < (1 << 31)
                    or not isinstance(entry, dict)):
                raise ValueError("伙伴培养身份无效")
            units = entry.get("units")
            if not isinstance(units, list) or len(units) != 3 or any(type(v) is not int or not 0 <= v < (1 << 31) for v in units):
                raise ValueError("伙伴培养属性记录无效")
            if key == "records":
                if type(entry.get("cid")) is not int or str(entry["cid"]) not in config["general"]:
                    raise ValueError("伙伴培养CID无效")
            else:
                base = entry.get("base")
                if (not isinstance(base, list) or len(base) != 5 or str(base[0]) not in config["general"]
                        or any(type(v) is not int or not 0 <= v < (1 << 31) for v in base)
                        or type(entry.get("spent")) is not int or not 0 <= entry["spent"] < (1 << 31)
                        or type(entry.get("token")) is not int or not 0 < entry["token"] <= state["serial"]
                        or entry["token"] in tokens):
                    raise ValueError("伙伴培养预览无效")
                if sum(units)-sum(base[2:]) not in (entry["spent"], entry["spent"]*2):
                    raise ValueError("伙伴培养预览潜力与属性不一致")
                tokens.add(entry["token"])
    return state


def remove(save, iid):
    for key in ("records", "pending"):
        save.get("general_foster_state", {}).get(key, {}).pop(str(iid), None)
    save.get("qiankun_state", {}).get("receipts", {}).pop(f"general:{iid}", None)


def used_potential(raw, config):
    row = config["general"][str(pb_get_varint(raw, 1))]
    maximum = row["potential"] + int(Fraction(str(row["potential-grow"])) * (pb_get_varint(raw, 3) - 1))
    remaining = pb_get_varint(raw, 17)
    if type(remaining) is not int or not 0 <= remaining <= maximum < (1 << 31):
        raise ValueError("伙伴潜力数据无效")
    return maximum - remaining


def ratios(config, gold=False):
    values = [int(config["global_kv"][f'general_foster_{name}_ratio{"_gold" if gold else ""}']["value"]) for name in NAMES]
    if any(not 0 < value <= 100 for value in values):
        raise ValueError("伙伴培养属性配比无效")
    return values


def roll(units, potential, count, gold, config, rng):
    base, rate = ratios(config), ratios(config, gold)
    factors = [Fraction(b, a) for a, b in zip(base, rate)]
    if len(set(factors)) != 1 or factors[0] not in (1, 2):
        raise ValueError("伙伴培养属性倍率不一致")
    deck = [tuple(map(int, item.split(","))) for item in config["global_kv"]["general_foster_good" if gold else "general_foster_bad"]["value"].split(";") if item]
    if not deck or any(len(row) != 2 or not 0 < row[0] <= 100 or row[1] < 0 for row in deck) or sum(row[1] for row in deck) <= 0:
        raise ValueError("伙伴培养随机配置无效")
    source = rng.choice([i for i in range(3) if potential or units[i]])
    target = rng.choice([i for i in range(3) if i != source])
    after, remaining, actual = units[:], potential, 0
    for _ in range(count):
        if not remaining and not after[source]:
            break
        amount = rng.choices([p for p, w in deck], [w for p, w in deck])[0]
        spent = min(remaining, amount)
        transfer = min(after[source], rng.randint(0, amount) if remaining else amount)
        after[source] -= transfer
        after[target] += spent * int(factors[0]) + transfer
        remaining -= spent
        actual += 1
    return after, remaining, actual, source, target


def comb(rows):
    return b"".join(encode_pb_field(1, 2, encode_pb_field(1, 0, mid) + encode_pb_field(2, 2, data)) for mid, data in rows)


def changed_general(raw, before, after, spent, config):
    from . import development

    changes = {field: (new-old)*ratio for field, old, new, ratio in zip(FIELDS, before, after, ratios(config))}
    changes[17] = -spent
    return development.adjust(raw, changes)


def prepare(opcode, save, body, config, seed):
    from . import formation, qiankun, recharge

    fields = list(iter_pb_fields(body))
    if opcode == 1126:
        if len(fields) != 6 or any(n != 1 or w != 0 or not 0 <= v < (1 << 31) for n, w, v in fields):
            raise ValueError("自动培养需要伙伴、方式、次数及三个筛选标记")
        iid, method, count, *flags = [v for _, _, v in fields]
        if method not in (1, 2) or not 1 <= count <= 200 or any(v not in (0, 1) for v in flags):
            raise ValueError("自动培养方式、次数或筛选无效")
    else:
        if (len(fields) != (3 if opcode == 1014 else 2) or {n for n, _, _ in fields} != set(range(1, len(fields)+1))
                or any(w != 0 or not 0 <= v < (1 << 31) for n, w, v in fields)):
            raise ValueError("培养参数或预览编号不完整")
        values = {n: v for n, _, v in fields}
        iid, method = values[1], values[2]
        if method not in ((0, 1) if opcode == 1014 else range(5)):
            raise ValueError("伙伴培养方式无效")
        count = 10 if method in (2, 4) else 1
    if (not save.get("has_role") or save["role_state"]["level"] < config["build"]["51"]["level"]
            or save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2):
        raise ValueError("伙伴培养尚未解锁")
    world = bytes.fromhex(save["world_state"]["1002"])
    generals = formation.records(world, 1, 2)
    if iid not in generals:
        raise ValueError("培养伙伴不存在或不属于当前账号")
    raw = generals[iid]
    from . import illusion
    illusion.validate_general(raw, config)
    cid = pb_get_varint(raw, 1)
    row = config["general"][str(cid)]
    if (iid == pb_get_varint(bytes.fromhex(save.get("protagonist_snapshot", "")), 1)
            or not row["battle"] or not row["init_cid"] or row["quality"] not in range(2, 8)
            or pb_get_varint(raw, 3) <= 1):
        raise ValueError("请选择2级以上普通伙伴，主角和高级对象暂不支持")
    if (pb_get_varint(raw, 4) or 0) > 10 or any(pb_get_varint(raw, n) for n in range(21, 41)):
        from . import partner_growth
        partner_growth.validate(raw, config)
    state = get_state(save, config)
    # shortcut: 旧培养分配不倒算，有可验证的分配台账后再开放其转移。
    record = state["records"].get(str(iid), {"cid": cid, "units": [0, 0, 0]})
    units = record["units"]
    if record["cid"] != cid or any((pb_get_varint(raw, f) or 0) <= v*r for f, v, r in zip(FIELDS, units, ratios(config))):
        raise ValueError("伙伴培养记录与当前属性不一致")
    base = [cid, used_potential(raw, config), *units]
    pending = state["pending"].get(str(iid))
    potential, actual, status, counts = pb_get_varint(raw, 17), 0, [], []
    costs, update, changed, after = [], b"", raw, units[:]
    if opcode == 1014:
        if not pending or values[3] != pending["token"]:
            raise ValueError("培养预览已变化，请重新打开当前伙伴后确认")
        if method:
            if pending["base"] != base or pending["spent"] > potential:
                raise ValueError("培养预览与当前伙伴不一致，请先放弃旧预览")
            after = pending["units"]
            changed, _ = changed_general(raw, units, after, pending["spent"], config)
        del state["pending"][str(iid)]
        reply = comb(((1, encode_pb_field(1, 2, changed)), (2, recharge.ids([method]))))
    elif opcode == 1013 and method == 0:
        if pending:
            if pending["base"] != base or pending["spent"] > potential:
                raise ValueError("培养预览与当前伙伴不一致，请先放弃旧预览")
            candidate, _ = changed_general(raw, units, pending["units"], pending["spent"], config)
        else:
            candidate = raw
        return comb(((1, encode_pb_field(1, 2, raw)), (2, encode_pb_field(1, 2, candidate)),
                     (3, recharge.ids([pending["token"] if pending else 0, 0])))), [], b"", 0
    else:
        if opcode == 1126 and pending:
            raise ValueError("请先保留或放弃当前伙伴的培养预览")
        if not potential and not any(units):
            raise ValueError("没有剩余潜力或可核实的本地培养属性可转移")
        gold = method == 2 if opcode == 1126 else method >= 3
        props = formation.records(bytes.fromhex(save["world_state"]["1200"]), 1, 1)
        if (pb_get_varint(props.get(20009, b""), 2) or 0) < count or gold and save["role_state"]["gold"] < count*5:
            raise ValueError("培养丹或元宝不足")
        rng = random.Random(seed)
        remaining = potential
        while actual < count:
            if not remaining and (not any(after) or opcode == 1126 and not any(v and not flag for v, flag in zip(after, flags))):
                break
            candidate, rest, done, source, target = roll(after, remaining, min(10, count-actual), gold, config, rng)
            deltas = [(new-old)*ratio for old, new, ratio in zip(after, candidate, ratios(config))]
            keep = opcode == 1013 or all(delta >= 0 for delta, flag in zip(deltas, flags) if flag) and any(delta > 0 for delta in deltas)
            status.extend([int(keep), source+1, deltas[source], target+1, deltas[target], remaining-rest])
            counts.append(done)
            actual += done
            if keep:
                after, remaining = candidate, rest
        if not actual:
            raise ValueError("当前筛选下没有可培养的属性")
        costs = [(20009, actual)] + ([(1001, actual*5)] if gold else [])
        changed, _ = changed_general(raw, units, after, potential-remaining, config)
        if opcode == 1013:
            if state["serial"] + 1 >= (1 << 31):
                raise ValueError("伙伴培养预览编号超出范围")
            state["serial"] += 1
            pending = {"token": state["serial"], "base": base, "units": after, "spent": potential-remaining}
            state["pending"][str(iid)] = pending
            reply = comb(((1, encode_pb_field(1, 2, raw)), (2, encode_pb_field(1, 2, changed)),
                          (3, recharge.ids([pending["token"], actual]))))
            changed, after = raw, units
        else:
            reply = comb(((1, encode_pb_field(1, 2, changed)), (2, recharge.ids(v & ((1 << 64)-1) for v in status)), (3, recharge.ids(counts))))
    qiankun.record_training(save, "general", raw, changed, [(cid, n) for cid, n in costs if cid == 20009], qiankun.pristine_general(raw, config, save))
    if changed != raw:
        state["records"][str(iid)] = {"cid": cid, "units": after}
        update = encode_pb_field(1, 2, changed)
        delta = (pb_get_varint(changed, 20) or 0) - (pb_get_varint(raw, 20) or 0)
        if iid in formation.records(world, 4, 2):
            for key in ("power", "power_all"):
                if not 0 <= save["role_state"][key]+delta < (1 << 31):
                    raise ValueError("培养后的角色战力超出范围")
                save["role_state"][key] += delta
    get_state(save, config)
    return reply, costs, update, actual
