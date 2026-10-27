local statusOverview = {
	rootNode = nil,
    rootItems = nil,

}

function statusOverview.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function statusOverview.open(self, touchPriority, data, callback)
	printT(data,"statusOverview")
	self.type = data.type
	self:initNode(touchPriority, callback)
	self:initData(data)
	self:initConfig()
    self:initFixedString()
    self:initEventBtn()
    self:reloadData()

    return self.rootNode
end

function statusOverview.initNode(self, touchPriority, callback)
	self.rootNode, self.rootItems = CCBReaderLoad("shenhundian/shenhundian_shuxing", nil, true, "shenhundian_shuxing")
	self.touchPriority = touchPriority
	self.callback = callback
end

function statusOverview.initData(self, data)
	self.soulType = data.soulType
	self.soulLevel = data.soulLevel
	self.soulStatus = data.soulStatus
	self.soulStar = data.soulStar
	self.godStatus = data.godStatus
	self.godStar = data.godStar
	self.status = {
		g_atk = 0,
		g_def = 0,
		g_hp = 0,
		g_adddmg = 0,
		g_subdmg = 0,
		g_criticaldmg = 0,
		g_dodge = 0,
		g_hit = 0,
		g_critical = 0,
		g_resilience = 0,
		g_parry = 0,
		g_arp = 0,
	}
end

function statusOverview.initConfig(self)
	self.sanshengshiConfig = gamedata.config.shenhundian_sanshengshi[self.soulType]
	self.soulConfig = gamedata.config.shenhundian_lianhun[self.soulType] or {}
	self.godConfig = gamedata.config.shenhundian_cuishen[self.soulType] or {}
end

function statusOverview.initFixedString(self)
	self.rootItems["g_atkTxt"]:setString(gameConfig.strings:string_common("godSoulTemple", "status", "g_atk"))
    self.rootItems["g_defTxt"]:setString(gameConfig.strings:string_common("godSoulTemple", "status", "g_def"))
    self.rootItems["g_hpTxt"]:setString(gameConfig.strings:string_common("godSoulTemple", "status", "g_hp"))
    self.rootItems["g_adddmgTxt"]:setString(gameConfig.strings:string_common("godSoulTemple", "status", "g_adddmg"))
    self.rootItems["g_subdmgTxt"]:setString(gameConfig.strings:string_common("godSoulTemple", "status", "g_subdmg"))
    self.rootItems["g_criticaldmgTxt"]:setString(gameConfig.strings:string_common("godSoulTemple", "status", "g_criticaldmg"))
    self.rootItems["g_dodgeTxt"]:setString(gameConfig.strings:string_common("godSoulTemple", "status", "g_dodge"))
    self.rootItems["g_hitTxt"]:setString(gameConfig.strings:string_common("godSoulTemple", "status", "g_hit"))
    self.rootItems["g_criticalTxt"]:setString(gameConfig.strings:string_common("godSoulTemple", "status", "g_critical"))
    self.rootItems["g_resilienceTxt"]:setString(gameConfig.strings:string_common("godSoulTemple", "status", "g_resilience"))
    self.rootItems["g_parryTxt"]:setString(gameConfig.strings:string_common("godSoulTemple", "status", "g_parry"))
    self.rootItems["g_arpTxt"]:setString(gameConfig.strings:string_common("godSoulTemple", "status", "g_arp"))
end

function statusOverview.initEventBtn(self)
	self:initCloseBtn()
end

function statusOverview.initCloseBtn(self)
	local _cb = function()
		gameWindows:closeWindow("statusOverview")
	end

	ui.commonBtn(self, self.rootItems, "closeBtn", _cb)
end

function statusOverview.reloadData(self)
	self:setStatus()
	self:refreshStatus()
end

function statusOverview.setStatus(self)

	if self.type == 1 then
		self:setStoneStatus()
		self:setRefineSoulStatus()
		self:setExtractionGodStatus()
	elseif self.type == 2 then
		self:setRefineSoulStatus()
	elseif self.type == 3 then
		self:setExtractionGodStatus()
	end
	
	self:setSumStatus()
