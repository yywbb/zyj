"""尚未开放玩法的只读状态应答；按真实协议/配置回包，不伪造进度或奖励。

这些 opcode 此前在 session.py 落到通用兜底（999999 + 1999），客户端打开
活动页时反复收到「此操作尚未实现或参数不受支持」。本模块只补查询／状态：
所有进度都是真实的初始状态（活动未开启、未报名、未达成、无挑战次数），
结算／领奖／挑战／购买类 opcode 仍不注册，避免凭空发奖或假装玩法已开放。
通天塔 7010–7019 已由 babel_tower.py 完整实现，不再属于占位玩法。
"""

from .protocol import encode_pb_field, iter_pb_fields

QUERIES = (1600, 4702, 4820, 8055, 8120, 8122, 8250, 8251)
OPCODES = QUERIES
MASK = (1 << 64) - 1

MINI_GAME_FIELDS = 26        # 10 项积分/状态 + 16 格棋盘
WORLD_WAR_FIELDS = 9         # 报名、赛区、晋级等
GOD_COMPETITION_FIELDS = 24  # 届次/赛区/阶段、三个 Boss 的伤害与 buff
MANOR_FIELDS = 23            # 名称/公告 + 6 项状态 + 5 座建筑×3


def ids(values):
    return b"".join(encode_pb_field(1, 0, int(v) & MASK) for v in values)


def params(values):
    return b"".join(encode_pb_field(1, 2, encode_pb_field(2, 2, v.encode("utf-8")) if isinstance(v, str)
                    else encode_pb_field(1, 0, int(v) & MASK)) for v in values)


def comb(messages):
    return b"".join(encode_pb_field(1, 2, encode_pb_field(1, 0, mid) + encode_pb_field(2, 2, data))
                    for mid, data in messages)


def _rows(table, name):
    if not isinstance(table, dict):
        raise ValueError(f"{name} 配置无效")
    rows = []
    for group, entries in table.items():
        if not isinstance(entries, dict):
            raise ValueError(f"{name} 配置无效")
        rows.extend((int(group), int(row)) for row in entries)
    return sorted(rows)


def _require_empty(body, label):
    if body:
        raise ValueError(f"{label}不接受参数")


def dew_pool(config):
    """成就/任务按真实配置逐行回报未达成，购买次数按真实商品逐项回报 0。"""
    achievements = []
    for group, row in _rows(config.get("dew_pool_achievement"), "露水池成就"):
        achievements.extend((group, row, 0))       # 0 = 未达成
    tasks = []
    for group, row in _rows(config.get("dew_pool_task"), "露水池任务"):
        tasks.extend((group, row, 0, 0))           # 0 = 未达到，进度 0
    shop = config.get("dew_pool_shop")
    if not isinstance(shop, dict):
        raise ValueError("露水池商店配置无效")
    return comb(((1, ids(achievements)), (2, ids(tasks)), (3, ids([0] * len(shop)))))


def reply(opcode, body, config):
    if opcode == 1600:
        _require_empty(body, "2048 小游戏查询")
        return ids([0] * MINI_GAME_FIELDS)         # 第 8 项 state=0：活动未开启
    if opcode == 8055:
        _require_empty(body, "露水池查询")
        return dew_pool(config)
    if opcode in (8120, 8122):
        _require_empty(body, "成长计划查询")
        # 第 1 项是阶段，状态列表留空：客户端按 growplan_x2/x3 配置自行生成未达成奖励。
        return ids([1])
    if opcode == 4702:
        _require_empty(body, "国战查询")
        return ids([0] * WORLD_WAR_FIELDS)
    if opcode == 4820:
        fields = list(iter_pb_fields(body))
        if len(fields) > 1 or any((n, w) != (1, 0) for n, w, _ in fields):
            raise ValueError("藏经阁查询参数无效")
        if fields and fields[0][2]:
            raise ValueError("暂不支持查看其他玩家的藏经阁")
        return params(["", ""] + [0] * (MANOR_FIELDS - 2))
    if opcode == 8250:
        _require_empty(body, "封神赛报名")
        return ids([0])                            # 未开放报名，不产生报名状态
    if opcode == 8251:
        _require_empty(body, "封神赛查询")
        return ids([0] * GOD_COMPETITION_FIELDS)
    raise ValueError("此玩法查询尚未实现")
