"""古董拍卖：临时账号、真实配置和实际客户端回调结构，不修改正式角色。"""

import copy
import random
import struct
import unittest
from unittest.mock import patch

import test_soul
from zyj_server import antique, player, protocol, recharge


def setUpModule():
    test_soul.setUpModule()


class AntiqueTests(unittest.TestCase):
    request = test_soul.SoulTests.request
    success = test_soul.SoulTests.success
    reconnect = test_soul.SoulTests.reconnect
    add_account = test_soul.SoulTests.add_account
    assert_rejected = test_soul.SoulTests.assert_rejected
    refresh = test_soul.SoulTests.refresh
    grant = test_soul.SoulTests.grant
    props = test_soul.SoulTests.props
    client_scripts = classmethod(test_soul.SoulTests.client_scripts.__func__)
    client_call = test_soul.SoulTests.client_call

    def setUp(self):
        test_soul.SoulTests.setUp(self)
        self.base = int(self.clock.return_value)
        self.save["role_state"].update(level=33, coin=200000000, gold=1000000)
        self.grant(20657, 3)

    def flat(self, body):
        return [v - (1 << 64) if v >= (1 << 63) else v for v in protocol.parse_ids_pb(body)]

    def queue(self, values):
        self.assertEqual((len(values) - 2) % 5, 0)
        return [values[i:i + 5] for i in range(2, len(values), 5)]

    def start(self, cid=20657):
        reply = self.success(1, 5410, values=[cid])
        self.refresh()
        return self.queue(self.flat(reply))

    def state(self):
        return self.save["antique_state"]

    def set_clock(self, value):
        self.clock.return_value = value

    def messages(self, body):
        messages = {}
        for name, wire, value in protocol.iter_pb_fields(body):
            if (name, wire) == (1, 2):
                messages[protocol.pb_get_varint(value, 1)] = b"".join(
                    data for sub, sub_wire, data in protocol.iter_pb_fields(value) if sub == 2)
        return messages

    def test_start_generates_persisted_monotonic_queue_and_repeated_queries_are_readonly(self):
        rounds = self.start()
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        self.assertEqual((self.props(20657), self.state()["auction"]["cid"]), (2, 20657))
        self.assertGreaterEqual(len(rounds), 2)
        self.assertEqual(rounds[-1][1], 0)
        self.assertIn(rounds[-1][3], (0, 1))
        self.assertEqual(rounds[-1][3], self.state()["auction"]["result"])
        previous_price, previous_time = 0, 0
        for index, (round_id, npc, price, judge, stamp) in enumerate(rounds[:-1], 1):
            self.assertEqual((round_id, npc, judge), (index, npc, 0))
            self.assertIn(npc, range(1, 10))
            self.assertGreaterEqual(price, previous_price)
            self.assertGreater(stamp, previous_time)
            self.assertLessEqual(price, 200000 * 12)
            previous_price, previous_time = price, stamp
        for first, second in zip(rounds, rounds[1:]):
            self.assertIn(second[4] - first[4], (4, 5))
        query = self.flat(self.success(1, 5410))
        self.assertEqual(query[:2], [1, 20657])
        self.assertEqual(self.queue(query), rounds)
        self.assertEqual((self.save, self.store.path(1).read_bytes()), (before, disk))
        self.reconnect()
        self.refresh()
        self.assertEqual(self.queue(self.flat(self.success(1, 5410))), rounds)
        self.assertEqual(self.props(20657), 2)

    def test_hammer_pays_current_bidder_and_records_only_bidded_rounds(self):
        item = antique.item_row(self.config, 20657)
        seed = next(s for s in range(2000)
                    if len(antique.start_auction(self.config, self.now, random.Random(s), item, 20657)["rounds"]) >= 3)
        with patch.object(player.random, "getrandbits", return_value=seed):
            self.start()
        rounds = self.state()["auction"]["rounds"]
        self.set_clock(rounds[1]["time"] + 1)
        before_coin = self.save["role_state"]["coin"]
        reply = self.messages(self.success(1, 5411))
        self.refresh()
        self.assertEqual(self.flat(reply[0]), [rounds[1]["npc"], 0])
        self.assertEqual(protocol.pb_get_varint(reply[1], 1), rounds[1]["price"])
        self.assertEqual(self.save["role_state"]["coin"], before_coin + rounds[1]["price"])
        self.assertIsNone(self.state()["auction"])
        flat = self.flat(self.success(1, 5412))
        self.assertEqual(flat[:4], [-1, self.state()["records"][0]["time"], 20657,
                                    self.state()["records"][0]["judge"]])
        self.assertEqual(flat[4:10], [1, rounds[0]["npc"], rounds[0]["price"],
                                      2, rounds[1]["npc"], rounds[1]["price"]])
        self.assert_rejected(5411)

    def test_hammer_before_first_bid_and_after_appraiser_arrival_are_rejected(self):
        self.start()
        self.assert_rejected(5411)
        self.set_clock(self.state()["auction"]["rounds"][-1]["time"] + 1)
        self.assert_rejected(5411)
        self.assertIsNotNone(self.state()["auction"])

    def test_appraiser_settles_once_by_rolled_result_and_fake_never_pays(self):
        item = antique.item_row(self.config, 20657)
        seeds = {}
        for seed in range(2000):
            queue = antique.start_auction(self.config, self.now, random.Random(seed), item, 20657)
            seeds.setdefault(queue["result"], seed)
        self.assertEqual(set(seeds), {0, 1})
        for result, seed in sorted(seeds.items()):
            self.set_clock(self.clock.return_value + 600)
            self.grant(20657, 1)
            with patch.object(player.random, "getrandbits", return_value=seed):
                rounds = self.start()
            last_price = self.state()["auction"]["rounds"][-1]["price"]
            before_coin = self.save["role_state"]["coin"]
            self.set_clock(rounds[-1][4] + 1)
            reply = self.flat(self.success(1, 5414))
            self.refresh()
            self.assertEqual(reply, [result])
            self.assertEqual(self.save["role_state"]["coin"], before_coin + (last_price if result else 0))
            self.assertIsNone(self.state()["auction"])
            self.assertEqual(self.state()["records"][0]["judge"], result)
            self.assertEqual(self.state()["records"][0]["rounds"][-1], [len(rounds), 0, last_price])
        self.assert_rejected(5414)

    def test_appraiser_rejects_settlement_before_arrival(self):
        self.start()
        self.set_clock(self.state()["auction"]["rounds"][-1]["time"] - 1)
        self.assert_rejected(5414)

    def test_onekey_uses_real_fast_section_and_writes_summary_record(self):
        self.grant(20657, 4)
        before_coin = self.save["role_state"]["coin"]
        row = self.config["antique_fast"]["20657"]["500000"]
        reply = self.messages(self.success(1, 5415, values=[20657, 4, 500000]))
        self.refresh()
        self.assertEqual(self.flat(reply[0]), [0, 0])
        total = protocol.pb_get_varint(reply[1], 1) or 0
        self.assertLessEqual(total, 4 * int(row["price"] * 2))
        self.assertEqual((self.props(20657), self.save["role_state"]["coin"]), (3, before_coin + total))
        record = self.state()["records"][0]
        self.assertEqual((record["num"], record["right"] + record["wrong"], record["gold"]), (4, 4, total))
        self.assertLessEqual(record["sold"], record["right"])
        flat = self.flat(self.success(1, 5412))
        self.assertEqual(flat[:9], [-2, record["time"], 20657, record["judge"], 4,
                                    record["right"], record["wrong"], record["sold"], total])
        self.assert_rejected(5415, values=[20657, 1, 10000001])
        self.assert_rejected(5415, values=[20657, 1, 499999])

    def test_onekey_price_snaps_to_nearest_real_section(self):
        for price in (500004, 900000):
            self.grant(20657, 1)
            self.success(1, 5415, values=[20657, 1, price])
            self.refresh()
            self.assertEqual(self.props(20657), 3)

    def test_gates_bad_payloads_active_auction_and_clock_rollback_are_atomic(self):
        for opcode in antique.OPCODES:
            for raw in (b"\x08", b"\x10\x01", b"\x0a\x00", b"\x08\xff\xff\xff\xff\x7f"):
                self.assert_rejected(opcode, raw=raw)
        for opcode, values in ((5410, [20657, 20658]), (5411, [1]), (5412, [1]), (5413, [1]),
                               (5414, [1]), (5415, [20657]), (5415, [20657, 1, 500000, 4]),
                               (5410, [20658]), (5410, [20659]), (5410, [20660]),
                               (5415, [20658, 1, 1500000])):
            self.assert_rejected(opcode, values=values)
        self.save["role_state"]["level"] = 32
        self.assert_rejected(5410, values=[20657])
        self.save["role_state"]["level"] = 33
        player.change_item_count(self.save, 20657, -self.props(20657), self.config, self.now)
        self.assert_rejected(5410, values=[20657])
        self.grant(20657, 2)
        self.start()
        self.assertEqual(self.props(20657), 1)
        self.assert_rejected(5410, values=[20657])
        self.assert_rejected(5415, values=[20657, 1, 500000])
        self.set_clock(self.base - 1)
        self.assert_rejected(5411)
        self.assert_rejected(5414)
        self.assert_rejected(5415, values=[20657, 1, 500000])
        self.set_clock(self.base)

    def test_failed_saves_and_same_connection_retries_never_consume_twice(self):
        player.change_item_count(self.save, 20657, -self.props(20657), self.config, self.now)
        self.grant(20657, 2)
        for opcode, values in ((5410, [20657]), (5415, [20657, 1, 500000])):
            session = self.sessions[1]
            memory, disk = copy.deepcopy(session.save), self.store.path(1).read_bytes()
            with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
                self.request(1, opcode, values=values)
            self.assertEqual((session.save, self.store.path(1).read_bytes()), (memory, disk))
        with patch.object(player.random, "getrandbits", return_value=7):
            reply = self.request(1, 5410, values=[20657])
        self.refresh()
        self.assertEqual(self.props(20657), 1)
        retried = self.sessions[1].handle(5410, self.seq, recharge.ids([20657]))
        self.assertEqual([(struct.unpack(">IIII", packet[:16])[2], packet[16:]) for packet in retried], reply)
        self.assertEqual(self.props(20657), 1)

    def test_state_corruption_and_disabled_special_npc_config_fail_closed(self):
        for state in (None, [], {"checked_at": "x"}, {"checked_at": -1}, {"records": 5},
                      {"checked_at": 0, "records": [], "auction": {"rounds": []}},
                      {"checked_at": 0, "records": [1]},
                      {"checked_at": 0, "records": [{"time": 0, "cid": 20657, "judge": 0,
                                                     "num": 2, "right": 1, "wrong": 0, "sold": 0, "gold": 0}]}):
            with self.assertRaises(ValueError):
                antique.get_state({**self.save, "antique_state": state}, self.config)
        config = copy.deepcopy(self.config)
        config["antique_npc"]["1"]["extraDropPro"] = 0.5
        with self.assertRaisesRegex(ValueError, "特殊NPC"):
            antique.validate_config(config)
        config = copy.deepcopy(self.config)
        config["antique_item"]["20657"]["coinID"] = 1002
        with self.assertRaisesRegex(ValueError, "古董条目"):
            antique.validate_config(config)
