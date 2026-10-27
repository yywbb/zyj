---
-- Net main thread interface.
-- User: jutian
-- Date: 13-4-27
-- Time: 下午2:15
--

--- 网络线程表示，用于调试和容错，请勿删除
isNetThread = true

--Require global modules
require("log")
--require("functions")
require("network")


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
--        socket = true,
--        mime = true,
        luaoc = true,
--        device = true,
        md5 = true,
    }

    for k,v in pairs(package.loaded) do
        --print(k)
        if remainlist[k] then

        else
            package.loaded[k] =  nil
        end

    end

    require"accbyhttp/main_net"

end

gamedata = require"gamedata"

local function checkfile(name)
    return CCFileUtils:sharedFileUtils():fullPathForFilename(name..".lua") ~= name..".lua" or CCFileUtils:sharedFileUtils():fullPathForFilename(name..".so") ~= name..".so"
end

local function initGameClient()
    gamedata:init()
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 5000)
    initCacheDir()
    
    gamedata.sdk = require"SDKfunction"

    require"UIRequest"
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

    require("accbyhttp/service_net")
    if acc_net_service() == 777777 then return reloadlua() end

    local sock = {}
    sock.close = function() end
    fd={sock=sock}

    require("gameserver")
    if ProcessFromGameServer() == 777777 then return reloadlua() end

end


xpcall(initGameClient, __G_TRACKBACK__)

