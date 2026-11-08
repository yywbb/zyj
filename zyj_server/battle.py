"""自研回合战斗 v2；纯计算、配置与战报，规则及适用范围见 battle_rules.md。"""

import copy
import random
from fractions import Fraction

from . import guild_skill

from . import artifact, cover, equip_baptize, equip_evolve, godstone, illusion, magic, partner_growth, pets, sigil, soul, treasure_refine, wing
from .protocol import encode_pb_field, iter_pb_fields, parse_ids_pb, pb_get_varint


POSITIONS = (2, 8, 10, 4, 12, 6, 14)
QUEENS = (10595, 10817)
MAX_ROUNDS = 30
# shortcut: 已接玉鼎、元始、通天、广成子、太乙，其他彩金技能须实现并回归后才允许付费转换。
PARTNER_EFFECTS = {*range(9000742, 9000748), *range(9000547, 9000553), *range(9000678, 9000684),
                   *range(9000688, 9000694), *range(9000598, 9000604)}
# 广成子彩金技能 9001142–9001147：诅咒/守护印记比例取自配置描述，配置无独立字段。
# 9000692 同时是「专属神器S1」的行ID（type=0、code 回退到自身ID），仙命加成只认这两行。
GUANGCHENGZI_AURA_SKILLS = (9001146, 9001147)
# 太乙真人彩金技能 9001070–9001075：效果号 9000598–9000603 同时是「傲骨 I–VI」的行 ID，
# 但引擎按 type_param 判定（傲骨族实际为 9000481），不会误放行；9000600 亦是无当圣母
# 9001231「过载」的效果号，两行 value/value2/描述完全一致，共享同一实现。
TAIYI_AURA_SKILLS = (9001074, 9001075)
TAIYI_HEAL_SHARING = 9000602
CURSE_ATTACK = Fraction(1, 10)
CURSE_DEFENSE = Fraction(1, 5)
CURSE_DAMAGE = Fraction(2, 5)
# 主角彩金进阶24–26的天/地/人突破技能效果。
LEAD_GOLD_EFFECTS = set(range(9000517, 9000524))
HADES_EFFECTS = {9000022, 9000034, 9000306, 9000307, 9000309, 9000314, 9000315, 9000316, 9000318,
                 9000322, 9000323, 9000403, 9000414, 9000415, 9000416, *range(9000418, 9000429),
                 *range(9000431, 9000436), *range(9000437, 9000445),
                 9000466, 9000468, 9000469, 9000470, 9000471, 9000472, 9000476,
                 *range(9000479, 9000489), *range(9000490, 9000496), 9000497, 9000498, 9000499, 9000500,
                 9000504, 9000505, 9000584, 9000585, 9000586, 9000606, 9000675, 9000676, 9000677,
                 9000687, 9000759, 9000760, 9000761, 9000762, 9000769, 9000770, 9000771, 9000775,
                 9000776, 9000777, 9000778, 9000783, 9000784, 9000785, 9000792, 9000793, 9000795,
                 9000796, 9000804, 9000805, 9000806, 9000807, 9999991}
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


def rosters(save, point, config, *, illusion_mode="pve", now=None):
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
    wings = wing.get_state(save, config)
    covers, _ = cover.bonuses(save, config)
    artifacts, _ = artifact.read_world(save, config)
    protagonist_raw = bytes.fromhex(save.get("protagonist_snapshot", "")) or next((v for n, w, v in fields if (n, w) == (6, 2)), b"")
    protagonist = pb_get_varint(protagonist_raw, 1)
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
            if iid != protagonist:
                partner_growth.validate(raw, config)
            else:
                from . import development
                soaring = development.lead_fairy(raw, config)[0]
                # 主角飞升仙属性按同比例折算进战斗面板，与伙伴一致；彩金属性同字段叠加。
                if soaring:
                    factor = Fraction(config["global_kv"]["fairy_turn_every"]["value"])
                    for name, field in (("hp", 24), ("def", 25), ("atk", 26)):
                        unit[name] += int((pb_get_varint(raw, field) or 0)*factor)
                    unit["fei_sheng_level"] = soaring
                if unit["advance"] > development.gold_limit(config):
                    unit.update(partner_skills=partner_growth.skills(raw, config), gold_camp=pb_get_varint(raw, 40) or 0)
        if index > config["role_exp"][str(save["role_state"]["level"])]["slotnum"]:
            raise ValueError("阵位尚未解锁")
        if POSITIONS[index - 1] in attack or any(u["iid"] == iid for u in attack.values()):
            raise ValueError("阵位或上阵武将重复")
        unit["skill"] = config["general"][str(unit["cid"])]["skillid"]
        worn = pb_get_varint(slot, 26) or 0
        if worn:
            data = artifact.values(artifacts[worn])
            unit["artifact"] = {"cid": data[1], "level": data[13], "skills": [sid for sid in data[6:9] if sid]}
        mask = covers[index]
        if mask["level"]:
            unit.update(cover_l=mask["level"], cover_d=mask["value"], cover_p=mask["percent"], skill_resilience=mask["skill_resilience"])
        if iid == protagonist and wings["stage"]:
            unit.update(w_l=wings["stage"], w_c=wings["color"])
        if iid == protagonist and unit["skilllevel"]:
            awakening = config["protagonist_awaken"].get(str(unit["skilllevel"]))
            if awakening is None:
                raise ValueError("主角觉醒等级配置不存在")
            # 主角的同名字段是觉醒，不是旧版技能升级等级。
            unit.update(awakening=unit["skilllevel"], skilllevel=0,
                         adddmgpct=Fraction(str(awakening["adddmgpct"])), subdmgpct=Fraction(str(awakening["subdmgpct"])))
        elif iid != protagonist:
            unit.update(awakening=unit["skilllevel"], skilllevel=0, partner_skills=partner_growth.skills(raw, config), gold_camp=pb_get_varint(raw, 40) or 0)
            factor = Fraction(config["global_kv"]["fairy_turn_every"]["value"])
            for name, f in partner_growth.FAIRY.items():
                name = name.removeprefix("g_")
                unit[name] += int((pb_get_varint(raw, f) or 0)*factor)
            progress = partner_growth.research(save, iid, config)
            growth = partner_growth.research_stats(progress, config)
            unit.update(partner_flat=(growth["adddmg"], growth["subdmg"]),
                        adddmgpct=Fraction(config["Immortal_level"]["1"][str(progress[0])]["adddmgpct"], 100),
                        subdmgpct=Fraction(config["Immortal_level"]["2"][str(progress[5])]["subdmgpct"], 100))
        unit["flat_out"], unit["flat_in"] = equip_baptize.flat(slot, equips, config)
        unit["flat_out"] += unit.get("partner_flat", (0, 0))[0]
        unit["flat_in"] += unit.get("partner_flat", (0, 0))[1]
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
        image = illusion.effective(raw, save, config, illusion_mode, now)
        if image:
            source = config["general"][str(unit["cid"])]
            target = config["general"][str(image[8])]
            advance = min(unit["advance"], target["breach_upper_limit"])
            before = self_stats(source, unit["level"], unit["advance"], config)
            after = self_stats(target, unit["level"], advance, config, basis=(source, unit["advance"]))
            for name, field in GENERAL_FIELDS.items():
                if field in before:
                    unit[name] += after[field]-before[field]
            for name in ("atk", "def", "hp"):
                unit[name] = max(1 if name != "def" else 0, unit[name]*(100-image[7])//100)
            unit.update(cid=image[8], advance=advance, skill=target["skillid"], gold_camp=image[6],
                        partner_skills=[target[f"gold{i}_will_skills_{image[i]}"] for i in range(1, 4) if image[i]])
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
           flat=0, critical_multiplier=Fraction(3, 2), combo=False, final_multiplier=Fraction(1), clip=True):
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
    reduction = Fraction(str(defender.get("skill_resilience", 0)))
    if not 0 <= reduction <= 1:
        raise ValueError("技能减伤比例无效")
    if skill_id is not None:
        final_multiplier *= 1 - reduction
    amount = max(0, int((total + flat) * final_multiplier))
    return min(defender["hp"], amount) if clip else amount


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
    dynamic = {*range(9100001, 9100008), 9000001, 9000008, 9000015, 9000020, 9000021, 9000023, 9000024, 9000025,
               9000026, 9000027, 9000028, 9000029, 9000030, 9000031, 9000032, 9000036,
               9000037, 9000038, 9000039, 9000040, 9000062, 9000400, 9000401, 9000412, 9000413, 9000429, 9000430, 9000483, 9000489,
               9000496, 9000501, 9000502, 9000506, 9000528, 9000583, 9000674, 9000789, 9000791, 9000803,
               9000324, 9000327, 9000328, 9000329} | HADES_EFFECTS | PARTNER_EFFECTS | LEAD_GOLD_EFFECTS
    flat_defense = {9000047, 9000049, 9000072, 9000078, 9000082}
    stats = ("atk", "def", "hp", "speed", "critical", "dodge", "parry", "resilience", "hit", "arp", "criticaldmg")
    lead_basis = {}
    for direct, team in teams.items():
        if not team:
            raise ValueError("战斗双方必须有上阵武将")
        for pos, unit in sorted(team.items()):
            if pos not in POSITIONS or any(unit[k] <= 0 for k in ("hp", "atk", "speed")) or unit["def"] < 0:
                raise ValueError("战斗属性或阵位无效")
            general = config["general"][str(unit["cid"])]
            advance_limit = (int(config["global_kv"]["passive_breakthrough_limit"]["value"]) + 3
                             if general.get("actor") == "lead" else 23)
            if not 0 <= unit["advance"] <= advance_limit or not 0 <= unit.get("skilllevel", 0) <= 300:
                raise ValueError("战斗突破或技能等级无效")
            skill = config["skill"].get(str(unit["skill"]))
            if "boss_cycle" in unit:
                if (not unit.get("npc") or str(unit["cid"]) not in config.get("personalboss_att", {})
                        or not isinstance(unit["boss_cycle"], list) or not unit["boss_cycle"]
                        or any(type(sid) is not int or sid not in range(12640, 12648)
                               or str(sid) not in config["combskill"] for sid in unit["boss_cycle"])
                        or unit.get("boss_passive", 0) not in (0, 12648)):
                    raise ValueError("个人Boss技能循环无效")
            if not skill and not (unit["cid"] in QUEENS and unit["skill"] == 0
                                  or unit.get("npc") and unit["cid"] in (10820, 10822, 10823) and unit["skill"] == 0
                                  or "boss_cycle" in unit and unit["skill"] == 0
                                  or str(unit["cid"]) in config.get("huodong_monster", {}) and unit["skill"] == 12858):
                raise ValueError("武将技能不存在")
            if skill and (skill["kind"] not in ("attack", "gain") or skill["range"] not in ("single", "all", "first", "second", "random", "three")
                          or skill["effect"] not in ("once", "dizzy", "dot", "firing", "suck", "promote", "weaken")):
                raise ValueError("尚不支持该武将的技能效果")
            ids = {general.get(f"break{i}", 0) for i in range(1, unit["advance"] + 1)} - {0}
            partner_ids = unit.get("partner_skills", ())
            basis = int(config["global_kv"]["passive_breakthrough_limit" if general.get("actor") == "lead" else "partner_breakthrough_limit"]["value"])
            allowed = {general.get(f"gold{i}_will_skills_{choice}", 0)
                       for i in range(1, max(0, unit["advance"]-basis)+1) for choice in (1, 2, 3)}-{0}
            if not isinstance(partner_ids, (list, tuple)) or len(partner_ids) > 3 or any(pid not in allowed for pid in partner_ids):
                raise ValueError("彩金突破技能与当前伙伴不一致")
            ids.update(partner_ids)
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
            unit.update(passive_buffs={}, trigger_counts={}, received_hits=0, casts=0, fire_seeds=0,
                        hidden=False, heal_shield=0, ap_self_guard=0, ap_received_guard=0)
            unit["cover_d2"] = unit["cover_d"]
            added, reduced = unit.get("adddmgpct", 0), unit.get("subdmgpct", 0)
            if added <= -1 or min(reduced, unit["cover_d"]) < 0 or not 0 <= unit.get("cover_p", 0) <= 100:
                raise ValueError("增减伤或魔罩属性无效")
            unit.update(out_multiplier=1 + Fraction(str(added)), in_multiplier=1 / (1 + Fraction(str(reduced))))
            unit["artifact_effects"] = artifact.combat_effects(unit.get("artifact"), config)
            unit["artifact_used"] = {}
            if "神降" in unit["artifact_effects"]:
                unit["out_multiplier"] *= 1 + Fraction(str(unit["artifact_effects"]["神降"]["value"]))
            unit["base"] = {name: unit.get(name, 0) for name in stats}
            for row in rows:
                attr, code = row["attr"], row["type_param"] or row["id"]
                # 主角的种类号与别行ID重号，按本行识别，不能套用被引用行的效果。
                if 9100001 <= row["id"] <= 9100007:
                    code = row["id"]
                if code == 9999991 and (row["id"], row["type"], attr, row["target"], row["value"], row["method"], row["kind"]) != (9999991, 2, "hp", "1", 100000, "value", "0"):
                    raise ValueError("尚不支持该突破被动 9999991")
                if row["type"] == 0 and code not in range(9100001, 9100005):
                    if attr not in (*stats, "ap", "dmg", "fdmg") or row["target"] not in ("1", "2", "3", "4", "5", "7"):
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
                if row["type"] == 0 or row["type"] == 2 and code in HADES_EFFECTS or code == 9000001:
                    if row["attr"] == "fdmg" or row["method"] == "value" and row["attr"] == "dmg":
                        continue
                    scope = row["target"]
                    targets = ([provider] if scope == "3" else list(teams[not direct].values()) if scope in ("2", "4", "5") else list(team.values()))
                    for target in targets:
                        if (scope == "4" and target["pos"] > 7 or scope in ("5", "7") and target["pos"] < 8
                                or not matches(target, row["region"], row["sex"])):
                            continue
                        group = ("ap", scope, row["region"], row["sex"], row["kind"], value) if row["attr"] == "ap" else row["id"]
                        key = (direct, group, target["direct"], target["pos"])
                        if key in applied:
                            continue
                        applied.add(key)
                        attr = "dmg" if code == 9000001 else row["attr"]
                        if scope == "3" and not target.get("npc") and attr in stats:
                            continue  # 玩家快照已汇总自身常驻属性，不能再加一次。
                        if attr == "dmg" and row["kind"] == "1":
                            attr = "reduction"
                        add(target, attr, -value if row["kind"] == "1" and attr != "reduction" else value, row["method"])
                if code in HADES_EFFECTS:
                    if code == 9000490:
                        add(provider, "dmg", Fraction(str(row["value2"])))
                    aura = ("atk" if code in (9000419, 9000420, 9000421, 9000422, 9000431, 9000444, 9000480, 9000490, 9000491, 9000677, 9000498, 9000807)
                            else "hp" if code in (9000423, 9000424, 9000425, 9000432, 9000433, 9000434, 9000435, 9000437, 9000486, 9000505, 9000778)
                            else "def" if code in (9000426, 9000427, 9000428, 9000438, 9000439, 9000442, 9000482, 9000495, 9000762, 9000785, 9000796) else None)
                    if aura and row["value2"] >= 1000 and (direct, code) not in applied:
                        applied.add((direct, code))
                        for target in team.values():
                            if config["general"][str(target["cid"])]["quality"] >= 6:
                                add(target, aura, Fraction(str(row["value2"])))
                    if code in (9000415, 9000416, 9000487, 9000494) and (direct, code) not in applied:
                        applied.add((direct, code))
                        humans = [u for u in teams[not direct].values() if config["general"][str(u["cid"])]["region"] in ("7", "8")]
                        if code in (9000415, 9000416):
                            for target in humans:
                                add(target, "def" if code == 9000415 else "atk", -Fraction(3, 10) if code == 9000415 else -Fraction(1, 5), "percent")
                        else:
                            for target in team.values():
                                add(target, "atk" if code == 9000487 else "def", len(humans) * (Fraction(1, 25) if code == 9000487 else Fraction(str(row["value2"]))), "percent")
                    if code in (9000792, 9000793):
                        members = [u for u in team.values() if matches(u, "14", "all")]
                        if (direct, code) not in applied:
                            applied.add((direct, code))
                            for target in members:
                                # type2 的开场部分已按本行处理；此处只补足阵营限定。
                                if row["type"] != 2:
                                    add(target, "hp" if code == 9000792 else "def", value, "percent")
                        if len(members) <= 2:
                            add(provider, "hp" if code == 9000792 else "def", Fraction(str(row["value2"])), "percent")
                    continue
                if code in (9000400, 9000791, 9000583):
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
                elif code == 9000506 and (direct, code) not in applied:
                    applied.add((direct, code))
                    count = sum(matches(unit, "13", "all") for unit in team.values())
                    amount = min(value * count, Fraction(str(row["value2"])))
                    for target in team.values():
                        add(target, "atk", amount, "percent")
                elif code == 9000549:
                    add(provider, "ap", value)
                elif code == 9000550 and (direct, code) not in applied:
                    applied.add((direct, code))
                    for target in team.values():
                        if matches(target, "13", "all"):
                            add(target, "dmg", value)
                            add(target, "reduction", Fraction(str(row["value2"])))
                elif code in (9000746, 9000747, 9000551, 9000552, 9000682, 9000683):
                    group = 9000746 if code in (9000746, 9000747) else 9000551 if code in (9000551, 9000552) else 9000682
                    if (direct, group) in applied:
                        continue
                    applied.add((direct, group))
                    for target in team.values():
                        if config["general"][str(target["cid"])]["quality"] == 7:
                            add(target, "atk", Fraction(str(row["value2"])))
                elif row["id"] in GUANGCHENGZI_AURA_SKILLS and (direct, row["id"]) not in applied:
                    # 无限光波/能量防护：开场给己方彩金将加 value2 仙命，按技能行去重、两技能可叠加。
                    applied.add((direct, row["id"]))
                    for target in team.values():
                        if config["general"][str(target["cid"])]["quality"] == 7:
                            add(target, "hp", Fraction(str(row["value2"])))
                elif row["id"] in TAIYI_AURA_SKILLS and (direct, row["id"]) not in applied:
                    # 强心剂+/纳米科技：开场给己方彩金将加仙防。沿用广成子口径取 value2=32000
                    # （描述 320000 的 0.1 折算值），不取 value2_n=320000；按技能行去重、两技能叠加。
                    applied.add((direct, row["id"]))
                    for target in team.values():
                        if config["general"][str(target["cid"])]["quality"] == 7:
                            add(target, "def", Fraction(str(row["value2"])))
                elif code == 9000008:
                    add(provider, "reduction", value)
                elif code == 9000028 and provider.get("npc"):
                    add(provider, "parry", value)
                elif code == 9000489:
                    if 9000490 not in provider["effects"]:
                        add(provider, "dmg", value)
    for direct, team in teams.items():
        reduction = max((Fraction(str(u["effects"][9100006]["value"])) for u in team.values() if 9100006 in u["effects"]), default=0)
        tower = max((Fraction(str(u["effects"][9000761]["value"])) for u in team.values() if 9000761 in u["effects"]), default=0)
        for unit in team.values():
            unit["in_multiplier"] *= (1 - reduction) * (1 - tower)
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
            if 9000327 in unit["effects"]:
                unit.update(hp=1, absorbing=True)


