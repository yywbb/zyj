"""乾坤炉：严格按所有权处理炼化；重生只返还可验证的实际材料。"""

from collections import Counter

from . import activities, equip_baptize, fashion, favorite, formation, general_foster, recharge, recruit
from .protocol import encode_pb_field, iter_pb_fields, parse_ids_pb, pb_get_varint, pb_set_varint

QUERIES = (3704, 3850, 7030, 3780)
MUTATIONS = (1036, 1037, 1039, 1104, 1035, 1117, 1077, 6901)
OPCODES = QUERIES + MUTATIONS


def get_state(save):
    state = save.setdefault("qiankun_state", {"quality": 4, "receipts": {}, "red_fragments": {}})
    if (not isinstance(state, dict) or type(state.get("quality")) is not int or state["quality"] not in range(2, 6)
            or not isinstance(state.get("receipts"), dict) or not isinstance(state.get("red_fragments"), dict)):
        raise ValueError("乾坤炉存档无效")
    for key, item in state["receipts"].items():
        if (not isinstance(key, str) or key.split(":")[0] not in ("general", "equip") or not isinstance(item, dict)
                or not isinstance(item.get("before"), str) or not isinstance(item.get("after"), str)
                or not isinstance(item.get("costs"), list)):
            raise ValueError("重生材料记录无效")
        for value in (item["before"], item["after"]):
            list(iter_pb_fields(bytes.fromhex(value)))
        if any(not isinstance(p, list) or len(p) != 2 or any(type(v) is not int or not 0 < v < (1 << 31) for v in p)
               for p in item["costs"]):
            raise ValueError("重生材料数量无效")
    if any(type(k) is not str or not k.isdecimal() or not 18001 <= int(k) <= 19000
           or type(v) is not int or not 0 <= v < (1 << 31) for k, v in state["red_fragments"].items()):
        raise ValueError("伙伴精华存档无效")
    return state


def protected(save):
    world = bytes.fromhex(save["world_state"]["1002"])
    iids = {pb_get_varint(v, 2) for n, w, v in iter_pb_fields(world) if n in (4, 5) and w == 2}
    iids.add(pb_get_varint(bytes.fromhex(save.get("protagonist_snapshot", "")), 1))
    iids.update(iid for team in save.get("single_boss_state", {}).get("teams", {}).values() if team for iid in team[:7])
    return iids - {None, 0}


def red_query(save, request, baseline=b""):
    if request:
        raise ValueError("伙伴精华查询不接受参数")
    state = get_state(save)["red_fragments"]
    seen, result, index = set(), bytearray(), 0
    for n, w, value in iter_pb_fields(baseline):
        if (n, w) == (1, 0):
            if index % 2 == 0:
                cid = value
                seen.add(str(cid))
            else:
                value = state.get(str(cid), 0)
            index += 1
        result.extend(encode_pb_field(n, w, value))
    if index % 2:
        raise ValueError("伙伴精华查询基线无效")
    result.extend(recharge.ids(v for key, count in sorted(state.items()) if key not in seen for v in (int(key), count)))
    return bytes(result)


def record_training(save, kind, before, after, costs, clean):
    iid = pb_get_varint(before, 2 if kind == "general" else 1)
    entries = get_state(save)["receipts"]
    key = f"{kind}:{iid}"
    previous = entries.get(key)
    if previous and previous["after"] != before.hex():
        entries.pop(key)
        previous = None
    if not previous and not clean:
        return
    entry = previous or {"before": before.hex(), "costs": []}
    total = Counter(dict(entry["costs"]))
    for cid, count in costs:
        total[cid] += count
    entry.update(after=after.hex(), costs=[[cid, count] for cid, count in sorted(total.items()) if count])
    entries[key] = entry
    get_state(save)


def pristine_general(raw, config, save=None):
    cid, iid = pb_get_varint(raw, 1), pb_get_varint(raw, 2)
    if str(cid) not in config["general"]:
        return False
    expected = favorite.add_bonus(recruit.new_general(cid, iid, config), save or {}, config)
    return (all((pb_get_varint(raw, n) or 0) == (pb_get_varint(expected, n) or 0) for n in range(1, 41))
            and not any(any(parse_ids_pb(v)) for n, w, v in iter_pb_fields(raw) if (n, w) == (41, 2)))


def item_pairs(body):
    entries = []
    for n, w, value in iter_pb_fields(body):
        if (n, w) != (1, 2):
            raise ValueError("炼化参数必须为物品和数量列表")
        fields = list(iter_pb_fields(value))
        if len(fields) != 2 or {n for n, _, _ in fields} != {1, 2} or any(w != 0 for _, w, _ in fields):
            raise ValueError("炼化物品参数无效")
        pair = {n: v for n, _, v in fields}
        if not 0 < pair[1] < (1 << 31) or not (0 < pair[2] <= 10000 or pair[2] == (1 << 64) - 1):
            raise ValueError("炼化物品数量无效")
        entries.append((pair[1], -1 if pair[2] == (1 << 64) - 1 else pair[2]))
    if not entries or len(entries) > 10 or len({cid for cid, _ in entries}) != len(entries):
        raise ValueError("炼化物品为空、重复或数量过多")
    return entries


