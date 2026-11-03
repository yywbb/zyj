"""玩家存档与录制操作的状态更新；整组回包准备、原子保存后才交给调用方。"""

import copy
import functools
import json
import os
from pathlib import Path
import random
import tempfile
import time
import zipfile

from . import activities, activity_copy, arena, battle, blackmarket, cheer, configuration, cornucopia, daily_events, development, equip_baptize, fashion, favorite, formation, friend_copy, general_foster, magic, mieshendian, online_rewards, penglai, pets, qiankun, recharge, recruit, resource_purchase, rob, secret_shop, shop, sigil, single_boss, star_copy, timebag, training, treasure_refine, watchstar, welfare, world_boss
from . import achievements, collection, cup, soul
from .guide import describe_guide, get_guide_sections, migrate_guide, record_guide_progress
from .protocol import (
    encode_pb_field, get_comb_messages, iter_pb_fields, pack_frame,
    parse_ids_pb, pb_get_varint, pb_set_field, pb_set_varint,
)

print_flush = functools.partial(print, flush=True)

WORLD_QUERY_IDS = (1002, 1012, 1107, 1200, 1300)
SLOT_RECORD_KEYS = {1: 2, 2: 1, 3: 1, 4: 1, 5: 1, 7: 1, 17: 1}
STAMINA_INTERVAL = 360  # 多份 Role 抓包的全部/下次恢复倒计时之差可交叉验证。

# role_pb.Role 的字段号。
ROLE_FIELD_MAP = {
    "vip": 4,
    "level": 5,
    "exp": 6,
    "nextexp": 7,
    "coin": 8,
    "gold": 9,
    "stamina": 10,
    "maxstamina": 11,
    "energy": 12,
    "maxenergy": 13,
    "power": 14,
    "profile": 21,
    "g_gold": 25,
    "g_power": 26,
    "power_all": 27,
}


def load_role_config(config_path):
    with zipfile.ZipFile(config_path) as archive:
        sign_tables = tuple(n[2:-5] for n in archive.namelist() if n.startswith("5/sign2_") and n.endswith(".json"))
    return configuration.load_tables(config_path,
                             ("role_exp", "cheer", "copy", "star_copy", "star_map", "expedition2", "expedition_map", "protagonist_grow", "map", "props", "general_fragment", "recruit_basic",
                             "begin7day", "begin7day_task", "liveness", "liveness_reward", "week_liveness_reward", "equip", "rollname",
                             "mid_autumn_exchange", "activity_time", "treasure_discount_1", "consumegift_reward_1",
                             "goddown_contribution_reward_1", "goddown_exchange_1", "new_generals_exchange_1",
                             "general", "general_exp", "copy_monster", "skill", "combskill", "global_kv",
                             "combskillprobability", "breakskill", "mozhao_break", "worlddrop", "recruit_deck", "recruit_tenlottery",
                             "buycount_price", "recharge", "vip", "firstpay", "monthcardgift", "equip_strengthen", "treasure2_strengthen", "treasure2_refine", "build",
                             "shop", "shop_price", "gift_bag", "vip_weekgift", "sigil", "sigilposition", "kingofmofu_lv", "soul", "soul_hunt", "soul_exchange", "soulslot", "soul_integrate", "soul_integrate_lv", "soul_thousand", "gambling_items", "gambling_gold",
                             "fashion_gift_bag", "fashioncoat", "fashionintentify", "online_reward",
                             "continue7_X1", "mammon", "luxurysign", "vip_welfare", "week_month_gift",
                             "growplan_x1", "growplan_global_x1", "chengzhangplan_money", "general_awake",
                             "month_welfare", "month_growup", "week_growup_1", "week_growup_2_1",
                             "week_growup_money_1", "week_growup_money_2_1", "recharge_gift_1",
                             "speedup_gift_time_x1", "speedup_gift", "treasure2_fragment", "equip_fragment", "loot", "exchange_shop",
                             "trump", "trump_gem", "toplevel", "combat_rank", "wing_rank", "copy_rank", "mozhao_rank", "friend_rank",
                             "combat_grow", "combat_grow_x1", "combat_grow_x2", "sigil_rank", "soul_rank", "artifact_rank", "localTrump_rank",
                             "pet3_fragment", "pet3_attr", "pet3_talentskill", "pet3_passiveskill", "pet3_illustrated", "trigger_gift2", "boss2", "boss2_rewards1", "boss2_rewards2", "mieshendian_monster_param", "mieshendian_condition", "mieshendian_attr",
                             "mieshendian_award", "mieshendian_reward", "mieshendian_shop", "blackmarket_items", "blackmarket_pos", "blackmarket_refresh",
                             "watchstar_reward", "watchstar_lv_reward", "watchstar_starextra", "watchstar_change", "watchstar_fix", "activity_huodong",
                             "mystery_shop", "renascence", "redl_awake_item", "gang2_level", "gang2_incense",
                             "gang2_shop", "gang2_bait", "gang2_fishpond", "gang2_fishpondexp",
                             "gang2_skill_open", "gang2_skill_level", "gang2_boss", "gang2_boss_reward", "gang2_boss_contribution", "gang2_boss_encouraging",
                             "guild_box", "guild_box_total", "guild_play", "guild_integral", "guild_time", "guild_rank",
                             "gang2_feast_type", "gang2_bath_type", "gang2_feast_gain", "gang2_bath_buff", "gang2_feast_profit", "gang2_bath_profit",
                             "gang2_feast_award", "gang2_bath_award", "price_props", "barrage", "gang2_cityaward", "gang2_battleTime", "gang2battle_youhua_type",
                             "godstone", "godstonestrengthening", "daily_function", "huodong_monster",
                             "favorable", "favorable_level", "favorable_task", "shake_param",
                             "penglai3_map", "penglai3_type", "penglai3_dice", "penglai3_card", "penglai3_monster",
                             "personalboss_att", "personalboss_date", "equip_baptize", "artifact", "artifact_baptize", "artifact_baptize_xian", "artifact_xian_config", "task", "team_recommend", "cup_reward",
                             "athletics_copy2", "athletics_choice", "athletics_rewards", "athletics_rewards2", "athletics_rewards3", "athletics_npc", "token", "token_fragment",
                             *(row[0] for row in activity_copy.COPIES.values()), *sign_tables))


def get_default_save():
    return {
        "has_role": False,
        "role_name": "",
        "selected_general_id": 0,
        "level": 1,
        "gold": 0,
        "silver": 0,
        "energy": 20,
        # 空 sections = 全新号，客户端会从头播开场剧情。
        "guide": {"sections": {}},
        "created_at": time.time(),
        "last_login": time.time()
    }


def load_save(save_path, step_counts):
    if os.path.exists(save_path):
        try:
            with open(save_path, "r", encoding="utf-8") as f:
                data = json.load(f)
                return migrate_guide(data, step_counts)
        except Exception as e:
            print_flush(f"[!] 读取存档失败 ({e})，保留原文件并停止加载")
            raise ValueError("存档读取失败，拒绝用空进度覆盖") from e
    try:
        from . import db
        p = Path(save_path)
        aid = int(p.parent.name) if p.parent.name.isdigit() and 1 <= int(p.parent.name) <= 1000 else 1
        db_path = db.get_db_path(save_path)
        data = db.load_player(db_path, aid) if db_path.exists() else None
        if data is not None:
            return migrate_guide(data, step_counts)
    except Exception:
        pass
    return get_default_save()


def save_role(save_data, save_path, step_counts):
    temporary_path = None
    try:
        save_data["last_login"] = time.time()
        os.makedirs(os.path.dirname(save_path), exist_ok=True)
        # 同步写入 SQLite (若数据库存在则同步)
        try:
            from . import db
            db_path = db.get_db_path(save_path)
            if db_path.exists():
                p = Path(save_path)
                aid = int(p.parent.name) if p.parent.name.isdigit() and 1 <= int(p.parent.name) <= 1000 else 1
                db.save_player(db_path, aid, save_data)
        except Exception:
            pass
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=os.path.dirname(save_path), delete=False) as f:
            temporary_path = f.name
            json.dump(save_data, f, ensure_ascii=False, indent=2)
        os.replace(temporary_path, save_path)
        temporary_path = None
        print_flush(f"[✓] 进度实时落盘: 角色【{save_data.get('role_name', '未起名')}】 (Lv.{save_data.get('level', 1)}, 引导: {describe_guide(get_guide_sections(save_data, step_counts), step_counts)})")
        return True
    except Exception as e:
        print_flush(f"[!] 保存存档失败: {e}")
        return False
    finally:
        if temporary_path is not None:
            os.unlink(temporary_path)


def build_random_name(body, role_config):
    try:
        fields = list(iter_pb_fields(body))
    except ValueError as e:
        raise ValueError("随机名字请求格式错误") from e
    if len(fields) != 1 or fields[0][:2] != (1, 0) or fields[0][2] not in (1, 2, 3):
        raise ValueError("随机名字请求格式错误")
    names = tuple(role_config["rollname"].values())
    name = random.choice(names)["name1"] + random.choice(names)[f"name{fields[0][2] + 1}"]
    return encode_pb_field(1, 2, name.encode("utf-8"))


