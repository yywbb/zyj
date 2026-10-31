"""乾坤炉神魂商店：六格持久货架、魂蛋交易及免费/道具/元宝刷新。"""

import random

from . import recharge, recruit, shop
from .protocol import iter_pb_fields, pb_get_varint

QUERIES = (3650,)
MUTATIONS = (3651, 3652)
OPCODES = QUERIES + MUTATIONS


def get_state(save, config):
    state = save.setdefault("secret_shop_state", {"day": 0, "period": 0, "refreshes": 0, "slots": []})
    if (not isinstance(state, dict)
            or any(type(state.get(k)) is not int or not 0 <= state[k] < (1 << 31) for k in ("day", "period", "refreshes"))
            or not isinstance(state.get("slots"), list) or len(state["slots"]) not in (0, 6)):
        raise ValueError("神魂商店存档无效")
    for item in state["slots"]:
        if (not isinstance(item, list) or len(item) != 2 or any(type(v) is not int for v in item)
                or str(item[0]) not in config["mystery_shop"]
                or not 0 <= item[1] <= config["mystery_shop"][str(item[0])]["limit"]):
            raise ValueError("神魂商店商品存档无效")
    if len({item[0] for item in state["slots"]}) != len(state["slots"]):
        raise ValueError("神魂商店商品重复")
    return state


def refresh(save, state, config, now, seed):
    level, vip = save["role_state"]["level"], save["role_state"]["vip"]
    rows = [v for v in config["mystery_shop"].values()
            if v["down_level"] <= level <= v["up_level"] and v["vip"] <= vip and shop.in_period(v, now)
            and v["probability"] > 0]
    rng = random.Random(seed)
    state["slots"] = []
    # shortcut: 无原服刷新序号保底证据，按配置权重抽六个不同商品；有证据后接入basic_times/refresh_times。
    for _ in range(6):
        if not rows:
            raise ValueError("神魂商店缺少当前等级可用的商品")
        selected = rng.choices(rows, [r["probability"] for r in rows])[0]
        state["slots"].append([selected["id"], 0])
        rows.remove(selected)


def response(save, state, config):
    free = max(0, config["vip"][str(save["role_state"]["vip"])]["mystery_shop_times"] - state["refreshes"])
    return recharge.ids([free, *(v for item in state["slots"] for v in item)])


def prepare(opcode, save, body, config, now, seed):
    if not save.get("has_role") or save["role_state"]["level"] < config["build"]["134"]["level"]:
        raise ValueError("神魂商店尚未解锁")
    fields = list(iter_pb_fields(body))
    if opcode != 3651 and body:
        raise ValueError("神魂商店查询和刷新不接受参数")
    if opcode == 3651 and (len(fields) != 2 or any(n != 1 or w != 0 or not 0 < v < (1 << 31) for n, w, v in fields)):
        raise ValueError("神魂商店购买需要货架位置和数量")
    state = get_state(save, config)
    day, period = (now + 28800) // 86400, (now + 28800) // 7200
    if opcode in MUTATIONS and (not state["slots"] or period > state["period"]):
        raise ValueError("神魂商店已到刷新时间，请重新进入")
    if day > state["day"]:
        state.update(day=day, refreshes=0)
    if opcode == 3650:
        if not state["slots"] or period > state["period"]:
            refresh(save, state, config, now, seed)
            state["period"] = max(state["period"], period)
        return response(save, state, config), [], b""
    if opcode == 3651:
        index, count = [v for _, _, v in fields]
        if not 1 <= index <= 6 or count != 1:
            raise ValueError("神魂商店货架或购买数量无效")
        item = state["slots"][index - 1]
        row = config["mystery_shop"][str(item[0])]
        if (item[1] + count > row["limit"] or not row["down_level"] <= save["role_state"]["level"] <= row["up_level"]
                or row["vip"] > save["role_state"]["vip"] or not shop.in_period(row, now)):
            raise ValueError("神魂商店商品已售罄或购买条件不足")
        costs = [tuple(map(int, e.split(","))) for e in row["consume"].split(";") if e]
        gets = [tuple(map(int, e.split(","))) for e in row["good"].split(";") if e]
        if len(costs) != 1 or costs[0][0] != 20200 or costs[0][1] <= 0:
            raise ValueError("神魂商店价格无效")
        reward = recruit.build_reward(save, gets, config)
        item[1] += count
        return reward, costs, reward
    free = config["vip"][str(save["role_state"]["vip"])]["mystery_shop_times"]
    costs = []
    if state["refreshes"] >= free:
        cid, count = map(int, config["global_kv"]["mysteryshop_refreshprop"]["value"].rstrip(";").split(","))
        props = bytes.fromhex(save["world_state"]["1200"])
        available = next((pb_get_varint(v, 2) for n, w, v in iter_pb_fields(props)
                          if (n, w) == (1, 2) and pb_get_varint(v, 1) == cid), 0)
        costs = [(cid, count)] if available >= count else [(1001, int(config["global_kv"]["mysteryshop_refreshgold"]["value"]))]
    state["refreshes"] += 1
    refresh(save, state, config, now, seed)
    get_state(save, config)
    return response(save, state, config), costs, b""
