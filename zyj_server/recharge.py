"""研究用本地模拟充值；订单确认即成功，永不调用支付渠道。"""

from . import activities, daily_events, recruit, timebag, welfare
from .protocol import encode_pb_field, iter_pb_fields


OPCODES = (115, 116, 117, 2090, 2091, 2092, 2093, 2097, 2098, 2099)
CLAIMS = (116, 2091, 2093, 2098)


def ids(values):
    return b"".join(encode_pb_field(1, 0, v) for v in values)


def one_id(body):
    fields = list(iter_pb_fields(body))
    if len(fields) != 1 or fields[0][:2] != (1, 0) or not 0 < fields[0][2] < (1 << 31):
        raise ValueError("充值参数无效")
    return fields[0][2]


def get_state(save):
    state = save.setdefault("recharge_state", {"order": 0, "cid": 0, "paid": False, "rmb": 0,
                                             "bought": [], "first_claimed": False, "card_rmb": 0,
                                             "month_until": 0, "forever": False,
                                             "card_days": {"1": 0, "2": 0}, "card_gifts": []})
    if not isinstance(state, dict):
        raise ValueError("充值存档无效")
    for key in ("order", "cid", "rmb", "card_rmb", "month_until"):
        if type(state.get(key)) is not int or not 0 <= state[key] < (1 << 31):
            raise ValueError("充值存档数值无效")
    for key in ("paid", "first_claimed", "forever"):
        if type(state.get(key)) is not bool:
            raise ValueError("充值存档状态无效")
    for key in ("bought", "card_gifts"):
        if not isinstance(state.get(key), list) or any(type(v) is not int or v <= 0 for v in state[key]):
            raise ValueError("充值领取记录无效")
    if (type(state.setdefault("bagid", 0)) is not int
            or not (state["bagid"] in (0, 2, 7, 8, *timebag.GIFTS) or 190000 <= state["bagid"] < 192000)):
        raise ValueError("充值商品类型无效")
    if (not isinstance(state.get("card_days"), dict) or set(state["card_days"]) != {"1", "2"}
            or any(type(v) is not int or v < 0 for v in state["card_days"].values())):
        raise ValueError("月卡领取记录无效")
    return state


def vip(state, config):
    return max(int(k) for k, v in config["vip"].items() if v["needgold"] <= state["rmb"])


