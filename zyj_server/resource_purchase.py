"""体力、精力的配置价格、每日限额和客户端报价校验。"""

from fractions import Fraction

from . import arena, single_boss
from .protocol import iter_pb_fields


def get_state(save):
    state = save.setdefault("resource_purchase_state", {"day": 0, "physical": 0, "energy": 0})
    if (not isinstance(state, dict) or any(type(state.get(k)) is not int or not 0 <= state[k] < (1 << 31)
                                          for k in ("day", "physical", "energy"))):
        raise ValueError("体力精力购买存档无效")
    return state


def settle(save, now):
    state = get_state(save)
    day = (now + 28800) // 86400
    if day > state["day"]:
        state.update(day=day, physical=0, energy=0)
    return state


def prepare(save, body, config, now):
    fields = list(iter_pb_fields(body))
    if len(fields) not in (2, 3) or any((n, w) != (1, 0) or v >= (1 << 31) for n, w, v in fields):
        raise ValueError("购买资源需要数量和当前价格，请更新客户端")
    if len(fields) == 3:
        kind, count, quoted = (v for _, _, v in fields)
    else:
        kind, count = (v for _, _, v in fields)
        quoted = None
    if not save.get("has_role") or count <= 0:
        raise ValueError("购买资源类型或数量无效")
    if kind == 1:
        if quoted is None:
            raise ValueError("购买资源需要数量和当前价格，请更新客户端")
        return arena.buy(save, count, quoted, config, now)
    if kind == 6:
        if quoted is None:
            raise ValueError("购买资源需要数量和当前价格，请更新客户端")
        return single_boss.buy(save, count, quoted, config, now)
    from . import activity_copy
    if kind in activity_copy.BUY_KINDS:
        return activity_copy.buy(save, kind, count, quoted, config, now)
    if kind not in (2, 3) or quoted is None:
        raise ValueError("购买资源类型或数量无效")
    state = settle(save, now)
    if (now + 28800) // 86400 < state["day"]:
        raise ValueError("服务器日期回拨，请稍后重试")
    key, resource, vipkey = ("physical", "stamina", "b_physical") if kind == 2 else ("energy", "energy", "b_energy")
    if state[key] + count > config["vip"][str(save["role_state"]["vip"])][vipkey]:
        raise ValueError("今日购买次数不足")
    day = (now + 28800) // 86400
    weekday = (day + 3) % 7 + 1
    rows = [v for v in config["activity_huodong"].values() if v["param"] == 3 and v["open_time"] == weekday]
    factor = Fraction(str(rows[0]["modulus"])) if rows else Fraction(1)
    prices = config["buycount_price"]
    price = sum(int(prices[str(i)][resource] * factor) for i in range(state[key] + 1, state[key] + count + 1))
    if price != quoted:
        raise ValueError("价格或每日次数已变化，请重新打开购买窗口")
    amount = int(config["global_kv"][f"basic_buy_{resource}"]["value"]) * count
    if amount <= 0 or save["role_state"][resource] + amount >= (1 << 31):
        raise ValueError("购买资源超出范围")
    state[key] += count
    save["role_state"][resource] += amount
    return price
