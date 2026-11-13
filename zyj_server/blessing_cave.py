"""福祉天宫：原配置10层×4难度、成功次数、真实战斗与已通关扫荡。"""

import json
import random

from . import activities, battle, cheer, pets
from .protocol import encode_pb_field, iter_pb_fields
from .recharge import ids

QUERIES = (6520,)
MUTATIONS = (6521, 6522)
OPCODES = (*QUERIES, *MUTATIONS)
BUY_SYS_ID = 463


def get_state(save, config):
    state = save.get("blessing_cave_state", {"day": 0, "used": 0, "bought": 0,
                                            "cleared": [0] * 10, "checked_at": 0})
    free = config["vip"]["0"]["xianku_cishu"]
    # VIP0可买2次、VIP1只有1次；升级不能把当天已付费次数判成坏档。
    limit = max(row["xianku_cishu"] for row in config["vip"].values())
    if (not isinstance(state, dict)
            or any(type(state.get(k)) is not int or not 0 <= state[k] < (1 << 63)
                   for k in ("day", "used", "bought", "checked_at"))
            or state["day"] >= (1 << 31) or state["bought"] > limit
            or state["used"] > free + state["bought"]
            or not isinstance(state.get("cleared"), list) or len(state["cleared"]) != 10
            or any(type(v) is not int or not 0 <= v <= 4 for v in state["cleared"])
            or any(v and index and not state["cleared"][index-1] for index, v in enumerate(state["cleared"]))):
        raise ValueError("福祉天宫存档无效")
    return state


def require_open(save, config):
    row = config["build"][str(BUY_SYS_ID)]
    if not save.get("has_role") or row["switch"] != 1 or save["role_state"]["level"] < row["level"]:
        raise ValueError("福祉天宫105级解锁")


def parse(body, count):
    fields = list(iter_pb_fields(body))
    if len(fields) != count or any(n != 1 or w != 0 or not 0 <= v < (1 << 31) for n, w, v in fields):
        raise ValueError("福祉天宫请求参数无效，请刷新后重试")
    return [v for _, _, v in fields]


def settle(save, config, now):
    state = get_state(save, config)
    if type(now) is not int or not 0 <= now < (1 << 63):
        raise ValueError("福祉天宫时间无效")
    day = (now + 28800) // 86400
    if now < state["checked_at"] or day < state["day"]:
        raise ValueError("福祉天宫时钟回拨，请稍后重试")
    if day > state["day"]:
        state.update(day=day, used=0, bought=0)
    state["checked_at"] = now
    save["blessing_cave_state"] = state
    return state


def remaining(state, config):
    return config["vip"]["0"]["xianku_cishu"] + state["bought"] - state["used"]


def open_floor(save, state, floor, config):
    return (str(floor) in config["xianku_guaiwu"]
            and save["role_state"]["level"] >= config["xianku_guaiwu"][str(floor)]["1"]["open_level"]
            and (floor == 1 or state["cleared"][floor-2] > 0))


def query(save, state, config):
    values = [remaining(state, config)]
    for floor in range(1, 11):
        if not open_floor(save, state, floor, config):
            break
        cleared = state["cleared"][floor-1]
        values.extend([floor, *(2 if level <= cleared else int(level == cleared+1) for level in range(1, 5))])
    # 尾部购买数不占原生每层五值；旧页面 floor(len/5) 仍保持兼容。
    return ids([*values, state["bought"]])


def prizes(save, point, config, seed):
    rng = random.Random(seed ^ 0xF021)
    specification = []
    for index in range(1, 5):
        chance = point[f"probability{index}"]
        if type(chance) is not int or not 0 <= chance <= 100:
            raise ValueError("福祉天宫掉率配置无效")
        for entry in point[f"reward{index}"].strip(";").split(";"):
            if not entry:
                continue
            parts = entry.split(",")
            if len(parts) != 3:
                raise ValueError("福祉天宫掉落配置无效")
            cid, low, high = map(int, parts)
            if not 0 < cid < (1 << 31) or not 0 < low <= high < (1 << 31):
                raise ValueError("福祉天宫掉落区间无效")
            if rng.randrange(100) < chance:
                specification.append(f"{cid},{rng.randint(low, high)}")
    return activities.build_reward(save, ";".join(specification), config)


def prepare(opcode, save, body, config, now, seed):
    require_open(save, config)
    values = parse(body, 0 if opcode == 6520 else 2)
    state = settle(save, config, now)
    if opcode == 6520:
        return query(save, state, config), b"", []
    floor, difficulty = values
    if (not 1 <= floor <= 10 or not 1 <= difficulty <= 4
            or not open_floor(save, state, floor, config)
            or difficulty > state["cleared"][floor-1] + 1):
        raise ValueError("福祉天宫关卡尚未解锁，请先通关前一层或本层前一难度")
    if remaining(state, config) <= 0:
        raise ValueError("福祉天宫今日挑战次数不足")
    point = config["xianku_guaiwu"][str(floor)][str(difficulty)]
    if opcode == 6522:
        if difficulty > state["cleared"][floor-1]:
            raise ValueError("福祉天宫须先真实通关后才能扫荡")
        reward = prizes(save, point, config, seed)
        state["used"] += 1
        return reward, reward, []
    attack, defense = battle.rosters(save, dict(point, level=point["monster_level"]), config, now=now)
    report = battle.simulate(attack, defense, config, seed,
                             attack_pet=pets.combat(save, config), attack_cheer=cheer.combat(save, config))
    report["meta"]["attack"]["n"] = save["role_name"]
    report["meta"]["defense"]["n"] = point["name1"] + " " + point["name2"]
    reward = prizes(save, point, config, seed) if report["result"] else b""
    if report["result"]:
        state["used"] += 1
        state["cleared"][floor-1] = max(state["cleared"][floor-1], difficulty)
    save["last_blessing_battle"] = {"rules": report["rules"], "seed": seed, "floor": floor,
                                   "difficulty": difficulty, "won": report["result"], "rounds": report["round"]}
    reply = (encode_pb_field(1, 0, int(report["result"])) + encode_pb_field(2, 0, report["star"])
             + encode_pb_field(4, 2, reward)
             + encode_pb_field(5, 2, json.dumps(report, ensure_ascii=False, separators=(",", ":")).encode()))
    return reply, reward, []


def buy_times_supported(body):
    return next((v for n, w, v in iter_pb_fields(body) if (n, w) == (1, 0)), None) == BUY_SYS_ID


def buy_times(save, body, config, now):
    require_open(save, config)
    sys_id, count, quote = parse(body, 3)
    state = settle(save, config, now)
    limit = config["vip"][str(save["role_state"].get("vip", 0))]["xianku_cishu"]
    if sys_id != BUY_SYS_ID or not count or state["bought"] + count > limit:
        raise ValueError("福祉天宫今日可购买次数不足")
    price = sum(config["buycount_price"][str(index)]["fuzhi_goumai_jiage"]
                for index in range(state["bought"]+1, state["bought"]+count+1))
    if type(price) is not int or not 0 <= price < (1 << 31) or quote != price:
        raise ValueError("福祉天宫购买报价已变化，请刷新后重试")
    state["bought"] += count
    return b"", b"", [(1025, price)]


def rewrite_vip(body, save, config, now):
    state = get_state(save, config)
    bought = 0 if (now + 28800) // 86400 > state["day"] else state["bought"]
    out, index = bytearray(), 0
    for n, w, value in iter_pb_fields(body):
        if (n, w) == (1, 0):
            index += 1
            if index == 33:
                value = bought
        out.extend(encode_pb_field(n, w, value))
    return bytes(out)
