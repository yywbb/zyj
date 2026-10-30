"""元宝商店：九个配置加权货架、定时/付费刷新与限购。"""

import random

from . import recharge, recruit
from .protocol import iter_pb_fields, pb_get_varint


QUERIES = (3630,)
MUTATIONS = (3631, 3632)
OPCODES = QUERIES + MUTATIONS


def get_state(save, config):
    state = save.setdefault("blackmarket_state", {"period": 0, "day": 0, "refreshes": 0, "slots": []})
    if (not isinstance(state, dict) or any(type(state.get(k)) is not int or not 0 <= state[k] < (1 << 31)
                                         for k in ("period", "day", "refreshes"))
            or not isinstance(state.get("slots"), list)):
        raise ValueError("元宝商店存档无效")
    if len(state["slots"]) not in (0, len(config["blackmarket_pos"])) or not state["slots"] and state["period"]:
        raise ValueError("元宝商店货架存档无效")
    for item in state["slots"]:
        if (not isinstance(item, list) or len(item) != 2 or any(type(v) is not int for v in item)
                or str(item[0]) not in config["blackmarket_items"]
                or not 0 <= item[1] <= config["blackmarket_items"][str(item[0])]["limit"]):
            raise ValueError("元宝商店商品存档无效")
    return state


def period(config, now):
    day = (now + 28800) // 86400
    times = [day * 86400 - 28800 + row["hour"] * 3600 for row in config["blackmarket_refresh"].values()]
    return max(at for at in times if at <= now), day


def refresh(save, config, state, seed):
    rng = random.Random(seed)
    level, vip = save["role_state"]["level"], save["role_state"]["vip"]
    guaranteed = int(config["global_kv"]["blackmarket_end_times"]["value"])
    pool = "items2" if state["refreshes"] and state["refreshes"] % guaranteed == 0 else "items"
    slots = []
    for _, position in sorted(config["blackmarket_pos"].items(), key=lambda item: int(item[0])):
        entries = [tuple(map(int, item.split(","))) for item in position[pool].split(";") if item]
        if any(len(item) != 2 or item[0] <= 0 or item[1] < 0 for item in entries):
            raise ValueError("元宝商店货架权重无效")
        choices = [(iid, weight) for iid, weight in entries if weight > 0
                   and config["blackmarket_items"][str(iid)]["down_level"] <= level <= config["blackmarket_items"][str(iid)]["up_level"]
                   and config["blackmarket_items"][str(iid)]["vip"] <= vip]
        if not choices:
            raise ValueError("元宝商店缺少当前等级可用的商品")
        slots.append([rng.choices([v[0] for v in choices], weights=[v[1] for v in choices])[0], 0])
    state["slots"] = slots


def response(state):
    return recharge.ids([state["refreshes"], *(value for item in state["slots"] for value in item)])


def prepare(opcode, save, body, config, now, seed):
    if not save.get("has_role") or save["role_state"]["level"] < config["build"]["131"]["level"]:
        raise ValueError("元宝商店尚未解锁")
    fields = list(iter_pb_fields(body))
    if opcode != 3631 and fields:
        raise ValueError("元宝商店查询和刷新不接受参数")
    if opcode == 3631 and (len(fields) != 2 or any(n != 1 or w != 0 or not 0 < v < (1 << 31) for n, w, v in fields)):
        raise ValueError("元宝商店购买需要货架位置和数量")
    state = get_state(save, config)
    current, day = period(config, now)
    if opcode in MUTATIONS and (not state["slots"] or current > state["period"]):
        raise ValueError("商品已到刷新时间，请重新打开元宝商店")
    if day > state["day"]:
        state.update(day=day, refreshes=0)
    if opcode == 3630:
        if not state["slots"] or current > state["period"]:
            refresh(save, config, state, seed)
            state["period"] = current
        return response(state), [], b""
    if opcode == 3631:
        position, count = [v for _, _, v in fields]
        if not 1 <= position <= len(state["slots"]) or not 1 <= count <= 100:
            raise ValueError("元宝商店货架位置或数量无效")
        item = state["slots"][position - 1]
        row = config["blackmarket_items"][str(item[0])]
        if item[1] + count > row["limit"]:
            raise ValueError("此商品剩余购买次数不足")
        costs = [(int(cid), int(num) * count) for entry in row["consume"].split(";") if entry for cid, num in [entry.split(",")]]
        if len(costs) != 1 or costs[0][0] not in (1000, 1001) or costs[0][1] <= 0:
            raise ValueError("元宝商店商品价格无效")
        gets = [(int(cid), int(num) * count) for entry in row["good"].split(";") if entry for cid, num in [entry.split(",")]]
        reward = recruit.build_reward(save, gets, config)
        item[1] += count
        return reward, costs, reward
    cid, quantity = map(int, config["global_kv"]["blackmarket_refreshprop"]["value"].rstrip(";").split(","))
    available = next((pb_get_varint(raw, 2) for n, w, raw in iter_pb_fields(bytes.fromhex(save["world_state"]["1200"]))
                      if (n, w) == (1, 2) and pb_get_varint(raw, 1) == cid), 0)
    if available >= quantity:
        costs = [(cid, quantity)]
    else:
        prices = config["buycount_price"]
        price = prices[str(min(state["refreshes"] + 1, max(map(int, prices))))]["blackmarket_refreshgold"]
        costs = [(1001, price)]
    state["refreshes"] += 1
    refresh(save, config, state, seed)
    get_state(save, config)
    return response(state), costs, b""
