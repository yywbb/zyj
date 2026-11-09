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
from zyj_server import activities, activity_copy, battle, formation, guide, player, protocol, recharge, replay
from zyj_server.session import Session


ROOT = Path(__file__).parent
NOW = 1800172800  # UTC+8 周日，六类活动均开放。


class ActivityCopyTests(unittest.TestCase):
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
            cls.baseline = copy.deepcopy(session.save)
        cls.baseline["role_state"].update(level=23, nextexp=cls.config["role_exp"]["23"]["nextexp"])
        cls.baseline["guide"]["sections"]["64"] = {"status": 1, "step": 1, "steps": [1]}

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

    def reconnect(self):
        return Session(self.tables, self.path, self.steps, self.config)

    def call(self, opcode, values=(), seq=181):
        return self.session.handle(opcode, seq, recharge.ids(values))

    def rows(self):
        packet = self.call(1340)[0]
        self.assertEqual(struct.unpack(">IIII", packet[:16])[2], 1340)
        values = protocol.parse_ids_pb(packet[16:])
        self.assertEqual(len(values) % 5, 0)
        return {values[i]: values[i:i + 5] for i in range(0, len(values), 5)}

    def strengthen(self, *, weak=False):
        world = bytes.fromhex(self.session.save["world_state"]["1002"])
        for raw in formation.records(world, 1, 2).values():
            for field, value in ((6, 1 if weak else 10000000), (7, 0), (8, 1 if weak else 10000000), (9, 1 if weak else 1000)):
                raw = protocol.pb_set_varint(raw, field, value)
            player.record_slot_update(self.session.save, protocol.encode_pb_field(1, 2, raw))
        self.path.write_text(json.dumps(self.session.save))

    def report(self, packets):
        return json.loads(next(v for n, w, v in protocol.iter_pb_fields(packets[0][16:]) if (n, w) == (5, 2)))

    def prop_count(self, save, cid):
        props = formation.records(bytes.fromhex(save["world_state"]["1200"]), 1, 1)
        return protocol.pb_get_varint(props.get(cid, b""), 2) or 0

    def assert_rejected(self, opcode, body):
        memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        packets = self.session.handle(opcode, 200, body)
        self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets], [999999, 1999])
        self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))

    def test_query_opens_section64_without_granting_or_advancing_anything(self):
        before = copy.deepcopy(self.session.save)
        self.assertEqual(self.rows(), {i: [i, 0, 1, 1, 0] for i in range(1, 7)})
        for key in ("guide", "world_state", "role_state", "protagonist_snapshot"):
            self.assertEqual(self.session.save[key], before[key])
        self.session = self.reconnect()
        self.assertEqual(self.rows()[1], [1, 0, 1, 1, 0])
        self.session.handle(201, 182, b"\x08\x40\x10\x02")
        self.session = self.reconnect()
        self.assertEqual(self.session.save["guide"]["sections"]["64"], {"status": 2, "step": 2, "steps": [1, 2]})

    def test_actual_victory_rewards_and_unlock_survive_reconnect_and_retry(self):
        self.strengthen()
        before = copy.deepcopy(self.session.save)
        packets = self.call(1342, [1])
        report = self.report(packets)
        self.assertTrue(report["result"])
        for cid in (26407, 26410):
            self.assertIn(self.prop_count(self.session.save, cid) - self.prop_count(before, cid), (1, 2))
        self.assertEqual(self.rows()[1], [1, 1, 2, 1, 1])
        for key in ("guide", "protagonist_snapshot"):
            self.assertEqual(self.session.save[key], before[key])
        for key in ("exp", "level", "stamina", "energy", "power"):
            self.assertEqual(self.session.save["role_state"][key], before["role_state"][key])
        for key in ("1002", "1300"):
            self.assertEqual(self.session.save["world_state"][key], before["world_state"][key])
        saved = copy.deepcopy(self.session.save)
        self.assertEqual(self.call(1342, [1]), packets)
        self.assertEqual(self.session.save, saved)
        self.session = self.reconnect()
        self.assertEqual(self.rows()[1], [1, 1, 2, 1, 1])

    def test_regular_loss_neither_spends_a_success_nor_grants_rewards(self):
        self.strengthen(weak=True)
        before = copy.deepcopy(self.session.save)
        packets = self.call(1342, [1])
        self.assertFalse(self.report(packets)["result"])
        self.assertEqual(self.rows()[1], [1, 0, 1, 0, 0])
        for key in ("guide", "world_state", "role_state", "protagonist_snapshot"):
            self.assertEqual(self.session.save[key], before[key])

    def test_boss_uses_five_real_rounds_and_damage_brackets_even_without_a_kill(self):
        before = copy.deepcopy(self.session.save)
        packets = self.call(1341, [1])
        report = self.report(packets)
        self.assertFalse(report["result"])
        self.assertEqual(report["round"], 5)
        self.assertTrue(all(action["s"].get("r", True) for action in report["b"]["a"]))
        initial = next(iter(report["meta"]["defense"]["g"].values()))["j"]
        remaining = next(iter(report["endmeta"]["defense"].values()))["h"]
        percent = (initial - remaining) * 100 // initial
        bucket = percent // 10 * 10
        expected = int(self.config["coin_copy"]["1"][f"{bucket}_reward"].strip(";").split(",")[1])
        self.assertEqual(self.session.save["role_state"]["coin"] - before["role_state"]["coin"], expected)
        self.assertEqual(self.rows()[2], [2, 1, 1, 0, 0])
        self.assertEqual(self.session.save["guide"], before["guide"])
        self.assertEqual(next(iter(report["meta"]["defense"]["g"].values()))["c"], 34003)

    def test_boss_full_damage_unlocks_and_charges_exactly_one_attempt(self):
        self.strengthen()
        before = copy.deepcopy(self.session.save)
        packets = self.call(1341, [1])
        self.assertTrue(self.report(packets)["result"])
        self.assertEqual(self.rows()[2], [2, 1, 2, 1, 1])
        self.assertEqual(self.session.save["role_state"]["coin"] - before["role_state"]["coin"], 50000)
        saved = copy.deepcopy(self.session.save)
        self.assertEqual(self.call(1341, [1]), packets)
        self.assertEqual(self.session.save, saved)
        self.call(1341, [2], seq=182)
        self.assert_rejected(1341, recharge.ids([1]))

    def test_daily_limits_reset_only_forward_without_losing_unlocks(self):
        self.strengthen()
        self.call(1342, [1])
        self.call(1342, [2], seq=182)
        self.assert_rejected(1342, recharge.ids([1]))
        self.assertEqual(self.rows()[1], [1, 2, 3, 1, 2])
        self.clock.return_value = NOW + 86400
        self.session = self.reconnect()
        self.assertEqual(self.rows()[1], [1, 0, 3, 1, 2])
        self.call(1342, [3], seq=183)
        self.assertEqual(self.rows()[1], [1, 1, 3, 0, 3])
        self.session.save["role_state"]["level"] = 25
        self.assertEqual(self.rows()[1], [1, 1, 4, 1, 3])
        self.clock.return_value = NOW
        self.assertEqual(self.rows()[1], [1, 1, 4, 1, 3])
        self.assert_rejected(1342, recharge.ids([1]))

    def test_each_weekday_uses_configured_openings_and_saturday_double_rewards(self):
        baseline = copy.deepcopy(self.session.save)
        for offset in range(7):
            self.session.save = copy.deepcopy(baseline)
            self.clock.return_value = NOW + offset * 86400
            weekday = (6 + offset) % 7 + 1
            expected = {int(aid) for aid, row in self.config["daily_function"].items()
                        if str(weekday) in row["date"].strip(";").split(";")}
            self.assertEqual(set(self.rows()), expected)
            if 1 not in expected:
                self.assert_rejected(1342, recharge.ids([1]))
            if 5 not in expected:
                self.session.save["role_state"]["level"] = 150
                self.assert_rejected(1345, recharge.ids([1]))
        friday = (NOW + 28800) // 86400 - 2
        normal = activity_copy.reward(copy.deepcopy(baseline), 2, 1, 100, self.config, friday, 7)
        doubled = activity_copy.reward(copy.deepcopy(baseline), 2, 1, 100, self.config, friday + 1, 7)
        self.assertEqual(protocol.pb_get_varint(doubled, 1), protocol.pb_get_varint(normal, 1) * 2)
        normal = activity_copy.reward(copy.deepcopy(baseline), 1, 1, 100, self.config, friday, 7)
        doubled = activity_copy.reward(copy.deepcopy(baseline), 1, 1, 100, self.config, friday + 1, 7)
        normal_props = next(v for n, w, v in protocol.iter_pb_fields(normal) if n == 5)
        double_props = next(v for n, w, v in protocol.iter_pb_fields(doubled) if n == 5)
        self.assertEqual([protocol.pb_get_varint(v, 2) * 2 for _, _, v in protocol.iter_pb_fields(normal_props)],
                         [protocol.pb_get_varint(v, 2) for _, _, v in protocol.iter_pb_fields(double_props)])

    def test_invalid_locked_unsupported_and_comb_requests_are_atomic(self):
        for opcode in (1340, *activity_copy.BATTLES):
            for body in (b"\x08", b"\x10\x01", b"\x0a\x00", recharge.ids([0]), recharge.ids([1, 1]), recharge.ids([1 << 31])):
                with self.subTest(opcode=opcode, body=body.hex()):
                    self.assert_rejected(opcode, body)
        for opcode in activity_copy.BATTLES:
            for values in ([], [999], [3]):
                self.assert_rejected(opcode, recharge.ids(values))
        for opcode in (1343, 1344, 1345, 1347):
            self.assert_rejected(opcode, recharge.ids([1]))
        self.assert_rejected(1346, recharge.ids([1, 999]))
        self.assert_rejected(1348, recharge.ids([1, 1]))
        comb = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 1342) + protocol.encode_pb_field(2, 2, recharge.ids([1])))
        self.assert_rejected(999900, comb)
        self.session.save["role_state"]["level"] = 22
        self.assert_rejected(1340, b"")
        self.session.save["has_role"] = False
        self.assert_rejected(1341, recharge.ids([1]))

    def test_save_failure_overflow_and_bad_drops_do_not_publish_partial_results(self):
        self.strengthen()
        for opcode, values in ((1340, []), (1341, [1]), (1342, [1])):
            memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
            with self.subTest(opcode=opcode), patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
                self.call(opcode, values)
            self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))
            self.assertEqual(self.session.random_replies, {})
        self.session.save["role_state"]["coin"] = (1 << 63) - 1
        self.assert_rejected(1341, recharge.ids([1]))
        self.session.role_config = copy.deepcopy(self.config)
        for changes in ({"drop1prob1": -1}, {"drop1section2": 0}, {"drop1": 999999}, {"drop1": True}):
            self.session.role_config["exp_copy"]["1"] = {**self.config["exp_copy"]["1"], **changes}
            self.assert_rejected(1342, recharge.ids([1]))

    def test_corrupt_saved_counters_fail_closed_before_a_daily_reset(self):
        for changes in ({"used": -1}, {"used": 3}, {"used": True}, {"cleared": 99}, {"tried": 2}, {"cleared": 2}):
            saved = copy.deepcopy(self.baseline)
            state = activity_copy.get_state(saved, self.config)
            state["copies"]["1"].update(changes)
            self.path.write_text(json.dumps(saved))
            original = self.path.read_bytes()
            with self.subTest(changes=changes), self.assertRaisesRegex(ValueError, "活动副本"):
                self.reconnect()
            self.assertEqual(self.path.read_bytes(), original)

    def test_all_147_configured_rosters_and_every_reward_bracket_are_supported(self):
        original = copy.deepcopy(self.session.save)
        config = copy.deepcopy(self.config)
        count = 0
        for aid, (table, _, _, _) in activity_copy.COPIES.items():
            for difficulty in config[table]:
                with self.subTest(aid=aid, difficulty=difficulty):
                    attack, defense, combat_config = activity_copy.rosters(self.session.save, aid, difficulty, config)
                    inputs = copy.deepcopy((attack, defense))
                    report = battle.simulate(attack, defense, combat_config, 7, max_rounds=5 if aid in activity_copy.BOSSES else 30)
                    self.assertEqual((attack, defense), inputs)
                    self.assertEqual(report, battle.simulate(attack, defense, combat_config, 7, max_rounds=5 if aid in activity_copy.BOSSES else 30))
                    for percent in range(0, 101, 10) if aid in activity_copy.BOSSES else (100,):
                        raw = activity_copy.reward(copy.deepcopy(original), aid, difficulty, percent, config, (NOW + 28800) // 86400, 7)
                        player.apply_reward(copy.deepcopy(original), raw, config, NOW)
                    if aid not in activity_copy.BOSSES:
                        point = config[table][difficulty]
                        for i in range(1, 5):
                            if point[f"drop{i}"] and point[f"drop{i}prob1"]:
                                raw = activities.build_reward(copy.deepcopy(original), f'{point[f"drop{i}"]},{point[f"drop{i}section2"]}', config)
                                player.apply_reward(copy.deepcopy(original), raw, config, NOW)
                    count += 1
        self.assertEqual(count, 147)
        self.assertEqual(config, self.config)
        self.assertEqual(self.session.save, original)

    def test_round_limit_rejects_invalid_values_and_default_remains_thirty(self):
        attack, defense, config = activity_copy.rosters(self.session.save, 2, 1, self.config)
        for unit in attack.values():
            unit["atk"] = 1
        for value in (0, -1, 31, True, 1.5):
            with self.subTest(value=value), self.assertRaisesRegex(ValueError, "回合上限"):
                battle.simulate(attack, defense, config, 7, max_rounds=value)
        report = battle.simulate(attack, defense, config, 7)
        self.assertEqual(report["round"], 30)

    def test_boss_damage_brackets_round_down_instead_of_rounding_up(self):
        day = (NOW + 28800) // 86400
        for percent, expected in ((0, 20480), (49, 20480), (50, 25400), (99, 45080), (100, 50000)):
            raw = activity_copy.reward(self.session.save, 2, 1, percent, self.config, day, 7)
            self.assertEqual(protocol.pb_get_varint(raw, 1), expected)

    def network_lua(self, *, native_protobuf=False):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("实际APK回调验证需要本机已有lupa.lua51")
        lua = LuaRuntime(encoding=None, unpack_returned_tuples=True)
        lua.execute(b'''print=function() end; printT=print; cclog=print
            package.preload.protobuf=function() return {
                Descriptor=function() return {} end, FieldDescriptor=function() return {} end,
                Message=function(d) return setmetatable({}, {__call=function()
                    local m=decode_message(d, "")
                    m.ParseFromString=function(self,raw)
                        for k,v in pairs(decode_message(d,raw)) do self[k]=v end
                    end
                    m.SerializeToString=function(self) return encode_message(d,self) end
                    return m
                end}) end} end
            package.loaded["BattleReportConvertPbToTab.lua"]={}; package.loaded.myjson={}
            package.loaded.PickBattleResultReport={}
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            gamedata={cache={role={level=150}},ext={}}
            gamedata.SomethingProcess=function(self,p) return p end''')

        def decode_message(descriptor, raw):
            result, fields = lua.table(), {int(f[b"number"]): f for _, f in descriptor[b"fields"].items()}
            for field in fields.values():
                result[field[b"name"]] = lua.table() if field[b"label"] == 3 else field[b"default_value"]
            for number, wire, value in protocol.iter_pb_fields(raw):
                field = fields.get(number)
                if field is None:
                    continue
                if field[b"type"] == 11:
                    self.assertEqual(wire, 2)
                    value = decode_message(field[b"message_type"], value)
                elif field[b"type"] in (3, 5):
                    self.assertEqual(wire, 0)
                    value = value - (1 << 64) if value >= (1 << 63) else value
                elif field[b"type"] == 8:
                    value = bool(value)
                name = field[b"name"]
                if field[b"label"] == 3:
                    result[name][len(result[name]) + 1] = value
                else:
                    result[name] = value
            return result

        def encode_message(descriptor, message):
            output = bytearray()
            for _, field in descriptor[b"fields"].items():
                value = message[field[b"name"]]
                if field[b"label"] == 1 and value == field[b"default_value"]:
                    continue
                values = list(value.values()) if field[b"label"] == 3 else ([] if value is None else [value])
                for value in values:
                    wire = 2 if field[b"type"] in (9, 11, 12) else 0
                    if field[b"type"] == 11:
                        value = encode_message(field[b"message_type"], value)
                    output.extend(protocol.encode_pb_field(int(field[b"number"]), wire, int(value) & ((1 << 64) - 1) if wire == 0 else value))
            return bytes(output)

        def native(value):
            if isinstance(value, dict):
                return lua.table_from({native(k): native(v) for k, v in value.items()})
            return value.encode() if isinstance(value, str) else value

        lua.globals().decode_message = decode_message
        lua.globals().encode_message = encode_message
        lua.globals().gamedata[b"config"] = native(self.config)
        if native_protobuf:
            # 仅替代 Android C pb 原语；消息解析和未知字段跳过使用 APK 原件。
            def signed_varint(raw, pos):
                value, end = protocol.parse_varint(raw, pos)
                return value - (1 << 64) if value >= (1 << 63) else value, end

            def encode_varint(write, value):
                write(protocol.encode_varint(int(value) & ((1 << 64) - 1)))

            lua.globals().package[b"loaded"][b"pb"] = lua.table_from({
                b"varint_decoder": protocol.parse_varint, b"signed_varint_decoder": signed_varint,
                b"varint_encoder": encode_varint, b"signed_varint_encoder": encode_varint,
            })
            lua.execute(b'''local pb=require("pb")
                pb.read_tag=function(raw,pos)
                    assert(type(pos)=="number","ReadTag expects a number")
                    local _,endpos=pb.varint_decoder(raw,pos)
                    return raw:sub(pos+1,endpos),endpos
                end
                package.preload.protobuf=nil''')
            for name in ("descriptor", "type_checkers", "listener", "containers", "text_format",
                         "wire_format", "encoder", "decoder", "protobuf"):
                lua.execute(builder.read_script(name, "common_lua"))
        for name in ("ids_pb", "copies_pb", "copyattack_pb", "copyall3starreward_pb", "result_pb", "somethings_pb", "battleresult_pb"):
            lua.execute(builder.read_script(name, "pb"))
        lua.execute(builder.read_script("PickBattleResultReport"))
        code = builder.read_script("gamedata").decode().replace("\r\n", "\n")
        start = code.index("function gamedata.activityCopy(")
        lua.execute(code[start:code.index("function gamedata.friendcopyData(", start)].encode())
        lua.execute(builder.read_script("GameCopyActivity"))
        return lua

    def test_actual_apk_queries_and_six_battle_callbacks_accept_native_protobuf(self):
        lua = self.network_lua()
        self.assertIsNone(lua.globals().gameConfig)
        self.session.save["role_state"]["level"] = 150
        self.strengthen()
        lua.globals().NetActivityCopyCallback(lua.table_from({b"rbuf": self.call(1340)[0][16:]}))
        self.assertEqual(len(lua.globals().gamedata[b"cache"][b"copyActivity"]), 6)
        callbacks = {1: ("ExpDan", "NetActivityExpDanCopyCallback"), 2: ("Coin", "NetyActivityCoinCopyCallback"),
                     3: ("ForgeStone", "NetActivityForgeStoneCopyCallback"), 4: ("EquipStar", "NetActivityEquipStarCopyCallback"),
                     5: ("Zhenfu", "NetActivityZhenfuCopyCallback"), 6: ("Forging", "NetActivityForgingCopyCallback")}
        for aid, (name, receive) in callbacks.items():
            _, opcode, body = getattr(lua.globals(), "UIActivity" + name + "CopyCallback")(lua.table_from({b"id": 1}))
            self.assertEqual((opcode, body), (activity_copy.COPIES[aid][1], recharge.ids([1])))
            packets = self.session.handle(opcode, 180 + aid, body)
            result = getattr(lua.globals(), receive)(lua.table_from({b"rbuf": packets[0][16:]}))
            self.assertEqual(json.loads(result[b"battlereport"]), self.report(packets))
            self.assertEqual(result[b"result"], 1)
            row = next(v for _, v in result[b"data"].items() if v[b"aid"] == aid)
            self.assertEqual((row[b"usedTimes"], row[b"openLevel"], row[b"passLevel"]), (1, 2, 1))

    def test_packaged_ui_refreshes_entry_and_results_without_mutating_guide(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("实际APK界面回调验证需要本机已有lupa.lua51")
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute('''print=function() end;printT=print
            requests={};UIRequest=function(t) requests[#requests+1]=t.type end
            gameWindows={windows={activityCopySelect={show=false},copyacivity={show=false}},
                closeWindow=function(self,name) closed=name;self.windows[name].show=false end}
            local module={reloadactivityData=function(self,data) rows=data end}
            GameScene={layers={copy_chapter={show=true,module=module}},roleinfo={level=23}}
            ui={CheckHuodongByParam=function() return nil end}
            RunbattleCallBack=function(kind,t,callback) callback() end''')
        scripts = builder.patch_activity_copy_scripts()
        lua.execute(scripts["UICopyActivity"])
        layer = lua.execute(scripts["Layer_copy_chapter"])
        layer.setUIPosition = lambda *_: None
        layer.activitydata = lua.table()
        layer.shiftPage(layer, "activity", False)
        self.assertEqual(list(lua.globals().requests.values()), [1340])
        lua.execute('''gameWindows.windows.copyacivity={show=true,module={data={aid=2},
            activityReload=function(self,row) displayed=row.usedTimes end}}
            UIActivityCopy({data={{aid=2,usedTimes=0,openLevel=1}}})''')
        self.assertEqual(lua.globals().displayed, 0)
        lua.execute('UIActivityCopy({data={{aid=1}}})')
        self.assertEqual(lua.globals().closed, "copyacivity")
        lua.execute('''GameScene.layers.copy_chapter.show=false
            for _,name in ipairs({"Coin","ExpDan","ForgeStone","EquipStar","Zhenfu","Forging"}) do
                requests={}
                _G["UIActivity"..name.."Copy"]({data={},result=0})
                assert(requests[#requests]==1340)
            end''')

    def test_all_generated_reports_convert_with_actual_apk_animation_assets(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("实际动画转换需要本机已有lupa.lua51")
        with redirect_stdout(io.StringIO()):
            patched = builder.get_patched_lua_scripts()
        raw = builder.xxtea_decrypt(patched["assets/scripts/battleReportConvert.so"], builder.XXTEA_KEY)
        converter = raw[:struct.unpack("<I", raw[-4:])[0]].decode()
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
            lua.execute(converter)
            lua.execute(builder.read_script("BattleReportAbbToKey").decode())
            for aid, (table, _, _, _) in activity_copy.COPIES.items():
                for difficulty in config[table]:
                    attack, defense, combat_config = activity_copy.rosters(self.session.save, aid, difficulty, config)
                    report = battle.simulate(attack, defense, combat_config, 7, max_rounds=5 if aid in activity_copy.BOSSES else 30)
                    native = lua.table_from(json.loads(lua.globals().ReplaceAbbToKey(json.dumps(report))), recursive=True)
                    atk, enemy = lua.globals().getBattleInitSlotInfo(native)
                    animations, ext = lua.globals().convertBattleReportToAnimationSub(
                        native, atk, enemy, None, "activitycopyboss" if aid in activity_copy.BOSSES else "activitycopy")
                    self.assertGreater(len(animations), 1)
                    for side, key in (("attack", "atk"), ("defense", "def")):
                        for pos, unit in report["endmeta"][side].items():
                            self.assertEqual((ext.endinfo[key][pos].hp, ext.endinfo[key][pos].ap), (unit["h"], unit["ap"]))

    def test_stone_copy_purchase_vip_limits_and_challenge(self):
        self.session.save["role_state"].update(level=31, gold=100000, vip=0)
        self.strengthen()
        status = protocol.parse_ids_pb(self.session.handle(300, 100, b"")[0][16:])
        self.assertEqual(status[14], 0)
        before_gold = self.session.save["role_state"]["gold"]
        packets = self.session.handle(301, 101, recharge.ids([9, 1]))
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 301)
        self.assertEqual(protocol.pb_get_varint(packets[0][16:], 1), 1)
        self.assertEqual(self.session.save["role_state"]["gold"], before_gold - 50)
        self.assertEqual(self.session.save["activity_copy_state"]["copies"]["3"]["bought"], 1)

        status = protocol.parse_ids_pb(self.session.handle(300, 102, b"")[0][16:])
        self.assertEqual(status[14], 1)

        packets = self.session.handle(301, 103, recharge.ids([9, 1, 80]))
        self.assertEqual(protocol.pb_get_varint(packets[0][16:], 1), 1)
        self.assertEqual(self.session.save["role_state"]["gold"], before_gold - 50 - 80)
        self.assertEqual(self.session.save["activity_copy_state"]["copies"]["3"]["bought"], 2)

        self.assert_rejected(301, recharge.ids([9, 1]))

        self.session.save["role_state"]["vip"] = 27
        gold_before_5 = self.session.save["role_state"]["gold"]
        packets = self.session.handle(301, 104, recharge.ids([9, 5]))
        self.assertEqual(protocol.pb_get_varint(packets[0][16:], 1), 1)
        self.assertEqual(self.session.save["role_state"]["gold"], gold_before_5 - 1000)
        self.assertEqual(self.session.save["activity_copy_state"]["copies"]["3"]["bought"], 7)

        self.assert_rejected(301, recharge.ids([9, 1]))

        for i in range(1, 10):
            pkts = self.call(1343, [1], seq=200 + i)
            self.assertTrue(self.report(pkts)["result"])
            self.assertEqual(self.session.save["activity_copy_state"]["copies"]["3"]["used"], i)

        self.assert_rejected(1343, recharge.ids([1]))

        status = protocol.parse_ids_pb(self.session.handle(300, 300, b"")[0][16:])
        self.assertEqual(status[13], 9)
        self.assertEqual(status[14], 7)

        self.clock.return_value = NOW + 86400
        self.session = self.reconnect()
        self.rows()
        self.assertEqual(self.session.save["activity_copy_state"]["copies"]["3"]["used"], 0)
        self.assertEqual(self.session.save["activity_copy_state"]["copies"]["3"]["bought"], 0)

    def test_single_sweep_1346(self):
        # 初始状态等级升到 60 级以解锁更高难度
        self.session.save["role_state"]["level"] = 60
        before_stone = self.prop_count(self.session.save, 20270)
        # 对锻造石副本(aid=3)第 1 难度进行一键完成
        packets = self.session.handle(1346, 501, recharge.ids([3, 1]))
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 1346)
        # 验证次数使用增加 1，cleared 推进到 1
        self.assertEqual(self.session.save["activity_copy_state"]["copies"]["3"]["used"], 1)
        self.assertEqual(self.session.save["activity_copy_state"]["copies"]["3"]["cleared"], 1)
        # 验证背包中获得了锻造石
        after_stone = self.prop_count(self.session.save, 20270)
        self.assertGreater(after_stone, before_stone)

        # 挑战 Boss 银币副本(aid=2)第 1 难度一键完成
        before_coin = self.session.save["role_state"]["coin"]
        packets = self.session.handle(1346, 502, recharge.ids([2, 1]))
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 1346)
        self.assertEqual(self.session.save["activity_copy_state"]["copies"]["2"]["used"], 1)
        self.assertEqual(self.session.save["activity_copy_state"]["copies"]["2"]["cleared"], 1)
        self.assertEqual(self.session.save["role_state"]["coin"], before_coin + 50000)

        # 验证未解锁难度拒绝
        self.assert_rejected(1346, recharge.ids([3, 10]))
        # 验证参数错误拒绝
        self.assert_rejected(1346, recharge.ids([3]))
        self.assert_rejected(1346, recharge.ids([99, 1]))

        # 次数耗尽校验
        self.session.save["activity_copy_state"]["copies"]["3"]["used"] = 2
        self.assert_rejected(1346, recharge.ids([3, 1]))

    def test_batch_sweep_1348(self):
        self.session.save["role_state"]["level"] = 60
        # 先通关 aid=1(经验) 和 aid=3(锻造石) 第 1 难度
        self.session.save["activity_copy_state"]["copies"]["1"].update(cleared=1, tried=1)
        self.session.save["activity_copy_state"]["copies"]["3"].update(cleared=1, tried=1)

        before_exp_items = self.prop_count(self.session.save, 26407) + self.prop_count(self.session.save, 26410)
        before_stone = self.prop_count(self.session.save, 20270)

        # 批量扫荡：经验副本 1 次，锻造石副本 2 次
        packets = self.session.handle(1348, 601, recharge.ids([1, 1, 3, 2]))
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 1348)
        self.assertEqual(self.session.save["activity_copy_state"]["copies"]["1"]["used"], 1)
        self.assertEqual(self.session.save["activity_copy_state"]["copies"]["3"]["used"], 2)

        after_stone = self.prop_count(self.session.save, 20270)
        self.assertGreater(after_stone, before_stone)

        # 次数不足拒绝
        self.assert_rejected(1348, recharge.ids([3, 1]))
        # 未通关难度拒绝 (aid=4 cleared=0)
        self.assert_rejected(1348, recharge.ids([4, 1]))
        # 奇数参数拒绝
        self.assert_rejected(1348, recharge.ids([1, 1, 3]))


if __name__ == "__main__":
    unittest.main()
