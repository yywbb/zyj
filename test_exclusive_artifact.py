"""专属神器（8101–8204、7010 sysId=614）的真实协议、配置、战斗与存档回归。"""

from contextlib import redirect_stdout
import copy
import io
import json
from pathlib import Path
import random
import struct
import tempfile
import unittest
from unittest.mock import patch

import build_local_apk as builder
import test_activity_copy as base
from zyj_server import exclusive_artifact as artifact, formation, player, protocol, recharge
from zyj_server.session import Session

NOW = 1800172800
GOLD_CID = 164001
ARTIFACT_IID = 990001


def messages(raw):
    result = {}
    for n, w, value in protocol.iter_pb_fields(raw):
        if (n, w) != (1, 2):
            continue
        mid, data = None, b""
        for fn, fw, sub in protocol.iter_pb_fields(value):
            if (fn, fw) == (1, 0):
                mid = sub
            elif (fn, fw) == (2, 2):
                data = sub
        result[mid] = data
    return result


def values(raw):
    return protocol.parse_ids_pb(raw)


def reward_items(raw):
    items = []
    for n, w, data in protocol.iter_pb_fields(raw):
        if (n, w) != (5, 2):
            continue
        for fn, fw, record in protocol.iter_pb_fields(data):
            if (fn, fw) == (1, 2):
                items.append((protocol.pb_get_varint(record, 1), protocol.pb_get_varint(record, 2)))
    return items


def qiling_groups(raw):
    for n, w, data in protocol.iter_pb_fields(raw):
        if (n, w) == (19, 2):
            flat = values(data)
            return [flat[i:i + 17] for i in range(0, len(flat), 17)]
    return []


