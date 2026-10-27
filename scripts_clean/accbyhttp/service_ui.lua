--
-- Created by IntelliJ IDEA.
-- User: lichungeng
-- Date: 16/8/31
-- Time: 下午2:09
-- To change this template use File | Settings | File Templates.
--

local uiqueue = require("uiqueue")
require"UILoadConfig"

local deadtime = 0

local resourceupdate = require"accbyhttp/http_updateresource"
local serverinfoupdate = require"accbyhttp/http_updateServerInfo"
local configupdate = require"accbyhttp/http_updateconfig"
local posthandler = require"accbyhttp/http_post"
local loginhandler = require"accbyhttp/http_login"
local entergame = require"accbyhttp/http_entergame"
local checkpackage = require"accbyhttp/http_checkpackage"

local function uigamestart( t )
    print("游戏启动")

    posthandler:checkpost()
end

local function uipost( t )
    print("登陆公告")
    printT(t)

    local function callback()
        resourceupdate:checkifneedupdate()
    end

    if next(t.event) then
        --todo 打开事件弹窗弹窗  resourceCB 为回调
        gameWindowslogin:openWindow("versionUpdate",t.event,callback)
    else
        callback()
    end
end

local function uiresouceunzip( t )
    print("资源解压完成")
    resourceupdate:unzipcomplete() 
end

local function uiresoucecomplete( t )
    print("资源更新完成")
    checkpackage:checkisvalid() 
end

local function checkpackagecomplete( t )
    print("包体检查完成")
    serverinfoupdate:checkifneedupdate()
end

local function uiserverinfocomplete( t )
    print("服务器信息更新完成")

    local gameversion = require"config_version"
    if gameversion.showversion then 
        gameversion:showversion()
    end

    texture = require"texture" -- plist资源管理
    require"setSpriteFrame" -- 设置帧相关的方法

    require"Prompts"

    GameScene = require"GameScene"
    if not mainScene then
        mainScene = CCScene:create()
        mainScene:retain()
    end
    gameConfig:addScreenSide(mainScene)

    battleScene = require"battleScene"
    if not bScene then
        bScene = CCScene:create()
        bScene:retain()
    end
    gameConfig:addScreenSide(bScene)

    guide = require"guide"

    gameTouch = require"GameTouch"
    gameTouch:init()

    gameWindows = require"GameWindows"
    gameWindows:init()

    texture:LoadPublic()
    LoginScene:showNode(LoginScene.enterLayerItem.processNode,false)

    UIResponse({type=900})
end

function uisdklogin( t )
    gamedata.sdk:Login()
    LoginScene:showNode(LoginScene.enterLayerItem.channel_loginnode,true)
end

local function uisdklogincallback( t )
    print("sdk登录完成")
    printT(t)

    --都没有值才不登录（奇遇的是其中一个没有值都不登录）
    if (not t.sessionId or t.sessionId =="")
    and  (not t.uin or t.uin == "")  then
        runGamePrompt({msg="登录失败，请重试"})
        LoginScene:showNode(LoginScene.enterLayerItem.channel_loginnode,true)
        return
    end
    
    LoginScene:showNode(LoginScene.enterLayerItem.channel_loginnode,false)

    gamedata.sdk.channel.uid = t.nickname or ""
    gamedata.sdk.channel.uuid = t.sessionId
    gamedata.sdk.channel.ucid = t.uin
    gamedata.sdk.channel.loginId = t.loginId or 1
    gamedata.sdk.channel.channelid = t.channelid or ""
    gamedata.sdk.channel.channelname = t.channelname or ""


    if (gamedata.gameconfig.channelid and gamedata.gameconfig.channelid ~= "") then
        gamedata.sdk.channel.channelid = gamedata.gameconfig.channelid
        t.channelid = gamedata.gameconfig.channelid
    end

    if (gamedata.gameconfig.channel and gamedata.gameconfig.channel ~= "") then
        gamedata.sdk.channel.channelname = gamedata.gameconfig.channel or ""
        t.channelname = gamedata.gameconfig.channel
    end



    loginhandler:login({
            uin         = t.uin,
            sessionid   = t.sessionId,
            nickname    = t.nickname,
            channelname = t.channelname,
            channelid   = t.channelid,
            uuid        = gamedata.device.getOpenUDID(),
            device      = gamedata.device.model,
            os          = gamedata.device.platform,
            version     = gamedata.device.getsystemVersion(),
        })
