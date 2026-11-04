import unittest
from pathlib import Path

import test_build_local_apk as apk_tests


UI_HARNESS = '''
print,printT,cclog=function() end,function() end,function() end
package.preload.BattleReportAbbToKey=function() return {} end
requests,notices,battles={}, {}, {}
wallClock=1000;os.time=function() return math.floor(wallClock) end
UIRequest=function(t) table.insert(requests,t) end
runGamePrompt=function(t) table.insert(notices,t.msg) end
RunbattleCallBack=function(kind,t) table.insert(battles,{kind=kind,t=t}) end
updateDataLife=function() rewardUpdates=(rewardUpdates or 0)+1 end
setTriggerGiftEnable=function() end
guide={controller={isOnGuide=false}}
gameConfig={originSize={width=1080}}
gamedata={config={copy={
    ['42101']={['1']={physical=5,challenge=3,xp=10},['2']={physical=5,challenge=3,xp=10}},
    ['42102']={['1']={physical=6,challenge=2,xp=12}}},
    vip={['0']={b_physical=3,b_fbsd=0}},
    global_kv={basic_buy_stamina={value='50'},copy_wipe_level={value='1'}},
    buycount_price={['1']={stamina=50},['2']={stamina=100},['3']={stamina=150}},
    activity_huodong={['1']={param=3,open_time=3,modulus=0.8}}}}
function node()
    return {children={},addChild=function(self,c) table.insert(self.children,c) end,
        setPreferredSize=function(self,s) self.size=s end,setContentSize=function(self,s) self.size=s end,
        setAnchorPoint=function() end,setPosition=function(self,p) self.position=p end,
        setTouchPriority=function(self,p) self.priority=p end,setSwallowsTouch=function() end,
        setEnabled=function(self,e) self.enabled=e end,
        setTitleForState=function(self,s,state) assert(type(s)=='string');self.title=s end,
        setTitleColorForState=function(self,c,state) self.color=c end,
        setBackgroundSpriteFrameForState=function(_,frame) assert(frame) end,
        addHandleOfControlEvent=function(self,cb) self.callback=cb end,
        setString=function(self,s) self.text=s end,
        removeAllChildrenWithCleanup=function(self) self.children={} end,
        removeFromParentAndCleanup=function(self) self.removed=true end,
        stopAllActions=function(self) self.action=nil end,
        runAction=function(self,a) self.action=a end,
        fire=function(self,seconds) local a=self.action;self.action=nil
            assert(a,'timer not scheduled');wallClock=wallClock+(seconds or math.ceil(a.delay)+1);a.callback() end}
end
CCNode={create=function() return node() end}
CCControlButton={create=function(_,s) local b=node();b.title=s;return b end}
CCSizeMake=function(w,h) return {width=w,height=h} end;ccp=function(x,y) return {x=x,y=y} end
ccc3=function(r,g,b) return {r=r,g=g,b=b} end
CCControlStateNormal=0;CCControlStateHighlighted=1;CCControlStateDisabled=2;CCControlEventTouchUpInside=1
CCString={create=function(_,s) return {value=s} end}
CCDelayTime={create=function(_,delay) return delay end};CCCallFunc={create=function(_,cb) return cb end}
CCSequence={createWithTwoActions=function(_,d,cb) return {delay=d,callback=cb} end}
CCSprite={create=function(_,path) return {displayFrame=function() return path end} end}
CCScale9Sprite={createWithSpriteFrame=function(_,frame) assert(frame:find('GM/GMTool/GMTool_bg1.png',1,true));return node() end}
local frames={}
CCSpriteFrameCache={sharedSpriteFrameCache=function() return {
    spriteFrameByName=function(_,n) return frames[n] end,addSpriteFrame=function(_,v,n) frames[n]=v end} end}
ui={createLabel=function(t) local n=node();n.text=t.text;n.args=t;return n end}
gameWindows={windows={confirm={show=false}},openWindow=function(self,name,data,cb)
    if name=='confirm' then confirmation=cb;confirmationText=data.msg;self.windows.confirm.show=true
    else local w=self.windows[name];assert(w);w.show=true;w.module:open(-200,data,cb) end
end,closeWindowDirect=function(self,name)
    local w=self.windows[name];if w and w.show then w.show=false;if w.module then w.module:close() end end
end}
function gameWindows:closeWindow(name) self:closeWindowDirect(name) end
function gameWindows:closeAllWindowDirect() for name in pairs(self.windows) do self:closeWindowDirect(name) end end
function confirmNow() local cb=confirmation;confirmation=nil;gameWindows:closeWindowDirect('confirm');assert(cb);cb() end
GameScene={presentLayer='copy_map',roleinfo={stamina=30,gold=1000,level=16,vip=0},
    layers={copy_map={show=true,module={}},copy_chapter={show=false,module={}}},
    addUpdate=function() end,checkopenlevelbyId=function() return false end,UpdatePresentLayer=function() end}
function copies(a,b,c,kill)
    return {['1']={maps={['1']={id=42101,points={['1']={id=1,star=a,kill=kill or 0},['2']={id=2,star=b,kill=0}}},
        ['2']={id=42102,points={['1']={id=1,star=c,kill=0}}}}}}
end
function attach(data)
    layer={datatype='normal',rootNode=node(),normaldata=data or copies(0,0,0),data={id=42101,points={}}}
    layer.data=layer.normaldata['1'].maps['1']
    function layer:reloadnormalData(data,param) self.normaldata=data or self.normaldata;self.lastParam=param end
    GameScene.layers.copy_map.module=layer;AutoCopyAttach(layer,1500)
end
function start(mode,buy,reset) AutoCopyStart(mode or 'progress',buy or false,reset or false);confirmNow() end
function tick() layer.autoCopyTimer:fire() end
function respond(data,request)
    local req=request or requests[#requests];local t=data or {}
    t.type=req.type;t.localAutoCopy=req.local_auto_copy;t.map=t.map or req.map;t.point=t.point or req.point
    t.localAutoRole=t.localAutoRole or GameScene.roleinfo;t.localAutoTime=t.localAutoTime or 6*86400
    if req.type==1300 then t.copy=t.copy or layer.normaldata;UICopyQuery(t)
    elseif req.type==300 then t.vipstatus=t.vipstatus or {b_physical=0};UIVipStatus(t)
    elseif req.type==1305 then t.copy=t.copy or layer.normaldata;UICopyResetKill(t)
    elseif req.type==301 then UIUserBuy(t)
    else
        t.copy=t.copy or layer.normaldata;t.result=t.result or 1;t.reward={};t.exp=t.exp or {oldlevel=16,newlevel=16}
        if req.type==1306 then UICopyAttack2(t) else UICopyWipe2(t) end
    end
    return t
end
function readCycle(data) tick();assert(requests[#requests].type==1300);respond({copy=data or layer.normaldata}) end
'''


class AutoCopyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        from lupa.lua51 import LuaRuntime
        cls.runtime = staticmethod(LuaRuntime)
        cls.scripts = apk_tests.LanBuildTests().client_scripts()

    def setUp(self):
        self.lua = self.runtime()
        self.lua.execute(UI_HARNESS)
        self.lua.execute((Path(__file__).parent / "scripts_clean/setSpriteFrame.lua").read_text())
        self.lua.execute(self.scripts["assets/scripts/UICopy.so"])
        self.lua.execute(self.scripts["assets/scripts/UIRecharge.so"])
        self.lua.globals().autoWindow = self.lua.execute(self.scripts["assets/scripts/window_localAutoCopy.so"])
        self.lua.execute("gameWindows.windows.localAutoCopy={module=autoWindow};attach()")

    def test_popup_modes_paid_options_default_off_and_stale_confirmation(self):
        self.lua.execute('''
            layer.autoCopyButton.callback();assert(#requests==0)
            assert(autoWindow.mode=='progress' and not autoWindow.buy and not autoWindow.reset)
            autoWindow.modeButtons.stars.callback();assert(autoWindow.mode=='stars')
            autoWindow.buyButton.callback();autoWindow.resetButton.callback()
            assert(autoWindow.buy and autoWindow.reset)
            autoWindow.startButton.callback()
            assert(confirmationText:find('元宝') and confirmationText:find('连续') and #requests==0)
            AutoCopyDetach(layer);attach();confirmNow();assert(not AutoCopyIsRunning() and #requests==0)
            layer.autoCopyButton.callback();assert(not autoWindow.buy and not autoWindow.reset)
            assert(layer.autoCopyButton.position.x+layer.autoCopyButton.size.width/2<830)
        ''')

    def test_opening_settings_pauses_spending_and_disables_start_until_pending_reply(self):
        self.lua.execute('''
            attach(copies(3,0,0));start('sweep',true,true);readCycle()
            local count=#requests
            layer.autoCopyButton.callback()
            assert(not AutoCopyIsRunning() and not autoWindow.startButton.enabled)
            assert(not autoWindow.buy and not autoWindow.reset and #requests==count)
            respond();assert(not AutoCopyBlockManual())
            for i=count+1,#requests do assert(requests[i].type==1001) end -- 停止后的原生结果只刷新角色。
            gameWindows:closeWindowDirect('localAutoCopy')
        ''')

    def test_progression_stars_scan_once_and_latest_sweep_keeps_levelups(self):
        self.lua.execute('''
            start();readCycle();assert(requests[#requests].type==1306 and requests[#requests].point==1)
            respond({copy=copies(3,0,0)});readCycle()
            assert(requests[#requests].map==42101 and requests[#requests].point==2)
            respond({copy=copies(3,3,0)});readCycle()
            assert(requests[#requests].map==42102 and requests[#requests].point==1)
            respond({result=0});assert(not AutoCopyIsRunning() and battles[#battles].kind=='copy')
            attach(copies(1,2,3));start('stars');readCycle()
            assert(requests[#requests].map==42101 and requests[#requests].point==1)
            respond({copy=copies(2,2,3)});readCycle()
            assert(requests[#requests].point==2) -- 未三星也不在同轮重复烧体力。
            respond({copy=copies(2,3,3)});readCycle()
            assert(not AutoCopyIsRunning() and notices[#notices]:find('补星'))
            attach(copies(3,2,3));start('sweep');readCycle()
            assert(requests[#requests].type==1307 and requests[#requests].map==42102)
            assert(requests[#requests].method==0 and requests[#requests].exchange==0)
            local count=#battles
            respond({exp={oldlevel=16,newlevel=17}});readCycle()
            assert(AutoCopyIsRunning() and #battles==count and requests[#requests].type==1307)
            assert(requests[#requests].map==42102 and rewardUpdates>=5)
        ''')

    def test_scan_reaches_earlier_maps_and_fresh_midnight_counts_avoid_paid_reset(self):
        self.lua.execute('''
            attach(copies(1,2,0));layer.data=layer.normaldata['1'].maps['2']
            start('stars');readCycle();assert(requests[#requests].map==42101 and requests[#requests].point==1)
            AutoCopyStop();respond()
            attach(copies(3,3,0,3));start('sweep',false,true)
            readCycle(copies(3,3,0)) -- 午夜后1300已清空次数，不按旧页面付费重置。
            assert(requests[#requests].type==1307 and requests[#requests].point==2)
            AutoCopyStop();respond()
            attach(copies(0,0,0));layer.data=layer.normaldata['1'].maps['2']
            start();readCycle();assert(requests[#requests].map==42102)
        ''')

    def test_role_refresh_uses_the_real_network_path_not_the_native_role_cache(self):
        lua = self.runtime()
        lua.execute('''print=function() end;gamedata={cache={role={id=1}}}
            for _,name in ipairs({'role_pb','ids_pb','protagonist_pb','slots_pb','generals_pb'}) do
                package.preload[name]=function() return {} end
            end''')
        import build_local_apk
        lua.execute(build_local_apk.read_script("GameRole").decode())
        lua.execute('''
            assert(UIRoleInfoCallBack({type=1001})==0)
            assert(UIRoleInfoCallBack({type=1001,param='error'})==1)
        ''')

    def test_buys_one_fresh_quoted_stamina_then_resets_before_sweep(self):
        self.lua.execute('''
            attach(copies(3,0,0,3));GameScene.roleinfo.stamina=0
            start('sweep',true,true);readCycle()
            assert(requests[#requests].type==300)
            respond({localAutoTime=6*86400}) -- UTC+8 Wednesday: 50 * 0.8。
            local req=requests[#requests]
            assert(req.type==301 and req.cid==2 and req.count==1 and req.gold==40)
            GameScene.roleinfo.stamina=50;GameScene.roleinfo.gold=960
            respond();readCycle();assert(requests[#requests].type==1305 and requests[#requests].map==42101)
            GameScene.roleinfo.gold=945
            respond({copy=copies(3,0,0)});readCycle()
            assert(requests[#requests].type==1307 and GameScene.roleinfo.gold==945)
        ''')

    def test_no_unrequested_spending_and_limits_or_combined_cost_stop_before_charge(self):
        self.lua.execute('''
            for _,opts in ipairs({{false,false},{true,false},{false,true}}) do
                attach(copies(3,0,0,3));GameScene.roleinfo.stamina=0
                start('sweep',opts[1],opts[2]);readCycle()
                assert(not AutoCopyIsRunning() and requests[#requests].type==1300)
            end
            attach(copies(3,0,0,3));start('sweep',true,true);readCycle()
            respond({vipstatus={b_physical=3}})
            assert(not AutoCopyIsRunning() and requests[#requests].type==300 and notices[#notices]:find('上限'))
            attach(copies(3,0,0,3));GameScene.roleinfo.gold=54;start('sweep',true,true);readCycle()
            respond();assert(not AutoCopyIsRunning() and requests[#requests].type==300)
            assert(notices[#notices]:find('元宝')) -- 40体力价+15重置价不能只付一半。
            attach(copies(3,0,0));GameScene.roleinfo.gold=1000;start('sweep',true,false);readCycle()
            respond({vipstatus={b_physical=1}})
            assert(requests[#requests].type==301 and requests[#requests].gold==80)
        ''')

    def test_matching_rejections_timeout_cancel_and_late_callbacks_never_retry_payment(self):
        self.lua.execute('''
            attach(copies(3,0,0));GameScene.roleinfo.stamina=0;start('sweep',true,false);readCycle();respond()
            assert(requests[#requests].type==301)
            local paid=requests[#requests];local count=#requests
            tick();assert(not AutoCopyIsRunning() and AutoCopyBlockManual() and #requests==count)
            AutoCopyServerError({request_opcode=1305,localAutoCopy=paid.local_auto_copy})
            assert(AutoCopyBlockManual())
            respond({},paid);assert(not AutoCopyBlockManual() and #requests==count)
            GameScene.roleinfo.stamina=50;start('sweep');readCycle();local current=requests[#requests]
            respond({},paid);assert(AutoCopyIsRunning() and AutoCopyBlockManual())
            AutoCopyServerError({request_opcode=1307,localAutoCopy=current.local_auto_copy})
            assert(not AutoCopyIsRunning() and not AutoCopyBlockManual())
            start('sweep');readCycle();current=requests[#requests];AutoCopyStop()
            assert(AutoCopyBlockManual());respond({},current);assert(not AutoCopyBlockManual())
            assert(battles[#battles].kind=='copywipe')
        ''')

    def test_native_prompt_and_error_hooks_release_only_the_matching_operation(self):
        self.lua.execute("package.preload.logError=function() return {errorMessage={},errorFunc={}} end")
        self.lua.execute(self.scripts["assets/scripts/UIPrompt.so"])
        self.lua.execute(self.scripts["assets/scripts/UIErrorMessage.so"])
        self.lua.execute('''
            attach(copies(3,0,0));start('sweep');readCycle();local req=requests[#requests]
            UIPrompt({type=503,localAutoCopy=req.local_auto_copy,localAutoOpcode=1307,msg='体力不足'})
            assert(not AutoCopyIsRunning() and not AutoCopyBlockManual() and notices[#notices]=='体力不足')
            start('sweep');readCycle();req=requests[#requests]
            UIErrorMessage({request_opcode=301,localAutoCopy=req.local_auto_copy,msg='unrelated'})
            assert(AutoCopyIsRunning() and AutoCopyBlockManual())
            UIErrorMessage({request_opcode=1307,localAutoCopy=req.local_auto_copy,msg='stale quote'})
            assert(not AutoCopyIsRunning() and not AutoCopyBlockManual())
            start('sweep');tick();req=requests[#requests]
            GameScene.presentLayer='main';respond({},req)
            assert(not AutoCopyIsRunning() and not AutoCopyBlockManual() and requests[#requests].type==1300)
        ''')

    def test_guide_modal_page_exit_and_sweep_gate_stop_without_spending(self):
        self.lua.execute('''
            attach(copies(3,0,0));start('sweep');guide.controller.isOnGuide=true;tick()
            assert(not AutoCopyIsRunning() and #requests==0);guide.controller.isOnGuide=false
            start('sweep');gameWindows.windows.other={show=true};tick()
            assert(not AutoCopyIsRunning() and #requests==0);gameWindows.windows.other.show=false
            gamedata.config.global_kv.copy_wipe_level.value='50'
            start('sweep');readCycle();assert(not AutoCopyIsRunning() and requests[#requests].type==1300)
            gamedata.config.global_kv.copy_wipe_level.value='1'
            start('sweep');AutoCopyDetach(layer);assert(not AutoCopyIsRunning())
        ''')

    def test_manual_battle_start_or_late_result_stops_automation_before_any_payment(self):
        self.lua.execute('''
            manualBattle=false;getbattlecallbackactive=function() return manualBattle end
            attach(copies(3,0,0));start('sweep',true,true);manualBattle=true;tick()
            assert(not AutoCopyIsRunning() and #requests==0)
            manualBattle=false;start('sweep',true,true);tick();local query=requests[#requests]
            assert(query.type==1300)
            UICopyAttack2({type=1306,map=42101,point=1,result=1,copy=copies(3,0,0),reward={},exp={oldlevel=16,newlevel=16}})
            assert(not AutoCopyIsRunning() and AutoCopyBlockManual())
            respond({},query);assert(not AutoCopyBlockManual())
            for _,r in ipairs(requests) do assert(r.type==1001 or r.type==1300) end
        ''')

    def test_real_time_pacing_and_timeouts_under_acceleration(self):
        network = self.runtime()
        network.execute('''
            print,cclog,cctrace=function() end,function() end,function() end
            package.preload.network=function() return {} end
            package.preload.uiqueue=function() return {
                getrequestfromui=function() local t=request;request=nil;return t end,
                setresponsetoui=function() end,autorelease=function() coroutine.yield() end} end
            os.time=function() return math.floor(wallClock) end;__G_TRACKBACK__=tostring
            UIReqeustClear=function() end;UIRequest_=function() end
            checkNetSatus=function() return true end
            ConnectToServer=function() return {sock={close=function() end}} end
            TCPSelect1conn=function() return true end
            accepted=0
            local function accept(t) accepted=accepted+1;return 0,t.type,{type=t.type} end
            local runner=coroutine.create(function() GameLoop2({}, {[1306]=accept,[1307]=accept},{},{}) end)
            function pump(t)
                request=t;local before=accepted;local ok,err=coroutine.resume(runner)
                assert(ok and coroutine.status(runner)=='suspended',err);return accepted>before
            end
        ''')
        network.execute(self.scripts["assets/scripts/gameloop2.so"])

        def accepts(request):
            network.globals().wallClock = self.lua.globals().wallClock
            return network.globals().pump(network.table_from(dict(request.items())))

        self.lua.globals().nativeAccepts = accepts
        self.lua.execute('''
            local enqueue=UIRequest
            UIRequest=function(t)
                if t.type==1306 or t.type==1307 then assert(nativeAccepts(t),'native throttle dropped request') end
                enqueue(t)
            end
            for _,speed in ipairs({1,3,10}) do for _,mode in ipairs({'progress','sweep'}) do
                wallClock=wallClock+100
                assert(nativeAccepts({type=mode=='sweep' and 1307 or 1306})) -- 同API刚有手动请求。
                attach(copies(mode=='sweep' and 3 or 0,0,0));start(mode)
                local began=wallClock;local count=#requests
                for i=1,1000 do tickSeconds=layer.autoCopyTimer.action.delay/speed;layer.autoCopyTimer:fire(tickSeconds)
                    if #requests>count then break end end
                assert(wallClock-began>=3.1 and requests[#requests].type==1300)
                respond();assert(requests[#requests].type==(mode=='sweep' and 1307 or 1306))
                began=wallClock;count=#requests
                for i=1,1000 do layer.autoCopyTimer:fire(layer.autoCopyTimer.action.delay/speed)
                    if not AutoCopyIsRunning() then break end end
                assert(wallClock-began>=20 and #requests==count and AutoCopyBlockManual())
                respond();assert(not AutoCopyBlockManual())
            end end
        ''')

    def network(self):
        lua = self.runtime()
        lua.execute('''
            print,cclog,printT,printf=function() end,function() end,function() end,function() end
            local function message() return {ids={},SerializeToString=function(self) return self.ids end,
                ParseFromString=function(self,data) for k,v in pairs(data) do self[k]=v end end} end
            package.preload.ids_pb=function() return {Ids=message} end
            package.preload.result_pb=function() return {Result=message} end
            package.preload.copyattack_pb=function() return {CopyAttack=function()
                return {SerializeToString=function(self) return {map=self.map,point=self.point} end} end} end
            package.preload.copies_pb=function() return {Copies=message} end
            package.preload.battleresult_pb=function() return {BattleResult=message} end
            for _,name in ipairs({'somethings_pb','copyall3starreward_pb','params_pb','error_pb','GameRecharge','PickBattleResultReport'}) do
                package.preload[name]=function() return {} end
            end
            package.preload.logError=function() return {errorMessage={}} end
            table.copy=function(t) local r={} for k,v in pairs(t) do r[k]=type(v)=='table' and table.copy(v) or v end return r end
            table.getTableLength=function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
            UIResponse=function() end;initPb=function(_,fd) return fd.rbuf end
            gamedata={ext={},cache={role={stamina=50,gold=1000,level=16,vip=0},slots={},vipstatus={b_physical=0},
                copy={[42101]={id=42101,pa1=3,pa2=3,pa3=3,points={[1]={id=1,star=3,kill=0}}}}},
                config={global_kv={basic_buy_stamina={value=50},basic_buy_energy={value=10}},
                    copy={['42101']={['1']={physical=5,challenge=3,xp=10,coin=100}}},
                    map={['42101']={section=40001,star1=3,star2=6,star3=9}},section={['40001']={name='test'}}}}
            function gamedata.config:getConfigByName(name) return self[name] end
            function gamedata:time() return 1000 end
            function gamedata:updateRoleGold(n) self.cache.role.gold=self.cache.role.gold+n end
            function gamedata:updateRoleStamina(n) self.cache.role.stamina=self.cache.role.stamina+n end
            function gamedata:Vipstatus(ids) self.cache.vipstatus={b_physical=ids[2]} end
            function gamedata:Copies() end
            function gamedata:SomethingProcess() return {} end
            function gamedata:updateRoleExp() return {oldlevel=16,newlevel=16} end
            function gamedata:Encounters() return {} end
            function gamedata:Generals() end
            function gamedata:GeneralsEXP() return {} end
        ''')
        lua.execute(self.scripts["assets/scripts/GameRecharge.so"])
        lua.execute(self.scripts["assets/scripts/GameCopy.so"])
        lua.execute(self.scripts["assets/common_lua/GameErrorMessage.so"])
        return lua

    def test_network_serializes_manual_and_automatic_mutations_and_preserves_native_costs(self):
        lua = self.network()
        lua.execute('''
            local remote,op,body=UIUserBuyCallBack({type=301,cid=2,count=1,gold=50,local_auto_copy=17})
            assert(remote==1 and op==301 and body[1]==2 and body[2]==1 and body[3]==50)
            for _,send in ipairs({UICopyWipe2Callback,UICopyResetKillCallback,UICopyAttack2Callback,UIUserBuyCallBack}) do
                assert(send({type=1305,map=42101,point=1})==0)
            end
            assert(gamedata.ext.UserBuyDatagold==50 and gamedata.ext.UserBuyDatacid==2)
            local t=NetUserBuyCallBack({rbuf={}})
            assert(t.localAutoCopy==17 and t.localAutoRole.stamina==100 and gamedata.cache.role.gold==950)
            assert(not gamedata.ext.localAutoCopyBusy)
            assert(UICopyResetKillCallback({type=1305,map=42101,point=1,local_auto_copy=18})==1)
            t=NetCopyResetKillCallback({rbuf={}})
            assert(t.localAutoCopy==18 and t.map==42101 and t.point==1 and gamedata.cache.role.gold==935)
            assert(UICopyWipe2Callback({type=1307,map=42101,point=1,method=0,exchange=0,local_auto_copy=19})==1)
            t=NetCopyWipe2Callback({rbuf={reward={},generals={},encounters={},exp={generals={{exp=10}}}}})
            assert(t.localAutoCopy==19 and t.map==42101 and t.localAutoRole.stamina==95)
            assert(gamedata.cache.copy[42101].points[1].kill==1 and gamedata.cache.role.gold==935)
            local before=gamedata.cache.role.stamina
            t=NetCopyWipe2Callback({rbuf={}});assert(t.localAutoCopyIgnored and gamedata.cache.role.stamina==before)
            assert(UIUserBuyCallBack({type=301,cid=2,count=1,gold=50})==1)
            t=NetUserBuyCallBack({rbuf={}});assert(not t.localAutoCopy and gamedata.cache.role.gold==885)
        ''')

    def test_read_fifo_unsolicited_push_and_matching_errors_keep_other_contexts(self):
        lua = self.network()
        lua.execute('''
            UIVipStatusCallBack({type=300});UIVipStatusCallBack({type=300,local_auto_copy=21})
            local t=NetVipStatusCallBack({ser=0,rbuf={ids={0,0}}});assert(not t.localAutoCopy)
            t=NetVipStatusCallBack({ser=1,rbuf={ids={0,0}}});assert(not t.localAutoCopy)
            t=NetVipStatusCallBack({ser=2,rbuf={ids={0,1}}});assert(t.localAutoCopy==21)
            UICopyQueryCallback({type=1300,update=true,local_auto_copy=22})
            t=NetCopyQueryCallback({ser=0,rbuf={}});assert(not t.localAutoCopy)
            t=NetCopyQueryCallback({ser=3,rbuf={}});assert(t.localAutoCopy==22)
            UIUserBuyCallBack({type=301,cid=2,count=1,gold=50,local_auto_copy=23})
            t=NetErrorMessageCallback9({rbuf={ids={1305,0}}})
            assert(not t.localAutoCopy and gamedata.ext.localAutoCopyBusy.type==301)
            t=NetErrorMessageCallback9({rbuf={ids={301,0}}})
            assert(t.localAutoCopy==23 and not gamedata.ext.localAutoCopyBusy and gamedata.cache.role.gold==1000)
            gamedata.cache.role.stamina=0
            local remote,op,err=UICopyAttack2Callback({type=1306,map=42101,point=1,local_auto_copy=24})
            assert(remote==0 and op==503 and err.localAutoCopy==24 and err.localAutoOpcode==1306)
            assert(not gamedata.ext.localAutoCopyBusy)
        ''')


if __name__ == "__main__":
    unittest.main()
