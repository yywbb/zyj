local swapChangeSelect = {
	cellSize = {width = 930, height = 228},
	rootNode = nil,
    rootItems = nil,

    listTableView = nil,
    isSelect = nil,
	-- tabList = {"18", "20", "23", "44"},
	tabList = {"18"},
    selectTab = 1,
}

function swapChangeSelect.close(self)
	gameTouch:UnrigistFunc("begin", "swapChangeSelect")
    gameTouch:UnrigistFunc("end", "swapChangeSelect")

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.listTableView = nil
    self.isSelect = nil
    self.selectTab = 1
end

function swapChangeSelect.open(self, touchPriority, data, callback)
	self:initNode(touchPriority, callback)
	self:initConfig()
	self:initData(data)
	self:initTab()
    self:initFixedString()
    self:initEventBtn()
    self:initTouch()
    self:createList()

    return self.rootNode
end

function swapChangeSelect.initNode(self, touchPriority, callback)
	self.rootNode, self.rootItems = CCBReaderLoad("zhuanhuan/tc_wujianghuhuan", nil, true, "tc_wujianghuhuan")
	self.touchPriority = touchPriority
	self.callback = callback
end

function swapChangeSelect.initData(self, data)
	-- self.data = {["18"] = {}, ["20"] = {}, ["23"] = {}, ["44"] = {}}
	self.data = {["18"] = {}}
	self.generalRemoveData = data.generalRemoveData
	self.openType = data.openType
	self.selectData = data.selectData

	if data.upperLimit then
		self.upperLimit = data.upperLimit
	end


	for i,v in ipairs(data.data) do
		local _originCid = ui.getOriginCid(v.cid)
		local _basic = self.generalConfig[tostring(_originCid)].basic
		
		-- if _basic == 18 or _basic == 20 or _basic == 23 or _basic == 44 then
		-- 	table.insert(self.data[tostring(_basic)], v)
		-- end

		table.insert(self.data["18"], v)
	end

	for k,v in pairs(self.data) do
		if next(v) == nil then
			self.data[k] = nil
		end
	end


end

function swapChangeSelect.initTab(self)
	self.tabConfig = {}
	self.tabConfigKey = {}

	for i = 1, table.getTableLength(self.data) do
		for ii = 1, #self.tabList do
			local _key = self.tabList[ii]
			if self.data[_key] and next(self.data[_key]) and self.tabConfigKey[_key] == nil then
				self.tabConfig[i] = {}
				self.tabConfig[i].id = i
				self.tabConfig[i].name = _key..gameConfig.strings:string_common("change", "general", 16)
				self.tabConfig[i].data = self.data[_key]
				self.tabConfigKey[_key] = true
				break
			end
		end
	end

	-- for i = 1, #self.tabConfig do
	-- 	self.rootItems["tab"..i]:setVisible(true)
	-- 	self.rootItems["tabLab"..i]:setString(self.tabConfig[i].name)

	-- 	local _cb = function()
	-- 		self.selectTab = i
	-- 		self:ChangeTab()
	-- 		self.listTableView:setLuaContentOffset(0, self.rootItems.listscrollgeneral:getContentSize().height - table.getTableLength(self.currentData) * self.cellSize.height)
	-- 		self.listTableView:reloadData()
	-- 	end

	-- 	ui.commonBtn(self, self.rootItems, "tabBtn"..i, _cb)
	-- end

	self:ChangeTab()

end

function swapChangeSelect.ChangeTab(self)
	-- for i = 1, #self.tabConfig do
	-- 	if self.selectTab == i then
	-- 		setSpriteFrameByName(self.rootItems["tabOn"..i], gameConfig.images.pageButtonON)
	-- 	else
	-- 		setSpriteFrameByName(self.rootItems["tabOn"..i], gameConfig.images.pageButtonOFF)
	-- 	end
	-- end

	self.currentData = self.tabConfig[self.selectTab].data

	self.isSelect = nil
	for i,v in ipairs(self.currentData) do
		if self.selectData and self.selectData.cid == v.cid then
			self.isSelect = i
			break
		end
	end
