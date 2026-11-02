"""活动副本的开放日、逐级挑战与奖励；不推进展示引导或改动普通主线。"""

from fractions import Fraction
import json
import random

from . import activities, battle, cheer, magic, pets, recharge
from .protocol import encode_pb_field, iter_pb_fields


QUERIES = (1340,)
BATTLES = (1341, 1342, 1343, 1344, 1345, 1347)
# aid: 配置表、挑战协议、功能入口、每日基础次数字段。
COPIES = {1: ("exp_copy", 1342, 157, "exp_copy_times"),
          2: ("coin_copy", 1341, 157, "coin_copy_times"),
          3: ("stone_copy", 1343, 173, "stone_copy_times"),
          4: ("upstar_huodong", 1344, 206, "upstar_times"),
          5: ("zhenfu_huodong", 1345, 207, "zhenfu_times"),
          6: ("forging_copy", 1347, 389, "forging_copy_times")}
BOSSES = (2, 4, 5)


def get_state(save, config):
    state = save.setdefault("activity_copy_state", {"day": 0, "copies": {
        str(aid): {"cleared": 0, "used": 0, "tried": 0} for aid in COPIES}})
    if (not isinstance(state, dict) or type(state.get("day")) is not int or not 0 <= state["day"] < (1 << 31)
            or not isinstance(state.get("copies"), dict) or set(state["copies"]) != set(map(str, COPIES))):
        raise ValueError("活动副本存档无效")
    for aid, (table, _, _, limit) in COPIES.items():
        row = state["copies"][str(aid)]
        if (not isinstance(row, dict) or any(type(row.get(k)) is not int for k in ("cleared", "used", "tried"))
                or not 0 <= row["cleared"] <= len(config[table])
                or not row["cleared"] <= row["tried"] <= min(row["cleared"] + 1, len(config[table]))
                or not 0 <= row["used"] <= config["vip"]["0"][limit]):
            raise ValueError("活动副本进度或次数无效")
    return state


def settle(save, config, now):
    state = get_state(save, config)
    day = (now + 28800) // 86400
    if day > state["day"]:
        state["day"] = day
        for row in state["copies"].values():
            row["used"] = 0
    return state


def open_copies(state, config):
    weekday = (state["day"] + 3) % 7 + 1
    return [aid for aid in COPIES if weekday in map(int, config["daily_function"][str(aid)]["date"].strip(";").split(";"))]


def query(save, state, config):
    values = []
    for aid in open_copies(state, config):
        row = state["copies"][str(aid)]
        table = config[COPIES[aid][0]]
        eligible = max((int(pid) for pid, point in table.items() if point["monster_level"] <= save["role_state"]["level"]), default=1)
        opened = min(row["cleared"] + 1, eligible)
        values.extend((aid, row["used"], opened, int(row["tried"] < opened), row["cleared"]))
    return recharge.ids(values)


def rosters(save, aid, difficulty, config):
    row = config[COPIES[aid][0]][str(difficulty)]
    point = dict(row, level=row["monster_level"])
    if aid in BOSSES:
        cid = str(row["monster_id"])
        monster = config["huodong_monster"][cid]
        general = dict(monster, skillid=monster["skill1"], combskillid=0, init_cid=0)
        npc = dict(monster, generalid=monster["id"], skilllevel=0,
                   **{f"{name}-grow": 0 for name in ("atk", "def", "hp", "speed")})
        # 与原生战报转换器一样加载活动Boss模板，不改共享配置或替换其CID。
        config = {**config, "general": {**config["general"], cid: general},
                  "copy_monster": {**config["copy_monster"], cid: npc}}
        for i in range(1, 8):
            point.update({f"p{i}": monster["id"] if i == 1 else 0, f"p{i}-type": 2 if i == 1 else 0,
                          f"p{i}-grow": row["p1-grow"] if i == 1 else 0, f"break{i}-correct": 0, f"mozhao{i}_lv": 0})
        for name in ("atk", "def", "hp"):
            point[f"{name}1-correct"] = row[f"{name}-correct"]
    for i in range(1, 8):
        for name in ("adddmgpct", "subdmgpct"):
            point.setdefault(f"{name}{i}-correct", 0)
    attack, defense = battle.rosters(save, point, config)
    return attack, defense, config


