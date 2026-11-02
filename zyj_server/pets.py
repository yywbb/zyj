"""魔宠所有权、养成、共享技能及战前数据；成本和属性由 player 原子提交。"""

import random
from collections import Counter
from fractions import Fraction

from . import recharge, recruit
from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint

QUERIES = (1040, 1044, 1047)
MUTATIONS = (1043, 1046, 1048, 1049, 1060, 1061, 1062, 1064, 1065)
OPCODES = QUERIES + MUTATIONS
UNSUPPORTED = (1041, 1042, 1045, 1066)
ATTR_FIELDS = {"atk": 6, "def": 7, "hp": 8, "dodge": 11, "resilience": 13, "arp": 15}


def get_state(save, config):
    state = save.setdefault("pet_state", {"active": 0, "pets": [], "starter_claimed": False})
    if (not isinstance(state, dict) or type(state.get("active")) is not int
            or type(state.get("starter_claimed")) is not bool or not isinstance(state.get("pets"), list)):
        raise ValueError("魔宠存档无效")
    for pet in state["pets"]:
        if (not isinstance(pet, list) or len(pet) != 4 or any(type(v) is not int for v in pet)
                or not 5000000 < pet[0] < (1 << 31) or str(pet[1]) not in config["pet3_attr"]
                or str(pet[2]) not in config["pet3_attr"][str(pet[1])]
                or str(pet[3]) not in config["pet3_illustrated"][str(pet[1])]):
            raise ValueError("魔宠存档含无效的进阶或图鉴等级")
    if (len({p[0] for p in state["pets"]}) != len(state["pets"])
            or len({p[1] for p in state["pets"]}) != len(state["pets"])
            or state["active"] not in {0, *(p[0] for p in state["pets"])}):
        raise ValueError("魔宠重复或上阵所有权无效")
    skills = state.setdefault("skills", [[0, 0] for _ in range(5)])
    spent = state.setdefault("spent_points", 0)
    if (not isinstance(skills, list) or len(skills) != 5 or type(spent) is not int or not 0 <= spent < (1 << 31)):
        raise ValueError("魔宠技能存档无效")
    limit = int(config["global_kv"]["pet3_passiveskill_limit"]["value"])
    for skill in skills:
        if (not isinstance(skill, list) or len(skill) != 2 or any(type(v) is not int for v in skill)
                or skill != [0, 0] and (str(skill[0]) not in config["pet3_passiveskill"]
                                       or not 1 <= skill[1] <= limit)):
            raise ValueError("魔宠技能或等级无效")
    known = [cid for cid, _ in skills if cid]
    if (len(set(known)) != len(known) or any(cid for cid, _ in skills[skill_slots(state, config):])
            or spent != sum(level for _, level in skills) * int(config["global_kv"]["pet3_passiveskill_spot"]["value"])):
        raise ValueError("魔宠技能重复、未解锁或技能点记录无效")
    locks = state.setdefault("locks", [0] * 5)
    if (not isinstance(locks, list) or len(locks) != 5
            or any(type(v) is not int or v not in (0, 1) or v and not skills[i][0] for i, v in enumerate(locks))
            or sum(locks) > int(config["global_kv"]["pet3_passiveskill_lock"]["value"])):
        raise ValueError("魔宠技能锁定记录无效")
    if min(quality_points(state, config)) < 0:
        raise ValueError("魔宠红色或彩金技能点记录无效")
    if type(state.setdefault("owned_stats", False)) is not bool:
        raise ValueError("魔宠属性迁移标记无效")
    receipts = state.setdefault("receipts", {})
    if not isinstance(receipts, dict):
        raise ValueError("魔宠养成收据无效")
    for key, receipt in receipts.items():
        pet = next((p for p in state["pets"] if str(p[0]) == key), None)
        if (not isinstance(receipt, dict) or receipt.get("pet") != pet or pet is None
                or not isinstance(receipt.get("costs"), list)
                or any(not isinstance(e, list) or len(e) != 2 or any(type(v) is not int or v <= 0 for v in e) or e[0] >= (1 << 31)
                       for e in receipt["costs"])
                or len({e[0] for e in receipt["costs"]}) != len(receipt["costs"])):
            raise ValueError("魔宠养成收据与当前状态不符")
    return state


