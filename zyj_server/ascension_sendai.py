"""升仙台：10 轮地图、事件链、点仙镜像、真实战斗与升仙币/升仙玉商店。

原生客户端已有完整 UI；本模块按 GameAscensionSendai.lua / Layer_ascensionSendai_*.lua
的回包形状实现 8851–8860（88591 是纯本地布阵，不发网络包）。
地图走格、事件选择、阵容血量、buff 与奖励都由服务端按真实配置判定。
"""

import copy
import json
import random
from fractions import Fraction

from . import activities, battle, cheer, formation, pets
from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint
from .recharge import ids

QUERIES = (8851, 8855, 8856, 8859, 8860)
MUTATIONS = (8852, 8853, 8854, 8857, 8858)
OPCODES = (*QUERIES, *MUTATIONS)
ROUND_SECONDS = 3 * 86400
CURRENCY_BI = 1044
CURRENCY_YU = 1045
COLUMNS = 5
EVENT_TYPES = ("adventure", "buy", "buff", "cheer", "encounter", "recover", "revive",
               "battle", "battle1", "boss", "reward")


def comb(messages):
    return b"".join(encode_pb_field(1, 2, encode_pb_field(1, 0, mid) + encode_pb_field(2, 2, data))
                    for mid, data in messages)


def param_string(text):
    return encode_pb_field(1, 2, encode_pb_field(2, 2, text.encode("utf-8")))


def parse(raw, count=None):
    values = []
    for n, w, value in iter_pb_fields(raw):
        if (n, w) != (1, 0):
            raise ValueError("升仙台参数格式无效")
        # 原生布阵用 -1 表示不可用阵位；protobuf 的负 int32 按 64 位补码下发。
        if value >= 1 << 63:
            value -= 1 << 64
        if not -1 <= value < 1 << 31:
            raise ValueError("升仙台参数格式无效")
        values.append(value)
    if count is not None and len(values) != count:
        raise ValueError("升仙台参数个数无效")
    return values


def comb_messages(raw):
    result = {}
    for n, w, value in iter_pb_fields(raw):
        if (n, w) != (1, 2):
            raise ValueError("升仙台复合消息格式无效")
        mid, data = None, b""
        for fn, fw, sub in iter_pb_fields(value):
            if (fn, fw) == (1, 0):
                mid = sub
            elif (fn, fw) == (2, 2):
                data = sub
        if mid is None:
            raise ValueError("升仙台复合消息缺少编号")
        result[mid] = data
    return result


def flat(rows):
    return ids([value for row in rows for value in row])


def currency(save, cid):
    records = formation.records(bytes.fromhex(save["world_state"]["1200"]), 1, 1)
    return pb_get_varint(records.get(cid, b""), 2) or 0


def battle_result(report, reward):
    return (encode_pb_field(1, 0, int(report["result"])) + encode_pb_field(2, 0, report["star"])
            + encode_pb_field(4, 2, reward)
            + encode_pb_field(5, 2, json.dumps(report, ensure_ascii=False, separators=(",", ":")).encode("utf-8")))


def map_table(config, round_id):
    return config[f"shengxian_map{round_id}"]


def rounds(config):
    return max(int(name.removeprefix("shengxian_map")) for name in config if name.startswith("shengxian_map"))


def origin(config, round_id):
    table = map_table(config, round_id)
    last = max(int(key) for key in table)
    for column in range(1, COLUMNS + 1):
        if table[str(last)].get(f"line_{column}"):
            return (last - 1) * COLUMNS + column
    raise ValueError("升仙台地图缺少起点")


def cell(config, round_id, point):
    table = map_table(config, round_id)
    rows = max(int(key) for key in table)
    if not 1 <= point <= rows * COLUMNS:
        raise ValueError("升仙台格子不存在")
    row, column = (point - 1) // COLUMNS + 1, (point - 1) % COLUMNS + 1
    return table[str(row)], column


def predecessors(row, column):
    text = str(row.get(f"line_{column}", ""))
    values = []
    for part in text.replace("，", ",").replace("；", ";").replace(";", ",").split(","):
        if part.strip().isdigit() and int(part) > 0:
            values.append(int(part))
    return values


