"""自研回合战斗 v2；纯计算、配置与战报，规则及适用范围见 battle_rules.md。"""

import copy
import random
from fractions import Fraction

from . import guild_skill

from . import equip_baptize, equip_evolve, godstone, magic, pets, sigil, soul, treasure_refine
from .protocol import encode_pb_field, iter_pb_fields, parse_ids_pb, pb_get_varint


POSITIONS = (2, 8, 10, 4, 12, 6, 14)
QUEENS = (10595, 10817)
MAX_ROUNDS = 30
MULTI_COMBOS = (12601, 12602, 12604, *range(12622, 12639), 12836, 12841, 12943,
                12988, 12989, 12990, 13017, 13018, 13073, 13075, 13076, 13077,
                13078, 13079, 13122, 13124, 13125)
GENERAL_FIELDS = {"cid": 1, "iid": 2, "level": 3, "advance": 4, "exp": 5,
                  "atk": 6, "def": 7, "hp": 8, "speed": 9,
                  "critical": 10, "dodge": 11, "parry": 12, "resilience": 13,
                  "hit": 14, "arp": 15, "criticaldmg": 16, "skilllevel": 18}


def _copy_points(save, map_id):
    copies = bytes.fromhex(save["world_state"]["1300"])
    current = next((v for n, w, v in iter_pb_fields(copies)
                    if n == 1 and w == 2 and pb_get_varint(v, 1) == map_id), b"")
    return current, {pb_get_varint(v, 1): v for n, w, v in iter_pb_fields(current) if n == 7 and w == 2}


def challenge(save, body, config):
    try:
        fields = list(iter_pb_fields(body))
    except ValueError as error:
        raise ValueError("关卡挑战参数无效") from error
    if len(fields) != 2 or any(n != 1 or w != 0 or not 0 < v < (1 << 31) for n, w, v in fields):
        raise ValueError("关卡挑战参数无效")
    map_id, point_id = (v for _, _, v in fields)
    row = config["copy"].get(str(map_id), {}).get(str(point_id))
    if not row or str(map_id) not in config["map"] or not save.get("has_role"):
        raise ValueError("关卡不存在或角色尚未创建")
    current, points = _copy_points(save, map_id)
    if not current or (point_id > 1 and not pb_get_varint(points.get(point_id - 1, b""), 3)):
        raise ValueError("关卡尚未解锁")
    previous = points.get(point_id, b"")
    if (pb_get_varint(previous, 4) or 0) >= row["challenge"]:
        raise ValueError("关卡挑战次数不足")
    if save["role_state"]["stamina"] < row["physical"]:
        raise ValueError("体力不足")
    return row, pb_get_varint(previous, 3) or 0