def prepare(opcode, save, body, config, now):
    state = get_state(save)
    day = (now + 8 * 3600) // 86400
    if opcode not in (115, 116, 2091, 2093) and body:
        raise ValueError("充值查询/首充领取不接受参数")
    if opcode in (115, *CLAIMS) and not save.get("has_role"):
        raise ValueError("角色尚未创建")
    if opcode == 115:
        fields = list(iter_pb_fields(body))
        if len(fields) not in (1, 2) or any(f[:2] != (1, 2) for f in fields):
            raise ValueError("本地模拟充值参数无效")
        cid = one_id(fields[0][2])
        bagid = one_id(fields[1][2]) if len(fields) == 2 else 0
        if bagid == 2 and (cid != config["chengzhangplan_money"]["1"]["recharge_id"]
                           or welfare.get_state(save)["growth_bought"]):
            raise ValueError("成长计划档位无效或已购买")
        if bagid in timebag.GIFTS:
            timebag.validate_purchase(save, cid, config, now, bagid)
        elif bagid not in (0, 2):
            daily_events.validate_purchase(save, cid, bagid, config, now)
        row = config["recharge"].get(str(cid))
        if not row or row["show"] != 1 or cid == 2 and state["forever"]:
            raise ValueError("充值档位无效或终身卡已购买")
        if state["paid"] or state["cid"] != cid or state["bagid"] != bagid:
            state.update(order=state["order"] + 1, cid=cid, bagid=bagid, paid=False)
        get_state(save)
        return encode_pb_field(1, 2, encode_pb_field(1, 0, state["order"]))
    if opcode == 117:
        return ids([vip(state, config), state["rmb"], 2 if state["first_claimed"] else int(bool(state["bought"]))])
    if opcode in (2097, 2099):
        return ids([int(i in state["bought"]) for i in range(1, max(map(int, config["recharge"])) + 1)])
    if opcode == 2090:
        days = max(0, state["month_until"] - day)
        return ids([days, (2 if state["card_days"]["1"] >= day else 1) if days else 0,
                    1 if state["forever"] else 0, (2 if state["card_days"]["2"] >= day else 1) if state["forever"] else 0])
    if opcode == 2092:
        return ids([2 if i in state["card_gifts"] else int(bool(state["card_rmb"]) and state["card_rmb"] >= config["monthcardgift"][str(i)]["rmb"])
                    for i in range(1, max(map(int, config["monthcardgift"])) + 1)])
    if opcode == 116:
        order = one_id(body)
        if order != state["order"] or not state["cid"]:
            raise ValueError("本地模拟充值订单不存在或已过期")
        if state["paid"]:
            return recruit.build_reward(save, [], config)
        row = config["recharge"][str(state["cid"])]
        cid = row["id"]
        if state["bagid"] in timebag.GIFTS:
            timebag.validate_purchase(save, cid, config, now, state["bagid"])
            timebag.get_state(save, state["bagid"])["paid"] = True
        elif state["bagid"] not in (0, 2):
            daily_events.validate_purchase(save, cid, state["bagid"], config, now)
        benefits = welfare.get_state(save)
        if state["bagid"] == 2:
            if benefits["growth_bought"]:
                raise ValueError("成长计划已购买")
            benefits["growth_bought"] = True
        gold = 0 if state["bagid"] else row["gold"] * daily_events.gold_multiplier(save, row, config, now)
        state["paid"] = True
        if 1 <= activities.begin7day_day(save, now) <= 7:
            activities.get_state(save)["begin7day_rmb"] += int(row["rmb"])
        state["rmb"] += int(row["rmb"])
        if day != benefits["day"]:
            raise ValueError("服务器日期回拨，请稍后重试")
        benefits["daily_rmb"] += int(row["rmb"])
        if not state["bagid"] and cid not in state["bought"]:
            state["bought"].append(cid)
        if cid == 1 and not state["bagid"]:
            state["month_until"] = max(day, state["month_until"]) + 30
        if cid == 2 and not state["bagid"]:
            state["forever"] = True
        if cid in (1, 2) and not state["bagid"]:
            state["card_rmb"] += int(row["rmb"])
        save["role_state"]["vip"] = vip(state, config)
        daily_events.record_payment(save, row, state["bagid"], config, now)
        get_state(save)
        welfare.get_state(save)
        return recruit.build_reward(save, [(1001, gold)] if gold else [], config)
    if opcode == 2091:
        cid = one_id(body)
        if (cid not in (1, 2) or state["card_days"][str(cid)] >= day
                or not (state["month_until"] > day if cid == 1 else state["forever"])):
            raise ValueError("月卡未生效或今日奖励已领取")
        state["card_days"][str(cid)] = day
        row = config["recharge"][str(cid)]
        specification = row["daygift"] + (f";1001,{row['daygold']}" if row["daygold"] else "")
    elif opcode == 2093:
        cid = one_id(body)
        row = config["monthcardgift"].get(str(cid))
        if not row or not state["card_rmb"] or state["card_rmb"] < row["rmb"] or cid in state["card_gifts"]:
            raise ValueError("月卡累计奖励未达标或已领取")
        state["card_gifts"].append(cid)
        specification = row["reward"]
    else:
        if not state["bought"] or state["first_claimed"]:
            raise ValueError("首充奖励未达标或已领取")
        row = config["firstpay"]["1"]
        state["first_claimed"] = True
        specification = ";".join(f"{row[f'goods{i}']},{row[f'goods{i}num']}" for i in (2, 3, 4))
    return recruit.build_reward(save, [tuple(map(int, e.split(","))) for e in specification.split(";") if e], config)
