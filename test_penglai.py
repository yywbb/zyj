from contextlib import redirect_stdout
import copy
from fractions import Fraction
import io
import json
from pathlib import Path
import struct
import tempfile
import unittest
from unittest.mock import patch
import zipfile

import build_local_apk as builder
from zyj_server import battle, formation, guide, penglai, player, protocol, recharge, replay
from zyj_server.session import Session


ROOT = Path(__file__).parent
NOW = 1800000000 - 86400


class PenglaiTests(unittest.TestCase):
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
        cls.baseline["role_state"].update(level=22, gold=10000, vip=0, nextexp=cls.config["role_exp"]["22"]["nextexp"])

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

    def call(self, opcode, values=(), seed=0):
        self.sequence += 1
        with patch("random.getrandbits", return_value=seed):
            packets = self.session.handle(opcode, self.sequence, recharge.ids(values))
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], opcode)
        return packets

    def query(self):
        return protocol.parse_ids_pb(self.call(2120)[0][16:])

    def state(self):
        self.query()
        self.session.save["penglai_state"]["map"] = 1
        return self.session.save["penglai_state"]

    def props(self, cid):
        rows = formation.records(bytes.fromhex(self.session.save["world_state"]["1200"]), 1, 1)
        return protocol.pb_get_varint(rows.get(cid, b""), 2) or 0

    def give(self, cid, count):
        player.change_item_count(self.session.save, cid, count, self.config, NOW)
        self.path.write_text(json.dumps(self.session.save))

    def groups(self, body):
        return {protocol.pb_get_varint(row, 1): next(v for n, w, v in protocol.iter_pb_fields(row) if (n, w) == (2, 2))
                for n, w, row in protocol.iter_pb_fields(body) if (n, w) == (1, 2)}

    def assert_rejected(self, opcode, body):
        memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        packets = self.session.handle(opcode, 800, body)
        self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets], [999999, 1999])
        self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))

    def strong(self):
        world = bytes.fromhex(self.session.save["world_state"]["1002"])
        for raw in formation.records(world, 1, 2).values():
            for field in (6, 8):
                raw = protocol.pb_set_varint(raw, field, 10000000)
            raw = protocol.pb_set_varint(raw, 9, 10000)
            player.record_slot_update(self.session.save, protocol.encode_pb_field(1, 2, raw))

    def cards(self):
        state = self.state()
        state["location"] = 4
        self.give(20262, 1)
        self.call(2121, [1])
        return protocol.parse_ids_pb(self.call(2124)[0][16:])

    def test_entry_query_has_native_37_values_and_only_real_report_advances_guide(self):
        assets = copy.deepcopy(self.session.save["world_state"])
        values = self.query()
        self.assertEqual(len(values), 37)
        self.assertEqual(values[:6], [0, 1, 0, 0, 0, 1])
        self.assertEqual(values[6:], [0] * 31)
        self.assertEqual(self.session.save["world_state"], assets)
        self.assertNotIn("105", self.session.save["guide"]["sections"])
        self.session.handle(201, 700, protocol.encode_pb_field(1, 0, 105) + protocol.encode_pb_field(2, 0, 1))
        self.session = self.reconnect()
        self.assertEqual(self.session.save["guide"]["sections"]["105"]["status"], 2)

    def test_regular_dice_free_then_ordinal_gold_and_remote_uses_only_owned_prop(self):
        state = self.state()
        coin, gold = (self.session.save["role_state"][k] for k in ("coin", "gold"))
        self.call(2121)
        self.assertEqual((self.query()[2], self.session.save["role_state"]["gold"]), (1, gold))
        state = self.session.save["penglai_state"]
        state.update(location=1, dice=10)
        self.call(2121)
        self.assertEqual((self.query()[2], self.session.save["role_state"]["gold"]), (11, gold - 10))
        self.call(2127, [0])
        self.call(2126)
        self.give(20262, 1)
        state = self.session.save["penglai_state"]
        state["location"] = 1
        self.call(2121, [1])
        self.assertEqual(self.query()[2], 11)
        self.assertEqual(self.props(20262), 0)
        self.assertEqual(self.session.save["role_state"]["gold"], gold - 10)
        self.assertGreaterEqual(self.session.save["role_state"]["coin"], coin)
        self.assert_rejected(2121, recharge.ids([1]))

    def test_box_rewards_follow_native_level_formula_and_do_not_respawn_on_laps(self):
        state = self.state()
        self.give(20262, 3)
        before = self.props(20262)
        self.call(2121, [2])
        self.assertEqual(self.props(20262), before)
        state = self.session.save["penglai_state"]
        state["location"] = 1
        self.call(2121, [2])
        self.assertEqual(self.props(20262), before - 1)
        state = self.session.save["penglai_state"]
        state["location"] = 30
        self.call(2121, [3])
        self.assertEqual(self.query()[5], 2)
        self.session = self.reconnect()
        self.assertEqual(self.query()[6 + 2], 1)

    def test_real_wins_and_loss_do_not_change_campaign_experience_or_main_formation(self):
        state = self.state()
        state["location"] = 8
        self.give(20262, 2)
        before = copy.deepcopy(self.session.save)
        packets = self.call(2121, [1])
        groups = self.groups(packets[0][16:])
        report = json.loads(next(v for n, w, v in protocol.iter_pb_fields(groups[1]) if (n, w) == (5, 2)))
        self.assertFalse(report["result"])
        self.assertEqual(self.query()[3], 0)
        self.assertEqual(self.session.save["world_state"]["1300"], before["world_state"]["1300"])
        self.assertEqual(self.session.save["world_state"]["1002"], before["world_state"]["1002"])
        for key in ("stamina", "energy", "exp", "level"):
            self.assertEqual(self.session.save["role_state"][key], before["role_state"][key])
        self.strong()
        self.session.save["penglai_state"]["location"] = 8
        self.call(2121, [1])
        self.assertEqual(self.query()[3], 1)
        self.assertTrue(self.session.save["last_penglai_battle"]["won"])

    def test_four_actual_encounters_unlock_one_star_box_and_reset_does_not_auto_claim(self):
        self.state()
        self.strong()
        self.give(20262, 5)
        self.assert_rejected(2122, b"")
        for position, distance in ((8, 1), (15, 2), (24, 1), (30, 1)):
            self.session.save["penglai_state"]["location"] = position
            self.call(2121, [distance])
        self.assertEqual(self.query()[3:5], [4, 1])
        self.assert_rejected(2123, b"")
        before = self.props(20223)
        self.call(2122)
        self.assertEqual(self.props(20223) - before, 30)
        self.assert_rejected(2122, b"")
        self.call(2123)
        self.assertEqual(self.query()[:6], [1, 4, 0, 0, 0, 1])
        self.assertEqual(self.props(20223) - before, 30)
        self.call(2123)
        self.assertEqual(self.session.save["role_state"]["gold"], 9900)
        self.assert_rejected(2123, b"")

    def test_cards_persist_exact_deck_and_single_free_paid_and_bulk_prices(self):
        cards = self.cards()
        self.assertEqual(len(cards), 11)
        self.assertTrue(all(i in range(1, 10) for i in cards[1::2]))
        self.session = self.reconnect()
        self.assertEqual(protocol.parse_ids_pb(self.call(2124)[0][16:]), cards)
        self.assert_rejected(2121, b"")
        self.assert_rejected(2126, b"")
        for position in (1, 2, 3):
            self.call(2125, [0, position])
        self.assertEqual(self.session.save["role_state"]["gold"], 9995)
        self.assert_rejected(2125, recharge.ids([0, 1]))
        self.call(2125, [1, 1])
        self.assertEqual(self.session.save["role_state"]["gold"], 9970)
        self.assertEqual(protocol.parse_ids_pb(self.call(2124)[0][16:])[2::2], [1] * 5)
        self.call(2126)
        self.assertEqual(self.query()[6 + 4], 5)
        self.assert_rejected(2124, b"")
        self.call(2126)

    def test_auto_free_cards_forfeit_unflipped_prizes_and_paid_auto_opens_remaining(self):
        self.cards()
        self.call(2127, [0])
        state = self.session.save["penglai_state"]
        self.assertIsNone(state["card"])
        self.assertEqual(state["status"][4], 5)
        self.assertEqual(self.session.save["role_state"]["gold"], 10000)
        self.assert_rejected(2127, recharge.ids([0]))
        self.assert_rejected(2127, recharge.ids([1]))
        self.call(2123)
        self.cards()
        self.call(2125, [0, 1])
        self.call(2125, [0, 2])
        self.call(2127, [1])
        self.assertEqual(self.session.save["role_state"]["gold"], 9975)
        self.call(2126)
        self.assertIsNone(self.session.save["penglai_state"]["card"])

    def test_batch_roll_requires_unlock_never_buys_dice_and_stops_on_actual_loss(self):
        self.state()
        self.assert_rejected(2128, recharge.ids([0]))
        self.session.save["role_state"]["level"] = 50
        self.strong()
        packets = self.call(2128, [0], seed=7)
        groups = self.groups(packets[0][16:])
        self.assertEqual(protocol.parse_ids_pb(groups[0]), [0])
        self.assertEqual(self.query()[2], 10)
        self.assertIsNone(self.session.save["penglai_state"]["card"])
        self.assertEqual(self.session.save["role_state"]["gold"], 10000)
        self.assert_rejected(2128, recharge.ids([0]))
        self.session.save = copy.deepcopy(self.baseline)
        self.session.save["role_state"]["level"] = 50
        self.call(2128, [0], seed=7)
        self.assertLess(self.query()[2], 10)
        self.assertFalse(self.session.save["last_penglai_battle"]["won"])

    def test_forward_midnight_resets_daily_map_only_and_rollback_cannot_claim_or_roll(self):
        self.cards()
        world = copy.deepcopy(self.session.save["world_state"])
        self.clock.return_value += 86400
        self.assertEqual(self.query()[:6], [0, 1, 0, 0, 0, 1])
        for mid in ("1002", "1012", "1107", "1200"):
            self.assertEqual(self.session.save["world_state"][mid], world[mid])
        self.clock.return_value = NOW
        self.query()
        for opcode, values in ((2121, []), (2122, []), (2123, []), (2125, [0, 1]), (2128, [0])):
            self.assert_rejected(opcode, recharge.ids(values))

    def test_bad_requests_funds_and_failed_save_never_partially_consume(self):
        for opcode in range(2120, 2129):
            for body in (b"\x08", b"\x10\x01", b"\x0a\x00", recharge.ids([1 << 31]), recharge.ids([0, 0, 0])):
                self.assert_rejected(opcode, body)
        for values in ([0], [7], [1, 2]):
            self.assert_rejected(2121, recharge.ids(values))
        self.assert_rejected(2125, recharge.ids([2, 1]))
        self.assert_rejected(2128, recharge.ids([2]))
        state = self.state()
        state["dice"] = 10
        self.session.save["role_state"]["gold"] = 0
        self.assert_rejected(2121, b"")
        self.session.save["role_state"]["gold"] = 10000
        for opcode, values in ((2121, []), (2123, [])):
            self.session = self.reconnect()
            self.state()
            memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
            with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
                self.call(opcode, values)
            self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))
        self.session = self.reconnect()
        self.session.save["role_state"]["level"] = 21
        self.assert_rejected(2120, b"")
        self.assert_rejected(999900, protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 2121)))

    def test_latest_same_connection_retry_is_cached_and_save_survives_reconnect(self):
        self.state()
        packets = self.call(2121)
        memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        self.assertEqual(self.session.handle(2121, self.sequence, b""), packets)
        self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))
        self.session = self.reconnect()
        self.assertEqual(self.session.save["penglai_state"], memory["penglai_state"])

    def test_all_five_flips_reconnect_without_close_ack_does_not_block_next_roll(self):
        self.cards()
        self.call(2125, [1, 1])
        self.session = self.reconnect()
        self.assertEqual(self.query()[6 + 4], 5)
        self.give(20262, 1)
        self.call(2121, [1])
        self.assertEqual(self.query()[5], 6)
        self.assertIsNone(self.session.save["penglai_state"]["card"])

    def test_auto_free_flip_atomically_closes_before_disconnect_and_close_ack_is_safe(self):
        self.cards()
        self.call(2127, [0])
        self.assertIsNone(self.session.save["penglai_state"]["card"])
        self.session = self.reconnect()
        self.assertEqual(self.query()[6 + 4], 5)
        assets = copy.deepcopy(self.session.save["world_state"])
        self.call(2126)
        self.assertEqual(self.session.save["world_state"], assets)
        self.give(20262, 1)
        self.call(2121, [1])
        self.assertEqual(self.query()[5], 6)

    def test_friday_doubles_configured_prizes_but_reset_keeps_daily_dice_usage(self):
        self.clock.return_value += 86400
        self.state()
        self.give(20262, 1)
        before = self.props(20262)
        self.call(2121, [2])
        self.assertEqual(self.props(20262), before + 1)
        self.session.save["penglai_state"]["dice"] = 10
        self.call(2123)
        self.assertEqual(self.query()[2], 10)
        self.call(2121)
        self.assertEqual(self.session.save["role_state"]["gold"], 9990)

    def test_failed_card_claim_close_and_star_save_keep_exact_original_assets(self):
        self.cards()
        for opcode, values in ((2125, [0, 1]), (2127, [0])):
            memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
            with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
                self.call(opcode, values)
            self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))
            self.session = self.reconnect()
        self.call(2125, [0, 1])
        self.call(2125, [0, 2])
        memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
            self.call(2126)
        self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))
        self.session = self.reconnect()
        self.call(2126)
        state = self.session.save["penglai_state"]
        for position in (9, 17, 25, 31):
            state["status"][position - 1] = 1
        memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
            self.call(2122)
        self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))

    def test_paid_auto_card_insufficient_gold_and_overflow_roll_back_entire_exploration(self):
        self.cards()
        self.session.save["role_state"]["gold"] = 24
        self.assert_rejected(2127, recharge.ids([1]))
        self.call(2127, [0])
        self.call(2126)
        self.session.save["penglai_state"]["location"] = 1
        self.give(20262, 1)
        player.change_item_count(self.session.save, 20262, (1 << 31) - 1 - self.props(20262), self.config, NOW)
        self.session.save["penglai_state"]["status"][2] = 0
        # 扣一件遥控器后再加两件：奖励溢出仍必须回滚整次投掷。
        self.clock.return_value += 86400
        self.query()
        self.assert_rejected(2121, recharge.ids([2]))
        self.session.save["role_state"]["level"] = 50
        self.session.save["role_state"]["gold"] = 0
        with patch("random.getrandbits", return_value=7):
            self.assert_rejected(2128, recharge.ids([1]))
        self.session.save["penglai_state"]["dice"] = 9
        packets = self.call(2128, [1], seed=0)
        self.assertEqual(protocol.parse_ids_pb(self.groups(packets[0][16:])[0]), [0])
        self.assertEqual((self.query()[2], self.session.save["role_state"]["gold"]), (10, 0))

    def test_corrupt_map_and_card_history_fail_before_day_reset_without_overwriting_disk(self):
        self.cards()
        baseline = copy.deepcopy(self.session.save)
        for changes in ({"map": 5}, {"dice": True}, {"location": 32}, {"claimed": True},
                        {"status": [0] * 30}, {"card": None}, {"card": {"ids": [1] * 5, "opened": [1, 1]}}):
            data = copy.deepcopy(baseline)
            data["penglai_state"].update(changes)
            self.path.write_text(json.dumps(data))
            disk = self.path.read_bytes()
            self.clock.return_value = NOW + 86400
            with self.assertRaisesRegex(ValueError, "蓬莱"):
                self.reconnect()
            self.assertEqual(self.path.read_bytes(), disk)

    def test_all_390_npc_templates_use_current_v2_and_explicit_growth_percentages(self):
        before = copy.deepcopy(self.session.save)
        count = 0
        for kind, rows in self.config["penglai3_monster"].items():
            for level, row in rows.items():
                save = copy.deepcopy(before)
                save["role_state"]["level"] = int(level)
                attack, defense = penglai.rosters(save, int(kind), self.config)
                for i, position in enumerate(battle.POSITIONS, 1):
                    if position not in defense:
                        continue
                    monster = self.config["copy_monster"][str(row[f"p{i}"])]
                    for name in ("atk", "def", "hp"):
                        base = int(Fraction(str(monster[name])) + Fraction(str(monster[f"{name}-grow"])) * (int(level) - 1))
                        self.assertEqual(defense[position][name], base + base * row[f"p{i}-grow"] // 100 + row[f"{name}{i}-correct"])
                report = battle.simulate(attack, defense, self.config, 7)
                self.assertEqual(report["rules"], "zyj-v2")
                self.assertEqual(save, {**before, "role_state": {**before["role_state"], "level": int(level)}})
                count += 1
        self.assertEqual(count, 390)
        self.assertEqual(self.session.save, before)

    def test_actual_network_lua_queries_dice_cards_and_cost_callbacks_without_ui_globals(self):
        import test_activity_copy
        lua = test_activity_copy.ActivityCopyTests.network_lua(self)
        lua.execute(builder.read_script("combmessages_pb", "pb"))
        code = builder.read_script("gamedata").decode().replace("\r\n", "\n")
        lua.execute(code[code.index("function gamedata.Penglai3("):code.index("function gamedata.Penglai(")].encode())
        lua.execute(code[code.index("function gamedata.getIDandNUM("):code.index("function gamedata.getIDandData(")].encode())
        lua.execute(b'''gamedata.cache.penglai3={};gamedata.cache.role.gold=10000
            gamedata.updateRoleGold=function(self,n) self.cache.role.gold=self.cache.role.gold+n end
            propChanges={};gamedata.updateprops=function(self,p)
                propChanges[p.cid]=(propChanges[p.cid] or 0)+p.num end''')
        lua.execute(builder.read_script("GameIsland"))
        self.assertIsNone(lua.globals().gameConfig)
        result = lua.globals().NetPenglai3CallBack(lua.table_from({b"rbuf": self.call(2120)[0][16:]}))
        self.assertEqual(len(result[b"penglai"][b"status"]), 31)
        self.session.save["penglai_state"]["dice"] = 10
        lua.globals().gamedata[b"cache"][b"penglai3"][b"dice"] = 10
        remote, opcode, body = lua.globals().UIPenglai3DiceCallBack(lua.table_from({}))
        self.assertEqual((remote, opcode, body), (1, 2121, None))
        packets = self.call(2121)
        result = lua.globals().NetPenglai3DiceCallBack(lua.table_from({b"rbuf": packets[0][16:]}))
        self.assertEqual(result[b"penglai"][b"dice"], 11)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"gold"], 9990)
        cards = lua.globals().NetPenglai3CardCallBack(lua.table_from({b"rbuf": self.call(2124)[0][16:]}))
        self.assertEqual(len(cards[b"card"][b"cards"]), 5)
        for position in (1, 2, 3):
            remote, opcode, body = lua.globals().UIPenglai3CardOpenCallBack(lua.table_from({b"opt": 0, b"id": position, b"gold": 5 if position == 3 else 0}))
            packets = self.call(opcode, protocol.parse_ids_pb(body))
            lua.globals().NetPenglai3CardOpenCallBack(lua.table_from({b"rbuf": packets[0][16:]}))
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"gold"], self.session.save["role_state"]["gold"])
        self.call(2126)
        self.state()
        self.session.save["penglai_state"].update(location=8, dice=0)
        self.strong()
        self.give(20262, 1)
        remote, opcode, body = lua.globals().UIPenglai3DiceCallBack(lua.table_from({b"dice": 1}))
        self.assertEqual((remote, opcode, body), (1, 2121, recharge.ids([1])))
        packets = self.call(opcode, protocol.parse_ids_pb(body))
        result = lua.globals().NetPenglai3DiceCallBack(lua.table_from({b"rbuf": packets[0][16:]}))
        self.assertTrue(result[b"result"])
        self.assertIsNotNone(result[b"battlereport"])
        self.assertEqual(lua.globals().propChanges[20262], -1)
        self.assertEqual(len(result[b"reward"][b"usedcidnums"]), 0)

    def test_all_penglai_reports_convert_with_actual_apk_animations_and_shields(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("蓬莱原生战报验证需要本机已有lupa.lua51")
        import test_build_local_apk
        lua = LuaRuntime()
        config = dict(self.config)
        with zipfile.ZipFile(ROOT / "configs_sec5.zip") as archive:
            for name in ("generalanimation", "skillanimation", "personalboss_att"):
                config[name] = json.loads(archive.read("5/" + name + ".json"))
        lua.globals().gamedata = lua.table_from({"config": config}, recursive=True)
        lua.execute('''print=function() end;printT=print;battleScene={slotNum=7}
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            CCFileUtils={sharedFileUtils=function(self) return self end,fullPathForFilename=function(self,p) return p end}
            ui={Split=function(s,sep) local t={} for v in string.gmatch(s,'[^'..sep..']+') do t[#t+1]=v end return t end}''')
        with zipfile.ZipFile(builder.SRC_APK) as archive:
            names, assets = archive.namelist(), {}
            lua.globals().CCFileUtils.isFileExist = lambda _, path: any(n.endswith("/" + path) for n in names)
            def load_asset(path):
                if path not in assets:
                    matches = [n for n in names if n.endswith("/" + path)]
                    self.assertEqual(len(matches), 1, path)
                    assets[path] = json.loads(archive.read(matches[0]))
                return lua.table_from(assets[path], recursive=True)
            lua.globals().LoadJsonFileToTable = load_asset
            scripts = test_build_local_apk.LanBuildTests.client_scripts(self)
            lua.execute(scripts["assets/scripts/battleReportConvert.so"])
            lua.execute(builder.read_script("BattleReportAbbToKey"))
            count = 0
            for kind, rows in config["penglai3_monster"].items():
                for level in rows:
                    save = copy.deepcopy(self.session.save)
                    save["role_state"]["level"] = int(level)
                    attack, defense = penglai.rosters(save, int(kind), config)
                    report = battle.simulate(attack, defense, config, 7)
                    native = lua.table_from(json.loads(lua.globals().ReplaceAbbToKey(json.dumps(report))), recursive=True)
                    atk, enemy = lua.globals().getBattleInitSlotInfo(native)
                    animations, ext = lua.globals().convertBattleReportToAnimationSub(native, atk, enemy, None, "penglai")
                    self.assertGreater(len(animations), 1)
                    for side, key in (("attack", "atk"), ("defense", "def")):
                        for pos, unit in report["endmeta"][side].items():
                            self.assertEqual((ext.endinfo[key][pos].hp, ext.endinfo[key][pos].ap), (unit["h"], unit["ap"]))
                    count += 1
            self.assertEqual(count, 390)


if __name__ == "__main__":
    unittest.main()
