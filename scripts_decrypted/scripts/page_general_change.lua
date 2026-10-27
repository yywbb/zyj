local generalChange = {
	rootNode = nil,
    rootItems = nil,
	    
    offGeneralData = nil,
	offGeneralRemoveData = nil,
	generalData = nil,
}

function generalChange.setOffGeneralData(self, data)
	self.offGeneralData = data
	
	UIRequest({type = 3704})
end

function generalChange.setOffGeneralRemoveData(self, data)
	self.offGeneralRemoveData = data
end

function generalChange.initOffGeneralData(self, openType)
	self.generalData = {}

	if openType == "changed" then
		self.originCid = ui.getOriginCid(self.originSelect.cid)
		self.basic = self.generalConfig[tostring(self.originCid)].basic
		print("self.basic == ",self.basic)
		self.originLevel2Max = self.originSelect.level2
	else
		-- self.originCid = nil
		-- self.basic = nil
		-- self.originLevel2Max = nil
	end

	for k,v in pairs(self.offGeneralData) do
		if openType == "changed" then
			local _cid1 = ui.getOriginCid(v.cid)
			local _level2Max = self.generalConfig[tostring(_cid1)].breach_upper_limit
			
			if self.generalConfig[tostring(_cid1)].basic == self.basic and
				_cid1 ~= self.originCid and
				_level2Max >= self.originLevel2Max then
				table.insert(self.generalData, table.copy(v))
			end
		else
			if v.quality > self.limitQuality then 
				table.insert(self.generalData, table.copy(v))
			end
		end
	end

	for k,v in pairs(self.generalData) do
		v.sortNum = 0
		local _isCanChange = true
		if openType == "origin" then
			if v.level2 < self.breachLevel then
				v.sortNum = v.sortNum + 100
				_isCanChange = false
			elseif self.offGeneralRemoveData[tostring(v.iid)] then
				v.sortNum = v.sortNum + 1
				_isCanChange = false
			end
		end

		if openType == "changed" then
			if v.level1 > 1 then
				v.sortNum = v.sortNum + 100
				_isCanChange = false
			elseif self.offGeneralRemoveData[tostring(v.iid)] then
				v.sortNum = v.sortNum + 1
				_isCanChange = false
			end
		end

		if _isCanChange then
			v.sortNum = v.sortNum + 1000
		end
	end

	local _sortTable = function(left, right)
		if left.sortNum > right.sortNum then
			return true
		elseif left.sortNum < right.sortNum then
			return false
		else
			--突破
			if left.level2 > right.level2 then
				return true
			elseif left.level2 < right.level2 then
				return false
			else
			 	if left.skilllevel > right.skilllevel then
			 		return true
			 	elseif left.skilllevel < right.skilllevel then
			 		return false
			 	else
			 		return left.cid > right.cid
			 	end
			end
		end
	end

	table.sort(self.generalData, _sortTable)
end

function generalChange.realClear(self)
	self:clear()

	if self.rootNode then
		self.rootNode:removeAllChildrenWithCleanup(true)
		self.rootNode:removeFromParentAndCleanup(true)
		self.rootNode = nil
		self.rootItems = nil
	end
end

function generalChange.clear(self)
	self.offGeneralData = nil
	self.offGeneralRemoveData = nil
	self.generalData = nil
end

function generalChange.init(self, touchPriority, toppos)
	self:initNode(touchPriority, toppos)
	self:initChangeNode()
	self:initConfig()
	self:initFixedString()
	self:initEventBtn()
	UIRequest({type = 10024})

	return self.rootNode
end

function generalChange.initNode(self, touchPriority, toppos)
	self.rootNode, self.rootItems = CCBReaderLoad("zhuanhuan/wujiangzhuanhuan_1", nil, true, "wujiangzhuanhuan_1")
	self.touchPriority = touchPriority
	self.rootItems.topnode:setPositionY(toppos - 300)
end

function generalChange.initChangeNode(self)
	self.changeNode, self.changeItems = CCBReaderLoad("zhuanhuan/wujiangzhuanhuan_n", nil, true, "wujiangzhuanhuan_n")
	self.rootItems["changeNode"]:addChild(self.changeNode)
end

