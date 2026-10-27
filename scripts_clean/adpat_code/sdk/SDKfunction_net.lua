--
-- Created by IntelliJ IDEA.
-- User: han-joy
-- Date: 14-5-20
-- Time: 下午5:09
-- To change this template use File | Settings | File Templates.
--


local SDK = {
    messageNum = 99
    ,channel = nil
    ,tencentchannel = "qq",

    idCardStatus = -1
}

local deviceApi = require"device"
local config = require"a_config"

function SDK.init(self)
    cclog("SDK.init")
    gamedata.gameconfig = config.config
    gamedata.isshowlog = config.config.isshowlog
    gamedata.isdebug = config.config.isdebug

    self.channelname = gamedata.gameconfig.channel
    self.channelid = gamedata.gameconfig.channelid
    local addressconfig = require"adpat_code.sdk.addressConfig"
    self.address = addressconfig[self.channelname]
end
SDK:init()

function SDK.UserSessionValid(uireq)
    cclog("SDK.UserSessionValid")
    local userTBlogin_pb = require("user91login_pb")
    -- cclog(uireq)
    local messageNum = SDK.messageNum
    if uireq.messageNum then
        messageNum = uireq.messageNum
    end
    if uireq.uin == nil then
        return 0
    end
    local userTBSessionRequest = userTBlogin_pb.User91LoginRequest()
    userTBSessionRequest.uin = uireq.uin
    userTBSessionRequest.sessionid = uireq.sessionId
    userTBSessionRequest.nickname = uireq.nickname

    local uuid, device, os, version = deviceApi.getOpenUDID(), uireq.devicemodel, deviceApi.platform, uireq.systemVersion
    userTBSessionRequest.uuid = uuid
    userTBSessionRequest.device = device
    userTBSessionRequest.os = os
    userTBSessionRequest.version = version


    cclog("SDK.UserSessionValid messageNum:"..messageNum)
    return 1,messageNum,userTBSessionRequest:SerializeToString()
end

function SDK.UserSessionValid2(uireq)
    cclog("SDK.UserSessionValid2")
    local userchanneloginl_pb = require("userchannellogin_pb")
    -- cclog(uireq)
    local messageNum = SDK.messageNum
    if uireq.messageNum then
        messageNum = uireq.messageNum
    end
    if uireq.uin == nil then
        return 0
    end
    local userChannelLoginRequest = userchanneloginl_pb.UserChannelLogin()
    userChannelLoginRequest.uin = uireq.uin
    userChannelLoginRequest.sessionid = uireq.sessionId
    userChannelLoginRequest.nickname = uireq.nickname
    userChannelLoginRequest.channelname = uireq.channel
    userChannelLoginRequest.channelid   = uireq.channelid

    if deviceApi.channel and uireq.channel then
        deviceApi.channel = uireq.channel
        deviceApi.channelid   = uireq.channelid
    end

    cclog("SDK.UserSessionValid2 channel3 is  %s",userChannelLoginRequest.channelname )

    local uuid, device, os, version = deviceApi.getOpenUDID(), uireq.devicemodel, deviceApi.platform, uireq.systemVersion
    userChannelLoginRequest.uuid = uuid
    userChannelLoginRequest.device = device
    userChannelLoginRequest.os = os
    userChannelLoginRequest.version = version


    cclog("SDK.UserSessionValid2 messageNum:"..messageNum)

    local userchannelname = userChannelLoginRequest.channelname 
    if string.find(userchannelname,"qq")~=nil or string.find(userchannelname,"weixin")~=nil  or string.find(userchannelname,"tencent")~=nil then
        return 1,900001,userChannelLoginRequest:SerializeToString()
    else
        return 1,messageNum,userChannelLoginRequest:SerializeToString()
    end
end

