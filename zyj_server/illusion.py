"""幻化系统 (Illusion)

建筑 599 伙伴幻化（Lv.65 解锁）。
Opcode:
  8110: 幻化数据查询 (IllusionQuery)
"""

QUERIES = (8110,)
OPCODES = QUERIES


def prepare(opcode: int, save: dict, body: bytes, role_config: dict) -> bytes:
    if opcode == 8110:
        # 客户端查询幻化数据，未获得幻化时返回空的 Ids Protobuf（即空字节流）
        return b""
    raise ValueError(f"未知的幻化请求: {opcode}")
