"""24级客栈引导查询；只投影当前拥有的伙伴，不赠送物品或推进引导。"""

from . import formation, recharge
from .protocol import iter_pb_fields, pb_get_varint

QUERIES = (3670, 3671, 3673)
UNSUPPORTED = (3672, 3674, 3675)


def query(opcode, save, body, config):
    fields = list(iter_pb_fields(body))
    if (opcode != 3670 and body or len(fields) > 1
            or any(n != 1 or w != 0 or not 0 < v < (1 << 31) for n, w, v in fields)):
        raise ValueError("客栈查询只接受空参数，伙伴详情可指定一个CID")
    if (not save.get("has_role") or save["role_state"]["level"] < config["build"]["138"]["level"]
            or save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2):
        if opcode == 3671:
            return b""  # 原生新号初始化也预加载伙伴好感列表，未解锁时保持空表。
        raise ValueError("客栈尚未解锁，请先完成新手引导并达到24级")
    # shortcut: 仅接通零好感的引导查询；开放送礼/成就领取/转移前须实现持久化结算。
    if opcode == 3673:
        return recharge.ids([v for cid in sorted(map(int, config["favorable_task"])) for v in (cid, 0)])
    owned = set()
    world = bytes.fromhex(save["world_state"]["1002"])
    for raw in formation.records(world, 1, 2).values():
        cid = pb_get_varint(raw, 1)
        row = config["general"][str(cid)]
        owned.update(value for value in (cid, *(row.get(key, 0) for key in ("init_cid", "orange_id", "generalid2", "partner_id")))
                     if str(value) in config["favorable"])
    candidates = sorted(owned)
    if opcode == 3671:
        return recharge.ids([v for cid in candidates for v in (cid, 0)])
    cid = fields[0][2] if fields else next(iter(candidates), None)
    if cid not in owned:
        raise ValueError("当前没有可查看好感度的伙伴，或该伙伴不属于本账号")
    return recharge.ids([cid] + [0] * 17)
