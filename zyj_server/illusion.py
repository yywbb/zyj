"""限时幻影、伙伴绑定及战斗投影；原伙伴养成和缘分始终保留。"""

import random
import time

from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint, pb_set_field

QUERIES = (8110, 8113, 8115, 8117, 8252)
MUTATIONS = (8111, 8112, 7021)
OPCODES = QUERIES + MUTATIONS
UTC8 = 28800


def ids_body(values):
    return b"".join(encode_pb_field(1, 0, v) for v in values)


def parse_ids(body):
    fields = list(iter_pb_fields(body))
    if any((n, w) != (1, 0) or not 0 <= v < 1 << 31 for n, w, v in fields):
        raise ValueError("幻化参数无效")
    return [v for _, _, v in fields]


def get_state(save, config):
    state = save.get("illusion_state", {"items": {}})
    if not isinstance(state, dict) or not isinstance(state.get("items"), dict):
        raise ValueError("幻化存档无效")
    for key in ("serial", "checked_at"):
        value = state.get(key, 0)
        if type(value) is not int or not 0 <= value < 1 << (31 if key == "serial" else 63):
            raise ValueError("幻化序号或时钟无效")
    bound = set()
    for cid, entry in state["items"].items():
        if (not isinstance(cid, str) or cid not in config["illusion"]
                or not isinstance(entry, list) or len(entry) != 2
                or any(type(v) is not int or not 0 <= v < 1 << 31 for v in entry) or not entry[1]
                or entry[0] and entry[0] in bound):
            raise ValueError("幻影所有权、有效期或绑定无效")
        if entry[0]:
            bound.add(entry[0])
    return {**state, "serial": state.get("serial", 0), "checked_at": state.get("checked_at", 0),
            "items": {k: v[:] for k, v in state["items"].items()}}


def values(raw):
    fields = [(w, v) for n, w, v in iter_pb_fields(raw) if n == 41]
    if len(fields) > 1 or fields and fields[0][0] != 2:
        raise ValueError("伙伴幻化字段重复")
    return parse_ids(fields[0][1]) if fields else []


def validate_general(raw, config):
    data = values(raw)
    if not any(data):
        return
    if (len(data) < 9 or len(data) > 12 or str(data[0]) not in config["illusion"]
            or any(data[9:]) or data[7] > 100 or str(data[8]) not in config["general"]):
        raise ValueError("伙伴含未知幻化、时装或专属属性")
    target = config["general"][str(data[8])]
    if target["init_cid"] != config["general"][str(config["illusion"][str(data[0])]["general_id"])]["init_cid"]:
        raise ValueError("幻影与伙伴形态不一致")
    for i, choice in enumerate(data[1:4], 1):
        if choice and (choice not in (1, 2, 3) or not target.get(f"gold{i}_will_skills_{choice}")):
            raise ValueError("幻影彩金技能选择无效")
    if any(data[4:6]):
        raise ValueError("未知幻影技能字段")


def validate_ownership(save, config):
    from . import formation
    if "illusion_state" not in save:
        return
    state = get_state(save, config)
    roster = formation.records(bytes.fromhex(save["world_state"]["1002"]), 1, 2)
    for cid, (iid, _) in state["items"].items():
        if iid and (iid not in roster or values(roster[iid])[:1] != [int(cid)]):
            raise ValueError("幻影绑定与实际伙伴不一致")
    for iid, raw in roster.items():
        validate_general(raw, config)
        data = values(raw)
        if data and data[0] and state["items"].get(str(data[0]), [0])[0] != iid:
            raise ValueError("伙伴幻影缺少真实所有权")


