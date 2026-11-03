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
from zyj_server import formation, guide, player, protocol, recharge, replay
from zyj_server.session import Session


ROOT = Path(__file__).parent
NOW = 1800000000


class CornucopiaTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with redirect_stdout(io.StringIO()), tempfile.TemporaryDirectory() as directory, patch("time.time", return_value=NOW):
            cls.config = player.load_role_config(ROOT / "configs_sec5.zip")
            cls.steps = guide.load_guide_step_counts(ROOT / "configs_sec5.zip")
            frames = replay.load_recordings(ROOT / "recorded_frames.json")
            cls.tables = replay.build_routing_tables(frames)
            session = Session(cls.tables, Path(directory) / "role_save.json", cls.steps, cls.config)
            for frame in replay.split_recordings(frames)[0]:
                if frame["c2s"] and frame["opcode"] != 1000:
                    session.handle(frame["opcode"], frame["seq"], bytes.fromhex(frame["hex"]))
            for step in range(session.save["guide"]["sections"]["1"]["step"] + 1, cls.steps[1] + 1):
                session.handle(201, 1000 + step, protocol.encode_pb_field(1, 0, 1) + protocol.encode_pb_field(2, 0, step))
            cls.baseline = copy.deepcopy(session.save)
        cls.baseline["role_state"].update(level=25, vip=13, gold=10000, nextexp=cls.config["role_exp"]["25"]["nextexp"])

    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.path = Path(temporary.name) / "role_save.json"
        self.path.write_text(json.dumps(self.baseline))
        clock = patch("time.time", return_value=NOW)
        self.clock = clock.start()
        self.addCleanup(clock.stop)
        quiet = redirect_stdout(io.StringIO())
        quiet.__enter__()
        self.addCleanup(quiet.__exit__, None, None, None)
        self.session = self.reconnect()
        self.sequence = 300

    def reconnect(self):
        return Session(self.tables, self.path, self.steps, self.config)

    def call(self, opcode, values=(), seq=None):
        self.sequence += 1
        packets = self.session.handle(opcode, self.sequence if seq is None else seq, recharge.ids(values))
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], opcode)
        return packets

    def query(self):
        return protocol.parse_ids_pb(self.call(2031)[0][16:])

    def assert_rejected(self, opcode, body):
        memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        packets = self.session.handle(opcode, 800, body)
        self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets], [999999, 1999])
        self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))

    def extension(self, body):
        data = next(v for n, w, v in protocol.iter_pb_fields(body) if (n, w) == (12, 2))
        return protocol.parse_ids_pb(data)

    def test_query_and_real_guide_reports_do_not_grant_free_rewards(self):
        before = copy.deepcopy(self.session.save)
        self.assertEqual(self.query(), [0, 0, 0, 0, 0])
        for key in ("guide", "world_state", "role_state"):
            self.assertEqual(self.session.save[key], before[key])
        self.assertNotIn("83", self.session.save["guide"]["sections"])
        for step in (1, 2):
            self.session.handle(201, 500 + step, protocol.encode_pb_field(1, 0, 83) + protocol.encode_pb_field(2, 0, step))
            self.session = self.reconnect()
            self.assertEqual(self.session.save["guide"]["sections"]["83"]["step"], step)
            self.assertEqual(self.query()[1], 0)

    def test_batch_costs_and_multipliers_are_configured_and_retry_is_exactly_once(self):
        before = copy.deepcopy(self.session.save)
        with patch("random.Random.randrange", return_value=0):
            packets = self.call(2032, [5, 0], seq=330)
        self.assertEqual(self.query(), [0, 5, 0, 0, 0])
        self.assertEqual(self.session.save["role_state"]["coin"] - before["role_state"]["coin"], 80000 * 5)
        self.assertEqual(before["role_state"]["gold"] - self.session.save["role_state"]["gold"], 70)
        self.assertEqual(self.extension(packets[0][16:]), [0, 5, 0, 0, 0, 1, 1, 1, 1, 1])
        self.assertEqual(protocol.pb_get_varint(packets[0][16:], 2) or 0, 0)
        self.assertIn(1001, [struct.unpack(">IIII", p[:16])[2] for p in packets[1:]])
        saved = copy.deepcopy(self.session.save)
        self.assertEqual(self.call(2032, [5, 0], seq=330), packets)
        self.assertEqual(self.session.save, saved)
        self.session = self.reconnect()
        self.assertEqual(self.query()[1], 5)

    def test_vip_zero_batch_clips_to_one_free_attempt_and_never_fabricates_attempts(self):
        self.session.save["role_state"]["vip"] = 0
        gold, coin = (self.session.save["role_state"][k] for k in ("gold", "coin"))
        with patch("random.Random.randrange", return_value=101):
            packets = self.call(2032, [5, 0])
        self.assertEqual(self.query()[1], 1)
        self.assertEqual(self.extension(packets[0][16:])[5:], [10])
        self.assertEqual(self.session.save["role_state"]["gold"], gold)
        self.assertEqual(self.session.save["role_state"]["coin"] - coin, 800000)
        self.assert_rejected(2032, recharge.ids([1, 0]))

    def test_all_three_daily_rewards_claim_once_and_survive_reconnect(self):
        for _ in range(6):
            self.call(2032, [5, 0])
        self.assertEqual(self.query(), [0, 30, 1, 1, 1])
        coin = self.session.save["role_state"]["coin"]
        props = formation.records(bytes.fromhex(self.session.save["world_state"]["1200"]), 1, 1)
        stones = protocol.pb_get_varint(props.get(20223, b""), 2) or 0
        self.call(2033, [1])
        self.call(2033, [2])
        self.call(2033, [3])
        self.assertEqual(self.session.save["role_state"]["coin"] - coin, 440000)
        props = formation.records(bytes.fromhex(self.session.save["world_state"]["1200"]), 1, 1)
        self.assertEqual(protocol.pb_get_varint(props[20223], 2) - stones, 100)
        self.session = self.reconnect()
        self.assertEqual(self.query(), [0, 30, 2, 2, 2])
        for index in (1, 2, 3):
            self.assert_rejected(2033, recharge.ids([index]))
        self.assert_rejected(2032, recharge.ids([1, 0]))

    def test_forward_midnight_resets_counts_and_claims_but_rollback_cannot_repeat_it(self):
        for _ in range(2):
            self.call(2032, [5, 0])
        self.call(2033, [1])
        assets = copy.deepcopy(self.session.save["world_state"])
        self.clock.return_value += 86400
        self.session = self.reconnect()
        self.assertEqual(self.query(), [0, 0, 0, 0, 0])
        for key in ("1002", "1012", "1107", "1200"):
            self.assertEqual(self.session.save["world_state"][key], assets[key])
        self.call(2032, [1, 0])
        self.clock.return_value = NOW
        self.assertEqual(self.query(), [0, 1, 0, 0, 0])
        self.assert_rejected(2032, recharge.ids([1, 0]))

    def test_bad_parameters_locks_and_unverified_ads_are_non_mutating(self):
        for opcode in (2031, 2032, 2033):
            for body in (b"\x08", b"\x0a\x00", b"\x10\x01", recharge.ids([1 << 31]), recharge.ids([1, 0, 0])):
                self.assert_rejected(opcode, body)
        for values in ([], [1], [0, 0], [2, 0], [5, 1], [1, 2]):
            self.assert_rejected(2032, recharge.ids(values))
        for index in (0, 1, 4):
            self.assert_rejected(2033, recharge.ids([index]))
        self.assert_rejected(2031, recharge.ids([1]))
        self.session.save["role_state"]["level"] = 24
        for opcode, values in ((2031, []), (2032, [1, 0]), (2033, [1])):
            self.assert_rejected(opcode, recharge.ids(values))
        self.session.save["has_role"] = False
        self.assert_rejected(2031, b"")

    def test_insufficient_gold_overflow_bad_weight_and_save_failures_roll_back(self):
        self.call(2032, [1, 0])
        self.session.save["role_state"]["gold"] = 0
        self.assert_rejected(2032, recharge.ids([1, 0]))
        self.session.save["role_state"]["gold"] = 10000
        self.session.save["role_state"]["coin"] = (1 << 63) - 1
        self.assert_rejected(2032, recharge.ids([1, 0]))
        self.session = self.reconnect()
        with patch.dict(self.config["buycount_price"]["2"], {"shake_cost": -1}):
            self.assert_rejected(2032, recharge.ids([5, 0]))
        for deck in ("1,0;", "1,-1;", "11,100;", "not-a-deck"):
            with patch.dict(self.config["shake_param"]["25"], {"shake_money_weight": deck}):
                self.assert_rejected(2032, recharge.ids([1, 0]))
        for opcode, values in ((2031, []), (2032, [1, 0]), (2033, [1])):
            self.session = self.reconnect()
            self.session.save["cornucopia_state"]["count"] = 10
            self.session.connected_at -= 60
            self.session.save["online_reward_state"]["checked_at"] -= 60
            memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
            with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
                self.call(opcode, values)
            self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))

    def test_corrupt_saved_counts_fail_closed_before_daily_reset(self):
        for changes in ({"count": -1}, {"count": True}, {"count": 31}, {"day": -1}, {"claimed": [1]}, {"claimed": [1, 1]}):
            data = copy.deepcopy(self.baseline)
            data["cornucopia_state"] = {"day": (NOW + 28800) // 86400, "count": 0, "claimed": [], **changes}
            self.path.write_text(json.dumps(data))
            disk = self.path.read_bytes()
            with self.assertRaisesRegex(ValueError, "聚宝盆"):
                self.reconnect()
            self.assertEqual(self.path.read_bytes(), disk)

    def test_native_callback_uses_critical_multipliers_after_all_five_status_values(self):
        import test_activity_copy
        import test_build_local_apk
        lua = test_activity_copy.ActivityCopyTests.network_lua(self)
        code = builder.read_script("gamedata").decode().replace("\r\n", "\n")
        lua.execute(code[code.index("function gamedata.Cornucopia("):code.index("function gamedata.magic(")].encode())
        lua.execute(b'''gamedata.cache.cornucopia={};gamedata.cache.role.gold=10000
            gamedata.updateRoleGold=function(self,n) self.cache.role.gold=self.cache.role.gold+n end
            gamedata.SomethingProcess=function(self,m,kind)
                self:Cornucopia(m.pext1[1].ids)
                local ext={};for i=5,9 do ext[i-4]=m.pext1[1].ids[i] or 1 end
                return {},{},ext
            end''')
        scripts = test_build_local_apk.LanBuildTests.client_scripts(self)
        lua.execute(scripts["assets/scripts/GameActivityCornucopia.so"].encode())
        self.assertIsNone(lua.globals().gameConfig)
        query = lua.globals().NetCornucopiaQueryCallBack(lua.table_from({b"rbuf": self.call(2031)[0][16:]}))
        self.assertEqual(query[b"cornucopia"][b"count"], 0)
        with patch("random.Random.randrange", side_effect=[0, 50, 65, 75, 85]):
            packets = self.call(2032, [5, 0])
        lua.globals().gamedata[b"ext"][b"cornucopiaGold"] = 70
        result = lua.globals().NetCornucopiaCallBack(lua.table_from({b"rbuf": packets[0][16:]}))
        self.assertEqual(list(result[b"ext"].values()), [1, 2, 3, 4, 5])
        self.assertEqual(result[b"cornucopia"][b"box3"], 0)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"gold"], self.session.save["role_state"]["gold"])


if __name__ == "__main__":
    unittest.main()
