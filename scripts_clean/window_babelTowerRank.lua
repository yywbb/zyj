--
-- Author: songyibo
-- Date: 2019-06-26 13:47:14
--
local babelTowerRank = {
    rootNode = nil,
    rootItems = nil,
    rankType = "today",  --"history"
    rankConfig = {"today","history"},
    normalCellSize = {x = 920,y = 130},
    ListTableView = nil,
    data = {today = {},history = {}}
}

function babelTowerRank.open(self,touchPriority,data,callback)
    self.touchPriority = touchPriority

    self.rootNode,self.rootItems = CCBReaderLoad("tongtianta/tc_paihangbang", nil, true, "tc_paihangbang")

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindowDirect("babelTowerRank")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self:initFixedString()

    self.rootItems.todayBtn:addHandleOfControlEvent(function()
        self:shiftRank("today")
    end, CCControlEventTouchUpInside)
    self.rootItems.todayBtn:setSwallowsTouch(true)
    self.rootItems.todayBtn:setTouchPriority(self.touchPriority)
    
    self.rootItems.historyBtn:addHandleOfControlEvent(function()
        self:shiftRank("history")
    end, CCControlEventTouchUpInside)
    self.rootItems.historyBtn:setSwallowsTouch(true)
    self.rootItems.historyBtn:setTouchPriority(self.touchPriority)

    UIRequest({type = 7019, id = 0})
    return self.rootNode
end

function babelTowerRank.reload(self,data)
    if data and data.id then
        self:makeData(data)
    end
    self:refreshUI()
end

function babelTowerRank.makeData(self,data)
    local Ex = (data.id == 0 and "today" or "history")

    
    self.data[Ex] = {rankData = {},myRank = -1,myRankData = {}}
    self.data[Ex].rankData = data.data
    self.data[Ex].myRankData = data.myRankData

    for k,v in pairs(data.data) do
        if v.rid == GameScene.roleinfo.id then
            self.data[Ex].myRank = tonumber(k)
        end
    end
end

function babelTowerRank.shiftRank(self,_type)
	if self.rankType == _type then return end
	self.rankType = _type

    for i,v in ipairs(self.rankConfig) do
        if v == self.rankType then
            setSpriteFrameByName(self.rootItems["buttonsprite"..i], gameConfig.images.pageButtonON)
        else
            setSpriteFrameByName(self.rootItems["buttonsprite"..i], gameConfig.images.pageButtonOFF)
        end
    end
            

    if self.data[self.rankType].rankData then
        self:refreshUI()
    else
        UIRequest({type = 7019, id = self.rankType == "today" and 0 or 1})
    end
	
end

function babelTowerRank.refreshUI(self)
	if self.ListTableView then

        self.ListTableView:setLuaContentOffset(0, self.rootItems.listnode:getContentSize().height - table.getTableLength(self.data[self.rankType].rankData)*self.normalCellSize.y)

        self.ListTableView:reloadData()
    else
        self:createList()
    end

    local myRank = self.data[self.rankType].myRank

    if myRank == -1 then
        self.rootItems.wodepaihang:setString(gameConfig.strings:string_common("babelTower", 31))
    else
        self.rootItems.wodepaihang:setString(myRank)
    end

    self.rootItems.mylevel:setString("")
    if self.data[self.rankType].myRankData and self.data[self.rankType].myRankData.point then
        local config = gamedata.config.tongtianta_dazhangjie[tostring(self.data[self.rankType].myRankData.point)]
        if config then
            self.rootItems.mylevel:setString(config.name.."第"..self.data[self.rankType].myRankData.level.."层")
        end
    end

end

function babelTowerRank.setCell(self,items,index)
    printT(self.data,"setCell")
    print(index)
	local data = self.data[self.rankType].rankData[tostring(index)]
    items.rank:setString(index)
    items.name:setString(data.name)

    if data.params["1"].i then
        local config = gamedata.config.tongtianta_dazhangjie[tostring(data.params["1"].i)]
        if config then
            items.level:setString(config.name.."第"..data.params["2"].i.."层")
        end
    end
    
end

function babelTowerRank.createList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("tongtianta/cell_rank", nil, true, "cell_rank")
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
            r = table.getTableLength(self.data[self.rankType].rankData)
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

function babelTowerRank.initFixedString(self)
	self.rootItems.fixed1:setString(gameConfig.strings:string_common("babelTower", 28))
	self.rootItems.fixed2:setString(gameConfig.strings:string_common("babelTower", 29))
	self.rootItems.fixed3:setString(gameConfig.strings:string_common("babelTower", 30))
end

function babelTowerRank.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.rankType = "today"
    self.ListTableView = nil
    self.data = {today = {},history = {}}
    if self.callback then
        self.callback()
    end	
end
return babelTowerRank