"""真实本地群仙屠龙；共享HP、冻结排名邮件和角色消耗以同身份收据衔接。"""

import copy
from fractions import Fraction
import json
import re
import secrets

from . import battle, cheer, friends, guild, pets, storage
from .guild_boss import battle_result
from .guild_games import integer, pairs
from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint, pb_set_varint

QUERIES = (3400, 3402, 3403, 3404, 3410, 3412, 3413, 3414)
MUTATIONS = (3401, 3411)
OPCODES = QUERIES + MUTATIONS
HOURS = {"1": 12, "2": 21}


def get_state(save):
    state = save.get("world_boss_state", {"receipt": "", "claimed": [], "deleted": []})
    try:
        if not isinstance(state["receipt"], str) or state["receipt"] and not re.fullmatch(r"[a-f0-9]{32}", state["receipt"]):
            raise ValueError
        for name in ("claimed", "deleted"):
            values = state[name]
            if not isinstance(values, list) or len(set(values)) != len(values):
                raise ValueError
            for mid in values:
                integer(mid, 600000001, 699999999)
        if not set(state["deleted"]) <= set(state["claimed"]):
            raise ValueError
    except (KeyError, TypeError, ValueError):
        raise ValueError("屠龙角色收据或邮件状态无效") from None
    return state


def validate(state):
    try:
        if set(state) != {"version", "checked_at", "next_mail", "next_event", "bosses", "players", "pending"} or type(state["version"]) is not int or state["version"] != 1:
            raise ValueError
        integer(state["checked_at"], high=(1 << 31) - 1)
        integer(state["next_mail"], 600000001, 700000000)
        integer(state["next_event"], 1, (1 << 31) - 1)
        if set(state["bosses"]) != {"1", "2"} or not isinstance(state["players"], dict) or len(state["players"]) > 1000:
            raise ValueError
        for kind, boss in state["bosses"].items():
            first = 30001 if kind == "1" else 31001
            integer(boss["next_cid"], first, first + 119)
            for name in ("period", "history"):
                period = boss[name]
                if period is None:
                    continue
                integer(period["day"])
                integer(period["cid"], first, first + 119)
                integer(period["hp"])
                integer(period["ended"])
                integer(period["killer"], 0, 1000)
                if bool(period["killer"]) != (period["hp"] == 0) or name == "history" and not period["ended"]:
                    raise ValueError
                if not isinstance(period["damage"], dict) or len(period["damage"]) > 1000 or not isinstance(period["events"], list) or len(period["events"]) > 100:
                    raise ValueError
                for account, row in period["damage"].items():
                    friends.account_id(account)
                    if account not in state["players"]:
                        raise ValueError
                    friends.identity(row["identity"])
                    for key in ("amount", "ready_at"):
                        integer(row[key])
                    integer(row["count"], 1, (1 << 31) - 1)
                    profile = bytes.fromhex(row["profile"])
                    if pb_get_varint(profile, 1) != 1000000 + int(account):
                        raise ValueError
                    for field in (3, 4, 5):
                        integer(pb_get_varint(profile, field))
                    if not any(n == 2 and w == 2 and v for n, w, v in iter_pb_fields(profile)):
                        raise ValueError
                if period["killer"] and str(period["killer"]) not in period["damage"]:
                    raise ValueError
                seen = set()
                for event in period["events"]:
                    integer(event["id"], 1, state["next_event"] - 1)
                    integer(event["account"], 1, 1000)
                    integer(event["count"], 1, (1 << 31) - 1)
                    integer(event["damage"])
                    integer(event["kill"], 0, 1)
                    if event["id"] in seen or not isinstance(event["name"], str) or type(event["method"]) is not int or event["method"] not in (0, 2, 10):
                        raise ValueError
                    seen.add(event["id"])
        mail_ids = set()
        for account, row in state["players"].items():
            friends.account_id(account)
            friends.identity(row["identity"])
            if not isinstance(row["mails"], dict):
                raise ValueError
            for mid, mail in row["mails"].items():
                integer(int(mid), 600000001, state["next_mail"] - 1)
                if mid != str(int(mid)) or mid in mail_ids or not pairs(mail["reward"]):
                    raise ValueError
                mail_ids.add(mid)
                integer(mail["second"])
                if not isinstance(mail["title"], str) or not isinstance(mail["content"], str):
                    raise ValueError
        pending = state["pending"]
        if pending is not None:
            integer(pending["account"], 1, 1000)
            friends.identity(pending["identity"])
            if not re.fullmatch(r"[a-f0-9]{32}", pending["token"]) or pending["after"]["pending"] is not None:
                raise ValueError
            validate(pending["after"])
    except (KeyError, TypeError, ValueError, AttributeError, OverflowError):
        raise ValueError("屠龙共享记录损坏，请恢复world_boss.json与角色的配套备份") from None


