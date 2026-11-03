"""真实共享HP公会Boss；当次伤害和击杀奖由同一份战报结算。"""

from fractions import Fraction
import json
import secrets

from .protocol import encode_pb_field

OPCODES = tuple(range(4840, 4847))
MUTATIONS = (4843, 4844)


def validate(row):
    from .guild_games import integer

    boss = row.get("boss")
    if boss is None:
        return
    for key in ("cid", "hp", "born", "revive", "round", "inspire"):
        integer(boss[key])
    if not 32001 <= boss["cid"] <= 32060 or boss["inspire"] > 5:
        raise ValueError("公会Boss等级/鼓舞无效")
    for key in ("damage", "pending"):
        if not isinstance(boss[key], dict) or len(boss[key]) > 1000:
            raise ValueError("公会Boss伤害记录无效")
        for account, entry in boss[key].items():
            integer(int(account), 1, 1000)
            if type(entry["identity"]) not in (int, float) or entry["identity"] <= 0:
                raise ValueError("公会Boss身份无效")
            if key == "damage":
                integer(entry["amount"])
                integer(entry["contribution"], high=(1 << 31) - 1)
            else:
                for cid, count in entry["items"].items():
                    integer(int(cid), 1, (1 << 31) - 1)
                    integer(count, 1, (1 << 31) - 1)


def settle(row, config, now):
    validate(row)
    boss = row.setdefault("boss", {"cid": 32001, "hp": config["gang2_boss"]["32001"]["hp"], "born": now,
        "revive": 0, "round": 1, "inspire": 0, "damage": {}, "pending": {}})
    if not boss["hp"] and now >= boss["revive"]:
        fast = boss["revive"] - int(config["global_kv"]["sociaty_boss_revive"]["value"]) * 60 - boss["born"] <= int(config["global_kv"]["sociaty_boss_survival_time"]["value"]) * 3600
        boss["cid"] = min(32060, boss["cid"] + int(fast))
        boss.update(hp=config["gang2_boss"][str(boss["cid"])]["hp"], born=now, revive=0,
                    round=boss["round"] + 1, inspire=0, damage={})
    return boss


def personal(save, now):
    from .guild_games import integer

    day = (now + 28800) // 86400
    state = save.setdefault("guild_boss", {"day": day, "used": 0, "bought": 0})
    for k in ("day", "used", "bought"):
        integer(state[k], high=(1 << 31) - 1)
    if day > state["day"]:
        state.update(day=day, used=0, bought=0)
    return state


def battle_result(report, reward=b""):
    return (encode_pb_field(1, 0, int(report["result"])) + encode_pb_field(2, 0, report["star"])
        + encode_pb_field(4, 2, reward) + encode_pb_field(5, 2, json.dumps(report, ensure_ascii=False, separators=(",", ":")).encode()))


