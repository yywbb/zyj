"""日常活动首期：充值奖励、月/周基金、加速礼包；不接真实支付。"""

from . import activities, recruit, welfare
from .protocol import encode_pb_field, iter_pb_fields, parse_ids_pb, pb_get_varint, pb_set_field, pb_set_varint

QUERIES = (3680, 3682, 5000, 5034, 8026, 8075, 8077)
CLAIMS = (3681, 3683, 5001, 8027, 8076, 8078)
WEEK_PLANS = {7: (169, "week_growup_1", "week_growup_money_1"),
              8: (170, "week_growup_2_1", "week_growup_money_2_1")}


def get_state(save):
    state = save.setdefault("daily_event_state", {
        "day": 0, "rmb": 0, "recharge_claimed": [], "double_counts": {}, "month_max": 0,
        "month_active": [], "month_counts": [0, 0], "month_days": [0, 0], "month_gifts": [],
        "weeks": {"7": {"bought": False, "claimed": []}, "8": {"bought": False, "claimed": []}},
        "speed_bought": {}, "speed_claimed": {},
    })
    if not isinstance(state, dict):
        raise ValueError("日常活动存档无效")
    for key in ("day", "rmb", "month_max"):
        if type(state.get(key)) is not int or not 0 <= state[key] < (1 << 31):
            raise ValueError("日常活动数值无效")
    for key, maximum in (("recharge_claimed", 11), ("month_active", 2), ("month_gifts", 2)):
        values = state.get(key)
        if (not isinstance(values, list) or any(type(v) is not int or not 1 <= v <= maximum for v in values)
                or len(values) != len(set(values))):
            raise ValueError("日常活动领取记录无效")
    for key, maximum in (("month_counts", 20), ("month_days", (1 << 31) - 1)):
        values = state.get(key)
        if not isinstance(values, list) or len(values) != 2 or any(type(v) is not int or not 0 <= v <= maximum for v in values):
            raise ValueError("月基金存档无效")
    for key in ("double_counts", "speed_bought", "speed_claimed"):
        values = state.get(key)
        if (not isinstance(values, dict) or any(not isinstance(k, str) or not k.isascii() or not k.isdecimal()
                or type(v) is not int or not 0 <= v < (1 << 31) for k, v in values.items())):
            raise ValueError("充值活动次数无效")
    weeks = state.get("weeks")
    if not isinstance(weeks, dict) or set(weeks) != {"7", "8"}:
        raise ValueError("周基金存档无效")
    for item in weeks.values():
        if (not isinstance(item, dict) or type(item.get("bought")) is not bool
                or not isinstance(item.get("claimed"), list) or any(type(v) is not int or not 1 <= v <= 7 for v in item["claimed"])
                or len(item["claimed"]) != len(set(item["claimed"]))):
            raise ValueError("周基金领取记录无效")
    return state


def settle(save, now):
    state = get_state(save)
    day = (now + 28800) // 86400
    if day > state["day"]:
        # shortcut: 模拟礼包支付/领取限当天；接真实支付前须保留跨日待领奖订单。
        state.update(day=day, speed_bought={}, speed_claimed={})
    return state


def period(save, config, activity, now):
    return activities.first_period(save, config, activity, now)


