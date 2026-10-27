

local safemaskRule = {
    rootNode = nil,
    rootItems = nil,
}

function safemaskRule.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("safemask/safemask_rule", nil, true, "safemask_rule")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    self:initFixedString()
    return self.rootNode
end

function safemaskRule.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("safemaskRule")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end

function safemaskRule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

function safemaskRule.initFixedString(self)
    self.rootItems.title:setString(gameConfig.strings:string_common("fixedString","goddown",2))

end

return safemaskRule