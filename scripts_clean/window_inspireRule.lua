
local inspireRule = {
    rootNode = nil,
    rootItems = nil,
}

function inspireRule.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("gonghuizhan/gonghuizhan_guwurule", nil, true, "guwurule")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function inspireRule.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("inspireRule")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end

function inspireRule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return inspireRule