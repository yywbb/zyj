--
-- Created by IntelliJ IDEA.
-- User: lichungeng
-- Date: 16/8/29
-- Time: 下午1:59
-- To change this template use File | Settings | File Templates.
--

require("localfile")
require"sqlite3init"
SQLite3Init()
local resourcedownload = {

    urls = {
        {
            url="http://yq-res.kylinga.com/zyj_gat/1.0.9/spine.zip",
            filename  = "spine.zip",
            size = 12217709,
            totalfilenum = 772,
        },
        {
            url="http://yq-res.kylinga.com/zyj_gat/1.0.9/battle.zip",
            filename  = "battle.zip",
            size = 18653173,
            totalfilenum = 716,
        },
        {
            url="http://yq-res.kylinga.com/zyj_gat/1.0.9/battle1.zip",
            filename  = "battle1.zip",
            size = 18156754,
            totalfilenum = 830,
        },
        -- {
        --     url="http://yq-res.kylinga.com/zyj_gat/1.0.9/battle2.zip",
        --     filename  = "battle2.zip",
        --     size = 16944974,
        --     totalfilenum = 697,
        -- },
        -- {
        --     url="http://yq-res.kylinga.com/zyj_gat/1.0.9/battle3.zip",
        --     filename  = "battle3.zip",
        --     size = 16433927,
        --     totalfilenum = 770,
        -- },
        {
            url="http://yq-res.kylinga.com/zyj_gat/1.0.9/UI.zip",
            filename  = "UI.zip",
            size = 25218293,
            totalfilenum = 1361,
        },
        {
            url="http://yq-res.kylinga.com/zyj_gat/1.0.9/UI1.zip",
            filename  = "UI1.zip",
            size = 26149218,
            totalfilenum = 2284,
        },
    },

    url="http://yq-res.kylinga.com/zyj_gat/1.0.0/compress.zip",
    filename  = "compress.zip",
    size = 15183586,
    totalfilenum = 5938,

    TimeoutForConnect = 5,
    TimeoutForRead = 100000,

    retrytime = 0,
    maxretrytime = 20,

    sizedownload = 0,
    numunzip = 0,

    sizeneeddown = 0,

    isboss = false,

    downloadspeed = 0,

    index = 1,
    index_s = 1,

    updatetimer = nil,
}

function resourcedownload.findstatus(self)

    local mydb = SQLite3Open()
    if nil == mydb then
        return nil
    end

    local SQL = "SELECT  KEY, VALUE FROM downloadInfoTable where KEY = 'download'"
    local downloadstatus = "0"
    for row in mydb:rows(SQL) do
        downloadstatus = row[2]
    end

    local SQL2 = "SELECT  KEY, VALUE FROM downloadInfoTable where KEY = 'unzip'"
    local unzipstatus = "0"
    for row in mydb:rows(SQL2) do
        unzipstatus = row[2]
    end

    mydb:close()

    if tonumber(downloadstatus) < #self.urls then
        self.status = "downloading"
        self.index = tonumber(downloadstatus) +1
        self.size = 0
        for i=1,#self.urls do
            self.size = self.size + self.urls[i].size
            if i<self.index then
                self.sizedownload = self.sizedownload + self.urls[i].size
            else
                self.sizeneeddown = self.sizeneeddown + self.urls[i].size
            end
        end
    elseif tonumber(unzipstatus) < #self.urls then
        self.status = "unziping"
        self.index = tonumber(unzipstatus) +1
        self.totalfilenum = 0
        for i=1,#self.urls do
            self.totalfilenum = self.totalfilenum + self.urls[i].totalfilenum
            if i<self.index then
                self.numunzip = self.numunzip + self.urls[i].totalfilenum
            end
        end
    else
        return true
    end

    return false
end

function resourcedownload.findwritepath(self)

    -- local strindex = string.find(gWPath,"compress")
    -- if strindex then
    --     return string.sub(gWPath,1,strindex-1)
    -- end
    return gWPath
end

