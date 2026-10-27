local blackShopNew = {
	rootItems = nil,
    rootNode = nil,

    cellSize = {width = 1080, height = 290},
    listTableView = nil,
    touchPriority = -103,
    activityId = 18,
    isscrolltouched = false,
}

function blackShopNew.clear(self)
	gameTouch:UnrigistFunc("begin","blackShopNew")
    gameTouch:UnrigistFunc("end","blackShopNew")
    gameTimer:UnrigistTimeFunc("activity_blackshop")

    self.show = false
    self.listTableView = nil

    if self.rootNode then
        self.rootNode:removeAllChildrenWithCleanup(true)
        self.rootNode:removeFromParentAndCleanup(true)
        self.rootItems = nil
        self.rootNode = nil
    end
end

function blackShopNew.init(self, size)
	self.contentsize = size
    self.show = true
    
    self:initNode()
    -- self:initSpine()
    self:initConfig()
    self:initFixedString()
    self:initRefreshTime()
    self:initTouch()

    return self.rootNode
end

function blackShopNew.initNode(self)
	self.rootNode, self.rootItems = CCBReaderLoad("activityreward_new/yuanbaoshangdian", nil, true, "yuanbaoshangdian")
    self.rootItems.topnode:setPositionY(self.contentsize.y - 180)
    self.rootItems.listNode:setContentSize(CCSizeMake(gameConfig.originSize.width, self.contentsize.y - 520 - 392))
end

function blackShopNew.initSpine(self)
	local Gneral = CCSkeletonAnimation:create("mengpo/mengpo.json", "mengpo/mengpo.atlas", 2)
    Gneral:setAnimation("stand",true,0)
    Gneral:setScale(1.5)
    self.rootItems.generalNode:addChild(Gneral)
end

function blackShopNew.initConfig(self)
	self.refreshConfig = gamedata.config.blackmarket_refresh
	self.priceConfig = gamedata.config.buycount_price
	self.itemConfig = gamedata.config.blackmarket_items
end

function blackShopNew.initFixedString(self)
    -- ui.setLabelString(self.rootItems["desc4"], "当前拥有：", 14)
    -- ui.setLabelString(self.rootItems["desc5"], "下次刷新时间：", 14)
    ui.setLabelString(self.rootItems["desc6"], "消耗：", 14)
end

function blackShopNew.initRefreshTime(self)
	local _nowTime = os.date("*t", gamedata:time())
	local _refreshTimeString = "00:00"

	local _refreshArray = {}

	for k,v in pairs(self.refreshConfig) do
        -- print("refreshtimestring==",v.hour)
        table.insert(_refreshArray, tonumber(v.hour))
    end

    local _sortTable = function( a, b )
        return a < b
    end

    table.sort(_refreshArray, _sortTable)

    for i,v in ipairs(_refreshArray) do
        if v > _nowTime.hour then
            _refreshTimeString = v.."点刷新"
            break
        elseif v == 0 and _nowTime.hour >= 18 then
            _refreshTimeString = v.."点刷新"
            break
        end
    end

    -- ui.setLabelString(self.rootItems["updateTime"], _refreshTimeString, 136)
    self.rootItems["updateTime"]:setString(_refreshTimeString)
end