def targets(actor, enemies, skill, rng):
    living = [u for _, u in sorted(enemies.items()) if u["hp"] > 0 and not u.get("hidden")]
    scope = skill["range"] if skill else "single"
    if scope == "single":
        taunters = [u for u in living if not skill and 9000476 in u.get("effects", {}) and u.get("taunt_active")]
        if taunters:
            living = taunters
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
    pending_hits = []
    round_actions = 0
    pvp = not any(u.get("npc") for team in teams.values() for u in team.values())
    combat_pets = {True: copy.deepcopy(attack_pet), False: copy.deepcopy(defense_pet)}
    for direct, team in teams.items():
        side = "attack" if direct else "defense"
        meta, initial = {}, {}
        for pos, unit in sorted(team.items()):
            general = config["general"][str(unit["cid"])]
            initial[str(pos)] = {"i": unit["iid"], "o": unit.get("boss", False)}
            meta[str(unit["iid"])] = {"i": unit["iid"], "c": unit["cid"], "n": unit.get("name", general["name"]),
                                      "level1": unit["level"], "level2": unit["advance"], "level3": unit.get("awakening", 0),
                                      "h": unit["hp"], "j": unit["maxhp"], "ap": unit["ap"], "d": {"i": unit["skill"]},
                                      **({key: unit[key] for key in ("cover_d", "cover_d2", "cover_p", "cover_l")} if unit["cover_d"] else {})}
            if unit.get("w_l"):
                meta[str(unit["iid"])].update(w_l=unit["w_l"], w_c=unit.get("w_c", 0))
            if unit.get("fei_sheng_level"):
                meta[str(unit["iid"])].update(fei_sheng_level=unit["fei_sheng_level"])
            if unit.get("artifact"):
                meta[str(unit["iid"])].update(a_cid=unit["artifact"]["cid"], a_level=unit["artifact"]["level"])
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

    def region(unit):
        return config["general"][str(unit["cid"])]["region"]

    def event(destinations, source=None):
        actions.append({"t": "b", "s": source or {}, "e": destinations})
        if len(actions) > 2000:
            raise ValueError("战斗事件超出上限，未结算")

    def trigger(unit, code, limit=1):
        key = (code, round_number)
        count = unit["trigger_counts"].get(key, 0)
        if count >= limit:
            return False
        unit["trigger_counts"][key] = count + 1
        return True

    def immune(unit):
        return (unit["states"].get("statusproof", 0) > round_number
                or 9000499 in unit["effects"] and unit["ap"] >= 4)

    def passive_event(unit, code, changes):
        row = unit["effects"].get(code)
        if changes:
            # 原包缺元始之气资源；保命不需要复活模型，使用已有无敌状态显示。
            event(changes, {"r": unit["direct"], "p": [unit["pos"]], "t": "break", "S": row["id"]}
                  if row and row["animationid"] and code != 9000444 else None)

    def passive_buff(unit, provider, code, attr, amount, duration):
        unit["passive_buffs"][provider["iid"], code, attr] = (amount, round_number + duration)
        return dest(unit, B={"R": attr, "u": "promote" if amount >= 0 else "weaken", "w": True})

    def invincible_display(unit):
        return (unit["states"].get("invincible", 0) > round_number
                or unit.get("artifact_barrier", 0) and round_number < 2
                or unit.get("attack_immunity", 0) and unit["attack_immunity_until"] > round_number)

    def change_hp(unit, amount, status="N", hits=0, *, shield=True, healing=False, healer=None, unsealed=False, bypass_barrier=False, kind="other", revival=False, attacker=None, reaction=False):
        unit["last_heal_absorbed"] = 0
        blocked_heal = (healing and unit["states"].get("close", 0) > round_number and not unsealed
                        or 9000315 in unit["effects"] and unit["hp"] < unit["maxhp"] * effect(unit, 9000315)
                        or unit.get("last_stand_until", 0) > round_number)
        if amount < 0 and healing and healer:
            multiplier = 1 + effect(healer, 9000425) * ((unit["maxhp"] - unit["hp"]) * 10 // unit["maxhp"])
            if 9999991 in healer["effects"]:
                multiplier *= Fraction(6, 5)
            amount = -int(-amount * multiplier)
        if amount < 0:
            amount = -int(-amount * (1 + unit.get("soul_effects", {}).get("heal", 0)))
        excess = max(0, -amount - (unit["maxhp"] - unit["hp"]))
        if amount < 0 and blocked_heal and not revival:
            excess, amount = -amount, 0
        if healing and healer and effect(healer, 9000776) and excess:
            gained = int(excess * effect(healer, 9000776))
            if gained:
                unit["heal_shield"] += gained
                event([state_event(unit, "shield", True)])
        if amount > 0:
            missing = (unit["maxhp"] - unit["hp"]) * 10 // unit["maxhp"]
            multiplier = max(0, 1 - effect(unit, 9000022) * missing)
            if kind == "basic":
                multiplier *= max(0, 1 - min(1 if pvp else Fraction(2, 5), effect(unit, 9000504) * missing))
            if amount * 10 > unit["maxhp"] * 3:
                multiplier *= 1 - effect(unit, 9000469)
            multiplier *= max(0, 1 - effect(unit, 9000778) * round_actions)
            multiplier *= max(0, 1 - unit["ap_self_guard"]) * max(0, 1 - unit["ap_received_guard"])
            multiplier *= 1 - unit["fire_seeds"] * Fraction(2, 25)
            if unit["states"].get("qianlong", 0) > round_number:
                multiplier *= 1 - effect(unit, 9000795, "value2")
            if unit["heal_shield"] and any(9000776 in u["effects"] for u in teams[unit["direct"]].values()):
                multiplier *= 1 - max(effect(u, 9000776, "value2") for u in teams[unit["direct"]].values())
            amount = max(0, int(amount * multiplier))
        if amount > 0 and (unit["states"].get("invincible", 0) > round_number or unit.get("last_stand_until", 0) > round_number
                           or kind == "skill" and 9000315 in unit["effects"] and unit["hp"] < unit["maxhp"] * effect(unit, 9000315)
                           or kind == "basic" and 9000316 in unit["effects"] and unit["hp"] < unit["maxhp"] * effect(unit, 9000316, "value2")):
            amount, status = 0, "proof"
        barrier_end = False
        if (amount > 0 and kind in ("basic", "skill", "pet") and not bypass_barrier
                and unit.get("attack_immunity", 0) and unit["attack_immunity_until"] > round_number):
            amount, status = 0, "proof"
            unit["attack_immunity"] -= 1
            barrier_end = not unit["attack_immunity"]
        if amount > 0 and kind in ("basic", "skill") and not bypass_barrier and unit.get("guard_marks", 0):
            # 能量防护：守护印记免疫 1 次受到的攻击；印记可叠加，额外伤害不消耗。
            unit["guard_marks"] -= 1
            amount, status = 0, "proof"
        if amount > 0 and unit.get("artifact_barrier", 0) and round_number < 2 and not bypass_barrier:
            amount, status = 0, "proof"
            unit["artifact_barrier"] -= 1
            barrier_end = unit["artifact_barrier"] == 0
        if amount > 0 and unit.get("absorbing"):
            amount, status = -min(amount, unit["maxhp"] - unit["hp"]), "N"
        if amount > 0 and unit["heal_shield"] and shield:
            absorbed = min(amount, unit["heal_shield"])
            unit["last_heal_absorbed"] = absorbed
            unit["heal_shield"] -= absorbed
            amount -= absorbed
            if not amount:
                status = "proof"
            if not unit["heal_shield"]:
                event([state_event(unit, "shield", False)])
        absorbed = min(unit["cover_d"], int(max(0, amount) * Fraction(unit.get("cover_p", 0), 100))) if shield else 0
        unit["cover_d"] -= absorbed
        amount -= absorbed
        amount = max(- (unit["maxhp"] - unit["hp"]), min(unit["hp"], amount))
        if (amount == unit["hp"] and amount > 0 and 9000444 in unit["effects"] and not unit.get("last_stand")):
            unit["last_stand"] = True
            unit["last_stand_until"] = round_number + 1 + int(effect(unit, 9000551))
            amount = unit["hp"] - 1
            # 先发本次扣血，再在伤害后发布保命状态和绝对怒气。
            unit["last_stand_pending"] = True
        if healing and healer and amount < 0 and TAIYI_HEAL_SHARING in healer["effects"]:
            # 强心剂+：记录被太乙真人恢复的最大单次生命值，供该角色的后续伤害加成使用。
            unit["taiyi_heal_bonus"] = max(unit.get("taiyi_heal_bonus", 0), -amount)
            unit["taiyi_heal_row"] = healer["effects"][TAIYI_HEAL_SHARING]
        previous = unit["hp"]
        unit["hp"] -= amount
        if attacker is not None and amount + absorbed + unit["last_heal_absorbed"] > 0:
            unit["received_hits"] += 1
            pending_hits.append((unit, attacker, kind, reaction))
        if unit.get("absorbing") and unit["hp"] == unit["maxhp"]:
            unit["absorbing"] = False
        if unit["hp"] == 0:
            status = "dead" if status == "N" else status + "dead" if status not in ("C",) else "C"
            report["dead_log"][str(unit["direct"]).lower()][str(unit["cid"])] = round_number
            if previous:
                unit["killed_by"] = (attacker.get("direct"), attacker.get("pos")) if attacker else None
                pending_deaths.append(unit)
        return dest(unit, m={"m": amount, "f": 0, "u": status, "U": hits, **({"M": absorbed} if absorbed else {})},
                    **({"u": {"u": "invincible", "w": False}} if barrier_end and not invincible_display(unit) else {}))

    def damage_hp(unit):
        return unit["maxhp"] if unit.get("absorbing") else unit["hp"] + unit["cover_d"] + unit["heal_shield"]

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
        value += sum(amount for (_, _, attr), (amount, until) in unit["passive_buffs"].items() if attr == name and until > round_number)
        allies, enemies = teams[unit["direct"]], teams[not unit["direct"]]
        alive = living(allies) + living(enemies)
        if name == "atk":
            extra = effect(unit, 9000403) * sum(u["hp"] <= 0 for t in teams.values() for u in t.values())
            extra += effect(unit, 9000486) * len(alive)
            extra += effect(unit, 9000771) * len(alive) + effect(unit, 9000771, "value2") * sum(region(u) == "14" for u in living(allies))
            extra += max((effect(u, 9000498) for u in living(allies) if region(unit) == "9"), default=0)
            # 天神威：每名存活天属性（scope1）友方含自身加 value 攻击，上限 value2。
            extra += min(effect(unit, 9000521, "value2"),
                         effect(unit, 9000521) * sum(u.get("gold_camp") == 1 for u in living(allies)))
            value += unit["atk"] * extra
        if name in ("critical", "criticaldmg"):
            value += max((effect(u, 9000584) if name == "critical" else effect(u, 9000584, "value2") * 100 for u in living(allies)), default=0)
        if name in ("def", "resilience") and any(9000413 in u["effects"] and u["hp"] > 0 for u in teams[unit["direct"]].values()):
            value += unit["def"] * Fraction(1, 5) if name == "def" else 10
        result = int(value) + unit.get("pet_rates", {}).get(name, 0)
        if name in ("atk", "def") and unit.get("curse_marks", 0) and unit.get("curse_marks_until", 0) > round_number:
            result = int(result * (1 - (CURSE_ATTACK if name == "atk" else CURSE_DEFENSE)))
        return result if name in ("hit", "criticaldmg") else max(0, result)

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
        if duration <= unit["dizzy"] or unit["states"].get("xiyin", 0) > round_number or immune(unit):
            return False
        unit["dizzy"] = duration
        return True

    def status_damage(unit, kind, amount, duration, provider=None):
        duration -= int(effect(unit, 9000789))
        if duration <= 0:
            return None
        unit[kind] = [max(1, amount), duration]
        if kind == "firing" and provider and provider["hp"] > 0 and effect(provider, 9000806):
            key = (provider["iid"], 9000806, "atk")
            previous = unit["passive_buffs"].get(key, (0, 0))[0]
            value = max(-unit["atk"] * effect(provider, 9000806, "value2"), previous - unit["atk"] * effect(provider, 9000806))
            event([passive_buff(unit, provider, 9000806, "atk", value, MAX_ROUNDS + 1)])
        return dest(unit, m=[], u={"u": kind, "w": True})

    def cleanse(unit):
        changes = []
        for kind in ("dizzy", "dot", "firing"):
            if unit[kind]:
                unit[kind] = False if kind == "dizzy" else None
                changes.append(dest(unit, m=[], u={"u": kind, "w": False}))
        for kind in ("skilllock", "fire", "close"):
            if kind in unit["states"]:
                del unit["states"][kind]
                changes.append(state_event(unit, kind, False))
        for kind, attr in list(unit["buffs"]):
            if kind == "weaken":
                del unit["buffs"][kind, attr]
                changes.append(dest(unit, B={"R": attr, "u": kind, "w": False}))
        for key, (amount, _) in list(unit["passive_buffs"].items()):
            if amount < 0:
                del unit["passive_buffs"][key]
                changes.append(dest(unit, B={"R": key[2], "u": "weaken", "w": False}))
        return changes

    def kill_recovery(actor, killed):
        if actor["hp"] > 0 and killed and effect(actor, 9000038):
            event([change_hp(actor, -int(actor["maxhp"] * effect(actor, 9000038) * killed))])
        if killed and region(actor) == "13":
            for provider in living(teams[actor["direct"]]):
                if 9000742 in provider["effects"]:
                    provider["chan_kill_damage"] = provider.get("chan_kill_damage", 0)+effect(provider, 9000742)*killed
                    passive_event(provider, 9000742, [change_ap(u, killed, provider=provider) for u in living(teams[actor["direct"]]) if u is not actor])

    def modifiers(actor, target):
        multiplier = actor["out_multiplier"] * target["in_multiplier"]
        if actor.get("gold_camp") and target.get("gold_camp"):
            camp = config["jinjiangkezhiguanxi"][str(actor["gold_camp"]*100)]
            if target["gold_camp"] == camp["restraint_camp"]:
                multiplier *= 1 + Fraction(str(camp["restraint_attribute"]))
            elif target["gold_camp"] == camp["be_restrained_camp"]:
                multiplier *= 1 - Fraction(str(camp["be_restrained_attribute"]))
        if actor["strikes"] == 0:
            multiplier *= 1 + effect(actor, 9000029)
        if target["hp"] < actor["hp"]:
            multiplier *= 1 + effect(actor, 9000032)
        if target["hp"] > actor["hp"]:
            multiplier *= 1 + effect(actor, 9000037)
        for name, eligible in (("蔑视", stat(actor, "atk") > stat(target, "atk")), ("无畏", stat(actor, "atk") < stat(target, "atk"))):
            if eligible and name in actor["artifact_effects"]:
                multiplier *= 1 + Fraction(str(actor["artifact_effects"][name]["value"]))
        multiplier *= 1 + effect(actor, 9000429) * (target["hp"] * 10 // target["maxhp"])
        multiplier *= 1 + effect(actor, 9000430) * ((target["maxhp"] - target["hp"]) * 10 // target["maxhp"])
        if target["ap"] <= 2:
            multiplier *= 1 + effect(actor, 9000036)
        if target["firing"]:
            multiplier *= 1 + (effect(actor, 9000490, "value2") if 9000490 in actor["effects"] else effect(actor, 9000489))
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
        if target["hp"] * 2 > target["maxhp"]:
            multiplier *= 1 + effect(actor, 9000314)
            if 9000470 in actor["effects"]:
                multiplier *= Fraction(3, 2)
        elif target["hp"] * 2 < target["maxhp"] and 9000470 in actor["effects"]:
            multiplier *= Fraction(5, 2)
        multiplier *= 1 + effect(actor, 9000318) * (target["hp"] * 20 // target["maxhp"])
        multiplier *= 1 + min(Fraction(3, 2), effect(actor, 9000471) * ((target["maxhp"] - target["hp"]) * 20 // target["maxhp"]))
        multiplier *= 1 + effect(actor, 9000468) * len(living(teams[actor["direct"]]))
        multiplier *= 1 + effect(actor, 9000472, "value2") * len(living(teams[not actor["direct"]]))
        multiplier *= 1 + effect(actor, 9000479) * sum(region(u) == "13" for u in living(teams[actor["direct"]]))
        multiplier *= 1 + min(effect(actor, 9000484, "value2"), effect(actor, 9000484) * sum(region(u) == "9" for u in teams[actor["direct"]].values()))
        multiplier *= 1 + effect(actor, 9000485, "value2") * sum(region(u) in ("6", "7", "8", "9") and config["general"][str(u["cid"])]["sex"] == "nan" and not 10101 <= u["cid"] <= 10115 for u in teams[not actor["direct"]].values())
        if config["general"][str(target["cid"])]["sex"] == "nan" and region(target) in ("6", "7", "8", "9"):
            multiplier *= 1 + effect(actor, 9000497)
        dead = sum(u["hp"] <= 0 for team in teams.values() for u in team.values())
        multiplier *= 1 + (effect(actor, 9000431) + effect(actor, 9000488)) * dead
        multiplier *= 1 + actor.get("ramp_damage", 0) + actor.get("cast_damage", 0) + actor.get("kill_damage", 0)
        multiplier *= 1 + actor["fire_seeds"] * Fraction(2, 25)
        providers = list(teams[actor["direct"]].values())
        multiplier *= 1 + max((u.get("living_damage", 0) for u in providers if u["hp"] > 0), default=0)
        multiplier *= 1 + max((u.get("team_ramp", 0) for u in providers if u["hp"] > 0), default=0)
        multiplier *= 1 + max((u.get("ancient_damage", 0) * (1 if u["hp"] > 0 else Fraction(1, 2)) for u in providers), default=0)
        multiplier *= 1 + actor.get("tower_damage", 0)
        multiplier *= 1 + actor.get("chan_attack_damage", 0)
        multiplier *= 1 + actor.get("enemy_death_damage", 0)
        if round_number == 1:
            multiplier *= 1 + effect(actor, 9000549, "value2")
        if actor.get("photon_target") == (target["pos"], target["iid"]):
            multiplier *= 1 + effect(actor, 9000547)
        if actor.get("sword_marks", {}).get((target["pos"], target["iid"]), 0) > round_number:
            multiplier *= 1 + effect(actor, 9000678)
        if target.get("sword_marks", {}).get((actor["pos"], actor["iid"]), 0) > round_number:
            multiplier *= 1 - effect(target, 9000678, "value2")
        if 9000743 in actor["effects"] and len(living(teams[not actor["direct"]])) <= effect(actor, 9000743):
            multiplier *= 1 + effect(actor, 9000743, "value2")
        if region(actor) == "13" and target.get("qi_until", 0) > round_number:
            multiplier *= 1 + max((effect(u, 9000746) for u in living(teams[actor["direct"]])), default=0)
        if region(target) == "13" and actor.get("qi_until", 0) > round_number:
            multiplier *= 1 - max((effect(u, 9000746) for u in living(teams[target["direct"]])), default=0)
        if target["dizzy"] or target["dot"] or target["firing"] or any(target["states"].get(k, 0) > round_number for k in ("skilllock", "close", "fire")):
            multiplier *= 1 + effect(actor, 9000480)
        if target.get("curse_marks", 0) and target.get("curse_marks_until", 0) > round_number:
            multiplier *= 1 + CURSE_DAMAGE
        if target["cover_d"] > 0:
            multiplier *= 1 + effect(actor, 9000421)
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
        amount = damage({**actor, "atk": max(1, stat(actor, "atk"))},
                        {**target, "def": stat(target, "def"), "hp": damage_hp(target)}, config,
                        multiplier=coefficient * multiplier, flat=flat, final_multiplier=final, clip=False) if coefficient else int(max(0, int(fixed * multiplier) + flat) * final)
        return change_hp(target, amount, bypass_barrier=True, attacker=actor)

    def last_stands():
        for team in teams.values():
            for unit in team.values():
                if unit.pop("last_stand_pending", False):
                    passive_event(unit, 9000444, [change_ap(unit, int(effect(unit, 9000444)) - unit["ap"]),
                                                *set_state(unit, "invincible", unit["last_stand_until"]-round_number)])

    def hurt_reactions():
        while pending_hits:
            target, attacker, kind, reaction = pending_hits.pop(0)
            if target["hp"] <= 0:
                continue
            if 9000439 in target["effects"]:
                value = min(Fraction(7, 20), effect(target, 9000439) * target["received_hits"])
                event([passive_buff(target, target, 9000439, "def", target["def"] * value, MAX_ROUNDS + 1)])
            if kind == "basic" and not reaction and 9000426 in target["effects"]:
                event([change_ap(attacker, -rng.choices((2, 4), weights=(60, 40))[0])])
            # 冷静护甲：受普通攻击时按 value 概率减怒气最高的敌人 value2 点怒气，每回合最多2次。
            if (kind == "basic" and not reaction and 9000518 in target["effects"]
                    and roll(effect(target, 9000518)) and trigger(target, 9000518, 2)):
                rivals = [u for u in living(teams[not target["direct"]]) if not u["hidden"]]
                if rivals:
                    top = max(rivals, key=lambda u: (u["ap"], -u["pos"]))
                    passive_event(target, 9000518, [change_ap(top, -int(effect(target, 9000518, "value2")), provider=target)])
            if 9000606 in target["effects"]:
                ally = min(living(teams[target["direct"]]), key=lambda u: (u["ap"], u["pos"]))
                passive_event(target, 9000606, [change_ap(ally, int(effect(target, 9000606, "value2")), provider=target)])
            if target["states"].get("qianlong", 0) > round_number:
                target["hidden"] = True
                passive_event(target, 9000795, [*cleanse(target), *set_state(target, "hide")])

    def deaths():
        last_stands()
        while pending_deaths or pending_hits:
            hurt_reactions()
            last_stands()
            if not pending_deaths:
                break
            unit = pending_deaths.pop(0)
            killer = unit.pop("killed_by", None)
            if unit["hp"] > 0:
                continue
            if unit["heal_shield"]:
                unit["heal_shield"] = 0
                event([state_event(unit, "shield", False)])
            if (9000747 in unit["effects"] and not unit.get("gold_revived")
                    and len(living(teams[unit["direct"]])) >= 4):
                unit["gold_revived"] = True
                revive(unit, unit, 9000747, 1, ap=unit["ap"])
                continue
            if 9000441 in unit["effects"] and not unit.get("self_revived"):
                unit["self_revived"] = True
                revive(unit, unit, 9000441, 1, ap=int(effect(unit, 9000441)))
                continue
            if (9000328 in unit["effects"] and unit.get("revives", 0) < 2
                    and any(u is not unit and u["hp"] > 0 for u in teams[unit["direct"]].values())):
                unit["revives"] = unit.get("revives", 0) + 1
                unit["def"] //= 2
                event([change_hp(unit, -max(1, unit["maxhp"] // 2), revival=True), dest(unit, B={"R": "def", "u": "weaken", "w": True})],
                      {"r": unit["direct"], "p": [unit["pos"]], "t": "break", "S": 9000328})
                continue
            friends = teams[unit["direct"]]
            for provider in living(teams[not unit["direct"]]):
                if 9000548 in provider["effects"]:
                    provider["enemy_death_damage"] = provider.get("enemy_death_damage", 0) + effect(provider, 9000548, "value2")
                    passive_event(provider, 9000548, [change_ap(provider, int(effect(provider, 9000548)))])
                if killer != (provider["direct"], provider["pos"]):
                    continue
                if provider.get("photon_target") == (unit["pos"], unit["iid"]):
                    candidates = [u for u in living(teams[unit["direct"]]) if not u["hidden"]]
                    target = rng.choice(candidates) if candidates else None
                    provider["photon_target"] = (target["pos"], target["iid"]) if target else None
                    if target:
                        passive_event(provider, 9000547, [dest(target, m={"m": 0, "f": 0, "u": "N", "U": 0})])
                if 9000681 in provider["effects"] and trigger(provider, 9000681):
                    provider["sacrifice_pending"] = True
            for other in [u for team in teams.values() for u in team.values()]:
                for key in list(other["passive_buffs"]):
                    if key[1] == 9000806 and (key[0] == unit["iid"] or other is unit):
                        del other["passive_buffs"][key]
                        event([dest(other, B={"R": "atk", "u": "weaken", "w": False})])
            if unit["fire_seeds"]:
                candidates = living(friends)
                if candidates:
                    target = min(candidates, key=lambda u: (u["fire_seeds"], u["pos"]))
                    target["fire_seeds"] = min(7, target["fire_seeds"] + unit["fire_seeds"])
                    event([dest(target, B={"R": "atk", "u": "promote", "w": True})])
                unit["fire_seeds"] = 0
            for code in (9000586, 9000762):
                if code not in unit["effects"] or unit.get(("death_used", code)):
                    continue
                unit["death_used", code] = True
                if code == 9000762:
                    event([change for ally in living(friends) for change in cleanse(ally)])
                corpses = [u for _, u in sorted(friends.items()) if u is not unit and u["hp"] <= 0 and (code != 9000586 or region(u) == "7")]
                if code == 9000762:
                    corpses = sorted(rng.sample(corpses, min(len(corpses), int(effect(unit, code)))), key=lambda u: u["pos"])
                for target in corpses:
                    revive(unit, target, code, effect(unit, code) if code == 9000586 else 1, ap=4 if code == 9000762 else None)
            if 9000306 in unit["effects"]:
                passive_event(unit, 9000306, [passive_buff(u, unit, 9000306, "atk", u["atk"] * effect(unit, 9000306), 1) for u in living(friends)])
            if 9000034 in unit["effects"]:
                multiplier = 1 + (Fraction(3, 10) + unit["received_hits"] * Fraction(3, 20) if 9000323 in unit["effects"] else 0)
                passive_event(unit, 9000034, [extra_hit(unit, u, effect(unit, 9000034) * multiplier, explosion=True) for u in living(teams[not unit["direct"]])])
            if 9000493 in unit["effects"]:
                event([change for u in living(teams[not unit["direct"]]) if (change := ignite(unit, u))])
            for code in (9000414, 9000432, 9000438, 9000495):
                if code not in unit["effects"]:
                    continue
                allies = living(friends)
                if code == 9000414:
                    allies = [u for u in allies if region(u) == "8"]
                    allies = sorted(rng.sample(allies, min(2, len(allies))), key=lambda u: u["pos"])
                elif code == 9000438:
                    allies = sorted(allies, key=lambda u: (Fraction(u["hp"], u["maxhp"]), u["pos"]))[:1]
                elif code == 9000495:
                    allies = [u for u in allies if region(u) == "9"]
                changes = []
                for target in allies:
                    fraction = Fraction(1, 2) if code == 9000414 else Fraction(3, 10) if code == 9000495 or code == 9000432 and region(target) != "8" else 1
                    changes.append(change_hp(target, -int(target["maxhp"] * fraction), healing=True, healer=unit))
                    if code != 9000432:
                        changes.append(change_ap(target, (4 - target["ap"]) if code == 9000414 else 2, provider=unit))
                passive_event(unit, code, changes)
            # 地祇佑：死亡时为随机3个己方地属性（scope2）角色恢复 value 生命和 value2 点怒气。
            if 9000522 in unit["effects"]:
                allies = [u for u in living(friends) if u.get("gold_camp") == 2]
                allies = sorted(rng.sample(allies, min(3, len(allies))), key=lambda u: u["pos"])
                changes = []
                for target in allies:
                    changes.append(change_hp(target, -int(target["maxhp"] * effect(unit, 9000522)), healing=True, healer=unit))
                    changes.append(change_ap(target, int(effect(unit, 9000522, "value2")), provider=unit))
                passive_event(unit, 9000522, changes)
            for team in teams.values():
                for provider in living(team):
                    if provider is not unit and 9000482 in provider["effects"] and trigger(provider, 9000482, 2):
                        target = min(living(team), key=lambda u: (Fraction(u["hp"], u["maxhp"]), u["pos"]))
                        changes = cleanse(target)
                        changes.extend((change_hp(target, -target["maxhp"], healing=True, healer=provider), change_ap(target, 4 - target["ap"], provider=provider)))
                        passive_event(provider, 9000482, changes)
            for provider in teams[unit["direct"]].values():
                if provider["hp"] > 0 and 9100003 in provider["effects"]:
                    event([dest(provider, B={"R": "atk", "u": "promote", "w": True})])
            if effect(unit, 9000027):
                friends = sorted((u for u in teams[unit["direct"]].values() if u["hp"] > 0), key=lambda u: (u["hp"], u["pos"]))
                if friends:
                    event([change_hp(friends[0], -int(stat(unit, "atk") * effect(unit, 9000027)), healing=True, healer=unit)])
            if effect(unit, 9000040):
                selected = targets(unit, teams[not unit["direct"]], None, rng)
                if selected:
                    target = selected[0]
                    event([extra_hit(unit, target, effect(unit, 9000040), explosion=True)])
        last_stands()

    def living(team):
        return [u for _, u in sorted(team.items()) if u["hp"] > 0]

    def revive(provider, unit, code, fraction, ap=None, hidden=False):
        changes = cleanse(unit)
        changes.append(change_hp(unit, -max(1, int(unit["maxhp"] * fraction)), revival=True))
        if ap is not None:
            changes.append(change_ap(unit, ap - unit["ap"]))
        unit["hidden"] = hidden
        if hidden:
            unit["states"]["hide"] = round_number + 1
            changes.append(state_event(unit, "hide", True))
        unit["living_damage"] = effect(unit, 9000442)
        unit["team_ramp"] = 0
        if 9000747 in unit["effects"]:
            amount = min(unit["cover_d2"]-unit["cover_d"], int(unit["cover_d2"]*effect(unit, 9000747)))
            if amount > 0:
                unit["cover_d"] += amount
                changes.append(dest(unit, m={"m": 0, "M": -amount, "f": 0, "u": "N", "U": 0}))
        passive_event(provider, code, changes)

    def ignite(provider, unit):
        amount = damage({**provider, "atk": max(1, stat(provider, "atk"))}, {**unit, "def": stat(unit, "def"), "hp": (1 << 63) - 1}, config) // 10
        return status_damage(unit, "firing", amount, 2, provider)

    def queen_recovery(target):
        provider = next((u for _, u in sorted(teams[target["direct"]].items()) if u["cid"] in QUEENS and u["hp"] > 0), None)
        return ((stat(provider, "atk") * 12 + provider["maxhp"] * 4) // 100 if provider else 0), provider

    def state_event(unit, kind, enabled):
        if kind in ("xiyin", "fire"):
            return dest(unit, B={"R": kind, "u": "promote" if kind == "xiyin" else "break", "w": enabled})
        return dest(unit, m=[], u={"u": kind, "w": enabled})

    def set_state(unit, kind, duration=1):
        if kind in ("skilllock", "close"):
            if kind == "skilllock" and immune(unit):
                return []
            duration -= int(effect(unit, 9000789))
        if duration <= 0:
            return []
        unit["states"][kind] = max(unit["states"].get(kind, 0), round_number + duration)
        return [state_event(unit, kind, True)]

    def change_ap(unit, amount, provider=None, *, pet=False, supply=True):
        if amount < 0 and immune(unit) and not pet:
            amount = 0
        previous = unit["ap"]
        unit["ap"] = max(0, min(10, unit["ap"] + amount))
        gained = unit["ap"] - previous
        if gained < 0 and not pet:
            # 磁场/过热：广成子所在一方每次实际降低敌方怒气时，按本行给目标减攻并追加生命上限伤害。
            for source in living(teams[not unit["direct"]]):
                if source["hp"] <= 0:
                    continue
                if 9000691 in source["effects"]:
                    changes = [passive_buff(unit, source, 9000691, "atk",
                                            -stat(unit, "atk") * effect(source, 9000691),
                                            int(effect(source, 9000691, "value2")) + 1)]
                    passive_event(source, 9000691, changes)
                if 9000690 in source["effects"]:
                    changes = [change_hp(unit, int(source["maxhp"] * -gained * effect(source, 9000690)),
                                         bypass_barrier=True, attacker=source)]
                    passive_event(source, 9000690, changes)
        if gained > 0 and provider and provider is not unit and 9000785 in provider["effects"]:
            provider["ap_self_guard"] = min(Fraction(4, 5), provider["ap_self_guard"] + effect(provider, 9000785) * gained)
            unit["ap_received_guard"] = min(Fraction(9, 20), unit["ap_received_guard"] + Fraction(3, 20) * gained)
        if (gained > 0 and supply and 9000600 in unit["effects"] and unit["hp"] > 0
                and previous < effect(unit, 9000600) <= unit["ap"]):
            # 过量补给：自身怒气从 <value 跨到 >=value 时，给己方怒气最低的其他角色 +value2 怒。
            # 递归传 supply=False 避免同队多名携带者连锁放大。
            allies = [u for u in living(teams[unit["direct"]]) if u is not unit]
            if allies:
                lowest = min(allies, key=lambda u: (u["ap"], u["pos"]))
                granted = int(effect(unit, 9000600, "value2"))
                if granted:
                    # 不新增 break 动画源：原包该族资源是否可用未确认，只发怒气状态变更。
                    event([change_ap(lowest, granted, provider=unit, supply=False)])
        if unit["ap"] >= 4 and 9000499 in unit["effects"]:
            changes = []
            if unit["dizzy"]:
                unit["dizzy"] = False
                changes.append(dest(unit, m=[], u={"u": "dizzy", "w": False}))
            if unit["states"].pop("skilllock", None):
                changes.append(state_event(unit, "skilllock", False))
            if changes:
                event(changes)
        return dest(unit, ap=unit["ap"], E=True)

    def artifact_trigger(unit, name, *, certain=False):
        row = unit["artifact_effects"].get(name)
        if (unit["hp"] <= 0 or not row or unit["artifact_used"].get(name) == round_number
                or not certain and not roll(Fraction(str(row["value"])) )):
            return None
        unit["artifact_used"][name] = round_number
        return row

    def artifact_event(unit, row, changes):
        if changes:
            event(changes, None if unit["dizzy"] or not row["animationid"] else
                  {"r": unit["direct"], "p": [unit["pos"]], "t": "break", "S": row["id"]})

    def artifact_after(actor, skill, hits, killed, reaction, followup):
        enemies = teams[not actor["direct"]]
        survivors = [u for u in hits if u["hp"] > 0]
        if not skill and hits:
            row = artifact_trigger(actor, "贪婪")
            if row:
                artifact_event(actor, row, [change_ap(actor, 2)])
            if survivors:
                row = artifact_trigger(actor, "怒损")
                if row:
                    artifact_event(actor, row, [change_ap(survivors[0], -2)])
            for target in survivors:
                for name in ("狂躁", "鼓舞"):
                    row = artifact_trigger(target, name)
                    if row:
                        ally = target if name == "狂躁" else min(living(enemies), key=lambda u: (u["ap"], u["pos"]))
                        artifact_event(target, row, [change_ap(ally, 2)])
        if skill and not reaction and not followup:
            for name in ("狂怒", "怒蚀", "扼制", "侵蚀", "腐蚀", "滋养", "救赎"):
                candidates = living(enemies) if name in ("怒蚀", "扼制") else survivors
                if name in ("侵蚀", "腐蚀") and (skill["kind"] != "attack" or not candidates):
                    continue
                if name in ("怒蚀", "扼制") and not candidates:
                    continue
                row = artifact_trigger(actor, name, certain=name in ("滋养", "救赎"))
                if not row:
                    continue
                changes = []
                if name == "狂怒":
                    changes = [change_ap(actor, 2)]
                elif name == "怒蚀":
                    changes = [change_ap(min(candidates, key=lambda u: (-stat(u, "atk"), u["pos"])), -2)]
                elif name == "扼制":
                    for target in sorted(rng.sample(candidates, min(len(candidates), rng.randint(1, 2))), key=lambda u: u["pos"]):
                        changes.extend(set_state(target, "skilllock"))
                elif name in ("侵蚀", "腐蚀"):
                    for target in candidates:
                        change = buff(target, {"effect": "weaken", "effect-param": "atk;0.25" if name == "侵蚀" else "def;0.5", "effect-round": 2})
                        if change:
                            changes.append(change)
                elif name in ("滋养", "救赎"):
                    amount = int((stat(actor, "atk") if name == "滋养" else actor["maxhp"]) * Fraction(str(row["value"])))
                    changes = [change_hp(actor, -amount, healing=True, unsealed=True)]
                    if name == "滋养":
                        actor["artifact_regen"] = (int(stat(actor, "atk") * Fraction(str(row["value2"]))), round_number, row)
                artifact_event(actor, row, changes)
        if killed:
            row = artifact_trigger(actor, "嗜战")
            if row:
                artifact_event(actor, row, [change_ap(actor, 2)])
        if not reaction and actor["hp"] > 0 and not actor["dizzy"] and not finished():
            name = "连击" if not skill and hits else "残暴" if killed else None
            row = artifact_trigger(actor, name) if name else None
            if row:
                # 额外普攻不借当前怒气改成技能，不再衍生反击或连锁追击。
                selected = targets(actor, enemies, None, rng)
                if selected:
                    act(actor, selected[0], reaction=True)
            if killed and name != "残暴":
                row = artifact_trigger(actor, "残暴")
                if row and not finished():
                    selected = targets(actor, enemies, None, rng)
                    if selected:
                        act(actor, selected[0], reaction=True)

    def choose_combo(actor, friends, enemies):
        # 前线机型：自身处于前排（阵位 < 8）时无法使用合体技能。
        if 9000599 in actor["effects"] and actor["pos"] < 8:
            return None
        general = config["general"][str(actor["cid"])]
        skill = config["combskill"].get(str(general["combskillid"]))
        if not skill:
            return None
        if not skill["cid2"]:
            # 本地规则：只有彩金主角（quality7的lead）使用无伙伴位的单人合体技，
            # 其他武将的同类配置维持不发动，避免改变既有战斗。
            if general.get("actor") != "lead" or general["quality"] < 7:
                return None
            if actor["ap"] < skill["ap"]:
                return None
            chance = config["combskillprobability"][str(skill["id"])][f"bout{min(10, round_number)}"]
            chance += effect(actor, 9000520)  # 心有灵犀：合体技能几率提升 value。
            if 9000599 in actor["effects"]:
                chance *= Fraction(1, 2)  # 前线机型：合体技能概率降低一半（按描述；value2=0.2 未采用）。
            return (skill, [actor["pos"]]) if roll(chance) else None
        if skill["id"] not in MULTI_COMBOS:
            raise ValueError(f"尚不支持该合体技能 {skill['id']}")
        free_combo = actor.get("free_combo", False)
        if actor["ap"] < skill["ap"] and not free_combo:
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
                            and not u["hidden"] and not u["dizzy"] and u["states"].get("skilllock", 0) <= round_number), None)
            if partner is None:
                if (cid in cheer_ids[actor["direct"]]
                        and not any((config["general"][str(u["cid"])]["init_cid"] or u["cid"]) == cid for u in friends.values())):
                    continue
                return None
            participants.append(partner["pos"])
        candidates = [u for u in living(friends if skill["kind"] == "gain" else enemies) if not u["hidden"]]
        if skill["range"] == "second":
            candidates = [u for u in candidates if u["pos"] > 7]
        chance = config["combskillprobability"][str(skill["id"])][f"bout{min(10, round_number)}"]
        if free_combo:
            chance = effect(actor, 9000424)
        elif 9000422 in actor["effects"]:
            chance = 1 if actor.pop("certain_combo", False) else max(chance, effect(actor, 9000422))
        if round_number <= actor.get("chan_combo_until", 0):
            chance = 1
        chance += effect(actor, 9000520)  # 心有灵犀：合体技能几率提升 value。
        if 9000599 in actor["effects"]:
            chance *= Fraction(1, 2)  # 前线机型：合体技能概率降低一半（按描述；value2=0.2 未采用）。
        return (skill, participants) if candidates and roll(chance) else None

    def passive_after(actor, skill, combined, hits, slain, reaction, base_skill):
        friends, enemies = teams[actor["direct"]], teams[not actor["direct"]]
        killed = sum(u["hp"] <= 0 for u in slain)
        if killed:
            actor["kill_damage"] = actor.get("kill_damage", 0) + effect(actor, 9000420) * killed
            if 9000440 in actor["effects"]:
                for _ in range(killed):
                    if trigger(actor, 9000440, 2) and actor["hp"] > 0:
                        event([change_hp(actor, -int(actor["maxhp"] * effect(actor, 9000440)), healing=True, healer=actor), change_ap(actor, 2)])
            if region(actor) == "7":
                for provider in living(friends):
                    if 9000585 in provider["effects"] and trigger(provider, 9000585):
                        passive_event(provider, 9000585, [change_hp(provider, -int(provider["maxhp"] * effect(provider, 9000585)), healing=True, healer=provider),
                                                       change_ap(provider, int(effect(provider, 9000585, "value2")))])
        if actor["hp"] <= 0:
            return []
        if skill:
            actor["casts"] += 1
            actor["cast_damage"] = min(Fraction(12, 5), effect(actor, 9000443) * actor["casts"])
            if killed and 9000422 in actor["effects"]:
                actor["certain_combo"] = True
            if 9000437 in actor["effects"]:
                event([change_ap(actor, rng.choice((2, 4)))])
            if 9000423 in actor["effects"]:
                allies = sorted((u for u in living(friends) if u is not actor), key=lambda u: (u["ap"], u["pos"]))[:2]
                event([change_ap(u, max(0, 4 - u["ap"]), provider=actor) for u in allies])
            if 9000322 in actor["effects"]:
                count = 1 + (rng.choice((1, 2)) if 9000427 in actor["effects"] else 0)
                changes = []
                for target in [actor, *enemies.values()]:
                    for key, (amount, _) in list(target["passive_buffs"].items()):
                        if key[1] == 9000322 and (target is actor and amount > 0 or target is not actor and key[0] == actor["iid"]):
                            del target["passive_buffs"][key]
                            changes.append(dest(target, B={"R": "atk", "u": "promote" if amount > 0 else "weaken", "w": False}))
                remaining = actor["atk"] * Fraction(1, 5)
                for target in sorted((u for u in living(enemies) if not u["hidden"]), key=lambda u: (-stat(u, "atk"), u["pos"]))[:count]:
                    changes.append(change_ap(target, -4))
                    stolen = min(stat(target, "atk") * effect(actor, 9000322), remaining)
                    remaining -= stolen
                    changes.extend((passive_buff(target, actor, 9000322, "atk", -stolen, 2), passive_buff(actor, target, 9000322, "atk", stolen, 2)))
                passive_event(actor, 9000427 if 9000427 in actor["effects"] else 9000322, changes)
            if 9000481 in actor["effects"] and not combined:
                corpses = [u for _, u in sorted(friends.items()) if u["hp"] <= 0]
                if corpses:
                    revive(actor, rng.choice(corpses), 9000481, effect(actor, 9000481), hidden=True)
            if 9000761 in actor["effects"]:
                for unit in friends.values():
                    if unit is not actor:
                        unit["tower_damage"] = unit.get("tower_damage", 0) + effect(actor, 9000761, "value2")
            if 9000804 in actor["effects"]:
                changes = []
                allies = living(friends)
                for target in sorted(rng.sample(allies, min(3, len(allies))), key=lambda u: u["pos"]):
                    current = target["buffs"].get(("promote", "critical"), (0, 0))
                    amount = effect(actor, 9000804, "value2") if current[0] and current[1] > round_number else effect(actor, 9000804)
                    target["buffs"]["promote", "critical"] = (amount, round_number + 2)
                    changes.append(dest(target, B={"R": "critical", "u": "promote", "w": True}))
                passive_event(actor, 9000804, changes)
            tongtian = not combined and (config["general"][str(actor["cid"])]["init_cid"] or actor["cid"]) == 10839
            if tongtian:
                actor["tongtian_casts"] = actor.get("tongtian_casts", 0) + 1
                if 9000678 in actor["effects"]:
                    candidates = [u for u in hits if u["hp"] > 0]
                    marks = actor.setdefault("sword_marks", {})
                    for target in rng.sample(candidates, min(2, len(candidates))):
                        marks[target["pos"], target["iid"]] = round_number + 2
                if 9000680 in actor["effects"]:
                    candidates = sorted((u for u in living(enemies) if not u["hidden"]), key=lambda u: (-u["ap"], u["pos"]))
                    passive_event(actor, 9000680, [change_ap(u, -int(effect(actor, 9000680))) for u in candidates[:rng.randint(1, 2)]])
                if 9000682 in actor["effects"]:
                    target = min(living(friends), key=lambda u: (Fraction(u["hp"], u["maxhp"]), u["pos"]))
                    changes = [change_hp(target, -target["maxhp"], healing=True, healer=actor)]
                    if roll(effect(actor, 9000682)):
                        changes.append(change_ap(target, 2, provider=actor))
                    passive_event(actor, 9000682, changes)
                for provider in friends.values():
                    if 9000759 in provider["effects"] and roll(effect(provider, 9000759)):
                        candidates = [u for u in hits if u["hp"] > 0 and not u["dizzy"]]
                        if candidates:
                            target = rng.choice(candidates)
                            if stun(target):
                                event([dest(target, m=[], u={"u": "dizzy", "w": True})])
                    if provider["hp"] > 0 and 9000775 in provider["effects"] and trigger(provider, 9000775):
                        candidates = [u for u in hits if u["hp"] > 0]
                        selected = sorted(rng.sample(candidates, min(2, len(candidates))), key=lambda u: u["pos"])
                        passive_event(provider, 9000775, [*(change_ap(u, -int(effect(provider, 9000775, "value2"))) for u in selected),
                                                            change_ap(provider, int(effect(provider, 9000775)))])
                    if killed and 9000783 in provider["effects"] and roll(effect(provider, 9000783)):
                        corpses = [u for _, u in sorted(friends.items()) if u["hp"] <= 0 and region(u) == "14"]
                        if corpses:
                            revive(provider, rng.choice(corpses), 9000783, 1, hidden=True)
        elif not reaction:
            if 9000760 in actor["effects"]:
                candidates = [u for u in living(enemies) if not u["hidden"]]
                if candidates:
                    target = min(candidates, key=lambda u: (-u["ap"], u["pos"]))
                    passive_event(actor, 9000760, [change_ap(target, -int(effect(actor, 9000760)))])
        if not reaction and round_number <= effect(actor, 9000795) and not actor["hidden"]:
            passive_event(actor, 9000795, set_state(actor, "qianlong"))
        reactions = []
        if reaction or not base_skill or actor["dizzy"] or actor["hidden"] or actor["states"].get("skilllock", 0) > round_number:
            return reactions
        repeats = []
        for code, limit, eligible in (
                (9000418, 1, 9000418 in actor["effects"] and bool(skill) and (killed > 0 or roll(Fraction(1, 2)))),
                (9000419, 2, bool(skill) and killed > 0),
                (9000466, 1, killed > 0),
                (9000491, 1, bool(skill) and roll(effect(actor, 9000491) * sum(u["hp"] <= 0 and bool(u["firing"]) for u in slain))),
                (9000769, 1, bool(skill) and roll(effect(actor, 9000769))),
                (9000777, 1, bool(skill))):
            if code in actor["effects"] and eligible:
                for _ in range(min(killed, 2) if code == 9000419 else 1):
                    if trigger(actor, code, limit):
                        repeats.append(code)
        dead = sum(u["hp"] <= 0 for u in enemies.values())
        if (skill and not combined and dead and 9000487 in actor["effects"] and trigger(actor, 9000487)
                and roll(effect(actor, 9000487) + effect(actor, 9000487, "value2") * (dead - 1))):
            repeats.extend([9000487] * rng.randint(1, 2))
        for code in repeats:
            if not finished() and actor["hp"] > 0 and not actor["hidden"] and not actor["dizzy"]:
                reactions += act(actor, followup=(base_skill, [actor["pos"]], base_skill["ap"]))
        return reactions

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
                changes.extend(change_hp(u, -stat(actor, "atk"), healing=True, healer=actor) for u in allies)
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
                    change = status_damage(target, "firing", amount, 3 if sid == 12633 else 2, actor)
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
        enemies = [u for u in living(teams[not actor["direct"]]) if not u["hidden"]]
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
                amount = target["maxhp"] if target.get("absorbing") else target["hp"]
            elif sid == 12642:
                amount = target["maxhp"] // 2
            else:
                amount = damage({**actor, "atk": stat(actor, "atk")},
                                {**target, "def": stat(target, "def"), "hp": damage_hp(target)},
                                config, sid, multiplier=modifiers(actor, target) * guard(target),
                                flat=actor["flat_out"] - target["flat_in"], combo=True, clip=False)
            change = change_hp(target, amount, hits=skill["count"], shield=sid not in (12640, 12647), bypass_barrier=sid in (12640, 12647), kind="skill", attacker=actor)
            if target["hp"] > 0:
                if sid == 12641:
                    change.update(change_ap(target, -skill["ap_reduce"]))
                if sid == 12645 and stun(target, 2):
                    change["u"] = {"u": "dizzy", "w": True}
            killed += int(target["hp"] == 0)
            destinations.append(change)
        event(destinations, source)
        if sid != 12644:
            for target in selected:
                amount, healer = queen_recovery(target)
                if target["hp"] > 0 and amount:
                    event([change_hp(target, -amount, healing=True, healer=healer)])
        if sid == 12641:
            event([change_hp(actor, actor["maxhp"] // 100, shield=False)])
        actor["strikes"] += 1
        kill_recovery(actor, killed)
        deaths()
        return []

    next_iid = max(u["iid"] for team in teams.values() for u in team.values()) + 1

    def dragon_act(actor):
        nonlocal next_iid
        friends, enemies = teams[actor["direct"]], teams[not actor["direct"]]
        source = {"r": actor["direct"], "p": [actor["pos"]], "t": "break"}
        if 9000324 in actor["effects"] and actor["hp"] * 5 < actor["maxhp"]:
            allies = sorted((u for u in living(friends) if u is not actor), key=lambda u: (-u["maxhp"], u["pos"]))
            if allies:
                target = allies[0]
                target["atk"] += target["base"]["atk"]
                event([change_hp(target, -(target["maxhp"] // 5)), dest(target, B={"R": "atk", "u": "promote", "w": True})],
                      {**source, "S": 9000324})
                actor["hp"] = 0
                del friends[actor["pos"]]
                actions.append({"t": "pos", "changes": [{"r": actor["direct"], "p": actor["pos"], "opt": "disappear"}]})
                return True
        if 9000329 in actor["effects"]:
            event([dest(actor, m={"m": 0, "f": 0, "u": "N", "U": 0})], {**source, "S": 9000334})
            changes = []
            for pos in sorted(p for p in POSITIONS if p not in friends or friends[p]["hp"] <= 0)[:2]:
                child = copy.deepcopy(actor)
                child.update(cid=10823, iid=next_iid, name=config["general"]["10823"]["name"], pos=pos, skill=0, advance=0,
                             hp=actor["maxhp"], ap=0, speed=config["general"]["10823"]["speed"], effects={}, passive_rows=[],
                             buffs={}, states={}, dizzy=False, dot=None, firing=None, guard=0, low_action=False, strikes=0,
                             emergency=False, cover_d=0, cover_d2=0, cover_p=0)
                child["base"]["speed"] = child["speed"]
                friends[pos] = child
                side = report["meta"]["attack" if actor["direct"] else "defense"]["g"]
                side[str(next_iid)] = {"i": next_iid, "c": 10823, "n": child["name"], "level1": child["level"], "level2": 0,
                                       "h": child["hp"], "j": child["maxhp"], "ap": 0, "d": {"i": 0}}
                changes.append({"r": actor["direct"], "p": pos, "opt": "appear", "general": next_iid})
                next_iid += 1
            if changes:
                actions.append({"t": "pos", "changes": changes})
            return True
        sid = 12987 if actor.get("npc") and actor["cid"] == 10823 else 12986 if actor.get("npc") and actor["cid"] == 10820 else 0
        if actor.get("absorbing") or sid == 12987 and actor["states"].get("skilllock", 0) > round_number:
            return True
        if sid and actor["states"].get("skilllock", 0) <= round_number and actor["ap"] >= config["combskill"][str(sid)]["ap"]:
            skill = config["combskill"][str(sid)]
            selected = targets(actor, enemies, skill, rng)
            changes = []
            for target in selected:
                if sid == 12986:
                    amount = target["maxhp"] if target.get("absorbing") else target["hp"]
                else:
                    amount = damage({**actor, "atk": stat(actor, "atk")}, {**target, "def": stat(target, "def"), "hp": damage_hp(target)},
                        config, sid, combo=True, multiplier=modifiers(actor, target) * guard(target), flat=actor["flat_out"] - target["flat_in"],
                        final_multiplier=max(0, 1 - target.get("soul_effects", {}).get("antiblew", 0)), clip=False)
                changes.append(change_hp(target, amount, shield=sid != 12986, bypass_barrier=True, kind="skill", attacker=actor))
            actor["ap"] = skill["ap_give"]
            if sid == 12987:
                amount, actor["hp"] = actor["hp"], 0
                report["dead_log"][str(actor["direct"]).lower()][str(actor["cid"])] = round_number
                pending_deaths.append(actor)
                changes.append(dest(actor, m={"m": amount, "f": 0, "u": "dead", "U": 0}))
            changes.append(dest(actor, ap=actor["ap"], E=True))
            event(changes, {**source, "t": "x", "S": sid})
            deaths()
            return True
        return False

    def act(actor, forced_target=None, reaction=False, followup=None, chain=0):
        nonlocal round_actions
        if actor["hidden"]:
            return []
        if reaction and (actor.get("absorbing") or 9000329 in actor["effects"] or actor.get("npc") and actor["cid"] == 10823):
            return []
        if not reaction and not followup and dragon_act(actor):
            return []
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
            actor["free_combo"] = skill is None and 9000424 in actor["effects"]
            combination = choose_combo(actor, friends, enemies)
            if combination:
                skill, participants = combination
        combined = skill is not None and skill is config["combskill"].get(str(skill["id"]))
        if skill and skill["kind"] == "gain":
            selected = sorted((u for u in friends.values() if u["hp"] > 0 and not u["hidden"]), key=lambda u: (Fraction(u["hp"], u["maxhp"]), u["pos"]))
            if skill["range"] in ("first", "second"):
                selected = [u for u in selected if (u["pos"] < 8) == (skill["range"] == "first")]
            else:
                selected = selected[:skill["randnum"] if skill["range"] == "random" else len(selected) if skill["range"] == "all" else 1]
        else:
            targeting = skill
            if skill and not combined and 9000679 in actor["effects"]:
                targeting = {**skill, "randnum": skill["randnum"] + rng.randint(0, int(effect(actor, 9000679, "value2")))}
            # 密集打击：个人技能目标减少2个（主角金技能180001–3为random范围）。
            if skill and not combined and targeting.get("range") == "random" and 9000517 in actor["effects"]:
                targeting = {**targeting, "randnum": max(1, targeting["randnum"] - 2)}
            selected = [forced_target] if forced_target else targets(actor, enemies, targeting, rng)
            if skill and not combined and 9000743 in actor["effects"] and len(living(enemies)) > effect(actor, 9000743):
                selected = [u for u in living(enemies) if not u["hidden"]]
            if reaction and forced_target and 9000028 in actor["effects"]:
                selected = targets(actor, enemies, {"range": "three"}, rng)
            elif not skill and not forced_target and 9000501 in actor["effects"]:
                selected = sorted((u for u in enemies.values() if u["hp"] > 0 and not u["hidden"]), key=lambda u: (-stat(u, "atk"), u["pos"]))[:1]
            if not skill and not forced_target and any(u.get("taunt_active") and 9000476 in u["effects"] for u in living(enemies)):
                selected = targets(actor, enemies, None, rng)
        if skill and not combined and effect(actor, 9000528):
            candidates = friends if skill["kind"] == "gain" else enemies
            extra = sorted((u for u in candidates.values() if u["hp"] > 0 and not u["hidden"] and u not in selected),
                           key=lambda u: (Fraction(u["hp"], u["maxhp"]) if skill["kind"] == "gain" else 0, u["pos"]))
            selected += extra[:int(effect(actor, 9000528))]
        if (skill and not combined and 9000598 in actor["effects"] and actor["pos"] > 7
                and effect(actor, 9000598, "value2")):
            # 后援机型：自身处于后排（阵位 > 7）时，个人技能目标增加 value2 个。
            candidates = friends if skill["kind"] == "gain" else enemies
            extra = sorted((u for u in candidates.values() if u["hp"] > 0 and not u["hidden"] and u not in selected),
                           key=lambda u: (Fraction(u["hp"], u["maxhp"]) if skill["kind"] == "gain" else 0, u["pos"]))
            selected += extra[:int(effect(actor, 9000598, "value2"))]
        if not skill and not forced_target and 9000688 in actor["effects"] and roll(effect(actor, 9000688)):
            # 进击：普通攻击有 value 概率多打 value2 个目标，反击/续击不重复触发。
            extra = sorted((u for u in enemies.values() if u["hp"] > 0 and not u["hidden"] and u not in selected),
                           key=lambda u: u["pos"])
            selected += extra[:int(effect(actor, 9000688, "value2"))]
        if not selected:
            return []
        actor["chan_attack_damage"] = actor.pop("chan_kill_damage", 0)
        round_actions += 1
        if 9000307 in actor["effects"] and actor["hp"] * 10 > actor["maxhp"] and trigger(actor, 9000307):
            event([change_hp(actor, max(1, actor["maxhp"] // 10), shield=False)])
            amount = actor.get("ramp_damage", 0) + effect(actor, 9000307)
            actor["ramp_damage"] = min(Fraction(8, 5), amount) if pvp else amount
        skill_id = skill["id"] if skill else None
        combo_id = skill_id if combined else None
        source = {"r": actor["direct"], "p": participants, "t": "x" if combined else "k" if skill else "N"}
        if skill:
            source["S"] = skill_id
        old_ap = followup[2] if followup else actor["ap"]
        free_combo = combined and actor.pop("free_combo", False) and not followup
        if not followup:
            actor["ap"] = old_ap if free_combo or not skill and actor.get("qi_until", 0) > round_number else 0 if skill else min(10, old_ap + 2)
        destinations, reactions, dealt, recovered = [], [], 0, []
        killed, hit_targets, burned = 0, [], False
        critical_targets = set()
        tongtian = bool(skill) and not combined and (config["general"][str(actor["cid"])]["init_cid"] or actor["cid"]) == 10839
        lowest = min((u for u in living(enemies) if not u["hidden"]), key=lambda u: (Fraction(u["hp"], u["maxhp"]), u["pos"]), default=None)
        slain = []
        # 强心剂+：被太乙真人恢复过的角色，伤害增加「最大单次恢复量 ÷ (敌方存活数 + value)」。
        heal_row = actor.get("taiyi_heal_row")
        taiyi_bonus = (int(Fraction(actor["taiyi_heal_bonus"], len(living(enemies)) + int(heal_row["value"])))
                       if heal_row and actor.get("taiyi_heal_bonus") else 0)
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
                if not combined and 9000599 in actor["effects"]:
                    # 前线机型：个人技能（非合体）生命恢复效果增加 value。
                    amount = int(amount * (1 + effect(actor, 9000599)))
                destinations.append(change_hp(target, -amount, healing=True, healer=actor))
                if 9000500 in actor["effects"] and target["ap"] < effect(actor, 9000500) and roll(effect(actor, 9000500, "value2")):
                    destinations.append(change_ap(target, 2, provider=actor))
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
                if target["hp"] * 2 < target["maxhp"]:
                    multiplier *= 1 + effect(actor, 9000433)
                if 9999991 in actor["effects"]:
                    multiplier *= Fraction(6, 5)
            elif target["hp"] * 2 < target["maxhp"]:
                multiplier *= 1 + effect(actor, 9000434)
            if tongtian:
                multiplier *= 1 + min(effect(actor, 9000676, "value2"), effect(actor, 9000676) * actor.get("tongtian_casts", 0))
                multiplier *= 1 + effect(actor, 9000677) * sum(u["hp"] <= 0 for u in enemies.values())
                for provider in friends.values():
                    if target is lowest:
                        multiplier *= 1 + effect(provider, 9000675)
                    if provider["hp"] > 0 and target["pos"] == provider["pos"]:
                        multiplier *= 1 + effect(provider, 9000770)
            if skill:
                multiplier *= 1 + max(0, old_ap - skill["ap"]) * Fraction(str(skill["ap_up"]))
                coefficient, growth = map(Fraction, skill["atk-param"].split(";")[:2])
                if not combined:
                    multiplier *= (coefficient + growth * max(0, actor.get("skilllevel", 0) - 1)) / coefficient
                    # 密集打击：释放个人技能时伤害增加 value。
                    multiplier *= 1 + effect(actor, 9000517)
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
            attacker, defender = {**actor, "atk": max(1, stat(actor, "atk"))}, {**target, "def": stat(target, "def"), "hp": damage_hp(target)}
            shared = [target]
            if (not skill and 9000401 in target["effects"] and not target.get("absorbing")
                    and target["states"].get("invincible", 0) <= round_number):
                shared = [u for u in living(enemies) if u is target or config["general"][str(u["cid"])]["region"] == "13"]
            amount = damage(attacker, defender, config, skill_id, critical, multiplier=multiplier, combo=combined,
                            flat=actor["flat_out"] - target["flat_in"] + taiyi_bonus,
                             critical_multiplier=Fraction(3, 2) + Fraction(stat(actor, "criticaldmg"), 100)
                             + (Fraction(1, 10) if combo_id == 12627 else 0), clip=False)
            portion, remainder = divmod(amount, len(shared))
            if not skill and effect(target, 9000428):
                reflected = int(amount * effect(target, 9000428))
                destinations.append(change_hp(actor, reflected))
                portion, remainder = divmod(max(0, amount - reflected), len(shared))
            hits = [(u, change_hp(u, 1 if u is not target and 9000745 in u["effects"] else portion + int(i < remainder), "parry" if parry else "C" if critical else "N",
                                  skill["count"] if critical and skill else int(critical), kind="skill" if skill else "basic", attacker=actor, reaction=reaction)) for i, u in enumerate(shared)]
            hit = next(change for u, change in hits if u is target)
            for recipient, change in hits:
                if recipient is not target:
                    destinations.append(change)
                    recovery, healer = queen_recovery(recipient)
                    if recipient["hp"] > 0 and change["m"]["m"] + change["m"].get("M", 0) > 0 and recovery:
                        recovered.append((recipient, recovery, healer))
            dealt += sum(max(0, change["m"]["m"]) for _, change in hits)
            killed += sum(u["hp"] == 0 for u, _ in hits)
            slain.extend(u for u, _ in hits if u["hp"] == 0)
            amount = hit["m"]["m"] + hit["m"].get("M", 0) + target.get("last_heal_absorbed", 0)
            if skill and amount > 0 and target["states"].pop("fire", None):
                destinations.append(state_event(target, "fire", False))
            if amount > 0:
                hit_targets.append(target)
            if target["hp"] > 0 and amount > 0:
                if skill and 9000021 in actor["effects"]:
                    destinations.extend(set_state(target, "close", rng.randint(1, 2)))
                dizzy = (combo_id == 12622 and target["hp"] * 5 < target["maxhp"]
                         or combo_id == 12618 and target["pos"] > 7 and roll(.35)
                         or skill and skill.get("effect") == "dizzy"
                         and roll(Fraction(str(skill["effect-trigger"])) * (2 if combined and 9000519 in actor["effects"] else 1)
                                  + (effect(actor, 9000679) if not combined else 0))
                         # 魔王震击：合体技本身无眩晕时，按配置基础概率翻倍附加眩晕。
                         or combined and skill.get("effect") != "dizzy" and 9000519 in actor["effects"] and roll(effect(actor, 9000519) * 2)
                         or not skill and 9100002 in actor["effects"] and roll(.3))
                dizzy = dizzy or target["firing"] and roll(effect(actor, 9000483))
                dizzy = dizzy or not skill and (roll(effect(actor, 9000687)) or target["firing"] and roll(effect(actor, 9000805)))
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
                    change = status_damage(target, "firing", int(tick * Fraction(skill["effect-param"])), skill["effect-round"], actor)
                    if change:
                        destinations.append(change)
                if skill and effect(actor, 9000803) and roll(effect(actor, 9000803, "value2")):
                    change = status_damage(target, "firing", min(actor["maxhp"], int(target["maxhp"] * effect(actor, 9000803))), 2, actor)
                    if change:
                        destinations.append(change)
                        burned = True
                if skill and skill.get("effect") == "weaken" and roll(skill["effect-trigger"]):
                    change = buff(target, skill)
                    if change:
                        destinations.append(change)
                if 9000492 in actor["effects"]:
                    change = ignite(actor, target)
                    if change:
                        destinations.append(change)
                reduction = (skill["ap_reduce"] if skill else 0) + (int(effect(actor, 9000020)) if target["dot"] else 0)
                if not reaction:
                    reduction += int(effect(actor, 9000435))
                if not skill:
                    reduction += sum(int(row["value"]) for row in actor["passive_rows"]
                                     if row["type"] == 1 and (row["type_param"] or row["id"]) == 9000502
                                     and target["ap"] >= row["value2"])
                if reduction:
                    destinations.append(change_ap(target, -reduction))
                if skill and not reaction and 9000689 in actor["effects"] and roll(effect(actor, 9000689)):
                    # 平息：释放怒气技能命中后，按 value 概率额外降目标 value2 点怒气。
                    destinations.append(change_ap(target, -int(effect(actor, 9000689, "value2")), provider=actor))
                if not skill and not reaction and 9000505 in actor["effects"]:
                    if target["ap"] >= effect(actor, 9000505):
                        destinations.append(change_ap(target, -int(effect(actor, 9000505))))
                    elif stun(target):
                        destinations.append(dest(target, m=[], u={"u": "dizzy", "w": True}))
                amount, healer = queen_recovery(target)
                if amount:
                    recovered.append((target, amount, healer))
                if not reaction and not target["dizzy"]:
                    if parry:
                        reactions.append((target, actor))
                    if target["low_action"] and not target["emergency"] and target["hp"] * 5 < target["maxhp"]:
                        target["emergency"] = True
                        reactions.append((target, None))
            destinations.append(hit)
        if hit_targets:
            actor["strikes"] += 1
        if combined and 9000598 in actor["effects"] and actor["hp"] > 0:
            # 后援机型：本地把「合体技能的眩晕目标数量+1」解释为发动合体技时额外眩晕
            # 1 个尚未眩晕的存活敌人（太乙自身合体技 12988 的 effect 为空，严格要求
            # 自带眩晕会让该技能永不生效）。按阵位取，不新增 break 动画源。
            for enemy in living(enemies):
                if not enemy["dizzy"] and not enemy.get("hidden") and stun(enemy):
                    event([dest(enemy, u={"u": "dizzy", "w": True})])
                    break
        if (hit_targets and not reaction and not followup and 9000601 in actor["effects"]
                and actor["hp"] > 0 and trigger(actor, 9000601)):
            # 精准支援：攻击时敌方怒气最高者 >= value2 则（仅 PVP）降至 value；
            # 未实际降怒则把己方怒气最低的其他角色恢复到 value2 点。每回合最多 1 次。
            changes, reduced = [], False
            threshold = int(effect(actor, 9000601, "value2"))
            target_ap = int(effect(actor, 9000601))
            if pvp:
                top = max((u["ap"] for u in living(enemies) if not u.get("hidden")), default=0)
                if top >= threshold:
                    for enemy in living(enemies):
                        if enemy["ap"] == top and enemy["ap"] > target_ap:
                            before = enemy["ap"]
                            changes.append(change_ap(enemy, target_ap - before, provider=actor))
                            reduced = reduced or enemy["ap"] < before
            if not reduced:
                allies = [u for u in living(friends) if u is not actor]
                if allies:
                    lowest_ally = min(allies, key=lambda u: (u["ap"], u["pos"]))
                    if lowest_ally["ap"] < threshold:
                        changes.append(change_ap(lowest_ally, threshold - lowest_ally["ap"], provider=actor))
            if changes:
                event(changes)
        if skill and not reaction and actor["hp"] > 0:
            # 无限光波/能量防护：释放技能按 value 概率附加印记。诅咒印记持续 1 回合，
            # 守护印记按层数免疫后续攻击；印记只改内部状态，不伪造原生动画资源。
            if 9000693 in actor["effects"] and roll(effect(actor, 9000693)):
                for target in hit_targets:
                    target["curse_marks"] = target.get("curse_marks", 0) + 1
                    target["curse_marks_until"] = round_number + 2
            if 9000692 in actor["effects"] and roll(effect(actor, 9000692)):
                actor["guard_marks"] = actor.get("guard_marks", 0) + 1
        if skill and effect(actor, 9000803) and not burned:
            target = next((u for u in hit_targets if u["hp"] > 0), None)
            if target:
                change = status_damage(target, "firing", min(actor["maxhp"], int(target["maxhp"] * effect(actor, 9000803))), 2, actor)
                if change:
                    destinations.append(change)
        if (skill and not reaction and not followup and 9000603 in actor["effects"]
                and actor["hp"] > 0):
            # 纳米科技：释放怒气技能后，若自身生命低于敌方生命最高者则交换。
            # PVE 怪物减少量不超过太乙真人生命上限的 value 倍；交换按状态变更入同一战报事件。
            candidates = [u for u in living(enemies) if not u.get("hidden")]
            if candidates:
                richest = max(candidates, key=lambda u: (u["hp"], -u["pos"]))
                gap = richest["hp"] - actor["hp"]
                if gap > 0:
                    delta = min(gap, actor["maxhp"] * int(effect(actor, 9000603))) if not pvp else gap
                    drain = change_hp(richest, delta, kind="other", shield=False, bypass_barrier=True)
                    actual = drain["m"]["m"] + drain["m"].get("M", 0)
                    destinations.append(drain)
                    if actual > 0:
                        # 只按敌人实际减少的生命值回复，避免无敌/减伤挡下时凭空加血。
                        destinations.append(change_hp(actor, -actual, healing=True, healer=actor, kind="other"))
        destinations.append(dest(actor, ap=actor["ap"], E=False))
        if skill and not free_combo and skill["ap_give"] and (not followup or not combined):
            destinations.append(change_ap(actor, skill["ap_give"]))
        event(destinations, source)
        if combo_id in MULTI_COMBOS:
            combo_effects(actor, skill, hit_targets, killed)
        if skill and not followup and effect(actor, 9000062):
            allies = sorted((u for u in living(friends) if u is not actor), key=lambda u: (u["ap"], u["pos"]))
            if allies:
                event([change_ap(allies[0], int(effect(actor, 9000062)), provider=actor)])
        # 人魂雄：人属性（scope3）友方释放怒气技能时恢复自身 value 点怒气。
        if skill and not followup and actor.get("gold_camp") == 3:
            for provider in living(friends):
                if provider is not actor and 9000523 in provider["effects"]:
                    passive_event(provider, 9000523, [change_ap(provider, int(effect(provider, 9000523)), provider=actor)])
        if skill and skill.get("effect") == "suck" and dealt and actor["hp"] > 0:
            amount = min(actor["maxhp"] - actor["hp"], int(dealt * Fraction(skill["effect-param"])))
            if amount:
                event([change_hp(actor, -amount)])
        if not skill and dealt and actor["hp"] > 0 and effect(actor, 9000031):
            event([change_hp(actor, -int(dealt * effect(actor, 9000031)))])
        kill_recovery(actor, killed)
        deaths()
        reactions += passive_after(actor, skill, combined, hit_targets, slain, reaction, base_skill)
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
            killed += extra_kills
        if skill and skill["kind"] == "attack" and skill.get("effect") == "promote" and roll(skill["effect-trigger"]):
            change = buff(actor, skill)
            if change and actor["hp"] > 0:
                event([change])
        for target, amount, healer in recovered:
            if target["hp"] > 0:
                event([change_hp(target, -amount, healing=True, healer=healer)])
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
        artifact_after(actor, skill, hit_targets, killed, reaction, followup)
        if (actor.pop("sacrifice_pending", False) and actor["hp"] > 0 and not actor["hidden"] and not actor["dizzy"]
                and actor["states"].get("skilllock", 0) <= round_number and not finished()):
            reactions += act(actor, followup=(base_skill, [actor["pos"]], base_skill["ap"]))
        actor["chan_attack_damage"] = 0
        return reactions

    def pet_action(direct, pet):
        skill = config["combskill"][str(pet["skill"])]
        if not roll(Fraction(str(skill["trigger"]))):
            return
        friends = [u for _, u in sorted(teams[direct].items()) if u["hp"] > 0 and not u["hidden"]]
        enemies = [u for _, u in sorted(teams[not direct].items()) if u["hp"] > 0 and not u["hidden"]]
        if not friends or not enemies:
            return
        cid, sid = pet["cid"], pet["skill"]
        coefficient = Fraction(skill["atk-param"].split(";")[0].strip())
        destinations = []
        if cid == 90001:
            selected = sorted(friends, key=lambda u: (u["hp"], u["pos"]))[:skill["randnum"]]
            destinations = [change_hp(u, -int((u["maxhp"] - u["hp"]) * coefficient), healing=True) for u in selected]
        else:
            candidates = enemies if cid in (90003, 90005) else friends
            if cid == 90008:
                count = rng.randint(1 if sid == 12998 else 2, skill["randnum"]) if sid in (12998, 14032) else skill["randnum"]
                selected = sorted(rng.sample(enemies, min(len(enemies), count)), key=lambda u: u["pos"])
                average = sum(stat(u, "atk") for u in friends) // len(friends)
                for target in selected:
                    amount = damage({"atk": max(1, average)}, {**target, "def": stat(target, "def"), "hp": damage_hp(target)},
                                    config, sid, multiplier=target["in_multiplier"] * guard(target), clip=False)
                    destinations.append(change_hp(target, amount, kind="pet", attacker=pet))
                    if target["hp"] > 0 and sid != 12996:
                        destinations.append(change_ap(target, -2, pet=True))
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
                destinations.append(change_ap(target, -2 if kind == "weaken" else 2, pet=True))
        event(destinations, {"r": direct, "p": [0], "t": "x", "S": sid})
        deaths()

    round_number = 0
    for team in teams.values():
        seeds = any(9000807 in u["effects"] for u in team.values())
        for unit in team.values():
            if 9000547 in unit["effects"]:
                target = teams[not unit["direct"]].get(unit["pos"])
                if target:
                    unit["photon_target"] = (target["pos"], target["iid"])
                    passive_event(unit, 9000547, [dest(target, m={"m": 0, "f": 0, "u": "N", "U": 0})])
            if 9000744 in unit["effects"]:
                for target in team.values():
                    if target is not unit and region(target) == "13":
                        target["chan_combo_until"] = 2
                        if not target.get("chan_speed"):
                            target["chan_speed"] = 1
                            target["speed"] += 1
            if 9000746 in unit["effects"]:
                target = teams[not unit["direct"]].get(unit["pos"])
                if target:
                    target["qi_until"] = 3
                    passive_event(unit, 9000746, [state_event(target, "close", True)])
            if seeds:
                unit["fire_seeds"] = 1
                event([dest(unit, B={"R": "atk", "u": "promote", "w": True})])
            if 9000784 in unit["effects"]:
                adjacent = [u for u in living(team) if u["pos"] > 7 and abs(u["pos"] - unit["pos"]) == 2 and region(u) == "14"]
                changes = [change for u in adjacent for change in set_state(u, "statusproof", int(effect(unit, 9000784)) + 1)]
                if not adjacent:
                    changes = set_state(unit, "invincible", int(effect(unit, 9000784, "value2")) + 1)
                passive_event(unit, 9000784, changes)
            for kind, attr in unit["buffs"]:
                event([dest(unit, B={"R": attr, "u": kind, "w": True})])
            if unit["cid"] in QUEENS:
                event([dest(u, m={"m": 0, "f": 0, "u": "N", "U": 0}) for _, u in sorted(team.items())],
                      {"r": unit["direct"], "p": [unit["pos"]], "t": "x", "S": 12859})
            row = unit["artifact_effects"].get("屏障")
            if row and roll(Fraction(str(row["value2"]))):
                unit["artifact_barrier"] = 2
                artifact_event(unit, row, [state_event(unit, "invincible", True)])
    for round_number in range(1, max_rounds + 1):
        round_actions = 0
        if round_number > 1:
            event([])
        if finished():
            break
        for team in teams.values():
            for unit in living(team):
                if unit.get("attack_immunity_until") == round_number:
                    if unit.get("attack_immunity") and not invincible_display(unit):
                        event([state_event(unit, "invincible", False)])
                    unit["attack_immunity"] = 0
                if (round_number % 2 == 0 and 9000683 in unit["effects"]
                        and len(living(team)) <= len(living(teams[not unit["direct"]]))):
                    unit["attack_immunity"], unit["attack_immunity_until"] = 2, round_number + 1
                    passive_event(unit, 9000683, [state_event(unit, "invincible", True)])
                if 9000552 in unit["effects"] and roll(effect(unit, 9000552)):
                    passive_event(unit, 9000552, set_state(unit, "statusproof"))
                if round_number == 3 and unit.get("chan_speed"):
                    unit["speed"] -= unit.pop("chan_speed")
                if unit.get("qi_until") == round_number:
                    event([state_event(unit, "close", False)])
                if round_number % 2 == 0 and 9000745 in unit["effects"]:
                    changes = [change_ap(unit, int(effect(unit, 9000745))), *cleanse(unit)]
                    candidates = living(teams[not unit["direct"]])
                    if candidates:
                        target = min(candidates, key=lambda u: (-u["ap"], u["pos"]))
                        changes.append(change_ap(target, -int(effect(unit, 9000745, "value2"))))
                        if target["dizzy"]:
                            target["dizzy"] += 1
                        for kind in ("dot", "firing"):
                            if target[kind]:
                                target[kind][1] += 1
                        for kind in ("skilllock", "close", "fire"):
                            if target["states"].get(kind, 0) > round_number:
                                target["states"][kind] += 1
                        for key, (amount, until) in list(target["buffs"].items()):
                            if key[0] == "weaken" and until > round_number:
                                target["buffs"][key] = (amount, until+1)
                        for key, (amount, until) in list(target["passive_buffs"].items()):
                            if amount < 0 and until > round_number:
                                target["passive_buffs"][key] = (amount, until+1)
                        if target.get("qi_until", 0) > round_number:
                            target["qi_until"] += 1
                    passive_event(unit, 9000745, changes)
                unit["taunt_active"] = round_number <= 2
                if 9000309 in unit["effects"]:
                    row = unit["effects"][9000309]
                    amount = Fraction(str(row["value2"]))
                    key = "team_ramp" if row["type"] == 2 else "ramp_damage"
                    amount += unit.get(key, 0)
                    unit[key] = min(Fraction(8, 5), amount) if pvp else amount
                if 9000442 in unit["effects"]:
                    unit["living_damage"] = min(Fraction(1, 2), unit.get("living_damage", 0) + effect(unit, 9000442))
                if 9000796 in unit["effects"]:
                    unit["ancient_damage"] = min(Fraction(1, 2), unit.get("ancient_damage", 0) + effect(unit, 9000796))
                if round_number == 2 and unit.get("artifact_barrier", 0):
                    unit["artifact_barrier"] = 0
                    if not invincible_display(unit):
                        event([state_event(unit, "invincible", False)])
                regen = unit.get("artifact_regen")
                if regen and regen[1] < round_number <= regen[1] + 2:
                    artifact_event(unit, regen[2], [change_hp(unit, -regen[0], healing=True, unsealed=True)])
                if round_number == 4 and unit.get("absorbing"):
                    unit["absorbing"] = False
                if unit.get("boss_passive") == 12648:
                    unit["atk"] += unit["base"]["atk"] // 5
                    event([change_ap(unit, config["combskill"]["12648"]["ap_give"]),
                           dest(unit, B={"R": "atk", "u": "promote", "w": True})],
                          {"r": unit["direct"], "p": [unit["pos"]], "t": "x", "S": 12648})
                for kind, until in list(unit["states"].items()):
                    if until <= round_number:
                        del unit["states"][kind]
                        if kind == "hide":
                            unit["hidden"] = False
                        if kind != "invincible" or not invincible_display(unit):
                            event([state_event(unit, kind, False)])
                for key, (amount, until) in list(unit["passive_buffs"].items()):
                    if until <= round_number:
                        del unit["passive_buffs"][key]
                        event([dest(unit, B={"R": key[2], "u": "promote" if amount >= 0 else "weaken", "w": False})])
        for direct, pet in combat_pets.items():
            if pet is not None and not finished():
                pet_action(direct, pet)
        order = sorted((u for team in teams.values() for u in team.values() if u["hp"] > 0),
                       key=lambda u: (-u["speed"], u["pos"], not u["direct"], u["iid"]))
        for actor in order:
            if finished():
                break
            if actor["hp"] <= 0 or actor["hidden"]:
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
                if reactor["hp"] > 0 and not reactor["hidden"] and not reactor["dizzy"] and (target is None or target["hp"] > 0 and not target["hidden"]):
                    act(reactor, target, reaction=True)
        if finished():
            break
        for team in teams.values():
            for provider in living(team):
                enemies = living(teams[not provider["direct"]])
                if 9000746 in provider["effects"] and any(u.get("qi_until", 0) > round_number for u in enemies):
                    candidates = [u for u in enemies if u.get("qi_until", 0) <= round_number]
                    if candidates:
                        target = rng.choice(candidates)
                        target["qi_until"] = round_number+3
                        passive_event(provider, 9000746, [state_event(target, "close", True)])
            if any(9000807 in u["effects"] for u in living(team)):
                for unit in sorted(living(team), key=lambda u: (u["fire_seeds"], u["pos"]))[:2]:
                    unit["fire_seeds"] = min(7, unit["fire_seeds"] + 1)
                    event([dest(unit, B={"R": "atk", "u": "promote", "w": True})])
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


def self_stats(row, level, advance, config, *, basis=None):
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
            base_row, base_advance = basis or (row, advance)
            value *= int(general_base(base_row, name, level, base_advance, config))
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