end

local function loginsuccess( t )
    print("游戏登录完成")
    printT(t)

    gamedata.session = t.session
    gamedata.serverlist = t.serverlist
    gamedata.age = t.age
    gamedata.holidays = t.holidays
    gamedata.onlinetime = t.onlinetime

    if t.user == "" and table.getTableLength(t.serverlist) == 0 then
        if gamedata.sdk.channel then
            cclog("AndroidSDK_common.changeUser 7")
            gamedata.sdk:changeUser()
        else
            if LoginScene.status then
                LoginScene:showEnter(t)
                if t.uid then

                    cclog("umen setUserInfo 1 uid:%d",t.uid)
                    LoginScene.roleuid = t.uid
                    
                end
            end
        end
    else
        if MYGameSendData then
            MYGameSendData:SendLogin(t.uid)
        end

        if sdk:isValid() then
            --整改
            sdk:loginSuccess(t)
            -- if gamedata.device.channel == "huawei" then
            --     print("huawei loginsuccess")
            --     sdk:loginSuccess();
            -- elseif gamedata.device.channel == "chujiani" or gamedata.device.channel == "chujianii" or gamedata.device.channel == "anfengbz" or gamedata.device.channel == "anfengsw" or gamedata.device.channel == "anfengfk" or gamedata.device.channel == "anfengjj"
            --     or gamedata.device.channel == "anfengswhd" or gamedata.device.channel == "anfengsgy" or gamedata.device.channel == "hanfengfg"or gamedata.device.channel == "hanfengdq" or gamedata.device.channel == "anfengwd" or gamedata.device.channel == "anfengygn" 
            --     or gamedata.device.channel == "anfengswg" or gamedata.device.channel == "fanzuozyj" or gamedata.device.channel == "muyouzyj" or gamedata.device.channel == "zuoyaojiapple" or gamedata.device.channel == "zuoyaojihdios" or gamedata.device.channel == "YYLAppStore" 
            --     or gamedata.device.channel == "zuoyaojihdios2" or gamedata.device.channel == "zuoyaojiapple2" or  gamedata.device.channel == "muyoutg" or gamedata.device.channel == "muyoughqnxs"  or string.find(gamedata.device.channel,"muyoutg_")~=nil then

            --     print("chujiani loginsuccess")
            --     if t.first then
            --         print("loginsuccess----")
            --         sdk:loginAccountSuc(tostring(t.uid));
            --     end
            -- elseif string.find(gamedata.device.channel,"qq")~=nil or string.find(gamedata.device.channel,"weixin")~=nil  or string.find(gamedata.device.channel,"tencent")~=nil then
            --     gamedata.sdk.channel.loginId = 1
            -- else

            -- end
        end

        if LoginScene.status then
            LoginScene:showEnter(t)
            if sdk:isValid() then

                --整改
                local guid = t.guid
                if guid then
                    cclog("guid:"..guid)
                    GameScene.guid = guid or ""
                    GameScene.guidname =  ""
                    sdk:LoginToken(guid)
                end    
                -- local device = require"device"
                -- if gamedata.device.channel == "linnyou" or  gamedata.device.channel == "hanfenga" or  gamedata.device.channel == "beiyouaQM" then
                --     cclog("umen setUserInfo 1 uid:%s",GameScene.guid)
                --     -- sdk:LoginToken();
                --     gamedata.sdk.LoginToken(GameScene.guid)
                -- elseif gamedata.device.channel == "x7syn" then
                --     if gamedata.device.platform=="android" then
                --         cclog("umen setUserInfo 1 uid:%s",GameScene.guid)
                --         -- sdk:LoginToken();
                --         gamedata.sdk.LoginToken(GameScene.guid)
                --     else
                --         cclog("UILogin:loginToken:guid",GameScene)
                --         sdk:LoginTokenIos(GameScene.guid)
                --     end
                    
                -- else
                --     gamedata.sdk.LoginToken(t.user)
                -- end


            end


            if t.uid then

                cclog("umen setUserInfo 2 uid:%d",t.uid)
                LoginScene.roleuid = t.uid
               
            end
        end
    end

    deadtime = gamedata:time()
