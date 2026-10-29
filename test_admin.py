from contextlib import redirect_stdout
import copy
import http.client
import io
import json
import os
from pathlib import Path
import shutil
import tempfile
import threading
import unittest
import uuid
from unittest.mock import patch

from zyj_server import accounts, configuration, guide, player, protocol, replay, storage
from zyj_server.admin import gm, views
from zyj_server.admin.http import start_admin
from zyj_server.session import Session

ROOT = Path(__file__).parent
PASSWORD = "test-password-123"


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
        self.store.register(1, PASSWORD, self.store.snapshot(1)["revision"])
        self.store.open_session(1, PASSWORD, ("phone", 1234))
        self.addCleanup(self.store.close_session, 1)
        for action in ("backup", "reset", "reset-guide", "restore"):
            with self.subTest(action=action), self.assertRaisesRegex(ValueError, "在线"):
                self.maintain(action)
        with self.assertRaisesRegex(ValueError, "在线"):
            self.store.open_session(1, PASSWORD, ("emulator", 1235))
        snapshot = self.store.snapshot(1)
        self.assertTrue(snapshot["online"])
        self.assertEqual(snapshot["connection"]["address"], "phone")
        self.assertIsNotNone(self.maintain("backup", 2)["backup_id"])
        self.assertEqual(self.store.path(1).read_bytes(), before)

    def test_login_waits_until_reset_and_its_backup_are_complete(self):
        self.save()
        self.store.register(1, PASSWORD, self.store.snapshot(1)["revision"])
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
                sessions.append(self.store.open_session(1, PASSWORD, ("phone", 0)))
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
        self.store.register(1, PASSWORD, self.store.snapshot(1)["revision"])
        with self.assertRaises(ValueError):
            self.store.open_session(1, PASSWORD, ("phone", 0))
        self.assertEqual(self.store.active, {})