def event_type(config, event_id):
    row = config["shengxian_type"].get(str(event_id))
    if row is None or row["type"] not in EVENT_TYPES:
        raise ValueError("升仙台事件配置不存在")
    return row["type"]


def first_id(config, event_id, level, mode):
    row = config["shengxian_type"].get(str(event_id))
    if row is None or level not in range(1, 8) or mode not in (1, 2):
        raise ValueError("升仙台难度或事件无效")
    text = row.get(f"difficult{level}_{mode}", "")
    if not text or ";" not in text:
        raise ValueError("升仙台事件缺少难度配置")
    head = text.split(";")[0].split(",")
    if len(head) < 2 or not head[0].strip().isdigit():
        raise ValueError("升仙台事件难度配置无效")
    return int(head[0])


def pool(text, width):
    entries = []
    for part in text.split(";"):
        if not part:
            continue
        values = [int(v) for v in part.split(",")[:width]]
        if len(values) != width or values[0] <= 0 or values[-1] < 0:
            raise ValueError("升仙台事件池配置无效")
        entries.append(values)
    if not entries:
        raise ValueError("升仙台事件池为空")
    return entries


def weighted(entries, count, seed):
    rng = random.Random(seed)
    remaining = [list(entry) for entry in entries]
    picked = []
    for _ in range(count):
        if not remaining:
            break
        total = sum(entry[-1] for entry in remaining)
        target = rng.randrange(total) if total > 0 else 0
        for index, entry in enumerate(remaining):
            target -= entry[-1]
            if total == 0 or target < 0:
                picked.append(entry[0])
                remaining.pop(index)
                break
    if len(picked) < count:
        picked.extend(entry[0] for entry in remaining[:count - len(picked)])
    return picked


def fresh(config, now):
    state = {
        "day": (now + 28800) // 86400, "checked_at": now, "end_at": now + ROUND_SECONDS,
        "round": 1, "difficulty": 0, "level": 0, "point": origin(config, 1), "point_state": 0,
        "path": [], "events": {}, "generals": [], "monsters": {}, "buffs": [], "cheers": [],
        "shop": {key: 0 for key in config["shengxian_shop"]},
    }
    state["path"] = [state["point"]]
    return state


def new_round(state, config, now):
    state["round"] = state["round"] % rounds(config) + 1
    state.update(end_at=now + ROUND_SECONDS, difficulty=0, level=0,
                 point=origin(config, state["round"]), point_state=0,
                 events={}, generals=[], monsters={}, buffs=[], cheers=[],
                 shop={key: 0 for key in config["shengxian_shop"]})
    state["path"] = [state["point"]]


def integer(value, low, high):
    return type(value) is int and low <= value <= high


def get_state(save, config, now):
    state = save.get("ascension_sendai_state")
    if state is None:
        state = fresh(config, now)
        save["ascension_sendai_state"] = state
    try:
        if (not isinstance(state, dict)
                or any(not integer(state.get(k), 0, 1 << 63) for k in ("day", "checked_at", "end_at"))
                or not integer(state["round"], 1, rounds(config))
                or not integer(state["difficulty"], 0, 2)
                or not integer(state["level"], 0, 7)
                or not integer(state["point"], 1, 1 << 20)
                or state["point_state"] not in (0, 1, 2)
                or not isinstance(state["path"], list) or not 1 <= len(state["path"]) <= 1024
                or any(not integer(v, 1, 1 << 20) for v in state["path"])
                or not isinstance(state["events"], dict) or not isinstance(state["generals"], list)
                or not isinstance(state["monsters"], dict) or not isinstance(state["buffs"], list)
                or not isinstance(state["cheers"], list) or not isinstance(state["shop"], dict)
                or set(state["shop"]) != set(config["shengxian_shop"])
                or any(not isinstance(row, list) or len(row) != 10 for row in state["generals"])
                or any(not isinstance(row, list) or len(row) != 2 for row in state["buffs"])
                or any(not integer(v, 0, 1 << 31) for row in state["buffs"] for v in row)
                or any(not integer(v, 0, 1 << 31) for v in state["cheers"])):
            raise ValueError
        for key, event in state["events"].items():
            if (not isinstance(event, dict) or event["type"] not in EVENT_TYPES
                    or not integer(event["id"], 1, 1 << 31) or type(event["done"]) is not bool
                    or not isinstance(event["follow"], list) or not isinstance(event["data"], dict)):
                raise ValueError
        for key, rows in state["monsters"].items():
            if not isinstance(rows, list) or any(not isinstance(row, list) or len(row) != 4 for row in rows):
                raise ValueError
    except (KeyError, TypeError, ValueError):
        raise ValueError("升仙台存档无效") from None
    if now < state["checked_at"] or (now + 28800) // 86400 < state["day"]:
        raise ValueError("升仙台时钟回拨，请稍后重试")
    if now >= state["end_at"]:
        new_round(state, config, now)
    state["day"] = (now + 28800) // 86400
    state["checked_at"] = max(now, state["checked_at"])
    save["ascension_sendai_state"] = state
    return state


