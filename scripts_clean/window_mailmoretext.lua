--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/4/8
-- Time: 16:32
-- To change this template use File | Settings | File Templates.
--

local mailmoretext = {
    rootNode = nil,
    rootItems = nil,
}

function mailmoretext.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("mails/cell_mail_more", nil, true, "cell_mail_more")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function mailmoretext.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("mailmoretext")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.text:setString(data and data.text or "")

end

function mailmoretext.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return mailmoretext