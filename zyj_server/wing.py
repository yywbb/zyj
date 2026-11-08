"""主角翅膀的配置成长、概率进阶与永久染色；仅修改事务工作副本。"""

from fractions import Fraction
import random

from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint

QUERIES = (3740, 3744)
MUTATIONS = (3741, 3742, 3743)
OPCODES = QUERIES + MUTATIONS

# 现版配置单次升星最多约 3794 次经验抽取（13 阶 9→10 星，最小权重 10 点）。
# 该阈值仅拦截异常配置造成的超大应答，不是每次使用羽毛的数量上限。
MAX_STAR_ROLLS = 10000


def get_state(save, config):
    state = save.get("wing_state", {"stage": 0, "stars": 0, "exp": 0, "color": 0, "failures": 0, "colors": [], "checked_at": 0})
    if (not isinstance(state, dict) or any(type(state.get(k)) is not int or not 0 <= state[k] < (1 << 31)
            for k in ("stage", "stars", "exp", "color", "failures"))
            or type(state.get("checked_at")) is not int or not 0 <= state["checked_at"] < (1 << 63)
            or state["stage"] > len(config["wing_stage"]) or state["stars"] > 10 or state["failures"] > 100
            or not isinstance(state.get("colors"), list) or len(set(state["colors"])) != len(state["colors"])
            or any(type(c) is not int or str(c) not in config["wing_coler"] for c in state["colors"])
            or state["color"] and state["color"] not in state["colors"]):
        raise ValueError("翅膀成长或染色存档无效")
    if not state["stage"]:
        if any(state[k] for k in ("stars", "exp", "color", "failures")) or state["colors"]:
            raise ValueError("未激活的翅膀不能拥有成长或颜色")
    else:
        row = config["wing_stage"][str(state["stage"])]
        following = config["wing_uplv"][str(state["stage"])].get(str(state["stars"] + 1))
        if ((state["exp"] >= following["lv_exp"] if following else state["exp"] != 0)
                or any(not row.get(f"c{c}") for c in state["colors"])):
            raise ValueError("翅膀经验或当前阶级颜色无效")
    return state


def chance(state, config):
    row = config["wing_stage"].get(str(state["stage"] + 1))
    if row and (not 0 <= row["basic"] <= 100 or not 0 <= row["add"] <= 100):
        raise ValueError("翅膀成功率配置无效")
    return min(100, row["basic"] + row["add"] * state["failures"]) if row else 0


def attributes(raw, state, config):
    from . import battle

    result = {f: 0 for f in range(6, 17)}
    general = config["general"][str(pb_get_varint(raw, 1))]
    if not state or not state["stage"] or general["actor"] != "lead":
        return result
    row = (config["wing_uplv"][str(state["stage"])][str(state["stars"])] if state["stars"]
           else config["wing_stage"][str(state["stage"])])
    for i in range(1, 5):
        name, amount = row[f"effect{i}"].split(";")
        if name not in ("atk", "def", "hp", "speed") or not 0 <= int(amount) < (1 << 31):
            raise ValueError("翅膀属性配置无效")
        result[battle.GENERAL_FIELDS[name]] += int(amount)
    if general["basic"] <= 0:
        raise ValueError("主角基础资质配置无效")
    # 本地资质口径：只提高基础核心的effect5/basic部分，不放大其他养成。
    for name in ("atk", "def", "hp"):
        base = battle.general_base(general, name, pb_get_varint(raw, 3), pb_get_varint(raw, 4) or 0, config)
        result[battle.GENERAL_FIELDS[name]] += int(base * Fraction(row["effect5"], general["basic"]))
    return result


def score(save, config):
    state = get_state(save, config)
    return state["stage"] * 100 + state["stars"]


