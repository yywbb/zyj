"""本地普通/封神招募；配置卡池/价格，计数与奖励由 player 在同一事务中保存。"""

import random
from datetime import datetime, timedelta, timezone

from . import activities
from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint


def get_state(save):
    if "recruit_state" not in save:
        # 旧存档只有已确认的教程步骤可作历史证据；缺失的冷却不从录制时间推算。
        steps = save.get("guide", {}).get("sections", {}).get("1", {}).get("steps", [])
        save["recruit_state"] = {str(pos): {"consum": 0, "freetimes": int(pos == 3 and 13 in steps),
                                          "consumtimes": int(pos == 1 and 30 in steps),
                                          "tentimes": 0, "next_free_at": 0} for pos in range(1, 5)}
    state = save["recruit_state"]
    if not isinstance(state, dict) or set(state) != {"1", "2", "3", "4"}:
        raise ValueError("招募存档无效")
    for row in state.values():
        if (not isinstance(row, dict) or set(row) != {"consum", "freetimes", "consumtimes", "tentimes", "next_free_at"}
                or any(type(v) is not int or not 0 <= v < (1 << (63 if k == "next_free_at" else 31))
                       for k, v in row.items())):
            raise ValueError("招募计数或冷却无效")
    return state


def query(save, body, now):
    if body:
        raise ValueError("招募查询不接受参数")
    values = []
    state = get_state(save)
    for pos in range(1, 5):
        row = state[str(pos)]
        values.extend(row[k] for k in ("consum", "freetimes", "consumtimes", "tentimes"))
        values.append(min((1 << 31) - 1, max(0, row["next_free_at"] - now)))
    return b"".join(encode_pb_field(1, 0, v) for v in values)


def discount(save, config, now):
    zone = timezone(timedelta(hours=8))
    opened = pb_get_varint(bytes.fromhex(save.get("role_snapshot", "")), 22)
    opened = int(save["created_at"]) if opened is None else opened
    for row in config["recruit_tenlottery"].values():
        if row["open_type"] == 1:
            start = (opened + 8 * 3600) // 86400 * 86400 - 8 * 3600 + row["days_later"] * 86400
            end = start + row["continued_time"] * 86400
        else:
            start = int(datetime.strptime(row["opentime"], "%Y%m%d%H%M%S").replace(tzinfo=zone).timestamp())
            end = int(datetime.strptime(row["overtime"], "%Y%m%d%H%M%S").replace(tzinfo=zone).timestamp())
        if start < now < end:
            return row["discount"]
    return 10


def record_draw(save, pos, method, free, cost, config, now):
    row = get_state(save)[str(pos)]
    if free:
        row["freetimes"] += 1
        row["next_free_at"] = now + config["recruit_basic"][str(pos)]["cooldowntime"]
    elif method == 1:
        row["consumtimes"] += 1
    else:
        row["tentimes"] += 10 if method == 3 else 1
    row["consum"] += cost
    get_state(save)


def new_general(cid, iid, config):
    row = config["general"][str(cid)]
    values = {n: 0 for n in range(1, 41)}
    values.update({1: cid, 2: iid, 3: 1, 17: row["potential"]})
    for field, name in enumerate(("atk", "def", "hp", "speed", "critical", "dodge", "parry",
                                  "resilience", "hit", "arp", "criticaldmg"), 6):
        values[field] = row[name]
    # 自研展示战力与战斗成长使用同一四围计分，不声称是官方战力公式。
    values[20] = row["atk"] + row["def"] + row["hp"] // 10 + row["speed"]
    if any(type(v) is not int or not 0 <= v < (1 << 31) for v in values.values()):
        raise ValueError("新武将属性或 iid 超出范围")
    return (b"".join(encode_pb_field(n, 0, v) for n, v in values.items())
            + encode_pb_field(41, 2, b"\x08\x00" * 11))


def require_role(save):
    if not save.get("has_role"):
        raise ValueError("角色尚未创建")
    if save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2:
        raise ValueError("请先完成新手引导后自由招募")


def pick(config, group, rng):
    entries = [tuple(map(int, item.split(","))) for item in config["recruit_deck"][str(group)]["resourceid"].split(";") if item]
    entries = [(e[0], 1, e[1]) if len(e) == 2 else e for e in entries]
    if not entries or any(len(e) != 3 or min(e) <= 0 for e in entries):
        raise ValueError("招募卡池配置无效")
    ticket = rng.randrange(sum(e[2] for e in entries))
    for cid, count, weight in entries:
        ticket -= weight
        if ticket < 0:
            return cid, count


def build_reward(save, gets, config):
    """普通/封神招募及首充共用武将去重，预览不调用此函数发放。"""
    roster = [v for n, w, v in iter_pb_fields(bytes.fromhex(save["world_state"]["1002"])) if n == 1 and w == 2]
    owned = {config["general"][str(pb_get_varint(v, 1))]["init_cid"] for v in roster}
    iid = max([2000000, *(pb_get_varint(v, 2) for v in roster)])
    fragments = {v["general"]: v for v in config["general_fragment"].values()}
    generals, props = [], {}
    for cid, count in gets:
        if type(count) is not int or not 0 < count < (1 << 31):
            raise ValueError("奖励数量无效")
        if str(cid) in config["general"]:
            for _ in range(count):
                if cid in owned:
                    fragment = fragments[cid]
                    props[fragment["id"]] = props.get(fragment["id"], 0) + fragment["recruit"]
                else:
                    iid += 1
                    generals.append(encode_pb_field(8, 2, new_general(cid, iid, config)))
                    owned.add(cid)
        else:
            props[cid] = props.get(cid, 0) + count
    return activities.build_reward(save, ";".join(f"{cid},{amount}" for cid, amount in props.items()), config) + b"".join(generals)


