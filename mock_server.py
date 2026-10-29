#!/usr/bin/env python3
"""
作妖记局域网模拟服入口：命令行、账号绑定与 TCP 收发，不依赖 ADB。
游戏请求由 zyj_server.session.Session 处理：
    python3 mock_server.py
    python3 mock_server.py --account 2 --reset        清空账号 2 的存档
    python3 mock_server.py --account 2 --reset-guide  只清账号 2 的引导进度
"""

import argparse
import functools
import os
import socket
import struct
import threading

from zyj_server import accounts, configuration, guide, player, protocol, replay
from zyj_server.admin.http import start_admin

print_flush = functools.partial(print, flush=True)

PORT = 14600
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
RECORD_PATH = os.path.join(BASE_DIR, "recorded_frames.json")
SAVE_PATH = os.path.join(BASE_DIR, "role_save.json")
CONFIG_ZIP = os.path.join(BASE_DIR, "configs_sec5.zip")
MAX_FRAME_SIZE = 1024 * 1024


def handle_client(conn, addr, account_store):
    print_flush(f"\n[+] 新客户端连入: {addr}")
    account = None
    session = None
    recv_buf = bytearray()

    try:
        conn.settimeout(30)
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

                if plen > MAX_FRAME_SIZE:
                    raise ValueError("协议帧超过 1 MiB 上限")
                total_len = 16 + plen
                if len(recv_buf) < total_len:
                    break

                body = bytes(recv_buf[16:total_len])
                del recv_buf[:total_len]
                if opcode == 1000:
                    requested_account = accounts.parse_login_account(body)
                    if account is not None and requested_account != account:
                        raise ValueError("连接已绑定账号，切换账号必须重新连接")
                    if account is None:
                        session = account_store.open_session(requested_account, addr)
                        account = requested_account
                        conn.settimeout(None)
                        print_flush(f"[★] 连接已绑定账号 {account}")
                    conn.sendall(protocol.pack_frame(1000, seq, b"\x08\x00\x10\x00\x18\x00"))
                    continue

                if session is None:
                    raise ValueError("请先发送登录请求，未登录连接不能访问存档")
                for packet in session.handle(opcode, seq, body):
                    conn.sendall(packet)
                    _, length, resp_op, send_seq = struct.unpack(">IIII", packet[:16])
                    print_flush(f"  └── [S->C] Opcode: {resp_op:6d}, Seq: {send_seq:3d}, Len: {length:4d} B")

    except Exception as e:
        print_flush(f"[!] 连接异常: {e}")
    finally:
        try:
            conn.close()
        finally:
            if account is not None:
                account_store.close_session(account)


def main(argv=None):
    parser = argparse.ArgumentParser(description="局域网多账号模拟服，监听 0.0.0.0:14600，不需要 ADB")
    parser.add_argument("--account", type=accounts.parse_account_id, default=1, help="重置目标账号（默认 1），不限制其他账号登录")
    parser.add_argument("--admin-port", type=int, default=14601, help="本机网页后台端口（默认 14601，0 为自动分配）")
    reset = parser.add_mutually_exclusive_group()
    reset.add_argument("--reset", action="store_true", help="清空目标账号存档后启动")
    reset.add_argument("--reset-guide", action="store_true", help="仅清空目标账号引导后启动")
    args = parser.parse_args(argv)
    if not 0 <= args.admin_port <= 65535:
        parser.error("--admin-port 必须为 0~65535")

    configs = configuration.ConfigStore(CONFIG_ZIP)
    step_counts = guide.load_guide_step_counts(CONFIG_ZIP)
    role_config = player.load_role_config(CONFIG_ZIP)
    frames = replay.load_recordings(RECORD_PATH)
    tables = replay.build_routing_tables(frames)
    account_store = accounts.AccountStore(SAVE_PATH, tables, step_counts, role_config)

    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    admin = None
    try:
        server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server.bind(("0.0.0.0", PORT))
        server.listen(5)

        # 先占用监听端口，避免另一个服务端仍在线时重置其存档。
        if (args.reset or args.reset_guide) and account_store.path(args.account).exists():
            action = "reset" if args.reset else "reset-guide"
            result = account_store.maintain(args.account, action, account_store.snapshot(args.account)["revision"])
            print_flush(f"[✓] 账号 {args.account} 已执行 {action}，原存档备份: {result['backup_id']}")
        admin = start_admin(args.admin_port, account_store, configs)

        print_flush(f"\n=======================================================")
        print_flush(f"  《作妖记》局域网多账号模拟服已启动（无需 ADB）")
        print_flush(f"  监听地址: 0.0.0.0:{PORT}")
        print_flush(f"  本机管理后台: http://127.0.0.1:{admin.server_port}")
        print_flush(f"  手机/模拟器直连电脑的局域网 IP:{PORT}；账号 1 沿用 {SAVE_PATH}")
        print_flush(f"  无密码，仅用于可信局域网，禁止直接暴露公网")
        print_flush(f"=======================================================\n")

        while True:
            conn, addr = server.accept()
            # shortcut: 断网旧会话等待 TCP 断开释放；即时跨设备接管需另做会话交接。
            conn.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, 1)
            t = threading.Thread(target=handle_client, args=(conn, addr, account_store), daemon=True)
            t.start()
    except KeyboardInterrupt:
        print_flush("\n[*] 服务端已停止")
    finally:
        server.close()
        if admin is not None:
            admin.shutdown()
            admin.server_close()


if __name__ == "__main__":
    main()