function blackShopNew.initTouch(self)
    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin", "blackShopNew", touchbegin)

    local function touchend(pos)
        if self.rootItems.listNode and ui.isTouched(self.rootItems.listNode, pos.x, pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end", "blackShopNew", touchend)
end

function blackShopNew.reloaddata(self, data)
    if not self.show then return end
	self:updatetimeFunc()
	self:refreshString(data)
	self:setData(data)
	self:refreshResetButton()
	self:refreshList()
end

function blackShopNew.updatetimeFunc(self)
    local _refreshArr = {}
    local _nowTime = os.date("*t", gamedata:time())
    local _addTime = 0

    for k,v in pairs(self.refreshConfig) do
        if v.hour == 0 then
            v.hour = 24
        end

        table.insert(_refreshArr,tonumber(v.hour))
    end

    local _sortTable = function(a, b)
        return a < b
    end

    table.sort(_refreshArr, _sortTable)

    for i,v in ipairs(_refreshArr) do
        if _nowTime.hour < v then
            _addTime = v
            break
        end
    end

    local _remainTime = _addTime * 3600 - _nowTime.hour * 3600 - _nowTime.min * 60 - _nowTime.sec

    gameTimer:rigistTime("activity_blackshop", _remainTime)
    gameTimer:rigistTimeFunc("activity_blackshop",function()
        if gameTimer.times["activity_blackshop"] >= 0 then
            
        end
        if gameTimer.times["activity_blackshop"] == 0 then
            UIRequest({type = 3630, update = true})
            gameTimer:UnrigistTimeFunc("activity_blackshop")
        end
    end)
end

function blackShopNew.refreshString(self,data)
    -- ui.setLabelString(self.rootItems["gold_num"], GameScene.roleinfo.gold, 86)
    if data and data.gold then
        self.rootItems["gold_num"]:setString(data.gold)
    else
        self.rootItems["gold_num"]:setString(GameScene.roleinfo.gold)
    end
    
end

function blackShopNew.setData(self, data)
	self.data = data.data.itemsdata
    self.heishiSton = data.heishiSton
    self.generalTab = data.onGenerals
    self.resetNum = data.data.resetnum
end

function blackShopNew.refreshResetButton(self)
	self:refreshResetBtnStatus()
	self:refreshResetBtn()
end

function blackShopNew.refreshResetBtnStatus(self)
	if self.resetNum > 59 then
        self.resetNum = 59
    end

    -- self.rootItems["resetGoldNode"]:setVisible(true)

    if self.heishiSton > 0 then
        self.rootItems.goldsprite:setVisible(false)
        self.rootItems.heishisprite:setVisible(true)
        ui.setLabelString(self.rootItems.resetgold, self.heishiSton, 14)
    else
        self.rootItems.goldsprite:setVisible(true)
        self.rootItems.heishisprite:setVisible(false)
        ui.setLabelString(self.rootItems.resetgold, self.priceConfig[tostring(self.resetNum + 1)].blackmarket_refreshgold, 14)
    end

    ui.setLabelString(self.rootItems.resettext, gameConfig.strings:string_common("buttontext", "shuaxin"), 19)
end

function blackShopNew.refreshResetBtn(self)
	local _cb = function()
		if GameScene.layers["activity"].module.isContentScroll then return end
        local _refresh = self:refreshJudge()

        if not _refresh then
            runGamePrompt({msg = "马上就要刷新了，请稍等一会儿"})
            return
        end

        if self.heishiSton <= 0 then
            local _spendNum = self.priceConfig[tostring(self.resetNum + 1)].blackmarket_refreshgold
            UIRequest({type = 3632, spendnum = _spendNum})
        else
            UIRequest({type = 3632, spendnum = 0})
        end
	end

	ui.commonBtn(self, self.rootItems, "resetBtn", _cb)
end

function blackShopNew.refreshJudge(self)
    local _nowTime = os.date("*t", gamedata:time())
    local _refreshStatus = true

    for k,v in pairs(self.refreshConfig) do
        if (_nowTime.hour+1) == v.hour and _nowTime.min >= 57 then
            _refreshStatus = false
            break
        elseif v.hour == 0 and _nowTime.hour == 23  and _nowTime.min >= 57 then
            _refreshStatus = false
            break
        end
    end

    return _refreshStatus
end

function blackShopNew.refreshList(self)
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
                _cellCCB, _ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_yuanbaoshangdian", nil, true, "cell_yuanbaoshangdian")
                _celldict[a2] = {cellCCB = _cellCCB, ccbDocumentControler = _ccbDocumentControler }
            else
                _first = false
                _cellCCB = _celldict[a2].cellCCB
                _ccbDocumentControler = _celldict[a2].ccbDocumentControler
            end

            self:setCell(_ccbDocumentControler, nil, a1 + 1)

            _cellCCB:setPosition(0, 0)

            if _first then
                a2:addChild(_cellCCB)
            end

            _r = a2
        elseif fn == "numberOfCells" then
            _r = table.getTableLength(self.data) / 3
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end

        return _r
    end)

    self.rootItems["listNode"]:removeAllChildrenWithCleanup(true)
    self.listTableView = ui.createLuaTableView({
        handle = _listHandle,
        viewwidth = self.rootItems["listNode"]:getContentSize().width,
        viewheight = self.rootItems["listNode"]:getContentSize().height,
        dire = 1
    })
    self.rootItems["listNode"]:addChild(self.listTableView)
    self.listTableView:setTouchPriority(self.touchPriority - 1)
end

