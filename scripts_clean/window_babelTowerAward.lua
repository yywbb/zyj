--
-- Author: songyibo
-- Date: 2019-03-21 13:54:56
--
local babelTowerAward = {
    rootNode = nil,
    rootItems = nil,
    normalCellSize = {x = 880,y = 230},
    ListTableView = nil
}

function babelTowerAward.open(self,touchPriority,data,callback)
    self.touchPriority = touchPriority

    self.rootNode,self.rootItems = CCBReaderLoad("tongtianta/tc_sanxingjiangli", nil, true, "tc_sanxingjiangli")

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("babelTowerAward")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    
    self:reload(data)
    self:initFixedString()
    return self.rootNode
end

function babelTowerAward.reload(self,data)
	printT(data,"babelTowerAward")
    local awardStatus = {}
    if data then
        for i=1,6 do
            if data["awardStatus"..i] == 1 then
                table.insert(awardStatus,{id = i,status = data["awardStatus"..i] or 0})
            end
        end

        for i=1,6 do
            if data["awardStatus"..i] == 0 then
                table.insert(awardStatus,{id = i,status = data["awardStatus"..i] or 0})
            end
        end

        for i=1,6 do
            if data["awardStatus"..i] == 2 then
                table.insert(awardStatus,{id = i,status = data["awardStatus"..i] or 0})
            end
        end
    end
	self.data = awardStatus
	-- table.sort(self.data,function ( a,b )
	-- 	if a.status == 1 and b.status ~= 1 then
	-- 		return true
	-- 	end
	-- 	if a.status ~= 1 and b.status == 1 then
	-- 		return false
	-- 	end
	-- 	if a.status == 0 and b.status ~= 0 then
	-- 		return true
	-- 	end
	-- 	if a.status ~= 0 and b.status == 0 then
	-- 		return false
	-- 	end
	-- end)

    if self.ListTableView then
        self.ListTableView:reloadData()
    else
        self:createList()
    end
	
end

function babelTowerAward.setCell(self,items,index)
	
	local award = ui.getIDandNUMs(gamedata.config.tongtianta_dazhangjie[tostring(self.data[index] and self.data[index].id or 1)].reward)
	for i=1,5 do
		if award[i] then
			items["icon"..i]:setVisible(true)
			 ui.setNewIcon(items,award[i], i - 1)

            local id = i - 1
            local key_Ex
            if id == 0 then
                key_Ex = ""
            else
                key_Ex = "_"..id
            end

            items["i_button"..key_Ex]:setTouchPriority(self.touchPriority-1)
            items["i_button"..key_Ex]:addHandleOfControlEvent(function()
                if not gameTouch.isScrollling then
                    ui.setPopwindowByCid(award[i].cid)
                end
            end, CCControlEventTouchUpInside)


		else
			items["icon"..i]:setVisible(false)
		end
	end
        

	if self.data[index] and self.data[index].status == 1 then
        items.buttonNode:setVisible(true)
		items.hintnode:setVisible(false)
		ui.setLabelString(items["doLab"],gameConfig.strings:string_common("moreCommon",6),19)
		ui.removeGray("CCControlButton",items["dobutton"])
		ui.removeGray("CCLabelTTF",items.doLab)
	elseif self.data[index] and self.data[index].status == 2 then
		-- items.hasnode:setVisible(true)
		ui.setLabelString(items["doLab"],gameConfig.strings:string_common("moreCommon",5),19)
		-- ui.addGray("CCControlButton",items["dobutton"])
		-- ui.addGray("CCLabelTTF",items.doLab)
        items["hintLab"]:setString(gameConfig.strings:string_common("moreCommon",5))
        items.buttonNode:setVisible(false)
        items.hintnode:setVisible(true)
	else
        -- items["hintLab"]:setString(gameConfig.strings:string_common("moreCommon",4))
		items.buttonNode:setVisible(true)
        items.hintnode:setVisible(false)
		ui.setLabelString(items["doLab"],gameConfig.strings:string_common("moreCommon",6),19)
		ui.addGray("CCControlButton",items["dobutton"])
		ui.addGray("CCLabelTTF",items.doLab)
	end

	items["dobutton"]:setSwallowsTouch(false)
    items["dobutton"]:setTouchPriority(self.touchPriority-1)
    items["dobutton"]:addHandleOfControlEvent(function()
        if self.data[index] and self.data[index].status == 1 then
        	print("领奖")
            UIRequest({type = 7015,mapId = self.data[index].id})
        elseif self.data[index] and self.data[index].status == 2 then
        	runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",5)})
        end
        
    end, CCControlEventTouchUpInside)
	

    local level = self.data[index] and self.data[index].id or 1
    local config = gamedata.config.tongtianta_dazhangjie[tostring(level)]
	items.title:setString(config.name)
end


function babelTowerAward.createList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("tongtianta/cell_sanxingjiangli", nil, true, "cell_sanxingjiangli")
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
            r = table.getTableLength(gamedata.config.tongtianta_dazhangjie)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listnode:getContentSize().width,
        viewheight = self.rootItems.listnode:getContentSize().height,
        dire = 1
    })
    self.rootItems.listnode:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(self.touchPriority)
end

function babelTowerAward.initFixedString(self)
end

function babelTowerAward.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.ListTableView = nil
    if self.callback then
        self.callback()
    end	
end
return babelTowerAward