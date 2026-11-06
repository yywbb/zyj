"""幻化：临时账号、真实协议/技能、有效期、失败回滚及包内Lua。"""

import copy
import unittest
from unittest.mock import patch

import test_soul
from zyj_server import battle, cheer, cup, formation, guild_war, illusion, partner_growth, player, protocol, qiankun, recruit, single_boss


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
