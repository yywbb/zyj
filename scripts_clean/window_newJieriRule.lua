--
-- Author: songyibo
-- Date: 2018-09-28 17:16:34
--

local newJieriRule = {
    rootNode = nil,
    rootItems = nil,

}

function newJieriRule.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("activityjieri/jieri_rule", nil, true, "jieri_rule")
    self.touchPriority = touchPriority

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("newJieriRule")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)


    self:initFixedString(data.systemid)
    return self.rootNode
end

function newJieriRule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

function newJieriRule.initFixedString(self,systemid)

	for k,v in pairs(gamedata.config.system_intro) do
		if v.build_id == systemid then
			self.rootItems.infoTxt:setString(v.intro)
            self.rootItems.ruleTitle:setString(v.title)
			break
		end
	end

end

return newJieriRule