local token = {
	rsootNode = nil,
    rootItems = nil,
	data = nil,
    touchPriority = -102,

	titleCellSize = {x=180,y=180},
    generalListTableView = nil,
    sid = 1,
    generalindex = 1,

	activeNodes = {},
	activeItems = {},
    
	cellSize = {width = 160, height = 160},
	listTableView = nil,

	sid = 1,
	select = {1,1,1,1,1,1,1},
	select2 = {1,1,1,1,1,1,1},	
	props = nil,
	MAX_NUM = 4
}

function token.idleRequest()

end

function token.realClear(self)
	self:clear()
end

function token.clear(self)
	if self.rootNode then
		for i = 1, self.MAX_NUM do
			self.activeNodes[i]:removeAllChildrenWithCleanup(true)
			self.activeNodes[i]:removeFromParentAndCleanup(true)
		end

		self.activeNodes = {}
		self.activeItems = {}
		self.rootNode:removeAllChildrenWithCleanup(true)
		self.rootNode:removeFromParentAndCleanup(true)
		self.rootNode = nil
		self.rootItems = nil
		self.data = nil
		self.listTableView = nil
		self.props = nil

		self.generalListTableView = nil
		self.sid = 1
		self.generalindex = 1
	end
end

function token.init(self, touchPriority, toppos, data)
	self:initNode(touchPriority, toppos)
	self:initConfig()
	self:initData(data)
	self:initEvent()
	self:reloadGeneralData()
    self:reload()

	return self.rootNode
end

function token.initNode(self, touchPriority, toppos)
	self.rootNode, self.rootItems = CCBReaderLoad("tianjiling/tianjiling", nil, true, "tianjiling")
	self.touchPriority = touchPriority
	self.rootItems.topnode:setPositionY(toppos)

	for i = 1, self.MAX_NUM do
		self.activeNodes[i], self.activeItems[i] = CCBReaderLoad("tianjiling/tianjiling_icon", nil, true, "tianjiling_icon"..i)
		self.rootItems["activeIcon"..i]:addChild(self.activeNodes[i])

		local _cb = function()
			local _sid = self.slotdata[tostring(self.generalindex)].sid

			if self.select2[_sid] ~= i then
				self.select2[_sid] = i
				self:selectItems()
			end
		end

		ui.commonBtn(self, self.activeItems[i], "i_button", _cb)
	end
end

function token.initConfig(self)
	self.tokenConfig = gamedata.config.token
	self.tokenSuitConfig = gamedata.config.token_suit
	self.tempTokenConfig = {}

	for k,v in pairs(gamedata.config.token) do
		local _id = v.suit
		local _location = v.location

		if not self.tempTokenConfig[_id] then
			self.tempTokenConfig[_id] = {}
		end

		if not self.tempTokenConfig[_id][_location] then
			self.tempTokenConfig[_id][_location] = {}
		end

		self.tempTokenConfig[_id][_location].id = v.id
		self.tempTokenConfig[_id][_location].name = v.name
        self.tempTokenConfig[_id][_location].icon = v.icon
        self.tempTokenConfig[_id][_location].bg = v.bg
		self.tempTokenConfig[_id][_location].desc = v.desc
		self.tempTokenConfig[_id][_location].cost = ui.getIDandNUMs(v.cost)[1]
		self.tempTokenConfig[_id][_location].label = v.label
		self.tempTokenConfig[_id][_location].recover = v.recover
		self.tempTokenConfig[_id][_location].quality = v.quality
		self.tempTokenConfig[_id][_location].limit_level = v.limit_level
	end

	-- printT(self.tempTokenConfig)
end

function token.initData(self, data)
	self.sid = data.sid or 1
    self.slotdata = data.slotdata

    if data and data.slotdata and table.getTableLength(data.slotdata) > 0 then
        _slotdata = data.slotdata
    else
        _slotdata = GameScene.layers["slotsInfo"].module.slotdata
    end

    if _slotdata and next(_slotdata) then
        local temp = table.copy(_slotdata)
        local indexs = {}
        for k,v in pairs(temp) do
            if v.general then
                table.insert(indexs,k)
            end
        end
        local sortfunc = function (a,b)
            return tonumber(a) < tonumber(b)
        end
        table.sort(indexs,sortfunc)
        --
        self.slotdata = {}
        for i = 1, #indexs do
            self.slotdata[tostring(i)] = temp[tostring(indexs[i])]
        end
    end

    for k,v in pairs(self.slotdata) do
        if self.sid and v.sid and v.sid == self.sid then
            self.generalindex = tonumber(k)
        end
    end
