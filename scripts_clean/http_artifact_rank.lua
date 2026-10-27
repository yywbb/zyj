--
-- Created by IntelliJ IDEA.
-- User: lichungeng
-- Date: 16/8/29
-- Time: 下午1:59
-- To change this template use File | Settings | File Templates.
--

require("Prompts")
local http_artifact_rank = {

    busytimer = nil,

    strings={
        [0] = "",
        [1] = "网络延时请稍等.",
        [2] = "网络延时请稍等..",
        [3] = "网络延时请稍等...",
        [4] = "网络延时请稍等....",
    },
    
    geturl = "",

    retrytime = 0,
}

function http_artifact_rank.runGamePrompt(self,dataTable)

    print("http_artifact_rank.runGamePrompt")

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

function http_artifact_rank.clear( self )

end

function http_artifact_rank.getdata(self,callback)

    print("http_artifact_rank.getdata")

    self.geturl = gamedata.config.cross_trump_rank and gamedata.config.cross_trump_rank.url.value or ""

    self.callback = callback
   
    local responseMethod,executeHttpPost
    responseMethod =  function(tag,response)

        if not response:isSucceed() then
            cclog("post %s error msg:%s", self.geturl, response:getErrorBuffer())

            if ui.isWiFI3G() ==0 then
                self:runGamePrompt({msg = self.strings[1]})
            elseif string.find(response:getErrorBuffer(),"timedout") or string.find(response:getErrorBuffer(),"timed out") then
                self:runGamePrompt({msg = self.strings[2]})
            else
                self:runGamePrompt({msg = self.strings[4]})
            end 

        else
            if not response:getResponseDataBuffer() then
                self:runGamePrompt({msg = self.strings[3]})

            else
                require"myjson"
                --print("getResponseDataBuffer",response:getResponseDataBuffer())
                local responsedata = LoadJsonStringToTable(response:getResponseDataBuffer())

                if not responsedata then
                    self:runGamePrompt({msg = self.strings[4]})

                else
                    --printT(responsedata)
                    --todo
                    if responsedata.data then 
                        self.callback(responsedata.data)   
                    end        
                end
            end
        end

    end

    executeHttpPost = function()
        --local sharedApplication = CCApplication:sharedApplication()
        --local target = sharedApplication:getTargetPlatform()

        local id = gamedata.config.cross_trump_rank and gamedata.config.cross_trump_rank.cross_id.value or 0        

        local requestdata = "id="..id
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



return http_artifact_rank

