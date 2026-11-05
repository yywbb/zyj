"""功能限时礼包：触发、模拟付款及领取与角色存档一起提交。"""

from . import recruit
from .protocol import encode_pb_field, iter_pb_fields, parse_ids_pb, pb_get_varint

PET_GIFT = 130012
GIFTS = {PET_GIFT: ("pet_gift_state", 59), 130013: ("stone_gift_state", 104), 130014: ("baptize_gift_state", 21),
         130004: ("sigil_gift_state", 22), 130010: ("sigil_growth_gift_state", None), 130015: ("treasure_gift_state", 23),
         130016: ("magic_gift_state", 65), 130007: ("soul_gift_state", 73), 130021: ("equip_evolve_gift_state", 75),
          130009: ("equip_star_gift_state", 93), 130006: ("wing_gift_state", 86),
          130019: ("equip_injection_gift_state", 79),
          130005: ("cover_gift_state", 97), 130017: ("cover_advance_gift_state", 78), 130026: ("cover_soaring_gift_state", 102),
          130018: ("gamestar_gift_state", None), 130008: ("deployment_gift_state", 90), 130011: ("artifact_gift_state", 80)}
QUERIES = (2880,)
MUTATIONS = (2881, 2882)
OPCODES = QUERIES + MUTATIONS


def get_state(save, gift_id=PET_GIFT):
    state = save.setdefault(GIFTS[gift_id][0], {"triggered_at": 0, "checked_at": 0, "paid": False, "claimed": False})
    if (not isinstance(state, dict)
            or any(type(state.get(k)) is not int or state[k] < 0 for k in ("triggered_at", "checked_at"))
            or any(type(state.get(k)) is not bool for k in ("paid", "claimed"))
            or state["claimed"] and not state["paid"]
            or state["paid"] and not state["triggered_at"]
            or state["triggered_at"] > state["checked_at"]):
        raise ValueError("限时礼包存档无效")
    return state


def status(save, config, now, gift_id=PET_GIFT):
    state = get_state(save, gift_id)
    state["checked_at"] = max(now, state["checked_at"])
    # 本地限时规则：配置 time 按分钟计，付款后待领奖资格不随倒计时消失。
    remaining = max(0, state["triggered_at"] + config["trigger_gift2"][str(gift_id)]["time"] * 60 - state["checked_at"])
    return (2 if state["claimed"] else 1 if state["paid"] else -1 if not state["triggered_at"]
            else 0 if remaining else -2), remaining if state["triggered_at"] else 0


def validate_purchase(save, cid, config, now, gift_id=PET_GIFT):
    if (not save.get("has_role") or save["role_state"]["level"] < config["trigger_gift2"][str(gift_id)]["level"]
            or cid != int(config["trigger_gift2"][str(gift_id)]["recharge_id"])
            or status(save, config, now, gift_id)[0] != 0):
        raise ValueError("礼包尚未触发、已过期、已购买或充值档位无效")


def status_payload(save, config, now, gift_id):
    return b"".join(encode_pb_field(1, 0, v & ((1 << 64) - 1)) for v in (gift_id, *status(save, config, now, gift_id)))


def prepare(opcode, save, body, config, now, baseline=b""):
    fields = list(iter_pb_fields(body))
    if opcode == 2880:
        if body:
            raise ValueError("限时礼包查询不接受参数")
        values = parse_ids_pb(baseline)
        if len(values) % 3:
            raise ValueError("限时礼包查询基线无效")
        rows = [values[i:i + 3] for i in range(0, len(values), 3)]
        for gift_id in GIFTS:
            current = [gift_id, *status(save, config, now, gift_id)]
            if any(r[0] == gift_id for r in rows):
                rows = [current if r[0] == gift_id else r for r in rows]
            else:
                rows.append(current)
        return b"".join(encode_pb_field(1, 0, v & ((1 << 64) - 1)) for r in rows for v in r)
    if len(fields) != 1 or fields[0][:2] != (1, 0) or fields[0][2] not in GIFTS:
        raise ValueError("此限时礼包请求无效或对应功能尚未接通")
    gift_id = fields[0][2]
    state = get_state(save, gift_id)
    if opcode == 2882:
        row = config["trigger_gift2"][str(gift_id)]
        if not save.get("has_role") or save["role_state"]["level"] < row["level"]:
            raise ValueError("限时礼包等级尚未满足")
        if row["type"] == 1 and GIFTS[gift_id][1] is not None and save.get("guide", {}).get("sections", {}).get(str(GIFTS[gift_id][1]), {}).get("status") != 2:
            raise ValueError("对应功能引导完成后才能触发礼包")
        if gift_id == 130018 and ("gamestar_state" not in save or save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2):
            raise ValueError("请先打开已解锁的游戏厅")
        if row["type"] == 2 and not state["triggered_at"]:
            opened = pb_get_varint(bytes.fromhex(save.get("role_snapshot", "")), 22)
            day = (max(now, state["checked_at"]) + 28800) // 86400 - ((int(save["created_at"]) if opened is None else opened) + 28800) // 86400 + 1
            if not row["param1"] <= day <= row["param2"]:
                raise ValueError("魔符成长礼包不在配置的首期触发日期内")
        if not state["triggered_at"]:
            state["triggered_at"] = state["checked_at"] = max(now, state["checked_at"])
        return status_payload(save, config, now, gift_id)
    if status(save, config, now, gift_id)[0] != 1:
        raise ValueError("请先完成礼包的本地模拟付款，且不能重复领取")
    state["claimed"] = True
    gets = [tuple(map(int, e.split(","))) for e in config["trigger_gift2"][str(gift_id)]["gift_id"].split(";") if e]
    return recruit.build_reward(save, gets, config)