def load(path, saves, now):
    if path.exists():
        try:
            state = json.loads(path.read_bytes())
        except (ValueError, UnicodeError):
            raise ValueError("屠龙共享记录损坏，不能重建场次") from None
    else:
        if any(save.get("world_boss_state") for save in saves.values()):
            raise ValueError("屠龙共享记录丢失，请恢复world_boss.json备份")
        state = {"version": 1, "checked_at": now, "next_mail": 600000001, "next_event": 1,
                 "bosses": {k: {"next_cid": cid, "period": None, "history": None} for k, cid in (("1", 30001), ("2", 31001))},
                 "players": {}, "pending": None}
    validate(state)
    return state


def write(path, state):
    validate(state)
    storage.atomic_write(path, json.dumps(state, ensure_ascii=False, allow_nan=False).encode())


def recover(state, saves):
    pending = state["pending"]
    if pending:
        save = saves.get(pending["account"], {})
        if save.get("created_at") == pending["identity"] and get_state(save)["receipt"] == pending["token"]:
            after = pending["after"]
            state.clear()
            state.update(after)
        state["pending"] = None
    for account, save in saves.items():
        if save.get("world_boss_state"):
            own = state["players"].get(str(account), {})
            if own.get("identity") != save["created_at"] or any(str(mid) not in own["mails"] for mid in get_state(save)["claimed"]):
                raise ValueError("屠龙角色与共享记录不一致，请恢复配套备份")


def stage(state, before, account, save):
    token = secrets.token_hex(16)
    after = copy.deepcopy(state)
    state.clear()
    state.update(copy.deepcopy(before))
    state["pending"] = {"account": account, "identity": save["created_at"], "token": token, "after": after}
    save["world_boss_state"]["receipt"] = token


def ranks(period):
    return sorted(((int(a), row) for a, row in period["damage"].items() if row["amount"]), key=lambda item: (-item[1]["amount"], item[0])) if period else []


def times(day, kind):
    start = day * 86400 - 28800 + HOURS[kind] * 3600
    return start, start + 1800


def finish(state, kind, saves, config, now):
    boss = state["bosses"][kind]
    period = boss["period"]
    if not period or period["ended"] or period["hp"] and now < times(period["day"], kind)[1]:
        return
    period["ended"] = now if not period["hp"] else times(period["day"], kind)[1]
    table = config["boss2_rewards" + kind]
    for rank, (account, row) in enumerate(ranks(period), 1):
        if saves.get(account, {}).get("created_at") != row["identity"]:
            continue
        brackets = [r for r in sorted(table.values(), key=lambda r: r["rank"]) if rank <= r["rank"]]
        gets = pairs(brackets[0]["reward"]) if brackets else {}
        if account == period["killer"]:
            for cid, count in pairs(next(r["reward"] for r in table.values() if r["rank"] == 0)).items():
                gets[cid] = gets.get(cid, 0) + count
        if not gets:
            continue
        if state["next_mail"] >= 700000000:
            raise ValueError("屠龙邮件编号已用尽，请维护归档")
        own = state["players"][str(account)]
        if own["identity"] != row["identity"]:
            raise ValueError("屠龙奖励身份不一致")
        own["mails"][str(state["next_mail"])] = {"reward": ";".join(f"{cid},{count}" for cid, count in sorted(gets.items())),
            "title": "本地群仙屠龙排名奖励", "content": f"第{period['day']}日第{kind}场，伤害排名{rank}；" + ("含最后一击奖励。" if account == period["killer"] else "按实际伤害排名结算。"), "second": period["ended"]}
        state["next_mail"] += 1
    boss["history"] = copy.deepcopy(period)
    boss["next_cid"] = min((30120 if kind == "1" else 31120), period["cid"] + int(not period["hp"]))