end

local function selectServersuccess( t )
    print("进入游戏完成")
    printT(t)

    gamedata.uuid = t.uuid
    configupdate:checkifneedupdate({section=t.section})
    deadtime = 0
end

local function uifangchengmi( t )
    local min = math.ceil(t.time/60)
    local hour = math.modf(min/60)
    min = math.mod(min,60)
    local time = (hour>0 and hour.."小时" or "")..(min>0 and min.."分钟" or "")
    if gamedata.sdk.idCardStatus and gamedata.sdk.idCardStatus ==0 then
        gameWindowslogin:openWindow("shiming",{page = "renzheng2",data = "请进行实名认证后登录游戏"})
    else
        gameWindowslogin:openWindow("shiming",{page = "tishi",des = t.msg})
    end
    deadtime = 0
end 

local function selectServerfail( t )
    print("进入游戏失败")
    printT(t)
    if LoginScene.status then
        LoginScene:showEnter()
    end
end

local function uiconfigunzip( t )
    print("配置解压完成")
    printT(t)
    configupdate:unzipcomplete() 
end

local function UIRoleShowNew(t)
    print("New请求角色信息1001 接收客户端返回数据")
    --printT(t)

    if t.param == "first" then
        local device = require"device"

        return
    end

    if t.info then
        GameScene:setRoleInfo(t.info)

        --uc专用的信息
        local params = {}
        local serverInfo = gameWindows.windows["roleinfo"].module.SelectedServer  --获取服务器的基本数据
        print("t.info------------------------")
        printT(t.info)
        params.roleId = t.info.id   --玩家ID
        params.roleName = t.info.name  --玩家名字
        params.roleLv = t.info.level   --玩家等级
        params.serverId = serverInfo.id   --服务器ID
        params.severName = serverInfo.name  --服务器名字
        params.vip = t.info.vip  --等级
        params.gold = t.info.gold   --玩家元宝
        params.roleuid = LoginScene.roleuid  --玩家uid

        if GameScene.guid then
         params.paltformGuid = GameScene.guid --平台id
        end
        
        if sdk:isValid() then
            local device = require"device"
            
            --整改
            if GameScene.guid then
                params.platformId = GameScene.guid
            end
            if GameScene.guidname then
                params.platforName = GameScene.guidname
            end
            sdk:UserInformation(params)

            -- if device.channel == "360" or device.channel == "coolpad" then
            --     params.platformId = GameScene.guid  --平台的id
            --     params.platforName = GameScene.guidname  --平台的名字
            --     printT(params)
            --     sdk:UserInformation(params)
            -- elseif string.find(device.channel,"qq")~=nil or string.find(device.channel,"weixin")~=nil  or string.find(device.channel,"tencent")~=nil then
            --     local luaj = require "luaj"
            --     local javaClassName = gameConfig.AD_packageName .. "/CommonSDK_Utils"
            --     local javaMethodName = "UserInformation"
                -- local javaParams = { string.format("%d", params.roleuid), params.roleName, string.format("%d", params.roleLv), params.serverId <= 2 and 1 or params.serverId, params.severName }
            --     local javaMethodSig = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;ILjava/lang/String;)V"
            --     luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig);
            -- else
            --     printT(params)
            --     sdk:UserInformation(params)
            -- end


        end
    end

    if t.param == "role_info" then
        gameTimer:rigistTime("staminanext",t.info["staminanext"])
        gameTimer:rigistTime("staminaall",t.info["staminaall"])
        gameTimer:rigistTime("energynext",t.info["energynext"])
        gameTimer:rigistTime("energyall",t.info["energyall"])
        gameWindows:openWindow("roleinfo",t.info,nil)
    end

    if t.param == "resume" then
        if t.info then
            if gameWindows.windows["roleinfo"].show then
                gameTimer:rigistTime("staminanext",t.info["staminanext"])
                gameTimer:rigistTime("staminaall",t.info["staminaall"])
                gameTimer:rigistTime("energynext",t.info["energynext"])
                gameTimer:rigistTime("energyall",t.info["energyall"])
                gameWindows:openWindow("roleinfo",t.info,nil)
            end
        else
            UIRequest({type = 1001,param = "resume"})
        end

    end

    if roleupdatacallback then
        roleupdatacallback()
        roleupdatacallback = nil
    end

    if t.info and (t.info.coin<0 or t.info.gold<0 or t.info.stamina<0 or t.info.energy<0) then
        UIRequest({type = 1001,param = "error"})
    end
    if gameWindows.windows["robselect"].show then
        gameWindows.windows["robselect"].module:reloadEnergy()
    end
    return 0, nil
