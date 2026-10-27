
local peentoSurePanel = {
    rootNode = nil,
    rootItems = nil,
}

function peentoSurePanel.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("pantaoxianli/pantaoxianli_queren", nil, true, "pantaoxianli_queren")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function peentoSurePanel.reload(self,data,callback)
    self.callback = callback
    self.rootItems.canelBtn:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("peentoSurePanel")
    end, CCControlEventTouchUpInside)
    self.rootItems.canelBtn:setSwallowsTouch(true)
    self.rootItems.canelBtn:setTouchPriority(self.touchPriority)
    
    self.rootItems.sureBtn:addHandleOfControlEvent(function()
        if self.callback then
            self.callback()
            self.callback = nil
        end
        gameWindows:closeWindow("peentoSurePanel")
    end, CCControlEventTouchUpInside)
    self.rootItems.sureBtn:setSwallowsTouch(true)
    self.rootItems.sureBtn:setTouchPriority(self.touchPriority)
    
    self.rootItems.consumeN:setString(gameConfig.strings:string_format({"activity",6},{data.num}))
end

function peentoSurePanel.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    -- if self.callback then
    --     self.callback()
    -- end
end

return peentoSurePanel

