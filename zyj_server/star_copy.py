"""名将副本：全 62 章配置解锁、每日胜利次数、首通掉落与每关一次通关箱。

1350 是业务 Comb（0 号行总胜利次数，地图行是 ``[map,status,point,pointstatus,boxstatus,...]``）；
1351 按原生 BattleResult 回战报/奖励；1352 按原生 SomeThings 回通关箱奖励。
所有进度、次数、宝箱与奖励在深拷贝上准备，一次原子保存成功后才发包。
"""

import json
import random

from . import activities, battle, cheer, formation, pets, recharge
from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint


QUERIES = (1350,)
MUTATIONS = (1351, 1352)
OPCODES = (*QUERIES, *MUTATIONS)


def get_state(save, config):
    state = save.setdefault("star_copy_state", {"day": 0, "progress": {}, "wins": {}, "boxes": []})
    if (not isinstance(state, dict) or type(state.get("day")) is not int
            or not 0 <= state["day"] < (1 << 31)
            or not isinstance(state.get("progress"), dict) or not isinstance(state.get("wins"), dict)):
        raise ValueError("名将副本存档无效")
    # boxes 是后加字段；旧档没有时按空列表解释，不覆盖已有通关/次数历史。
    boxes = state.get("boxes", [])
    if not isinstance(boxes, list) or len(set(map(repr, boxes))) != len(boxes):
        raise ValueError("名将副本通关箱记录无效")
    for mid, point in state["progress"].items():
        if (mid not in config["star_copy"] or type(point) is not int
                or str(point) not in config["star_copy"][mid]):
            raise ValueError("名将副本通关记录无效")
    for key, count in state["wins"].items():
        parts = key.split("/")
        if (len(parts) != 2 or parts[0] not in config["star_copy"]
                or parts[1] not in config["star_copy"][parts[0]] or type(count) is not int
                or not 0 < count <= config["star_copy"][parts[0]][parts[1]]["challenge"]
                or int(parts[1]) > state["progress"].get(parts[0], 0)):
            raise ValueError("名将副本胜利次数无效")
    for key in boxes:
        parts = key.split("/") if type(key) is str else []
        if (len(parts) != 2 or parts[0] not in config["star_copy"]
                or parts[1] not in config["star_copy"][parts[0]]
                or int(parts[1]) > state["progress"].get(parts[0], 0)
                or not config["star_copy"][parts[0]][parts[1]].get("receive")):
            raise ValueError("名将副本通关箱记录无效")
    return state


def boxes(state):
    return state.get("boxes", [])


def settle(save, config, now):
    state = get_state(save, config)
    day = (now + 8 * 3600) // 86400
    if day > state["day"]:
        state.update(day=day, wins={})
    return state


def unlocked(save, config):
    """按角色等级与 build148 判定名将副本是否开放；查询不拒绝，只影响可选状态。"""
    return bool(save.get("has_role") and save["role_state"]["level"] >= config["build"]["148"]["level"])


def available_maps(save, config):
    """全 62 章按各自 ``star_map.condition`` 对应普通地图全三星解锁。"""
    copies = formation.records(bytes.fromhex(save["world_state"]["1300"]), 1, 1)
    available = set()
    for mid in sorted(config["star_map"], key=int):
        condition = config["star_map"][mid]["condition"]
        points = formation.records(copies.get(condition, b""), 7, 1)
        if all(pb_get_varint(points.get(int(pid), b""), 3) for pid in config["copy"][str(condition)]):
            available.add(mid)
    return available


def query(save, body, config, now):
    if body:
        raise ValueError("名将副本查询不接受参数")
    state = settle(save, config, now)
    available = available_maps(save, config)
    claimed = set(boxes(state))
    rows = [(0, [sum(state["wins"].values())])]
    for mid in sorted(config["star_map"], key=int):
        points = config["star_copy"][mid]
        progress = state["progress"].get(mid, 0)
        values = [int(mid), int(progress == max(map(int, points))) if mid in available else -1]
        if mid in available:
            for pid in sorted(points, key=int):
                if int(pid) <= progress + 1:
                    key = f"{mid}/{pid}"
                    box = (2 if key in claimed else
                           1 if int(pid) <= progress and points[pid].get("receive") else 0)
                    values.extend((int(pid), state["wins"].get(key, 0) if int(pid) <= progress else -1, box))
        rows.append((int(mid), values))
    # 业务 Comb 的0号行是总次数，不改变顶层999900的正ID校验。
    return b"".join(encode_pb_field(1, 2, encode_pb_field(1, 0, mid)
                                 + encode_pb_field(2, 2, recharge.ids(v & ((1 << 64) - 1) for v in values)))
                    for mid, values in rows)


