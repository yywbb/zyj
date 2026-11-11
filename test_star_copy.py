"""名将副本：全 62 章 / 310 图 / 1219 关与 1350–1352 通关箱的定向回归。"""

import copy
import io
import json
import struct
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

import test_activity_copy as activity_tests
from zyj_server import activities, battle, formation, player, protocol, recharge, star_copy
from zyj_server.session import Session


NOW = 1800172800


class StarCopyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        activity_tests.ActivityCopyTests.setUpClass.__func__(cls)
        cls.baseline["role_state"].update(level=150, nextexp=cls.config["role_exp"]["150"]["nextexp"])
        copies = []
        for mid in cls.config["star_map"]:
            points = b"".join(protocol.encode_pb_field(7, 2, protocol.encode_pb_field(1, 0, int(pid))
                              + protocol.encode_pb_field(3, 0, 3))
                              for pid in cls.config["copy"][mid])
            copies.append(protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, int(mid)) + points))
        cls.baseline["world_state"]["1300"] = b"".join(copies).hex()

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

    def reconnect(self):
        return Session(self.tables, self.path, self.steps, self.config)

    def call(self, opcode, values=(), seq=181):
        return self.session.handle(opcode, seq, recharge.ids(values))

    def rows(self):
        packet = self.call(1350)[0]
        self.assertEqual(struct.unpack(">IIII", packet[:16])[2], 1350)
        result = {}
        for _, _, raw in protocol.iter_pb_fields(packet[16:]):
            fields = {n: v for n, _, v in protocol.iter_pb_fields(raw)}
            result[fields[1]] = [v - (1 << 64) if v >= (1 << 63) else v
                                 for v in protocol.parse_ids_pb(fields[2])]
        return result

    def report(self, packets):
        return json.loads(next(v for n, w, v in protocol.iter_pb_fields(packets[0][16:]) if (n, w) == (5, 2)))

    def prop_count(self, save, cid):
        props = formation.records(bytes.fromhex(save["world_state"]["1200"]), 1, 1)
        return protocol.pb_get_varint(props.get(cid, b""), 2) or 0

    def strengthen(self, *, weak=False):
        world = bytes.fromhex(self.session.save["world_state"]["1002"])
        for raw in formation.records(world, 1, 2).values():
            for field, value in ((6, 1 if weak else 10000000), (7, 0), (8, 1 if weak else 10000000), (9, 1 if weak else 1000)):
                raw = protocol.pb_set_varint(raw, field, value)
            player.record_slot_update(self.session.save, protocol.encode_pb_field(1, 2, raw))
            player.record_protagonist_general(self.session.save, raw)
        self.path.write_text(json.dumps(self.session.save))

    def assert_rejected(self, opcode, body):
        memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        packets = self.session.handle(opcode, 200, body)
        self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets], [999999, 1999])
        self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))

    def test_full_catalog_query_covers_all_62_sections_without_free_progress(self):
        before = copy.deepcopy(self.session.save)
        rows = self.rows()
        self.assertEqual(len(rows), 311)
        self.assertEqual(rows[0], [0])
        self.assertEqual(set(rows), {0, *map(int, self.config["star_map"])})
        self.assertEqual(len({self.config["star_map"][mid]["section"] for mid in self.config["star_map"]}), 62)
        self.assertEqual(sum(len(points) for points in self.config["star_copy"].values()), 1219)
        for mid in ("42101", "42322", "42410"):
            point_ids = sorted(map(int, self.config["star_copy"][mid]))
            self.assertEqual(rows[int(mid)], [int(mid), 0, point_ids[0], -1, 0])
        for key in ("role_state", "world_state", "guide", "protagonist_snapshot"):
            self.assertEqual(self.session.save[key], before[key])
        self.session = self.reconnect()
        self.assertEqual(self.rows(), rows)

    def test_all_1219_points_use_real_rosters_battles_drops_and_box_rewards(self):
        saved = copy.deepcopy(self.session.save)
        self.strengthen()
        saved = copy.deepcopy(self.session.save)
        clamped, checked = 0, 0
        for mid, points in self.config["star_copy"].items():
            for pid, point in points.items():
                with self.subTest(map=mid, point=pid):
                    checked += 1
                    safe = battle.sanitize_breakthrough(dict(point), self.config)
                    clamped += int(any(safe[f"break{i}-correct"] != point[f"break{i}-correct"] for i in range(1, 8)))
                    attack, defense = battle.rosters(saved, safe, self.config)
                    report = battle.simulate(attack, defense, self.config, 7)
                    self.assertEqual(report["rules"], "zyj-v2")
                    self.assertIsInstance(report["result"], bool)
                    self.assertGreater(report["round"], 0)
                    for i in range(1, 6):
                        if point[f"drop{i}"] and point[f"drop{i}prob"]:
                            activities.build_reward(copy.deepcopy(saved),
                                                    f'{point[f"drop{i}"]},{point[f"drop{i}number"]}', self.config)
                    activities.build_reward(copy.deepcopy(saved),
                                            f'{point["drop_no1"]},{point["drop1number_no1"]}', self.config)
                    activities.build_reward(copy.deepcopy(saved), f'{point["receive"]},1', self.config)
        self.assertEqual(checked, 1219)
        # 15 个后期关卡的 NPC break9 引用未实现的 ap/target=6 行，按共享白名单逐档收敛。
        self.assertEqual(clamped, 15)

    def test_first_clear_and_daily_cap_use_real_settlement(self):
        self.strengthen()
        before = copy.deepcopy(self.session.save)
        packets = self.call(1351, [42101, 1], seq=210)
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 1351)
        self.assertTrue(self.report(packets)["result"])
        after = json.loads(self.path.read_text())
        self.assertEqual(after["star_copy_state"]["progress"], {"42101": 1})
        self.assertEqual(after["star_copy_state"]["wins"], {"42101/1": 1})
        self.assertEqual(after["last_star_battle"]["map"], 42101)
        self.assertEqual(after["world_state"]["1300"], before["world_state"]["1300"])
        for key in ("level", "exp", "stamina", "energy", "power"):
            self.assertEqual(after["role_state"][key], before["role_state"][key])
        self.assertEqual(after["role_state"]["gold"] - before["role_state"]["gold"], 40)
        rows = self.rows()
        self.assertEqual(rows[42101], [42101, 1, 1, 1, 1])
        self.assertEqual(rows[0], [1])
        self.assert_rejected(1351, recharge.ids([42101, 1]))
        # 同名请求在同一连接内沿用缓存，不重复发奖。
        self.assertEqual(self.call(1351, [42101, 1], seq=210), packets)
        self.clock.return_value += 86400
        self.session = self.reconnect()
        self.assertEqual(self.rows()[0], [0])
        self.assertEqual(self.rows()[42101], [42101, 1, 1, 0, 1])

    def test_last_chapter_is_open_for_a_real_battle_and_loss_does_not_progress(self):
        # 第 62 章 42410 的 NPC 逐位修正为十亿级，150 级阵容打不过属配置数值，
        # 但必须能真实发起 v2 战斗并返回战报，不能因章节限制被拒或伪造进度。
        self.strengthen()
        before = copy.deepcopy(self.session.save)
        packets = self.call(1351, [42410, 1], seq=211)
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 1351)
        report = self.report(packets)
        self.assertEqual(report["rules"], "zyj-v2")
        self.assertGreater(report["round"], 0)
        after = json.loads(self.path.read_text())
        self.assertEqual(after["star_copy_state"]["progress"], {})
        self.assertEqual(after["star_copy_state"]["wins"], {})
        self.assertEqual(after["last_star_battle"]["map"], 42410)
        self.assertEqual(after["role_state"], before["role_state"])
        self.assertEqual(after["world_state"]["1300"], before["world_state"]["1300"])
        self.assertEqual(star_copy.get_state(after, self.config)["boxes"], [])

    def test_box_claim_is_once_and_survives_reconnect_and_day_reset(self):
        self.strengthen()
        self.call(1351, [42101, 1], seq=220)
        self.assertEqual(self.rows()[42101][4], 1)
        before = self.prop_count(self.session.save, 20267)
        packets = self.call(1352, [42101, 1], seq=221)
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 1352)
        self.assertEqual(self.prop_count(self.session.save, 20267), before + 1)
        saved = json.loads(self.path.read_text())
        self.assertEqual(saved["star_copy_state"]["boxes"], ["42101/1"])
        self.assertEqual(self.rows()[42101][4], 2)
        self.assertEqual(self.call(1352, [42101, 1], seq=221), packets)
        self.assert_rejected(1352, recharge.ids([42101, 1]))
        self.session = self.reconnect()
        self.assertEqual(self.rows()[42101][4], 2)
        self.assert_rejected(1352, recharge.ids([42101, 1]))
        self.clock.return_value += 86400
        self.session = self.reconnect()
        rows = self.rows()
        self.assertEqual(rows[0], [0])
        self.assertEqual(rows[42101][4], 2)
        self.assertEqual(json.loads(self.path.read_text())["star_copy_state"]["boxes"], ["42101/1"])

    def test_box_rejects_invalid_unearned_duplicate_locked_and_comb_requests(self):
        for opcode in star_copy.OPCODES:
            for body in (b"\x08", b"\x10\x01", b"\x0a\x00", recharge.ids([0]),
                         recharge.ids([1 << 31]), recharge.ids([42410, 1, 1])):
                self.assert_rejected(opcode, body)
        for values in ([], [42101], [42101, 2], [99999, 1], [42101, 0]):
            self.assert_rejected(1352, recharge.ids(values))
        # 未首通不可领；首通后重复领取被拒。
        self.strengthen()
        self.assert_rejected(1352, recharge.ids([42101, 1]))
        self.call(1351, [42101, 1], seq=230)
        self.call(1352, [42101, 1], seq=231)
        self.assert_rejected(1352, recharge.ids([42101, 1]))
        # 等级不足或普通地图未通关都不放行宝箱。
        self.session.save["role_state"]["level"] = 13
        self.assert_rejected(1352, recharge.ids([42101, 1]))
        self.session.save["role_state"]["level"] = 150
        self.session.save["world_state"]["1300"] = ""
        self.assert_rejected(1352, recharge.ids([42101, 1]))
        comb = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 1352)
                                        + protocol.encode_pb_field(2, 2, recharge.ids([42101, 1])))
        self.assert_rejected(999900, comb)

    def test_box_save_failure_and_reward_overflow_are_atomic(self):
        self.strengthen()
        self.call(1351, [42101, 1], seq=240)
        before, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        with patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
            self.call(1352, [42101, 1])
        self.assertEqual((self.session.save, self.path.read_bytes()), (before, disk))
        player.change_item_count(self.session.save, 20267, (1 << 31) - 1 - self.prop_count(self.session.save, 20267),
                                 self.config, NOW)
        self.assert_rejected(1352, recharge.ids([42101, 1]))

    def test_corrupt_box_state_fails_closed_without_changing_the_save(self):
        baseline = copy.deepcopy(self.baseline)
        cases = [{"day": 0, "progress": {}, "wins": {}, "boxes": "42410/1"},
                 {"day": 0, "progress": {}, "wins": {}, "boxes": ["42410/1"]},
                 {"day": 0, "progress": {"42410": 1}, "wins": {}, "boxes": ["42410/1", "42410/1"]},
                 {"day": 0, "progress": {"42410": 1}, "wins": {}, "boxes": ["42410/2"]},
                 {"day": 0, "progress": {"42410": 1}, "wins": {}, "boxes": [42410]},
                 {"day": 0, "progress": {"42410": 1}, "wins": {}, "boxes": ["99999/1"]}]
        for state in cases:
            baseline["star_copy_state"] = state
            self.path.write_text(json.dumps(baseline))
            before = self.path.read_bytes()
            with self.subTest(state=state), self.assertRaisesRegex(ValueError, "名将副本"):
                self.reconnect()
            self.assertEqual(self.path.read_bytes(), before)
        # 旧档没有 boxes 字段时按空列表安全迁移，不清空已有进度。
        baseline["star_copy_state"] = {"day": 0, "progress": {"42101": 1}, "wins": {"42101/1": 1}}
        self.path.write_text(json.dumps(baseline))
        self.assertEqual(star_copy.boxes(star_copy.get_state(self.reconnect().save, self.config)), [])


if __name__ == "__main__":
    unittest.main()
