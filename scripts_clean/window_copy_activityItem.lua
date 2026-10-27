local activityitem = {
    rootNode = nil,
    rootItems = nil,
    cellSize = {width = 900,height = 230},
    items = {},
}

function activityitem.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("shop/recruit_yulan", nil, true, "activityItem")
    self.touchPriority = touchPriority
    
    self.rootItems.title:setString(gameConfig.strings:string_common("copyChapter",4))
    self.rootItems.closeButton:setTouchPriority(self.touchPriority) 
    self.rootItems.closeButton:addHandleOfControlEvent(function()
    	gameWindows:closeWindow("copyacivityitem")
    end, CCControlEventTouchDown) 
    printT(data)
    if data.type and data.type == "boosfall" then
        self.data = data.data
        self:getBossFall(data.data)
    else
        self.data = data
        self:getNum(data)
    end
    self:createitemlist()
    
    self.isrewarddouble = data.isrewarddouble
    self:doubleRewardSet()

    return self.rootNode	
end

-- 双倍活动2016年7月活动
function activityitem.doubleRewardSet(self)
    print("doubleRewardSet===")
    -- if not self.data.isrewarddouble or self.data.isrewarddouble == false then return end
    if not self.rootItems.isrewarddouble then return end

    if self.isrewarddouble then
        self.rootItems.isrewarddouble:setVisible(true)
        ui.setLabelString(self.rootItems.isrewarddouble,gameConfig.strings:string_common("doublereward",1),24)
    else
        self.rootItems.isrewarddouble:setVisible(false)
    end
end

function activityitem.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
	self.count = 0
	self.items = {}    
    self.isrewarddouble = false
end
--获得活动掉落物品
function activityitem.getNum(self,aiData)
	self.count = 0
    if tonumber(aiData[1]["function"]) == 4 or tonumber(aiData[1]["function"]) == 5 or tonumber(aiData[1]["function"]) == 2 then
        local min_rewards = ui.getIDandNUMs(aiData[2]["0_reward"])
        local rewards = ui.getIDandNUMs(aiData[2]["100_reward"])
        for k,v in pairs(rewards) do
            self.count = self.count + 1
            local num1 = min_rewards[self.count].num
            local num2 = rewards[self.count].num
            if num1 >= 10000 then
                num1 = math.floor(num1/10000).."万"
            end 
            if num2 >= 10000 then
                num2 = math.floor(num2/10000).."万"
            end 
            table.insert( self.items, {cid = v.cid, num = (num1.."~"..num2)})
        end
    else
        for i = 1,4 do
            if aiData[2]["drop"..i] ~= 0 then
                self.count = self.count + 1
                table.insert( self.items, {cid = aiData[2]["drop"..i], num = (aiData[2]["drop"..i.."section1"].."~"..aiData[2]["drop"..i.."section2"])})
            end
        end
    end
end
--获得王的男人掉落物品
function activityitem.getBossFall( self,aiData )
    self.count = 0   
    for i = 1,4 do
        if aiData["drop"..i] ~= 0 then
            self.count = self.count + 1
            if aiData["drop"..i.."number"..i] and aiData["drop"..i.."number"..i] > 0 then
                table.insert( self.items, {cid = aiData["drop"..i], num = (aiData["drop"..i.."number"].."~"..aiData["drop"..i.."number"..i])} )
            else    
                table.insert( self.items, {cid = aiData["drop"..i]} )
            end
        end        
    end
end
function activityitem.createitemlist(self)
    local celldict = {}
    local listHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.cellSize.width, self.cellSize.height)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("mochong3/cell_mochongskill.ccbi", nil, true, "cell_items")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            cellCCB:setPosition(self.cellSize.width/2, self.cellSize.height/2)         
           	self:setCell(ccbDocumentControler,a1)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = math.ceil(self.count/4)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.listTableView = ui.createLuaTableView({
        handle = listHandle,
        viewwidth = self.rootItems.listnode:getContentSize().width,
        viewheight = self.rootItems.listnode:getContentSize().height,
        dire = 1
    })
    self.listTableView:setTouchPriority(self.touchPriority)
    self.rootItems.listnode:addChild(self.listTableView)
end
function activityitem.setCell(self,aiCell,aiIndex )
	print("activityitem.setCell")
	for i = 1,4 do
		if aiIndex * 4 + i <= self.count  then
			if i == 1 then
				ui.setNewIconName(aiCell,self.items[aiIndex * 4 + i])
			else
				ui.setNewIconName(aiCell,self.items[aiIndex * 4 + i],i-1)
			end
		else
			aiCell["cellItem"..i]:setVisible(false)
		end
	end
end
return activityitem