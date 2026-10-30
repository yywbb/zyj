import contextlib
import io
import json
import os
from pathlib import Path
import shutil
import struct
import tempfile
import unittest
from unittest.mock import patch
import zipfile

import build_local_apk as builder
import build_download_tool as download_builder
from zyj_server import configuration, player, ranking


class LanBuildTests(unittest.TestCase):
    def test_download_tool_rejects_credentials_and_non_minio_base_urls_before_building(self):
        self.assertEqual(download_builder.validate_download_base("https://example.com/bucket/"), "https://example.com/bucket/")
        for value in ("file:///bucket/", "http://user:password@example.com/bucket/", "https://example.com/",
                      "http://example.com/bucket/?secret=value", "http://example.com/bucket/#fragment", "https://example.com/bucket"):
            with self.subTest(value=value), self.assertRaises(ValueError):
                download_builder.validate_download_base(value)
        with patch.object(download_builder.subprocess, "run") as run, contextlib.redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit):
                download_builder.main(["--download-base", "file:///bucket/"])
            run.assert_not_called()

    def test_account_list_uses_one_lan_endpoint_and_preserves_extra_fields(self):
        original = json.dumps({"9": {"id": 9, "name": "old", "ip": "old", "port": 1, "extra": True}}).encode()
        with contextlib.redirect_stdout(io.StringIO()):
            result = builder.patch_game_server_json(original, "192.168.1.20", 3)
        servers = json.loads(result)
        self.assertEqual(list(servers), ["1", "2", "3"])
        for account, row in servers.items():
            self.assertEqual((row["id"], row["name"]), (int(account), f"账号 {account}"))
            self.assertEqual((row["ip"], row["port"]), ("192.168.1.20", 14600))
            self.assertTrue(row["extra"])

    def test_server_address_must_be_a_lan_ipv4_not_loopback_or_public(self):
        for address in ("192.168.1.20", "10.1.2.3", "172.16.0.20"):
            self.assertEqual(builder.parse_server_ip(address), address)
        for address in ("127.0.0.1", "0.0.0.0", "8.8.8.8", "224.0.0.1", "169.254.1.2", "::1", "not-an-ip"):
            with self.subTest(address=address), self.assertRaises(ValueError):
                builder.parse_server_ip(address)

    def test_invalid_build_arguments_do_not_start_packaging(self):
        cases = ([], ["--server-ip", "127.0.0.1"], ["--server-ip", "192.168.1.20", "--accounts", "0"],
                 ["--server-ip", "192.168.1.20", "--accounts", "1001"], ["--unknown"])
        with patch.object(builder, "get_patched_lua_scripts") as build, contextlib.redirect_stderr(io.StringIO()):
            for args in cases:
                with self.subTest(args=args), self.assertRaises(SystemExit) as error:
                    builder.main(args)
                self.assertEqual(error.exception.code, 2)
            build.assert_not_called()

    def client_scripts(self):
        sources = Path(__file__).parent / "scripts_clean"

        def read_reference_script(relative, folder="scripts"):
            return (sources / (relative + ".lua")).read_text(encoding="utf-8").encode("utf-8")

        with tempfile.TemporaryDirectory() as directory:
            fixture = Path(directory) / "fixture.apk"
            log = b"function echo(...)\n    if gamedata and not gamedata.isshowlog then return end\nend\n"
            with zipfile.ZipFile(fixture, "w") as archive:
                archive.writestr("assets/common_lua/log.so", builder.xxtea_encrypt(log, builder.XXTEA_KEY))
            with patch.object(builder, "SRC_APK", str(fixture)), patch.object(builder, "read_script", side_effect=read_reference_script), contextlib.redirect_stdout(io.StringIO()):
                patched = builder.get_patched_lua_scripts()

        def decrypted(path):
            raw = builder.xxtea_decrypt(patched[path], builder.XXTEA_KEY)
            length = struct.unpack("<I", raw[-4:])[0]
            self.assertLessEqual(length, len(raw) - 4)
            self.assertEqual(raw[length:-4], b"\0" * (len(raw) - 4 - length))
            return raw[:length].decode("utf-8")

        return {path: decrypted(path) for path in patched}

    def test_client_patches_select_and_remember_account_without_loopback(self):
        decrypted = self.client_scripts().__getitem__
        login = decrypted("assets/scripts/accbyhttp/service_ui.so")
        enter = decrypted("assets/scripts/accbyhttp/http_entergame.so")
        network = decrypted("assets/scripts/gameserver.so")
        scene = decrypted("assets/scripts/accbyhttp/LoginScene.so")
        handoff = decrypted("assets/scripts/accbyhttp/service_net.so")
        validate = decrypted("assets/scripts/GameUserValid.so")
        errors = decrypted("assets/common_lua/GameErrorMessage.so")
        self.assertIn('fullPathForFilename("LocalGameServer.json")', login)
        self.assertIn('getIntegerForKey("local_account", 1)', login)
        self.assertIn('recentlist = { ["1"] = selected }', login)
        self.assertIn('uuid = "local_account_" .. tostring(account), section = 1', enter)
        self.assertIn('tonumber(params.sid)', enter)
        self.assertNotIn('setIntegerForKey', enter)
        self.assertNotIn("local_mock_uuid_10001", enter)
        self.assertNotIn("127.0.0.1", login + network)
        self.assertIn("host = gamedata.serverlist[tonumber(gamedata.selectserver)].ip", network)
        self.assertIn("port = gamedata.serverlist[tonumber(gamedata.selectserver)].port", network)
        self.assertNotIn("999898", network)
        self.assertIn("self:showUserInput(11)", scene)
        self.assertIn("self.passwordInputBox:setInputFlag(0)", scene)
        self.assertIn("self.passwordInputBox:registerScriptEditBoxHandler(noop)", scene)
        self.assertIn("account > 1000", scene)
        self.assertNotIn("acctest:userlogin()", scene)
        self.assertNotIn("acctest:userrigist()", scene)
        self.assertIn("local_password = gamedata.local_password", login)
        self.assertIn("gamedata.local_password = uireq.local_password", handoff)
        self.assertIn('credential.s = gamedata.local_password or ""', validate)
        self.assertLess(validate.index("table.insert(params.params, credential)"), validate.index("if gamedata.reconnect_type then"))
        self.assertIn("error.ids[1] == 1000", errors)
        self.assertIn("type = 9997", errors)
        self.assertIn("local_login_failed = true", errors)
        form = scene[scene.index("function loginScene.showUserInput("):scene.index("function loginScene.egameabout(")]
        self.assertNotIn("setStringForKey", form + enter)
        self.assertIn("if t.location == 0 then LoginScene:rememberLocalLogin() end", decrypted("assets/scripts/UILogin.so"))
        self.assertIn("LoginScene:failLocalLogin(t.msg, true)", decrypted("assets/scripts/UIErrorMessage.so"))

    def test_local_rank_callbacks_preserve_ui_handoff_and_native_artifact_details(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("排行榜回调验证需本机已有 lupa.lua51")
        scripts = self.client_scripts()
        layer = scripts["assets/scripts/Layer_rank2.so"]
        self.assertNotIn("http_artifact_rank", layer)
        lua = LuaRuntime()
        lua.execute('''
            cclog, printT = function() end, function() end
            local function message()
                return {ids={},SerializeToString=function(self) return self.ids end,
                    ParseFromString=function(self,data) for k,v in pairs(data) do self[k]=v end end}
            end
            package.preload.ids_pb=function() return {Ids=message} end
            package.preload.players_pb=function() return {Players=message} end
            gamedata={ext={},cache={role={id=25}}}
            function gamedata:players(data) return data end
            function gamedata:artifactData(data) return data end
        ''')
        lua.execute(scripts["assets/scripts/GameRank.so"])
        lua.execute('''
            local remote,opcode,body=UIRankQueryCallBack({method=0})
            assert(remote==1 and opcode==3500 and #body==3 and body[1]==0)
            local value={params={iid=5000001,cid=110001,name="铸造者",score=999,level1=7,
                attr1=15,attr2=1,levelHP=100,levelAttack=10,levelDef=20,
                resonanceActiveId1=1,resonanceActiveId2=2,resonanceActiveId3=3}}
            local response=NetRankQueryCallBack({rbuf={players={value}}})
            assert(response.method==0 and response.players[1].artifact.cid==110001)
            assert(response.players[1].score==999 and response.players[1].artifact.level1==7)
            local _,_,current=UIRankQueryCallBack({method=11,activityRankId=106})
            assert(#current==4 and current[4]==106)
            local _,_,old=UIOldRankQueryCallBack({method=1,activityRankId=11})
            assert(#old==4 and old[4]==11)
            GameScene={layers={ranklist={show=true,module={
                setMyArtifactData=function(self,p) self.own=p end,
                ReloadData=function(self,t) self.data=t end}}}}
        ''')
        lua.execute(scripts["assets/scripts/UIRank.so"])
        lua.execute('''
            UIRankQuery({method=0,players={}})
            assert(GameScene.layers.ranklist.module.own~=nil)
            assert(GameScene.layers.ranklist.module.data.method==0)
        ''')

    def test_rank_periods_and_fragment_batch_scripts_are_packaged_not_reference_only(self):
        scripts = self.client_scripts()
        self.assertIn("localRankOpenedAt", scripts["assets/scripts/GameActivityQuery.so"])
        self.assertIn("v.id == 5601", scripts["assets/scripts/GameActivityQuery.so"])
        self.assertIn("GameScene.localRankOpenedAt = t.localRankOpenedAt", scripts["assets/scripts/UIActivity.so"])
        for name in ("newrank", "powerRank", "sigilPowerRank", "powerGrowthRank", "powerGrowthRank_x1", "powerGrowthRank_x2",
                     "magicWeaponRank", "copyRank", "shieldRank", "wingRank", "minggeRank", "partnerPowerRank", "artifactRank"):
            self.assertIn("GameScene.localRankOpenedAt", scripts[f"assets/scripts/Layer_activity_{name}.so"])
        self.assertIn('tonumber(gamedata.config.props["20020"].param1)', scripts["assets/scripts/GameRob.so"])
        self.assertIn("uireq.isautoxh ~= 0", scripts["assets/scripts/GameRob.so"])
        self.assertNotIn("next(gamedata.cache.mails) and not uireq.update", scripts["assets/scripts/GameMails.so"])
        self.assertIn("self.cache.petsfragment = {}", scripts["assets/scripts/gamedata.so"])
        tables = player.load_role_config(Path(__file__).parent / "configs_sec5.zip")
        for activity, _ in ranking.EVENTS.values():
            row = tables["activity_time"][str(activity)]
            self.assertEqual((row["open_type"], row["begin"], row["days_later"]), (1, "", 0))
        self.assertTrue(all(row["default"] == 1 for row in tables["treasure2_fragment"].values()))

    def test_all_treasure_lists_keep_tutorial_target_in_first_row_with_real_lua(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("挑战列表行为验证需本机已有 lupa.lua51")
        scripts = self.client_scripts()
        lua = LuaRuntime()
        config = player.load_role_config(Path(__file__).parent / "configs_sec5.zip")
        lua.globals().gamedata = lua.table_from({"config": config, "cache": {"equipfragments": {
            28011: {"cid": 28011, "num": 1}, 28012: {"cid": 28012, "num": 1}}}}, recursive=True)
        code = scripts["assets/scripts/gamedata.so"]
        lua.execute(code[code.index("function gamedata.sortData("):code.index("function gamedata.sortDataByOrder(")])
        lua.execute('''
            table.copy=function(t) local out={} for k,v in pairs(t) do out[k]=v end return out end
            mekehintext=function() end
            for _,name in ipairs({"PickBattleResultReport","players_pb","ids_pb","battleresult_pb","somethings_pb","combmessages_pb"}) do
                package.preload[name]=function() return {} end
            end
        ''')
        lua.execute(scripts["assets/scripts/GameRob.so"])
        lua.execute('''
            local treasures,horses=makeTreasureRob()
            assert(#treasures>20 and #horses>20)
            assert(treasures[1].cid==26102)
            assert(treasures[1].fragments[1].cid==28010 and treasures[1].fragments[1].num==0)
            assert(treasures[1].fragments[2].num==1 and treasures[1].fragments[3].num==1)
        ''')

    def test_treasure_ten_result_counts_actual_attempts_including_losses_without_rob_tokens(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("十连结算行为验证需本机已有 lupa.lua51")
        scripts = self.client_scripts()
        lua = LuaRuntime()
        lua.execute('''
            cclog, printT = function() end, function() end
            local function message() return {ParseFromString=function(self,data)
                for k,v in pairs(data) do self[k]=v end end} end
            for _,name in ipairs({"players_pb","ids_pb","somethings_pb","combmessages_pb","battleresult_pb"}) do
                package.preload[name]=function() return {Ids=message,SomeThings=message,CombMessages=message} end
            end
            package.preload.PickBattleResultReport=function() return {} end
            gamedata={cache={role={energy=10},props={}},ext={robrequest={cid=28002}}}
            function gamedata:SomethingProcess(data) return data.items end
            function gamedata:updateRoleEnergy(delta) self.cache.role.energy=self.cache.role.energy+delta end
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
        ''')
        lua.execute(scripts["assets/scripts/GameRob.so"])
        lua.execute('''
            result=NetGameTreasureFragmentRobTenCallBack({rbuf={messages={
                {data={ids={3}}}, {data={items={}}}, {data={items={{cid=1000,num=220}}}},
                {data={items={{cid=1000,num=220},{cid=28002,num=1},{cid=20100,num=1}}}}
            }}})
            assert(result.energy==3 and gamedata.cache.role.energy==7)
            assert(#result.coin==3 and result.coin[1].num==0 and result.coin[3].num==220)
            assert(#result.rob==3 and result.rob[1].num==0 and result.get.cid==28002)
            -- UI/net handoff converts list keys to strings.
            for _,key in ipairs({"coin","rob","otherreward"}) do
                local out={} for i,v in ipairs(result[key]) do out[tostring(i)]=v end result[key]=out
            end
            function item() return {setString=function(self,v) self.value=v end,
                setVisible=function() end,setPosition=function() end,addChild=function() end,
                setSwallowsTouch=function() end,setTouchPriority=function() end,
                addHandleOfControlEvent=function() end,getContentSize=function() return {width=920,height=680} end} end
            ui={setLabelString=function() end,IDconfig=function() return {name="碎片"} end,
                createLuaTableView=function(data) rowHandler=data.handle return item() end}
            gameWindows={closeWindowDirect=function() end}
            LuaEventHandler={create=function(self,fn) return fn end}
            CCTableViewCell={create=item}
            CCBReaderLoad=function() return item(),{getCoinTenSprite=item(),lineNumLabel=item(),
                getCoinNumLabel=item(),getNode=item(),rewardUpName=item()} end
            setSpriteFrameByName=function() end
            gameConfig={strings={numci=function(self,n) return tostring(n) end}}
            CCControlEventTouchUpInside=1
        ''')
        window = lua.execute(scripts["assets/scripts/window_robresult.so"])
        lua.globals().window = window
        lua.execute('''
            window.configdata=result
            window.rootItems={}
            for _,key in ipairs({"lookRewardBtn_Text","lookRewardBtn","rewardDescNode","successFontNode",
                "failFontNode","getnum","rewardUpName","rewardDownName","listScroll"}) do window.rootItems[key]=item() end
            window:tenReload()
            assert(window.rootItems.getnum.value==3 and rowHandler("numberOfCells")==3)
            rowHandler("cellAtIndex",{},0,nil)
        ''')

    def test_battle_seventh_target_uses_existing_timing_and_updates_hp_and_shield(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("战报转换验证需本机已有 lupa.lua51")
        lua = LuaRuntime()
        lua.execute('''
            print,printT=function() end,function() end
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            CCFileUtils={sharedFileUtils=function(self) return self end,fullPathForFilename=function(self,p) return p end}
            LoadJsonFileToTable=function() return {injured={delay=0,actiondelay=0}} end
            gamedata={config={}}
        ''')
        code = self.client_scripts()["assets/scripts/battleReportConvert.so"]
        lua.globals().make = lua.execute(code + "\nreturn makeDestGeneralEffective")
        lua.execute('''
            for _,explicit in ipairs({false,true}) do
                injuredAudioTimes={}
                local unit={hp=100,hp2=100,cover_d=25,cover_d2=25,animation={name="stub"}}
                local templates={damage={['1']={damagedelay={['1']='0'}}},ccbtype=''}
                if explicit then templates.damage['7']={damagedelay={['1']='0',['2']='0.1'}} end
                local action={pos=14,direct=false,damage={damage=11,damage2=5,status='normal',num=0}}
                local animation=make(action,unit,templates,'7')
                assert(unit.hp==89 and unit.cover_d==20)
                assert(#animation.animation.damage==(explicit and 2 or 1))
            end
        ''')

    def test_welfare_refreshes_queries_keeps_vip_local_callback_and_net_rewards(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("福利回调行为验证需本机已有 lupa.lua51")
        scripts = self.client_scripts()
        lua = LuaRuntime()
        lua.execute('''
            cclog, printT = function() end, function() end
            local function message()
                return {ParseFromString = function(self, data)
                    for k,v in pairs(data) do self[k] = v end
                end}
            end
            package.preload.ids_pb = function() return {Ids=message} end
            package.preload.somethings_pb = function() return {SomeThings=message} end
            package.preload.params_pb = function() return {ParamS=message} end
            package.preload.result_pb = function() return {Result=message} end
            package.preload.combmessages_pb = function() return {CombMessages=message} end
            package.preload.activityquery_pb = function() return {} end
            gamedata = {cache={role={gold=1000}, mammon={1,100}, chicken={2,2,2},
                              continueX1={1,1}, signin2={daynum=1,status=1}, luxurySignInStatus={status=2},
                              vipstatus={vipexchange_free=0}, timegift={}, growplanx1={status={}}}, ext={},
                        config={mammon={['1']={gold=18}}}}
            function gamedata:Mammon(data) for _,v in ipairs(data.ids) do table.insert(self.cache.mammon,v) end end
            function gamedata:SomethingProcess(data)
                self.cache.role.gold=self.cache.role.gold+(data.gold or 0)
                return data.gold and {{num=data.gold}} or {}
            end
            function gamedata:updateRoleGold(delta) self.cache.role.gold=self.cache.role.gold+delta end
            function gamedata:Vipstatus(ids) self.cache.vipstatus.vipexchange_free=ids[25] end
        ''')
        for name in ("GameActivityMammon", "GameEatChicken", "GameActivityReward", "GameSignIn", "GameRecharge",
                     "GameActivityMultipleRebate", "GameActivityQuery"):
            lua.execute(scripts[f"assets/scripts/{name}.so"])
        lua.execute('''
            for _,row in ipairs({{UIActivityMammonQueryCallBack,2015}, {UIActivityEatChickenQueryCallBack,2010},
                                 {UIContinue7QueryCallBack1,214}, {UISignIn2StatusCallBack,3641},
                                 {UILuxurySignInStatusCallBack,3643}, {UIVipStatusCallBack,300}, {UIGrowPlan2CallBack,7091}}) do
                local remote, opcode, body = row[1]({})
                assert(remote==1 and opcode==row[2] and body==nil)
            end
            NetActivityMammonQueryCallBack({rbuf={ids={1,120}}})
            NetActivityMammonQueryCallBack({rbuf={ids={1,60}}})
            assert(#gamedata.cache.mammon==2 and gamedata.cache.mammon[2]==60)
            local result=NetActivityMammonCallBack({rbuf={gold=36}})
            assert(gamedata.cache.role.gold==1036 and result.reward[1].num==54)
            assert(gamedata.cache.mammon[1]==2)
            gamedata.ext.TimeGiftGold=200
            NetTimeGiftRewardCallBack({rbuf={}})
            assert(gamedata.cache.role.gold==836)
            gamedata.ext.isrechare=true
            NetRechargeResultCallBack({rbuf={}})
            assert(gamedata.ext.isrechare==false)
            local remote, opcode, response=UIVipWelfareExtCallBack({})
            assert(remote==0 and opcode==46111 and response.vipstatus==gamedata.cache.vipstatus)
            for _,row in ipairs({{UIMonthGrowQueryCallBack,3680}, {UIMonthGrowWelfareQueryCallBack,3682}}) do
                local remote, opcode = row[1]({})
                assert(remote==1 and opcode==row[2])
            end
            local remote, opcode=UIActivityQueryCallBack({page='5'})
            assert(remote==1 and opcode==2000)
            gamedata.config.build={}
            gamedata.cache.activitystatus={['78']={id=78,status=1}}
            table.copy=function(value) return value end
            local remote, opcode, response=UIActivityQueryCallBack({page='5',ischeck=1})
            assert(remote==0 and opcode==2000 and response.page=='5' and response.ischeck==1)
        ''')
        lua.execute(scripts["assets/scripts/UIRecharge.so"])
        lua.execute('''
            GameScene={vipstatus={},layers={activity={module={pageTable={}}}}}
            gameWindows={windows={buypower={show=false}}}
            requests={}
            UIRequest=function(t) table.insert(requests,t.type) end
            UIVipStatus({vipstatus={vipexchange_free=1}})
            assert(#requests==1 and requests[1]==46111)
            requests={}
            UIRechargefresh()
            local found={}
            for _,opcode in ipairs(requests) do found[opcode]=true end
            assert(found[7091] and found[7094] and found[3643])
            GameScene.layers.activity.module.pageTable={[78]={module={show=true}},[169]={module={show=false}}}
            requests={}
            UIRechargefresh()
            local found={}
            for _,opcode in ipairs(requests) do found[opcode]=true end
            assert(found[5000] and not found[8075] and not found[8077] and not found[8026])
        ''')
        self.assertIn("[57] = { request = 300,", scripts["assets/scripts/Layer_activity.so"])
        self.assertIn("desc_muyou:setVisible(false)", scripts["assets/scripts/Layer_activity_newcontinuous.so"])
        self.assertIn('desc1,"连续登录，可获得 元宝和银币', scripts["assets/scripts/Layer_activity_newcontinuous.so"])
        self.assertNotIn("isdouble", scripts["assets/scripts/Layer_activity_peace.so"])

    def test_month_fund_unactivated_and_expired_views_do_not_offer_invalid_claims(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("月基金页面行为验证需本机已有 lupa.lua51")
        scripts = self.client_scripts()
        lua = LuaRuntime()
        lua.execute('''
            print = function() end
            local noop = function() end
            function widgets()
                return setmetatable({}, {__index=function(items,key)
                    local node = setmetatable({setString=function(self,v) self.text=v end,
                        setTouchEnabled=function(self,v) self.enabled=v end}, {__index=function() return noop end})
                    items[key]=node
                    return node
                end})
            end
            ui = {setLabelString=function(node,text) if text~=nil then node:setString(text) end end,
                  addGray=noop, removeGray=noop, setNewIconName=noop, IDconfig=function() return {name='奖励'} end,
                  getIDandNUM=function() return 20223,1 end}
            tolua = {cast=function(node) return node end}
            ccp, setSpriteFrameByName = noop, noop
            gameConfig = {images={}, checkBuildOpen=function() return false end}
            GameScene = {layers={activity={module={isContentScroll=false}}}}
            gamedata = {config={month_growup={}}, time=function() return now end}
            for i=1,20 do gamedata.config.month_growup[tostring(i)]={reward1='20223,1',reward2='20223,2'} end
        ''')
        lua.globals().fund = lua.execute(scripts["assets/scripts/Layer_activity_multipleRebate.so"])
        lua.globals().welfare = lua.execute(scripts["assets/scripts/Layer_activity_welfareMonth.so"])
        lua.execute('''
            fund.coveritems=widgets()
            fund.show, fund.status = true, 2
            fund.configWelfare={['1']={limit=68,coefficient=10},['2']={limit=198,coefficient=20}}
            fund.rebateTab, fund.endTimeLab = {68,10}, '2026年11月23日0时0分'
            for _,statuses in ipairs({{0,0},{2,0},{0,2},{3,2}}) do
                fund:reloaddata({data={activationBtnStatus1=statuses[1],activationBtnStatus2=statuses[2],
                                      receiveDay1=0,receiveDay2=5}})
                assert(#fund.pageconfig==2)
                for i=1,2 do
                    fund:shiftPage('rebate'..i)
                    assert(fund.coveritems.getButton.enabled==(statuses[i]==2))
                    assert(fund.coveritems.day.text==(i==1 and 0 or 5))
                    assert(fund.coveritems.getLab.text==(statuses[i]==0 and '未激活' or '领取'))
                end
            end
            welfare.coveritems, welfare.endAt = widgets(), 100
            now=200
            welfare:reloaddata({data={btnStatus1=0,btnStatus2=1}})
            for i=1,2 do
                assert(welfare.coveritems['doButton'..i].enabled==false)
                assert(welfare.coveritems['doLab'..i].text=='已结束')
            end
            now=50
            welfare:reloaddata({data={btnStatus1=0,btnStatus2=1}})
            assert(welfare.coveritems.doButton1.enabled and welfare.coveritems.doButton2.enabled)
            assert(welfare.coveritems.doLab1.text=='去充值' and welfare.coveritems.doLab2.text=='领 取')
        ''')

    def test_shop_refreshes_limits_and_client_deducts_purchase_cost_once(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("商城回调行为验证需本机已有 lupa.lua51")
        scripts = self.client_scripts()
        lua = LuaRuntime()
        lua.execute('''
            cclog = function() end
            local function message()
                return {ParseFromString = function(self, data)
                    for k,v in pairs(data) do self[k] = v end
                end}
            end
            package.preload.ids_pb = function() return {Ids = message} end
            package.preload.idnums_pb = function() return {} end
            package.preload.shopquery_pb = function() return {ShopQuery = message} end
            package.preload.somethings_pb = function() return {SomeThings = message} end
            package.preload.result_pb = function() return {Result = message} end
            gamedata = {cache = {shop = {props = {[1]=9}, giftbags = {[20101]={cid=20101}}}, role = {gold=5000}},
                        config = {gift_bag = {['20101']={id=20101,discount=8}}}, ext = {}, awarded = 0}
            function gamedata:ShopProps(data) for k,v in ipairs(data) do self.cache.shop.props[k]=v end end
            function gamedata:GiftBags(data) for _,v in ipairs(data) do self.cache.shop.giftbags[v.cid]=v end end
            function gamedata:SomethingProcess(data) self.awarded=self.awarded+1 return data end
            function gamedata:updateRoleGold(delta) self.cache.role.gold=self.cache.role.gold+delta end
            function gamedata:updateprops(data) self.prop=data end
        ''')
        lua.execute(scripts["assets/scripts/GameShop.so"])
        lua.execute('''
            local network, opcode = UIshopQueryCallback({type=3200})
            assert(network==1 and opcode==3200)
            network, opcode = UIGiftBagQueryCallback({type=3210})
            assert(network==1 and opcode==3210)
            NetshopQueryCallback({rbuf={ids={0,0}}})
            assert(gamedata.cache.shop.props[1]==0)
            NetGiftBagQueryCallback({rbuf={items={}}})
            assert(next(gamedata.cache.shop.giftbags)==nil)
            gamedata.ext.shopbuy={id=1,num=2,gold=2400}
            NetShopBuyCallback({rbuf={}})
            assert(gamedata.cache.role.gold==2600 and gamedata.cache.shop.props[1]==2)
            gamedata.cache.shop.giftbags[20101]={cid=20101}
            gamedata.ext.shopbuy={id=20101,num=1}
            NetGiftBagBuyCallback({rbuf={result=true}})
            assert(gamedata.cache.role.gold==2592 and gamedata.prop.num==1)
            assert(gamedata.cache.shop.giftbags[20101]==nil)
            gamedata.ext.weekgiftgold=100
            NetVipWeekGiftRewardCallback({rbuf={}})
            assert(gamedata.cache.role.gold==2492 and gamedata.awarded==2)
        ''')

    def test_activity_touch_does_not_query_adjacent_pages(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("活动页面行为验证需本机已有 lupa.lua51")
        source = self.client_scripts()["assets/scripts/Layer_activity.so"]
        source = source[source.index("function activity.createOnePage("):source.index("function activity.setPageByid(")]
        lua = LuaRuntime()
        lua.execute('''
            print = function() end
            activity, requests, initialized = {}, {}, {}
            function UIRequest(t) table.insert(requests,t.type) end
            function ccp(x,y) return {x=x,y=y} end
            function page(id,request)
                local node = {setPosition=function() end,setVisible=function() end}
                return {id=id,request=request,module={init=function()
                    table.insert(initialized,id); return node end}}
            end
        ''')
        lua.execute(source)
        lua.execute('''
            local view = setmetatable({presentPage=2,createsPage={},contentCellSize={x=480},
                realPageTable={page(19,3641),page(173,4890),page(59,4615)},
                rootItems={container={addChild=function() end}}}, {__index=activity})
            view:createPages()
            view:createPagesExt()
            view:createPagesExt()
            assert(#requests==1 and requests[1]==4890 and #initialized==1)
            view.presentPage=3
            view:createPages()
            assert(#requests==2 and requests[2]==4615 and initialized[2]==59)
            view.presentPage=2
            view:createPages()
            assert(#requests==2)
        ''')

    def test_local_login_success_failure_timeout_and_switch_with_lua51(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("Lua5.1 行为验证需本机已有 lupa.lua51；构建/打包回归不依赖它")
        scripts = self.client_scripts()
        lua = LuaRuntime()
        lua.globals().scene_source = scripts["assets/scripts/accbyhttp/LoginScene.so"]
        lua.execute('''
            function noop() end
            print, printT, cclog, ccc3 = noop, noop, noop, noop
            gameConfig = {strings={}}
            local values = {}
            defaults = {
                getIntegerForKey=function(self,k,d) return values[k] or d end,
                getStringForKey=function(self,k,d) return values[k] or d end,
                getBoolForKey=function(self,k,d) if values[k]==nil then return d end; return values[k] end,
                setIntegerForKey=function(self,k,v) values[k]=v end,
                setStringForKey=function(self,k,v) values[k]=v end,
                setBoolForKey=function(self,k,v) values[k]=v end,
                flush=noop,
            }
            CCUserDefault = {sharedUserDefault=function() return defaults end}
            function node()
                local n = {text='', handlers={}}
                function n:setText(v) self.text=v end
                function n:getText() return self.text end
                function n:setInputFlag(v) self.flag=v end
                function n:registerScriptEditBoxHandler(v) self.editHandler=v end
                function n:addHandleOfControlEvent(v) table.insert(self.handlers,v) end
                return setmetatable(n,{__index=function() return noop end})
            end
            ui = {setLabelString=noop, removeInputEditBox=noop, creatInputEditBoxBylable=function()
                local n=node(); n.editHandler=function() error('password logged') end; return n end}
            CCSequence = {createWithTwoActions=function(self,delay,callback) return {delay=delay,callback=callback} end}
            CCDelayTime = {create=function(self,delay) return delay end}
            CCCallFunc = {create=function(self,callback) return callback end}
            function UIRequest(t) table.insert(requests,t) end
            function runGamePrompt(t) table.insert(prompts,t.msg) end
            loading = {exitGame=function(self,msg,restart) assert(restart); failures=failures+1 end}
            package.loaded.device = {channel='', platform='android'}
            package.loaded.SDKfunction = {isValid=function() return false end}
            package.loaded.logError = {}
            function boot()
                gamedata = {device={SCREEN_WIDTH=1080,SCREEN_HEIGHT=1920},serverlist={['1']={id=1,ip='192.168.1.20'}}}
                requests, prompts, actions, failures, logins = {}, {}, {}, 0, 0
                LoginScene = assert(loadstring(scene_source))()
                LoginScene.SelectedServer = {id=defaults:getIntegerForKey('local_account',1)}
                LoginScene.enterLayerItem=setmetatable({}, {__index=function(t,k) local n=node();rawset(t,k,n);return n end})
                LoginScene.rootLayer={runAction=function(self,action) table.insert(actions,action) end}
                LoginScene.loginGame=function() logins=logins+1 end
                LoginScene.showEnter=noop
            end
        ''')
        lua.execute(scripts["assets/scripts/UILogin.so"])
        lua.execute(scripts["assets/scripts/UIErrorMessage.so"])
        lua.execute(scripts["assets/scripts/UIPrompt.so"])
        lua.execute('''
            sendNetError=noop
            boot()
            LoginScene:offerLocalLogin()
            assert(logins==0 and LoginScene.passwordInputBox.flag==0)
            LoginScene.accountInputBox:setText('1000')
            LoginScene.passwordInputBox:setText('Simple-123')
            LoginScene.passwordInputBox.editHandler('ended',LoginScene.passwordInputBox)
            LoginScene.enterLayerItem.userconfirm.handlers[1]()
            assert(logins==1 and gamedata.local_account==1000 and gamedata.local_password=='Simple-123')
            assert(defaults:getStringForKey('local_password','')=='', 'saved before authentication')
            judgeSelectedServerIDValid({location=0})
            assert(defaults:getIntegerForKey('local_account',1)==1000)
            assert(defaults:getStringForKey('local_password','')=='Simple-123')
            assert(defaults:getBoolForKey('local_auto_login',false))
            actions[1].callback()
            assert(failures==0, 'successful login timed out')

            boot()
            LoginScene:offerLocalLogin()
            LoginScene:offerLocalLogin()
            assert(#actions==1 and actions[1].delay==2)
            actions[1].callback()
            assert(logins==1 and gamedata.local_account==1000 and gamedata.local_password=='Simple-123')
            assert(not defaults:getBoolForKey('local_auto_login',true))
            UIPromptTimeOut()
            assert(failures==1 and requests[1].type==777777)
            assert(defaults:getStringForKey('local_password','')=='Simple-123')
            judgeSelectedServerIDValid({location=0})
            assert(not defaults:getBoolForKey('local_auto_login',true), 'late success reenabled auto-login')
            actions[2].callback()
            assert(failures==1)
            boot()
            LoginScene:offerLocalLogin()
            assert(logins==0 and #actions==0 and LoginScene.passwordInputBox:getText()=='Simple-123')
            LoginScene.enterLayerItem.userconfirm.handlers[1]()
            judgeSelectedServerIDValid({location=0})

            boot()
            LoginScene:offerLocalLogin()
            LoginScene:showUserInput(11)
            actions[1].callback()
            assert(logins==0, 'switch account did not cancel automatic login')
            LoginScene.accountInputBox:setText('2')
            LoginScene.passwordInputBox:setText('Wrong-123')
            LoginScene.enterLayerItem.userconfirm.handlers[1]()
            UIErrorMessage7({local_login_failed=true,msg='rejected'})
            assert(failures==1 and not defaults:getBoolForKey('local_auto_login',true))
            assert(defaults:getStringForKey('local_password','')=='')
            assert(defaults:getIntegerForKey('local_account',1)==1000, 'rejected account replaced last success')
            boot()
            LoginScene:offerLocalLogin()
            assert(logins==0 and #actions==0 and LoginScene.passwordInputBox:getText()=='')
            LoginScene.accountInputBox:setText('2')
            LoginScene.passwordInputBox:setText('Simple-456')
            LoginScene.enterLayerItem.userconfirm.handlers[1]()
            judgeSelectedServerIDValid({location=0})
            assert(defaults:getIntegerForKey('local_account',1)==2)
            assert(defaults:getStringForKey('local_password','')=='Simple-456')

            boot()
            LoginScene:offerLocalLogin()
            actions[1].callback()
            actions[2].callback()
            assert(failures==1 and not defaults:getBoolForKey('local_auto_login',true))
            assert(defaults:getStringForKey('local_password','')=='Simple-456')
        ''')

    def test_login_network_rejection_and_queued_cancel_stop_reconnecting(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("网络循环行为验证需本机已有 lupa.lua51")
        scripts = self.client_scripts()
        loop = scripts["assets/scripts/gameloop2.so"]
        server = scripts["assets/scripts/gameserver.so"]
        server = server[server.index("function ProcessFromGameServer()"):server.index("local t1 = socket.gettime()")]
        for case in ("rejected", "cancel-during-disconnect", "unreachable", "reconnect"):
            with self.subTest(case=case):
                lua = LuaRuntime()
                lua.globals().case = case
                lua.execute('''
                    function noop() end
                    print, cclog, cctrace = noop, noop, noop
                    queue, replies, connects, sends, reads, closes = {}, {}, 0, 0, 0, 0
                    uiqueue = {
                        getrequestfromui=function() return table.remove(queue,1) end,
                        pushrequesttoclient=function(t) table.insert(queue,t) end,
                        setresponsetoui=function(t) table.insert(replies,t) end,
                        autorelease=noop,
                    }
                    package.loaded.uiqueue, package.loaded.network = uiqueue, {}
                    package.loaded.error_pb, package.loaded.ids_pb, package.loaded.params_pb = {}, {}, {}
                    package.loaded.logError = {}
                    function initPb() return {ids={1000,0}} end
                    function UIReqeustClear() queue={} end
                    UIRequest_ = uiqueue.pushrequesttoclient
                    function checkNetSatus() return true end
                    function MakeSer() return 1 end
                    function PackHeader() return '' end
                    function UnPackHeader() return 1,case=='reconnect' and 1000 or 999999,1 end
                    socket = {sleep=function() assert(connects<=2,'kept reconnecting') end}
                    local sock = {close=function() closes=closes+1 end}
                    fd = {sock={close=noop}}
                    function ConnectToServer()
                        connects=connects+1
                        assert(connects<=2,'kept reconnecting')
                        if case=='unreachable' then return nil end
                        return {sock=sock}
                    end
                    function TCPSelect1conn(fd)
                        reads=reads+1
                        if case=='cancel-during-disconnect' then
                            queue={{type=1001},{type=777777}}
                            return nil
                        end
                        if case=='reconnect' then
                            if reads==3 then queue={{type=1001}}; return nil end
                            if reads==5 then queue={{type=777777}} end
                        elseif reads>2 then return nil end
                        fd.wbuf=nil; fd.rlen=0; fd.rbuf='response'
                        return true
                    end
                    gamedata={serverlist={[1]={ip='192.168.1.20',port=14600}},selectserver=1}
                    game_ui_callback = {
                        [1000]=function() sends=sends+1; return 1,1000,'login' end,
                        [777777]=function() return 777777 end,
                    }
                    game_net_ext_callback = {}
                    queue={{type=case=='unreachable' and 777777 or 1000}}
                ''')
                lua.execute(scripts["assets/common_lua/GameErrorMessage.so"])
                lua.execute("game_net_callback = {[999999]=NetErrorMessageCallback9, [1000]=function() return {type=1000,location=0} end}")
                lua.execute(loop)
                lua.execute(server)
                lua.execute('''
                    assert(ProcessFromGameServer()==777777)
                    assert(sends==(case=='unreachable' and 0 or case=='reconnect' and 2 or 1))
                    if case=='rejected' then
                        assert(connects==1 and #replies==1 and replies[1].local_login_failed)
                        assert(closes==1)
                    elseif case=='reconnect' then
                        assert(connects==2 and #replies==2)
                    end
                ''')

    def test_find_tool_supports_native_and_windows_sdk_names(self):
        for name, filename in (("zipalign", "zipalign"), ("zipalign", "zipalign.exe"),
                               ("apksigner", "apksigner"), ("apksigner", "apksigner.bat")):
            with self.subTest(filename=filename), tempfile.TemporaryDirectory() as directory:
                path = Path(directory) / "build-tools" / "35.0.0" / filename
                path.parent.mkdir(parents=True)
                path.touch()
                with patch.object(builder.shutil, "which", return_value=None), patch.dict(os.environ, {"ANDROID_HOME": directory}):
                    self.assertEqual(builder.find_tool(name), str(path))

    def test_find_tool_prefers_path(self):
        with patch.object(builder.shutil, "which", return_value="/sdk/bin/zipalign"):
            self.assertEqual(builder.find_tool("zipalign"), "/sdk/bin/zipalign")

    def test_apk_and_server_use_same_overrides_in_both_config_sections(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config_path = root / "configs_sec5.zip"
            shutil.copyfile(Path(__file__).parent / "configs_sec5.zip", config_path)
            configs = configuration.ConfigStore(config_path)
            configs.update("props", "20014", {"param1": "37"}, configs.status()["revision"])
            with zipfile.ZipFile(root / "z7_7_4.apk", "w") as archive:
                archive.writestr("assets/GameServer.json", '{"1":{"id":1}}')
                for section in (1, 5):
                    archive.writestr(f"assets/config/{section}/props.json", "old config")
                    archive.writestr(f"assets/config/{section}/client_only.json", "{}")

            def tool(name, args):
                if name == "zipalign":
                    shutil.copyfile(args[-2], args[-1])

            with patch.object(builder, "__file__", str(root / "build_local_apk.py")), \
                    patch.object(builder, "get_patched_lua_scripts", return_value={}), \
                    patch.object(builder, "find_tool", side_effect=lambda name: name), \
                    patch.object(builder, "run_tool", side_effect=tool), \
                    patch.object(builder.subprocess, "run"), contextlib.redirect_stdout(io.StringIO()):
                builder.main(["--server-ip", "192.168.1.20", "--accounts", "2"])
            runtime = player.load_role_config(config_path)
            with zipfile.ZipFile(root / "zyj_local.apk") as archive:
                for section in (1, 5):
                    name = f"assets/config/{section}/props.json"
                    self.assertEqual(archive.namelist().count(name), 1)
                    self.assertEqual(json.loads(archive.read(name)), runtime["props"])
                    for table in ("continue7_X1", "activity_time"):
                        data = json.loads(archive.read(f"assets/config/{section}/{table}.json"))
                        self.assertEqual(data, runtime[table])
                    self.assertTrue(all("1026," not in r["reward"] for r in runtime["continue7_X1"].values()))
                    self.assertEqual(archive.read(f"assets/config/{section}/client_only.json"), b"{}")
                    with zipfile.ZipFile(config_path) as source:
                        with contextlib.redirect_stdout(io.StringIO()):
                            guide_config = builder.patch_guide_step(source.read("5/guide_step.json"))
                        self.assertEqual(archive.read(f"assets/config/{section}/guide_step.json"), guide_config)
                self.assertEqual(list(json.loads(archive.read("assets/GameServer.json"))), ["1", "2"])
                self.assertEqual(archive.read("assets/LocalGameServer.json"), archive.read("assets/GameServer.json"))
                self.assertEqual(archive.namelist().count("assets/LocalGameServer.json"), 1)


if __name__ == "__main__":
    unittest.main()
