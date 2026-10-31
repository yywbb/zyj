"""账号福利：本地周期和领取状态，奖励由 player 随响应组原子入账。"""

import copy
import datetime
import random

from . import activities
from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint, pb_set_field, pb_set_varint

QUERIES = (214, 2010, 2015, 2017, 2080, 3641, 3643, 4615, 7091)
CLAIMS = (215, 2011, 2016, 3642, 3644, 4611, 4616, 7093)
OPCODES = QUERIES + CLAIMS
HINT_IDS = (30, 32, 36, 132, 245, 252, 429, 551)


def ids(values):
    return b"".join(encode_pb_field(1, 0, v) for v in values)


def get_state(save):
    state = save.setdefault("welfare_state", {
        "day": 0, "checked_at": 0, "peaches": [], "vip_free": False, "vip_buy": False,
        "daily_rmb": 0, "luxury_claimed": False, "luxury_level": 0,
        "sign_month": 0, "sign_count": 0, "sign_day": 0,
        "sign_task_claimed": False, "sign_week": 0, "sign_week_score": 0,
        "login_day": 0, "login_index": 0, "login_claimed": [], "mammon_count": 0,
        "gift_week": 0, "gift_month": 0, "growth_bought": False,
        "growth_claimed": [], "growth_global_claimed": [],
    })
    if not isinstance(state, dict):
        raise ValueError("福利存档无效")
    for key in ("day", "checked_at", "daily_rmb", "luxury_level", "sign_month", "sign_count", "sign_day",
                "sign_week", "sign_week_score", "login_day", "login_index", "mammon_count", "gift_week", "gift_month"):
        if type(state.get(key)) is not int or not 0 <= state[key] < (1 << 31):
            raise ValueError("福利存档数值无效")
    for key in ("vip_free", "vip_buy", "luxury_claimed", "sign_task_claimed", "growth_bought"):
        if type(state.get(key)) is not bool:
            raise ValueError("福利领取状态无效")
    for key, maximum in (("peaches", 3), ("login_claimed", 5), ("growth_claimed", 11), ("growth_global_claimed", 12)):
        values = state.get(key)
        if (not isinstance(values, list) or any(type(v) is not int or not 1 <= v <= maximum for v in values)
                or len(values) != len(set(values))):
            raise ValueError("福利领取记录无效")
    if state["mammon_count"] > 5 or state["login_index"] > 5 or state["sign_count"] > 31:
        raise ValueError("福利次数无效")
    return state


def calendar(now):
    day = (now + 8 * 3600) // 86400
    date = datetime.datetime.fromtimestamp(now, datetime.timezone(datetime.timedelta(hours=8)))
    return day, (day + 3) // 7, date.year * 100 + date.month


def settle(save, now):
    if not save.get("has_role"):
        return
    state = get_state(save)
    day, week, month = calendar(now)
    if day > state["day"]:
        state.update(day=day, peaches=[], vip_free=False, vip_buy=False, daily_rmb=0,
                     luxury_claimed=False, luxury_level=0, sign_task_claimed=False)
    if month > state["sign_month"]:
        state.update(sign_month=month, sign_count=0)
    if week > state["sign_week"]:
        state.update(sign_week=week, sign_week_score=0)
    if day > state["login_day"]:
        # 本地连续五日：首次接入起算，断登重新计数；完成五日后不循环发奖。
        if not (state["login_index"] == 5 and 5 in state["login_claimed"]):
            if state["login_day"] and day == state["login_day"] + 1:
                state["login_index"] = min(5, state["login_index"] + 1)
            else:
                state.update(login_index=1, login_claimed=[])
        state["login_day"] = day
    state["checked_at"] = max(now, state["checked_at"])


def peach_status(state, now):
    seconds = (now + 8 * 3600) % 86400
    return [2 if i in state["peaches"] else 1 if seconds < start * 3600 else
            3 if seconds >= end * 3600 else 0
            for i, (start, end) in enumerate(((12, 14), (18, 20), (21, 24)), 1)]


