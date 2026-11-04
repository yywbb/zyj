"""48级灵阵和阵符副本：临时存档、真实配置和原生Lua。"""

import copy
import json
import unittest
from unittest.mock import patch

import build_local_apk as builder
import test_soul
from zyj_server import activities, battle, cup, deployment, formation, guild_war, player, protocol, recharge, recruit, single_boss


def setUpModule():
    test_soul.setUpModule()


class DeploymentTests(unittest.TestCase):
    request = test_soul.SoulTests.request
    success = test_soul.SoulTests.success
    reconnect = test_soul.SoulTests.reconnect
    add_account = test_soul.SoulTests.add_account
    assert_rejected = test_soul.SoulTests.assert_rejected
    refresh = test_soul.SoulTests.refresh
    grant = test_soul.SoulTests.grant
    props = test_soul.SoulTests.props
    gen = test_soul.SoulTests.gen
    records = test_soul.SoulTests.records
    groups = test_soul.SoulTests.groups
    client_scripts = classmethod(test_soul.SoulTests.client_scripts.__func__)
    client_call = test_soul.SoulTests.client_call

    def setUp(self):
        test_soul.SoulTests.setUp(self)
        self.save["role_state"].update(level=150, coin=100000000000, gold=1000000)

    def query(self):
        body = self.groups(self.success(1, 4200))
        self.refresh()
        return {k: protocol.parse_ids_pb(v) for k, v in body.items()}

    def eligible(self):
        # 真实魔界伙伴置于1号位，主角移到4号位满足资质/等级条件。
        iid = 2000901
        cid = next(int(k) for k, row in self.config["general"].items()
                   if row["region"] == "3" and row["quality"] == 5 and row["actor"] != "lead" and row["battle"])
        raw = recruit.new_general(cid, iid, self.config)
        raw = protocol.pb_set_varint(protocol.pb_set_varint(raw, 3, 150), 4, 7)
        player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, raw))
        hero = protocol.pb_set_varint(self.gen(), 3, 150)
        player.record_protagonist_general(self.save, hero)
        player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, hero))
        world = bytes.fromhex(self.save["world_state"]["1002"])
        slots = formation.records(world, 4, 1)
        slots[4] = protocol.pb_set_varint(slots[1], 1, 4)
        slots[1] = protocol.pb_set_varint(slots[1], 2, iid)
        player.record_slot_update(self.save, b"".join(protocol.encode_pb_field(4, 2, s) for s in slots.values()))
        player.record_slot_update(self.save, formation.apply_slots(self.save, slots, self.config))
        return iid

    def test_locked_query_is_zero_and_unlock_initializes_only_without_free_materials_or_guide(self):
        self.save["role_state"]["level"] = 47
        before = copy.deepcopy(self.save)
        self.assertEqual(self.query(), {0: [0, 0, 0], 1: [0]*7, 2: [0]*7})
        self.assertNotIn("deployment_state", self.save)
        self.assert_rejected(4201, values=[1])
        self.save["role_state"]["level"] = 48
        memory, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 4200)
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (memory, disk))
        self.assertEqual(self.query()[1], [1]*7)
        self.assertEqual(self.props(20293), 0)
        self.assertEqual(self.save["guide"], before["guide"])
        self.reconnect(); self.refresh()
        self.assertEqual(self.query()[0][0], 1)
        self.assert_rejected(4202, values=[1, 1])

    def test_real_conditions_switching_upgrade_prices_power_and_reconnect(self):
        iid = self.eligible()
        original = copy.deepcopy(self.save)
        result = self.query()
        self.assertEqual(result[2][0], 1)
        count = sum(result[2])
        values = dict.fromkeys((6, 7, 8), 0)
        for i in range(1, count+1):
            name, amount = self.config["lingzhentu_jihuo"]["1"][str(i)]["addition1"].rstrip(";").split(",")
            values[deployment.FIELDS[name]] += int(amount)
        old = formation.records(bytes.fromhex(original["world_state"]["1002"]), 1, 2)
        for member, bonus in deployment.bonuses(self.save, self.config)[0].items():
            for field in values:
                self.assertEqual(protocol.pb_get_varint(self.gen(member), field), protocol.pb_get_varint(old[member], field)+bonus[field])
        self.grant(20293, 1000)
        coin = self.save["role_state"]["coin"]
        frames = self.request(1, 4202, values=[1, 1]); self.refresh()
        self.assertEqual(frames[0][0], 4202)
        self.assertEqual(self.save["deployment_state"]["levels"][0], 2)
        self.assertEqual((self.props(20293), self.save["role_state"]["coin"]), (930, coin-400000))
        self.assertIn(1200, [mid for mid, _ in frames])
        self.assertIn(1001, [mid for mid, _ in frames])
        self.assertLessEqual([mid for mid, _ in frames].count(205), 1)
        retry = [(int.from_bytes(p[8:12], "big"), p[16:]) for p in self.sessions[1].handle(4202, self.seq, recharge.ids([1, 1]))]
        self.assertEqual(retry, frames)
        self.assert_rejected(4202, values=[1, 1])
        self.success(1, 4201, values=[2]); self.refresh()
        self.reconnect(); self.refresh()
        self.assertEqual(self.query()[0][0], 2)
        self.success(1, 4201, values=[1]); self.refresh()
        self.assertEqual(self.query()[1][0], 2)
        attack, _ = battle.rosters(self.save, self.config["copy"]["42101"]["1"], self.config)
        self.assertEqual(attack[2]["atk"], protocol.pb_get_varint(self.gen(iid), 6))

    def test_all_seven_patterns_sixty_levels_and_84_masteries_use_final_rows_and_highest_effect(self):
        self.query()
        state = self.save["deployment_state"]
        for pattern in range(1, 8):
            for level in range(1, 61):
                state.update(use=pattern, levels=[level]*7)
                for sid, condition in self.config["lingzhentu_cond"][str(pattern)].items():
                    # 每个条件独立使用原生配置身份，不制造高级伙伴所有权。
                    candidates = [row for row in self.config["general"].values() if row["battle"]]
                    raw = next((protocol.pb_set_varint(protocol.pb_set_varint(recruit.new_general(row["generalid"], 2001000, self.config), 3, 300), 4, 23)
                                for row in candidates if (condition["param1"] != 1 or condition["param1_cond"] in row["region"].split(";"))
                                and (condition["param1"] != 5 or condition["param1_cond"] == row["sex"])
                                and (condition["param1"] != 6 or row["basic"] >= int(condition["param1_cond"]))
                                and (condition["param2"] != 6 or row["basic"] >= int(condition["param2_cond"]))), None)
                    self.assertIsNotNone(raw, (pattern, sid))
                    self.assertTrue(deployment.matches(raw, condition, self.config))
                add, active = deployment.mastery(state, self.config)
                expected = [row for row in self.config["lingzhentu_add"].values() if int(row["cond1"].split(",")[1].rstrip(";")) <= level]
                self.assertEqual(add, max((r["effect"] for r in expected), default=0))
                self.assertEqual(set(active), {r["id"] for r in expected})
        self.assertEqual((add, len(active)), (18, 84))

    def test_formation_and_dedicated_projection_remove_and_reapply_group_bonuses_without_stacking(self):
        iid = self.eligible(); self.query()
        before = copy.deepcopy(self.save)
        team = [protocol.pb_get_varint(self.gen(), 2), iid, 0, 0, 0, 0, 0, 0]
        temporary, power = single_boss.project_team(self.save, team, self.config)
        self.assertEqual(self.save, before)
        self.assertEqual(power, sum(protocol.pb_get_varint(g, 20) for key, g in formation.records(bytes.fromhex(temporary["world_state"]["1002"]), 1, 2).items() if key in team[:7]))
        with patch.object(deployment, "differences", return_value=(b"", 1 << 31)), self.assertRaisesRegex(ValueError, "战力"):
            single_boss.project_team(self.save, team, self.config)
        old_bonus = deployment.bonuses(self.save, self.config)[0]
        new_bonus = deployment.bonuses(temporary, self.config)[0]
        self.assertNotEqual(old_bonus, new_bonus)
        raw = protocol.encode_pb_field(1, 0, 1)+protocol.encode_pb_field(2, 0, 4)
        self.success(1, 1003, raw=raw); self.refresh()
        self.success(1, 1003, raw=raw); self.refresh()
        self.assertEqual(self.save["world_state"]["1002"], before["world_state"]["1002"])

    def test_stale_legacy_malformed_unmatched_and_rollback_requests_never_charge(self):
        self.query(); self.grant(20293, 1000)
        for opcode, values in ((4201, []), (4201, [0]), (4201, [8]), (4201, [1, 1]), (4202, [1]), (4202, [1, 0]), (4202, [1, 1, 1])):
            self.assert_rejected(opcode, values=values)
        for opcode in deployment.OPCODES:
            for raw in (b"\x08", b"\x10\x01", b"\x0a\x00"):
                self.assert_rejected(opcode, raw=raw)
            self.assert_rejected(999900, raw=protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, opcode)))
        self.clock.return_value -= 1
        self.assert_rejected(4201, values=[2]); self.assert_rejected(4202, values=[1, 1])

    def test_insufficient_materials_overflow_save_failures_and_invalid_saved_state_are_atomic(self):
        self.eligible(); self.query()
        self.assert_rejected(4202, values=[1, 1])
        self.grant(20293, 1000)
        self.assertTrue(player.save_role(self.save, self.store.path(1), self.sessions[1].step_counts))
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 4202, values=[1, 1])
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))
        iid = 2000901
        raw = self.gen(iid)
        player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, protocol.pb_set_varint(raw, 6, (1 << 31)-1)))
        self.assert_rejected(4202, values=[1, 1])
        player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, raw))
        self.save["role_state"]["coin"] = 0
        self.assert_rejected(4202, values=[1, 1])
        for invalid in (None, {}, {"use": True, "levels": [1]*7, "checked_at": 0},
                        {"use": 1, "levels": [0]*7, "checked_at": 0}, {"use": 1, "levels": [61]*7, "checked_at": 0}):
            saved = dict(before, deployment_state=invalid)
            with self.subTest(state=invalid), self.assertRaises(ValueError): deployment.get_state(saved, self.config)

    def test_all_413_paid_upgrades_charge_only_current_rows_and_stop_at_sixty(self):
        self.query(); self.grant(20293, 100000000)
        before = copy.deepcopy(self.save)
        coin, symbols = 0, 0
        for pattern in range(1, 8):
            for level in range(1, 60):
                row = self.config["lingzhentu_lv"][str(level)]
                cost = dict(tuple(map(int, item.split(","))) for item in row["cost"].split(";") if item)
                coin += cost[1000]; symbols += cost[20293]
                self.success(1, 4202, values=[pattern, level]); self.refresh()
            self.assert_rejected(4202, values=[pattern, 60])
        self.assertEqual(self.save["deployment_state"]["levels"], [60]*7)
        self.assertEqual(self.save["role_state"]["coin"], before["role_state"]["coin"]-coin)
        self.assertEqual(self.props(20293), 100000000-symbols)
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 4204)), [18, *range(1, 85)])
        self.reconnect(); self.refresh()
        self.assertEqual(self.query()[1], [60]*7)

    def test_paid_general_growth_rechecks_whole_team_conditions_and_frozen_rosters_keep_their_stats(self):
        self.eligible()
        hero = protocol.pb_set_varint(self.gen(), 3, 99)
        hero = protocol.pb_set_varint(hero, 5, 0)
        player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, hero))
        player.record_protagonist_general(self.save, hero)
        initial = self.query()
        self.assertEqual(initial[2][3], 0)
        self.grant(20199, 100)
        before = copy.deepcopy(self.save)
        frozen = cup.frozen(self.save, 1, self.config)["snapshot"]
        war = guild_war.freeze(self.save)
        raw = protocol.encode_pb_field(1, 0, protocol.pb_get_varint(hero, 2))+b"".join(protocol.encode_pb_field(2, 0, n) for n in (0, 0, 0, 30))
        frames = self.request(1, 1038, raw=raw); self.refresh()
        self.assertIn(4203, [mid for mid, _ in frames])
        self.assertEqual(self.query()[2][3], 1)
        self.assertEqual(self.props(20199), 70)
        for snapshot in (frozen, war):
            old, _ = battle.rosters(snapshot, self.config["copy"]["42101"]["1"], self.config)
            for unit in old.values():
                original = formation.records(bytes.fromhex(before["world_state"]["1002"]), 1, 2)[unit["iid"]]
                self.assertEqual(unit["hp"], protocol.pb_get_varint(original, 8))

    def test_guide_gated_level_fifty_gift_simulated_payment_and_claim_only_once(self):
        self.query()
        self.assert_rejected(2882, values=[130008])
        for step in range(1, 4):
            self.success(1, 201, raw=protocol.encode_pb_field(1, 0, 90)+protocol.encode_pb_field(2, 0, step)); self.refresh()
        self.save["role_state"]["level"] = 48
        self.assert_rejected(2882, values=[130008])
        self.save["role_state"]["level"] = 50
        self.success(1, 2882, values=[130008]); self.refresh()
        deadline = self.save["deployment_gift_state"]["triggered_at"]
        self.assert_rejected(2881, values=[130008])
        body = protocol.encode_pb_field(1, 2, recharge.ids([3]))+protocol.encode_pb_field(1, 2, recharge.ids([130008]))
        order = self.success(1, 115, raw=body)
        params = self.records(order)
        confirm = recharge.ids([protocol.pb_get_varint(params[0], 1)])
        self.success(1, 116, raw=confirm); self.refresh()
        self.clock.return_value += 13*3600
        self.success(1, 2881, values=[130008]); self.refresh()
        self.assertEqual(self.props(20293), 300)
        self.assertEqual(self.save["deployment_gift_state"]["triggered_at"], deadline)
        self.reconnect(); self.refresh()
        self.assert_rejected(2881, values=[130008])

    def test_48_zhenfu_boss_has_real_loss_rewards_limits_and_forward_daily_reset(self):
        self.save["role_state"]["level"] = 48
        self.clock.return_value = 1800172800  # 周日
        self.success(1, 1001); self.refresh()
        before = copy.deepcopy(self.save)
        frames = self.request(1, 1345, values=[1]); self.refresh()
        report = json.loads(next(v for n, w, v in protocol.iter_pb_fields(frames[0][1]) if (n, w) == (5, 2)))
        summary = self.save["last_activity_battle"]
        expected = int(self.config["zhenfu_huodong"]["1"][f'{summary["damage_percent"]//10*10}_reward'].rstrip(";").split(",")[1])
        self.assertEqual(self.props(20293), expected)
        self.assertFalse(report["result"])
        self.assertEqual(report["round"], 5)
        for key in ("exp", "stamina", "energy"): self.assertEqual(self.save["role_state"][key], before["role_state"][key])
        self.success(1, 1345, values=[1]); self.refresh()
        self.assert_rejected(1345, values=[1])
        self.clock.return_value += 86400
        self.assert_rejected(1345, values=[1])  # 周一关闭，不自动补次数领奖。
        self.clock.return_value += 86400
        self.success(1, 1345, values=[1]); self.refresh()
        self.assertEqual(self.save["activity_copy_state"]["copies"]["5"]["used"], 1)

    def test_zhenfu_real_victory_save_failure_and_reward_overflow_keep_attempts_atomic(self):
        self.clock.return_value = 1800172800
        self.success(1, 1001); self.refresh()
        for raw in formation.records(bytes.fromhex(self.save["world_state"]["1002"]), 1, 2).values():
            for field, value in ((6, 10000000), (8, 10000000), (9, 1000)):
                raw = protocol.pb_set_varint(raw, field, value)
            player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, raw))
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 1345, values=[1])
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))
        self.grant(20293, (1 << 31)-1)
        self.assert_rejected(1345, values=[1])
        player.change_item_count(self.save, 20293, -((1 << 31)-1), self.config, int(self.clock.return_value))
        self.success(1, 1345, values=[1]); self.refresh()
        self.assertTrue(self.save["last_activity_battle"]["won"])
        self.assertEqual(self.save["last_activity_battle"]["damage_percent"], 100)
        self.assertEqual(self.props(20293), 41)
        self.assertEqual(self.save["activity_copy_state"]["copies"]["5"], {"cleared": 1, "used": 1, "tried": 1})

    def test_zhenfu_daily_35_counts_only_real_attempts_claims_two_symbols_and_two_points_once(self):
        self.clock.return_value = 1800172800
        self.success(1, 1340); self.refresh()
        self.assertEqual(activities.liveness_statuses(self.save, self.config, int(self.clock.return_value))[1][35], 0)
        self.assert_rejected(1345, values=[99])
        for count in (1, 2):
            self.success(1, 1345, values=[1]); self.refresh()
            self.success(1, 1340); self.refresh()
            flags, counts, _ = activities.liveness_statuses(self.save, self.config, int(self.clock.return_value))
            self.assertEqual((flags[35], counts[35]), (int(count==2), count))
        self.assert_rejected(1345, values=[1])
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 2411, values=[135])
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))
        original = self.props(20293)
        points = protocol.parse_ids_pb(self.success(1, 6517))[0]
        self.success(1, 2411, values=[135]); self.refresh()
        self.assertEqual(self.props(20293), original+2)
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 6517))[0], points+2)
        self.assertEqual(sum(self.config["liveness"][str(t)]["point"] for t in activities.LIVENESS_TASKS), 85)
        self.reconnect(); self.refresh()
        self.assert_rejected(2411, values=[135])
        self.clock.return_value += 86400
        self.success(1, 2410); self.refresh()
        self.assertEqual(activities.liveness_statuses(self.save, self.config, int(self.clock.return_value))[1][35], 0)
        self.assert_rejected(2411, values=[135])

    def network_lua(self, *, native_protobuf=False):
        lua = test_soul.SoulTests.network_lua(self, native_protobuf=native_protobuf)
        lua.execute(self.client_scripts()["assets/scripts/GameCopyActivity.so"])
        return lua

    def test_actual_native_pb_reads_use_string_keys_fifo_and_ignore_unsolicited_acknowledgements(self):
        lua = self.network_lua(native_protobuf=True)
        fd = lambda raw, ser=1: lua.table_from({b"rbuf": raw, b"ser": ser})
        for page in (4, 5):
            lua.globals().UISlotSpiritQueryCallBack(lua.table_from({b"deploymentView": lua.table_from({b"page": page})}))
        raw = self.success(1, 4200); self.refresh()
        lua.globals().NetSlotSpiritQueryCallBack(fd(raw, 0))
        for page in (4, 5):
            result = lua.globals().NetSlotSpiritQueryCallBack(fd(raw))
            self.assertEqual(result[b"deploymentView"][b"page"], page)
            self.assertEqual(result[b"slotSpirit"][b"level"][b"1"], 1)
        self.client_call(lua, 1, "UISlotSpiritUseCallBack", "NetSlotSpiritUseCallBack", {"id": 2})
        self.assertEqual(lua.globals().gamedata[b"cache"][b"slotSpirit"][b"use"], 2)
        self.assertIsNone(lua.globals().gameConfig)

    def test_actual_native_upgrade_prices_shared_locks_error_matching_and_single_deduction(self):
        self.query(); self.grant(20293, 1000)
        lua = self.network_lua(native_protobuf=True)
        lua.globals().props_raw = bytes.fromhex(self.save["world_state"]["1200"])
        lua.execute(b'local t=require("idnums_pb").IdNums();t:ParseFromString(props_raw);gamedata:Props(t.idnums)')
        self.client_call(lua, 1, "UISlotSpiritQueryCallBack", "NetSlotSpiritQueryCallBack", {})
        req = lua.table_from({b"id": 1, b"level": 1})
        lua.globals().upgrade_req = req
        lua.execute(b'upgrade_req.props=gamedata.getIDandNUMs(gamedata.config.lingzhentu_lv["1"].cost)')
        mode, mid, raw = lua.globals().UISlotSpiritLevelupCallBack(req)
        self.assertEqual((mode, mid, protocol.parse_ids_pb(raw)), (1, 4202, [1, 1]))
        self.assertEqual(lua.globals().UISlotSpiritUseCallBack(lua.table_from({b"id": 3}))[0], 0)
        self.assertEqual(lua.globals().UIChangeSlotCallBack(lua.table_from({b"pos1": 1, b"pos2": 2}))[0], 0)
        lua.globals().NetErrorMessageCallback9(lua.table_from({b"rbuf": recharge.ids([4201, 0])}))
        self.assertIsNotNone(lua.globals().gamedata[b"ext"][b"localDeploymentBusy"])
        coin = lua.globals().gamedata[b"cache"][b"role"][b"coin"]
        result = lua.globals().NetSlotSpiritLevelupCallBack(lua.table_from({b"rbuf": self.success(1, mid, raw=raw)}))
        self.assertEqual(result[b"slotSpirit"][b"level"][b"1"], 2)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"coin"], coin-400000)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"props"][20293][b"num"], 930)
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localFormationBusy"])
        self.assertEqual(lua.globals().UISlotSpiritLevelupCallBack(req)[0], 0)
        req[b"level"] = 2
        lua.execute(b'upgrade_req.props=gamedata.getIDandNUMs(gamedata.config.lingzhentu_lv["2"].cost)')
        self.assertEqual(lua.globals().UISlotSpiritLevelupCallBack(req)[0], 1)
        lua.globals().NetErrorMessageCallback9(lua.table_from({b"rbuf": recharge.ids([4202, 0])}))
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localDeploymentBusy"])
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localFormationBusy"])

    def test_packaged_ui_drops_closed_page_window_and_material_responses(self):
        from lupa.lua51 import LuaRuntime

        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute('''print=function() end;printT=print;requests={};updated=0;reloaded=0
            UIRequest=function(req) requests[#requests+1]=req end
            GameScene={layers={deployment={show=true,module={rootNode={},localDeploymentGeneration=1,
                reloadSlotSpirit=function(self,t) reloaded=reloaded+1 end}}},addUpdate=function() updated=updated+1 end}
            gameWindows={windows={deploymentLevelUp={show=true,module={rootNode={},localDeploymentGeneration=2,showindex=1,
                slotSpirit={level={['1']=1}},reload=function(self,t) self.slotSpirit=t;reloaded=reloaded+1 end,
                reloadAddition=function(self,t) addition=t end}},deploymentUp={show=false,module={}}},
                openWindow=function(self,name,data) opened=name end}''')
        lua.execute(self.client_scripts()["assets/scripts/UISlots.so"].decode())
        lua.execute('''view=LocalDeploymentContext(true)
            assert(LocalDeploymentActive(view,true))
            gameWindows.windows.deploymentLevelUp.module.localDeploymentGeneration=3
            UISlotSpiritLevelup({type=4202,deploymentView=view,slotSpirit={level={['1']=2}}})
            assert(reloaded==1 and #requests==0)
            UISlotSpiritAdditionQuery({type=4204,deploymentView=view,opt='up',data={add=0}})
            assert(addition==nil)
            GameScene.layers.deployment.module.localDeploymentGeneration=2
            UISlotSpiritQuery({type=4200,deploymentView=view,slotSpirit={}})
            assert(reloaded==1)
            UIRequest({type=4202,id=1,deploymentView=view})
            assert(#requests==0)
            GameScene.layers.deployment.module.localDeploymentGeneration=1
            view=LocalDeploymentContext()
            UISlotSpiritAdditionQuery({type=4204,deploymentView=view,opt='addmain',data={add=0}})
            assert(opened=='deploymentUp')''')

    def test_actual_activity_callbacks_serialize_six_callers_keep_query_fifo_and_matching_errors(self):
        lua = self.network_lua(native_protobuf=True)
        self.clock.return_value = 1800172800
        self.client_call(lua, 1, "UIActivityCopyCallback", "NetActivityCopyCallback", {})
        for temp in (b"zhenfu", b"coin"):
            lua.globals().UIActivityCopyCallback(lua.table_from({b"temp": temp}))
        raw = self.success(1, 1340)
        lua.globals().NetActivityCopyCallback(lua.table_from({b"rbuf": raw, b"ser": 0}))
        for temp in (b"zhenfu", b"coin"):
            result = lua.globals().NetActivityCopyCallback(lua.table_from({b"rbuf": raw}))
            self.assertEqual(result[b"temptype"], temp)
        mode, mid, raw = lua.globals().UIActivityZhenfuCopyCallback(lua.table_from({b"id": 1}))
        self.assertEqual((mode, mid, protocol.parse_ids_pb(raw)), (1, 1345, [1]))
        for name in ("Coin", "ExpDan", "ForgeStone", "EquipStar", "Zhenfu", "Forging"):
            self.assertEqual(getattr(lua.globals(), "UIActivity"+name+"CopyCallback")(lua.table_from({b"id": 1}))[0], 0)
        lua.globals().NetErrorMessageCallback9(lua.table_from({b"rbuf": recharge.ids([1341, 0])}))
        self.assertEqual(lua.globals().gamedata[b"ext"][b"localActivityCopyBusy"], 1345)
        result = lua.globals().NetActivityZhenfuCopyCallback(lua.table_from({b"rbuf": self.success(1, 1345, raw=raw)}))
        self.assertEqual(result[b"chooseLevel"], 1)
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localActivityCopyBusy"])
        lua.globals().UIActivityZhenfuCopyCallback(lua.table_from({b"id": 1}))
        lua.globals().NetErrorMessageCallback9(lua.table_from({b"rbuf": recharge.ids([1345, 0])}))
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localActivityCopyBusy"])

    def test_every_generated_lua_compiles_and_native_page_patches_are_shipped(self):
        from lupa.lua51 import LuaRuntime

        lua = LuaRuntime(encoding=None)
        compile_lua = lua.eval(b"function(code,name) local fn,err=loadstring(code,name);assert(fn,err);return true end")
        for name, source in self.client_scripts().items():
            with self.subTest(name=name): self.assertTrue(compile_lua(source, name.encode()))
        for name in ("GameSlots", "UISlots", "Layer_deployment", "window_deploymentLevelUp", "UIProps", "GameCopyActivity"):
            self.assertIn("assets/scripts/"+name+".so", self.client_scripts())

    def test_actual_activity_ui_ignores_old_page_window_and_post_playback_callbacks(self):
        from lupa.lua51 import LuaRuntime

        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute('''print=function() end;printT=print;requests={};played=0;refreshed=0;windowed=0
            UIRequest=function(req) requests[#requests+1]=req end
            ui={CheckHuodongByParam=function() end}
            RunbattleCallBack=function(kind,t,cb) played=played+1;playback=cb end
            GameScene={layers={copy_chapter={show=true,module={rootNode={},localActivityCopyGeneration=1,selectpage='activity',
                reloadactivityData=function() refreshed=refreshed+1 end,battleZhenfuData=function() refreshed=refreshed+1 end}}}}
            gameWindows={windows={activityCopySelect={show=false},copyacivity={show=true,module={rootNode={},
                localActivityCopyGeneration=1,data={aid=5},activityReload=function() windowed=windowed+1 end}}}}''')
        lua.execute(self.client_scripts()["assets/scripts/UICopyActivity.so"].decode())
        lua.execute('''UIRequest({type=1345,id=1})
            result={type=1345,activityCopyView=requests[1].activityCopyView,data={{aid=5},{aid=4}},result=0}
            gameWindows.windows.copyacivity.module.localActivityCopyGeneration=2
            gameWindows.windows.copyacivity.module.data.aid=4
            UIActivityZhenfuCopy(result)
            assert(played==0)
            UIActivityCopy(result)
            assert(refreshed==1 and windowed==0)
            gameWindows.windows.copyacivity.module.localActivityCopyGeneration=1
            gameWindows.windows.copyacivity.module.data.aid=5
            UIActivityZhenfuCopy(result)
            assert(played==1)
            gameWindows.windows.copyacivity.module.localActivityCopyGeneration=2
            gameWindows.windows.copyacivity.module.data.aid=4
            playback()
            assert(windowed==0 and refreshed==2 and requests[#requests].type==1340)
            GameScene.layers.copy_chapter.module.localActivityCopyGeneration=2
            local count=#requests
            playback()
            UIActivityCopy(result)
            assert(refreshed==2 and #requests==count)''')

    def test_actual_upgrade_window_controls_show_costs_and_reject_old_click_and_property_callbacks(self):
        from lupa.lua51 import LuaRuntime

        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.globals().gamedata = lua.table_from({"config": {k: self.config[k] for k in
            ("lingzhentu_zhenfa", "lingzhentu_jihuo", "lingzhentu_lv", "lingzhentu_add")}}, recursive=True)
        lua.execute('''print=function() end;printT=print;requests={};CCControlEventTouchUpInside=1
            local function node()
                return setmetatable({setString=function(self,s) self.text=s end,
                    addHandleOfControlEvent=function(self,cb) self.click=cb end},
                    {__index=function(self,key) return function() end end})
            end
            CCBReaderLoad=function() return node(),setmetatable({}, {__index=function(t,k) local n=node();t[k]=n;return n end}) end
            ui={setLabelString=function(n,text) if text then n:setString(text) end end,
                getSTRandNUM=function(s) local k,n=s:match('(%a+),(%d+)');return k,tonumber(n) end,
                getIDandNUMs=function(s) local r={} for c,n in s:gmatch('(%d+),(%d+)') do r[#r+1]={cid=tonumber(c),num=tonumber(n)} end return r end,
                setNewIconName=function() end}
            gameConfig={strings={string_common=function() return '原生标题' end,attr_type={atk='攻击',hp='生命',def='防御'},
                slotSpiritActivation=function(self,i) return i..'位' end}}
            gameTouch={clickprofbytime=function() end}
            UIRequest=function(req) requests[#requests+1]=req end
            GameScene={roleinfo={level=50,coin=1000000},layers={deployment={show=true,module={rootNode={},localDeploymentGeneration=1}}}}
            gameWindows={windows={deploymentLevelUp={show=true,module={}},deploymentUp={show=false,module={}}}}
            state={use=1,level={},activation={}}
            for i=1,7 do state.level[tostring(i)]=1;state.activation[tostring(i)]=0 end''')
        lua.execute(self.client_scripts()["assets/scripts/UISlots.so"].decode())
        lua.execute(self.client_scripts()["assets/scripts/UIProps.so"].decode())
        window = lua.execute(self.client_scripts()["assets/scripts/window_deploymentLevelUp.so"].decode())
        lua.globals().gameWindows.windows.deploymentLevelUp.module = window
        lua.globals().window = window
        lua.execute('''window:open(-1,{slotSpirit=state,showindex=1})
            assert(window.rootItems.level.text=='等级:1')
            assert(window.rootItems.coin.text==400000)
            local click=window.rootItems.upButton.click
            click()
            assert(requests[#requests].type==4202 and requests[#requests].level==1 and requests[#requests].id==1)
            local view=requests[1].deploymentView
            UIPropQueryById({order=42021,deploymentView=view,nums={['20293']=100}})
            assert(window.rootItems.in_num.text=='100/70')
            window:close();window:open(-1,{slotSpirit=state,showindex=2})
            local count=#requests
            click()
            assert(#requests==count)
            UIPropQueryById({order=42021,deploymentView=view,nums={['20293']=999}})
            assert(rawget(window.rootItems.in_num,'text')==nil)''')


if __name__ == "__main__":
    unittest.main()
