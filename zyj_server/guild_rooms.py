"""盛宴/篝火真实本地房间；按服务端秒数与在场心跳分段结算。"""

import copy
from fractions import Fraction

from .protocol import encode_pb_field, pb_get_varint

OPCODES = (*range(2271, 2279), *range(2281, 2288), 2290, 2291)
MUTATIONS = (2272, 2273, 2275, 2276, 2277, 2278, 2282, 2283, 2285, 2286, 2287, 2290)


def validate(row):
    from .guild_games import integer

    rooms = row.get("rooms", {})
    if not isinstance(rooms, dict):
        raise ValueError("公会房间无效")
    integer(row.get("next_room", 1), 1)
    for rid, room in rooms.items():
        integer(int(rid), 1, row.get("next_room", 1) - 1)
        if room["kind"] not in ("feast", "bath"):
            raise ValueError("公会房间类型无效")
        integer(room["tier"], 1, 3)
        for k in ("start", "end", "checked", "created"):
            integer(room[k])
        if not room["created"] <= room["start"] <= room["end"] or not room["created"] <= room["checked"] <= room["end"]:
            raise ValueError("公会房间时间无效")
        if not isinstance(room["members"], dict) or len(room["members"]) > 20:
            raise ValueError("公会房间成员无效")
        for a, member in room["members"].items():
            integer(int(a), 1, 1000)
            if type(member["identity"]) not in (float, int) or member["identity"] <= 0 or member["mode"] not in (1, 2):
                raise ValueError("公会房间身份无效")
            for k in ("since", "present_until", "guest_seconds", "guest_day"):
                integer(member[k])
            if type(member["left"]) is not bool:
                raise ValueError("公会房间状态无效")
            for cid, amount in member["pending"].items():
                integer(int(cid), 1, (1 << 31) - 1)
                integer(amount)


