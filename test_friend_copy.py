from contextlib import redirect_stdout
import copy
import io
import json
from pathlib import Path
import shutil
import struct
import tempfile
import unittest
from unittest.mock import patch
import zipfile

import build_local_apk as builder
from zyj_server import battle, formation, friend_copy, guide, player, protocol, recharge, replay
from zyj_server.session import Session


ROOT = Path(__file__).parent
NOW = 1800000000


class FriendCopyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.config = player.load_role_config(ROOT / "configs_sec5.zip")
        cls.steps = guide.load_guide_step_counts(ROOT / "configs_sec5.zip")
        frames = replay.load_recordings(ROOT / "recorded_frames.json")
        with redirect_stdout(io.StringIO()), tempfile.TemporaryDirectory() as directory, patch("time.time", return_value=NOW):
            cls.tables = replay.build_routing_tables(frames)
            session = Session(cls.tables, Path(directory) / "role_save.json", cls.steps, cls.config)
            for frame in replay.split_recordings(frames)[0]:
                if frame["c2s"] and frame["opcode"] != 1000:
                    session.handle(frame["opcode"], frame["seq"], bytes.fromhex(frame["hex"]))
            cls.baseline = copy.deepcopy(session.save)
        cls.baseline["role_state"].update(level=21, nextexp=cls.config["role_exp"]["21"]["nextexp"])
        cls.baseline["guide"]["sections"]["55"] = {"status": 1, "step": 1, "steps": [1]}

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

    def strengthen(self, *, weak=False):
        world = bytes.fromhex(self.session.save["world_state"]["1002"])
        for raw in formation.records(world, 1, 2).values():
            for field, value in ((6, 1 if weak else 1000000), (7, 0), (8, 1 if weak else 1000000), (9, 1 if weak else 1000)):
                raw = protocol.pb_set_varint(raw, field, value)
            player.record_slot_update(self.session.save, protocol.encode_pb_field(1, 2, raw))
        self.path.write_text(json.dumps(self.session.save))

    def report(self, packets):
        return json.loads(next(v for n, w, v in protocol.iter_pb_fields(packets[0][16:]) if (n, w) == (9, 2)))

    def prop_count(self, save, cid):
        props = formation.records(bytes.fromhex(save["world_state"]["1200"]), 1, 1)
        return protocol.pb_get_varint(props.get(cid, b""), 2) or 0

    def assert_rejected(self, opcode, body):
        memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        packets = self.session.handle(opcode, 200, body)
        self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets], [999999, 1999])
        self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))

    def test_query_resumes_section55_without_inventing_progress_or_rewards(self):
        before = copy.deepcopy(self.session.save)
        packets = self.call(1323)
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2:], (1323, 181))
        self.assertEqual(protocol.parse_ids_pb(packets[0][16:]), [3, 43001, (1 << 64) - 1])
        for key in ("guide", "world_state", "role_state", "protagonist_snapshot"):
            self.assertEqual(self.session.save[key], before[key])
        self.session = self.reconnect()
        self.assertEqual(self.call(1323)[0], packets[0])

    def test_query_includes_three_explicit_npcs_and_no_real_friend_relationships(self):
        raw = self.call(1323)[0][16:]
        helpers = next(v for n, w, v in protocol.iter_pb_fields(raw) if (n, w) == (2, 2))
        rows = formation.records(helpers, 1, 1)
        self.assertEqual(set(rows), set(friend_copy.HELPERS))
        for rid, row in rows.items():
            self.assertIn("本地NPC", next(v.decode() for n, w, v in protocol.iter_pb_fields(row) if n == 2))
            self.assertEqual(protocol.pb_get_varint(row, 4), friend_copy.HELPERS[rid])
            self.assertEqual(protocol.pb_get_varint(row, 7), 0)
        self.assertNotIn("friends", self.session.save)

    def test_real_victory_rewards_unlocks_and_reconnect_preserve_the_current_account(self):
        self.strengthen()
        before = copy.deepcopy(self.session.save)
        packets = self.call(1324, [43001, 990000001])
        report = self.report(packets)
        self.assertTrue(report["result"])
        attack, _ = battle.rosters(before, self.config["expedition2"]["43001"], self.config)
        self.assertEqual(len(report["meta"]["attack"]["g"]), len(attack) + 1)
        self.assertIn("本地NPC·哪吒", [v["n"] for v in report["meta"]["attack"]["g"].values()])
        self.assertEqual(self.session.save["role_state"]["coin"], before["role_state"]["coin"] + 1000)
        self.assertEqual(self.prop_count(self.session.save, 20256), self.prop_count(before, 20256) + 20)
        for key in ("guide", "protagonist_snapshot"):
            self.assertEqual(self.session.save[key], before[key])
        for key in ("1002", "1300"):
            self.assertEqual(self.session.save["world_state"][key], before["world_state"][key])
        for key in ("exp", "level", "stamina", "energy", "power"):
            self.assertEqual(self.session.save["role_state"][key], before["role_state"][key])
        saved = copy.deepcopy(self.session.save)
        self.assertEqual(self.call(1324, [43001, 990000001]), packets)
        self.assertEqual(self.session.save, saved)
        self.session = self.reconnect()
        self.assertEqual(protocol.parse_ids_pb(self.call(1323)[0][16:]), [2, 43001, 1, 43002, (1 << 64) - 1])
        self.assert_rejected(1324, recharge.ids([43001, 990000001]))
        self.call(1324, [43002, 990000002], seq=182)
        self.assertEqual(self.session.save["friend_copy_state"]["cleared"], 43002)

    def test_real_loss_spends_one_attempt_and_helper_but_grants_nothing(self):
        self.strengthen(weak=True)
        before = copy.deepcopy(self.session.save)
        packets = self.call(1324, [43001, 990000001])
        self.assertFalse(self.report(packets)["result"])
        self.assertEqual(self.session.save["friend_copy_state"], {"day": (NOW + 28800) // 86400,
                         "cleared": 43000, "attempts": 1, "wins": {}, "used": [990000001]})
        for key in ("guide", "world_state", "role_state", "protagonist_snapshot"):
            self.assertEqual(self.session.save[key], before[key])
        saved = copy.deepcopy(self.session.save)
        self.assertEqual(self.call(1324, [43001, 990000001]), packets)
        self.assertEqual(self.session.save, saved)
        self.assertEqual(protocol.parse_ids_pb(self.call(1323)[0][16:]), [2, 43001, (1 << 64) - 1])

    def test_daily_limits_only_reset_forward_and_keep_lifetime_unlocks(self):
        self.strengthen()
        for index, rid in enumerate(friend_copy.HELPERS):
            self.call(1324, [43001, rid], seq=181 + index)
        self.assertEqual(protocol.parse_ids_pb(self.call(1323)[0][16:])[0], 0)
        self.assert_rejected(1324, recharge.ids([43001, 990000001]))
        midnight = ((NOW + 28800) // 86400 + 1) * 86400 - 28800
        self.clock.return_value = midnight
        self.session = self.reconnect()
        self.assertEqual(protocol.parse_ids_pb(self.call(1323)[0][16:]), [3, 43001, 0, 43002, (1 << 64) - 1])
        self.call(1324, [43001, 990000001], seq=190)
        self.clock.return_value = midnight - 100
        self.assertEqual(protocol.parse_ids_pb(self.call(1323)[0][16:])[0], 2)
        self.assert_rejected(1324, recharge.ids([43001, 990000001]))

    def test_sweep_requires_unlock_and_level_or_vip_then_settles_exact_count(self):
        self.assert_rejected(1325, recharge.ids([43001, 1]))
        self.strengthen()
        self.call(1324, [43001, 990000001])
        self.assert_rejected(1325, recharge.ids([43001, 1]))
        self.session.save["role_state"]["vip"] = 5
        self.path.write_text(json.dumps(self.session.save))
        self.assert_rejected(1325, recharge.ids([43002, 1]))
        self.assert_rejected(1325, recharge.ids([43001, 3]))
        before = copy.deepcopy(self.session.save)
        packets = self.call(1325, [43001, 2])
        self.assertEqual(self.prop_count(self.session.save, 20256), self.prop_count(before, 20256) + 40)
        self.assertEqual(self.session.save["role_state"]["coin"], before["role_state"]["coin"] + 2000)
        self.assertEqual(self.session.save["last_friend_battle"], before["last_friend_battle"])
        self.assertEqual(self.session.save["friend_copy_state"]["attempts"], 3)
        saved = copy.deepcopy(self.session.save)
        self.assertEqual(self.call(1325, [43001, 2]), packets)
        self.assertEqual(self.session.save, saved)
        self.session = self.reconnect()
        self.assertEqual(protocol.parse_ids_pb(self.call(1323)[0][16:]), [0, 43001, 3, 43002, (1 << 64) - 1])
        self.session.save["role_state"].update(level=50, vip=0)
        self.clock.return_value = NOW + 86400
        self.assertEqual(struct.unpack(">IIII", self.call(1325, [43001, 1], seq=190)[0][:16])[2], 1325)

    def test_full_temporary_team_never_removes_protagonist_or_changes_saved_roster(self):
        self.strengthen()
        saved = self.session.save
        saved["role_state"]["level"] = 50
        world = bytes.fromhex(saved["world_state"]["1002"])
        raw = next(iter(formation.records(world, 1, 2).values()))
        protagonist = protocol.pb_get_varint(bytes.fromhex(saved["protagonist_snapshot"]), 1)
        for sid in range(1, 8):
            iid = 2100000 + sid if sid != 7 else protagonist
            general = protocol.pb_set_varint(raw, 2, iid)
            slot = protocol.encode_pb_field(1, 0, sid) + protocol.encode_pb_field(2, 0, iid)
            player.record_slot_update(saved, protocol.encode_pb_field(1, 2, general) + protocol.encode_pb_field(4, 2, slot))
        before = saved["world_state"]["1002"]
        report = self.report(self.call(1324, [43001, 990000002]))
        generals = report["meta"]["attack"]["g"]
        self.assertEqual(len(generals), 7)
        self.assertIn(str(protagonist), generals)
        self.assertIn("990000002", generals)
        self.assertEqual(saved["world_state"]["1002"], before)
        self.assertEqual(self.session.save["world_state"]["1002"], before)

    def test_invalid_parameters_and_unmatched_combs_leave_memory_and_disk_unchanged(self):
        for opcode in (1323, 1324, 1325):
            for body in (b"\x08", b"\x10\x01", b"\x0a\x00", recharge.ids([1]), recharge.ids([43001, 1, 1])):
                with self.subTest(opcode=opcode, body=body.hex()):
                    self.assert_rejected(opcode, body)
        for values in ([43001, 1], [43001, 0], [43002, 990000001], [43061, 990000001]):
            self.assert_rejected(1324, recharge.ids(values))
        message = protocol.encode_pb_field(1, 0, 1324) + protocol.encode_pb_field(2, 2, recharge.ids([43001, 990000001]))
        self.assert_rejected(999900, protocol.encode_pb_field(1, 2, message))
        self.session.save["role_state"]["level"] = 18
        self.assert_rejected(1323, b"")
        self.session.save["has_role"] = False
        self.assert_rejected(1324, recharge.ids([43001, 990000001]))

    def test_save_failure_and_reward_overflow_cannot_publish_half_a_transaction(self):
        self.strengthen()
        for opcode, values in ((1323, []), (1324, [43001, 990000001]), (1325, [43001, 2])):
            if opcode == 1325:
                self.session.save["role_state"]["vip"] = 5
                self.session.save["friend_copy_state"]["cleared"] = 43001
                self.path.write_text(json.dumps(self.session.save))
            memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
            with self.subTest(opcode=opcode), patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
                self.call(opcode, values)
            self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))
        self.session.save["role_state"]["coin"] = (1 << 63) - 1
        self.assert_rejected(1324, recharge.ids([43001, 990000001]))

    def test_corrupt_saved_counters_fail_closed_even_after_midnight(self):
        for changes in ({"attempts": -1}, {"attempts": 4}, {"cleared": 43061}, {"wins": {"43002": 1}},
                        {"used": [990000001]}, {"attempts": 2, "used": [990000001, 990000001]}):
            saved = copy.deepcopy(self.baseline)
            state = friend_copy.get_state(saved, self.config)
            state.update(changes)
            self.path.write_text(json.dumps(saved))
            original = self.path.read_bytes()
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.reconnect()
            self.assertEqual(self.path.read_bytes(), original)

    def test_only_actual_201_reports_advance_the_friend_dungeon_tutorial(self):
        self.call(1323)
        self.assertEqual(self.session.save["guide"]["sections"]["55"]["step"], 1)
        for step in (2, 3):
            self.session.handle(201, 181 + step, protocol.encode_pb_field(1, 0, 55) + protocol.encode_pb_field(2, 0, step))
        self.session = self.reconnect()
        self.assertEqual(self.session.save["guide"]["sections"]["55"], {"status": 2, "step": 3, "steps": [1, 2, 3]})

    def test_all_configured_enemy_rosters_and_positive_drop_types_are_supported(self):
        self.assertEqual(set(self.config["expedition2"]), set(self.config["expedition_map"]))
        self.assertEqual(len(self.config["expedition2"]), 60)
        original = copy.deepcopy(self.session.save)
        for mid, point in self.config["expedition2"].items():
            with self.subTest(map=mid):
                attack, defense = battle.rosters(self.session.save, point, self.config)
                attack[14] = friend_copy.helper(self.session.save, 990000001, self.config)
                report = battle.simulate(attack, defense, self.config, 7)
                self.assertIsInstance(report["result"], bool)
                row = self.config["expedition_map"][mid]
                prizes = ";".join(f"{row[f'drop{i}']},{row[f'number{i}']}" for i in range(1, 7)
                                  if row[f"drop{i}"] and row[f"drop{i}prob"] > 0)
                reward = friend_copy.activities.build_reward(copy.deepcopy(original), prizes, self.config)
                player.apply_reward(copy.deepcopy(original), reward, self.config, NOW)
        self.assertEqual(self.session.save, original)

    def network_lua(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("实际APK回调验证需要本机已有lupa.lua51")
        lua = LuaRuntime(encoding=None, unpack_returned_tuples=True)
        lua.execute(b'''print=function() end; printT=print
            friendCopyLogs={}
            cclog=function(fmt,...) table.insert(friendCopyLogs,string.format(fmt,...)) end
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
            package.loaded.PickBattleResultReport={}
            table.copy=function(t) local r={} for k,v in pairs(t) do
                r[k]=type(v)=="table" and table.copy(v) or v end return r end
            gamedata={cache={friendcopy={},friends={friends={[123]={use=0}}}},ext={}}
            gamedata.sortData=function(t) table.sort(t,function(a,b) return a.rid<b.rid end) end
            gamedata.SomethingProcess=function(self,p) return p end''')

        # 执行真实PB描述符/业务回调；仅把原生pb编解码桥接到标准库实现。
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
                    if wire == 0:
                        value = int(value) & ((1 << 64) - 1)
                    output.extend(protocol.encode_pb_field(int(field[b"number"]), wire, value))
            return bytes(output)

        lua.globals().decode_message = decode_message
        lua.globals().encode_message = encode_message
        patched = builder.patch_friend_copy_scripts()
        lua.execute(patched["localfriendcopy_pb"].encode())
        for name in ("ids_pb", "friends_pb", "combmessages_pb", "somethings_pb", "battleresult_pb"):
            lua.execute(builder.read_script(name, "pb"))
        code = builder.read_script("gamedata").decode().replace("\r\n", "\n")
        start = code.index("function  gamedata.FriendCopies(")
        lua.execute(code[start:code.index("function gamedata.propData(", start)].encode())
        lua.execute(patched["GameFriendCopy"].encode())
        return lua

    def test_packaged_callbacks_open_npc_selection_and_keep_the_real_friend_cache_separate(self):
        lua = self.network_lua()
        self.assertIsNone(lua.globals().gameConfig)
        response = self.call(1323)[0][16:]
        query = lua.globals().NetFriendCopyQueryCallback(lua.table_from({b"rbuf": response}))
        self.assertEqual(query[b"friendcopy"][b"kill"], 3)
        self.assertEqual(len(query[b"friendcopy"][b"maps"]), 1)
        self.assertIn(b"[LocalFriendCopy] net ready attempts=3 maps=1 helpers=3",
                      list(lua.globals().friendCopyLogs.values()))
        _, opcode, selection = lua.globals().UIFriendCopyFriendSelectCallBack(lua.table())
        self.assertEqual(opcode, 13201)
        self.assertEqual(len(selection[b"data"]), 3)
        self.assertEqual(selection[b"data"][1][b"use"], 1)
        self.assertIn(b"NPC", selection[b"data"][1][b"name"])
        self.assertIsNone(selection[b"data"][1][b"title"])
        self.assertIsNone(selection[b"data"][1][b"iconBox"])
        self.strengthen()
        _, opcode, body = lua.globals().UIFriendCopyAttackCallback(lua.table_from({b"map": 43001, b"help": 990000001}))
        self.assertEqual((opcode, body), (1324, recharge.ids([43001, 990000001])))
        packets = self.session.handle(opcode, 182, body)
        result = lua.globals().NetFriendCopyAttackCallback(lua.table_from({b"rbuf": packets[0][16:]}))
        self.assertTrue(result[b"result"])
        self.assertEqual(json.loads(result[b"battlereport1"]), self.report(packets))
        self.assertEqual(result[b"battlereport2"], b"")
        self.assertEqual(lua.globals().gamedata[b"cache"][b"friends"][b"friends"][123][b"use"], 0)
        query = lua.globals().NetFriendCopyQueryCallback(lua.table_from({b"rbuf": self.call(1323)[0][16:]}))
        _, _, selection = lua.globals().UIFriendCopyFriendSelectCallBack(lua.table())
        self.assertEqual(selection[b"data"][1][b"use"], 0)
        self.assertEqual(selection[b"data"][2][b"use"], 1)

        from lupa.lua51 import LuaRuntime
        ui = LuaRuntime(encoding=None)
        ui.execute(b'''print=function() end;printT=print
            uiLogs={};cclog=function(fmt,...) table.insert(uiLogs,string.format(fmt,...)) end
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            ui={setLabelString=function(node,value) displayedAttempts=value end}
            GameScene={layers={friendcopy={show=true}}}
            gameWindows={openWindow=function(self,name,data) opened={name=name,data=data} end}
            runGamePrompt=function() error("NPC selection must not be empty") end''')
        patched = builder.patch_friend_copy_scripts()
        ui.execute(patched["UIFriendCopy"].encode())
        layer = ui.execute(patched["Layer_friendcopy2"].encode())
        layer[b"rootItems"] = ui.table_from({b"rest": ui.table()})
        ui.globals().GameScene[b"layers"][b"friendcopy"][b"module"] = layer
        ui.execute(b'''GameScene.layers.friendcopy.module.creatList=function(self) createdMaps=self.copydata.maps end''')
        # UI/net是真实的独立Lua状态，队列传输把数组键转成字符串。
        def transfer(value):
            if hasattr(value, "items"):
                return ui.table_from({str(k).encode() if isinstance(k, int) else k: transfer(v) for k, v in value.items()})
            return value
        ui.globals().UIFriendCopyQuery(transfer(query))
        self.assertEqual(ui.globals().displayedAttempts, 2)
        self.assertEqual(len(list(ui.globals().createdMaps.values())), 2)
        self.assertIn(b"[LocalFriendCopy] ui recv shown=true attempts=2 maps=2", list(ui.globals().uiLogs.values()))
        self.assertIn(b"[LocalFriendCopy] render attempts=2 maps=2 existingView=false", list(ui.globals().uiLogs.values()))
        ui.globals().UIFriendCopyFriendSelect(transfer(selection))
        self.assertEqual(ui.globals().opened[b"name"], b"friendcopy")
        self.assertEqual(ui.globals().opened[b"data"][b"type"], b"select")

    def test_generated_friend_reports_convert_with_actual_apk_animation_assets(self):
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
            for mid, point in config["expedition2"].items():
                attack, defense = battle.rosters(self.session.save, point, config)
                rid = list(friend_copy.HELPERS)[(int(mid) - 43001) % 3]
                attack[14] = friend_copy.helper(self.session.save, rid, config)
                report = battle.simulate(attack, defense, config, 7)
                native = lua.table_from(json.loads(lua.globals().ReplaceAbbToKey(json.dumps(report))), recursive=True)
                atk, enemy = lua.globals().getBattleInitSlotInfo(native)
                animations, ext = lua.globals().convertBattleReportToAnimationSub(native, atk, enemy, None, "friendcopy")
                self.assertGreater(len(animations), 1)
                for side, key in (("attack", "atk"), ("defense", "def")):
                    for pos, unit in report["endmeta"][side].items():
                        self.assertEqual(ext.endinfo[key][pos].hp, unit["h"], mid)
                        self.assertEqual(ext.endinfo[key][pos].ap, unit["ap"], mid)

    def test_packager_includes_the_new_query_module_once_without_changing_global_ids(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "configs_sec5.zip").symlink_to(ROOT / "configs_sec5.zip")
            with zipfile.ZipFile(root / "z7_7_4.apk", "w") as archive:
                archive.writestr("assets/GameServer.json", '{"1":{"id":1}}')
                archive.writestr("assets/pb/ids_pb.so", b"original ids")
            name = "assets/scripts/localfriendcopy_pb.so"
            def tool(executable, args):
                if executable == "zipalign":
                    shutil.copyfile(args[-2], args[-1])
            with patch.object(builder, "__file__", str(root / "build_local_apk.py")), \
                    patch.object(builder, "get_patched_lua_scripts", return_value={name: b"new local module"}), \
                    patch.object(builder, "find_tool", side_effect=lambda name: name), \
                    patch.object(builder, "run_tool", side_effect=tool), patch.object(builder.subprocess, "run"):
                builder.main(["--server-ip", "10.66.0.12"])
            with zipfile.ZipFile(root / "zyj_local.apk") as archive:
                self.assertEqual(archive.namelist().count(name), 1)
                self.assertEqual(archive.read(name), b"new local module")
                self.assertEqual(archive.read("assets/pb/ids_pb.so"), b"original ids")


if __name__ == "__main__":
    unittest.main()
