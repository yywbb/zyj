--
-- Author: songyibo
-- Date: 2019-08-28 16:12:33
--

local vipBuy = {
    rootNode = nil,
    rootItems = nil,
    normalCellSize = {x = 940,y = 200},
    ListTableView = nil,
}

function vipBuy.open(self,touchPriority,data,callback)
    self.touchPriority = touchPriority

    self.rootNode,self.rootItems = CCBReaderLoad("activityreward_new/tc_vipfuli", nil, true, "tc_vipfuli")

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindowDirect("vipExchangeBuy")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self:initFixedString()

    self:makeConfig()

    self:reload(data)
    return self.rootNode
end

function vipBuy.makeConfig(self)
	local vip = tonumber(GameScene.roleinfo.vip)
    if vip < 1 then vip = 1 end

    self.vipconfig = {}
    self.realconfig = {}
    local config = gamedata.config.vip_welfare[tostring(vip)]
    for k,v in pairs(config) do
    	table.insert(self.vipconfig,v)
    end
    table.sort(self.vipconfig,function ( a,b)
        return a.battle_lv < b.battle_lv
    end)

    for i,v in ipairs(self.vipconfig) do
    	v.id = i
    	if v.limit == 1 then
    		table.insert(self.realconfig,v.id)
    	end
    end
end

function vipBuy.reload(self,data)

	if data then
		self.status = data.status
	end
	
    if self.ListTableView then
        self.ListTableView:reloadData()
    else
        self:createList()
    end
end

function vipBuy.setCell(self,item,index)
	print("index",index)
	local data
	local idnums

	local realIndex = self.realconfig[index]
	data = self.vipconfig[realIndex]
	idnums = ui.getIDandNUMs(data.pay)

	for i=1,3 do
		item["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
			if gameTouch.isScrollling then return end
            if idnums[i] then
                ui.setPopwindowByCid(idnums[i].cid)
            end
        end, CCControlEventTouchUpInside)
        item["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(self.touchPriority)  
              
        if not idnums[i] then
            item["reward"..i]:setVisible(false)
        else
            item["reward"..i]:setVisible(true)
            ui.setNewIcon(item,{cid = idnums[i].cid, num = idnums[i].num},i-1)
        end
	end

	local str = ""
	if realIndex == 1 then
		str = "1-"..data.battle_lv.."级"
	else
		str = (self.vipconfig[realIndex - 1].battle_lv + 1).."-"..data.battle_lv.."级"
	end
	item.desc1:setString(str)

	ui.setLabelString(item.doLab,"购 买",19)

	local need = ui.getIDandNUMs(data.discount)[1] or {}
	item.price:setString(need.num or 0)

	if GameScene.roleinfo.gold < need.num then
		item.price:setColor(ccc3(255,0,0))
	else
		item.price:setColor(ccc3(134,83,32))
	end

	if self.status == 1 then
		ui.addGray("CCControlButton",item["doButton"])
	elseif GameScene.roleinfo.level < (self.vipconfig[realIndex - 1].battle_lv + 1) then
		ui.addGray("CCControlButton",item["doButton"])
	else
		ui.removeGray("CCControlButton",item["doButton"])
	end

	item["doButton"]:addHandleOfControlEvent(function()
		if gameTouch.isScrollling then return end
        if self.status == 1 then
			runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",10)})
		elseif GameScene.roleinfo.level < (self.vipconfig[realIndex - 1].battle_lv + 1) then
			runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",28)})
        elseif GameScene.roleinfo.gold < need.num then
            shortGold()
		else
			UIRequest({type = 4611, isfree = 0, need = need,battle_lv = data.battle_lv})
		end
    end, CCControlEventTouchUpInside)
    item["doButton"]:setTouchPriority(self.touchPriority) 

	
end

function vipBuy.createList(self)
    print("createList")
    local celldict = {}
    local unrecycleCell = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_viplibao", nil, true, "cell_viplibao")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCell(ccbDocumentControler, a1+1)

            cellCCB:setPosition(self.normalCellSize.x/2, 0)
            if first then
                a2:addChild(cellCCB)
            end
            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.realconfig)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listNode:getContentSize().width,
        viewheight = self.rootItems.listNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.listNode:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(self.touchPriority)
end

function vipBuy.initFixedString(self)
	
end

function vipBuy.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.ListTableView = nil
    if self.callback then
        self.callback()
    end	
end
return vipBuy