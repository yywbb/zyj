"""本地活动协议与领取条件；奖励入账和原子保存由 player 统一完成。"""

import copy

from .protocol import encode_pb_field, iter_pb_fields, parse_ids_pb, pb_get_varint

PAGE_OPCODES = (4016, 4810, 4813, 4814, 5010, 5015, 5017, 5020, 5022, 5030, 5039)
TRANSACTION_OPCODES = (5031, 5040)
UNSUPPORTED_OPCODES = (2081, 2082, 7092, 4017, 4811, 4812, 5011, 5012, 5013, 5014, 5016, 5021, 5023)
OPCODES = (3610, 3611, 2410, 2411, 6517, 4600, *PAGE_OPCODES, *TRANSACTION_OPCODES)
CLAIM_OPCODES = (3611, 2411, 5040)
BEGIN_REWARDS = (*range(80001, 80015), 80030)
LIVENESS_TASKS = (1, 3, 7, 8, 9, 11, 14, 16, 17, 22, 23, 25, 37, 48)
HINT_IDS = (40, *range(82, 110), 542, 30, 32, 36, 132, 245, 252, 429, 551, 44)


def get_state(save):
    state = save.setdefault("activity_state", {})
    if not isinstance(state, dict):
        raise ValueError("activity_state 必须是对象")
    for key, supported in (("begin7day_claimed", BEGIN_REWARDS), ("liveness_claimed", tuple(t for t in LIVENESS_TASKS if t != 7)),
                           ("liveness_boxes", range(1, 6)),
                           ("consume_claimed", range(1, 7))):
        values = state.setdefault(key, [])
        if (not isinstance(values, list) or any(type(v) is not int or v not in supported for v in values)
                or len(values) != len(set(values))):
            raise ValueError("活动领取存档无效")
    count = state.setdefault("strengthen_count", 0)
    if type(count) is not int or not 0 <= count < (1 << 31):
        raise ValueError("活动强化进度无效")
    for key in ("liveness_day", "liveness_week", "liveness_week_score"):
        value = state.setdefault(key, 0)
        if type(value) is not int or not 0 <= value < (1 << 31):
            raise ValueError("日常任务周期或积分无效")
    counts = state.setdefault("liveness_counts", {})
    if (not isinstance(counts, dict) or any(key not in {str(t) for t in LIVENESS_TASKS if t not in (7, 16)}
            or type(value) is not int or not 0 <= value < (1 << 31) for key, value in counts.items())):
        raise ValueError("日常任务进度无效")
    # 兼容旧档：只承接已记录的本地充值，不从 VIP、元宝或官方录制推算。
    rmb = state.setdefault("begin7day_rmb", save.get("recharge_state", {}).get("rmb", 0))
    if type(rmb) is not int or not 0 <= rmb < (1 << 31):
        raise ValueError("开服累计充值进度无效")
    spent = state.setdefault("gold_spent", 0)
    purchases = state.setdefault("discount_bought", {})
    if type(spent) is not int or not 0 <= spent < (1 << 31):
        raise ValueError("活动消费进度无效")
    if (not isinstance(purchases, dict)
            or any(key not in {str(i) for i in range(1, 14)} or type(value) is not int
                   or not 0 <= value < (1 << 31) for key, value in purchases.items())):
        raise ValueError("活动限购存档无效")
    return state


def settle_liveness(save, config, now):
    state = get_state(save)
    if not save.get("has_role"):
        return state
    day = (now + 28800) // 86400
    week = (day + 3) // 7
    if not state["liveness_day"]:
        # 旧强化记录无日期，首次接入保留进度和已领标记，不能再发一次奖励。
        state.update(liveness_day=day, liveness_week=week,
                     liveness_week_score=sum(config["liveness"][str(t)]["point"] for t in state["liveness_claimed"]))
    if day > state["liveness_day"]:
        state.update(liveness_day=day, liveness_counts={}, liveness_claimed=[], liveness_boxes=[], strengthen_count=0)
    if week > state["liveness_week"]:
        state.update(liveness_week=week, liveness_week_score=0)
    return state


