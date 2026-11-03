"""蓬莱仙洞：31格循环探索、真实遭遇战、翻牌和四星奖励。"""

from collections import Counter
from fractions import Fraction
import json
import random

from . import battle, cheer, pets, recharge, recruit
from .protocol import encode_pb_field, iter_pb_fields

QUERIES = (2120, 2124)
MUTATIONS = (2121, 2122, 2123, 2125, 2126, 2127, 2128)
OPCODES = QUERIES + MUTATIONS
ENEMIES = {"monster": 1, "brave": 2, "boss": 3}


def tile(state, position, config):
    return config["penglai3_type"][str(config["penglai3_map"][str(position)][f'map{state["map"]}'])]


def wins(state, config):
    return sum(state["status"][i - 1] for i in range(1, 32) if tile(state, i, config)["type"] in ENEMIES)


def get_state(save, config):
    state = save.setdefault("penglai_state", {"day": 0, "count": 0, "dice": 0, "map": 1,
                           "location": 1, "status": [0] * 31, "claimed": False, "card": None})
    if (not isinstance(state, dict) or any(type(state.get(k)) is not int or not 0 <= state[k] < (1 << 31)
                                         for k in ("day", "count", "dice", "map", "location"))
            or state["map"] not in range(1, 5) or state["location"] not in range(1, 32)
            or state["count"] > max(r["penglai3_times"] for r in config["vip"].values())
            or type(state.get("claimed")) is not bool
            or "card" not in state
            or not isinstance(state.get("status"), list) or len(state["status"]) != 31):
        raise ValueError("蓬莱存档无效")
    for position, value in enumerate(state["status"], 1):
        kind = tile(state, position, config)["type"]
        if type(value) is not int or not 0 <= value <= (5 if kind == "card" else 0 if kind == "start" else 1):
            raise ValueError("蓬莱格子状态无效")
        if kind == "card" and 0 < value < 5 and position != state["location"]:
            raise ValueError("蓬莱未完成的牌局位置无效")
    if state["day"] == 0 and (state["count"] or state["dice"] or any(state["status"]) or state["card"] is not None):
        raise ValueError("蓬莱历史缺少日期")
    if state["claimed"] and wins(state, config) != 4:
        raise ValueError("蓬莱星箱领取记录无效")
    card = state.get("card")
    if card is not None:
        if (not isinstance(card, dict) or not isinstance(card.get("ids"), list) or len(card["ids"]) != 5
                or any(type(cid) is not int or str(cid) not in config["penglai3_card"] for cid in card["ids"])
                or not isinstance(card.get("opened"), list)
                or any(type(i) is not int or i not in range(1, 6) for i in card["opened"])
                or len(set(card["opened"])) != len(card["opened"])
                or any(count > config["penglai3_card"][str(cid)]["appear2"] for cid, count in Counter(card["ids"]).items())
                or tile(state, state["location"], config)["type"] != "card"
                or state["status"][state["location"] - 1] != len(card["opened"])):
            raise ValueError("蓬莱翻牌记录无效")
    elif tile(state, state["location"], config)["type"] == "card" and state["status"][state["location"] - 1] < 5:
        raise ValueError("蓬莱未完成的牌局缺失")
    return state


def query(state, config):
    count = wins(state, config)
    return recharge.ids([state["count"], state["map"], state["dice"], count,
                         2 if state["claimed"] else int(count == 4), state["location"], *state["status"]])


def price(config, ordinal, field):
    value = config["buycount_price"][str(min(ordinal, max(map(int, config["buycount_price"]))))][field]
    if type(value) is not int or value < 0:
        raise ValueError("蓬莱费用配置无效")
    return value


def global_value(config, name):
    value = int(config["global_kv"][name]["value"])
    if value < 0:
        raise ValueError("蓬莱配置数值无效")
    return value


def scaled_reward(specification, save, config):
    values = [int(v) for v in specification.strip(";").split(",")]
    if len(values) != 4 or values[0] <= 0 or values[1] <= 0 or values[2] <= 0 or values[3] < 0:
        raise ValueError("蓬莱奖励配置无效")
    cid, base, interval, growth = values
    return cid, base + (save["role_state"]["level"] - config["build"]["22"]["level"]) // interval * growth


