#!/usr/bin/env python3
"""
作妖记 (ZuoYaoJi) 本地 Mock 模拟游戏服务端 (全流程引导与渐进式持久化)
设计原则:
1. 不强行跳过新手引导: 新玩家从头正常跑完整新手流程 (开场漫画 -> 随机起名 -> 选初始武将 -> 新手第一战 -> 升级奖励 -> 主线副本)。
2. 实时记录玩家真实操作:
   - 玩家自定义或随机起名 (Opcode 101) -> 实时存入存档文件 role_save.json
   - 玩家选择的初始武将 (Opcode 202) -> 实时记录武将 ID
   - 玩家推进引导步骤 (Opcode 201) -> 实时更新 guide.step
3. 断点续玩支持: 若中途退出，下次登录根据玩家实际游玩进度平滑继续，绝不漏步也绝不强关。
4. 引导状态严格对齐客户端 (guideControl.lua / guidequery_pb.lua):
   - status = 1 -> 该段引导进行中, 客户端从 step+1 恢复
   - status = 2 -> 该段已完成
   - sections 为空 -> 全新号, 客户端从头播开场剧情
   - 完成判定依据 configs_sec5.zip 里 guide_step.json 的真实步数 (Section 1 = 83 步),
     不再写死阈值, 避免客户端判定"无引导"而静默跳主城。
5. 命令行:
   - `python3 mock_server.py --reset`        清空整个存档, 从 0 开始
   - `python3 mock_server.py --reset-guide`  只清引导进度(保留角色名), 可重播新手引导
"""

import functools
import copy
print_flush = functools.partial(print, flush=True)

import socket
import struct
import json
import os
import sys
import subprocess
import threading
import time
import zipfile
import tempfile

PORT = 14600
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
RECORD_PATH = os.path.join(BASE_DIR, "recorded_frames.json")
SAVE_PATH = os.path.join(BASE_DIR, "role_save.json")
CONFIG_ZIP = os.path.join(BASE_DIR, "configs_sec5.zip")

# ==================== 0. 真实引导配置 ====================
# 客户端 guideControl.lua 完全依据 guide_step.json / guide_section.json 推进引导,
# 服务端不能再拍脑袋定"第几步算完成", 必须按真实配置判定。
# 语义 (见 guideControl.lua 的 _guide.Init):
#   status == 1 -> 该 Section 引导进行中, 客户端从 step+1 恢复
#   status == 2 -> 该 Section 已完成
#   status == 0 -> 客户端不认, 等于"没有引导在跑", 会直接跳主城 (历史 Bug 根因)

def load_guide_step_counts():
    counts = {}
    try:
        with zipfile.ZipFile(CONFIG_ZIP) as z:
            step_cfg = json.loads(z.read("5/guide_step.json").decode("utf-8"))
            for sec, steps in step_cfg.items():
                counts[int(sec)] = len(steps)
        print_flush(f"[*] 引导配置就绪: 共 {len(counts)} 个 Section, Section 1 共 {counts.get(1, 0)} 步")
    except Exception as e:
        print_flush(f"[!] 读取引导配置失败 ({e})，完成判定将退化为仅依赖客户端上报")
    return counts

GUIDE_STEP_COUNTS = load_guide_step_counts()
with zipfile.ZipFile(CONFIG_ZIP) as config_zip:
    ROLE_EXP_CONFIG = json.loads(config_zip.read("5/role_exp.json"))
    COPY_CONFIG = json.loads(config_zip.read("5/copy.json"))
    PROTAGONIST_GROW_CONFIG = json.loads(config_zip.read("5/protagonist_grow.json"))

# ==================== 1. 渐进式存档管理 ====================

def get_default_save():
    return {
        "has_role": False,
        "role_name": "",
        "selected_general_id": 0,
        "level": 1,
        "gold": 0,
        "silver": 0,
        "energy": 20,
        # sections: { "<section号>": {"status": 1|2, "step": 最后完成的步数} }
        # 空字典 = 全新号, 客户端会从头播开场剧情
        "guide": {"sections": {}},
        "created_at": time.time(),
        "last_login": time.time()
    }

