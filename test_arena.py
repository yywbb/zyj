from contextlib import redirect_stdout
import copy
import io
import json
from pathlib import Path
import struct
import tempfile
import unittest
from unittest.mock import patch
import zipfile

import build_local_apk as builder
from zyj_server import activities, arena, battle, formation, guide, pets, player, protocol, recharge, replay
from zyj_server.session import Session


ROOT = Path(__file__).parent
NOW = 1800172800


class ArenaTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with redirect_stdout(io.StringIO()), tempfile.TemporaryDirectory() as directory, patch("time.time", return_value=NOW):
            cls.config = player.load_role_config(ROOT / "configs_sec5.zip")
            cls.steps = guide.load_guide_step_counts(ROOT / "configs_sec5.zip")
            frames = replay.load_recordings(ROOT / "recorded_frames.json")
            cls.tables = replay.build_routing_tables(frames)
            session = Session(cls.tables, Path(directory) / "role_save.json", cls.steps, cls.config)
            for frame in replay.split_recordings(frames)[0]:
                if frame["c2s"] and frame["opcode"] != 1000:
                    session.handle(frame["opcode"], frame["seq"], bytes.fromhex(frame["hex"]))
            cls.baseline = copy.deepcopy(session.save)
        cls.baseline["role_state"].update(level=23, nextexp=cls.config["role_exp"]["23"]["nextexp"])

    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.path = Path(temporary.name) / "role_save.json"
        self.path.write_text(json.dumps(self.baseline))
        clock = patch("time.time", return_value=NOW)
        self.clock = clock.start()
        self.addCleanup(clock.stop)
        quiet = redirect_stdout(io.StringIO())
        quiet.__enter__()
        self.addCleanup(quiet.__exit__, None, None, None)
        self.session = self.reconnect()

    def reconnect(self):
        return Session(self.tables, self.path, self.steps, self.config)

    def call(self, opcode, values=(), seq=181):
        return self.session.handle(opcode, seq, recharge.ids(values))

    def query(self):
        packet = self.call(1610)[0]
        self.assertEqual(struct.unpack(">IIII", packet[:16])[2], 1610)
        fields = list(protocol.iter_pb_fields(packet[16:]))
        mine = next(v for n, w, v in fields if (n, w) == (1, 2))
        rows = {protocol.pb_get_varint(v, 1): v for n, w, v in fields if (n, w) == (2, 2)}
        return mine, rows

    def strengthen(self, *, weak=False):
        world = bytes.fromhex(self.session.save["world_state"]["1002"])
        for raw in formation.records(world, 1, 2).values():
            for field, value in ((6, 1 if weak else 10000000), (7, 0), (8, 1 if weak else 10000000), (9, 1 if weak else 1000)):
                raw = protocol.pb_set_varint(raw, field, value)
            player.record_slot_update(self.session.save, protocol.encode_pb_field(1, 2, raw))
        self.path.write_text(json.dumps(self.session.save))

    def report(self, packets):
        return json.loads(next(v for n, w, v in protocol.iter_pb_fields(packets[0][16:]) if (n, w) == (5, 2)))

    def assert_rejected(self, opcode, body):
        memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
        packets = self.session.handle(opcode, 200, body)
        self.assertEqual([struct.unpack(">IIII", p[:16])[2] for p in packets], [999999, 1999])
        self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))

    def prop_count(self, save, cid):
        fragment = self.config["general_fragment"].get(str(cid))
        key = "1012" if fragment else "1107" if str(cid) in self.config["equip_fragment"] else "1200"
        if fragment:
            cid = fragment["general"]
        props = formation.records(bytes.fromhex(save["world_state"][key]), 1, 1)
        return protocol.pb_get_varint(props.get(cid, b""), 2) or 0

    def test_entry_and_first_rank_queries_return_live_empty_account_state(self):
        before = copy.deepcopy(self.session.save)
        mine, rows = self.query()
        self.assertEqual([protocol.pb_get_varint(mine, n) for n in range(1, 5)], [0, 5364, 23, 5])
        self.assertTrue(set(range(1, 11)) <= rows.keys())
        self.assertEqual(protocol.pb_get_varint(rows[5364], 4), 4)
        for rank, row in rows.items():
            if rank != 5364:
                name = next(v for n, w, v in protocol.iter_pb_fields(row) if n == 2).decode()
                self.assertTrue(name.startswith("NPC"))
                self.assertGreater(protocol.pb_get_varint(row, 5), 2146483648)
        packet = self.call(1615)[0]
        self.assertEqual(struct.unpack(">IIII", packet[:16])[2], 1615)
        self.assertEqual(protocol.parse_ids_pb(packet[16:]), [0] * 9)
        self.assertEqual(protocol.parse_ids_pb(self.call(1613)[0][16:]), [0] * 17)
        for key in ("guide", "world_state", "role_state", "protagonist_snapshot"):
            self.assertEqual(self.session.save[key], before[key])
        self.session = self.reconnect()
        self.assertEqual(protocol.pb_get_varint(self.query()[0], 2), 5364)

    def test_victory_uses_current_team_and_commits_rank_points_and_first_prizes_once(self):
        self.query()
        self.strengthen()
        state = self.session.save["arena_state"]
        state["rank"] = 2100
        target = min(arena.opponents(2100, self.config))
        before = copy.deepcopy(self.session.save)
        packets = self.call(1611, [target])
        report = self.report(packets)
        self.assertTrue(report["result"])
        attack, defense = arena.rosters(before, self.config["athletics_copy2"][str(target)], self.config)
        expected = battle.simulate(attack, defense, self.config, report["seed"], attack_pet=pets.combat(before, self.config))
        self.assertEqual(report["b"], expected["b"])
        self.assertEqual(report["endmeta"], expected["endmeta"])
        self.assertEqual(state, before["arena_state"])  # Session 发布工作副本，不改旧对象。
        state = self.session.save["arena_state"]
        self.assertEqual((state["rank"], state["points"], state["used"]), (target, 20, 1))
        self.assertEqual(set(state["first"]), {108, 109})
        self.assertEqual(self.session.save["role_state"]["gold"] - before["role_state"]["gold"], 150)
        for key in ("guide", "world_state", "protagonist_snapshot", "last_battle"):
            self.assertEqual(self.session.save.get(key), before.get(key))
        for key in ("coin", "stamina", "energy", "exp", "level", "power"):
            self.assertEqual(self.session.save["role_state"][key], before["role_state"][key])
        saved = copy.deepcopy(self.session.save)
        self.assertEqual(self.call(1611, [target]), packets)
        self.assertEqual(self.session.save, saved)
        self.session = self.reconnect()
        self.assertEqual(protocol.parse_ids_pb(self.call(1615)[0][16:]), [0] * 7 + [1, 1])
        self.assertEqual(protocol.pb_get_varint(self.query()[0], 1), 20)
        lower = max(arena.opponents(target, self.config))
        self.call(1611, [lower], seq=182)
        self.assertEqual(self.session.save["role_state"]["gold"], saved["role_state"]["gold"])
        self.assertEqual(self.session.save["arena_state"]["rank"], target)
        self.assertEqual(self.session.save["arena_state"]["points"], 40)

    def test_losses_consume_real_attempts_without_rewards_rank_or_campaign_changes(self):
        self.query()
        self.strengthen(weak=True)
        before = copy.deepcopy(self.session.save)
        for seq in range(181, 186):
            packets = self.call(1611, [5363], seq=seq)
            self.assertFalse(self.report(packets)["result"])
        state = self.session.save["arena_state"]
        self.assertEqual((state["rank"], state["points"], state["used"]), (5364, 0, 5))
        self.assert_rejected(1611, recharge.ids([5363]))
        for key in ("guide", "world_state", "role_state", "protagonist_snapshot"):
            self.assertEqual(self.session.save[key], before[key])
        self.session = self.reconnect()
        self.assertEqual(protocol.pb_get_varint(self.query()[0], 4), 0)

    def test_daily_reward_and_counters_settle_once_without_offline_catchup_or_rollback(self):
        self.query()
        state = self.session.save["arena_state"]
        state.update(rank=4000, used=4, exchanged={"13": 10})
        before = copy.deepcopy(self.session.save)
        prizes = {int(cid): int(num) for cid, num in (entry.split(",") for entry in self.config["athletics_rewards"]["4000"]["day"].strip(";").split(";"))}
        self.clock.return_value = NOW + 86400
        self.call(300)
        self.assertEqual(self.session.save["arena_state"], state)
        packets = self.call(1610)
        state = self.session.save["arena_state"]
        self.assertEqual((state["used"], state["bought"], state["boss"], state["exchanged"]), (0, 0, 0, {}))
        self.assertEqual(state["points"], prizes[1005])
        self.assertEqual(self.session.save["role_state"]["coin"] - before["role_state"]["coin"], prizes[1000])
        self.assertIn(1001, [struct.unpack(">IIII", p[:16])[2] for p in packets])
        self.session = self.reconnect()
        self.query()
        self.assertEqual(self.session.save["arena_state"]["points"], prizes[1005])
        self.clock.return_value = NOW + 6 * 86400
        self.query()
        self.assertEqual(self.session.save["arena_state"]["points"], prizes[1005] * 2)
        saved = copy.deepcopy(self.session.save["arena_state"])
        self.clock.return_value = NOW
        self.query()
        self.assertEqual(self.session.save["arena_state"], saved)
        self.assert_rejected(1611, recharge.ids([3999]))
        self.assert_rejected(1614, recharge.ids([13, 1]))
        self.assert_rejected(301, recharge.ids([1, 1, 50]))

    def test_exchange_uses_points_not_inventory_and_enforces_prices_limits_and_level(self):
        self.query()
        player.change_item_count(self.session.save, 1005, 10000, self.config, NOW)
        before = copy.deepcopy(self.session.save)
        packets = self.call(1614, [13, 2])
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 1614)
        self.assertEqual(self.session.save["arena_state"]["points"], 9000)
        self.assertEqual(self.prop_count(self.session.save, 27040) - self.prop_count(before, 27040), 2)
        self.assertEqual(self.prop_count(self.session.save, 1005), 0)
        self.assertEqual(self.call(1614, [13, 2]), packets)
        self.session = self.reconnect()
        self.assertEqual(protocol.parse_ids_pb(self.call(1613)[0][16:])[12], 2)
        self.assert_rejected(1614, recharge.ids([13, 9]))
        self.assert_rejected(1614, recharge.ids([1, 1]))
        self.session.save["arena_state"]["points"] = 499
        self.assert_rejected(1614, recharge.ids([13, 1]))
        self.clock.return_value = NOW + 86400
        self.assertEqual(protocol.parse_ids_pb(self.call(1613)[0][16:]), [0] * 17)
        self.assertEqual(self.session.save["arena_state"]["points"], 499)

    def test_every_configured_shop_reward_and_first_rank_prize_is_supported(self):
        self.query()
        self.session.save["role_state"]["level"] = 150
        self.session.save["arena_state"]["points"] = 10000000
        for item, row in self.config["athletics_rewards2"].items():
            packets = self.call(1614, [int(item), row["limit"]], seq=200 + int(item))
            self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 1614, item)
            self.assertEqual(self.session.save["arena_state"]["exchanged"][item], row["limit"])
        self.assertEqual(self.prop_count(self.session.save, 201901), 1)
        self.assertEqual(self.prop_count(self.session.save, 202105), 50)
        self.session = self.reconnect()
        self.assertEqual(self.prop_count(self.session.save, 201901), 1)
        self.assertEqual(self.prop_count(self.session.save, 202105), 50)
        self.strengthen()
        self.session.save["arena_state"].update(rank=2)
        before = self.session.save["role_state"]["gold"]
        self.call(1611, [1], seq=230)
        self.assertEqual(protocol.parse_ids_pb(self.call(1615)[0][16:]), [1] * 9)
        self.assertEqual(self.session.save["role_state"]["gold"] - before, 2950)
        self.assert_rejected(1611, recharge.ids([1]))

    def test_purchased_attempts_require_current_quote_vip_cap_and_real_gold(self):
        self.query()
        self.session.save["role_state"].update(vip=0, gold=1000)
        self.session.save["arena_state"]["used"] = 5
        packets = self.call(301, [1, 1, 50])
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 301)
        self.assertEqual(self.session.save["role_state"]["gold"], 950)
        self.assertEqual(protocol.pb_get_varint(self.query()[0], 4), 3)
        self.assertEqual(protocol.parse_ids_pb(self.call(300)[0][16:])[0], 1)
        self.assertEqual(self.call(301, [1, 1, 50]), packets)
        self.assert_rejected(301, recharge.ids([1, 1, 50]))  # 同内容新序号仍受日上限约束。
        self.session = self.reconnect()
        self.assertEqual(self.session.save["arena_state"]["bought"], 1)
        self.clock.return_value = NOW + 86400
        self.session.save["role_state"].update(vip=2, gold=1000)
        self.assertEqual(protocol.parse_ids_pb(self.call(300)[0][16:])[0], 0)
        self.assert_rejected(301, recharge.ids([1, 2, 50]))
        packets = self.call(301, [1, 2, 100], seq=182)
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 301)
        self.assertEqual(protocol.pb_get_varint(self.query()[0], 4), 11)
        self.assertEqual(self.session.save["role_state"]["gold"], 900)
        self.session.save["role_state"]["gold"] = 0
        self.assert_rejected(301, recharge.ids([1, 1, 100]))

    def test_bull_demon_king_rank_caps_losses_rewards_and_forward_daily_reset(self):
        self.query()
        self.strengthen(weak=True)
        self.assert_rejected(1616, b"")
        self.session.save["arena_state"]["rank"] = 5
        packets = self.call(1616)
        self.assertFalse(self.report(packets)["result"])
        state = self.session.save["arena_state"]
        self.assertEqual((state["used"], state["boss"], state["points"]), (1, 1, 0))
        self.assert_rejected(1616, b"")
        self.clock.return_value = NOW + 86400
        self.query()
        self.strengthen()
        self.session.role_config = copy.deepcopy(self.config)
        self.session.role_config["athletics_npc"]["50001"]["dropprob"] = 1
        before = copy.deepcopy(self.session.save)
        packets = self.call(1616, seq=182)
        self.assertTrue(self.report(packets)["result"])
        self.assertEqual(self.session.save["arena_state"]["points"] - before["arena_state"]["points"], 100)
        self.assertEqual(self.session.save["role_state"]["coin"] - before["role_state"]["coin"], 50000)
        self.assertEqual(self.prop_count(self.session.save, 11510) - self.prop_count(before, 11510), 1)
        self.assertEqual(self.call(1616, seq=182), packets)
        self.assertEqual(protocol.parse_ids_pb(self.call(300)[0][16:])[19], 1)
        self.session = self.reconnect()
        self.assert_rejected(1616, b"")
        self.session.save["arena_state"]["rank"] = 1
        for seq in range(183, 187):
            self.call(1616, seq=seq)
        self.assertEqual(self.session.save["arena_state"]["boss"], 5)
        self.assert_rejected(1616, b"")

    def test_invalid_stale_legacy_and_comb_requests_never_change_saves(self):
        for opcode in arena.OPCODES:
            for body in (b"\x08", b"\x10\x01", b"\x0a\x00", recharge.ids([0]), recharge.ids([1, 1, 1]), recharge.ids([1 << 31])):
                with self.subTest(opcode=opcode, body=body.hex()):
                    self.assert_rejected(opcode, body)
        for rank in (0, 1, 10, 5364, 999999):
            self.assert_rejected(1611, recharge.ids([rank]))
        for values in ([], [13], [13, 0], [13, 101], [999, 1]):
            self.assert_rejected(1614, recharge.ids(values))
        for values in ([1], [1, 1], [1, 0, 0], [1, 1, 0], [1, 1, 50, 0]):
            self.assert_rejected(301, recharge.ids(values))
        for opcode in (1600, 1601, 1603, 1604, 1605, 1606, 1607, 1608, 1612):
            self.assert_rejected(opcode, b"")
        comb = b"".join(protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, opcode)) for opcode in (1610, 1613))
        self.assert_rejected(999900, comb)
        self.session.save["role_state"]["level"] = 11
        self.assert_rejected(1610, b"")
        self.session.save["has_role"] = False
        self.assert_rejected(1611, recharge.ids([5363]))

    def test_save_failure_and_overflow_do_not_publish_partial_transactions(self):
        self.strengthen()
        for opcode, values in ((1610, []), (1613, []), (1615, []), (1611, [5363]), (1614, [13, 1]), (301, [1, 1, 50])):
            self.session.save["arena_state"]["points"] = 1000
            memory, disk = copy.deepcopy(self.session.save), self.path.read_bytes()
            with self.subTest(opcode=opcode), patch.object(player.os, "replace", side_effect=OSError("disk full")), self.assertRaises(OSError):
                self.call(opcode, values)
            self.assertEqual((self.session.save, self.path.read_bytes()), (memory, disk))
            self.assertEqual(self.session.random_replies, {})
        self.session.save["arena_state"]["points"] = (1 << 31) - 1
        self.assert_rejected(1611, recharge.ids([5363]))
        self.query()
        self.session.save["arena_state"]["rank"] = 4000
        self.session.save["role_state"]["coin"] = (1 << 31) - 1
        self.clock.return_value = NOW + 86400
        self.assert_rejected(1610, b"")

    def test_corrupt_state_is_rejected_before_a_daily_reset_and_accounts_stay_isolated(self):
        for changes in ({"day": -1}, {"rank": 0}, {"rank": 5365}, {"points": True}, {"used": 6},
                        {"boss": 1}, {"first": [109]}, {"first": [999]}, {"exchanged": {"13": 11}}, {"exchanged": {"99": 1}}):
            saved = copy.deepcopy(self.baseline)
            saved["arena_state"].update(changes)
            self.path.write_text(json.dumps(saved))
            disk = self.path.read_bytes()
            with self.subTest(changes=changes), self.assertRaisesRegex(ValueError, "竞技场"):
                self.reconnect()
            self.assertEqual(self.path.read_bytes(), disk)
        self.path.write_text(json.dumps(self.baseline))
        self.session = self.reconnect()
        other_path = self.path.with_name("other_role.json")
        other_path.write_text(json.dumps(self.baseline))
        other = Session(self.tables, other_path, self.steps, self.config)
        before = copy.deepcopy(other.save), other_path.read_bytes()
        self.strengthen()
        self.call(1611, [5363])
        self.assertEqual((other.save, other_path.read_bytes()), before)

    def test_all_5363_npc_rosters_and_68_distinct_teams_use_supported_real_combat(self):
        before = copy.deepcopy(self.session.save)
        seen = set()
        for rank in range(1, 5364):
            row = self.config["athletics_copy2"][str(rank)]
            attack, defense = arena.rosters(self.session.save, row, self.config)
            for i, pos in enumerate(battle.POSITIONS, 1):
                if row[f"p{i}"]:
                    self.assertEqual(defense[pos]["cid"], self.config["copy_monster"][str(row[f"p{i}"])]["generalid"])
            signature = tuple((row[f"p{i}"], row[f"break{i}-correct"]) for i in range(1, 8))
            if signature not in seen:
                inputs = copy.deepcopy((attack, defense))
                result = battle.simulate(attack, defense, self.config, 7)
                self.assertEqual(result, battle.simulate(attack, defense, self.config, 7))
                self.assertEqual((attack, defense), inputs)
                seen.add(signature)
        self.assertEqual(len(seen), 68)
        for rank in range(1, 5365):
            self.assertTrue(all(1 <= target <= 5363 and target != rank for target in arena.opponents(rank, self.config)))
        self.assertEqual(self.session.save, before)

    @classmethod
    def client_scripts(cls):
        if not hasattr(cls, "packaged"):
            with redirect_stdout(io.StringIO()):
                patched = builder.get_patched_lua_scripts()
            cls.packaged = {}
            for path, data in patched.items():
                raw = builder.xxtea_decrypt(data, builder.XXTEA_KEY)
                cls.packaged[path] = raw[:struct.unpack("<I", raw[-4:])[0]]
        return cls.packaged

    def test_actual_apk_network_callbacks_accept_queries_battles_shop_and_first_prizes(self):
        import test_activity_copy
        lua = test_activity_copy.ActivityCopyTests.network_lua(self)
        scripts = self.client_scripts()
        for name in ("athleticsattack_pb", "athleticsquery_pb", "athleticsrewardsexchange_pb", "athleticsrewardsquery_pb"):
            lua.execute(builder.read_script(name, "pb"))
        lua.execute(b'''gamedata.cache.athletics={rewardlist={},rewards={}}
            gamedata.cache.vipstatus={athletics_boss=99}
            gamedata.cache.role.name="test";gamedata.cache.role.profile=10112;gamedata.cache.role.f_power=100
            gamedata.rankreward=function(self,data) self.cache.athletics.rankRewardStatus=data end''')
        lua.execute(scripts["assets/scripts/GameAthletics.so"])
        self.assertIsNone(lua.globals().gameConfig)
        result = lua.globals().NetAthleticsList2Callback(lua.table_from({b"rbuf": self.call(1610)[0][16:]}))
        self.assertEqual((result[b"my"][b"rank"], result[b"my"][b"athletics"], result[b"athletics_boss"]), (5364, 5, 0))
        self.assertEqual(len(result[b"top10"]), 10)
        target = next(v for _, v in result[b"ranklist"].items() if v[b"rank"] == 5363)
        remote, opcode, body = lua.globals().UIAthleticsAtta2ckCallback(lua.table_from({b"rank": target, b"isFight": 1}))
        self.assertEqual((remote, opcode, body), (1, 1611, recharge.ids([5363])))
        self.strengthen()
        packets = self.session.handle(opcode, 182, body)
        reply = lua.globals().NetAthleticsAtta2ckCallback(lua.table_from({b"rbuf": packets[0][16:]}))
        self.assertEqual((reply[b"result"], reply[b"isFight"]), (1, 1))
        self.assertEqual(json.loads(reply[b"battlereport"]), self.report(packets))
        lua.globals().gamedata[b"cache"][b"athletics"][b"rewards"] = lua.table_from([1])
        self.assertEqual(lua.globals().UIAthleticsRewardsQuery3Callback(lua.table()), (1, 1613, None))
        result = lua.globals().NetAthleticsRewardsQuery3Callback(lua.table_from({b"rbuf": self.call(1613)[0][16:]}))
        self.assertEqual(len(result[b"rewards"]), 17)
        self.session.save["arena_state"]["points"] = 1000
        remote, opcode, body = lua.globals().UIAthleticsRewardExchange3Callback(lua.table_from({b"id": 13, b"num": 2}))
        self.assertEqual((remote, opcode, body), (1, 1614, recharge.ids([13, 2])))
        packets = self.session.handle(opcode, 183, body)
        reply = lua.globals().NetAthleticsRewardExchange3Callback(lua.table_from({b"rbuf": packets[0][16:]}))
        self.assertEqual(reply[b"type"], 1614)
        self.session.save["arena_state"]["rank"] = 2
        self.call(1611, [1], seq=184)
        reply = lua.globals().NetAthleticsRankRewardsStatusCallback(lua.table_from({b"rbuf": self.call(1615)[0][16:]}))
        self.assertEqual(list(reply[b"rankstatus"].values()), [1] * 9)
        self.session.save["arena_state"].update(used=2, boss=2)
        result = lua.globals().NetAthleticsList2Callback(lua.table_from({b"rbuf": self.call(1610)[0][16:]}))
        self.assertEqual(result[b"athletics_boss"], 2)
        self.assertEqual(lua.globals().UIAthleticsBoss2Callback(lua.table()), (1, 1616, None))
        packets = self.call(1616, seq=185)
        reply = lua.globals().NetAthleticsBoss2Callback(lua.table_from({b"rbuf": packets[0][16:]}))
        self.assertEqual(reply[b"result"], 1)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"vipstatus"][b"athletics_boss"], 3)

    def test_packaged_ui_refreshes_tabs_and_transactions_and_plays_lower_rank_rematches(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("竞技场实际UI验证需要本机已有lupa.lua51")
        scripts = self.client_scripts()
        lua = LuaRuntime()
        lua.globals().gamedata = lua.table_from({"config": self.config}, recursive=True)
        lua.execute('''print=function() end;printT=print
            requests={};UIRequest=function(t) requests[#requests+1]=t end
            local function widget() return {setString=function(self,v) self.text=v end,
                setVisible=function(self,v) self.visible=v end,setPositionX=function() end,
                setTouchPriority=function() end,addHandleOfControlEvent=function(self,cb) self.callback=cb end} end
            widgetTable=function() return setmetatable({duanNode=false},{__index=function(t,k)
                local w=widget();rawset(t,k,w);return w end}) end
            gameConfig={npcRidlimit=2146483648,strings={string_common=function() return "挑战" end}}
            gameTouch={clickprofbytime=function() end}
            setControlButtonFrame=function() end;CCControlEventTouchUpInside=1
            ui={setIconLv=function() end,setLabelString=function() end,setWudaoDuanweiRankEffect=function() end,
                getIDandNUMs=function() return {} end,addGray=function() end,removeGray=function() end}
            GameScene={layers={sports2={show=true,module={}},activity={module={pageTable={}}}}}
            RunbattleCallBack=function(kind,t,cb) cb() end
            showRewardPopupWindow=function(reward,ext,cb) cb() end''')
        layer = lua.execute(scripts["assets/scripts/Layer_sports.so"])
        layer.rootItems = lua.globals().widgetTable()
        layer.rankData, layer.top10Data, layer.firstRewardData = lua.table_from([1]), lua.table_from([1]), lua.table_from([1])
        for page, opcode in (("rank", 1610), ("top10", 1610), ("first", 1615)):
            lua.execute("requests={}")
            layer.shiftPage(layer, page)
            self.assertEqual(lua.globals().requests[1].type, opcode)
        layer.myData = lua.table_from({"rank": 1, "athletics": 5})
        layer.isscrolltouched = True
        items = lua.globals().widgetTable()
        row = lua.table_from({"rank": 2, "rid": arena.NPC_RID + 2, "status": 1, "icon": 10112, "level": 26, "power": 10})
        layer.setRankCell(layer, row, items, False)
        items.button.callback()
        self.assertEqual((lua.globals().requests[len(lua.globals().requests)].type, lua.globals().requests[len(lua.globals().requests)].isFight), (1611, 1))
        row.status, row.rank = 4, 1
        layer.setRankCell(layer, row, items, True)
        self.assertFalse(items.button.visible)
        lua.execute(scripts["assets/scripts/UIAthletics.so"])
        for name, data, expected in (("UIAthleticsAttack", {"isFight": 1}, [1610, 1613, 1001]),
                                     ("UIAthleticsRewardsExchange2", {}, [1610, 1613, 1001]),
                                     ("UIAthleticsBoss", {}, [1610, 1001])):
            lua.execute("requests={}")
            getattr(lua.globals(), name)(lua.table_from(data))
            self.assertEqual([req.type for _, req in lua.globals().requests.items()], expected)

    def test_packaged_attempt_purchase_waits_for_live_vip_status_before_quoting(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("竞技场购买窗口验证需要本机已有lupa.lua51")
        scripts = self.client_scripts()
        lua = LuaRuntime()
        lua.globals().gamedata = lua.table_from({"config": self.config}, recursive=True)
        lua.execute('''print=function() end;printT=print
            local function widget() return setmetatable({}, {__index=function(t,k)
                if k=="addHandleOfControlEvent" then return function(self,cb) self.callback=cb end end
                return function() end end}) end
            CCBReaderLoad=function() return {},setmetatable({}, {__index=function(t,k)
                local w=widget();rawset(t,k,w);return w end}) end
            ui={creatInputEditBoxForNum=function() end,setLabelString=function() end}
            gameConfig={checkBuildOpen=function() return true end,strings={string_common=function() return '' end}}
            GameScene={vip={vip=0},vipstatus={b_athletics=99},roleinfo={gold=100}}
            requests={};UIRequest=function(req) requests[#requests+1]=req end
            gameTouch={clickprofbytime=function() end};CCControlEventTouchUpInside=1
            runGamePrompt=function() prompted=true end;setSpriteFrameByName=function() end;ccc3=function() end
            gameWindows={windows={buypower={show=false}},closeWindowDirect=function() end}''')
        window = lua.execute(scripts["assets/scripts/window_buyProperty.so"])
        lua.globals().window = window
        lua.execute(scripts["assets/scripts/UIRecharge.so"])
        window.open(window, -1, lua.table_from({"id": 1}), None)
        self.assertEqual(lua.globals().requests[1].type, 300)
        self.assertTrue(window.localVipPending)
        window.rootItems.doButton2.callback()
        self.assertEqual(len(lua.globals().requests), 1)
        lua.execute('gameWindows.windows.buyProperty={show=true,module=window};UIVipStatus({vipstatus={b_athletics=0}})')
        self.assertFalse(window.localVipPending)
        self.assertEqual(window.nowcount, 0)
        window.numchange(window, 1)
        window.rootItems.doButton2.callback()
        request = lua.globals().requests[len(lua.globals().requests)]
        self.assertEqual((request.type, request.cid, request.count, request.gold), (301, 1, 1, 50))

    def test_all_npc_team_and_boss_reports_convert_using_actual_apk_animation_assets(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("竞技场原生动画转换验证需要本机已有lupa.lua51")
        lua = LuaRuntime()
        config = dict(self.config)
        with zipfile.ZipFile(ROOT / "configs_sec5.zip") as archive:
            for name in ("generalanimation", "skillanimation", "personalboss_att"):
                config[name] = json.loads(archive.read("5/" + name + ".json"))
        lua.globals().gamedata = lua.table_from({"config": config}, recursive=True)
        lua.execute('''print=function() end;printT=print;battleScene={slotNum=7}
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            CCFileUtils={sharedFileUtils=function(self) return self end,fullPathForFilename=function(self,p) return p end}
            ui={Split=function(s,sep) local t={} for v in string.gmatch(s,'[^'..sep..']+') do t[#t+1]=v end return t end}''')
        with zipfile.ZipFile(builder.SRC_APK) as archive:
            names, assets = archive.namelist(), {}
            lua.globals().CCFileUtils.isFileExist = lambda _, path: any(n.endswith("/" + path) for n in names)
            def load_asset(path):
                if path not in assets:
                    matches = [n for n in names if n.endswith("/" + path)]
                    self.assertEqual(len(matches), 1, path)
                    assets[path] = json.loads(archive.read(matches[0]))
                return lua.table_from(assets[path], recursive=True)
            lua.globals().LoadJsonFileToTable = load_asset
            lua.execute(self.client_scripts()["assets/scripts/battleReportConvert.so"])
            lua.execute(builder.read_script("BattleReportAbbToKey"))
            seen = set()
            for row in [*config["athletics_copy2"].values(), config["athletics_npc"]["50001"]]:
                if not row["p1"]:
                    continue
                signature = tuple((row[f"p{i}"], row[f"break{i}-correct"]) for i in range(1, 8))
                if signature in seen:
                    continue
                seen.add(signature)
                attack, defense = arena.rosters(self.session.save, row, config)
                report = battle.simulate(attack, defense, config, 7)
                native = lua.table_from(json.loads(lua.globals().ReplaceAbbToKey(json.dumps(report))), recursive=True)
                atk, enemy = lua.globals().getBattleInitSlotInfo(native)
                animations, ext = lua.globals().convertBattleReportToAnimationSub(native, atk, enemy, None, "sports")
                self.assertGreater(len(animations), 1)
                for side, key in (("attack", "atk"), ("defense", "def")):
                    for pos, unit in report["endmeta"][side].items():
                        self.assertEqual((ext.endinfo[key][pos].hp, ext.endinfo[key][pos].ap), (unit["h"], unit["ap"]))
            self.assertEqual(len(seen), 69)


if __name__ == "__main__":
    unittest.main()
