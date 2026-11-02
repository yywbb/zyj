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
            relative = "UISingleBoss" if relative == "UIsingleBoss" else relative
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

    def test_guild_incense_queries_live_and_midnight_restores_buttons(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("公会上香回调验证需本机已有 lupa.lua51")
        scripts = self.client_scripts()
        code = scripts["assets/scripts/GameGang.so"]
        start = code.index("function UIUserGang2PrayQueryCallBack(uireq)")
        end = code.index("function NetUserGang2PrayQueryCallBack(fd)", start)
        lua = LuaRuntime()
        lua.execute('gamedata={cache={gang2pray=3}}; cclog=function() end')
        lua.execute(code[start:end])
        self.assertEqual(lua.globals().UIUserGang2PrayQueryCallBack(lua.table()), (1, 2250, None))
        self.assertIn("gamedata.cache.gang2status.totalcontribution+ids.ids[1]", code)
        lua.execute('''
            print=function() end
            ui={addGray=function(_,button) button.gray=true end,removeGray=function(_,button) button.gray=false end,
                setLabelString=function(label,text) label.text=text end}
            gameConfig={strings={string_common=function() return "已贡献" end}}
        ''')
        layer = lua.execute(scripts["assets/scripts/Layer_guild2_shangxiang.so"])
        lua.globals().layer = layer
        lua.execute('''
            layer.rootItems={}; layer.prayTitles={}
            for _,name in ipairs({"first","second","third"}) do
                layer.rootItems[name.."Btn"]={}; layer.rootItems[name.."Text"]={}
                layer.prayTitles[name]="贡献"
            end
            layer:reloaddata({status=2})
            assert(layer.rootItems.secondBtn.gray and layer.rootItems.secondText.text=="已贡献")
            layer:reloaddata({status=0})
            for _,name in ipairs({"first","second","third"}) do
                assert(not layer.rootItems[name.."Btn"].gray)
                assert(layer.rootItems[name.."Text"].text=="贡献")
            end
        ''')

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

    def test_multicombo_missing_visuals_use_explicit_aliases_without_changing_ids(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("合体显示兼容验证需本机已有 lupa.lua51")
        with zipfile.ZipFile(Path(__file__).parent / "configs_sec5.zip") as archive:
            config = {name: json.loads(archive.read(f"5/{name}.json"))
                      for name in ("general", "skill", "combskill", "skillanimation", "generalanimation")}
        lua = LuaRuntime()
        lua.globals().gamedata = lua.table_from({"config": config}, recursive=True)
        lua.execute('''print=function() end;printT=print
            CCFileUtils={sharedFileUtils=function(self) return self end,isFileExist=function() return originalPresent end}
        ''')
        code = self.client_scripts()["assets/scripts/battleReportConvert.so"]
        skill_animation, general_animation = lua.execute(code + "\nreturn localBattleSkillAnimation, localBattleGeneralAnimation")
        for present in (False, True):
            lua.globals().originalPresent = present
            for sid, alias in ((13124, 12989), (13125, 12638), (12281, 12517), (12282, 12523), (12283, 12511), (12284, 12415)):
                with self.subTest(skill=sid, original=present):
                    table = "combskill" if sid in (13124, 13125) else "skill"
                    row = lua.globals().gamedata.config[table][str(sid)]
                    result = skill_animation(row)
                    self.assertEqual(result.id, config[table][str(sid if present else alias)]["animationid"])
                    self.assertEqual(row.id, sid)
            for cid, alias in ((10853, 10517), (10854, 10524), (10855, 10511), (10856, 10415)):
                with self.subTest(cid=cid, original=present):
                    info = lua.table_from({"cid": cid})
                    result = general_animation(info)
                    self.assertEqual(result.id, int(config["general"][str(cid if present else alias)]["animationid"]))
                    self.assertEqual(info.cid, cid)
        ordinary = lua.globals().gamedata.config.combskill['12990']
        self.assertEqual(skill_animation(ordinary).id, ordinary.animationid)

    def test_pet_rest_control_is_packaged_and_empty_active_tabs_are_safe(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("魔宠按钮验证需本机已有 lupa.lua51")
        scripts = self.client_scripts()
        lua = LuaRuntime()
        lua.execute('print=function() end;printT=print')
        selection = scripts["assets/scripts/window_devourSelect.so"]
        self.assertIn('battleString = "休息"', selection)
        start = selection.index('            ccbDocumentControler.battleBtn:addHandleOfControlEvent(function()')
        end = selection.index('end, CCControlEventTouchUpInside)', start) + len('end, CCControlEventTouchUpInside)')
        lua.execute('''CCControlEventTouchUpInside=1
            ccbDocumentControler={battleBtn={addHandleOfControlEvent=function(self,f) self.click=f end}}
            gameWindows={closeWindow=function() closed=true end}
            UIRequest=function(t) request=t end
            celldata={iid=5000001};self={data={iid=5000001}}''')
        lua.execute(selection[start:end])
        lua.execute('ccbDocumentControler.battleBtn.click();assert(closed and request.type==1043 and request.iid==0)')
        lua.execute('self.data.iid=0;request=nil;closed=false')
        lua.execute('ccbDocumentControler.battleBtn.click();assert(closed and request.type==1043 and request.iid==5000001)')
        lead = scripts["assets/scripts/Layer_mochonglead.so"]
        start = lead.index('function mochonglead.shiftPage(self, page)')
        end = lead.index('    print("mochonglead.shiftPage"', start)
        lua.execute('mochonglead={};runGamePrompt=function(t) prompt=t.msg end\n' + lead[start:end] + '\nend')
        lua.execute('''for _,page in ipairs({'shengji','jinjie'}) do
            prompt=nil
            mochonglead.shiftPage({selectpage=page,allPetsData={iid=0},PromptString={notmochong='resting'}},page)
            assert(prompt=='resting')
        end''')

    def test_campaign_sweep_uses_settled_attempts_not_stale_client_stamina(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("扫荡回调验证需本机已有 lupa.lua51")
        lua = LuaRuntime()
        lua.execute('''
            print,cclog,printT=function() end,function() end,function() end
            for _,name in ipairs({'copies_pb','copyattack_pb','copyall3starreward_pb','result_pb','ids_pb','somethings_pb','PickBattleResultReport'}) do
                package.preload[name]=function() return {} end
            end
            package.preload.battleresult_pb=function()
                return {BattleResult=function() return {ParseFromString=function(self,data)
                    for key,value in pairs(data) do self[key]=value end
                end} end}
            end
            table.copy=function(t)
                local result={} for k,v in pairs(t) do result[k]=type(v)=='table' and table.copy(v) or v end return result
            end
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            gamedata={cache={role={stamina=100},slots={},copy={[42102]={id=42102,pa1=3,pa2=3,pa3=3,
                      points={[1]={id=1,star=3,kill=1,move=0}}}}},ext={},
                      config={copy={['42102']={['1']={physical=4,challenge=10,xp=300,coin=100}}},
                              map={['42102']={section=40001,star1=3,star2=3,star3=3}},section={['40001']={name='test'}}}}
            function gamedata.config:getConfigByName(name) return self[name] end
            function gamedata:SomethingProcess() return {} end
            function gamedata:updateRoleExp() return {oldlevel=12,newlevel=12} end
            function gamedata:Encounters() return {} end
            function gamedata:updateRoleStamina(value) self.cache.role.stamina=self.cache.role.stamina+value end
            function gamedata:Generals() end
            function gamedata:GeneralsEXP(value) return value end
        ''')
        scripts = self.client_scripts()
        code = scripts.get("assets/scripts/GameCopy.so")
        if code is None:
            code = (Path(__file__).parent / "scripts_clean/GameCopy.lua").read_text(encoding="utf-8")
        lua.execute(code)
        lua.execute('''
            for _,row in ipairs({{0,1},{1,3}}) do
                local method,attempts=row[1],row[2]
                gamedata.ext.copyattackwipe={map=42102,point=1,method=method,exchange=0}
                gamedata.cache.role.stamina=100
                gamedata.cache.copy[42102].points[1].kill=1
                local result=NetCopyWipe2Callback({rbuf={result=1,star=3,reward={},generals={},encounters={},
                    exp={generals={{id=1,exp=300*attempts,levelup=false}}}}})
                assert(gamedata.cache.copy[42102].points[1].kill==1+attempts)
                assert(gamedata.cache.role.stamina==100-4*attempts and result.coin==100*attempts)
            end
        ''')

    def test_auto_copy_is_opt_in_sequential_and_stops_safely(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("自动推图回调验证需本机已有 lupa.lua51")
        scripts = self.client_scripts()
        layer = scripts["assets/scripts/Layer_copy_list.so"]
        self.assertIn("AutoCopyAttach(self,toppos)", layer)
        self.assertIn("AutoCopyDetach(self)", layer)
        self.assertIn("AutoCopyBlockManual()", layer)
        self.assertIn('[1306] = 1', scripts["assets/scripts/gameloop2.so"])
        self.assertIn('os.time() > timeinteval[uireq["type"]]+2', scripts["assets/scripts/gameloop2.so"])
        lua = LuaRuntime()
        lua.execute('''
            print,printT,cclog=function() end,function() end,function() end
            package.preload.BattleReportAbbToKey=function() return {} end
            events={}; requests={}; notices={}; confirmed=nil
            wallClock=1000;os.time=function() return math.floor(wallClock) end
            local function event(kind,value) table.insert(events,{kind=kind,value=value}) end
            UIRequest=function(req) table.insert(requests,req) end
            runGamePrompt=function(t) table.insert(notices,t.msg) end
            RunbattleCallBack=function(kind,t,cb) event('battle',t.result) end
            updateDataLife=function(reward) event('rewards',reward) end
            setTriggerGiftEnable=function() end
            guide={controller={isOnGuide=false}}
            gamedata={config={copy={
                ['42101']={['1']={physical=5,challenge=3},['2']={physical=5,challenge=3}},
                ['42102']={['1']={physical=6,challenge=3}}}}}
            local function root() return {children={},addChild=function(self,child) table.insert(self.children,child) end} end
            local function scheduler()
                return {stopAllActions=function(self) self.action=nil end,
                    runAction=function(self,action) self.action=action end,
                    fire=function(self,seconds)
                        local action=self.action;self.action=nil
                        if action then wallClock=wallClock+(seconds or math.ceil(action.delay)+1);action.callback() end
                    end}
            end
            CCNode={create=function() return scheduler() end}
            CCDelayTime={create=function(_,delay) return delay end}
            CCCallFunc={create=function(_,callback) return callback end}
            CCSequence={createWithTwoActions=function(_,delay,callback) return {delay=delay,callback=callback} end}
            CCControlStateNormal=0; CCControlStateHighlighted=1; CCControlStateDisabled=2; CCControlEventTouchUpInside=1
            CCString={create=function(_,text) return {value=text} end}
            CCSizeMake=function(w,h) return {width=w,height=h} end
            ccp=function(x,y) return {x=x,y=y} end
            CCControlButton={create=function()
                return {setPreferredSize=function(self,size) self.size=size end,setAnchorPoint=function() end,
                    setPosition=function(self,position) self.position=position end,
                    setTouchPriority=function() end,setSwallowsTouch=function() end,
                    setBackgroundSpriteFrameForState=function(_,frame) assert(frame=='button-frame') end,
                    setTitleForState=function(self,title,state)
                        assert(type(title)=='string','native button title must be a Lua string')
                        self.titles=self.titles or {};self.titles[state]=title;self.title=title
                    end,
                    addHandleOfControlEvent=function(self,callback) self.callback=callback end}
            end}
            local frames={}
            CCSpriteFrameCache={sharedSpriteFrameCache=function() return {
                spriteFrameByName=function(_,name) return frames[name] end,
                addSpriteFrame=function(_,frame,name) frames[name]=frame end} end}
            CCSprite={create=function(_,path)
                if path=='public/publicsprite/b_n_button5.png' then return {displayFrame=function() return 'button-frame' end} end
            end}
            ui={createLabel=function(args) return {x=args.x,y=args.y,setString=function(self,value) self.value=value end} end}
            gameWindows={windows={},openWindow=function(self,name,args,cb) confirmed=cb end}
            gameConfig={originSize={width=1080}}
            GameScene={presentLayer='copy_map',roleinfo={stamina=20},layers={
                copy_map={show=true,module={}},copy_chapter={show=false,module={}}},
                addUpdate=function() end,checkopenlevelbyId=function() return false end}
            function makeLayer()
                local layer={datatype='normal',rootNode=root(),data={id=42101,
                    points={['1']={id=1,star=0,kill=0}}}}
                function layer:reloadnormalData(copy,param) self.lastParam=param end
                GameScene.layers.copy_map.module=layer
                return layer
            end
            function dataFor(map,point,nextmap,nextpoint)
                return {result=1,map=map,point=point,localAutoCopy=1,localAutoStamina=10,
                    exp={oldlevel=16,newlevel=16},reward={},copy={['1']={maps={
                        [tostring(nextmap-42100)]={id=nextmap,points={[tostring(nextpoint)]={id=nextpoint,star=0,kill=0}}}}}}}
            end
        ''')
        lua.execute((Path(__file__).parent / "scripts_clean/setSpriteFrame.lua").read_text())
        lua.execute(scripts["assets/scripts/UICopy.so"])
        lua.execute('''
            layer=makeLayer();AutoCopyAttach(layer,1500)
            assert(layer.autoCopyButton.title=='自动推图' and #requests==0)
            assert(layer.autoCopyButton.position.x+layer.autoCopyButton.size.width/2<gameConfig.originSize.width-250)
            assert(layer.autoCopyLabel.y>layer.autoCopyButton.position.y)
            for _,state in ipairs({CCControlStateNormal,CCControlStateHighlighted,CCControlStateDisabled}) do
                assert(layer.autoCopyButton.titles[state]=='自动推图')
            end
            layer.autoCopyButton.callback();assert(confirmed and #requests==0)
            confirmed();assert(layer.autoCopyTimer.action.delay>=3);layer.autoCopyTimer:fire()
            assert(#requests==1 and requests[1].type==1306 and requests[1].map==42101 and requests[1].point==1)
            assert(requests[1].local_auto_copy and layer.autoCopyButton.title=='停止推图')
            for _,state in ipairs({CCControlStateNormal,CCControlStateHighlighted,CCControlStateDisabled}) do
                assert(layer.autoCopyButton.titles[state]=='停止推图')
            end
            assert(AutoCopyBlockManual())
            UICopyAttack2(dataFor(42101,1,42101,2))
            assert(#requests==2 and requests[2].type==1001)
            assert(layer.lastParam.section==1 and layer.lastParam.map==1 and layer.lastParam.point==2)
            assert(layer.autoCopyTimer.action.delay>=3)
            layer.autoCopyTimer:fire()
            assert(#requests==3 and requests[3].point==2)
            UICopyAttack2(dataFor(42101,2,42102,1))
            layer.autoCopyTimer:fire()
            assert(requests[#requests].map==42102 and requests[#requests].point==1)
            assert(layer.lastParam.section==1 and layer.lastParam.map==2 and layer.lastParam.point==1)
            local lost=dataFor(42102,1,42102,1);lost.result=0
            UICopyAttack2(lost)
            assert(not AutoCopyIsRunning() and layer.autoCopyButton.title=='自动推图')
            assert(events[#events].kind=='battle' and events[#events].value==0)
            local count=#requests;layer.autoCopyTimer:fire();assert(#requests==count)
        ''')
        lua.execute('''
            layer=makeLayer();AutoCopyAttach(layer,1500);layer.autoCopyButton.callback();confirmed();layer.autoCopyTimer:fire()
            local before=#requests
            layer.autoCopyButton.callback();assert(not AutoCopyIsRunning())
            layer.autoCopyButton.callback();assert(#requests==before)
            UICopyAttack2(dataFor(42101,1,42101,2))
            assert(#requests>=before and events[#events].kind=='battle')
            layer.autoCopyButton.callback();confirmed();layer.autoCopyTimer:fire()
            local changed=dataFor(42101,1,42101,2);changed.exp.newlevel=17
            UICopyAttack2(changed);assert(not AutoCopyIsRunning() and events[#events].kind=='battle')
        ''')
        lua.execute('''
            layer=makeLayer();AutoCopyAttach(layer,1500);layer.autoCopyButton.callback();confirmed();layer.autoCopyTimer:fire()
            local low=dataFor(42101,1,42101,2);low.localAutoStamina=4
            UICopyAttack2(low);local count=#requests;layer.autoCopyTimer:fire()
            assert(not AutoCopyIsRunning() and #requests==count and notices[#notices]:find('体力'))
            layer=makeLayer();AutoCopyAttach(layer,1500);layer.autoCopyButton.callback();confirmed()
            guide.controller.isOnGuide=true;count=#requests;layer.autoCopyTimer:fire()
            assert(not AutoCopyIsRunning() and #requests==count and notices[#notices]:find('引导'))
            guide.controller.isOnGuide=false
            layer.autoCopyButton.callback();confirmed();gameWindows.windows.interrupt={show=true};layer.autoCopyTimer:fire()
            assert(not AutoCopyIsRunning() and #requests==count and notices[#notices]:find('弹窗'))
            gameWindows.windows.interrupt.show=false
        ''')
        lua.execute('''
            layer=makeLayer();GameScene.roleinfo.stamina=4;AutoCopyAttach(layer,1500)
            layer.autoCopyButton.callback();confirmed();layer.autoCopyTimer:fire()
            assert(not AutoCopyIsRunning() and notices[#notices]:find('体力'))
            GameScene.roleinfo.stamina=20;guide.controller.isOnGuide=true
            layer.autoCopyButton.callback();assert(not AutoCopyIsRunning() and notices[#notices]:find('引导'))
            guide.controller.isOnGuide=false
            layer.autoCopyButton.callback();confirmed();layer.autoCopyTimer:fire()
        ''')
        lua.execute('package.preload.logError=function() return {errorMessage={},errorFunc={}} end')
        lua.execute(scripts["assets/scripts/UIPrompt.so"])
        lua.execute('''
            local previous=confirmed
            UIPrompt({msgtype='shortphysical',localAutoCopy=1})
            assert(not AutoCopyIsRunning() and not AutoCopyBlockManual())
            assert(confirmed==previous and notices[#notices]:find('体力'))
            layer.autoCopyButton.callback();confirmed();layer.autoCopyTimer:fire()
            layer.autoCopyButton.callback();assert(not AutoCopyIsRunning() and AutoCopyBlockManual())
            assert(not AutoCopyLocalReject({msgtype='shortphysical'}))
            assert(AutoCopyBlockManual())
            UIPrompt({msgtype='shortphysical',localAutoCopy=1})
            assert(not AutoCopyBlockManual())
            layer.autoCopyButton.callback();confirmed();layer.autoCopyTimer:fire()
            function gameConfig:checkBuildOpen() return true end
            function gameWindows:closeAllWindowDirect() end
            function GameScene:UpdatePresentLayer() end
        ''')
        lua.execute(scripts["assets/scripts/UIErrorMessage.so"])
        lua.execute('''
            UIErrorMessage({errornum=0,request_opcode=1306})
            assert(not AutoCopyIsRunning() and not AutoCopyBlockManual())
            layer.autoCopyButton.callback();confirmed();layer.autoCopyTimer:fire()
            local count=#requests
            assert(layer.autoCopyTimer.action.delay==20);layer.autoCopyTimer:fire()
            assert(not AutoCopyIsRunning() and AutoCopyBlockManual() and #requests==count)
            layer.autoCopyButton.callback();assert(#requests==count)
            UICopyAttack2(dataFor(42101,1,42101,2))
            assert(not AutoCopyBlockManual() and events[#events].kind=='battle')
            for _,req in ipairs(requests) do assert(req.type==1306 or req.type==1001) end
            layer.autoCopyButton.callback();confirmed();layer.autoCopyTimer:fire()
            AutoCopyDetach(layer);assert(not AutoCopyIsRunning())
        ''')
        network = LuaRuntime()
        network.execute('''print,cclog,cctrace=function() end,function() end,function() end
            package.preload.network=function() return {} end
            package.preload.uiqueue=function() return {
                getrequestfromui=function() local t=request;request=nil;return t end,
                setresponsetoui=function() end,
                autorelease=function() coroutine.yield() end} end
            os.time=function() return math.floor(wallClock) end
            __G_TRACKBACK__=tostring
            UIReqeustClear=function() end;UIRequest_=function() end
            checkNetSatus=function() return true end
            ConnectToServer=function() return {sock={close=function() end}} end
            TCPSelect1conn=function() return true end
            accepted=0
            local runner=coroutine.create(function()
                GameLoop2({}, {[1306]=function()
                    accepted=accepted+1;return 0,1306,{type=1306}
                end},{},{})
            end)
            function pump(t)
                request=t;local before=accepted
                local ok,err=coroutine.resume(runner)
                assert(ok and coroutine.status(runner)=='suspended',err)
                return accepted>before
            end''')
        network.execute(scripts["assets/scripts/gameloop2.so"])

        def accepts_request(request):
            network.globals().wallClock = lua.globals().wallClock
            return network.globals().pump(network.table_from(dict(request.items())))

        lua.globals().networkAcceptsRequest = accepts_request
        lua.execute('''
            UICopyAttack2(dataFor(42101,1,42101,2))
            local enqueue=UIRequest
            UIRequest=function(t)
                enqueue(t)
                if t.type==1306 then assert(networkAcceptsRequest(t),'native throttle dropped automatic challenge') end
            end
            local function fireScaled(speed) layer.autoCopyTimer:fire(layer.autoCopyTimer.action.delay/speed) end
            for _,speed in ipairs({1,3,10}) do
                wallClock=wallClock+100
                assert(networkAcceptsRequest({type=1306})) -- 刚完成一场手动挑战。
                layer=makeLayer();AutoCopyAttach(layer,1500)
                layer.autoCopyButton.callback();confirmed()
                for point=1,2 do
                    local started=wallClock;local count=#requests
                    for i=1,500 do
                        fireScaled(speed)
                        if #requests>count then break end
                    end
                    assert(#requests==count+1 and requests[#requests].type==1306 and requests[#requests].point==point)
                    assert(wallClock-started>=3.1-1e-6,'scaled timer sent challenge before real-time cooldown')
                    if point==1 then UICopyAttack2(dataFor(42101,1,42101,2)) end
                end
                local waiting=wallClock;local count=#requests
                for i=1,1000 do
                    fireScaled(speed)
                    if not AutoCopyIsRunning() then break end
                end
                assert(not AutoCopyIsRunning() and wallClock-waiting>=20-1e-6,'scaled timer timed out too early')
                assert(AutoCopyBlockManual() and #requests==count) -- 结果未知时仍不可重试。
                UICopyAttack2(dataFor(42101,2,42102,1))
                assert(not AutoCopyBlockManual() and events[#events].kind=='battle')
                AutoCopyDetach(layer)
            end
            layer=makeLayer();AutoCopyAttach(layer,1500)
            layer.autoCopyButton.callback();confirmed()
            local count=#requests
            layer.autoCopyTimer:fire(0.1)
            assert(AutoCopyIsRunning() and #requests==count)
            layer.autoCopyButton.callback()
            assert(not AutoCopyIsRunning() and not AutoCopyBlockManual() and layer.autoCopyTimer.action==nil)
            AutoCopyDetach(layer)
        ''')

    def test_auto_copy_network_handoff_keeps_real_stamina_and_manual_behavior(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("自动推图网络回调验证需本机已有 lupa.lua51")
        lua = LuaRuntime()
        lua.execute('''
            print,cclog,printT=function() end,function() end,function() end
            local function message() return {ids={},SerializeToString=function(self) return self.ids end,
                ParseFromString=function(self,data) for k,v in pairs(data) do self[k]=v end end} end
            for _,name in ipairs({'copies_pb','copyattack_pb','copyall3starreward_pb','result_pb','somethings_pb','PickBattleResultReport'}) do
                package.preload[name]=function() return {} end
            end
            package.preload.ids_pb=function() return {Ids=message} end
            package.preload.battleresult_pb=function() return {BattleResult=message} end
            table.copy=function(t) local out={} for k,v in pairs(t) do out[k]=type(v)=='table' and table.copy(v) or v end return out end
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            PickBattleResultReport=function(result) return result.battlereport end
            UIResponse=function() end
            gamedata={cache={role={stamina=20},copy={[42101]={id=42101,status=0,pa1=1,pa2=1,pa3=1,points={}}}},ext={},
                config={copy={['42101']={['1']={physical=5,challenge=3,coin=100}}},
                    map={['42101']={section=40001,star1=3,star2=6,star3=9}},
                    section={['40001']={name='测试',basemap='test'}},global_kv={}}}
            function gamedata:SomethingProcess() return {} end
            function gamedata:updateRoleExp() return {oldlevel=16,newlevel=16} end
            function gamedata:Encounters() return {} end
            function gamedata:updateRoleStamina(value) self.cache.role.stamina=self.cache.role.stamina+value end
            function gamedata:Generals() end
            function gamedata:GeneralsEXP() return {} end
        ''')
        lua.execute(self.client_scripts()["assets/scripts/GameCopy.so"])
        lua.execute('''
            local remote,opcode,body=UICopyAttack2Callback({map=42101,point=1,local_auto_copy=1})
            assert(remote==1 and opcode==1306 and body[1]==42101 and body[2]==1)
            local reply=NetCopyAttack2Callback({rbuf={result=1,star=3,reward={},exp={generals={}},generals={},encounters={},battlereport='{}'}})
            assert(reply.localAutoCopy==1 and reply.localAutoStamina==15 and reply.map==42101 and reply.point==1)
            remote,opcode,body=UICopyAttack2Callback({map=42101,point=1})
            assert(remote==1 and opcode==1306)
            reply=NetCopyAttack2Callback({rbuf={result=1,star=3,reward={},exp={generals={}},generals={},encounters={},battlereport='{}'}})
            assert(reply.localAutoCopy==nil and reply.localAutoStamina==10)
            gamedata.cache.role.stamina=0
            remote,opcode,body=UICopyAttack2Callback({map=42101,point=1,local_auto_copy=1})
            assert(remote==0 and opcode==503 and body.msgtype=='shortphysical' and body.localAutoCopy==1)
            remote,opcode,body=UICopyAttack2Callback({map=42101,point=1})
            assert(body.localAutoCopy==nil)
        ''')

        lua.execute('''
            package.preload.error_pb=function() return {} end
            package.preload.params_pb=function() return {} end
            package.preload.logError=function() return {errorMessage={}} end
            initPb=function(_,fd) return fd.rbuf end
            printf=function() end
        ''')
        lua.execute(self.client_scripts()["assets/common_lua/GameErrorMessage.so"])
        lua.execute('''
            local err=NetErrorMessageCallback9({rbuf={ids={1306,0}}})
            assert(err.type==9999 and err.request_opcode==1306)
            local login=NetErrorMessageCallback9({rbuf={ids={1000,0}}})
            assert(login.type==9997 and login.local_login_failed)
        ''')

    def test_treasure_training_original_client_parses_equipment_and_deducts_cost_once(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("宝物强化客户端回调验证需本机已有 lupa.lua51")
        lua = LuaRuntime()
        lua.execute('''
            print,cclog,printT=function() end,function() end,function() end
            local function message()
                return {ids={},SerializeToString=function(self) return self end,
                    ParseFromString=function(self,data) for k,v in pairs(data) do self[k]=v end end}
            end
            package.preload.equiprefine_pb=function() return {} end
            package.preload.treasurerefine_pb=function() return {TreasureRefine=message} end
            package.preload.ids_pb=function() return {Ids=message} end
            package.preload.somethings_pb=function() return {SomeThings=message} end
            gamedata={ext={},cache={equips={[1000100]={},[1000101]={},[1000102]={}},
                role={coin=100000},props={[26410]={num=3},[26411]={num=0}}},
                config={equip={['26201']={quality=3,type='treasure',adorn=1}}}}
            function gamedata:updateRoleCoin(n) self.cache.role.coin=self.cache.role.coin+n end
            function gamedata:updateprops(item) self.cache.props[item.cid].num=self.cache.props[item.cid].num+item.num end
            function gamedata:SomethingProcess(reward)
                assert(reward.coin==nil and reward.usedcidnums==nil)
                for _,raw in ipairs(reward.equips) do self.cache.equips[raw.ids[1]]=self:equipData(raw) end
            end
        ''')
        data = builder.read_script("gamedata").decode("utf-8")
        start = data.index("function gamedata.equipData(self,data)")
        end = data.index("function gamedata.artifactData(self,data)", start)
        lua.execute(data[start:end])
        lua.execute(builder.read_script("GameTreasureUp").decode("utf-8"))
        lua.execute('''
            local remote,opcode,body=UITreasureStrengthenCallBack({iid=1000100,ids={1000101,1000102},xcoin=20000})
            assert(remote==1 and opcode==1118 and body.iid==1000100 and #body.ids==2)
            local reply=NetTreasureStrengthenCallBack({rbuf={equips={{ids={1000100,26201,4,0,100}}}}})
            assert(reply.type==1118 and reply.equip.level1==4 and reply.equip.exp==100)
            assert(gamedata.cache.equips[1000101]==nil and gamedata.cache.equips[1000102]==nil)
            assert(gamedata.cache.role.coin==80000)
            remote,opcode,body=UITreasureStrengthenByPropCallBack({iid=1000100,xcoin=6000,cids={{cid=26410,num=2},{cid=26411,num=0}}})
            assert(remote==1 and opcode==1210 and #body.ids==3 and body.ids[1]==1000100 and body.ids[2]==26410 and body.ids[3]==2)
            reply=NetTreasureStrengthenByPropCallBack({rbuf={equips={{ids={1000100,26201,7,0,300}}}}})
            assert(reply.type==1210 and reply.equip.level1==7 and reply.equip.exp==300)
            assert(gamedata.cache.props[26410].num==1 and gamedata.cache.role.coin==74000)
        ''')
        with zipfile.ZipFile(Path(__file__).parent / "configs_sec5.zip") as archive:
            config = {name: json.loads(archive.read(f"5/{name}.json"))
                      for name in ("equip", "treasure2_strengthen", "global_kv")}
        lua.globals().gamedata.config = lua.table_from(config, recursive=True)
        lua.execute('''
            treasureup={}
            ui={setSpriteTextureRect2=function() end,setLabelString=function() end}
            labels=setmetatable({},{__index=function(t,key)
                local label={setString=function() end};rawset(t,key,label);return label
            end})
        ''')
        code = builder.read_script("Layer_treasureup").decode("utf-8")
        start = code.index("function treasureup.setexp_up(self)")
        end = code.index("function treasureup.setData_up(", start)
        lua.execute(code[start:end])
        lua.execute('''
            local page={data={cid=26201,quality=3,level1=1,exp=0,maxlv1=8},rootItems=labels,
                selectData={{cid=26302,quality=4,level1=2,exp=30}}}
            treasureup.setexp_up(page)
            assert(page.uplevel1==4 and page.upexp==0 and page.xcoin==10000)
            page.data.maxlv1=2;page.selectData[1].level1=1
            treasureup.setexp_up(page)
            assert(page.uplevel1==2 and page.upexp==300)
            page.data.maxlv1=8;page.selectData[2]={cid=26302,quality=4,level1=1}
            treasureup.setexp_up(page)
            assert(page.uplevel1==4 and page.upexp==100 and page.xcoin==20000)
        ''')

    def test_protagonist_advance_original_client_parses_slots_and_deducts_cost_once(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("主角进阶客户端回调验证需本机已有 lupa.lua51")
        lua = LuaRuntime()
        lua.execute('''
            print=function() end
            local function message()
                return {ids={},SerializeToString=function(self) return self.ids end,
                    ParseFromString=function(self,data) for k,v in pairs(data) do self[k]=v end end}
            end
            for _,name in ipairs({'role_pb','protagonist_pb','generals_pb'}) do package.preload[name]=function() return {} end end
            package.preload.ids_pb=function() return {Ids=message} end
            package.preload.slots_pb=function() return {SlotS=message} end
            gamedata={ext={},cache={role={coin=1000000,gold=100},props={[20167]={num=10},[20161]={num=500}}},
                config={protagonist_grow={['6']={atk_cost=20161}}}}
            function gamedata.getIDandNUMs(spec)
                assert(spec=='20167,10;1000,500000;')
                return {{cid=20167,num=10},{cid=1000,num=500000}}
            end
            function gamedata:SlotInfoProcess(data) self.lastSlots=data;self.cache.protagonist=data.protagonist end
            function gamedata:updateRoleCoin(n) self.cache.role.coin=self.cache.role.coin+n end
            function gamedata:updateRoleGold(n) self.cache.role.gold=self.cache.role.gold+n end
            function gamedata:updateprops(item) self.cache.props[item.cid].num=self.cache.props[item.cid].num+item.num end
        ''')
        lua.execute(builder.read_script("GameRole").decode("utf-8"))
        lua.execute('''
            local remote,opcode,body=UIUserProtagonist2GrowupCallBack({xstr='20167,10;1000,500000;'})
            assert(remote==1 and opcode==1057 and #body==1 and body[1]==0)
            local nextState={level2=5,atk_a=0,def_a=0,hp_a=0,train=2,general={cid=10128,iid=7059}}
            local reply=NetUserProtagonist2GrowupCallBack({rbuf={protagonist=nextState,generals={nextState.general},slots={}}})
            assert(reply.type==1057 and reply.protagonist==nextState and reply.xhasnum==500)
            assert(gamedata.cache.role.coin==500000 and gamedata.cache.role.gold==100)
            assert(gamedata.cache.props[20167].num==0 and gamedata.cache.role.profile==10128)
            assert(gamedata.lastSlots.generals[1].iid==7059)
        ''')

    def test_watchstar_original_client_parses_status_and_deducts_cost_once(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("观星台客户端回调验证需本机已有 lupa.lua51")
        lua = LuaRuntime()
        lua.execute('''
            print,cclog=function() end,function() end
            local function ids() return {ParseFromString=function(self,data) self.ids=data end} end
            package.preload.ids_pb=function() return {Ids=ids} end
            package.preload.mysticalcave_pb=function() return {} end
            package.preload.somethings_pb=function() return {SomeThings=function() return {
                ParseFromString=function(self,data) self.data=data end} end} end
            gamedata={cache={role={gold=100}},ext={}}
            function gamedata:updateRoleGold(value) self.cache.role.gold=self.cache.role.gold+value end
            function gamedata:updateStaff(item) self.lastCost=item end
            function gamedata:SomethingProcess(reward) return reward.data end
            values={45,1,10,1,1,3,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,2}
        ''')
        game_data = builder.read_script("gamedata").decode("utf-8")
        start = game_data.index("function gamedata.ActivityWatchStar(self,data)")
        end = game_data.index("function gamedata.ActivityMonthGrowQuery(self, data)", start)
        lua.execute(game_data[start:end])
        lua.execute(builder.read_script("GameActivityHole").decode("utf-8"))
        lua.execute('''
            local remote,opcode,body=UIMysticalStargazingCallBack({})
            assert(remote==1 and opcode==2062 and body==nil)
            local reply=NetMysticalStargazingCallBack({rbuf=values})
            assert(reply.data.starnum==45 and reply.data.forecastnum==1 and reply.data.changenum==10)
            assert(#reply.data.starstatus==8 and #reply.data.rewardstatus==10 and reply.data.rewardlevel==2)
            assert(reply.data.starstatus[3]==3 and reply.data.rewardstatus[3]==1)
            remote,opcode,body=UIMysticalChangeSwacthStarCallBack({xnum=10})
            assert(remote==1 and opcode==2064 and body==nil)
            reply=NetMysticalChangeSwacthStarCallBack({rbuf=values})
            assert(reply.gold==90 and gamedata.cache.role.gold==90)
            remote,opcode,body=UIWatchStarWatchExCallBack({xnum=60})
            assert(remote==1 and opcode==2067 and body==nil)
            NetWatchStarWatchExCallBack({rbuf=values})
            assert(gamedata.cache.role.gold==30)
            remote,opcode,body=UIWatchStarUpLevelCallBack({need={{cid=1001,num=10}}})
            assert(remote==1 and opcode==2068 and body==nil)
            reply=NetWatchStarUpLevelCallBack({rbuf={3}})
            assert(reply.data.rewardlevel==3 and gamedata.lastCost.cid==1001 and gamedata.lastCost.num==-10)
            remote,opcode,body=UIWatchStarRewardCallBack({})
            assert(remote==1 and opcode==2066 and body==nil)
            reply=NetWatchStarRewardCallBack({rbuf='reward'})
            assert(reply.reward=='reward')
        ''')

    def test_resource_purchase_client_quotes_price_and_refreshes_status(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("购买体力客户端回调验证需本机已有 lupa.lua51")
        scripts = self.client_scripts()
        window = scripts["assets/scripts/window_buyPowerPop.so"]
        self.assertIn("self.localVipPending = true", window)
        self.assertIn("UIRequest({type = 300, update = true})", window)
        self.assertIn("if self.localVipPending then", window)
        self.assertIn("self.localVipPending = false", window)
        lua = LuaRuntime()
        lua.execute('''
            print,cclog,printT=function() end,function() end,function() end
            package.preload.ids_pb=function() return {Ids=function() return {ids={},
                SerializeToString=function(self) return self.ids end} end} end
            package.preload.result_pb=function() return {Result=function() return {
                ParseFromString=function() end} end} end
            package.preload.somethings_pb=function() return {} end
            package.preload.params_pb=function() return {} end
            gamedata={ext={},cache={role={gold=100,stamina=3,energy=4},vipstatus={b_physical=0,b_energy=0}},
                config={global_kv={basic_buy_stamina={value='50'},basic_buy_energy={value='10'}}}}
            function gamedata:updateRoleStamina(n) self.cache.role.stamina=self.cache.role.stamina+n end
            function gamedata:updateRoleEnergy(n) self.cache.role.energy=self.cache.role.energy+n end
            function gamedata:updateRoleGold(n) self.cache.role.gold=self.cache.role.gold+n end
        ''')
        lua.execute(scripts["assets/scripts/GameRecharge.so"])
        lua.execute('''
            local remote,opcode,body=UIUserBuyCallBack({cid=2,count=2,gold=100})
            assert(remote==1 and opcode==301 and #body==3 and body[1]==2 and body[2]==2 and body[3]==100)
            local reply=NetUserBuyCallBack({rbuf=''})
            assert(reply.order==2 and gamedata.cache.role.stamina==103 and gamedata.cache.role.gold==0)
            assert(gamedata.cache.vipstatus.b_physical==2)
            remote,opcode,body=UIUserBuyCallBack({cid=1,count=1,gold=50})
            assert(#body==3 and body[1]==1 and body[2]==1 and body[3]==50)
        ''')
        lua.execute('''
            CCControlEventTouchUpInside=1
            local function button() return {addHandleOfControlEvent=function(self,cb) self.callback=cb end,
                setSwallowsTouch=function() end,setTouchPriority=function() end} end
            CCBReaderLoad=function() return {},{closeButton=button(),add1=button(),sub1=button(),doButton2=button()} end
            ui={creatInputEditBoxForNum=function() end,setLabelString=function() end}
            gameConfig={checkBuildOpen=function() return true end,strings={string_common=function() return '' end}}
            GameScene={roleinfo={gold=100}}
            gameTouch={clickprofbytime=function() end}
            requests={}
            UIRequest=function(req) table.insert(requests,req) end
            runGamePrompt=function() prompted=true end
        ''')
        lua.globals().buy = lua.execute(window)
        lua.execute('''
            function buy:reload(data) self.data=data end
            function buy:setbuydata() end
            function buy:setShowData() end
            buy:open(-1,{id=2})
            assert(#requests==1 and requests[1].type==300 and requests[1].update)
            buy.buynum=1;buy.totalprice=50
            buy.rootItems.doButton2.callback()
            assert(prompted and #requests==1 and buy.localVipPending)
            buy:reloadShowData()
            buy.buynum=1;buy.totalprice=50
            buy.rootItems.doButton2.callback()
            assert(not buy.localVipPending and #requests==2)
            assert(requests[2].type==301 and requests[2].cid==2 and requests[2].gold==50)
        ''')

    def test_qiankun_client_identifies_consumed_general_by_iid(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("乾坤炉客户端回调验证需本机已有 lupa.lua51")
        scripts = self.client_scripts()
        lua = LuaRuntime()
        lua.execute('''
            print,printT,cclog=function() end,function() end,function() end
            package.preload.ids_pb=function() return {} end
            package.preload.somethings_pb=function() return {SomeThings=function() return {
                ParseFromString=function(self,data) self.data=data end} end} end
            package.preload.idnums_pb=function() return {IdNums=function()
                local values={}
                function values:add() local item={} table.insert(self,item) return item end
                return {idnums=values,SerializeToString=function(self) return self.idnums end}
            end} end
            gamedata={ext={},config={general={['10402']={}}},cache={generals={[2000001]={cid=10402}}}}
            function gamedata:updategeneralfragmentbynum(value) self.lastFragment=value end
            function gamedata:SomethingProcess(value) return value.data end
        ''')
        lua.execute(scripts["assets/scripts/GameQiankunlu.so"])
        lua.execute('''
            local remote,opcode,body=UIGeneralResolveCallBack2({ids={2000001},cid={},
                fragments={{cid=10402,num=1},{cid=11402,num=2}}})
            assert(remote==1 and opcode==1039 and #body==2)
            assert(body[1].id==11402 and body[1].num==2)
            assert(body[2].id==2000001 and body[2].num==-1)
            local reply=NetGeneralResolveCallBack2({rbuf='reward'})
            assert(gamedata.cache.generals[2000001]==nil)
            assert(gamedata.lastFragment.cid==11402 and gamedata.lastFragment.num==-2)
            assert(reply.reward=='reward')
        ''')
        lua.execute(scripts["assets/scripts/GameActivitySecretShop.so"])
        lua.execute('''
            gamedata.cache.activitySecretShop={itemsdata={}}
            local remote,opcode,body=UIActivitySecretShopQueryCallBack({})
            assert(remote==1 and opcode==3650 and body==nil)
        ''')

    def test_battle_overlapping_dodges_keep_ghosts_alive_until_their_own_cleanup(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("闪避残影回调验证需本机已有 lupa.lua51")
        lua = LuaRuntime()
        lua.execute('''
            gameConfig={strings={damageConfig={}}}
            ccc3=function() return {} end
            local now,queue,order=0,{},0
            function advance(until_time)
                while #queue>0 do
                    table.sort(queue,function(a,b) return a.at<b.at or a.at==b.at and a.order<b.order end)
                    if queue[1].at>until_time then break end
                    local event=table.remove(queue,1)
                    now=event.at
                    if event.owner.alive and event.generation==event.owner.generation then event.callback() end
                end
                now=until_time
            end
            local function node()
                local n={alive=true,generation=0,children={}}
                function n:stopAllActions() self.generation=self.generation+1 end
                function n:addChild(child) child.parent=self table.insert(self.children,child) end
                function n:removeFromParentAndCleanup()
                    assert(self.alive,'removed node reused')
                    self.alive=false
                    while #self.children>0 do self.children[1]:removeFromParentAndCleanup() end
                    for i,child in ipairs(self.parent.children) do
                        if child==self then table.remove(self.parent.children,i) break end
                    end
                end
                function n:runAction(action)
                    assert(self.alive,'removed skeleton reused')
                    if not action then return end
                    order=order+1
                    table.insert(queue,{at=now+action[1],callback=action[2],owner=self,
                                        generation=self.generation,order=order})
                end
                function n:setAnimation() assert(self.alive,'removed skeleton reused') end
                function n:setPosition() end
                function n:setScale() end
                function n:setScaleX(value) self.scale_x=value end
                return n
            end
            CCNode={create=node}
            CCSkeletonAnimation={create=node}
            CCDelayTime={create=function(_,delay) return delay end}
            CCFadeTo=CCDelayTime
            CCTintTo={create=function() return 0 end}
            CCSpawn={createWithTwoActions=function() return nil end}
            CCCallFunc={create=function(_,callback) return callback end}
            CCSequence={createWithTwoActions=function(_,delay,callback) return {delay,callback} end}
            function check_dodges(general,interval,direct)
                now,queue,order=0,{},0
                local parent,main=node(),node()
                parent:addChild(main)
                local unit={SkeletonNode=parent,skeleton=main,direct=direct,data={animation={name='stub'}},
                            findStandStatus=function() return 'stand' end}
                general.dodgeAction(unit,{actiondelay=0.5})
                advance(interval)
                general.dodgeAction(unit,{actiondelay=0.5})
                advance(1.5)
                assert(main.alive and #parent.children==1 and parent.children[1]==main,
                       'canceled parent callback leaked a dodge ghost')
            end
        ''')
        scripts = self.client_scripts()
        code = scripts.get("assets/scripts/battlegeneral.so")
        if code is None:
            code = (Path(__file__).parent / "scripts_clean/battlegeneral.lua").read_text(encoding="utf-8")
        lua.globals().general = lua.execute(code)
        for interval in (0.25, 0.05, 0.4):
            for direct in ("atk", "def"):
                with self.subTest(interval=interval, direct=direct):
                    lua.globals().check_dodges(lua.globals().general, interval, direct)

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
                              vipstatus={vipexchange_free=0}, monthcard={{status=2}}, timegift={}, growplanx1={status={}}}, ext={},
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
                                 {UILuxurySignInStatusCallBack,3643}, {UIVipStatusCallBack,300},
                                 {UIMonthCardCallBack,2090}, {UIGrowPlan2CallBack,7091}}) do
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

    def test_daily_refresh_uses_read_queries_and_restores_vip_buttons(self):
        try:
            from lupa.lua51 import LuaRuntime
        except ImportError:
            self.skipTest("跨日页面刷新验证需本机已有 lupa.lua51")
        scripts = self.client_scripts()
        lua = LuaRuntime()
        lua.execute('''
            require=function() return {} end
            cclog=function() end
            myque={new=function() return {} end}
            ccp=function(x,y) return {x=x,y=y} end
            gameConfig={originSize={width=1080,height=1920}, maxRadio_size=1, images={}}
            gamedata={device={SCREEN_WIDTH=1080,SCREEN_HEIGHT=1920}, config={vip_welfare={['6']={
                ['10']={battle_lv=10,free='20001,1',pay='20001,1',discount='1001,10'}}},global_kv={}}}
            requests={}
            UIRequest=function(t) table.insert(requests,t) end
            gameWindows={openWindow=function() end}
            gameTouch={clickprofbytime=function() end}
            CCUserDefault={sharedUserDefault=function() return {setStringForKey=function() end} end}
            CCControlEventTouchUpInside=1
            ui={getIDandNUMs=function() return {{cid=1001,num=1}} end,
                setLabelString=function() end, removeGray=function(_,node) node.gray=false end,
                addGray=function(_,node) node.gray=true end}
            function widgets()
                return setmetatable({}, {__index=function(items,key)
                    local node=setmetatable({addHandleOfControlEvent=function(self,f) self.click=f end},
                        {__index=function() return function() end end})
                    items[key]=node
                    return node
                end})
            end
        ''')
        lua.globals().GameScene = lua.execute(scripts["assets/scripts/GameScene.so"])
        lua.execute('''
            GameScene.rootItems={}
            GameScene.roleinfo={id=10001,level=8}
            GameScene.vip={vip=6}
            GameScene.layers.activity={show=true,module={type='5',presentPage=1,
                realPageTable={{request=300},{request=4611}}}}
            GameScene.layers.copy_map.module.normaldata={stale=true}
            GameScene:cacheresetrequest('cachereset')
            local found={}
            for _,request in ipairs(requests) do
                found[request.type]=(found[request.type] or 0)+1
                assert(request.type~=999900 and request.type~=4611 and request.type~=2038 and request.type~=3626)
            end
            assert(GameScene.layers.copy_map.module.normaldata==nil)
            assert(found[300]==1 and found[1300] and found[3200] and found[2410] and found[2037])
            assert(not found[3620])
            requests={}
            GameScene.layers.activity.module.realPageTable[1].request=4611
            GameScene:cacheresetrequest('cachereset')
            for _,request in ipairs(requests) do assert(request.type~=4611) end
            for _,opcode in ipairs({2090,2010,3641,3630,3680,8075,8026,4890}) do
                requests={}
                GameScene.layers.activity.module.realPageTable[1].request=opcode
                GameScene:cacheresetrequest('cachereset')
                local count=0
                for _,request in ipairs(requests) do
                    if request.type==opcode then assert(request.update); count=count+1 end
                    assert(request.type~=4611 and request.type~=3620)
                end
                assert(count==1)
            end
            GameScene.layers.activity.module.realPageTable[1]={id=161,module={pageId=2,tempRequestTable={6911,3650}}}
            requests={}
            GameScene:cacheresetrequest('cachereset')
            assert(requests[#requests].type==3650)
            GameScene.layers.copy_chapter.show=true
            for _,kind in ipairs({'normal','star'}) do
                GameScene.layers.copy_chapter.module.selectpage=kind
                requests={}
                GameScene:cacheresetrequest('cachereset')
                local found=false
                for _,request in ipairs(requests) do if request.type==1350 then found=true end end
                assert(found==(kind=='star'))
            end
            GameScene.layers.copy_chapter.show=false
        ''')
        lua.execute((Path(__file__).parent / "scripts_clean/UICacheReset.lua").read_text())
        lua.execute('''
            guide={}
            requests={}
            battleScene={show=true}
            UICacheReset({type=110})
            assert(#requests==0 and battleScene.cacheresetCallBack)
            battleScene.show=false
            GameScene.layers.activity.show=false
            GameScene.layers.bloodbattle.show=true
            battleScene.cacheresetCallBack()
            local found={}
            for _,request in ipairs(requests) do
                found[request.type]=true
                assert(request.type~=999900 and request.type~=4611 and request.type~=2038 and request.type~=3626)
            end
            assert(found[3620] and not found[3650])
        ''')
        lua.execute(scripts["assets/scripts/GameCopy.so"])
        lua.execute('''
            gamedata.cache={copy={stale=true}}
            local remote,opcode,body=UICopyQueryCallback({update=true})
            assert(remote==1 and opcode==1300 and body==nil)
        ''')
        lua.globals().welfare = lua.execute(scripts.get("assets/scripts/Layer_activity_vipwelfare.so") or
            (Path(__file__).parent / "scripts_clean/Layer_activity_vipwelfare.lua").read_text())
        lua.execute('''
            welfare.show=true
            welfare.coveritems=widgets()
            welfare.ListTableView1={reloadData=function() end}
            welfare.ListTableView2=welfare.ListTableView1
            welfare:reloaddata({vipstatus={vipexchange_free=1,vipexchange_buy=1}})
            assert(welfare.coveritems.getButton.gray and welfare.coveritems.buyButton.gray)
            welfare:reloaddata({vipstatus={vipexchange_free=0,vipexchange_buy=0}})
            assert(not welfare.coveritems.getButton.gray and not welfare.coveritems.buyButton.gray)
            requests={}
            welfare.coveritems.getButton:click()
            assert(#requests==1 and requests[1].type==4611 and requests[1].isfree==1)
        ''')
        lua.globals().activity = lua.execute(scripts["assets/scripts/Layer_activity.so"])
        lua.execute('''
            gamedata.config.activity_time={}
            activity:makepageconfig()
            for _,id in ipairs({1,5,10,18,19,22,28,57,101,132,149,153,169,170,173}) do
                assert(activity.activityPageconfig[id].needupdate)
            end
            assert(not activity.activityPageconfig[3].needupdate)
        ''')
        lua.globals().generalShop = lua.execute(scripts["assets/scripts/Layer_activity_general_shop.so"])
        lua.execute('''
            requests={}
            generalShop.tempActivityTable={}
            generalShop.tempRequestTable={6911,3650}
            generalShop.pageId=2
            generalShop:refreshFunc()
            assert(#requests==1 and requests[1].type==3650 and requests[1].update)
            requests={}
            generalShop.pageId=1
            generalShop:refreshFunc()
            assert(#requests==0)
        ''')

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
