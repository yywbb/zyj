"""王的男人：独立布阵、日历Boss、真实挑战与胜利次数结算。"""

from collections import Counter
import copy
import datetime
from fractions import Fraction
import json
import random

from . import activities, battle, development, formation, pets, recharge
from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint, pb_set_varint

QUERIES = (3700, 3702)
MUTATIONS = (3701, 3703, 3705)
OPCODES = QUERIES + MUTATIONS


def levels(config, kind):
    return sorted((row for row in config["personalboss_att"].values() if row["function"] == kind), key=lambda r: r["level"])


def validate_team(save, team, config):
    if not isinstance(team, list) or len(team) != 8 or any(type(i) is not int or not 0 <= i < (1 << 31) for i in team):
        raise ValueError("王的男人布阵记录无效")
    world = bytes.fromhex(save["world_state"]["1002"])
    generals, cheers = formation.records(world, 1, 2), formation.records(world, 5, 2)
    protagonist = pb_get_varint(bytes.fromhex(save.get("protagonist_snapshot", "")), 1)
    maximum = min(7, config["role_exp"][str(save["role_state"]["level"])]["slotnum"])
    members = [i for i in team[:7] if i]
    if not protagonist or protagonist not in members or len(set(members)) != len(members):
        raise ValueError("专用阵容必须保留主角，伙伴不能重复")
    for index, iid in enumerate(team[:7], 1):
        if not iid:
            continue
        raw = generals.get(iid)
        if (index > maximum or not raw or iid in cheers
                or not config["general"][str(pb_get_varint(raw, 1))]["battle"]
                or any(pb_get_varint(raw, n) for n in range(21, 41))):
            raise ValueError("专用阵位未解锁、伙伴不属于本人或高级/助阵属性不支持")
    if team[7] and team[7] not in {p[0] for p in pets.get_state(save, config)["pets"]}:
        raise ValueError("专用阵容魔宠不属于当前账号")


def get_state(save, config):
    state = save.setdefault("single_boss_state", {"day": 0, "used": 0, "bought": 0,
                            "cleared": {"1": 0, "2": 0}, "teams": {"1": None, "2": None}})
    if (not isinstance(state, dict) or any(type(state.get(k)) is not int or not 0 <= state[k] < (1 << 31) for k in ("day", "used", "bought"))
            or not isinstance(state.get("cleared"), dict) or set(state["cleared"]) != {"1", "2"}
            or not isinstance(state.get("teams"), dict) or set(state["teams"]) != {"1", "2"}
            or state["bought"] > max(row["personalboss_times"] for row in config["vip"].values())
            or state["used"] > config["vip"]["0"]["personalboss_times"] + state["bought"]
            or state["day"] == 0 and (state["used"] or state["bought"])):
        raise ValueError("王的男人存档无效")
    for kind in ("1", "2"):
        value = state["cleared"][kind]
        if type(value) is not int or not 0 <= value <= len(levels(config, int(kind))):
            raise ValueError("王的男人通关记录无效")
        if state["teams"][kind] is not None:
            validate_team(save, state["teams"][kind], config)
    return state


def settle(save, config, now):
    state = get_state(save, config)
    day = (now + 28800) // 86400
    if day > state["day"]:
        state.update(day=day, used=0, bought=0)
    return state


def boss_type(state, config):
    date = datetime.datetime.fromtimestamp(state["day"] * 86400, datetime.timezone.utc)
    return config["personalboss_date"][str(date.day)]["boss"]


def query(save, state, config):
    kind = boss_type(state, config)
    cleared = state["cleared"][str(kind)]
    return recharge.ids([state["used"], kind, int(state["teams"][str(kind)] is None),
                         levels(config, kind)[cleared - 1]["id"] if cleared else 0, 100, state["bought"]])


