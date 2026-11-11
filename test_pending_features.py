"""未开放玩法只读状态：真实协议/配置回包，不发奖、不写存档。"""

import copy
import unittest

import build_local_apk as builder
import test_activity_copy
import test_soul
from zyj_server import pending_features, player, protocol


def setUpModule():
    test_soul.setUpModule()


class PendingFeatureTests(unittest.TestCase):
    request = test_soul.SoulTests.request
    success = test_soul.SoulTests.success
    assert_rejected = test_soul.SoulTests.assert_rejected
    refresh = test_soul.SoulTests.refresh
    add_account = test_soul.SoulTests.add_account
    reconnect = test_soul.SoulTests.reconnect

    def setUp(self):
        test_soul.SoulTests.setUp(self)

    def comb(self, body):
        return {mid: data for mid, data in protocol.get_comb_messages(body)}

    def test_every_previously_unrouted_query_gets_native_reply(self):
        for opcode in pending_features.QUERIES:
            with self.subTest(opcode=opcode):
                packets = self.request(1, opcode)
                self.assertEqual(packets[0][0], opcode, packets)
                self.assertNotIn(999999, [mid for mid, _ in packets])

    def test_mini_game_reports_closed_state_and_empty_grid(self):
        values = protocol.parse_ids_pb(self.success(1, 1600))
        self.assertEqual(values, [0] * pending_features.MINI_GAME_FIELDS)
        self.assertEqual(values[7], 0)  # state：活动未开启

    def test_dew_pool_reports_every_real_config_row_as_unreached(self):
        groups = self.comb(self.success(1, 8055))
        self.assertEqual(set(groups), {1, 2, 3})
        achievement = protocol.parse_ids_pb(groups[1])
        task = protocol.parse_ids_pb(groups[2])
        shop = protocol.parse_ids_pb(groups[3])
        expected_achievement = sorted((int(group), int(row))
                                      for group, rows in self.config["dew_pool_achievement"].items() for row in rows)
        expected_task = sorted((int(group), int(row))
                               for group, rows in self.config["dew_pool_task"].items() for row in rows)
        self.assertEqual([(achievement[i], achievement[i + 1]) for i in range(0, len(achievement), 3)],
                         expected_achievement)
        self.assertEqual(achievement[2::3], [0] * len(expected_achievement))
        self.assertEqual([(task[i], task[i + 1]) for i in range(0, len(task), 4)], expected_task)
        self.assertEqual(task[2::4], [0] * len(expected_task))
        self.assertEqual(task[3::4], [0] * len(expected_task))
        self.assertEqual(shop, [0] * len(self.config["dew_pool_shop"]))

    def test_status_queries_report_zero_progress_without_free_rewards(self):
        self.assertNotIn(7011, pending_features.QUERIES)
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 4702)), [0] * pending_features.WORLD_WAR_FIELDS)
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 8120)), [1])
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 8122)), [1])
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 8250)), [0])
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 8251)),
                         [0] * pending_features.GOD_COMPETITION_FIELDS)
        rows = [value for field, wire, value in protocol.iter_pb_fields(self.success(1, 4820))
                if (field, wire) == (1, 2)]
        self.assertEqual(len(rows), pending_features.MANOR_FIELDS)
        self.assertEqual(list(rows[:2]), [b"\x12\x00", b"\x12\x00"])  # 空名称/公告
        self.assertTrue(all(row == b"\x08\x00" for row in rows[2:]))

    def test_queries_reject_parameters_without_changing_save(self):
        for opcode in pending_features.QUERIES:
            with self.subTest(opcode=opcode):
                self.assert_rejected(opcode, values=[1])

    def test_queries_are_read_only_and_idempotent(self):
        first = {opcode: self.success(1, opcode) for opcode in pending_features.QUERIES}
        before = copy.deepcopy(self.sessions[1].save)
        disk = self.store.path(1).read_bytes()
        second = {opcode: self.success(1, opcode) for opcode in pending_features.QUERIES}
        self.assertEqual(first, second)
        self.refresh()
        self.assertEqual(self.sessions[1].save, before)
        self.assertEqual(self.store.path(1).read_bytes(), disk)

    def test_comb_submessages_are_filled_by_recorded_response(self):
        inner = protocol.encode_pb_field(1, 0, 1600) + protocol.encode_pb_field(2, 2, b"")
        body = protocol.encode_pb_field(1, 2, inner)
        out = player.prepare_recorded_response(999900, body, {}, body, {}, self.config, self.now)
        self.assertEqual(self.comb(out)[1600], pending_features.reply(1600, b"", self.config))

    def test_client_field_counts_match_replies(self):
        scripts = {name: builder.read_script(name).decode("utf-8")
                   for name in ("GameMiniGames", "GameGodCompetition_main")}
        self.assertIn("idsData.ids[10+i]", scripts["GameMiniGames"])
        self.assertIn("for i=1,16 do", scripts["GameMiniGames"])
        self.assertIn("idsdata.ids[24]", scripts["GameGodCompetition_main"])
        gamedata = builder.read_script("gamedata").decode("utf-8")
        start = gamedata.index("function gamedata.CangjinggeData(")
        self.assertIn("data[3*i+8]", gamedata[start:start + 1200])
        self.assertIn("for i = 1,5 do", gamedata[start:start + 1200])

    def test_native_lua_protobufs_parse_every_reply_shape(self):
        lua = test_activity_copy.ActivityCopyTests.network_lua(self)
        for name in ("combmessages_pb", "params_pb"):
            lua.execute(builder.read_script(name, "pb"))
        lua.globals().reply_1600 = self.success(1, 1600)
        lua.globals().reply_8055 = self.success(1, 8055)
        lua.globals().reply_4820 = self.success(1, 4820)
        result = lua.execute(b'''
            local ids = ids_pb.Ids(); ids:ParseFromString(reply_1600)
            local comb = combmessages_pb.CombMessages(); comb:ParseFromString(reply_8055)
            local params = params_pb.ParamS(); params:ParseFromString(reply_4820)
            return #ids.ids, #comb.messages, #params.params
        ''')
        self.assertEqual(tuple(result), (26, 3, 23))


if __name__ == "__main__":
    unittest.main()
