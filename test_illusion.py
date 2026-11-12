"""幻化：临时账号、真实协议/技能、有效期、失败回滚及包内Lua。"""

import copy
import unittest
from unittest.mock import patch

import test_soul
from zyj_server import activities, battle, cheer, cup, formation, guild_war, illusion, partner_growth, player, protocol, qiankun, recruit, single_boss


def setUpModule():
    test_soul.setUpModule()


class IllusionTests(unittest.TestCase):
    request = test_soul.SoulTests.request
    add_account = test_soul.SoulTests.add_account
    success = test_soul.SoulTests.success
    reconnect = test_soul.SoulTests.reconnect
    refresh = test_soul.SoulTests.refresh
    props = test_soul.SoulTests.props
    gen = test_soul.SoulTests.gen
    assert_rejected = test_soul.SoulTests.assert_rejected
    client_scripts = classmethod(test_soul.SoulTests.client_scripts.__func__)
    network_lua = test_soul.SoulTests.network_lua
    client_call = test_soul.SoulTests.client_call

    def setUp(self):
        test_soul.SoulTests.setUp(self)
        self.save["role_state"].update(level=100, vip=9)
        self.iid = 2000900
        player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, recruit.new_general(10201, self.iid, self.config)))
        self.save["self_stats_version"] = 1

    def grant_image(self, cid=200502, count=1):
        reward = recruit.build_reward(self.save, [(cid, count)], self.config, now=self.now)
        player.apply_reward(self.save, reward, self.config, self.now)
        return reward

    def mutation(self, cid=200502, iid=None):
        state = illusion.get_state(self.save, self.config)
        old, end = state["items"][str(cid)]
        return [cid, self.iid if iid is None else iid, end, old, state["serial"]]

    def bind(self, cid=200502):
        self.success(1, 8111, values=self.mutation(cid))
        self.refresh()

    def put_main(self):
        self.success(1, 1003, raw=protocol.encode_pb_field(1, 0, 2)+protocol.encode_pb_field(3, 0, self.iid))
        self.refresh()

    def test_reward_preview_is_read_only_actual_rewards_accumulate_days_and_reconnect(self):
        before = copy.deepcopy(self.save)
        recruit.build_reward(self.save, [(200502, 1)], self.config, now=self.now)
        self.assertEqual(self.save, before)
        reward = self.grant_image(count=2)
        first = illusion.get_state(self.save, self.config)["items"]["200502"]
        self.assertEqual((first[1]+28800) % 86400, 0)
        self.assertEqual(first[1], (self.now+28800)//86400*86400-28800+3*86400)
        self.assertTrue(any(n == 18 for n, _, _ in protocol.iter_pb_fields(reward)))
        self.grant_image(count=3)
        self.assertEqual(illusion.get_state(self.save, self.config)["items"]["200502"][1], first[1]+3*86400)
        self.success(1, 8110, values=[1]); self.refresh()
        self.reconnect(); self.refresh()
        self.assertEqual(illusion.get_state(self.save, self.config)["items"]["200502"][1], first[1]+3*86400)

    def test_bind_uses_cid_not_iid_cancel_keeps_ownership_and_source_unknown_fields(self):
        self.grant_image()
        original = self.gen(self.iid)+protocol.encode_pb_field(50, 2, b"keep")
        player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, original))
        old = copy.deepcopy(self.save["role_state"])
        self.bind()
        data = illusion.values(self.gen(self.iid))
        self.assertEqual((data[0], data[8]), (200502, 10598))
        self.assertEqual(self.save["role_state"], old)
        self.success(1, 8112, values=self.mutation()); self.refresh()
        self.assertEqual(illusion.get_state(self.save, self.config)["items"]["200502"][0], 0)
        for n in range(1, 41):
            self.assertEqual(protocol.pb_get_varint(original, n), protocol.pb_get_varint(self.gen(self.iid), n))
        self.assertIn((50, 2, b"keep"), list(protocol.iter_pb_fields(self.gen(self.iid))))

    def test_expiry_settles_on_unrelated_success_and_save_failure_is_atomic(self):
        self.grant_image(); self.bind()
        end = self.save["illusion_state"]["items"]["200502"][1]
        self.clock.return_value = end
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 1001)
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))
        packets = self.request(1, 1001); self.refresh()
        self.assertIn(8110, [mid for mid, _ in packets])
        self.assertIn(1027, [mid for mid, _ in packets])
        self.assertFalse(any(illusion.values(self.gen(self.iid))))
        self.assertEqual(self.save["illusion_state"]["items"], {})

    def test_stale_binding_expiry_and_serial_reject_without_overwriting_another_target(self):
        self.grant_image()
        stale = self.mutation()
        self.bind()
        self.assert_rejected(8111, values=stale)
        self.assert_rejected(8112, values=stale)
        self.assert_rejected(8112, values=self.mutation(iid=1))
        self.clock.return_value = self.now-1
        self.assert_rejected(8112, values=self.mutation())

    def test_unlock_bad_parameters_unknown_activity_and_protagonist_reject_atomically(self):
        self.grant_image()
        self.save["role_state"]["level"] = 64
        self.assert_rejected(8111, values=self.mutation())
        self.save["role_state"]["level"] = 65
        lead = protocol.pb_get_varint(bytes.fromhex(self.save["protagonist_snapshot"]), 1)
        self.assert_rejected(8111, values=self.mutation(iid=lead))
        for opcode in (8110, 8111, 8112, 7021, 8113, 8115, 8117, 8252):
            self.assert_rejected(opcode, raw=b"\x10\x01")
        for opcode in (8111, 8112, 7021):
            self.assert_rejected(opcode, values=[200502, self.iid])

    def test_corrupt_state_and_overflow_are_read_only_and_rejected(self):
        before = copy.deepcopy(self.save)
        for state in (None, {}, {"items": {"wrong": [0, 123]}}, {"items": {"200502": [True, 123]}},
                      {"items": {"200502": [0, -1]}}, {"items": {}, "serial": True}, {"items": {}, "checked_at": None}):
            self.save["illusion_state"] = state
            self.assert_rejected(8110)
        self.sessions[1].save = before; self.refresh()
        with self.assertRaises(ValueError):
            self.grant_image(count=1 << 30)
        self.assertEqual(self.save, before)

    def test_effective_skills_passives_and_vip_modes_never_change_saved_source_stats(self):
        self.grant_image(); self.put_main(); self.bind()
        before = copy.deepcopy(self.save)
        point = self.config["copy"]["42101"]["1"]
        for vip, mode, cid in ((0, "pve", 10201), (1, "pve", 10598), (8, "pvp", 10201), (9, "pvp", 10598), (15, "none", 10201)):
            self.save["role_state"]["vip"] = vip
            attack, defense = battle.rosters(self.save, point, self.config, illusion_mode=mode, now=self.now)
            self.assertEqual(attack[8]["cid"], cid)
            self.assertEqual(attack[8]["skill"], self.config["general"][str(cid)]["skillid"])
            battle.simulate(attack, defense, self.config, 7, max_rounds=1)
        self.save["role_state"]["vip"] = before["role_state"]["vip"]
        self.assertEqual(self.save, before)

    def test_original_and_illusion_duplicate_identities_block_main_and_cheer_but_not_ownership(self):
        self.grant_image(); self.put_main(); self.bind()
        iid = self.iid+1
        player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, recruit.new_general(10598, iid, self.config)))
        for opcode in (1003, 1004):
            self.assert_rejected(opcode, raw=protocol.encode_pb_field(1, 0, 3 if opcode == 1003 else 1)+protocol.encode_pb_field(3, 0, iid))
        self.success(1, 8112, values=self.mutation()); self.refresh()
        self.success(1, 1004, raw=protocol.encode_pb_field(1, 0, 1)+protocol.encode_pb_field(3, 0, iid))

    def test_illusion_supports_use_transformed_combo_identity_only_above_mode_vip(self):
        self.grant_image(); self.bind()
        self.success(1, 1004, raw=protocol.encode_pb_field(1, 0, 1)+protocol.encode_pb_field(3, 0, self.iid)); self.refresh()
        self.assertEqual(cheer.combat(self.save, self.config, now=self.now), [10598])
        self.save["role_state"]["vip"] = 1
        self.assertEqual(cheer.combat(self.save, self.config, illusion_mode="pvp", now=self.now), [10201])

    def test_growth_retains_binding_and_cancel_retains_all_paid_growth(self):
        self.grant_image(); self.bind()
        player.change_item_count(self.save, 20196, 1, self.config, self.now)
        self.success(1, 1038, raw=protocol.encode_pb_field(1, 0, self.iid)+b"\x10\x01\x10\x00\x10\x00\x10\x00"); self.refresh()
        grown = self.gen(self.iid)
        self.assertGreater(protocol.pb_get_varint(grown, 3), 1)
        self.success(1, 8112, values=self.mutation()); self.refresh()
        self.assertEqual(protocol.pb_get_varint(self.gen(self.iid), 6), protocol.pb_get_varint(grown, 6))
        self.assertEqual(protocol.pb_get_varint(self.gen(self.iid), 3), protocol.pb_get_varint(grown, 3))

    def test_all_44_images_have_valid_low_level_models_and_unsupported_mechanics_fail_closed(self):
        self.assertEqual(len(self.config["illusion"]), 44)
        for cid in self.config["illusion"]:
            data = illusion.metadata(self.gen(self.iid), int(cid), self.config)
            illusion.check_combat(self.gen(self.iid), data, self.config)
        raw = protocol.pb_set_varint(self.gen(self.iid), 4, 10)
        data = illusion.metadata(raw, 200540, self.config)
        with self.assertRaisesRegex(ValueError, "被动"):
            illusion.check_combat(raw, data, self.config)

    def test_new_frozen_teams_keep_snapshot_illusion_and_old_snapshots_do_not_gain_it(self):
        self.grant_image(); self.put_main(); self.bind()
        frozen = cup.frozen(self.save, 1, self.config)["snapshot"]
        war = guild_war.freeze(self.save)
        self.clock.return_value = self.save["illusion_state"]["items"]["200502"][1]+1
        for snapshot in (frozen, war):
            attack, _ = battle.rosters(snapshot, self.config["copy"]["42101"]["1"], self.config, illusion_mode="pvp")
            self.assertEqual(attack[8]["cid"], 10598)
        legacy = copy.deepcopy(frozen)
        legacy.pop("illusion_state"); legacy.pop("illusion_frozen_at")
        attack, _ = battle.rosters(legacy, self.config["copy"]["42101"]["1"], self.config, illusion_mode="pvp")
        self.assertEqual(attack[8]["cid"], 10201)

    def test_single_boss_allows_original_identities_and_never_uses_illusion(self):
        self.grant_image(); self.put_main(); self.bind()
        lead = protocol.pb_get_varint(bytes.fromhex(self.save["protagonist_snapshot"]), 1)
        other = self.iid+1
        player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, recruit.new_general(10598, other, self.config)))
        team = [lead, self.iid, other, 0, 0, 0, 0, 0]
        before = copy.deepcopy(self.save)
        temporary, _ = single_boss.project_team(self.save, team, self.config)
        attack, _ = battle.rosters(temporary, self.config["copy"]["42101"]["1"], self.config, illusion_mode="none")
        self.assertEqual([attack[p]["cid"] for p in (8, 10)], [10201, 10598])
        self.assertEqual(self.save, before)

    def test_bound_idle_partners_are_protected_and_actual_receipts_survive_bind_cancel(self):
        self.grant_image()
        raw = self.gen(self.iid)
        qiankun.get_state(self.save)["receipts"][f"general:{self.iid}"] = {"before": raw.hex(), "after": raw.hex(), "costs": []}
        self.bind()
        self.assertIn(self.iid, qiankun.protected(self.save))
        self.assertEqual(self.save["qiankun_state"]["receipts"][f"general:{self.iid}"]["after"], self.gen(self.iid).hex())
        self.success(1, 8112, values=self.mutation()); self.refresh()
        self.assertNotIn(self.iid, qiankun.protected(self.save))
        self.assertEqual(self.save["qiankun_state"]["receipts"][f"general:{self.iid}"]["after"], self.gen(self.iid).hex())

    def test_gold_image_random_choices_and_free_strict_reselection_do_not_change_source_choices(self):
        raw = recruit.new_general(164036, self.iid, self.config)
        for field, value in ((4, 16), (35, 1), (36, 1), (37, 1), (40, 1)):
            raw = protocol.pb_set_varint(raw, field, value)
        for field, value in partner_growth.fairy(raw, self.config).items():
            raw = protocol.pb_set_varint(raw, field, value)
        raw = protocol.pb_set_varint(raw, 34, sum(protocol.pb_get_varint(raw, f) for f in (25, 26))+protocol.pb_get_varint(raw, 24)//10)
        player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, raw))
        self.grant_image(); self.bind()
        data = illusion.values(self.gen(self.iid))
        self.assertEqual(data[8], 164004)
        self.assertTrue(all(v in (1, 3) for v in data[1:4]))
        state = illusion.get_state(self.save, self.config)
        cost = copy.deepcopy(self.save["role_state"])
        choice = 3 if data[1] == 1 else 1
        self.success(1, 7021, values=[1, 164036, 200502, state["serial"], 1, choice]); self.refresh()
        self.assertEqual(illusion.values(self.gen(self.iid))[1], choice)
        self.assertEqual([protocol.pb_get_varint(self.gen(self.iid), f) for f in (35, 36, 37)], [1, 1, 1])
        self.assertEqual(self.save["role_state"], cost)
        self.assert_rejected(7021, values=[0, 164036, 200502, state["serial"], 1, choice])

    def test_mutation_save_failure_leaves_ownership_binding_and_wallet_unchanged(self):
        self.grant_image()
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 8111, values=self.mutation())
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))

    def test_actual_packaged_lua_query_fifo_binding_cancel_shared_lock_and_matching_errors(self):
        self.grant_image()
        lua = self.network_lua(native_protobuf=True)
        code = self.client_scripts()["assets/scripts/gamedata.so"].decode()
        for name in ("illusionData", "generalData"):
            start = code.index("function gamedata."+name+"(")
            end = code.find("\nfunction ", start+1)
            lua.execute(code[start:end].encode())
        lua.execute(b'local native=assert(require("GameIllusion"));gamedata.cache.illusion={}')
        req = lua.table_from({b"illusionView": lua.table_from({b"generation": 1})})
        lua.globals().UIIllusionQueryCallBack(req)
        lua.globals().UIIllusionQueryCallBack(req)
        packet = self.success(1, 8110, values=[1]); self.refresh()
        fd = lambda raw, ser=7: lua.table_from({b"rbuf": raw, b"ser": ser})
        lua.execute(b'''package.loaded.uiqueue={setresponsetoui=function() end};__G_TRACKBACK__=function(e) error(e) end
            game_net_callback={[8110]=NetIllusionQueryCallBack};gamedata.ext.combmessageOrder="datainit"''')
        lua.execute(self.client_scripts()["assets/scripts/GameCombMessages.so"])
        message = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 8110)+protocol.encode_pb_field(2, 2, packet))
        lua.globals().NetCombMessagesCallback(fd(message))
        self.assertIsNotNone(lua.globals().gamedata[b"cache"][b"illusion"][200502])
        self.assertTrue(lua.globals().NetIllusionQueryCallBack(fd(packet, 0))[b"illusionPush"])
        for _ in range(2):
            query = lua.globals().NetIllusionQueryCallBack(fd(packet))
            self.assertEqual(query[b"illusionView"][b"generation"], 1)
        state = illusion.get_state(self.save, self.config)
        expected = lua.table_from({b"cid": 200502, b"serial": state["serial"], b"endtime": state["items"]["200502"][1], b"generalIid": 0})
        request = lua.table_from({b"generalIid": self.iid, b"illusionExpected": expected, b"illusionView": lua.table_from({b"generation": 1})})
        mode, mid, body = lua.globals().UIIllusionExeCallBack(request)
        self.assertEqual((mode, mid, protocol.parse_ids_pb(body)), (1, 8111, self.mutation()))
        self.assertEqual(lua.globals().UIIllusionExeCallBack(request)[0], 0)
        lua.globals().NetErrorMessageCallback9(fd(illusion.ids_body([8112, 0])))
        self.assertIsNotNone(lua.globals().gamedata[b"ext"][b"localFormationBusy"])
        result = lua.globals().NetIllusionExeCallBack(fd(self.success(1, mid, raw=body))); self.refresh()
        self.assertEqual(result[b"data"][1][b"general"][b"illusionGeneralCid"], 10598)
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localFormationBusy"])
        state = illusion.get_state(self.save, self.config)
        expected[b"serial"], expected[b"generalIid"] = state["serial"], self.iid
        mode, mid, body = lua.globals().UIIllusionCancelCallBack(request)
        self.assertEqual((mode, mid), (1, 8112))
        lua.globals().NetIllusionCancelCallBack(fd(self.success(1, mid, raw=body)))
        self.assertIsNone(lua.globals().gamedata[b"cache"][b"generals"][self.iid][b"illusionGeneralCid"])

    def test_actual_ui_ignores_closed_pages_and_old_select_callbacks(self):
        from lupa.lua51 import LuaRuntime
        lua = LuaRuntime(encoding=None)
        lua.execute(b'''print=function() end;printT=print
            gameConfig={strings={string_common=function() return "text" end}}
            gamedata={config={illusion={['200502']={general_id=10598}},general={['10598']={quality=5,name='image'}}},time=function() return 1 end}
            gameTouch={};ui={setLabelString=function() end,setNewIcon=function() end,sethint=function() end}
            sent={};UIRequest=function(req) sent[#sent+1]=req end
            gameWindows={windows={},openWindow=function(self,name,req,cb) selected=cb end}
            local function node() return {setVisible=function() end,setString=function() end,
                setSwallowsTouch=function() end,setTouchPriority=function() end,
                addHandleOfControlEvent=function(self,fn) self.handler=fn end} end
            items={};for _,name in ipairs({'time','resNode','name1','infoNode','doLab','i_button','doButton','hintnode'}) do items[name]=node() end
        ''')
        page = lua.execute(self.client_scripts()["assets/scripts/Layer_illusion.so"])
        lua.globals().page = page
        lua.execute(b'''page.rootNode={};page.localIllusionGeneration=1;page.localIllusionRevision=1
            page.data={['1']={cid=200502,endtime=1794000000,generalIid=0}};page.IllsionHints={}
            page:setCell(items,1);items.doButton.handler();assert(selected)
            page.localIllusionGeneration=2;selected({{iid=7}});assert(#sent==0)
            page.localIllusionGeneration=1;page.localIllusionRevision=2;items.doButton.handler();assert(#sent==0)
            page:setCell(items,1);items.doButton.handler();selected({{iid=7}});assert(#sent==1)
            GameScene={layers={illusion={show=true,module=page}},addUpdate=function() end}
            page.reloaddata=function(self,data) self.data=data;applied=(applied or 0)+1 end
            package.loaded.UIGenerals={};UIGeneralChangeBreakSkill=function() end
        ''')
        lua.execute(self.client_scripts()["assets/scripts/UIIllusion.so"])
        lua.execute(b'''UIIllusionQuery({illusionSerial=2,illusionView={generation=1},data={}});assert(applied==1)
            page.localIllusionGeneration=3
            UIIllusionQuery({illusionSerial=3,illusionView={generation=1},data={}});assert(applied==1)
            GameScene.layers.illusion.show=false
            UIIllusionQuery({illusionSerial=4,illusionPush=true,data={}});assert(applied==1)
        ''')

    def test_native_page_expiry_uses_real_seconds_under_acceleration_and_cancels_on_exit(self):
        from lupa.lua51 import LuaRuntime
        lua = LuaRuntime(encoding=None)
        code = self.client_scripts()["assets/scripts/Layer_illusion.so"]
        start = code.index(b"local localIllusionInit=huanhuaList.init")
        lua.execute(b'''now=10;os.time=function() return now end
            gamedata={time=function() return now end};requests=0;UIRequest=function(req) requests=requests+1 end
            CCDelayTime={create=function(_,seconds) return seconds end}
            CCCallFunc={create=function(_,fn) return fn end}
            CCSequence={createWithTwoActions=function(_,delay,fn) return fn end}
            huanhuaList={init=function(self) self.localIllusionGeneration=(self.localIllusionGeneration or 0)+1
                self.rootNode={runAction=function(_,fn) delayed=fn end};self.data={{endtime=20}} end}
        ''')
        page = lua.execute(code[start:])
        lua.globals().page = page
        lua.execute(b'''page:init()
            for _,speed in ipairs({1,3,10}) do for i=1,50*speed do delayed() end end
            assert(requests==0);now=20;delayed();assert(requests==1)
            for i=1,100 do delayed() end;assert(requests==1)
            local old=delayed;page.localIllusionGeneration=page.localIllusionGeneration+1;page.rootNode=nil
            now=30;old();assert(requests==1)
        ''')

    def test_configured_attenuation_weakens_battle_only_and_leaves_training_and_speed_intact(self):
        raw = recruit.new_general(10609, self.iid, self.config)
        for field, value in ((6, 10000), (7, 2000), (8, 100000), (9, 120)):
            raw = protocol.pb_set_varint(raw, field, value)
        player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, raw))
        self.grant_image(200522); self.put_main(); self.bind(200522)
        bound = self.gen(self.iid)
        data = illusion.values(bound)
        self.assertEqual(data[7], self.config["illusion_attenuation"]["0"]["illusion_ratio_23_20"])
        attack, _ = battle.rosters(self.save, self.config["copy"]["42101"]["1"], self.config, now=self.now)
        for name, field in (("atk", 6), ("def", 7), ("hp", 8)):
            self.assertEqual(attack[8][name], protocol.pb_get_varint(bound, field)*(100-data[7])//100)
        self.assertEqual(attack[8]["speed"], protocol.pb_get_varint(bound, 9))
        self.assertEqual(self.gen(self.iid), bound)

    def test_all_44_transformed_personal_skills_and_models_convert_actual_native_reports(self):
        import test_partner_growth
        self.put_main()
        reports = []
        original = copy.deepcopy(self.save)
        for cid in self.config["illusion"]:
            temporary = copy.deepcopy(original)
            raw = self.gen(self.iid)
            data = illusion.metadata(raw, int(cid), self.config)
            player.record_slot_update(temporary, protocol.encode_pb_field(1, 2, illusion.with_illusion(raw, data)))
            temporary["illusion_state"] = {"items": {cid: [self.iid, self.now+86400]}, "serial": 1, "checked_at": self.now}
            attack, defense = battle.rosters(temporary, self.config["copy"]["42101"]["1"], self.config, now=self.now)
            attack[8].update(hp=10**7, atk=1000, speed=1000, initial_ap=10)
            for unit in defense.values(): unit.update(hp=10**7, atk=1, speed=1)
            reports.append(battle.simulate(attack, defense, self.config, 7, max_rounds=2))
        test_partner_growth.PartnerBattleTests.assert_native_reports(self, reports)
        self.assertEqual(self.save, original)

    def test_same_connection_retry_returns_same_receipt_without_rebinding_or_extending(self):
        self.grant_image()
        body = illusion.ids_body(self.mutation())
        result = self.request(1, 8111, raw=body); self.refresh()
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        packets = self.sessions[1].handle(8111, self.seq, body)
        self.assertEqual([(int.from_bytes(p[8:12], "big"), p[16:]) for p in packets], result)
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))

    def account_age(self, day=1):
        """把建号日推到第 day 天：175/176 停在该天，177 停在对应轮次的第几天。"""
        self.refresh()
        start = (self.now + illusion.UTC8) // illusion.DAY * illusion.DAY - illusion.UTC8
        self.save["created_at"] = start - (day - 1) * illusion.DAY + 60

    def fragment(self, cid):
        body = bytes.fromhex(self.save["world_state"]["1012"])
        return protocol.pb_get_varint(formation.records(body, 1, 1).get(cid, b""), 2) or 0

    def recharge_rmb(self, amount):
        """走真实 1008 奖励通道累计充值，而不是直接改字段。"""
        self.refresh()
        player.apply_reward(self.save, activities.build_reward(self.save, f"1008,{amount}", self.config),
                            self.config, self.now)

    def gift_ids(self, table, position):
        return [cid for cid, _ in illusion.gift_rows(self.config, table, position)]

    def task_ids(self, cycle):
        return sorted(int(key) for key in self.config[f"illusion_task_{cycle}"])

    def activity_entries(self, body):
        groups = dict(protocol.get_comb_messages(body))
        statuses = {protocol.pb_get_varint(row, 1): protocol.pb_get_varint(row, 2)
                    for n, w, row in protocol.iter_pb_fields(groups[1]) if (n, w) == (1, 2)}
        values = protocol.parse_ids_pb(groups[2])
        return statuses, {values[i]: values[i+1:i+3] for i in range(0, len(values), 3)}

    def test_activity_entry_opens_at_65_without_granting_images(self):
        self.account_age(1)
        for level, has_role, guide_status, expected in ((64, True, 2, 0), (65, True, 2, 1),
                                                       (65, False, 2, 0), (65, True, 1, 0)):
            with self.subTest(level=level, has_role=has_role, guide_status=guide_status):
                self.save["role_state"]["level"] = level
                self.save["has_role"] = has_role
                self.save["guide"]["sections"]["1"]["status"] = guide_status
                statuses, periods = self.activity_entries(self.success(1, 2000))
                self.refresh()
                self.assertEqual([statuses[mid] for mid in (175, 176, 177)], [expected] * 3)
                self.assertEqual([periods[mid] for mid in (175, 176, 177)], [[1, 1]] * 3)
                self.assertNotIn("illusion_state", self.save)

    def test_activity_entry_periods_match_reward_pages_and_initialization(self):
        for day in (1, 4, 7, 8, 28, 29, 10000):
            with self.subTest(day=day):
                self.account_age(day)
                statuses, periods = self.activity_entries(self.success(1, 2000))
                self.assertEqual([statuses[mid] for mid in (175, 176, 177)], [1] * 3)
                self.assertEqual(periods[175], [1, min(day, 4)])
                self.assertEqual(periods[176], periods[175])
                self.assertEqual(periods[177], [(min(day, 28)-1)//7+1, (min(day, 28)-1)%7+1])
                self.assertEqual(protocol.parse_ids_pb(self.success(1, 8113))[0::3],
                                 self.gift_ids("illusion_present_time_x1", periods[175][1]))
                self.assertEqual(protocol.parse_ids_pb(self.success(1, 8117))[0::3], self.task_ids(periods[177][0]))
        raw = next(raw for ids, raw in self.store.tables[1] if 8110 in ids and 2000 in ids)
        player.save_role(self.sessions[1].save, self.store.path(1), self.store.step_counts)
        messages = dict(protocol.get_comb_messages(self.success(1, 999900, raw=raw)))
        self.assertEqual(self.activity_entries(messages[2000]), self.activity_entries(self.success(1, 2000)))

    def test_activity_entry_rewrite_preserves_unrelated_rows_envelopes_and_unknown_fields(self):
        self.account_age(8)
        rows = {mid: illusion.ids_body([mid]) + protocol.encode_pb_field(2, 0, 0)
                + protocol.encode_pb_field(9, 2, b"row") for mid in (175, 176, 177, 999)}
        groups = {1: b"".join(protocol.encode_pb_field(1, 2, row) for row in rows.values()),
                  2: illusion.ids_body([177, 9, 99, 999, 8, 9, 175, 9, 99]) + protocol.encode_pb_field(8, 2, b"period"),
                  3: b"untouched"}
        body = b"".join(protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, mid)
                        + protocol.encode_pb_field(2, 2, raw) + protocol.encode_pb_field(9, 0, 42))
                        for mid, raw in groups.items()) + protocol.encode_pb_field(7, 2, b"outer")
        before = copy.deepcopy(self.save)
        result = illusion.rewrite_activities(body, self.save, self.config, self.now)
        self.assertEqual(self.save, before)
        self.assertEqual(result, illusion.rewrite_activities(result, self.save, self.config, self.now))
        actual = dict(protocol.get_comb_messages(result))
        self.assertEqual(actual[3], groups[3])
        self.assertEqual(formation.records(actual[1], 1, 1),
                         {mid: protocol.pb_set_varint(row, 2, int(mid != 999)) for mid, row in rows.items()})
        self.assertEqual(protocol.parse_ids_pb(actual[2]), [999, 8, 9, 175, 1, 4, 176, 1, 4, 177, 2, 1])
        self.assertIn((8, 2, b"period"), list(protocol.iter_pb_fields(actual[2])))
        self.assertIn((7, 2, b"outer"), list(protocol.iter_pb_fields(result)))
        for n, w, raw in protocol.iter_pb_fields(result):
            if (n, w) == (1, 2):
                self.assertEqual(protocol.pb_get_varint(raw, 9), 42)
        added = illusion.rewrite_activities(b"", self.save, self.config, self.now)
        self.assertEqual(self.activity_entries(added), ({175: 1, 176: 1, 177: 1},
                                                       {175: [1, 4], 176: [1, 4], 177: [2, 1]}))
        broken = protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 2)
                                          + protocol.encode_pb_field(2, 2, illusion.ids_body([177, 1])))
        with self.assertRaisesRegex(ValueError, "三值组"):
            illusion.rewrite_activities(broken, self.save, self.config, self.now)

    def test_activity_entry_respects_switch_and_future_creation_without_mutating_state(self):
        self.account_age(1)
        self.config["build"]["600"]["switch"] = 0
        before = copy.deepcopy(self.save)
        statuses, _ = self.activity_entries(illusion.rewrite_activities(b"", self.save, self.config, self.now))
        self.assertEqual(statuses, {175: 0, 176: 1, 177: 1})
        self.assertEqual(self.save, before)
        self.save["created_at"] = self.now + illusion.DAY
        before = copy.deepcopy(self.save)
        statuses, periods = self.activity_entries(illusion.rewrite_activities(b"", self.save, self.config, self.now))
        self.assertEqual(statuses, {175: 0, 176: 0, 177: 0})
        self.assertEqual(periods, {175: [0, 0], 176: [0, 0], 177: [0, 0]})
        self.assertEqual(self.save, before)

    def test_activity_claim_save_failure_keeps_costs_rewards_and_ledger_atomic(self):
        self.account_age(1)
        self.success(1, 2000); self.refresh()
        for task_id in (1, 4):
            with self.subTest(task_id=task_id):
                before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
                with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
                    self.request(1, 8118, values=[task_id])
                self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))
                self.success(1, 8118, values=[task_id]); self.refresh()
                ledger = copy.deepcopy(self.save["illusion_state"])
                self.success(1, 2000); self.refresh()
                self.assertEqual(self.save["illusion_state"], ledger)
                self.assert_rejected(8118, values=[task_id])

    def test_native_activity_entry_queries_claim_and_illusion_list_form_one_path(self):
        from lupa.lua51 import LuaRuntime
        self.account_age(1)
        lua = self.network_lua(native_protobuf=True)
        code = self.client_scripts()["assets/scripts/gamedata.so"].decode()
        for name in ("ActivityStatusData", "ActivityStatus", "DailyCpActivityTimeStatus", "illusionData"):
            start = code.index("function gamedata." + name + "(")
            lua.execute(code[start:code.index("\nfunction ", start+1)].encode())
        lua.execute(b'gamedata.cache.activitystatus={};gamedata.cache.dailyCpActivityTimeStatus={};gamedata.cache.illusion={};require("GameActivityQuery");require("GameIllusion")')
        entry = self.client_call(lua, 1, "UIActivityQueryCallBack", "NetActivityQueryCallBack", {"page": 5})
        ui = LuaRuntime(encoding=None)
        def native(value):
            if isinstance(value, dict) or hasattr(value, "items"):
                return ui.table_from({native(k): native(v) for k, v in value.items()})
            return value.encode() if isinstance(value, str) else value
        ui.globals().gamedata = ui.table_from({b"config": native(self.config)})
        ui.globals().entry = native(entry)
        ui.execute(b'''print=function() end;printT=print
            table.merge=function(a,b) local r={} for k,v in pairs(a) do r[k]=v end for k,v in pairs(b) do r[k]=v end return r end
            activity={realPageTable={},presentPage=1,pageTable1={},pageTable5={}}
            deviceApi={channel="local"};local module={clear=function() end}
            activity.pageTable1[177]={module=module};activity.pageTable5[175]={module=module};activity.pageTable5[176]={module=module}''')
        code = self.client_scripts()["assets/scripts/Layer_activity.so"].decode()
        start = code.index("function activity.setActivityData(")
        ui.execute(code[start:code.index("\nfunction ", start+1)].encode())
        ui.execute(b'''for _,page in ipairs({1,5}) do
            activity.type=page;activity:setActivityData(entry)
            assert(#activity.realPageTable==(page==1 and 1 or 2))
        end''')
        for send, receive, expected in (("UIIllusionActivityQueryCallBack", "NetIllusionActivityQueryCallBack", 8),
                                         ("UIIllusionActivityQueryX1CallBack", "NetIllusionActivityQueryX1CallBack", 8)):
            reply = self.client_call(lua, 1, send, receive, {})
            self.assertEqual(len(reply[b"giftdata"]), expected)
        tasks = self.client_call(lua, 1, "UIIllusionActivityTaskQueryCallBack", "NetIllusionActivityTaskQueryCallBack", {})
        self.assertEqual([row[b"id"] for _, row in tasks[b"task"].items()], self.task_ids(1))
        gold = self.sessions[1].save["role_state"]["gold"]
        self.client_call(lua, 1, "UIIllusionActivityTaskRewardCallBack", "NetIllusionActivityTaskRewardCallBack", {"id": 1})
        self.refresh()
        self.assertEqual(self.save["role_state"]["gold"], gold)
        self.assertIsNotNone(lua.globals().gamedata[b"cache"][b"illusion"][200503])
        result = self.client_call(lua, 1, "UIIllusionQueryCallBack", "NetIllusionQueryCallBack", {})
        self.assertEqual(result[b"data"][1][b"cid"], 200503)
        self.reconnect(); self.refresh()
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 8110))[:2], [200503, 0])
        self.assert_rejected(8118, values=[1])

    def test_activity_pages_are_read_only_and_report_configured_rows(self):
        self.account_age(1)
        self.assertEqual(self.gen(self.iid), self.gen(self.iid))
        self.assertNotIn("illusion_state", self.save)
        first = protocol.parse_ids_pb(self.success(1, 8113))
        self.assertEqual(first[0::3], self.gift_ids("illusion_present_time_x1", 1))
        # 全新账号没有充值记录，礼包一律停在"去充值"。
        self.assertEqual(set(first[1::3]), {0})
        self.assertEqual(first[2::3], [0] * 8)
        second = protocol.parse_ids_pb(self.success(1, 8115))
        self.assertEqual(second[0::3], self.gift_ids("illusion_present_time_x2", 1))
        tasks = protocol.parse_ids_pb(self.success(1, 8117))
        self.assertEqual(tasks[0::3], self.task_ids(1))
        # 类型1免费、类型4购买可直接领；类型2/3/6/8/11/12/15/19/20 必须真实达成。
        self.assertEqual(tasks[1::3], [1, 0, 0, 1, 0, 0, 0, 0, 0])
        self.assertEqual(tasks[2::3], [0, 0, 0, 0, 0, 0, 0, 0, 0])
        self.refresh()
        self.assertNotIn("illusion_state", self.save)

    def test_old_account_stays_on_the_last_round_instead_of_empty_pages(self):
        self.account_age(1)
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 8117))[0::3], self.task_ids(1))
        self.account_age(10 ** 4)
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 8117))[0::3], self.task_ids(4))
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 8113))[0::3],
                         self.gift_ids("illusion_present_time_x1", 4))

    def test_free_task_grants_configured_days_and_claims_only_once(self):
        self.account_age(1)
        body = self.success(1, 8118, values=[1])
        self.refresh()
        iid, end = illusion.get_state(self.save, self.config)["items"]["200503"]
        self.assertEqual(iid, 0)
        self.assertEqual((end + illusion.UTC8) % illusion.DAY, 0)
        self.assertGreater(end, self.now)
        self.assertLessEqual(end, self.now + 4 * illusion.DAY)
        reward = [v for n, w, v in protocol.iter_pb_fields(body) if n == 18]
        self.assertEqual(protocol.parse_ids_pb(reward[0]), [200503, iid, end, 3])
        self.assert_rejected(8118, values=[1])
        self.reconnect(); self.refresh()
        self.assertEqual(illusion.get_state(self.save, self.config)["items"]["200503"], [iid, end])

    def test_gift_needs_actual_recharge_and_stops_at_configured_times(self):
        self.account_age(1)
        self.assert_rejected(8114, values=[201001])
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 8113))[1], 0)
        self.recharge_rmb(648)
        rows = protocol.parse_ids_pb(self.success(1, 8113))
        self.assertEqual(rows[1], 1)
        fragments = self.fragment(10839)
        packets = self.request(1, 8114, values=[201001])
        self.assertEqual(packets[0][0], 8114)
        self.assertIn(1012, [mid for mid, _ in packets])
        self.assertIn(1001, [mid for mid, _ in packets])
        self.assertIn(8110, [mid for mid, _ in packets])
        self.refresh()
        self.assertEqual(self.fragment(10839), fragments + 170)
        images = illusion.get_state(self.save, self.config)["items"]["200501"]
        self.assertEqual(images[0], 0)
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 8113))[2], 1)
        # 201001 的 number 是 2：第二次成功，第三次已达上限。
        self.success(1, 8114, values=[201001])
        self.refresh()
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 8113))[1:3], [2, 2])
        self.assert_rejected(8114, values=[201001])
        self.assertGreater(illusion.get_state(self.save, self.config)["items"]["200501"][1], images[1])

    def test_task_purchase_charges_real_gold_and_progress_comes_from_real_counters(self):
        self.account_age(1)
        gold = self.save["role_state"]["gold"]
        self.assert_rejected(8118, values=[3])
        packets = self.request(1, 8118, values=[4])
        self.assertEqual(packets[0][0], 8118)
        self.assertIn(1001, [mid for mid, _ in packets])
        self.refresh()
        self.assertEqual(self.save["role_state"]["gold"], gold - 800)
        self.assertEqual(illusion.get_state(self.save, self.config)["items"]["200535"][0], 0)
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 8117))[1::3][3], 2)
        self.assert_rejected(8118, values=[4])
        # 类型2读真实元宝累计消费，不是凭空补的次数。
        self.refresh()
        self.save["activity_state"]["gold_spent"] = 30000
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 8117))[1::3][2], 1)
        self.success(1, 8118, values=[3])
        self.refresh()
        self.assertIn("200518", illusion.get_state(self.save, self.config)["items"])

    def test_activity_rejects_bad_parameters_unknown_ids_and_future_clock(self):
        self.account_age(1)
        self.assert_rejected(8113, values=[1])
        self.assert_rejected(8115, values=[1])
        self.assert_rejected(8117, values=[1])
        self.assert_rejected(8114, values=[201001, 1])
        self.assert_rejected(8114, values=[0])
        self.assert_rejected(8114, values=[999999])
        self.assert_rejected(8118, values=[200501])
        self.refresh()
        self.save["illusion_state"] = {"items": {}, "gifts": {"1:999999": 1}, "serial": 0, "checked_at": 0}
        self.assert_rejected(8110, values=[1])
        self.refresh()
        del self.save["illusion_state"]
        self.save["created_at"] = self.now + 10 * illusion.DAY
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 8113)), [])
        self.assertEqual(protocol.parse_ids_pb(self.success(1, 8117)), [])
        self.assert_rejected(8118, values=[1])
