auctionRule = {
    touchPriority = -101,
}

function auctionRule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

function auctionRule.open(self, touchPriority, data, callback)
	self:initNode(touchPriority)
	self:initConfig()
	self:initEventBtn()
    self:initFixedString()

    return self.rootNode
end

function auctionRule.initNode(self, touchPriority)
	self.rootNode, self.rootItems = CCBReaderLoad("activitygudong/gudong_rule", nil, true, "gudong_rule")
	self.touchPriority = touchPriority
end

function auctionRule.initConfig(self)
    self.systemIntro = gamedata.config.system_intro
end

function auctionRule.initEventBtn(self)
	self:initCloseBtn()
end

function auctionRule.initCloseBtn(self)
	local _cb = function()
		gameWindows:closeWindow("activityAuctionRule")
	end

	self:commonBtn(self.rootItems, "closeButton", _cb)
end

function auctionRule.initFixedString(self)
    self.rootItems.infoTxt:setString(self.systemIntro["30"].intro)
end

-- 通用按钮
function auctionRule.commonBtn(self, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)
    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(touchPriority or (self.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return auctionRule