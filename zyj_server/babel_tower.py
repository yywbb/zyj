"""通天塔：6 大章节 × 配置关卡，顺序首通、每日次数、三星条件、扫荡/商店/排行。

所有进度来自真实战斗与真实配置；回包形状严格按原生 GameBabelTower.lua 组包。
7010 是跨系统通用的「仙元购买次数」，只有 sysId=450 由本模块结算。
"""

import json
import random

from . import activities, battle, cheer, pets
from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint
from .recharge import ids

QUERIES = (7011, 7012, 7014, 7017, 7019)
MUTATIONS = (7013, 7015, 7016, 7018)
OPCODES = (*QUERIES, *MUTATIONS)
BUY_TIMES = 7010
STATUS_FIELDS = 10
LEVEL_FIELDS = 7
SHOP_CURRENCIES = (1025, 20809)


def comb(messages):
    return b"".join(encode_pb_field(1, 2, encode_pb_field(1, 0, mid) + encode_pb_field(2, 2, data))
                    for mid, data in messages)


def parse(body, count=None):
    fields = list(iter_pb_fields(body))
    if any((n, w) != (1, 0) or not 0 <= v < (1 << 31) for n, w, v in fields):
        raise ValueError("通天塔参数格式无效")
    values = [v for _, _, v in fields]
    if count is not None and len(values) != count:
        raise ValueError("通天塔参数个数无效")
    return values


def maps(config):
    return sorted(int(key) for key in config["tongtianta_guaiwu"])


def levels(config, map_id):
    return config["tongtianta_guaiwu"][str(map_id)]


def fresh(save, config):
    state = {
        "day": 0, "checked_at": 0, "max_point": 1, "cur_point": 0,
        "used": 0, "bought": 0, "awards": [0] * len(maps(config)),
        "levels": {str(mid): [{"stars": [0, 0, 0], "used": 0, "daily": 0, "first": 0, "auto": 0}
                              for _ in levels(config, mid)] for mid in maps(config)},
        "shop": {key: 0 for key in config["tongtianta_shangdian"]},
        "best": {"point": 1, "level": 0},
    }
    save["babel_tower_state"] = state
    return state


def integer(value, low, high):
    return type(value) is int and low <= value <= high


def get_state(save, config):
    state = save.get("babel_tower_state")
    if state is None:
        return fresh(save, config)
    available = maps(config)
    try:
        if (not isinstance(state, dict)
                or any(not integer(state.get(k), 0, 1 << 31) for k in ("day", "checked_at", "used", "bought"))
                or state["day"] >= 1 << 31
                or not integer(state["max_point"], 1, len(available))
                or not integer(state["cur_point"], 0, len(available))
                or state["cur_point"] > state["max_point"]
                or not isinstance(state["awards"], list) or len(state["awards"]) != len(available)
                or any(v not in (0, 1, 2) for v in state["awards"])
                or not isinstance(state["levels"], dict) or set(state["levels"]) != {str(m) for m in available}
                or not isinstance(state["shop"], dict)
                or set(state["shop"]) != set(config["tongtianta_shangdian"])
                or not isinstance(state["best"], dict)
                or not integer(state["best"]["point"], 1, len(available))
                or not integer(state["best"]["level"], 0, len(levels(config, state["best"]["point"])))):
            raise ValueError
        for mid in available:
            rows = state["levels"][str(mid)]
            if not isinstance(rows, list) or len(rows) != len(levels(config, mid)):
                raise ValueError
            for index, row in enumerate(rows):
                if (not isinstance(row, dict) or not isinstance(row["stars"], list) or len(row["stars"]) != 3
                        or any(v not in (0, 1) for v in row["stars"])
                        or any(not integer(row.get(k), 0, 1 << 31) for k in ("used", "daily", "first", "auto"))
                        or any(v not in (0, 1) for v in (row["daily"], row["first"], row["auto"]))
                        or row["used"] > int(levels(config, mid)[str(index + 1)]["challenge"]) * 100):
                    raise ValueError
        for row_id, bought in state["shop"].items():
            limit = int(config["tongtianta_shangdian"][row_id]["times"])
            if not integer(bought, 0, 1 << 31) or limit and bought > limit:
                raise ValueError
    except (KeyError, TypeError, ValueError):
        raise ValueError("通天塔存档无效") from None
    return state


def vip_row(save, config):
    return config["vip"].get(str(save["role_state"].get("vip", 0)), config["vip"]["0"])


def limits(save, state, config):
    return int(config["vip"]["0"]["tongtianta_cishu"]), int(vip_row(save, config)["tongtianta_cishu"])


def remaining(save, state, config):
    free, _ = limits(save, state, config)
    return max(0, free + state["bought"] - state["used"])


