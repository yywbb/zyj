--
-- Author: songyibo
-- Date: 2021-03-03 11:57:04
--

local sculpturePost = {
    rootNode = nil,
    rootItems = nil,
    data= {},

    cancelTip = "sculpture",
}

function sculpturePost.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("activityreward_new/diaosu_pailian", nil, true, "diaosu_pailian")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function sculpturePost.reload(self,data,callback)
    self.callback = callback

    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("sculpturePost")
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.goLab,nil,19)
    self.rootItems.goButton:setSwallowsTouch(true)
    self.rootItems.goButton:setTouchPriority(self.touchPriority)
    self.rootItems.goButton:addHandleOfControlEvent(function()
        self.callback = nil
        GameScene:shiftLayerById(610)
    end, CCControlEventTouchUpInside)

    local tip_time = gamedata.config.global_kv.sculpture_dividend_countdown and tonumber(gamedata.config.global_kv.sculpture_dividend_countdown.value) or 0
   
    self.rootItems.timeNode:setVisible(false)
    local timediff = GameScene.layers["activity"].module:getActivityRemainingTime(180)
    if timediff > 0 and timediff < tip_time*24*3600 then
    	self.rootItems.timeNode:setVisible(true)
    	ui.setLabelString(self.rootItems.timelab,nil,14,36)
    	gameTimer:rigistTime("sculpturePost", timediff)
	    gameTimer:rigistTimeFunc("sculpturePost",function()

	        if gameTimer.times["sculpturePost"] >= 0 then
	            ui.setLabelString(self.rootItems.time,ui.makeTimeDayText(gameTimer.times["sculpturePost"],"day"),26,36)
	        end
	        if gameTimer.times["sculpturePost"] <= 0 then
	            gameTimer:UnrigistTimeFunc("sculpturePost")
	        end
	    end)
    end
end

function sculpturePost.close(self)

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if gameTimer.times["sculpturePost"] then
        gameTimer:UnrigistTimeFunc("sculpturePost")
    end

    if self.callback then
        self.callback()
        self.callback = nil
    end
end

return sculpturePost