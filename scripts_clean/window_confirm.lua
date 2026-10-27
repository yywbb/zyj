--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/25
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
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
        ui.createRichLabel(data.rich,self.rootItems["richNode"],false,{horizontal = "center",vertical = "center"})
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
        if data.oldQuality then
            self.callback = callback(data.oldQuality)
        else
            self.callback = nil
        end
        gameWindows:closeWindow("confirm")
    end, CCControlEventTouchUpInside)
    self.rootItems.concel:setSwallowsTouch(true)
    self.rootItems.concel:setTouchPriority(self.touchPriority)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        if data.oldQuality then
            self.callback = callback(data.oldQuality)
        else
            self.callback = nil
        end
        gameWindows:closeWindow("confirm")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.confirmtext,"确 定",18)
    ui.setLabelString(self.rootItems.confirmtext,gameConfig.strings:string_common("popups","queding"),18)
    self.rootItems.confirm:addHandleOfControlEvent(function()
        if data.newQuality then
            self.callback = callback(data.newQuality)
        else
            self.callback = callback
        end
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