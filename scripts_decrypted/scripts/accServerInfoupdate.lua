--
-- Created by IntelliJ IDEA.
-- User: lichungeng
-- Date: 16/8/29
-- Time: 下午1:59
-- To change this template use File | Settings | File Templates.
--

require("Prompts")
local resourcedownload = {

    TimeoutForConnect = 5,
    TimeoutForRead = 10,

    retrytime = 0,
    maxretrytime = 10,

    isbusy = false,
    busytimer = nil,

    strings={
        [0] = "",
        [1] = "网络连接中断...",
        [2] = "服务器信息请求超时...",
        [3] = "服务器信息请求无响应",
        [4] = "服务器信息请求出错",
        [5] = "服务器信息请求失败",
        [6] = "服务器信息下载失败",
        [7] = "服务器信息下载超时",
        [8] = "服务器信息下载出错",
    }
}

function resourcedownload.runGamePrompt(self,dataTable)

    if self.isbusy then return end
    self.isbusy = true
    self.busytimer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
        self.isbusy = false
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.busytimer)
        self.busytimer = nil
    end, 4, false)  

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

function resourcedownload.findversionnum(self)
    local mydb = SQLite3Open()
    if nil == mydb then
        return nil
    end
    local ret = 0
    local SQL = "SELECT VersionNum FROM ServerListVersion"
    for row in mydb:nrows(SQL) do
        ret=row["VersionNum"]
    end
    if ret == 0 then
        SQL = "INSERT INTO ServerListVersion VALUES (0)"
        mydb:exec(SQL)
    end
    mydb:close()
    return ret
end

function resourcedownload.updateVersionNum(self,version)
        local mydb = SQLite3Open()
    if nil == mydb then
        return nil
    end

    local SQL = "UPDATE ServerListVersion set VersionNum="..tonumber(version)
    mydb:exec(SQL)
    mydb:close()
end

function resourcedownload.checkifneedupdate(self,url,callback)

    self.callback = callback or self.callback

    UIResponse({type = 9998, log = "服务器信息更新..." })

    self.geturl = url
    print("accserverinfoupdate url ==",self.geturl)
    if not self.geturl or self.geturl == "" then 
        self.callback()
        return 
    end

    local localversionnum = self:findversionnum()
    print("checkserverinfoupdate localversionnum ",localversionnum)
    
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
            executeHttpPost()  
        else
            local responsedata = response:getResponseDataBuffer()
            if not responsedata then
                self:runGamePrompt({msg = self.strings[3]})
                executeHttpPost()
                return
            else
                require"myjson"
                print("getResponseDataBuffer",responsedata)
                responsedata = LoadJsonStringToTable(responsedata)

                if not responsedata then
                    self:runGamePrompt({msg = self.strings[4]})
                    executeHttpPost()
                    return
                end

                printT(responsedata)

                if responsedata.success and responsedata.success == "true" then
                    if responsedata.result and responsedata.result~="" and next(responsedata.result) then

                        self.serverVersion = tonumber(responsedata.result.version)
                        self.result = responsedata.result
                        self.url = self.result.url1
                        self:download()
                    else
                        self:clear()
                    end
                else
                    self:clear()
                    return
                end
            end
        end
    end

    executeHttpPost = function()
        local sharedApplication = CCApplication:sharedApplication()
        local target = sharedApplication:getTargetPlatform()

        local gchannel = gamedata.gameconfig.channel..(gamedata.sdk.channelid or "").."_"..gamedata.gameconfig.submit 
        print("gchannel",gchannel)

        local timestamp = os.time_ and os.time_() or os.time()
        local requestdata = "channel="..gchannel.."&timestamp="..timestamp.."&version="..localversionnum
        require"mymd5"
        local md5code = md5sumhexa(requestdata)
        print("serverupdate requestdata",requestdata,md5code)

        local httpReq = CCHttpRequest:new()
        httpReq:setUrl(self.geturl.."?"..requestdata.."&sign="..md5code)
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

function resourcedownload.findurl( self )
    
    if math.mod(self.retrytime,2) ==0 then
        self.url = self.result and (self.result.url1 or self.url) or self.url
    elseif math.mod(self.retrytime,3) ==1 then
        self.url = self.result and (self.result.url2 or self.url) or self.url
    end
    self.retrytime = self.retrytime + 1
end

function resourcedownload.download(self)
    if self.busytimer then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.busytimer)
        self.busytimer = nil
        self.isbusy = false
    end
    self.retrytime = 0
    
    local responseMethod,executeHttpDownload
    responseMethod =  function (tag,response)
        cclog("CHttpResponse-----%s %s %s %s", tag, response, response:isSucceed(), response:getResponseCode())
        if not response:isSucceed() then
            cclog("download %s error msg:%s", self.url, response:getErrorBuffer())


            if ui.isWiFI3G() ==0 then
                self:runGamePrompt({msg = self.strings[1]})
            elseif string.find(response:getErrorBuffer(),"timeout") or string.find(response:getErrorBuffer(),"time out") then
                self:runGamePrompt({msg = self.strings[7]})
            else
                self:runGamePrompt({msg = self.strings[8]})
            end
 
            executeHttpDownload()
        else
            self:downloadcomplete(response:getResponseDataBuffer())
        end
    end
    executeHttpDownload = function()
        self:findurl()
        local httpReq = CCHttpRequest:new()
        httpReq:setUrl(self.url)
        httpReq:setRequestType(0)

        httpReq:registerScriptTapHandler(responseMethod)
        CCHttpClient:getInstance():setTimeoutForConnect(5)

        CCHttpClient:getInstance():setTimeoutForRead(10)
        CCHttpClient:getInstance():send(httpReq)
        httpReq:release()
    end
    executeHttpDownload()
end

function resourcedownload.findwritepath( self )
    return gWPath
end

function resourcedownload.downloadcomplete(self,data)

    local filepath = self:findwritepath().."GameServer.json"
    local filehandle = io.open(filepath,"wb")
    if nil ~= filehandle then
        filehandle:write(data)
        filehandle:close()
    else

    end

    require"myjson"
    local test = LoadJsonFileToTable(filepath)

    if test then 
        self:updateVersionNum(self.serverVersion)
        self:clear()
    else
        self:runGamePrompt({msg = self.strings[6]})
        self:download()
    end
end

function resourcedownload.clear(self)
    local path = CCFileUtils:sharedFileUtils():fullPathForFilename("GameServer.json")
    local destpath = self:findwritepath().."GameServer.json"
    if path ~= destpath then
        CCDeviceModel:copyFile(path,destpath)
        CCFileUtils:sharedFileUtils():purgeCachedEntries()
    end
    if self.callback then self.callback() end
end

return resourcedownload

  6$  