end

function swapChangeSelect.initConfig(self)
	self.generalConfig = gamedata.config.general
end

function swapChangeSelect.initFixedString(self)
	ui.setLabelString(self.rootItems["okTxt"], gameConfig.strings:string_common("change", "general", 4), 18)
end

function swapChangeSelect.initEventBtn(self)
	self:initCloseBtn()
	self:initOkBtn()
end

function swapChangeSelect.initCloseBtn(self)
	local _cb = function()
		gameWindows:closeWindow("swapChangeSelect")
	end

	ui.commonBtn(self, self.rootItems, "closeBtn", _cb)
end

function swapChangeSelect.initOkBtn(self)
	local _cb = function()
		if self.isSelect then
			if self.callback then
				self.callback(self.currentData[self.isSelect])
			end
			gameWindows:closeWindow("swapChangeSelect")
		else
			gameWindows:closeWindow("swapChangeSelect")
		end
	end

	ui.commonBtn(self, self.rootItems, "okBtn", _cb)
end

function swapChangeSelect.initTouch(self)
    local _touchBegin = function(pos)
        self.isscrolltouched = false
    end
    
    local _touchEnd = function(pos)
        if self.rootItems.listscrollgeneral and ui.isTouched(self.rootItems.listscrollgeneral, pos.x, pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("begin", "swapChangeSelect", _touchBegin)
    gameTouch:rigistFunc("end", "swapChangeSelect", _touchEnd)
end

function swapChangeSelect.createList(self)
	local _celldict = {}
    local _listHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local _r

        if fn == "cellSize" then
            _r = CCSizeMake(self.cellSize.width, self.cellSize.height)
        elseif fn == "cellAtIndex" then
            local _cellCCB, _ccbDocumentControler = 0,0
            local _first = true

            if not a2 then
                a2 = CCTableViewCell:create()
                _cellCCB, _ccbDocumentControler = CCBReaderLoad("zhuanhuan/cell_wujiangzhuanhuan", nil, true, "cell_wujiangzhuanhuan")
                _celldict[a2] = {cellCCB = _cellCCB, ccbDocumentControler = _ccbDocumentControler }
            else
                _first = false
                _cellCCB = _celldict[a2].cellCCB
                _ccbDocumentControler = _celldict[a2].ccbDocumentControler
            end

            self:setCell(_ccbDocumentControler, self.currentData[a1 + 1], a1 + 1)

            _cellCCB:setPosition(self.cellSize.width / 2, 0)

            if _first then
                a2:addChild(_cellCCB)
            end

            _r = a2
        elseif fn == "numberOfCells" then
            _r = table.getTableLength(self.currentData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end

        return _r
    end)

    self.listTableView = ui.createLuaTableView({
        handle = _listHandle,
        viewwidth = self.rootItems.listscrollgeneral:getContentSize().width,
        viewheight = self.rootItems.listscrollgeneral:getContentSize().height,
        dire = 1
    })
    self.listTableView:setTouchPriority(self.touchPriority)
    self.rootItems.listscrollgeneral:addChild(self.listTableView)
end

function swapChangeSelect.setCell(self, item, data, index)
	local _config = self.generalConfig[tostring(data.cid)]
	self:setGeneralIcon(item, data)
	self:setGeneralActorIcon(item, data, _config)
	self:setGeneralName(item, data, _config)
	self:setGeneralPower(item, data)
	self:setOnWhere(item, data)
	self:setIsSelectShow(item, index)
	self:setSelectBtn(item, data, index)
end

function swapChangeSelect.setGeneralIcon(self, item, data)
	-- 设置头像
	if data.illusionGeneralCid == nil then
		local configGeneral = gamedata.config.general[tostring(data.cid)]
		local gdata = ui.getConfigGeneral(data)
		if next(gdata) and configGeneral.fashion_id == 0 then
			data.icon = gdata.icon
		end
	end
	ui.setIconLv(item, data)
end

function swapChangeSelect.setGeneralActorIcon(self, item, data, config)
	setSpriteFrameByName(item["type"], gameConfig.images[config.actor])
end

function swapChangeSelect.setGeneralName(self, item, data, config)
	if config.quality and config.quality >= 7 then
        ui.setLabelString(item["name"], config.name..((data.level2 and data.level2 > 0) and " +"..data.level2 or ""), 213)
    else
        ui.setLabelString(item["name"], config.name..((data.level2 and data.level2 > 0) and " +"..data.level2 or ""), config.quality and 2 * config.quality - 1 or 1)
    end
end

function swapChangeSelect.setGeneralPower(self, item, data, config)
	item["power"]:setString(gameConfig.strings:string_common("change", "general", 5)..data.power)
end

function swapChangeSelect.setOnWhere(self, item, data)
	-- if data.level1 > 1 and self.openType == "changed" then
	-- 	item["onwhere"]:setString("("..gameConfig.strings:string_common("change", "general", 6)..")")
	-- elseif data.level2 < 4 and self.openType == "origin" then
	-- 	item["onwhere"]:setString("("..gameConfig.strings:string_common("change", "general", 7)..")")
	-- elseif self.generalRemoveData[tostring(data.iid)] then
	-- 	item["onwhere"]:setString("("..gameConfig.strings:string_common("change", "general", 8)..")")
	-- else
	-- 	item["onwhere"]:setString("")
	-- end

	local _cid1 = ui.getOriginCid(data.cid)
	local _upperLimit = self.generalConfig[tostring(_cid1)].breach_upper_limit

	if self.generalRemoveData[tostring(data.iid)] then
		item["onwhere"]:setString("("..gameConfig.strings:string_common("change", "general", 8)..")")
	elseif _upperLimit ~= self.upperLimit and self.openType == "changed" then
		item["onwhere"]:setString("("..gameConfig.strings:string_common("change", "general", 23)..")")
	else
		item["onwhere"]:setString("")
	end
end

function swapChangeSelect.setIsSelectShow(self, item, index)
	item["isSelect"]:setVisible(index == self.isSelect)
end

function swapChangeSelect.setSelectBtn(self, item, data, index)
	local _cb = function()
		if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end

		-- if data.level1 > 1 and self.openType == "changed" then
		-- 	runGamePrompt({msg = gameConfig.strings:string_common("change", "general", 6)..gameConfig.strings:string_common("change", "general", 9)})
		-- elseif data.level2 < 4 and self.openType == "origin" then
		-- 	runGamePrompt({msg = gameConfig.strings:string_common("change", "general", 7)..gameConfig.strings:string_common("change", "general", 9)})
		-- elseif self.generalRemoveData[tostring(data.iid)] then
		-- 	runGamePrompt({msg = gameConfig.strings:string_common("change", "general", 8)..gameConfig.strings:string_common("change", "general", 9)})
		-- else
		-- 	self.isSelect = index
		-- 	self.listTableView:reloadData()
		-- end

		local _cid1 = ui.getOriginCid(data.cid)
		local _upperLimit = self.generalConfig[tostring(_cid1)].breach_upper_limit

		if self.generalRemoveData[tostring(data.iid)] then
			runGamePrompt({msg = gameConfig.strings:string_common("change", "general", 8)..gameConfig.strings:string_common("change", "general", 9)})
		elseif _upperLimit ~= self.upperLimit and self.openType == "changed" then
			runGamePrompt({msg = gameConfig.strings:string_common("change", "general", 23)..gameConfig.strings:string_common("change", "general", 24)})
		else
			self.isSelect = index
			self.listTableView:reloadData()
		end
	end

	ui.commonBtn(self, item, "selectBtn", _cb)
end

return swapChangeSelect �+  