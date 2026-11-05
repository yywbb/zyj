"""冠军试炼：临时角色、实际v2与原生Lua，不使用正式账号。"""

import copy
import json
import struct
import unittest
import zipfile
from unittest.mock import patch

import test_game_helper
from zyj_server import activities, champion, player, protocol, recharge


def setUpModule():
    test_game_helper.setUpModule()


class ChampionTests(unittest.TestCase):
    request = test_game_helper.GameHelperTests.request
    success = test_game_helper.GameHelperTests.success
    reconnect = test_game_helper.GameHelperTests.reconnect
    add_account = test_game_helper.GameHelperTests.add_account
    refresh = test_game_helper.GameHelperTests.refresh
    records = test_game_helper.GameHelperTests.records
    groups = test_game_helper.GameHelperTests.groups
    assert_rejected = test_game_helper.GameHelperTests.assert_rejected
    grant = test_game_helper.GameHelperTests.grant
    props = test_game_helper.GameHelperTests.props
    gen = test_game_helper.GameHelperTests.gen
    strong = test_game_helper.GameHelperTests.strong
    client_scripts = classmethod(test_game_helper.GameHelperTests.client_scripts.__func__)
    body = test_game_helper.GameHelperTests.body
    quote = test_game_helper.GameHelperTests.quote
    execute = test_game_helper.GameHelperTests.execute
    reasons = test_game_helper.GameHelperTests.reasons
    native = test_game_helper.GameHelperTests.native

    def setUp(self):
        test_game_helper.GameHelperTests.setUp(self)

    def board(self):
        raw = self.success(1, 2700)
        self.refresh()
        return self.groups(raw)

    def mutate(self, opcode, values=()):
        return self.success(1, opcode, values=[self.save['champion_state']['serial'], *values])

    def shop(self):
        result = protocol.parse_ids_pb(self.success(1, 2710))
        self.refresh()
        return result

    def buy(self, slot=1, count=1):
        state = self.save['champion_state']
        cid = state['slots'][slot-1][0]
        price = int(self.config['champion_goods'][str(cid)]['consume'].strip(';').split(',')[1])
        return [state['shelf_serial'], slot, cid, count, price]

    def clear_path(self):
        for point in (1, 4, 7):
            self.mutate(2701, [point]); self.refresh()

    def test_native_board_initializes_real_npcs_and_preserves_unrelated_progress(self):
        before = copy.deepcopy(self.save)
        board = self.board()
        self.assertEqual(protocol.parse_ids_pb(board[0]), [1, 0, 0, 0, 0])
        self.assertEqual(set(board), {0, *range(1, 10), 100})
        for raw in (board[i] for i in range(1, 10)):
            params = [value for n, w, value in protocol.iter_pb_fields(raw) if (n, w) == (1, 2)]
            self.assertTrue(next(v for n, w, v in protocol.iter_pb_fields(params[4]) if (n, w) == (2, 2)).startswith(b'NPC'))
        self.assertEqual(self.save['world_state'], before['world_state'])
        self.reconnect(); self.refresh()
        self.assertEqual(self.board(), board)

    def test_actual_victory_consumes_attempt_and_rewards_points_once(self):
        self.strong(); self.board()
        reply = self.mutate(2701, [1])
        self.refresh()
        self.assertEqual(protocol.pb_get_varint(reply, 1), 1)
        report = json.loads(next(v for n, w, v in protocol.iter_pb_fields(reply) if (n, w) == (5, 2)))
        self.assertTrue(report['result'])
        self.assertEqual(self.save['champion_state']['cleared'], [1])
        self.assertEqual(self.save['champion_state']['used'], 1)
        expected = int(self.config['champion_produce']['150']['1']['stronghold1'].strip(';').split(',')[1])
        self.assertEqual(self.save['champion_state']['points'], expected)
        self.assert_rejected(2701, values=[self.save['champion_state']['serial'], 1])

    def test_loss_consumes_one_attempt_no_reward_or_attrition_and_auto_stops(self):
        self.strong(weak=True); self.board()
        before = copy.deepcopy(self.save)
        result = self.groups(self.mutate(2705, [1, 5, 260]))
        self.refresh()
        self.assertEqual(protocol.parse_ids_pb(result[0]), [1, 0, 1, 0, 0, 0])
        self.assertEqual(self.save['champion_state']['used'], 1)
        self.assertFalse(self.save['last_champion_battle']['won'])
        for key in ('role_state', 'world_state', 'protagonist_snapshot', 'guide'):
            self.assertEqual(self.save[key], before[key])
        self.assertEqual(protocol.parse_ids_pb(self.board()[0]), [1, 1, 0, 0, 0])

    def test_two_stages_adjacent_gates_free_box_and_exact_five_box_prices(self):
        self.strong(); self.board()
        self.assert_rejected(2701, values=[self.save['champion_state']['serial'], 7])
        self.assert_rejected(2702, values=[self.save['champion_state']['serial']])
        self.clear_path()
        self.assert_rejected(2702, values=[self.save['champion_state']['serial']])
        old = self.save['role_state']['gold']
        for opened, price in enumerate((0, 10, 20, 40, 60), 1):
            raw = self.groups(self.mutate(2704, [price])); self.refresh()
            self.assertEqual(protocol.parse_ids_pb(raw[0]), [3 if opened == 5 else 2, opened])
            self.assertEqual(self.save['role_state']['gold'], old-sum((0, 10, 20, 40, 60)[:opened]))
        self.assert_rejected(2704, values=[self.save['champion_state']['serial'], 60])
        self.mutate(2702); self.refresh()
        self.assertEqual((self.save['champion_state']['stage'], self.save['champion_state']['used']), (2, 3))
        self.clear_path()
        self.mutate(2704, [0]); self.refresh()
        self.assert_rejected(2702, values=[self.save['champion_state']['serial']])
        self.assert_rejected(2701, values=[self.save['champion_state']['serial'], 2])

    def test_auto_runs_six_actual_fights_and_only_confirmed_boxes_with_atomic_costs(self):
        self.strong(); self.board()
        old = self.save['role_state']['gold']
        result = self.groups(self.mutate(2705, [2, 3, 60])); self.refresh()
        self.assertEqual(protocol.parse_ids_pb(result[0]), [6, 6, 0, 2, 6, 60])
        self.assertEqual(self.save['role_state']['gold'], old-60)
        self.assertEqual((self.save['champion_state']['stage'], self.save['champion_state']['used'], self.save['champion_state']['boxes']), (2, 6, 3))
        self.assertEqual(self.save['last_champion_battle']['point'], 8)
        self.reconnect(); self.refresh()
        self.assertEqual(self.save['champion_state']['boxes'], 3)
        for key in ('stamina', 'energy', 'exp'):
            self.assertEqual(self.save['role_state'][key], self.sessions[2].save['role_state'][key])

    def test_reset_vip_free_then_paid_preserves_currency_and_only_forward_day_resets(self):
        self.strong(); self.board()
        self.assert_rejected(2703, values=[self.save['champion_state']['serial'], 0])
        self.save['role_state']['vip'] = 9
        self.mutate(2701, [1]); self.refresh()
        old = self.save['champion_state']['points']
        self.mutate(2703, [0]); self.refresh()
        self.assertEqual((self.save['champion_state']['used'], self.save['champion_state']['resets']), (0, 1))
        gold = self.save['role_state']['gold']
        self.assert_rejected(2703, values=[self.save['champion_state']['serial'], 0])
        self.mutate(2703, [300]); self.refresh()
        self.assertEqual(self.save['role_state']['gold'], gold-300)
        self.assertEqual(self.save['champion_state']['points'], old)
        self.assert_rejected(2703, values=[self.save['champion_state']['serial'], 450])
        self.clock.return_value += 86400
        self.board()
        self.assertEqual((self.save['champion_state']['used'], self.save['champion_state']['resets'], self.save['champion_state']['points']), (0, 0, old))
        self.clock.return_value -= 86400
        self.assert_rejected(2703, values=[self.save['champion_state']['serial'], 0])

    def test_shop_spends_points_not_gold_and_daily_50_claim_is_atomic_once(self):
        self.grant(1009, 1000000)
        self.shop()
        values = self.buy()
        before = copy.deepcopy(self.save)
        self.success(1, 2711, values=values); self.refresh()
        self.assertEqual(self.save['champion_state']['points'], before['champion_state']['points']-values[-1])
        self.assertEqual(self.save['role_state']['gold'], before['role_state']['gold'])
        self.assertEqual(activities.liveness_statuses(self.save, self.config, int(self.clock.return_value))[1][50], 1)
        self.assert_rejected(2711, values=values)
        old = self.save['champion_state']['points']
        self.success(1, 2411, values=[150]); self.refresh()
        self.assertEqual(self.save['champion_state']['points'], old+50)
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 6517))[0], 5)
        self.reconnect(); self.refresh()
        self.assert_rejected(2411, values=[150])
        self.assertEqual(sum(self.config['liveness'][str(t)]['point'] for t in activities.LIVENESS_TASKS), 90)

    def test_shop_refresh_and_scheduled_boundary_bind_real_shelf_and_price(self):
        self.grant(1009, 1000000); self.shop()
        values = self.buy()
        before_gold = self.save['role_state']['gold']
        result = protocol.parse_ids_pb(self.success(1, 2712, values=[values[0], 20])); self.refresh()
        self.assertEqual((result[0], self.save['champion_state']['points']), (999980, 999980))
        self.assertEqual(self.save['role_state']['gold'], before_gold)
        self.assert_rejected(2711, values=values)
        values = self.buy()
        self.clock.return_value = ((int(self.clock.return_value)+28800)//43200+1)*43200-28800
        self.assert_rejected(2711, values=values)
        self.shop()
        self.assertGreater(self.save['champion_state']['shelf_serial'], values[0])
        self.assertEqual(self.save['champion_state']['points'], 999980)
        self.assertEqual(activities.liveness_statuses(self.save, self.config, int(self.clock.return_value))[1][50], 0)

    def test_legacy_unquoted_malformed_extra_and_unmatched_comb_requests_never_mutate(self):
        self.board(); self.shop()
        for opcode in champion.OPCODES:
            for raw in (b'\x08', b'\x10\x01', b'\x0a\x00', recharge.ids([1]*(8 if opcode in champion.MUTATIONS else 1))):
                self.assert_rejected(opcode, raw=raw)
        for opcode, values in ((2701, [1]), (2702, []), (2703, []), (2704, []), (2705, [1, 1]), (2711, [1, 1]), (2712, [])):
            self.assert_rejected(opcode, values=values)
        self.assert_rejected(999900, raw=protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 2701)+protocol.encode_pb_field(2, 2, recharge.ids([1]))))
        self.save['role_state']['level'] = 49
        self.assert_rejected(2700)
        self.assert_rejected(2710)

    def test_stale_board_quotes_gates_and_insufficient_money_do_not_charge_or_roll(self):
        self.board()
        self.assert_rejected(2704, values=[self.save['champion_state']['serial'], 0])
        self.assert_rejected(2705, values=[self.save['champion_state']['serial'], 0, 1, 0])
        self.assert_rejected(2705, values=[self.save['champion_state']['serial'], 1, 6, 0])
        self.assert_rejected(2705, values=[self.save['champion_state']['serial'], 1, 5, 130])
        self.save['role_state']['gold'] = 59
        self.assert_rejected(2705, values=[self.save['champion_state']['serial'], 1, 3, 60])
        self.save['role_state']['gold'] = 1000000
        self.save['role_state']['level'] = 80
        self.assert_rejected(2705, values=[self.save['champion_state']['serial'], 1, 1, 0])
        self.save['role_state']['level'] = 150
        self.strong()
        serial = self.save['champion_state']['serial']
        self.mutate(2701, [1]); self.refresh()
        self.assert_rejected(2701, values=[serial, 2])
        self.shop(); self.save['champion_state']['points'] = 0
        self.assert_rejected(2711, values=self.buy())
        self.assert_rejected(2712, values=[self.save['champion_state']['shelf_serial'], 20])

    def test_save_failures_overflows_and_bad_state_never_publish_partial_transactions(self):
        self.strong(); self.board(); self.grant(1009, 1000000); self.shop()
        for opcode, values in ((2701, [self.save['champion_state']['serial'], 1]), (2711, self.buy()), (2712, [self.save['champion_state']['shelf_serial'], 20])):
            before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
            with patch.object(player, 'save_role', return_value=False), self.assertRaises(OSError):
                self.request(1, opcode, values=values)
            self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))
        self.save['champion_state']['points'] = (1 << 31)-1
        self.assert_rejected(2701, values=[self.save['champion_state']['serial'], 1])
        self.save['champion_state']['points'] = 0
        for field, value in (('points', True), ('serial', 0), ('cleared', [7]), ('boxes', 1), ('slots', [[100001, -1]]), ('checked_at', None)):
            invalid = copy.deepcopy(self.save)
            invalid['champion_state'][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                champion.get_state(invalid, self.config)

    def test_paid_batch_box_reset_save_failures_and_reconnect_stale_versions_are_atomic(self):
        self.strong(); self.board()
        for opcode, args in ((2705, [1, 5, 260]), (2703, [0])):
            self.save['role_state']['vip'] = 9
            player.save_role(self.save, self.store.path(1), self.sessions[1].step_counts)
            before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
            with patch.object(player, 'save_role', return_value=False), self.assertRaises(OSError):
                self.mutate(opcode, args)
            self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))
            self.reconnect(); self.refresh()
        self.clear_path()
        self.mutate(2704, [0]); self.refresh()
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        with patch.object(player, 'save_role', return_value=False), self.assertRaises(OSError):
            self.mutate(2704, [10])
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))
        self.reconnect(); self.refresh()
        values = [self.save['champion_state']['serial'], 10]
        packets = self.request(1, 2704, values=values)
        self.refresh()
        before = copy.deepcopy(self.save)
        cached = self.sessions[1].handle(2704, self.seq, recharge.ids(values))
        self.assertEqual([(struct.unpack('>IIII', raw[:16])[2], raw[16:]) for raw in cached], packets)
        self.assertEqual(self.sessions[1].save, before)
        self.reconnect(); self.refresh()
        self.assert_rejected(2704, values=values)
        old_serial = self.save['champion_state']['serial']
        self.clock.return_value += 86400
        self.assert_rejected(2701, values=[old_serial, 1])
        self.board()
        self.assertGreater(self.save['champion_state']['serial'], old_serial)

    def test_all_88_shop_rewards_18_npcs_and_202_reward_rows_are_supported(self):
        self.strong(); self.board()
        state = self.save['champion_state']
        for level in (50, 150):
            state['level'] = level
            for stage in (1, 2):
                state['stage'] = stage
                for point in range(1, 10):
                    _, row = champion.npc(state, point, self.config)
                    attack, defense = champion.arena.rosters(self.save, row, self.config)
                    report = champion.battle.simulate(attack, defense, self.config, point)
                    self.assertIn(report['result'], (True, False))
        for row in self.config['champion_goods'].values():
            activities.build_reward(self.save, row['good'], self.config, row['limit'])
        for stages in self.config['champion_produce'].values():
            for row in stages.values():
                for name, reward in row.items():
                    if name.startswith(('stronghold', 'storehouse')):
                        activities.build_reward(self.save, reward, self.config)

    def test_helper_quotes_real_rounds_explicit_resets_and_never_repeats_rewards(self):
        self.strong(); self.save['role_state']['vip'] = 9
        before = self.save['role_state']['gold']
        rows = [(3, 5, 3, 2, 0, 0, 0)]
        with patch.object(champion.battle, 'simulate', side_effect=AssertionError('报价不能战斗')):
            self.assertEqual(self.quote(rows)[1], 480)
        groups, quote, packets = self.execute(rows)
        self.assertEqual(self.save['role_state']['gold'], before-480)
        self.assertEqual(self.save['champion_state']['resets'], 2)
        self.assertEqual(self.save['champion_state']['used'], 6)
        self.assertIn('真实挑战18次、胜利18次、开箱18次', next(iter(self.reasons(groups).values())))
        self.assertIn(2700, [mid for mid, _ in packets])
        old = copy.deepcopy(self.save)
        self.reconnect(); self.refresh()
        self.assertEqual(set(self.groups(self.success(1, 6212, raw=self.body(rows, quote[0])))), {103})
        self.assertEqual(self.save['champion_state'], old['champion_state'])
        self.assertEqual(self.save['role_state'], old['role_state'])

    def test_helper_stops_on_loss_without_resetting_or_charging_unopened_boxes(self):
        self.strong(weak=True); self.save['role_state']['vip'] = 9
        gold = self.save['role_state']['gold']
        groups, quote, _ = self.execute([(3, 5, 5, 2, 0, 0, 0)])
        self.assertEqual(quote[1], 1080)
        self.assertEqual((self.save['champion_state']['used'], self.save['champion_state']['resets']), (1, 0))
        self.assertEqual(self.save['role_state']['gold'], gold)
        self.assertIn('明确重置0次', next(iter(self.reasons(groups).values())))
        self.save['role_state']['level'] = 80; self.save['role_state']['vip'] = 0
        groups, _, _ = self.execute([(3, 5, 1, 0, 0, 0, 0)])
        self.assertIn('90级或VIP6', next(iter(self.reasons(groups).values())))

    def network_lua(self):
        lua = test_game_helper.test_soul.SoulTests.network_lua(self, native_protobuf=True)
        code = self.client_scripts()['assets/scripts/gamedata.so'].decode()
        start = code.index('function gamedata.ChampionShop(')
        lua.execute(code[start:code.index('function gamedata.PetsData(', start)].encode())
        for name in ('checkEquipNum', 'equipfragmentData', 'updateequipfragment', 'EquipFragments'):
            start = code.index('function gamedata.'+name+'(')
            lua.execute(code[start:code.index('\nfunction ', start+1)].encode())
        lua.globals().champion_now = lambda: int(self.clock.return_value)
        lua.execute(b'gamedata.cache.champion={status={},points={}};gamedata.cache.championShop={};gamedata.cache.equipfragments={};gamedata.time=function() return champion_now() end')
        lua.execute(self.client_scripts()['assets/scripts/GameChampion.so'])
        return lua

    def native_call(self, lua, send, receive, req):
        mode, opcode, raw = lua.globals()[send.encode()](self.native(lua, req))
        self.assertEqual(mode, 1)
        packets = self.request(1, opcode, raw=raw or b'')
        self.assertEqual(packets[0][0], opcode, packets)
        result = lua.globals()[receive.encode()](self.native(lua, dict(rbuf=packets[0][1], ser=1)))
        for mid, raw in packets[1:]:
            callback = {2700: 'NetChampionStatusCallBack', 2710: 'NetChampionShopQueryCallBack'}.get(mid)
            if callback:
                lua.globals()[callback.encode()](self.native(lua, dict(rbuf=raw, ser=0)))
        self.refresh()
        return result, packets[0][1]

    def test_actual_native_pb_board_fifo_preserves_queries_around_seq0_and_has_no_ui_globals(self):
        lua = self.network_lua()
        for generation in (1, 2):
            lua.globals().UIChampionStatusCallBack(self.native(lua, dict(championView=dict(generation=generation))))
        raw = self.board()
        raw = champion.board(self.save, self.save['champion_state'], self.config)
        lua.globals().NetChampionStatusCallBack(self.native(lua, dict(rbuf=raw, ser=0)))
        for generation in (1, 2):
            result = lua.globals().NetChampionStatusCallBack(self.native(lua, dict(rbuf=raw, ser=1)))
            self.assertEqual(result[b'championView'][b'generation'], generation)
            self.assertEqual(result[b'champion'][b'localSerial'], self.save['champion_state']['serial'])
            self.assertEqual(len(result[b'champion'][b'points']), 0)  # 原生使用字符串据点键。
            self.assertEqual(result[b'champion'][b'points'][b'1'][b'status'], 1)
        self.assertTrue(lua.globals().NetChampionStatusCallBack(self.native(lua, dict(rbuf=raw, ser=1)))[b'localChampionIgnored'])
        self.assertIsNone(lua.globals().gameConfig)

    def test_actual_native_pb_fights_boxes_auto_and_shop_charge_once_then_calibrate(self):
        self.strong(); self.grant(1009, 1000000)
        lua = self.network_lua()
        self.native_call(lua, 'UIChampionStatusCallBack', 'NetChampionStatusCallBack', {})
        serial = self.save['champion_state']['serial']
        result, raw = self.native_call(lua, 'UIChampionBattleCallBack', 'NetChampionBattleCallBack', dict(id=1, championSerial=serial, isauto=True))
        self.assertEqual(result[b'isauto'], 1)
        self.assertEqual(json.loads(result[b'battlereport'])['result'], True)
        self.assertTrue(lua.globals().NetChampionBattleCallBack(self.native(lua, dict(rbuf=raw, ser=1)))[b'localChampionIgnored'])
        for point in (4, 7):
            self.native_call(lua, 'UIChampionBattleCallBack', 'NetChampionBattleCallBack', dict(id=point, championSerial=self.save['champion_state']['serial']))
        for price in (0, 10):
            self.native_call(lua, 'UIChampionBoxOpenCallBack', 'NetChampionBoxOpenCallBack', dict(championSerial=self.save['champion_state']['serial'], championGold=price, xgold=price))
        self.assertEqual(lua.globals().gamedata[b'cache'][b'role'][b'gold'], self.save['role_state']['gold'])
        state = self.save['champion_state']
        ceiling = champion.auto_cost(state, 3, self.config)
        self.native_call(lua, 'UIChampionCompleteCallBack', 'NetChampionCompleteCallBack', dict(championSerial=state['serial'], championConfirmed=True, championCeiling=ceiling, path=1, times=3, res='试炼'))
        self.assertEqual(lua.globals().gamedata[b'cache'][b'role'][b'gold'], self.save['role_state']['gold'])
        self.native_call(lua, 'UIChampionShopQueryCallBack', 'NetChampionShopQueryCallBack', {})
        state = self.save['champion_state']
        self.native_call(lua, 'UIChampionShopCallBack', 'NetChampionShopCallBack', dict(championShelf=state['shelf_serial'], id=1, goodid=state['slots'][0][0], num=1))
        self.assertEqual(lua.globals().gamedata[b'cache'][b'championShop'][b'championpoint'], self.save['champion_state']['points'])
        gold = self.save['role_state']['gold']
        self.native_call(lua, 'UIChampionShopResetCallBack', 'NetChampionShopResetCallBack', dict(championShelf=self.save['champion_state']['shelf_serial'], xgold=99999))
        self.assertEqual(lua.globals().gamedata[b'cache'][b'championShop'][b'championpoint'], self.save['champion_state']['points'])
        self.assertEqual(lua.globals().gamedata[b'cache'][b'role'][b'gold'], gold)

    def test_actual_network_matching_error_releases_only_its_operation_and_stale_targets_fail(self):
        lua = self.network_lua()
        self.native_call(lua, 'UIChampionStatusCallBack', 'NetChampionStatusCallBack', {})
        req = dict(id=1, championSerial=self.save['champion_state']['serial'])
        self.assertEqual(lua.globals().UIChampionBattleCallBack(self.native(lua, req))[0], 1)
        self.assertEqual(lua.globals().UIChampionBattleCallBack(self.native(lua, req))[0], 0)
        for opcode, ser in ((2704, 1), (2701, 0)):
            lua.globals().NetErrorMessageCallback9(self.native(lua, dict(rbuf=recharge.ids([opcode, 0]), ser=ser)))
            self.assertEqual(lua.globals().gamedata[b'ext'][b'localChampionBusy'], 2701)
        lua.globals().NetErrorMessageCallback9(self.native(lua, dict(rbuf=recharge.ids([2701, 0]), ser=1)))
        self.assertIsNone(lua.globals().gamedata[b'ext'][b'localChampionBusy'])
        req['championSerial'] -= 1
        self.assertEqual(lua.globals().UIChampionBattleCallBack(self.native(lua, req))[0], 0)
        lua.globals().gamedata[b'ext'][b'localHelperBusy'] = lua.table()
        self.assertEqual(lua.globals().UIChampionStatusCallBack(self.native(lua, {}))[0], 0)

    def test_actual_native_pb_accepts_every_shop_reward_not_just_one_random_shelf(self):
        lua = self.network_lua()
        process = lua.eval(b'''function(raw)
            local message=require('somethings_pb').SomeThings();message:ParseFromString(raw)
            local reward=gamedata:SomethingProcess(message)
            assert(#reward>0)
        end''')
        for cid, row in self.config['champion_goods'].items():
            with self.subTest(cid=cid):
                reward = activities.build_reward(self.save, row['good'], self.config, row['limit'])
                player.apply_reward(self.save, reward, self.config, int(self.clock.return_value))
                process(reward)

    def ui_lua(self):
        from lupa.lua51 import LuaRuntime

        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.globals().config = lua.table_from(self.config, recursive=True)
        lua.execute('''print=function() end;printT=print;requests={};opened={};prompts={};reloads=0
            UIRequest=function(t) requests[#requests+1]=t end
            runGamePrompt=function(t) prompts[#prompts+1]=t.msg end
            local module={rootNode={},localChampionGeneration=1,data={localSerial=5,localLevel=150,status={pass=1,boxopen=0}},
                reload=function(self,data) self.data=data;reloads=reloads+1 end}
            GameScene={presentLayer="champion",layers={champion={show=true,module=module},daily={show=false,module={}}},
                shiftLayer=function(self,name) self.presentLayer=name;for key,row in pairs(self.layers) do row.show=key==name end end}
            gameWindows={windows={championbox={show=false}},openWindow=function(self,name,data,callback)
                opened[#opened+1]={name=name,data=data,callback=callback} end}
            gamedata={config=config};RunbattleCallBack=function() end;showRewardPopupWindow=function() end
        ''')
        lua.execute(self.client_scripts()['assets/scripts/UIChampion.so'].decode())
        return lua

    def test_actual_ui_confirms_exact_remaining_ceiling_once_and_cancels_changed_generations(self):
        lua = self.ui_lua()
        lua.execute('''UIRequest({type=2705,path=2,times=3})
            assert(#requests==0 and #opened==1)
            opened[1].callback();opened[1].callback()
            assert(#requests==1 and requests[1].championCeiling==60 and requests[1].championConfirmed)
            assert(requests[1].championSerial==5)
            UIRequest({type=2705,path=1,times=5})
            GameScene.layers.champion.module.data.localSerial=6
            opened[2].callback();assert(#requests==1)
            UIRequest({type=2705,path=1,times=5})
            GameScene:shiftLayer("daily");GameScene:shiftLayer("champion")
            opened[3].callback();assert(#requests==1)
            GameScene.layers.champion.module.data.status={pass=2,boxopen=2}
            UIRequest({type=2705,path=1,times=3})
            opened[4].callback();assert(#requests==2 and requests[2].championCeiling==20)
        ''')

    def test_actual_ui_ignores_old_page_window_and_entry_results_without_reopening(self):
        lua = self.ui_lua()
        lua.execute('''UIRequest({type=2700});local view=requests[1].championView
            UIChampionStatus({type=2700,championView=view,champion={localSerial=6,status={pass=1}}})
            assert(reloads==1)
            GameScene.layers.champion.module.localChampionGeneration=2
            UIChampionStatus({type=2700,championView=view,champion={status={pass=1}}});assert(reloads==1)
            package.loaded.window_championBox={rootNode={},localChampionGeneration=1,data={localSerial=6}}
            UIRequest({type=2704,xgold=10});view=requests[2].championView
            package.loaded.window_championBox.localChampionGeneration=2
            UIChampionBoxOpen({type=2704,championView=view,champion={status={pass=1}}});assert(reloads==1)
            GameScene:shiftLayer("daily");UIRequest({type=2700,param="main"});view=requests[3].championView
            GameScene:shiftLayer("champion");GameScene:shiftLayer("daily")
            UIChampionStatus({type=2700,param="main",championView=view,champion={status={pass=1}}})
            assert(GameScene.presentLayer=="daily")
            UIRequest({type=2700,param="main"});view=requests[4].championView
            UIChampionStatus({type=2700,param="main",championView=view,champion={status={pass=1}}})
            assert(GameScene.presentLayer=="champion")
        ''')

    def test_actual_shop_timer_uses_real_utc8_seconds_under_acceleration_and_stops_after_exit(self):
        lua = self.ui_lua()
        lua.execute('''now=1793430000;timerCallback=nil;timerQueries=0
            gamedata.time=function() return now end
            ui={makeTimeText=tostring}
            gameTimer={times={},rigistTime=function(self,key,value) self.times[key]=value end,
                rigistTimeFunc=function(self,key,callback) timerCallback=callback end,
                UnrigistTimeFunc=function(self,key) self.times[key]=nil;timerCallback=nil end}
            UIRequest=function(req) assert(req.type==2710);timerQueries=timerQueries+1 end
        ''')
        shop = lua.execute(self.client_scripts()['assets/scripts/Layer_activity_championshop.so'].decode())
        lua.globals().shop = shop
        lua.execute('''shop.show=true;shop.coverccb={};shop.localChampionGeneration=1
            shop.coveritems={updatetime={setString=function(self,text) self.text=text end}}
            for _,speed in ipairs({1,3,10}) do
                shop:updatetimeFunc()
                local remaining=gameTimer.times.championshop_reset
                for tick=1,10*speed do gameTimer.times.championshop_reset=0;timerCallback() end
                assert(gameTimer.times.championshop_reset==remaining and timerQueries==0)
            end
            local deadline=now+gameTimer.times.championshop_reset
            now=deadline-180;assert(not shop:refreshJudge())
            now=deadline-181;assert(shop:refreshJudge())
            now=deadline;timerCallback();assert(timerQueries==1 and timerCallback==nil)
            shop:updatetimeFunc();local stale=timerCallback
            shop.localChampionGeneration=2;stale();assert(timerQueries==1)
        ''')

    def test_all_18_npc_reports_convert_with_actual_apk_animation_assets(self):
        from lupa.lua51 import LuaRuntime
        import build_local_apk as builder

        self.strong(); self.board()
        lua = LuaRuntime()
        config = dict(self.config)
        with zipfile.ZipFile('configs_sec5.zip') as archive:
            for name in ('generalanimation', 'skillanimation'):
                config[name] = json.loads(archive.read('5/'+name+'.json'))
        lua.globals().gamedata = lua.table_from({'config': config}, recursive=True)
        lua.execute('''print=function() end;printT=print;battleScene={slotNum=7}
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            CCFileUtils={sharedFileUtils=function(self) return self end,fullPathForFilename=function(self,p) return p end}
            ui={Split=function(s,sep) local t={} for v in string.gmatch(s,'[^'..sep..']+') do t[#t+1]=v end return t end}''')
        with zipfile.ZipFile(builder.SRC_APK) as archive:
            names, assets = archive.namelist(), {}
            lua.globals().CCFileUtils.isFileExist = lambda _, path: any(n.endswith('/'+path) for n in names)
            def load_asset(path):
                if path not in assets:
                    matches = [n for n in names if n.endswith('/'+path)]
                    self.assertEqual(len(matches), 1, path)
                    assets[path] = json.loads(archive.read(matches[0]))
                return lua.table_from(assets[path], recursive=True)
            lua.globals().LoadJsonFileToTable = load_asset
            lua.execute(self.client_scripts()['assets/scripts/battleReportConvert.so'])
            lua.execute(builder.read_script('BattleReportAbbToKey'))
            for stage in (1, 2):
                state = dict(self.save['champion_state'], stage=stage)
                for point in range(1, 10):
                    _, row = champion.npc(state, point, self.config)
                    attack, defense = champion.arena.rosters(self.save, row, self.config)
                    report = champion.battle.simulate(attack, defense, self.config, point)
                    native = lua.table_from(json.loads(lua.globals().ReplaceAbbToKey(json.dumps(report))), recursive=True)
                    attack, defense = lua.globals().getBattleInitSlotInfo(native)
                    animations, ext = lua.globals().convertBattleReportToAnimationSub(native, attack, defense, None, 'champion')
                    self.assertGreater(len(animations), 1)
                    for side, key in (('attack', 'atk'), ('defense', 'def')):
                        for pos, unit in report['endmeta'][side].items():
                            self.assertEqual((ext.endinfo[key][pos].hp, ext.endinfo[key][pos].ap), (unit['h'], unit['ap']))
