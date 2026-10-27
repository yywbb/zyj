--
-- Created by IntelliJ IDEA.
-- User: lichungeng
-- Date: 16/6/18
-- Time: 下午5:25
-- To change this template use File | Settings | File Templates.
--

local tigerchickenRule = {
    rootNode = nil,
    rootItems = nil,
}

function tigerchickenRule.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("activitytigerchicken/tigerchicken_rule", nil, true, "tigerchicken_rule")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function tigerchickenRule.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("tigerchickenRule")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end

function tigerchickenRule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return tigerchickenRule