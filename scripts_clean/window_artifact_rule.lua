artifactRule = {
    touchPriority = -101,
}

function artifactRule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

function artifactRule.open(self, touchPriority, data, callback)
	self:initNode(touchPriority)
	self:initConfig()
	self:initEventBtn()
    self:initFixedString()

    return self.rootNode
end

function artifactRule.initNode(self, touchPriority)
	self.rootNode, self.rootItems = CCBReaderLoad("shenqi_new/shenqi_rule", nil, true, "shenqi_rule")
	self.touchPriority = touchPriority
end

function artifactRule.initConfig(self)
    self.systemIntro = gamedata.config.system_intro
end

function artifactRule.initEventBtn(self)
	self:initCloseBtn()
end

function artifactRule.initCloseBtn(self)
	local _cb = function()
		gameWindows:closeWindow("artifactRule")
	end

	self:commonBtn(self.rootItems, "closeButton", _cb)
end

function artifactRule.initFixedString(self)
    self.rootItems.infoTxt:setString(self.systemIntro["31"].intro)
end

-- 通用按钮
function artifactRule.commonBtn(self, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)
    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(touchPriority or (self.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return artifactRule