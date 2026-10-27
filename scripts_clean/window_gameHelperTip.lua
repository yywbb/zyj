--
-- Author: songyibo
-- Date: 2020-02-11 17:08:23
--

local confirm = {
    rootNode = nil,
    rootItems = nil,
}

function confirm.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("youxizhushou/tc_tips", nil, true, "tc_tip")

    self.touchPriority = touchPriority
    self.callback = callback

    ui.setLabelString(self.rootItems.conceltext,gameConfig.strings:string_common("popups","quxiao"),18)
    ui.setLabelString(self.rootItems.confirmtext,gameConfig.strings:string_common("popups","queding"),18)

    self.rootItems.copyNode:setVisible(false)
	self.rootItems.confirmNode:setVisible(false)

	printT(data,"confirm")
    --副本确认跳转
    self:reloadCopy(data)

    return self.rootNode
end

function confirm.reloadCopy(self,data)
	self.rootItems.copyNode:setVisible(true)

	local str = "已开启 "
	for i,v in ipairs(data.data) do
		str = str..v.name..","
	end
	str = str.."是否手动挑战新开启副本?"

    ui.setLabelString(self.rootItems.copyMsg,str)

    
    self.rootItems.concel:addHandleOfControlEvent(function()
        self.callback()
        gameWindows:closeWindow("gameHelperTip")
    end, CCControlEventTouchUpInside)
    self.rootItems.concel:setSwallowsTouch(true)
    self.rootItems.concel:setTouchPriority(self.touchPriority)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback()
        gameWindows:closeWindow("gameHelperTip")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    
    self.rootItems.confirm:addHandleOfControlEvent(function()
        GameScene:shiftLayer("copy_chapter","up",{datatype = "activity"})
    end, CCControlEventTouchUpInside)
    self.rootItems.confirm:setSwallowsTouch(true)
    self.rootItems.confirm:setTouchPriority(self.touchPriority)

end

function confirm.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    -- if self.callback then
    --     self.callback()
    --     self.callback = nil
    -- end
end

return confirm

