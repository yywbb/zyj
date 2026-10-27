local swapChange = {
	rootNode = nil,
    rootItems = nil,
	    
    offGeneralData = nil,
	offGeneralRemoveData = nil,
	generalData = nil,

	needpropnum = 3,
	npNum = 1,
}

function swapChange.setOffGeneralData(self, data)
	self.offGeneralData = data
	
	UIRequest({type = 3704})
end

function swapChange.setOffGeneralRemoveData(self, data)
	self.offGeneralRemoveData = data
end

function swapChange.initOffGeneralData(self, openType)
	self.generalData = {}

	if openType == "changed" then
		self.originCid = ui.getOriginCid(self.originSelect.cid)
		self.originUpperLimit = self.generalConfig[tostring(self.originCid)].breach_upper_limit
	else
		self.originCid = nil
	end

	printT(self.offGeneralData,"offGeneralData")
	for k,v in pairs(self.offGeneralData) do
		local _cid1 = ui.getOriginCid(v.cid)
		if self.generalConfig[tostring(_cid1)].exchange_id ~= nil and self.generalConfig[tostring(_cid1)].exchange_id ~= ""
			and _cid1 ~= self.originCid then
			table.insert(self.generalData, table.copy(v))
		end
	end
	--排序
	for k,v in pairs(self.generalData) do
		v.sortNum = 0
		local _isCanChange = true
		if openType == "origin" then
			if self.offGeneralRemoveData[tostring(v.iid)] then
				v.sortNum = v.sortNum + 1
				_isCanChange = false
			end
		end

		if openType == "changed" then
			if self.offGeneralRemoveData[tostring(v.iid)] then
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

function swapChange.realClear(self)
	self:clear()

	if self.rootNode then
		self.rootNode:removeAllChildrenWithCleanup(true)
		self.rootNode:removeFromParentAndCleanup(true)
		self.rootNode = nil
		self.rootItems = nil
	end

end

function swapChange.clear(self)
	self.offGeneralData = nil
	self.offGeneralRemoveData = nil
	self.generalData = nil
end

function swapChange.init(self, touchPriority, toppos)
	self:initNode(touchPriority, toppos)
	self:initChangeNode()
	self:initConfig()
	self:initFixedString()
	self:initEventBtn()
	UIRequest({type = 10024})

	return self.rootNode
end

function swapChange.initNode(self, touchPriority, toppos)
	self.rootNode, self.rootItems = CCBReaderLoad("zhuanhuan/wujiangzhuanhuan_2", nil, true, "wujiangzhuanhuan_2")
	self.touchPriority = touchPriority
	self.rootItems.topnode:setPositionY(toppos - 300)
end

function swapChange.initChangeNode(self)
	self.changeNode, self.changeItems = CCBReaderLoad("zhuanhuan/wujiangzhuanhuan_n2", nil, true, "wujiangzhuanhuan_n2")
	self.rootItems["changeNode"]:addChild(self.changeNode)
end

function swapChange.initConfig(self)
	self.globalConfig = gamedata.config.global_kv
	self.generalConfig = gamedata.config.general
	self.exchange_break = gamedata.config.exchange_break_value --互换突破参数
	self.exchange_awaken = gamedata.config.exchange_awaken_param --互换觉醒参数
	self.exchange_soaring = gamedata.config.exchange_soaring_param --互换飞升参数
end

function swapChange.initFixedString(self)
	self.rootItems["descTxt"]:setString(gameConfig.strings:string_common("change", "general", 19))
	self.rootItems["title"]:setString(gameConfig.strings:string_common("change", "general", 2))
	ui.setLabelString(self.rootItems["upTxt"], gameConfig.strings:string_common("change", "general", 20), 18) 
end

function swapChange.initEventBtn(self)
	self:initOriginAddBtn()
	self:initChangedAddBtn()
	self:initChangeBtn()
	self:initRuleBtn()
end

