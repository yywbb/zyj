--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 2016-01-27
-- Time: 上午10:26
-- To change this temisLandate use File | Settings | File TemisLandates.
--

local standingsScroll = {
	rootNode = nil,
	rootItems = nil,
	titleCellSize = {x=910, y=110},

	standingsListTableView = nil,
	guildTable = {},
}

function standingsScroll.open(self, touchPriority, data, callback)
	self.rootNode, self.rootItems = CCBReaderLoad("gonghuizhan/tc_zhanbao", nil, true, "zhanbao")
	self.touchPriority = touchPriority
	self.callback = callback
	-- self.guildTable = {}

	for k, v in pairs(data.data) do
		table.insert(self.guildTable, v)
	end	

    local guildSort = function(a,b) return a.id < b.id end
    table.sort(self.guildTable,guildSort)

	printT(self.guildTable)



	self.pointId = data.pointId
	-- 退出
	self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("standingsScroll")
	end, CCControlEventTouchUpInside)

	self.rootItems.closeButton:setSwallowsTouch(true)
	self.rootItems.closeButton:setTouchPriority(self.touchPriority)	


    ui.setLabelString(self.rootItems.closeLab, "关 闭", 19)
	self.rootItems.closeBtn2:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("standingsScroll")
	end, CCControlEventTouchUpInside)

	self.rootItems.closeBtn2:setSwallowsTouch(true)
	self.rootItems.closeBtn2:setTouchPriority(self.touchPriority)


	self:upStandingsList()
	return self.rootNode
end

----------------------------------------------------------------------------
function standingsScroll.upStandingsList(self)  -- scrollView ```
    local celldict = {}
    local standingsListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.titleCellSize.x, self.titleCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("gonghuizhan/cell_zhanbao", nil, true, "cell_zhanbao")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                --ui.tableviewAnimation(self.standingsListTableView, cellCCB, self.titleCellSize.x/2 + 15, 0, a1)
            	cellCCB:setPosition(self.titleCellSize.x/2, self.titleCellSize.y/2)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            --
            --info
            if a1+1 == 1 then
                ui.setLabelString(ccbDocumentControler.name1, self.guildTable[a1+1].battleName1, 7)
                ui.setLabelString(ccbDocumentControler.name2, self.guildTable[a1+1].battleName2, 7) 
                ui.setLabelString(ccbDocumentControler.totalStandings, "总战报", 35)
                ccbDocumentControler.totalStandings:setVisible(true)

            else
                ui.setLabelString(ccbDocumentControler.name1, self.guildTable[a1+1].battleName1, 14)
                ui.setLabelString(ccbDocumentControler.name2, self.guildTable[a1+1].battleName2, 14)    
                ccbDocumentControler.totalStandings:setVisible(false)
            end

            -- ccbDocumentControler.i_select:setVisible(false)
            -- self.treasuresData[a1+1].item = ccbDocumentControler.i_select
            ui.setLabelString(ccbDocumentControler.doLab, "查看", 18)
            ccbDocumentControler.doButton:addHandleOfControlEvent(function()
            	print("点击第" .. a1+1 .. "个图标", self.guildTable[1].fightId, self.pointId)

            	if a1+1 == 0 then
            		
            	elseif a1+1 == 1 then
            		-- 请求公会战报
            		UIRequest({type = 2139, id = self.pointId, fightId = self.guildTable[1].fightId})
            	else
            		-- 请求单个人物战报
            		UIRequest({type = 2141, id = self.pointId, fightId = self.guildTable[1].fightId, fightRoundId = self.guildTable[a1+1].fightId})

            	end
			end, CCControlEventTouchUpInside)
	        ccbDocumentControler.doButton:setSwallowsTouch(true)
	        ccbDocumentControler.doButton:setTouchPriority(self.touchPriority-1)
	        

            if self.standingsListTableView then
                cellCCB:setPosition(self.titleCellSize.x/2, self.titleCellSize.y/2)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.guildTable)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.standingsListTableView = ui.createLuaTableView({
        handle = standingsListHandle,
        viewwidth = self.rootItems.listscroll:getContentSize().width,
        viewheight = self.rootItems.listscroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.listscroll:addChild(self.standingsListTableView)
    self.standingsListTableView:setTouchPriority(self.touchPriority)

end
----------------------------------------------------------------------------

function standingsScroll.close(self, _type) -- 退出
	self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
	self.rootNode = nil
	self.rootItems = nil
    self.standingsListTableView = nil
    self.guildTable = {}
end

return standingsScroll