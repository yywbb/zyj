"""装备注灵：原生5521、真实材料、四件灵气及安全重生；只用临时账号。"""

import copy
from fractions import Fraction
import struct
import unittest
from unittest.mock import patch

import test_equip_evolve
from zyj_server import battle, equip_baptize, equip_evolve, formation, player, protocol, qiankun, recharge, single_boss, timebag


def setUpModule():
    test_equip_evolve.setUpModule()


class EquipInjectionTests(unittest.TestCase):
    request = test_equip_evolve.EquipEvolveTests.request
    success = test_equip_evolve.EquipEvolveTests.success
    reconnect = test_equip_evolve.EquipEvolveTests.reconnect
    assert_rejected = test_equip_evolve.EquipEvolveTests.assert_rejected
    add_account = test_equip_evolve.EquipEvolveTests.add_account
    refresh = test_equip_evolve.EquipEvolveTests.refresh
    props = test_equip_evolve.EquipEvolveTests.props
    gen = test_equip_evolve.EquipEvolveTests.gen
    give = test_equip_evolve.EquipEvolveTests.give
    add_equip = test_equip_evolve.EquipEvolveTests.add_equip
    equip = test_equip_evolve.EquipEvolveTests.equip
    wear = test_equip_evolve.EquipEvolveTests.wear
    pay = test_equip_evolve.EquipEvolveTests.pay
    foods = test_equip_evolve.EquipEvolveTests.foods
    client_scripts = classmethod(test_equip_evolve.EquipEvolveTests.client_scripts.__func__)
    network_lua = test_equip_evolve.EquipEvolveTests.network_lua
    ui_lua = test_equip_evolve.EquipEvolveTests.ui_lua

    def setUp(self):
        test_equip_evolve.EquipEvolveTests.setUp(self)
        self.give(20669, 1000000)

    def inject(self, iid, count=1):
        result = self.success(1, 5521, values=[iid, count])
        self.refresh()
        return result

    def test_native_request_charges_real_cost_updates_stats_once_and_survives_reconnect(self):
        iid = self.add_equip(extra=protocol.encode_pb_field(99, 2, b"keep"))
        self.wear(iid)
        before, stones, power = self.gen(), self.props(20669), self.save["role_state"]["power"]
        packets = self.request(1, 5521, values=[iid, 10])
        self.assertEqual(packets[0][0], 5521)
        self.assertIn(1200, [mid for mid, _ in packets])
        self.assertIn(1001, [mid for mid, _ in packets])
        self.refresh()
        self.assertEqual(self.equip(iid)[12], 10)
        expected = sum(equip_evolve.costs(self.config["equip_forgingConsume"][str(n)]["quality5"])[20669] for n in range(1, 11))
        self.assertEqual(self.props(20669), stones - expected)
        gain = int(self.config["equip"]["21403"]["forging_grow"] * 10)
        self.assertEqual(protocol.pb_get_varint(self.gen(), 6) - protocol.pb_get_varint(before, 6), gain)
        self.assertEqual(self.save["role_state"]["power"], power + gain)
        raw = formation.records(bytes.fromhex(self.save["world_state"]["1002"]), 2, 1)[iid]
        self.assertIn((99, 2, b"keep"), list(protocol.iter_pb_fields(raw)))
        snapshot, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        retry = self.sessions[1].handle(5521, self.seq, recharge.ids([iid, 10]))
        self.assertEqual([(struct.unpack(">IIII", p[:16])[2], p[16:]) for p in retry], packets)
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (snapshot, disk))
        self.reconnect()
        self.refresh()
        self.assertEqual(self.equip(iid)[12], 10)
        self.assertEqual(self.gen(), formation.records(bytes.fromhex(snapshot["world_state"]["1002"]), 1, 2)[protocol.pb_get_varint(before, 2)])

    def test_strict_payload_unlock_ownership_cap_materials_and_save_failure_are_atomic(self):
        iid = self.add_equip()
        for raw in (b"", b"\x08", b"\x10\x01", b"\x0a\x00", recharge.ids([iid]), recharge.ids([iid, 0]),
                    recharge.ids([iid, 11]), recharge.ids([iid, 1, 1]), recharge.ids([iid, 1]) + b"\x10\x01"):
            self.assert_rejected(5521, raw=raw)
        self.save["role_state"]["level"] = 39
        self.assert_rejected(5521, values=[iid, 1])
        self.save["role_state"]["level"] = 40
        self.sessions[2].save["role_state"]["level"] = 150
        self.assert_rejected(5521, account=2, values=[iid, 1])
        for _ in range(4):
            self.inject(iid, 10)
        self.assert_rejected(5521, values=[iid, 1])
        self.save["role_state"]["level"] = 41
        self.assert_rejected(5521, values=[iid, 2])
        self.inject(iid)
        self.save["role_state"]["level"] = 150
        player.change_item_count(self.save, 20669, -self.props(20669), self.config, self.now)
        self.assert_rejected(5521, values=[iid, 10])
        self.give(20669, 1)
        self.assert_rejected(5521, values=[iid, 10])
        self.give(20669, 1000)
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 5521, values=[iid, 10])
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))

    def test_four_worn_items_use_lowest_five_level_tier_not_missing_slots_or_cumulative_tiers(self):
        original = formation.records(bytes.fromhex(self.save["world_state"]["1002"]), 4, 1)[1]
        iids = [self.add_equip(cid) for cid in (21201, 22201, 23201, 24201)]
        for iid in iids:
            self.wear(iid)
        for iid in iids[:3]:
            self.inject(iid, 5)
        before = self.gen()
        self.inject(iids[3], 5)
        tier = self.config["equip_foringlv"]["5"]
        for field, name in ((6, "atk"), (7, "def"), (8, "hp")):
            personal = self.config["equip"]["24201"]["forging_grow"] * 5 if field == 8 else 0
            self.assertEqual(protocol.pb_get_varint(self.gen(), field) - protocol.pb_get_varint(before, field), tier[name] + personal)
        for iid in iids:
            self.inject(iid, 5)
        world = bytes.fromhex(self.save["world_state"]["1002"])
        slot = formation.records(world, 4, 1)[1]
        equips = formation.records(world, 2, 1)
        values = equip_evolve.attributes(self.gen(), slot, equips, self.config)
        singles = {f: sum(equip_evolve.attributes(self.gen(), protocol.encode_pb_field(n, 0, protocol.pb_get_varint(slot, n)), equips, self.config)[f]
                          for n in range(4, 8)) for f in range(6, 17)}
        for field, name in ((6, "atk"), (7, "def"), (8, "hp")):
            self.assertEqual(values[field] - singles[field], self.config["equip_foringlv"]["10"][name])
        # 换回零注灵武器时，整个四件灵气消失，其他三件的单件加成保留。
        self.wear(protocol.pb_get_varint(original, 4))
        current = self.gen()
        self.wear(iids[0])
        self.assertGreater(protocol.pb_get_varint(self.gen(), 6), protocol.pb_get_varint(current, 6))

    def test_all_112_real_profiles_validate_exact_single_piece_growth_and_caps(self):
        profiles = [r for r in self.config["equip"].values() if r["forging_maxlevel"]]
        self.assertEqual(len(profiles), 112)
        for row in profiles:
            for level in (1, 5, 40, 149, 150):
                item = [9900001, row["id"], 1] + [0] * 9 + [level]
                equip_baptize.validate(item, self.config)
                slot = protocol.encode_pb_field(4 + equip_evolve.KINDS.index(row["type"]), 0, item[0])
                values = equip_evolve.attributes(self.gen(), slot, {item[0]: recharge.ids(item)}, self.config)
                item[12] = 0
                plain = equip_evolve.attributes(self.gen(), slot, {item[0]: recharge.ids(item)}, self.config)
                field = equip_evolve.FIELDS[row["forging_attr"]]
                self.assertEqual(values[field] - plain[field], int(Fraction(str(row["forging_grow"])) * level))
            item[12] = 151
            with self.assertRaises(ValueError):
                equip_baptize.validate(item, self.config)
        for cid in (21101, 25101, 26101):
            iid = self.add_equip(cid)
            self.assert_rejected(5521, values=[iid, 1])

    def test_injected_items_keep_growth_wash_evolution_battle_and_receipted_rebirth(self):
        iid = self.add_equip()
        self.inject(iid, 10)
        self.wear(iid)
        self.foods(21403, 1)
        self.pay(1122, iid)
        self.pay(1123, iid)
        self.success(1, 1101, raw=protocol.encode_pb_field(1, 0, iid))
        self.refresh()
        self.success(1, 1120, values=[iid, 1, 1])
        self.refresh()
        token = equip_baptize.get_state(self.save, self.config)["pending"][str(iid)]["token"]
        self.assert_rejected(5521, values=[iid, 1])
        self.success(1, 1121, values=[0, iid, token])
        self.refresh()
        self.assertEqual(self.equip(iid)[12], 10)
        before = self.gen()
        giid = protocol.pb_get_varint(before, 2)
        self.give(20199, 1)
        self.success(1, 1038, raw=protocol.encode_pb_field(1, 0, giid) + b"".join(protocol.encode_pb_field(2, 0, n) for n in (0, 0, 0, 1)))
        self.refresh()
        self.assertGreaterEqual(protocol.pb_get_varint(self.gen(), 6), protocol.pb_get_varint(before, 6))
        self.success(1, 3702, values=[140, 1])
        self.refresh()
        temporary, _ = single_boss.project_team(self.save, self.save["single_boss_state"]["teams"]["1"], self.config)
        self.assertEqual(formation.records(bytes.fromhex(temporary["world_state"]["1002"]), 1, 2)[giid], self.gen())
        attack, _ = battle.rosters(self.save, self.config["copy"]["42101"]["1"], self.config)
        self.assertEqual(attack[2]["atk"], protocol.pb_get_varint(self.gen(), 6))
        replacement = self.add_equip(21201)
        self.wear(replacement)
        receipt = copy.deepcopy(qiankun.get_state(self.save)["receipts"][f"equip:{iid}"])
        gold, stones = self.save["role_state"]["gold"], self.props(20669)
        fee = equip_evolve.rebirth_fee(self.equip(iid), self.config)
        self.assertGreaterEqual(fee, self.config["renascence"]["10"]["injection"])
        self.pay(1117, iid)
        self.assertEqual(self.equip(iid), protocol.parse_ids_pb(bytes.fromhex(receipt["before"])))
        self.assertEqual(self.props(20669), stones + dict(receipt["costs"])[20669])
        self.assertEqual(self.save["role_state"]["gold"], gold - fee)
        unknown = self.add_equip()
        item = self.equip(unknown)
        item[12] = 1
        player.record_slot_update(self.save, protocol.encode_pb_field(2, 2, recharge.ids(item)))
        self.assert_rejected(1117, values=[unknown])

    def test_bad_costs_overflow_and_unmatched_comb_never_change_items_or_charge(self):
        iid = self.add_equip()
        self.wear(iid)
        for text in ("", "20669,-1;", "999999,1;", "20669,2147483648;"):
            with patch.dict(self.config["equip_forgingConsume"]["1"], {"quality5": text}):
                self.assert_rejected(5521, values=[iid, 1])
        before = self.gen()
        raw = protocol.pb_set_varint(before, 6, (1 << 31) - 1)
        player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, raw))
        self.assert_rejected(5521, values=[iid, 1])
        player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, before))
        comb = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 5521)
                                       + protocol.encode_pb_field(2, 2, recharge.ids([iid, 1])))
        self.assert_rejected(999900, raw=comb)

    def test_injection_gift_uses_real_guide_and_configured_payment_once_only(self):
        gid = 130019
        self.assert_rejected(2882, values=[gid])
        steps = self.sessions[1].step_counts[79]
        for step in range(1, steps + 1):
            self.success(1, 201, raw=protocol.encode_pb_field(1, 0, 79) + protocol.encode_pb_field(2, 0, step))
        self.refresh()
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 2882, values=[gid])), [gid, 0, 43200])
        self.refresh()
        self.assert_rejected(2881, values=[gid])
        tier = int(self.config["trigger_gift2"][str(gid)]["recharge_id"])
        raw = b"".join(protocol.encode_pb_field(1, 2, recharge.ids([v])) for v in (tier, gid))
        reply = self.success(1, 115, raw=raw)
        order = next(v for n, w, v in protocol.iter_pb_fields(reply) if (n, w) == (1, 2))
        self.refresh()
        gold = self.save["role_state"]["gold"]
        self.success(1, 116, values=[protocol.pb_get_varint(order, 1)])
        self.refresh()
        self.assertEqual(self.save["role_state"]["gold"], gold)
        self.reconnect()
        self.refresh()
        stones = self.props(20669)
        self.pay(2881, gid)
        self.assertEqual(self.props(20669), stones + 50)
        self.assertTrue(timebag.get_state(self.save, gid)["claimed"])
        self.assert_rejected(2881, values=[gid])

    def test_actual_network_computes_its_own_prices_charges_once_and_shares_equipment_lock(self):
        iid = self.add_equip()
        self.wear(iid)
        lua = self.network_lua()
        code = self.client_scripts()["assets/scripts/gamedata.so"].decode()
        start = code.index("function gamedata.isEquipOn(")
        lua.execute(code[start:code.index("\nfunction ", start+1)].encode())
        fd = lambda raw: lua.table_from({b"rbuf": raw})
        req = lua.table_from({b"iid": iid, b"count": 10, b"props": lua.table_from([]),
                              b"growthView": lua.table_from({b"generation": 7})})
        mode, opcode, raw = lua.globals().UIEquipCastCallBack(req)
        self.assertEqual((mode, opcode, protocol.parse_ids_pb(raw)), (1, 5521, [iid, 10]))
        self.assertEqual(lua.globals().UIEquipCastCallBack(req)[0], 0)
        self.assertEqual(lua.globals().UIEquipStrengthenCallBack(lua.table_from({b"iid": iid, b"xcoin": 0}))[0], 0)
        self.assertEqual(lua.globals().UIChangeSlotCallBack(lua.table_from({b"pos1": 1, b"pos2": 2}))[0], 0)
        self.assertEqual(lua.globals().UISoulHuntCallBack(lua.table_from({b"param": 1}))[0], 0)
        lua.globals().NetErrorMessageCallback9(fd(recharge.ids([1122, 0])))
        self.assertIsNotNone(lua.globals().gamedata[b"ext"][b"localEquipGrowthBusy"])
        stones = self.props(20669)
        packets = self.request(1, 5521, raw=raw)
        self.refresh()
        result = lua.globals().NetEquipCastCallBack(fd(packets[0][1]))
        self.assertEqual((result[b"equip"][b"level4"], result[b"growthIID"], result[b"growthView"][b"generation"]), (10, iid, 7))
        self.assertEqual(lua.globals().gamedata[b"cache"][b"props"][20669][b"num"], self.props(20669))
        self.assertLess(self.props(20669), stones)
        lua.globals().NetEquipCastCallBack(fd(packets[0][1]))
        self.assertEqual(lua.globals().gamedata[b"cache"][b"props"][20669][b"num"], self.props(20669))
        absolute = next(raw for mid, raw in packets if mid == 1200)
        lua.globals().NetPropListCallback(fd(absolute))
        self.assertEqual(lua.globals().gamedata[b"cache"][b"props"][20669][b"num"], self.props(20669))
        self.assertEqual(lua.globals().UIEquipCastCallBack(req)[0], 1)
        lua.globals().NetErrorMessageCallback9(fd(recharge.ids([5521, 0])))
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localEquipGrowthBusy"])
        self.assertEqual(lua.globals().UIEquipCastCallBack(req)[0], 1)
        self.assertIsNone(lua.globals().gameConfig)

    def test_actual_ui_reply_and_material_reads_ignore_closed_replaced_and_reentered_pages(self):
        lua = self.ui_lua()
        lua.execute(self.client_scripts()["assets/scripts/UIEquips.so"].decode())
        lua.execute(self.client_scripts()["assets/scripts/UIProps.so"].decode())
        lua.execute('''page.selectpage="cast"
            page.reloaddata=function(self,t) self.received=(self.received or 0)+1 end
            page.setCSpendPropsData=function(self,t) self.materials=(self.materials or 0)+1 end''')
        old = lua.globals().LocalEquipGrowthContext()
        payload = lua.table_from({"type": 5521, "growthView": old, "growthIID": 9900001,
                                  "equip": {"iid": 9900001, "cid": 21403, "level4": 1}}, recursive=True)
        props = lua.table_from({"order": 14004, "growthView": old, "nums": {"20669": 100}}, recursive=True)
        for change in ("page.data.iid=9900002", "page.data.iid=9900001;page.selectpage='up'",
                       "page.selectpage='cast';page.localEquipGrowthGeneration=2",
                       "page.localEquipGrowthGeneration=1;GameScene.layers.equipsup.show=false"):
            lua.execute(change)
            lua.globals().UIEquipCast(payload)
            lua.globals().UIPropQueryById(props)
            self.assertIsNone(lua.globals().page.received)
            self.assertIsNone(lua.globals().page.materials)
        lua.execute("GameScene.layers.equipsup.show=true")
        lua.globals().UIEquipCast(payload)
        lua.globals().UIPropQueryById(props)
        self.assertEqual((lua.globals().page.received, lua.globals().page.materials), (1, 1))
        lua.globals().UIRequest(lua.table_from({"type": 5521, "iid": 9900001, "count": 1}))
        self.assertIsNotNone(lua.globals().requests[1].growthView)
        self.assertFalse(any(r.type in (1001, 10322) for r in lua.globals().requests.values()))

    def cast_page(self):
        lua = self.ui_lua()
        module = lua.execute(self.client_scripts()["assets/scripts/Layer_equip_up.so"].decode())
        lua.globals().page = module
        lua.globals().GameScene.layers.equipsup.module = module
        lua.execute('''page.rootNode=node();page.rootItems=items();page.localEquipGrowthGeneration=1
            page.selectpage="cast";page.sid=1;page.hasup=0
            page.setEquipIcons=function() end
            page.data={iid=9900001,cid=21403,quality=5,level1=1,level2=0,level3=0,level4=68,type="weapon"}
            page.castProps={["20669"]=1000000}
            page.slotequips={["1"]={equips={weapon=table.copy(page.data)}}}''')
        return lua

    def test_actual_cast_controls_clip_batch_to_level_cap_and_do_not_act_from_stale_generation(self):
        lua = self.cast_page()
        page = lua.globals().page
        page.setPage_Cast(page)
        lua.execute("requests={}")
        page.rootItems.cast_addButton.callback()
        req = lua.globals().requests[1]
        self.assertEqual((req.type, req.iid, req.count), (5521, 9900001, 2))
        expected = sum(equip_evolve.costs(self.config["equip_forgingConsume"][str(n)]["quality5"])[20669] for n in (69, 70))
        self.assertEqual(req.props[1].num, expected)
        page.localEquipGrowthGeneration = 2
        page.rootItems.cast_upButton.callback()
        page.rootItems.cast_addButton.callback()
        self.assertEqual(len(lua.globals().requests), 1)

    def test_actual_aura_display_requires_four_worn_iids_and_late_animation_cannot_touch_new_page(self):
        lua = self.cast_page()
        page = lua.globals().page
        page.data.level4 = 10
        # 同CID的闲置装备不能覆盖正在穿戴的另一IID。
        lua.execute('''page.slotequips["1"].equips={
            weapon={iid=9900002,cid=21403,quality=5,level4=5,type="weapon"},
            armor={iid=9900003,cid=22201,quality=3,level4=5,type="armor"},
            head={iid=9900004,cid=24201,quality=3,level4=5,type="head"}}
            page:showAllEquipCast()''')
        self.assertEqual(page.rootItems.activationlv.text, 0)
        self.assertEqual(page.slotequips["1"].equips.weapon.level4, 5)
        lua.execute('''page.slotequips["1"].equips.accessory={iid=9900005,cid=23201,quality=3,level4=5,type="accessory"}
            page:showAllEquipCast()''')
        self.assertEqual(page.rootItems.activationlv.text, 1)
        lua.execute('''managers={};loads=0
            CCBReaderLoad=function() loads=loads+1;return node(),items() end
            getAnimationManager=function() local n=node();managers[#managers+1]=n;return n end
            page.hasup=1;page:setPage_Cast()''')
        first = lua.globals().managers[1].callback
        first()
        second = lua.globals().managers[2].callback
        page.localEquipGrowthGeneration = 2
        page.hasup = 1
        page.setPage_Cast(page)
        loads = lua.globals().loads
        first()
        second()
        self.assertEqual(lua.globals().loads, loads)
