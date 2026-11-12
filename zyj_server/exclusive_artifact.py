"""130 级专属神器：本体激活/强化/洗礼/镶嵌、器灵、专属副本与重生。

回包形状严格按原生 GameExclusiveArtifact.lua / gamedata.lua：
8101/8102/8104 是每条 12 个 int 的 Ids，8105/8106/8107 是每条 17 个 int，
8103/8201 是 CombMessages，8108/8203/8204 是 SomeThings，8202/8103 内含 BattleResult。
7010 是跨系统购买次数协议，sysId=614 由本模块结算，450 仍归通天塔。

所有等级、消耗、掉落、概率、次数与战斗都来自 configs_sec5.zip 的真实表；
重生返还按本模块逐笔记录的真实消耗，不按理论累计值凭空发料。

战斗加成：combat_bonuses() 只读计算本体基础/强化、器灵基础/强化、随机属性与
套装，battle.rosters 按上阵 IID 注入 unit；已实现的静态属性行与动态被动行通过
exclusive_skills 进入 battle._prepare_teams。未实现的触发型技能行会被显式过滤，
不会让整场战斗抛「尚不支持该突破被动」。加成只作用于战斗 unit，不写
world_state["1002"]，因此角色面板战力不变（与 cover/soul 的战斗专用加成同口径）。

边界：激活副本按已尝试次数取 exclusive_copy 的对应 checkpoint，原生客户端一次
胜利即打开激活窗口；阵位页图标是否置灰仍读取角色快照 General.ids[11] 的
exclusiveArtifactCid，服务端不改写该幻化共用字段，详情/强化页按 8101 数据正常显示。
build611–618 的本地 1 级开放随 configuration.apply_overrides 下发，需重打 APK 才可见；
guide_section 113 同步改为首次升级(2级)触发，S114–S119 仍由原生 NewSystem 首入触发。
"""

import copy
import json
import random
from collections import Counter
from fractions import Fraction

from . import activities, battle, cheer, formation, pets
from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint
from .recharge import ids

QUERIES = (8101, 8105, 8109, 8201)
MUTATIONS = (8102, 8103, 8104, 8106, 8107, 8108, 8202, 8203, 8204)
OPCODES = (*QUERIES, *MUTATIONS)
BUY_SYS_ID = 614

ARTIFACT_FIELDS = 12
QILING_FIELDS = 17
INLAY_SLOTS = 6
SUIT_SLOTS = 3
SPIRIT_GROUPS = 6
DIFFICULTIES = 6
MAX_STRENGTHEN = 5
MAX_REFINE = 10
SPIRIT_VIP_KEYS = ("device_spirit_atk", "device_spirit_def", "device_spirit_hp",
                   "device_spirit_critical", "device_spirit_criticaldmg", "device_spirit_tx")
MATERIALS = (192087, 192088, 192089, 192090, 192091)


def comb(messages):
    return b"".join(encode_pb_field(1, 2, encode_pb_field(1, 0, mid) + encode_pb_field(2, 2, data))
                    for mid, data in messages)


def battle_result(report, reward):
    return (encode_pb_field(1, 0, int(report["result"])) + encode_pb_field(2, 0, report["star"])
            + encode_pb_field(4, 2, reward)
            + encode_pb_field(5, 2, json.dumps(report, ensure_ascii=False, separators=(",", ":")).encode("utf-8")))


def display_reward(reward, qiling_rows):
    """SomeThings.qiling (field 19) 是每枚器灵的 17 字段组，原生客户端据此入缓存、标红点。

    器灵不是普通道具，apply_reward 会忽略 field 19；其真实归属在 exclusive_artifact_state 中。
    """
    if not qiling_rows:
        return reward
    return reward + encode_pb_field(19, 2, ids([value for row in qiling_rows for value in row]))


def parse(body, count=None):
    try:
        fields = list(iter_pb_fields(body))
    except ValueError:
        raise ValueError("专属神器参数格式无效") from None
    if any((n, w) != (1, 0) or not 0 <= v < (1 << 31) for n, w, v in fields):
        raise ValueError("专属神器参数格式无效")
    values = [v for _, _, v in fields]
    if count is not None and len(values) != count:
        raise ValueError("专属神器参数个数无效")
    return values


def require_empty(body, label):
    if body:
        raise ValueError(f"{label}不接受参数")


def integer(value, low, high):
    return type(value) is int and low <= value <= high


def blank_state():
    return {
        "version": 1, "day": 0, "checked_at": 0, "serial": 2200000,
        "artifacts": {}, "qilings": {}, "active": {},
        "soul": {"cleared": {}, "used": 0, "bought": 0},
        "spirit": {"used": {}, "cleared": {}},
    }


def fresh(save):
    state = blank_state()
    save["exclusive_artifact_state"] = state
    return state


