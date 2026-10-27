--
-- Author: songyibo
-- Date: 2019-04-11 14:14:28
--

local confirm = {
    rootNode = nil,
    rootItems = nil,
}

function confirm.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("general_new/goldbreak_confirm", nil, true, "goldbreak_confirm")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function confirm.reload(self,data,callback)
	local scopetype = {
        [1] = "tian",
        [2] = "di",
        [3] = "ren",
    }

    setSpriteFrameByName(self.rootItems.goldtype,"tujin_"..scopetype[data])

    ui.setLabelString(self.rootItems.conceltext,gameConfig.strings:string_common("popups","fanhui"),18)
    self.rootItems.concel:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("goldBreakConfirm")
    end, CCControlEventTouchUpInside)
    self.rootItems.concel:setSwallowsTouch(true)
    self.rootItems.concel:setTouchPriority(self.touchPriority)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("goldBreakConfirm")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.confirmtext,gameConfig.strings:string_common("popups","queding"),18)
    self.rootItems.confirm:addHandleOfControlEvent(function()
        self.callback = callback
        gameWindows:closeWindowDirect("goldBreakConfirm")
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