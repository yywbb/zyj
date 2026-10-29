"""独立 JSON 行诊断日志；只观察回包/异常，不参与游戏事务。"""

from datetime import datetime, timezone
import json
import logging
from logging.handlers import RotatingFileHandler
from pathlib import Path
import struct
import sys
import traceback

from .protocol import get_comb_messages, iter_pb_fields


PAYLOAD_LIMIT = 4096


def describe_payload(opcode, body):
    result = {"opcode": opcode, "length": len(body)}
    if opcode in (1000, 20000):
        result["redacted"] = True
    elif opcode == 999900:
        # 不保存外层原文，避免把已脱敏的登录子包再次写入日志。
        try:
            if len(body) > PAYLOAD_LIMIT:
                result["truncated"] = True
                return result
            messages = get_comb_messages(body)
            for n, w, raw in iter_pb_fields(body):
                if (n, w) == (1, 2) and any(
                        f == 1 and t == 0 and value in (1000, 999900)
                        for f, t, value in iter_pb_fields(raw)):
                    result["redacted"] = True
                    return result
            result["messages"] = [describe_payload(mid, data) for mid, data in messages]
        except ValueError as error:
            result.update(redacted=True, parse_error=str(error))
    else:
        result["hex"] = body[:PAYLOAD_LIMIT].hex()
        if len(body) > PAYLOAD_LIMIT:
            result["truncated"] = True
        else:
            try:
                fields = list(iter_pb_fields(body))
                if all((n, w) == (1, 0) for n, w, _ in fields):
                    result["ids"] = [v for _, _, v in fields]
            except ValueError as error:
                result["parse_error"] = str(error)
    return result


class DiagnosticLog(RotatingFileHandler):
    def __init__(self, path):
        Path(path).parent.mkdir(parents=True, exist_ok=True)
        super().__init__(path, maxBytes=5 * 1024 * 1024, backupCount=3, encoding="utf-8")
        self.warned = False

    def emit(self, record):
        # 服务关闭后仍在退出的连接线程不能重新打开日志文件。
        if not self._closed:
            super().emit(record)

    def handleError(self, record):
        if not self.warned:
            self.warned = True
            print("[!] 诊断日志写入失败，游戏请求继续处理；请检查日志目录和磁盘。", file=sys.stderr, flush=True)

    def record(self, account, peer, opcode, seq, body, packets=(), *, error=None, phase="response"):
        try:
            self._record(account, peer, opcode, seq, body, packets, error, phase)
        except Exception:
            # 诊断解析或磁盘失败不能把已保存的成功操作变成断线。
            self.handleError(None)

    def _record(self, account, peer, opcode, seq, body, packets, error, phase):
        responses, empty, errors, malformed = [], [], [], []
        for packet in packets:
            _, length, resp_op, resp_seq = struct.unpack(">IIII", packet[:16])
            payload = packet[16:]
            messages = [(resp_op, payload)]
            if resp_op == 999900:
                try:
                    messages += get_comb_messages(payload)
                except ValueError as parse_error:
                    malformed.append(str(parse_error))
            for index, (mid, data) in enumerate(messages):
                item = {"opcode": mid, "seq": resp_seq, "length": len(data)}
                if index:
                    item["parent_opcode"] = resp_op
                if not data and mid != 999904:
                    empty.append(dict(item))
                if mid in (999999, 1999):
                    item.update(describe_payload(mid, data))
                    if mid == 999999:
                        errors.append(dict(item))
                    else:
                        try:
                            item["message"] = next((v.decode("utf-8", errors="replace")
                                                    for n, w, v in iter_pb_fields(data) if (n, w) == (1, 2)), "")
                        except ValueError as parse_error:
                            malformed.append(str(parse_error))
                responses.append(item)
            if length != len(payload):
                malformed.append("响应帧长度不匹配")

        if error is not None:
            event, level = "exception", logging.ERROR
        elif malformed:
            event, level = "invalid_response", logging.ERROR
        elif errors:
            event, level = "error_response", logging.WARNING
        elif not packets:
            event, level = "no_response", logging.WARNING
        elif empty:
            event, level = "empty_response", logging.INFO
        else:
            return
        request = describe_payload(opcode, body) if account is not None else {
            "opcode": opcode, "length": len(body), "redacted": True}
        request["seq"] = seq
        entry = {"time": datetime.now(timezone.utc).isoformat(timespec="milliseconds"),
                 "level": logging.getLevelName(level), "event": event, "phase": phase,
                 "account": account, "peer": list(peer), "request": request,
                 "responses": responses, "empty": empty}
        if malformed:
            entry["parse_errors"] = malformed
        if error is not None:
            entry.update(error_type=type(error).__name__, reason=str(error),
                         traceback="".join(traceback.format_exception(type(error), error, error.__traceback__))[-8192:])
        else:
            entry["reason"] = " | ".join(item["message"] for item in responses if item.get("message"))
        self.handle(logging.LogRecord("zyj.diagnostics", level, __file__, 0,
                                      json.dumps(entry, ensure_ascii=False), (), None))
