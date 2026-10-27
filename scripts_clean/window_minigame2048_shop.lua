
local game2048shop = {
    rewardCellSize = {x=900, y=280},

    rootNode = nil,
    rootItems = nil,
    rewardListTableView = nil,

    listReward = {},
    rewardData = {},
    myData = {},

    oqidata = {},

    isscrolltouched = false,
}

function game2048shop.open(self,touchPriority,data,callback)
    self.touchPriority = touchPriority

    self.rootNode,self.rootItems = CCBReaderLoad("minigame/2048_duihuan.ccbi", nil, true, "2048_duihuan")

    ui.setLabelString(self.rootItems["alljifenlab"],nil,14)

    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
    	gameWindows:closeWindow("game2048shop")
    end,CCControlEventTouchUpInside)

    --
    self.listReward = gamedata.config.exchange_2048

    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","game2048shop",touchbegin)
    local function touchend(pos)
        if self.rootItems.rewardScroll and ui.isTouched(self.rootItems.rewardScroll, pos.x, pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","game2048shop",touchend)

    UIRequest({type = 1608})

    return self.rootNode
end

function game2048shop.relaodpoint(self,data)
    self.myData = {point = data}
    ui.setLabelString(self.rootItems.pointnum, self.myData.point or 0, 21)
end

function game2048shop.reloaddata(self,data)

    if data then
        self.rewardData = data
    end
    printT(self.rewardData,"jkp-rewardData")

    if not self.rewardListTableView then
        self:createRewardList()
    else
        if self.rewardListTableView:getLuaContentOffsetY() < self.rootItems.rewardScroll:getContentSize().height - table.getTableLength(self.listReward)*self.rewardCellSize.y then
            self.rewardListTableView:setLuaContentOffset(0, self.rootItems.rewardScroll:getContentSize().height - table.getTableLength(self.listReward)*self.rewardCellSize.y)
        end
        self.rewardListTableView:reloadData()
    end

end

function game2048shop.createRewardList(self)
    local celldict = {}
    local rankListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.rewardCellSize.x, self.rewardCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("minigame/cell_2048_duihuan", nil, true, "cell_2048_duihuan")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                --ui.tableviewAnimation(self.rewardListTableView,cellCCB,self.rewardCellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setone(self.listReward[tostring((a1+1)*2-1)],ccbDocumentControler,1)
            if self.listReward[tostring((a1+1)*2)] then
                ccbDocumentControler.cellnode2:setVisible(true)
                self:setone(self.listReward[tostring((a1+1)*2)],ccbDocumentControler,2)
            else
                ccbDocumentControler.cellnode2:setVisible(false)
            end
            cellCCB:setPosition(self.rewardCellSize.x/2, 0)

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = math.ceil(table.getTableLength(self.listReward)/2)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.rewardListTableView = ui.createLuaTableView({
        handle = rankListHandle,
        viewwidth = self.rootItems.rewardScroll:getContentSize().width,
        viewheight = self.rootItems.rewardScroll:getContentSize().height,
        dire = 1
    })
    self.rewardListTableView:setTouchPriority(self.touchPriority)
    self.rootItems.rewardScroll:addChild(self.rewardListTableView)
end

function game2048shop.setone(self,data,items,index)
    print("index = ",index)
    printT(data)

    local key_Ex
    local exchangeNum = 99999999
    if index == nil or index == 1 then
        key_Ex = ""
    else
        key_Ex = "_1"
    end

    if not data then
        return
    end

    local exnum = 0
    if (data.limit and data.limit > 0) then
        exnum = data.limit - self.rewardData[tostring(data.id)]
        items["changenum"..key_Ex]:setString("可兑换次数: "..exnum)
    else
        items["changenum"..key_Ex]:setString("")
    end
    ui.setLabelString(items["changenum"..key_Ex],nil,13)

    if data.item and data.item ~= "" then
        local id1,num1 = ui.getIDandNUM(data.item)
        ui.setNewIconName(items,{cid = id1, num = num1}, index-1)
        --
        items["in_button"..key_Ex]:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            if not self.isscrolltouched then return end
            ui.setPopwindowByCid(id1)
        end, CCControlEventTouchUpInside)
        items["in_button"..key_Ex]:setTouchPriority(self.touchPriority)
        --
    end

    if data.number and data.number ~= "" then
        items["pointnode"..key_Ex]:setVisible(true)

        ui.setLabelString(items["jifenlab"..key_Ex],nil,14)
        local num1 = tonumber(data.number)
        ui.setLabelString(items["pointnum"..key_Ex],num1,14)
        exchangeNum = exchangeNum > math.floor((self.myData.point or 0)/num1) and math.floor((self.myData.point or 0)/num1) or exchangeNum
    else
        items["pointnode"..key_Ex]:setVisible(false)
    end

    --
    ui.setLabelString(items["buttontext"..key_Ex],nil,18)
    items["button"..key_Ex]:setTouchPriority(self.touchPriority)
    items["button"..key_Ex]:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        if not self.isscrolltouched then return end
        gameTouch:clickprofbytime(1)
        --
        if (data.limit and data.limit > 0) and (exnum < exchangeNum) then
            exchangeNum = exnum
        end
        if (data.limit and data.limit > 0) and (exnum <= 0) then
            runGamePrompt({msg = "兑换次数不足"})
        else
            local cb = function( num )
                UIRequest({type = 1604, pos = data.id, num = num})
            end
            ui.exchangeMore(cb,exchangeNum)
        end
    end, CCControlEventTouchUpInside)


    if (data.limit and data.limit > 0) and (exnum <= 0) then
        ui.addGray("CCControlButton",items["button"..key_Ex])
    else
        ui.removeGray("CCControlButton",items["button"..key_Ex])
    end

end

function game2048shop.close(self)

    gameTouch:UnrigistFunc("begin","game2048shop")
    gameTouch:UnrigistFunc("end","game2048shop")

    self.listReward = {}
    self.rewardData = {}
    self.myData = {}
    self.oqidata = {}

    self.rewardListTableView = nil

    if self.rootNode then
        self.rootNode:removeAllChildrenWithCleanup(true)
        self.rootNode:removeFromParentAndCleanup(true)
        self.rootNode = nil
        self.rootItems = nil
    end

end

return game2048shop