def skill_slots(state, config, active=False):
    return max((config["pet3_talentskill"][str(config["pet3_attr"][str(p[1])][str(p[2])]["talentskill"])]["number"]
                for p in state["pets"] if not active or p[0] == state["active"]), default=0)


def quality_points(state, config):
    total = [0, 0]
    for pet in state["pets"]:
        for phase, row in config["pet3_attr"][str(pet[1])].items():
            if int(phase) <= pet[2] and row["skill_points"]:
                total[row["quality"] - 6] += row["skill_points"]
    for cid, _ in state["skills"]:
        if cid:
            quality = config["pet3_passiveskill"][str(cid)]["quality"]
            total[0] -= int(quality >= 6)
            total[1] -= int(quality >= 7)
    return total


def skill_points(save, config):
    level = save.get("role_state", {}).get("level", 1)
    return sum(config["role_exp"][str(lv)]["pet3_number"] for lv in range(config["build"]["49"]["level"], level + 1))


def attributes(save, config):
    values = {field: Fraction(0) for field in ATTR_FIELDS.values()}
    if not save.get("pet_state"):
        return values
    state = get_state(save, config)
    if state["active"]:
        for cid, level in state["skills"][:skill_slots(state, config, active=True)]:
            if cid:
                row = config["pet3_passiveskill"][str(cid)]
                amount = Fraction(str(row["init"])) + Fraction(str(row["init_grow"])) * (level - 1)
                values[ATTR_FIELDS[row["attr"]]] += amount * (100 if row["attr"] in ("dodge", "resilience", "arp") else 1)
    if state["owned_stats"]:
        for _, cid, phase, collect in state["pets"]:
            rows = config["pet3_attr"][str(cid)]
            for i in range(1, 4):
                values[ATTR_FIELDS[rows["0"][f"attr{i}"]]] += (Fraction(str(rows["0"][f"init{i}"]))
                    + config["pet3_illustrated"][str(cid)][str(collect)][f"attr{i}"])
            for step in range(1, phase + 1):
                row = rows[str(step)]
                for i in range(1, 5):
                    if row[f"attr{i}"]:
                        values[ATTR_FIELDS[row[f"attr{i}"]]] += Fraction(str(row[f"init{i}"]))
    return values


def combat(save, config):
    if not save.get("pet_state"):
        return None
    state = get_state(save, config)
    pet = next((p for p in state["pets"] if p[0] == state["active"]), None)
    return {"iid": pet[0], "cid": pet[1], "phase": pet[2], "level": pet[3]} if pet else None


def fragments(save, config):
    rows = {pb_get_varint(v, 1): pb_get_varint(v, 2) or 0
            for n, w, v in iter_pb_fields(bytes.fromhex(save["world_state"]["1200"])) if (n, w) == (1, 2)}
    return {int(cid): rows.get(int(cid), 0) for cid in config["pet3_fragment"]}


def starter(save, config):
    state = get_state(save, config)
    section = save.get("guide", {}).get("sections", {}).get("59", {})
    if (not save.get("has_role") or save["role_state"]["level"] < config["build"]["49"]["level"]
            or save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2
            or state["starter_claimed"] or state["pets"] or section.get("status") == 2 or section.get("step", 0) >= 3):
        return 0
    # 用户确认的本地规则：首次进入魔宠引导只补足一只炽炎犬的碎片，收据与库存一起落盘。
    state["starter_claimed"] = True
    return max(0, config["pet3_fragment"]["91001"]["number"] - fragments(save, config)[91001])


def skills(save, state, config):
    unlocked = skill_slots(state, config)
    active = skill_slots(state, config, active=True)
    points = max(0, skill_points(save, config) - state["spent_points"])
    return recharge.ids([points, *quality_points(state, config), *(v for i in range(5) for v in
                                       (state["skills"][i][0], 2 if i < active else 1 if i < unlocked else 0,
                                        state["skills"][i][1], state["locks"][i]))])


