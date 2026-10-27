-- 耐力密码说明

local nailicode_rule = {
    rootNode = nil,
    rootItems = nil,

    callback = nil,
}

function nailicode_rule.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority

    self.rootNode, self.rootItems = CCBReaderLoad("MainScene/2weima_rule", nil, true, "2weima_rule")
    self.callback  = callback
    
    --返回
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("nailicode_rule")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
        
    self.root:addChild(self.rootNode)

    return self.root
end

function nailicode_rule.reloadData(self, data)

end

function nailicode_rule.close(self) 
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return nailicode_rule