"""关羽／燃脂大乔／王母娘娘彩金突破 +13→+16 与十六个技能的战斗效果。

三个伙伴的 164xxx 与 174xxx 链复用同一组技能行，本批只实现一份；
每行只有两个有效选择（关羽 1/3、大乔 2/3、王母 1/2），第三个为 0。
"""

import copy
from fractions import Fraction
from itertools import product
import unittest

import test_soul
import test_hades_battle
import test_partner_growth
from zyj_server import battle, development, partner_growth, player, protocol


def setUpModule():
    test_soul.setUpModule()


class GoldBreakthroughTests(unittest.TestCase):
    """三条 +13→+16 付费链、门槛、原子性、重连与白名单边界。"""

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

    # (基础 CID, 彩金 CID, 每行有效选择)
    CHAINS = {"关羽": (10825, 164001, (1, 3)),
              "燃脂大乔": (10834, 164002, (2, 3)),
              "王母娘娘": (10817, 164003, (1, 2))}

    def setUp(self):
        test_soul.SoulTests.setUp(self)
        self.iid = 2000900
        self.save["role_state"].update(level=150, coin=10**12, gold=1000000)

    def ready(self, base):
        raw = self.put_hero(base, advance=13, awake=90)
        raw = protocol.pb_set_varint(raw, 23, 30)
        for field, value in partner_growth.fairy(raw, self.config).items():
            raw = protocol.pb_set_varint(raw, field, value)
        raw = partner_growth.power(self.save, self.gen(self.iid), raw)
        player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, raw))
        return raw

    def test_plus_13_conversion_no_longer_fails_combat_preparation(self):
        # 修复前：+13→+14 转彩金时，扣费前被 check_combat 以「尚不支持该突破被动」整体拒绝。
        for name, (base, _, choices) in self.CHAINS.items():
            for choice in choices:
                with self.subTest(name=name, choice=choice):
                    self.ready(base)
                    body = b"".join(protocol.encode_pb_field(1, 0, v) for v in (base, choice, 13))
                    result, costs, _ = development.prepare(
                        1017, copy.deepcopy(self.save), body, self.config)
                    self.assertTrue(costs)
                    self.assertTrue(result)

    def test_all_gold_choices_keep_gates_costs_and_reconnect(self):
        for name, (base, gold_cid, choices) in self.CHAINS.items():
            for picks in product(choices, repeat=3):
                with self.subTest(name=name, picks=picks):
                    self.ready(base)
                    self.assert_rejected(1017, values=[base, picks[0], 13])
                    for stage, choice in enumerate(picks, 14):
                        old = protocol.pb_get_varint(self.gen(self.iid), 1)
                        self.paid(1017, [old, choice, stage - 1])
                        self.assert_rejected(1017, values=[old, choice, stage - 1])
                    hero = self.gen(self.iid)
                    self.assertEqual(
                        [protocol.pb_get_varint(hero, f) for f in (1, 4, 35, 36, 37)],
                        [gold_cid, 16, *picks])
                    self.assertIn((50, 2, b"preserve-partner"), list(protocol.iter_pb_fields(hero)))
                    partner_growth.check_combat(hero, self.config)
                    self.reconnect()
                    self.refresh()
                    self.assertEqual(self.gen(self.iid), hero)

    def test_all_sixteen_effect_codes_are_whitelisted(self):
        for cid, sids in (("164001", range(9001010, 9001016)),
                          ("164002", range(9001016, 9001022)),
                          ("164003", range(9001028, 9001034))):
            with self.subTest(cid=cid):
                row = self.config["general"][cid]
                for sid in sids:
                    br = self.config["breakskill"][str(sid)]
                    if br["type"] == 0:
                        continue  # 弑神战刃是普通属性行，走属性分支不需要效果号白名单。
                    code = br["type_param"] or br["id"]
                    self.assertIn(code, battle.PARTNER_EFFECTS | battle.HADES_EFFECTS
                                  | battle.LEAD_GOLD_EFFECTS | {9000528})

    def test_second_gold_chains_use_the_same_skill_rows(self):
        for first, second in (("164001", "174001"), ("164002", "174005"),
                              ("164002", "174011"), ("164003", "174018")):
            with self.subTest(chain=(first, second)):
                for stage in (1, 2, 3):
                    for choice in (1, 2, 3):
                        key = f"gold{stage}_will_skills_{choice}"
                        self.assertEqual(self.config["general"][first][key],
                                         self.config["general"][second][key])

    def test_wangmu_uses_narrow_no_skill_combat_exception(self):
        # 王母彩金形态 skillid=0；例外只覆盖这两个 CID，不放宽其它无技能武将。
        self.assertEqual(battle.QUEEN_GOLD, (164003, 174018))
        for cid in ("164003", "174018"):
            self.assertNotIn(str(self.config["general"][cid]["skillid"]), self.config["skill"])
        for cid in ("164001", "164002"):
            self.assertIn(str(self.config["general"][cid]["skillid"]), self.config["skill"])
        raw = self.put_hero(164003, advance=16, awake=90)
        for stage, choice in enumerate((1, 1, 1), 35):
            raw = protocol.pb_set_varint(raw, stage, choice)
        packed = 111
        raw = protocol.pb_set_varint(raw, 40,
                                     self.config["jinjiangkezhiguanxi"][str(packed)]["camp"])
        partner_growth.check_combat(raw, self.config)

    def test_other_unimplemented_gold_partners_still_rejected_before_charge(self):
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