def grant(save, cid, count, config, now):
    """只生成奖励，实际所有权由 apply_reward 原子应用，预览不得赠送幻影。"""
    row = config["illusion"].get(str(cid))
    state = get_state(save, config)
    if not row or type(count) is not int or not 0 < count < 1 << 31 or now < state["checked_at"]:
        raise ValueError("幻影奖励或服务器时间无效")
    iid, end = state["items"].get(str(cid), [0, 0])
    if end <= now:
        iid = 0
    end = (max(end, now) + row["time"] * 86400 * count + UTC8 + 86399) // 86400 * 86400 - UTC8
    if not 0 < end < 1 << 31:
        raise ValueError("幻影有效期超出协议范围")
    return [cid, iid, end, count]


def receive_reward(save, body, config, now):
    from . import formation
    data = parse_ids(body)
    if not data or len(data) % 4 or len(set(data[::4])) != len(data) // 4:
        raise ValueError("幻影奖励数据无效")
    state = get_state(save, config)
    for i in range(0, len(data), 4):
        cid, iid, end, count = data[i:i+4]
        if [cid, iid, end, count] != grant(save, cid, count, config, now):
            raise ValueError("幻影奖励有效期与当前所有权不一致")
        old_iid, old_end = state["items"].get(str(cid), [0, 0])
        if old_iid and old_end <= now:
            roster = formation.records(bytes.fromhex(save["world_state"]["1002"]), 1, 2)
            write_general(save, roster[old_iid], with_illusion(roster[old_iid], None))
        state["items"][str(cid)] = [iid, end]
    state["serial"] += 1
    if state["serial"] >= 1 << 31:
        raise ValueError("幻化序号已达上限")
    state["checked_at"] = now
    save["illusion_state"] = state


def reward_field(rows):
    return encode_pb_field(18, 2, ids_body(v for row in rows for v in row)) if rows else b""


def chain(general_id, config):
    generals = config["general"]
    origin = generals[str(general_id)]["init_cid"]
    row = generals[str(origin)]
    red = origin if row["quality"] == 6 else row["break_id"]
    gold = generals.get(str(red), {}).get("gold_id", 0)
    return [general_id, red or general_id, gold or red or general_id]


def target_cid(source_cid, illusion_cid, config):
    quality = config["general"][str(source_cid)]["quality"]
    return chain(config["illusion"][str(illusion_cid)]["general_id"], config)[2 if quality == 7 else int(quality == 6)]


def metadata(raw, cid, config, seed=0):
    source = config["general"][str(pb_get_varint(raw, 1))]
    target = target_cid(pb_get_varint(raw, 1), cid, config)
    row = config["general"][str(target)]
    advance = pb_get_varint(raw, 4) or 0
    if not 0 <= advance <= 16:
        raise ValueError("幻化伙伴突破等级无效")
    old = values(raw)
    data = [cid, 0, 0, 0, 0, 0, 0, 0, target] + (old[9:] if len(old) > 9 else [0, 0])
    rng = random.Random(seed)
    for i in range(1, max(0, min(advance, row["breach_upper_limit"])-13)+1):
        options = [s for s in (1, 2, 3) if row.get(f"gold{i}_will_skills_{s}")]
        data[i] = old[i] if old and old[0] == cid and old[i] in options else rng.choice(options)
    packed = data[1]*100 + data[2]*10 + data[3]
    data[6] = config["jinjiangkezhiguanxi"].get(str(packed), {}).get("camp", 0)
    diff = max(0, advance-row["breach_upper_limit"])
    # 原表仅有20/23两档；23以上归高资质，低档向高档不衰减。
    origin = config["general"][str(source["init_cid"])]
    target_origin = config["general"][str(row["init_cid"])]
    a, b = (23 if r["basic"] > 20 else 20 for r in (origin, target_origin))
    data[7] = config["illusion_attenuation"][str(diff)].get(f"illusion_ratio_{a}_{b}", 0)
    return data


def with_illusion(raw, data):
    old = values(raw)
    if not data:
        data = [0]*9 + old[9:] if len(old) > 9 else []
    return pb_set_field(raw, 41, 2, ids_body(data))