end

function statusOverview.setStoneStatus(self)
	self.stoneStatus = {
		g_atk = self.sanshengshiConfig[tostring(self.soulLevel)] and self.sanshengshiConfig[tostring(self.soulLevel)]["g_atk"] or 0,
		g_def = self.sanshengshiConfig[tostring(self.soulLevel)] and self.sanshengshiConfig[tostring(self.soulLevel)]["g_def"] or 0,
		g_hp = self.sanshengshiConfig[tostring(self.soulLevel)] and self.sanshengshiConfig[tostring(self.soulLevel)]["g_hp"] or 0,
		g_adddmg = 0,
		g_subdmg = 0,
		g_criticaldmg = 0,
		g_dodge = 0,
		g_hit = 0,
		g_critical = 0,
		g_resilience = 0,
		g_parry = 0,
		g_arp = 0,
	}
end

function statusOverview.setRefineSoulStatus(self)
	self.refineSoulStatus = {
		g_atk = 0,
		g_def = 0,
		g_hp = 0,
		g_adddmg = 0,
		g_subdmg = 0,
		g_criticaldmg = 0,
		g_dodge = 0,
		g_hit = 0,
		g_critical = 0,
		g_resilience = 0,
		g_parry = 0,
		g_arp = 0,
	}

	local _refineSoulStatusPercent = {
		g_atk = 1,
		g_def = 1,
		g_hp = 1,
		g_adddmg = 1,
		g_subdmg = 1,
		g_criticaldmg = 0,
		g_dodge = 0,
		g_hit = 0,
		g_critical = 0,
		g_resilience = 0,
		g_parry = 0,
		g_arp = 0,
	}

	if next(self.soulConfig) and self.soulStatus >= 0 then
		local _soulConfigPast = self.soulConfig[tostring(self.soulStatus - 1)]
		local _soulConfigCurrent = self.soulConfig[tostring(self.soulStatus)]
		local _sum = {}

		if _soulConfigPast then
			local _tempSum = ui.Split(_soulConfigPast.attribute_summation, ";")

			for i = 1, #_tempSum do
				if _tempSum[i] ~= "" then
					table.insert(_sum, ui.Split(_tempSum[i], ","))
				end
			end
		end
		
		for i = 1, #_sum do
			if _sum[i][2] == "value" then
				self.refineSoulStatus[_sum[i][1]] = self.refineSoulStatus[_sum[i][1]] + _sum[i][3]
			elseif _sum[i][2] == "percent" then
				_refineSoulStatusPercent[_sum[i][1]] = _refineSoulStatusPercent[_sum[i][1]] + _sum[i][3]
			end
		end

		if self.soulStar >= 0 then
			for i = 1, self.soulStar do
				if _soulConfigCurrent["method"..i] == "value" then
					self.refineSoulStatus[_soulConfigCurrent["attr"..i]] = self.refineSoulStatus[_soulConfigCurrent["attr"..i]] + _soulConfigCurrent["value"..i]
				elseif _soulConfigCurrent["method"..i] == "percent" then
					_refineSoulStatusPercent[_soulConfigCurrent["attr"..i]] = _refineSoulStatusPercent[_soulConfigCurrent["attr"..i]] + _soulConfigCurrent["value"..i]
				end
			end
		end

		for k,v in pairs(self.refineSoulStatus) do
			if k == "g_atk" or k == "g_def" or k == "g_hp" or k == "g_adddmg" or k == "g_subdmg" then
				self.refineSoulStatus[k] = v * _refineSoulStatusPercent[k]
			else
				self.refineSoulStatus[k] = _refineSoulStatusPercent[k] * 100
			end
		end
	end
end

