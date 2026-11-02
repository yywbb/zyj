import copy
from fractions import Fraction
import json
import random
import struct
import unittest
from unittest.mock import patch

import test_penglai
import build_local_apk as builder
from zyj_server import battle, formation, magic, player, protocol, ranking, recharge, recruit, single_boss, training


class MagicTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        test_penglai.PenglaiTests.setUpClass.__func__(cls)
        cls.baseline = copy.deepcopy(cls.baseline)
        cls.baseline["role_state"].update(level=31, coin=100000000, gold=100000)

    reconnect = test_penglai.PenglaiTests.reconnect
    call = test_penglai.PenglaiTests.call
    give = test_penglai.PenglaiTests.give
    props = test_penglai.PenglaiTests.props
    groups = test_penglai.PenglaiTests.groups
    assert_rejected = test_penglai.PenglaiTests.assert_rejected

    def setUp(self):
        test_penglai.PenglaiTests.setUp(self)
        self.give(20270, 10000)

    def query(self):
        return protocol.parse_ids_pb(self.call(1360)[0][16:])

    def unlock(self):
        self.call(1361, [1])

    def preview(self, method=1, count=1, cid=1, seed=0):
        data = protocol.parse_ids_pb(self.call(1362, [cid, method, count], seed)[0][16:])
        return data[:4], data[4], data[5]

    def confirm(self, token, keep=1, cid=1):
        return self.call(1363, [keep, cid, token])

    def change_magic(self, cid, **changes):
        before = magic.bonuses(self.session.save, self.config)
        self.session.save["magic_state"]["items"][str(cid)].update(changes)
        update, power = magic.differences(self.session.save, before, self.config)
        if update:
            player.apply_sigil_update(self.session.save, update, power, self.config)

    def seed_items(self, count):
        before = magic.bonuses(self.session.save, self.config)
        state = magic.get_state(self.session.save, self.config)
        state["items"] = {str(i): {"normal": magic.values(self.config["artifact"][str(i)], "initial"), "fairy": [0]*4, "stage": 0}
                          for i in range(1, count+1)}
        self.session.save["magic_state"] = state
        update, power = magic.differences(self.session.save, before, self.config)
        if update:
            player.apply_sigil_update(self.session.save, update, power, self.config)

    def test_query_is_native_shape_unlock_is_explicit_and_only_real_201_advances_guide(self):
        before = copy.deepcopy(self.session.save["world_state"])
        self.assertEqual(self.query(), [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1])
        self.assertEqual(before, self.session.save["world_state"])
        self.unlock()
        self.assertEqual(self.query()[:10], [1, 196, 109, 653, 300, 0, 0, 0, 0, 0])
        self.assertNotIn("65", self.session.save["guide"]["sections"])
        self.assert_rejected(1361, recharge.ids([1]))
        self.assert_rejected(1361, recharge.ids([3]))

    def test_paid_preview_changes_no_attributes_and_reconnect_restores_for_free(self):
        self.unlock()
        before, stones = copy.deepcopy(self.session.save), self.props(20270)
        values, token, actual = self.preview(3, 10)
        self.assertEqual((actual, stones-self.props(20270)), (10, 10))
        self.assertEqual(before["role_state"]["gold"]-self.session.save["role_state"]["gold"], 200)
        self.assertEqual(before["world_state"]["1002"], self.session.save["world_state"]["1002"])
        self.session = self.reconnect()
        self.assertEqual(self.preview(0, 0), (values, token, 0))
        self.confirm(token)
        self.assertEqual(self.query()[1:5], values)
        self.assertEqual(self.props(20270), stones-10)

    def test_legacy_stale_cross_target_and_duplicate_confirmations_fail_closed(self):
        self.unlock()
        token = self.preview()[1]
        newer = self.preview()[1]
        for values in ([1], [1, 1, token], [1, 2, newer], [2, 1, newer], [1, 1, 0]):
            self.assert_rejected(1363, recharge.ids(values))
        self.confirm(newer, 0)
        self.assert_rejected(1363, recharge.ids([1, 1, newer]))

    def test_automatic_charges_real_rolls_records_task25_and_rejects_pending(self):
        self.unlock()
        self.session.save["role_state"]["level"] = 55
        token = self.preview()[1]
        self.assert_rejected(1364, recharge.ids([1, 1, 10, 0, 0, 0, 0, 0]))
        self.confirm(token, 0)
        stones = self.props(20270)
        parts = self.groups(self.call(1364, [1, 1, 23, 0, 0, 0, 0, 0])[0][16:])
        self.assertEqual(protocol.parse_ids_pb(parts[3]), [23, 10, 10, 3])
        self.assertEqual(len(protocol.parse_ids_pb(parts[2])), 15)
        self.assertEqual(stones-self.props(20270), 46)
        self.assertGreaterEqual(self.session.save["activity_state"]["liveness_counts"]["25"], 1)
        self.call(2411, [125])
        self.assert_rejected(2411, recharge.ids([125]))

    def test_save_failure_and_success_retry_do_not_double_charge(self):
        self.unlock()
        self.sequence += 1
        body = recharge.ids([1, 3, 1])
        packets = self.session.handle(1362, self.sequence, body)
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 1362)
        memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        self.assertEqual(self.session.handle(1362, self.sequence, body), packets)
        with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
            self.session.handle(1362, self.sequence+1, body)
        self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))

    def test_all_54_wave_tables_ten_bands_and_nine_profiles_have_exact_bounded_units(self):
        for cid in range(1, 10):
            for stage in (0, 1):
                row = self.config["artifact_xian_config"][str(cid)]["1"] if stage else self.config["artifact"][str(cid)]
                caps = magic.values(row, "init")
                for method in (1, 2, 3):
                    table = self.config["artifact_baptize_xian"][str((cid-1)*3+method)] if stage else self.config["artifact_baptize"][str(cid)][str(method)]
                    for band in range(1, 11):
                        data = [v*(band-1)//10 for v in caps]
                        after, done = magic.roll(data, row, table, 10, random.Random(7))
                        self.assertTrue(1 <= done <= 10)
                        self.assertTrue(all(0 <= v <= cap for v, cap in zip(after, caps)))
                        self.assertEqual((after, done), magic.roll(data, row, table, 10, random.Random(7)))
                if caps[3] < 100:
                    self.assertEqual(caps[3], round(row["init4"]*100))

    def test_strict_payloads_locks_limits_funds_and_unmatched_combs_are_non_mutating(self):
        for opcode, values in ((1360, [1]), (1361, []), (1362, [1, 1]), (1363, [1]), (1364, [1]*7), (1365, [0])):
            self.assert_rejected(opcode, recharge.ids(values))
        self.unlock()
        for opcode in magic.OPCODES:
            for body in (b"\x08", b"\x0a\x00", b"\x10\x00"):
                self.assert_rejected(opcode, body)
        for values in ([1, 0, 1], [1, 4, 1], [1, 1, 50], [1, 1, 5], [2, 1, 1]):
            self.assert_rejected(1362, recharge.ids(values))
        for values in ([1, 1, 10, 0, 0, 0, 0, 0], [1, 1, 0, 0, 0, 0, 0, 0], [1, 1, 201, 0, 0, 0, 0, 0], [1, 1, 10, 2, 0, 0, 0, 0]):
            self.assert_rejected(1364, recharge.ids(values))
        baseline = copy.deepcopy(self.session.save)
        for key, value, request in (("level", 30, [1, 1, 1]), ("coin", 0, [1, 2, 1]), ("gold", 19, [1, 3, 1])):
            self.session.save = copy.deepcopy(baseline)
            self.session.save["role_state"][key] = value
            self.assert_rejected(1362, recharge.ids(request))
        self.session.save = baseline
        comb = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 1362)+protocol.encode_pb_field(2, 2, recharge.ids([1, 1, 1])))
        self.assert_rejected(999900, comb)

    def test_three_normal_prices_vip_auto_and_level_eighty_limits(self):
        self.unlock()
        for method, stones, coin, gold in ((1, 2, 0, 0), (2, 1, 30000, 0), (3, 1, 0, 20)):
            before = self.props(20270), self.session.save["role_state"].copy()
            token = self.preview(method)[1]
            self.assertEqual((before[0]-self.props(20270), before[1]["coin"]-self.session.save["role_state"]["coin"],
                              before[1]["gold"]-self.session.save["role_state"]["gold"]), (stones, coin, gold))
            self.confirm(token, 0)
        self.session.save["role_state"]["vip"] = 5
        self.call(1364, [1, 1, 200, 0, 0, 0, 0, 0])
        self.session.save["role_state"]["level"] = 80
        self.confirm(self.preview(3, 50)[1], 0)
        self.call(1364, [1, 1, 1000, 0, 0, 0, 0, 0])
        self.assert_rejected(1364, recharge.ids([1, 1, 1001, 0, 0, 0, 0, 0]))

    def test_two_magic_previews_have_independent_tokens_and_reconnect_without_cross_confirmation(self):
        self.seed_items(2)
        first = self.preview(cid=1)
        second = self.preview(cid=2)
        self.assertNotEqual(first[1], second[1])
        self.assert_rejected(1363, recharge.ids([1, 1, second[1]]))
        self.session = self.reconnect()
        self.assertEqual(self.preview(0, 0, cid=1)[:2], first[:2])
        self.assertEqual(self.preview(0, 0, cid=2)[:2], second[:2])
        self.confirm(second[1], cid=2)
        self.confirm(first[1], cid=1)

    def test_every_magic_and_both_tiers_use_configured_costs_without_id_table_aliasing(self):
        self.seed_items(9)
        self.session.save["role_state"]["level"] = 100
        self.give(1025, 100000)
        for cid in range(1, 10):
            for stage in (0, 1):
                row = self.config["artifact_xian_config"][str(cid)]["1"] if stage else self.config["artifact"][str(cid)]
                self.change_magic(cid, stage=stage, normal=magic.values(self.config["artifact"][str(cid)], "init" if stage else "initial"),
                                  fairy=magic.values(row, "initial") if stage else [0]*4)
                for method in (1, 2, 3):
                    before = {20270: self.props(20270), **{c: self.session.save["role_state"][k] for c, k in ((1000, "coin"), (1001, "gold"), (1025, "g_gold"))}}
                    token = self.preview(method, cid=cid)[1]
                    text = row[f"forging_consume{method}"] if stage else self.config["global_kv"][f"artifact_consume_{method}"]["value"]
                    fees = dict(tuple(map(int, entry.split(","))) for entry in text.split(";") if entry)
                    after = {20270: self.props(20270), **{c: self.session.save["role_state"][k] for c, k in ((1000, "coin"), (1001, "gold"), (1025, "g_gold"))}}
                    self.assertEqual({c: before[c]-after[c] for c in before}, {c: fees.get(c, 0) for c in before})
                    self.confirm(token, 0, cid=cid)

    def test_full_cap_stops_real_rolls_and_confirmation_is_required_before_breakthrough(self):
        self.unlock()
        self.session.save["role_state"]["level"] = 100
        caps = magic.values(self.config["artifact"]["1"], "init")
        self.change_magic(1, normal=[v-1 for v in caps])
        table = {**self.config["artifact_baptize"]["1"]["3"], **{name+key+"10": 1 for name in ("atk", "def", "hp", "adddmg") for key in ("down", "up")}}
        with patch.dict(self.config["artifact_baptize"]["1"], {"3": table}):
            stones, gold = self.props(20270), self.session.save["role_state"]["gold"]
            values, token, done = self.preview(3, 50)
            self.assertEqual((values, done, stones-self.props(20270), gold-self.session.save["role_state"]["gold"]), (caps, 1, 1, 20))
        self.assert_rejected(1365, recharge.ids([1]))
        self.confirm(token)
        self.assert_rejected(1362, recharge.ids([1, 1, 1]))
        self.give(1025, 1000)
        self.call(1365, [1])
        self.assert_rejected(1365, recharge.ids([1]))

    def test_breakthrough_fairy_costs_project_to_v2_without_enabling_advanced_generals(self):
        self.unlock()
        self.session.save["role_state"]["level"] = 99
        self.change_magic(1, normal=magic.values(self.config["artifact"]["1"], "init"))
        self.give(1025, 1000)
        self.assert_rejected(1365, recharge.ids([1]))
        self.session.save["role_state"]["level"] = 100
        before = copy.deepcopy(self.session.save)
        packets = self.call(1365, [1])
        row = self.config["artifact_xian_config"]["1"]["1"]
        costs = dict(tuple(map(int, entry.split(","))) for entry in row["breach_consume"].split(";") if entry)
        self.assertEqual(self.props(20270), next(protocol.pb_get_varint(v, 2) for n, w, v in protocol.iter_pb_fields(bytes.fromhex(before["world_state"]["1200"])) if (n, w) == (1, 2) and protocol.pb_get_varint(v, 1) == 20270)-costs[20270])
        self.assertEqual(self.session.save["role_state"]["g_gold"], 1000-costs[1025])
        self.assertIn(1027, [struct.unpack(">IIII", p[:16])[2] for p in packets])
        self.assertEqual(self.query()[5:10], [1, *magic.values(row, "initial")])
        for method in (1, 2, 3):
            gold = self.session.save["role_state"]["g_gold"]
            token = self.preview(method)[1]
            fee = dict(tuple(map(int, entry.split(","))) for entry in row[f"forging_consume{method}"].split(";") if entry)
            self.assertEqual(gold-self.session.save["role_state"]["g_gold"], fee.get(1025, 0))
            self.confirm(token)
        world = bytes.fromhex(self.session.save["world_state"]["1002"])
        self.assertTrue(all(not any(protocol.pb_get_varint(raw, f) for f in range(21, 41)) for raw in formation.records(world, 1, 2).values()))
        attack, _ = battle.rosters(self.session.save, self.config["copy"]["42102"]["1"], self.config)
        self.assertTrue(attack)
        role = player.apply_role_state(bytes.fromhex(self.session.save["role_snapshot"]), self.session.save, test_penglai.NOW)
        self.assertEqual(protocol.pb_get_varint(role, 25), self.session.save["role_state"]["g_gold"])
        self.assertEqual(self.props(1025), 0)

    def test_global_attributes_swaps_growth_and_dedicated_teams_apply_exactly_once(self):
        iid = 2000888
        raw = recruit.new_general(10201, iid, self.config)
        player.record_slot_update(self.session.save, protocol.encode_pb_field(1, 2, raw))
        original = formation.records(bytes.fromhex(self.session.save["world_state"]["1002"]), 1, 2)
        self.unlock()
        current = formation.records(bytes.fromhex(self.session.save["world_state"]["1002"]), 1, 2)
        self.assertEqual(current[iid], raw)
        slots = formation.records(bytes.fromhex(self.session.save["world_state"]["1002"]), 4, 2)
        for active in slots:
            if active:
                self.assertEqual(protocol.pb_get_varint(current[active], 6)-protocol.pb_get_varint(original[active], 6), 196)
        body = protocol.encode_pb_field(1, 0, 2)+protocol.encode_pb_field(3, 0, iid)
        self.assertEqual(struct.unpack(">IIII", self.session.handle(1003, 901, body)[0][:16])[2], 1003)
        current = formation.records(bytes.fromhex(self.session.save["world_state"]["1002"]), 1, 2)
        self.assertEqual(protocol.pb_get_varint(current[iid], 6)-protocol.pb_get_varint(raw, 6), 196)
        before = copy.deepcopy(self.session.save["world_state"])
        team = protocol.parse_ids_pb(self.call(3702, [140, 1])[0][16:])[:8]
        temporary, _ = single_boss.project_team(self.session.save, team, self.config)
        point = self.config["copy"]["42102"]["1"]
        self.assertEqual(battle.rosters(temporary, point, self.config)[0], battle.rosters(self.session.save, point, self.config)[0])
        self.assertEqual(before, self.session.save["world_state"])
        grown, _, _ = training.grow_general(current[iid], 1000, b"", set(), {}, self.config, 62)
        plain, _, _ = training.grow_general(raw, 1000, b"", set(), {}, self.config, 62)
        self.assertEqual(protocol.pb_get_varint(grown, 6)-protocol.pb_get_varint(plain, 6), 196)

    def test_fairy_rate_fractions_and_fixed_damage_reach_all_battles_without_rounding_loss(self):
        self.seed_items(3)
        self.change_magic(3, normal=magic.values(self.config["artifact"]["3"], "init"), stage=1, fairy=[0, 0, 0, 1])
        stats, flat = magic.bonuses(self.session.save, self.config)
        self.assertEqual(stats[11], Fraction(101, 10))
        attack, _ = battle.rosters(self.session.save, self.config["copy"]["42102"]["1"], self.config)
        for unit in attack.values():
            self.assertEqual(unit["pet_rates"]["dodge"], Fraction(1, 10))
            self.assertEqual(unit["flat_out"], 300)
        self.assertEqual(flat, [300, 0])
        unit = {"cid": 10201, "iid": 10201, "level": 1, "advance": 0, "exp": 0, "atk": 10000,
                "def": 0, "hp": 1000000, "speed": 200, "critical": 100, "skill": self.config["general"]["10201"]["skillid"]}
        enemy = {**unit, "iid": 1, "speed": 100, "atk": 1}
        plain = battle.simulate({2: unit}, {2: enemy}, self.config, 7)
        modified = battle.simulate({2: {**unit, "pet_rates": {"criticaldmg": Fraction(1, 10)}}}, {2: enemy}, self.config, 7)
        self.assertEqual(modified["b"]["a"][0]["e"][0]["m"]["m"]-plain["b"]["a"][0]["e"][0]["m"]["m"], 10)

    def test_auto_filters_early_cap_and_partial_row_charge_the_actual_attempts_only(self):
        self.unlock()
        self.session.save["role_state"]["level"] = 100
        baseline = copy.deepcopy(self.session.save)
        for flags in ((1, 0, 0, 0, 0), (1, 1, 1, 1, 0), (0, 0, 0, 0, 1)):
            self.session.save = copy.deepcopy(baseline)
            before = self.session.save["magic_state"]["items"]["1"]["normal"][:]
            self.call(1364, [1, 1, 23, *flags])
            after = self.session.save["magic_state"]["items"]["1"]["normal"]
            for a, b, flag in zip(before, after, flags):
                if flag: self.assertGreaterEqual(b, a)
            if flags[4]: self.assertGreaterEqual(magic.score(after, self.config["artifact"]["1"]), magic.score(before, self.config["artifact"]["1"]))
        self.session.save = copy.deepcopy(baseline)
        caps = magic.values(self.config["artifact"]["1"], "init")
        self.change_magic(1, normal=[v-1 for v in caps])
        table = {**self.config["artifact_baptize"]["1"]["3"], **{name+key+"10": 1 for name in ("atk", "def", "hp", "adddmg") for key in ("down", "up")}}
        stones, gold = self.props(20270), self.session.save["role_state"]["gold"]
        with patch.dict(self.config["artifact_baptize"]["1"], {"3": table}):
            parts = self.groups(self.call(1364, [1, 3, 23, 0, 0, 0, 0, 0])[0][16:])
        self.assertEqual(protocol.parse_ids_pb(parts[3]), [1, 1])
        self.assertEqual((stones-self.props(20270), gold-self.session.save["role_state"]["gold"]), (1, 20))

    def test_real_unlock_conditions_use_owned_state_and_do_not_grant_task_rewards(self):
        self.unlock()
        self.assertEqual(self.query()[-11:][2::2], [1, 0, 0, 0, 0])
        self.assert_rejected(1361, recharge.ids([2]))
        save = self.session.save
        point = protocol.encode_pb_field(1, 0, 10)+protocol.encode_pb_field(2, 0, 1)+protocol.encode_pb_field(3, 0, 1)
        copy_row = protocol.encode_pb_field(1, 0, 42115)+protocol.encode_pb_field(7, 2, point)
        save["world_state"]["1300"] = (bytes.fromhex(save["world_state"]["1300"])+protocol.encode_pb_field(1, 2, copy_row)).hex()
        magic.record_count(save, "stone_copy", 10, self.config)
        generals = [int(cid) for cid, r in self.config["general"].items() if r["battle"] and r["init_cid"] == int(cid) and r["quality"] == 5][:2]
        for i, cid in enumerate(generals):
            player.record_slot_update(save, protocol.encode_pb_field(1, 2, recruit.new_general(cid, 2000800+i, self.config)))
        slots = formation.records(bytes.fromhex(save["world_state"]["1002"]), 4, 1)
        for sid in range(1, self.config["role_exp"]["31"]["slotnum"]+1):
            raw = slots.get(sid, protocol.encode_pb_field(1, 0, sid))
            for f in range(18, 26): raw = protocol.pb_set_varint(raw, f, 1)
            player.record_slot_update(save, protocol.encode_pb_field(4, 2, raw))
        self.assertEqual(magic.progress(save, 2, self.config)[1::2], [1]*5)
        before = save["world_state"]["1200"]
        self.call(1361, [2])
        self.assertEqual(self.session.save["world_state"]["1200"], before)
        self.assertEqual(self.query()[10], 2)

    def test_cumulative_counters_count_actual_fights_and_gold_quantity_not_old_daily_state(self):
        self.session.save["role_state"]["level"] = 150
        with patch.dict(self.config["daily_function"]["3"], date="1;2;3;4;5;6;7"):
            self.call(1343, [1])
        self.assertEqual(magic.get_state(self.session.save, self.config)["counts"]["stone_copy"], 1)
        self.call(3630)
        state = self.session.save["blackmarket_state"]
        choice = next(row for row in self.config["blackmarket_items"].values() if row["consume"].startswith("1001,"))
        state["slots"][0] = [choice["id"], 0]
        state["slots"][1] = [choice["id"], 0]
        self.call(3631, [1, 1])
        self.call(3631, [2, 1])
        self.assertEqual(magic.get_state(self.session.save, self.config)["counts"], {"stone_copy": 1, "blackmarketgoldbuycount": 2})
        self.session = self.reconnect()
        self.clock.return_value += 86400
        self.call(3630)
        self.assertEqual(self.session.save["magic_state"]["counts"]["blackmarketgoldbuycount"], 2)

    def test_last_two_unlocks_are_not_fabricated_while_ordinary_breakthrough_stops_at_ten(self):
        self.seed_items(7)
        self.session.save["role_state"].update(level=150, power=20000000)
        state = self.session.save["magic_state"]
        state["counts"].update(stone_copy=500, blackmarketgoldbuycount=300)
        self.assertEqual(magic.progress(self.session.save, 8, self.config)[7], 0)
        self.assert_rejected(1361, recharge.ids([8]))

    def test_rank_score_is_actual_per_magic_bonuses_and_projection_is_read_only(self):
        self.unlock()
        before = copy.deepcopy(self.session.save)
        self.assertEqual(ranking.entry(1, self.session.save, self.config)["scores"]["16"], 196+109+65+300)
        self.assertEqual(before, self.session.save)

    def test_fairy_currency_rewards_use_role25_never_inventory_and_refuse_overflow(self):
        reward = recruit.build_reward(self.session.save, [(1025, 7)], self.config)
        player.apply_reward(self.session.save, reward, self.config, test_penglai.NOW)
        self.assertEqual((self.session.save["role_state"]["g_gold"], self.props(1025)), (7, 0))
        before = copy.deepcopy(self.session.save)
        with self.assertRaises(ValueError):
            player.change_item_count(self.session.save, 1025, 1 << 31, self.config)
        self.assertEqual(before, self.session.save)

    def test_magic_gift_requires_real_s65_and_persists_simulated_payment_and_claim(self):
        self.assert_rejected(2882, recharge.ids([130016]))
        for step in range(1, self.steps[65]+1):
            self.session.handle(201, 1600+step, protocol.encode_pb_field(1, 0, 65)+protocol.encode_pb_field(2, 0, step))
        self.assertEqual(protocol.parse_ids_pb(self.call(2882, [130016])[0][16:]), [130016, 0, 43200])
        request = b"".join(protocol.encode_pb_field(1, 2, recharge.ids([v])) for v in (3, 130016))
        packet = self.session.handle(115, 1700, request)[0]
        order = protocol.pb_get_varint(next(v for n, w, v in protocol.iter_pb_fields(packet[16:]) if (n, w) == (1, 2)), 1)
        gold = self.session.save["role_state"]["gold"]
        self.call(116, [order])
        self.assertEqual(gold, self.session.save["role_state"]["gold"])
        self.session = self.reconnect()
        stones, coin = self.props(20270), self.session.save["role_state"]["coin"]
        self.call(2881, [130016])
        self.assertEqual((self.props(20270)-stones, self.session.save["role_state"]["coin"]-coin), (300, 200000))
        self.assert_rejected(2881, recharge.ids([130016]))

    def test_corruption_overflow_and_failed_confirmation_keep_all_resources_and_snapshots(self):
        self.unlock()
        token = self.preview(3)[1]
        memory = copy.deepcopy(self.session.save)
        for key, value in (("serial", True), ("items", []), ("counts", {"stone_copy": -1, "blackmarketgoldbuycount": 0}), ("pending", {"1": {}})):
            self.session.save = copy.deepcopy(memory)
            self.session.save["magic_state"][key] = value
            self.assert_rejected(1360, b"")
        self.session.save = copy.deepcopy(memory)
        self.session.save["role_state"]["power"] = (1 << 31)-1
        self.assert_rejected(1363, recharge.ids([1, 1, token]))
        self.session.save = memory
        disk = self.path.read_bytes()
        with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
            self.confirm(token)
        self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))

    @classmethod
    def client_scripts(cls):
        if not hasattr(cls, "_client_scripts"):
            cls._client_scripts = {}
            for name, raw in builder.get_patched_lua_scripts().items():
                data = builder.xxtea_decrypt(raw, builder.XXTEA_KEY)
                cls._client_scripts[name] = data[:struct.unpack("<I", data[-4:])[0]]
        return cls._client_scripts

    def network_lua(self):
        import test_activity_copy
        lua = test_activity_copy.ActivityCopyTests.network_lua(self)
        for name in ("slots_pb", "combmessages_pb", "error_pb", "params_pb"):
            lua.execute(builder.read_script(name, "pb"))
        code = builder.read_script("gamedata").decode().replace("\r\n", "\n")
        for start, end in (("function gamedata.magic(", "function gamedata.mazeShop("),
                           ("function gamedata.getIDandNUMs(", "function gamedata.getIds(")):
            lua.execute(code[code.index(start):code.index(end)].encode())
        lua.execute(b'''gamedata.cache.magicdata={unlock={}};gamedata.cache.props={[20270]={num=10000}}
            gamedata.updateRoleCoin=function(self,n) self.cache.role.coin=self.cache.role.coin+n end
            gamedata.updateRoleGold=function(self,n) self.cache.role.gold=self.cache.role.gold+n end
            gamedata.updateRoleG_gold=function(self,n) self.cache.role.g_gold=self.cache.role.g_gold+n end
            gamedata.updateprops=function(self,p) self.cache.props[p.cid].num=self.cache.props[p.cid].num+p.num end
            gamedata.SlotInfoProcess=function(self,data) self.lastSlots=data end
            package.loaded.logError={errorMessage={},errorFunc={}};printf=function() end
            initPb=function(mod,fd) local m=mod.Ids();m:ParseFromString(fd.rbuf);return m end''')
        for key in ("coin", "gold", "g_gold", "level"):
            lua.globals().gamedata[b"cache"][b"role"][key.encode()] = self.session.save["role_state"][key]
        lua.globals().gamedata[b"cache"][b"props"][20270][b"num"] = self.props(20270)
        lua.execute(self.client_scripts()["assets/scripts/GameMagic.so"])
        lua.execute(self.client_scripts()["assets/common_lua/GameErrorMessage.so"])
        self.assertIsNone(lua.globals().gameConfig)
        return lua

    def client_call(self, lua, send, receive, request):
        mode, opcode, body = getattr(lua.globals(), send)(lua.table_from({k.encode(): v for k, v in request.items()}))
        self.assertEqual(mode, 1)
        self.sequence += 1
        packet = self.session.handle(opcode, self.sequence, body)[0]
        self.assertEqual(struct.unpack(">IIII", packet[:16])[2], opcode)
        return getattr(lua.globals(), receive)(lua.table_from({b"rbuf": packet[16:]}))

    def test_actual_lua_pb_preview_confirm_restore_and_error_unlock_without_ui_globals(self):
        lua = self.network_lua()
        self.client_call(lua, "UIInstrumentQueryCallback", "NetInstrumentQueryCallback", {"view": 4})
        self.client_call(lua, "UIInstrumentUnlockCallback", "NetInstrumentUnlockCallback", {"id": 1, "view": 4})
        self.client_call(lua, "UIInstrumentQueryCallback", "NetInstrumentQueryCallback", {"view": 4})
        for method in (1, 2, 3):
            result = self.client_call(lua, "UIInstrumentForgePreview", "NetInstrumentForgePreview", {"id": 1, "typeIndex": method, "times": 10, "view": 4})
            token = result[b"token"]
            self.assertEqual((result[b"id"], result[b"view"]), (1, 4))
            result = self.client_call(lua, "UIInstrumentForgePreview", "NetInstrumentForgePreview", {"id": 1, "typeIndex": 0, "times": 0, "view": 4})
            self.assertTrue(result[b"restored"])
            self.assertEqual(result[b"token"], token)
            result = self.client_call(lua, "UIInstrumentForgeConfirm", "NetInstrumentForgeConfirm", {"id": 1, "typeIndex": 1, "token": token, "view": 4})
            self.assertEqual(result[b"isChage"], 1)
            role = lua.globals().gamedata[b"cache"][b"role"]
            self.assertEqual((role[b"coin"], role[b"gold"]), tuple(self.session.save["role_state"][k] for k in ("coin", "gold")))
            self.assertEqual(lua.globals().gamedata[b"cache"][b"props"][20270][b"num"], self.props(20270))
        request = lua.table_from({b"id": 1, b"typeIndex": 1, b"times": 1})
        self.assertEqual(lua.globals().UIInstrumentForgePreview(request)[0], 1)
        self.assertEqual(lua.globals().UIInstrumentQueryCallback(lua.table())[0], 0)
        lua.globals().NetErrorMessageCallback9(lua.table_from({b"rbuf": recharge.ids([1362, 0])}))
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localMagicBusy"])
        self.assertEqual(lua.globals().UIInstrumentQueryCallback(lua.table())[0], 1)

    def test_actual_auto_lua_preserves_signed_deltas_partial_counts_and_fairy_currency(self):
        self.unlock()
        self.session.save["role_state"]["level"] = 100
        lua = self.network_lua()
        self.client_call(lua, "UIInstrumentQueryCallback", "NetInstrumentQueryCallback", {})
        result = self.client_call(lua, "UIInstrumentForgeAutomaticCallback", "NetInstrumentForgeAutomaticCallback",
                                  {"iid": 1, "method": 1, "xlnum": 23, "view": 4, "window": 8})
        self.assertEqual((result[b"autotimes"], result[b"window"], result[b"status"][b"3"][b"count"]), (23, 8, 3))
        self.assertEqual(lua.globals().gamedata[b"cache"][b"props"][20270][b"num"], self.props(20270))
        self.change_magic(1, normal=magic.values(self.config["artifact"]["1"], "init"))
        self.give(1025, 1000)
        lua.globals().gamedata[b"cache"][b"role"][b"g_gold"] = self.session.save["role_state"]["g_gold"]
        self.client_call(lua, "UIBreakForgePreview", "NetBreakForgePreview", {"id": 1})
        self.client_call(lua, "UIInstrumentQueryCallback", "NetInstrumentQueryCallback", {})
        result = self.client_call(lua, "UIInstrumentForgePreview", "NetInstrumentForgePreview", {"id": 1, "typeIndex": 3, "times": 10})
        self.assertEqual(result[b"data"][b"requestData"][b"tuPoStatus"], 1)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"g_gold"], self.session.save["role_state"]["g_gold"])
        self.assertEqual(lua.globals().gamedata[b"cache"][b"props"][20270][b"num"], self.props(20270))

    def ui_lua(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("实际APK界面验证需要本机已有lupa.lua51")
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.globals().gamedata = lua.table_from({"config": self.config}, recursive=True)
        code = builder.read_script("gamedata").decode().replace("\r\n", "\n")
        lua.execute(code[code.index("function gamedata.getIDandNUMs("):code.index("function gamedata.getIds(")])
        lua.execute('''print=function() end; printT=print; CCControlEventTouchUpInside=1
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            requests={};UIRequest=function(t) requests[#requests+1]=t end
            function node() return setmetatable({size={width=100,height=100}}, {__index=function(t,k)
                if k=="addHandleOfControlEvent" then return function(self,f) self.callback=f end end
                if k=="getContentSize" then return function(self) return self.size end end
                if k=="getPositionX" or k=="getPositionY" then return function() return 0 end end
                if k=="setString" then return function(self,v) self.text=v end end
                return function() end
            end}) end
            function items() return setmetatable({}, {__index=function(t,k) local n=node();rawset(t,k,n);return n end}) end
            CCBReaderLoad=function() lastItems=items();return node(),lastItems end
            ui=setmetatable({setLabelString=function(n,v) if v then n:setString(v) end end,
                Split=function(text,separator) local r={} for s in string.gmatch(text,"[^"..separator.."]+") do r[#r+1]=s end return r end,
                createLuaTableView=node,getIDandNUMs=gamedata.getIDandNUMs}, {__index=function() return function() end end})
            gameConfig={originSize={width=1080,height=1920},strings={string_common=function() return "法宝" end,
                attr_type=setmetatable({}, {__index=function(t,k) return k end})}}
            GameScene={roleinfo={level=31,coin=100000000,gold=100000,g_gold=1000},vip={vip=0},layers={},addUpdate=function() end}
            gameWindows={windows={},openWindow=function() end};gameTouch={clickprofbytime=function() end};ccc3=function() return {} end
            guide={controller={addComplete=function() end}};LuaEventHandler={create=function(self,f) lastListHandler=f;return f end}
            CCTableViewCell={create=node}
            setSpriteFrameByName=function() end;runGamePrompt=function() end''')
        page = lua.execute(self.client_scripts()["assets/scripts/Layer_magic.so"].decode())
        lua.globals().GameScene.layers.magic = lua.table_from({"show": True, "module": page})
        lua.execute(self.client_scripts()["assets/scripts/UIMagic.so"].decode())
        page.init(page, lua.globals().node(), 1920, lua.table())
        return lua, page

    def test_actual_magic_page_restores_own_token_and_ignores_closed_old_view_and_other_target(self):
        lua, page = self.ui_lua()
        self.assertEqual(lua.globals().requests[1].view, page.localMagicView)

        def query_data():
            data = self.query()
            unlocked = [{"id": data[i], "istupo": data[i+5], **{f"attr{j}": data[i+j if j <= 4 else i+j+1] for j in range(1, 9)}} for i in range(0, len(data)-11, 10)]
            lock = {"id": data[-11], **{f"task{i}{key}": data[-11+2*i-1+offset] for i in range(1, 6) for key, offset in (("Num", 0), ("Complete", 1))}}
            return {"id": -1, "view": page.localMagicView, "data": {"unlock": unlocked, "lock": lock}, "stoneNum": self.props(20270), "g_goldNum": 0, "rolelv": 31}

        data = query_data()
        lua.globals().UIInstrumentQuery(lua.table_from(data, recursive=True))
        page.rootItems.lockButton.callback()
        self.assertEqual((lua.globals().requests[len(lua.globals().requests)].type, lua.globals().requests[len(lua.globals().requests)].id), (1361, 1))
        self.unlock()
        data = query_data()
        lua.globals().UIInstrumentQuery(lua.table_from(data, recursive=True))
        request = lua.globals().requests[len(lua.globals().requests)]
        self.assertEqual((request.type, request.id, request.typeIndex, request.times), (1362, 1, 0, 0))
        values, token, _ = self.preview(3)
        result = {"id": 1, "view": page.localMagicView, "token": token, "data": {"data": dict(zip(map(str, range(1, 5)), values)), "num": self.props(20270), "g_goldNum": 0,
                  "requestData": {"id": 1, "times": 1, "tuPoStatus": 0}, "magicdata": data["data"]}}
        lua.globals().UIInstrumentForgePreview(lua.table_from(result, recursive=True))
        page.rootItems.upTenButton.callback()
        request = lua.globals().requests[len(lua.globals().requests)]
        self.assertEqual((request.type, request.id, request.token, request.typeIndex), (1363, 1, token, 1))
        page.localMagicToken = 999
        result["id"] = 2
        lua.globals().UIInstrumentForgePreview(lua.table_from(result, recursive=True))
        self.assertEqual(page.localMagicToken, 999)
        result["id"], result["view"] = 1, page.localMagicView-1
        lua.globals().UIInstrumentForgePreview(lua.table_from(result, recursive=True))
        self.assertEqual(page.localMagicToken, 999)
        page.clear(page)
        lua.globals().UIInstrumentQuery(lua.table_from(data, recursive=True))
        self.assertIsNone(page.rootItems)

    def test_actual_auto_window_sends_integer_count_own_generation_and_displays_partial_rows(self):
        lua, page = self.ui_lua()
        window = lua.execute(self.client_scripts()["assets/scripts/window_instrumentForgeAutomatic.so"].decode())
        window.open(window, -100, lua.table_from({"iid": 1, "method": 2, "tuPoStatus": 0, "view": page.localMagicView}), None)
        window.hasstonenum = 10000
        window.numchange(window, 13.9)
        self.assertEqual(window.donum, 23)
        window.rootItems.doButton.callback()
        request = lua.globals().requests[len(lua.globals().requests)]
        self.assertEqual((request.type, request.xlnum, request.view, request.window), (1364, 23, page.localMagicView, window.localMagicWindow))
        window.status = lua.table_from({"1": {"method": 1, "num1": 1, "num2": -1, "num3": 0, "num4": 1, "count": 3}}, recursive=True)
        window.rnum, window.doButtonNum = 1, 1
        lua.globals().lastListHandler("cellAtIndex", None, 0, None)
        self.assertIn("实际3次", lua.globals().lastItems.x_title.text)
        lua.globals().gameWindows.windows.instrumentForgeAutomatic = lua.table_from({"show": True, "module": window})
        window.reloadData = lua.eval("function(self,t) self.reloaded=t.autotimes end")
        result = {"id": 1, "view": page.localMagicView, "window": window.localMagicWindow-1, "autotimes": 3}
        lua.globals().UIInstrumentForgeAutomatic(lua.table_from(result))
        self.assertIsNone(window.reloaded)
        result["window"] = window.localMagicWindow
        lua.globals().UIInstrumentForgeAutomatic(lua.table_from(result))
        self.assertEqual(window.reloaded, 3)


if __name__ == "__main__":
    unittest.main()