end

function token.initEvent(self)
	self:initBackBtn()
	self:initRuleBtn()
	self:initActiveBtn()
	self:initSumStatusBtn()
end

function token.initBackBtn(self)
	local _cb = function()
        GameScene:shiftLayer(GameScene.priorLayer,"up", {sid = self.slotdata[tostring(self.generalindex)].sid or 1})
	end

	ui.commonBtn(self, self.rootItems, "closeButton", _cb)
end

function token.initRuleBtn(self)
	local _cb = function()
		ui.popCommonRule(631)
	end

	ui.commonBtn(self, self.rootItems, "rulebutton", _cb)
end

function token.initActiveBtn(self)

    ui.setLabelString(self.rootItems.doLab3,nil,19)

	local _cb = function()
        gameTouch:clickprofbytime(1)
		local _sid = self.slotdata[tostring(self.generalindex)].sid
        local tokenConfig = self.tempTokenConfig[self.select[_sid]][self.select2[_sid]]
		local _needLevel = tokenConfig.limit_level
		local _cost = tokenConfig.cost
		local _cid = tokenConfig.id

		if GameScene.roleinfo.level >= _needLevel and
		   	self.props[tostring(_cost.cid)] >= _cost.num and
			self.props[tostring(_cid)] >= 1 then

            local _sid = self.slotdata[tostring(self.generalindex)].sid
            local _location = self.select2[_sid]
			
            UIRequest({type = 8241, 
				sid = _sid,
				location = _location,
				cost = {
					{cid = _cid, num = 1},
					{cid = _cost.cid, num = _cost.num}
				}
			})

            if self.data.token[self.select[_sid]].activeNum + 1 == self.MAX_NUM and
                self.select[_sid] < table.getTableLength(self.tokenSuitConfig)  then
                self.select[_sid] = self.select[_sid] + 1
                self.select2[_sid] = 1
            end
		else
			if GameScene.roleinfo.level < _needLevel then
				runGamePrompt({msg = gameConfig.strings:string_common("token", 5)})
            elseif self.props[tostring(_cid)] < 1 then
                runGamePrompt({msg = "未获得"..tokenConfig.name.."，请先获得该令牌"})
			elseif self.props[tostring(_cost.cid)] < _cost.num then
				runGamePrompt({msg = gamedata.config.props[tostring(_cost.cid)].name.."不足"})
			else

			end
		end
	end

	ui.commonBtn(self, self.rootItems, "activeBtn", _cb)
end

function token.initSumStatusBtn(self)
	local _cb = function()
		local _data = {}

		for i, v in ipairs(self.data.token) do
			table.insert(_data, v.data)
		end

		gameWindows:openWindow("tokenOverview", _data)
	end

	ui.commonBtn(self, self.rootItems, "activeStatusBtn", _cb)
	ui.commonBtn(self, self.rootItems, "activedStatusBtn", _cb)
end

function token.reloadSlotData(self)
    local _slotdata = GameScene.layers["slotsInfo"].module.slotdata

    if _slotdata and next(_slotdata) then
        local _temp = table.copy(_slotdata)
        local _indexs = {}

        for k,v in pairs(_temp) do
            if v.general then
                table.insert(_indexs, k)
            end
        end

        local sortfunc = function (a,b)
            return tonumber(a) < tonumber(b)
        end

        table.sort(_indexs, sortfunc)
        --
        self.slotdata = {}

        for i = 1, #_indexs do
            self.slotdata[tostring(i)] = _temp[tostring(_indexs[i])]
        end

        self:reloadGeneralData()
        self:reload()
    end
end

function token.reloadGeneralData(self)
    if not self.generalListTableView then
        self:reloadGeneralList()
    else
        self.generalListTableView:reloadData()
    end

    -- 添加touch层 伙伴左右拖动换位
    self:touchLayerSet()
end

