--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/17
-- Time: 下午12:09
-- To change this template use File | Settings | File Templates.
--

local post = {
    rootNode = nil,
    rootItems = nil,

    listview = nil,

    CellSize = {x=960,y=270},
    updateCellSize = {x=960,y=430},
--
    unrecycleCell = {},

    timelocation={
        [1] = 184,
        [2] = 544,
    }
}

function post.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("post/post", nil, true, "post")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function post.reload(self,data,callback)
    self.data = gamedata.config.notice_2

    printT(self.data)

    -- ui.setLabelString(self.rootItems.buttontext,"进入游戏",19)
    ui.setLabelString(self.rootItems.buttontext,gameConfig.strings:string_common("popups","enterGame"),19)
    self.rootItems.button:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("post")
    end, CCControlEventTouchUpInside)
    self.rootItems.button:setSwallowsTouch(true)
    self.rootItems.button:setTouchPriority(self.touchPriority)


    local celldict = {}
    local chatListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then

        elseif fn == "hasFixedCellSize" then
            r = false
        elseif fn == "cellSizeForIndex" then
            if  self.data[tostring(1000+a1+1)].type ==2 then
                r = CCSizeMake(self.updateCellSize.x, self.updateCellSize.y)
            else
                r = CCSizeMake(self.CellSize.x, self.CellSize.y)
            end
        elseif fn == "isRecycle" then
            for k,v in pairs (self.unrecycleCell) do
                if a2 == v.cell then
                    print("unrecycleCELL ")
                    return false
                end
            end
            return true

        elseif fn == "cellAtIndex" then
            if self.data[tostring(1000+a1+1)].type ==2 then
                local ccb, items
                if self.unrecycleCell.updateCell == nil then
                    a2 = CCTableViewCell:create()
                    ccb, items =  CCBReaderLoad("post/cell_post", nil, true, "cell_post")
                    a2:addChild(ccb)
                    self.unrecycleCell.updateCell={cell = a2, ccb =ccb, items=items}
                    self.unrecycleCell.updateCell.cell:retain()
                else
                    a2 = self.unrecycleCell.updateCell.cell
                    ccb = self.unrecycleCell.updateCell.ccb
                    items = self.unrecycleCell.updateCell.items
                end
                ccb:setPosition(self.updateCellSize.x/2, -self.updateCellSize.y)

            else
                local cellCCB,ccbDocumentControler = 0,0
                local first = true
                if not a2 then
                    a2 = CCTableViewCell:create()
                    cellCCB, ccbDocumentControler = CCBReaderLoad("post/cell_post", nil, true, "cell_post")
                    celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                else
                    first = false
                    cellCCB = celldict[a2].cellCCB
                    ccbDocumentControler = celldict[a2].ccbDocumentControler
                end

                local celldata = self.data[tostring(1000+a1+1)]
                setSpriteFrameByName(ccbDocumentControler.bg, celldata.bg)
                ui.setLabelString(ccbDocumentControler.time,celldata.time,26)
                ccbDocumentControler.time:setPositionX(self.timelocation[celldata.timelocation])

                cellCCB:setPosition(self.CellSize.x/2, -self.CellSize.y)
                if first then
                    a2:addChild(cellCCB)
                end
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.data)
        elseif fn == "cellTouched" then

            local celldata = self.data[tostring(1000+a1:getIdx()+1)]
            if celldata.buttonid and celldata.buttonid ~= 0 then
                GameScene:shiftLayerById(celldata.buttonid)
            end

        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.listview = ui.createLuaTableView({
        handle = chatListHandle,
        viewwidth =  self.rootItems.listscroll:getContentSize().width,
        viewheight =  self.rootItems.listscroll:getContentSize().height,
        dire = 1
    })
    self.listview:setTouchPriority(self.touchPriority)
    self.rootItems.listscroll:addChild(self.listview)
end

function post.close(self)
    if self.unrecycleCell.detailCell then
        self.unrecycleCell.detailCell.cell:release()
    end
    self.unrecycleCell = {}
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.listview = nil

    if self.callback then
        self.callback()
    end
end

