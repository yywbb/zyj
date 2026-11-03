"""本地公会据点战：定时冻结真实参战阵容，未驻防据点使用配置NPC。"""

import copy
from fractions import Fraction
import secrets

OPCODES = tuple(range(2130, 2148))
MUTATIONS = (2132, 2135, 2136, 2137, 2142, 2146, 2147)


def schedule(config, now):
    day = (now + 28800) // 86400
    weekday = (day + 3) % 7 + 1
    starts = [int(rows["1"]["weektime_open"]) for rows in config["gang2_battleTime"].values()]
    days = [day - (weekday - start) % 7 for start in starts]
    current = max(days)
    base = current * 86400 - 28800
    return current, base


def validate(state):
    from .guild_games import integer

    war = state.get("war")
    if war is None:
        return
    integer(war["day"])
    integer(war["stage"], 0, 2)
    for k in ("owners", "signups", "teams", "inspire", "pending", "finalists"):
        if not isinstance(war[k], dict):
            raise ValueError("公会战存档无效")
    for city, gid in war["owners"].items():
        integer(int(city), 1, 9)
        integer(gid)
    for gid, cities in war["signups"].items():
        integer(int(gid), 1)
        if not isinstance(cities, list) or len(cities) > 2 or len(set(cities)) != len(cities):
            raise ValueError("公会战报名无效")
        for city in cities:
            integer(city, 1, 9)
    for account, team in war["teams"].items():
        integer(int(account), 1, 1000)
        integer(team["point"], 1, 9)
        integer(team["guild"], 1)
        if type(team["identity"]) not in (int, float) or team["identity"] <= 0 or not isinstance(team["snapshot"], dict):
            raise ValueError("公会战阵容身份无效")
    for counts in war["inspire"].values():
        if not isinstance(counts, list) or len(counts) != 2:
            raise ValueError("公会战鼓舞无效")
        for count in counts:
            integer(count, 0, 20)
    if not isinstance(war["fights"], list) or len(war["fights"]) > 2000:
        raise ValueError("公会战战报无效")
    for fight in war["fights"]:
        for k in ("id", "point", "a", "b", "winner"):
            integer(fight[k])
        for item in fight["reports"]:
            bytes.fromhex(item["body"])
    for rewards in war["pending"].values():
        for entry in rewards.values():
            if type(entry["identity"]) not in (int, float) or entry["identity"] <= 0:
                raise ValueError("公会战奖励身份无效")
            for cid, count in entry["items"].items():
                integer(int(cid), 1)
                integer(count, 1, (1 << 31) - 1)


def get_state(state, config, now):
    validate(state)
    day, base = schedule(config, now)
    war = state.setdefault("war", {"day": day, "stage": 0, "owners": {}, "signups": {}, "teams": {}, "inspire": {},
                                   "pending": {}, "fights": [], "finalists": {}})
    return war, day, base


def freeze(save):
    snapshot = copy.deepcopy({k: save[k] for k in ("role_state", "role_name", "pet_state", "guild_skills", "wing_state", "cover_state") if k in save})
    if "cover_state" in snapshot:
        snapshot["cover_state"].update(shop={}, day=0, checked_at=0)
    snapshot["world_state"] = {"1002": save["world_state"]["1002"]}
    return snapshot


