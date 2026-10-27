
local cornucopiaRule = {
    rootNode = nil,
    rootItems = nil,
}

function cornucopiaRule.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("activitymoney/money_help", nil, true, "money_help")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function cornucopiaRule.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("cornucopiaRule")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end

function cornucopiaRule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return cornucopiaRule

