"""TCP 封包与 Protobuf/Comb 编解码，不依赖配置、存档或网络连接。"""

import struct


def pack_frame(opcode, seq, payload_bytes):
    magic = 0x0000ee1c
    length = len(payload_bytes)
    hdr = struct.pack(">IIII", magic, length, opcode, seq)
    return hdr + payload_bytes


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
