import http.client
from http.server import BaseHTTPRequestHandler, HTTPServer
import json
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import threading
import unittest
from unittest.mock import patch

from zyj_server import client_reports


class ClientReportTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.key = client_reports.load_key(self.root / "client_reports.key")
        self.server = client_reports.ReportServer(("127.0.0.1", 0), self.root / "reports", self.key)
        worker = threading.Thread(target=self.server.serve_forever, daemon=True)
        worker.start()
        self.addCleanup(self.server.server_close)
        self.addCleanup(self.server.shutdown)
        self.report = dict(id="a" * 32, kind="lua", build="b" * 16, time=1800000000,
                           sdk=29, abi="arm64-v8a", source="ui",
                           trace="lua_error=nil_value\nat Layer_main:42\nin checkminigame")

    def post(self, report=None, key=None, **headers):
        connection = http.client.HTTPConnection(*self.server.server_address, timeout=5)
        self.addCleanup(connection.close)
        body = json.dumps(self.report if report is None else report).encode()
        values = {"Content-Type": "application/json", "X-Client-Log-Key": self.key if key is None else key}
        values.update(headers)
        connection.request("POST", "/v1/reports", body, values)
        response = connection.getresponse()
        return response.status, response.read()

    def test_key_is_persistent_private_and_corruption_fails_closed(self):
        path = self.root / "client_reports.key"
        self.assertEqual(client_reports.load_key(path), self.key)
        self.assertEqual(path.stat().st_mode & 0o777, 0o600)
        path.write_text("invalid")
        with self.assertRaises(ValueError):
            client_reports.load_key(path)
        self.assertEqual(path.read_text(), "invalid")

    def test_accepts_durable_reports_and_duplicate_acknowledgement_survives_restart(self):
        status, body = self.post()
        self.assertEqual(status, 200)
        self.assertEqual(json.loads(body), {"id": self.report["id"], "stored": True})
        path = self.root / "reports" / (self.report["id"] + ".json")
        before = path.read_bytes()
        self.server.shutdown()
        self.server.server_close()
        self.server = client_reports.ReportServer(("127.0.0.1", 0), self.root / "reports", self.key)
        threading.Thread(target=self.server.serve_forever, daemon=True).start()
        self.addCleanup(self.server.server_close)
        self.addCleanup(self.server.shutdown)
        self.assertEqual(self.post()[0], 200)
        self.assertEqual(path.read_bytes(), before)
        self.assertEqual(path.stat().st_mode & 0o777, 0o600)
        changed = dict(self.report, trace="lua_error=runtime")
        self.assertEqual(self.post(changed)[0], 409)
        self.assertEqual(path.read_bytes(), before)

    def test_no_admin_access_browser_posts_credentials_or_unbounded_inputs(self):
        for key in ("", "wrong", "x" * 300):
            self.assertEqual(self.post(key=key)[0], 403)
        self.assertEqual(self.post(Origin="http://evil.example")[0], 403)
        self.assertEqual(self.post(**{"Transfer-Encoding": "chunked"})[0], 400)
        mutations = [dict(self.report, id="../../role_save"), dict(self.report, password="secret"),
                     dict(self.report, sdk=True), dict(self.report, trace="password=secret"),
                     dict(self.report, trace="lua_error=runtime\nlocal_password=secret"),
                     dict(self.report, trace="x" * 65536), dict(self.report, trace="at Foo:1\x00"),
                     dict(self.report, build="../bad"), dict(self.report, time=-1),
                     dict(self.report, abi="private device serial"), dict(self.report, trace="at Foo:\ud800")]
        for report in mutations:
            with self.subTest(report=repr(report)[:120]):
                self.assertEqual(self.post(report)[0], 400)
        self.assertEqual(list((self.root / "reports").glob("*.json")), [])
        connection = http.client.HTTPConnection(*self.server.server_address, timeout=5)
        self.addCleanup(connection.close)
        for method, path in (("GET", "/v1/reports"), ("GET", "/api/status"), ("POST", "/api/accounts/1/gm")):
            connection.request(method, path, headers={"X-Client-Log-Key": self.key})
            response = connection.getresponse()
            self.assertEqual(response.status, 404)
            response.read()

    def test_native_and_java_reports_never_contain_memory_or_exception_messages(self):
        native = dict(self.report, id="c" * 32, kind="native", source="process",
                      trace="native-v1\nbuild=" + "b" * 16 + "\nabi=arm64-v8a\nsignal=11\ncode=1\npc=0x123\nlr=0x456\ntime=1800000000\nimage=100-200 offset=0 name=libcocos2dlua.so")
        self.assertEqual(self.post(native)[0], 200)
        java = dict(self.report, id="d" * 32, kind="java", source="process",
                    trace="exception=java.lang.NullPointerException\nat com.zyj.local.Test.run(Test.java:12)")
        self.assertEqual(self.post(java)[0], 200)
        for report in (dict(native, trace=native["trace"] + "\nstack bytes: secret"),
                       dict(java, trace=java["trace"] + "\npassword=secret")):
            self.assertEqual(self.post(report)[0], 400)

    def test_rate_and_disk_limits_reject_without_acknowledging_lost_data(self):
        with patch.object(client_reports, "PER_PEER_LIMIT", 1):
            self.assertEqual(self.post()[0], 200)
            self.assertEqual(self.post(dict(self.report, id="c" * 32))[0], 429)
        self.server.limits.clear()
        with patch.object(client_reports, "MAX_FILES", 1):
            self.assertEqual(self.post()[0], 200)
            self.assertEqual(self.post(dict(self.report, id="c" * 32))[0], 507)
        with patch.object(client_reports, "MAX_DISK", 1):
            self.assertEqual(self.post(dict(self.report, id="d" * 32))[0], 507)
        self.assertEqual(len(list((self.root / "reports").glob("*.json"))), 1)

    def test_start_stop_uses_ephemeral_port_and_no_game_files(self):
        directory = self.root / "independent"
        directory.mkdir()
        server = client_reports.start_reports(0, directory, host="127.0.0.1")
        try:
            self.assertGreater(server.server_port, 0)
            self.assertEqual(set(p.name for p in directory.iterdir()), {"client_reports.key", "logs"})
            connection = http.client.HTTPConnection(*server.server_address, timeout=5)
            connection.request("GET", "/api/status")
            response = connection.getresponse()
            self.assertEqual(response.status, 404)
            response.read()
            connection.close()
        finally:
            server.shutdown()
            server.server_close()

    def test_save_failure_is_not_a_success_and_does_not_leave_a_partial_report(self):
        with patch.object(client_reports.os, "replace", side_effect=OSError("disk failure")):
            self.assertEqual(self.post()[0], 503)
        self.assertEqual(list((self.root / "reports").iterdir()), [])
        self.assertEqual(self.post()[0], 200)


class AndroidReportTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temporary = tempfile.TemporaryDirectory()
        cls.addClassCleanup(cls.temporary.cleanup)
        cls.work = Path(cls.temporary.name)
        cls.source = Path(__file__).parent / "android_reports"
        subprocess.run(["javac", "--release", "8", "-d", str(cls.work), str(cls.source / "ReportQueue.java"),
                        str(cls.source / "tests/ReportQueueTest.java")], check=True, capture_output=True)

    def run_java(self, mode, root, endpoint="http://127.0.0.1:1/v1/reports", key="b" * 64):
        result = subprocess.run(["java", "-ea", "-cp", str(self.work), "com.zyj.local.ReportQueueTest", mode,
                                 str(root), endpoint, key], capture_output=True, text=True, timeout=20)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout.strip()

    def test_actual_java_queue_bounds_atomic_files_and_preserves_pending_data(self):
        with tempfile.TemporaryDirectory() as directory:
            self.assertEqual(self.run_java("basic", directory), "OK")

    def test_actual_java_upload_retries_after_server_failure_and_only_deletes_matching_ack(self):
        class Receiver(BaseHTTPRequestHandler):
            mode = "failure"
            requests = 0
            def log_message(self, *args):
                pass
            def do_POST(self):
                self.rfile.read(int(self.headers["Content-Length"]))
                Receiver.requests += 1
                status = 503 if Receiver.mode == "failure" else 302 if Receiver.mode == "redirect" else 200
                body = json.dumps({"id": "a" * 32 if Receiver.mode == "success" else "c" * 32, "stored": True}).encode()
                self.send_response(status)
                self.send_header("Content-Length", str(len(body)))
                self.send_header("Location", "/redirected")
                self.end_headers()
                self.wfile.write(body)
        server = HTTPServer(("127.0.0.1", 0), Receiver)
        threading.Thread(target=server.serve_forever, daemon=True).start()
        self.addCleanup(server.server_close)
        self.addCleanup(server.shutdown)
        endpoint = "http://127.0.0.1:" + str(server.server_port) + "/v1/reports"
        with tempfile.TemporaryDirectory() as directory:
            for mode in ("failure", "redirect", "wrong-ack", "success"):
                Receiver.mode = mode
                self.assertEqual(self.run_java("network", directory, endpoint), "0" if mode == "success" else "1")
            self.assertEqual(Receiver.requests, 4)

    def test_actual_java_queue_delivers_to_real_python_receiver_without_game_or_admin_session(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            server = client_reports.ReportServer(("127.0.0.1", 0), root / "received", "b" * 64)
            threading.Thread(target=server.serve_forever, daemon=True).start()
            try:
                endpoint = f"http://127.0.0.1:{server.server_port}/v1/reports"
                self.assertEqual(self.run_java("network", root / "queue", endpoint), "0")
                self.assertEqual(json.loads((root / "received" / ("a" * 32 + ".json")).read_text())["kind"], "lua")
            finally:
                server.shutdown(); server.server_close()

    def test_actual_native_signal_handler_persists_then_preserves_crash_exit(self):
        executable = self.work / "native-report-test"
        harness = self.work / "native-harness.c"
        harness.write_text('#define REPORT_TEST\n#define main native_example_main\n'
                           f'#include "{self.source / "native_reports.c"}"\n#undef main\n'
                           '''int main(int argc, char **argv) {
                               if (argc!=2) return 2;
                               signal(SIGTRAP,SIG_IGN);
                               if (!install(argv[1], "bbbbbbbbbbbbbbbb")) return 2;
                               struct sigaction ignored;
                               if (sigaction(SIGTRAP,NULL,&ignored) || ignored.sa_handler!=SIG_IGN) return 4;
                               raise(SIGTRAP);
                               char line[]="100-200 r-xp 0000 00:00 1 /private/secret/libcocos2dlua.so";
                               image(line, sizeof(line)-1);
                               char bad[]="300-400 r-xp 0000 00:00 1 /private/libpassword=secret.so";
                               image(bad, sizeof(bad)-1);
                               return native_example_main(argc,argv);
                           }''')
        subprocess.run(["clang", "-Wall", "-Wextra", "-Werror", "-o", str(executable), str(harness)],
                       check=True, capture_output=True)
        path = self.work / "signal.native"
        code = "import os,resource,sys;resource.setrlimit(resource.RLIMIT_CORE,(0,0));os.execv(sys.argv[1],sys.argv[1:])"
        result = subprocess.run([sys.executable, "-B", "-c", code, str(executable), str(path)], capture_output=True, timeout=10)
        self.assertEqual(result.returncode, -signal.SIGABRT, result.stderr)
        text = path.read_text().strip()
        self.assertIn("\nsignal=6\n", text)
        self.assertEqual(text.count("signal="), 1)
        self.assertIn("\npc=0x", text)
        self.assertIn("image=100-200 offset=0000 name=libcocos2dlua.so", text)
        self.assertNotIn("/private", text)
        self.assertNotIn("secret", text)
        self.assertNotIn("password", text)
        report = dict(id="a" * 32, kind="native", build="b" * 16, time=1800000000, sdk=29,
                      abi="arm64-v8a", source="process", trace=text)
        self.assertEqual(client_reports.validate(report), report)


if __name__ == "__main__":
    unittest.main()
