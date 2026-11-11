"""升仙台 8851–8860 真实地图、事件链、阵容镜像、战斗与商店回归。"""

from contextlib import redirect_stdout
import copy
import io
import json
from pathlib import Path
import struct
import tempfile
import unittest
from unittest.mock import patch

import build_local_apk as builder
import test_activity_copy as base
from zyj_server import ascension_sendai, formation, player, protocol, recharge
from zyj_server.session import Session

NOW = 1800172800
E = protocol.encode_pb_field


def messages(raw):
    result = {}
    for n, w, value in protocol.iter_pb_fields(raw):
        if (n, w) != (1, 2):
            continue
        mid, data = None, b""
        for fn, fw, sub in protocol.iter_pb_fields(value):
            if (fn, fw) == (1, 0):
                mid = sub
            elif (fn, fw) == (2, 2):
                data = sub
        result[mid] = data
    return result


def comb1(values, mid=1):
    return E(1, 2, E(1, 0, mid) + E(2, 2, recharge.ids(values)))


def comb2(first, second):
    return comb1(first, 1) + comb1(second, 2)


class AscensionSendaiTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        base.ActivityCopyTests.setUpClass.__func__(cls)
        cls.baseline["role_state"].update(level=150, nextexp=cls.config["role_exp"]["150"]["nextexp"])
        cls.origin = ascension_sendai.origin(cls.config, 1)
        cls.events = {}
        for kind in ascension_sendai.EVENT_TYPES:
            for key, row in sorted(cls.config["shengxian_type"].items()):
                if row["type"] == kind and "difficult1_1" in row and row["difficult1_1"].startswith(tuple("0123456789")):
                    cls.events[kind] = int(key)
                    break

    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.path = Path(temporary.name) / "role_save.json"
        self.path.write_text(json.dumps(self.baseline))
        self.clock = patch("time.time", return_value=NOW).start()
        self.addCleanup(patch.stopall)
        quiet = redirect_stdout(io.StringIO())
        quiet.__enter__()
        self.addCleanup(quiet.__exit__, None, None, None)
        self.session = self.reconnect()

    def reconnect(self):
        return Session(self.tables, self.path, self.steps, self.config)

    strengthen = base.ActivityCopyTests.strengthen
    network_lua = base.ActivityCopyTests.network_lua

    def call(self, opcode, values=(), seq=181, raw=None):
        return self.session.handle(opcode, seq, raw if raw is not None else recharge.ids(values))

    def success(self, opcode, values=(), seq=181, raw=None):
        packets = self.call(opcode, values, seq=seq, raw=raw)
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], opcode, packets)
        return packets[0][16:]

    def assert_rejected(self, opcode, values=(), *, raw=None):
        memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        packets = self.session.handle(opcode, 200, raw if raw is not None else recharge.ids(values))
        self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets], [999999, 1999])
        self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))

    def give(self, cid, count):
        player.change_item_count(self.session.save, cid, count, self.config, NOW)
        self.path.write_text(json.dumps(self.session.save))

    def state(self):
        return self.session.save["ascension_sendai_state"]

    def setup_round(self, mode=1, level=1):
        self.success(8852, [mode, self.origin, level])
        return self.state()

    def iids(self):
        generals = formation.records(bytes.fromhex(self.session.save["world_state"]["1002"]), 1, 2)
        return list(generals)[:7]

    def inject(self, kind, point=118, done=False):
        state = self.state()
        event_id = self.events[kind]
        state.update(point=point, point_state=1)
        state["events"][str(point)] = {"id": event_id, "type": kind, "done": done,
                                       "follow": [], "data": {}}
        return state, event_id

    def test_query_shape_matches_native_lua_comb_and_params(self):
        lua = self.network_lua()
        for name in ("combmessages_pb", "params_pb"):
            lua.execute(builder.read_script(name, "pb"))
        lua.globals().reply_8851 = self.success(8851)
        result = lua.execute(b'''
            local comb = combmessages_pb.CombMessages(); comb:ParseFromString(reply_8851)
            local ids, path = nil, ""
            for k,v in ipairs(comb.messages) do
                if v.id == 0 then ids = ids_pb.Ids(); ids:ParseFromString(v.data) end
                if v.id == 1 then local p = params_pb.ParamS(); p:ParseFromString(v.data); path = p.params[1].s end
            end
            return #ids.ids, path
        ''')
        self.assertEqual(tuple(result), (8, b"123,"))

    def test_difficulty_select_is_once_per_round_and_replays_on_query(self):
        state = self.setup_round()
        self.assertEqual((state["difficulty"], state["level"], state["point"]), (1, 1, self.origin))
        parts = messages(self.success(8851))
        values = protocol.parse_ids_pb(parts[0])
        self.assertEqual(values[2:5], [1, 1, self.origin])
        self.assertEqual(protocol.parse_ids_pb(self.success(8859)), [])
        self.assert_rejected(8852, [2, self.origin, 1])

    def test_move_validation_uses_real_map_lines(self):
        self.setup_round()
        self.assert_rejected(8853, raw=comb1([1, self.events["battle"]]))
        point, event_id = 118, int(self.config["shengxian_map1"]["24"]["event_3"])
        body = self.success(8853, raw=comb1([point, event_id]))
        parts = messages(body)
        self.assertEqual(set(parts), {1, 2})
        self.assertEqual(protocol.parse_ids_pb(parts[2]), [point, 0])
        self.assertEqual(self.state()["point"], point)
        self.assertIn(point, self.state()["path"])

    def test_every_event_type_has_native_8853_payload(self):
        self.setup_round()
        expected = {"adventure": 1, "buy": 6, "buff": 4, "cheer": 5, "encounter": 2,
                    "recover": 1, "revive": 1, "battle": 1, "battle1": 1, "boss": 1, "reward": None}
        for kind, count in expected.items():
            with self.subTest(kind=kind):
                _, event_id = self.inject(kind, point=100 + list(expected).index(kind))
                point = self.state()["point"]
                body = self.success(8853, raw=comb1([point, event_id]), seq=300 + list(expected).index(kind))
                parts = messages(body)
                if kind != "reward":
                    self.assertEqual(len(protocol.parse_ids_pb(parts[1])), count)
                else:
                    self.assertTrue(parts[1])
                self.assertEqual(protocol.parse_ids_pb(parts[2])[0], point)

    def test_secondary_events_apply_buffs_cheers_encounter_and_heal(self):
        self.give(1045, 5000)
        self.give(1044, 5000)
        self.setup_round()
        iids = self.iids()
        self.success(8858, iids)
        for kind, selection in (("buy", None), ("buff", None), ("cheer", None),
                                ("encounter", [1]), ("recover", iids), ("revive", iids)):
            with self.subTest(kind=kind):
                point = 200 + len(self.state()["events"])
                _, event_id = self.inject(kind, point=point)
                payload = protocol.parse_ids_pb(messages(self.success(8853, raw=comb1([point, event_id]),
                                                                      seq=400 + point))[1])
                if selection is None:
                    selection = [payload[2] if kind == "buy" else payload[0]]
                body = self.success(8854, raw=comb2([point, event_id], selection), seq=500 + point)
                self.assertIn(1, messages(body))
                self.assertTrue(self.state()["events"][str(point)]["done"])
        self.assertEqual(len(self.state()["buffs"]), 2)
        self.assertEqual(len(self.state()["cheers"]), 1)
        self.assertTrue(self.state()["path"])

    def test_battle_uses_real_report_persists_mirror_and_monster_hp(self):
        self.strengthen()
        self.setup_round()
        iids = self.iids()
        self.success(8858, iids)
        state, event_id = self.inject("battle", point=118)
        self.success(8860, [118, event_id])
        self.success(8853, raw=comb1([118, event_id]))
        body = self.success(8854, raw=comb2([118, event_id], iids))
        parts = messages(body)
        self.assertEqual(set(parts), {1, 2})
        battle = {n: v for n, w, v in protocol.iter_pb_fields(parts[1])}
        self.assertEqual(battle[1], 1)
        report = json.loads(next(v for n, w, v in protocol.iter_pb_fields(parts[1]) if (n, w) == (5, 2)))
        self.assertTrue(report["result"])
        follow = protocol.parse_ids_pb(parts[2])
        self.assertEqual(len(follow), 1)
        self.assertEqual(self.config["shengxian_type"][str(follow[0])]["type"], "buff")
        self.assertTrue(self.state()["events"]["118"]["done"])
        self.assertTrue(any(row[4] <= row[3] for row in self.state()["generals"]))
        self.assertTrue(any(row[1] < row[2] for row in self.state()["monsters"][f"118:{event_id}"]))

    def test_boss_victory_ends_round_and_next_query_rotates_map(self):
        self.strengthen()
        self.setup_round()
        iids = self.iids()
        self.success(8858, iids)
        _, event_id = self.inject("boss", point=118)
        self.success(8853, raw=comb1([118, event_id]))
        body = self.success(8854, raw=comb2([118, event_id], iids))
        self.assertEqual(set(messages(body)), {1})
        self.assertEqual(self.state()["end_at"], NOW)
        state = self.state()
        state["round"] = 1
        parts = messages(self.success(8851))
        self.assertEqual(protocol.parse_ids_pb(parts[0])[0], 2)
        self.assertEqual(self.state()["difficulty"], 0)

    def test_shop_query_purchase_limit_and_currency(self):
        self.give(1044, 10000)
        self.setup_round()
        values = protocol.parse_ids_pb(self.success(8856))
        self.assertEqual(len(values), 2 + len(self.config["shengxian_shop"]))
        self.assertEqual(values[1], 10000)
        reward = self.success(8857, [3, 1])
        self.assertTrue(reward)
        values = protocol.parse_ids_pb(self.success(8856))
        self.assertEqual(values[4], 1)
        self.assert_rejected(8857, [999, 1])
        self.assert_rejected(8857, [3, 0])

    def test_mirror_and_monster_queries_use_ten_and_four_field_records(self):
        self.setup_round()
        iids = self.iids()
        uploaded = protocol.parse_ids_pb(self.success(8858, iids))
        self.assertEqual(len(uploaded), 10 * len(iids))
        self.assertEqual(protocol.parse_ids_pb(self.success(8859)), uploaded)
        battle_id = ascension_sendai.first_id(self.config, self.events["boss"], 1, 1)
        expected = sum(bool(self.config["shengxian_battle"][str(battle_id)][f"p{i}"]) for i in range(1, 8))
        monsters = protocol.parse_ids_pb(self.success(8860, [118, self.events["boss"]]))
        self.assertEqual(len(monsters), 4 * expected)
        self.assertEqual(protocol.parse_ids_pb(self.success(8855)), [])

    def test_round_expiry_resets_progress_and_rotates_map(self):
        state = self.setup_round()
        state["end_at"] = NOW
        state["generals"] = [[1] * 10]
        state["buffs"] = [[9001349, 1]]
        parts = messages(self.success(8851))
        values = protocol.parse_ids_pb(parts[0])
        self.assertEqual((values[0], values[2], values[3], values[6]), (2, 0, 0, 0))
        self.assertEqual(self.state()["generals"], [])
        self.assertEqual(self.state()["buffs"], [])

    def test_rejected_requests_never_change_save(self):
        self.setup_round()
        self.assert_rejected(8852, [3, self.origin, 1])
        self.assert_rejected(8853, raw=comb1([0, self.events["boss"]]))
        self.assert_rejected(8854, raw=comb2([self.origin, self.events["boss"]], [1]))
        self.assert_rejected(8856, [1])
        self.assert_rejected(8857, [1, 1])
        self.assert_rejected(8858, [999999999])
        self.assert_rejected(8860, [118, 999999999])


if __name__ == "__main__":
    unittest.main()
