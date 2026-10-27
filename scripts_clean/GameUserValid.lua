---
-- GameUserValid
-- User: jutian
-- Date: 13-5-7
-- Time: 下午1:56
-- To change this template use File | Settings | File Templates.
--

--local sessionvalidate_pb = require("sessionvalidate_pb")
local params_pb = require("params_pb")
function UINetSessionValidateCallback(uireq)
    --local uservalid = sessionvalidate_pb.SessionValidate()
    local params = params_pb.ParamS()
    local param1 = params_pb.ParamS.Param()
    param1.s = gamedata.role.uuid
    table.insert(params.params, param1)
    if gamedata.reconnect_type then
        local param2 = params_pb.ParamS.Param()
        param2.i = gamedata.reconnect_type
        table.insert(params.params, param2)
        gamedata.reconnect_type = nil
    end
    --uservalid.uuid = gamedata.role.uuid
    --local uservalid2bit = uservalid:SerializeToString()
    return 1, 1000, params:SerializeToString()
end



function TencentPayCheck(uireq)
    cclog("TencentPayCheck NET type:%d cmd:%s recv request from UI", 10001, "TencentPayCheck")
    local params = params_pb.ParamS()
    local param1 = params_pb.ParamS.Param()
    param1.s = uireq.orderid
    table.insert(params.params, param1)
    return 1, 10001, params:SerializeToString()
end

--腾讯登录有关的数值
function UITencentLogin(uireq)
    cclog("UITencentLogin NET type:%d cmd:%s recv request from UI", 10000, "UITencentLogin")
    local params = params_pb.ParamS()
    local param1 = params_pb.ParamS.Param()
    param1.s = uireq.openid

    table.insert(params.params, param1)
    local param2 = params_pb.ParamS.Param()
    param2.s = uireq.openkey
    table.insert(params.params, param2)

    local param3 = params_pb.ParamS.Param()
    param3.s = uireq.pf
    table.insert(params.params, param3)

    local param4 = params_pb.ParamS.Param()
    param4.s = uireq.pfkey
    table.insert(params.params, param4)

    local param5 = params_pb.ParamS.Param()
    param5.s = uireq.paytoken
    table.insert(params.params, param5)


    return 1, 10000, params:SerializeToString()
end

function NetTencentLogin(uireq)
    cclog("---------TencentLogin Net Data---------")
    return { type = 10000 }
end

function TencentPayCheck2(uireq)
    cclog("TencentPayCheck NET type:%d cmd:%s recv request from UI", 10003, "TencentPayCheck")
    local params = params_pb.ParamS()
    local param1 = params_pb.ParamS.Param()
    param1.s = uireq.orderid
    table.insert(params.params, param1)
    return 1, 10003, params:SerializeToString()
end

--腾讯登录有关的数值
function UITencentLogin2(uireq)
    cclog("UITencentLogin NET type:%d cmd:%s recv request from UI", 10002, "UITencentLogin")
    local params = params_pb.ParamS()
    local param1 = params_pb.ParamS.Param()
    param1.s = uireq.openid

    table.insert(params.params, param1)
    local param2 = params_pb.ParamS.Param()
    param2.s = uireq.openkey
    table.insert(params.params, param2)

    local param3 = params_pb.ParamS.Param()
    param3.s = uireq.pf
    table.insert(params.params, param3)

    local param4 = params_pb.ParamS.Param()
    param4.s = uireq.pfkey
    table.insert(params.params, param4)

    local param5 = params_pb.ParamS.Param()
    param5.s = uireq.paytoken
    table.insert(params.params, param5)


    return 1, 10002, params:SerializeToString()
end

function NetTencentLogin2(uireq)
    cclog("---------TencentLogin Net Data---------")
    return { type = 10002 }
end



local gameuserqueue_pb = require("gameuserqueue_pb")
function NetSessionValidateCallback(fd)
    local result = gameuserqueue_pb.GameUserQueue();
    result:ParseFromString(fd.rbuf)
    cclog("---------------inGameUserValid-------------------: %s", result.cur)


    return { type = 1000, total = result.total, location = result.cur, time = result.waittime }
end

function UIReloginCallBack(uireq)

    gamedata:init()
    return 999
end