def normalize_sections(sections):
    """按真实配置纠正状态: 步数已达上限 -> 2(已完成); 否则只要起步就是 1(进行中)。"""
    fixed = {}
    for sec, st in sections.items():
        try:
            sec_i = int(sec)
        except Exception:
            continue
        step = int(st.get("step", 0) or 0)
        status = int(st.get("status", 0) or 0)
        total = GUIDE_STEP_COUNTS.get(sec_i, 0)
        if step <= 0 and not st.get("steps"):
            continue
        # 保留客户端上报过的完整步骤轨迹 (用于排障; 200 应答只回传最后一步)
        history = st.get("steps") or []
        if isinstance(history, list):
            history = sorted({int(x) for x in history if str(x).isdigit()})
            if step > 0 and step not in history:
                history.append(step)
                history.sort()
        else:
            history = [step] if step > 0 else []
        # 对齐官方抓包: 200 应答里的 step = 客户端"最后上报的那一步"
        # (官方样例 0a06080110021851 -> section=1, status=2, step=81)
        # redo==0 的步骤在 Comb 内上报，不能只看独立的 201 请求。
        if total and step >= total:
            status = 2
        elif status != 2:
            status = 1
        fixed[str(sec_i)] = {"status": status, "step": step, "steps": history}
    return fixed

def migrate_guide(save):
    """兼容旧存档: 旧结构是 {section,status,step}, 且 status 只会是 0/2。"""
    g = save.get("guide")
    if not isinstance(g, dict):
        save["guide"] = {"sections": {}}
        return save
    if "sections" not in g:
        sec = int(g.get("section", 1) or 1)
        step = int(g.get("step", 0) or 0)
        sections = {}
        if step > 0:
            # 旧版本用 0 表示"进行中", 客户端不认, 这里纠正为 1
            sections[str(sec)] = {"status": int(g.get("status", 0) or 0), "step": step}
        save["guide"] = {"sections": sections}
    save["guide"]["sections"] = normalize_sections(save["guide"].get("sections", {}))
    return save

def load_save():
    if os.path.exists(SAVE_PATH):
        try:
            with open(SAVE_PATH, "r", encoding="utf-8") as f:
                data = json.load(f)
                return migrate_guide(data)
        except Exception as e:
            print_flush(f"[!] 读取存档失败 ({e})，保留原文件并停止加载")
            raise ValueError("存档读取失败，拒绝用空进度覆盖") from e
    return get_default_save()

def save_role(save_data):
    temporary_path = None
    try:
        save_data["last_login"] = time.time()
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=os.path.dirname(SAVE_PATH), delete=False) as f:
            temporary_path = f.name
            json.dump(save_data, f, ensure_ascii=False, indent=2)
        os.replace(temporary_path, SAVE_PATH)
        temporary_path = None
        print_flush(f"[✓] 进度实时落盘: 角色【{save_data.get('role_name', '未起名')}】 (Lv.{save_data.get('level', 1)}, 引导: {describe_guide(get_guide_sections(save_data))})")
        return True
    except Exception as e:
        print_flush(f"[!] 保存存档失败: {e}")
        return False
    finally:
        if temporary_path is not None:
            os.unlink(temporary_path)

# ==================== 2. Protobuf 编解码辅助 ====================

def encode_varint(n):
    res = bytearray()
    while True:
        b = n & 0x7f
        n >>= 7
        if n:
            res.append(b | 0x80)
        else:
            res.append(b)
            break
    return bytes(res)

def parse_varint(buf, pos):
    res = 0
    for shift in range(0, 70, 7):
        if pos >= len(buf):
            raise ValueError("截断的 Protobuf varint")
        b = buf[pos]
        pos += 1
        if shift == 63 and b > 1:
            raise ValueError("Protobuf varint 超出 64 位")
        res |= (b & 0x7f) << shift
        if not (b & 0x80):
            return res, pos
    raise ValueError("无终止字节的 Protobuf varint")

