"""灭神殿引导及首个五层：配置难度、临时Boss加成与原子结算所需状态。"""

from fractions import Fraction
import json

from . import activities, battle, recharge
from .protocol import encode_pb_field, iter_pb_fields


QUERIES = (3620,)
BATTLES = (3621, 3622)
UNSUPPORTED = (3623, 3624, 3625, 3626, 3627, 3628)
MAX_FLOOR = 5  # shortcut: 仅开放引导所在的首个五层，后续需接入特殊通关条件和Boss加成。


def get_state(save, config):
    state = save.setdefault("mieshendian_state", {
        "floor": 1, "failcount": 0, "star": 0, "earned": 0, "day": 0, "todaymaxfloor": 0,
    })
    if not isinstance(state, dict) or any(type(state.get(key)) is not int or not 0 <= state[key] < (1 << 31)
                                         for key in ("floor", "failcount", "star", "earned", "day", "todaymaxfloor")):
        raise ValueError("灭神殿存档无效")
    maximum = max(map(int, config["mieshendian_monster_param"]))
    if (not 1 <= state["floor"] <= maximum + 1 or state["star"] > state["earned"]
            or state["todaymaxfloor"] >= state["floor"] or state["failcount"] > 3):
        raise ValueError("灭神殿进度或星数无效")
    return state


def settle(save, config, now):
    state = get_state(save, config)
    day = (now + 8 * 3600) // 86400
    if day > state["day"]:
        state.update(day=day, todaymaxfloor=0)
    return state


def query(save, body, config, now):
    if body:
        raise ValueError("灭神殿查询不接受参数")
    state = settle(save, config, now)
    return recharge.ids([state["floor"] - 1, state["todaymaxfloor"], 0, state["failcount"], state["floor"],
                         state["star"], 0, 0, 0, state["earned"], 0])


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
    if floor > MAX_FLOOR:
        raise ValueError("灭神殿目前仅开放前5层，后续通关条件尚未接入")
    if (floor % 5 == 0) != (opcode == 3622):
        raise ValueError("灭神殿挑战方式与当前层数不符，请重新进入")
    difficulty = values[0] if opcode == 3621 else 1
    row = config["mieshendian_monster_param"][str(floor)].get(str(difficulty))
    if not row:
        raise ValueError("请选择配置中的灭神殿难度")
    if state["failcount"] >= row["number"]:
        raise ValueError("本层失败次数已用完，未开始新挑战")
    condition = config["mieshendian_condition"][str(floor)]
    if condition["condition"] != 1 or condition["condition_param"]:
        raise ValueError("此灭神殿通关条件尚未支持")
    if any(row[f"p{i}"] and row[f"ap{i}"] != 2 for i in range(1, 8)):
        raise ValueError("此灭神殿初始怒气尚未支持")
    attack, defense = battle.rosters(save, {**row, "level": row["monster_level"]}, config)
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
        for i, enabled in enumerate(selected, 1):
            if not enabled:
                continue
            attr = bonus[f"attr{i}"]
            if (attr not in ("dodge", "criticaldmg", "hit") or bonus[f"range{i}"] != "all"
                    or bonus[f"region{i}"] != "11" or bonus[f"buffid{i}"]
                    or bonus[f"target{i}"] not in ("0", "1") or bonus[f"kind{i}"] not in ("0", "1")):
                raise ValueError("此Boss临时加成尚未支持")
            amount = int(Fraction(str(bonus[f"int{i}"])) * 100) * (-1 if bonus[f"kind{i}"] == "1" else 1)
            for unit in (attack if bonus[f"target{i}"] == "0" else defense).values():
                unit[attr] = unit.get(attr, 0) + amount
    report = battle.simulate(attack, defense, config, seed)
    report["meta"]["attack"]["n"] = save["role_name"]
    report["meta"]["defense"]["n"] = f"灭神殿第{floor}层"
    state["star"] -= cost
    specifications = []
    if report["result"]:
        specifications.append(row["star1reward"])
        if str(floor) in config["mieshendian_reward"]:
            specifications.append(config["mieshendian_reward"][str(floor)]["rewards"])
        specifications.extend(item["reward"] for item in config["mieshendian_award"].values() if item["number"] == floor)
        state.update(floor=floor + 1, failcount=0, star=state["star"] + row["star"],
                     earned=state["earned"] + row["star"], todaymaxfloor=max(state["todaymaxfloor"], floor))
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
