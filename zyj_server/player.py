"""玩家存档与录制操作的状态更新；整组回包准备、原子保存后才交给调用方。"""

import copy
import functools
import json
import os
import tempfile
import time
import zipfile

from .guide import describe_guide, get_guide_sections, migrate_guide, record_guide_progress
from .protocol import (
    encode_pb_field, get_comb_messages, iter_pb_fields, pack_frame,
    parse_ids_pb, pb_get_varint, pb_set_field, pb_set_varint,
)

print_flush = functools.partial(print, flush=True)

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
                for name in ("role_exp", "copy", "protagonist_grow")}


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


def apply_role_state(body, save):
    """把存档里的角色状态回填进 Role 消息，避免回放录制数据时把等级/货币冲掉。"""
    st = save.get("role_state") or {}
    for k, fn in ROLE_FIELD_MAP.items():
        v = st.get(k)
        if type(v) is int and v >= 0:
            body = pb_set_varint(body, fn, v)
    if save.get("role_name"):
        body = pb_set_field(body, 3, 2, save["role_name"].encode("utf-8"))
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
        save["role_snapshot"] = apply_role_state(bytes.fromhex(save["role_snapshot"]), save).hex()
    return True


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
        elif field == 8 and wire == 2:
            record_protagonist_general(save, value)


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


def prepare_recorded_response(opcode, body, save, request_body, step_counts, role_config):
    if opcode == 999900:
        requests = dict(get_comb_messages(request_body))
        messages = iter(get_comb_messages(body))
        out = bytearray()
        for field, wire, value in iter_pb_fields(body):
            if field == 1 and wire == 2:
                mid, data = next(messages)
                updated = prepare_recorded_response(mid, data, save, requests.get(mid, b""), step_counts, role_config)
                if updated != data:
                    value = pb_set_field(value, 2, 2, updated)
            out.extend(encode_pb_field(field, wire, value))
        return bytes(out)
    if opcode == 1001:
        get_role_state(save, role_config)
        body = apply_role_state(bytes.fromhex(save["role_snapshot"]) if save.get("role_snapshot") else body, save)
        save["role_snapshot"] = body.hex()
    elif opcode == 201 and request_body and pb_get_varint(body, 1) == 1:
        record_guide_progress(save, request_body, step_counts)
    elif opcode == 202:
        ids = parse_ids_pb(request_body)
        if len(ids) != 1 or ids[0] <= 0 or not pb_get_varint(body, 1):
            raise ValueError("无效的选将请求或响应")
        save["selected_general_id"] = ids[0]
        save["has_role"] = True
        save["protagonist_snapshot"] = body.hex()
    elif opcode in (1050, 1054):
        body = bytes.fromhex(save["protagonist_snapshot"]) if save.get("protagonist_snapshot") else body
    elif opcode == 1055:
        save["protagonist_snapshot"] = body.hex()
    elif opcode == 205:
        ids = parse_ids_pb(body)
        if len(ids) >= 6:
            get_role_state(save, role_config).update(power=ids[1], g_power=ids[3], power_all=ids[5])
    elif opcode in (1003, 1007, 1024, 1027, 1057):
        old_protagonist = bytes.fromhex(save["protagonist_snapshot"]) if save.get("protagonist_snapshot") else b""
        old_growth = pb_get_varint(old_protagonist, 3) or 1
        for field, wire, value in iter_pb_fields(body):
            if field == 1 and wire == 2:
                record_protagonist_general(save, value)
            elif field == 6 and wire == 2 and opcode == 1057:
                previous = bytes.fromhex(save["protagonist_snapshot"]) if save.get("protagonist_snapshot") else b""
                level = pb_get_varint(value, 3)
                if level and level > old_growth:
                    costs = role_config["protagonist_grow"][str(level)]["consume"]
                    for cost in costs.split(";"):
                        if cost:
                            cid, amount = map(int, cost.split(","))
                            if cid in (1000, 1001):
                                reward_field = 1 if cid == 1000 else 2
                                apply_reward(save, encode_pb_field(reward_field, 0, (-amount) & ((1 << 64) - 1)), role_config)
                general = next((v for n, w, v in iter_pb_fields(previous) if n == 10 and w == 2), None)
                save["protagonist_snapshot"] = (pb_set_field(value, 10, 2, general) if general else value).hex()
                if general:
                    get_role_state(save, role_config)["profile"] = pb_get_varint(general, 1)
    elif opcode == 1306:
        values = {n: v for n, w, v in iter_pb_fields(body)}
        if values.get(1) in (0, 1):
            exp = {n: v for n, w, v in iter_pb_fields(values[3])}
            state = get_role_state(save, role_config)
            # shortcut: 仅处理录制教程中递增的经验轨迹，任意重复战斗需实现真实结算。
            if (exp[2], exp[3]) > (state["level"], state["exp"]):
                apply_reward(save, values[4], role_config)
                config = role_config["role_exp"][str(exp[2])]
                location = parse_ids_pb(request_body)
                state.update(level=exp[2], exp=exp[3], nextexp=config["nextexp"],
                             maxstamina=config["maxstamina"], maxenergy=config["maxenergy"])
                # shortcut: 体力仅按录制操作消耗，按时间恢复需接入服务端时钟。
                state["stamina"] -= role_config["copy"][str(location[0])][str(location[1])]["physical"]
                if state["stamina"] < 0:
                    raise ValueError("体力不足")
            for field, wire, value in iter_pb_fields(body):
                if field == 6 and wire == 2:
                    record_protagonist_general(save, value)
    elif opcode in (1109, 1201, 1304):
        apply_reward(save, body, role_config)
    elif opcode == 1403:
        for mid, data in get_comb_messages(body):
            if mid == 1:
                apply_reward(save, data, role_config)
    return body


def prepare_recorded_responses(seq, responses, save, request_body, save_path, step_counts, role_config):
    before = copy.deepcopy(save)
    packets = []
    for response in responses:
        opcode = response["opcode"]
        body = prepare_recorded_response(opcode, bytes.fromhex(response["hex"]), save,
                                         request_body if response["seq"] != 0 else b"", step_counts, role_config)
        packets.append(pack_frame(opcode, seq if response["seq"] != 0 else 0, body))
    state = save.get("role_state")
    if state:
        for name, key in (("level", "level"), ("coin", "silver"), ("gold", "gold"), ("energy", "energy")):
            save[key] = state[name]
        if save.get("role_snapshot"):
            save["role_snapshot"] = apply_role_state(bytes.fromhex(save["role_snapshot"]), save).hex()
    if save != before and not save_role(save, save_path, step_counts):
        raise OSError("角色状态保存失败，不发送成功响应")
    return packets
