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
import test_activity_copy as activity_tests
import test_hades_battle as battle_tests
from zyj_server import activities, battle, formation, hades_copy, player, protocol, recharge
from zyj_server.session import Session


NOW = 1800172800


class HadesCopyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        activity_tests.ActivityCopyTests.setUpClass.__func__(cls)
        cls.baseline["role_state"].update(level=60, nextexp=cls.config["role_exp"]["60"]["nextexp"])
        copies = []
        for mid in cls.config["hades_map"]:
            points = b"".join(protocol.encode_pb_field(7, 2, protocol.encode_pb_field(1, 0, int(pid)) + protocol.encode_pb_field(3, 0, 3))
                              for pid in cls.config["copy"][mid])
            copies.append(protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, int(mid)) + points))
        cls.baseline["world_state"]["1300"] = b"".join(copies).hex()

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

    call = activity_tests.ActivityCopyTests.call
    report = activity_tests.ActivityCopyTests.report
    strengthen = activity_tests.ActivityCopyTests.strengthen
    prop_count = activity_tests.ActivityCopyTests.prop_count
    assert_rejected = activity_tests.ActivityCopyTests.assert_rejected

    def rows(self):
        packets = self.call(1370)
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 1370)
        result = {}
        for _, _, raw in protocol.iter_pb_fields(packets[0][16:]):
            values = {n: v for n, _, v in protocol.iter_pb_fields(raw)}
            result[values[1]] = [v - (1 << 64) if v >= (1 << 63) else v for v in protocol.parse_ids_pb(values[2])]
        return result

    def test_query_full_catalog_has_one_current_point_and_no_free_progress(self):
        before = copy.deepcopy(self.session.save)
        rows = self.rows()
        self.assertEqual(len(rows), 46)
        self.assertEqual(rows[0], [0])
        self.assertEqual(rows[42101], [42101, 0, 0, 1, -1, 0])
        self.assertTrue(all(rows[int(mid)] == [int(mid), -1, 0] for mid in self.config["hades_map"] if mid != "42101"))
        for key in ("role_state", "world_state", "guide", "protagonist_snapshot"):
            self.assertEqual(self.session.save[key], before[key])
        self.session = self.reconnect()
        self.assertEqual(self.rows(), rows)

    def test_victory_loss_daily_limit_and_permanent_box_survive_reconnect(self):
        self.strengthen(weak=True)
        before = copy.deepcopy(self.session.save)
        self.assertFalse(self.report(self.call(1371, [42101, 1]))["result"])
        self.assertEqual(self.rows()[0], [0])
        for key in ("role_state", "world_state", "guide", "protagonist_snapshot"):
            self.assertEqual(self.session.save[key], before[key])
        self.strengthen()
        for pid in range(1, 6):
            if pid == 4:
                self.assert_rejected(1371, recharge.ids([42101, pid]))
                self.clock.return_value += 86400
                self.session = self.reconnect()
                self.rows()
            before = copy.deepcopy(self.session.save)
            packets = self.call(1371, [42101, pid], seq=200 + pid)
            report = self.report(packets)
            self.assertTrue(report["result"])
            saved = copy.deepcopy(self.session.save)
            self.assertEqual(self.call(1371, [42101, pid], seq=200 + pid), packets)
            self.assertEqual(self.session.save, saved)
            expected = activities.build_reward(copy.deepcopy(before), self.config["hades_copy"]["42101"][str(pid)]["reward"], self.config)
            field4 = next(v for n, w, v in protocol.iter_pb_fields(packets[0][16:]) if (n, w) == (4, 2))
            self.assertEqual(field4, expected)
            self.assertEqual(self.session.save["world_state"]["1300"], before["world_state"]["1300"])
            for key in ("exp", "level", "stamina", "energy", "power", "gold", "coin"):
                self.assertEqual(self.session.save["role_state"][key], before["role_state"][key])
        self.assertEqual(self.rows()[42101][:3], [42101, 1, 1])
        self.assertEqual(self.rows()[42102], [42102, 0, 0, 1, -1, 0])
        before = self.prop_count(self.session.save, 20680)
        self.call(1372, [42101])
        self.assertEqual(self.prop_count(self.session.save, 20680), before + 1)
        self.session = self.reconnect()
        self.assertEqual(self.rows()[42101][:3], [42101, 1, 2])
        self.assert_rejected(1372, recharge.ids([42101]))
        self.assert_rejected(1371, recharge.ids([42101, 1]))
        self.clock.return_value = NOW
        self.assertEqual(self.rows()[0], [2])
        self.assert_rejected(1371, recharge.ids([42102, 1]))

    def test_invalid_locked_stale_and_comb_requests_change_nothing(self):
        for opcode in hades_copy.OPCODES:
            for body in (b"\x08", b"\x10\x01", b"\x0a\x00", recharge.ids([0]), recharge.ids([1 << 31]), recharge.ids([42101, 1, 1])):
                self.assert_rejected(opcode, body)
        for values in ([], [42101], [42101, 2], [42102, 1], [99999, 1], [42101, 6]):
            self.assert_rejected(1371, recharge.ids(values))
        self.assert_rejected(1372, recharge.ids([42101]))
        self.session.save["world_state"]["1300"] = ""
        self.assert_rejected(1371, recharge.ids([42101, 1]))
        self.session.save["role_state"]["level"] = 59
        self.assert_rejected(1370, b"")
        comb = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 1371) + protocol.encode_pb_field(2, 2, recharge.ids([42101, 1])))
        self.assert_rejected(999900, comb)

    def test_save_failure_overflow_and_corrupt_state_are_atomic(self):
        self.strengthen()
        for opcode, values in ((1370, []), (1371, [42101, 1]), (1372, [42101])):
            if opcode == 1372:
                self.session.save["hades_copy_state"] = {"day": 0, "used": 0, "cleared": 5, "claimed": [], "checked_at": 0}
            before, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
            with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
                self.call(opcode, values)
            self.assertEqual((self.session.save, self.path.read_bytes()), (before, disk))
        self.session.save.pop("hades_copy_state")
        player.change_item_count(self.session.save, 120201, (1 << 31) - 1 - self.prop_count(self.session.save, 120201), self.config, NOW)
        self.assert_rejected(1371, recharge.ids([42101, 1]))
        for key, value in (("cleared", 226), ("cleared", True), ("used", 4), ("used", 1), ("claimed", [42101]), ("checked_at", -1), ("day", None)):
            saved = copy.deepcopy(self.baseline)
            state = hades_copy.get_state(saved, self.config)
            state[key] = value
            saved["hades_copy_state"] = state
            self.path.write_text(json.dumps(saved))
            before = self.path.read_bytes()
            with self.subTest(key=key, value=value), self.assertRaisesRegex(ValueError, "地狱副本"):
                self.reconnect()
            self.assertEqual(self.path.read_bytes(), before)

    def test_complete_225_fights_over_75_days_and_45_boxes_use_real_settlement(self):
        world = bytes.fromhex(self.session.save["world_state"]["1002"])
        active = sorted(iid for iid in formation.records(world, 4, 2) if iid)
        generals = formation.records(world, 1, 2)
        for index, iid in enumerate(active):
            raw = generals[iid]
            for field, value in ((6, 1000000000), (7, 2000000000), (8, 2000000000), (9, 10000)):
                raw = protocol.pb_set_varint(raw, field, value)
            if index in (1, 2):
                raw = protocol.pb_set_varint(protocol.pb_set_varint(raw, 1, 10839 if index == 1 else 10828), 4, 10)
            player.record_slot_update(self.session.save, protocol.encode_pb_field(1, 2, raw))
        self.path.write_text(json.dumps(self.session.save))
        for ordinal in range(225):
            self.clock.return_value = NOW + ordinal // 3 * 86400
            mid, pid = 42101 + ordinal // 5, ordinal % 5 + 1
            with patch.object(player.random, "getrandbits", return_value=7):
                packets = self.call(1371, [mid, pid], seq=1000 + ordinal)
                self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 1371, (mid, pid))
                report = self.report(packets)
                self.assertTrue(report["result"], (mid, pid, report["endmeta"]))
                if pid == 5:
                    self.call(1372, [mid], seq=2000 + ordinal)
        self.session = self.reconnect()
        state = self.session.save["hades_copy_state"]
        self.assertEqual((state["cleared"], state["used"], len(state["claimed"])), (225, 3, 45))
        self.assertTrue(all(row[1:3] == [1, 2] for mid, row in self.rows().items() if mid))
        self.assert_rejected(1371, recharge.ids([42145, 5]))
        self.assert_rejected(1372, recharge.ids([42145]))

    def test_corresponding_ordinary_map_is_required_even_after_previous_hades_clear(self):
        self.session.save["hades_copy_state"] = {"day": 0, "used": 0, "cleared": 5, "claimed": [], "checked_at": 0}
        raw = bytes.fromhex(self.session.save["world_state"]["1300"])
        self.session.save["world_state"]["1300"] = b"".join(protocol.encode_pb_field(n, w, value) for n, w, value in protocol.iter_pb_fields(raw)
                                                           if (n, w) != (1, 2) or protocol.pb_get_varint(value, 1) != 42102).hex()
        self.assertEqual(self.rows()[42102], [42102, -1, 0])
        self.assert_rejected(1371, recharge.ids([42102, 1]))

    def test_all_225_actual_rosters_and_all_rewards_are_supported_without_mutating_inputs(self):
        before = copy.deepcopy(self.session.save)
        count = 0
        for mid, points in self.config["hades_copy"].items():
            for pid, point in points.items():
                with self.subTest(map=mid, point=pid):
                    attack, defense = battle.rosters(self.session.save, {**point, "level": point["monster_level"]}, self.config)
                    original = copy.deepcopy((attack, defense))
                    report = battle.simulate(attack, defense, self.config, 7)
                    self.assertEqual(report, battle.simulate(attack, defense, self.config, 7))
                    self.assertEqual((attack, defense), original)
                    reward = activities.build_reward(copy.deepcopy(before), point["reward"], self.config)
                    player.apply_reward(copy.deepcopy(before), reward, self.config, NOW)
                    count += 1
            reward = activities.build_reward(copy.deepcopy(before), self.config["hades_map"][mid]["reward"], self.config)
            player.apply_reward(copy.deepcopy(before), reward, self.config, NOW)
        self.assertEqual(count, 225)
        self.assertEqual(self.session.save, before)

    def patched_script(self, name):
        if not hasattr(type(self), "patched"):
            type(self).patched = builder.get_patched_lua_scripts()
        raw = builder.xxtea_decrypt(self.patched["assets/scripts/" + name + ".so"], builder.XXTEA_KEY)
        return raw[:struct.unpack("<I", raw[-4:])[0]]

    def test_actual_apk_protocol_full_cache_fifo_mutual_lock_and_reward_once(self):
        lua = activity_tests.ActivityCopyTests.network_lua(self, native_protobuf=True)
        lua.execute(builder.read_script("combmessages_pb", "pb"))
        code = builder.read_script("gamedata").decode().replace("\r\n", "\n")
        start = code.index("function gamedata.HadesCopyMapData(")
        lua.execute(code[start:code.index("\nend", start) + 4].encode())
        lua.execute(self.patched_script("GameCopyStar"))
        lua.execute(b'''gamedata.cache.hadescopy={sections={['99']={}}};gamedata.cache.role.power=10000000
            applied=0;gamedata.SomethingProcess=function(self,p) applied=applied+1;return p end''')
        send, receive = lua.globals().UIHadesCopyQueryCallback, lua.globals().NetHadesCopyQueryCallback
        for view in (11, 22):
            self.assertEqual(send(lua.table_from({b"hadesView": view}))[0], 1)
        body = self.call(1370)[0][16:]
        result = receive(lua.table_from({b"rbuf": body, b"ser": 0}))
        self.assertTrue(result[b"localHadesIgnored"])
        self.assertEqual(receive(lua.table_from({b"rbuf": body, b"ser": 1}))[b"hadesView"], 11)
        self.assertEqual(receive(lua.table_from({b"rbuf": body, b"ser": 2}))[b"hadesView"], 22)
        self.assertIsNone(lua.globals().gamedata[b"cache"][b"hadescopy"][b"sections"][b"99"])
        self.assertIsNone(lua.globals().gameConfig)
        self.strengthen()
        mode, opcode, body = lua.globals().UIHadesCopyAttackCallback(lua.table_from({b"mapid": 42101, b"pointid": 1, b"hadesView": 33}))
        self.assertEqual((mode, opcode, body), (1, 1371, recharge.ids([42101, 1])))
        self.assertEqual(lua.globals().UIHadesCopyGetBoxCallback(lua.table_from({b"mapid": 42101}))[0], 0)
        self.assertEqual(lua.globals().UIActivityCoinCopyCallback(lua.table_from({b"id": 1}))[0], 0)
        lua.globals().LocalHadesError(1372)
        self.assertEqual(lua.globals().gamedata[b"ext"][b"localHadesBusy"], 1371)
        packet = self.session.handle(1371, 203, body)[0][16:]
        self.assertTrue(lua.globals().NetHadesCopyAttackCallback(lua.table_from({b"ser": 0}))[b"localHadesIgnored"])
        result = lua.globals().NetHadesCopyAttackCallback(lua.table_from({b"ser": 3, b"rbuf": packet}))
        self.assertEqual((result[b"result"], result[b"hadesView"]), (1, 33))
        self.assertEqual(json.loads(result[b"battlereport"]), self.report([protocol.pack_frame(1371, 203, packet)]))
        self.assertEqual(lua.globals().applied, 1)
        self.assertTrue(lua.globals().NetHadesCopyAttackCallback(lua.table_from({b"ser": 3, b"rbuf": packet}))[b"localHadesIgnored"])
        self.assertEqual(lua.globals().applied, 1)
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localAutoCopyBusy"])
        lua.globals().UIHadesCopyAttackCallback(lua.table_from({b"mapid": 42101, b"pointid": 2}))
        lua.globals().LocalHadesError(1371)
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localHadesBusy"])

    def test_packaged_ui_refreshes_both_pages_and_discards_old_generations(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("实际APK界面回调验证需要lupa.lua51")
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute('''print=function() end;printT=print
            table.copy=function(t) local n={} for k,v in pairs(t) do n[k]=v end return n end
            requests={};UIRequest=function(t) requests[#requests+1]=t end
            local page={rootNode={},localHadesGeneration=1}
            GameScene={layers={hadescopy_map={show=true,module=page},copy_chapter={show=false,module={}}},
                checkopenlevelbyId=function() return true end}
            RunbattleCallBack=function(kind,t,cb) battleKind=kind;cb() end
            runGamePrompt=function() end
            showRewardPopupWindow=function(r,_,cb) popups=(popups or 0)+1;if cb then cb() end end''')
        lua.execute(self.patched_script("UICopyStar").decode())
        lua.execute('''local view=LocalHadesContext()
            UIHadesCopyAttack({hadesView=view,result=1,skip=1,reward={}})
            assert(#requests==1 and requests[1].type==1370 and requests[1].hadesView.name=='hadescopy_map')
            requests={};UIHadesCopyAttack({hadesView=view,result=0,skip=0,reward={}})
            assert(battleKind=='copyhades' and #requests==1 and requests[1].type==1370)
            requests={};GameScene.layers.hadescopy_map.module.localHadesGeneration=2
            UIHadesCopyAttack({hadesView=view,result=1,skip=0,reward={}})
            UIHadesCopyGetBox({hadesView=view,reward={1}})
            assert(#requests==0 and not popups)
            view=LocalHadesContext();UIHadesCopyGetBox({hadesView=view,reward={1}})
            assert(#requests==1 and requests[1].type==1370 and popups==1)
            GameScene.layers.hadescopy_map.show=false
            GameScene.layers.copy_chapter={show=true,module={rootNode={},localHadesGeneration=3,selectpage='hades',
                hadesCopyBattleCallback=function(self,t) completed=t.result end}}
            UIHadesCopyAttack({hadesView=LocalHadesContext(),result=0,skip=0,reward={}})
            assert(completed==0)''')
        layer = lua.execute(self.patched_script("Layer_copy_chapter").decode())
        lua.globals().chapter = layer
        lua.execute('''requests={};gamedata={config={hades_copy={},hades_map={}}}
            chapter.rootNode={};chapter.localHadesGeneration=4;chapter.selectpage='hades'
            GameScene.layers.copy_chapter.module=chapter
            chapter.hadesCCB={generalItems={tempNode={removeAllChildrenWithCleanup=function() end}}}
            chapter.hadesGenerals={}
            chapter.bgAnimationManager={setAnimationCompletedCallback=function(self,f) delayed=f end,
                runAnimationsForSequenceNamed=function() end}
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            chapter:hadesCopyBattleCallback({hadesView=LocalHadesContext(),params={mapid=42101,pointid=1},result=1})
            chapter.localHadesGeneration=5;delayed();assert(#requests==0)''')
        window = lua.execute(self.patched_script("window_copy_hadesInfo").decode())
        lua.globals().window = window
        lua.execute('''CCDelayTime={create=function() return {} end};CCCallFunc={create=function(self,f) return f end}
            CCSequence={createWithTwoActions=function(self,delay,callback) return callback end}
            window.localHadesGeneration=1;window.rootNode={};window.rootItems={generalNode={runAction=function(self,f) closeLater=f end}}
            gameWindows={closeWindowDirect=function() closed=true end}
            window:closedelay();window.localHadesGeneration=2;closeLater();assert(not closed)''')

    def test_all_patched_lua_compiles_and_general_copy_callbacks_remain_unchanged(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("Lua5.1校验需要lupa")
        lua = LuaRuntime(unpack_returned_tuples=True)
        for name in ("GameCopyStar", "UICopyStar", "Layer_copy_chapter", "Layer_copy_hades_map", "window_copy_hadesInfo", "window_hades_all_reward", "battleSkillModules", "battleScene", "battlegeneral"):
            fn, error = lua.eval('function(s) local f,e=loadstring(s);return f,e end')(self.patched_script(name).decode())
            self.assertIsNotNone(fn, (name, error))
        original = builder.read_script("UICopyStar").replace(b"\r\n", b"\n").split(b"--hades\n")[0]
        self.assertIn(original, self.patched_script("UICopyStar"))

    def test_native_revival_passes_scalar_zero_and_leaves_hp_to_existing_damage_rows(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("Lua5.1校验需要lupa")
        lua = LuaRuntime()
        lua.execute(self.patched_script("battleSkillModules").decode())
        lua.execute('''calls=0;scene={atk={general={['2']={reborn=function(self,t)
            assert(t.damage==0);calls=calls+1 end}}}}
            action={destAnimation={{postype='atk',pos='2',animation={damage={{damage=-100},{damage=-100}}}},
                {postype='atk',pos='2',animation={damage={{damage=0}}}},
                {postype='atk',pos='2',animation={damage={{damage=100}}}}}}
            for _,name in ipairs({'jiusi','wangtuijiangqi','huanhua','zhuzhenyi'}) do _G[name](scene,action) end
            assert(calls==4)''')
        self.assertIn(b"jiusi = jiusi,", self.patched_script("battleScene"))

    def test_all_225_balanced_rosters_replay_and_convert_with_actual_apk_animation_assets(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("实际APK动画验证需要lupa.lua51")
        patched = builder.get_patched_lua_scripts()
        raw = builder.xxtea_decrypt(patched["assets/scripts/battleReportConvert.so"], builder.XXTEA_KEY)
        converter = raw[:struct.unpack("<I", raw[-4:])[0]].decode()
        lua = LuaRuntime()
        config = dict(self.config)
        with zipfile.ZipFile(Path(__file__).with_name("configs_sec5.zip")) as archive:
            for name in ("generalanimation", "skillanimation"):
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
            revivals = ("yuhuochongsheng", "jiusi", "wangtuijiangqi", "huanhua", "zhuzhenyi")
            lua.execute(self.patched_script("battleSkillModules").decode())
            lua.execute('''reborns=0;scene={atk={general={}},def={general={}}}
                for _,side in ipairs({'atk','def'}) do for _,pos in ipairs({2,4,6,8,10,12,14}) do
                    scene[side].general[tostring(pos)]={ccbeffectwithoutddelay=function() end,
                        reborn=function(self,t) assert(type(t.damage)=='number' and t.damage<=0);reborns=reborns+1 end}
                end end''')
            for mid, points in self.config["hades_copy"].items():
                for pid, point in points.items():
                    with self.subTest(map=mid, point=pid):
                        _, defense = battle.rosters(self.session.save, {**point, "level": point["monster_level"]}, self.config)
                        attack = copy.deepcopy(defense)
                        for unit in attack.values():
                            unit["iid"] += 10000000
                        inputs = copy.deepcopy((attack, defense))
                        report = battle.simulate(attack, defense, self.config, 11)
                        self.assertEqual((attack, defense), inputs)
                        battle_tests.HadesBattleTests.assert_replays(self, report)
                        native = lua.table_from(json.loads(lua.globals().ReplaceAbbToKey(json.dumps(report))), recursive=True)
                        atk, enemy = lua.globals().getBattleInitSlotInfo(native)
                        animations, ext = lua.globals().convertBattleReportToAnimationSub(native, atk, enemy, None, "copyhades")
                        self.assertGreater(len(animations), 1)
                        for _, action in animations.items():
                            module = action.sourceccbmodule
                            if not module or module.name not in revivals:
                                module = action.destccbmodule
                            if module and module.name in revivals:
                                lua.globals()[module.name](lua.globals().scene, action)
                        for side, key in (("attack", "atk"), ("defense", "def")):
                            for pos, unit in report["endmeta"][side].items():
                                self.assertEqual((ext.endinfo[key][pos].hp, ext.endinfo[key][pos].ap), (unit["h"], unit["ap"]))
            self.assertGreater(lua.globals().reborns, 0)


if __name__ == "__main__":
    unittest.main()
