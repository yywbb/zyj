--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-8-22
-- Time: 下午5:05
-- To change this template use File | Settings | File Templates.
--


local deviceApi = require"device"
function setLoginServerListTable(t)

    if t.uid < 0 then
        runGamePrompt({msg="登录失败，请稍等"})
        if LoginScene.enterLayerItem.channel_login then
            local sequencepre = CCSequence:createWithTwoActions(CCDelayTime:create(10), CCCallFunc:create(function() 
                    loading:restart() 
                end))
            LoginScene.enterLayerItem.channel_login:runAction(sequencepre)
            LoginScene.enterLayerItem.channel_login:addHandleOfControlEvent(function()
                runGamePrompt({msg="处理中，请稍等"})
            end, CCControlEventTouchUpInside)
        end
        return
    end

    if t.user == "" and table.getTableLength(t.serverslist) == 0 then
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

        printT(t)
        local device = require"device"
        local sdk = require"SDKfunction"
        if sdk:isValid() then
            if gamedata.device.channel == "huawei" then
                print("huawei loginsuccess")
                sdk:loginSuccess();
            elseif gamedata.device.channel == "chujiani" or gamedata.device.channel == "chujianii" or gamedata.device.channel == "anfengbz" or gamedata.device.channel == "anfengsw" or gamedata.device.channel == "anfengfk" or gamedata.device.channel == "anfengjj"
                or gamedata.device.channel == "anfengswhd" or gamedata.device.channel == "anfengsgy" or gamedata.device.channel == "hanfengfg"or gamedata.device.channel == "hanfengdq" or gamedata.device.channel == "anfengwd" or gamedata.device.channel == "anfengygn" 
                or gamedata.device.channel == "anfengswg" or gamedata.device.channel == "fanzuozyj" or gamedata.device.channel == "muyouzyj" or gamedata.device.channel == "zuoyaojiapple" or gamedata.device.channel == "zuoyaojihdios" or gamedata.device.channel == "YYLAppStore" 
                or gamedata.device.channel == "zuoyaojihdios2" or gamedata.device.channel == "zuoyaojiapple2" or  gamedata.device.channel == "muyoutg" or gamedata.device.channel == "muyoughqnxs"  or string.find(gamedata.device.channel,"muyoutg_")~=nil then

                print("chujiani loginsuccess")
                if t.user == "0" then
                    print("loginsuccess----")
                    sdk:loginAccountSuc(tostring(t.uid));
                end
            elseif string.find(gamedata.device.channel,"qq")~=nil or string.find(gamedata.device.channel,"weixin")~=nil  or string.find(gamedata.device.channel,"tencent")~=nil then
                gamedata.sdk.channel.loginId = 1
            else

                if t.user and t.user == "0" then
                    print("loginsuccess----")
                    sdk:loginAccountSuc(tostring(t.uid));
                end 
                
            end
        end

        if LoginScene.status then
            LoginScene:showEnter(t)
            if gamedata.sdk:isValid() then
                local device = require"device"
                if gamedata.device.channel == "linnyou" or  gamedata.device.channel == "hanfenga" or  gamedata.device.channel == "beiyouaQM" then
                    cclog("umen setUserInfo 1 uid:%s",GameScene.guid)
                    -- sdk:LoginToken();
                    gamedata.sdk.LoginToken(GameScene.guid)
                elseif gamedata.device.channel == "x7syn" then
                    if gamedata.device.platform=="android" then
                        cclog("umen setUserInfo 1 uid:%s",GameScene.guid)
                        -- sdk:LoginToken();
                        gamedata.sdk.LoginToken(GameScene.guid)
                    else
                        cclog("UILogin:loginToken:guid",GameScene)
                        sdk:LoginTokenIos(GameScene.guid)
                    end
                    
                else
                    gamedata.sdk.LoginToken(t.user)
                end
            end


            if t.uid then

                cclog("umen setUserInfo 2 uid:%d",t.uid)
                LoginScene.roleuid = t.uid
               
            end
        end
    end
end

