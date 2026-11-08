"""太乙真人彩金突破 +13→+16：修复扣费前拒绝，并验证六技能真实战斗效果。"""

import copy
from itertools import product
import unittest

import test_soul
import test_hades_battle
import test_partner_growth
from zyj_server import battle, development, partner_growth, player, protocol


def setUpModule():
    test_soul.setUpModule()


class TaiyiBreakthroughTests(unittest.TestCase):
    """10832→164015 的 +13→+16 付费链、门槛、原子性与重连。"""

    request = test_soul.SoulTests.request
    add_account = test_soul.SoulTests.add_account
    success = test_soul.SoulTests.success
    reconnect = test_soul.SoulTests.reconnect
    refresh = test_soul.SoulTests.refresh
    grant = test_soul.SoulTests.grant
    props = test_soul.SoulTests.props
    gen = test_soul.SoulTests.gen
    assert_rejected = test_soul.SoulTests.assert_rejected
    put_hero = test_partner_growth.PartnerGrowthTests.put_hero
    paid = test_partner_growth.PartnerGrowthTests.paid

    def setUp(self):
        test_soul.SoulTests.setUp(self)
        self.iid = 2000900
        self.save["role_state"].update(level=150, coin=10**12, gold=1000000)

    def ready(self, cid=10832):
        raw = self.put_hero(cid, advance=13, awake=90)
        raw = protocol.pb_set_varint(raw, 23, 30)
        for field, value in partner_growth.fairy(raw, self.config).items():
            raw = protocol.pb_set_varint(raw, field, value)
        raw = partner_growth.power(self.save, self.gen(self.iid), raw)
        player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, raw))
        return raw

    def test_plus_13_conversion_no_longer_fails_combat_preparation(self):
        # 复现用户故障：原本「尚不支持该突破被动 9001070/9001071」在扣费前整体拒绝。
        self.ready()
        for choice, sid in ((1, 9001070), (3, 9001071)):
            with self.subTest(choice=choice):
                body = b"".join(protocol.encode_pb_field(1, 0, v) for v in (10832, choice, 13))
                result, costs, _ = development.prepare(1017, copy.deepcopy(self.save), body, self.config)
                self.assertTrue(costs)
                self.assertTrue(result)
                self.assertIn(sid, (9001070, 9001071))

    def test_all_eight_gold_choices_keep_gates_costs_and_reconnect(self):
        for choices in product((1, 3), repeat=3):
            with self.subTest(choices=choices):
                self.ready()
                self.assert_rejected(1017, values=[10832, choices[0], 13])
                for stage, choice in enumerate(choices, 14):
                    old = protocol.pb_get_varint(self.gen(self.iid), 1)
                    self.paid(1017, [old, choice, stage - 1])
                    self.assert_rejected(1017, values=[old, choice, stage - 1])
                hero = self.gen(self.iid)
                self.assertEqual([protocol.pb_get_varint(hero, f) for f in (1, 4, 35, 36, 37)],
                                 [164015, 16, *choices])
                self.assertIn((50, 2, b"preserve-partner"), list(protocol.iter_pb_fields(hero)))
                partner_growth.check_combat(hero, self.config)
                self.reconnect()
                self.refresh()
                self.assertEqual(self.gen(self.iid), hero)

    def test_second_gold_chain_174013_uses_same_six_skills(self):
        # 170024→174013 是太乙另一条彩金转换链，技能行相同，同样不能扣费前拒绝。
        row = self.config["general"]["174013"]
        self.assertEqual([row[f"gold{i}_will_skills_{c}"] for i in (1, 2, 3) for c in (1, 3)],
                         [9001070, 9001071, 9001072, 9001073, 9001074, 9001075])
        for pid in range(9001070, 9001076):
            self.assertIn(self.config["breakskill"][str(pid)]["type_param"], battle.PARTNER_EFFECTS)

    def test_other_unimplemented_gold_partners_still_rejected_before_charge(self):
        # 轩辕黄帝 164047 的 9001281/9001282 效果号 9000925/9000926 不在白名单。
        row = self.config["general"]["164047"]
        sid = row["gold1_will_skills_1"]
        self.assertNotIn(self.config["breakskill"][str(sid)]["type_param"], battle.PARTNER_EFFECTS)
        teams = {True: {2: {"cid": 164047, "iid": 700, "level": 10, "advance": 14, "atk": 100,
                            "def": 0, "hp": 10000, "speed": 100, "initial_ap": 0,
                            "skill": row["skillid"], "partner_skills": [sid]}},
                 False: {2: {"cid": 10201, "iid": 1, "level": 10, "advance": 0, "atk": 100,
                             "def": 0, "hp": 10000, "speed": 100, "initial_ap": 0,
                             "skill": self.config["general"]["10201"]["skillid"]}}}
        with self.assertRaisesRegex(ValueError, "尚不支持该突破被动"):
            battle._prepare_teams(teams, self.config)