function UIDisconnect2(uireq)
    --NET_SELECT_TIMEOUT = NET_SELECT_TIMEOUT_BACKGROUND
    return 995
end

function UIDisconnect3(uireq)
    --NET_SELECT_TIMEOUT = NET_SELECT_TIMEOUT_BACKGROUND
    return 9951
end

function UIDisconnect(uireq)
    --NET_SELECT_TIMEOUT = NET_SELECT_TIMEOUT_BACKGROUND
    bBackGround = true
    return 997
end

function UIReconnect(uireq)
    --NET_SELECT_TIMEOUT = NET_SELECT_TIMEOUT_NORMAL
    bBackGround = false
    return 996
end

function UIHearCheckCallBack(uireq)
    return 1, 999904, nil
end

function NetHearCheckCallBack(fd)
    return {type = 999904}
end

function UIServerTimeCallBack(uireq)
    return 1, 999905, nil
end

local ids_pb = require("ids_pb")
function NetServerTimeCallBack(fd)
    local  Result = ids_pb.Ids();
    Result:ParseFromString(fd.rbuf)

    local tmpAdds = 0
    if Result.ids[2] then
        tmpAdds = 0-Result.ids[2]
    end
    if  Result.ids[1] and  Result.ids[1] > 0 then
        local tmpOneDay = 86400
        local tmpOneHou = 3600
        local tmpOneMin = 60

        local tmpZeroShi = os.time()
        local tmpZeroTime = tmpZeroShi % tmpOneDay
        local tmpZeroDay = math.floor(tmpZeroShi/tmpOneDay)

        local tmpShi2 = os.date("*t",tmpZeroShi)
        local tmpNowTime = tmpShi2.hour * tmpOneHou + tmpShi2.min*tmpOneMin + tmpShi2.sec

        local ddd = tonumber(os.date("%z", 0))/100

        -- print("1111=====:",tmpZeroTime,ddd,tmpZeroTime + ddd * tmpOneHou,tmpNowTime)
        if tmpZeroTime + ddd * tmpOneHou ~= tmpNowTime then
            if ddd > 0 then -- 东市区
                if tmpZeroTime > tmpNowTime then -- 跨天
                    tmpNowTime = tmpNowTime + tmpOneDay
                end
            elseif ddd < 0 then -- 西市区
                if tmpNowTime > tmpZeroTime then -- 跨天
                    tmpZeroTime = tmpZeroTime + tmpOneDay
                end
            end
            -- print("不对需要校验",tmpZeroTime,tmpNowTime)
        -- else
            -- print("对了")
        end

        local tmpTimeSub = tmpNowTime - tmpZeroTime
        if tmpTimeSub > 0 then
            tmpTimeSub = math.ceil(tmpTimeSub/tmpOneHou)
        else
            tmpTimeSub = math.floor(tmpTimeSub/tmpOneHou)
        end

        -- print("tmpShi====:",Result.ids[1],tmpZeroShi,tmpAdds,tmpTimeSub)
        gamedata.timeDis = (Result.ids[1] - tmpZeroShi) + (tmpAdds - tmpTimeSub)*tmpOneHou
        gamedata.timeDis2 = (tmpAdds - tmpTimeSub)*tmpOneHou
    end

    return {type = 999905,timeDis=gamedata.timeDis}
end


function UIconfigUpdateCallBack(uireq)
    return 1, 999907, nil
end

local params_pb = require("params_pb")

function NetconfigUpdateCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 999907, "configUpdate")
    local  Result = params_pb.ParamS();
    Result:ParseFromString(fd.rbuf)

    if not gamedata.configVersion then
        if  Result.params[1]  then
            gamedata.configVersion = Result.params[1].i
        end
    else
        print(gamedata.configVersion,Result.params[1].i)
        if  Result.params[1] and gamedata.configVersion ~= Result.params[1].i then
            return {type = 999907, needupdate = true}
        end
    end

    return {type = 999907}
end


function NetOfflineCallBack(fd)
    local  Result = params_pb.ParamS();
    Result:ParseFromString(fd.rbuf)

    if Result.params[1] and Result.params[1].s ~= "" then
        return {type = 999908, des = Result.params[1].s}
    else
        return {type = 999908 }
    end
end