def record_liveness(save, task, amount, config, now):
    if not save.get("has_role") or not amount:
        return
    state = settle_liveness(save, config, now)
    limit = config["liveness"][str(task)]["num"]
    if task == 16:
        state["strengthen_count"] = min(limit, state["strengthen_count"] + amount)
    else:
        state["liveness_counts"][str(task)] = min(limit, state["liveness_counts"].get(str(task), 0) + amount)


def liveness_statuses(save, config, now):
    from . import welfare

    # 提示和管理页只投影跨日状态，不能修改被读取的角色。
    projected = dict(save, activity_state=copy.deepcopy(save.get("activity_state", {})))
    state = settle_liveness(projected, config, now)
    counts = {t: min(config["liveness"][str(t)]["num"], state["liveness_counts"].get(str(t), 0)) for t in LIVENESS_TASKS}
    counts[16] = min(config["liveness"]["16"]["num"], state["strengthen_count"])
    flags = {t: 2 if t in state["liveness_claimed"] else
             int(bool(save.get("has_role") and counts[t] >= config["liveness"][str(t)]["num"])) for t in LIVENESS_TASKS}
    flags[7] = welfare.sign_task_status(projected, now)
    counts[7] = int(flags[7] > 0)
    score = sum(config["liveness"][str(t)]["point"] for t, status in flags.items() if status == 2)
    boxes = [2 if i in state["liveness_boxes"] else int(bool(save.get("has_role") and score >= config["liveness_reward"][str(i)]["point"]))
             for i in range(1, len(config["liveness_reward"]) + 1)]
    return flags, counts, boxes


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
    coin, gold, stamina, energy, props, equipment = 0, 0, 0, 0, [], []
    souls, gems = [], []
    roster = list(iter_pb_fields(bytes.fromhex(save["world_state"]["1002"])))
    gem_iid = max([4000000, *(pb_get_varint(v, 1) for n, w, v in roster if n == 7 and w == 2)])
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
        elif cid == 1002:
            stamina += count
        elif cid == 1003:
            energy += count
        elif (cid in (1004, 1005, 1008, 1019, 1025, 70000) or str(cid) in config["props"] or str(cid) in config["general_fragment"]
              or str(cid) in config["treasure2_fragment"] or str(cid) in config["equip_fragment"]
               or str(cid) in config["pet3_fragment"] or str(cid) in config["redl_awake_item"] or str(cid) in config["fashioncoat"]
               or str(cid) in config["trump_gem"] or str(cid) in config["token"] or str(cid) in config["token_fragment"]):
            record = encode_pb_field(1, 0, cid) + encode_pb_field(2, 0, count)
            props.append(encode_pb_field(1, 2, record))
        elif str(cid) in config["equip"]:
            for _ in range(count):
                iid += 1
                if iid >= (1 << 31):
                    raise ValueError("本地装备 iid 已耗尽")
                equipment.append(encode_pb_field(6, 2, _ids([iid, cid, 1] + [0] * 10)))
        elif str(cid) in config["soul"]:
            from .soul import allocate
            for _ in range(count):
                soul_iid = allocate(save)
                souls.append(encode_pb_field(1, 2, b"".join(encode_pb_field(n, 0, v)
                             for n, v in ((1, soul_iid), (2, cid), (3, 1)))))
        elif str(cid) in config["sigil"]:
            for _ in range(count):
                gem_iid += 1
                if gem_iid >= (1 << 31):
                    raise ValueError("本地魔符 iid 已耗尽")
                gems.append(encode_pb_field(11, 2, _ids([gem_iid, cid, config["sigil"][str(cid)]["level"], 0])))
        else:
            raise ValueError(f"不支持的活动奖励类型: {cid}")
    return ((encode_pb_field(1, 0, coin) if coin else b"")
            + (encode_pb_field(2, 0, gold) if gold else b"")
            + (encode_pb_field(3, 0, stamina) if stamina else b"")
            + (encode_pb_field(4, 0, energy) if energy else b"")
            + encode_pb_field(5, 2, b"".join(props)) + b"".join(equipment)
            + encode_pb_field(7, 2, b"".join(souls)) + b"".join(gems) + encode_pb_field(10, 2, b""))


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
    record_liveness(save, 14, amount, config, now)
    day, remaining = first_period(save, config, 91, now)
    if save.get("has_role") and day > 0 and remaining:
        state = get_state(save)
        if state["gold_spent"] + amount >= (1 << 31):
            raise ValueError("活动消费进度超出范围")
        state["gold_spent"] += amount


