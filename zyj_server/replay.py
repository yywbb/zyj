"""共享录制索引与每连接的匹配计数；不更新玩家状态或发送数据。"""

import functools
import json

from .protocol import (
    encode_pb_field, get_comb_ids, get_comb_messages, iter_pb_fields,
    pb_get_varint, pb_set_field,
)

print_flush = functools.partial(print, flush=True)


def load_recordings(record_path):
    with open(record_path, "r", encoding="utf-8") as f:
        frames = json.load(f)
    print_flush(f"[*] 成功加载 {len(frames)} 条捕获的历史协议帧数据")
    return frames


def split_recordings(frames):
    recordings = []
    current = []
    previous_seq = None
    for frame in frames:
        if frame["c2s"]:
            # shortcut: 旧录制没有连接标签，按请求序号回退分段；独立采集序号不回退时需补标签。
            if previous_seq is not None and frame["seq"] <= previous_seq:
                recordings.append(current)
                current = []
            previous_seq = frame["seq"]
        current.append(frame)
    if current:
        recordings.append(current)
    return recordings


def normalize_comb_request(raw):
    """规范 Comb、GuideExcute、GeneralChangePos 字段顺序；保留所有字段及同字段的重复顺序。"""
    messages = iter(get_comb_messages(raw))
    fields = []
    for field, wire, value in iter_pb_fields(raw):
        if field == 1 and wire == 2:
            mid, _ = next(messages)
            subfields = []
            for number, kind, sub in iter_pb_fields(value):
                if mid in (201, 1003) and number == 2 and kind == 2:
                    sub = b"".join(encode_pb_field(*f) for f in sorted(iter_pb_fields(sub), key=lambda f: f[0]))
                subfields.append((number, kind, sub))
            value = b"".join(encode_pb_field(*f) for f in sorted(subfields, key=lambda f: f[0]))
        fields.append((field, wire, value))
    return b"".join(encode_pb_field(*f) for f in sorted(fields, key=lambda f: f[0]))


def build_routing_tables(frames):
    opcode_routes = {}
    comb_routes = {}
    verified = {}
    for recording in split_recordings(frames):
        replies = {}
        for index, frame in enumerate(recording):
            if not frame["c2s"] and frame["seq"] != 0:
                replies.setdefault((frame["seq"], frame["opcode"]), []).append((index, frame))

        for i, f in enumerate(recording):
            if not f["c2s"]:
                continue
            op = f["opcode"]
            raw = bytes.fromhex(f["hex"])
            events = []
            j = i + 1
            while j < len(recording) and not recording[j]["c2s"]:
                r = recording[j]
                # shortcut: 目前仅恢复教程所需的非空状态推送，其他异步事件待业务实现后补齐。
                if r["seq"] == 0 and r["opcode"] in (205, 1024, 1027) and r["hex"]:
                    events.append((j, r))
                j += 1

            # 应答可能跨过后续请求才到达，但不能跨录制段查找。
            matched = replies.get((f["seq"], op), [])
            if not matched:
                continue
            events.extend(matched)
            events.sort(key=lambda item: item[0])
            resps = [r for _, r in events]
            if op == 999900:
                raw = normalize_comb_request(raw)
            verified.setdefault((f["seq"], op, raw), []).append(resps)

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

    master_comb_packets = []
    initializations = []
    baseline = {}
    for (sig, _), resps_list in comb_routes.items():
        if len(sig) < 20 or not (1001 in sig or 1002 in sig):
            continue
        initializations.extend(resps_list)
        for resps in resps_list:
            for response in resps:
                if response["opcode"] == 999900 and not master_comb_packets:
                    messages = dict(get_comb_messages(bytes.fromhex(response["hex"])))
                    if pb_get_varint(messages.get(1001, b""), 5) == 1:
                        master_comb_packets, baseline = resps, messages

    if initializations and not master_comb_packets:
        raise ValueError("缺少已录制的一级新号初始化基础，拒绝使用完成账号快照")
    for resps in initializations:
        for index, response in enumerate(resps):
            if response["opcode"] != 999900:
                continue
            raw = bytes.fromhex(response["hex"])
            messages = iter(get_comb_messages(raw))
            out = bytearray()
            for field, wire, value in iter_pb_fields(raw):
                if field == 1 and wire == 2:
                    mid, data = next(messages)
                    if mid not in baseline and data:
                        raise ValueError(f"初始化扩展 {mid} 非空，需实现本地状态后再接入")
                    # 公共模块取新号基础，再由 player 回填存档；只补录制中的空扩展。
                    value = pb_set_field(value, 2, 2, baseline.get(mid, b""))
                out.extend(encode_pb_field(field, wire, value))
            resps[index] = dict(response, hex=out.hex())

    print_flush(f"[*] 带请求校验的录制路由就绪: {sum(len(groups) for groups in verified.values())} 个请求")
    print_flush(f"[*] 路由表就绪: {len(opcode_routes)} 个普通请求参数组合, {len(comb_routes)} 个 Comb 请求参数组合, {len(master_comb_packets)} 个主城初始化子帧")
    return opcode_routes, comb_routes, master_comb_packets, verified


class Replay:
    def __init__(self, tables):
        self.opcode_routes, self.comb_routes, self.master_comb_packets, self.resp_by_request = tables
        self.op_counters = {}
        self.comb_counters = {}

    def match(self, opcode, seq, body):
        """返回录制响应组；None 表示未录制，不把空初始化响应组当成未匹配。"""
        if opcode == 999900:
            body = normalize_comb_request(body)
        ordinary_key = (opcode, b"" if opcode == 1000 else body)
        hits = self.resp_by_request.get((seq, opcode, body), [])
        if opcode != 999900 and len(hits) == 1:
            self.op_counters[ordinary_key] = self.op_counters.get(ordinary_key, 0) + 1
            return hits[0]

        if opcode == 999900:
            sig = get_comb_ids(body)
            print_flush(f"  [*] Comb 签名 IDs: {sig[:8]}{'...' if len(sig)>8 else ''} (共 {len(sig)} 项)")
            # 相同子消息 IDs 仍可能是不同关卡或操作，必须同时匹配请求参数。
            key = (sig, body)
            resps_list = self.comb_routes.get(key)
            if resps_list:
                c_idx = self.comb_counters.get(key, 0)
                self.comb_counters[key] = c_idx + 1
                return resps_list[c_idx % len(resps_list)]
            print_flush(f"  [!] 未录制的 Comb 请求参数 (IDs={sig})")
            return None

        candidates = self.opcode_routes.get(ordinary_key)
        if candidates:
            cnt = self.op_counters.get(ordinary_key, 0)
            if opcode == 200 and cnt >= len(candidates):
                return None
            self.op_counters[ordinary_key] = cnt + 1
            # shortcut: 同参数的多份录制仍按连接内次数轮询，接入真实业务后替换。
            return candidates[cnt % len(candidates)]
        print_flush(f"  [!] 未录制的普通请求参数 (Opcode={opcode})")
        return None
