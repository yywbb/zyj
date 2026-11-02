from contextlib import redirect_stdout
import copy
from fractions import Fraction
import io
import struct
import unittest
from unittest.mock import patch

import build_local_apk as builder
import test_penglai
from zyj_server import battle, formation, player, protocol, recharge, single_boss, training, treasure_refine


class TreasureRefineTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        test_penglai.PenglaiTests.setUpClass.__func__(cls)
        cls.baseline = copy.deepcopy(cls.baseline)
        cls.baseline["role_state"].update(level=28, coin=200000000, gold=100000)

    reconnect = test_penglai.PenglaiTests.reconnect
    call = test_penglai.PenglaiTests.call
    give = test_penglai.PenglaiTests.give
    props = test_penglai.PenglaiTests.props
    assert_rejected = test_penglai.PenglaiTests.assert_rejected

    def setUp(self):
        test_penglai.PenglaiTests.setUp(self)
        self.next_iid = 1000200
        self.give(20256, 2000000)

    def equips(self):
        return formation.records(bytes.fromhex(self.session.save["world_state"]["1002"]), 2, 1)

    def equip(self, cid=25401, level=1, refined=0, exp=0):
        self.next_iid += 1
        player.record_slot_update(self.session.save, protocol.encode_pb_field(2, 2, recharge.ids([self.next_iid, cid, level, refined, exp])))
        return self.next_iid

    def item(self, iid):
        return protocol.parse_ids_pb(self.equips()[iid])

    def wear(self, iid, slot=1):
        body = protocol.encode_pb_field(1, 0, slot) + protocol.encode_pb_field(2, 0, iid)
        packets = self.session.handle(1005, 800, body)
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 1005)

    def refine(self, iid):
        item = self.item(iid)
        row = self.config["equip"][str(item[1])]
        amount = self.config["treasure2_refine"][str(item[3] + 1)][f'oneself{row["quality"]}']
        return self.call(1119, [iid, *(self.equip(item[1]) for _ in range(amount))])

    def general(self, slot=1):
        world = bytes.fromhex(self.session.save["world_state"]["1002"])
        iid = protocol.pb_get_varint(formation.records(world, 4, 1)[slot], 2)
        return formation.records(world, 1, 2)[iid]

    def test_idle_refine_charges_configured_cost_once_and_reconnects_with_authoritative_pushes(self):
        target = self.equip()
        before = copy.deepcopy(self.session.save)
        stones = self.props(20256)
        packets = self.call(1119, [target])
        self.assertEqual(self.item(target), [target, 25401, 1, 1, 0])
        self.assertEqual(before["role_state"]["coin"] - self.session.save["role_state"]["coin"], 40000)
        self.assertEqual(stones - self.props(20256), 120)
        self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets][-2:], [1200, 1001])
        self.assertFalse(any(n in (1, 2, 9) for n, w, v in protocol.iter_pb_fields(packets[0][16:])))
        for key in ("power", "level", "exp", "stamina", "energy", "gold"):
            self.assertEqual(before["role_state"][key], self.session.save["role_state"][key])
        self.assertEqual(before["world_state"]["1300"], self.session.save["world_state"]["1300"])
        self.assertNotIn("23", self.session.save["guide"]["sections"])
        self.session = self.reconnect()
        self.assertEqual(self.item(target)[3], 1)

    def test_worn_refine_changes_only_the_wearer_and_updates_power_without_erasing_training(self):
        target = self.equip()
        self.wear(target)
        before, raw = copy.deepcopy(self.session.save), self.general()
        packets = self.refine(target)
        self.assertEqual(protocol.pb_get_varint(self.general(), 7), protocol.pb_get_varint(raw, 7) + 110)
        self.assertEqual(self.session.save["role_state"]["power"] - before["role_state"]["power"], 110)
        self.assertIn(205, [struct.unpack(">IIII", p[:16])[2] for p in packets])
        for field in (3, 4, 5, 6, 8, 9, 17):
            self.assertEqual(protocol.pb_get_varint(self.general(), field), protocol.pb_get_varint(raw, field))

    def test_hidden_percent_uses_base_growth_and_is_reversible_on_swaps_and_level_growth(self):
        target = self.equip(refined=4)
        self.wear(target)
        raw = self.general()
        row = self.config["general"][str(protocol.pb_get_varint(raw, 1))]
        base = battle.general_base(row, "hp", protocol.pb_get_varint(raw, 3), protocol.pb_get_varint(raw, 4) or 0, self.config)
        self.refine(target)
        self.assertEqual(protocol.pb_get_varint(self.general(), 8) - protocol.pb_get_varint(raw, 8), int(base / 10))
        world = bytes.fromhex(self.session.save["world_state"]["1002"])
        slots, equips = formation.records(world, 4, 2), formation.records(world, 2, 1)
        generals = formation.records(world, 1, 2)
        members = {self.config["general"][str(protocol.pb_get_varint(v, 1))]["init_cid"] for iid, v in generals.items() if iid in slots}
        iid = protocol.pb_get_varint(self.general(), 2)
        grown, _, up = training.grow_general(self.general(), 10000, slots[iid], members, equips, self.config, 56)
        self.assertTrue(up)
        old, _ = formation.bonuses(self.general(), slots[iid], members, equips, self.config)
        new, _ = formation.bonuses(grown, slots[iid], members, equips, self.config)
        self.assertGreater(new[8], old[8])
        saved = copy.deepcopy(self.session.save)
        team = protocol.parse_ids_pb(self.call(3702, [140, 1])[0][16:])[:8]
        temporary, _ = single_boss.project_team(self.session.save, team, self.config)
        self.assertEqual(battle.rosters(temporary, self.config["copy"]["42102"]["1"], self.config)[0],
                         battle.rosters(self.session.save, self.config["copy"]["42102"]["1"], self.config)[0])
        self.assertEqual(saved["world_state"], self.session.save["world_state"])

    def test_same_cid_material_counts_are_exact_unique_and_all_or_nothing(self):
        target = self.equip(refined=4)
        food, other = self.equip(), self.equip(25402)
        for values in ([target], [target, food, other], [target, other], [target, target], [target, food, food], [target, 999999]):
            self.assert_rejected(1119, recharge.ids(values))
        self.call(1119, [target, food])
        self.assertNotIn(food, self.equips())
        self.assertIn(other, self.equips())
        self.assertEqual(self.item(target)[3], 5)

    def test_worn_cheer_refined_and_starred_materials_are_protected(self):
        target = self.equip(refined=4)
        baseline = copy.deepcopy(self.session.save)
        for problem in ("worn", "cheer", "refined", "starred", "target_cheer"):
            self.session.save = copy.deepcopy(baseline)
            food = self.equip(refined=1 if problem == "refined" else 0)
            if problem == "starred":
                player.record_slot_update(self.session.save, protocol.encode_pb_field(2, 2, recharge.ids(self.item(food) + [0]*6 + [1])))
            elif problem == "worn":
                self.wear(food)
            elif problem in ("cheer", "target_cheer"):
                slot = protocol.encode_pb_field(1, 0, 1) + protocol.encode_pb_field(9, 0, target if problem == "target_cheer" else food)
                player.record_slot_update(self.session.save, protocol.encode_pb_field(5, 2, slot))
            with self.subTest(problem=problem):
                self.assert_rejected(1119, recharge.ids([target, food]))

    def test_strict_requests_unlocked_caps_resources_and_unsupported_legacy_routes(self):
        target = self.equip()
        for body in (b"", b"\x08", b"\x0a\x00", b"\x10\x01", recharge.ids([0]), recharge.ids([1<<31])):
            self.assert_rejected(1119, body)
        self.session.save["role_state"]["level"] = 27
        self.assert_rejected(1119, recharge.ids([target]))
        self.session.save["role_state"]["level"] = 28
        capped = self.equip(refined=20)
        self.assert_rejected(1119, recharge.ids([capped]))
        self.session.save["role_state"]["coin"] = 0
        self.assert_rejected(1119, recharge.ids([target]))
        self.session.save["role_state"]["coin"] = 200000000
        self.give(20256, -self.props(20256))
        self.assert_rejected(1119, recharge.ids([target]))
        self.assert_rejected(1106, recharge.ids([target]))
        comb = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 1119) + protocol.encode_pb_field(2, 2, recharge.ids([target])))
        self.assert_rejected(999900, comb)

    def test_success_retry_save_failure_and_power_overflow_never_publish_half_updates(self):
        target = self.equip()
        body = recharge.ids([target])
        packets = self.session.handle(1119, 900, body)
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 1119)
        memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        self.assertEqual(self.session.handle(1119, 900, body), packets)
        with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
            self.call(1119, [target])
        self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))
        self.wear(target)
        self.session.save["role_state"]["power_all"] = (1 << 31)-1
        self.assert_rejected(1119, body)

    def test_strengthening_refined_targets_keeps_refine_stats_and_rejects_refined_food(self):
        target = self.equip()
        self.wear(target)
        self.refine(target)
        self.give(26407, 5)
        self.call(1210, [target, 26407, 1])
        self.assertEqual(self.item(target)[3], 1)
        self.assertGreater(self.item(target)[2], 1)
        food = self.equip()
        body = protocol.encode_pb_field(1, 0, target) + protocol.encode_pb_field(2, 0, food)
        packets = self.session.handle(1118, 1000, body)
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 1118)
        self.assertEqual(self.item(target)[3], 1)
        food = self.equip(refined=1)
        self.assert_rejected(1118, protocol.encode_pb_field(1, 0, target) + protocol.encode_pb_field(2, 0, food))

    def test_verified_rebirth_returns_only_actual_stones_coin_and_pristine_copies(self):
        target = self.equip()
        coin, stones = self.session.save["role_state"]["coin"], self.props(20256)
        for _ in range(5):
            self.refine(target)
        self.give(26407, 1)
        self.call(1210, [target, 26407, 1])
        item = self.item(target)
        gold = self.session.save["role_state"]["gold"]
        self.call(1117, [target])
        self.assertEqual(self.item(target)[:3], [target, 25401, 1])
        self.assertFalse(any(self.item(target)[3:]))
        self.assertEqual((self.session.save["role_state"]["coin"], self.props(20256), self.props(26407)), (coin, stones, 1))
        self.assertEqual(sum(protocol.parse_ids_pb(raw)[1] == 25401 for raw in self.equips().values()), 2)
        fee = self.config["renascence"][str(item[2])]["treasurerecost"] + self.config["renascence"][str(item[3])]["treasurerefinecost"]
        self.assertEqual(gold - self.session.save["role_state"]["gold"], fee)
        self.assert_rejected(1117, recharge.ids([target]))

    def test_trained_materials_follow_native_consumption_but_do_not_invent_rebirth_history(self):
        target = self.equip(refined=4)
        food = self.equip(level=3, exp=12)
        self.call(1119, [target, food])
        self.assertNotIn(food, self.equips())
        self.assert_rejected(1117, recharge.ids([target]))
        self.assert_rejected(1104, protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, target) + protocol.encode_pb_field(2, 0, (1<<64)-1)))

    def test_all_seventy_two_profiles_hidden_attributes_and_every_quality_cost_tier(self):
        rows = [r for r in self.config["equip"].values() if r["type"] in ("horse", "treasure") and r["adorn"]]
        self.assertEqual(len(rows), 72)
        raw = self.general()
        general = self.config["general"][str(protocol.pb_get_varint(raw, 1))]
        for row in rows:
            for level in range(row["maxlevel2"] + 1):
                item = [1000201, row["id"], 1, level, 0]
                treasure_refine.validate(item, self.config)
                actual = treasure_refine.attributes(raw, item, self.config)
                expected = {f: 0 for f in range(6, 17)}
                expected[battle.GENERAL_FIELDS[row["refine"]]] += sum(row[f"refine-grow{i}"] for i in range(1, level + 1))
                for i in range(1, 11):
                    if row[f"refine-attr{i}"] and level >= row[f"refine-level{i}"]:
                        name, value = row[f"refine-attr{i}"].split(";")
                        base = battle.general_base(general, name, protocol.pb_get_varint(raw, 3), protocol.pb_get_varint(raw, 4) or 0, self.config) if name in ("atk", "def", "hp") else 100
                        expected[battle.GENERAL_FIELDS[name]] += int(base * Fraction(value))
                with self.subTest(cid=row["id"], level=level):
                    self.assertEqual(actual, expected)
        baseline = copy.deepcopy(self.session.save)
        for quality in range(2, 7):
            self.session.save = copy.deepcopy(baseline)
            row = next(r for r in rows if r["quality"] == quality)
            target = self.equip(row["id"])
            coin, stones = self.session.save["role_state"]["coin"], self.props(20256)
            for level in range(1, row["maxlevel2"] + 1):
                cost = dict(tuple(map(int, entry.split(","))) for entry in self.config["treasure2_refine"][str(level)][f"num{quality}"].split(";") if entry)
                self.refine(target)
                coin -= cost[1000]
                stones -= cost[20256]
                self.assertEqual((self.item(target)[3], self.session.save["role_state"]["coin"], self.props(20256)), (level, coin, stones))
            self.assert_rejected(1119, recharge.ids([target]))

    def test_malformed_saved_items_and_bad_recipes_preserve_unknown_fields_and_fail_atomically(self):
        target = self.equip()
        raw = self.equips()[target] + protocol.encode_pb_field(50, 2, b"preserve")
        player.record_slot_update(self.session.save, protocol.encode_pb_field(2, 2, raw))
        self.refine(target)
        self.assertIn((50, 2, b"preserve"), list(protocol.iter_pb_fields(self.equips()[target])))
        baseline = copy.deepcopy(self.session.save)
        for field, value in ((3, 31), (5, 1), (11, 1), (12, 1)):
            self.session.save = copy.deepcopy(baseline)
            item = self.item(target) + [0]*8
            item[field] = value
            player.record_slot_update(self.session.save, protocol.encode_pb_field(2, 2, recharge.ids(item)))
            self.assert_rejected(1119, recharge.ids([target]))
        self.session.save = copy.deepcopy(baseline)
        self.session.role_config = copy.deepcopy(self.config)
        self.session.role_config["treasure2_refine"]["2"]["num5"] = "1000,-1;20256,10;"
        self.assert_rejected(1119, recharge.ids([target]))

    def test_gift_requires_real_s23_reports_and_uses_existing_simulated_payment_once(self):
        import test_sigil
        self.assert_rejected(2882, recharge.ids([130015]))
        for step in range(1, self.steps[23] + 1):
            self.session.handle(201, 1200 + step, protocol.encode_pb_field(1, 0, 23) + protocol.encode_pb_field(2, 0, step))
        self.assertEqual(protocol.parse_ids_pb(self.call(2882, [130015])[0][16:]), [130015, 0, 43200])
        test_sigil.SigilTests.pay_gift(self, 130015, 4)
        stones = self.props(20256)
        self.session = self.reconnect()
        self.call(2881, [130015])
        self.assertEqual((self.props(20259), self.props(20256) - stones, self.props(26412), self.props(26409)), (2, 200, 1, 1))
        self.assert_rejected(2881, recharge.ids([130015]))

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

    def test_actual_network_lua_serializes_real_materials_deducts_once_and_releases_busy_on_error(self):
        import test_activity_copy
        lua = test_activity_copy.ActivityCopyTests.network_lua(self)
        for name in ("treasurerefine_pb", "equiprefine_pb", "error_pb", "params_pb"):
            lua.execute(builder.read_script(name, "pb"))
        code = builder.read_script("gamedata").decode().replace("\r\n", "\n")
        start = code.index("function gamedata.equipData(")
        lua.execute(code[start:code.index("function gamedata.artifactData(", start)].encode())
        lua.execute(b'''gamedata.cache.equips={};gamedata.cache.props={[20256]={num=2000000}}
            gamedata.cache.role.coin=200000000
            gamedata.updateRoleCoin=function(self,n) self.cache.role.coin=self.cache.role.coin+n end
            gamedata.updateprops=function(self,p) self.cache.props[p.cid].num=self.cache.props[p.cid].num+p.num end
            gamedata.SomethingProcess=function(self,p)
                for _,e in ipairs(p.equips) do local v=self:equipData(e);self.cache.equips[v.iid]=v end
            end
            makeEquipsTemp=function() return gamedata.cache.equips end
            package.loaded.logError={errorMessage={},errorFunc={}};printf=function() end
            initPb=function(mod,fd) local m=mod.Ids();m:ParseFromString(fd.rbuf);return m end''')
        scripts = self.client_scripts()
        lua.execute(scripts["assets/scripts/GameTreasureUp.so"])
        lua.execute(scripts["assets/common_lua/GameErrorMessage.so"])
        self.assertIsNone(lua.globals().gameConfig)
        target, food = self.equip(refined=4), self.equip()
        lua.globals().gamedata[b"cache"][b"equips"][food] = lua.table_from({b"iid": food, b"cid": 25401})
        request = lua.table_from({b"iid": target, b"ids": lua.table_from([food]), b"xprops": lua.table_from([
            lua.table_from({b"cid": 1000, b"num": 80000}), lua.table_from({b"cid": 20256, b"num": 252})])})
        mode, opcode, body = lua.globals().UITreasureRefine2CallBack(request)
        self.assertEqual((mode, opcode, protocol.parse_ids_pb(body)), (1, 1119, [target, food]))
        self.assertEqual(lua.globals().UITreasureRefine2CallBack(request)[0], 0)
        result = lua.globals().NetTreasureRefine2CallBack(lua.table_from({b"rbuf": self.call(1119, [target, food])[0][16:]}))
        self.assertEqual((result[b"equip"][b"iid"], result[b"equip"][b"level2"]), (target, 5))
        self.assertIsNone(lua.globals().gamedata[b"cache"][b"equips"][food])
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"coin"], self.session.save["role_state"]["coin"])
        self.assertEqual(lua.globals().gamedata[b"cache"][b"props"][20256][b"num"], self.props(20256))
        lua.globals().gamedata[b"ext"][b"localTreasureBusy"] = True
        lua.globals().NetErrorMessageCallback9(lua.table_from({b"rbuf": recharge.ids([1119, 0])}))
        self.assertFalse(lua.globals().gamedata[b"ext"][b"localTreasureBusy"])

    def test_actual_refine_page_uses_configured_copy_count_and_ignores_late_other_target_callbacks(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("实际APK界面验证需要本机已有lupa.lua51")
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.globals().gamedata = lua.table_from({"config": self.config}, recursive=True)
        lua.execute('''print=function() end;printT=print;CCControlEventTouchUpInside=1
            requests={};UIRequest=function(t) requests[#requests+1]=t end
            gameTouch={clickprofbytime=function() end};CCSizeMake=function(w,h) return {width=w,height=h} end
            function node() return setmetatable({}, {__index=function(t,k)
                if k=="addHandleOfControlEvent" then return function(self,f) self.callback=f end end
                if k=="setString" then return function(self,v) self.text=v end end
                return function() end
            end}) end
            function items() return setmetatable({}, {__index=function(t,k) local n=node();rawset(t,k,n);return n end}) end
            CCBReaderLoad=function() return node(),items() end
            getAnimationManager=function() return node() end;gamedata.music={PlayOptSound=function() end}
            GameScene={roleinfo={coin=200000000},layers={},addUpdate=function() end,UpdatePresentLayer=function() end}
            gameConfig={strings={attr_type={atk="攻击",def="防御",hp="生命",critical="暴击"}}}
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            ui=setmetatable({setLabelString=function(n,v) if v then n:setString(v) end end,
                getIDandNUMs=function(s) local r={} for c,n in s:gmatch("(%d+),(%d+)") do r[#r+1]={cid=tonumber(c),num=tonumber(n)} end return r end},
                {__index=function() return function() end end})''')
        page = lua.execute(builder.read_script("Layer_treasureup").decode())
        page.rootItems = lua.globals()["items"]()
        page.data = lua.table_from({"iid": 1000201, "cid": 25401, "level1": 1, "level2": 4, "quality": 5})
        page.xtreasures = lua.table_from([lua.table_from({"iid": 1000202})])
        page.refinePropNum = 2000000
        page.setPage_refine(page)
        page.rootItems.refine_refineButton.callback()
        request = lua.globals().requests[len(lua.globals().requests)]
        self.assertEqual((request.type, request.iid, request.ids[1]), (1119, 1000201, 1000202))
        self.assertEqual([(request.xprops[i].cid, request.xprops[i].num) for i in range(1, 3)], [(1000, 80000), (20256, 252)])
        self.assertIn("10%", page.rootItems.refine_next_refine1.text)
        scripts = self.client_scripts()
        lua.execute(scripts["assets/scripts/UIEquips.so"].decode())
        page.ReloadData = lua.eval("function(self,data) self.refreshed=(self.refreshed or 0)+1 end")
        lua.globals().GameScene.layers.treasureup = lua.table_from({"show": True, "module": page})
        lua.globals().UITreasureRefine2(lua.table_from({"equip": {"iid": 99999, "cid": 25401}}, recursive=True))
        self.assertIsNone(page.refreshed)
        lua.globals().UITreasureRefine2(lua.table_from({"equip": {"iid": 1000201, "cid": 25401}}, recursive=True))
        self.assertEqual(page.refreshed, 1)
        self.assertFalse(any(lua.globals().requests[i].type in (10322, 1001) for i in range(1, len(lua.globals().requests)+1)))


if __name__ == "__main__":
    unittest.main()
