"""阵位魔罩、全队大师与配置商店；真实费用和属性由玩家事务统一提交。"""

from fractions import Fraction

from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint, pb_set_varint

QUERIES = (3730, 3732, 3733)
MUTATIONS = (3731, 3734, 3735, 3736)
OPCODES = QUERIES + MUTATIONS
FIELDS = {"atk": 6, "def": 7, "hp": 8}


def get_state(save, config):
    state = save.get("cover_state", {"levels": [0] * 7, "advanced": [0] * 7, "soaring": [0] * 7,
                                     "day": 0, "shop": {}, "checked_at": 0})
    if (not isinstance(state, dict) or any(not isinstance(state.get(k), list) or len(state[k]) != 7
            or any(type(v) is not int or not 0 <= v <= limit for v in state[k])
            for k, limit in (("levels", 240), ("advanced", 18), ("soaring", 90)))
            or any(type(state.get(k)) is not int or not 0 <= state[k] < (1 << 63) for k in ("day", "checked_at"))
            or not isinstance(state.get("shop"), dict)):
        raise ValueError("魔罩成长或商店存档无效")
    for sid in range(7):
        advanced, soaring = state["advanced"][sid], state["soaring"][sid]
        if advanced:
            row = config["mozhao_evolve"][str(advanced)]
            if state["levels"][sid] < row["mozhao_lv"] or min(state["advanced"]) < row["mozhao_evolve_lv"]:
                raise ValueError("魔罩进阶存档不满足真实前置")
        row = config["mozhao_soaring"][str(soaring)]
        if advanced < row["advanced_level"] or min(state["soaring"]) < row["all_soaring_level"]:
            raise ValueError("魔罩飞升存档不满足真实前置")
    for key, count in state["shop"].items():
        row = config["mozhao_shop"].get(key)
        if not row or type(count) is not int or not 0 <= count <= row["times"]:
            raise ValueError("魔罩商店购买次数无效")
    return state


def effects(text):
    result = {}
    for entry in text.split(";"):
        if not entry:
            continue
        name, amount = entry.split(",")
        value = Fraction(amount)
        if name not in (*FIELDS, "g_hp", "g_def", "skill_resilience") or not 0 <= value < (1 << 31):
            raise ValueError("魔罩属性配置无效")
        result[name] = result.get(name, 0) + value
    return result


def bonuses(save, config):
    state = get_state(save, config)
    levels = sorted(state["levels"], reverse=True)
    masters, shared = [], dict.fromkeys(FIELDS.values(), Fraction(0))
    for number in range(1, 8):
        rows = config["mozhao_liandan"][str(number)]
        mid = max((r["id"] for r in rows.values() if levels[number - 1] >= r["cond"]), default=0)
        masters.append(mid)
        if mid:
            for name, amount in effects(rows[str(mid)]["effect"]).items():
                shared[FIELDS[name]] += amount
    result = {}
    factor = Fraction(config["global_kv"]["fairy_turn_every"]["value"])
    capacity = Fraction(config["global_kv"]["mozhao_xishou_dam"]["value"])
    percent = Fraction(config["global_kv"]["mozhao_percent_dam"]["value"])
    if not 0 < factor <= 1 or min(capacity, percent) < 0:
        raise ValueError("魔罩折算或战力配置无效")
    for index in range(7):
        values, reduction = dict(shared), Fraction(0)
        for table, level in (("mozhao_evolve", state["advanced"][index]), ("mozhao_soaring", state["soaring"][index])):
            if not level:
                continue
            for name, amount in effects(config[table][str(level)]["effect"]).items():
                if name == "skill_resilience":
                    reduction += amount
                else:
                    values[FIELDS[name.removeprefix("g_")]] += amount * (factor if name.startswith("g_") else 1)
        row = config["mozhao_break"][str(state["levels"][index])]
        if not 0 <= reduction <= 1 or not 0 <= row["percent"] <= 100 or row["value"] < 0:
            raise ValueError("魔罩吸收或技能减伤配置无效")
        result[index + 1] = {"stats": {f: int(v) for f, v in values.items()}, "skill_resilience": reduction,
                             "level": state["levels"][index], "value": row["value"], "percent": row["percent"],
                             "power": int(row["value"] * capacity + row["percent"] * percent)}
    return result, masters


def score(save, config):
    return sum(get_state(save, config)["levels"])


def rank_name(save, config):
    from . import formation
    state = get_state(save, config)
    if not any(state["levels"]):
        return "--"
    sid = max(range(1, 8), key=lambda s: (state["levels"][s - 1], -s))
    world = bytes.fromhex(save["world_state"]["1002"])
    iid = pb_get_varint(formation.records(world, 4, 1).get(sid, b""), 2)
    raw = formation.records(world, 1, 2).get(iid, b"")
    general = config["general"].get(str(pb_get_varint(raw, 1)))
    return "--" if not general else "主角" if general["actor"] == "lead" else general["name"]