def get_state(save):
    state = save.get("exclusive_artifact_state")
    if state is None:
        return fresh(save)
    try:
        if (not isinstance(state, dict) or state.get("version") != 1
                or not all(integer(state.get(key), 0, 1 << 31) for key in ("day", "checked_at", "serial"))
                or not isinstance(state["artifacts"], dict) or not isinstance(state["qilings"], dict)
                or not isinstance(state["active"], dict) or not isinstance(state["soul"], dict)
                or not isinstance(state["spirit"], dict)):
            raise ValueError
        soul, spirit = state["soul"], state["spirit"]
        if (not integer(soul["used"], 0, 1 << 31) or not integer(soul["bought"], 0, 1 << 31)
                or not isinstance(soul["cleared"], dict) or not isinstance(spirit["used"], dict)
                or not isinstance(spirit["cleared"], dict)):
            raise ValueError
        for key, used in state["active"].items():
            if not key.isdigit() or not integer(used, 0, 1 << 31):
                raise ValueError
        for key, cleared in soul["cleared"].items():
            if not key.isdigit() or cleared not in (1, 2):
                raise ValueError
        for key, used in spirit["used"].items():
            if not key.isdigit() or not integer(used, 0, 1 << 31):
                raise ValueError
        for key, levels in spirit["cleared"].items():
            if not key.isdigit() or not isinstance(levels, dict):
                raise ValueError
            for level, cleared in levels.items():
                if not level.isdigit() or cleared not in (0, 1):
                    raise ValueError
        worn = set()
        for key, artifact in state["artifacts"].items():
            if (not key.isdigit() or not isinstance(artifact, dict)
                    or not integer(artifact["cid"], 0, 1 << 31) or not integer(artifact["level"], 0, 70)
                    or not isinstance(artifact["inlay"], list) or len(artifact["inlay"]) != INLAY_SLOTS
                    or not isinstance(artifact["spent"], dict)):
                raise ValueError
            for iid in artifact["inlay"]:
                if not integer(iid, 0, 1 << 31) or iid and (str(iid) not in state["qilings"] or iid in worn):
                    raise ValueError
                if iid:
                    worn.add(iid)
            for cid, count in artifact["spent"].items():
                if not cid.isdigit() or not integer(count, 0, 1 << 31):
                    raise ValueError
        for key, qiling in state["qilings"].items():
            if (not key.isdigit() or int(key) > state["serial"] or not isinstance(qiling, dict)
                    or not integer(qiling["cid"], 0, 1 << 31) or not integer(qiling["level"], 0, 20)
                    or not integer(qiling["success"], 0, 100) or qiling["lock"] not in (0, 1)
                    or not isinstance(qiling["attrs"], list) or len(qiling["attrs"]) != 4
                    or any(not isinstance(attr, list) or len(attr) != 3
                           or any(not integer(v, 0, 1 << 31) for v in attr) for attr in qiling["attrs"])):
                raise ValueError
    except (KeyError, TypeError, ValueError):
        raise ValueError("专属神器存档无效") from None
    return state


def settle(save, config, now):
    state = get_state(save)
    day = (now + 8 * 3600) // 86400
    if day > state["day"]:
        state["day"] = day
        state["active"] = {}
        state["soul"]["used"] = 0
        state["soul"]["bought"] = 0
        state["spirit"]["used"] = {}
    if now < state["checked_at"]:
        raise ValueError("服务器时钟回拨，专属神器操作已停止")
    return state


def validate(save):
    """登录时校验旧档，但不为纯查询/初始化 Comb 创建空存档。"""
    if save.get("exclusive_artifact_state") is not None:
        get_state(save)


def query_view(save, now):
    """只读查看：日切按当前时间呈现，但绝不落盘（初始化 Comb 必须保持存档字节不变）。"""
    state = get_state(save) if save.get("exclusive_artifact_state") is not None else blank_state()
    if (now + 8 * 3600) // 86400 > state["day"]:
        state = copy.deepcopy(state)
        state["day"] = (now + 8 * 3600) // 86400
        state["active"] = {}
        state["soul"] = dict(state["soul"], used=0, bought=0)
        state["spirit"] = dict(state["spirit"], used={})
    return state


def vip_row(save, config):
    return config["vip"].get(str(save["role_state"].get("vip", 0)), config["vip"]["0"])


def require_open(save, config):
    if not save.get("has_role") or save["role_state"]["level"] < int(config["build"]["611"]["level"]):
        raise ValueError("专属神器尚未解锁")


def generals(save):
    world = bytes.fromhex(save["world_state"]["1002"])
    return formation.records(world, 1, 2), formation.records(world, 4, 1)


def general_config(save, config, general_iid):
    members, slots = generals(save)
    raw = members.get(general_iid)
    if raw is None:
        raise ValueError("伙伴不存在或已离队")
    cid = pb_get_varint(raw, 1) or 0
    row = config["general"].get(str(cid))
    if not row:
        raise ValueError("伙伴配置不存在")
    on = any(pb_get_varint(slot, 2) == general_iid for slot in slots.values())
    return row, on


