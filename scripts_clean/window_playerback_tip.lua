--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 16/2/14
-- Time: 下午4:50
-- To change this template use File | Settings | File Templates.
--

local playerback_tip = {
    rootNode = nil,
    rootItems = nil,
    needcallback = true,
    data= {},
}

function playerback_tip.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("mowangzailin/mowangzailin_post", nil, true, "mowangzailin_post")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function playerback_tip.reload(self,data,callback)
    self.callback = callback

    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("playerback_tip")
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.doLab,"前往查看",19)
    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:setTouchPriority(self.touchPriority)
    self.rootItems.doButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("playerback_tip")
        --
        gameWindows:openWindow("playerback",nil,nil)
    end, CCControlEventTouchUpInside)
end

function playerback_tip.close(self)

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
        self.callback = nil
    end
end

return playerback_tip