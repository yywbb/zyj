"""猎命、命格成长与阵位穿戴；只按真实消耗/库存结算，不套用千次预制奖励。"""

from fractions import Fraction
import random

from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint, pb_set_varint

QUERIES = (2501,)
MUTATIONS = (*range(2502, 2508), 1006, 5345)
OPCODES = QUERIES + MUTATIONS
FIELDS = {"atk": 6, "def": 7, "hp": 8, "speed": 9, "critical": 10, "dodge": 11,
          "parry": 12, "resilience": 13, "hit": 14, "arp": 15, "criticaldmg": 16}
LIMIT = 100  # 原包gameConfig.bagLimit_soul；已有超额库存仍可查/整理，猎取和兑换不得继续超额。


def integer(value, low=0, high=(1 << 31) - 1):
    if type(value) is not int or not low <= value <= high:
        raise ValueError("命格数值无效")
    return value


def ids(body):
    fields = list(iter_pb_fields(body))
    if any((n, w) != (1, 0) or not 0 <= v < (1 << 31) for n, w, v in fields):
        raise ValueError("命格操作需要完整整数列表")
    return [v for _, _, v in fields]


def get_state(save):
    state = save.get("soul_state", {"hunt": 1, "tokens": 0, "serial": 3000000, "checked_at": 0})
    try:
        if state["hunt"] not in range(1, 6) or type(state["hunt"]) is not int:
            raise ValueError
        for key in ("tokens", "serial", "checked_at"):
            integer(state[key], 3000000 if key == "serial" else 0)
    except (KeyError, TypeError, ValueError):
        raise ValueError("猎命状态无效") from None
    return state


def allocate(save):
    state = dict(get_state(save))
    existing = [pb_get_varint(v, 1) or 0 for n, w, v in iter_pb_fields(bytes.fromhex(save["world_state"]["1002"])) if (n, w) == (3, 2)]
    state["serial"] = integer(max([state["serial"], *existing]) + 1)
    save["soul_state"] = state
    return state["serial"]


def record(item):
    return b"".join(encode_pb_field(n, 0, v) for n, v in enumerate(item, 1))


def read_world(save, config):
    items, slots, cheers = {}, {}, []
    for n, w, raw in iter_pb_fields(bytes.fromhex(save.get("world_state", {}).get("1002", ""))):
        if n == 3:
            fields = list(iter_pb_fields(raw)) if w == 2 else []
            values = {f: v for f, t, v in fields}
            if len(fields) != 3 or set(values) != {1, 2, 3} or any(t != 0 for f, t, v in fields):
                raise ValueError("命格库存格式无效")
            iid, cid, level = [integer(values[f], 1) for f in (1, 2, 3)]
            row = config["soul"].get(str(cid))
            if not row or iid in items or not 1 <= level <= (row["limit1"] or 1):
                raise ValueError("命格编号、等级或配置无效")
            items[iid] = [iid, cid, level]
        elif n == 4 and w == 2:
            sid = pb_get_varint(raw, 1)
            if sid in slots:
                raise ValueError("命格阵位重复")
            slots[sid] = raw
        elif n == 5 and w == 2:
            cheers.append(raw)
    if any(pb_get_varint(raw, n) for raw in cheers for n in range(10, 18)):
        raise ValueError("请先处理不支持的助阵命格穿戴记录")
    validate_slots(items, slots, save, config)
    return items, slots


def attributes(row):
    return {(row[f"attr{i}"], row[f"method{i}"]) for i in (1, 2) if row[f"attr{i}"] not in ("", "0")}


def validate_slots(items, slots, save, config):
    seen = set()
    level = save.get("role_state", {}).get("level", 1)
    for sid, raw in slots.items():
        types = set()
        for pos in range(1, 9):
            iid = pb_get_varint(raw, pos + 9) or 0
            if not iid:
                continue
            if (sid not in range(1, min(7, config["role_exp"][str(level)]["slotnum"]) + 1)
                    or config["soulslot"][str(pos)]["level"] > level or iid not in items or iid in seen or items[iid][1] == 70000):
                raise ValueError("命格不属于本人、阵位未解锁或重复穿戴")
            names = attributes(config["soul"][str(items[iid][1])])
            if not names or types & names:
                raise ValueError("同一阵位不能穿戴重复属性的命格，包括双属性合成命格")
            seen.add(iid)
            types |= names