def team_roster(team, config, counts):
    from . import battle, pets

    snapshot = team["snapshot"]
    roster, _ = battle.rosters(snapshot, config["copy"]["42101"]["1"], config)
    atk = min(counts[0] // 2 * 5, 50) + counts[1] * 5
    defense = min((counts[0] + 1) // 2 * 5, 50) + counts[1] * 5
    for u in roster.values():
        u["atk"] = u["atk"] * (100 + atk) // 100
        u["def"] = u["def"] * (100 + defense) // 100
    return roster, pets.combat(snapshot, config)


def duel(war, city, attacker, defender, state, saves, config):
    from . import arena, battle, cheer
    from .guild_boss import battle_result

    groups = {}
    for g in (attacker, defender):
        groups[g] = [(int(a), t) for a, t in war["teams"].items() if t["guild"] == g and t["point"] == city
                     and saves.get(int(a), {}).get("created_at") == t["identity"]
                     and str(a) in state["guilds"].get(str(g), {}).get("members", {})]
        groups[g].sort(key=lambda item: (-item[1]["snapshot"]["role_state"]["power"], item[0]))
    if not groups[attacker]:
        return defender
    npc = not groups[defender]
    if npc:
        groups[defender] = [(0, {"npc": int(n)}) for n in config["gang2_cityaward"][str(city)]["npc"].strip(";").split(";")]
    fight = {"id": len(war["fights"]) + 1, "point": city, "a": attacker, "b": defender, "winner": defender, "reports": []}
    ai, di, streak_a, streak_d = 0, 0, 0, 0
    while ai < len(groups[attacker]) and di < len(groups[defender]):
        a, ta = groups[attacker][ai]
        b, td = groups[defender][di]
        attack, pet_a = team_roster(ta, config, war["inspire"].get(str(a), [0, 0]))
        if "npc" in td:
            point = config["athletics_copy2"][str(td["npc"])]
            _, defense = arena.rosters(ta["snapshot"], point, config)
            pet_b = None
            name = config["gang2_cityaward"][str(city)]["npc_name"]
        else:
            defense, pet_b = team_roster(td, config, war["inspire"].get(str(b), [0, 0]))
            name = td["snapshot"]["role_name"]
        castle = config["gang2_cityaward"][str(city)]
        for unit in defense.values():
            unit["atk"] = int(unit["atk"] * (1 + Fraction(str(castle["att"]))))
            unit["def"] += castle["def"] // len(defense)
        seed = secrets.randbits(64)
        report = battle.simulate(attack, defense, config, seed, attack_pet=pet_a, defense_pet=pet_b,
                                 attack_cheer=cheer.combat(ta["snapshot"], config),
                                 defense_cheer=() if "npc" in td else cheer.combat(td["snapshot"], config))
        report["meta"]["attack"]["n"] = ta["snapshot"]["role_name"]
        report["meta"]["defense"]["n"] = name
        fight["reports"].append({"a": a, "b": b, "name_a": ta["snapshot"]["role_name"], "name_b": name,
                                 "seed": seed, "body": battle_result(report).hex()})
        if report["result"]:
            di += 1
            streak_a, streak_d = streak_a + 1, 0
            if streak_a >= 5 + war["inspire"].get(str(a), [0, 0])[1]:
                ai, streak_a = ai + 1, 0
        else:
            ai += 1
            streak_d, streak_a = streak_d + 1, 0
            if streak_d >= 5 + war["inspire"].get(str(b), [0, 0])[1]:
                di, streak_d = di + 1, 0
    winner = attacker if di == len(groups[defender]) else defender
    fight["winner"] = winner
    war["fights"].append(fight)
    return winner


def settle(state, saves, config, now):
    from .guild_games import pairs

    war, day, base = get_state(state, config, now)
    old_base = war["day"] * 86400 - 28800
    if now >= old_base + 21 * 3600 and war["stage"] < 1:
        for city in range(1, 10):
            candidates = sorted(int(g) for g, points in war["signups"].items() if city in points and g in state["guilds"])
            owner = war["owners"].get(str(city), 0)
            candidates = [g for g in candidates if g != owner]
            # 第一轮挑战者两两真实对战；次轮胜者再与驻防方争夺据点。
            finalists = []
            for index in range(0, len(candidates), 2):
                a = candidates[index]
                if index + 1 < len(candidates):
                    a = duel(war, city, a, candidates[index + 1], state, saves, config)
                finalists.append(a)
            war["finalists"][str(city)] = finalists
        war["stage"] = 1
    if now >= old_base + 22 * 3600 and war["stage"] < 2:
        for city in range(1, 10):
            owner = war["owners"].get(str(city), 0)
            if str(owner) not in state["guilds"]:
                owner = 0
            for attacker in war["finalists"].get(str(city), []):
                owner = duel(war, city, attacker, owner, state, saves, config)
            war["owners"][str(city)] = owner
            if not owner:
                continue
            for a, team in war["teams"].items():
                if team["guild"] != owner or team["point"] != city or saves.get(int(a), {}).get("created_at") != team["identity"]:
                    continue
                post = state["guilds"][str(owner)]["members"].get(a, {}).get("post")
                if post is None:
                    continue
                prize = config["gang2_cityaward"][str(city)][{0: "member", 1: "president", 2: "vice_president"}[post]]
                war["pending"].setdefault(a, {})[f"{war['day']}:{city}"] = {"identity": team["identity"], "point": city,
                                                                            "items": {str(c): n for c, n in pairs(prize).items()}}
        war["stage"] = 2
    if day > war["day"]:
        war.update(day=day, stage=0, signups={}, teams={}, inspire={}, fights=[], finalists={})
    return war, base


def benefit(state, viewer, config, now):
    from . import guild

    gid, row = guild.membership(state, viewer)
    war = state.get("war", {})
    cities = [int(c) for c, g in war.get("owners", {}).items() if str(g) == gid]
    return config["gang2_cityaward"][str(min(cities))]["bonus_id"] if cities else 0


def effect(save, config, kind):
    if not save.get("guild_profit"):
        return 0
    row = config["gang2battle_youhua_type"].get(str(save.get("guild_profit", 0)), {})
    if row.get("add") != kind:
        return 0
    text = row["effect"]
    return int(text.split(":")[-1])


def prepare(opcode, body, state, gid, save, saves, viewer, config, now):
    from . import guild
    from .guild_games import award, pairs, param

    war, base = settle(state, saves, config, now)
    row, account = state["guilds"][gid], str(viewer)
    cities = war["signups"].get(gid, [])
    phase = 1 if base + 8 * 3600 <= now < base + 20 * 3600 else 2 if base + 20 * 3600 <= now < base + 21 * 3600 else 3 if base + 21 * 3600 <= now < base + 22 * 3600 else 0
    if opcode == 2130:
        guild.request_ids(body, 0)
        pending = [e["point"] for e in war["pending"].get(account, {}).values() if e["identity"] == save["created_at"]]
        points = cities + [0, 0]
        return guild.message(0, guild.ids([int(account in war["inspire"]), int(account in war["teams"]), 0, points[0], points[1], pending[0] if pending else 0, int(bool(pending))])) + guild.message(1,
            param([(war["owners"].get(str(city), 0), state["guilds"].get(str(war["owners"].get(str(city), 0)), {}).get("name", "")) for city in range(1, 10)])), [], b""
    if opcode in (2144, 2145):
        guild.request_ids(body, 0)
        return guild.ids([benefit(state, viewer, config, now)]), [], b""
    if opcode == 2142:
        city, = guild.request_ids(body, 1)
        pending = war["pending"].get(account, {})
        selected = [(k, e) for k, e in pending.items() if e["point"] == city and e["identity"] == save["created_at"]]
        if not selected:
            raise ValueError("该据点没有可领取奖励")
        gets = {}
        for key, entry in selected:
            for cid, count in entry["items"].items():
                gets[int(cid)] = gets.get(int(cid), 0) + count
            del pending[key]
        reward = award(save, row, gets, config, now)
        return reward, [], reward
    if opcode in (2136, 2137, 2146, 2147):
        guild.request_ids(body, 0)
        if phase != 2:
            raise ValueError("请在20至21点战前准备阶段操作")
        if not cities:
            raise ValueError("公会尚未报名")
        counts = war["inspire"].setdefault(account, [0, 0])
        if opcode == 2147:
            if account in war["teams"]:
                raise ValueError("已经参战，无需重复一键参战")
            point = cities[0]
            join(war, row, gid, save, viewer, point, config, now)
            return guild.ids([0]), list(pairs(config["global_kv"]["quick_war_cost"]["value"]).items()), b""
        if opcode == 2146:
            if counts == [20, 20]:
                raise ValueError("鼓舞已经达到上限")
            cost = list(pairs(config["global_kv"]["quick_Inspire_cost"]["value"]).items())
            counts[:] = [20, 20]
            return guild.ids([0]), [(c, n) for c, n in cost if n], b""
        index = int(opcode == 2137)
        name = "gold" if index else "silver"
        if counts[index] >= int(config["global_kv"][f"{name}_inspire_times"]["value"]):
            raise ValueError("鼓舞次数已满")
        counts[index] += 1
        atk, defense = buffs(counts)
        return guild.ids([counts[index], atk, defense, 5 + counts[1]]), [(1001 if index else 1000, int(config["global_kv"][f"{name}_inspire_cost"]["value"]))], b""
    count = {2131: 1, 2132: 1, 2133: 1, 2134: 1, 2135: 2, 2138: 1, 2139: 2, 2140: 2, 2141: 3, 2143: 1}[opcode]
    values = guild.request_ids(body, count)
    city = values[0]
    if str(city) not in config["gang2_cityaward"]:
        raise ValueError("公会据点不存在")
    owner = war["owners"].get(str(city), 0)
    owned = state["guilds"].get(str(owner))
    if opcode == 2132:
        if (phase != 1 or row["members"][account]["post"] not in (1, 2) or city in cities or len(cities) >= 2
                or guild.progress(row, config)[0] < config["gang2_cityaward"][str(city)]["level"]
                or now - row["created_at"] < int(config["global_kv"]["gang2_signup_time"]["value"]) * 86400):
            raise ValueError("报名时间、职务、公会等级/创建天数或据点数量不符合要求")
        war["signups"].setdefault(gid, []).append(city)
        return guild.ids([0]), [], b""
    if opcode == 2131:
        status = (2 if city in cities else 1) if phase == 1 else 5 if phase == 2 and city in cities else 6 if war["fights"] else 0
        return param([(owner, owned["name"] if owned else "城防守卫军"), guild.progress(owned, config)[0] if owned else 0,
                       guild.power(owned, saves) if owned else 0, config["gang2_cityaward"][str(city)]["def"],
                       int(config["gang2_cityaward"][str(city)]["att"] * 100), 2 - len(cities), status,
                       max(0, base + 20 * 3600 - now), 0]), [], b""
    if opcode == 2133:
        data = [int(city in cities)]
        for g, points in war["signups"].items():
            r = state["guilds"].get(g)
            if r and city in points:
                data += [(int(g), r["name"]), guild.progress(r, config)[0], guild.power(r, saves), 0]
        return param(data), [], b""
    if opcode == 2135:
        if phase != 2 or values[1] not in (0, 1):
            raise ValueError("仅可在战前准备时参战/退出")
        if values[1]:
            join(war, row, gid, save, viewer, city, config, now)
        else:
            war["teams"].pop(account, None)
        return guild.ids([0]), [], b""
    if opcode in (2134, 2143):
        entries = [(int(a), t) for a, t in war["teams"].items() if t["point"] == city]
        members = param([city, *[v for a, t in sorted(entries) for v in ((guild.role_id(a, viewer, saves), t["snapshot"]["role_name"]),
                        t["snapshot"]["role_state"]["profile"], 1 if t["guild"] == owner else 2)]])
        if opcode == 2143:
            return members, [], b""
        counts = war["inspire"].get(account, [0, 0])
        return guild.message(0, guild.ids([war["teams"].get(account, {}).get("point", 0), *counts, *buffs(counts), 5 + counts[1]])) + guild.message(1,
            param([1 if phase == 2 else 2, max(0, base + 21 * 3600 - now), (owner, owned["name"] if owned else "城防守卫军"), (int(gid), row["name"])])) + guild.message(2, members), [], b""
    fights = [f for f in war["fights"] if f["point"] == city]
    if opcode == 2138:
        return b"".join(guild.message(i, param([f["id"], (f["a"], state["guilds"].get(str(f["a"]), {}).get("name", "已解散公会")), int(f["winner"] == f["a"]),
            (f["b"], state["guilds"].get(str(f["b"]), {}).get("name", "城防守卫军")), int(f["winner"] == f["b"])])) for i, f in enumerate(fights, 1)), [], b""
    fight = next((f for f in fights if f["id"] == values[1]), None)
    if not fight:
        raise ValueError("所选战报不存在")
    if opcode == 2140:
        return b"".join(guild.message(i, param([fight["id"], (1000000 + r["a"], r["name_a"]), (1000000 + r["b"] if r["b"] else 0, r["name_b"])]))
                        for i, r in enumerate(fight["reports"], 1)), [], b""
    index = values[2] if opcode == 2141 else 1
    if not 1 <= index <= len(fight["reports"]):
        raise ValueError("所选个人战报不存在")
    return bytes.fromhex(fight["reports"][index - 1]["body"]), [], b""


def buffs(counts):
    return min(counts[0] // 2 * 5, 50) + counts[1] * 5, min((counts[0] + 1) // 2 * 5, 50) + counts[1] * 5


def join(war, row, gid, save, viewer, city, config, now):
    if (city not in war["signups"].get(gid, [])
            or now - row["members"][str(viewer)]["joined_at"] < int(config["global_kv"]["gang2_join_time"]["value"]) * 86400):
        raise ValueError("据点尚未报名或入会未满一天")
    from . import battle
    snapshot = freeze(save)
    battle.rosters(snapshot, config["copy"]["42101"]["1"], config)
    war["teams"][str(viewer)] = {"guild": int(gid), "point": city, "identity": save["created_at"], "snapshot": snapshot}
