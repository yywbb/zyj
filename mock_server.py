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

# ==================== 1. 渐进式存档管理 ====================

def get_default_save():
    return {
        "has_role": False,
        "role_name": "",
        "selected_general_id": 0,
        "level": 1,
        "gold": 0,
        "silver": 0,
        "energy": 50,
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
        # redo==0 的步骤客户端不上报 (section 1 里是 78/79/80), 所以轨迹跳号是正常的
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
            print_flush(f"[!] 读取存档失败 ({e})，使用默认空存档")
    return get_default_save()

def save_role(save_data):
    try:
        save_data["last_login"] = time.time()
        with open(SAVE_PATH, "w", encoding="utf-8") as f:
            json.dump(save_data, f, ensure_ascii=False, indent=2)
        print_flush(f"[✓] 进度实时落盘: 角色【{save_data.get('role_name', '未起名')}】 (Lv.{save_data.get('level', 1)}, 引导: {describe_guide(get_guide_sections(save_data))})")
    except Exception as e:
        print_flush(f"[!] 保存存档失败: {e}")

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
    res, shift = 0, 0
    while True:
        b = buf[pos]
        pos += 1
        res |= (b & 0x7f) << shift
        if not (b & 0x80):
            break
        shift += 7
    return res, pos

def get_comb_ids(raw):
    pos = 0
    ids = []
    while pos < len(raw):
        tag, pos = parse_varint(raw, pos)
        fn = tag >> 3
        wt = tag & 7
        if fn == 1 and wt == 2:
            length, pos = parse_varint(raw, pos)
            sub = raw[pos:pos+length]
            pos += length
            spos = 0
            while spos < len(sub):
                stag, spos = parse_varint(sub, spos)
                sfn = stag >> 3
                swt = stag & 7
                if sfn == 1 and swt == 0:
                    mid, spos = parse_varint(sub, spos)
                    ids.append(mid)
                elif swt == 2:
                    dlen, spos = parse_varint(sub, spos)
                    spos += dlen
                elif swt == 0:
                    _, spos = parse_varint(sub, spos)
        else:
            break
    return tuple(sorted(ids))

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
    try:
        pos = 0
        while pos < len(body):
            tag, pos = parse_varint(body, pos)
            fn = tag >> 3
            wt = tag & 7
            if fn == 1 and wt == 2:
                length, pos = parse_varint(body, pos)
                return body[pos:pos+length].decode("utf-8")
            elif wt == 0:
                _, pos = parse_varint(body, pos)
            elif wt == 2:
                length, pos = parse_varint(body, pos)
                pos += length
    except Exception:
        pass
    return None

def parse_guide_excute(body):
    try:
        pos = 0
        section = 1
        step = 1
        while pos < len(body):
            tag, pos = parse_varint(body, pos)
            fn = tag >> 3
            wt = tag & 7
            if fn == 1 and wt == 0:
                section, pos = parse_varint(body, pos)
            elif fn == 2 and wt == 0:
                step, pos = parse_varint(body, pos)
            elif wt == 2:
                length, pos = parse_varint(body, pos)
                pos += length
        return section, step
    except Exception:
        pass
    return 1, 1

# ---- 角色状态持久化相关 (客户端通过 999898 上报, 服务端在 1001 应答里回填) ----

# role_pb.Role 的字段号: id=1 gender=2 name=3 vip=4 level=5 exp=6 nextexp=7
#                        coin=8 gold=9 stamina=10 maxstamina=11 energy=12
#                        maxenergy=13 power=14
ROLE_FIELD_MAP = {
    "level": 5,
    "exp": 6,
    "coin": 8,
    "gold": 9,
    "power": 14,
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

def pb_set_varint(body, field, value):
    """把顶层 varint 字段 field 设为 value；字段不存在则追加。其它字段原样保留。"""
    out = bytearray()
    pos = 0
    found = False
    while pos < len(body):
        start = pos
        try:
            tag, pos = parse_varint(body, pos)
        except Exception:
            out.extend(body[start:])
            break
        fn = tag >> 3
        wt = tag & 7
        if wt == 0:
            _, pos = parse_varint(body, pos)
            if fn == field:
                out.extend(encode_varint((field << 3) | 0))
                out.extend(encode_varint(value))
                found = True
            else:
                out.extend(body[start:pos])
        elif wt == 2:
            ln, pos = parse_varint(body, pos)
            pos += ln
            out.extend(body[start:pos])
        elif wt == 5:
            pos += 4
            out.extend(body[start:pos])
        elif wt == 1:
            pos += 8
            out.extend(body[start:pos])
        else:
            out.extend(body[start:])
            break
    if not found:
        out.extend(encode_varint((field << 3) | 0))
        out.extend(encode_varint(value))
    return bytes(out)

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
    st = save.get("role_state")
    if not st:
        return body
    for k, fn in ROLE_FIELD_MAP.items():
        v = st.get(k)
        if isinstance(v, int) and v > 0:
            body = pb_set_varint(body, fn, v)
    return body

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
    
    i = 0
    while i < len(frames):
        f = frames[i]
        if f["c2s"]:
            op = f["opcode"]
            raw = bytes.fromhex(f["hex"])
            resps = []
            j = i + 1
            while j < len(frames) and not frames[j]["c2s"]:
                resps.append(frames[j])
                j += 1

            # 关键净化：官方通信是严格一问一答（录制里 167 条请求全部满足
            # "首条应答 opcode == 请求 opcode"，且无一问多答）。
            # 录制时夹杂的服务端主动推送（seq=0 的 999/3501/5207/1027/205/1024/111 等）
            # 会被上面的连续帧扫描误并进应答组。若不剔除，客户端会收到不该收的推送，
            # 触发错误的 UIUpdate 并打断流程（典型现象：引导卡在 step 24）。
            resps = [r for r in resps if r["opcode"] == op]

            # 只收录非空应答组：空组会让轮询命中"录制缺失"分支而补发空包，
            # 客户端因此拿不到真实数据（例如 2000 的 1113B 应答）。
            if not resps:
                i = j
                continue

            if op == 999900:
                sig = get_comb_ids(raw)
                if sig not in comb_routes:
                    comb_routes[sig] = []
                comb_routes[sig].append(resps)
            else:
                if op not in opcode_routes:
                    opcode_routes[op] = []
                opcode_routes[op].append(resps)
            i = j
        else:
            i += 1
            
    master_comb_packets = []
    for sig, resps_list in comb_routes.items():
        if 1001 in sig and len(sig) >= 20:
            master_comb_packets = resps_list[0]
            break

    # 按 seq 精确配对（录制帧里每条都带 seq）。
    # 官方通信是严格一问一答：应答 opcode 恒等于请求 opcode，且 seq 与请求一致。
    # 而"请求之后紧跟的连续帧"这种分组会把服务端主动推送（seq=0 的 999/3501/5207/111 等）
    # 误并进应答组，导致客户端收到不该收的数据、流程被打断。
    # 这里以 (seq, opcode) 双重校验为准，只收录 opcode 与请求一致、且 seq 非 0 的应答。
    resp_by_seq = {}
    req_op_by_seq = {}
    for f in frames:
        if f["c2s"]:
            req_op_by_seq[f["seq"]] = f["opcode"]
        else:
            resp_by_seq.setdefault(f["seq"], []).append(f)

    # 双重校验：seq 必须对应一个真实请求，且应答 opcode 必须等于该请求的 opcode
    verified = {}
    for seq, rs in resp_by_seq.items():
        if seq in req_op_by_seq and rs[0]["opcode"] == req_op_by_seq[seq]:
            verified[seq] = rs
    print_flush(f"[*] seq 精确路由就绪: {len(verified)} 个请求可获得逐字节还原的官方应答")
    return opcode_routes, comb_routes, master_comb_packets, verified

# ==================== 4. 会话与真实交互推进 ====================

def handle_client(conn, addr, opcode_routes, comb_routes, master_comb_packets, resp_by_seq):
    print_flush(f"\n[+] 新客户端连入: {addr}")
    save = load_save()
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
                    if new_name:
                        save["role_name"] = new_name
                        print_flush(f"[★] 玩家确定角色名: 【{new_name}】")
                        save_role(save)
                    conn.sendall(pack_frame(101, seq, b"\x08\x01"))
                    print_flush(f"  └── [S->C] 应答 Opcode 101: 起名成功")
                    continue
                
                # ----------------- C. Opcode 201 (引导步数推进) -----------------
                if opcode == 201:
                    sec_v, step_v = parse_guide_excute(body)
                    print_flush(f"  [201] 原始载荷 hex={body.hex()} -> section={sec_v}, step={step_v}")
                    sections = get_guide_sections(save)
                    
                    # 完成判定依据真实配置: 客户端 CompleteSection 会上报该段的最后一步
                    # (Section 1 共 83 步)，达到即标记 status=2，否则一律 status=1
                    total = GUIDE_STEP_COUNTS.get(sec_v, 0)
                    done = bool(total and step_v >= total)
                    # 逐步记录: 保留该段上报过的完整步骤轨迹
                    rec = sections.get(str(sec_v), {})
                    history = set(rec.get("steps") or [])
                    history.add(step_v)
                    sections[str(sec_v)] = {
                        "status": 2 if done else 1,
                        "step": step_v,
                        "steps": sorted(history),
                    }
                    save["guide"] = {"sections": sections}

                    save_role(save)
                    conn.sendall(pack_frame(201, seq, b"\x08\x01"))
                    tag = "已完结" if done else "进行中"
                    print_flush(f"  └── [S->C] 应答 Opcode 201: Section {sec_v} Step {step_v}/{total or '?'} [{tag}] 已记录 {len(history)} 步")
                    continue
                
                # ---------- C2. Opcode 999898 (客户端角色状态上报, 本地化扩展协议) ----------
                if opcode == 999898:
                    ids = parse_ids_pb(body)
                    if len(ids) >= 5:
                        prev = save.get("role_state") or {}
                        # 关键: 重连时 Comb 全量包会先把客户端等级冲回录制值(1)，
                        # 随后客户端上报的就是被污染的值。因此这里一律取历史最大值，
                        # 保证升级进度只增不减。
                        def _mx(key, val):
                            old = prev.get(key)
                            return max(old, val) if isinstance(old, int) else val
                        save["role_state"] = {
                            "level": _mx("level", ids[0]),
                            "exp":   _mx("exp", ids[1]),
                            "coin":  _mx("coin", ids[2]),
                            "gold":  _mx("gold", ids[3]),
                            "power": _mx("power", ids[4]),
                        }
                        save["level"] = save["role_state"]["level"]
                        save["silver"] = save["role_state"]["coin"]
                        save["gold"] = save["role_state"]["gold"]
                        save_role(save)
                        st = save["role_state"]
                        changed = "" if prev.get("level") == st["level"] else f" (等级 {prev.get('level', '?')} -> {st['level']})"
                        print_flush(f"  └── [S->C] 已持久化角色状态: Lv.{st['level']} 银币={st['coin']} 元宝={st['gold']} 战力={st['power']}{changed}")
                    conn.sendall(pack_frame(999898, seq, b"\x08\x01"))
                    continue

                # ---------- C3. seq 精确回放（优先，逐字节还原官方应答） ----------
                # 录制帧自带 seq。当客户端 seq 与录制对齐时，直接按 (seq, opcode) 精确回放，
                # 得到与官方完全一致的应答（包括 2000 那 1113B 的真实数据）。
                hit = resp_by_seq.get(seq)
                if hit and hit[0]["opcode"] == opcode:
                    if opcode == 999900:
                        sig = get_comb_ids(body)
                        print_flush(f"  [*] Comb 签名 IDs: {sig[:8]}{'...' if len(sig) > 8 else ''} (共 {len(sig)} 项)")
                        if 202 in sig:
                            print_flush(f"[★] 玩家已确认选择初始武将！")
                            save["has_role"] = True
                            save_role(save)
                    for rf in hit:
                        resp_op = rf["opcode"]
                        resp_body = bytes.fromhex(rf["hex"])
                        if resp_op == 1001:
                            resp_body = apply_role_state(resp_body, save)
                            save["role_snapshot"] = resp_body.hex()
                            lv = pb_get_varint(resp_body, 5)
                            if lv:
                                save["level"] = lv
                            coin = pb_get_varint(resp_body, 8)
                            gold = pb_get_varint(resp_body, 9)
                            if coin is not None: save["silver"] = coin
                            if gold is not None: save["gold"] = gold
                            save_role(save)
                        conn.sendall(pack_frame(resp_op, seq, resp_body))
                        print_flush(f"  └── [S->C] [seq精确] Opcode: {resp_op:6d}, Seq: {seq:3d}, Len: {len(resp_body):4d} B")
                    # 主城全量包之后补发角色快照（重连时客户端不会主动请求 1001）
                    if opcode == 999900:
                        sig = get_comb_ids(body)
                        if (1001 in sig and len(sig) >= 20) or (1002 in sig and len(sig) >= 20):
                            snap = save.get("role_snapshot")
                            if snap:
                                sbody = bytes.fromhex(snap)
                                conn.sendall(pack_frame(1001, 0, sbody))
                                print_flush(f"  └── [S->C] [重连补发角色] Opcode:  1001, Seq:   0, Len: {len(sbody):4d} B "
                                            f"(Lv.{pb_get_varint(sbody, 5)})")
                    continue

                # ----------------- D. Opcode 999900 (Comb 智能复合路由) -----------------
                if opcode == 999900:
                    sig = get_comb_ids(body)
                    print_flush(f"  [*] Comb 签名 IDs: {sig[:8]}{'...' if len(sig)>8 else ''} (共 {len(sig)} 项)")
                    
                    # 1. 选将请求 (包含 202)
                    if 202 in sig:
                        print_flush(f"[★] 玩家已确认选择初始武将！")
                        save["has_role"] = True
                        save_role(save)
                    
                    # 2. 全量数据初始化请求 (包含 1001 且模块数 >= 20)
                    if (1001 in sig and len(sig) >= 20) or (1002 in sig and len(sig) >= 20):
                        for rf in master_comb_packets:
                            resp_op = rf["opcode"]
                            resp_body = bytes.fromhex(rf["hex"])
                            send_seq = seq if resp_op == 999900 else 0
                            pkt = pack_frame(resp_op, send_seq, resp_body)
                            conn.sendall(pkt)
                            print_flush(f"  └── [S->C] [初始化全量包] Opcode: {resp_op:6d}, Seq: {send_seq:3d}, Len: {len(resp_body):4d} B")

                        # 主城全量包携带的是"录制当时"的角色数据(永远是 Lv.1)，
                        # 而重连后客户端不再主动请求 1001，等级/银币就会回退。
                        # 官方服务器下发的是账号当前真实数据，这里按官方协议
                        # 主动补推一次上次下发过的角色快照(seq=0 表示服务端推送)。
                        snap = save.get("role_snapshot")
                        if snap:
                            sbody = bytes.fromhex(snap)
                            conn.sendall(pack_frame(1001, 0, sbody))
                            print_flush(f"  └── [S->C] [重连补发角色] Opcode:  1001, Seq:   0, Len: {len(sbody):4d} B "
                                        f"(Lv.{pb_get_varint(sbody, 5)} 银币={pb_get_varint(sbody, 8)} 元宝={pb_get_varint(sbody, 9)})")
                        continue
                    
                    # 3. 按签名精确匹配其他业务 (主城模块、副本战斗等)
                    resps_list = comb_routes.get(sig)
                    if resps_list:
                        c_idx = comb_counters.get(sig, 0)
                        comb_counters[sig] = c_idx + 1
                        chosen_resps = resps_list[c_idx % len(resps_list)]
                        
                        for rf in chosen_resps:
                            resp_op = rf["opcode"]
                            resp_body = bytes.fromhex(rf["hex"])
                            send_seq = seq if resp_op == 999900 else 0
                            pkt = pack_frame(resp_op, send_seq, resp_body)
                            conn.sendall(pkt)
                            print_flush(f"  └── [S->C] [Comb 路由] Opcode: {resp_op:6d}, Seq: {send_seq:3d}, Len: {len(resp_body):4d} B")
                        continue
                    else:
                        print_flush(f"  [!] 未匹配到 Comb 签名 {sig}，返回安全空组合包")
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
                    has_own_resp = False
                    for rf in chosen_resps:
                        resp_op = rf["opcode"]
                        resp_body = bytes.fromhex(rf["hex"])
                        # 角色信息应答: 用客户端上报过的真实状态覆盖录制时的旧值
                        if resp_op == 1001:
                            resp_body = apply_role_state(resp_body, save)
                            # 记录本次下发的角色快照，供会话重连后补发
                            save["role_snapshot"] = resp_body.hex()
                            lv = pb_get_varint(resp_body, 5)
                            if lv:
                                save["level"] = lv
                            coin = pb_get_varint(resp_body, 8)
                            gold = pb_get_varint(resp_body, 9)
                            if coin is not None: save["silver"] = coin
                            if gold is not None: save["gold"] = gold
                            save_role(save)
                        send_seq = seq if resp_op == opcode else 0
                        pkt = pack_frame(resp_op, send_seq, resp_body)
                        conn.sendall(pkt)
                        if resp_op == opcode:
                            has_own_resp = True
                        print_flush(f"  └── [S->C] 应答 Opcode: {resp_op:6d} (0x{resp_op:04x}), Seq: {send_seq:3d}, Len: {len(resp_body):3d} B")
                    # 关键兜底: 录制时服务端主动推送帧(如 999 globalparam / 5207 等)常被误当成
                    # 上一个请求的应答, 导致该 opcode 自身的应答缺失。客户端会一直等待这个应答,
                    # Loading_Ultimate 的全屏触摸遮罩因此永不销毁 -> 所有点击被吞 -> 引导卡死。
                    if not has_own_resp:
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
            with open(SAVE_PATH, "w", encoding="utf-8") as f:
                json.dump(cur, f, ensure_ascii=False, indent=2)
            print_flush("[✓] 已清空引导进度（保留角色信息），下次登录将从开场剧情重播新手引导。")
        else:
            print_flush("[!] 未找到存档，无需重置引导。")
    
    setup_adb_reverse()
    frames = load_recordings()
    opcode_routes, comb_routes, master_comb_packets, resp_by_seq = build_routing_tables(frames)
    print_flush(f"[*] 路由表就绪: {len(opcode_routes)} 个独立 Opcode, {len(comb_routes)} 个 Comb 业务复合签名, {len(master_comb_packets)} 个主城初始化子帧")
    
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