function token.reloadGeneralList(self,alldata)
    local _celldict = {}
    local _generalListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local _r

        if fn == "cellSize" then
            _r = CCSizeMake(self.titleCellSize.x, self.titleCellSize.y)
        elseif fn == "cellAtIndex" then
            local _cellCCB, _ccbDocumentControler = 0,0
            local _first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                _cellCCB, _ccbDocumentControler = CCBReaderLoad("slotsInfo/generalIcon.ccbi", nil, true, "generalIcon")
                _celldict[a2] = {_cellCCB=_cellCCB,_ccbDocumentControler=_ccbDocumentControler }

                ui.tableviewAnimationH(self.generalListTableView,_cellCCB,self.titleCellSize.x, self.titleCellSize.y,a1)
            else
                _first = false
                _cellCCB = _celldict[a2]._cellCCB
                _ccbDocumentControler = _celldict[a2]._ccbDocumentControler
            end

            _cellCCB:setScale(0.9)
            _ccbDocumentControler.selectEffect:removeAllChildrenWithCleanup(true)
            if self.slotdata[tostring(a1+1)] and self.slotdata[tostring(a1+1)].general then
                -- 设置头像
                local generalData = self.slotdata[tostring(a1+1)] or {}
				if generalData.general then
					if generalData.general.illusionGeneralCid then
						local configGeneral = gamedata.config.general[tostring(generalData.general.illusionGeneralCid)]
						local gdata = ui.getConfigGeneralSion(generalData.general)
						if next(gdata) and configGeneral.fashion_id == 0 then
							ui.setSlotGeneralIcon(generalData,_ccbDocumentControler,0,gdata)
						else
							ui.setSlotGeneralIcon(generalData,_ccbDocumentControler)
						end
					else
						local configGeneral = gamedata.config.general[tostring(generalData.general.cid)]
						local gdata = ui.getConfigGeneral(generalData.general)
						if next(gdata) and configGeneral.fashion_id == 0 then
							ui.setSlotGeneralIcon(generalData,_ccbDocumentControler,0,gdata)
						else
							ui.setSlotGeneralIcon(generalData,_ccbDocumentControler)
						end
					end
				else
					ui.setSlotGeneralIcon(self.slotdata[tostring(a1+1)],_ccbDocumentControler)
				end

                ui.sethint(_ccbDocumentControler.g_hint, self.slotdata[tostring(a1+1)].tokenHint == 1)
            end

            if self.generalindex == a1+1 then
                local eccb,eitem = CCBReaderLoad("UIEffect/zhenrongxuanzhong/zhenrongxuanzhong", nil, true, "zhenrongxuanzhong")
                eccb:setScale(1.1)
                _ccbDocumentControler.selectEffect:addChild(eccb)
            end

            if self.generalListTableView then
                _cellCCB:setPosition(self.titleCellSize.x/2, self.titleCellSize.y/2)
            end
            
            if _first then
                a2:addChild(_cellCCB)
            end

            _r = a2
        elseif fn == "numberOfCells" then
            _r = table.getTableLength(self.slotdata)
        elseif fn == "cellTouched" then
            gameTouch:clickprofbytime(0.5)

            if a1:getIdx()+1<= table.getTableLength(self.slotdata) then
                self:setGeneralIndex(a1:getIdx()+1,true)
            else

            end
        elseif fn == "scrollViewDidScroll" then
        end
        return _r
    end)

    self.generalListTableView = ui.createLuaTableView({
        handle = _generalListHandle,
        viewwidth = self.rootItems.listscroll:getContentSize().width,
        viewheight = self.rootItems.listscroll:getContentSize().height,
        dire = 0
    })
    self.rootItems.listscroll:addChild(self.generalListTableView)
    self.generalListTableView:setTouchPriority(-102)
    --
    if self.generalindex > 5 then
        self.generalListTableView:setContentOffsetInDuration(ccp(-self.titleCellSize.x * (self.generalindex-5) ,0),0.2)
    end
end

function token.setGeneralIndex(self,index)
    self.generalindex = index
    self.generalcid = self.slotdata[tostring(self.generalindex)].general and self.slotdata[tostring(self.generalindex)].general.cid or nil

    if self.generalListTableView then
        self.generalListTableView:reloadData()
    end
    -- 滑动层设置
    self:touchLayerSet()
	self:reload()
end