def parse_set_name(body):
    name = None
    for field, wire, value in iter_pb_fields(body):
        if field == 1:
            if wire != 2:
                raise ValueError("名字必须是 UTF-8 字符串")
            name = value.decode("utf-8")
    if not name:
        raise ValueError("缺少玩家名字")
    return name


def parse_prop_use(body):
    try:
        fields = list(iter_pb_fields(body))
    except ValueError as e:
        raise ValueError("道具使用请求格式错误") from e
    if len(fields) not in (2, 3) or any(n != 1 or w != 0 or not 0 < value < (1 << 31)
                                      for n, w, value in fields):
        raise ValueError("道具使用请求格式错误")
    return [value for _, _, value in fields]


def apply_role_state(body, save, now):
    """把存档里的角色状态回填进 Role 消息，避免回放录制数据时把等级/货币冲掉。"""
    st = save.get("role_state") or {}
    for k, fn in ROLE_FIELD_MAP.items():
        v = st.get(k)
        if type(v) is int and v >= 0:
            body = pb_set_varint(body, fn, v)
    if save.get("role_name"):
        body = pb_set_field(body, 3, 2, save["role_name"].encode("utf-8"))
    clock = save.get("stamina_clock")
    if clock:
        missing = max(0, st["maxstamina"] - st["stamina"])
        remaining = max(0, clock["next_at"] - now) if missing else 0
        body = pb_set_varint(body, 17, remaining)
        body = pb_set_varint(body, 18, remaining + (missing - 1) * STAMINA_INTERVAL if missing else 0)
    return body


def get_role_state(save, role_config):
    state = save.setdefault("role_state", {})
    if not isinstance(state, dict):
        raise ValueError("role_state 必须是对象")
    if save.get("role_snapshot"):
        snapshot = bytes.fromhex(save["role_snapshot"])
        for name, field in ROLE_FIELD_MAP.items():
            value = pb_get_varint(snapshot, field)
            if value is not None:
                state.setdefault(name, value)
    level = state.setdefault("level", save.get("level", 1))
    config = role_config["role_exp"][str(level)]
    defaults = {"vip": recharge.vip(save.get("recharge_state", {"rmb": 0}), role_config),
                "exp": 0, "nextexp": config["nextexp"], "coin": save.get("silver", 0),
                "gold": save.get("gold", 0), "stamina": config["maxstamina"],
                "maxstamina": config["maxstamina"] + favorite.capacity_bonus(save, role_config, "maxstamina"), "energy": save.get("energy", 20),
                "maxenergy": config["maxenergy"] + favorite.capacity_bonus(save, role_config, "maxenergy"), "power": 0, "g_gold": 0, "g_power": 0, "power_all": 0}
    for name, value in defaults.items():
        state.setdefault(name, value)
    if any(type(value) is not int or value < 0 for name, value in state.items() if name in ROLE_FIELD_MAP):
        raise ValueError("角色数值必须是非负整数")
    if state["g_gold"] >= (1 << 31):
        raise ValueError("仙元超出范围")
    return state


def validate_stamina_clock(save):
    if "stamina_clock" not in save:
        return
    clock = save["stamina_clock"]
    if not isinstance(clock, dict) or any(type(clock.get(key)) is not int or not 0 <= clock[key] < (1 << 63)
                                          for key in ("next_at", "checked_at")):
        raise ValueError("体力计时存档无效")


def settle_stamina(save, role_config, now):
    if not (save.get("has_role") or save.get("role_state") or save.get("role_snapshot")):
        return
    state = get_role_state(save, role_config)
    # 旧档没有本地锚点时从现在起算，不能按录制时间或创建时间补发。
    clock = save.setdefault("stamina_clock", {"next_at": 0, "checked_at": now})
    # 时钟回拨不缩短已排定的恢复期限。
    checked = max(now, clock["checked_at"])
    clock["checked_at"] = checked
    if state["stamina"] >= state["maxstamina"]:
        clock["next_at"] = 0
    elif clock["next_at"] == 0:
        clock["next_at"] = checked + STAMINA_INTERVAL
    elif checked >= clock["next_at"]:
        recovered = (checked - clock["next_at"]) // STAMINA_INTERVAL + 1
        state["stamina"] = min(state["maxstamina"], state["stamina"] + recovered)
        clock["next_at"] = clock["next_at"] + recovered * STAMINA_INTERVAL if state["stamina"] < state["maxstamina"] else 0


def settle_campaign(save, role_config, now):
    if not save.get("has_role"):
        return
    day = (now + 28800) // 86400
    # 旧次数没有日期，首次接入只锚定；不能清掉可能已在今天消耗的次数。
    previous = save.setdefault("campaign_day", day)
    if type(previous) is not int or not 0 <= previous < (1 << 31):
        raise ValueError("主线每日次数日期无效")
    if day <= previous:
        return
    out = bytearray()
    for field, wire, value in iter_pb_fields(bytes.fromhex(save["world_state"]["1300"])):
        if (field, wire) == (1, 2) and str(pb_get_varint(value, 1)) in role_config["copy"]:
            points = role_config["copy"][str(pb_get_varint(value, 1))]
            rows = bytearray()
            for n, w, row in iter_pb_fields(value):
                if (n, w) == (7, 2) and str(pb_get_varint(row, 1)) in points:
                    row = pb_set_varint(row, 4, 0)
                rows.extend(encode_pb_field(n, w, row))
            value = bytes(rows)
        out.extend(encode_pb_field(field, wire, value))
    save["world_state"]["1300"] = out.hex()
    save["campaign_day"] = day


def record_legacy_role_state(save, body, role_config):
    ids = parse_ids_pb(body)
    if len(ids) != 5 or str(ids[0]) not in role_config["role_exp"] or any(not 0 <= value < (1 << 31) for value in ids):
        raise ValueError("无效的旧客户端角色上报")
    state = get_role_state(save, role_config)
    # 兼容旧客户端；只拒绝经验倒退，货币和战力必须允许消费/下降。
    if (ids[0], ids[1]) < (state["level"], state["exp"]):
        return False
    state.update(zip(("level", "exp", "coin", "gold", "power"), ids[:5]))
    state["power_all"] = ids[4]
    save.update(level=state["level"], silver=state["coin"], gold=state["gold"])
    if save.get("role_snapshot"):
        save["role_snapshot"] = apply_role_state(bytes.fromhex(save["role_snapshot"]), save, int(time.time())).hex()
    return True


def initialize_world_state(save, master_packets):
    world = save.setdefault("world_state", {})
    if not isinstance(world, dict):
        raise ValueError("world_state 必须是对象")
    if save.get("has_role") and any(str(mid) not in world for mid in WORLD_QUERY_IDS):
        print_flush("[!] 旧存档未保存阵容/背包/副本明细，以录制基础建立缓存；无法推断缺失的历史物品。")
    for frame in master_packets:
        if frame["opcode"] == 999900:
            for mid, body in get_comb_messages(bytes.fromhex(frame["hex"])):
                if mid in WORLD_QUERY_IDS:
                    world.setdefault(str(mid), body.hex())
    for mid in WORLD_QUERY_IDS:
        if str(mid) not in world or not isinstance(world[str(mid)], str):
            raise ValueError(f"缺少有效的 {mid} 状态基础包")
        body = bytes.fromhex(world[str(mid)])
        merge_pb_records(body, b"", SLOT_RECORD_KEYS if mid == 1002 else {1: 1})
        for field, wire, value in iter_pb_fields(body):
            if field == 1 and wire == 2:
                if mid == 1300:
                    merge_pb_records(value, b"", {7: 1})
                elif mid in (1012, 1107, 1200):
                    count = pb_get_varint(value, 2)
                    if count is None or not 0 <= count < (1 << 31):
                        raise ValueError("存档道具数量无效")


def merge_pb_records(base, update, keys):
    def identity(field, wire, value):
        if field not in keys:
            return field, None
        if wire != 2:
            raise ValueError("重复记录必须是嵌套消息")
        list(iter_pb_fields(value))
        iid = pb_get_varint(value, keys[field])
        if iid is None or not 0 < iid < (1 << 31):
            raise ValueError("重复记录缺少有效标识")
        return field, iid

    updates = {}
    for record in iter_pb_fields(update):
        key = identity(*record)
        if record[0] in keys:
            updates[key] = [record]
        else:
            updates.setdefault(key, []).append(record)
    out, written = [], set()
    for record in iter_pb_fields(base):
        key = identity(*record)
        if key not in updates:
            out.append(record)
        elif key not in written:
            out.extend(updates[key])
            written.add(key)
    for key, records in updates.items():
        if key not in written:
            out.extend(records)
    return b"".join(encode_pb_field(*record) for record in out)


