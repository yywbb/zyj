--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 18/3/8
-- Time: 15:00
-- To change this template use File | Settings | File Templates.
--

local bosschallenge_double = {
    rootNode = nil,
    rootItems = nil,
}

function bosschallenge_double.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("bosschallenge/bosschallenge_tishi", nil, true, "bosschallenge_tishi")
    self.touchPriority = touchPriority
    self.callback = callback
    self:reload(data)
    return self.rootNode
end

function bosschallenge_double.reload(self,data)

    ui.setLabelString(self.rootItems.yesLab,nil,19)
    ui.setLabelString(self.rootItems.noLab,nil,19)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("bosschallenge_double")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    --
    self.rootItems.noButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("bosschallenge_double")
    end, CCControlEventTouchUpInside)
    self.rootItems.noButton:setSwallowsTouch(true)
    self.rootItems.noButton:setTouchPriority(self.touchPriority)
    --
    self.rootItems.yesButton:addHandleOfControlEvent(function()
        UIRequest({type = 5211,opt = 1})
        gameWindows:closeWindow("bosschallenge_double")
    end, CCControlEventTouchUpInside)
    self.rootItems.yesButton:setSwallowsTouch(true)
    self.rootItems.yesButton:setTouchPriority(self.touchPriority)


end

function bosschallenge_double.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return bosschallenge_double