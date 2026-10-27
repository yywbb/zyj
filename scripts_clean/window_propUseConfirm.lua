--
-- Author: songyibo
-- Date: 2018-10-10 10:55:46
--


local confirm = {
    rootNode = nil,
    rootItems = nil,
}

function confirm.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("windows/confirm", nil, true, "confirm")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function confirm.reload(self,data,callback)

    if data.rich then
        self.rootItems.des:setString("")
        ui.createRichLabel(data.rich,self.rootItems["richNode"],false)
    else
        ui.setLabelString(self.rootItems.des,data.msg,data.fontId or 47)
    end
    
    if data.noShowCancel then
        self.rootItems.confirmNode:setPositionX(0)
        self.rootItems.concelNode:setVisible(false)
    end
    -- ui.setLabelString(self.rootItems.conceltext,"返 回",18)
    ui.setLabelString(self.rootItems.conceltext,gameConfig.strings:string_common("popups","fanhui"),18)
    self.rootItems.concel:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("confirm")
    end, CCControlEventTouchUpInside)
    self.rootItems.concel:setSwallowsTouch(true)
    self.rootItems.concel:setTouchPriority(self.touchPriority)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("confirm")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.confirmtext,"确 定",18)
    ui.setLabelString(self.rootItems.confirmtext,gameConfig.strings:string_common("popups","queding"),18)
    self.rootItems.confirm:addHandleOfControlEvent(function()
        self.callback = callback
        gameWindows:closeWindowDirect("confirm")
    end, CCControlEventTouchUpInside)
    self.rootItems.confirm:setSwallowsTouch(true)
    self.rootItems.confirm:setTouchPriority(self.touchPriority)
end

function confirm.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
        self.callback = nil
    end
end

return confirm

