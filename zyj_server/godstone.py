"""阵位神石：按原生顺序强化，配置决定属性、材料和等级门槛。"""

from fractions import Fraction

from .protocol import iter_pb_fields, pb_get_varint, pb_set_varint

ATTR_FIELDS = {"atk": 6, "def": 7, "hp": 8, "dodge": 11, "parry": 12, "resilience": 13, "hit": 14, "arp": 15}
RATE_FIELDS = {11, 12, 13, 14, 15}


def levels(slot, config):
    fields = [(n, w, v) for n, w, v in iter_pb_fields(slot) if 18 <= n <= 25]
    values = [pb_get_varint(slot, n) or 0 for n in range(18, 26)]
    if (any(w != 0 for n, w, v in fields) or len({n for n, w, v in fields}) != len(fields)
            or any(v and str(v) not in config["godstonestrengthening"] for v in values)
            or values != sorted(values, reverse=True) or max(values) - min(values) > 1):
        raise ValueError("阵位神石等级或强化顺序无效")
    return values


def attributes(slot, config):
    values = {field: Fraction(0) for field in ATTR_FIELDS.values()}
    for index, level in enumerate(levels(slot, config), 1):
        if level:
            name = config["godstone"][str(index)]["attribute"]
            field = ATTR_FIELDS[name]
            values[field] += Fraction(str(config["godstonestrengthening"][str(level)][name])) * (100 if field in RATE_FIELDS else 1)
    return values


def strengthen(slot, method, role_level, fragments, config):
    values = levels(slot, config)
    start = next((i for i, v in enumerate(values) if v < values[0]), 0)
    cost = 0
    # 本地一键补齐当前一轮，每块最多升一级，与原生回调逐块扣料一致。
    for index in range(start, 8 if method else start + 1):
        row = config["godstonestrengthening"].get(str(values[index] + 1))
        if row is None or role_level < row["teamlv"]:
            break
        name = config["godstone"][str(index + 1)]["attribute"]
        price = row[name + "_number"]
        if fragments < cost + price:
            break
        cost += price
        slot = pb_set_varint(slot, 18 + index, values[index] + 1)
    if not cost:
        raise ValueError("神石碎片不足、角色等级不足或已强化到满级")
    return slot, cost