def ids(body):
    fields = list(iter_pb_fields(body))
    if not 1 <= len(fields) <= 10 or any(n != 1 or w != 0 or not 0 < v < (1 << 31) for n, w, v in fields):
        raise ValueError("重生对象参数无效")
    values = [v for _, _, v in fields]
    if len(set(values)) != len(values):
        raise ValueError("重生对象重复")
    return values


def prepare(opcode, save, body, config):
    if opcode == 3780:
        return red_query(save, body), [], b""
    if not save.get("has_role"):
        raise ValueError("角色尚未创建")
    state = get_state(save)
    if save["role_state"]["level"] < config["build"]["161"]["level"]:
        raise ValueError("乾坤炉尚未解锁")
    if opcode in (3704, 7030):
        if body:
            raise ValueError("乾坤炉初始化查询不接受参数")
        return recharge.ids(sorted(protected(save))) if opcode == 3704 else recharge.ids([0] * 24), [], b""
    if opcode == 3850:
        if body:
            values = ids(body)
            if len(values) != 1 or values[0] not in range(2, 6):
                raise ValueError("炼化品质筛选无效")
            state["quality"] = values[0]
        return recharge.ids([state["quality"]]), [], b""
    world = bytes.fromhex(save["world_state"]["1002"])
    generals, equips = formation.records(world, 1, 2), formation.records(world, 2, 1)
    occupied = {pb_get_varint(v, f) for n, w, v in iter_pb_fields(world) if n in (4, 5) and w == 2 for f in range(4, 10)}
    removed = {1: set(), 2: set()}
    gets, costs, updates = Counter(), [], b""
    pairs = item_pairs(body) if opcode in (1036, 1039, 1104, 6901) else [(iid, -1) for iid in ids(body)]
    if opcode in (1035, 1117, 1077) and len(pairs) != 1:
        raise ValueError("重生每次仅支持一个对象")
    if len(pairs) > (10 if save["role_state"]["level"] >= int(config["global_kv"]["recycle_10_level"]["value"]) else 5):
        raise ValueError("乾坤炉批量数量尚未解锁")
    for iid, count in pairs:
        if opcode in (1036, 1039) and count > 0:
            row = config["general_fragment"].get(str(iid))
            if not row or config["general"][str(row["general"])]["quality"] <= 1:
                raise ValueError("请选择实际拥有的伙伴碎片，完整伙伴必须使用IID")
            costs.append((iid, count))
            gets[20200] += row["stovestone"] * count
        elif opcode == 1104 and count > 0:
            row = config["equip_fragment"].get(str(iid)) or config["treasure2_fragment"].get(str(iid))
            if not row or row.get("whether_refining", 1) != 1:
                raise ValueError("此装备碎片不能炼化")
            costs.append((iid, count))
            gets.update({int(cid): int(num) * count for e in row["resolve"].split(";") if e for cid, num in [e.split(",")]})
        elif opcode in (1037, 1039, 1035):
            raw = generals.get(iid)
            if count != -1 or raw is None or iid in protected(save):
                raise ValueError("伙伴不存在或正在上阵/助阵，不能炼化或重生")
            row = config["general"][str(pb_get_varint(raw, 1))]
            if opcode == 1035:
                receipt = state["receipts"].get(f"general:{iid}")
                if not receipt or receipt["after"] != raw.hex():
                    raise ValueError("此伙伴缺少完整消耗记录，安全保护：未扣款、未重生")
                baseline = bytes.fromhex(receipt["before"])
                if not pristine_general(baseline, config, save):
                    raise ValueError("伙伴重生基线无效")
                gets.update(dict(receipt["costs"]))
                used = general_foster.used_potential(raw, config)
                divisor = int(config["global_kv"]["general_rebirth_potential"]["value"])
                price = int(config["global_kv"]["general_rebirth_potentialcost"]["value"])
                if divisor <= 0 or price < 0:
                    raise ValueError("培养重生费用配置无效")
                costs.append((1001, config["renascence"][str(pb_get_varint(raw, 3))]["generallvcost"]
                              + config["renascence"][str(pb_get_varint(raw, 4) or 0)]["breakcost"] + (2*used*price+divisor)//(2*divisor)))
                updates += encode_pb_field(8, 2, baseline)
                del state["receipts"][f"general:{iid}"]
                general_foster.remove(save, iid)
            else:
                if not pristine_general(raw, config, save):
                    raise ValueError("强化过的伙伴请先安全重生，炼化未执行")
                fragment = next((v for v in config["general_fragment"].values() if v["general"] == row["init_cid"]), None)
                if not fragment:
                    raise ValueError("此伙伴没有炼化配置")
                gets[20200] += fragment["stovestone"] * fragment["num"]
                if opcode == 1037:
                    costs.append((1000, int(config["global_kv"][f'{row["quality"]}_soul_cost']["value"])))
                removed[1].add(iid)
        elif opcode in (1104, 1117):
            if count != -1 or iid not in equips or iid in occupied:
                raise ValueError("装备不存在或已穿戴，不能炼化或重生")
            item = parse_ids_pb(equips[iid])
            row = equip_baptize.validate(item, config)
            if row["quality"] not in range(2, 8) or str(item[2]) not in config["equip_strengthen"]:
                raise ValueError("此装备等级或品质暂不支持炼化重生")
            if opcode == 1117:
                receipt = state["receipts"].get(f"equip:{iid}")
                if not receipt or receipt["after"] != equips[iid].hex():
                    raise ValueError("此装备缺少完整消耗记录，安全保护：未扣款、未重生")
                baseline = parse_ids_pb(bytes.fromhex(receipt["before"]))
                if baseline[:3] != [iid, item[1], 1] or any(baseline[3:]):
                    raise ValueError("装备重生基线无效")
                gets.update(dict(receipt["costs"]))
                fee = (config["renascence"][str(item[2])]["treasurerecost"] + config["renascence"][str(item[3] if len(item) > 3 else 0)]["treasurerefinecost"]
                       if row["type"] in ("horse", "treasure") else config["renascence"][str(item[2])]["strengthencost"]
                       + (int(config["global_kv"]["equip_baptize_cost"]["value"]) if len(item) > 10 and item[10] else 0))
                costs.append((1001, fee))
                updates += encode_pb_field(6, 2, bytes.fromhex(receipt["before"]))
                del state["receipts"][f"equip:{iid}"]
            else:
                if any(item[3:]):
                    raise ValueError("洗炼过的装备请先安全重生，炼化未执行")
                if row.get("whether_refining", 1) != 1 or row["type"] in ("horse", "treasure") and item[2] != 1:
                    raise ValueError("此装备请先重生或不允许炼化")
                gets.update({int(cid): int(num) for e in row["resolve"].split(";") if e for cid, num in [e.split(",")]})
                gets[1000] += row["sellprice"]
                if row["type"] not in ("horse", "treasure"):
                    gets[1000] += config["equip_strengthen"][str(item[2])][f'Trafficking{row["quality"]}']
                removed[2].add(iid)
            equip_baptize.get_state(save, config)["pending"].pop(str(iid), None)
        elif opcode == 6901:
            row = config["redl_awake_item"].get(str(iid))
            if not row or row["decompose"] != 1 or count <= 0 or state["red_fragments"].get(str(iid), 0) < count:
                raise ValueError("伙伴精华数量不足或不可分解")
            state["red_fragments"][str(iid)] -= count
            gets.update({int(cid): int(num) * count for e in row["decompose_prop"].split(";") if e for cid, num in [e.split(",")]})
        elif opcode == 1077:
            levels = fashion.get_state(save, config)["levels"]
            if str(iid) not in levels or levels[str(iid)] <= 1:
                raise ValueError("时装未拥有或没有可重生的强化等级")
            previous = fashion.attributes(levels, config)
            level = levels[str(iid)]
            for lv in range(1, level):
                gets.update({int(cid): int(num) for e in config["fashionintentify"][str(iid)][str(lv)]["use"].split(";") if e for cid, num in [e.split(",")]})
            costs.append((1001, config["renascence"][str(level)]["fashion_reborn"]))
            levels[str(iid)] = 1
            current = fashion.attributes(levels, config)
            protagonist = pb_get_varint(bytes.fromhex(save["protagonist_snapshot"]), 1)
            raw, power = generals[protagonist], 0
            for field in previous:
                old = pb_get_varint(raw, field)
                value = old + current[field] - previous[field]
                if not 0 < value < (1 << 31):
                    raise ValueError("重生后的时装属性无效")
                power += value // 10 - old // 10 if field == 8 else value - old
                raw = pb_set_varint(raw, field, value)
            raw = pb_set_varint(raw, 20, pb_get_varint(raw, 20) + power)
            for key in ("power", "power_all"):
                save["role_state"][key] += power
            updates += encode_pb_field(8, 2, raw)
        else:
            raise ValueError("此乾坤炉操作尚未支持，未更改物品")
    save["world_state"]["1002"] = b"".join(encode_pb_field(n, w, v) for n, w, v in iter_pb_fields(world)
        if not (n in removed and w == 2 and pb_get_varint(v, 2 if n == 1 else 1) in removed[n])).hex()
    for n, removed_ids in removed.items():
        for iid in removed_ids:
            state["receipts"].pop(f'{"general" if n == 1 else "equip"}:{iid}', None)
            if n == 1:
                general_foster.remove(save, iid)
    reward = activities.build_reward(save, ";".join(f"{cid},{num}" for cid, num in gets.items() if num), config) + updates
    return reward, [(cid, num) for cid, num in costs if num], reward
