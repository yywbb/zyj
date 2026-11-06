"""本地账号好友；共享关系/私聊与角色领奖用同身份收据衔接。"""

import copy
import json
import math
import random
import re
import secrets

from . import activities, artifact, battle, cheer, formation, guild, pets, storage
from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint


OPCODES = (*range(2300, 2314), 3002, 3003, 3004, 6038, 1020, 1022)
MUTATIONS = (2302, 2304, 2306, 2308, 2309, 2310, 2311, 3003, 3004, 6038)


def integer(value, low=0, high=(1 << 31) - 1):
    if type(value) is not int or not low <= value <= high:
        raise ValueError("好友数值无效")
    return value


def identity(value):
    if type(value) not in (int, float) or not math.isfinite(value) or value <= 0:
        raise ValueError("好友角色身份无效")


def account_id(key):
    if not isinstance(key, str) or not re.fullmatch(r"[1-9][0-9]{0,3}", key) or int(key) > 1000:
        raise ValueError("好友账号无效")
    return int(key)


def daily(save, now=None):
    state = copy.deepcopy(save.get("friend_state", {"day": 0, "received": [], "receipt": ""}))
    try:
        integer(state["day"])
        received = state["received"]
        if not isinstance(received, list) or len(received) > 1000:
            raise ValueError
        for account in received:
            integer(account, 1, 1000)
        if len(set(received)) != len(received) or not isinstance(state["receipt"], str) or state["receipt"] and not re.fullmatch(r"[a-f0-9]{32}", state["receipt"]):
            raise ValueError
    except (KeyError, TypeError, ValueError):
        raise ValueError("好友收礼记录损坏，请恢复角色存档") from None
    if now is not None and (now + 28800) // 86400 > state["day"]:
        state.update(day=(now + 28800) // 86400, received=[])
    return state


def validate(state):
    if type(state["version"]) is not int or state["version"] != 1:
        raise ValueError("好友存档版本无效")
    for key in ("checked_at", "day", "next_chat"):
        integer(state[key], int(key == "next_chat"))
    for key in ("players", "gifts", "chats"):
        if not isinstance(state[key], dict):
            raise ValueError("好友存档格式无效")
    players = state["players"]
    for key, row in players.items():
        account = account_id(key)
        identity(row["identity"])
        integer(row["last_chat"])
        for group in ("friends", "requests", "blocked"):
            values = row[group]
            if not isinstance(values, list) or len(values) > 999:
                raise ValueError("好友关系无效")
            for other in values:
                integer(other, 1, 1000)
                if other == account or str(other) not in players:
                    raise ValueError("好友关系指向无效角色")
            if len(values) != len(set(values)):
                raise ValueError("好友关系重复")
        if not isinstance(row["read"], dict):
            raise ValueError("私聊已读记录无效")
        for peer, index in row["read"].items():
            account_id(peer)
            integer(index, high=state["next_chat"] - 1)
        for peer in row["friends"]:
            other = players[str(peer)]
            if account not in other["friends"] or peer in row["blocked"] or account in other["blocked"]:
                raise ValueError("双向好友关系不一致")
        for peer in row["requests"]:
            if peer in row["friends"] or peer in row["blocked"] or account in players[str(peer)]["blocked"]:
                raise ValueError("好友申请状态无效")
    for key, identities in state["gifts"].items():
        ends = key.split(":")
        if len(ends) != 2 or account_id(ends[0]) == account_id(ends[1]) or not isinstance(identities, list) or len(identities) != 2:
            raise ValueError("好友赠礼记录无效")
        for value in identities:
            identity(value)
    for key, room in state["chats"].items():
        ends = key.split(":")
        if len(ends) != 2 or account_id(ends[0]) >= account_id(ends[1]):
            raise ValueError("私聊对象无效")
        if room["identities"] != [players[k]["identity"] for k in ends] or not isinstance(room["messages"], list) or len(room["messages"]) > 100:
            raise ValueError("私聊历史无效")
        previous = 0
        for message in room["messages"]:
            previous = integer(message["id"], previous + 1, state["next_chat"] - 1)
            integer(message["at"])
            integer(message["account"], 1, 1000)
            if str(message["account"]) not in ends or not valid_text(message["text"]):
                raise ValueError("私聊内容无效")
    if "pending" in state:
        pending = state["pending"]
        account_id(pending["account"])
        identity(pending["identity"])
        if not isinstance(pending["token"], str) or not re.fullmatch(r"[a-f0-9]{32}", pending["token"]):
            raise ValueError("好友事务收据无效")
        after = pending["after"]
        if "pending" in after or after["players"][pending["account"]]["identity"] != pending["identity"]:
            raise ValueError("好友事务身份无效")
        validate(after)


def load(path, saves):
    if not path.exists():
        if any(save.get("friend_state") for save in saves.values()):
            raise ValueError("好友存档缺失，请将 friends.json 与角色存档一起恢复")
        return {"version": 1, "checked_at": 0, "day": 0, "next_chat": 1, "players": {}, "gifts": {}, "chats": {}}
    try:
        state = json.loads(path.read_bytes())
        validate(state)
        if any(save.get("friend_state") and str(account) not in state["players"] for account, save in saves.items()):
            raise ValueError("角色的好友事务记录缺失")
        return state
    except (ValueError, KeyError, TypeError, AttributeError, UnicodeError, OverflowError):
        raise ValueError("好友存档损坏，未修改关系或奖励") from None


def write(path, state):
    validate(state)
    storage.atomic_write(path, json.dumps(state, ensure_ascii=False, allow_nan=False).encode())


def recover(state, saves):
    pending = state.pop("pending", None)
    if pending:
        saved = saves.get(int(pending["account"]), {})
        if saved.get("created_at") == pending["identity"] and daily(saved)["receipt"] == pending["token"]:
            state.clear()
            state.update(pending["after"])
    removed = {int(key) for key, row in state["players"].items() if saves.get(int(key), {}).get("created_at") != row["identity"]}
    for account in removed:
        del state["players"][str(account)]
    for row in state["players"].values():
        for group in ("friends", "requests", "blocked"):
            row[group] = [a for a in row[group] if a not in removed]
        row["read"] = {k: v for k, v in row["read"].items() if int(k) not in removed}
    for key in list(state["chats"]):
        a, b = map(int, key.split(":"))
        if a in removed or b in removed or b not in state["players"][str(a)]["friends"]:
            del state["chats"][key]
    for account, save in saves.items():
        state["players"].setdefault(str(account), {"identity": save["created_at"], "friends": [], "requests": [], "blocked": [], "read": {}, "last_chat": 0})


def stage(state, before, account, save):
    token = secrets.token_hex(16)
    after = copy.deepcopy(state)
    save["friend_state"]["receipt"] = token
    state.clear()
    state.update(copy.deepcopy(before))
    state["pending"] = {"account": str(account), "identity": save["created_at"], "token": token, "after": after}


def request_ids(body, minimum=0, maximum=100):
    fields = list(iter_pb_fields(body))
    if not minimum <= len(fields) <= maximum or any((n, w) != (1, 0) or not 0 <= v < (1 << 31) for n, w, v in fields):
        raise ValueError("好友操作参数无效")
    return [v for _, _, v in fields]


def target(rid, account, saves):
    return guild.target_account(rid, account, saves)


def blocked(state, account, peer):
    return peer in state["players"][str(account)]["blocked"] or account in state["players"][str(peer)]["blocked"]


def capacity(save, config):
    return config["vip"][str(save["role_state"]["vip"])]["friend"]


def relation_status(state, account, peer, saves, config):
    own, other = state["players"][str(account)], state["players"][str(peer)]
    return (2 if peer in own["friends"] else 1 if account in other["requests"] else
            3 if len(own["friends"]) >= capacity(saves[account], config) else
            4 if len(other["friends"]) >= capacity(saves[peer], config) else 0)


def player_body(account, viewer, saves, param=0, online=(), guild_names=None):
    save = saves[account]
    role = save["role_state"]
    raw = bytes.fromhex(save["role_snapshot"])
    values = [0, 0, pb_get_varint(raw, 23) or 35001, pb_get_varint(raw, 24) or 35501,
              role["power"], (guild_names or {}).get(account, ""), 0 if account in online else -1, role["vip"]]
    return (encode_pb_field(1, 0, guild.role_id(account, viewer, saves))
        + encode_pb_field(2, 2, save["role_name"].encode())
        + b"".join(encode_pb_field(n, 0, role[k]) for n, k in ((3, "level"), (4, "vip"), (5, "profile")))
        + encode_pb_field(7, 0, param) + encode_pb_field(8, 2, guild.params(values)))


def players_body(accounts, viewer, saves, state, config, online, guild_names):
    return b"".join(encode_pb_field(1, 2, player_body(a, viewer, saves, relation_status(state, viewer, a, saves, config), online, guild_names)) for a in accounts)


def available_gift(state, sender, receiver):
    return state["gifts"].get(f"{sender}:{receiver}") == [state["players"][str(sender)]["identity"], state["players"][str(receiver)]["identity"]]


def friends_body(state, saves, account, now, online, guild_names):
    received = daily(saves[account], now)["received"]
    result = encode_pb_field(2, 0, len(received)) + encode_pb_field(3, 0, 1000000 + account)
    for peer in sorted(state["players"][str(account)]["friends"]):
        public = player_body(peer, account, saves, online=online, guild_names=guild_names)
        raw = b"".join(encode_pb_field(n, w, value) for n, w, value in iter_pb_fields(public) if n in (1, 2, 3))
        raw += encode_pb_field(4, 0, saves[peer]["role_state"]["profile"])
        raw += encode_pb_field(5, 0, int(f"{account}:{peer}" in state["gifts"]))
        raw += encode_pb_field(6, 0, 2 if peer in received else int(available_gift(state, peer, account)))
        raw += encode_pb_field(7, 0, 0) + encode_pb_field(10, 2, next(v for n, w, v in iter_pb_fields(public) if n == 8))
        result += encode_pb_field(1, 2, raw)
    return result


def recommend(state, saves, account, config, online):
    own = state["players"][str(account)]
    return sorted((a for a in saves if a != account and a not in own["friends"] and not blocked(state, account, a)),
                  key=lambda a: (a not in online, abs(saves[a]["role_state"]["level"] - saves[account]["role_state"]["level"]), a))[:20]


def accept(state, saves, account, peer, config):
    own, other = state["players"][str(account)], state["players"][str(peer)]
    if peer not in own["requests"] or blocked(state, account, peer):
        raise ValueError("好友申请已失效")
    if len(own["friends"]) >= capacity(saves[account], config) or len(other["friends"]) >= capacity(saves[peer], config):
        raise ValueError("自己或对方好友数量已满")
    own["friends"].append(peer)
    other["friends"].append(account)
    own["requests"].remove(peer)
    if account in other["requests"]:
        other["requests"].remove(account)


def public_slots(save):
    raw = bytes.fromhex(save["world_state"]["1002"])
    fields = list(iter_pb_fields(raw))
    slots = [v for n, w, v in fields if (n, w) in ((4, 2), (5, 2)) and pb_get_varint(v, 2)]
    generals = {pb_get_varint(v, 2) for v in slots}
    equips = {pb_get_varint(v, k) for v in slots for k in range(4, 10)}
    souls = {pb_get_varint(v, k) for v in slots for k in range(10, 18)}
    artifacts = {pb_get_varint(v, 26) for v in slots}
    gems = {v for n, w, data in fields if w == 2 and 8 <= n <= 15 for fn, wt, v in iter_pb_fields(data) if (fn, wt) == (1, 0)}
    output = bytearray()
    for n, w, value in fields:
        if w != 2:
            continue
        if (n in (4, 5) and value in slots or n == 6 or 8 <= n <= 15
                or n == 1 and pb_get_varint(value, 2) in generals
                or n in (2, 3, 7) and pb_get_varint(value, 1) in {2: equips, 3: souls, 7: gems}[n]
                or n == 16 and artifact.iid(value) in artifacts):
            output.extend(encode_pb_field(n, w, value))
    if not generals or not any(n == 6 for n, w, v in fields):
        raise ValueError("对方公开阵容尚未初始化")
    if generals != set(formation.records(bytes(output), 1, 2)):
        raise ValueError("对方公开阵容缺少武将")
    return bytes(output)


def valid_text(text):
    return isinstance(text, str) and 1 <= len(text) <= 40 and text.isprintable() and bool(text.strip()) and not any(mark in text for mark in ("<", ">", "&&&"))


def unread(state, account, peer):
    room = state["chats"].get(":".join(map(str, sorted((account, peer)))), {})
    seen = state["players"][str(account)]["read"].get(str(peer), 0)
    return any(m["account"] == peer and m["id"] > seen for m in room.get("messages", []))


def chat(opcode, body, state, saves, account, config, now, cursors, online, guild_names):
    if opcode == 2306:
        fields = list(iter_pb_fields(body))
        if len(fields) != 1 or fields[0][:2] != (2, 2):
            raise ValueError("私聊只接受一条消息")
        fields = list(iter_pb_fields(fields[0][2]))
        if sorted((n, w) for n, w, _ in fields) != [(1, 0), (2, 2)]:
            raise ValueError("私聊消息字段无效")
        values = {n: v for n, w, v in fields}
        try:
            text = values[2].decode("utf-8")
        except UnicodeError:
            raise ValueError("私聊文字编码无效") from None
        if not valid_text(text):
            raise ValueError("私聊须为1–40个可显示字符，不接受富文本链接")
        role = saves[account]["role_state"]
        gates = [(key, int(config["global_kv"]["private_chat_" + key]["value"])) for key in ("vip", "level", "power")]
        enabled = [(key, value) for key, value in gates if value >= 0]
        if enabled and not any(role[key] >= value for key, value in enabled):
            raise ValueError("尚未达到配置的私聊等级/VIP/战力要求")
        rid, incremental = values[1], True
    else:
        fields = list(iter_pb_fields(body))
        if sorted((n, w) for n, w, _ in fields) not in ([(1, 0)], [(1, 0), (2, 0)]):
            raise ValueError("私聊查询参数无效")
        values = {n: v for n, w, v in fields}
        rid, incremental = values[1], values.get(2, 0)
        if incremental not in (0, 1):
            raise ValueError("私聊查询方式无效")
    peer = target(rid, account, saves)
    own = state["players"][str(account)]
    if peer not in own["friends"] or blocked(state, account, peer):
        raise ValueError("只能与当前未屏蔽的本地好友私聊")
    ends = sorted((account, peer))
    key = ":".join(map(str, ends))
    room = state["chats"].get(key, {"identities": [saves[a]["created_at"] for a in ends], "messages": []})
    if opcode == 2306:
        if own["last_chat"] and now - own["last_chat"] < 5:
            raise ValueError("私聊发言间隔为5秒")
        integer(state["next_chat"], 1, (1 << 31) - 2)
        room["messages"].append({"id": state["next_chat"], "at": now, "account": account, "text": text})
        room["messages"] = room["messages"][-100:]
        state["chats"][key] = room
        state["next_chat"] += 1
        own["last_chat"] = now
    cursor = cursors.get(peer)
    start = cursor[1] if incremental and cursor and cursor[0] == saves[peer]["created_at"] else 0
    messages = [m for m in room["messages"] if m["id"] > start]
    last = room["messages"][-1]["id"] if room["messages"] else 0
    if last:
        own["read"][str(peer)] = last
    public = b"".join(encode_pb_field(1, 2, player_body(a, account, saves, online=online, guild_names=guild_names))
                      for a in sorted({m["account"] for m in messages}))
    contents = b"".join(encode_pb_field(2, 2, encode_pb_field(1, 0, guild.role_id(m["account"], account, saves))
        + encode_pb_field(2, 2, m["text"].encode()) + encode_pb_field(3, 0, m["at"])) for m in messages)
    return public + contents, b"", (peer, saves[peer]["created_at"], last)


def prepare(opcode, body, state, saves, account, config, now, cursors, online, guild_names):
    save, own = saves[account], state["players"][str(account)]
    day = (now + 28800) // 86400
    if day > state["day"]:
        state.update(day=day, gifts={})
    state["checked_at"] = now
    if opcode in (2305, 2306):
        return chat(opcode, body, state, saves, account, config, now, cursors, online, guild_names)
    values = request_ids(body)
    if opcode in (2300, 2303, 2312, 2313, 6038):
        if values:
            raise ValueError("此好友查询不接受参数")
    elif opcode == 2301:
        if values not in ([], [1]):
            raise ValueError("好友推荐参数无效")
    elif opcode == 3002:
        if len(values) != 1 or not 0 <= values[0] <= len(own["blocked"]):
            raise ValueError("屏蔽列表页码无效")
    elif opcode in (2304, 2311):
        if len(values) != (2 if opcode == 2304 else 1) or values[-1] not in (1, 2):
            raise ValueError("请选择接受或拒绝好友申请")
    elif opcode in (2307, 1020, 1022):
        if len(values) != 1:
            raise ValueError("请选择一名本地角色")
    elif not values and opcode not in (2308, 2309) or len(values) != len(set(values)):
        raise ValueError("请选择唯一的本地好友")
    if opcode == 2300:
        reply = friends_body(state, saves, account, now, online, guild_names)
    elif opcode in (2301, 6038):
        peers = recommend(state, saves, account, config, online)
        if opcode == 6038:
            if len(own["friends"]) >= capacity(save, config):
                return guild.ids([1]), b"", None
            for peer in peers:
                if relation_status(state, account, peer, saves, config) == 0:
                    state["players"][str(peer)]["requests"].append(account)
            reply = guild.ids([0])
        else:
            reply = guild.message(0, guild.ids([int(any(a in online for a in peers))])) + guild.message(1, players_body(peers, account, saves, state, config, online, guild_names))
    elif opcode in (2303, 2312):
        peers = sorted(own["requests"] if opcode == 2303 else own["friends"], key=lambda a: (not unread(state, account, a), a))
        reply = players_body(peers, account, saves, state, config, online, guild_names)
    elif opcode == 2313:
        reply = guild.ids([int(any(unread(state, account, a) for a in own["friends"]))])
    elif opcode == 2307:
        peer = values[0] - 1000000
        reply = players_body([peer], account, saves, state, config, online, guild_names) if peer in saves and peer != account and not blocked(state, account, peer) else b""
    elif opcode in (1020, 1022):
        peer = target(values[0], account, saves)
        if blocked(state, account, peer):
            raise ValueError("对方不可查看或切磋")
        if opcode == 1020:
            reply = public_slots(saves[peer])
        else:
            if peer not in own["friends"]:
                raise ValueError("请选择当前本地好友切磋")
            from .guild_boss import battle_result
            point = config["copy"]["42101"]["1"]
            attacker, defender = copy.deepcopy(save), copy.deepcopy(saves[peer])
            attack, _ = battle.rosters(attacker, point, config, illusion_mode="pvp", now=now)
            defense, _ = battle.rosters(defender, point, config, illusion_mode="pvp", now=now)
            report = battle.simulate(attack, defense, config, random.getrandbits(64), attack_pet=pets.combat(attacker, config), defense_pet=pets.combat(defender, config),
                                     attack_cheer=cheer.combat(attacker, config, illusion_mode="pvp", now=now), defense_cheer=cheer.combat(defender, config, illusion_mode="pvp", now=now))
            report["meta"]["attack"]["n"], report["meta"]["defense"]["n"] = save["role_name"], saves[peer]["role_name"]
            reply = battle_result(report)
    elif opcode == 3002:
        offset = values[0]
        peers = sorted(own["blocked"])[offset:offset + 50]
        reply = guild.message(0, guild.ids([len(own["blocked"]), offset, len(peers)])) + guild.message(1, players_body(peers, account, saves, state, config, online, guild_names))
    elif opcode in (2304, 2311):
        peers = [target(values[0], account, saves)] if opcode == 2304 else sorted(own["requests"])
        for peer in peers:
            if peer not in own["requests"]:
                raise ValueError("好友申请已失效")
            if values[-1] == 2:
                own["requests"].remove(peer)
            elif opcode == 2304 or len(own["friends"]) < capacity(save, config) and len(state["players"][str(peer)]["friends"]) < capacity(saves[peer], config):
                accept(state, saves, account, peer, config)
        reply = friends_body(state, saves, account, now, online, guild_names)
    else:
        peers = [target(rid, account, saves) for rid in values] if values else sorted(own["friends"])
        for peer in peers:
            if opcode == 3004:
                if peer not in own["blocked"]:
                    raise ValueError("该角色不在屏蔽列表")
            elif blocked(state, account, peer):
                raise ValueError("该角色已被屏蔽")
            elif opcode in (2308, 2309, 2310) and peer not in own["friends"]:
                raise ValueError("该角色不是当前好友")
            elif opcode == 3003 and peer in own["friends"]:
                raise ValueError("请先删除好友再屏蔽")
        if opcode == 2302:
            if len(own["friends"]) >= capacity(save, config):
                return guild.ids([1001]), b"", None
            if any(len(state["players"][str(peer)]["friends"]) >= capacity(saves[peer], config) for peer in peers):
                return guild.ids([1002]), b"", None
            for peer in peers:
                other = state["players"][str(peer)]
                if peer not in own["friends"] and account not in other["requests"]:
                    other["requests"].append(account)
            reply = guild.ids([0])
        elif opcode in (3003, 3004):
            for peer in peers:
                if opcode == 3003:
                    own["blocked"].append(peer)
                    if peer in own["requests"]:
                        own["requests"].remove(peer)
                    other = state["players"][str(peer)]
                    if account in other["requests"]:
                        other["requests"].remove(account)
                else:
                    own["blocked"].remove(peer)
            reply = guild.ids([0])
        elif opcode == 2310:
            for peer in peers:
                own["friends"].remove(peer)
                state["players"][str(peer)]["friends"].remove(account)
                state["chats"].pop(":".join(map(str, sorted((account, peer)))), None)
            reply = guild.ids([1])
        elif opcode == 2308:
            for peer in peers:
                state["gifts"].setdefault(f"{account}:{peer}", [save["created_at"], saves[peer]["created_at"]])
            reply = guild.ids([1])
        elif opcode == 2309:
            personal = daily(save, now)
            available = [a for a in peers if available_gift(state, a, account) and a not in personal["received"]]
            if values and len(available) != len(peers):
                raise ValueError("礼物不存在或已领取")
            limit = int(config["global_kv"]["friend_reward_times"]["value"])
            available = available[:max(0, limit - len(personal["received"]))]
            if not available:
                raise ValueError("没有可领取的好友礼物或今日已达上限")
            reward = activities.build_reward(save, config["global_kv"]["friend_reward"]["value"], config, len(available))
            personal["received"].extend(available)
            save["friend_state"] = personal
            return reward, reward, None
        else:
            raise ValueError("好友操作尚未支持")
    return reply, b"", None