def settle(save, config, now):
    state = get_state(save, config)
    if type(now) is not int or not 0 <= now < 1 << 63:
        raise ValueError("通天塔时间无效")
    day = (now + 28800) // 86400
    if now < state["checked_at"] or day < state["day"]:
        raise ValueError("通天塔时钟回拨，请稍后重试")
    if state["day"] == 0:
        # 首次进入：初始化日历而不把刚建立的本轮状态当作跨日重置。
        state["day"] = day
        state["checked_at"] = max(now, state["checked_at"])
        save["babel_tower_state"] = state
        return state
    if day > state["day"]:
        state["day"] = day
        state["used"] = 0
        state["bought"] = 0
        state["cur_point"] = 0
        for rows in state["levels"].values():
            for row in rows:
                row.update(used=0, daily=0, auto=0)
    state["checked_at"] = max(now, state["checked_at"])
    save["babel_tower_state"] = state
    return state


def require_open(save, config):
    row = config["build"]["450"]
    if (not save.get("has_role") or row["switch"] != 1
            or save["role_state"]["level"] < row["level"]):
        raise ValueError("通天塔尚未解锁")


def status(state, config):
    return ids([state["max_point"], state["cur_point"], state["used"], state["bought"],
                *state["awards"][:len(maps(config))]])


def level_values(row):
    return ids([row["used"], *row["stars"], row["daily"], row["first"], row["auto"]])


def all_three_star(state, map_id):
    return all(all(star for star in row["stars"]) for row in state["levels"][str(map_id)])


def refresh_progress(state, config, map_id):
    if state["awards"][map_id - 1] == 0 and all_three_star(state, map_id):
        state["awards"][map_id - 1] = 1
    if all_three_star(state, map_id) and map_id < len(maps(config)):
        state["max_point"] = max(state["max_point"], map_id + 1)


def sanitize_breakthrough(point, config):
    """按 v2 引擎白名单收敛 NPC 突破等级，避免个别 break9 属性行让整关不可打。"""
    dynamic = battle.DYNAMIC_BASE | battle.HADES_EFFECTS | battle.PARTNER_EFFECTS | battle.LEAD_GOLD_EFFECTS
    stats = ("atk", "def", "hp", "speed", "critical", "dodge", "parry", "resilience", "hit", "arp", "criticaldmg")

    def supported(pid):
        row = config["breakskill"].get(str(pid))
        if row is None:
            return False
        code = row["type_param"] or row["id"]
        if 9100001 <= row["id"] <= 9100007:
            code = row["id"]
        return bool(row["type"] == 0 and code not in range(9100001, 9100005)
                    and row["attr"] in (*stats, "ap", "dmg", "fdmg") and row["target"] in ("1", "2", "3", "4", "5", "7")
                    or code in dynamic)

    for index in range(1, 8):
        monster_id = point.get(f"p{index}")
        if not monster_id:
            continue
        general = config["general"][str(config["copy_monster"][str(monster_id)]["generalid"])]
        advance = int(point.get(f"break{index}-correct", 0))
        while advance > 0:
            pids = {general.get(f"break{level}", 0) for level in range(1, advance + 1)} - {0}
            if all(supported(pid) for pid in pids):
                break
            advance -= 1
        point[f"break{index}-correct"] = advance
    return point


def battle_result(report, reward):
    return (encode_pb_field(1, 0, int(report["result"])) + encode_pb_field(2, 0, report["star"])
            + encode_pb_field(4, 2, reward)
            + encode_pb_field(5, 2, json.dumps(report, ensure_ascii=False, separators=(",", ":")).encode("utf-8")))


def condition_met(kind, param, extra, report, config):
    won = bool(report["result"])
    if not won:
        return False
    round_number = report["round"]
    attack = {int(pos): unit for pos, unit in report["endmeta"]["attack"].items()}
    defense = report["endmeta"]["defense"]
    dead = {int(pos) for pos, unit in attack.items() if unit["h"] <= 0}
    front = sorted(pos for pos in attack if pos < 8)
    back = sorted(pos for pos in attack if pos >= 8)
    killed = report["dead_log"]["false"]
    if kind == 1:
        return True
    if kind == 2:
        return round_number <= param
    if kind == 3:
        return all(unit["h"] * 100 > unit["j"] * param for unit in attack.values() if unit["j"] > 0)
    if kind == 4:
        return len(dead) <= param
    if kind == 5:
        return 1 <= param <= len(front) and front[param - 1] not in dead
    if kind == 6:
        return 1 <= param <= len(back) and back[param - 1] not in dead
    if kind == 7:
        return all(pos not in dead for pos in front)
    if kind == 8:
        return all(pos not in dead for pos in back)
    if kind == 9:
        return killed.get(str(extra), 1 << 30) <= param
    if kind == 10:
        return any(str(unit["region"]) == str(extra) and killed.get(str(unit["c"]), 1 << 30) <= param
                   for unit in defense.values())
    raise ValueError(f"不支持的通天塔通关条件 {kind}")