class AccountAuthenticationTests(AdminFixture):
    def register(self, account=1, password=PASSWORD):
        return self.store.register(account, password, self.store.snapshot(account)["revision"])

    def test_binding_preserves_old_progress_and_survives_store_restart(self):
        before = self.save()
        with patch.object(accounts, "Session") as load, self.assertRaisesRegex(ValueError, "未启用"):
            self.store.open_session(1, PASSWORD, ("phone", 0))
        load.assert_not_called()
        self.register()
        self.register(7)
        self.assertIn(7, self.store.account_ids())
        self.assertFalse(self.store.path(7).exists())
        record = json.loads(self.store.credential_path(1).read_bytes())
        other = json.loads(self.store.credential_path(7).read_bytes())
        self.assertEqual(record["iterations"], 600000)
        self.assertNotEqual(record["salt"], other["salt"])
        self.assertNotEqual(record["hash"], other["hash"])
        self.assertNotIn(PASSWORD, self.store.credential_path(1).read_text())
        if os.name != "nt":
            self.assertEqual(self.store.credential_path(1).stat().st_mode & 0o777, 0o600)
        restarted = accounts.AccountStore(self.store.save_path, TABLES, COUNTS, CONFIG)
        session = restarted.open_session(1, PASSWORD, ("phone", 0))
        self.assertEqual(session.save["role_name"], "测试账号1")
        self.assertEqual(self.store.path(1).read_bytes(), before)
        snapshot = restarted.snapshot(1)
        self.assertTrue(snapshot["registered"])
        for secret in (PASSWORD, record["salt"], record["hash"]):
            self.assertNotIn(secret, json.dumps(views.detail(snapshot, COUNTS, CONFIG)))
        restarted.close_session(1)

    def test_invalid_duplicate_stale_and_failed_creation_preserve_data(self):
        before = self.save()
        for password in (None, 12345678, "short", "a" * 65, "space password", "中文密码测试1234"):
            with self.subTest(password=password), self.assertRaises(ValueError):
                self.register(password=password)
        with self.assertRaisesRegex(ValueError, "变化"):
            self.store.register(1, PASSWORD, "stale")
        with patch.object(storage.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
            self.register()
        self.assertFalse(self.store.credential_path(1).exists())
        self.assertEqual(list(self.store.credential_path(1).parent.iterdir()), [])
        self.assertEqual(self.store.active, {})
        self.register()
        credential = self.store.credential_path(1).read_bytes()
        with self.assertRaisesRegex(ValueError, "已设置"):
            self.register(password="another-password")
        self.assertEqual(self.store.credential_path(1).read_bytes(), credential)
        self.assertEqual(self.store.path(1).read_bytes(), before)

    def test_failed_attempt_limit_covers_reconnects_but_not_other_accounts(self):
        self.register()
        self.register(2)
        with patch.object(accounts.time, "monotonic", return_value=100) as clock:
            for _ in range(5):
                with self.assertRaisesRegex(ValueError, "密码错误"):
                    self.store.open_session(1, "wrong-password", ("phone", 0))
            with patch.object(accounts.hashlib, "pbkdf2_hmac") as derive, self.assertRaisesRegex(ValueError, "频繁"):
                self.store.open_session(1, PASSWORD, ("other-device", 0))
            derive.assert_not_called()
            self.store.open_session(2, PASSWORD, ("phone", 0))
            self.store.close_session(2)
            clock.return_value = 160
            self.store.open_session(1, PASSWORD, ("phone", 0))
            self.store.close_session(1)
            for at in (200, 215, 230, 245, 260):
                clock.return_value = at
                with self.assertRaisesRegex(ValueError, "密码错误"):
                    self.store.authenticate(1, "wrong-password")
            clock.return_value = 261
            self.store.authenticate(1, PASSWORD)
        self.assertEqual(self.store.failed_logins, {})

    def test_corrupt_credentials_fail_closed_and_cannot_be_overwritten(self):
        self.register()
        path = self.store.credential_path(1)
        record = json.loads(path.read_bytes())
        for raw in (b"{", b"[]", json.dumps({**record, "iterations": 1}).encode(),
                    json.dumps({**record, "hash": "bad"}).encode()):
            path.write_bytes(raw)
            with patch.object(accounts, "Session") as load, self.assertRaisesRegex(ValueError, "配置损坏"):
                self.store.open_session(1, PASSWORD, ("phone", 0))
            load.assert_not_called()
            with self.assertRaisesRegex(ValueError, "已设置"):
                self.register()
            self.assertEqual(path.read_bytes(), raw)
            self.assertEqual(self.store.active, {})

    def test_credentials_survive_game_progress_reset_and_restore(self):
        self.save()
        self.register()
        credential = self.store.credential_path(1).read_bytes()
        backup = self.maintain("reset")["backup_id"]
        self.store.open_session(1, PASSWORD, ("phone", 0))
        self.store.close_session(1)
        self.maintain("restore", backup_id=backup)
        self.store.open_session(1, PASSWORD, ("phone", 0))
        self.store.close_session(1)
        self.assertEqual(self.store.credential_path(1).read_bytes(), credential)
        self.assertNotIn("credentials", self.store.snapshot(1)["save"])


class GmTests(AdminFixture):
    def setUp(self):
        super().setUp()
        self.save()
        self.gm = gm.Workbench(self.store)

    def request(self, resources=None, items=None):
        return {"operation_id": uuid.uuid4().hex, "revision": self.store.snapshot(1)["revision"],
                "reason": "测试补偿", "resources": {"gold": 10} if resources is None else resources,
                "items": items or []}

    def test_resources_sync_snapshots_and_clock_without_counting_recharge_or_consumption(self):
        before = self.store.snapshot(1)["save"]
        request = self.request({"gold": -before["role_state"]["gold"], "coin": 123, "stamina": 1000, "energy": 9})
        result = self.gm.apply(1, request)
        after = Session(TABLES, self.store.path(1), COUNTS, CONFIG).save
        self.assertEqual(after["role_state"]["gold"], 0)
        self.assertEqual(after["gold"], 0)
        self.assertEqual(after["silver"], before["role_state"]["coin"] + 123)
        self.assertEqual(after["energy"], before["role_state"]["energy"] + 9)
        self.assertEqual(after["stamina_clock"]["next_at"], 0)
        self.assertEqual(protocol.pb_get_varint(bytes.fromhex(after["role_snapshot"]), 9), 0)
        self.assertEqual(after["activity_state"], before["activity_state"])
        self.assertEqual(after["recharge_state"], before["recharge_state"])
        self.assertEqual(result["status"], "success")
        self.assertEqual(result["after_revision"], self.store.snapshot(1)["revision"])
        self.assertEqual(len(self.store.backups(1)), 1)

    def test_mixed_grant_preserves_roster_deduplicates_generals_and_restores(self):
        save = self.store.snapshot(1)["save"]
        save["guide"]["sections"]["1"].update(status=2, step=COUNTS[1])
        player.save_role(save, self.store.path(1), COUNTS)
        before = views.detail(self.store.snapshot(1), COUNTS, CONFIG)
        owned = {r["cid"] for r in before["generals"]}
        cid = next(r["cid"] for r in self.gm.items.values() if r["kind"] == "武将" and r["cid"] not in owned)
        request = self.request(items=[{"cid": 20014, "count": 3}, {"cid": 22204, "count": 2}, {"cid": cid, "count": 2}])
        result = self.gm.apply(1, request)
        after = views.detail(self.store.snapshot(1), COUNTS, CONFIG)
        self.assertIsNone(after["error"])
        self.assertEqual(len(after["generals"]), len(before["generals"]) + 1)
        self.assertEqual(len(after["equipment"]), len(before["equipment"]) + 2)
        self.assertEqual([r for r in after["generals"] if r["cid"] in owned], before["generals"])
        fragment = next(r for r in CONFIG["general_fragment"].values() if r["general"] == cid)
        count = next((r["count"] for r in before["inventory"] if r["cid"] == cid), 0)
        self.assertEqual(next(r["count"] for r in after["inventory"] if r["cid"] == cid), count + fragment["recruit"])
        self.assertTrue(any(r.get("iid", 0) and r["iid"] > 2000000 for r in result["changes"]))
        self.store.maintain(1, "restore", self.store.snapshot(1)["revision"], result["backup_id"])
        restored = self.store.path(1).read_bytes()
        self.assertEqual(gm.Workbench(self.store).apply(1, request)["status"], "success")
        self.assertEqual(self.store.path(1).read_bytes(), restored)

    def test_invalid_requests_and_overflows_never_change_save(self):
        before = self.store.path(1).read_bytes()
        for change in ({"resources": {"vip": 3}}, {"resources": {"gold": True}}, {"resources": {"gold": 1 << 31}},
                       {"resources": {"gold": -(1 << 30)}}, {"resources": {"coin": 1.5}},
                       {"reason": " "}, {"operation_id": "../bad"}, {"revision": "old"},
                       {"resources": {}, "items": []}, {"items": [{"cid": 10101, "count": 1}]},
                       {"items": [{"cid": 20014, "count": -1}]}, {"items": [{"cid": 20014, "count": True}]},
                       {"items": [{"cid": 20014, "count": 1}] * 2}, {"items": [{"cid": 22204, "count": 101}]}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                self.gm.apply(1, {**self.request(), **change})
            self.assertEqual(self.store.path(1).read_bytes(), before)
        data = self.store.snapshot(1)["save"]
        count = next((r["count"] for r in views.detail(self.store.snapshot(1), COUNTS, CONFIG)["inventory"] if r["cid"] == 20014), 0)
        player.change_item_count(data, 20014, (1 << 31) - 1 - count, CONFIG)
        player.save_role(data, self.store.path(1), COUNTS)
        before = self.store.path(1).read_bytes()
        with self.assertRaises(ValueError):
            self.gm.apply(1, self.request(items=[{"cid": 20014, "count": 1}]))
        self.assertEqual(self.store.path(1).read_bytes(), before)
        self.assertEqual(self.store.backups(1), [])

    def test_online_stale_and_uncreated_roles_are_rejected_with_audit(self):
        before = self.store.path(1).read_bytes()
        self.store.active[1] = {"address": "phone", "connected_at": 1}
        with self.assertRaisesRegex(ValueError, "在线"):
            self.gm.apply(1, self.request())
        self.store.close_session(1)
        with self.assertRaisesRegex(ValueError, "变化"):
            self.gm.apply(1, {**self.request(), "revision": "0" * 64})
        with self.assertRaisesRegex(ValueError, "创建"):
            self.gm.apply(2, {**self.request(), "revision": self.store.snapshot(2)["revision"]})
        self.assertEqual(self.store.path(1).read_bytes(), before)
        self.assertEqual(self.gm.history(1, "grant")["total"], 2)
        self.assertTrue(all(row["status"] == "failed" for row in self.gm.history()["rows"]))

    def test_backups_journal_and_save_failures_preserve_original(self):
        before = self.store.path(1).read_bytes()
        with patch.object(self.gm, "_write", side_effect=OSError("log full")), self.assertRaises(OSError):
            self.gm.apply(1, self.request())
        with patch.object(storage, "backup", side_effect=OSError("backup full")), self.assertRaises(OSError):
            self.gm.apply(1, self.request())
        self.assertEqual(self.store.backups(1), [])
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.gm.apply(1, self.request())
        self.assertEqual(self.store.path(1).read_bytes(), before)
        self.assertEqual(self.gm.history()["total"], 2)
        self.assertTrue(all(row["status"] == "failed" for row in self.gm.history()["rows"]))

    def test_retry_after_missing_final_journal_write_is_exactly_once_across_restart(self):
        request = self.request()
        write = self.gm._write
        def fail_success(row):
            if row["status"] == "success":
                raise OSError("log full")
            write(row)
        with patch.object(self.gm, "_write", side_effect=fail_success):
            result = self.gm.apply(1, request)
        self.assertIn("audit_warning", result)
        before = self.store.path(1).read_bytes()
        restarted = gm.Workbench(self.store)
        self.assertEqual(restarted.apply(1, request)["status"], "success")
        self.assertEqual(self.store.path(1).read_bytes(), before)
        self.assertEqual(restarted.history()["rows"][0]["status"], "success")
        with self.assertRaisesRegex(ValueError, "编号"):
            restarted.apply(1, {**request, "resources": {"gold": 99}})
        restarted.apply(1, self.request())
        self.assertTrue(all(row["status"] == "success" for row in restarted.history()["rows"]))
        self.assertEqual(len(self.store.backups(1)), 2)

    def test_crash_before_save_leaves_queryable_pending_operation_not_reexecuted(self):
        request = self.request()
        before = self.store.path(1).read_bytes()
        with patch.object(player, "save_response_group", side_effect=SystemExit), self.assertRaises(SystemExit):
            self.gm.apply(1, request)
        self.assertEqual(gm.Workbench(self.store).apply(1, request)["status"], "pending")
        self.assertEqual(self.store.path(1).read_bytes(), before)

    def test_web_restore_finalizes_success_receipt_before_replacing_it(self):
        request = self.request()
        write = self.gm._write
        def fail_success(row):
            if row["status"] == "success":
                raise OSError("log full")
            write(row)
        with patch.object(self.gm, "_write", side_effect=fail_success):
            result = self.gm.apply(1, request)
        revision = self.store.snapshot(1)["revision"]
        self.gm.logged("restore", 1, {"revision": revision, "backup_id": result["backup_id"]},
                       lambda: self.store.maintain(1, "restore", revision, result["backup_id"]))
        restored = self.store.path(1).read_bytes()
        self.assertNotIn("gm_receipt", self.store.snapshot(1)["save"])
        self.assertEqual(gm.Workbench(self.store).apply(1, request)["status"], "success")
        self.assertEqual(self.store.path(1).read_bytes(), restored)
        self.assertTrue(all(row["status"] == "success" for row in self.gm.history()["rows"]))

    def test_gm_holds_login_lock_until_save_and_audit_complete(self):
        self.store.register(1, PASSWORD, self.store.snapshot(1)["revision"])
        request = self.request()
        entered, release, connected = threading.Event(), threading.Event(), threading.Event()
        errors, sessions = [], []
        real_backup = storage.backup
        def backup(*args):
            entered.set()
            if not release.wait(5):
                raise TimeoutError("GM 未释放")
            return real_backup(*args)
        def grant():
            try:
                self.gm.apply(1, request)
            except Exception as error:
                errors.append(error)
        def login():
            try:
                sessions.append(self.store.open_session(1, PASSWORD, ("phone", 0)))
                connected.set()
            except Exception as error:
                errors.append(error)
        with patch.object(storage, "backup", side_effect=backup):
            worker, client = threading.Thread(target=grant), threading.Thread(target=login)
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
        self.assertEqual(errors, [])
        self.assertTrue(connected.is_set())
        self.assertEqual(sessions[0].save["gm_receipt"], request["operation_id"])


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
        self.store.register(1, PASSWORD, self.store.snapshot(1)["revision"])
        self.store.open_session(1, PASSWORD, ("phone", 0))
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

    def test_http_creates_and_binds_accounts_without_exposing_credentials(self):
        before = self.store.path(1).read_bytes()
        for account in (1, 17):
            route = f"/api/accounts/{account}/credentials"
            payload = {"password": PASSWORD, "revision": self.store.snapshot(account)["revision"]}
            for headers in ({"Host": "evil.example"}, {"Origin": "https://evil.example"}, {"X-Admin-Token": "bad"}):
                self.assertEqual(self.request(route, payload, headers)[0], 403)
            self.assertFalse(self.store.credential_path(account).exists())
            self.assertEqual(self.request(route, {**payload, "unexpected": True})[0], 400)
            self.assertEqual(self.request(route, payload)[0], 200)
            self.assertEqual(self.request(route, payload)[0], 400)
            self.assertEqual(self.request(route)[0], 404)
            detail = self.request(f"/api/accounts/{account}")[2]
            self.assertTrue(detail["registered"])
            self.assertNotIn(PASSWORD, json.dumps(detail))
        self.assertEqual([row["id"] for row in self.request("/api/accounts")[2]["accounts"]], [1, 17])
        self.assertEqual(self.request("/api/accounts/1/download")[2], before)
        self.assertFalse(self.store.path(17).exists())

    def test_gm_catalog_and_structured_views_are_read_only_and_paginated(self):
        before = self.store.path(1).read_bytes()
        code, _, catalog = self.request("/api/catalog?q=20014")
        self.assertEqual(code, 200)
        self.assertEqual(catalog["rows"][0]["cid"], 20014)
        first = self.request("/api/catalog")[2]
        second = self.request("/api/catalog?offset=50")[2]
        self.assertEqual(len(first["rows"]), 50)
        self.assertFalse({r["cid"] for r in first["rows"]} & {r["cid"] for r in second["rows"]})
        self.assertNotIn(10101, self.http.gm.items)
        for row in self.http.gm.items.values():
            if row["kind"] == "武将碎片":
                self.assertIn(str(CONFIG["general_fragment"][str(row["cid"])]["general"]), CONFIG["general"])
        data = self.request("/api/accounts/1")[2]
        self.assertEqual(len(data["business"]["recruit"]), 4)
        self.assertEqual(data["business"]["recharge"]["rmb"], SAVE["recharge_state"]["rmb"])
        self.assertTrue(data["copies"][0]["points"])
        for path in ("/api/catalog?offset=-1", "/api/catalog?kind=invalid", "/api/operations?account=1001", "/api/operations?action=no", "/api/operations?since=-1"):
            self.assertEqual(self.request(path)[0], 400)
        self.assertEqual(self.store.path(1).read_bytes(), before)
        self.assertFalse(self.http.gm.directory.exists())

    def test_gm_http_retries_and_operation_records_preserve_credentials(self):
        before = self.store.path(1).read_bytes()
        payload = {"operation_id": uuid.uuid4().hex, "revision": self.store.snapshot(1)["revision"],
                   "reason": "HTTP 补偿", "resources": {"gold": 5}, "items": [{"cid": 20014, "count": 2}]}
        for headers in ({"Host": "evil.example"}, {"Origin": "https://evil.example"}, {"X-Admin-Token": "bad"}):
            self.assertEqual(self.request("/api/accounts/1/gm", payload, headers)[0], 403)
        self.assertEqual(self.store.path(1).read_bytes(), before)
        self.assertEqual(self.request("/api/accounts/1/gm", payload)[0], 200)
        after = self.store.path(1).read_bytes()
        self.assertEqual(self.request("/api/accounts/1/gm", payload)[2]["status"], "success")
        self.assertEqual(self.store.path(1).read_bytes(), after)
        revision = self.store.snapshot(1)["revision"]
        self.request("/api/accounts/1/credentials", {"password": PASSWORD, "revision": revision})
        self.request("/api/accounts/1", {"action": "backup", "revision": revision})
        revision = self.configs.status()["revision"]
        self.request("/api/configs/props", {"row_id": "20014", "changes": {"param1": "31"}, "revision": revision})
        records = self.request("/api/operations")[2]
        self.assertEqual({r["action"] for r in records["rows"]}, {"grant", "register", "backup", "config"})
        self.assertNotIn(PASSWORD, json.dumps(records))
        credential = json.loads(self.store.credential_path(1).read_bytes())
        self.assertNotIn(credential["hash"], json.dumps(records))
        self.assertEqual(self.request("/api/operations?account=1&action=grant")[2]["total"], 1)
        self.assertEqual(self.request("/api/operations?offset=50")[2]["rows"], [])
        self.assertEqual(self.request(f'/api/operations?since={int(records["rows"][0]["at"]) + 1}')[2]["total"], 0)
        changed = next(r for r in records["rows"] if r["action"] == "config")
        self.assertEqual(changed["result"]["changes"], [{"name": "param1", "before": "25", "after": "31"}])
        self.assertEqual(self.request("/api/configs/props?q=20014")[2]["rows"][0]["original"]["param1"], "25")


if __name__ == "__main__":
    unittest.main()
