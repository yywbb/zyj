--
-- Author: songyibo
-- Date: 2018-09-28 17:16:34
--

local rule = {
    rootNode = nil,
    rootItems = nil,

}

function rule.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("chongbang/chongbang_rule", nil, true, "chongbang_rule")
    self.touchPriority = touchPriority

    printT(data,"newRankRule")

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("newRankRule")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)


    self:initFixedString(data.systemid)
    return self.rootNode
end

function rule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

function rule.initFixedString(self,systemid)

	for k,v in pairs(gamedata.config.system_intro) do
		if v.build_id == systemid then
			self.rootItems.infoTxt:setString(v.intro)
            self.rootItems.ruleTitle:setString(v.title)
			break
		end
	end

end

return rule