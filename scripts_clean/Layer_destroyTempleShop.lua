--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 16/3/26
-- Time: 上午午14:39
-- To change this template use File | Settings | File Templates.
--

local destroyTempleShop = {
	normalCellSize = {x=1080, y=245},

	rootNode = nil,
	rootItems = nil,

	pageconfig = {"prop", "reward"},
	pagename = {"商 品", "奖 励"},
	selectpage = "prop",

	commodityListTableView = nil,
    rewardListTableView = nil,
	isscrolltouched = false,
	commodityTab = {},
	rewardTab = {},

    mieshendianshop = {},

}

function destroyTempleShop.init(self,parent,toppos)
	print("进入灭神殿商店")
    self.rootNode,self.rootItems = CCBReaderLoad("zhuxiantai2/zhuxiantai2_shop", nil, true, "up")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)	

    self.rootItems.topnode:setPositionY(toppos)

    self.rootItems.listnode_prop:setContentSize(CCSizeMake(gameConfig.originSize.width, toppos-gameConfig.maiscenebottomheight-gameConfig.labelnodeheight - 260))-- -160-180
	self.rootItems.listnode_reward:setContentSize(CCSizeMake(gameConfig.originSize.width, toppos-gameConfig.maiscenebottomheight-gameConfig.labelnodeheight - 260))-- -160-180

    self.rootItems.backBtn:addHandleOfControlEvent(function()
    	print("回到灭神殿")
        GameScene:shiftLayer(GameScene.priorLayer,"down")

    end, CCControlEventTouchUpInside)
    self.rootItems.backBtn:setSwallowsTouch(true)
    self.rootItems.backBtn:setTouchPriority(-103)

    ui.setLabelString(self.rootItems.docLab, nil, 21)

    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","destroyTempleShop",touchbegin)
    local function touchend(pos)
        if self.rootItems.listnode_prop and ui.isTouched(self.rootItems.listnode_prop, pos.x, pos.y) then
            self.isscrolltouched = true
        elseif self.rootItems.listnode_reward and ui.isTouched(self.rootItems.listnode_reward, pos.x, pos.y) then
        	self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","destroyTempleShop",touchend)

    -- printT(gamedata.config.mieshendian_shop)
    for k,v in pairs(gamedata.config.mieshendian_shop) do
    	if v.paging == 1 then
    		table.insert(self.commodityTab, v)
    	elseif v.paging == 2 then
    		table.insert(self.rewardTab, v)
    	end
    end

    local sortfunc = function (a,b)
        return a.id < b.id
    end
    table.sort(self.commodityTab,sortfunc)
    table.sort(self.rewardTab,sortfunc)

    --
    UIRequest({type = 3627})

end

function destroyTempleShop.ReloadData(self,data)
	-- 请求数据
    self.mieshendianshop = data or {}

    ui.setLabelString(self.rootItems.integralLab, self.mieshendianshop.points or 0, 23)
    --
	self:shiftPage(self.selectpage)
	-- self:upMaterialList()  -- 数据返回创建scrollView
end

function destroyTempleShop.shiftPage(self, type)
	if type then
		self.selectpage = type
				
	end
	for k,v in pairs(self.pageconfig) do
		if v == type then
			self.rootItems["listnode_"..v]:setVisible(true)
            self.rootItems["listnode_"..v]:setPositionX(0)
        else
        	self.rootItems["listnode_"..v]:setVisible(false)
            self.rootItems["listnode_"..v]:setPositionX(9999)
		end
	end

	if self.selectpage == "reward" then
		-- self:onRewardList(self.rewardTab, "reward")
		if not self.rewardListTableView then
			self:onRewardList()
		else
            self.rewardListTableView:reloadData() -- 刷新列表
            print("is ListTableView")			
		end
	else
		print("进入奖励")
		-- self:onCommodityList(self.commodityTab, "commodity")
		if not self.commodityListTableView then
			self:onCommodityList()
		else
            self.commodityListTableView:reloadData() -- 刷新列表
            print("is ListTableView")			
		end		
	end

end


function destroyTempleShop.onCommodityList(self, data, _type)
	-- 商品list
	print("商品列表")
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("zhuxiantai2/cell_shop", nil, true, "cell_destroyTempleShop")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

			self:setCell(ccbDocumentControler, self.commodityTab[a1+1], a1+1, "commodity")
            cellCCB:setPosition(self.normalCellSize.x/2, 14)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
        	-- print("self.treasuresStatus ====="..table.getTableLength(self.treasuresStatus))
            r = table.getTableLength(self.commodityTab)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            ----gameTouch.isScrollling = true
        end
        return r
    end)

    self.commodityListTableView = ui.createLuaTableView({
        handle = ListHandle,
		viewwidth = self.rootItems.listnode_prop:getContentSize().width,
		viewheight = self.rootItems.listnode_prop:getContentSize().height,
        dire = 1
    })


    self.rootItems.listnode_prop:addChild(self.commodityListTableView)

    
    self.commodityListTableView:setTouchPriority(-101)	
end