def bonuses(slot, items, config):
    values, flat, effects = {f: Fraction(0) for f in range(6, 17)}, [0, 0], {"heal": Fraction(0), "antiblew": Fraction(0)}
    for n in range(10, 18):
        iid = pb_get_varint(slot, n) or 0
        if not iid:
            continue
        if iid not in items:
            raise ValueError("阵位命格库存缺失")
        _, cid, level = items[iid]
        row = config["soul"][str(cid)]
        for i in (1, 2):
            name, method = row[f"attr{i}"], row[f"method{i}"]
            if name in ("", "0"):
                continue
            value = Fraction(str(row[f"attr{i}_grow{level}"]))
            if value < 0:
                raise ValueError("命格属性配置无效")
            if name in FIELDS and method == ("value" if FIELDS[name] < 10 else "percent"):
                values[FIELDS[name]] += value * (1 if method == "value" else 100)
            elif name in ("adddmg", "subdmg") and method == "value" and value.denominator == 1:
                flat[int(name == "subdmg")] += int(value)
            elif name in effects and method == "percent":
                effects[name] += value
            else:
                raise ValueError("此命格属性尚未支持，未改变穿戴")
    return values, flat, effects


def query(state, items=(), coin=0):
    return (encode_pb_field(1, 0, state["tokens"]) + encode_pb_field(2, 0, state["hunt"])
            + b"".join(encode_pb_field(3, 2, record(item)) for item in items) + encode_pb_field(4, 0, coin))