def _point_ids(body):
    fields = list(iter_pb_fields(body))
    if len(fields) != 2 or any(n != 1 or w != 0 or not 0 < v < (1 << 31) for n, w, v in fields):
        raise ValueError("名将副本参数无效")
    return tuple(str(v) for _, _, v in fields)


def fight(save, body, config, now, seed):
    mid, pid = _point_ids(body)
    point = config["star_copy"].get(mid, {}).get(pid)
    if not unlocked(save, config):
        raise ValueError("名将副本尚未解锁")
    state = settle(save, config, now)
    progress = state["progress"].get(mid, 0)
    if not point or mid not in available_maps(save, config) or int(pid) > progress + 1:
        raise ValueError("名将副本关卡尚未解锁")
    key = f"{mid}/{pid}"
    if (sum(state["wins"].values()) >= int(config["global_kv"]["star_copy_times"]["value"])
            or state["wins"].get(key, 0) >= point["challenge"]):
        raise ValueError("名将副本今日可战胜次数已用完")
    # 15 个后期关卡的 NPC break9 引用未实现的 ap/target=6 静态行，按共享白名单逐档收敛。
    attack, defense = battle.rosters(save, battle.sanitize_breakthrough(dict(point), config), config)
    report = battle.simulate(attack, defense, config, seed, attack_pet=pets.combat(save, config), attack_cheer=cheer.combat(save, config))
    report["meta"]["attack"]["n"] = save["role_name"]
    report["meta"]["defense"]["n"] = point["name"]
    rewards, rng = [], random.Random(seed ^ 0xD09)
    if report["result"]:
        drops = [(point[f"drop{i}"], point[f"drop{i}number"], point[f"drop{i}prob"]) for i in range(1, 6)]
        if int(pid) > progress:
            drops.insert(0, (point["drop_no1"], point["drop1number_no1"], point["drop1prob_no1"]))
        for cid, count, probability in drops:
            if not 0 <= cid < (1 << 31) or not 0 <= probability <= 100 or (cid and not 0 < count < (1 << 31)):
                raise ValueError("名将副本掉落配置无效")
            if cid and rng.randrange(100) < probability:
                rewards.append((cid, count))
        state["progress"][mid] = max(progress, int(pid))
        state["wins"][key] = state["wins"].get(key, 0) + 1
    reward = activities.build_reward(save, ";".join(f"{cid},{count}" for cid, count in rewards), config)
    save["last_star_battle"] = {"rules": report["rules"], "seed": seed, "map": int(mid), "point": int(pid),
                                "won": report["result"], "star": report["star"], "rounds": report["round"]}
    response = (encode_pb_field(1, 0, int(report["result"])) + encode_pb_field(2, 0, report["star"])
                + encode_pb_field(4, 2, reward)
                + encode_pb_field(5, 2, json.dumps(report, ensure_ascii=False, separators=(",", ":")).encode("utf-8")))
    return response, reward


def claim_box(save, body, config, now):
    mid, pid = _point_ids(body)
    point = config["star_copy"].get(mid, {}).get(pid)
    if not unlocked(save, config):
        raise ValueError("名将副本尚未解锁")
    state = settle(save, config, now)
    key = f"{mid}/{pid}"
    if (not point or not point.get("receive") or int(pid) > state["progress"].get(mid, 0)
            or key in boxes(state)):
        raise ValueError("名将副本通关箱未满足或已领取")
    # 原生 1352 回 SomeThings；本包 receive 是「名将副本元宝礼包」道具，不直接折算元宝。
    reward = activities.build_reward(save, f'{point["receive"]},1', config)
    state.setdefault("boxes", []).append(key)
    return reward, reward


def prepare(opcode, save, body, config, now, seed):
    if opcode == 1350:
        return query(save, body, config, now), b""
    if opcode == 1351:
        return fight(save, body, config, now, seed)
    if opcode == 1352:
        return claim_box(save, body, config, now)
    raise ValueError("名将副本请求无效")
