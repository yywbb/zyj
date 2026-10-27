
local championSetting = {
    rootNode = nil,
    rootItems = nil,
    buynum = 1,
    path = 1,
    buySpend = 0,
}

function championSetting.open(self,touchPriority,data,callback)
    self.touchPriority = touchPriority

    self.rootNode,self.rootItems = CCBReaderLoad("chamipon/tc_queren", nil, true, "tc_queren")

    -- 添加输入数字功能 
    ui.creatInputEditBoxForNum(self.rootItems.inputNumNode,self.rootItems.buynum,self.touchPriority,function (num)
        self.buynum = 0
        self:numchange(num)
    end)

    self.moneynum = GameScene.roleinfo.gold or 0

    self.maxBuyTime = 5

    self.rootItems.add1:addHandleOfControlEvent(function()
        self:numchange(1)
    end, CCControlEventTouchUpInside)
    self.rootItems.add1:setSwallowsTouch(true)
    self.rootItems.add1:setTouchPriority(self.touchPriority)

    self.rootItems.add2:addHandleOfControlEvent(function()
        self:numchange(10)
    end, CCControlEventTouchUpInside)
    self.rootItems.add2:setSwallowsTouch(true)
    self.rootItems.add2:setTouchPriority(self.touchPriority)

    self.rootItems.sub1:addHandleOfControlEvent(function()
        self:numchange(-1)
    end, CCControlEventTouchUpInside)
    self.rootItems.sub1:setSwallowsTouch(true)
    self.rootItems.sub1:setTouchPriority(self.touchPriority)

    self.rootItems.sub2:addHandleOfControlEvent(function()
        self:numchange(-10)
    end, CCControlEventTouchUpInside)
    self.rootItems.sub2:setSwallowsTouch(true)
    self.rootItems.sub2:setTouchPriority(self.touchPriority)


    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("championSetting")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.quxiaoText,"取 消",19)
    ui.setLabelString(self.rootItems.querenText,"确 认",19)

    self.rootItems.quxiaoBtn:addHandleOfControlEvent(function()
        gameWindows:closeWindow("championSetting")
    end, CCControlEventTouchUpInside)
    self.rootItems.quxiaoBtn:setSwallowsTouch(true)
    self.rootItems.quxiaoBtn:setTouchPriority(self.touchPriority)

    self.rootItems.querenBtn:addHandleOfControlEvent(function()
        if self.buynum > 0 then
            if data == nil then
                CCUserDefault:sharedUserDefault():setIntegerForKey("ChampionPath"..GameScene.roleinfo.id, self.path)
                CCUserDefault:sharedUserDefault():setIntegerForKey("ChampionTimes"..GameScene.roleinfo.id, self.buynum)
            else
                if GameScene.roleinfo.level < tonumber(gamedata.config.global_kv.champion_level.value) and GameScene.roleinfo.vip < tonumber(gamedata.config.global_kv.champion_vip.value) then
                    local msg = string.format(gameConfig.strings:string_common("champion","minLevel"), gamedata.config.global_kv.champion_vip.value, gamedata.config.global_kv.champion_level.value)
                    runGamePrompt({msg = msg})
                    return
                end
                if self.buySpend > self.moneynum then
                    runGamePrompt({msg = gameConfig.strings:string_common("popups","goldbz")})
                    return
                end
                CCUserDefault:sharedUserDefault():setIntegerForKey("ChampionPath"..GameScene.roleinfo.id, self.path)
                CCUserDefault:sharedUserDefault():setIntegerForKey("ChampionTimes"..GameScene.roleinfo.id, self.buynum)
                UIRequest({type = 2705, path = self.path, times = self.buynum, res = string.format("冠军试炼开%d宝箱", self.buynum), price = self.buySpend})
            end
            gameWindows:closeWindow("championSetting")
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.querenBtn:setSwallowsTouch(true)
    self.rootItems.querenBtn:setTouchPriority(self.touchPriority)

    self.rootItems.autobutton1:addHandleOfControlEvent(function()
        self:shiftSelect(1)
    end, CCControlEventTouchUpInside)
    self.rootItems.autobutton1:setSwallowsTouch(true)
    self.rootItems.autobutton1:setTouchPriority(self.touchPriority)

    self.rootItems.autobutton2:addHandleOfControlEvent(function()
        self:shiftSelect(2)
    end, CCControlEventTouchUpInside)
    self.rootItems.autobutton2:setSwallowsTouch(true)
    self.rootItems.autobutton2:setTouchPriority(self.touchPriority)

    self.rootItems.autobutton3:addHandleOfControlEvent(function()
        self:shiftSelect(3)
    end, CCControlEventTouchUpInside)
    self.rootItems.autobutton3:setSwallowsTouch(true)
    self.rootItems.autobutton3:setTouchPriority(self.touchPriority)

    self:reload(data)
    return self.rootNode
end

function championSetting.shiftSelect(self, path)
    self.path = path and path or self.path
    self.rootItems.autosprite1:setVisible(false)
    self.rootItems.autosprite2:setVisible(false)
    self.rootItems.autosprite3:setVisible(false)
    self.rootItems["autosprite"..self.path]:setVisible(true)
end

function championSetting.reload(self,data)
    self.data = data or {}
    local path = CCUserDefault:sharedUserDefault():getIntegerForKey("ChampionPath"..GameScene.roleinfo.id)
    local times = CCUserDefault:sharedUserDefault():getIntegerForKey("ChampionTimes"..GameScene.roleinfo.id)
    if path and path ~= 0 then
        self.path = path
        self.buynum = times
    else
        self.path = 1
        self.buynum = 1
    end
    print("championSetting.reload(self,data)----", self.buynum)
    self:shiftSelect()
    self:setbuydata()
end

function championSetting.numchange(self,num)
    local canbuynum = self.maxBuyTime
    if self.buynum+num < 1 then
        self.buynum = 1
        runGamePrompt({msg = gameConfig.strings:string_common("popups","openTimeMin")})
    elseif self.buynum+num > canbuynum then
        self.buynum = canbuynum
    	runGamePrompt({msg = gameConfig.strings:string_common("popups","openTimeMax")})
    else
    	self.buynum = self.buynum + num
    end
	self:setbuydata()
end

function championSetting.setbuydata(self)
	self.rootItems.buynum:setString(self.buynum)

	local price = 0
	for i=1,self.buynum do
        price = price + gamedata.config.buycount_price[tostring(i)].championbox_cost
    end
    self.rootItems.kaiqijiagenum:setString(tostring(price))

	self.buySpend = price
end

function championSetting.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.buynum = 1
    self.buySpend = 0
    if self.callback then
        self.callback()
    end	
end
return championSetting