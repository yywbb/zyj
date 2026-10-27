--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/25
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--

local sportshelp = {
    ListTableView = nil,
    rootNode = nil,
    rootItems = nil,
    data = {},
    CellSize = {x=870,y=80+14},
}

function sportshelp.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("n_sports2/n_sports2_help", nil, true, "sportshelp")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function sportshelp.reload(self,data,callback)
    self.callback = callback

    self.data = {}
    local config = gamedata.config.athletics_rewards or {}
    for k,v in pairs(config) do
        table.insert(self.data,v)
    end
    local sortById = function(a,b) return a.rank < b.rank end
    table.sort(self.data, sortById)


    if not self.ListTableView then
        self:createList()
    else
        self.ListTableView:reloadData()
    end


    --
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("sportshelp")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

end

function sportshelp.createList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("n_sports2/cell_n_sports2_jiangli", nil, true, "cell_help")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCell(ccbDocumentControler,self.data[a1+1] or self.data[tostring(a1+1)],a1+1)

            cellCCB:setPosition(self.CellSize.x/2, 10)


            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.data)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.list:getContentSize().width,
        viewheight = self.rootItems.list:getContentSize().height,
        dire = 1
    })
    self.rootItems.list:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(self.touchPriority)
end

function sportshelp.setCell(self,item,data,index)

    item.rank:setString(data.rank or "?")

    if index > 1  and self.data[index-1].rank+1 < data.rank then
        item.rank:setString((self.data[index-1].rank+1).."-"..data.rank)
    end

    item.num1:setString("?")
    item.num2:setString("?")
    item.num3:setString("?")
    local rewards = ui.getIDandNUMs(data.day) or {}
    for k,v in pairs(rewards) do
        if v.cid == 1005 then
            item.num1:setString(v.num or "?")
        elseif v.cid == 1001 then
            item.num2:setString(v.num or "?")
        elseif v.cid == 1000 then
            item.num3:setString(v.num or "?")
        end
    end
    --
    ui.setLabelString(item.num1,nil,13)
    ui.setLabelString(item.num2,nil,13)
    ui.setLabelString(item.num3,nil,13)

end

function sportshelp.close(self)
    self.ListTableView = nil
    self.data = {}
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return sportshelp