def consumption(text, label):
    result = []
    for entry in str(text).strip(";").split(";"):
        if not entry:
            continue
        parts = entry.split(",")
        if len(parts) != 2 or not parts[0].isdigit() or not parts[1].isdigit():
            raise ValueError(f"{label}配置无效")
        cid, count = int(parts[0]), int(parts[1])
        if cid not in MATERIALS or not 0 < count < 1 << 31:
            raise ValueError(f"{label}配置无效")
        result.append((cid, count))
    if not result:
        raise ValueError(f"{label}配置无效")
    return result


def merge_costs(rows, label):
    total = Counter()
    for row in rows:
        for cid, count in consumption(row["consumption"], label):
            total[cid] += count
    return [(cid, count) for cid, count in sorted(total.items()) if count < 1 << 31]


def table_row(table, key, label):
    row = table.get(str(key))
    if not isinstance(row, dict):
        raise ValueError(f"{label}配置不存在")
    return row


def suit_ids(artifact, state, config):
    suits = Counter()
    for iid in artifact["inlay"]:
        if not iid:
            continue
        qiling = state["qilings"][str(iid)]
        row = table_row(config["exclusive_device_spirit"], qiling["cid"], "器灵")
        suits[int(row["suit"])] += 1
    activated = []
    for suit, count in suits.items():
        candidates = [row for row in config["exclusive_device_spirit_suit"].values()
                      if int(row["suit"]) == suit and int(row["activate_suit"]) <= count]
        if candidates:
            activated.append(max(candidates, key=lambda row: (int(row["activate_suit"]), -int(row["sorting"]))))
    activated.sort(key=lambda row: int(row["sorting"]))
    return [*(int(row["id"]) for row in activated[:SUIT_SLOTS]), *([0] * max(0, SUIT_SLOTS - len(activated)))]


# ---- 战斗加成（只读，不写存档、不改写 1002 面板战力） ----
RATE_STATS = ("critical", "dodge", "parry", "resilience", "hit", "arp", "criticaldmg")
BASE_STATS = ("atk", "def", "hp", "speed")
ATTR_ALIAS = {name: name for name in (*BASE_STATS, *RATE_STATS)}
ATTR_ALIAS.update({"g_atk": "atk", "g_def": "def", "g_hp": "hp",
                   **{f"g_{name}": name for name in RATE_STATS}})
MAX_COMBAT_SKILLS = 32


def skill_ids(config):
    """原生三张专属表里出现的全部 breakskill 行 ID，供 _prepare_teams 校验。"""
    breakskill = config.get("breakskill", {})
    result = set()

    def include(skill):
        if skill and str(skill) in breakskill:
            result.add(int(skill))

    for row in config.get("exclusive", {}).values():
        for index in range(1, 6):
            include(row.get(f"skill{index}"))
    for row in config.get("exclusive_device_spirit_suit", {}).values():
        include(row.get("suit_skill"))
    for row in config.get("exclusive_device_spirit_random_properties", {}).values():
        include(row.get("breakskill"))
        for index in range(1, 6):
            include(row.get(f"intensify{index}"))
    return result


def supported_skill(skill, config, dynamic):
    """只把战斗引擎已实现的行注入 ids；未实现的触发型效果不会让整场战斗报错。"""
    row = config.get("breakskill", {}).get(str(skill))
    if not row:
        return False
    code = row["type_param"] or row["id"]
    if row["type"] == 0 and code not in range(9100001, 9100005):
        return (row["attr"] in (*BASE_STATS, *RATE_STATS, "ap", "dmg", "fdmg")
                and row["target"] in ("1", "2", "3", "4", "5", "7"))
    return code in dynamic


def parse_attribute(text):
    result = []
    for entry in str(text).strip(";").split(";"):
        if not entry:
            continue
        name, _, value = entry.partition(",")
        result.append((name.strip(), Fraction(str(value))))
    return result


def add_stat(bonus, attr, value, method, fairy):
    if attr in ("adddmg", "subdmg"):
        bonus["flat"][0 if attr == "adddmg" else 1] += int(Fraction(str(value)))
        return
    name = ATTR_ALIAS.get(attr)
    if name is None:
        return
    amount = Fraction(str(value))
    if attr.startswith("g_"):
        amount *= fairy  # 仙属性按 global_kv.fairy_turn_every 折算成凡属性
    if method == "percent" and name in BASE_STATS:
        bonus["percent"][name] = bonus["percent"].get(name, Fraction(0)) + amount
    elif name in RATE_STATS:
        bonus["rates"][name] = bonus["rates"].get(name, Fraction(0)) + amount
    else:
        bonus["fixed"][name] = bonus["fixed"].get(name, 0) + int(amount)


