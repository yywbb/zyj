from contextlib import redirect_stdout
import copy
import http.client
import io
import json
from pathlib import Path
import shutil
import tempfile
import threading
import unittest
from unittest.mock import patch

from zyj_server import accounts, configuration, guide, player, replay, storage
from zyj_server.admin import views
from zyj_server.admin.http import start_admin
from zyj_server.session import Session

ROOT = Path(__file__).parent


def setUpModule():
    global TABLES, COUNTS, CONFIG, SAVE
    with redirect_stdout(io.StringIO()), tempfile.TemporaryDirectory() as directory:
        COUNTS = guide.load_guide_step_counts(ROOT / "configs_sec5.zip")
        CONFIG = player.load_role_config(ROOT / "configs_sec5.zip")
        frames = replay.load_recordings(ROOT / "recorded_frames.json")
        TABLES = replay.build_routing_tables(frames)
        session = Session(TABLES, Path(directory) / "role_save.json", COUNTS, CONFIG)
        for frame in replay.split_recordings(frames)[0]:
            if frame["c2s"] and frame["opcode"] != 1000:
                session.handle(frame["opcode"], frame["seq"], bytes.fromhex(frame["hex"]))
        SAVE = session.save


class AdminFixture(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        self.store = accounts.AccountStore(self.root / "role_save.json", TABLES, COUNTS, CONFIG)
        self.config_path = self.root / "configs_sec5.zip"
        shutil.copyfile(ROOT / "configs_sec5.zip", self.config_path)
        self.configs = configuration.ConfigStore(self.config_path)
        quiet = redirect_stdout(io.StringIO())
        quiet.__enter__()
        self.addCleanup(quiet.__exit__, None, None, None)

    def save(self, account=1):
        data = copy.deepcopy(SAVE)
        data["role_name"] = f"测试账号{account}"
        self.assertTrue(player.save_role(data, self.store.path(account), COUNTS))
        return self.store.path(account).read_bytes()

    def maintain(self, action, account=1, backup_id=None):
        return self.store.maintain(account, action, self.store.snapshot(account)["revision"], backup_id)


class AccountMaintenanceTests(AdminFixture):
    def test_live_sessions_block_all_maintenance_without_blocking_other_accounts(self):
        before = self.save()
        self.save(2)
        self.store.open_session(1, ("phone", 1234))
        self.addCleanup(self.store.close_session, 1)
        for action in ("backup", "reset", "reset-guide", "restore"):
            with self.subTest(action=action), self.assertRaisesRegex(ValueError, "在线"):
                self.maintain(action)
        with self.assertRaisesRegex(ValueError, "在线"):
            self.store.open_session(1, ("emulator", 1235))
        snapshot = self.store.snapshot(1)
        self.assertTrue(snapshot["online"])
        self.assertEqual(snapshot["connection"]["address"], "phone")
        self.assertIsNotNone(self.maintain("backup", 2)["backup_id"])
        self.assertEqual(self.store.path(1).read_bytes(), before)

    def test_login_waits_until_reset_and_its_backup_are_complete(self):
        self.save()
        entered, release, connected = threading.Event(), threading.Event(), threading.Event()
        errors, sessions = [], []
        real_backup = storage.backup

        def blocked_backup(*args):
            entered.set()
            if not release.wait(5):
                raise TimeoutError("maintenance was not released")
            return real_backup(*args)

        def reset():
            try:
                self.maintain("reset")
            except Exception as error:
                errors.append(error)

        def login():
            try:
                sessions.append(self.store.open_session(1, ("phone", 0)))
                connected.set()
            except Exception as error:
                errors.append(error)

        with patch.object(storage, "backup", side_effect=blocked_backup):
            worker = threading.Thread(target=reset)
            client = threading.Thread(target=login)
            worker.start()
            try:
                self.assertTrue(entered.wait(3))
                client.start()
                self.assertFalse(connected.wait(.05))
            finally:
                release.set()
                worker.join(5)
                if client.ident is not None:
                    client.join(5)
                self.store.close_session(1)
        self.assertFalse(worker.is_alive() or client.is_alive())
        self.assertEqual(errors, [])
        self.assertTrue(connected.is_set())
        self.assertFalse(sessions[0].save["has_role"])

    def test_reset_restore_and_guide_reset_preserve_other_accounts_and_backups(self):
        first, second = self.save(), self.save(2)
        result = self.maintain("reset", 2)
        backup_id = result["backup_id"]
        self.assertEqual((self.root / "backups/accounts/2" / (backup_id + ".json")).read_bytes(), second)
        self.assertFalse(self.store.path(2).exists())
        self.assertIn(2, self.store.account_ids())
        self.maintain("restore", 2, backup_id)
        restored = self.store.snapshot(2)["save"]
        for key in ("world_state", "role_state", "guide", "activity_state", "stamina_clock"):
            self.assertEqual(restored[key], json.loads(second)[key])
        self.maintain("reset-guide", 2)
        current = self.store.snapshot(2)["save"]
        self.assertEqual(current["guide"], {"sections": {}})
        for key in ("world_state", "role_state", "activity_state", "has_role"):
            self.assertEqual(current[key], restored[key])
        self.assertEqual(self.store.path(1).read_bytes(), first)

    def test_stale_revision_bad_backup_and_failed_writes_leave_original_intact(self):
        before = self.save()
        with self.assertRaisesRegex(ValueError, "变化"):
            self.store.maintain(1, "reset", "stale")
        for backup_id in ("../role_save", "0" * 32):
            with self.subTest(backup_id=backup_id), self.assertRaises(ValueError):
                self.maintain("restore", backup_id=backup_id)
        with patch.object(storage, "backup", side_effect=OSError("disk full")), self.assertRaises(OSError):
            self.maintain("reset")
        self.assertEqual(self.store.path(1).read_bytes(), before)
        original_replace = storage.os.replace

        def fail_save(source, target):
            if Path(target) == self.store.path(1):
                raise OSError("save disk full")
            return original_replace(source, target)

        with patch.object(storage.os, "replace", side_effect=fail_save), self.assertRaises(OSError):
            self.maintain("reset-guide")
        self.assertEqual(self.store.path(1).read_bytes(), before)
        self.assertEqual(len(self.store.backups(1)), 1)
        self.assertEqual(sorted(p.name for p in self.root.iterdir()), ["backups", "configs_sec5.zip", "role_save.json"])

    def test_invalid_restores_are_validated_before_replacing_or_backing_up(self):
        before = self.save()
        invalid = json.loads(before)
        invalid["world_state"]["1200"] = "broken"
        backup_id = storage.backup(self.root / "backups/accounts/1", json.dumps(invalid).encode())
        with self.assertRaises(ValueError):
            self.maintain("restore", backup_id=backup_id)
        self.assertEqual(self.store.path(1).read_bytes(), before)
        self.assertEqual(len(self.store.backups(1)), 1)

    def test_dashboard_reads_zero_balances_roster_and_copy_progress_without_settlement(self):
        self.save()
        data = self.store.snapshot(1)["save"]
        data["role_state"]["gold"] = 0
        self.assertTrue(player.save_role(data, self.store.path(1), COUNTS))
        before = self.store.path(1).read_bytes()
        snapshot = self.store.snapshot(1)
        result = views.detail(snapshot, COUNTS, CONFIG)
        self.assertIsNone(result["error"])
        self.assertEqual(result["gold"], 0)
        self.assertTrue(result["generals"] and result["equipment"] and result["inventory"])
        self.assertEqual(len({r["iid"] for r in result["generals"]}), len(result["generals"]))
        self.assertTrue(any(r["position"] == 1 for r in result["generals"]))
        self.assertGreaterEqual(next(r for r in result["copies"] if r["id"] == 42101)["stars"], 15)
        self.assertEqual(self.store.path(1).read_bytes(), before)
        self.assertEqual(snapshot["save"], json.loads(before))

    def test_corrupt_save_is_visible_and_can_be_backed_up_before_restore(self):
        self.store.path(1).write_bytes(b"{")
        snapshot = self.store.snapshot(1)
        self.assertIsNotNone(views.detail(snapshot, COUNTS, CONFIG)["error"])
        backup_id = self.maintain("backup")["backup_id"]
        self.assertEqual((self.root / "backups/accounts/1" / (backup_id + ".json")).read_bytes(), b"{")
        with self.assertRaises(ValueError):
            self.store.open_session(1, ("phone", 0))
        self.assertEqual(self.store.active, {})


class ConfigurationTests(AdminFixture):
    def update(self, table, row, changes):
        return self.configs.update(table, row, changes, self.configs.status()["revision"])

    def test_saved_overrides_require_restart_and_feed_server_loading(self):
        initial = self.configs.status()["revision"]
        changed = self.update("props", "20014", {"param1": "37", "desc": "恢复37点体力"})
        self.assertTrue(changed["restart_required"])
        self.assertEqual(CONFIG["props"]["20014"]["param1"], "25")
        self.assertEqual(player.load_role_config(self.config_path)["props"]["20014"]["param1"], "37")
        with self.assertRaisesRegex(ValueError, "修改"):
            self.configs.update("props", "20014", {"param1": "20"}, initial)
        restarted = configuration.ConfigStore(self.config_path)
        self.assertFalse(restarted.status()["restart_required"])
        self.update("props", "20014", None)
        self.assertEqual(player.load_role_config(self.config_path)["props"]["20014"]["param1"], "25")
        self.assertFalse(self.configs.status()["restart_required"])
        self.assertTrue(restarted.status()["restart_required"])

    def test_invalid_fields_rewards_and_types_never_write_overrides(self):
        cases = [("general", "10101", {"name": "no"}), ("props", "20017", {"desc": "no"}),
                 ("props", "20014", {"param2": "gold"}), ("props", "20014", {"param1": 50}),
                 ("props", "20014", {"param1": "100001"}), ("liveness", "16", {"num": True}),
                 ("liveness", "16", {"reward": "9999999999,1;"}), ("liveness", "16", {"reward": "1000,0;"}),
                 ("liveness", "16", {"reward": "1000,1;1000,2;"}), ("liveness", "16", {"reward": "22204,101;"})]
        for table, row, changes in cases:
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.update(table, row, changes)
        self.assertFalse(configuration.overrides_path(self.config_path).exists())
        self.assertFalse((self.root / "backups").exists())

    def test_reward_edits_browse_search_and_pagination(self):
        self.update("begin7day_task", "80001", {"rewards": "1000,3;1001,2;20014,1;22204,1;"})
        self.update("liveness", "16", {"num": 8})
        loaded = player.load_role_config(self.config_path)
        self.assertEqual(loaded["liveness"]["16"]["num"], 8)
        self.assertEqual(loaded["begin7day_task"]["80001"]["rewards"], "1000,3;1001,2;20014,1;22204,1;")
        result = self.configs.table("props", "体力丹")
        self.assertTrue({"20014", "20019"} <= {r["id"] for r in result["rows"]})
        self.assertEqual(self.configs.table("props", "20014")["rows"][0]["id"], "20014")
        page1, page2 = self.configs.table("general"), self.configs.table("general", offset=50)
        self.assertEqual(len(page1["rows"]), 50)
        self.assertFalse({r["id"] for r in page1["rows"]} & {r["id"] for r in page2["rows"]})
        self.assertIsNone(page1["editor"])

    def test_failed_override_write_keeps_previous_config_and_backup(self):
        self.update("props", "20014", {"param1": "37"})
        path = configuration.overrides_path(self.config_path)
        before = path.read_bytes()
        real_write = storage.atomic_write

        def fail_override(target, data):
            if Path(target) == path:
                raise OSError("disk full")
            return real_write(target, data)

        with patch.object(storage, "atomic_write", side_effect=fail_override), self.assertRaises(OSError):
            self.update("props", "20014", {"param1": "38"})
        self.assertEqual(path.read_bytes(), before)
        backups = [json.loads(p.read_bytes()) for p in (self.root / "backups/configs").glob("*.json")]
        self.assertIn(json.loads(before), backups)


class AdminHttpTests(AdminFixture):
    def setUp(self):
        super().setUp()
        self.save()
        self.http = start_admin(0, self.store, self.configs)
        self.addCleanup(self.http.server_close)
        self.addCleanup(self.http.shutdown)

    def request(self, path, data=None, headers=None, method=None):
        connection = http.client.HTTPConnection("127.0.0.1", self.http.server_port, timeout=3)
        try:
            body = json.dumps(data) if data is not None else None
            defaults = {"Content-Type": "application/json", "X-Admin-Token": self.http.token}
            connection.request(method or ("POST" if data is not None else "GET"), path, body, {**defaults, **(headers or {})})
            response = connection.getresponse()
            raw = response.read()
            content = json.loads(raw) if response.getheader("Content-Type").startswith("application/json") else raw
            return response.status, dict(response.getheaders()), content
        finally:
            connection.close()

    def test_local_assets_status_and_download_are_available_without_mutating_save(self):
        before = self.store.path(1).read_bytes()
        self.assertEqual(self.http.server_address[0], "127.0.0.1")
        for path in ("/", "/app.js", "/style.css", "/api/status", "/api/accounts", "/api/accounts/1"):
            code, headers, data = self.request(path)
            self.assertEqual(code, 200, data)
            self.assertEqual(headers["Cache-Control"], "no-store")
            self.assertIn("frame-ancestors 'none'", headers["Content-Security-Policy"])
        code, headers, data = self.request("/api/accounts/1/download")
        self.assertEqual((code, data), (200, before))
        self.assertIn("account-1.json", headers["Content-Disposition"])
        self.assertEqual(self.store.path(1).read_bytes(), before)

    def test_bad_host_origin_token_and_request_shape_cannot_write(self):
        before = self.store.path(1).read_bytes()
        payload = {"action": "reset", "revision": self.store.snapshot(1)["revision"]}
        for headers, expected in [({"Host": "evil.example"}, 403), ({"Origin": "https://evil.example"}, 403),
                                  ({"X-Admin-Token": "old-token"}, 403), ({"Content-Type": "text/plain"}, 400),
                                  ({"Content-Length": "40000"}, 400)]:
            with self.subTest(headers=headers):
                self.assertEqual(self.request("/api/accounts/1", payload, headers)[0], expected)
        self.assertEqual(self.request("/api/accounts/1", [payload])[0], 400)
        self.assertEqual(self.request("/api/accounts/1001")[0], 400)
        self.assertEqual(self.request("/../role_save.json")[0], 404)
        self.assertEqual(self.request("/api/accounts", headers={"Host": "evil.example"})[0], 403)
        self.assertEqual(self.store.path(1).read_bytes(), before)

    def test_http_maintenance_and_config_edits_use_shared_live_objects(self):
        self.store.open_session(1, ("phone", 0))
        payload = {"action": "reset", "revision": self.store.snapshot(1)["revision"]}
        self.assertEqual(self.request("/api/accounts/1", payload)[0], 400)
        self.assertTrue(self.request("/api/accounts/1")[2]["online"])
        self.store.close_session(1)
        self.assertEqual(self.request("/api/accounts/1", payload)[0], 200)
        self.assertFalse(self.store.path(1).exists())
        revision = self.configs.status()["revision"]
        self.assertEqual(self.request("/api/configs/props", {"row_id": "20014", "revision": revision})[0], 400)
        code, _, result = self.request("/api/configs/props", {"row_id": "20014", "changes": {"param1": "37"}, "revision": revision})
        self.assertEqual(code, 200)
        self.assertTrue(result["restart_required"])
        self.assertEqual(self.request("/api/configs/props?q=20014")[2]["rows"][0]["value"]["param1"], "37")


if __name__ == "__main__":
    unittest.main()