function SDK.AndroidSessionValid2(uireq)
    cclog("SDK.AndroidSessionValid2")

    local combmessages_pb = require("combmessages_pb")
    local userchanneloginl_pb = require("userchannellogin_pb")
    local params_pb = require("params_pb")

    -- cclog(uireq)
    local messageNum = SDK.messageNum
    if uireq.messageNum then
        messageNum = uireq.messageNum
    end
    if uireq.uin == nil then
        return 0
    end
    local userChannelLoginRequest = userchanneloginl_pb.UserChannelLogin()
    userChannelLoginRequest.uin = uireq.uin
    userChannelLoginRequest.sessionid = uireq.sessionId
    userChannelLoginRequest.nickname = uireq.nickname

   cclog("SDK.AndroidSessionValid3")
    if deviceApi.channel then
        userChannelLoginRequest.channelname = deviceApi.channel
        userChannelLoginRequest.channelid   = deviceApi.channelid
    end

    cclog("SDK.AndroidSessionValid3")
    cclog("SDK.UserSessionValid2 channelid:%s",uireq.channelid)
    cclog("SDK.UserSessionValid2 channelname:%s",uireq.channelname)

    if uireq.channelname then
      userChannelLoginRequest.channelname = uireq.channelname
    end

    if uireq.channelid then
      userChannelLoginRequest.channelid = uireq.channelid
    end

    cclog("SDK.UserSessionValid2 userChannelLoginRequest channelname:%s",userChannelLoginRequest.channelname)
    cclog("SDK.UserSessionValid2 userChannelLoginRequest channelid:%s",userChannelLoginRequest.channelid)

    local uuid, device, os, version = deviceApi.getOpenUDID(), uireq.devicemodel, deviceApi.platform, uireq.systemVersion
    userChannelLoginRequest.uuid = uuid
    userChannelLoginRequest.device = device
    userChannelLoginRequest.os = os
    userChannelLoginRequest.version = version

    cclog("SDK.UserSessionValid2 messageNum:"..messageNum)

     local userchannelname = userChannelLoginRequest.channelname
    if string.find(userchannelname,"qq")~=nil or string.find(userchannelname,"weixin")~=nil  or string.find(userchannelname,"tencent")~=nil  then
        return 1,900001,userChannelLoginRequest:SerializeToString()
    else
        local versiondata = params_pb.ParamS()
        local paramdata = versiondata.params:add()

        --安卓提审版本号
        paramdata.s = tostring(gamedata.gameconfig.submit)

        local reqs = combmessages_pb.CombMessages()

        local userreq = reqs.messages:add()
        userreq.id = 1
        userreq.data = userChannelLoginRequest:SerializeToString()

        local sysversion = reqs.messages:add()
        sysversion.id = 2
        sysversion.data = versiondata:SerializeToString()

        return 1,900002,reqs:SerializeToString()
    end
end

function SDK.appleUserSessionValid(uireq)
    cclog("SDK.appleUserSessionValid")

    local combmessages_pb = require("combmessages_pb")
    local userchanneloginl_pb = require("userchannellogin_pb")
    local params_pb = require("params_pb")
    

    -- cclog(uireq)
    local messageNum = SDK.messageNum
    if uireq.messageNum then
        messageNum = uireq.messageNum
    end
    if uireq.uin == nil then
        return 0
    end
    local userChannelLoginRequest = userchanneloginl_pb.UserChannelLogin()
    userChannelLoginRequest.uin = uireq.uin
    userChannelLoginRequest.sessionid = uireq.sessionId
    userChannelLoginRequest.nickname = uireq.nickname
    if deviceApi.channel then
        userChannelLoginRequest.channelname = deviceApi.channel
        userChannelLoginRequest.channelid   = deviceApi.channelid
    end

     if uireq.channelname then
      userChannelLoginRequest.channelname = uireq.channelname
    end

    if uireq.channelid then
      userChannelLoginRequest.channelid = uireq.channelid
    end

    
    cclog("SDK.UserSessionValid2 channel3 is  %s",userChannelLoginRequest.channelname )

    local uuid, device, os, version = deviceApi.getOpenUDID(), uireq.devicemodel, deviceApi.platform, uireq.systemVersion
    userChannelLoginRequest.uuid = uuid
    userChannelLoginRequest.device = device
    userChannelLoginRequest.os = os
    userChannelLoginRequest.version = version

    cclog("SDK.UserSessionValid2 messageNum:"..messageNum)

    local versiondata = params_pb.ParamS()
    local paramdata = versiondata.params:add()


    --苹果提审版本号
    paramdata.s = tostring(gamedata.gameconfig.submit)


    local reqs = combmessages_pb.CombMessages()

    local userreq = reqs.messages:add()
    userreq.id = 1
    userreq.data = userChannelLoginRequest:SerializeToString()

    local sysversion = reqs.messages:add()
    sysversion.id = 2
    sysversion.data = versiondata:SerializeToString()

    return 1,900000,reqs:SerializeToString()
end

return SDK
