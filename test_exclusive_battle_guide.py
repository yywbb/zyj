"""专属神器战斗属性/技能接入与 S113–S119 引导真实进度回归。"""

from contextlib import redirect_stdout
import copy
from fractions import Fraction
import io
import json
from pathlib import Path
import random
import struct
import tempfile
import unittest
from unittest.mock import patch
import zipfile

import test_activity_copy as base
from zyj_server import (battle, configuration, exclusive_artifact as artifact,
                        formation, player, protocol, recharge)
from zyj_server.session import Session

ROOT = Path(__file__).parent
NOW = 1800172800
SECTIONS = tuple(range(113, 120))


def guide_rows(raw):
    result = {}
    for n, w, value in protocol.iter_pb_fields(raw):
        if (n, w) == (1, 2):
            result[protocol.pb_get_varint(value, 1)] = {
                "status": protocol.pb_get_varint(value, 2),
                "step": protocol.pb_get_varint(value, 3),
            }
    return result


class ExclusiveBattleGuideTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        base.ActivityCopyTests.setUpClass.__func__(cls)
        cls.baseline["role_state"].update(level=150, nextexp=cls.config["role_exp"]["150"]["nextexp"])

    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.path = Path(temporary.name) / "role_save.json"
        self.path.write_text(json.dumps(self.baseline))
        self.clock = patch("time.time", return_value=NOW).start()
        self.addCleanup(patch.stopall)
        quiet = redirect_stdout(io.StringIO())
        quiet.__enter__()
        self.addCleanup(quiet.__exit__, None, None, None)
        self.session = self.reconnect()
        for cid in (192087, 192088, 192089, 192090, 192091):
            player.change_item_count(self.session.save, cid, 200000, self.config, NOW)
        self.commit()

    def reconnect(self):
        return Session(self.tables, self.path, self.steps, self.config)

    def commit(self):
        self.path.write_text(json.dumps(self.session.save))

    def state(self):
        return artifact.get_state(self.session.save)

    def slot_iid(self):
        world = bytes.fromhex(self.session.save["world_state"]["1002"])
        slots = formation.records(world, 4, 1)
        return next(protocol.pb_get_varint(slot, 2) for slot in slots.values()
                    if protocol.pb_get_varint(slot, 2))

    def make_artifact(self, iid=None, cid=201501, level=0):
        iid = iid if iid is not None else self.slot_iid()
        self.state()["artifacts"][str(iid)] = {"cid": cid, "level": level,
                                               "inlay": [0] * 6, "spent": {}}
        self.commit()
        return iid

    def make_qiling(self, cid=201601):
        iid, _ = artifact.create_qiling(self.state(), cid, self.config, random.Random(11))
        self.commit()
        return iid

    def units(self, save=None):
        point = self.config["exclusive_device_soul_copy"]["1"]
        attack, _ = battle.rosters(save or self.session.save, point, self.config)
        return {unit["iid"]: unit for unit in attack.values()}

    def call(self, opcode, body=(), seq=181, *, raw=None):
        return self.session.handle(opcode, seq, raw if raw is not None else recharge.ids(body))

    def success(self, opcode, body=(), seq=181, *, raw=None):
        packets = self.call(opcode, body, seq=seq, raw=raw)
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], opcode, packets)
        return packets[0][16:]

    # ---- 战斗属性 ----
    def test_no_exclusive_state_leaves_rosters_unchanged(self):
        self.assertIsNone(self.session.save.get("exclusive_artifact_state"))
        self.assertEqual(artifact.combat_bonuses(self.session.save, self.config), {})
        units = self.units()
        self.assertTrue(units)
        self.assertTrue(all("exclusive_skills" not in unit for unit in units.values()))

    def test_artifact_base_and_strengthen_add_real_combat_stats(self):
        iid = self.slot_iid()
        before = self.units()[iid]["atk"]
        self.make_artifact(iid)
        bonus = artifact.combat_bonuses(self.session.save, self.config)[iid]
        self.assertEqual(bonus["fixed"]["atk"], 5000)  # g_atk 50000 × fairy_turn_every 0.1
        self.assertEqual(self.units()[iid]["atk"] - before, 5000)
        self.state()["artifacts"][str(iid)]["level"] = 1
        self.commit()
        bonus = artifact.combat_bonuses(self.session.save, self.config)[iid]
        self.assertEqual(bonus["fixed"]["atk"], 11360)  # 基础 5000 + 强化 63600×0.1
        self.assertEqual(self.units()[iid]["atk"] - before, 11360)

    def test_qiling_percent_and_fixed_attributes_are_applied(self):
        iid = self.slot_iid()
        before = self.units()[iid]["atk"]
        self.make_artifact(iid)
        percent_qiling = self.make_qiling(201604)  # atk / percent / 0.15 / location 4
        self.success(8104, [iid, 4, percent_qiling], seq=181)
        bonus = artifact.combat_bonuses(self.session.save, self.config)[iid]
        self.assertEqual(bonus["percent"]["atk"], Fraction("0.15"))
        fixed_qiling = self.make_qiling(201601)  # g_atk / value / 405000 / location 1
        self.success(8104, [iid, 1, fixed_qiling], seq=182)
        bonus = artifact.combat_bonuses(self.session.save, self.config)[iid]
        self.assertEqual(bonus["fixed"]["atk"], 5000 + 40500)
        unit = self.units()[iid]
        general_row = self.config["general"][str(unit["cid"])]
        expected_percent = int(battle.general_base(general_row, "atk", unit["level"], unit["advance"], self.config)
                               * Fraction("0.24"))  # 器灵15% + 实际两件套9%。
        self.assertGreater(expected_percent, 0)
        self.assertEqual(unit["atk"], before + bonus["fixed"]["atk"] + expected_percent)

    def test_corrupt_state_never_breaks_battle_rosters(self):
        save = copy.deepcopy(self.session.save)
        save["exclusive_artifact_state"] = {"version": 2, "artifacts": "bad"}
        self.assertEqual(artifact.combat_bonuses(save, self.config), {})
        self.assertEqual(set(self.units(save)), set(self.units()))

    # ---- 战斗技能 ----
    def baptism_level_row(self, wanted):
        table = self.config["exclusive_intensify"]["1"]
        return int(next(key for key, row in table.items() if int(row["baptism_level"]) >= wanted))

    def test_supported_skills_inject_into_real_battle_without_engine_errors(self):
        iid = self.slot_iid()
        self.make_artifact(iid, level=self.baptism_level_row(1))
        first = self.make_qiling(201601)
        second = self.make_qiling(201602)
        self.success(8104, [iid, 1, first], seq=181)
        self.success(8104, [iid, 2, second], seq=182)
        bonus = artifact.combat_bonuses(self.session.save, self.config)[iid]
        self.assertTrue(bonus["skills"])
        allowed = artifact.skill_ids(self.config)
        dynamic = battle.supported_breakthrough(self.config)
        self.assertTrue(all(skill in allowed and artifact.supported_skill(skill, self.config, dynamic)
                            for skill in bonus["skills"]))
        unit = self.units()[iid]
        self.assertEqual(unit["exclusive_skills"], bonus["skills"])
        point = self.config["exclusive_device_soul_copy"]["1"]
        attack, defense = battle.rosters(self.session.save, point, self.config)
        report = battle.simulate(attack, defense, self.config, 7)
        self.assertIn(int(report["result"]), (0, 1))
        attack2, defense2 = battle.rosters(self.session.save, point, self.config)
        battle._prepare_teams({True: attack2, False: defense2}, self.config)
        target = next(unit for unit in attack2.values() if unit["iid"] == iid)
        # 9000692 是 type=0 静态行，只走 add()，不能污染广成子 9001147 的 effects 编号。
        self.assertNotIn(9000692, target["effects"])
        self.assertGreater(target["out_multiplier"], 1)

    def test_unimplemented_trigger_skills_are_filtered_not_injected(self):
        iid = self.slot_iid()
        self.make_artifact(iid, level=self.baptism_level_row(3))
        exclusive = self.config["exclusive"]["201501"]
        unsupported = next(skill for skill in (exclusive[f"skill{n}"] for n in range(1, 6))
                           if not artifact.supported_skill(skill, self.config, battle.supported_breakthrough(self.config)))
        bonus = artifact.combat_bonuses(self.session.save, self.config)[iid]
        self.assertIn(int(exclusive["skill1"]), bonus["skills"])
        self.assertNotIn(int(unsupported), bonus["skills"])
        point = self.config["exclusive_device_soul_copy"]["1"]
        attack, defense = battle.rosters(self.session.save, point, self.config)
        report = battle.simulate(attack, defense, self.config, 3)
        self.assertIn(int(report["result"]), (0, 1))

    # ---- 引导 ----
    def test_step_counts_cover_all_exclusive_sections(self):
        for section in SECTIONS:
            self.assertGreater(self.steps[section], 0)

    def test_guide_section_override_is_consistent_between_server_and_apk(self):
        with zipfile.ZipFile(ROOT / "configs_sec5.zip") as archive:
            raw = json.loads(archive.read("5/guide_section.json"))
        changed = configuration.apply_overrides("guide_section", copy.deepcopy(raw), {})
        self.assertEqual(changed["113"]["condition"], "2")
        self.assertEqual(changed["114"], raw["114"])
        emitted = dict(configuration.iter_config_bytes(ROOT / "configs_sec5.zip"))
        self.assertEqual(json.loads(emitted["guide_section.json"]), changed)

    def test_standalone_201_reports_real_progress_for_113_119(self):
        for index, section in enumerate(SECTIONS):
            with self.subTest(section=section):
                body = (protocol.encode_pb_field(1, 0, section)
                        + protocol.encode_pb_field(2, 0, 1))
                self.assertEqual(self.success(201, seq=300 + index, raw=body), b"\x08\x01")
                record = self.session.save["guide"]["sections"][str(section)]
                expected = 2 if self.steps[section] == 1 else 1  # 单步段上报首步即完成
                self.assertEqual((record["status"], record["step"], record["steps"]), (expected, 1, [1]))
                rows = guide_rows(self.success(200, seq=400 + index))
                self.assertEqual(rows[section], {"status": expected, "step": 1})
        self.session = self.reconnect()
        rows = guide_rows(self.success(200, seq=500))
        self.assertEqual({section: rows[section]["step"] for section in SECTIONS},
                         dict.fromkeys(SECTIONS, 1))
        final = self.steps[113]
        self.success(201, seq=501, raw=protocol.encode_pb_field(1, 0, 113)
                     + protocol.encode_pb_field(2, 0, final))
        self.assertEqual(self.session.save["guide"]["sections"]["113"]["status"], 2)
        self.success(201, seq=502, raw=protocol.encode_pb_field(1, 0, 113)
                     + protocol.encode_pb_field(2, 0, 1))
        self.assertEqual(self.session.save["guide"]["sections"]["113"]["step"], final)

    def test_guide_rejects_unknown_and_out_of_range_reports(self):
        before = copy.deepcopy(self.session.save["guide"])
        for body in (recharge.ids([113, self.steps[113] + 1]), recharge.ids([99999, 1])):
            with self.assertRaises(ValueError):
                self.session.handle(201, 600, body)
        self.assertEqual(self.session.save["guide"], before)

    def test_real_exclusive_operations_never_auto_complete_guide(self):
        iid = self.slot_iid()
        self.make_artifact(iid)
        qiling = self.make_qiling()
        before = copy.deepcopy(self.session.save["guide"])
        self.success(8102, [iid, 1], seq=181)
        self.success(8104, [iid, 1, qiling], seq=182)
        self.success(8107, [qiling, 1], seq=183)
        self.success(8101, [iid], seq=184)
        self.assertEqual(self.session.save["guide"], before)
        self.assertEqual(self.session.save["guide"]["sections"], before["sections"])
