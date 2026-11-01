from contextlib import redirect_stdout
import copy
import io
import json
from pathlib import Path
import struct
import tempfile
import unittest
from unittest.mock import patch
import zipfile

import build_local_apk as builder
from zyj_server import formation, guide, player, protocol, recharge, replay
from zyj_server.session import Session


ROOT = Path(__file__).parent
NOW = 1800000000


class FavoriteGuideTests(unittest.TestCase):
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
        cls.baseline["role_state"].update(level=24, nextexp=cls.config["role_exp"]["24"]["nextexp"])

    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.path = Path(temporary.name) / "role_save.json"
        self.path.write_text(json.dumps(self.baseline))
        clock = patch("time.time", return_value=NOW)
        clock.start()
        self.addCleanup(clock.stop)
        quiet = redirect_stdout(io.StringIO())
        quiet.__enter__()
        self.addCleanup(quiet.__exit__, None, None, None)
        self.session = self.reconnect()

    def reconnect(self):
        return Session(self.tables, self.path, self.steps, self.config)

    def query(self, opcode, values=()):
        packets = self.session.handle(opcode, 200, recharge.ids(values))
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], opcode)
        return protocol.parse_ids_pb(packets[0][16:])

    def assert_rejected(self, opcode, body):
        memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        packets = self.session.handle(opcode, 201, body)
        self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets], [999999, 1999])
        self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))

    def test_entry_queries_supply_complete_zero_affinity_without_changing_progress(self):
        before = copy.deepcopy(self.session.save)
        rows = self.query(3671)
        self.assertTrue(rows)
        self.assertEqual(len(rows) % 2, 0)
        self.assertTrue(all(level == 0 for level in rows[1::2]))
        self.assertTrue(all(str(cid) in self.config["favorable"] for cid in rows[::2]))
        selected = self.query(3670)
        self.assertEqual(len(selected), 18)
        self.assertIn(selected[0], rows[::2])
        self.assertEqual(selected[1:], [0] * 17)
        tasks = self.query(3673)
        self.assertEqual(dict(zip(tasks[::2], tasks[1::2])), {int(cid): 0 for cid in self.config["favorable_task"]})
        for cid in rows[::2]:
            self.assertEqual(self.query(3670, [cid]), [cid] + [0] * 17)
        for key in ("guide", "world_state", "role_state", "protagonist_snapshot"):
            self.assertEqual(self.session.save[key], before[key])
        self.session = self.reconnect()
        self.assertEqual(self.query(3671), rows)

    def test_only_real_reports_complete_level24_and_first_entry_guides(self):
        self.query(3671)
        self.assertNotIn("20", self.session.save["guide"]["sections"])
        self.assertNotIn("56", self.session.save["guide"]["sections"])
        self.assertEqual((self.steps[20], self.steps[56]), (1, 2))
        for section, step in ((20, 1), (56, 1), (56, 2)):
            body = protocol.encode_pb_field(1, 0, section) + protocol.encode_pb_field(2, 0, step)
            self.session.handle(201, 202 + step, body)
            self.session = self.reconnect()
            saved = self.session.save["guide"]["sections"][str(section)]
            self.assertEqual((saved["step"], saved["status"]), (step, 2 if step == self.steps[section] else 1))
            self.query(3670)
        queried = self.session.handle(200, 210, b"")[0][16:]
        self.assertIn(guide.encode_guide_section(56, 2, 2), [v for _, _, v in protocol.iter_pb_fields(queried)])
        self.assertEqual(self.config["role_exp"]["24"]["slotnum"], 7)

    def test_new_account_initialization_retains_the_locked_empty_preload(self):
        request = next(frame for frame in replay.split_recordings(replay.load_recordings(ROOT / "recorded_frames.json"))[0]
                       if frame["c2s"] and frame["opcode"] == 999900 and 3671 in protocol.get_comb_ids(bytes.fromhex(frame["hex"])))
        fresh = Session(self.tables, self.path.with_name("fresh.json"), self.steps, self.config)
        before = copy.deepcopy(fresh.save["guide"])
        packets = fresh.handle(999900, 212, bytes.fromhex(request["hex"]))
        reply = next(p[16:] for p in packets if struct.unpack(">IIII", p[:16])[2] == 999900)
        self.assertEqual(dict(protocol.get_comb_messages(reply))[3671], b"")
        self.assertEqual(fresh.save["guide"], before)

    def test_ownership_comes_from_current_roster_not_config_or_cached_queries(self):
        rows = self.query(3671)
        world = bytes.fromhex(self.session.save["world_state"]["1002"])
        self.session.save["world_state"]["1002"] = b"".join(protocol.encode_pb_field(n, w, v)
            for n, w, v in protocol.iter_pb_fields(world) if (n, w) != (1, 2)).hex()
        self.assertEqual(self.query(3671), [])
        self.assert_rejected(3670, b"")
        self.assert_rejected(3670, recharge.ids([rows[0]]))
        raw = next(iter(formation.records(world, 1, 2).values()))
        raw = protocol.pb_set_varint(raw, 1, 10501)
        player.record_slot_update(self.session.save, protocol.encode_pb_field(1, 2, raw))
        self.assertEqual(self.query(3671), [10501, 0])
        self.assertEqual(self.query(3670), [10501] + [0] * 17)

    def test_invalid_locked_and_comb_queries_leave_memory_and_disk_unchanged(self):
        for opcode in (3670, 3671, 3673):
            for body in (b"\x08", b"\x10\x01", b"\x0a\x00", recharge.ids([0]), recharge.ids([1 << 31]), recharge.ids([10213, 10213])):
                with self.subTest(opcode=opcode, body=body.hex()):
                    self.assert_rejected(opcode, body)
        self.assert_rejected(3670, recharge.ids([999999]))
        for opcode in (3671, 3673):
            self.assert_rejected(opcode, recharge.ids([10213]))
        comb = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 3671))
        self.assert_rejected(999900, comb)
        self.session.save["role_state"]["level"] = 23
        for opcode in (3670, 3673):
            self.assert_rejected(opcode, b"")
        self.assertEqual(self.query(3671), [])
        self.session.save["role_state"]["level"] = 24
        self.session.save["has_role"] = False
        self.assert_rejected(3670, b"")
        self.assertEqual(self.query(3671), [])

    def test_unimplemented_gifting_claims_and_exchange_cannot_use_recorded_successes(self):
        for opcode, values in ((3672, [10213, 20201, 1]), (3674, [1001]), (3675, [10213, 10214])):
            self.assert_rejected(opcode, recharge.ids(values))

    def test_failed_query_save_does_not_publish_partial_settlement(self):
        for opcode in (3670, 3671, 3673):
            self.session = self.reconnect()
            self.session.connected_at -= 60
            self.session.save["online_reward_state"]["checked_at"] -= 60
            memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
            with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
                self.query(opcode)
            self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))

    def test_actual_apk_callbacks_and_guide_accept_the_query_chain(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("实际APK回调验证需要本机已有lupa.lua51")
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.globals().decode_ids = lambda raw: lua.table_from(protocol.parse_ids_pb(bytes.fromhex(raw)))
        lua.execute('''print=function() end;printT=print;cclog=print
            require=function() return {Ids=function() return {ids={},
                SerializeToString=function(self) return self.ids end,
                ParseFromString=function(self,raw) self.ids=decode_ids(raw) end} end} end
            gamedata={cache={generalslove={},generalslovetask={},props={},generals={}},ext={}}
            gamedata.time=function() return 1800000000 end
            makeAllGeneralsTemp=function() return gamedata.cache.generals end
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end''')
        lua.globals().gamedata.config = lua.table_from(self.config, recursive=True)
        world = bytes.fromhex(self.session.save["world_state"]["1002"])
        lua.globals().gamedata.cache.generals = lua.table_from([
            {"cid": protocol.pb_get_varint(raw, 1), "level1": protocol.pb_get_varint(raw, 3), "ison": 1}
            for raw in formation.records(world, 1, 2).values()], recursive=True)
        source = builder.read_script("gamedata").decode()
        lua.execute(source[source.index("function gamedata.generalLoveData("):source.index("function gamedata.generalAttrChange(")])
        lua.execute(builder.read_script("GameFavorite"))
        self.assertIsNone(lua.globals().gameConfig)
        for opcode, name in ((3671, "NetGeneralsLoveQueryCallback"), (3673, "NetGeneralLoveTaskCallBack"), (3670, "NetGeneralLoveCallBack")):
            packet = self.session.handle(opcode, 211, b"")[0]
            result = lua.globals()[name](lua.table_from({"rbuf": packet[16:].hex()}))
            self.assertEqual(result.type, opcode)
        lua.execute('assert(gamedata.cache.generalslove.showdata.cid>0 and gamedata.cache.generalslove.showdata.level==0)')
        lua.execute(builder.read_script("GameTimeBag"))
        lua.execute('gamedata.cache.timebag={};gamedata.cache.role={level=24}')
        lua.execute('local net,opcode=UITimeBagTrigCallBack({opt=1,sysID=138});assert(net==0 and opcode==2882)')
        controller = lua.execute(builder.read_script("guideControl"))
        with zipfile.ZipFile(ROOT / "configs_sec5.zip") as archive:
            controller.config = lua.table_from({"section": json.loads(archive.read("5/guide_section.json")),
                                               "step": json.loads(archive.read("5/guide_step.json"))}, recursive=True)
        controller.data = lua.table()
        lua.globals().controller = controller
        lua.globals().report_step = lambda section, step: self.session.handle(201, 220 + step,
            protocol.encode_pb_field(1, 0, section) + protocol.encode_pb_field(2, 0, step))
        lua.execute('''guide={excuteGuide=function(self,t) shown=t end,removeGuideLayer=function() end}
            GameScene={setNew=function() end,layers={}}
            UIRequest=function(t) assert(t.type==201);report_step(t.section,t.step) end
            controller:LevelUp3(24);assert(shown.section==20)
            controller:CompleteStep("animation",8060)
            controller:NewSystem(138);assert(shown.section==56 and shown.step==1)
            controller:CompleteStep("UI",8020);assert(shown.step==2)
            controller:CompleteStep("UI",8020);assert(not controller.isOnGuide)''')
        self.session = self.reconnect()
        self.assertEqual(self.session.save["guide"]["sections"]["56"]["status"], 2)


if __name__ == "__main__":
    unittest.main()
