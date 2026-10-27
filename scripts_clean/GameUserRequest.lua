--
-- Created by IntelliJ IDEA.
-- User: WangTao
-- Date: 13-5-17
-- Time: 下午1:27
-- To change this template use File | Settings | File Templates.
--

local deviceApi = require"device"
local config = require"config"

-- 客户端向服务器发送请求
local userrequest_pb = require("userrequest_pb")
function UIUserRequestCallback(uireq)
    if deviceApi.platform == "android" then
        if deviceApi.openUDID == nil then
            return nil
        end
        if deviceApi.channel then
            local sdk = require"SDKfunction"
            return sdk.UserSessionValid(uireq)
        else
            -- 发送用户登陆请求
            -- TODO version is not a fixed number.
            local userrequest = userrequest_pb.UserRequest()
            local uuid, device, os, version = deviceApi.openUDID, uireq.devicemodel, deviceApi.platform, uireq.systemVersion
            ---local uuid, device, os, version = "test123",deviceApi.model, deviceApi.platform, "5.1"
            cclog("传给服务器:uuid=" .. uuid .. " device=" .. device .. " os=" .. os .. " verion=" .. version)
            userrequest.uuid = uuid -- 手机唯一uuid
            userrequest.device = device -- 手机设备
            userrequest.os = os -- 手机系统
            userrequest.version = version -- 手机系统版本
            local login2bit = userrequest:SerializeToString()
            return 1, 3, login2bit
        end
    else
        local userrequest = userrequest_pb.UserRequest()
        local uuid, device, os, version = config.getOpenUDID(),uireq.devicemodel, deviceApi.platform, uireq.systemVersion
        ---local uuid, device, os, version = "test123",deviceApi.model, deviceApi.platform, "5.1"
        cclog("传给服务器:uuid=" .. uuid .. " device=" .. device .. " os=" .. os .. " verion=" .. version)
        userrequest.uuid = uuid -- 手机唯一uuid
        userrequest.device = device -- 手机设备
        userrequest.os = os -- 手机系统
        userrequest.version = version -- 手机系统版本
        local login2bit = userrequest:SerializeToString()
        return 1, 3, login2bit
    end
end


local function makeServerList(fd)
    local responseuser = responseuser_pb.ResponseUser()
    responseuser:ParseFromString(fd.rbuf)
    cclog("最近登录的用户名：%s", responseuser.userinfo.user)
    local t = { type = 3, user = responseuser.userinfo.user, uid = responseuser.userinfo.id, serverslist = {}, recentlist = {} }

    if gamedata.sdk.address.serverInfoAddress and gamedata.sdk.address.serverInfoAddress~="" then
        require"myjson"
        local path = CCFileUtils:sharedFileUtils():fullPathForFilename("GameServer.json")
        local ServerInfo = LoadJsonFileToTable(path)
        printT(ServerInfo,"downloadcomplete")

        if next(responseuser.serverinfo) ~= nil then
            for k, v in ipairs(responseuser.serverinfo) do
                local serverconfig = ServerInfo[tostring(v.id)]
                if serverconfig then
                    local defaut = {
                        id=v.id,
                        status=v.status,
                        tag1 = v.tag1,
                        tag2 = v.tag2,
                        name=serverconfig.name,
                        ip=serverconfig.ip,
                        port=serverconfig.port,
                    }

                    table.insert(t.serverslist, defaut)
                    gamedata.serverlist[v.id] = defaut
                end
            end
        end
    else
        if next(responseuser.serverinfo) ~= nil then
            for k, v in ipairs(responseuser.serverinfo) do
                local defaut = {
                    id=v.id,
                    status=v.status,
                    tag1 = v.tag1,
                    tag2 = v.tag2,
                    name=v.name,
                    ip=v.ip,
                    port=v.port,
                }

                table.insert(t.serverslist, defaut)
                gamedata.serverlist[v.id] = defaut
            end
        end
    end

    if next(responseuser.rls) ~= nil then
        for k, v in ipairs(responseuser.rls) do
            for kk, vv in ipairs(t.serverslist) do
                if tonumber(vv.id) == tonumber(v.id) then
                    table.insert(t.recentlist, vv)
                    cclog("最近登陆的服务器id为: %s ", vv.id)
                    break
                end
            end
        end
    end

    printT(t,"makeServerList")

    return t
end

-- 客户端接受服务器传来的数据
local responseuser_pb = require("responseuser_pb")
function NetUserResponseCallback(fd)

    return makeServerList(fd)
end

function NetChannelLoginResponseCallback(fd)

    return makeServerList(fd)
end

local params_pb = require("params_pb")

--客户端接受服务器传来的数据获取guid，保存到gamedata中
function NetGetGuidCallback(fd)
    -- body
    local get_guid = params_pb.ParamS()
    get_guid:ParseFromString(fd.rbuf)
    cclog("NetGetGuidCallback ------- ")
    print("1111111")
    print(get_guid.params[1].s)
    local channelName = gamedata.sdk.channelname

    if channelName == "pp" then
        local guid = get_guid.params[1].s or ""
        return { type = 98 ,  guid = guid }
    elseif channelName == "xsdk" then
        local guid = get_guid.params[1].s or ""
        return { type = 98 ,  guid = guid }
        
    elseif channelName == "linnyou" or channelName == "x7syn" then
        local guid = get_guid.params[1].s or ""
        cclog("小7guid  ",guid)
        return { type = 98 ,  guid = guid }
    elseif channelName == "hanfenga" or  channelName == "beiyouaQM" then
        local guid = get_guid.params[1].s or ""
        cclog("NetGetGuidCallback hanfenga------- %s   ",guid)
        return { type = 98 ,  guid = guid }
    else
        local guid = get_guid.params[1].s or ""
        local guidname = get_guid.params[2].s or ""
        return { type = 98 ,  guid = guid, guidname = guidname }
    end
    
end

function UIReloginInAcc()
    UIReqeustClear()
    UIResponse({type=8888882})
    return 998
end