def record_slot_update(save, body):
    world = save["world_state"]
    world["1002"] = merge_pb_records(bytes.fromhex(world["1002"]), body, SLOT_RECORD_KEYS).hex()


def settle_self_stats(save, role_config):
    if not save.get("has_role"):
        return b""
    get_role_state(save, role_config)
    update = development.migrate_self_stats(save, role_config)
    if update:
        record_slot_update(save, update)
    return update


def change_item_count(save, cid, delta, role_config, now=None):
    if cid == 70000:
        state = dict(soul.get_state(save))
        state["tokens"] = soul.integer(state["tokens"] + delta)
        save["soul_state"] = state
        return
    if cid == 1025:
        state = get_role_state(save, role_config)
        if not 0 <= state["g_gold"] + delta < (1 << 31):
            raise ValueError("仙元不足或超出范围")
        state["g_gold"] += delta
        return
    if cid in (1000, 1001, 1003):
        field = {1000: 1, 1001: 2, 1003: 4}[cid]
        apply_reward(save, encode_pb_field(field, 0, delta & ((1 << 64) - 1)), role_config, now)
        return
    if cid == 1004:
        state = mieshendian.get_state(save, role_config)
        if not 0 <= state["points"] + delta < (1 << 31):
            raise ValueError("灭神殿积分不足或超出范围")
        state["points"] += delta
        return
    if cid == 1005:
        state = arena.get_state(save, role_config)
        if not 0 <= state["points"] + delta < (1 << 31):
            raise ValueError("竞技场积分不足或超出范围")
        state["points"] += delta
        return
    if str(cid) in role_config["redl_awake_item"]:
        fragments = qiankun.get_state(save)["red_fragments"]
        value = fragments.get(str(cid), 0) + delta
        if not 0 <= value < (1 << 31):
            raise ValueError("伙伴精华数量不足或超出范围")
        fragments[str(cid)] = value
        return
    if str(cid) in role_config["trump_gem"]:
        roster = bytes.fromhex(save["world_state"]["1002"])
        previous = next((parse_ids_pb(v) for n, w, v in iter_pb_fields(roster)
                         if (n, w) == (17, 2) and pb_get_varint(v, 1) == cid), [cid, 0])
        if len(previous) != 2 or not 0 <= previous[1] + delta < (1 << 31):
            raise ValueError("神器宝石数量不足或超出范围")
        record = encode_pb_field(17, 2, encode_pb_field(1, 0, cid) + encode_pb_field(1, 0, previous[1] + delta))
        record_slot_update(save, record)
        return
    fragment = role_config["general_fragment"].get(str(cid))
    if fragment is None and str(cid) not in role_config["props"]:
        fragment = next((row for row in role_config["general_fragment"].values() if row["general"] == cid), None)
    equip_fragment = str(cid) in role_config["treasure2_fragment"] or str(cid) in role_config["equip_fragment"]
    query = "1012" if fragment else "1107" if equip_fragment else "1200"
    if fragment:
        cid = fragment["general"]
    elif (not equip_fragment and str(cid) not in role_config["props"] and str(cid) not in role_config["pet3_fragment"]
          and str(cid) not in role_config["token"] and str(cid) not in role_config["token_fragment"]):
        raise ValueError(f"未实现的物品类型: {cid}")
    world = save["world_state"]
    body = bytes.fromhex(world[query])
    record = next((v for n, w, v in iter_pb_fields(body) if n == 1 and w == 2 and pb_get_varint(v, 1) == cid), b"")
    count = (pb_get_varint(record, 2) or 0) + delta
    if not 0 <= count < (1 << 31):
        raise ValueError(f"道具 {cid} 数量不足或超出范围")
    record = pb_set_varint(pb_set_varint(record, 1, cid), 2, count)
    if fragment:
        record = pb_set_varint(pb_set_varint(record, 3, 1), 4, fragment["num"])
    body = merge_pb_records(body, encode_pb_field(1, 2, record), {1: 1})
    world[query] = b"".join(encode_pb_field(n, w, v) for n, w, v in iter_pb_fields(body)
                              if not (n == 1 and w == 2 and pb_get_varint(v, 2) == 0)).hex()


def record_copy_win(save, request_body, star, role_config, *, allow_repeat=False):
    location = parse_ids_pb(request_body)
    if len(location) != 2 or not 0 < star <= 3:
        raise ValueError("无效的副本战斗位置或星级")
    map_id, point_id = location
    config = role_config["copy"][str(map_id)]
    if str(point_id) not in config:
        raise ValueError("副本关卡不存在")
    world = save["world_state"]
    copies = bytes.fromhex(world["1300"])
    current = next((v for n, w, v in iter_pb_fields(copies) if n == 1 and w == 2 and pb_get_varint(v, 1) == map_id), b"")
    if not current:
        current = b"".join(encode_pb_field(n, 0, v) for n, v in ((1, map_id), (2, 0), (3, 0), (4, 1), (5, 1), (6, 1)))
    points = {pb_get_varint(v, 1): v for n, w, v in iter_pb_fields(current) if n == 7 and w == 2}
    if not allow_repeat and point_id in points and pb_get_varint(points[point_id], 3):
        raise ValueError("已通关关卡不支持重复录制战斗")
    point = points.get(point_id, b"")
    count = (pb_get_varint(point, 4) or 0) + 1
    if count >= (1 << 31):
        raise ValueError("副本次数超出范围")
    for n, v in ((1, point_id), (2, 0), (3, max(star, pb_get_varint(point, 3) or 0)), (4, count)):
        point = pb_set_varint(point, n, v)
    points[point_id] = point
    current = merge_pb_records(current, encode_pb_field(7, 2, point), {7: 1})
    total = sum(pb_get_varint(v, 3) or 0 for v in points.values())
    for i in (1, 2, 3):
        if pb_get_varint(current, i + 3) == 1 and total >= role_config["map"][str(map_id)][f"star{i}"]:
            current = pb_set_varint(current, i + 3, 2)
    if all(int(p) in points and pb_get_varint(points[int(p)], 3) == 3 for p in config):
        current = pb_set_varint(current, 2, 3)
    copies = merge_pb_records(copies, encode_pb_field(1, 2, current), {1: 1})
    if str(point_id + 1) not in config and str(map_id + 1) in role_config["copy"]:
        existing = any(n == 1 and w == 2 and pb_get_varint(v, 1) == map_id + 1 for n, w, v in iter_pb_fields(copies))
        if not existing:
            unlocked = b"".join(encode_pb_field(n, 0, v) for n, v in ((1, map_id + 1), (2, 0), (3, 0), (4, 1), (5, 1), (6, 1)))
            copies += encode_pb_field(1, 2, unlocked)
    world["1300"] = copies.hex()


def record_copy_box(save, request_body, role_config):
    fields = list(iter_pb_fields(request_body))
    if len(fields) != 2 or any(n != 1 or w != 0 or not 0 <= v < (1 << 31) for n, w, v in fields):
        raise ValueError("无效的副本宝箱请求")
    map_id, method = (v for _, _, v in fields)
    if method not in (0, 3, 6):
        raise ValueError("无效的副本宝箱请求")
    if not save.get("has_role"):
        raise ValueError("角色尚未创建")
    if str(map_id) not in role_config["copy"] or str(map_id) not in role_config["map"]:
        raise ValueError("暂不支持此地图的副本宝箱")
    index = method // 3 + 1
    config = role_config["map"][str(map_id)]
    copies = bytes.fromhex(save["world_state"]["1300"])
    current = next((v for n, w, v in iter_pb_fields(copies) if n == 1 and w == 2 and pb_get_varint(v, 1) == map_id), b"")
    field = index + 3
    stars = sum(pb_get_varint(v, 3) or 0 for n, w, v in iter_pb_fields(current) if n == 7 and w == 2)
    if pb_get_varint(current, field) not in (1, 2) or stars < config[f"star{index}"]:
        raise ValueError("副本宝箱未解锁或已领取")
    current = pb_set_varint(current, field, 3)
    save["world_state"]["1300"] = merge_pb_records(copies, encode_pb_field(1, 2, current), {1: 1}).hex()
    return config[f"award{index}"]