function blackShopNew.setCell(self, item, data, index)
	for i = 1, 3 do
		local _key = ui.getKey(i)
		local _config = self:setConfig((index - 1) * 3 + i)

		if not _config then
	        return
	    end

	    local _spendData = ui.getIDandNUMs(_config.consume) 
    	local _goodData = ui.getIDandNUMs(_config.good)

    	self:setCellIcon(item, _key, _goodData, i)
    	self:setCellHotNode(item, _config, i)
    	self:setCellBattleNode(item, _goodData, i)
    	self:setCellString(item, _spendData, i)
    	self:setCellBuyBtn(item, _config, _spendData, _goodData, i, (index - 1) * 3 + i)
	end
end

function blackShopNew.setConfig(self, id)
	return gamedata.config.blackmarket_items[tostring(self.data[tostring(id)].id)]
end

function blackShopNew.setCellIcon(self, item, key, goodData, index)
	ui.setNewIconName(item, {cid = goodData[1].cid, num = goodData[1].num}, index - 1)

	local _cb = function()
		if gameTouch.ismove then return end
        ui.setPopwindowByCid(goodData[1].cid)
	end

	ui.commonBtn(self, item, "i_button"..key, _cb,self.touchPriority - 10,false)
end

function blackShopNew.setCellHotNode(self, item, data, index)
	if data.recommend == 1 then -- 显示推荐
        item["hotnode"..index]:setVisible(true)
    else
        item["hotnode"..index]:setVisible(false)
    end 
end

function blackShopNew.setCellBattleNode(self, item, goodData, index)
	item["battleNode"..index]:setVisible(false) 
    local _generalStatus = ui.IDconfig(goodData[1].cid) or 0
    local _generalFrangment = gamedata.config.general_fragment
    if _generalStatus.staffType == "general" then
        for k,v in pairs(self.generalTab) do
            if goodData[1].cid == v then
                -- 显示上阵
                if item["hotnode"..index]:isVisible() then
                    item["hotnode"..index]:setVisible(false)
                end
                item["battleNode"..index]:setVisible(true)
            end
        end
    elseif _generalStatus.staffType == "general_fragment" then
        for k,v in pairs(self.generalTab) do
            if _generalFrangment[tostring(goodData[1].cid)] and _generalFrangment[tostring(goodData[1].cid)].general == v then
                -- 显示上阵
                if item["hotnode"..index]:isVisible() then
                    item["hotnode"..index]:setVisible(false)
                end
                item["battleNode"..index]:setVisible(true)
            end
        end
    end
end

function blackShopNew.setCellString(self, item, spendData, index)
	-- ui.setLabelString(item["buyNumText"..index],nil,14)
    -- ui.setLabelString(item["buyNumLabel"..index],configdata.limit-self.data[tostring(id)].num,14)
    ui.setLabelString(item["gold_num"..index], spendData[1]["num"],14)

    -- ui.setLabelString(item["buttontext"..index],gameConfig.strings:string_common("buttontext","goumai"),18)
end

function blackShopNew.setCellBuyBtn(self, item, config, spendData, goodData, index, index2)
	if self.data[tostring(index2)].num < config.limit then
        -- print("canbeo===")
        item["soldoutNode"..index]:setVisible(false)

        item["button"..index]:setTouchPriority(self.touchPriority-5)
        item["button"..index]:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            gameTouch:clickprofbytime(1)
            local _num = 1

            if spendData[1].cid and tonumber(spendData[1].cid) == 1001 then
                if tonumber(spendData[1].num) > 500 and tonumber(spendData[1].num) < GameScene.roleinfo.gold then
                    function shopExchangeRequest(num)
                        UIRequest({type = 3631, id = index2,goodid = self.data[tostring(index2)].id,num = num})            
                    end
                    local exchangeNum = config.limit-self.data[tostring(index2)].num
                    gameWindows:openWindow("shopExchange",{cid = goodData[1].cid,num = goodData[1].num,cost = spendData,exchangeNum = exchangeNum, ccbtype = 2},shopExchangeRequest)
                else
                    UIRequest({type = 3631, id = index2,goodid = self.data[tostring(index2)].id,num = _num})
                end
            else
                UIRequest({type = 3631, id = index2,goodid = self.data[tostring(index2)].id,num = _num})
            end
        end, CCControlEventTouchUpInside)
    else
        item["soldoutNode"..index]:setVisible(true)

        item["button"..index]:setTouchPriority(self.touchPriority-5)
        item["button"..index]:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            runGamePrompt({msg = gameConfig.strings:string_common("buttontext","yigoumai")})
        end, CCControlEventTouchUpInside)
    end
end

return blackShopNew(7  