-- 添加touch层 伙伴左右拖动换位
function token.touchLayerSet(self)
    self.standdata = {{cid=0,index=0},{cid=0,index=0},{cid=0,index=0}}

    if self.slotdata[tostring(self.generalindex-1)] and self.slotdata[tostring(self.generalindex-1)].general then
        self.standdata[1]["cid"] = self.slotdata[tostring(self.generalindex-1)].general.cid or 0
        self.standdata[1]["index"] = self.generalindex-1
    end

    self.standdata[2]["cid"] = self.slotdata[tostring(self.generalindex)].general.cid or 0
    self.standdata[2]["index"] = self.generalindex

    if self.slotdata[tostring(self.generalindex+1)] and self.slotdata[tostring(self.generalindex+1)].general then
        self.standdata[3]["cid"] = self.slotdata[tostring(self.generalindex+1)].general.cid or 0
        self.standdata[3]["index"] = self.generalindex+1
    end

    self.rootItems.markLeft:setVisible(true)
    self.rootItems.markRight:setVisible(true)

    if self.standdata[1]["cid"] == 0 then
        self.rootItems.markLeft:setVisible(false)
    end

    if self.standdata[3]["cid"] == 0 then
        self.rootItems.markRight:setVisible(false)
    end

    self.rootItems.general:removeAllChildrenWithCleanup(true)
    self.stepGneral1 = nil
    self.stepGneral2 = nil
    self.stepGneral3 = nil

    local wing = {level = GameScene.protagonist.w_l, color = GameScene.protagonist.w_c}

    if self.standdata[1]["cid"] ~= 0 then
        -- printT(self.slotdata[tostring(self.standdata[1].index)],"jkp-self.standdata[1]")
        -- 设置形象
        local generalConfig = gamedata.config.general[tostring(self.standdata[1]["cid"])]
        local generalName = gamedata.config.generalanimation[tostring(generalConfig.animationid)].name
        if generalConfig.fashion_id == 0 then --非时装
            local generalData = self.slotdata[tostring(self.standdata[1].index)].general
            if generalData.illusionGeneralCid == nil then
                generalName = ui.getGeneralAnimationid(generalName, generalData)
            end
        end
        self.stepGneral1 = CCNode:create()
        local general = ui.itemcache:loadSkeleton(generalName,wing)
        --local general = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        general:setAnimation("stand",true,0)
        general:setScale(1.6)
        self.stepGneral1:addChild(general.root or general)
        self.stepGneral1:setPosition(-820,-50)
        self.rootItems.general:addChild(self.stepGneral1)
    end

    ---
    if self.standdata[2]["cid"] ~= 0 then
        -- printT(self.slotdata[tostring(self.standdata[2].index)],"jkp-self.standdata[2]")
        -- 设置形象
        local generalConfig = gamedata.config.general[tostring(self.standdata[2]["cid"])]
        local generalName = gamedata.config.generalanimation[tostring(generalConfig.animationid)].name
        if generalConfig.fashion_id == 0 then --非时装
            local generalData = self.slotdata[tostring(self.standdata[2].index)].general
            if generalData.illusionGeneralCid == nil then
                generalName = ui.getGeneralAnimationid(generalName, generalData)
            end
        end
        self.stepGneral2 = CCNode:create()
        local general = ui.itemcache:loadSkeleton(generalName,wing)
        --local general =CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        general:setAnimation("stand",true,0)
        general:setScale(1.6)
        self.stepGneral2:addChild(general.root or general)
        self.stepGneral2:setPosition(0,-50)
        self.rootItems.general:addChild(self.stepGneral2)
        --
    end


    if self.standdata[3]["cid"] ~= 0 then
        -- printT(self.slotdata[tostring(self.standdata[3].index)],"jkp-self.standdata[3]")
        -- 设置形象
        local generalConfig = gamedata.config.general[tostring(self.standdata[3]["cid"])]
        local generalName = gamedata.config.generalanimation[tostring(generalConfig.animationid)].name
        if generalConfig.fashion_id == 0 then --非时装
            local generalData = self.slotdata[tostring(self.standdata[3].index)].general
            if generalData.illusionGeneralCid == nil then
                generalName = ui.getGeneralAnimationid(generalName, generalData)
            end
        end
        self.stepGneral3 = CCNode:create()
        local general = ui.itemcache:loadSkeleton(generalName,wing)
        --local general =CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        general:setAnimation("stand",true,0)
        general:setScale(1.6)
        self.stepGneral3:addChild(general.root or general)
        self.stepGneral3:setPosition(820,-50)
        self.rootItems.general:addChild(self.stepGneral3)
        --
    end

    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.touchLayer,x,y) then
            self.touchX = x
            self.touchY = y
            self.item1 = nil
            self.item2 = nil
            self.item3 = nil
            self.x1,self.y1 = 0,0
            self.x2,self.y2 = 0,0
            self.x3,self.y3 = 0,0

            if self.stepGneral1 then
                self.item1 = tolua.cast(self.stepGneral1,"CCNode")
                self.x1,self.y1 = self.item1:getPosition()
            end

            if self.stepGneral2 then
                self.item2 = tolua.cast(self.stepGneral2,"CCNode")
                self.x2,self.y2 = self.item2:getPosition()
            end

            if self.stepGneral3 then
                self.item3 = tolua.cast(self.stepGneral3,"CCNode")
                self.x3,self.y3 = self.item3:getPosition()
            end

            return true
        end
    end

    local function ccTouchMoved(x, y)
        local distanceX = x-self.touchX
        if math.abs(distanceX) >20 then
            if self.item1 then
                self.item1:setPositionX(self.x1+distanceX)
            end

            if self.item2 then
                self.item2:setPositionX(self.x2+distanceX)
            end
            if self.item3 then
                self.item3:setPositionX(self.x3+distanceX)
            end
        end

    end

    local function ccTouchEnded(x, y)
        if x-self.touchX > 20 then
            gameTouch:clickprofbytime(0.5)
            self:setActionRightreload()
        elseif self.touchX-x > 20 then
            gameTouch:clickprofbytime(0.5)
            self:setActionLeftreload()
        end
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then
            return ccTouchBegan(x, y)
        elseif eventType == "moved" then
            return ccTouchMoved(x, y)
        elseif eventType == "ended" then
            return ccTouchEnded(x, y)
        end
    end

    if self.rootItems.touchLayer then
        self.rootItems.touchLayer:registerScriptTouchHandler(onTouch, false, -101, false)
        self.rootItems.touchLayer:setTouchPriority(-101)
        self.rootItems.touchLayer:setTouchEnabled(true)
    end
