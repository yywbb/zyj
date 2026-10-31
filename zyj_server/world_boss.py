"""群仙屠龙介绍页；本地尚无世界Boss场次和历史排名，不伪造挑战结算。"""

from .protocol import encode_pb_field

QUERIES = (3400, 3402, 3403, 3404, 3410, 3412, 3413, 3414)


def query(opcode, save, body, config):
    if body or not save.get("has_role") or save["role_state"]["level"] < config["build"]["21"]["level"]:
        raise ValueError("屠龙查询参数无效或功能尚未解锁")
    kind = opcode % 10
    if kind == 0:
        row = config["boss2"]["30001" if opcode == 3400 else "31001"]
        # bosslevel原生用于血条分母，实际是int64总血量，不是等级。
        return b"".join(encode_pb_field(n, 0, row["hp"] if n == 10 else 0) for n in (1, 2, 3, 4, 7, 8, 9, 10))
    if kind == 3:
        return encode_pb_field(2, 0, 0)
    if kind == 4:
        return encode_pb_field(3, 0, 0)
    return b""
