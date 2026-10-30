"""只读本地已创建角色的排行榜，不引入录制账号或虚构名次。"""

from . import formation, player
from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint


def query(body, saves, viewer, config):
    fields = list(iter_pb_fields(body))
    if len(fields) != 3 or any(n != 1 or w != 0 or not 0 < v < (1 << 31) for n, w, v in fields):
        raise ValueError("排行榜需要类型、起始名次和数量")
    method, start, count = [v for _, _, v in fields]
    if method not in (1, 2, 5, 6, 7, 8, 19) or start > 1000 or count > 1000:
        raise ValueError("排行榜类型或分页范围暂不支持")
    # shortcut: 翅膀/面具尚无本地成长记录，保持空榜；实现对应系统时再接入真实数值。
    if method in (5, 7):
        return b""
    rows = []
    for account, save in saves.items():
        state = player.get_role_state(save, config)
        role = bytes.fromhex(save.get("role_snapshot", ""))
        params = [0, 0, pb_get_varint(role, 23) or 35001, pb_get_varint(role, 24) or 35501]
        score, secondary = state["power"], state["level"]
        if method == 1:
            score, secondary = state["level"], state["power"]
        elif method == 6:
            copies = bytes.fromhex(save["world_state"]["1300"])
            score = sum(pb_get_varint(point, 3) or 0 for n, w, copy in iter_pb_fields(copies) if (n, w) == (1, 2)
                        for f, t, point in iter_pb_fields(copy) if (f, t) == (7, 2))
            params.append(score)
        elif method == 8:
            generals = formation.records(bytes.fromhex(save["world_state"]["1002"]), 1, 2)
            if not generals:
                continue
            general = max(generals.values(), key=lambda raw: (pb_get_varint(raw, 20) or 0, -(pb_get_varint(raw, 2) or 0)))
            score = pb_get_varint(general, 20) or 0
            params.extend((pb_get_varint(general, 1), pb_get_varint(general, 2), score))
        elif method == 19:
            score = state["g_power"]
        # shortcut: 旧本地角色共用录制 RID；本人保留原 RID，其他账号用隔离编号，接入跨角色交互时统一迁移。
        rid = pb_get_varint(role, 1) if account == viewer else 1000000 + account
        if not rid or not 0 < rid < (1 << 31):
            raise ValueError("排行榜角色编号无效")
        raw = (encode_pb_field(1, 0, rid) + encode_pb_field(2, 2, save["role_name"].encode("utf-8"))
               + b"".join(encode_pb_field(n, 0, v) for n, v in
                          ((3, state["level"]), (4, state["vip"]), (5, state["profile"]),
                           (7, state["g_power"] if method == 19 else state["power"])))
               + encode_pb_field(8, 2, b"".join(encode_pb_field(1, 2, encode_pb_field(1, 0, v)) for v in params)))
        rows.append((-score, -secondary, account, raw))
    return b"".join(encode_pb_field(1, 2, row[3]) for row in sorted(rows)[start - 1:start - 1 + count])
