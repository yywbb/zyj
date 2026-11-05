"""游戏助手：只编排已接通的真实玩法；报价不执行，确认后单笔角色事务。"""

import copy
import hashlib
import random

from . import activity_copy, arena, friend_copy, mieshendian, nightclub, online_rewards, penglai, recharge, single_boss, watchstar, welfare
from .penglai import comb
from .protocol import encode_pb_field, iter_pb_fields, pack_frame, pb_get_varint


SUPPORTED = {(2, aid) for aid in activity_copy.COPIES} | {(3, aid) for aid in (1, 2, 3, 9, 10, 12)}


def require_open(save, config):
    if (not save.get("has_role") or save["role_state"]["level"] < config["build"]["566"]["level"]
            or save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2):
        raise ValueError("游戏助手需要50级并完成新手引导")


def receipt(save):
    value = save.get("game_helper_receipt")
    if "game_helper_receipt" in save and (not isinstance(value, dict) or set(value) != {"token", "request"}
            or type(value["token"]) is not int or not 0 < value["token"] < (1 << 31)
            or not isinstance(value["request"], str) or len(value["request"]) != 64
            or any(c not in "0123456789abcdef" for c in value["request"])):
        raise ValueError("游戏助手执行收据无效")
    return value


def ids(raw):
    fields = list(iter_pb_fields(raw))
    if any((n, w) != (1, 0) or not 0 <= v < (1 << 31) for n, w, v in fields):
        raise ValueError("游戏助手整数参数无效")
    return [v for _, _, v in fields]


def parse(body, config):
    if len(body) > 8192:
        raise ValueError("游戏助手请求过大")
    messages = {}
    for n, w, raw in iter_pb_fields(body):
        if (n, w) != (1, 2):
            raise ValueError("游戏助手只接受业务消息")
        fields = list(iter_pb_fields(raw))
        keys = [(n, w) for n, w, _ in fields]
        if sorted(keys) not in ([(1, 0)], [(1, 0), (2, 2)]):
            raise ValueError("游戏助手业务消息格式无效")
        mid = next(v for n, _, v in fields if n == 1)
        if mid not in (1, 2, 3) or mid in messages:
            raise ValueError("游戏助手业务消息重复或未知")
        messages[mid] = ids(next((v for n, _, v in fields if n == 2), b""))
    if not {1, 2}.issubset(messages) or not 0 < len(messages[1]) <= 40 * 7 or len(messages[1]) % 7:
        raise ValueError("请选择有效的助手项目")
    rows = [tuple(messages[1][i:i+7]) for i in range(0, len(messages[1]), 7)]
    seen = set()
    for page, item, *params in rows:
        key = (page, item)
        if key in seen or str(item) not in config["game_helper"].get(str(page), {}):
            raise ValueError("助手项目重复或不存在")
        seen.add(key)
        if key in SUPPORTED:
            used = 2 if key in ((3, 10), (3, 12)) else 1
            if any(params[used:]) or params[0] > 1000:
                raise ValueError("助手项目含多余参数或执行次数过大")
    extras = messages[2]
    if (len(extras) > 10 or len(extras) != len(set(extras)) or any(v == 0 for v in extras)
            or extras and (3, 8) not in seen):
        raise ValueError("助手银座伙伴参数无效")
    token = messages.get(3)
    if token is not None and (len(token) != 1 or token[0] == 0):
        raise ValueError("助手确认报价无效")
    canonical = comb([(1, recharge.ids(messages[1])), (2, recharge.ids(extras))])
    return rows, token[0] if token else None, hashlib.sha256(canonical).hexdigest()


