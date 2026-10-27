

local shengxiantai_rule = {
    rootNode = nil,
    rootItems = nil,
}

function shengxiantai_rule.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("shengxiantai/shengxiantai_rule", nil, true, "shengxiantai_rule")
    self.touchPriority = touchPriority

    self:reload(data,callback)

    return self.rootNode
end

function shengxiantai_rule.reload(self,data,callback)
    self.callback = callback

    self.rootItems.scrollview = tolua.cast(self.rootItems.scrollview, "CCScrollView")
    self.rootItems.scrollview:setTouchPriority(self.touchPriority)
    self.rootItems.scrollview:setContentOffsetInDuration(ccp(0,-370),0)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("shengxiantai_rule")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end

function shengxiantai_rule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return shengxiantai_rule