--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/25
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--

local baglimittip = {
    rootNode = nil,
    rootItems = nil,
}

function baglimittip.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("loading/confirm", nil, true, "confirm")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function baglimittip.reload(self,data,callback)

    ui.setLabelString(self.rootItems.des,data.msg,47)
    self.rootItems.closeButton:setVisible(false)


    -- ui.setLabelString(self.rootItems.confirmtext,"确 定",18)
    ui.setLabelString(self.rootItems.confirmtext,data.confirmtext and data.confirmtext or gameConfig.strings:string_common("popups","queding"),18)
    self.rootItems.confirm:addHandleOfControlEvent(function()
        self.callback = callback
        gameWindows:closeWindowDirect("baglimittip")
    end, CCControlEventTouchUpInside)
    self.rootItems.confirm:setSwallowsTouch(true)
    self.rootItems.confirm:setTouchPriority(self.touchPriority)
end

function baglimittip.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
        self.callback = nil
    end
end

return baglimittip

