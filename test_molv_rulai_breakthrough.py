"""魔吕布／如来彩金突破 +13→+16 与十二技能战斗效果；元始天尊既有链路回归锁定。

元始天尊（10598→10829→164004）在 2026-11-07 批次已完整接通，本批不改它的代码，
只把它的六效果号与三阶八种组合作为回归锁定，避免新白名单意外放宽或覆盖旧实现。
"""

import copy
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

    CHAINS = {"魔吕布": (10827, 164006), "元始天尊": (10829, 164004), "如来": (10828, 164016)}

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
        # 复现用户故障：魔吕布/如来原本在 +13 点突破转彩金 +14 时、扣费前被整体拒绝。
        for name, (base, _) in self.CHAINS.items():
            for choice in (1, 3):
                with self.subTest(name=name, choice=choice):
                    self.ready(base)
                    body = b"".join(protocol.encode_pb_field(1, 0, v) for v in (base, choice, 13))
                    result, costs, _ = development.prepare(
                        1017, copy.deepcopy(self.save), body, self.config)
                    self.assertTrue(costs)
                    self.assertTrue(result)

    def test_all_eight_gold_choices_keep_gates_costs_and_reconnect(self):
        for name, (base, gold_cid) in self.CHAINS.items():
            for choices in product((1, 3), repeat=3):
                with self.subTest(name=name, choices=choices):
                    self.ready(base)
                    self.assert_rejected(1017, values=[base, choices[0], 13])
                    for stage, choice in enumerate(choices, 14):
                        old = protocol.pb_get_varint(self.gen(self.iid), 1)
                        self.paid(1017, [old, choice, stage - 1])
                        self.assert_rejected(1017, values=[old, choice, stage - 1])
                    hero = self.gen(self.iid)
                    self.assertEqual(
                        [protocol.pb_get_varint(hero, f) for f in (1, 4, 35, 36, 37)],
                        [gold_cid, 16, *choices])
                    self.assertIn((50, 2, b"preserve-partner"), list(protocol.iter_pb_fields(hero)))
                    partner_growth.check_combat(hero, self.config)
                    self.reconnect()
                    self.refresh()
                    self.assertEqual(self.gen(self.iid), hero)

    def test_yuanshi_existing_chain_stays_implemented_without_new_code(self):
        # 元始天尊是 11-07 批次的既有实现，本批只锁定：六个效果号与三阶八种组合仍可用。
        row = self.config["general"]["164004"]
        sids = [row[f"gold{i}_will_skills_{c}"] for i in (1, 2, 3) for c in (1, 3)]
        self.assertEqual(sids, list(range(9001034, 9001040)))
        for sid in sids:
            self.assertIn(self.config["breakskill"][str(sid)]["type_param"], battle.PARTNER_EFFECTS)
        for choices in product((1, 3), repeat=3):
            with self.subTest(choices=choices):
                raw = self.put_hero(164004, advance=16, awake=90)
                for stage, choice in enumerate(choices, 35):
                    raw = protocol.pb_set_varint(raw, stage, choice)
                packed = sum((protocol.pb_get_varint(raw, 35 + i) or 0) * 10 ** (2 - i)
                             for i in range(3))
                raw = protocol.pb_set_varint(
                    raw, 40, self.config["jinjiangkezhiguanxi"][str(packed)]["camp"])
                partner_growth.check_combat(raw, self.config)

    def test_all_twelve_effect_codes_are_whitelisted(self):
        for cid, sids in (("164006", range(9001058, 9001064)),
                          ("164016", range(9001076, 9001082))):
            with self.subTest(cid=cid):
                row = self.config["general"][cid]
                for stage in (1, 2, 3):
                    for choice in (1, 3):
                        self.assertIn(row[f"gold{stage}_will_skills_{choice}"], sids)
                for sid in sids:
                    code = self.config["breakskill"][str(sid)]["type_param"]
                    self.assertIn(code, battle.PARTNER_EFFECTS | battle.HADES_EFFECTS)

    def test_second_gold_chains_use_the_same_skill_rows(self):
        for first, second in (("164006", "174003"), ("164004", "174002"), ("164004", "174028")):
            with self.subTest(chain=(first, second)):
                for stage in (1, 2, 3):
                    for choice in (1, 3):
                        key = f"gold{stage}_will_skills_{choice}"
                        self.assertEqual(self.config["general"][first][key],
                                         self.config["general"][second][key])

    def test_other_unimplemented_gold_partners_still_rejected_before_charge(self):
        # 轩辕黄帝 164047 的效果号仍在白名单外；新白名单不能放宽为「全英雄彩金」。
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
    """十二技能各自的战前校验与确定性战斗数值。"""

    unit = test_hades_battle.HadesBattleTests.unit
    hits = test_hades_battle.HadesBattleTests.hits
    assert_replays = test_hades_battle.HadesBattleTests.assert_replays

    @classmethod
    def setUpClass(cls):
        cls.config = player.load_role_config("configs_sec5.zip")

    def isolated(self, cid, *patches, combos=None, skills=None, extra=None):
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

    def seals(self, report, enabled=True):
        return [x for action in report["b"]["a"] for x in action["e"]
                if x.get("u") == {"u": "skilllock", "w": enabled}]

    def incoming(self, report):
        return [x["m"]["m"] for action in report["b"]["a"] for x in action["e"]
                if x["r"] is True and isinstance(x.get("m"), dict) and x["m"]["m"] > 0]

    def combos(self, report):
        return [action["s"].get("S") for action in report["b"]["a"]
                if action["s"].get("t") == "x"]

    def test_aura_stats_use_real_config_values_and_do_not_stack(self):
        # 描述 400000 仙攻／320000 仙防，按既有 0.1 折算取 value2；同英雄两种选择共用一份。
        for cid, pids, attr, expected in (
                (164006, (9001062,), "atk", 40100),
                (164006, (9001063,), "atk", 40100),
                (164006, (9001062, 9001063), "atk", 40100),
                (164016, (9001080,), "def", 32000),
                (164016, (9001081,), "def", 32000),
                (164016, (9001080, 9001081), "def", 32000)):
            with self.subTest(cid=cid, pids=pids):
                teams = {True: {2: self.gold(cid, *pids)}, False: {2: self.unit(iid=1)}}
                battle._prepare_teams(teams, self.isolated(cid))
                self.assertEqual(teams[True][2][attr], expected)
        teams = {True: {2: self.gold(164016, 9001081), 8: self.unit(iid=701)},
                 False: {2: self.unit(iid=1)}}
        battle._prepare_teams(teams, self.isolated(164016))
        # 妙法莲华的 10% 仙抗暴折算为 10 点韧性，己方全体（不止彩金将）都享受。
        self.assertEqual(teams[True][2]["resilience"], 10)
        self.assertEqual(teams[True][8]["resilience"], 10)

    def test_qiannu_drains_two_targets_and_restores_own_ap(self):
        # 自身 2 怒 -> 指定 4-2=2 个目标，各降 1 怒；自身按目标数 +2 怒。
        attack = {2: self.gold(164006, 9001058, iid=700, speed=300, atk=10, initial_ap=2),
                  8: self.unit(iid=701, speed=1)}
        defense = {2: self.unit(iid=1, hp=100000, atk=10, speed=1, initial_ap=4),
                   8: self.unit(iid=2, hp=100000, atk=10, speed=1, initial_ap=4)}
        report = battle.simulate(attack, defense, self.isolated(164006), 7, max_rounds=1)
        first = report["b"]["a"][0]
        self.assertEqual(first["s"], {})
        self.assertEqual([(x["r"], x["p"], x["ap"]) for x in first["e"] if "ap" in x],
                         [(False, 2, 3), (False, 8, 3), (True, 2, 4)])
        self.assert_replays(report)

    def test_nushi_blocks_enemy_combo_and_boosts_own_chance(self):
        # 敌方同阵位携带者存活时我方不能合体；同阵位敌方存活时自身合体概率 +10%。
        attack = lambda pids: {2: self.gold(164006, *pids, iid=700, speed=300, atk=10, initial_ap=4),
                               8: self.unit(10614, iid=701, speed=1)}
        blocked = self.isolated(164006, combos={12989: {"bout1": 1}})
        for enemy_pids, expected in (((), [12989]), ((9001059,), [])):
            with self.subTest(block=enemy_pids):
                report = battle.simulate(
                    attack((9001059,)),
                    {2: self.gold(164006, *enemy_pids, iid=800, speed=1, atk=10)},
                    blocked, 7, max_rounds=1)
                self.assertEqual(self.combos(report), expected)
                self.assert_replays(report)
        # seed 7 的首个随机数是 0.3238：概率 0.3 不发动，+0.1 后发动。
        boosted = self.isolated(164006, combos={12989: {"bout1": 0.3}})
        for pids, expected in (((), []), ((9001059,), [12989])):
            with self.subTest(boost=pids):
                report = battle.simulate(
                    attack(pids), {2: self.unit(iid=1, hp=100000, atk=10, speed=1)},
                    boosted, 7, max_rounds=1)
                self.assertEqual(self.combos(report), expected)
                self.assert_replays(report)

    def test_jingcai_caozuo_reduces_incoming_damage_per_combo(self):
        # 每放 1 次合体技减伤 5%（线性累加），闪避 +10 点。
        config = self.isolated(164006, (9001060, {"value2": 0.05}))
        damages = []
        for casts in (0, 1, 2):
            report = battle.simulate(
                {2: self.gold(164006, 9001060, iid=700, speed=1, atk=10, combo_casts=casts)},
                self.enemy(speed=300), config, 7, max_rounds=1)
            damages.append(self.incoming(report)[0])
            self.assert_replays(report)
        self.assertEqual(damages, [200, 190, 180])

    def test_zhanshen_rests_first_round_then_halves_damage(self):
        # 隔离 40000 攻击光环后，只看「首回合休息 + 最终伤害/受伤各 50%」。
        config = self.isolated(164006, (9001062, {"value2": 0}))
        for pids, actions, hp in (((), 2, 9700), ((9001062,), 1, 9850)):
            with self.subTest(pids=pids):
                report = battle.simulate(
                    {2: self.gold(164006, *pids, iid=700, speed=300, atk=10)},
                    self.enemy(), config, 7, max_rounds=2)
                self.assertEqual(len([a for a in report["b"]["a"]
                                      if a["s"].get("t") in ("N", "k", "x")
                                      and a["s"].get("r") is True]), actions)
                self.assertEqual(report["endmeta"]["attack"]["2"]["h"], hp)
                self.assert_replays(report)

    def test_fengyin_daji_seals_and_juji_extends_duration(self):
        # 封印按配置概率 patch 为 100%；封印巨戟把同一次封印延长到 2 回合。
        config = self.isolated(164006, (9001061, {"value": 1}),
                               (9001063, {"value": 1, "value2": 0}))
        for pids, on, off in (((), 0, 0), ((9001061,), 2, 1), ((9001061, 9001063), 2, 0)):
            with self.subTest(pids=pids):
                report = battle.simulate(
                    {2: self.gold(164006, *pids, iid=700, speed=300, atk=10)},
                    {2: self.unit(iid=1, hp=100000, atk=10, speed=1, initial_ap=4)},
                    config, 7, max_rounds=2)
                self.assertEqual(len(self.seals(report)), on)
                self.assertEqual(len(self.seals(report, False)), off)
                self.assert_replays(report)

    def test_jingang_seal_cuts_damage_and_transfers_back(self):
        config = self.isolated(164016, (9001076, {"value2": 1}))
        for pids, damage, hp in (((), 200, 9800), ((9001076,), 40, 9960)):
            with self.subTest(pids=pids):
                report = battle.simulate(
                    {2: self.gold(164016, *pids, iid=700, speed=300, atk=10)},
                    self.enemy(), config, 7, max_rounds=1)
                self.assertEqual(self.incoming(report)[0], damage)
                self.assertEqual(report["endmeta"]["attack"]["2"]["h"], hp)
                self.assert_replays(report)
        # 队友持佛印受击后转移回携带者：减伤随佛印走，且按 100% 回 4 怒。
        for seal, restored in ((None, 0), (0.8, 1)):
            with self.subTest(seal=seal):
                report = battle.simulate(
                    {2: self.unit(iid=701, speed=1, buddha_seal=seal),
                     8: self.gold(164016, 9001076, iid=700, speed=1, atk=10, initial_ap=0)},
                    {2: self.unit(iid=1, hp=100000, atk=100, speed=300, initial_ap=4)},
                    config, 7, max_rounds=1)
                events = [a for a in report["b"]["a"] if a["s"] == {}
                          and any(x.get("ap") == 4 for x in a["e"])]
                self.assertEqual(len(events), restored)
                if seal is not None:
                    self.assertGreater(report["endmeta"]["attack"]["2"]["h"], 9900)
                self.assert_replays(report)

    def test_guanwuliangshou_heals_and_lotus_forces_its_seal(self):
        # 回合开始恢复 20% 生命（此处只缺 200，回满）；妙法莲华把技能后封印提到 100%。
        for pids, expected in (((), []), ((9001077,), [-200])):
            with self.subTest(heal=pids):
                report = battle.simulate(
                    {2: self.gold(164016, *pids, iid=700, speed=300, atk=10)},
                    self.enemy(), self.isolated(164016), 7, max_rounds=2)
                heals = [x["m"]["m"] for a in report["b"]["a"] for x in a["e"]
                         if x["r"] is True and isinstance(x.get("m"), dict) and x["m"]["m"] < 0]
                self.assertEqual(heals, expected)
                self.assert_replays(report)
        config = self.isolated(164016, (9001077, {"value2": 0}), (9001081, {"value2": 0}))
        for pids, expected in (((), 0), ((9001077,), 0), ((9001077, 9001081), 1)):
            with self.subTest(seal=pids):
                report = battle.simulate(
                    {2: self.gold(164016, *pids, iid=700, speed=300, atk=10, initial_ap=4)},
                    {2: self.unit(iid=1, hp=100000, atk=10, speed=1)},
                    config, 7, max_rounds=1)
                self.assertEqual(len(self.seals(report)), expected)
                self.assert_replays(report)

    def test_shishanyedao_returns_ap_and_wuxiang_keeps_its_own_rule(self):
        # 9000606 是「无相」与「十善业道」共用的效果号：按 effects[code]["id"] 区分，
        # 前者必定回 value2=1 怒，后者按 0.6（前排 100%）回 1 怒。
        config = self.isolated(164016, (9001078, {"value2": 0.6}))
        for pids, ap in (((), 2), ((9001078,), 3)):
            with self.subTest(pids=pids):
                report = battle.simulate(
                    {2: self.unit(iid=1, hp=100000, atk=100, speed=300, initial_ap=4)},
                    {2: self.gold(164016, *pids, iid=700, speed=1, atk=10)},
                    config, 7, max_rounds=1)
                self.assertEqual(report["endmeta"]["defense"]["2"]["ap"], ap)
                self.assert_replays(report)
        extra = {10201: {**{f"break{i}": 0 for i in range(1, 17)}, "break1": 9000671}}
        config = self.isolated(164016, extra=extra)
        report = battle.simulate(
            {2: self.unit(iid=1, hp=100000, atk=100, speed=300, initial_ap=4)},
            {2: self.unit(iid=2, hp=10000, atk=10, speed=1, advance=1)},
            config, 7, max_rounds=1)
        self.assertTrue(any(a["s"].get("S") == 9000671 and any(x.get("ap") == 1 for x in a["e"])
                            for a in report["b"]["a"] if a["s"].get("t") == "break"))
        self.assert_replays(report)

    def test_dachengqixin_mercy_blocks_death_skills(self):
        # 真实链路：观无量寿技能封印 -> 大乘起信附加慈悲 -> 同回合队友补刀，死亡自爆被禁。
        extra = {10201: {**{f"break{i}": 0 for i in range(1, 17)}, "break1": 9000034}}
        config = self.isolated(164016, (9001077, {"value2": 1}), (9001079, {"value2": 1}),
                               (9001081, {"value2": 0}), extra=extra)
        for pids, deaths, hp in (((), 1, 9988), ((9001077,), 1, 9988),
                                 ((9001077, 9001079), 0, 10000)):
            with self.subTest(pids=pids):
                report = battle.simulate(
                    {2: self.gold(164016, *pids, iid=700, speed=300, atk=1000, initial_ap=4),
                     8: self.unit(iid=701, speed=200, atk=100000)},
                    {2: self.unit(iid=2, hp=100000, atk=10, speed=1, advance=1)},
                    config, 7, max_rounds=1)
                self.assertEqual(len([a for a in report["b"]["a"]
                                      if a["s"].get("r") is False
                                      and a["s"].get("t") == "break"]), deaths)
                self.assertEqual(report["endmeta"]["attack"]["2"]["h"], hp)
                self.assert_replays(report)

    def test_daniepan_zeros_critical_and_weakens_after_revive(self):
        # 隔离 32000 仙防光环后，同阵位敌方暴击归零；复活后首个怒气技降敌方全体 30% 攻击。
        config = self.isolated(164016, (9001080, {"value2": 0}))
        for pids, crits in (((), 1), ((9001080,), 0)):
            with self.subTest(pids=pids):
                report = battle.simulate(
                    {2: self.gold(164016, *pids, iid=700, speed=1, atk=10)},
                    {2: self.unit(iid=1, hp=100000, atk=100, speed=300, critical=100,
                                  initial_ap=4)},
                    config, 7, max_rounds=1)
                self.assertEqual(len([x for a in report["b"]["a"] for x in a["e"]
                                      if isinstance(x.get("m"), dict) and x["m"].get("u") == "C"]),
                                 crits)
                self.assert_replays(report)
        for pending, weakened in ((False, 0), (True, 1)):
            with self.subTest(pending=pending):
                report = battle.simulate(
                    {2: self.gold(164016, 9001080, iid=700, speed=300, atk=10,
                                  initial_ap=4, nirvana_pending=pending)},
                    {2: self.unit(iid=1, hp=100000, atk=100, speed=1)},
                    config, 7, max_rounds=1)
                self.assertEqual(len([x for a in report["b"]["a"] for x in a["e"]
                                      if x.get("B", {}).get("u") == "weaken"
                                      and x.get("B", {}).get("R") == "atk"]), weakened)
                self.assert_replays(report)

    def test_miaofalianhua_also_boosts_ten_virtues(self):
        # 妙法莲华把四个技能的触发概率统一提到 100%：十善业道 value2=0 时仍触发。
        config = self.isolated(164016, (9001078, {"value2": 0}),
                               skills={12201: {"range": "all"}})
        for pids, expected in (((9001078,), 0), ((9001078, 9001081), 1)):
            with self.subTest(pids=pids):
                report = battle.simulate(
                    {2: self.unit(iid=2, hp=100000, atk=10, speed=1),
                     8: self.gold(164016, *pids, iid=700, speed=1, atk=10)},
                    {2: self.unit(iid=1, hp=100000, atk=100, speed=300, initial_ap=4)},
                    config, 7, max_rounds=1)
                self.assertEqual(len([a for a in report["b"]["a"]
                                      if a["s"].get("t") == "break"
                                      and a["s"].get("S") == 9001078]), expected)
                self.assert_replays(report)
