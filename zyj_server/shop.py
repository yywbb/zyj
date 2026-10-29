"""商城道具、终身限购礼包、周礼包及固定内容礼包。"""

from datetime import datetime, timedelta, timezone

from . import recharge, recruit
from .protocol import encode_pb_field, iter_pb_fields


QUERIES = (3200, 3210, 4890)
PURCHASES = (3201, 3211, 4891)
OPCODES = QUERIES + PURCHASES


def get_state(save):
    state = save.setdefault("shop_state", {"day": 0, "week": 0, "props": {}, "gifts": {}, "weekly": {}})
    if not isinstance(state, dict):
        raise ValueError("商城存档无效")
    for key in ("day", "week"):
        if type(state.get(key)) is not int or state[key] < 0:
            raise ValueError("商城周期存档无效")
    for key in ("props", "gifts", "weekly"):
        counts = state.get(key)
        if (not isinstance(counts, dict) or any(not isinstance(k, str) or not k.isdecimal() or int(k) <= 0
                or str(int(k)) != k or type(v) is not int or not 0 <= v < (1 << 31) for k, v in counts.items())):
            raise ValueError("商城限购存档无效")
    return state


def in_period(row, now):
    current = datetime.fromtimestamp(now, timezone(timedelta(hours=8))).strftime("%Y%m%d%H%M%S")
    return (not row.get("begin") or row["begin"] <= current) and (not row.get("end") or current < row["end"])


def id_num(body):
    fields = list(iter_pb_fields(body))
    if len(fields) != 1 or fields[0][:2] != (1, 2):
        raise ValueError("商城购买必须指定一件商品及数量")
    item = sorted(iter_pb_fields(fields[0][2]))
    if (len(item) != 2 or [f[:2] for f in item] != [(1, 0), (2, 0)]
            or any(not 0 < v < (1 << 31) for _, _, v in item)):
        raise ValueError("商城商品或数量无效")
    return item[0][2], item[1][2]


def fixed_box(row):
    return row.get("type") in ("box", "vipbox") and row.get("function") == "box1"


def open_box(save, values, config):
    if not save.get("has_role"):
        raise ValueError("角色尚未创建")
    if len(values) != 2 or not 1 <= values[1] <= 100:
        raise ValueError("礼包使用数量无效")
    cid, count = values
    row = config["props"][str(cid)]
    if not fixed_box(row) or row["use_limit"]:
        raise ValueError("此礼包开启条件暂不支持")
    vip_box = row["type"] == "vipbox"
    if vip_box and int(row["param1"] or 0) > save["role_state"].get("vip", 0):
        raise ValueError("贵族等级不足")
    specification = row["param2" if vip_box else "param1"]
    gets = [(int(cid), int(num) * count) for entry in specification.split(";") if entry
            for cid, num in [entry.split(",")]]
    if not gets:
        raise ValueError("礼包缺少奖励配置")
    return recruit.build_reward(save, gets, config)


def prepare(opcode, save, body, config, now):
    state = get_state(save)
    day = (now + 8 * 3600) // 86400
    # 本地规则：UTC+8 零点/周一刷新，时钟回退不得再次发放限购额度。
    for key, current, counts in (("day", day, "props"), ("week", (day + 3) // 7, "weekly")):
        if current > state[key]:
            state[key], state[counts] = current, {}
    if opcode in QUERIES:
        if body:
            raise ValueError("商城查询不接受参数")
        if opcode == 3200:
            response = recharge.ids([state["props"].get(str(i), 0) for i in range(1, max(map(int, config["shop"])) + 1)])
        elif opcode == 4890:
            response = recharge.ids([state["weekly"].get(str(i), 0) for i in range(1, max(map(int, config["vip_weekgift"])) + 1)])
        else:
            response = b"".join(encode_pb_field(1, 2, b"".join(encode_pb_field(n, 0, v) for n, v in
                                ((1, row["id"]), (2, row["personallimit"] - state["gifts"].get(key, 0)),
                                 (3, row["gold"]), (4, row["discount"]))))
                                for key, row in sorted(config["gift_bag"].items(), key=lambda e: int(e[0]))
                                if state["gifts"].get(key, 0) < row["personallimit"])
        return response, [], b""
    if not save.get("has_role"):
        raise ValueError("角色尚未创建")
    vip = save["role_state"].get("vip", 0)
    cid, count = (recharge.one_id(body), 1) if opcode == 4891 else id_num(body)
    key = str(cid)
    if opcode == 3201:
        row = config["shop"].get(key)
        if not row or not in_period(row, now):
            raise ValueError("商品不存在或不在出售时间")
        used = state["props"].get(key, 0)
        limit = row.get(f"vip{vip}_times", 0) or row["num"]
        if used + count > limit:
            raise ValueError("今日购买数量已达上限")
        prices = config["shop_price"]
        last = max(map(int, prices))
        cost = row["discount"] * count if row["discount"] else sum(
            prices[str(min(i, last))][f"{cid}_id"] for i in range(used + 1, used + count + 1))
        state["props"][key] = used + count
    elif opcode == 3211:
        row = config["gift_bag"].get(key)
        if not row or count != 1 or state["gifts"].get(key, 0) >= row["personallimit"]:
            raise ValueError("礼包不存在、数量无效或已购买")
        prop = config["props"][key]
        if prop["type"] == "vipbox" and int(prop["param1"] or 0) > vip:
            raise ValueError("贵族等级不足")
        cost = row["discount"] or row["gold"]
        state["gifts"][key] = state["gifts"].get(key, 0) + 1
    else:
        row = config["vip_weekgift"].get(key)
        if not row or vip < cid or state["weekly"].get(key, 0) >= row["num"]:
            raise ValueError("周礼包未解锁或本周已购买")
        cost = row["gold"]
        state["weekly"][key] = state["weekly"].get(key, 0) + 1
    reward = recruit.build_reward(save, [(row["id"], count)], config)
    # 原生购买回调自行扣元宝，普通礼包还自行加入背包。
    return encode_pb_field(1, 0, 1) if opcode == 3211 else reward, [(1001, cost)], reward