def iter_pb_fields(raw):
    pos = 0
    while pos < len(raw):
        tag, pos = parse_varint(raw, pos)
        fn, wt = tag >> 3, tag & 7
        if not 0 < fn < (1 << 29):
            raise ValueError("无效的 Protobuf 字段号")
        if wt == 0:
            value, pos = parse_varint(raw, pos)
        elif wt in (1, 2, 5):
            if wt == 2:
                length, pos = parse_varint(raw, pos)
            else:
                length = 8 if wt == 1 else 4
            end = pos + length
            if end > len(raw):
                raise ValueError("截断的 Protobuf 字段")
            value, pos = raw[pos:end], end
        else:
            raise ValueError(f"不支持的 Protobuf wire type: {wt}")
        yield fn, wt, value

def get_comb_messages(raw):
    messages = []
    for fn, wt, value in iter_pb_fields(raw):
        if fn != 1:
            continue
        if wt != 2:
            raise ValueError("Comb messages 字段必须是嵌套消息")
        mid, data = None, b""
        for sfn, swt, sub in iter_pb_fields(value):
            if sfn == 1:
                if swt != 0:
                    raise ValueError("Comb id 字段必须是整数")
                mid = sub
            elif sfn == 2:
                if swt != 2:
                    raise ValueError("Comb data 字段必须是 bytes")
                data = sub
        if mid is None or not 0 < mid < (1 << 31):
            raise ValueError("Comb 消息缺少有效的 id")
        messages.append((mid, data))
    return messages

def get_comb_ids(raw):
    return tuple(sorted(mid for mid, _ in get_comb_messages(raw)))

def encode_guide_section(sec_i, status, step):
    """GuideSection { 1:section, 2:status, 3:step }"""
    sub = bytearray()
    sub.extend(encode_varint((1 << 3) | 0))
    sub.extend(encode_varint(sec_i))
    sub.extend(encode_varint((2 << 3) | 0))
    sub.extend(encode_varint(status))
    sub.extend(encode_varint((3 << 3) | 0))
    sub.extend(encode_varint(step))
    return bytes(sub)

def build_guide_query_pb(sections):
    """GuideQuery { repeated GuideSection sections = 1; }
    sections: { "<段号>": {"status":1|2, "step":n} }"""
    gq = bytearray()
    for sec in sorted(sections.keys(), key=lambda x: int(x)):
        st = sections[sec]
        sub = encode_guide_section(int(sec), int(st.get("status", 0)), int(st.get("step", 0)))
        gq.extend(encode_varint((1 << 3) | 2))
        gq.extend(encode_varint(len(sub)))
        gq.extend(sub)
    return bytes(gq)

def describe_guide(sections):
    """生成人可读的引导进度描述。"""
    if not sections:
        return "全新号 (未开始引导)"
    parts = []
    for sec in sorted(sections.keys(), key=lambda x: int(x)):
        st = sections[sec]
        total = GUIDE_STEP_COUNTS.get(int(sec), 0)
        tag = "已完成" if st.get("status") == 2 else "进行中"
        hist = st.get("steps") or []
        extra = f" 已记录{len(hist)}步" if hist else ""
        parts.append(f"S{sec} {tag} step {st.get('step')}/{total or '?'}{extra}")
    return ", ".join(parts)

def get_guide_sections(save):
    g = save.get("guide")
    if not isinstance(g, dict):
        return {}
    return normalize_sections(g.get("sections", {}))

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

def parse_guide_excute(body):
    values = {}
    for fn, wt, value in iter_pb_fields(body):
        if fn in (1, 2):
            if wt != 0:
                raise ValueError("引导 section/step 字段必须是整数")
            values[fn] = value
    if any(fn not in values or not 0 < values[fn] < (1 << 31) for fn in (1, 2)):
        raise ValueError("引导上报缺少有效的 section/step")
    return values[1], values[2]

def record_guide_progress(save, body):
    section, step = parse_guide_excute(body)
    sections = get_guide_sections(save)
    total = GUIDE_STEP_COUNTS.get(section, 0)
    rec = sections.get(str(section), {})
    history = set(rec.get("steps") or [])
    history.add(step)
    done = bool(total and step >= total)
    sections[str(section)] = {"status": 2 if done else 1, "step": step, "steps": sorted(history)}
    save["guide"] = {"sections": sections}
    tag = "已完结" if done else "进行中"
    print_flush(f"  [201] Section {section} Step {step}/{total or '?'} [{tag}] 已记录 {len(history)} 步")

# ---- 角色状态持久化 (由录制操作更新；999898 仅兼容旧客户端) ----

