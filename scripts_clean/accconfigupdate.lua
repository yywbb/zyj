--
-- Created by IntelliJ IDEA.
-- User: lichungeng
-- Date: 16/8/29
-- Time: 下午1:59
-- To change this template use File | Settings | File Templates.
--

require("Prompts")
local resourcedownload = {

    url="",
    filename  = "compress.zip",
    size = 0,
    totalfilenum = 0,

    TimeoutForConnect = 5,
    TimeoutForRead = 100000,

    retrytime = 0,
    maxretrytime = 10,

    sizedownload = 0,
    numunzip = 0,


    updatetimer = nil,

    isbusy = false,
    busytimer = nil,

    sizepre = 0,

    strings={
        [0] = "",
        [1] = "网络连接中断...",
        [2] = "配置更新请求超时...",
        [3] = "配置更新请求无响应",
        [4] = "配置更新请求出错",
        [5] = "更新配置文件...",
        [6] = "解压中...",
        [7] = "配置下载出错，开始重新下载",
        [8] = "配置下载更新包出错",
        [9] = "配置下载更新包超时",
    },
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

function resourcedownload.findversionnum(self,section)

    local mydb = SQLite3Open()
    if nil == mydb then
        return nil
    end
    local ret = 0
    local SQL = "SELECT Section, VersionNum FROM ConfigVersion where Section = "..section
    for row in mydb:rows(SQL) do
        ret=row[2]
    end
    mydb:close()

    return ret
end

function resourcedownload.findwritepath(self)

    -- local strindex = string.find(gWPath,"compress")
    -- if strindex then
    --     return string.sub(gWPath,1,strindex-1)
    -- end
    if not self.writepath then
        self.writepath = gWPath.."config/"
        myfile.mkdir(self.writepath)
    end
    
    return self.writepath
end

function resourcedownload.checkifneedupdate(self,params)
    self.callback = params.callback or self.callback

    UIResponse({type = 9998, log2 = "config check..." })

    self.geturl = gamedata.sdk.address.configupdateAddress
    if not self.geturl or self.geturl == "" then self:clearWithError() return end

    self.section = params.section
    local localversionnum = self:findversionnum(params.section)
    print("checkconfigupdate localversionnum ",localversionnum)
    
    local responseMethod,executeHttpPost
    responseMethod =  function(tag,response)
        if not response:isSucceed() then
            cclog("post %s error msg:%s", self.geturl, response:getErrorBuffer())

            if ui.isWiFI3G() ==0 then
                self:runGamePrompt({msg = self.strings[1]})
                --executeHttpPost() 
            elseif string.find(response:getErrorBuffer(),"timedout") or string.find(response:getErrorBuffer(),"timed out") then
                self:runGamePrompt({msg = self.strings[2]})
                --self:clearWithError()
            else
                self:runGamePrompt({msg = self.strings[4]})
                --self:clearWithError() 
            end 
            executeHttpPost()
        else
            if not response:getResponseDataBuffer() then
                self:runGamePrompt({msg = self.strings[3]})
                self:clearWithError()
                return
            else
                require"myjson"
                print("getResponseDataBuffer",response:getResponseDataBuffer())
                local responsedata = LoadJsonStringToTable(response:getResponseDataBuffer())

                if not responsedata then
                    self:runGamePrompt({msg = self.strings[4]})
                    self:clearWithError()
                    return
                end

                printT(responsedata)

                if not responsedata.success or responsedata.success == "false" then
                    --self:runGamePrompt({msg = self.strings[4]})
                    self:clearWithError()
                    return
                else
                    if responsedata.result.version <= 0 then 
                        self:clearWithError()
                        return
                    elseif responsedata.result.version<=tonumber(localversionnum) then
                        self:clearWithNormal()
                        return
                    end

                    self.result = responsedata.result 
                    self.md5 = responsedata.result.sign 
                    self.url = responsedata.result.url 
                    self.size = responsedata.result.size 
                    self.totalfilenum = responsedata.result.file_length
                    self.server_version = responsedata.result.version
                    
                    if not self.url or type(self.url) ~= "string" then
                        self:runGamePrompt({msg = self.strings[4]})
                        self:clearWithError()
                        return
                    end
                    if not self.size or type(self.size) ~= "number" then
                        self:runGamePrompt({msg = self.strings[4]})
                        self:clearWithError()
                        return
                    end
                    if not self.server_version or type(self.server_version) ~= "number" then
                        self:runGamePrompt({msg = self.strings[4]})
                        self:clearWithError()
                        return
                    end
                    if not self.totalfilenum or type(self.totalfilenum) ~= "number" then
                        self:runGamePrompt({msg = self.strings[4]})
                        self:clearWithError()
                        return
                    end

                    self.filename = params.section.."_"..localversionnum.."_"..self.server_version..".zip"
                
                    if CCFileUtils:sharedFileUtils():fullPathForFilename(self.filename) ~= self.filename then
                        self.updatetimer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
                            self:updateprocess()
                        end, 0, false)
                        UIRequest({type = 6666666,opt = "config",zippath = self:findwritepath()..self.filename,writepath = self:findwritepath()})
                        self.status =  "unziping"
                    elseif self.url ~= "" and self.size ~=0 then         
                        self.updatetimer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
                            self:updateprocess()
                        end, 0, false)
                        self:download()
                        self.status =  "downloading"
                    else
                        self:runGamePrompt({msg = self.strings[4]})
                        self:clearWithError()
                    end
                end
            end
        end
    end

    executeHttpPost = function()
        local sharedApplication = CCApplication:sharedApplication()
        local target = sharedApplication:getTargetPlatform()

        local gchannel = gamedata.gameconfig.channel..(gamedata.sdk.channelid or "") 
        print("gchannel",gchannel)

        local timestamp = os.time_ and os.time_() or os.time()

        local requestdata = "channel="..gchannel.."&section="..self.section.."&timestamp="..timestamp.."&version="..localversionnum
        
        require"mymd5"
        local md5code = md5sumhexa(requestdata)
        print("configupdate requestdata",requestdata,md5code)

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