def prepare_page(opcode, save, config, now):
    state = get_state(save)
    if opcode == 4016:
        # 兑换尚未开放，没有本地已兑换次数；原生页面要求五组完整的逐项计数。
        return b"".join(encode_pb_field(1, 2, encode_pb_field(1, 0, group) + encode_pb_field(2, 2,
                        _ids([0] * max(map(int, config["exchange_shop"].get(str(group), {})), default=0)))) for group in range(1, 6))
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


def record_strengthening(save, reward, config, now):
    equipment = _equipment(save)
    increase = 0
    for field, wire, value in iter_pb_fields(reward):
        if field == 6 and wire == 2:
            ids = parse_ids_pb(value)
            if len(ids) < 3:
                raise ValueError("强化装备数据无效")
            previous = equipment.get(ids[0], [ids[0], ids[1], 1])
            increase += max(0, ids[2] - previous[2])
    critical = sum(sum(parse_ids_pb(value)) for field, wire, value in iter_pb_fields(reward) if (field, wire) == (12, 2))
    if not 0 <= critical <= increase:
        raise ValueError("强化暴击次数无效")
    record_liveness(save, 16, increase - critical, config, now)


def begin7day_day(save, now):
    # 本地规则：建号日为第 1 天（UTC+8），不使用录制中的旧开服时间。
    return max(0, (now + 8 * 3600) // 86400 - (int(save["created_at"]) + 8 * 3600) // 86400 + 1)


def get_reward_statuses(save, config, now):
    state = get_state(save)
    day = begin7day_day(save, now)
    active = save.get("has_role") and 1 <= day <= 10
    eligible = set()
    for pages in config["begin7day"].values():
        page = pages["1"]
        if active and page["day"] <= day:
            eligible.add(page["task1"])
            task = config["begin7day_task"][str(page["task2"])]
            if state["begin7day_rmb"] >= int(task["target"]):
                eligible.add(task["id"])
    map_id, point_id = map(int, config["begin7day_task"]["80030"]["target"].split(","))
    copies = bytes.fromhex(save["world_state"]["1300"])
    for n, w, row in iter_pb_fields(copies):
        if n == 1 and w == 2 and pb_get_varint(row, 1) == map_id:
            if active and any(f == 7 and t == 2 and pb_get_varint(point, 1) == point_id
                                          and (pb_get_varint(point, 3) or 0) > 0 for f, t, point in iter_pb_fields(row)):
                eligible.add(80030)
    statuses = {rid: 2 if rid in state["begin7day_claimed"] else 1 if rid in eligible else 0 for rid in BEGIN_REWARDS}
    flags, _, _ = liveness_statuses(save, config, now)
    return statuses, flags[16]


def get_hints(save, config, now):
    from . import achievements, welfare

    statuses, _ = get_reward_statuses(save, config, now)
    flags, _, boxes = liveness_statuses(save, config, now)
    # shortcut: 未开放玩法、超值付费页和周宝箱待相应业务开放。
    hints = dict.fromkeys(HINT_IDS, 0)
    hints[84] = int(statuses[80030] == 1)
    hints.update(welfare.get_hints(save, config, now))
    hints[40] = int(1 in flags.values() or 1 in boxes)
    hints[44] = int(bool(save.get("has_role")) and any(status == 1 for status, _ in achievements.statuses(save, config).values()))
    for pages in config["begin7day"].values():
        page = pages["1"]
        hints[82 + (page["day"] - 1) * 4] = int(any(statuses.get(page[f"task{i}"]) == 1 for i in (1, 2)))
    return hints


def parse_hint_ids(body):
    try:
        fields = list(iter_pb_fields(body))
    except ValueError as e:
        raise ValueError("红点查询格式错误") from e
    if any(n != 1 or w != 0 or not 0 < value < (1 << 31) for n, w, value in fields):
        raise ValueError("红点查询格式错误")
    return [value for _, _, value in fields]


def prepare_hints(body, save, request_body, config, now):
    requested = parse_hint_ids(request_body)
    hints = get_hints(save, config, now)
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
    from . import welfare

    try:
        fields = list(iter_pb_fields(request_body))
    except ValueError as e:
        raise ValueError("活动请求格式错误") from e
    if any(n != 1 or w != 0 or not 0 < value < (1 << 31) for n, w, value in fields):
        raise ValueError("活动请求格式错误")
    ids = [value for _, _, value in fields]
    expected = 2 if opcode == 5031 else 1 if opcode in CLAIM_OPCODES else 0
    if opcode == 3611:
        if not 1 <= len(ids) <= len(BEGIN_REWARDS) or len(ids) != len(set(ids)):
            raise ValueError("活动请求格式错误")
    elif len(ids) != expected and not (opcode == 2411 and not ids):
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
    statuses, _ = get_reward_statuses(save, config, now)
    if opcode in (2410, 2411, 6517):
        settle_liveness(save, config, now)
    task_statuses, task_counts, boxes = liveness_statuses(save, config, now)
    benefits = welfare.get_state(save)

    if opcode == 3610:
        flags = [statuses.get(80000 + i, 0) for i in range(1, max(map(int, config["begin7day_task"])) - 80000 + 1)]
        groups = ([begin7day_day(save, now)], flags, [state["begin7day_rmb"]] + [0] * 10, [0] * 10)
        return b"".join(encode_pb_field(1, 2, encode_pb_field(1, 0, mid) + encode_pb_field(2, 2, _ids(values)))
                        for mid, values in enumerate(groups))
    if opcode == 2410:
        # 协议按任务 ID 下标排列，配置存在缺号。
        size = max(map(int, config["liveness"]))
        flags, counts = [0] * size, [0] * size
        for task in LIVENESS_TASKS:
            flags[task - 1], counts[task - 1] = task_statuses[task], task_counts[task]
        return _ids(flags + counts) + b"".join(encode_pb_field(2, 0, status) for status in boxes)
    if opcode == 6517:
        score = state["liveness_week_score"] + benefits["sign_week_score"]
        if score >= (1 << 31):
            raise ValueError("日常任务积分超出范围")
        return _ids([score] + [0] * len(config["week_liveness_reward"]))
    if not save.get("has_role"):
        raise ValueError("活动奖励未解锁或不支持")
    if opcode == 3611:
        from . import recruit

        if any(statuses.get(reward_id, 0) == 0 for reward_id in ids):
            raise ValueError("活动奖励未解锁或不支持")
        if any(statuses[reward_id] == 2 for reward_id in ids):
            raise ValueError("活动奖励已领取")
        gets = [tuple(map(int, entry.split(","))) for reward_id in ids
                for entry in config["begin7day_task"][str(reward_id)]["rewards"].split(";") if entry]
        reward = recruit.build_reward(save, gets, config)
        state["begin7day_claimed"].extend(ids)
        return reward
    if ids and ids[0] <= 100:
        box = ids[0]
        if box > len(boxes) or boxes[box - 1] == 0:
            raise ValueError("活动奖励未解锁或不支持")
        if boxes[box - 1] == 2:
            raise ValueError("活动奖励已领取")
        # shortcut: 已接任务最多65分，仅可达25/50分基础宝箱；高档附奖随更多玩法接入。
        reward = build_reward(save, config["liveness_reward"][str(box)]["reward"], config)
        state["liveness_boxes"].append(box)
        return reward
    eligible = [task for task, status in task_statuses.items() if status == 1]
    requested = [ids[0] - 100] if ids else eligible
    if not requested or any(task not in eligible for task in requested):
        if (ids and task_statuses.get(ids[0] - 100) == 2) or (not ids and 2 in task_statuses.values()):
            raise ValueError("活动奖励已领取")
        raise ValueError("活动奖励未解锁或不支持")
    reward = build_reward(save, ";".join(config["liveness"][str(task)]["reward"] for task in requested), config)
    if 7 in requested:
        benefits["sign_task_claimed"] = True
        benefits["sign_week_score"] += config["liveness"]["7"]["point"]
    gained = sum(config["liveness"][str(task)]["point"] for task in requested if task != 7)
    if state["liveness_week_score"] + benefits["sign_week_score"] + gained >= (1 << 31):
        raise ValueError("日常任务积分超出范围")
    state["liveness_week_score"] += gained
    state["liveness_claimed"].extend(task for task in requested if task != 7)
    return reward