# role_pb.Role 的字段号: id=1 gender=2 name=3 vip=4 level=5 exp=6 nextexp=7
#                        coin=8 gold=9 stamina=10 maxstamina=11 energy=12
#                        maxenergy=13 power=14
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

def parse_ids_pb(body):
    """解析 ids_pb.Ids (repeated int32, field 1, varint)"""
    out = []
    pos = 0
    while pos < len(body):
        try:
            tag, pos = parse_varint(body, pos)
        except Exception:
            break
        fn = tag >> 3
        wt = tag & 7
        if wt == 0:
            v, pos = parse_varint(body, pos)
            if fn == 1:
                out.append(v)
        elif wt == 2:
            ln, pos = parse_varint(body, pos)
            pos += ln
        elif wt == 5:
            pos += 4
        elif wt == 1:
            pos += 8
        else:
            break
    return out

def encode_pb_field(field, wire, value):
    tag = encode_varint((field << 3) | wire)
    if wire == 0:
        if not 0 <= value < (1 << 64):
            raise ValueError("Protobuf 整数字段超出 64 位")
        return tag + encode_varint(value)
    if wire == 2:
        return tag + encode_varint(len(value)) + value
    return tag + value

def pb_set_field(body, field, wire, value):
    out = bytearray()
    found = False
    for fn, wt, old in iter_pb_fields(body):
        if fn == field:
            wt, old, found = wire, value, True
        out.extend(encode_pb_field(fn, wt, old))
    if not found:
        out.extend(encode_pb_field(field, wire, value))
    return bytes(out)

def pb_set_varint(body, field, value):
    return pb_set_field(body, field, 0, value)

def pb_get_varint(body, field):
    """读取顶层 varint 字段的值，不存在返回 None。"""
    pos = 0
    while pos < len(body):
        try:
            tag, pos = parse_varint(body, pos)
        except Exception:
            return None
        fn = tag >> 3
        wt = tag & 7
        if wt == 0:
            v, pos = parse_varint(body, pos)
            if fn == field:
                return v
        elif wt == 2:
            ln, pos = parse_varint(body, pos)
            pos += ln
        elif wt == 5:
            pos += 4
        elif wt == 1:
            pos += 8
        else:
            return None
    return None

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

def get_role_state(save):
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
    config = ROLE_EXP_CONFIG[str(level)]
    defaults = {"exp": 0, "nextexp": config["nextexp"], "coin": save.get("silver", 0),
                "gold": save.get("gold", 0), "stamina": config["maxstamina"],
                "maxstamina": config["maxstamina"], "energy": save.get("energy", 20),
                "maxenergy": config["maxenergy"], "power": 0, "g_power": 0, "power_all": 0}
    for name, value in defaults.items():
        state.setdefault(name, value)
    if any(type(value) is not int or value < 0 for name, value in state.items() if name in ROLE_FIELD_MAP):
        raise ValueError("角色数值必须是非负整数")
    return state

def apply_reward(save, body):
    state = get_role_state(save)
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

