"""本地活动协议与领取条件；奖励入账和原子保存由 player 统一完成。"""

from .protocol import encode_pb_field, iter_pb_fields, parse_ids_pb, pb_get_varint

PAGE_OPCODES = (4810, 4813, 4814, 5010, 5015, 5017, 5020, 5022, 5030, 5039)
TRANSACTION_OPCODES = (5031, 5040)
# 福利页会预加载蟠桃；空成功包使客户端将缺失状态传给原生 setString。
UNSUPPORTED_OPCODES = (2010, 2011, 4811, 4812, 5011, 5012, 5013, 5014, 5016, 5021, 5023)
OPCODES = (3610, 3611, 2410, 2411, 6517, 4600, *PAGE_OPCODES, *TRANSACTION_OPCODES)
CLAIM_OPCODES = (3611, 2411, 5040)
BEGIN_REWARDS = (80001, 80030)
HINT_IDS = (40, *range(82, 110), 542)


def get_state(save):
    state = save.setdefault("activity_state", {})
    if not isinstance(state, dict):
        raise ValueError("activity_state 必须是对象")
    for key, supported in (("begin7day_claimed", BEGIN_REWARDS), ("liveness_claimed", (16,)),
                           ("consume_claimed", range(1, 7))):
        values = state.setdefault(key, [])
        if (not isinstance(values, list) or any(type(v) is not int or v not in supported for v in values)
                or len(values) != len(set(values))):
            raise ValueError("活动领取存档无效")
    count = state.setdefault("strengthen_count", 0)
    if type(count) is not int or not 0 <= count < (1 << 31):
        raise ValueError("活动强化进度无效")
    spent = state.setdefault("gold_spent", 0)
    purchases = state.setdefault("discount_bought", {})
    if type(spent) is not int or not 0 <= spent < (1 << 31):
        raise ValueError("活动消费进度无效")
    if (not isinstance(purchases, dict)
            or any(key not in {str(i) for i in range(1, 14)} or type(value) is not int
                   or not 0 <= value < (1 << 31) for key, value in purchases.items())):
        raise ValueError("活动限购存档无效")
    return state


def _ids(values):
    return b"".join(encode_pb_field(1, 0, value) for value in values)


def _equipment(save):
    equipment = {}
    for field, wire, value in iter_pb_fields(bytes.fromhex(save["world_state"]["1002"])):
        if field == 2 and wire == 2:
            ids = parse_ids_pb(value)
            equipment[ids[0]] = ids
    return equipment


def build_reward(save, specification, config, quantity=1):
    coin, gold, props, equipment = 0, 0, [], []
    # 本地装备使用独立 iid 区间，避免与尚未回放的录制掉落撞号。
    iid = max([1000000, *_equipment(save)])
    for entry in specification.split(";"):
        if not entry:
            continue
        cid, count = map(int, entry.split(","))
        count *= quantity
        if not 0 < count < (1 << 31):
            raise ValueError("活动奖励数量无效")
        if cid == 1000:
            coin += count
        elif cid == 1001:
            gold += count
        elif str(cid) in config["props"] or str(cid) in config["general_fragment"]:
            record = encode_pb_field(1, 0, cid) + encode_pb_field(2, 0, count)
            props.append(encode_pb_field(1, 2, record))
        elif str(cid) in config["equip"]:
            for _ in range(count):
                iid += 1
                if iid >= (1 << 31):
                    raise ValueError("本地装备 iid 已耗尽")
                equipment.append(encode_pb_field(6, 2, _ids([iid, cid, 1] + [0] * 10)))
        else:
            raise ValueError(f"不支持的活动奖励类型: {cid}")
    return ((encode_pb_field(1, 0, coin) if coin else b"")
            + (encode_pb_field(2, 0, gold) if gold else b"")
            + encode_pb_field(5, 2, b"".join(props)) + b"".join(equipment)
            + encode_pb_field(7, 2, b"") + encode_pb_field(10, 2, b""))


def first_period(save, config, activity_id, now):
    """首期开服活动按 UTC+8 自然日计算，与客户端 activity_time 倒计时一致。"""
    opened = pb_get_varint(bytes.fromhex(save.get("role_snapshot", "")), 22)
    if opened is None:
        opened = int(save["created_at"])
    row = config["activity_time"][str(activity_id)]
    start_day = (opened + 8 * 3600) // 86400 + row["days_later"]
    day = (now + 8 * 3600) // 86400 - start_day + 1
    end_at = (start_day + row["continued_time_1"]) * 86400 - 8 * 3600
    # shortcut: 仅实现开服首期；后续轮次需同时实现活动轮换和历史归档，不能重置旧领取记录。
    return max(0, day), max(0, end_at - now)


