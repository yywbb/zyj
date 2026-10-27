--
-- Author: songyibo
-- Date: 2020-03-02 15:05:02
--


local confirm = {
    rootNode = nil,
    rootItems = nil,
}

function confirm.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("island3/confirm", nil, true, "confirm")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function confirm.reload(self,data,callback)

	local count = data.count
	local reset_gold = 0
	local reset_gold = 0 

    if gamedata.config.buycount_price[tostring(count+1)] then
        reset_gold = gamedata.config.buycount_price[tostring(count+1)].penglai3reset or 0
    end

    self.rootItems.freeNode:setVisible(reset_gold <= 0)
    self.rootItems.confirmNode:setVisible(reset_gold > 0)
    self.rootItems.gold:setString(reset_gold)
    
    ui.setLabelString(self.rootItems.conceltext,gameConfig.strings:string_common("popups","fanhui"),18)
    self.rootItems.concel:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("island2Confirm")
    end, CCControlEventTouchUpInside)
    self.rootItems.concel:setSwallowsTouch(true)
    self.rootItems.concel:setTouchPriority(self.touchPriority)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("island2Confirm")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.confirmtext,gameConfig.strings:string_common("popups","queding"),18)
    self.rootItems.confirm:addHandleOfControlEvent(function()
        self.callback = callback
        gameWindows:closeWindowDirect("island2Confirm")
    end, CCControlEventTouchUpInside)
    self.rootItems.confirm:setSwallowsTouch(true)
    self.rootItems.confirm:setTouchPriority(self.touchPriority)
end

function confirm.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
        self.callback = nil
    end
end

return confirm