def stars(point, report, config):
    result = []
    for index in range(1, 4):
        kind = int(point[f"through_conditions{index}"])
        param = int(point[f"attribute{index}"])
        extra = int(point[f"attribute{index}_{index}"])
        if str(kind) not in config["tongtianta_tongguantiaojian"]:
            raise ValueError("通天塔通关条件配置不存在")
        result.append(int(condition_met(kind, param, extra, report, config)))
    return result


def daily_reward(point, seed):
    rng = random.Random(seed ^ 0xBABE1)
    spec = []
    for entry in point["daily_reward"].split(";"):
        if not entry:
            continue
        cid, low, high = map(int, entry.split(","))
        if not 0 < cid < 1 << 31 or not 0 <= low <= high < 1 << 31:
            raise ValueError("通天塔每日奖励配置无效")
        count = rng.randint(low, high)
        if count:
            spec.append(f"{cid},{count}")
    return ";".join(spec) + (";" if spec else "")


def players_body(save, config, point, level):
    role = bytes.fromhex(save["role_snapshot"])
    state = save["role_state"]
    icon = pb_get_varint(role, 23) or 35001
    title = pb_get_varint(role, 24) or 35501
    params = b"".join(encode_pb_field(1, 2, encode_pb_field(1, 0, value))
                      for value in (0, 0, icon, title, point, level))
    player = (encode_pb_field(1, 0, pb_get_varint(role, 1) or 0)
              + encode_pb_field(2, 2, save["role_name"].encode("utf-8"))
              + b"".join(encode_pb_field(n, 0, state[key]) for n, key in ((3, "level"), (4, "vip"), (5, "profile")))
              + encode_pb_field(7, 0, state["power"]) + encode_pb_field(8, 2, params))
    return encode_pb_field(1, 2, player)


def sweep_level(state, map_id):
    rows = state["levels"][str(map_id)]
    for index, row in enumerate(rows, 1):
        if not row["daily"]:
            return index
    return len(rows) + 1


def buy_times(save, body, config, now):
    """7010 sysId=450：按 buycount_price 重算价格，扣仙元并增加当日次数。"""
    require_open(save, config)
    values = parse(body, 2)
    sys_id, count = values
    if sys_id != 450 or count <= 0:
        raise ValueError("通天塔购买次数参数无效")
    state = settle(save, config, now)
    _, max_buy = limits(save, state, config)
    if state["bought"] + count > max_buy:
        raise ValueError("通天塔今日可购买次数不足")
    prices = config["buycount_price"]
    ceiling = max(map(int, prices))
    price = sum(int(prices[str(min(index, ceiling))]["tongtianta_goumai_jiage"])
                for index in range(state["bought"] + 1, state["bought"] + count + 1))
    if price < 0 or price >= 1 << 31:
        raise ValueError("通天塔购买价格无效")
    state["bought"] += count
    return b"", b"", [(1025, price)]


