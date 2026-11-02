"""个人公会科技；永久等级，主阵加成按差值转移。"""

from .protocol import encode_pb_field, pb_get_varint, pb_set_varint


def levels(save):
    values = save.get("guild_skills", [0] * 4)
    if not isinstance(values, list) or len(values) != 4 or any(type(v) is not int or not 0 <= v <= 150 for v in values):
        raise ValueError("公会科技存档无效")
    return values[:]


def bonuses(save, config):
    values, flat = {6: 0, 7: 0, 8: 0}, 0
    learned = levels(save)
    if not any(learned):
        return values, flat
    for cid, level in zip(sorted(map(int, config["gang2_skill_open"])), learned):
        if level:
            name = config["gang2_skill_open"][str(cid)]["attr1"]
            amount = config["gang2_skill_level"][str(level)][name]
            if name == "adddmg":
                flat += amount
            else:
                values[{"atk": 6, "def": 7, "hp": 8}[name]] += amount
    return values, flat


def prepare(opcode, body, save, row, config):
    from . import development, formation, guild, player

    values = levels(save)
    if opcode == 2262:
        guild.request_ids(body, 0)
        return guild.ids(values)
    index, = guild.request_ids(body, 1)
    if index not in range(1, 5):
        raise ValueError("请选择已开放的公会科技")
    target = config["gang2_skill_level"].get(str(values[index - 1] + 1))
    name = config["gang2_skill_open"][str(sorted(map(int, config["gang2_skill_open"]))[index - 1])]["attr1"]
    if (not target or save["role_state"]["level"] < target["team_level"]
            or guild.progress(row, config)[0] < target[name + "_gang2_level"]):
        raise ValueError("公会科技已满级或战队/公会等级不足")
    cid, cost = map(int, target[name + "_contribution"].strip(";").split(","))
    if cid != 1006 or cost <= 0:
        raise ValueError("科技贡献配置无效")
    previous, old_flat = bonuses(save, config)
    daily = guild.daily_state(save)
    guild.change_contribution(daily, -cost)
    save["guild_daily_state"] = daily
    values[index - 1] += 1
    save["guild_skills"] = values
    current, flat = bonuses(save, config)
    changes = {f: current[f] - previous[f] for f in current}
    world = bytes.fromhex(save["world_state"]["1002"])
    generals, slots = formation.records(world, 1, 2), formation.records(world, 4, 2)
    update, power = b"", 0
    for iid in sorted(i for i in slots if i):
        raw, delta = development.adjust(generals[iid], changes)
        value = (pb_get_varint(raw, 20) or 0) + flat - old_flat
        if not 0 <= value < (1 << 31):
            raise ValueError("科技战力超出范围")
        update += encode_pb_field(1, 2, pb_set_varint(raw, 20, value))
        power += delta + flat - old_flat
    player.apply_sigil_update(save, update, power, config)
    return guild.ids([1])
