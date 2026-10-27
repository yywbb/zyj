--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/7/6
-- Time: 10:21
-- To change this template use File | Settings | File Templates.
--


local goddownRule = {
    rootNode = nil,
    rootItems = nil,
}

function goddownRule.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("activitypig/pig_rule", nil, true, "pig_rule")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    self:initFixedString()
    return self.rootNode
end

function goddownRule.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("goddownRule")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end

function goddownRule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

function goddownRule.initFixedString(self)
    self.rootItems.title:setString(gameConfig.strings:string_common("fixedString","goddown",2))

end

return goddownRule