def prepare_recorded_response(opcode, body, save, request_body):
    if opcode == 999900:
        requests = dict(get_comb_messages(request_body))
        messages = iter(get_comb_messages(body))
        out = bytearray()
        for field, wire, value in iter_pb_fields(body):
            if field == 1 and wire == 2:
                mid, data = next(messages)
                updated = prepare_recorded_response(mid, data, save, requests.get(mid, b""))
                if updated != data:
                    value = pb_set_field(value, 2, 2, updated)
            out.extend(encode_pb_field(field, wire, value))
        return bytes(out)
    if opcode == 1001:
        get_role_state(save)
        body = apply_role_state(bytes.fromhex(save["role_snapshot"]) if save.get("role_snapshot") else body, save)
        save["role_snapshot"] = body.hex()
    elif opcode == 201 and request_body and pb_get_varint(body, 1) == 1:
        record_guide_progress(save, request_body)
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
            get_role_state(save).update(power=ids[1], g_power=ids[3], power_all=ids[5])
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
                    costs = PROTAGONIST_GROW_CONFIG[str(level)]["consume"]
                    for cost in costs.split(";"):
                        if cost:
                            cid, amount = map(int, cost.split(","))
                            if cid in (1000, 1001):
                                reward_field = 1 if cid == 1000 else 2
                                apply_reward(save, encode_pb_field(reward_field, 0, (-amount) & ((1 << 64) - 1)))
                general = next((v for n, w, v in iter_pb_fields(previous) if n == 10 and w == 2), None)
                save["protagonist_snapshot"] = (pb_set_field(value, 10, 2, general) if general else value).hex()
                if general:
                    get_role_state(save)["profile"] = pb_get_varint(general, 1)
    elif opcode == 1306:
        values = {n: v for n, w, v in iter_pb_fields(body)}
        if values.get(1) in (0, 1):
            exp = {n: v for n, w, v in iter_pb_fields(values[3])}
            state = get_role_state(save)
            # shortcut: 仅处理录制教程中递增的经验轨迹，任意重复战斗需实现真实结算。
            if (exp[2], exp[3]) > (state["level"], state["exp"]):
                apply_reward(save, values[4])
                config = ROLE_EXP_CONFIG[str(exp[2])]
                location = parse_ids_pb(request_body)
                state.update(level=exp[2], exp=exp[3], nextexp=config["nextexp"],
                             maxstamina=config["maxstamina"], maxenergy=config["maxenergy"])
                # shortcut: 体力仅按录制操作消耗，按时间恢复需接入服务端时钟。
                state["stamina"] -= COPY_CONFIG[str(location[0])][str(location[1])]["physical"]
                if state["stamina"] < 0:
                    raise ValueError("体力不足")
            for field, wire, value in iter_pb_fields(body):
                if field == 6 and wire == 2:
                    record_protagonist_general(save, value)
    elif opcode in (1109, 1201, 1304):
        apply_reward(save, body)
    elif opcode == 1403:
        for mid, data in get_comb_messages(body):
            if mid == 1:
                apply_reward(save, data)
    return body

def send_recorded_responses(conn, seq, responses, save, request_body):
    before = copy.deepcopy(save)
    packets = []
    for response in responses:
        opcode = response["opcode"]
        body = prepare_recorded_response(opcode, bytes.fromhex(response["hex"]), save,
                                         request_body if response["seq"] != 0 else b"")
        packets.append(pack_frame(opcode, seq if response["seq"] != 0 else 0, body))
    state = save.get("role_state")
    if state:
        for name, key in (("level", "level"), ("coin", "silver"), ("gold", "gold"), ("energy", "energy")):
            save[key] = state[name]
        if save.get("role_snapshot"):
            save["role_snapshot"] = apply_role_state(bytes.fromhex(save["role_snapshot"]), save).hex()
    if save != before and not save_role(save):
        raise OSError("角色状态保存失败，不发送成功响应")
    for packet, response in zip(packets, responses):
        conn.sendall(packet)
        send_seq = seq if response["seq"] != 0 else 0
        print_flush(f"  └── [S->C] Opcode: {response['opcode']:6d}, Seq: {send_seq:3d}, Len: {len(packet) - 16:4d} B")

# ==================== 3. 封包与路由构建 ====================

def pack_frame(opcode, seq, payload_bytes):
    magic = 0x0000ee1c
    length = len(payload_bytes)
    hdr = struct.pack(">IIII", magic, length, opcode, seq)
    return hdr + payload_bytes

def load_recordings():
    with open(RECORD_PATH, "r", encoding="utf-8") as f:
        frames = json.load(f)
    print_flush(f"[*] 成功加载 {len(frames)} 条捕获的历史协议帧数据")
    return frames