def combat_bonuses(save, config):
    """按上阵伙伴 IID 返回专属神器/器灵/套装的真实战斗加成。

    纯只读：不调用会写存档的 get_state()/settle()，坏档只跳过该条，绝不让
    别的系统战斗因专属神器状态崩溃。属性只在 battle.rosters 的 unit 上生效，
    不改 world_state["1002"]，因此面板战力不变（与 cover/soul 的战斗专用加成同口径）。
    """
    state = save.get("exclusive_artifact_state")
    if not isinstance(state, dict):
        return {}
    artifacts, qilings = state.get("artifacts"), state.get("qilings")
    if not isinstance(artifacts, dict) or not isinstance(qilings, dict):
        return {}
    try:
        fairy = Fraction(str(config.get("global_kv", {}).get("fairy_turn_every", {}).get("value", "0.1")))
        dynamic = battle.supported_breakthrough(config)
        allowed = skill_ids(config)
    except (KeyError, TypeError, ValueError, AttributeError):
        return {}
    result = {}
    for key, artifact in artifacts.items():
        try:
            iid = int(key)
            bonus = {"fixed": {}, "percent": {}, "rates": {}, "flat": [0, 0], "skills": []}
            exclusive = config["exclusive"].get(str(artifact["cid"]))
            if not exclusive:
                continue
            attributes = parse_attribute(exclusive["attribute"])
            level = int(artifact["level"])
            table = config["exclusive_intensify"].get(str(exclusive["intensify_type"]), {})
            current = table.get(str(level))
            for name, value in attributes:
                add_stat(bonus, name, value, "value", fairy)
            if current:
                for name, _ in attributes:
                    add_stat(bonus, name, current["value"], "value", fairy)
                for index in range(1, min(5, int(current["baptism_level"])) + 1):
                    bonus["skills"].append(int(exclusive[f"skill{index}"]))
            for slot_iid in artifact["inlay"]:
                if not slot_iid:
                    continue
                qiling = qilings.get(str(slot_iid))
                spirit = (config["exclusive_device_spirit"].get(str(qiling["cid"]))
                          if isinstance(qiling, dict) else None)
                if not spirit:
                    continue
                amount = Fraction(str(spirit["value"]))
                qiling_level = int(qiling["level"])
                if qiling_level:
                    qtable = config["exclusive_device_spirit_intensify"].get(str(spirit["intensify_bonus_way"]), {})
                    row = qtable.get(str(qiling_level))
                    if row:
                        amount += Fraction(str(row["value"]))
                add_stat(bonus, spirit["attribute"], amount, spirit["method"], fairy)
                for pid, plevel, pvalue in qiling["attrs"]:
                    if not pid:
                        continue
                    prop = config["exclusive_device_spirit_random_properties"].get(str(pid))
                    if not prop:
                        continue
                    if int(prop["type"]) == 1:
                        add_stat(bonus, prop["attribute"], pvalue, prop["method"], fairy)
                    else:
                        skill = prop.get(f"intensify{plevel}") if plevel else None
                        skill = skill or prop.get("breakskill")
                        if skill:
                            bonus["skills"].append(int(skill))
            for suit_id in suit_ids(artifact, state, config):
                suit = config["exclusive_device_spirit_suit"].get(str(suit_id))
                if suit and suit.get("suit_skill"):
                    bonus["skills"].append(int(suit["suit_skill"]))
        except (KeyError, TypeError, ValueError, IndexError, ZeroDivisionError, OverflowError):
            continue
        bonus["skills"] = sorted({skill for skill in bonus["skills"]
                                  if skill in allowed and supported_skill(skill, config, dynamic)})
        result[iid] = bonus
    return result


def artifact_values(state, config, key):
    artifact = state["artifacts"][str(key)]
    return [int(key), artifact["cid"], artifact["level"], *artifact["inlay"], *suit_ids(artifact, state, config)]


def artifacts_reply(state, config, keys):
    values = []
    for key in keys:
        values.extend(artifact_values(state, config, key))
    return ids(values)


def qiling_values(key, qiling):
    values = [int(key), qiling["cid"], qiling["level"], qiling["success"], qiling["lock"]]
    for attr in qiling["attrs"]:
        values.extend(attr)
    return values


def qilings_reply(state, keys):
    return ids([value for key in keys for value in qiling_values(key, state["qilings"][str(key)])])


def weighted(entries, rng):
    if not entries or any(weight <= 0 for _, weight in entries) or sum(weight for _, weight in entries) <= 0:
        raise ValueError("专属神器随机权重配置无效")
    ticket = rng.randrange(sum(weight for _, weight in entries))
    for value, weight in entries:
        ticket -= weight
        if ticket < 0:
            return value
    raise ValueError("专属神器随机权重配置无效")


def spec_pairs(text, label, width=3):
    result = []
    for entry in str(text).strip(";").split(";"):
        if not entry:
            continue
        parts = entry.split(",")
        if len(parts) != width or any(not part.isdigit() for part in parts):
            raise ValueError(f"{label}配置无效")
        result.append(tuple(int(part) for part in parts))
    if not result:
        raise ValueError(f"{label}配置无效")
    return result