def project_team(save, team, config):
    """仅战斗副本重算缘分/宠物，当前主阵位的装备和神石随其伙伴带入。"""
    validate_team(save, team, config)
    temporary = copy.deepcopy(save)
    world = bytes.fromhex(save["world_state"]["1002"])
    generals, old = formation.records(world, 1, 2), formation.records(world, 4, 2)
    slots = {i: pb_set_varint(pb_set_varint(old.get(iid, b"") if iid else b"", 1, i), 2, iid) for i, iid in enumerate(team[:7], 1)}
    update = formation.apply_slots(temporary, slots, config)
    generals.update(formation.records(update, 1, 2))
    previous = pets.attributes(temporary, config)
    pets.get_state(temporary, config)["active"] = team[7]
    changes = {field: int(value) - int(previous[field]) for field, value in pets.attributes(temporary, config).items()}
    power = 0
    for iid in team[:7]:
        if iid:
            generals[iid], _ = development.adjust(generals[iid], changes)
            power += pb_get_varint(generals[iid], 20) or 0
    if power >= (1 << 31):
        raise ValueError("专用阵容战力超出范围")
    temporary["world_state"]["1002"] = (b"".join(encode_pb_field(n, w, v) for n, w, v in iter_pb_fields(world) if n not in (1, 4))
        + b"".join(encode_pb_field(1, 2, v) for _, v in sorted(generals.items()))
        + b"".join(encode_pb_field(4, 2, v) for _, v in sorted(slots.items()))).hex()
    return temporary, power


def rosters(save, team, row, config):
    temporary, power = project_team(save, team, config)
    point = dict(config["copy"]["42101"]["1"])
    attack, _ = battle.rosters(temporary, point, config)
    cycle = []
    for entry in row["order"].strip(";").split(";"):
        index = int(entry)
        if index not in range(1, 5) or row[f"skill{index}"] not in range(12640, 12648):
            raise ValueError("个人Boss技能顺序配置无效")
        cycle.append(row[f"skill{index}"])
    if row["breakskill"] not in (9000613, 9000614) or row["passiveskills"] not in (0, 12648) or row["grow"]:
        raise ValueError("个人Boss被动或成长配置无效")
    general = dict(row, skillid=0, combskillid=0, init_cid=0)
    config = {**config, "general": {**config["general"], str(row["id"]): general}}
    mask = config["mozhao_break"][str(row["mozhao1_lv"])]
    unit = {"iid": row["id"], "cid": row["id"], "level": row["level"], "advance": 0,
            "skill": 0, "skilllevel": 0, "name": row["name"], "npc": True, "boss": True,
            "boss_cycle": cycle, "boss_aura": True, "boss_passive": row["passiveskills"], "initial_ap": row["ap"],
            "cover_l": row["mozhao1_lv"], "cover_d": mask["value"], "cover_p": mask["percent"],
            "adddmgpct": Fraction(str(row["adddmgpct-correct"])) / 100,
            "subdmgpct": Fraction(str(row["subdmgpct-correct"])) / 100}
    for name in ("atk", "def", "hp", "speed", "critical", "dodge", "parry", "resilience", "hit", "arp", "criticaldmg"):
        unit[name] = row[name] + row.get(f"{name}-correct", 0)
    return attack, {2: unit}, config, pets.combat(temporary, config), power


def prizes(save, row, first, config, day, rng):
    gets = Counter()
    weekday = (day + 3) % 7 + 1
    factor = next((Fraction(str(r["modulus"])) for r in config["activity_huodong"].values()
                   if r["param"] == 4 and r["open_time"] == weekday), Fraction(1))
    for i in range(1, 5):
        cid, low, high, chance = (row[f"drop{i}"], row[f"drop{i}number"], row[f"drop{i}number{i}"], row[f"drop{i}prob"])
        if (any(type(v) is not int for v in (cid, low, high, chance)) or not 0 <= chance <= 100
                or not 0 <= low <= high < (1 << 31) or cid < 0):
            raise ValueError("个人Boss掉落配置无效")
        if cid and high and chance:
            activities.build_reward(save, f"{cid},1", config)
            if rng.randrange(100) < chance:
                gets[cid] += int(rng.randint(low, high) * factor)
    if first:
        for entry in row["firstDrop"].split(";"):
            if entry:
                cid, count = map(int, entry.split(","))
                if cid <= 0 or count <= 0:
                    raise ValueError("个人Boss首次奖励无效")
                gets[cid] += count  # 首次附奖不参加周四双倍。
    return gets


def rewrite_vip(body, save, config, now):
    state = get_state(save, config)
    index, result = 0, bytearray()
    for n, w, v in iter_pb_fields(body):
        if (n, w) == (1, 0):
            index += 1
            if index == 12:
                v = state["bought"] if (now + 28800) // 86400 <= state["day"] else 0
        result.extend(encode_pb_field(n, w, v))
    return bytes(result)


