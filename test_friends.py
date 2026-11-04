"""真实本地好友：临时多账号、原生PB/Lua，不操作正式角色。"""

from contextlib import redirect_stdout
import copy
import io
import json
from pathlib import Path
import struct
import tempfile
import threading
import unittest
import zipfile
from unittest.mock import patch

import build_local_apk as builder
import test_guild
from zyj_server import accounts, formation, friends, guild, player, protocol, storage


def setUpModule():
    test_guild.setUpModule()


class FriendsTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        self.now = 1793430000
        self.clock = patch("time.time", return_value=self.now).start()
        self.addCleanup(patch.stopall)
        quiet = redirect_stdout(io.StringIO())
        quiet.__enter__()
        self.addCleanup(quiet.__exit__, None, None, None)
        self.config = copy.deepcopy(test_guild.CONFIG)
        self.store = accounts.AccountStore(self.root / "role_save.json", test_guild.TABLES, test_guild.COUNTS, self.config)
        patch.object(self.store, "authenticate", return_value=None).start()
        self.sessions, self.seq = {}, 50000
        for account in (1, 2, 3):
            self.add_account(account)

    def add_account(self, account):
        save = copy.deepcopy(test_guild.SAVE)
        save.update(created_at=self.now - 10 * 86400 + account, role_name=f"好友测试{account}")
        save["role_state"].update(level=31, vip=0)
        save["guide"]["sections"]["1"]["status"] = 2
        player.save_role(save, self.store.path(account), test_guild.COUNTS)
        self.sessions[account] = self.store.open_session(account, "test-password", ("same-address", account))
        self.addCleanup(self.store.close_session, account)

    def request(self, account, opcode, values=(), raw=None):
        self.seq += 1
        return [(struct.unpack(">IIII", p[:16])[2], p[16:]) for p in self.sessions[account].handle(
            opcode, self.seq, guild.ids(values) if raw is None else raw)]

    def success(self, account, opcode, **kwargs):
        packets = self.request(account, opcode, **kwargs)
        self.assertEqual(packets[0][0], opcode, packets)
        return packets[0][1]

    def shared(self):
        return json.loads((self.root / "friends.json").read_bytes())

    def records(self, body, field=1):
        return [v for n, w, v in protocol.iter_pb_fields(body) if (n, w) == (field, 2)]

    def groups(self, body):
        return {protocol.pb_get_varint(row, 1): next(v for n, w, v in protocol.iter_pb_fields(row) if (n, w) == (2, 2))
                for row in self.records(body)}

    def friends(self, account=1):
        body = self.success(account, 2300)
        return {protocol.pb_get_varint(v, 1): v for v in self.records(body)}, protocol.pb_get_varint(body, 2)

    def befriend(self, sender=1, receiver=2):
        self.assertEqual(protocol.parse_ids_pb(self.success(sender, 2302, values=[1000000 + receiver])), [0])
        self.success(receiver, 2304, values=[1000000 + sender, 1])

    def reconnect(self, account=1):
        self.store.close_session(account)
        self.sessions[account] = self.store.open_session(account, "test-password", ("same-address", account))

    def assert_rejected(self, account, opcode, **kwargs):
        before = copy.deepcopy(self.sessions[account].save)
        disk = {a: self.store.path(a).read_bytes() for a in self.sessions}
        path = self.root / "friends.json"
        shared = path.read_bytes() if path.exists() else None
        packets = self.request(account, opcode, **kwargs)
        self.assertEqual([mid for mid, _ in packets], [999999, 1999])
        self.assertEqual(self.sessions[account].save, before)
        self.assertEqual({a: self.store.path(a).read_bytes() for a in self.sessions}, disk)
        self.assertEqual(path.read_bytes() if path.exists() else None, shared)

    def chat(self, account=1, target=2, text="你好"):
        body = protocol.encode_pb_field(2, 2, protocol.encode_pb_field(1, 0, 1000000 + target)
            + protocol.encode_pb_field(2, 2, text.encode()))
        return self.success(account, 2306, raw=body)

    def chat_query(self, account=1, target=2, new=0):
        return self.success(account, 2305, raw=protocol.encode_pb_field(1, 0, 1000000 + target)
                            + protocol.encode_pb_field(2, 0, new))

    def test_real_recommendations_search_identity_and_read_only_role_snapshots(self):
        disk = {a: self.store.path(a).read_bytes() for a in self.sessions}
        rows = self.groups(self.success(1, 2301))
        self.assertEqual({protocol.pb_get_varint(v, 1) for v in self.records(rows[1])}, {1000002, 1000003})
        self.assertEqual(self.friends(), ({}, 0))
        for account in (1, 2):
            self.assertEqual(protocol.pb_get_varint(self.success(account, 2300), 3), 1000000 + account)
        found = self.records(self.success(1, 2307, values=[1000002]))
        self.assertEqual(protocol.pb_get_varint(found[0], 1), 1000002)
        self.assertEqual(self.success(1, 2307, values=[1000999]), b"")
        self.assertEqual({a: self.store.path(a).read_bytes() for a in self.sessions}, disk)
        self.assertNotIn("66", self.sessions[1].save["guide"]["sections"])

    def test_new_selected_role_queries_before_first_role_snapshot_are_empty_and_readonly(self):
        session = self.sessions[1]
        session.save.pop("role_snapshot")
        session.save["role_state"]["level"] = 1
        player.save_role(session.save, self.store.path(1), test_guild.COUNTS)
        before, disk = copy.deepcopy(session.save), self.store.path(1).read_bytes()
        body = self.success(1, 2300)
        self.assertEqual((self.records(body), protocol.pb_get_varint(body, 2), protocol.pb_get_varint(body, 3)), ([], 0, 1000001))
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 2313)), [0])
        self.assertEqual((session.save, self.store.path(1).read_bytes()), (before, disk))
        self.assertFalse((self.root / "friends.json").exists())
        self.assert_rejected(1, 2302, values=[1000002])
        session.save["has_role"] = False
        player.save_role(session.save, self.store.path(1), test_guild.COUNTS)
        before = self.store.path(1).read_bytes()
        self.assertEqual(protocol.pb_get_varint(self.success(1, 2300), 3), 1000001)
        self.assertEqual(self.store.path(1).read_bytes(), before)
        self.assertFalse((self.root / "friends.json").exists())

    def test_apply_accept_reject_delete_and_reconnect_are_real_bilateral_relations(self):
        self.success(1, 2302, values=[1000002])
        self.assertEqual(self.friends(1)[0], {})
        pending = self.records(self.success(2, 2303))
        self.assertEqual([protocol.pb_get_varint(v, 1) for v in pending], [1000001])
        self.success(2, 2304, values=[1000001, 2])
        self.assertEqual(self.success(2, 2303), b"")
        self.befriend()
        self.reconnect(1)
        self.reconnect(2)
        self.assertEqual(set(self.friends(1)[0]), {1000002})
        self.assertEqual(set(self.friends(2)[0]), {1000001})
        self.success(1, 2310, values=[1000002])
        self.assertEqual((self.friends(1)[0], self.friends(2)[0]), ({}, {}))

    def test_bulk_applications_accepts_and_rejections_respect_both_vip_capacities(self):
        for row in self.config["vip"].values():
            row["friend"] = 1
        self.success(1, 6038)
        self.assertEqual(len(self.records(self.success(2, 2303))), 1)
        self.success(3, 2302, values=[1000002])
        self.success(2, 2311, values=[1])
        self.assertEqual(set(self.friends(2)[0]), {1000001})
        self.assertEqual(self.friends(3)[0], {})
        self.success(2, 2311, values=[2])
        self.assertEqual(self.success(2, 2303), b"")
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 2302, values=[1000003])), [1001])
        self.assertEqual(protocol.parse_ids_pb(self.success(3, 2302, values=[1000002])), [1002])

    def test_blocks_are_private_prevent_apply_chat_and_require_unfriend_first(self):
        self.success(1, 3003, values=[1000002])
        rows = self.groups(self.success(1, 3002, values=[0]))
        self.assertEqual(protocol.parse_ids_pb(rows[0]), [1, 0, 1])
        self.assertEqual(protocol.pb_get_varint(self.records(rows[1])[0], 1), 1000002)
        self.assert_rejected(2, 2302, values=[1000001])
        self.success(1, 3004, values=[1000002])
        self.befriend()
        self.assert_rejected(1, 3003, values=[1000002])
        self.success(1, 2310, values=[1000002])
        self.success(1, 3003, values=[1000002])
        self.assert_rejected(2, 1022, values=[1000001])

    def test_gifts_add_configured_energy_once_and_delete_readd_cannot_repeat(self):
        self.befriend()
        before = self.sessions[2].save["role_state"]["energy"]
        self.success(1, 2308, values=[1000002])
        rows, count = self.friends(2)
        self.assertEqual((protocol.pb_get_varint(rows[1000001], 6), count), (1, 0))
        packets = self.request(2, 2309, values=[1000001])
        self.assertEqual([mid for mid, _ in packets][:2], [2309, 1001])
        self.assertEqual(self.sessions[2].save["role_state"]["energy"], before + 1)
        self.assertEqual(self.friends(2)[1], 1)
        self.assert_rejected(2, 2309, values=[1000001])
        self.success(1, 2310, values=[1000002])
        self.befriend()
        self.success(1, 2308, values=[1000002])
        self.assert_rejected(2, 2309, values=[1000001])
        self.reconnect(2)
        self.assertEqual(self.friends(2)[1], 1)

    def test_all_gifts_clip_to_daily_limit_and_flags_keep_actual_partial_results(self):
        self.config["global_kv"]["friend_reward_times"]["value"] = "1"
        self.befriend(1, 2)
        self.befriend(3, 2)
        self.success(1, 2308)
        self.success(3, 2308)
        self.success(2, 2309)
        rows, count = self.friends(2)
        self.assertEqual(count, 1)
        self.assertEqual([protocol.pb_get_varint(rows[rid], 6) for rid in sorted(rows)], [2, 1])
        self.assert_rejected(2, 2309)

    def test_forward_day_and_rollback_do_not_repeat_claims_or_restore_expired_gifts(self):
        self.befriend()
        self.success(1, 2308)
        self.success(2, 2309)
        self.clock.return_value += 86400
        self.assertEqual(self.friends(2)[1], 0)
        self.assert_rejected(2, 2309)
        self.success(1, 2308)
        self.success(2, 2309)
        self.clock.return_value = self.now
        self.assertEqual(self.friends(2)[1], 1)
        self.assert_rejected(2, 2309)

    def test_gift_save_failure_overflow_and_same_request_retry_are_atomic(self):
        self.befriend()
        self.success(1, 2308)
        before = copy.deepcopy(self.sessions[2].save)
        shared = (self.root / "friends.json").read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(2, 2309)
        self.assertEqual(self.sessions[2].save, before)
        self.assertEqual((self.root / "friends.json").read_bytes(), shared)
        self.sessions[2].save["role_state"]["energy"] = (1 << 31) - 1
        player.save_role(self.sessions[2].save, self.store.path(2), test_guild.COUNTS)
        self.assert_rejected(2, 2309)
        self.sessions[2].save["role_state"]["energy"] = 0
        player.save_role(self.sessions[2].save, self.store.path(2), test_guild.COUNTS)
        packet = self.sessions[2].handle(2309, 65000, b"")
        state = copy.deepcopy(self.sessions[2].save)
        self.assertEqual(self.sessions[2].handle(2309, 65000, b""), packet)
        self.assertEqual(self.sessions[2].save, state)

    def test_private_chat_has_bound_sender_persistent_unread_and_connection_cursors(self):
        self.befriend()
        self.chat()
        self.assertEqual(protocol.parse_ids_pb(self.success(2, 2313)), [1])
        self.assertEqual(protocol.pb_get_varint(self.records(self.success(2, 2312))[0], 1), 1000001)
        self.reconnect(2)
        history = self.chat_query(2, 1)
        self.assertEqual(protocol.pb_get_varint(self.records(history, 2)[0], 1), 1000001)
        self.assertEqual(protocol.parse_ids_pb(self.success(2, 2313)), [0])
        self.assertEqual(self.chat_query(2, 1, 1), b"")
        self.clock.return_value += 5
        answer = self.chat(2, 1, "收到")
        own = protocol.pb_get_varint(bytes.fromhex(self.sessions[2].save["role_snapshot"]), 1)
        self.assertEqual(protocol.pb_get_varint(self.records(answer, 2)[0], 1), own)
        self.assertEqual(len(self.records(self.chat_query(1, 2, 1), 2)), 1)
        self.assertEqual(self.success(3, 2312), b"")

    def test_chat_rejects_spoofed_fields_strangers_control_text_and_spam(self):
        self.befriend()
        for text in ("", " ", "\n", "<a>", "&&&", "字" * 41):
            raw = protocol.encode_pb_field(2, 2, protocol.encode_pb_field(1, 0, 1000002)
                + protocol.encode_pb_field(2, 2, text.encode()))
            self.assert_rejected(1, 2306, raw=raw)
        raw = protocol.encode_pb_field(2, 2, protocol.encode_pb_field(1, 0, 1000002)
            + protocol.encode_pb_field(2, 2, b"ok") + protocol.encode_pb_field(3, 0, self.now))
        self.assert_rejected(1, 2306, raw=raw)
        self.chat()
        self.assert_rejected(1, 2306, raw=protocol.encode_pb_field(2, 2,
            protocol.encode_pb_field(1, 0, 1000002) + protocol.encode_pb_field(2, 2, b"again")))
        self.assert_rejected(3, 2305, raw=protocol.encode_pb_field(1, 0, 1000002))

    def test_chat_level_gate_and_bounded_history_survive_reconnect(self):
        self.befriend()
        self.sessions[1].save["role_state"]["level"] = 18
        self.assert_rejected(1, 2306, raw=protocol.encode_pb_field(2, 2,
            protocol.encode_pb_field(1, 0, 1000002) + protocol.encode_pb_field(2, 2, b"hello")))
        self.sessions[1].save["role_state"]["level"] = 19
        for i in range(102):
            self.clock.return_value = self.now + i * 5
            self.chat(text=str(i))
        self.reconnect(2)
        self.assertEqual(len(self.records(self.chat_query(2, 1), 2)), 100)

    def test_recreated_roles_do_not_inherit_relations_blocks_chat_or_gifts(self):
        self.befriend()
        self.chat()
        self.success(1, 2308)
        self.store.close_session(2)
        save = copy.deepcopy(test_guild.SAVE)
        save.update(created_at=self.now + 10, role_name="重建角色")
        save["role_state"]["level"] = 31
        player.save_role(save, self.store.path(2), test_guild.COUNTS)
        self.reconnect(2)
        self.assertEqual((self.friends(1)[0], self.friends(2)[0]), ({}, {}))
        self.assertEqual(protocol.parse_ids_pb(self.success(2, 2313)), [0])
        self.assert_rejected(2, 2309)
        self.assert_rejected(1, 2305, raw=protocol.encode_pb_field(1, 0, 1000002))

    def test_invalid_inputs_and_unmatched_combs_never_mutate_any_account(self):
        self.friends()
        for opcode, values in ((2300, [1]), (2301, [2]), (2302, []), (2302, [1000001]),
                (2302, [1000002, 1000002]), (2304, [1000002, 1]), (2311, [0]),
                (2307, []), (2308, [1000002]), (2309, [1000002]), (2310, [1000002]),
                (3002, [1]), (3003, [1000999]), (3004, [1000002]), (1020, [0]), (1022, [1000001])):
            with self.subTest(opcode=opcode, values=values):
                self.assert_rejected(1, opcode, values=values)
        self.assert_rejected(1, 999900, raw=guild.message(2302, guild.ids([1000002])))

    def test_corrupt_shared_or_peer_save_fails_closed_without_losing_relationships(self):
        self.befriend()
        path = self.root / "friends.json"
        raw = path.read_bytes()
        path.write_bytes(b"{")
        self.assert_rejected(1, 2300)
        path.write_bytes(raw)
        peer = self.store.path(2)
        saved = peer.read_bytes()
        peer.write_bytes(b"{")
        self.assert_rejected(1, 2300)
        peer.write_bytes(saved)
        self.assertEqual(set(self.friends(1)[0]), {1000002})

    def test_failed_shared_write_has_no_partial_relation_or_success(self):
        self.friends()
        self.assertFalse((self.root / "friends.json").exists())
        original = storage.atomic_write
        def fail(path, raw):
            if Path(path).name == "friends.json":
                raise OSError("disk full")
            return original(path, raw)
        with patch.object(storage, "atomic_write", side_effect=fail), self.assertRaises(OSError):
            self.request(1, 2302, values=[1000002])
        self.assertFalse((self.root / "friends.json").exists())
        self.assertEqual(self.success(2, 2303), b"")

    def test_role_failure_discards_unpaid_relation_and_publish_failure_recovers_matching_receipt(self):
        self.friends()
        before = copy.deepcopy(self.sessions[1].save)
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 2302, values=[1000002])
        self.assertEqual(self.sessions[1].save, before)
        self.assertEqual(self.success(2, 2303), b"")
        self.success(1, 2302, values=[1000002])
        original = storage.atomic_write
        def fail_publish(path, raw):
            state = json.loads(raw) if Path(path).name == "friends.json" else {}
            if "pending" not in state and state.get("players", {}).get("2", {}).get("friends"):
                raise OSError("publish failed")
            return original(path, raw)
        with patch.object(storage, "atomic_write", side_effect=fail_publish), self.assertRaises(OSError):
            self.request(2, 2304, values=[1000001, 1])
        self.assertIn("pending", self.shared())
        self.reconnect(2)
        for _ in range(2):
            self.assertEqual(set(self.friends(2)[0]), {1000001})
        self.assertNotIn("pending", self.shared())
        self.assertEqual(set(self.friends(1)[0]), {1000002})

    def test_missing_or_structurally_corrupt_journal_never_creates_an_empty_replacement(self):
        self.befriend()
        path = self.root / "friends.json"
        raw = path.read_bytes()
        path.unlink()
        self.assert_rejected(1, 2300)
        state = json.loads(raw)
        for change in ({"version": True}, {"next_chat": -1}, {"players": {}}, {"gifts": {"1:2": [True, 1]}}):
            candidate = {**state, **change}
            path.write_text(json.dumps(candidate))
            self.assert_rejected(1, 2300)
        path.write_bytes(raw)
        self.assertEqual(set(self.friends()[0]), {1000002})

    def test_offline_public_metadata_is_truthful_and_does_not_expose_addresses_or_credentials(self):
        self.befriend()
        self.store.close_session(2)
        peer = self.store.path(2)
        before = peer.read_bytes()
        row = self.friends(1)[0][1000002]
        params = self.records(next(v for n, w, v in protocol.iter_pb_fields(row) if n == 10))
        self.assertEqual(protocol.pb_get_varint(params[6], 1), (1 << 64) - 1)
        self.assertNotIn(b"same-address", row)
        self.assertNotIn(b"test-password", row)
        self.assertEqual(peer.read_bytes(), before)

    def test_matched_main_preload_rewrites_unread_without_relaxing_comb_matching(self):
        self.befriend()
        self.chat()
        frames = json.loads((test_guild.ROOT / "recorded_frames.json").read_bytes())
        frame = next(f for f in frames if f["c2s"] and f["opcode"] == 999900 and 2313 in protocol.get_comb_ids(bytes.fromhex(f["hex"])))
        body = self.success(2, 999900, raw=bytes.fromhex(frame["hex"]))
        self.assertEqual(protocol.parse_ids_pb(dict(protocol.get_comb_messages(body))[2313]), [1])
        self.assert_rejected(2, 999900, raw=guild.message(2313, b"") + guild.message(2300, b""))

    def test_parallel_accepts_cannot_overfill_last_friend_slot(self):
        for row in self.config["vip"].values():
            row["friend"] = 1
        self.success(1, 2302, values=[1000002])
        self.success(3, 2302, values=[1000002])
        results = []
        def accept(sender):
            results.append(self.request(2, 2304, values=[1000000 + sender, 1])[0][0])
        threads = [threading.Thread(target=accept, args=(sender,)) for sender in (1, 3)]
        for thread in threads: thread.start()
        for thread in threads: thread.join()
        self.assertEqual(sorted(results), [2304, 999999])
        self.assertEqual(len(self.friends(2)[0]), 1)

    def test_public_slots_only_show_used_generals_equipment_and_worn_sigils(self):
        save = self.sessions[2].save
        hidden = protocol.encode_pb_field(1, 2, protocol.pb_set_varint(
            next(iter(formation.records(bytes.fromhex(save["world_state"]["1002"]), 1, 2).values())), 2, 2999999))
        player.record_slot_update(save, hidden)
        player.save_role(save, self.store.path(2), test_guild.COUNTS)
        before = self.store.path(2).read_bytes()
        public = self.success(1, 1020, values=[1000002])
        active = {protocol.pb_get_varint(v, 2) for v in self.records(public, 4)}
        self.assertEqual(set(formation.records(public, 1, 2)), active)
        self.assertNotIn(2999999, formation.records(public, 1, 2))
        self.assertEqual(self.store.path(2).read_bytes(), before)

    def test_sparring_uses_both_real_rosters_and_never_charges_or_changes_progress(self):
        self.befriend()
        before = {a: self.store.path(a).read_bytes() for a in self.sessions}
        for account, target in ((1, 2), (2, 1)):
            raw = self.success(account, 1022, values=[1000000 + target])
            report = json.loads(self.records(raw, 5)[0])
            self.assertEqual(report["meta"]["attack"]["n"], f"好友测试{account}")
            self.assertEqual(report["meta"]["defense"]["n"], f"好友测试{target}")
            self.assertEqual(bool(protocol.pb_get_varint(raw, 1)), report["result"])
        self.assertEqual({a: self.store.path(a).read_bytes() for a in self.sessions}, before)

    def test_sparring_has_real_losses_and_unknown_passives_reject_without_settlement(self):
        self.befriend()
        save = self.sessions[1].save
        for raw in formation.records(bytes.fromhex(save["world_state"]["1002"]), 1, 2).values():
            for field, value in ((4, 0), (6, 1), (7, 0), (8, 1), (9, 1)):
                raw = protocol.pb_set_varint(raw, field, value)
            player.record_slot_update(save, protocol.encode_pb_field(1, 2, raw))
        player.save_role(save, self.store.path(1), test_guild.COUNTS)
        with patch.object(friends.random, "getrandbits", return_value=7):
            self.assertFalse(protocol.pb_get_varint(self.success(1, 1022, values=[1000002]), 1))
            self.assertTrue(protocol.pb_get_varint(self.success(2, 1022, values=[1000001]), 1))
        raw = next(iter(formation.records(bytes.fromhex(save["world_state"]["1002"]), 1, 2).values()))
        cid = str(protocol.pb_get_varint(raw, 1))
        player.record_slot_update(save, protocol.encode_pb_field(1, 2, protocol.pb_set_varint(raw, 4, 1)))
        player.save_role(save, self.store.path(1), test_guild.COUNTS)
        with patch.dict(self.config["general"][cid], break1=9999991), patch.dict(self.config["breakskill"],
                {"9999991": {**self.config["breakskill"]["9100003"], "id": 9999991, "type": 1}}):
            self.assert_rejected(1, 1022, values=[1000002])

    def test_sparring_never_persists_or_leaks_legacy_state_normalization(self):
        self.befriend()
        for key in ("pet_state", "sigil_state"):
            self.sessions[1].save.pop(key, None)
        before = copy.deepcopy(self.sessions[1].save)
        disk = self.store.path(1).read_bytes()
        self.success(1, 1022, values=[1000002])
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))

    @classmethod
    def client_scripts(cls):
        if not hasattr(cls, "_client_scripts"):
            with redirect_stdout(io.StringIO()):
                encrypted = builder.get_patched_lua_scripts()
            cls._client_scripts = {}
            for name, raw in encrypted.items():
                data = builder.xxtea_decrypt(raw, builder.XXTEA_KEY)
                cls._client_scripts[name] = data[:struct.unpack("<I", data[-4:])[0]]
        return cls._client_scripts

    def network_lua(self, account=1, *, native_protobuf=False):
        import test_activity_copy
        lua = test_activity_copy.ActivityCopyTests.network_lua(self, native_protobuf=native_protobuf)
        def native(value):
            if isinstance(value, dict):
                return lua.table_from({native(k): native(v) for k, v in value.items()})
            return value.encode() if isinstance(value, str) else value
        with zipfile.ZipFile(test_guild.ROOT / "configs_sec5.zip") as archive:
            for name in ("token_suit",):
                lua.globals().gamedata[b"config"][name.encode()] = native(json.loads(archive.read("5/" + name + ".json")))
        comb = builder.read_script("GameCombMessages").decode().replace("\r\n", "\n")
        lua.execute(comb[comb.index("function roleexpEx()"):comb.index("local ext_req")].encode())
        lua.globals().roleexpEx()
        for name in ("friends_pb", "players_pb", "chats_pb", "friendchatquery_pb", "combmessages_pb", "slots_pb", "error_pb", "params_pb"):
            lua.execute(self.client_scripts()["assets/pb/friends_pb.so"] if name == "friends_pb" else builder.read_script(name, "pb"))
        code = builder.read_script("gamedata").decode().replace("\r\n", "\n")
        for start, end in (("function gamedata.othereneralData(", "function gamedata.shopData("),
                ("function gamedata.SomethingProcess(", "function gamedata.countdownGiftData("),
                ("function gamedata.updateRoleStamina(", "function gamedata.shortenergy("),
                ("function gamedata.ProtagonistData(", "function gamedata.RoleData("),
                ("function gamedata.generalData(", "function gamedata.artifactData("),
                ("function gamedata.soulData(", "function gamedata.SoulHuntQuery("),
                ("function gamedata.getOriginCid(", "function gamedata.setAdStatus("),
                ("function gamedata.findcombskilllevel(", "function gamedata.Generals("),
                ("function gamedata.relationData(", "function gamedata.Slots("),
                ("function gamedata.cheerData(", "function gamedata.SlotInfoProcess(")):
            lua.execute(code[code.index(start):code.index(end)].encode())
        lua.execute(b'''gamedata.cache.friends={friends={},max=0};gamedata.cache.shield={friends={},max=0,index_now=0}
            UIResponse=function() end;gamedata.sortData=function() end
            table.copy=function(t) local r={} for k,v in pairs(t) do r[k]=v end return r end
            table.merge=function(a,b) local r=table.copy(a or {}) for k,v in pairs(b) do r[k]=v end return r end
            package.loaded.logError={errorMessage={},errorFunc={}};printf=function() end
            initPb=function(mod,fd) local m=mod.Ids();m:ParseFromString(fd.rbuf);return m end''')
        role = self.sessions[account].save["role_state"]
        lua.globals().gamedata[b"cache"][b"role"] = lua.table_from({k.encode(): v for k, v in role.items()})
        lua.globals().gamedata[b"cache"][b"role"][b"id"] = protocol.pb_get_varint(bytes.fromhex(self.sessions[account].save["role_snapshot"]), 1)
        for name in ("GameFriendQuery", "GameFriendChat"):
            lua.execute(builder.read_script(name))
        for name in ("GameFriendManager", "GameCheckOtherSlotsInfo", "GameBattleOther"):
            lua.execute(self.client_scripts()["assets/scripts/" + name + ".so"])
        lua.execute(self.client_scripts()["assets/common_lua/GameErrorMessage.so"])
        self.assertIsNone(lua.globals().gameConfig)
        return lua

    def client_call(self, lua, account, send, receive, request):
        req = lua.table_from({k.encode(): lua.table_from(v) if isinstance(v, list) else v for k, v in request.items()})
        mode, opcode, body = getattr(lua.globals(), send)(req)
        self.assertEqual(mode, 1)
        packet = self.success(account, opcode, raw=body or b"")
        return getattr(lua.globals(), receive)(lua.table_from({b"rbuf": packet}))

    def test_actual_network_lua_handles_relations_native_metadata_and_gift_energy_once(self):
        lua = self.network_lua()
        req = self.client_call(lua, 1, "UIFriendRecommendCallback", "NetFriendRecommendCallback", {})
        self.assertEqual(len(req[b"players"]), 2)
        self.client_call(lua, 1, "UIFriendReqCallBack", "NetFriendReqCallBack", {"ids": [1000002]})
        self.success(2, 2304, values=[1000001, 1])
        req = self.client_call(lua, 1, "UIFriendQueryCallback", "NetFriendQueryCallback", {"view": 4})
        self.assertEqual((req[b"view"], req[b"max"], req[b"publicRid"]), (4, 0, 1000001))
        friend = req[b"friends"][1]
        self.assertEqual(friend[b"rid"], 1000002)
        self.assertIsNotNone(friend[b"params"][1][b"i"])
        self.assertEqual(friend[b"params"][2][b"s"], b"")
        self.assertEqual(friend[b"params"][3][b"i"], 0)
        self.success(2, 2308)
        energy = lua.globals().gamedata[b"cache"][b"role"][b"energy"]
        self.client_call(lua, 1, "UIFriendRecvGiftCallBack", "NetFriendRecvGiftCallBack", {"ids": [1000002]})
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"energy"], energy + 1)
        req = self.client_call(lua, 1, "UIFriendQueryCallback", "NetFriendQueryCallback", {})
        self.assertEqual((req[b"max"], req[b"friends"][1][b"recvgift"]), (1, 2))

    def test_actual_lua_serializes_string_index_ids_and_unlocks_after_native_errors(self):
        lua = self.network_lua()
        request = lua.table_from({b"ids": lua.table_from({b"1": 1000002, b"2": 2})})
        mode, opcode, raw = lua.globals().UIFriendRepCallBack(request)
        self.assertEqual((mode, opcode, protocol.parse_ids_pb(raw)), (1, 2304, [1000002, 2]))
        self.assertEqual(lua.globals().UIFriendReqCallBack(lua.table_from({b"ids": lua.table_from([1000003])}))[0], 0)
        lua.globals().NetErrorMessageCallback9(lua.table_from({b"rbuf": guild.ids([2304, 0])}))
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localFriendBusy"])
        self.assertEqual(lua.globals().UIFriendReqCallBack(lua.table_from({b"ids": lua.table_from([1000003])}))[0], 1)

    def test_actual_lua_changed_chat_targets_keep_fifo_context_and_same_queries_do_not_duplicate(self):
        self.befriend()
        self.befriend(1, 3)
        lua = self.network_lua()
        pending = []
        for peer in (2, 3):
            req = lua.table_from({b"rid": 1000000 + peer, b"new": 0, b"generation": 4})
            mode, opcode, raw = lua.globals().UIFriendChatQueryCallback(req)
            self.assertEqual(mode, 1)
            pending.append(self.success(1, opcode, raw=raw))
        self.assertEqual(lua.globals().UIFriendChatQueryCallback(req)[0], 0)
        for peer, raw in zip((2, 3), pending):
            reply = lua.globals().NetFriendChatQueryCallback(lua.table_from({b"rbuf": raw}))
            self.assertEqual((reply[b"rid"], reply[b"generation"]), (1000000 + peer, 4))

    def test_actual_chat_and_block_callbacks_refresh_real_caches_without_ui_globals(self):
        self.befriend()
        lua = self.network_lua()
        self.client_call(lua, 1, "UIFriendQueryCallback", "NetFriendQueryCallback", {})
        reply = self.client_call(lua, 1, "UIFriendChatCallback", "NetFriendChatCallback",
            {"rid": 1000002, "content": "你好".encode(), "generation": 8})
        self.assertEqual((reply[b"rid"], reply[b"generation"], len(reply[b"chats"])), (1000002, 8, 1))
        self.assertEqual(reply[b"chats"][1][b"rid"], reply[b"selfRid"])
        self.client_call(lua, 1, "UIFriendAddShieldCallBack", "NetFriendAddShieldCallBack", {"ids": [1000003]})
        for _ in range(2):
            reply = self.client_call(lua, 1, "UIFriendAllShieldCallBack", "NetFriendAllShieldCallBack", {"refresh": True})
            self.assertEqual((reply[b"max"], len(reply[b"players"]), reply[b"players"][1][b"rid"]), (1, 1, 1000003))
        self.client_call(lua, 1, "UIFriendDeleteShieldCallBack", "NetFriendDeleteShieldCallBack", {"ids": [1000003]})
        reply = self.client_call(lua, 1, "UIFriendAllShieldCallBack", "NetFriendAllShieldCallBack", {"refresh": True})
        self.assertEqual((reply[b"max"], len(reply[b"players"])), (0, 0))
        self.assertIsNone(lua.globals().gameConfig)

    def test_block_pagination_uses_real_offsets_and_refresh_replaces_old_cache(self):
        for account in range(4, 55):
            save = copy.deepcopy(test_guild.SAVE)
            save.update(created_at=self.now - 86400 + account, role_name=f"分页{account}")
            player.save_role(save, self.store.path(account), test_guild.COUNTS)
        self.success(1, 3003, values=[1000000 + a for a in range(4, 55)])
        lua = self.network_lua()
        first = self.client_call(lua, 1, "UIFriendAllShieldCallBack", "NetFriendAllShieldCallBack", {"refresh": True})
        self.assertEqual((first[b"max"], len(first[b"players"])), (51, 50))
        second = self.client_call(lua, 1, "UIFriendAllShieldCallBack", "NetFriendAllShieldCallBack", {})
        self.assertEqual((second[b"max"], len(second[b"players"])), (51, 51))
        self.assertEqual(lua.globals().gamedata[b"cache"][b"shield"][b"index_now"], 51)
        first = self.client_call(lua, 1, "UIFriendAllShieldCallBack", "NetFriendAllShieldCallBack", {"refresh": True})
        self.assertEqual(len(first[b"players"]), 50)

    def test_actual_public_slots_and_sparring_callbacks_accept_only_current_target_context(self):
        self.befriend()
        lua = self.network_lua()
        result = self.client_call(lua, 1, "UICheckOtherSlotsInfoCallBack", "NetCheckOtherSlotsInfoCallBack",
            {"rid": 1000002, "level": 31, "generation": 3})
        self.assertEqual((result[b"rid"], result[b"generation"]), (1000002, 3))
        self.assertGreater(len(result[b"slots"]), 0)
        result = self.client_call(lua, 1, "UIBattleOtherCallback", "NetBattleOtherCallback", {"rid": 1000002, "view": 4})
        self.assertEqual((result[b"rid"], result[b"view"]), (1000002, 4))
        self.assertTrue(result[b"battlereport"])

    def ui_lua(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("实际好友界面验证需要lupa.lua51")
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute('''print=function() end;printT=print
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            gameConfig={strings={string_common=function() return "好友" end}}
            requests={};UIRequest=function(t) requests[#requests+1]=t end
            ui={setLabelString=function(n,text) n.text=text end}
            function node() return setmetatable({}, {__index=function(t,k)
                if k=="getContentSize" then return function() return {width=500,height=600} end end
                return function() end
            end}) end
            function items() return setmetatable({}, {__index=function(t,k) local n=node();rawset(t,k,n);return n end}) end
            GameScene={layers={friends={show=true,module={localFriendView=4,reloadFriendList=function(self) self.loaded=true end}}},templayers={}}
            local chat={localFriendKind="chat",localFriendGeneration=8,seleteRid=1,frinedData={["1"]={rid=1000002}},
                addNewChat=function(self) self.added=(self.added or 0)+1 end,
                reloadChatView=function(self) self.reloaded=(self.reloaded or 0)+1 end}
            gameWindows={windows={friend={show=true,module=chat}},openWindow=function(self) self.opened=(self.opened or 0)+1 end}
            gameTimer={UnrigistTimeFunc=function(self,name) self.cancelled=name end}
            showRewardPopupWindow=function() end''')
        lua.execute(self.client_scripts()["assets/scripts/UIFriends.so"].decode())
        return lua

    def test_actual_ui_discards_closed_reopened_and_other_target_chat_replies(self):
        lua = self.ui_lua()
        module = lua.globals().gameWindows.windows.friend.module
        reply = lua.table_from({"rid": 1000003, "generation": 8, "req": {"new": 1}, "chats": {}}, recursive=True)
        lua.globals().UIFriendChatQuery(reply)
        self.assertIsNone(module.added)
        reply.rid = 1000002
        lua.globals().UIFriendChatQuery(reply)
        self.assertEqual(module.added, 1)
        module.localFriendGeneration = 9
        lua.globals().UIFriendChat(reply)
        self.assertEqual(module.added, 1)
        lua.globals().gameWindows.windows.friend.show = False
        reply.req.new = 0
        lua.globals().UIFriendChatQuery(reply)
        self.assertIsNone(lua.globals().gameWindows.opened)
        reply.generation, reply.view, reply.friend = None, 4, lua.table_from({"rid": 1000002})
        lua.globals().GameScene.layers.friends.module.localFriendView = 5
        lua.globals().UIFriendChatQuery(reply)
        self.assertIsNone(lua.globals().gameWindows.opened)
        reply.view = 5
        lua.globals().UIFriendChatQuery(reply)
        self.assertEqual(lua.globals().gameWindows.opened, 1)

    def test_actual_page_queries_every_reentry_and_window_close_invalidates_generation(self):
        lua = self.ui_lua()
        page = lua.execute(self.client_scripts()["assets/scripts/Layer_friends.so"].decode())
        page.rootItems, page.localFriendView = lua.globals()["items"](), 4
        for name in ("frinedData", "recomendData", "reqData", "shieldData"):
            page[name] = lua.table_from({"cached": True})
        for tab, opcode in (("friend", 2300), ("recomend", 2301), ("req", 2303), ("shield", 3002)):
            page.shiftPage(page, tab)
            request = lua.globals().requests[len(lua.globals().requests)]
            self.assertEqual((request.type, request.view), (opcode, 4))
        self.assertTrue(request.refresh)
        window = lua.execute(self.client_scripts()["assets/scripts/window_friend.so"].decode())
        window.root, window.localFriendGeneration = lua.globals().node(), 8
        window.close(window)
        self.assertEqual(window.localFriendGeneration, 9)
        self.assertEqual(lua.globals().gameTimer.cancelled, "friendChat")
        self.assertIsNone(window.root)

    def test_actual_friend_page_displays_server_public_id_not_reused_native_role_id(self):
        lua = self.ui_lua()
        module = lua.globals().GameScene.layers.friends.module
        module.rootItems = lua.globals()["items"]()
        lua.globals().UIFriendQuery(lua.table_from({"view": 4, "publicRid": 1000001}))
        self.assertEqual(module.rootItems.myid.text, "1000001")
        self.assertTrue(module.loaded)

    def test_actual_public_slot_ui_checks_both_target_and_window_generation(self):
        lua = self.ui_lua()
        lua.execute('''GameScene.templayers.other_slotinfo={show=true,localFriendGeneration=3,palyerdata={rid=1000002},
            reload=function(self) self.loaded=(self.loaded or 0)+1 end}''')
        lua.execute(self.client_scripts()["assets/scripts/UISlots.so"].decode())
        reply = lua.table_from({"rid": 1000002, "generation": 2})
        target = lua.globals().GameScene.templayers.other_slotinfo
        lua.globals().UICheckOtherSlotsInfo(reply)
        self.assertIsNone(target.loaded)
        reply.generation = 3
        lua.globals().UICheckOtherSlotsInfo(reply)
        self.assertEqual(target.loaded, 1)
        target.palyerdata.rid = 1000003
        lua.globals().UICheckOtherSlotsInfo(reply)
        self.assertEqual(target.loaded, 1)

    def test_real_sparring_with_same_native_iids_converts_actual_animation_assets(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("真实切磋动画验证需要lupa.lua51")
        self.befriend()
        with patch.object(friends.random, "getrandbits", return_value=7):
            report = json.loads(self.records(self.success(1, 1022, values=[1000002]), 5)[0])
        lua = LuaRuntime()
        config = dict(self.config)
        with zipfile.ZipFile(test_guild.ROOT / "configs_sec5.zip") as archive:
            for name in ("generalanimation", "skillanimation"):
                config[name] = json.loads(archive.read("5/" + name + ".json"))
        lua.globals().gamedata = lua.table_from({"config": config}, recursive=True)
        lua.execute('''print=function() end;printT=print;battleScene={slotNum=7}
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            CCFileUtils={sharedFileUtils=function(self) return self end,fullPathForFilename=function(self,p) return p end}
            ui={Split=function(s,sep) local t={} for v in string.gmatch(s,'[^'..sep..']+') do t[#t+1]=v end return t end}''')
        with zipfile.ZipFile(builder.SRC_APK) as archive:
            names = archive.namelist()
            lua.globals().CCFileUtils.isFileExist = lambda _, path: any(n.endswith("/" + path) for n in names)
            def asset(path):
                matches = [n for n in names if n.endswith("/" + path)]
                self.assertEqual(len(matches), 1, path)
                return lua.table_from(json.loads(archive.read(matches[0])), recursive=True)
            lua.globals().LoadJsonFileToTable = asset
            lua.execute(self.client_scripts()["assets/scripts/battleReportConvert.so"].decode())
            lua.execute(builder.read_script("BattleReportAbbToKey").decode())
            native = lua.table_from(json.loads(lua.globals().ReplaceAbbToKey(json.dumps(report))), recursive=True)
            allies, enemies = lua.globals().getBattleInitSlotInfo(native)
            animations, ext = lua.globals().convertBattleReportToAnimationSub(native, allies, enemies)
            self.assertGreater(len(animations), 1)
            for side, key in (("attack", "atk"), ("defense", "def")):
                for pos, unit in report["endmeta"][side].items():
                    self.assertEqual((ext.endinfo[key][pos].hp, ext.endinfo[key][pos].ap), (unit["h"], unit["ap"]))


if __name__ == "__main__":
    unittest.main()
