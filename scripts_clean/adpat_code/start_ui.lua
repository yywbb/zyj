--
-- UI thread interface of game
-- User: liliang
-- Date: 13-8-9
-- Time: 下午5:36
--

NEW_ENGINE_VERSION = true

require "adpat_code.tolua_adpat"
require "cocos.init"
require "adpat_code.DeprecatedClassExt"
require "adpat_code.ExtensionConstants"
require "GameTouch_ext"

require"log" -- 日志

CONFIG = require"a_config.lua"
require "adpat_code.CCLabelTTFExt"

require "adpat_code.device"
package.loaded["device"] = package.loaded["adpat_code.device"]

require "adpat_code.GameTouch"
package.loaded["GameTouch"] = package.loaded["adpat_code.GameTouch"]

require "sqlite3init"
SQLite3Init()

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

    gamedata = require"gamedata"
    gameConfig = require"gameConfig"
    gameConfig:makeScreenParam()

	require("functions")

    require"cocos.cocosbuilder.CCBReaderLoad"
	
    ui = require"ui" -- UI Object create method
    require"adpat_code.ui_ext"

    require"UIRequest"
    require"adpat_code.uiqueue_adpat"

    gamedata.sdk = require"adpat_code.sdk.SDKfunction_ui"
    package.loaded["SDKfunction"] = package.loaded["adpat_code.sdk.SDKfunction_ui"]
    sdk = gamedata.sdk
    sdk:SDKChannelName();
    
	--~ End global include.

    gameTimer = require"GameTimer"
    gameTimer:init()

    if gamedata.gameconfig.isHttpLogin and gamedata.gameconfig.isHttpLogin == "true" then
        LoginScene = require"accbyhttp/LoginScene"
    else
        LoginScene = require"LoginScene"
    end

    if not loginScene then
        loginScene = CCScene:create()
        loginScene:retain()
    end

    gameConfig:addScreenSide(loginScene)

    LoginScene:init(loginScene)

    gameWindowslogin = require"GameWindowsLogin"
    gameWindowslogin:init()

    loading = require"adpat_code/Loading_Ultimate"
    loading:init()


    local unziper = require"adpat_code/game_unzip"
    unziper:checkneedunzip(function()
        if not gamedata.music then
            gamedata.music = require"music"
            gamedata.music:Init()
            gamedata.music:GameStart()
        end

        if gamedata.gameconfig.isHttpLogin and gamedata.gameconfig.isHttpLogin == "true" then
            require("accbyhttp/service_ui")
            UIResponse({type = 1})
        else
            require"UIUpdate"
            if gamedata.gameconfig.isupdate then
                local updater = require"accresourceupdate"
                pauseUIUpdate()
                updater:checkifneedupdate({callback = startUIUpdate})
            end
        end
    end)
end

xpcall(createLoginScene, __G_TRACKBACK__)
