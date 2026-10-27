--
-- Author: songyibo
-- Date: 2021-07-20 13:58:56
--

local ageTips = {
	rootNode = nil,
	rootItems = nil,
}

function ageTips.open(self,touchPriority,data,callback)
	self.rootNode, self.rootItems = CCBReaderLoad("Login/egame_age_tips",nil,true,"egame_age_tips")
	self.touchPriority = touchPriority

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindowslogin:closeWindowDirect("ageTips")
    end,CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)


	return self.rootNode
end

function ageTips.close(self)

	self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
    	self.callback()
    end
end

return ageTips