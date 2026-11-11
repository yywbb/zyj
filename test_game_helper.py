"""游戏助手：只操作临时账号，验证真实玩法、报价和原生回调。"""

import copy
import json
import re
import unittest
import zipfile
from unittest.mock import patch

import build_local_apk as builder
import test_soul
from zyj_server import activities, activity_copy, arena, formation, game_helper, mieshendian, player, protocol, recharge, single_boss


def setUpModule():
    test_soul.setUpModule()


class GameHelperTests(unittest.TestCase):
    request = test_soul.SoulTests.request
    success = test_soul.SoulTests.success
    reconnect = test_soul.SoulTests.reconnect
    add_account = test_soul.SoulTests.add_account
    refresh = test_soul.SoulTests.refresh
    records = test_soul.SoulTests.records
    groups = test_soul.SoulTests.groups
    assert_rejected = test_soul.SoulTests.assert_rejected
    grant = test_soul.SoulTests.grant
    props = test_soul.SoulTests.props
    gen = test_soul.SoulTests.gen
    client_scripts = classmethod(test_soul.SoulTests.client_scripts.__func__)

    def setUp(self):
        test_soul.SoulTests.setUp(self)
        self.save["role_state"].update(level=150, coin=100000000000, gold=1000000)

    def body(self, rows, token=None, extra=()):
        messages = [(1, recharge.ids([v for row in rows for v in row])), (2, recharge.ids(extra))]
        if token is not None:
            messages.append((3, recharge.ids([token])))
        return b"".join(protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, mid)
                        + protocol.encode_pb_field(2, 2, raw)) for mid, raw in messages)

    def test_query_has_native_rows_and_does_not_settle_or_write_roles(self):
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        groups = self.groups(self.success(1, 6211))
        self.assertEqual(set(groups), {2, 3, 4, 10, 20})
        self.assertEqual(len(protocol.parse_ids_pb(groups[3])), 15 * 8)
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))

    def test_execution_first_returns_an_unpaid_server_quote(self):
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        groups = self.groups(self.success(1, 6212, raw=self.body([(2, 1, 1, 0, 0, 0, 0)])))
        quote = protocol.parse_ids_pb(groups[101])
        self.assertGreater(quote[0], 0)
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))

    def quote(self, rows):
        return protocol.parse_ids_pb(self.groups(self.success(1, 6212, raw=self.body(rows)))[101])

    def execute(self, rows):
        quote = self.quote(rows)
        result = self.request(1, 6212, raw=self.body(rows, quote[0]))
        self.assertEqual(result[0][0], 6212, result)
        self.refresh()
        return self.groups(result[0][1]), quote, result

    def reasons(self, groups):
        return {key: value.decode() for key, value in self.groups(groups[200]).items()}

    def strong(self, weak=False):
        world = bytes.fromhex(self.save["world_state"]["1002"])
        for raw in formation.records(world, 1, 2).values():
            for field, value in ((6, 1 if weak else 10000000), (7, 0), (8, 100 if weak else 10000000), (9, 1 if weak else 1000)):
                raw = protocol.pb_set_varint(raw, field, value)
            player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, raw))
            player.record_protagonist_general(self.save, raw)

    def tower(self):
        state = mieshendian.get_state(self.save, self.config)
        state.update(maxfloor=5, maxstar=5, best={str(i): 1 for i in range(1, 6)})

    def test_malformed_duplicate_extra_unknown_and_unmatched_comb_requests_do_not_execute(self):
        valid = self.body([(2, 1, 1, 0, 0, 0, 0)])
        cases = [b"", b"\x08", b"\x10\x01", valid+valid, valid+b"\x10\x00",
                 self.body([(2, 1, 1, 1, 0, 0, 0)]), self.body([(2, 1, 1001, 0, 0, 0, 0)]),
                 self.body([(5, 1, 0, 0, 0, 0, 0)]), self.body([(2, 8, 0, 0, 0, 0, 0)]),
                 self.body([(2, 1, 1, 0, 0, 0, 0)]*2), self.body([(2, 1, 1, 0, 0, 0, 0)], extra=[1]),
                 self.body([(2, 1, 1, 0, 0, 0, 0)], token=0)]
        for raw in cases:
            with self.subTest(raw=raw):
                self.assert_rejected(6212, raw=raw)
        self.assert_rejected(6211, values=[1])
        self.assert_rejected(999900, raw=protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 6212)+protocol.encode_pb_field(2, 2, valid)))
        self.save["role_state"]["level"] = 49
        self.assert_rejected(6211)
        self.assert_rejected(6212, raw=valid)

    def test_confirmation_binds_exact_settings_save_token_time_and_forward_day(self):
        rows = [(3, 9, 0, 0, 0, 0, 0)]
        self.assert_rejected(6212, raw=self.body(rows, 123))
        quote = self.quote(rows)
        self.assert_rejected(6212, raw=self.body(rows, quote[0]+1))
        self.assert_rejected(6212, raw=self.body([(3, 9, 1, 0, 0, 0, 0)], quote[0]))
        self.save["role_state"]["gold"] += 1
        self.assert_rejected(6212, raw=self.body(rows, quote[0]))
        quote = self.quote(rows)
        self.clock.return_value += 60
        self.assert_rejected(6212, raw=self.body(rows, quote[0]))
        self.clock.return_value = ((int(self.clock.return_value)+28800)//86400+1)*86400-28801
        quote = self.quote(rows)
        self.clock.return_value += 2
        self.assert_rejected(6212, raw=self.body(rows, quote[0]))
        quote = self.quote(rows)
        self.clock.return_value -= 1
        self.assert_rejected(6212, raw=self.body(rows, quote[0]))

    def test_quote_does_not_roll_battle_or_random_rewards(self):
        with patch.object(player.random, "getrandbits", side_effect=AssertionError("预览不能抽奖或战斗")):
            self.assertEqual(self.quote([(3, 9, 1, 0, 0, 0, 0)])[1], 50)
        self.assertNotIn("last_arena_battle", self.save)
        self.assertNotIn("game_helper_receipt", self.save)

    def test_six_actual_activity_copies_use_earned_difficulties_and_real_loss_rules(self):
        self.strong(weak=True)
        initial = copy.deepcopy(self.save)
        for aid in activity_copy.COPIES:
            with self.subTest(aid=aid):
                self.sessions[1].save = copy.deepcopy(initial)
                self.refresh()
                weekday = int(self.config["daily_function"][str(aid)]["date"].split(";")[0])
                day = (int(self.clock.return_value)+28800)//86400
                day += (weekday-((day+3)%7+1))%7
                self.clock.return_value = day*86400
                state = activity_copy.settle(self.save, self.config, int(self.clock.return_value))
                state["copies"][str(aid)].update(cleared=1, tried=1)
                player.settle_stamina(self.save, self.config, int(self.clock.return_value))
                player.settle_campaign(self.save, self.config, int(self.clock.return_value))
                before = copy.deepcopy(self.save)
                groups, _, frames = self.execute([(2, aid, 2, 0, 0, 0, 0)])
                last = self.save["last_activity_battle"]
                self.assertFalse(last["won"])
                self.assertEqual((last["aid"], last["difficulty"]), (aid, 1))
                self.assertEqual(self.save["activity_copy_state"]["copies"][str(aid)]["used"], int(aid in activity_copy.BOSSES))
                self.assertEqual([mid for mid, _ in frames].count(6212), 1)
                self.assertTrue(all(mid not in activity_copy.BATTLES for mid, _ in frames))
                for key in ("stamina", "energy", "exp", "gold"):
                    self.assertEqual(self.save["role_state"][key], before["role_state"][key])
                self.assertEqual(self.save["world_state"]["1300"], before["world_state"]["1300"])
                if aid == 5:
                    self.assertEqual(activities.liveness_statuses(self.save, self.config, int(self.clock.return_value))[1][35], 1)
                self.assertIn("真实挑战", next(iter(self.reasons(groups).values())))

    def test_unearned_closed_days_locked_level_and_excess_attempts_are_logged_without_cost(self):
        for row in ((2, 1, 2, 0, 0, 0, 0), (2, 5, 3, 0, 0, 0, 0), (3, 3, 1, 0, 0, 0, 0), (1, 9, 0, 0, 0, 0, 0)):
            before = copy.deepcopy(self.save)
            groups, _, _ = self.execute([row])
            key = next(k for k in groups if k not in (100, 200))
            self.assertTrue(str(key).endswith("71"))
            for name in ("role_state", "world_state", "guide"):
                self.assertEqual(self.save[name], before[name])

    def test_arena_uses_real_npc_candidate_buy_limit_and_stops_on_loss(self):
        self.strong(weak=True)
        old = self.save["role_state"]["gold"]
        target = min(arena.opponents(self.save["arena_state"]["rank"], self.config))
        groups, quote, _ = self.execute([(3, 9, 1, 0, 0, 0, 0)])
        self.assertEqual(quote[1], 50)
        state = self.save["arena_state"]
        self.assertEqual((state["bought"], state["used"]), (1, 1))
        self.assertEqual(self.save["last_arena_battle"]["target"], target)
        self.assertFalse(self.save["last_arena_battle"]["won"])
        self.assertEqual(self.save["role_state"]["gold"], old-50)
        self.assertTrue(self.records(groups[309010], 10))
        self.assert_rejected(6212, raw=self.body([(3, 9, 1, 0, 0, 0, 0)]))

    def test_insufficient_total_budget_does_not_buy_anything(self):
        self.save["role_state"]["gold"] = 49
        rows = [(3, 9, 1, 0, 0, 0, 0)]
        quote = self.quote(rows)
        self.assert_rejected(6212, raw=self.body(rows, quote[0]))

    def test_mieshendian_sweep_is_real_and_paid_finish_never_exceeds_confirmed_ceiling(self):
        self.tower()
        old = self.save["role_state"]["gold"]
        groups, quote, _ = self.execute([(3, 1, 119, 0, 0, 0, 0)])
        self.assertEqual(quote[1], 8)
        self.assertEqual(self.save["role_state"]["gold"], old-8)
        state = self.save["mieshendian_state"]
        self.assertEqual((state["floor"], state["resets"], state["sweep"]), (6, 1, None))
        self.assertGreater(state["points"], 0)
        self.assertEqual(protocol.parse_ids_pb(groups[100])[2:4], [1, 2])
        self.reconnect(); self.refresh()
        self.assertEqual(self.save["mieshendian_state"]["floor"], 6)

    def test_starting_timed_sweep_does_not_grant_future_rewards_and_unconfirmed_reset_rolls_back(self):
        self.tower()
        self.execute([(3, 1, 10, 0, 0, 0, 0)])
        state = self.save["mieshendian_state"]
        self.assertEqual((state["floor"], state["points"]), (1, 0))
        self.assertEqual(state["sweep"]["target"], 5)
        before = copy.deepcopy(self.save)
        groups, _, _ = self.execute([(3, 1, 110, 0, 0, 0, 0)])
        self.assertIn("正在扫荡", next(iter(self.reasons(groups).values())))
        self.assertEqual(self.save["mieshendian_state"], before["mieshendian_state"])

    def test_free_watchstar_reuses_real_slots_counts_rewards_and_does_not_spend_gold(self):
        old = self.save["role_state"]["gold"]
        self.execute([(3, 2, 0, 0, 0, 0, 0)])
        state = self.save["watchstar_state"]
        self.assertEqual(state["forecasts"], 3)
        self.assertEqual(state["changes"], 10)
        self.assertEqual(state["slots"], [0]*8)
        self.assertGreater(state["stars"], 0)
        self.assertEqual(self.save["role_state"]["gold"], old)
        self.assertEqual(activities.liveness_statuses(self.save, self.config, int(self.clock.return_value))[1][8], 3)
        before = copy.deepcopy(self.save)
        self.execute([(3, 2, 0, 0, 0, 0, 0)])
        self.assertEqual(self.save["watchstar_state"], before["watchstar_state"])

    def test_penglai_free_dice_and_cards_do_not_reset_or_charge(self):
        old = self.save["role_state"]["gold"]
        self.execute([(3, 3, 0, 0, 0, 0, 0)])
        self.assertGreater(self.save["penglai_state"]["dice"], 0)
        self.assertEqual(self.save["penglai_state"]["count"], 0)
        self.assertEqual(self.save["role_state"]["gold"], old)
        self.assertGreater(activities.liveness_statuses(self.save, self.config, int(self.clock.return_value))[1][20], 0)

    def test_friend_sweep_targets_actual_clear_and_remaining_attempts_after_reconnect(self):
        self.save["friend_copy_state"]["cleared"] = 43001
        rows = [(3, 10, 2, 43001, 0, 0, 0)]
        self.execute(rows)
        self.assertEqual(self.save["friend_copy_state"]["attempts"], 2)
        self.assertEqual(self.save["friend_copy_state"]["wins"], {"43001": 2})
        self.reconnect(); self.refresh()
        before = copy.deepcopy(self.save)
        groups, _, _ = self.execute(rows)
        self.assertIn("次数不足", next(iter(self.reasons(groups).values())))
        self.assertEqual(self.save["friend_copy_state"], before["friend_copy_state"])
        groups, _, _ = self.execute([(3, 10, 1, 43002, 0, 0, 0)])
        self.assertIn("关卡已变化", next(iter(self.reasons(groups).values())))

    def test_single_boss_uses_current_calendar_and_saved_team_real_result(self):
        self.strong(weak=True)
        state = single_boss.settle(self.save, self.config, int(self.clock.return_value))
        kind = single_boss.boss_type(state, self.config)
        self.success(1, 3702, values=[140, kind]); self.refresh()
        self.save["single_boss_state"]["cleared"][str(kind)] = 1
        target = single_boss.levels(self.config, kind)[0]["id"]
        self.execute([(3, 12, 1, target, 0, 0, 0)])
        self.assertFalse(self.save["last_single_boss_battle"]["won"])
        self.assertEqual(self.save["single_boss_state"]["used"], 0)
        self.assertEqual(self.save["last_single_boss_battle"]["target"], target)

    def test_one_failed_item_does_not_erase_another_success_or_fake_completion(self):
        groups, _, _ = self.execute([(3, 2, 0, 0, 0, 0, 0), (3, 6, 1, 1, 0, 0, 0), (4, 1, 0, 0, 0, 0, 0)])
        self.assertIn(302010, groups)
        self.assertIn(3060171, groups)
        self.assertIn(4010171, groups)
        self.assertIn("后续批次", self.reasons(groups)[3060171])
        self.assertEqual(self.save["champion_state"]["day"], 0)
        self.assertGreater(self.save["watchstar_state"]["stars"], 0)
        self.assertFalse((self.root/"guilds.json").exists())

    def test_failed_save_and_overflow_do_not_leak_costs_rewards_or_receipts(self):
        self.tower()
        rows = [(3, 1, 19, 0, 0, 0, 0)]
        quote = self.quote(rows)
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 6212, raw=self.body(rows, quote[0]))
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))
        with patch.object(game_helper, "execute", return_value=(b"", quote[1]+1)):
            self.assert_rejected(6212, raw=self.body(rows, quote[0]))
        self.save["role_state"]["coin"] = (1 << 63)-1
        groups, _, _ = self.execute(rows)
        self.assertIn("范围", next(iter(self.reasons(groups).values())))
        self.assertEqual(self.save["mieshendian_state"], before["mieshendian_state"])

    def test_latest_receipt_prevents_recharging_after_reply_loss_reconnect_and_state_change(self):
        self.strong(weak=True)
        rows = [(3, 9, 1, 0, 0, 0, 0)]
        _, quote, _ = self.execute(rows)
        old = copy.deepcopy(self.save)
        groups = self.groups(self.success(1, 6212, raw=self.body(rows, quote[0])))
        self.assertEqual(set(groups), {103})
        self.assertEqual(self.sessions[1].save, old)
        self.reconnect(); self.refresh()
        self.success(1, 1001); self.refresh()
        old = copy.deepcopy(self.save)
        self.assertEqual(set(self.groups(self.success(1, 6212, raw=self.body(rows, quote[0])))), {103})
        self.assertEqual(self.sessions[1].save, old)
        self.assert_rejected(6212, raw=self.body([(3, 9, 0, 0, 0, 0, 0)], quote[0]))

    def test_bad_receipts_fail_closed_and_reward_merging_sums_scalar_and_nested_values(self):
        for value in (None, {}, {"token": True, "request": "a"*64}, {"token": 1, "request": "x"*64}):
            with self.subTest(value=value), self.assertRaises(ValueError):
                game_helper.receipt({"game_helper_receipt": value})
        a = activities.build_reward(self.save, "1000,7;20009,2", self.config)
        b = activities.build_reward(self.save, "1000,11;20009,3", self.config)
        raw = game_helper.merge_rewards([a, b], 50)
        self.assertEqual(protocol.pb_get_varint(raw, 1), 18)
        items = self.records(self.records(raw, 5)[0])
        self.assertEqual(sum(protocol.pb_get_varint(row, 2) for row in items), 5)
        self.assertEqual(protocol.pb_get_varint(self.records(self.records(raw, 10)[0])[0], 2), 50)

    def network_lua(self):
        lua = test_soul.SoulTests.network_lua(self, native_protobuf=True)
        lua.execute(self.client_scripts()["assets/scripts/GameHelper.so"])
        lua.execute(b'gamedata.cache.gang2status={};gamedata.cache.mieshendian={};gamedata.cache.mieshendianshop={};gamedata.cache.petsfragment={}')
        code = self.client_scripts()["assets/scripts/gamedata.so"]
        start = code.index(b"function gamedata.updatePetsFragment(")
        lua.execute(code[start:code.index(b"\nfunction ", start+1)])
        return lua

    def native(self, lua, value):
        if isinstance(value, dict):
            return lua.table_from({self.native(lua, k): self.native(lua, v) for k, v in value.items()})
        if isinstance(value, list):
            return lua.table_from([self.native(lua, v) for v in value])
        return value.encode() if isinstance(value, str) else value

    def native_request(self, lua, rows, token=None, view=1):
        params = {str(i): dict(zip(("type", "id", "param1", "param2", "param3", "param4", "param5"), row)) for i, row in enumerate(rows, 1)}
        req = {"params": params, "ext": {}, "helperView": {"generation": view}, "helperAction": view}
        if token is not None:
            req["helperToken"] = token
        return self.native(lua, req)

    def test_actual_network_pb_query_uses_fifo_string_keys_and_ignores_sequence_zero(self):
        lua = self.network_lua()
        fd = lambda raw, ser=1: self.native(lua, {"rbuf": raw, "ser": ser})
        for generation in (4, 5):
            lua.globals().UIGameHelperQueryCallback(self.native(lua, {"helperView": {"generation": generation}}))
        raw = self.success(1, 6211)
        self.assertTrue(lua.globals().NetGameHelperQueryCallback(fd(raw, 0))[b"localHelperIgnored"])
        for generation in (4, 5):
            result = lua.globals().NetGameHelperQueryCallback(fd(raw))
            self.assertEqual(result[b"helperView"][b"generation"], generation)
            self.assertTrue(result[b"data"][b"localHelperSupported"][b"2:1"])
            self.assertTrue(result[b"data"][b"localHelperSupported"][b"3:5"])
            self.assertIsNone(result[b"data"][b"localHelperSupported"][b"3:6"])
            self.assertEqual(result[b"data"][b"activity"][10][b"challengeTimes"], 3)
        self.assertTrue(lua.globals().NetGameHelperQueryCallback(fd(raw))[b"localHelperIgnored"])
        self.assertIsNone(lua.globals().gameConfig)

    def test_actual_network_quote_commit_real_gold_and_logs_are_applied_exactly_once(self):
        self.strong(weak=True)
        lua = self.network_lua()
        rows = [(3, 9, 1, 0, 0, 0, 0)]
        req = self.native_request(lua, rows)
        mode, opcode, raw = lua.globals().UIGameHelperExeCallback(req)
        self.assertEqual((mode, opcode), (1, 6212))
        old = lua.globals().gamedata[b"cache"][b"role"][b"gold"]
        fd = lambda raw, ser=1: self.native(lua, {"rbuf": raw, "ser": ser})
        reply = self.success(1, 6212, raw=raw)
        result = lua.globals().NetGameHelperExeCallback(fd(reply))
        self.assertTrue(result[b"helperQuote"])
        self.assertEqual(result[b"helperCost"], 50)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"gold"], old)
        mode, opcode, raw = lua.globals().UIGameHelperExeCallback(self.native_request(lua, rows, result[b"helperToken"]))
        self.assertEqual((mode, opcode), (1, 6212))
        self.assertEqual(lua.globals().UIGameHelperExeCallback(req)[0], 0)
        self.assertEqual(lua.globals().UIGameHelperQueryCallback(self.native(lua, {}))[0], 0)
        reply = self.success(1, 6212, raw=raw)
        self.assertTrue(lua.globals().NetGameHelperExeCallback(fd(reply, 0))[b"localHelperIgnored"])
        result = lua.globals().NetGameHelperExeCallback(fd(reply))
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"gold"], old-50)
        row = result[b"data"][b"rewards"][1]
        self.assertIn("战败".encode(), row[b"helperMessage"])
        self.assertEqual((row[b"type"], row[b"id"], row[b"errorcode"]), (3, 9, 0))
        self.assertEqual(row[b"used"][1][b"num"], 50)
        self.assertTrue(lua.globals().NetGameHelperExeCallback(fd(reply))[b"localHelperIgnored"])
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"gold"], old-50)

    def test_actual_network_only_matching_error_releases_busy_and_rejects_changed_confirmation(self):
        lua = self.network_lua()
        rows = [(3, 9, 0, 0, 0, 0, 0)]
        _, _, raw = lua.globals().UIGameHelperExeCallback(self.native_request(lua, rows, view=4))
        error = lambda mid, ser=1: self.native(lua, {"rbuf": recharge.ids([mid, 0]), "ser": ser})
        lua.globals().NetErrorMessageCallback9(error(6211))
        self.assertIsNotNone(lua.globals().gamedata[b"ext"][b"localHelperBusy"])
        lua.globals().NetErrorMessageCallback9(error(6212, 0))
        self.assertIsNotNone(lua.globals().gamedata[b"ext"][b"localHelperBusy"])
        result = lua.globals().NetErrorMessageCallback9(error(6212))
        self.assertTrue(result[b"localHelperError"])
        self.assertEqual(result[b"helperAction"], 4)
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localHelperBusy"])
        lua.globals().UIGameHelperExeCallback(self.native_request(lua, rows))
        result = lua.globals().NetGameHelperExeCallback(self.native(lua, {"rbuf": self.success(1, 6212, raw=raw), "ser": 1}))
        fail = lua.globals().UIGameHelperExeCallback(self.native_request(lua, [(3, 9, 1, 0, 0, 0, 0)], result[b"helperToken"]))
        self.assertEqual(fail[0:2], (0, 9999))
        self.assertTrue(fail[2][b"localHelperError"])

    def test_actual_native_pb_merges_real_prizes_and_keeps_failed_items_visible(self):
        self.tower()
        self.save["friend_copy_state"]["cleared"] = 43001
        lua = self.network_lua()
        rows = [(3, 1, 19, 0, 0, 0, 0), (3, 10, 2, 43001, 0, 0, 0), (3, 6, 1, 1, 0, 0, 0)]
        mode, mid, raw = lua.globals().UIGameHelperExeCallback(self.native_request(lua, rows))
        fd = lambda body: self.native(lua, {"rbuf": body, "ser": 1})
        quote = lua.globals().NetGameHelperExeCallback(fd(self.success(1, mid, raw=raw)))
        old = self.save["role_state"]["coin"]
        _, mid, raw = lua.globals().UIGameHelperExeCallback(self.native_request(lua, rows, quote[b"helperToken"]))
        result = lua.globals().NetGameHelperExeCallback(fd(self.success(1, mid, raw=raw)))
        self.refresh()
        self.assertGreater(lua.globals().gamedata[b"cache"][b"role"][b"coin"], old)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"coin"], self.save["role_state"]["coin"])
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"gold"], self.save["role_state"]["gold"])
        self.assertEqual(lua.globals().gamedata[b"cache"][b"mieshendian"][b"points"], self.save["mieshendian_state"]["points"])
        self.assertEqual(len(result[b"data"][b"rewards"]), 3)
        self.assertEqual(result[b"data"][b"rewards"][3][b"errorcode"], 71)
        self.assertIn("后续批次".encode(), result[b"data"][b"rewards"][3][b"helperMessage"])

    def unlock_star(self, maps=(42101, 42102, 42103, 42104, 42105)):
        """按原生 1300 结构标记对应普通地图全三星，只解锁这些名将章节。"""
        copies = []
        for mid in maps:
            points = b"".join(protocol.encode_pb_field(7, 2, protocol.encode_pb_field(1, 0, int(pid))
                              + protocol.encode_pb_field(3, 0, 3))
                              for pid in self.config["copy"][str(mid)])
            copies.append(protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, mid) + points))
        self.save["world_state"]["1300"] = b"".join(copies).hex()

    def test_mingjiang_query_and_quote_advertise_real_times_without_cost(self):
        self.unlock_star()
        groups = self.groups(self.success(1, 6211))
        challenge = protocol.parse_ids_pb(groups[2])
        self.assertEqual(len(challenge) % 3, 0)
        self.assertEqual(challenge[-3:], [7, 0, 0])
        supported = protocol.parse_ids_pb(groups[20])
        self.assertIn((2, 7), [tuple(supported[i:i + 2]) for i in range(0, len(supported), 2)])
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        quote = self.quote([(2, 7, 0, 0, 0, 0, 0)])
        self.assertEqual(quote[1:3], [0, 1])
        self.assertEqual((self.save, self.store.path(1).read_bytes()), (before, disk))

    def test_mingjiang_helper_challenges_real_unlocked_points_and_reports_count(self):
        self.unlock_star()
        self.strong()
        before = copy.deepcopy(self.save)
        groups, quote, _ = self.execute([(2, 7, 0, 0, 0, 0, 0)])
        self.assertEqual(quote[1], 0)
        after = json.loads(self.store.path(1).read_text())
        state = after["star_copy_state"]
        self.assertEqual(sum(state["wins"].values()), 5)
        self.assertEqual(sorted(state["progress"]), ["42101", "42102", "42103", "42104", "42105"])
        self.assertEqual(protocol.parse_ids_pb(groups[100])[4], 5)
        self.assertEqual(after["role_state"]["gold"] - before["role_state"]["gold"], 200)
        self.assertIn("名将副本真实挑战5次、胜利5次", next(iter(self.reasons(groups).values())))
        self.assertEqual(after["world_state"]["1300"], before["world_state"]["1300"])
        # 次数用尽后同一设置再次执行只记原因，不扣费、不重复发奖。
        second, _, _ = self.execute([(2, 7, 0, 0, 0, 0, 0)])
        self.assertTrue(str(next(k for k in second if k not in (100, 200))).endswith("71"))

    def test_mingjiang_helper_explicit_target_stops_on_loss_and_rejects_bad_settings(self):
        self.unlock_star()
        self.strong(weak=True)
        groups, quote, _ = self.execute([(2, 7, 0, 42101, 1, 0, 0)])
        self.assertEqual(quote[1], 0)
        self.assertIn("遇败停止", next(iter(self.reasons(groups).values())))
        self.assertEqual(json.loads(self.store.path(1).read_text())["star_copy_state"]["wins"], {})
        # 形状合法但目标/次数不合法的选关只在执行阶段按单项记原因，不影响其它项目。
        for row in ((2, 7, 2, 42101, 1, 0, 0), (2, 7, 0, 99999, 1, 0, 0),
                    (2, 7, 0, 42101, 2, 0, 0)):
            with self.subTest(row=row):
                before = copy.deepcopy(self.save)
                groups, _, _ = self.execute([row])
                self.assertTrue(str(next(k for k in groups if k not in (100, 200))).endswith("71"))
                self.assertEqual(self.save["star_copy_state"]["wins"], before["star_copy_state"]["wins"])
        # 多余参数与成对校验在请求解析阶段直接拒绝。
        self.assert_rejected(6212, raw=self.body([(2, 7, 0, 0, 0, 1, 0)]))
        self.assert_rejected(6212, raw=self.body([(2, 7, 0, 42101, 0, 0, 0)]))
        self.assert_rejected(6212, raw=self.body([(2, 7, 6, 0, 0, 0, 0)]))
        # 未解锁任何名将章节时只记录原因，不伪造挑战。
        self.save["world_state"]["1300"] = ""
        groups, _, _ = self.execute([(2, 7, 0, 0, 0, 0, 0)])
        self.assertTrue(str(next(k for k in groups if k not in (100, 200))).endswith("71"))

    def ui_lua(self):
        from lupa.lua51 import LuaRuntime

        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute('''print=function() end;printT=print;requests={};prompts={};opened={};updated=0
            UIRequest=function(t) table.insert(requests,t) end
            UIRequestEx=UIRequest
            runGamePrompt=function(t) table.insert(prompts,t.msg) end
            GameScene={layers={gameHelper={show=true,module={rootNode={},localHelperGeneration=1,
                selectPage="activity",status="normal",initData=function(self,data) self.data=data end}}},
                addUpdate=function() updated=updated+1 end}
            gameWindows={openWindow=function(self,name,data,callback) opened[#opened+1]={name=name,data=data,callback=callback} end}
        ''')
        lua.execute(self.client_scripts()["assets/scripts/UIHelper.so"].decode())
        return lua

    def test_actual_ui_binds_quotes_to_page_tab_settings_and_submits_confirmation_once(self):
        lua = self.ui_lua()
        lua.execute('''UIRequest({type=6212,params={},ext={}})
            local q=requests[1]
            UIGameHelperExe({helperQuote=true,helperCost=50,helperCount=1,helperToken=7,params={},ext={},
                helperView=q.helperView,helperAction=q.helperAction})
            assert(#requests==1 and #opened==1 and opened[1].name=="gameHelperConfirm")
            assert(opened[1].data.data[1001]==50)
            opened[1].callback();opened[1].callback()
            assert(#requests==2 and requests[2].helperToken==7)
            UIRequest({type=1003});assert(#requests==2)
            UIRequestEx({type=3201});assert(#requests==2)
            UIRequest({type=999904});assert(#requests==3)
            local r=requests[2]
            GameScene.layers.gameHelper.module.localHelperGeneration=2
            UIGameHelperExe({helperView=r.helperView,helperAction=r.helperAction,data={rewards={}}})
            assert(localHelperExecuting==nil and #opened==1)
            UIRequest({type=6212,params={},ext={}})
            q=requests[#requests]
            UIGameHelperExe({helperQuote=true,helperCost=0,helperCount=1,helperToken=8,params={},ext={},
                helperView=q.helperView,helperAction=q.helperAction})
            local old=#requests
            GameScene.layers.gameHelper.module.selectPage="task"
            opened[2].callback();assert(#requests==old)
            UIGameHelperQuery({helperView=q.helperView,data={old=true}})
            assert(GameScene.layers.gameHelper.module.data==nil)
        ''')

    def test_actual_ui_errors_clear_only_matching_execution_and_log_close_never_reapplies_rewards(self):
        lua = self.ui_lua()
        lua.execute('''UIRequest({type=6212,helperToken=4,params={},ext={}})
            local r=requests[1]
            assert(LocalHelperUIError({localHelperError=true,helperAction=r.helperAction+1}))
            assert(localHelperExecuting==r.helperAction)
            assert(LocalHelperUIError({localHelperError=true,helperAction=r.helperAction,helperView=r.helperView}))
            assert(localHelperExecuting==nil)
            UIRequest({type=6212,helperToken=5,params={},ext={}})
            r=requests[2]
            updateDataLife=function() error("日志不能再次发奖") end
            UIGameHelperExe({helperView=r.helperView,helperAction=r.helperAction,data={rewards={{}}}})
            assert(opened[1].name=="gameHelperLog" and localHelperExecuting==nil)
            opened[1].callback();assert(requests[#requests].type==6211)
        ''')

    def test_all_generated_scripts_compile_and_helper_sources_ship_with_asserted_native_controls(self):
        from lupa.lua51 import LuaRuntime

        lua = LuaRuntime(encoding=None)
        compile_lua = lua.eval(b"function(code,name) local f,e=loadstring(code,name);assert(f,e) end")
        for name, source in self.client_scripts().items():
            compile_lua(source, name.encode())
        for name in ("GameHelper", "UIHelper", "Layer_gameHelper", "window_gameHelperLog", "window_gameHelperConfirm"):
            self.assertIn("assets/scripts/"+name+".so", self.client_scripts())
        code = self.client_scripts()["assets/scripts/Layer_gameHelper.so"].decode()
        self.assertIn('local maxChallengeTimes = data.challengeTimes', code)
        self.assertIn('math.min(num,data.challengeTimes)', code)
        self.assertIn('local _curNum = math.max(minNum,math.min', code)
        self.assertIn('button:setTouchEnabled(false)', code)
        self.assertIn('UIRequest({type=6212,params=rows,ext={}})', code)

    def test_actual_four_page_initialization_only_uses_existing_ccbi_members_and_clamps_saved_settings(self):
        lua = self.ui_lua()
        code = builder.read_script("functions", "common_lua").decode()
        start = code.index("function string.split(")
        lua.execute(code[start:code.index("function string.trim(", start)])
        with zipfile.ZipFile(builder.SRC_APK) as archive:
            resources = {name: archive.read("assets/UI/youxizhushou/"+name+".ccbi")
                         for name in ("youxizhushou", "cell_kaiguan", "container_task", "container_challenge", "container_activity", "container_guild")}

        def check_member(path, name):
            embedded = re.sub(r"_\d+$", "", name).encode()
            self.assertTrue(name.encode() in resources[path] or embedded.startswith(b"s_") and embedded in resources["cell_kaiguan"], (path, name))

        lua.globals().check_member = check_member
        lua.globals().config = self.native(lua, self.config)
        lua.execute('''
            local count=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            table.getTableLength=count
            table.copy=function(t) local r={} for k,v in pairs(t) do r[k]=type(v)=="table" and table.copy(v) or v end return r end
            ui={ccbNameEx=function(name,id) return name..(id==1 and "" or "_"..(id-1)) end,
                addGray=function() end,removeGray=function() end,
                makeTimeText=tostring,getVipLevelByStr=function() return 0 end}
            GameScene.roleinfo={id=1,level=150,gold=1000000};GameScene.vip={vip=0};GameScene.vipstatus={}
            gameConfig={strings={string_common=function(self,group,key) return "说明" end,lvNum=function(self,id,name) return name end}}
            gamedata={config=config};config.getConfigByName=function(self,name) return self[name] end
            CCUserDefault={sharedUserDefault=function(self) return {getStringForKey=function() return "" end} end}
            CCControlEventTouchUpInside=1
            ccp=function(x,y) return {x=x,y=y} end
            gameTimer={times={},UnrigistTimeFunc=function() end,
                rigistTime=function(self,name,value) self.times[name]=value end}
            function nativeNode()
                return {setString=function(self,v) self.text=v end,getString=function(self) return self.text or "" end,
                    setVisible=function(self,v) self.visible=v end,setTouchEnabled=function(self,v) self.enabled=v end,
                    addHandleOfControlEvent=function(self,f) self.callback=f end,
                    setSwallowsTouch=function() end,setTouchPriority=function() end,
                    setContainer=function() end,setPositionX=function() end,setPositionY=function() end,
                    getContentSize=function() return {width=100,height=100} end}
            end
            function nativeItems(path)
                return setmetatable({},{__index=function(self,name)
                    check_member(path,name);local node=nativeNode();rawset(self,name,node);return node end})
            end
            CCBReaderLoad=function(path) return nativeNode(),nativeItems(string.match(path,"[^/]+$")) end
        ''')
        layer = lua.execute(self.client_scripts()["assets/scripts/Layer_gameHelper.so"].decode())
        lua.globals().helper = layer
        lua.execute('''helper:makeInitData();helper:makeSettingData()
            helper.rootNode={};helper.rootItems=nativeItems("youxizhushou");helper.viewH=1000
            helper.showParams[3][3][1]=99;helper.showParams[3][10][1]=99;helper.showParams[3][12][1]=99
            helper.showParams[3][5][1]=99;helper.showParams[3][5][2]=99
        ''')
        challenge = {str(i): {"open": 1, "challengeTimes": 0, "maxLevel": 1} for i in range(1, 8)}
        activity = {str(i): {} for i in range(1, 16)}
        activity.update({"1": {"reset": 0, "maxlevel": 5, "endtime": 0, "curlevel": 1}, "2": {"freetimes": 10},
                         "3": {"reset": 0}, "5": {"reset": 0}, "9": {"canChallengeTimes": 5}, "10": {"openlevel": 43001, "challengeTimes": 3},
                         "12": {"openlevel": 33001, "challengeTimes": 1}})
        data = {"challenge": challenge, "activity": activity, "task": {}, "guild": {},
                "localHelperSupported": {f"{p}:{i}": True for p, i in game_helper.SUPPORTED}}
        layer.initData(layer, self.native(lua, data))
        lua.execute('''
            assert(helper.params[3][3][1]==0 and helper.params[3][10][1]==3 and helper.params[3][12][1]==1,
                helper.params[3][3][1]..","..helper.params[3][10][1]..","..helper.params[3][12][1])
            assert(helper.containers.task.items.s_bt.enabled==false)
            assert(helper.containers.guild.items.s_bt.enabled==false)
            assert(helper.containers.activity.items.s_bt_4.enabled==true)
            assert(helper.params[3][5][1]==5 and helper.params[3][5][2]==0)
            assert(helper.containers.activity.items.s_bt_8.enabled==true)
            local rows=helper:makeHelperParams("activity")
            for _,row in ipairs(rows) do assert(row.id~=6 and row.id~=8) end
            helper.selectPage="activity";helper:executeHelper(false)
            assert(requests[#requests].type==6212 and requests[#requests].helperToken==nil)
        ''')


if __name__ == "__main__":
    unittest.main()
