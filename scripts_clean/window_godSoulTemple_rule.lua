godSoulTempleRule = {
    touchPriority = -101,

    ruleid = "62",
}

function godSoulTempleRule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.ruleid = nil

    if self.callback then
        self.callback()
    end
end

function godSoulTempleRule.open(self, touchPriority, data, callback)
    self.ruleid =  data.ruleid

	self:initNode(touchPriority)
	self:initConfig()
	self:initEventBtn()
    self:initFixedString()


    return self.rootNode
end

function godSoulTempleRule.initNode(self, touchPriority)
	self.rootNode, self.rootItems = CCBReaderLoad("shenhundian/shenhundian_rule.ccbi", nil, true, "shenhundian_rule.ccbi")
	self.touchPriority = touchPriority

    if self.ruleid == "63" then
        self.rootItems.ruleName:setString(gameConfig.strings:string_common("godSoulTemple", "refineSoule", 12))
    elseif self.ruleid == "64" then
        self.rootItems.ruleName:setString(gameConfig.strings:string_common("godSoulTemple", "refineSoule", 13))
    end    

end

function godSoulTempleRule.initConfig(self)
    self.systemIntro = gamedata.config.system_intro
end

function godSoulTempleRule.initEventBtn(self)
	self:initCloseBtn()
end

function godSoulTempleRule.initCloseBtn(self)
	local _cb = function()
		gameWindows:closeWindow("godSoulTempleRule")
	end

	self:commonBtn(self.rootItems, "closeButton", _cb)
end

function godSoulTempleRule.initFixedString(self)
    if self.ruleid ~=nil then
        self.rootItems.infoTxt:setString(self.systemIntro[self.ruleid].intro)
    end    
end

-- 通用按钮
function godSoulTempleRule.commonBtn(self, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)
    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(touchPriority or (self.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return godSoulTempleRule