end

function token.setActionRightreload(self)
    if self.item1 then
        local moveTo = CCMoveTo:create(0.8, ccp(0, -50))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item1:runAction(backOut)
        self.item1:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.5),CCCallFunc:create(function()
            self.generalindex = self.standdata[1]["index"]
            self.generalcid = self.slotdata[tostring(self.generalindex)].general.cid or nil
            self.generalListTableView:reloadData()

            self:touchLayerSet()
            self:reload()

            if self.standdata[2]["index"] == table.getTableLength(self.slotdata) then
                if  self.rootItems.listscroll:getContentSize().width - self.titleCellSize.x * (self.standdata[2]["index"]) < 0  then
                    self.generalListTableView:setContentOffsetInDuration(ccp(self.rootItems.listscroll:getContentSize().width - self.titleCellSize.x * (self.standdata[2]["index"]),0),0.2)
                end
            elseif  self.titleCellSize.x * self.standdata[2]["index"] >  self.rootItems.listscroll:getContentSize().width - self.generalListTableView:getLuaContentOffsetX() then
                self.generalListTableView:setContentOffsetInDuration(ccp(self.rootItems.listscroll:getContentSize().width - self.titleCellSize.x * self.standdata[2]["index"],0),0.2)
            elseif self.titleCellSize.x * (self.standdata[2]["index"]-1) < -self.generalListTableView:getLuaContentOffsetX() then
                self.generalListTableView:setContentOffsetInDuration(ccp(-self.titleCellSize.x * (self.standdata[2]["index"]-1) ,0),0.2)
            end

        end)))
    else
        local moveTo = CCMoveTo:create(0.5, ccp(0, -50))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item2:runAction(backOut)
        local moveTo = CCMoveTo:create(0.5, ccp(820, -50))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item3:runAction(backOut)

        return
    end
    
    if self.item2 then
        local moveTo = CCMoveTo:create(1, ccp(820, -50))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item2:runAction(backOut)
    end
end