def create_qiling(state, cid, config, rng):
    row = table_row(config["exclusive_device_spirit"], cid, "器灵")
    location, quality = int(row["location"]), int(row["quality"])
    pool = config["exclusive_device_spirit_random_pool"].get(str(location), {})
    entry = pool.get(str(quality)) or (pool.get(max(pool, key=int)) if pool else None)
    candidates = spec_pairs(entry["random_pool"], "器灵随机属性", width=2) if entry else []
    attrs = []
    for _ in range(min(4, int(row.get("random_attribute_number", 0)))):
        pid = weighted(candidates, rng) if candidates else 0
        prop = config["exclusive_device_spirit_random_properties"].get(str(pid), {})
        low, high, step = (int(prop.get("minimum_attribute", 0)), int(prop.get("biggest_attribute", 0)),
                           max(1, int(prop.get("tolerance", 1))))
        value = rng.randrange(low, high + 1, step) if candidates and high >= low else 0
        attrs.append([pid, 0, value])
    attrs += [[0, 0, 0]] * (4 - len(attrs))
    state["serial"] += 1
    if state["serial"] >= 1 << 31:
        raise ValueError("器灵编号已耗尽")
    key = str(state["serial"])
    state["qilings"][key] = {"cid": int(cid), "level": 0, "success": 0, "lock": 0, "attrs": attrs}
    return state["serial"], int(cid)


def _rosters(save, point, config):
    return battle.rosters(save, battle.sanitize_breakthrough(dict(point), config), config)


def _fight(save, point, config, seed, name):
    attack, defense = _rosters(save, point, config)
    report = battle.simulate(attack, defense, config, seed, attack_pet=pets.combat(save, config),
                             attack_cheer=cheer.combat(save, config))
    report["meta"]["attack"]["n"] = save["role_name"]
    report["meta"]["defense"]["n"] = name
    return report


def soul_rows(config):
    return config["exclusive_device_soul_copy"]


def spirit_rows(config):
    return config["exclusive_device_spirit_copy"]


def soul_unlocked(save, state, config, copy_id):
    rows = soul_rows(config)
    row = rows.get(str(copy_id))
    if not row or save["role_state"]["level"] < int(row["open_level"]):
        return None
    if copy_id > 1 and state["soul"]["cleared"].get(str(copy_id - 1), 0) != 2:
        return None
    return row


def spirit_unlocked(save, state, config, group, difficulty):
    row = spirit_rows(config).get(str(group), {}).get(str(difficulty))
    if not row or save["role_state"]["level"] < int(row["open_level"]):
        return None
    cleared = state["spirit"]["cleared"].get(str(group), {})
    if difficulty > 1 and cleared.get(str(difficulty - 1), 0) != 1:
        return None
    return row


def soul_remaining(state, config, save):
    free = int(vip_row(save, config)["exclusive_copy"])
    return max(0, free + state["soul"]["bought"] - state["soul"]["used"])


def spirit_remaining(state, config, save, group):
    return max(0, int(vip_row(save, config)[SPIRIT_VIP_KEYS[group - 1]])
               - state["spirit"]["used"].get(str(group), 0))


def soul_drops(row, rng):
    specification = []
    for index in range(1, 5):
        probability = int(row[f"probability{index}"])
        if not 0 <= probability <= 100:
            raise ValueError("器魂副本掉落概率无效")
        for cid, low, high in spec_pairs(row[f"reward{index}"], "器魂副本掉落"):
            if rng.randrange(100) < probability and high >= low:
                specification.append((cid, rng.randint(low, high)))
    return ";".join(f"{cid},{count}" for cid, count in specification)


def spirit_drops(row, rng, state, config):
    """胜利按权重抽 1~N 枚器灵；返回 (材料规范, SomeThings.qiling 的 17 字段组)。"""
    if not 1 <= int(row["successful_minimum_number"]) <= int(row["successful_biggest_number"]):
        raise ValueError("器灵副本掉落数量无效")
    count = rng.randint(int(row["successful_minimum_number"]), int(row["successful_biggest_number"]))
    candidates = spec_pairs(row["successful_reward"], "器灵副本掉落")
    rows = []
    for _ in range(count):
        cid = weighted([(cid, weight) for cid, _, weight in candidates], rng)
        iid, _ = create_qiling(state, cid, config, rng)
        rows.append(qiling_values(iid, state["qilings"][str(iid)]))
    return "", rows


def failure_drops(row, rng):
    specification = []
    for cid, low, high in spec_pairs(row["failure_reward"], "器灵副本保底掉落"):
        if high >= low:
            specification.append((cid, rng.randint(low, high)))
    return ";".join(f"{cid},{count}" for cid, count in specification)


def query_artifacts(state, config, body):
    values = parse(body)
    if len(values) > 1:
        raise ValueError("专属神器查询参数无效")
    keys = [str(values[0])] if values and str(values[0]) in state["artifacts"] else ([] if values else sorted(state["artifacts"], key=int))
    return artifacts_reply(state, config, keys), b"", []


def query_qilings(state, body):
    require_empty(body, "器灵查询")
    return qilings_reply(state, sorted(state["qilings"], key=int)), b"", []


def query_active(state, body):
    require_empty(body, "激活挑战次数查询")
    values = [value for key, used in sorted(state["active"].items(), key=lambda item: int(item[0]))
              for value in (int(key), used)]
    return ids(values), b"", []