end

local function UIInitGeneralNew(t)
    print("New选择初始武将202，接受客户端数据")

    if t.isfirst then
        local sdk = gamedata.sdk
        if sdk:isValid() then
            sdk:CreateRole(guide.first.name)
        end
        LoginScene:initrequest("afterselect")
    else

    end
end

local function uiconfigcomplete( t )
    print("配置更新完成")
    printT(t)

    pauseaccUIUpdate()

    UIRequest({ 
            type = 999, 
            uuid = gamedata.uuid,
            server = LoginScene.SelectedServer,
        })

    UIResponse({type=888888})

    UIRequest({ type = 1000 })
    UIResponse({type = 9998, log2 = "" })

    require"UIRole"
    UIRoleShow = UIRoleShowNew
        
    require"UIGuide"
    UIInitGeneral = UIInitGeneralNew

    require"UIUpdate"
    UILoginShow = function() end
end

local function uiprompt( t )
    if t.msgtype == "restartgame" then
        loading:exitGame(t.msg or "",true)
    end
end

local loginprocess = 0

local function uiloginlog(t)
    print("loginprocess",loginprocess)
    printT(t,"login log")
    if t.log and  LoginScene and LoginScene.status and LoginScene.enterLayerItem and LoginScene.enterLayerItem.logstatus then
        if t.log=="" then
            LoginScene.enterLayerItem.logstatus:setString("")
            LoginScene:showNode(LoginScene.enterLayerItem.loadingNode,false)
            LoginScene:showNode(LoginScene.enterLayerItem.processNode,false)            
        else
            LoginScene.enterLayerItem.logstatus:setString(t.log)
            if string.find(t.log,"渠道登录") then
                LoginScene:showNode(LoginScene.enterLayerItem.loadingNode,false)
                LoginScene:showNode(LoginScene.enterLayerItem.processNode,false)      
                if gamedata.sdk.isShowUserAgreement then 
                    LoginScene:showNode(LoginScene.enterLayerItem.userAgreement,true)      
                end
            else
                
                if gamedata.audit_state and gamedata.audit_state ~= "true" then
                    LoginScene:showNode(LoginScene.enterLayerItem.loadingNode,true)
                    LoginScene:showNode(LoginScene.enterLayerItem.processNode,true)
                end

                LoginScene:showNode(LoginScene.enterLayerItem.loadingNode,true)
                LoginScene:showNode(LoginScene.enterLayerItem.processNode,true)
                LoginScene:showNode(LoginScene.enterLayerItem.userAgreement,false)  
                loginprocess = loginprocess + 1
                local porcess = math.mod(loginprocess,2)==1 and math.random(1,90)/100 or 1
                ui.setLabelString(LoginScene.enterLayerItem.tip,t.log,13)
                ui.setLabelString(LoginScene.enterLayerItem.persentage,"",13)
                ui.setSpriteTextureRect2(LoginScene.enterLayerItem.resourceprocess,0,0,921*porcess,33)
            end
        end
    end

    if t.log2 and LoginScene and LoginScene.status and LoginScene.processLayerItem and LoginScene.processLayerItem.log then
        LoginScene.processLayerItem.log:setString(t.log2 or "")
    end
