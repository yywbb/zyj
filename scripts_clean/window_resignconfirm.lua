--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/8
-- Time: 下午2:33
-- To change this template use File | Settings | File Templates.
--

local resignconfirm = {
    rootNode = nil,
    rootItems = nil,
}

function resignconfirm.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("activitysignin/resign", nil, true, "resign")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function resignconfirm.reload(self,data,callback)
    self.callback = callback

    ui.setNewIconName(self.rootItems,data.icondata)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("resignconfirm")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.doLab1,"取 消",18)
    ui.setLabelString(self.rootItems.doLab1,gameConfig.strings:string_common("popups","quxiao"),18)
    self.rootItems.doButton1:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("resignconfirm")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton1:setSwallowsTouch(true)
    self.rootItems.doButton1:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.doLab2,"确 定",18)
    ui.setLabelString(self.rootItems.doLab2,gameConfig.strings:string_common("popups","queding"),18)
    self.rootItems.doButton2:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("resignconfirm")
        UIRequest({type = 2061, day = data.day})
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton2:setSwallowsTouch(true)
    self.rootItems.doButton2:setTouchPriority(self.touchPriority)

end

function resignconfirm.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return resignconfirm