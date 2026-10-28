"""共享录制索引与每连接的匹配计数；不更新玩家状态或发送数据。"""

import functools
import json

from .protocol import get_comb_ids

print_flush = functools.partial(print, flush=True)


def load_recordings(record_path):
    with open(record_path, "r", encoding="utf-8") as f:
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
                # shortcut: 本地单存档登录忽略 UUID，接入真实账号时改为鉴权。
                key = (op, b"" if op == 1000 else raw)
                opcode_routes.setdefault(key, []).append(resps)
            i = j
        else:
            i += 1

    master_comb_packets = []
    for (sig, _), resps_list in comb_routes.items():
        if 1001 in sig and len(sig) >= 20:
            master_comb_packets = resps_list[0]
            break

    print_flush(f"[*] 带请求校验的录制路由就绪: {len(verified)} 个请求")
    print_flush(f"[*] 路由表就绪: {len(opcode_routes)} 个普通请求参数组合, {len(comb_routes)} 个 Comb 请求参数组合, {len(master_comb_packets)} 个主城初始化子帧")
    return opcode_routes, comb_routes, master_comb_packets, verified


class Replay:
    def __init__(self, tables):
        self.opcode_routes, self.comb_routes, self.master_comb_packets, self.resp_by_seq = tables
        self.op_counters = {}
        self.comb_counters = {}

    def match(self, opcode, seq, body):
        """返回录制响应组；None 表示未录制，不把空初始化响应组当成未匹配。"""
        ordinary_key = (opcode, b"" if opcode == 1000 else body)
        recorded_op, recorded_body, hit = self.resp_by_seq.get(seq, (None, None, None))
        if opcode != 999900 and hit and recorded_op == opcode and recorded_body == body:
            self.op_counters[ordinary_key] = self.op_counters.get(ordinary_key, 0) + 1
            return hit

        if opcode == 999900:
            sig = get_comb_ids(body)
            print_flush(f"  [*] Comb 签名 IDs: {sig[:8]}{'...' if len(sig)>8 else ''} (共 {len(sig)} 项)")
            if (1001 in sig and len(sig) >= 20) or (1002 in sig and len(sig) >= 20):
                return self.master_comb_packets
            # 相同子消息 IDs 仍可能是不同关卡或操作，必须同时匹配请求参数。
            key = (sig, body)
            resps_list = self.comb_routes.get(key)
            if resps_list:
                c_idx = self.comb_counters.get(key, 0)
                self.comb_counters[key] = c_idx + 1
                return resps_list[c_idx % len(resps_list)]
            # shortcut: 未录制的组合参数仍返回空包，补齐对应业务处理后替换此兜底。
            print_flush(f"  [!] 未录制的 Comb 请求参数 (IDs={sig})，返回空组合包")
            return None

        candidates = self.opcode_routes.get(ordinary_key)
        if candidates:
            cnt = self.op_counters.get(ordinary_key, 0)
            if opcode == 200 and cnt >= len(candidates):
                return None
            self.op_counters[ordinary_key] = cnt + 1
            # shortcut: 同参数的多份录制仍按连接内次数轮询，接入真实业务后替换。
            return candidates[cnt % len(candidates)]
        print_flush(f"  [!] 未录制的普通请求参数 (Opcode={opcode})，返回空应答")
        return None
