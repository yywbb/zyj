--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/25
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--

local guildquit = {
    rootNode = nil,
    rootItems = nil,
}

function guildquit.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("gonghui2/gonghui_tc_tuichu", nil, true, "quit")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function guildquit.reload(self,data,callback)
    self.callback = callback



    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("guildquit")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.noLab,nil,19)
    self.rootItems.noButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("guildquit")
    end, CCControlEventTouchUpInside)
    self.rootItems.noButton:setSwallowsTouch(true)
    self.rootItems.noButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.yesLab,nil,19)
    self.rootItems.yesButton:addHandleOfControlEvent(function()
        gameWindows:closeWindowDirect("guildquit")
    end, CCControlEventTouchUpInside)
    self.rootItems.yesButton:setSwallowsTouch(true)
    self.rootItems.yesButton:setTouchPriority(self.touchPriority)

end

function guildquit.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return guildquit

