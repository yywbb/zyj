"""银座完整结算：真实v2、定时产出、临时存档、实际APK回调。"""

import copy
import json
import unittest
import zipfile
from unittest.mock import patch

import build_local_apk as builder
import test_soul
from zyj_server import activities, formation, nightclub, player, protocol, qiankun, recharge, recruit


def setUpModule():
    test_soul.setUpModule()


class NightclubTests(unittest.TestCase):
    request = test_soul.SoulTests.request
    success = test_soul.SoulTests.success
    reconnect = test_soul.SoulTests.reconnect
    add_account = test_soul.SoulTests.add_account
    assert_rejected = test_soul.SoulTests.assert_rejected
    refresh = test_soul.SoulTests.refresh
    grant = test_soul.SoulTests.grant
    props = test_soul.SoulTests.props
    groups = test_soul.SoulTests.groups
    records = test_soul.SoulTests.records
    client_scripts = classmethod(test_soul.SoulTests.client_scripts.__func__)
    network_lua = test_soul.SoulTests.network_lua
    client_call = test_soul.SoulTests.client_call

    def setUp(self):
        test_soul.SoulTests.setUp(self)
        self.save["role_state"].update(level=125, energy=1000, vip=7)

    def partner(self, cid=10598):
        player.apply_reward(self.save, recruit.build_reward(self.save, [(cid, 1)], self.config), self.config, self.now)
        return next(iid for iid, raw in formation.records(bytes.fromhex(self.save["world_state"]["1002"]), 1, 2).items()
                    if protocol.pb_get_varint(raw, 1) == cid)

    def strong(self):
        world = bytes.fromhex(self.save["world_state"]["1002"])
        active = {protocol.pb_get_varint(slot, 2) for slot in formation.records(world, 4, 1).values()}
        for iid, raw in formation.records(world, 1, 2).items():
            if iid not in active:
                continue
            for field in (6, 8):
                raw = protocol.pb_set_varint(raw, field, 1000000000)
            player.record_slot_update(self.save, protocol.encode_pb_field(1, 2, raw))
            player.record_protagonist_general(self.save, raw)

    def unlock(self, count=1):
        self.strong()
        for floor in range(1, count + 1):
            self.success(1, 4502, values=[floor]); self.refresh()
        self.assertEqual(self.save["nightclub_state"]["cleared"], list(range(1, count + 1)))

    def dispatch(self, floor, iid, time=1):
        raw = self.success(1, 4503, values=[floor, time, iid]); self.refresh()
        values = protocol.parse_ids_pb(raw)
        if values[1]:
            self.event(floor, 0)
        return self.save["nightclub_state"]["jobs"][str(floor)]

    def event(self, floor, choose):
        job = self.save["nightclub_state"]["jobs"][str(floor)]
        reply = self.success(1, 4505, values=[floor, choose, job["event"], job["start"]]); self.refresh()
        return reply

    def claim(self, floor):
        return [floor, self.save["nightclub_state"]["jobs"][str(floor)]["start"]]

    def test_ten_real_floor_wins_first_rewards_and_achievement_no_campaign_or_xp_cost(self):
        before = copy.deepcopy(self.save)
        self.unlock(10)
        self.assertEqual(self.save["world_state"]["1300"], before["world_state"]["1300"])
        for key in ("stamina", "energy", "exp", "level"):
            self.assertEqual(self.save["role_state"][key], before["role_state"][key])
        self.assertIn(53010, self.save["achievement_state"]["completed"])
        self.assert_rejected(4502, values=[1])
        self.reconnect(); self.refresh()
        self.assertEqual(set(self.groups(self.success(1, 4500))), set(range(1, 11)))

    def test_actual_loss_is_free_and_does_not_unlock_or_grant_first_reward(self):
        before = copy.deepcopy(self.save)
        raw = self.groups(self.success(1, 4502, values=[1]))[1]; self.refresh()
        self.assertEqual(protocol.pb_get_varint(raw, 1), 0)
        self.assertEqual(self.save["nightclub_state"]["cleared"], [])
        self.assertEqual(self.save["world_state"], before["world_state"])
        self.assertEqual(self.save["role_state"], before["role_state"])

    def test_all_nine_time_tiers_charge_real_config_and_never_grant_unelapsed_income(self):
        iid = self.partner()
        self.unlock(9)
        for time in range(1, 10):
            before = copy.deepcopy(self.save["role_state"])
            self.success(1, 4503, values=[time, time, iid]); self.refresh()
            job = self.save["nightclub_state"]["jobs"][str(time)]
            row = self.config["tiantingyz_time"][str(time)]
            self.assertEqual(job["end"] - job["start"], row["time"] * 3600)
            self.assertEqual(self.save["role_state"]["energy"], before["energy"] - row["murderous"])
            self.assertEqual(self.save["role_state"]["gold"], before["gold"] - row["Ingots"])
            if not job["resolved"]:
                self.event(time, 0)
            self.assertIn(iid, qiankun.protected(self.save))
            self.assert_rejected(4504, values=self.claim(time))
            self.clock.return_value = job["end"]
            self.success(1, 4504, values=self.claim(time)); self.refresh()
        self.assertEqual(activities.liveness_statuses(self.save, self.config, int(self.clock.return_value))[0][27], 1)

    def test_frozen_tick_income_reconnect_clock_rollback_and_claim_match_actual_rewards(self):
        iid = self.partner(); self.unlock()
        job = copy.deepcopy(self.dispatch(1, iid))
        self.clock.return_value += 1800
        values = protocol.parse_ids_pb(self.success(1, 4501, values=[1])); self.refresh()
        self.assertEqual(values[7], job["ticks"][0][0])
        self.reconnect(); self.refresh()
        self.assertEqual(self.save["nightclub_state"]["jobs"]["1"]["ticks"], job["ticks"])
        self.clock.return_value = job["end"]
        before = copy.deepcopy(self.save)
        gets = nightclub.claim(copy.deepcopy(self.save["nightclub_state"]), [(1, job["start"])], self.config, int(self.clock.return_value))
        reward = recruit.build_reward(before, gets, self.config)
        player.apply_reward(before, reward, self.config, int(self.clock.return_value))
        self.success(1, 4504, values=self.claim(1)); self.refresh()
        for mid in ("1002", "1012", "1200"):
            self.assertEqual(self.save["world_state"][mid], before["world_state"][mid])
        self.assertNotIn(iid, qiankun.protected(self.save))
        self.assert_rejected(4504, values=[1])
        self.clock.return_value -= 1
        self.assert_rejected(4503, values=[1, 1, iid])

    def test_batch_ownership_occupied_duplicate_iid_limits_vip_and_atomic_failure(self):
        a, b = self.partner(), self.partner(10609); self.unlock(2)
        before = copy.deepcopy(self.save)
        for values in ([0] + [a] + [0] * 9, [1] + [a, a] + [0] * 8, [1] + [a, 99999] + [0] * 8):
            self.assert_rejected(4509, values=values)
        self.save["role_state"]["vip"] = 0
        self.assert_rejected(4503, values=[1, 4, a])
        self.save = self.sessions[1].save = before
        self.save["role_state"]["energy"] = 15
        self.assert_rejected(4509, values=[1, a, b] + [0] * 8)
        self.save["role_state"]["energy"] = 16
        self.success(1, 4509, values=[1, a, b] + [0] * 8); self.refresh()
        self.assertEqual(self.save["role_state"]["energy"], 0)
        self.assert_rejected(4503, values=[1, 1, b])
        self.assert_rejected(1035, values=[a])
        self.assert_rejected(1039, raw=protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, a)
            + protocol.encode_pb_field(2, 0, (1 << 64) - 1)))
        for floor, job in list(self.save["nightclub_state"]["jobs"].items()):
            if not job["resolved"]:
                self.event(int(floor), 0)
        self.clock.return_value += 14400
        self.assert_rejected(4510, values=[1, 1])
        self.success(1, 4510, values=self.claim(1) + self.claim(2)); self.refresh()
        self.assertEqual(self.save["nightclub_state"]["jobs"], {})

    def test_all_config_events_actual_costs_rewards_and_battles_settle_once(self):
        iid = self.partner(); self.unlock(4)
        for event in self.config["tiantingyz_sjtype"].values():
            floor = next(int(k) for k, r in self.config["tiantingyz_guanqia"].items() if str(event["id"]) in r["event_id"].split(";"))
            with self.subTest(event=event["id"]):
                # 使用真实派驻记录，仅指定本轮随机事件便于覆盖全部配置分支。
                if str(floor) not in self.save["nightclub_state"]["jobs"]:
                    self.save["nightclub_state"]["cleared"] = list(range(1, 11))
                    self.dispatch(floor, iid)
                job = self.save["nightclub_state"]["jobs"][str(floor)]
                job.update(event=event["id"], resolved=False)
                for cid, amount in nightclub.pairs(event["cost"]).items():
                    player.change_item_count(self.save, cid, amount, self.config, int(self.clock.return_value))
                expected = copy.deepcopy(self.save)
                for cid, amount in nightclub.pairs(event["cost"]).items():
                    player.change_item_count(expected, cid, -amount, self.config, int(self.clock.return_value))
                player.apply_reward(expected, recruit.build_reward(expected, list(nightclub.pairs(event["bonus1"]).items()), self.config), self.config, int(self.clock.return_value))
                raw = self.event(floor, 1)
                self.assertEqual(protocol.pb_get_varint(raw, 1), 1 if event["fighting"] else (1 << 64) - 1)
                self.assertEqual((self.save["role_state"], self.save["world_state"]), (expected["role_state"], expected["world_state"]))
                self.assert_rejected(4505, values=[floor, 1])
                self.save["nightclub_state"]["jobs"].clear()

    def test_invalid_payloads_save_failure_overflow_and_bad_saved_income_are_non_mutating(self):
        for opcode in nightclub.OPCODES:
            self.assert_rejected(opcode, raw=b"\x10\x01")
        self.assert_rejected(4501, values=[0])
        self.assert_rejected(4502, values=[2])
        iid = self.partner(); self.unlock()
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 4503, values=[1, 1, iid])
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))
        job = self.dispatch(1, iid)
        self.clock.return_value = job["end"]
        self.save["role_state"]["coin"] = (1 << 63) - 1
        # 保证本次含银币产出，溢出不能释放伙伴或吞掉收益。
        job["ticks"][0][1] = [[1, 1]]
        self.assert_rejected(4504, values=self.claim(1))
        self.save["role_state"]["coin"] = 0
        before, disk = copy.deepcopy(self.save), self.store.path(1).read_bytes()
        with patch.object(player, "save_role", return_value=False), self.assertRaises(OSError):
            self.request(1, 4504, values=self.claim(1))
        self.assertEqual((self.sessions[1].save, self.store.path(1).read_bytes()), (before, disk))
        job["ticks"] = []
        self.assert_rejected(4501, values=[1])

    def test_stale_job_claim_and_event_tokens_and_same_connection_retry_never_reapply(self):
        iid = self.partner(); self.unlock()
        self.dispatch(1, iid)
        self.clock.return_value += 14400
        old = self.claim(1)
        body = recharge.ids(old)
        packets = self.sessions[1].handle(4504, 7878, body)
        self.assertEqual(self.sessions[1].handle(4504, 7878, body), packets)
        self.refresh()
        job = self.dispatch(1, iid)
        self.assert_rejected(4504, values=old)
        event = int(self.config["tiantingyz_guanqia"]["1"]["event_id"].split(";")[0])
        job.update(event=event, resolved=False)
        self.assert_rejected(4505, values=[1, 1, event, old[1]])
        self.assert_rejected(4505, values=[1, 1])
        self.assert_rejected(999900, raw=protocol.encode_pb_field(1, 2, protocol.encode_pb_field(1, 0, 4503)))

    def test_actual_native_network_pb_callbacks_prices_zero_slots_fifo_and_matching_errors(self):
        iid, second = self.partner(), self.partner(10609); self.unlock(2)
        lua = self.network_lua(native_protobuf=True)
        native = builder.read_script("gamedata").decode()
        lua.execute(native[native.index("function gamedata.generalfragmentData("):native.index("function gamedata.recruitsData(")].encode())
        lua.execute(b'''gamedata.cache.generalfragments={}
            makeAllGeneralsTemp=function() local t={} for iid,v in pairs(gamedata.cache.generals) do
                if gamedata.config.general[tostring(v.cid)].actor~="lead" then t[iid]=v end end return t end
            gamedata.getOriginCid=function(cid) return gamedata.config.general[tostring(cid)].init_cid end
            gamedata.findFragmentCid=function(self,cid) for _,v in pairs(self.config.general_fragment) do if v.general==cid then return v.id end end end''')
        lua.eval(b"require")(b"GameNightclub")
        self.client_call(lua, 1, "UIUserPatrolQuery", "NetUserPatrolQuery", {"nightclubView": 1})
        result = self.client_call(lua, 1, "UIUserPatrolStatus", "NetUserPatrolStatus", {"_id": 1})
        self.assertEqual((result[b"status"][b"1"], result[b"status"][b"5"]), (2, 0))
        gold, energy = self.save["role_state"]["gold"], self.save["role_state"]["energy"]
        req = lua.table_from({b"_id": 1, b"_cid": iid, b"_time": 1, b"_shaNum": 9999, b"_shaType": 1})
        mode, opcode, raw = lua.globals().UIUserPatrolDo(req)
        self.assertEqual((mode, opcode, protocol.parse_ids_pb(raw)), (1, 4503, [1, 1, iid]))
        self.assertEqual(lua.globals().UIUserPatrolDo(req)[0], 0)
        fd = lambda raw: lua.table_from({b"rbuf": raw})
        lua.globals().NetErrorMessageCallback9(fd(recharge.ids([4504, 0])))
        self.assertEqual(lua.globals().gamedata[b"ext"][b"localNightclubBusy"], 4503)
        result = lua.globals().NetUserPatrolDo(fd(self.success(1, opcode, raw=raw))); self.refresh()
        self.assertEqual((lua.globals().gamedata[b"cache"][b"role"][b"gold"], lua.globals().gamedata[b"cache"][b"role"][b"energy"]), (gold, energy - 8))
        self.assertEqual(result[b"status"][b"5"], 10598)
        stamp = result[b"status"][b"7"]
        self.assertEqual(lua.globals().UIUserPatrolReward(lua.table_from({b"_id": 1}))[0], 0)
        claim = lua.table_from({b"_id": 1, b"nightclubToken": lua.table_from({b"stamp": stamp})})
        self.assertEqual(protocol.parse_ids_pb(lua.globals().UIUserPatrolReward(claim)[2]), [1, stamp])
        lua.globals().NetErrorMessageCallback9(fd(recharge.ids([4504, 0])))
        self.assertIsNone(lua.globals().gamedata[b"ext"][b"localNightclubBusy"])
        for view in (3, 4): lua.globals().UIUserPatrolQuery(lua.table_from({b"nightclubView": view}))
        for view in (3, 4):
            result = lua.globals().NetUserPatrolQuery(fd(self.success(1, 4500)))
            self.assertEqual(result[b"nightclubView"], view)
        self.refresh()
        self.save["nightclub_state"]["jobs"]["1"].update(event=1, resolved=False)
        self.client_call(lua, 1, "UIUserPatrolStatus", "NetUserPatrolStatus", {"_id": 1})
        result = self.client_call(lua, 1, "UIUserPatrolEventDo", "NetUserPatrolEventDo", {
            "_index": 1, "_choose": 1, "_gold": 9999, "nightclubToken": lua.table_from({b"event": 1, b"stamp": stamp})})
        self.refresh()
        self.assertEqual(result[b"result"], -1)
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"gold"], self.save["role_state"]["gold"])
        self.clock.return_value += 14400
        self.client_call(lua, 1, "UIUserPatrolReward", "NetUserPatrolReward", {"_id": 1, "nightclubToken": lua.table_from({b"stamp": stamp})})
        self.refresh()
        self.client_call(lua, 1, "UIUserPatrolOneAddQuery", "NetUserPatrolOneAddQuery", {})
        self.client_call(lua, 1, "UIUserPatrolOneAdd", "NetUserPatrolOneAdd", {"_time": 1, "data": lua.table_from({b"1": iid, b"2": second}), "_shaNum": 1, "_baoNum": 9999})
        self.refresh()
        self.assertEqual(lua.globals().gamedata[b"cache"][b"role"][b"energy"], self.save["role_state"]["energy"])
        self.assertIsNone(lua.globals().gameConfig)

    def test_actual_ui_generation_rejects_old_windows_and_timer_does_not_accelerate_income(self):
        from lupa.lua51 import LuaRuntime
        lua = LuaRuntime()
        scripts = self.client_scripts()
        for name in ("GameNightclub", "UINightclub", "Layer_nightclub_main", "Layer_nightclub_cell", "Layer_nightclub_oneAdd", "window_nightclubchance"):
            lua.compile(scripts[f"assets/scripts/{name}.so"].decode())
        page = lua.execute(scripts["assets/scripts/Layer_nightclub_main.so"].decode())
        lua.globals().page = page
        lua.execute('''print=function() end;printT=print
            requests={};UIRequest=function(t) requests[#requests+1]=t end
            GameScene={layers={nightclub={show=true,module=page}},presentLayer="nightclub"}
            page.rootNode={};page.localNightclubGeneration=1
            page.reloaddata=function(self) self.reads=(self.reads or 0)+1 end
            now=100;gamedata={time=function() return now end}
            ui={setLabelString=function() end,makeTimeText=tostring}
            gameConfig={strings={string_common=function() return "" end}}
            gameTimer={times={},rigistTime=function(self,key,n) self.times[key]=n end,
                rigistTimeFunc=function(self,key,cb) timer=cb end,UnrigistTimeFunc=function() end}
        ''')
        lua.execute(scripts["assets/scripts/UINightclub.so"].decode())
        lua.execute('''UIRequest({type=4500});local view=requests[1].nightclubView
            UIUserPatrolQuery({nightclubView=view});assert(page.reads==1)
            page.localNightclubGeneration=2
            UIUserPatrolQuery({nightclubView=view});assert(page.reads==1)
            page:updatetimeFunc({},1,60)
            for i=1,100 do timer() end;assert(gameTimer.times.night_1==60 and #requests==1)
            now=160;timer();assert(#requests==2 and requests[2].type==4500)
            page.localNightclubGeneration=3;timer();assert(#requests==2)
            window={rootNode={},localNightclubGeneration=1,reload=function(self) self.reads=(self.reads or 0)+1 end}
            package.loaded.window_nightclubchance=window
            gameWindows={windows={clubchance={show=true,module=window}}}
            updateDataLife=function() return false,false end
            local t={type=4505,result=-1,nightclubView={page="nightclub",generation=3,window=1},reward={}}
            UIUserPatrolEventDo(t);assert(window.reads==1)
            window.localNightclubGeneration=2
            UIUserPatrolEventDo(t);assert(window.reads==1)
        ''')

    def test_all_ten_profiles_convert_actual_apk_battle_animations_without_changing_main_save(self):
        from lupa.lua51 import LuaRuntime
        lua = LuaRuntime()
        config = dict(self.config)
        with zipfile.ZipFile("configs_sec5.zip") as archive:
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
                    assets[path] = json.loads(archive.read(next(n for n in names if n.endswith("/" + path))))
                return lua.table_from(assets[path], recursive=True)
            lua.globals().LoadJsonFileToTable = load_asset
            lua.execute(self.client_scripts()["assets/scripts/battleReportConvert.so"])
            lua.execute(builder.read_script("BattleReportAbbToKey"))
            before = copy.deepcopy(self.save)
            for floor in range(1, 11):
                report = nightclub.simulate(self.save, floor, config, 7)
                native = lua.table_from(json.loads(lua.globals().ReplaceAbbToKey(json.dumps(report))), recursive=True)
                attack, defense = lua.globals().getBattleInitSlotInfo(native)
                animations, ext = lua.globals().convertBattleReportToAnimationSub(native, attack, defense, None, "nightclub1")
                self.assertGreater(len(animations), 1)
                for side, key in (("attack", "atk"), ("defense", "def")):
                    for pos, unit in report["endmeta"][side].items():
                        self.assertEqual(ext.endinfo[key][pos].hp, unit["h"])
            self.assertEqual(self.save, before)


if __name__ == "__main__":
    unittest.main()
