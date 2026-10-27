--
-- Author: songyibo
-- Date: 2019-12-04 13:33:13
--
--
local fengshenRule = {
    rootNode = nil,
    rootItems = nil,
}

function fengshenRule.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("shop/fengshen_rule", nil, true, "fengshen_rule")
    self.touchPriority = touchPriority

    self:reload(data,callback)
    return self.rootNode
end

function fengshenRule.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("fengshenRule")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

end

function fengshenRule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return fengshenRule