"""普通/金光神器完整养成：只使用临时账号与原包配置。"""

import copy
from fractions import Fraction
import json
import re
import struct
import unittest
from unittest.mock import patch

import test_artifact
import build_local_apk as builder
from zyj_server import artifact, battle, player, protocol, recharge


setUpModule = test_artifact.setUpModule


class ArtifactGrowthTests(unittest.TestCase):
    setUp = test_artifact.ArtifactTests.setUp
    request = test_artifact.ArtifactTests.request
    success = test_artifact.ArtifactTests.success
    reconnect = test_artifact.ArtifactTests.reconnect
    add_account = test_artifact.ArtifactTests.add_account
    assert_rejected = test_artifact.ArtifactTests.assert_rejected
    refresh = test_artifact.ArtifactTests.refresh
    grant = test_artifact.ArtifactTests.grant
    props = test_artifact.ArtifactTests.props
    gen = test_artifact.ArtifactTests.gen
    records = test_artifact.ArtifactTests.records
    groups = test_artifact.ArtifactTests.groups
    items = test_artifact.ArtifactTests.items
    forge = test_artifact.ArtifactTests.forge
    identify = test_artifact.ArtifactTests.identify
    wear = test_artifact.ArtifactTests.wear
    unit = test_artifact.ArtifactTests.unit
    assert_battle_report = test_artifact.ArtifactTests.assert_battle_report
    client_scripts = classmethod(test_artifact.ArtifactTests.client_scripts.__func__)
    client_call = test_artifact.ArtifactTests.client_call
    network_lua = test_artifact.ArtifactTests.network_lua
    ui_lua = test_artifact.ArtifactTests.ui_lua

    def make(self, cid=110001, skills=()):
        with patch.object(artifact, "choose", return_value=self.config["trump"][str(cid)]):
            key = self.forge(self.config["trump"][str(cid)]["goldTrump"])
        self.identify(key)
        selected = (*skills, 0, 0, 0)[:3]
        self.set_item(key, {**{7+i: sid for i, sid in enumerate(selected)},
                            **{22+i: 1 if sid else -1 for i, sid in enumerate(selected)}})
        return key

    def set_item(self, key, changes):
        raw = artifact.replace(self.items()[key], changes)
        player.record_slot_update(self.save, protocol.encode_pb_field(16, 2, raw))

    def action_body(self, opcode, values):
        if opcode in (5502, 5517):
            keys = values if opcode == 5502 else values[:-1]
        elif opcode == 5519:
            keys = values
        elif opcode in (5545, 5546):
            keys = values[:2]
        else:
            keys = [] if opcode == 5507 else values[:1]
        versions = [v for key in sorted(set(keys)) for v in
                    (key, (artifact.values(self.items()[key]) + [0])[33])]
        return recharge.ids([0, len(keys), *versions, *values])

    def action(self, opcode, values):
        raw = self.success(1, opcode, raw=self.action_body(opcode, values))
        self.refresh()
        return raw

    def reject(self, opcode, values, raw=None):
        self.assert_rejected(opcode, raw=raw or self.action_body(opcode, values))

    def test_lock_and_three_for_one_recast_preserve_ownership_and_reject_stale_clicks(self):
        keys = [self.make(110101) for _ in range(3)]
        stale = self.action_body(5518, [keys[0], 1])
        self.action(5518, [keys[0], 1])
        self.reject(5502, keys)
        self.action(5518, [keys[0], 0])
        self.reject(5518, [keys[0], 1], stale)
        raw = self.action(5502, keys)
        self.assertEqual(set(self.items()), {artifact.iid(raw)})
        self.assertEqual(self.config["trump"][str(artifact.values(raw)[1])]["goldTrump"], 1)
        self.assertEqual(artifact.values(raw)[5], 0)
        self.reconnect(); self.refresh()
        self.assertEqual(set(self.items()), {artifact.iid(raw)})

    def test_strengthening_failure_pity_success_refund_and_no_duplicate_rebirth(self):
        key, first, second = [self.make() for _ in range(3)]
        self.wear(key)
        base = self.gen()
        with patch.object(artifact.random.Random, "randrange", return_value=999):
            self.action(5519, [key, first])
        data = artifact.values(self.items()[key])
        self.assertEqual(data[13:15], [0, 130])
        self.assertNotIn(first, self.items())
        with patch.object(artifact.random.Random, "randrange", return_value=0):
            self.action(5519, [key, second])
        self.assertEqual(artifact.values(self.items()[key])[13:15], [1, 0])
        self.assertGreater(protocol.pb_get_varint(self.gen(), 8), protocol.pb_get_varint(base, 8))
        self.wear(0)
        gold = self.save["role_state"]["gold"]
        self.action(5520, [key])
        self.assertEqual(artifact.values(self.items()[key])[13], 0)
        returned = [artifact.values(v)[1] for k, v in self.items().items() if k != key]
        self.assertEqual(returned, [110301, 110301])
        self.assertEqual(self.save["role_state"]["gold"], gold-5)
        self.reject(5520, [key])

    def test_four_holes_jewels_combine_upgrade_unequip_and_rebirth_are_real(self):
        self.save["role_state"]["level"] = 90
        self.grant(20680, 20); self.grant(120001, 4)
        key = self.make()
        for pos in (2, 3, 4):
            self.action(5504, [key, pos])
        self.assertEqual(self.props(20680), 12)
        self.action(5507, [120001, 1])
        self.action(5505, [key, 120001, 1])
        self.action(5506, [key, 1])
        self.assertEqual(artifact.values(self.items()[key])[9], 120002)
        self.wear(key)
        raw = self.gen()
        self.action(5505, [key, 0, 1])
        self.assertEqual(protocol.pb_get_varint(raw, 6)-protocol.pb_get_varint(self.gen(), 6), 1240)
        self.wear(0)
        self.action(5520, [key])
        self.assertEqual(self.props(20680), 20)
        self.assertEqual(artifact.values(self.items()[key])[9:13], [0, -1, -1, -1])

    def test_all_four_jewel_types_reach_eleven_with_exact_costs_and_full_level_refusals(self):
        self.save["role_state"]["level"] = 100
        def inventory(cid):
            if str(cid) in self.config["trump_gem"]:
                return next((protocol.parse_ids_pb(raw)[1] for raw in self.records(
                    bytes.fromhex(self.save["world_state"]["1002"]), 17) if protocol.pb_get_varint(raw, 1) == cid), 0)
            return self.props(cid)
        for first in (r for r in self.config["trump_gem"].values() if r["lv"] == 1):
            key = self.make()
            self.grant(first["id"], 1)
            self.action(5505, [key, first["id"], 1])
            current = first
            for level in range(2, 12):
                costs = [(c, n-int(c == current["id"])) for c, n in artifact.deck(current["gem_lv"])]
                for cid, count in costs:
                    self.grant(cid, count)
                before = {cid: inventory(cid) for cid, _ in costs}
                self.action(5506, [key, 1])
                self.assertEqual({cid: before[cid]-inventory(cid) for cid, _ in costs}, dict(costs))
                current = self.config["trump_gem"][str(current["per_cid"])]
                self.assertEqual((current["lv"], artifact.values(self.items()[key])[9]), (level, current["id"]))
            self.reject(5506, [key, 1])
            self.reject(5507, [current["id"], 1])

    def test_wash_is_token_bound_persistent_and_orange_point_upgrade_uses_real_material(self):
        self.grant(20804, 10); self.grant(20806, 10); self.grant(20808, 2)
        key = self.make(skills=[9000566])
        self.action(5540, [key, 1, 2])
        self.reject(5541, [key, 1])
        self.action(5540, [key, 1, 3])
        self.action(5541, [key, 1])
        pending = artifact.values(self.items()[key])[18:21]
        self.assertTrue(any(pending))
        stale = self.action_body(5542, [key])
        self.reconnect(); self.refresh()
        self.assertEqual(artifact.values(self.items()[key])[18:21], pending)
        self.action(5544, [key])
        self.action(5541, [key, 1])
        self.reject(5542, [key], stale)
        self.action(5544, [key])
        self.action(5543, [key, 1])
        self.assertEqual(artifact.values(self.items()[key])[6], 9000567)
        self.assertEqual(self.props(20808), 1)
        self.reject(5543, [key, 1])

    def test_new_operations_save_failure_and_retries_are_atomic(self):
        key = self.make()
        body = self.action_body(5518, [key, 1])
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 5518, raw=body)
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))
        session = self.sessions[1]
        packets = session.handle(5518, 9876, body)
        self.assertEqual(session.handle(5518, 9876, body), packets)
        self.refresh()
        self.assertEqual(artifact.values(self.items()[key])[27], 1)

    def test_washing_pool_static_rates_and_resonance_reach_real_stats_and_battle(self):
        key = self.make(skills=[9000567, 9000579])
        base = self.gen()
        self.wear(key)
        self.assertEqual(protocol.pb_get_varint(self.gen(), 10)-(protocol.pb_get_varint(base, 10) or 0), 35)
        self.assertEqual(protocol.pb_get_varint(self.gen(), 13)-(protocol.pb_get_varint(base, 13) or 0), 35)
        attack, _ = battle.rosters(self.save, self.config["copy"]["42102"]["1"], self.config)
        teams = {True: copy.deepcopy(attack), False: {2: self.unit()}}
        battle._prepare_teams(teams, self.config)
        self.assertEqual(teams[True][2]["base"]["critical"], protocol.pb_get_varint(self.gen(), 10))
        self.assertEqual(protocol.pb_get_varint(self.gen(), 9)-(protocol.pb_get_varint(base, 9) or 0), 2)

    def stock_food(self, cid, count):
        state = copy.deepcopy(artifact.get_state(self.save, self.config))
        raws = [artifact.new_item(self.config["trump"][str(cid)], self.save["role_name"], state, self.config, returned=True)
                for _ in range(count)]
        player.record_slot_update(self.save, b"".join(protocol.encode_pb_field(16, 2, r) for r in raws))
        self.save["artifact_state"] = state
        return [artifact.iid(r) for r in raws]

    def test_all_twenty_four_profiles_strengthen_through_thirty_without_cumulative_rows(self):
        for cid in (20627, 20628, 20629):
            self.grant(cid, 100)
        for row in self.config["trump"].values():
            if not row["appraiseMethod"]:
                continue
            with self.subTest(cid=row["id"]):
                key = self.make(row["id"])
                for level in range(1, 31):
                    data = artifact.values(self.items()[key])
                    step = artifact.strength_row(data, self.config, level)
                    foods = self.stock_food(row["return"], step["num"])
                    with patch.object(artifact.random.Random, "randrange", return_value=0):
                        self.action(5519, [key, *foods])
                    current = artifact.values(self.items()[key])
                    self.assertEqual(current[13:15], [level, 0])
                    self.assertEqual(Fraction(current[16]), Fraction(step["attr1Value"]*current[3], 100))
                food = self.stock_food(row["return"], 1)[0]
                self.reject(5519, [key, food])

    def test_batch_recast_uses_three_actual_inputs_and_preserves_unselected_items(self):
        keys = [self.make() for _ in range(7)]
        rows = self.groups(self.action(5517, [*keys[:6], 0]))
        self.assertEqual(len(rows), 2)
        self.assertEqual(set(self.items()), {keys[-1], *map(artifact.iid, rows.values())})
        self.assertTrue(all(artifact.values(r)[5] == 0 for r in rows.values()))
        self.reject(5517, [keys[-1], 0])

    def test_strength_and_skill_exchange_move_their_actual_receipts_and_recompute_bonuses(self):
        self.grant(20808, 10)
        first = self.make(skills=[9000566])
        second = self.make(skills=[9000591])
        food = self.stock_food(110301, 1)[0]
        with patch.object(artifact.random.Random, "randrange", return_value=0):
            self.action(5519, [first, food])
        self.action(5546, [first, second])
        self.assertEqual([artifact.values(self.items()[k])[13] for k in (first, second)], [0, 1])
        self.assertNotIn("strength", self.save["artifact_state"]["items"][str(first)])
        self.assertEqual(self.save["artifact_state"]["items"][str(second)]["strength"]["costs"], [[110301, 1]])
        before = self.save["role_state"]["gold"]
        self.action(5545, [first, second])
        self.assertEqual([artifact.values(self.items()[k])[6] for k in (first, second)], [9000591, 9000566])
        self.assertEqual(before-self.save["role_state"]["gold"], 5000+10000+500)
        self.action(5520, [second])
        self.assertEqual(sum(artifact.values(r)[1] == 110301 for r in self.items().values()), 1)

    def test_ordinary_pity_advanced_wash_resonance_and_golden_no_white_are_enforced(self):
        self.grant(20804, 100); self.grant(20805, 100); self.grant(192006, 10)
        key = self.make(skills=[9000438, 9000451])
        self.action(5540, [key, 1, 2])
        self.action(5541, [key, 3])
        pending = artifact.values(self.items()[key])[18:21]
        self.assertEqual(pending[0], 9000438)
        pairs, _ = artifact.resonance(pending, self.config)
        self.assertTrue(pairs)
        self.assertTrue(all(9000438 in (row["skills1"], row["skills2"]) for row in pairs))
        self.action(5542, [key])
        data = artifact.values(self.items()[key])
        self.assertEqual([v for v in data[29:32] if v], [row["id"] for row in pairs])
        self.assertEqual(data[32], 2)
        self.assertEqual(self.props(20805), 97)
        self.assertEqual(self.props(192006), 9)
        self.action(5540, [key, 1, 3])
        self.save["artifact_state"]["items"][str(key)]["rolls"] = [199, 1499]
        self.action(5541, [key, 1])
        selected = artifact.values(self.items()[key])[18:21]
        self.assertTrue(any(self.config["breakskill"][str(s)]["quality"] == 6 for s in selected if s))
        self.assertEqual(self.save["artifact_state"]["items"][str(key)]["rolls"], [0, 0])
        self.action(5544, [key])
        self.action(5541, [key, 2])
        self.assertTrue(any(self.config["breakskill"][str(s)]["quality"] == 6 for s in artifact.values(self.items()[key])[18:21] if s))
        self.action(5544, [key])
        gold = self.make(110101, skills=[9000433])
        for _ in range(12):
            self.action(5541, [gold, 1])
            self.assertTrue(all(self.config["breakskill"][str(s)]["quality"] > 1 for s in artifact.values(self.items()[gold])[18:21] if s))
            self.action(5544, [gold])

    def test_skill_holes_failure_pity_order_and_lock_have_no_free_opening(self):
        self.grant(20806, 100); self.grant(20807, 1)
        key = self.make(skills=[])
        self.reject(5540, [key, 2, 1])
        with patch.object(artifact.random.Random, "randrange", return_value=99):
            self.action(5540, [key, 1, 1])
        self.assertEqual(artifact.values(self.items()[key])[21:27], [-1, -1, -1, 23, 5, 100])
        with patch.object(artifact.random.Random, "randrange", return_value=0):
            for pos in (1, 2, 3):
                self.action(5540, [key, pos, 1])
        self.assertEqual(self.props(20806), 95)
        self.assertEqual(self.props(20807), 0)
        self.reject(5540, [key, 1, 1])
        self.reject(5540, [key, 1, 2])

    def test_cost_shortfalls_overflow_unknown_history_and_save_failure_leave_no_partial_assets(self):
        key = self.make()
        self.save["role_state"]["level"] = 90
        self.reject(5504, [key, 2])
        self.grant(20680, 5)
        self.action(5504, [key, 2])
        self.grant(20680, (1 << 31)-1-self.props(20680))
        self.reject(5520, [key])
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 5518, raw=self.action_body(5518, [key, 1]))
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))
        other = self.make()
        self.set_item(other, {14: 1})
        self.reject(5520, [other])

    def washing_unit(self, name, level=6, **changes):
        row = next(r for r in self.config["trump_washing_skill"]["1"].values() if r["name"] == name)
        return self.unit(artifact={"cid": 110001, "level": 0, "skills": [row[f"skill{level}"]]}, **changes)

    def test_all_twenty_six_skill_families_six_tiers_both_sides_are_deterministic_and_replayable(self):
        count = 0
        for row in self.config["trump_washing_skill"]["1"].values():
            for quality in range(1, 7):
                for direct in (True, False):
                    teams = {direct: {2: self.washing_unit(row["name"], quality, speed=300, initial_ap=4)},
                             not direct: {2: self.unit(iid=1), 8: self.unit(iid=8)}}
                    before = copy.deepcopy(teams)
                    report = battle.simulate(teams[True], teams[False], self.config, 7, max_rounds=3)
                    self.assertEqual(report, battle.simulate(teams[True], teams[False], self.config, 7, max_rounds=3))
                    self.assertEqual(teams, before)
                    self.assert_battle_report(report)
                count += 1
        self.assertEqual(count, 156)

    def test_round_start_qi_and_escape_actually_change_ap_and_control_without_partner_aliases(self):
        config = copy.deepcopy(self.config)
        for name, sid in (("聚气", 9000591), ("挣脱", 9000597)):
            config["breakskill"][str(sid)]["value"] = 1
            actor = self.washing_unit(name, dizzy=2, states={"skilllock": 4, "close": 4}, speed=300)
            teams = {True: {2: copy.deepcopy(actor)}, False: {2: self.unit(iid=1)}}
            battle._prepare_teams(teams, config)
            self.assertNotIn(sid, teams[True][2]["effects"])
            report = battle.simulate({2: actor}, {2: self.unit(iid=1)}, config, 1, max_rounds=1)
            changes = [d for a in report["b"]["a"] for d in a["e"] if d["r"]]
            if name == "聚气":
                self.assertTrue(any(d.get("ap") == 1 for d in changes))
            else:
                self.assertTrue(any(d.get("u") == {"u": "dizzy", "w": False} for d in changes))
                self.assertTrue(any(d.get("u") == {"u": "skilllock", "w": False} for d in changes))
                self.assertTrue(any(a.get("s", {}).get("p") == [2] and a["s"].get("r") for a in report["b"]["a"]))

    def test_pride_cleans_actual_attack_debuff_at_next_round_but_keeps_burning(self):
        config = copy.deepcopy(self.config)
        config["breakskill"]["9000450"]["value"] = 1
        config["breakskill"]["9000603"]["value"] = 1
        attack = self.washing_unit("侵蚀", speed=300, initial_ap=4)
        defense = self.washing_unit("傲骨", iid=1, firing=[10, 3])
        report = battle.simulate({2: attack}, {2: defense}, config, 7, max_rounds=2)
        actions = report["b"]["a"]
        separator = next(i for i, a in enumerate(actions) if not a["s"] and not a["e"])
        self.assertTrue(any(d.get("B") == {"R": "atk", "u": "weaken", "w": True}
                            for a in actions[:separator] for d in a["e"]))
        self.assertTrue(any(not a["s"] and any(d.get("B") == {"R": "atk", "u": "weaken", "w": False} for d in a["e"])
                            for a in actions[separator+1:]))
        self.assertFalse(any(d.get("u") == {"u": "firing", "w": False} for a in actions for d in a["e"]))
        self.assert_battle_report(report)

    def test_strength_pity_guarantees_success_and_rebirth_save_failure_keeps_all_inputs(self):
        key = self.make()
        foods = self.stock_food(110301, 5)
        with patch.object(artifact.random.Random, "randrange", return_value=999):
            for food in foods:
                self.action(5519, [key, food])
        self.assertEqual(artifact.values(self.items()[key])[13:15], [1, 0])
        self.assertEqual(self.save["artifact_state"]["items"][str(key)]["strength"]["costs"], [[110301, 5]])
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 5520, raw=self.action_body(5520, [key]))
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))
        self.action(5520, [key])
        self.reconnect(); self.refresh()
        self.assertEqual(sum(artifact.values(r)[1] == 110301 for r in self.items().values()), 5)
        self.reject(5520, [key])

    def test_shield_damage_gem_only_increases_actual_shield_loss_never_hp_damage(self):
        actor = self.unit(speed=300, artifact={"cid": 110001, "level": 0, "skills": [], "shield_damage": "1/2"})
        enemy = self.unit(iid=1, cover_d=1000, cover_p=100, cover_l=1)
        report = battle.simulate({2: actor}, {2: enemy}, self.config, 7, max_rounds=1)
        self.assertEqual(report["endmeta"]["defense"]["2"]["cover_d"], 850)
        self.assertEqual(report["endmeta"]["defense"]["2"]["h"], 10000)
        self.assert_battle_report(report)
        enemy["cover_d"] = 50
        report = battle.simulate({2: actor}, {2: enemy}, self.config, 7, max_rounds=1)
        self.assertEqual(report["endmeta"]["defense"]["2"]["h"], 9950)

    def test_actual_packaged_network_new_apis_use_versions_and_never_charge_on_push_or_error(self):
        self.grant(20804, 5); self.grant(20808, 2)
        key = self.make(skills=[9000566])
        lua = self.network_lua(native_protobuf=True)
        result = self.client_call(lua, 1, "UIUserArtifactLockCallBack", "NetUserArtifactLockCallBack", {"cid": key, "isLock": 1})
        self.assertEqual(result[b"artifactData"][b"isLockState"], 1)
        self.client_call(lua, 1, "UIUserArtifactLockCallBack", "NetUserArtifactLockCallBack", {"cid": key, "isLock": 0})
        self.client_call(lua, 1, "UIUserArtifactSkillUpCallBack", "NetUserArtifactSkillUpCallBack", {"iid": key, "pos": 1})
        self.assertEqual(lua.globals().gamedata[b"cache"][b"props"][20808][b"num"], 1)
        result = self.client_call(lua, 1, "UIUserArtifactBaptizeCallBack", "NetUserArtifactBaptizeCallBack", {"iid": key, "curType": 1, "xprops": []})
        self.assertGreater(result[b"artifactData"][b"skill1_cid_bk"], 0)
        self.client_call(lua, 1, "UIUserArtifactSkillWashCancelCallBack", "NetUserArtifactSkillWashCancelCallBack", {"iid": key})
        mode, mid, raw = lua.globals().UIUserArtifactBaptizeCallBack(lua.table_from({b"iid": key, b"curType": 1}))
        self.assertEqual((mode, mid), (1, 5541))
        self.assertEqual(protocol.parse_ids_pb(raw)[:4], [0, 1, key, 6])
        error = lua.table_from({b"rbuf": recharge.ids([5541, 0]), b"ser": 0})
        lua.globals().NetErrorMessageCallback9(error)
        self.assertIsNotNone(lua.globals().gamedata[b"ext"][b"localArtifactBusy"])
        self.assertIsNotNone(lua.globals().gamedata[b"ext"][b"localFormationBusy"])
        error[b"ser"] = 10
        lua.globals().NetErrorMessageCallback9(error)
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localArtifactBusy"])
        lua.globals().UIUserArtifactBaptizeCallBack(lua.table_from({b"iid": key, b"curType": 1}))
        lua.globals().NetErrorMessageCallback9(error)
        self.assertIsNotNone(lua.globals().gamedata[b"ext"][b"localArtifactBusy"])
        self.assertIsNotNone(lua.globals().gamedata[b"ext"][b"localFormationBusy"])
        error[b"ser"] = 11
        lua.globals().NetErrorMessageCallback9(error)
        self.assertIsNone(lua.globals().gameConfig)

    def test_late_duplicate_reply_does_not_consume_the_next_same_opcode_request(self):
        key = self.make()
        lua = self.network_lua(native_protobuf=True)
        req = lua.table_from({b"cid": key, b"isLock": 1})
        _, opcode, raw = lua.globals().UIUserArtifactLockCallBack(req)
        reply = self.success(1, opcode, raw=raw)
        fd = lua.table_from({b"rbuf": reply, b"ser": 20})
        lua.globals().NetUserArtifactLockCallBack(fd)
        req[b"isLock"] = 0
        _, opcode, raw = lua.globals().UIUserArtifactLockCallBack(req)
        ignored = lua.globals().NetUserArtifactLockCallBack(fd)
        self.assertTrue(ignored[b"localArtifactIgnored"])
        self.assertIsNotNone(lua.globals().gamedata[b"ext"][b"localArtifactBusy"])
        fd[b"rbuf"], fd[b"ser"] = self.success(1, opcode, raw=raw), 21
        result = lua.globals().NetUserArtifactLockCallBack(fd)
        self.assertEqual(result[b"artifactData"][b"isLockState"], 0)

    def test_actual_network_gem_upgrade_unmount_combine_and_refund_use_one_inventory(self):
        self.save["role_state"]["level"] = 90
        self.grant(20680, 20); self.grant(120001, 2)
        key = self.make()
        lua = self.network_lua(native_protobuf=True)
        code = self.client_scripts()["assets/scripts/gamedata.so"].decode()
        for name in ("jewelData", "Jewel", "updateJewelData"):
            start = code.index("function gamedata."+name+"(")
            end = code.index("\nfunction ", start+1)
            lua.execute(code[start:end].encode())
        lua.globals().world = bytes.fromhex(self.save["world_state"]["1002"])
        lua.execute(b'gamedata.cache.jewels={};local s=require("slots_pb").SlotS();s:ParseFromString(world);gamedata:SlotInfoProcess(s)')
        self.client_call(lua, 1, "UIArtifactOpenPosCallBack", "NetArtifactOpenPosCallBack", {"iid": key, "pos": 2})
        self.client_call(lua, 1, "UIArtifactMountJewelCallBack", "NetArtifactMountJewelCallBack", {"iid": key, "jewelCid": 120001, "pos": 1})
        self.client_call(lua, 1, "UIJewelUpgradeCallBack", "NetJewelUpgradeCallBack", {"iid": key, "pos": 1})
        cache = lua.globals().gamedata[b"cache"]
        self.assertIsNone(cache[b"jewels"][120002])
        self.client_call(lua, 1, "UIArtifactMountJewelCallBack", "NetArtifactMountJewelCallBack", {"iid": key, "jewelCid": 0, "pos": 1})
        self.assertEqual(cache[b"jewels"][120002][b"num"], 1)
        self.client_call(lua, 1, "UIUserArtifactRenascenceCallBack", "NetUserArtifactRenascenceCallBack", {"iid": key, "gold": 999999})
        self.assertEqual(cache[b"props"][20680][b"num"], 20)
        self.refresh()
        self.grant(120001, 2)
        lua.globals().gamedata.updateJewelData(lua.globals().gamedata, lua.table_from([lua.table_from({b"cid": 120001, b"num": 2})]))
        self.client_call(lua, 1, "UIJewelCommpondCallBack", "NetJewelCommpondCallBack", {"cid": 120002, "num": 1})
        self.assertEqual(cache[b"jewels"][120002][b"num"], 2)
        self.assertIsNone(cache[b"jewels"][120001])
        self.assertIsNone(lua.globals().gameConfig)

    def test_actual_network_strength_rebirth_and_stale_string_key_versions_are_safe(self):
        key = self.make()
        food = self.stock_food(110301, 1)[0]
        lua = self.network_lua(native_protobuf=True)
        with patch.object(artifact.random.Random, "randrange", return_value=0):
            result = self.client_call(lua, 1, "UIUserArtifactStrengthenCallBack", "NetUserArtifactStrengthenCallBack",
                                      {"iid": key, "expendList": [lua.table_from({b"iid": food})]})
        self.assertEqual(result[b"artifacts"][b"1"][b"level1"], 1)
        self.assertIsNone(lua.globals().gamedata[b"cache"][b"artifacts"][food])
        versions = lua.table_from({str(key).encode(): 1})
        mode, opcode, raw = lua.globals().UIUserArtifactLockCallBack(lua.table_from({b"cid": key, b"isLock": 1, b"artifactVersions": versions}))
        self.assertEqual(protocol.parse_ids_pb(raw)[:4], [0, 1, key, 1])
        self.refresh()
        self.assert_rejected(opcode, raw=raw)
        lua.globals().NetErrorMessageCallback9(lua.table_from({b"rbuf": recharge.ids([opcode, 0]), b"ser": 1}))
        result = self.client_call(lua, 1, "UIUserArtifactRenascenceCallBack", "NetUserArtifactRenascenceCallBack", {"iid": key})
        self.assertEqual([(v[b"cid"], v[b"num"]) for _, v in result[b"reward"].items()], [(110301, 1)])
        self.assertEqual(lua.globals().gamedata[b"cache"][b"artifacts"][key][b"level1"], 0)

    def test_real_rebirth_and_recast_confirmations_bind_selection_and_displayed_revision(self):
        lua = self.ui_lua()
        scripts = self.client_scripts()
        for filename, variable, entry in (("Layer_qiankunlu", "rebirth", "qiankunlu"),
                                           ("Layer_artifactCreate", "recast", "artifactCreate")):
            module = lua.execute(scripts["assets/scripts/"+filename+".so"].decode())
            lua.globals()[variable] = module
            lua.globals().GameScene.layers[entry] = lua.table_from({"show": True, "module": module})
        lua.execute('''ui.IDconfig=function(cid) return {staffType="artifact"} end
            GameScene.checkUpdate=function() return false end
            rebirth.rootNode=node();rebirth.rootItems=items();rebirth.localArtifactGeneration=1
            rebirth.selectpage="chongsheng";rebirth.allspendgold=5
            rebirth.chooseData={{iid=6000001,cid=110001,localRevision=4}}
            rebirth:chongshenginit();rebirth.rootItems.chongshengBtn.callback()
            local old=opened.callback;local count=#requests
            rebirth.chooseData[1].localRevision=5
            old();assert(#requests==count,"old rebirth confirmation charged a changed artifact")
            rebirth.rootItems.chongshengBtn.callback();opened.callback()
            assert(requests[#requests].artifactVersions[6000001]==5,"rebirth lost displayed version")
            rebirth:reloadPageData({type=5520,artifactView=LocalArtifactContext(),reward={}})
            rebirth.chooseData={{iid=6000002,cid=110001,localRevision=1}}
            count=#requests
            rebirth.shiftPage=function() error("old rebirth animation changed the page") end
            for _,callback in ipairs(callbacks) do callback() end
            for _,animation in ipairs(animations) do animation.callback() end
            assert(#requests==count,"old rebirth animation sent another query")
            local window=gameWindows.windows.artifactSelect
            window.module.artifactSelect=2
            assert(LocalArtifactContext(),"expanded list row is an index, not an artifact")
            window.module.artifactSelect=nil
            recast.rootNode=node();recast.rootItems=items();recast.localArtifactGeneration=1
            recast.selectpage="commpond";recast.artifactSelect={{iid=1},{iid=2},{iid=3}}
            gameWindows.windows.onceRecoin={module={consumeJudge=function() return 1 end}}
            recast:setBtnFuncs();recast.rootItems.combutton.callback()
            old=opened.callback;count=#requests
            recast.artifactSelect[3]={iid=4}
            old();assert(#requests==count,"old recast confirmation consumed replacement material")
        ''')

    def test_native_point_window_sends_actual_iid_and_ignores_closed_generation_and_old_materials(self):
        lua = self.ui_lua()
        code = builder.read_script("ui", "common_lua").decode().replace("\r\n", "\n")
        start = code.index("function ui.getIDandNUMs(")
        end = code.index("\nfunction ", start+1)
        lua.execute(code[start:end])
        # 使用原包的字符串分割工具，不往网络 Lua 中注入 UI 全局。
        start = code.index("function ui.Split(")
        end = code.index("\nfunction ", start+1)
        lua.execute(code[start:end])
        module = lua.execute(self.client_scripts()["assets/scripts/window_artifactSkillUp.so"].decode())
        lua.globals().point = module
        lua.globals().gameWindows.windows.artifactSkillUp = lua.table_from({"show": True, "module": module})
        code = self.client_scripts()["assets/scripts/UIProps.so"].decode()
        start = code.index("function UIPropQueryById(t)")
        end = code.index("\nfunction ", start+1)
        lua.execute(code[start:end])
        lua.execute('''local data={iid=6000001,skill1=9000566,localRevision=4}
            point:open(-103,{pos=1,data=data})
            local query=requests[#requests]
            assert(query.order==32003 and query.artifactView.property=="artifactSkillUp")
            UIPropQueryById({order=32003,artifactView=query.artifactView,nums={["20808"]=2}})
            point.rootItems.yesButton.callback()
            assert(requests[#requests].type==5543 and requests[#requests].iid==6000001)
            local oldClick=point.rootItems.yesButton.callback
            point:close();gameWindows.windows.artifactSkillUp.show=true
            point:open(-103,{pos=1,data={iid=6000002,skill1=9000566,localRevision=1}})
            local count=#requests
            oldClick();assert(#requests==count)
            point.isCanLevelup=false
            UIPropQueryById({order=32003,artifactView=query.artifactView,nums={["20808"]=2}})
            assert(not point.isCanLevelup)
        ''')

    def test_swap_confirmation_checks_same_iid_revision_and_old_animation_does_not_touch_new_page(self):
        lua = self.ui_lua()
        module = lua.execute(self.client_scripts()["assets/scripts/Layer_artifactSkillSwop.so"].decode())
        lua.globals().swap = module
        lua.globals().GameScene.layers.artifactSkillSwop = lua.table_from({"show": True, "module": module})
        lua.execute('''swap.rootNode=node();swap.rootItems=items();swap.localArtifactGeneration=1
            swap.artifactData1={iid=1,skill1=9000566,skill2=0,skill3=0,localRevision=1}
            swap.artifactData2={iid=2,skill1=9000591,skill2=0,skill3=0,localRevision=1}
            swap:setButtonStatus();swap.rootItems.doButton.callback()
            local old=opened.callback;local count=#requests
            swap.artifactData1.localRevision=2
            old();assert(#requests==count)
            swap:swopCallback({["1"]=swap.artifactData1,["2"]=swap.artifactData2})
            local complete=animations[#animations].callback
            swap:clear();swap.rootNode=node();swap.localArtifactGeneration=3
            local count=#animations
            complete();assert(#animations==count)
        ''')

    def test_new_families_and_strengthened_models_convert_real_apk_animations(self):
        existing = {r["name"] for group in self.config["trump_skillRnd"].values() for r in group.values()}
        self.config["trump_skillRnd"] = {"1": {k: r for k, r in self.config["trump_washing_skill"]["1"].items() if r["name"] not in existing}}
        original = self.unit
        def strengthened(*args, **kwargs):
            unit = original(*args, **kwargs)
            if "artifact" in unit:
                unit["artifact"]["level"] = 30
            return unit
        self.unit = strengthened
        test_artifact.ArtifactTests.test_all_artifact_reports_convert_actual_apk_animation_assets_and_preserve_terminal_hp_ap(self)

    def test_all_generated_scripts_compile_and_shared_point_configuration_is_exported(self):
        from lupa.lua51 import LuaRuntime
        lua = LuaRuntime(encoding=None)
        compile_lua = lua.eval(b"function(s,n) local f,e=loadstring(s,n); return f~=nil,e end")
        scripts = builder.get_patched_lua_scripts()
        ccb_keys = builder.ccb_resource_keys(builder.SRC_APK)
        for name, raw in scripts.items():
            data = builder.xxtea_decrypt(raw, builder.XXTEA_KEY)
            code = data[:struct.unpack("<I", data[-4:])[0]]
            ok, error = compile_lua(code, name.encode())
            self.assertTrue(ok, (name, error))
            if any(part in name for part in ("/Layer_artifact", "/window_artifact", "/window_jewel", "/window_onceRecoin", "/window_onceAddStrengthen")):
                for path in re.findall(rb'CCBReaderLoad\("([^"]+)"\s*[,)]', code):
                    key = "/".join(path.decode().removesuffix(".ccbi").split("/")[-2:])
                    self.assertIn(key, ccb_keys, (name, path))
        exported = dict(player.configuration.iter_config_bytes("configs_sec5.zip"))
        self.assertEqual(json.loads(exported["trump_config.json"])["skill_up_lv"]["value"], "5")
        self.assertEqual(self.config["trump_config"]["skill_up_lv"]["value"], "5")


if __name__ == "__main__":
    unittest.main()
