from contextlib import redirect_stdout
import io
import json
import os
from pathlib import Path
import struct
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

import mock_server as server
from zyj_server import guide, player, protocol, replay
from zyj_server.session import Session


class ReplayConnection:
    def __init__(self, requests, chunk_size):
        stream = b"".join(protocol.pack_frame(f["opcode"], f["seq"], bytes.fromhex(f["hex"])) for f in requests)
        self.chunks = iter(stream[i:i + chunk_size] for i in range(0, len(stream), chunk_size))
        self.responses = []
        self.closed = False

    def recv(self, size):
        chunk = next(self.chunks, b"")
        assert len(chunk) <= size
        return chunk

    def sendall(self, data):
        magic, length, opcode, seq = struct.unpack(">IIII", data[:16])
        assert magic == 0xEE1C and len(data) == 16 + length
        self.responses.append({"opcode": opcode, "seq": seq, "hex": data[16:].hex()})

    def close(self):
        self.closed = True


class ReplayRoutingTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with redirect_stdout(io.StringIO()):
            cls.step_counts = guide.load_guide_step_counts(server.CONFIG_ZIP)
            cls.role_config = player.load_role_config(server.CONFIG_ZIP)
            cls.frames = replay.load_recordings(server.RECORD_PATH)
            cls.tables = replay.build_routing_tables(cls.frames)
        cls.requests = [f for f in cls.frames if f["c2s"]]
        cls.by_seq = {f["seq"]: f for f in cls.requests}
        cls.recorded = {(f["seq"], f["opcode"]): f for f in cls.frames if not f["c2s"] and f["seq"] != 0}
        cls.activity_frames = json.loads((Path(server.BASE_DIR) / "test_activity_frames.json").read_text())

    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.save_path = Path(temp.name) / "role_save.json"
        self.now = 1800000000
        clock_patch = patch.object(player.time, "time", return_value=self.now)
        self.clock = clock_patch.start()
        self.addCleanup(clock_patch.stop)

    def run_client(self, conn):
        server.handle_client(conn, ("test", 0), self.tables, self.save_path, self.step_counts, self.role_config)

    def replay(self, requests, chunk_size=4096):
        conn = ReplayConnection(requests, chunk_size)
        with redirect_stdout(io.StringIO()) as log:
            self.run_client(conn)
        self.assertTrue(conn.closed)
        errors = [line for line in log.getvalue().splitlines() if "连接异常" in line or "载入玩家状态失败" in line]
        self.assertEqual(errors, [])
        return conn.responses

    def assert_rejected(self, request, reason):
        original = self.save_path.read_bytes()
        conn = ReplayConnection([request], 7)
        with redirect_stdout(io.StringIO()) as log:
            self.run_client(conn)
        self.assertTrue(conn.closed)
        self.assertEqual(len(conn.responses), 0)
        self.assertEqual(self.save_path.read_bytes(), original)
        self.assertIn(reason, log.getvalue())

    def assert_recorded_response(self, response, recorded_seq, live_seq=None):
        expected = self.recorded[(recorded_seq, response["opcode"])]
        self.assertEqual(response["seq"], recorded_seq if live_seq is None else live_seq)
        self.assertEqual(response["hex"], expected["hex"])

    def assert_replayed_payload(self, opcode, actual, expected):
        if opcode == 999900:
            actual_messages = protocol.get_comb_messages(bytes.fromhex(actual))
            expected_messages = protocol.get_comb_messages(bytes.fromhex(expected))
            self.assertEqual([mid for mid, _ in actual_messages], [mid for mid, _ in expected_messages])
            for (mid, data), (_, recorded) in zip(actual_messages, expected_messages):
                self.assert_replayed_payload(mid, data.hex(), recorded.hex())
        elif opcode == 3610:
            groups = self.begin7day_groups(bytes.fromhex(actual))
            recorded = self.begin7day_groups(bytes.fromhex(expected))
            self.assertEqual(set(groups), set(recorded))
            self.assertEqual(groups[0], recorded[0])
            self.assertEqual((groups[1][0], groups[1][29]), (recorded[1][0], recorded[1][29]))
            # Only the two supported rewards are live; unsupported paid gifts stay disabled.
            self.assertTrue(all(value == 0 for i, value in enumerate(groups[1]) if i not in (0, 29)))
        elif opcode == 999905:
            values = protocol.parse_ids_pb(bytes.fromhex(actual))
            self.assertEqual(values, [int(self.clock.return_value), protocol.parse_ids_pb(bytes.fromhex(expected))[1]])
        elif opcode in (1001, 1054):
            values = {n: value for n, wire, value in protocol.iter_pb_fields(bytes.fromhex(actual))}
            recorded = {n: value for n, wire, value in protocol.iter_pb_fields(bytes.fromhex(expected))}
            # Role timers/stamina now follow local operations, not captured wall-clock regeneration.
            fields = (1, 3, 5, 6, 7, 8, 9, 11, 12, 13, 14, 21, 26, 27) if opcode == 1001 else range(1, 10)
            for field in fields:
                self.assertEqual(values.get(field, 0), recorded.get(field, 0), (opcode, field))
            if opcode == 1054:
                if 10 in recorded:
                    self.assertEqual(values.get(10), recorded[10])
                elif 10 in values:
                    # Reconnect replies may now include the last known general instead of relying on client cache.
                    general = {n: v for n, w, v in protocol.iter_pb_fields(values[10])}
                    self.assertEqual((general[2], general[3]), (values[1], values[2]))
        else:
            self.assertEqual(actual, expected)

    def role_data(self, response):
        body = bytes.fromhex(response["hex"])
        if response["opcode"] == 999900:
            body = next(data for mid, data in protocol.get_comb_messages(body) if mid == 1001)
        return {n: value for n, wire, value in protocol.iter_pb_fields(body)}

    def query_world(self, opcode):
        responses = self.replay([{"opcode": opcode, "seq": 20000, "hex": ""}])
        self.assertEqual(len(responses), 1)
        self.assertEqual((responses[0]["opcode"], responses[0]["seq"]), (opcode, 20000))
        return bytes.fromhex(responses[0]["hex"])

    def activity_request(self, opcode, values=()):
        body = b"".join(protocol.encode_pb_field(1, 0, value) for value in values)
        return {"opcode": opcode, "seq": 20000, "hex": body.hex()}

    def begin7day_groups(self, body):
        groups = {}
        for n, w, row in protocol.iter_pb_fields(body):
            if n == 1 and w == 2:
                data = next(v for f, t, v in protocol.iter_pb_fields(row) if f == 2 and t == 2)
                groups[protocol.pb_get_varint(row, 1)] = protocol.parse_ids_pb(data)
        return groups

    def seed_stamina(self, amount):
        saved = player.get_default_save()
        saved["has_role"] = True
        saved["role_snapshot"] = self.recorded[(41, 1001)]["hex"]
        saved["role_state"] = {"level": 1, "exp": 0, "stamina": amount, "maxstamina": 50}
        self.save_path.write_text(json.dumps(saved))

    def give_props(self, amounts):
        saved = json.loads(self.save_path.read_text())
        with redirect_stdout(io.StringIO()):
            player.initialize_world_state(saved, self.tables[2])
            for cid, count in amounts.items():
                player.change_item_count(saved, cid, count, self.role_config)
        self.save_path.write_text(json.dumps(saved))

    def query_role(self):
        response = self.replay([dict(self.by_seq[41], seq=20000)])
        self.assertEqual(len(response), 1)
        return self.role_data(response[0])

    def entity_records(self, body, field, key_field):
        return {protocol.pb_get_varint(value, key_field): value for n, wire, value in protocol.iter_pb_fields(body) if n == field and wire == 2}

    def replay_through(self, seq):
        return self.replay([f for f in self.requests if f["seq"] <= seq])

    def expected_group(self, recorded_seq, live_seq=None):
        request = self.by_seq[recorded_seq]
        start = self.frames.index(request) + 1
        end = next((i for i in range(start, len(self.frames)) if self.frames[i]["c2s"]), len(self.frames))
        result = []
        for index, frame in enumerate(self.frames):
            if frame["c2s"]:
                continue
            reply = frame["seq"] == recorded_seq and frame["opcode"] == request["opcode"]
            push = start <= index < end and frame["seq"] == 0 and frame["opcode"] in (205, 1024, 1027) and frame["hex"]
            if reply or push:
                seq = (recorded_seq if live_seq is None else live_seq) if reply else 0
                result.append({"opcode": frame["opcode"], "seq": seq, "hex": frame["hex"]})
        return result

    def test_select_does_not_receive_city_init_at_same_sequence(self):
        request = dict(self.by_seq[11], seq=12)
        responses = self.replay([request], chunk_size=7)
        self.assertEqual(len(responses), 1)
        self.assert_recorded_response(responses[0], 11, 12)

    def test_recruit_does_not_receive_battle_at_same_sequence(self):
        request = dict(self.by_seq[49], seq=36)
        responses = self.replay([request])
        self.assert_recorded_response(responses[0], 49, 36)

    def test_second_battle_uses_its_parameters_after_exact_first_battle(self):
        requests = [self.by_seq[36], dict(self.by_seq[61], seq=10000)]
        responses = [f for f in self.replay(requests) if f["seq"] != 0]
        self.assertEqual(len(responses), 2)
        self.assert_recorded_response(responses[0], 36)
        self.assert_recorded_response(responses[1], 61, 10000)

    def test_second_battle_can_resume_without_replaying_first_battle(self):
        responses = [f for f in self.replay([dict(self.by_seq[61], seq=10000)]) if f["seq"] != 0]
        self.assert_recorded_response(responses[0], 61, 10000)

    def test_unknown_battle_parameters_do_not_receive_a_different_battle(self):
        body = bytes.fromhex(self.by_seq[61]["hex"])
        point_two = b"\x08" + protocol.encode_varint(42101) + b"\x08\x02"
        self.assertEqual(body.count(point_two), 1)
        body = body.replace(point_two, b"\x08" + protocol.encode_varint(42101) + b"\x08\x63")
        responses = self.replay([dict(self.by_seq[61], seq=10000, hex=body.hex())])
        self.assertEqual(responses, [{"opcode": 999900, "seq": 10000, "hex": ""}])
        self.assertFalse(self.save_path.exists())

    def test_unrecorded_selection_does_not_create_a_role(self):
        body = bytes.fromhex(self.by_seq[11]["hex"])
        self.assertEqual(body.count(b"\x12\x02\x08\x03"), 1)
        body = body.replace(b"\x12\x02\x08\x03", b"\x12\x02\x08\x01")
        responses = self.replay([dict(self.by_seq[11], hex=body.hex())])
        self.assertEqual(responses, [{"opcode": 999900, "seq": 11, "hex": ""}])
        self.assertFalse(self.save_path.exists())

    def test_exact_ordinary_reply_advances_fallback_counter(self):
        hints = [f for f in self.requests if f["opcode"] == 1032 and not f["hex"]]
        responses = self.replay([hints[0], dict(hints[1], seq=10000)])
        self.assert_recorded_response(responses[0], hints[0]["seq"])
        self.assert_recorded_response(responses[1], hints[1]["seq"], 10000)

    def test_sessions_share_recordings_but_not_replay_counters(self):
        hints = [f for f in self.requests if f["opcode"] == 1032 and not f["hex"]]
        conn = ReplayConnection([], 4096)
        with redirect_stdout(io.StringIO()):
            first = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            second = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            for session in (first, first, second):
                for packet in session.handle(1032, 10000, bytes.fromhex(hints[0]["hex"])):
                    conn.sendall(packet)
        self.assertEqual(len(conn.responses), 3)
        for response, hint in zip(conn.responses, (hints[0], hints[1], hints[0])):
            self.assert_recorded_response(response, hint["seq"], 10000)

    def test_session_uses_explicit_save_path_without_entrypoint_patches(self):
        other_path = self.save_path.with_name("other_role.json")
        with redirect_stdout(io.StringIO()):
            first = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            second = Session(self.tables, other_path, self.step_counts, self.role_config)
            self.assertEqual(first.handle(201, 1, b"\x08\x01\x10\x03"),
                             [protocol.pack_frame(201, 1, b"\x08\x01")])
            self.assertEqual(second.handle(200, 2, b""), [protocol.pack_frame(200, 2, b"")])
        self.assertEqual(json.loads(self.save_path.read_text())["guide"]["sections"]["1"]["step"], 3)
        self.assertFalse(other_path.exists())

    def test_ordinary_sequence_hit_must_match_request_payload(self):
        self.assertNotEqual(self.by_seq[28]["hex"], self.by_seq[31]["hex"])
        responses = self.replay([dict(self.by_seq[28], seq=10000), dict(self.by_seq[31], seq=28)])
        self.assert_recorded_response(responses[0], 28, 10000)
        self.assert_recorded_response(responses[1], 31, 28)

    def test_ordinary_parameters_match_without_replaying_other_parameters_first(self):
        responses = self.replay([dict(self.by_seq[31], seq=10000), dict(self.by_seq[28], seq=10001)])
        self.assertEqual(len(responses), 2)
        self.assert_recorded_response(responses[0], 31, 10000)
        self.assert_recorded_response(responses[1], 28, 10001)
        self.assertFalse(self.save_path.exists())

    def test_ordinary_payload_counters_are_independent(self):
        responses = self.replay([self.by_seq[28], self.by_seq[31],
                                 dict(self.by_seq[124], seq=10000), dict(self.by_seq[52], seq=10001)])
        self.assertEqual(len(responses), 4)
        for response, recorded_seq, live_seq in zip(responses, (28, 31, 124, 52), (28, 31, 10000, 10001)):
            self.assert_recorded_response(response, recorded_seq, live_seq)

    def test_unknown_ordinary_payload_returns_empty_without_advancing_known_payload(self):
        requests = [dict(self.by_seq[31], seq=10000)]
        requests.extend({"opcode": 1032, "seq": seq, "hex": "08c404"} for seq in (28, 31, 10001))
        requests.append(dict(self.by_seq[52], seq=10002))
        responses = self.replay(requests, chunk_size=7)
        self.assertEqual(len(responses), len(requests))
        self.assert_recorded_response(responses[0], 31, 10000)
        self.assertEqual(responses[1:-1], [{"opcode": 1032, "seq": seq, "hex": ""} for seq in (28, 31, 10001)])
        self.assert_recorded_response(responses[-1], 52, 10002)
        self.assertFalse(self.save_path.exists())

    def test_unknown_ordinary_mutation_does_not_apply_pushes_or_spend(self):
        self.replay_through(131)
        original = self.save_path.read_bytes()
        self.clock.return_value = self.now + 360
        responses = self.replay([dict(self.by_seq[133], hex="0801")])
        self.assertEqual(responses, [{"opcode": 1057, "seq": 133, "hex": ""}])
        self.assertEqual(self.save_path.read_bytes(), original)

    def test_ordinary_routes_match_each_recorded_payload_from_a_new_replay(self):
        checked = set()
        for request in self.requests:
            opcode, body = request["opcode"], bytes.fromhex(request["hex"])
            key = opcode, body
            if opcode in (1000, 101, 200, 201, 999900) or key in checked:
                continue
            checked.add(key)
            with self.subTest(opcode=opcode, body=body), redirect_stdout(io.StringIO()):
                actual = replay.Replay(self.tables).match(opcode, 10000, body)
                self.assertEqual(actual, self.tables[3][request["seq"]][2])

    def test_local_login_uuid_remains_compatible_and_shares_login_counter(self):
        uuid = protocol.encode_pb_field(2, 2, b"local_mock_uuid_10001")
        login = protocol.encode_pb_field(1, 2, uuid).hex()
        responses = self.replay([dict(self.by_seq[1], seq=10000, hex=login), dict(self.by_seq[114], seq=10001)])
        self.assertEqual(len(responses), 2)
        self.assert_recorded_response(responses[0], 1, 10000)
        self.assert_recorded_response(responses[1], 114, 10001)
        self.assertFalse(self.save_path.exists())

    def test_city_init_embeds_saved_role_without_stale_initial_role(self):
        snapshot = self.recorded[(41, 1001)]["hex"]
        save = player.get_default_save()
        save["role_snapshot"] = snapshot
        self.save_path.write_text(json.dumps(save))
        responses = self.replay([self.by_seq[12]])
        self.assertEqual(len(responses), 1)
        role = next(data for mid, data in protocol.get_comb_messages(bytes.fromhex(responses[0]["hex"])) if mid == 1001)
        actual = {n: v for n, w, v in protocol.iter_pb_fields(role) if n not in (17, 18)}
        expected = {n: v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(snapshot)) if n not in (17, 18)}
        self.assertEqual(actual, expected)
        self.assertEqual((protocol.pb_get_varint(role, 17), protocol.pb_get_varint(role, 18)), (360, 1080))

    def test_custom_name_reaches_city_init_and_role_query(self):
        name = "本地玩家".encode("utf-8")
        body = b"\x0a" + protocol.encode_varint(len(name)) + name
        responses = self.replay([{"opcode": 101, "seq": 10000, "hex": body.hex()}, self.by_seq[11], self.by_seq[12]])
        self.assertEqual(self.role_data(responses[-1])[3], name)
        responses = self.replay([dict(self.by_seq[41], seq=20000)])
        self.assertEqual(self.role_data(responses[0])[3], name)

    def test_accepted_selection_persists_actual_requested_id(self):
        self.replay([self.by_seq[11]])
        saved = json.loads(self.save_path.read_text())
        self.assertEqual(saved["selected_general_id"], 3)
        self.assertTrue(saved["has_role"])

    def test_zero_role_values_override_recorded_nonzero_values(self):
        save = player.get_default_save()
        save["role_snapshot"] = self.recorded[(41, 1001)]["hex"]
        save["role_state"] = {"level": 2, "exp": 0, "coin": 0, "gold": 0, "power": 0}
        self.save_path.write_text(json.dumps(save))
        responses = self.replay([self.by_seq[12]])
        values = self.role_data(responses[0])
        self.assertEqual(values[5], 2)
        self.assertEqual([values[n] for n in (6, 8, 9, 14)], [0, 0, 0, 0])

    def test_first_battle_persists_role_progress_without_client_report(self):
        self.replay([self.by_seq[12], self.by_seq[36]])
        saved = json.loads(self.save_path.read_text())
        self.assertEqual(saved["level"], 2)
        self.assertEqual(saved["silver"], 2960)
        self.assertEqual(saved["gold"], 10)
        values = {n: v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(saved["role_snapshot"]))}
        self.assertEqual([values[n] for n in (5, 6, 8, 9, 10)], [2, 0, 2960, 10, 49])

    def test_reconnect_role_queries_cannot_change_progress_by_recording_sequence(self):
        self.replay([self.by_seq[12], self.by_seq[36]])
        responses = self.replay([self.by_seq[111], dict(self.by_seq[63], seq=20000)])
        for response in responses:
            self.assertEqual([self.role_data(response)[n] for n in (5, 8, 9)], [2, 2960, 10])

    def test_strengthen_spending_can_reach_zero_and_survive_reconnect(self):
        save = player.get_default_save()
        save["role_snapshot"] = self.recorded[(90, 1001)]["hex"]
        save["role_state"] = {"level": 4, "exp": 0, "coin": 11200, "gold": 0}
        self.save_path.write_text(json.dumps(save))
        self.replay([self.by_seq[99]])
        saved = json.loads(self.save_path.read_text())
        self.assertEqual(saved["silver"], 0)
        responses = self.replay([dict(self.by_seq[12], seq=20000)])
        self.assertEqual(self.role_data(responses[0])[8], 0)

    def test_all_recorded_role_rewards_and_costs_are_persisted(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        self.assertEqual([saved[k] for k in ("level", "silver", "gold")], [6, 123040, 100])
        self.assertEqual(saved["role_state"]["exp"], 1000)
        self.assertEqual(saved["role_state"]["power_all"], 5862)

    def test_insufficient_funds_do_not_change_save_or_emit_success(self):
        save = player.get_default_save()
        save["role_state"] = {"level": 4, "exp": 0, "coin": 1, "gold": 0}
        original = json.dumps(save)
        self.save_path.write_text(original)
        conn = ReplayConnection([self.by_seq[99]], 4096)
        with redirect_stdout(io.StringIO()):
            self.run_client(conn)
        self.assertTrue(conn.closed)
        self.assertEqual(conn.responses, [])
        self.assertEqual(self.save_path.read_text(), original)

    def test_failed_save_keeps_original_and_emits_no_success(self):
        save = player.get_default_save()
        save["role_state"] = {"level": 4, "exp": 0, "coin": 11200, "gold": 0}
        original = json.dumps(save)
        self.save_path.write_text(original)
        conn = ReplayConnection([self.by_seq[99]], 4096)
        with redirect_stdout(io.StringIO()), patch.object(player.os, "replace", side_effect=OSError("disk failure")):
            self.run_client(conn)
        self.assertTrue(conn.closed)
        self.assertEqual(conn.responses, [])
        self.assertEqual(self.save_path.read_text(), original)
        self.assertEqual([p.name for p in self.save_path.parent.iterdir() if not p.name.startswith('._')], ["role_save.json"])

    def test_entire_recorded_group_is_saved_before_first_push(self):
        conn = ReplayConnection([self.by_seq[36]], 7)
        sendall = conn.sendall

        def check_saved_before_send(packet):
            saved = json.loads(self.save_path.read_text())
            self.assertEqual((saved["level"], saved["silver"], saved["gold"]), (2, 2960, 10))
            self.assertEqual(saved["guide"]["sections"]["1"]["step"], 8)
            sendall(packet)

        conn.sendall = check_saved_before_send
        with redirect_stdout(io.StringIO()):
            self.run_client(conn)
        self.assertTrue(conn.closed)
        self.assertEqual(conn.responses, self.expected_group(36))

    def test_live_updates_do_not_acknowledge_failed_saves(self):
        original = json.dumps(player.get_default_save())
        self.save_path.write_text(original)
        for opcode, body in ((101, "0a046e616d65"), (201, "08011003"), (999898, "08010800080008000800")):
            with self.subTest(opcode=opcode):
                conn = ReplayConnection([{"opcode": opcode, "seq": 10000, "hex": body}], 7)
                with redirect_stdout(io.StringIO()), patch.object(player.os, "replace", side_effect=OSError("disk failure")):
                    self.run_client(conn)
                self.assertTrue(conn.closed)
                self.assertEqual(conn.responses, [])
                self.assertEqual(self.save_path.read_text(), original)

    def test_corrupt_save_is_not_silently_replaced(self):
        original = '{"unfinished":'
        self.save_path.write_text(original)
        self.assert_rejected(self.by_seq[12], "存档读取失败")
        self.assertEqual(self.save_path.read_text(), original)

    def test_malformed_name_does_not_change_existing_save(self):
        save = player.get_default_save()
        save["role_name"] = "已保存的名字"
        original = json.dumps(save)
        self.save_path.write_text(original)
        conn = ReplayConnection([{"opcode": 101, "seq": 10000, "hex": "0a05e69cac"}], 7)
        with redirect_stdout(io.StringIO()):
            self.run_client(conn)
        self.assertEqual(conn.responses, [])
        self.assertEqual(self.save_path.read_text(), original)

    def test_legacy_client_report_preserves_extended_fields_and_zero_balances(self):
        self.replay([self.by_seq[12], self.by_seq[36]])
        values = (2, 0, 0, 0, 0)
        body = b"".join(b"\x08" + protocol.encode_varint(value) for value in values)
        self.replay([{"opcode": 999898, "seq": 10000, "hex": body.hex()}])
        saved = json.loads(self.save_path.read_text())
        self.assertEqual([saved["role_state"][k] for k in ("coin", "gold", "power", "power_all", "stamina")], [0, 0, 0, 0, 49])

    def test_legacy_client_lower_experience_does_not_change_save(self):
        self.replay([self.by_seq[12], self.by_seq[36]])
        original = self.save_path.read_text()
        body = b"".join(b"\x08" + protocol.encode_varint(value) for value in (1, 0, 100, 10, 20))
        responses = self.replay([{"opcode": 999898, "seq": 10000, "hex": body.hex()}])
        self.assertEqual(responses, [{"opcode": 999898, "seq": 10000, "hex": "0801"}])
        self.assertEqual(self.save_path.read_text(), original)

    def test_field_replacement_preserves_unknown_fields_and_zero(self):
        raw = b"\x08\x05\x1a\x03old" + protocol.encode_pb_field(50, 5, b"1234")
        updated = protocol.pb_set_field(raw, 3, 2, "新名字".encode("utf-8"))
        updated = protocol.pb_set_varint(updated, 1, 0)
        self.assertEqual(list(protocol.iter_pb_fields(updated)), [(1, 0, 0), (3, 2, "新名字".encode("utf-8")), (50, 5, b"1234")])

    def test_protagonist_growth_is_not_general_level2(self):
        self.replay([self.by_seq[11], self.by_seq[12], self.by_seq[36]])
        saved = json.loads(self.save_path.read_text())
        values = {n: v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(saved["protagonist_snapshot"]))}
        general = {n: v for n, w, v in protocol.iter_pb_fields(values[10])}
        self.assertEqual((values[3], general[4]), (1, 0))

    def test_recruit_and_slot_updates_survive_reconnect_and_init(self):
        self.replay_through(56)
        roster = self.query_world(1002)
        generals = self.entity_records(roster, 1, 2)
        slots = self.entity_records(roster, 4, 1)
        self.assertTrue({7059, 7060}.issubset(generals))
        self.assertEqual(protocol.pb_get_varint(slots[2], 2), 7060)
        responses = self.replay([dict(self.by_seq[12], seq=30000)])
        restored = dict(protocol.get_comb_messages(bytes.fromhex(responses[0]["hex"])))[1002]
        self.assertEqual(restored, roster)

    def test_equipment_updates_merge_without_deleting_old_equipment(self):
        self.replay_through(99)
        roster = self.query_world(1002)
        equips = self.entity_records(roster, 2, 1)
        self.assertTrue({10719, 10720, 10721}.issubset(equips))
        reward = dict(protocol.get_comb_messages(bytes.fromhex(self.recorded[(99, 999900)]["hex"])))[1109]
        updated = [v for n, w, v in protocol.iter_pb_fields(reward) if n == 6 and w == 2]
        self.assertTrue(updated)
        for equip in updated:
            self.assertEqual(equips[protocol.pb_get_varint(equip, 1)], equip)

    def test_recruit_token_is_spent_and_starter_gift_is_preserved(self):
        self.replay_through(76)
        props = self.entity_records(self.query_world(1200), 1, 1)
        self.assertEqual(protocol.pb_get_varint(props[20111], 2), 1)
        self.assertNotIn(20100, props)

    def test_gift_rewards_consumption_and_training_cost_survive_reconnect(self):
        self.replay_through(148)
        props = self.entity_records(self.query_world(1200), 1, 1)
        self.assertNotIn(20111, props)
        self.assertEqual(protocol.pb_get_varint(props[20100], 2), 5)
        self.assertEqual(protocol.pb_get_varint(props[20161], 2), 47)
        fragments = self.entity_records(self.query_world(1012), 1, 1)
        self.assertEqual(protocol.pb_get_varint(fragments[10204], 2), 20)

    def test_resource_props_use_configured_delta_and_persist_batch_consumption(self):
        for cid, field, initial, delta in ((20014, 3, 0, 25), (20019, 3, 0, 50),
                                           (20015, 4, 20, 10), (20020, 4, 20, 20)):
            with self.subTest(cid=cid):
                self.seed_stamina(0)
                self.give_props({cid: 3})
                response = self.replay([self.activity_request(1201, (cid, 2))])[0]
                fields = list(protocol.iter_pb_fields(bytes.fromhex(response["hex"])))
                self.assertEqual(fields, [(field, 0, 2 * delta), (5, 2, b""), (7, 2, b""), (10, 2, b"")])
                role = self.query_role()
                self.assertEqual(role[{3: 10, 4: 12}[field]], initial + 2 * delta)
                props = self.entity_records(self.query_world(1200), 1, 1)
                self.assertEqual(protocol.pb_get_varint(props[cid], 2), 1)
                init = self.replay([dict(self.by_seq[12], seq=30000)])[0]
                self.assertEqual(self.role_data(init)[{3: 10, 4: 12}[field]], initial + 2 * delta)

    def test_claimed_daily_stamina_prop_is_usable_at_recorded_gift_sequence(self):
        self.replay(self.requests)
        self.replay([self.activity_request(3611, (80001,))])
        before = json.loads(self.save_path.read_text())["role_state"]
        request = dict(self.activity_request(1201, (20014, 1)), seq=148)
        response = self.replay([request])[0]
        self.assertEqual((response["opcode"], response["seq"]), (1201, 148))
        self.assertEqual(protocol.pb_get_varint(bytes.fromhex(response["hex"]), 3), 25)
        self.assertNotIn(20014, self.entity_records(self.query_world(1200), 1, 1))
        after = json.loads(self.save_path.read_text())["role_state"]
        self.assertEqual(after, {**before, "stamina": before["stamina"] + 25})
        self.assert_rejected(request, "道具 20014 数量不足")

    def test_resource_prop_reward_survives_later_tutorial_recordings(self):
        self.replay(self.requests)
        baseline = json.loads(self.save_path.read_text())["role_state"]
        self.save_path.unlink()
        self.replay_through(12)
        self.replay([self.activity_request(3611, (80001,)), self.activity_request(1201, (20014, 1))])
        self.replay([f for f in self.requests if f["seq"] > 12])
        saved = json.loads(self.save_path.read_text())["role_state"]
        self.assertEqual(saved, {**baseline, "coin": baseline["coin"] + 20000,
                                "gold": baseline["gold"] + 100, "stamina": baseline["stamina"] + 25})

    def test_resource_prop_use_settles_recovery_and_preserves_partial_interval(self):
        for elapsed, amount, remaining in ((100, 25, 260), (360, 26, 360)):
            with self.subTest(elapsed=elapsed):
                self.clock.return_value = self.now
                self.seed_stamina(0)
                self.give_props({20014: 1})
                self.query_role()
                self.clock.return_value = self.now + elapsed
                self.replay([self.activity_request(1201, (20014, 1))])
                role = self.query_role()
                self.assertEqual((role[10], role[17]), (amount, remaining))

    def test_resource_prop_can_exceed_soft_cap_and_stops_recovery(self):
        self.seed_stamina(49)
        self.give_props({20014: 1})
        self.query_role()
        self.clock.return_value = self.now + 100
        self.replay([self.activity_request(1201, (20014, 1))])
        self.clock.return_value = self.now + 100 * 360
        role = self.query_role()
        self.assertEqual((role[10], role[17], role[18]), (74, 0, 0))

    def test_resource_prop_consumes_once_per_request_in_same_session(self):
        self.seed_stamina(0)
        self.give_props({20015: 3})
        conn = ReplayConnection([self.activity_request(1201, (20015, 1)),
                                 self.activity_request(1201, (20015, 2))], 7)
        with redirect_stdout(io.StringIO()):
            self.run_client(conn)
        self.assertTrue(conn.closed)
        self.assertEqual([protocol.pb_get_varint(bytes.fromhex(f["hex"]), 4) for f in conn.responses], [10, 20])
        self.assertEqual(self.query_role()[12], 50)
        self.assertNotIn(20015, self.entity_records(self.query_world(1200), 1, 1))

    def test_resource_prop_batch_allows_client_limit_of_100(self):
        self.seed_stamina(0)
        self.give_props({20020: 101})
        self.replay([self.activity_request(1201, (20020, 100))])
        self.assertEqual(self.query_role()[12], 2020)
        self.assert_rejected(self.activity_request(1201, (20020, 101)), "恢复道具使用参数无效")

    def test_resource_prop_insufficient_quantity_does_not_partially_consume(self):
        self.seed_stamina(0)
        self.give_props({20014: 1})
        self.assert_rejected(self.activity_request(1201, (20014, 2)), "道具 20014 数量不足")

    def test_resource_prop_integer_overflow_keeps_inventory_and_role(self):
        for cid, name in ((20014, "stamina"), (20020, "energy")):
            with self.subTest(cid=cid):
                self.seed_stamina(0)
                self.give_props({cid: 1})
                saved = json.loads(self.save_path.read_text())
                saved["role_state"][name] = (1 << 31) - 10
                self.save_path.write_text(json.dumps(saved))
                self.assert_rejected(self.activity_request(1201, (cid, 1)), "恢复资源超出范围")

    def test_resource_prop_save_failure_is_atomic_with_due_recovery(self):
        self.seed_stamina(0)
        self.give_props({20014: 1})
        self.query_role()
        self.clock.return_value = self.now + 360
        with patch.object(player.os, "replace", side_effect=OSError("disk failure")):
            self.assert_rejected(self.activity_request(1201, (20014, 1)), "保存失败")
        self.assertEqual(self.query_role()[10], 1)
        self.assertEqual(protocol.pb_get_varint(self.entity_records(self.query_world(1200), 1, 1)[20014], 2), 1)

    def test_malformed_resource_prop_use_does_not_change_save(self):
        self.seed_stamina(0)
        self.give_props({20014: 2})
        valid = bytes.fromhex(self.activity_request(1201, (20014, 1))["hex"])
        for body in (b"", valid[:-2], valid[:-1], valid + b"\x08\x01", valid + b"\x10\x01",
                     valid[:-1] + b"\x00", valid[:-2] + b"\x0a\x01\x01",
                     valid[:-1] + protocol.encode_varint((1 << 64) - 1)):
            with self.subTest(body=body):
                self.assert_rejected({"opcode": 1201, "seq": 20000, "hex": body.hex()}, "道具")

    def test_resource_prop_use_without_created_role_is_rejected(self):
        self.save_path.write_text(json.dumps(player.get_default_save()))
        self.assert_rejected(self.activity_request(1201, (20014, 1)), "角色尚未创建")

    def test_unsupported_resource_prop_is_not_silently_consumed(self):
        self.seed_stamina(0)
        self.give_props({20013: 1})
        self.assert_rejected(self.activity_request(1201, (20013, 1)), "暂不支持的恢复道具")

    def test_item_and_fragment_deltas_add_consume_and_remove_zero(self):
        self.replay_through(12)
        saved = json.loads(self.save_path.read_text())
        for cid, query, key in ((20100, "1200", 20100), (11204, "1012", 10204), (10204, "1012", 10204)):
            with self.subTest(cid=cid):
                player.change_item_count(saved, cid, 2, self.role_config)
                record = protocol.encode_pb_field(1, 0, cid) + protocol.encode_pb_field(2, 0, 1)
                used = protocol.encode_pb_field(10, 2, protocol.encode_pb_field(1, 2, record))
                player.apply_reward(saved, used, self.role_config)
                records = self.entity_records(bytes.fromhex(saved["world_state"][query]), 1, 1)
                self.assertEqual(protocol.pb_get_varint(records[key], 2), 1)
                player.change_item_count(saved, cid, -1, self.role_config)
                self.assertNotIn(key, self.entity_records(bytes.fromhex(saved["world_state"][query]), 1, 1))
                for delta in (-1, 1 << 31):
                    with self.assertRaises(ValueError):
                        player.change_item_count(saved, cid, delta, self.role_config)

    def test_cleared_maps_and_claimed_box_survive_reconnect(self):
        self.replay_through(138)
        maps = self.entity_records(self.query_world(1300), 1, 1)
        self.assertTrue({42101, 42102}.issubset(maps))
        self.assertEqual(protocol.pb_get_varint(maps[42101], 2), 3)
        self.assertEqual(protocol.pb_get_varint(maps[42101], 6), 3)
        points = self.entity_records(maps[42101], 7, 1)
        self.assertEqual(set(points), {1, 2, 3, 4, 5})
        self.assertTrue(all(protocol.pb_get_varint(p, 3) == 3 and protocol.pb_get_varint(p, 4) == 1 for p in points.values()))
        point = self.entity_records(maps[42102], 7, 1)[1]
        self.assertEqual(protocol.pb_get_varint(point, 3), 3)

    def test_consumed_gift_cannot_grant_rewards_twice(self):
        self.replay_through(148)
        self.assert_rejected(self.by_seq[148], "道具 20111 数量不足")

    def test_replayed_old_battle_cannot_overwrite_newer_state(self):
        self.replay_through(61)
        self.assert_rejected(self.by_seq[36], "已通关关卡不支持重复录制战斗")

    def test_missing_legacy_world_history_does_not_allow_old_battle(self):
        self.replay_through(138)
        saved = json.loads(self.save_path.read_text())
        del saved["world_state"]
        self.save_path.write_text(json.dumps(saved))
        self.assert_rejected(self.by_seq[36], "战斗录制经验已过期")

    def test_existing_role_cannot_be_recreated_by_old_selection(self):
        self.replay_through(61)
        self.assert_rejected(self.by_seq[11], "角色已创建")

    def test_empty_saved_inventory_is_not_reseeded_on_reconnect(self):
        self.replay_through(12)
        saved = json.loads(self.save_path.read_text())
        saved["world_state"]["1200"] = ""
        saved["world_state"]["1012"] = ""
        self.save_path.write_text(json.dumps(saved))
        for _ in range(2):
            self.assertEqual(self.query_world(1200), b"")
            self.assertEqual(self.query_world(1012), b"")
        self.assert_rejected(self.by_seq[148], "道具 20111 数量不足")

    def test_invalid_world_cache_is_not_sent_or_overwritten(self):
        self.replay_through(12)
        valid = json.loads(self.save_path.read_text())
        cases = (("1002", []), ("1200", "zz"), ("1300", "0a"),
                 ("1200", "0a03080180"), ("1002", "0a020801"),
                 ("1300", "0a0508013a0180"), ("1200", "0a020801"))
        for opcode, invalid in cases:
            with self.subTest(opcode=opcode, invalid=invalid):
                saved = json.loads(json.dumps(valid))
                saved["world_state"][opcode] = invalid
                self.save_path.write_text(json.dumps(saved))
                self.assert_rejected(self.by_seq[12], "载入玩家状态失败")

    def test_partial_slot_updates_preserve_other_entities_and_unknown_fields(self):
        extra = protocol.encode_pb_field(50, 2, b"keep")
        first = b"\x08\x01\x10\x09"
        second = b"\x08\x02\x10\x08"
        base = protocol.encode_pb_field(4, 2, first) + extra + protocol.encode_pb_field(4, 2, second)
        cleared = b"\x08\x01\x10\x00"
        merged = player.merge_pb_records(base, protocol.encode_pb_field(4, 2, cleared), player.SLOT_RECORD_KEYS)
        self.assertEqual(self.entity_records(merged, 4, 1), {1: cleared, 2: second})
        self.assertIn((50, 2, b"keep"), list(protocol.iter_pb_fields(merged)))

    def test_locked_copy_box_cannot_grant_rewards(self):
        self.replay_through(12)
        self.assert_rejected(self.by_seq[119], "副本宝箱未解锁或已领取")

    def test_claimed_copy_box_cannot_grant_rewards_twice(self):
        self.replay_through(119)
        self.assert_rejected(self.by_seq[119], "副本宝箱未解锁或已领取")

    def test_gift_save_failure_keeps_items_rewards_and_guide_atomic(self):
        self.replay_through(138)
        with patch.object(player.os, "replace", side_effect=OSError("disk failure")):
            self.assert_rejected(self.by_seq[148], "保存失败")
        self.assertEqual([p.name for p in self.save_path.parent.iterdir() if not p.name.startswith('._')], ["role_save.json"])

    def test_recruit_requires_a_token_and_cannot_reset_owned_generals(self):
        self.replay_through(12)
        self.assert_rejected(self.by_seq[76], "道具 20100 数量不足")
        self.replay([f for f in self.requests if 12 < f["seq"] <= 148])
        for seq in (49, 76):
            with self.subTest(seq=seq):
                self.assert_rejected(self.by_seq[seq], "不支持重复录制招募")

    def test_old_training_and_advancement_cannot_revert_newer_growth(self):
        self.replay_through(138)
        self.assert_rejected(self.by_seq[131], "已过期的主角培养")
        self.assert_rejected(self.by_seq[133], "已过期的主角进阶")

    def test_tutorial_reconnect_after_every_request_keeps_world_state(self):
        self.replay(self.requests)
        expected = {opcode: self.query_world(opcode) for opcode in player.WORLD_QUERY_IDS}
        expected_role = json.loads(self.save_path.read_text())["role_state"]
        self.save_path.unlink()
        for request in self.requests:
            self.replay([request], chunk_size=7)
            self.replay([dict(self.by_seq[12], seq=30000)])
        for opcode, body in expected.items():
            with self.subTest(opcode=opcode):
                self.assertEqual(self.query_world(opcode), body)
        self.assertEqual(json.loads(self.save_path.read_text())["role_state"], expected_role)

    def test_first_battle_restores_state_pushes_in_recorded_order(self):
        responses = self.replay([dict(self.by_seq[36], seq=10000)], chunk_size=7)
        self.assertEqual([f["opcode"] for f in responses], [1027, 205, 1024, 999900])
        self.assertEqual(responses, self.expected_group(36, 10000))

    def test_state_push_after_response_stays_after_response(self):
        responses = self.replay([dict(self.by_seq[97], seq=10000)])
        self.assertEqual([f["opcode"] for f in responses], [999900, 205])
        self.assertEqual(responses, self.expected_group(97, 10000))

    def test_ordinary_exact_and_fallback_restore_state_pushes(self):
        for seq in (133, 10000):
            with self.subTest(seq=seq):
                save = player.get_default_save()
                save["role_snapshot"] = self.recorded[(111, 1001)]["hex"]
                self.save_path.write_text(json.dumps(save))
                responses = self.replay([dict(self.by_seq[133], seq=seq)])
                self.assertEqual([f["opcode"] for f in responses], [205, 1057])
                self.assertEqual(responses, self.expected_group(133, seq))
                self.assertEqual(json.loads(self.save_path.read_text())["silver"], 6720)

    def test_reply_after_another_request_is_not_lost(self):
        self.assertEqual([self.by_seq[seq]["opcode"] for seq in (91, 92)], [2000, 201])
        responses = self.replay([self.by_seq[91], self.by_seq[92]])
        self.assertEqual(len(responses), 2)
        self.assert_recorded_response(responses[0], 91)
        self.assert_recorded_response(responses[1], 92)

    def test_state_push_without_matching_reply_is_not_attached_to_request(self):
        push = self.expected_group(36)[1]
        frames = [self.by_seq[12], self.recorded[(12, 999900)], self.by_seq[36],
                  dict(push, c2s=False), dict(self.recorded[(36, 999900)], seq=999)]
        with redirect_stdout(io.StringIO()):
            self.tables = replay.build_routing_tables(frames)
        responses = self.replay([dict(self.by_seq[36], seq=10000)])
        self.assertEqual(responses, [{"opcode": 999900, "seq": 10000, "hex": ""}])
        self.assertFalse(self.save_path.exists())

    def test_combination_guide_progress_is_saved_and_returned_after_reconnect(self):
        self.replay([dict(self.by_seq[36], seq=10000)])
        self.assertTrue(self.save_path.exists())
        saved = json.loads(self.save_path.read_text())
        self.assertEqual(saved["guide"]["sections"]["1"], {"status": 1, "step": 8, "steps": [8]})
        responses = self.replay([{"opcode": 200, "seq": 20000, "hex": ""}])
        self.assertEqual(responses, [{"opcode": 200, "seq": 20000, "hex": "0a06080110011808"}])

    def test_standalone_and_combination_reports_share_step_history(self):
        self.replay([{"opcode": 201, "seq": 10000, "hex": "08011003"}, self.by_seq[11]])
        saved = json.loads(self.save_path.read_text())
        self.assertTrue(saved["has_role"])
        self.assertEqual(saved["guide"]["sections"]["1"], {"status": 1, "step": 4, "steps": [3, 4]})

    def test_combination_progress_preserves_legacy_save_history(self):
        save = player.get_default_save()
        save["guide"] = {"section": 1, "status": 0, "step": 7}
        self.save_path.write_text(json.dumps(save))
        self.replay([self.by_seq[36]])
        saved = json.loads(self.save_path.read_text())
        self.assertEqual(saved["guide"]["sections"]["1"], {"status": 1, "step": 8, "steps": [7, 8]})

    def test_completion_uses_configured_step_count(self):
        total = self.step_counts[1]
        for step, status in ((total - 1, 1), (total, 2)):
            body = b"\x08\x01\x10" + protocol.encode_varint(step)
            self.replay([{"opcode": 201, "seq": 10000, "hex": body.hex()}])
            saved = json.loads(self.save_path.read_text())
            self.assertEqual(saved["guide"]["sections"]["1"]["status"], status)

    def test_guide_tail_requires_both_display_steps_and_survives_reconnect(self):
        self.replay(self.requests)
        for step, status in ((81, 1), (82, 1), (83, 2)):
            with self.subTest(step=step):
                body = protocol.encode_pb_field(1, 0, 1) + protocol.encode_pb_field(2, 0, step)
                self.replay([{"opcode": 201, "seq": 20000, "hex": body.hex()}])
                response = self.replay([{"opcode": 200, "seq": 20001, "hex": ""}])[0]
                self.assertEqual(bytes.fromhex(response["hex"]), guide.build_guide_query_pb({"1": {"status": status, "step": step}}))

    def test_server_time_is_live_and_keeps_captured_timezone(self):
        timezone = protocol.parse_ids_pb(bytes.fromhex(self.recorded[(3, 999905)]["hex"]))[1]
        for offset, seq in ((0, 3), (17, 10000)):
            with self.subTest(offset=offset):
                self.clock.return_value = self.now + offset
                responses = self.replay([{"opcode": 999905, "seq": seq, "hex": ""}])
                self.assertEqual((responses[0]["opcode"], responses[0]["seq"]), (999905, seq))
                self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(responses[0]["hex"])), [self.now + offset, timezone])
        self.assertFalse(self.save_path.exists())

    def test_stamina_interval_is_consistent_with_all_captured_countdowns(self):
        samples = []
        for frame in self.frames:
            if frame["c2s"]:
                continue
            body = bytes.fromhex(frame["hex"])
            messages = protocol.get_comb_messages(body) if frame["opcode"] == 999900 else [(frame["opcode"], body)]
            for opcode, raw in messages:
                if opcode == 1001:
                    values = {n: v for n, w, v in protocol.iter_pb_fields(raw)}
                    missing = values[11] - values[10]
                    if missing > 1:
                        self.assertEqual(values[18] - values[17], (missing - 1) * 360)
                        samples.append(raw)
        self.assertTrue(samples)

    def test_legacy_stamina_does_not_recover_from_recorded_wall_clock(self):
        self.seed_stamina(0)
        role = self.query_role()
        self.assertEqual((role[10], role[17], role[18]), (0, 360, 50 * 360))
        snapshot = bytes.fromhex(self.recorded[(41, 1001)]["hex"])
        for field in (15, 16, 22):
            self.assertEqual(role.get(field), protocol.pb_get_varint(snapshot, field))

    def test_stamina_recovers_at_boundary_and_preserves_partial_interval(self):
        self.seed_stamina(0)
        self.query_role()
        for elapsed, amount, remaining in ((359, 0, 1), (360, 1, 360), (731, 2, 349)):
            with self.subTest(elapsed=elapsed):
                self.clock.return_value = self.now + elapsed
                role = self.query_role()
                self.assertEqual((role[10], role[17], role[18]), (amount, remaining, remaining + (50 - amount - 1) * 360))
                self.assertEqual(json.loads(self.save_path.read_text())["role_state"]["stamina"], amount)

    def test_stamina_offline_recovery_survives_reconnect_without_double_credit(self):
        self.seed_stamina(5)
        self.query_role()
        self.clock.return_value = self.now + 4 * 360 + 21
        first = self.query_role()
        second = self.query_role()
        self.assertEqual((first[10], first[17]), (9, 339))
        self.assertEqual((second[10], second[17]), (9, 339))
        init = self.replay([dict(self.by_seq[12], seq=30000)])[0]
        role = self.role_data(init)
        self.assertEqual((role[10], role[17], role[18]), (9, 339, 339 + 40 * 360))

    def test_stamina_recovery_caps_without_clamping_reward_overflow(self):
        for amount in (49, 50, 65):
            with self.subTest(amount=amount):
                self.clock.return_value = self.now
                self.seed_stamina(amount)
                self.query_role()
                self.clock.return_value = self.now + 100 * 360
                role = self.query_role()
                self.assertEqual((role[10], role[17], role[18]), (max(50, amount), 0, 0))

    def test_full_stamina_does_not_bank_recovery_before_battle(self):
        self.seed_stamina(50)
        self.query_role()
        self.clock.return_value = self.now + 100 * 360
        self.replay([self.by_seq[36]])
        role = self.query_role()
        self.assertEqual((role[10], role[11], role[17], role[18]), (49, 52, 360, 1080))

    def test_stamina_recovery_is_settled_before_battle_cost(self):
        self.seed_stamina(0)
        self.query_role()
        self.clock.return_value = self.now + 359
        self.assert_rejected(self.by_seq[36], "体力不足")
        self.clock.return_value = self.now + 360
        self.replay([self.by_seq[36]])
        role = self.query_role()
        self.assertEqual((role[10], role[17]), (0, 360))

    def test_stamina_deadline_survives_spending_in_same_session(self):
        self.seed_stamina(5)
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            session.handle(1001, 20000, b"")
            self.clock.return_value = self.now + 100
            request = self.by_seq[36]
            session.handle(request["opcode"], request["seq"], bytes.fromhex(request["hex"]))
            for elapsed, amount, remaining in ((100, 4, 260), (360, 5, 360), (360, 5, 360)):
                self.clock.return_value = self.now + elapsed
                packet = session.handle(1001, 20001, b"")[0]
                role = {n: v for n, w, v in protocol.iter_pb_fields(packet[16:])}
                self.assertEqual((role[10], role[17]), (amount, remaining))

    def test_recovered_stamina_and_battle_are_saved_before_first_push(self):
        self.seed_stamina(0)
        self.query_role()
        self.clock.return_value = self.now + 360
        conn = ReplayConnection([self.by_seq[36]], 7)
        sendall = conn.sendall

        def check_saved_before_send(packet):
            saved = json.loads(self.save_path.read_text())
            self.assertEqual((saved["role_state"]["stamina"], saved["level"]), (0, 2))
            self.assertEqual(saved["stamina_clock"]["next_at"], self.now + 720)
            self.assertEqual(saved["guide"]["sections"]["1"]["step"], 8)
            self.assertEqual(protocol.pb_get_varint(bytes.fromhex(saved["role_snapshot"]), 17), 360)
            sendall(packet)

        conn.sendall = check_saved_before_send
        with redirect_stdout(io.StringIO()):
            self.run_client(conn)
        self.assertTrue(conn.closed)
        self.assertEqual(conn.responses, self.expected_group(36))

    def test_clock_rollback_does_not_grant_stamina_or_shorten_next_recovery(self):
        self.seed_stamina(0)
        self.query_role()
        self.clock.return_value = self.now + 400
        self.assertEqual(self.query_role()[10], 1)
        self.clock.return_value = self.now - 100
        role = self.query_role()
        self.assertEqual((role[10], role[17]), (1, 820))
        self.clock.return_value = self.now + 720
        self.assertEqual(self.query_role()[10], 2)

    def test_stamina_recovery_save_failure_keeps_original_and_emits_no_success(self):
        self.seed_stamina(0)
        self.query_role()
        self.clock.return_value = self.now + 360
        for request in (dict(self.by_seq[41], seq=20000), self.by_seq[36]):
            with self.subTest(opcode=request["opcode"]), patch.object(player.os, "replace", side_effect=OSError("disk failure")):
                self.assert_rejected(request, "保存失败")
        self.assertEqual(self.query_role()[10], 1)

    def test_invalid_stamina_clock_is_not_overwritten(self):
        self.seed_stamina(0)
        original = json.loads(self.save_path.read_text())
        for invalid in ([], {}, None, {"next_at": self.now + 360},
                        {"next_at": -1, "checked_at": self.now},
                        {"next_at": self.now + 360, "checked_at": True},
                        {"next_at": "old", "checked_at": self.now}):
            with self.subTest(invalid=invalid):
                saved = json.loads(json.dumps(original))
                saved["stamina_clock"] = invalid
                self.save_path.write_text(json.dumps(saved))
                self.assert_rejected(dict(self.by_seq[41], seq=20000), "体力计时存档无效")

    def test_malformed_time_query_does_not_change_save(self):
        self.seed_stamina(0)
        self.query_role()
        self.clock.return_value = self.now + 360
        self.assert_rejected({"opcode": 999905, "seq": 20000, "hex": "0801"}, "时间查询不接受参数")

    def test_late_guide_reports_do_not_rewind_or_reopen_completed_sections(self):
        for saved_step, saved_status in ((82, 1), (83, 2), (81, 2)):
            with self.subTest(saved_step=saved_step, saved_status=saved_status):
                saved = player.get_default_save()
                saved["guide"]["sections"]["1"] = {"status": saved_status, "step": saved_step, "steps": [saved_step]}
                self.save_path.write_text(json.dumps(saved))
                self.replay([{"opcode": 201, "seq": 20000, "hex": "08011050"}])
                section = json.loads(self.save_path.read_text())["guide"]["sections"]["1"]
                self.assertEqual((section["step"], section["status"]), (saved_step, saved_status))
                self.assertIn(80, section["steps"])

    def test_guide_report_outside_config_cannot_complete_section(self):
        self.replay_through(12)
        for section, step in ((1, self.step_counts[1] + 1), (99999, 1)):
            with self.subTest(section=section, step=step):
                body = protocol.encode_pb_field(1, 0, section) + protocol.encode_pb_field(2, 0, step)
                self.assert_rejected({"opcode": 201, "seq": 20000, "hex": body.hex()}, "引导上报超出配置")

    def test_recorded_activity_rewards_are_generated_and_persisted(self):
        self.replay(self.requests)
        previous = json.loads(self.save_path.read_text())
        for frame in self.activity_frames["rewards"]:
            request = {"opcode": frame["opcode"], "seq": frame["seq"], "hex": frame["request"]}
            response = self.replay([request])[0]
            actual = bytes.fromhex(response["hex"])
            expected = bytes.fromhex(frame["response"])
            if frame["opcode"] == 3611 and protocol.parse_ids_pb(bytes.fromhex(frame["request"])) == [80030]:
                actual_equip = next(v for n, w, v in protocol.iter_pb_fields(actual) if n == 6)
                expected_equip = next(v for n, w, v in protocol.iter_pb_fields(expected) if n == 6)
                self.assertEqual(protocol.parse_ids_pb(actual_equip)[1:], protocol.parse_ids_pb(expected_equip)[1:])
                self.assertGreater(protocol.parse_ids_pb(actual_equip)[0], 1000000)
                self.assertEqual([(n,w,v) for n,w,v in protocol.iter_pb_fields(actual) if n != 6],
                                 [(n,w,v) for n,w,v in protocol.iter_pb_fields(expected) if n != 6])
            else:
                self.assertEqual(actual, expected)
        saved = json.loads(self.save_path.read_text())
        self.assertEqual(saved["silver"] - previous["silver"], 32000)
        self.assertEqual(saved["gold"] - previous["gold"], 150)
        props = self.entity_records(self.query_world(1200), 1, 1)
        self.assertEqual(protocol.pb_get_varint(props[20014], 2), 1)
        equips = self.entity_records(self.query_world(1002), 2, 1)
        self.assertTrue(any(protocol.parse_ids_pb(equip)[1] == 22204 and iid > 1000000 for iid, equip in equips.items()))

    def test_activity_fixture_frames_match_raw_capture(self):
        capture = (Path(server.BASE_DIR) / self.activity_frames["source"]).read_bytes()
        # These selected replies each fit in one captured TCP segment.
        for frame in self.activity_frames["queries"] + self.activity_frames["rewards"]:
            with self.subTest(opcode=frame["opcode"], seq=frame["seq"]):
                packet = protocol.pack_frame(frame["opcode"], frame["seq"], bytes.fromhex(frame["response"]))
                self.assertTrue(packet in capture, "fixture does not match its source capture")

    def test_activity_claims_are_rejected_when_locked_or_repeated(self):
        self.replay_through(12)
        for opcode, values in ((3611, (80030,)), (2411, (116,)), (3611, (80015,)), (3611, (80002,))):
            with self.subTest(opcode=opcode, values=values):
                self.assert_rejected(self.activity_request(opcode, values), "活动奖励未解锁或不支持")
        self.replay([self.activity_request(3611, (80001,))])
        self.assert_rejected(self.activity_request(3611, (80001,)), "活动奖励已领取")
        self.replay([f for f in self.requests if f["seq"] > 12])
        for opcode, values in ((3611, (80030,)), (2411, (116,))):
            self.replay([self.activity_request(opcode, values)])
            self.assert_rejected(self.activity_request(opcode, values), "活动奖励已领取")

    def test_activity_queries_restore_claim_flags_and_liveness_score(self):
        self.replay(self.requests)
        before = self.begin7day_groups(self.query_world(3610))
        recorded_before = self.begin7day_groups(bytes.fromhex(self.activity_frames["queries"][0]["response"]))
        self.assertEqual((before[0], before[1][0], before[1][29]), (recorded_before[0], 1, 1))
        for opcode, values in ((3611, (80001,)), (3611, (80030,)), (2411, (116,))):
            self.replay([self.activity_request(opcode, values)])
        after = self.begin7day_groups(self.query_world(3610))
        self.assertEqual((after[1][0], after[1][29]), (2, 2))
        liveness = [v for n,w,v in protocol.iter_pb_fields(self.query_world(2410)) if n == 1]
        recorded = [v for n,w,v in protocol.iter_pb_fields(bytes.fromhex(self.activity_frames["queries"][3]["response"])) if n == 1]
        self.assertEqual(len(liveness), len(recorded))
        self.assertEqual((liveness[15], liveness[len(liveness)//2+15]), (2, 4))
        self.assertEqual(self.query_world(6517).hex(), self.activity_frames["queries"][5]["response"])
        init = self.replay([dict(self.by_seq[12], seq=30000)])[0]
        restored = dict(protocol.get_comb_messages(bytes.fromhex(init["hex"])))[3610]
        self.assertEqual(restored, self.query_world(3610))

    def test_activity_save_failure_is_atomic(self):
        self.replay(self.requests)
        for opcode, values in ((3611, (80001,)), (3611, (80030,)), (2411, (116,))):
            with self.subTest(opcode=opcode, values=values), patch.object(player.os, "replace", side_effect=OSError("disk failure")):
                self.assert_rejected(self.activity_request(opcode, values), "保存失败")

    def test_activity_equipment_does_not_collide_with_later_recorded_drops(self):
        self.replay_through(107)
        reward = self.replay([self.activity_request(3611, (80030,))])[0]
        equipment = next(v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(reward["hex"])) if n == 6)
        iid = protocol.parse_ids_pb(equipment)[0]
        self.replay([f for f in self.requests if f["seq"] > 107])
        self.assertEqual(self.entity_records(self.query_world(1002), 2, 1)[iid], equipment)

    def test_activity_inventory_overflow_cannot_partially_grant_reward(self):
        self.replay_through(12)
        saved = json.loads(self.save_path.read_text())
        player.change_item_count(saved, 20014, (1 << 31) - 1, self.role_config)
        self.save_path.write_text(json.dumps(saved))
        self.assert_rejected(self.activity_request(3611, (80001,)), "超出范围")

    def test_invalid_activity_state_is_not_overwritten(self):
        self.replay_through(12)
        original = json.loads(self.save_path.read_text())
        for key, value in (("strengthen_count", -1), ("strengthen_count", True),
                           ("begin7day_claimed", "bad"), ("liveness_claimed", [16, 16])):
            with self.subTest(key=key, value=value):
                saved = json.loads(json.dumps(original))
                saved["activity_state"][key] = value
                self.save_path.write_text(json.dumps(saved))
                self.assert_rejected(self.activity_request(3610), "载入玩家状态失败")

    def test_activity_claim_before_role_creation_is_rejected(self):
        self.save_path.write_text(json.dumps(player.get_default_save()))
        self.assert_rejected(self.activity_request(3611, (80001,)), "活动奖励未解锁或不支持")

    def test_malformed_activity_claim_does_not_mutate_save(self):
        self.replay(self.requests)
        for opcode in (3611, 2411):
            for body in ("", "0800", "08", "08010802", "0a0101"):
                with self.subTest(opcode=opcode, body=body):
                    self.assert_rejected({"opcode": opcode, "seq": 20000, "hex": body}, "活动请求格式错误")

    def test_all_19_combination_guide_steps_are_persisted(self):
        requests = [f for f in self.requests if f["opcode"] == 999900 and 201 in protocol.get_comb_ids(bytes.fromhex(f["hex"]))]
        self.assertEqual(len(requests), 19)
        self.replay(requests)
        self.assertTrue(self.save_path.exists())
        saved = json.loads(self.save_path.read_text())
        expected = [4, 8, 13, 19, 22, 30, 36, 39, 44, 45, 48, 51, 56, 60, 66, 71, 78, 79, 80]
        self.assertEqual(saved["guide"]["sections"]["1"], {"status": 1, "step": 80, "steps": expected})

    def test_failed_combination_guide_ack_does_not_advance_progress(self):
        reply = self.recorded[(36, 999900)]
        self.assertTrue(reply["hex"].endswith("0801"))
        frames = [self.by_seq[12], self.recorded[(12, 999900)], self.by_seq[36], dict(reply, hex=reply["hex"][:-2] + "00")]
        with redirect_stdout(io.StringIO()):
            self.tables = replay.build_routing_tables(frames)
        self.replay([self.by_seq[36]])
        self.assertEqual(json.loads(self.save_path.read_text())["guide"]["sections"], {})

    def test_malformed_guide_report_does_not_overwrite_save(self):
        save = player.get_default_save()
        save["guide"]["sections"] = {"1": {"status": 1, "step": 5, "steps": [5]}}
        original = json.dumps(save)
        self.save_path.write_text(original)
        for body in ("", "0801", "08011080", "08011000", "080110" + "ff" * 10):
            with self.subTest(body=body):
                conn = ReplayConnection([{"opcode": 201, "seq": 10000, "hex": body}], 7)
                with redirect_stdout(io.StringIO()):
                    self.run_client(conn)
                self.assertTrue(conn.closed)
                self.assertEqual(conn.responses, [])
                self.assertEqual(self.save_path.read_text(), original)

    def test_combination_parser_validates_lengths_and_required_ids(self):
        messages = protocol.get_comb_messages(bytes.fromhex(self.by_seq[11]["hex"]))
        self.assertEqual(messages, [(202, b"\x08\x03"), (201, b"\x08\x01\x10\x04")])
        for raw in (b"\x0a\x05\x08\xca", b"\x0a\x02\x12\x00", b"\x0a\x04\x08\xca\x01\x12", b"\x00", b"\x0e", b"\x80" * 11):
            with self.subTest(raw=raw):
                with self.assertRaises(ValueError):
                    protocol.get_comb_messages(raw)

    def test_parser_accepts_optional_data_unknown_fields_and_uint64(self):
        self.assertEqual(protocol.get_comb_messages(b"\x0a\x05\x08\xca\x01\x18\x01\x10\x01"), [(202, b"")])
        maximum = (1 << 64) - 1
        encoded = protocol.encode_varint(maximum)
        self.assertEqual(protocol.parse_varint(encoded, 0), (maximum, len(encoded)))

    def test_recorded_tutorial_responses_survive_combination_sequence_changes(self):
        # The second login is a reconnect; keep the isolated save but reset connection counters.
        sessions = []
        for frame in self.requests:
            if frame["opcode"] == 1000:
                sessions.append([])
            sessions[-1].append(frame)
        for shift in (0, 10000):
            self.save_path.unlink(missing_ok=True)
            push_count = 0
            for session in sessions:
                requests = [dict(f, seq=f["seq"] + shift) if f["opcode"] == 999900 else f for f in session]
                responses = self.replay(requests, chunk_size=31)
                expected = []
                for original, request in zip(session, requests):
                    expected.extend(self.expected_group(original["seq"], request["seq"]))
                self.assertEqual([(f["opcode"], f["seq"]) for f in responses], [(f["opcode"], f["seq"]) for f in expected])
                for actual, recorded in zip(responses, expected):
                    with self.subTest(shift=shift, seq=actual["seq"], opcode=actual["opcode"]):
                        self.assert_replayed_payload(actual["opcode"], actual["hex"], recorded["hex"])
                replies = [f for f in responses if f["seq"] != 0]
                push_count += len(responses) - len(replies)
                self.assertEqual(len(replies), len(requests))
                for original, request, response in zip(session, requests, replies):
                    with self.subTest(shift=shift, seq=original["seq"], opcode=original["opcode"]):
                        self.assertEqual(response["opcode"], request["opcode"])
                        self.assertEqual(response["seq"], request["seq"])
            self.assertEqual(push_count, 33)


class EntryPointTests(unittest.TestCase):
    def test_import_from_other_directory_does_not_load_assets_or_start_io(self):
        root = Path(server.__file__).parent
        code = (
            "from unittest.mock import patch\n"
            "with patch('zipfile.ZipFile', side_effect=AssertionError('config read')), "
            "patch('socket.socket', side_effect=AssertionError('socket opened')), "
            "patch('subprocess.check_output', side_effect=AssertionError('adb run')):\n"
            "    import mock_server\n"
            "    print(mock_server.BASE_DIR)\n"
            "    print(mock_server.RECORD_PATH)\n"
            "    print(mock_server.CONFIG_ZIP)\n"
            "    print(mock_server.SAVE_PATH)\n"
        )
        with tempfile.TemporaryDirectory() as directory:
            result = subprocess.run([sys.executable, "-B", "-c", code], cwd=directory,
                                    env={**os.environ, "PYTHONPATH": str(root)},
                                    capture_output=True, text=True, check=True, timeout=15)
            self.assertEqual(list(Path(directory).iterdir()), [])
        self.assertEqual(result.stdout.splitlines(), [str(root), str(root / "recorded_frames.json"),
                                                     str(root / "configs_sec5.zip"), str(root / "role_save.json")])
        self.assertEqual(result.stderr, "")

    def test_startup_passes_resources_to_connection_thread(self):
        conn = ReplayConnection([{"opcode": 200, "seq": 1, "hex": ""}], 7)
        with tempfile.TemporaryDirectory() as directory:
            save_path = Path(directory) / "role_save.json"
            with redirect_stdout(io.StringIO()), patch.object(server, "SAVE_PATH", str(save_path)), \
                    patch.object(sys, "argv", ["mock_server.py"]), \
                    patch.object(server, "setup_adb_reverse"), \
                    patch.object(server.socket, "socket") as socket_factory, \
                    patch.object(server.threading, "Thread") as thread_factory:
                socket_factory.return_value.accept.side_effect = [(conn, ("test", 0)), KeyboardInterrupt]
                server.main()
                thread_factory.assert_called_once()
                thread_factory.return_value.start.assert_called_once_with()
                options = thread_factory.call_args.kwargs
                self.assertIs(options["target"], server.handle_client)
                self.assertTrue(options["daemon"])
                options["target"](*options["args"])
            self.assertFalse(save_path.exists())
        self.assertTrue(conn.closed)
        self.assertEqual(conn.responses, [{"opcode": 200, "seq": 1, "hex": ""}])

    def test_startup_preserves_reset_flag_behavior_with_temporary_save(self):
        save = player.get_default_save()
        save.update(role_name="原有玩家", has_role=True, selected_general_id=3)
        save["guide"]["sections"] = {"1": {"status": 1, "step": 5, "steps": [5]}}
        original = json.dumps(save)
        with tempfile.TemporaryDirectory() as directory:
            save_path = Path(directory) / "role_save.json"
            for flags in ([], ["--reset-guide"], ["--reset"]):
                with self.subTest(flags=flags):
                    save_path.write_text(original)
                    with redirect_stdout(io.StringIO()), patch.object(server, "SAVE_PATH", str(save_path)), \
                            patch.object(sys, "argv", ["mock_server.py", *flags]), \
                            patch.object(server, "setup_adb_reverse") as adb, \
                            patch.object(server.socket, "socket") as socket_factory:
                        socket_factory.return_value.accept.side_effect = KeyboardInterrupt
                        server.main()
                    adb.assert_called_once_with()
                    socket_factory.return_value.bind.assert_called_once_with(("0.0.0.0", 14600))
                    if flags == ["--reset"]:
                        self.assertFalse(save_path.exists())
                    elif flags == ["--reset-guide"]:
                        saved = json.loads(save_path.read_text())
                        self.assertEqual(saved["guide"], {"sections": {}})
                        for key in ("role_name", "has_role", "selected_general_id", "created_at"):
                            self.assertEqual(saved[key], save[key])
                    else:
                        self.assertEqual(save_path.read_text(), original)


if __name__ == "__main__":
    unittest.main()