def rosters(save, kind, config):
    row = config["penglai3_monster"][str(kind)][str(save["role_state"]["level"])]
    point = dict(row, level=row["monster_level"])
    for i in range(1, 8):
        if type(point[f"p{i}-grow"]) is not int or point[f"p{i}-grow"] not in (0, 10, 30, 50):
            raise ValueError("蓬莱怪物额外成长配置无效")
        point[f"p{i}-grow"] = 0
        for field in ("adddmgpct", "subdmgpct"):
            point.setdefault(f"{field}{i}-correct", 0)
    attack, defense = battle.rosters(save, point, config)
    for i, position in enumerate(battle.POSITIONS, 1):
        if position in defense:
            # 本地规则：grow为基础三围额外百分比，不放大逐位修正或速度。
            for name in ("atk", "def", "hp"):
                base = defense[position][name] - point[f"{name}{i}-correct"]
                defense[position][name] += base * row[f"p{i}-grow"] // 100
    return attack, defense


def make_cards(config, rng):
    pool = []
    for cid, row in sorted(config["penglai3_card"].items(), key=lambda p: int(p[0])):
        if (type(row["appear1"]) is not int or type(row["appear2"]) is not int
                or not 0 <= row["appear1"] <= row["appear2"] <= 5):
            raise ValueError("蓬莱牌池配置无效")
        pool.extend([int(cid)] * rng.randint(row["appear1"], row["appear2"]))
    if len(pool) < 5:
        raise ValueError("蓬莱牌池不足五张")
    # 本地洗牌规则：按出现数区间生成牌池，再无放回抽五张；牌局保存后不重抽。
    return {"ids": rng.sample(pool, 5), "opened": []}


def flip(state, save, config, slots, all_cards=False):
    card = state["card"]
    if card is None or not slots or any(i in card["opened"] for i in slots):
        raise ValueError("蓬莱牌局不存在、已领取或没有可翻的牌")
    fee, gets = global_value(config, "penglai3_card_akey") if all_cards else 0, []
    free = global_value(config, "penglai3_card_freetimes")
    for slot in slots:
        if not all_cards and len(card["opened"]) >= free:
            ordinal = len(card["opened"]) - free + 1
            fee += global_value(config, "penglai3_card_paytimes" + (str(ordinal) if ordinal > 1 else ""))
        gets.append(scaled_reward(config["penglai3_card"][str(card["ids"][slot - 1])]["param"], save, config))
        card["opened"].append(slot)
    state["status"][state["location"] - 1] = len(card["opened"])
    return fee, gets


def close_cards(state, config):
    if state["card"] is None and tile(state, state["location"], config)["type"] == "card" and state["status"][state["location"] - 1] == 5:
        return  # 自动翻牌已原子关局，允许原生后续确认包安全重试。
    if state["card"] is None or len(state["card"]["opened"]) < global_value(config, "penglai3_card_freetimes"):
        raise ValueError("请先完成免费翻牌")
    state["status"][state["location"] - 1] = 5
    state["card"] = None