function resourcedownload.download(self)
    if self.busytimer then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.busytimer)
        self.busytimer = nil
        self.isbusy = false
    end

    local responseMethod,executeHttpDownload
    responseMethod =  function (tag,response)
        cclog("CHttpResponse-----%s %s %s %s", tag, response, response:isSucceed(), response:getResponseCode())
        if not response:isSucceed() then
            cclog("download %s error msg:%s", self.url, response:getErrorBuffer())
       
            if ui.isWiFI3G() ==0 then
                self:runGamePrompt({msg = self.strings[1]})
            elseif string.find(response:getErrorBuffer(),"timeout") or string.find(response:getErrorBuffer(),"time out") then
                self:runGamePrompt({msg = self.strings[9]})
            else
                self:runGamePrompt({msg = self.strings[8]})
            end

            executeHttpDownload()
        else
            self:downloadcomplete(response:getResponseDataBuffer())
        end
    end
    executeHttpDownload = function()
        self.sizepre = self.sizedownload or 0
        local httpReq = CCHttpRequest:new()
        httpReq:setUrl(self.url)
        httpReq:setRequestType(0)

        httpReq:registerScriptTapHandler(responseMethod)
        CCHttpClient:getInstance():setTimeoutForConnect(self.TimeoutForConnect)

        CCHttpClient:getInstance():setTimeoutForRead(self.TimeoutForRead)
        CCHttpClient:getInstance():send(httpReq)
        httpReq:release()
    end
    executeHttpDownload()
end

function resourcedownload.updateprocess(self)
    if not self.status then return end
    if self.status == "downloading" then
        self:showdownloadprocess()
    elseif self.status == "unziping" then
        self:showunzipprocess()
    end
end

