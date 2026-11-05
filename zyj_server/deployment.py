"""48级灵阵图：七阵等级、真实阵位条件及最高阵服加成。"""

from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint

QUERIES = (4200, 4204)
MUTATIONS = (4201, 4202)
OPCODES = QUERIES + MUTATIONS
FIELDS = {"atk": 6, "def": 7, "hp": 8}


def get_state(save, config):
    state = save.get("deployment_state", {"use": 0, "levels": [0]*7, "checked_at": 0})
    if (not isinstance(state, dict) or type(state.get("use")) is not int or not 0 <= state["use"] <= 7
            or type(state.get("checked_at")) is not int or not 0 <= state["checked_at"] < (1 << 63)
            or not isinstance(state.get("levels"), list) or len(state["levels"]) != 7
            or any(type(v) is not int or not (1 if state["use"] else 0) <= v <= (len(config["lingzhentu_lv"]) if state["use"] else 0)
                   for v in state["levels"])):
        raise ValueError("灵阵图存档无效")
    return state


def matches(raw, condition, config):
    row = config["general"][str(pb_get_varint(raw, 1))]
    for i in (1, 2):
        kind, target = condition[f"param{i}"], condition[f"param{i}_cond"]
        if kind == 1:
            valid = target in row["region"].strip(";").split(";")
        elif kind == 5:
            valid = row["sex"] == target
        elif kind in (2, 3, 6):
            current = row["basic"] if kind == 6 else pb_get_varint(raw, 3 if kind == 2 else 4) or 0
            valid = current >= int(target)
        else:
            raise ValueError("灵阵图条件配置无效")
        if not valid:
            return False
    return True


def mastery(state, config):
    active = []
    for key, row in sorted(config["lingzhentu_add"].items(), key=lambda p: int(p[0])):
        count, level = map(int, row["cond1"].rstrip(";").split(","))
        if sum(v >= level for v in state["levels"]) >= count:
            active.append(int(key))
    return max((config["lingzhentu_add"][str(k)]["effect"] for k in active), default=0), active


def bonuses(save, config):
    from . import formation

    state = get_state(save, config)
    activation, values = [0]*7, dict.fromkeys(FIELDS.values(), 0)
    if not state["use"]:
        return {}, activation
    world = bytes.fromhex(save["world_state"]["1002"])
    generals, slots = formation.records(world, 1, 2), formation.records(world, 4, 1)
    members = []
    maximum = min(7, config["role_exp"][str(save["role_state"]["level"])]["slotnum"])
    for sid, slot in slots.items():
        iid = pb_get_varint(slot, 2)
        if not iid:
            continue
        if not 1 <= sid <= maximum or iid not in generals or iid in members:
            raise ValueError("灵阵图阵位或伙伴无效")
        members.append(iid)
        activation[sid-1] = int(matches(generals[iid], config["lingzhentu_cond"][str(state["use"])][str(sid)], config))
    level = state["levels"][state["use"]-1]
    add, _ = mastery(state, config)
    for i in range(1, sum(activation)+1):
        name, amount = config["lingzhentu_jihuo"][str(state["use"])][str(i)][f"addition{level}"].rstrip(";").split(",")
        if name not in FIELDS or int(amount) < 0:
            raise ValueError("灵阵图属性配置无效")
        values[FIELDS[name]] += int(amount)
    values = {f: v*(100+add)//100 for f, v in values.items()}
    return {iid: values for iid in members}, activation


def differences(save, previous, config):
    from . import development, formation

    old, _ = bonuses(previous, config)
    new, _ = bonuses(save, config)
    if old == new:
        return b"", 0
    generals = formation.records(bytes.fromhex(save["world_state"]["1002"]), 1, 2)
    update, power = b"", 0
    for iid in sorted((old.keys() | new.keys()) & generals.keys()):
        changes = {f: new.get(iid, {}).get(f, 0)-old.get(iid, {}).get(f, 0) for f in FIELDS.values()}
        if not any(changes.values()):
            continue
        raw, delta = development.adjust(generals[iid], changes)
        update += encode_pb_field(1, 2, raw)
        if iid in new:
            power += delta
    return update, power


def query(save, config, *, addition=False):
    from . import formation, general_foster, recharge

    state = get_state(save, config)
    add, active = mastery(state, config)
    if addition:
        return recharge.ids([add, *active])
    values, activation = bonuses(save, config)
    generals = formation.records(bytes.fromhex(save["world_state"]["1002"]), 1, 2)
    power = sum(v[6]+v[7]+(pb_get_varint(generals[iid], 8)//10-(pb_get_varint(generals[iid], 8)-v[8])//10)
                for iid, v in values.items())
    if not 0 <= power < (1 << 31):
        raise ValueError("灵阵图战力超出范围")
    return general_foster.comb(((0, recharge.ids([state["use"], add, power])),
                               (1, recharge.ids(state["levels"])), (2, recharge.ids(activation))))


def prepare(opcode, save, body, config, now):
    fields = list(iter_pb_fields(body))
    if (any(n != 1 or w != 0 or not 0 <= v < (1 << 31) for n, w, v in fields)
            or len(fields) != {4200: 0, 4201: 1, 4202: 2, 4204: 0}[opcode]):
        raise ValueError("灵阵图请求参数无效")
    state, costs = get_state(save, config), []
    unlocked = save.get("has_role") and save["role_state"]["level"] >= config["build"]["198"]["level"]
    if not unlocked:
        if opcode in MUTATIONS:
            raise ValueError("灵阵图尚未解锁")
        return query(save, config, addition=opcode == 4204), costs
    if opcode in MUTATIONS and (now < state["checked_at"] or not state["use"]):
        raise ValueError("请先查询灵阵图，服务器时钟不能回拨")
    if not state["use"]:
        state = dict(state, use=1, levels=[1]*7)
    state["checked_at"] = max(now, state["checked_at"])
    save["deployment_state"] = state
    if opcode in MUTATIONS:
        cid = fields[0][2]
        if str(cid) not in config["lingzhentu_zhenfa"]:
            raise ValueError("灵阵图不存在")
        if opcode == 4201:
            state["use"] = cid
        else:
            level = state["levels"][cid-1]
            row = config["lingzhentu_lv"][str(level)]
            if fields[1][2] != level or str(level+1) not in config["lingzhentu_lv"] or save["role_state"]["level"] < row["lv_cond"]:
                raise ValueError("灵阵图等级已变化、已满级或队伍等级不足")
            costs = [tuple(map(int, item.split(","))) for item in row["cost"].split(";") if item]
            if (not costs or len({c for c, _ in costs}) != len(costs)
                    or any(c not in (1000, 20293) or n <= 0 for c, n in costs)):
                raise ValueError("灵阵图费用配置无效")
            state["levels"][cid-1] += 1
    return query(save, config, addition=opcode == 4204), costs
