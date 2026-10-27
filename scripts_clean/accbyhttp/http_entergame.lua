--
-- Created by IntelliJ IDEA.
-- User: lichungeng
-- Date: 16/8/29
-- Time: 下午1:59
-- To change this template use File | Settings | File Templates.
--

require("Prompts")
local http_entergame = {

    busytimer = nil,

    strings={
        [0] = "选服地址出错",
        [1] = "网络连接中断...",
        [2] = "选服请求超时...",
        [3] = "选服请求无响应",
        [4] = "选服请求出错",
    },
}

function http_entergame.runGamePrompt(self,dataTable)

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

function http_entergame.entergame(self,params)

    self.geturl = gamedata.sdk.address.entergameAddress
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
                        success = false
                        errorcode = responsedata.result.errorcode
                        if errorcode == 2 then
                            UIResponse({type = 7,time = responsedata.result.time,msg = responsedata.msg})
                        else
                            self:runGamePrompt({msg = responsedata.msg or self.strings[4]})
                        end
                    else

                        local data = {
                            type = 5,
                            uuid = responsedata.result.uuid,
                            section = responsedata.result.section,
                        }

                        UIResponse(data)
                    end                    
                end
            end
        end

        if not success then
            UIResponse({type = 6})
        end
    end

    executeHttpPost = function()

        local timestamp = os.time_ and os.time_() or os.time()

        local requestdata = "session="..params.session.."&sid="..params.sid.."&timestamp="..timestamp
        
        require"mymd5"
        local md5code = md5sumhexa(requestdata)

        local requesturl = self.geturl.."?"..requestdata.."&sign="..md5code
        print("entergame requestdata",requesturl)

        local httpReq = CCHttpRequest:new()
        httpReq:setUrl(requesturl)
        httpReq:setRequestType(0)

        httpReq:registerScriptTapHandler(responseMethod)
        CCHttpClient:getInstance():setTimeoutForConnect(10)
        CCHttpClient:getInstance():setTimeoutForRead(10)
        CCHttpClient:getInstance():send(httpReq)
        httpReq:release()
    end
    executeHttpPost()

    return true
end


return http_entergame