function token.setActionLeftreload(self)
    if self.item3 then
        local moveTo = CCMoveTo:create(0.8, ccp(0, -50))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item3:runAction(backOut)
        self.item3:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.5),CCCallFunc:create(function()
        -- 移动后刷新页面
            self.generalindex = self.standdata[3]["index"]
            self.generalcid = self.slotdata[tostring(self.generalindex)].general.cid or nil
            self.generalListTableView:reloadData()

            self:touchLayerSet()
            self:reload()
            
            if self.standdata[2]["index"] == table.getTableLength(self.slotdata) then
                if  self.rootItems.listscroll:getContentSize().width - self.titleCellSize.x * (self.standdata[2]["index"]) < 0  then
                    self.generalListTableView:setContentOffsetInDuration(ccp(self.rootItems.listscroll:getContentSize().width - self.titleCellSize.x * (self.standdata[2]["index"]),0),0.2)
                end
            elseif  self.titleCellSize.x * self.standdata[2]["index"] >  self.rootItems.listscroll:getContentSize().width - self.generalListTableView:getLuaContentOffsetX() then
                self.generalListTableView:setContentOffsetInDuration(ccp(self.rootItems.listscroll:getContentSize().width - self.titleCellSize.x * self.standdata[2]["index"],0),0.2)
            elseif self.titleCellSize.x * (self.standdata[2]["index"]-1) < -self.generalListTableView:getLuaContentOffsetX() then
                self.generalListTableView:setContentOffsetInDuration(ccp(-self.titleCellSize.x * (self.standdata[2]["index"]-1) ,0),0.2)
            end

        end)))

    else
        local moveTo = CCMoveTo:create(0.5, ccp(-820, -50))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item1:runAction(backOut)

        local moveTo = CCMoveTo:create(0.5, ccp(0, -50))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item2:runAction(backOut)

        return
    end

    if self.item2 then
        local moveTo = CCMoveTo:create(1, ccp(-820, -50))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item2:runAction(backOut)
    end
end

function token.selectItems(self)
	local _sid = self.slotdata[tostring(self.generalindex)].sid
	local _config =	self.tempTokenConfig[self.select[_sid]]
	local _cids = {}
	
	for i,v in ipairs(_config) do
		table.insert(_cids, v.id)
		table.insert(_cids, v.cost.cid)
	end

	UIRequest({type = 12001, order = 34307, cids = _cids})
end

function token.reloadPropNum(self, data)
	self.props = data

	self:refreshTokenNode()
	self:refreshStatusNode()
end

function token.refreshTokenList(self)
	if not self.listTableView then
        self:refreshList()
    else
        self.listTableView:reloadData()
    end
end

function token.refreshList(self)
	local _celldict = {}
    local _listHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local _r

        if fn == "cellSize" then
            _r = CCSizeMake(self.cellSize.width, self.cellSize.height)
        elseif fn == "cellAtIndex" then
            local _cellCCB, _ccbDocumentControler = 0, 0
            local _first = true

            if not a2 then
                a2 = CCTableViewCell:create()
                _cellCCB, _ccbDocumentControler = CCBReaderLoad("tianjiling/tianjiling_icon", nil, true, "tianjiling_icon")
                _celldict[a2] = {cellCCB = _cellCCB, ccbDocumentControler = _ccbDocumentControler }
            else
                _first = false
                _cellCCB = _celldict[a2].cellCCB
                _ccbDocumentControler = _celldict[a2].ccbDocumentControler
            end

			local _sid = self.slotdata[tostring(self.generalindex)].sid
			
            self:setCell(_ccbDocumentControler, self.tokenSuitConfig[tostring(a1 + 1)], a1 + 1)
			self:refreshSelectEffect(_ccbDocumentControler, self.select[_sid], a1 + 1)
			
            _cellCCB:setPosition(self.cellSize.width / 2, self.cellSize.height / 2)
			_cellCCB:setScale(0.8)

            if _first then
                a2:addChild(_cellCCB)
            end

            _r = a2
        elseif fn == "numberOfCells" then
            _r = table.getTableLength(self.tokenSuitConfig)
        elseif fn == "cellTouched" then
			gameTouch:clickprofbytime(0.5)

			if a1:getIdx() == 0 or self.data.token[a1:getIdx()].activeNum == self.MAX_NUM then
				local _sid = self.slotdata[tostring(self.generalindex)].sid

				if self.select[_sid] ~= a1:getIdx()+1 then
					self.select[_sid] = a1:getIdx()+1
					self:selectItems()
					self.listTableView:reloadData()
				end
            else
                runGamePrompt({msg = gameConfig.strings:tokenNeedSuit(self.tokenSuitConfig[tostring(self.data.section + 1)]["1"].name)})
			end
        elseif fn == "scrollViewDidScroll" then

        end

        return _r
    end)

    self.rootItems["listNode"]:removeAllChildrenWithCleanup(true)
    self.listTableView = ui.createLuaTableView({
        handle = _listHandle,
        viewwidth = self.rootItems["listNode"]:getContentSize().width,
        viewheight = self.rootItems["listNode"]:getContentSize().height,
        dire = 0
    })
    self.rootItems["listNode"]:addChild(self.listTableView)
    self.listTableView:setTouchPriority(self.touchPriority - 1)
