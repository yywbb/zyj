"""自研回合战斗 v2；纯计算、配置与战报，规则及适用范围见 battle_rules.md。"""

import copy
import random
from fractions import Fraction

from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint


POSITIONS = (2, 8, 10, 4, 12, 6, 14)
QUEENS = (10595, 10817)
MAX_ROUNDS = 30
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
           flat=0, critical_multiplier=Fraction(3, 2)):
    """倍率在分段取整前应用，固定加减伤在求和后应用，最后死亡截断。"""
    coefficient, hits = Fraction(1), 1
    if skill_id is not None:
        skill = config["skill"].get(str(skill_id)) or config["combskill"].get(str(skill_id))
        if not skill or skill["kind"] != "attack":
            raise ValueError("不支持的伤害技能")
        coefficient, hits = Fraction(skill["atk-param"].split(";")[0]), skill["count"]
    if hits <= 0 or coefficient <= 0 or attacker["atk"] <= 0 or defender["def"] < 0 or defender["hp"] < 0:
        raise ValueError("伤害计算参数无效")
    defense_factor = Fraction(config["global_kv"]["battle_def_param1"]["value"])
    base = max(Fraction(attacker["atk"], 20), attacker["atk"] - defender["def"] * defense_factor)
    # 憾地 count=19：逐段向下取整再合计，不能把总伤害取整一次。
    total = int(base * coefficient * (critical_multiplier if critical else 1) * multiplier / hits) * hits
    return min(defender["hp"], max(0, total + flat))


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
    dynamic = {9100001, 9000001, 9000008, 9000015, 9000020, 9000023, 9000024, 9000025,
               9000026, 9000027, 9000028, 9000029, 9000030, 9000031, 9000032, 9000036,
               9000038, 9000039, 9000040, 9000400, 9000412, 9000413, 9000483, 9000489,
               9000496, 9000501, 9000528, 9000583, 9000674, 9000789, 9000791, 9000803}
    flat_defense = {9000047, 9000049, 9000072, 9000078, 9000082}
    stats = ("atk", "def", "hp", "speed", "critical", "dodge", "parry", "resilience", "hit", "arp", "criticaldmg")
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
            if not skill and not (unit["cid"] in QUEENS and unit["skill"] == 0):
                raise ValueError("武将技能不存在")
            if skill and (skill["kind"] not in ("attack", "gain") or skill["range"] not in ("single", "all", "first", "second", "random", "three")
                          or skill["effect"] not in ("once", "dizzy", "dot", "firing", "suck", "promote", "weaken")):
                raise ValueError("尚不支持该武将的技能效果")
            ids = {general.get(f"break{i}", 0) for i in range(1, unit["advance"] + 1)} - {0}
            rows = [config["breakskill"][str(pid)] for pid in sorted(ids)]
            unit.update(pos=pos, direct=direct, ap=2, dizzy=False, dot=None, firing=None, buffs={},
                        emergency=False, strikes=0, guard=0, effects={}, passive_rows=rows,
                        flat_out=0, flat_in=0, cover_d=unit.get("cover_d", 0))
            unit["cover_d2"] = unit["cover_d"]
            added, reduced = unit.get("adddmgpct", 0), unit.get("subdmgpct", 0)
            if min(added, reduced, unit["cover_d"]) < 0 or not 0 <= unit.get("cover_p", 0) <= 100:
                raise ValueError("增减伤或魔罩属性无效")
            unit.update(out_multiplier=1 + Fraction(str(added)), in_multiplier=1 / (1 + Fraction(str(reduced))))
            unit["base"] = {name: unit.get(name, 0) for name in stats}
            for row in rows:
                attr, code = row["attr"], row["type_param"] or row["id"]
                if row["id"] == 9100001:
                    code = 9100001
                if row["type"] == 0 and code != 9100001:
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
        else:
            unit[attr] = unit.get(attr, 0) + (unit["base"][attr] * value if method == "percent" and attr in ("atk", "def", "hp", "speed") else value)

    applied = set()
    for direct, team in teams.items():
        for _, provider in sorted(team.items()):
            for row in provider["passive_rows"]:
                code = 9100001 if row["id"] == 9100001 else row["type_param"] or row["id"]
                value = Fraction(str(row["value"]))
                if code == 9100001:
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
    for team in teams.values():
        for unit in team.values():
            for name in stats:
                unit[name] = max(0, int(unit.get(name, 0)))
            unit["ap"] = max(0, min(10, unit["ap"]))
            unit["maxhp"] = unit["hp"]
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