class GoldBattleTests(unittest.TestCase):
    """十六个技能的战前校验与确定性战斗数值。"""

    unit = test_hades_battle.HadesBattleTests.unit
    assert_replays = test_hades_battle.HadesBattleTests.assert_replays

    @classmethod
    def setUpClass(cls):
        cls.config = player.load_role_config("configs_sec5.zip")

    def isolated(self, cid, *patches, combos=None, skills=None, extra=None, comboskill=None):
        general = {**self.config["general"],
                   str(cid): {**self.config["general"][str(cid)],
                              **{f"break{i}": 0 for i in range(1, 17)}}}
        for other, values in (extra or {}).items():
            general[str(other)] = {**general[str(other)], **values}
        breakskill = dict(self.config["breakskill"])
        for sid, values in patches:
            breakskill[str(sid)] = {**breakskill[str(sid)], **values}
        config = {**self.config, "general": general, "breakskill": breakskill}
        if combos:
            table = dict(self.config["combskillprobability"])
            for sid, values in combos.items():
                table[str(sid)] = {**table[str(sid)], **values}
            config["combskillprobability"] = table
        if comboskill:
            table = dict(self.config["combskill"])
            for sid, values in comboskill.items():
                table[str(sid)] = {**table[str(sid)], **values}
            config["combskill"] = table
        if skills:
            table = dict(self.config["skill"])
            for sid, values in skills.items():
                table[str(sid)] = {**table[str(sid)], **values}
            config["skill"] = table
        return config

    def gold(self, cid, *pids, **values):
        return self.unit(cid, iid=values.pop("iid", 700), advance=16,
                         partner_skills=list(pids), **values)

    def enemy(self, **values):
        defaults = {"iid": 1, "hp": 100000, "atk": 100, "speed": 1, "initial_ap": 4}
        defaults.update(values)
        return {2: self.unit(**defaults)}

    def incoming(self, report):
        return [x["m"]["m"] for action in report["b"]["a"] for x in action["e"]
                if x["r"] is True and isinstance(x.get("m"), dict) and x["m"]["m"] > 0]

    def dealt(self, report):
        return [x["m"]["m"] for action in report["b"]["a"] for x in action["e"]
                if x["r"] is False and isinstance(x.get("m"), dict) and x["m"]["m"] > 0]

    def combos(self, report):
        return [action["s"].get("S") for action in report["b"]["a"]
                if action["s"].get("t") == "x"]

    def breaks(self, report, sid):
        return [action for action in report["b"]["a"] if action["s"].get("S") == sid]

    def test_auras_use_real_config_values_and_do_not_stack(self):
        # 描述 200000 仙攻／2400000 仙命，按既有 0.1 折算取 value2；同英雄两种选择共用一份。
        for cid, pids, attr, expected in (
                (164001, (9001014,), "atk", 20100), (164001, (9001015,), "atk", 20100),
                (164001, (9001014, 9001015), "atk", 20100),
                (164002, (9001020,), "atk", 20100), (164002, (9001021,), "atk", 20100),
                (164002, (9001020, 9001021), "atk", 20100),
                (164003, (9001032,), "hp", 250000), (164003, (9001033,), "hp", 250000),
                (164003, (9001032, 9001033), "hp", 250000)):
            with self.subTest(cid=cid, pids=pids):
                teams = {True: {2: self.gold(cid, *pids)}, False: {2: self.unit(iid=1)}}
                battle._prepare_teams(teams, self.isolated(cid))
                self.assertEqual(teams[True][2][attr], expected)

    def test_jianding_fengcai_adds_damage_and_last_stand_reduction(self):
        # 坚定风采：伤害 +30%（out_multiplier），己方仅剩自己时受伤减少 50%。
        for pids, multiplier in (((), 1), ((9001011,), Fraction(13, 10))):
            teams = {True: {2: self.gold(164001, *pids)}, False: {2: self.unit(iid=1)}}
            battle._prepare_teams(teams, self.isolated(164001))
            self.assertEqual(teams[True][2]["out_multiplier"], multiplier)
        damages = []
        for pids in ((), (9001011,)):
            report = battle.simulate(
                {2: self.gold(164001, *pids, iid=700, speed=1, atk=10)},
                self.enemy(speed=300), self.isolated(164001), 7, max_rounds=1)
            damages.append(self.incoming(report)[0])
            self.assert_replays(report)
        # 无技能 200；带技能时孤独减伤 50% -> 100。
        self.assertEqual(damages, [200, 100])

    def test_shenli_baozhang_adds_ramp_each_round(self):
        # 神力暴涨每回合 +20% 伤害；对照「不带该技能」的同场战斗，第二回合伤害应更高。
        config = self.isolated(164001)
        totals = []
        for pids in ((), (9001013,)):
            report = battle.simulate(
                {2: self.gold(164001, *pids, iid=700, speed=300, atk=100, initial_ap=0)},
                self.enemy(speed=1, hp=10**9), config, 7, max_rounds=3)
            totals.append(sum(self.dealt(report)))
            self.assert_replays(report)
        self.assertGreater(totals[1], totals[0])
        self.assertEqual(totals[1] - totals[0] > 0, True)

    def test_tianlong_shenzi_grants_opening_immunity(self):
        for pids, expected in (((), 0), ((9001014,), 2)):
            teams = {True: {2: self.gold(164001, *pids)}, False: {2: self.unit(iid=1)}}
            battle._prepare_teams(teams, self.isolated(164001))
            self.assertEqual(teams[True][2]["states"].get("statusproof", 0), expected)

    def test_longren_luanwu_keeps_existing_personal_skill_target_bonus(self):
        # 9000528 既有实现（个人技能目标 +1）不能被新光环分支覆盖。
        row = self.config["breakskill"]["9001015"]
        self.assertEqual(row["type_param"], 9000528)
        self.assertIn(9000528, battle.PARTNER_EFFECTS)
        teams = {True: {2: self.gold(164001, 9001015)}, False: {2: self.unit(iid=1)}}
        battle._prepare_teams(teams, self.isolated(164001))
        self.assertEqual(teams[True][2]["effects"][9000528]["value"], 1)

    def test_shenlong_duanhun_sets_richest_enemy_to_100_hp_once(self):
        config = self.isolated(164001)
        attack = {2: self.gold(164001, 9001010, iid=700, speed=1, hp=1)}
        defense = self.enemy(speed=300, atk=100000, hp=100000)
        report = battle.simulate(attack, defense, config, 7, max_rounds=2)
        events = self.breaks(report, 9001010)
        self.assertEqual(len(events), 1)
        self.assertEqual(events[0]["e"][0]["m"]["m"], 99900)
        self.assert_replays(report)

    def test_lala_duiyuan_boosts_male_allies_defense(self):
        # 己方男性防御 +30%（主角不受影响）；女性队友不享受。
        config = self.isolated(164002)
        for ally_cid, expected in ((10615, 1000), (10404, 1300)):
            with self.subTest(ally=ally_cid):
                teams = {True: {2: self.gold(164002, 9001018, iid=700, **{"def": 1000}),
                                8: self.unit(ally_cid, iid=701, **{"def": 1000})},
                         False: {2: self.unit(iid=1)}}
                battle._prepare_teams(teams, config)
                self.assertEqual(teams[True][8]["def"], expected)

    def test_ni_zhaohuo_la_reduces_damage_from_burning_attacker(self):
        config = self.isolated(164002)
        damages = []
        for pids, firing in (((), None), ((9001019,), None),
                             ((), [10, 3]), ((9001019,), [10, 3])):
            report = battle.simulate(
                {2: self.gold(164002, *pids, iid=700, speed=1, atk=10)},
                self.enemy(speed=300, firing=firing), config, 7, max_rounds=1)
            damages.append(self.incoming(report)[0])
            self.assert_replays(report)
        self.assertEqual(damages, [200, 200, 200, 100])

    def test_chaojie_lingwu_boosts_wu_damage_in_first_two_rounds(self):
        config = self.isolated(164002)
        totals = []
        for pids in ((), (9001021,)):
            report = battle.simulate(
                {2: self.gold(164002, *pids, iid=700, speed=300, atk=100, initial_ap=0)},
                self.enemy(speed=1, hp=10**9), config, 7, max_rounds=2)
            totals.append(sum(self.dealt(report)))
            self.assert_replays(report)
        self.assertGreater(totals[1], totals[0])

    def test_zhinan_kuaipao_raises_combo_chance_per_male_enemy(self):
        # 13017 需要同队燃脂小乔 10615；seed 7 首个随机数 0.3238：0.35 发动，
        # 降到 0.30 不发动，再加一名男性敌人的 +0.08 又发动。
        config = self.isolated(164002, combos={13017: {"bout1": 0.30}})
        attack = lambda: {2: self.gold(164002, 9001017, iid=700, speed=300, initial_ap=4),
                          8: self.unit(10615, iid=701, speed=1)}
        for males, expected in ((0, []), (1, [13017])):
            defense = {2: self.unit(iid=1, cid=10404, hp=100000, atk=10, speed=1)}
            if not males:
                defense[2]["cid"] = 10615  # 女性敌人，不加概率
            report = battle.simulate(attack(), defense, config, 7, max_rounds=1)
            self.assertEqual(self.combos(report), expected)
            self.assert_replays(report)

    def test_nuhuo_liaoyuan_forces_combo_at_high_ap(self):
        config = self.isolated(164003, combos={12943: {"bout1": 0}})
        attack = lambda pids, ap: {2: self.gold(164003, *pids, iid=700, speed=300, initial_ap=ap),
                                   8: self.unit(10596, iid=701, speed=1)}
        for pids, ap, expected in (((), 6, []), ((9001033,), 4, []), ((9001033,), 6, [12943])):
            with self.subTest(pids=pids, ap=ap):
                report = battle.simulate(
                    attack(pids, ap), self.enemy(speed=1), config, 7, max_rounds=1)
                self.assertEqual(self.combos(report), expected)
                self.assert_replays(report)

    def test_zhuyu_zhufu_adds_hp_to_whole_team(self):
        for pids, expected in (((), 10000), ((9001030,), 11500)):
            teams = {True: {2: self.gold(164003, *pids, iid=700),
                            8: self.unit(iid=701)}, False: {2: self.unit(iid=1)}}
            battle._prepare_teams(teams, self.isolated(164003))
            self.assertEqual(teams[True][8]["hp"], expected)

    def test_wangmu_liansheng_heals_lowest_ally_by_hit_count(self):
        config = self.isolated(164003)
        for pids, expected in (((), None), ((9001028,), -200)):
            attack = {2: self.gold(164003, *pids, iid=700, speed=200, atk=10),
                      8: self.unit(iid=701, speed=1)}
            report = battle.simulate(attack, self.enemy(speed=300), config, 7, max_rounds=1)
            heals = [x["m"]["m"] for action in report["b"]["a"] for x in action["e"]
                     if x["r"] is True and isinstance(x.get("m"), dict) and x["m"]["m"] < 0]
            if expected is None:
                self.assertEqual(heals, [])
            else:
                self.assertIn(expected, heals)
            self.assert_replays(report)

    def test_niepan_xinghuo_shield_converts_one_hit_to_proof(self):
        config = self.isolated(164003)
        damages = []
        for shield in (0, 2):
            report = battle.simulate(
                {2: self.gold(164003, 9001029, iid=700, speed=1, atk=10, phoenix_shield=shield)},
                self.enemy(speed=300), config, 7, max_rounds=1)
            damages.append(self.incoming(report))
            self.assert_replays(report)
        self.assertEqual(damages[0], [200])
        self.assertEqual(damages[1], [])

    def test_fenghuang_yuyi_reduces_damage_by_lost_hp(self):
        # 去掉 +240000 生命光环后，只看「已损失生命每 10% 减伤 20%（上限 60%）」：
        # 满血首次受击不减伤，第二击按当时血量触发 60% 上限。
        config = self.isolated(164003, (9001032, {"value2": 0}))
        damages = []
        for pids in ((), (9001032,)):
            report = battle.simulate(
                {2: self.gold(164003, *pids, iid=700, speed=1, atk=10, hp=10000)},
                self.enemy(speed=300, atk=2500), config, 7, max_rounds=2)
            damages.append(self.incoming(report))
            self.assert_replays(report)
        self.assertEqual(damages, [[5000, 2500], [5000, 1000]])

    def test_kuangre_yizhi_cleanses_one_negative_state(self):
        config = self.isolated(164003)
        for pids in ((), (9001031,)):
            attack = {2: self.gold(164003, *pids, iid=700, speed=1, atk=10),
                      8: self.unit(iid=701, speed=1, states={"skilllock": 99})}
            report = battle.simulate(attack, self.enemy(speed=300), config, 7, max_rounds=1)
            cleared = [x for action in report["b"]["a"] for x in action["e"]
                       if x.get("u") == {"u": "skilllock", "w": False}]
            self.assertEqual(len(cleared), 1 if pids else 0)
            self.assert_replays(report)

    def test_show_time_cleanses_control_and_queues_free_skill(self):
        config = self.isolated(164002, (9001016, {"value": 1}))
        # 己方吴国角色（10615 燃脂小乔）死亡时，携带者解封并排队一次免费个人技。
        # 阵位 2 放濒死的吴国队友，敌方先手击杀它；携带者在阵位 8 被解封并补发免费技能。
        attack = {2: self.unit(10615, iid=701, speed=1, hp=1),
                  8: self.gold(164002, 9001016, iid=700, speed=1,
                               states={"skilllock": 99})}
        defense = self.enemy(speed=400, atk=100000)
        report = battle.simulate(attack, defense, config, 7, max_rounds=1)
        self.assertTrue(any(x.get("u") == {"u": "skilllock", "w": False}
                            for action in report["b"]["a"] for x in action["e"]))
        self.assert_replays(report)

    def test_gailiang_huaban_adds_extra_personal_attacks(self):
        # 把个人技改成全体范围，让 4 名残血敌人阵亡、仍留 1 名存活敌人；
        # dead>=2 时改良滑板按描述补 3 次不耗怒的额外个人技。
        sid = self.config["general"]["164002"]["skillid"]
        config = self.isolated(164002, (9001020, {"value2": 0}),
                               skills={sid: {"range": "all"}})
        counts = []
        for pids in ((), (9001020,)):
            attack = {2: self.gold(164002, *pids, iid=700, speed=300, atk=10, initial_ap=4)}
            defense = {p: self.unit(iid=p, hp=1, atk=1, speed=1)
                       for p in (2, 4, 6, 8, 10)}
            defense[10]["hp"] = 10**9
            report = battle.simulate(attack, defense, config, 7, max_rounds=1)
            counts.append(len(self.dealt(report)))
            self.assert_replays(report)
        self.assertGreater(counts[1], counts[0])
