"""首日开服奖励与已录制强化任务；奖励入账和原子保存由 player 统一完成。"""

from .protocol import encode_pb_field, iter_pb_fields, parse_ids_pb, pb_get_varint

OPCODES = (3610, 3611, 2410, 2411, 6517)
CLAIM_OPCODES = (3611, 2411)
BEGIN_REWARDS = (80001, 80030)


def get_state(save):
    state = save.setdefault("activity_state", {})
    if not isinstance(state, dict):
        raise ValueError("activity_state 必须是对象")
    for key, supported in (("begin7day_claimed", BEGIN_REWARDS), ("liveness_claimed", (16,))):
        values = state.setdefault(key, [])
        if (not isinstance(values, list) or any(type(v) is not int or v not in supported for v in values)
                or len(values) != len(set(values))):
            raise ValueError("活动领取存档无效")
    count = state.setdefault("strengthen_count", 0)
    if type(count) is not int or not 0 <= count < (1 << 31):
        raise ValueError("活动强化进度无效")
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


def _reward_body(save, specification, config):
    coin, gold, props, equipment = 0, 0, [], []
    # 本地装备使用独立 iid 区间，避免与尚未回放的录制掉落撞号。
    iid = max([1000000, *_equipment(save)])
    for entry in specification.split(";"):
        if not entry:
            continue
        cid, count = map(int, entry.split(","))
        if not 0 < count < (1 << 31):
            raise ValueError("活动奖励数量无效")
        if cid == 1000:
            coin += count
        elif cid == 1001:
            gold += count
        elif str(cid) in config["props"]:
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


def prepare_response(opcode, save, request_body, config):
    try:
        fields = list(iter_pb_fields(request_body))
    except ValueError as e:
        raise ValueError("活动请求格式错误") from e
    if any(n != 1 or w != 0 or not 0 < value < (1 << 31) for n, w, value in fields):
        raise ValueError("活动请求格式错误")
    ids = [value for _, _, value in fields]
    if (opcode in CLAIM_OPCODES and len(ids) != 1) or (opcode not in CLAIM_OPCODES and ids):
        raise ValueError("活动请求格式错误")
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
        reward = _reward_body(save, config["begin7day_task"][str(reward_id)]["rewards"], config)
        state["begin7day_claimed"].append(reward_id)
        return reward
    if ids[0] != 116 or task_status == 0:
        raise ValueError("活动奖励未解锁或不支持")
    if task_status == 2:
        raise ValueError("活动奖励已领取")
    reward = _reward_body(save, config["liveness"]["16"]["reward"], config)
    state["liveness_claimed"].append(16)
    return reward