def prepare(opcode, save, body, config, now, seed):
    """返回 (回包, 需要入账的奖励, 需要扣除的物品)；player 统一落盘。"""
    require_open(save, config)
    state = settle(save, config, now)
    available = maps(config)
    if opcode in (7011, 7014):
        if body:
            raise ValueError("通天塔查询不接受参数")
        if opcode == 7014:
            state["cur_point"] = 0
        return status(state, config), b"", []
    if opcode == 7012:
        values = parse(body, 1)
        map_id = values[0]
        if map_id not in available or map_id > state["max_point"]:
            raise ValueError("通天塔章节尚未解锁")
        if state["cur_point"] not in (0, map_id):
            raise ValueError("请先退出当前通天塔章节")
        if not remaining(save, state, config):
            raise ValueError("通天塔今日挑战次数已用完")
        state["cur_point"] = map_id
        return b"".join(level_values(row) for row in state["levels"][str(map_id)]), b"", []
    if opcode == 7017:
        if body:
            raise ValueError("通天塔商店查询不接受参数")
        shop = config["tongtianta_shangdian"]
        return ids([state["max_point"], *[state["shop"][key] for key in sorted(shop, key=int)]]), b"", []
    if opcode == 7019:
        values = parse(body, 1)
        if values[0] not in (0, 1):
            raise ValueError("通天塔排行榜类型无效")
        best = state["best"]
        return comb([(0, ids([best["point"], best["level"]])),
                     (1, players_body(save, config, best["point"], best["level"]))]), b"", []
    if opcode == 7013:
        values = parse(body, 1)
        map_id, level_id = state["cur_point"], values[0]
        if not map_id or str(level_id) not in levels(config, map_id):
            raise ValueError("通天塔关卡不存在")
        table = levels(config, map_id)
        point = table[str(level_id)]
        if level_id > 1:
            previous = state["levels"][str(map_id)][level_id - 2]
            if not previous["stars"][0] or not previous["daily"]:
                raise ValueError("请先通关上一层通天塔")
        row = state["levels"][str(map_id)][level_id - 1]
        if row["used"] >= int(point["challenge"]):
            raise ValueError("该通天塔关卡今日挑战次数已用完")
        if not remaining(save, state, config):
            raise ValueError("通天塔今日挑战次数已用完")
        attack, defense = battle.rosters(save, sanitize_breakthrough(dict(point), config), config)
        report = battle.simulate(attack, defense, config, seed,
                                 attack_pet=pets.combat(save, config), attack_cheer=cheer.combat(save, config))
        report["meta"]["attack"]["n"] = save["role_name"]
        report["meta"]["defense"]["n"] = point["name"]
        gained = stars(point, report, config)
        row["used"] += 1
        state["used"] += 1
        row["stars"] = [max(old, new) for old, new in zip(row["stars"], gained)]
        spec = ""
        if report["result"]:
            if not row["first"]:
                spec += point["reward"]
                row["first"] = 1
            if not row["daily"]:
                spec += daily_reward(point, seed)
                row["daily"] = 1
            old = state["best"]
            if (map_id, level_id) > (old["point"], old["level"]):
                state["best"] = {"point": map_id, "level": level_id}
            refresh_progress(state, config, map_id)
        save["last_babel_tower_battle"] = {"map": map_id, "level": level_id, "won": report["result"],
                                           "round": report["round"], "stars": gained}
        reward = activities.build_reward(save, spec, config) if spec else b""
        return comb([(0, level_values(row)), (1, battle_result(report, reward))]), reward, []
    if opcode == 7015:
        values = parse(body, 1)
        map_id = values[0]
        if map_id not in available:
            raise ValueError("通天塔章节不存在")
        if state["awards"][map_id - 1] != 1 or not all_three_star(state, map_id):
            raise ValueError("通天塔章节奖励未达成或已领取")
        reward = activities.build_reward(save, config["tongtianta_dazhangjie"][str(map_id)]["reward"], config)
        state["awards"][map_id - 1] = 2
        return reward, reward, []
    if opcode == 7016:
        if body:
            raise ValueError("通天塔扫荡不接受参数")
        map_id = state["cur_point"]
        if not map_id:
            raise ValueError("请先进入通天塔章节")
        rows = state["levels"][str(map_id)]
        start = sweep_level(state, map_id)
        if start > len(rows) or rows[0]["auto"] or not all(rows[start - 1]["stars"]):
            raise ValueError("当前不满足通天塔扫荡条件")
        table = levels(config, map_id)
        rewards = []
        for index in range(start, len(rows) + 1):
            row = rows[index - 1]
            if row["daily"] or not all(row["stars"]):
                break
            reward = activities.build_reward(save, daily_reward(table[str(index)], seed ^ index), config)
            rewards.append((index - start + 1, reward))
            row["daily"] = 1
        if not rewards:
            raise ValueError("当前没有可扫荡的通天塔关卡")
        rows[0]["auto"] = 1
        return comb(rewards), b"".join(data for _, data in rewards), []
    if opcode == 7018:
        values = parse(body, 2)
        row_id, count = str(values[0]), values[1]
        shop = config["tongtianta_shangdian"]
        if row_id not in shop or count <= 0:
            raise ValueError("通天塔商店商品或数量无效")
        item = shop[row_id]
        if int(item["page"]) > state["max_point"]:
            raise ValueError("该通天塔商店页签尚未解锁")
        limit = int(item["times"])
        if limit and state["shop"][row_id] + count > limit:
            raise ValueError("通天塔商店兑换次数不足")
        cid, unit = map(int, item["num"].rstrip(";").split(",")[:2])
        if cid not in SHOP_CURRENCIES or unit <= 0:
            raise ValueError("通天塔商店消耗配置无效")
        cost = unit * count
        if cost >= 1 << 31:
            raise ValueError("通天塔商店消耗超出范围")
        state["shop"][row_id] += count
        reward = activities.build_reward(save, item["reward"], config, quantity=count)
        return reward, reward, [(cid, cost)]
    raise ValueError("通天塔协议未实现")
