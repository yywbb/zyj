"""真实本地杯赛：报名冻结阵容，按时结算淘汰赛，不填充NPC或轮空奖励。"""

from collections import Counter
import copy
import json
import random
import re
import secrets
import time

from . import activities, battle, cheer, formation, friends, guild, pets, storage
from .guild_boss import battle_result
from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint, pb_set_varint

OPCODES = (2100, 2101, 2102, 2103, 2104, 2106, 2107)
MUTATIONS = (2101, 2104, 2106)
ids = guild.ids


def get_state(save):
    state = save.get("cup_state", {"receipt": "", "best": 0, "points": 0, "joined_day": 0})
    try:
        for key in ("best", "points", "joined_day"):
            friends.integer(state[key])
        if state["best"] > 1000 or not isinstance(state["receipt"], str) or state["receipt"] and not re.fullmatch(r"[a-f0-9]{32}", state["receipt"]):
            raise ValueError
    except (KeyError, TypeError, ValueError):
        raise ValueError("杯赛角色记录无效") from None
    return state


def validate(state):
    try:
        if set(state) != {"version", "checked_at", "next_id", "signups", "periods", "players", "pending"} or type(state["version"]) is not int or state["version"] != 1:
            raise ValueError
        friends.integer(state["checked_at"])
        friends.integer(state["next_id"], 1)
        if not isinstance(state["periods"], dict) or len(state["periods"]) > 8 or not isinstance(state["players"], dict) or len(state["players"]) > 1000:
            raise ValueError
        def entrants(rows):
            if not isinstance(rows, dict) or len(rows) > 1000:
                raise ValueError
            for account, entry in rows.items():
                friends.account_id(account)
                friends.identity(entry["identity"])
                if not isinstance(entry["snapshot"], dict) or not isinstance(entry["profile"], str):
                    raise ValueError
                snapshot = entry["snapshot"]
                friends.integer(snapshot["role_state"]["level"], 1, 150)
                list(iter_pb_fields(bytes.fromhex(snapshot["world_state"]["1002"])))
                if (not isinstance(snapshot["role_name"], str) or not snapshot["role_name"]
                        or pb_get_varint(bytes.fromhex(entry["profile"]), 1) != 1000000 + int(account)
                        or account not in state["players"]):
                    raise ValueError
        friends.integer(state["signups"]["day"])
        entrants(state["signups"]["entrants"])
        seen = set()
        for key, period in state["periods"].items():
            friends.integer(period["day"])
            if key != str(period["day"]) or type(period["done"]) is not bool:
                raise ValueError
            entrants(period["entrants"])
            friends.integer(period["round"], 1, 13)
            if (not isinstance(period["alive"], list) or len(set(period["alive"])) != len(period["alive"])
                    or any(type(a) is not int for a in period["alive"] + period["byes"])
                    or any(str(a) not in period["entrants"] for a in period["alive"])
                    or not isinstance(period["byes"], list) or not set(period["byes"]) <= set(period["alive"])
                    or not isinstance(period["battles"], list) or len(period["battles"]) > 1000):
                raise ValueError
            for row in period["battles"]:
                friends.integer(row["id"], 1, state["next_id"] - 1)
                friends.integer(row["round"], 1, 12)
                friends.integer(row["a"], 1, 1000)
                friends.integer(row["b"], 1, 1000)
                friends.integer(row["winner"], 0, 1000)
                if row["id"] in seen or row["a"] == row["b"] or any(str(a) not in period["entrants"] for a in (row["a"], row["b"])):
                    raise ValueError
                seen.add(row["id"])
                if row["winner"] not in (0, row["a"], row["b"]) or bool(row["winner"]) != bool(row["body"]):
                    raise ValueError
                if row["body"]:
                    list(iter_pb_fields(bytes.fromhex(row["body"])))
        for account, row in state["players"].items():
            friends.account_id(account)
            friends.identity(row["identity"])
            friends.integer(row["points"])
            friends.integer(row["best"], 0, 1000)
            if pb_get_varint(bytes.fromhex(row["profile"]), 1) != 1000000 + int(account) or not isinstance(row["prizes"], dict):
                raise ValueError
            for mid, prize in row["prizes"].items():
                friends.integer(int(mid), 1, state["next_id"] - 1)
                friends.integer(prize["day"])
                friends.integer(prize["round"], 1, 12)
                if (mid != str(int(mid)) or not isinstance(prize["items"], dict) or not prize["items"]
                        or not pb_get_varint(bytes.fromhex(prize["enemy"]), 1) or not prize["body"]):
                    raise ValueError
                list(iter_pb_fields(bytes.fromhex(prize["body"])))
                for cid, count in prize["items"].items():
                    friends.integer(int(cid), 1)
                    friends.integer(count, 1)
        pending = state["pending"]
        if pending is not None:
            friends.integer(pending["account"], 1, 1000)
            friends.identity(pending["identity"])
            if not re.fullmatch(r"[a-f0-9]{32}", pending["token"]) or pending["after"]["pending"] is not None:
                raise ValueError
            validate(pending["after"])
    except (KeyError, TypeError, ValueError, AttributeError, OverflowError):
        raise ValueError("杯赛共享记录损坏，请恢复cups.json与角色的配套备份") from None


