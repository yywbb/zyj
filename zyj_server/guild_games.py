"""公会多人活动共用的原生投影、奖励与严格存档检查。"""

from . import guild_boss, guild_guard, guild_rooms, guild_skill, guild_war
from .protocol import encode_pb_field, pb_get_varint


OPCODES = (2262, 2263, *guild_boss.OPCODES, *guild_guard.OPCODES, *guild_rooms.OPCODES, *guild_war.OPCODES)
MUTATIONS = (2263, *guild_boss.MUTATIONS, *guild_guard.MUTATIONS, *guild_rooms.MUTATIONS, *guild_war.MUTATIONS)


def integer(value, low=0, high=(1 << 63) - 1):
    if type(value) is not int or not low <= value <= high:
        raise ValueError("公会活动数值无效")
    return value


def pairs(text):
    result = {}
    for entry in text.strip(";").split(";"):
        if not entry:
            continue
        cid, count = map(int, entry.split(","))
        integer(cid, 1, (1 << 31) - 1)
        integer(count, 1, (1 << 31) - 1)
        result[cid] = result.get(cid, 0) + count
    return result


def award(save, row, values, config, now):
    from . import activities, guild

    values = dict(values)
    contribution = values.pop(1006, 0)
    if contribution:
        daily = guild.daily_state(save, now)
        guild.change_contribution(daily, contribution)
        save["guild_daily_state"] = daily
    guild_exp = values.pop(1030, 0)
    row["experience"] = row.get("experience", 0) + guild_exp
    reward = activities.build_reward(save, ";".join(f"{cid},{count}" for cid, count in sorted(values.items()) if count), config)
    extra = [v for cid, n in ((1006, contribution), (1030, guild_exp)) if n for v in (cid, n)]
    return reward + (encode_pb_field(12, 2, guild.ids(extra)) if extra else b"")


def param(values):
    """ParamS允许同一项同时携带i/s（原生排行榜/房间协议）。"""
    return b"".join(encode_pb_field(1, 2, (encode_pb_field(1, 0, value[0]) + encode_pb_field(2, 2, value[1].encode()))
                    if isinstance(value, tuple) else encode_pb_field(2, 2, value.encode()) if isinstance(value, str)
                    else encode_pb_field(1, 0, value)) for value in values)


def public_player(account, viewer, saves, score=0, room=None):
    from . import guild

    save = saves[account]
    role, raw = save["role_state"], bytes.fromhex(save["role_snapshot"])
    return encode_pb_field(1, 2, encode_pb_field(1, 0, guild.role_id(account, viewer, saves))
        + encode_pb_field(2, 2, save["role_name"].encode())
        + b"".join(encode_pb_field(n, 0, v) for n, v in ((3, role["level"]), (4, role["vip"]), (5, role["profile"]), (7, score)))
        + encode_pb_field(8, 2, param([0, 0, pb_get_varint(raw, 23) or 35001, pb_get_varint(raw, 24) or 35501, *(room or ())])))


def validate(row):
    guild_boss.validate(row)
    guild_rooms.validate(row)
    for day, entries in row.get("guard_scores", {}).items():
        integer(int(day))
        for a, record in entries.items():
            integer(int(a), 1, 1000)
            integer(record["score"], high=(1 << 31) - 1)
            if type(record["identity"]) not in (float, int) or record["identity"] <= 0:
                raise ValueError("守卫排名身份无效")
    for a, record in row.get("guard_pending", {}).items():
        integer(int(a), 1, 1000)
        if type(record["identity"]) not in (float, int) or record["identity"] <= 0:
            raise ValueError("守卫奖励身份无效")
        for cid, count in record["items"].items():
            integer(int(cid), 1)
            integer(count, 1, (1 << 31) - 1)


def member_busy(row, account, now):
    key = str(account)
    if key in row.get("boss", {}).get("pending", {}) or key in row.get("guard_pending", {}):
        return True
    return any(key in r["members"] and (r["end"] > now or any(v >= 1000 for v in r["members"][key]["pending"].values()))
               for r in row.get("rooms", {}).values())


def prepare(opcode, body, state, save, saves, viewer, config, now, online, stamp):
    from . import guild

    gid, row = guild.membership(state, viewer)
    if row is None or not save.get("has_role") or save["role_state"]["level"] < config["build"]["28"]["level"]:
        raise ValueError("请先加入已解锁的公会")
    daily = guild.daily_state(save, now)
    if opcode in MUTATIONS and (now + 28800) // 86400 < daily["day"]:
        raise ValueError("日期回拨，请稍后操作公会活动")
    save["guild_daily_state"] = daily
    if opcode in (2262, 2263):
        return guild_skill.prepare(opcode, body, save, row, config), [], b""
    if opcode in guild_guard.OPCODES:
        return guild_guard.prepare(opcode, body, row, save, saves, viewer, config, now, stamp)
    if opcode in guild_boss.OPCODES:
        return guild_boss.prepare(opcode, body, state, gid, save, saves, viewer, config, now)
    if opcode in guild_rooms.OPCODES:
        return guild_rooms.prepare(opcode, body, state, gid, save, saves, viewer, config, now, online)
    return guild_war.prepare(opcode, body, state, gid, save, saves, viewer, config, now)
