--
-- Author: songyibo
-- Date: 2020-09-10 15:14:24
--

local confirm = {
    rootNode = nil,
    rootItems = nil,
}

function confirm.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("general_new/tc_skillselect_illusionConfirm", nil, true, "confirm")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function confirm.reload(self,data,callback)

	self.data = data
    self.callback = callback
	local generalConfig = gamedata.config.general[tostring(self.data.cid)]
	local generalIllusionConfig = gamedata.config.general[tostring(self.data.illusionGeneralCid)]


	self.rootItems.label1:setString(string.format(gameConfig.strings:string_common("huanhua",13), generalConfig.name,generalIllusionConfig.name))
	self.rootItems.label3:setString(string.format(gameConfig.strings:string_common("huanhua",14),generalIllusionConfig.name))

    ui.setLabelString(self.rootItems.optionsLab1,generalConfig.name,18)
    ui.setLabelString(self.rootItems.optionsLab2,generalIllusionConfig.name,18)


    self.selectIllusion = false
    self.rootItems.optionsBtn1:addHandleOfControlEvent(function()
        gameWindows:closeWindow("changeSkillIllusion")
    end, CCControlEventTouchUpInside)
    self.rootItems.optionsBtn1:setSwallowsTouch(true)
    self.rootItems.optionsBtn1:setTouchPriority(self.touchPriority)

    self.rootItems.optionsBtn2:addHandleOfControlEvent(function()
    	self.selectIllusion = true
        gameWindows:closeWindow("changeSkillIllusion")
    end, CCControlEventTouchUpInside)
    self.rootItems.optionsBtn2:setSwallowsTouch(true)
    self.rootItems.optionsBtn2:setTouchPriority(self.touchPriority)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("changeSkillIllusion")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

end

function confirm.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback(self.selectIllusion)
        self.callback = nil
    end
end

return confirm

