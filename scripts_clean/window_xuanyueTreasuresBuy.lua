--
-- Author: songyibo
-- Date: 2019-08-20 15:10:57
--

local xuanyueTreasuresBuy = {
    rootNode = nil,
    rootItems = nil,
}

function xuanyueTreasuresBuy.open(self,touchPriority,data,callback)
    self.touchPriority = touchPriority
    self.id = data.id

    self.rootNode,self.rootItems = CCBReaderLoad("xuanyuemibao/tc_mibaobuy", nil, true, "tc_mibaobuy")

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("xuanyueTreasuresBuy")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems["buyBtn"]:setSwallowsTouch(true)
    self.rootItems["buyBtn"]:setTouchPriority(self.touchPriority)
    self.rootItems["buyBtn"]:addHandleOfControlEvent(function()
        print("购买")

        local id = gamedata.config:getConfigByName("global_kv").xuanyue_gaoji_num.value
        if gamedata.config:getConfigByName("recharge")[tostring(id)] then
            if RechargeLimit(gamedata.config:getConfigByName("recharge")[tostring(id)].rmb) then
                return
            end
        end
        
        if sdk:isValid() then
            UIRequest({type = 115,cid = tonumber(gamedata.config:getConfigByName("global_kv").xuanyue_gaoji_num.value),bagid=1})
            gameWindows:closeWindowDirect("xuanyueTreasuresBuy")
        else
            -- runGamePrompt({msg = "未接入充值渠道"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","change_qudao")})
        end

        
    end, CCControlEventTouchUpInside)
    

    self:initFixedString()
    self:reload()

    return self.rootNode
end

function xuanyueTreasuresBuy.reload(self)

	--本次
	local config = gamedata.config:getConfigByName("xuanyue_reward")
	local reward2 = {}

    for i=1,table.getTableLength(config) do
        if i <= self.id then
            for i2,v2 in ipairs(ui.getIDandNUMs(config[tostring(i)].reward2)) do
                if not reward2[v2.cid] then
                    reward2[v2.cid] = v2.num
                else
                    reward2[v2.cid] = reward2[v2.cid] + v2.num
                end
            end
        end
    end

    self.reward2 = {}
    for k,v in pairs(reward2) do
        table.insert(self.reward2,{cid = k,num = v})
    end

    self.rootItems.curMore:setVisible(#self.reward2 > 5)
    self:createList(self.rootItems.curNode,self.reward2)
	-- local pos = ui.getPosCentered(180,30,table.getTableLength(reward2))

 --    local i = 1
	-- for k,v in pairs(reward2) do
	-- 	local node,items = CCBReaderLoad("icons/new_icon", nil, true, "new_icon")
	-- 	node:setPosition(pos[i],0)
	-- 	self.rootItems.curNode:addChild(node)

 --        ui.setNewIcon(items, {cid = k, num = v})

 --        items["i_button"]:setTouchPriority(self.touchPriority)
 --        items["i_button"]:addHandleOfControlEvent(function()
 --            ui.setPopwindowByCid(v)
 --        end, CCControlEventTouchUpInside)
 --        i = i + 1
	-- end

	--全部
	local reward1 = {}
	for k,v in pairs(gamedata.config:getConfigByName("xuanyue_reward")) do
		for i,v2 in ipairs(ui.getIDandNUMs(v.reward2)) do
			if not reward1[v2.cid] then
				reward1[v2.cid] = v2.num
			else
				reward1[v2.cid] = reward1[v2.cid] + v2.num
			end
		end
	end

    self.reward1 = {}
    for k,v in pairs(reward1) do
        table.insert(self.reward1,{cid = k,num = v})
    end

    self.rootItems.totalMore:setVisible(#self.reward1 > 5)
    self:createList(self.rootItems.totalNode,self.reward1)
	-- local pos = ui.getPosCentered(180,30,table.getTableLength(reward1))


	-- local i = 1
	-- for k,v in pairs(reward1) do
	-- 	local node,items = CCBReaderLoad("icons/new_icon", nil, true, "new_icon")
	-- 	node:setPosition(pos[i],0)
	-- 	self.rootItems.totalNode:addChild(node)
 --        ui.setNewIcon(items, {cid = k, num = v})
 --        items["i_button"]:setTouchPriority(self.touchPriority)
 --        items["i_button"]:addHandleOfControlEvent(function()
 --            ui.setPopwindowByCid(v)
 --        end, CCControlEventTouchUpInside)
 --        i = i + 1
	-- end


end


function xuanyueTreasuresBuy.createList(self,rootNode,data)

    local offy = 30
    local num = math.min(#data,5)
    local width = num * (180 + offy)
    rootNode:setContentSize(CCSizeMake(width,180))



    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(180 + offy, 180)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("icons/new_icon", nil, true, "new_icon")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local celldata = data[a1+1]

            ui.setNewIcon(ccbDocumentControler, {cid = celldata.cid, num = celldata.num})
            ccbDocumentControler["i_button"]:setTouchPriority(self.touchPriority)
            ccbDocumentControler["i_button"]:addHandleOfControlEvent(function()
                if gameTouch.isScrollling then return end
                ui.setPopwindowByCid(celldata.cid)
            end, CCControlEventTouchUpInside)

            cellCCB:setPosition((180 + offy)/2, 90)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(data)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            ----gameTouch.isScrollling = true
        end
        return r
    end)

    local ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = rootNode:getContentSize().width,
        viewheight = rootNode:getContentSize().height,
        dire = 0
    })
    rootNode:addChild(ListTableView)
    ListTableView:setTouchPriority(self.touchPriority)
end

function xuanyueTreasuresBuy.initFixedString(self)
	self.rootItems.fixed1:setString(gameConfig.strings:string_common("xuanyueTreasures",10))
	-- self.rootItems.fixed2:setString(gameConfig.strings:string_common("xuanyueTreasures",11))


    local id = gamedata.config:getConfigByName("global_kv").xuanyue_gaoji_num.value

    if gamedata.config:getConfigByName("recharge")[tostring(id)] then
        ui.setLabelString(self.rootItems.pricelab,"￥"..gamedata.config:getConfigByName("recharge")[tostring(id)].rmb,19)
    end

end

function xuanyueTreasuresBuy.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end	
end
return xuanyueTreasuresBuy