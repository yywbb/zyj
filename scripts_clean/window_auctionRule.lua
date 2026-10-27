local auctionRule = {
    rootNode = nil,
    rootItems = nil,
}

function auctionRule.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("paimaihang/paimiahang_rule", nil, true, "paimaihang_rule")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function auctionRule.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("auctionRule")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end

function auctionRule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return auctionRule

