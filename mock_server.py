#!/usr/bin/env python3
"""
作妖记本地模拟服启动入口：命令行、ADB 与 TCP 收发。
游戏请求由 zyj_server.session.Session 处理，启动方式不变：
    python3 mock_server.py
    python3 mock_server.py --reset        清空整个存档
    python3 mock_server.py --reset-guide  只清引导进度，保留角色数据
"""

import functools
import os
import socket
import struct
import subprocess
import sys
import threading

from zyj_server import guide, player, replay
from zyj_server.session import Session

print_flush = functools.partial(print, flush=True)

PORT = 14600
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
RECORD_PATH = os.path.join(BASE_DIR, "recorded_frames.json")
SAVE_PATH = os.path.join(BASE_DIR, "role_save.json")
CONFIG_ZIP = os.path.join(BASE_DIR, "configs_sec5.zip")


def handle_client(conn, addr, tables, save_path, step_counts, role_config):
    print_flush(f"\n[+] 新客户端连入: {addr}")
    try:
        session = Session(tables, save_path, step_counts, role_config)
    except Exception:
        conn.close()
        return
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
                for packet in session.handle(opcode, seq, body):
                    conn.sendall(packet)
                    _, length, resp_op, send_seq = struct.unpack(">IIII", packet[:16])
                    print_flush(f"  └── [S->C] Opcode: {resp_op:6d}, Seq: {send_seq:3d}, Len: {length:4d} B")

    except Exception as e:
        print_flush(f"[!] 连接异常: {e}")
    finally:
        conn.close()


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
    step_counts = guide.load_guide_step_counts(CONFIG_ZIP)
    role_config = player.load_role_config(CONFIG_ZIP)

    if "--reset" in sys.argv:
        if os.path.exists(SAVE_PATH):
            os.remove(SAVE_PATH)
            print_flush("[✓] 已成功清空角色存档 role_save.json，重新启动将进入全新号完整新手流程。")

    if "--reset-guide" in sys.argv:
        if os.path.exists(SAVE_PATH):
            cur = player.load_save(SAVE_PATH, step_counts)
            cur["guide"] = {"sections": {}}
            if not player.save_role(cur, SAVE_PATH, step_counts):
                raise OSError("重置引导存档失败")
            print_flush("[✓] 已清空引导进度（保留角色信息），下次登录将从开场剧情重播新手引导。")
        else:
            print_flush("[!] 未找到存档，无需重置引导。")

    setup_adb_reverse()
    frames = replay.load_recordings(RECORD_PATH)
    tables = replay.build_routing_tables(frames)

    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(("0.0.0.0", PORT))
    server.listen(5)

    cur_save = player.load_save(SAVE_PATH, step_counts)
    print_flush(f"\n=======================================================")
    print_flush(f"  《作妖记》本地 Mock 模拟服务端 (全流程引导与持久化版) 已启动")
    print_flush(f"  监听地址: 0.0.0.0:{PORT}")
    print_flush(f"  当前存档: 玩家【{cur_save.get('role_name') or '未创建'}】 (Lv.{cur_save.get('level', 1)}) -> {guide.describe_guide(guide.get_guide_sections(cur_save, step_counts), step_counts)}")
    print_flush(f"=======================================================\n")

    try:
        while True:
            conn, addr = server.accept()
            t = threading.Thread(target=handle_client, args=(conn, addr, tables, SAVE_PATH, step_counts, role_config), daemon=True)
            t.start()
    except KeyboardInterrupt:
        print_flush("\n[*] 服务端已停止")


if __name__ == "__main__":
    main()