def record_costs(state, pet, before, costs):
    receipt = state["receipts"].get(str(pet[0]))
    if receipt is None and before[2:] != [0, 1]:
        return  # shortcut: 外部旧养成没有本地完整收据，只能继续养成而不能凭估算重生退款。
    total = Counter(dict(receipt["costs"])) if receipt else Counter()
    total.update(dict(costs))
    state["receipts"][str(pet[0])] = {"pet": list(pet), "costs": [[cid, n] for cid, n in sorted(total.items())]}


def prepare(opcode, save, body, config):
    fields = list(iter_pb_fields(body))
    if opcode in QUERIES and body:
        raise ValueError("魔宠查询不接受参数")
    if opcode in MUTATIONS:
        if (not save.get("has_role") or save["role_state"]["level"] < config["build"]["49"]["level"]
                or save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2):
            raise ValueError("魔宠尚未解锁")
        if opcode in (1048, 1061) and body:
            raise ValueError("魔宠学习/重置不接受参数")
        if opcode not in (1048, 1061, 1065) and (len(fields) != 1 or fields[0][:2] != (1, 0)
                or not (0 if opcode == 1043 else 1) <= fields[0][2] < (1 << 31)):
            raise ValueError("魔宠操作需要一个有效编号")
    state = get_state(save, config)
    state["owned_stats"] = True
    if opcode == 1040:
        return recharge.ids([state["active"], *(v for p in state["pets"] for v in p)]), []
    if opcode == 1044:
        # 原生查询合并缓存，显式零值清掉已消耗的碎片。
        return b"".join(encode_pb_field(1, 2, encode_pb_field(1, 0, cid) + encode_pb_field(2, 0, count))
                        for cid, count in fragments(save, config).items()), []
    if opcode == 1047:
        return skills(save, state, config), []
    if opcode in (1060, 1064):
        index = fields[0][2] - 1
        if not 0 <= index < skill_slots(state, config) or not state["skills"][index][0]:
            raise ValueError("该技能栏未解锁或尚未学习")
        if opcode == 1060:
            if not state["locks"][index] and sum(state["locks"]) >= int(config["global_kv"]["pet3_passiveskill_lock"]["value"]):
                raise ValueError("技能锁定数已达上限")
            state["locks"][index] = 1 - state["locks"][index]
            return b"\x08\x01", []
        skill = state["skills"][index]
        row = config["pet3_passiveskill"][str(skill[0])]
        if row["quality"] not in (5, 6) or not row["red_skill"] or quality_points(state, config)[row["quality"] - 5] <= 0:
            raise ValueError("技能品质或红色/彩金技能点不足")
        if any(cid == row["red_skill"] for cid, _ in state["skills"]):
            raise ValueError("已拥有该品质的相同技能")
        skill[0] = row["red_skill"]
        get_state(save, config)
        return skills(save, state, config), []
    if opcode == 1061:
        cleared = [i for i, (cid, _) in enumerate(state["skills"]) if cid and not state["locks"][i]]
        if not cleared:
            raise ValueError("没有可重置的未锁定技能")
        count = sum(state["locks"])
        cost = int(config["global_kv"]["pet3_passiveskill_cost"]["value"])
        if count:
            cost += int(config["global_kv"][f"pet3_passiveskill_cost{count}"]["value"])
        for i in cleared:
            state["skills"][i] = [0, 0]
        state["spent_points"] = sum(level for _, level in state["skills"]) * int(config["global_kv"]["pet3_passiveskill_spot"]["value"])
        return skills(save, state, config), [(1001, cost)]
    if opcode == 1065:
        if (not 1 <= len(fields) <= len(state["pets"]) or any(n != 1 or w != 0 for n, w, _ in fields)
                or len({v for _, _, v in fields}) != len(fields)):
            raise ValueError("魔宠重生对象为空、重复或参数无效")
        reward, cost = Counter(), 0
        for _, _, iid in fields:
            pet = next((p for p in state["pets"] if p[0] == iid), None)
            occupied = {team[7] for team in save.get("single_boss_state", {}).get("teams", {}).values() if team}
            if not pet or iid == state["active"] or iid in occupied or pet[2:] == [0, 1]:
                raise ValueError("请先卸下魔宠，且只能重生已养成的本人魔宠")
            receipt = state["receipts"].get(str(iid))
            if receipt is None or receipt["pet"] != pet:
                raise ValueError("魔宠缺少完整养成收据，未扣款或退款")
            cost += config["renascence"][str(pet[2])]["pet_reborn"]
            reward.update(dict(receipt["costs"]))
            pet[2:] = [0, 1]
            del state["receipts"][str(iid)]
        get_state(save, config)
        return recruit.build_reward(save, sorted(reward.items()), config), [(1001, cost)]
    if opcode == 1048:
        cost = int(config["global_kv"]["pet3_passiveskill_spot"]["value"])
        if not state["active"] or skill_points(save, config) - state["spent_points"] < cost:
            raise ValueError("请先上阵魔宠并确保技能点充足")
        available = state["skills"][:skill_slots(state, config)]
        empty = next((skill for skill in available if not skill[0]), None)
        rng = random.Random(random.getrandbits(64))
        # 本地抽取规则：先按scale填空槽（不重复技能），填满后等概率升级一个未满槽。
        if empty is not None:
            known = {cid for cid, _ in state["skills"]}
            rows = [row for row in config["pet3_passiveskill"].values() if row["scale"] > 0 and row["id"] not in known]
            empty[:] = [rng.choices(rows, [row["scale"] for row in rows])[0]["id"], 1]
        else:
            available = [skill for skill in available if skill[1] < int(config["global_kv"]["pet3_passiveskill_limit"]["value"])]
            if not available:
                raise ValueError("已开启的魔宠技能均已满级")
            rng.choice(available)[1] += 1
        state["spent_points"] += cost
        get_state(save, config)
        return skills(save, state, config), []
    value = fields[0][2]
    if opcode == 1043:
        if value not in {0, *(p[0] for p in state["pets"])}:
            raise ValueError("该魔宠不属于当前角色")
        state["active"] = value
        return skills(save, state, config), []
    if opcode in (1046, 1062):
        pet = next((p for p in state["pets"] if p[0] == value), None)
        if pet is None:
            raise ValueError("该魔宠不属于当前角色")
        before = list(pet)
        if opcode == 1046:
            row = config["pet3_attr"][str(pet[1])][str(pet[2])]
            if not row["consume"] or str(pet[2] + 1) not in config["pet3_attr"][str(pet[1])]:
                raise ValueError("魔宠已达最高阶")
            if save["role_state"]["level"] < row["level"]:
                raise ValueError("队伍等级不足，不能进阶")
            costs = [tuple(map(int, e.split(","))) for e in row["consume"].split(";") if e]
            pet[2] += 1
        else:
            row = config["pet3_illustrated"][str(pet[1])][str(pet[3])]
            if not row["cost"] or str(pet[3] + 1) not in config["pet3_illustrated"][str(pet[1])]:
                raise ValueError("图鉴已达最高等级")
            if save["role_state"]["level"] < row["cond1"] or pet[2] < row["cond2"]:
                raise ValueError("队伍或魔宠进阶等级不足，不能升级图鉴")
            costs = [tuple(map(int, e.split(","))) for e in row["cost"].split(";") if e]
            pet[3] += 1
        record_costs(state, pet, before, costs)
        get_state(save, config)
        return (skills(save, state, config) if opcode == 1046 else recharge.ids([state["active"], *(v for p in state["pets"] for v in p)])), costs
    row = config["pet3_fragment"].get(str(value))
    if not row or any(p[1] == row["petid"] for p in state["pets"]):
        raise ValueError("魔宠碎片无效或已拥有该魔宠")
    if fragments(save, config)[value] < row["number"]:
        raise ValueError("魔宠碎片不足")
    if save["role_state"]["level"] < config["pet3_attr"][str(row["petid"])]["0"]["level"]:
        raise ValueError("队伍等级不足，尚不能合成该魔宠")
    pet = [max([5000000, *(p[0] for p in state["pets"])]) + 1, row["petid"], 0, 1]
    state["pets"].append(pet)
    get_state(save, config)
    return recharge.ids([*pet[:3], 1, pet[3]]), [(value, row["number"])]