def prepare(opcode, body, state, gid, save, saves, viewer, config, now):
    from . import battle, cheer, guild, guild_war, pets
    from .guild_games import award, pairs, param

    guild.request_ids(body, 0)
    row = state["guilds"][gid]
    if guild.progress(row, config)[0] < int(config["global_kv"]["sociaty_boss_class"]["value"]):
        raise ValueError("公会等级不足，尚未开启Boss")
    boss = settle(row, config, now)
    own = personal(save, now)
    key = str(viewer)
    pending = boss["pending"].get(key)
    gets, prize = {}, b""
    if pending:
        if pending["identity"] == save["created_at"]:
            gets = {int(cid): count for cid, count in pending["items"].items()}
        del boss["pending"][key]
    if opcode != 4844:
        prize = award(save, row, gets, config, now) if gets else b""
    if opcode in (4840, 4845, 4846):
        reply = param([boss["cid"], str(boss["hp"]), max(0, boss["revive"] - now), boss["inspire"], boss["inspire"] * 20,
                       max(0, 3 + own["bought"] - own["used"])]) if opcode == 4840 else param([int(not boss["hp"]), str(boss["hp"]), (0, "")]) if opcode == 4845 else b""
        return reply, [], prize
    if opcode == 4841:
        entries = [(g, r, sum(d["amount"] for d in r.get("boss", {}).get("damage", {}).values())) for g, r in state["guilds"].items()]
        entries.sort(key=lambda v: (-v[2], int(v[0])))
        def projection(index, g, r, damage):
            leader = next(a for a, m in r["members"].items() if m["post"] == 1)
            return param([(index, r["name"]), (int(g), saves[int(leader)]["role_name"]), (len(r["members"]), r["content"]), str(damage)])
        index = next(i for i, (g, _, _) in enumerate(entries, 1) if g == gid)
        return projection(index, *entries[index - 1]) + b"".join(projection(i, *e) for i, e in enumerate(entries, 1) if e[2]), [], prize
    if opcode == 4842:
        entries = [(int(a), e) for a, e in boss["damage"].items() if saves.get(int(a), {}).get("created_at") == e["identity"]]
        entries.sort(key=lambda v: (-v[1]["amount"], v[0]))
        return b"".join(param([i, saves[a]["role_state"]["vip"], saves[a]["role_state"]["level"],
            (saves[a]["role_state"]["profile"], saves[a]["role_name"]), 35501, 35001, e["contribution"]]) for i, (a, e) in enumerate(entries, 1)), [], prize
    if not boss["hp"]:
        raise ValueError("Boss正在复活，请稍后挑战")
    if now - row["members"][key]["joined_at"] < int(config["global_kv"]["sociaty_boss_authority"]["value"]) * 3600:
        raise ValueError("加入公会满24小时才可参与Boss")
    if opcode == 4843:
        setting = config["gang2_boss_encouraging"].get(str(boss["inspire"] + 1))
        if not setting:
            raise ValueError("本轮公会鼓舞已满")
        boss["inspire"] += 1
        prize += award(save, row, {1006: setting["contribution"]}, config, now)
        return guild.ids([0]), list(pairs(setting["money"]).items()), prize
    if own["used"] >= 3 + own["bought"]:
        raise ValueError("今日Boss挑战次数已用完")
    setting = config["gang2_boss"][str(boss["cid"])]
    attack, _ = battle.rosters(save, config["copy"]["42101"]["1"], config)
    for unit in attack.values():
        unit["adddmgpct"] = Fraction(boss["inspire"], 5)
        unit["atk"] = unit["atk"] * (100 + guild_war.effect(save, config, 2)) // 100
    general = dict(setting, init_cid=setting["bossid"])
    combat = {**config, "general": {**config["general"], str(boss["cid"]): general}}
    unit = {name: setting[name] for name in ("atk", "def", "hp", "speed", "critical", "dodge", "parry", "resilience", "hit", "arp", "criticaldmg")}
    unit.update(hp=boss["hp"], cid=boss["cid"], iid=boss["cid"], level=setting["level"], advance=0,
                skill=setting["skillid"], skilllevel=0, initial_ap=4, npc=True, boss=True,
                adddmgpct=Fraction(str(setting["adddmgpct-correct"])) / 100)
    seed = secrets.randbits(64)
    report = battle.simulate(attack, {2: unit}, combat, seed, attack_pet=pets.combat(save, config), attack_cheer=cheer.combat(save, config))
    report["meta"]["attack"]["n"] = save["role_name"]
    report["meta"]["defense"]["n"] = setting["name"]
    remaining = sum(v["h"] for v in report["endmeta"]["defense"].values())
    damage = boss["hp"] - remaining
    boss["hp"] = remaining
    own["used"] += 1
    coefficient = next(Fraction(str(r["coefficient"])) for r in sorted(config["gang2_boss_contribution"].values(), key=lambda r: r["id"])
                       if Fraction(damage, setting["hp"]) <= Fraction(str(r["interval"])))
    contribution = int(setting["foundation_award"] * coefficient) if damage else 0
    drops = battle.drops({"drop": 0, **{f"drop{i}": 0 for i in range(1, 4)}, "randdrop": setting["awards"],
                           "randdropprob": 100 if damage else 0, "randdrop1": 0, "randdropprob1": 0}, False, config, seed ^ 0xB055)
    drops[1006] = contribution
    for cid, count in gets.items():
        drops[cid] = drops.get(cid, 0) + count
    prize = award(save, row, drops, config, now)
    entry = boss["damage"].setdefault(key, {"identity": save["created_at"], "amount": 0, "contribution": 0})
    if entry["identity"] != save["created_at"]:
        entry.update(identity=save["created_at"], amount=0, contribution=0)
    entry["amount"] += damage
    entry["contribution"] += contribution
    if not remaining:
        boss["revive"] = now + int(config["global_kv"]["sociaty_boss_revive"]["value"]) * 60
        ranks = sorted(boss["damage"].items(), key=lambda item: (-item[1]["amount"], int(item[0])))
        for rank, (account, record) in enumerate(ranks, 1):
            if row["members"].get(account, {}).get("identity") != record["identity"]:
                continue
            bracket = next(r for r in sorted(config["gang2_boss_reward"].values(), key=lambda r: r["rank"]) if rank <= r["rank"])
            pending = boss["pending"].setdefault(account, {"identity": record["identity"], "items": {}})
            if pending["identity"] != record["identity"]:
                pending.update(identity=record["identity"], items={})
            for cid, count in pairs(bracket["reward"]).items():
                pending["items"][str(cid)] = pending["items"].get(str(cid), 0) + count
        # 本次击杀者也走持久待领奖，下次读取领取，其他成员不跨文件写入。
    save["last_guild_boss"] = {"seed": seed, "round": boss["round"], "cid": boss["cid"], "damage": damage, "won": report["result"]}
    battle_body = battle_result(report, prize)
    return encode_pb_field(6, 2, battle_body), [], prize