def personal(save, now):
    from .guild_games import integer

    state = save.setdefault("guild_room_state", {"day": (now + 28800) // 86400, "feast": {}, "bath": {}, "convert": 0, "converted_exp": 0, "price_props": {}})
    integer(state["day"])
    integer(state["convert"], 0, 1)
    integer(state["converted_exp"])
    for kind in ("feast", "bath"):
        r = state[kind]
        for k in ("hosted", "joined", "room", "seconds"):
            integer(r.setdefault(k, 0))
    for cid, count in state["price_props"].items():
        integer(int(cid), 1)
        integer(count)
    if (now + 28800) // 86400 > state["day"]:
        state["day"] = (now + 28800) // 86400
        for kind in ("feast", "bath"):
            state[kind].update(hosted=0, joined=0, seconds=0)
        state["price_props"] = {}
    return state


def settle(room, config, now, saves, online):
    from .guild_games import pairs

    end = min(now, room["end"])
    kind = room["kind"]
    for second in range(max(room["checked"], room["start"]), end):
        present = {a for a, m in room["members"].items() if not m["left"] and m["present_until"] > second
                   and saves.get(int(a), {}).get("created_at") == m["identity"]}
        factor = Fraction(config["gang2_feast_gain" if kind == "feast" else "gang2_bath_buff"][str(max(1, len(present)))]["up"], 100)
        for a, member in room["members"].items():
            if member["since"] > second or saves.get(int(a), {}).get("created_at") != member["identity"]:
                continue
            day = (second + 28800) // 86400
            if day > member["guest_day"]:
                member.update(guest_day=day, guest_seconds=0)
            level = member["level"]
            rates = pairs(config[f"gang2_{kind}_award"][str(level)][str(room["tier"])]["award" if member["mode"] == 1 else "award_2"])
            gain = factor
            if a not in present:
                gain *= Fraction(100 - int(config["global_kv"][f"gang2_{kind}_reduce"]["value"]), 100)
            if member["mode"] == 2:
                profit = next(r["profit"] for r in sorted(config[f"gang2_{kind}_profit"].values(), key=lambda r: r["id"]) if member["guest_seconds"] < r["times"])
                gain *= Fraction(str(profit)) / 100
                member["guest_seconds"] += 1
            # 千分单位保存小数余量，查询频率不改变收益。
            for cid, rate in rates.items():
                key = str(cid)
                member["pending"][key] = member["pending"].get(key, 0) + int(rate * gain * 1000)
    room["checked"] = end


def status(row, save, viewer, saves, config, now):
    local = {"guild_room_state": copy.deepcopy(save["guild_room_state"])} if "guild_room_state" in save else {}
    own = personal(local, now)
    result = []
    for kind in ("feast", "bath"):
        room = row.get("rooms", {}).get(str(own[kind]["room"]))
        if (not room or room["kind"] != kind
                or room["members"].get(str(viewer), {}).get("identity") != save["created_at"]):
            result.extend((0, 0, 0))
            continue
        projected = copy.deepcopy(room)
        checked = max(now, room["checked"])
        settle(projected, config, checked, saves, ())
        finished = checked >= room["end"]
        pending = projected["members"][str(viewer)]["pending"]
        # 原生doing使用档次，不是共享房间ID；未使用的旧座位字段保留0。
        result.extend((int(finished and any(v >= 1000 for v in pending.values())), 0 if finished else room["tier"], 0))
    return result


def gain_exp(save, role_exp, general_exp, config):
    from . import battle, cheer, favorite, formation, player, training

    state = save["role_state"]
    previous = state["level"]
    level, exp = battle._gain_experience(previous, state["exp"], role_exp, config["role_exp"], "nextexp", max(map(int, config["role_exp"])))
    if exp >= (1 << 31):
        raise ValueError("盛宴角色经验超出范围")
    state.update(level=level, exp=exp, nextexp=config["role_exp"][str(level)]["nextexp"],
                 maxstamina=config["role_exp"][str(level)]["maxstamina"] + favorite.capacity_bonus(save, config, "maxstamina"),
                 maxenergy=config["role_exp"][str(level)]["maxenergy"] + favorite.capacity_bonus(save, config, "maxenergy"))
    for reached in range(previous + 1, level + 1):
        for cid, name in ((1000, "c_reward"), (1001, "g_reward")):
            player.change_item_count(save, cid, config["role_exp"][str(reached)][name], config)
    world = bytes.fromhex(save["world_state"]["1002"])
    generals, slots, equips = formation.records(world, 1, 2), formation.records(world, 4, 2), formation.records(world, 2, 1)
    members = cheer.members(save, config)
    update, delta = b"", 0
    maximum = min(level * int(config["global_kv"]["general_level"]["value"]), max(map(int, config["general_exp"])))
    for iid in sorted(i for i in slots if i):
        raw, increase, _ = training.grow_general(generals[iid], general_exp, slots[iid], members, equips, config, maximum, cheer_tiers=cheer.tiers(save, config))
        update += encode_pb_field(1, 2, raw)
        delta += increase
    player.apply_sigil_update(save, update, delta, config)


def take(save, row, room, account, config, now):
    from .guild_games import award

    member = room["members"].get(str(account))
    if not member or member["identity"] != save["created_at"]:
        raise ValueError("未参加当前房间")
    values = {int(cid): amount // 1000 for cid, amount in member["pending"].items()}
    for cid in member["pending"]:
        member["pending"][cid] %= 1000
    state = personal(save, now)
    if member["guest_day"] == state["day"]:
        state[room["kind"]]["seconds"] = max(state[room["kind"]]["seconds"], member["guest_seconds"])
    role_exp, general_exp = values.pop(1017, 0), values.pop(1031, 0)
    if state["convert"] and general_exp:
        # 本地转换使用现有20199经验丹，余量留存；原配置没有神器经验丹兑换比例。
        unit = int(config["props"]["20199"]["param1"])
        count, state["converted_exp"] = divmod(state["converted_exp"] + general_exp, unit)
        values[20199] = values.get(20199, 0) + count
        general_exp = 0
    if role_exp or general_exp:
        gain_exp(save, role_exp, general_exp, config)
    special = {cid: amount for cid, amount in ((1017, role_exp), (1031, general_exp)) if amount}
    reward = award(save, row, values, config, now)
    return reward + (encode_pb_field(12, 2, b"".join(encode_pb_field(1, 0, v) for c, n in special.items() for v in (c, n))) if special else b"")


def prepare(opcode, body, shared, gid, save, saves, viewer, config, now, online):
    from . import guild, guild_chat
    from .guild_games import pairs, public_player

    if opcode in (2290, 2291):
        if opcode == 2291:
            guild.request_ids(body, 0)
            return guild_chat.prepare(3010, guild.ids([0]), shared, saves, viewer, config, now, None)[0], [], b""
        kind_id, talk, tier = guild.request_ids(body, 3)
        kind = {1: "feast", 6: "bath"}.get(kind_id)
        if not kind or str(talk) not in config["barrage"][str(kind_id)] or tier not in range(1, 4):
            raise ValueError("活动邀请类型无效")
        rooms = shared["guilds"][gid].get("rooms", {})
        room = next((r for r in rooms.values() if r["kind"] == kind and r["tier"] == tier and r["end"] > now), None)
        if not room or str(viewer) not in room["members"] or room["members"][str(viewer)]["identity"] != save["created_at"]:
            raise ValueError("只能邀请参加自己所在的有效房间")
        text = config["barrage"][str(kind_id)][str(talk)]["sendout"] + (" &&&" if kind == "feast" else " &&&&&") + str(tier)
        rid = guild.role_id(viewer, viewer, saves)
        raw = encode_pb_field(2, 2, encode_pb_field(1, 0, rid) + encode_pb_field(2, 2, text.encode()))
        reply, _ = guild_chat.prepare(3011, raw, shared, saves, viewer, config, now, None, invitation=True)
        return reply, [], b""
    kind = "feast" if opcode < 2280 else "bath"
    action = opcode % 10
    state = personal(save, now)
    own = state[kind]
    row = shared["guilds"][gid]
    if guild.progress(row, config)[0] < int(config["global_kv"]["sociaty_feast_class" if kind == "feast" else "sociaty_bonfire_class"]["value"]):
        raise ValueError("公会等级不足，活动尚未开启")
    rooms = row.setdefault("rooms", {})
    for room in rooms.values():
        settle(room, config, now, saves, online)
    if action == 8:
        method, = guild.request_ids(body, 1)
        if method not in (0, 1) or save["role_state"]["level"] < int(config["global_kv"]["gang2_feast_conversion_lv"]["value"]):
            raise ValueError("经验转换需要130级，参数仅0/1")
        state["convert"] = method
        return b"", [], b""
    if action == 1:
        guild.request_ids(body, 0)
        automatic = b""
        for room in rooms.values():
            if (room["kind"] == kind and room["end"] <= now
                    and room["members"].get(str(viewer), {}).get("identity") == save["created_at"]):
                automatic += take(save, row, room, viewer, config, now)
        data = [own["hosted"], 0]
        for tier in range(1, 4):
            r = next((r for r in rooms.values() if r["kind"] == kind and r["tier"] == tier and r["end"] > now), None)
            data += [int(bool(r)), 1 if r and now < r["start"] else 2 if r else 0,
                     max(0, (r["start"] if now < r["start"] else r["end"]) - now) if r else 0, len(r["members"]) if r else 0]
            if r and str(viewer) in r["members"]:
                data[1] = tier
        return guild.ids(data + ([state["convert"]] if kind == "feast" else [])), [], automatic
    cost, reward = [], b""
    if action == 2:
        tier, method, quote = guild.request_ids(body, 3)
        if tier not in range(1, 4) or method not in (1, 2):
            raise ValueError("活动房间或举办方式无效")
        current = rooms.get(str(own["room"]))
        if current and str(viewer) in current["members"]:
            m = current["members"][str(viewer)]
            if current["end"] > now and current["tier"] != tier or any(v >= 1000 for v in m["pending"].values()):
                raise ValueError("请先领取当前房间收益再切换")
        room_key, room = next(((k, r) for k, r in rooms.items() if r["kind"] == kind and r["tier"] == tier and r["end"] > now), (None, None))
        setting = config[f"gang2_{kind}_type"][str(tier)]
        if method == 2:
            if room:
                raise ValueError("房间已经举办，请刷新后加入")
            cost = host_cost(save, own, state, kind, setting, quote, config)
            room_key = str(row.get("next_room", 1))
            row["next_room"] = int(room_key) + 1
            room = {"kind": kind, "tier": tier, "created": now, "start": now + setting["prepare_time"],
                    "end": now + setting["prepare_time"] + setting["time"], "checked": now, "members": {}}
            rooms[room_key] = room
        elif room is None or quote:
            raise ValueError("房间不存在或加入不应收费")
        member = room["members"].get(str(viewer))
        if member and member["identity"] != save["created_at"]:
            del room["members"][str(viewer)]
            member = None
        if not member:
            if len(room["members"]) >= setting["number"] or own["joined"] >= int(config["global_kv"][f"gang2_{kind}_partake" if kind == "feast" else "gang2_bath_start"]["value"]):
                raise ValueError("活动人数或每日参与次数已达上限")
            own["joined"] += 1
            room["members"][str(viewer)] = {"identity": save["created_at"], "mode": 1 if method == 2 else 2, "since": now,
                "level": save["role_state"]["level"] if kind == "feast" else guild.progress(row, config)[0],
                "present_until": now + 10, "guest_seconds": own["seconds"], "guest_day": state["day"], "left": False, "pending": {}}
        own["room"] = int(room_key)
    else:
        room = rooms.get(str(own["room"]))
        if not room or room["kind"] != kind or room["members"].get(str(viewer), {}).get("identity") != save["created_at"]:
            raise ValueError("请先加入有效房间")
        member = room["members"][str(viewer)]
        if action == 6:
            quote, = guild.request_ids(body, 1)
            if now < room["start"] or room["end"] <= now:
                raise ValueError("只能在活动进行中接龙")
            setting = config[f"gang2_{kind}_type"][str(room["tier"])]
            cost = host_cost(save, own, state, kind, setting, quote, config)
            room["end"] += setting["time"]
            member["mode"] = 1
        else:
            guild.request_ids(body, 0)
        if action == 5:
            if member["mode"] != 1 or now < room["created"] + config[f"gang2_{kind}_type"][str(room["tier"])] ["start_time"] or now >= room["start"]:
                raise ValueError("只有举办者可在准备60秒后提前开始")
            room["end"] = now + room["end"] - room["start"]
            room["start"] = now
        if action in (3, 7):
            reward = take(save, row, room, viewer, config, now)
        if action == 7:
            member.update(left=True, present_until=now)
            return guild.ids([0]), cost, reward
    member = room["members"][str(viewer)]
    member.update(left=False, present_until=now + 10)
    active = [int(a) for a, m in room["members"].items() if saves.get(int(a), {}).get("created_at") == m["identity"]]
    data = [own["hosted"], len(active), 1 if now < room["start"] else 2, max(0, (room["start"] if now < room["start"] else room["end"]) - now),
            member["mode"], max(room["start"], room["checked"]), member["guest_seconds"], sum(a in online for a in active), room["tier"]]
    preview = [v for cid, amount in member["pending"].items() for v in (int(cid), amount // 1000)]
    visible = [viewer, *sorted(a for a in active if a != viewer)][:7]
    reply = guild.message(1, guild.ids(data)) + guild.message(2, b"".join(public_player(a, viewer, saves, room=(i, room["members"][str(a)]["mode"]))
            for i, a in enumerate(visible, 1))) + guild.message(3, guild.ids(preview))
    return reward if action == 3 else reply, cost, reward


def host_cost(save, own, state, kind, setting, quote, config):
    from . import formation
    from .guild_games import pairs

    limit = int(config["global_kv"]["gang2_feast_times" if kind == "feast" else "gang2_bath_partake"]["value"])
    if own["hosted"] >= limit:
        raise ValueError("今日举办次数已用完")
    cost, gold = [], 0
    inventory = formation.records(bytes.fromhex(save["world_state"]["1200"]), 1, 1)
    for cid, count in pairs(setting["props"]).items():
        available = pb_get_varint(inventory.get(cid, b""), 2) or 0
        consume = min(available, count)
        if consume:
            cost.append((cid, consume))
        previous = state["price_props"].get(str(cid), 0)
        prices = config["price_props"][str(cid)]
        for ordinal in range(previous + 1, previous + count - consume + 1):
            bracket = min((int(k) for k in prices if int(k) >= ordinal), default=max(map(int, prices)))
            gold += prices[str(bracket)]["gold"]
        state["price_props"][str(cid)] = previous + count - consume
    if gold != quote:
        raise ValueError("食材报价已变化，请重新打开举办窗口")
    if gold:
        cost.append((1001, int(gold)))
    own["hosted"] += 1
    return cost