def build_routing_tables(frames):
    opcode_routes = {}
    comb_routes = {}
    verified = {}
    replies = {}
    for index, frame in enumerate(frames):
        if not frame["c2s"] and frame["seq"] != 0:
            replies.setdefault((frame["seq"], frame["opcode"]), []).append((index, frame))
    
    i = 0
    while i < len(frames):
        f = frames[i]
        if f["c2s"]:
            op = f["opcode"]
            raw = bytes.fromhex(f["hex"])
            events = []
            j = i + 1
            while j < len(frames) and not frames[j]["c2s"]:
                r = frames[j]
                # shortcut: 目前仅恢复教程所需的非空状态推送，其他异步事件待业务实现后补齐。
                if r["seq"] == 0 and r["opcode"] in (205, 1024, 1027) and r["hex"]:
                    events.append((j, r))
                j += 1

            # 应答可能跨过后续请求才到达，不能只在相邻服务端帧内查找。
            matched = replies.get((f["seq"], op), [])
            if not matched:
                i = j
                continue
            events.extend(matched)
            events.sort(key=lambda item: item[0])
            resps = [r for _, r in events]
            verified[f["seq"]] = (op, raw, resps)

            if op == 999900:
                sig = get_comb_ids(raw)
                key = (sig, raw)
                if key not in comb_routes:
                    comb_routes[key] = []
                comb_routes[key].append(resps)
            else:
                if op not in opcode_routes:
                    opcode_routes[op] = []
                opcode_routes[op].append(resps)
            i = j
        else:
            i += 1
            
    master_comb_packets = []
    for (sig, _), resps_list in comb_routes.items():
        if 1001 in sig and len(sig) >= 20:
            master_comb_packets = resps_list[0]
            break

    print_flush(f"[*] 带请求校验的录制路由就绪: {len(verified)} 个请求")
    return opcode_routes, comb_routes, master_comb_packets, verified

# ==================== 4. 会话与真实交互推进 ====================