function statusOverview.setExtractionGodStatus(self)
	self.extractionGodStatus = {
		g_atk = 0,
		g_def = 0,
		g_hp = 0,
		g_adddmg = 0,
		g_subdmg = 0,
		g_criticaldmg = 0,
		g_dodge = 0,
		g_hit = 0,
		g_critical = 0,
		g_resilience = 0,
		g_parry = 0,
		g_arp = 0,
	}

	local _extractionGodStatusPercent = {
		g_atk = 1,
		g_def = 1,
		g_hp = 1,
		g_adddmg = 1,
		g_subdmg = 1,
		g_criticaldmg = 0,
		g_dodge = 0,
		g_hit = 0,
		g_critical = 0,
		g_resilience = 0,
		g_parry = 0,
		g_arp = 0,
	}

	if next(self.godConfig) and self.godStatus >= 0 then
		local _godConfigPast = self.godConfig[tostring(self.godStatus - 1)]
		local _godConfigCurrent = self.godConfig[tostring(self.godStatus)]
		local _sum = {}

		if _godConfigPast then
			local _tempSum = ui.Split(_godConfigPast.attribute_summation, ";")

			for i = 1, #_tempSum do
				if _tempSum[i] ~= "" then
					table.insert(_sum, ui.Split(_tempSum[i], ","))
				end
			end
		end
		
		for i = 1, #_sum do
			if _sum[i][2] == "value" then
				self.extractionGodStatus[_sum[i][1]] = self.extractionGodStatus[_sum[i][1]] + _sum[i][3]
			elseif _sum[i][2] == "percent" then
				_extractionGodStatusPercent[_sum[i][1]] = _extractionGodStatusPercent[_sum[i][1]] + _sum[i][3]
			end
		end

		if self.godStar >= 0 then
			for i = 1, self.godStar do
				if _godConfigCurrent["method"..i] == "value" then
					self.extractionGodStatus[_godConfigCurrent["attr"..i]] = self.extractionGodStatus[_godConfigCurrent["attr"..i]] + _godConfigCurrent["value"..i]
				elseif _godConfigCurrent["method"..i] == "percent" then
					_extractionGodStatusPercent[_godConfigCurrent["attr"..i]] = _extractionGodStatusPercent[_godConfigCurrent["attr"..i]] + _godConfigCurrent["value"..i]
				end
			end
		end

		for k,v in pairs(self.extractionGodStatus) do
			if k == "g_atk" or k == "g_def" or k == "g_hp" or k == "g_adddmg" or k == "g_subdmg" then
				self.extractionGodStatus[k] = v * _extractionGodStatusPercent[k]
			else
				self.extractionGodStatus[k] = _extractionGodStatusPercent[k] * 100
			end
		end
	end
end

function statusOverview.setSumStatus(self)
	for k,v in pairs(self.status) do

		if self.type == 1 then
			self.status[k] = self.stoneStatus[k] + self.refineSoulStatus[k] + self.extractionGodStatus[k]
		elseif self.type == 2 then
			self.status[k] = self.refineSoulStatus[k]
		elseif self.type == 3 then
			self.status[k] = self.extractionGodStatus[k]
		end
		-- print(k, self.stoneStatus[k], self.refineSoulStatus[k], self.extractionGodStatus[k], "utai")
	end
end

function statusOverview.refreshStatus(self)
	self.rootItems["g_atk"]:setString(math.floor(self.status.g_atk))
    self.rootItems["g_def"]:setString(math.floor(self.status.g_def))
    self.rootItems["g_hp"]:setString(math.floor(self.status.g_hp))
    self.rootItems["g_adddmg"]:setString(math.floor(self.status.g_adddmg))
    self.rootItems["g_subdmg"]:setString(math.floor(self.status.g_subdmg))
    self.rootItems["g_criticaldmg"]:setString(math.floor(self.status.g_criticaldmg).."%")
    self.rootItems["g_dodge"]:setString(math.floor(self.status.g_dodge).."%")
    self.rootItems["g_hit"]:setString(math.floor(self.status.g_hit).."%")
    self.rootItems["g_critical"]:setString(math.floor(self.status.g_critical).."%")
    self.rootItems["g_resilience"]:setString(math.floor(self.status.g_resilience).."%")
    self.rootItems["g_parry"]:setString(math.floor(self.status.g_parry).."%")
    self.rootItems["g_arp"]:setString(math.floor(self.status.g_arp).."%")
end

return statusOverview   &  