def simulate(attack, defense, config, seed):
    """不改变输入；同一输入/配置/seed 生成完全相同的行动及终局。"""
    teams = {True: copy.deepcopy(attack), False: copy.deepcopy(defense)}
    _prepare_teams(teams, config)
    rng = random.Random(seed)
    report = {"t": "b", "meta": {}, "b": {"init": {}, "a": []}, "endmeta": {},
              "dead_log": {"true": {}, "false": {}}, "rules": "zyj-v2", "seed": seed}
    actions = report["b"]["a"]
    pending_deaths = []
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
                                "g": meta, "pet": {}, "cheer": []}
        report["b"]["init"][side] = initial

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
        for (kind, attr), (amount, until) in unit["buffs"].items():
            if attr == name and until > round_number:
                value += (unit.get(name, 0) if name in ("atk", "def", "speed") else 100) * amount * (1 if kind == "promote" else -1)
        if name in ("def", "resilience") and any(9000413 in u["effects"] and u["hp"] > 0 for u in teams[unit["direct"]].values()):
            value += unit["def"] * Fraction(1, 5) if name == "def" else 10
        return max(0, int(value))

    def buff(unit, skill):
        attr, amount = skill["effect-param"].split(";")
        if attr not in ("atk", "def", "critical", "dodge"):
            raise ValueError("尚不支持的技能属性效果")
        duration = skill["effect-round"] - (int(effect(unit, 9000789)) if skill["effect"] == "weaken" else 0)
        if duration <= 0:
            return None
        unit["buffs"][(skill["effect"], attr)] = (Fraction(amount), round_number + duration)
        return dest(unit, B={"R": attr, "u": skill["effect"], "w": True})

    def stun(unit):
        if unit["dizzy"] or effect(unit, 9000789) >= 1:
            return False
        unit["dizzy"] = True
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

    def extra_hit(actor, target, coefficient, fixed=0):
        multiplier = modifiers(actor, target) * guard(target)
        flat = actor["flat_out"] - target["flat_in"]
        amount = damage({**actor, "atk": stat(actor, "atk")},
                        {**target, "def": stat(target, "def"), "hp": target["hp"] + target["cover_d"]}, config,
                        multiplier=coefficient * multiplier, flat=flat) if coefficient else max(0, int(fixed * multiplier) + flat)
        return change_hp(target, amount)

    def deaths():
        while pending_deaths:
            unit = pending_deaths.pop(0)
            if effect(unit, 9000027):
                friends = sorted((u for u in teams[unit["direct"]].values() if u["hp"] > 0), key=lambda u: (u["hp"], u["pos"]))
                if friends:
                    event([change_hp(friends[0], -int(stat(unit, "atk") * effect(unit, 9000027)))])
            if effect(unit, 9000040):
                selected = targets(unit, teams[not unit["direct"]], None, rng)
                if selected:
                    target = selected[0]
                    event([extra_hit(unit, target, effect(unit, 9000040))])

    def act(actor, forced_target=None, reaction=False):
        enemies, friends = teams[not actor["direct"]], teams[actor["direct"]]
        skill, participants = None, [actor["pos"]]
        base_skill = config["skill"].get(str(actor["skill"]))
        if not reaction and base_skill and actor["ap"] >= base_skill["ap"]:
            skill = base_skill
            if actor["cid"] == 10112:
                skill = config["combskill"]["12618"]
            elif actor["cid"] in (10213, 10214):
                partner_cid = {10213: 10214, 10214: 10213}[actor["cid"]]
                partner = next((u for _, u in sorted(friends.items()) if u["cid"] == partner_cid
                                and u["hp"] > 0 and not u["dizzy"]), None)
                chance = config["combskillprobability"]["12622"][f"bout{min(10, round_number)}"]
                if partner and any(u["hp"] > 0 and u["pos"] > 7 for u in enemies.values()) and roll(chance):
                    skill = config["combskill"]["12622"]
                    participants.append(partner["pos"])
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
        if skill and skill["id"] not in (12618, 12622) and effect(actor, 9000528):
            candidates = friends if skill["kind"] == "gain" else enemies
            extra = sorted((u for u in candidates.values() if u["hp"] > 0 and u not in selected),
                           key=lambda u: (Fraction(u["hp"], u["maxhp"]) if skill["kind"] == "gain" else 0, u["pos"]))
            selected += extra[:int(effect(actor, 9000528))]
        if not selected:
            return []
        skill_id = skill["id"] if skill else None
        source = {"r": actor["direct"], "p": participants, "t": "x" if skill_id in (12618, 12622) else "k" if skill else "N"}
        if skill:
            source["S"] = skill_id
        old_ap = actor["ap"]
        actor["ap"] = 0 if skill else min(10, old_ap + 2)
        destinations, reactions, dealt, recovered = [], [], 0, []
        killed, hit_targets, burned = 0, [], False
        for target in selected:
            if target["hp"] <= 0:
                continue
            if skill and skill["kind"] == "gain":
                if 9000412 in actor["effects"]:
                    destinations.extend(cleanse(target))
                coefficient, growth = map(Fraction, skill["atk-param"].split(";")[:2])
                multiplier = 1 + max(0, old_ap - skill["ap"]) * Fraction(str(skill["ap_up"]))
                amount = int(stat(actor, "atk") * (coefficient + growth * max(0, actor.get("skilllevel", 0) - 1)) * multiplier)
                destinations.append(change_hp(target, -amount))
                if skill["effect"] == "promote" and roll(skill["effect-trigger"]):
                    change = buff(target, skill)
                    if change:
                        destinations.append(change)
                continue
            dodge = max(0, min(75, stat(target, "dodge") - actor.get("hit", 0))) / 100
            if roll(dodge):
                destinations.append(dest(target, m={"m": 0, "f": 0, "u": "dodge", "U": 0}))
                continue
            critical_chance = (stat(actor, "critical") - stat(target, "resilience")) / 100 if 9000030 not in target["effects"] else 0
            critical = skill_id == 12618 and target["pos"] < 8 or roll(max(0, min(.75, critical_chance)))
            parry = roll(max(0, min(.5, (stat(target, "parry") - stat(actor, "arp")) / 100)))
            multiplier = modifiers(actor, target)
            if skill:
                multiplier *= 1 + max(0, old_ap - skill["ap"]) * Fraction(str(skill["ap_up"]))
                coefficient, growth = map(Fraction, skill["atk-param"].split(";")[:2])
                if skill_id not in (12618, 12622):
                    multiplier *= (coefficient + growth * max(0, actor.get("skilllevel", 0) - 1)) / coefficient
            multiplier *= guard(target)
            if parry:
                multiplier *= Fraction(3, 10)
            attacker, defender = {**actor, "atk": max(1, stat(actor, "atk"))}, {**target, "def": stat(target, "def"), "hp": target["hp"] + target["cover_d"]}
            amount = damage(attacker, defender, config, skill_id, critical, multiplier=multiplier,
                            flat=actor["flat_out"] - target["flat_in"],
                            critical_multiplier=Fraction(3, 2) + Fraction(actor.get("criticaldmg", 0), 100))
            hit = change_hp(target, amount, "parry" if parry else "C" if critical else "N",
                             skill["count"] if critical and skill else int(critical))
            dealt += hit["m"]["m"]
            killed += int(target["hp"] == 0)
            if amount > 0:
                hit_targets.append(target)
            if target["hp"] > 0 and amount > 0:
                dizzy = (skill_id == 12622 and target["hp"] * 5 < target["maxhp"]
                         or skill_id == 12618 and target["pos"] > 7 and roll(.35)
                         or skill and skill.get("effect") == "dizzy" and roll(skill["effect-trigger"]))
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
                provider = next((u for _, u in sorted(teams[target["direct"]].items()) if u["cid"] in QUEENS and u["hp"] > 0), None)
                if provider:
                    recovered.append((target, (stat(provider, "atk") * 12 + provider["maxhp"] * 4) // 100))
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
        if skill and skill["ap_give"]:
            actor["ap"] = min(10, actor["ap"] + skill["ap_give"])
            destinations.append(dest(actor, ap=actor["ap"], E=True))
        event(destinations, source)
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
        return reactions

    round_number = 0
    for team in teams.values():
        for unit in team.values():
            for kind, attr in unit["buffs"]:
                event([dest(unit, B={"R": attr, "u": kind, "w": True})])
            if unit["cid"] in QUEENS:
                event([dest(u, m={"m": 0, "f": 0, "u": "N", "U": 0}) for _, u in sorted(team.items())],
                      {"r": unit["direct"], "p": [unit["pos"]], "t": "x", "S": 12859})
    for round_number in range(1, MAX_ROUNDS + 1):
        if round_number > 1:
            event([])
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
                actor["dizzy"] = False
                event([dest(actor, m=[], u={"u": "dizzy", "w": False})])
                continue
            for reactor, target in act(actor):
                if finished():
                    break
                if reactor["hp"] > 0 and not reactor["dizzy"] and (target is None or target["hp"] > 0):
                    act(reactor, target, reaction=True)
        if finished():
            break
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


def grown_general(unit, gained, config, maximum=None):
    level, experience, up = general_experience(unit, gained, config, maximum)
    values = {3: level, 5: experience}
    row = config["general"][str(unit["cid"])]
    deltas = {}
    for name in ("atk", "def", "hp", "speed"):
        delta = (int(general_base(row, name, level, unit.get("advance", 0), config))
                 - int(general_base(row, name, unit["level"], unit.get("advance", 0), config)))
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
