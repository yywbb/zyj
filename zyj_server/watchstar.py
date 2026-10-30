"""观星台：本地随机星位、每日星辰和配置奖励。"""

import random

from . import activities, recharge


QUERIES = (2062,)
MUTATIONS = (2063, 2064, 2065, 2066, 2067, 2068)
OPCODES = QUERIES + MUTATIONS


def get_state(save, config):
    state = save.setdefault("watchstar_state", {"day": 0, "stars": 0, "forecasts": 0, "changes": 0,
                                                "slots": [0] * 8, "claimed": [], "reward_level": 1})
    if (not isinstance(state, dict)
            or any(type(state.get(k)) is not int or not 0 <= state[k] < (1 << 31)
                   for k in ("day", "stars", "forecasts", "changes"))
            or type(state.get("reward_level")) is not int
            or str(state["reward_level"]) not in config["watchstar_lv_reward"]
            or not isinstance(state.get("slots"), list) or len(state["slots"]) != 8
            or any(type(v) is not int or not 0 <= v <= 8 for v in state["slots"])
            or (any(state["slots"]) and not all(state["slots"]))
            or not isinstance(state.get("claimed"), list)
            or any(type(v) is not int or str(v) not in config["watchstar_reward"] for v in state["claimed"])
            or len(set(state["claimed"])) != len(state["claimed"])):
        raise ValueError("观星台存档无效")
    return state


def response(state, config):
    statuses = [2 if i in state["claimed"] else 1 if state["stars"] >= config["watchstar_reward"][str(i)]["star"] else 0
                for i in range(1, 11)]
    return recharge.ids([state["stars"], state["forecasts"], state["changes"], *state["slots"],
                         *statuses, state["reward_level"]])


def prepare(opcode, save, body, config, now, seed):
    if body:
        raise ValueError("观星台操作不接受参数")
    if not save.get("has_role") or save["role_state"]["level"] < config["build"]["31"]["level"]:
        raise ValueError("观星台尚未解锁")
    state = get_state(save, config)
    day = (now + 28800) // 86400
    if day > state["day"]:
        # 客户端规则：每日清空星辰及奖励；进行中的星图也按本地规则重置。
        state.update(day=day, stars=0, forecasts=0, changes=0, slots=[0] * 8, claimed=[])
    vip = config["vip"][str(save["role_state"]["vip"])]
    active = bool(state["slots"][0])
    correct = sum(value == i for i, value in enumerate(state["slots"], 1)) if active else 0
    costs, reward = [], b""
    if opcode == 2063:
        if active or state["forecasts"] >= vip["c_watchstar_watch"]:
            raise ValueError("请先领取本次星辰或观星次数已用完")
        # shortcut: 未获原服概率，未点亮星位等概率取1–8；有证据后替换随机规则。
        rng = random.Random(seed)
        state["slots"] = [rng.randint(1, 8) for _ in range(8)]
        state["forecasts"] += 1
    elif opcode == 2064:
        if not active or correct == 8:
            raise ValueError("请先观星，且必须有未点亮星位")
        paid = state["changes"] - vip["c_watchstar_change"] + 1
        if paid > 0:
            prices = [row for row in config["watchstar_change"].values() if row["count"] <= paid]
            if not prices:
                raise ValueError("观星台换星价格配置无效")
            costs = [(1001, max(prices, key=lambda row: row["count"])["watchstar_change"])]
        rng = random.Random(seed)
        state["slots"] = [value if value == i else rng.randint(1, 8) for i, value in enumerate(state["slots"], 1)]
        state["changes"] += 1
    elif opcode == 2065:
        if not active:
            raise ValueError("请先观星")
        state["stars"] += config["watchstar_starextra"][str(correct)]["extra"]
        if state["stars"] >= (1 << 31):
            raise ValueError("观星台星辰超出范围")
        state["slots"] = [0] * 8
    elif opcode == 2066:
        eligible = [i for i in range(1, 11) if i not in state["claimed"]
                    and state["stars"] >= config["watchstar_reward"][str(i)]["star"]]
        if not eligible:
            raise ValueError("没有可领取的观星台奖励")
        specification = "".join(config["watchstar_reward"][str(i)][f"rewards{state['reward_level']}"] for i in eligible)
        reward = activities.build_reward(save, specification, config)
        state["claimed"].extend(eligible)
    elif opcode == 2067:
        if not active or correct == 8 or not vip["lookstar_onekey"]:
            raise ValueError("一键观星尚未解锁或没有未点亮的星位")
        costs = [(1001, config["watchstar_fix"][str(correct)]["price"])]
        state["slots"] = list(range(1, 9))
    elif opcode == 2068:
        level = state["reward_level"]
        row = config["watchstar_lv_reward"][str(level)]
        if str(level + 1) not in config["watchstar_lv_reward"] or save["role_state"]["level"] < row["interval"]:
            raise ValueError("观星台奖励升级等级不足或已达到上限")
        costs = [tuple(map(int, entry.split(","))) for entry in row["cost"].split(";") if entry]
        state["reward_level"] += 1
        return recharge.ids([state["reward_level"]]), costs, reward
    get_state(save, config)
    return (reward if opcode == 2066 else response(state, config)), costs, reward
