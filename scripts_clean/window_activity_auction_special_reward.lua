activityAuctionSpecialReward = {
	rootNode = nil,
	rootItems = nil,
    needcallback = true,
}

function activityAuctionSpecialReward.close(self)
    if self.callback then
    	self.callback()
    end

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function activityAuctionSpecialReward.open(self, touchPriority, data, callback)
	self:initNode(touchPriority, data, callback)
	self:initConfig()
	self:initEventBtn()
	self:initFixedString()
	self:initNpcSpine()

    return self.rootNode
end

function activityAuctionSpecialReward.initNode(self, touchPriority, data, callback)
	self.rootNode, self.rootItems = CCBReaderLoad("activitygudong/gudong_pop", nil, true, "gudong_pop")
	self.touchPriority = touchPriority
	self.npcId = data.npcId
	self.cid = data.cid
	self.price = data.price
	self.callback = callback
end

function activityAuctionSpecialReward.initConfig(self)
	self.antiqueNpc = gamedata.config.antique_npc
	self.generalAnimation = gamedata.config.generalanimation
end

function activityAuctionSpecialReward.initEventBtn(self)
	self:initDoBtn1()
	self:initDoBtn2()
end

function activityAuctionSpecialReward.initDoBtn1(self)
	local _cb = function()
		gameWindows:closeWindow("activityAuctionSpecialReward")
	end

	self:commonBtn(self.rootItems, "doButton1", _cb)
end

function activityAuctionSpecialReward.initDoBtn2(self)
	local _cb = function()
		gameWindows:closeWindow("activityAuctionSpecialReward")
	end

	self:commonBtn(self.rootItems, "doButton2", _cb)
end

function activityAuctionSpecialReward.initFixedString(self)
	local _desc = string.format(self.antiqueNpc[tostring(self.npcId)].extraTalk, tonumber(self.price))
	self.rootItems.desc:setString(_desc)
	ui.setLabelString(self.rootItems.doLab1, gameConfig.strings:string_common("activityAuction", 8),18)
	ui.setLabelString(self.rootItems.doLab2, gameConfig.strings:string_common("activityAuction", 9),18)
end

function activityAuctionSpecialReward.initNpcSpine(self)
	local _spineName = self.generalAnimation[tostring(self.antiqueNpc[tostring(self.npcId)].extraHead)].name
	self.npcSpine = CCSkeletonAnimation:create(_spineName.."/".._spineName..".json", _spineName.."/".._spineName..".atlas", 1)
	self.npcSpine:setAnimation("stand", true, 0)
	self.npcSpine:setScale(1.5)
    self.npcSpine:setPosition(0,0)
    self.rootItems.npcNode:addChild(self.npcSpine)
end

-- 通用按钮
function activityAuctionSpecialReward.commonBtn(self, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)
    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(toucnhPriority or (self.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return activityAuctionSpecialReward