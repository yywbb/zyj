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
4. 唯有当新手引导真正全部完成时，才标记 status = 2。
5. 命令行重置: `python3 mock_server.py --reset` 清空存档从 0 开始。
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

PORT = 14600
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
RECORD_PATH = os.path.join(BASE_DIR, "recorded_frames.json")
SAVE_PATH = os.path.join(BASE_DIR, "role_save.json")

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
        "guide": {
            "section": 1,
            "status": 0,    # 0 = 引导进行中，必须正常跑流程；2 = 全部完成
            "step": 0       # 0 = 从开场漫画第一幕开始
        },
        "created_at": time.time(),
        "last_login": time.time()
    }

def load_save():
    if os.path.exists(SAVE_PATH):
        try:
            with open(SAVE_PATH, "r", encoding="utf-8") as f:
                data = json.load(f)
                return data
        except Exception as e:
            print_flush(f"[!] 读取存档失败 ({e})，使用默认空存档")
    return get_default_save()

def save_role(save_data):
    try:
        save_data["last_login"] = time.time()
        with open(SAVE_PATH, "w", encoding="utf-8") as f:
            json.dump(save_data, f, ensure_ascii=False, indent=2)
        step_str = f"Section {save_data.get('guide', {}).get('section', 1)} Step {save_data.get('guide', {}).get('step', 0)}"
        print_flush(f"[✓] 进度实时落盘: 角色【{save_data.get('role_name', '未起名')}】 (Lv.{save_data.get('level', 1)}, 引导: {step_str})")
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

def build_guide_query_pb(section, status, step):
    sec = bytearray()
    sec.extend(encode_varint((1 << 3) | 0))
    sec.extend(encode_varint(section))
    sec.extend(encode_varint((2 << 3) | 0))
    sec.extend(encode_varint(status))
    sec.extend(encode_varint((3 << 3) | 0))
    sec.extend(encode_varint(step))
    
    gq = bytearray()
    gq.extend(encode_varint((1 << 3) | 2))
    gq.extend(encode_varint(len(sec)))
    gq.extend(sec)
    return bytes(gq)

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

    return opcode_routes, comb_routes, master_comb_packets

# ==================== 4. 会话与真实交互推进 ====================

def handle_client(conn, addr, opcode_routes, comb_routes, master_comb_packets):
    print_flush(f"\n[+] 新客户端连入: {addr}")
    save = load_save()
    has_role = save.get("has_role", False)
    guide_status = save.get("guide", {}).get("status", 0)
    guide_step = save.get("guide", {}).get("step", 0)
    
    if guide_status == 2:
        print_flush(f"[★] 状态: 玩家【{save.get('role_name', '主角')}】新手引导已全部通关，直接进入主城！")
    elif guide_step > 0:
        print_flush(f"[★] 状态: 玩家【{save.get('role_name', '未命名')}】断点恢复 (进行到 Section {save.get('guide', {}).get('section', 1)}, Step {guide_step})")
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
                    # 只有在引导真正完成 (status=2) 或有明确断点进度时，才下发 PB；否则返回空让客户端正常播漫画
                    if guide_status == 2:
                        pb = build_guide_query_pb(1, 2, guide_step if guide_step else 81)
                        conn.sendall(pack_frame(200, seq, pb))
                        print_flush(f"  └── [S->C] 应答 Opcode 200: 引导已完成 (Status 2)")
                        continue
                    elif guide_step > 0:
                        pb = build_guide_query_pb(save.get("guide", {}).get("section", 1), 0, guide_step)
                        conn.sendall(pack_frame(200, seq, pb))
                        print_flush(f"  └── [S->C] 应答 Opcode 200: 断点恢复至 Step {guide_step}")
                        continue
                    else:
                        # 全新号: 返回空，客户端正常调用 LoginScene:enterToGame() 播放剧情与起名
                        conn.sendall(pack_frame(200, seq, b""))
                        print_flush(f"  └── [S->C] 应答 Opcode 200: 新角色初始状态，开启完整开场流程！")
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
                    guide_step = step_v
                    if "guide" not in save:
                        save["guide"] = {}
                    save["guide"]["section"] = sec_v
                    save["guide"]["step"] = step_v
                    
                    # 引导推进到第一章末尾 (例如 Step >= 80) 时才标记 status = 2
                    if step_v >= 80:
                        save["guide"]["status"] = 2
                        guide_status = 2
                    
                    save_role(save)
                    conn.sendall(pack_frame(201, seq, b"\x08\x01"))
                    print_flush(f"  └── [S->C] 应答 Opcode 201: 引导步数推进至 (Section {sec_v}, Step {step_v})")
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
                    chosen_resps = candidates[(cnt - 1) % len(candidates)]
                    for rf in chosen_resps:
                        resp_op = rf["opcode"]
                        resp_body = bytes.fromhex(rf["hex"])
                        send_seq = seq if resp_op == opcode else 0
                        pkt = pack_frame(resp_op, send_seq, resp_body)
                        conn.sendall(pkt)
                        print_flush(f"  └── [S->C] 应答 Opcode: {resp_op:6d} (0x{resp_op:04x}), Seq: {send_seq:3d}, Len: {len(resp_body):3d} B")
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
    
    setup_adb_reverse()
    frames = load_recordings()
    opcode_routes, comb_routes, master_comb_packets = build_routing_tables(frames)
    print_flush(f"[*] 路由表就绪: {len(opcode_routes)} 个独立 Opcode, {len(comb_routes)} 个 Comb 业务复合签名, {len(master_comb_packets)} 个主城初始化子帧")
    
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(("0.0.0.0", PORT))
    server.listen(5)
    
    cur_save = load_save()
    print_flush(f"\n=======================================================")
    print_flush(f"  《作妖记》本地 Mock 模拟服务端 (全流程引导与持久化版) 已启动")
    print_flush(f"  监听地址: 0.0.0.0:{PORT}")
    if cur_save.get("has_role") and cur_save.get("guide", {}).get("status") == 2:
        print_flush(f"  当前存档: 玩家【{cur_save.get('role_name')}】 (Lv.{cur_save.get('level', 1)}) [引导已通关]")
    elif cur_save.get("guide", {}).get("step", 0) > 0:
        print_flush(f"  当前存档: 玩家【{cur_save.get('role_name', '未命名')}】 [进行至 Step {cur_save.get('guide', {}).get('step')}]")
    else:
        print_flush(f"  当前存档: 全新初始状态 (完整走完开场剧情、起名、选将与新手战斗！)")
    print_flush(f"=======================================================\n")
    
    try:
        while True:
            conn, addr = server.accept()
            t = threading.Thread(target=handle_client, args=(conn, addr, opcode_routes, comb_routes, master_comb_packets), daemon=True)
            t.start()
    except KeyboardInterrupt:
        print_flush("\n[*] 服务端已停止")

if __name__ == "__main__":
    main()
