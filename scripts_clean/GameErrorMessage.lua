--[[
-- Game error message callback
-- Created by IntelliJ IDEA.
-- User: inaction
-- Date: 13-10-14
-- Time: 下午6:10
]]


local error_pb = require("error_pb")
local ids_pb = require("ids_pb")
local logerr = require("logError")

function NetErrorMessageCallback9(fd)
    local error = initPb(ids_pb, fd)
    local cnMessage = logerr.errorMessage[error.ids[2]] or "您的数据可能出现异常，退出游戏再重进可以解决！"
    -- local cnMessage = "您的数据可能出现异常，退出游戏再重进可以解决！"

    printf("[SERVER ERROR] CODE:%d RESON:%s ", 999999, cnMessage)
    --printf("[SERVER ERROR] CODE:%d RESON:%s \nPythonStackTrace:%s", 999999, cnMessage, error.errmsg)

    --return {type = error.errno, msg = "哎呀主公，数据错误！"}
    --return nil -- Not push the error tu UI.
    return { type = 9999, errornum = error.ids[2], msg = cnMessage }
end


function NetErrorMessageCallback8(fd)
    local cnMessage = "您的数据出现异常，请联系客服！"
    local error = initPb(error_pb, fd)
    printf("[SERVER ERROR] CODE:%d RESON:%s ", 999998, cnMessage)
    return { type = 9999, msg = cnMessage }
end

function NetErrorMessageCallback7(fd)
    local cnMessage = "账号在其他地方登陆，请退出游戏重新登录并注意账号安全！"
    local error = initPb(error_pb, fd)
    printf("[SERVER ERROR] CODE:%d RESON:%s ", 999997, cnMessage)
    return { type = 9997, msg = cnMessage }
end

function NetRequestLocking(fd)

    print("NetLastResponseType",NetLastResponseType)
    return {type=999903}
end

local params_pb = require("params_pb")
function LuaExceptionReportCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 999988, "luaexception")
    cclog("from %s msg:%s", uireq.from, uireq.msg)

    return 0,999988,{
        type = 999988,
        redirect = not uireq.noneedfix,
        needsend = true,
        from = uireq.from,
        msg = uireq.msg,
    }

    -- local params = params_pb.ParamS()
    -- local p1 = params_pb.ParamS.Param()
    -- p1.s = uireq.msg
    -- table.insert(params.params, p1)
    -- local p2 = params_pb.ParamS.Param()
    -- p2.s = uireq.from
    -- table.insert(params.params, p2)

    -- gamedata.ext.errornoneedfix = nil
    -- gamedata.ext.errornoneedfix = uireq.noneedfix
    -- return 1, 999988, params:SerializeToString()
end


function LuaExceptionResponseCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 999988, "luaexception")
    local params = params_pb.ParamS()
    params:ParseFromString(fd.rbuf)

    if gamedata.ext.errornoneedfix then
        return { type = 999988}
    else
        if params.params[1].i == 1 then
            return { type = 999988, redirect = true }
        end
        return { type = 999988}
    end

end

function UIdeviceinfoCallBack(uireq)
    cclog("deviceinfo %d", 999906)
    local params = params_pb.ParamS()

    for i=1,table.getTableLength(uireq.infos) do
        local p1 = params_pb.ParamS.Param()
        p1.s = uireq.infos[tostring(i)]
        print(uireq.infos[tostring(i)])
        table.insert(params.params, p1)
    end


    return 1, 999906, params:SerializeToString()
end

function UInetLuaReloadCallBack(uireq)
    cclog("UInetLuaReloadCallBack %d", 777777)
    return 777777
end

