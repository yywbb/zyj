"""自研回合战斗 v2；纯计算、配置与战报，规则及适用范围见 battle_rules.md。"""

import copy
import random
from fractions import Fraction

from .protocol import iter_pb_fields, pb_get_varint


POSITIONS = (2, 8, 10, 4, 12, 6, 14)
MAPS = (42102, 42103, 42104)
MAX_ROUNDS = 30
GENERAL_FIELDS = {"cid": 1, "iid": 2, "level": 3, "advance": 4, "exp": 5,
                  "atk": 6, "def": 7, "hp": 8, "speed": 9,
                  "critical": 10, "dodge": 11, "parry": 12, "resilience": 13,
                  "hit": 14, "arp": 15, "criticaldmg": 16, "skilllevel": 18}


def challenge(save, body, config):
    try:
        fields = list(iter_pb_fields(body))
    except ValueError as error:
        raise ValueError("关卡挑战参数无效") from error
    if len(fields) != 2 or any(n != 1 or w != 0 or not 0 < v < (1 << 31) for n, w, v in fields):
        raise ValueError("关卡挑战参数无效")
    map_id, point_id = (v for _, _, v in fields)
    if map_id not in MAPS:
        raise ValueError("战斗 v2 暂支持奈河桥、葬剑谷、轮回殿关卡")
    row = config["copy"].get(str(map_id), {}).get(str(point_id))
    if not row or not save.get("has_role"):
        raise ValueError("关卡不存在或角色尚未创建")
    copies = bytes.fromhex(save["world_state"]["1300"])
    current = next((v for n, w, v in iter_pb_fields(copies)
                    if n == 1 and w == 2 and pb_get_varint(v, 1) == map_id), b"")
    points = {pb_get_varint(v, 1): v for n, w, v in iter_pb_fields(current) if n == 7 and w == 2}
    if not current or (point_id > 1 and not pb_get_varint(points.get(point_id - 1, b""), 3)):
        raise ValueError("关卡尚未解锁")
    previous = points.get(point_id, b"")
    if (pb_get_varint(previous, 4) or 0) >= row["challenge"]:
        raise ValueError("关卡挑战次数不足")
    if save["role_state"]["stamina"] < row["physical"]:
        raise ValueError("体力不足")
    return row, pb_get_varint(previous, 3) or 0


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
        if (point[f"p{i}-grow"] or point[f"mozhao{i}_lv"]
                or point[f"adddmgpct{i}-correct"] or point[f"subdmgpct{i}-correct"]):
            raise ValueError("该关卡的额外怪物属性尚未核实")
        unit = {"iid": monster_id * 10 + i, "cid": monster["generalid"], "level": level,
                "advance": point[f"break{i}-correct"], "name": monster["name"],
                "boss": point[f"p{i}-type"] == 2}
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


def _gain_experience(level, experience, gained, table, field):
    if any(type(v) is not int or v < 0 for v in (level, experience, gained)) or level < 1:
        raise ValueError("经验参数无效")
    experience += gained
    while True:
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
    level, experience = _gain_experience(state["level"], state["exp"], gained, config["role_exp"], "nextexp")
    coin = point["coin"] * (3 if old_star != 3 and star == 3 else 1)
    gold = 0
    for reached in range(state["level"] + 1, level + 1):
        coin += config["role_exp"][str(reached)]["c_reward"]
        gold += config["role_exp"][str(reached)]["g_reward"]
    return {"gained": gained, "level": level, "exp": experience, "coin": coin, "gold": gold}