def write_general(save, raw, changed):
    from . import player
    iid = pb_get_varint(raw, 2)
    receipt = save.get("qiankun_state", {}).get("receipts", {}).get(f"general:{iid}")
    if receipt and receipt["after"] == raw.hex():
        receipt["after"] = changed.hex()
    update = encode_pb_field(1, 2, changed)
    player.record_slot_update(save, update)
    return update


def check_combat(raw, data, config):
    from . import battle
    row = config["general"][str(data[8])]
    unit = dict(cid=data[8], iid=pb_get_varint(raw, 2), level=pb_get_varint(raw, 3),
                advance=min(pb_get_varint(raw, 4) or 0, row["breach_upper_limit"]), skill=row["skillid"],
                skilllevel=0, atk=100, hp=1000, speed=100, **{"def": 0})
    unit["partner_skills"] = [row[f"gold{i}_will_skills_{data[i]}"] for i in range(1, 4) if data[i]]
    battle._prepare_teams({True: {2: unit.copy()}, False: {2: unit.copy()}}, config)


def identities(raw, config):
    result = {config["general"][str(pb_get_varint(raw, 1))]["init_cid"]}
    data = values(raw)
    if data and data[0]:
        validate_general(raw, config)
        result.add(config["general"][str(data[8])]["init_cid"])
    return result


def validate_slots(generals, iids, config):
    seen = set()
    for iid in sorted(iids):
        current = identities(generals[iid], config)
        if current & seen:
            raise ValueError("幻化本体或幻影同源伙伴不能重复上阵、助阵")
        seen.update(current)


def query(save, config):
    state = get_state(save, config)
    return (ids_body(v for cid, entry in sorted(state["items"].items(), key=lambda p: int(p[0])) for v in (int(cid), *entry))
            + encode_pb_field(100, 2, ids_body([state["serial"]])))


def synchronize(save, config, now):
    from . import formation
    if "illusion_state" not in save:
        return b""
    state = get_state(save, config)
    if now < state["checked_at"]:
        return b""
    roster = formation.records(bytes.fromhex(save["world_state"]["1002"]), 1, 2)
    update = b""
    for cid, (iid, end) in list(state["items"].items()):
        if iid and iid not in roster:
            raise ValueError("幻化伙伴已丢失，拒绝重建所有权")
        raw = roster.get(iid)
        if end <= now:
            del state["items"][cid]
            data = None
        elif raw:
            data = metadata(raw, int(cid), config)
        else:
            continue
        if raw:
            changed = with_illusion(raw, data)
            if changed != raw:
                update += write_general(save, raw, changed)
                roster[iid] = changed
    if update or state["items"] != save["illusion_state"]["items"]:
        state["serial"] += 1
    if state["serial"] >= 1 << 31:
        raise ValueError("幻化序号已达上限")
    state["checked_at"] = now
    save["illusion_state"] = state
    return update


def effective(raw, save, config, kind="pve", now=None):
    validate_general(raw, config)
    data = values(raw)
    if not data or not data[0] or kind == "none":
        return None
    now = save.get("illusion_frozen_at", int(time.time()) if now is None else now)
    entry = get_state(save, config)["items"].get(str(data[0]))
    if (not entry or entry[0] != pb_get_varint(raw, 2) or entry[1] <= now
            or save["role_state"]["vip"] < int(config["global_kv"]["illusion_pvp_1" if kind == "pvp" else "illusion_pve_1"]["value"])):
        return None
    return metadata(raw, data[0], config)