function resourcedownload.createscene(self,scene)
    self.rootNode,self.rootitem = CCBReaderLoad("ccb1/ziploading.ccbi", nil, true, "ziploading")

    local openGLView = CCDirector:sharedDirector():getOpenGLView()
    local frameSize = openGLView:getFrameSize()
    self.rootNode:setAnchorPoint(ccp(0.5, 0))
    self.rootNode:setPosition(frameSize.width/2, 0)
    local Scale = 1
    if frameSize.width/frameSize.height <= 640.0/960 then
        Scale =frameSize.width/1080
    else
        Scale = (frameSize.height/1620)
    end
    self.rootNode:setScale(Scale)

    self.rootitem.partical:setPositionType(kCCPositionTypeGrouped)
    self.rootitem.posnode:setPosition(207, 218)
    self.rootitem.posnode:setZOrder(1)
    self.rootitem.downloadsize:setZOrder(1)

    local barsprite = CCSprite:createWithSpriteFrameName("loadingprocessbar.png")
    self.rootitem.processBar = CCProgressTimer:create(barsprite)
    self.rootitem.processBar:setAnchorPoint(ccp(0.047, 0.494))
    self.rootitem.processBar:setType(kCCProgressTimerTypeBar)
    self.rootitem.processBar:setMidpoint(ccp(0, 0.5))
    self.rootitem.processBar:setBarChangeRate(ccp(1, 0))
    self.rootitem.processBar:setPosition(ccp(207, 218))
    self.rootitem.processBar:setPercentage(4.7)
    self.rootitem.processBar:setScale(1)
    self.rootNode:addChild(self.rootitem.processBar)

    self.scene = scene
    self.scene:addChild(self.rootNode)

    if bRunWithScene then
        CCDirector:sharedDirector():runWithScene(scene)
        bRunWithScene = false
    else
        if CCDirector:sharedDirector():getRunningScene() ~= scene then
            CCDirector:sharedDirector():replaceScene(scene)
        end
    end
end

function resourcedownload.createprompt(self,dataTable)
    local promptLoaderLayer, ccbDocumentControler = CCBReaderLoad("ccb1/Prompt", nil, true, "Prompt")

    local openGLView = CCDirector:sharedDirector():getOpenGLView()
    local frameSize = openGLView:getFrameSize()
    promptLoaderLayer:setPosition(ccp(frameSize.width/2, frameSize.height * 0.618))
    ccbDocumentControler.node:setScale(frameSize.width/1080)

    CCDirector:sharedDirector():getRunningScene():addChild(promptLoaderLayer,10000)

    local promptLabel = tolua.cast(ccbDocumentControler.promptLabel, "CCLabelTTF") --提示信息label
    promptLabel:setString(dataTable["msg"])

    -------------------------------------------------------------------------------------------------------------------
    local animationManager = getAnimationManager(ccbDocumentControler)
    --动画完成操作
    animationManager:setAnimationCompletedCallback(function()
        promptLoaderLayer:removeFromParentAndCleanup(true)
    end)
    --先播放动画
    animationManager:runAnimationsForSequenceNamed("prompt")
end

function resourcedownload.createtip(self,size,callback)
    -- body
    self.tip,self.tipitem = CCBReaderLoad("ccb1/tip.ccbi", nil, true, "tip")

    local openGLView = CCDirector:sharedDirector():getOpenGLView()
    local frameSize = openGLView:getFrameSize()

    self.tip:setPosition(frameSize.width/2, frameSize.height/2)
    local Scale = 1
    if frameSize.width/frameSize.height <= 640.0/960 then
        Scale =frameSize.width/1080
    else
        Scale = (frameSize.height/1620)
    end
    self.tip:setScale(Scale)
    self.scene:addChild(self.tip,2)

    self.tipitem.size:setString("您還需要下載"..string.format("%0.2f",self.sizeneeddown/1048576).."M的資源，建議在WIFI環境下載")
    self.tipitem.sizedes:setString("當前網路不是WIFI環境，是否繼續？(老闆請隨意^_^)")

    ui.setLabelString(self.tipitem.conceltext,"取 消",18)
    self.tipitem.concel:addHandleOfControlEvent(function()
        loading:exit()      
    end, CCControlEventTouchUpInside)
    self.tipitem.concel:setSwallowsTouch(true)
    self.tipitem.concel:setTouchPriority(-1)

    ui.setLabelString(self.tipitem.confirmtext,"確 定",18)
    self.tipitem.confirm:addHandleOfControlEvent(function()
        self.tip:removeFromParentAndCleanup(true)
        self.isboss = true
        callback()
    end, CCControlEventTouchUpInside)
    self.tipitem.confirm:setSwallowsTouch(true)
    self.tipitem.confirm:setTouchPriority(-1)
end

