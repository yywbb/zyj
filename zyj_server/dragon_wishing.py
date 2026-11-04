"""神龙许愿：139格分路、真实骰子恢复、原事件／NPC与每日龙珠。"""

import random

from . import activities, battle, cheer, development, pets, recruit
from .guild_boss import battle_result
from .guild_games import pairs
from .penglai import comb, price
from .protocol import encode_pb_field
from .recharge import ids

QUERIES = (4901, 4907)
MUTATIONS = (4902, 4903, 4904, 4905, 4906)
OPCODES = QUERIES + MUTATIONS


def value(config, key):
    return int(config["global_kv"]["shenlong_" + key]["value"])


def roads(config):
    return {int(key): [int(p) for p in row["param"].split(",")] for key, row in config["shenlong_map2"].items()}


def layout(state, config):
    return config["shenlong_random2"][str(state["map"])]


def get_state(save, config):
    state = save.get("dragon_wishing_state")
    if state is None:
        return None
    try:
        for key in ("day", "checked_at", "next_at", "dice", "bought", "balls", "buff", "serial", "wishes"):
            if type(state[key]) is not int or not 0 <= state[key] < (1 << 31):
                raise ValueError
        if state["balls"] > 7 or state["buff"] > 2 or state["serial"] < 1 or type(state["ball_today"]) is not bool or type(state["seen"]) is not bool:
            raise ValueError
        if (type(state["map"]) is not int or str(state["map"]) not in config["shenlong_random2"]
                or not isinstance(state["points"], list) or len(state["points"]) != 139
                or not isinstance(state["shop"], list) or len(state["shop"]) != 4
                or any(type(v) is not int or v not in (0, 1) for v in state["shop"])):
            raise ValueError
        for pos, mark in enumerate(state["points"], 1):
            kind = layout(state, config).get(f"point{pos}", 0)
            if type(mark) is not int or mark not in (0, kind - 5 if 6 <= kind <= 9 else 1) or kind == 0 and mark:
                raise ValueError
        path, paths = state["path"], roads(config)
        if not isinstance(path, list) or not 1 <= len(path) <= 1024:
            raise ValueError
        for road, index in path:
            if type(road) is not int or type(index) is not int or road not in paths or not 0 <= index < len(paths[road]):
                raise ValueError
        for (road, index), (next_road, next_index) in zip(path, path[1:]):
            if index + 1 < len(paths[road]):
                valid = (next_road, next_index) == (road, index + 1)
            else:
                row = config["shenlong_map2"][str(road)]
                valid = next_road in (row["road"], row["road_1"], row["road_2"]) and next_index == int(paths[next_road][0] == paths[road][index])
            if not valid:
                raise ValueError
        pending = state["pending"]
        if pending is not None:
            if (type(pending["event"]) is not int or pending["event"] not in (3, 5, 6, 7, 8, 9, *map(int, config["shenlong_praram"]))
                    or type(pending["boss"]) is not int or pending["boss"] not in range(5)
                    or type(pending["level"]) is not int or not 1 <= pending["level"] <= 150
                    or not state["points"][paths[path[-1][0]][path[-1][1]] - 1]):
                raise ValueError
            if pending["event"] in (5, 6, 7, 8, 9) and pending["boss"] not in range(1, 5):
                raise ValueError
            eid = pending["event"]
            kind = layout(state, config).get(f"point{paths[path[-1][0]][path[-1][1]]}", 0)
            if (not (kind == eid or kind in (1, 4) and str(eid) in config["shenlong_praram"] or kind == 1 and eid in (3, 5))
                    or eid in (6, 7, 8, 9) and pending["boss"] != eid - 5
                    or eid == 5 and pending["boss"] not in (1, 2, 3)
                    or (eid == 3 or eid > 10000) and pending["boss"] != 0):
                raise ValueError
        if state["dice"] >= value(config, "dice_limit") and state["next_at"]:
            raise ValueError
    except (KeyError, ValueError, TypeError, AttributeError):
        raise ValueError("神龙许愿地图、骰子或事件存档无效") from None
    return state


def fresh_map(state, config, variant):
    state.update(map=variant, path=[[1, 0]], pending=None, shop=[0] * 4)
    state["points"] = [kind - 5 if 6 <= kind <= 9 else int(bool(kind))
                       for pos in range(1, 140) for kind in [layout(state, config).get(f"point{pos}", 0)]]


