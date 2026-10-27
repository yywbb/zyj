--
-- UI thread interface of game
-- User: liliang
-- Date: 13-8-9
-- Time: 下午5:36
--


--- 网络线程表示，用于调试和容错，请勿删除
isNetThread = false

function __G_TRACKBACK__(msg)
	-- for CCLuaEngine traceback 输出绑定执行函数发生错误的信息
	local msg = tostring(msg)
    local msgreport = ""
	msg = string.gsub(msg, "string", "Lua")
	msg = string.gsub(msg, '"]', '')
	msg = string.gsub(msg, ': ', '"] ')
    msgreport = msg
	print("-----------------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx-----------------------")
	print("------[ UI  Thread ]-----LUA ERROR: " .. msg .. "\n")
    msg = debug.traceback()
    msg = string.gsub(msg, "string", "Lua")
    msg = string.gsub(msg, '"]', '')
    msg = string.gsub(msg, ': ', '"] ')
    print(msg)
    print("-----------------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx-----------------------")
    msgreport = msgreport .."\n"..msg
    UIRequest({type=999988, msg=msgreport, from="ui"})
end


local function createLoginScene()

	-- avoid memory leak 设置脚本内存回收参数 避免内存泄露
	collectgarbage("setpause", 100)
	collectgarbage("setstepmul", 5000)
	--~ avoid memory leak end

	-- Include global module and functions
	require"log" -- 日志

    gamedata = require"gamedata"
    gameConfig = require"gameConfig"
    gameConfig:makeScreenParam()

	require("functions")
	require"CCBReaderLoad" -- 读取CCB
    ui = require"ui" -- UI Object create method
    require"UIRequest"    

    if gamedata.device.platform=="android" then
        local TotalMemory = tonumber(gamedata.device.getTotalMemory() or "1000000")

        print("TotalMemory=====",TotalMemory)
        if TotalMemory and TotalMemory<600000 then
            CCTexture2D:setDefaultAlphaPixelFormat(kCCTexture2DPixelFormat_RGBA4444);
        end
    end

    gamedata.sdk = require"accbyhttp/sdk/SDKfunction"
    sdk = gamedata.sdk
    sdk:SDKChannelName();
    
	--~ End global include.

    gameTimer = require"GameTimer"
    gameTimer:init()


    LoginScene = require"accbyhttp/LoginScene"
    if not loginScene then
        loginScene = CCScene:create()
        loginScene:retain()
    end

    gameConfig:addScreenSide(loginScene)

    LoginScene:init(loginScene)

    gameWindowslogin = require"GameWindowsLogin"
    gameWindowslogin:init()

    loading = require"accbyhttp/Loading_Ultimate"
    loading:init()

    if not gamedata.music then
        gamedata.music = require"music"
        gamedata.music:Init()
        gamedata.music:GameStart()
    end

    require("accbyhttp/service_ui")
    UIResponse({type = 1})

end

xpcall(createLoginScene, __G_TRACKBACK__)