def load(path, saves, now):
    if path.exists():
        try:
            state = json.loads(path.read_bytes())
        except (ValueError, UnicodeError):
            raise ValueError("杯赛共享记录损坏，不能重建赛事") from None
    else:
        if any(save.get("cup_state") for save in saves.values()):
            raise ValueError("杯赛共享记录丢失，请恢复cups.json备份")
        state = {"version": 1, "checked_at": now, "next_id": 1, "signups": {"day": (now + 28800) // 86400 + 1, "entrants": {}},
                 "periods": {}, "players": {}, "pending": None}
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
    if any(save.get("cup_state") and state["players"].get(str(account), {}).get("identity") != save.get("created_at")
           for account, save in saves.items()):
        raise ValueError("杯赛角色与共享记录不一致，请恢复配套备份")


def stage(state, before, account, save):
    token = secrets.token_hex(16)
    after = copy.deepcopy(state)
    state.clear()
    state.update(copy.deepcopy(before))
    state["pending"] = {"account": account, "identity": save["created_at"], "token": token, "after": after}
    save["cup_state"]["receipt"] = token


def profile(save, account):
    raw = friends.player_body(account, -1, {account: save})
    world = bytes.fromhex(save["world_state"]["1002"])
    generals = formation.records(world, 1, 2)
    for _, slot in sorted(formation.records(world, 4, 1).items()):
        iid = pb_get_varint(slot, 2) or 0
        if iid:
            general = generals[iid]
            values = ((1, iid), (2, pb_get_varint(general, 1)), (3, pb_get_varint(general, 3)),
                      (4, pb_get_varint(general, 4) or 0), (5, pb_get_varint(general, 20) or 0), (6, 0))
            raw += encode_pb_field(6, 2, b"".join(encode_pb_field(n, 0, v) for n, v in values))
    return raw.hex()


def frozen(save, account, config):
    from . import exclusive_artifact

    names = ("role_state", "role_name", "pet_state", "sigil_state", "guild_skills", "magic_state", "wing_state", "cover_state", "illusion_state", "partner_growth_state")
    snapshot = copy.deepcopy({k: save[k] for k in names if k in save})
    if "cover_state" in snapshot:
        snapshot["cover_state"].update(shop={}, day=0, checked_at=0)
    snapshot["world_state"] = {"1002": friends.public_slots(save).hex()}
    exclusive = exclusive_artifact.frozen(save)
    if exclusive:
        snapshot["exclusive_artifact_state"] = exclusive
    if "illusion_state" in snapshot:
        snapshot["illusion_frozen_at"] = int(time.time())
    attack, defense = battle.rosters(copy.deepcopy(snapshot), config["copy"]["42101"]["1"], config, illusion_mode="pvp")
    battle.simulate(attack, defense, config, 0, attack_pet=pets.combat(copy.deepcopy(snapshot), config),
                    attack_cheer=cheer.combat(snapshot, config, illusion_mode="pvp"), max_rounds=1)
    return {"identity": save["created_at"], "snapshot": snapshot, "profile": profile(save, account)}


def duel(first, second, config, seed):
    a, b = copy.deepcopy(first["snapshot"]), copy.deepcopy(second["snapshot"])
    attack, _ = battle.rosters(a, config["copy"]["42101"]["1"], config, illusion_mode="pvp")
    defense, _ = battle.rosters(b, config["copy"]["42101"]["1"], config, illusion_mode="pvp")
    report = battle.simulate(attack, defense, config, seed, attack_pet=pets.combat(a, config), defense_pet=pets.combat(b, config),
                            attack_cheer=cheer.combat(a, config, illusion_mode="pvp"), defense_cheer=cheer.combat(b, config, illusion_mode="pvp"))
    report["meta"]["attack"]["n"], report["meta"]["defense"]["n"] = a["role_name"], b["role_name"]
    return report


def due(period, round):
    return period["day"] * 86400 - 28800 + (9 * 3600 + round * 1200 if round <= 9 else {10: 14 * 3600 + 1800, 11: 16 * 3600 + 1800, 12: 19 * 3600 + 1800}[round])


def pair(state, period):
    alive = period["alive"]
    period["byes"] = alive[-1:] if len(alive) % 2 else []
    for i in range(0, len(alive) - 1, 2):
        period["battles"].append({"id": state["next_id"], "round": period["round"], "a": alive[i], "b": alive[i + 1], "winner": 0, "body": ""})
        state["next_id"] += 1


def settle(state, saves, config, now):
    day = (now + 28800) // 86400
    signups = state["signups"]
    if signups["day"] <= day:
        entrants = {a: entry for a, entry in signups["entrants"].items() if saves.get(int(a), {}).get("created_at") == entry["identity"]}
        if entrants:
            alive = sorted(map(int, entrants))
            random.Random(signups["day"]).shuffle(alive)
            period = {"day": signups["day"], "entrants": entrants, "alive": alive, "byes": [],
                      "round": 13 - max(1, (len(alive) - 1).bit_length()), "battles": [], "done": len(alive) < 2}
            state["periods"][str(signups["day"])] = period
            if not period["done"]:
                pair(state, period)
        state["signups"] = {"day": day + 1, "entrants": {}}
    for period in state["periods"].values():
        while not period["done"] and now >= due(period, period["round"]):
            winners = [a for a in period["byes"] if saves.get(a, {}).get("created_at") == period["entrants"][str(a)]["identity"]]
            for row in (b for b in period["battles"] if b["round"] == period["round"]):
                a, b = row["a"], row["b"]
                valid = [x for x in (a, b) if saves.get(x, {}).get("created_at") == period["entrants"][str(x)]["identity"]]
                if len(valid) < 2:
                    winners.extend(valid)
                    continue
                seed = secrets.randbits(64)
                report = duel(period["entrants"][str(a)], period["entrants"][str(b)], config, seed)
                winner, loser = (a, b) if report["result"] else (b, a)
                row.update(winner=winner, body=battle_result(report).hex(), seed=seed)
                winners.append(winner)
                rank = 1 << (12 - row["round"])
                for account, value in ((winner, rank), (loser, min(rank * 2, len(period["entrants"])))):
                    personal = state["players"][str(account)]
                    personal["best"] = min(personal["best"] or 1001, value)
                own = state["players"][str(winner)]
                own["points"] += int(config["global_kv"]["cross_battle_cup_integral"]["value"])
                specification = config["cup_reward"][str(row["round"])]["reward"]
                items = {}
                for item in specification.strip(";").split(";"):
                    cid, count = map(int, item.split(","))
                    items[str(cid)] = items.get(str(cid), 0) + count
                own["prizes"][str(row["id"])] = {"day": period["day"], "round": row["round"], "items": items,
                    "enemy": period["entrants"][str(loser)]["profile"], "body": row["body"]}
            period["alive"] = winners
            period["byes"] = []
            period["round"] += 1
            period["done"] = len(winners) < 2 or period["round"] > 12
            if not period["done"]:
                pair(state, period)
    # shortcut: 公开战报保留最近七天，未领奖的个人胜利战报另存至领取；有长期回看需求时再扩档案。
    state["periods"] = {key: value for key, value in state["periods"].items() if value["day"] >= day - 7}


def own_rows(state, account):
    own = state["players"][str(account)]
    target = min((row["day"] for row in own["prizes"].values()), default=0)
    periods = [p for p in state["periods"].values() if str(account) in p["entrants"] and p["entrants"][str(account)]["identity"] == own["identity"]]
    period = next((p for p in periods if p["day"] == target), None) if target else max(periods, key=lambda p: p["day"], default=None)
    rows = {}
    if period:
        for row in period["battles"]:
            if row["body"] and account in (row["a"], row["b"]):
                enemy = row["b"] if account == row["a"] else row["a"]
                rows[row["round"]] = (row["id"], int(row["winner"] == account), period["entrants"][str(enemy)]["profile"])
    for mid, prize in own["prizes"].items():
        if prize["day"] == target:
            rows[prize["round"]] = (int(mid), 1, prize["enemy"])
    return rows


def prepare(opcode, body, state, saves, account, config, now):
    fields = list(iter_pb_fields(body))
    if any((n, w) != (1, 0) or not 0 <= value < (1 << 31) for n, w, value in fields):
        raise ValueError("杯赛请求格式无效")
    values = [v for _, _, v in fields]
    if (opcode not in OPCODES or opcode in (2101, 2106, 2107) and values or opcode == 2100 and (len(values) > 1 or values and values[0] > 12)
            or opcode == 2102 and values != [2, 4, 8]
            or opcode in (2103, 2104) and (len(values) != 2 or not 1 <= values[0] <= 12 or not values[1])):
        raise ValueError("杯赛请求参数无效")
    save = saves[account]
    if not save.get("has_role") or save["role_state"]["level"] < config["build"]["27"]["level"]:
        raise ValueError("杯赛需要队伍29级")
    day = (now + 28800) // 86400
    if opcode == 2101 and not 9 * 3600 <= (now + 28800) % 86400 < 23 * 3600:
        raise ValueError("杯赛报名时间为每日9:00至23:00，参加次日赛事")
    key = str(account)
    own = state["players"].get(key)
    if own is not None and own["identity"] != save["created_at"]:
        state["signups"]["entrants"].pop(key, None)
        for period in state["periods"].values():
            if key in period["entrants"]:
                # 重建角色不能继承旧阵容；历史战报仍保留原身份用于回看。
                period["alive"] = [a for a in period["alive"] if a != account]
                period["byes"] = [a for a in period["byes"] if a != account]
    if own is None or own["identity"] != save["created_at"]:
        own = {"identity": save["created_at"], "profile": profile(save, account), "points": 0, "best": 0, "prizes": {}}
        state["players"][key] = own
    own["profile"] = profile(save, account)
    settle(state, saves, config, now)
    personal = dict(get_state(save), best=own["best"], points=own["points"])
    save["cup_state"] = personal
    reward = b""
    if opcode == 2101:
        signups = state["signups"]
        if key in signups["entrants"] or personal["joined_day"] >= day + 1:
            raise ValueError("已经报名次日杯赛")
        if len(signups["entrants"]) >= int(config["global_kv"]["cup_maxpeople"]["value"]):
            raise ValueError("本地杯赛报名人数已满")
        signups["entrants"][key] = frozen(save, account, config)
        personal["joined_day"] = day + 1
        reward = activities.build_reward(save, config["global_kv"]["cup_sign_reward"]["value"], config)
        reply = guild.message(1, encode_pb_field(1, 0, 1)) + guild.message(2, reward)
    elif opcode in (2104, 2106):
        selected = [str(values[1])] if opcode == 2104 else list(own["prizes"])
        if not selected or any(mid not in own["prizes"] or opcode == 2104 and own["prizes"][mid]["round"] != values[0] for mid in selected):
            raise ValueError("本场没有可领胜利奖励或已经领取")
        gets = Counter()
        for mid in selected:
            gets.update(own["prizes"].pop(mid)["items"])
        reward = activities.build_reward(save, ";".join(f"{cid},{count}" for cid, count in sorted(gets.items())), config)
        reply = reward
    elif opcode == 2100:
        rows = own_rows(state, account)
        data = encode_pb_field(1, 0, max(rows, default=0)) + encode_pb_field(3, 0, int(key in state["signups"]["entrants"]))
        for round, (mid, result, enemy) in sorted(rows.items()):
            data += encode_pb_field(2, 2, b"".join(encode_pb_field(n, 0, v) for n, v in
                ((1, mid), (2, round), (3, result), (5, int(str(mid) not in own["prizes"])))) + encode_pb_field(4, 2, bytes.fromhex(enemy)))
        reply = guild.message(0, ids([1])) + guild.message(1, data)
    elif opcode == 2107:
        rows = [(int(a), r) for a, r in state["players"].items() if r["points"] and saves.get(int(a), {}).get("created_at") == r["identity"]]
        rows.sort(key=lambda item: (-item[1]["points"], item[0]))
        index = next((i for i, (a, _) in enumerate(rows, 1) if a == account), 0)
        reply = guild.message(0, ids([own["points"], index])) + guild.message(1, b"".join(
            encode_pb_field(1, 2, pb_set_varint(pb_set_varint(bytes.fromhex(r["profile"]), 7, r["points"]),
                1, guild.role_id(a, account, saves))) for a, r in rows))
    else:
        periods = list(state["periods"].values())
        if opcode == 2102:
            period = max(periods, key=lambda p: p["day"], default={"battles": []})
            reply = b""
            for row in period["battles"]:
                if row["round"] < 10 or not row["body"] and (period["done"] or row["round"] != period["round"]):
                    continue
                result = int(row["winner"] == row["a"]) if row["body"] else -1
                data = b"".join(encode_pb_field(n, 0, v & ((1 << 64) - 1)) for n, v in
                    ((1, row["id"]), (2, row["round"]), (5, result), (6, -1), (7, 0)))
                data += b"".join(encode_pb_field(n, 2, pb_set_varint(bytes.fromhex(period["entrants"][str(a)]["profile"]),
                    1, guild.role_id(a, account, saves))) for n, a in ((3, row["a"]), (4, row["b"])))
                reply += encode_pb_field(1, 2, data)
        else:
            round, mid = values
            prize = own["prizes"].get(str(mid))
            reply = prize["body"] if prize and prize["round"] == round else next((r["body"] for p in periods for r in p["battles"]
                if r["id"] == mid and r["round"] == round and r["body"] and (round >= 10 or account in (r["a"], r["b"]))), "")
            if not reply:
                raise ValueError("该场比赛尚未结束、战报已过期或不属于本人")
            reply = bytes.fromhex(reply)
    return reply, reward
