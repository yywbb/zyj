--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 2016-01-19 15:35:45
-- Time: 下午3:54
-- To change this temisLandate use File | Settings | File TemisLandates.
--

local isLand = {
	rootNode = nil,
	rootItems = nil,

	cardData = {},
	flopPrice = {},
    olddata = nil,
}

function isLand.open(self, touchPriority, data, callback)

	local _type = data.page
	self.touchPriority = touchPriority
	if _type == "xuanze" then
		self.rootNode, self.rootItems = CCBReaderLoad("island3/island3_xuanze", nil, true, "xuanze")
		self:onSelectDice()
        self.rootItems.closeButton:setTouchEnabled(true)
	elseif _type == "fanpaizi" then
		self.cardData = data.card or {}
		self.flopPrice = {
			tonumber(gamedata.config.global_kv.penglai3_card_freetimes.value),
            tonumber(gamedata.config.global_kv.penglai3_card_paytimes.value),
            tonumber(gamedata.config.global_kv.penglai3_card_paytimes2.value),
            tonumber(gamedata.config.global_kv.penglai3_card_paytimes3.value),
            tonumber(gamedata.config.global_kv.penglai3_card_akey.value),
		}
		self.rootNode, self.rootItems = CCBReaderLoad("island3/island3_fanpaizi", nil, true, "fanpaizi")
		local brandPos = {
			{pos = ccp(-290, 140)}, {pos = ccp(0, 140)}, {pos = ccp(280, 140)}, {pos = ccp(-150, -190)}, {pos = ccp(150, -190)}
		}
		self.brand = {}

	    ui.addGray("CCControlButton", self.rootItems.definiteBtn)
	    self.rootItems.definiteBtn:setTouchEnabled(false)
        ui.setLabelString(self.rootItems.definiteLab, "确定", 19)
		self.rootItems.definiteBtn:addHandleOfControlEvent(function() -- 确定
            if _type == "fanpaizi" and callback ~= nil then
                callback()
            end
			self.callback = nil
            gameWindows:closeWindowDirect("isLand")
            UIRequest({type = 2126,})
		end, CCControlEventTouchUpInside)

		self.rootItems.definiteBtn:setSwallowsTouch(true)
		self.rootItems.definiteBtn:setTouchPriority(self.touchPriority)

        ui.setLabelString(self.rootItems.definiteLab,nil,19)
        ui.setLabelString(self.rootItems.allTurnLab,nil,19)

        self.rootItems.closeButton:setTouchEnabled(false)
		self.rootItems.allTurnBtn:setTouchEnabled(false)
        ui.setLabelString(self.rootItems.allTurnLab, "一键全翻", 19)
		self.rootItems.allTurnBtn:addHandleOfControlEvent(function() -- 一键全翻
            local opennum = 0
            for k,v in pairs(self.cardData.cards) do
                if v.status > 0 then
                    opennum = opennum+1
                end
            end
            if opennum < 5 then
                gameTouch:clickprofbytime(1)
                UIRequest({type = 2125,opt = 1,id = 1, gold = self.flopPrice[5],})
            end
		end, CCControlEventTouchUpInside)

		self.rootItems.allTurnBtn:setSwallowsTouch(true)
		self.rootItems.allTurnBtn:setTouchPriority(self.touchPriority)	

		ui.setLabelString(self.rootItems.costNum, "花费" .. self.flopPrice[5] , 14) -- 一键全翻的价格

        -- 双倍活动判断
        self:doubleRewardSet()

        local cardconfig = gamedata.config.penglai3_card or {}
		for i=1,5 do
			self.rootItems["brand" .. i]:setPosition(brandPos[i].pos)
			local rootNode, rootItems = CCBReaderLoad("island3/cell_island_fanpaizi", nil, true, "paizi")
			rootNode:setPosition(0,0)
			self.rootItems["brand" .. i]:addChild(rootNode)
			self.brand[i] = rootItems

            local cardstr = cardconfig[tostring(self.cardData.cards[tostring(i)].id)] and cardconfig[tostring(self.cardData.cards[tostring(i)].id)].param or ""
            local card = ui.penglaiCidNum(cardstr,gamedata.config.build["22"].level)
            -- -- 双倍活动
            local datatmp = ui.CheckHuodongByParam(5)
            local timesnum = ui.GetHuodongModulus(5)
            -- local datatmp = ui.CheckHuodongByParam(1)
            -- local timesnum = ui.GetHuodongModulus(1)
            if datatmp then
                card.num = card.num * tonumber(timesnum)
            end

			ui.setNewIcon(rootItems, card)

			ui.setLabelString(rootItems.prizeName, ui.IDconfig(card.cid).name or "", ((ui.IDconfig(card.cid).quality and ui.IDconfig(card.cid).quality ~= 0) and ui.IDconfig(card.cid).quality or 1)*2-1)
		end
        self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1),CCCallFunc:create(function()
            self:onTurnAll()
        end)))		

	else
		-- 退出弹窗
		return
	end
	self.callback = callback
	-- 退出
	self.rootItems.closeButton:addHandleOfControlEvent(function()
        if _type == "fanpaizi" and callback ~= nil then
            callback()
        end
        self.callback = nil
        gameWindows:closeWindowDirect("isLand")
        if _type == "fanpaizi" then
            UIRequest({type = 2126,})
        end
	end, CCControlEventTouchUpInside)

	self.rootItems.closeButton:setSwallowsTouch(true)
	self.rootItems.closeButton:setTouchPriority(self.touchPriority)


	return self.rootNode