def apply_reward(save, body, role_config, now=None):
    state = get_role_state(save, role_config)
    for field, wire, value in iter_pb_fields(body):
        if field in (1, 2, 3, 4) and wire == 0:
            name = {1: "coin", 2: "gold", 3: "stamina", 4: "energy"}[field]
            delta = value - (1 << 64) if value >= (1 << 63) else value
            balance = state[name] + delta
            if balance < 0:
                raise ValueError(f"{name} 不足，拒绝录制操作")
            # Role.coin 是 int64，其余资源是 int32；按协议位宽校验，别让银币奖励被 int32 截断。
            if balance >= (1 << 63 if name == "coin" else 1 << 31):
                raise ValueError(f"{name} 超出范围")
            state[name] = balance
            if name == "gold" and delta < 0:
                activities.record_gold_spend(save, -delta, role_config, int(time.time()) if now is None else now)
            elif name == "stamina" and delta < 0:
                activities.record_liveness(save, 1, -delta, role_config, int(time.time()) if now is None else now)
        elif field in (5, 10) and wire == 2:
            for n, w, record in iter_pb_fields(value):
                if n == 1 and w == 2:
                    cid, count = pb_get_varint(record, 1), pb_get_varint(record, 2)
                    if cid is None or count is None:
                        raise ValueError("道具变更缺少 ID/数量")
                    count = (count & 0xffffffff) - (1 << 32) if count & (1 << 31) else count
                    if cid == 1008:
                        if field == 5 and count > 0:
                            current_time = int(time.time()) if now is None else now
                            rstate = recharge.get_state(save)
                            rstate["rmb"] += count
                            save["role_state"]["vip"] = recharge.vip(rstate, role_config)
                            welfare.get_state(save)["daily_rmb"] += count
                            if 1 <= activities.begin7day_day(save, current_time) <= 7:
                                activities.get_state(save)["begin7day_rmb"] += count
                    elif str(cid) in role_config["fashioncoat"]:
                        if field != 5 or count != 1:
                            raise ValueError("时装奖励数量无效")
                        if str(cid) not in fashion.get_state(save, role_config)["levels"]:
                            _, _, general = fashion.prepare(1074, save, encode_pb_field(1, 0, cid), role_config, now, grant=True)
                            record_protagonist_general(save, general)
                            record_slot_update(save, encode_pb_field(1, 2, general)
                                               + encode_pb_field(6, 2, bytes.fromhex(save["protagonist_snapshot"])))
                    else:
                        change_item_count(save, cid, count if field == 5 else -count, role_config, now)
        elif field == 6 and wire == 2:
            record_slot_update(save, encode_pb_field(2, 2, value))
        elif field == 7 and wire == 2:
            for n, w, soul in iter_pb_fields(value):
                if n == 1 and w == 2:
                    record_slot_update(save, encode_pb_field(3, 2, soul))
        elif field == 11 and wire == 2:
            record_slot_update(save, encode_pb_field(7, 2, value))
        elif field == 8 and wire == 2:
            record_protagonist_general(save, value)
            record_slot_update(save, encode_pb_field(1, 2, value))


def record_protagonist_general(save, general):
    snapshot = save.get("protagonist_snapshot")
    if not snapshot:
        return
    body = bytes.fromhex(snapshot)
    if pb_get_varint(general, 2) != pb_get_varint(body, 1):
        return
    body = pb_set_field(body, 10, 2, general)
    body = pb_set_varint(body, 2, pb_get_varint(general, 3))
    # General_Property.level2 与 Protagonist.level2 不是同一成长级别。
    save["protagonist_snapshot"] = body.hex()


def apply_sigil_update(save, body, power_delta, role_config):
    state = get_role_state(save, role_config)
    for key in ("power", "power_all"):
        state[key] += power_delta
        if not 0 <= state[key] < (1 << 31):
            raise ValueError("魔符增加后的角色战力超出范围")
    record_slot_update(save, body)
    for n, w, raw in iter_pb_fields(body):
        if (n, w) == (1, 2):
            record_protagonist_general(save, raw)
    if save.get("protagonist_snapshot"):
        protagonist = encode_pb_field(6, 2, bytes.fromhex(save["protagonist_snapshot"]))
        record_slot_update(save, protagonist)
        body += protagonist
    return body


