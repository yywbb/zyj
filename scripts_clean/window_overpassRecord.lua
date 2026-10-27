--
-- Author: songyibo
-- Date: 2020-03-31 15:13:10
--

local rank = {
    rootNode = nil,
    rootItems = nil,
    listview = nil,

    players = {},
}

function rank.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("passkill/tc_record", nil, true, "tc_record")
    self.touchPriority = touchPriority
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("overpassRecord")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.tip,nil,14)

    UIRequest({type = 3829})
    return self.rootNode
end

function rank.reloadData(self,data)
    printT(data,"rank")
    self.players = data
    if not self.listview  then
        self:createList()
    else
        self.listview:reloadData()
    end
end


function rank.createList(self)
    print("createRankList")
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(930, 260)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("passkill/cell_record", nil, true, "cell_record")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCell(ccbDocumentControler,a1 + 1)
            
            cellCCB:setPosition(930/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.players)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.listview = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listnode:getContentSize().width,
        viewheight = self.rootItems.listnode:getContentSize().height,
        dire = 1
    })
    self.rootItems.listnode:addChild(self.listview)
    self.listview:setTouchPriority(self.touchPriority)
end

function rank.setCell(self,items,index)
	local player = self.players[tostring(index)]
	ui.setWudaoDuanweiRankEffect(items,player,0,(34/34)*1.2,14)
    if items.duanNode then
        ui.setWudaoPart(items,player.part_point or 0)
    end

    ui.setIconLv(items,{cid = player.profile,level = player.level,title = player.title,iconBox = player.iconBox})

    ui.setLabelString(items.power,player.param,1010,34)

    local id = player.params["1"] and player.params["1"].i or 0
    local time = player.params["2"] and player.params["2"].i or 0
    local score = player.params["3"] and player.params["3"].i or 0
    local battleType = player.params["4"] and player.params["4"].i or 0
    local battleResult = player.params["5"] and player.params["5"].i or 0

    local date = os.date("*t", time)

    items.time:setString(gameConfig.strings:fixedDate(time))

    if battleType == 0 then
        ui.setLabelString(items.resultLab,battleResult == 1 and "挑战成功" or "挑战失败",battleResult == 1 and 26 or 27)
    else
        ui.setLabelString(items.resultLab,battleResult == 1 and "防守成功" or "防守失败",battleResult == 1 and 26 or 27)
    end
    
    -- ui.setLabelString(items.reward,(score > 0 and "+" or "-")..score,score > 0 and 13 or 24)

    if score ~= 0 then
        ui.setLabelString(items.reward,(score > 0 and "+" or "-")..score)
        items.rewardNode:setVisible(true)
    else
        items.rewardNode:setVisible(false)
    end
    

    items["doButton"]:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        UIRequest({type = 3830,id = id})
    end, CCControlEventTouchUpInside)
    items["doButton"]:setTouchPriority(self.touchPriority - 1)

    ui.setLabelString(items.doLab,nil,19)

    items.atk:setVisible(battleType == 0)
    items.def:setVisible(battleType == 1)
end

function rank.close(self)  
    
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.listview = nil

    if self.callback then
        self.callback()
    end
end

return rank