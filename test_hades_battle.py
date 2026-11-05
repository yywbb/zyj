import copy
from fractions import Fraction
from pathlib import Path
import unittest
from unittest.mock import patch

from zyj_server import battle, player


class HadesBattleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.config = player.load_role_config(Path(__file__).with_name("configs_sec5.zip"))

    def unit(self, cid=10201, **values):
        return {"cid": cid, "iid": cid, "level": 10, "advance": 0, "atk": 100, "def": 0, "hp": 10000,
                "speed": 100, "skill": self.config["general"][str(cid)]["skillid"], "initial_ap": 0, **values}

    def config_for(self, cid, *ids):
        row = {**self.config["general"][str(cid)], **{f"break{i}": pid for i, pid in enumerate(ids, 1)}}
        return {**self.config, "general": {**self.config["general"], str(cid): row}}

    def hits(self, report, direct=True, pos=2):
        return [d["m"]["m"] for a in report["b"]["a"] if a["s"].get("r") == direct and a["s"].get("p") == [pos]
                and a["s"]["t"] in ("N", "k", "x") for d in a["e"] if d["r"] != direct and isinstance(d.get("m"), dict)]

    def assert_replays(self, report):
        units = {}
        for side, direct in (("attack", True), ("defense", False)):
            for pos, row in report["b"]["init"][side].items():
                raw = report["meta"][side]["pet" if pos == "0" else "g"][str(row["i"])]
                units[direct, int(pos)] = {"hp": raw["h"], "maxhp": raw["j"], "ap": raw["ap"], "cover": raw.get("cover_d", 0)}
        for action in report["b"]["a"]:
            if action["s"] and action["s"]["t"] != "break":
                for pos in action["s"]["p"]:
                    self.assertGreater(units[action["s"]["r"], pos]["hp"], 0)
            for dest in action["e"]:
                unit = units[dest["r"], dest["p"]]
                if isinstance(dest.get("m"), dict):
                    unit["hp"] -= dest["m"]["m"]
                    unit["cover"] -= dest["m"].get("M", 0)
                    self.assertTrue(0 <= unit["hp"] <= unit["maxhp"])
                    self.assertGreaterEqual(unit["cover"], 0)
                if "ap" in dest:
                    unit["ap"] = dest["ap"]
                    self.assertTrue(0 <= unit["ap"] <= 10)
        for side, direct in (("attack", True), ("defense", False)):
            for pos, row in report["endmeta"][side].items():
                unit = units[direct, int(pos)]
                self.assertEqual((row["h"], row["ap"], row["cover_d"]), (unit["hp"], unit["ap"], unit["cover"]))

    def test_damage_families_use_real_fractions_not_referenced_rows(self):
        for pid, expected in ((9000314, 150), (9000318, 220), (9000403, 120), (9000405, 150), (9000407, 115)):
            with self.subTest(pid=pid):
                report = battle.simulate({2: self.unit(advance=1, speed=300)}, {2: self.unit(iid=1, atk=1)}, self.config_for(10201, pid), 7, max_rounds=1)
                self.assertEqual(self.hits(report)[0], expected)
                self.assert_replays(report)

    def test_valid_negative_correction_and_invalid_multiplier_boundaries(self):
        actor = self.unit(speed=300, adddmgpct=Fraction(-17, 100))
        report = battle.simulate({2: actor}, {2: self.unit(iid=1)}, self.config, 7, max_rounds=1)
        self.assertEqual(self.hits(report)[0], 83)
        for added in (-1, -2):
            with self.assertRaisesRegex(ValueError, "增减伤"):
                battle.simulate({2: {**actor, "adddmgpct": added}}, {2: self.unit(iid=1)}, self.config, 7)

    def test_back_row_initial_ap_and_red_flat_aura_do_not_stack(self):
        config = self.config_for(10201, 9000289, 9000353)
        teams = {True: {2: self.unit(advance=2), 8: self.unit(iid=8, advance=2), 10: self.unit(10839, iid=10)}, False: {2: self.unit(iid=1)}}
        battle._prepare_teams(teams, config)
        self.assertEqual([u["ap"] for u in teams[True].values()], [0, 1, 1])
        self.assertEqual(teams[True][10]["atk"], 100100)
        self.assertEqual(teams[True][2]["atk"], 100)
        self.assertEqual(teams[False][2]["ap"], 0)

    def test_missing_hp_reduction_uses_pre_hit_hp_and_floors_after_reduction(self):
        config = self.config_for(10305, 9000022)
        report = battle.simulate({2: self.unit(speed=300), 8: self.unit(iid=8, speed=200)},
                                 {2: self.unit(10305, iid=1, advance=1, hp=1000, speed=1)}, config, 7, max_rounds=1)
        self.assertEqual((self.hits(report)[0], self.hits(report, pos=8)[0]), (100, 93))
        self.assert_replays(report)
        report = battle.simulate({2: self.unit(speed=300, atk=900), 8: self.unit(iid=8, speed=200, atk=1000)},
                                 {2: self.unit(10305, iid=1, advance=1, hp=1000, speed=1)}, config, 7, max_rounds=1)
        self.assertEqual(report["endmeta"]["defense"]["2"]["h"], 0)
        self.assert_replays(report)

    def test_low_hp_skill_and_basic_immunity_respect_strict_thresholds_and_block_healing(self):
        config = self.config_for(10305, 9000315)
        for opening, remaining in ((800, 200), (750, 0)):
            report = battle.simulate({2: self.unit(speed=400, atk=opening), 8: self.unit(iid=8, speed=300, initial_ap=4, atk=1000)},
                                     {2: self.unit(10305, iid=1, advance=1, hp=1000, speed=1),
                                      8: self.unit(10610, iid=2, initial_ap=4, atk=1000, speed=200)}, config, 7, max_rounds=1)
            self.assertEqual(report["endmeta"]["defense"]["2"]["h"], remaining)
            self.assert_replays(report)
        config = self.config_for(10305, 9000316)
        report = battle.simulate({2: self.unit(speed=400, atk=850), 8: self.unit(iid=8, speed=300)},
                                 {2: self.unit(10305, iid=1, advance=1, hp=1000, speed=1)}, config, 7, max_rounds=1)
        self.assertEqual(report["endmeta"]["defense"]["2"]["h"], 150)
        self.assert_replays(report)

    def test_death_explosion_uses_this_rows_value_for_every_enemy(self):
        report = battle.simulate({2: self.unit(speed=400, atk=1000), 8: self.unit(iid=8)},
                                 {2: self.unit(10305, iid=1, advance=1, hp=1, speed=1)}, self.config_for(10305, 9000110), 7, max_rounds=1)
        explosion = next(a for a in report["b"]["a"] if a["s"].get("S") == 9000110)
        self.assertEqual([d["m"]["m"] for d in explosion["e"]], [30, 30])
        self.assert_replays(report)

    def test_contract_pays_once_with_extra_casts_and_fire_seeds_scale_both_directions(self):
        report = battle.simulate({2: self.unit(advance=2, initial_ap=4, speed=300)}, {2: self.unit(iid=1, atk=1, hp=1000000)},
                                 self.config_for(10201, 9000307, 9000667), 7, max_rounds=1)
        self.assertEqual(self.hits(report), [360, 360])
        self.assertEqual(report["endmeta"]["attack"]["2"]["h"], 8999)
        self.assert_replays(report)
        report = battle.simulate({2: self.unit(advance=1, speed=300)}, {2: self.unit(iid=1)}, self.config_for(10201, 9000691), 7, max_rounds=2)
        self.assertEqual(self.hits(report), [108, 116])
        self.assertEqual(self.hits(report, False), [92, 84])
        self.assert_replays(report)

    def test_qianlong_reduces_hit_then_hides_before_another_enemy_can_target(self):
        report = battle.simulate({2: self.unit(advance=1, speed=300)},
                                 {2: self.unit(iid=1, speed=200), 8: self.unit(iid=8, speed=100)}, self.config_for(10201, 9000685), 7, max_rounds=1)
        self.assertEqual(report["endmeta"]["attack"]["2"]["h"], 9980)
        self.assertFalse(self.hits(report, False, 8))
        self.assertTrue(any(d.get("u") == {"u": "hide", "w": True} for a in report["b"]["a"] for d in a["e"]))
        self.assert_replays(report)

    def test_artifact_extra_attacks_stop_when_only_hidden_enemies_remain(self):
        for name in ("连击", "残暴"):
            for direct in (True, False):
                with self.subTest(name=name, direct=direct):
                    config = copy.deepcopy(self.config_for(10305, 9000685))
                    row = next(r for r in config["trump_skillRnd"]["3"].values() if r["name"] == name)
                    sid = row["skill6"]
                    config["breakskill"][str(sid)]["value"] = 1
                    actor = self.unit(iid=9000, speed=400, artifact={"cid": 110009, "level": 0, "skills": [sid]})
                    attack = {2: actor} if name == "连击" else {2: self.unit(iid=9001, speed=450), 8: actor}
                    defense = {2: self.unit(10305, iid=1, advance=1, speed=500, atk=1)}
                    if name == "残暴":
                        defense[8] = self.unit(iid=8, hp=1, speed=1)
                    teams = {direct: attack, not direct: defense}
                    before = copy.deepcopy(teams)
                    report = battle.simulate(teams[True], teams[False], config, 7, max_rounds=1)
                    self.assertEqual(teams, before)
                    self.assertEqual(len(self.hits(report, direct, 2 if name == "连击" else 8)), 1)
                    self.assertTrue(any(d.get("u") == {"u": "hide", "w": True} for a in report["b"]["a"] for d in a["e"]))
                    self.assert_replays(report)

    def test_basic_transfer_does_not_recurse_and_preserves_report_hp(self):
        config = self.config_for(10305, 9000363)
        report = battle.simulate({2: self.unit(speed=300)}, {2: self.unit(10305, iid=1, advance=1, atk=1)}, config, 7, max_rounds=1)
        self.assertEqual(self.hits(report)[0], 0)
        self.assertEqual(report["endmeta"]["defense"]["2"]["h"], 10000)
        self.assertLess(report["endmeta"]["attack"]["2"]["h"], 10000)
        self.assert_replays(report)

    def test_self_revive_is_once_per_battle_and_lethal_stand_keeps_one_hp(self):
        for pid in (9000376, 9000379):
            config = self.config_for(10305, pid)
            report = battle.simulate({2: self.unit(speed=300)}, {2: self.unit(10305, iid=1, advance=1, hp=1, atk=1)}, config, 7, max_rounds=2)
            if pid == 9000376:
                self.assertEqual(sum(a["s"].get("S") == pid for a in report["b"]["a"]), 1)
            else:
                self.assertEqual(sum(d.get("u") == {"u": "invincible", "w": True} for a in report["b"]["a"] for d in a["e"]), 1)
            self.assertEqual(report["endmeta"]["defense"]["2"]["h"], 0)
            self.assert_replays(report)

    def test_personal_revival_hides_only_for_current_round_and_keeps_dead_ap(self):
        config = self.config_for(10610, 9000516)
        report = battle.simulate({2: self.unit(speed=500)},
                                 {2: self.unit(10305, iid=1, hp=1, atk=1, initial_ap=2),
                                  8: self.unit(10610, iid=8, advance=1, speed=200, initial_ap=4)}, config, 7, max_rounds=2)
        revived = next(a for a in report["b"]["a"] if a["s"].get("S") == 9000516)
        self.assertTrue(any(d.get("u") == {"u": "hide", "w": True} for d in revived["e"]))
        self.assertTrue(any(d.get("u") == {"u": "hide", "w": False} for a in report["b"]["a"] for d in a["e"]))
        self.assert_replays(report)

    def test_control_and_ap_immunity_and_pet_exception_are_real(self):
        config = self.config_for(10305, 9000537)
        config = {**config, "general": {**config["general"], "10201": {**config["general"]["10201"], "break1": 9100002, "break2": 9000370}}}
        with patch.object(battle.random.Random, "random", return_value=0):
            report = battle.simulate({2: self.unit(advance=2, speed=300)}, {2: self.unit(10305, iid=1, advance=1, initial_ap=4)}, config, 7, max_rounds=1)
        first = report["b"]["a"][0]
        self.assertFalse(any(d.get("u", {}).get("u") == "dizzy" for d in first["e"]))
        self.assertTrue(all(d["ap"] == 4 for d in first["e"] if d["r"] is False and "ap" in d))
        phase = min(int(k) for k, r in config["pet3_attr"]["90008"].items() if r["skillid"] == 12997)
        pet = {"cid": 90008, "iid": 999, "phase": phase, "level": 1}
        petrow = config["pet3_attr"]["90008"][str(phase)]
        config = {**config, "combskill": {**config["combskill"], str(petrow["skillid"]): {**config["combskill"][str(petrow["skillid"])], "trigger": 1}}}
        report = battle.simulate({2: self.unit()}, {2: self.unit(10305, iid=1, advance=1, initial_ap=4)}, config, 7, attack_pet=pet, max_rounds=1)
        self.assertTrue(any(d.get("ap") == 2 and d["r"] is False for d in report["b"]["a"][0]["e"]))
        self.assert_replays(report)

    def test_taunt_overrides_highest_attack_target_and_expires_after_two_rounds(self):
        config = self.config_for(10305, 9000508)
        config = {**config, "general": {**config["general"], "10201": {**config["general"]["10201"], "break1": 9000539}}}
        report = battle.simulate({2: self.unit(advance=1, speed=300)}, {2: self.unit(iid=1, atk=1000), 8: self.unit(10305, iid=8, advance=1, atk=1)}, config, 7, max_rounds=1)
        self.assertEqual([d["p"] for d in report["b"]["a"][0]["e"] if isinstance(d.get("m"), dict)], [8])

    def test_extra_cast_is_bounded_and_does_not_spend_second_ap_budget(self):
        config = self.config_for(10201, 9000667, 9000657)
        with patch.object(battle.random.Random, "random", return_value=0):
            report = battle.simulate({2: self.unit(advance=2, initial_ap=4, speed=300)}, {2: self.unit(iid=1, hp=1000000)}, config, 7, max_rounds=1)
        casts = [a for a in report["b"]["a"] if a["s"].get("r") and a["s"].get("t") == "k"]
        self.assertEqual(len(casts), 3)
        self.assert_replays(report)

    def test_healing_shield_uses_separate_capacity_not_magic_cover(self):
        config = self.config_for(10610, 9000666)
        report = battle.simulate({2: self.unit(10610, advance=1, initial_ap=4, speed=300, atk=1000)}, {2: self.unit(iid=1, atk=100)}, config, 7, max_rounds=1)
        self.assertTrue(any(d.get("u") == {"u": "shield", "w": True} for a in report["b"]["a"] for d in a["e"]))
        self.assertEqual(report["endmeta"]["attack"]["2"]["cover_d"], 0)
        self.assertEqual(report["endmeta"]["attack"]["2"]["h"], 10000)
        self.assert_replays(report)

    def test_queen_passive_uses_actual_healers_superstrong_and_missing_hp_bonus(self):
        config = self.config_for(10595, 9999991, 9000360)
        report = battle.simulate({2: self.unit(10305, iid=1, hp=1000), 8: self.unit(10595, iid=8, advance=2, speed=1)},
                                 {2: self.unit(iid=2, atk=20000, speed=300)}, config, 7, max_rounds=1)
        heals = [d["m"]["m"] for a in report["b"]["a"] for d in a["e"] if d["r"] and d["p"] == 2 and isinstance(d.get("m"), dict) and d["m"]["m"] < 0]
        self.assertEqual(heals, [-5612])
        self.assert_replays(report)

    def test_real_superstrong_shape_is_supported_but_fake_or_unknown_rows_fail_closed(self):
        config = self.config_for(10201, 9999991)
        report = battle.simulate({2: self.unit(advance=1)}, {2: self.unit(iid=1)}, config, 7, max_rounds=1)
        self.assertEqual(report["meta"]["attack"]["g"]["10201"]["h"], 110000)
        config = {**config, "breakskill": {**config["breakskill"], "9999991": {**config["breakskill"]["9999991"], "type": 1}}}
        with self.assertRaisesRegex(ValueError, "9999991"):
            battle.simulate({2: self.unit(advance=1)}, {2: self.unit(iid=1)}, config, 7)


if __name__ == "__main__":
    unittest.main()