def roll(state, save, config, rng, remote=0):
    if state["card"] is not None:
        if len(state["card"]["opened"]) < 5:
            raise ValueError("请先结束当前翻牌")
        state["card"] = None
    free = global_value(config, "penglai3_freetimes")
    costs, gets, report = [], [], None
    if remote:
        entries = [tuple(map(int, e.split(","))) for e in config["global_kv"]["penglai3_diceid"]["value"].split(";") if e]
        if len(entries) != 1 or len(entries[0]) != 2 or min(entries[0]) <= 0:
            raise ValueError("蓬莱遥控器配置无效")
        costs = entries
        distance = remote
    else:
        if state["dice"] >= free:
            costs = [(1001, price(config, state["dice"] - free + 1, "penglai3cost"))]
        row = config["penglai3_dice"].get(str(state["dice"] + 1))
        low, high = (row["probability1"], row["probability2"]) if row else (1, 6)
        if type(low) is not int or type(high) is not int or not 1 <= low <= high <= 6:
            raise ValueError("蓬莱骰子区间配置无效")
        distance = rng.randint(low, high)
        state["dice"] += 1
    path = [(state["location"] - 1 + i) % 31 + 1 for i in range(1, distance + 1)]
    for position in path:
        row = tile(state, position, config)
        if row["type"] not in ENEMIES or state["status"][position - 1]:
            continue
        if report is not None:
            raise ValueError("一个骰子不能返回多份遭遇战报")
        kind, seed = ENEMIES[row["type"]], rng.getrandbits(64)
        attack, defense = rosters(save, kind, config)
        report = battle.simulate(attack, defense, config, seed, attack_pet=pets.combat(save, config), attack_cheer=cheer.combat(save, config))
        report["meta"]["attack"]["n"] = save["role_name"]
        report["meta"]["defense"]["n"] = row["desc"]
        if report["result"]:
            state["status"][position - 1] = 1
            monster = config["penglai3_monster"][str(kind)][str(save["role_state"]["level"])]
            gets.append((monster["drop"], monster["drop_number"]))
        save["last_penglai_battle"] = {"rules": report["rules"], "seed": seed, "position": position,
                                      "kind": kind, "won": report["result"], "rounds": report["round"]}
    state["location"] = path[-1]
    row = tile(state, state["location"], config)
    if not state["status"][state["location"] - 1]:
        if row["type"] in ("box", "prop"):
            if row["type"] == "prop":
                deck = [tuple(map(int, e.split(","))) for e in row["param"].split(";") if e]
                if not deck or any(len(e) != 2 or str(e[0]) not in config["penglai3_type"] or e[1] < 0 for e in deck) or sum(e[1] for e in deck) <= 0:
                    raise ValueError("蓬莱宝箱权重无效")
                ticket = rng.randrange(sum(weight for _, weight in deck))
                for cid, weight in deck:
                    ticket -= weight
                    if ticket < 0:
                        row = config["penglai3_type"][str(cid)]
                        break
            gets.append(scaled_reward(row["param"], save, config))
            state["status"][state["location"] - 1] = 1
        elif row["type"] == "card":
            state["card"] = make_cards(config, rng)
    return costs, gets, report


def comb(messages):
    return b"".join(encode_pb_field(1, 2, encode_pb_field(1, 0, mid) + encode_pb_field(2, 2, data)) for mid, data in messages)