--function post.setTitle(self,data,item,isdetail)
--    item.title:setString(data.title or "")
--    item.statussprite:setRotation(isdetail and 90 or 0)
--
--    item.newnode:setVisible(data.status and data.status == "new")
--    item.hotnode:setVisible(data.status and data.status == "hot")
--end
--
--function post.setContent(self,data,item,index)
--    item.content1:setString(data.content1 or "")
--    item.content2:setString(data.content2 or "")
--    item.content1:setPositionY(self.sizeT[index]-40)
--    item.content2:setPositionY(self.sizeT[index]-70)
--    item.content2:setDimensions(CCSizeMake(830,self.sizeT[index]))
--
--
--    if data.buttonid and data.buttonid > 0 then
--        item.button:setVisible(true)
--        item.buttontext:setVisible(true)
--        ui.setLabelString(item.buttontext,"前 往",18)
--        item.button:addHandleOfControlEvent(function()
--            if gameTouch.isScrollling then return end
--            GameScene:shiftLayerById(data.buttonid)
--        end, CCControlEventTouchUpInside)
--        item.button:setSwallowsTouch(true)
--        item.button:setTouchPriority(self.touchPriority-1)
--    else
--        item.button:setVisible(false)
--        item.buttontext:setVisible(false)
--    end
--end
--
--function post.findDetailHeight(self)
--    local label = ui.createLabel({
--        fontsize = 35,
--        font = "Helvetica-Bold",
--    })
--
--    label:setString("测试")
--    self.sizeT = {}
--
--    for i=1,table.getTableLength(self.data) do
----        local height = 0
--        print(string.len(self.data[tostring(1000+i)].content2))
----        label:setString(self.data[tostring(1000+i)].content2)
--        local h = label:getContentSize().height
----        local w = label:getContentSize().width
----
----        if w > 820 then
----            height = math.ceil(w/820)*h+190+20
----        else
----            height = h+190+20
----        end
--
--        local height =  math.ceil(string.len(self.data[tostring(1000+i)].content2)/70)*h+190+20
--
--        self.sizeT[i] = height
--    end
--
--    printT(self.sizeT,"self.sizeT")
--
--end
--
--function post.reload(self,data,callback)
--    self.callback = callback
--    self.data = gamedata.config.notice
--
--    ui.setLabelString(self.rootItems.buttontext,"确 定",19)
--    self.rootItems.button:addHandleOfControlEvent(function()
--        self.callback = nil
--        gameWindows:closeWindow("post")
--    end, CCControlEventTouchUpInside)
--    self.rootItems.button:setSwallowsTouch(true)
--    self.rootItems.button:setTouchPriority(self.touchPriority)
--
--    self:findDetailHeight()
--
--    local celldict = {}
--    local friendListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
--        local r
--        if fn == "cellSize" then
--
--        elseif fn == "hasFixedCellSize" then
--            r = false
--        elseif fn == "cellSizeForIndex" then
--            if self.Selected and self.Selected == a1+1 then
--
--                r = CCSizeMake(self.CellSize.x, self.sizeT[a1+1] +self.CellSize.y)
--            else
--                r = CCSizeMake(self.CellSize.x, self.CellSize.y)
--            end
--        elseif fn == "isRecycle" then
--            for k,v in pairs (self.unrecycleCell) do
--                if a2 == v.cell then
--                    print("unrecycleCELL ")
--                    return false
--                end
--            end
--            return true
--        elseif fn == "cellAtIndex" then
--
--            if self.Selected and self.Selected == a1+1 then
--                local ccb, items,ccb1, items1
--                if self.unrecycleCell.detailCell == nil then
--                    a2 = CCTableViewCell:create()
--                    ccb, items =  CCBReaderLoad("tanchuang/xitonggonggao_biaoti", nil, true, "xitonggonggao_biaoti")
--                    ccb1, items1 =  CCBReaderLoad("tanchuang/xitonggonggao_neirong", nil, true, "xitonggonggao_neirong")
--                    a2:addChild(ccb1)
--                    a2:addChild(ccb)
--                    self.unrecycleCell.detailCell={cell = a2, ccb =ccb, items=items,ccb1 =ccb1, items1=items1}
--                    self.unrecycleCell.detailCell.cell:retain()
--                else
--                    a2 = self.unrecycleCell.detailCell.cell
--                    ccb = self.unrecycleCell.detailCell.ccb
--                    items = self.unrecycleCell.detailCell.items
--                    ccb1 = self.unrecycleCell.detailCell.ccb1
--                    items1 = self.unrecycleCell.detailCell.items1
--                end
--                ccb:setPosition(self.CellSize.x/2, -self.CellSize.y)
--                ccb1:setPosition(self.CellSize.x/2, -self.sizeT[a1+1]-self.CellSize.y)
--                self:setTitle(self.data[tostring(1000+a1+1)],items,true)
--                self:setContent(self.data[tostring(1000+a1+1)],items1,a1+1)
--            else
--                local cellCCB,ccbDocumentControler = 0,0
--                local first = true
--                if not a2 then
--                    a2 = CCTableViewCell:create()
--                    cellCCB, ccbDocumentControler = CCBReaderLoad("tanchuang/xitonggonggao_biaoti", nil, true, "xitonggonggao_biaoti")
--                    celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
--                else
--                    first = false
--                    cellCCB = celldict[a2].cellCCB
--                    ccbDocumentControler = celldict[a2].ccbDocumentControler
--                end
--
--                self:setTitle(self.data[tostring(1000+a1+1)],ccbDocumentControler)
--
--                cellCCB:setPosition(self.CellSize.x/2, -self.CellSize.y)
--                if first then
--                    a2:addChild(cellCCB)
--                end
--            end
--
--            r = a2
--        elseif fn == "numberOfCells" then
--            r = table.getTableLength(self.data)
--        elseif fn == "cellTouched" then
--
--            local index = a1:getIdx()+1
--            local scrollH =  self.rootItems.listscroll:getContentSize().height
--            local num =  table.getTableLength(self.data)
--
--            print(index)
--
--            if self.Selected and self.Selected == index then
--                self.Selected = nil
--                self.listview:setLuaContentOffset(0, self.listview:getLuaContentOffsetY()+self.sizeT[index])
--            elseif self.Selected and self.Selected ~= index then
--                self.Selected = index
--                if self.CellSize.y*index + self.sizeT[index] < scrollH then
--                    self.listview:setLuaContentOffset(0,scrollH - self.CellSize.y*num - self.sizeT[index])
--                else
--                    self.listview:setLuaContentOffset(0, -self.CellSize.y*(num-index))
--                end
--            else
--                self.Selected = index
--                if self.CellSize.y*index + self.sizeT[index] < scrollH then
--                    print(scrollH,self.CellSize.y*num,self.sizeT[index])
--                    self.listview:setLuaContentOffset(0,scrollH - self.CellSize.y*num - self.sizeT[index])
--                else
--                    print(scrollH,self.CellSize.y*num,self.sizeT[index])
--                    self.listview:setLuaContentOffset(0, -self.CellSize.y*(num-index))
--                end
--            end
--
--
----            local location
----            self.Selected,location = ui.tableviewLocation(
----                self.listview,
----                table.getTableLength(self.data),
----                a1:getIdx()+1,
----                self.rootItems.listscroll,
----                self.Selected,
----                self.detailCellSize.y,
----                self.CellSize.y
----            )
--            self.listview:reloadData()
--            --self.listview:setLuaContentOffset(0,location)
--
--        elseif fn == "scrollViewDidScroll" then
--            --gameTouch.isScrollling = true
--        end
--        return r
--    end)
--
--    self.listview = ui.createLuaTableView({
--        handle = friendListHandle,
--        viewwidth = self.rootItems.listscroll:getContentSize().width,
--        viewheight = self.rootItems.listscroll:getContentSize().height,
--        dire = 1
--    })
--    self.listview:setTouchPriority(self.touchPriority)
--    self.rootItems.listscroll:addChild(self.listview)
--end
--
--function post.close(self)
--    if self.unrecycleCell.detailCell then
--        self.unrecycleCell.detailCell.cell:release()
--    end
--    self.unrecycleCell = {}
--    self.rootNode:removeAllChildrenWithCleanup(true)
--    self.rootNode:removeFromParentAndCleanup(true)
--    self.rootNode = nil
--    self.rootItems = nil
--
--    if self.callback then
--        self.callback()
--    end
--end

return posth6  