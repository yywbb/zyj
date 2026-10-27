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
        [0] = "更新地址出错",
        [1] = "网络连接中断...",
        [2] = "网络有点忙,请稍等..",
        [3] = "网络有点忙,请稍等...",
        [4] = "网络有点忙,请稍等....",
        [5] = "下载更新包...",
        [6] = "安装更新包...",
        [7] = "网络有点忙,请稍等.....",
        [8] = "网络有点忙,请稍等......",
        [9] = "网络有点忙,请稍等.......",
    },

}

function resourcedownload.runGamePrompt(self,dataTable)

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
    local SQL = "SELECT VersionNum FROM ResourcesVersion"
    for row in mydb:nrows(SQL) do
        ---print("VersionNUm:"..row["VersionNum"])
        ret=row["VersionNum"]
    end
    if ret == 0 then
        SQL = "INSERT INTO ResourcesVersion VALUES (0)"
        mydb:exec(SQL)
        ---log(string.format("sqlite err in syncresource: %s",mydb:errmsg()));
    end
    mydb:close()

    return ret
end

function resourcedownload.findwritepath(self)

    local strindex = string.find(gWPath,"compress")
    if strindex then
        return string.sub(gWPath,1,strindex-1)
    end
    return gWPath
end

function resourcedownload.checkifneedupdate(self)

    if not gamedata.gameconfig.isupdate then
        self:clear()
        return
    end

    UIResponse({type = 9998, log = "检查更新..." })

    self.geturl = gamedata.sdk.address.updateAddress

    print("resourceupdate url ==",self.geturl)
    if not self.geturl or self.geturl == "" then 
        self:runGamePrompt({msg = self.strings[0]})
        return  
    end

    local localversionnum = self:findversionnum()
    print("checkifneedupdate localversionnum ",localversionnum)
    
    local responseMethod,executeHttpPost
    responseMethod =  function(tag,response)

        local success = true
        if not response:isSucceed() then
            cclog("post %s error msg:%s", self.posturl, response:getErrorBuffer())

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
                        self:runGamePrompt({msg = self.strings[4]})
                        success = false
                    else
                        if responsedata.result.version <= 0 then 
                            self:clear()
                            return
                        elseif responsedata.result.version<=tonumber(localversionnum) then
                            self:clear()
                            return
                        end

                        self.result = responsedata.result 
                        self.md5 = responsedata.result.sign 
                        self.url = responsedata.result.url 
                        self.size = responsedata.result.size 
                        self.totalfilenum = responsedata.result.file_length
                        self.server_version = responsedata.result.version
                        self.needrestart = responsedata.result.needrestart and responsedata.result.needrestart == "yes"
                        
                        if not self.url or type(self.url) ~= "string" then
                            self:runGamePrompt({msg = self.strings[4]})
                            success = false
                        elseif not self.size or type(self.size) ~= "number" then
                            self:runGamePrompt({msg = self.strings[4]})
                            success = false
                        elseif not self.server_version or type(self.server_version) ~= "number" then
                            self:runGamePrompt({msg = self.strings[4]})
                            success = false
                        elseif not self.totalfilenum or type(self.totalfilenum) ~= "number" then
                            self:runGamePrompt({msg = self.strings[4]})
                            success = false
                        else
                            self.filename = localversionnum.."_"..self.server_version..".zip"

                            if CCFileUtils:sharedFileUtils():fullPathForFilename(self.filename) ~= self.filename then
                                self.updatetimer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
                                    self:updateprocess()
                                end, 0, false)
                                self:unzip()
                            elseif self.url ~= "" and self.size ~=0 then         
                                function continueCB(  )
                                    self.updatetimer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
                                        self:updateprocess()
                                    end, 0, false)
                                    self:download()
                                end

                                if self.size < 1048576 then --1048576 then
                                    continueCB()
                                else
                                    gameWindowslogin:openWindow("downloadUpdate",{length = self.size},continueCB)
                                end
                            else
                                self:runGamePrompt({msg = self.strings[4]})
                                success = false
                            end                            
                        end
                    end
                end
            end
        end
        if not success then
            self.busytimer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
                executeHttpPost()

                CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.busytimer)
                self.busytimer = nil
            end, 3, false) 
        end
    end

    executeHttpPost = function()
        local sharedApplication = CCApplication:sharedApplication()
        local target = sharedApplication:getTargetPlatform()
        local platform = "android"
        if target == kTargetIphone or target == kTargetIpad then
            platform = "ios"
        end
        local gchannel = gamedata.gameconfig.channel..(gamedata.sdk.channelid or "").."_"..gamedata.gameconfig.submit 
        print("gchannel",gchannel)

        local requestdata = self.geturl.."?version="..localversionnum.."&platform="..platform.."&channel="..gchannel
        print("resourceupdate requestdata",requestdata)

        local httpReq = CCHttpRequest:new()
        httpReq:setUrl(requestdata)
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

            self.busytimer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
                executeHttpDownload()

                CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.busytimer)
                self.busytimer = nil
            end, 3, false) 
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
    self.status =  "downloading"
