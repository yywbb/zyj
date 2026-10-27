local tortoise = {
	rootNode = nil,
    rootItems = nil,

    soulType = "20",
    pageName = "tortoise",

    soullimit = 2,
    godlimit = 2,
}

function tortoise.realClear(self)
	self:clear()

	self.rootNode:removeAllChildrenWithCleanup(true)
	self.rootNode:removeFromParentAndCleanup(true)
	rootNode = nil
	rootItems = nil
end

function tortoise.clear(self)

end

function tortoise.init(self, touchPriority, toppos)
	self:initNode(touchPriority, toppos)
	self:initConfig()
	self:initFixedString()
	self:initProgresBar()
	self:initEventBtn()

	UIRequest({type = 7030, id = tonumber(self.soulType), pageName = self.pageName})

	return self.rootNode
end

function tortoise.initNode(self, touchPriority, toppos)
	self.rootNode, self.rootItems = CCBReaderLoad("shenhundian/shenhundian_1", nil, true, "shenhundian_1")
	self.touchPriority = touchPriority
	self.rootItems.topnode:setPositionY(toppos - 100)
end

function tortoise.initConfig(self)
	self.sanshengshiConfig = gamedata.config.shenhundian_sanshengshi[self.soulType]
	self.soulConfig = gamedata.config.shenhundian_lianhun[self.soulType]
	self.godConfig = gamedata.config.shenhundian_cuishen[self.soulType]

	self.soullimit = tonumber(self.soulConfig["0"].limit)
	self.godlimit = tonumber(self.godConfig["0"].limit)

	print(self.soullimit,"self.soullimit")
	print(self.godlimit,"self.godlimit")

end

function tortoise.initFixedString(self)
	ui.setLabelString(self.rootItems["levelUpTxt"], gameConfig.strings:string_common("godSoulTemple", "common", 1), 19)
	ui.setLabelString(self.rootItems["levelUpDesc"], gameConfig.strings:string_common("godSoulTemple", "common", 2), 13)
end

function tortoise.initProgresBar(self)
	local _sprite = CCSprite:create("public/publicsprite/obj_15.png")

    self.rootItems.progress = CCProgressTimer:create(_sprite)
    self.rootItems.progress:setAnchorPoint(ccp(0.0, 0.5))
    self.rootItems.progress:setType(kCCProgressTimerTypeBar)
    self.rootItems.progress:setMidpoint(ccp(0, 0.5))
    self.rootItems.progress:setBarChangeRate(ccp(1, 0))
    self.rootItems.progress:setPosition(ccp(0, 0))
    self.rootItems.progress:setPercentage(0)
    self.rootItems.progress:setScaleX(1.25)
    self.rootItems.progress:setScaleY(1.2)
    self.rootItems.progressNode:addChild(self.rootItems.progress)
end


function tortoise.initEventBtn(self)
	self:initRuleBtn()
	self:initRefineSoulBtn()
	self:initExtractionGodBtn()
	self:initLevelUpBtn()
	self:initStatusOverviewBtn()
end

function tortoise.initRuleBtn(self)
	local _cb = function()
          gameWindows:openWindow("godSoulTempleRule",{ ruleid =  "62" })
	end

	ui.commonBtn(self, self.rootItems, "ruleBtn", _cb)
end

function tortoise.initRefineSoulBtn(self)
	local _cb = function()
		if  self.soulStatus >0 or self.soulLevel >= self.soullimit  then
			GameScene:shiftLayer("godSoulTempleRefineSoul", "up", {soulType = self.soulType, soulLevel = self.soulLevel})
		else
			local _str1 = gameConfig.strings:string_common("godSoulTemple", "pageName", 2)
			local _str2 = gameConfig.strings:string_common("godSoulTemple", "common", 10)
			local _str3 = self.soulConfig["0"].limit
			local _str4 = gameConfig.strings:string_common("godSoulTemple", "common", 11)

			runGamePrompt({msg = _str1.._str2.._str3.._str4})
		end
	end

	ui.commonBtn(self, self.rootItems, "refineSoulBtn", _cb)
end

