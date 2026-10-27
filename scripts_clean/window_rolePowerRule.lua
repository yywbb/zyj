--
-- Author: songyibo
-- Date: 2019-04-10 10:55:47
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

    self.rootItems.power:setString(GameScene.roleinfo.power)
    self.rootItems.g_power:setString(GameScene.roleinfo.g_power)
    self.rootItems.f_power:setString(GameScene.roleinfo.f_power)
    self.rootItems.g_power_basic:setString(GameScene.roleinfo.g_power_WithOutTransform)
    self.rootItems.f_power_basic:setString(GameScene.roleinfo.f_power_WithOutTransform)
    self.rootItems.g_power_trans:setString(math.floor(GameScene.roleinfo.g_power_WithOutTransform *  gamedata.config.global_kv.fairy_turn_every.value))
    self.rootItems.f_power_trans:setString(math.floor(GameScene.roleinfo.f_power_WithOutTransform * gamedata.config.global_kv.every_fairy_turn.value))
    return self.rootNode
end

function rule.initNode(self, touchPriority)
	self.rootNode, self.rootItems = CCBReaderLoad("MainScene/power_rule", nil, true, "power_rule")
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
		gameWindows:closeWindow("power_rule")
	end

	self:commonBtn(self.rootItems, "closeButton", _cb)
end

function rule.initFixedString(self)
    self.rootItems.infoTxt:setString(self.systemIntro["55"].intro)
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