def mammon_remaining(save, config, now):
    return max(0, int(save["created_at"]) + config["activity_time"]["2"]["continued_time"] * 86400 - now)


def vip_row(save, config):
    rows = config["vip_welfare"][str(save["role_state"].get("vip", 0))]
    levels = sorted(map(int, rows))
    level = next((v for v in levels if v >= save["role_state"]["level"]), levels[-1])
    return rows[str(level)]


def luxury_reward(save, config):
    state = get_state(save)
    if not state["luxury_level"]:
        levels = sorted(map(int, config["luxurysign"]))
        state["luxury_level"] = next((v for v in levels if v >= save["role_state"]["level"]), levels[-1])
    row = config["luxurysign"].get(str(state["luxury_level"]))
    if not row or any(row[f"good{i}prob"] not in (0, 100) for i in range(1, 7)):
        raise ValueError("豪华签到随机奖励配置尚未支持")
    return [(row[f"good{i}"], row[f"good{i}number"]) for i in range(1, 7) if row[f"good{i}prob"] == 100]


def sign_task_status(save, now):
    state = get_state(save)
    day, _, _ = calendar(now)
    if day != state["day"]:
        return 0
    return 2 if state["sign_task_claimed"] else int(bool(save.get("has_role") and state["sign_day"] == day))


def get_hints(save, config, now):
    hints = dict.fromkeys(HINT_IDS, 0)
    if not save.get("has_role"):
        return hints
    save = dict(save, welfare_state=copy.deepcopy(get_state(save)))
    settle(save, now)
    state = get_state(save)
    day, week, month = calendar(now)
    hints[30] = int(day == state["day"] and 0 in peach_status(state, now))
    row = config["mammon"].get(str(state["mammon_count"] + 1))
    hints[32] = int(bool(row and mammon_remaining(save, config, max(now, state["checked_at"]))
                         and save["role_state"].get("vip", 0) >= row["limit"]))
    hints[132] = int(state["sign_day"] < day and str(state["sign_count"] + 1) in config.get(f"sign2_{month}", {}))
    hints[36] = hints[132]
    hints[429] = int(state["login_index"] > 0 and state["login_index"] not in state["login_claimed"])
    hints[245] = int(bool(vip_row(save, config)["free"]) and not state["vip_free"])
    hints[252] = int(state["gift_week"] < week or state["gift_month"] < month)
    hints[551] = int(state["growth_bought"] and any(int(k) not in state["growth_claimed"]
                    and row["level"] <= save["role_state"]["level"] for k, row in config["growplan_x1"]["1"].items()))
    return hints


def rewrite_vip(body, save, purchases):
    state = get_state(save)
    out, index = bytearray(), 0
    for n, w, value in iter_pb_fields(body):
        if (n, w) == (1, 0):
            index += 1
            if index in (2, 3):
                value = purchases["physical" if index == 2 else "energy"]
            elif index in (25, 26):
                value = int(state["vip_free" if index == 25 else "vip_buy"])
        out.extend(encode_pb_field(n, w, value))
    for index in range(index + 1, 27):
        out.extend(ids([purchases["physical"] if index == 2 else purchases["energy"] if index == 3
                        else int(state["vip_free"]) if index == 25 else int(state["vip_buy"]) if index == 26 else 0]))
    return bytes(out)


def rewrite_activities(body):
    # 好友邀请依赖外部关系；保留其余业务 Comb 和未知字段。
    out = bytearray()
    for n, w, value in iter_pb_fields(body):
        if (n, w) == (1, 2) and pb_get_varint(value, 1) == 1:
            data = next(v for f, t, v in iter_pb_fields(value) if (f, t) == (2, 2))
            rows = bytearray()
            for f, t, row in iter_pb_fields(data):
                if (f, t) == (1, 2) and pb_get_varint(row, 1) == 9:
                    row = pb_set_varint(row, 2, 0)
                rows.extend(encode_pb_field(f, t, row))
            value = pb_set_field(value, 2, 2, bytes(rows))
        out.extend(encode_pb_field(n, w, value))
    return bytes(out)