function tortoise.initExtractionGodBtn(self)
	local _cb = function()
		if self.godStatus>0 or self.soulLevel >= self.godlimit then
			GameScene:shiftLayer("godSoulTempleCuishen", "up", {soulType = self.soulType, soulLevel = self.soulLevel})
		else
			local _str1 = gameConfig.strings:string_common("godSoulTemple", "pageName", 2)
			local _str2 = gameConfig.strings:string_common("godSoulTemple", "common", 10)
			local _str3 = self.godConfig["0"].limit
			local _str4 = gameConfig.strings:string_common("godSoulTemple", "common", 12)
			
			runGamePrompt({msg = _str1.._str2.._str3.._str4})
		end
	end

	ui.commonBtn(self, self.rootItems, "extractionGodBtn", _cb)
end

function tortoise.initLevelUpBtn(self)
	local _cb = function()
		if self:checkGeneralsLevel2ByBasic() == 1 then
			UIRequest({type = 7031, id = tonumber(self.soulType), pageName = self.pageName})
		elseif self:checkGeneralsLevel2ByBasic() == 2 then
			runGamePrompt({msg = gameConfig.strings:string_common("godSoulTemple", "common", 8)})
		else
			runGamePrompt({msg = gameConfig.strings:string_common("godSoulTemple", "common", 13)})
		end
	end

	ui.commonBtn(self, self.rootItems, "levelUpBtn", _cb)
end

function tortoise.initStatusOverviewBtn(self)
	local _cb = function()
		gameWindows:openWindow("statusOverview", {
			soulType = self.soulType,
			soulLevel = self.soulLevel, 
			soulStatus = self.soulStatus,
			soulStar = self.soulStar,
			godStatus = self.godStatus,
			godStar = self.godStar,
			type = 1
		})
	end

	ui.commonBtn(self, self.rootItems, "statusOverviewBtn", _cb)
end

function tortoise.reloadData(self, data)
	self:setData(data)
	self:refreshTitle()
	self:refreshSoulNode()
	self:refreshStatusNodes()
	self:refreshLevelUpNode()
	self:reloadHint()
end

function tortoise.reloadHint(self)

	--判断今天有没有点过
	local isShow = true
    local lianhun_FirstString = CCUserDefault:sharedUserDefault():getStringForKey("lianhun_FirstString"..GameScene.roleinfo.id.."_"..self.soulType)
    if lianhun_FirstString and lianhun_FirstString ~= "" then
        local now = os.date("*t", gamedata:time())
        local _t = string.split(lianhun_FirstString,"_")
        if tonumber(_t[1]) == now.year and tonumber(_t[2]) == now.month and tonumber(_t[3]) == now.day then
            isShow = false
        end
    end

    if isShow then
    	local result = self:reloadLianHunHint()
    	ui.sethint(self.rootItems.lianhun_hint,result)
    end


    local isShow = true
    local cuishen_FirstString = CCUserDefault:sharedUserDefault():getStringForKey("cuishen_FirstString"..GameScene.roleinfo.id.."_"..self.soulType)
    if cuishen_FirstString and cuishen_FirstString ~= "" then
        local now = os.date("*t", gamedata:time())
        local _t = string.split(cuishen_FirstString,"_")
        if tonumber(_t[1]) == now.year and tonumber(_t[2]) == now.month and tonumber(_t[3]) == now.day then
            isShow = false
        end
    end

    if isShow then
    	local result = self:reloadCuishenHint()
    	ui.sethint(self.rootItems.cuishen_hint,result)
    end
end