def prepare_recorded_response(opcode, body, save, request_body, step_counts, role_config, now):
    if opcode == 999900:
        requests = dict(get_comb_messages(request_body))
        messages = iter(get_comb_messages(body))
        out = bytearray()
        for field, wire, value in iter_pb_fields(body):
            if field == 1 and wire == 2:
                mid, data = next(messages)
                updated = prepare_recorded_response(mid, data, save, requests.get(mid, b""), step_counts, role_config, now)
                if mid == 1111 and save["last_rob"]["fragment"] != 28010:
                    raise ValueError("挑战引导请选择搜神记碎片一")
                if mid == 1111 and pb_get_varint(updated, 1) == 0:
                    # 原生引导收到 1111 成功包就进入翻牌；失败整组回滚，避免跳到不存在的奖励窗口。
                    raise ValueError("未战胜本地守卫，请先提升阵容；引导未推进，未消耗精力。")
                if updated != data:
                    value = pb_set_field(value, 2, 2, updated)
            out.extend(encode_pb_field(field, wire, value))
        return bytes(out)
    if opcode == 204:
        gender = pb_get_varint(bytes.fromhex(save.get("role_snapshot", "")), 2)
        if request_body or not save.get("has_role") or gender not in (0, 1):
            raise ValueError("角色性别查询参数或角色状态无效")
        body = encode_pb_field(1, 0, 1 if gender else 2)
    elif opcode == 999905:
        if request_body:
            raise ValueError("时间查询不接受参数")
        # 客户端把第二项取反作为时区；沿用抓包的 UTC+8，不跟随宿主机时区。
        body = encode_pb_field(1, 0, now) + encode_pb_field(1, 0, (-8) & ((1 << 64) - 1))
    elif opcode in (*collection.OPCODES, *achievements.OPCODES):
        module = collection if opcode in collection.OPCODES else achievements
        body = module.prepare(opcode, save, request_body, role_config)
        if opcode in module.MUTATIONS:
            apply_reward(save, body, role_config, now)
    elif opcode in online_rewards.OPCODES:
        body = online_rewards.prepare(opcode, save, request_body, role_config)
        if opcode == 2038:
            apply_reward(save, body, role_config, now)
    elif opcode in timebag.OPCODES:
        body = timebag.prepare(opcode, save, request_body, role_config, now, body)
        if opcode == 2881:
            apply_reward(save, body, role_config, now)
    elif opcode in pets.OPCODES:
        previous = pets.attributes(save, role_config)
        body, costs = pets.prepare(opcode, save, request_body, role_config)
        for cid, count in costs:
            change_item_count(save, cid, -count, role_config, now)
        if opcode == 1046:
            achievements.record(save, "petbreakcount", 1, role_config)
        if opcode == 1065:
            apply_reward(save, body, role_config, now)
        changes = {field: int(value) - int(previous[field]) for field, value in pets.attributes(save, role_config).items()
                   if int(value) != int(previous[field])}
        if changes:
            world = bytes.fromhex(save["world_state"]["1002"])
            generals, slots = formation.records(world, 1, 2), formation.records(world, 4, 2)
            update, increase = b"", 0
            for iid in sorted(i for i in slots if i):
                if iid not in generals:
                    raise ValueError("上阵武将属性不存在")
                raw, delta = development.adjust(generals[iid], changes)
                record_protagonist_general(save, raw)
                update += encode_pb_field(1, 2, raw)
                increase += delta
            record_slot_update(save, update)
            for key in ("power", "power_all"):
                save["role_state"][key] += increase
                if not 0 <= save["role_state"][key] < (1 << 31):
                    raise ValueError("魔宠技能增加后的战力超出范围")
            record_slot_update(save, encode_pb_field(6, 2, bytes.fromhex(save["protagonist_snapshot"])))
    elif opcode in world_boss.QUERIES:
        body = world_boss.query(opcode, save, request_body, role_config)
    elif opcode in soul.OPCODES or opcode == 1007 and len(parse_ids_pb(request_body)) >= 2 and parse_ids_pb(request_body)[1] == 2:
        body, costs, reward, update = soul.prepare(opcode, save, request_body, role_config, now, random.getrandbits(64))
        for cid, count in costs:
            change_item_count(save, cid, -count, role_config, now)
        if reward:
            apply_reward(save, reward, role_config, now)
        if update:
            record_slot_update(save, update)
            for n, w, raw in iter_pb_fields(update):
                if (n, w) == (1, 2):
                    record_protagonist_general(save, raw)
            protagonist = encode_pb_field(6, 2, bytes.fromhex(save["protagonist_snapshot"]))
            record_slot_update(save, protagonist)
            if opcode in (1006, 1007, 2504, 2507):
                body += protagonist
    elif opcode in favorite.OPCODES:
        body, costs, update = favorite.prepare(opcode, save, request_body, role_config, random.getrandbits(64))
        for cid, count in costs:
            change_item_count(save, cid, -count, role_config, now)
        previous = formation.records(bytes.fromhex(save["world_state"]["1002"]), 1, 2)
        for iid, raw in formation.records(update, 1, 2).items():
            receipt = qiankun.get_state(save)["receipts"].get(f"general:{iid}")
            if receipt and receipt["after"] == previous[iid].hex():
                baseline = bytes.fromhex(receipt["before"])
                if all(pb_get_varint(baseline, field) == pb_get_varint(raw, field) for field in (1, 2)):
                    changes = {field: pb_get_varint(raw, field) - pb_get_varint(previous[iid], field) for field in (6, 7, 8)}
                    baseline, _ = development.adjust(baseline, changes)
                    receipt.update(before=baseline.hex(), after=raw.hex())
            record_protagonist_general(save, raw)
        if update:
            record_slot_update(save, update)
    elif opcode in (*cornucopia.OPCODES, *penglai.OPCODES, *single_boss.OPCODES):
        module = cornucopia if opcode in cornucopia.OPCODES else penglai if opcode in penglai.OPCODES else single_boss
        body, costs, reward = module.prepare(opcode, save, request_body, role_config, now, random.getrandbits(64))
        for cid, count in costs:
            change_item_count(save, cid, -count, role_config, now)
        if reward:
            apply_reward(save, reward, role_config, now)
    elif opcode in welfare.OPCODES:
        body, costs = welfare.prepare(opcode, save, request_body, role_config, now)
        for cid, count in costs:
            change_item_count(save, cid, -count, role_config, now)
        if opcode in welfare.CLAIMS:
            apply_reward(save, body, role_config, now)
    elif opcode in magic.OPCODES:
        previous = magic.bonuses(save, role_config)
        body, costs, actual = magic.prepare(opcode, save, request_body, role_config, random.getrandbits(64))
        for cid, count in costs:
            change_item_count(save, cid, -count, role_config, now)
        update, power = magic.differences(save, previous, role_config)
        if update:
            update = apply_sigil_update(save, update, power, role_config)
        if opcode in (1361, 1363):
            body = update
        elif opcode == 1364:
            body = general_foster.comb(((1, update),)) + body
        activities.record_liveness(save, 25, actual, role_config, now)
    elif opcode in general_foster.OPCODES:
        body, costs, update, actual = general_foster.prepare(opcode, save, request_body, role_config, random.getrandbits(64))
        for cid, count in costs:
            change_item_count(save, cid, -count, role_config, now)
        if update:
            record_slot_update(save, update)
        activities.record_liveness(save, 22, actual, role_config, now)
    elif opcode in (*development.QUERIES, *development.MUTATIONS) and not body:
        body, costs, update = development.prepare(opcode, save, request_body, role_config)
        for cid, count in costs:
            change_item_count(save, cid, -count, role_config, now)
        if update:
            if opcode == 1017:
                raw = next(v for n, w, v in iter_pb_fields(update) if (n, w) == (1, 2))
                before = formation.records(bytes.fromhex(save["world_state"]["1002"]), 1, 2)[pb_get_varint(raw, 2)]
                qiankun.record_training(save, "general", before, raw, costs, qiankun.pristine_general(before, role_config, save))
            record_slot_update(save, update)
    elif opcode in (*daily_events.QUERIES, *daily_events.CLAIMS):
        body = daily_events.prepare(opcode, save, request_body, role_config, now)
        if opcode in daily_events.CLAIMS:
            apply_reward(save, body, role_config, now)
    elif opcode in mieshendian.OPCODES:
        body, costs, reward = mieshendian.prepare(opcode, save, request_body, role_config, now, random.getrandbits(64))
        for cid, count in costs:
            change_item_count(save, cid, -count, role_config, now)
        if reward:
            apply_reward(save, reward, role_config, now)
        if opcode in mieshendian.BATTLES or opcode == 3624 and reward:
            activities.record_liveness(save, 3, 1, role_config, now)
    elif opcode in arena.OPCODES:
        body, costs, reward = arena.prepare(opcode, save, request_body, role_config, now, random.getrandbits(64))
        for cid, count in costs:
            change_item_count(save, cid, -count, role_config, now)
        if reward:
            apply_reward(save, reward, role_config, now)
    elif opcode == 1350:
        body = star_copy.query(save, request_body, role_config, now)
    elif opcode in (*activity_copy.QUERIES, *activity_copy.BATTLES):
        body, reward = activity_copy.prepare(opcode, save, request_body, role_config, now, random.getrandbits(64))
        if reward:
            apply_reward(save, reward, role_config, now)
    elif opcode == 1351:
        body, reward = star_copy.fight(save, request_body, role_config, now, random.getrandbits(64))
        apply_reward(save, reward, role_config, now)
    elif opcode in (*friend_copy.QUERIES, *friend_copy.MUTATIONS):
        body, reward = friend_copy.prepare(opcode, save, request_body, role_config, now, random.getrandbits(64))
        if reward:
            apply_reward(save, reward, role_config, now)
    elif opcode == 300:
        if request_body:
            raise ValueError("贵族状态查询不接受参数")
        body = welfare.rewrite_vip(body, save, resource_purchase.settle(save, now))
        body = arena.rewrite_vip(body, save, role_config, now)
        body = single_boss.rewrite_vip(body, save, role_config, now)
    elif opcode == 301:
        price = resource_purchase.prepare(save, request_body, role_config, now)
        change_item_count(save, 1001, -price, role_config, now)
        body = b"\x08\x01"
    elif opcode == 2000:
        body = welfare.rewrite_activities(body)
        body = daily_events.rewrite_periods(body, save, role_config, now)
    elif opcode in activities.OPCODES:
        body = activities.prepare_response(opcode, save, request_body, role_config, now)
        if opcode == 5031:
            item_id, quantity = parse_ids_pb(request_body)
            for entry in role_config["treasure_discount_1"][str(item_id)]["generals"].split(";"):
                if entry:
                    cid, amount = map(int, entry.split(","))
                    change_item_count(save, cid, -amount * quantity, role_config, now)
        if opcode in activities.CLAIM_OPCODES or opcode == 5031:
            # 5031 客户端按配置自行扣款，回包只包含奖励，避免客户端再扣一次。
            apply_reward(save, body, role_config, now)
    elif opcode == 1032:
        body = activities.prepare_hints(body, save, request_body, role_config, now)
    elif opcode == 1402:
        body = recruit.query(save, request_body, now)
    elif opcode in (7110, 7111, 7112, 7113):
        body, cid, cost = recruit.preview(save, opcode, request_body, role_config, now, random.getrandbits(64))
        if cost:
            change_item_count(save, cid, -cost, role_config, now)
        if opcode == 7113:
            apply_reward(save, body, role_config, now)
            activities.record_liveness(save, 11, 10, role_config, now)
    elif opcode in recharge.OPCODES:
        body = recharge.prepare(opcode, save, request_body, role_config, now)
        if opcode in recharge.CLAIMS:
            apply_reward(save, body, role_config, now)
    elif opcode in blackmarket.OPCODES:
        body, costs, reward = blackmarket.prepare(opcode, save, request_body, role_config, now, random.getrandbits(64))
        for cid, count in costs:
            change_item_count(save, cid, -count, role_config, now)
        if reward:
            apply_reward(save, reward, role_config, now)
        if opcode == 3631:
            activities.record_liveness(save, 48, 1, role_config, now)
            if any(cid == 1001 for cid, _ in costs):
                magic.record_count(save, "blackmarketgoldbuycount", parse_ids_pb(request_body)[1], role_config)
    elif opcode in secret_shop.OPCODES:
        body, costs, reward = secret_shop.prepare(opcode, save, request_body, role_config, now, random.getrandbits(64))
        for cid, count in costs:
            change_item_count(save, cid, -count, role_config, now)
        if reward:
            apply_reward(save, reward, role_config, now)
        if opcode == 3651:
            activities.record_liveness(save, 37, 1, role_config, now)
    elif opcode == 3780:
        body = qiankun.red_query(save, request_body, body)
    elif opcode in qiankun.OPCODES:
        body, costs, reward = qiankun.prepare(opcode, save, request_body, role_config)
        for cid, count in costs:
            change_item_count(save, cid, -count, role_config, now)
        if reward:
            apply_reward(save, reward, role_config, now)
    elif opcode in watchstar.OPCODES:
        body, costs, reward = watchstar.prepare(opcode, save, request_body, role_config, now, random.getrandbits(64))
        for cid, count in costs:
            if count:
                change_item_count(save, cid, -count, role_config, now)
        if reward:
            apply_reward(save, reward, role_config, now)
        if opcode == 2065:
            activities.record_liveness(save, 8, 1, role_config, now)
    elif opcode in shop.OPCODES:
        body, costs, reward = shop.prepare(opcode, save, request_body, role_config, now)
        for cid, count in costs:
            change_item_count(save, cid, -count, role_config, now)
        if reward:
            apply_reward(save, reward, role_config, now)
    elif opcode in fashion.OPCODES:
        body, costs, general = fashion.prepare(opcode, save, request_body, role_config, now)
        for cid, count in costs:
            change_item_count(save, cid, -count, role_config, now)
        if general:
            record_protagonist_general(save, general)
            record_slot_update(save, encode_pb_field(1, 2, general)
                               + encode_pb_field(6, 2, bytes.fromhex(save["protagonist_snapshot"])))
    elif opcode in rob.OPCODES:
        body, costs, rewards = rob.prepare(opcode, save, request_body, role_config, random.getrandbits(64))
        for cid, count in costs:
            change_item_count(save, cid, -count, role_config, now)
        for reward in rewards:
            apply_reward(save, reward, role_config, now)
        if opcode in (1111, 1114, 1125):
            activities.record_liveness(save, 9, save["last_rob"]["attempts"], role_config, now)
            achievements.record(save, "robcount", save["last_rob"]["attempts"], role_config)
    elif opcode in WORLD_QUERY_IDS:
        body = bytes.fromhex(save["world_state"][str(opcode)])
        if opcode == 1002 and save.get("protagonist_snapshot"):
            protagonist = bytes.fromhex(save["protagonist_snapshot"])
            update = encode_pb_field(6, 2, protagonist)
            for field, wire, value in iter_pb_fields(protagonist):
                if field == 10 and wire == 2:
                    update += encode_pb_field(1, 2, value)
            record_slot_update(save, update)
            body = bytes.fromhex(save["world_state"]["1002"])
    elif opcode == 1001:
        get_role_state(save, role_config)
        settle_stamina(save, role_config, now)
        body = apply_role_state(bytes.fromhex(save["role_snapshot"]) if save.get("role_snapshot") else body, save, now)
        save["role_snapshot"] = body.hex()
    elif opcode == 201 and request_body and pb_get_varint(body, 1) == 1:
        record_guide_progress(save, request_body, step_counts)
    elif opcode == 202:
        ids = parse_ids_pb(request_body)
        if len(ids) != 1 or ids[0] <= 0 or not pb_get_varint(body, 1):
            raise ValueError("无效的选将请求或响应")
        if save.get("has_role"):
            raise ValueError("角色已创建，拒绝旧选将录制覆盖")
        save["selected_general_id"] = ids[0]
        save["has_role"] = True
        save["protagonist_snapshot"] = body.hex()
    elif opcode in (1050, 1054):
        body = bytes.fromhex(save["protagonist_snapshot"]) if save.get("protagonist_snapshot") else body
    elif opcode == 1055:
        previous = bytes.fromhex(save["protagonist_snapshot"]) if save.get("protagonist_snapshot") else b""
        ids = parse_ids_pb(request_body)
        if len(ids) != 2 or ids[0] not in (1, 2, 3) or ids[1] <= 0:
            raise ValueError("无效的主角培养请求")
        config = role_config["protagonist_grow"][str((pb_get_varint(body, 3) or 1) + 1)]
        attribute = {1: "atk", 2: "def", 3: "hp"}[ids[0]]
        increase = (pb_get_varint(body, ids[0] + 3) or 0) - (pb_get_varint(previous, ids[0] + 3) or 0)
        if ((pb_get_varint(previous, 3) or 1) != pb_get_varint(body, 3)
                or (pb_get_varint(previous, 2) or 1) > (pb_get_varint(body, 2) or 1)
                or increase != ids[1]):
            raise ValueError("已过期的主角培养录制，拒绝覆盖当前成长")
        change_item_count(save, int(config[f"{attribute}_cost"]), -increase * config[f"{attribute}_stone"], role_config, now)
        save["protagonist_snapshot"] = body.hex()
    elif opcode == 205:
        ids = parse_ids_pb(body)
        if len(ids) >= 6:
            get_role_state(save, role_config).update(power=ids[1], g_power=ids[3], power_all=ids[5])
    elif opcode in (1003, 1004, 1005, 1009, 1007, 1130, 1024, 1027, 1057):
        if opcode == 1004 and body:
            raise ValueError("助阵不使用历史录制结果，请单独操作")
        if opcode == 1130:
            body, costs = formation.strengthen_stones(save, request_body, role_config)
            for cid, count in costs:
                change_item_count(save, cid, -count, role_config, now)
        if opcode in (1003, 1004, 1005, 1007, 1009) and not body:
            body = formation.change(save, opcode, request_body, role_config)
        record_slot_update(save, body)
        old_protagonist = bytes.fromhex(save["protagonist_snapshot"]) if save.get("protagonist_snapshot") else b""
        old_growth = pb_get_varint(old_protagonist, 3) or 1
        for field, wire, value in iter_pb_fields(body):
            if field == 1 and wire == 2:
                record_protagonist_general(save, value)
            elif field == 6 and wire == 2 and opcode == 1057:
                previous = bytes.fromhex(save["protagonist_snapshot"]) if save.get("protagonist_snapshot") else b""
                level = pb_get_varint(value, 3)
                if level != old_growth + 1:
                    raise ValueError("已过期的主角进阶录制，拒绝覆盖当前成长")
                costs = role_config["protagonist_grow"][str(level)]["consume"]
                for cost in costs.split(";"):
                    if cost:
                        cid, amount = map(int, cost.split(","))
                        change_item_count(save, cid, -amount, role_config, now)
                general = next((v for n, w, v in iter_pb_fields(previous) if n == 10 and w == 2), None)
                save["protagonist_snapshot"] = (pb_set_field(value, 10, 2, general) if general else value).hex()
                if general:
                    get_role_state(save, role_config)["profile"] = pb_get_varint(general, 1)
        if opcode in (1003, 1004, 1005, 1007, 1009, 1130) and save.get("protagonist_snapshot"):
            record_slot_update(save, encode_pb_field(6, 2, bytes.fromhex(save["protagonist_snapshot"])))
    elif opcode == 1306:
        values = {n: v for n, w, v in iter_pb_fields(body)}
        if values.get(1) in (0, 1):
            if values[1] == 1:
                record_copy_win(save, request_body, values[2], role_config)
            exp = {n: v for n, w, v in iter_pb_fields(values[3])}
            state = get_role_state(save, role_config)
            # shortcut: 仅处理录制教程中递增的经验轨迹，任意重复战斗需实现真实结算。
            if (exp[2], exp[3]) <= (state["level"], state["exp"]):
                raise ValueError("战斗录制经验已过期，拒绝覆盖当前状态")
            apply_reward(save, values[4], role_config, now)
            settle_stamina(save, role_config, now)
            config = role_config["role_exp"][str(exp[2])]
            location = parse_ids_pb(request_body)
            state.update(level=exp[2], exp=exp[3], nextexp=config["nextexp"],
                         maxstamina=config["maxstamina"], maxenergy=config["maxenergy"])
            state["stamina"] -= role_config["copy"][str(location[0])][str(location[1])]["physical"]
            if state["stamina"] < 0:
                raise ValueError("体力不足")
            activities.record_liveness(save, 1, role_config["copy"][str(location[0])][str(location[1])]["physical"], role_config, now)
            for field, wire, value in iter_pb_fields(body):
                if field == 6 and wire == 2:
                    record_protagonist_general(save, value)
                    record_slot_update(save, encode_pb_field(1, 2, value))
    elif opcode in sigil.OPCODES:
        body, power_delta = sigil.prepare(opcode, save, request_body, role_config)
        if opcode in (1140, 1141):
            body = apply_sigil_update(save, body, power_delta, role_config)
    elif opcode in equip_baptize.OPCODES:
        body, costs, reward, power_delta, replaced = equip_baptize.prepare(opcode, save, request_body, role_config, random.getrandbits(64))
        state = get_role_state(save, role_config)
        for cid, count in costs:
            change_item_count(save, cid, -count, role_config, now)
        for key in ("power", "power_all"):
            state[key] += power_delta
            if not 0 <= state[key] < (1 << 31):
                raise ValueError("洗炼后的角色战力超出范围")
        apply_reward(save, reward, role_config, now)
        activities.record_liveness(save, 17, replaced, role_config, now)
        if costs:
            achievements.record(save, "equipbaptize", parse_ids_pb(request_body)[2], role_config)
        if save.get("protagonist_snapshot"):
            record_slot_update(save, encode_pb_field(6, 2, bytes.fromhex(save["protagonist_snapshot"])))
    elif opcode in (*training.OPCODES, *treasure_refine.OPCODES):
        if not body:
            if opcode == 1038:
                body, costs, power_delta = training.use_exp(save, request_body, role_config)
                for cid, count in costs:
                    change_item_count(save, cid, -count, role_config, now)
                raw = next(v for n, w, v in iter_pb_fields(body) if (n, w) == (8, 2))
                before = formation.records(bytes.fromhex(save["world_state"]["1002"]), 1, 2)[pb_get_varint(raw, 2)]
                qiankun.record_training(save, "general", before, raw, costs, qiankun.pristine_general(before, role_config, save))
            elif opcode in (1118, 1119, 1210):
                if opcode == 1119:
                    body, costs, power_delta = treasure_refine.prepare(save, request_body, role_config)
                else:
                    body, costs, power_delta = training.strengthen_treasure(save, opcode, request_body, role_config)
                for cid, count in costs:
                    change_item_count(save, cid, -count, role_config, now)
            else:
                body, power_delta = training.strengthen(save, opcode, request_body, role_config, random.getrandbits(64))
            state = get_role_state(save, role_config)
            for key in ("power", "power_all"):
                state[key] += power_delta
                if not 0 <= state[key] < (1 << 31):
                    raise ValueError("角色战力超出范围")
        if opcode in (1101, 1109):
            activities.record_strengthening(save, body, role_config, now)
        apply_reward(save, body, role_config, now)
        if save.get("protagonist_snapshot"):
            record_slot_update(save, encode_pb_field(6, 2, bytes.fromhex(save["protagonist_snapshot"])))
    elif opcode in (1201, 1304):
        if opcode == 1201:
            ids = parse_prop_use(request_body)
            config = role_config["props"][str(ids[0])]
            if config["type"] == "value":
                if not save.get("has_role"):
                    raise ValueError("角色尚未创建")
                if len(ids) != 2 or ids[1] > 100:
                    raise ValueError("恢复道具使用参数无效")
                # shortcut: 仅实现体力/精力恢复；挑战次数等需对应业务状态后再开放。
                resource = {"stamina": ("stamina", 3), "enery": ("energy", 4)}.get(config["param2"])
                if config["function"] != "attr" or not resource or config["use_limit"]:
                    raise ValueError("暂不支持的恢复道具")
                name, field = resource
                delta = int(config["param1"]) * ids[1]
                if delta <= 0 or get_role_state(save, role_config)[name] + delta >= (1 << 31):
                    raise ValueError("恢复资源超出范围")
                # 客户端自行扣除使用数量，usedcidnums 必须为空，避免重复扣道具。
                body = encode_pb_field(field, 0, delta) + b"".join(encode_pb_field(n, 2, b"") for n in (5, 7, 10))
            elif shop.openable_box(config) and not body:
                body = shop.open_box(save, ids, role_config, random.getrandbits(64))
            change_item_count(save, ids[0], -ids[1], role_config, now)
            if config["type"] == "keybox":
                change_item_count(save, int(config["param1"]), -ids[1], role_config, now)
        elif opcode == 1304:
            specification = record_copy_box(save, request_body, role_config)
            if not body:
                body = activities.build_reward(save, specification, role_config)
        apply_reward(save, body, role_config, now)
    elif opcode == 1403:
        if not body:
            body, cid, cost = recruit.draw(save, request_body, role_config, now, random.getrandbits(64))
            if cost:
                change_item_count(save, cid, -cost, role_config, now)
        else:
            ids = parse_ids_pb(request_body)
            if len(ids) != 2:
                raise ValueError("无效的招募请求")
            rewards = [data for mid, data in get_comb_messages(body) if mid == 1]
            owned = {pb_get_varint(v, 2) for n, w, v in iter_pb_fields(bytes.fromhex(save["world_state"]["1002"])) if n == 1 and w == 2}
            for reward in rewards:
                if any(n == 8 and w == 2 and pb_get_varint(v, 2) in owned for n, w, v in iter_pb_fields(reward)):
                    raise ValueError("不支持重复录制招募，拒绝覆盖已有武将")
            config = role_config["recruit_basic"][str(ids[0])]
            free = config["openfreerecruit"] == 0
            cost = 0 if free else config["count"]
            if cost:
                change_item_count(save, config["costid"], -cost, role_config, now)
            recruit.record_draw(save, ids[0], ids[1], free, cost, role_config, now)
        rewards = [data for mid, data in get_comb_messages(body) if mid == 1]
        for reward in rewards:
            apply_reward(save, reward, role_config, now)
        activities.record_liveness(save, 11, {1: 1, 2: 10, 3: 100}[parse_ids_pb(request_body)[1]], role_config, now)
    settle_stamina(save, role_config, now)
    return body


