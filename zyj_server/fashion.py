"""主角商城时装的拥有、穿戴、隐藏与配置强化。"""

from . import formation, recharge, shop
from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint, pb_set_varint


QUERIES = (1070, 1075, 1076, 6911)
TRANSACTIONS = (1071, 1072, 1073, 1074)
OPCODES = QUERIES + TRANSACTIONS


def get_state(save, config):
    state = save.setdefault("fashion_state", {"equipped": 0, "show": 0, "levels": {}})
    if (not isinstance(state, dict) or type(state.get("equipped")) is not int
            or type(state.get("show")) is not int or state["show"] not in (0, 1)
            or not isinstance(state.get("levels"), dict)):
        raise ValueError("时装存档无效")
    for cid, level in state["levels"].items():
        if (cid not in config["fashion_gift_bag"] or type(level) is not int
                or str(level) not in config["fashionintentify"][cid]):
            raise ValueError("时装等级存档无效")
    if state["equipped"] and str(state["equipped"]) not in state["levels"]:
        raise ValueError("穿戴了未拥有的时装")
    return state


def attributes(levels, config):
    result = {6: 0, 7: 0, 8: 0}
    for cid, level in levels.items():
        rows = config["fashionintentify"][cid]
        current = rows[str(level)]
        specs = [current[f"intentify_add{i}"] for i in (1, 2, 3)]
        specs.extend(rows[str(i)]["add_attribute"] for i in range(1, level + 1))
        for spec in specs:
            if spec:
                name, value = spec.split(":")
                if name not in ("atk", "def", "hp"):
                    raise ValueError("此时装属性暂不支持")
                result[{"atk": 6, "def": 7, "hp": 8}[name]] += int(value)
    return result


def prepare(opcode, save, body, config, now):
    if opcode == 6911:
        if body:
            raise ValueError("本地伙伴时装暂只支持完整列表查询")
        # 伙伴时装尚无购买/领取入口，当前真实拥有列表为空，不混用主角时装。
        return b"", [], b""
    state = get_state(save, config)
    levels = state["levels"]
    event = config["activity_time"]["43"]
    discount = event["param"] if shop.in_period(event, now) else 0
    if opcode in QUERIES:
        if body:
            raise ValueError("时装查询不接受参数")
        if opcode == 1070:
            values = [state["equipped"], state["show"]]
            for cid, level in sorted(levels.items()):
                values.extend((int(cid), level))
        elif opcode == 1075:
            values = [2 if str(event["param"]) in levels else int(bool(discount))]
        else:
            values = [discount]
            for cid in sorted(config["fashion_gift_bag"], key=int):
                values.extend((int(cid), 2 if cid in levels else 1))
        return recharge.ids(values), [], b""
    if not save.get("has_role") or not save.get("protagonist_snapshot"):
        raise ValueError("角色尚未创建")
    if save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2:
        raise ValueError("请先完成新手引导后使用时装")
    protagonist = bytes.fromhex(save["protagonist_snapshot"])
    generals = formation.records(bytes.fromhex(save["world_state"]["1002"]), 1, 2)
    raw = generals.get(pb_get_varint(protagonist, 1))
    if not raw:
        raise ValueError("缺少主角属性")
    old = attributes(levels, config)
    costs, upgraded, coin, stones = [], 0, 0, 0
    if opcode == 1071:
        if body or not state["equipped"]:
            raise ValueError("尚未穿戴时装或隐藏参数无效")
        state["show"] = 1 - state["show"]
    else:
        fields = list(iter_pb_fields(body))
        if (len(fields) not in ((1, 2) if opcode == 1072 else (1,))
                or any(n != 1 or w != 0 or not 0 < v < (1 << 31) for n, w, v in fields)
                or len(fields) == 2 and fields[1][2] != 5):
            raise ValueError("时装操作参数无效")
        cid = fields[0][2]
        key = str(cid)
        if opcode == 1074:
            row = config["fashion_gift_bag"].get(key)
            if not row or key in levels:
                raise ValueError("时装不存在或已拥有")
            costs = [(1001, row["price"] if cid == discount else row["gold"])]
            levels[key] = 1
        elif key not in levels:
            raise ValueError("尚未拥有此时装")
        elif opcode == 1073:
            state.update(equipped=cid, show=1)
        else:
            props = formation.records(bytes.fromhex(save["world_state"]["1200"]), 1, 1)
            available = pb_get_varint(props.get(20281, b""), 2) or 0
            for _ in range(fields[1][2] if len(fields) == 2 else 1):
                rows = config["fashionintentify"][key]
                row = rows[str(levels[key])]
                if str(levels[key] + 1) not in rows or save["role_state"]["level"] < row["troop"]:
                    break
                price = dict(tuple(map(int, e.split(","))) for e in row["use"].split(";") if e)
                if set(price) != {1000, 20281}:
                    raise ValueError("此时装强化消耗暂不支持")
                if coin + price[1000] > save["role_state"]["coin"] or stones + price[20281] > available:
                    break
                coin += price[1000]
                stones += price[20281]
                levels[key] += 1
                upgraded += 1
            if not upgraded:
                raise ValueError("时装已满级、队伍等级不足或强化材料不足")
            costs = [(1000, coin), (20281, stones)]
    power_delta = 0
    for field, value in attributes(levels, config).items():
        previous = pb_get_varint(raw, field) or 0
        changed = previous + value - old[field]
        if not 0 < changed < (1 << 31):
            raise ValueError("时装属性超出范围")
        raw = pb_set_varint(raw, field, changed)
        power_delta += changed // 10 - previous // 10 if field == 8 else changed - previous
    power = (pb_get_varint(raw, 20) or 0) + power_delta
    if not 0 <= power < (1 << 31):
        raise ValueError("时装战力超出范围")
    raw = pb_set_varint(raw, 20, power)
    for field in ("power", "power_all"):
        save["role_state"][field] += power_delta
        if not 0 <= save["role_state"][field] < (1 << 31):
            raise ValueError("角色战力超出范围")
    current = pb_get_varint(raw, 1)
    coats = config["fashioncoat"][str(state["equipped"] or 80001)]
    base = current if str(current) in coats else next((r["role_id"] for r in coats.values() if r["coat_id"] == current), None)
    if base is None:
        raise ValueError("此主角暂不支持商城时装")
    current = coats[str(base)]["coat_id"] if state["equipped"] and state["show"] else base
    raw = pb_set_varint(raw, 1, current)
    save["role_state"]["profile"] = current
    # 原生“显示时装”复选框：1 不勾选，2 勾选；隐藏仍保留拥有属性。
    save["protagonist_snapshot"] = pb_set_varint(protagonist, 7, (2 if state["show"] else 1) if state["equipped"] else 0).hex()
    response = encode_pb_field(1, 2, raw)
    if opcode == 1072:
        response = b"".join(encode_pb_field(1, 2, encode_pb_field(1, 0, mid) + encode_pb_field(2, 2, data))
                            for mid, data in ((0, response), (1, recharge.ids([upgraded, coin, stones]))))
    elif opcode == 1074:
        prop = encode_pb_field(1, 0, cid) + encode_pb_field(2, 0, 1)
        response = encode_pb_field(5, 2, encode_pb_field(1, 2, prop)) + encode_pb_field(7, 2, b"") + encode_pb_field(10, 2, b"")
    return response, costs, raw
