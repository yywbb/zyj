from contextlib import redirect_stdout
import copy
import http.client
import io
import json
import os
from pathlib import Path
import shutil
import struct
import tempfile
import threading
import unittest
import uuid
from unittest.mock import patch

from zyj_server import accounts, configuration, formation, guide, player, protocol, recharge, replay, storage
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


class GuildTests(AdminFixture):
    def setUp(self):
        super().setUp()
        self.now = 1793430000
        self.clock = patch("time.time", return_value=self.now).start()
        self.addCleanup(patch.stopall)
        patch.object(self.store, "authenticate", return_value=None).start()
        self.sessions = {}
        self.seq = 30000
        for account in (1, 2, 3):
            self.add_account(account)

    def add_account(self, account):
        data = json.loads(self.save(account))
        data["created_at"] = self.now - 3600 + account
        data["role_state"].update(level=19, gold=10000, nextexp=CONFIG["role_exp"]["19"]["nextexp"])
        self.assertTrue(player.save_role(data, self.store.path(account), COUNTS))
        self.sessions[account] = self.store.open_session(account, PASSWORD, ("phone", account))
        self.addCleanup(self.store.close_session, account)

    def request(self, account, opcode, values=None, text=None, raw=None):
        if raw is None:
            raw = (protocol.encode_pb_field(1, 2, protocol.encode_pb_field(2, 2, text.encode())) if text is not None
                   else b"".join(protocol.encode_pb_field(1, 0, v) for v in (values or [])))
        self.seq += 1
        packets = self.sessions[account].handle(opcode, self.seq, raw)
        return [(struct.unpack(">IIII", p[:16])[2], p[16:]) for p in packets]

    def success(self, account, opcode, **kwargs):
        packets = self.request(account, opcode, **kwargs)
        self.assertEqual(packets[0][0], opcode, packets)
        return packets[0][1]

    def guild_id(self, account):
        rows = self.business_rows(self.success(account, 2230))
        if 1 not in rows:
            return 0
        first = next(v for n, w, v in protocol.iter_pb_fields(rows[1]) if (n, w) == (1, 2))
        return protocol.pb_get_varint(first, 1)

    def business_rows(self, body):
        rows = {}
        for n, w, value in protocol.iter_pb_fields(body):
            self.assertEqual((n, w), (1, 2))
            fields = list(protocol.iter_pb_fields(value))
            self.assertEqual([f[:2] for f in fields], [(1, 0), (2, 2)])
            rows[fields[0][2]] = fields[1][2]
        return rows

    def create(self, account=1, name="测试公会"):
        self.assertEqual(protocol.parse_ids_pb(self.success(account, 2231, text=name)), [0])
        return self.guild_id(account)

    def test_entry_create_search_and_reconnect_use_real_membership(self):
        self.assertEqual(self.guild_id(1), 0)
        self.assertEqual(self.success(1, 2232), b"")
        gid = self.create()
        self.assertGreater(gid, 0)
        self.assertEqual(self.store.snapshot(1)["save"]["role_state"]["gold"], 9000)
        self.assertTrue(self.success(2, 2232))
        self.assertTrue(self.success(2, 2243, text="测试公会"))
        self.assertFalse(self.success(2, 2243, text="不存在"))
        self.assertEqual(self.request(1, 2231, text="重复创建")[0][0], 999999)
        self.store.close_session(1)
        self.sessions[1] = self.store.open_session(1, PASSWORD, ("reconnect", 1))
        self.assertEqual(self.guild_id(1), gid)
        self.assertEqual(self.sessions[1].save["role_state"]["gold"], 9000)
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 2265)), [0, 19])

    def test_native_application_approval_cancel_and_rejection(self):
        gid = self.create()
        self.assertEqual(protocol.parse_ids_pb(self.success(2, 2233, values=[gid])), [0])
        self.assertTrue(self.success(1, 2234))
        self.success(2, 2267, values=[gid])
        self.assertFalse(self.success(1, 2234))
        self.success(2, 2233, values=[0])
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 2235, values=[1000002, 1])), [2005])
        self.assertEqual(self.guild_id(2), 0)
        self.success(2, 2233, values=[gid])
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 2235, values=[1000002, 0])), [0])
        self.assertEqual(self.guild_id(2), gid)
        self.assertFalse(self.success(1, 2234))
        self.assertEqual(self.request(1, 2235, values=[1000002, 0])[0][0], 999999)
        self.assertEqual(self.store.snapshot(2)["save"]["role_state"]["gold"], 10000)

    def test_member_permissions_promotion_transfer_kick_and_disband(self):
        gid = self.create()
        self.success(1, 2265, values=[1, 19])
        for account in (2, 3):
            self.assertEqual(protocol.parse_ids_pb(self.success(account, 2233, values=[gid])), [1])
        for op, args in ((2237, {"text": "越权"}), (2239, {"values": [0, 1000003]}),
                         (2240, {"values": [1000003]}), (2241, {"values": [1000003]}), (2266, {})):
            self.assertEqual(self.request(2, op, **args)[0][0], 999999)
        self.success(1, 2239, values=[0, 1000002])
        self.success(2, 2237, text="新公告")
        self.assertEqual(self.request(2, 2240, values=[1000001])[0][0], 999999)
        self.success(2, 2240, values=[1000003])
        self.assertEqual(self.guild_id(3), 0)
        self.assertEqual(self.request(1, 2266)[0][0], 999999)
        self.success(1, 2241, values=[1000002])
        members = self.business_rows(self.success(2, 2236))
        own_rid = protocol.pb_get_varint(bytes.fromhex(self.sessions[2].save["role_snapshot"]), 1)
        self.assertEqual(protocol.parse_ids_pb(members[0])[0], own_rid)
        self.success(1, 2242)
        self.success(2, 2266)
        self.assertEqual(self.guild_id(2), 0)
        self.assertEqual(self.success(3, 2232), b"")

    def test_limits_cooldown_and_identity_survive_restart_and_rollback(self):
        gid = self.create()
        self.success(1, 2265, values=[1, 20])
        self.assertEqual(self.request(2, 2233, values=[gid])[0][0], 999999)
        self.success(1, 2265, values=[1, 19])
        with patch.dict(CONFIG["gang2_level"]["1"], people=1):
            self.assertEqual(self.request(2, 2233, values=[gid])[0][0], 999999)
        self.success(2, 2233, values=[gid])
        self.success(2, 2242)
        self.assertEqual(self.request(2, 2233, values=[gid])[0][0], 999999)
        self.clock.return_value += int(CONFIG["global_kv"]["gang_quit_limit"]["value"])
        self.success(2, 2233, values=[gid])
        self.clock.return_value -= 100
        self.success(2, 2242)
        self.assertEqual(self.request(2, 2233, values=[gid])[0][0], 999999)
        self.sessions[1].save["created_at"] += 1000
        player.save_role(self.sessions[1].save, self.store.path(1), COUNTS)
        self.assertEqual(self.guild_id(1), 0)

    def test_untrusted_parameters_names_and_foreign_targets_never_spend(self):
        for body in (b"", b"\x08\x01", b"\x0a\x00", b"\x0a\x02\x12\xff"):
            self.assertEqual(self.request(1, 2231, raw=body)[0][0], 999999)
        for name in ("", " ", "x" * 13, "bad\nname"):
            self.assertEqual(self.request(1, 2231, text=name)[0][0], 999999)
        self.assertEqual(self.sessions[1].save["role_state"]["gold"], 10000)
        self.create()
        for opcode, raw in ((2230, b"\x08\x00"), (2232, b"\x08\x01"), (2239, b"\x08\x00"),
                            (2240, b"\x08\x01"), (2265, b"\x08\x02\x08\x13")):
            before = (self.root / "guilds.json").read_bytes()
            self.assertEqual(self.request(1, opcode, raw=raw)[0][0], 999999)
            self.assertEqual((self.root / "guilds.json").read_bytes(), before)

    def test_exact_ten_query_preload_and_initialization_refresh_membership(self):
        gid = self.create()
        ids = (2313, 4800, 6911, 3210, 7002, 2230, 2037, 2039, 6501, 6810)
        body = b"".join(protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, mid)) for mid in ids)
        rows = protocol.get_comb_messages(self.success(1, 999900, raw=body))
        self.assertEqual([mid for mid, _ in rows], list(ids))
        self.assertEqual(dict(rows)[2230], self.success(1, 2230))
        initial = next(f for f in replay.load_recordings(ROOT / "recorded_frames.json")
                       if f["c2s"] and f["opcode"] == 999900 and 1001 in protocol.get_comb_ids(bytes.fromhex(f["hex"])))
        rows = dict(protocol.get_comb_messages(self.success(1, 999900, raw=bytes.fromhex(initial["hex"]))))
        self.assertEqual(rows[2230], self.success(1, 2230))
        self.assertEqual(self.guild_id(1), gid)
        for invalid in (body + b"\x10\x01", body + body[:5], body.replace(b"\x0a\x03\x08\xb6\x11", b"\x0a\x05\x08\xb6\x11\x18\x01")):
            self.assertEqual(self.request(1, 999900, raw=invalid)[0][0], 999999)

    def test_failed_creation_save_and_publish_recover_without_free_guild_or_double_charge(self):
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 2231, text="未扣款")
        self.assertEqual(self.sessions[1].save["role_state"]["gold"], 10000)
        self.assertEqual(self.guild_id(1), 0)
        original = storage.atomic_write

        def fail_publish(path, raw):
            state = json.loads(raw) if Path(path).name == "guilds.json" else {}
            if state.get("guilds") and not any(g.get("pending") for g in state["guilds"].values()):
                raise OSError("publish failed")
            return original(path, raw)

        with patch.object(storage, "atomic_write", side_effect=fail_publish), self.assertRaises(OSError):
            self.request(1, 2231, text="已扣款待恢复")
        self.store.close_session(1)
        self.sessions[1] = self.store.open_session(1, PASSWORD, ("reconnect", 1))
        self.assertGreater(self.guild_id(1), 0)
        self.assertEqual(self.sessions[1].save["role_state"]["gold"], 9000)

    def test_concurrent_duplicate_names_and_corrupt_journal_fail_closed(self):
        barrier = threading.Barrier(2)
        result = []
        def create(account):
            barrier.wait(5)
            result.append(self.request(account, 2231, text="同名公会")[0][0])
        threads = [threading.Thread(target=create, args=(a,)) for a in (1, 2)]
        for t in threads:
            t.start()
        for t in threads:
            t.join(10)
            self.assertFalse(t.is_alive())
        self.assertCountEqual(result, [2231, 999999])
        self.assertEqual(sum(self.store.snapshot(a)["save"]["role_state"]["gold"] for a in (1, 2)), 19000)
        (self.root / "guilds.json").write_text('{"guilds": null}')
        self.assertEqual(self.request(3, 2231, text="损坏时不得创建")[0][0], 999999)
        self.assertEqual(self.sessions[3].save["role_state"]["gold"], 10000)

    def test_creation_cost_and_failed_draft_preserve_pending_applications(self):
        gid = self.create()
        self.success(2, 2233, values=[gid])
        data = self.sessions[2].save
        data["role_snapshot"] = protocol.pb_set_varint(bytes.fromhex(data["role_snapshot"]), 22, self.now - 3600).hex()
        self.sessions[2].save["role_state"]["gold"] = 999
        before = copy.deepcopy(self.sessions[2].save)
        journal = (self.root / "guilds.json").read_bytes()
        self.assertEqual(self.request(2, 2231, text="余额不足")[0][0], 999999)
        self.assertEqual(self.sessions[2].save, before)
        self.assertEqual((self.root / "guilds.json").read_bytes(), journal)
        self.sessions[2].save["role_state"]["gold"] = 10000
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(2, 2231, text="失败草稿")
        self.assertTrue(self.success(1, 2234))
        packets = self.request(2, 2231, text="独立公会")
        self.assertEqual([op for op, _ in packets[:2]], [2231, 1001])
        self.assertEqual(protocol.pb_get_varint(packets[1][1], 9), 9000)
        self.assertFalse(self.success(1, 2234))
        self.assertEqual(self.sessions[2].save["activity_state"]["gold_spent"], 1000)

    def test_parallel_approvals_cannot_join_two_guilds(self):
        self.create(1, "第一公会")
        self.create(2, "第二公会")
        self.success(3, 2233, values=[0])
        barrier, results = threading.Barrier(2), []
        def approve(account):
            barrier.wait(5)
            results.append(self.request(account, 2235, values=[1000003, 0])[0][0])
        threads = [threading.Thread(target=approve, args=(a,)) for a in (1, 2)]
        for t in threads:
            t.start()
        for t in threads:
            t.join(10)
            self.assertFalse(t.is_alive())
        self.assertCountEqual(results, [2235, 999999])
        state = json.loads((self.root / "guilds.json").read_bytes())
        self.assertEqual(sum("3" in g["members"] for g in state["guilds"].values()), 1)
        self.assertFalse(self.success(1, 2234))
        self.assertFalse(self.success(2, 2234))

    def test_parallel_auto_join_respects_last_slot_and_failed_membership_write(self):
        gid = self.create()
        self.success(1, 2265, values=[1, 19])
        original = (self.root / "guilds.json").read_bytes()
        with patch.object(storage, "atomic_write", side_effect=OSError("disk full")), self.assertRaises(OSError):
            self.request(2, 2233, values=[gid])
        self.assertEqual((self.root / "guilds.json").read_bytes(), original)
        self.assertEqual(self.guild_id(2), 0)
        barrier, results = threading.Barrier(2), []
        def join(account):
            barrier.wait(5)
            results.append(self.request(account, 2233, values=[gid])[0][0])
        threads = [threading.Thread(target=join, args=(a,)) for a in (2, 3)]
        with patch.dict(CONFIG["gang2_level"]["1"], people=2):
            for t in threads:
                t.start()
            for t in threads:
                t.join(10)
                self.assertFalse(t.is_alive())
        self.assertCountEqual(results, [2233, 999999])

    def test_corrupt_role_or_missing_guild_file_never_erases_membership(self):
        self.create()
        original = self.store.path(1).read_bytes()
        journal = (self.root / "guilds.json").read_bytes()
        for broken in ({}, {"has_role": True}, {**json.loads(original), "created_at": None},
                       {**json.loads(original), "guild_creations": "invalid"}):
            self.store.path(1).write_text(json.dumps(broken))
            self.assertEqual(self.request(2, 2232)[0][0], 999999)
            self.assertEqual((self.root / "guilds.json").read_bytes(), journal)
        self.store.path(1).write_bytes(original)
        (self.root / "guilds.json").unlink()
        self.assertEqual(self.request(2, 2231, text="不能重置数据库")[0][0], 999999)
        self.assertFalse((self.root / "guilds.json").exists())

    def test_process_restart_and_recreated_leader_keep_other_members(self):
        gid = self.create()
        self.success(1, 2265, values=[1, 19])
        self.success(2, 2233, values=[gid])
        self.store.close_session(1)
        self.maintain("reset", 1)
        restarted = accounts.AccountStore(self.store.save_path, TABLES, COUNTS, CONFIG)
        with patch.object(restarted, "authenticate", return_value=None):
            self.sessions[2] = restarted.open_session(2, PASSWORD, ("restarted", 2))
        self.assertEqual(self.guild_id(2), gid)
        self.add_account(1)
        self.assertEqual(self.guild_id(1), 0)
        posts = protocol.parse_ids_pb(self.business_rows(self.success(2, 2236))[0])
        own = protocol.pb_get_varint(bytes.fromhex(self.sessions[2].save["role_snapshot"]), 1)
        self.assertEqual(posts, [own, 0, 0, 0])

    def test_guild_incense_prices_contribution_experience_and_native_reply_order(self):
        gid = self.create()
        self.success(1, 2265, values=[1, 19])
        for account in (2, 3):
            self.success(account, 2233, values=[gid])
        for account, method, cid, amount in ((1, 1, 1000, 50000), (2, 2, 1001, 50), (3, 3, 1001, 200)):
            save = self.sessions[account].save
            save["role_state"].update(vip=3, coin=100000)
            before = copy.deepcopy(save["role_state"])
            self.assertEqual(protocol.parse_ids_pb(self.success(account, 2250)), [0])
            packets = self.request(account, 2251, values=[method])
            row = CONFIG["gang2_incense"][str(method)]
            self.assertEqual([op for op, _ in packets[:2]], [2251, 1001])
            self.assertEqual(protocol.parse_ids_pb(packets[0][1]), [row["contribution"], row["gang_exp"], 0])
            field, number = ("coin", 8) if cid == 1000 else ("gold", 9)
            self.assertEqual(protocol.pb_get_varint(packets[1][1], number), before[field] - amount)
            saved = self.store.snapshot(account)["save"]
            self.assertEqual(saved["role_state"][field], before[field] - amount)
            self.assertEqual(saved["guild_daily_state"]["contribution"], row["contribution"])
            self.assertEqual(protocol.parse_ids_pb(self.success(account, 2250)), [method])
        journal = json.loads((self.root / "guilds.json").read_bytes())
        self.assertEqual(journal["guilds"][str(gid)]["experience"], 510000)
        for account, amount in ((1, 20000), (2, 40000), (3, 200000)):
            status = self.business_rows(self.success(account, 2230))
            self.assertEqual(protocol.parse_ids_pb(status[2])[:2], [amount, amount])

    def test_guild_daily_reward_is_configured_atomic_and_once_after_reconnect(self):
        self.create()
        before = copy.deepcopy(self.sessions[1].save)
        packets = self.request(1, 2260)
        self.assertEqual([op for op, _ in packets[:2]], [2260, 1001])
        self.assertTrue(packets[0][1])
        current = self.store.snapshot(1)["save"]
        for cid, amount in ((20256, 20), (20197, 2)):
            def count(save):
                return next((protocol.pb_get_varint(v, 2) for n, w, v in protocol.iter_pb_fields(bytes.fromhex(save["world_state"]["1200"]))
                             if (n, w) == (1, 2) and protocol.pb_get_varint(v, 1) == cid), 0)
            self.assertEqual(count(current) - count(before), amount)
        self.assertEqual(protocol.parse_ids_pb(self.business_rows(self.success(1, 2230))[2])[3], 1)
        self.store.close_session(1)
        self.sessions[1] = self.store.open_session(1, PASSWORD, ("reconnect", 1))
        original = self.store.path(1).read_bytes()
        self.assertEqual(self.request(1, 2260)[0][0], 999999)
        self.assertEqual(self.store.path(1).read_bytes(), original)

    def test_guild_daily_invalid_locked_overflow_and_insufficient_funds_never_mutate(self):
        self.assertEqual(self.request(1, 2260)[0][0], 999999)
        self.assertEqual(self.request(1, 2250)[0][0], 999999)
        self.create()
        save = self.sessions[1].save
        save["role_state"].update(coin=49999, gold=49, vip=2)
        for op, values in ((2250, [1]), (2260, [1]), (2251, []), (2251, [0]), (2251, [4]), (2251, [1, 1]),
                           (2251, [1]), (2251, [2]), (2251, [3])):
            before = copy.deepcopy(save)
            journal = (self.root / "guilds.json").read_bytes()
            self.assertEqual(self.request(1, op, values=values)[0][0], 999999)
            self.assertEqual(self.sessions[1].save, before)
            self.assertEqual((self.root / "guilds.json").read_bytes(), journal)
        self.success(1, 2250)
        self.sessions[1].save["guild_daily_state"]["contribution"] = (1 << 31) - 1
        self.sessions[1].save["role_state"]["coin"] = 100000
        self.assertEqual(self.request(1, 2251, values=[1])[0][0], 999999)

    def test_guild_daily_forward_midnight_rollback_and_switching_cannot_repeat(self):
        gid = self.create()
        self.create(2, "另一公会")
        self.success(2, 2265, values=[1, 19])
        self.success(1, 2251, values=[2])
        self.success(1, 2260)
        self.success(1, 2266)
        self.clock.return_value += int(CONFIG["global_kv"]["gang_quit_limit"]["value"])
        self.success(1, 2233, values=[self.guild_id(2)])
        self.assertNotEqual(self.guild_id(1), gid)
        self.assertEqual(self.request(1, 2251, values=[2])[0][0], 999999)
        self.assertEqual(self.request(1, 2260)[0][0], 999999)
        self.clock.return_value = ((self.now + 28800) // 86400 + 1) * 86400 - 28800
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 2250)), [0])
        self.success(1, 2251, values=[2])
        self.success(1, 2260)
        self.clock.return_value = self.now
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 2250)), [2])
        self.assertEqual(self.request(1, 2260)[0][0], 999999)

    def test_guild_incense_completes_daily_task_and_claims_once(self):
        day = (self.now + 28800) // 86400
        self.sessions[1].save["activity_state"].update(liveness_day=day, liveness_week=(day + 3) // 7)
        self.create()
        self.success(1, 2250)
        values = protocol.parse_ids_pb(self.success(1, 2410))
        self.assertEqual((values[22], values[len(values) // 2 + 22]), (0, 0))
        self.success(1, 2251, values=[1])
        values = protocol.parse_ids_pb(self.success(1, 2410))
        self.assertEqual((values[22], values[len(values) // 2 + 22]), (1, 1))
        self.success(1, 2411, values=[123])
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 6517))[0], 5)
        self.store.close_session(1)
        self.sessions[1] = self.store.open_session(1, PASSWORD, ("reconnect", 1))
        disk = self.store.path(1).read_bytes()
        self.assertEqual(self.request(1, 2411, values=[123])[0][0], 999999)
        self.assertEqual(self.request(1, 2251, values=[1])[0][0], 999999)
        self.assertEqual(self.store.path(1).read_bytes(), disk)
        self.clock.return_value += 86400
        values = protocol.parse_ids_pb(self.success(1, 2410))
        self.assertEqual((values[22], values[len(values) // 2 + 22]), (0, 0))
        self.success(1, 2251, values=[1])
        self.success(1, 2411, values=[123])
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 6517))[0], 10)

    def test_guild_incense_save_and_publish_failures_recover_exactly_once(self):
        gid = self.create()
        self.success(1, 2250)
        before = copy.deepcopy(self.sessions[1].save)
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 2251, values=[2])
        self.assertEqual(self.sessions[1].save, before)
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 2250)), [0])
        original = storage.atomic_write
        def fail_publish(path, raw):
            state = json.loads(raw) if Path(path).name == "guilds.json" else {}
            row = state.get("guilds", {}).get(str(gid), {})
            if row.get("experience") and "pending_pray" not in row:
                raise OSError("publish failed")
            return original(path, raw)
        with patch.object(storage, "atomic_write", side_effect=fail_publish), self.assertRaises(OSError):
            self.request(1, 2251, values=[2])
        self.store.close_session(1)
        self.sessions[1] = self.store.open_session(1, PASSWORD, ("restart", 1))
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 2250)), [2])
        for _ in range(2):
            self.assertEqual(self.request(1, 2251, values=[2])[0][0], 999999)
            self.success(1, 2230)
        self.assertEqual(self.sessions[1].save["role_state"]["gold"], before["role_state"]["gold"] - 50)
        row = json.loads((self.root / "guilds.json").read_bytes())["guilds"][str(gid)]
        self.assertEqual(row["experience"], 150000)
        self.assertNotIn("pending_pray", row)
        before = copy.deepcopy(self.sessions[1].save)
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 2260)
        self.assertEqual(self.sessions[1].save, before)
        self.success(1, 2260)

    def test_guild_concurrent_incense_accumulates_shared_experience_and_level_rewards(self):
        gid = self.create()
        self.success(1, 2265, values=[1, 19])
        self.success(2, 2233, values=[gid])
        path = self.root / "guilds.json"
        state = json.loads(path.read_bytes())
        state["guilds"][str(gid)]["experience"] = CONFIG["gang2_level"]["1"]["gang_exp"] - 150000
        path.write_text(json.dumps(state))
        barrier, results = threading.Barrier(2), []
        def pray(account):
            barrier.wait(5)
            results.append(self.request(account, 2251, values=[2])[0][0])
        threads = [threading.Thread(target=pray, args=(a,)) for a in (1, 2)]
        for thread in threads:
            thread.start()
        for thread in threads:
            thread.join(10)
            self.assertFalse(thread.is_alive())
        self.assertEqual(results, [2251, 2251])
        status = self.business_rows(self.success(1, 2230))
        values = [protocol.pb_get_varint(v, 1) for n, w, v in protocol.iter_pb_fields(status[1]) if (n, w) == (1, 2)]
        self.assertEqual(values[2:4], [2, 150000])
        reward = self.success(1, 2260)
        props = next(v for n, w, v in protocol.iter_pb_fields(reward) if (n, w) == (5, 2))
        self.assertEqual({protocol.pb_get_varint(v, 1): protocol.pb_get_varint(v, 2)
                          for n, w, v in protocol.iter_pb_fields(props) if (n, w) == (1, 2)}, {20256: 30, 20197: 3})

    def test_guild_corrupt_daily_state_or_pending_receipt_fail_closed(self):
        self.create()
        self.success(1, 2250)
        path, journal = self.store.path(1), self.root / "guilds.json"
        original, shared = path.read_bytes(), journal.read_bytes()
        for key, value in (("day", True), ("pray", 4), ("claimed", 1), ("receipt", "bad"), ("contribution", -1)):
            save = json.loads(original)
            save["guild_daily_state"][key] = value
            path.write_text(json.dumps(save))
            self.assertEqual(self.request(2, 2232)[0][0], 999999)
            self.assertEqual(journal.read_bytes(), shared)
        path.write_bytes(original)
        state = json.loads(shared)
        state["guilds"]["1"]["pending_pray"] = {"account": "1", "identity": self.now, "token": "bad", "exp": 1}
        journal.write_text(json.dumps(state))
        self.assertEqual(self.request(1, 2251, values=[2])[0][0], 999999)
        self.assertEqual(path.read_bytes(), original)

    def test_guild_daily_reward_inventory_overflow_and_parallel_claims(self):
        self.create()
        save = self.sessions[1].save
        initial = copy.deepcopy(save)
        player.change_item_count(save, 20256, (1 << 31) - 1, CONFIG, self.now)
        before = copy.deepcopy(save)
        self.assertEqual(self.request(1, 2260)[0][0], 999999)
        self.assertEqual(self.sessions[1].save, before)
        self.sessions[1].save = initial
        barrier, results = threading.Barrier(2), []
        def claim():
            barrier.wait(5)
            results.append(self.request(1, 2260)[0][0])
        threads = [threading.Thread(target=claim) for _ in range(2)]
        for thread in threads:
            thread.start()
        for thread in threads:
            thread.join(10)
            self.assertFalse(thread.is_alive())
        self.assertCountEqual(results, [2260, 999999])

    def test_guild_progress_membership_initialization_and_departed_donations(self):
        gid = self.create()
        self.success(1, 2265, values=[1, 19])
        self.success(2, 2233, values=[gid])
        self.success(2, 2251, values=[2])
        other = self.store.path(2).read_bytes()
        members = self.business_rows(self.success(1, 2236))
        values = [protocol.pb_get_varint(v, 1) for n, w, v in protocol.iter_pb_fields(members[2]) if (n, w) == (1, 2)]
        self.assertEqual(values[4:6], [40000, 40000])
        self.assertEqual(self.store.path(2).read_bytes(), other)
        self.success(2, 2242)
        self.assertEqual(json.loads((self.root / "guilds.json").read_bytes())["guilds"][str(gid)]["experience"], 150000)
        self.success(1, 2260)
        self.clock.return_value += 86400
        ids = (2313, 4800, 6911, 3210, 7002, 2230, 2037, 2039, 6501, 6810)
        body = b"".join(protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, mid)) for mid in ids)
        status = self.business_rows(dict(protocol.get_comb_messages(self.success(1, 999900, raw=body)))[2230])
        self.assertEqual(protocol.parse_ids_pb(status[2])[3], 0)
        self.assertEqual(self.store.path(2).read_bytes(), other)

    def test_guild_max_level_uses_configured_daily_rewards_and_capacity(self):
        gid = self.create()
        path = self.root / "guilds.json"
        state = json.loads(path.read_bytes())
        state["guilds"][str(gid)]["experience"] = sum(row["gang_exp"] for row in CONFIG["gang2_level"].values()) + 300000
        path.write_text(json.dumps(state))
        status = self.business_rows(self.success(1, 2230))
        values = [protocol.pb_get_varint(v, 1) for n, w, v in protocol.iter_pb_fields(status[1]) if (n, w) == (1, 2)]
        self.assertEqual(values[2:4], [15, CONFIG["gang2_level"]["15"]["gang_exp"]])
        reward = self.success(1, 2260)
        props = next(v for n, w, v in protocol.iter_pb_fields(reward) if (n, w) == (5, 2))
        self.assertEqual({protocol.pb_get_varint(v, 1): protocol.pb_get_varint(v, 2)
                          for n, w, v in protocol.iter_pb_fields(props) if (n, w) == (1, 2)}, {20256: 170, 20199: 8, 20338: 8})
        self.success(1, 2265, values=[1, 19])
        with patch.dict(CONFIG["gang2_level"]["1"], people=1):
            self.success(2, 2233, values=[gid])

    def test_native_lua_callbacks_decode_guild_rows_and_charge_once(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("公会客户端回调验证需本机已有 lupa.lua51")
        if not (ROOT / "z7_7_4.apk").exists():
            self.skipTest("原始 APK 未提供")
        from build_local_apk import read_script
        lua = LuaRuntime()

        def decode(kind, raw):
            fields = list(protocol.iter_pb_fields(bytes.fromhex(raw)))
            if kind == "Ids":
                result = {"ids": [v for n, w, v in fields if (n, w) == (1, 0)]}
            elif kind == "Result":
                result = {"result": bool(dict((n, v) for n, w, v in fields)[1])}
            elif kind == "ParamS":
                result = {"params": [{"i" if w == 0 else "s": v if w == 0 else v.decode()
                                      for n, w, v in protocol.iter_pb_fields(value)} for _, _, value in fields]}
            elif kind == "CombMessages":
                result = {"messages": [{"id": mid, "data": body.hex()} for mid, body in self.business_rows(bytes.fromhex(raw)).items()]}
            elif kind == "SomeThings":
                props = next(v for n, w, v in fields if (n, w) == (5, 2))
                result = {"props": [{"cid": protocol.pb_get_varint(v, 1), "count": protocol.pb_get_varint(v, 2)}
                                     for n, w, v in protocol.iter_pb_fields(props) if (n, w) == (1, 2)]}
            else:
                self.assertEqual(kind, "Players")
                names = {1: "rid", 2: "name", 3: "level", 4: "vip", 5: "profile", 7: "param", 8: "params"}
                result = {"players": [{names[n]: decode("ParamS", v.hex()) if n == 8 else v.decode() if n == 2 else v
                                        for n, w, v in protocol.iter_pb_fields(value)} for _, _, value in fields]}
            return lua.table_from(result, recursive=True)

        lua.globals().decode = decode
        lua.execute('''
            print, printT, cclog = function() end, function() end, function() end
            for mod,kind in pairs({ids_pb="Ids",result_pb="Result",params_pb="ParamS",combmessages_pb="CombMessages",
                players_pb="Players",gangstatus_pb="GangStatus",gangbroadcasts_pb="GangBroadcasts",
                stringcontent_pb="StringContent",gangs_pb="Gangs",gangmembers_pb="GangMembers",somethings_pb="SomeThings"}) do
                local name=kind
                package.preload[mod]=function() return {[name]=function() return {
                    ParseFromString=function(self,raw) for k,v in pairs(decode(name,raw)) do self[k]=v end end} end} end
            end
            gamedata={ext={},cache={role={gold=10000,level=19},gang2status={}},
                config={global_kv={gang_establish_coin={value="1000"}}},sortData=function() end}
            function gamedata:updateRoleGold(value) self.cache.role.gold=self.cache.role.gold+value end
            function gamedata:updateRoleCoin(value) self.cache.role.coin=(self.cache.role.coin or 0)+value end
            function gamedata:SomethingProcess(value) return value end
            for _,mod in ipairs({"worldboss1_pb","worldboss1realnotify_pb","PickBattleResultReport"}) do
                package.preload[mod]=function() return {} end
            end
        ''')
        source = read_script("gamedata").decode()
        lua.execute(source[source.index("function gamedata.Gang2Status("):source.index("function gamedata.gangData(")])
        lua.execute(source[source.index("function gamedata.playerdata("):source.index("function gamedata.players(")])
        from build_local_apk import get_patched_lua_scripts, xxtea_decrypt, XXTEA_KEY
        with redirect_stdout(io.StringIO()):
            patched = get_patched_lua_scripts()
        raw = xxtea_decrypt(patched["assets/scripts/GameGang.so"], XXTEA_KEY)
        lua.execute(raw[:struct.unpack("<I", raw[-4:])[0]].decode())

        def callback(name, body):
            return lua.globals()[name](lua.table_from({"rbuf": body.hex()}))

        callback("NetUserGang2CallBack", self.success(1, 2230))
        self.assertIsNone(lua.globals().gamedata.cache.gang2status.id)
        packets = self.request(1, 2231, text="原生解析公会")
        self.assertEqual(callback("NetUserGang2CreateCallBack", packets[0][1]).result, 0)
        self.assertEqual(lua.globals().gamedata.cache.role.gold, protocol.pb_get_varint(packets[1][1], 9))
        gid = self.guild_id(1)
        callback("NetUserGang2CallBack", self.success(1, 2230))
        self.assertEqual(lua.globals().gamedata.cache.gang2status.id, gid)
        self.assertEqual(callback("NetUserGang2ListCallBack", self.success(2, 2232)).gangs[1].name, "原生解析公会")
        self.assertEqual(len(callback("NetUserGang2SearchCallBack", self.success(2, 2243, text="不存在")).gangs), 0)
        self.success(2, 2233, values=[gid])
        applicants = callback("NetUserGang2ReqQueryCallBack", self.success(1, 2234)).players
        self.assertEqual((applicants[1].rid, applicants[1].name, applicants[1].level), (1000002, "测试账号2", 19))
        self.success(1, 2235, values=[1000002, 0])
        result = callback("NetUserGang2MemberCallBack", self.success(1, 2236))
        self.assertEqual(len(result.gangmembers), 2)
        self.assertEqual(result.gangmembers[1].rid, result.gang2post.post1)
        self.assertEqual(result.gangmembers[2].rid, 1000002)
        lua.execute('gamedata.ext.gonghuipraymethod=2; gamedata.ext.gonghuinextgold=50; gamedata.ext.gonghuinextconin=0')
        packets = self.request(1, 2251, values=[2])
        result = callback("NetUserGang2PrayCallBack", packets[0][1])
        self.assertEqual((result.contribution, result.totalcontribution), (40000, 150000))
        self.assertEqual(lua.globals().gamedata.cache.role.gold, protocol.pb_get_varint(packets[1][1], 9))
        self.assertEqual(lua.globals().gamedata.cache.gang2status.totalcontribution, 40000)
        callback("NetUserGang2CallBack", self.success(1, 2230))
        self.assertEqual(lua.globals().gamedata.cache.gang2status.contribution, 40000)
        reward = callback("NetUserGang2DailyRewardCallBack", self.success(1, 2260)).reward
        self.assertEqual([(reward.props[i].cid, reward.props[i].count) for i in (1, 2)], [(20256, 20), (20197, 2)])
        self.assertEqual(lua.globals().gamedata.cache.gang2status.rewardstatus, 1)
        self.success(2, 2242)
        self.success(1, 2266)
        callback("NetUserGang2CallBack", self.success(1, 2230))
        self.assertIsNone(lua.globals().gamedata.cache.gang2status.id)


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


class GmManagementTests(AdminFixture):
    def setUp(self):
        super().setUp()
        self.save()
        save = self.store.snapshot(1)["save"]
        save["guide"]["sections"]["1"].update(status=2, step=COUNTS[1])
        player.save_role(save, self.store.path(1), COUNTS)
        self.gm = gm.Workbench(self.store)

    def request(self, action, **values):
        return {"operation_id": uuid.uuid4().hex, "revision": self.store.snapshot(1)["revision"],
                "reason": "管理测试", "action": action, **values}

    def detail(self):
        return views.detail(self.store.snapshot(1), COUNTS, CONFIG)

    def test_inventory_set_and_clear_preserve_fragment_identity_and_reconnect(self):
        before = self.detail()
        fragment = next(r for r in before["inventory"] if r["kind"] == "武将碎片")
        self.assertNotEqual(fragment["item_id"], fragment["cid"])
        for cid, count in ((20014, 12), (20014, 2), (fragment["item_id"], 7)):
            result = self.gm.apply(1, self.request("inventory", cid=cid, count=count))
            self.assertEqual(result["status"], "success")
            self.assertEqual(next(r["count"] for r in self.detail()["inventory"] if r["item_id"] == cid), count)
        self.assertEqual(self.detail()["generals"], before["generals"])
        request = self.request("inventory", cid=fragment["item_id"], count=0)
        result = self.gm.apply(1, request)
        self.assertIn({"name": fragment["name"], "cid": fragment["cid"], "iid": None, "before": 7, "after": 0}, result["changes"])
        saved = self.store.path(1).read_bytes()
        self.assertEqual(gm.Workbench(self.store).apply(1, request)["status"], "success")
        self.assertEqual(self.store.path(1).read_bytes(), saved)
        session = Session(TABLES, self.store.path(1), COUNTS, CONFIG)
        self.assertEqual(session.save["world_state"]["1012"], "")
        self.assertEqual(self.gm.history(action="inventory")["total"], 4)

    def test_upgrade_syncs_protagonist_power_and_snapshots_without_spending(self):
        before = self.detail()
        hero = next(r for r in before["generals"] if r["protagonist"])
        request = self.request("general-level", iid=hero["iid"], level=hero["level"] + 2)
        result = self.gm.apply(1, request)
        after = self.detail()
        grown = next(r for r in after["generals"] if r["iid"] == hero["iid"])
        self.assertEqual(grown["level"], hero["level"] + 2)
        self.assertEqual(grown["exp"], 0)
        self.assertGreater(grown["atk"], hero["atk"])
        self.assertEqual(grown["potential"], hero["potential"])
        self.assertEqual(after["power"] - before["power"], grown["power"] - hero["power"])
        self.assertEqual(after["inventory"], before["inventory"])
        for key in ("gold", "coin", "vip"):
            self.assertEqual(after[key], before[key])
        session = Session(TABLES, self.store.path(1), COUNTS, CONFIG)
        protagonist = bytes.fromhex(session.save["protagonist_snapshot"])
        world = bytes.fromhex(session.save["world_state"]["1002"])
        self.assertEqual(protocol.pb_get_varint(protagonist, 2), grown["level"])
        self.assertEqual(next(v for n, w, v in protocol.iter_pb_fields(protagonist) if n == 10), formation.records(world, 1, 2)[hero["iid"]])
        self.assertEqual(next(v for n, w, v in protocol.iter_pb_fields(world) if n == 6), protagonist)
        self.assertTrue(any(r["name"].endswith("等级") and r["after"] == grown["level"] for r in result["changes"]))
        saved = self.store.path(1).read_bytes()
        self.gm.apply(1, request)
        self.assertEqual(self.store.path(1).read_bytes(), saved)

    def test_idle_growth_and_formation_round_trip_keep_training_equipment_and_relations(self):
        before = self.detail()
        idle = next(r for r in before["generals"] if not r["position"])
        active = next(r for r in before["generals"] if r["position"] == 2)
        self.gm.apply(1, self.request("general-level", iid=idle["iid"], level=6))
        self.assertEqual(self.detail()["power"], before["power"])
        self.assertGreater(next(r for r in self.detail()["generals"] if r["iid"] == idle["iid"])["potential"], idle["potential"])
        self.gm.apply(1, self.request("general-level", iid=active["iid"], level=8))
        grown = self.detail()
        world = bytes.fromhex(self.store.snapshot(1)["save"]["world_state"]["1002"])
        previous_slot = formation.records(world, 4, 1)[2]
        result = self.gm.apply(1, self.request("formation", iid=idle["iid"], position=2))
        after = self.detail()
        self.assertIsNone(next(r for r in after["generals"] if r["iid"] == active["iid"])["position"])
        self.assertEqual(next(r for r in after["generals"] if r["iid"] == idle["iid"])["position"], 2)
        current_slot = formation.records(bytes.fromhex(self.store.snapshot(1)["save"]["world_state"]["1002"]), 4, 1)[2]
        self.assertEqual([protocol.pb_get_varint(previous_slot, n) for n in range(4, 10)],
                         [protocol.pb_get_varint(current_slot, n) for n in range(4, 10)])
        self.assertTrue(any(r["name"].endswith("阵位") for r in result["changes"]))
        self.gm.apply(1, self.request("formation", iid=active["iid"], position=2))
        restored = self.detail()
        self.assertEqual(restored["generals"], grown["generals"])
        self.assertEqual(restored["equipment"], before["equipment"])
        self.assertEqual(restored["power"], sum(r["power"] for r in restored["generals"] if r["position"]))
        self.gm.apply(1, self.request("formation", iid=active["iid"], position=0))
        self.assertIsNone(next(r for r in self.detail()["generals"] if r["iid"] == active["iid"])["position"])

    def test_remove_idle_general_and_restore_do_not_reapply_old_request(self):
        before = self.detail()
        idle = next(r for r in before["generals"] if not r["position"])
        request = self.request("remove-general", iid=idle["iid"])
        result = self.gm.apply(1, request)
        after = self.detail()
        self.assertEqual(after["generals"], [r for r in before["generals"] if r["iid"] != idle["iid"]])
        self.assertEqual(after["inventory"], before["inventory"])
        self.assertEqual(after["equipment"], before["equipment"])
        self.assertEqual(after["power"], before["power"])
        self.assertTrue(any(r.get("iid") == idle["iid"] and r["after"] == 0 for r in result["changes"]))
        session = Session(TABLES, self.store.path(1), COUNTS, CONFIG)
        self.assertNotIn(idle["iid"], formation.records(bytes.fromhex(session.save["world_state"]["1002"]), 1, 2))
        self.store.maintain(1, "restore", self.store.snapshot(1)["revision"], result["backup_id"])
        restored = self.store.path(1).read_bytes()
        self.assertEqual(gm.Workbench(self.store).apply(1, request)["status"], "success")
        self.assertEqual(self.store.path(1).read_bytes(), restored)
        self.assertEqual(self.detail()["generals"], before["generals"])

    def test_invalid_management_actions_never_change_save(self):
        before = self.store.path(1).read_bytes()
        invalid = [("inventory", {"cid": 20014, "count": -1}), ("inventory", {"cid": 20014, "count": True}),
                   ("inventory", {"cid": 20014, "count": 1 << 31}), ("inventory", {"cid": 20014, "count": 0}),
                   ("inventory", {"cid": 10213, "count": 1}), ("inventory", {"cid": 22204, "count": 1}),
                   ("inventory", {"cid": 20014, "count": 1, "extra": 0}), ("inventory", {"cid": 20014}),
                   ("general-level", {"iid": 7060, "level": 13}), ("general-level", {"iid": 7060, "level": 4}),
                   ("general-level", {"iid": 7060, "level": 5.5}), ("general-level", {"iid": 999, "level": 6}),
                   ("formation", {"iid": 7059, "position": 0}), ("formation", {"iid": 7060, "position": 4}),
                   ("formation", {"iid": 7060, "position": 8}), ("formation", {"iid": 7061, "position": 0}),
                   ("remove-general", {"iid": 7059}), ("remove-general", {"iid": 7060}), ("remove-general", {"iid": True}),
                   ("unknown", {}), ([], {})]
        for action, values in invalid:
            with self.subTest(action=action, values=values), self.assertRaises(ValueError):
                self.gm.apply(1, self.request(action, **values))
            self.assertEqual(self.store.path(1).read_bytes(), before)
        self.assertEqual(self.store.backups(1), [])

    def test_new_actions_share_offline_revision_backup_and_save_guards(self):
        before = self.store.path(1).read_bytes()
        actions = [("inventory", {"cid": 20100, "count": 2}), ("general-level", {"iid": 7060, "level": 6}),
                   ("formation", {"iid": 7061, "position": 2}), ("remove-general", {"iid": 7061})]
        for action, values in actions:
            with self.subTest(action=action):
                self.store.active[1] = {"address": "phone", "connected_at": 1}
                with self.assertRaisesRegex(ValueError, "在线"):
                    self.gm.apply(1, self.request(action, **values))
                self.store.close_session(1)
                with self.assertRaisesRegex(ValueError, "变化"):
                    self.gm.apply(1, {**self.request(action, **values), "revision": "0" * 64})
                with patch.object(storage, "backup", side_effect=OSError("full")), self.assertRaises(OSError):
                    self.gm.apply(1, self.request(action, **values))
                with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
                    self.gm.apply(1, self.request(action, **values))
                self.assertEqual(self.store.path(1).read_bytes(), before)

    def test_new_action_receipts_recover_missing_final_journal_before_next_write(self):
        write = self.gm._write
        def fail_success(row):
            if row["status"] == "success" and row["id"] == request["operation_id"]:
                raise OSError("log full")
            write(row)
        requests = []
        for action, values in [("inventory", {"cid": 20100, "count": 2}), ("general-level", {"iid": 7060, "level": 6}),
                               ("formation", {"iid": 7061, "position": 2}), ("remove-general", {"iid": 7060})]:
            request = self.request(action, **values)
            with patch.object(self.gm, "_write", side_effect=fail_success):
                self.assertIn("audit_warning", self.gm.apply(1, request))
            saved = self.store.path(1).read_bytes()
            self.assertEqual(gm.Workbench(self.store).apply(1, request)["status"], "success")
            self.assertEqual(self.store.path(1).read_bytes(), saved)
            requests.append(request)
        self.assertTrue(all(r["status"] == "success" for r in self.gm.history()["rows"]))
        for request in requests:
            self.assertEqual(gm.Workbench(self.store).apply(1, request)["status"], "success")

    def test_tutorial_advanced_and_cheer_generals_are_rejected(self):
        original = copy.deepcopy(self.store.snapshot(1)["save"])
        for variant in ("guide", "advanced", "cheer"):
            save = copy.deepcopy(original)
            if variant == "guide":
                save["guide"]["sections"]["1"].update(status=1, step=30, steps=list(range(1, 31)))
            elif variant == "advanced":
                world = bytes.fromhex(save["world_state"]["1002"])
                raw = protocol.pb_set_varint(formation.records(world, 1, 2)[7061], 21, 1)
                player.record_slot_update(save, protocol.encode_pb_field(1, 2, raw))
            else:
                slot = protocol.encode_pb_field(1, 0, 1) + protocol.encode_pb_field(2, 0, 7061)
                player.record_slot_update(save, protocol.encode_pb_field(5, 2, slot))
            player.save_role(save, self.store.path(1), COUNTS)
            before = self.store.path(1).read_bytes()
            for action, values in (("general-level", {"level": 8}), ("formation", {"position": 2}), ("remove-general", {})):
                with self.subTest(variant=variant, action=action), self.assertRaises(ValueError):
                    self.gm.apply(1, self.request(action, iid=7061, **values))
                self.assertEqual(self.store.path(1).read_bytes(), before)


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
        common = self.request("/api/status")[2]["common_items"]
        self.assertIn(20100, [row["cid"] for row in common])
        self.assertTrue(all(row["name"] == CONFIG["props"][str(row["cid"])]["name"] for row in common))
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
        self.assertEqual({row["id"] for row in data["business"]["activities"] if row["id"] < 100},
                         {1, 3, 7, 8, 9, 11, 14, 16, 23, 37, 48})
        self.assertEqual(data["business"]["recharge"]["rmb"], SAVE["recharge_state"]["rmb"])
        self.assertTrue(data["copies"][0]["points"])
        self.assertEqual(data["general_level_cap"], 12)
        self.assertEqual(data["slot_limit"], 3)
        self.assertTrue(next(row for row in data["generals"] if row["iid"] == 7059)["protagonist"])
        self.assertEqual(next(row for row in data["inventory"] if row["cid"] == 10204)["item_id"], 11204)
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

    def test_gm_mail_http_endpoints_send_list_and_delete(self):
        # 1. 初始邮件列表为空
        code, _, list_res = self.request("/api/mails")
        self.assertEqual(code, 200)
        self.assertEqual(list_res["total"], 0)

        # 2. 发送邮件到指定账号 1，包含金币、体力、道具和充值
        payload1 = {
            "target": 1,
            "title": "测试个人补偿",
            "content": "补偿内容说明",
            "resources": {"gold": 1000, "coin": 50000, "stamina": 30},
            "items": [{"cid": 20014, "count": 5}],
            "recharge": {"rmb": 648, "gold": 6480, "card": 0},
            "reason": "测试账号1补发充值与资源"
        }
        code, _, res1 = self.request("/api/mails", payload1)
        self.assertEqual(code, 200)
        self.assertEqual(res1["title"], "测试个人补偿")
        self.assertEqual(res1["target"], 1)
        self.assertEqual(res1["recharge_rmb"], 648)
        self.assertEqual(res1["attachments"]["1008"], 648)
        self.assertEqual(res1["attachments"]["1001"], 7480) # 1000 + 6480
        self.assertEqual(res1["attachments"]["20014"], 5)
        mail1_id = res1["id"]

        # 3. 发送全服邮件 (target = 'all' 或 0)
        payload2 = {
            "target": "all",
            "title": "全服狂欢礼包",
            "content": "全服人人有份",
            "resources": {"gold": 2000},
            "items": [],
            "recharge": {"card": 1},
            "reason": "测试全服发放月卡"
        }
        code, _, res2 = self.request("/api/mails", payload2)
        self.assertEqual(code, 200)
        self.assertEqual(res2["target"], 0)
        self.assertEqual(res2["card"], 1)
        self.assertEqual(res2["recharge_rmb"], 25)
        mail2_id = res2["id"]

        # 4. 获取邮件列表并测试筛选与分页
        code, _, list_res = self.request("/api/mails")
        self.assertEqual(code, 200)
        self.assertEqual(list_res["total"], 2)
        self.assertEqual([m["id"] for m in list_res["rows"]], [mail2_id, mail1_id])

        # 按账号筛选
        code, _, filter_res = self.request("/api/mails?account=1")
        self.assertEqual(filter_res["total"], 2) # 全服邮件 (0) + 账号 1
        code, _, filter_res2 = self.request("/api/mails?account=2")
        self.assertEqual(filter_res2["total"], 1) # 仅全服邮件 (0)

        # 5. 校验非法邮件参数拦截
        self.assertEqual(self.request("/api/mails", {"title": "", "target": 1})[0], 400)
        self.assertEqual(self.request("/api/mails", {"title": "有效标题", "target": 9999})[0], 400)

        # 6. 删除/撤回邮件
        code, _, del_res = self.request(f"/api/mails/{mail1_id}/delete", {"reason": "撤回个人邮件"})
        self.assertEqual(code, 200)
        self.assertTrue(del_res["deleted"])

        # 再次查询确认已删除
        code, _, list_res2 = self.request("/api/mails")
        self.assertEqual(list_res2["total"], 1)
        self.assertEqual(list_res2["rows"][0]["id"], mail2_id)

        # 7. 确认操作流水中有 mail 和 mail-delete 记录
        operations = self.request("/api/operations")[2]["rows"]
        actions = [op["action"] for op in operations]
        self.assertIn("mail", actions)
        self.assertIn("mail-delete", actions)

    def test_gm_mail_game_protocol_query_claim_recharge_and_delete(self):
        # 准备账号 1 和账号 2
        self.save(1)
        self.save(2)

        # GM 发送全服邮件包含 500 元宝和 68 元充值 (680元宝+68VIP经验)
        self.request("/api/mails", {
            "target": "all",
            "title": "全服充值福利",
            "content": "祝大家游戏愉快",
            "resources": {"gold": 500},
            "recharge": {"rmb": 68, "gold": 680},
            "reason": "测试全服充值"
        })

        # GM 发送指定账号 1 的专属月卡邮件
        self.request("/api/mails", {
            "target": 1,
            "title": "专属月卡体验",
            "content": "专属月卡已送达",
            "recharge": {"card": 1},
            "items": [{"cid": 20014, "count": 10}],
            "reason": "测试账号1月卡与招募令"
        })

        # 模拟账号 1 客户端登录并与服务端通信
        self.store.register(1, PASSWORD, self.store.snapshot(1)["revision"])
        session = self.store.open_session(1, PASSWORD, ("127.0.0.1", 12345))
        try:
            # 1. 客户端请求 3100 邮件列表
            packets = session.handle(3100, 1, b"")
            self.assertEqual(len(packets), 1)
            magic, plen, opcode, seq = struct.unpack(">IIII", packets[0][:16])
            self.assertEqual(opcode, 3100)
            body = packets[0][16:]
            fields = list(protocol.iter_pb_fields(body))
            # 账号 1 应该收到两封邮件（全服邮件 + 个人月卡邮件）
            self.assertEqual(len([f for f in fields if f[0] == 2]), 2)

            mail_ids = []
            for _, _, raw_mail in [f for f in fields if f[0] == 2]:
                m_fields = dict((n, v) for n, w, v in protocol.iter_pb_fields(raw_mail))
                mid = m_fields[1]
                mail_ids.append(mid)
                status = m_fields[4]
                self.assertEqual(status, 0) # 未领取

            self.assertEqual(len(mail_ids), 2)
            personal_mid = max(mail_ids)
            global_mid = min(mail_ids)

            # 2. 未领取有附件的邮件，删除应被拒绝 (999999)
            del_packet = session.handle(3102, 2, protocol.encode_pb_field(1, 0, personal_mid))
            self.assertEqual(struct.unpack(">IIII", del_packet[0][:16])[2], 999999)

            # 3. 领取账号 1 的个人邮件 (月卡 + 10个招募令)
            before_gold = session.save["role_state"]["gold"]
            claim_packet = session.handle(3101, 3, protocol.encode_pb_field(1, 0, personal_mid))
            self.assertEqual(struct.unpack(">IIII", claim_packet[0][:16])[2], 3101)

            # 验证月卡效果与物品到账
            rstate = recharge.get_state(session.save)
            self.assertTrue(rstate["month_until"] > 0)
            self.assertEqual(rstate["card_rmb"], 25)
            self.assertEqual(rstate["rmb"], 25)
            self.assertEqual(session.save["role_state"]["vip"], recharge.vip(rstate, CONFIG))
            self.assertEqual(session.save["role_state"]["gold"], before_gold + 250)
            # 验证招募令到账
            props_1200 = session.save["world_state"]["1200"]
            token_count = next(protocol.pb_get_varint(v, 2) for n, w, v in protocol.iter_pb_fields(bytes.fromhex(props_1200))
                               if n == 1 and w == 2 and protocol.pb_get_varint(v, 1) == 20014)
            self.assertEqual(token_count, 10)

            # 4. 重复领取应被拒绝 (999999)
            dup_packet = session.handle(3101, 4, protocol.encode_pb_field(1, 0, personal_mid))
            self.assertEqual(struct.unpack(">IIII", dup_packet[0][:16])[2], 999999)

            # 5. 领取全服邮件 (68元充值 + 500+680元宝)
            claim2_packet = session.handle(3101, 5, protocol.encode_pb_field(1, 0, global_mid))
            self.assertEqual(struct.unpack(">IIII", claim2_packet[0][:16])[2], 3101)
            self.assertEqual(session.save["recharge_state"]["rmb"], 25 + 68)
            self.assertEqual(session.save["role_state"]["vip"], recharge.vip(session.save["recharge_state"], CONFIG))
            self.assertEqual(session.save["role_state"]["gold"], before_gold + 250 + 1180)

            # 6. 删除已领取的邮件
            del_packet2 = session.handle(3102, 6, protocol.encode_pb_field(1, 0, personal_mid))
            self.assertEqual(struct.unpack(">IIII", del_packet2[0][:16])[2], 3102)

            # 再次查询 3100，个人邮件已不在列表中，全服邮件状态为已领取 (status=2)
            packets2 = session.handle(3100, 7, b"")
            remaining_mails = [f for f in protocol.iter_pb_fields(packets2[0][16:]) if f[0] == 2]
            self.assertEqual(len(remaining_mails), 1)
            remaining_fields = dict((n, v) for n, w, v in protocol.iter_pb_fields(remaining_mails[0][2]))
            self.assertEqual(remaining_fields[1], global_mid)
            self.assertEqual(remaining_fields[4], 2) # status=2 (已领取)
        finally:
            self.store.close_session(1)

        # 模拟账号 2 客户端登录
        self.store.register(2, PASSWORD, self.store.snapshot(2)["revision"])
        session2 = self.store.open_session(2, PASSWORD, ("127.0.0.1", 12346))
        try:
            # 账号 2 只能收到全服邮件，收不到账号 1 的专属月卡邮件
            packets = session2.handle(3100, 1, b"")
            mails_acc2 = [f for f in protocol.iter_pb_fields(packets[0][16:]) if f[0] == 2]
            self.assertEqual(len(mails_acc2), 1)
            # 测试一键全部领取 (ids = [-1])
            all_claim_body = protocol.encode_pb_field(1, 0, (1 << 64) - 1)
            all_claim_packet = session2.handle(3101, 2, all_claim_body)
            self.assertEqual(struct.unpack(">IIII", all_claim_packet[0][:16])[2], 3101)
            self.assertEqual(session2.save["recharge_state"]["rmb"], 68)

            # 测试一键全部删除 (ids = [-1])
            all_del_packet = session2.handle(3102, 3, all_claim_body)
            self.assertEqual(struct.unpack(">IIII", all_del_packet[0][:16])[2], 3102)

            # 再次查询，邮件箱已空
            self.assertEqual(session2.handle(3100, 4, b"")[0][16:], b"")
        finally:
            self.store.close_session(2)


class DatabaseHybridJsonTests(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.root = Path(self.temp_dir)
        self.db_path = self.root / "zyj.db"

    def tearDown(self):
        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def test_sqlite_hybrid_json_player_save_load_and_indexing(self):
        from zyj_server import db
        db.init_db(self.db_path)

        p1 = {
            "role_name": "玩家甲", "has_role": True, "level": 30,
            "role_state": {"level": 30, "power": 300000, "vip": 5, "coin": 50000, "gold": 1000},
            "created_at": 1700000000, "last_login": 1700005000
        }
        p2 = {
            "role_name": "玩家乙", "has_role": True, "level": 50,
            "role_state": {"level": 50, "power": 800000, "vip": 8, "coin": 90000, "gold": 5000},
            "created_at": 1700001000, "last_login": 1700006000
        }
        db.save_player(self.db_path, 1, p1)
        db.save_player(self.db_path, 2, p2)

        # 验证读取完整存档
        loaded1 = db.load_player(self.db_path, 1)
        self.assertEqual(loaded1["role_name"], "玩家甲")
        self.assertEqual(loaded1["role_state"]["power"], 300000)

        # 验证轻量索引摘要
        summary = db.get_player_summary(self.db_path, 2)
        self.assertEqual(summary["level"], 50)
        self.assertEqual(summary["power"], 800000)
        self.assertEqual(summary["vip"], 8)

        # 验证按战力排名查询 (B-Tree 索引)
        top_power = db.list_top_players(self.db_path, "power", 10)
        self.assertEqual(len(top_power), 2)
        self.assertEqual(top_power[0]["account_id"], 2)
        self.assertEqual(top_power[1]["account_id"], 1)

        # 验证按等级排名查询
        top_level = db.list_top_players(self.db_path, "level", 10)
        self.assertEqual(top_level[0]["account_id"], 2)

        # 验证删除
        db.delete_player(self.db_path, 1)
        self.assertIsNone(db.load_player(self.db_path, 1))

    def test_sqlite_credentials_and_mails_persistence(self):
        from zyj_server import db
        db.init_db(self.db_path)

        # 凭据存储测试
        cred = {"algorithm": "pbkdf2_sha256", "iterations": 600000, "salt": "11"*16, "hash": "22"*32}
        db.save_credentials(self.db_path, 5, cred)
        self.assertTrue(db.has_credentials(self.db_path, 5))
        self.assertFalse(db.has_credentials(self.db_path, 6))
        self.assertEqual(db.load_credentials(self.db_path, 5)["salt"], "11"*16)

        # 邮件存储测试
        m1 = {"id": 800000001, "target": 0, "title": "全服通告", "content": "内容", "attachments": {"1001": 100}, "created_at": 100}
        m2 = {"id": 800000002, "target": 5, "title": "专属奖励", "content": "奖励", "attachments": {"1000": 500}, "created_at": 200}
        db.save_mail(self.db_path, m1)
        db.save_mail(self.db_path, m2)

        # 账号 5 可查到 m1 和 m2
        res5 = db.list_mails(self.db_path, 5)
        self.assertEqual(res5["total"], 2)
        self.assertEqual(res5["rows"][0]["id"], 800000002)

        # 账号 1 只能查到全服邮件 m1
        res1 = db.list_mails(self.db_path, 1)
        self.assertEqual(res1["total"], 1)
        self.assertEqual(res1["rows"][0]["id"], 800000001)

        # 删除邮件
        self.assertTrue(db.delete_mail(self.db_path, 800000001))
        self.assertEqual(db.list_mails(self.db_path, 1)["total"], 0)

    def test_sqlite_migration_from_disk_files(self):
        from zyj_server import db
        # 1. 预先在磁盘写入 JSON 文件
        p1 = {"role_name": "磁盘老角色", "has_role": True, "level": 15, "role_state": {"level": 15, "power": 88888}}
        (self.root / "role_save.json").write_text(json.dumps(p1), encoding="utf-8")

        acc2_dir = self.root / "accounts" / "2"
        acc2_dir.mkdir(parents=True)
        p2 = {"role_name": "二号角色", "has_role": True, "level": 20, "role_state": {"level": 20, "power": 120000}}
        (acc2_dir / "role_save.json").write_text(json.dumps(p2), encoding="utf-8")
        (acc2_dir / "credentials.json").write_text(json.dumps({
            "algorithm": "pbkdf2_sha256", "iterations": 600000, "salt": "aa"*16, "hash": "bb"*32
        }), encoding="utf-8")

        # 2. 调用 init_db 并指定 base_dir 触发自动迁移
        db.init_db(self.db_path, self.root)

        # 3. 验证数据已成功导入 SQLite
        loaded1 = db.load_player(self.db_path, 1)
        self.assertIsNotNone(loaded1)
        self.assertEqual(loaded1["role_name"], "磁盘老角色")

        loaded2 = db.load_player(self.db_path, 2)
        self.assertIsNotNone(loaded2)
        self.assertEqual(loaded2["role_name"], "二号角色")

        cred2 = db.load_credentials(self.db_path, 2)
        self.assertIsNotNone(cred2)
        self.assertEqual(cred2["hash"], "bb"*32)


if __name__ == "__main__":
    unittest.main()