function tortoise.reloadLianHunHint(self)
	local lianhun_hint = true
	print("reloadLianHunHint")

	local soulStatus = self.soulStatus
	local soulStar = self.soulStar
	local soulExp = self.soulExp

	if soulStatus == -1 then
		lianhun_hint = false
		return lianhun_hint
	end

	local generalfragments = self.lianhun_materials.generalfragments


	print("判断炼魂红点")
	if self.soulLevel < self.soullimit then
		print("开启等级不足",self.soulLevel,self.soullimit)
		lianhun_hint = false
		return lianhun_hint
	end

	local soulConfig = gamedata.config.shenhundian_lianhun[self.soulType][tostring(soulStatus)]

	if self.soulLevel < soulConfig.limit then
		print("灵石等级不足",soulConfig.limit,self.soulLevel)
		lianhun_hint = false
		return lianhun_hint
	end

	if soulStar >= soulConfig.number then
		print("MAX")
		lianhun_hint = false
		return lianhun_hint
	end

	local lianhunxiaohao = gamedata.config.shenhundian_lianhunxiaohao[self.soulType]

	local fragments = {}
	for k,v in pairs(lianhunxiaohao) do
		local generalCid = tonumber(k) - 1000 --武将id
		if generalfragments[tostring(generalCid)] then
			local generalConfig = ui.IDconfig(generalCid)
			if generalConfig and generalConfig.basic == tonumber(self.soulType) then
				local _d = generalfragments[tostring(tonumber(k) - 1000)]
				table.insert(fragments,_d)
			end
		end
	end

	local soulMaxExp = soulConfig["experience"..(soulStar + 1)]
	for k,v in pairs(fragments) do
		local config = lianhunxiaohao[tostring(v.fragmentCid)]
		soulExp = soulExp + config.experience * v.num

		if soulExp >= soulMaxExp then
			break
		end
	end

	if soulExp < soulMaxExp then
		print("经验值不够",soulExp,soulMaxExp)
		lianhun_hint = false
		return lianhun_hint
	end

	
	return lianhun_hint
end

function tortoise.reloadCuishenHint(self,data)
	local cuishen_hint = true
	print("reloadCuishenHint")

	local soulStatus = self.godStatus
	local soulStar = self.godStar
	local soulExp = self.godExp

	local props = self.cuishen_materials.props


	if soulStatus == -1 then
		cuishen_hint = false
		return cuishen_hint
	end


	print("判断粹神红点")
	if self.soulLevel < self.godlimit then
		print("开启等级不足",self.soulLevel,self.godlimit)
		cuishen_hint = false
		return cuishen_hint
	end

	local soulConfig = gamedata.config.shenhundian_cuishen[self.soulType][tostring(soulStatus)]

	if self.soulLevel < soulConfig.limit then
		print("灵石等级不足",soulConfig.limit,self.soulLevel)
		cuishen_hint = false
		return cuishen_hint
	end

	if soulStar >= soulConfig.number then
		print("MAX")
		cuishen_hint = false
		return cuishen_hint
	end

	local cuishenxiaohao = gamedata.config.shenhundian_cuishenxiaohao[self.soulType]

	local fragments = {}
	for k,v in pairs(cuishenxiaohao) do
		if props[tostring(k)] then
			table.insert(fragments,k)
		end
	end

	local soulMaxExp = soulConfig["experience"..(soulStar + 1)]
	for k,v in pairs(fragments) do
		local config = cuishenxiaohao[tostring(v)]
		soulExp = soulExp + config.experience * props[tostring(v)]

		if soulExp >= soulMaxExp then
			break
		end
	end

	if soulExp < soulMaxExp then
		print("经验值不够",soulExp,soulMaxExp)
		cuishen_hint = false
		return cuishen_hint
	end

	return cuishen_hint
end

function tortoise.setData(self, data)
	if data.type == 7030 then
		self.soulLevel = data.godSoulTemple.soulLevel
		self.genralsLevel2ByBasic =	data.godSoulTemple.genralsLevel2ByBasic
	    self.soulStatus = data.godSoulTemple.soulStatus
	    self.soulStar = data.godSoulTemple.soulStar
	    self.soulExp = data.godSoulTemple.soulExp
	    self.godStatus = data.godSoulTemple.godStatus
	    self.godStar = data.godSoulTemple.godStar
	    self.godExp = data.godSoulTemple.godExp
	    self.lianhun_materials = data.lianhun_materials
	    self.cuishen_materials = data.cuishen_materials
	elseif data.type == 7031 then
		self.soulLevel = data.godSoulTemple.soulLevel
		self.soulStatus = data.godSoulTemple.soulStatus
		self.godStatus = data.godSoulTemple.godStatus
	end
end

