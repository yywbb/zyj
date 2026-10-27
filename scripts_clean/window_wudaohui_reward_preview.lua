local wudaohuiRewardPreview = {
	cellSize = {width = 850, height = 300},
	rootNode = nil,
    rootItems = nil,

    listTableView = nil,
}

function wudaohuiRewardPreview.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.listTableView = nil
end

function wudaohuiRewardPreview.open(self, touchPriority, data, callback)
    if GameScene.roleinfo and next(GameScene.roleinfo) and GameScene.roleinfo.id then
        CCUserDefault:sharedUserDefault():setBoolForKey("wudaohuiRewardPreview"..GameScene.roleinfo.id, false)
    end
	self:initNode(touchPriority, callback)
	self:initConfig()
	self:initData(data)
    self:initFixedString()
    self:initEventBtn()
    self:createList()

    return self.rootNode
end

function wudaohuiRewardPreview.initNode(self, touchPriority, callback)
	self.rootNode, self.rootItems = CCBReaderLoad("wudaohui/tc_wudaohuigongxihuode", nil, true, "tc_wudaohuigongxihuode")
	self.touchPriority = touchPriority
	self.callback = callback
end

function wudaohuiRewardPreview.initConfig(self)
	self.xiandouShopConfig = table.copy(gamedata.config.xiandou_shop)
end

function wudaohuiRewardPreview.initData(self)
	self.data = {}

	for i = 1, table.getTableLength(self.xiandouShopConfig) do
		for ii = 1, table.getTableLength(self.xiandouShopConfig[tostring(i)]) do
			if GameScene.roleinfo.level >= self.xiandouShopConfig[tostring(i)][tostring(ii)].level_min and 
			   GameScene.roleinfo.level <= self.xiandouShopConfig[tostring(i)][tostring(ii)].level_max then
			   	local _reward = ui.getIDandNUMs(self.xiandouShopConfig[tostring(i)][tostring(ii)].reward)

			   	table.insert(self.data, _reward[1])
                self.data[#self.data].ranking = self.xiandouShopConfig[tostring(i)][tostring(ii)].ranking
			end
		end
	end
    
    local _sortTable = function(left, right)
        if left.ranking > right.ranking then
            return left.cid > right.cid
        elseif left.ranking == right.ranking then
            return left.cid > right.cid
        else
            return left.cid > right.cid
        end 
    end

    table.sort(self.data, _sortTable)
end

function wudaohuiRewardPreview.initFixedString(self)
	self.rootItems["descTxt"]:setString(gameConfig.strings:string_common("wudaohui", 53))
end

function wudaohuiRewardPreview.initEventBtn(self)
	self:initCloseBtn()
end

function wudaohuiRewardPreview.initCloseBtn(self)
	local _cb = function()
		gameWindows:closeWindow("wudaohuiRewardPreview")
	end

	ui.commonBtn(self, self.rootItems, "closeBtn", _cb)
end

function wudaohuiRewardPreview.createList(self)
	local _celldict = {}
    local _listHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local _r

        if fn == "cellSize" then
            _r = CCSizeMake(self.cellSize.width, self.cellSize.height)
        elseif fn == "cellAtIndex" then
            local _cellCCB, _ccbDocumentControler = {},{}
            local _first = true

            if not a2 then
                a2 = CCTableViewCell:create()
                for i = 1, 4 do
                	_cellCCB[i], _ccbDocumentControler[i] = CCBReaderLoad("icons/new_iconName2.ccbi", nil, true, "new_iconName2")
                end

                _celldict[a2] = {cellCCB = _cellCCB, ccbDocumentControler = _ccbDocumentControler }
            else
                _first = false
                _cellCCB = _celldict[a2].cellCCB
                _ccbDocumentControler = _celldict[a2].ccbDocumentControler
            end
            
            for i = 1, 4 do
            	local _data = self.data[4*(a1) + i]

            	if _data then
            		_cellCCB[i]:setVisible(true)
            		ui.setNewIconName(_ccbDocumentControler[i], _data)
            	else
            		_cellCCB[i]:setVisible(false)
            	end

	            _cellCCB[i]:setPosition(200*(i-0.5)+25, 200)

	            if _first then
	                a2:addChild(_cellCCB[i])
	            end
	        end

            _r = a2
        elseif fn == "numberOfCells" then
            _r = math.ceil(table.getTableLength(self.data) / 4)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end

        return _r
    end)

    self.listTableView = ui.createLuaTableView({
        handle = _listHandle,
        viewwidth = self.rootItems.listScroll:getContentSize().width,
        viewheight = self.rootItems.listScroll:getContentSize().height,
        dire = 1
    })
    self.listTableView:setTouchPriority(self.touchPriority)
    self.rootItems.listScroll:addChild(self.listTableView)
end

return wudaohuiRewardPreview