def general_experience(unit, gained, config):
    quality = config["general"][str(unit["cid"])]["quality"]
    level, experience = _gain_experience(unit["level"], unit["exp"], gained, config["general_exp"], f"{quality}exp")
    return level, experience, level - unit["level"]


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
    rng = random.Random(seed)
    report = {"t": "b", "meta": {}, "b": {"init": {}, "a": []}, "endmeta": {},
              "dead_log": {"true": {}, "false": {}}, "rules": "zyj-v2", "seed": seed}
    actions = report["b"]["a"]
    for direct, team in teams.items():
        if not team:
            raise ValueError("战斗双方必须有上阵武将")
        side = "attack" if direct else "defense"
        meta, initial = {}, {}
        for pos, unit in sorted(team.items()):
            if pos not in POSITIONS or any(unit[k] <= 0 for k in ("hp", "atk", "speed")) or unit["def"] < 0:
                raise ValueError("战斗属性或阵位无效")
            general = config["general"][str(unit["cid"])]
            if not 0 <= unit["advance"] <= 23 or not 0 <= unit.get("skilllevel", 0) <= 300:
                raise ValueError("战斗突破或技能等级无效")
            skill = config["skill"].get(str(unit["skill"]))
            if not skill and not (unit["cid"] == 10595 and unit["skill"] == 0):
                raise ValueError("武将技能不存在")
            if skill and (skill["kind"] not in ("attack", "gain") or skill["range"] not in ("single", "all", "first", "second", "random", "three")
                          or skill["effect"] not in ("once", "dizzy", "dot", "suck", "promote", "weaken")):
                raise ValueError("尚不支持该武将的技能效果")
            passives = {general.get(f"break{i}", 0) for i in range(1, unit["advance"] + 1)} - {0}
            if not passives <= {9100001, 9000024, 9000061, 9000066, 9000074, 9000078, 9000049}:
                raise ValueError("尚不支持该突破被动")
            unit.update(pos=pos, direct=direct, maxhp=unit["hp"], ap=2, dizzy=False, dot=None, buffs={},
                        emergency=False, guard=2 if 9000024 in passives else 0,
                        low_action=9100001 in passives,
                        flat_out=sum(int(config["breakskill"][str(p)]["value"]) for p in passives & {9000061, 9000074}),
                        flat_in=sum(int(config["breakskill"][str(p)]["value"]) for p in passives & {9000078, 9000049}))
            initial[str(pos)] = {"i": unit["iid"], "o": unit.get("boss", False)}
            meta[str(unit["iid"])] = {"i": unit["iid"], "c": unit["cid"], "n": unit.get("name", general["name"]),
                                      "level1": unit["level"], "level2": unit["advance"], "level3": 0,
                                      "h": unit["hp"], "j": unit["hp"], "ap": 2, "d": {"i": unit["skill"]}}
        report["meta"][side] = {"n": "本地玩家" if direct else next(iter(team.values())).get("name", "守关队伍"),
                                "g": meta, "pet": {}, "cheer": []}
        report["b"]["init"][side] = initial

    def roll(chance):
        return chance > 0 and rng.random() < min(1, chance)

    def dest(unit, **values):
        return {"r": unit["direct"], "p": unit["pos"], **values}

    def event(destinations, source=None):
        actions.append({"t": "b", "s": source or {}, "e": destinations})
        if len(actions) > 2000:
            raise ValueError("战斗事件超出上限，未结算")

    def change_hp(unit, amount, status="N", hits=0):
        amount = max(- (unit["maxhp"] - unit["hp"]), min(unit["hp"], amount))
        unit["hp"] -= amount
        if unit["hp"] == 0:
            status = "dead" if status == "N" else status + "dead" if status not in ("C",) else "C"
            report["dead_log"][str(unit["direct"]).lower()][str(unit["cid"])] = round_number
        return dest(unit, m={"m": amount, "f": 0, "u": status, "U": hits})

    def finished():
        return any(not any(u["hp"] > 0 for u in team.values()) for team in teams.values())

    def stat(unit, name):
        value = unit.get(name, 0)
        for (kind, attr), (amount, until) in unit["buffs"].items():
            if attr == name and until > round_number:
                value += (unit.get(name, 0) if name in ("atk", "def", "speed") else 100) * amount * (1 if kind == "promote" else -1)
        return max(0, int(value))

    def buff(unit, skill):
        attr, amount = skill["effect-param"].split(";")
        if attr not in ("atk", "def", "critical", "dodge"):
            raise ValueError("尚不支持的技能属性效果")
        unit["buffs"][(skill["effect"], attr)] = (Fraction(amount), round_number + skill["effect-round"])
        return dest(unit, B={"R": attr, "u": skill["effect"], "w": True})

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
            selected = selected[:skill["randnum"] if skill["range"] == "random" else len(selected) if skill["range"] == "all" else 1]
        else:
            selected = [forced_target] if forced_target else targets(actor, enemies, skill, rng)
        if not selected:
            return []
        skill_id = skill["id"] if skill else None
        source = {"r": actor["direct"], "p": participants, "t": "x" if skill_id in (12618, 12622) else "k" if skill else "N"}
        if skill:
            source["S"] = skill_id
        old_ap = actor["ap"]
        actor["ap"] = 0 if skill else min(10, old_ap + 2)
        destinations, reactions, dealt, recovered = [], [], 0, []
        for target in selected:
            if target["hp"] <= 0:
                continue
            if skill and skill["kind"] == "gain":
                coefficient, growth = map(Fraction, skill["atk-param"].split(";")[:2])
                multiplier = 1 + max(0, old_ap - skill["ap"]) * Fraction(str(skill["ap_up"]))
                amount = int(stat(actor, "atk") * (coefficient + growth * max(0, actor.get("skilllevel", 0) - 1)) * multiplier)
                destinations.append(change_hp(target, -amount))
                if skill["effect"] == "promote" and roll(skill["effect-trigger"]):
                    destinations.append(buff(target, skill))
                continue
            dodge = max(0, min(75, stat(target, "dodge") - actor.get("hit", 0))) / 100
            if roll(dodge):
                destinations.append(dest(target, m={"m": 0, "f": 0, "u": "dodge", "U": 0}))
                continue
            critical_chance = (stat(actor, "critical") - target.get("resilience", 0)) / 100
            critical = skill_id == 12618 and target["pos"] < 8 or roll(max(0, min(.75, critical_chance)))
            parry = roll(max(0, min(.5, (target.get("parry", 0) - actor.get("arp", 0)) / 100)))
            multiplier = Fraction(1)
            if skill:
                multiplier += max(0, old_ap - skill["ap"]) * Fraction(str(skill["ap_up"]))
                coefficient, growth = map(Fraction, skill["atk-param"].split(";")[:2])
                if skill_id not in (12618, 12622):
                    multiplier *= (coefficient + growth * max(0, actor.get("skilllevel", 0) - 1)) / coefficient
            if target["guard"]:
                multiplier *= 1 - Fraction(str(config["breakskill"]["9000024"]["value"]))
                target["guard"] -= 1
            if parry:
                multiplier *= Fraction(3, 10)
            attacker, defender = {**actor, "atk": max(1, stat(actor, "atk"))}, {**target, "def": stat(target, "def")}
            amount = damage(attacker, defender, config, skill_id, critical, multiplier=multiplier,
                            flat=actor["flat_out"] - target["flat_in"],
                            critical_multiplier=Fraction(3, 2) + Fraction(actor.get("criticaldmg", 0), 100))
            dealt += amount
            hit = change_hp(target, amount, "parry" if parry else "C" if critical else "N",
                            skill["count"] if critical and skill else int(critical))
            if target["hp"] > 0 and amount > 0:
                dizzy = (skill_id == 12622 and target["hp"] * 5 < target["maxhp"]
                         or skill_id == 12618 and target["pos"] > 7 and roll(.35)
                         or skill and skill.get("effect") == "dizzy" and roll(skill["effect-trigger"]))
                if dizzy and not target["dizzy"]:
                    target["dizzy"] = True
                    hit["u"] = {"u": "dizzy", "w": True}
                if skill and skill.get("effect") == "dot" and roll(skill["effect-trigger"]):
                    tick = damage(attacker, {**defender, "hp": (1 << 31) - 1}, config)
                    target["dot"] = [max(1, int(tick * Fraction(skill["effect-param"]))), skill["effect-round"]]
                    hit["u"] = {"u": "dot", "w": True}
                if skill and skill.get("effect") == "weaken" and roll(skill["effect-trigger"]):
                    destinations.append(buff(target, skill))
                if skill and skill["ap_reduce"]:
                    target["ap"] = max(0, target["ap"] - skill["ap_reduce"])
                    destinations.append(dest(target, ap=target["ap"], E=True))
                provider = next((u for _, u in sorted(teams[target["direct"]].items()) if u["cid"] == 10595 and u["hp"] > 0), None)
                if provider:
                    recovered.append((target, (stat(provider, "atk") * 12 + provider["maxhp"] * 4) // 100))
                if not reaction and not target["dizzy"]:
                    if parry:
                        reactions.append((target, actor))
                    if target["low_action"] and not target["emergency"] and target["hp"] * 5 < target["maxhp"]:
                        target["emergency"] = True
                        reactions.append((target, None))
            destinations.append(hit)
        destinations.append(dest(actor, ap=actor["ap"], E=False))
        if skill and skill["ap_give"]:
            actor["ap"] = min(10, actor["ap"] + skill["ap_give"])
            destinations.append(dest(actor, ap=actor["ap"], E=True))
        event(destinations, source)
        if skill and skill.get("effect") == "suck" and dealt and actor["hp"] > 0:
            amount = min(actor["maxhp"] - actor["hp"], int(dealt * Fraction(skill["effect-param"])))
            if amount:
                event([change_hp(actor, -amount)])
        if skill and skill["kind"] == "attack" and skill.get("effect") == "promote" and roll(skill["effect-trigger"]):
            event([buff(actor, skill)])
        for target, amount in recovered:
            if target["hp"] > 0:
                event([change_hp(target, -amount)])
        return reactions

    round_number = 0
    for team in teams.values():
        for unit in team.values():
            if unit["cid"] == 10595:
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
            if actor["dot"]:
                event([change_hp(actor, actor["dot"][0], "dot")])
                actor["dot"][1] -= 1
                if not actor["dot"][1]:
                    actor["dot"] = None
                    event([dest(actor, m=[], u={"u": "dot", "w": False})])
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
                       "cover_d": 0, "feign_dead": False, "region": config["general"][str(u["cid"])]["region"]}
            for pos, u in sorted(team.items())}
    return report


def grown_general(unit, gained, config):
    level, experience, up = general_experience(unit, gained, config)
    values = {3: level, 5: experience}
    row = config["general"][str(unit["cid"])]
    deltas = {}
    for name in ("atk", "def", "hp", "speed"):
        growth = Fraction(str(row[f"{name}-grow"]))
        delta = int(growth * (level - 1)) - int(growth * (unit["level"] - 1))
        values[GENERAL_FIELDS[name]] = unit[name] + delta
        deltas[name] = delta
    # 自研战力仅用于显示：保留旧基值，新增成长按四围增量计分，不参与胜负。
    power = deltas["atk"] + deltas["def"] + deltas["hp"] // 10 + deltas["speed"]
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
        if not entries or any(len(e) != 3 or min(e) <= 0 for e in entries):
            raise ValueError("关卡掉落配置无效")
        draw = rng.randrange(sum(e[2] for e in entries))
        for cid, count, weight in entries:
            draw -= weight
            if draw < 0:
                add(cid, count)
                break
    return rewards
