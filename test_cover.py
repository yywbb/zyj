"""玩家魔罩：临时账号、真实配置费用、阵位护盾与原生PB。"""

import copy
from fractions import Fraction
import json
from pathlib import Path
import unittest
from unittest.mock import patch
import zipfile

import test_soul
import test_wing
from zyj_server import battle, cover, development, formation, player, protocol, ranking, recharge


def setUpModule():
    test_soul.setUpModule()


class CoverTests(unittest.TestCase):
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
    give = test_wing.WingTests.give

    def network_lua(self):
        import build_local_apk as builder
        lua = test_soul.SoulTests.network_lua(self, native_protobuf=True)
        native = builder.read_script("gamedata").decode()
        for start_name, end_name in (("SafeMask", "GoddownStatus"), ("ActivitySafeMaskShop", None)):
            start = native.index("function gamedata." + start_name + "(")
            end = native.index("function gamedata." + end_name + "(", start) if end_name else native.index("\nfunction ", start + 1)
            lua.execute(native[start:end].encode())
        lua.globals().cover_props = bytes.fromhex(self.save["world_state"]["1200"])
        lua.execute(b'local p=require("idnums_pb").IdNums();p:ParseFromString(cover_props);gamedata:Props(p.idnums);gamedata.cache.safemaskshop={}')
        return lua

    def setUp(self):
        test_soul.SoulTests.setUp(self)
        self.save["role_state"].update(level=150, coin=1000000000000)
        for cid in (20296, 20322, 20318, 20314, 20507, 20508, 20842, 20843, 20844, 20845):
            self.give(cid, 1000000)

    def test_paid_first_cover_has_actual_shield_power_costs_and_reconnect(self):
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 3730)), [0] * 21)
        self.refresh()
        before = copy.deepcopy(self.save)
        self.success(1, 3731, values=[1]); self.refresh()
        self.assertEqual(self.save["cover_state"]["levels"], [1, 0, 0, 0, 0, 0, 0])
        self.assertEqual(before["role_state"]["coin"] - self.save["role_state"]["coin"], 15000)
        self.assertEqual(self.props(20296), 999997)
        self.assertEqual(self.save["role_state"]["power"] - before["role_state"]["power"], 3350)
        attack, _ = battle.rosters(self.save, self.config["copy"]["42101"]["1"], self.config)
        self.assertEqual((attack[2]["cover_d"], attack[2]["cover_p"]), (5000, 26))
        self.reconnect(); self.refresh()
        self.assertEqual(self.save["cover_state"]["levels"][0], 1)

    def seed_cover(self, levels, advanced=None, soaring=None):
        old, _ = cover.bonuses(self.save, self.config)
        self.save["cover_state"] = {"levels": list(levels), "advanced": list(advanced or [0] * 7),
                                    "soaring": list(soaring or [0] * 7), "day": (self.now + 28800) // 86400,
                                    "shop": {}, "checked_at": self.now}
        new, _ = cover.bonuses(self.save, self.config)
        world = bytes.fromhex(self.save["world_state"]["1002"])
        generals, slots = formation.records(world, 1, 2), formation.records(world, 4, 1)
        update, total = b"", 0
        for sid, slot in slots.items():
            iid = protocol.pb_get_varint(slot, 2)
            if not iid:
                continue
            raw, delta = development.adjust(generals[iid], {f: new[sid]["stats"][f] - old[sid]["stats"][f] for f in (6, 7, 8)})
            fixed = new[sid]["power"] - old[sid]["power"]
            raw = protocol.pb_set_varint(raw, 20, protocol.pb_get_varint(raw, 20) + fixed)
            update += protocol.encode_pb_field(1, 2, raw)
            total += delta + fixed
        player.apply_sigil_update(self.save, update, total, self.config)

    def test_master_and_first_advance_use_real_levels_costs_and_skill_reduction(self):
        for _ in range(10):
            self.success(1, 3731, values=[1]); self.refresh()
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 3732)), [1, 0, 0, 0, 0, 0, 0])
        self.refresh()
        before, pills, cores = self.gen(), self.props(20507), self.props(20508)
        self.success(1, 3735, values=[1]); self.refresh()
        self.assertEqual(self.props(20507), pills - 30)
        self.assertEqual(self.props(20508), cores - 2)
        self.assertEqual(protocol.pb_get_varint(self.gen(), 7) - protocol.pb_get_varint(before, 7), 800)
        self.assertEqual(protocol.pb_get_varint(self.gen(), 8) - protocol.pb_get_varint(before, 8), 4000)
        units, _ = battle.rosters(self.save, self.config["copy"]["42101"]["1"], self.config)
        self.assertEqual(units[2]["skill_resilience"], Fraction(1, 100))

    def test_real_global_advance_and_soaring_gates_cannot_use_empty_zero_tracks(self):
        self.seed_cover([30] * 7, [2, 0, 0, 0, 0, 0, 0])
        self.assert_rejected(3735, values=[1])
        self.seed_cover([30] * 7, [2, 1, 1, 1, 1, 1, 1])
        self.success(1, 3735, values=[1]); self.refresh()
        self.assertEqual(self.save["cover_state"]["advanced"][0], 3)
        self.seed_cover([30] * 7, [2] * 7, [5, 0, 0, 0, 0, 0, 0])
        self.assert_rejected(3736, values=[1])
        self.seed_cover([30] * 7, [2] * 7, [5] * 7)
        self.success(1, 3736, values=[1]); self.refresh()
        self.assertEqual(self.save["cover_state"]["soaring"][0], 6)

    def test_soaring_uses_configured_materials_and_explicit_ordinary_conversion(self):
        self.seed_cover([10] * 7, [1] * 7)
        self.save["role_state"]["level"] = 104
        self.assert_rejected(3736, values=[1])
        self.save["role_state"]["level"] = 105
        before, materials = self.gen(), self.props(20842)
        gold_power = self.save["role_state"]["g_power"]
        self.success(1, 3736, values=[1]); self.refresh()
        self.assertEqual(self.props(20842), materials - 3)
        self.assertEqual(protocol.pb_get_varint(self.gen(), 8) - protocol.pb_get_varint(before, 8), 904)
        self.assertEqual(protocol.pb_get_varint(self.gen(), 7) - protocol.pb_get_varint(before, 7), 151)
        self.assertEqual(self.save["role_state"]["g_power"], gold_power)
        self.assertFalse(any(protocol.pb_get_varint(self.gen(), n) for n in range(21, 41)))

    def test_all_241_basic_18_advance_and_91_soaring_profiles_have_bounded_real_stats(self):
        for level, row in self.config["mozhao_break"].items():
            self.seed_cover([int(level)] * 7)
            values, masters = cover.bonuses(self.save, self.config)
            self.assertEqual((values[1]["value"], values[1]["percent"]), (row["value"], row["percent"]))
            self.assertTrue(all(0 <= v <= 24 for v in masters))
        self.seed_cover([240] * 7)
        self.assert_rejected(3731, values=[1])
        for level, row in self.config["mozhao_evolve"].items():
            self.seed_cover([240] * 7, [int(level)] * 7)
            values, _ = cover.bonuses(self.save, self.config)
            self.assertEqual(values[1]["skill_resilience"], cover.effects(row["effect"])["skill_resilience"])
        self.seed_cover([240] * 7, [18] * 7)
        self.assert_rejected(3735, values=[1])
        for level in self.config["mozhao_soaring"]:
            self.seed_cover([240] * 7, [18] * 7, [int(level)] * 7)
            values, _ = cover.bonuses(self.save, self.config)
            self.assertTrue(all(0 <= n < (1 << 31) for r in values.values() for n in r["stats"].values()))
        self.seed_cover([240] * 7, [18] * 7, [90] * 7)
        self.assert_rejected(3736, values=[1])

    def test_masks_stay_with_positions_and_dedicated_and_frozen_teams_keep_them(self):
        from zyj_server import cup, guild_war, single_boss
        self.seed_cover([10, 0, 0, 0, 0, 0, 0], [1, 0, 0, 0, 0, 0, 0])
        world = bytes.fromhex(self.save["world_state"]["1002"])
        slots = formation.records(world, 4, 1)
        self.assertTrue(protocol.pb_get_varint(slots[2], 2))
        before, original_iid = self.gen(), protocol.pb_get_varint(self.gen(), 2)
        self.success(1, 1003, raw=b"\x08\x01\x10\x02"); self.refresh()
        self.assertEqual(protocol.pb_get_varint(self.gen(), 7), protocol.pb_get_varint(before, 7) - 800)
        self.assertEqual(protocol.pb_get_varint(self.gen(), 8), protocol.pb_get_varint(before, 8) - 4000)
        units, _ = battle.rosters(self.save, self.config["copy"]["42101"]["1"], self.config)
        self.assertEqual(units[2]["cover_l"], 10)
        self.assertNotIn("cover_l", units[8])
        temporary, _ = single_boss.project_team(self.save, [original_iid, 0, 0, 0, 0, 0, 0, 0], self.config)
        projected, _ = battle.rosters(temporary, self.config["copy"]["42101"]["1"], self.config)
        self.assertEqual(projected[2]["cover_l"], 10)
        for snapshot in (cup.frozen(self.save, 1, self.config)["snapshot"], guild_war.freeze(self.save)):
            frozen, _ = battle.rosters(snapshot, self.config["copy"]["42101"]["1"], self.config)
            self.assertEqual(frozen[2]["cover_l"], 10)
            self.assertEqual(snapshot["cover_state"]["shop"], {})

    def test_skill_reduction_is_before_hp_clipping_and_not_applied_to_basic_hits(self):
        attack, target = {"atk": 10000}, {"hp": 1000000, "def": 0}
        ordinary = battle.damage(attack, target, self.config)
        skill = battle.damage(attack, target, self.config, 12101, flat=100)
        defended = {**target, "skill_resilience": Fraction(46, 100)}
        self.assertEqual(battle.damage(attack, defended, self.config), ordinary)
        self.assertEqual(battle.damage(attack, defended, self.config, 12101, flat=100), int(skill * Fraction(54, 100)))
        self.assertEqual(battle.damage(attack, {**defended, "hp": 1}, self.config, 12101), 1)
        with self.assertRaises(ValueError):
            battle.damage(attack, {**target, "skill_resilience": 2}, self.config, 12101)

    def test_actual_shield_damage_and_terminal_hp_work_on_both_sides_without_mutating_saves(self):
        self.success(1, 3731, values=[1]); self.refresh()
        before = copy.deepcopy(self.save)
        units, _ = battle.rosters(self.save, self.config["copy"]["42101"]["1"], self.config)
        protected = {**units[2], "atk": 1, "def": 0, "hp": 10000, "speed": 1, "advance": 0, "initial_ap": 0,
                     "critical": 0, "dodge": 0, "parry": 0, "resilience": 0, "pet_rates": {}}
        enemy = {"iid": 9900001, "cid": 10101, "level": 1, "advance": 0, "atk": 1000,
                 "def": 0, "hp": 100000, "speed": 300, "skill": 12101, "initial_ap": 0}
        for direct in (True, False):
            teams = ({2: enemy}, {2: protected})
            report = battle.simulate(*(teams if direct else teams[::-1]), self.config, 7, max_rounds=1)
            side = "defense" if direct else "attack"
            final = report["endmeta"][side]["2"]
            self.assertEqual((final["h"], final["cover_d"]), (9260, 4740))
        self.assertEqual(self.save, before)

    def test_all_38_shop_rows_use_real_quotes_rewards_limits_and_forward_day_reset(self):
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 3733)), [0] * 38); self.refresh()
        for key, row in self.config["mozhao_shop"].items():
            before = self.save["role_state"]["gold"]
            price = cover.shop_price(row, self.now)
            self.success(1, 3734, values=[int(key), 1, price]); self.refresh()
            self.assertEqual(self.save["role_state"]["gold"], before - price)
            self.assert_rejected(3734, values=[int(key), row["times"], price])
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 3733)), [1] * 38)
        self.clock.return_value += 86400
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 3733)), [0] * 38); self.refresh()
        self.clock.return_value -= 86400
        self.assert_rejected(3734, values=[1, 1, cover.shop_price(self.config["mozhao_shop"]["1"], self.now)])

    def test_expired_discount_quote_legacy_buy_and_failed_save_never_charge(self):
        self.success(1, 3733); self.refresh()
        weekday = ((self.now + 28800) // 86400 + 3) % 7 + 1
        row = next(r for r in self.config["mozhao_shop"].values() if str(weekday) in r["week"].split(";"))
        price = cover.shop_price(row, self.now)
        self.clock.return_value += 2 * 86400
        while cover.shop_price(row, int(self.clock.return_value)) == price:
            self.clock.return_value += 86400
        self.assert_rejected(3734, values=[row["id"], 1, price])
        self.clock.return_value = self.now
        self.assert_rejected(3734, values=[1, 1])
        before = copy.deepcopy(self.save)
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 3731, values=[1])
        self.assertEqual(self.sessions[1].save, before)
        self.save["role_state"]["coin"] = 14999
        self.assert_rejected(3731, values=[1])

    def test_bad_payloads_locked_slots_and_corrupt_state_are_non_mutating(self):
        for opcode, values in ((3730, [1]), (3732, [1]), (3733, [1]), (3731, [0]), (3731, [8]),
                               (3731, [1, 1]), (3735, [1]), (3736, [1]), (3734, [1, 0, 80])):
            self.assert_rejected(opcode, values=values)
        self.save["role_state"]["level"] = 31
        self.assert_rejected(3731, values=[1])
        self.save["role_state"]["level"] = 150
        state = cover.get_state(self.save, self.config)
        state["levels"][0] = -1
        self.save["cover_state"] = state
        self.assert_rejected(3730)

    def test_partial_cost_failure_power_overflow_shop_overflow_and_retry_are_atomic(self):
        baseline = copy.deepcopy(self.save)
        player.change_item_count(self.save, 20314, 2 - self.props(20314), self.config, self.now)
        self.assert_rejected(3731, values=[1])
        self.sessions[1].save = self.save = copy.deepcopy(baseline)
        self.save["role_state"]["power"] = (1 << 31) - 1
        self.assert_rejected(3731, values=[1])
        self.sessions[1].save = self.save = copy.deepcopy(baseline)
        self.assert_rejected(3731, raw=recharge.ids([1]) + protocol.encode_pb_field(100, 2, recharge.ids([240] * 21)))
        self.success(1, 3731, values=[1]); self.refresh()
        after = copy.deepcopy(self.save)
        (seq, raw), packets, _ = self.sessions[1].random_replies[3731]
        self.assertEqual(tuple(self.sessions[1].handle(3731, seq, raw)), tuple(packets))
        self.assertEqual(self.save, after)
        row = self.config["mozhao_shop"]["1"]
        cid, _ = map(int, row["reward"].strip(";").split(","))
        player.change_item_count(self.save, cid, (1 << 31) - 1 - self.props(cid), self.config, self.now)
        self.assert_rejected(3734, values=[1, 1, cover.shop_price(row, self.now)])

    def test_rank_and_three_gifts_require_real_progress_guides_and_simulated_payment(self):
        self.success(1, 3731, values=[1]); self.refresh()
        self.assertEqual(ranking.entry(1, self.save, self.config)["scores"]["7"], 1)
        for gid, section, tier in ((130005, 97, 3), (130017, 78, 4), (130026, 102, 4)):
            self.assert_rejected(2882, values=[gid])
            for step in range(1, self.sessions[1].step_counts[section] + 1):
                self.success(1, 201, raw=protocol.encode_pb_field(1, 0, section) + protocol.encode_pb_field(2, 0, step))
            self.success(1, 2882, values=[gid]); self.refresh()
            self.assert_rejected(2881, values=[gid])
            raw = b"".join(protocol.encode_pb_field(1, 2, recharge.ids([v])) for v in (tier, gid))
            order = self.records(self.success(1, 115, raw=raw))[0]
            self.success(1, 116, values=[protocol.pb_get_varint(order, 1)])
            self.reconnect(); self.refresh()
            self.success(1, 2881, values=[gid]); self.refresh()
            self.assert_rejected(2881, values=[gid])

    def test_actual_network_pb_atomic_state_costs_and_mandatory_shop_quote(self):
        lua = self.network_lua()
        self.client_call(lua, 1, "UISlotCoverQueryCallBack", "NetSlotCoverQueryCallBack", {})
        self.client_call(lua, 1, "UISlotCoverMasterQueryCallBack", "NetSlotCoverMasterQueryCallBack", {})
        price = [lua.table_from({b"cid": cid, b"num": num}) for cid, num in ((20296, 3), (20322, 3), (20318, 3), (20314, 3), (1000, 15000))]
        bad = lua.table_from({b"sid": 1, b"cost": lua.table_from([])})
        self.assertEqual(lua.globals().UISlotCoverupCallBack(bad)[0], 0)
        request = lua.table_from({b"sid": 1, b"cost": lua.table_from(price), b"coverView": lua.table_from({b"generation": 7})})
        remote, opcode, body = lua.globals().UISlotCoverupCallBack(request)
        self.assertEqual((remote, opcode, protocol.parse_ids_pb(body)), (1, 3731, [1]))
        self.assertEqual(lua.globals().UISlotCoverupCallBack(request)[0], 0)
        before = self.save["role_state"]["coin"]
        result = lua.globals().NetSlotCoverupCallBack(lua.table_from({b"rbuf": self.success(1, 3731, raw=body)})); self.refresh()
        cache = lua.globals().gamedata[b"cache"]
        self.assertEqual(cache[b"safemask"][b"1"][b"level"], 1)
        self.assertEqual(cache[b"role"][b"coin"], before - 15000)
        self.assertEqual(cache[b"props"][20296][b"num"], self.props(20296))
        self.assertEqual((result[b"coverSID"], result[b"coverView"][b"generation"]), (1, 7))
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localCoverBusy"])
        for opcode, advanced, send, receive, spec, amount in (
                (3735, [0] * 7, "UISlotCoverLevel2UpCallBack", "NetSlotCoverLevel2UpCallBack",
                 self.config["mozhao_evolve"]["1"]["lv_cost"], 300000),
                (3736, [1] * 7, "UISlotCoverFeiShengCallBack", "NetSlotCoverFeiShengCallBack",
                 self.config["mozhao_soaring"]["1"]["consume"], 14000)):
            self.seed_cover([10] * 7, advanced)
            self.client_call(lua, 1, "UISlotCoverQueryCallBack", "NetSlotCoverQueryCallBack", {})
            request = lua.table_from({b"sid": 1})
            request[b"cost"] = lua.globals().gamedata[b"getIDandNUMs"](spec.encode())
            mode, mid, raw = lua.globals()[send.encode()](request)
            self.assertEqual((mode, mid, protocol.parse_ids_pb(raw)), (1, opcode, [1]))
            before = self.save["role_state"]["coin"]
            lua.globals()[receive.encode()](lua.table_from({b"rbuf": self.success(1, opcode, raw=raw)})); self.refresh()
            self.assertEqual(cache[b"role"][b"coin"], before - amount)
            key = b"level2" if opcode == 3735 else b"level3"
            self.assertEqual(cache[b"safemask"][b"1"][key], 1)
        self.client_call(lua, 1, "UISafeMaskShopQueryCallBack", "NetSafeMaskShopQueryCallBack", {})
        quote = cover.shop_price(self.config["mozhao_shop"]["1"], self.now)
        request = lua.table_from({b"id": 1, b"num": 1, b"gold": quote})
        remote, opcode, body = lua.globals().UISafeMaskShopRewardCallBack(request)
        self.assertEqual((remote, opcode, protocol.parse_ids_pb(body)), (1, 3734, [1, 1, quote]))
        before = self.save["role_state"]["gold"]
        result = lua.globals().NetSafeMaskShopRewardCallBack(lua.table_from({b"rbuf": self.success(1, 3734, raw=body)})); self.refresh()
        self.assertEqual(cache[b"role"][b"gold"], before - quote)
        cid, count = map(int, self.config["mozhao_shop"]["1"]["reward"].strip(";").split(","))
        self.assertEqual((result[b"reward"][1][b"cid"], result[b"reward"][1][b"num"]), (cid, count))
        self.assertEqual(cache[b"props"][cid][b"num"], self.props(cid))
        lua.globals().UISafeMaskShopRewardCallBack(request)
        lua.globals().NetErrorMessageCallback9(lua.table_from({b"rbuf": recharge.ids([3731, 0])}))
        self.assertEqual(lua.globals().gamedata[b"ext"][b"localCoverBusy"], 3734)
        lua.globals().NetErrorMessageCallback9(lua.table_from({b"rbuf": recharge.ids([3734, 0])}))
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localCoverBusy"])
        self.assertIsNone(lua.globals().gameConfig)

    def test_original_apk_decoder_stays_unchanged_and_cover_parsers_receive_separate_fields(self):
        lua = self.network_lua()
        from lupa.lua51 import LuaError
        native = recharge.ids([10] * 7 + [1] * 7 + [2] * 7)
        mask = protocol.encode_pb_field(100, 2, native)
        masters = protocol.encode_pb_field(101, 2, recharge.ids([1] + [0] * 6))
        lua.globals().mixed_cover = native + mask + masters
        for constructor in ('require("localcoverupdate_pb").LocalCoverUpdate', 'require("ids_pb").Ids'):
            with self.assertRaisesRegex(LuaError, "ReadTag expects a number"):
                lua.execute(f'local p={constructor}();p:ParseFromString(mixed_cover)'.encode())
        scripts = self.client_scripts()
        for name in ("protobuf", "decoder", "ids_pb", "generals_pb", "somethings_pb"):
            self.assertFalse(any(path.endswith("/" + name + ".so") for path in scripts))
        for raw in (native + mask + masters, mask + native + masters, masters + native[:14] + mask + native[14:]):
            with self.subTest(order=raw[:3]):
                fd = lua.table_from({b"rbuf": raw})
                result = lua.globals().NetSlotCoverQueryCallBack(fd)
                self.assertEqual(fd[b"rbuf"], raw)
                self.assertEqual(result[b"safemask"][b"7"][b"level3"], 2)
                self.assertEqual([result[b"safemaskmaster"][str(i).encode()][b"masterid"] for i in range(1, 8)], [1] + [0] * 6)

    def test_malformed_cover_extensions_never_update_caches_or_deduct_native_costs(self):
        lua = self.network_lua()
        from lupa.lua51 import LuaError
        self.client_call(lua, 1, "UISlotCoverQueryCallBack", "NetSlotCoverQueryCallBack", {})
        native = protocol.encode_pb_field(1, 2, self.gen())
        mask = protocol.encode_pb_field(100, 2, recharge.ids([0] * 21))
        masters = protocol.encode_pb_field(101, 2, recharge.ids([0] * 7))
        extension = mask + masters
        malformed = [b"", mask, masters, extension + mask, extension + masters,
                     protocol.encode_pb_field(100, 0, 1) + masters,
                     protocol.encode_pb_field(100, 2, recharge.ids([0] * 20)) + masters,
                     mask + protocol.encode_pb_field(101, 2, recharge.ids([0] * 6)),
                     mask + protocol.encode_pb_field(101, 2, recharge.ids([999] + [0] * 6)),
                     extension[:-1], extension + b"\x80", extension + b"\x00",
                     extension + protocol.encode_varint(1 << 32), extension + b"\x0b",
                     extension + b"\x0c", extension + b"\x0e", extension + b"\x0f",
                     extension + b"\x09\x00", extension + b"\x0d\x00",
                     extension + b"\x0a\x80", extension + b"\x0a\x05\x00",
                     extension + b"\x08" + b"\xff" * 10,
                     extension + b"\x0a" + protocol.encode_varint((1 << 64) - 1)]
        for index, value in ((0, 241), (7, 19), (14, 91), (0, (1 << 64) - 1)):
            values = [0] * 21
            values[index] = value
            malformed.append(protocol.encode_pb_field(100, 2, recharge.ids(values)) + masters)
        lua.execute(b'''cover_old_mask=gamedata.cache.safemask;cover_old_masters=gamedata.cache.safemaskmaster
            cover_old_coin=gamedata.cache.role.coin;cover_old_props=gamedata.cache.props[20296].num''')
        for index, extra in enumerate(malformed):
            with self.subTest(case=index):
                lua.execute(b'''gamedata.ext.localCoverBusy=nil
                    local price=gamedata.getIDandNUMs(gamedata.config.mozhao_break["0"].lv_cost)
                    assert(UISlotCoverupCallBack({sid=1,cost=price})==1)''')
                with self.assertRaises((LuaError, ValueError)):
                    lua.globals().NetSlotCoverupCallBack(lua.table_from({b"rbuf": native + extra}))
                lua.execute(b'''assert(gamedata.cache.safemask==cover_old_mask and gamedata.cache.safemaskmaster==cover_old_masters)
                    assert(gamedata.cache.role.coin==cover_old_coin and gamedata.cache.props[20296].num==cover_old_props)
                    assert(gamedata.ext.localCoverBusy==3731)''')

    def test_actual_page_waits_for_cover_query_before_rendering_and_rejects_closed_reads(self):
        import build_local_apk as builder
        lua = test_soul.SoulTests.ui_lua(self)
        scripts = self.client_scripts()
        with zipfile.ZipFile(Path(__file__).parent / "configs_sec5.zip") as archive:
            lua.globals().gamedata.config.generalanimation = lua.table_from(
                json.loads(archive.read("5/generalanimation.json")), recursive=True)
        native = builder.read_script("ui", "common_lua").decode()
        lua.execute(native[native.index("function ui.getSTRandNUM("):native.index("function ui.getXGroupByString(")])
        native = builder.read_script("gamedata").decode()
        lua.execute(native[native.index("function gamedata.SafeMask("):native.index("function gamedata.GoddownStatus(")])
        lua.execute(scripts["assets/scripts/UISlots.so"].decode())
        lua.globals().cover_page = lua.execute(scripts["assets/scripts/Layer_safemask.so"].decode())
        lua.globals().mask_values = lua.table_from(protocol.parse_ids_pb(self.success(1, 3730)))
        generals = formation.records(bytes.fromhex(self.save["world_state"]["1002"]), 1, 2)
        lua.globals().cover_cids = lua.table_from([protocol.pb_get_varint(raw, 1) for raw in generals.values()][:2])
        lua.execute('''
            CCNode={create=node};LuaEventHandler={create=function(_,callback) return callback end}
            ui.createLuaTableView=function() return node() end
            ui.itemcache={loadSkeleton=function(_,name) assert(name);return node() end}
            ui.getGeneralAnimationid=function(name) return name end
            setControlButtonFrame=function() end
            guide={controller={addComplete=function() end}}
            gamedata.cache={};gamedata:SafeMask(mask_values)
            GameScene.protagonist={w_l=0,w_c=0};GameScene.roleinfo.coin=1000000
            GameScene.layers.slotsInfo={module={safemask={}}}
            GameScene.layers.safemask={show=true,module=cover_page}
            package.loaded.Layer_safemask=cover_page
            local slots={['1']={sid=1,general={cid=cover_cids[1]}},['4']={sid=4,general={cid=cover_cids[2]}}}
            local param={sid=4,slotdata=slots,safemask={}}
            requests={};cover_page:init(node(),0,param)
            assert(#requests==2 and requests[1].type==3730 and requests[2].type==3732)
            assert(not cover_page.localCoverReady and not cover_page.rootItems.upnode.visible
                and not cover_page.rootItems.feishengnode.visible)
            local old_view=requests[1].coverView
            assert(old_view.sid==4)
            cover_page:shiftPage('stage')
            assert(#requests==2 and not rawget(cover_page.rootItems.upButton,'callback'))
            local reply={coverView=old_view,safemask=gamedata.cache.safemask,safemaskmaster={}}
            UISlotCoverQuery(reply)
            assert(cover_page.localCoverReady and cover_page.rootItems.upnode.visible)
            assert(cover_page.safemask['4'].level==0 and cover_page.generalindex==2)
            assert(requests[#requests].type==12001 and requests[#requests].order==37322)
            cover_page:shiftPage('up')
            assert(cover_page.rootItems.num1.text==gamedata.config.mozhao_break['0'].value)
            assert(cover_page.rootItems.coin.text==15000 and cover_page.up_needprops['20296'].num==3)
            for _,req in ipairs(requests) do assert(req.type==3730 or req.type==3732 or req.type==12001) end
            cover_page:clear();GameScene.layers.safemask.show=false
            UISlotCoverQuery(reply)
            assert(cover_page.rootNode==nil)
            requests={};GameScene.layers.safemask.show=true
            cover_page:init(node(),0,param)
            assert(not cover_page.localCoverReady and requests[1].type==3730)
            UISlotCoverQuery(reply)
            assert(not cover_page.localCoverReady)
            reply.coverView=requests[1].coverView
            UISlotCoverQuery(reply)
            assert(cover_page.localCoverReady and cover_page.safemask['4'].level==0)
        ''')

    def test_actual_ui_updates_only_its_generation_and_animates_only_its_target(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("魔罩界面验证需 lupa.lua51")
        lua = LuaRuntime()
        scripts = self.client_scripts()
        for name in ("GameSlots", "UISlots", "Layer_safemask", "Layer_activity_safemaskshop", "UIActivitySafeMaskShop"):
            lua.compile(scripts[f"assets/scripts/{name}.so"].decode())
        lua.compile(scripts["assets/pb/localcoverupdate_pb.so"].decode())
        lua.execute('''
            print=function() end;printT=print
            UIRequest=function(t) request=t end
            page={rootNode={},localCoverGeneration=1,selectpage="up",generalindex=1,slotdata={["1"]={sid=1}},
                ReloadData=function(self) self.reloads=(self.reloads or 0)+1 end,
                ReloadMasterData=function() end,ReloadUpData=function(self) self.animations=(self.animations or 0)+1 end}
            package.loaded.Layer_safemask=page
            GameScene={layers={safemask={show=true},slotsInfo={module={}}},addUpdate=function() end}
        ''')
        code = scripts["assets/scripts/UISlots.so"].decode()
        start = code.index('-- 魔罩整组状态更新')
        lua.execute(code[start:])
        lua.execute('''
            UIRequest({type=3731,sid=1})
            local view=request.coverView
            local t={coverView=view,coverSID=1,safemask={},safemaskmaster={}}
            UISlotCoverup(t);assert(page.reloads==1 and page.animations==1)
            page.slotdata["1"].sid=2
            UISlotCoverup(t);assert(page.reloads==2 and page.animations==1)
            page.localCoverGeneration=2
            UISlotCoverup(t);assert(page.reloads==2 and page.animations==1)
            page.localCoverGeneration=1;GameScene.layers.safemask.show=false
            UISlotCoverup(t);assert(page.reloads==2 and page.animations==1)
        ''')
        lua.execute(scripts["assets/scripts/UIActivitySafeMaskShop.so"].decode())
        lua.execute('''
            shop={rootNode={},localCoverGeneration=1}
            package.loaded.Layer_activity_safemaskshop=shop
            local shown=0
            GameScene.layers.activity={show=true,module={pageTable={[53]={module={reloaddata=function() shown=shown+1 end}}}}}
            local t={coverView={shop=1},data={},reward={}}
            UISafeMaskShopQuery(t);assert(shown==1)
            shop.localCoverGeneration=2
            UISafeMaskShopQuery(t);assert(shown==1)
            showRewardPopupWindow=function(_,_,f) after=f end
            t.coverView.shop=2
            UISafeMaskShopReward(t)
            request=nil;shop.localCoverGeneration=3;after()
            assert(request==nil)
        ''')
