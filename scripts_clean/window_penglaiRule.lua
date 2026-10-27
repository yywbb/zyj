
local penglaiRule = {
    rootNode = nil,
    rootItems = nil,
}

function penglaiRule.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("island3/island_rule", nil, true, "island_rule")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function penglaiRule.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("penglaiRule")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end

function penglaiRule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return penglaiRule