def prepare(opcode, save, body, config, now):
    from . import formation, partner_growth
    request = parse_ids(body)
    if opcode in (8113, 8115, 8117, 8252):
        # shortcut: 活动订单/周期/任务未接通，完整接入并验收后再开放。
        if (opcode == 8252 and request not in ([], [1])) or (opcode != 8252 and request):
            raise ValueError("幻化活动或阵容查询参数无效")
        return b"", b""
    if opcode == 8110:
        if request not in ([], [0], [1]):
            raise ValueError("幻影查询只接受刷新标记")
        return query(save, config), b""
    if (not save.get("has_role") or save["role_state"]["level"] < config["build"]["599"]["level"]
            or save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2):
        raise ValueError("65级并完成引导后才能幻化")
    state = get_state(save, config)
    if now < state["checked_at"]:
        raise ValueError("服务器时间回拨，幻化未结算")
    roster = formation.records(bytes.fromhex(save["world_state"]["1002"]), 1, 2)
    if opcode == 7021:
        if len(request) < 6 or len(request) % 2 or request[0] != 1:
            raise ValueError("仅接通幻影彩金技能改选")
        _, source, cid, serial, *choices = request
        entry = state["items"].get(str(cid))
        iid = entry[0] if entry else 0
    else:
        if len(request) != 5:
            raise ValueError("幻化需要幻影、伙伴、显示有效期、原绑定和序号")
        cid, iid, end, previous, serial = request
        entry = state["items"].get(str(cid))
        if entry != [previous, end]:
            raise ValueError("幻影或绑定已变化，请重新打开页面")
    if not entry or entry[1] <= now or serial != state["serial"] or iid not in roster:
        raise ValueError("幻影已过期、目标或序号已变化")
    raw = roster[iid]
    if config["general"][str(pb_get_varint(raw, 1))].get("actor") == "lead":
        raise ValueError("主角不能幻化")
    validate_general(raw, config)
    if opcode == 8111:
        if (pb_get_varint(raw, 4) or 0) > 10 or any(pb_get_varint(raw, f) for f in range(21, 41)):
            partner_growth.validate(raw, config)
        if entry[0] or any(e[0] == iid for e in state["items"].values()):
            raise ValueError("请先解除已有幻化")
        target = config["general"][str(config["illusion"][str(cid)]["general_id"])]["init_cid"]
        if not config["general"][str(pb_get_varint(raw, 1))].get("battle") or target in identities(raw, config):
            raise ValueError("不能幻化自身或经验伙伴")
        for other, binding in state["items"].items():
            if binding[0] and (target in identities(roster[binding[0]], config)
                              or identities(raw, config) & identities(roster[binding[0]], config)):
                raise ValueError("本体或幻影已存在幻化关系")
        data = metadata(raw, cid, config, random.getrandbits(64))
        check_combat(raw, data, config)
        entry[0] = iid
    elif opcode == 8112:
        if entry[0] != iid:
            raise ValueError("幻化伙伴已变化")
        data = None
        entry[0] = 0
    else:
        if pb_get_varint(raw, 1) != source:
            raise ValueError("幻影技能目标已变化")
        data = metadata(raw, cid, config)
        seen = set()
        for stage, choice in zip(choices[::2], choices[1::2]):
            if stage not in (1, 2, 3) or stage in seen or not data[stage] or choice not in (1, 2, 3):
                raise ValueError("幻影彩金技能阶数或选择无效")
            seen.add(stage)
            data[stage] = choice
        row = config["general"][str(data[8])]
        if any(not row.get(f"gold{i}_will_skills_{data[i]}") for i in seen):
            raise ValueError("幻影没有此彩金技能")
        data[6] = config["jinjiangkezhiguanxi"][str(data[1]*100+data[2]*10+data[3])]["camp"]
        check_combat(raw, data, config)
    changed = with_illusion(raw, data)
    roster[iid] = changed
    world = bytes.fromhex(save["world_state"]["1002"])
    assigned = {pb_get_varint(v, 2) for n, w, v in iter_pb_fields(world) if n in (4, 5) and w == 2} - {None, 0}
    validate_slots(roster, assigned, config)
    state.update(serial=state["serial"]+1, checked_at=now)
    save["illusion_state"] = state
    get_state(save, config)
    update = write_general(save, raw, changed)
    return (b"" if opcode == 8112 else update) + encode_pb_field(100, 2, query(save, config)), update
