"""通天塔 7010–7019 的真实协议、战斗、次数、奖励与客户端 PB 回环。"""

from contextlib import redirect_stdout
import copy
import io
import json
from pathlib import Path
import struct
import tempfile
import unittest
from unittest.mock import patch

import build_local_apk as builder
import test_activity_copy as base
from zyj_server import babel_tower, formation, game_helper, pending_features, player, protocol, recharge
from zyj_server.session import Session

NOW = 1800172800


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


class BabelTowerTests(unittest.TestCase):
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
        self.give(1025, 10000)

    def reconnect(self):
        return Session(self.tables, self.path, self.steps, self.config)

    strengthen = base.ActivityCopyTests.strengthen
    network_lua = base.ActivityCopyTests.network_lua

    def call(self, opcode, values=(), seq=181, raw=None):
        return self.session.handle(opcode, seq, raw if raw is not None else recharge.ids(values))

    def success(self, opcode, values=(), seq=181, raw=None):
        packets = self.call(opcode, values, seq=seq, raw=raw)
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], opcode, packets)
        return packets[0][16:]

    def assert_rejected(self, opcode, values=(), *, raw=None):
        memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        packets = self.session.handle(opcode, 200, raw if raw is not None else recharge.ids(values))
        self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets], [999999, 1999])
        self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))

    def give(self, cid, count):
        player.change_item_count(self.session.save, cid, count, self.config, NOW)
        self.path.write_text(json.dumps(self.session.save))

    def state(self):
        return babel_tower.get_state(self.session.save, self.config)

    def test_query_is_real_ten_field_status_and_read_only(self):
        values = protocol.parse_ids_pb(self.success(7011))
        self.assertEqual(len(values), babel_tower.STATUS_FIELDS)
        self.assertEqual(values, [1, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        before = copy.deepcopy(self.session.save)
        self.assertEqual(protocol.parse_ids_pb(self.call(7011)[0][16:]), values)
        self.assertEqual(self.session.save, before)
        self.assertNotIn(7011, pending_features.QUERIES)

    def test_level_query_returns_seven_values_per_configured_level(self):
        values = protocol.parse_ids_pb(self.success(7012, [1]))
        self.assertEqual(len(values), 7 * len(self.config["tongtianta_guaiwu"]["1"]))
        self.assertEqual(values[:7], [0, 0, 0, 0, 0, 0, 0])
        self.assertEqual(self.state()["cur_point"], 1)
        self.assert_rejected(7012, [7])

    def test_buy_times_only_routes_sysid_450_and_charges_config_price(self):
        gold = self.session.save["role_state"]["g_gold"]
        self.success(7010, [450, 1])
        price = int(self.config["buycount_price"]["1"]["tongtianta_goumai_jiage"])
        self.assertEqual(self.session.save["role_state"]["g_gold"], gold - price)
        self.assertEqual(self.state()["bought"], 1)
        self.assertEqual(protocol.parse_ids_pb(self.success(7011))[3], 1)
        self.assert_rejected(7010, [463, 1])

    def test_battle_uses_real_report_stars_and_permanent_daily_state(self):
        self.strengthen()
        self.success(7012, [1])
        packets = self.call(7013, [1], seq=191)
        parts = messages(packets[0][16:])
        self.assertEqual(set(parts), {0, 1})
        row = self.state()["levels"]["1"][0]
        self.assertEqual(protocol.parse_ids_pb(parts[0]), [row["used"], *row["stars"], row["daily"], row["first"], row["auto"]])
        fields = {n: v for n, w, v in protocol.iter_pb_fields(parts[1])}
        self.assertEqual(fields[1], 1)
        report = json.loads(next(v for n, w, v in protocol.iter_pb_fields(parts[1]) if (n, w) == (5, 2)))
        self.assertTrue(report["result"])
        self.assertEqual(row["stars"], [1, 1, 1])
        # 私服规则取消全局挑战次数上限：全局 used 恒为 0，单关 row["used"] 仍按真实挑战递增。
        self.assertEqual((row["daily"], row["first"], self.state()["used"]), (1, 1, 0))
        self.assertEqual(row["used"], 1)
        self.assertEqual(self.session.save["last_babel_tower_battle"]["stars"], [1, 1, 1])
        # 私服规则：已通关关卡可复战且不再计全局次数，但不重复首通/当日奖励。
        repeat = self.call(7013, [1], seq=192)
        self.assertEqual(struct.unpack(">IIII", repeat[0][:16])[2], 7013)
        self.assertEqual(self.state()["used"], 0)
        self.assertEqual(self.state()["levels"]["1"][0]["used"], 1)
        self.assertEqual(self.state()["levels"]["1"][0]["first"], 1)
        self.session = self.reconnect()
        self.assertEqual(self.state()["levels"]["1"][0]["stars"], [1, 1, 1])

    def test_every_configured_breakthrough_can_reach_real_battle(self):
        self.strengthen()
        state = self.state()
        state["cur_point"] = 1
        for row in state["levels"]["1"][:7]:
            row["stars"] = [1, 1, 1]
            row["daily"] = 1
        self.success(7012, [1])
        # 第 8 关的 30166/10550 break9=9000291 带引擎尚不支持的 ap/target=6，
        # sanitize_breakthrough 必须收敛突破等级而不是整关拒绝。
        packets = self.call(7013, [8], seq=195)
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 7013, packets)
        self.assertTrue(json.loads(next(v for n, w, v in protocol.iter_pb_fields(
            messages(packets[0][16:])[1]) if (n, w) == (5, 2)))["rules"])

    def test_chapter_award_requires_full_three_star_and_is_claimed_once(self):
        state = self.state()
        for row in state["levels"]["1"]:
            row["stars"] = [1, 1, 1]
        babel_tower.refresh_progress(state, self.config, 1)
        self.assertEqual(state["awards"][0], 1)
        reward = self.success(7015, [1])
        self.assertTrue(reward)
        self.assertEqual(self.state()["awards"][0], 2)
        self.assertEqual(protocol.parse_ids_pb(self.success(7011))[4], 2)
        self.assert_rejected(7015, [1])

    def test_sweep_returns_one_somethings_per_three_star_level(self):
        self.give(20809, 100)
        state = self.state()
        state["cur_point"] = 1
        for index, row in enumerate(state["levels"]["1"][:3], 1):
            row["stars"] = [1, 1, 1]
        parts = messages(self.success(7016))
        self.assertEqual(len(parts), 3)
        self.assertTrue(all(parts[index] for index in parts))
        rows = self.state()["levels"]["1"]
        self.assertTrue(all(row["daily"] for row in rows[:3]))
        self.assertEqual(rows[0]["auto"], 1)
        self.assert_rejected(7016)

    def test_shop_query_and_purchase_use_config_currency_and_limit(self):
        self.give(20809, 1000)
        values = protocol.parse_ids_pb(self.success(7017))
        self.assertEqual(len(values), 1 + len(self.config["tongtianta_shangdian"]))
        self.assertEqual(values[0], 1)
        before = formation.records(bytes.fromhex(self.session.save["world_state"]["1200"]), 1, 1)
        count = protocol.pb_get_varint(before.get(20809, b""), 2) or 0
        reward = self.success(7018, [1, 1])
        self.assertTrue(reward)
        after = formation.records(bytes.fromhex(self.session.save["world_state"]["1200"]), 1, 1)
        self.assertEqual((protocol.pb_get_varint(after.get(20809, b""), 2) or 0),
                         count - int(self.config["tongtianta_shangdian"]["1"]["num"].split(",")[1].rstrip(";")))
        self.assertEqual(self.state()["shop"]["1"], 1)
        self.assert_rejected(7018, [999, 1])

    def test_rank_reply_parses_with_native_lua_protobufs(self):
        lua = self.network_lua()
        for name in ("combmessages_pb", "params_pb", "players_pb"):
            lua.execute(builder.read_script(name, "pb"))
        lua.globals().reply_7019 = self.success(7019, [0])
        result = lua.execute(b'''
            local comb = combmessages_pb.CombMessages(); comb:ParseFromString(reply_7019)
            local ids, players = nil, 0
            for k,v in ipairs(comb.messages) do
                if v.id == 0 then ids = ids_pb.Ids(); ids:ParseFromString(v.data) end
                if v.id == 1 then local p = players_pb.Players(); p:ParseFromString(v.data); players = #p.players end
            end
            return #ids.ids, players
        ''')
        self.assertEqual(tuple(result), (2, 1))

    def test_helper_reports_real_tower_rows_and_supports_activity_15(self):
        self.assertIn((3, 15), game_helper.SUPPORTED)
        state = self.state()
        state["used"] = 2
        state["levels"]["1"][0]["stars"] = [1, 1, 1]
        save = copy.deepcopy(self.session.save)
        save.setdefault("guide", {}).setdefault("sections", {})["1"] = {"status": 2}
        parts = messages(game_helper.query(save, self.config, NOW))
        values = protocol.parse_ids_pb(parts[3])
        self.assertEqual(len(values), 15 * 8)
        self.assertEqual(values[14 * 8:15 * 8], [15, 2, 1, 0, 0, 0, 0, 0])
        self.assertEqual(self.session.save["babel_tower_state"]["used"], 2)

    def test_day_rollover_resets_daily_counters_but_keeps_awards(self):
        state = self.state()
        state["day"] = (NOW + 28800) // 86400 - 1
        state["used"], state["bought"], state["awards"][0] = 2, 1, 2
        state["levels"]["1"][0].update(used=3, daily=1, auto=1)
        self.path.write_text(json.dumps(self.session.save))
        self.clock.return_value += 86400
        self.session = self.reconnect()
        values = protocol.parse_ids_pb(self.success(7011))
        self.assertEqual(values[:4], [1, 0, 0, 0])
        self.assertEqual(values[4], 2)
        self.assertEqual(self.state()["levels"]["1"][0]["daily"], 0)

    def test_invalid_mutations_never_write_save(self):
        self.assert_rejected(7013, [2])
        self.assert_rejected(7015, [1])
        self.assert_rejected(7016)
        self.assert_rejected(7018, [1, 0])
        self.assert_rejected(7019, [2])
        self.assert_rejected(7011, [1])


if __name__ == "__main__":
    unittest.main()