class TaiyiBattleTests(unittest.TestCase):
    """六技能：后援机型/前线机型/过量补给/精准支援/强心剂+/纳米科技。"""

    unit = test_hades_battle.HadesBattleTests.unit
    hits = test_hades_battle.HadesBattleTests.hits
    assert_replays = test_hades_battle.HadesBattleTests.assert_replays

    @classmethod
    def setUpClass(cls):
        cls.config = player.load_role_config("configs_sec5.zip")

    def isolated(self, *patches, combos=None, skills=None):
        row = {**self.config["general"]["164015"], **{f"break{i}": 0 for i in range(1, 17)}}
        breakskill = dict(self.config["breakskill"])
        for sid, values in patches:
            breakskill[str(sid)] = {**breakskill[str(sid)], **values}
        config = {**self.config, "general": {**self.config["general"], "164015": row},
                  "breakskill": breakskill}
        if combos:
            table = dict(self.config["combskillprobability"])
            for cid, values in combos.items():
                table[str(cid)] = {**table[str(cid)], **values}
            config["combskillprobability"] = table
        if skills:
            table = dict(self.config["skill"])
            for sid, values in skills.items():
                table[str(sid)] = {**table[str(sid)], **values}
            config["skill"] = table
        return config

    def gold(self, *pids, **values):
        return self.unit(164015, iid=700, advance=16, partner_skills=list(pids), **values)

    def events(self, report, kind=None):
        return [a for a in report["b"]["a"] if a["s"].get("t") == kind] if kind else report["b"]["a"]

    def heal_destinations(self, report, pos=2):
        return [d for a in report["b"]["a"] if a["s"].get("r") is True and a["s"].get("p") == [pos]
                for d in a["e"] if d["r"] is True and isinstance(d.get("m"), dict)]

    def heals(self, report):
        return [-d["m"]["m"] for a in report["b"]["a"] for d in a["e"]
                if isinstance(d.get("m"), dict) and d["m"]["m"] < 0]

    def test_all_six_gold_skills_pass_combat_preparation_and_replay(self):
        for pid in range(9001070, 9001076):
            with self.subTest(pid=pid):
                report = battle.simulate({2: self.gold(pid, speed=300, initial_ap=4)},
                                         {2: self.unit(iid=1, hp=1000000, atk=1)},
                                         self.isolated(), 7, max_rounds=2)
                self.assertTrue(report["b"]["a"])
                self.assert_replays(report)

    def test_aura_adds_32000_defense_only_to_gold_allies_and_stacks(self):
        for pids, expected in (((9001074,), 32000), ((9001075,), 32000),
                               ((9001074, 9001075), 64000)):
            with self.subTest(pids=pids):
                teams = {True: {2: self.gold(*pids), 8: self.unit(164015, iid=701, speed=1),
                                10: self.unit(10201, iid=702, speed=1)},
                         False: {2: self.unit(iid=1, atk=1)}}
                battle._prepare_teams(teams, self.isolated())
                self.assertEqual(teams[True][2]["def"], expected)
                self.assertEqual(teams[True][8]["def"], expected)
                self.assertEqual(teams[True][10]["def"], 0)

    def test_back_row_personal_skill_gains_one_more_target(self):
        # 太乙治疗技 180042 为 gain/random/3；后排 pos=8 时后援机型多选 1 个友方。
        def fight(pid=None):
            attack = {2: self.unit(164015, iid=701, speed=1),
                      8: self.gold(*([pid] if pid else []), speed=300, initial_ap=4, atk=10),
                      10: self.unit(164015, iid=702, speed=1),
                      12: self.unit(164015, iid=703, speed=1)}
            return battle.simulate(attack, {2: self.unit(iid=1, hp=1000000, atk=1)},
                                   self.isolated(), 7, max_rounds=1)
        plain, boosted = fight(), fight(9001070)
        self.assertEqual(len(self.heal_destinations(plain, 8)), 3)
        self.assertEqual(len(self.heal_destinations(boosted, 8)), 4)
        front = battle.simulate({2: self.gold(9001070, speed=300, initial_ap=4, atk=10),
                                 8: self.unit(164015, iid=701, speed=1),
                                 10: self.unit(164015, iid=702, speed=1),
                                 12: self.unit(164015, iid=703, speed=1)},
                                {2: self.unit(iid=1, hp=1000000, atk=1)}, self.isolated(), 7, max_rounds=1)
        self.assertEqual(len(self.heal_destinations(front, 2)), 3)
        for report in (plain, boosted, front):
            self.assert_replays(report)

    def test_front_line_mode_heals_ten_percent_more(self):
        def fight(pid=None):
            attack = {2: self.gold(*([pid] if pid else []), speed=300, initial_ap=4, atk=10)}
            defense = {2: self.unit(iid=1, hp=1000000, atk=100, speed=500)}
            return battle.simulate(attack, defense, self.isolated(), 7, max_rounds=1)
        plain, boosted = fight(), fight(9001071)
        # 个人技治疗量 int(12 × 1.1) = 13，合体技不享受该加成。
        self.assertEqual(self.heals(boosted)[0], int(self.heals(plain)[0] * 1.1))
        self.assertEqual(boosted["endmeta"]["attack"]["2"]["h"] - plain["endmeta"]["attack"]["2"]["h"], 1)
        for report in (plain, boosted):
            self.assert_replays(report)

    def test_front_line_mode_blocks_front_row_combo_and_halves_back_row_chance(self):
        # 12988 需要 10608/10609/10610 三身份；把 bout1 概率固定为 1 观察发动情况。
        config = self.isolated(combos={12988: {"bout1": 1}})
        def fight(pids, back, seed=7):
            actor = self.gold(*pids, speed=300, initial_ap=4)
            attack = ({2: self.unit(10608, iid=701, speed=1),
                       8: self.unit(10609, iid=702, speed=1),
                       10: actor} if back else
                      {2: actor, 8: self.unit(10609, iid=702, speed=1),
                       10: self.unit(10608, iid=701, speed=1)})
            return battle.simulate(attack, {2: self.unit(iid=1, hp=1000000, atk=1),
                                            8: self.unit(iid=2, hp=1000000, atk=1)},
                                   config, seed, max_rounds=1)
        def combined(report):
            return any(a["s"].get("t") == "x" for a in report["b"]["a"])
        for seed in range(20):
            with self.subTest(seed=seed):
                self.assertTrue(combined(fight((), False, seed)))
                self.assertFalse(combined(fight((9001071,), False, seed)))
        # 后排不禁合体，但概率按本地规则由 1.0 折半为 0.5。
        fired = sum(combined(fight((9001071,), True, seed)) for seed in range(20))
        self.assertTrue(0 < fired < 20, fired)

    def test_over_supply_grants_two_ap_when_crossing_four_without_chaining(self):
        # 技能 ap_give=4，放完归 0 后经 change_ap 回到 4，触发过量补给给最低怒队友 +2。
        config = self.isolated(skills={180042: {"ap_give": 4}})
        def fight(pid=None):
            attack = {2: self.gold(*([pid] if pid else []), speed=300, initial_ap=4, atk=10),
                      8: self.unit(164015, iid=701, speed=1, initial_ap=0)}
            return battle.simulate(attack, {2: self.unit(iid=1, hp=1000000, atk=1)},
                                   config, 7, max_rounds=1)
        plain, supplied = fight(), fight(9001072)
        # 队友怒气 0 → 2（补给 value2）→ 4（自己普攻），比对照组恰好多 2 点且不连锁。
        self.assertEqual(supplied["endmeta"]["attack"]["8"]["ap"] - plain["endmeta"]["attack"]["8"]["ap"], 2)
        for report in (plain, supplied):
            self.assert_replays(report)

    def test_precise_support_drains_in_pvp_and_restores_in_pve_once_per_round(self):
        def ap_values(report, direct, pos):
            return [d["ap"] for a in report["b"]["a"] for d in a["e"]
                    if d["r"] == direct and d["p"] == pos and "ap" in d]
        def fight(pid=None, *, pve=False):
            attack = {2: self.gold(*([pid] if pid else []), speed=300, atk=100),
                      8: self.unit(164015, iid=701, speed=1, initial_ap=0)}
            defense = {2: self.unit(iid=1, hp=1000000, atk=1, speed=1, initial_ap=5,
                                    **({"npc": True} if pve else {}))}
            return battle.simulate(attack, defense, self.isolated(), 7, max_rounds=1)
        plain, drained = fight(), fight(9001073)
        # 敌方怒气最高者 5 → 3；PVE 不降怒，改为把己方最低怒的其他角色恢复到 4。
        self.assertNotIn(3, ap_values(plain, False, 2))
        self.assertIn(3, ap_values(drained, False, 2))
        pve_plain, pve = fight(pve=True), fight(9001073, pve=True)
        self.assertNotIn(3, ap_values(pve, False, 2))
        self.assertNotIn(4, ap_values(pve_plain, True, 8))
        self.assertIn(4, ap_values(pve, True, 8))
        for report in (plain, drained, pve_plain, pve):
            self.assert_replays(report)

    def test_heart_tonic_adds_flat_damage_from_largest_single_heal(self):
        # 敌先手打 pos2 的非彩金友方，太乙随后治疗它，该友方普攻享固定增伤。
        config = self.isolated()
        def fight(pid=None):
            attack = {2: self.unit(10201, iid=702, speed=200, atk=100),
                      8: self.gold(*([pid] if pid else []), speed=300, initial_ap=4, atk=100)}
            return battle.simulate(attack, {2: self.unit(iid=1, hp=1000000, atk=100, speed=500)},
                                   config, 7, max_rounds=1)
        plain, boosted = fight(), fight(9001074)
        # 增伤 = 最大单次恢复量 ÷ (敌方存活数 1 + value 2) = 100 // 3 = 33。
        heal = max(self.heals(boosted))
        self.assertEqual(self.hits(boosted, pos=2)[0] - self.hits(plain, pos=2)[0], heal // 3)
        for report in (plain, boosted):
            self.assert_replays(report)

    def test_nanotech_swaps_hp_with_pve_cap_and_never_ghosts_recovery(self):
        def fight(pid=None, *, cap=20):
            patches = ((9001075, {"value": cap}),) if pid else ()
            attack = {2: self.gold(*([pid] if pid else []), speed=300, initial_ap=4, atk=10)}
            return battle.simulate(attack, {2: self.unit(iid=1, hp=1000000, atk=1, speed=1, npc=True)},
                                   self.isolated(*patches), 7, max_rounds=1)
        plain, swapped = fight(), fight(9001075)
        self.assertGreater(plain["endmeta"]["defense"]["2"]["h"] - swapped["endmeta"]["defense"]["2"]["h"], 0)
        # PVE 减少量 = min(gap, 太乙生命上限 × 20)；太乙已回满，上限为 200000。
        self.assertEqual(plain["endmeta"]["defense"]["2"]["h"] - swapped["endmeta"]["defense"]["2"]["h"], 200000)
        self.assertLessEqual(swapped["endmeta"]["attack"]["2"]["h"], swapped["meta"]["attack"]["g"]["700"]["j"])
        for report in (plain, swapped):
            self.assert_replays(report)