def query_copy(save, state, config, body):
    require_empty(body, "专属副本查询")
    rows = soul_rows(config)
    statuses = []
    for copy_id in sorted(map(int, rows)):
        unlocked = soul_unlocked(save, state, config, copy_id) is not None
        cleared = state["soul"]["cleared"].get(str(copy_id), 0)
        statuses.append(2 if cleared else (1 if unlocked else 0))
        if not statuses[-1]:
            break
    first = ids([soul_remaining(state, config, save), *statuses])
    numbers = [spirit_remaining(state, config, save, group) for group in range(1, SPIRIT_GROUPS + 1)]
    progress = []
    for group in range(1, SPIRIT_GROUPS + 1):
        for difficulty in range(1, DIFFICULTIES + 1):
            cleared = state["spirit"]["cleared"].get(str(group), {}).get(str(difficulty), 0)
            unlocked = spirit_unlocked(save, state, config, group, difficulty) is not None
            progress.append(1 if cleared or unlocked else 0)
    return comb(((1, first), (2, ids([*numbers, *progress])))), b"", []


def strengthen(save, state, config, body, now):
    general_iid, num = parse(body, 2)
    key = str(general_iid)
    artifact = state["artifacts"].get(key)
    if artifact is None:
        raise ValueError("专属神器尚未激活")
    if not 0 <= num <= MAX_STRENGTHEN:
        raise ValueError("专属神器强化次数无效")
    exclusive = table_row(config["exclusive"], artifact["cid"], "专属神器")
    table = config["exclusive_intensify"][str(exclusive["intensify_type"])]
    level = artifact["level"]
    if num == 0:
        current = table.get(str(level))
        if not current or int(current["intensify_level"]) != 0:
            raise ValueError("当前阶段不能洗礼")
        rows, next_level = [current], level + 1
    else:
        rows = []
        for step in range(1, num + 1):
            row = table.get(str(level + step))
            if not row or int(row["intensify_level"]) == 0:
                raise ValueError("已满级或强化不能跨越洗礼阶段")
            rows.append(row)
        next_level = level + num
    # 客户端 NetExclusiveArtifactStrengthenCallBack 会把紧邻的洗礼等级一并跳过，服务端同步口径。
    following = table.get(str(next_level + 1))
    if following and int(following["intensify_level"]) == 0:
        next_level = int(following["id"])
    costs = merge_costs(rows, "专属神器强化消耗")
    for cid, count in costs:
        artifact["spent"][str(cid)] = artifact["spent"].get(str(cid), 0) + count
    artifact["level"] = next_level
    state["checked_at"] = now
    return artifacts_reply(state, config, [key]), b"", costs


def activate(save, state, config, body, now, seed):
    general_iid = parse(body, 1)[0]
    key = str(general_iid)
    if key in state["artifacts"]:
        raise ValueError("专属神器已激活")
    row, on = general_config(save, config, general_iid)
    if int(row["quality"]) < 7 or not int(row.get("exclusive", 0)):
        raise ValueError("只有彩金伙伴可以激活专属神器")
    if not on:
        raise ValueError("请先将该伙伴上阵")
    exclusive = table_row(config["exclusive"], row["exclusive"], "专属神器")
    limit = int(vip_row(save, config)["exclusive_copy"])
    used = state["active"].get(key, 0)
    if used >= limit:
        raise ValueError("今日激活挑战次数已用完")
    copies = config["exclusive_copy"].get(str(exclusive["copy"]))
    if not isinstance(copies, dict) or not copies:
        raise ValueError("激活副本配置不存在")
    # 11 个 checkpoint 是同一场激活挑战的逐档配置；按已尝试次数取对应档，不跳过真实战斗。
    checkpoint = min(max(int(key) for key in copies), used + 1)
    point = copies.get(str(checkpoint))
    if not isinstance(point, dict):
        raise ValueError("激活副本配置不存在")
    state["active"][key] = used + 1
    report = _fight(save, point, config, seed, str(point["name"]))
    reward = activities.build_reward(save, "", config)
    changed = []
    if report["result"]:
        state["artifacts"][key] = {"cid": int(exclusive["id"]), "level": 0,
                                   "inlay": [0] * INLAY_SLOTS, "spent": {}}
        changed.append(key)
    state["checked_at"] = now
    return comb(((1, battle_result(report, reward)), (2, artifacts_reply(state, config, changed)))), b"", []