def prepare_recorded_responses(seq, responses, save, request_body, save_path, step_counts, role_config, connected_at, *, auto_sigils=None, guild_profit=None, guild_level=None, cup_rank=None):
    before = copy.deepcopy(save)
    now = int(time.time())
    if guild_level and responses and responses[0]["opcode"] in achievements.OPCODES:
        state = achievements.get_state(save, role_config)
        state["guild_level"] = guild_level()
    if cup_rank and responses and responses[0]["opcode"] in achievements.OPCODES:
        rank = cup_rank()
        if rank or "cup_state" in save:
            save["cup_state"] = dict(cup.get_state(save), best=rank)
        save["achievement_state"] = state
    if guild_profit and responses and responses[0]["opcode"] in (1101, 1109, 999900):
        save["guild_profit"] = guild_profit(now)
    self_update = settle_self_stats(save, role_config)
    settle_campaign(save, role_config, now)
    online_rewards.settle(save, role_config, connected_at, now)
    welfare.settle(save, now)
    settle_stamina(save, role_config, now)
    sigil_update = b""
    if auto_sigils:
        sigil_update, power_delta = sigil.auto_compose(save, role_config, auto_sigils)
        if sigil_update:
            apply_sigil_update(save, sigil_update, power_delta, role_config)
    automatic_reward = b""
    if responses and (responses[0]["opcode"] in arena.OPCODES
                      or responses[0]["opcode"] == 301 and pb_get_varint(request_body, 1) == 1):
        automatic_reward = arena.daily_reward(save, role_config, now)
        if automatic_reward:
            apply_reward(save, automatic_reward, role_config, now)
    starter = pets.starter(save, role_config) if responses and responses[0]["opcode"] == 1040 and not request_body else 0
    if starter:
        change_item_count(save, 91001, starter, role_config, now)
    if responses and responses[0]["opcode"] in mieshendian.QUERIES:
        automatic_reward = mieshendian.finish_sweep(save, role_config, now)
        if automatic_reward:
            apply_reward(save, automatic_reward, role_config, now)
            activities.record_liveness(save, 3, 1, role_config, now)
    packets = []
    if starter:
        fragments, _ = pets.prepare(1044, save, b"", role_config)
        packets.append(pack_frame(1044, 0, fragments))
    for response in responses:
        opcode = response["opcode"]
        body = prepare_recorded_response(opcode, bytes.fromhex(response["hex"]), save,
                                         request_body if response["seq"] != 0 else b"", step_counts, role_config, now)
        packets.append(pack_frame(opcode, seq if response["seq"] != 0 else 0, body))
    cheer_update, cheer_power = cheer.growth(save, before, role_config) if not responses or responses[0]["opcode"] != 1004 else (b"", 0)
    if cheer_update:
        apply_sigil_update(save, cheer_update, cheer_power, role_config)
        packets.append(pack_frame(1027, 0, bytes.fromhex(save["world_state"]["1002"])))
    if responses and responses[0]["opcode"] == 116:
        gift_id = save["recharge_state"]["bagid"]
        if gift_id in timebag.GIFTS and save.get(timebag.GIFTS[gift_id][0]) != before.get(timebag.GIFTS[gift_id][0]):
            packets.append(pack_frame(2882, 0, timebag.status_payload(save, role_config, now, gift_id)))
    if responses and responses[0]["opcode"] in (1046, 1062, 1065):
        for mid in (1040, 1044, 1047):
            raw, _ = pets.prepare(mid, save, b"", role_config)
            packets.append(pack_frame(mid, 0, raw))
        packets.append(pack_frame(1200, 0, bytes.fromhex(save["world_state"]["1200"])))
    if automatic_reward:
        for mid in WORLD_QUERY_IDS:
            if save["world_state"][str(mid)] != before["world_state"][str(mid)]:
                packets.append(pack_frame(mid, 0, bytes.fromhex(save["world_state"][str(mid)])))
    soul_change = responses and (responses[0]["opcode"] in soul.OPCODES or responses[0]["opcode"] == 1007 and parse_ids_pb(request_body)[1:2] == [2])
    if soul_change and save["world_state"]["1002"] != before["world_state"]["1002"]:
        packets.append(pack_frame(1002, 0, bytes.fromhex(save["world_state"]["1002"])))
    if responses and responses[0]["opcode"] in (*penglai.MUTATIONS, *equip_baptize.OPCODES, *treasure_refine.OPCODES, *general_foster.OPCODES, *magic.MUTATIONS, *soul.MUTATIONS) and save["world_state"]["1200"] != before["world_state"]["1200"]:
        packets.append(pack_frame(1200, 0, bytes.fromhex(save["world_state"]["1200"])))
    if responses and responses[0]["opcode"] in (1120, 1365) and save["world_state"]["1002"] != before["world_state"]["1002"]:
        packets.append(pack_frame(1027, 0, bytes.fromhex(save["world_state"]["1002"])))
    baptize_cost = responses and responses[0]["opcode"] in equip_baptize.OPCODES and save["world_state"]["1002"] != before["world_state"]["1002"]
    if automatic_reward or baptize_cost or responses and responses[0]["opcode"] in (301, 3624, 3626, 3628, 1046, 1061, 1062, 1065, 3674, 3675, *cornucopia.MUTATIONS, *penglai.MUTATIONS, *treasure_refine.OPCODES, *general_foster.OPCODES, *magic.MUTATIONS, *soul.MUTATIONS):
        packets.append(pack_frame(1001, 0, apply_role_state(bytes.fromhex(save["role_snapshot"]), save, now)))
    pet_update = save.get("pet_state") != before.get("pet_state") and save["world_state"]["1002"] != before["world_state"]["1002"]
    if pet_update or self_update:
        packets.append(pack_frame(1027, 0, bytes.fromhex(save["world_state"]["1002"])))
    local_update = (responses and responses[0]["opcode"] in (1003, 1004, 1005, 1006, 1007, 1009, 1130, *training.OPCODES, *fashion.TRANSACTIONS, *soul.MUTATIONS, 1077,
                                                         *development.MUTATIONS, *pets.MUTATIONS, *favorite.MUTATIONS, *equip_baptize.OPCODES, *treasure_refine.OPCODES, *general_foster.OPCODES, *magic.MUTATIONS, 1140, 1141) and not responses[0]["hex"])
    break_comb = responses and responses[0]["opcode"] == 999900 and any(mid == 1017 for mid, _ in get_comb_messages(request_body))
    if local_update or break_comb or pet_update or self_update or sigil_update or cheer_update:
        state, previous = save["role_state"], get_role_state(before, role_config)
        if any(state[key] != previous[key] for key in ("power", "g_power", "power_all")):
            power = b"".join(encode_pb_field(1, 0, value & ((1 << 64) - 1)) for value in
                             (state["power"] - previous["power"], state["power"], state["g_power"] - previous["g_power"], state["g_power"],
                              state["power_all"] - previous["power_all"], state["power_all"]))
            packets.append(pack_frame(205, 0, power))
    return save_response_group(packets, save, before, save_path, step_counts, role_config, now)