def require_open(save, config):
    row = config["build"]["664"]
    if (not save.get("has_role") or row["switch"] != 1
            or save["role_state"]["level"] < row["level"]):
        raise ValueError("升仙台尚未解锁")


def point_str(state):
    return ",".join(map(str, state["path"])) + ","


def status(state, save, now):
    return ids([state["round"], max(0, state["end_at"] - now), state["difficulty"], state["level"],
                state["point"], state["point_state"], int(bool(state["generals"])), currency(save, CURRENCY_YU)])


def event_payload(kind, event, state, config, seed, save):
    """8853 message id=1：按事件类型生成未完成事件数据，并写入事件上下文。"""
    event_id = event["id"]
    level, mode = state["level"], state["difficulty"]
    if kind == "adventure":
        entries = pool(config["shengxian_type"][str(event_id)][f"difficult{level}_{mode}"], 2)
        choices = [e for e in entries if event_type(config, e[0]) != "adventure"]
        if not choices:
            raise ValueError("升仙台随机事件池无效")
        follow = weighted(choices, 1, seed)
        event["follow"] = follow
        event["data"] = {"from": event_id}
        return ids(follow)
    if kind == "buy":
        buy_id = first_id(config, event_id, level, mode)
        entries = pool(config["shengxian_buy"][str(buy_id)]["buffid"], 4)
        offers = weighted(entries, 4, seed)
        prices = {entry[0]: entry[2] for entry in entries}
        event["data"] = {"buy_id": buy_id, "offers": offers, "prices": prices}
        return ids([currency(save, CURRENCY_YU), 0, *offers])
    if kind == "buff":
        pool_id = first_id(config, event_id, level, mode)
        offers = weighted(pool(config["shengxian_buff"][str(pool_id)]["buffid"], 2), 3, seed)
        event["data"] = {"offers": offers}
        return ids([*offers, 0])
    if kind == "cheer":
        pool_id = first_id(config, event_id, level, mode)
        offers = weighted(pool(config["shengxian_hero"][str(pool_id)]["generalid"], 2), 4, seed)
        event["data"] = {"offers": offers}
        return ids([*offers, 0])
    if kind == "encounter":
        encounter_id = first_id(config, event_id, level, mode)
        if str(encounter_id) not in config["shengxian_praram"]:
            raise ValueError("升仙台仙遇配置不存在")
        event["data"] = {"encounter_id": encounter_id}
        return ids([encounter_id, 0])
    if kind in ("recover", "revive"):
        recover_id = first_id(config, event_id, level, mode)
        if str(recover_id) not in config["shengxian_recover"]:
            raise ValueError("升仙台恢复配置不存在")
        event["data"] = {"recover_id": recover_id}
        return ids([0])
    if kind in ("battle", "battle1", "boss"):
        battle_id = first_id(config, event_id, level, mode)
        if str(battle_id) not in config["shengxian_battle"]:
            raise ValueError("升仙台战斗配置不存在")
        event["data"] = {"battle_id": battle_id}
        return ids([0])
    if kind == "reward":
        reward_id = first_id(config, event_id, level, mode)
        if str(reward_id) not in config["shengxian_reward"]:
            raise ValueError("升仙台奖励配置不存在")
        event["data"] = {"reward_id": reward_id}
        return activities.build_reward(save, config["shengxian_reward"][str(reward_id)]["reward"], config)
    raise ValueError("升仙台事件类型未实现")


