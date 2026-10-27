--- Device plateform api
-- Created by IntelliJ IDEA.
-- User: inaction
-- Date: 13-9-3
-- Time: 下午5:16
--

local device = {}
device.platform = "unknown"
device.model = "unknown"
device.systemVersion = ""
device.SimState = ""
device.PhoneType = ""
device.TotalMemory = ""

device.channel = nil
device.channelid = nil
--device.packageName = "com/ldfs/zyj/ly"
device.packageName = "unknown"


if gPlatform then 
    device.platform = gPlatform

end

if device.model == "unknown" then
    print("1111")
    if CCDeviceModel and not isNetThread then
         print("1112")
        device.model = CCDeviceModel:getDeviceModel()
    end    
end

device.language = "cn"--language_
--device.writablePath = CCFileUtils:sharedFileUtils():getWritablePath()
device.writablePath = gWPath or ""
-- device.writablePath = gWPath
--device.cachePath = CCFileUtils:sharedFileUtils():getCachePath()
device.directorySeparator = "/"
device.pathSeparator = ":"
if device.platform == "windows" then
    device.directorySeparator = "\\"
    device.pathSeparator = ";"
end

function device.getPackageName()
   
    print("getPackageName")
    if device.packageName == nil or device.packageName == "unknown" then
        -- if device.platform == "android" then
        --     -- local luaj = require"luaj"

        --     -- local javaClassName = "org/cocos2dx/lib/Cocos2dxHelper"
        --     -- local javaMethodName = "getCocos2dxPackageName"
        --     -- local javaMethodSig = "()Ljava/lang/String;"

        --     -- local result, packgename = luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
        --     -- device.packageName = string.gsub(packgename,"%.","/")

            
        -- end

        require"myjson"
        local configjson = LoadJsonFileToTable(CCFileUtils:sharedFileUtils():fullPathForFilename("config.json"))
        device.packageName = string.gsub(configjson.androidPackageName,"%.","/")
        
    end
    return device.packageName
end

function device.getsystemVersion()
    if not device.systemVersion or device.systemVersion == "" then
        if device.platform == "android" then
            local luaj = require"luaj"
            local javaClassName = device.getPackageName().."/MobileUtils"
            local javaMethodName = "getSystemVersion"
            local javaMethodSig = "()Ljava/lang/String;"
            local result, Version = luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
            device.systemVersion  = Version
        elseif device.platform == "ios" then
            device.systemVersion = tostring(CCDeviceModel:getSystemVersion())
        end
    end
    return device.systemVersion
end

function device.getSimState()
    if not device.SimState or device.SimState == "" then
        if device.platform == "android" then
            local luaj = require"luaj"
            local javaClassName = device.getPackageName().."/MobileUtils"
            local javaMethodName = "SimState"
            local javaMethodSig = "()Ljava/lang/String;"
            local result, Version = luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
            device.SimState  = Version
        elseif device.platform == "ios" then
            device.SimState = "ios"
        end
    end
    return device.SimState
end


function device.getPhoneType()
    if not device.PhoneType or device.PhoneType == "" then
        if device.platform == "android" then
            local luaj = require"luaj"
            local javaClassName = device.getPackageName().."/MobileUtils"
            local javaMethodName = "PhoneType"
            local javaMethodSig = "()Ljava/lang/String;"
            local result, Version = luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
            device.PhoneType  = Version
        elseif device.platform == "ios" then
            device.PhoneType = "ios"
        end
    end
    return device.PhoneType
end

function device.getTotalMemory()
    if not device.TotalMemory or device.TotalMemory == "" then
        if device.platform == "android" then
            local luaj = require"luaj"
            local javaClassName = device.getPackageName().."/MobileUtils"
            local javaMethodName = "getTotalMemory"
            local javaMethodSig = "()Ljava/lang/String;"
            local result, Version = luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
            device.TotalMemory  = Version
        elseif device.platform == "ios" then
            device.TotalMemory = "1048576"
        end
    end
    return device.TotalMemory
end


echoInfo("# device.platform              = " .. device.platform)
echoInfo("# device.model                 = " .. device.model)
echoInfo("# device.systemVersion         = " .. device.systemVersion)
echoInfo("# device.language              = " .. device.language)
echoInfo("# device.writablePath          = " .. device.writablePath)
--echoInfo("# device.cachePath             = " .. device.cachePath)
echoInfo("# device.directorySeparator    = " .. device.directorySeparator)
echoInfo("# device.pathSeparator         = " .. device.pathSeparator)
echoInfo("#")



--- Get device open UDID
-- @return Device UDID string.

device.openUDID = gDeviceID 
local udid = "default"
function device.getOpenUDID()

    if gDeviceID then
        print("gDeviceID",gDeviceID)
        return gDeviceID 
    end

    return udid
end

if not isNetThread then
    local openGLView = CCDirector:sharedDirector():getOpenGLView()
    local frameSize = openGLView:getFrameSize()
    device.SCREEN_WIDTH = frameSize.width
    device.SCREEN_HEIGHT = frameSize.height
end

--- return device module.
return device


