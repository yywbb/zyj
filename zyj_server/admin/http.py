"""仅监听本机的 HTTP 入口；业务读写分别交给账号和配置模块。"""

from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import secrets
import threading
from urllib.parse import parse_qs, urlsplit

from ..accounts import parse_account_id
from . import views

STATIC = Path(__file__).with_name("static")
ASSETS = {"/": ("index.html", "text/html"), "/app.js": ("app.js", "text/javascript"),
          "/style.css": ("style.css", "text/css")}


class AdminServer(ThreadingHTTPServer):
    daemon_threads = True

    def __init__(self, port, accounts, configs):
        self.accounts = accounts
        self.configs = configs
        self.token = secrets.token_urlsafe(32)
        super().__init__(("127.0.0.1", port), AdminHandler)


class AdminHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass

    def _send(self, status, body, content_type="application/json", filename=None):
        if content_type == "application/json":
            body = json.dumps(body, ensure_ascii=False, allow_nan=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", content_type + "; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Content-Security-Policy", "default-src 'self'; style-src 'self'; script-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'self'")
        if filename:
            self.send_header("Content-Disposition", f'attachment; filename="{filename}"')
        self.end_headers()
        self.wfile.write(body)

    def _check_origin(self):
        port = self.server.server_port
        hosts = (f"127.0.0.1:{port}", f"localhost:{port}")
        if self.headers.get("Host") not in hosts:
            raise PermissionError("请通过启动日志中的本机地址访问后台。")
        origin = self.headers.get("Origin")
        if origin is not None and origin not in tuple("http://" + host for host in hosts):
            raise PermissionError("拒绝跨站后台请求")

    def do_GET(self):
        self._dispatch(False)

    def do_POST(self):
        self._dispatch(True)

    def _dispatch(self, writing):
        try:
            self.connection.settimeout(10)
            self._check_origin()
            route = urlsplit(self.path)
            parts = route.path.strip("/").split("/")
            data = {}
            if writing:
                if not secrets.compare_digest(self.headers.get("X-Admin-Token", ""), self.server.token):
                    raise PermissionError("页面已过期，请刷新后再操作。")
                if self.headers.get_content_type() != "application/json" or self.headers.get("Transfer-Encoding"):
                    raise ValueError("请求必须使用 JSON")
                size = int(self.headers.get("Content-Length", "0"))
                if not 0 < size <= 32768:
                    raise ValueError("请求长度无效（最多 32 KiB）")
                data = json.loads(self.rfile.read(size))
                if not isinstance(data, dict):
                    raise ValueError("请求必须为 JSON 对象")
            accounts, configs = self.server.accounts, self.server.configs
            if not writing and route.path in ASSETS:
                filename, mime = ASSETS[route.path]
                return self._send(200, (STATIC / filename).read_bytes(), mime)
            if not writing and route.path == "/api/status":
                return self._send(200, {"token": self.server.token, "config": configs.status()})
            if not writing and route.path == "/api/accounts":
                rows = [views.summary(accounts.snapshot(i), accounts.step_counts, accounts.role_config) for i in accounts.account_ids()]
                return self._send(200, {"accounts": rows})
            if len(parts) in (3, 4) and parts[:2] == ["api", "accounts"]:
                account = parse_account_id(parts[2])
                if writing and len(parts) == 3:
                    return self._send(200, accounts.maintain(account, data.get("action"), data.get("revision"), data.get("backup_id")))
                if not writing and len(parts) == 3:
                    result = views.detail(accounts.snapshot(account), accounts.step_counts, accounts.role_config)
                    result["backups"] = accounts.backups(account)
                    return self._send(200, result)
                if not writing and parts[3:] == ["download"]:
                    raw = accounts.path(account).read_bytes()
                    return self._send(200, raw, "application/octet-stream", f"account-{account}.json")
            if len(parts) == 3 and parts[:2] == ["api", "configs"]:
                if writing:
                    return self._send(200, configs.update(parts[2], data.get("row_id"), data["changes"], data.get("revision")))
                query = parse_qs(route.query)
                return self._send(200, configs.table(parts[2], query.get("q", [""])[0], int(query.get("offset", ["0"])[0])))
            self._send(404, {"error": "页面或操作不存在"})
        except PermissionError as error:
            self._send(403, {"error": str(error)})
        except (ValueError, TypeError, KeyError, UnicodeError) as error:
            self._send(400, {"error": str(error)})
        except FileNotFoundError:
            self._send(404, {"error": "存档或备份不存在"})
        except OSError as error:
            self._send(500, {"error": f"读写失败，操作未完成: {error}"})


def start_admin(port, accounts, configs):
    server = AdminServer(port, accounts, configs)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    return server