def month_end(save, config):
    opened = int(save["created_at"])
    # 与其他首期活动一致，优先使用Role22开服日。
    recorded = pb_get_varint(bytes.fromhex(save.get("role_snapshot", "")), 22)
    if recorded is not None:
        opened = recorded
    return (((opened + 28800) // 86400) + config["activity_time"]["101"]["continued_time"]) * 86400 - 28800


def speed_ids(save, config, now):
    day, remaining = period(save, config, 153, now)
    rows = [r for r in config["speedup_gift_time_x1"].values() if r["day"] <= day]
    if not rows or not remaining:
        return []
    return [int(v) for v in max(rows, key=lambda r: r["day"])["reward"].split(";") if v]


def rewrite_periods(body, save, config, now):
    result = bytearray()
    periods = {rid: period(save, config, rid, now) for rid in (78, 87, 153, 169, 170)}
    for n, w, value in iter_pb_fields(body):
        if (n, w) == (1, 2) and pb_get_varint(value, 1) in (1, 2):
            raw = next(v for f, t, v in iter_pb_fields(value) if (f, t) == (2, 2))
            if pb_get_varint(value, 1) == 1:
                rows = bytearray()
                for f, t, row in iter_pb_fields(raw):
                    if (f, t) == (1, 2):
                        rid = pb_get_varint(row, 1)
                        if rid in periods and not all(periods[rid]):
                            row = pb_set_varint(row, 2, 0)
                    rows.extend(encode_pb_field(f, t, row))
                raw = bytes(rows)
            else:
                values = parse_ids_pb(raw)
                for i in range(0, len(values), 3):
                    if values[i] in periods:
                        values[i + 1:i + 3] = [1, periods[values[i]][0]]
                numbers = iter(values)
                raw = b"".join(encode_pb_field(f, t, next(numbers) if (f, t) == (1, 0) else v) for f, t, v in iter_pb_fields(raw))
            value = pb_set_field(value, 2, 2, raw)
        result.extend(encode_pb_field(n, w, value))
    return bytes(result)


def validate_purchase(save, cid, bagid, config, now):
    state = settle(save, now)
    if (now + 28800) // 86400 < state["day"]:
        raise ValueError("服务器日期回拨，请稍后重试")
    if bagid in WEEK_PLANS:
        activity, _, money = WEEK_PLANS[bagid]
        day, remaining = period(save, config, activity, now)
        if not day or not remaining or cid != config[money]["1"]["gear"] or state["weeks"][str(bagid)]["bought"]:
            raise ValueError("首期周基金已结束、档位不符或已购买")
    else:
        row = config["speedup_gift"].get(str(bagid))
        bought = state["speed_bought"].get(str(bagid), 0)
        claimed = state["speed_claimed"].get(str(bagid), 0)
        if (bagid not in speed_ids(save, config, now) or not row or row["rmb"] != cid
                or save["role_state"]["level"] < row["level"] or save["role_state"]["vip"] < row["vip"]
                or bought >= row["number"] or bought > claimed
                or row["before_id"] and not state["speed_claimed"].get(str(row["before_id"]), 0)):
            raise ValueError("加速礼包未开放、条件不足、已达限购或尚有待领取奖励")


def gold_multiplier(save, row, config, now):
    basic = max(1, row["isdouble"]) if row["id"] not in save["recharge_state"]["bought"] else 1
    day, remaining = period(save, config, 87, now)
    used = get_state(save)["double_counts"].get(str(row["id"]), 0)
    if day and remaining and row["isdouble"] > 1 and used < int(config["global_kv"]["recharge_times"]["value"]):
        return max(basic, int(config["activity_time"]["87"]["param"]))
    return basic


def record_payment(save, row, bagid, config, now):
    state = settle(save, now)
    if (now + 28800) // 86400 < state["day"]:
        raise ValueError("服务器日期回拨，请稍后重试")
    if bagid in WEEK_PLANS:
        state["weeks"][str(bagid)]["bought"] = True
    elif bagid >= 190000:
        key = str(bagid)
        state["speed_bought"][key] = state["speed_bought"].get(key, 0) + 1
    day, remaining = period(save, config, 78, now)
    if day and remaining:
        state["rmb"] += int(row["rmb"])
    day, remaining = period(save, config, 87, now)
    if not bagid and day and remaining and row["isdouble"] > 1:
        key = str(row["id"])
        state["double_counts"][key] = min(int(config["global_kv"]["recharge_times"]["value"]), state["double_counts"].get(key, 0) + 1)
    if now < month_end(save, config):
        state["month_max"] = max(state["month_max"], int(row["rmb"]))
        recharge = save["recharge_state"]
        if recharge["month_until"] > state["day"] and recharge["forever"]:
            for key, fund in config["month_welfare"].items():
                if state["month_max"] >= fund["limit"] and int(key) not in state["month_active"]:
                    state["month_active"].append(int(key))
    get_state(save)


def prepare(opcode, save, body, config, now):
    values = welfare.request_ids(body)
    if len(values) != int(opcode in CLAIMS):
        raise ValueError("日常活动查询/领取参数无效")
    if not save.get("has_role"):
        raise ValueError("角色尚未创建")
    state = settle(save, now)
    day = (now + 28800) // 86400
    if opcode in CLAIMS and day < state["day"]:
        raise ValueError("服务器日期回拨，请稍后重试")
    if opcode in (5000, 5001):
        event_day, remaining = period(save, config, 78, now)
        rows = config["recharge_gift_1"]
        flags = [2 if i in state["recharge_claimed"] else int(bool(event_day and remaining and state["rmb"] >= rows[str(i)]["rmb"]))
                 for i in range(1, len(rows) + 1)]
        if opcode == 5000:
            return welfare.ids([1, event_day, state["rmb"]] + flags)
        rid = values[0]
        if not 1 <= rid <= len(rows) or flags[rid - 1] != 1:
            raise ValueError("累计充值奖励条件未达成或已领取")
        state["recharge_claimed"].append(rid)
        specification = rows[str(rid)]["reward"]
    elif opcode == 5034:
        event_day, _ = period(save, config, 87, now)
        return welfare.ids([1, event_day] + [state["double_counts"].get(str(i), 0) for i in range(1, max(map(int, config["recharge"])) + 1)])
    elif opcode in (8075, 8076, 8077, 8078):
        bagid = 7 if opcode in (8075, 8076) else 8
        activity, table, _ = WEEK_PLANS[bagid]
        event_day, remaining = period(save, config, activity, now)
        plan = state["weeks"][str(bagid)]
        flags = [2 if i in plan["claimed"] else int(bool(plan["bought"] and remaining and 1 <= i <= event_day)) for i in range(1, 8)]
        if opcode in QUERIES:
            return welfare.ids([int(plan["bought"])] + flags)
        rid = values[0]
        if not 1 <= rid <= 7 or flags[rid - 1] != 1:
            raise ValueError("周基金未购买、日期未到、已结束或奖励已领取")
        plan["claimed"].append(rid)
        specification = config[table][str(rid)]["reward"]
    elif opcode in (3680, 3681, 3682, 3683):
        end = month_end(save, config)
        until = end + int(config["global_kv"]["monthfund_time"]["value"]) * 86400
        if opcode == 3680:
            result = []
            for i in (1, 2):
                status = (0 if i not in state["month_active"] else 1 if now < end else
                          3 if now >= until or state["month_days"][i - 1] >= day or state["month_counts"][i - 1] >= 20 else 2)
                result.extend((status, state["month_counts"][i - 1]))
            return welfare.ids(result)
        if opcode == 3682:
            return welfare.ids([2 if i in state["month_gifts"] else int(i in state["month_active"] and now < end) for i in (1, 2)])
        rid = values[0]
        if rid not in state["month_active"]:
            raise ValueError("月基金需要活动期内激活双卡及单笔充值达标")
        if opcode == 3683:
            if rid in state["month_gifts"] or now >= end:
                raise ValueError("基金福利已领取或领取期已结束")
            state["month_gifts"].append(rid)
            specification = config["month_welfare"][str(rid)]["reward"]
        else:
            index = rid - 1
            if not end <= now < until or state["month_days"][index] >= day or state["month_counts"][index] >= 20:
                raise ValueError("月基金尚未到领取期、今日已领或已结束")
            state["month_counts"][index] += 1
            state["month_days"][index] = day
            specification = config["month_growup"][str(state["month_counts"][index])][f"reward{rid}"]
    else:
        available = speed_ids(save, config, now)
        if opcode == 8026:
            result = []
            for rid in available:
                bought, claimed = state["speed_bought"].get(str(rid), 0), state["speed_claimed"].get(str(rid), 0)
                status = 1 if bought > claimed else 2 if claimed >= config["speedup_gift"][str(rid)]["number"] else 0
                result.extend((rid, status, claimed))
            return welfare.ids(result)
        rid = values[0]
        if rid not in available or state["speed_bought"].get(str(rid), 0) <= state["speed_claimed"].get(str(rid), 0):
            raise ValueError("加速礼包未购买、已领取或当日礼包已刷新")
        state["speed_claimed"][str(rid)] = state["speed_claimed"].get(str(rid), 0) + 1
        specification = config["speedup_gift"][str(rid)]["reward"]
    return recruit.build_reward(save, welfare.pairs(specification), config)
