--
-- Author: songyibo
-- Date: 2019-03-25 19:48:36
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
	self.rootNode, self.rootItems = CCBReaderLoad("tongtianta/rule", nil, true, "rule")
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
		gameWindows:closeWindow("babelTowerRule")
	end

	self:commonBtn(self.rootItems, "closeButton", _cb)
end

function rule.initFixedString(self)
    self.rootItems.infoTxt:setString(self.systemIntro["53"].intro)
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