"""玩家存档与录制操作的状态更新；整组回包准备、原子保存后才交给调用方。"""

import copy
import functools
import json
import os
import tempfile
import time
import zipfile

from . import activities
from .guide import describe_guide, get_guide_sections, migrate_guide, record_guide_progress
from .protocol import (
    encode_pb_field, get_comb_messages, iter_pb_fields, pack_frame,
    parse_ids_pb, pb_get_varint, pb_set_field, pb_set_varint,
)

print_flush = functools.partial(print, flush=True)

WORLD_QUERY_IDS = (1002, 1012, 1200, 1300)
SLOT_RECORD_KEYS = {1: 2, 2: 1, 4: 1, 5: 1}
STAMINA_INTERVAL = 360  # 多份 Role 抓包的全部/下次恢复倒计时之差可交叉验证。

# role_pb.Role 的字段号。
ROLE_FIELD_MAP = {
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
    "g_power": 26,
    "power_all": 27,
}


def load_role_config(config_path):
    with zipfile.ZipFile(config_path) as config_zip:
        return {name: json.loads(config_zip.read(f"5/{name}.json"))
                for name in ("role_exp", "copy", "protagonist_grow", "map", "props", "general_fragment", "recruit_basic",
                             "begin7day_task", "liveness", "liveness_reward", "week_liveness_reward", "equip")}


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
    return get_default_save()


def save_role(save_data, save_path, step_counts):
    temporary_path = None
    try:
        save_data["last_login"] = time.time()
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
    defaults = {"exp": 0, "nextexp": config["nextexp"], "coin": save.get("silver", 0),
                "gold": save.get("gold", 0), "stamina": config["maxstamina"],
                "maxstamina": config["maxstamina"], "energy": save.get("energy", 20),
                "maxenergy": config["maxenergy"], "power": 0, "g_power": 0, "power_all": 0}
    for name, value in defaults.items():
        state.setdefault(name, value)
    if any(type(value) is not int or value < 0 for name, value in state.items() if name in ROLE_FIELD_MAP):
        raise ValueError("角色数值必须是非负整数")
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
                elif mid in (1012, 1200):
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


def change_item_count(save, cid, delta, role_config):
    if cid in (1000, 1001, 1003):
        field = {1000: 1, 1001: 2, 1003: 4}[cid]
        apply_reward(save, encode_pb_field(field, 0, delta & ((1 << 64) - 1)), role_config)
        return
    fragment = role_config["general_fragment"].get(str(cid))
    if fragment is None and str(cid) not in role_config["props"]:
        fragment = next((row for row in role_config["general_fragment"].values() if row["general"] == cid), None)
    query = "1012" if fragment else "1200"
    if fragment:
        cid = fragment["general"]
    elif str(cid) not in role_config["props"]:
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


def record_copy_win(save, request_body, star, role_config):
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
    # shortcut: 录制战斗只支持首次通关，重复战斗需真实结算；拒绝旧回包覆盖当前属性。
    if point_id in points and pb_get_varint(points[point_id], 3):
        raise ValueError("已通关关卡不支持重复录制战斗")
    point = b"".join(encode_pb_field(n, 0, v) for n, v in ((1, point_id), (2, 0), (3, star), (4, 1)))
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


def record_copy_box(save, request_body):
    ids = parse_ids_pb(request_body)
    if len(ids) != 2 or ids[1] not in (0, 3, 6):
        raise ValueError("无效的副本宝箱请求")
    copies = bytes.fromhex(save["world_state"]["1300"])
    current = next((v for n, w, v in iter_pb_fields(copies) if n == 1 and w == 2 and pb_get_varint(v, 1) == ids[0]), None)
    field = {0: 4, 3: 5, 6: 6}[ids[1]]
    if current is None or pb_get_varint(current, field) != 2:
        raise ValueError("副本宝箱未解锁或已领取")
    current = pb_set_varint(current, field, 3)
    save["world_state"]["1300"] = merge_pb_records(copies, encode_pb_field(1, 2, current), {1: 1}).hex()


def apply_reward(save, body, role_config):
    state = get_role_state(save, role_config)
    for field, wire, value in iter_pb_fields(body):
        if field in (1, 2, 3, 4) and wire == 0:
            name = {1: "coin", 2: "gold", 3: "stamina", 4: "energy"}[field]
            delta = value - (1 << 64) if value >= (1 << 63) else value
            balance = state[name] + delta
            if balance < 0:
                raise ValueError(f"{name} 不足，拒绝录制操作")
            state[name] = balance
        elif field in (5, 10) and wire == 2:
            for n, w, record in iter_pb_fields(value):
                if n == 1 and w == 2:
                    cid, count = pb_get_varint(record, 1), pb_get_varint(record, 2)
                    if cid is None or count is None:
                        raise ValueError("道具变更缺少 ID/数量")
                    count = (count & 0xffffffff) - (1 << 32) if count & (1 << 31) else count
                    change_item_count(save, cid, count if field == 5 else -count, role_config)
        elif field == 6 and wire == 2:
            record_slot_update(save, encode_pb_field(2, 2, value))
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