def done_payload(kind, event, state, save):
    """8853 已完成事件：按原生客户端的「已完成」判定返回对应标记。"""
    data = event["data"]
    if kind == "buy":
        return ids([currency(save, CURRENCY_YU), data.get("chosen", 1), 0, 0, 0, 0])
    if kind == "buff":
        return ids([0, 0, 0, data.get("chosen", 1)])
    if kind == "cheer":
        return ids([0, 0, 0, 0, data.get("chosen", 1)])
    if kind == "encounter":
        return ids([data.get("encounter_id", 1), 1])
    if kind in ("recover", "revive"):
        return ids([1])
    if kind == "reward":
        return b""
    if kind in ("battle", "battle1", "boss") or kind == "adventure":
        return ids(event["follow"][:1] or [0])
    return ids([0])


def add_buff(state, buff_id, config):
    if str(buff_id) not in config["breakskill"]:
        raise ValueError("升仙台仙术配置不存在")
    for row in state["buffs"]:
        if row[0] == buff_id:
            row[1] = 1
            return
    state["buffs"].append([buff_id, 1])


def apply_buffs(units, state, config):
    for buff_id, active in state["buffs"]:
        if not active:
            continue
        row = config["breakskill"].get(str(buff_id))
        if not row or row["attr"] not in ("atk", "def", "hp", "speed", "critical", "dodge", "hit", "arp"):
            continue
        value = Fraction(str(row["value"]))
        for unit in units.values():
            base = unit.get(row["attr"], 0)
            unit[row["attr"]] = max(0, int(base + (base * value if row["method"] == "percent" else value)))


def monster_state(state, config, point_id, event_id, level, mode):
    key = f"{point_id}:{event_id}"
    if key not in state["monsters"]:
        battle_id = first_id(config, event_id, level, mode)
        row = config["shengxian_battle"][str(battle_id)]
        state["monsters"][key] = [[int(row[f"p{i}"]), 100, 100, 0] for i in range(1, 8) if row[f"p{i}"] > 0]
    return state["monsters"][key]