def inlay(save, state, config, body, now):
    general_iid, pos, qiling_iid = parse(body, 3)
    key = str(general_iid)
    artifact = state["artifacts"].get(key)
    if artifact is None:
        raise ValueError("专属神器尚未激活")
    if not 1 <= pos <= INLAY_SLOTS:
        raise ValueError("器灵孔位无效")
    if qiling_iid:
        qiling = state["qilings"].get(str(qiling_iid))
        if qiling is None:
            raise ValueError("器灵不存在")
        row = table_row(config["exclusive_device_spirit"], qiling["cid"], "器灵")
        if int(row["location"]) != pos:
            raise ValueError("器灵类型与孔位不符")
        if artifact["inlay"][pos - 1] == qiling_iid:
            raise ValueError("器灵已镶嵌在此孔位")
    changed = {key}
    if qiling_iid:
        for other_key, other in state["artifacts"].items():
            for index, worn in enumerate(other["inlay"]):
                if worn == qiling_iid:
                    other["inlay"][index] = 0
                    changed.add(other_key)
    artifact["inlay"][pos - 1] = qiling_iid
    state["checked_at"] = now
    return artifacts_reply(state, config, sorted(changed, key=int)), b"", []


def qiling_strengthen(save, state, config, body, now, seed):
    qiling_iid = parse(body, 1)[0]
    key = str(qiling_iid)
    qiling = state["qilings"].get(key)
    if qiling is None:
        raise ValueError("器灵不存在")
    row = table_row(config["exclusive_device_spirit"], qiling["cid"], "器灵")
    table = config["exclusive_device_spirit_intensify"][str(row["intensify_bonus_way"])]
    next_row = table.get(str(qiling["level"] + 1))
    if not next_row:
        raise ValueError("器灵已满级")
    chance = qiling["success"] or int(next_row["intensify_basis_chance"])
    rng = random.Random(seed)
    if rng.randrange(100) < chance:
        qiling["level"] += 1
        qiling["success"] = 0
    else:
        qiling["success"] = min(100, chance + int(next_row["intensify_increase_chance"]))
    state["checked_at"] = now
    return qilings_reply(state, [key]), b"", merge_costs([next_row], "器灵强化消耗")


def qiling_lock(save, state, config, body, now):
    qiling_iid, lock = parse(body, 2)
    key = str(qiling_iid)
    qiling = state["qilings"].get(key)
    if qiling is None or lock not in (0, 1):
        raise ValueError("器灵不存在或锁定参数无效")
    qiling["lock"] = lock
    state["checked_at"] = now
    return qilings_reply(state, [key]), b"", []


def qiling_refine(save, state, config, body, now):
    values = parse(body)
    if not 1 <= len(values) <= MAX_REFINE or len(set(values)) != len(values):
        raise ValueError("熔炼器灵数量无效")
    worn = {iid for artifact in state["artifacts"].values() for iid in artifact["inlay"] if iid}
    specification = Counter()
    for qiling_iid in values:
        key = str(qiling_iid)
        qiling = state["qilings"].get(key)
        if qiling is None or qiling["lock"] or qiling_iid in worn:
            raise ValueError("器灵不存在、已锁定或已镶嵌")
        row = table_row(config["exclusive_device_spirit"], qiling["cid"], "器灵")
        table = config["exclusive_device_spirit_intensify"][str(row["intensify_bonus_way"])]
        texts = [row["smelting_material"]]
        if qiling["level"]:
            texts.append(table[str(qiling["level"])]["return"])
        for text in texts:
            for cid, count in consumption(text, "器灵熔炼返还"):
                specification[cid] += count
    for qiling_iid in values:
        del state["qilings"][str(qiling_iid)]
    state["checked_at"] = now
    spec = ";".join(f"{cid},{count}" for cid, count in sorted(specification.items()))
    reward = activities.build_reward(save, spec, config)
    return reward, reward, []


def copy_fight(save, state, config, body, now, seed):
    values = parse(body)
    if len(values) == 1:
        copy_id = values[0]
        row = soul_unlocked(save, state, config, copy_id)
        if row is None or soul_remaining(state, config, save) <= 0:
            raise ValueError("器魂副本未解锁或挑战次数不足")
        state["soul"]["used"] += 1
        rng = random.Random(seed ^ 0x5A17)
        report = _fight(save, row, config, seed, str(row["name"]))
        spec = soul_drops(row, rng) if report["result"] else ""
        if report["result"]:
            state["soul"]["cleared"][str(copy_id)] = 2
        reward = activities.build_reward(save, spec, config)
        state["checked_at"] = now
        return battle_result(report, reward), reward, []
    if len(values) == 2:
        group, difficulty = values
        row = spirit_unlocked(save, state, config, group, difficulty)
        if (row is None or not 1 <= group <= SPIRIT_GROUPS or not 1 <= difficulty <= DIFFICULTIES
                or spirit_remaining(state, config, save, group) <= 0
                or save["role_state"]["stamina"] < int(row["physical"])):
            raise ValueError("器灵副本未解锁、次数或体力不足")
        state["spirit"]["used"][str(group)] = state["spirit"]["used"].get(str(group), 0) + 1
        rng = random.Random(seed ^ 0x71A9)
        report = _fight(save, row, config, seed, f'{row["name1"]} {row["name2"]}')
        if report["result"]:
            spec, qiling_rows = spirit_drops(row, rng, state, config)
            state["spirit"]["cleared"].setdefault(str(group), {})[str(difficulty)] = 1
        else:
            spec, qiling_rows = failure_drops(row, rng), []
        reward = display_reward(activities.build_reward(save, spec, config), qiling_rows)
        state["checked_at"] = now
        return battle_result(report, reward), reward, [(1002, int(row["physical"]))]
    raise ValueError("专属副本挑战参数无效")


