"""原配置开放的羽毛兑换；不开放关闭页或猜测次数重置。"""

from . import activities, development, recharge
from .protocol import encode_pb_field

QUERIES = (4016,)
MUTATIONS = (4017,)
OPCODES = QUERIES + MUTATIONS


def get_state(save, config):
    state = save.get("exchange_state", {"counts": {}, "checked_at": 0})
    if (not isinstance(state, dict) or not isinstance(state.get("counts"), dict)
            or type(state.get("checked_at")) is not int or not 0 <= state["checked_at"] < (1 << 63)):
        raise ValueError("兑换次数或时钟存档无效")
    limits = {f"{page}:{key}": row["count"] for page, rows in config["exchange_shop"].items() for key, row in rows.items()}
    if any(key not in limits or type(count) is not int or not 0 <= count <= limits[key] for key, count in state["counts"].items()):
        raise ValueError("兑换次数存档无效")
    return state


def prepare(opcode, save, body, config, now):
    values = development.ids(body)
    state = get_state(save, config)
    if opcode == 4016:
        if values:
            raise ValueError("兑换查询不接受参数")
        reply = b"".join(encode_pb_field(1, 2, encode_pb_field(1, 0, page) + encode_pb_field(2, 2,
            recharge.ids([state["counts"].get(f"{page}:{key}", 0)
                          for key in range(1, max(map(int, config["exchange_shop"].get(str(page), {})), default=0) + 1)])))
            for page in range(1, 6))
        return reply, []
    if (not save.get("has_role") or save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2
            or save["role_state"]["level"] < config["build"]["182"]["level"]):
        raise ValueError("请先完成新手引导并解锁兑换商店")
    if len(values) != 3 or not 1 <= values[2] <= 999:
        raise ValueError("兑换需要页签、配方及1–999次数量")
    page, key, count = values
    row = config["exchange_shop"].get(str(page), {}).get(str(key), {})
    if page != 1 or row.get("open") != 1 or row.get("astrict") != 0:
        raise ValueError("该兑换配方尚未开放")
    if not max(row["label_level"], row["down_level"]) <= save["role_state"]["level"] <= row["up_level"]:
        raise ValueError("队伍等级不符合兑换要求")
    identity = f"{page}:{key}"
    if count > row["count"] - state["counts"].get(identity, 0):
        raise ValueError("兑换剩余次数不足")
    if now < state["checked_at"]:
        raise ValueError("兑换时钟发生回拨，请稍后重试")
    pairs = [[tuple(map(int, entry.split(","))) for entry in row[field].split(";") if entry]
             for field in ("generals", "target")]
    if any(not entries or any(str(cid) not in config["props"] or not 0 < amount * count < (1 << 31)
                             for cid, amount in entries) for entries in pairs):
        raise ValueError("羽毛兑换材料或奖励配置无效")
    reward = activities.build_reward(save, row["target"], config, count)
    # shortcut: astrict=0按永久次数保存；确认其他重置类型前不能清空或开放它们。
    state["counts"][identity] = state["counts"].get(identity, 0) + count
    state["checked_at"] = now
    save["exchange_state"] = state
    return reward, [(cid, amount * count) for cid, amount in pairs[0]]