def fight(save, state, config, event, selected, point_id, event_id, seed, now):
    row = config["shengxian_battle"][str(event["data"]["battle_id"])]
    if not state["generals"]:
        raise ValueError("请先点仙上传升仙台阵容")
    point = dict(row)
    for index in range(1, 8):
        point.setdefault(f"p{index}-grow", 0)
        # 升仙台怪物不是玩家武将；突破被动按真实 general.breakN 表投影会引入
        # 原生战斗引擎尚不支持的字段，怪物强度已由 *-correct 修正字段给出。
        point[f"break{index}-correct"] = 0
    monsters = {str(row[f"p{i}"]): config["shengxian_monster"][str(row[f"p{i}"])]
                for i in range(1, 8) if row[f"p{i}"] > 0}
    combat_config = {**config, "copy_monster": {**config["copy_monster"], **monsters}}
    attack, defense = battle.rosters(save, point, combat_config)
    by_iid = {unit["iid"]: unit for unit in attack.values()}
    mirror = {row[0]: row for row in state["generals"]}
    chosen = []
    for iid in selected:
        if iid and iid in by_iid and iid in mirror and iid not in [u["iid"] for u in chosen]:
            unit = copy.deepcopy(by_iid[iid])
            saved = mirror[iid]
            ratio = min(1, max(0, saved[4] / saved[3])) if saved[3] > 0 else 0
            unit["hp"] = max(1, int(unit["hp"] * ratio))
            chosen.append(unit)
    limit = min(7, max(1, int(row["num"])))
    chosen = chosen[:limit]
    if not chosen:
        raise ValueError("升仙台上阵阵容无效")
    attack = {battle.POSITIONS[index]: unit for index, unit in enumerate(chosen)}
    apply_buffs(attack, state, config)
    enemy = monster_state(state, config, point_id, event_id, state["level"], state["difficulty"])
    positions = [(index, battle.POSITIONS[index - 1]) for index in range(1, 8) if row[f"p{index}"] > 0]
    for (_, pos), saved in zip(positions, enemy):
        unit = defense.get(pos)
        if unit and saved[2] > 0:
            unit["hp"] = max(1, int(unit["hp"] * saved[1] / saved[2]))
    cheer_cids = [cid for cid in dict.fromkeys([*state["cheers"], *cheer.combat(save, config)])
                  if config["general"].get(str(cid), {}).get("battle")][:8]
    report = battle.simulate(attack, defense, combat_config, seed,
                             attack_pet=pets.combat(save, config), attack_cheer=cheer_cids)
    report["meta"]["attack"]["n"] = save["role_name"]
    report["meta"]["defense"]["n"] = next(iter(monsters.values()))["name"]
    for pos, unit in report["endmeta"]["attack"].items():
        saved = mirror.get(unit["i"])
        if saved and unit["j"] > 0:
            saved[4] = max(0, int(saved[3] * unit["h"] / unit["j"]))
            saved[5] = unit["ap"]
    for (_, pos), saved in zip(positions, enemy):
        unit = report["endmeta"]["defense"].get(str(pos))
        if unit and unit["j"] > 0:
            saved[1] = max(0, int(saved[2] * unit["h"] / unit["j"]))
            saved[3] = unit["ap"]
    reward = activities.build_reward(save, row["reward"], config) if report["result"] else b""
    follow = []
    if report["result"] and event["type"] in ("battle", "battle1"):
        follow = [next(int(key) for key, config_row in sorted(config["shengxian_type"].items())
                       if config_row["type"] == "buff" and f"difficult{state['level']}_{state['difficulty']}" in config_row)]
        event["follow"] = follow
    event["done"] = bool(report["result"])
    state["point_state"] = 1 if report["result"] else 0
    if report["result"] and event["type"] == "boss":
        # 通关顶层 Boss 后下一次 8851 开启新一轮，重新选择难度与点仙。
        state["end_at"] = now
    messages = [(1, battle_result(report, reward))]
    if event["type"] in ("battle", "battle1"):
        messages.append((2, ids(follow[:1] or [0])))
    return comb(messages), reward, []


def heal(state, config, event, selected, revive):
    row = config["shengxian_recover"][str(event["data"]["recover_id"])]
    percent = Fraction(str(row["percent"]))
    count = max(1, int(row["num"]))
    mirror = {entry[0]: entry for entry in state["generals"]}
    targets = [mirror[iid] for iid in selected if iid in mirror][:count]
    if not targets:
        raise ValueError("升仙台恢复对象无效")
    for entry in targets:
        if revive and entry[4] <= 0:
            entry[4] = max(1, int(entry[3] * percent))
        else:
            entry[4] = min(entry[3], int(entry[4] + entry[3] * percent))
    first = targets[0]
    return ids([first[0], first[2], first[4]])


def offer_entry(text):
    entries = [part for part in text.split(";") if part]
    if not entries:
        return []
    return [(int(part.split(",")[0]), int(part.split(",")[1])) for part in entries]


