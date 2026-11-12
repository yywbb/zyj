"""专属神器属性/战力同笔结算，旧档、换将、冻结与失败回滚。"""

import copy
from fractions import Fraction
import json
import unittest
from unittest.mock import patch

import test_exclusive_battle_guide as base
import test_exclusive_artifact as native
from zyj_server import battle, cup, exclusive_artifact as artifact, formation, guild_war, player, protocol, qiankun, single_boss, training


class ExclusiveStatsTests(unittest.TestCase):
    setUpClass = classmethod(base.ExclusiveBattleGuideTests.setUpClass.__func__)
    reconnect = base.ExclusiveBattleGuideTests.reconnect
    commit = base.ExclusiveBattleGuideTests.commit
    state = base.ExclusiveBattleGuideTests.state
    slot_iid = base.ExclusiveBattleGuideTests.slot_iid
    make_artifact = base.ExclusiveBattleGuideTests.make_artifact
    make_qiling = base.ExclusiveBattleGuideTests.make_qiling
    units = base.ExclusiveBattleGuideTests.units
    call = base.ExclusiveBattleGuideTests.call
    success = base.ExclusiveBattleGuideTests.success
    set_general_cid = native.ExclusiveArtifactTests.set_general_cid

    def setUp(self):
        base.ExclusiveBattleGuideTests.setUp(self)
        self.session.save["guide"]["sections"]["1"] = {
            "status": 2, "step": self.steps[1], "steps": list(range(1, self.steps[1] + 1))}
        self.commit()

    def general(self, iid):
        return formation.records(bytes.fromhex(self.session.save["world_state"]["1002"]), 1, 2)[iid]

    def test_strengthen_updates_real_panel_power_and_battle_only_once(self):
        iid = self.slot_iid()
        original = self.general(iid)
        power = self.session.save["role_state"]["power"]
        self.make_artifact(iid)
        packets = self.call(8102, [iid, 1])
        current = self.general(iid)
        self.assertEqual(protocol.pb_get_varint(current, 6) - protocol.pb_get_varint(original, 6), 11360)
        self.assertEqual(protocol.pb_get_varint(current, 20) - protocol.pb_get_varint(original, 20), 11360)
        self.assertEqual(self.session.save["role_state"]["power"] - power, 11360)
        self.assertEqual(self.units()[iid]["atk"], protocol.pb_get_varint(current, 6))
        mids = [int.from_bytes(p[8:12], "big") for p in packets]
        self.assertEqual(mids.count(205), 1)
        self.assertIn(1027, mids)
        self.assertEqual(protocol.parse_ids_pb(next(p[16:] for p in packets if int.from_bytes(p[8:12], "big") == 205))[:2],
                         [11360, power + 11360])
        saved = copy.deepcopy(self.session.save)
        self.assertEqual(self.call(8102, [iid, 1]), packets)
        self.assertEqual(self.session.save, saved)
        self.session = self.reconnect()
        self.success(1002, seq=190)
        self.assertEqual(self.general(iid), current)
        self.assertEqual(self.session.save["role_state"]["power"], power + 11360)

    def test_real_activation_victory_adds_base_stats_and_power_immediately(self):
        native.ExclusiveArtifactTests.make_gold_general(self)
        native.ExclusiveArtifactTests.power(self)
        slots = artifact.generals(self.session.save)[1]
        protagonist = protocol.pb_get_varint(bytes.fromhex(self.session.save["protagonist_snapshot"]), 1)
        iid = next(protocol.pb_get_varint(slot, 2) for slot in slots.values()
                   if protocol.pb_get_varint(slot, 2) not in (0, None, protagonist))
        original = self.general(iid)
        power = self.session.save["role_state"]["power"]
        reply = native.messages(self.success(8103, [iid], seq=181))
        self.assertEqual(protocol.pb_get_varint(reply[1], 1), 1)
        self.assertEqual(protocol.pb_get_varint(self.general(iid), 6) - protocol.pb_get_varint(original, 6), 5000)
        self.assertEqual(self.session.save["role_state"]["power"] - power, 5000)

    def test_old_save_battle_projection_and_migration_agree_without_read_side_effects(self):
        iid = self.slot_iid()
        original = self.general(iid)
        self.make_artifact(iid, level=1)
        before = copy.deepcopy(self.session.save)
        expected = self.units()[iid]["atk"]
        artifact.prepare(8101, self.session.save, b"", self.config, 1800172800, 1)
        self.assertEqual(self.session.save, before)
        self.assertEqual(self.path.read_text(), json.dumps(before))
        self.success(1002, seq=190)
        self.assertEqual(protocol.pb_get_varint(self.general(iid), 6), expected)
        self.assertEqual(expected - protocol.pb_get_varint(original, 6), 11360)
        self.assertEqual(self.units()[iid]["atk"], expected)
        stable = self.general(iid)
        self.success(1002, seq=191)
        self.assertEqual(self.general(iid), stable)

    def test_attack_two_piece_suit_reaches_panel_and_combat(self):
        iid = self.slot_iid()
        original = self.general(iid)
        self.make_artifact(iid)
        first, second = self.make_qiling(201601), self.make_qiling(201602)
        self.success(8104, [iid, 1, first], seq=181)
        before = self.general(iid)
        self.success(8104, [iid, 2, second], seq=182)
        cid = protocol.pb_get_varint(original, 1)
        base = battle.general_base(self.config["general"][str(cid)], "atk", protocol.pb_get_varint(original, 3),
                                   protocol.pb_get_varint(original, 4) or 0, self.config)
        expected = int(base * 9 // 100)
        self.assertGreater(expected, 0)
        self.assertEqual(protocol.pb_get_varint(self.general(iid), 6) - protocol.pb_get_varint(before, 6), expected)
        unit = self.units()[iid]
        self.assertEqual(unit["atk"], protocol.pb_get_varint(self.general(iid), 6))
        enemy = {**unit, "iid": 999999, "exclusive_skills": []}
        teams = {True: {2: copy.deepcopy(unit)}, False: {2: enemy}}
        battle._prepare_teams(teams, self.config)
        self.assertEqual(teams[True][2]["atk"], unit["atk"])
        self.success(8104, [iid, 2, 0], seq=183)
        self.assertEqual(self.general(iid), before)

    def test_percent_qiling_tracks_growth_and_does_not_multiply_other_training(self):
        iid = self.slot_iid()
        self.make_artifact(iid)
        spirit = self.make_qiling(201604)
        self.success(8104, [iid, 4, spirit], seq=181)
        before = self.general(iid)
        changed = protocol.pb_set_varint(before, 6, protocol.pb_get_varint(before, 6) + 1234)
        player.record_slot_update(self.session.save, protocol.encode_pb_field(1, 2, changed))
        player.record_protagonist_general(self.session.save, changed)
        self.commit()
        self.success(1002, seq=182)
        self.assertEqual(protocol.pb_get_varint(self.general(iid), 6), protocol.pb_get_varint(before, 6) + 1234)
        self.success(8104, [iid, 4, 0], seq=183)
        self.assertEqual(self.units()[iid]["atk"], protocol.pb_get_varint(self.general(iid), 6))

    def test_real_level_up_recalculates_percent_but_not_other_training(self):
        iid = self.slot_iid()
        self.make_artifact(iid)
        spirit = self.make_qiling(201604)
        self.success(8104, [iid, 4, spirit], seq=181)
        player.change_item_count(self.session.save, 20199, 1, self.config, 1800172800)
        self.commit()
        before = copy.deepcopy(self.session.save)
        old = self.general(iid)
        body = protocol.encode_pb_field(1, 0, iid) + b"".join(protocol.encode_pb_field(2, 0, n) for n in (0, 0, 0, 1))
        preview, _, _ = training.use_exp(copy.deepcopy(before), body, self.config)
        grown = next(v for n, w, v in protocol.iter_pb_fields(preview) if (n, w) == (8, 2))
        self.assertGreater(protocol.pb_get_varint(grown, 3), protocol.pb_get_varint(old, 3))
        bonus = artifact.combat_bonuses(before, self.config)[iid]
        delta = int(artifact.attributes(grown, bonus, self.config)[6]) - int(artifact.attributes(old, bonus, self.config)[6])
        self.assertGreater(delta, 0)
        self.success(1038, raw=body, seq=182)
        self.assertEqual(protocol.pb_get_varint(self.general(iid), 6), protocol.pb_get_varint(grown, 6) + delta)
        self.assertEqual(self.units()[iid]["atk"], protocol.pb_get_varint(self.general(iid), 6))

    def test_worn_qiling_strengthen_updates_panel_power_only_on_success(self):
        iid = self.slot_iid()
        self.make_artifact(iid)
        spirit = self.make_qiling(201601)
        self.success(8104, [iid, 1, spirit], seq=181)
        original = self.general(iid)
        with patch.object(artifact.random.Random, "randrange", return_value=99):
            self.success(8106, [spirit], seq=182)
        self.assertEqual(self.general(iid), original)
        with patch.object(artifact.random.Random, "randrange", return_value=0):
            self.success(8106, [spirit], seq=183)
        self.assertGreater(protocol.pb_get_varint(self.general(iid), 6), protocol.pb_get_varint(original, 6))
        self.assertGreater(protocol.pb_get_varint(self.general(iid), 20), protocol.pb_get_varint(original, 20))

    def test_new_frozen_rosters_keep_artifacts_and_are_independent_of_later_changes(self):
        iid = self.slot_iid()
        self.make_artifact(iid, level=1)
        first, second = self.make_qiling(201601), self.make_qiling(201602)
        hidden = self.make_qiling(201603)
        self.success(8104, [iid, 1, first], seq=181)
        self.success(8104, [iid, 2, second], seq=182)
        self.success(1002, seq=183)
        expected = self.units()[iid]["atk"]
        snapshots = [cup.frozen(self.session.save, 1, self.config)["snapshot"], guild_war.freeze(self.session.save)]
        for snapshot in snapshots:
            self.assertIn("exclusive_artifact_state", snapshot)
            self.assertEqual(self.units(snapshot)[iid]["atk"], expected)
            self.assertNotIn("spent", snapshot["exclusive_artifact_state"]["artifacts"][str(iid)])
            self.assertEqual(set(snapshot["exclusive_artifact_state"]["qilings"]), {str(first), str(second)})
            self.assertNotIn(str(hidden), snapshot["exclusive_artifact_state"]["qilings"])
        self.success(8102, [iid, 1], seq=184)
        self.assertGreater(self.units()[iid]["atk"], expected)
        for snapshot in snapshots:
            self.assertEqual(self.units(snapshot)[iid]["atk"], expected)

    def test_old_frozen_rosters_do_not_pick_up_new_equipment(self):
        snapshot = cup.frozen(self.session.save, 1, self.config)["snapshot"]
        original = copy.deepcopy(snapshot)
        units = self.units(snapshot)
        self.make_artifact(self.slot_iid(), level=1)
        self.success(1002, seq=181)
        self.assertEqual(self.units(snapshot), units)
        self.assertEqual(snapshot, original)

    def test_rebirth_removes_exact_growth_and_keeps_base_attributes(self):
        iid = self.slot_iid()
        original = self.general(iid)
        self.make_artifact(iid)
        self.success(8102, [iid, 1], seq=181)
        spirit = self.make_qiling(201601)
        self.success(8104, [iid, 1, spirit], seq=182)
        player.change_item_count(self.session.save, 1025, 100000, self.config, 1800172800)
        self.commit()
        self.success(8204, [iid], seq=183)
        after = self.general(iid)
        self.assertEqual(protocol.pb_get_varint(after, 6) - protocol.pb_get_varint(original, 6), 5000)
        self.assertEqual(protocol.pb_get_varint(after, 20) - protocol.pb_get_varint(original, 20), 5000)
        self.assertEqual(self.units()[iid]["atk"], protocol.pb_get_varint(after, 6))

    def test_save_failure_rolls_back_migration_costs_and_power_together(self):
        iid = self.slot_iid()
        self.make_artifact(iid)
        memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.call(8102, [iid, 1])
        self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))

    def test_activation_owner_is_protected_from_general_removal(self):
        world = bytes.fromhex(self.session.save["world_state"]["1002"])
        slots = formation.records(world, 4, 1)
        iid = protocol.pb_get_varint(slots[2], 2)
        self.make_artifact(iid)
        request = protocol.encode_pb_field(1, 0, 2) + protocol.encode_pb_field(3, 0, 0)
        self.success(1003, seq=181, raw=request)
        self.assertIn(iid, qiankun.protected(self.session.save))
        self.assertNotIn(iid, {protocol.pb_get_varint(slot, 2) for slot in artifact.generals(self.session.save)[1].values()})

    def test_all_eligible_suit_tiers_remain_active_at_four_and_six_pieces(self):
        iid = self.slot_iid()
        self.make_artifact(iid)
        for pos in range(1, 7):
            row = next(row for row in self.config["exclusive_device_spirit"].values()
                       if row["suit"] == 1 and row["location"] == pos)
            key = self.make_qiling(row["id"])
            self.success(8104, [iid, pos, key], seq=180 + pos)
            if pos in (2, 4, 6):
                item = self.state()["artifacts"][str(iid)]
                self.assertEqual([sid for sid in artifact.suit_ids(item, self.state(), self.config) if sid],
                                 list(range(1, pos // 2 + 1)))
                bonus = artifact.combat_bonuses(self.session.save, self.config)[iid]
                self.assertEqual(bonus["percent"]["atk"], Fraction((21 if pos == 6 else 9) + (15 if pos >= 4 else 0), 100))

    def test_idle_and_dedicated_rosters_keep_personal_stats_without_double_power(self):
        slots = artifact.generals(self.session.save)[1]
        iid = protocol.pb_get_varint(slots[2], 2)
        original = self.general(iid)
        self.make_artifact(iid)
        self.success(8102, [iid, 1], seq=181)
        expected = self.general(iid)
        self.success(1003, raw=protocol.encode_pb_field(1, 0, 2) + protocol.encode_pb_field(3, 0, 0), seq=182)
        idle = self.general(iid)
        power = self.session.save["role_state"]["power"]
        temporary, dedicated_power = single_boss.project_team(self.session.save,
            [self.slot_iid(), iid, 0, 0, 0, 0, 0, 0], self.config)
        dedicated = artifact.generals(temporary)[0][iid]
        self.assertEqual(self.units(temporary)[iid]["atk"], protocol.pb_get_varint(dedicated, 6))
        self.assertGreater(protocol.pb_get_varint(idle, 6), protocol.pb_get_varint(original, 6))
        self.assertEqual(self.general(iid), idle)
        self.assertGreater(dedicated_power, power)
        self.success(1003, raw=protocol.encode_pb_field(1, 0, 2) + protocol.encode_pb_field(3, 0, iid), seq=183)
        self.assertEqual(self.general(iid), expected)

    def test_stat_and_role_power_overflow_reject_without_consumption_or_partial_migration(self):
        iid = self.slot_iid()
        self.make_artifact(iid)
        for target in ("stat", "power"):
            with self.subTest(target=target):
                original = copy.deepcopy(self.session.save)
                if target == "stat":
                    raw = protocol.pb_set_varint(self.general(iid), 6, (1 << 31) - 1)
                    player.record_slot_update(self.session.save, protocol.encode_pb_field(1, 2, raw))
                    player.record_protagonist_general(self.session.save, raw)
                else:
                    self.session.save["role_state"].update(power=(1 << 31) - 1, power_all=(1 << 31) - 1)
                self.commit()
                before, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
                packets = self.call(8102, [iid, 1], seq=190)
                self.assertEqual(int.from_bytes(packets[0][8:12], "big"), 999999)
                self.assertEqual((self.session.save, self.path.read_bytes()), (before, disk))
                self.session.save = original
                self.commit()

    def test_applied_ledger_is_strictly_validated_on_reconnect(self):
        iid = self.slot_iid()
        self.make_artifact(iid)
        for values in (None, True, [], [0] * 11, [False] * 12, [1 << 31] * 12):
            with self.subTest(values=values):
                self.state()["applied"] = {str(iid): values}
                self.commit()
                with self.assertRaises(ValueError):
                    self.reconnect()
                self.session.save["exclusive_artifact_state"].pop("applied", None)


if __name__ == "__main__":
    unittest.main()