def save_response_group(packets, save, before, save_path, step_counts, role_config, now):
    collection.observe(save, role_config, before)
    achievements.observe(save, role_config, before)
    activities.settle_liveness(save, role_config, now)
    state = save.get("role_state")
    if state:
        for name, key in (("level", "level"), ("coin", "silver"), ("gold", "gold"), ("energy", "energy")):
            save[key] = state[name]
        if save.get("role_snapshot"):
            save["role_snapshot"] = apply_role_state(bytes.fromhex(save["role_snapshot"]), save, now).hex()
    if before.get("has_role"):
        previous_hints = activities.get_hints(before, role_config, now)
        changes = b"".join(encode_pb_field(1, 2, encode_pb_field(1, 0, mid) + encode_pb_field(2, 0, status))
                           for mid, status in activities.get_hints(save, role_config, now).items()
                           if status != previous_hints[mid])
        if changes:
            packets.append(pack_frame(1034, 0, changes))
    if save != before and not save_role(save, save_path, step_counts):
        raise OSError("角色状态保存失败，不发送成功响应")
    return packets


def prepare_battle_responses(seq, save, request_body, save_path, step_counts, role_config, connected_at, *, opcode=1306, guild_profit=None):
    before = copy.deepcopy(save)
    now = int(time.time())
    if guild_profit:
        save["guild_profit"] = guild_profit(now)
    self_update = settle_self_stats(save, role_config)
    settle_campaign(save, role_config, now)
    online_rewards.settle(save, role_config, connected_at, now)
    welfare.settle(save, now)
    settle_stamina(save, role_config, now)
    if opcode == 1307:
        point, attempts = battle.sweep(save, request_body, role_config)
        old_star = 3
        location = encode_pb_field(1, 0, point["map"]) + encode_pb_field(1, 0, point["point"])
    else:
        point, old_star = battle.challenge(save, request_body, role_config)
        attempts, location = 1, request_body
    attack, defense = battle.rosters(save, point, role_config)
    from . import guild_war
    for unit in attack.values():
        unit["atk"] = unit["atk"] * (100 + guild_war.effect(save, role_config, 4)) // 100
    seed = random.getrandbits(64)
    report = None if opcode == 1307 else battle.simulate(attack, defense, role_config, seed, attack_pet=pets.combat(save, role_config), attack_cheer=cheer.combat(save, role_config))
    if report is not None:
        report["meta"]["attack"]["n"] = save.get("role_name") or "主角"
        report["meta"]["defense"]["n"] = point["name"]
    won, star = (True, 3) if report is None else (report["result"], report["star"])
    state = get_role_state(save, role_config)
    rewards, generals, experience, power_delta = {}, [], b"", 0
    gained = 0
    if won:
        for index in range(attempts):
            reward = battle.victory_role_reward(state, point, old_star, star, role_config)
            reward["coin"] = reward["coin"] * (100 + guild_war.effect(save, role_config, 1)) // 100
            drops = battle.drops(point, old_star == 0, role_config, (seed + index) ^ 0xD09)
            for cid, name in ((1000, "coin"), (1001, "gold")):
                if reward[name]:
                    drops[cid] = drops.get(cid, 0) + reward[name]
            for cid, count in drops.items():
                rewards[cid] = rewards.get(cid, 0) + count
            gained += reward["gained"]
            state.update(level=reward["level"], exp=reward["exp"])
        level_config = role_config["role_exp"][str(state["level"])]
        state.update(nextexp=level_config["nextexp"],
                     maxstamina=level_config["maxstamina"] + favorite.capacity_bonus(save, role_config, "maxstamina"),
                     maxenergy=level_config["maxenergy"] + favorite.capacity_bonus(save, role_config, "maxenergy"))
        world = bytes.fromhex(save["world_state"]["1002"])
        records = formation.records(world, 1, 2)
        slots = formation.records(world, 4, 2)
        equips = formation.records(world, 2, 1)
        members = cheer.members(save, role_config)
        maximum = min(state["level"] * int(role_config["global_kv"]["general_level"]["value"]),
                      max(map(int, role_config["general_exp"])))
        for _, unit in sorted(attack.items()):
            raw, increase, up = training.grow_general(records[unit["iid"]], point["xp"] * attempts, slots[unit["iid"]],
                                                     members, equips, role_config, maximum, cheer_tiers=cheer.tiers(save, role_config))
            record_slot_update(save, encode_pb_field(1, 2, raw))
            record_protagonist_general(save, raw)
            generals.append(encode_pb_field(6, 2, raw))
            power_delta += increase
            experience += encode_pb_field(4, 2, b"".join(encode_pb_field(n, 0, v) for n, v in
                                                        ((1, unit["iid"]), (2, point["xp"] * attempts), (3, int(up > 0)))))
        if save.get("protagonist_snapshot"):
            record_slot_update(save, encode_pb_field(6, 2, bytes.fromhex(save["protagonist_snapshot"])))
        for key in ("power", "power_all"):
            state[key] += power_delta
            if not 0 <= state[key] < (1 << 31):
                raise ValueError("角色战力超出范围")
        for _ in range(attempts):
            record_copy_win(save, location, star, role_config, allow_repeat=True)
    reward_body = activities.build_reward(save, ";".join(f"{cid},{count}" for cid, count in sorted(rewards.items())), role_config)
    apply_reward(save, reward_body, role_config, now)
    state["stamina"] -= point["physical"] * attempts
    activities.record_liveness(save, 1, point["physical"] * attempts, role_config, now)
    settle_stamina(save, role_config, now)
    experience = b"".join(encode_pb_field(n, 0, v) for n, v in ((1, gained), (2, state["level"]), (3, state["exp"]))) + experience
    body = (encode_pb_field(1, 0, int(won)) + encode_pb_field(2, 0, star)
             + encode_pb_field(3, 2, experience) + encode_pb_field(4, 2, reward_body)
            + (encode_pb_field(5, 2, json.dumps(report, ensure_ascii=False, separators=(",", ":")).encode("utf-8")) if report is not None else b"")
             + b"".join(generals))
    packets = [pack_frame(opcode, seq, body)]
    if self_update:
        packets.append(pack_frame(1027, 0, bytes.fromhex(save["world_state"]["1002"])))
    power_delta = state["power"] - get_role_state(before, role_config)["power"]
    if power_delta:
        power = b"".join(encode_pb_field(1, 0, value) for value in
                         (power_delta, state["power"], 0, state["g_power"], power_delta, state["power_all"]))
        packets.append(pack_frame(205, 0, power))
    if save.get("role_snapshot"):
        # 放在关卡应答后同步绝对值，避免客户端再按挑战/扫荡成本扣第二次。
        packets.append(pack_frame(1001, 0, apply_role_state(bytes.fromhex(save["role_snapshot"]), save, now)))
    if report is not None:
        save["last_battle"] = {"rules": report["rules"], "seed": seed, "map": point["map"], "point": point["point"],
                               "won": won, "star": star, "rounds": report["round"]}
    packets = save_response_group(packets, save, before, save_path, step_counts, role_config, now)
    if report is None:
        print_flush(f"[扫荡] {point['map']}/{point['point']} seed={seed} 次数={attempts}")
    else:
        print_flush(f"[战斗 v2] {point['map']}/{point['point']} seed={seed} 胜={won} 星={star} 回合={report['round']}")
    return packets