end

function resourcedownload.unzip( self )
    UIRequest({type = 666666,opt = "needunzip",zippath = gWPath..self.filename,writepath = self:findwritepath(),restart = self.needrestart})
    self.status =  "unziping"
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
        if LoginScene.enterLayer then
            LoginScene:showNode(LoginScene.enterLayerItem.processNode,true)
            LoginScene:showNode(LoginScene.enterLayerItem.enterNode,false)
            LoginScene:showNode(LoginScene.enterLayerItem.serverlistNode,false)
            LoginScene:showNode(LoginScene.enterLayerItem.loadingNode,false)
        end
        local length = string.format("%0.2f",self.sizedownload/1048576)
        local total = string.format("%0.2f",self.size/1048576)
        local speed = string.format("%0.1f",(self.downloadspeed or 0)/1024)
        ui.setLabelString(LoginScene.enterLayerItem.tip,self.strings[5],13)
        ui.setLabelString(LoginScene.enterLayerItem.persentage,length.."M/"..total.."M("..speed.."K/s)",13)
        ui.setSpriteTextureRect2(LoginScene.enterLayerItem.resourceprocess,0,0,921*(self.sizedownload/self.size),33)
    end
end

function resourcedownload.showunzipprocess(self)

    self.numunzip = CCDeviceModel:getunzipfilenums()
    print("self.numunzip",self.numunzip)
    if self.numunzip>self.totalfilenum then
        self.numunzip = self.totalfilenum
    end

    if LoginScene.status then
        if LoginScene.enterLayer then
            LoginScene:showNode(LoginScene.enterLayerItem.processNode,true)
            LoginScene:showNode(LoginScene.enterLayerItem.enterNode,false)
            LoginScene:showNode(LoginScene.enterLayerItem.serverlistNode,false)
            LoginScene:showNode(LoginScene.enterLayerItem.loadingNode,false)
        end
        ui.setLabelString(LoginScene.enterLayerItem.tip,self.strings[6],13)
        ui.setLabelString(LoginScene.enterLayerItem.persentage,"",13)
        ui.setSpriteTextureRect2(LoginScene.enterLayerItem.resourceprocess,0,0,921*(math.min(1,self.numunzip/self.totalfilenum)),33)
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
        local filepath = gWPath..self.filename
        local filehandle = io.open(filepath,"wb")
        if nil ~= filehandle then
            filehandle:write(data)
            filehandle:close()
        else
 
        end

        self:unzip()
    end
end

function resourcedownload.unzipcomplete( self )
    local mydb = SQLite3Open()
    if nil == mydb then
        return nil
    end

    local SQL = "UPDATE ResourcesVersion set VersionNum="..self.server_version
    mydb:exec(SQL)
    mydb:close()

    if LoginScene.status and LoginScene.enterLayer then
        LoginScene:showNode(LoginScene.enterLayerItem.loadingNode,true)
        LoginScene:showNode(LoginScene.enterLayerItem.processNode,false)
    end
    local gameversion = require"config_version"
    if gameversion.showversion then 
        gameversion:showversion()
    end

    self:clear(self.needrestart)
end

function resourcedownload.clear(self,restart)
    if self.updatetimer then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.updatetimer)
        self.updatetimer = nil
    end

    if restart then
        UIRequest({type = 777777})
        UIResponse({type = 777777})
    else
        UIResponse({type = 555555})
    end
end

return resourcedownload