def prepare(opcode, save, body, config, now, seed):
    from . import development, equip_evolve, formation, recharge

    fields = list(iter_pb_fields(body))
    if (len(fields) != (1 if opcode in (3742, 3743) else 0)
            or any((n, w) != (1, 0) or not 0 <= v < (1 << 31) for n, w, v in fields)
            or not save.get("has_role") or save["role_state"]["level"] < config["build"]["213"]["level"]
            or save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2):
        raise ValueError("翅膀尚未解锁或参数无效")
    state = get_state(save, config)
    if opcode in MUTATIONS and now < state["checked_at"]:
        raise ValueError("日期回拨，请稍后操作翅膀")
    snapshot = bytes.fromhex(save["protagonist_snapshot"])
    raw = formation.records(bytes.fromhex(save["world_state"]["1002"]), 1, 2)[pb_get_varint(snapshot, 1)]
    previous = attributes(raw, state, config)
    costs, rolls, successful = [], [], 0
    rng = random.Random(seed)
    if opcode == 3741:
        row = config["wing_uplv"].get(str(state["stage"]), {}).get(str(state["stars"] + 1))
        if not row:
            raise ValueError("请先激活翅膀或满星后进阶")
        props = formation.records(bytes.fromhex(save["world_state"]["1200"]), 1, 1)
        available = pb_get_varint(props.get(row["cost"], b""), 2) or 0
        if not available:
            raise ValueError("翅膀羽毛不足")
        deck = [tuple(map(int, entry.split(","))) for entry in row["weights"].split(";") if entry]
        if not deck or any(value <= 0 or weight <= 0 for value, weight in deck):
            raise ValueError("翅膀经验权重配置无效")
        # 一次请求用尽当前羽毛：升 1 星即停，或羽毛用光为止，不再限制每次最多使用数量。
        # 每次至少获得最小档经验，故达到 lv_exp 所需的抽取次数是天然上界，应答长度有界。
        minimum = min(value for value, _ in deck)
        needed = (row["lv_exp"] - state["exp"] + minimum - 1) // minimum
        if not 0 < needed <= MAX_STAR_ROLLS:
            raise ValueError("翅膀升星经验配置无效")
        for _ in range(min(available, needed)):
            gain = rng.choices([p[0] for p in deck], [p[1] for p in deck])[0]
            rolls.append(gain)
            state["exp"] += gain
            if state["exp"] >= row["lv_exp"]:
                state["exp"] = state["exp"] - row["lv_exp"] if state["stars"] < 9 else 0
                state["stars"] += 1
                break
        costs = [(row["cost"], len(rolls))]
    elif opcode == 3742:
        method = fields[0][2]
        row = config["wing_stage"].get(str(state["stage"] + 1))
        if method not in (0, 1) or not row:
            raise ValueError("翅膀进阶等级、方式或上限无效")
        if save["role_state"]["level"] < row["battle_lv"]:
            raise ValueError(f'翅膀激活或进阶需要队伍{row["battle_lv"]}级')
        if not state["stage"]:
            if method:
                raise ValueError("激活翅膀不接受保星方式")
            costs = [(1001, int(config["global_kv"]["wing_activation"]["value"]))]
            successful = 1
        else:
            if state["stars"] < row["cond"] or method and not row["special_cost"]:
                raise ValueError("翅膀星级不足或此阶没有保星材料")
            costs = list(equip_evolve.costs(row["cost"] + (row["special_cost"] if method else "")).items())
            successful = int(rng.randrange(100) < chance(state, config))
        if successful:
            state.update(stage=state["stage"] + 1, stars=0, exp=0, failures=0)
        else:
            state["failures"] += 1
            if row["down_lv"] and not method:
                state["stars"] -= 1
                state["exp"] = 0
    elif opcode == 3743:
        color = fields[0][2]
        row = config["wing_stage"].get(str(state["stage"]))
        if not row or color and (str(color) not in config["wing_coler"] or not row.get(f"c{color}")):
            raise ValueError("翅膀未激活或当前阶级不支持此颜色")
        if color and color not in state["colors"]:
            costs = [(config["wing_coler"][str(color)]["item_id"], row["cost_return"])]
            state["colors"].append(color)
        state["color"] = color
    if any(type(cid) is not int or type(count) is not int or not 0 < count < (1 << 31)
           or cid not in (1000, 1001) and str(cid) not in config["props"] for cid, count in costs):
        raise ValueError("翅膀费用配置无效")
    state["checked_at"] = max(now, state["checked_at"])
    save["wing_state"] = state
    get_state(save, config)
    current = attributes(raw, state, config)
    changes = {f: current[f] - previous[f] for f in current if current[f] != previous[f]}
    changed, power = development.adjust(raw, changes) if changes else (raw, 0)
    values = [state["stage"], state["stars"], state["exp"], state["color"], chance(state, config)]
    result = recharge.ids(values + rolls)
    if opcode == 3742:
        result = b"".join(encode_pb_field(1, 2, encode_pb_field(1, 0, mid) + encode_pb_field(2, 2, value))
                          for mid, value in ((0, recharge.ids(values + [successful])), (1, encode_pb_field(1, 2, changed)), (2, b"")))
    elif opcode == 3744:
        row = config["wing_stage"].get(str(state["stage"]), {})
        result = recharge.ids(2 if i in state["colors"] else int(bool(row.get(f"c{i}"))) for i in range(1, 11))
    return result, costs, encode_pb_field(1, 2, changed) if changes else b"", power