function swapChange.initOriginAddBtn(self)
	local _cb = function()
		if self.locked then
			if self.offGeneralData and next(self.offGeneralData) and self.offGeneralRemoveData and next(self.offGeneralRemoveData) then
				self:initOffGeneralData("origin")
				gameWindows:openWindow( "swapChangeSelect", 
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

function swapChange.initChangedAddBtn(self)
	local _cb = function()
		if self.locked then
			if self.originSelect and next(self.originSelect) then
				self:initOffGeneralData("changed")
				if self.generalData and next(self.generalData) then
					gameWindows:openWindow( "swapChangeSelect",
											{selectData = self.changeSelect,data = self.generalData, generalRemoveData = self.offGeneralRemoveData, openType = "changed", upperLimit = self.originUpperLimit},
											function(data)
												self.changeSelect = data
												self:refreshNode("changed")
											end)
				else
					runGamePrompt({msg = gameConfig.strings:string_common("change", "general", 22)})
				end
			end
		end
	end

	ui.commonBtn(self, self.changeItems, "changedAddBtn", _cb)
end

function swapChange.initChangeBtn(self)
	local _cb = function()
		if self.locked then
			if self.originSelect == nil then
				runGamePrompt({msg = gameConfig.strings:string_common("change", "general", 17)})
			elseif self.changeSelect == nil then
				runGamePrompt({msg = gameConfig.strings:string_common("change", "general", 17)})
			elseif self.originSelect.level2 < 4 and self.changeSelect.level2 < 4 then
				runGamePrompt({msg = gameConfig.strings:string_common("change", "general", 18)})
			elseif self.propsData[tostring(self.globalConfig.exchange_prop.value)] < self.needpropnum then
				runGamePrompt({msg = gameConfig.strings:string_common("change", "general", 21)})
			else
				
				local req = function (  )
					local callback =  function()
						UIRequest({ type = 8095,
							iid1 = self.originSelect.iid,
							iid2 = self.changeSelect.iid,
							needpropid = self.globalConfig.exchange_prop.value,
							needpropnum = self.needpropnum,
						})
					end

					if math.ceil(self.npNum) <= 0 then
						gameWindows:openWindow("confirm",{msg = gameConfig.strings:string_common("change", "general", 25)}, callback)
					else
						callback()
					end
				end

				if (self.originSelect.quality >= 7 and self.originSelect.exclusiveArtifactCid > 0 and self.changeSelect.quality < 7) then
					gameWindows:openWindow("confirm",{msg = string.format(gameConfig.strings:string_common("exclusiveArtifactNew",23), gamedata.config.general[tostring(self.originSelect.cid)].name)}, req)
				elseif (self.changeSelect.quality >= 7 and self.changeSelect.exclusiveArtifactCid > 0 and self.originSelect.quality < 7) then
					gameWindows:openWindow("confirm",{msg = string.format(gameConfig.strings:string_common("exclusiveArtifactNew",23), gamedata.config.general[tostring(self.changeSelect.cid)].name)}, req)
				else
					req()
				end

			end
		end
	end

	ui.commonBtn(self, self.rootItems, "changeBtn", _cb)
end

function swapChange.initRuleBtn(self)
	local _cb = function()
		gameWindows:openWindow("generalChangedRule",{other = "swap"})
	end

	ui.commonBtn(self, self.rootItems, "ruleBtn", _cb)
end

function swapChange.runChangeAnimation(self, data)
	local _changeAnimation = getAnimationManager(self.changeItems)

    _changeAnimation:setAnimationCompletedCallback(function()
		local _general = table.copy(data.general)
		local _general2 = table.copy(data.general2)
		local _opt = 0
    	UIRequest({type = 10322})
		self.originSelect = nil
		self.changeSelect = nil
		self.originCid = nil
		if _general.quality == _general2.quality then
			_opt = 1
		end
        gameWindows:openWindow("generalChangedResult", {general = _general2, opt = _opt}, function()
    		gameWindows:openWindow("generalChangedResult", {general = _general, opt = _opt})
    	end)

    	self:runBackAnimation()
		UIRequest({type = 10024})
    end)

    _changeAnimation:runAnimationsForSequenceNamed("change")
end

function swapChange.runBackAnimation(self)
	local _backAnimation = getAnimationManager(self.changeItems)

    _backAnimation:setAnimationCompletedCallback(function()
       
    end)

    _backAnimation:runAnimationsForSequenceNamed("back")
end

function swapChange.refreshNode(self, refreshType)
	self.locked = true
	self:refreshNodeData()

	if refreshType == "init" then
		self.changeItems["originGeneralNode"]:removeAllChildrenWithCleanup(true)
		self.changeItems["changedGeneralNode"]:removeAllChildrenWithCleanup(true)
		self:refreshChangeNode(true, true, false, false, true)
		self.originSelect = nil
		self.changeSelect = nil
		local _str = LoadJsonStringToTable(gamedata.config.system_intro["85"].intro)
		ui.createRichLabel(_str, self.rootItems["richLabelNode"], false, alignment)
	elseif refreshType == "origin" then
		self.changeItems["changedGeneralNode"]:removeAllChildrenWithCleanup(true)
		self:refreshChangeNode(false, false, true, true, true)
		self:initSpine("originGeneralNode", self.originSelect)
		self.changeSelect = nil
		local _str = LoadJsonStringToTable(gamedata.config.system_intro["86"].intro)
		ui.createRichLabel(_str, self.rootItems["richLabelNode"], false, alignment)
	elseif refreshType == "changed" then
		self:refreshChangeNode(false, false, false, false, false)
		self:initSpine("changedGeneralNode", self.changeSelect)
	end

	self:refreshUseItem(refreshType)
end

function swapChange.refreshNodeData(self)
	self.fragementId = nil
	self.fragementNum = nil
	self.redfragmentcid = nil
	self.redItemNum = nil
	self.propsData = {}
end

function swapChange.refreshItemIcon(self, isShow)
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

function swapChange.refreshUseItem(self, openType)
	if openType == "init" or openType == "origin" then
		self:refreshItemIcon(true)
	elseif openType == "changed" then
		self:refreshItemIcon(false)
		self:getUseItem()
	end
end

function swapChange.getUseItem(self)
	printT(self.originSelect,"originSelect")
	printT(self.changeSelect,"changeSelect")
	local xa = 1
	local ya = 1
	local za = 1
	local xb = 1
	local yb = 1
	local zb = 1
	local xa2 = 1
	local ya2 = 1
	local za2 = 1
	local xb2 = 1
	local yb2 = 1
	local zb2 = 1
	local s_a = 0
	local s_b = 0
	if self.originSelect then
		local exchange1_id = self.generalConfig[tostring(self.originSelect.cid)].exchange_id
		local nums1 = ui.Split(exchange1_id,";")
		local exchange1 = {}
		for k,v in pairs(nums1) do
            if v ~= nil and v ~= "" then
                table.insert(exchange1, tonumber(v))
            end
		end
		printT(exchange1, "exchange1")
		xa = self.exchange_break[tostring(exchange1[1])][tostring(self.originSelect.level2)]["value"]
		if self.originSelect.skilllevel > 0 then
			ya = self.exchange_awaken[tostring(exchange1[2])][tostring(self.originSelect.skilllevel)]["value"]
		else
			ya = self.exchange_awaken[tostring(exchange1[2])][tostring(self:getGeneralAwakenBasic(self.originSelect))]["value"]
		end
		za = self.exchange_soaring[tostring(exchange1[3])][tostring(self.originSelect.level8)]["value"]

		xa2 = self.exchange_break[tostring(exchange1[1])][tostring(self.changeSelect.level2)]["value"]
		if self.changeSelect.skilllevel > 0 then
			ya2 = self.exchange_awaken[tostring(exchange1[2])][tostring(self.changeSelect.skilllevel)]["value"]
		else
			ya2 = self.exchange_awaken[tostring(exchange1[2])][tostring(self:getGeneralAwakenBasic(self.changeSelect))]["value"]
		end
		za2 = self.exchange_soaring[tostring(exchange1[3])][tostring(self.changeSelect.level8)]["value"]
		s_a = xa + ya - xa2 - ya2
	end

	if self.changeSelect then
		local exchange2_id = self.generalConfig[tostring(self.changeSelect.cid)].exchange_id
		local nums2 = ui.Split(exchange2_id,";")
		local exchange2 = {}
		for k,v in pairs(nums2) do
			if v ~= nil and v ~= "" then
				table.insert(exchange2, tonumber(v))
			end
		end
		printT(exchange2, "exchange2")
		xb = self.exchange_break[tostring(exchange2[1])][tostring(self.changeSelect.level2)]["value"]
		if self.changeSelect.skilllevel > 0 then
			yb = self.exchange_awaken[tostring(exchange2[2])][tostring(self.changeSelect.skilllevel)]["value"]
		else
			yb = self.exchange_awaken[tostring(exchange2[2])][tostring(self:getGeneralAwakenBasic(self.changeSelect))]["value"]
		end
		zb = self.exchange_soaring[tostring(exchange2[3])][tostring(self.changeSelect.level8)]["value"]

		xb2 = self.exchange_break[tostring(exchange2[1])][tostring(self.originSelect.level2)]["value"]
		if self.originSelect.skilllevel > 0 then
			yb2 = self.exchange_awaken[tostring(exchange2[2])][tostring(self.originSelect.skilllevel)]["value"]
		else
			yb2 = self.exchange_awaken[tostring(exchange2[2])][tostring(self:getGeneralAwakenBasic(self.originSelect))]["value"]
		end
		zb2 = self.exchange_soaring[tostring(exchange2[3])][tostring(self.originSelect.level8)]["value"]
		s_b = xb + yb - xb2 - yb2
	end

	print("s_a == ", s_a)
	print("s_b == ", s_b)
	local x1 = xa
	local y1 = ya
	local z1 = za
	local x1_2 = xa2
	local y1_2 = ya2
	local z1_2 = za2

	local x2 = xb
	local y2 = yb
	local z2 = zb
	local x2_2 = xb2
	local y2_2 = yb2
	local z2_2 = zb2

	if s_a < s_b then
		x1 = xb
		y1 = yb
		z1 = zb
		x1_2 = xb2
		y1_2 = yb2
		z1_2 = zb2

		x2 = xa
		y2 = ya
		z2 = za
		x2_2 = xa2
		y2_2 = ya2
		z2_2 = za2
	end

	local U = (x2_2+y2_2) - (x2+y2)
	local V = (z2_2+z1_2) - (z2+z1)
	local W = (x1+y1) - (x1_2+y1_2)
	local pNum = (U+V)*tonumber(self.globalConfig.exchange_param_1.value) - W*tonumber(self.globalConfig.exchange_param_2.value)
	print("pNum == ", pNum)
	self.npNum = pNum
	if pNum < tonumber(self.globalConfig.exchange_param_3.value)  then
		pNum = tonumber(self.globalConfig.exchange_param_3.value)
	end

	self.needpropnum = math.ceil(pNum)
	print("needpropnum == ", self.needpropnum)

	UIRequest({type = 12001, order = 32008, cids = {tonumber(self.globalConfig.exchange_prop.value)}})
end

function swapChange.getGeneralAwakenBasic(self, general)
	local awaken = 0
	if general.basic == 18 then
		awaken = 0
	elseif general.basic == 20 then
		awaken = self.globalConfig.general_awaken20.value
	elseif general.basic == 23 then
		awaken = self.globalConfig.general_awaken23.value
	elseif general.basic == 44 then
		awaken = self.globalConfig.general_awaken44.value
	end
	return awaken
end

function swapChange.setGeneralChangePropNum(self, data)
	self.propsData = data
	local _len = table.getTableLength(self.propsData)

	for i = 1, 2 do
		if i <= _len then
			local _key = ui.getKey(i)
			self.rootItems["item"..i]:setVisible(true)

			if i == 1 then
				ui.setNewIcon(self.rootItems, {cid = self.globalConfig.exchange_prop.value, num = self.propsData[tostring(self.globalConfig.exchange_prop.value)].."/"..self.needpropnum}, i - 1)
				
				if self.propsData[tostring(self.globalConfig.exchange_prop.value)] < self.needpropnum then
					ui.setLabelString(self.rootItems["i_num".._key],nil,12)
				else
					ui.setLabelString(self.rootItems["i_num".._key],nil,13)

				end

				local _cb = function()
					gameWindows:openWindow("dropTips",{cid = self.globalConfig.exchange_prop.value},nil)
				end

				ui.commonBtn(self, self.rootItems, "i_button".._key, _cb)
			end

			-- if i == 2 and self.redfragmentcid then
			-- 	ui.setNewIcon(self.rootItems, {cid = self.redfragmentcid, num = self.propsData[tostring(self.redfragmentcid)].."/"..self.redItemNum}, i - 1)
				
			-- 	if self.propsData[tostring(self.redfragmentcid)] < self.redItemNum then
			-- 		ui.setLabelString(self.rootItems["i_num".._key],nil,12)
			-- 	else
			-- 		ui.setLabelString(self.rootItems["i_num".._key],nil,13)
			-- 	end

			-- 	local _cb = function()
			-- 		ui.setPopwindowByCid(self.redfragmentcid)
			-- 	end

			-- 	ui.commonBtn(self, self.rootItems, "i_button".._key, _cb)
			-- end
		else
			self.rootItems["item"..i]:setVisible(false)
		end
	end

	if self.originSelect and self.changeSelect then
		if self.originSelect.level2 >= 4 or self.changeSelect.level2 >= 4 then
			self.rootItems["tupotip"]:setVisible(false)
			ui.removeGray("CCControlButton", self.rootItems["changeBtn"])
			ui.removeGray("CCLabelTTF", self.rootItems["upTxt"])
		else
			self.rootItems["tupotip"]:setVisible(true)
			ui.setLabelString(self.rootItems["tupotip"],nil,12)
			ui.addGray("CCControlButton", self.rootItems["changeBtn"])
			ui.addGray("CCLabelTTF", self.rootItems["upTxt"])
		end
	end
end

-- --魂魄id
-- function swapChange.getOriginCid(self, cid)
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
function swapChange.getRedId(self)
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
function swapChange.initSpine(self, node, data)
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

function swapChange.refreshChangeNode(self, isShow1, isShow2, isShow3, isShow4, isShow5)
	self.changeItems["originAddSprite"]:setVisible(isShow1)
	self.changeItems["originShadowSprite"]:setVisible(isShow2)
	self.changeItems["changedAddSprite"]:setVisible(isShow3)
	self.changeItems["arrowSprite"]:setVisible(isShow4)
	self.rootItems["noneNode"]:setVisible(isShow5)
	self.rootItems["upNode"]:setVisible(not isShow5)
end

function swapChange.generalChange(self, data)
	self.locked = false
	self:runChangeAnimation(data)
end

return swapChange N  