function generalChange.initConfig(self)
	self.globalConfig = gamedata.config.global_kv
	self.transformationConfig = gamedata.config.transformation_config
	self.generalConfig = gamedata.config.general
	self.generalFragmentConfig = gamedata.config.general_fragment --碎片
	self.redlAwakeItemConfig = gamedata.config.redl_awake_item --精华
	self.generalAwakeConfig = table.copy(gamedata.config.general_awake) --突破
	self.generalAwakenConfig = table.copy(gamedata.config.general_awaken) --觉醒
	self.breachLevel = tonumber(self.transformationConfig["breach_level"]["value"])
	self.limitQuality =  tonumber(self.transformationConfig["quality_limit"]["value"])
	self.generalFragmentConfig2 = {}
	self.redlAwakeItemConfig2 = {}

	for k,v in pairs(gamedata.config.general_fragment) do
		self.generalFragmentConfig2[tostring(v.general)] = v
	end

	for k,v in pairs(gamedata.config.redl_awake_item) do
		self.redlAwakeItemConfig2[tostring(v.red_id)] = v
	end

	for i = 1, table.getTableLength(self.generalAwakeConfig) do
		local _level2 = tostring(i)

		for ii = 3, 7 do
			if i == 1 then
				self.generalAwakeConfig[_level2]["sumPiece"..ii] = 0 + self.generalAwakeConfig[_level2][ii.."piece"]
			else
				self.generalAwakeConfig[_level2]["sumPiece"..ii] = self.generalAwakeConfig[tostring(i - 1)]["sumPiece"..ii] + self.generalAwakeConfig[_level2][ii.."piece"]
			end
		end
		
		self.generalAwakeConfig[_level2]["sumRedItem"] = self.generalAwakeConfig[_level2]["return_cost_jinghua"]
	end

	for i = 0, table.getTableLength(self.generalAwakenConfig) - 1 do
		if i == 0 then
			self.generalAwakenConfig[tostring(i)]["sumNumber"] = 0 + self.generalAwakenConfig[tostring(i)]["number"]
		else
			self.generalAwakenConfig[tostring(i)]["sumNumber"] = self.generalAwakenConfig[tostring(i - 1)]["sumNumber"] + self.generalAwakenConfig[tostring(i)]["number"]
		end
	end
end

function generalChange.initFixedString(self)
	self.rootItems["descTxt"]:setString(gameConfig.strings:string_common("change", "general", 1))
	self.rootItems["title"]:setString(gameConfig.strings:string_common("change", "general", 2))
	ui.setLabelString(self.rootItems["upTxt"], gameConfig.strings:string_common("change", "general", 3), 18) 
end

function generalChange.initEventBtn(self)
	self:initOriginAddBtn()
	self:initChangedAddBtn()
	self:initChangeBtn()
	self:initRuleBtn()
end

function generalChange.initOriginAddBtn(self)
	local _cb = function()
		if self.locked then
			if self.offGeneralData and next(self.offGeneralData) and self.offGeneralRemoveData and next(self.offGeneralRemoveData) then
				self:initOffGeneralData("origin")
				gameWindows:openWindow( "generalChangeSelect", 
									    {selectData = self.originSelect,data = self.generalData, generalRemoveData = self.offGeneralRemoveData, openType = "origin"},
									    function(data)
											self.originSelect = data
											self:refreshNode("origin")
										end)
			end
		end
	end

	ui.commonBtn(self, self.changeItems, "originAddBtn", _cb)
end

function generalChange.initChangedAddBtn(self)
	local _cb = function()
		if self.locked then
			if self.originSelect and next(self.originSelect) then
				self:initOffGeneralData("changed")
				
				if self.generalData and next(self.generalData) then
					gameWindows:openWindow( "generalChangeSelect",
											{selectData = self.changeSelect,data = self.generalData, generalRemoveData = self.offGeneralRemoveData, openType = "changed"},
											function(data)
												self.changeSelect = data
												self:refreshNode("changed")
											end)
				else
					runGamePrompt({msg = gameConfig.strings:string_common("change", "general", 15)})
				end
			end
		end
	end

	ui.commonBtn(self, self.changeItems, "changedAddBtn", _cb)
end