end

function token.setCell(self, item, data, index)
	local _config = self.tokenSuitConfig[tostring(index)]["1"]

	setSpriteFrameByName(item.i_icon, _config.suit_icon)
    setSpriteFrameByName(item.i_quality, _config.suit_bg)
	item.tokenNameLab:setString(data["1"].name)
    ui.setLabelString(item.tokenNameLab, nil, 18, 30)
	item.suitEffect:setVisible(self.data.token[index].activeNum == self.MAX_NUM)

	if index <= self.data.section + 1 then
		ui.removeGray("CCSprite", item.i_icon)
		ui.removeGray("CCSprite", item.i_quality)
		item.tokenStatusLab:setString(self.data.token[index].activeNum .. "/" .. self.MAX_NUM)
	else
		ui.addGray("CCSprite", item.i_icon)
		ui.addGray("CCSprite", item.i_quality)
		item.tokenStatusLab:setString(gameConfig.strings:string_common("token", self.MAX_NUM))
	end
end

function token.reload(self)
	self:refreshData()
    self:refreshTokenList()
    self:selectItems()
end

function token.refreshData(self)
	local _data = self.slotdata[tostring(self.generalindex)] or {}
	
	self.data = {
		token = {},
		section = 0
	}
	
	for k,v in pairs(_data.token) do
		self.data.token[tonumber(k)] = {}
		self.data.token[tonumber(k)].data = {}
		self.data.token[tonumber(k)].activeNum = 0

		for _k, _v in pairs(v) do
			self.data.token[tonumber(k)].data[tonumber(_k)] = _v

			if _v == 1 then
				self.data.token[tonumber(k)].activeNum = self.data.token[tonumber(k)].activeNum + 1
			end
		end

		if self.data.token[tonumber(k)].activeNum == self.MAX_NUM then
			self.data.section = self.data.section + 1
		end
	end
end

function token.refreshTokenNode(self)
	local _sid = self.slotdata[tostring(self.generalindex)].sid
	local _data = self.data.token[self.select[_sid]].data
	local _config =	self.tempTokenConfig[self.select[_sid]]
    local tokenConfig = gamedata.config.token

    printT(_data,"jkp-data")
	printT(_config,"jkp-config")

	for i,v in ipairs(_config) do
        print(v.icon, v.bg)
		setSpriteFrameByName(self.activeItems[i].i_icon, v.icon)
        setSpriteFrameByName(self.activeItems[i].i_quality, v.bg)
		self.activeItems[i].tokenStatusLab:setString("")
		self.activeItems[i].tokenNameLab:setString("")

		self:refreshSelectEffect(self.activeItems[i], self.select2[_sid], i)

		--激活
		if _data[i] == 1 then
			ui.removeGray("CCSprite", self.activeItems[i].i_icon)
			ui.removeGray("CCSprite", self.activeItems[i].i_quality)
            if self.select2[_sid] == i then
                ui.removeGray("CCControlButton", self.rootItems.activeBtn)
            end

			self.activeItems[i].activeEffect:setVisible(true)
			self.activeItems[i].addIcon:setVisible(false)
		--未激活
		elseif _data[i] == 0 then
			-- 有令
			if self.props[tostring(v.id)] > 0 then
				ui.removeGray("CCSprite", self.activeItems[i].i_icon)
				ui.removeGray("CCSprite", self.activeItems[i].i_quality)
                if self.select2[_sid] == i then
                    ui.removeGray("CCControlButton", self.rootItems.activeBtn)
                end

				self.activeItems[i].addIcon:setVisible(false)
			-- 没有令
			else
				ui.addGray("CCSprite", self.activeItems[i].i_icon)
				ui.addGray("CCSprite", self.activeItems[i].i_quality)
                if self.select2[_sid] == i then
                    ui.addGray("CCControlButton", self.rootItems.activeBtn)
                end

				self.activeItems[i].addIcon:setVisible(false)
			end

			self.activeItems[i].activeEffect:setVisible(false)
		else
			print("数据有问题啊")
		end
	end

    --设置激活按钮