def handle_client(conn, addr, opcode_routes, comb_routes, master_comb_packets, resp_by_seq):
    print_flush(f"\n[+] 新客户端连入: {addr}")
    try:
        save = load_save()
    except Exception:
        conn.close()
        return
    has_role = save.get("has_role", False)
    sections = get_guide_sections(save)
    in_progress = [s for s in sections.values() if s.get("status") == 1]

    if sections and not in_progress:
        print_flush(f"[★] 状态: 玩家【{save.get('role_name', '主角')}】引导段均已完结，直接进入主城！")
    elif in_progress:
        print_flush(f"[★] 状态: 玩家【{save.get('role_name', '未命名')}】断点续玩 -> {describe_guide(sections)}")
    else:
        print_flush(f"[★] 状态: 全新玩家连入，正常跑完整新手流程 (剧情动画 -> 起名 -> 选将 -> 第一战)！")

    op_counters = {}
    comb_counters = {}
    recv_buf = bytearray()
    
    try:
        while True:
            data = conn.recv(4096)
            if not data:
                print_flush(f"[-] 客户端断开连接: {addr}")
                break
            recv_buf.extend(data)
            
            while len(recv_buf) >= 16:
                magic, plen, opcode, seq = struct.unpack(">IIII", recv_buf[:16])
                if magic != 0x0000ee1c:
                    idx = recv_buf.find(b"\x00\x00\xee\x1c")
                    if idx != -1:
                        del recv_buf[:idx]
                        continue
                    else:
                        recv_buf.clear()
                        break
                
                total_len = 16 + plen
                if len(recv_buf) < total_len:
                    break
                
                body = bytes(recv_buf[16:total_len])
                del recv_buf[:total_len]
                
                print_flush(f"[C->S] Opcode: {opcode:6d} (0x{opcode:04x}), Seq: {seq:3d}, Payload: {len(body):3d} B")
                
                # ----------------- A. Opcode 200 (引导状态查询) -----------------
                if opcode == 200:
                    sections = get_guide_sections(save)
                    if not sections:
                        # 全新号: 返回空 sections，客户端 next(cache.guide)==nil，
                        # 走 LoginScene:enterToGame() 完整播开场剧情、起名、选将
                        conn.sendall(pack_frame(200, seq, b""))
                        print_flush(f"  └── [S->C] 应答 Opcode 200: 空引导表 (全新号)，开启完整开场流程！")
                        continue
                    # 下发真实结构: repeated GuideSection{section,status,step}
                    # 关键点: 进行中的段必须是 status=1，否则客户端判定"无引导"直接跳主城
                    pb = build_guide_query_pb(sections)
                    conn.sendall(pack_frame(200, seq, pb))
                    print_flush(f"  └── [S->C] 应答 Opcode 200: {describe_guide(sections)} | hex={pb.hex()}")
                    continue
                
                # ----------------- B. Opcode 101 (玩家确定起名) -----------------
                if opcode == 101:
                    new_name = parse_set_name(body)
                    save["role_name"] = new_name
                    if save.get("role_snapshot"):
                        save["role_snapshot"] = apply_role_state(bytes.fromhex(save["role_snapshot"]), save).hex()
                    print_flush(f"[★] 玩家确定角色名: 【{new_name}】")
                    if not save_role(save):
                        raise OSError("名字保存失败")
                    conn.sendall(pack_frame(101, seq, b"\x08\x01"))
                    print_flush(f"  └── [S->C] 应答 Opcode 101: 起名成功")
                    continue
                
                # ----------------- C. Opcode 201 (引导步数推进) -----------------
                if opcode == 201:
                    record_guide_progress(save, body)
                    if not save_role(save):
                        raise OSError("引导进度保存失败")
                    conn.sendall(pack_frame(201, seq, b"\x08\x01"))
                    continue
                
                # ---------- C2. Opcode 999898 (客户端角色状态上报, 本地化扩展协议) ----------
                if opcode == 999898:
                    ids = parse_ids_pb(body)
                    if len(ids) != 5 or str(ids[0]) not in ROLE_EXP_CONFIG or any(not 0 <= value < (1 << 31) for value in ids):
                        raise ValueError("无效的旧客户端角色上报")
                    state = get_role_state(save)
                    # 兼容旧客户端；只拒绝经验倒退，货币和战力必须允许消费/下降。
                    if (ids[0], ids[1]) >= (state["level"], state["exp"]):
                        state.update(zip(("level", "exp", "coin", "gold", "power"), ids[:5]))
                        state["power_all"] = ids[4]
                        save.update(level=state["level"], silver=state["coin"], gold=state["gold"])
                        if save.get("role_snapshot"):
                            save["role_snapshot"] = apply_role_state(bytes.fromhex(save["role_snapshot"]), save).hex()
                        if not save_role(save):
                            raise OSError("角色状态保存失败")
                    conn.sendall(pack_frame(999898, seq, b"\x08\x01"))
                    continue

                # ---------- C3. 普通请求校验后回放；Comb 始终按完整请求参数路由 ----------
                recorded_op, recorded_body, hit = resp_by_seq.get(seq, (None, None, None))
                if opcode != 999900 and hit and recorded_op == opcode and recorded_body == body:
                    op_counters[opcode] = op_counters.get(opcode, 0) + 1
                    send_recorded_responses(conn, seq, hit, save, body)
                    continue

                # ----------------- D. Opcode 999900 (Comb 智能复合路由) -----------------
                if opcode == 999900:
                    messages = get_comb_messages(body)
                    sig = tuple(sorted(mid for mid, _ in messages))
                    print_flush(f"  [*] Comb 签名 IDs: {sig[:8]}{'...' if len(sig)>8 else ''} (共 {len(sig)} 项)")
                    
                    # 全量数据初始化请求 (包含 1001 且模块数 >= 20)
                    if (1001 in sig and len(sig) >= 20) or (1002 in sig and len(sig) >= 20):
                        send_recorded_responses(conn, seq, master_comb_packets, save, body)
                        continue
                    
                    # 3. 相同子消息 IDs 仍可能是不同关卡或操作，必须同时匹配请求参数。
                    key = (sig, body)
                    resps_list = comb_routes.get(key)
                    if resps_list:
                        c_idx = comb_counters.get(key, 0)
                        comb_counters[key] = c_idx + 1
                        chosen_resps = resps_list[c_idx % len(resps_list)]
                        send_recorded_responses(conn, seq, chosen_resps, save, body)
                        continue
                    else:
                        # shortcut: 未录制的组合参数仍返回空包，补齐对应业务处理后替换此兜底。
                        print_flush(f"  [!] 未录制的 Comb 请求参数 (IDs={sig})，返回空组合包")
                        conn.sendall(pack_frame(999900, seq, b""))
                        continue
                
                # ----------------- E. 其他普通 Opcode -----------------
                cnt = op_counters.get(opcode, 0)
                op_counters[opcode] = cnt + 1
                candidates = opcode_routes.get(opcode)
                
                if opcode == 200 and candidates and cnt >= len(candidates):
                    conn.sendall(pack_frame(200, seq, b""))
                    continue
                
                if candidates:
                    # 按请求顺序依次取应答组。注意不能用 (cnt-1)：cnt=0 时 Python
                    # 负数取模会绕到最后一组（导致第一次 1001 就返回录制末尾的 Lv.6）。
                    chosen_resps = candidates[cnt % len(candidates)]
                    send_recorded_responses(conn, seq, chosen_resps, save, body)
                    # 关键兜底: 录制时服务端主动推送帧(如 999 globalparam / 5207 等)常被误当成
                    # 上一个请求的应答, 导致该 opcode 自身的应答缺失。客户端会一直等待这个应答,
                    # Loading_Ultimate 的全屏触摸遮罩因此永不销毁 -> 所有点击被吞 -> 引导卡死。
                    if not any(r["opcode"] == opcode and r["seq"] != 0 for r in chosen_resps):
                        conn.sendall(pack_frame(opcode, seq, b""))
                        print_flush(f"  └── [S->C] 补发自应答 Opcode: {opcode:6d} (0x{opcode:04x}), Seq: {seq:3d}, Len:   0 B (录制缺失, 防遮罩残留)")
                else:
                    print_flush(f"  [!] 未匹配到历史应答 Opcode: {opcode}，返回安全空应答")
                    conn.sendall(pack_frame(opcode, seq, b""))
                    
    except Exception as e:
        print_flush(f"[!] 连接异常: {e}")
    finally:
        conn.close()