function generalChange.initChangeBtn(self)
	local _cb = function()
		if self.locked then
			local _gold = tonumber(self.transformationConfig["currency_num"..self.basic]["value"])
			
			if self.originSelect == nil then
				runGamePrompt({msg = gameConfig.strings:string_common("change", "general", 10)})
			elseif self.changeSelect == nil then
				runGamePrompt({msg = gameConfig.strings:string_common("change", "general", 11)})
			elseif self.fragementId and self.propsData and next(self.propsData) and self.propsData[tostring(self.fragementId)] < self.fragementNum then
				runGamePrompt({msg = gameConfig.strings:string_common("change", "general", 12)})
			elseif self.redfragmentcid and self.propsData and next(self.propsData) and self.propsData[tostring(self.redfragmentcid)] < self.redItemNum then
				runGamePrompt({msg = gameConfig.strings:string_common("change", "general", 13)})
			elseif self.basic and self.transformationConfig["currency_num"..self.basic] and next(self.transformationConfig["currency_num"..self.basic]) and GameScene.roleinfo.gold < _gold then
				runGamePrompt({msg = gameConfig.strings:string_common("change", "general", 14)})
			else

				local req = function (  )
					UIRequest({ type = 7025,
							iid1 = self.originSelect.iid,
							iid2 = self.changeSelect.iid,
							fragementId = self.fragementId,
							fragementNum = self.fragementNum,
							redfragmentcid = self.redfragmentcid,
							redItemNum = self.redItemNum,
							gold = _gold,
						})
				end
				if self.originSelect.quality >= 7 and self.originSelect.exclusiveArtifactCid > 0 then
					gameWindows:openWindow("confirm",{msg = string.format(gameConfig.strings:string_common("exclusiveArtifactNew",22), gamedata.config.general[tostring(self.originSelect.cid)].name)}, req)
				else
					req()
				end
			end
		end
	end

	ui.commonBtn(self, self.rootItems, "changeBtn", _cb)
end

function generalChange.initRuleBtn(self)
	local _cb = function()
		gameWindows:openWindow("generalChangedRule")
	end

	ui.commonBtn(self, self.rootItems, "ruleBtn", _cb)
end

function generalChange.runChangeAnimation(self, data)
	local _changeAnimation = getAnimationManager(self.changeItems) 
    _changeAnimation:setAnimationCompletedCallback(function()
		local _general = table.copy(data.general)
		local _opt = 0
    	updateDataLife(data.reward)
    	UIRequest({type = 10322})
		gameWindows:openWindow("generalChangedResult", {general = _general, opt = _opt}, function()
			printT(data.reward,"data.reward")
			if data.reward["1"].num > 0 then
				gameWindows:openWindow("getStaff", data.reward)
			end
    	end)

    	self:runBackAnimation()
    	UIRequest({type = 10024})
    end)

    _changeAnimation:runAnimationsForSequenceNamed("change")
end

function generalChange.runBackAnimation(self)
	local _backAnimation = getAnimationManager(self.changeItems)

    _backAnimation:setAnimationCompletedCallback(function()
       
    end)

    _backAnimation:runAnimationsForSequenceNamed("back")
end

function generalChange.refreshNode(self, refreshType)
	self.locked = true
	self:refreshNodeData()

	if refreshType == "init" then
		self.changeItems["originGeneralNode"]:removeAllChildrenWithCleanup(true)
		self.changeItems["changedGeneralNode"]:removeAllChildrenWithCleanup(true)
		self:refreshChangeNode(true, true, false, false, true)
		self.originSelect = nil
		self.changeSelect = nil
		local _str = LoadJsonStringToTable(gamedata.config.system_intro["60"].intro)
		ui.createRichLabel(_str, self.rootItems["richLabelNode"], false, alignment)
	elseif refreshType == "origin" then
		self.changeItems["changedGeneralNode"]:removeAllChildrenWithCleanup(true)
		self:refreshChangeNode(false, false, true, true, true)
		self:initSpine("originGeneralNode", self.originSelect)
		self.changeSelect = nil
		local _str = LoadJsonStringToTable(gamedata.config.system_intro["61"].intro)
		ui.createRichLabel(_str, self.rootItems["richLabelNode"], false, alignment)
	elseif refreshType == "changed" then
		self:refreshChangeNode(false, false, false, false, false)
		self:initSpine("changedGeneralNode", self.changeSelect)
	end

	self:refreshUseItem(refreshType)
