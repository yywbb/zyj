"""猎命和命格：临时账号、真实费用/属性/17条成就，不修改正式角色。"""

import copy
from fractions import Fraction
import json
import random
import struct
import unittest
import zipfile
from unittest.mock import patch

import test_friends
import build_local_apk as builder
from zyj_server import achievements, activities, battle, formation, guild, player, protocol, recharge, recruit, soul, timebag


def setUpModule():
    with patch("time.time",return_value=1793430000):
        test_friends.setUpModule()


class SoulTests(unittest.TestCase):
    request = test_friends.FriendsTests.request
    success = test_friends.FriendsTests.success
    records = test_friends.FriendsTests.records
    groups = test_friends.FriendsTests.groups
    reconnect = test_friends.FriendsTests.reconnect
    add_account = test_friends.FriendsTests.add_account
    client_scripts = classmethod(test_friends.FriendsTests.client_scripts.__func__)
    client_call = test_friends.FriendsTests.client_call

    def setUp(self):
        test_friends.FriendsTests.setUp(self)
        self.save = self.sessions[1].save
        self.save["role_state"].update(level=55, coin=200000000, gold=1000000)
        self.now = int(self.clock.return_value)

    def items(self, account=1):
        return soul.read_world(self.sessions[account].save, self.config)[0]

    def props(self, cid):
        raw = formation.records(bytes.fromhex(self.save["world_state"]["1200"]), 1, 1).get(cid, b"")
        return protocol.pb_get_varint(raw, 2) or 0

    def grant(self, cid, count=1):
        reward = activities.build_reward(self.save, f"{cid},{count}", self.config)
        player.apply_reward(self.save, reward, self.config, self.now)
        return max(self.items()) if cid != 70000 and str(cid) in self.config["soul"] else None

    def wear(self, iid, sid=1, pos=1):
        raw = b"".join(protocol.encode_pb_field(n, 0, v) for n, v in ((1, sid), (2, pos), (3, iid)))
        return self.success(1, 1006, raw=raw)

    def quick_upgrade(self, cost, sid=1):
        items, slots = soul.read_world(self.save, self.config)
        values = [0, sid, protocol.pb_get_varint(slots[sid], 2), cost]
        for pos in range(1, 9):
            iid = protocol.pb_get_varint(slots[sid], pos + 9) or 0
            values.extend((iid, items[iid][2] if iid else 0))
        return values

    def assert_rejected(self, opcode, account=1, **kwargs):
        before = copy.deepcopy(self.sessions[account].save)
        disk = self.store.path(account).read_bytes()
        self.assertEqual([mid for mid, _ in self.request(account, opcode, **kwargs)], [999999, 1999])
        self.assertEqual((self.sessions[account].save, self.store.path(account).read_bytes()), (before, disk))

    def gen(self, iid=None):
        generals = formation.records(bytes.fromhex(self.save["world_state"]["1002"]), 1, 2)
        iid = iid or protocol.pb_get_varint(bytes.fromhex(self.save["protagonist_snapshot"]), 1)
        return generals[iid]

    def refresh(self):
        self.save = self.sessions[1].save

    def test_query_legacy_tokens_reward_currency_and_monotonic_iids_survive_reconnect(self):
        self.grant(70000, 100)
        raw = self.success(1, 2501)
        self.refresh()
        self.assertEqual(protocol.pb_get_varint(raw, 1), 100)
        self.assertFalse(any(item[1] == 70000 for item in self.items().values()))
        old = self.grant(70004)
        self.success(1, 2506, values=[old])
        self.refresh()
        fresh = self.grant(70004)
        self.assertGreater(fresh, old)
        legacy = soul.record([fresh + 1, 70000, 1])
        player.record_slot_update(self.save, protocol.encode_pb_field(3, 2, legacy))
        self.success(1, 2501)
        self.refresh()
        self.assertEqual(soul.get_state(self.save)["tokens"], 101)
        self.reconnect()
        self.refresh()
        self.assertEqual(protocol.pb_get_varint(self.success(1, 2501), 1), 101)

    def test_quick_soul_transaction_also_migrates_legacy_tokens_and_pushes_a_complete_cache_replacement(self):
        player.record_slot_update(self.save,protocol.encode_pb_field(3,2,soul.record([3000900,70000,1])))
        packets=self.request(1,1007,values=[1,2,0,0,0,0,0,0,0,0])
        self.assertEqual(packets[0][0],1007)
        self.assertIn(1002,[mid for mid,_ in packets])
        world=next(raw for mid,raw in packets if mid==1002)
        self.assertNotIn(3000900,formation.records(world,3,1))
        self.refresh()
        self.assertEqual(soul.get_state(self.save)["tokens"],1)

    def test_silver_hunts_charge_actual_stage_prices_and_real_counts_without_free_cd(self):
        before = copy.deepcopy(self.save)
        with patch.object(player.random, "getrandbits", return_value=7):
            reply = self.groups(self.success(1, 2502, values=[10, 0, 0, 0]))
        self.refresh()
        coin = protocol.pb_get_varint(reply[1], 4)
        self.assertGreater(coin, 0)
        self.assertEqual(self.save["role_state"]["coin"], before["role_state"]["coin"] - coin)
        self.assertEqual(len(self.items()) + soul.get_state(self.save)["tokens"], 10)
        self.assertEqual(self.save["achievement_state"]["counts"]["soulhuntcount"], 10)
        self.assertEqual(self.save["world_state"]["1300"], before["world_state"]["1300"])
        for key in ("exp", "stamina", "energy"):
            self.assertEqual(self.save["role_state"][key], before["role_state"][key])
        before_coin = self.save["role_state"]["coin"]
        self.success(1, 2502, values=[1, 0, 0, 0])
        self.refresh()
        self.assertLess(self.save["role_state"]["coin"], before_coin)

    def test_lingshi_purchase_and_premium_batch_charge_catalogue_prices_and_add_one_token_per_roll(self):
        before_gold = self.save["role_state"]["gold"]
        self.success(1, 5345, values=[20617, 10])
        self.refresh()
        self.assertEqual(self.props(20617), 10)
        self.assertEqual(self.save["role_state"]["gold"], before_gold - 1000)
        before = self.save["role_state"]["coin"]
        self.success(1, 2502, values=[60, 1, 1, 1])
        self.refresh()
        self.assertEqual(self.props(20617), 0)
        self.assertEqual(self.save["role_state"]["coin"], before - 200000)
        self.assertEqual(soul.get_state(self.save)["tokens"], 10)
        self.assertEqual(self.save["achievement_state"]["counts"]["soulhuntcount"], 10)
        self.assert_rejected(5345, values=[20612, 1])

    def test_batch_limits_bad_payloads_inventory_overflow_and_clock_rollback_never_charge(self):
        for opcode in soul.OPCODES:
            for raw in (b"\x08", b"\x10\x01", b"\x0a\x00"):
                self.assert_rejected(opcode, raw=raw)
        for values in ([0, 0, 0, 0], [6000, 1, 1, 1], [1, 1, 0, 0], [10, 2, 0, 0], [10, 0, 0], [100, 1, 1, 1]):
            self.assert_rejected(2502, values=values)
        self.save["role_state"]["level"] = 40
        self.assert_rejected(2502, values=[1, 0, 0, 0])
        self.save["role_state"]["level"] = 55
        self.grant(70001, 100)
        self.assert_rejected(2502, values=[1, 0, 0, 0])
        self.success(1, 2501)
        self.refresh()
        self.clock.return_value -= 1
        self.assert_rejected(2505)

    def test_batch_insufficient_actual_total_and_failed_save_rollback_whole_hunt(self):
        self.save["role_state"]["coin"] = 5000
        self.assert_rejected(2502, values=[10, 0, 0, 0])
        self.save["role_state"]["coin"] = 10000000
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 2502, values=[10, 1, 1, 1])
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))

    def test_force_stage_exchange_and_all_four_compounds_use_real_currency_and_exact_materials(self):
        self.success(1, 2505)
        self.refresh()
        self.assertEqual((soul.get_state(self.save)["hunt"], self.save["role_state"]["gold"]), (4, 999900))
        self.assert_rejected(2505)
        self.grant(70000, 10000)
        for row in self.config["soul_exchange"].values():
            before = soul.get_state(self.save)["tokens"]
            raw = self.success(1, 2503, values=[row["id"]])
            self.refresh()
            self.assertEqual(protocol.pb_get_varint(self.records(raw)[0], 2), row["id"])
            self.assertEqual(soul.get_state(self.save)["tokens"], before - row["num"])
        for row in self.config["soul_integrate"].values():
            a, b = self.grant(row["main_id"]), self.grant(row["assist_id"])
            for iid in (a, b):
                player.record_slot_update(self.save, protocol.encode_pb_field(3, 2, soul.record([iid, self.items()[iid][1], 10])))
            self.success(1, 2507, values=[a, b])
            self.refresh()
            self.assertNotIn(a, self.items())
            self.assertNotIn(b, self.items())
            self.assertEqual(self.items()[max(self.items())][1:], [row["id"], 10])

    def test_all_62_real_items_and_levels_have_exact_configured_bonuses_and_fractional_rates(self):
        for cid, row in self.config["soul"].items():
            if cid == "70000": continue
            for level in range(1, row["limit1"] + 1):
                values, flat, effects = soul.bonuses(protocol.encode_pb_field(10, 0, 3000001), {3000001: [3000001, int(cid), level]}, self.config)
                expected = {f: Fraction(0) for f in range(6, 17)}
                for i in (1, 2):
                    name = row[f"attr{i}"]
                    value = Fraction(str(row[f"attr{i}_grow{level}"]))
                    if name in soul.FIELDS:
                        expected[soul.FIELDS[name]] += value * (100 if row[f"method{i}"] == "percent" else 1)
                    elif name in ("adddmg", "subdmg"):
                        self.assertEqual(flat[int(name == "subdmg")], value)
                    elif name in effects:
                        self.assertEqual(effects[name], value)
                self.assertEqual(values, expected)

    def test_wear_swap_unmount_upgrade_and_quick_souls_preserve_existing_stats_and_power(self):
        iid = self.grant(70004)
        old = self.gen()
        self.wear(iid)
        self.refresh()
        self.assertEqual(protocol.pb_get_varint(self.gen(), 6), protocol.pb_get_varint(old, 6) + 1200)
        self.grant(20099, 100000)
        self.success(1, 2504, values=[iid])
        self.refresh()
        self.assertEqual(self.props(20099), 100000 - 220)
        self.assertEqual(protocol.pb_get_varint(self.gen(), 6), protocol.pb_get_varint(old, 6) + 2400)
        self.wear(0)
        self.refresh()
        self.assertEqual(self.gen(), old)
        other = self.grant(70008)
        self.success(1, 1007, values=[1, 2, iid, other, 0, 0, 0, 0, 0, 0])
        self.refresh()
        self.assertEqual([protocol.pb_get_varint(soul.read_world(self.save, self.config)[1][1], n) for n in (10, 11)], [iid, other])

    def test_duplicate_attributes_locked_positions_other_owners_and_worn_materials_reject_atomically(self):
        a, b = self.grant(70004), self.grant(70001)
        self.wear(a)
        self.refresh()
        raw = b"".join(protocol.encode_pb_field(n, 0, v) for n, v in ((1, 1), (2, 2), (3, b)))
        self.assert_rejected(1006, raw=raw)
        self.assert_rejected(2506, values=[a])
        self.assert_rejected(2507, values=[a, b])
        self.sessions[2].save["role_state"]["level"] = 55
        self.assert_rejected(2504, account=2, values=[a])
        self.save["role_state"]["level"] = 41
        self.assert_rejected(1006, raw=raw)

    def test_quick_upgrade_matches_real_single_steps_and_only_spends_confirmed_dust(self):
        a, b, idle = self.grant(70004), self.grant(70008), self.grant(70012)
        self.wear(a); self.refresh()
        self.wear(b, pos=2); self.refresh()
        self.grant(20099, 100000)
        self.sessions[2].save = copy.deepcopy(self.save)
        budget, spent = 3000, 0
        while True:
            items = self.items(2)
            choices = [i for i in (a, b) if self.config["soul"][str(items[i][1])]["upexp"] * 2 ** (items[i][2] - 1) <= budget - spent]
            if not choices:
                break
            iid = min(choices, key=lambda i: (items[i][2], i))
            spent += self.config["soul"][str(items[iid][1])]["upexp"] * 2 ** (items[iid][2] - 1)
            self.success(2, 2504, values=[iid])
        values = self.quick_upgrade(spent)
        packets = self.request(1, 2504, values=values)
        self.assertEqual(packets[0][0], 2504)
        self.assertLess([m for m, _ in packets].index(2504), [m for m, _ in packets].index(1200))
        self.refresh()
        self.assertEqual(self.items(), self.items(2))
        self.assertEqual(self.items()[idle][2], 1)
        self.assertEqual(self.props(20099), 100000 - spent)
        self.assertEqual(self.gen(), formation.records(bytes.fromhex(self.sessions[2].save["world_state"]["1002"]), 1, 2)[protocol.pb_get_varint(self.gen(), 2)])
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        cached = self.sessions[1].handle(2504, self.seq, guild.ids(values))
        self.assertEqual([(struct.unpack(">IIII", p[:16])[2], p[16:]) for p in cached], packets)
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))
        self.reconnect(); self.refresh()
        self.assertEqual((self.items(), self.props(20099)), (self.items(2), 100000 - spent))
        self.assert_rejected(2504, values=values)

    def test_quick_upgrade_obeys_every_team_gate_and_item_cap(self):
        iid = self.grant(70020)
        self.wear(iid); self.refresh()
        self.grant(20099, 100000000)
        current = 1
        for role_level, maximum in ((55, 10), (70, 11), (80, 12), (90, 13), (100, 14), (110, 15)):
            self.save["role_state"]["level"] = role_level
            cost = sum(self.config["soul"]["70020"]["upexp"] * 2 ** (level - 1) for level in range(current, maximum))
            self.success(1, 2504, values=self.quick_upgrade(cost))
            self.refresh()
            self.assertEqual(self.items()[iid][2], maximum)
            self.assert_rejected(2504, values=self.quick_upgrade(1))
            current = maximum

    def test_quick_upgrade_skips_unaffordable_and_capped_souls_without_touching_another_slot(self):
        expensive, cheap, capped, other = [self.grant(cid) for cid in (70053, 70005, 70020, 70012)]
        player.record_slot_update(self.save, protocol.encode_pb_field(3, 2, soul.record([capped, 70020, 15])))
        for pos, iid in enumerate((expensive, cheap, capped), 1):
            self.wear(iid, pos=pos); self.refresh()
        iid = 2000901
        player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, recruit.new_general(10201, iid, self.config)))
        self.success(1, 1003, raw=protocol.encode_pb_field(1, 0, 2) + protocol.encode_pb_field(3, 0, iid)); self.refresh()
        self.wear(other, sid=2); self.refresh()
        before = self.gen(iid)
        self.grant(20099, 120)
        self.success(1, 2504, values=self.quick_upgrade(120)); self.refresh()
        self.assertEqual([self.items()[i][2] for i in (expensive, cheap, capped, other)], [1, 3, 15, 1])
        self.assertEqual((self.gen(iid), self.props(20099)), (before, 0))
        self.assert_rejected(2504, values=self.quick_upgrade(40))

    def test_quick_upgrade_stale_quotes_targets_insufficient_dust_and_save_failure_are_atomic(self):
        iid = self.grant(70004)
        self.wear(iid); self.refresh()
        self.grant(20099, 1000)
        valid = self.quick_upgrade(220)
        for index, value in ((0, 1), (1, 8), (2, valid[2] + 1), (3, 0), (3, 219), (3, 221),
                             (3, 1540), (4, iid + 1), (5, 2), (6, iid), (7, 1)):
            values = valid[:]
            values[index] = value
            self.assert_rejected(2504, values=values)
        for values in (valid[:-1], valid + [0], [iid, iid], [0, 1, 220]):
            self.assert_rejected(2504, values=values)
        self.assert_rejected(999900, raw=guild.message(2504, guild.ids(valid)))
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 2504, values=valid)
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))
        self.save["role_state"]["g_power"] = (1 << 31) - 1
        self.assert_rejected(2504, values=valid)

    def test_growth_dedicated_team_and_battle_inputs_keep_souls_without_double_applying(self):
        a = self.grant(70020)
        self.wear(a)
        self.refresh()
        attack, _ = battle.rosters(self.save, self.config["copy"]["42101"]["1"], self.config)
        self.assertGreaterEqual(attack[2]["flat_in"], 600)
        before = self.gen()
        self.wear(a)
        self.refresh()
        self.assertEqual(self.gen(), before)
        self.success(1, 3702, values=[140, 1])
        self.refresh()
        from zyj_server import single_boss
        projected, _ = single_boss.project_team(self.save, self.save["single_boss_state"]["teams"]["1"], self.config)
        self.assertEqual(formation.records(bytes.fromhex(projected["world_state"]["1002"]), 3, 1), formation.records(bytes.fromhex(self.save["world_state"]["1002"]), 3, 1))

    def test_level_gates_decompose_base_only_and_actual_17_achievement_sources(self):
        a = self.grant(70020)
        player.record_slot_update(self.save, protocol.encode_pb_field(3, 2, soul.record([a, 70020, 10])))
        self.grant(20099, 1000000)
        self.assert_rejected(2504, values=[a])
        self.save["role_state"]["level"] = 70
        self.success(1, 2504, values=[a])
        self.refresh()
        self.assertEqual(self.items()[a][2], 11)
        before = self.props(20099)
        self.success(1, 2506, values=[a])
        self.refresh()
        self.assertEqual(self.props(20099), before + 2000)
        self.assertIn(55601, self.save["achievement_state"]["completed"])
        self.success(1, 2502, values=[100, 1, 1, 1])
        self.refresh()
        self.assertIn(51801, self.save["achievement_state"]["completed"])
        supported = [r for r in self.config["task"].values() if r["type"] in ("soul", "soulhuntcount")]
        self.assertEqual(len(supported), 17)
        for row in supported:
            for value in (int(row["target"]) - 1, int(row["target"])):
                view = {"scalars": {row["type"]: value}}
                self.assertEqual(achievements.progress(row, view), (value, value >= int(row["target"])))

    def test_thousand_is_1000_real_draws_with_dynamic_prices_and_latest_retry_is_not_a_second_purchase(self):
        self.save["role_state"].update(level=70, coin=15000000)
        seed, rng, stage, tokens, dust, coin, kept = 17, random.Random(17), 1, 0, 0, 0, []
        for _ in range(1000):
            row = self.config["soul_hunt"][str(stage)]
            coin += row["coin"]
            rows = sorted(self.config["soul"].values(), key=lambda r:r["id"])
            draw = rng.randrange(sum(r[f"rang{stage}"] for r in rows))
            for item in rows:
                draw -= item[f"rang{stage}"]
                if draw < 0: break
            if item["id"] == 70000: tokens += 1
            elif 2 <= item["quality"] <= 4: dust += item["eatexp"]
            else: kept.append(item["id"])
            stage = stage+1 if stage < 5 and rng.random() < row["range"] else 1
        with patch.object(player.random,"getrandbits",return_value=seed):
            packets = self.request(1,2502,values=[1000,1,1,1])
        self.assertEqual(packets[0][0],2502)
        self.refresh()
        self.assertEqual((self.save["role_state"]["coin"],self.props(20099)),(15000000-coin,dust))
        self.assertEqual((soul.get_state(self.save)["tokens"],soul.get_state(self.save)["hunt"]),(tokens,stage))
        self.assertEqual([i[1] for i in self.items().values()],kept)
        self.assertEqual(self.save["achievement_state"]["counts"]["soulhuntcount"],1000)
        before,disk = copy.deepcopy(self.save),self.store.path(1).read_bytes()
        cached = self.sessions[1].handle(2502,self.seq,guild.ids([1000,1,1,1]))
        self.assertEqual([(struct.unpack(">IIII",p[:16])[2],p[16:]) for p in cached],packets)
        self.assertEqual((self.sessions[1].save,self.store.path(1).read_bytes()),(before,disk))
        self.reconnect();self.refresh()
        self.assertEqual(soul.get_state(self.save)["hunt"],stage)

    def test_corrupt_inventory_state_overflow_duplicate_fields_and_unmatched_comb_fail_without_changes(self):
        original = copy.deepcopy(self.save)
        for state in (None,[],{}, {"hunt":True,"tokens":0,"serial":3000000,"checked_at":0},
                      {"hunt":1,"tokens":-1,"serial":3000000,"checked_at":0}):
            self.save["soul_state"] = state
            self.assert_rejected(2501)
        self.sessions[1].save = copy.deepcopy(original);self.refresh()
        self.grant(70004)
        world = self.save["world_state"]["1002"]
        self.save["world_state"]["1002"] += protocol.encode_pb_field(3,2,soul.record([3000001,70004,1])).hex()
        self.assert_rejected(2501)
        self.save["world_state"]["1002"] = world
        self.grant(70000,100)
        self.save["soul_state"]["serial"] = (1<<31)-1
        self.assert_rejected(2503,values=[70004])
        self.grant(70000,1)
        self.save["soul_state"]["tokens"] = (1<<31)-1
        player.record_slot_update(self.save,protocol.encode_pb_field(3,2,soul.record([3000900,70000,1])))
        self.assert_rejected(2501)
        self.sessions[1].save = copy.deepcopy(original);self.refresh()
        self.assert_rejected(1006,raw=b"\x08\x01\x10\x01\x18\x00\x18\x00")
        self.assert_rejected(1006,raw=b"\x08\x01\x10\x01")
        self.assert_rejected(999900,raw=guild.message(2502,guild.ids([1,0,0,0])))

    def test_exp_growth_replacement_drag_and_dedicated_team_preserve_soul_training_differences(self):
        iid = 2000901
        player.record_slot_update(self.save,protocol.encode_pb_field(1,2,recruit.new_general(10201,iid,self.config)))
        self.success(1,1003,raw=protocol.encode_pb_field(1,0,2)+protocol.encode_pb_field(3,0,iid));self.refresh()
        a = self.grant(70004)
        self.wear(a,sid=2);self.refresh()
        before = self.gen(iid)
        self.grant(20196,1)
        self.success(1,1038,raw=protocol.encode_pb_field(1,0,iid)+b"".join(protocol.encode_pb_field(2,0,n) for n in (1,0,0,0)))
        self.refresh()
        grown = self.gen(iid)
        self.assertGreater(protocol.pb_get_varint(grown,3),protocol.pb_get_varint(before,3))
        self.wear(0,sid=2);self.refresh()
        self.assertEqual(protocol.pb_get_varint(self.gen(iid),6),protocol.pb_get_varint(grown,6)-1200)
        self.wear(a,sid=2);self.refresh()
        raw = protocol.encode_pb_field(1,0,3)+protocol.encode_pb_field(2,0,2)
        self.success(1,1003,raw=raw);self.refresh()
        self.assertEqual(self.gen(iid),grown)
        from zyj_server import single_boss
        team = [0]*8
        team[0] = protocol.pb_get_varint(bytes.fromhex(self.save["protagonist_snapshot"]),1)
        team[1] = iid
        temporary,_ = single_boss.project_team(self.save,team,self.config)
        projected,_ = battle.rosters(temporary,self.config["copy"]["42101"]["1"],self.config)
        self.assertEqual(projected[8]["atk"],protocol.pb_get_varint(grown,6))
        self.assertEqual(soul.read_world(temporary,self.config)[1][2] and protocol.pb_get_varint(soul.read_world(temporary,self.config)[1][2],10),a)
        self.assertEqual(self.gen(iid),grown)

    def network_lua(self, *, native_protobuf=False):
        lua = test_friends.FriendsTests.network_lua(self, native_protobuf=native_protobuf)
        scripts = self.client_scripts()
        with zipfile.ZipFile(builder.SRC_APK) as archive:
            modules = {name[len("assets/"):].rsplit("/",1)[-1][:-3]:name for name in archive.namelist()
                       if name.startswith(("assets/scripts/","assets/pb/","assets/common_lua/")) and name.endswith(".so")}
        modules.update({path.rsplit("/", 1)[-1][:-3]: path for path in scripts
                        if path.startswith(("assets/scripts/", "assets/pb/", "assets/common_lua/")) and path.endswith(".so")})
        def script(name):
            name = name.decode()
            path = modules.get(name)
            if not path: return None
            return scripts.get(path) or builder.read_script(name,path.split("/")[1])
        lua.globals().soul_module = script
        lua.execute(b'''package.loaded.socket={}
            table.insert(package.loaders,2,function(name) local raw=soul_module(name);if raw then return assert(loadstring(raw,name)) end end)
            gamedata.cache.souls={};gamedata.cache.soulhunt={};gamedata.cache.slots={};gamedata.cache.cheers={};gamedata.cache.props={}
            gamedata.cache.generals={};gamedata.cache.equips={};gamedata.cache.gems={};gamedata.cache.protagonist={}
            for _,n in ipairs({"Newartifact","Jewel","slotGems"}) do gamedata[n]=function() end end''')
        code = scripts["assets/scripts/gamedata.so"].decode()
        for name in ("Souls","SoulHuntQuery","SoulHunt","SlotInfoProcess","Slots","Protagonist","Generals","Equips","equipData","checkIsMainChacter", "Props","propData",
                     "updateprops","updateStaff","updateRoleCoin","updateRoleGold","getIDandNUMs","getStaffNum","IDconfig","coinConfig","goldConfig","checkStaffEnough",
                     "illusions","ExclusiveArtifactQiLingDatas"):
            start = code.index("function gamedata."+name+"(")
            end = code.find("\nfunction ",start+1)
            lua.execute(code[start:end if end!=-1 else len(code)].encode())
        for name in ("GameSlots","GameSlotChangeSoul","GameQuickEquip","GameShop","GamePropList","GameSoul"):
            lua.eval(b"require")(name.encode())
        world = bytes.fromhex(self.save["world_state"]["1002"])
        lua.globals().seed_world = world
        lua.execute(b'local t=require("slots_pb").SlotS();t:ParseFromString(seed_world);gamedata:SlotInfoProcess(t)')
        return lua

    def test_actual_network_pb_hunt_exchange_growth_unmount_decompose_and_errors_keep_bound_contexts(self):
        self.grant(20617,10);self.grant(70000,100);self.grant(20099,10000)
        lua = self.network_lua()
        fd = lambda raw:lua.table_from({b"rbuf":raw})
        props = self.save["world_state"]["1200"]
        lua.globals().props_raw = bytes.fromhex(props)
        lua.execute(b'local t=require("idnums_pb").IdNums();t:ParseFromString(props_raw);gamedata:Props(t.idnums)')
        self.client_call(lua,1,"UISoulHuntQueryCallBack","NetSoulHuntQueryCallBack",{})
        gold,coin = self.save["role_state"]["gold"],self.save["role_state"]["coin"]
        result = self.client_call(lua,1,"UISoulHuntCallBack","NetSoulHuntCallBack",{"param":60,"param1":1,"param2":1,"param3":1})
        self.refresh()
        self.assertEqual(result[b"getnum"],10)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"coin"],coin-200000)
        self.assertEqual(self.save["role_state"]["coin"],coin-200000)
        result = self.client_call(lua,1,"UISoulExchangeCallBack","NetSoulExchangeCallBack",{"ids":[70004]})
        iid = result[b"getsouls"][1][b"iid"]
        dust = lua.globals().gamedata[b"cache"][b"props"][20099][b"num"]
        self.client_call(lua,1,"UISoulUpgradeCallBack","NetSoulUpgradeCallBack",{"iid":iid,"prop":1})
        self.assertEqual(lua.globals().gamedata[b"cache"][b"props"][20099][b"num"],dust-220)
        self.client_call(lua,1,"UISlotChangeSoulCallBack","NetSlotChangeSoulCallBack",{"slot":1,"soulpos":1,"soulid":iid})
        mode,mid,raw = lua.globals().UISlotChangeSoulCallBack(lua.table_from({b"slot":1,b"soulpos":1,b"soulid":0}))
        self.assertEqual(list(protocol.iter_pb_fields(raw)),[(1,0,1),(2,0,1),(3,0,0)])
        self.assertEqual(lua.globals().UISoulHuntCallBack(lua.table_from({b"param":1}))[0],0)
        lua.globals().NetSlotChangeSoulCallBack(fd(self.success(1,mid,raw=raw)))
        self.assertEqual(lua.globals().gamedata[b"cache"][b"slots"][1][b"s1"],0)
        self.client_call(lua,1,"UISoulResolveCallBack","NetSoulResolveCallBack",{"ids":[iid]})
        self.assertIsNone(lua.globals().gamedata[b"cache"][b"souls"][iid])
        query = lua.table_from({b"soulView":lua.table_from({b"soul":4})})
        lua.globals().UISoulHuntQueryCallBack(query)
        lua.globals().UISoulHuntQueryCallBack(lua.table_from({b"soulView":lua.table_from({b"soul":5})}))
        for generation in (4,5):
            result = lua.globals().NetSoulHuntQueryCallBack(fd(self.success(1,2501)))
            self.assertEqual(result[b"soulView"][b"soul"],generation)
        lua.globals().UISoulHuntCallBack(lua.table_from({b"param":1}))
        lua.globals().NetErrorMessageCallback9(fd(guild.ids([2504,0])))
        self.assertEqual(lua.globals().gamedata[b"ext"][b"localSoulBusy"],2502)
        lua.globals().NetErrorMessageCallback9(fd(guild.ids([2502,0])))
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localSoulBusy"])
        self.assertEqual(lua.globals().UISoulHuntCallBack(lua.table_from({b"param":1}))[0],1)
        self.assertEqual(self.save["role_state"]["gold"],gold)
        self.assertIsNone(lua.globals().gameConfig)

    def test_actual_pb_compound_purchase_quick_wear_and_full_query_remove_old_soul_cache(self):
        main,food=self.grant(70052),self.grant(70004)
        for iid in (main,food):
            player.record_slot_update(self.save,protocol.encode_pb_field(3,2,soul.record([iid,self.items()[iid][1],10])))
        lua=self.network_lua()
        result=self.client_call(lua,1,"UISoulCompoundCallBack","NetSoulCompoundCallBack",{"iid1":main,"iid2":food})
        self.refresh()
        self.assertIsNone(result[b"souls"][main]);self.assertIsNone(result[b"souls"][food])
        iid=max(self.items())
        changes={str(i).encode():iid if i==1 else 0 for i in range(1,9)}
        req=lua.table_from({b"sid":1,b"method":2,b"changeiids":lua.table_from(changes)})
        mode,opcode,raw=lua.globals().UIQuickEquipCallBack(req)
        self.assertEqual((mode,opcode,protocol.parse_ids_pb(raw)),(1,1007,[1,2,iid,0,0,0,0,0,0,0]))
        lua.globals().NetQuickEquipCallBack(lua.table_from({b"rbuf":self.success(1,1007,raw=raw)}))
        self.assertEqual(lua.globals().gamedata[b"cache"][b"slots"][1][b"s1"],iid)
        gold=self.sessions[1].save["role_state"]["gold"]
        req=lua.table_from({b"data":lua.table_from({b"id":20617,b"num":10,b"useId":1001,b"useNum":1000})})
        mode,opcode,raw=lua.globals().UIActivityBuyItemCallBack(req)
        self.assertEqual((mode,opcode),(1,5345))
        result=lua.globals().NetActivityBuyItemCallBack(lua.table_from({b"rbuf":self.success(1,5345,raw=raw)}))
        self.assertEqual(result[b"soulItem"],20617)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"props"][20617][b"num"],10)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"gold"],gold-1000)
        lua.execute(b'''gamedata.cache.souls[999999]={iid=999999,cid=70004,quality=5,level=1}
            CheckArtifactAllHint=function() end
            for _,name in ipairs({"makeEquipsTemp","makeAllGeneralsTemp","makeOffGenerals","makeSlotInfo","makeCheerInfo","makeAllGenerals",
                "makeOffEquip","makeOffTreasure","makeOnEquipsForSlot","makeSlotGeminfo","makeMofulist"}) do _G[name]=function() return {} end end
            makeEquipsByTypeAll=function() return {treasures={},horse={},treasure={}} end
            makeSoulsByQualityAll=function() return {all={},souls2={},souls3={},souls4={},souls5={}} end''')
        code=self.client_scripts()["assets/scripts/GameSlots.so"].decode()
        start=code.index("function NetSlotsAllInfoCallBack(fd)\n")
        end=code.index("\nfunction ",start+1)
        lua.execute(b'local slots_pb=require("slots_pb")\n'+code[start:end].encode())
        lua.globals().NetSlotsAllInfoCallBack(lua.table_from({b"rbuf":self.success(1,1002)}))
        self.assertIsNone(lua.globals().gamedata[b"cache"][b"souls"][999999])
        self.assertIsNotNone(lua.globals().gamedata[b"cache"][b"souls"][iid])
        lua.execute(b'''require("GameTimeBag");gamedata.cache.timebag={}
            for _,row in pairs(gamedata.config.trigger_gift2) do gamedata.cache.timebag[row.id]={cid=row.id,status=-1} end''')
        mode,opcode,raw=lua.globals().UITimeBagTrigCallBack(lua.table_from({b"opt":1,b"sysID":9}))
        self.assertEqual((mode,opcode,protocol.parse_ids_pb(raw)),(1,2882,[130007]))

    def test_actual_network_quick_upgrade_previews_without_charging_and_commits_one_native_reply(self):
        iid = self.grant(70004)
        self.wear(iid); self.refresh()
        self.grant(20099, 1000)
        lua = self.network_lua(native_protobuf=True)
        lua.globals().props_raw = bytes.fromhex(self.save["world_state"]["1200"])
        lua.execute(b'local t=require("idnums_pb").IdNums();t:ParseFromString(props_raw);gamedata:Props(t.idnums)')
        before = copy.deepcopy(self.save)
        req = lua.table_from({b"sid": 1, b"general": protocol.pb_get_varint(self.gen(), 2), b"preview": True})
        mode, opcode, preview = lua.globals().UISoulUpgradeCallBack(req)
        self.assertEqual((mode, opcode, preview[b"soulSteps"]), (0, 2504, 2))
        values = [preview[b"soulPreview"][i] for i in range(1, 21)]
        self.assertEqual(values, self.quick_upgrade(660))
        self.assertEqual(self.save, before)
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localSoulBusy"])
        confirm = lua.table_from({b"batch": preview[b"soulPreview"]})
        mode, opcode, raw = lua.globals().UISoulUpgradeCallBack(confirm)
        self.assertEqual((mode, opcode, protocol.parse_ids_pb(raw)), (1, 2504, values))
        self.assertEqual(lua.globals().UISoulUpgradeCallBack(confirm)[0], 0)
        lua.globals().NetErrorMessageCallback9(lua.table_from({b"rbuf": guild.ids([2502, 0])}))
        self.assertEqual(lua.globals().gamedata[b"ext"][b"localSoulBusy"], 2504)
        result = lua.globals().NetSoulUpgradeCallBack(lua.table_from({b"rbuf": self.success(1, 2504, raw=raw)}))
        self.assertEqual(result[b"soulSteps"], 2)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"props"][20099][b"num"], 340)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"souls"][iid][b"level"], 3)
        self.assertEqual(lua.globals().UISoulUpgradeCallBack(confirm)[0], 0)
        for lock in (b"localFormationBusy", b"localEquipGrowthBusy"):
            lua.globals().gamedata[b"ext"][lock] = True
            self.assertEqual(lua.globals().UISoulUpgradeCallBack(req)[0], 0)
            lua.globals().gamedata[b"ext"][lock] = None
        self.assertIsNone(lua.globals().gameConfig)

    def test_real_soul_battle_report_converts_actual_animations_and_preserves_terminal_hp(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("实际APK动画验证需要lupa.lua51")
        lua=LuaRuntime()
        config=dict(self.config)
        with zipfile.ZipFile(test_friends.test_guild.ROOT/"configs_sec5.zip") as archive:
            for name in ("generalanimation","skillanimation"):
                config[name]=json.loads(archive.read("5/"+name+".json"))
        lua.globals().gamedata=lua.table_from({"config":config},recursive=True)
        lua.execute('''print=function() end;printT=print;battleScene={slotNum=7}
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            CCFileUtils={sharedFileUtils=function(self) return self end,fullPathForFilename=function(self,p) return p end}
            ui={Split=function(s,sep) local t={} for v in string.gmatch(s,'[^'..sep..']+') do t[#t+1]=v end return t end}''')
        with zipfile.ZipFile(builder.SRC_APK) as archive:
            names,assets=archive.namelist(),{}
            lua.globals().CCFileUtils.isFileExist=lambda _,path:any(n.endswith("/"+path) for n in names)
            def asset(path):
                if path not in assets:
                    matches=[n for n in names if n.endswith("/"+path)]
                    self.assertEqual(len(matches),1,path)
                    assets[path]=json.loads(archive.read(matches[0]))
                return lua.table_from(assets[path],recursive=True)
            lua.globals().LoadJsonFileToTable=asset
            lua.execute(self.client_scripts()["assets/scripts/battleReportConvert.so"].decode())
            lua.execute(builder.read_script("BattleReportAbbToKey").decode())
            for cid in (70004,70020,70024,70053,70059,70060,70061,70062):
                for direct in (True,False):
                    iid=self.grant(cid)
                    self.wear(iid);self.refresh()
                    attack,defense=battle.rosters(self.save,self.config["copy"]["42101"]["1"],self.config)
                    report=battle.simulate(attack if direct else defense,defense if direct else attack,self.config,7)
                    native=lua.table_from(json.loads(lua.globals().ReplaceAbbToKey(json.dumps(report))),recursive=True)
                    allies,enemies=lua.globals().getBattleInitSlotInfo(native)
                    animations,ext=lua.globals().convertBattleReportToAnimationSub(native,allies,enemies)
                    self.assertGreater(len(animations),1)
                    for side,key in (("attack","atk"),("defense","def")):
                        for pos,unit in report["endmeta"][side].items():
                            self.assertEqual((ext.endinfo[key][pos].hp,ext.endinfo[key][pos].ap),(unit["h"],unit["ap"]))
                    self.wear(0);self.refresh()

    def ui_lua(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("实际APK界面验证需要lupa.lua51")
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.globals().gamedata = lua.table_from({"config":self.config,"music":{}},recursive=True)
        lua.execute('''print=function() end;printT=print;CCControlEventTouchUpInside=1
            requests={};UIRequest=function(t) requests[#requests+1]=t end
            runGamePrompt=function(t) prompt=t.msg end;showRewardPopupWindow=function(t) reward=t end
            function node() return setmetatable({visible=true,enabled=true}, {__index=function(t,k)
                if k=="addHandleOfControlEvent" or k=="setAnimationCompletedCallback" then return function(self,f) self.callback=f end end
                if k=="setString" then return function(self,v) self.text=v end end
                if k=="setEnabled" then return function(self,v) self.enabled=v end end
                if k=="setVisible" then return function(self,v) self.visible=v end end
                if k=="getContentSize" then return function() return {width=400,height=200} end end
                return function() end end}) end
            function items() return setmetatable({}, {__index=function(t,k) local n=node();rawset(t,k,n);return n end}) end
            CCBReaderLoad=function(path) resource=path;return node(),items() end
            getAnimationManager=function() return node() end
            CCSizeMake=function(w,h) return {width=w,height=h} end;ccc3=function(...) return {...} end
            CCScaleTo={create=node};CCSequence={createWithTwoActions=node}
            gameTouch={clickprofbytime=function() end};gamedata.music.PlayOptSound=function() end
            ui=setmetatable({createNode=node,IDconfig=function(cid) return gamedata.config.soul[tostring(cid)] or gamedata.config.props[tostring(cid)] end,
                getIDandNUM=function(s) local a,b=s:match("(%d+),(%d+)");return tonumber(a),tonumber(b) end,
                setLabelString=function(n,v) if v then n:setString(v) end end,
                addGray=function(_,n) n.gray=true end,removeGray=function(_,n) n.gray=false end},
                {__index=function() return function() end end})
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            table.copy=function(t) local r={} for k,v in pairs(t) do r[k]=v end return r end
            table.merge=function(a,b) local r=table.copy(a);for k,v in pairs(b) do r[k]=v end return r end
            gameConfig={checkBuildOpen=function() return true end,strings={attr_type=setmetatable({}, {__index=function(_,k) return k end}),
                string_common=function() return "label" end,equipName=function(_,name) return name end}}
            page={localSoulGeneration=1,rootNode=node(),selectpage="hunt",relaodHunt=function(self,t) self.received=(self.received or 0)+1 end,
                requestItemNum=function() end,playget=function() end,relaodList=function() end,shiftListPage=function() end}
            GameScene={layers={soul={show=true,module=page},soulResolveList={show=false,module={}}},roleinfo={level=70,vip=6,gold=100000},
                addUpdate=function() end,UpdatePresentLayer=function() end,checkopenlevelbyId=function() return true end}
            gameWindows={windows={},openWindow=function(self,name,data,callback) opened={name=name,data=data,callback=callback} end,
                closeWindowDirect=function(self,name) local w=self.windows[name];w.show=false;w.module:close() end}
            gameWindows.closeWindow=gameWindows.closeWindowDirect
            package.preload.UIShop=function() end
            UIActivityBuyItem=function() end''')
        lua.execute(self.client_scripts()["assets/scripts/UISouls.so"].decode())
        for name,key in (("window_soulInfo","soulInfo"),("window_soulintegrate","soulintegrate"),("window_buyItem","buyItem")):
            module = lua.execute(self.client_scripts()[f"assets/scripts/{name}.so"].decode())
            lua.globals().gameWindows.windows[key] = lua.table_from({"show":True,"module":module})
        return lua

    def test_actual_existing_unmount_upgrade_and_decompose_controls_bind_target_and_confirm_loss(self):
        lua = self.ui_lua()
        window = lua.globals().gameWindows.windows.soulInfo.module
        data = lua.table_from({"iid":3000001,"cid":70004,"level":10,"sid":1,"soulpos":1,"fromtype":"slot"})
        window.open(window,-103,data,None)
        self.assertTrue(window.infoItems.resolveButton.enabled)
        self.assertTrue(window.infoItems.resolveNode.visible)
        self.assertEqual(window.infoItems.resolveLab.text,"卸 下")
        view = lua.globals().LocalSoulContext()
        window.infoItems.resolveButton.callback()
        req = lua.globals().requests[1]
        self.assertEqual((req.type,req.slot,req.soulpos,req.soulid),(1006,1,1,0))
        data.iid = 3000002;data.fromtype="soullist";data.pagetype="up"
        lua.globals().gameWindows.windows.soulInfo.show=True
        window.open(window,-103,data,None)
        old_callback = window.upItems.doButton.callback
        window.uppropnum=10000000
        lua.globals().UISoulUpgrade(lua.table_from({"soulView":view,"newsoul":{"iid":3000001,"cid":70004,"level":11}},recursive=True))
        self.assertEqual((window.data.iid,window.data.level),(3000002,10))
        lua.globals().gameWindows.closeWindowDirect(lua.globals().gameWindows,"soulInfo")
        old_callback()
        self.assertEqual(len(lua.globals().requests),2)  # 升级页只读12001，不发送旧目标升级。
        lua.globals().gameWindows.windows.soulInfo.show=True
        data.pagetype="info"
        window.open(window,-103,data,None)
        window.infoItems.resolveButton.callback()
        confirmation = lua.globals().opened
        self.assertEqual(confirmation.name,"confirm")
        self.assertIn("强化消耗不返还",confirmation.data.msg)
        self.assertIn(str(self.config["soul"]["70004"]["eatexp"]),confirmation.data.msg)
        before = len(lua.globals().requests)
        window.close(window)
        confirmation.callback()
        self.assertEqual(len(lua.globals().requests),before)
        window.open(window,-103,data,None)
        window.infoItems.resolveButton.callback()
        lua.globals().opened.callback()
        self.assertEqual(lua.globals().requests[len(lua.globals().requests)].type,2506)

    def test_actual_idle_compound_buttons_exact_level_and_late_animation_callbacks_are_isolated(self):
        lua = self.ui_lua()
        window = lua.globals().gameWindows.windows.soulintegrate.module
        data = {"iid":3000001,"cid":70052,"level":10}
        all_data = [dict(data),{"iid":3000002,"cid":70004,"level":10},
                    {"iid":3000003,"cid":70004,"level":11}, {"iid":3000004,"cid":70004,"level":10,"generalcid":10201}]
        options = lua.table_from({"data":data,"allData":all_data},recursive=True)
        window.open(window,-103,options,None)
        old_callback = window.rootItems.doButton.callback
        old_callback()
        req = lua.globals().requests[1]
        self.assertEqual((req.type,req.iid1,req.iid2),(2507,3000001,3000002))
        window.reload(window,options,None)
        old_callback()
        self.assertEqual(len(lua.globals().requests),1)
        window.compound(window)
        completion = window.animationManager.callback
        window.close(window);window.open(window,-103,options,None)
        completion()
        self.assertFalse(window.rootItems.okNode.visible)
        layer = lua.execute(self.client_scripts()["assets/scripts/Layer_soul.so"].decode())
        layer.isscrolltouched=True
        cell = lua.globals()["items"]()
        layer.setlistCell(layer,cell,lua.table_from(data))
        cell.button2.callback()
        self.assertEqual(lua.globals().opened.name,"soulintegrate")
        for extra,message in (({"level":11},"恰好10级"),({"generalcid":10201},"请先卸下")):
            layer.setlistCell(layer,cell,lua.table_from({**data,**extra}))
            cell.button2.callback()
            self.assertIn(message,lua.globals().prompt)

    def test_actual_quick_upgrade_button_is_enabled_and_confirm_binds_slot_page_and_general(self):
        lua = self.ui_lua()
        lua.globals().slots_module = lua.execute(self.client_scripts()["assets/scripts/Layer_slotsInfo.so"].decode())
        lua.execute('''slotpage={rootNode=node(),rootItems=items(),localSoulGeneration=1,sid=1,status="soul",systemid=slots_module.systemid,
            slotdata={["1"]={sid=1,general={iid=123}}},addedDataNode={general={items=items()}},changeButtonStatus=function() end}
            GameScene.layers.slotsInfo={show=true,module=slotpage}
            slots_module.shiftButtonStatus(slotpage)
            slotpage.rootItems.quickEquipUp.callback()''')
        page = lua.globals().slotpage
        self.assertTrue(page.rootItems.quickEquipUp.enabled)
        self.assertFalse(page.rootItems.quickEquipUp.gray)
        self.assertFalse(page.rootItems.quickEquipUptext.gray)
        lua.execute('''GameScene.checkopenlevelbyId=function() return false end
            slots_module.shiftStatus(slotpage,"stone")
            assert(slotpage.status=="soul" and slotpage.localSoulGeneration==1)''')
        req = lua.globals().requests[1]
        self.assertEqual((req.type, req.sid, req.general, req.preview), (2504, 1, 123, True))
        preview = lua.table_from({"type": 2504, "soulView": req.soulView, "soulPreview": [0, 1, 123, 660], "soulSteps": 2}, recursive=True)
        lua.globals().UISoulUpgrade(preview)
        self.assertEqual(lua.globals().opened.name, "confirm")
        self.assertIn("660", lua.globals().opened.data.msg)
        confirm = lua.globals().opened.callback
        page.slotdata["1"].general.iid = 124
        confirm()
        self.assertEqual(len(lua.globals().requests), 1)
        page.slotdata["1"].general.iid = 123
        page.localSoulGeneration = 2
        confirm()
        self.assertEqual(len(lua.globals().requests), 1)
        lua.globals().slots_module.shiftButtonStatus(page)
        page.rootItems.quickEquipUp.callback()
        preview.soulView = lua.globals().requests[2].soulView
        lua.globals().UISoulUpgrade(preview)
        lua.globals().opened.callback()
        self.assertEqual(lua.globals().requests[3].type, 2504)
        self.assertEqual(lua.globals().requests[3].batch[4], 660)
        lua.globals().UISoulUpgrade(lua.table_from({"type": 2504, "soulView": preview.soulView, "soulSteps": 2}))
        self.assertIn("一键强化完成", lua.globals().prompt)
        old_button = page.rootItems.quickEquipUp.callback
        page.status = "equip"
        old_button()
        self.assertEqual(len(lua.globals().requests), 3)

    def test_actual_page_reentry_and_lingshi_purchase_ignore_old_generations_and_other_windows(self):
        lua = self.ui_lua()
        view = lua.globals().LocalSoulContext()
        lua.globals().page.localSoulGeneration=2
        lua.globals().UISoulHuntQuery(lua.table_from({"soulView":view,"soulhunt":{"hunt":4,"soul":9}},recursive=True))
        self.assertIsNone(lua.globals().page.received)
        lua.globals().UISoulHuntQuery(lua.table_from({"soulView":lua.globals().LocalSoulContext(),"soulhunt":{"hunt":1,"soul":0}},recursive=True))
        self.assertEqual(lua.globals().page.received,1)
        window = lua.globals().gameWindows.windows.buyItem.module
        window.open(window,-103,lua.table_from({"id":20617,"num":0}),None)
        window.rootItems.m_obutton.callback()
        req = lua.globals().requests[len(lua.globals().requests)]
        self.assertEqual((req.type,req.data.id,req.data.num,req.data.useId,req.data.useNum),(5345,20617,1,1001,100))
        old = lua.globals().LocalSoulContext()
        window.close(window);window.open(window,-103,lua.table_from({"id":20617,"num":0}),None)
        reward = {"1":{"cid":20617,"num":10}}
        lua.globals().UIActivityBuyItem(lua.table_from({"soulView":old,"soulItem":20617,"reward":reward},recursive=True))
        self.assertEqual(window.data.num,0)
        current = lua.globals().LocalSoulContext()
        before=len(lua.globals().requests)
        lua.globals().UIActivityBuyItem(lua.table_from({"soulView":current,"soulItem":20617,"reward":reward},recursive=True))
        self.assertEqual(window.data.num,10)
        self.assertEqual(len(lua.globals().requests),before)

    def test_actual_overlapping_hunt_animations_do_not_remove_newer_effects_or_update_closed_pages(self):
        lua=self.ui_lua()
        layer=lua.execute(self.client_scripts()["assets/scripts/Layer_soul.so"].decode())
        lua.globals().hunt_layer=layer
        lua.execute('''animations={};getAnimationManager=function() local n=node();animations[#animations+1]=n;return n end
            CCDelayTime={create=node};CCCallFunc={create=node}
            hunt_layer.localSoulGeneration=1;hunt_layer.rootNode=node();hunt_layer.rootItems=items()
            hunt_layer.General=node();hunt_layer.mainstatus=15;hunt_layer.huntData={hunt=1,soul=0}
            hunt_layer.exchangeTableView=node();hunt_layer.setStatus=function(self) self.statusCalls=(self.statusCalls or 0)+1 end
            hunt_layer.huntget=true;hunt_layer:relaodHunt({soulhunt={hunt=2,soul=1}})
            local old=animations[1].callback
            hunt_layer.huntget=true;hunt_layer:relaodHunt({soulhunt={hunt=3,soul=2}})
            old();assert(not hunt_layer.statusCalls)
            animations[3].callback();assert(hunt_layer.statusCalls==1)
            hunt_layer.localSoulGeneration=2;animations[3].callback();assert(hunt_layer.statusCalls==1)''')

    def test_packaged_lua_compiles_and_unmount_reuses_actual_native_assets(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("实际APK编译验证需要lupa.lua51")
        lua = LuaRuntime(unpack_returned_tuples=True)
        compile_lua = lua.eval("function(s,n) local fn,err=loadstring(s,n);return fn,err end")
        for path,code in self.client_scripts().items():
            fn,error = compile_lua(code,path)
            self.assertIsNotNone(fn,(path,error))
        with zipfile.ZipFile(builder.SRC_APK) as archive:
            paths=[n for n in archive.namelist() if n.endswith("/soul/soul_info.ccbi")]
            self.assertEqual(len(paths),1)
            for key in (b"resolveButton",b"resolveNode",b"resolveLab",b"changeButton",b"upButton"):
                self.assertIn(key,archive.read(paths[0]))

    def test_healing_bonus_uses_recipient_and_explosion_reduction_is_battle_only_on_both_sides(self):
        def unit(cid,**values):
            return {"cid":cid,"iid":cid,"level":1,"advance":0,"exp":0,"atk":100,"def":0,"hp":10000,"speed":100,
                    "skill":self.config["general"][str(cid)]["skillid"],**values}
        for direct in (True,False):
            attack={8:unit(10595,speed=50),2:unit(10201,hp=10000,soul_effects={"heal":Fraction(3,10)})}
            defense={2:unit(10201,iid=5,atk=1000,speed=200)}
            report=battle.simulate(attack if direct else defense,defense if direct else attack,self.config,1,max_rounds=1)
            heals=[d["m"]["m"] for a in report["b"]["a"] for d in a["e"]
                   if d.get("r")==direct and d.get("p")==2 and isinstance(d.get("m"),dict) and d["m"]["m"]<0]
            self.assertTrue(heals)
            self.assertEqual(heals[0],-535)  # floor((100*0.12+10000*0.04)*1.3)
        config=copy.deepcopy(self.config)
        config["general"]["10201"]["break1"]=9000040
        amounts=[]
        for reduction in (0,Fraction(2,5),1):
            dead={2:unit(10201,hp=1,atk=1000,speed=1,advance=1)}
            target={2:unit(10201,iid=4,atk=1000,speed=500,soul_effects={"antiblew":reduction})}
            before=copy.deepcopy((dead,target))
            report=battle.simulate(dead,target,config,4,max_rounds=1)
            explosions=[d["m"]["m"] for a in report["b"]["a"] if not a["s"] for d in a["e"]
                        if not d["r"] and isinstance(d.get("m"),dict)]
            self.assertTrue(explosions)
            amounts.append(explosions[0])
            self.assertEqual((dead,target),before)
        self.assertEqual(amounts[1],int(amounts[0]*Fraction(3,5)))
        self.assertEqual(amounts[2],0)
        target[2].update(hp=1,soul_effects={"antiblew":Fraction(2,5)})
        report=battle.simulate(dead,target,config,4,max_rounds=1)
        self.assertEqual(report["endmeta"]["defense"]["2"]["h"],0)

    def test_soul_gift_requires_real_s73_payment_and_atomic_once_only_claim_after_reconnect(self):
        self.assert_rejected(2882,values=[130007])
        self.success(1,201,raw=protocol.encode_pb_field(1,0,73)+protocol.encode_pb_field(2,0,1))
        self.refresh()
        raw=self.success(1,2882,values=[130007]);self.refresh()
        self.assertEqual(protocol.parse_ids_pb(raw),[130007,0,43200])
        first=self.save["soul_gift_state"]["triggered_at"]
        self.success(1,2882,values=[130007]);self.refresh()
        self.assertEqual(self.save["soul_gift_state"]["triggered_at"],first)
        self.assert_rejected(2881,values=[130007])
        raw=b"".join(protocol.encode_pb_field(1,2,recharge.ids([v])) for v in (4,130007))
        order=self.records(self.success(1,115,raw=raw))[0]
        self.refresh()
        gold=self.save["role_state"]["gold"]
        self.success(1,116,values=[protocol.pb_get_varint(order,1)])
        self.reconnect();self.refresh()
        self.assertEqual(self.save["role_state"]["gold"],gold)
        before,disk=copy.deepcopy(self.save),self.store.path(1).read_bytes()
        with patch.object(player,"save_role",return_value=False),self.assertRaises(OSError):
            self.request(1,2881,values=[130007])
        self.assertEqual((self.sessions[1].save,self.store.path(1).read_bytes()),(before,disk))
        self.reconnect();self.refresh()
        count,dust,tokens=len(self.items()),self.props(20099),soul.get_state(self.save)["tokens"]
        self.success(1,2881,values=[130007]);self.refresh()
        self.assertEqual((len(self.items())-count,self.props(20099)-dust,soul.get_state(self.save)["tokens"]-tokens),(2,30000,100))
        self.assert_rejected(2881,values=[130007])
        self.assertEqual(timebag.get_state(self.save,130007)["claimed"],True)


if __name__ == "__main__":
    unittest.main()