end

local function uirestart( t )
    print("uirestart")
    sdk:loginOutStatusRest()
    loading:restart(true)
end 

local function uilogout( t )
    loading:restart()
end

local function uiLuaerror(t)
    if t.redirect and t.redirect==1 then
        runGamePrompt({msg = "数据出错,请返回主界面"})
    end

    if t.needsend and MYGameSendData and MYGameSendData.SendErrorLog then
        local msg = string.gsub(t.msg,"=",":")
        MYGameSendData:SendErrorLog(t.from,msg)
    end
end

function LoginNewUserIsValid(t)
    print("新账户注册结果10， 接受客户端数据")
    printT(t)
    if LoginScene.status then
        LoginScene:UserInputResult(t)
    end
end

function LoginUserAccountIsValid(t)
    print("账户登陆结果11， 接受客户端数据")
    printT(t)
    if LoginScene.status then
        LoginScene:UserInputResult(t)
    end
end

local function uiidcardparam( t )
    print("uiidcardparam0")
    require"UIFangchenmi"
     print("uiidcardparam1")

     if gamedata.sdk then
        print("uiidcardparam------"..t.idCardStatus)
        gamedata.sdk.idCardStatus = tonumber(t.idCardStatus)
         print("uiidcardparam------gamedata.sdk:"..gamedata.sdk.idCardStatus)
    end

    UIIDCardParam(t)
    print("uiidcardparam2")
end

local acc_ui_callback = {
    [1] = uigamestart,
    [80] = uipost,

    [666666] = uiresouceunzip,
    [555555] = uiresoucecomplete,
    [333333] = checkpackagecomplete,
    [444444] = uiserverinfocomplete,
    [900] = uisdklogin,
    [901] = uisdklogincallback,

    [3] = loginsuccess,
    [5] = selectServersuccess,
    [6] = selectServerfail,
    [7] = uifangchengmi,

    [6666666] = uiconfigunzip,
    [500] = UILoadConfig,
    [4] = uiconfigcomplete,

    [503] = uiprompt,
    [9998] = uiloginlog,
    [777777] = uirestart,
    [999988] = uiLuaerror,
    [999911] = uilogout,
    [902] = uiidcardparam,

    [10] = LoginNewUserIsValid,
    [11] = LoginUserAccountIsValid,
}

function accuiupdate()

    local tret = uiqueue.popresponsefromclient()
    if tret ~= nil then
        local func = acc_ui_callback[tonumber(tret["type"], 10)]

        if nil ~= func then
            local func1,func2 = func,__G_TRACKBACK__
            local bcall, ret, body = xpcall(function() return func1(tret) end,func2)
        else
            cclog("accuiupdate type:%s invalid content:%s", tret["type"], tret)
        end
    end

    local now = gamedata:time()
    if deadtime>0 and now-deadtime>300 then
        loading:exitGame("本次登录失效，请重新登录",true)
    end
end

function startaccUIUpdate()
    if not accUpdateFunc then
        accUpdateFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(accuiupdate, 0, false)
    end
end

function pauseaccUIUpdate()
    if accUpdateFunc then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(accUpdateFunc)
        accUpdateFunc = nil
    end
end

startaccUIUpdate()