def get_pending(save):
    state = save.setdefault("recruit_pending", {"gets": [], "refreshes": 0})
    if (not isinstance(state, dict) or type(state.get("refreshes")) is not int or not 0 <= state["refreshes"] < (1 << 31)
            or not isinstance(state.get("gets"), list) or len(state["gets"]) not in (0, 10)
            or any(not isinstance(e, list) or len(e) != 2 or any(type(v) is not int or not 0 < v < (1 << 31) for v in e)
                   for e in state["gets"])):
        raise ValueError("封神招募暂存无效")
    return state


def preview(save, opcode, body, config, now, seed):
    if body:
        raise ValueError("封神招募十连操作不接受参数")
    pending = get_pending(save)
    if opcode == 7110:
        values = [0, pending["refreshes"]] + [v for e in pending["gets"] for v in e] if pending["gets"] else [1]
        return b"".join(encode_pb_field(1, 0, v) for v in values), 0, 0
    require_role(save)
    if opcode == 7113:
        if not pending["gets"]:
            raise ValueError("没有待领取的封神招募结果")
        reward = build_reward(save, pending["gets"], config)
        pending.update(gets=[], refreshes=0)
        return reward, 0, 0
    basic = config["recruit_basic"]["4"]
    if opcode == 7111:
        if pending["gets"]:
            raise ValueError("请先领取上次封神十连结果")
        cid, cost = god_cost(save, basic, "tentaverncount")
        record_draw(save, 4, 2, False, cost, config, now)
    else:
        if not pending["gets"]:
            raise ValueError("没有可重抽的封神招募结果")
        prices = config["buycount_price"]
        row = prices[str(min(pending["refreshes"] + 1, max(map(int, prices))))]
        cid, cost = 1001, row["modify_price"]
        pending["refreshes"] += 1
    rng = random.Random(seed)
    # 自研封神十连：每批一名完整武将，其余九份配置碎片；重抽保持同样保底。
    pending["gets"] = [list(pick(config, basic["firsttentavern"] if i == 0 else basic["freecardgroupid"], rng)) for i in range(10)]
    get_pending(save)
    return b"".join(encode_pb_field(1, 0, v) for e in pending["gets"] for v in e), cid, cost


def god_cost(save, basic, field):
    count = next((pb_get_varint(v, 2) for n, w, v in iter_pb_fields(bytes.fromhex(save["world_state"]["1200"]))
                  if n == 1 and w == 2 and pb_get_varint(v, 1) == basic["costid"]), 0)
    return (basic["costid"], basic[field]) if count >= basic[field] else (basic["costid_god"], basic[field + "_god"])


def draw(save, body, config, now, seed):
    fields = list(iter_pb_fields(body))
    if len(fields) != 2 or any(n != 1 or w != 0 or not 0 < v < (1 << 31) for n, w, v in fields):
        raise ValueError("招募参数无效")
    pos, method = (v for _, _, v in fields)
    if not (pos in (1, 2, 3) and method in (1, 2) or (pos, method) in ((1, 3), (4, 1))):
        raise ValueError("招募方式无效；封神十连请使用预览入口")
    require_role(save)
    if pos == 4 and get_pending(save)["gets"]:
        raise ValueError("请先领取上次封神十连结果")
    basic = config["recruit_basic"][str(pos)]
    state = get_state(save)[str(pos)]
    free = method == 1 and basic["openfreerecruit"] == 0 and now >= state["next_free_at"]
    count = {1: 1, 2: 10, 3: 100}[method]
    cost = 0 if free else basic[{1: "count", 2: "tentaverncount", 3: "hundred"}[method]]
    if method != 1:
        cost = cost * discount(save, config, now) // 10
    cost_id = basic["costid"]
    if pos == 4:
        cost_id, cost = god_cost(save, basic, "count")
    group = basic["freecardgroupid"]
    # shortcut: 采用基础池和首次保底；recruit_count 的累计消费换池须明确服务端语义后接入。
    if method == 1 and state["freetimes" if free else "consumtimes"] == 0:
        group = basic["freefirstcardgroupid" if free else "normalfirstcardgroupid"]
    guaranteed = basic["firsttentavern"] if method != 1 and state["tentimes"] == 0 else group
    rng = random.Random(seed)
    gets = [pick(config, guaranteed if i == 0 else group, rng) for i in range(count)]
    reward = build_reward(save, gets, config)
    results = b"".join(encode_pb_field(1, 0, v) for e in gets for v in e)
    response = b"".join(encode_pb_field(1, 2, encode_pb_field(1, 0, mid) + encode_pb_field(2, 2, payload))
                        for mid, payload in ((1, reward), (2, results)))
    record_draw(save, pos, method, free, cost, config, now)
    return response, cost_id, cost
