"""21级魔宠：真实碎片、合成、上阵与普通被动技能学习。"""

import random
from fractions import Fraction

from . import recharge
from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint

QUERIES = (1040, 1044, 1047)
MUTATIONS = (1043, 1048, 1049)
OPCODES = QUERIES + MUTATIONS
UNSUPPORTED = (1041, 1042, 1045, 1046, 1060, 1061, 1062, 1064, 1066)
ATTR_FIELDS = {"atk": 6, "def": 7, "hp": 8, "dodge": 11, "resilience": 13, "arp": 15}
# shortcut: 仅支持零阶宠物与普通被动；进阶、技能锁定/重置和主动参战需补齐结算及战报后再开放。


def get_state(save, config):
    state = save.setdefault("pet_state", {"active": 0, "pets": [], "starter_claimed": False})
    if (not isinstance(state, dict) or type(state.get("active")) is not int
            or type(state.get("starter_claimed")) is not bool or not isinstance(state.get("pets"), list)):
        raise ValueError("魔宠存档无效")
    for pet in state["pets"]:
        if (not isinstance(pet, list) or len(pet) != 4 or any(type(v) is not int for v in pet)
                or not 5000000 < pet[0] < (1 << 31) or str(pet[1]) not in config["pet3_attr"]
                or pet[2:] != [0, 1]):
            raise ValueError("魔宠存档含无效或尚未支持的养成")
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
                                       or config["pet3_passiveskill"][str(skill[0])]["scale"] <= 0
                                       or not 1 <= skill[1] <= limit)):
            raise ValueError("魔宠技能或等级无效")
    known = [cid for cid, _ in skills if cid]
    if (len(set(known)) != len(known) or any(cid for cid, _ in skills[skill_slots(state, config):])
            or spent != sum(level for _, level in skills) * int(config["global_kv"]["pet3_passiveskill_spot"]["value"])):
        raise ValueError("魔宠技能重复、未解锁或技能点记录无效")
    return state


def skill_slots(state, config):
    return max((config["pet3_talentskill"][str(config["pet3_attr"][str(p[1])]["0"]["talentskill"])]["number"]
                for p in state["pets"]), default=0)


def skill_points(save, config):
    level = save.get("role_state", {}).get("level", 1)
    return config["role_exp"][str(level)]["pet3_number"] if level >= config["build"]["49"]["level"] else 0


def attributes(save, config):
    values = {field: Fraction(0) for field in ATTR_FIELDS.values()}
    if not save.get("pet_state"):
        return values
    state = get_state(save, config)
    if state["active"]:
        for cid, level in state["skills"]:
            if cid:
                row = config["pet3_passiveskill"][str(cid)]
                amount = Fraction(str(row["init"])) + Fraction(str(row["init_grow"])) * (level - 1)
                values[ATTR_FIELDS[row["attr"]]] += amount * (100 if row["attr"] in ("dodge", "resilience", "arp") else 1)
    return values


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
    points = max(0, skill_points(save, config) - state["spent_points"])
    return recharge.ids([points, 0, 0, *(v for i in range(5) for v in
                                       (state["skills"][i][0], (2 if state["active"] else 1) if i < unlocked else 0,
                                        state["skills"][i][1], 0))])


def prepare(opcode, save, body, config):
    fields = list(iter_pb_fields(body))
    if opcode in QUERIES and body:
        raise ValueError("魔宠查询不接受参数")
    if opcode in MUTATIONS:
        if (not save.get("has_role") or save["role_state"]["level"] < config["build"]["49"]["level"]
                or save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2):
            raise ValueError("魔宠尚未解锁")
        if opcode == 1048 and body:
            raise ValueError("魔宠学习不接受参数")
        if opcode != 1048 and (len(fields) != 1 or fields[0][:2] != (1, 0) or not 0 < fields[0][2] < (1 << 31)):
            raise ValueError("魔宠操作需要一个有效编号")
    state = get_state(save, config)
    if opcode == 1040:
        return recharge.ids([state["active"], *(v for p in state["pets"] for v in p)]), []
    if opcode == 1044:
        # 原生查询合并缓存，显式零值清掉已消耗的碎片。
        return b"".join(encode_pb_field(1, 2, encode_pb_field(1, 0, cid) + encode_pb_field(2, 0, count))
                        for cid, count in fragments(save, config).items()), []
    if opcode == 1047:
        return skills(save, state, config), []
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
        if value not in {p[0] for p in state["pets"]}:
            raise ValueError("该魔宠不属于当前角色")
        state["active"] = value
        return skills(save, state, config), []
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