end

function generalChange.refreshNodeData(self)
	self.fragementId = nil
	self.fragementNum = nil
	self.redfragmentcid = nil
	self.redItemNum = nil
	self.propsData = {}
end

function generalChange.refreshItemIcon(self, isShow)
	for i = 1, 2 do
		local _key = ui.getKey(i)
		self.rootItems["item"..i]:setVisible(isShow)
		ui.setLabelString(self.rootItems["priceTxt"], "", 14)
		ui.setLabelString(self.rootItems["i_num".._key], "", 14)
		setSpriteFrameByName(self.rootItems["i_soulsprite".._key], "alpha")
		setSpriteFrameByName(self.rootItems["i_icon".._key], "alpha")
		setSpriteFrameByName(self.rootItems["i_quality".._key], "b_iconbg1")
		setSpriteFrameByName(self.rootItems["i_k_quality".._key], "b_iconk1")
	end
end

function generalChange.refreshUseItem(self, openType)
	if openType == "init" or openType == "origin" then
		self:refreshItemIcon(true)
	elseif openType == "changed" then
		self:refreshItemIcon(false)
		self:getUseItem()
	end
end

function generalChange.getUseItem(self)
	local _level2 = self.originSelect.level2
	local _skilllevel = self.originSelect.skilllevel
	local _cid = ui.getOriginCid(self.originSelect.cid)
	local _quality = self.originSelect.quality
	local _basic = self.generalConfig[tostring(_cid)].basic
	local _basicAwaken = 0

	local _originCid = ui.getOriginCid(self.changeSelect.cid)
	self.fragementId = self.generalFragmentConfig2[tostring(_originCid)]["id"]


	print("getUseItem")

	print(_level2,_skilllevel,_quality)
	printT(originSelect,"originSelect")
	printT(self.generalAwakenConfig,"generalAwakenConfig")
	printT(self.redlAwakeItemConfig2,"redlAwakeItemConfig2")


	if _basic == 20 then
		_basicAwaken = self.globalConfig["general_awaken20"].value
	elseif _basic == 23 then
		_basicAwaken = self.globalConfig["general_awaken23"].value
	elseif _basic == 44 then
		_basicAwaken = self.globalConfig["general_awaken44"].value
	end

	if _skilllevel == 0 then
		_skilllevel = _basicAwaken
	end

	-- self.fragementNum = self.generalAwakeConfig[tostring(_level2)]["sumPiece".._quality] + self.generalAwakenConfig[tostring(_skilllevel)]["sumNumber"] - self.generalAwakenConfig[tostring(_basicAwaken)]["sumNumber"]
	if _basic == 44 then
		self.fragementNum = self.generalAwakeConfig[tostring(_level2)]["return_cost_hunpo44"] + self.generalAwakenConfig[tostring(_skilllevel)]["return_cost44"]
	else
		self.fragementNum = self.generalAwakeConfig[tostring(_level2)]["return_cost_hunpo"] + self.generalAwakenConfig[tostring(_skilllevel)]["return_cost".._basic]
	end
	print("self.fragementNum == ",self.fragementNum)

	local _redConfig = self.redlAwakeItemConfig2[tostring(self:getRedId())]
    self.redfragmentcid = (_redConfig and next(_redConfig)) and _redConfig["id"] or nil
	self.redItemNum =  self.generalAwakeConfig[tostring(_level2)]["sumRedItem"]

	if self.fragementNum == 0 then
		self.fragementId = nil
	end

	if self.redItemNum == 0 then
		self.redfragmentcid = nil
	end

	UIRequest({type = 12001, order = 32008, cids = {self.fragementId, self.redfragmentcid}})
end

