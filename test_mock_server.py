from contextlib import redirect_stdout
import copy
import io
import json
import os
from pathlib import Path
import struct
import subprocess
import sys
import tempfile
import threading
import socket
import unittest
from unittest.mock import patch

import mock_server as server
import build_local_apk as apk_builder
from zyj_server import accounts, activities, battle, formation, guide, player, protocol, recharge, recruit, replay, training
from zyj_server.session import Session


def login_request(account, seq=0):
    identity = protocol.encode_pb_field(2, 2, f"local_account_{account}".encode("ascii"))
    return {"opcode": 1000, "seq": seq, "hex": protocol.encode_pb_field(1, 2, identity).hex()}


class ReplayConnection:
    def __init__(self, requests, chunk_size, account=1, login=True):
        self.hide_login_reply = bool(login and requests and requests[0]["opcode"] != 1000)
        if login:
            requests = [login_request(account, f["seq"]) if f["opcode"] == 1000 else f for f in requests]
            if self.hide_login_reply:
                requests.insert(0, login_request(account))
        stream = b"".join(protocol.pack_frame(f["opcode"], f["seq"], bytes.fromhex(f["hex"])) for f in requests)
        self.chunks = iter(stream[i:i + chunk_size] for i in range(0, len(stream), chunk_size))
        self.responses = []
        self.closed = False

    def settimeout(self, timeout):
        self.timeout = timeout

    def setsockopt(self, level, option, value):
        pass

    def recv(self, size):
        chunk = next(self.chunks, b"")
        assert len(chunk) <= size
        return chunk

    def sendall(self, data):
        magic, length, opcode, seq = struct.unpack(">IIII", data[:16])
        assert magic == 0xEE1C and len(data) == 16 + length
        if self.hide_login_reply and opcode == 1000 and seq == 0:
            self.hide_login_reply = False
            return
        self.responses.append({"opcode": opcode, "seq": seq, "hex": data[16:].hex()})

    def close(self):
        self.closed = True


class ReplayRoutingTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with redirect_stdout(io.StringIO()):
            cls.step_counts = guide.load_guide_step_counts(server.CONFIG_ZIP)
            cls.role_config = player.load_role_config(server.CONFIG_ZIP)
            cls.all_frames = replay.load_recordings(server.RECORD_PATH)
            cls.recordings = replay.split_recordings(cls.all_frames)
            cls.frames = cls.recordings[0]
            cls.tables = replay.build_routing_tables(cls.all_frames)
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
        sendall = conn.sendall
        def send_after_login(packet):
            if conn.hide_login_reply:
                return ReplayConnection.sendall(conn, packet)
            return sendall(packet)
        with patch.object(conn, "sendall", side_effect=send_after_login):
            store = accounts.AccountStore(self.save_path, self.tables, self.step_counts, self.role_config)
            server.handle_client(conn, ("test", 0), store)

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
        if response["opcode"] == 1032:
            self.assert_replayed_payload(1032, response["hex"], expected["hex"])
        else:
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
        elif opcode == 100:
            fields = list(protocol.iter_pb_fields(bytes.fromhex(actual)))
            self.assertEqual([(n, w) for n, w, _ in fields], [(1, 2)])
            self.assertTrue(fields[0][2].decode("utf-8"))
        elif opcode == 999905:
            values = protocol.parse_ids_pb(bytes.fromhex(actual))
            self.assertEqual(values, [int(self.clock.return_value), protocol.parse_ids_pb(bytes.fromhex(expected))[1]])
        elif opcode == 1032:
            live_ids = {40, 542, *range(82, 110)}
            actual_fields = list(protocol.iter_pb_fields(bytes.fromhex(actual)))
            expected_fields = list(protocol.iter_pb_fields(bytes.fromhex(expected)))
            self.assertEqual([f for f in actual_fields if not (f[:2] == (1, 0) and f[2] // 100 in live_ids)],
                             [f for f in expected_fields if not (f[:2] == (1, 0) and f[2] // 100 in live_ids)])
            self.assertTrue(all(value % 100 in (0, 1) for n, w, value in actual_fields
                                if n == 1 and w == 0 and value // 100 in live_ids))
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

    def hint_map(self, body):
        return {value // 100: value % 100 for n, w, value in protocol.iter_pb_fields(body) if n == 1 and w == 0}

    def hint_changes(self, response):
        self.assertEqual((response["opcode"], response["seq"]), (1034, 0))
        return {mid: protocol.pb_get_varint(row, 2)
                for mid, row in self.entity_records(bytes.fromhex(response["hex"]), 1, 1).items()}

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

    def test_phone_field_order_starts_first_battle_and_survives_reconnect(self):
        self.replay_through(35)
        request = dict(self.by_seq[36], seq=30, hex="0a0b089a0a120608f5c80208010a0908c901120410080801")
        responses = self.replay([request], chunk_size=7)
        self.assertEqual(responses, self.expected_group(36, 30))
        saved = json.loads(self.save_path.read_text())
        self.assertEqual([saved[k] for k in ("level", "silver", "gold")], [2, 2960, 10])
        self.assertEqual(saved["guide"]["sections"]["1"], {"status": 1, "step": 8, "steps": list(range(1, 9))})
        responses = self.replay([{"opcode": 200, "seq": 2, "hex": ""}, dict(self.by_seq[12], seq=5)])
        self.assertEqual(responses[0], {"opcode": 200, "seq": 2, "hex": "0a06080110011808"})
        self.assertEqual([self.role_data(responses[1])[n] for n in (5, 8, 9, 10)], [2, 2960, 10, 49])
        self.assert_rejected(request, "已通关关卡不支持重复录制战斗")

    def test_equivalent_comb_encodings_share_recordings_and_counters(self):
        request = self.by_seq[36]
        phone = dict(request, hex="0a0b089a0a120608f5c80208010a0908c901120410080801")
        first = {"c2s": False, "opcode": 999900, "seq": 36, "hex": "0a0708c90112020801"}
        second = dict(first, hex="0a0708c90112020800")
        with redirect_stdout(io.StringIO()):
            tables = replay.build_routing_tables([request, first, phone, second])
            routing = replay.Replay(tables)
            for body, seq, expected in ((request, 36, first), (phone, 10000, second),
                                        (phone, 36, first), (request, 10001, second)):
                self.assertEqual(routing.match(999900, seq, bytes.fromhex(body["hex"])), [expected])
        self.assertEqual(len(tables[1]), 1)
        self.assertEqual(list(tables[3].values()), [[[first], [second]]])

    def test_comb_field_order_variants_match_all_recorded_requests(self):
        for request in self.requests:
            if request["opcode"] != 999900:
                continue
            body = bytes.fromhex(request["hex"])
            fields = []
            for field, wire, value in protocol.iter_pb_fields(body):
                subfields = list(protocol.iter_pb_fields(value))
                if protocol.pb_get_varint(value, 1) in (201, 1003):
                    subfields = [(n, w, b"".join(protocol.encode_pb_field(*f) for f in reversed(list(protocol.iter_pb_fields(v)))))
                                 if (n, w) == (2, 2) else (n, w, v) for n, w, v in subfields]
                value = b"".join(protocol.encode_pb_field(*f) for f in reversed(subfields))
                fields.append(protocol.encode_pb_field(field, wire, value))
            with self.subTest(seq=request["seq"]), redirect_stdout(io.StringIO()):
                expected = replay.Replay(self.tables).match(999900, request["seq"], body)
                actual = replay.Replay(self.tables).match(999900, 10000, b"".join(fields))
                self.assertIsNotNone(expected)
                self.assertEqual(actual, expected)

    def test_comb_normalization_preserves_full_parameters_and_repeated_order(self):
        self.replay_through(35)
        before = self.save_path.read_bytes()
        self.clock.return_value = self.now + 360
        battle = bytes.fromhex("08f5c8020801")
        report = bytes.fromhex("10080801")

        def comb(battle_data, guide_data):
            return b"".join(protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, mid)
                            + protocol.encode_pb_field(2, 2, data)) for mid, data in ((1306, battle_data), (201, guide_data)))

        body = comb(battle, report)
        first, second = [v for n, w, v in protocol.iter_pb_fields(body)]
        bodies = [comb(bytes.fromhex("08f6c8020801"), report),
                  comb(bytes.fromhex("08f5c8020802"), report),
                  comb(bytes.fromhex("080108f5c802"), report),
                  comb(battle, b"\x10\x09\x08\x01"),
                  comb(battle, b"\x10\x08\x08\x02"),
                  comb(battle, report + b"\x08\x01"),
                  comb(battle, report + b"\x18\x01"),
                  comb(battle + b"\x18\x01", report),
                  protocol.encode_pb_field(1, 2, second) + protocol.encode_pb_field(1, 2, first),
                  body + protocol.encode_pb_field(1, 2, second),
                  body + b"\x10\x01"]
        for extra in (b"\x18\x01", protocol.encode_pb_field(1, 0, 1306), protocol.encode_pb_field(2, 2, battle)):
            bodies.append(protocol.encode_pb_field(1, 2, first + extra) + protocol.encode_pb_field(1, 2, second))
        for changed in bodies:
            with self.subTest(body=changed.hex()):
                for seq in (36, 10000):
                    responses = self.replay([dict(self.by_seq[36], seq=seq, hex=changed.hex())])
                    self.assert_unavailable_response(responses, 999900, seq, "关卡")
                    self.assertEqual(self.save_path.read_bytes(), before)
        malformed = comb(battle, b"\x10\x80")
        self.assert_rejected(dict(self.by_seq[36], hex=malformed.hex()), "截断的 Protobuf varint")

    def test_unknown_battle_parameters_do_not_receive_a_different_battle(self):
        body = bytes.fromhex(self.by_seq[61]["hex"])
        point_two = b"\x08" + protocol.encode_varint(42101) + b"\x08\x02"
        self.assertEqual(body.count(point_two), 1)
        body = body.replace(point_two, b"\x08" + protocol.encode_varint(42101) + b"\x08\x63")
        responses = self.replay([dict(self.by_seq[61], seq=10000, hex=body.hex())])
        self.assert_unavailable_response(responses, 999900, 10000, "关卡")
        self.assertFalse(self.save_path.exists())

    def assert_unavailable_response(self, responses, opcode, seq, message):
        self.assertEqual([(f["opcode"], f["seq"]) for f in responses], [(999999, seq), (1999, 0)])
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(responses[0]["hex"])), [opcode, 0])
        fields = list(protocol.iter_pb_fields(bytes.fromhex(responses[1]["hex"])))
        self.assertEqual([(n, w) for n, w, _ in fields], [(1, 2)])
        self.assertIn(message, fields[0][2].decode("utf-8"))

    def test_out_of_scope_standalone_battle_does_not_spend_or_start_empty_battle(self):
        self.replay(self.requests)
        before = self.save_path.read_bytes()
        request = dict(self.activity_request(1306, [42105, 1]), seq=36)
        responses = self.replay([request, dict(request, seq=37), self.activity_request(1300)], chunk_size=7)
        self.assert_unavailable_response(responses[:2], 1306, 36, "关卡")
        self.assert_unavailable_response(responses[2:4], 1306, 37, "关卡")
        self.assertEqual(responses[4]["opcode"], 1300)
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_unrecorded_battle_payloads_do_not_mutate_current_progress(self):
        self.replay(self.requests)
        before = self.save_path.read_bytes()
        for body in ("", "08", "0800", "08f6c8020863", "08f6c80208021001", "08f6c80208020801"):
            with self.subTest(body=body):
                responses = self.replay([{"opcode": 1306, "seq": 36, "hex": body}])
                self.assert_unavailable_response(responses, 1306, 36, "关卡")
                self.assertEqual(self.save_path.read_bytes(), before)

    def test_unrecorded_selection_does_not_create_a_role(self):
        body = bytes.fromhex(self.by_seq[11]["hex"])
        self.assertEqual(body.count(b"\x12\x02\x08\x03"), 1)
        body = body.replace(b"\x12\x02\x08\x03", b"\x12\x02\x08\x01")
        responses = self.replay([dict(self.by_seq[11], hex=body.hex())])
        self.assert_unavailable_response(responses, 999900, 11, "尚未实现")
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

    def test_unknown_ordinary_payload_returns_error_without_advancing_known_payload(self):
        requests = [dict(self.by_seq[31], seq=10000)]
        requests.extend({"opcode": 1032, "seq": seq, "hex": "08c404"} for seq in (28, 31, 10001))
        requests.append(dict(self.by_seq[52], seq=10002))
        responses = self.replay(requests, chunk_size=7)
        self.assertEqual(len(responses), 8)
        self.assert_recorded_response(responses[0], 31, 10000)
        for i, seq in enumerate((28, 31, 10001)):
            self.assert_unavailable_response(responses[1 + i * 2:3 + i * 2], 1032, seq, "尚未实现")
        self.assert_recorded_response(responses[-1], 52, 10002)
        self.assertFalse(self.save_path.exists())

    def test_unknown_ordinary_mutation_does_not_apply_pushes_or_spend(self):
        self.replay_through(131)
        original = self.save_path.read_bytes()
        self.clock.return_value = self.now + 360
        responses = self.replay([dict(self.by_seq[133], hex="0801")])
        self.assert_unavailable_response(responses, 1057, 133, "尚未实现")
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
                self.assertEqual(actual, self.tables[3][(request["seq"], opcode, body)][0])

    def test_imported_recordings_are_separated_at_sequence_restart(self):
        self.assertGreaterEqual(len(self.recordings), 2)
        self.assertEqual([f for recording in self.recordings for f in recording], self.all_frames)
        self.assertEqual(len(self.frames), 410)
        self.assertEqual(len(self.requests), 167)
        for recording in self.recordings:
            sequences = [f["seq"] for f in recording if f["c2s"]]
            self.assertEqual(sequences, sorted(set(sequences)))

    def test_mixed_library_does_not_duplicate_login_or_config_acknowledgements(self):
        requests = [self.by_seq[1], self.by_seq[4]]
        responses = self.replay(requests, chunk_size=7)
        self.assertEqual([(f["opcode"], f["seq"]) for f in responses], [(1000, 1), (999907, 4)])
        self.assertFalse(self.save_path.exists())

    def test_reused_sequence_payloads_keep_separate_reply_groups(self):
        request = {"c2s": True, "opcode": 9001, "seq": 1, "hex": "0801"}
        first = {"c2s": False, "opcode": 9001, "seq": 1, "hex": "080a"}
        second = dict(first, hex="0814")
        frames = [request, first, dict(request), second]
        with redirect_stdout(io.StringIO()):
            tables = replay.build_routing_tables(frames)
            routing = replay.Replay(tables)
            self.assertEqual(routing.match(9001, 1, b"\x08\x01"), [first])
            self.assertEqual(routing.match(9001, 1, b"\x08\x01"), [second])
        self.assertEqual(len(tables[3][(1, 9001, b"\x08\x01")]), 2)

    def test_reused_sequence_with_different_payload_is_not_overwritten(self):
        request = {"c2s": True, "opcode": 9001, "seq": 1, "hex": "0801"}
        first = {"c2s": False, "opcode": 9001, "seq": 1, "hex": "080a"}
        other_request = dict(request, hex="0802")
        second = dict(first, hex="0814")
        with redirect_stdout(io.StringIO()):
            tables = replay.build_routing_tables([request, first, other_request, second])
            self.assertEqual(replay.Replay(tables).match(9001, 1, b"\x08\x01"), [first])
            self.assertEqual(replay.Replay(tables).match(9001, 1, b"\x08\x02"), [second])

    def test_cross_request_reply_matching_stops_at_recording_boundary(self):
        first_request = {"c2s": True, "opcode": 9001, "seq": 1, "hex": "0801"}
        later_request = dict(first_request, opcode=9002, seq=2, hex="")
        late_reply = {"c2s": False, "opcode": 9001, "seq": 1, "hex": "080a"}
        next_recording = dict(first_request, hex="0802")
        next_reply = dict(late_reply, hex="0814")
        with redirect_stdout(io.StringIO()):
            tables = replay.build_routing_tables([first_request, later_request, late_reply, next_recording, next_reply])
            self.assertEqual(replay.Replay(tables).match(9001, 10000, b"\x08\x01"), [late_reply])
            tables = replay.build_routing_tables([first_request, later_request, next_recording, next_reply])
            self.assertIsNone(replay.Replay(tables).match(9001, 10000, b"\x08\x01"))

    def test_new_initialization_returns_all_modules_without_completed_account_state(self):
        frames = self.recordings[1]
        request = next(f for f in frames if f["c2s"] and f["opcode"] == 999900
                       and 8110 in protocol.get_comb_ids(bytes.fromhex(f["hex"])))
        recorded = next(f for f in frames if not f["c2s"] and f["opcode"] == 999900 and f["seq"] == request["seq"])
        responses = self.replay([dict(request, seq=30000)])
        self.assertEqual(len(responses), 1)
        self.assertEqual((responses[0]["opcode"], responses[0]["seq"]), (999900, 30000))
        messages = protocol.get_comb_messages(bytes.fromhex(responses[0]["hex"]))
        recorded_messages = protocol.get_comb_messages(bytes.fromhex(recorded["hex"]))
        self.assertEqual([mid for mid, _ in messages], [mid for mid, _ in recorded_messages])
        self.assertEqual({mid: body for mid, body in messages if mid in (8101, 8105, 8109, 8110)},
                         dict.fromkeys((8101, 8105, 8109, 8110), b""))
        role = self.role_data(responses[0])
        self.assertEqual([role[n] for n in (5, 6, 8, 9, 10)], [1, 0, 0, 0, 50])
        baseline_role = self.role_data(self.recorded[(12, 999900)])
        self.assertEqual(role[21], baseline_role[21])
        protagonist = dict(messages)[1054]
        self.assertEqual(protagonist, dict(protocol.get_comb_messages(bytes.fromhex(self.recorded[(12, 999900)]["hex"])))[1054])
        saved = json.loads(self.save_path.read_text())
        self.assertEqual(saved["world_state"]["1002"], self.query_world(1002).hex())
        self.assertNotIn(8927, self.entity_records(self.query_world(1002), 1, 2))

    def test_new_initialization_restores_current_saved_progress(self):
        self.replay(self.requests)
        self.replay([dict(self.by_seq[12], seq=29999)])
        before = json.loads(self.save_path.read_text())
        request = next(f for f in self.recordings[1] if f["c2s"] and f["opcode"] == 999900
                       and 8110 in protocol.get_comb_ids(bytes.fromhex(f["hex"])))
        response = self.replay([dict(request, seq=30000)])[0]
        self.assertEqual([self.role_data(response)[n] for n in (5, 6, 8, 9, 27)], [6, 1000, 123040, 100, 5862])
        self.assertEqual(json.loads(self.save_path.read_text()), before)
        messages = dict(protocol.get_comb_messages(bytes.fromhex(response["hex"])))
        for opcode in player.WORLD_QUERY_IDS:
            self.assertEqual(messages[opcode].hex(), before["world_state"][str(opcode)])

    def test_unrecorded_initialization_parameters_do_not_reuse_generic_template(self):
        self.replay_through(12)
        request = self.by_seq[12]
        raw = bytes.fromhex(request["hex"])
        extra_module = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 8999) + protocol.encode_pb_field(2, 2, b""))
        fields = list(protocol.iter_pb_fields(raw))
        fields[0] = (1, 2, protocol.pb_set_field(fields[0][2], 2, 2, b"\x08\x01"))
        changed_data = b"".join(protocol.encode_pb_field(*field) for field in fields)
        self.assertEqual(protocol.get_comb_ids(changed_data), protocol.get_comb_ids(raw))
        before = self.save_path.read_bytes()
        self.clock.return_value = self.now + 360
        for body in (raw + extra_module, changed_data, raw + protocol.encode_pb_field(2, 0, 1)):
            with self.subTest(body=body):
                self.assert_unavailable_response(self.replay([dict(request, seq=30000, hex=body.hex())]),
                                                 999900, 30000, "尚未实现")
                self.assertEqual(self.save_path.read_bytes(), before)

    def test_new_account_template_does_not_depend_on_capture_order(self):
        frames = [*self.recordings[1], *self.frames]
        with redirect_stdout(io.StringIO()):
            self.tables = replay.build_routing_tables(frames)
        self.replay([self.by_seq[11], self.by_seq[12]])
        role = self.query_role()
        self.assertEqual([role[n] for n in (5, 8, 9, 10)], [1, 0, 0, 50])

    def test_new_capture_ordinary_requests_match_one_reply_each(self):
        frames = self.recordings[1]
        with redirect_stdout(io.StringIO()):
            for request in frames:
                if not request["c2s"] or request["opcode"] == 999900:
                    continue
                opcode, seq, body = request["opcode"], request["seq"], bytes.fromhex(request["hex"])
                expected = next(f for f in frames if not f["c2s"] and f["opcode"] == opcode and f["seq"] == seq)
                responses = replay.Replay(self.tables).match(opcode, seq, body)
                replies = [f for f in responses if f["seq"] != 0]
                self.assertEqual(len(replies), 1, (opcode, seq))
                self.assertEqual(replies[0]["opcode"], opcode)
                candidates = self.tables[0][(opcode, b"" if opcode == 1000 else body)]
                self.assertIn(responses, candidates)
                self.assertIn([expected], candidates)

    def test_initialization_without_new_account_baseline_is_rejected(self):
        with redirect_stdout(io.StringIO()), self.assertRaisesRegex(ValueError, "一级新号初始化基础"):
            replay.build_routing_tables(self.recordings[1])

    def test_nonempty_unimplemented_initialization_extension_is_rejected(self):
        response = next(f for f in self.recordings[1] if not f["c2s"] and f["opcode"] == 999900 and f["seq"] == 5)
        body = b"".join(protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, mid)
                       + protocol.encode_pb_field(2, 2, b"\x08\x01" if mid == 8110 else data))
                        for mid, data in protocol.get_comb_messages(bytes.fromhex(response["hex"])))
        frames = [dict(f, hex=body.hex()) if f is response else f for f in self.all_frames]
        with redirect_stdout(io.StringIO()), self.assertRaisesRegex(ValueError, "初始化扩展 8110 非空"):
            replay.build_routing_tables(frames)

    def test_initialization_rewrite_preserves_unknown_fields_and_source_frames(self):
        response = next(f for f in self.recordings[1] if not f["c2s"] and f["opcode"] == 999900 and f["seq"] == 5)
        unknown = protocol.encode_pb_field(9, 2, b"keep")
        body = bytes.fromhex(response["hex"]) + unknown
        frames = [dict(f, hex=body.hex()) if f is response else f for f in self.all_frames]
        before = json.dumps(frames)
        request = next(f for f in self.recordings[1] if f["c2s"] and f["opcode"] == 999900 and f["seq"] == 5)
        with redirect_stdout(io.StringIO()):
            tables = replay.build_routing_tables(frames)
            actual = replay.Replay(tables).match(999900, 30000, bytes.fromhex(request["hex"]))
        self.assertEqual(len(actual), 1)
        self.assertTrue(bytes.fromhex(actual[0]["hex"]).endswith(unknown))
        self.assertEqual(json.dumps(frames), before)

    def test_repeated_local_login_uses_bound_account_without_recording(self):
        responses = self.replay([login_request(1, 10000), login_request(1, 10001)])
        self.assertEqual(responses, [{"opcode": 1000, "seq": seq, "hex": "080010001800"}
                                     for seq in (10000, 10001)])
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

    def test_random_names_use_config_for_all_three_profiles(self):
        first = {"name1": "唐", "name2": "尔岚", "name3": "忻云", "name4": "钦豪"}
        second = {"name1": "景", "name2": "初夏", "name3": "函韵", "name4": "善瀚"}
        self.role_config = dict(self.role_config, rollname={"1": first, "2": second})
        requests = [{"opcode": 100, "seq": seq, "hex": protocol.encode_pb_field(1, 0, profile).hex()}
                    for profile in (3, 1, 2) for seq in (9, 10000)]
        with patch("random.choice", side_effect=[first, second, second, first] * 3):
            responses = self.replay(requests, chunk_size=7)
        self.assertEqual([(r["opcode"], r["seq"]) for r in responses], [(100, r["seq"]) for r in requests])
        self.assertEqual([player.parse_set_name(bytes.fromhex(r["hex"])) for r in responses],
                         ["唐善瀚", "景钦豪", "唐初夏", "景尔岚", "唐函韵", "景忻云"])
        self.assertFalse(self.save_path.exists())

    def test_random_name_does_not_rename_or_change_saved_role(self):
        self.replay_through(12)
        original = self.save_path.read_bytes()
        response = self.replay([dict(self.by_seq[9], seq=20000)])[0]
        self.assertTrue(player.parse_set_name(bytes.fromhex(response["hex"])))
        self.assertEqual(self.save_path.read_bytes(), original)

    def test_malformed_random_name_request_does_not_change_save(self):
        self.replay_through(12)
        for body in ("", "08", "0800", "0804", "0a0103", "1003", "08030801", "08031001"):
            with self.subTest(body=body):
                self.assert_rejected({"opcode": 100, "seq": 20000, "hex": body}, "随机名字请求格式错误")

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

    def test_unimplemented_training_returns_error_instead_of_empty_success(self):
        self.replay(self.requests)
        before = self.save_path.read_bytes()
        for opcode in (1026, 1028, 1029, 1102, 1105, 1106):
            with self.subTest(opcode=opcode):
                request = self.activity_request(opcode, [7060])
                self.assert_unavailable_response(self.replay([request]), opcode, 20000, "尚未实现")
                self.assertEqual(self.save_path.read_bytes(), before)

    def test_exp_pills_update_general_and_inventory_after_reconnect(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        saved["role_state"]["level"] = 8
        self.save_path.write_text(json.dumps(saved))
        self.give_props({20196: 2, 20197: 1})
        world = self.query_world(1002)
        previous = self.entity_records(world, 1, 2)[7060]
        inventory = self.entity_records(self.query_world(1200), 1, 1)
        body = protocol.encode_pb_field(1, 0, 7060) + b"".join(protocol.encode_pb_field(2, 0, v) for v in (2, 1, 0, 0))
        replies = self.replay([{"opcode": 1038, "seq": 20000, "hex": body.hex()}])
        self.assertEqual(replies[0]["opcode"], 1038)
        updated = self.entity_records(bytes.fromhex(replies[0]["hex"]), 8, 2)[7060]
        self.assertGreater(protocol.pb_get_varint(updated, 3), protocol.pb_get_varint(previous, 3))
        self.assertGreater(protocol.pb_get_varint(updated, 6), protocol.pb_get_varint(previous, 6))
        self.assertEqual(self.entity_records(self.query_world(1002), 1, 2)[7060], updated)
        after_inventory = self.entity_records(self.query_world(1200), 1, 1)
        for cid, count in ((20196, 2), (20197, 1)):
            self.assertEqual(protocol.pb_get_varint(after_inventory.get(cid, b""), 2) or 0,
                             protocol.pb_get_varint(inventory[cid], 2) - count)
        self.assertFalse(any(n == 10 and v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(replies[0]["hex"]))))

    def seed_training_account(self, coin=100000, vip=0):
        self.complete_tutorial()
        saved = json.loads(self.save_path.read_text())
        saved["role_state"].update(level=8, coin=coin, vip=vip)
        saved["activity_state"]["strengthen_count"] = 0
        self.save_path.write_text(json.dumps(saved))
        self.give_props({20196: 20, 20197: 10, 20198: 5, 20199: 2})
        return json.loads(self.save_path.read_text())

    def training_request(self, opcode, iid, values):
        body = protocol.encode_pb_field(1, 0, iid) + b"".join(protocol.encode_pb_field(2, 0, v) for v in values)
        return {"opcode": opcode, "seq": 20000, "hex": body.hex()}

    def test_exp_growth_matches_official_1038_attributes_and_potential(self):
        frames = json.loads((Path(server.BASE_DIR) / "official_battle_capture_20261028_2210.json").read_text())["connections"][0]["frames"]
        saved = {"world_state": {"1002": ""}, "has_role": True, "role_state": {"level": 8}}
        for frame in frames:
            if frame["c2s"]:
                if frame["opcode"] == 1038:
                    request = frame
                    break
                continue
            body = bytes.fromhex(frame["hex"])
            messages = protocol.get_comb_messages(body) if frame["opcode"] == 999900 else [(frame["opcode"], body)]
            for opcode, body in messages:
                if opcode in (1002, 1024, 1027):
                    player.record_slot_update(saved, body)
                elif opcode in (1306, 1017):
                    for raw in self.entity_records(body, 6 if opcode == 1306 else 1, 2).values():
                        player.record_slot_update(saved, protocol.encode_pb_field(1, 2, raw))
        expected = next(f for f in frames if not f["c2s"] and f["opcode"] == 1038 and f["seq"] == request["seq"])
        before = copy.deepcopy(saved)
        body, costs, _ = training.use_exp(saved, bytes.fromhex(request["hex"]), self.role_config)
        self.assertEqual(saved, before)
        self.assertEqual(costs, [(20196, 2), (20197, 1)])
        actual = self.entity_records(body, 8, 2)[7060]
        recorded = self.entity_records(bytes.fromhex(expected["hex"]), 8, 2)[7060]
        for field in (3, 5, 6, 7, 8, 9, 17):
            self.assertEqual(protocol.pb_get_varint(actual, field), protocol.pb_get_varint(recorded, field), field)

    def test_exp_cap_preserves_last_pill_overflow_and_rejects_more(self):
        saved = self.seed_training_account()
        raw = recruit.new_general(10213, 2000001, self.role_config)
        raw = protocol.pb_set_varint(protocol.pb_set_varint(raw, 3, 15), 5, 1199)
        player.record_slot_update(saved, protocol.encode_pb_field(1, 2, raw))
        self.save_path.write_text(json.dumps(saved))
        before_power = saved["role_state"]["power"]
        request = self.training_request(1038, 2000001, (0, 0, 0, 1))
        reply = self.replay([request])[0]
        raw = self.entity_records(bytes.fromhex(reply["hex"]), 8, 2)[2000001]
        self.assertEqual(protocol.pb_get_varint(raw, 3), 16)
        self.assertEqual(protocol.pb_get_varint(raw, 5), 1199 + 20000 - self.role_config["general_exp"]["15"]["4exp"])
        self.assertEqual(json.loads(self.save_path.read_text())["role_state"]["power"], before_power)
        before = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([request]), 1038, 20000, "上限")
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_growth_batching_keeps_attributes_potential_and_power_identical(self):
        raw = recruit.new_general(10213, 2000001, self.role_config)
        combined, _, _ = training.grow_general(raw, 5000, b"", set(), {}, self.role_config)
        for _ in range(50):
            raw, _, _ = training.grow_general(raw, 100, b"", set(), {}, self.role_config)
        self.assertEqual(raw, combined)

    def test_exp_upgraded_relation_survives_removal_and_level_cap_survives_battle(self):
        saved = self.seed_training_account()
        raw = recruit.new_general(10213, 2000001, self.role_config)
        player.record_slot_update(saved, protocol.encode_pb_field(1, 2, raw))
        self.save_path.write_text(json.dumps(saved))
        self.replay([self.change_general_request(2, 2000001)])
        replies = self.replay([self.training_request(1038, 2000001, (0, 1, 0, 0))])
        self.assertEqual(replies[0]["opcode"], 1038)
        self.replay([self.change_general_request(2, 7060)])
        raw = self.entity_records(self.query_world(1002), 1, 2)[2000001]
        level = protocol.pb_get_varint(raw, 3)
        self.assertEqual(protocol.pb_get_varint(raw, 6), 420 + 42 * (level - 1))
        self.assertEqual(protocol.pb_get_varint(raw, 17), 30 + 80 * (level - 1))
        self.replay([self.change_general_request(2, 2000001)])
        self.replay([self.training_request(1038, 2000001, (0, 0, 0, 1))])
        raw = self.entity_records(self.query_world(1002), 1, 2)[2000001]
        self.assertEqual(protocol.pb_get_varint(raw, 3), 16)
        with patch.object(player.random, "getrandbits", return_value=42):
            result = self.replay([self.activity_request(1306, [42102, 2])])[0]
        self.assertEqual(result["opcode"], 1306)
        self.assertEqual(protocol.pb_get_varint(bytes.fromhex(result["hex"]), 1), 1)
        after = self.entity_records(self.query_world(1002), 1, 2)[2000001]
        self.assertEqual(protocol.pb_get_varint(after, 3), 16)
        self.assertGreater(protocol.pb_get_varint(after, 5), protocol.pb_get_varint(raw, 5))

    def test_strengthening_charges_once_updates_protagonist_and_reconnects(self):
        saved = self.seed_training_account(coin=560)
        raw = self.entity_records(bytes.fromhex(saved["world_state"]["1002"]), 1, 2)[7059]
        request = self.training_request(1101, 10726, (0,))
        responses = self.replay([request, request], chunk_size=7)
        self.assertEqual(responses[:2], responses[2:])
        self.assertEqual([r["opcode"] for r in responses[:2]], [1101, 205])
        body = bytes.fromhex(responses[0]["hex"])
        self.assertEqual(protocol.pb_get_varint(body, 1), (1 << 64) - 560)
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["role_state"]["coin"], 0)
        world = self.query_world(1002)
        changed = self.entity_records(world, 1, 2)[7059]
        self.assertEqual(protocol.parse_ids_pb(self.entity_records(world, 2, 1)[10726])[2], 9)
        self.assertEqual(protocol.pb_get_varint(changed, 6), protocol.pb_get_varint(raw, 6) + 20)
        self.assertEqual(after["role_state"]["power"], saved["role_state"]["power"] + 20)
        protagonist = bytes.fromhex(after["protagonist_snapshot"])
        self.assertEqual(next(v for n, w, v in protocol.iter_pb_fields(protagonist) if n == 10), changed)
        self.assertEqual(after["activity_state"]["strengthen_count"], 1)
        self.assertEqual(self.query_role()[8], 0)

    def test_strengthen_five_levels_and_quick_all_follow_costs_and_limits(self):
        saved = self.seed_training_account()
        request = self.training_request(1101, 10726, (1,))
        replies = self.replay([request])
        self.assertEqual(replies[0]["opcode"], 1101)
        after = json.loads(self.save_path.read_text())
        self.assertEqual(saved["role_state"]["coin"] - after["role_state"]["coin"], 560 + 640 + 680 + 720 + 760)
        self.assertEqual(protocol.parse_ids_pb(self.entity_records(self.query_world(1002), 2, 1)[10726])[2], 13)
        old_items = self.entity_records(self.query_world(1002), 2, 1)
        cost = 0
        for iid in (10720, 10721, 10723, 10726):
            item = protocol.parse_ids_pb(old_items[iid])
            cost += sum(self.role_config["equip_strengthen"][str(lv)]["quality2"] for lv in range(item[2], 16))
        response = self.replay([self.activity_request(1109, [7059])])
        self.assertEqual(response[0]["opcode"], 1109)
        final = json.loads(self.save_path.read_text())
        self.assertEqual(after["role_state"]["coin"] - final["role_state"]["coin"], cost)
        items = self.entity_records(self.query_world(1002), 2, 1)
        for iid in (10720, 10721, 10723, 10726):
            self.assertEqual(protocol.parse_ids_pb(items[iid])[2], 16)
        self.assertEqual(final["activity_state"]["strengthen_count"], self.role_config["liveness"]["16"]["num"])
        self.assertTrue(any(f["opcode"] == 1034 and self.hint_changes(f).get(40) == 1 for f in replies))

    def test_strengthening_vip_critical_is_charged_per_attempt(self):
        self.seed_training_account(coin=560, vip=3)
        with patch.object(player.random, "getrandbits", return_value=0):
            replies = self.replay([self.training_request(1101, 10726, (0,))])
        body = bytes.fromhex(replies[0]["hex"])
        self.assertEqual(protocol.parse_ids_pb(self.entity_records(body, 6, 1)[10726])[2], 10)
        self.assertEqual(protocol.pb_get_varint(body, 1), (1 << 64) - 560)
        self.assertEqual(protocol.parse_ids_pb(next(v for n, w, v in protocol.iter_pb_fields(body) if n == 12)), [1])

    def test_old_tutorial_strengthening_cannot_overwrite_live_progress(self):
        self.seed_training_account()
        self.replay([self.training_request(1101, 10726, (1,))])
        before = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.by_seq[99]]), 999900, 99, "已过期")
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_recording_without_own_reply_cannot_apply_pushes(self):
        self.seed_training_account()
        before = self.save_path.read_bytes()
        pushes = [f for f in self.expected_group(99) if f["seq"] == 0]
        with patch.object(replay.Replay, "match", return_value=pushes):
            self.assert_unavailable_response(self.replay([self.activity_request(1028, [1, 7060])]), 1028, 20000, "缺少完整应答")
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_training_invalid_insufficient_and_save_failure_leave_no_partial_state(self):
        saved = self.seed_training_account(coin=1)
        good_exp = self.training_request(1038, 7060, (2, 1, 0, 0))
        invalid = [self.training_request(1038, 7060, (0, 0, 0, 0)),
                   self.training_request(1038, 7060, (1, 1, 1)),
                   self.training_request(1038, 999999, (1, 0, 0, 0)),
                   self.training_request(1038, 7060, (0, 0, 0, 100)),
                   self.training_request(1101, 10726, (0,)),
                   self.training_request(1101, 10726, (2,)),
                   self.training_request(1101, 10726, (0, 0)),
                   self.training_request(1101, 999999, (0,)),
                   self.activity_request(1109, [7059, 7059]), self.activity_request(1109, [999999])]
        invalid += [dict(good_exp, hex=good_exp["hex"] + suffix) for suffix in ("18", "1801", "089437")]
        inventory = self.entity_records(bytes.fromhex(saved["world_state"]["1200"]), 1, 1)
        for cid in training.EXP_PROPS:
            player.change_item_count(saved, cid, -(protocol.pb_get_varint(inventory.get(cid, b""), 2) or 0), self.role_config)
        # A valid first deduction followed by a missing second item must roll back too.
        player.change_item_count(saved, 20196, 2, self.role_config)
        self.save_path.write_text(json.dumps(saved))
        invalid.append(good_exp)
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
            for request in invalid:
                with self.subTest(request=request):
                    packet = session.handle(request["opcode"], request["seq"], bytes.fromhex(request["hex"]))[0]
                    self.assertEqual(struct.unpack(">IIII", packet[:16])[2], 999999)
                    self.assertEqual(session.save, memory)
                    self.assertEqual(self.save_path.read_bytes(), disk)
            request = self.training_request(1038, 7060, (2, 0, 0, 0))
            with patch.object(player.os, "replace", side_effect=OSError("disk full")):
                with self.assertRaises(OSError):
                    session.handle(1038, 20001, bytes.fromhex(request["hex"]))
            self.assertEqual(session.save, memory)
            self.assertEqual(self.save_path.read_bytes(), disk)

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
            if struct.unpack(">I", packet[8:12])[0] == 1000:
                return sendall(packet)
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
        self.replay_through(55)
        request = dict(self.by_seq[56], seq=44, hex="0a0a08eb07120518943708020a0908c901120410130801")
        self.assertEqual(self.replay([request], chunk_size=7), self.expected_group(56, 44))
        self.assertEqual(json.loads(self.save_path.read_text())["guide"]["sections"]["1"]["step"], 19)
        roster = self.query_world(1002)
        generals = self.entity_records(roster, 1, 2)
        slots = self.entity_records(roster, 4, 1)
        self.assertTrue({7059, 7060}.issubset(generals))
        self.assertEqual(protocol.pb_get_varint(slots[2], 2), 7060)
        responses = self.replay([dict(self.by_seq[12], seq=30000)])
        restored = dict(protocol.get_comb_messages(bytes.fromhex(responses[0]["hex"])))[1002]
        self.assertEqual(restored, roster)

    def test_unrecorded_slot_parameters_remain_non_mutating(self):
        self.replay_through(55)
        before = self.save_path.read_bytes()
        body = bytes.fromhex(self.by_seq[56]["hex"])
        for data in (b"\x18\x94\x37\x08\x03", b"\x18\x95\x37\x08\x02",
                     b"\x18\x94\x37\x08\x02\x10\x00", b"\x18\x94\x37\x08\x02\x08\x02"):
            changed = b"".join(protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, mid)
                              + protocol.encode_pb_field(2, 2, data if mid == 1003 else payload))
                               for mid, payload in protocol.get_comb_messages(body))
            with self.subTest(data=data.hex()):
                self.assert_unavailable_response(self.replay([dict(self.by_seq[56], hex=changed.hex())]),
                                                 999900, 56, "尚未实现")
                self.assertEqual(self.save_path.read_bytes(), before)

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

    def test_live_copy_boxes_return_rewards_and_save_before_popup(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        for pid, stars in ((2, 3), (3, 3), (4, 3), (5, 2)):
            player.record_copy_win(saved, bytes.fromhex(self.activity_request(1306, [42102, pid])["hex"]),
                                   stars, self.role_config, allow_repeat=True)
        self.save_path.write_text(json.dumps(saved))
        for method, field, expected in ((0, 4, {20017: 2, 20161: 20}), (3, 5, {20017: 2, 20161: 30})):
            before = self.entity_records(bytes.fromhex(saved["world_state"]["1200"]), 1, 1)
            request = self.activity_request(1304, [42102, method])
            conn = ReplayConnection([request], 7)
            send = conn.sendall

            def check_saved_before_send(packet):
                committed = json.loads(self.save_path.read_text())
                copies = self.entity_records(bytes.fromhex(committed["world_state"]["1300"]), 1, 1)
                self.assertEqual(protocol.pb_get_varint(copies[42102], field), 3)
                props = self.entity_records(bytes.fromhex(committed["world_state"]["1200"]), 1, 1)
                for cid, count in expected.items():
                    self.assertEqual(protocol.pb_get_varint(props[cid], 2), (protocol.pb_get_varint(before.get(cid, b""), 2) or 0) + count)
                send(packet)

            conn.sendall = check_saved_before_send
            with redirect_stdout(io.StringIO()):
                self.run_client(conn)
            self.assertEqual([r["opcode"] for r in conn.responses], [1304])
            fields = {n: v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(conn.responses[0]["hex"]))}
            self.assertEqual({cid: protocol.pb_get_varint(raw, 2) for cid, raw in self.entity_records(fields[5], 1, 1).items()}, expected)
            saved = json.loads(self.save_path.read_text())
            self.assertEqual(self.query_world(1200).hex(), saved["world_state"]["1200"])
            self.assertEqual(self.query_world(1300).hex(), saved["world_state"]["1300"])
            committed = self.save_path.read_bytes()
            self.assert_unavailable_response(self.replay([request]), 1304, request["seq"], "已领取")
            self.assertEqual(self.save_path.read_bytes(), committed)

    def test_live_copy_boxes_reject_invalid_locked_and_uncreated_without_changes(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        valid = bytes.fromhex(self.activity_request(1304, [42102, 0])["hex"])
        invalid = [b"", b"\x08", valid + b"\x10\x01", valid + b"\x08\x00", valid + b"\x80"]
        invalid += [bytes.fromhex(self.activity_request(1304, ids)["hex"])
                    for ids in ([42102, 1], [42102, 3], [42102, 6], [42103, 0], [42105, 0], [0, 0], [42102, (1 << 31)])]
        for body in invalid:
            with self.subTest(hex=body.hex()), redirect_stdout(io.StringIO()):
                session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
                memory, original = copy.deepcopy(session.save), self.save_path.read_bytes()
                packets = session.handle(1304, 21000, body)
                self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets], [999999, 1999])
                self.assertEqual(session.save, memory)
                self.assertEqual(self.save_path.read_bytes(), original)
        comb = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 1304) + protocol.encode_pb_field(2, 2, valid))
        before = self.save_path.read_bytes()
        replies = self.replay([{"opcode": 999900, "seq": 21000, "hex": comb.hex()}])
        self.assert_unavailable_response(replies, 999900, 21000, "副本宝箱")
        self.assertEqual(self.save_path.read_bytes(), before)
        saved["has_role"] = False
        self.save_path.write_text(json.dumps(saved))
        before = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(1304, [42102, 0])]), 1304, 20000, "角色")
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_live_copy_box_failure_rolls_back_items_flags_and_stamina(self):
        self.replay(self.requests)
        body = bytes.fromhex(self.activity_request(1304, [42102, 0])["hex"])
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            before, memory = self.save_path.read_bytes(), copy.deepcopy(session.save)
            self.clock.return_value += player.STAMINA_INTERVAL
            with patch.object(player.os, "replace", side_effect=OSError("disk full")):
                with self.assertRaises(OSError):
                    session.handle(1304, 21000, body)
            self.assertEqual(self.save_path.read_bytes(), before)
            self.assertEqual(session.save, memory)
        props = self.entity_records(bytes.fromhex(memory["world_state"]["1200"]), 1, 1)
        self.give_props({20161: (1 << 31) - 1 - (protocol.pb_get_varint(props.get(20161, b""), 2) or 0)})
        before = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(1304, [42102, 0])]), 1304, 20000, "范围")
        self.assertEqual(self.save_path.read_bytes(), before)

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

    def complete_tutorial(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        for step in range(saved["guide"]["sections"]["1"]["step"] + 1, self.step_counts[1] + 1):
            body = protocol.encode_pb_field(1, 0, 1) + protocol.encode_pb_field(2, 0, step)
            self.replay([{"opcode": 201, "seq": 20000 + step, "hex": body.hex()}])

    def test_live_recruit_free_paid_duplicate_and_cooldown_survive_reconnect(self):
        self.complete_tutorial()
        gold = self.query_role()[9]
        before = self.entity_records(self.query_world(1002), 1, 2)
        response = self.replay([self.activity_request(1403, [2, 1])])[0]
        reward = dict(protocol.get_comb_messages(bytes.fromhex(response["hex"])))
        self.assertEqual(protocol.parse_ids_pb(reward[2]), [10401, 1])
        generals = [v for n, w, v in protocol.iter_pb_fields(reward[1]) if n == 8 and w == 2]
        self.assertEqual(len(generals), 1)
        iid = protocol.pb_get_varint(generals[0], 2)
        self.assertGreater(iid, 2000000)
        roster = self.entity_records(self.query_world(1002), 1, 2)
        self.assertEqual(roster[iid], generals[0])
        self.assertTrue(all(roster[k] == v for k, v in before.items()))
        self.assertEqual(self.query_role()[9], gold)
        self.clock.return_value += 100
        response = self.replay([dict(self.activity_request(1403, [2, 1]), seq=20001)])[0]
        reward = dict(protocol.get_comb_messages(bytes.fromhex(response["hex"])))
        self.assertEqual(protocol.parse_ids_pb(reward[2]), [10401, 1])
        self.assertFalse(any(n == 8 for n, w, v in protocol.iter_pb_fields(reward[1])))
        fragment = self.entity_records(self.query_world(1012), 1, 1)[10401]
        self.assertEqual(protocol.pb_get_varint(fragment, 2), self.role_config["general_fragment"]["11401"]["recruit"])
        self.assertEqual(self.query_role()[9], gold - 100)
        query = self.replay([self.activity_request(1402)])[0]
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(query["hex"]))[5:10], [100, 1, 1, 0, 43100])
        self.clock.return_value = self.now + 43200
        self.replay([self.activity_request(1403, [2, 1])])
        self.assertEqual(self.query_role()[9], gold - 100)
        saved = json.loads(self.save_path.read_text())
        self.assertEqual(saved["recruit_state"]["2"]["freetimes"], 2)
        self.assertEqual(saved["recruit_state"]["2"]["next_free_at"], self.now + 86400)

    def test_live_recruit_ten_and_hundred_costs_first_guarantee_and_unique_ids(self):
        self.complete_tutorial()
        original = json.loads(self.save_path.read_text())
        for pos, method, cid, cost, count in ((1, 2, 20100, 10, 10), (2, 2, 1001, 900, 10),
                                             (3, 2, 20619, 10, 10), (1, 3, 20100, 100, 100)):
            with self.subTest(pos=pos, method=method):
                saved = copy.deepcopy(original)
                player.change_item_count(saved, cid, cost * 2, self.role_config, self.now)
                self.save_path.write_text(json.dumps(saved))
                config = copy.deepcopy(self.role_config)
                base = str(config["recruit_basic"][str(pos)]["freecardgroupid"])
                guarantee = str(config["recruit_basic"][str(pos)]["firsttentavern"])
                config["recruit_deck"][base]["resourceid"] = "10213,1;"
                config["recruit_deck"][guarantee]["resourceid"] = "10409,1;"
                with patch.object(self, "role_config", config):
                    for first in (True, False):
                        response = self.replay([self.activity_request(1403, [pos, method])])[0]
                        rewards = dict(protocol.get_comb_messages(bytes.fromhex(response["hex"])))
                        gets = protocol.parse_ids_pb(rewards[2])
                        self.assertEqual(len(gets), count * 2)
                        self.assertEqual(gets[:2], [10409 if first else 10213, 1])
                        self.assertEqual(gets[2:], [10213, 1] * (count - 1))
                        generals = [v for n, w, v in protocol.iter_pb_fields(rewards[1]) if n == 8 and w == 2]
                        self.assertEqual(len(generals), int(first))
                committed = json.loads(self.save_path.read_text())
                self.assertEqual(committed["recruit_state"][str(pos)]["tentimes"], 20 if method == 3 else 2)
                self.assertEqual(committed["recruit_state"][str(pos)]["consum"], original["recruit_state"][str(pos)]["consum"] + 2 * cost)
                for key in ("gold", "coin", "stamina"):
                    self.assertEqual(committed["role_state"][key], original["role_state"][key])
                self.assertEqual(committed["world_state"]["1200"], original["world_state"]["1200"])
                roster = self.entity_records(self.query_world(1002), 1, 2)
                self.assertEqual(sum(protocol.pb_get_varint(v, 1) == 10409 for v in roster.values()), 1)

    def test_live_recruit_saves_before_reply_and_retry_does_not_charge_twice(self):
        self.complete_tutorial()
        self.give_props({20100: 2})
        request = self.activity_request(1403, [1, 1])
        conn = ReplayConnection([request, request], 7)
        send = conn.sendall
        before = json.loads(self.save_path.read_text())

        def check_saved(packet):
            saved = json.loads(self.save_path.read_text())
            self.assertEqual(saved["recruit_state"]["1"]["consumtimes"], before["recruit_state"]["1"]["consumtimes"] + 1)
            props = self.entity_records(bytes.fromhex(saved["world_state"]["1200"]), 1, 1)
            old = self.entity_records(bytes.fromhex(before["world_state"]["1200"]), 1, 1)
            self.assertEqual(protocol.pb_get_varint(props[20100], 2), protocol.pb_get_varint(old[20100], 2) - 1)
            send(packet)

        conn.sendall = check_saved
        with redirect_stdout(io.StringIO()):
            self.run_client(conn)
        self.assertEqual(len(conn.responses), 2)
        self.assertEqual(conn.responses[0], conn.responses[1])

    def test_live_recruit_rejects_bad_requests_and_rolls_back_failed_settlement(self):
        self.complete_tutorial()
        body = bytes.fromhex(self.activity_request(1403, [1, 1])["hex"])
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            original, memory = self.save_path.read_bytes(), copy.deepcopy(session.save)
            for data in (b"", b"\x08", body + b"\x08\x01", body + b"\x10\x01", body + b"\x80",
                         b"\x08\x05\x08\x01", b"\x08\x02\x08\x03", b"\x08\x01\x08\x00"):
                replies = session.handle(1403, 20000, data)
                self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in replies], [999999, 1999])
                self.assertEqual(session.save, memory)
                self.assertEqual(self.save_path.read_bytes(), original)
            self.clock.return_value += 360
            with patch.object(player.os, "replace", side_effect=OSError("disk full")):
                with self.assertRaises(OSError):
                    session.handle(1403, 20000, body)
            self.assertEqual(session.save, memory)
            self.assertEqual(self.save_path.read_bytes(), original)
        self.assert_unavailable_response(self.replay([self.activity_request(1403, [1, 3])]), 1403, 20000, "数量不足")
        self.assertEqual(self.save_path.read_bytes(), original)

    def test_recruit_query_validates_state_and_preserves_pool_order(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        saved["recruit_state"] = dict(reversed(list(saved["recruit_state"].items())))
        self.save_path.write_text(json.dumps(saved))
        reply = self.replay([self.activity_request(1402)])[0]
        values = protocol.parse_ids_pb(bytes.fromhex(reply["hex"]))
        self.assertEqual(values[:5], [1, 0, 1, 0, 0])
        self.assertEqual(values[10:15], [0, 1, 0, 0, 86400])
        before = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(1402, [1])]), 1402, 20000, "不接受参数")
        self.assertEqual(self.save_path.read_bytes(), before)
        for invalid in ([], {}, {"1": {}}, dict(saved["recruit_state"], **{"2": {"next_free_at": -1}})):
            saved["recruit_state"] = invalid
            self.save_path.write_text(json.dumps(saved))
            self.assert_rejected(self.activity_request(1402), "招募")

    def test_live_recruit_discount_boundary_and_token_only_payment(self):
        self.complete_tutorial()
        saved = json.loads(self.save_path.read_text())
        opened = self.now - self.now % 86400 - 8 * 3600
        saved["role_snapshot"] = protocol.pb_set_varint(bytes.fromhex(saved["role_snapshot"]), 22, opened).hex()
        start = opened + 5 * 86400
        for now, expected in ((start, 10), (start + 1, 8), (start + 5 * 86400 - 1, 8), (start + 5 * 86400, 10)):
            self.assertEqual(recruit.discount(saved, self.role_config, now), expected)
        self.clock.return_value = start + 1
        player.change_item_count(saved, 20619, 8, self.role_config, self.now)
        self.save_path.write_text(json.dumps(saved))
        gold = saved["role_state"]["gold"]
        response = self.replay([self.activity_request(1403, [3, 2])])[0]
        self.assertEqual(response["opcode"], 1403)
        self.assertNotIn(20619, self.entity_records(self.query_world(1200), 1, 1))
        self.assertEqual(self.query_role()[9], gold)
        before = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(1403, [3, 2])]), 1403, 20000, "20619")
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_live_recruit_overflow_uncreated_and_guide_lock_are_nonmutating(self):
        self.complete_tutorial()
        original = json.loads(self.save_path.read_text())
        for kind in ("uncreated", "guide", "fragments", "iid", "counter", "gold"):
            with self.subTest(kind=kind):
                saved = copy.deepcopy(original)
                pos = 3
                saved["recruit_state"]["3"]["consumtimes"] = 0
                player.change_item_count(saved, 20619, 1, self.role_config, self.now)
                if kind == "uncreated":
                    saved["has_role"] = False
                elif kind == "guide":
                    saved["guide"]["sections"]["1"] = {"status": 1, "step": 30, "steps": [13, 30]}
                elif kind == "fragments":
                    player.change_item_count(saved, 11213, (1 << 31) - 1, self.role_config, self.now)
                elif kind == "iid":
                    pos = 2
                    general = recruit.new_general(10201, (1 << 31) - 1, self.role_config)
                    player.record_slot_update(saved, protocol.encode_pb_field(1, 2, general))
                elif kind == "counter":
                    saved["recruit_state"]["3"]["consumtimes"] = (1 << 31) - 1
                else:
                    pos = 2
                    saved["role_state"]["gold"] = 0
                    saved["recruit_state"]["2"]["next_free_at"] = self.now + 10
                self.save_path.write_text(json.dumps(saved))
                before = self.save_path.read_bytes()
                response = self.replay([self.activity_request(1403, [pos, 1])])
                self.assertEqual([r["opcode"] for r in response], [999999, 1999])
                self.assertEqual(self.save_path.read_bytes(), before)

    def test_live_recruit_determinism_legacy_migration_and_changed_retry(self):
        self.complete_tutorial()
        saved = json.loads(self.save_path.read_text())
        del saved["recruit_state"]
        self.assertEqual(recruit.get_state(saved)["3"]["freetimes"], 1)
        self.assertEqual(recruit.get_state(saved)["1"]["consumtimes"], 1)
        self.assertEqual(recruit.get_state(saved)["3"]["next_free_at"], 0)
        request = bytes.fromhex(self.activity_request(1403, [1, 2])["hex"])
        first, second = copy.deepcopy(saved), copy.deepcopy(saved)
        self.assertEqual(recruit.draw(first, request, self.role_config, self.now, 73),
                         recruit.draw(second, request, self.role_config, self.now, 73))
        self.assertEqual(first, second)
        self.save_path.write_text(json.dumps(saved))
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            body = bytes.fromhex(self.activity_request(1403, [2, 1])["hex"])
            session.handle(1403, 21000, body)
            self.clock.return_value += 1
            session.handle(1001, 21001, b"")
            before = self.save_path.read_bytes()
            reply = session.handle(1403, 21000, body)
            self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in reply], [999999, 1999])
            self.assertEqual(self.save_path.read_bytes(), before)

    def test_invalid_recharge_recruit_and_unsupported_comb_return_native_errors(self):
        self.replay(self.requests)
        before = self.save_path.read_bytes()
        for opcode in (115, 116, 20000, 1401, 7111, 7112, 7113):
            request = self.activity_request(opcode, [1])
            self.assert_unavailable_response(self.replay([request]), opcode, 20000, "充值" if opcode in (115, 116, 20000) else "招募")
            comb = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, opcode)
                                           + protocol.encode_pb_field(2, 2, bytes.fromhex(request["hex"])))
            response = self.replay([{"opcode": 999900, "seq": 21000, "hex": comb.hex()}])
            self.assert_unavailable_response(response, 999900, 21000, "充值" if opcode in (115, 116, 20000) else "招募")
            self.assertEqual(self.save_path.read_bytes(), before)

    def recharge_order(self, cid):
        body = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, cid))
        response = self.replay([{"opcode": 115, "seq": 20000, "hex": body.hex()}])[0]
        self.assertEqual(response["opcode"], 115)
        param = next(v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(response["hex"])) if n == 1)
        return protocol.pb_get_varint(param, 1)

    def test_simulated_recharge_persists_order_and_confirms_only_once(self):
        self.complete_tutorial()
        gold = self.query_role()[9]
        self.assertEqual(protocol.parse_ids_pb(self.query_world(117)), [1, 0, 0])
        order = self.recharge_order(3)
        self.assertEqual(self.recharge_order(3), order)
        self.assertEqual(self.query_role()[9], gold)
        request = self.activity_request(116, [order])
        conn = ReplayConnection([request, request], 7)
        send = conn.sendall

        def check_committed(packet):
            saved = json.loads(self.save_path.read_text())
            self.assertTrue(saved["recharge_state"]["paid"])
            self.assertEqual(saved["role_state"]["gold"], gold + 132)
            send(packet)

        conn.sendall = check_committed
        with redirect_stdout(io.StringIO()):
            self.run_client(conn)
        self.assertEqual([r["opcode"] for r in conn.responses], [116, 116])
        self.assertIsNone(protocol.pb_get_varint(bytes.fromhex(conn.responses[1]["hex"]), 2))
        self.replay([request])  # A new connection must not grant the same payment again.
        self.assertEqual(self.query_role()[9], gold + 132)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(117)), [2, 6, 1])
        self.assertEqual(protocol.parse_ids_pb(self.query_world(2099))[2], 1)
        next_order = self.recharge_order(3)
        self.assertGreater(next_order, order)
        self.replay([self.activity_request(116, [next_order])])
        self.assertEqual(self.query_role()[9], gold + 198)
        before = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([request]), 116, 20000, "过期")
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_simulated_recharge_first_gift_deduplicates_owned_general(self):
        self.complete_tutorial()
        saved = json.loads(self.save_path.read_text())
        player.apply_reward(saved, recruit.build_reward(saved, [(10405, 1)], self.role_config), self.role_config, self.now)
        self.save_path.write_text(json.dumps(saved))
        self.replay([self.activity_request(116, [self.recharge_order(8)])])
        role = self.query_role()
        self.assertEqual(role[9], saved["role_state"]["gold"] + 23340)
        self.assertEqual(role[4], recharge.vip({"rmb": 648}, self.role_config))
        response = self.replay([self.activity_request(2098)])[0]
        reward = bytes.fromhex(response["hex"])
        self.assertEqual(response["opcode"], 2098)
        self.assertEqual(protocol.pb_get_varint(reward, 1), 1000000)
        self.assertFalse(any(n == 8 for n, _, _ in protocol.iter_pb_fields(reward)))
        fragments = self.entity_records(self.query_world(1012), 1, 1)
        self.assertEqual(protocol.pb_get_varint(fragments[10405], 2), self.role_config["general_fragment"]["11405"]["recruit"])
        self.assertEqual(protocol.parse_ids_pb(self.query_world(117))[2], 2)
        before = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(2098)]), 2098, 20000, "已领取")
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_simulated_month_cards_renew_daily_at_utc8_and_keep_claims(self):
        self.complete_tutorial()
        midnight = (self.now + 8 * 3600) // 86400 * 86400 - 8 * 3600 + 86400
        self.clock.return_value = midnight - 1
        for cid in (1, 2):
            self.replay([self.activity_request(116, [self.recharge_order(cid)])])
        self.assertEqual(protocol.parse_ids_pb(self.query_world(2090)), [30, 1, 1, 1])
        self.assertEqual(protocol.parse_ids_pb(self.query_world(2092)), [1, 1, 0, 0])
        for cid in (1, 2):
            self.assertEqual(self.replay([self.activity_request(2091, [cid])])[0]["opcode"], 2091)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(2090)), [30, 2, 1, 2])
        before = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(2091, [1])]), 2091, 20000, "已领取")
        self.assertEqual(self.save_path.read_bytes(), before)
        self.clock.return_value = midnight
        self.assertEqual(protocol.parse_ids_pb(self.query_world(2090)), [29, 1, 1, 1])
        self.assertEqual(self.replay([self.activity_request(2091, [1])])[0]["opcode"], 2091)
        self.clock.return_value -= 2
        self.assert_unavailable_response(self.replay([self.activity_request(2091, [1])]), 2091, 20000, "已领取")
        self.clock.return_value = midnight
        self.replay([self.activity_request(116, [self.recharge_order(1)])])
        self.assertEqual(protocol.parse_ids_pb(self.query_world(2090)), [59, 2, 1, 1])
        self.assertEqual(self.replay([self.activity_request(2093, [2])])[0]["opcode"], 2093)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(2092)), [1, 2, 0, 0])
        self.clock.return_value = midnight + 59 * 86400
        self.assertEqual(protocol.parse_ids_pb(self.query_world(2090)), [0, 0, 1, 1])
        self.assert_unavailable_response(self.replay([self.activity_request(2091, [1])]), 2091, 20000, "未生效")

    def test_simulated_recharge_invalid_overflow_and_failed_save_are_atomic(self):
        self.complete_tutorial()
        for opcode, body in ((115, b""), (115, b"\x0a\x02\x08\x09"), (115, b"\x0a\x02\x08\x03\x10\x01"),
                             (116, b"\x08\x01"), (117, b"\x08\x01"), (2098, b""), (2093, b"\x08\x01")):
            before = self.save_path.read_bytes()
            response = self.replay([{"opcode": opcode, "seq": 20000, "hex": body.hex()}])
            self.assertEqual([r["opcode"] for r in response], [999999, 1999])
            self.assertEqual(self.save_path.read_bytes(), before)
        order = self.recharge_order(3)
        body = bytes.fromhex(self.activity_request(116, [order])["hex"])
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
            with patch.object(player.os, "replace", side_effect=OSError("disk full")):
                with self.assertRaises(OSError):
                    session.handle(116, 20001, body)
            self.assertEqual(session.save, memory)
            self.assertEqual(self.save_path.read_bytes(), disk)
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            session.save["role_state"]["gold"] = (1 << 31) - 1
            memory = copy.deepcopy(session.save)
            self.assertEqual(struct.unpack(">IIII", session.handle(116, 20001, body)[0][:16])[2], 999999)
            self.assertEqual(session.save, memory)
            self.assertEqual(self.save_path.read_bytes(), disk)

    def test_fengshen_single_spends_token_then_gold_and_grants_fragments(self):
        self.complete_tutorial()
        self.give_props({20618: 1, 1001: 1000})
        gold = self.query_role()[9]
        config = copy.deepcopy(self.role_config)
        config["recruit_deck"]["10000017"]["resourceid"] = "11595,2,1;"
        with patch.object(self, "role_config", config):
            for expected in (gold, gold - 500):
                reply = self.replay([self.activity_request(1403, [4, 1])])[0]
                self.assertEqual(reply["opcode"], 1403)
                result = dict(protocol.get_comb_messages(bytes.fromhex(reply["hex"])))
                self.assertEqual(protocol.parse_ids_pb(result[2]), [11595, 2])
                self.assertEqual(self.query_role()[9], expected)
        self.assertNotIn(20618, self.entity_records(self.query_world(1200), 1, 1))
        self.assertEqual(protocol.pb_get_varint(self.entity_records(self.query_world(1012), 1, 1)[10595], 2), 4)

    def test_fengshen_preview_refresh_claim_and_reconnect(self):
        self.complete_tutorial()
        self.give_props({1001: 8000})
        original = json.loads(self.save_path.read_text())
        request = self.activity_request(7111)
        response = self.replay([request, request])
        self.assertEqual(response[0], response[1])
        initial = protocol.parse_ids_pb(bytes.fromhex(response[0]["hex"]))
        self.assertEqual(len(initial), 20)
        self.assertIn(str(initial[0]), self.role_config["general"])
        saved = json.loads(self.save_path.read_text())
        self.assertEqual(saved["world_state"], original["world_state"])
        self.assertEqual(saved["role_state"]["gold"], original["role_state"]["gold"] - 5000)
        self.assertEqual(protocol.parse_ids_pb(self.query_world(7110)), [0, 0] + initial)
        self.assert_unavailable_response(self.replay([request]), 7111, 20000, "先领取")
        refresh = self.replay([self.activity_request(7112)])[0]
        pending = protocol.parse_ids_pb(bytes.fromhex(refresh["hex"]))
        self.assertEqual(protocol.parse_ids_pb(self.query_world(7110)), [0, 1] + pending)
        self.assertEqual(self.query_role()[9], original["role_state"]["gold"] - 5998)
        self.assertEqual(json.loads(self.save_path.read_text())["world_state"], original["world_state"])
        claim = self.activity_request(7113)
        replies = self.replay([claim, claim])
        self.assertEqual(replies[0], replies[1])
        self.assertEqual(protocol.parse_ids_pb(self.query_world(7110)), [1])
        roster = self.entity_records(self.query_world(1002), 1, 2)
        self.assertIn(pending[0], [protocol.pb_get_varint(v, 1) for v in roster.values()])
        self.assert_unavailable_response(self.replay([claim]), 7113, 20000, "没有待领取")
        self.give_props({20618: 10})
        gold = self.query_role()[9]
        self.assertEqual(self.replay([request])[0]["opcode"], 7111)
        self.assertEqual(self.query_role()[9], gold)
        self.assertNotIn(20618, self.entity_records(self.query_world(1200), 1, 1))

    def test_fengshen_failed_refresh_or_save_preserves_previous_preview(self):
        self.complete_tutorial()
        self.give_props({20618: 10})
        self.replay([self.activity_request(7111)])
        before = self.save_path.read_bytes()
        self.assert_unavailable_response(self.replay([self.activity_request(7112)]), 7112, 20000, "不足")
        self.assertEqual(self.save_path.read_bytes(), before)
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            memory = copy.deepcopy(session.save)
            with patch.object(player.os, "replace", side_effect=OSError("disk full")):
                with self.assertRaises(OSError):
                    session.handle(7113, 20001, b"")
            self.assertEqual(session.save, memory)
            self.assertEqual(self.save_path.read_bytes(), before)

    def change_general_request(self, sid, iid):
        body = protocol.encode_pb_field(1, 0, sid) + protocol.encode_pb_field(3, 0, iid)
        return {"opcode": 1003, "seq": 20000, "hex": body.hex()}

    def test_formation_replacement_inherits_equipment_and_is_reversible(self):
        self.complete_tutorial()
        saved = json.loads(self.save_path.read_text())
        player.apply_reward(saved, recruit.build_reward(saved, [(10401, 1)], self.role_config), self.role_config, self.now)
        self.save_path.write_text(json.dumps(saved))
        before = self.entity_records(self.query_world(1002), 1, 2)
        slots = self.entity_records(self.query_world(1002), 4, 1)
        iid = next(k for k, v in before.items() if protocol.pb_get_varint(v, 1) == 10401)
        old_iid = protocol.pb_get_varint(slots[3], 2)
        replies = self.replay([self.change_general_request(3, iid)])
        self.assertEqual([r["opcode"] for r in replies[:2]], [1003, 205])
        current = self.entity_records(self.query_world(1002), 4, 1)
        self.assertEqual(protocol.pb_get_varint(current[3], 2), iid)
        self.assertEqual([protocol.pb_get_varint(current[3], i) for i in range(4, 10)],
                         [protocol.pb_get_varint(slots[3], i) for i in range(4, 10)])
        self.assertGreater(protocol.pb_get_varint(self.entity_records(self.query_world(1002), 1, 2)[iid], 6),
                           protocol.pb_get_varint(before[iid], 6))
        self.replay([self.change_general_request(3, old_iid)])
        after = self.entity_records(self.query_world(1002), 1, 2)
        for key in before:
            self.assertEqual(dict((n, v) for n, w, v in protocol.iter_pb_fields(after[key])),
                             dict((n, v) for n, w, v in protocol.iter_pb_fields(before[key])))
        self.replay([self.activity_request(1009, [2, 1, 0, 0, 0, 0, 0])])
        current = self.entity_records(self.query_world(1002), 4, 1)
        self.assertEqual(protocol.pb_get_varint(current[2], 2), protocol.pb_get_varint(slots[1], 2))
        self.assertEqual(protocol.pb_get_varint(current[2], 4), protocol.pb_get_varint(slots[1], 4))
        self.assertEqual(self.entity_records(self.query_world(1002), 1, 2), after)

    def test_formation_invalid_locked_duplicate_and_failed_save_are_atomic(self):
        self.complete_tutorial()
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            memory, disk = copy.deepcopy(session.save), self.save_path.read_bytes()
            requests = [self.change_general_request(1, 0), self.change_general_request(2, 987654),
                        self.change_general_request(4, 7060), self.activity_request(1009, [2, 2, 0, 0, 0, 0, 0]),
                        self.activity_request(1009, [2, 1]), {"opcode": 1003, "seq": 20000, "hex": "080210011800"}]
            for request in requests:
                packet = session.handle(request["opcode"], request["seq"], bytes.fromhex(request["hex"]))[0]
                self.assertEqual(struct.unpack(">IIII", packet[:16])[2], 999999)
                self.assertEqual(session.save, memory)
                self.assertEqual(self.save_path.read_bytes(), disk)
            with patch.object(player.os, "replace", side_effect=OSError("disk full")):
                with self.assertRaises(OSError):
                    session.handle(1009, 20001, bytes.fromhex(self.activity_request(1009, [2, 1, 0, 0, 0, 0, 0])["hex"]))
            self.assertEqual(session.save, memory)
            self.assertEqual(self.save_path.read_bytes(), disk)

    def test_formation_relation_growth_survives_battle_and_unequip(self):
        self.complete_tutorial()
        saved = json.loads(self.save_path.read_text())
        raw = recruit.new_general(10213, 2000001, self.role_config)
        # Replace the tutorial thunder general with a fresh one to measure exact growth.
        player.record_slot_update(saved, protocol.encode_pb_field(1, 2, raw))
        self.save_path.write_text(json.dumps(saved))
        self.replay([self.change_general_request(2, 2000001)])
        with patch.object(player.random, "getrandbits", return_value=42):
            result = self.replay([self.activity_request(1306, [42102, 2])])[0]
        self.assertEqual(result["opcode"], 1306)
        self.assertEqual(protocol.pb_get_varint(bytes.fromhex(result["hex"]), 1), 1)
        self.replay([self.change_general_request(2, 7060)])
        changed = self.entity_records(self.query_world(1002), 1, 2)[2000001]
        level = protocol.pb_get_varint(changed, 3)
        self.assertGreater(level, 1)
        row = self.role_config["general"]["10213"]
        self.assertEqual(protocol.pb_get_varint(changed, 6), row["atk"] + row["atk-grow"] * (level - 1))

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
        self.assert_unavailable_response(responses, 999900, 10000, "关卡")
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
            if struct.unpack(">I", packet[8:12])[0] == 1000:
                return sendall(packet)
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

    def test_activity_hints_follow_created_role_and_hide_unsupported_pages(self):
        fresh = self.hint_map(self.query_world(1032))
        self.assertEqual({mid: fresh[mid] for mid in (40, 82, 83, 84, 85, 542)}, dict.fromkeys((40, 82, 83, 84, 85, 542), 0))
        self.assertFalse(self.save_path.exists())
        self.replay(self.requests)
        hints = self.hint_map(self.query_world(1032))
        self.assertEqual({mid: hints[mid] for mid in (40, 82, 84)}, {40: 1, 82: 1, 84: 1})
        self.assertTrue(all(hints[mid] == 0 for mid in (83, *range(85, 110), 542)))

    def test_activity_hint_subset_preserves_requested_order_and_duplicates(self):
        self.replay_through(12)
        request = dict(self.activity_request(1032, (84, 82, 40, 82, 85, 542, 83)), seq=31)
        responses = self.replay([request])
        self.assertEqual(len(responses), 1)
        self.assertEqual((responses[0]["opcode"], responses[0]["seq"]), (1032, 31))
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(responses[0]["hex"])), [0, 1, 0, 1, 0, 0, 0])

    def test_mixed_unrecorded_hint_parameters_remain_non_mutating(self):
        self.replay_through(12)
        original = self.save_path.read_bytes()
        request = self.activity_request(1032, (82, 579))
        self.clock.return_value = self.now + 360
        self.assert_unavailable_response(self.replay([request]), 1032, 20000, "尚未实现")
        self.assertEqual(self.save_path.read_bytes(), original)

    def test_activity_hint_changes_activate_and_clear_on_eligible_operations(self):
        self.replay_through(98)
        responses = self.replay([self.by_seq[99]])
        self.assertEqual([self.hint_changes(f) for f in responses if f["opcode"] == 1034], [{40: 1}])
        responses = self.replay([f for f in self.requests if 99 < f["seq"] <= 107])
        self.assertEqual([self.hint_changes(f) for f in responses if f["opcode"] == 1034], [{84: 1}])
        for opcode, reward, hint in ((3611, 80001, 82), (3611, 80030, 84), (2411, 116, 40)):
            responses = self.replay([self.activity_request(opcode, (reward,))])
            self.assertEqual([(f["opcode"], f["seq"]) for f in responses], [(opcode, 20000), (1034, 0)])
            self.assertEqual(self.hint_changes(responses[-1]), {hint: 0})
        hints = self.hint_map(self.query_world(1032))
        self.assertEqual([hints[mid] for mid in (40, 82, 84)], [0, 0, 0])

    def test_activity_hint_refresh_in_same_connection_does_not_repeat_push(self):
        self.replay_through(12)
        query = self.activity_request(1032, (82,))
        responses = self.replay([query, self.activity_request(3611, (80001,)), query, query], chunk_size=7)
        self.assertEqual([f["opcode"] for f in responses], [1032, 3611, 1034, 1032, 1032])
        self.assertEqual([protocol.parse_ids_pb(bytes.fromhex(f["hex"])) for f in responses if f["opcode"] == 1032],
                         [[1], [0], [0]])
        self.assertEqual(self.hint_changes(responses[2]), {82: 0})

    def test_reconnect_init_hints_do_not_restore_claimed_activity_notifications(self):
        self.replay(self.requests)
        for opcode, reward in ((3611, 80001), (3611, 80030), (2411, 116)):
            self.replay([self.activity_request(opcode, (reward,))])
        init = self.replay([dict(self.by_seq[12], seq=30000)])
        self.assertEqual(len(init), 1)
        body = dict(protocol.get_comb_messages(bytes.fromhex(init[0]["hex"])))[1032]
        hints = self.hint_map(body)
        self.assertEqual([hints[mid] for mid in (40, 82, 84)], [0, 0, 0])
        subset = self.replay([self.activity_request(1032, (82, 84, 40))])[0]
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(subset["hex"])), [0, 0, 0])

    def test_failed_activity_save_does_not_clear_or_push_hints(self):
        self.replay(self.requests)
        for opcode, reward in ((3611, 80001), (3611, 80030), (2411, 116)):
            with patch.object(player.os, "replace", side_effect=OSError("disk failure")):
                self.assert_rejected(self.activity_request(opcode, (reward,)), "保存失败")
        hints = self.hint_map(self.query_world(1032))
        self.assertEqual([hints[mid] for mid in (40, 82, 84)], [1, 1, 1])

    def test_activity_hint_push_is_sent_only_after_entire_claim_is_saved(self):
        self.replay_through(12)
        before = json.loads(self.save_path.read_text())
        conn = ReplayConnection([self.activity_request(3611, (80001,))], 7)
        sendall = conn.sendall

        def check_saved_before_send(packet):
            saved = json.loads(self.save_path.read_text())
            self.assertIn(80001, saved["activity_state"]["begin7day_claimed"])
            self.assertEqual(saved["silver"], before["silver"] + 20000)
            props = self.entity_records(bytes.fromhex(saved["world_state"]["1200"]), 1, 1)
            self.assertEqual(protocol.pb_get_varint(props[20014], 2), 1)
            sendall(packet)

        conn.sendall = check_saved_before_send
        with redirect_stdout(io.StringIO()):
            self.run_client(conn)
        self.assertTrue(conn.closed)
        self.assertEqual([f["opcode"] for f in conn.responses], [3611, 1034])
        self.assertEqual(self.hint_changes(conn.responses[-1]), {82: 0})

    def test_activity_hint_rewrite_preserves_unrelated_and_unknown_fields(self):
        request = next(f for f in self.requests if f["opcode"] == 1032 and not f["hex"])
        extra = protocol.encode_pb_field(50, 2, b"keep")
        body = b"".join(protocol.encode_pb_field(1, 0, v) for v in (12345, 8201, 8200)) + extra
        response = dict(self.recorded[(request["seq"], 1032)], hex=body.hex())
        with redirect_stdout(io.StringIO()):
            self.tables = replay.build_routing_tables([self.by_seq[12], self.recorded[(12, 999900)], request, response])
        actual = self.query_world(1032)
        fields = list(protocol.iter_pb_fields(actual))
        self.assertIn((50, 2, b"keep"), fields)
        self.assertIn((1, 0, 12345), fields)
        self.assertEqual([v for n, w, v in fields if n == 1 and w == 0 and v // 100 == 82], [8200, 8200])
        self.assertTrue(all(self.hint_map(actual)[mid] == 0 for mid in (40, 84, 542)))

    def test_malformed_hint_query_does_not_mutate_save(self):
        self.replay_through(12)
        for body in ("08", "0800", "0a0152", "1052", "08521001", "08" + "ff" * 9 + "01"):
            with self.subTest(body=body):
                self.assert_rejected({"opcode": 1032, "seq": 20000, "hex": body}, "红点查询格式错误")

    def test_activity_save_failure_is_atomic(self):
        self.replay(self.requests)
        for opcode, values in ((3611, (80001,)), (3611, (80030,)), (2411, (116,))):
            with self.subTest(opcode=opcode, values=values), patch.object(player.os, "replace", side_effect=OSError("disk failure")):
                self.assert_rejected(self.activity_request(opcode, values), "保存失败")

    def test_anniversary_query_supplies_every_configured_count_and_status(self):
        response = self.replay([self.activity_request(4600)])[0]
        values = protocol.parse_ids_pb(bytes.fromhex(response["hex"]))
        self.assertEqual(len(values), 30)
        for row in self.role_config["mid_autumn_exchange"].values():
            # Lua 用 ID 作数组下标，然后计算 limit - 已兑次数。
            count, status = values[2 * row["id"] - 2:2 * row["id"]]
            self.assertEqual((count, status), (0, 0))
            self.assertEqual(row["limit"] - count, row["limit"])
        self.assertFalse(self.save_path.exists())

    def test_anniversary_query_can_reopen_after_tutorial_and_reconnect(self):
        self.replay(self.requests)
        before = self.save_path.read_bytes()
        first = self.replay([self.activity_request(4600)])[0]
        second = self.replay([self.activity_request(4600)])[0]
        self.assertEqual(first, second)
        self.assertEqual(len(protocol.parse_ids_pb(bytes.fromhex(first["hex"]))), 30)
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_anniversary_query_matches_official_capture(self):
        capture = json.loads((Path(server.BASE_DIR) / "official_battle_capture_20261028_2014.json").read_text())
        frames = capture["connections"][0]["frames"]
        request = next(f for f in frames if f["c2s"] and f["opcode"] == 4600)
        reply = next(f for f in frames if not f["c2s"] and f["opcode"] == 4600 and f["seq"] == request["seq"])
        raw = (Path(server.BASE_DIR) / capture["source"]).read_bytes()
        self.assertIn(protocol.pack_frame(4600, reply["seq"], bytes.fromhex(reply["hex"])), raw)
        self.assertEqual(self.replay([request])[0]["hex"], reply["hex"])

    def seed_activity_account(self, gold=5000):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        snapshot = bytes.fromhex(saved["role_snapshot"])
        saved["role_snapshot"] = protocol.pb_set_varint(snapshot, 22, self.now - 4 * 86400).hex()
        saved["role_state"]["gold"] = gold
        self.save_path.write_text(json.dumps(saved))
        return saved

    def test_battle_math_matches_every_hit_and_experience_in_official_samples(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        samples = []
        for name in ("2014", "2017"):
            capture = json.loads((Path(server.BASE_DIR) / f"official_battle_capture_20261028_{name}.json").read_text())
            for connection in capture["connections"]:
                for reply in connection["frames"]:
                    if not reply["c2s"] and reply["opcode"] == 1306:
                        request = next(f for f in connection["frames"]
                                       if f["c2s"] and f["opcode"] == 1306 and f["seq"] == reply["seq"])
                        samples.append((request, reply))
        self.assertEqual(len(samples), 3)
        for request, reply in samples:
            with self.subTest(seq=reply["seq"]):
                location = protocol.parse_ids_pb(bytes.fromhex(request["hex"]))
                point = self.role_config["copy"][str(location[0])][str(location[1])]
                attack, defense = battle.rosters(saved, point, self.role_config)
                values = {n: v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(reply["hex"]))}
                report = json.loads(values[5])
                for side, units in (("attack", attack), ("defense", defense)):
                    for pos, unit in units.items():
                        self.assertEqual(report["b"]["init"][side][str(pos)]["i"], unit["iid"])
                        meta = report["meta"][side]["g"][str(unit["iid"])]
                        self.assertEqual((meta["c"], meta["h"], meta["d"]["i"]), (unit["cid"], unit["hp"], unit["skill"]))
                for action in report["b"]["a"]:
                    source = action["s"]
                    if not source:
                        continue
                    attacker = (attack if source["r"] else defense)[source["p"][0]]
                    for dest in action["e"]:
                        if "m" not in dest:
                            continue
                        defender = (attack if dest["r"] else defense)[dest["p"]]
                        amount = battle.damage(attacker, defender, self.role_config, source.get("S"), dest["m"]["u"] == "C")
                        self.assertEqual(amount, dest["m"]["m"], (source, dest))
                        defender["hp"] -= amount
                for side, units in (("attack", attack), ("defense", defense)):
                    for pos, unit in units.items():
                        self.assertEqual(unit["hp"], report["endmeta"][side][str(pos)]["h"])
                result = battle.victory_role_reward(saved["role_state"], point, 3 if location[1] == 1 else 0, values[2], self.role_config)
                exp = {n: v for n, w, v in protocol.iter_pb_fields(values[3])}
                self.assertEqual((result["gained"], result["level"], result["exp"]), (exp[1], exp[2], exp[3]))
                self.assertEqual((result["coin"], result["gold"]), (protocol.pb_get_varint(values[4], 1), protocol.pb_get_varint(values[4], 2)))
                expected = self.entity_records(bytes.fromhex(reply["hex"]), 6, 2)
                for unit in attack.values():
                    level, experience, up = battle.general_experience(unit, point["xp"], self.role_config)
                    self.assertEqual((level, experience), (protocol.pb_get_varint(expected[unit["iid"]], 3), protocol.pb_get_varint(expected[unit["iid"]], 5)))
                    gained = next(v for n, w, v in protocol.iter_pb_fields(values[3]) if n == 4 and protocol.pb_get_varint(v, 1) == unit["iid"])
                    self.assertEqual(up, protocol.pb_get_varint(gained, 3))
                saved["role_state"].update(level=result["level"], exp=result["exp"])
                # 测试中用本场官方结算建立下一场的战前属性；生产路由不会载入这些样本。
                update = b"".join(protocol.encode_pb_field(1, 2, raw) for raw in expected.values())
                player.record_slot_update(saved, update)

    def test_battle_challenge_validation_uses_current_progress(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        body = bytes.fromhex(self.activity_request(1306, [42102, 2])["hex"])
        point, star = battle.challenge(saved, body, self.role_config)
        self.assertEqual((point["name"], star), ("望乡台", 0))
        for invalid in (b"", body + b"\x10\x01", body + b"\x08\x01", b"\x08"):
            with self.assertRaises(ValueError):
                battle.challenge(saved, invalid, self.role_config)
        with self.assertRaisesRegex(ValueError, "未解锁"):
            battle.challenge(saved, bytes.fromhex(self.activity_request(1306, [42102, 3])["hex"]), self.role_config)
        saved["role_state"]["stamina"] = 1
        with self.assertRaisesRegex(ValueError, "体力不足"):
            battle.challenge(saved, body, self.role_config)

    def test_battle_damage_uses_current_stats_and_caps_lethal_hits(self):
        attacker, defender = {"atk": 1756}, {"def": 694, "hp": 4410}
        self.assertEqual(battle.damage(attacker, defender, self.role_config, 12618, True), 1178)
        attacker["atk"] = 100
        self.assertEqual(battle.damage(attacker, defender, self.role_config), 5)
        attacker["atk"] = 99999
        self.assertEqual(battle.damage(attacker, defender, self.role_config, 12618, True), 4410)

    def test_live_battle_is_deterministic_and_report_replays_to_its_end(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        point = self.role_config["copy"]["42103"]["2"]
        attack, defense = battle.rosters(saved, point, self.role_config)
        before = copy.deepcopy((attack, defense))
        report = battle.simulate(attack, defense, self.role_config, 45)
        self.assertEqual(report, battle.simulate(attack, defense, self.role_config, 45))
        self.assertEqual((attack, defense), before)
        self.assert_battle_report(report)
        self.assertLessEqual(report["round"], 30)

    def assert_battle_report(self, report):
        units = {}
        for side, direct in (("attack", True), ("defense", False)):
            for pos, unit in report["b"]["init"][side].items():
                meta = report["meta"][side]["g"][str(unit["i"])]
                units[direct, int(pos)] = {"hp": meta["h"], "maxhp": meta["j"], "ap": meta["ap"], "dizzy": False}
        for action in report["b"]["a"]:
            if action["s"]:
                for pos in action["s"]["p"]:
                    self.assertGreater(units[action["s"]["r"], pos]["hp"], 0)
                    self.assertFalse(units[action["s"]["r"], pos]["dizzy"])
            for dest in action["e"]:
                unit = units[dest["r"], dest["p"]]
                if isinstance(dest.get("m"), dict):
                    unit["hp"] -= dest["m"]["m"]
                    self.assertGreaterEqual(unit["hp"], 0)
                    self.assertLessEqual(unit["hp"], unit["maxhp"])
                if "ap" in dest:
                    self.assertGreaterEqual(dest["ap"], 0)
                    unit["ap"] = dest["ap"]
                if dest.get("u", {}).get("u") == "dizzy":
                    unit["dizzy"] = dest["u"]["w"]
        for side, direct in (("attack", True), ("defense", False)):
            for pos, unit in report["endmeta"][side].items():
                self.assertEqual((unit["h"], unit["ap"]), (units[direct, int(pos)]["hp"], units[direct, int(pos)]["ap"]))
        won = all(v["h"] == 0 for v in report["endmeta"]["defense"].values()) and any(v["h"] > 0 for v in report["endmeta"]["attack"].values())
        self.assertEqual(report["result"], won)
        self.assertEqual(bool(report["star"]), won)

    def test_live_battle_saves_rewards_growth_and_repeat_before_reply(self):
        self.replay(self.requests)
        before = json.loads(self.save_path.read_text())
        request = self.activity_request(1306, [42102, 2])
        conn = ReplayConnection([request], 7)
        send = conn.sendall

        def check_saved_before_send(packet):
            committed = json.loads(self.save_path.read_text())
            self.assertEqual(committed["last_battle"]["point"], 2)
            self.assertEqual(committed["role_state"]["stamina"], before["role_state"]["stamina"] - 2)
            send(packet)

        conn.sendall = check_saved_before_send
        with redirect_stdout(io.StringIO()), patch.object(player.random, "getrandbits", return_value=42):
            self.run_client(conn)
        replies = conn.responses
        self.assertEqual([r["opcode"] for r in replies[:3]], [1306, 205, 1001])
        result = next(r for r in replies if r["opcode"] == 1306)
        fields = {n: v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(result["hex"]))}
        self.assertEqual(fields[1], 1)
        self.assert_battle_report(json.loads(fields[5]))
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["role_state"]["stamina"], before["role_state"]["stamina"] - 2)
        self.assertGreater((after["role_state"]["level"], after["role_state"]["exp"]), (before["role_state"]["level"], before["role_state"]["exp"]))
        old = self.entity_records(bytes.fromhex(before["world_state"]["1002"]), 1, 2)
        for iid, raw in self.entity_records(bytes.fromhex(after["world_state"]["1002"]), 1, 2).items():
            if protocol.pb_get_varint(raw, 3) > protocol.pb_get_varint(old[iid], 3):
                self.assertGreater(protocol.pb_get_varint(raw, 6), protocol.pb_get_varint(old[iid], 6))
                self.assertGreater(protocol.pb_get_varint(raw, 20), protocol.pb_get_varint(old[iid], 20))
        self.assertEqual(self.query_world(1002).hex(), after["world_state"]["1002"])
        with patch.object(player.random, "getrandbits", return_value=42):
            self.replay([dict(request, seq=20001)])
        copies = self.entity_records(self.query_world(1300), 1, 1)
        point = self.entity_records(copies[42102], 7, 1)[2]
        self.assertEqual(protocol.pb_get_varint(point, 4), 2)
        self.assertEqual(protocol.pb_get_varint(point, 3), 3)

    def test_live_battle_retry_and_failed_save_are_atomic(self):
        self.replay(self.requests)
        with redirect_stdout(io.StringIO()):
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            body = bytes.fromhex(self.activity_request(1306, [42102, 2])["hex"])
            original, memory = self.save_path.read_bytes(), copy.deepcopy(session.save)
            with patch.object(player.os, "replace", side_effect=OSError("disk full")):
                with self.assertRaises(OSError):
                    session.handle(1306, 20000, body)
            self.assertEqual(self.save_path.read_bytes(), original)
            self.assertEqual(session.save, memory)
            # A failed connection is discarded; retry on a new session.
            session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
            first = session.handle(1306, 20000, body)
            committed = self.save_path.read_bytes()
            self.assertEqual(first, session.handle(1306, 20000, body))
            self.assertEqual(self.save_path.read_bytes(), committed)
            session.handle(101, 20001, protocol.encode_pb_field(1, 2, "新名字".encode()))
            changed = self.save_path.read_bytes()
            retry = session.handle(1306, 20000, body)
            self.assertEqual(struct.unpack(">IIII", retry[0][:16])[2], 999999)
            self.assertEqual(self.save_path.read_bytes(), changed)

    def test_live_battle_loss_has_no_rewards_and_does_not_unlock(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        for raw in self.entity_records(bytes.fromhex(saved["world_state"]["1002"]), 1, 2).values():
            for field in (6, 7, 8, 9):
                raw = protocol.pb_set_varint(raw, field, 1)
            player.record_slot_update(saved, protocol.encode_pb_field(1, 2, raw))
            player.record_protagonist_general(saved, raw)
        self.save_path.write_text(json.dumps(saved))
        replies = self.replay([self.activity_request(1306, [42102, 2])])
        fields = {n: v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(replies[0]["hex"]))}
        self.assertEqual((fields[1], fields[2]), (0, 0))
        self.assert_battle_report(json.loads(fields[5]))
        after = json.loads(self.save_path.read_text())
        self.assertEqual(after["world_state"], saved["world_state"])
        for key in ("coin", "gold", "level", "exp"):
            self.assertEqual(after["role_state"][key], saved["role_state"][key])
        self.assertEqual(after["role_state"]["stamina"], saved["role_state"]["stamina"] - 2)

    def combat_unit(self, cid, **values):
        return {"cid": cid, "iid": cid, "level": 1, "advance": 0, "exp": 0,
                "atk": 100, "def": 0, "hp": 10000, "speed": 100,
                "skill": self.role_config["general"][str(cid)]["skillid"], **values}

    def test_live_combo_uses_each_initiator_and_zero_ap_partner(self):
        config = copy.deepcopy(self.role_config)
        config["combskillprobability"]["12622"] = dict.fromkeys((f"bout{i}" for i in range(1, 11)), 1)
        report = battle.simulate({8: self.combat_unit(10213, atk=100, speed=200),
                                 10: self.combat_unit(10214, atk=200, speed=190)},
                                {2: self.combat_unit(10201, iid=1, atk=1), 8: self.combat_unit(10201, iid=2, atk=1)}, config, 1)
        self.assert_battle_report(report)
        combos = [a for a in report["b"]["a"] if a["s"].get("S") == 12622]
        self.assertEqual([a["s"]["p"] for a in combos[:2]], [[8, 10], [10, 8]])
        self.assertEqual([a["e"][0]["m"]["m"] for a in combos[:2]], [84, 168])
        self.assertEqual([[d["p"] for d in a["e"] if "ap" in d] for a in combos[:2]], [[8], [10]])

    def test_live_stun_skips_one_turn_and_then_releases(self):
        config = copy.deepcopy(self.role_config)
        config["skill"]["12214"]["effect-trigger"] = 1
        report = battle.simulate({2: self.combat_unit(10214, speed=200)}, {2: self.combat_unit(10201, atk=1)}, config, 1)
        self.assert_battle_report(report)
        turns, rounds, releases = [], 1, []
        for a in report["b"]["a"]:
            if not a["s"] and not a["e"]:
                rounds += 1
            if a["s"] and not a["s"]["r"]:
                turns.append(rounds)
            if any(d.get("u") == {"u": "dizzy", "w": False} for d in a["e"]):
                releases.append(rounds)
        self.assertNotIn(2, turns)
        self.assertIn(3, turns)
        self.assertIn(2, releases)

    def test_live_guard_counts_attacks_and_low_hp_action_is_once(self):
        report = battle.simulate({2: self.combat_unit(10201, speed=200)},
                                {2: self.combat_unit(10224, atk=1, advance=1)}, self.role_config, 1)
        hits = [a["e"][0]["m"]["m"] for a in report["b"]["a"] if a["s"].get("r")]
        self.assertEqual(hits[:3], [40, 80, 100])
        report = battle.simulate({2: self.combat_unit(10112, hp=100, atk=5, advance=2)},
                                {2: self.combat_unit(10201, atk=90, speed=200)}, self.role_config, 1)
        self.assert_battle_report(report)
        sources = [a["s"] for a in report["b"]["a"] if a["s"]]
        self.assertEqual([s["r"] for s in sources[:4]], [False, True, True, False])

    def test_live_lifesteal_poison_and_round_limit(self):
        report = battle.simulate({2: self.combat_unit(10201, atk=200, speed=200)},
                                {2: self.combat_unit(10303)}, self.role_config, 1)
        self.assert_battle_report(report)
        i = next(i for i, a in enumerate(report["b"]["a"]) if a["s"].get("S") == 12303)
        self.assertEqual(report["b"]["a"][i + 1]["e"][0]["m"]["m"], -64)
        config = copy.deepcopy(self.role_config)
        config["skill"]["12302"]["effect-trigger"] = 1
        report = battle.simulate({2: self.combat_unit(10302, speed=200)},
                                {2: self.combat_unit(10201, atk=1)}, config, 1)
        self.assert_battle_report(report)
        ticks = [d["m"]["m"] for a in report["b"]["a"] for d in a["e"]
                 if isinstance(d.get("m"), dict) and d["m"]["u"] == "dot"]
        self.assertTrue(ticks)
        self.assertEqual(set(ticks), {10})
        unit = self.combat_unit(10201, atk=1, **{"def": 10000})
        report = battle.simulate({2: unit}, {2: unit}, config, 1)
        self.assertEqual((report["round"], report["result"], report["star"]), (30, False, 0))
        self.assert_battle_report(report)

    def test_live_battle_all_supported_points_generate_consistent_reports(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        for mid in battle.MAPS:
            for pid, point in self.role_config["copy"][str(mid)].items():
                with self.subTest(map=mid, point=pid):
                    attack, defense = battle.rosters(saved, point, self.role_config)
                    self.assert_battle_report(battle.simulate(attack, defense, self.role_config, 7))

    def test_all_recruitable_generals_generate_replayable_battles(self):
        ids = set()
        for row in self.role_config["recruit_basic"].values():
            for key in ("freecardgroupid", "freefirstcardgroupid", "normalfirstcardgroupid", "firsttentavern"):
                if row[key]:
                    ids.update(int(e.split(",")[0]) for e in self.role_config["recruit_deck"][str(row[key])]["resourceid"].split(";") if e)
        ids.add(self.role_config["firstpay"]["1"]["goods2"])
        for cid in sorted(ids):
            if str(cid) not in self.role_config["general"] or not self.role_config["general"][str(cid)]["battle"]:
                continue
            with self.subTest(cid=cid):
                attack = {2: self.combat_unit(cid, speed=200), 8: self.combat_unit(10213, iid=2)}
                defense = {2: self.combat_unit(10201, iid=3, parry=50), 8: self.combat_unit(10201, iid=4)}
                report = battle.simulate(attack, defense, self.role_config, 7)
                self.assert_battle_report(report)
                self.assertEqual(report["rules"], "zyj-v2")

    def test_healing_selects_lowest_hp_ally_and_caps_at_maximum(self):
        for enemy_atk, expected in ((400, -150), (1, -3)):
            with self.subTest(enemy_atk=enemy_atk):
                report = battle.simulate({8: self.combat_unit(10305, speed=200), 2: self.combat_unit(10201, atk=1)},
                                         {2: self.combat_unit(10201, iid=1, atk=enemy_atk, speed=300)}, self.role_config, 1)
                self.assert_battle_report(report)
                action = next(a for a in report["b"]["a"] if a["s"].get("S") == 12305)
                self.assertEqual((action["e"][0]["r"], action["e"][0]["p"], action["e"][0]["m"]["m"]), (True, 2, expected))

    def test_defense_buffs_expire_and_reduce_real_damage(self):
        report = battle.simulate({8: self.combat_unit(10610, speed=200), 2: self.combat_unit(10201, speed=50, **{"def": 100})},
                                 {2: self.combat_unit(10201, iid=1, atk=200)}, self.role_config, 1)
        self.assert_battle_report(report)
        hits = [d["m"]["m"] for a in report["b"]["a"] if a["s"] and not a["s"]["r"]
                for d in a["e"] if isinstance(d.get("m"), dict)]
        self.assertEqual(hits[:4], [105, 162, 81, 105])
        switches = [d["B"]["w"] for a in report["b"]["a"] for d in a["e"] if d.get("B", {}).get("R") == "def"]
        self.assertIn(True, switches)
        self.assertIn(False, switches)

    def test_defense_debuff_and_ap_reduction_affect_following_actions(self):
        config = copy.deepcopy(self.role_config)
        config["skill"]["12311"]["effect-trigger"] = 1
        report = battle.simulate({2: self.combat_unit(10311, speed=200), 8: self.combat_unit(10201, iid=2, speed=100)},
                                 {2: self.combat_unit(10201, iid=3, speed=150, **{"def": 100})}, config, 1)
        self.assert_battle_report(report)
        second_round = next(i for i, a in enumerate(report["b"]["a"]) if a["s"].get("S") == 12311)
        skill = report["b"]["a"][second_round]
        self.assertTrue(any(d.get("ap") == 3 and not d["r"] for d in skill["e"]))
        enemy_turn = next(a for a in report["b"]["a"][second_round + 1:] if a["s"] and not a["s"]["r"])
        self.assertEqual(enemy_turn["s"]["t"], "N")
        ally = next(a for a in report["b"]["a"][second_round + 1:] if a["s"].get("r") and a["s"]["p"] == [8])
        self.assertEqual(ally["e"][0]["m"]["m"], 48)

    def test_queen_passive_heals_survivors_but_never_revives(self):
        for hp, expected in ((10000, -412), (100, None)):
            report = battle.simulate({8: self.combat_unit(10595, speed=50), 2: self.combat_unit(10201, hp=hp)},
                                     {2: self.combat_unit(10201, iid=1, atk=1000, speed=200)}, self.role_config, 1)
            self.assert_battle_report(report)
            actions = report["b"]["a"]
            self.assertEqual(actions[0]["s"]["S"], 12859)
            heals = [d["m"]["m"] for a in actions[2:3] for d in a["e"]
                     if isinstance(d.get("m"), dict) and d["p"] == 2 and d["r"] and d["m"]["m"] < 0]
            self.assertEqual(heals, [] if expected is None else [expected])

    def test_live_battle_first_drop_repeat_and_new_map_survive_reconnect(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        for pid in (2, 3, 4):
            body = bytes.fromhex(self.activity_request(1306, [42102, pid])["hex"])
            player.record_copy_win(saved, body, 3, self.role_config, allow_repeat=True)
        self.save_path.write_text(json.dumps(saved))
        config = copy.deepcopy(self.role_config)
        point = config["copy"]["42102"]["5"]
        point.update(drop1prob=0, drop2prob=0, drop3prob=0, randdropprob=0, randdropprob1=0)
        request = bytes.fromhex(self.activity_request(1306, [42102, 5])["hex"])
        original_iids = set(activities._equipment(saved))
        with redirect_stdout(io.StringIO()), patch.object(player.random, "getrandbits", return_value=1):
            session = Session(self.tables, self.save_path, self.step_counts, config)
            session.handle(1306, 21000, request)
            first = copy.deepcopy(session.save)
            self.assertTrue(first["last_battle"]["won"])
            equipment = activities._equipment(first)
            new_iids = set(equipment) - original_iids
            self.assertEqual(len(new_iids), 1)
            self.assertEqual(equipment[next(iter(new_iids))][1], point["drop"])
            session = Session(self.tables, self.save_path, self.step_counts, config)
            session.handle(1306, 21001, request)
            self.assertTrue(session.save["last_battle"]["won"])
            self.assertEqual(activities._equipment(session.save), equipment)
            copies = self.entity_records(bytes.fromhex(session.save["world_state"]["1300"]), 1, 1)
            self.assertIn(42103, copies)
            self.assertEqual(protocol.pb_get_varint(self.entity_records(copies[42102], 7, 1)[5], 4), 2)
            current = copy.deepcopy(session.save)
            player.record_copy_win(current, request, 1, config, allow_repeat=True)
            copies_after = self.entity_records(bytes.fromhex(current["world_state"]["1300"]), 1, 1)
            self.assertEqual(protocol.pb_get_varint(self.entity_records(copies_after[42102], 7, 1)[5], 3),
                             protocol.pb_get_varint(self.entity_records(copies[42102], 7, 1)[5], 3))

    def test_live_battle_stars_include_threshold_and_order_is_stable(self):
        for incoming, stars in ((30, 3), (31, 2), (70, 2), (71, 1)):
            with self.subTest(damage=incoming):
                report = battle.simulate({2: self.combat_unit(10201, hp=100, atk=100)},
                                         {2: self.combat_unit(10201, hp=100, atk=incoming, speed=200)}, self.role_config, 0)
                self.assertEqual(report["star"], stars)
                self.assert_battle_report(report)
        report = battle.simulate({8: self.combat_unit(10201, iid=2), 2: self.combat_unit(10201, iid=1)},
                                 {2: self.combat_unit(10201, iid=3)}, self.role_config, 0)
        sources = [a["s"] for a in report["b"]["a"] if a["s"]]
        self.assertEqual([(s["r"], s["p"]) for s in sources[:3]], [(True, [2]), (False, [2]), (True, [8])])

    def test_live_battle_rejects_locked_limit_unsupported_and_overflow_atomically(self):
        self.replay(self.requests)
        saved = json.loads(self.save_path.read_text())
        body = bytes.fromhex(self.activity_request(1306, [42102, 2])["hex"])
        for kind in ("locked", "stamina", "limit", "roster", "overflow"):
            modified = copy.deepcopy(saved)
            request = body
            if kind == "locked":
                request = bytes.fromhex(self.activity_request(1306, [42103, 1])["hex"])
            elif kind == "stamina":
                modified["role_state"]["stamina"] = 0
            elif kind == "limit":
                for _ in range(10):
                    player.record_copy_win(modified, body, 3, self.role_config, allow_repeat=True)
            elif kind == "roster":
                raw = self.entity_records(bytes.fromhex(modified["world_state"]["1002"]), 1, 2)[7060]
                player.record_slot_update(modified, protocol.encode_pb_field(1, 2, protocol.pb_set_varint(raw, 21, 1)))
            else:
                modified["role_state"]["coin"] = (1 << 31) - 1
            self.save_path.write_text(json.dumps(modified))
            original = self.save_path.read_bytes()
            with self.subTest(kind=kind), redirect_stdout(io.StringIO()), patch.object(player.random, "getrandbits", return_value=42):
                session = Session(self.tables, self.save_path, self.step_counts, self.role_config)
                memory = copy.deepcopy(session.save)
                packets = session.handle(1306, 21000, request)
                self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 999999)
                self.assertEqual(self.save_path.read_bytes(), original)
                self.assertEqual(session.save, memory)

    def test_activity_tabs_match_official_fields_without_account_history(self):
        self.replay(self.requests)
        capture = json.loads((Path(server.BASE_DIR) / "official_battle_capture_20261028_2014.json").read_text())
        frames = capture["connections"][0]["frames"]
        for opcode in (5010, 4810, 4814, 5020, 5030, 5039):
            with self.subTest(opcode=opcode):
                request = next(f for f in frames if f["c2s"] and f["opcode"] == opcode)
                reply = next(f for f in frames if not f["c2s"] and f["opcode"] == opcode and f["seq"] == request["seq"])
                self.clock.return_value = int(request["timestamp"])
                actual = protocol.parse_ids_pb(bytes.fromhex(self.replay([request])[0]["hex"]))
                expected = protocol.parse_ids_pb(bytes.fromhex(reply["hex"]))
                if opcode == 4810:
                    self.assertEqual(actual, [expected[0], 0])
                elif opcode == 5039:
                    self.assertEqual(actual[:2], expected[:2])
                    self.assertLessEqual(abs(actual[2] - expected[2]), 1)
                    self.assertEqual(actual[3:], [0] * (1 + len(self.role_config["consumegift_reward_1"])))
                else:
                    self.assertEqual(actual, expected)

    def test_activity_subpages_and_queries_reject_extra_fields(self):
        self.seed_activity_account()
        for opcode in activities.PAGE_OPCODES:
            with self.subTest(opcode=opcode):
                reply = self.replay([self.activity_request(opcode)])[0]
                self.assertEqual(reply["opcode"], opcode)
                self.assert_rejected(self.activity_request(opcode, [1]), "活动请求格式错误")
        shop = protocol.parse_ids_pb(bytes.fromhex(self.replay([self.activity_request(5015)])[0]["hex"]))
        self.assertEqual(len(shop), 3 + max(map(int, self.role_config["goddown_exchange_1"])))
        rank = self.replay([self.activity_request(5017)])[0]
        self.assertEqual(self.begin7day_groups(bytes.fromhex(rank["hex"])), {0: [1, 1, 0], 1: []})

    def test_discount_purchase_and_consume_claim_persist_and_do_not_double_charge(self):
        self.seed_activity_account()
        before_props = self.entity_records(self.query_world(1200), 1, 1)
        replies = self.replay([self.activity_request(5031, [1, 1])])
        self.assertEqual(replies[0]["opcode"], 5031)
        reward = bytes.fromhex(replies[0]["hex"])
        self.assertIsNone(protocol.pb_get_varint(reward, 2))
        self.assertEqual(self.query_role()[9], 5000 - 1566)
        after_props = self.entity_records(self.query_world(1200), 1, 1)
        for cid in (20619, 20197):
            self.assertEqual(protocol.pb_get_varint(after_props[cid], 2),
                             (protocol.pb_get_varint(before_props.get(cid, b""), 2) or 0) + 10)
        query = self.replay([self.activity_request(5030), self.activity_request(5039)])
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(query[0]["hex"]))[2:4], [1, 0])
        self.assertEqual(protocol.parse_ids_pb(bytes.fromhex(query[1]["hex"]))[3:6], [1566, 1, 0])
        coin = self.query_role()[8]
        self.assertEqual(self.replay([self.activity_request(5040, [1])])[0]["opcode"], 5040)
        self.assertEqual(self.query_role()[8], coin + 100000)
        saved = json.loads(self.save_path.read_text())
        self.assertEqual(saved["activity_state"]["consume_claimed"], [1])
        before = self.save_path.read_bytes()
        for opcode, ids, reason in ((5031, [1, 1], "限购"), (5040, [1], "已领取"), (5040, [2], "未达成")):
            responses = self.replay([self.activity_request(opcode, ids), self.activity_request(5039)])
            self.assert_unavailable_response(responses[:2], opcode, 20000, reason)
            self.assertEqual(responses[2]["opcode"], 5039)
            self.assertEqual(self.save_path.read_bytes(), before)

    def test_discount_fragments_use_inventory_and_enforce_quantity(self):
        self.seed_activity_account()
        self.replay([self.activity_request(5031, [10, 2])])
        fragments = self.entity_records(self.query_world(1012), 1, 1)
        self.assertEqual(protocol.pb_get_varint(fragments[10505], 2), 10)
        self.assertEqual(self.query_role()[9], 5000 - 288 * 2)
        before = self.save_path.read_bytes()
        for ids in ([10, 3], [10, 0], [14, 1], [1], [1, 1, 1]):
            replies = self.replay([self.activity_request(5031, ids)])
            self.assertEqual(replies[0]["opcode"], 999999)
            self.assertEqual(self.save_path.read_bytes(), before)

    def test_activity_transactions_rollback_insufficient_gold_and_reward_overflow(self):
        saved = self.seed_activity_account(gold=0)
        for gold, overflow in ((0, False), (5000, True)):
            saved["role_state"]["gold"] = gold
            if overflow:
                player.change_item_count(saved, 20619, (1 << 31) - 1, self.role_config)
            self.save_path.write_text(json.dumps(saved))
            self.query_role()
            before = self.save_path.read_bytes()
            replies = self.replay([self.activity_request(5031, [1, 1]), self.activity_request(5039)])
            self.assert_unavailable_response(replies[:2], 5031, 20000, "超出范围" if overflow else "不足")
            self.assertEqual(self.save_path.read_bytes(), before)

    def test_activity_first_period_boundary_uses_server_day_and_expires(self):
        saved = self.seed_activity_account()
        opened = protocol.pb_get_varint(bytes.fromhex(saved["role_snapshot"]), 22)
        end_at = ((opened + 28800) // 86400 + 7) * 86400 - 28800
        self.assertEqual(activities.first_period(saved, self.role_config, 85, end_at - 1), (7, 1))
        self.assertEqual(activities.first_period(saved, self.role_config, 85, end_at), (8, 0))
        self.clock.return_value = end_at
        before = self.save_path.read_bytes()
        replies = self.replay([self.activity_request(5031, [1, 1])])
        self.assert_unavailable_response(replies, 5031, 20000, "已结束")
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_activity_purchase_saves_whole_transaction_before_reply(self):
        self.seed_activity_account()
        before = self.save_path.read_bytes()
        conn = ReplayConnection([self.activity_request(5031, [1, 1])], 7)
        with patch.object(player.os, "replace", side_effect=OSError("disk failure")), redirect_stdout(io.StringIO()):
            self.run_client(conn)
        self.assertEqual(conn.responses, [])
        self.assertEqual(self.save_path.read_bytes(), before)
        self.replay([self.activity_request(5031, [1, 1])])
        saved = json.loads(self.save_path.read_text())
        self.assertEqual(saved["role_state"]["gold"], 3434)
        self.assertEqual(saved["activity_state"]["gold_spent"], 1566)
        self.assertEqual(saved["activity_state"]["discount_bought"], {"1": 1})

    def test_unimplemented_activity_operations_return_native_error_without_changes(self):
        self.seed_activity_account()
        before = self.save_path.read_bytes()
        for opcode in activities.UNSUPPORTED_OPCODES:
            for values in ([], [1]):
                replies = self.replay([self.activity_request(opcode, values)])
                self.assert_unavailable_response(replies, opcode, 20000, "未扣除")
                self.assertEqual(self.save_path.read_bytes(), before)

    def test_anniversary_query_rejects_nonempty_payload(self):
        self.replay(self.requests)
        for body in ("0801", "08", "0a00", "1000"):
            with self.subTest(body=body):
                self.assert_rejected({"opcode": 4600, "seq": 20000, "hex": body}, "活动请求格式错误")

    def test_unimplemented_anniversary_exchange_is_nonmutating_and_connection_stays_usable(self):
        self.replay(self.requests)
        before = self.save_path.read_bytes()
        for ids in ((1,), (1, 1), (13, 2), (15, 1), (15, 999), (0,), (16,), ()):
            with self.subTest(ids=ids):
                responses = self.replay([self.activity_request(4601, ids),
                                         dict(self.activity_request(4600), seq=20001)], chunk_size=7)
                self.assert_unavailable_response(responses[:2], 4601, 20000, "兑换")
                self.assertEqual((responses[2]["opcode"], responses[2]["seq"]), (4600, 20001))
                self.assertEqual(len(protocol.parse_ids_pb(bytes.fromhex(responses[2]["hex"]))), 30)
                self.assertEqual(self.save_path.read_bytes(), before)

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
            hint_changes = []
            for session in sessions:
                requests = [dict(f, seq=f["seq"] + shift) if f["opcode"] == 999900 else f for f in session]
                responses = self.replay(requests, chunk_size=31)
                hint_changes.extend(self.hint_changes(f) for f in responses if f["opcode"] == 1034)
                responses = [f for f in responses if f["opcode"] != 1034]
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
            self.assertEqual(hint_changes, [{40: 1}, {84: 1}])


class ApkToolTests(unittest.TestCase):
    def test_build_tools_use_platform_names_on_path_and_in_sdk(self):
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            for platform, names in (("posix", ("zipalign", "apksigner")), ("nt", ("zipalign.exe", "apksigner.bat"))):
                for tool, filename in zip(("zipalign", "apksigner"), names):
                    target = base / filename
                    target.touch()
                    target.chmod(0o755)
                    with patch.dict(os.environ, {"PATH": directory}), patch.object(os, "name", platform):
                        self.assertEqual(apk_builder.find_tool(tool), str(target))
            target = base / "build-tools" / "34.0.0" / "apksigner"
            target.parent.mkdir(parents=True)
            target.touch()
            with patch.dict(os.environ, {"PATH": "", "ANDROID_HOME": directory}), patch.object(os, "name", "posix"):
                self.assertEqual(apk_builder.find_tool("apksigner"), str(target))


class LanAccountTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with redirect_stdout(io.StringIO()):
            cls.step_counts = guide.load_guide_step_counts(server.CONFIG_ZIP)
            cls.role_config = player.load_role_config(server.CONFIG_ZIP)
            frames = replay.load_recordings(server.RECORD_PATH)
            cls.tables = replay.build_routing_tables(frames)
            # 两个教程隔离用例只用原始抓包；ReplayRoutingTests 仍验证完整混合库。
            end = next((i for i, f in enumerate(frames) if i and f["c2s"] and f["opcode"] == 1000 and f["seq"] == 1), len(frames))
            cls.tutorial_tables = replay.build_routing_tables(frames[:end])
        cls.requests = [f for f in frames[:end] if f["c2s"]]
        cls.by_seq = {f["seq"]: f for f in cls.requests}

    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.save_path = Path(temp.name) / "role_save.json"
        self.store = accounts.AccountStore(self.save_path, self.tables, self.step_counts, self.role_config)
        for context in (patch.object(server, "SAVE_PATH", str(self.save_path)),
                        patch.object(server, "start_admin"),
                        patch.object(player.time, "time", return_value=1800000000),
                        redirect_stdout(io.StringIO())):
            context.__enter__()
            self.addCleanup(context.__exit__, None, None, None)

    def run_client(self, conn, addr=("same-lan-ip", 1)):
        self.store.tables = self.tables
        server.handle_client(conn, addr, self.store)

    def replay(self, requests, chunk_size=4096, account=1):
        conn = ReplayConnection(requests, chunk_size, account=account)
        with redirect_stdout(io.StringIO()) as log:
            self.run_client(conn)
        self.assertTrue(conn.closed)
        self.assertNotIn("连接异常", log.getvalue())
        return conn.responses

    def test_two_accounts_keep_names_guides_and_world_state_after_reconnect(self):
        self.tables = self.tutorial_tables
        name = lambda text: {"opcode": 101, "seq": 20000, "hex": protocol.encode_pb_field(1, 2, text.encode("utf-8")).hex()}
        self.replay([name("手机账号"), self.by_seq[11], self.by_seq[12], self.by_seq[36]], account=1)
        first = self.save_path.read_bytes()
        self.replay([name("模拟器账号"), {"opcode": 201, "seq": 20001, "hex": "08011003"}], account=2)
        second_path = self.store.path(2)
        self.assertEqual(self.save_path.read_bytes(), first)
        self.assertEqual(json.loads(second_path.read_text())["role_name"], "模拟器账号")
        for account, expected_name, expected_step in ((1, "手机账号", 8), (2, "模拟器账号", 3)):
            responses = self.replay([self.by_seq[12], {"opcode": 200, "seq": 30000, "hex": ""}], account=account)
            role = dict(protocol.get_comb_messages(bytes.fromhex(responses[0]["hex"])))[1001]
            self.assertIn((3, 2, expected_name.encode("utf-8")), list(protocol.iter_pb_fields(role)))
            sections = [value for _, _, value in protocol.iter_pb_fields(bytes.fromhex(responses[1]["hex"]))]
            self.assertEqual(protocol.pb_get_varint(sections[0], 3), expected_step)
        self.assertEqual(json.loads(self.save_path.read_text())["level"], 2)
        self.assertEqual(json.loads(second_path.read_text())["level"], 1)

    def test_recorded_tutorial_can_run_independently_for_two_accounts(self):
        self.tables = self.tutorial_tables
        self.replay(self.requests, account=1)
        first = self.save_path.read_bytes()
        self.replay(self.requests, chunk_size=7, account=2)
        self.assertEqual(self.save_path.read_bytes(), first)
        a = json.loads(first)
        b = json.loads(self.store.path(2).read_text())
        for key in ("role_state", "world_state", "guide", "protagonist_snapshot", "activity_state", "stamina_clock"):
            self.assertEqual(a[key], b[key])

    def test_login_parser_accepts_reconnect_flag_but_rejects_invalid_identity(self):
        body = bytes.fromhex(login_request(2)["hex"]) + protocol.encode_pb_field(1, 2, b"\x08\x03")
        self.assertEqual(accounts.parse_login_account(body), 2)
        for account in ("0", "-1", "01", "1001", "../1", "1/../../2", "1\x00"):
            with self.subTest(account=account), self.assertRaises(ValueError):
                accounts.parse_login_account(bytes.fromhex(login_request(account)["hex"]))
        for body in (b"", b"\x08\x01", b"\x0a\x04\x12\x05x", b"\x0a\x02\x08\x01"):
            with self.subTest(body=body), self.assertRaises(ValueError):
                accounts.parse_login_account(body)

    def test_unauthenticated_requests_cannot_read_or_modify_saves(self):
        self.save_path.write_text('{"role_name":"keep"}')
        before = self.save_path.read_bytes()
        for opcode in (1001, 200, 101, 201, 999898, 999900):
            with self.subTest(opcode=opcode):
                conn = ReplayConnection([{"opcode": opcode, "seq": 1, "hex": ""}], 7, login=False)
                with patch.object(server, "print_flush"):
                    self.run_client(conn)
                self.assertTrue(conn.closed)
                self.assertEqual(conn.responses, [])
                self.assertEqual(self.save_path.read_bytes(), before)

    def test_connection_cannot_switch_accounts_after_login(self):
        conn = ReplayConnection([login_request(1, 1), login_request(2, 2)], 7, login=False)
        with patch.object(server, "print_flush"):
            self.run_client(conn)
        self.assertEqual([f["seq"] for f in conn.responses], [1])
        self.assertFalse(self.store.path(2).exists())
        self.assertEqual(self.store.active, {})

    def test_oversized_frame_is_rejected_without_touching_save(self):
        conn = ReplayConnection([], 4096, login=False)
        conn.chunks = iter([struct.pack(">IIII", 0xEE1C, server.MAX_FRAME_SIZE + 1, 1000, 1)])
        with patch.object(server, "print_flush"):
            self.run_client(conn)
        self.assertEqual(conn.responses, [])
        self.assertTrue(conn.closed)
        self.assertFalse(self.save_path.exists())

    def test_duplicate_account_rejected_while_other_account_can_play(self):
        waiting, release = threading.Event(), threading.Event()

        class HoldingConnection(ReplayConnection):
            def recv(self, size):
                data = super().recv(size)
                if not data:
                    waiting.set()
                    if not release.wait(5):
                        raise TimeoutError("test did not release connection")
                return data

        conn = HoldingConnection([login_request(1, 1)], 4096, login=False)
        worker = threading.Thread(target=self.run_client, args=(conn, ("same-ip", 1)))
        with patch.object(server, "print_flush"):
            worker.start()
            try:
                self.assertTrue(waiting.wait(5))
                duplicate = ReplayConnection([login_request(1, 2)], 7, login=False)
                self.run_client(duplicate, ("same-ip", 2))
                self.assertEqual(duplicate.responses, [])
                self.assertTrue(duplicate.closed)
                self.assertIn(1, self.store.active)
                self.replay([{"opcode": 201, "seq": 10, "hex": "08011003"}], account=2)
            finally:
                release.set()
                worker.join(5)
        self.assertFalse(worker.is_alive())
        self.assertEqual(self.store.active, {})
        self.replay([{"opcode": 201, "seq": 11, "hex": "08011004"}], account=1)

    def test_failed_login_releases_account_for_retry(self):
        path = self.store.path(2)
        path.parent.mkdir(parents=True)
        path.write_text('{"unfinished":')
        conn = ReplayConnection([login_request(2, 1)], 4096, login=False)
        with patch.object(server, "print_flush"):
            self.run_client(conn)
        self.assertEqual(conn.responses, [])
        self.assertEqual(self.store.active, {})
        path.write_text(json.dumps(player.get_default_save()))
        self.replay([{"opcode": 201, "seq": 11, "hex": "08011004"}], account=2)

    def test_startup_uses_one_port_and_never_runs_adb(self):
        with patch.object(server.socket, "socket") as factory, patch("subprocess.run", side_effect=AssertionError("must not run adb")), patch.object(server, "print_flush"):
            factory.return_value.accept.side_effect = KeyboardInterrupt
            server.main([])
            factory.return_value.bind.assert_called_once_with(("0.0.0.0", 14600))
            factory.return_value.close.assert_called_once()

    def test_reset_only_removes_target_account(self):
        self.replay([{"opcode": 201, "seq": 1, "hex": "08011003"}], account=1)
        self.replay([{"opcode": 201, "seq": 1, "hex": "08011004"}], account=2)
        before = self.save_path.read_bytes()
        with patch.object(server.socket, "socket") as factory, patch.object(server, "print_flush"):
            factory.return_value.accept.side_effect = KeyboardInterrupt
            server.main(["--account", "2", "--reset"])
        self.assertEqual(self.save_path.read_bytes(), before)
        self.assertFalse(self.store.path(2).exists())

    def test_occupied_port_prevents_resetting_live_account(self):
        self.save_path.write_text('{"role_name":"keep"}')
        before = self.save_path.read_bytes()
        with patch.object(server.socket, "socket") as factory, patch.object(server, "print_flush"):
            factory.return_value.bind.side_effect = OSError("address in use")
            with self.assertRaises(OSError):
                server.main(["--reset"])
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_reset_guide_preserves_both_accounts_role_data(self):
        for account in (1, 2):
            self.replay([{"opcode": 201, "seq": 1, "hex": "08011003"}], account=account)
        before = self.save_path.read_bytes()
        second = self.store.path(2)
        saved = json.loads(second.read_text())
        with patch.object(server.socket, "socket") as factory, patch.object(server, "print_flush"):
            factory.return_value.accept.side_effect = KeyboardInterrupt
            server.main(["--account", "2", "--reset-guide"])
        current = json.loads(second.read_text())
        self.assertEqual(current["guide"], {"sections": {}})
        for key in ("role_name", "has_role", "world_state"):
            self.assertEqual(current[key], saved[key])
        self.assertEqual(self.save_path.read_bytes(), before)

    def test_tcp_clients_share_one_listener_but_not_saves(self):
        def read_frame(client):
            def read_exact(size):
                data = b""
                while len(data) < size:
                    chunk = client.recv(size - len(data))
                    if not chunk:
                        raise AssertionError("unexpected disconnect")
                    data += chunk
                return data
            magic, length, opcode, seq = struct.unpack(">IIII", read_exact(16))
            self.assertEqual(magic, 0xEE1C)
            return opcode, seq, read_exact(length)

        clients, workers = [], []
        with socket.socket() as listener, patch.object(server, "print_flush"):
            listener.bind(("127.0.0.1", 0))
            listener.listen(2)
            try:
                for account in (1, 2):
                    client = socket.create_connection(listener.getsockname(), timeout=3)
                    clients.append(client)
                    conn, addr = listener.accept()
                    worker = threading.Thread(target=self.run_client, args=(conn, addr))
                    worker.start()
                    workers.append(worker)
                    login = login_request(account, 1)
                    packet = protocol.pack_frame(1000, 1, bytes.fromhex(login["hex"]))
                    packet += protocol.pack_frame(201, 2, bytes((8, 1, 16, account + 2)))
                    for offset in range(0, len(packet), 7):
                        client.sendall(packet[offset:offset + 7])
                    self.assertEqual(read_frame(client), (1000, 1, b"\x08\x00\x10\x00\x18\x00"))
                    self.assertEqual(read_frame(client), (201, 2, b"\x08\x01"))
                self.assertEqual(set(self.store.active), {1, 2})
                for account, client in enumerate(clients, 1):
                    client.sendall(protocol.pack_frame(200, 3, b""))
                    opcode, seq, body = read_frame(client)
                    self.assertEqual((opcode, seq), (200, 3))
                    section = next(value for _, _, value in protocol.iter_pb_fields(body))
                    self.assertEqual(protocol.pb_get_varint(section, 3), account + 2)
            finally:
                for client in clients:
                    client.close()
                for worker in workers:
                    worker.join(5)
                    self.assertFalse(worker.is_alive())
        self.assertEqual(self.store.active, {})


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
                    patch.object(server, "start_admin") as admin_factory, \
                    patch.object(sys, "argv", ["mock_server.py"]), \
                    patch("subprocess.check_output", side_effect=AssertionError("must not run adb")), \
                    patch.object(server.socket, "socket") as socket_factory, \
                    patch.object(server.threading, "Thread") as thread_factory:
                socket_factory.return_value.accept.side_effect = [(conn, ("test", 0)), KeyboardInterrupt]
                server.main()
                thread_factory.assert_called_once()
                thread_factory.return_value.start.assert_called_once_with()
                options = thread_factory.call_args.kwargs
                self.assertIs(options["target"], server.handle_client)
                self.assertTrue(options["daemon"])
                self.assertIs(options["args"][2], admin_factory.call_args.args[1])
                admin_factory.return_value.shutdown.assert_called_once_with()
                admin_factory.return_value.server_close.assert_called_once_with()
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
                            patch.object(server, "start_admin"), \
                            patch.object(sys, "argv", ["mock_server.py", *flags]), \
                            patch("subprocess.check_output", side_effect=AssertionError("must not run adb")), \
                            patch.object(server.socket, "socket") as socket_factory:
                        socket_factory.return_value.accept.side_effect = KeyboardInterrupt
                        server.main()
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
