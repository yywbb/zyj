--
-- Created by IntelliJ IDEA.
-- User: lichungeng
-- Date: 16/8/29
-- Time: 下午1:59
-- To change this template use File | Settings | File Templates.
--

require("Prompts")
local http_check = {

    busytimer = nil,

    strings={
        [0] = "",
        [1] = "网络延时请稍等.",
        [2] = "网络延时请稍等..",
        [3] = "网络延时请稍等...",
        [4] = "网络延时请稍等....",
        [5] = "包体非法",
    },
    

    retrytime = 0,
}

function http_check.runGamePrompt(self,dataTable)

    local promptLoaderLayer, ccbDocumentControler = CCBReaderLoad("Prompts/GamePrompt", nil, true, "GamePrompt")

    local openGLView = CCDirector:sharedDirector():getOpenGLView()
    local frameSize = openGLView:getFrameSize()

    promptLoaderLayer:setPosition(ccp(frameSize.width/2, frameSize.height * 0.618))
    ccbDocumentControler.node:setScale(frameSize.width/1080)

    local nowScene = CCDirector:sharedDirector():getRunningScene()
    nowScene:addChild(promptLoaderLayer,10000)

    local promptLabel = tolua.cast(ccbDocumentControler.promptLabel, "CCLabelTTF") --提示信息label
    promptLabel:setString(dataTable["msg"] or "")

    -------------------------------------------------------------------------------------------------------------------
    local animationManager = getAnimationManager(ccbDocumentControler)
    --动画完成操作
    animationManager:setAnimationCompletedCallback(function()
    --移除
        promptLoaderLayer:removeFromParentAndCleanup(true)
    end)
    --先播放动画
    animationManager:runAnimationsForSequenceNamed("prompt")
end

function http_check.checkisvalid(self)

    UIResponse({type = 9998, log = "检查本地数据..." })

    self.geturl = gamedata.sdk.address.packageAddress
    if not self.geturl or self.geturl == "" then 
        print("no checkpackage url")
        UIResponse({type = 333333})
        return 
    end

    if gamedata.device.platform ~= "android" then
        print("not android noneed checkpackage")
        UIResponse({type = 333333})
        return 
    end

    
    local responseMethod,executeHttpPost
    responseMethod =  function(tag,response)

        local success = true
        local errorcode = 0
        if not response:isSucceed() then
            cclog("post %s error msg:%s", self.geturl, response:getErrorBuffer())

            if ui.isWiFI3G() ==0 then
                self:runGamePrompt({msg = self.strings[1]})
            elseif string.find(response:getErrorBuffer(),"timedout") or string.find(response:getErrorBuffer(),"timed out") then
                self:runGamePrompt({msg = self.strings[2]})
            else
                self:runGamePrompt({msg = self.strings[4]})
            end 
            errorcode = 999
            success = false
        else
            if not response:getResponseDataBuffer() then
                self:runGamePrompt({msg = self.strings[3]})
                success = false
                errorcode = 999
            else
                require"myjson"
                print("getResponseDataBuffer",response:getResponseDataBuffer())
                local responsedata = LoadJsonStringToTable(response:getResponseDataBuffer())

                if not responsedata then
                    self:runGamePrompt({msg = self.strings[4]})
                    success = false
                    errorcode = 999
                else
                    printT(responsedata)
                    if not responsedata.success or responsedata.success == "false" then
                        loading:exitGame(self.strings[5])
                    else
                        UIResponse({type = 333333})
                    end                    
                end
            end
        end

        if not success then
            if errorcode == 999 then
                UIResponse({type = 333333})
            end
        end
    end

    executeHttpPost = function()
        local sharedApplication = CCApplication:sharedApplication()
        local target = sharedApplication:getTargetPlatform()

        local appname = self:getAppname()
        local channel = gamedata.gameconfig.channel..(gamedata.sdk.channelid or "")         
        local deviceid = gamedata.device.getOpenUDID()
        local package = self:getPackagename()
        local packagesign = self:getSign()
        local version = gamedata.gameconfig.version

        local requestdata = "appname="..appname.."&channel="..channel.."&deviceid="..deviceid.."&package="..package.."&packagesign="..packagesign.."&version="..version
        print(requestdata)

        local httpReq = CCHttpRequest:new()
        httpReq:setUrl(self.geturl)
        httpReq:setRequestType(1)
        httpReq:setRequestData(requestdata,string.len(requestdata))

        httpReq:registerScriptTapHandler(responseMethod)
        CCHttpClient:getInstance():setTimeoutForConnect(5)
        CCHttpClient:getInstance():setTimeoutForRead(5)
        CCHttpClient:getInstance():send(httpReq)
        httpReq:release()

        self.retrytime = self.retrytime+1
    end
    executeHttpPost()

    return true
end

function http_check.getAppname( self )
    local namestr = ""
    if gamedata.device.platform == "android" then
        local luaj = require"luaj"

        local javaClassName = "org/cocos2dx/lib/Cocos2dxHelper"
        local javaMethodName = "getAppName"
        local javaMethodSig = "()Ljava/lang/String;"

        local result, name = luaj.callStaticMethod(javaClassName, javaMethodName, "", javaMethodSig)
        namestr = name or ""
    end
    return namestr
end

function http_check.getPackagename( self )
    local packagestr = ""
    if gamedata.device.platform == "android" then
        local luaj = require"luaj"

        local javaClassName = "org/cocos2dx/lib/Cocos2dxHelper"
        local javaMethodName = "getCocos2dxPackageName"
        local javaMethodSig = "()Ljava/lang/String;"

        local result, packgename = luaj.callStaticMethod(javaClassName, javaMethodName, "", javaMethodSig)
        packagestr = packgename or ""
    end
    return packagestr
end

function http_check.getSign( self )
    local signstr = ""
    if gamedata.device.platform == "android" then
        local luaj = require"luaj"

        local javaClassName = "org/cocos2dx/lib/Cocos2dxHelper"
        local javaMethodName = "checkAppSignature"
        local javaMethodSig = "()Ljava/lang/String;"

        local result, sign = luaj.callStaticMethod(javaClassName, javaMethodName, "", javaMethodSig)
        signstr = sign or ""
    end
    return signstr
end


return http_check