def prepare_recorded_response(opcode, body, save, request_body, step_counts, role_config, now):
    if opcode == 999900:
        requests = dict(get_comb_messages(request_body))
        messages = iter(get_comb_messages(body))
        out = bytearray()
        for field, wire, value in iter_pb_fields(body):
            if field == 1 and wire == 2:
                mid, data = next(messages)
                updated = prepare_recorded_response(mid, data, save, requests.get(mid, b""), step_counts, role_config, now)
                if updated != data:
                    value = pb_set_field(value, 2, 2, updated)
            out.extend(encode_pb_field(field, wire, value))
        return bytes(out)
    if opcode == 999905:
        if request_body:
            raise ValueError("时间查询不接受参数")
        # 客户端把第二项取反作为时区；沿用抓包的 UTC+8，不跟随宿主机时区。
        body = encode_pb_field(1, 0, now) + encode_pb_field(1, 0, (-8) & ((1 << 64) - 1))
    elif opcode in activities.OPCODES:
        body = activities.prepare_response(opcode, save, request_body, role_config)
        if opcode in activities.CLAIM_OPCODES:
            apply_reward(save, body, role_config)
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
        change_item_count(save, int(config[f"{attribute}_cost"]), -increase * config[f"{attribute}_stone"], role_config)
        save["protagonist_snapshot"] = body.hex()
    elif opcode == 205:
        ids = parse_ids_pb(body)
        if len(ids) >= 6:
            get_role_state(save, role_config).update(power=ids[1], g_power=ids[3], power_all=ids[5])
    elif opcode in (1003, 1007, 1024, 1027, 1057):
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
                        change_item_count(save, cid, -amount, role_config)
                general = next((v for n, w, v in iter_pb_fields(previous) if n == 10 and w == 2), None)
                save["protagonist_snapshot"] = (pb_set_field(value, 10, 2, general) if general else value).hex()
                if general:
                    get_role_state(save, role_config)["profile"] = pb_get_varint(general, 1)
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
            apply_reward(save, values[4], role_config)
            settle_stamina(save, role_config, now)
            config = role_config["role_exp"][str(exp[2])]
            location = parse_ids_pb(request_body)
            state.update(level=exp[2], exp=exp[3], nextexp=config["nextexp"],
                         maxstamina=config["maxstamina"], maxenergy=config["maxenergy"])
            state["stamina"] -= role_config["copy"][str(location[0])][str(location[1])]["physical"]
            if state["stamina"] < 0:
                raise ValueError("体力不足")
            for field, wire, value in iter_pb_fields(body):
                if field == 6 and wire == 2:
                    record_protagonist_general(save, value)
                    record_slot_update(save, encode_pb_field(1, 2, value))
    elif opcode in (1109, 1201, 1304):
        if opcode == 1109:
            activities.record_strengthening(save, body, role_config)
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
            change_item_count(save, ids[0], -ids[1], role_config)
            if config["type"] == "keybox":
                change_item_count(save, int(config["param1"]), -ids[1], role_config)
        elif opcode == 1304:
            record_copy_box(save, request_body)
        apply_reward(save, body, role_config)
    elif opcode == 1403:
        ids = parse_ids_pb(request_body)
        if len(ids) != 2:
            raise ValueError("无效的招募请求")
        rewards = [data for mid, data in get_comb_messages(body) if mid == 1]
        owned = {pb_get_varint(v, 2) for n, w, v in iter_pb_fields(bytes.fromhex(save["world_state"]["1002"])) if n == 1 and w == 2}
        for reward in rewards:
            if any(n == 8 and w == 2 and pb_get_varint(v, 2) in owned for n, w, v in iter_pb_fields(reward)):
                raise ValueError("不支持重复录制招募，拒绝覆盖已有武将")
        config = role_config["recruit_basic"][str(ids[0])]
        if config["openfreerecruit"] == 1 and ids[1] == 1:
            change_item_count(save, config["costid"], -config["count"], role_config)
        # shortcut: 录制招募仅覆盖各自首次，后续招募及冷却/付费规则需真实业务实现。
        for reward in rewards:
            apply_reward(save, reward, role_config)
    settle_stamina(save, role_config, now)
    return body


def prepare_recorded_responses(seq, responses, save, request_body, save_path, step_counts, role_config):
    before = copy.deepcopy(save)
    now = int(time.time())
    settle_stamina(save, role_config, now)
    packets = []
    for response in responses:
        opcode = response["opcode"]
        body = prepare_recorded_response(opcode, bytes.fromhex(response["hex"]), save,
                                         request_body if response["seq"] != 0 else b"", step_counts, role_config, now)
        packets.append(pack_frame(opcode, seq if response["seq"] != 0 else 0, body))
    state = save.get("role_state")
    if state:
        for name, key in (("level", "level"), ("coin", "silver"), ("gold", "gold"), ("energy", "energy")):
            save[key] = state[name]
        if save.get("role_snapshot"):
            save["role_snapshot"] = apply_role_state(bytes.fromhex(save["role_snapshot"]), save, now).hex()
    if save != before and not save_role(save, save_path, step_counts):
        raise OSError("角色状态保存失败，不发送成功响应")
    return packets