function resourcedownload.checkspeed(self,sizenow)   
    local timenow = os.time() 
    if not self.checkbegintime then self.checkbegintime = timenow end
    if not self.checkbeginsize then self.checkbeginsize = sizenow end
    if not self.timenow then self.timenow = timenow end

    if timenow - self.timenow >2 then
        self.checkbegintime = timenow
        self.checkbeginsize = sizenow
    end

    self.lowtime = self.lowtime or 0
    if timenow > self.timenow then
        self.downloadspeed = sizenow - self.checkbeginsize     
        self.checkbeginsize = sizenow   
        if self.downloadspeed == 0 then
            self.lowtime = (self.lowtime or 0) +1
        else
            self.lowtime = 0
        end 
    end
    self.timenow = timenow

    if self.lowtime > 9 then
        local net = ui.isWiFI3G()
        if net == 0 then
            self:runGamePrompt({msg = self.strings[1]})
        else
            -- self:createprompt({msg = "網路不給力"})  
        end
        
        self.lowtime = 0
    end
end

function resourcedownload.showdownloadprocess(self)

    self.sizedownload = CCHttpClient:getInstance():getDownLoadSizeOfGet()
    if self.sizedownload < self.sizepre then
        self.sizepre = 0
    end
    self.sizedownload = self.sizedownload - self.sizepre
    self:checkspeed(self.sizedownload)

    print("self.sizedownload",self.sizedownload)

    if LoginScene.status then
        if LoginScene.processLayerItem and LoginScene.processLayerItem.log then
            local length = string.format("%0.2f",self.sizedownload/1048576)
            local total = string.format("%0.2f",self.size/1048576)
            local speed = string.format("%0.1f",(self.downloadspeed or 0)/1024)
            LoginScene.processLayerItem.tip:setString(self.strings[5])
            LoginScene.processLayerItem.log:setString(length.."M/"..total.."M("..speed.."K/s)")
            LoginScene:showDownloadProcess({type = "updateconfig", index = math.min(length,total),total = total})
        end
    end
end

function resourcedownload.showunzipprocess(self)

    self.numunzip = CCDeviceModel:getunzipfilenums()
    print("self.numunzip",self.numunzip)

    if LoginScene.status then
        LoginScene.processLayerItem.log:setString("")
        LoginScene:showDownloadProcess({type = "updateconfig", index = math.min(self.numunzip,self.totalfilenum),total = self.totalfilenum})
    end
end

function resourcedownload.downloadcomplete(self,data)
    print("data len ======",string.len(data))

    require"mymd5"
    local md5code = md5sumhexa(data)
    print(md5code,self.md5)
    if self.md5 and self.md5 ~= "" and md5code ~= self.md5 then 
        self:download()
        self:runGamePrompt({msg = 7})
    else

        local filepath = self:findwritepath()..self.filename
        local filehandle = io.open(filepath,"wb")
        if nil ~= filehandle then
            filehandle:write(data)
            filehandle:close()
        else
 
        end
        UIRequest({type = 6666666,opt = "config",zippath = filepath,writepath = self:findwritepath()})
        self.status =  "unziping"
    end
end

function resourcedownload.unzipcomplete( self )

    if LoginScene.status then
        LoginScene.processLayerItem.log:setString("")
    end
    
    local mydb = SQLite3Open()
    if nil == mydb then
        return nil
    end

    local SQL = "UPDATE ConfigVersion set VersionNum = " .. self.server_version .. " where Section = "..self.section
    mydb:exec(SQL)

    if mydb:changes() == 0 then
        SQL = string.format("INSERT INTO ConfigVersion (Section,VersionNum) VALUES (%d,%d)", self.section, self.server_version)
        mydb:exec(SQL)
    end

    mydb:close()

    self:clear()
end

function resourcedownload.clear(self)
    if self.updatetimer then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.updatetimer)
        self.updatetimer = nil
    end
end

function resourcedownload.clearWithNormal(self)
    print("clearWithNormal")
    self:clear()
    UIRequest({type = 6666666,opt = "config"})
end

function resourcedownload.clearWithError(self)
    print("clearWithError")
    self:clear()
    UIRequest({type = 2})
end

return resourcedownload