function selectServerIDResult(t)
    print("selectServerIDResult: type=", t.type, "section=", t.section,  " sid=", t.sid)

    if tostring(t.sid) == "0" then
        runGamePrompt({msg = "当前区服爆满，请选择其他区"})
        if LoginScene.status then
            LoginScene:showEnter()
        end
        return
    elseif tostring(t.sid) == "1" then
        runGamePrompt({msg = "当前区服繁忙，请稍后尝试"})
        if LoginScene.status then
            LoginScene:showEnter()
        end
        return
    elseif tostring(t.sid) == "2" then
        runGamePrompt({msg = "该区注册角色已满，请选择其他区服创建角色"})
        if LoginScene.status then
            LoginScene:showEnter()
        end
        return
    elseif tostring(t.sid) == "3" then
        local min = math.ceil(t.section/60)
        local hour = math.modf(min/60)
        min = math.mod(min,60)
        local time = (hour>0 and hour.."小时" or "")..(min>0 and min.."分钟" or "")
        if gamedata.sdk.idCardStatus and gamedata.sdk.idCardStatus ==0 then
            gameWindowslogin:openWindow("shiming",{page = "renzheng2",data = "请进行实名认证或"..time.."后登录游戏"})
        else
            gameWindowslogin:openWindow("shiming",{page = "tishi3",des = "请"..time.."后登录游戏"})
        end
        if LoginScene.status then
            LoginScene:showEnter()
        end
        return
    elseif tostring(t.sid) == "4" then
        runGamePrompt({msg = "游客区已满，请使用正式账号进行游戏,可在《浮动图标》的个人中心设置为正式账号"})
        if LoginScene.status then
            LoginScene:showEnter()
        end
        return
    elseif tostring(t.sid) == "5" then
        if LoginScene.status then
            LoginScene:showEnter()
        end
        loading:exitGame("当前区服爆满",true)
        return
    end 

    UIRequest({ type = 999 })
    
    print(gamedata.device.platform)
    if gamedata.device.platform=="android" then
        UIRequest({
            type = 999906,
            infos = {
                gamedata.device.platform,
                gamedata.device.model,
                gamedata.device.getsystemVersion(),
                gamedata.device.getSimState(),
                gamedata.device.getPhoneType(),
            },
        })
    end

    local configupdater = require"accconfigupdate"
    configupdater:checkifneedupdate({section=t.section})
    --return 1, { type = 2 }
end

function UIunzip(t)
    if t.opt and t.opt=="config" then
        local configupdater = require"accconfigupdate"
        configupdater:unzipcomplete()
    end
end

function setLoginPercentFromServer(t)
    if LoginScene then

    end
end

function judgeLoginNewUserIsValid(t)
    print("新账户注册结果10， 接受客户端数据")
    printT(t)
    if LoginScene.status then
        LoginScene:UserInputResult(t)
    end
end

function judgeLoginUserAccountIsValid(t)
    print("账户登陆结果11， 接受客户端数据")
    printT(t)
    if LoginScene.status then
        LoginScene:UserInputResult(t)
    end
end

function judgeLoginChangePwdIsValid(t)
    if LoginScene then

    end
end


function sendNetError()
    require("sqlite3init")
    local mydb = SQLite3Open()
    if nil == mydb then
        return nil
    end

    local SQL_ = string.format("select count(*) as texist from sqlite_master where type='table' and name='%s'", "ErrorInfoTable");
    local ret = 0
    for row in mydb:nrows(SQL_) do
        ret = row["texist"]
    end
    if ret == 0 then
        return nil
    end


    local SQL = "SELECT  KEY, VALUE FROM ErrorInfoTable where KEY = 'neterror'"
    local errorinfo = ""
    for row in mydb:rows(SQL) do
        errorinfo = row[2]
    end

    local SQL2 = "UPDATE ErrorInfoTable set VALUE='' where KEY = 'neterror'";
    mydb:exec(SQL2)

    mydb:close()
    print("sendNetError",errorinfo)

    if errorinfo ~= "" then
        UIRequest({type=999988, msg=errorinfo, from="net",noneedfix = true})
    end

end


function judgeSelectedServerIDValid(t)
    print("账户登陆结果1000， 接受客户端数据")
    printT(t)

    if t.location ~= 0 then
        if t.location == 99999 then
            loading:exitGame("您的账号有可疑操作，暂时被系统停封")
--            local cb = function()
--                if deviceApi.platform == "android" then
--                    local luaj = require"luaj"
--                    --local javaClassName = "com/ldfs/sanguo/AndroidUtils"
--                    --local javaClassName = "com/ldfs/sanguo2/AndroidUtils"
--                    local javaClassName = gameConfig.AD_packageName.."/AndroidUtils"
--                    local javaMethodName = "SystemExit"
--                    local javaMethodSig = "()V"
--                    luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
--                else
--                    local myfile = require"myfile"
--                    myfile.osexit()
--                end
--            end
--            gameWindowslogin:openWindow("loginPrompt",nil,cb)
            return
        else
            if LoginScene.status then
                LoginScene:waiting(t)
            end
        end
    else
        local device = require"device"
        local sdk = require"SDKfunction"
        if sdk:isValid() and string.find(device.channel,"qq")~=nil or string.find(device.channel,"weixin")~=nil  or string.find(device.channel,"tencent")~=nil then
                print("tencent loginsuccess")
                sdk:loginSuccess();
        else
            if LoginScene.status or not LoginScene.isrelog then
                print("qita loginsuccess")
                LoginScene:checkGuide()
            end
            LoginScene.isrelog = true
        end
        -- if gameTimer then
        --     gameTimer:startheartCheck()
        -- end

    end

    UIRequest({type = 999905})
    UIRequest({type = 999907})

    sendNetError()

end