def record_gold_spend(save, amount, config, now):
    day, remaining = first_period(save, config, 91, now)
    if save.get("has_role") and day > 0 and remaining:
        state = get_state(save)
        if state["gold_spent"] + amount >= (1 << 31):
            raise ValueError("活动消费进度超出范围")
        state["gold_spent"] += amount


def prepare_page(opcode, save, config, now):
    state = get_state(save)
    if opcode == 4810:
        # 空拍卖行无竞价记录；不复用抓包的两秒刷新计时，避免无物品时反复轮询。
        return _ids([2, 0])
    if opcode in (4813, 4814):
        return b""
    if opcode in (5010, 5015, 5017):
        day, _ = first_period(save, config, 82, now)
        if opcode == 5010:
            return _ids([1, day] + [0] * (5 + len(config["goddown_contribution_reward_1"])))
        if opcode == 5015:
            return _ids([1, day, 0] + [0] * max(map(int, config["goddown_exchange_1"])))
        return (encode_pb_field(1, 2, encode_pb_field(1, 0, 0) + encode_pb_field(2, 2, _ids([1, day, 0])))
                + encode_pb_field(1, 2, encode_pb_field(1, 0, 1) + encode_pb_field(2, 2, b"")))
    if opcode in (5020, 5022):
        day, _ = first_period(save, config, 80, now)
        return _ids([1, day] + [0] * (5 if opcode == 5020 else max(map(int, config["new_generals_exchange_1"]))))
    if opcode == 5030:
        day, remaining = first_period(save, config, 85, now)
        values = [1, day]
        for item_id in range(1, max(map(int, config["treasure_discount_1"])) + 1):
            row = config["treasure_discount_1"][str(item_id)]
            used = state["discount_bought"].get(str(item_id), 0)
            values.extend((used, int(day > 0 and remaining > 0 and used < row["count"])))
        return _ids(values)
    day, remaining = first_period(save, config, 91, now)
    values = [1, day, remaining, state["gold_spent"]]
    for reward_id in range(1, max(map(int, config["consumegift_reward_1"])) + 1):
        row = config["consumegift_reward_1"][str(reward_id)]
        values.append(2 if reward_id in state["consume_claimed"] else
                      int(day > 0 and remaining > 0 and state["gold_spent"] >= row["gold"]))
    return _ids(values)


def record_strengthening(save, reward, config):
    equipment = _equipment(save)
    increase = 0
    for field, wire, value in iter_pb_fields(reward):
        if field == 6 and wire == 2:
            ids = parse_ids_pb(value)
            if len(ids) < 3:
                raise ValueError("强化装备数据无效")
            previous = equipment.get(ids[0], [ids[0], ids[1], 1])
            increase += max(0, ids[2] - previous[2])
    state = get_state(save)
    limit = config["liveness"]["16"]["num"]
    state["strengthen_count"] = min(limit, state["strengthen_count"] + increase)


def get_reward_statuses(save, config):
    state = get_state(save)
    eligible = {80001} if save.get("has_role") else set()
    map_id, point_id = map(int, config["begin7day_task"]["80030"]["target"].split(","))
    copies = bytes.fromhex(save["world_state"]["1300"])
    for n, w, row in iter_pb_fields(copies):
        if n == 1 and w == 2 and pb_get_varint(row, 1) == map_id:
            if save.get("has_role") and any(f == 7 and t == 2 and pb_get_varint(point, 1) == point_id
                                          and (pb_get_varint(point, 3) or 0) > 0 for f, t, point in iter_pb_fields(row)):
                eligible.add(80030)
    statuses = {rid: 2 if rid in state["begin7day_claimed"] else 1 if rid in eligible else 0 for rid in BEGIN_REWARDS}
    limit = config["liveness"]["16"]["num"]
    task_status = 2 if 16 in state["liveness_claimed"] else int(bool(save.get("has_role") and state["strengthen_count"] >= limit))
    return statuses, task_status


def get_hints(save, config):
    statuses, task_status = get_reward_statuses(save, config)
    # shortcut: 仅提示已实现奖励，后续天数、付费页和周宝箱待相应业务开放。
    hints = dict.fromkeys(HINT_IDS, 0)
    hints.update({40: int(task_status == 1), 82: int(statuses[80001] == 1), 84: int(statuses[80030] == 1)})
    return hints


def parse_hint_ids(body):
    try:
        fields = list(iter_pb_fields(body))
    except ValueError as e:
        raise ValueError("红点查询格式错误") from e
    if any(n != 1 or w != 0 or not 0 < value < (1 << 31) for n, w, value in fields):
        raise ValueError("红点查询格式错误")
    return [value for _, _, value in fields]