function resourcedownload.createtipnetclosed(self,callback)
    -- body
    self.tipnet,self.tipnetitem = CCBReaderLoad("ccb1/tipnetclosed.ccbi", nil, true, "tipnetclosed")

    local openGLView = CCDirector:sharedDirector():getOpenGLView()
    local frameSize = openGLView:getFrameSize()

    self.tipnet:setPosition(frameSize.width/2, frameSize.height/2)
    local Scale = 1
    if frameSize.width/frameSize.height <= 640.0/960 then
        Scale =frameSize.width/1080
    else
        Scale = (frameSize.height/1620)
    end
    self.tipnet:setScale(Scale)
    self.scene:addChild(self.tipnet,2)

    self.tipnetitem.size:setString("網路已斷開，請檢查網路連接！確認聯網後點擊確定繼續")

    ui.setLabelString(self.tipnetitem.confirmtext,"確 定",18)
    self.tipnetitem.confirm:addHandleOfControlEvent(function()
        self.tipnet:removeFromParentAndCleanup(true)
        callback()
    end, CCControlEventTouchUpInside)
    self.tipnetitem.confirm:setSwallowsTouch(true)
    self.tipnetitem.confirm:setTouchPriority(-1)
end

function resourcedownload.checknet(self,callback)
    local net = ui.isWiFI3G()
    self.net = net
    if net == 0 then
        self:createtipnetclosed(function( ... )
            self:checknet(callback)
        end)
    elseif net == 1 then
        if self.isboss then
            callback() 
        else
            self:createtip(self.size,function()
                callback()
            end)
        end
    elseif net == 2 then
        callback() 
    end
end

function resourcedownload.checkifneeddownload(self,params,scene)
    self.callback = params.callback or self.callback

    local iscomplete = self:findstatus()

    if iscomplete then
        local timer = nil
        timer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
            if timer then
                CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(timer)
                timer = nil
            end
            UIRequest({type = 666666,opt = "noneedunzip"})
            if self.callback then self.callback() end
        end, 0, false)
    else
        self:createscene(scene)
        self.updatetimer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
            self:updateprocess()
        end, 0, false)
        if self.status == "downloading" then
            self:download()
        elseif self.status == "unziping" then
            self:unzip()
        end
    end

    return true
end

function resourcedownload.download(self)
    self.url = self.urls[self.index].url
    self.filename = self.urls[self.index].filename

    print(self.index)
    printT(self.urls[self.index])

    local responseMethod,executeHttpDownload
    responseMethod =  function (tag,response)
        cclog("CHttpResponse-----%s %s %s %s", tag, response, response:isSucceed(), response:getResponseCode())
        if not response:isSucceed() then
            cclog("download %s error msg:%s", self.url, response:getErrorBuffer())
            self.retrytime = self.retrytime + 1
            if self.retrytime>1 then
                if os.time() - self.errortime >= 4 then
                    self:createprompt({msg = "連接逾時，請檢查網路連接"})
                    self.errortime = os.time()
                end
            end              
            executeHttpDownload()
            cclog("%s retry %d time", self.url, self.retrytime)
        else
            self:downloadcomplete(response:getResponseDataBuffer())
        end
    end
    executeHttpDownload = function()
        self.retrytime = 0
        self.errortime = os.time()
        local httpReq = CCHttpRequest:new()
        httpReq:setUrl(self.url)
        httpReq:setRequestType(0)

        httpReq:registerScriptTapHandler(responseMethod)
        CCHttpClient:getInstance():setTimeoutForConnect(self.TimeoutForConnect)

        CCHttpClient:getInstance():setTimeoutForRead(self.TimeoutForRead)
        CCHttpClient:getInstance():send(httpReq)
        httpReq:release()
    end
    self:checknet(function( ... )
        executeHttpDownload()
        self.net = 2
    end)
end

function resourcedownload.unzip( self )
    self.filename = self.urls[self.index].filename

    print(self.index)
    printT(self.urls[self.index])

    UIRequest({type = 666666,opt = "needunzip",zippath = gWPath..self.filename,writepath = self:findwritepath()})
    -- body
end

function resourcedownload.updateprocess(self)
    local tret = uiqueue.popresponsefromclient()

    if tret and tret.type == 666666 then
        self:unzipcomplete()
    end

    if not self.status then return end
    if self.status == "downloading" then
        self:showdownloadprocess()
    elseif self.status == "unziping" then
        self:showunzipprocess()
    end
end

function resourcedownload.checkspeed(self,sizenow)
    if not self.net or self.net ~= 2 then return end     
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
            self:createprompt({msg = "網路已斷開，請檢查網路連接"})
        else
            -- self:createprompt({msg = "網路不給力"})  
        end
        
        self.lowtime = 0
    end


    -- if timenow-self.checkbegintime >10 then
    --     if sizenow-self.checkbeginsize == 0 then
    --         self:createprompt({msg = "網路已斷開，請檢查網路連接"})
    --     elseif sizenow-self.checkbeginsize < 10240 then
    --         self:createprompt({msg = "網路不給力"})
    --     end
    --     self.checkbegintime = timenow
    --     self.checkbeginsize = sizenow
    -- end
    -- body
