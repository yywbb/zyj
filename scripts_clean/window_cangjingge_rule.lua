

local cangjingge_rule = {
    rootNode = nil,
    rootItems = nil,
}

function cangjingge_rule.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("cangjingge/cangjingge_rule", nil, true, "cangjingge_rule")
    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function cangjingge_rule.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("cangjingge_rule")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end

function cangjingge_rule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end


return cangjingge_rule