def request_ids(body):
    fields = list(iter_pb_fields(body))
    if any((n, w) != (1, 0) or value >= (1 << 31) for n, w, value in fields):
        raise ValueError("福利请求格式错误")
    return [v for _, _, v in fields]


def prepare(opcode, save, body, config, now):
    values = request_ids(body)
    if opcode == 4611:
        valid = values == [1] or len(values) == 2 and values[0] == 0
    else:
        valid = len(values) == (1 if opcode in (4616, 7093) else 0)
    if not valid:
        raise ValueError("福利请求参数无效")
    if not save.get("has_role"):
        raise ValueError("角色尚未创建")
    state = get_state(save)
    day, week, month = calendar(now)
    if opcode in CLAIMS and day != state["day"]:
        raise ValueError("服务器日期回拨，请稍后重试")
    costs, specification = [], ""
    if opcode in (2017, 2080):
        return b"", costs
    if opcode in (214, 215):
        index = state["login_index"]
        if opcode == 214:
            return ids([index] + [int(i in state["login_claimed"]) for i in range(1, 8)]), costs
        if index in state["login_claimed"]:
            raise ValueError("今日连续登录奖励已领取")
        specification = config["continue7_X1"][str(index)]["reward"]
        state["login_claimed"].append(index)
    elif opcode in (2010, 2011):
        statuses = peach_status(state, now)
        if opcode == 2010:
            return ids(statuses), costs
        if 0 not in statuses:
            raise ValueError("蟠桃宴未到时间或本时段已领取")
        state["peaches"].append(statuses.index(0) + 1)
        specification = f"1001,{config['global_kv']['eat_peaches']['value']}"
        # 原生 language_CN.activity_peace[7] 明确写50体力；不套用录制中的双倍活动。
        return activities.build_reward(save, specification, config) + encode_pb_field(3, 0, 50), costs
    elif opcode in (2015, 2016):
        remaining = mammon_remaining(save, config, max(now, state["checked_at"]))
        if opcode == 2015:
            return ids([state["mammon_count"] + 1, remaining]), costs
        row = config["mammon"].get(str(state["mammon_count"] + 1))
        if not remaining or not row or save["role_state"]["vip"] < row["limit"]:
            raise ValueError("迎财神已结束、次数已用完或贵族等级不足")
        if save["role_state"]["gold"] < row["gold"]:
            raise ValueError("迎财神元宝不足")
        # 本地均匀整数抽取配置区间；客户端只加净收益，展示时再加回本金。
        gross = random.randint(int(row["gold"] * row["min"]), int(row["gold"] * row["max"]))
        specification = f"1001,{gross - row['gold']}"
        state["mammon_count"] += 1
    elif opcode in (3641, 3642):
        if opcode == 3641:
            return ids([state["sign_count"], int(state["sign_day"] >= day)]), costs
        row = config.get(f"sign2_{month}", {}).get(str(state["sign_count"] + 1))
        if state["sign_day"] >= day or not row:
            raise ValueError("今日已签到或本月奖励配置已领完")
        multiple = 2 if row["double"] and save["role_state"]["vip"] >= row["vip"] else 1
        specification = ";".join(f"{cid},{count * multiple}" for cid, count in pairs(row["award"]))
        state.update(sign_day=day, sign_count=state["sign_count"] + 1)
    elif opcode in (3643, 3644):
        reward = luxury_reward(save, config)
        status = 2 if state["luxury_claimed"] else int(state["daily_rmb"] >= int(config["global_kv"]["luxurysign_cost"]["value"]))
        if opcode == 3643:
            return ids([status] + [v for pair in reward for v in pair]), costs
        if status != 1:
            raise ValueError("今日模拟充值未达豪华签到门槛或奖励已领取")
        specification = ";".join(f"{cid},{count}" for cid, count in reward)
        state["luxury_claimed"] = True
    elif opcode == 4611:
        row = vip_row(save, config)
        free = values == [1]
        key = "vip_free" if free else "vip_buy"
        if not free:
            rows = config["vip_welfare"][str(save["role_state"]["vip"])]
            chosen = rows.get(str(values[1]))
            levels = sorted(map(int, rows))
            minimum = levels[levels.index(values[1]) - 1] + 1 if chosen and values[1] != levels[0] else 1
            if not chosen or minimum > save["role_state"]["level"]:
                raise ValueError("贵族礼包等级未解锁")
            if chosen != row and (save["role_state"]["level"] < int(config["global_kv"]["welfare_choose_limit"]["value"])
                                  or not chosen["limit"]):
                raise ValueError("贵族自选礼包未解锁")
            row = chosen
            costs = pairs(row["discount"])
        specification = row["free" if free else "pay"]
        if not specification or state[key]:
            raise ValueError("贵族福利未解锁或今日已领取")
        state[key] = True
    elif opcode in (4615, 4616):
        # 本地周/月轮换：按 UTC+8 日历周期依次轮换四套配置，不读取官方账号历史。
        weekly = week % len(config["week_month_gift"]) + 1
        monthly = (month // 100 * 12 + month % 100 - 1) % len(config["week_month_gift"]) + 1
        if opcode == 4615:
            return ids([int(state["gift_week"] >= week), weekly, int(state["gift_month"] >= month), monthly]), costs
        if values[0] not in (1, 2):
            raise ValueError("福利礼包编号无效")
        opt = values[0]
        key, period = ("gift_week", week) if opt == 1 else ("gift_month", month)
        if state[key] >= period:
            raise ValueError("本周期福利礼包已购买")
        row = config["week_month_gift"][str(weekly if opt == 1 else monthly)]
        costs, specification = pairs(row[f"price{opt}"]), row[f"gift{opt}"]
        state[key] = period
    elif opcode in (7091, 7093):
        # shortcut: 当前开放第一期；后续期需明确升级/购买规则后再推进阶段。
        rows = config["growplan_x1"]["1"]
        if opcode == 7091:
            flags = [2 if i in state["growth_claimed"] else int(save["role_state"]["level"] >= rows[str(i)]["level"])
                     for i in range(1, len(rows) + 1)] if state["growth_bought"] else []
            return ids([1] + flags), costs
        row = rows.get(str(values[0]))
        if (not state["growth_bought"] or not row or save["role_state"]["level"] < row["level"]
                or values[0] in state["growth_claimed"]):
            raise ValueError("成长计划未购买、等级不足或奖励已领取")
        specification = f"1001,{row['gold']}"
        state["growth_claimed"].append(values[0])
    return activities.build_reward(save, specification, config), costs


def pairs(specification):
    return [tuple(map(int, entry.split(","))) for entry in specification.split(";") if entry]


def prepare_global(opcode, save, body, config, count):
    values = request_ids(body)
    if len(values) != (1 if opcode == 7095 else 0) or not save.get("has_role"):
        raise ValueError("成长计划查询/领取参数无效")
    state = get_state(save)
    rows = config["growplan_global_x1"]
    if opcode == 7094:
        return ids([count] + [2 if i in state["growth_global_claimed"] else int(count >= rows[str(i)]["num"])
                             for i in range(1, len(rows) + 1)])
    row = rows.get(str(values[0]))
    if not row or count < row["num"] or values[0] in state["growth_global_claimed"]:
        raise ValueError("本地服购买人数未达标或奖励已领取")
    state["growth_global_claimed"].append(values[0])
    return activities.build_reward(save, row["awards"], config)
