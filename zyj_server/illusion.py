"""幻化系统 (Illusion)

建筑 599 伙伴幻化（Lv.65 解锁）。
Opcode:
  8110: 幻化数据查询，返回 [幻影CID, 已幻化武将IID, 到期时间]*N
  8111: 幻化 [幻影CID, 武将IID]，返回被修改的武将
  8112: 解除幻化 [幻影CID]
  8113/8115/8117: 幻化活动/幻化馆查询，本地暂无活动，返回空列表
  8252: 打开幻化界面时附带的封神赛阵容查询，本地没有封神赛阵容，返回空的 CombMessages

幻影（200501…）经礼包/奖励获得，按配置 time 天叠加有效期，到期自动解除。
武将的幻化信息存放在 General_Property.ids(41)：
[幻影CID, 评分1-5, 总评分, 属性削弱, 幻化后武将CID]。
这里只改变武将外观/形象，不做属性削弱，也不改变战斗数值。
"""

from . import formation
from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint, pb_set_field

QUERIES = (8110, 8113, 8115, 8117, 8252)
MUTATIONS = (8111, 8112)
OPCODES = QUERIES + MUTATIONS

IDS_FIELD = 41
UTC8 = 8 * 3600


def ids_body(values):
    return b"".join(encode_pb_field(1, 0, v) for v in values)


def parse_ids(body):
    values = []
    for n, w, v in iter_pb_fields(body):
        if n != 1 or w != 0:
            raise ValueError("幻化参数无效")
        values.append(v)
    return values


def get_state(save):
    state = save.setdefault("illusion_state", {"items": {}})
    items = state.get("items") if isinstance(state, dict) else None
    if not isinstance(items, dict) or any(
            not isinstance(v, list) or len(v) != 2 or any(type(x) is not int for x in v) for v in items.values()):
        raise ValueError("幻化存档无效")
    return state


def grant(save, cid, count, config, now):
    """发放幻影，返回 SomeThings.illusion(18) 的 Ids 值：[cid, generalIid, endtime, num]。"""
    row = config["illusion"].get(str(cid))
    if not row or type(count) is not int or not 0 < count < (1 << 20):
        raise ValueError("幻影奖励无效")
    items = get_state(save)["items"]
    iid, end = items.get(str(cid), [0, 0])
    end = max(end, now) + int(row["time"]) * 86400 * count
    # 有效期按“当日 24:00”结算，与界面显示的到期日一致。
    end = (end + UTC8 + 86399) // 86400 * 86400 - UTC8
    items[str(cid)] = [iid, end]
    return [cid, iid, end, count]


def reward_field(rows):
    return encode_pb_field(18, 2, ids_body([v for row in rows for v in row])) if rows else b""


def chain(general_id, config):
    generals = config["general"]
    origin = generals[str(general_id)]["init_cid"]
    row = generals[str(origin)]
    if row["quality"] == 6:
        return [origin, origin, row["gold_id"] if row["gold_id"] > 0 else origin]
    red = row["break_id"]
    gold = generals[str(red)]["gold_id"] if red > 0 and str(red) in generals else general_id
    return [general_id, red, gold]


def target_cid(source_cid, illusion_cid, config):
    generals = config["general"]
    origin = generals[str(source_cid)]["init_cid"]
    stage = 0
    if source_cid != origin:
        stage = 1 if source_cid == generals[str(origin)]["break_id"] else 2
    target = chain(config["illusion"][str(illusion_cid)]["general_id"], config)[stage]
    if target > 0 and str(target) in generals:
        return target
    return generals[str(config["illusion"][str(illusion_cid)]["general_id"])]["init_cid"]


def with_illusion(raw, values):
    return pb_set_field(raw, IDS_FIELD, 2, ids_body(values))


def sweep(save, roster, now):
    """清理过期幻影，并解除其武将上的幻化。返回需要写回的武将记录。"""
    items = get_state(save)["items"]
    update = b""
    for cid in [c for c, (iid, end) in items.items() if end <= now]:
        iid = items.pop(cid)[0]
        if iid in roster:
            roster[iid] = with_illusion(roster[iid], [])
            update += encode_pb_field(1, 2, roster[iid])
    return update


def prepare(opcode, save, body, config, now):
    """返回 (回复, 需写回的武将记录)。"""
    if opcode in (8113, 8115, 8117, 8252):
        return b"", b""
    if not save.get("has_role"):
        raise ValueError("角色尚未创建")
    roster = formation.records(bytes.fromhex(save["world_state"]["1002"]), 1, 2)
    update = sweep(save, roster, now)
    items = get_state(save)["items"]
    if opcode == 8110:
        values = []
        for cid in sorted(items, key=int):
            values.extend((int(cid), *items[cid]))
        return ids_body(values), update
    values = parse_ids(body)
    protagonist = save.get("protagonist_snapshot")
    protagonist_iid = pb_get_varint(bytes.fromhex(protagonist), 1) if protagonist else None
    if opcode == 8111:
        if len(values) != 2:
            raise ValueError("幻化需要幻影和武将")
        cid, iid = values
        if str(cid) not in items:
            raise ValueError("幻影已过期或未拥有")
        if iid not in roster or iid == protagonist_iid:
            raise ValueError("请选择已拥有的伙伴进行幻化")
        # 一个幻影只能附着一名武将，一名武将也只能有一个幻影。
        for other, entry in items.items():
            if entry[0] and (entry[0] == iid or other == str(cid)):
                if entry[0] in roster:
                    roster[entry[0]] = with_illusion(roster[entry[0]], [])
                    update += encode_pb_field(1, 2, roster[entry[0]])
                entry[0] = 0
        general = target_cid(pb_get_varint(roster[iid], 1), cid, config)
        roster[iid] = with_illusion(roster[iid], [cid, 0, 0, 0, 0, 0, 0, 0, general])
        items[str(cid)][0] = iid
        update += encode_pb_field(1, 2, roster[iid])
        return encode_pb_field(1, 2, roster[iid]), update
    if len(values) != 1:
        raise ValueError("解除幻化需要幻影")
    entry = items.get(str(values[0]))
    if entry is None:
        raise ValueError("幻影已过期或未拥有")
    if entry[0] in roster:
        roster[entry[0]] = with_illusion(roster[entry[0]], [])
        update += encode_pb_field(1, 2, roster[entry[0]])
    entry[0] = 0
    # 8112 回复是空 Ids，客户端自行清除本地武将的幻化数据。
    return b"", update
