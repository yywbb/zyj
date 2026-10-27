--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/25
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--

local devilconfirm = {
    rootNode = nil,
    rootItems = nil,
}

function devilconfirm.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("devil2/tc_mowangjinjie", nil, true, "up")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function devilconfirm.reload(self,data,callback)
    self.callback = callback


    ui.setLabelString(self.rootItems.noLab,nil,18)
    self.rootItems.noButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("devilconfirm")
    end, CCControlEventTouchUpInside)
    self.rootItems.noButton:setSwallowsTouch(true)
    self.rootItems.noButton:setTouchPriority(self.touchPriority)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("devilconfirm")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.yesLab,nil,18)
    self.rootItems.yesButton:addHandleOfControlEvent(function()
        UIRequest({type = 1052})
        gameWindows:closeWindowDirect("devilconfirm")
    end, CCControlEventTouchUpInside)
    self.rootItems.yesButton:setSwallowsTouch(true)
    self.rootItems.yesButton:setTouchPriority(self.touchPriority)
end

function devilconfirm.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return devilconfirm