function tortoise.refreshTitle(self)
	self.rootItems["titleTxt"]:setString(gameConfig.strings:string_common("godSoulTemple", "pageName", 2)..self.soulLevel..gameConfig.strings:string_common("godSoulTemple", "common", 3))
end

function tortoise.refreshSoulNode(self)
	self.rootItems["soulNode"]:removeAllChildrenWithCleanup(true)
	local _ccbNode, _ccbItem

	if self.soulLevel == 0 then
		_ccbNode, _ccbItem = CCBReaderLoad("shenhundian/"..self.sanshengshiConfig[tostring(self.soulLevel + 1)].picture_ccb, nil, true, "tortoiseSoul")
	else
		_ccbNode, _ccbItem = CCBReaderLoad("shenhundian/"..self.sanshengshiConfig[tostring(self.soulLevel)].picture_ccb, nil, true, "tortoiseSoul")
	end

	self.rootItems["soulNode"]:addChild(_ccbNode)
end

function tortoise.refreshStatusNodes(self)
	self:refreshStatusShow()
	self:refreshStatus()
end

function tortoise.checkLevel(self)
	return self.soulLevel < table.getTableLength(self.sanshengshiConfig)
end

function tortoise.refreshStatusShow(self)
	if self:checkLevel() then
		self.rootItems["currentNode"]:setPositionX(170)
		self.rootItems["arrowSprite"]:setVisible(true)
		self.rootItems["nextNode"]:setVisible(true)
	else
		self.rootItems["currentNode"]:setPositionX(540)
		self.rootItems["arrowSprite"]:setVisible(false)
		self.rootItems["nextNode"]:setVisible(false)
	end
end

function tortoise.refreshStatus(self)
	self:refreshCurrentStatus()

	if self:checkLevel() then
		self:refreshNextStatus()
	end
end

function tortoise.refreshCurrentStatus(self)
	ui.setLabelString(self.rootItems["currentStatusTxt"], gameConfig.strings:string_common("godSoulTemple", "common", 4), 13)
	self.rootItems["currentGatkTxt"]:setString(gameConfig.strings:string_common("godSoulTemple", "common", "g_atk"))
	self.rootItems["currentGdefTxt"]:setString(gameConfig.strings:string_common("godSoulTemple", "common", "g_def"))
	self.rootItems["currentGhpTxt"]:setString(gameConfig.strings:string_common("godSoulTemple", "common", "g_hp"))
	self.rootItems["currentGatk"]:setString((self.sanshengshiConfig[tostring(self.soulLevel)] and next(self.sanshengshiConfig[tostring(self.soulLevel)])) and self.sanshengshiConfig[tostring(self.soulLevel)].g_atk or 0)
	self.rootItems["currentGdef"]:setString((self.sanshengshiConfig[tostring(self.soulLevel)] and next(self.sanshengshiConfig[tostring(self.soulLevel)])) and self.sanshengshiConfig[tostring(self.soulLevel)].g_def or 0)
	self.rootItems["currentGhp"]:setString((self.sanshengshiConfig[tostring(self.soulLevel)] and next(self.sanshengshiConfig[tostring(self.soulLevel)])) and self.sanshengshiConfig[tostring(self.soulLevel)].g_hp or 0)
end

function tortoise.refreshNextStatus(self)
	ui.setLabelString(self.rootItems["nextStatusTxt"], gameConfig.strings:string_common("godSoulTemple", "common", 5), 13)
	self.rootItems["nextGatkTxt"]:setString(gameConfig.strings:string_common("godSoulTemple", "common", "g_atk"))
	self.rootItems["nextGdefTxt"]:setString(gameConfig.strings:string_common("godSoulTemple", "common", "g_def"))
	self.rootItems["nextGhpTxt"]:setString(gameConfig.strings:string_common("godSoulTemple", "common", "g_hp"))
	self.rootItems["nextGatk"]:setString((self.sanshengshiConfig[tostring(self.soulLevel + 1)] and next(self.sanshengshiConfig[tostring(self.soulLevel + 1)])) and self.sanshengshiConfig[tostring(self.soulLevel + 1)].g_atk or 0)
	self.rootItems["nextGdef"]:setString((self.sanshengshiConfig[tostring(self.soulLevel + 1)] and next(self.sanshengshiConfig[tostring(self.soulLevel + 1)])) and self.sanshengshiConfig[tostring(self.soulLevel + 1)].g_def or 0)
	self.rootItems["nextGhp"]:setString((self.sanshengshiConfig[tostring(self.soulLevel + 1)] and next(self.sanshengshiConfig[tostring(self.soulLevel + 1)])) and self.sanshengshiConfig[tostring(self.soulLevel + 1)].g_hp or 0)