end

-- 双倍活动2016年7月活动
function isLand.doubleRewardSet(self)
    if not self.rootItems.isrewarddouble then return end
    local datatmp = ui.CheckHuodongByParam(5)
    -- local datatmp = ui.CheckHuodongByParam(1)

    if datatmp then
        self.rootItems.isrewarddouble:setVisible(true)
        ui.setLabelString(self.rootItems.isrewarddouble,gameConfig.strings:string_common("doublereward",1),24)
    else
        self.rootItems.isrewarddouble:setVisible(false)
    end
end

function isLand.onTurnAll(self) -- 翻牌
	for k,v in pairs(self.brand) do
	 	self:onTouchBrand(k, "fanpai_zheng-fan")

	    v.touchBtn:addHandleOfControlEvent(function()
            if self.cardData.cards[tostring(k)] and self.cardData.cards[tostring(k)].status == 0 then
                gameTouch:clickprofbytime(1)
                local opennum = 0
                for k1,v1 in pairs(self.cardData.cards) do
                    if v1.status > 0 then
                        opennum = opennum+1
                    end
                end
                if opennum >= self.flopPrice[1] then
                    UIRequest({type = 2125,opt = 0,id = tonumber(k),gold = self.flopPrice[opennum-self.flopPrice[1]+2]})
                else
                    UIRequest({type = 2125,opt = 0,id = tonumber(k),gold = 0})
                end
            end
		end, CCControlEventTouchUpInside)

		v.touchBtn:setSwallowsTouch(true)
		v.touchBtn:setTouchPriority(self.touchPriority)
		v.touchBtn:setTouchEnabled(false)
	end

	-- 显示
    self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1),CCCallFunc:create(function()
		local animationManager = getAnimationManager(self.rootItems)
        animationManager:setAnimationCompletedCallback(function()
            self:onTurn()
        end)
	    animationManager:runAnimationsForSequenceNamed("allTurnAnimation")
    end)))		

end

function isLand.onOffTouch(self)
	for k,v in pairs(self.brand) do
		v.touchBtn:setTouchEnabled(true)
    end

    local opennum = 0
    for k,v in pairs(self.cardData.cards) do
        if v.status > 0 then
            opennum = opennum+1
        end
    end
    if opennum >= 5 then
        self.rootItems.allTurnBtn:setTouchEnabled(false)
        ui.addGray("CCControlButton", self.rootItems.allTurnBtn)
    else
        self.rootItems.allTurnBtn:setTouchEnabled(true)
        ui.removeGray("CCControlButton", self.rootItems.allTurnBtn)
    end

    if opennum >= 2 then
        self.rootItems.closeButton:setTouchEnabled(true)
        self.rootItems.definiteBtn:setTouchEnabled(true)
        ui.removeGray("CCControlButton", self.rootItems.definiteBtn)
    else
        self.rootItems.closeButton:setTouchEnabled(false)
        self.rootItems.definiteBtn:setTouchEnabled(false)
        ui.addGray("CCControlButton", self.rootItems.definiteBtn)
    end

