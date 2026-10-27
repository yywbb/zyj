--
-- Author: songyibo
-- Date: 2019-03-21 17:39:06
--
local babelTowerEnter = {
    rootNode = nil,
    rootItems = nil,
}

function babelTowerEnter.open(self,touchPriority,data,callback)
    self.touchPriority = touchPriority

    self.rootNode,self.rootItems = CCBReaderLoad("tongtianta/tc_guankainfo", nil, true, "tc_guankainfo")

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("babelTowerEnter")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems["buyTime"]:setSwallowsTouch(true)
    self.rootItems["buyTime"]:setTouchPriority(self.touchPriority-1)
    self.rootItems["buyTime"]:addHandleOfControlEvent(function()
        print("buyTime")
        gameWindows:openWindow("babelTowerBuy",{buyTime = self.data.mapData.buyTime,challengeTime = self.data.mapData.challengeTime,moneynum = 0})
    end, CCControlEventTouchUpInside)

    self:reload(data)
    self:initFixedString()

    -- if not GameScene:checkUpdate(10021) then
    --     self:judgeEnterCondition()
    -- end

    UIRequest({type = 70110})
    return self.rootNode
end

function babelTowerEnter.reload(self,data)
	self.data = data

	local config = gamedata.config.tongtianta_dazhangjie[tostring(self.data.enterMapId)]
	self.rootItems.title:setString(config.name)

	self:freshChallengeTimes()
	self.rootItems.condition1:setString("")
	self.rootItems.condition2:setString("")

	self.rootItems.meet1:setVisible(false)
	self.rootItems.meet2:setVisible(false)

	self:setIcon()
end

function babelTowerEnter.freshChallengeTimes(self,times)
	if times then
		self.data.mapData.buyTime = times
	end

	self.maxChallengeTime = gamedata.config.vip["0"].tongtianta_cishu + gamedata.config.vip[tostring(GameScene.vip.vip)].tongtianta_cishu

	local canChallengeTime = math.max(gamedata.config.vip["0"].tongtianta_cishu +self.data.mapData.buyTime - self.data.mapData.challengeTime,0)

    self.rootItems.challengeTime:setString(canChallengeTime)
    if canChallengeTime > 0 then
        self.rootItems.challengeTime:setColor(ccc3(255,255,255))
    else
        self.rootItems.challengeTime:setColor(ccc3(255,0,0))
    end
	self.rootItems.challengeMaxTime:setString("/"..self.maxChallengeTime)
end

function babelTowerEnter.setIcon(self)
	local reward1 = ui.getIDandNUMs(gamedata.config.tongtianta_dazhangjie[tostring(self.data.enterMapId)].reward)
	local reward2 = string.split(gamedata.config.tongtianta_dazhangjie[tostring(self.data.enterMapId)].drop_preview,",")

	for i=1,5 do
		if reward1[i] then
			self.rootItems["icon1_"..i]:setVisible(true)
			ui.setNewIcon(self.rootItems, {cid = reward1[i].cid,num = reward1[i].num}, i - 1)

			local id = i - 1
			local key_Ex
		    if id == 0 then
		        key_Ex = ""
		    else
		        key_Ex = "_"..id
		    end

		    self.rootItems["i_button"..key_Ex]:setTouchPriority(self.touchPriority-1)
			self.rootItems["i_button"..key_Ex]:addHandleOfControlEvent(function()
		        ui.setPopwindowByCid(reward1[i].cid)
		    end, CCControlEventTouchUpInside)
		else
			self.rootItems["icon1_"..i]:setVisible(false)
		end
	end
	if table.getTableLength(reward2) > 4 then
		self.rootItems.tipSp:setVisible(true)
	else
		self.rootItems.tipSp:setVisible(false)
	end
	self:createList()
	-- for i=1,5 do
	-- 	if reward2[i] then
	-- 		self.rootItems["icon2_"..i]:setVisible(true)
	-- 		ui.setNewIcon(self.rootItems, {cid = tonumber(reward2[i])}, 5 + i - 1)

	-- 		local id = 5 + i - 1
	-- 		local key_Ex
	-- 	    if id == 0 then
	-- 	        key_Ex = ""
	-- 	    else
	-- 	        key_Ex = "_"..id
	-- 	    end

	-- 	    self.rootItems["i_button"..key_Ex]:setTouchPriority(self.touchPriority-1)
	-- 		self.rootItems["i_button"..key_Ex]:addHandleOfControlEvent(function()
	-- 	        ui.setPopwindowByCid(tonumber(reward2[i]))
	-- 	    end, CCControlEventTouchUpInside)

	-- 	else
	-- 		self.rootItems["icon2_"..i]:setVisible(false)
	-- 	end
	-- end
