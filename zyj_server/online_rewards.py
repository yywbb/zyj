"""每日在线奖励；本地累计在线规则，奖励与计时随响应组一起保存。"""

from . import activities
from .protocol import encode_pb_field


OPCODES = (2037, 2038)


def get_state(save, config):
    state = save.setdefault("online_reward_state", {"day": 0, "seconds": 0, "claimed": 0, "checked_at": 0})
    if (not isinstance(state, dict)
            or any(type(state.get(k)) is not int or state[k] < 0 for k in ("day", "seconds", "claimed", "checked_at"))
            or state["claimed"] > len(config["online_reward"])
            or state["seconds"] > max(row["minute"] for row in config["online_reward"].values()) * 60):
        raise ValueError("在线奖励存档无效")
    return state


def settle(save, config, connected_at, now):
    if not save.get("has_role"):
        return
    state = get_state(save, config)
    # 旧档从首次结算开始；重连只累计当前连接内的时间，不拿落盘时间补算离线时长。
    start = max(connected_at, state["checked_at"] or now)
    day = (now + 8 * 3600) // 86400
    if day > state["day"]:
        state.update(day=day, seconds=0, claimed=0)
        start = max(start, day * 86400 - 8 * 3600)
    maximum = max(row["minute"] for row in config["online_reward"].values()) * 60
    state["seconds"] = min(maximum, state["seconds"] + max(0, now - start))
    state["checked_at"] = max(now, state["checked_at"])
    # shortcut: 未确认的断线尾段不补算；需精确离线边界时再补断线结算。


def prepare(opcode, save, body, config):
    if body:
        raise ValueError("在线奖励请求不接受参数")
    if not save.get("has_role"):
        if opcode == 2037:
            return b""
        raise ValueError("角色尚未创建")
    state = get_state(save, config)
    rows = sorted(config["online_reward"].items(), key=lambda item: item[1]["minute"])
    if state["claimed"] == len(rows):
        if opcode == 2037:
            return b""
        raise ValueError("今日在线奖励已领完")
    key, row = rows[state["claimed"]]
    remaining = max(0, row["minute"] * 60 - state["seconds"])
    if opcode == 2037:
        return encode_pb_field(1, 0, int(key)) + encode_pb_field(1, 0, remaining)
    if remaining:
        raise ValueError("在线时长不足，奖励尚未解锁")
    reward = activities.build_reward(save, row["reward"], config)
    state["claimed"] += 1
    return reward