def shop_price(row, now):
    from . import equip_evolve

    costs = equip_evolve.costs(row["num"])
    if set(costs) != {1001} or not 1 <= row["labal"] <= 10:
        raise ValueError("魔罩商店价格配置无效")
    weekday = ((now + 28800) // 86400 + 3) % 7 + 1
    discount = row["labal"] if str(weekday) in row["week"].split(";") else 10
    price = costs[1001] * discount // 10
    if not 0 < price < (1 << 31):
        raise ValueError("魔罩商店单价无效")
    return price


def extension(save, config):
    from . import recharge

    state = get_state(save, config)
    _, masters = bonuses(save, config)
    values = [*state["levels"], *state["advanced"], *state["soaring"]]
    # 仅此功能的高位可选bytes扩展，不改变全局Generals/Ids/SomeThings协议。
    return encode_pb_field(100, 2, recharge.ids(values)) + encode_pb_field(101, 2, recharge.ids(masters))


def prepare(opcode, save, body, config, now):
    from . import activities, development, equip_evolve, formation, recharge

    fields = list(iter_pb_fields(body))
    expected = {3730: 0, 3731: 1, 3732: 0, 3733: 0, 3734: 3, 3735: 1, 3736: 1}[opcode]
    if len(fields) != expected or any((n, w) != (1, 0) or not 0 < v < (1 << 31) for n, w, v in fields):
        raise ValueError("魔罩请求参数无效，商店购买还需当前单价")
    state = get_state(save, config)
    if opcode in (3730, 3732) and (not save.get("has_role") or save.get("role_state", {}).get("level", 0) < config["build"]["209"]["level"]):
        data = [*state["levels"], *state["advanced"], *state["soaring"]] if opcode == 3730 else bonuses(save, config)[1]
        return recharge.ids(data) + extension(save, config), [], b"", b"", 0
    if (not save.get("has_role") or save["role_state"]["level"] < config["build"]["209"]["level"]
            or save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2):
        raise ValueError("魔罩尚未解锁")
    if opcode in MUTATIONS and now < state["checked_at"]:
        raise ValueError("日期回拨，请稍后操作魔罩")
    previous, _ = bonuses(save, config)
    day = (now + 28800) // 86400
    if day > state["day"]:
        state.update(day=day, shop={})
    costs, reward, body = [], b"", None
    world = bytes.fromhex(save["world_state"]["1002"])
    slots, generals = formation.records(world, 4, 1), formation.records(world, 1, 2)
    if opcode in (3731, 3735, 3736):
        sid = fields[0][2]
        if (sid not in range(1, 8) or sid > config["role_exp"][str(save["role_state"]["level"])]["slotnum"]
                or pb_get_varint(slots.get(sid, b""), 2) not in generals):
            raise ValueError("请选择已解锁并有武将的主阵位")
        index = sid - 1
        if opcode == 3731:
            row = config["mozhao_break"][str(state["levels"][index])]
            if not row["lv_cost"] or save["role_state"]["level"] < row["battle_lv"]:
                raise ValueError("魔罩等级已满或队伍等级不足")
            costs = list(equip_evolve.costs(row["lv_cost"]).items())
            state["levels"][index] += 1
        elif opcode == 3735:
            row = config["mozhao_evolve"].get(str(state["advanced"][index] + 1))
            if (not row or save["role_state"]["level"] < config["build"]["330"]["level"]
                    or state["levels"][index] < row["mozhao_lv"] or min(state["advanced"]) < row["mozhao_evolve_lv"]):
                raise ValueError("魔罩进阶等级或全队前置不足")
            costs = list(equip_evolve.costs(row["lv_cost"]).items())
            state["advanced"][index] += 1
        else:
            row = config["mozhao_soaring"].get(str(state["soaring"][index] + 1))
            if (not row or save["role_state"]["level"] < config["build"]["462"]["level"]
                    or state["advanced"][index] < row["advanced_level"] or min(state["soaring"]) < row["all_soaring_level"]):
                raise ValueError("魔罩飞升等级或全队前置不足")
            costs = list(equip_evolve.costs(row["consume"]).items())
            state["soaring"][index] += 1
        if not costs:
            raise ValueError("魔罩养成缺少真实费用")
    elif opcode == 3734:
        iid, count, quote = (v for _, _, v in fields)
        row = config["mozhao_shop"].get(str(iid))
        if (not row or not 1 <= count <= 100 or state["shop"].get(str(iid), 0) + count > row["times"]
                or save["role_state"]["level"] < config["mozhao_shoptype"][str(row["type"])]["openlv"]):
            raise ValueError("魔罩商品、数量、等级或今日限购无效")
        price = shop_price(row, now)
        if quote != price:
            raise ValueError("魔罩商店价格已变化，请重新打开商店")
        costs = [(1001, price * count)]
        reward = activities.build_reward(save, row["reward"], config, count)
        state["shop"][str(iid)] = state["shop"].get(str(iid), 0) + count
        body = reward
    save["cover_state"] = state
    state["checked_at"] = max(now, state["checked_at"])
    current, masters = bonuses(save, config)
    update, power = b"", 0
    for sid, slot in sorted(slots.items()):
        iid = pb_get_varint(slot, 2)
        if not iid:
            continue
        old, new = previous[sid], current[sid]
        changes = {f: new["stats"][f] - old["stats"][f] for f in new["stats"]}
        fixed = new["power"] - old["power"]
        if not any(changes.values()) and not fixed:
            continue
        raw, delta = development.adjust(generals[iid], changes)
        value = (pb_get_varint(raw, 20) or 0) + fixed
        if not 0 <= value < (1 << 31):
            raise ValueError("魔罩成长后的伙伴战力超出范围")
        update += encode_pb_field(1, 2, pb_set_varint(raw, 20, value))
        power += delta + fixed
    if opcode == 3730:
        body = recharge.ids([*state["levels"], *state["advanced"], *state["soaring"]])
    elif opcode == 3732:
        body = recharge.ids(masters)
    elif opcode == 3733:
        body = recharge.ids(state["shop"].get(str(i), 0) for i in range(1, max(map(int, config["mozhao_shop"])) + 1))
    return (update if body is None else body) + extension(save, config), costs, reward, update, power