def query(save, config, now):
    require_open(save, config)
    # 所有日切/旧档补字段只在副本投影；打开助手绝不结算奖励或写入角色。
    save = copy.deepcopy(save)
    challenges = activity_copy.settle(save, config, now)
    available = activity_copy.open_copies(challenges, config)
    challenge_rows = []
    for aid in available:
        row = challenges["copies"][str(aid)]
        challenge_rows.extend((aid, row["used"], row["cleared"]))
    activity_rows = {i: [i, 0, 0, 0, 0, 0, 0, 0] for i in range(1, 16)}
    state = mieshendian.settle(save, config, now)
    activity_rows[1][1:5] = [state["resets"], state["maxfloor"],
                            max(0, state["sweep"]["end_at"]-now) if state["sweep"] else 0, state["floor"]]
    watchstar.prepare(2062, save, b"", config, now, 0)
    vip = config["vip"][str(save["role_state"]["vip"])]
    activity_rows[2][1] = max(0, vip["c_watchstar_change"]-save["watchstar_state"]["changes"])
    penglai.prepare(2120, save, b"", config, now, 0)
    activity_rows[3][1] = save["penglai_state"]["count"]
    state = nightclub.get_state(save, config)
    statuses, partners = [], []
    for floor in range(1, 11):
        job = state["jobs"].get(str(floor))
        statuses.append(2 if job and now >= job["end"] else 3 if job else int(floor in state["cleared"]))
        partners.append(job["iid"] if job else 0)
    # 十个3会超过int32，原生Ids是int64；此处直接编码，不走请求整数校验。
    activity_rows[8][1] = int("".join(map(str, statuses)))
    arena.daily_reward(save, config, now)  # 只投影日切，故意不应用旧排名奖励。
    activity_rows[9][1] = arena.remaining(save, save["arena_state"], config)
    state = friend_copy.settle(save, config, now)
    activity_rows[10][1:3] = [state["cleared"] if state["cleared"] > 43000 else 0,
                             int(config["global_kv"]["friendcopy_challenge"]["value"])-state["attempts"]]
    state = single_boss.settle(save, config, now)
    kind = single_boss.boss_type(state, config)
    cleared = state["cleared"][str(kind)]
    activity_rows[12][1:3] = [single_boss.levels(config, kind)[cleared-1]["id"] if cleared else 0,
                             config["vip"]["0"]["personalboss_times"]+state["bought"]-state["used"]]
    return comb([(2, recharge.ids(challenge_rows)), (3, recharge.ids([v for row in activity_rows.values() for v in row])),
                 (4, recharge.ids([0, 0, 0])), (10, recharge.ids(partners)),
                 (20, recharge.ids([v for row in sorted(SUPPORTED) for v in row]))])


def sweep_options(value):
    text = str(value)
    if len(text) < 2 or text[0] != "1" or text[-1] not in "09":
        raise ValueError("灭神殿助手设置无效")
    count = int(text[1:-1] or "0")
    if count > 20 or count and text[1] == "0":
        raise ValueError("灭神殿助手重置设置无效")
    if count > 1 and text[-1] != "9":
        raise ValueError("多次重置必须勾选立即完成")
    return count, text[-1] == "9"