def settle(state, saves, config, now):
    day = (now + 28800) // 86400
    for kind, boss in state["bosses"].items():
        finish(state, kind, saves, config, now)
        period = boss["period"]
        start, end = times(day, kind)
        if start <= now < end and (not period or period["day"] < day):
            cid = boss["next_cid"]
            boss["period"] = {"day": day, "cid": cid, "hp": config["boss2"][str(cid)]["hp"], "ended": 0, "killer": 0, "damage": {}, "events": []}
        if boss["period"] and boss["period"]["hp"] > config["boss2"][str(boss["period"]["cid"])]["hp"]:
            raise ValueError("屠龙剩余HP超过配置上限")


def reward_mails(state, viewer, identity):
    own = state["players"].get(str(viewer), {})
    return {int(mid): {**row, "gets": list(pairs(row["reward"]).items())} for mid, row in own.get("mails", {}).items()} if own.get("identity") == identity else {}


def simulate(save, cid, hp, method, config, seed):
    from . import guild_war

    save = copy.deepcopy(save)
    setting = config["boss2"][str(cid)]
    attack, _ = battle.rosters(save, config["copy"]["42101"]["1"], config)
    for unit in attack.values():
        unit["atk"] = unit["atk"] * (100 + guild_war.effect(save, config, 2)) // 100
        if method == 10:
            unit["atk"] *= 2
    combat = {**config, "general": {**config["general"], str(cid): dict(setting, init_cid=cid)}}
    unit = {k: setting[k] for k in ("atk", "def", "hp", "speed", "critical", "dodge", "parry", "resilience", "hit", "arp", "criticaldmg")}
    unit.update(hp=hp, cid=cid, iid=cid, level=setting["boss_level"], advance=0, skill=setting["skillid"], skilllevel=0,
                initial_ap=setting["ap"], npc=True, boss=True,
                adddmgpct=Fraction(str(setting["adddmgpct-correct"])), subdmgpct=Fraction(str(setting["subdmgpct-correct"])))
    report = battle.simulate(attack, {2: unit}, combat, seed, attack_pet=pets.combat(save, config), attack_cheer=cheer.combat(save, config))
    report["meta"]["attack"]["n"], report["meta"]["defense"]["n"] = save["role_name"], setting["name"]
    return report


def request(opcode, save, body, config):
    fields = list(iter_pb_fields(body))
    values = [v for _, _, v in fields]
    if (opcode not in OPCODES or opcode in QUERIES and body or opcode in MUTATIONS and
            (len(fields) != 2 or any((n, w) != (1, 0) for n, w, _ in fields) or values[0] not in (0, 2, 10) or values[1] not in (0, 1))):
        raise ValueError("屠龙请求参数无效")
    if not save.get("has_role") or save["role_state"]["level"] < config["build"]["21"]["level"]:
        raise ValueError("屠龙需要队伍21级")
    if values and values[1] and not (config["vip"][str(save["role_state"]["vip"])]["b_sjbszd"] or save["role_state"]["level"] >= int(config["global_kv"]["worldboss_autolv"]["value"])):
        raise ValueError("自动屠龙需要队伍45级或VIP5")
    return values


