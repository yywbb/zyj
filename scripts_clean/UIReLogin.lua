 --
-- Created by IntelliJ IDEA.
-- User: jutian
-- Date: 15/1/6
-- Time: 下午5:57
-- To change this template use File | Settings | File Templates.
--
local haslogined = false

function UISetLoginParam(t)
    print("UISetLoginParam")
    if gamedata.sdk then
        gamedata.sdk.channel.uid = t.nickname
        gamedata.sdk.channel.uuid = t.sessionId
        gamedata.sdk.channel.ucid = t.uin
        gamedata.sdk.channel.loginId = t.loginId or 1
        gamedata.sdk.channel.channelid = t.channelid or ""
        gamedata.sdk.channel.channelname = t.channelname or ""
    end

    if t.needlogin then
        if haslogined then return end

        print("UISetLoginParam 2")
        UIRequest({ 
            type = 90, 
            nickname = t.nickname, 
            sessionId = t.sessionId, 
            uin =t.uin, 
            messageNum = 99, 
            devicemodel = gamedata.device.model, 
            systemVersion = gamedata.device.systemVersion, 
            channelid = t.channelid or gamedata.device.channelid,
            channelname = t.channelname or gamedata.device.channel,
            })
        haslogined = true
    end
end

function UIReLogin(t)
    cclog("UI type:%d cmd:%s recv request from NET", t.type, "UIReLogin")
    if not gamedata.sdk then
        gamedata.sdk = require"SDKfunction"
        gamedata.sdk:SDKChannelName() 
        gamedata.sdk:Login()
    else
        if gamedata.sdk.channel and (gamedata.sdk.channel.userid or gamedata.sdk.channel.ucid) then
            if string.find(gamedata.device.channel,"qq")~=nil or string.find(gamedata.device.channel,"weixin")~=nil  or string.find(gamedata.device.channel,"tencent")~=nil then
                gamedata.sdk.channel.loginId = 0
            end
            sdk:reLogin()
        else
            if string.find(gamedata.device.channel,"qq")~=nil or string.find(gamedata.device.channel,"weixin")~=nil  or string.find(gamedata.device.channel,"tencent")~=nil then
                gamedata.sdk.channel.loginId = 1
            end
            sdk:Login()
        end   
    end
end

local haslogin = false

function UILoginShow(t)

    if haslogin then
        print("haslogin==",haslogin)
        UIReLoginShow(t)
        return
    end

    local gameversion = require"config_version"
    if gameversion.showversion then 
        gameversion:showversion()
    end


    -- 请求数据
    cclog("UI type:%d cmd:%s recv request from NET", t.type, "UILoginShow")

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

    loginWindows = require"GameWindowsLogin"
    loginWindows:init()
    if CCUserDefault:sharedUserDefault():getStringForKey("userAgreement") ~= "true" then
        loginWindows:openWindow("userAgreement",{},function()
            print("打开用户协议窗口")
        end)
    end


    gamedata.sdk:Login()

    LoginScene:showNode(LoginScene.enterLayerItem.processNode,false)
    -- LoginScene:showNode(LoginScene.enterLayerItem.enterNode,true)
    haslogin = true
end

function UIReLoginShow(t)

    local gameversion = require"config_version"
    if gameversion.showversion then 
        gameversion:showversion()
    end
    
    if not gamedata.sdk then
        gamedata.sdk = require"SDKfunction"
        gamedata.sdk:SDKChannelName() 
        gamedata.sdk:Login()
    else
       if gamedata.sdk.channel and (gamedata.sdk.channel.userid or gamedata.sdk.channel.ucid) then
            if string.find(gamedata.device.channel,"qq")~=nil or string.find(gamedata.device.channel,"weixin")~=nil  or string.find(gamedata.device.channel,"tencent")~=nil then
                gamedata.sdk.channel.loginId = 0
            end
            sdk:reLogin()
        else
            if string.find(gamedata.device.channel,"qq")~=nil or string.find(gamedata.device.channel,"weixin")~=nil  or string.find(gamedata.device.channel,"tencent")~=nil then
                gamedata.sdk.channel.loginId = 1
            end
            sdk:Login()
        end   
    end
    LoginScene:showNode(LoginScene.enterLayerItem.processNode,false)
    -- LoginScene:showNode(LoginScene.enterLayerItem.enterNode,true)
    startUIUpdate()
end