def estimate(rows, save, config, now):
    save = copy.deepcopy(save)
    vip = config["vip"][str(save["role_state"]["vip"])]
    gold, active = 0, 0
    for page, item, p1, p2, p3, p4, p5 in rows:
        if (page, item) not in SUPPORTED or save["role_state"]["level"] < config["game_helper"][str(page)][str(item)]["level"]:
            continue
        active += 1
        if (page, item) == (3, 1):
            resets, instant = sweep_options(p1)
            state = mieshendian.settle(save, config, now)
            if state["resets"] + resets > vip["bzxtrst"]:
                raise ValueError("灭神殿今日重置次数不足，请修改助手设置")
            gold += sum(config["buycount_price"][str(i)]["mieshendian"] for i in range(state["resets"]+1, state["resets"]+resets+1))
            if instant:
                target = state["maxfloor"] // 5 * 5
                seconds = max(0, state["sweep"]["end_at"]-now) if state["sweep"] else max(0, target-state["floor"]+1) * int(config["global_kv"]["mieshendian_saodang_time"]["value"])
                gold += ((seconds+59)//60 + resets*((target*int(config["global_kv"]["mieshendian_saodang_time"]["value"])+59)//60)) * int(config["global_kv"]["mieshendian_saodang_gold"]["value"])
        elif (page, item) == (3, 9):
            arena.daily_reward(save, config, now)
            state = save["arena_state"]
            if state["bought"]+p1 > vip["b_athletics"]:
                raise ValueError("竞技场今日购买次数不足，请修改助手设置")
            prices = config["buycount_price"]
            gold += sum(prices[str(min(i, max(map(int, prices))))]["athletics"] for i in range(state["bought"]+1, state["bought"]+p1+1))
    if gold >= (1 << 31):
        raise ValueError("游戏助手报价超出范围")
    return gold, active


def merge_rewards(rewards, gold=0):
    scalar, nested, repeated = {}, {}, []
    for reward in rewards:
        for n, w, value in iter_pb_fields(reward):
            if n in (1, 2, 3, 4) and w == 0:
                scalar[n] = scalar.get(n, 0)+value
            elif n in (5, 7, 9, 10) and w == 2:
                nested[n] = nested.get(n, b"")+value
            elif n in (6, 8, 11) and w == 2:
                repeated.append(encode_pb_field(n, w, value))
    if gold:
        nested[10] = nested.get(10, b"")+encode_pb_field(1, 2, encode_pb_field(1, 0, 1001)+encode_pb_field(2, 0, gold))
    if any(v >= (1 << (63 if n == 1 else 31)) for n, v in scalar.items()):
        raise ValueError("游戏助手累计奖励超出范围")
    return (b"".join(encode_pb_field(n, 0, v) for n, v in scalar.items())
            + b"".join(encode_pb_field(n, 2, v) for n, v in nested.items())+b"".join(repeated))


def execute_item(row, save, config, now, step_counts):
    from . import player

    page, item, p1, p2, p3, p4, p5 = row
    if (page, item) not in SUPPORTED:
        raise ValueError("此项底层玩法或助手接入仍在后续批次，未消耗资源")
    if save["role_state"]["level"] < config["game_helper"][str(page)][str(item)]["level"]:
        raise ValueError("未到此助手项目开放等级")
    rewards, cost, counts = [], 0, [0]*6

    def run(opcode, values=()):
        nonlocal cost
        previous = save["role_state"]["gold"]
        data = player.prepare_recorded_response(opcode, b"", save, recharge.ids(values), step_counts, config, now)
        if opcode in (*activity_copy.BATTLES, 1611):
            prize = next((v for n, w, v in iter_pb_fields(data) if (n, w) == (4, 2)), b"")
        elif opcode == 2128:
            prize = next(v for n, w, raw in iter_pb_fields(data) if (n, w) == (1, 2) and pb_get_varint(raw, 1) == 3
                         for n, w, v in iter_pb_fields(raw) if (n, w) == (2, 2))
        elif opcode in (1325, 3705, 2066, 3624, 2122):
            prize = data
        else:
            prize = b""
        cost += previous-save["role_state"]["gold"]+sum(v for n, w, v in iter_pb_fields(prize) if (n, w) == (2, 0))
        rewards.append(prize)
        return data

    if page == 2:
        state = activity_copy.settle(save, config, now)
        table, opcode, _, limit = activity_copy.COPIES[item]
        current = state["copies"][str(item)]
        if not current["cleared"]:
            raise ValueError("没有已通关的活动难度，请先手动挑战")
        if not 1 <= p1 <= config["vip"]["0"][limit]-current["used"]:
            raise ValueError("本批助手不购买活动副本次数，请只选择剩余免费次数")
        for attempt in range(1, p1+1):
            result = run(opcode, [current["cleared"]])
            if not pb_get_varint(result, 1):
                break
        message = f"最高已通关难度真实挑战{attempt}次；"+("胜利" if pb_get_varint(result, 1) else "战败，已停止")
    elif item == 1:
        resets, instant = sweep_options(p1)
        state = mieshendian.settle(save, config, now)
        for index in range(resets+1):
            if state["sweep"]:
                if not instant and state["sweep"]["end_at"] > now:
                    raise ValueError("正在扫荡，请勾选立即完成或等待结束")
                run(3624)
                counts[3] += 1
            elif state["floor"] <= state["maxfloor"]//5*5:
                run(3623)
                if instant:
                    run(3624)
                    counts[3] += 1
            elif index == 0 and not resets:
                raise ValueError("没有可扫荡的灭神殿层数")
            if index < resets:
                run(3626)
                counts[2] += 1
        message = f"真实扫荡；重置{counts[2]}次，完成{counts[3]}次"
    elif item == 2:
        run(2062)
        state = save["watchstar_state"]
        vip = config["vip"][str(save["role_state"]["vip"])]
        for _ in range(vip["c_watchstar_watch"]+1):
            if not state["slots"][0]:
                if state["forecasts"] >= vip["c_watchstar_watch"]:
                    break
                run(2063)
            while state["changes"] < vip["c_watchstar_change"] and state["slots"] != list(range(1, 9)):
                run(2064)
            run(2065)
        if any(i not in state["claimed"] and state["stars"] >= config["watchstar_reward"][str(i)]["star"] for i in range(1, 11)):
            run(2066)
        message = "已用剩余免费观星/换星并领取已达奖励；不付费点亮或升级"
    elif item == 3:
        if p1:
            raise ValueError("本批蓬莱助手只用免费骰和免费翻牌，请将重置次数设为0")
        run(2128, [0])
        message = "只用剩余免费骰、免费翻牌；遇败停止，不重置、不领四星箱"
    elif item == 9:
        reward = arena.daily_reward(save, config, now)
        if reward:
            player.apply_reward(save, reward, config, now)
            rewards.append(reward)
        if p1:
            state = save["arena_state"]
            prices = config["buycount_price"]
            price = sum(prices[str(min(i, max(map(int, prices))))]["athletics"] for i in range(state["bought"]+1, state["bought"]+p1+1))
            run(301, [1, p1, price])
        remaining = arena.remaining(save, save["arena_state"], config)
        if not remaining:
            raise ValueError("竞技场剩余挑战次数不足")
        if remaining > 100:
            raise ValueError("竞技场助手单次最多100场")
        for attempt in range(1, remaining+1):
            opponents = arena.opponents(save["arena_state"]["rank"], config)
            result = run(1611, [min(opponents)])
            if not pb_get_varint(result, 1):
                break
        message = f"真实挑战可选NPC {attempt}次；"+("胜利，不续购" if pb_get_varint(result, 1) else "战败，已停止，不续购")
    elif item == 10:
        state = friend_copy.settle(save, config, now)
        if p2 != state["cleared"]:
            raise ValueError("好友副本显示关卡已变化，请重新打开助手")
        run(1325, [p2, p1])
        message = f"最高已通关好友副本真实扫荡{p1}次"
    elif item == 12:
        state = single_boss.settle(save, config, now)
        kind = single_boss.boss_type(state, config)
        cleared = state["cleared"][str(kind)]
        if not cleared or p2 != single_boss.levels(config, kind)[cleared-1]["id"]:
            raise ValueError("王的男人当前Boss或已通关难度已变化，请重新打开助手")
        run(3705, [p2, p1])
        last = save["last_single_boss_battle"]
        message = f"专用阵容真实挑战{last['attempts']}次、胜利{last['wins']}次；遇败停止"
    return merge_rewards(rewards, cost), cost, counts, message


def execute(rows, save, config, now, step_counts):
    logs, messages, totals, spent = [], [], [0]*6, 0
    for row in rows:
        working = copy.deepcopy(save)
        try:
            reward, cost, counts, message = execute_item(row, working, config, now, step_counts)
        except ValueError as error:
            code, reward, message = 71, b"", str(error)
        else:
            code = 0
            save.clear()
            save.update(working)
            spent += cost
            totals = [a+b for a, b in zip(totals, counts)]
        mid = int(f"{row[0]}{row[1]:02d}01{code}")
        logs.append((mid, reward))
        messages.append((mid, message.encode("utf-8")))
    return comb([(100, recharge.ids(totals)), *logs, (200, comb(messages))]), spent


def snapshots(save, now):
    from . import player

    return [pack_frame(mid, 0, bytes.fromhex(save["world_state"][str(mid)])) for mid in (1002, 1012, 1200)] + [
        pack_frame(1001, 0, player.apply_role_state(bytes.fromhex(save["role_snapshot"]), save, now))]


def handle(session, opcode, seq, body):
    from . import player

    config, now = session.role_config, int(player.time.time())
    require_open(session.save, config)
    previous = receipt(session.save)
    if opcode == 6211:
        if body:
            raise ValueError("游戏助手查询不接受参数")
        return [pack_frame(opcode, seq, query(session.save, config, now))]
    if now < session.save.get("stamina_clock", {}).get("checked_at", 0):
        raise ValueError("服务器时钟回拨，游戏助手未执行、未扣费")
    rows, token, request = parse(body, config)
    if token is None:
        gold, active = estimate(rows, session.save, config, now)
        token = random.SystemRandom().randrange(1, 1 << 31)
        while previous and token == previous["token"]:
            token = random.SystemRandom().randrange(1, 1 << 31)
        session.helper_quote = {"token": token, "request": request, "before": copy.deepcopy(session.save),
                                "now": now, "gold": gold}
        info = ("按勾选项目执行；元宝为服务端报价上限，仅扣实际费用。观星仅用免费次数；蓬莱须重置0，仅免费骰/翻牌；"
                "活动副本不买次数，战斗遇败停止。未接通项目只记原因、不扣费。确认60秒内有效，状态变化须重新报价。")
        return [pack_frame(opcode, seq, comb([(101, recharge.ids([token, gold, active, len(rows)-active])), (102, info.encode("utf-8"))]))]
    if previous and previous == {"token": token, "request": request}:
        return [pack_frame(opcode, seq, comb([(103, recharge.ids([1]))]))]+snapshots(session.save, now)
    quote = getattr(session, "helper_quote", None)
    if (not quote or quote["token"] != token or quote["request"] != request or quote["before"] != session.save
            or not quote["now"] <= now < quote["now"]+60 or (now+28800)//86400 != (quote["now"]+28800)//86400):
        raise ValueError("助手报价过期或角色状态已变化，请重新打开助手并确认；未扣费")
    if session.save["role_state"]["gold"] < quote["gold"]:
        raise ValueError("元宝不足以覆盖确认上限，请修改助手设置；未执行")
    working = copy.deepcopy(session.save)
    player.settle_self_stats(working, config)
    player.settle_campaign(working, config, now)
    online_rewards.settle(working, config, session.connected_at, now)
    welfare.settle(working, now)
    player.settle_stamina(working, config, now)
    reply, spent = execute(rows, working, config, now, session.step_counts)
    if not 0 <= spent <= quote["gold"]:
        raise ValueError("助手实际费用超出确认上限，整笔未保存、未扣费")
    working["game_helper_receipt"] = {"token": token, "request": request}
    packets = player.save_response_group([pack_frame(opcode, seq, reply)]+snapshots(working, now), working, session.save,
                                         session.save_path, session.step_counts, config, now)
    session.save = working
    session.helper_quote = None
    return packets