end

function tortoise.refreshLevelUpNode(self)
	self:refreshLevelUpDesc()
	self:refreshLevel2()
	self:refreshProgress()
	self:refreshBtnGray()
end

function tortoise.checkGeneralsLevel2ByBasic(self)
	if self:checkLevel() then
		return self.genralsLevel2ByBasic >= self.sanshengshiConfig[tostring(self.soulLevel + 1)].breakthrough_limit and 1 or 2
	else
		return 3
	end
end

function tortoise.refreshLevelUpDesc(self)
	if self:checkLevel() then
		local _str1 = gameConfig.strings:string_common("godSoulTemple", "common", 6)
		local _str2 = gameConfig.strings:string_common("godSoulTemple", "common", 7)
		ui.setLabelString(self.rootItems["levelUpDesc1"], _str1..self.soulType.._str2, 13)
		if self.genralsLevel2ByBasic >= self.sanshengshiConfig[tostring(self.soulLevel + 1)].breakthrough_limit then
			ui.setLabelString(self.rootItems["levelUpDesc2"], self.sanshengshiConfig[tostring(self.soulLevel + 1)].breakthrough_limit, 26)
		else
			ui.setLabelString(self.rootItems["levelUpDesc2"], self.sanshengshiConfig[tostring(self.soulLevel + 1)].breakthrough_limit, 27)
		end
	else
		ui.setLabelString(self.rootItems["levelUpDesc1"], "", 13)
		ui.setLabelString(self.rootItems["levelUpDesc2"], "", 13)
	end
end

function tortoise.refreshLevel2(self)
	if self:checkLevel() then
		ui.setLabelString(self.rootItems["level2Txt"], self.genralsLevel2ByBasic.."/"..self.sanshengshiConfig[tostring(self.soulLevel + 1)].breakthrough_limit, 13)
	else
		ui.setLabelString(self.rootItems["level2Txt"], "max", 13)
	end
end

function tortoise.refreshProgress(self)
	if self:checkLevel() then
		local _num = self.genralsLevel2ByBasic / self.sanshengshiConfig[tostring(self.soulLevel + 1)].breakthrough_limit
		_num = _num > 1 and 1 or _num
		self.rootItems.progress:setPercentage(100 * _num)
	    self.rootItems["progressEffect"]:setPositionX(math.floor(1000 * _num))
	else
		self.rootItems.progress:setPercentage(100)
	    self.rootItems["progressEffect"]:setPositionX(math.floor(1000))
	end
end

function tortoise.refreshBtnGray(self)
	self:refreshLevelUpBtnGray()
	self:refreshRefineSoulBtnGray()
	self:refreshExtractionGodBtn()
end

function tortoise.refreshLevelUpBtnGray(self)
	if self:checkGeneralsLevel2ByBasic() == 1 then
		ui.removeGray("CCControlButton", self.rootItems["levelUpBtn"])
	else
		ui.addGray("CCControlButton", self.rootItems["levelUpBtn"])
	end
end

function tortoise.refreshRefineSoulBtnGray(self)
	if self.soulStatus >0 or self.soulLevel >= self.soullimit then
		ui.removeGray("CCControlButton", self.rootItems["refineSoulBtn"])
	else
		ui.addGray("CCControlButton", self.rootItems["refineSoulBtn"])	
	end
end

function tortoise.refreshExtractionGodBtn(self)
	if self.godStatus>0  or self.soulLevel >= self.godlimit then
		ui.removeGray("CCControlButton", self.rootItems["extractionGodBtn"])
	else
		ui.addGray("CCControlButton", self.rootItems["extractionGodBtn"])	
	end
end

return tortoise  �B  