function UITCLoginResult(t)
    print("账户登陆结果10000， 接受腾讯登录数据")
    
    if LoginScene.status or not LoginScene.isrelog then
        LoginScene:checkGuide()
        LoginScene.isrelog = true
    end
end

function UITCLoginResult2(t)
    print("账户登陆结果10002， 接受腾讯登录数据")
    
    if LoginScene.status or not LoginScene.isrelog then
        LoginScene:checkGuide()
        LoginScene.isrelog = true
    end
end


function configUpdateFinished(t)

    --UIRequest({ type = 999 })
    UIRequest({ type = 1000 })
    UIResponse({type = 9998, log2 = "" })

    print(gamedata.device.platform)
    if gamedata.device.platform=="android" then
        UIRequest({
            type = 999906,
            infos = {
                gamedata.device.platform,
                gamedata.device.model,
                gamedata.device.getsystemVersion(),
                gamedata.device.getSimState(),
                gamedata.device.getPhoneType(),
            },
        })
    end
end

--获取guid
function UIGetGuid(t)
    print("获取ppsdk guid")
    printT(t)
    GameScene.guid = t.guid or ""
    GameScene.guidname = t.guidname or ""
end

function UIEventPost(t)
    print("登陆公告")
    printT(t)

    local continueCB = function() UIRequest({ type = 81 }) end

    --local exitCB = function() loading:exitGame("本次更新需重启游戏")  end

    local resourceCB = function()
        if t.needupdate == 1 then
            --todo 打开网络环境弹窗  continueCB 为回调
            if t.length < 1048576 then
                continueCB()
            else
                UIResponse({type = 9998, log = "" })
                gameWindowslogin:openWindow("downloadUpdate",{length = t.length},continueCB)
            end
        else
            continueCB()
        end
    end

    if next(t.event) then
        --todo 打开事件弹窗弹窗  resourceCB 为回调
        gameWindowslogin:openWindow("versionUpdate",t.event,resourceCB)

    else
        resourceCB()
    end
end

function addNetError(error)
    print("addNetError",error)
    require("sqlite3init")
    local mydb = SQLite3Open()
    if nil == mydb then
        return nil
    end

    local SQL_ = string.format("select count(*) as texist from sqlite_master where type='table' and name='%s'", "ErrorInfoTable");
    local ret = 0
    for row in mydb:nrows(SQL_) do
        ret = row["texist"]
    end
    if ret == 0 then
        return nil
    end

    local SQL = "SELECT  KEY, VALUE FROM ErrorInfoTable where KEY = 'neterror'"
    local errorinfo = os.date("%c").." "..error
    for row in mydb:rows(SQL) do
        errorinfo = row[2]..";  \n"..errorinfo
    end

    print("addNetError2",errorinfo)

    local SQL2 = "UPDATE ErrorInfoTable set VALUE='" .. errorinfo .. "' where KEY = 'neterror'";
    mydb:exec(SQL2)

    mydb:close()
end

local loginprocess = 0

function UIshowloginlog(t)
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
            else
                LoginScene:showNode(LoginScene.enterLayerItem.loadingNode,true)
                LoginScene:showNode(LoginScene.enterLayerItem.processNode,true)
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

    if t.version and LoginScene and LoginScene.status and LoginScene.enterLayerItem and LoginScene.enterLayerItem.gameversion then
        LoginScene.enterLayerItem.gameversion:setString(t.version or "")
    end

    if t.error and t.error ~= "" then
        addNetError(t.error)
    end
end


function UIResourceUpdateFinish(t)
    print("资源更新完成")
    loading:restart()
    --loading:exitGame("本次更新需重启游戏",true)
end

function UIHeartCheck(t)
    if gameTimer then
        gameTimer:reciveheartCheck()
    end
end

function UILogout(t)

    loading:restart()

    -- if gamedata.sdk and gamedata.sdk.channel then
    --     gamedata.sdk.channel.userid = nil
    --     gamedata.sdk.channel.ucid = nil
    -- end
    -- if LoginScene.status then
    --     if not LoginScene.enterLayer  then
    --         LoginScene:clear()
    --         bRunWithScene = false
    --         LoginScene:init(loginScene)
    --         UIRequest({type =1})
    --     else
    --         LoginScene:reset()
    --         bRunWithScene = false
    --         UIRequest({type =1})
    --     end
    -- else
    --     guide:clear()
    --     gameWindows:closeAllWindowDirect()
    --     if battleScene.show then
    --         battleScene.callback = nil
    --         battleScene:clear()
    --     end
    --     GameScene:clear()
    --     ui.itemcache:removeAllSkeletons()

    --     gameTimer:UnrigistAll()
    --     gameTouch:clear()
    --     bRunWithScene = false
    --     LoginScene:init(loginScene,true)
    --     UIRequest({type =1})
    -- end

    -- if gamedata.music then
    --     gamedata.music:GameStart()
    -- end
end

function UIrestart(t)
    print("UIrestart")
    loading:restart(true)
end
  FB  