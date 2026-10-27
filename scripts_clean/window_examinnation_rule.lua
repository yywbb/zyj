examinationRule = {
    touchPriority = -101,
}

function examinationRule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

function examinationRule.open(self, touchPriority, data, callback)
	self:initNode(touchPriority)
	self:initConfig()
	self:initEventBtn()
    self:initFixedString()

    return self.rootNode
end

function examinationRule.initNode(self, touchPriority)
	self.rootNode, self.rootItems = CCBReaderLoad("sanjieliankao/sanjieliankao_rule", nil, true, "sanjieliankao_rule")
	self.touchPriority = touchPriority
end

function examinationRule.initConfig(self)
    self.systemIntro = gamedata.config.system_intro
end

function examinationRule.initEventBtn(self)
	self:initCloseBtn()
end

function examinationRule.initCloseBtn(self)
	local _cb = function()
		gameWindows:closeWindow("examinationRule")
	end

	self:commonBtn(self.rootItems, "closeButton", _cb)
end

function examinationRule.initFixedString(self)
    self.rootItems.infoTxt:setString(self.systemIntro["65"].intro)
end

-- 通用按钮
function examinationRule.commonBtn(self, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)
    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(touchPriority or (self.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return examinationRule