end

function resourcedownload.showdownloadprocess(self)

    if not self.lastsizedownload then self.lastsizedownload = 0 end
    local sizenow = CCHttpClient:getInstance():getDownLoadSizeOfGet()
    if sizenow>=self.lastsizedownload then
        self.sizedownload = self.sizedownload + (sizenow-self.lastsizedownload)
    else
        local sizeext = 0
        if self.index>self.index_s then
            for i=self.index_s,self.index-1 do
                sizeext = sizeext + self.urls[i].size
            end
        end
        self.sizedownload = sizeext + sizenow
    end
    self.lastsizedownload = sizenow

    if self.rootitem then
        self.rootitem.statusdes:setDisplayFrame(CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("ziploading_4.png"))

        local length = string.format("%0.2f",self.sizedownload/1048576)
        local total = string.format("%0.2f",self.size/1048576)
        local speed = string.format("%0.1f",self.downloadspeed/1024)

        self.rootitem.downloadsize:setString(length.."M/"..total.."M("..speed.."K/s)")
        local percentage = (self.sizedownload/self.size)*100
        self.rootitem.processBar:setPercentage(4.7+90.6*percentage/100.0)
        self.rootitem.posnode:setPosition((872-207)*percentage/100.0 + 207, 218)
    end
    self:checkspeed(self.sizedownload)
end

function resourcedownload.showunzipprocess(self)

    if not self.lastnumunzip then self.lastnumunzip = 0 end
    local numnow = CCDeviceModel:getunzipfilenums()
    if numnow>=self.lastnumunzip then
        self.numunzip = self.numunzip + (numnow-self.lastnumunzip)
    else
        local numext = 0
        if self.index>self.index_s then
            for i=self.index_s,self.index-1 do
                numext = numext + self.urls[i].totalfilenum
            end
        end
        self.numunzip = numext + numnow
    end
    self.lastnumunzip = numnow

    if self.rootitem then
        self.rootitem.statusdes:setDisplayFrame(CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName("ziploading_1.png"))
        self.rootitem.downloadsize:setString("")
        local percentage = (self.numunzip/self.totalfilenum)*100
        self.rootitem.processBar:setPercentage(4.7+90.6*percentage/100.0)
        self.rootitem.posnode:setPosition((872-207)*percentage/100.0 + 207, 218)
    end
end

function resourcedownload.downloadcomplete(self,data)

    WriteFile(gWPath..self.filename, data)

    local mydb = SQLite3Open()
    if nil == mydb then
        return nil
    end

    local SQL2 = "UPDATE downloadInfoTable set VALUE='"..self.index.."' where KEY = 'download'";
    mydb:exec(SQL2)
    mydb:close()

    if self.index >= #self.urls then
        self.index = 1
        self.totalfilenum = 0
        for i=self.index,#self.urls do
            self.totalfilenum = self.totalfilenum + self.urls[i].totalfilenum
        end
        self.status = "unziping"
        self:unzip()
    else
        self.index = self.index +1
        self:download()
    end
end

function resourcedownload.unzipcomplete( self )
    local mydb = SQLite3Open()
    if nil == mydb then
        return nil
    end

    local SQL2 = "UPDATE downloadInfoTable set VALUE='"..self.index.."' where KEY = 'unzip'";
    mydb:exec(SQL2)
    mydb:close()

    print("unzipcomplete",self.filename,CCDeviceModel:getunzipfilenums())

    if self.index >= #self.urls then
        self:clear()
        UIRequest({type = 666666,opt = "noneedunzip"})
    else
        self.index = self.index +1
        self:unzip()
    end
    -- body
end

function resourcedownload.clear(self)

    if self.updatetimer then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.updatetimer)
        self.updatetimer = nil
    end

    if self.scene then
        self.scene:removeAllChildrenWithCleanup(true)
        self.scene = nil
        self.rootNode = nil
        self.rootitem = nil
    end

    CCTextureCache:sharedTextureCache():removeTextureForKey("ccb1/ziploading.png")
    CCSpriteFrameCache:sharedSpriteFrameCache():removeSpriteFramesFromFile("ccb1/ziploading.plist")

    if self.callback then self.callback() end
end

return resourcedownload

