--
-- Created by IntelliJ IDEA.
-- User: lichungeng
-- Date: 16/8/29
-- Time: 下午1:59
-- To change this template use File | Settings | File Templates.
--

require("Prompts")
local http_post = {

    busytimer = nil,

    strings={
        [0] = "公告地址出错",
        [1] = "网络连接中断...",
        [2] = "网络有点忙,请稍等..",
        [3] = "网络有点忙,请稍等...",
        [4] = "网络有点忙,请稍等....",
    },

    errstr = {
        [999] = "网络连接中断，请检查网络",
        [0] = "网络繁忙，请稍后在试",
    },
    

    retrytime = 0,
}

function http_post.runGamePrompt(self,dataTable)

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

function http_post.checkpost(self)

    UIResponse({type = 9998, log = "获取服务器状态..." })

    self.geturl = gamedata.sdk.address.postAddress
    if not self.geturl or self.geturl == "" then 
        self:runGamePrompt({msg = self.strings[0]})
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
                errorcode = 999
            elseif string.find(response:getErrorBuffer(),"timedout") or string.find(response:getErrorBuffer(),"timed out") then
                self:runGamePrompt({msg = self.strings[2]})
            else
                self:runGamePrompt({msg = self.strings[4]})
            end 
            success = false
        else
            if not response:getResponseDataBuffer() then
                self:runGamePrompt({msg = self.strings[3]})
                success = false
            else
                require"myjson"
                print("getResponseDataBuffer",response:getResponseDataBuffer())
                local responsedata = LoadJsonStringToTable(response:getResponseDataBuffer())

                if not responsedata then
                    self:runGamePrompt({msg = self.strings[4]})
                    success = false
                else
                    printT(responsedata)
                    if not responsedata.success or responsedata.success == "false" then
                        self:runGamePrompt({msg = responsedata.msg or self.strings[4]})
                        success = false
                    else

                        local event = responsedata.result
                        UIResponse({type = 80,event = event})
                    end                    
                end
            end
        end

        if not success then
            self.busytimer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
                if self.retrytime>=5 then
                    loading:exitGame(self.errstr[errorcode])
                else
                    executeHttpPost()    
                end
                CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.busytimer)
                self.busytimer = nil
            end, 4, false) 
        end
    end

    executeHttpPost = function()
        local sharedApplication = CCApplication:sharedApplication()
        local target = sharedApplication:getTargetPlatform()

        local gchannel = gamedata.gameconfig.channel..(gamedata.sdk.channelid or "") 
        local forceupdate = gamedata.gameconfig.forceupdate
        local timestamp = os.time_ and os.time_() or os.time()

        local requestdata = "channel="..gchannel.."&forceupdate="..forceupdate.."&timestamp="..timestamp
        
        require"mymd5"
        local md5code = md5sumhexa(requestdata)

        local requesturl = self.geturl.."?"..requestdata.."&sign="..md5code
        print("post requestdata",requesturl)

        local httpReq = CCHttpRequest:new()
        httpReq:setUrl(requesturl)
        httpReq:setRequestType(0)

        httpReq:registerScriptTapHandler(responseMethod)
        CCHttpClient:getInstance():setTimeoutForConnect(10)
        CCHttpClient:getInstance():setTimeoutForRead(10)
        CCHttpClient:getInstance():send(httpReq)
        httpReq:release()

        self.retrytime = self.retrytime+1
    end
    executeHttpPost()

    return true
end


return http_post

