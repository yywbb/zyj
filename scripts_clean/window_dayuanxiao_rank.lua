-- dayuanxiaorank

local dayuanxiaorank = {
    rootNode = nil,
    rootItems = nil,

    rankListTableView = nil,
    rankCellSize = {x=960,y=130},

    isscrolltouched = false,
    callback = nil,


    rankData = {},
    myRank = {},

    point = 0,
}

function dayuanxiaorank.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority

    self.rootNode, self.rootItems = CCBReaderLoad("activityzhongqiu/tc_yuanxiao_rank", nil, true, "tc_yuanxiao_rank")
    self.callback  = callback

    if data and data.point then
        self.point = data.point
    end
    
    --返回
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("dayuanxiaorank")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","dayuanxiaorank",touchbegin)
    local function touchend(pos)
        if self.rootItems.ranklistnode and ui.isTouched(self.rootItems.ranklistnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end

        if self.rootItems.rankrewardlistnode and ui.isTouched(self.rootItems.rankrewardlistnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","dayuanxiaorank",touchend) 

    UIRequest({type = 8245})

    self.root:addChild(self.rootNode)

    return self.root
end

function dayuanxiaorank.reloadData(self, data)
    self.rankData = data.rankData
    self.myRank = data.myRank

    if self.myRank and next(self.myRank) then
        if self.myRank.rank <= 100 then
            self.rootItems.myranknum:setString(self.myRank.rank)
        end
        self.rootItems.myserver:setString("S"..self.myRank.server)
        self.rootItems.myname:setString(self.myRank.name)
        self.rootItems.mypoint:setString(self.myRank.maxpoint)
    else
        self.rootItems.myranknum:setString("未上榜")
        local serverid = gameWindows.windows["roleinfo"].module.SelectedServer.id or 1
        self.rootItems.myserver:setString("S"..serverid)
        self.rootItems.myname:setString(GameScene.roleinfo.name)
        self.rootItems.mypoint:setString(self.point)
    end

    if self.rankData and next(self.rankData) then
        if self.rankListTableView == nil then
            self:createRankList()
        else
            self.rankListTableView:reloadData()
        end
    end
end

--排行榜
function dayuanxiaorank.createRankList(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.rankCellSize.x, self.rankCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityzhongqiu/cell_rank", nil, true, "cell_rank")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCellRankList(ccbDocumentControler,a1+1)

            cellCCB:setPosition(self.rankCellSize.x/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
                r = table.getTableLength(self.rankData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.rankListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.ranklistnode:getContentSize().width,
        viewheight = self.rootItems.ranklistnode:getContentSize().height,
        dire = 1
    })
    self.rootItems.ranklistnode:addChild(self.rankListTableView)
    self.rankListTableView:setTouchPriority(self.touchPriority)
end

function dayuanxiaorank.setCellRankList(self,item,index)
    local rData = self.rankData[tostring(index)]
    item.ranknum:setString(rData.rank)
    item.server:setString("S"..rData.server)
    item.name:setString(rData.name)
    item.point:setString(rData.maxpoint)
end

function dayuanxiaorank.close(self)
    gameTouch:UnrigistFunc("begin","dayuanxiaorank")
    gameTouch:UnrigistFunc("end","dayuanxiaorank")    

    self.isscrolltouched = false    
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.rankListTableView = nil

    self.rankData = {}
    self.myRank = {}

    if self.callback then
        self.callback()
    end
end

return dayuanxiaorank