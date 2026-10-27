--
-- Author: songyibo
-- Date: 2019-03-23 14:10:26
--

local babelTowerAutoBattle = {
    rootNode = nil,
    rootItems = nil,
    cellSize = {x = 860,y = 230},
    showtimer = nil,
}

function babelTowerAutoBattle.open(self,touchPriority,data,callback)
    self.touchPriority = touchPriority

    self.rootNode,self.rootItems = CCBReaderLoad("tongtianta/tc_saodangjiangli", nil, true, "tc_saodangjiangli")

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("babelTowerAutoBattle")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    

    self.rootItems.doButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("babelTowerAutoBattle")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:setTouchPriority(self.touchPriority - 10)
  
    self.rootItems.touchButton:addHandleOfControlEvent(function()

        if self.showtimer then
            self:stopTimer()
            self:skipAnimate()
        end
        
    end, CCControlEventTouchUpInside)
    -- self.rootItems.touchButton:setSwallowsTouch(true)
    self.rootItems.touchButton:setTouchPriority(self.touchPriority - 10)
    

    self:reload(data)
    self:initFixedString()
    return self.rootNode
end

function babelTowerAutoBattle.reload(self,data)
	printT(data,"babelTowerAutoBattle")
    local rewards = {}
    if data then
        for i=1,table.getTableLength(data) do
        	rewards[i] = data[tostring(i)]
        end
    end
	self.rewards = rewards
    self.copyRewards = table.copy(rewards)
	self:createScrollView()
end

function babelTowerAutoBattle.startTimer(self)
	self.showtimer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
   		print("showtimer")
         self:createCell()
    end, 1, false)
end

function babelTowerAutoBattle.stopTimer(self)
	if self.showtimer then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.showtimer)
	    self.showtimer = nil
	end
end

function babelTowerAutoBattle.skipAnimate(self)
    if #self.copyRewards >= 3 then
        self.rootItems.scrollnode:removeFromParentAndCleanup(true)
        self:createList()
    else
        while next(self.rewards) do
            local reward = table.remove(self.rewards,1)
            local ccb,items = CCBReaderLoad("tongtianta/cell_saodangjiangli", nil, true, "cell_saodangjiangli")
            table.insert(self.celldict,{ccb = ccb,items = items})
            self.rootItems.container:addChild(ccb)
            self:setCell(items,reward,#self.celldict)
            self.rootItems.container:setContentSize(CCSizeMake(self.cellSize.x,#self.celldict * self.cellSize.y))
        end

        for i=#self.celldict,1,-1 do
            local ccb = self.celldict[i].ccb
            ccb:setPosition(self.cellSize.x/2,(#self.celldict - i)*self.cellSize.y)
        end
        local contentH = 610
        self.rootItems.container:setPositionY(contentH - self.cellSize.y * #self.celldict)
    end
end

function babelTowerAutoBattle.createList(self)
    print("createList")
    local celldict = {}
    local unrecycleCell = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(860, 230)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("tongtianta/cell_saodangjiangli", nil, true, "cell_saodangjiangli")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            self:setCell(ccbDocumentControler,self.copyRewards[a1+1], a1+1)

            cellCCB:setPosition(860/2, 0)
            if first then
                a2:addChild(cellCCB)
            end
            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.copyRewards)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.ListNode:getContentSize().width,
        viewheight = self.rootItems.ListNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.ListNode:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(self.touchPriority)

    self.ListTableView:setLuaContentOffset(0, 0)
end


function babelTowerAutoBattle.createScrollView(self)
    print("createScrollView")

    self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    print(self.rootItems.scrollnode)
    self.rootItems.scrollnode:setTouchPriority(self.touchPriority)

    self.celldict = {}
    self.rootItems.touchButton:setTouchEnabled(false)
    self.firsttimer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
        print("firsttimer")
        self.rootItems.touchButton:setTouchEnabled(true)
        self:createCell()
        self:startTimer()
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.firsttimer)
        self.firsttimer = nil
    end, 0.3, false)

end

function babelTowerAutoBattle.createCell(self)
	if not next(self.rewards) then
		self:stopTimer()
		return
	end
	local reward = table.remove(self.rewards,1)
	if not reward then
		self:stopTimer()
		return
	end
	local ccb,items = CCBReaderLoad("tongtianta/cell_saodangjiangli", nil, true, "tc_sanxingjiangli")
	table.insert(self.celldict,{ccb = ccb,items = items})
	ccb:setPosition(self.cellSize.x/2,(#self.celldict - 1)*self.cellSize.y)
	self.rootItems.container:addChild(ccb)
	self:setCell(items,reward,#self.celldict)
	self.rootItems.container:setContentSize(CCSizeMake(self.cellSize.x,#self.celldict * self.cellSize.y))

	for i=#self.celldict,1,-1 do
		local ccb = self.celldict[i].ccb
		ccb:setPosition(self.cellSize.x/2,(#self.celldict - i)*self.cellSize.y)
	end

    local contentH = 610
	if #self.celldict > 3 then
		self.rootItems.container:setPositionY(-self.cellSize.y)
		self.rootItems.container:runAction(CCMoveBy:create(0.3,ccp(0,self.cellSize.y)))
    elseif #self.celldict == 3 then
        local offy = contentH - self.cellSize.y * #self.celldict
        self.rootItems.container:setPositionY(offy)
        self.rootItems.container:runAction(CCMoveBy:create(0.3,ccp(0,-offy)))
    else
        self.rootItems.container:setPositionY(contentH - self.cellSize.y * #self.celldict)
	end

end

function babelTowerAutoBattle.setCell(self,items,data,index)
    local reward = data.reward
	if next(reward) then
		items.noreward:setVisible(false)
	else
		items.noreward:setVisible(true)
	end
	for i=1,5 do
		if reward[tostring(i)] then
			items["icon_"..i]:setVisible(true)
			ui.setNewIcon(items,reward[tostring(i)], i - 1)

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
                    ui.setPopwindowByCid(reward[tostring(i)].cid)
                end
            end, CCControlEventTouchUpInside)
		else
			items["icon_"..i]:setVisible(false)
		end
	end

    local config = gamedata.config.tongtianta_guaiwu[tostring(data.mapId or 1)][tostring(data.level or 1)]
	items.title:setString(config.name)
end


function babelTowerAutoBattle.initFixedString(self)
	ui.setLabelString(self.rootItems.doLab,gameConfig.strings:string_common("buttontext","queding"),19)
end

function babelTowerAutoBattle.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.firsttimer then
    	CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.firsttimer)
    	self.firsttimer = nil
    end

    self:stopTimer()

    if self.callback then
        self.callback()
    end	
end
return babelTowerAutoBattle