function destroyTempleShop.onRewardList(self)
	-- 商品list
	print("奖励列表")
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("zhuxiantai2/cell_shop", nil, true, "cell_destroyTempleShop")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

			self:setCell(ccbDocumentControler, self.rewardTab[a1+1], a1+1, "reward")
            cellCCB:setPosition(self.normalCellSize.x/2, 14)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
        	-- print("self.treasuresStatus ====="..table.getTableLength(self.treasuresStatus))
            r = table.getTableLength(self.rewardTab)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            ----gameTouch.isScrollling = true
        end
        return r
    end)

    self.rewardListTableView = ui.createLuaTableView({
        handle = ListHandle,
		viewwidth = self.rootItems.listnode_reward:getContentSize().width,
		viewheight = self.rootItems.listnode_reward:getContentSize().height,
        dire = 1
    })

    self.rootItems.listnode_reward:addChild(self.rewardListTableView)

    
    self.rewardListTableView:setTouchPriority(-101)	
end

function destroyTempleShop.setCell(self, item, cellData, index, _type)

	local needItem, needNum = ui.getIDandNUM(cellData.consume)
	local itemCid, itemNum = ui.getIDandNUM(cellData.good)

    local hascount = 0
    local needstar = 0
	if _type == "commodity" then
		item.dayLab1:setVisible(true)
		item.dayLab2:setVisible(false)
		item.needStars:setVisible(false)
        hascount = cellData.limit-(self.mieshendianshop.items[tostring(cellData.id)] and self.mieshendianshop.items[tostring(cellData.id)].count or 0)
		ui.setLabelString(item.exchangeNum, hascount, 4) -- 兑换次数
		
	elseif _type == "reward" then
		item.dayLab1:setVisible(false)
		item.dayLab2:setVisible(true)
		item.needStars:setVisible(true)
        --hascount = cellData.total-(self.mieshendianshop.items[tostring(cellData.id)] and self.mieshendianshop.items[tostring(cellData.id)].count or 0)
        --
        if self.mieshendianshop.items[tostring(cellData.id)] and self.mieshendianshop.items[tostring(cellData.id)].count and self.mieshendianshop.items[tostring(cellData.id)].count >= 2 then
            hascount = 0
        else
            hascount = 1
        end
        --
        ui.setLabelString(item.needStars, "星数达到" .. cellData.rank, 21)
        ui.setLabelString(item.exchangeNum, hascount, 4) -- 兑换次数
        needstar = cellData.rank

    end
	local itemTab = ui.IDconfig(itemCid) -- 取配置表  里面包含名称 id 等
	ui.setNewIcon(item, {cid = itemCid, num = itemNum,})
    item.i_button:addHandleOfControlEvent(function()
        ui.setPopwindowByCid(itemCid)
    end, CCControlEventTouchUpInside)
    item.i_button:setSwallowsTouch(true)
    item.i_button:setTouchPriority(-103)
	-- printT(itemTab)
    local xpoints = 0
    local xgold = 0
    if needItem and tonumber(needItem) == 1004 then
        item.integral:setVisible(true) -- 显示积分还是元宝
        item.gold:setVisible(false)
        xpoints = needNum+0
    else
        item.integral:setVisible(false) -- 显示积分还是元宝
        item.gold:setVisible(true)
        xgold = needNum+0
    end
	ui.setLabelString(item.name, itemTab.name, 9) -- 道具名称
	ui.setLabelString(item.integralLab, needNum, 22) -- 需要的积分
	ui.setLabelString(item.buyLab, nil, 18) -- 
    item.buyBtn:addHandleOfControlEvent(function()
    	print("购买物品")
        gameTouch:clickprofbytime(0.5)
    	if not self.isscrolltouched then return end
        if hascount < 1 then
            runGamePrompt({msg = _type == "reward" and "已兑换过" or "兑换次数已用完" })
        elseif needstar > self.mieshendianshop.maxstar then
            runGamePrompt({msg = "星数未达条件" })
        elseif xpoints > self.mieshendianshop.points then
            runGamePrompt({msg = "积分不足" })
        else
            UIRequest({type = 3628, id = cellData.id, xgold = xgold})
        end
    end, CCControlEventTouchUpInside)
    item.buyBtn:setSwallowsTouch(true)
    item.buyBtn:setTouchPriority(-103)

    if _type == "reward" and hascount < 1 then
        ui.setLabelString(item.buyLab, "已购买", 18)
    else
        ui.setLabelString(item.buyLab, "购 买", 18)
    end

    if hascount < 1 then
        ui.addGray("CCControlButton",item.buyBtn)
        ui.addGray("CCLabelTTF",item.buyLab)
    elseif needstar > self.mieshendianshop.maxstar then
        ui.addGray("CCControlButton",item.buyBtn)
        ui.addGray("CCLabelTTF",item.buyLab)
    elseif xpoints > self.mieshendianshop.points then
        ui.addGray("CCControlButton",item.buyBtn)
        ui.addGray("CCLabelTTF",item.buyLab)
    else
        ui.removeGray("CCControlButton",item.buyBtn)
        ui.removeGray("CCLabelTTF",item.buyLab)
    end

end

function destroyTempleShop.clear(self)
    if self.rootNode then
        self.commodityListTableView = nil
        self.rewardListTableView = nil
        self.selectpage = "prop"
        self.rootNode:removeAllChildrenWithCleanup(true)
        self.rootNode:removeFromParentAndCleanup(true)
        self.rootNode = nil
        self.rootItems = nil
		self.commodityTab = {}
		self.rewardTab = {}
        self.mieshendianshop = {}
        gameTouch:UnrigistFunc("begin","destroyTempleShop")
        gameTouch:UnrigistFunc("end","destroyTempleShop")
    end
	-- self.show = false
end

function destroyTempleShop.UIUpdateData(self, isreset)
    if isreset then
        UIRequest({type = 3627})
    end
end

return destroyTempleShop
