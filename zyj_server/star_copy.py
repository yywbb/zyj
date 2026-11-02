"""名将副本：配置解锁、每日胜利次数与首通掉落，共用现有 v2 战斗。"""

import json
import random

from . import activities, battle, cheer, formation, pets, recharge
from .protocol import encode_pb_field, iter_pb_fields, pb_get_varint


SECTION = 40001  # shortcut: 仅开放引导所在第一章，后续需先补齐名将专用突破被动。


def get_state(save, config):
    state = save.setdefault("star_copy_state", {"day": 0, "progress": {}, "wins": {}})
    if (not isinstance(state, dict) or type(state.get("day")) is not int
            or not 0 <= state["day"] < (1 << 31)
            or not isinstance(state.get("progress"), dict) or not isinstance(state.get("wins"), dict)):
        raise ValueError("名将副本存档无效")
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
    return state


def settle(save, config, now):
    state = get_state(save, config)
    day = (now + 8 * 3600) // 86400
    if day > state["day"]:
        state.update(day=day, wins={})
    return state


def available_maps(save, config):
    copies = formation.records(bytes.fromhex(save["world_state"]["1300"]), 1, 1)
    available = set()
    for mid in sorted(config["star_map"], key=int):
        if config["star_map"][mid]["section"] != SECTION:
            continue
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
    rows = [(0, [sum(state["wins"].values())])]
    for mid in sorted(config["star_map"], key=int):
        if config["star_map"][mid]["section"] != SECTION:
            continue
        progress = state["progress"].get(mid, 0)
        values = [int(mid), int(progress == max(map(int, config["star_copy"][mid]))) if mid in available else -1]
        if mid in available:
            for pid in sorted(config["star_copy"][mid], key=int):
                if int(pid) <= progress + 1:
                    values.extend((int(pid), state["wins"].get(f"{mid}/{pid}", 0) if int(pid) <= progress else -1, 0))
        rows.append((int(mid), values))
    # 业务 Comb 的0号行是总次数，不改变顶层999900的正ID校验。
    return b"".join(encode_pb_field(1, 2, encode_pb_field(1, 0, mid)
                                 + encode_pb_field(2, 2, recharge.ids(v & ((1 << 64) - 1) for v in values)))
                    for mid, values in rows)


def fight(save, body, config, now, seed):
    fields = list(iter_pb_fields(body))
    if len(fields) != 2 or any(n != 1 or w != 0 or not 0 < v < (1 << 31) for n, w, v in fields):
        raise ValueError("名将副本挑战参数无效")
    mid, pid = (str(v) for _, _, v in fields)
    point = config["star_copy"].get(mid, {}).get(pid)
    if not save.get("has_role") or save["role_state"]["level"] < config["build"]["148"]["level"]:
        raise ValueError("名将副本尚未解锁")
    if mid in config["star_map"] and config["star_map"][mid]["section"] != SECTION:
        raise ValueError("名将副本目前仅开放第一章，后续特殊被动尚未接入")
    state = settle(save, config, now)
    progress = state["progress"].get(mid, 0)
    if not point or mid not in available_maps(save, config) or int(pid) > progress + 1:
        raise ValueError("名将副本关卡尚未解锁")
    key = f"{mid}/{pid}"
    if (sum(state["wins"].values()) >= int(config["global_kv"]["star_copy_times"]["value"])
            or state["wins"].get(key, 0) >= point["challenge"]):
        raise ValueError("名将副本今日可战胜次数已用完")
    attack, defense = battle.rosters(save, point, config)
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