def copy_sweep(save, state, config, body, now, seed):
    copy_id = parse(body, 1)[0]
    row = soul_unlocked(save, state, config, copy_id)
    if row is None or state["soul"]["cleared"].get(str(copy_id), 0) != 2:
        raise ValueError("器魂副本尚未通关，不能扫荡")
    if soul_remaining(state, config, save) <= 0:
        raise ValueError("器魂副本挑战次数不足")
    state["soul"]["used"] += 1
    reward = activities.build_reward(save, soul_drops(row, random.Random(seed ^ 0x5A17)), config)
    state["checked_at"] = now
    return reward, reward, []


def rebirth(save, state, config, body, now):
    general_iid = parse(body, 1)[0]
    key = str(general_iid)
    artifact = state["artifacts"].get(key)
    if artifact is None:
        raise ValueError("专属神器尚未激活")
    if not artifact["level"] and not any(artifact["inlay"]) and not artifact["spent"]:
        raise ValueError("专属神器没有可重生的养成记录")
    exclusive = table_row(config["exclusive"], artifact["cid"], "专属神器")
    table = config["exclusive_intensify"][str(exclusive["intensify_type"])]
    current = table.get(str(artifact["level"]))
    intensify_level = 0
    baptism_level = 0
    if current:
        baptism_level = int(current["baptism_level"])
        if int(current["intensify_level"]):
            intensify_level = int(current["intensify_level"])
        else:
            previous = table.get(str(artifact["level"] - 1))
            intensify_level = int(previous["intensify_level"]) if previous else 0
    renascence = config["renascence"]
    fee = (int(renascence[str(intensify_level)]["exclusive_intensify"])
           + int(renascence[str(baptism_level)]["exclusive_baptism"]))
    spec = ";".join(f"{cid},{count}" for cid, count in sorted((int(cid), count) for cid, count in artifact["spent"].items()))
    artifact.update(level=0, inlay=[0] * INLAY_SLOTS, spent={})
    state["checked_at"] = now
    reward = activities.build_reward(save, spec, config)
    return reward, reward, [(1025, fee)]


def buy_times(save, body, config, now):
    """7010 sysId=614：按 buycount_price 与 vip.device_soul 结算器魂挑战次数。"""
    require_open(save, config)
    values = parse(body, 2)
    sys_id, count = values
    if sys_id != BUY_SYS_ID or not 0 < count < 1 << 31:
        raise ValueError("器魂副本购买次数参数无效")
    state = settle(save, config, now)
    limit = int(vip_row(save, config)["device_soul"])
    bought = state["soul"]["bought"]
    if bought + count > limit:
        raise ValueError("今日可购买器魂挑战次数不足")
    prices = config["buycount_price"]
    ceiling = max(map(int, prices))
    price = sum(int(prices[str(min(index, ceiling))]["device_soul_copy_cost"])
                for index in range(bought + 1, bought + count + 1))
    if not 0 <= price < 1 << 31:
        raise ValueError("器魂副本购买价格无效")
    state["soul"]["bought"] += count
    state["checked_at"] = now
    return b"", b"", [(1025, price)]


def prepare(opcode, save, body, config, now, seed):
    """返回 (回包, 需要入账的奖励, 需要扣除的物品)；player 统一原子落盘。"""
    if opcode in QUERIES:
        # 8101/8105/8109 也是 999900 初始化 Comb 的空扩展：查询必须零写入。
        state = query_view(save, now)
        if opcode == 8101:
            return query_artifacts(state, config, body)
        if opcode == 8105:
            return query_qilings(state, body)
        if opcode == 8109:
            return query_active(state, body)
        return query_copy(save, state, config, body)
    require_open(save, config)
    state = settle(save, config, now)
    if opcode == 8102:
        return strengthen(save, state, config, body, now)
    if opcode == 8103:
        return activate(save, state, config, body, now, seed)
    if opcode == 8104:
        return inlay(save, state, config, body, now)
    if opcode == 8106:
        return qiling_strengthen(save, state, config, body, now, seed)
    if opcode == 8107:
        return qiling_lock(save, state, config, body, now)
    if opcode == 8108:
        return qiling_refine(save, state, config, body, now)
    if opcode == 8202:
        return copy_fight(save, state, config, body, now, seed)
    if opcode == 8203:
        return copy_sweep(save, state, config, body, now, seed)
    if opcode == 8204:
        return rebirth(save, state, config, body, now)
    raise ValueError("专属神器请求无效")


def buy_times_supported(body):
    """session 用来把 7010 sysId=614 纳入本地结算，不干扰 450 与录制兜底。"""
    try:
        return parse(body, 2)[0] == BUY_SYS_ID
    except ValueError:
        return False
