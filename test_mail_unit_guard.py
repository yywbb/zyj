"""GM 批量赠送魔符等按件物品时的启动故障回归。

现场：一封邮件含 50 种魔符各 1000 枚，一键领取会生成 5 万个实例，
逐条合并进 1002 存档使服务端单线程长期占满，账号在线锁不释放，客户端启动报错。
"""

import copy
import json
import signal
import struct
import unittest
from unittest.mock import patch

import test_penglai
from zyj_server import accounts, activities, formation, mail, player, protocol, recharge
from zyj_server.admin import gm


NOW = test_penglai.NOW
MAIL_ID = 800000127
UNIT_LIMIT = 200


class _ClaimDeadline(Exception):
    pass


def _on_alarm(signum, frame):
    raise _ClaimDeadline("领取超时")


class MailUnitGuardTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        test_penglai.PenglaiTests.setUpClass.__func__(cls)

    reconnect = test_penglai.PenglaiTests.reconnect

    def setUp(self):
        test_penglai.PenglaiTests.setUp(self)
        self.mail_path = self.path.with_name("mails.json")
        self.store = accounts.AccountStore(self.path, self.tables, self.steps, self.config)
        (self.path.parent / "gm_operations").mkdir(exist_ok=True)
        self.session.rank_query = lambda body, opcode, working: mail.prepare(
            opcode, working, body, self.mail_path, None, 1, self.config, NOW)

    def send_mail(self, attachments, mail_id=MAIL_ID):
        self.mail_path.write_text(json.dumps({
            "next_id": mail_id + 1,
            "mails": [{"id": mail_id, "target": 1, "title": "GM系统福利发放", "content": "",
                       "attachments": attachments, "card": 0, "recharge_rmb": 0,
                       "created_at": NOW, "sender": "GM"}]
        }, ensure_ascii=False))
        return mail_id

    def claim(self, mail_id=MAIL_ID, timeout=0):
        body = recharge.ids([mail_id])
        self.claim_seq = getattr(self, "claim_seq", 900) + 1
        seq = self.claim_seq
        if not timeout:
            return self.session.handle(3101, seq, body)
        previous = signal.signal(signal.SIGALRM, _on_alarm)
        signal.setitimer(signal.ITIMER_REAL, timeout)
        try:
            return self.session.handle(3101, seq, body)
        finally:
            signal.setitimer(signal.ITIMER_REAL, 0)
            signal.signal(signal.SIGALRM, previous)

    def gems(self, save=None):
        data = self.session.save if save is None else save
        return formation.records(bytes.fromhex(data["world_state"]["1002"]), 7, 1)

    def sigil_cids(self, count):
        return [int(cid) for cid in list(self.config["sigil"])[:count]]

    def test_reward_module_declares_a_unit_reward_limit(self):
        self.assertEqual(getattr(activities, "MAX_UNIT_REWARDS", None), UNIT_LIMIT)

    def test_stacked_and_recruit_routed_cids_are_not_counted_as_unit_rewards(self):
        """战魂令牌 70000 等可堆叠道具不能因同号出现在配置表里而被误判。"""
        self.assertEqual(activities.unit_reward_count("70000,10000", self.config), 0)
        self.assertEqual(activities.unit_reward_count("33001,10;70000,10000", self.config), 10)

    def test_real_bulk_sigil_mail_is_rejected_fast_and_never_touches_save(self):
        """真实现场：50 种魔符各 1000 枚，必须在生成实例前拒绝，不能卡住连接线程。"""
        self.send_mail({str(cid): 1000 for cid in self.sigil_cids(50)})
        before = copy.deepcopy(self.session.save), self.path.read_bytes()
        original_gems = self.gems(before[0])
        try:
            packets = self.claim(timeout=3)
        except _ClaimDeadline:
            self.fail("领取 5 万枚魔符超时：旧实现会逐条合并 1002 存档")
        self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets[:2]], [999999, 1999])
        self.assertIn("分批".encode(), packets[1][16:])
        self.assertEqual((self.session.save, self.path.read_bytes()), before)
        self.assertNotIn(MAIL_ID, self.session.save.get("mail_state", {}).get("claimed", []))
        self.assertEqual(len(self.gems()), len(original_gems))

    def test_just_over_the_unit_limit_is_rejected_without_partial_grant(self):
        cids = self.sigil_cids(50)
        self.send_mail({str(cid): UNIT_LIMIT // len(cids) + 1 for cid in cids})
        before = copy.deepcopy(self.session.save), self.path.read_bytes()
        packets = self.claim()
        self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets[:2]], [999999, 1999])
        self.assertEqual((self.session.save, self.path.read_bytes()), before)
        self.assertEqual(len(self.gems()), len(self.gems(before[0])))

    def test_small_sigil_mail_still_grants_unique_instances_once(self):
        cids = self.sigil_cids(3)
        self.send_mail({str(cid): 2 for cid in cids})
        before = self.gems()
        packet = self.claim()[0]
        self.assertEqual(struct.unpack(">IIII", packet[:16])[2], 3101)
        after = self.gems()
        self.assertEqual(len(after) - len(before), 6)
        self.assertEqual(len(set(after)), len(after))
        self.assertEqual({protocol.parse_ids_pb(raw)[1] for iid, raw in after.items() if iid not in before},
                         set(cids))
        self.assertIn(MAIL_ID, self.session.save["mail_state"]["claimed"])
        self.assertEqual(struct.unpack(">IIII", self.claim()[0][:16])[2], 999999)

    def test_instance_rewards_merge_slots_in_one_pass(self):
        """按件奖励一次性合并 1002，不能每个实例都重扫整个存档。"""
        save = copy.deepcopy(self.session.save)
        before = len(self.gems())
        reward = b"".join(protocol.encode_pb_field(11, 2, recharge.ids([4000000 + i, 33001, 1, 0]))
                          for i in range(60))
        with patch.object(player, "record_slot_update", wraps=player.record_slot_update) as merged:
            player.apply_reward(save, reward, self.config, NOW)
        self.assertEqual(merged.call_count, 1)
        gems = formation.records(bytes.fromhex(save["world_state"]["1002"]), 7, 1)
        self.assertEqual(len(gems) - before, 60)
        self.assertEqual(len(set(gems)), len(gems))

    def test_gm_mail_rejects_oversized_unit_batch_before_sending(self):
        """后台批量发魔符时必须先挡住，避免再生成会卡死服务端的邮件。"""
        workbench = gm.Workbench(self.store)
        items = [{"cid": cid, "count": 1000} for cid in self.sigil_cids(50)]
        with self.assertRaisesRegex(ValueError, "分批"):
            workbench.send_mail({"target": 1, "title": "魔符福利", "content": "", "items": items})
        self.assertFalse(self.mail_path.exists())

    def test_gm_mail_still_accepts_unit_batch_within_limit(self):
        workbench = gm.Workbench(self.store)
        items = [{"cid": cid, "count": UNIT_LIMIT // 50} for cid in self.sigil_cids(50)]
        result = workbench.send_mail({"target": 1, "title": "魔符福利", "content": "", "items": items})
        self.assertEqual(result["id"], 800000001)
        self.assertTrue(self.mail_path.exists())


if __name__ == "__main__":
    unittest.main()
