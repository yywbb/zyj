"""彩金伙伴接通进度的可复算回归：防止手工计数过期或白名单被误放宽。

接通数变化时同步更新 EXPECTED 常量，并重新生成 gold_partner_progress.md。
"""

import unittest

import gold_partner_progress as progress
from zyj_server import battle


class ProgressTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data = progress.rows()
        cls.summary = progress.summary()

    def test_live_counts_match_delivered_state(self):
        self.assertEqual(self.summary,
                         {"total": 90, "done": 21, "todo": 69,
                          "families": 38, "codes": 206})

    def test_this_batch_delivers_eight_entries(self):
        # 6 个写了付费链/战斗回归的条目 + 2 个复用同一技能族自动覆盖的条目。
        delivered = (164001, 164002, 164003, 174001, 174005, 174018, 174011, 174032)
        by_cid = {r["cid"]: r for r in self.data}
        for cid in delivered:
            with self.subTest(cid=cid):
                self.assertTrue(by_cid[cid]["done"], cid)
                self.assertEqual(by_cid[cid]["missing"], [])

    def test_reused_second_chains_share_the_same_skill_rows(self):
        by_cid = {r["cid"]: r for r in self.data}
        for first, second in ((164001, 174001), (164001, 174032),
                              (164002, 174005), (164002, 174011), (164003, 174018)):
            with self.subTest(chain=(first, second)):
                self.assertEqual(by_cid[first]["sids"], by_cid[second]["sids"])

    def test_remaining_partners_are_still_rejected_before_charge(self):
        by_cid = {r["cid"]: r for r in self.data}
        for cid in (164047, 164045, 164046, 164049):
            with self.subTest(cid=cid):
                self.assertFalse(by_cid[cid]["done"])
                self.assertTrue(by_cid[cid]["missing"])

    def test_partner_effect_whitelist_is_exact(self):
        # 白名单只能按已实现并回归过的技能族扩展，不能悄悄放宽成「全英雄彩金」。
        expected = {*range(9000742, 9000748), *range(9000547, 9000553),
                    *range(9000678, 9000684), *range(9000688, 9000694),
                    *range(9000598, 9000604), *range(9000571, 9000577),
                    *range(9000604, 9000610), *range(9000524, 9000529),
                    *range(9000529, 9000535), *range(9000541, 9000547)}
        self.assertEqual(battle.PARTNER_EFFECTS, expected)

    def test_progress_document_matches_live_data(self):
        with open("gold_partner_progress.md", encoding="utf-8") as stream:
            saved = stream.read()
        self.assertEqual(saved, progress.markdown() + "\n")
        self.assertIn("剩余 **69**", saved)
