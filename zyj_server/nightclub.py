"""天庭银座：真实挑战、伙伴派驻、冻结产出与一次性事件。"""

from collections import Counter
import random

from . import activities, battle, cheer, development, formation, pets, recruit
from .guild_boss import battle_result
from .guild_games import pairs
from .penglai import comb
from .protocol import encode_pb_field, pb_get_varint
from .recharge import ids

QUERIES = (4500, 4501, 4511)
MUTATIONS = (4502, 4503, 4504, 4505, 4509, 4510)
OPCODES = QUERIES + MUTATIONS


def get_state(save, config):
    state = save.get("nightclub_state", {"cleared": [], "jobs": {}, "checked_at": 0})
    try:
        if (not isinstance(state["cleared"], list) or any(type(v) is not int for v in state["cleared"]) or state["cleared"] != list(range(1, len(state["cleared"]) + 1))
                or len(state["cleared"]) > len(config["tiantingyz_guanqia"]) or not isinstance(state["jobs"], dict)
                or type(state["checked_at"]) is not int or not 0 <= state["checked_at"] < (1 << 63)):
            raise ValueError
        seen = set()
        roster = formation.records(bytes.fromhex(save["world_state"]["1002"]), 1, 2)
        for floor, job in state["jobs"].items():
            if floor != str(int(floor)) or int(floor) not in state["cleared"]:
                raise ValueError
            time = config["tiantingyz_time"][str(job["time"])]
            if (any(type(job[k]) is not int or not 0 < job[k] < (1 << 31) for k in ("iid", "cid", "start", "end", "time"))
                    or job["iid"] not in roster or job["end"] != job["start"] + time["time"] * 3600
                    or type(job["event"]) is not int or job["event"] and str(job["event"]) not in config["tiantingyz_guanqia"][floor]["event_id"].split(";")
                    or type(job["resolved"]) is not bool or type(job["double"]) is not bool
                    or not job["event"] and not job["resolved"]
                    or job["double"] and (not job["resolved"] or not job["event"] or not config["tiantingyz_sjtype"][str(job["event"])]["double"])):
                raise ValueError
            general = config["general"][str(pb_get_varint(roster[job["iid"]], 1))]
            if job["cid"] != general["init_cid"] or job["cid"] in seen:
                raise ValueError
            seen.add(job["cid"])
            ticks = job["ticks"]
            if not isinstance(ticks, list) or len(ticks) != time["time"] * 60 // time["income_time"]:
                raise ValueError
            allowed = {int(v) for key in (f'drop{time["type"]}_low', f'drop{time["type"]}_up')
                       for v in config["tiantingyz_guanqia"][floor][key].split(";") if v}
            for soul, drops in ticks:
                if type(soul) is not int or not time["soul_small"] <= soul <= time["soul_big"] or not isinstance(drops, list) or len(drops) > 2:
                    raise ValueError
                for text, drop in drops:
                    if (type(text) is not int or str(text) not in config["tiantingyz_zhanbao"] or type(drop) is not int
                            or drop not in allowed or config["tiantingyz_diaoluo"][str(drop)]["random"] <= 0):
                        raise ValueError
    except (KeyError, TypeError, ValueError, AttributeError):
        raise ValueError("天庭银座派驻或产出存档无效") from None
    return state


