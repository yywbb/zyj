--
-- Author: songyibo
-- Date: 2019-09-24 09:35:10
--

local rule = {
    touchPriority = -101,
}

function rule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

function rule.open(self, touchPriority, data, callback)
	self:initNode(touchPriority)
	self:initConfig()
	self:initEventBtn()
    self:initFixedString()

    return self.rootNode
end

function rule.initNode(self, touchPriority)
	self.rootNode, self.rootItems = CCBReaderLoad("shangguyiji/rule", nil, true, "rule")
	self.touchPriority = touchPriority
end

function rule.initConfig(self)
    self.systemIntro = gamedata.config.system_intro
end

function rule.initEventBtn(self)
	self:initCloseBtn()
end

function rule.initCloseBtn(self)
	local _cb = function()
		gameWindows:closeWindow("ancientRuinsRule")
	end

	self:commonBtn(self.rootItems, "closeButton", _cb)
end

function rule.initFixedString(self)
    self.rootItems.infoTxt:setString(self.systemIntro["68"].intro)
end

-- 通用按钮
function rule.commonBtn(self, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)
    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(touchPriority or (self.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return rule