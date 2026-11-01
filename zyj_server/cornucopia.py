"""聚宝盆：配置权重银币、VIP次数/阶梯费用、三档日奖；由player原子提交。"""

import random

from . import recharge, recruit
from .protocol import encode_pb_field, iter_pb_fields

QUERIES = (2031,)
MUTATIONS = (2032, 2033)
OPCODES = QUERIES + MUTATIONS


def get_state(save, config):
    state = save.setdefault("cornucopia_state", {"day": 0, "count": 0, "claimed": []})
    if (not isinstance(state, dict) or any(type(state.get(k)) is not int or not 0 <= state[k] < (1 << 31) for k in ("day", "count"))
            or not isinstance(state.get("claimed"), list)
            or any(type(i) is not int or i not in (1, 2, 3) for i in state["claimed"])
            or len(set(state["claimed"])) != len(state["claimed"])
            or state["count"] > max(r["shake_times"] for r in config["vip"].values())
            or state["day"] == 0 and (state["count"] or state["claimed"])):
        raise ValueError("聚宝盆存档无效")
    row = config["shake_param"][str(min(map(int, config["shake_param"])))]
    if any(state["count"] < row[f"shake_award{i}"] for i in state["claimed"]):
        raise ValueError("聚宝盆领取记录早于累计次数")
    return state


def statuses(state, row):
    return [0, state["count"], *(2 if i in state["claimed"] else int(state["count"] >= row[f"shake_award{i}"]) for i in (1, 2, 3))]


def multiplier(row, rng):
    deck = [tuple(map(int, entry.split(","))) for entry in row["shake_money_weight"].split(";") if entry]
    if (not deck or any(len(pair) != 2 or not 1 <= pair[0] <= 10 or pair[1] < 0 for pair in deck)
            or sum(pair[1] for pair in deck) <= 0):
        raise ValueError("聚宝盆暴击权重无效")
    ticket = rng.randrange(sum(weight for _, weight in deck))
    for value, weight in deck:
        ticket -= weight
        if ticket < 0:
            return value


def prepare(opcode, save, body, config, now, seed):
    fields = list(iter_pb_fields(body))
    if any(n != 1 or w != 0 or not 0 <= value < (1 << 31) for n, w, value in fields):
        raise ValueError("聚宝盆请求格式错误")
    values = [v for _, _, v in fields]
    if (not save.get("has_role") or save["role_state"]["level"] < config["build"]["168"]["level"]
            or save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2):
        raise ValueError("聚宝盆尚未解锁")
    if (opcode == 2031 and values or opcode == 2032 and (len(values) != 2 or values[0] not in (1, 5) or values[1] != 0)
            or opcode == 2033 and (len(values) != 1 or values[0] not in (1, 2, 3))):
        raise ValueError("聚宝仅支持普通单次/五次及三档日奖；未接入广告凭证验证")
    state = get_state(save, config)
    day = (now + 28800) // 86400
    if day > state["day"]:
        state.update(day=day, count=0, claimed=[])
    if opcode in MUTATIONS and day != state["day"]:
        raise ValueError("聚宝盆服务器日期回拨，请稍后重试")
    row = config["shake_param"][str(save["role_state"]["level"])]
    if opcode == 2031:
        return recharge.ids(statuses(state, row)), [], b""
    costs, rolls = [], []
    if opcode == 2032:
        available = config["vip"][str(save["role_state"]["vip"])]["shake_times"] - state["count"]
        count = min(values[0], available)
        if count <= 0:
            raise ValueError("今日聚宝次数已用完")
        prices = config["buycount_price"]
        fees = [prices[str(min(i, max(map(int, prices))))]["shake_cost"] for i in range(state["count"] + 1, state["count"] + count + 1)]
        if any(type(fee) is not int or fee < 0 for fee in fees) or type(row["shake_money"]) is not int or row["shake_money"] <= 0:
            raise ValueError("聚宝盆价格或银币配置无效")
        price = sum(fees)
        rng = random.Random(seed)
        rolls = [multiplier(row, rng) for _ in range(count)]
        reward = recruit.build_reward(save, [(1000, row["shake_money"] * sum(rolls))], config)
        costs = [(1001, price)] if price else []
        state["count"] += count
    else:
        index = values[0]
        if state["count"] < row[f"shake_award{index}"] or index in state["claimed"]:
            raise ValueError("聚宝盆累计次数不足或奖励已领取")
        gets = [tuple(map(int, entry.split(","))) for entry in row[f"shake{index * 10}"].split(";") if entry]
        reward = recruit.build_reward(save, gets, config)
        state["claimed"].append(index)
    get_state(save, config)
    reply = reward + encode_pb_field(12, 2, recharge.ids([*statuses(state, row), *rolls]))
    return reply, costs, reward
