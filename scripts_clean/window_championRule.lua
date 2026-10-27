local championRule = {
    rootNode = nil,
    rootItems = nil,
}

function championRule.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("chamipon/chamipon_rule", nil, true, "Rule")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function championRule.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("championRule")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end

function championRule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return championRule

