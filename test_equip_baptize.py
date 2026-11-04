from contextlib import redirect_stdout
import copy
import io
import json
import random
import struct
import unittest
from unittest.mock import patch

import build_local_apk as builder
import test_penglai
from zyj_server import activities, battle, equip_baptize, formation, player, protocol, recharge, single_boss


NOW = test_penglai.NOW


class EquipBaptizeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        test_penglai.PenglaiTests.setUpClass.__func__(cls)
        cls.baseline = copy.deepcopy(cls.baseline)
        cls.baseline["role_state"].update(level=26, coin=5000000, gold=10000)

    reconnect = test_penglai.PenglaiTests.reconnect
    call = test_penglai.PenglaiTests.call
    give = test_penglai.PenglaiTests.give
    props = test_penglai.PenglaiTests.props
    groups = test_penglai.PenglaiTests.groups
    assert_rejected = test_penglai.PenglaiTests.assert_rejected

    def setUp(self):
        test_penglai.PenglaiTests.setUp(self)
        self.iid = 9900001
        self.add_equip(self.iid, 21201)
        armor = next(r["id"] for r in self.config["equip"].values() if r["type"] == "armor" and r["quality"] == 3)
        self.add_equip(self.iid + 1, armor)
        self.give(20222, 5000)
        self.call(1007, [1, 1, self.iid, 0, 0, 0, 0, 0])
        self.session.random_replies.clear()

    def add_equip(self, iid, cid, level=1):
        player.record_slot_update(self.session.save, protocol.encode_pb_field(2, 2, recharge.ids([iid, cid, level])))

    def equip(self, iid=None):
        raw = formation.records(bytes.fromhex(self.session.save["world_state"]["1002"]), 2, 1)[iid or self.iid]
        return protocol.parse_ids_pb(raw) + [0] * (13 - len(protocol.parse_ids_pb(raw)))

    def preview(self, iid=None, method=1, count=1, seed=0):
        return protocol.parse_ids_pb(self.call(1120, [iid or self.iid, method, count], seed)[0][16:])

    def confirm(self, candidate, method=1):
        return self.call(1121, [method, candidate[0], candidate[13]])

    def test_three_costs_preview_does_not_apply_and_keep_never_refunds(self):
        for method, stones, coin, gold in ((1, 2, 0, 0), (2, 1, 20000, 0), (3, 1, 0, 5)):
            before = copy.deepcopy(self.session.save)
            counts = self.props(20222)
            old = self.equip()
            preview = self.preview(method=method)
            self.assertEqual(len(preview), 14)
            self.assertGreater(preview[13], 0)
            self.assertEqual(self.equip()[5:10], old[5:10])
            self.assertEqual(self.equip()[10], old[10] + stones)
            self.assertEqual(self.props(20222), counts - stones)
            self.assertEqual(self.session.save["role_state"]["coin"], before["role_state"]["coin"] - coin)
            self.assertEqual(self.session.save["role_state"]["gold"], before["role_state"]["gold"] - gold)
            self.assertEqual(self.session.save["role_state"]["power"], before["role_state"]["power"])
            self.confirm(preview, 0)
            self.assertEqual(self.equip()[5:10], old[5:10])
            self.assertEqual(self.props(20222), counts - stones)
        self.assertEqual(activities.liveness_statuses(self.session.save, self.config, NOW)[1][17], 0)

    def test_replace_updates_wearer_and_power_once_and_real_reports_only(self):
        before = copy.deepcopy(self.session.save)
        preview = self.preview(count=10, seed=7)
        packets = self.confirm(preview)
        self.assertEqual(self.equip()[5:10], preview[5:10])
        world = bytes.fromhex(self.session.save["world_state"]["1002"])
        old = formation.records(bytes.fromhex(before["world_state"]["1002"]), 1, 2)
        for iid, raw in formation.records(world, 1, 2).items():
            slot = formation.records(world, 4, 2).get(iid, b"")
            worn = any(protocol.pb_get_varint(slot, f) == self.iid for f in range(4, 10))
            for field, index in ((6, 5), (7, 6), (8, 7)):
                self.assertEqual(protocol.pb_get_varint(raw, field), protocol.pb_get_varint(old[iid], field) + (preview[index] if worn else 0))
        delta = preview[5] + preview[6] + preview[7] // 10 + preview[8] + preview[9]
        self.assertEqual(self.session.save["role_state"]["power"] - before["role_state"]["power"], delta)
        self.assertIn(205, [struct.unpack(">IIII", p[:16])[2] for p in packets])
        self.assertNotIn("21", self.session.save["guide"]["sections"])
        self.assertEqual(activities.liveness_statuses(self.session.save, self.config, NOW)[1][17], 1)
        self.assert_rejected(1121, recharge.ids([1, self.iid, preview[13]]))

    def test_each_equipment_pending_preview_recovers_after_reconnect_and_binds_token(self):
        first = self.preview(seed=7)
        second = self.preview(self.iid + 1, count=10, seed=8)
        stones = self.props(20222)
        self.session = self.reconnect()
        self.assertEqual(self.preview(count=0, method=0), first)
        self.assertEqual(self.preview(self.iid + 1, count=0, method=0), second)
        self.assertEqual(self.props(20222), stones)
        self.assert_rejected(1121, recharge.ids([1]))
        self.assert_rejected(1121, recharge.ids([1, self.iid, second[13]]))
        fresh = self.preview(seed=9)
        self.assert_rejected(1121, recharge.ids([1, self.iid, first[13]]))
        self.confirm(second)
        self.confirm(fresh)
        self.assertEqual(self.preview(count=0, method=0)[13], 0)

    def test_manual_batch_and_auto_unlock_limits_and_no_partial_charge(self):
        self.preview(count=10)
        self.assert_rejected(1120, recharge.ids([self.iid, 1, 50]))
        self.assert_rejected(1124, recharge.ids([self.iid, 1, 10, 0, 0, 0, 0, 0]))
        self.session.save["role_state"].update(level=80, coin=100000000)
        current = self.preview(count=50)
        self.confirm(current, 0)
        for count in (1, 9, 11, 1001, 1010):
            self.assert_rejected(1124, recharge.ids([self.iid, 1, count, 0, 0, 0, 0, 0]))
        self.give(20222, -self.props(20222) + 19)
        self.assert_rejected(1124, recharge.ids([self.iid, 1, 10, 0, 0, 0, 0, 0]))
        self.give(20222, 1981)
        self.assertEqual(len(protocol.parse_ids_pb(self.groups(self.call(1124, [self.iid, 1, 1000, 0, 0, 0, 0, 0])[0][16:])[2])), 500)

    def test_automatic_rows_cost_ten_rolls_and_only_actual_replacements_count(self):
        self.session.save["role_state"]["level"] = 55
        before = self.props(20222)
        packets = self.call(1124, [self.iid, 2, 30, 1, 0, 0, 0, 1], seed=7)
        groups = self.groups(packets[0][16:])
        rows = protocol.parse_ids_pb(groups[2])
        self.assertEqual(len(rows), 15)
        self.assertEqual(self.props(20222), before - 30)
        self.assertEqual(self.equip()[10], 30)
        self.assertEqual(activities.liveness_statuses(self.session.save, self.config, NOW)[1][17], min(5, sum(rows[::5])))
        for offset in range(0, len(rows), 5):
            if rows[offset]:
                self.assertLess(rows[offset + 1], 1 << 63)
        self.assertEqual(self.session.save["role_state"]["coin"], 5000000 - 30 * 20000)
        self.assertEqual(self.preview(method=0, count=0)[13], 0)
        self.preview()
        self.assert_rejected(1124, recharge.ids([self.iid, 1, 10, 0, 0, 0, 0, 0]))

    def test_strengthen_formation_and_dedicated_team_preserve_preview_and_wash_stats(self):
        pending = self.preview(count=10, seed=7)
        raw = protocol.encode_pb_field(1, 0, self.iid)
        self.sequence += 1
        self.assertEqual(struct.unpack(">IIII", self.session.handle(1101, self.sequence, raw)[0][:16])[2], 1101)
        self.confirm(pending)
        attrs = self.equip()[5:10]
        self.assertEqual(attrs, pending[5:10])
        self.call(1009, [2, 1, 0, 0, 0, 0, 0])
        self.call(1009, [2, 1, 0, 0, 0, 0, 0])
        self.assertEqual(self.equip()[5:10], attrs)
        self.session.save["role_state"]["level"] = 27
        team = protocol.parse_ids_pb(self.call(3702, [140, 1])[0][16:])[:8]
        projected, _ = single_boss.project_team(self.session.save, team, self.config)
        attack, _ = battle.rosters(projected, self.config["copy"]["42102"]["1"], self.config)
        wearer = next(unit for unit in attack.values() if unit.get("flat_out") == attrs[3] and unit.get("flat_in") == attrs[4])
        self.assertGreater(wearer["atk"], attrs[0])

    def test_safe_rebirth_returns_only_verified_stones_and_strengthening_not_wash_fees(self):
        iid = self.iid + 1
        first = self.preview(iid, method=2, count=10, seed=7)
        self.confirm(first, 0)
        last = self.preview(iid, method=3, count=10, seed=8)
        self.confirm(last)
        receipt = self.session.save["qiankun_state"]["receipts"][f"equip:{iid}"]
        self.assertEqual(receipt["costs"], [[20222, 20]])
        props, coin, gold = self.props(20222), self.session.save["role_state"]["coin"], self.session.save["role_state"]["gold"]
        self.call(1117, [iid])
        fee = self.config["renascence"]["1"]["strengthencost"] + int(self.config["global_kv"]["equip_baptize_cost"]["value"])
        self.assertEqual(self.props(20222), props + 20)
        self.assertEqual(self.session.save["role_state"]["coin"], coin)
        self.assertEqual(self.session.save["role_state"]["gold"], gold - fee)
        self.assertEqual(self.equip(iid)[2:], [1] + [0] * 10)
        self.assertEqual(self.preview(iid, method=0, count=0)[13], 0)
        self.add_equip(iid + 1, 21201, 2)
        self.preview(iid + 1)
        self.assert_rejected(1117, recharge.ids([iid + 1]))

    def test_duplicate_success_and_save_failures_are_atomic(self):
        body = recharge.ids([self.iid, 1, 10])
        with patch("random.getrandbits", return_value=7):
            packets = self.session.handle(1120, 900, body)
        saved, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        self.assertEqual(self.session.handle(1120, 900, body), packets)
        self.assertEqual((self.session.save, self.path.read_bytes()), (saved, disk))
        candidate = protocol.parse_ids_pb(packets[0][16:])
        for opcode, values in ((1120, [self.iid, 3, 10]), (1121, [1, self.iid, candidate[13]])):
            with self.subTest(opcode=opcode), patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
                self.call(opcode, values)
            self.assertEqual((self.session.save, self.path.read_bytes()), (saved, disk))
        self.confirm(candidate, 0)
        self.session.save["role_state"]["level"] = 55
        saved, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
            self.call(1124, [self.iid, 1, 20, 0, 0, 0, 0, 0])
        self.assertEqual((self.session.save, self.path.read_bytes()), (saved, disk))

    def test_invalid_requests_do_not_mutate_and_advanced_equipment_stays_protected(self):
        for opcode in (1120, 1121, 1124):
            for body in (b"", b"\x08", b"\x0a\x00", b"\x10\x01", recharge.ids([1 << 31]), recharge.ids([1, 2])):
                with self.subTest(opcode=opcode, body=body.hex()):
                    self.assert_rejected(opcode, body)
        for values in ([self.iid, 0, 1], [self.iid, 4, 1], [self.iid, 1, 0], [self.iid, 1, 5], [99999, 1, 1]):
            self.assert_rejected(1120, recharge.ids(values))
        self.session.save["role_state"]["level"] = 25
        self.assert_rejected(1120, recharge.ids([self.iid, 1, 1]))
        self.session.save["role_state"]["level"] = 55
        for index in (3, 4, 11, 12):
            item = self.equip()
            item[index] = 151 if index == 12 else 1
            player.record_slot_update(self.session.save, protocol.encode_pb_field(2, 2, recharge.ids(item)))
            self.assert_rejected(1120, recharge.ids([self.iid, 1, 1]))
            self.add_equip(self.iid, 21201)
        self.assert_rejected(1124, recharge.ids([self.iid, 1, 10, 0, 0, 0, 0, 2]))
        comb = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 1120) + protocol.encode_pb_field(2, 2, recharge.ids([self.iid, 1, 1])))
        self.assert_rejected(999900, comb)

    def test_every_configured_quality_and_random_band_stays_bounded_and_repeatable(self):
        seen = set()
        for row in self.config["equip"].values():
            if row["type"] not in equip_baptize.KINDS or row["quality"] < 3:
                continue
            for level in (1, 150):
                caps = equip_baptize.limits(row, level)
                for method in (1, 2, 3):
                    for band in range(1, 11):
                        initial = [cap * band // 10 for cap in caps.values()]
                        result = equip_baptize.roll(initial, row, level, method, self.config, random.Random(7), 50)
                        self.assertEqual(result, equip_baptize.roll(initial, row, level, method, self.config, random.Random(7), 50))
                        self.assertTrue(all(0 <= value <= cap for value, cap in zip(result, caps.values())))
                        self.assertEqual(initial, [cap * band // 10 for cap in caps.values()])
                        equip_baptize.validate([self.iid, row["id"], level, 0, 0, *result, 100], self.config)
                        seen.add((row["id"], method, band))
        self.assertEqual(len(seen), 112 * 3 * 10)

    def test_extra_attribute_opening_and_automatic_filter_have_explicit_local_rules(self):
        config = copy.deepcopy(self.config)
        row = config["equip"]["21201"]
        for method in (1, 2, 3):
            config["global_kv"][f"baptize_equip_{method}"]["value"] = "0"
            self.assertEqual(equip_baptize.roll([0] * 5, row, 1, method, config, random.Random(7), 50)[3:], [0, 0])
            config["global_kv"][f"baptize_equip_{method}"]["value"] = "100"
            rolled = equip_baptize.roll([0] * 5, row, 1, method, config, random.Random(7), 1)
            self.assertEqual(sum(v > 0 for v in rolled[3:]), 1)
        old = [10, 0, 0, 5, 5]
        for flags, after, expected in (([0]*5, [9,0,0,6,5], True), ([1,0,0,0,0], [9,0,0,6,5], False),
                                       ([1,0,0,0,0], [10,0,0,4,5], True), ([0,0,0,0,1], [9,0,0,5,5], False),
                                       ([0,0,0,0,1], [9,0,0,6,5], True), ([1]*5, old, False)):
            self.assertEqual(equip_baptize.accepts(old, after, row, flags), expected)

    def test_flat_damage_is_worn_only_and_applied_once_after_multipliers(self):
        unit = {"cid": 10201, "iid": 10201, "level": 1, "advance": 0, "exp": 0,
                "atk": 100, "def": 0, "hp": 10000, "speed": 200,
                "skill": self.config["general"]["10201"]["skillid"]}
        enemy = {**unit, "iid": 1, "speed": 100, "atk": 1}
        plain = battle.simulate({2: unit}, {2: enemy}, self.config, 7)
        modified = battle.simulate({2: {**unit, "flat_out": 13}}, {2: {**enemy, "flat_in": 5}}, self.config, 7)
        self.assertEqual(modified["b"]["a"][0]["e"][0]["m"]["m"] - plain["b"]["a"][0]["e"][0]["m"]["m"], 8)
        gear = self.equip()
        gear[8:11] = [4, 3, 20]
        player.record_slot_update(self.session.save, protocol.encode_pb_field(2, 2, recharge.ids(gear)))
        attack, _ = battle.rosters(self.session.save, self.config["copy"]["42102"]["1"], self.config)
        self.assertEqual(sum(u["flat_out"] for u in attack.values()), 4)
        self.assertEqual(sum(u["flat_in"] for u in attack.values()), 3)
        before = copy.deepcopy(self.session.save["role_state"])
        self.add_equip(self.iid + 2, 21201)
        self.call(1007, [1, 1, self.iid + 2, 0, 0, 0, 0, 0])
        attack, _ = battle.rosters(self.session.save, self.config["copy"]["42102"]["1"], self.config)
        self.assertEqual(sum(u["flat_out"] + u["flat_in"] for u in attack.values()), 0)
        self.assertEqual(self.session.save["role_state"]["power"], before["power"] - 7)

    def test_corrupt_pending_and_overflow_fail_closed(self):
        preview = self.preview()
        baseline = copy.deepcopy(self.session.save)
        for key, value in (("token", True), ("token", 0), ("cid", 99999), ("values", [1]), ("base", [-1]*5)):
            saved = copy.deepcopy(baseline)
            saved["equip_baptize_state"]["pending"][str(self.iid)][key] = value
            self.path.write_text(json.dumps(saved))
            disk = self.path.read_bytes()
            with self.subTest(key=key), self.assertRaisesRegex(ValueError, "洗炼"):
                self.reconnect()
            self.assertEqual(self.path.read_bytes(), disk)
        self.path.write_text(json.dumps(baseline))
        self.session.save["equip_baptize_state"]["serial"] = (1 << 31) - 1
        self.assert_rejected(1120, recharge.ids([self.iid, 1, 1]))
        self.session.save = copy.deepcopy(baseline)
        self.session.save["role_state"]["power"] = (1 << 31) - 1
        self.assert_rejected(1121, recharge.ids([1, self.iid, preview[13]]))

    def test_vip_auto_unlock_caps_resources_and_invalid_config_do_not_partially_apply(self):
        self.session.save["role_state"]["vip"] = 5
        self.call(1124, [self.iid, 1, 10, 0, 0, 0, 0, 0])
        self.assert_rejected(1124, recharge.ids([self.iid, 1, 210, 0, 0, 0, 0, 0]))
        self.session.save["role_state"]["coin"] = 19999
        self.assert_rejected(1120, recharge.ids([self.iid, 2, 1]))
        self.session.save["role_state"]["gold"] = 4
        self.assert_rejected(1120, recharge.ids([self.iid, 3, 1]))
        item = self.equip()
        caps = equip_baptize.limits(self.config["equip"][str(item[1])], item[2])
        item[5:10] = list(caps.values())
        player.record_slot_update(self.session.save, protocol.encode_pb_field(2, 2, recharge.ids(item)))
        self.assert_rejected(1120, recharge.ids([self.iid, 1, 1]))
        self.add_equip(self.iid, 21201)
        self.session.role_config = copy.deepcopy(self.config)
        self.session.role_config["equip_baptize"]["1"]["atkup1"] = -2
        self.assert_rejected(1120, recharge.ids([self.iid, 1, 1]))

    def test_actual_replacements_unlock_daily_task_and_claim_once(self):
        for index in range(5):
            iid = self.iid + 10 + index
            self.add_equip(iid, 21201)
            self.confirm(self.preview(iid, count=10, seed=7))
        statuses, counts, _ = activities.liveness_statuses(self.session.save, self.config, NOW)
        self.assertEqual((statuses[17], counts[17]), (1, 5))
        coin = self.session.save["role_state"]["coin"]
        self.call(2411, [117])
        self.assertEqual(self.session.save["role_state"]["coin"], coin + 2000)
        self.assert_rejected(2411, recharge.ids([117]))
        self.assertEqual(activities.liveness_statuses(self.session.save, self.config, NOW)[0][17], 2)
        self.clock.return_value = NOW + 86400
        self.call(2410)
        self.assertEqual(activities.liveness_statuses(self.session.save, self.config, NOW + 86400)[1][17], 0)

    def test_baptize_gift_uses_real_guide_trigger_simulated_payment_and_persisted_claim(self):
        self.assert_rejected(2882, recharge.ids([130014]))
        for step in range(1, self.steps[21] + 1):
            self.session.handle(201, 1200 + step, protocol.encode_pb_field(1, 0, 21) + protocol.encode_pb_field(2, 0, step))
        self.assertEqual(protocol.parse_ids_pb(self.call(2882, [130014])[0][16:]), [130014, 0, 43200])
        request = b"".join(protocol.encode_pb_field(1, 2, recharge.ids([v])) for v in (3, 130014))
        packets = self.session.handle(115, 1400, request)
        order = protocol.pb_get_varint(next(v for n, w, v in protocol.iter_pb_fields(packets[0][16:]) if (n, w) == (1, 2)), 1)
        self.assertTrue(order)
        gold = self.session.save["role_state"]["gold"]
        self.call(116, [order])
        self.assertEqual(self.session.save["role_state"]["gold"], gold)
        stones, coin = self.props(20222), self.session.save["role_state"]["coin"]
        self.session = self.reconnect()
        self.call(2881, [130014])
        self.assertEqual(self.props(20222), stones + 200)
        self.assertEqual(self.session.save["role_state"]["coin"], coin + 100000)
        self.assert_rejected(2881, recharge.ids([130014]))

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

    def test_actual_network_lua_preview_confirm_restore_auto_costs_and_error_unlock(self):
        import test_activity_copy
        lua = test_activity_copy.ActivityCopyTests.network_lua(self)
        scripts = self.client_scripts()
        for name in ("equiprefine_pb", "combmessages_pb", "error_pb", "params_pb"):
            lua.execute(builder.read_script(name, "pb"))
        code = builder.read_script("gamedata").decode().replace("\r\n", "\n")
        start = code.index("function gamedata.equipData(")
        lua.execute(code[start:code.index("function gamedata.artifactData(", start)].encode())
        start = code.index("function gamedata.getIDandNUMs(")
        lua.execute(code[start:code.index("\nfunction ", start)].encode())
        lua.execute(b'''gamedata.cache.equips={};gamedata.cache.props={[20222]={num=5000}}
            gamedata.cache.role.coin=5000000;gamedata.cache.role.gold=10000
            gamedata.updateRoleCoin=function(self,n) self.cache.role.coin=self.cache.role.coin+n end
            gamedata.updateRoleGold=function(self,n) self.cache.role.gold=self.cache.role.gold+n end
            gamedata.updateprops=function(self,p) self.cache.props[p.cid].num=self.cache.props[p.cid].num+p.num end
            gamedata.SomethingProcess=function(self,p)
                for _,e in ipairs(p.equips) do local v=self:equipData(e);self.cache.equips[v.iid]=v end
            end
            package.loaded.logError={errorMessage={},errorFunc={}};printf=function() end
            initPb=function(mod,fd) local m=mod.Ids();m:ParseFromString(fd.rbuf);return m end''')
        lua.globals().gamedata[b"cache"][b"props"][20222][b"num"] = self.props(20222)
        lua.execute(scripts["assets/scripts/GameEquipRefine.so"])
        lua.execute(scripts["assets/common_lua/GameErrorMessage.so"])
        self.assertIsNone(lua.globals().gameConfig)
        for method, count in ((1, 1), (2, 10), (3, 10)):
            request = lua.table_from({b"iid": self.iid, b"method": method, b"xlnum": count})
            mode, opcode, body = lua.globals().UIEquipBaptizePreviewCallBack(request)
            self.assertEqual((mode, opcode, protocol.parse_ids_pb(body)), (1, 1120, [self.iid, method, count]))
            self.assertEqual(lua.globals().UIEquipBaptizePreviewCallBack(request)[0], 0)
            packets = self.call(1120, [self.iid, method, count], seed=7)
            preview = lua.globals().NetEquipBaptizePreviewCallBack(lua.table_from({b"rbuf": packets[0][16:]}))[b"equip"]
            token = preview[b"preview_token"]
            self.assertGreater(token, 0)
            role = lua.globals().gamedata[b"cache"][b"role"]
            self.assertEqual((role[b"coin"], role[b"gold"]), tuple(self.session.save["role_state"][k] for k in ("coin", "gold")))
            self.assertEqual(lua.globals().gamedata[b"cache"][b"props"][20222][b"num"], self.props(20222))
            mode, opcode, body = lua.globals().UIEquipBaptizeConfirmCallBack(lua.table_from({b"id": self.iid, b"method": 1, b"token": token}))
            self.assertEqual((mode, opcode, protocol.parse_ids_pb(body)), (1, 1121, [1, self.iid, token]))
            result = lua.globals().NetEquipBaptizeConfirmCallBack(lua.table_from({b"rbuf": self.call(1121, [1, self.iid, token])[0][16:]}))
            self.assertEqual(result[b"equip"][b"iid"], self.iid)
        lua.globals().UIEquipBaptizePreviewCallBack(lua.table_from({b"iid": self.iid, b"method": 0, b"xlnum": 0}))
        result = lua.globals().NetEquipBaptizePreviewCallBack(lua.table_from({b"rbuf": self.call(1120, [self.iid, 0, 0])[0][16:]}))
        self.assertEqual(result[b"equip"][b"preview_token"], 0)
        self.session.save["role_state"]["level"] = 55
        request = lua.table_from({b"iid": self.iid, b"method": 2, b"xlnum": 30})
        _, opcode, body = lua.globals().UIEquipBaptizeAutomaticCallBack(request)
        self.assertEqual((opcode, protocol.parse_ids_pb(body)), (1124, [self.iid, 2, 30, 0, 0, 0, 0, 0]))
        result = lua.globals().NetEquipBaptizeAutomaticCallBack(lua.table_from({b"rbuf": self.call(1124, [self.iid, 2, 30, 0, 0, 0, 0, 0])[0][16:]}))
        self.assertEqual(len(list(result[b"status"].items())), 3)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"coin"], self.session.save["role_state"]["coin"])
        lua.globals().gamedata[b"ext"][b"localBaptizeBusy"] = True
        lua.globals().NetErrorMessageCallback9(lua.table_from({b"rbuf": recharge.ids([1124, 0])}))
        self.assertFalse(lua.globals().gamedata[b"ext"][b"localBaptizeBusy"])

    def test_packaged_page_recovers_bound_preview_and_does_not_query_unsupported_callbacks(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("实际APK界面验证需要本机已有lupa.lua51")
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.globals().gamedata = lua.table_from({"config": self.config}, recursive=True)
        lua.execute('''print=function() end;printT=print;CCControlEventTouchUpInside=1
            requests={};updates={}
            UIRequest=function(t) requests[#requests+1]=t end
            runGamePrompt=function(t) lastPrompt=t.msg end
            gameTouch={clickprofbytime=function() end}
            gameConfig={strings={attr_type={atk="攻击",def="防御",hp="生命",adddmg="增伤",subdmg="减伤"},
                string_common=function(self,...) return "label" end}}
            GameScene={roleinfo={level=26,coin=5000000,gold=10000},vip={vip=0},layers={},
                addUpdate=function(self,id) updates[#updates+1]=id end,UpdatePresentLayer=function() end}
            gameWindows={windows={equipInfo={show=false},equipbaptize={show=false}},openWindow=function(self,name,t) opened=name end}
            function node()
                return setmetatable({}, {__index=function(t,k)
                    if k=="addHandleOfControlEvent" then return function(self,fn) self.callback=fn end end
                    if k=="setString" then return function(self,v) self.text=v end end
                    if k=="setVisible" then return function(self,v) self.visible=v end end
                    if k=="setEnabled" then return function(self,v) self.enabled=v end end
                    return function() end
                end})
            end
            ui=setmetatable({setLabelString=function(n,v) if v then n:setString(v) end end,
                getVipLevelByStr=function() return 5 end,
                getIDandNUMs=function(s) local t={} for id,n in s:gmatch("(%d+),(%d+)") do
                    t[#t+1]={cid=tonumber(id),num=tonumber(n)} end return t end},
                {__index=function() return function() end end})''')
        scripts = self.client_scripts()
        layer = lua.execute(scripts["assets/scripts/Layer_equip_up.so"].decode())
        lua.globals().layer = layer
        lua.execute('''layer.rootItems=setmetatable({}, {__index=function(t,k) local n=node();rawset(t,k,n);return n end})
            layer.setEquipIcons=function() end
            layer.selectpage="xilian";layer.touchPriority=-103
            layer.data={iid=9900001,cid=21201,level1=1,level2=0,xatk=0,xdef=0,xhp=0,xadddmg=0,xsubdmg=0,xcount=0}
            layer.rolecoin=5000000
            GameScene.layers.equipsup={show=true,module=layer}
            layer.reloaddata=function(self,t) self.lastReload=t.equip end''')
        layer.setPage_strengthen(layer)
        request = lua.globals().requests[len(lua.globals().requests)]
        self.assertEqual((request.type, request.iid, request.method, request.xlnum), (1120, self.iid, 0, 0))
        self.assertEqual(layer.dotimes, 10)
        lua.execute(scripts["assets/scripts/UIEquips.so"].decode())
        preview = lua.table_from({"iid": self.iid, "cid": 21201, "xatk": 7, "xdef": 0, "xhp": 0,
                                  "xadddmg": 0, "xsubdmg": 0, "preview_token": 42})
        lua.globals().UIEquipBaptizePreview(lua.table_from({"equip": preview}))
        self.assertTrue(layer.hasXLPreview)
        self.assertTrue(layer.rootItems.xl_Button_no.enabled)
        self.assertTrue(layer.rootItems.xl_Button_yes.enabled)
        layer.rootItems.xl_Button_yes.callback()
        request = lua.globals().requests[len(lua.globals().requests)]
        self.assertEqual((request.type, request.iid, request.method, request.token), (1121, self.iid, 1, 42))
        preview.iid = self.iid + 1
        preview.preview_token = 43
        layer.setXilianPreview(layer, preview)
        self.assertEqual(layer.localBaptizeToken, 42)
        lua.globals().UIEquipBaptizeConfirm(lua.table_from({"equip": preview}))
        self.assertIsNone(layer.lastReload)
        lua.execute('''gameWindows.windows.equipbaptize={show=true,module={iid=9900001,
            reloadData=function() wrongAutoReload=true end}}''')
        lua.globals().UIEquipBaptizeAutomatic(lua.table_from({"equip": preview}))
        self.assertIsNone(lua.globals().wrongAutoReload)
        preview.iid = self.iid
        preview.xatk = 0
        layer.setXilianPreview(layer, preview)
        self.assertTrue(layer.rootItems.xl_Button_no.enabled)
        self.assertFalse(layer.rootItems.xl_Button_yes.enabled)
        preview.preview_token = 0
        layer.setPage_strengthen(layer)
        layer.setXilianPreview(layer, preview)
        self.assertFalse(layer.hasXLPreview)
        for _, request in lua.globals().requests.items():
            self.assertNotIn(request.type, (1001, 10322))
        lua.globals().GameScene.roleinfo.level = 80
        layer.setPage_strengthen(layer)
        self.assertEqual(layer.dotimes, 50)
        window = lua.execute(scripts["assets/scripts/window_equipBaptizeAutomatic.so"].decode())
        window.rootItems = layer.rootItems
        window.donum, window.costnum, window.stonenum, window.hasstonenum = 0, 0, 2, 5000
        window.numchange(window, 15)
        self.assertEqual(window.donum, 10)
        window.numchange(window, 2000)
        self.assertEqual(window.donum, 10)


if __name__ == "__main__":
    unittest.main()