def sweep(save, body, config):
    try:
        fields = list(iter_pb_fields(body))
    except ValueError as error:
        raise ValueError("扫荡参数无效") from error
    if len(fields) != 4 or any(n != 1 or w != 0 or not 0 <= v < (1 << 31) for n, w, v in fields):
        raise ValueError("扫荡参数无效")
    map_id, point_id, method, exchange = (v for _, _, v in fields)
    if method not in (0, 1):
        raise ValueError("扫荡方式无效")
    if exchange != 0:
        raise ValueError("经验兑换扫荡尚未实现，请选择不兑换")
    location = encode_pb_field(1, 0, map_id) + encode_pb_field(1, 0, point_id)
    point, star = challenge(save, location, config)
    if star != 3:
        raise ValueError("三星通关后才能扫荡")
    state = save["role_state"]
    level_key, vip_key = ("copy_wipe_level10", "copy_sweep") if method else ("copy_wipe_level", "b_fbsd")
    if state["level"] < int(config["global_kv"][level_key]["value"]) and not config["vip"][str(state["vip"])][vip_key]:
        raise ValueError("等级或VIP不足，尚未解锁此扫荡方式")
    _, points = _copy_points(save, map_id)
    remaining = point["challenge"] - (pb_get_varint(points[point_id], 4) or 0)
    return point, min(remaining, state["stamina"] // point["physical"]) if method else 1


def rosters(save, point, config):
    """属性来自当前阵容快照；怪物属性来自关卡修正，绝不读取录制账号。"""
    fields = list(iter_pb_fields(bytes.fromhex(save["world_state"]["1002"])))
    generals = {pb_get_varint(v, 2): v for n, w, v in fields if n == 1 and w == 2}
    attack, defense = {}, {}
    equips = {pb_get_varint(v, 1): v for n, w, v in fields if n == 2 and w == 2}
    pet_bonus = pets.attributes(save, config)
    sigil_bonus, sigil_flat = sigil.bonuses(save, config)
    _, skill_flat = guild_skill.bonuses(save, config)
    magic_bonus, magic_flat = magic.bonuses(save, config)
    souls, _ = soul.read_world(save, config)
    for n, w, slot in fields:
        if n != 4 or w != 2 or not pb_get_varint(slot, 2):
            continue
        index, iid = pb_get_varint(slot, 1), pb_get_varint(slot, 2)
        if index not in range(1, 8) or iid not in generals:
            raise ValueError("无效阵位或缺少武将属性")
        raw = generals[iid]
        unit = {name: pb_get_varint(raw, field) or 0 for name, field in GENERAL_FIELDS.items()}
        if (any(unit[name] <= 0 for name in ("cid", "iid", "level", "atk", "hp", "speed"))
                or any(not 0 <= value < (1 << 31) for value in unit.values())):
            raise ValueError("武将战斗属性无效")
        if not config["general"].get(str(unit["cid"]), {}).get("battle"):
            raise ValueError("该武将不能上阵战斗")
        if any(pb_get_varint(raw, field) for field in range(21, 41)):
            raise ValueError("尚不支持该武将的高级战斗属性")
        if index > config["role_exp"][str(save["role_state"]["level"])]["slotnum"]:
            raise ValueError("阵位尚未解锁")
        if POSITIONS[index - 1] in attack or any(u["iid"] == iid for u in attack.values()):
            raise ValueError("阵位或上阵武将重复")
        unit["skill"] = config["general"][str(unit["cid"])]["skillid"]
        unit["flat_out"], unit["flat_in"] = equip_baptize.flat(slot, equips, config)
        unit["flat_out"] += sigil_flat[0]
        unit["flat_out"] += skill_flat
        unit["flat_in"] += sigil_flat[1]
        unit["flat_out"] += magic_flat[0]
        unit["flat_in"] += magic_flat[1]
        soul_stats, soul_flat, soul_effects = soul.bonuses(slot, souls, config)
        unit["flat_out"] += soul_flat[0]
        unit["flat_in"] += soul_flat[1]
        unit["soul_effects"] = soul_effects
        stone = godstone.attributes(slot, config)
        unit["pet_rates"] = {name: pet_bonus.get(field, 0) - int(pet_bonus.get(field, 0)) + stone[field] - int(stone[field])
                             for name, field in godstone.ATTR_FIELDS.items() if field in godstone.RATE_FIELDS}
        unit["pet_rates"]["critical"] = sigil_bonus[10] - int(sigil_bonus[10])
        for name, field in magic.FIELDS.items():
            if field >= 10:
                unit["pet_rates"][name] = unit["pet_rates"].get(name, 0) + magic_bonus[field] - int(magic_bonus[field])
        for name, field in soul.FIELDS.items():
            if field >= 10:
                unit["pet_rates"][name] = unit["pet_rates"].get(name, 0) + soul_stats[field] - int(soul_stats[field])
        equipment_stats = equip_evolve.attributes(raw, slot, equips, config)
        for name, field in equip_evolve.FIELDS.items():
            if field >= 10:
                unit["pet_rates"][name] = unit["pet_rates"].get(name, 0) + equipment_stats[field] - int(equipment_stats[field])
        treasure_passives = [sid for field in (8, 9) if pb_get_varint(slot, field)
                             for sid in treasure_refine.star_skills(parse_ids_pb(equips[pb_get_varint(slot, field)]), config)]
        if treasure_passives:
            unit["treasure_passives"] = treasure_passives
        attack[POSITIONS[index - 1]] = unit
    if not attack:
        raise ValueError("没有上阵武将")
    if point.get("p8"):
        raise ValueError("战斗 v2 尚不支持第八怪物阵位")
    for i, pos in enumerate(POSITIONS, 1):
        monster_id = point[f"p{i}"]
        if not monster_id:
            continue
        monster = config["copy_monster"][str(monster_id)]
        level = point["level"]
        if point[f"p{i}-grow"]:
            raise ValueError("该关卡的额外怪物属性尚未核实")
        mask_level = point[f"mozhao{i}_lv"]
        mask = config["mozhao_break"].get(str(mask_level))
        if mask is None:
            raise ValueError("关卡魔罩等级配置不存在")
        unit = {"iid": monster_id * 10 + i, "cid": monster["generalid"], "level": level,
                 "advance": point[f"break{i}-correct"], "name": monster["name"],
                "boss": point[f"p{i}-type"] == 2, "npc": True,
                "cover_l": mask_level, "cover_d": mask["value"], "cover_p": mask["percent"],
                "adddmgpct": Fraction(str(point[f"adddmgpct{i}-correct"])),
                "subdmgpct": Fraction(str(point[f"subdmgpct{i}-correct"]))}
        for name in ("atk", "def", "hp", "speed"):
            value = Fraction(str(monster[name])) + Fraction(str(monster[f"{name}-grow"])) * (level - 1)
            unit[name] = int(value) + point.get(f"{name}{i}-correct", 0)
        # 30124 的 copy_monster.skillid 与实际战报不同，战报使用 general.skillid。
        unit["skill"] = config["general"][str(unit["cid"])]["skillid"]
        unit.update({name: monster.get(name, 0) for name in
                     ("critical", "dodge", "parry", "resilience", "hit", "arp", "criticaldmg")})
        unit["skilllevel"] = monster["skilllevel"]
        defense[pos] = unit
    if not defense:
        raise ValueError("关卡没有怪物")
    return attack, defense


def damage(attacker, defender, config, skill_id=None, critical=False, *, multiplier=Fraction(1),
           flat=0, critical_multiplier=Fraction(3, 2), combo=False, final_multiplier=Fraction(1)):
    """倍率在分段取整前应用，固定加减伤在求和后应用，最后死亡截断。"""
    coefficient, hits = Fraction(1), 1
    if skill_id is not None:
        # 两张技能表有重号，合体必须显式选表，不能误取同ID的普通技能。
        skill = config["combskill"].get(str(skill_id)) if combo else config["skill"].get(str(skill_id)) or config["combskill"].get(str(skill_id))
        if not skill or skill["kind"] != "attack":
            raise ValueError("不支持的伤害技能")
        coefficient, hits = Fraction(skill["atk-param"].split(";")[0]), skill["count"]
    if hits <= 0 or coefficient <= 0 or attacker["atk"] <= 0 or defender["def"] < 0 or defender["hp"] < 0:
        raise ValueError("伤害计算参数无效")
    defense_factor = Fraction(config["global_kv"]["battle_def_param1"]["value"])
    base = max(Fraction(attacker["atk"], 20), attacker["atk"] - defender["def"] * defense_factor)
    # 憾地 count=19：逐段向下取整再合计，不能把总伤害取整一次。
    total = int(base * coefficient * (critical_multiplier if critical else 1) * multiplier / hits) * hits
    return min(defender["hp"], max(0, int((total + flat) * final_multiplier)))


def _gain_experience(level, experience, gained, table, field, maximum=None):
    if any(type(v) is not int or v < 0 for v in (level, experience, gained)) or level < 1:
        raise ValueError("经验参数无效")
    experience += gained
    while True:
        if maximum is not None and level >= maximum:
            return level, experience
        row = table.get(str(level))
        if not row or row[field] <= 0:
            raise ValueError("经验等级上限规则尚未核实")
        if experience < row[field]:
            return level, experience
        experience -= row[field]
        level += 1


def victory_role_reward(state, point, old_star, star, config):
    if not 0 <= old_star <= 3 or not 1 <= star <= 3:
        raise ValueError("副本星级无效")
    gained = point["physical"] * config["role_exp"][str(state["level"])]["exp"]
    level, experience = _gain_experience(state["level"], state["exp"], gained, config["role_exp"], "nextexp",
                                         max(map(int, config["role_exp"])))
    if experience >= (1 << 31):
        raise ValueError("角色经验超出范围")
    coin = point["coin"] * (3 if old_star != 3 and star == 3 else 1)
    gold = 0
    for reached in range(state["level"] + 1, level + 1):
        coin += config["role_exp"][str(reached)]["c_reward"]
        gold += config["role_exp"][str(reached)]["g_reward"]
    return {"gained": gained, "level": level, "exp": experience, "coin": coin, "gold": gold}


def general_experience(unit, gained, config, maximum=None):
    quality = config["general"][str(unit["cid"])]["quality"]
    level, experience = _gain_experience(unit["level"], unit["exp"], gained, config["general_exp"], f"{quality}exp", maximum)
    return level, experience, level - unit["level"]


def _prepare_teams(teams, config):
    dynamic = {*range(9100001, 9100008), 9000001, 9000008, 9000015, 9000020, 9000023, 9000024, 9000025,
               9000026, 9000027, 9000028, 9000029, 9000030, 9000031, 9000032, 9000036,
               9000037, 9000038, 9000039, 9000040, 9000400, 9000412, 9000413, 9000429, 9000430, 9000483, 9000489,
               9000496, 9000501, 9000528, 9000583, 9000674, 9000789, 9000791, 9000803}
    flat_defense = {9000047, 9000049, 9000072, 9000078, 9000082}
    stats = ("atk", "def", "hp", "speed", "critical", "dodge", "parry", "resilience", "hit", "arp", "criticaldmg")
    lead_basis = {}
    for direct, team in teams.items():
        if not team:
            raise ValueError("战斗双方必须有上阵武将")
        for pos, unit in sorted(team.items()):
            if pos not in POSITIONS or any(unit[k] <= 0 for k in ("hp", "atk", "speed")) or unit["def"] < 0:
                raise ValueError("战斗属性或阵位无效")
            if not 0 <= unit["advance"] <= 23 or not 0 <= unit.get("skilllevel", 0) <= 300:
                raise ValueError("战斗突破或技能等级无效")
            general = config["general"][str(unit["cid"])]
            skill = config["skill"].get(str(unit["skill"]))
            if "boss_cycle" in unit:
                if (not unit.get("npc") or str(unit["cid"]) not in config.get("personalboss_att", {})
                        or not isinstance(unit["boss_cycle"], list) or not unit["boss_cycle"]
                        or any(type(sid) is not int or sid not in range(12640, 12648)
                               or str(sid) not in config["combskill"] for sid in unit["boss_cycle"])
                        or unit.get("boss_passive", 0) not in (0, 12648)):
                    raise ValueError("个人Boss技能循环无效")
            if not skill and not (unit["cid"] in QUEENS and unit["skill"] == 0
                                  or "boss_cycle" in unit and unit["skill"] == 0
                                  or str(unit["cid"]) in config.get("huodong_monster", {}) and unit["skill"] == 12858):
                raise ValueError("武将技能不存在")
            if skill and (skill["kind"] not in ("attack", "gain") or skill["range"] not in ("single", "all", "first", "second", "random", "three")
                          or skill["effect"] not in ("once", "dizzy", "dot", "firing", "suck", "promote", "weaken")):
                raise ValueError("尚不支持该武将的技能效果")
            ids = {general.get(f"break{i}", 0) for i in range(1, unit["advance"] + 1)} - {0}
            extra = unit.get("treasure_passives", ())
            if extra:
                allowed = {row[kind + "_activated"] for row in config["treasure2_star"].values() for kind in ("horse", "treasure")}
                if not isinstance(extra, (list, tuple)) or len(extra) > 12 or any(type(pid) is not int or pid not in allowed or pid == 0 for pid in extra):
                    raise ValueError("宝物升星战斗被动无效")
                ids.update(extra)
            rows = [config["breakskill"][str(pid)] for pid in sorted(ids)]
            initial_ap = unit.get("initial_ap", 2)
            if type(initial_ap) is not int or not 0 <= initial_ap <= 10:
                raise ValueError("初始怒气无效")
            unit.update(pos=pos, direct=direct, ap=initial_ap, dizzy=False, dot=None, firing=None, buffs={}, states={},
                        emergency=False, strikes=0, guard=0, effects={}, passive_rows=rows,
                        flat_out=unit.get("flat_out", 0), flat_in=unit.get("flat_in", 0), cover_d=unit.get("cover_d", 0))
            unit["cover_d2"] = unit["cover_d"]
            added, reduced = unit.get("adddmgpct", 0), unit.get("subdmgpct", 0)
            if min(added, reduced, unit["cover_d"]) < 0 or not 0 <= unit.get("cover_p", 0) <= 100:
                raise ValueError("增减伤或魔罩属性无效")
            unit.update(out_multiplier=1 + Fraction(str(added)), in_multiplier=1 / (1 + Fraction(str(reduced))))
            unit["base"] = {name: unit.get(name, 0) for name in stats}
            for row in rows:
                attr, code = row["attr"], row["type_param"] or row["id"]
                # 主角的种类号与别行ID重号，按本行识别，不能套用被引用行的效果。
                if 9100001 <= row["id"] <= 9100007:
                    code = row["id"]
                if row["type"] == 0 and code not in range(9100001, 9100005):
                    if attr not in (*stats, "ap", "dmg", "fdmg") or row["target"] not in ("1", "2", "3", "4", "5"):
                        raise ValueError("尚不支持该突破属性")
                elif code not in dynamic:
                    raise ValueError(f"尚不支持该突破被动 {row['id']}")
                else:
                    old = unit["effects"].get(code)
                    if old is None or row["value"] > old["value"]:
                        unit["effects"][code] = row
                if attr in ("fdmg", "dmg") and row["method"] == "value":
                    unit["flat_in" if row["id"] in flat_defense else "flat_out"] += int(row["value"])
            unit["guard"] = 2 if 9000024 in unit["effects"] else 0
            unit["low_action"] = 9100001 in unit["effects"]
            if 9100005 in unit["effects"]:
                unit["ap"] += int(unit["effects"][9100005]["value"])
            if 9100007 in unit["effects"]:
                for name in ("atk", "def", "hp"):
                    unit[name] += int(unit["base"][name] * Fraction(str(unit["effects"][9100007]["value"])))
            lead_basis[direct, pos] = {name: unit[name] for name in ("atk", "def", "hp")}

    def matches(unit, region, sex):
        general = config["general"][str(unit["cid"])]
        return (region in ("", "11") or general["region"] == region or region == "12" and general["region"] in ("6", "7", "8", "9")) and sex in ("", "all", general["sex"])

    def add(unit, attr, value, method="value"):
        if attr == "ap":
            unit["ap"] += int(value)
        elif attr == "dmg":
            unit["out_multiplier"] *= 1 + value
        elif attr == "reduction":
            unit["in_multiplier"] *= max(0, 1 - value)
        elif attr in stats:
            unit[attr] = unit.get(attr, 0) + (unit["base"][attr] * value if method == "percent" and attr in ("atk", "def", "hp", "speed") else value)
        else:
            raise ValueError("尚不支持该突破属性")

    applied = set()
    for direct, team in teams.items():
        for _, provider in sorted(team.items()):
            for row in provider["passive_rows"]:
                code = row["id"] if 9100001 <= row["id"] <= 9100007 else row["type_param"] or row["id"]
                value = Fraction(str(row["value"]))
                if code in range(9100001, 9100008):
                    continue
                if row["type"] == 0 or code == 9000001:
                    if row["attr"] == "fdmg" or row["method"] == "value" and row["attr"] == "dmg":
                        continue
                    scope = row["target"]
                    targets = ([provider] if scope == "3" else list(teams[not direct].values()) if scope in ("2", "4", "5") else list(team.values()))
                    for target in targets:
                        if (scope == "4" and target["pos"] > 7 or scope == "5" and target["pos"] < 8
                                or not matches(target, row["region"], row["sex"])):
                            continue
                        key = (direct, row["id"], target["direct"], target["pos"])
                        if key in applied:
                            continue
                        applied.add(key)
                        attr = "dmg" if code == 9000001 else row["attr"]
                        if scope == "3" and not target.get("npc") and attr in stats:
                            continue  # 玩家快照已汇总自身常驻属性，不能再加一次。
                        if attr == "dmg" and row["kind"] == "1":
                            attr = "reduction"
                        add(target, attr, -value if row["kind"] == "1" and attr != "reduction" else value, row["method"])
                elif code in (9000400, 9000791, 9000583):
                    region = "13" if code == 9000400 else "14" if code == 9000791 else "7"
                    members = [u for u in team.values() if matches(u, region, "all")]
                    if (direct, code) not in applied:
                        applied.add((direct, code))
                        for target in members:
                            if code == 9000583:
                                target["buffs"]["promote", "def"] = (value, int(row["value2"]) + 1)
                            else:
                                for attr in ("atk", "def", "hp") if code == 9000400 else ("atk",):
                                    add(target, attr, value * (len(members) if code == 9000400 else 1), "percent")
                    if code == 9000791 and len(members) <= 2:
                        add(provider, "atk", Fraction(str(row["value2"])), "percent")
                elif code == 9000008:
                    add(provider, "reduction", value)
                elif code == 9000028 and provider.get("npc"):
                    add(provider, "parry", value)
                elif code == 9000489:
                    add(provider, "dmg", value)
    for direct, team in teams.items():
        reduction = max((Fraction(str(u["effects"][9100006]["value"])) for u in team.values() if 9100006 in u["effects"]), default=0)
        for unit in team.values():
            unit["in_multiplier"] *= 1 - reduction
            for code, name in ((9100005, "hp"), (9100006, "def"), (9100007, "atk")):
                unit[name] += max((int(lead_basis[direct, pos][name]) // 20 for pos, provider in team.items()
                                   if provider is not unit and code in provider["effects"]), default=0)
        if any(unit.get("boss_aura") for unit in team.values()):
            for target in teams[not direct].values():
                # 本地解释采用Boss文案的减攻80%，不误解析矛盾的生命光环引用。
                target["atk"] = max(1, int(target["atk"] * Fraction(1, 5)))
    for team in teams.values():
        for unit in team.values():
            # 命中/额外暴伤可被临时减至负值，不能吞掉零基础属性上的Boss减益。
            for name in stats:
                unit[name] = int(unit.get(name, 0))
                if name not in ("hit", "criticaldmg"):
                    unit[name] = max(0, unit[name])
            unit["ap"] = max(0, min(10, unit["ap"]))
            unit["maxhp"] = unit["hp"]
            if 9100003 in unit["effects"]:
                unit["protagonist_atk"] = unit["atk"]
            if min(unit["hp"], unit["atk"], unit["speed"]) <= 0:
                raise ValueError("突破效果后的战斗属性无效")


def targets(actor, enemies, skill, rng):
    living = [u for _, u in sorted(enemies.items()) if u["hp"] > 0]
    scope = skill["range"] if skill else "single"
    if scope == "single":
        return sorted(living, key=lambda u: (u["pos"] > 7, u["pos"]))[:1]
    if scope == "all":
        return living
    if scope == "second":
        return [u for u in living if u["pos"] > 7]
    if scope == "first":
        return [u for u in living if u["pos"] < 8] or living
    if scope == "random":
        return sorted(rng.sample(living, min(len(living), skill["randnum"])), key=lambda u: u["pos"])
    if scope == "three":
        rows = {2: 1, 4: 2, 6: 3, 8: 1, 10: 2, 12: 3, 14: 4}
        return [u for u in living if abs(rows[u["pos"]] - rows[actor["pos"]]) <= 1] or living[:1]
    raise ValueError(f"战斗 v2 尚不支持技能范围 {scope}")


def simulate(attack, defense, config, seed, *, attack_pet=None, defense_pet=None, attack_cheer=(), defense_cheer=(), max_rounds=None):
    """不改变输入；同一输入/配置/seed 生成完全相同的行动及终局。"""
    max_rounds = MAX_ROUNDS if max_rounds is None else max_rounds
    if type(max_rounds) is not int or not 1 <= max_rounds <= MAX_ROUNDS:
        raise ValueError("战斗回合上限无效")
    teams = {True: copy.deepcopy(attack), False: copy.deepcopy(defense)}
    cheers = {True: list(attack_cheer), False: list(defense_cheer)}
    cheer_ids = {}
    for direct, cids in cheers.items():
        if (len(cids) > 8 or any(type(cid) is not int or not config["general"].get(str(cid), {}).get("battle") for cid in cids)
                or len(set(cids)) != len(cids)):
            raise ValueError("战斗助阵成员无效")
        cheer_ids[direct] = {config["general"][str(cid)]["init_cid"] or cid for cid in cids}
    _prepare_teams(teams, config)
    rng = random.Random(seed)
    report = {"t": "b", "meta": {}, "b": {"init": {}, "a": []}, "endmeta": {},
              "dead_log": {"true": {}, "false": {}}, "rules": "zyj-v2", "seed": seed}
    actions = report["b"]["a"]
    pending_deaths = []
    combat_pets = {True: copy.deepcopy(attack_pet), False: copy.deepcopy(defense_pet)}
    for direct, team in teams.items():
        side = "attack" if direct else "defense"
        meta, initial = {}, {}
        for pos, unit in sorted(team.items()):
            general = config["general"][str(unit["cid"])]
            initial[str(pos)] = {"i": unit["iid"], "o": unit.get("boss", False)}
            meta[str(unit["iid"])] = {"i": unit["iid"], "c": unit["cid"], "n": unit.get("name", general["name"]),
                                      "level1": unit["level"], "level2": unit["advance"], "level3": 0,
                                      "h": unit["hp"], "j": unit["hp"], "ap": unit["ap"], "d": {"i": unit["skill"]},
                                      **({key: unit[key] for key in ("cover_d", "cover_d2", "cover_p", "cover_l")} if unit["cover_d"] else {})}
        report["meta"][side] = {"n": "本地玩家" if direct else next(iter(team.values())).get("name", "守关队伍"),
                                "g": meta, "pet": {}, "cheer": cheers[direct]}
        report["b"]["init"][side] = initial
        pet = combat_pets[direct]
        if pet is not None:
            row = config["pet3_attr"].get(str(pet["cid"]), {}).get(str(pet["phase"]))
            if not row or str(row["skillid"]) not in config["combskill"] or pet["level"] < 1:
                raise ValueError("魔宠战前数据无效")
            pet["skill"] = row["skillid"]
            report["meta"][side]["pet"][str(pet["iid"])] = {
                "i": pet["iid"], "c": pet["cid"], "level1": pet["level"], "level2": pet["phase"],
                "ap": row["ap"], "h": 1, "j": 1, "d": {"i": row["skillid"]}}
            initial["0"] = {"i": pet["iid"], "o": False}

    def roll(chance):
        return chance > 0 and rng.random() < min(1, chance)

    def dest(unit, **values):
        return {"r": unit["direct"], "p": unit["pos"], **values}

    def effect(unit, code, field="value"):
        return Fraction(str(unit["effects"].get(code, {}).get(field, 0)))

    def event(destinations, source=None):
        actions.append({"t": "b", "s": source or {}, "e": destinations})
        if len(actions) > 2000:
            raise ValueError("战斗事件超出上限，未结算")

    def change_hp(unit, amount, status="N", hits=0, *, shield=True):
        if amount < 0:
            amount = -int(-amount * (1 + unit.get("soul_effects", {}).get("heal", 0)))
        if amount > 0 and unit["states"].get("invincible", 0) > round_number:
            amount, status = 0, "proof"
        absorbed = min(unit["cover_d"], int(max(0, amount) * Fraction(unit.get("cover_p", 0), 100))) if shield else 0
        unit["cover_d"] -= absorbed
        amount -= absorbed
        amount = max(- (unit["maxhp"] - unit["hp"]), min(unit["hp"], amount))
        previous = unit["hp"]
        unit["hp"] -= amount
        if unit["hp"] == 0:
            status = "dead" if status == "N" else status + "dead" if status not in ("C",) else "C"
            report["dead_log"][str(unit["direct"]).lower()][str(unit["cid"])] = round_number
            if previous:
                pending_deaths.append(unit)
        return dest(unit, m={"m": amount, "f": 0, "u": status, "U": hits, **({"M": absorbed} if absorbed else {})})

    def finished():
        return any(not any(u["hp"] > 0 for u in team.values()) for team in teams.values())

    def stat(unit, name):
        value = unit.get(name, 0)
        if name == "atk" and 9100003 in unit["effects"]:
            dead = sum(other is not unit and other["hp"] <= 0 for other in teams[unit["direct"]].values())
            value += Fraction(unit["protagonist_atk"] * dead, 10)
        for (kind, attr), (amount, until) in unit["buffs"].items():
            if attr == name and until > round_number:
                value += (unit.get(name, 0) if name in ("atk", "def", "speed") else 100) * amount * (1 if kind == "promote" else -1)
        if name in ("def", "resilience") and any(9000413 in u["effects"] and u["hp"] > 0 for u in teams[unit["direct"]].values()):
            value += unit["def"] * Fraction(1, 5) if name == "def" else 10
        return max(0, int(value) + unit.get("pet_rates", {}).get(name, 0))

    def buff(unit, skill):
        attr, amount = skill["effect-param"].split(";")
        if attr not in ("atk", "def", "critical", "dodge"):
            raise ValueError("尚不支持的技能属性效果")
        duration = skill["effect-round"] - (int(effect(unit, 9000789)) if skill["effect"] == "weaken" else 0)
        if duration <= 0:
            return None
        unit["buffs"][(skill["effect"], attr)] = (Fraction(amount), round_number + duration)
        return dest(unit, B={"R": attr, "u": skill["effect"], "w": True})

    def stun(unit, duration=1):
        duration -= int(effect(unit, 9000789))
        if duration <= unit["dizzy"] or unit["states"].get("xiyin", 0) > round_number:
            return False
        unit["dizzy"] = duration
        return True

    def status_damage(unit, kind, amount, duration):
        duration -= int(effect(unit, 9000789))
        if duration <= 0:
            return None
        unit[kind] = [max(1, amount), duration]
        return dest(unit, m=[], u={"u": kind, "w": True})

    def cleanse(unit):
        changes = []
        for kind in ("dizzy", "dot", "firing"):
            if unit[kind]:
                unit[kind] = False if kind == "dizzy" else None
                changes.append(dest(unit, m=[], u={"u": kind, "w": False}))
        for kind in ("skilllock", "fire"):
            if kind in unit["states"]:
                del unit["states"][kind]
                changes.append(state_event(unit, kind, False))
        for kind, attr in list(unit["buffs"]):
            if kind == "weaken":
                del unit["buffs"][kind, attr]
                changes.append(dest(unit, B={"R": attr, "u": kind, "w": False}))
        return changes

    def kill_recovery(actor, killed):
        if actor["hp"] > 0 and killed and effect(actor, 9000038):
            event([change_hp(actor, -int(actor["maxhp"] * effect(actor, 9000038) * killed))])

    def modifiers(actor, target):
        multiplier = actor["out_multiplier"] * target["in_multiplier"]
        if actor["strikes"] == 0:
            multiplier *= 1 + effect(actor, 9000029)
        if target["hp"] < actor["hp"]:
            multiplier *= 1 + effect(actor, 9000032)
        if target["hp"] > actor["hp"]:
            multiplier *= 1 + effect(actor, 9000037)
        multiplier *= 1 + effect(actor, 9000429) * (target["hp"] * 10 // target["maxhp"])
        multiplier *= 1 + effect(actor, 9000430) * ((target["maxhp"] - target["hp"]) * 10 // target["maxhp"])
        if target["ap"] <= 2:
            multiplier *= 1 + effect(actor, 9000036)
        if target["firing"]:
            multiplier *= 1 + effect(actor, 9000489)
        if actor["hp"] < target["hp"]:
            multiplier *= 1 - effect(target, 9000023)
        if actor["hp"] > target["hp"]:
            multiplier *= 1 - effect(target, 9000026)
        general = config["general"][str(actor["cid"])]
        if general["sex"] == "nan":
            if general["region"] in ("6", "7", "8", "9"):
                multiplier *= 1 - effect(target, 9000015)
            if not 10101 <= actor["cid"] <= 10115:
                multiplier *= 1 - effect(target, 9000496)
        return multiplier

    def guard(target):
        if not target["guard"]:
            return 1
        target["guard"] -= 1
        return 1 - effect(target, 9000024)

    def extra_hit(actor, target, coefficient, fixed=0, *, explosion=False):
        multiplier = modifiers(actor, target) * guard(target)
        flat = actor["flat_out"] - target["flat_in"]
        final = max(0, 1 - target.get("soul_effects", {}).get("antiblew", 0)) if explosion else 1
        amount = damage({**actor, "atk": stat(actor, "atk")},
                        {**target, "def": stat(target, "def"), "hp": target["hp"] + target["cover_d"]}, config,
                        multiplier=coefficient * multiplier, flat=flat, final_multiplier=final) if coefficient else int(max(0, int(fixed * multiplier) + flat) * final)
        return change_hp(target, amount)

    def deaths():
        while pending_deaths:
            unit = pending_deaths.pop(0)
            for provider in teams[unit["direct"]].values():
                if provider["hp"] > 0 and 9100003 in provider["effects"]:
                    event([dest(provider, B={"R": "atk", "u": "promote", "w": True})])
            if effect(unit, 9000027):
                friends = sorted((u for u in teams[unit["direct"]].values() if u["hp"] > 0), key=lambda u: (u["hp"], u["pos"]))
                if friends:
                    event([change_hp(friends[0], -int(stat(unit, "atk") * effect(unit, 9000027)))])
            if effect(unit, 9000040):
                selected = targets(unit, teams[not unit["direct"]], None, rng)
                if selected:
                    target = selected[0]
                    event([extra_hit(unit, target, effect(unit, 9000040), explosion=True)])

    def living(team):
        return [u for _, u in sorted(team.items()) if u["hp"] > 0]

    def queen_recovery(target):
        provider = next((u for _, u in sorted(teams[target["direct"]].items()) if u["cid"] in QUEENS and u["hp"] > 0), None)
        return (stat(provider, "atk") * 12 + provider["maxhp"] * 4) // 100 if provider else 0

    def state_event(unit, kind, enabled):
        if kind in ("xiyin", "fire"):
            return dest(unit, B={"R": kind, "u": "promote" if kind == "xiyin" else "break", "w": enabled})
        return dest(unit, m=[], u={"u": kind, "w": enabled})

    def set_state(unit, kind, duration=1):
        if kind == "skilllock":
            duration -= int(effect(unit, 9000789))
        if duration <= 0:
            return []
        unit["states"][kind] = round_number + duration
        return [state_event(unit, kind, True)]

    def change_ap(unit, amount):
        unit["ap"] = max(0, min(10, unit["ap"] + amount))
        return dest(unit, ap=unit["ap"], E=True)

    def choose_combo(actor, friends, enemies):
        general = config["general"][str(actor["cid"])]
        skill = config["combskill"].get(str(general["combskillid"]))
        if not skill or not skill["cid2"]:
            return None
        if skill["id"] not in MULTI_COMBOS:
            raise ValueError(f"尚不支持该合体技能 {skill['id']}")
        if actor["ap"] < skill["ap"]:
            return None
        members = [skill[f"cid{i}"] for i in (1, 2, 3) if skill[f"cid{i}"]]
        identity = general["init_cid"] or actor["cid"]
        if identity not in members:
            raise ValueError("合体技能与发动者身份不匹配")
        participants = [actor["pos"]]
        for cid in members:
            if cid == identity:
                continue
            partner = next((u for u in living(friends) if (config["general"][str(u["cid"])]["init_cid"] or u["cid"]) == cid
                            and not u["dizzy"] and u["states"].get("skilllock", 0) <= round_number), None)
            if partner is None:
                if (cid in cheer_ids[actor["direct"]]
                        and not any((config["general"][str(u["cid"])]["init_cid"] or u["cid"]) == cid for u in friends.values())):
                    continue
                return None
            participants.append(partner["pos"])
        candidates = living(friends if skill["kind"] == "gain" else enemies)
        if skill["range"] == "second":
            candidates = [u for u in candidates if u["pos"] > 7]
        chance = config["combskillprobability"][str(skill["id"])][f"bout{min(10, round_number)}"]
        return (skill, participants) if candidates and roll(chance) else None

    def combo_effects(actor, skill, hits, killed):
        sid = skill["id"]
        friends = teams[actor["direct"]]
        survivors = [u for u in hits if u["hp"] > 0]
        changes = []
        if sid in (12601, 12625, 12636):
            for target in survivors:
                eligible = (target["hp"] * 2 < target["maxhp"] if sid != 12625 else target["hp"] * 5 > target["maxhp"] * 4)
                if eligible and (sid != 12636 or target["pos"] > 7) and stun(target):
                    changes.append(dest(target, m=[], u={"u": "dizzy", "w": True}))
        if sid in (12627, 12988, 13075):
            candidates = [u for u in survivors if sid == 12988 or not u["dizzy"]]
            if sid == 12627:
                selected = sorted(rng.sample(candidates, min(2, len(candidates))), key=lambda u: u["pos"])
                selected = [u for u in selected if roll(skill["trigger"])]
            else:
                selected = sorted(candidates, key=lambda u: (-stat(u, "atk"), u["pos"]))[:1 if sid == 13075 else 2]
            for target in selected:
                if stun(target):
                    changes.append(dest(target, m=[], u={"u": "dizzy", "w": True}))
        if sid in (12602, 12623, 12630, 12632, 12841):
            candidates = living(friends) if sid in (12602, 12632) else survivors
            if sid in (12602, 12841):
                selected = sorted(rng.sample(candidates, min(3, len(candidates))), key=lambda u: u["pos"])
            else:
                selected = [actor] if sid == 12632 else [u for u in candidates if sid != 12630 or u["pos"] < 8]
            kind, attr = ("promote", "atk") if sid in (12602, 12632) else ("weaken", "def")
            amount = Fraction(1, 5) if sid == 12632 else Fraction(1, 2) if sid == 12630 else Fraction(3, 10)
            duration = 3 if sid == 12841 else 2 if sid in (12602, 12632) else 1
            for target in selected:
                change = buff(target, {"effect": kind, "effect-param": f"{attr};{amount}", "effect-round": duration})
                if change:
                    changes.append(change)
        if sid in (12624, 12631):
            allies = sorted(living(friends), key=lambda u: (Fraction(u["hp"], u["maxhp"]), u["pos"]))
            if sid == 12624:
                changes.extend(change_hp(u, -stat(actor, "atk")) for u in allies)
            elif allies:
                changes.extend(set_state(allies[0], "invincible"))
        if sid in (12626, 12628, 12630, 12634, 12637):
            for target in survivors:
                if sid in (12626, 12628):
                    changes.append(change_ap(target, -rng.randint(1, 2)))
                elif (sid == 12630 and target["pos"] > 7 or sid == 12634 and target["pos"] < 8 and roll(Fraction(2, 5))
                      or sid == 12637 and target["pos"] > 7 and roll(skill["trigger"])):
                    changes.append(change_ap(target, -1))
        if sid in (12836, 12989, 13018, 13124):
            selected = sorted(survivors, key=lambda u: (-stat(u, "atk") if sid == 13018 else -u["ap"], u["pos"]))
            for target in selected[:1 if sid == 13018 else 2]:
                changes.append(change_ap(target, -2))
                if sid in (12989, 13124):
                    changes.extend(set_state(target, "skilllock"))
            if sid == 13018 and killed:
                changes.append(change_ap(actor, min(4, killed * 2)))
        if sid in (12635, 12990, 13073, 13079):
            allies = [u for u in living(friends) if u is not actor]
            shu = [u for u in allies if config["general"][str(u["cid"])]["region"] == "8"]
            candidates = shu if sid == 12990 and shu else allies
            for target in sorted(candidates, key=lambda u: (u["ap"], u["pos"]))[:2 if sid == 13073 else 1]:
                changes.append(change_ap(target, 4 if sid == 13079 or sid == 12990 and shu else 2))
        if sid in (12633, 12638):
            for target in survivors:
                if sid == 12633 and target["pos"] < 8 or sid == 12638 and roll(skill["trigger"]):
                    # shortcut: 合体灼烧未给比例，沿用本地普攻10%/跳，拿到实战参数后替换。
                    amount = damage({**actor, "atk": stat(actor, "atk")},
                                    {**target, "def": stat(target, "def"), "hp": target["maxhp"]}, config) // 10
                    change = status_damage(target, "firing", amount, 3 if sid == 12633 else 2)
                    if change:
                        changes.append(change)
        if sid == 13078:
            allies = living(friends)
            for target in sorted(rng.sample(allies, min(4, len(allies))), key=lambda u: u["pos"]):
                changes.extend(set_state(target, "xiyin"))
        if sid == 13125:
            for target in survivors:
                if roll(skill["trigger"]):
                    changes.extend(set_state(target, "fire", MAX_ROUNDS + 1))
        if changes:
            event(changes)

    def boss_act(actor):
        cycle = actor["boss_cycle"]
        index = actor.get("boss_turn", 0)
        actor["boss_turn"] = index + 1
        sid = cycle[index % len(cycle)]
        skill = config["combskill"][str(sid)]
        enemies = living(teams[not actor["direct"]])
        source = {"r": actor["direct"], "p": [actor["pos"]], "t": "x", "S": sid}
        if sid == 12646:
            actor["def"] += actor["base"]["def"] // 5
            event([dest(actor, B={"R": "def", "u": "promote", "w": True})], source)
            return []
        if sid == 12640:
            selected = sorted(enemies, key=lambda u: (u["pos"] != actor["pos"], u["pos"] > 7, u["pos"]))[:1]
        elif sid in (12641, 12642):
            selected = [u for u in enemies if u["pos"] < 8] or enemies
        elif sid == 12645:
            selected = rng.sample(enemies, min(1, len(enemies)))
        else:
            selected = enemies
        destinations, killed = [], 0
        for target in selected:
            if sid == 12644:
                destinations.append(change_ap(target, -skill["ap_reduce"]))
                continue
            if sid in (12640, 12647):
                amount = target["hp"]
            elif sid == 12642:
                amount = target["maxhp"] // 2
            else:
                amount = damage({**actor, "atk": stat(actor, "atk")},
                                {**target, "def": stat(target, "def"), "hp": target["hp"] + target["cover_d"]},
                                config, sid, multiplier=modifiers(actor, target) * guard(target),
                                flat=actor["flat_out"] - target["flat_in"], combo=True)
            change = change_hp(target, amount, hits=skill["count"], shield=sid not in (12640, 12647))
            if target["hp"] > 0:
                if sid == 12641:
                    target["ap"] = max(0, target["ap"] - skill["ap_reduce"])
                    change.update(ap=target["ap"], E=True)
                if sid == 12645 and stun(target, 2):
                    change["u"] = {"u": "dizzy", "w": True}
            killed += int(target["hp"] == 0)
            destinations.append(change)
        event(destinations, source)
        if sid != 12644:
            for target in selected:
                amount = queen_recovery(target)
                if target["hp"] > 0 and amount:
                    event([change_hp(target, -amount)])
        if sid == 12641:
            event([change_hp(actor, actor["maxhp"] // 100, shield=False)])
        actor["strikes"] += 1
        kill_recovery(actor, killed)
        deaths()
        return []

    def act(actor, forced_target=None, reaction=False, followup=None, chain=0):
        if actor["skill"] == 12858:
            return []  # 活动Boss配置的空技能，不退化成普通攻击。
        if "boss_cycle" in actor and not reaction:
            if actor["states"].get("skilllock", 0) > round_number:
                return []  # 无配置普攻；封印期间停手，不推进技能循环。
            return boss_act(actor)
        enemies, friends = teams[not actor["direct"]], teams[actor["direct"]]
        skill, participants = None, [actor["pos"]]
        base_skill = config["skill"].get(str(actor["skill"]))
        if followup:
            skill, participants, _ = followup
        elif not reaction and actor["states"].get("skilllock", 0) <= round_number:
            if base_skill and actor["ap"] >= base_skill["ap"]:
                skill = config["combskill"]["12618"] if actor["cid"] == 10112 else base_skill
            combination = choose_combo(actor, friends, enemies)
            if combination:
                skill, participants = combination
        combined = skill is not None and skill is config["combskill"].get(str(skill["id"]))
        if skill and skill["kind"] == "gain":
            selected = sorted((u for u in friends.values() if u["hp"] > 0), key=lambda u: (Fraction(u["hp"], u["maxhp"]), u["pos"]))
            if skill["range"] in ("first", "second"):
                selected = [u for u in selected if (u["pos"] < 8) == (skill["range"] == "first")]
            else:
                selected = selected[:skill["randnum"] if skill["range"] == "random" else len(selected) if skill["range"] == "all" else 1]
        else:
            selected = [forced_target] if forced_target else targets(actor, enemies, skill, rng)
            if reaction and forced_target and 9000028 in actor["effects"]:
                selected = targets(actor, enemies, {"range": "three"}, rng)
            elif not skill and not forced_target and 9000501 in actor["effects"]:
                selected = sorted((u for u in enemies.values() if u["hp"] > 0), key=lambda u: (-stat(u, "atk"), u["pos"]))[:1]
        if skill and not combined and effect(actor, 9000528):
            candidates = friends if skill["kind"] == "gain" else enemies
            extra = sorted((u for u in candidates.values() if u["hp"] > 0 and u not in selected),
                           key=lambda u: (Fraction(u["hp"], u["maxhp"]) if skill["kind"] == "gain" else 0, u["pos"]))
            selected += extra[:int(effect(actor, 9000528))]
        if not selected:
            return []
        skill_id = skill["id"] if skill else None
        combo_id = skill_id if combined else None
        source = {"r": actor["direct"], "p": participants, "t": "x" if combined else "k" if skill else "N"}
        if skill:
            source["S"] = skill_id
        old_ap = followup[2] if followup else actor["ap"]
        if not followup:
            actor["ap"] = 0 if skill else min(10, old_ap + 2)
        destinations, reactions, dealt, recovered = [], [], 0, []
        killed, hit_targets, burned = 0, [], False
        critical_targets = set()
        if combo_id == 13077:
            critical_targets = {u["pos"] for u in rng.sample(selected, min(4, len(selected)))}
        male_count = sum(config["general"][str(u["cid"])]["sex"] == "nan" and config["general"][str(u["cid"])]["name"] != "主角"
                         for u in living(enemies)) if combo_id == 13017 else 0
        dead_count = sum(u["hp"] <= 0 for u in enemies.values()) if combo_id == 13122 else 0
        for target in selected:
            if target["hp"] <= 0:
                continue
            if skill and skill["kind"] == "gain":
                if 9000412 in actor["effects"]:
                    destinations.extend(cleanse(target))
                coefficient, growth = map(Fraction, skill["atk-param"].split(";")[:2])
                multiplier = 1 + max(0, old_ap - skill["ap"]) * Fraction(str(skill["ap_up"]))
                amount = int(stat(actor, "atk") * (coefficient + (0 if combined else growth * max(0, actor.get("skilllevel", 0) - 1))) * multiplier)
                destinations.append(change_hp(target, -amount))
                if skill.get("effect") == "promote" and roll(skill["effect-trigger"]):
                    change = buff(target, skill)
                    if change:
                        destinations.append(change)
                continue
            dodge = max(0, min(75, stat(target, "dodge") - actor.get("hit", 0))) / 100
            if roll(dodge):
                destinations.append(dest(target, m={"m": 0, "f": 0, "u": "dodge", "U": 0}))
                continue
            critical_chance = (stat(actor, "critical") - stat(target, "resilience")) / 100 if 9000030 not in target["effects"] else 0
            critical_chance += Fraction(3, 10) if combo_id == 12627 and 9000030 not in target["effects"] else 0
            critical = (combo_id == 12618 and target["pos"] < 8 or combo_id == 12632 or target["pos"] in critical_targets
                        or roll(max(0, min(.75, critical_chance))))
            parry = roll(max(0, min(.5, (stat(target, "parry") - stat(actor, "arp")) / 100)))
            multiplier = modifiers(actor, target)
            if skill:
                multiplier *= 1 + max(0, old_ap - skill["ap"]) * Fraction(str(skill["ap_up"]))
                coefficient, growth = map(Fraction, skill["atk-param"].split(";")[:2])
                if not combined:
                    multiplier *= (coefficient + growth * max(0, actor.get("skilllevel", 0) - 1)) / coefficient
                if combo_id == 12629:
                    multiplier *= 1 + Fraction(target["hp"] * 5 // target["maxhp"], 5)
                elif combo_id == 13076:
                    multiplier *= (coefficient - Fraction(skill["atk-param2"]) * len(selected)) / coefficient
                elif combo_id == 13122:
                    multiplier *= 1 + Fraction(dead_count, 4)
                if target["states"].get("fire", 0) > round_number:
                    multiplier *= 2
            multiplier *= guard(target)
            if parry:
                multiplier *= Fraction(3, 10)
            attacker, defender = {**actor, "atk": max(1, stat(actor, "atk"))}, {**target, "def": stat(target, "def"), "hp": target["hp"] + target["cover_d"]}
            amount = damage(attacker, defender, config, skill_id, critical, multiplier=multiplier, combo=combined,
                            flat=actor["flat_out"] - target["flat_in"],
                             critical_multiplier=Fraction(3, 2) + Fraction(actor.get("criticaldmg", 0) + actor.get("pet_rates", {}).get("criticaldmg", 0), 100)
                            + (Fraction(1, 10) if combo_id == 12627 else 0))
            hit = change_hp(target, amount, "parry" if parry else "C" if critical else "N",
                             skill["count"] if critical and skill else int(critical))
            dealt += hit["m"]["m"]
            killed += int(target["hp"] == 0)
            amount = hit["m"]["m"] + hit["m"].get("M", 0)
            if skill and amount > 0 and target["states"].pop("fire", None):
                destinations.append(state_event(target, "fire", False))
            if amount > 0:
                hit_targets.append(target)
            if target["hp"] > 0 and amount > 0:
                dizzy = (combo_id == 12622 and target["hp"] * 5 < target["maxhp"]
                         or combo_id == 12618 and target["pos"] > 7 and roll(.35)
                         or skill and skill.get("effect") == "dizzy" and roll(skill["effect-trigger"])
                         or not skill and 9100002 in actor["effects"] and roll(.3))
                dizzy = dizzy or target["firing"] and roll(effect(actor, 9000483))
                if dizzy and stun(target):
                    hit["u"] = {"u": "dizzy", "w": True}
                poison = skill and skill.get("effect") == "dot" and roll(skill["effect-trigger"])
                if poison or roll(effect(actor, 9000039) / 100):
                    tick = damage(attacker, {**defender, "hp": (1 << 63) - 1}, config)
                    change = status_damage(target, "dot", int(tick * (Fraction(skill["effect-param"]) if poison else Fraction(1, 10))), skill["effect-round"] if poison else 2)
                    if change:
                        destinations.append(change)
                if skill and skill.get("effect") == "firing" and roll(skill["effect-trigger"]):
                    tick = damage(attacker, {**defender, "hp": target["maxhp"]}, config)
                    change = status_damage(target, "firing", int(tick * Fraction(skill["effect-param"])), skill["effect-round"])
                    if change:
                        destinations.append(change)
                if skill and effect(actor, 9000803) and roll(effect(actor, 9000803, "value2")):
                    change = status_damage(target, "firing", min(actor["maxhp"], int(target["maxhp"] * effect(actor, 9000803))), 2)
                    if change:
                        destinations.append(change)
                        burned = True
                if skill and skill.get("effect") == "weaken" and roll(skill["effect-trigger"]):
                    change = buff(target, skill)
                    if change:
                        destinations.append(change)
                reduction = (skill["ap_reduce"] if skill else 0) + (int(effect(actor, 9000020)) if target["dot"] else 0)
                if reduction:
                    target["ap"] = max(0, target["ap"] - reduction)
                    destinations.append(dest(target, ap=target["ap"], E=True))
                amount = queen_recovery(target)
                if amount:
                    recovered.append((target, amount))
                if not reaction and not target["dizzy"]:
                    if parry:
                        reactions.append((target, actor))
                    if target["low_action"] and not target["emergency"] and target["hp"] * 5 < target["maxhp"]:
                        target["emergency"] = True
                        reactions.append((target, None))
            destinations.append(hit)
        if hit_targets:
            actor["strikes"] += 1
        if skill and effect(actor, 9000803) and not burned:
            target = next((u for u in hit_targets if u["hp"] > 0), None)
            if target:
                change = status_damage(target, "firing", min(actor["maxhp"], int(target["maxhp"] * effect(actor, 9000803))), 2)
                if change:
                    destinations.append(change)
        destinations.append(dest(actor, ap=actor["ap"], E=False))
        if skill and skill["ap_give"] and (not followup or not combined):
            actor["ap"] = min(10, actor["ap"] + skill["ap_give"])
            destinations.append(dest(actor, ap=actor["ap"], E=True))
        event(destinations, source)
        if combo_id in MULTI_COMBOS:
            combo_effects(actor, skill, hit_targets, killed)
        if skill and skill.get("effect") == "suck" and dealt and actor["hp"] > 0:
            amount = min(actor["maxhp"] - actor["hp"], int(dealt * Fraction(skill["effect-param"])))
            if amount:
                event([change_hp(actor, -amount)])
        if not skill and dealt and actor["hp"] > 0 and effect(actor, 9000031):
            event([change_hp(actor, -int(dealt * effect(actor, 9000031)))])
        kill_recovery(actor, killed)
        deaths()
        if not reaction and actor["hp"] > 0:
            extra_kills = 0
            for _, target in sorted(enemies.items()):
                if target["hp"] <= 0:
                    continue
                for coefficient, fixed in ((effect(actor, 9000674), 0), (0, int(actor["maxhp"] * effect(actor, 9000025)) if skill else 0)):
                    if target["hp"] > 0 and (coefficient or fixed):
                        event([extra_hit(actor, target, coefficient, fixed)])
                        extra_kills += int(target["hp"] == 0)
            kill_recovery(actor, extra_kills)
            deaths()
        if skill and skill["kind"] == "attack" and skill.get("effect") == "promote" and roll(skill["effect-trigger"]):
            change = buff(actor, skill)
            if change and actor["hp"] > 0:
                event([change])
        for target, amount in recovered:
            if target["hp"] > 0:
                event([change_hp(target, -amount)])
        if actor["hp"] > 0 and not actor["dizzy"] and actor["states"].get("skilllock", 0) <= round_number and not finished():
            if combo_id in (12604, 12943) and all(friends[p]["hp"] > 0 and not friends[p]["dizzy"]
                and friends[p]["states"].get("skilllock", 0) <= round_number for p in participants):
                # shortcut: 续击概率用配置trigger，最多5击；拿到官服续击参数后替换。
                candidates = [u for u in living(enemies) if combo_id != 12943 or u not in selected]
                if chain < 4 and candidates and roll(skill["trigger"]):
                    target = selected[0] if combo_id == 12604 and selected[0]["hp"] > 0 else candidates[0]
                    reactions += act(actor, target, followup=(skill, participants, old_ap), chain=chain + 1)
            elif combo_id == 13017 and base_skill and roll(Fraction(male_count, 10)):
                reactions += act(actor, followup=(base_skill, [actor["pos"]], base_skill["ap"]))
        return reactions

    def pet_action(direct, pet):
        skill = config["combskill"][str(pet["skill"])]
        if not roll(Fraction(str(skill["trigger"]))):
            return
        friends = [u for _, u in sorted(teams[direct].items()) if u["hp"] > 0]
        enemies = [u for _, u in sorted(teams[not direct].items()) if u["hp"] > 0]
        cid, sid = pet["cid"], pet["skill"]
        coefficient = Fraction(skill["atk-param"].split(";")[0].strip())
        destinations = []
        if cid == 90001:
            selected = sorted(friends, key=lambda u: (u["hp"], u["pos"]))[:skill["randnum"]]
            destinations = [change_hp(u, -int((u["maxhp"] - u["hp"]) * coefficient)) for u in selected]
        else:
            candidates = enemies if cid in (90003, 90005) else friends
            if cid == 90008:
                count = rng.randint(1 if sid == 12998 else 2, skill["randnum"]) if sid in (12998, 14032) else skill["randnum"]
                selected = sorted(rng.sample(enemies, min(len(enemies), count)), key=lambda u: u["pos"])
                average = sum(stat(u, "atk") for u in friends) // len(friends)
                for target in selected:
                    amount = damage({"atk": max(1, average)}, {**target, "def": stat(target, "def"), "hp": target["hp"] + target["cover_d"]},
                                    config, sid, multiplier=target["in_multiplier"] * guard(target))
                    destinations.append(change_hp(target, amount))
                    if target["hp"] > 0 and sid != 12996:
                        target["ap"] = max(0, target["ap"] - 2)
                        destinations.append(dest(target, ap=target["ap"], E=True))
                candidates = friends
            front = cid in (90002, 90003)
            preferred = [u for u in candidates if (u["pos"] < 8) == front]
            other = [u for u in candidates if u not in preferred]
            count = 3 if cid == 90008 else skill["randnum"]
            if cid == 90008 and sid >= 14031:
                count = 4
            # 四目标金宠优先三后排一前排；不足时从其余存活位置补齐。
            first = min(len(preferred), count, 3 if count == 4 else count)
            selected = rng.sample(preferred, first)
            selected += rng.sample(other, min(len(other), count - len(selected)))
            remaining = [u for u in candidates if u not in selected]
            selected += rng.sample(remaining, min(len(remaining), count - len(selected)))
            selected.sort(key=lambda u: u["pos"])
            attr = "def" if front else "atk"
            kind = "weaken" if cid in (90003, 90005) else "promote"
            for target in selected:
                amount = Fraction(2, 5) if cid == 90008 else coefficient
                target["buffs"][kind, attr] = (amount, round_number + 2)
                destinations.append(dest(target, B={"R": attr, "u": kind, "w": True}))
                if sid in (14029, 14030):
                    target["buffs"]["promote", "critical"] = (Fraction(15 if sid == 14029 else 30, 100), round_number + 2)
                    destinations.append(dest(target, B={"R": "critical", "u": "promote", "w": True}))
            ap_count = {12936: 1, 12937: 2, 12939: 1, 12940: 2, 12941: 3, 14019: 2, 14020: 3,
                        14021: 4, 14025: 2, 14026: 3, 14027: 4, 14028: 4, 14029: 4, 14030: 4,
                        14023: 1, 14024: 2, 12996: 1, 12997: 2, 12998: 3, 14031: 4, 14032: 4, 14033: 4}.get(sid, 0)
            for target in sorted(rng.sample(selected, min(len(selected), ap_count)), key=lambda u: u["pos"]):
                target["ap"] = max(0, min(10, target["ap"] + (-2 if kind == "weaken" else 2)))
                destinations.append(dest(target, ap=target["ap"], E=True))
        event(destinations, {"r": direct, "p": [0], "t": "x", "S": sid})
        deaths()

    round_number = 0
    for team in teams.values():
        for unit in team.values():
            for kind, attr in unit["buffs"]:
                event([dest(unit, B={"R": attr, "u": kind, "w": True})])
            if unit["cid"] in QUEENS:
                event([dest(u, m={"m": 0, "f": 0, "u": "N", "U": 0}) for _, u in sorted(team.items())],
                      {"r": unit["direct"], "p": [unit["pos"]], "t": "x", "S": 12859})
    for round_number in range(1, max_rounds + 1):
        if round_number > 1:
            event([])
        if finished():
            break
        for team in teams.values():
            for unit in living(team):
                if unit.get("boss_passive") == 12648:
                    unit["atk"] += unit["base"]["atk"] // 5
                    event([change_ap(unit, config["combskill"]["12648"]["ap_give"]),
                           dest(unit, B={"R": "atk", "u": "promote", "w": True})],
                          {"r": unit["direct"], "p": [unit["pos"]], "t": "x", "S": 12648})
                for kind, until in list(unit["states"].items()):
                    if until <= round_number:
                        del unit["states"][kind]
                        event([state_event(unit, kind, False)])
        for direct, pet in combat_pets.items():
            if pet is not None and not finished():
                pet_action(direct, pet)
        order = sorted((u for team in teams.values() for u in team.values() if u["hp"] > 0),
                       key=lambda u: (-u["speed"], u["pos"], not u["direct"], u["iid"]))
        for actor in order:
            if finished():
                break
            if actor["hp"] <= 0:
                continue
            for (kind, attr), (_, until) in list(actor["buffs"].items()):
                if until <= round_number:
                    del actor["buffs"][(kind, attr)]
                    event([dest(actor, B={"R": attr, "u": kind, "w": False})])
            for kind in ("dot", "firing"):
                if actor[kind] and actor["hp"] > 0:
                    event([change_hp(actor, actor[kind][0], kind, shield=False)])
                    actor[kind][1] -= 1
                    if not actor[kind][1]:
                        actor[kind] = None
                        event([dest(actor, m=[], u={"u": kind, "w": False})])
                    deaths()
            if actor["hp"] <= 0 or finished():
                continue
            if actor["dizzy"]:
                actor["dizzy"] -= 1
                if not actor["dizzy"]:
                    event([dest(actor, m=[], u={"u": "dizzy", "w": False})])
                continue
            for reactor, target in act(actor):
                if finished():
                    break
                if reactor["hp"] > 0 and not reactor["dizzy"] and (target is None or target["hp"] > 0):
                    act(reactor, target, reaction=True)
        if finished():
            break
        if round_number == 5:
            for team in teams.values():
                for unit in living(team):
                    if 9100004 in unit["effects"] and unit["hp"] < unit["maxhp"]:
                        event([change_hp(unit, unit["hp"] - unit["maxhp"])])
    won = any(u["hp"] > 0 for u in teams[True].values()) and not any(u["hp"] > 0 for u in teams[False].values())
    remaining = sum(u["hp"] for u in teams[True].values())
    maximum = sum(u["maxhp"] for u in teams[True].values())
    star = (3 if remaining * 10 >= maximum * 7 else 2 if remaining * 10 >= maximum * 3 else 1) if won else 0
    report.update(result=won, star=star, round=round_number)
    for direct, team in teams.items():
        report["endmeta"]["attack" if direct else "defense"] = {
            str(pos): {"i": u["iid"], "c": u["cid"], "h": u["hp"], "j": u["maxhp"], "ap": u["ap"],
                       "cover_d": u["cover_d"], "feign_dead": False, "region": config["general"][str(u["cid"])]["region"]}
            for pos, u in sorted(team.items())}
    return report


def general_base(row, name, level, advance, config):
    value = Fraction(str(row[name])) + Fraction(str(row.get(f"{name}-grow", 0))) * (level - 1)
    if row.get("init_cid") and advance and name in ("atk", "def", "hp"):
        value *= 1 + Fraction(str(config["general_awake"][str(advance)]["promote"])) / 100
    return value


def self_stats(row, level, advance, config):
    values = {field: Fraction(0) for field in range(6, 17)}
    ids = {row.get(f"break{i}", 0) for i in range(1, advance + 1)} - {0}
    for pid in sorted(ids):
        passive = config["breakskill"][str(pid)]
        name = passive["attr"]
        if passive["type"] != 0 or passive["target"] != "3" or GENERAL_FIELDS.get(name) not in values:
            continue
        if passive["method"] not in ("value", "percent") or passive["kind"] not in ("0", "1"):
            raise ValueError("自身突破属性配置无效")
        value = Fraction(str(passive["value"])) * (-1 if passive["kind"] == "1" else 1)
        # 四围百分比只乘通用突破后的基础成长；概率属性使用配置百分点。
        if passive["method"] == "percent" and name in ("atk", "def", "hp", "speed"):
            value *= int(general_base(row, name, level, advance, config))
        values[GENERAL_FIELDS[name]] += value
    return {field: int(value) for field, value in values.items()}


def grown_general(unit, gained, config, maximum=None):
    level, experience, up = general_experience(unit, gained, config, maximum)
    values = {3: level, 5: experience}
    row = config["general"][str(unit["cid"])]
    previous = self_stats(row, unit["level"], unit.get("advance", 0), config)
    current = self_stats(row, level, unit.get("advance", 0), config)
    deltas = {}
    for name in ("atk", "def", "hp", "speed"):
        delta = (int(general_base(row, name, level, unit.get("advance", 0), config))
                 - int(general_base(row, name, unit["level"], unit.get("advance", 0), config))
                 + current[GENERAL_FIELDS[name]] - previous[GENERAL_FIELDS[name]])
        values[GENERAL_FIELDS[name]] = unit[name] + delta
        deltas[name] = delta
    # 自研战力仅用于显示：保留旧基值，新增成长按四围增量计分，不参与胜负。
    power = deltas["atk"] + deltas["def"] + values[8] // 10 - unit["hp"] // 10 + deltas["speed"]
    if any(not 0 <= value < (1 << 31) for value in values.values()):
        raise ValueError("武将升级数值超出范围")
    return values, power, up


def drops(point, first_win, config, seed):
    rng = random.Random(seed)
    rewards = {}

    def add(cid, count=1):
        rewards[cid] = rewards.get(cid, 0) + count

    if first_win and point["drop"]:
        add(point["drop"])
    else:
        for i in range(1, 4):
            if point[f"drop{i}"] and rng.randrange(100) < point[f"drop{i}prob"]:
                add(point[f"drop{i}"])
    for suffix in ("", "1"):
        group = point[f"randdrop{suffix}"]
        if not group or rng.randrange(100) >= point[f"randdropprob{suffix}"]:
            continue
        row = config["worlddrop"].get(str(group))
        if not row:
            raise ValueError("不支持的关卡掉落表")
        entries = [tuple(map(int, value.split(","))) for value in row["drop"].split(";") if value]
        if (not entries or any(len(e) != 3 or min(e[:2]) <= 0 or e[2] < 0 for e in entries)
                or not any(e[2] for e in entries)):
            raise ValueError("关卡掉落配置无效")
        draw = rng.randrange(sum(e[2] for e in entries))
        for cid, count, weight in entries:
            draw -= weight
            if draw < 0:
                add(cid, count)
                break
    return rewards