def prepare(opcode, body, state, saves, account, config, now):
    from . import achievements, recruit

    save = saves[account]
    values = request(opcode, save, body, config)
    kind = "1" if opcode < 3410 else "2"
    key = str(account)
    own = state["players"].get(key)
    if not own or own["identity"] != save["created_at"]:
        state["players"][key] = {"identity": save["created_at"], "mails": {}}
    save["world_boss_state"] = copy.deepcopy(get_state(save))
    settle(state, saves, config, now)
    boss = state["bosses"][kind]
    period = boss["period"]
    current = period if period and period["day"] == (now + 28800) // 86400 else None
    entry = (current or {}).get("damage", {}).get(key, {})
    if entry.get("identity") != save["created_at"]:
        entry = {}
    active = bool(current and not current["ended"])
    reward, report, damage, killed, cost = b"", None, 0, 0, 0
    if opcode in MUTATIONS:
        if not active:
            raise ValueError("本场屠龙未开启、已经结束或Boss已被击杀")
        method, _ = values
        cooling = entry.get("ready_at", 0) > now
        if method == 0 and cooling or method == 2 and not cooling:
            raise ValueError("冷却中请等待或选择复活；冷却结束无需立即复活费用")
        cost = 5 if method == 2 else int(config["global_kv"]["worldboss_gold"]["value"]) if method == 10 else 0
        if save["role_state"]["gold"] < cost:
            raise ValueError("元宝不足，未进行屠龙挑战")
        seed = secrets.randbits(64)
        report = simulate(save, current["cid"], current["hp"], method, config, seed)
        remaining = sum(unit["h"] for unit in report["endmeta"]["defense"].values())
        damage = current["hp"] - remaining
        integer(damage, 0, current["hp"])
        current["hp"], killed = remaining, int(remaining == 0)
        if not entry:
            entry = {"identity": save["created_at"], "amount": 0, "count": 0, "ready_at": 0, "profile": ""}
            current["damage"][key] = entry
        entry.update(amount=entry["amount"] + damage, count=entry["count"] + 1, ready_at=now + 60,
                     profile=friends.player_body(account, -1, saves).hex())
        if killed:
            current["killer"] = account
        current["events"].append({"id": state["next_event"], "account": account, "name": save["role_name"], "count": entry["count"], "damage": damage, "kill": killed, "method": method})
        current["events"] = current["events"][-100:]
        state["next_event"] += 1
        setting = config["boss2"][str(current["cid"])]
        drops = battle.drops({"drop": 0, **{f"drop{i}": 0 for i in range(1, 4)}, "randdrop": setting["awards"],
            "randdropprob": 100 if damage else 0, "randdrop1": 0, "randdropprob1": 0}, False, config, seed ^ 0xDB055)
        reward = recruit.build_reward(save, sorted(drops.items()), config)
        achievements.record(save, "worldbosscount", 1, config)
        save["last_world_boss"] = {"seed": seed, "day": current["day"], "cid": current["cid"], "method": method, "damage": damage, "won": report["result"]}
        finish(state, kind, saves, config, now)
        active = not current["ended"]
    viewer = account
    def player_body(account, row):
        raw = pb_set_varint(bytes.fromhex(row["profile"]), 7, row["amount"])
        if account == viewer and row["identity"] == save["created_at"]:
            raw = pb_set_varint(raw, 1, guild.role_id(account, account, saves))
        return raw
    if opcode % 10 in (0, 1):
        cid = current["cid"] if current else boss["next_cid"]
        reply = b"".join(encode_pb_field(n, 0, v) for n, v in ((1, int(active)), (2, damage), (3, killed),
            (4, max(0, entry.get("ready_at", 0) - now) if active else 0), (7, entry.get("count", 0)),
            (8, entry.get("amount", 0)), (9, current["hp"] if current else 0), (10, config["boss2"][str(cid)]["hp"])))
        reply += b"".join(encode_pb_field(5, 2, player_body(a, r)) for a, r in ranks(current))
        if report:
            reply += encode_pb_field(6, 2, battle_result(report, reward))
    elif opcode % 10 in (2, 4):
        selected = current if opcode % 10 == 2 else boss["history"]
        reply = b"".join(encode_pb_field(1, 2, player_body(a, r)) for a, r in ranks(selected))
        if opcode % 10 == 4:
            killer = selected["killer"] if selected else 0
            if killer:
                reply += encode_pb_field(2, 2, player_body(killer, selected["damage"][str(killer)]))
            reply += encode_pb_field(3, 0, selected["ended"] if selected else 0)
    else:
        reply = encode_pb_field(2, 0, current["hp"] if current else 0)
        for event in (current or {}).get("events", []):
            info = b"".join(encode_pb_field(n, 0, v) for n, v in ((1, event["id"]), (2, 1000000 + event["account"]),
                (4, event["count"]), (5, event["damage"]), (6, event["kill"]), (7, event["method"])))
            reply += encode_pb_field(1, 2, info + encode_pb_field(3, 2, event["name"].encode()))
    return reply, reward, cost


def query(opcode, save, body, config):
    """未绑定账号库的分析Session只保留介绍查询，不创建共享场次。"""
    request(opcode, save, body, config)
    kind = opcode % 10
    if kind == 0:
        row = config["boss2"]["30001" if opcode == 3400 else "31001"]
        return b"".join(encode_pb_field(n, 0, row["hp"] if n == 10 else 0) for n in (1, 2, 3, 4, 7, 8, 9, 10))
    return encode_pb_field(2 if kind == 3 else 3, 0, 0) if kind in (3, 4) else b""