def buy(save, count, quoted, config, now):
    if (not save.get("has_role") or save["role_state"]["level"] < config["build"]["140"]["level"]
            or save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2):
        raise ValueError("王的男人尚未解锁")
    state = settle(save, config, now)
    if (now + 28800) // 86400 != state["day"] or state["bought"] + count > config["vip"][str(save["role_state"]["vip"])]["personalboss_times"]:
        raise ValueError("王的男人日期回拨或今日购买次数不足")
    prices = config["buycount_price"]
    price = sum(prices[str(min(i, max(map(int, prices))))]["personalboss_cost"] for i in range(state["bought"] + 1, state["bought"] + count + 1))
    if quoted != price or price < 0:
        raise ValueError("王的男人报价已变化，请重新打开购买窗口")
    state["bought"] += count
    return price


def prepare(opcode, save, body, config, now, seed):
    fields = list(iter_pb_fields(body))
    if any(n != 1 or w != 0 or not 0 <= v < (1 << 31) for n, w, v in fields):
        raise ValueError("王的男人请求格式无效")
    values = [v for _, _, v in fields]
    if (len(values) != {3700: 0, 3701: 1, 3702: 2, 3703: 10, 3705: 2}[opcode]
            or opcode in (3702, 3703) and (values[0] != 140 or values[1] not in (1, 2))):
        raise ValueError("王的男人操作参数无效")
    if (not save.get("has_role") or save["role_state"]["level"] < config["build"]["140"]["level"]
            or save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2):
        raise ValueError("王的男人尚未解锁")
    state = settle(save, config, now)
    if opcode == 3700:
        return query(save, state, config), [], b""
    if (now + 28800) // 86400 != state["day"]:
        raise ValueError("服务器日期回拨，请稍后操作王的男人")
    if opcode in (3702, 3703):
        key = str(values[1])
        if opcode == 3703:
            state["teams"][key] = values[2:]
        elif state["teams"][key] is None:
            slots = formation.records(bytes.fromhex(save["world_state"]["1002"]), 4, 1)
            state["teams"][key] = [pb_get_varint(slots.get(i, b""), 2) or 0 for i in range(1, 8)] + [pets.get_state(save, config)["active"]]
        _, power = project_team(save, state["teams"][key], config)
        return recharge.ids([*state["teams"][key], power, 140, int(key)]), [], b""
    row = config["personalboss_att"].get(str(values[0]))
    kind = boss_type(state, config)
    cleared = state["cleared"][str(kind)]
    if (not row or row["function"] != kind or row["level"] > cleared + 1
            or row["level"] > save["role_state"]["level"] or state["teams"][str(kind)] is None):
        raise ValueError("请选择当日已解锁难度，并先设置专用阵容")
    remaining = config["vip"]["0"]["personalboss_times"] + state["bought"] - state["used"]
    count = values[1] if opcode == 3705 else 1
    if not 1 <= count <= min(100, remaining):
        raise ValueError("王的男人剩余挑战次数不足")
    if opcode == 3705 and (row["level"] > cleared or save["role_state"]["level"] < 80 and save["role_state"]["vip"] < 5):
        raise ValueError("一键挑战需要80级或VIP5，且只能挑战已通关难度")
    attack, defense, combat_config, pet, _ = rosters(save, state["teams"][str(kind)], row, config)
    rng, gets, won = random.Random(seed), Counter(), 0
    for attempt in range(1, count + 1):
        battle_seed = rng.getrandbits(64)
        report = battle.simulate(attack, defense, combat_config, battle_seed, attack_pet=pet)
        report["meta"]["attack"]["n"] = save["role_name"]
        if report["result"]:
            gets.update(prizes(save, row, row["level"] > state["cleared"][str(kind)], config, state["day"], rng))
            state["cleared"][str(kind)] = max(state["cleared"][str(kind)], row["level"])
            state["used"] += 1
            won += 1
        else:
            break
    reward = activities.build_reward(save, ";".join(f"{cid},{n}" for cid, n in sorted(gets.items()) if n), config) if gets else b""
    save["last_single_boss_battle"] = {"rules": report["rules"], "seed": battle_seed, "target": row["id"],
                                        "won": report["result"], "rounds": report["round"], "attempts": attempt, "wins": won}
    if opcode == 3705:
        return reward + encode_pb_field(12, 2, recharge.ids([attempt, won])), [], reward
    reply = (encode_pb_field(1, 0, int(report["result"])) + encode_pb_field(2, 0, report["star"])
             + encode_pb_field(4, 2, reward) + encode_pb_field(5, 2, json.dumps(report, ensure_ascii=False, separators=(",", ":")).encode()))
    return reply, [], reward
