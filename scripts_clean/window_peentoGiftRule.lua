
local peentoGiftRule = {
    rootNode = nil,
    rootItems = nil,
}

function peentoGiftRule.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("pantaoxianli/pantaoxianli_rule", nil, true, "pantao_rule")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function peentoGiftRule.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("peentoGiftRule")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end

function peentoGiftRule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return peentoGiftRule

