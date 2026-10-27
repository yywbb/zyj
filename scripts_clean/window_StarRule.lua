local starRule = {
    rootNode = nil,
    rootItems = nil,
}

function starRule.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("activitystar/star_rule", nil, true, "starRule")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function starRule.reload(self,data,callback)
    self.callback = callback    
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("starRule")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end

function starRule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return starRule