end

function isLand.onTouchBrand(self, num, _type)
	local animationManager = getAnimationManager(self.brand[tonumber(num)])
	animationManager:runAnimationsForSequenceNamed(_type)

end

function isLand.onUpdate(self) -- 更新翻牌金币显示

    local opennum = 0
    for k,v in pairs(self.cardData.cards) do
        if v.status > 0 then
            opennum = opennum+1
        end
    end

    if opennum >= self.flopPrice[1] then
        ui.setLabelString(self.rootItems.freeFlopNum, "", 21)
    else
	    ui.setLabelString(self.rootItems.freeFlopNum, "免费翻牌" .. self.flopPrice[1]-opennum .. "次" , 21)
    end

	for k,v in pairs(self.brand) do
        if self.cardData.cards[tostring(k)] and self.cardData.cards[tostring(k)].status == 0 then
            if opennum >= self.flopPrice[1] then
                v.goldNum:setVisible(true)
                v.goldItem:setVisible(true)
                ui.setLabelString(v.goldNum, self.flopPrice[opennum-self.flopPrice[1]+2], 14)
            else
                v.goldNum:setVisible(false)
                v.goldItem:setVisible(false)
            end
        else
            v.goldNum:setVisible(false)
            v.goldItem:setVisible(false)
        end
	end
end

function isLand.onSelectDice(self)
	for i=1,6 do
        self.rootItems["diceBtn" .. i]:addHandleOfControlEvent(function()
			if self.callback then
				self.callback(i)
				gameWindows:closeWindow("isLand")
			end
		end, CCControlEventTouchUpInside)
        self.rootItems["diceBtn" .. i]:setSwallowsTouch(true)
        self.rootItems["diceBtn" .. i]:setTouchPriority(self.touchPriority)
	end
end

function isLand.close(self, _type) -- 退出获得页面 || 遥控骰子页面
	self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
	self.rootNode = nil
	self.rootItems = nil
    self.olddata = nil
	self.cardData = {}
	self.flopPrice = {}
end

function isLand.reload(self,data)
    self.olddata = table.copy(self.cardData)
    self.cardData = data.card or {}

    local cardconfig = gamedata.config.penglai3_card or {}
    for i=1,5 do
        local cardstr = cardconfig[tostring(self.cardData.cards[tostring(i)].id)] and cardconfig[tostring(self.cardData.cards[tostring(i)].id)].param or ""
        local card = ui.penglaiCidNum(cardstr,gamedata.config.build["22"].level)
        -- -- 双倍活动
        local datatmp = ui.CheckHuodongByParam(5)
        local timesnum = ui.GetHuodongModulus(5)
        -- local datatmp = ui.CheckHuodongByParam(1)
        -- local timesnum = ui.GetHuodongModulus(1)
        if datatmp then
            card.num = card.num * tonumber(timesnum)
        end
            
        ui.setNewIcon(self.brand[i], card)
        ui.setLabelString(self.brand[i].prizeName, ui.IDconfig(card.cid).name or "", ((ui.IDconfig(card.cid).quality and ui.IDconfig(card.cid).quality ~= 0) and ui.IDconfig(card.cid).quality or 1)*2-1)
    end

    self:onTurn()
end

function isLand.onTurn(self) -- 翻牌
    for k,v in pairs(self.cardData.cards) do
        if v.status > 0 then
            if self.olddata and self.olddata.cards[tostring(k)].status > 0 then

            else
                self:onTouchBrand(k, "fanpai_fan-zheng")
            end
        end
    end
    self:onUpdate()
    self:onOffTouch()
end




return isLand o+  