"""宝物升星：临时账号、真实配置费用、被动和原生回调。"""

import copy
from fractions import Fraction
import struct
import unittest
from unittest.mock import patch

import test_equip_evolve
import test_soul
from zyj_server import battle, formation, player, protocol, recharge, single_boss, training, treasure_refine


def setUpModule():
    test_soul.setUpModule()


class TreasureStarTests(unittest.TestCase):
    request = test_soul.SoulTests.request
    success = test_soul.SoulTests.success
    reconnect = test_soul.SoulTests.reconnect
    add_account = test_soul.SoulTests.add_account
    records = test_soul.SoulTests.records
    groups = test_soul.SoulTests.groups
    assert_rejected = test_soul.SoulTests.assert_rejected
    props = test_soul.SoulTests.props
    refresh = test_soul.SoulTests.refresh
    gen = test_soul.SoulTests.gen
    client_scripts = classmethod(test_soul.SoulTests.client_scripts.__func__)
    client_call = test_soul.SoulTests.client_call
    give = test_equip_evolve.EquipEvolveTests.give
    add_equip = test_equip_evolve.EquipEvolveTests.add_equip
    equip = test_equip_evolve.EquipEvolveTests.equip
    wear = test_equip_evolve.EquipEvolveTests.wear
    pay = test_equip_evolve.EquipEvolveTests.pay
    network_lua = test_equip_evolve.EquipEvolveTests.network_lua
    ui_lua = test_equip_evolve.EquipEvolveTests.ui_lua

    def setUp(self):
        test_soul.SoulTests.setUp(self)
        self.save["role_state"].update(level=150, coin=1000000000000)
        self.next_iid = 9900000
        for cid in (192153, 192154, 20256):
            self.give(cid, 1000000)

    def test_idle_star_charges_real_materials_once_preserves_fields_and_reconnects(self):
        iid = self.add_equip(cid=25401, extra=protocol.encode_pb_field(99, 2, b"preserve"))
        before = copy.deepcopy(self.save)
        body = self.pay(1127, iid)
        self.assertEqual(self.equip(iid)[11], 1)
        self.assertEqual(before["role_state"]["coin"] - self.save["role_state"]["coin"], 50000)
        self.assertEqual(self.props(192153), 999990)
        self.assertEqual(self.props(192154), 999999)
        self.assertFalse(any(n in (1, 2, 9) for n, w, v in protocol.iter_pb_fields(body)))
        self.assertEqual(self.save["role_state"]["power"], before["role_state"]["power"])
        raw = formation.records(bytes.fromhex(self.save["world_state"]["1002"]), 2, 1)[iid]
        self.assertIn((99, 2, b"preserve"), list(protocol.iter_pb_fields(raw)))
        self.reconnect(); self.refresh()
        self.assertEqual(self.equip(iid)[11], 1)

    def test_worn_star_has_real_attributes_and_removal_restores_previous_training(self):
        iid = self.add_equip(cid=25401)
        old_item = self.add_equip(cid=25101)
        self.wear(old_item)
        self.wear(iid)
        before = self.gen()
        self.pay(1127, iid)
        for name, field in (("atk", 6), ("def", 7), ("hp", 8)):
            self.assertEqual(protocol.pb_get_varint(self.gen(), field) - protocol.pb_get_varint(before, field),
                             self.config["treasure2_star"]["1"][name])
        self.wear(old_item)
        self.wear(iid)
        after = self.gen()
        self.wear(old_item)
        self.wear(iid)
        self.assertEqual(self.gen(), after)
        self.assertEqual(protocol.pb_get_varint(self.gen(), 17), protocol.pb_get_varint(before, 17))

    def test_unlock_refinement_gate_caps_and_wrong_targets_do_not_charge(self):
        iid = self.add_equip(cid=25401)
        self.save["role_state"]["level"] = 89
        self.assert_rejected(1127, values=[iid])
        self.save["role_state"]["level"] = 90
        for body in (b"", b"\x08", b"\x10\x01", recharge.ids([iid, iid]), recharge.ids([0])):
            self.assert_rejected(1127, raw=body)
        for cid, stars in ((25101, 0), (21403, 0), (25401, 15), (25510, 25)):
            other = self.add_equip(cid=cid, stage=30 if cid == 25510 else 15 if stars else 0, stars=stars)
            self.assert_rejected(1127, values=[other])
        gated = self.add_equip(cid=25401, stage=4, stars=4)
        self.assert_rejected(1127, values=[gated])
        data = self.equip(gated); data[3] = 5
        player.record_slot_update(self.save, protocol.encode_pb_field(2, 2, recharge.ids(data)))
        self.pay(1127, gated)
        self.assertEqual(self.equip(gated)[11], 5)

    def test_star_materials_funds_save_failure_and_retry_are_atomic(self):
        iid = self.add_equip(cid=25401)
        raw = recharge.ids([iid])
        before = copy.deepcopy(self.save)
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 1127, raw=raw)
        self.assertEqual(self.sessions[1].save, before)
        packets = self.request(1, 1127, raw=raw); self.refresh()
        self.assertEqual(packets[0][0], 1127)
        self.assertIn(1200, [mid for mid, _ in packets])
        self.assertIn(1001, [mid for mid, _ in packets])
        seq, body = self.sessions[1].random_replies[1127][0]
        retry = self.sessions[1].handle(1127, seq, body)
        self.assertEqual([(struct.unpack(">IIII", p[:16])[2], p[16:]) for p in retry], packets)
        gold = self.save["role_state"]["coin"]
        self.assert_rejected(1127, values=[iid, 1])
        self.assertEqual(self.save["role_state"]["coin"], gold)

    def test_rebirth_returns_verified_star_costs_and_native_service_fee(self):
        iid = self.add_equip(cid=25401)
        initial = self.props(192153)
        coin, gold = self.save["role_state"]["coin"], self.save["role_state"]["gold"]
        self.pay(1127, iid)
        self.success(1, 1117, values=[iid]); self.refresh()
        self.assertEqual(self.equip(iid)[11], 0)
        self.assertEqual(self.props(192153), initial)
        self.assertEqual(self.save["role_state"]["coin"], coin)
        self.assertEqual(self.save["role_state"]["gold"], gold - self.config["renascence"]["1"]["treasurestarcost"])

    def test_every_actual_star_profile_caps_and_next_costs_match_configuration(self):
        count = 0
        for row in self.config["equip"].values():
            if row["type"] not in ("horse", "treasure") or not row["adorn"] or not row["up_star"]:
                continue
            cap = row["up_star"]
            iid = self.add_equip(cid=row["id"], stage=row["maxlevel2"], stars=cap - 1)
            coin = self.save["role_state"]["coin"]
            costs = dict(tuple(map(int, entry.split(","))) for entry in self.config["treasure2_star"][str(cap)][f'cost_{row["quality"]}'].split(";") if entry)
            self.pay(1127, iid)
            self.assertEqual(self.equip(iid)[11], cap)
            self.assertEqual(coin - self.save["role_state"]["coin"], costs[1000])
            self.assert_rejected(1127, values=[iid])
            count += 1
        self.assertEqual(count, sum(row["type"] in ("horse", "treasure") and bool(row["adorn"] and row["up_star"]) for row in self.config["equip"].values()))
        self.assertGreater(count, 30)

    def test_skill_families_keep_prior_caps_and_only_use_generic_base_for_percentages(self):
        raw = self.gen()
        general = self.config["general"][str(protocol.pb_get_varint(raw, 1))]
        for cid, name, factor, probability in ((25401, "atk", Fraction(1, 2), (10, 100)),
                                                (26401, "def", Fraction(1), (13, 50))):
            for stars in (1, 6, 10, 11, 15, 16, 20, 21, 25, 26, 30, 31, 35):
                item = [9900100, cid, 1, 0, 0, 0, 0, 0, 0, 0, 0, stars, 0]
                result = treasure_refine.attributes(raw, item, self.config)
                for attr, field in (("atk", 6), ("def", 7), ("hp", 8)):
                    expected = self.config["treasure2_star"][str(stars)][attr]
                    if attr == name and stars >= 6:
                        base = battle.general_base(general, attr, protocol.pb_get_varint(raw, 3), protocol.pb_get_varint(raw, 4) or 0, self.config)
                        expected += int(base * factor * min(5, stars - 5) / 5)
                    if attr == "hp" and stars >= 26:
                        base = battle.general_base(general, attr, protocol.pb_get_varint(raw, 3), protocol.pb_get_varint(raw, 4) or 0, self.config)
                        expected += int(base * min(5, stars - 25) / 10)
                    self.assertEqual(result[field], expected)
                field, maximum = probability
                self.assertEqual(result[field], maximum * min(5, max(0, stars - 15)) // 5)
                skills = treasure_refine.star_skills(item, self.config)
                self.assertEqual(len(skills), sum(stars >= n for n in (6, 11, 16, 21, 26, 31)))

    def test_starred_targets_keep_growth_refinement_and_dedicated_team_bonuses(self):
        iid = self.add_equip(cid=25401, stage=10, stars=10)
        self.wear(iid)
        before = self.gen()
        world = bytes.fromhex(self.save["world_state"]["1002"])
        slots, equips = formation.records(world, 4, 2), formation.records(world, 2, 1)
        target = protocol.pb_get_varint(before, 2)
        grown, _, up = training.grow_general(before, 10000, slots[target], set(), equips, self.config, 150)
        self.assertTrue(up)
        old = treasure_refine.attributes(before, self.equip(iid), self.config)
        new = treasure_refine.attributes(grown, self.equip(iid), self.config)
        self.assertGreater(new[6], old[6])
        team = [target, 0, 0, 0, 0, 0, 0, 0]
        temporary, _ = single_boss.project_team(self.save, team, self.config)
        point = self.config["copy"]["42101"]["1"]
        actual, _ = battle.rosters(self.save, point, self.config)
        projected, _ = battle.rosters(temporary, point, self.config)
        self.assertEqual(actual[2]["treasure_passives"], projected[2]["treasure_passives"])
        self.assertEqual(actual[2]["atk"], projected[2]["atk"])

    def test_starred_food_is_protected_in_strengthening_refinement_and_resolve(self):
        target, food = self.add_equip(cid=25401, stage=4), self.add_equip(cid=25401, stars=1)
        self.assert_rejected(1119, values=[target, food])
        self.assert_rejected(1118, raw=protocol.encode_pb_field(1, 0, target) + protocol.encode_pb_field(2, 0, food))
        self.assert_rejected(1104, values=[food])
        self.assert_rejected(1117, values=[food])

    def test_actual_network_pb_costs_error_unlock_and_cross_training_lock(self):
        iid = self.add_equip(cid=25401)
        lua = self.network_lua()
        req = lua.table_from({b"iid": iid, b"props": lua.table_from([]), b"growthView": lua.table_from({b"generation": 7})})
        mode, opcode, raw = lua.globals().UITreasureStarUpCallBack(req)
        self.assertEqual((mode, opcode, protocol.parse_ids_pb(raw)), (1, 1127, [iid]))
        self.assertEqual(lua.globals().UITreasureStarUpCallBack(req)[0], 0)
        self.assertEqual(lua.globals().UITreasureRefine2CallBack(lua.table_from({b"iid": iid, b"ids": lua.table_from([])}))[0], 0)
        before = self.save["role_state"]["coin"]
        result = lua.globals().NetTreasureStarUpCallBack(lua.table_from({b"rbuf": self.success(1, 1127, raw=raw)}))
        self.refresh()
        cache = lua.globals().gamedata[b"cache"]
        self.assertEqual(cache[b"role"][b"coin"], before - 50000)
        self.assertEqual(cache[b"props"][192153][b"num"], self.props(192153))
        self.assertEqual(cache[b"props"][192154][b"num"], self.props(192154))
        self.assertEqual((result[b"growthIID"], result[b"growthView"][b"generation"]), (iid, 7))
        self.assertIsNone(lua.globals().gameConfig)
        lua.globals().UITreasureStarUpCallBack(req)
        lua.globals().NetErrorMessageCallback9(lua.table_from({b"rbuf": recharge.ids([1119, 0])}))
        self.assertIsNotNone(lua.globals().gamedata[b"ext"][b"localEquipGrowthBusy"])
        lua.globals().NetErrorMessageCallback9(lua.table_from({b"rbuf": recharge.ids([1127, 0])}))
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localEquipGrowthBusy"])

    def test_actual_star_ui_discards_closed_other_target_and_old_generation_replies(self):
        lua = self.ui_lua()
        lua.execute('''
            updateDataLife=function() end
            treasure={rootNode=node(),localEquipGrowthGeneration=1,selectpage="upstar",data={iid=9900010},
                ReloadData=function(self,t) self.received=(self.received or 0)+1 end}
            GameScene.layers.treasureup={show=true,module=treasure}
            UIRequest({type=1127,iid=9900010})
            local view=requests[#requests].growthView
            UITreasureStarUp({growthView=view,growthIID=9900010,equipdata={iid=9900010},props={}})
            assert(treasure.received==1)
            treasure.localEquipGrowthGeneration=2
            UITreasureStarUp({growthView=view,growthIID=9900010,equipdata={iid=9900010},props={}})
            assert(treasure.received==1)
            treasure.localEquipGrowthGeneration=1; treasure.data.iid=9900011
            UITreasureStarUp({growthView=view,growthIID=9900010,equipdata={iid=9900010},props={}})
            assert(treasure.received==1)
            treasure.data.iid=9900010; GameScene.layers.treasureup.show=false
            UITreasureStarUp({growthView=view,growthIID=9900010,equipdata={iid=9900010},props={}})
            assert(treasure.received==1)
        ''')

    def test_star_passives_are_real_pure_and_work_on_both_sides(self):
        def unit(iid, hp, attack=100, speed=200):
            return {"iid": iid, "cid": 10101, "level": 1, "advance": 0, "exp": 0, "atk": attack,
                    "def": 0, "hp": hp, "speed": speed, "skill": 12101, "initial_ap": 0}
        for sid, enemy_hp, expected in ((9001406, 100000, 110), (9001436, 1000, 110), (9001396, 100000, 110)):
            for direct in (True, False):
                actor = unit(1, 10000)
                actor["treasure_passives"] = [sid]
                teams = ({2: actor}, {2: unit(2, enemy_hp, attack=1, speed=1)})
                original = copy.deepcopy(teams)
                report = battle.simulate(*teams if direct else teams[::-1], self.config, 7, max_rounds=1)
                side = "defense" if direct else "attack"
                self.assertEqual(enemy_hp - report["endmeta"][side]["2"]["h"], expected)
                self.assertEqual(teams, original)

    def test_hp_step_passives_floor_each_ten_percent_without_using_overkill(self):
        def unit(iid, hp, atk, speed):
            return {"iid": iid, "cid": 10101, "level": 1, "advance": 0, "atk": atk,
                    "def": 0, "hp": hp, "speed": speed, "skill": 12101, "initial_ap": 0}
        for sid, results in ((9001420, (280, 280, 260)), (9001445, (100, 120, 120))):
            for first, expected in zip((99, 100, 101), results):
                actor = unit(1, 10000, 100, 100)
                actor["treasure_passives"] = [sid]
                for direct in (True, False):
                    teams = ({2: unit(3, 10000, first, 200), 8: actor}, {2: unit(2, 1000, 1, 1)})
                    report = battle.simulate(*(teams if direct else teams[::-1]), self.config, 7, max_rounds=1)
                    hp = report["endmeta"]["defense" if direct else "attack"]["2"]["h"]
                    self.assertEqual(1000 - hp - first, expected)

    def test_each_missing_cost_and_attribute_overflow_preserve_resources_and_receipts(self):
        iid = self.add_equip(cid=25401)
        baseline = copy.deepcopy(self.save)
        for cid, count in ((1000, 49999), (192153, 9), (192154, 0)):
            self.sessions[1].save = self.save = copy.deepcopy(baseline)
            if cid == 1000:
                self.save["role_state"]["coin"] = count
            else:
                player.change_item_count(self.save, cid, count - self.props(cid), self.config, self.now)
            self.assert_rejected(1127, values=[iid])
        self.sessions[1].save = self.save = copy.deepcopy(baseline)
        self.wear(iid)
        self.save["role_state"]["power"] = (1 << 31) - 1
        self.assert_rejected(1127, values=[iid])

    def test_packaged_star_and_refine_scripts_compile_without_ui_globals(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("宝物升星原生脚本编译需 lupa.lua51")
        lua = LuaRuntime()
        scripts = self.client_scripts()
        for name in ("GameEquipStage", "UIEquipStage", "GameTreasureUp", "Layer_treasureup", "UIProps"):
            lua.compile(scripts[f"assets/scripts/{name}.so"].decode())
