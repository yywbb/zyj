--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/25
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--

local adCueboard = {
    rootNode = nil,
    rootItems = nil,
}

function adCueboard.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("windows/confirm", nil, true, "confirm")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function adCueboard.reload(self,data,callback)

    ui.setLabelString(self.rootItems.des,data.msg,data.fontId or 47)
    
    -- ui.setLabelString(self.rootItems.conceltext,"返 回",18)
    ui.setLabelString(self.rootItems.conceltext,gameConfig.strings:string_common("fixedString","adCueboard",2),18)
    self.rootItems.concel:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("adCueboard")
    end, CCControlEventTouchUpInside)
    self.rootItems.concel:setSwallowsTouch(true)
    self.rootItems.concel:setTouchPriority(self.touchPriority)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("adCueboard")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.confirmtext,"看广告",18)
    ui.setLabelString(self.rootItems.confirmtext,gameConfig.strings:string_common("fixedString","adCueboard",1),18)
    self.rootItems.confirm:addHandleOfControlEvent(function()
        self.callback = callback
        gameWindows:closeWindowDirect("adCueboard")
    end, CCControlEventTouchUpInside)
    self.rootItems.confirm:setSwallowsTouch(true)
    self.rootItems.confirm:setTouchPriority(self.touchPriority)
end

function adCueboard.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
        self.callback = nil
    end
end

return adCueboard

