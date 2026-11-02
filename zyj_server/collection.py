"""主城图鉴：真实获得历史和推荐阵容宝箱，不授予浏览中的对象。"""

from . import activities, formation
from .protocol import encode_pb_field, iter_pb_fields, parse_ids_pb, pb_get_varint

QUERIES = (1015, 1103, 3910)
MUTATIONS = (3911,)
OPCODES = QUERIES + MUTATIONS


def get_state(save, config):
    state = save.get("collection_state", {"generals": [], "equips": [], "claimed": []})
    if not isinstance(state, dict):
        raise ValueError("图鉴存档无效")
    for name, table in (("generals", "general"), ("equips", "equip"), ("claimed", "team_recommend")):
        values = state.get(name)
        if (not isinstance(values, list) or any(type(cid) is not int or str(cid) not in config[table]
                or name != "claimed" and config[table][str(cid)].get("illustrated") != 1 for cid in values)
                or len(values) != len(set(values))):
            raise ValueError("图鉴历史或领奖记录无效")
    return state


def observe(save, config, before=None):
    if not save.get("has_role"):
        return
    state = get_state(save, config)
    generals, equips = set(state["generals"]), set(state["equips"])
    for source in (before or {}, save):
        if not source.get("has_role"):
            continue
        world = bytes.fromhex(source.get("world_state", {}).get("1002", ""))
        generals.update(pb_get_varint(raw, 1) for raw in formation.records(world, 1, 2).values())
        equips.update(parse_ids_pb(raw)[1] for raw in formation.records(world, 2, 1).values())
    state["generals"] = sorted(cid for cid in generals if config["general"].get(str(cid), {}).get("illustrated") == 1)
    state["equips"] = sorted(cid for cid in equips if config["equip"].get(str(cid), {}).get("illustrated") == 1)
    save["collection_state"] = state


def statuses(save, config):
    state = get_state(save, config)
    owned = set(state["generals"])
    return [2 if cid in state["claimed"] else int({int(v) for v in config["team_recommend"][str(cid)]["icon"].split(";") if v} <= owned)
            for cid in sorted(map(int, config["team_recommend"]))]


def prepare(opcode, save, body, config):
    fields = list(iter_pb_fields(body))
    if (opcode in QUERIES and body or opcode == 3911 and (len(fields) != 1 or fields[0][:2] != (1, 0)
            or str(fields[0][2]) not in config["team_recommend"]) or not save.get("has_role")):
        raise ValueError("图鉴参数无效或角色尚未创建")
    observe(save, config)
    state = get_state(save, config)
    if opcode in (1015, 1103):
        table, name = ("general", "generals") if opcode == 1015 else ("equip", "equips")
        owned = set(state[name])
        return b"".join(encode_pb_field(1, 2, encode_pb_field(1, 0, cid) + encode_pb_field(2, 0, int(cid in owned)))
                        for cid in sorted(int(cid) for cid, row in config[table].items() if row.get("illustrated") == 1))
    flags = statuses(save, config)
    if opcode == 3910:
        return b"".join(encode_pb_field(1, 0, value) for value in flags)
    cid = fields[0][2]
    index = sorted(map(int, config["team_recommend"])).index(cid)
    if flags[index] != 1:
        raise ValueError("推荐阵容尚未集齐或宝箱已领取")
    reward = activities.build_reward(save, config["team_recommend"][str(cid)]["drop"], config)
    state["claimed"].append(cid)
    return reward
