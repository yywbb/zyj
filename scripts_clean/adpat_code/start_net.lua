---
-- Net main thread interface.
-- User: jutian
-- Date: 13-4-27
-- Time: 下午2:15
--

NEW_ENGINE_VERSION = true
require "adpat_code.DeprecatedClassExtforNet"

--- 网络线程表示，用于调试和容错，请勿删除
isNetThread = true

--Require global modules
require("log")
--require("functions")
require("network")

require "adpat_code.device"
package.loaded["device"] = package.loaded["adpat_code.device"]


--[End] required


function __G_TRACKBACK__(msg)
    local msg = tostring(msg)
    local msgreport = ""
    msg = string.gsub(msg, "string", "Lua")
    msg = string.gsub(msg, '"]', '')
    msg = string.gsub(msg, ': ', '"] ')
    msgreport = msg
    print("-----------------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx-----------------------")
    print("------[ Net Thread ]-----LUA ERROR: " .. msg .. "\n")
    msg = debug.traceback()
    msg = string.gsub(msg, "string", "Lua")
    msg = string.gsub(msg, '"]', '')
    msg = string.gsub(msg, ': ', '"] ')
    print(msg)
    print("-----------------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx-----------------------")
    msgreport = msgreport .."\n"..msg
    UIRequest({type=999988, msg=msgreport, from="net"})
end

--- 全局可写的路径变量
--gWPath = config:getWritablePath()

--- 是否处理滚动条进度数据开关,false 则停止向前台推送进度变化
isParseProgress = true


local function initCacheDir()
    local filepath = gWPath
    cclog("Global writable path: %s", filepath)
end

local function reloadlua()
    UIReqeustClear()
    local remainlist = {
        _G = true,
        uiqueue = true,
        myfile = true,
        sqlite3 = true,
        pb = true,
        cjson = true,
        struct = true,
        zipfileutil = true,
--        socket = true,
--        mime = true,
        luaoc = true,
--        device = true,
        md5 = true,
        Lua = true,
        jit = true,
        debug = true,
        table = true,
        socket = true,
        package = true,
        bit = true,
        string = true,
        timefunc = true,
        ["adpat_code.uiqueue_adpat"] = true,
    }

    for k,v in pairs(package.loaded) do
        --print(k)
        if remainlist[k] then

        else
            package.loaded[k] =  nil
        end

    end

    require"adpat_code/start_net"

end

gamedata = require"gamedata"

local function initGameClient()
    gamedata:init()
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 5000)
    initCacheDir()
    
    gamedata.sdk = require"adpat_code.sdk.SDKfunction_net"
    package.loaded["SDKfunction"] = package.loaded["adpat_code.sdk.SDKfunction_net"]

    require"UIRequest"
    require"adpat_code.uiqueue_adpat"
    require("GameUserRequest")
    require("GameSltServerRult")
    require("GameLoginandRegister")

    require"GameDownloadProxy"
    require"syncconfig2"
    require"commongameloopfunc"
    require"GameErrorMessage"
    require"GameRecharge"

    --内存情况
    echoInfo("collectgarbage start " .. collectgarbage("count") / 1024 .. " M")
    --进行垃圾搜集
    collectgarbage("collect");
    echoInfo("collectgarbage end " .. collectgarbage("count") / 1024 .. " M")


    if gamedata.gameconfig.isHttpLogin and gamedata.gameconfig.isHttpLogin == "true" then
        require("accbyhttp/service_net")
        if acc_net_service() == 777777 then return reloadlua() end

        local sock = {}
        sock.close = function() end
        fd={sock=sock}

        require("gameserver")
        if ProcessFromGameServer() == 777777 then return reloadlua() end
    else
        if gamedata.gameconfig.isupdate then
            require("accresourceupdateunzip")
            if resourceupdateunzip() == 777777 then return reloadlua() end
            require("accsyncresource")
            if SyncResourceFromAccServer() == 777777 then return reloadlua() end
        else
            UIResponse({type=888888})
        end

        require("accserver")
        if ProcessFromAccServer() == 777777 then return reloadlua() end

        require("gameserver")
        if ProcessFromGameServer() == 777777 then return reloadlua() end
    end

end


xpcall(initGameClient, __G_TRACKBACK__)