end

function babelTowerEnter.createList(self)
	local reward2 = string.split(gamedata.config.tongtianta_dazhangjie[tostring(self.data.enterMapId)].drop_preview,",")
    print("createList")
    local celldict = {}
    local unrecycleCell = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(140, 150)
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

            ui.setNewIcon(ccbDocumentControler, {cid = tonumber(reward2[a1+1])})
            cellCCB:setScale(0.7)
		    ccbDocumentControler["i_button"]:setTouchPriority(self.touchPriority-1)
			ccbDocumentControler["i_button"]:addHandleOfControlEvent(function()
				if not gameTouch.isScrollling then
					ui.setPopwindowByCid(tonumber(reward2[a1+1]))
				end
		    end, CCControlEventTouchUpInside)

            cellCCB:setPosition(140/2, 60)
            if first then
                a2:addChild(cellCCB)
            end
            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(reward2)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listnode:getContentSize().width,
        viewheight = self.rootItems.listnode:getContentSize().height,
        dire = 0
    })
    self.rootItems.listnode:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(self.touchPriority)
end


function babelTowerEnter.judgeEnterCondition(self,slots)
	local slots = slots
	local config = gamedata.config.tongtianta_dazhangjie[tostring(self.data.enterMapId)]


	local condition1 = false
	local condition2 = false

	if self.data.enterMapId == 1 then
		condition1 = true
		self:conditionActivateShow(1,"无",condition1)
	else
		if self.data.enterMapId <= self.data.mapData.maxPoint then
			condition1 = true
		end
		local config = gamedata.config.tongtianta_dazhangjie[tostring(self.data.enterMapId - 1)]
		self:conditionActivateShow(1,string.format(gameConfig.strings:string_common("babelTower",5),config.name),condition1)
	end

	if config.gold_num > 0 then
		local haveNum = 0
		for k,v in pairs(slots) do
			if v.general then
				if v.general.iid == GameScene.protagonist.iid then
					if v.general.level2 >= config.gold_break_level + 23 then
						haveNum = haveNum + 1
					end
				else
					if v.general.level2 >= config.gold_break_level + 13 then
						haveNum = haveNum + 1
					end
				end
			end
		end

		if haveNum >= config.gold_num then
			--激活
			condition2 = true
		end
		self:conditionActivateShow(2,string.format(gameConfig.strings:string_common("babelTower",6), config.gold_num,config.gold_break_level),condition2)
		self.rootItems.conditionnode2:setVisible(true)
	else
		condition2 = true
		self.rootItems.conditionnode2:setVisible(false)
	end

	self.rootItems["doButton"]:setSwallowsTouch(true)
    self.rootItems["doButton"]:setTouchPriority(self.touchPriority-1)
    self.rootItems["doButton"]:addHandleOfControlEvent(function()
    	
    	--次数不足
        self.maxChallengeTime = gamedata.config.vip["0"].tongtianta_cishu + self.data.mapData.buyTime
        if self.data.mapData.curPoint == 0 and self.data.mapData.challengeTime >= self.maxChallengeTime then
            runGamePrompt({msg = gameConfig.strings:string_common("babelTower", 18)})
            gameWindows:openWindow("babelTowerBuy",{buyTime = self.data.mapData.buyTime,challengeTime = self.data.mapData.challengeTime})
            return
        end

        if not condition1 then
        	runGamePrompt({msg=gameConfig.strings:string_common("babelTower",7)})
        elseif not condition2 then
        	runGamePrompt({msg=gameConfig.strings:string_common("babelTower",8)})
        else
        	UIRequest({type = 7012,mapId = self.data.enterMapId})
        end
    end, CCControlEventTouchUpInside)

end

function babelTowerEnter.conditionActivateShow(self,index,str,status)
	self.rootItems["condition"..index]:setString(str)
	if status then
		self.rootItems["condition"..index]:setColor(ccc3(0,255,0))
		self.rootItems["meet"..index]:setVisible(true)
	else
		self.rootItems["condition"..index]:setColor(ccc3(128,128,128))
		self.rootItems["meet"..index]:setVisible(false)
	end
end

function babelTowerEnter.initFixedString(self)
	ui.setLabelString(self.rootItems.doLab,gameConfig.strings:string_common("babelTower",4),19)
end

function babelTowerEnter.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end	
end
return babelTowerEnter