"""独立、仅上传的客户端诊断端口；不接触账号、游戏事务或后台令牌。"""

from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import os
from pathlib import Path
import re
import secrets
import threading
import time

from .storage import atomic_write

MAX_BODY = 65536
MAX_FILES = 1000
MAX_DISK = 32 * 1024 * 1024
PER_PEER_LIMIT = 30
GLOBAL_LIMIT = 120
TRACE_LINES = {
    "lua": r"(?:lua_error=(?:nil_value|argument|arithmetic|assertion|runtime)|at [\w./-]{1,160}:[0-9]{1,9}|in [\w.:]{1,120})",
    "java": r"(?:exception=[\w.$]{1,180}|at [\w.$<>]{1,200}\([\w.$ -]{1,120}(?::[0-9]{1,9})?\))",
    "native": r"(?:native-v1|build=[0-9a-f]{16,64}|abi=(?:arm64-v8a|armeabi-v7a)|signal=[0-9]{1,2}|code=-?[0-9]{1,10}|(?:pc|lr)=0x[0-9a-f]{1,16}|time=[0-9]{1,12}|image=[0-9a-f]{1,16}-[0-9a-f]{1,16} offset=[0-9a-f]{1,16} name=[\w.+-]{1,120}\.so)",
}


def load_key(path):
    path = Path(path)
    try:
        fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    except FileExistsError:
        pass
    else:
        with os.fdopen(fd, "w") as stream:
            stream.write(secrets.token_hex(32) + "\n")
            stream.flush()
            os.fsync(stream.fileno())
    key = path.read_text().strip()
    if not re.fullmatch(r"[0-9a-f]{64}", key):
        raise ValueError("client_reports.key 无效，拒绝自动替换已有上传密钥")
    return key


def validate(report):
    if (not isinstance(report, dict) or set(report) != {"id", "kind", "build", "time", "sdk", "abi", "source", "trace"}
            or report.get("kind") not in TRACE_LINES):
        raise ValueError("invalid report")
    patterns = {"id": r"[0-9a-f]{32}", "build": r"[0-9a-f]{16,64}",
                "abi": r"(?:arm64-v8a|armeabi-v7a)", "source": r"(?:ui|net|process)"}
    if (any(not isinstance(report[k], str) or not re.fullmatch(pattern, report[k], flags=re.ASCII) for k, pattern in patterns.items())
            or type(report["time"]) is not int or not 0 <= report["time"] < (1 << 63)
            or type(report["sdk"]) is not int or not 24 <= report["sdk"] <= 100
            or not isinstance(report["trace"], str) or not 0 < len(report["trace"]) <= 48000):
        raise ValueError("invalid metadata")
    if any(not re.fullmatch(TRACE_LINES[report["kind"]], line, flags=re.ASCII) for line in report["trace"].splitlines()):
        raise ValueError("only diagnostic locations are accepted")
    return report


class ReportServer(HTTPServer):
    # 单个短超时上传不占用游戏线程，也不为未鉴权连接创建无界线程。
    def __init__(self, address, directory, key):
        self.directory = Path(directory)
        self.directory.mkdir(parents=True, exist_ok=True, mode=0o700)
        self.key = key
        self.limits = {}
        super().__init__(address, ReportHandler)

    def allow(self, peer):
        now = time.monotonic()
        self.limits = {k: v for k, v in self.limits.items() if now - v[0] < 60}
        for key, limit in (("*", GLOBAL_LIMIT), (peer, PER_PEER_LIMIT)):
            if self.limits.get(key, (now, 0))[1] >= limit:
                return False
        for key in ("*", peer):
            start, count = self.limits.get(key, (now, 0))
            self.limits[key] = (start, count + 1)
        return True

    def store(self, report):
        target = self.directory / (report["id"] + ".json")
        if target.exists():
            existing = json.loads(target.read_text())
            existing.pop("received_at", None)
            return 200 if existing == report else 409
        encoded = json.dumps(dict(report, received_at=int(time.time())), ensure_ascii=True).encode()
        files = [p for p in self.directory.iterdir() if p.is_file() and not p.name.startswith("._")]
        if len(files) >= MAX_FILES or sum(p.stat().st_size for p in files) + len(encoded) > MAX_DISK:
            return 507
        atomic_write(target, encoded)
        return 200


class ReportHandler(BaseHTTPRequestHandler):
    def setup(self):
        self.request.settimeout(3)
        super().setup()

    def log_message(self, *args):
        pass

    def reply(self, status, report_id=None):
        self.close_connection = True
        body = json.dumps({"id": report_id, "stored": True} if status == 200 else {"stored": False}).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Connection", "close")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        self.reply(404)

    def do_POST(self):
        if self.path != "/v1/reports":
            return self.reply(404)
        key = self.headers.get("X-Client-Log-Key", "")
        if (self.headers.get("Origin") is not None or not re.fullmatch(r"[0-9a-f]{64}", key)
                or not secrets.compare_digest(key, self.server.key)):
            return self.reply(403)
        if (self.headers.get("Transfer-Encoding") is not None or self.headers.get("Content-Type") != "application/json"
                or len(self.headers.get_all("Content-Length", [])) != 1):
            return self.reply(400)
        try:
            length = int(self.headers["Content-Length"])
            if not 0 < length <= MAX_BODY:
                return self.reply(400)
            body = self.rfile.read(length)
            if len(body) != length:
                return self.reply(400)
            report = validate(json.loads(body))
        except (ValueError, TypeError, UnicodeError):
            return self.reply(400)
        if not self.server.allow(self.client_address[0]):
            return self.reply(429)
        try:
            status = self.server.store(report)
        except (OSError, ValueError):
            status = 503
        self.reply(status, report["id"])


def start_reports(port, root, host="0.0.0.0"):
    root = Path(root)
    server = ReportServer((host, port), root / "logs" / "client_reports", load_key(root / "client_reports.key"))
    threading.Thread(target=server.serve_forever, daemon=True, name="client-reports").start()
    return server