# ==================== 5. 主程序与 ADB 初始化 ====================

def setup_adb_reverse():
    try:
        dev_out = subprocess.check_output(["adb", "devices"]).decode("utf-8")
        devs = [l.split()[0] for l in dev_out.strip().splitlines()[1:] if "\tdevice" in l]
        for d in devs:
            subprocess.run(["adb", "-s", d, "reverse", f"tcp:{PORT}", f"tcp:{PORT}"], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            print_flush(f"[+] ADB 端口映射就绪: 设备 {d} 127.0.0.1:{PORT} <-> 电脑 127.0.0.1:{PORT}")
    except Exception as e:
        print_flush(f"[!] ADB 端口映射提示: {e}")

def main():
    if "--reset" in sys.argv:
        if os.path.exists(SAVE_PATH):
            os.remove(SAVE_PATH)
            print_flush("[✓] 已成功清空角色存档 role_save.json，重新启动将进入全新号完整新手流程。")

    if "--reset-guide" in sys.argv:
        if os.path.exists(SAVE_PATH):
            cur = load_save()
            cur["guide"] = {"sections": {}}
            if not save_role(cur):
                raise OSError("重置引导存档失败")
            print_flush("[✓] 已清空引导进度（保留角色信息），下次登录将从开场剧情重播新手引导。")
        else:
            print_flush("[!] 未找到存档，无需重置引导。")
    
    setup_adb_reverse()
    frames = load_recordings()
    opcode_routes, comb_routes, master_comb_packets, resp_by_seq = build_routing_tables(frames)
    print_flush(f"[*] 路由表就绪: {len(opcode_routes)} 个独立 Opcode, {len(comb_routes)} 个 Comb 请求参数组合, {len(master_comb_packets)} 个主城初始化子帧")
    
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(("0.0.0.0", PORT))
    server.listen(5)
    
    cur_save = load_save()
    print_flush(f"\n=======================================================")
    print_flush(f"  《作妖记》本地 Mock 模拟服务端 (全流程引导与持久化版) 已启动")
    print_flush(f"  监听地址: 0.0.0.0:{PORT}")
    print_flush(f"  当前存档: 玩家【{cur_save.get('role_name') or '未创建'}】 (Lv.{cur_save.get('level', 1)}) -> {describe_guide(get_guide_sections(cur_save))}")
    print_flush(f"=======================================================\n")
    
    try:
        while True:
            conn, addr = server.accept()
            t = threading.Thread(target=handle_client, args=(conn, addr, opcode_routes, comb_routes, master_comb_packets, resp_by_seq), daemon=True)
            t.start()
    except KeyboardInterrupt:
        print_flush("\n[*] 服务端已停止")

if __name__ == "__main__":
    main()
