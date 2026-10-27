--

--

local cangjinggeshop = {
    CellSize = {x=1080, y=330},
    rootNode = nil,
    rootItems = nil,

    isscrolltouched = false,

    ListTableView = nil,
    data = {},
    hasnum = 0,
}



function cangjinggeshop.init(self,size)
    self.contentsize = size
    self.show = true
    self.rootNode,self.rootItems = CCBReaderLoad("cangjingge/changjingge_shop", nil, true, "cangjingge_shop")

    self.rootItems.topnode:setPositionY(self.contentsize.y-180)

    self.rootItems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-520-160))

    ui.setLabelString(self.rootItems["gotoText"],gameConfig.strings:string_common("cangjingge",49),18)
    self.rootItems["gotoBtn"]:setTouchPriority(-102)
    self.rootItems["gotoBtn"]:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        gameTouch:clickprofbytime(1)
        GameScene:shiftLayer("manor","up")
    end, CCControlEventTouchUpInside)

    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","cangjinggeshop",touchbegin)

    local function touchend(pos)
        if self.rootItems.listnode and ui.isTouched(self.rootItems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","cangjinggeshop",touchend)
    --

    return self.rootNode

end



function cangjinggeshop.reloaddata(self,data)

    self.data = data.shop or {}
    self.hasnum = data.hasnum or 0

    if not self.show then return end

    self.rootItems.hasnum:setString("x"..self.hasnum)

    if not self.ListTableView then
        self:createList()
    else
        if self.ListTableView:getLuaContentOffsetY() < self.rootItems.listnode:getContentSize().height - math.ceil(table.getTableLength(self.data)/2)*self.CellSize.y then
            self.ListTableView:setLuaContentOffset(0, self.rootItems.listnode:getContentSize().height - math.ceil(table.getTableLength(self.data)/2)*self.CellSize.y)
        end
        self.ListTableView:reloadData()
    end

end




function cangjinggeshop.setone(self,data,items,index)

    if not data then
        return
    end

    local config = gamedata.config.home_store[tostring(data.id)]

    ui.setNewIconName(items,{cid = config.goods, num = config.number},index-1)
    --
    items["in_button"..(index>1 and "_1" or "")]:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        if not self.isscrolltouched then return end
        ui.setPopwindowByCid(config.goods)
    end, CCControlEventTouchUpInside)
    items["in_button"..(index>1 and "_1" or "")]:setTouchPriority(-102)
    --

    items["cost"..index]:setVisible(false)
    items["gold"..index]:setVisible(false)
    local cost = ui.getIDandNUMs(config.cost)
    if cost[1] then
        if cost[1].cid == 20376 then
            items["cost"..index]:setVisible(true)
            ui.setLabelString(items["costnum"..index],"x"..cost[1].num,14)
        elseif cost[1].cid == 1001 then
            items["gold"..index]:setVisible(true)
            ui.setLabelString(items["goldnum"..index],"x"..cost[1].num,14)
        end
    end
    if cost[2] then
        if cost[2].cid == 20376 then
            items["cost"..index]:setVisible(true)
            ui.setLabelString(items["costnum"..index],"x"..cost[2].num,14)
        elseif cost[2].cid == 1001 then
            items["gold"..index]:setVisible(true)
            ui.setLabelString(items["goldnum"..index],"x"..cost[2].num,14)
        end
        items["cost"..index]:setPositionY(-20)
        items["gold"..index]:setPositionY(-10)
    else
        items["cost"..index]:setPositionY(-50)
        items["gold"..index]:setPositionY(10)
    end

    local curCof = gamedata.config.home_store_material[tostring(data.id)]
    printT(data)
    printT(curCof,"  ======  curCof  =======")
    if curCof then
        local count = self:getCountByLevel(curCof)
        ui.setLabelString(items["limit"..index],gameConfig.strings:string_common("cangjingge",36)..((count-data.num>0) and (count-data.num) or 0),13)
    else
        if config.type and config.type == 1 then
            ui.setLabelString(items["limit"..index],gameConfig.strings:string_common("cangjingge",36)..((config.limit-data.num>0) and (config.limit-data.num) or 0),13)
        else
            ui.setLabelString(items["limit"..index],"",13)
        end
    end
    --
    ui.setLabelString(items["buttontext"..index],nil,18)

    items["button"..index]:setTouchPriority(-102)
    items["button"..index]:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        if not self.isscrolltouched then return end
        gameTouch:clickprofbytime(1)

        local curNum = config.limit
        if curCof then
            curNum = self:getCountByLevel(curCof)
            print("  ======  curNum  =======",curNum)
        end
        if curNum-data.num > 0 then
            --UIRequest({type = 4830, id = data.id, cost = cost})
            function shopExchangeRequest(num)
                UIRequest({type = 4830, id = data.id, cost = cost,num = num})            
            end
            -- if (data.id == 1) or (data.id == 2) then
            --     gameWindows:openWindow("shopExchange",{cid = config.goods,num = config.number,cost = cost,exchangeNum = (curNum-data.num),delaybutton = true},shopExchangeRequest)
            -- else    
            --     gameWindows:openWindow("shopExchange",{cid = config.goods,num = config.number,cost = cost,exchangeNum = (curNum-data.num),ccbtype = 2},shopExchangeRequest)
            -- end

            gameWindows:openWindow("shopExchange",{cid = config.goods,num = config.number,cost = cost,exchangeNum = (curNum-data.num),delaybutton = true},shopExchangeRequest)
        else
            runGamePrompt({msg = gameConfig.strings:string_common("cangjingge",37)})
        end
    end, CCControlEventTouchUpInside)

    local curCount = config.limit
    if curCof then
        curCount = self:getCountByLevel(curCof)
    end

    if curCount-data.num > 0 then
        ui.removeGray("CCControlButton",items["button"..index])
    else
        ui.addGray("CCControlButton",items["button"..index])
    end

end


function cangjinggeshop.createList(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.CellSize.x, self.CellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("cangjingge/cell_cangjinggeshop", nil, true, "cell_cangjinggeshop")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setone(self.data[tostring((a1+1)*2-1)],ccbDocumentControler,1)

            if self.data[tostring((a1+1)*2)] then
                self:setone(self.data[tostring((a1+1)*2)],ccbDocumentControler,2)
                ccbDocumentControler.node2:setVisible(true)
            else
                ccbDocumentControler.node2:setVisible(false)
            end


            --if self.rewardListTableView then
            cellCCB:setPosition(self.CellSize.x/2, 0)
            --end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = math.ceil(table.getTableLength(self.data)/2)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listnode:getContentSize().width,
        viewheight = self.rootItems.listnode:getContentSize().height,
        dire = 1
    })
    self.ListTableView:setTouchPriority(-101)
    self.rootItems.listnode:addChild(self.ListTableView)
end


function cangjinggeshop.getCountByLevel(self,data)
    -- body
    local count = 0
    local lvindex = 10000
    local curLevel = GameScene.roleinfo.level
    for i,v in pairs(data) do
        if (lvindex > v.level) and (curLevel <= v.level) then
            count = v.number
            lvindex = v.level
        end
    end
    return count
end


function cangjinggeshop.clear(self)


    gameTouch:UnrigistFunc("begin","cangjinggeshop")
    gameTouch:UnrigistFunc("end","cangjinggeshop")
    self.show = false

    self.ListTableView = nil
    self.data = {}
    self.hasnum = 0

    if self.rootNode then
        self.rootNode:removeAllChildrenWithCleanup(true)
        self.rootNode:removeFromParentAndCleanup(true)
        self.rootNode = nil
        self.rootItems = nil
    end
end


return cangjinggeshop
