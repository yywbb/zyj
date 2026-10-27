--
-- Author: songyibo
-- Date: 2019-03-21 14:44:34
--
local babelTowerBuy = {
    rootNode = nil,
    rootItems = nil,
    buynum = 0,
    buySpend = 0,
}

function babelTowerBuy.open(self,touchPriority,data,callback)
    self.touchPriority = touchPriority

    self.rootNode,self.rootItems = CCBReaderLoad("tongtianta/tc_goumaicishu", nil, true, "tc_goumaicishu")

    -- 添加输入数字功能 
    ui.creatInputEditBoxForNum(self.rootItems.inputNumNode,self.rootItems.buynum,touchPriority,function (num)
        self.buynum = 0
        self:numchange(num)
    end)

    self.buyTime = data.buyTime or 0
    self.challengeTime = data.challengeTime or 0
    self.moneynum = GameScene.roleinfo.g_gold or 0

    self.maxBuyTime = math.max(gamedata.config.vip[tostring(GameScene.vip.vip)].tongtianta_cishu - self.buyTime,0)

    self.rootItems.add1:addHandleOfControlEvent(function()
        self:numchange(1)
    end, CCControlEventTouchUpInside)
    self.rootItems.add1:setSwallowsTouch(true)
    self.rootItems.add1:setTouchPriority(self.touchPriority)

    self.rootItems.add10:addHandleOfControlEvent(function()
        self:numchange(10)
    end, CCControlEventTouchUpInside)
    self.rootItems.add10:setSwallowsTouch(true)
    self.rootItems.add10:setTouchPriority(self.touchPriority)

    self.rootItems.sub1:addHandleOfControlEvent(function()
        self:numchange(-1)
    end, CCControlEventTouchUpInside)
    self.rootItems.sub1:setSwallowsTouch(true)
    self.rootItems.sub1:setTouchPriority(self.touchPriority)

    self.rootItems.sub10:addHandleOfControlEvent(function()
        self:numchange(-10)
    end, CCControlEventTouchUpInside)
    self.rootItems.sub10:setSwallowsTouch(true)
    self.rootItems.sub10:setTouchPriority(self.touchPriority)


    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("babelTowerBuy")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.doButton1:addHandleOfControlEvent(function()
        gameWindows:closeWindow("babelTowerBuy")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton1:setSwallowsTouch(true)
    self.rootItems.doButton1:setTouchPriority(self.touchPriority)

    self.rootItems.doButton2:addHandleOfControlEvent(function()
        if self.buySpend > self.moneynum then
        	runGamePrompt({msg = gameConfig.strings:string_common("babelTower",2)})
        	return
        end
        if self.buynum > 0 then
            UIRequest({type = 7010,sysId = 450,times = self.buynum,spend = self.buySpend})
            gameWindows:closeWindow("babelTowerBuy")
        else
            runGamePrompt({msg = gameConfig.strings:string_common("babelTower",24)})
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.doButton2:setSwallowsTouch(true)
    self.rootItems.doButton2:setTouchPriority(self.touchPriority)

    self:reload(data)
    self:initFixedString()
    return self.rootNode
end

function babelTowerBuy.reload(self,data)
	self.data = data or {}

    local maxChallenge = gamedata.config.vip["0"].tongtianta_cishu + gamedata.config.vip[tostring(GameScene.vip.vip)].tongtianta_cishu
    local curCanChallenge = gamedata.config.vip["0"].tongtianta_cishu + self.buyTime - self.challengeTime
    self.rootItems.challenge:setString(curCanChallenge)
    if  curCanChallenge > 0 then
        self.rootItems.challenge:setColor(ccc3(106,228,108))
    else
        self.rootItems.challenge:setColor(ccc3(255,0,0))
    end

    -- ui.setLabelString(self.rootItems.challenge,self.challengeTime,26)
    -- ui.setLabelString(self.rootItems.buytime,self.maxBuyTime,26)

	self.rootItems.totalChallenge:setString("/"..maxChallenge)

    self.rootItems.buytime:setString(self.maxBuyTime)
	self.rootItems.money:setString(self.moneynum)

end

function babelTowerBuy.numchange(self,num)
    local canbuynum = self.maxBuyTime
    if self.buynum+num < 0 then
    	self.buynum = 0
    elseif self.buynum+num > canbuynum then
        self.buynum = canbuynum
    	runGamePrompt({msg = gameConfig.strings:string_common("popups","buy_time")})
    else
    	self.buynum = self.buynum + num
    end
	self:setbuydata()
end

function babelTowerBuy.setbuydata(self)
	self.rootItems.buynum:setString(self.buynum)

	local price = 0
	if self.buynum > 0 then
		for i=1,self.buynum do
			price = price + gamedata.config.buycount_price[tostring(self.buyTime + i)].tongtianta_goumai_jiage
		end
		self.rootItems.totalprice:setString(price)
	else
		self.rootItems.totalprice:setString("0")
	end

	self.buySpend = price
end

function babelTowerBuy.initFixedString(self)

	ui.setLabelString(self.rootItems.doLab1,gameConfig.strings:string_common("popups","quxiao"),19)
	ui.setLabelString(self.rootItems.doLab2,gameConfig.strings:string_common("popups","queding"),19)
end

function babelTowerBuy.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.buynum = 0
    self.buySpend = 0
    if self.callback then
        self.callback()
    end	
end
return babelTowerBuy