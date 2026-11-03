"""杯赛依赖闭环：临时真实账号、冻结阵容、实际战报与原子领奖。"""

from contextlib import redirect_stdout
import copy
import io
import json
import struct
import threading
import unittest
import zipfile
from unittest.mock import patch

import build_local_apk as builder
import test_friends
from zyj_server import achievements, activities, cup, formation, guild, player, protocol


def setUpModule():
    test_friends.setUpModule()


class CupTests(unittest.TestCase):
    request = test_friends.FriendsTests.request
    success = test_friends.FriendsTests.success
    add_account = test_friends.FriendsTests.add_account
    reconnect = test_friends.FriendsTests.reconnect
    groups = test_friends.FriendsTests.groups
    records = test_friends.FriendsTests.records
    client_scripts = classmethod(test_friends.FriendsTests.client_scripts.__func__)
    client_call = test_friends.FriendsTests.client_call

    def setUp(self):
        test_friends.FriendsTests.setUp(self)
        self.day = (self.now + 28800) // 86400
        self.now = self.day * 86400 - 28800 + 10 * 3600
        self.clock.return_value = self.now

    def at(self, days=0, hour=10, minute=0):
        self.clock.return_value = (self.day + days) * 86400 - 28800 + hour * 3600 + minute * 60

    def shared(self):
        return json.loads((self.root / "cups.json").read_bytes())

    def query(self, account=1):
        raw = self.groups(self.success(account, 2100, values=[0]))[1]
        return {protocol.pb_get_varint(row, 2): row for row in self.records(raw, 2)}

    def props(self, account, cid):
        raw = bytes.fromhex(self.sessions[account].save["world_state"]["1200"])
        return sum(protocol.pb_get_varint(row, 2) or 0 for row in self.records(raw)
                   if protocol.pb_get_varint(row, 1) == cid)

    def assert_rejected(self, account, opcode, **kwargs):
        before = copy.deepcopy(self.sessions[account].save)
        disk = {a: self.store.path(a).read_bytes() for a in self.sessions}
        path = self.root / "cups.json"
        shared = path.read_bytes() if path.exists() else None
        self.assertEqual([mid for mid, _ in self.request(account, opcode, **kwargs)], [999999, 1999])
        self.assertEqual(self.sessions[account].save, before)
        self.assertEqual({a: self.store.path(a).read_bytes() for a in self.sessions}, disk)
        self.assertEqual(path.read_bytes() if path.exists() else None, shared)

    def register(self, accounts=(1, 2)):
        for account in accounts:
            self.success(account, 2101)

    def finish(self):
        self.at(1, 20)
        self.query()
        return list(self.shared()["periods"].values())[-1]

    def test_entry_is_empty_and_registration_freezes_only_the_real_bound_player_once(self):
        self.assertEqual(self.query(), {})
        before = self.props(1, 20359)
        self.success(1, 2101)
        state = self.shared()
        self.assertEqual(set(state["signups"]["entrants"]), {"1"})
        self.assertEqual(self.props(1, 20359), before + 1)
        self.assert_rejected(1, 2101)
        self.reconnect()
        self.assert_rejected(1, 2101)
        self.assertEqual(self.props(1, 20359), before + 1)

    def test_signup_clock_level_capacity_and_malformed_requests_never_change_assets(self):
        self.at(hour=8)
        self.assert_rejected(1, 2101)
        self.at(hour=23)
        self.assert_rejected(1, 2101)
        self.at()
        self.sessions[1].save["role_state"]["level"] = 28
        self.assert_rejected(1, 2101)
        self.sessions[1].save["role_state"]["level"] = 31
        with patch.dict(self.config["global_kv"]["cup_maxpeople"], value="1"):
            self.success(1, 2101)
            self.assert_rejected(2, 2101)
        for opcode in (*cup.OPCODES, 2105):
            for raw in (b"\x08", b"\x10\x01", b"\x0a\x00"):
                self.assert_rejected(1, opcode, raw=raw)
        self.assert_rejected(1, 2105, values=[12, 1, 1])

    def test_one_signup_has_no_invented_enemy_win_rank_or_battle_reward(self):
        self.register((1,))
        period = self.finish()
        self.assertEqual(period["battles"], [])
        self.assertEqual(self.query(), {})
        self.assertEqual(self.sessions[1].save["cup_state"]["best"], 0)
        self.assert_rejected(1, 2106)

    def test_two_players_have_real_result_report_losses_and_no_campaign_or_experience_costs(self):
        self.register()
        before = {a: copy.deepcopy(self.sessions[a].save) for a in (1, 2)}
        period = self.finish()
        fights = period["battles"]
        self.assertEqual(len(fights), 1)
        fight = fights[0]
        self.assertEqual(set((fight["a"], fight["b"])), {1, 2})
        self.assertEqual(fight["round"], 12)
        report = json.loads(next(v for n, w, v in protocol.iter_pb_fields(bytes.fromhex(fight["body"])) if (n, w) == (5, 2)))
        self.assertEqual(fight["winner"], fight["a"] if report["result"] else fight["b"])
        for account in (1, 2):
            rows = self.query(account)
            self.assertEqual(protocol.pb_get_varint(rows[12], 3), int(account == fight["winner"]))
            after = self.sessions[account].save
            for key in ("world_state", "last_battle", "protagonist_snapshot"):
                self.assertEqual(after.get(key), before[account].get(key))
            for key in ("exp", "stamina", "energy", "level"):
                self.assertEqual(after["role_state"][key], before[account]["role_state"][key])
        self.assert_rejected(3 - fight["winner"], 2106)

    def test_signup_snapshot_keeps_equipment_magic_pet_and_support_changes_out_of_existing_bracket(self):
        self.register()
        snapshot = copy.deepcopy(self.shared()["signups"]["entrants"]["1"]["snapshot"])
        self.sessions[1].save["role_state"]["power"] = 1
        for raw in formation.records(bytes.fromhex(self.sessions[1].save["world_state"]["1002"]), 1, 2).values():
            raw = protocol.pb_set_varint(protocol.pb_set_varint(raw, 6, 1000000), 8, 1000000)
            player.record_slot_update(self.sessions[1].save, protocol.encode_pb_field(1, 2, raw))
        self.success(1, 999904)
        period = self.finish()
        self.assertEqual(period["entrants"]["1"]["snapshot"], snapshot)
        inputs = copy.deepcopy(period["entrants"])
        report = cup.duel(period["entrants"]["1"], period["entrants"]["2"], self.config, 77)
        self.assertEqual(report, cup.duel(period["entrants"]["1"], period["entrants"]["2"], self.config, 77))
        self.assertEqual(inputs, period["entrants"])
        row = period["battles"][0]
        expected = cup.duel(period["entrants"][str(row["a"])], period["entrants"][str(row["b"])], self.config, row["seed"])
        self.assertEqual(json.loads(self.records(bytes.fromhex(row["body"]), 5)[0]), expected)

    def test_eight_real_players_follow_schedule_and_real_reports_only(self):
        for account in range(4, 9):
            self.add_account(account)
        self.register(range(1, 9))
        self.at(1, 13)
        rows = self.records(self.success(1, 2102, values=[2, 4, 8]))
        self.assertEqual(len(rows), 4)
        self.assertTrue(all(protocol.pb_get_varint(row, 5) == (1 << 64) - 1 for row in rows))
        self.at(1, 14, 29)
        self.assertEqual(self.query(), {})
        self.at(1, 14, 30)
        self.query()
        period = list(self.shared()["periods"].values())[-1]
        self.assertEqual(sum(bool(row["body"]) for row in period["battles"]), 4)
        self.at(1, 16, 30)
        self.query()
        self.at(1, 19, 30)
        self.query()
        period = list(self.shared()["periods"].values())[-1]
        self.assertEqual(len(period["battles"]), 7)
        self.assertEqual(sum(bool(row["body"]) for row in period["battles"]), 7)

    def test_rewards_single_all_reconnect_and_latest_same_request_are_not_duplicate(self):
        self.register()
        fight = self.finish()["battles"][0]
        winner = fight["winner"]
        self.query(winner)
        self.seq += 1
        raw = cup.ids([12, fight["id"]])
        packets = self.sessions[winner].handle(2104, self.seq, raw)
        self.assertEqual(struct.unpack(">IIII", packets[0][:16])[2], 2104)
        memory, disk = copy.deepcopy(self.sessions[winner].save), self.store.path(winner).read_bytes()
        self.assertEqual(self.sessions[winner].handle(2104, self.seq, raw), packets)
        self.assertEqual((self.sessions[winner].save, self.store.path(winner).read_bytes()), (memory, disk))
        self.reconnect(winner)
        self.assert_rejected(winner, 2104, values=[12, fight["id"]])
        self.assert_rejected(winner, 2106)

    def test_saved_actual_rank_unlocks_seven_achievement_conditions_without_guessing_old_history(self):
        self.register()
        fight = self.finish()["battles"][0]
        winner = fight["winner"]
        self.query(winner)
        self.assertEqual(self.sessions[winner].save["cup_state"]["best"], 1)
        self.assertTrue(set(range(51601, 51608)) <= set(self.sessions[winner].save["achievement_state"]["completed"]))
        self.success(winner, 2401, values=[51601])
        self.reconnect(winner)
        self.assert_rejected(winner, 2401, values=[51601])
        self.assertEqual(self.sessions[3].save.get("cup_state", {}).get("best", 0), 0)

    def test_storage_failures_recover_only_matching_identity_receipts_without_free_rewards(self):
        before, disk = copy.deepcopy(self.sessions[1].save), self.store.path(1).read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 2101)
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))
        self.assertIsNotNone(self.shared()["pending"])
        self.reconnect()
        self.query()
        self.assertEqual(self.shared()["signups"]["entrants"], {})
        calls = 0
        original = cup.write
        def fail_publish(path, state):
            nonlocal calls
            calls += 1
            if calls == 2:
                raise OSError("publish")
            return original(path, state)
        with patch.object(cup, "write", side_effect=fail_publish), self.assertRaises(OSError):
            self.request(1, 2101)
        self.reconnect()
        self.query()
        self.assertIn("1", self.shared()["signups"]["entrants"])
        self.assert_rejected(1, 2101)

    def test_real_losses_use_frozen_weak_team_and_byes_never_create_rewards(self):
        save = self.sessions[1].save
        for raw in formation.records(bytes.fromhex(save["world_state"]["1002"]), 1, 2).values():
            for field, value in ((4, 0), (6, 1), (7, 0), (8, 1), (9, 1)):
                raw = protocol.pb_set_varint(raw, field, value)
            player.record_slot_update(save, protocol.encode_pb_field(1, 2, raw))
        self.register()
        fight = self.finish()["battles"][0]
        self.assertEqual(fight["winner"], 2)
        self.assertEqual(self.shared()["players"]["1"]["points"], 0)
        self.assertEqual(self.shared()["players"]["1"]["prizes"], {})
        self.at(1, 20)
        self.register((1, 2, 3))
        self.at(2, 20)
        self.query()
        period = self.shared()["periods"][str(self.day + 2)]
        self.assertEqual(len(period["battles"]), 2)
        self.assertEqual(sum(r["points"] for r in self.shared()["players"].values()), 30)

    def test_old_prizes_survive_retention_and_new_days_use_globally_unique_match_ids(self):
        self.register()
        first = self.finish()["battles"][0]
        winner = first["winner"]
        self.at(1, 20)
        self.register()
        self.at(2, 20)
        self.query()
        second = self.shared()["periods"][str(self.day + 2)]["battles"][0]
        self.assertGreater(second["id"], first["id"])
        self.at(12, 20)
        self.query(winner)
        self.assertEqual(self.shared()["periods"], {})
        rows = self.query(winner)
        self.assertEqual(protocol.pb_get_varint(rows[12], 1), first["id"])
        self.assertEqual(self.success(winner, 2103, values=[12, first["id"]]), bytes.fromhex(first["body"]))
        self.success(winner, 2106)
        self.assert_rejected(winner, 2106)
        self.assert_rejected(winner, 2103, values=[12, first["id"]])

    def test_forward_clock_and_rollback_cannot_repeat_signup_settlement_or_claims(self):
        self.register()
        period = self.finish()
        points = {a: r["points"] for a, r in self.shared()["players"].items()}
        self.at(hour=10)
        self.assert_rejected(1, 2101)
        self.assert_rejected(period["battles"][0]["winner"], 2106)
        self.query()
        self.assertEqual({a: r["points"] for a, r in self.shared()["players"].items()}, points)
        self.assertEqual(self.shared()["periods"][str(self.day + 1)], period)

    def test_recreated_account_cannot_inherit_signup_points_best_or_old_prizes(self):
        self.register()
        fight = self.finish()["battles"][0]
        winner = fight["winner"]
        self.store.close_session(winner)
        self.sessions.pop(winner)
        self.add_account(winner)
        self.query(winner)
        own = self.shared()["players"][str(winner)]
        self.assertEqual((own["best"], own["points"], own["prizes"]), (0, 0, {}))
        self.assert_rejected(winner, 2104, values=[12, fight["id"]])
        self.assertEqual(self.query(winner), {})

    def test_recreated_signup_is_removed_without_a_forfeit_win_or_fake_champion(self):
        self.register()
        self.store.close_session(2)
        self.sessions.pop(2)
        self.add_account(2)
        self.query(2)
        self.assertNotIn("2", self.shared()["signups"]["entrants"])
        self.assertEqual(self.finish()["battles"], [])
        self.assertEqual(self.shared()["players"]["1"]["best"], 0)

    def test_failed_claim_and_reward_overflow_leave_prize_and_assets_unmodified(self):
        self.register()
        fight = self.finish()["battles"][0]
        winner = fight["winner"]
        self.query(winner)
        before, disk = copy.deepcopy(self.sessions[winner].save), self.store.path(winner).read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(winner, 2106)
        self.assertEqual((self.sessions[winner].save, self.store.path(winner).read_bytes()), (before, disk))
        self.reconnect(winner)
        self.query(winner)
        self.assertIn(str(fight["id"]), self.shared()["players"][str(winner)]["prizes"])
        path = self.root / "cups.json"
        state = self.shared()
        state["players"][str(winner)]["prizes"][str(fight["id"])]["items"] = {"1001": 1 << 31}
        path.write_text(json.dumps(state))
        self.assert_rejected(winner, 2106)
        state["players"][str(winner)]["prizes"][str(fight["id"])]["items"] = {"1001": 1}
        cup.write(path, state)
        self.sessions[winner].save["role_state"]["gold"] = (1 << 31) - 1
        self.assert_rejected(winner, 2106)

    def test_parallel_signup_respects_last_place_and_parallel_claim_pays_once(self):
        results = []
        with patch.dict(self.config["global_kv"]["cup_maxpeople"], value="1"):
            threads = [threading.Thread(target=lambda a=a: results.append(self.request(a, 2101)[0][0])) for a in (1, 2)]
            for thread in threads: thread.start()
            for thread in threads: thread.join()
        self.assertEqual(sorted(results), [2101, 999999])
        other = next(a for a in (1, 2) if str(a) not in self.shared()["signups"]["entrants"])
        self.success(other, 2101)
        fight = self.finish()["battles"][0]
        winner = fight["winner"]
        results.clear()
        threads = [threading.Thread(target=lambda: results.append(self.request(winner, 2106)[0][0])) for _ in range(2)]
        for thread in threads: thread.start()
        for thread in threads: thread.join()
        self.assertEqual(sorted(results), [2106, 999999])

    def test_missing_corrupt_journal_and_foreign_requests_are_fail_closed(self):
        self.register()
        path = self.root / "cups.json"
        raw, original = path.read_bytes(), self.shared()
        for value in (b"{", b"[]", b"null"):
            path.write_bytes(value)
            self.assert_rejected(1, 2100, values=[0])
        for change in ({"version": True}, {"checked_at": -1}, {"next_id": 0}, {"players": {}}, {"pending": {}}):
            path.write_text(json.dumps({**original, **change}))
            self.assert_rejected(1, 2100, values=[0])
        path.unlink()
        self.assert_rejected(1, 2100, values=[0])
        path.write_bytes(raw)
        for opcode, values in ((2103, [12, 999]), (2104, [12, 999]), (2102, [8]), (2100, [0, 1])):
            self.assert_rejected(3, opcode, values=values)
        self.assert_rejected(1, 999900, raw=guild.message(2101, b""))
        self.sessions[1].cup_request = None
        self.assert_rejected(1, 2100, values=[0])

    def test_all_configured_rewards_and_rank_comparisons_use_real_sources(self):
        for row in self.config["cup_reward"].values():
            save = copy.deepcopy(self.sessions[1].save)
            raw = activities.build_reward(save, row["reward"], self.config)
            player.apply_reward(save, raw, self.config, int(self.clock.return_value))
        rows = [r for r in self.config["task"].values() if r["type"] == "cuprank"]
        self.assertEqual(len(rows), 7)
        for rank in (0, 1, 2, 4, 8, 16, 64, 256, 1000):
            save = copy.deepcopy(self.sessions[1].save)
            save["cup_state"] = dict(cup.get_state(save), best=rank)
            view = achievements.snapshot(save, self.config)
            for row in rows:
                self.assertEqual(achievements.progress(row, view)[1], 0 < rank <= int(row["target"]))

    def test_achievement_reads_sync_published_rank_only_without_writing_shared_or_peer_saves(self):
        self.success(3, 2400)
        self.assertFalse((self.root / "cups.json").exists())
        self.assertNotIn("cup_state", self.sessions[3].save)
        self.register()
        self.finish()
        own = copy.deepcopy(self.sessions[2].save)
        self.assertEqual(own["cup_state"]["best"], 0)
        paths = (self.root / "cups.json", self.store.path(1), self.store.path(3))
        disk = [p.read_bytes() for p in paths]
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(2, 2400)
        self.assertEqual(self.sessions[2].save, own)
        self.success(2, 2400)
        self.assertEqual(self.sessions[2].save["cup_state"]["best"], self.shared()["players"]["2"]["best"])
        self.assertEqual([p.read_bytes() for p in paths], disk)
        self.success(3, 2101)

    def test_claim_publish_failure_recovers_paid_prize_once_after_reconnect(self):
        self.register()
        fight = self.finish()["battles"][0]
        winner = fight["winner"]
        self.query(winner)
        original = cup.write
        calls = 0
        def fail_publish(path, state):
            nonlocal calls
            calls += 1
            if calls == 2:
                raise OSError("publish")
            return original(path, state)
        with patch.object(cup, "write", side_effect=fail_publish), self.assertRaises(OSError):
            self.request(winner, 2106)
        paid = self.store.path(winner).read_bytes()
        self.assertIsNotNone(self.shared()["pending"])
        self.reconnect(winner)
        self.query(winner)
        self.assertEqual(self.sessions[winner].save["world_state"], json.loads(paid)["world_state"])
        self.assertEqual(self.shared()["players"][str(winner)]["prizes"], {})
        self.assert_rejected(winner, 2106)

    def test_signup_rejects_unsupported_rosters_and_snapshot_keeps_only_battle_equipment(self):
        save = self.sessions[1].save
        raw = next(iter(formation.records(bytes.fromhex(save["world_state"]["1002"]), 1, 2).values()))
        player.record_slot_update(save, protocol.encode_pb_field(1, 2, protocol.pb_set_varint(raw, 21, 1)))
        self.assert_rejected(1, 2101)
        player.record_slot_update(save, protocol.encode_pb_field(1, 2, raw))
        idle = protocol.pb_set_varint(raw, 2, 2999999)
        player.record_slot_update(save, protocol.encode_pb_field(1, 2, idle))
        self.success(1, 2101)
        frozen = bytes.fromhex(self.shared()["signups"]["entrants"]["1"]["snapshot"]["world_state"]["1002"])
        self.assertNotIn(2999999, formation.records(frozen, 1, 2))
        self.assertIn(2999999, formation.records(bytes.fromhex(self.sessions[1].save["world_state"]["1002"]), 1, 2))

    def test_all_bracket_sizes_start_at_actual_round_and_do_not_award_skipped_tiers(self):
        for number in (2, 3, 8, 16, 64, 256, 500):
            with self.subTest(number=number):
                state = {"next_id": 1, "signups": {"day": self.day + 1, "entrants": {}}, "periods": {}, "players": {}}
                saves = {}
                for account in range(1, number + 1):
                    save = {**self.sessions[1].save, "created_at": self.now - account}
                    saves[account] = save
                    state["signups"]["entrants"][str(account)] = {"identity": save["created_at"]}
                cup.settle(state, saves, self.config, (self.day + 1) * 86400 - 28800 + 8 * 3600)
                period = state["periods"][str(self.day + 1)]
                self.assertEqual(period["round"], 13 - (number - 1).bit_length())
                self.assertEqual(len(period["battles"]), number // 2)
                self.assertTrue(all(row["winner"] == 0 and not row["body"] for row in period["battles"]))
                self.assertEqual(state["players"], {})

    def test_rank_and_public_bracket_use_native_self_id_without_exposing_private_state(self):
        self.register()
        fight = self.finish()["battles"][0]
        winner = fight["winner"]
        raw = self.groups(self.success(winner, 2107))
        self.assertEqual(protocol.parse_ids_pb(raw[0]), [10, 1])
        row = self.records(raw[1])[0]
        self.assertEqual(protocol.pb_get_varint(row, 1), protocol.pb_get_varint(bytes.fromhex(self.sessions[winner].save["role_snapshot"]), 1))
        visitor = self.records(self.groups(self.success(3, 2107))[1])[0]
        self.assertEqual(protocol.pb_get_varint(visitor, 1), 1000000 + winner)
        for raw in (row, visitor, self.success(3, 2102, values=[2, 4, 8])):
            self.assertNotIn(b"test-password", raw)
            self.assertNotIn(b"same-address", raw)

    def network_lua(self, account=1):
        lua = test_friends.FriendsTests.network_lua(self, account)
        for name in ("cupstatus_pb", "cuptops_pb"):
            lua.execute(builder.read_script(name, "pb"))
        code = builder.read_script("gamedata").decode().replace("\r\n", "\n")
        lua.execute(code[code.index("function gamedata.playerwithgeneralsdata("):code.index("function gamedata.gangbroadcastsData(")].encode())
        for start, end in (("function gamedata.propData(", "function gamedata.generalfragmentData("),
                           ("function gamedata.equipfragmentData(", "function gamedata.checkQilingNum("),
                           ("function gamedata.equipData(", "function gamedata.artifactData("),
                           ("function gamedata.gemData(", "function gamedata.SlotInfoProcess("),
                           ("function gamedata.updateRoleCoin(", "function gamedata.updateRoleExp(")):
            lua.execute(code[code.index(start):code.index(end)].encode())
        lua.execute(b'''gamedata.cache.cup={status={battles={}},topbattles={}}
            gamedata.cache.props={};gamedata.cache.equipfragments={};gamedata.cache.equips={};gamedata.cache.souls={};gamedata.cache.gems={}''')
        lua.globals().gamedata[b"cache"][b"role"][b"name"] = self.sessions[account].save["role_name"].encode()
        lua.execute(self.client_scripts()["assets/scripts/GameCup.so"])
        return lua

    def test_actual_native_pb_network_callbacks_signup_battles_rewards_and_full_cache_replacement(self):
        lua = self.network_lua()
        result = self.client_call(lua, 1, "UICupStatusCallBack", "NetCupStatusCallBack", {"view": 4})
        self.assertEqual((result[b"view"], len(result[b"cupstatus"][b"battles"])), (4, 0))
        self.client_call(lua, 1, "UICupJoinTomorrowCallBack", "NetCupJoinTomorrowCallBack", {"view": 4})
        self.success(2, 2101)
        self.finish()
        result = self.client_call(lua, 1, "UICupStatusCallBack", "NetCupStatusCallBack", {"view": 4})
        self.assertEqual(len(result[b"cupstatus"][b"battles"]), 1)
        tops = self.client_call(lua, 1, "UICupTopCallBack", "NetCupTopCallBack", {"view": 4})
        self.assertEqual(len(tops[b"cuptopbattles"][2]), 1)
        row = tops[b"cuptopbattles"][2][1]
        result = self.client_call(lua, 1, "UICupBattlePlayCallBack", "NetCupBattlePlayCallBack",
            {"view": 4, "round": 12, "id": row[b"id"], "generation": 6})
        self.assertTrue(result[b"battlereport"])
        self.assertEqual((result[b"generation"], result[b"id"]), (6, row[b"id"]))
        self.client_call(lua, 1, "UICupRankCallBack", "NetCupRankCallBack", {"view": 4})
        lua.execute(b'gamedata.cache.cup.status.battles[1]={id=999,round=1};gamedata.cache.cup.topbattles[999]={id=999}')
        self.client_call(lua, 1, "UICupStatusCallBack", "NetCupStatusCallBack", {"view": 5})
        self.client_call(lua, 1, "UICupTopCallBack", "NetCupTopCallBack", {"view": 5})
        self.assertIsNone(lua.globals().gamedata[b"cache"][b"cup"][b"status"][b"battles"][1])
        self.assertIsNone(lua.globals().gamedata[b"cache"][b"cup"][b"topbattles"][999])
        winner = self.shared()["periods"][str(self.day + 1)]["battles"][0]["winner"]
        winning = lua if winner == 1 else self.network_lua(winner)
        self.client_call(winning, winner, "UICupStatusCallBack", "NetCupStatusCallBack", {"view": 5})
        self.client_call(winning, winner, "UICupBattleRewardallCallBack", "NetCupBattleRewardallCallBack", {"view": 5})
        self.assertEqual(winning.globals().gamedata[b"cache"][b"cup"][b"status"][b"battles"][12][b"reward"], 1)
        self.assertIsNone(winning.globals().gameConfig)

    def test_actual_network_fifo_busy_native_errors_and_unavailable_bets_never_retry_blindly(self):
        lua = self.network_lua()
        pending = []
        for view in (4, 5):
            req = lua.table_from({b"view": view})
            mode, opcode, raw = lua.globals().UICupStatusCallBack(req)
            self.assertEqual(mode, 1)
            pending.append(self.success(1, opcode, raw=raw))
        self.assertEqual(lua.globals().UICupStatusCallBack(req)[0], 0)
        for view, raw in zip((4, 5), pending):
            result = lua.globals().NetCupStatusCallBack(lua.table_from({b"rbuf": raw}))
            self.assertEqual(result[b"view"], view)
        req = lua.table_from({b"view": 5})
        self.assertEqual(lua.globals().UICupJoinTomorrowCallBack(req)[0], 1)
        self.assertEqual(lua.globals().UICupBattleRewardallCallBack(req)[0], 0)
        lua.globals().NetErrorMessageCallback9(lua.table_from({b"rbuf": cup.ids([2101, 0])}))
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localCupBusy"])
        self.assertEqual(lua.globals().UICupBattleRewardallCallBack(req)[0], 1)
        self.assertEqual(lua.globals().UICupBattleBetCallBack(req)[0], 0)

    def test_actual_stale_personal_replay_never_falls_back_to_public_bracket_cache(self):
        self.register()
        fight = self.finish()["battles"][0]
        lua = self.network_lua()
        self.client_call(lua, 1, "UICupTopCallBack", "NetCupTopCallBack", {"view": 4})
        mode, opcode, result = lua.globals().UICupBattlePlayCallBack(lua.table_from(
            {b"view": 4, b"round": 12, b"id": fight["id"], b"isself": True}))
        self.assertEqual((mode, opcode), (0, 503))
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localCupBusy"])
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localCupPending"][2103])
        mode, _, _ = lua.globals().UICupBattlePlayCallBack(lua.table_from(
            {b"view": 4, b"round": 12, b"id": fight["id"]}))
        self.assertEqual(mode, 1)

    def ui_lua(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("实际杯赛界面验证需要lupa.lua51")
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute('''print=function() end;printT=print;CCControlEventTouchUpInside=1
            clock=1000;requests={};UIRequest=function(t) requests[#requests+1]=t end
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            gameConfig={originSize={width=1080},labelnodeheight=40,images={},
                strings={string_common=function() return "杯赛" end},checkBuildOpen=function() return false end}
            function node() return setmetatable({}, {__index=function(t,k)
                if k=="getContentSize" then return function() return {width=500,height=600} end end
                if k=="setString" then return function(self,s) self.text=s end end
                if k=="setVisible" then return function(self,v) self.visible=v end end
                if k=="addHandleOfControlEvent" then return function(self,f) self.handler=f end end
                return function() end
            end}) end
            function items() return setmetatable({}, {__index=function(t,k) local n=node();rawset(t,k,n);return n end}) end
            CCBReaderLoad=function() return node(),items() end
            ccp=function(x,y) return {x=x,y=y} end;CCSizeMake=function(x,y) return {width=x,height=y} end
            CCMoveTo={create=function() return node() end};CCNode={create=function() return node() end}
            CCSkeletonAnimation={create=function() return node() end}
            ui={setLabelString=function(n,text) n.text=text end,removeGray=function() end,addGray=function() end}
            gameTouch={rigistFunc=function() end,UnrigistFunc=function() end}
            gameTimer={times={},funcs={},rigistTime=function(self,k,n) self.times[k]=n end,
                rigistTimeFunc=function(self,k,f) self.funcs[k]=f end,
                UnrigistTimeFunc=function(self,k) self.times[k]=nil;self.funcs[k]=nil end}
            gamedata={config={general={}},time=function() return clock end}
            GameScene={topposY=1600,layers={cup={show=true}},roleinfo={id=9,name="本人",level=31}}
            gameWindows={windows={cup={show=true}},closeWindow=function(self) self.windows.cup.show=false end,
                closeWindowDirect=function(self) self.windows.cup.show=false end}
            runGamePrompt=function(t) prompt=t.msg end;showRewardPopupWindow=function() rewards=(rewards or 0)+1 end
            RunbattleCallBack=function(kind,t) played=(played or 0)+1 end''')
        lua.globals().cup = lua.execute(self.client_scripts()["assets/scripts/Layer_cup.so"].decode())
        lua.globals().window = lua.execute(self.client_scripts()["assets/scripts/window_cup.so"].decode())
        lua.execute('''GameScene.layers.cup.module=cup;gameWindows.windows.cup.module=window
            cup:init(node(),1600);window.localCupGeneration=6;window.data={id=7}
            requests={}''')
        lua.execute(self.client_scripts()["assets/scripts/UICup.so"].decode())
        return lua

    def test_actual_page_requeries_reentry_and_real_clock_polling_stops_when_closed(self):
        lua = self.ui_lua()
        lua.execute('''cup.statusdata={round=12};cup.topsdata={old=true};cup.rankdata={old=true}
            cup:shiftPage("self");cup:shiftPage("tops");cup:shiftPage("rank")
            for _,req in ipairs(requests) do assert(req.view==cup.localCupView) end''')
        self.assertEqual([r["type"] for r in lua.globals().requests.values()], [2100, 2100, 2102, 2107])
        lua.execute('''requests={};gameTimer.funcs.cuptimer()
            for i=1,100 do gameTimer.funcs.cuptimer() end
            assert(#requests==2)
            clock=1015;gameTimer.funcs.cuptimer();assert(#requests==4)
            GameScene.layers.cup.show=false;clock=1030;gameTimer.funcs.cuptimer();assert(#requests==4)
            local view=cup.localCupView;cup:clear();assert(cup.localCupView>view)
            assert(gameTimer.funcs.cuptimer==nil)''')

    def test_actual_ui_rejects_closed_reopened_and_other_match_replies_and_refreshes_after_rewards(self):
        lua = self.ui_lua()
        lua.execute('''local view=cup.localCupView
            UICupBattlePlay({view=view,id=7,generation=6});assert(played==1)
            UICupBattlePlay({view=view,id=8,generation=6});assert(played==1)
            UICupBattlePlay({view=view,id=7,generation=5});assert(played==1)
            gameWindows.windows.cup.show=false
            UICupBattlePlay({view=view,id=7,generation=6});assert(played==1)
            UICupBattleRewardall({view=view,cupstatus={tomorrow=0,battles={}},reward={{cid=1000,num=1}}})
            assert(rewards==1 and requests[#requests].type==2100)
            cup.localCupView=view+1
            UICupBattleRewardall({view=view,cupstatus={tomorrow=0,battles={}},reward={{cid=1000,num=1}}})
            assert(rewards==1)
            UICupStatus({view=cup.localCupView,localSkip=true})
            GameScene.layers.cup.show=false
            UICupStatus({view=cup.localCupView,cupstatus={tomorrow=1,battles={}}})
            assert(cup.statusdata.tomorrow==0)''')

    def test_actual_report_window_has_no_bet_or_inventory_request_and_binds_playback_generation(self):
        lua = self.ui_lua()
        lua.execute('''window:open(-100,{type="bet",view=cup.localCupView,
                data={id=9,round=12,status=1,a={name="甲",generals={}},b={name="乙",generals={}}}})
            assert(#requests==0 and window.rootItems.betNode.visible==false)
            window.rootItems.playbutton.handler()
            assert(#requests==1 and requests[1].type==2103 and requests[1].id==9)
            assert(requests[1].view==cup.localCupView and requests[1].generation==window.localCupGeneration)
            local generation=window.localCupGeneration;window:close();assert(window.localCupGeneration>generation)''')

    def test_actual_packager_ships_compilable_cup_scripts_and_consistent_local_rule_labels(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("实际Lua编译需要lupa.lua51")
        compile = LuaRuntime().eval("function(s) assert(loadstring(s)); return true end")
        for name in ("GameCup", "UICup", "Layer_cup", "window_cup", "language_CN"):
            code = self.client_scripts()[f"assets/scripts/{name}.so"].decode()
            self.assertTrue(compile(code), name)
        text = self.client_scripts()["assets/scripts/language_CN.so"].decode()
        self.assertIn("每天9至23点报名次日杯赛，不足2人不开赛", text)
        self.assertIn("本地不开放竞猜", text)

    def test_generated_frozen_pvp_reports_convert_actual_animation_assets_on_both_sides(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("实际APK动画验证需要lupa.lua51")
        lua = LuaRuntime()
        config = dict(self.config)
        with zipfile.ZipFile(test_friends.test_guild.ROOT / "configs_sec5.zip") as archive:
            for name in ("generalanimation", "skillanimation"):
                config[name] = json.loads(archive.read("5/" + name + ".json"))
        lua.globals().gamedata = lua.table_from({"config": config}, recursive=True)
        lua.execute('''print=function() end;printT=print;battleScene={slotNum=7}
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            CCFileUtils={sharedFileUtils=function(self) return self end,fullPathForFilename=function(self,p) return p end}
            ui={Split=function(s,sep) local t={} for v in string.gmatch(s,'[^'..sep..']+') do t[#t+1]=v end return t end}''')
        with zipfile.ZipFile(builder.SRC_APK) as archive:
            names, assets = archive.namelist(), {}
            lua.globals().CCFileUtils.isFileExist = lambda _, path: any(n.endswith("/" + path) for n in names)
            def asset(path):
                if path not in assets:
                    matches = [n for n in names if n.endswith("/" + path)]
                    self.assertEqual(len(matches), 1, path)
                    assets[path] = json.loads(archive.read(matches[0]))
                return lua.table_from(assets[path], recursive=True)
            lua.globals().LoadJsonFileToTable = asset
            lua.execute(self.client_scripts()["assets/scripts/battleReportConvert.so"].decode())
            lua.execute(builder.read_script("BattleReportAbbToKey").decode())
            entrants = [cup.frozen(self.sessions[a].save, a, self.config) for a in (1, 2)]
            for first, second in (entrants, entrants[::-1]):
                report = cup.duel(first, second, self.config, 7)
                native = lua.table_from(json.loads(lua.globals().ReplaceAbbToKey(json.dumps(report))), recursive=True)
                allies, enemies = lua.globals().getBattleInitSlotInfo(native)
                animations, ext = lua.globals().convertBattleReportToAnimationSub(native, allies, enemies)
                self.assertGreater(len(animations), 1)
                for side, key in (("attack", "atk"), ("defense", "def")):
                    for pos, unit in report["endmeta"][side].items():
                        self.assertEqual((ext.endinfo[key][pos].hp, ext.endinfo[key][pos].ap), (unit["h"], unit["ap"]))


if __name__ == "__main__":
    unittest.main()