def reward(save, aid, difficulty, percent, config, day, seed):
    row, rng = config[COPIES[aid][0]][str(difficulty)], random.Random(seed ^ 0xD09)
    prizes = []
    if aid in BOSSES:
        prizes = [tuple(map(int, entry.split(","))) for entry in row[f"{percent // 10 * 10}_reward"].split(";") if entry]
    else:
        for i in range(1, 5):
            cid, probability, low, high = (row[f"drop{i}{suffix}"] for suffix in ("", "prob1", "section1", "section2"))
            if (any(type(v) is not int for v in (cid, probability, low, high))
                    or not 0 <= cid < (1 << 31) or not 0 <= probability <= 100
                    or cid and not 0 < low <= high < (1 << 31)):
                raise ValueError("活动副本掉落配置无效")
            if cid and rng.randrange(100) < probability:
                prizes.append((cid, rng.randint(low, high)))
    weekday = (day + 3) % 7 + 1
    rows = [r for r in config["activity_huodong"].values() if r["param"] == 6 and r["open_time"] == weekday]
    factor = Fraction(str(rows[0]["modulus"])) if rows else Fraction(1)
    return activities.build_reward(save, ";".join(f"{cid},{int(count * factor)}" for cid, count in prizes), config)


def prepare(opcode, save, body, config, now, seed):
    if not save.get("has_role") or save["role_state"]["level"] < config["build"]["157"]["level"]:
        raise ValueError("活动副本尚未解锁")
    state = settle(save, config, now)
    if opcode == 1340:
        if body:
            raise ValueError("活动副本查询不接受参数")
        return query(save, state, config), b""
    fields = list(iter_pb_fields(body))
    if len(fields) != 1 or fields[0][:2] != (1, 0) or not 0 < fields[0][2] < (1 << 31):
        raise ValueError("活动副本挑战需要一个有效难度")
    if (now + 28800) // 86400 < state["day"]:
        raise ValueError("服务器日期回拨，请稍后挑战活动副本")
    aid = next(aid for aid, (_, mid, _, _) in COPIES.items() if mid == opcode)
    table, _, build, limit = COPIES[aid]
    difficulty = fields[0][2]
    point = config[table].get(str(difficulty))
    row = state["copies"][str(aid)]
    if aid not in open_copies(state, config):
        raise ValueError("未到活动副本开放日")
    if (not point or save["role_state"]["level"] < max(config["build"][str(build)]["level"], point["monster_level"])
            or difficulty > row["cleared"] + 1):
        raise ValueError("活动副本难度尚未解锁")
    if row["used"] >= config["vip"]["0"][limit]:
        raise ValueError("活动副本今日挑战次数已用完")
    attack, defense, combat_config = rosters(save, aid, difficulty, config)
    report = battle.simulate(attack, defense, combat_config, seed, attack_pet=pets.combat(save, config), attack_cheer=cheer.combat(save, config),
                             max_rounds=point["battle_times"] if aid in BOSSES else battle.MAX_ROUNDS)
    report["meta"]["attack"]["n"] = save["role_name"]
    report["meta"]["defense"]["n"] = point["name"]
    initial = sum(unit["j"] for unit in report["meta"]["defense"]["g"].values())
    remaining = sum(unit["h"] for unit in report["endmeta"]["defense"].values())
    percent = (initial - remaining) * 100 // initial
    prize = reward(save, aid, difficulty, percent, config, state["day"], seed) if aid in BOSSES or report["result"] else b""
    row["tried"] = max(row["tried"], difficulty)
    if aid in BOSSES or report["result"]:
        row["used"] += 1
    if report["result"]:
        row["cleared"] = max(row["cleared"], difficulty)
    save["last_activity_battle"] = {"rules": report["rules"], "seed": seed, "aid": aid, "difficulty": difficulty,
                                     "won": report["result"], "rounds": report["round"], "damage_percent": percent}
    if aid == 3:
        magic.record_count(save, "stone_copy", 1, config)
    response = (encode_pb_field(1, 0, int(report["result"])) + encode_pb_field(2, 0, report["star"])
                + encode_pb_field(4, 2, prize)
                + encode_pb_field(5, 2, json.dumps(report, ensure_ascii=False, separators=(",", ":")).encode("utf-8")))
    return response, prize
