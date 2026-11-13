"""福祉天宫：原生协议、真实战斗、奖励、次数与原子保存。"""

import copy
from contextlib import redirect_stdout
import io
import json
import struct
import unittest
from unittest.mock import patch
import zipfile

import build_local_apk as builder
import test_babel_tower as base
import test_activity_copy as activity
from zyj_server import battle, blessing_cave, formation, player, protocol, recharge


class BlessingCaveTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        base.BabelTowerTests.setUpClass.__func__(cls)
        cls.baseline = copy.deepcopy(cls.baseline)
        cls.baseline["role_state"].update(level=105, vip=0, nextexp=cls.config["role_exp"]["105"]["nextexp"])

    reconnect = base.BabelTowerTests.reconnect
    give = base.BabelTowerTests.give
    assert_rejected = base.BabelTowerTests.assert_rejected
    network_lua = base.BabelTowerTests.network_lua

    def setUp(self):
        base.BabelTowerTests.setUp(self)
        self.seq = 300

    def call(self, opcode, values=(), *, seq=None, raw=None):
        self.seq += 1
        return self.session.handle(opcode, self.seq if seq is None else seq,
                                   recharge.ids(values) if raw is None else raw)

    def success(self, opcode, values=(), **kwargs):
        packets = self.call(opcode, values, **kwargs)
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], opcode, packets)
        return packets

    def query(self):
        return protocol.parse_ids_pb(self.success(6520)[0][16:])

    def state(self):
        return self.session.save["blessing_cave_state"]

    def prop(self, cid):
        return activity.ActivityCopyTests.prop_count(self, self.session.save, cid)

    def strengthen(self, *, weak=False):
        base.BabelTowerTests.strengthen(self, weak=weak)
        if not weak:
            world = bytes.fromhex(self.session.save["world_state"]["1002"])
            for raw in formation.records(world, 1, 2).values():
                for field in (6, 8):
                    raw = protocol.pb_set_varint(raw, field, 1000000000)
                player.record_slot_update(self.session.save, protocol.encode_pb_field(1, 2, raw))
            self.path.write_text(json.dumps(self.session.save))

    def report(self, packets):
        return json.loads(next(v for n, w, v in protocol.iter_pb_fields(packets[0][16:]) if (n, w) == (5, 2)))

    def test_entry_returns_remaining_and_five_values_per_unlocked_floor_without_free_rewards(self):
        before = copy.deepcopy(self.session.save)
        self.assertEqual(self.query(), [2, 1, 1, 0, 0, 0, 0])
        for key in ("role_state", "world_state", "guide", "protagonist_snapshot"):
            self.assertEqual(self.session.save[key], before[key])
        saved = copy.deepcopy(self.session.save)
        self.assertEqual(self.query(), [2, 1, 1, 0, 0, 0, 0])
        self.assertEqual(self.session.save, saved)
        self.session = self.reconnect()
        self.assertEqual(self.query(), [2, 1, 1, 0, 0, 0, 0])
        self.assertNotIn("103", self.session.save["guide"]["sections"])

    def test_real_loss_grants_nothing_and_does_not_spend_a_success(self):
        self.query()
        self.strengthen(weak=True)
        before = copy.deepcopy(self.session.save)
        packets = self.success(6521, [1, 1])
        self.assertFalse(self.report(packets)["result"])
        self.assertEqual(self.state()["used"], 0)
        self.assertEqual(self.state()["cleared"], [0] * 10)
        for key in ("role_state", "world_state", "guide"):
            self.assertEqual(self.session.save[key], before[key])

    def test_real_win_unlocks_sweep_and_keeps_rewards_costs_and_retries_atomic(self):
        self.strengthen()
        self.query()
        before = copy.deepcopy(self.session.save)
        packets = self.success(6521, [1, 1], seq=900)
        report = self.report(packets)
        self.assertTrue(report["result"])
        self.assertTrue(report["rules"])
        self.assertEqual((self.state()["used"], self.state()["cleared"]), (1, [1] + [0] * 9))
        self.assertIn(self.prop(20842), range(17, 24))
        saved, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        self.assertEqual(self.call(6521, [1, 1], seq=900), packets)
        self.assertEqual((self.session.save, self.path.read_bytes()), (saved, disk))
        self.assertEqual(self.query(), [1, 1, 2, 1, 0, 0, 0])
        self.assert_rejected(6522, [1, 2])
        stones = self.prop(20842)
        self.success(6522, [1, 1])
        self.assertIn(self.prop(20842) - stones, range(17, 24))
        self.assertEqual(self.query(), [0, 1, 2, 1, 0, 0, 0])
        self.assert_rejected(6521, [1, 2])
        for key in ("role_state", "guide", "protagonist_snapshot"):
            self.assertEqual(self.session.save[key], before[key])
        for key in ("1002", "1300"):
            self.assertEqual(self.session.save["world_state"][key], before["world_state"][key])
        self.session = self.reconnect()
        self.assertEqual(self.query(), [0, 1, 2, 1, 0, 0, 0])

    def test_floor_levels_and_per_floor_difficulties_require_actual_sequential_clears(self):
        self.query()
        self.assert_rejected(6521, [2, 1])
        self.assert_rejected(6521, [1, 2])
        self.strengthen()
        self.success(6521, [1, 1])
        self.assertEqual(len(self.query()), 7)
        self.assert_rejected(6521, [2, 1])
        self.session.save["role_state"]["level"] = 110
        self.assertEqual(self.query()[6:], [2, 1, 0, 0, 0, 0])
        self.success(6521, [2, 1])
        self.assertEqual(self.state()["cleared"][:2], [1, 1])
        self.clock.return_value += 86400
        self.success(6521, [1, 2])
        self.assertEqual(self.state()["cleared"][:2], [2, 1])
        self.assert_rejected(6522, [2, 2])

    def test_purchase_is_quoted_fairy_currency_and_persists_vip_status(self):
        self.query()
        fairy, gold = (self.session.save["role_state"][key] for key in ("g_gold", "gold"))
        self.assert_rejected(7010, [463, 1])
        self.assert_rejected(7010, [463, 1, 49])
        packets = self.success(7010, [463, 1, 50], seq=900)
        self.assertEqual(self.session.save["role_state"]["g_gold"], fairy - 50)
        self.assertEqual(self.session.save["role_state"]["gold"], gold)
        self.assertEqual((self.state()["bought"], self.query()[0]), (1, 3))
        vip = protocol.parse_ids_pb(self.success(300)[0][16:])
        self.assertEqual(vip[32], 1)
        self.assertIn(1001, [struct.unpack(">IIII", packet[:16])[2] for packet in packets])
        self.assert_rejected(7010, [463, 1, 50])
        self.success(7010, [463, 1, 80])
        self.assert_rejected(7010, [463, 1, 100])
        self.session = self.reconnect()
        self.assertEqual((self.state()["bought"], self.query()[0]), (2, 4))
        self.clock.return_value += 86400
        self.assertEqual(self.query()[0], 2)
        self.assertEqual((self.state()["bought"], self.state()["used"]), (0, 0))

    def test_vip_upgrade_keeps_paid_times_even_when_the_new_purchase_limit_is_lower(self):
        self.success(7010, [463, 2, 130])
        self.session.save["role_state"]["vip"] = 1
        self.path.write_text(json.dumps(self.session.save))
        self.session = self.reconnect()
        self.assertEqual((self.query()[0], self.state()["bought"]), (4, 2))
        self.assert_rejected(7010, [463, 1, 100])
        self.clock.return_value += 86400
        self.assertEqual(self.query()[0], 2)
        self.success(7010, [463, 1, 50])
        self.assert_rejected(7010, [463, 1, 80])

    def test_forward_midnight_resets_only_daily_counts_and_rejects_stale_quotes(self):
        self.strengthen()
        self.clock.return_value = ((base.NOW + 28800) // 86400 + 1) * 86400 - 28800 - 1
        self.success(6521, [1, 1])
        self.success(7010, [463, 1, 50])
        state = copy.deepcopy(self.state())
        self.clock.return_value += 1
        vip = protocol.parse_ids_pb(self.success(300)[0][16:])
        self.assertEqual(vip[32], 0)
        self.assertEqual(self.state(), state)
        saved, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.call(6520)
        self.assertEqual((self.session.save, self.path.read_bytes()), (saved, disk))
        self.assertEqual(self.query(), [2, 1, 2, 1, 0, 0, 0])
        self.assertEqual(self.state()["cleared"], state["cleared"])
        self.assertEqual((self.state()["used"], self.state()["bought"]), (0, 0))
        self.assert_rejected(7010, [463, 1, 80])
        packets = self.success(7010, [463, 2, 130], seq=920)
        saved, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        self.assertEqual(self.call(7010, [463, 2, 130], seq=920), packets)
        self.assertEqual((self.session.save, self.path.read_bytes()), (saved, disk))
        self.clock.return_value -= 1
        self.assert_rejected(6520)
        self.assert_rejected(6522, [1, 1])

    def test_high_vip_batch_buy_uses_all_four_prices_and_strict_request_shapes(self):
        self.session.save["role_state"]["vip"] = 27
        for opcode, values in ((7010, [463, 4, 379]), (7010, [463, 5, 530]),
                               (7010, [463, 1, 1 << 31]), (6521, [1 << 31, 1])):
            self.assert_rejected(opcode, values)
        for opcode, body in ((6520, protocol.encode_pb_field(2, 0, 1)),
                              (6521, protocol.encode_pb_field(1, 2, b"\x01\x01")),
                              (6521, recharge.ids([1, 1]) + protocol.encode_pb_field(2, 0, 1))):
            self.assert_rejected(opcode, raw=body)
        fairy = self.session.save["role_state"]["g_gold"]
        self.success(7010, [463, 4, 380])
        self.assertEqual(self.session.save["role_state"]["g_gold"], fairy - 380)
        self.assertEqual((self.query()[0], self.state()["bought"]), (6, 4))
        self.assert_rejected(7010, [463, 1, 150])

    def test_malformed_locked_clock_and_save_failures_do_not_change_memory_or_disk(self):
        for opcode, values in ((6520, [1]), (6521, []), (6521, [0, 1]), (6521, [11, 1]),
                               (6521, [1, 5]), (6521, [1, 1, 1]), (6522, [1, 1]),
                               (7010, [463, 0, 0]), (7010, [463, 1, 50, 0])):
            self.assert_rejected(opcode, values)
        self.session.save["role_state"]["level"] = 104
        self.assert_rejected(6520)
        self.assert_rejected(7010, [463, 1, 50])
        self.session.save["role_state"]["level"] = 105
        self.query()
        self.clock.return_value -= 1
        self.assert_rejected(6521, [1, 1])
        self.assert_rejected(7010, [463, 1, 50])
        self.clock.return_value += 1
        self.strengthen()
        saved, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        for opcode, values in ((6521, [1, 1]), (7010, [463, 1, 50])):
            with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
                self.call(opcode, values)
            self.assertEqual((self.session.save, self.path.read_bytes()), (saved, disk))

    def test_corrupt_state_resource_overflow_and_sweep_save_failure_fail_closed(self):
        self.query()
        original = copy.deepcopy(self.session.save)
        for key, value in (("used", True), ("used", 99), ("bought", -1), ("day", 1 << 31),
                           ("checked_at", None), ("cleared", [0] * 9), ("cleared", [False] * 10),
                           ("cleared", [0, 1] + [0] * 8), ("cleared", [5] + [0] * 9)):
            with self.subTest(key=key, value=value):
                corrupted = copy.deepcopy(original)
                corrupted["blessing_cave_state"][key] = value
                self.path.write_text(json.dumps(corrupted))
                disk = self.path.read_bytes()
                with self.assertRaisesRegex(ValueError, "福祉天宫"):
                    self.reconnect()
                self.assertEqual(self.path.read_bytes(), disk)
        self.path.write_text(json.dumps(original))
        self.strengthen()
        self.give(20842, (1 << 31) - 1)
        self.assert_rejected(6521, [1, 1])
        self.give(20842, -self.prop(20842))
        self.success(6521, [1, 1])
        saved, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.call(6522, [1, 1])
        self.assertEqual((self.session.save, self.path.read_bytes()), (saved, disk))
        self.give(1025, -self.session.save["role_state"]["g_gold"])
        self.assert_rejected(7010, [463, 1, 50])
        comb = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 6521)
                                        + protocol.encode_pb_field(2, 2, recharge.ids([1, 1])))
        self.assert_rejected(999900, raw=comb)

    def test_all_forty_profiles_use_exact_npc_stats_and_real_native_animations(self):
        from lupa.lua51 import LuaRuntime
        lua = LuaRuntime()
        config = dict(self.config)
        with zipfile.ZipFile(activity.ROOT / "configs_sec5.zip") as archive:
            for name in ("generalanimation", "skillanimation", "personalboss_att"):
                config[name] = json.loads(archive.read(f"5/{name}.json"))
        lua.globals().gamedata = lua.table_from({"config": config}, recursive=True)
        lua.execute('''print=function() end;printT=print;battleScene={slotNum=7}
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            CCFileUtils={sharedFileUtils=function(self) return self end,fullPathForFilename=function(self,p) return p end}
            ui={Split=function(s,sep) local t={} for v in string.gmatch(s,'[^'..sep..']+') do t[#t+1]=v end return t end}''')
        lua.execute(self.client_scripts()["assets/scripts/battleReportConvert.so"].decode())
        lua.execute(builder.read_script("BattleReportAbbToKey").decode())
        original, count = copy.deepcopy(self.session.save), 0
        with zipfile.ZipFile(builder.SRC_APK) as archive:
            names, assets = archive.namelist(), {}
            lua.globals().CCFileUtils.isFileExist = lambda _, path: any(n.endswith("/" + path) for n in names)

            def asset(path):
                if path not in assets:
                    matches = [n for n in names if n.endswith("/" + path)]
                    self.assertEqual(len(matches), 1, path)
                    assets[path] = json.loads(archive.read(matches[0]))
                return lua.table_from(assets[path], recursive=True)

            lua.globals().LoadJsonFileToTable = asset
            for floor, rows in self.config["xianku_guaiwu"].items():
                for difficulty, point in rows.items():
                    with self.subTest(floor=floor, difficulty=difficulty):
                        attack, defense = battle.rosters(self.session.save, dict(point, level=point["monster_level"]), self.config)
                        npc = self.config["copy_monster"][str(point["p1"])]
                        self.assertEqual(defense[2]["atk"], int(npc["atk"] + npc["atk-grow"] * (point["monster_level"] - 1)) + point["atk1-correct"])
                        self.assertEqual(defense[2]["advance"], point["break1-correct"])
                        self.assertEqual(defense[2]["cover_l"], point["mozhao1_lv"])
                        inputs = copy.deepcopy((attack, defense))
                        report = battle.simulate(attack, defense, self.config, 7)
                        self.assertEqual((attack, defense), inputs)
                        self.assertEqual(report, battle.simulate(attack, defense, self.config, 7))
                        native = lua.table_from(json.loads(lua.globals().ReplaceAbbToKey(json.dumps(report))), recursive=True)
                        atk, enemy = lua.globals().getBattleInitSlotInfo(native)
                        animations, ext = lua.globals().convertBattleReportToAnimationSub(native, atk, enemy, None, "blessingCave")
                        self.assertGreater(len(animations), 1)
                        for side, key in (("attack", "atk"), ("defense", "def")):
                            for pos, unit in report["endmeta"][side].items():
                                self.assertEqual((ext.endinfo[key][pos].hp, ext.endinfo[key][pos].ap), (unit["h"], unit["ap"]))
                        reward = blessing_cave.prizes(copy.deepcopy(original), point, self.config, 7)
                        player.apply_reward(copy.deepcopy(original), reward, self.config, base.NOW)
                        count += 1
        self.assertEqual(count, 40)
        self.assertEqual(self.session.save, original)

    @classmethod
    def client_scripts(cls):
        if not hasattr(cls, "_client_scripts"):
            with redirect_stdout(io.StringIO()):
                encrypted = builder.get_patched_lua_scripts()
            cls._client_scripts = {}
            for name, raw in encrypted.items():
                data = builder.xxtea_decrypt(raw, builder.XXTEA_KEY)
                cls._client_scripts[name] = data[:struct.unpack("<I", data[-4:])[0]]
        return cls._client_scripts

    def blessing_network(self):
        lua = self.network_lua(native_protobuf=True)
        for name in ("combmessages_pb", "error_pb", "params_pb"):
            lua.execute(builder.read_script(name, "pb"))
        lua.execute(builder.read_script("GameBabelTower"))
        lua.execute(b'''package.loaded.GameBabelTower=true
            gamedata.cache.role.g_gold=10000;gamedata.cache.BabelTower={mapData={buyTime=0}}
            gamedata.updateRoleG_gold=function(self,n) self.cache.role.g_gold=self.cache.role.g_gold+n end
            gamedata.SomethingProcess=function(self,p) rewards=(rewards or 0)+1;return p end
            package.loaded.logError={errorMessage={},errorFunc={}}
            printf=function() end
            initPb=function(mod,fd) local m=mod.Ids();m:ParseFromString(fd.rbuf);return m end''')
        lua.execute(self.client_scripts()["assets/scripts/GameBlessingCave.so"])
        lua.execute(self.client_scripts()["assets/common_lua/GameErrorMessage.so"])
        self.assertIsNone(lua.globals().gameConfig)
        return lua

    def test_native_network_fifo_string_indexes_and_seq_zero_do_not_steal_queries(self):
        lua = self.blessing_network()
        for generation in (1, 2):
            request = lua.table_from({b"blessingView": lua.table_from({b"page": generation})})
            self.assertEqual(lua.globals().UIBlessingCaveStatusCallBack(request)[:2], (1, 6520))
        raw = self.success(6520)[0][16:]
        fd = lua.table_from({b"rbuf": raw, b"ser": 0})
        self.assertTrue(lua.globals().NetBlessingCaveStatusCallBack(fd)[b"blessingIgnored"])
        for generation in (1, 2):
            fd[b"ser"] = generation
            result = lua.globals().NetBlessingCaveStatusCallBack(fd)
            self.assertEqual((result[b"times"], result[b"bought"], result[b"blessingView"][b"page"]), (2, 0, generation))
            self.assertEqual(result[b"copyInfo"][b"3"], 1)
            self.assertIsNone(result[b"copyInfo"][3])
            self.assertEqual(len(list(result[b"copyInfo"].items())), 6)
        self.assertTrue(lua.globals().NetBlessingCaveStatusCallBack(fd)[b"blessingIgnored"])

    def test_native_network_battle_sweep_quote_and_errors_never_apply_rewards_or_costs_twice(self):
        self.strengthen()
        lua = self.blessing_network()
        request = lua.table_from({b"id": 1, b"difficulty": 1, b"blessingView": lua.table_from({b"page": 1})})
        for opcode, send, receive in ((6521, "UIBlessingCaveAttackCallBack", "NetBlessingCaveAttackCallBack"),
                                      (6522, "UIBlessingCaveSweepCallBack", "NetBlessingCaveSweepCallBack")):
            send, receive = lua.globals()[send.encode()], lua.globals()[receive.encode()]
            mode, mid, body = send(request)
            self.assertEqual((mode, mid, protocol.parse_ids_pb(body)), (1, opcode, [1, 1]))
            self.assertEqual(send(request)[0], 0)
            self.assertEqual(lua.globals().UIXianBuyTimesCallBack(lua.table_from({b"sysId": 450, b"times": 1, b"spend": 25}))[0], 0)
            packets = self.success(opcode, [1, 1])
            before = lua.globals().rewards
            fd = lua.table_from({b"rbuf": packets[0][16:], b"ser": 0})
            self.assertTrue(receive(fd)[b"blessingIgnored"])
            self.assertEqual(lua.globals().rewards, before)
            fd[b"ser"] = 1
            result = receive(fd)
            self.assertEqual(result[b"blessingFloor"], 1)
            after = lua.globals().rewards
            self.assertTrue(receive(fd)[b"blessingIgnored"])
            self.assertEqual(lua.globals().rewards, after)
            self.assertIsNone(lua.globals().gamedata[b"ext"][b"localAutoCopyBusy"])
        request = lua.table_from({b"sysId": 463, b"times": 1, b"spend": 50, b"blessingView": lua.table_from({b"page": 1})})
        mode, mid, body = lua.globals().UIXianBuyTimesCallBack(request)
        self.assertEqual((mode, mid, protocol.parse_ids_pb(body)), (1, 7010, [463, 1, 50]))
        packets = self.success(7010, [463, 1, 50])
        fd = lua.table_from({b"rbuf": packets[0][16:], b"ser": 1})
        lua.globals().NetXianBuyTimesCallBack(fd)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"g_gold"], self.session.save["role_state"]["g_gold"])
        self.assertTrue(lua.globals().NetXianBuyTimesCallBack(fd)[b"blessingIgnored"])
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"g_gold"], 9950)
        lua.globals().UIBlessingCaveAttackCallBack(lua.table_from({b"id": 1, b"difficulty": 2}))
        lua.globals().NetErrorMessageCallback9(lua.table_from({b"rbuf": recharge.ids([6521, 0]), b"ser": 0}))
        self.assertEqual(lua.globals().gamedata[b"ext"][b"localBlessingCaveBusy"], 6521)
        lua.globals().NetErrorMessageCallback9(lua.table_from({b"rbuf": recharge.ids([6522, 0]), b"ser": 1}))
        self.assertEqual(lua.globals().gamedata[b"ext"][b"localBlessingCaveBusy"], 6521)
        lua.globals().NetErrorMessageCallback9(lua.table_from({b"rbuf": recharge.ids([6521, 0]), b"ser": 1}))
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localBlessingCaveBusy"])
        mode, _, body = lua.globals().UIXianBuyTimesCallBack(lua.table_from({b"sysId": 450, b"times": 1, b"spend": 25}))
        self.assertEqual((mode, protocol.parse_ids_pb(body)), (1, [450, 1]))
        result = lua.globals().NetXianBuyTimesCallBack(lua.table_from({b"rbuf": b"", b"ser": 1}))
        self.assertEqual((result[b"sysId"], result[b"BabelTowerMapData"][b"buyTime"]), (450, 1))
        mode, _, body = lua.globals().UIXianBuyTimesCallBack(lua.table_from({b"sysId": 614, b"times": 1, b"spend": 50}))
        self.assertEqual((mode, protocol.parse_ids_pb(body)), (1, [614, 1]))
        result = lua.globals().NetXianBuyTimesCallBack(lua.table_from({b"rbuf": b"", b"ser": 2}))
        self.assertEqual((result[b"sysId"], result[b"buyTime"]), (614, 1))
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"g_gold"], 9875)

    def blessing_ui(self):
        from lupa.lua51 import LuaRuntime
        lua = LuaRuntime(unpack_returned_tuples=True)
        config = dict(self.config)
        with zipfile.ZipFile(activity.ROOT / "configs_sec5.zip") as archive:
            config["generalanimation"] = json.loads(archive.read("5/generalanimation.json"))
        lua.globals().gamedata = lua.table_from({"config": config}, recursive=True)
        lua.execute('''print=function() end;printT=print;CCControlEventTouchUpInside=1
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            function node() return setmetatable({}, {__index=function(t,k)
                if k=="addHandleOfControlEvent" or k=="setAnimationCompletedCallback" then return function(self,f) self.callback=f end end
                if k=="getContentSize" then return function() return {width=1080,height=500} end end
                if k=="getPositionY" then return function() return 0 end end
                if k=="setString" then return function(self,v) self.text=v end end
                return function() end
            end}) end
            function items() return setmetatable({}, {__index=function(t,k) local v=node();rawset(t,k,v);return v end}) end
            CCBReaderLoad=function() lastItems=items();return node(),lastItems end
            CCTableViewCell={create=function() return node() end}
            getAnimationManager=function() return node() end
            CCSizeMake=function(x,y) return {width=x,height=y} end;CCSize=CCSizeMake
            ccc3=function(...) return {...} end;tolua={cast=function(v) return v end}
            setSpriteFrameByName=function() end
            requests={};UIRequest=function(t) requests[#requests+1]=t end
            runGamePrompt=function(t) prompt=t.msg end
            RunbattleCallBack=function(_,t,cb) battles=(battles or 0)+1;battleDone=cb end
            showRewardPopupWindow=function(_,_,cb) popups=(popups or 0)+1;rewardDone=cb end
            gameTouch={clickprofbytime=function() end}
            gameConfig={originSize={width=1080},maiscenebottomheight=0,strings={string_common=function() return "label" end}}
            ui=setmetatable({setLabelString=function(n,v) if v then n:setString(v) end end,
                IDconfig=function(cid) return gamedata.config.general[tostring(cid)] end,
                itemcache={loadSkeleton=function() local n=node();n.root=n;return n end},
                createLuaTableView=function(t) listCallback=t.handle;return node() end,
                creatInputEditBoxForNum=function(_,_,_,cb) inputCallback=cb end}, {__index=function() return function() end end})
            LuaEventHandler={create=function(self,fn) return fn end}
            GameScene={presentLayer="daily",roleinfo={level=105,g_gold=10000},vip={vip=0},vipstatus={xianku_cishu=0},
                layers={daily={show=true,module={rootNode=node()}}}}
            function GameScene:shiftLayer(name,_,data)
                if name=="blessingCave" then
                    self.presentLayer=name
                    self.layers.blessingCave.module:init(node(),1800,data)
                    self.layers.blessingCave.show=true
                else self.presentLayer=name end
            end
            gameWindows={windows={},openWindow=function(self,name,data,cb)
                opens=(opens or 0)+1;self.windows[name].show=true
                self.windows[name].module:open(-110,data,cb)
            end,closeWindow=function(self,name)
                self.windows[name].module:close();self.windows[name].show=false
            end}''')
        lua.execute(builder.read_script("UIBabelTower").decode())
        lua.execute('package.loaded.UIBabelTower=true')
        page = lua.execute(self.client_scripts()["assets/scripts/Layer_blessingCave.so"].decode())
        window = lua.execute(self.client_scripts()["assets/scripts/window_blessingCaveBuy.so"].decode())
        lua.globals().GameScene.layers.blessingCave = lua.table_from({"show": False, "module": page})
        lua.globals().gameWindows.windows.blessingCaveBuy = lua.table_from({"show": False, "module": window})
        lua.execute(self.client_scripts()["assets/scripts/UIBlessingCave.so"].decode())
        return lua, page, window

    def test_native_direct_entry_query_before_the_page_is_shown_refreshes_the_same_page(self):
        lua, page, _ = self.blessing_ui()
        lua.globals().GameScene.shiftLayer(lua.globals().GameScene, "blessingCave", "up", "recommend")
        request = lua.globals().requests[1]
        self.assertEqual(request.type, 6520)
        result = lua.table_from({"type": 6520, "times": 2, "bought": 0, "rolelv": 105,
                                 "copyInfo": {"1": 2, "2": 1, "3": 1, "4": 0, "5": 0, "6": 0}}, recursive=True)
        result.blessingView = request.blessingView
        lua.globals().UIBlessingCaveStatusQuery(result)
        self.assertEqual((page.battleTimes, page.maxPositon, page.copyInfoCache[1].status), (2, 1, 1))
        self.assertEqual(len(lua.globals().requests), 1)

    def test_native_table_cell_sends_the_displayed_floor_and_discards_removed_page_buttons(self):
        lua, page, _ = self.blessing_ui()
        data = lua.table_from({"copyInfo": {"1": 2, "2": 1, "3": 1, "4": 0, "5": 0, "6": 0},
                               "times": 2, "rolelv": 105}, recursive=True)
        lua.globals().GameScene.shiftLayer(lua.globals().GameScene, "blessingCave", "up", data)
        self.assertEqual([page.currentCopyInfo[i].difficulty for i in (1, 2)], [2, 1])
        lua.globals().listCallback("cellAtIndex", None, 1, None)
        button = lua.globals().lastItems.tiaozhanBtn.callback
        button()
        request = lua.globals().requests[1]
        self.assertEqual((request.type, request.id, request.difficulty), (6521, 1, 1))
        page.clear(page)
        button()
        self.assertEqual(len(lua.globals().requests), 1)

    def test_actual_page_entry_buy_and_old_window_callbacks_are_generation_bound(self):
        lua, page, window = self.blessing_ui()
        lua.globals().UIRequest(lua.table_from({"type": 6520}))
        old_view = lua.globals().requests[1].blessingView
        lua.globals().GameScene.layers.daily.module.rootNode = lua.globals().node()
        values = self.query()
        data = {"type": 6520, "times": values[0], "bought": values[-1], "rolelv": 105,
                "copyInfo": {str(i+1): value for i, value in enumerate(values[:-1])}}
        result = lua.table_from(data, recursive=True)
        result.blessingView = old_view
        lua.globals().UIBlessingCaveStatusQuery(result)
        self.assertFalse(lua.globals().GameScene.layers.blessingCave.show)
        lua.globals().UIRequest(lua.table_from({"type": 6520}))
        result.blessingView = lua.globals().requests[2].blessingView
        lua.globals().UIBlessingCaveStatusQuery(result)
        self.assertTrue(lua.globals().GameScene.layers.blessingCave.show)
        self.assertEqual((page.maxPositon, page.currentcopyPosition, page.battleTimes), (1, 1, 2))
        self.assertEqual(len(lua.globals().requests), 2)
        old_button = page.rootItems.buyTime.callback
        old_button()
        self.assertEqual(lua.globals().opens, 1)
        window.numchange(window, 1)
        self.assertEqual(window.buySpend, 50)
        button, input_callback = window.rootItems.doButton2.callback, lua.globals().inputCallback
        button()
        request = lua.globals().requests[3]
        self.assertEqual((request.type, request.sysId, request.times, request.spend), (7010, 463, 1, 50))
        self.assertIsNotNone(request.blessingView.page)
        button();input_callback(2)
        self.assertEqual(len(lua.globals().requests), 3)
        page.clear(page)
        old_button()
        self.assertEqual(lua.globals().opens, 1)

    def test_native_purchase_window_shows_zero_not_negative_after_vip_upgrade(self):
        lua, page, window = self.blessing_ui()
        lua.globals().GameScene.vip.vip = 1
        lua.globals().GameScene.vipstatus.xianku_cishu = 2
        data = lua.table_from({"copyInfo": {"1": 4, "2": 1, "3": 1, "4": 0, "5": 0, "6": 0},
                               "times": 4, "rolelv": 105}, recursive=True)
        lua.globals().GameScene.shiftLayer(lua.globals().GameScene, "blessingCave", "up", data)
        page.rootItems.buyTime.callback()
        self.assertEqual(window.maxBuyTime, 0)
        window.numchange(window, 1)
        self.assertEqual((window.buynum, window.buySpend), (0, 0))
        window.rootItems.doButton2.callback()
        self.assertEqual(len(lua.globals().requests), 0)

    def test_actual_battle_and_reward_callbacks_never_reopen_closed_or_replaced_pages(self):
        lua, page, window = self.blessing_ui()
        data = lua.table_from({"copyInfo": {"1": 1, "2": 1, "3": 2, "4": 1, "5": 0, "6": 0},
                               "times": 1, "bought": 0, "rolelv": 105}, recursive=True)
        lua.globals().GameScene.shiftLayer(lua.globals().GameScene, "blessingCave", "up", data)
        view = lua.globals().LocalBlessingCaveContext()
        result = lua.table_from({"type": 6521, "blessingView": view, "blessingFloor": 1, "reward": {"props": {1: 1}}}, recursive=True)
        lua.globals().UIBlessingCaveAttack(result)
        self.assertEqual(lua.globals().battles, 1)
        battle_done, animation = lua.globals().battleDone, page.animationManager.callback
        page.clear(page)
        count = len(lua.globals().requests)
        battle_done();animation()
        self.assertEqual(len(lua.globals().requests), count)
        lua.globals().GameScene.shiftLayer(lua.globals().GameScene, "blessingCave", "up", data)
        lua.globals().UIBlessingCaveAttack(result)
        self.assertEqual(lua.globals().battles, 1)
        result.blessingView = lua.globals().LocalBlessingCaveContext()
        result.type = 6522
        lua.globals().UIBlessingCaveSweep(result)
        self.assertEqual(lua.globals().popups, 1)
        reward_done = lua.globals().rewardDone
        page.clear(page)
        reward_done()
        self.assertEqual(len(lua.globals().requests), count)
        lua.globals().GameScene.shiftLayer(lua.globals().GameScene, "blessingCave", "up", data)
        result.blessingView = lua.globals().LocalBlessingCaveContext()
        page.currentcopyPosition = 2
        result.type = 6521
        lua.globals().UIBlessingCaveAttack(result)
        self.assertEqual(lua.globals().battles, 1)
        self.assertEqual(lua.globals().requests[len(lua.globals().requests)].type, 6520)


if __name__ == "__main__":
    unittest.main()
