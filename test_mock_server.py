import json
from pathlib import Path
import struct
import tempfile
import unittest
from unittest.mock import patch

import mock_server as server


class ReplayConnection:
    def __init__(self, requests, chunk_size):
        stream = b"".join(server.pack_frame(f["opcode"], f["seq"], bytes.fromhex(f["hex"])) for f in requests)
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
        with patch.object(server, "print_flush"):
            cls.frames = server.load_recordings()
            cls.tables = server.build_routing_tables(cls.frames)
        cls.requests = [f for f in cls.frames if f["c2s"]]
        cls.by_seq = {f["seq"]: f for f in cls.requests}
        cls.recorded = {(f["seq"], f["opcode"]): f for f in cls.frames if not f["c2s"] and f["seq"] != 0}

    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.save_path = Path(temp.name) / "role_save.json"
        save_patch = patch.object(server, "SAVE_PATH", str(self.save_path))
        save_patch.start()
        self.addCleanup(save_patch.stop)

    def replay(self, requests, chunk_size=4096):
        conn = ReplayConnection(requests, chunk_size)
        with patch.object(server, "print_flush") as log:
            server.handle_client(conn, ("test", 0), *self.tables)
        self.assertTrue(conn.closed)
        errors = [str(call) for call in log.call_args_list if "连接异常" in str(call)]
        self.assertEqual(errors, [])
        return conn.responses

    def assert_recorded_response(self, response, recorded_seq, live_seq=None):
        expected = self.recorded[(recorded_seq, response["opcode"])]
        self.assertEqual(response["seq"], recorded_seq if live_seq is None else live_seq)
        self.assertEqual(response["hex"], expected["hex"])

    def assert_replayed_payload(self, opcode, actual, expected):
        if opcode == 999900:
            actual_messages = server.get_comb_messages(bytes.fromhex(actual))
            expected_messages = server.get_comb_messages(bytes.fromhex(expected))
            self.assertEqual([mid for mid, _ in actual_messages], [mid for mid, _ in expected_messages])
            for (mid, data), (_, recorded) in zip(actual_messages, expected_messages):
                self.assert_replayed_payload(mid, data.hex(), recorded.hex())
        elif opcode in (1001, 1054):
            values = {n: value for n, wire, value in server.iter_pb_fields(bytes.fromhex(actual))}
            recorded = {n: value for n, wire, value in server.iter_pb_fields(bytes.fromhex(expected))}
            # Role timers/stamina now follow local operations, not captured wall-clock regeneration.
            fields = (1, 3, 5, 6, 7, 8, 9, 11, 12, 13, 14, 21, 26, 27) if opcode == 1001 else range(1, 10)
            for field in fields:
                self.assertEqual(values.get(field, 0), recorded.get(field, 0), (opcode, field))
            if opcode == 1054:
                if 10 in recorded:
                    self.assertEqual(values.get(10), recorded[10])
                elif 10 in values:
                    # Reconnect replies may now include the last known general instead of relying on client cache.
                    general = {n: v for n, w, v in server.iter_pb_fields(values[10])}
                    self.assertEqual((general[2], general[3]), (values[1], values[2]))
        else:
            self.assertEqual(actual, expected)

    def role_data(self, response):
        body = bytes.fromhex(response["hex"])
        if response["opcode"] == 999900:
            body = next(data for mid, data in server.get_comb_messages(body) if mid == 1001)
        return {n: value for n, wire, value in server.iter_pb_fields(body)}

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
        point_two = b"\x08" + server.encode_varint(42101) + b"\x08\x02"
        self.assertEqual(body.count(point_two), 1)
        body = body.replace(point_two, b"\x08" + server.encode_varint(42101) + b"\x08\x63")
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
        hints = [f for f in self.requests if f["opcode"] == 1032]
        responses = self.replay([hints[0], dict(hints[1], seq=10000)])
        self.assert_recorded_response(responses[0], hints[0]["seq"])
        self.assert_recorded_response(responses[1], hints[1]["seq"], 10000)

    def test_ordinary_sequence_hit_must_match_request_payload(self):
        self.assertNotEqual(self.by_seq[28]["hex"], self.by_seq[31]["hex"])
        responses = self.replay([dict(self.by_seq[28], seq=10000), dict(self.by_seq[31], seq=28)])
        self.assert_recorded_response(responses[0], 28, 10000)
        self.assert_recorded_response(responses[1], 31, 28)

    def test_city_init_embeds_saved_role_without_stale_initial_role(self):
        snapshot = self.recorded[(41, 1001)]["hex"]
        save = server.get_default_save()
        save["role_snapshot"] = snapshot
        self.save_path.write_text(json.dumps(save))
        responses = self.replay([self.by_seq[12]])
        self.assertEqual(len(responses), 1)
        role = next(data for mid, data in server.get_comb_messages(bytes.fromhex(responses[0]["hex"])) if mid == 1001)
        self.assertEqual(role.hex(), snapshot)

    def test_custom_name_reaches_city_init_and_role_query(self):
        name = "本地玩家".encode("utf-8")
        body = b"\x0a" + server.encode_varint(len(name)) + name
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
        save = server.get_default_save()
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
        values = {n: v for n, w, v in server.iter_pb_fields(bytes.fromhex(saved["role_snapshot"]))}
        self.assertEqual([values[n] for n in (5, 6, 8, 9, 10)], [2, 0, 2960, 10, 49])

    def test_reconnect_role_queries_cannot_change_progress_by_recording_sequence(self):
        self.replay([self.by_seq[12], self.by_seq[36]])
        responses = self.replay([self.by_seq[111], dict(self.by_seq[63], seq=20000)])
        for response in responses:
            self.assertEqual([self.role_data(response)[n] for n in (5, 8, 9)], [2, 2960, 10])

    def test_strengthen_spending_can_reach_zero_and_survive_reconnect(self):
        save = server.get_default_save()
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
        save = server.get_default_save()
        save["role_state"] = {"level": 4, "exp": 0, "coin": 1, "gold": 0}
        original = json.dumps(save)
        self.save_path.write_text(original)
        conn = ReplayConnection([self.by_seq[99]], 4096)
        with patch.object(server, "print_flush"):
            server.handle_client(conn, ("test", 0), *self.tables)
        self.assertTrue(conn.closed)
        self.assertEqual(conn.responses, [])
        self.assertEqual(self.save_path.read_text(), original)

    def test_failed_save_keeps_original_and_emits_no_success(self):
        save = server.get_default_save()
        save["role_state"] = {"level": 4, "exp": 0, "coin": 11200, "gold": 0}
        original = json.dumps(save)
        self.save_path.write_text(original)
        conn = ReplayConnection([self.by_seq[99]], 4096)
        with patch.object(server, "print_flush"), patch.object(server.os, "replace", side_effect=OSError("disk failure")):
            server.handle_client(conn, ("test", 0), *self.tables)
        self.assertTrue(conn.closed)
        self.assertEqual(conn.responses, [])
        self.assertEqual(self.save_path.read_text(), original)
        self.assertEqual([p.name for p in self.save_path.parent.iterdir() if not p.name.startswith('._')], ["role_save.json"])

    def test_corrupt_save_is_not_silently_replaced(self):
        original = '{"unfinished":'
        self.save_path.write_text(original)
        self.assertEqual(self.replay([self.by_seq[12]]), [])
        self.assertEqual(self.save_path.read_text(), original)

    def test_malformed_name_does_not_change_existing_save(self):
        save = server.get_default_save()
        save["role_name"] = "已保存的名字"
        original = json.dumps(save)
        self.save_path.write_text(original)
        conn = ReplayConnection([{"opcode": 101, "seq": 10000, "hex": "0a05e69cac"}], 7)
        with patch.object(server, "print_flush"):
            server.handle_client(conn, ("test", 0), *self.tables)
        self.assertEqual(conn.responses, [])
        self.assertEqual(self.save_path.read_text(), original)

    def test_legacy_client_report_preserves_extended_fields_and_zero_balances(self):
        self.replay([self.by_seq[12], self.by_seq[36]])
        values = (2, 0, 0, 0, 0)
        body = b"".join(b"\x08" + server.encode_varint(value) for value in values)
        self.replay([{"opcode": 999898, "seq": 10000, "hex": body.hex()}])
        saved = json.loads(self.save_path.read_text())
        self.assertEqual([saved["role_state"][k] for k in ("coin", "gold", "power", "power_all", "stamina")], [0, 0, 0, 0, 49])

    def test_field_replacement_preserves_unknown_fields_and_zero(self):
        raw = b"\x08\x05\x1a\x03old" + server.encode_pb_field(50, 5, b"1234")
        updated = server.pb_set_field(raw, 3, 2, "新名字".encode("utf-8"))
        updated = server.pb_set_varint(updated, 1, 0)
        self.assertEqual(list(server.iter_pb_fields(updated)), [(1, 0, 0), (3, 2, "新名字".encode("utf-8")), (50, 5, b"1234")])

    def test_protagonist_growth_is_not_general_level2(self):
        self.replay([self.by_seq[11], self.by_seq[12], self.by_seq[36]])
        saved = json.loads(self.save_path.read_text())
        values = {n: v for n, w, v in server.iter_pb_fields(bytes.fromhex(saved["protagonist_snapshot"]))}
        general = {n: v for n, w, v in server.iter_pb_fields(values[10])}
        self.assertEqual((values[3], general[4]), (1, 0))

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
                save = server.get_default_save()
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
        frames = [self.by_seq[36], dict(push, c2s=False), dict(self.recorded[(36, 999900)], seq=999)]
        with patch.object(server, "print_flush"):
            tables = server.build_routing_tables(frames)
        self.assertEqual(tables[1], {})

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
        save = server.get_default_save()
        save["guide"] = {"section": 1, "status": 0, "step": 7}
        self.save_path.write_text(json.dumps(save))
        self.replay([self.by_seq[36]])
        saved = json.loads(self.save_path.read_text())
        self.assertEqual(saved["guide"]["sections"]["1"], {"status": 1, "step": 8, "steps": [7, 8]})

    def test_completion_uses_configured_step_count(self):
        total = server.GUIDE_STEP_COUNTS[1]
        for step, status in ((total - 1, 1), (total, 2)):
            body = b"\x08\x01\x10" + server.encode_varint(step)
            self.replay([{"opcode": 201, "seq": 10000, "hex": body.hex()}])
            saved = json.loads(self.save_path.read_text())
            self.assertEqual(saved["guide"]["sections"]["1"]["status"], status)

    def test_all_19_combination_guide_steps_are_persisted(self):
        requests = [f for f in self.requests if f["opcode"] == 999900 and 201 in server.get_comb_ids(bytes.fromhex(f["hex"]))]
        self.assertEqual(len(requests), 19)
        self.replay(requests)
        self.assertTrue(self.save_path.exists())
        saved = json.loads(self.save_path.read_text())
        expected = [4, 8, 13, 19, 22, 30, 36, 39, 44, 45, 48, 51, 56, 60, 66, 71, 78, 79, 80]
        self.assertEqual(saved["guide"]["sections"]["1"], {"status": 1, "step": 80, "steps": expected})

    def test_failed_combination_guide_ack_does_not_advance_progress(self):
        reply = self.recorded[(36, 999900)]
        self.assertTrue(reply["hex"].endswith("0801"))
        frames = [self.by_seq[36], dict(reply, hex=reply["hex"][:-2] + "00")]
        with patch.object(server, "print_flush"):
            self.tables = server.build_routing_tables(frames)
        self.replay([self.by_seq[36]])
        self.assertEqual(json.loads(self.save_path.read_text())["guide"]["sections"], {})

    def test_malformed_guide_report_does_not_overwrite_save(self):
        save = server.get_default_save()
        save["guide"]["sections"] = {"1": {"status": 1, "step": 5, "steps": [5]}}
        original = json.dumps(save)
        self.save_path.write_text(original)
        for body in ("", "0801", "08011080", "08011000", "080110" + "ff" * 10):
            with self.subTest(body=body):
                conn = ReplayConnection([{"opcode": 201, "seq": 10000, "hex": body}], 7)
                with patch.object(server, "print_flush"):
                    server.handle_client(conn, ("test", 0), *self.tables)
                self.assertTrue(conn.closed)
                self.assertEqual(conn.responses, [])
                self.assertEqual(self.save_path.read_text(), original)

    def test_combination_parser_validates_lengths_and_required_ids(self):
        messages = server.get_comb_messages(bytes.fromhex(self.by_seq[11]["hex"]))
        self.assertEqual(messages, [(202, b"\x08\x03"), (201, b"\x08\x01\x10\x04")])
        for raw in (b"\x0a\x05\x08\xca", b"\x0a\x02\x12\x00", b"\x0a\x04\x08\xca\x01\x12", b"\x00", b"\x0e", b"\x80" * 11):
            with self.subTest(raw=raw):
                with self.assertRaises(ValueError):
                    server.get_comb_messages(raw)

    def test_parser_accepts_optional_data_unknown_fields_and_uint64(self):
        self.assertEqual(server.get_comb_messages(b"\x0a\x05\x08\xca\x01\x18\x01\x10\x01"), [(202, b"")])
        maximum = (1 << 64) - 1
        encoded = server.encode_varint(maximum)
        self.assertEqual(server.parse_varint(encoded, 0), (maximum, len(encoded)))

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


if __name__ == "__main__":
    unittest.main()
