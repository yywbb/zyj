--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/25
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--

local guildmsg = {
    rootNode = nil,
    rootItems = nil,
}

function guildmsg.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("gonghui2/gonghui_tc_tishi", nil, true, "msg")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function guildmsg.reload(self,data,callback)
    self.callback = nil

    if data and data.msg then
        self.rootItems.msg:setString(data.msg)
    end

    if data and data.button_lab then
        self.rootItems.yesLab:setString(data.button_lab)
    end

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("guildmsg")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.noLab,nil,19)
    self.rootItems.noButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("guildmsg")
    end, CCControlEventTouchUpInside)
    self.rootItems.noButton:setSwallowsTouch(true)
    self.rootItems.noButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.yesLab,nil,19)
    self.rootItems.yesButton:addHandleOfControlEvent(function()
        self.callback = callback
        gameWindows:closeWindowDirect("guildmsg")
    end, CCControlEventTouchUpInside)
    self.rootItems.yesButton:setSwallowsTouch(true)
    self.rootItems.yesButton:setTouchPriority(self.touchPriority)

end

function guildmsg.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return guildmsg