end

function token.refreshSelectEffect(self, parent, index1, index2)
	parent.i_selectEffect:removeAllChildrenWithCleanup(true)

	if index1 == index2 then
		local _eCCB, eItem = CCBReaderLoad("UIEffect/zhenrongxuanzhong/zhenrongxuanzhong", nil, true, "zhenrongxuanzhong")
		_eCCB:setScale(1.1)
		parent.i_selectEffect:addChild(_eCCB)
	end
end

function token.refreshStatusNode(self)
	local _sid = self.slotdata[tostring(self.generalindex)].sid
	local _isActived = self.data.token[self.select[_sid]].data[self.select2[_sid]] == 1

	self:statusNodeIsShow(_isActived)
	self:setStatusNode(_isActived)
	self:setActiveNode(_isActived)
end

function token.statusNodeIsShow(self, isActived)
	self.rootItems.activeNode:setVisible(not isActived)
	self.rootItems.activedNode:setVisible(isActived)
end

function token.setStatusNode(self, isActived)
	local _sid = self.slotdata[tostring(self.generalindex)].sid
	local _name = ""
    local _suitName = self.tokenSuitConfig[tostring(self.select[_sid])]["1"].name

	if isActived then
		_name = "activedStatusLab"
        self.rootItems.activedTitleLab:setString(_suitName)
	else
		_name = "activeStatusLab"
        self.rootItems.activeTitleLab:setString(_suitName)
	end

	for i = 1, self.MAX_NUM do
		local _type = self.tokenSuitConfig[tostring(self.select[_sid])][tostring(i)].attribute_explain
		local _num = ""
		local _method = self.tokenSuitConfig[tostring(self.select[_sid])][tostring(i)].method
		local _value = self.tokenSuitConfig[tostring(self.select[_sid])][tostring(i)].value
		
		if _method == "percent" then
			_num = (_value * 100) .. "%"
		elseif _method == "value" then
			_num = _value
		end

		if i <= self.data.token[self.select[_sid]].activeNum then
			self.rootItems[_name..i]:setColor(ccc3(48, 249, 0))
		else
			self.rootItems[_name..i]:setColor(ccc3(192, 192, 192))
		end
		
		self.rootItems[_name..i]:setString(gameConfig.strings:tokenStatus(i, _type, _num))
	end
end

function token.setActiveNode(self, isActived)
	if not isActived then
		local _sid = self.slotdata[tostring(self.generalindex)].sid
		local _needLevel = self.tempTokenConfig[self.select[_sid]][self.select2[_sid]].limit_level
		local _cost = self.tempTokenConfig[self.select[_sid]][self.select2[_sid]].cost

		if GameScene.roleinfo.level >= _needLevel then
			ui.setLabelString(self.rootItems.needLevelLab, gameConfig.strings:tokenNeedLevel(GameScene.roleinfo.level, _needLevel), 13)
		else
			ui.setLabelString(self.rootItems.needLevelLab, gameConfig.strings:tokenNeedLevel(GameScene.roleinfo.level, _needLevel), 24)
		end

		ui.setNewIcon(self.rootItems, {cid = _cost.cid, num = self.props[tostring(_cost.cid)] .. "/" .. _cost.num})
        local _cb = function()
            ui.setPopwindowByCid(_cost.cid)
		end
		ui.commonBtn(self, self.rootItems, "i_button", _cb)
		
		if self.props[tostring(_cost.cid)] >= _cost.num then
			ui.setLabelString(self.rootItems.i_num, nil, 13)
		else
			ui.setLabelString(self.rootItems.i_num, nil, 24)
		end
	end
end

return tokenȀ  