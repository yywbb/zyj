"""魔宠限时礼包：触发、模拟付款及领取与角色存档一起提交。"""

from . import recruit
from .protocol import encode_pb_field, iter_pb_fields, parse_ids_pb

PET_GIFT = 130012
QUERIES = (2880,)
MUTATIONS = (2881, 2882)
OPCODES = QUERIES + MUTATIONS


def get_state(save):
    state = save.setdefault("pet_gift_state", {"triggered_at": 0, "checked_at": 0, "paid": False, "claimed": False})
    if (not isinstance(state, dict)
            or any(type(state.get(k)) is not int or state[k] < 0 for k in ("triggered_at", "checked_at"))
            or any(type(state.get(k)) is not bool for k in ("paid", "claimed"))
            or state["claimed"] and not state["paid"]
            or state["paid"] and not state["triggered_at"]
            or state["triggered_at"] > state["checked_at"]):
        raise ValueError("魔宠礼包存档无效")
    return state


def status(save, config, now):
    state = get_state(save)
    state["checked_at"] = max(now, state["checked_at"])
    # 本地限时规则：配置 time 按分钟计，付款后待领奖资格不随倒计时消失。
    remaining = max(0, state["triggered_at"] + config["trigger_gift2"][str(PET_GIFT)]["time"] * 60 - state["checked_at"])
    return (2 if state["claimed"] else 1 if state["paid"] else -1 if not state["triggered_at"]
            else 0 if remaining else -2), remaining if state["triggered_at"] else 0


def validate_purchase(save, cid, config, now):
    if (not save.get("has_role") or save["role_state"]["level"] < config["trigger_gift2"][str(PET_GIFT)]["level"]
            or cid != int(config["trigger_gift2"][str(PET_GIFT)]["recharge_id"])
            or status(save, config, now)[0] != 0):
        raise ValueError("魔宠礼包尚未触发、已过期、已购买或充值档位无效")


def prepare(opcode, save, body, config, now, baseline=b""):
    fields = list(iter_pb_fields(body))
    if opcode == 2880:
        if body:
            raise ValueError("限时礼包查询不接受参数")
        values = parse_ids_pb(baseline)
        if len(values) % 3:
            raise ValueError("限时礼包查询基线无效")
        rows = [values[i:i + 3] for i in range(0, len(values), 3)]
        current = [PET_GIFT, *status(save, config, now)]
        if any(r[0] == PET_GIFT for r in rows):
            rows = [current if r[0] == PET_GIFT else r for r in rows]
        else:
            rows.append(current)
        return b"".join(encode_pb_field(1, 0, v & ((1 << 64) - 1)) for r in rows for v in r)
    if len(fields) != 1 or fields[0] != (1, 0, PET_GIFT):
        raise ValueError("此限时礼包请求无效；本次仅接通魔宠礼包")
    state = get_state(save)
    if opcode == 2882:
        if (not save.get("has_role") or save["role_state"]["level"] < config["trigger_gift2"][str(PET_GIFT)]["level"]
                or save.get("guide", {}).get("sections", {}).get("59", {}).get("status") != 2):
            raise ValueError("魔宠引导完成后才能触发礼包")
        if not state["triggered_at"]:
            state["triggered_at"] = max(now, state["checked_at"])
        return b"".join(encode_pb_field(1, 0, v & ((1 << 64) - 1)) for v in (PET_GIFT, *status(save, config, now)))
    if status(save, config, now)[0] != 1:
        raise ValueError("请先完成魔宠礼包的本地模拟付款，且不能重复领取")
    state["claimed"] = True
    gets = [tuple(map(int, e.split(","))) for e in config["trigger_gift2"][str(PET_GIFT)]["gift_id"].split(";") if e]
    return recruit.build_reward(save, gets, config)
