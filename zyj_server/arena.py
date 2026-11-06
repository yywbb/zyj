"""原配置 NPC 的独立竞技榜；排名、次数、积分与奖励随角色原子保存。"""

from fractions import Fraction
import json
import random

from . import activities, battle, cheer, pets, recharge
from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint


QUERIES = (1610, 1613, 1615)
BATTLES = (1611, 1616)
MUTATIONS = (*BATTLES, 1614)
OPCODES = (*QUERIES, *MUTATIONS)
NPC_RID = 2146600000  # 原生 npcRidlimit 以上，仍在有符号 int32 内。


def get_state(save, config):
    last = max(map(int, config["athletics_copy2"]))
    state = save.setdefault("arena_state", {"day": 0, "rank": last + 1, "points": 0, "used": 0,
                                          "bought": 0, "boss": 0, "first": [], "exchanged": {}})
    if (not isinstance(state, dict) or any(type(state.get(k)) is not int or not 0 <= state[k] < (1 << 31)
            for k in ("day", "rank", "points", "used", "bought", "boss"))
            or not 1 <= state["rank"] <= last + 1 or not isinstance(state.get("first"), list)
            or not isinstance(state.get("exchanged"), dict)):
        raise ValueError("竞技场存档无效")
    maximum = max(v["b_athletics"] for v in config["vip"].values())
    free = max(v["athletics"] for v in config["vip"].values())
    if (state["bought"] > maximum or state["used"] > free + state["bought"] * int(config["global_kv"]["athletics_once_times"]["value"])
            or not 0 <= state["boss"] <= min(5, state["used"])):
        raise ValueError("竞技场挑战次数存档无效")
    if (any(type(i) is not int or str(i) not in config["athletics_rewards3"]
            or state["rank"] > config["athletics_rewards3"][str(i)]["rank"] for i in state["first"])
            or len(set(state["first"])) != len(state["first"])):
        raise ValueError("竞技场首次排名奖励记录无效")
    for key, count in state["exchanged"].items():
        row = config["athletics_rewards2"].get(key)
        if (not row or type(count) is not int or not 0 <= count < (1 << 31)
                or row["limit"] and count > row["limit"]):
            raise ValueError("竞技场兑换次数存档无效")
    return state


def daily_reward(save, config, now):
    state = get_state(save, config)
    day = (now + 28800) // 86400
    specification = ""
    if day > state["day"]:
        if state["day"] and str(state["rank"]) in config["athletics_copy2"]:
            row = min((r for r in config["athletics_rewards"].values() if r["rank"] >= state["rank"]), key=lambda r: r["rank"])
            specification = row["day"]
        # shortcut: 离线多日只结算一份旧排名日奖；接入定时排名/邮件后再支持逐日历史。
        state.update(day=day, used=0, bought=0, boss=0, exchanged={})
    return activities.build_reward(save, specification, config) if specification else b""


def remaining(save, state, config):
    return max(0, config["vip"][str(save["role_state"]["vip"])]["athletics"]
               + state["bought"] * int(config["global_kv"]["athletics_once_times"]["value"]) - state["used"])


def opponents(rank, config):
    last = max(map(int, config["athletics_copy2"]))
    row = min((r for r in config["athletics_choice"].values() if r["rank"] >= rank), key=lambda r: r["rank"])
    step = row["interval"]
    # 固定候选让查询/重连不重抽目标；选择间隔取配置，随机偏移的官服算法未核实。
    return sorted({max(1, rank - 1), *(max(1, rank - step * i) for i in range(1, 6)),
                   *(min(last, rank + step * i) for i in (1, 2))} - {rank})


def query(save, state, config):
    role = save["role_state"]
    mine = b"".join(encode_pb_field(n, 0, value) for n, value in
                    ((1, state["points"]), (2, state["rank"]), (3, role["level"]),
                     (4, remaining(save, state, config)), (5, role["power"])))
    # 原生 my.params 的前两项是段位；第三项本地传已用 Boss 次数，不发送 UI 专属称号字段。
    mine += encode_pb_field(6, 2, b"".join(encode_pb_field(1, 2, encode_pb_field(1, 0, v)) for v in (0, 0, state["boss"])))
    targets = opponents(state["rank"], config)
    body = encode_pb_field(1, 2, mine)
    for rank in sorted({*range(1, 11), *targets, state["rank"]}):
        if rank == state["rank"]:
            name, level, power, icon, rid, status = (save["role_name"], role["level"], role["power"], role["profile"],
                                                    pb_get_varint(bytes.fromhex(save["role_snapshot"]), 1), 4)
        else:
            row = config["athletics_copy2"][str(rank)]
            name = row["name"] if row["name"].startswith("NPC") else "NPC·" + row["name"]
            level, power = row["level"], row["power"]
            icon = config["copy_monster"][str(row["p1"])]["generalid"]
            rid, status = NPC_RID + rank, int(rank in targets)
        raw = (encode_pb_field(1, 0, rank) + encode_pb_field(2, 2, name.encode("utf-8"))
               + b"".join(encode_pb_field(n, 0, v) for n, v in ((3, level), (4, status), (5, rid)))
               + encode_pb_field(6, 2, encode_pb_field(1, 0, icon)) + encode_pb_field(7, 0, power))
        body += encode_pb_field(2, 2, raw)
    return body


def rewrite_vip(body, save, config, now):
    state = get_state(save, config)
    current = (now + 28800) // 86400 <= state["day"]
    out, index = bytearray(), 0
    for n, w, value in iter_pb_fields(body):
        if (n, w) == (1, 0):
            index += 1
            if index in (1, 20):
                value = state["bought" if index == 1 else "boss"] if current else 0
        out.extend(encode_pb_field(n, w, value))
    return bytes(out)