def status(state, floor, save, config, now):
    row = config["tiantingyz_guanqia"][str(floor)]
    job = state["jobs"].get(str(floor))
    if not job:
        available = save["role_state"]["level"] >= row["level"] and row["open_lv"] <= len(state["cleared"])
        return ids([2 if floor in state["cleared"] else int(available), 0, 0, 0, 0, 0, 0, 0])
    interval = config["tiantingyz_time"][str(job["time"])]["income_time"] * 60
    ticks = job["ticks"][:max(0, min(now, job["end"]) - job["start"]) // interval]
    return ids([3 if now < job["end"] else 4, 0 if job["resolved"] else job["event"], int(job["double"]), job["time"],
                job["iid"], max(0, job["end"] - now), job["start"], sum(t[0] for t in ticks) * (2 if job["double"] else 1),
                *(v for _, drops in ticks for pair in drops for v in pair)])


def simulate(save, floor, config, seed):
    point = dict(config["tiantingyz_guanqia"][str(floor)])
    point["level"] = point["monster_level"]
    for i in range(1, 8):
        point[f"adddmgpct{i}-correct"] = point[f"subdmgpct{i}-correct"] = 0
    attack, defense = battle.rosters(save, point, config)
    return battle.simulate(attack, defense, config, seed, attack_pet=pets.combat(save, config), attack_cheer=cheer.combat(save, config))


def pick(text, config, rng):
    rows = [config["tiantingyz_diaoluo"][key] for key in text.strip(";").split(";")]
    if any(type(r["random"]) is not int or r["random"] < 0 for r in rows) or sum(r["random"] for r in rows) <= 0:
        raise ValueError("银座产出权重配置无效")
    ticket = rng.randrange(sum(r["random"] for r in rows))
    for row in rows:
        ticket -= row["random"]
        if ticket < 0:
            return row["id"]


def dispatch(state, floor, time_id, iid, save, config, now, rng):
    row, time = config["tiantingyz_guanqia"].get(str(floor)), config["tiantingyz_time"].get(str(time_id))
    if not row or not time or floor not in state["cleared"] or str(floor) in state["jobs"] or save["role_state"]["level"] < row["level"]:
        raise ValueError("该楼层未解锁或仍有派驻收益待领取")
    if time["type"] != 1 and save["role_state"]["vip"] < time["vip_level"]:
        raise ValueError("银座训练档位VIP不足")
    roster = formation.records(bytes.fromhex(save["world_state"]["1002"]), 1, 2)
    raw = roster.get(iid)
    general = config["general"].get(str(pb_get_varint(raw or b"", 1)), {})
    if (not raw or general.get("actor") == "lead" or not general.get("battle")
            or not general.get("init_cid") or general.get("partner_id")
            or any(j["cid"] == general["init_cid"] for j in state["jobs"].values())):
        raise ValueError("伙伴不属于本人、已派驻或含未实现的高级数据")
    if general["init_cid"] != pb_get_varint(raw, 1) or any(pb_get_varint(raw, n) for n in range(21, 41)):
        from . import partner_growth
        partner_growth.validate(raw, config)
    if len([r for r in config["general_fragment"].values() if r["general"] == general["init_cid"]]) != 1:
        raise ValueError("该伙伴没有唯一魂魄配置")
    ticks, texts = [], [int(v) for v in row["text_id"].split(";") if v]
    # 本地抽样：每周期魂魄均匀；random1%普通掉落、drop_num%×random2%额外掉落，权重0禁用。
    for _ in range(time["time"] * 60 // time["income_time"]):
        drops = []
        if rng.randrange(100) < time["random1"]:
            drops.append([rng.choice(texts), pick(row[f'drop{time["type"]}_low'], config, rng)])
        if rng.randrange(100) < row["drop_num"] and rng.randrange(100) < time["random2"]:
            drops.append([rng.choice(texts), pick(row[f'drop{time["type"]}_up'], config, rng)])
        ticks.append([rng.randint(time["soul_small"], time["soul_big"]), drops])
    event = rng.choice([int(v) for v in row["event_id"].split(";") if v]) if rng.randrange(100) < row["event_prob"] else 0
    state["jobs"][str(floor)] = {"time": time_id, "iid": iid, "cid": general["init_cid"], "start": now,
        "end": now + time["time"] * 3600, "event": event, "resolved": not bool(event), "double": False, "ticks": ticks}
    activities.record_liveness(save, 27, 1, config, now)
    return (1003, time["murderous"]) if time["type"] == 1 else (1001, time["Ingots"])


def claim(state, floors, config, now):
    gets = Counter()
    for floor, started in floors:
        job = state["jobs"].get(str(floor))
        if not job or job["start"] != started or job["end"] > now or not job["resolved"]:
            raise ValueError("训练尚未结束或事件未处理，不能领取")
        fragment = next(r["id"] for r in config["general_fragment"].values() if r["general"] == job["cid"])
        multiplier = 2 if job["double"] else 1
        gets[fragment] += sum(t[0] for t in job["ticks"]) * multiplier
        for _, drops in job["ticks"]:
            for _, drop in drops:
                for cid, count in pairs(config["tiantingyz_diaoluo"][str(drop)]["item"]).items():
                    gets[cid] += count * multiplier
        del state["jobs"][str(floor)]
    return sorted(gets.items())


def prepare(opcode, save, body, config, now, seed):
    values = development.ids(body)
    count = {4500: 0, 4501: 1, 4502: 1, 4503: 3, 4504: 2, 4505: 4, 4509: 11, 4511: 0}.get(opcode)
    if count is not None and len(values) != count or opcode == 4510 and (not 2 <= len(values) <= 20 or len(values) % 2 or len(set(values[::2])) != len(values[::2])):
        raise ValueError("银座请求参数数量错误")
    if (not save.get("has_role") or save["role_state"]["level"] < config["build"]["211"]["level"]
            or save.get("guide", {}).get("sections", {}).get("1", {}).get("status") != 2):
        raise ValueError("天庭银座尚未解锁")
    state, rng = get_state(save, config), random.Random(seed)
    if opcode in MUTATIONS and now < state["checked_at"]:
        raise ValueError("银座时钟发生回拨，请稍后重试")
    now = max(now, state["checked_at"])
    floor = values[0] if values and opcode not in (4509, 4510) else 0
    if floor and str(floor) not in config["tiantingyz_guanqia"] or values and opcode not in (4509, 4510) and not floor:
        raise ValueError("银座楼层无效")
    costs, gets = [], []
    if opcode in (4500, 4511):
        rows = [(i, status(state, i, save, config, now)) for i in range(1, 11)]
        return comb(([(0, b"")] if opcode == 4511 else []) + rows), [], b""
    if opcode == 4501:
        return status(state, floor, save, config, now), [], b""
    if opcode == 4502:
        row = config["tiantingyz_guanqia"][str(floor)]
        if floor != len(state["cleared"]) + 1 or save["role_state"]["level"] < row["level"]:
            raise ValueError("银座挑战需要逐层解锁并达到等级")
        report = simulate(save, floor, config, rng.getrandbits(64))
        if report["result"]:
            state["cleared"].append(floor)
            gets = list(pairs(row["item"]).items())
        save["last_nightclub_battle"] = {"floor": floor, "seed": report["seed"], "won": report["result"]}
        reward = recruit.build_reward(save, gets, config)
        reply = comb([(0, status(state, floor, save, config, now)), (1, battle_result(report, reward))])
    elif opcode in (4503, 4509):
        jobs = [(floor, values[2])] if opcode == 4503 else [(i, iid) for i, iid in enumerate(values[1:], 1) if iid]
        if not jobs:
            raise ValueError("请至少选择一位派驻伙伴")
        time = values[1] if opcode == 4503 else values[0]
        for selected, iid in jobs:
            costs.append(dispatch(state, selected, time, iid, save, config, now, rng))
        reply = status(state, floor, save, config, now) if opcode == 4503 else comb([(i, status(state, i, save, config, now)) for i in range(1, 11)])
        reward = b""
    elif opcode in (4504, 4510):
        gets = claim(state, list(zip(values[::2], values[1::2])), config, now)
        reply = reward = recruit.build_reward(save, gets, config)
    else:
        job = state["jobs"].get(str(floor))
        if not job or job["resolved"] or values[1] not in (0, 1) or values[2:] != [job["event"], job["start"]]:
            raise ValueError("当前没有可处理的银座事件")
        event, choose = config["tiantingyz_sjtype"][str(job["event"])], values[1]
        report = simulate(save, floor, config, rng.getrandbits(64)) if choose and event["fighting"] else None
        if choose:
            costs = list(pairs(event["cost"]).items())
        successful = choose and (report is None or report["result"])
        gets = list(pairs(event["bonus1" if successful else "bonus2"]).items())
        job.update(resolved=True, double=bool(successful and event["double"]))
        reward = recruit.build_reward(save, gets, config)
        reply = battle_result(report, reward) if report else encode_pb_field(1, 0, (1 << 64) - 1) + encode_pb_field(4, 2, reward)
    state["checked_at"] = now
    save["nightclub_state"] = state
    get_state(save, config)
    return reply, costs, reward
