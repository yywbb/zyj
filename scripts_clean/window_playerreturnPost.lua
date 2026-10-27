
local playerreturnPost = {
    rootNode = nil,
    rootItems = nil,

    cancelTip = "playerreturn",
}

function playerreturnPost.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("activityplayerreturn/playerreturnpost", nil, true, "playerreturnpost")
    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function playerreturnPost.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        --self.callback = nil
        gameWindows:closeWindowDirect("playerreturnPost")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.gotoButton:addHandleOfControlEvent(function()
        --self.callback = nil
        gameWindows:closeWindowDirect("playerreturnPost")
        GameScene:shiftLayerById(246)
    end, CCControlEventTouchUpInside)
    self.rootItems.gotoButton:setSwallowsTouch(true)
    self.rootItems.gotoButton:setTouchPriority(self.touchPriority-1)

    ui.setLabelString(self.rootItems.gotoLab,nil,19)
    --

end

function playerreturnPost.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return playerreturnPost

