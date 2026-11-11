from contextlib import redirect_stdout
import copy
import io
import json
import struct
import unittest
from unittest.mock import patch
import zipfile

import build_local_apk as builder
import test_penglai
from zyj_server import battle, formation, player, protocol, recharge, recruit, replay, single_boss


NOW = test_penglai.NOW


class SigilTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        test_penglai.PenglaiTests.setUpClass.__func__(cls)
        cls.baseline = copy.deepcopy(cls.baseline)
        cls.baseline["role_state"].update(level=27, coin=5000000, gold=10000)

    reconnect = test_penglai.PenglaiTests.reconnect
    call = test_penglai.PenglaiTests.call
    give = test_penglai.PenglaiTests.give
    props = test_penglai.PenglaiTests.props
    assert_rejected = test_penglai.PenglaiTests.assert_rejected

    def setUp(self):
        test_penglai.PenglaiTests.setUp(self)
        self.next_iid = 4000100

    def gems(self):
        return {iid: protocol.parse_ids_pb(raw) for iid, raw in
                formation.records(bytes.fromhex(self.session.save["world_state"]["1002"]), 7, 1).items()}

    def gem(self, cid, exp=0):
        self.next_iid += 1
        row = self.config["sigil"][str(cid)]
        player.record_slot_update(self.session.save, protocol.encode_pb_field(7, 2, recharge.ids([self.next_iid, cid, row["level"], exp])))
        return self.next_iid

    def grid(self, row=1):
        raw = next(v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(self.session.save["world_state"]["1002"])) if n == row + 7 and w == 2)
        return protocol.parse_ids_pb(raw)

    def persist(self):
        self.path.write_text(json.dumps(self.session.save))

    def outer(self, level=5, row=1):
        for kind in range(1, 6):
            iid = self.gem(33000 + (kind - 1) * 15 + level)
            self.call(1141, [row * 10 + kind, iid])

    def generals(self):
        return formation.records(bytes.fromhex(self.session.save["world_state"]["1002"]), 1, 2)

    def test_equipped_sigils_affect_all_active_partners_not_idle_and_preserve_assets(self):
        iid = self.gem(33001)
        before, generals = copy.deepcopy(self.session.save), self.generals()
        packets = self.call(1141, [11, iid])
        self.assertEqual(self.grid()[:5], [iid, 0, 0, 0, 0])
        active = {i for i in formation.records(bytes.fromhex(before["world_state"]["1002"]), 4, 2) if i}
        for key, raw in self.generals().items():
            self.assertEqual(protocol.pb_get_varint(raw, 6), protocol.pb_get_varint(generals[key], 6) + (197 if key in active else 0))
        self.assertEqual(self.session.save["role_state"]["power"] - before["role_state"]["power"], 197 * len(active))
        self.assertIn(205, [struct.unpack(">IIII", p[:16])[2] for p in packets])
        for name in ("coin", "gold", "stamina", "energy", "level", "exp"):
            self.assertEqual(self.session.save["role_state"][name], before["role_state"][name])
        self.assertEqual(self.session.save["world_state"]["1300"], before["world_state"]["1300"])
        self.assertNotIn("22", self.session.save["guide"]["sections"])

    def test_replace_remove_reconnect_and_unlocked_rows_do_not_duplicate_bonuses(self):
        first, second = self.gem(33001), self.gem(33002)
        original = self.session.save["role_state"]["power"]
        self.call(1141, [11, first])
        self.call(1141, [11, second])
        self.assertIn(first, self.gems())
        saved = copy.deepcopy(self.session.save)
        self.call(1141, [11, second])
        self.assertEqual(self.session.save["role_state"], saved["role_state"])
        self.session = self.reconnect()
        self.assertEqual(self.grid()[0], second)
        self.call(1141, [11, 0])
        self.assertEqual(self.session.save["role_state"]["power"], original)
        self.assert_rejected(1141, recharge.ids([21, first]))
        self.session.save["role_state"]["level"] = 29
        self.call(1141, [21, first])
        self.assert_rejected(1141, recharge.ids([11, first]))

    def test_king_socket_requires_five_level_five_sigils_and_cannot_be_orphaned(self):
        king = self.gem(33076)
        self.assert_rejected(1141, recharge.ids([16, king]))
        self.outer()
        self.assertEqual(self.grid()[5], 0)
        self.call(1141, [16, king])
        self.assertEqual(self.grid()[5], king)
        self.assert_rejected(1141, recharge.ids([11, self.gem(33001)]))
        self.assert_rejected(1141, recharge.ids([11, 0]))
        self.call(1141, [16, 0])
        self.call(1141, [11, 0])
        self.assertEqual(self.grid()[5], (1 << 64) - 1)

    def test_upgrade_consumes_same_type_idle_materials_retains_iid_and_last_overflow(self):
        target = self.gem(33001, 3)
        food = self.gem(33003, 2)
        self.call(1141, [11, target])
        before = copy.deepcopy(self.session.save)
        self.call(1140, [target, food])
        self.assertEqual(self.gems()[target], [target, 33003, 3, 10])
        self.assertNotIn(food, self.gems())
        self.assertEqual(self.grid()[0], target)
        self.assertEqual(self.session.save["role_state"]["gold"], before["role_state"]["gold"])
        self.session = self.reconnect()
        self.assertEqual(self.gems()[target][3], 10)
        self.assert_rejected(1140, recharge.ids([target, food]))

    def test_king_gate_banks_final_material_exp_and_can_release_it_without_new_food(self):
        self.outer(5)
        target, food = self.gem(33082), self.gem(33085)
        self.call(1141, [16, target])
        self.call(1140, [target, food])
        self.assertEqual(self.gems()[target][1:], [33083, 8, 2240])
        self.assert_rejected(1140, recharge.ids([target, self.gem(33076)]))
        self.outer(8)
        self.call(1140, [target])
        self.assertEqual(self.gems()[target][1:], [33084, 9, 1600])
        self.outer(9)
        self.call(1140, [target])
        self.assertEqual(self.gems()[target][1:], [33085, 10, 320])
        self.assert_rejected(1140, recharge.ids([target]))

    def test_single_target_upgrade_auto_consumes_idle_same_type_materials_when_no_banked_exp(self):
        target = self.gem(33001)
        self.call(1141, [11, target])
        food1 = self.gem(33001)
        food2 = self.gem(33002)
        diff_type = self.gem(33016)
        self.call(1140, [target])
        self.assertEqual(self.gems()[target][1:], [33003, 3, 0])
        self.assertNotIn(food1, self.gems())
        self.assertNotIn(food2, self.gems())
        self.assertIn(diff_type, self.gems())
        self.assert_rejected(1140, recharge.ids([target]))

    def test_batch_upgrade_stops_at_king_gate_and_max_level_keeping_surplus_foods(self):
        self.outer(8)
        target, foods = self.gem(33082), [self.gem(33082) for _ in range(4)]
        self.call(1141, [16, target])
        self.call(1140, [target] + foods)
        self.assertEqual(self.gems()[target][1:], [33084, 9, 0])
        self.assertEqual([food in self.gems() for food in foods], [False, False, False, True])
        self.assert_rejected(1140, recharge.ids([target, self.gem(33076)]))
        target, foods = self.gem(33014), [self.gem(33013) for _ in range(5)]
        self.call(1141, [11, target])
        self.call(1140, [target] + foods)
        self.assertEqual(self.gems()[target][1:], [33015, 15, 0])
        self.assertEqual([food in self.gems() for food in foods], [False, False, True, True, True])
        self.assert_rejected(1140, recharge.ids([target, self.gem(33014)]))

    def test_surplus_foods_after_max_level_are_never_validated_or_consumed(self):
        # 一键添加一次提交至多 8 枚材料；前两枚把目标推到满级后，其余材料
        # 必须原样留在库存，不能再逐个校验，否则整批已结算结果会被回滚。
        target = self.gem(33014)
        self.call(1141, [11, target])
        foods = [self.gem(33013) for _ in range(2)]
        maxed, other, unowned = self.gem(33015), self.gem(33031), 999999
        self.call(1140, [target] + foods + [maxed, other, unowned])
        self.assertEqual(self.gems()[target][1:3], [33015, 15])
        self.assertFalse(any(food in self.gems() for food in foods))
        self.assertIn(maxed, self.gems())
        self.assertIn(other, self.gems())

    def test_surplus_foods_after_king_gate_are_never_validated_or_consumed(self):
        # 符之王越过外围等级门槛同理：门槛之后的满级材料不得让整批请求失败。
        self.outer(8)
        king = self.gem(33082)
        self.call(1141, [16, king])
        foods = [self.gem(33082) for _ in range(3)]
        maxed = self.gem(33090)
        self.call(1140, [king] + foods + [maxed])
        self.assertEqual(self.gems()[king][1:3], [33084, 9])
        self.assertFalse(any(food in self.gems() for food in foods))
        self.assertIn(maxed, self.gems())

    def test_invalid_materials_and_unowned_targets_never_consume(self):
        target, first = self.gem(33014), self.gem(33014)
        self.call(1141, [11, target])
        for values in ([target, target], [target, first, first], [target, self.gem(33016)],
                       [target, self.gem(33015)], [999999, first]):
            self.assert_rejected(1140, recharge.ids(values))
        surplus = self.gem(33001)
        self.call(1140, [target, first, surplus])
        self.assertEqual(self.gems()[target][1:3], [33015, 15])
        self.assertIn(surplus, self.gems())
        self.assert_rejected(1140, recharge.ids([target, self.gem(33001)]))
        idle = self.gem(33001)
        self.assert_rejected(1140, recharge.ids([idle, self.gem(33001)]))
        self.session.save["role_state"]["level"] = 29
        self.call(1141, [21, idle])
        self.assert_rejected(1140, recharge.ids([idle, target]))

    def test_strict_parameters_locked_features_and_unmatched_comb_are_atomic(self):
        iid = self.gem(33001)
        for opcode in (1140, 1141, 6405, 6406):
            for body in (b"\x08", b"\x0a\x00", b"\x10\x01", recharge.ids([1 << 31])):
                with self.subTest(opcode=opcode, body=body.hex()):
                    self.assert_rejected(opcode, body)
        for values in ([10, iid], [17, iid], [81, iid], [11, 999999], [12, iid], [11, iid, 0]):
            self.assert_rejected(1141, recharge.ids(values))
        self.session.save["role_state"]["level"] = 26
        self.assert_rejected(1141, recharge.ids([11, iid]))
        self.session.save["role_state"]["level"] = 27
        comb = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 1141) + protocol.encode_pb_field(2, 2, recharge.ids([11, iid])))
        self.assert_rejected(999900, comb)

    def test_success_retry_and_save_failures_never_publish_half_updates(self):
        target, food = self.gem(33001), self.gem(33001)
        body = recharge.ids([11, target])
        packets = self.session.handle(1141, 900, body)
        memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        self.assertEqual(self.session.handle(1141, 900, body), packets)
        self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))
        for opcode, values in ((1141, [11, 0]), (1140, [target, food])):
            with self.subTest(opcode=opcode), patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
                self.call(opcode, values)
            self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))

    def test_auto_settings_are_read_only_until_next_initialization_and_preserve_equipped_items(self):
        self.assertEqual(protocol.parse_ids_pb(self.call(6405)[0][16:]), [0, 5])
        self.assert_rejected(6406, recharge.ids([1, 5]))
        self.session.save["role_state"]["level"] = 80
        target = self.gem(33001)
        self.call(1141, [11, target])
        food, spare = self.gem(33001), self.gem(33016)
        for values in ([2, 5], [1, 6], [1, 15], [1, 5, 0]):
            self.assert_rejected(6406, recharge.ids(values))
        self.call(6406, [1, 5])
        self.call(1002)
        self.assertIn(food, self.gems())
        self.session = self.reconnect()
        self.call(1002)
        self.assertEqual(self.gems()[target][1], 33002)
        self.assertEqual(self.grid()[0], target)
        self.assertNotIn(food, self.gems())
        self.assertIn(spare, self.gems())
        before = copy.deepcopy(self.session.save)
        later = self.gem(33002)
        self.call(1002)
        self.assertIn(later, self.gems())
        self.assertEqual(self.session.save["role_state"], before["role_state"])

    def test_fractional_critical_and_fixed_damage_reach_every_current_battle_team(self):
        critical, damage = self.gem(33046), self.gem(33061)
        self.call(1141, [14, critical])
        self.call(1141, [15, damage])
        attack, defense = battle.rosters(self.session.save, self.config["copy"]["42102"]["1"], self.config)
        for unit in attack.values():
            self.assertEqual(unit["pet_rates"]["critical"], 0.5)
            self.assertEqual(unit["flat_out"], 117)
        before = copy.deepcopy(self.session.save)
        team = protocol.parse_ids_pb(self.call(3702, [140, 1])[0][16:])[:8]
        temporary, _ = single_boss.project_team(self.session.save, team, self.config)
        projected, _ = battle.rosters(temporary, self.config["copy"]["42102"]["1"], self.config)
        self.assertEqual([(u["atk"], u["pet_rates"]["critical"], u["flat_out"]) for u in projected.values()],
                         [(u["atk"], u["pet_rates"]["critical"], u["flat_out"]) for u in attack.values()])
        report = battle.simulate(attack, defense, self.config, 7)
        self.assertEqual(report, battle.simulate(attack, defense, self.config, 7))
        self.assertEqual(self.session.save["world_state"], before["world_state"])

    def test_new_and_departing_main_members_gain_and_lose_the_global_bonus_once(self):
        gem = self.gem(33001)
        self.call(1141, [11, gem])
        general = recruit.new_general(10201, 2000999, self.config)
        player.record_slot_update(self.session.save, protocol.encode_pb_field(1, 2, general))
        body = protocol.encode_pb_field(1, 0, 2) + protocol.encode_pb_field(3, 0, 2000999)
        self.assertEqual(struct.unpack(">IIII", self.session.handle(1003, 900, body)[0][:16])[2], 1003)
        attack = protocol.pb_get_varint(self.generals()[2000999], 6)
        self.call(1141, [11, 0])
        self.assertEqual(protocol.pb_get_varint(self.generals()[2000999], 6), attack - 197)
        self.call(1141, [11, gem])
        self.assertEqual(protocol.pb_get_varint(self.generals()[2000999], 6), attack)
        self.call(1009, [2, 1, 0, 0, 0, 0, 0])
        self.assertEqual(protocol.pb_get_varint(self.generals()[2000999], 6), attack)

    def test_all_ninety_rows_and_fourteen_upgrade_links_per_type_are_supported(self):
        self.session.save["role_state"]["level"] = 50
        self.outer(15)
        for kind in range(1, 7):
            target = self.gem(33000 + (kind - 1)*15 + 1)
            if kind == 6:
                self.call(1141, [16, target])
            else:
                self.call(1141, [21 + kind - 1, target])
            for level in range(1, 15):
                row = self.config["sigil"][str(33000 + (kind - 1)*15 + level)]
                food = self.gem(row["id"])
                self.call(1140, [target, food])
                self.assertEqual(self.gems()[target][1:3], [row["nextid"], level + 1])
        self.assertEqual(len(self.config["sigil"]), 90)

    def test_corrupt_inventory_grid_settings_and_overflow_fail_closed(self):
        target = self.gem(33001)
        self.call(1141, [11, target])
        saved = copy.deepcopy(self.session.save)
        for value in ([target, 33001, 2, 0], [target, 33001, 1, 5], [target, 33001, 1, 1 << 31]):
            self.session.save = copy.deepcopy(saved)
            player.record_slot_update(self.session.save, protocol.encode_pb_field(7, 2, recharge.ids(value)))
            self.persist()
            disk = self.path.read_bytes()
            with self.subTest(value=value), self.assertRaisesRegex(ValueError, "魔符"):
                self.reconnect()
            self.assertEqual(self.path.read_bytes(), disk)
        for changes in ({"auto_state": True}, {"auto_level": 6}):
            self.session.save = copy.deepcopy(saved)
            self.session.save["sigil_state"].update(changes)
            self.persist()
            with self.subTest(changes=changes), self.assertRaisesRegex(ValueError, "魔符"):
                self.reconnect()
        self.session.save = copy.deepcopy(saved)
        self.session.save["role_state"]["power"] = (1 << 31) - 1
        self.assert_rejected(1140, recharge.ids([target, self.gem(33001)]))

    def test_auto_composes_idle_pairs_during_matched_initialization_and_rolls_back_failed_save(self):
        self.session.save["role_state"]["level"] = 80
        self.call(6406, [1, 5])
        normal = [self.gem(33001) for _ in range(32)]
        kings = [self.gem(33076) for _ in range(2)]
        self.persist()
        self.session = self.reconnect()
        memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
            self.call(1002)
        self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))
        self.assertEqual(self.session.sigil_auto_pending, 5)
        self.session = self.reconnect()
        frames = replay.split_recordings(replay.load_recordings(test_penglai.ROOT / "recorded_frames.json"))[0]
        initial = next(f for f in frames if f["c2s"] and f["opcode"] == 999900 and 1002 in protocol.get_comb_ids(bytes.fromhex(f["hex"])))
        packets = self.session.handle(999900, 950, bytes.fromhex(initial["hex"]))
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 999900)
        self.assertEqual(sorted(v[1] for i, v in self.gems().items() if i in normal), [33005, 33005])
        self.assertTrue(all(i in self.gems() for i in kings))
        self.assertIsNone(self.session.sigil_auto_pending)
        self.assertEqual(self.session.save["role_state"]["power"], memory["role_state"]["power"])

    def pay_gift(self, gift, tier):
        body = b"".join(protocol.encode_pb_field(1, 2, recharge.ids([v])) for v in (tier, gift))
        packet = self.session.handle(115, 1400 + tier, body)[0]
        self.assertEqual(struct.unpack(">IIII", packet[:16])[2], 115)
        order = protocol.pb_get_varint(next(v for n, w, v in protocol.iter_pb_fields(packet[16:]) if (n, w) == (1, 2)), 1)
        gold = self.session.save["role_state"]["gold"]
        self.call(116, [order])
        self.assertEqual(self.session.save["role_state"]["gold"], gold)

    def test_opening_gift_requires_actual_s22_and_level_thirty_then_claims_once(self):
        self.assert_rejected(2882, recharge.ids([130004]))
        for step in range(1, self.steps[22] + 1):
            self.session.handle(201, 1200 + step, protocol.encode_pb_field(1, 0, 22) + protocol.encode_pb_field(2, 0, step))
        self.assert_rejected(2882, recharge.ids([130004]))
        self.session.save["role_state"]["level"] = 30
        self.assertEqual(protocol.parse_ids_pb(self.call(2882, [130004])[0][16:]), [130004, 0, 43200])
        self.pay_gift(130004, 3)
        self.session = self.reconnect()
        self.call(2881, [130004])
        self.assertEqual(sorted(v[1] for v in self.gems().values()), [33076, 33077])
        self.assertEqual((self.props(20641), self.props(20642)), (1, 1))
        self.assert_rejected(2881, recharge.ids([130004]))

    def test_growth_gift_uses_configured_server_days_six_through_ten_and_monotonic_time(self):
        self.session.save["role_state"]["level"] = 30
        self.session.save["role_snapshot"] = protocol.pb_set_varint(bytes.fromhex(self.session.save["role_snapshot"]), 22, NOW).hex()
        self.assert_rejected(2882, recharge.ids([130010]))
        self.clock.return_value = NOW + 5*86400
        self.assertEqual(protocol.parse_ids_pb(self.call(2882, [130010])[0][16:]), [130010, 0, 43200])
        self.pay_gift(130010, 4)
        self.call(2881, [130010])
        self.assertEqual(sorted(v[1] for v in self.gems().values()), [33078])
        self.assertEqual((self.props(20643), self.props(20642)), (1, 1))
        self.assert_rejected(2881, recharge.ids([130010]))

    @classmethod
    def client_scripts(cls):
        if not hasattr(cls, "_client_scripts"):
            with redirect_stdout(io.StringIO()):
                patched = builder.get_patched_lua_scripts()
            cls._client_scripts = {}
            for name, raw in patched.items():
                decoded = builder.xxtea_decrypt(raw, builder.XXTEA_KEY)
                cls._client_scripts[name] = decoded[:struct.unpack("<I", decoded[-4:])[0]]
        return cls._client_scripts

    def test_actual_network_lua_wear_upgrade_remove_and_full_query_clear_stale_gems(self):
        import test_activity_copy
        lua = test_activity_copy.ActivityCopyTests.network_lua(self)
        for name in ("slots_pb", "combmessages_pb", "error_pb", "params_pb"):
            lua.execute(builder.read_script(name, "pb"))
        config_code = builder.read_script("UILoadConfig").decode().replace("\r\n", "\n")
        start = config_code.index("local function roleexpEx()")
        lua.execute((config_code[start:config_code.index("local function noticeEx()", start)] + "\nroleexpEx()\n").encode())
        lua.execute(b'''table.copy=function(t) local r={} for k,v in pairs(t) do r[k]=type(v)=="table" and table.copy(v) or v end return r end
            gamedata.cache.gems={};gamedata.cache.slotgems={};gamedata.cache.role.level=27
            mekehintext=function() end
            for _,name in ipairs({"Slots","Protagonist","Cheers","Generals","Equips","Souls","Newartifact","Jewel"}) do
                gamedata[name]=function() end
            end
            for _,name in ipairs({"makeEquipsTemp","makeAllGeneralsTemp","makeOffGenerals","makeSoulsByQualityAll",
                "makeSlotInfo","makeCheerInfo","makeAllGenerals","makeOffEquip","makeOffTreasure","makeOnEquipsForSlot"}) do
                _G[name]=function() return {} end
            end
            makeEquipsByTypeAll=function() return {treasures={},horse={},treasure={}} end
            CheckArtifactAllHint=function() end
            package.loaded.logError={errorMessage={},errorFunc={}};printf=function() end
            initPb=function(mod,fd) local m=mod.Ids();m:ParseFromString(fd.rbuf);return m end''')
        code = builder.read_script("gamedata").decode().replace("\r\n", "\n")
        lua.execute(code[code.index("function gamedata.slotgemData("):code.index("function gamedata.pointData(")].encode())
        scripts = self.client_scripts()
        code = scripts["assets/scripts/GameSlots.so"].decode()
        lua.execute(code[code.index("function makeMofutemp("):code.index("function UIOffSoulsCallBack(")].encode())
        start = code.index("function NetSlotsAllInfoCallBack(")
        lua.execute(b'local slots_pb=require("slots_pb")\n' + code[start:code.index("\nfunction ", start + 1)].encode())
        lua.execute(scripts["assets/scripts/GameMofu.so"])
        lua.execute(scripts["assets/common_lua/GameErrorMessage.so"])
        self.assertIsNone(lua.globals().gameConfig)
        target, food = self.gem(33001), self.gem(33001)
        _, opcode, body = lua.globals().UISigilChangePosCallBack(lua.table_from({b"pos": 11, b"iid": target}))
        self.assertEqual((opcode, protocol.parse_ids_pb(body)), (1141, [11, target]))
        self.assertEqual(lua.globals().UISigilChangePosCallBack(lua.table_from({b"pos": 11, b"iid": target}))[0], 0)
        result = lua.globals().NetSigilChangePosCallBack(lua.table_from({b"rbuf": self.call(1141, [11, target])[0][16:]}))
        self.assertEqual(result[b"slotgems"][1][b"data"][1][b"iid"], target)
        mode, opcode, result = lua.globals().UISigilCanLevelUpCallBack(lua.table_from({b"data": lua.table_from({b"iid": target, b"type": 1})}))
        self.assertEqual((mode, opcode, result[b"data"][b"iid"], result[b"data"][b"ison"]), (0, 1142, target, 1))
        _, opcode, body = lua.globals().UISigilLevelUpCallBack(lua.table_from({b"iid": target, b"propertytype": 1,
            b"choose": lua.table_from([lua.table_from({b"iid": food})])}))
        self.assertEqual((opcode, protocol.parse_ids_pb(body)), (1140, [target, food]))
        result = lua.globals().NetSigilLevelUpCallBack(lua.table_from({b"rbuf": self.call(1140, [target, food])[0][16:]}))
        self.assertEqual(lua.globals().gamedata[b"cache"][b"gems"][target][b"cid"], 33002)
        self.assertIsNone(lua.globals().gamedata[b"cache"][b"gems"][food])
        lua.globals().UISigilChangePosCallBack(lua.table_from({b"pos": 11, b"iid": 0}))
        lua.globals().NetSigilChangePosCallBack(lua.table_from({b"rbuf": self.call(1141, [11, 0])[0][16:]}))
        gems = lua.globals().makeMofutemp()
        self.assertEqual(gems[target][b"ison"], 0)
        lua.globals().gamedata[b"cache"][b"gems"][food] = lua.table_from({b"iid": food, b"cid": 33001, b"level": 1, b"exp": 0})
        lua.globals().NetSlotsAllInfoCallBack(lua.table_from({b"rbuf": self.call(1002)[0][16:]}))
        self.assertIsNone(lua.globals().gamedata[b"cache"][b"gems"][food])
        lua.globals().gamedata[b"ext"][b"localSigilBusy"] = True
        lua.globals().NetErrorMessageCallback9(lua.table_from({b"rbuf": recharge.ids([1140, 0])}))
        self.assertFalse(lua.globals().gamedata[b"ext"][b"localSigilBusy"])

    def test_packaged_unmount_uses_existing_control_geometry_and_banked_exp_can_upgrade(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("实际APK界面验证需要本机已有lupa.lua51")
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.globals().gamedata = lua.table_from({"config": self.config}, recursive=True)
        lua.execute('''print=function() end;printT=print;CCControlEventTouchUpInside=1
            requests={};UIRequest=function(t) requests[#requests+1]=t end
            runGamePrompt=function(t) prompt=t.msg end;setSpriteFrameByName=function() end
            gameConfig={strings={string_common=function() return "label" end}}
            GameScene={roleinfo={coin=5000000}}
            gameWindows={closeWindow=function(self,n) closed=n end}
            function node() return setmetatable({x=720}, {__index=function(t,k)
                if k=="addHandleOfControlEvent" then return function(self,f) self.callback=f end end
                if k=="getPositionX" then return function(self) return self.x end end
                if k=="setPositionX" then return function(self,x) self.x=x end end
                if k=="setVisible" then return function(self,v) self.visible=v end end
                if k=="setEnabled" then return function(self,v) self.enabled=v end end
                if k=="setString" then return function(self,v) self.text=v end end
                return function() end
            end}) end
            function items() return setmetatable({}, {__index=function(t,k) local n=node();rawset(t,k,n);return n end}) end
            CCBReaderLoad=function() return node(),items() end
            ui=setmetatable({IDconfig=function(cid) return gamedata.config.sigil[tostring(cid)] end,
                setLabelString=function(n,v) if v then n:setString(v) end end}, {__index=function() return function() end end})''')
        scripts = self.client_scripts()
        window = lua.execute(scripts["assets/scripts/window_mofuProperty.so"].decode())
        gem = lua.table_from({"iid": 4000101, "cid": 33001, "type": 1, "level": 1, "exp": 0})
        window.open(window, -103, lua.table_from({"infodata": gem, "page": "slot", "selectlistdata": lua.table()}), None)
        self.assertTrue(window.rootItems.changeNode.visible)
        self.assertEqual(window.rootItems.levelupNode.x, 720)
        self.assertEqual(window.rootItems.changeText.text, "卸下")
        self.assertFalse(window.rootItems.changeBtn.enabled)
        window.setCanLevelUpGemsReload(window, lua.table_from({"iid": 99999, "ison": 2, "canlevelup": 1}))
        self.assertEqual(window.ison, 0)
        window.setCanLevelUpGemsReload(window, lua.table_from({"iid": 4000101, "ison": 1, "canlevelup": 1}))
        self.assertTrue(window.rootItems.changeBtn.enabled)
        window.rootItems.changeBtn.callback()
        request = lua.globals().requests[len(lua.globals().requests)]
        self.assertEqual((request.type, request.pos, request.iid), (1141, 11, 0))
        upgrade = lua.execute(scripts["assets/scripts/window_MofuLevelUp.so"].decode())
        upgrade.rootItems = lua.globals()["items"]()
        king = lua.table_from({"iid": 4000102, "cid": 33083, "type": 6, "level": 8, "exp": 2240})
        upgrade.reload(upgrade, lua.table_from({"mofudata": king}))
        upgrade.rootItems.levelUpBtn.callback()
        request = lua.globals().requests[len(lua.globals().requests)]
        self.assertEqual((request.type, request.iid, len(request.choose)), (1140, 4000102, 0))
        lua.globals().gameWindows.windows = lua.table_from({
            "mofuproperty": {"module": window, "show": True},
            "mofulevelup": {"module": upgrade, "show": True}}, recursive=True)
        lua.execute(scripts["assets/scripts/UIMofu.so"].decode())
        upgrade.ison = 0
        for iid in (99999, 4000101, 4000102):
            lua.globals().UISigilCanLevelUp(lua.table_from({"data": {"iid": iid, "ison": 3, "canlevelup": 1}}, recursive=True))
            self.assertEqual(window.ison, 1 if iid == 99999 else 3)
            self.assertEqual(upgrade.ison, 3 if iid == 4000102 else 0)
        lua.globals().gameWindows.windows.mofuproperty.show = False
        lua.globals().gameWindows.windows.mofulevelup.show = False
        lua.globals().UISigilCanLevelUp(lua.table_from({"data": {"iid": 4000101, "ison": 8, "canlevelup": 1}}, recursive=True))
        self.assertEqual(window.ison, 3)
        lua.execute('''GameScene.addUpdate=function() end;GameScene.UpdatePresentLayer=function() end
            GameScene.layers={mofulist={module={mofudataReload=function() end}},slotsInfo={module={}}}
            local module={data={iid=4000102},updates=0}
            module.reload=function(self) self.updates=self.updates+1 end
            module.selectdataReload=module.reload
            gameWindows.windows.mofulevelup.module=module''')
        response = lua.table_from({"iid": 4000102, "gems": {}, "slotmofudata": {}}, recursive=True)
        lua.globals().UISigilLevelUp(response)
        self.assertEqual(lua.globals().gameWindows.windows.mofulevelup.module.updates, 0)
        lua.globals().gameWindows.windows.mofulevelup.show = True
        response.iid = 99999
        lua.globals().UISigilLevelUp(response)
        self.assertEqual(lua.globals().gameWindows.windows.mofulevelup.module.updates, 0)
        response.iid = 4000102
        lua.globals().UISigilLevelUp(response)
        self.assertEqual(lua.globals().gameWindows.windows.mofulevelup.module.updates, 2)
        with zipfile.ZipFile(builder.SRC_APK) as archive:
            name = next(n for n in archive.namelist() if n.endswith("/mofu/mofu_info.ccbi"))
            for control in (b"changeBtn", b"changeNode", b"changeText", b"levelupNode"):
                self.assertIn(control, archive.read(name))


if __name__ == "__main__":
    unittest.main()
