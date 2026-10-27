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



--enum TargetPlatform
--	{
--		kTargetWindows,
--		kTargetLinux,
--		kTargetMacOS,
--		kTargetAndroid,
--		kTargetIphone,
--		kTargetIpad,
--		kTargetBlackBerry,
--		kTargetNaCl,
--		kTargetEmscripten,
--		kTargetTizen
--	};
local sharedApplication = CCApplication:sharedApplication()
local target = sharedApplication:getTargetPlatform()
if target == kTargetWindows then
    device.platform = "windows"
elseif target == kTargetMacOS then
    device.platform = "mac"
elseif target == kTargetAndroid then
    device.platform = "android"
elseif target == kTargetIphone or target == kTargetIpad then
    device.platform = "ios"
    if target == kTargetIphone then
        device.model = "iphone"
    else
        device.model = "ipad"
    end
end

if device.model == "unknown" then
    print("1111")
    if CCDeviceModel and not isNetThread then
         print("1112")
        device.model = CCDeviceModel:getDeviceModel()
    end    
end

--local language_ = sharedApplication:getCurrentLanguage()
--if language_ == kLanguageChinese then
--    language_ = "cn"
--elseif language_ == kLanguageFrench then
--    language_ = "fr"
--elseif language_ == kLanguageItalian then
--    language_ = "it"
--elseif language_ == kLanguageGerman then
--    language_ = "gr"
--elseif language_ == kLanguageSpanish then
--    language_ = "sp"
--elseif language_ == kLanguageRussian then
--    language_ = "ru"
--else
--    language_ = "en"
--end


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
   
    if device.packageName == "unknown" then
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

function device.showActivityIndicator()
    CCNative:showActivityIndicator()
end

function device.hideActivityIndicator()
    CCNative:hideActivityIndicator()
end

function device.showAlert(title, message, buttonLabels, listener)
    if type(buttonLabels) ~= "table" then
        buttonLabels = { tostring(buttonLabels) }
    end
    local defaultLabel = ""
    if #buttonLabels > 0 then
        defaultLabel = buttonLabels[1]
        table.remove(buttonLabels, 1)
    end

    CCNative:createAlert(title, message, defaultLabel)
    for i, label in ipairs(buttonLabels) do
        CCNative:addAlertButton(label)
    end

    if type(listener) ~= "function" then
        listener = function() end
    end

    CCNative:showAlertLua(listener)
end

function device.cancelAlert()
    CCNative:cancelAlert()
end

--- Get device open UDID
-- @return Device UDID string.
local udid = nil
function device.getOpenUDID()
    if udid == nil then
        if device.platform == "android" then
            local luaj = require"luaj"
            --local javaClassName = "com.ldfs.sanguo.MobileUtils"
            --local javaClassName = "com/ldfs/sanguo/MobileUtils"
            --local javaClassName = "com/ldfs/sanguo2/MobileUtils"

            local javaClassName = device.getPackageName().."/MobileUtils"
            local javaMethodName = "getOpenUDID"
            local javaMethodSig = "()Ljava/lang/String;"
            local result, udid1 = luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
            udid = udid1
            print(result, udid)
        else
            udid = CCNative:getOpenUDID()
        end
    else
        print("cache udid")
    end
    return udid
    ---return CCNative:getOpenUDID()
end

--- Open url by device.
function device.openURL(url)
    CCNative:openURL(url)
end

function device.showInputBox(title, message, defaultValue)
    title = title or "INPUT TEXT"
    message = message or "INPUT TEXT, CLICK OK BUTTON"
    defaultValue = defaultValue or ""
    return CCNative:getInputText(title, message, defaultValue)
end

if not isNetThread then
    local openGLView = CCDirector:sharedDirector():getOpenGLView()
    local frameSize = openGLView:getFrameSize()
    device.SCREEN_WIDTH = frameSize.width
    device.SCREEN_HEIGHT = frameSize.height
end

--- return device module.
return device