function generalChange.setGeneralChangePropNum(self, data)
	self.propsData = data
	local _len = table.getTableLength(self.propsData)

	for i = 1, 2 do
		if i <= _len then
			local _key = ui.getKey(i)
			self.rootItems["item"..i]:setVisible(true)

			if i == 1 and self.fragementId then
				ui.setNewIcon(self.rootItems, {cid = self.fragementId, num = self.propsData[tostring(self.fragementId)].."/"..self.fragementNum}, i - 1)
				
				if self.propsData[tostring(self.fragementId)] < self.fragementNum then
					ui.setLabelString(self.rootItems["i_num".._key],nil,12)
				else
					ui.setLabelString(self.rootItems["i_num".._key],nil,13)
				end

				local _cb = function()
					gameWindows:openWindow("dropTips",{cid = self.fragementId},nil)
				end

				ui.commonBtn(self, self.rootItems, "i_button".._key, _cb)
			end

			if i == 2 and self.redfragmentcid then
				ui.setNewIcon(self.rootItems, {cid = self.redfragmentcid, num = self.propsData[tostring(self.redfragmentcid)].."/"..self.redItemNum}, i - 1)
				
				if self.propsData[tostring(self.redfragmentcid)] < self.redItemNum then
					ui.setLabelString(self.rootItems["i_num".._key],nil,12)
				else
					ui.setLabelString(self.rootItems["i_num".._key],nil,13)
				end

				local _cb = function()
					ui.setPopwindowByCid(self.redfragmentcid)
				end

				ui.commonBtn(self, self.rootItems, "i_button".._key, _cb)
			end
		else
			self.rootItems["item"..i]:setVisible(false)
		end
	end

	local _transformation = self.transformationConfig["currency_num"..self.basic]
	if _transformation and next(_transformation) then
		ui.setLabelString(self.rootItems["priceTxt"], _transformation["value"], 14)
	end
end

-- --魂魄id
-- function generalChange.getOriginCid(self, cid)
-- 	local _fCid = cid
-- 	local _generalConfig = self.generalConfig[tostring(_fCid)]

-- 	if _generalConfig.orange_id and _generalConfig.orange_id > 0 then
--         _fCid = _generalConfig.orange_id
--     elseif _generalConfig.generalid2 and _generalConfig.generalid2 > 0 then
--         _fCid = _generalConfig.generalid2
--     elseif _generalConfig.partner_id and _generalConfig.partner_id > 0 then
--         _fCid = _generalConfig.partner_id    
--     end

--     return _fCid
-- end

--精华id
function generalChange.getRedId(self)
	local _rCid = self.changeSelect.cid
	local _generalConfig = self.generalConfig[tostring(_rCid)]

	if _generalConfig.red_id and _generalConfig.red_id > 0 then
        _rCid = _generalConfig.red_id
    elseif _generalConfig.break_id and _generalConfig.break_id > 0 then
        _rCid = _generalConfig.break_id
    elseif _generalConfig.partner_id and _generalConfig.partner_id > 0 then
        _rCid = _generalConfig.partner_id    
    end

    return _rCid
end

-- 初始化spine
function generalChange.initSpine(self, node, data)
	self.changeItems[node]:removeAllChildrenWithCleanup(true)
	local generalConfig = ui.IDconfig(data.cid)
	local _generalName = gamedata.config.generalanimation[tostring(ui.IDconfig(data.cid).animationid)].name
	if generalConfig.fashion_id == 0 then --非时装
		if data.illusionGeneralCid == nil then
			_generalName = ui.getGeneralAnimationid(_generalName, data)
		end
	end
    -- local _generalName = gamedata.config.generalanimation[tostring(ui.IDconfig(spineId).animationid)].name
    local _gneral = ui.itemcache:loadSkeleton(_generalName)
    _gneral:setAnimation("stand", true, 0)
    _gneral:setScale(1.8)
    self.changeItems[node]:addChild(_gneral.root or _gneral)
end

function generalChange.refreshChangeNode(self, isShow1, isShow2, isShow3, isShow4, isShow5)
	self.changeItems["originAddSprite"]:setVisible(isShow1)
	self.changeItems["originShadowSprite"]:setVisible(isShow2)
	self.changeItems["changedAddSprite"]:setVisible(isShow3)
	self.changeItems["arrowSprite"]:setVisible(isShow4)
	self.rootItems["noneNode"]:setVisible(isShow5)
	self.rootItems["upNode"]:setVisible(not isShow5)
end

function generalChange.generalChange(self, data)
	self.locked = false
	self:runChangeAnimation(data)
end

return generalChange [J  