def settle(save, config, now):
    state = get_state(save, config)
    if state is None:
        state = {"day": (now + 28800) // 86400, "checked_at": now, "next_at": 0,
            "dice": value(config, "dice_init"), "bought": 0, "balls": 0, "ball_today": False,
            "buff": 0, "serial": 1, "wishes": 0, "seen": False}
        fresh_map(state, config, (state["day"] % len(config["shenlong_random2"])) + 1)
        save["dragon_wishing_state"] = state
    day = (now + 28800) // 86400
    if day > state["day"]:
        state.update(day=day, bought=0, ball_today=False)
    limit, interval = value(config, "dice_limit"), value(config, "dice_regian") * 60
    if state["dice"] < limit and state["next_at"] and now >= state["next_at"]:
        count = min(limit - state["dice"], (now - state["next_at"]) // interval + 1)
        state["dice"] += count
        state["next_at"] += count * interval
    if state["dice"] >= limit:
        state["next_at"] = 0
    elif not state["next_at"]:
        state["next_at"] = max(now, state["checked_at"]) + interval
    state["checked_at"] = max(now, state["checked_at"])
    return state


def change_dice(state, delta, config, now):
    if not 0 <= state["dice"] + delta < (1 << 31):
        raise ValueError("骰子不足或数量超出范围")
    previous = state["dice"]
    state["dice"] += delta
    limit = value(config, "dice_limit")
    if state["dice"] >= limit:
        state["next_at"] = 0
    elif previous >= limit or not state["next_at"]:
        state["next_at"] = now + value(config, "dice_regian") * 60


def position(state, config):
    road, index = state["path"][-1]
    return roads(config)[road][index]


def query(state, config, now, first=False):
    event = state["pending"]
    return ids([state["map"], state["balls"], int(state["balls"] == 7), int(state["ball_today"]),
        state["dice"], 2 if state["buff"] else 1, max(0, state["next_at"] - now) if state["next_at"] else 0,
        state["bought"], position(state, config), event["event"] if event else 0, 0 if event else 1,
        *state["shop"], *state["points"], int(first), state["serial"]])


def weighted(entries, rng):
    if not entries or any(weight < 0 for *_, weight in entries) or sum(row[-1] for row in entries) <= 0:
        raise ValueError("神龙奖励权重配置无效")
    ticket = rng.randrange(sum(row[-1] for row in entries))
    for row in entries:
        ticket -= row[-1]
        if ticket < 0:
            return row[:-1]


def prop_reward(text, save, config, rng):
    entries = [tuple(map(int, entry.split(","))) for entry in text.strip(";").split(";")]
    if any(len(row) != 5 or row[0] <= 0 or row[1] <= 0 or row[2] <= 0 or row[3] < 0 for row in entries):
        raise ValueError("神龙格子奖励配置无效")
    cid, base, interval, growth = weighted(entries, rng)
    return [(cid, base + (save["role_state"]["level"] - config["build"]["308"]["level"]) // interval * growth)]


def simulate(save, boss, level, config, seed):
    row = config["zodiac_new"][str(boss)][str(level)]
    point = dict(row)
    for i in range(1, 8):
        if type(point[f"p{i}-grow"]) is not int or point[f"p{i}-grow"] not in (0, 1, 2):
            raise ValueError("神龙怪物额外成长配置无效")
        point[f"p{i}-grow"] = 0
        point.setdefault(f"adddmgpct{i}-correct", 0)
        point.setdefault(f"subdmgpct{i}-correct", 0)
    attack, defense = battle.rosters(save, point, config)
    for i, pos in enumerate(battle.POSITIONS, 1):
        if pos in defense:
            for name in ("atk", "def", "hp"):
                defense[pos][name] += (defense[pos][name] - row[f"{name}{i}-correct"]) * row[f"p{i}-grow"] // 100
            for name in ("critical", "dodge", "parry", "resilience", "hit", "arp", "criticaldmg"):
                defense[pos][name] += row[f"{name}{i}-correct"]
            defense[pos]["initial_ap"] = row[f"rage{i}-correct"]
    return battle.simulate(attack, defense, config, seed, attack_pet=pets.combat(save, config), attack_cheer=cheer.combat(save, config))


def finish_boss(state, save, config, now, rng, fight=True):
    pending = state["pending"]
    text = config["shenlong_type"]["5"]["param"] if pending["event"] == 5 else config["zodiac_new"][str(pending["boss"])][str(pending["level"])]["reward"]
    gets = list(pairs(text).items()) if fight else []
    if pending["event"] == 9:
        if not state["ball_today"]:
            state["ball_today"] = True
            state["balls"] += 1
        else:
            gets.extend(prop_reward(config["shenlong_type"]["27"]["param"], save, config, rng))
    elif fight and pending["event"] in (6, 7, 8):
        # 本地口径：原boss1–3的2,2表示接下来两次掷两个骰子；boss4的0,10不猜成额外奖励。
        state["buff"] = 2
    state["points"][position(state, config) - 1] = 0
    state["pending"] = None
    return gets


def step(state, config, rng):
    paths = roads(config)
    road, index = state["path"][-1]
    if index + 1 == len(paths[road]):
        row = config["shenlong_map2"][str(road)]
        options = sorted({row[k] for k in ("road", "road_1", "road_2") if row[k]})
        road = rng.choice(options)
        index = 0 if paths[road][0] != position(state, config) else 1
    else:
        index += 1
    state["path"].append([road, index])
    state["path"] = state["path"][-64:]  # 箭头最多后退2格，不保留整轮循环路线。
    return paths[road][index]


def roll(state, save, config, now, rng):
    if state["pending"] or state["balls"] == 7:
        raise ValueError("请先处理当前事件或召唤神龙")
    if position(state, config) == 139 and state["points"][138] == 0:
        fresh_map(state, config, rng.choice(sorted(map(int, config["shenlong_random2"]))))
    dice = [rng.randint(1, 6), rng.randint(1, 6) if state["buff"] else 0]
    if state["buff"]:
        state["buff"] -= 1
    route, report, gets, event = [], None, [], 0
    remaining, forced = sum(dice), False
    for _ in range(40):
        if remaining > 0:
            pos = step(state, config, rng)
            remaining -= 1
            route.append(pos)
        elif remaining < 0 and len(state["path"]) > 1:
            state["path"].pop()
            pos = position(state, config)
            route.append(pos)
            remaining += 1
        else:
            break
        kind = layout(state, config).get(f"point{pos}", 0)
        if not state["points"][pos - 1]:
            continue
        if 6 <= kind <= 9:
            state["pending"] = {"event": kind, "boss": kind - 5, "level": save["role_state"]["level"]}
            report = simulate(save, kind - 5, save["role_state"]["level"], config, rng.getrandbits(64))
            if report["result"]:
                gets.extend(finish_boss(state, save, config, now, rng))
            break
        if remaining == 0:
            row = config["shenlong_type"].get(str(kind), {})
            if row.get("type") in ("increase", "decrease") and not forced:
                forced = True
                state["points"][pos - 1] = 0
                remaining = int(row["param"]) * (1 if row["type"] == "increase" else -1)
    if not route:
        raise ValueError("神龙地图没有可走的道路")
    pos = position(state, config)
    kind = layout(state, config).get(f"point{pos}", 0)
    if not report and state["points"][pos - 1]:
        row = config["shenlong_type"][str(kind)]
        event = kind
        if row["type"] == "adventure":
            event = weighted([tuple(map(int, e.split(","))) for e in row["param"].strip(";").split(";")], rng)[0]
        if event == 4:
            event = weighted([tuple(map(int, e.split(","))) for e in config["shenlong_type"]["4"]["param"].strip(";").split(";")], rng)[0]
        if event in (3, 5) or str(event) in config["shenlong_praram"]:
            state["pending"] = {"event": event, "boss": rng.randint(1, 3) if event == 5 else 0, "level": save["role_state"]["level"]}
            if event == 3:
                state["shop"] = [0] * 4
        else:
            state["points"][pos - 1] = 0
            if row["type"] == "dice":
                change_dice(state, 1, config, now)
            elif row["type"] == "prop":
                gets.extend(prop_reward(row["param"], save, config, rng))
    return dice, route, report, gets, state["pending"]["event"] if state["pending"] else event


def prepare(opcode, save, body, config, now, seed):
    values = development.ids(body)
    counts = {4901: 0, 4907: 0, 4902: 3, 4903: 2, 4904: 2, 4905: 1, 4906: 4}
    if len(values) != counts[opcode]:
        raise ValueError("神龙许愿请求参数错误，请使用配套客户端")
    if (not save.get("has_role") or save["role_state"]["level"] < config["build"]["308"]["level"]
            or save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2):
        raise ValueError("神龙许愿尚未解锁")
    previous = get_state(save, config)
    if opcode in MUTATIONS and previous and now < previous["checked_at"]:
        raise ValueError("神龙时钟发生回拨，请稍后重试")
    state, rng = settle(save, config, now), random.Random(seed)
    if opcode == 4907:
        return ids([2]), [], b""
    if opcode == 4901:
        reply = query(state, config, max(now, state["checked_at"]), not state["seen"])
        state["seen"] = True
        return reply, [], b""
    serial = values[0] if opcode == 4902 else values[-1]
    if serial != state["serial"] or serial >= (1 << 31) - 1:
        raise ValueError("神龙状态已变化，请重新查询；旧事件不能再次处理")
    costs, gets, report, delta_dice = [], [], None, 0
    if opcode == 4902:
        _, quote, auto = values
        gold = 0 if state["dice"] else price(config, state["bought"] + 1, "shenlong_dice_cost")
        if quote != gold or auto not in (0, 1):
            raise ValueError("神龙骰子价格已变化，请刷新")
        if auto and (not state["dice"] or save["role_state"]["level"] < value(config, "quick_complete_level")
                or save["role_state"]["level"] < value(config, "quick_complete_level2") and save["role_state"]["vip"] < value(config, "quick_complete_vip")):
            raise ValueError("一键探索条件不足或没有免费骰子，未自动购买")
        if gold:
            state["bought"] += 1
            costs = [(1001, gold)]
        else:
            change_dice(state, -1, config, now)
        dice, route, report, gets, event_id = roll(state, save, config, now, rng)
        activities.record_liveness(save, 43, 1, config, now)
    elif opcode == 4903:
        if state["balls"] != 7 or values[0] not in (1, 2, 3):
            raise ValueError("请集齐七颗龙珠后选择许愿奖励")
        level = min(int(k) for k in config["shenlong_reward"] if int(k) >= save["role_state"]["level"])
        deck = [tuple(map(int, entry.split(","))) for entry in config["shenlong_reward"][str(level)][f"reward{values[0]}"].strip(";").split(";")]
        gets = [tuple(weighted(deck, rng))]
        state.update(balls=0, wishes=state["wishes"] + 1)
    else:
        event = state["pending"]
        if not event:
            raise ValueError("当前没有待处理的神龙事件")
        eid, option = event["event"], values[0]
        if opcode == 4906:
            if eid != 3 or not 1 <= option <= 4 or not 1 <= values[1] <= 100:
                raise ValueError("神龙商店不可购买该商品")
            level = min(int(k) for k in config["shenlong_discount"] if int(k) >= save["role_state"]["level"])
            row = config["shenlong_discount"][str(level)][str(option)]
            if state["shop"][option - 1] + values[1] > row["count"] or values[2] != row["price"]:
                raise ValueError("神龙商品剩余次数不足或价格已变")
            costs = [(1001, row["price"] * values[1])]
            gets = [(cid, count * values[1]) for cid, count in pairs(row["target"]).items()]
            state["shop"][option - 1] += values[1]
        elif opcode == 4905:
            if eid == 9:
                raise ValueError("终点守卫尚未通过，不能直接关闭跳过")
            state["points"][position(state, config) - 1] = 0
            state["pending"] = None
        elif opcode == 4904:
            if str(eid) in config["shenlong_praram"]:
                if option not in (1, 2):
                    raise ValueError("请选择问题的两个原始选项")
                row = config["shenlong_praram"][str(eid)]
                costs = list(pairs(row[f"cost{option}"]).items())
                gets = list(pairs(row[f"bonus{option}"]).items())
                used = sum(count for cid, count in costs if cid == 1022)
                delta_dice = sum(count for cid, count in gets if cid == 1022) - used
                if used > state["dice"]:
                    raise ValueError("该选项需要更多骰子")
                change_dice(state, delta_dice, config, now)
                costs, gets = [(cid, n) for cid, n in costs if cid != 1022], [(cid, n) for cid, n in gets if cid != 1022]
                state["points"][position(state, config) - 1] = 0
                state["pending"] = None
            elif eid in (5, 6, 7, 8, 9):
                allowed = (1, 2) if eid in (5, 9) else (2, 3)
                if option not in allowed:
                    raise ValueError("守卫处理选项无效")
                if option == 1:
                    report = simulate(save, event["boss"], event["level"], config, rng.getrandbits(64))
                    if report["result"]:
                        gets = finish_boss(state, save, config, now, rng)
                elif option == 2 and eid != 5:
                    costs = [(1001, value(config, "skip"))]
                    gets = finish_boss(state, save, config, now, rng, fight=False)
                else:
                    state["points"][position(state, config) - 1] = 0
                    state["pending"] = None
            else:
                raise ValueError("该神龙事件不接受选择")
    state["serial"] += 1
    reward = recruit.build_reward(save, gets, config)
    if opcode in (4902, 4904):
        head = ids([*dice, event_id, *route]) if opcode == 4902 else ids([delta_dice & ((1 << 64) - 1)])
        reply = comb([(0, head), (1, b"" if report else reward)] + ([(2, battle_result(report, reward))] if report else []))
    elif opcode == 4906:
        reply = comb([(0, ids(state["shop"])), (1, reward)])
    else:
        reply = reward if opcode == 4903 else b""
    get_state(save, config)
    return reply + encode_pb_field(100, 2, query(state, config, now)), costs, reward