def prepare_hints(body, save, request_body, config):
    requested = parse_hint_ids(request_body)
    hints = get_hints(save, config)
    if requested:
        return _ids(hints[mid] for mid in requested) if all(mid in hints for mid in requested) else body
    out, seen = bytearray(), set()
    for field, wire, value in iter_pb_fields(body):
        if field == 1 and wire == 0 and value // 100 in hints:
            mid = value // 100
            value = mid * 100 + hints[mid]
            seen.add(mid)
        out.extend(encode_pb_field(field, wire, value))
    out.extend(_ids(mid * 100 + status for mid, status in hints.items() if mid not in seen))
    return bytes(out)


def prepare_response(opcode, save, request_body, config, now):
    try:
        fields = list(iter_pb_fields(request_body))
    except ValueError as e:
        raise ValueError("活动请求格式错误") from e
    if any(n != 1 or w != 0 or not 0 < value < (1 << 31) for n, w, value in fields):
        raise ValueError("活动请求格式错误")
    ids = [value for _, _, value in fields]
    expected = 2 if opcode == 5031 else 1 if opcode in CLAIM_OPCODES else 0
    if len(ids) != expected:
        raise ValueError("活动请求格式错误")
    if opcode in PAGE_OPCODES:
        return prepare_page(opcode, save, config, now)
    if opcode == 4600:
        # shortcut: 尚未开放兑换；接入 4601 时需持久化次数和时装持有状态。
        return _ids([0, 0] * max(row["id"] for row in config["mid_autumn_exchange"].values()))
    state = get_state(save)
    if opcode in TRANSACTION_OPCODES:
        if not save.get("has_role"):
            raise ValueError("活动尚未解锁")
        day, remaining = first_period(save, config, 85 if opcode == 5031 else 91, now)
        if not day or not remaining:
            raise ValueError("首期活动尚未开始或已结束")
        if opcode == 5031:
            item_id, quantity = ids
            row = config["treasure_discount_1"].get(str(item_id))
            used = state["discount_bought"].get(str(item_id), 0)
            if not row or row["astrict"] or used + quantity > row["count"]:
                raise ValueError("珍品不存在或已超过限购次数")
            reward = build_reward(save, row["target"], config, quantity)
            state["discount_bought"][str(item_id)] = used + quantity
            return reward
        reward_id = ids[0]
        row = config["consumegift_reward_1"].get(str(reward_id))
        if not row or state["gold_spent"] < row["gold"]:
            raise ValueError("消费奖励条件未达成")
        if reward_id in state["consume_claimed"]:
            raise ValueError("消费奖励已领取")
        reward = build_reward(save, row["reward"], config)
        state["consume_claimed"].append(reward_id)
        return reward
    statuses, task_status = get_reward_statuses(save, config)
    limit = config["liveness"]["16"]["num"]
    score = sum(config["liveness"][str(task)]["point"] for task in state["liveness_claimed"])

    if opcode == 3610:
        # shortcut: 仅覆盖抓包首日两项奖励；跨天与其他活动条件待对应业务和重置规则接入。
        flags = [statuses.get(80000 + i, 0) for i in range(1, max(map(int, config["begin7day_task"])) - 80000 + 1)]
        level = save.get("role_state", {}).get("level", save.get("level", 1))
        groups = ([1], flags, [level] + [0] * 10, [0] * 10)
        return b"".join(encode_pb_field(1, 2, encode_pb_field(1, 0, mid) + encode_pb_field(2, 2, _ids(values)))
                        for mid, values in enumerate(groups))
    if opcode == 2410:
        # shortcut: 当前仅统计已录制装备强化任务 16，其他任务/日重置待业务接入。
        # 协议按任务 ID 下标排列，配置存在缺号。
        size = max(map(int, config["liveness"]))
        flags, counts = [0] * size, [0] * size
        flags[15], counts[15] = task_status, min(limit, state["strengthen_count"])
        return _ids(flags + counts) + b"".join(encode_pb_field(2, 0, 0) for _ in config["liveness_reward"])
    if opcode == 6517:
        return _ids([score] + [0] * len(config["week_liveness_reward"]))
    if not save.get("has_role"):
        raise ValueError("活动奖励未解锁或不支持")
    if opcode == 3611:
        reward_id = ids[0]
        if reward_id not in statuses or statuses[reward_id] == 0:
            raise ValueError("活动奖励未解锁或不支持")
        if statuses[reward_id] == 2:
            raise ValueError("活动奖励已领取")
        reward = build_reward(save, config["begin7day_task"][str(reward_id)]["rewards"], config)
        state["begin7day_claimed"].append(reward_id)
        return reward
    if ids[0] != 116 or task_status == 0:
        raise ValueError("活动奖励未解锁或不支持")
    if task_status == 2:
        raise ValueError("活动奖励已领取")
    reward = build_reward(save, config["liveness"]["16"]["reward"], config)
    state["liveness_claimed"].append(16)
    return reward