def buy(save, count, quoted, config, now):
    state = get_state(save, config)
    if save["role_state"]["level"] < config["build"]["23"]["level"] or (now + 28800) // 86400 != state["day"]:
        raise ValueError("竞技场尚未解锁或服务器日期回拨")
    if state["bought"] + count > config["vip"][str(save["role_state"]["vip"])]["b_athletics"]:
        raise ValueError("竞技场今日购买次数不足")
    prices = config["buycount_price"]
    price = sum(prices[str(min(i, max(map(int, prices))))]["athletics"] for i in range(state["bought"] + 1, state["bought"] + count + 1))
    if quoted != price:
        raise ValueError("竞技场价格或每日次数已变化，请重新打开购买窗口")
    state["bought"] += count
    return price


def rosters(save, row, config):
    point = dict(row)
    for i in range(1, 8):
        for name in ("adddmgpct", "subdmgpct"):
            point.setdefault(f"{name}{i}-correct", 0)
    return battle.rosters(save, point, config, illusion_mode="pvp")


def prepare(opcode, save, body, config, now, seed):
    if not save.get("has_role") or save["role_state"]["level"] < config["build"]["23"]["level"]:
        raise ValueError("竞技场尚未解锁")
    state = get_state(save, config)
    if opcode in QUERIES:
        if body:
            raise ValueError("竞技场查询不接受参数")
        if opcode == 1610:
            return query(save, state, config), [], b""
        values = ([state["exchanged"].get(str(i), 0) for i in range(1, max(map(int, config["athletics_rewards2"])) + 1)]
                  if opcode == 1613 else [int(row["id"] in state["first"]) for row in sorted(config["athletics_rewards3"].values(), key=lambda r: r["rank"])])
        return recharge.ids(values), [], b""
    if (now + 28800) // 86400 != state["day"]:
        raise ValueError("服务器日期回拨，请稍后进行竞技场操作")
    fields = list(iter_pb_fields(body))
    if opcode == 1614:
        if len(fields) != 2 or any((n, w) != (1, 0) or not 0 < v < (1 << 31) for n, w, v in fields):
            raise ValueError("竞技场兑换需要物品及数量")
        item, count = (v for _, _, v in fields)
        row = config["athletics_rewards2"].get(str(item))
        if not row or not 1 <= count <= 100 or row["buttontype"] != 1:
            raise ValueError("竞技场兑换物品或数量无效")
        used = state["exchanged"].get(str(item), 0)
        if (save["role_state"]["level"] < max(row["lv"], row["display_level"])
                or row["rank"] and state["rank"] > row["rank"] or row["limit"] and used + count > row["limit"]):
            raise ValueError("竞技场兑换等级、排名或今日次数不足")
        reward = activities.build_reward(save, row["reward"], config, count)
        state["exchanged"][str(item)] = used + count
        return reward, [(1005, row["prestige"] * count)], reward
    if remaining(save, state, config) <= 0:
        raise ValueError("竞技场今日挑战次数不足")
    if opcode == 1616:
        maximum = int(config["global_kv"].get(f'athletics_top_{state["rank"]}_boss', {"value": "0"})["value"])
        if body or not maximum or state["boss"] >= maximum:
            raise ValueError("牛魔王需要竞技前五名及剩余挑战次数，且不接受参数")
        row, target = config["athletics_npc"]["50001"], 50001
    else:
        if len(fields) != 1 or fields[0][:2] != (1, 0) or fields[0][2] not in opponents(state["rank"], config):
            raise ValueError("请选择当前竞技榜中可挑战的NPC")
        target = fields[0][2]
        row = config["athletics_copy2"][str(target)]
    attack, defense = rosters(save, row, config)
    report = battle.simulate(attack, defense, config, seed, attack_pet=pets.combat(save, config), attack_cheer=cheer.combat(save, config, illusion_mode="pvp"))
    report["meta"]["attack"]["n"] = save["role_name"]
    report["meta"]["defense"]["n"] = row.get("name", "NPC牛魔王")
    state["used"] += 1
    if opcode == 1616:
        state["boss"] += 1
    specification = ""
    if report["result"]:
        if opcode == 1611:
            state["rank"] = min(state["rank"], target)
            specification = config["global_kv"]["athletics_suc_awards"]["value"]
            for first in sorted(config["athletics_rewards3"].values(), key=lambda r: r["rank"]):
                if state["rank"] <= first["rank"] and first["id"] not in state["first"]:
                    specification += ";" + first["reward"]
                    state["first"].append(first["id"])
        else:
            probability = Fraction(str(row["dropprob"]))
            if not 0 <= probability <= 1:
                raise ValueError("牛魔王掉落概率无效")
            specification = row["reward"]
            if random.Random(seed ^ 0xD09).random() < probability:
                specification += f';{row["drop"]},1;'
    reward = activities.build_reward(save, specification, config) if specification else b""
    save["last_arena_battle"] = {"rules": report["rules"], "seed": seed, "target": target,
                                  "won": report["result"], "star": report["star"], "rounds": report["round"]}
    response = (encode_pb_field(1, 0, int(report["result"])) + encode_pb_field(2, 0, report["star"])
                + encode_pb_field(4, 2, reward)
                + encode_pb_field(5, 2, json.dumps(report, ensure_ascii=False, separators=(",", ":")).encode("utf-8")))
    return response, [], reward