def prepare(opcode, save, body, config, now, seed):
    from . import achievements, activities, formation, guild

    if opcode == 2501 and save.get("has_role") and save["role_state"]["level"] < config["build"]["9"]["level"]:
        if body:
            raise ValueError("猎命查询不接受参数")
        return query(get_state(save)), [], b"", b""
    if (not save.get("has_role") or save["role_state"]["level"] < config["build"]["9"]["level"]
            or save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2):
        raise ValueError("猎命需要队伍41级并完成新手引导")
    values = [] if opcode == 1006 else ids(body)
    state = dict(get_state(save))
    if opcode != 2501 and now < state["checked_at"]:
        raise ValueError("猎命时间发生回拨，请校准后操作")
    state["checked_at"] = max(now, state["checked_at"])
    save["soul_state"] = state
    items, slots = read_world(save, config)
    before, old_slots = {i: v[:] for i, v in items.items()}, dict(slots)
    legacy = [iid for iid, item in items.items() if item[1] == 70000]
    state["tokens"] = integer(state["tokens"] + len(legacy))
    for iid in legacy:
        del items[iid]
    costs, reward, reply = [], b"", b""
    if opcode == 2501:
        if body:
            raise ValueError("猎命查询不接受参数")
        reply = query(state)
    elif opcode == 2502:
        if len(values) != 4 or values[0] not in (1, 10, 100, 1000, 6, 60, 600) or any(v not in (0, 1) for v in values[1:]):
            raise ValueError("请选择有效的猎命次数和三个自动分解标志")
        method, *flags = values
        premium = method in (6, 60, 600)
        count = method // 6 if premium else method
        if count == 1 and any(flags) or count == 1000 and flags != [1, 1, 1]:
            raise ValueError("单次不自动分解，千次需要勾选全部自动分解")
        if count >= 100 and save["role_state"]["level"] < int(config["global_kv"]["hundred_soul_hunt_level_limit"]["value"]) and not config["vip"][str(save["role_state"]["vip"])]["hundred_soul_hunt"]:
            raise ValueError("百次/千次猎命需要70级或VIP6")
        if count == 1000 and save["role_state"]["coin"] < config["soul_thousand"]["1"]["consumption_limit"]:
            raise ValueError("千次猎命需要持有配置要求的银币")
        if premium:
            specification = config["gambling_items"]["9"]["1"][{1: "once2", 10: "tenfold2", 100: "hundredfold2"}[count]]
            from .guild_games import pairs
            costs.extend(pairs(specification).items())
        rng, got, spent, dust = random.Random(seed), [], 0, 0
        for _ in range(count):
            stage = 6 if premium else state["hunt"]
            setting = config["soul_hunt"][str(stage)]
            spent += integer(setting["coin"])
            deck = sorted((int(cid), integer(row[f"rang{stage}"])) for cid, row in config["soul"].items())
            total = sum(weight for _, weight in deck)
            if not total:
                raise ValueError("猎命权重表无效")
            draw = rng.randrange(total)
            for cid, weight in deck:
                draw -= weight
                if draw < 0:
                    break
            row = config["soul"][str(cid)]
            state["tokens"] = integer(state["tokens"] + int(premium) + int(cid == 70000))
            if cid != 70000:
                if 2 <= row["quality"] <= 4 and flags[row["quality"] - 2]:
                    dust += integer(row["eatexp"])
                else:
                    iid = allocate(save)
                    state = save["soul_state"]
                    items[iid] = [iid, cid, 1]
                    got.append(items[iid])
            if not premium:
                chance = Fraction(str(setting["range"]))
                if not 0 <= chance <= 1:
                    raise ValueError("猎命进阶概率配置无效")
                state["hunt"] = stage + 1 if stage < 5 and rng.random() < chance else 1
        if spent > save["role_state"]["coin"] or len(items) > LIMIT:
            raise ValueError("银币不足以完成整批猎命或命格背包已满；整批未扣款")
        costs.append((1000, spent))
        reward = activities.build_reward(save, f"20099,{dust}", config) if dust else b""
        reply = guild.message(1, query(state, got, spent)) + guild.message(2, reward)
        achievements.record(save, "soulhuntcount", count, config)
    elif opcode == 2503:
        if len(values) != 1 or str(values[0]) not in config["soul_exchange"] or len(items) >= LIMIT:
            raise ValueError("兑换命格无效或背包已满")
        cid = values[0]
        amount = integer(config["soul_exchange"][str(cid)]["num"], 1)
        if state["tokens"] < amount:
            raise ValueError("元命不足")
        state["tokens"] -= amount
        iid = allocate(save)
        state = save["soul_state"]
        items[iid] = [iid, cid, 1]
        reply = encode_pb_field(1, 2, record(items[iid]))
    elif opcode == 2505:
        if values or state["hunt"] >= 4:
            raise ValueError("本次无需重复点亮天人合一")
        state["hunt"] = 4
        costs = [(1001, 100)]
        reply = encode_pb_field(1, 0, 1)
    elif opcode == 5345:
        if len(values) != 2 or values[0] not in (20617, 20619) or values[1] not in ((1, 10, 100) if values[0] == 20617 else (1, 10)):
            raise ValueError("本地道具购买仅支持猎命灵石1/10/100个或高级招募令1/10个")
        from .guild_games import pairs
        costs = list(pairs(config["gambling_gold"][str(values[0])][{1: "once1", 10: "tenfold1", 100: "hundredfold1"}[values[1]]]).items())
        reply = reward = activities.build_reward(save, f"{values[0]},{values[1]}", config)
    elif opcode in (1006, 1007):
        if opcode == 1006:
            fields = list(iter_pb_fields(body))
            fields_by_id = {n: v for n, w, v in fields}
            if len(fields) != 3 or set(fields_by_id) != {1, 2, 3} or any(w != 0 or not 0 <= v < (1 << 31) for n, w, v in fields):
                raise ValueError("穿戴命格需要阵位、孔位和命格IID，0为卸下")
            sid, pos, iid = [fields_by_id[n] for n in (1, 2, 3)]
            selected = {pos: iid}
        else:
            if len(values) != 10 or values[1] != 2:
                raise ValueError("一键命格需要阵位、方式2及八个IID，0保持原孔")
            sid = values[0]
            selected = {pos: iid for pos, iid in enumerate(values[2:], 1) if iid}
        if sid not in slots or not pb_get_varint(slots[sid], 2) or sid > min(7, config["role_exp"][str(save["role_state"]["level"])]["slotnum"]):
            raise ValueError("请选择已解锁且有武将的主阵位")
        for pos, iid in selected.items():
            if pos not in range(1, 9) or config["soulslot"][str(pos)]["level"] > save["role_state"]["level"] or iid and iid not in items:
                raise ValueError("命格孔位未解锁或命格不属于本人")
            origins = [(s, p) for s, raw in slots.items() for p in range(1, 9) if iid and pb_get_varint(raw, p + 9) == iid]
            if origins and origins[0] != (sid, pos):
                if opcode == 1007:
                    raise ValueError("一键穿戴不能使用其他孔位的命格")
                origin, place = origins[0]
                slots[origin] = pb_set_varint(slots[origin], place + 9, pb_get_varint(slots[sid], pos + 9) or 0)
            slots[sid] = pb_set_varint(slots[sid], pos + 9, iid)
    elif opcode == 2504 and len(values) > 1:
        if len(values) != 20 or values[0] != 0:
            raise ValueError("一键强化需要阵位、武将、确认消耗和八孔当前命格/等级")
        _, sid, general, quoted = values[:4]
        if (sid not in slots or not general or pb_get_varint(slots[sid], 2) != general
                or sid > min(7, config["role_exp"][str(save["role_state"]["level"])]["slotnum"])):
            raise ValueError("一键强化的当前武将或阵位已变化")
        shown, selected = [], []
        for pos in range(1, 9):
            iid = pb_get_varint(slots[sid], pos + 9) or 0
            shown.extend((iid, items[iid][2] if iid else 0))
            if iid:
                selected.append(iid)
        if values[4:] != shown:
            raise ValueError("已装备命格或等级已变化，请重新确认")
        integer(quoted, 1)
        spent = 0
        while True:
            available = []
            for iid in selected:
                item = items[iid]
                row = config["soul"][str(item[1])]
                gate = config["soul_integrate_lv"].get(str(item[2] + 1), {}).get("battle_lv", 0)
                if item[2] < row["limit1"] and save["role_state"]["level"] >= gate:
                    amount = integer(row["upexp"] * 2 ** (item[2] - 1), 1)
                    if amount <= quoted - spent:
                        available.append((item[2], iid, amount))
            if not available:
                break
            # 本地规则与装备一键强化一致：优先可负担的最低等级，同级按IID。
            _, iid, amount = min(available)
            items[iid][2] += 1
            spent += amount
        if spent != quoted:
            raise ValueError("一键强化消耗已变化、灵元不足或已到等级上限，请重新确认")
        costs = [(20099, spent)]
    elif opcode in (2504, 2506, 2507):
        worn = {pb_get_varint(raw, n) for raw in slots.values() for n in range(10, 18)} - {None, 0}
        if not values or len(values) != len(set(values)) or any(iid not in items for iid in values):
            raise ValueError("命格不属于本人或请求重复")
        if opcode == 2504:
            if len(values) != 1:
                raise ValueError("每次只强化一个命格")
            item = items[values[0]]
            row = config["soul"][str(item[1])]
            gate = config["soul_integrate_lv"].get(str(item[2] + 1), {}).get("battle_lv", 0)
            if item[2] >= row["limit1"] or save["role_state"]["level"] < gate:
                raise ValueError("命格已满级或队伍等级不足")
            costs = [(20099, integer(row["upexp"] * 2 ** (item[2] - 1), 1))]
            item[2] += 1
        elif opcode == 2506:
            if len(values) > LIMIT or set(values) & worn:
                raise ValueError("每批至多分解100个闲置命格")
            amount = sum(integer(config["soul"][str(items[iid][1])]["eatexp"], 1) for iid in values)
            for iid in values:
                del items[iid]
            reply = reward = activities.build_reward(save, f"20099,{amount}", config)
        else:
            if len(values) != 2 or set(values) & worn or save["role_state"]["level"] < config["build"]["255"]["level"]:
                raise ValueError("合成需要55级及两个闲置命格")
            a, b = [items[iid] for iid in values]
            row = next((r for r in config["soul_integrate"].values() if (a[1], b[1]) in ((r["main_id"], r["assist_id"]), (r["assist_id"], r["main_id"]))), None)
            if not row or a[2] != row["cond"] or b[2] != row["cond"]:
                raise ValueError("合成材料必须恰好达到配置等级，避免损失更高等级投入")
            for iid in values:
                del items[iid]
            iid = allocate(save)
            state = save["soul_state"]
            items[iid] = [iid, row["id"], row["cond"]]
    else:
        raise ValueError("命格接口未实现")
    for cid, amount in costs:
        available = (save["role_state"][{1000: "coin", 1001: "gold"}[cid]] if cid in (1000, 1001)
                     else pb_get_varint(formation.records(bytes.fromhex(save["world_state"]["1200"]), 1, 1).get(cid, b""), 2) or 0)
        if available < amount:
            raise ValueError("命格操作所需货币或材料不足")
    validate_slots(items, slots, save, config)
    update = b""
    if items != before or slots != old_slots:
        update = formation.apply_slots(save, slots, config, souls=items)
        inventory = b"".join(encode_pb_field(3, 2, record(item)) for _, item in sorted(items.items()))
        world = bytes.fromhex(save["world_state"]["1002"])
        save["world_state"]["1002"] = b"".join(encode_pb_field(n, w, raw) for n, w, raw in iter_pb_fields(world) if n != 3).hex()
        update += inventory
    if opcode in (1006, 1007, 2504, 2507):
        reply = update
    return reply, costs, reward, update