class ExclusiveArtifactTests(unittest.TestCase):
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
            self.give(cid, 200000)
        self.give(1025, 200000)
        self.give(1002, 5000)

    # ---- 夹具 ----
    def reconnect(self):
        return Session(self.tables, self.path, self.steps, self.config)

    def commit(self):
        self.path.write_text(json.dumps(self.session.save))

    def give(self, cid, count):
        player.change_item_count(self.session.save, cid, count, self.config, NOW)
        self.commit()

    def state(self):
        return artifact.get_state(self.session.save)

    def call(self, opcode, body=(), seq=181, *, raw=None):
        return self.session.handle(opcode, seq, raw if raw is not None else recharge.ids(body))

    def success(self, opcode, body=(), seq=181, *, raw=None):
        packets = self.call(opcode, body, seq=seq, raw=raw)
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], opcode, packets)
        return packets[0][16:]

    def assert_rejected(self, opcode, body=(), *, raw=None):
        memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        packets = self.session.handle(opcode, 200, raw if raw is not None else recharge.ids(body))
        self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets], [999999, 1999])
        self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))

    def make_artifact(self, iid=ARTIFACT_IID, cid=201501, level=0):
        self.state()["artifacts"][str(iid)] = {"cid": cid, "level": level,
                                              "inlay": [0] * 6, "spent": {}}
        self.commit()
        return iid

    def make_qiling(self, cid=201601):
        iid, _ = artifact.create_qiling(self.state(), cid, self.config, random.Random(7))
        self.commit()
        return iid

    def prop_count(self, cid):
        rows = formation.records(bytes.fromhex(self.session.save["world_state"]["1200"]), 1, 1)
        return protocol.pb_get_varint(rows.get(cid, b""), 2) or 0

    def set_general_cid(self, iid, cid):
        world = bytes.fromhex(self.session.save["world_state"]["1002"])
        generals = formation.records(world, 1, 2)
        player.record_slot_update(self.session.save, protocol.encode_pb_field(
            1, 2, protocol.pb_set_varint(generals[iid], 1, cid)))
        self.commit()

    def make_gold_general(self):
        world = bytes.fromhex(self.session.save["world_state"]["1002"])
        generals = formation.records(world, 1, 2)
        slots = formation.records(world, 4, 1)
        protagonist = protocol.pb_get_varint(bytes.fromhex(self.session.save["protagonist_snapshot"]), 1)
        iid = next(key for key in generals if key != protagonist)
        player.record_slot_update(self.session.save, protocol.encode_pb_field(
            1, 2, protocol.pb_set_varint(generals[iid], 1, GOLD_CID)))
        if not any(protocol.pb_get_varint(slot, 2) == iid for slot in slots.values()):
            index = min(slots)
            player.record_slot_update(self.session.save, protocol.encode_pb_field(
                4, 2, protocol.pb_set_varint(slots[index], 2, iid)))
        self.commit()
        return iid

    def power(self):
        world = bytes.fromhex(self.session.save["world_state"]["1002"])
        for raw in formation.records(world, 1, 2).values():
            for field, value in ((6, 2000000000), (7, 1000000000), (8, 2000000000), (9, 100000)):
                raw = protocol.pb_set_varint(raw, field, value)
            player.record_slot_update(self.session.save, protocol.encode_pb_field(1, 2, raw))
        self.commit()

    def activate(self):
        iid = self.make_gold_general()
        self.power()
        reply = self.success(8103, [iid])
        parts = messages(reply)
        self.assertEqual(set(parts), {1, 2})
        self.assertEqual(protocol.pb_get_varint(parts[1], 1), 1, "激活挑战必须真实战胜")
        return iid, parts

    # ---- 查询与初始化 ----
    def test_queries_have_native_twelve_and_seventeen_field_shapes(self):
        self.assertEqual(self.success(8101), b"")
        self.assertEqual(self.success(8105), b"")
        self.assertEqual(self.success(8109), b"")
        parts = messages(self.success(8201))
        self.assertEqual(set(parts), {1, 2})
        self.assertEqual(len(values(parts[2])), 42)
        self.assertGreater(values(parts[1])[0], 0)
        iid = self.make_artifact(level=3)
        self.assertEqual(values(self.success(8101, [iid])), [iid, 201501, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        self.assertEqual(values(self.success(8101)), values(self.success(8101, [iid])))
        qiling = self.make_qiling()
        self.assertEqual(len(values(self.success(8105))), 17)
        self.assertEqual(values(self.success(8105))[0], qiling)
        self.assert_rejected(8101, [1, 2])
        self.assert_rejected(8105, [1])
        self.assert_rejected(8201, [1])

    def test_empty_initialization_extensions_are_preserved(self):
        # 999900 的 8101/8105/8109 子消息没有参数；新号没有任何进度，仍必须回空。
        for opcode in (8101, 8105, 8109):
            self.assertEqual(artifact.prepare(opcode, {"role_state": {"level": 1}}, b"", self.config, NOW, 1)[0], b"")

    # ---- 激活 ----
    def test_activation_requires_gold_onslot_general_and_real_battle(self):
        self.assert_rejected(8103, [1])
        iid = self.make_gold_general()
        self.set_general_cid(iid, 10502)  # 关羽基础品质 5，非彩金不能激活
        self.assert_rejected(8103, [iid])
        self.set_general_cid(iid, GOLD_CID)
        iid, parts = self.activate()
        self.assertEqual(values(parts[2]), [iid, 201501, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        self.assertEqual(self.state()["active"], {str(iid): 1})
        self.assertEqual(values(self.success(8109)), [iid, 1])
        self.assert_rejected(8103, [iid])

    def test_second_activation_attempt_uses_next_checkpoint(self):
        iid, _ = self.activate()
        self.state()["artifacts"].pop(str(iid))
        self.commit()
        captured = []
        original = artifact._fight

        def probe(save, point, config, seed, name):
            captured.append(int(point["checkpoint"]))
            return original(save, point, config, seed, name)

        with patch.object(artifact, "_fight", side_effect=probe):
            self.success(8103, [iid], seq=182)
        self.assertEqual(captured, [2])

    def test_activation_daily_limit_and_reconnect(self):
        iid, _ = self.activate()
        self.state()["artifacts"].pop(str(iid))
        self.commit()
        self.assertEqual(values(self.success(8109)), [iid, 1])
        self.session = self.reconnect()
        self.assertEqual(values(self.success(8109)), [iid, 1])
        state = self.state()
        state["active"][str(iid)] = int(self.config["vip"]["0"]["exclusive_copy"])
        self.commit()
        self.assert_rejected(8103, [iid])
        self.clock.return_value = NOW + 86400
        self.assertEqual(self.success(8109), b"")  # 只读视图已日切
        self.assertEqual(artifact.query_view(self.session.save, NOW + 86400)["active"], {})
        # 查询不落盘，旧档仍保留昨天的记录；下一次结算才真正写入日切。
        self.assertEqual(self.state()["active"], {str(iid): int(self.config["vip"]["0"]["exclusive_copy"])})

    # ---- 强化、洗礼与重生 ----
    def test_strengthen_and_baptism_charge_real_config_and_keep_client_level_formula(self):
        iid = self.make_artifact()
        before = self.prop_count(192087)
        self.assertEqual(values(self.success(8102, [iid, 1]))[2], 1)
        self.assertEqual(self.state()["artifacts"][str(iid)]["level"], 1)
        self.assertEqual(self.prop_count(192087), before - 10)
        self.assertEqual(self.state()["artifacts"][str(iid)]["spent"], {"192087": 10})
        self.assertEqual(values(self.success(8102, [iid, 5]))[2], 6)
        state = self.state()
        state["artifacts"][str(iid)]["level"] = 11
        self.commit()
        before = self.prop_count(192088)
        self.assertEqual(values(self.success(8102, [iid, 0]))[2], 12)
        self.assertEqual(self.prop_count(192088), before - 17)
        self.assert_rejected(8102, [iid, 6])
        self.assert_rejected(8102, [iid, 0])
        self.assert_rejected(8102, [999999, 1])

    def test_strengthen_never_crosses_baptism_or_overlevels(self):
        iid = self.make_artifact(level=9)
        self.assert_rejected(8102, [iid, 3])
        state = self.state()
        state["artifacts"][str(iid)]["level"] = 70
        self.commit()
        self.assert_rejected(8102, [iid, 1])

    def test_rebirth_returns_only_actual_spent_and_unloads_qilings(self):
        iid = self.make_artifact()
        qiling = self.make_qiling()
        self.success(8104, [iid, 1, qiling])
        self.success(8102, [iid, 1])
        state = self.state()
        state["artifacts"][str(iid)]["level"] = 12
        self.commit()
        gold = self.session.save["role_state"]["g_gold"]
        reward = self.success(8204, [iid])
        self.assertEqual(reward_items(reward), [(192087, 10)])
        self.assertEqual(self.state()["artifacts"][str(iid)]["level"], 0)
        self.assertEqual(self.state()["artifacts"][str(iid)]["inlay"], [0] * 6)
        self.assertIn(str(qiling), self.state()["qilings"])
        fee = (int(self.config["renascence"]["10"]["exclusive_intensify"])
               + int(self.config["renascence"]["1"]["exclusive_baptism"]))
        self.assertEqual(self.session.save["role_state"]["g_gold"], gold - fee)
        self.assert_rejected(8204, [iid])
        self.assert_rejected(5520, [1])

    # ---- 器灵 ----
    def test_inlay_suits_unload_and_auto_move(self):
        iid = self.make_artifact()
        first = self.make_qiling(201601)
        second = self.make_qiling(201602)
        other = self.make_artifact(990002)
        self.success(8104, [iid, 1, first])
        reply = values(self.success(8104, [iid, 2, second]))
        self.assertEqual(len(reply), 12)
        self.assertEqual(reply[3:5], [first, second])
        self.assertTrue(any(reply[9:12]))
        # 器灵已在其它神器上时自动换装，回包同时带两把神器。
        self.assertEqual(len(values(self.success(8104, [other, 1, first]))), 24)
        self.assertEqual(values(self.success(8104, [iid, 1, 0]))[3], 0)
        self.assert_rejected(8104, [iid, 2, first])
        self.assert_rejected(8104, [iid, 7, second])
        self.assert_rejected(8104, [iid, 1, 999999])

    def test_qiling_strengthen_consumes_dust_and_tracks_success_rate(self):
        qiling = self.make_qiling()
        before = self.prop_count(192091)
        reply = values(self.success(8106, [qiling]))
        self.assertEqual(len(reply), 17)
        row = self.state()["qilings"][str(qiling)]
        self.assertIn(row["level"], (0, 1))
        if row["level"] == 0:
            self.assertGreater(row["success"], 0)
        self.assertEqual(self.prop_count(192091), before - 2)
        self.assert_rejected(8106, [999999])

    def test_qiling_lock_and_refine_reject_locked_or_worn(self):
        first = self.make_qiling()
        second = self.make_qiling()
        third = self.make_qiling()
        self.assertEqual(values(self.success(8107, [first, 1]))[4], 1)
        self.assertEqual(values(self.success(8107, [first, 0]))[4], 0)
        iid = self.make_artifact()
        self.success(8104, [iid, 1, second])
        self.assert_rejected(8108, [first, second])
        self.assert_rejected(8108, [first, first])
        self.assert_rejected(8108, [999999])
        before = self.prop_count(192091)
        reward = self.success(8108, [first, third])
        self.assertEqual(reward_items(reward), [(192091, 24)])
        self.assertEqual(self.prop_count(192091), before + 24)
        self.assertNotIn(str(first), self.state()["qilings"])
        self.assertNotIn(str(third), self.state()["qilings"])
        self.assertIn(str(second), self.state()["qilings"])

    # ---- 专属副本 ----
    def test_copy_query_reports_real_unlock_progress_and_daily_times(self):
        parts = messages(self.success(8201))
        self.assertEqual(values(parts[1])[1], 1)  # 150 级：第 1 关可挑战
        self.assertEqual(values(parts[2])[:6], [2] * 6)
        self.assertEqual(values(parts[2])[6], 1)  # 第 1 图难度 1 已解锁
        self.assertEqual(values(parts[2])[7], 0)  # 难度 2 需要首通难度 1
        state = self.state()
        state["soul"]["cleared"]["1"] = 2
        state["spirit"]["cleared"]["1"] = {"1": 1}
        self.commit()
        parts = messages(self.success(8201))
        self.assertEqual(values(parts[1])[1], 2)
        self.assertEqual(values(parts[2])[7], 1)

    def test_soul_fight_sweep_and_buy_times(self):
        self.power()
        gold = self.session.save["role_state"]["g_gold"]
        self.assertEqual(values(messages(self.success(8201))[1])[0], 2)
        fight = self.success(8202, [1])
        self.assertIn(protocol.pb_get_varint(fight, 1), (0, 1))  # 胜负由真实战斗决定
        self.assertEqual(self.state()["soul"]["used"], 1)
        # 胜利直接记录通关；若本次战败，用等价的已通关存档继续验证扫荡。
        if self.state()["soul"]["cleared"].get("1") != 2:
            self.state()["soul"]["cleared"]["1"] = 2
            self.commit()
        self.assertEqual(values(messages(self.success(8201))[1])[0], 1)
        self.success(8203, [1])
        self.assertEqual(self.state()["soul"]["used"], 2)
        self.assert_rejected(8202, [1])
        price = int(self.config["buycount_price"]["1"]["device_soul_copy_cost"])
        self.assertEqual(self.success(7010, [614, 1]), b"")
        self.assertEqual(self.session.save["role_state"]["g_gold"], gold - price)
        self.assertEqual(self.state()["soul"]["bought"], 1)
        self.assertEqual(values(messages(self.success(8201))[1])[0], 1)
        self.assert_rejected(7010, [614, 3])
        self.assert_rejected(7010, [615, 1])

    def test_spirit_fight_uses_real_battle_and_costs_stamina(self):
        self.power()
        stamina = self.session.save["role_state"]["stamina"]
        physical = int(self.config["exclusive_device_spirit_copy"]["1"]["1"]["physical"])
        fight = self.success(8202, [1, 1])
        result = protocol.pb_get_varint(fight, 1)
        self.assertIn(result, (0, 1))
        self.assertEqual(self.state()["spirit"]["used"], {"1": 1})
        self.assertEqual(self.session.save["role_state"]["stamina"], stamina - physical)
        reward = next(v for n, w, v in protocol.iter_pb_fields(fight) if (n, w) == (4, 2))
        if result:
            self.assertEqual(self.state()["spirit"]["cleared"]["1"], {"1": 1})
            groups = qiling_groups(reward)
            self.assertTrue(groups)
            self.assertTrue(all(len(group) == 17 for group in groups))
            self.assertTrue(all(str(group[1]) in self.config["exclusive_device_spirit"] for group in groups))
            self.assertEqual(len(values(self.success(8105))), 17 * len(groups))
            # 器灵走 SomeThings.qiling，不会重复入账为普通道具。
            rows = formation.records(bytes.fromhex(self.session.save["world_state"]["1200"]), 1, 1)
            self.assertNotIn(groups[0][1], rows)
        else:
            self.assertEqual(self.state()["spirit"]["cleared"], {})
            self.assertEqual(qiling_groups(reward), [])
            self.assertEqual(reward_items(reward)[0][0], 192091)
        self.assert_rejected(8202, [1, 3])
        self.assert_rejected(8202, [1, 1, 1])

    def test_spirit_victory_drops_create_real_qilings_with_seventeen_fields(self):
        row = self.config["exclusive_device_spirit_copy"]["1"]["1"]
        state = self.state()
        spec, groups = artifact.spirit_drops(row, random.Random(3), state, self.config)
        self.assertEqual(spec, "")  # 器灵是实体，不发普通道具
        self.assertTrue(groups)
        self.assertEqual(len(state["qilings"]), len(groups))
        self.assertTrue(all(len(group) == 17 for group in groups))
        self.commit()
        self.assertEqual(len(values(self.success(8105))), 17 * len(groups))
        for group in groups:
            self.assertIn(str(group[1]), self.config["exclusive_device_spirit"])
        encoded = artifact.display_reward(b"", groups)
        self.assertEqual(qiling_groups(encoded), groups)

    # ---- 存档与原生 PB ----
    def test_corrupt_state_and_failed_mutations_are_atomic(self):
        with self.assertRaises(ValueError):
            artifact.get_state({"exclusive_artifact_state": {"version": 2}})
        memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        self.assert_rejected(8102, [ARTIFACT_IID, 1])
        self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))

    def test_native_lua_protobufs_parse_all_reply_shapes(self):
        lua = self.network_lua()
        for name in ("ids_pb", "combmessages_pb", "battleresult_pb", "somethings_pb"):
            lua.execute(builder.read_script(name, "pb"))
        iid = self.make_artifact(level=2)
        self.make_qiling()
        lua.globals().reply_8101 = self.success(8101, [iid])
        lua.globals().reply_8105 = self.success(8105)
        lua.globals().reply_8201 = self.success(8201)
        row = self.config["exclusive_device_spirit_copy"]["1"]["1"]
        _, groups = artifact.spirit_drops(row, random.Random(3), self.state(), self.config)
        lua.globals().reply_qiling = artifact.display_reward(b"", groups)
        result = lua.execute(b'''
            local a = ids_pb.Ids(); a:ParseFromString(reply_8101)
            local q = ids_pb.Ids(); q:ParseFromString(reply_8105)
            local c = combmessages_pb.CombMessages(); c:ParseFromString(reply_8201)
            local s = somethings_pb.SomeThings(); s:ParseFromString(reply_qiling)
            local m = 0
            for _,v in ipairs(c.messages) do m = m + 1 end
            return #a.ids, #q.ids, m, #s.qiling.ids
        ''')
        self.assertEqual(tuple(result), (12, 17, 2, 17 * len(groups)))

    def test_every_configured_copy_battle_is_supported(self):
        self.power()
        rows = [("激活", row) for group in self.config["exclusive_copy"].values() for row in group.values()]
        rows += [("器魂", row) for row in self.config["exclusive_device_soul_copy"].values()]
        rows += [("器灵", row) for group in self.config["exclusive_device_spirit_copy"].values() for row in group.values()]
        for index, (label, row) in enumerate(rows):
            with self.subTest(label=label, index=index):
                report = artifact._fight(self.session.save, row, self.config, index + 1, label)
                self.assertIn(report["result"], (0, 1))
                self.assertIn("meta", report)

    network_lua = base.ActivityCopyTests.network_lua
    strengthen = base.ActivityCopyTests.strengthen
