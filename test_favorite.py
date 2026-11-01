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
from zyj_server import favorite, formation, guide, player, protocol, qiankun, recharge, recruit, replay
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

    def call(self, opcode, values=(), seq=None):
        self.sequence = getattr(self, "sequence", 300) + 1
        packets = self.session.handle(opcode, self.sequence if seq is None else seq, recharge.ids(values))
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], opcode)
        return packets

    def give(self, items):
        for cid, count in items.items():
            player.change_item_count(self.session.save, cid, count, self.config, NOW)
        self.path.write_text(json.dumps(self.session.save))

    def roster(self):
        return formation.records(bytes.fromhex(self.session.save["world_state"]["1002"]), 1, 2)

    def groups(self, body):
        return {protocol.pb_get_varint(row, 1): next(v for n, w, v in protocol.iter_pb_fields(row) if (n, w) == (2, 2))
                for n, w, row in protocol.iter_pb_fields(body) if (n, w) == (1, 2)}

    def prop_count(self, cid):
        props = formation.records(bytes.fromhex(self.session.save["world_state"]["1200"]), 1, 1)
        return protocol.pb_get_varint(props.get(cid, b""), 2) or 0

    def add_general(self, cid=10501):
        iid = max(2000000, *self.roster()) + 1
        player.record_slot_update(self.session.save, protocol.encode_pb_field(1, 2, recruit.new_general(cid, iid, self.config)))
        self.path.write_text(json.dumps(self.session.save))
        return iid

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

    def test_invalid_gifting_claims_and_exchange_cannot_use_recorded_successes(self):
        for opcode, values in ((3672, [10213, 20201, 0]), (3674, [1001]), (3675, [10213, 10213])):
            self.assert_rejected(opcode, recharge.ids(values))

    def test_gifting_commits_actual_cost_stats_overflow_and_retry_once(self):
        cid = self.query(3670)[0]
        iid, before = next((iid, raw) for iid, raw in self.roster().items() if protocol.pb_get_varint(raw, 1) == cid)
        self.give({20220: 3})
        progress = copy.deepcopy(self.session.save["guide"])
        with patch("random.Random.random", return_value=.99):
            packets = self.call(3672, [cid, 20220, 3], seq=330)
        self.assertEqual(self.prop_count(20220), 0)
        self.assertEqual(self.query(3670, [cid])[1:3], [300, 1])
        after = self.roster()[iid]
        self.assertEqual(protocol.pb_get_varint(after, 6) - protocol.pb_get_varint(before, 6), 30)
        groups = self.groups(packets[0][16:])
        self.assertEqual(protocol.parse_ids_pb(groups[2]), [0, 20220, 3])
        self.assertEqual(formation.records(groups[1], 1, 2)[iid], after)
        saved = copy.deepcopy(self.session.save)
        self.assertEqual(self.call(3672, [cid, 20220, 3], seq=330), packets)
        self.assertEqual(self.session.save, saved)
        self.assertEqual(self.session.save["guide"], progress)
        self.session = self.reconnect()
        self.assertEqual(self.query(3670, [cid])[1:3], [300, 1])

    def test_configured_critical_gift_and_complete_achievement_are_persistent(self):
        cid = self.query(3670)[0]
        self.give({20201: 5})
        with patch("random.Random.random", return_value=0):
            packets = self.call(3672, [cid, 20201, 5])
        groups = self.groups(packets[0][16:])
        self.assertEqual(protocol.parse_ids_pb(groups[2]), [5, 20201, 5])
        self.assertEqual(self.query(3670, [cid])[1:3], [0, 5])
        tasks = self.query(3673)
        self.assertEqual(dict(zip(tasks[::2], tasks[1::2]))[1001], 1)
        before = copy.deepcopy(self.session.save["role_state"])
        packets = self.call(3674, [1001])
        self.assertIn(1001, [struct.unpack(">IIII", p[:16])[2] for p in packets[1:]])
        self.assertEqual(self.session.save["role_state"]["maxenergy"], before["maxenergy"] + 2)
        self.assertEqual(self.session.save["role_state"]["energy"], before["energy"])
        self.session = self.reconnect()
        self.assert_rejected(3674, recharge.ids([1001]))
        tasks = self.query(3673)
        self.assertEqual(dict(zip(tasks[::2], tasks[1::2]))[1001], 2)

    def test_owned_exchange_moves_full_affinity_and_cost_without_losing_training(self):
        cid = self.query(3670)[0]
        other_iid = self.add_general()
        self.give({20201: 3})
        with patch("random.Random.random", return_value=0):
            self.call(3672, [cid, 20201, 3])
        before = copy.deepcopy(self.session.save)
        original = self.roster()
        packets = self.call(3675, [cid, 10501])
        self.assertEqual(self.query(3670, [cid])[1:3], [0, 0])
        self.assertEqual(self.query(3670, [10501])[1:3], [0, 3])
        self.assertEqual(before["role_state"]["gold"] - self.session.save["role_state"]["gold"], 10)
        rows = self.roster()
        self.assertEqual(protocol.pb_get_varint(rows[other_iid], 6) - protocol.pb_get_varint(original[other_iid], 6), 50)
        self.assertEqual(formation.records(packets[0][16:], 1, 2)[other_iid], rows[other_iid])
        for iid, raw in rows.items():
            self.assertEqual(protocol.pb_get_varint(raw, 3), protocol.pb_get_varint(original[iid], 3))
        self.assertLess(self.session.save["role_state"]["power"], before["role_state"]["power"])

    def test_gift_cap_clips_actual_consumption_and_higher_levels_require_general_level(self):
        cid = self.query(3670)[0]
        self.give({20220: 50})
        state = favorite.get_state(self.session.save, self.config)
        state["generals"][str(cid)] = [29, self.config["favorable_level"]["30"]["exp4"] - 10]
        with patch("random.Random.random", return_value=.99):
            packets = self.call(3672, [cid, 20220, 50])
        groups = self.groups(packets[0][16:])
        self.assertEqual(protocol.parse_ids_pb(groups[2]), [0, 20220, 1])
        self.assertEqual(self.prop_count(20220), 49)
        self.assertEqual(self.query(3670, [cid])[1:3], [0, 30])
        self.assert_rejected(3672, recharge.ids([cid, 20220, 1]))
        self.add_general()
        favorite.get_state(self.session.save, self.config)["generals"]["10501"] = [50, 0]
        self.assert_rejected(3672, recharge.ids([10501, 20220, 1]))
        self.assert_rejected(3675, recharge.ids([cid, 10501]))

    def test_gifting_bad_inputs_and_failed_save_never_spend_or_change_stats(self):
        cid = self.query(3670)[0]
        self.give({20201: 10})
        for values in ([cid], [cid, 20201, 11], [cid, 20201, 1, 20201, 1], [cid, 20201, 51],
                       [cid, 999999, 1], [999999, 20201, 1], [cid, 20201, 1, 20220, 1]):
            self.assert_rejected(3672, recharge.ids(values))
        memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
            self.call(3672, [cid, 20201, 1])
        self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))

    def test_affinity_survives_refinement_recruitment_and_safe_rebirth_without_refunding_gifts(self):
        iid = self.add_general()
        self.give({20201: 1, 20196: 1, 1000: 100000, 1001: 100})
        body = protocol.encode_pb_field(1, 0, iid) + b"".join(protocol.encode_pb_field(2, 0, n) for n in (1, 0, 0, 0))
        packets = self.session.handle(1038, 350, body)
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 1038)
        receipt = copy.deepcopy(qiankun.get_state(self.session.save)["receipts"][f"general:{iid}"])
        with patch("random.Random.random", return_value=0):
            self.call(3672, [10501, 20201, 1])
        updated = qiankun.get_state(self.session.save)["receipts"][f"general:{iid}"]
        self.assertEqual(updated["costs"], receipt["costs"])
        self.assertEqual(protocol.pb_get_varint(bytes.fromhex(updated["before"]), 6)
                         - protocol.pb_get_varint(bytes.fromhex(receipt["before"]), 6), 50)
        self.call(1035, [iid])
        self.assertEqual(protocol.pb_get_varint(self.roster()[iid], 3), 1)
        self.assertEqual(self.prop_count(20201), 0)
        request = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, iid)
                                           + protocol.encode_pb_field(2, 0, (1 << 64) - 1))
        packets = self.session.handle(1039, 400, request)
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 1039)
        self.assertNotIn(iid, self.roster())
        self.assertIn(10501, self.query(3671)[::2])
        reward = recruit.build_reward(self.session.save, [(10501, 1)], self.config)
        returned = next(v for n, w, v in protocol.iter_pb_fields(reward) if (n, w) == (8, 2))
        self.assertEqual(protocol.pb_get_varint(returned, 6), self.config["general"]["10501"]["atk"] + 50)
        player.apply_reward(self.session.save, reward, self.config, NOW)
        self.assertEqual(self.query(3670, [10501])[2], 1)

    def test_claimed_energy_capacity_survives_real_campaign_level_up(self):
        cid = self.query(3670)[0]
        self.give({20201: 5})
        with patch("random.Random.random", return_value=0):
            self.call(3672, [cid, 20201, 5])
        self.call(3674, [1001])
        self.session.save["role_state"]["exp"] = self.config["role_exp"]["24"]["nextexp"] - 1
        self.call(1307, [42101, 1, 0, 0])
        level = self.session.save["role_state"]["level"]
        self.assertGreater(level, 24)
        self.assertEqual(self.session.save["role_state"]["maxenergy"], self.config["role_exp"][str(level)]["maxenergy"] + 2)
        self.session = self.reconnect()
        self.assertEqual(self.session.save["role_state"]["maxenergy"], self.config["role_exp"][str(level)]["maxenergy"] + 2)

    def test_refined_partner_keeps_history_and_can_move_it_back_to_an_owned_partner(self):
        iid = self.add_general()
        self.give({20201: 1})
        with patch("random.Random.random", return_value=0):
            self.call(3672, [10501, 20201, 1])
        request = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, iid)
                                           + protocol.encode_pb_field(2, 0, (1 << 64) - 1))
        packets = self.session.handle(1039, 700, request)
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 1039)
        cid = self.query(3670)[0]
        self.call(3675, [10501, cid])
        self.assertEqual(self.query(3670, [10501])[1:3], [0, 0])
        self.assertEqual(self.query(3670, [cid])[1:3], [0, 1])
        self.assert_rejected(3675, recharge.ids([cid, 10501]))

    def test_corrupt_affinity_history_fails_closed_and_configured_stats_cover_all_81_partners(self):
        for cid, row in self.config["favorable"].items():
            before = {6: 0, 7: 0, 8: 0}
            for level in range(1, row["level"] + 1):
                current = favorite.stats(int(cid), level, self.config)
                self.assertTrue(all(current[field] >= before[field] for field in before))
                self.assertGreater(sum(current.values()), sum(before.values()))
                before = current
        for changes in ({"generals": {"10213": [True, 0]}}, {"generals": {"10213": [31, 0]}},
                        {"generals": {"10213": [0, 300]}}, {"generals": {"10213": [1, -1]}},
                        {"claimed": [1001]}, {"claimed": [999999]}):
            data = copy.deepcopy(self.baseline)
            data["favorite_state"] = {"generals": {}, "claimed": [], **changes}
            self.path.write_text(json.dumps(data))
            disk = self.path.read_bytes()
            with self.assertRaises(ValueError):
                self.reconnect()
            self.assertEqual(self.path.read_bytes(), disk)

    def test_mutation_overflow_and_failed_exchange_preserve_all_assets(self):
        cid = self.query(3670)[0]
        self.add_general()
        self.give({20201: 5})
        self.session.save["role_state"]["power"] = (1 << 31) - 1
        with patch("random.Random.random", return_value=0):
            self.assert_rejected(3672, recharge.ids([cid, 20201, 1]))
        self.session = self.reconnect()
        with patch("random.Random.random", return_value=0):
            self.call(3672, [cid, 20201, 5])
        for opcode, values in ((3674, [1001]), (3675, [cid, 10501])):
            self.session = self.reconnect()
            memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
            with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
                self.call(opcode, values)
            self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))
        self.session = self.reconnect()
        with patch.dict(self.config["favorable_level"]["5"], {"favor_exchange_price": "1001,-10;"}):
            self.assert_rejected(3675, recharge.ids([cid, 10501]))

    def test_real_network_lua_consumes_gifts_once_and_parses_gifting_claim_and_exchange(self):
        import test_activity_copy
        self.add_general()
        self.give({20201: 5})
        lua = test_activity_copy.ActivityCopyTests.network_lua(self)
        for name in ("combmessages_pb", "generals_pb"):
            lua.execute(builder.read_script(name, "pb"))
        code = builder.read_script("gamedata").decode().replace("\r\n", "\n")
        lua.execute(code[code.index("function gamedata.generalLoveData("):code.index("function gamedata.generalAttrChange(")].encode())
        lua.execute(code[code.index("function gamedata.getIDandNUMs("):code.index("function gamedata.getIds(")].encode())
        lua.execute(b'''gamedata.cache.generalslove={};gamedata.cache.generalslovetask={}
            gamedata.cache.props={[20201]={cid=20201,num=5}};gamedata.cache.generals={}
            gamedata.updateprops=function(self,p) self.cache.props[p.cid].num=self.cache.props[p.cid].num+p.num end
            gamedata.Generals=function(self,rows) for _,row in ipairs(rows) do self.cache.generals[row.iid]=row end end
            gamedata.updateStaff=function(self,p) if p.cid==1001 then self.cache.role.gold=self.cache.role.gold+p.num end end
            makeAllGeneralsTemp=function() return gamedata.cache.generals end''')
        lua.globals().gamedata[b"cache"][b"role"][b"gold"] = self.session.save["role_state"]["gold"]
        for iid, raw in self.roster().items():
            lua.globals().gamedata[b"cache"][b"generals"][iid] = lua.table_from({
                b"cid": protocol.pb_get_varint(raw, 1), b"level1": protocol.pb_get_varint(raw, 3), b"ison": 0})
        lua.execute(builder.read_script("GameFavorite"))
        remote, opcode, body = lua.globals().UIGeneralLoveUsePropCallBack(lua.table_from({
            b"cid": 10501, b"props": lua.table_from([lua.table_from({b"cid": 20201, b"num": 5})])}))
        self.assertEqual((remote, opcode, body), (1, 3672, recharge.ids([10501, 20201, 5])))
        with patch("random.Random.random", return_value=0):
            packets = self.session.handle(opcode, 600, body)
        result = lua.globals().NetGeneralLoveUsePropCallBack(lua.table_from({b"rbuf": packets[0][16:]}))
        self.assertEqual(result[b"favorite"][b"level"], 5)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"props"][20201][b"num"], self.prop_count(20201))
        self.assertEqual(result[b"useprops"][b"baojinum"], 5)
        for mid, name in ((3671, "NetGeneralsLoveQueryCallback"), (3673, "NetGeneralLoveTaskCallBack")):
            getattr(lua.globals(), name)(lua.table_from({b"rbuf": self.call(mid)[0][16:]}))
        lua.globals().gamedata[b"ext"][b"GeneralLoveTaskRewardid"] = lua.table_from({b"cid": 1001, b"text": b"reward"})
        packets = self.call(3674, [1001])
        lua.globals().NetGeneralLoveTaskRewardCallBack(lua.table_from({b"rbuf": packets[0][16:]}))
        self.assertEqual(lua.globals().gamedata[b"cache"][b"generalslovetask"][1001][b"status"], 2)
        other = self.query(3670)[0]
        remote, opcode, body = lua.globals().UIGeneralLoveExchangeCallBack(lua.table_from({b"cid1": 10501, b"cid2": other}))
        packets = self.session.handle(opcode, 601, body)
        result = lua.globals().NetGeneralLoveExchangeCallBack(lua.table_from({b"rbuf": packets[0][16:]}))
        self.assertEqual(result[b"allgeneral"][other][b"level"], 5)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"gold"], self.session.save["role_state"]["gold"])
        self.assertIsNone(lua.globals().gameConfig)

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