def prepare(opcode, save, body, config, now, seed):
    fields = list(iter_pb_fields(body))
    if any(n != 1 or w != 0 or not 0 <= value < (1 << 31) for n, w, value in fields):
        raise ValueError("蓬莱请求格式错误")
    values = [v for _, _, v in fields]
    if (opcode in (2120, 2122, 2123, 2124, 2126) and values
            or opcode == 2121 and values and (len(values) != 1 or values[0] not in range(1, 7))
            or opcode == 2125 and (len(values) != 2 or values[0] not in (0, 1) or values[1] not in range(1, 6) or values[0] == 1 and values[1] != 1)
            or opcode in (2127, 2128) and (len(values) != 1 or values[0] not in (0, 1))):
        raise ValueError("蓬莱操作参数无效")
    if (not save.get("has_role") or save["role_state"]["level"] < config["build"]["22"]["level"]
            or save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2):
        raise ValueError("蓬莱仙洞尚未解锁")
    state, rng = get_state(save, config), random.Random(seed)
    day = (now + 28800) // 86400
    if day > state["day"]:
        state.update(day=day, count=0, dice=0, map=1, location=1, status=[0] * 31, claimed=False, card=None)
    if opcode in MUTATIONS and day != state["day"]:
        raise ValueError("蓬莱服务器日期回拨，请稍后重试")
    if opcode == 2120:
        return query(state, config), [], b""
    if opcode == 2124:
        if state["card"] is None:
            raise ValueError("当前没有待翻的牌")
        card = state["card"]
        return recharge.ids([len(card["opened"]), *(v for i, cid in enumerate(card["ids"], 1) for v in (cid, int(i in card["opened"])))]), [], b""
    costs, gets, report = [], [], None
    if opcode in (2121, 2128):
        from . import achievements
        if opcode == 2128 and (save["role_state"]["level"] < global_value(config, "penglai_onekey_openlv")
                              and not config["vip"][str(save["role_state"]["vip"])]["penglai3_onekey"]):
            raise ValueError("蓬莱一键探索等级或VIP不足")
        count = 1 if opcode == 2121 else global_value(config, "penglai3_freetimes") - state["dice"]
        if not 1 <= count <= 100:
            raise ValueError("没有剩余免费骰子或批次数无效")
        for _ in range(count):
            fee, prizes, report = roll(state, save, config, rng, values[0] if opcode == 2121 and values else 0)
            achievements.record(save, "penglairewardcount", 1, config)
            costs.extend(fee)
            gets.extend(prizes)
            if opcode == 2128 and state["card"] is not None:
                remaining = [i for i in range(1, 6) if i not in state["card"]["opened"]]
                if not values[0]:
                    remaining = remaining[:global_value(config, "penglai3_card_freetimes")]
                fee, prizes = flip(state, save, config, remaining, bool(values[0]))
                costs.append((1001, fee))
                gets.extend(prizes)
                close_cards(state, config)
            if report is not None and not report["result"]:
                break
    elif opcode == 2122:
        if wins(state, config) != 4 or state["claimed"]:
            raise ValueError("蓬莱四星奖励尚未达成或已领取")
        gets = [scaled_reward(config["penglai3_type"]["16"]["param"], save, config)]
        state["claimed"] = True
    elif opcode == 2123:
        if (state["card"] is not None and len(state["card"]["opened"]) < 5
                or wins(state, config) == 4 and not state["claimed"]):
            raise ValueError("请先结束翻牌并领取已达成的四星奖励")
        if state["count"] >= config["vip"][str(save["role_state"]["vip"])]["penglai3_times"]:
            raise ValueError("蓬莱今日重置次数已用完")
        costs = [(1001, price(config, state["count"] + 1, "penglai3reset"))]
        state.update(count=state["count"] + 1, map=rng.randrange(1, 5), location=1, status=[0] * 31, claimed=False, card=None)
    elif opcode == 2126:
        close_cards(state, config)
    else:
        if state["card"] is None:
            raise ValueError("当前没有待翻的牌")
        remaining = [i for i in range(1, 6) if i not in state["card"]["opened"]]
        if opcode == 2125 and not values[0]:
            remaining = [values[1]]
        if opcode == 2127 and not values[0]:
            remaining = remaining[:max(0, global_value(config, "penglai3_card_freetimes") - len(state["card"]["opened"]))]
        fee, gets = flip(state, save, config, remaining, bool(values[0]))
        costs = [(1001, fee)]
        if opcode == 2127:
            close_cards(state, config)
    weekday = (day + 3) % 7 + 1
    factor = next((Fraction(str(r["modulus"])) for r in config["activity_huodong"].values()
                   if r["param"] == 5 and r["open_time"] == weekday), Fraction(1))
    prizes = Counter()
    for cid, count in gets:
        prizes[cid] += int(count * factor)
    reward = recruit.build_reward(save, sorted(prizes.items()), config)
    if opcode == 2121:
        fight = (encode_pb_field(1, 0, int(report["result"])) + encode_pb_field(2, 0, report["star"])
                 + encode_pb_field(5, 2, json.dumps(report, ensure_ascii=False, separators=(",", ":")).encode())) if report else b""
        reply = comb([(0, query(state, config))] + ([(1, fight)] if report else []) + [(2, reward)])
    elif opcode == 2128:
        reply = comb([(0, recharge.ids([sum(n for cid, n in costs if cid == 1001)])),
                      (1, query(state, config)), (3, reward), (4, recharge.ids([int(report["result"]) if report else 1]))])
    else:
        reply = query(state, config) if opcode in (2123, 2126) else reward
    get_state(save, config)
    return reply, [(cid, count) for cid, count in costs if count], reward
