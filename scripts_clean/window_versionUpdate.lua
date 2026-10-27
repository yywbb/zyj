--新版本更新的显示

local versionUpdate = {
	rootNode = nil,
	rootItems = nil,
}

function versionUpdate.open(self,touchPriority,data,callback)
	self.rootNode, self.rootItems = CCBReaderLoad("tanchuang/tc_gengxin",nil,true,"gengxin")
	self.touchPriority = touchPriority
	self:reload(data,callback)
    ui.setLabelString(self.rootItems["startLable"],"继续",18)
	return self.rootNode
end

function versionUpdate.reload(self,data,callback)
	self.callback = callback
    --内容
    self.rootItems["updateLabel"]:setString(data.content)
    --时间
--    local starttime = os.date("(%Y-%m-%d %H:%M)",data.begint)
--    local endtime = os.date("(%Y-%m-%d %H:%M)",data.endt)
--
--    self.rootItems["updatetime"]:setString("时间: "..starttime.." - ".. endtime)

    self.rootItems["updateTitle"]:setString(data.title)

    if data.opt == 0 then
        --进入按钮
        self.rootItems.startButton:setVisible(true)
        self.rootItems.startLable:setVisible(true)
        self.rootItems.startButton:addHandleOfControlEvent(function()
            gameWindowslogin:closeWindowDirect("versionUpdate")

            -- gameWindows:closeWindowDirect("versionUpdate")
            -- gameWindows:openWindow("downloadUpdate",nil)
        end,CCControlEventTouchUpInside)
        self.rootItems.startButton:setSwallowsTouch(true)
        self.rootItems.startButton:setTouchPriority(self.touchPriority)
    elseif data.opt == 2 then
        --强更跳转
        self.rootItems.startButton:setVisible(true)
        self.rootItems.startLable:setVisible(true)
        self.rootItems.startButton:addHandleOfControlEvent(function()
            if gamedata.sdk then
                gamedata.sdk:forceUpdate(data.url)
            end
        end,CCControlEventTouchUpInside)
        self.rootItems.startButton:setSwallowsTouch(true)
        self.rootItems.startButton:setTouchPriority(self.touchPriority)

    else
        self.rootItems.startButton:setVisible(false)
        self.rootItems.startLable:setVisible(false)

        local tiemdis = data.servertime - os.time()

        local timenow = os.time()

        self.timer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
            if math.abs(os.time()-timenow) >2 then
                CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.timer)
                loading:restart()
                return
            end
            timenow = os.time()

            if data.endt - (os.time()+tiemdis) < 0 then
                gameWindowslogin:closeWindowDirect("versionUpdate")
            end
         end, 1, false)
    end
end

function versionUpdate.close(self)

    if self.timer then CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.timer) end

	self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
    	self.callback()
    end
end

return versionUpdate



