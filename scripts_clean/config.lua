--
-- Created by IntelliJ IDEA.
-- User: inaction
-- Date: 13-9-10
-- Time: 下午6:33
-- To change this template use File | Settings | File Templates.
--

require"functions"

local device = require"device"

local config = {}
config.device = device

local isAndroid = device.platform == "android"
local androidConfigFileName = "android_config"
local myfile = require("myfile")

-- Init cofig in main UI thread
function config.init()
    if device.platform == "android" then
        local writablePath = device.writablePath
        local lua_runtime = writablePath .. "lua_runtime" .. device.directorySeparator
        myfile.mkdir(lua_runtime)
        cclog("make dir: %s ", lua_runtime)

        local configLuaObj = {};
        configLuaObj.writablePath = device.writablePath
        configLuaObj.openUDID = device:getOpenUDID()
        configLuaObj.luaRuntime = lua_runtime
        local configContent = serialize(configLuaObj)
        cclog("android_config file content:[[\n %s \n]]", configContent)

        local filename = lua_runtime .. androidConfigFileName .. ".lua"

        local file
        if filename == nil then
            file = io.stdout
        else
            local err
            file, err = io.open(filename, "wb")
            if file == nil then
                error(("Unable to write '%s': %s"):format(filename, err))
            end
        end
        file:write(configContent)
        if filename ~= nil then
            file:close()
        end

        cclog("android config file: %s inited.", filename)
        require"UIRequest"
        UIRequest({type=998})
    end
end

function config.getWritablePath()
    return device.writablePath
end

function config.getOpenUDID()
    --return "3721544761346a2970264cc55c1d5d87d85d66cd"
    return device.getOpenUDID()
end

function AndroidNetLoad()
    local sisandroid = "true"
    if not isAndroid then
        sisandroid = "false"
    end
    cclog("AndroidNetLoad "..sisandroid.." "..gThreadTag)
    if isAndroid and gThreadTag == "Net" then
        -- TODO set search path in C++ code,如果用携程就不用这么写了？
        CCFileUtils:sharedFileUtils():addSearchPath(gWPath .. "lua_runtime" .. device.directorySeparator )
        local androidConfig = require(androidConfigFileName)
        if androidConfig ~= nil and type(androidConfig) == "table" then
            device.writablePath = androidConfig.writablePath
            device.openUDID = androidConfig.openUDID
            device.getOpenUDID = function() return device.openUDID end
            cclog("Init config from ext file.")
        end
        cclog("Inited?")
        ---UIRequest({type=3})
    end
end

return config

