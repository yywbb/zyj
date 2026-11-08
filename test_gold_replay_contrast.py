"""端到端协议回放对照的断言：修复前扣费前拒绝、修复后完整事务、确定性战斗数值。"""

import unittest

import gold_replay_contrast as replay
from zyj_server import battle


class ReplayContrastTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.results = replay.run()

    def test_three_chains_replayed_end_to_end(self):
        self.assertEqual([r["partner"] for r in self.results],
                         ["关羽", "燃脂大乔", "王母娘娘"])
        self.assertEqual([r["chain"] for r in self.results],
                         ["10825→164001", "10834→164002", "10817→164003"])
        for row in self.results:
            with self.subTest(partner=row["partner"]):
                self.assertEqual(row["opcode"], "1017")
                self.assertTrue(row["persisted"])
                self.assertEqual([step[0] for step in row["steps"]], [14, 15, 16])

    def test_fixed_before_charge_rejection_matches_reported_failure(self):
        expected = {"关羽": "尚不支持该突破被动 9001010",
                    "燃脂大乔": "尚不支持该突破被动 9001016",
                    "王母娘娘": "尚不支持该突破被动 9001028"}
        for row in self.results:
            with self.subTest(partner=row["partner"]):
                self.assertEqual(row["before"], expected[row["partner"]])

    def test_whitelist_is_restored_after_reproducing_failure(self):
        # 复现故障用的临时收窄必须完全还原，否则后续战斗/其它测试会受影响。
        self.assertEqual(battle.PARTNER_EFFECTS,
                         {*range(9000742, 9000748), *range(9000547, 9000553),
                          *range(9000678, 9000684), *range(9000688, 9000694),
                          *range(9000598, 9000604), *range(9000571, 9000577),
                          *range(9000604, 9000610), *range(9000524, 9000529),
                          *range(9000529, 9000535), *range(9000541, 9000547)})

    def test_battle_contrast_uses_exact_isolated_numbers(self):
        expected = {"关羽": ("开场攻击（天龙神姿/龙神乱舞光环）", 100, 20100, 20100),
                    "燃脂大乔": ("己方吴国前 2 回合累计伤害（潮街领舞）", 200, 250, None),
                    "王母娘娘": ("王母怜生治疗量（生命最低者，受缺失生命 clamp）", 0, -200, None)}
        for row in self.results:
            with self.subTest(partner=row["partner"]):
                self.assertEqual((row["label"], row["plain"], row["boosted"], row["stacked"]),
                                 expected[row["partner"]])

    def test_replay_document_matches_live_run(self):
        with open("end_to_end_replay.md", encoding="utf-8") as stream:
            saved = stream.read()
        self.assertEqual(saved, replay.markdown(self.results) + "\n")
        self.assertIn("未启动游戏、未连接手机、未操作任何账号", saved)
