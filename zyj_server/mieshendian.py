"""灭神殿：配置爬塔、临时加成、重置、定时扫荡及积分商店。"""

from fractions import Fraction
import json

from . import activities, battle, recharge
from .protocol import encode_pb_field, iter_pb_fields


QUERIES = (3620, 3627)
BATTLES = (3621, 3622)
MUTATIONS = (*BATTLES, 3623, 3624, 3626, 3628)
OPCODES = QUERIES + MUTATIONS


def get_state(save, config):
    state = save.setdefault("mieshendian_state", {
        "floor": 1, "failcount": 0, "star": 0, "earned": 0, "day": 0, "todaymaxfloor": 0,
    })
    if not isinstance(state, dict) or any(type(state.get(key)) is not int or not 0 <= state[key] < (1 << 31)
                                         for key in ("floor", "failcount", "star", "earned", "day", "todaymaxfloor")):
        raise ValueError("灭神殿存档无效")
    maximum = max(map(int, config["mieshendian_monster_param"]))
    if not 1 <= state["floor"] <= maximum + 1:
        raise ValueError("灭神殿层数存档无效")
    extra = ("maxfloor", "maxstar", "points", "resets", "best", "bought", "daily_bought", "sweep")
    if not any(key in state for key in extra):
        # 旧版从未重置过，已过层数和累计得星是唯一可追溯的迁移依据。
        state.update(maxfloor=state["floor"] - 1, maxstar=state["earned"], points=state["earned"] * 100,
                     resets=0, best={str(i): 1 for i in range(1, state["floor"])}, bought={}, daily_bought={}, sweep=None)
    if any(type(state.get(key)) is not int or not 0 <= state[key] < (1 << 31)
           for key in ("maxfloor", "maxstar", "points", "resets")):
        raise ValueError("灭神殿历史或积分存档无效")
    if (state["star"] > state["earned"]
            or not state["floor"] - 1 <= state["maxfloor"] <= maximum
            or state["todaymaxfloor"] > state["maxfloor"] or state["earned"] > state["maxstar"] or state["failcount"] > 3):
        raise ValueError("灭神殿进度或星数无效")
    best = state.get("best")
    if (not isinstance(best, dict) or set(best) != {str(i) for i in range(1, state["maxfloor"] + 1)}
            or any(type(value) is not int or str(value) not in config["mieshendian_monster_param"][key] for key, value in best.items())):
        raise ValueError("灭神殿通关难度存档无效")
    for key, page, limit in (("bought", 2, "total"), ("daily_bought", 1, "limit")):
        values = state.get(key)
        if (not isinstance(values, dict) or any(iid not in config["mieshendian_shop"]
                or config["mieshendian_shop"][iid]["paging"] != page or type(value) is not int
                or not 0 <= value <= config["mieshendian_shop"][iid][limit] for iid, value in values.items())):
            raise ValueError("灭神殿商店限购存档无效")
    pending = state.get("sweep")
    if pending is not None and (not isinstance(pending, dict) or set(pending) != {"target", "end_at"}
            or any(type(v) is not int or not 0 < v < (1 << 63) for v in pending.values())
            or pending["target"] % 5 or not state["floor"] <= pending["target"] <= state["maxfloor"] // 5 * 5):
        raise ValueError("灭神殿扫荡存档无效")
    if "sweep" not in state:
        raise ValueError("灭神殿扫荡存档缺失")
    return state


def settle(save, config, now):
    state = get_state(save, config)
    now = max(now, save.get("stamina_clock", {}).get("checked_at", now))
    day = (now + 8 * 3600) // 86400
    if day > state["day"]:
        state.update(day=day, todaymaxfloor=0, resets=0, daily_bought={})
    return state


def query(save, body, config, now):
    if body:
        raise ValueError("灭神殿查询不接受参数")
    state = settle(save, config, now)
    now = max(now, save.get("stamina_clock", {}).get("checked_at", now))
    remaining = max(0, state["sweep"]["end_at"] - now) if state["sweep"] else 0
    return recharge.ids([state["maxfloor"], state["todaymaxfloor"], state["resets"], state["failcount"], state["floor"],
                         state["star"], remaining, 0, state["points"], state["maxstar"], state["maxfloor"] // 5 * 5])


def condition_met(report, row):
    if not report["result"]:
        return False
    kind, value = row["condition"], Fraction(str(row["condition_param"]))
    units = {int(pos): unit for pos, unit in report["endmeta"]["attack"].items()}
    if kind == 1:
        return True
    if kind == 2:
        return report["round"] <= value
    if kind == 3:
        # 本地规则检查结算血量；战中受伤后被治疗的单位按最终血量判定。
        return all(unit["h"] >= unit["j"] * value for unit in units.values())
    if kind == 4:
        return sum(unit["h"] == 0 for unit in units.values()) <= value
    if kind in (5, 6):
        positions = (2, 4, 6) if kind == 5 else (8, 10, 12, 14)
        return value.denominator == 1 and 1 <= value <= len(positions) and units.get(positions[int(value) - 1], {}).get("h", 0) > 0
    if kind in (7, 8):
        return all(unit["h"] > 0 for pos, unit in units.items() if (pos < 8) == (kind == 7))
    raise ValueError("灭神殿通关条件无效")


def apply_bonuses(attack, defense, row, selected, config):
    base = {id(unit): dict(unit) for team in (attack, defense) for unit in team.values()}
    for i, enabled in enumerate(selected, 1):
        if not enabled:
            continue
        attr, scope = row[f"attr{i}"], row[f"range{i}"]
        if (attr not in ("atk", "def", "hp", "speed", "ap", "critical", "dodge", "parry", "resilience", "hit", "criticaldmg")
                or scope not in ("all", "first", "second") or row[f"buffid{i}"]
                or row[f"target{i}"] not in ("0", "1") or row[f"kind{i}"] not in ("0", "1")):
            raise ValueError("Boss临时加成配置无效")
        amount = Fraction(str(row[f"int{i}"])) * (-1 if row[f"kind{i}"] == "1" else 1)
        for pos, unit in (attack if row[f"target{i}"] == "0" else defense).items():
            if scope == "first" and pos > 7 or scope == "second" and pos < 8:
                continue
            region = config["general"][str(unit["cid"])]["region"]
            if row[f"region{i}"] != "11" and region != row[f"region{i}"]:
                continue
            if attr == "ap":
                unit["initial_ap"] = max(0, min(10, unit.get("initial_ap", 2) + int(amount)))
            elif attr in ("atk", "def", "hp", "speed"):
                unit[attr] += base[id(unit)][attr] * amount
            else:
                unit[attr] = unit.get(attr, 0) + int(amount * 100)


def victory(state, floor, difficulty, config):
    row = config["mieshendian_monster_param"][str(floor)][str(difficulty)]
    specifications = [row["star1reward"], f"1004,{row['star'] * 100};"]
    if str(floor) in config["mieshendian_reward"]:
        specifications.append(config["mieshendian_reward"][str(floor)]["rewards"])
    if floor > state["maxfloor"]:
        specifications.extend(item["reward"] for item in config["mieshendian_award"].values() if item["number"] == floor)
    state.update(floor=floor + 1, failcount=0, star=state["star"] + row["star"], earned=state["earned"] + row["star"],
                 todaymaxfloor=max(state["todaymaxfloor"], floor), maxfloor=max(state["maxfloor"], floor))
    state["maxstar"] = max(state["maxstar"], state["earned"])
    state["best"][str(floor)] = max(state["best"].get(str(floor), 1), difficulty)
    return specifications


def fight(save, opcode, body, config, now, seed):
    fields = list(iter_pb_fields(body))
    size = 1 if opcode == 3621 else 10
    if len(fields) != size or any(n != 1 or w != 0 or not 0 <= value < (1 << 31) for n, w, value in fields):
        raise ValueError("灭神殿挑战参数无效")
    values = [value for _, _, value in fields]
    if not save.get("has_role") or save["role_state"]["level"] < config["build"]["20"]["level"]:
        raise ValueError("灭神殿尚未解锁")
    state = settle(save, config, now)
    floor = state["floor"]
    if state["sweep"]:
        raise ValueError("灭神殿正在扫荡，请等待完成")
    if str(floor) not in config["mieshendian_monster_param"]:
        raise ValueError("灭神殿已通关配置中的全部层数")
    if (floor % 5 == 0) != (opcode == 3622):
        raise ValueError("灭神殿挑战方式与当前层数不符，请重新进入")
    difficulty = values[0] if opcode == 3621 else 1
    row = config["mieshendian_monster_param"][str(floor)].get(str(difficulty))
    if not row:
        raise ValueError("请选择配置中的灭神殿难度")
    if state["failcount"] >= row["number"]:
        raise ValueError("本层失败次数已用完，未开始新挑战")
    attack, defense = battle.rosters(save, {**row, "level": row["monster_level"]}, config)
    for i, pos in enumerate(battle.POSITIONS, 1):
        if pos in defense:
            defense[pos]["initial_ap"] = row[f"ap{i}"]
    cost = 0
    if opcode == 3622:
        selected, arrangement = values[:3], values[3:]
        sources = [value for value in arrangement if value]
        occupied = {battle.POSITIONS.index(pos) + 1: unit for pos, unit in attack.items()}
        if (any(value not in (0, 1) for value in selected) or any(value > 7 for value in sources)
                or len(sources) != len(set(sources)) or not set(occupied).issubset(sources)):
            raise ValueError("Boss临时布阵或加成选择无效")
        unlocked = config["role_exp"][str(save["role_state"]["level"])]["slotnum"]
        if any(index > unlocked and source in occupied for index, source in enumerate(arrangement, 1)):
            raise ValueError("Boss临时阵位尚未解锁")
        attack = {battle.POSITIONS[index - 1]: occupied[source] for index, source in enumerate(arrangement, 1)
                  if source in occupied}
        bonus = config["mieshendian_attr"][str(floor)]
        cost = sum(bonus[f"star{i}"] for i, enabled in enumerate(selected, 1) if enabled)
        if cost > state["star"]:
            raise ValueError("Boss临时加成所需星数不足")
        apply_bonuses(attack, defense, bonus, selected, config)
    report = battle.simulate(attack, defense, config, seed)
    condition = config["mieshendian_condition"][str(floor)]
    report["result"] = condition_met(report, condition)
    if not report["result"]:
        report["star"] = 0
    report["meta"]["attack"]["n"] = save["role_name"]
    report["meta"]["defense"]["n"] = f"灭神殿第{floor}层"
    state["star"] -= cost
    specifications = []
    if report["result"]:
        specifications = victory(state, floor, difficulty, config)
    else:
        state["failcount"] += 1
    get_state(save, config)
    reward = activities.build_reward(save, ";".join(specifications), config)
    save["last_mieshendian_battle"] = {"rules": report["rules"], "seed": seed, "floor": floor, "request": values,
                                      "won": report["result"], "star_cost": cost, "rounds": report["round"]}
    response = (encode_pb_field(1, 0, int(report["result"])) + encode_pb_field(2, 0, report["star"])
                + encode_pb_field(4, 2, reward)
                + encode_pb_field(5, 2, json.dumps(report, ensure_ascii=False, separators=(",", ":")).encode("utf-8")))
    return response, reward


def finish_sweep(save, config, now, force=False):
    state = settle(save, config, now)
    now = max(now, save.get("stamina_clock", {}).get("checked_at", now))
    pending = state["sweep"]
    if pending is None or not force and now < pending["end_at"]:
        return b""
    specifications = []
    for floor in range(state["floor"], pending["target"] + 1):
        specifications.extend(victory(state, floor, state["best"][str(floor)], config))
    state["sweep"] = None
    get_state(save, config)
    return activities.build_reward(save, ";".join(specifications), config)


def prepare(opcode, save, body, config, now, seed):
    now = max(now, save.get("stamina_clock", {}).get("checked_at", now))
    if opcode in BATTLES:
        reply, reward = fight(save, opcode, body, config, now, seed)
        return reply, [], reward
    fields = list(iter_pb_fields(body))
    if opcode == 3628:
        if len(fields) != 1 or fields[0][:2] != (1, 0) or not 0 < fields[0][2] < (1 << 31):
            raise ValueError("灭神殿购买需要一个商品ID")
    elif body:
        raise ValueError("灭神殿此操作不接受参数")
    state = settle(save, config, now)
    if opcode == 3620:
        return query(save, body, config, now), [], b""
    if opcode == 3627:
        counts = [value for key, row in sorted(config["mieshendian_shop"].items(), key=lambda item: int(item[0]))
                  for value in (row["id"], state["daily_bought"].get(key, 0) if row["paging"] == 1
                                else 2 if state["bought"].get(key, 0) else 0)]
        return recharge.ids([state["points"], state["maxstar"], *counts]), [], b""
    if not save.get("has_role") or save["role_state"]["level"] < config["build"]["20"]["level"]:
        raise ValueError("灭神殿尚未解锁")
    if opcode == 3628:
        key = str(fields[0][2])
        row = config["mieshendian_shop"].get(key)
        if not row or state["maxstar"] < row["rank"]:
            raise ValueError("灭神殿商品不存在或历史星数不足")
        counts, limit = (state["daily_bought"], row["limit"]) if row["paging"] == 1 else (state["bought"], row["total"])
        if counts.get(key, 0) >= limit:
            raise ValueError("此灭神殿商品兑换次数已用完")
        costs = [tuple(map(int, entry.split(","))) for entry in row["consume"].split(";") if entry]
        if len(costs) != 1 or costs[0][0] not in (1001, 1004) or costs[0][1] <= 0:
            raise ValueError("灭神殿商品价格配置无效")
        reward = activities.build_reward(save, row["good"], config)
        counts[key] = counts.get(key, 0) + 1
        return reward, costs, reward
    if opcode == 3624:
        if state["sweep"] is None:
            raise ValueError("当前没有灭神殿扫荡")
        left = max(0, state["sweep"]["end_at"] - now)
        cost = (left + 59) // 60 * int(config["global_kv"]["mieshendian_saodang_gold"]["value"])
        reward = finish_sweep(save, config, now, force=True)
        return reward, [(1001, cost)], reward
    if state["sweep"] is not None:
        raise ValueError("灭神殿正在扫荡，请等待完成")
    if opcode == 3626:
        if state["floor"] == 1:
            raise ValueError("已经是灭神殿最底层，不能重置")
        if state["resets"] >= config["vip"][str(save["role_state"]["vip"])]["bzxtrst"]:
            raise ValueError("今日灭神殿重置次数已用完")
        cost = config["buycount_price"][str(state["resets"] + 1)]["mieshendian"]
        state.update(floor=1, star=0, earned=0, failcount=0, resets=state["resets"] + 1)
        return query(save, b"", config, now), [(1001, cost)], b""
    vip = config["vip"][str(save["role_state"]["vip"])]
    if not vip["mieshendian_sweep"] and save["role_state"]["level"] < int(config["global_kv"]["mieshendian_saodang_openlv"]["value"]):
        raise ValueError("灭神殿扫荡等级或VIP不足")
    target = state["maxfloor"] // 5 * 5
    if state["floor"] > target:
        raise ValueError("已到达本次可扫荡的最高层")
    duration = (target - state["floor"] + 1) * int(config["global_kv"]["mieshendian_saodang_time"]["value"])
    state["sweep"] = {"target": target, "end_at": now + duration}
    return query(save, b"", config, now), [], b""