def prepare(opcode, save, body, config, now, seed):
    """返回 (回包, 需要入账的奖励, 需要扣除的物品)。"""
    require_open(save, config)
    state = get_state(save, config, now)
    if opcode == 8851:
        if body:
            raise ValueError("升仙台查询不接受参数")
        return comb([(0, status(state, save, now)), (1, param_string(point_str(state)))]), b"", []
    if opcode == 8852:
        mode, point_id, level = parse(body, 3)
        if mode not in (1, 2) or str(level) not in config["shengxian_interval"]:
            raise ValueError("升仙台难度或等级无效")
        if state["difficulty"] or state["level"] or point_id != origin(config, state["round"]):
            raise ValueError("本轮升仙台难度已选择")
        if save["role_state"]["level"] < config["shengxian_interval"][str(level)]["level"]:
            raise ValueError("队伍等级不足，无法选择该升仙台难度")
        state.update(difficulty=mode, level=level, point=point_id, point_state=0,
                     path=[point_id], events={}, generals=[], monsters={}, buffs=[], cheers=[])
        state["shop"] = {key: 0 for key in config["shengxian_shop"]}
        state["end_at"] = now + ROUND_SECONDS
        return ids([mode, point_id, level]), b"", []
    if opcode == 8855:
        if body:
            raise ValueError("升仙台仙术查询不接受参数")
        return flat(state["buffs"]), b"", []
    if opcode == 8856:
        if body:
            raise ValueError("升仙台商店查询不接受参数")
        shop = config["shengxian_shop"]
        return ids([max(0, state["end_at"] - now), currency(save, CURRENCY_BI),
                    *[state["shop"][key] for key in sorted(shop, key=int)]]), b"", []
    if opcode == 8857:
        row_id, count = parse(body, 2)
        key = str(row_id)
        shop = config["shengxian_shop"]
        if key not in shop or count <= 0:
            raise ValueError("升仙台商店商品或数量无效")
        item = shop[key]
        if int(item["lv"]) > save["role_state"]["level"]:
            raise ValueError("队伍等级不足，无法兑换该升仙台商品")
        limit = int(item["limit"])
        if limit and state["shop"][key] + count > limit:
            raise ValueError("升仙台商店兑换次数不足")
        costs = offer_entry(item["consume"])
        if len(costs) != 1 or costs[0][0] != CURRENCY_BI or costs[0][1] <= 0:
            raise ValueError("升仙台商店消耗配置无效")
        cost = costs[0][1] * count
        if cost >= 1 << 31 or currency(save, CURRENCY_BI) < cost:
            raise ValueError("升仙币不足")
        state["shop"][key] += count
        reward = activities.build_reward(save, item["reward"], config, quantity=count)
        return reward, reward, [(CURRENCY_BI, cost)]
    if opcode == 8858:
        selected = parse(body)
        if not selected or len(selected) > 7:
            raise ValueError("升仙台阵容参数无效")
        generals = formation.records(bytes.fromhex(save["world_state"]["1002"]), 1, 2)
        mirror = []
        for iid in selected:
            if iid <= 0:
                continue
            raw = generals.get(iid)
            if raw is None:
                raise ValueError("升仙台阵容包含未拥有的伙伴")
            unit = {name: pb_get_varint(raw, field) or 0 for name, field in battle.GENERAL_FIELDS.items()}
            if unit["cid"] <= 0 or unit["hp"] <= 0 or iid in [row[0] for row in mirror]:
                raise ValueError("升仙台阵容属性无效")
            mirror.append([iid, 0, unit["cid"], unit["hp"], unit["hp"], 0,
                           unit["level"], unit["advance"], 0, 0])
        if not mirror:
            raise ValueError("请至少上阵一名伙伴")
        state["generals"] = mirror
        return flat(mirror), b"", []
    if opcode == 8859:
        if body:
            raise ValueError("升仙台阵容查询不接受参数")
        return flat(state["generals"]), b"", []
    if opcode == 8860:
        point_id, event_id = parse(body, 2)
        if not state["difficulty"] or not state["level"]:
            raise ValueError("请先选择升仙台难度")
        battle_id = first_id(config, event_id, state["level"], state["difficulty"])
        if str(battle_id) not in config["shengxian_battle"]:
            raise ValueError("升仙台怪物阵容不存在")
        return flat(monster_state(state, config, point_id, event_id, state["level"], state["difficulty"])), b"", []
    if opcode == 8853:
        messages = comb_messages(body)
        if 1 not in messages:
            raise ValueError("升仙台走格请求缺少事件")
        point_id, event_id = parse(messages[1], 2)
        if not state["difficulty"] or not state["level"]:
            raise ValueError("请先选择升仙台难度")
        kind = event_type(config, event_id)
        key = str(point_id)
        follow = state["events"].get(key, {}).get("follow", [])
        if point_id != state["point"]:
            row, column = cell(config, state["round"], point_id)
            previous = predecessors(row, column)
            if not row.get(f"line_{column}") or state["point"] not in previous:
                raise ValueError("无法到达该升仙台")
            if state["point_state"] == 0 and origin(config, state["round"]) not in previous:
                raise ValueError("需要完成当前任务才能继续前进")
            if int(row.get(f"event_{column}", 0)) != event_id and event_id not in follow:
                raise ValueError("升仙台格子事件不匹配")
            state["point"] = point_id
            state["point_state"] = 0
            if point_id not in state["path"]:
                state["path"].append(point_id)
            state["events"].pop(key, None)
        event = state["events"].get(key)
        if event_id in follow:
            event = {"id": event_id, "type": kind, "done": False, "follow": [], "data": {}}
            state["events"][key] = event
        elif event is None or event["id"] != event_id:
            row, column = cell(config, state["round"], point_id)
            if int(row.get(f"event_{column}", 0)) != event_id:
                raise ValueError("升仙台格子事件不匹配")
            event = {"id": event_id, "type": kind, "done": False, "follow": [], "data": {}}
            state["events"][key] = event
        if event["done"]:
            data = done_payload(kind, event, state, save)
            reward = b""
        else:
            data = event_payload(kind, event, state, config, seed, save)
            reward = b""
            if kind == "reward":
                reward = data
                event["done"] = True
                state["point_state"] = 1
            elif kind == "adventure":
                state["point_state"] = 0
            else:
                state["point_state"] = 0
        return comb([(1, data), (2, ids([state["point"], state["point_state"]]))]), reward, []
    if opcode == 8854:
        messages = comb_messages(body)
        if 1 not in messages or 2 not in messages:
            raise ValueError("升仙台事件处理请求缺少参数")
        point_id, event_id = parse(messages[1], 2)
        selected = parse(messages[2])
        event = state["events"].get(str(point_id))
        if (event is None or event["id"] != event_id or event["done"] or point_id != state["point"]
                or not selected):
            raise ValueError("升仙台事件已完成或参数不匹配")
        kind = event["type"]
        reward, costs = b"", []
        if kind == "buy":
            chosen = selected[0]
            if chosen not in event["data"]["offers"]:
                raise ValueError("升仙台购买选项无效")
            price = int(event["data"]["prices"][chosen])
            if price <= 0 or currency(save, CURRENCY_YU) < price:
                raise ValueError("升仙玉不足")
            costs = [(CURRENCY_YU, price)]
            add_buff(state, chosen, config)
            event["data"]["chosen"] = chosen
            data = ids([chosen])
        elif kind == "buff":
            chosen = selected[0]
            if chosen not in event["data"]["offers"]:
                raise ValueError("升仙台仙术选项无效")
            add_buff(state, chosen, config)
            event["data"]["chosen"] = chosen
            data = ids([chosen])
        elif kind == "cheer":
            chosen = selected[0]
            if chosen not in event["data"]["offers"]:
                raise ValueError("升仙台助阵选项无效")
            general = config["general"].get(str(chosen))
            if not general:
                raise ValueError("升仙台助阵伙伴不存在")
            state["cheers"].append(chosen)
            event["data"]["chosen"] = chosen
            hp = int(general["hp"])
            data = ids([900000000 + chosen, 0, chosen, hp, hp, 0, save["role_state"]["level"], 0])
        elif kind == "encounter":
            if selected[0] not in (1, 2):
                raise ValueError("升仙台仙遇选项无效")
            row = config["shengxian_praram"][str(event["data"]["encounter_id"])]
            bonus = row[f"bonus{selected[0]}"]
            costs = offer_entry(row.get(f"cost{selected[0]}", ""))
            reward = activities.build_reward(save, bonus, config)
            data = reward
        elif kind in ("recover", "revive"):
            data = heal(state, config, event, selected, kind == "revive")
        elif kind in ("battle", "battle1", "boss"):
            return fight(save, state, config, event, selected, point_id, event_id, seed, now)
        else:
            raise ValueError("该升仙台事件不支持二次处理")
        event["done"] = True
        state["point_state"] = 1
        return comb([(1, data)]), reward, costs
    raise ValueError("升仙台协议未实现")
