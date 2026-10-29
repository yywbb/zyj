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
from zyj_server import configuration, player


class LanBuildTests(unittest.TestCase):
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
