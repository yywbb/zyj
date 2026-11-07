"""天机令激活（8241）。

每个主阵位的 Slot_Property.token(27) 保存 6 套×4 个位置共 24 个 0/1，
下标为 (套装-1)*4+位置-1。客户端只发 [阵位, 位置]，套装按客户端规则
取该阵位第一套尚未集齐的套装。激活消耗对应令牌1个和配置费用。
本模块只记录激活状态，不改变战斗属性。
"""

from . import formation
from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint

OPCODES = (8241,)
TOKEN_FIELD = 27
PER_SUIT = 4


def parse_costs(text):
    costs = []
    for entry in text.split(";"):
        if entry:
            cid, count = map(int, entry.split(","))
            if cid <= 0 or count <= 0:
                raise ValueError("天机令费用配置无效")
            costs.append((cid, count))
    return costs


def prepare(opcode, save, body, config):
    """返回 (回复, 费用, 需写回的阵位记录)。"""
    fields = list(iter_pb_fields(body))
    if len(fields) != 2 or any(n != 1 or w != 0 for n, w, v in fields):
        raise ValueError("天机令激活需要阵位和位置")
    sid, location = (v for n, w, v in fields)
    if not save.get("has_role"):
        raise ValueError("角色尚未创建")
    if location not in range(1, PER_SUIT + 1):
        raise ValueError("天机令位置无效")
    slots = formation.records(bytes.fromhex(save["world_state"]["1002"]), 4, 1)
    raw = slots.get(sid)
    if not raw or not pb_get_varint(raw, 2):
        raise ValueError("请选择已上阵伙伴的阵位")
    suits = sorted({int(row["suit"]) for row in config["token"].values()})
    cells = [v for n, w, v in iter_pb_fields(raw) if n == TOKEN_FIELD and w == 0]
    cells += [0] * (len(suits) * PER_SUIT - len(cells))
    suit = next((s for s in suits if not all(cells[(s - 1) * PER_SUIT:s * PER_SUIT])), None)
    if suit is None:
        raise ValueError("该阵位的天机令已全部激活")
    index = (suit - 1) * PER_SUIT + location - 1
    if cells[index]:
        raise ValueError("该天机令已激活")
    row = next(r for r in config["token"].values() if r["suit"] == suit and r["location"] == location)
    if save["role_state"]["level"] < row["limit_level"]:
        raise ValueError(f"角色等级不足{row['limit_level']}级")
    costs = [(row["id"], 1), *parse_costs(row["cost"])]
    inventory = {pb_get_varint(v, 1): pb_get_varint(v, 2) for n, w, v in
                 iter_pb_fields(bytes.fromhex(save["world_state"]["1200"])) if (n, w) == (1, 2)}
    for cid, count in costs:
        if inventory.get(cid, 0) < count:
            raise ValueError(f"{config['props'][str(cid)]['name']}不足")
    cells[index] = 1
    seen, rebuilt = 0, b""
    for n, w, v in iter_pb_fields(raw):
        if n == TOKEN_FIELD and w == 0:
            rebuilt += encode_pb_field(n, 0, cells[seen])
            seen += 1
        else:
            rebuilt += encode_pb_field(n, w, v)
    rebuilt += b"".join(encode_pb_field(TOKEN_FIELD, 0, v) for v in cells[seen:])
    return encode_pb_field(1, 0, 1), costs, encode_pb_field(4, 2, rebuilt)
