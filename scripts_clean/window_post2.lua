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

    ListTableView = nil,

    CellSize = {x=800,y=255},

    unrecycleCell = {},

    celldict = {},
    sizeT = {},

    timelocation={
        [1] = 184,
        [2] = 544,
    },
    Selected = 1,
}

function post.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("post2/post_new", nil, true, "post")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    self.callback = callback

    return self.rootNode
end

function post.reload(self,data,callback)
    self.rootItems.button:addHandleOfControlEvent(function()
        gameWindows:closeWindow("post")
    end, CCControlEventTouchUpInside)
    self.rootItems.button:setSwallowsTouch(true)
    self.rootItems.button:setTouchPriority(self.touchPriority)

    self:getSizeTable()
    self:getNewTable()
    self:createListView()
end

function post.getSizeTableatIndex(self,index)
   if not self.sizeT[index] then
       local data = self.data[index]
       local str = {}
       table.insert(str,{fontID = 1000,content = data.title_time})
       table.insert(str,{fontID = 1000,content = data.content})
       table.insert(str,{fontID = 1000,content = data.reward})
       local container = CCNode:create()
       container:setAnchorPoint(ccp(0.5,1))
       container:setContentSize(CCSizeMake(600,200))
       container:retain()
       self.sizeT[index]={
           height = ui.createRichLabel(str,container,true)+160,
           container = container
       }

   end
   return self.sizeT[index]
end

function post.getNewTable(self)
    if not self.data then return end
    for i = #self.data,1,-1 do
        if GameScene.openactivityinpost and GameScene.openactivityinpost[tostring(self.data[i].button)] and GameScene.openactivityinpost[tostring(self.data[i].button)] == 0 then
            table.remove(self.data,i)
        end
    end
end

function post.getSizeTable(self)
    if self.data and next(self.data) then return end

    self.data = {}

    local todaydata = os.date("%Y%m%d%H%M%S", gamedata:time())

    print("post.reload")
    print(todaydata)
    for k,v in pairs(gamedata.config.notice_3) do
        if v.type == 1 then
            table.insert(self.data,v)
        elseif tonumber(todaydata)>tonumber(v.param1) and tonumber(todaydata)<tonumber(v.param2) then
            table.insert(self.data,v)
        end
    end

    local rankSort = function( a, b )
        return a.display < b.display
    end
    table.sort( self.data, rankSort )

    print("next is =")
    printT(self.data)



--    for i=1,table.getTableLength(self.data or data) do
--        local str = {}
--        table.insert(str,{fontID = 14,content = self.data[tonumber(i)].title_time})
--        table.insert(str,{fontID = 14,content = self.data[tonumber(i)].content})
--        table.insert(str,{fontID = 14,content = self.data[tonumber(i)].reward})
--        local container = CCNode:create()
--        container:setAnchorPoint(ccp(0.5,1))
--        container:setContentSize(CCSizeMake(730,200))
--        container:retain()
--        self.sizeT[i]={
--            height = ui.createRichLabel(str,container,true)+160,
--            container = container
--        }
--    end
--    printT(self.sizeT)
end

function post.createListView( self )
    self.celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            -- r = CCSizeMake(940, 260)
        elseif fn == "hasFixedCellSize" then
            r = false
        elseif fn == "cellSizeForIndex" then
            if self.Selected and self.Selected == a1+1 then
                local sizet = self:getSizeTableatIndex(a1+1)
                r = CCSizeMake(self.CellSize.x, self.CellSize.y + sizet.height)
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
            if self.Selected and self.Selected == a1+1 then
                local sizet = self:getSizeTableatIndex(a1+1)

                local ccb, items,ccb1, items1
--                if self.unrecycleCell.detailCell == nil then
                    a2 = CCTableViewCell:create()
                    ccb, items =  CCBReaderLoad("post2/cell_post_new", nil, true, "cell_post_new")
                    ccb1, items1 =  CCBReaderLoad("post2/cell_post_xiala_new", nil, true, "cell_post_xiala_new")
                    if a1 + 1 > 1 then
                        ccb1:setPosition(self.CellSize.x/2+60, -self.CellSize.y - sizet.height + (a1)*15)
                        ccb:setPosition(self.CellSize.x/2, -self.CellSize.y + (a1)*15)
                    else
                        ccb1:setPosition(self.CellSize.x/2+60, -self.CellSize.y - sizet.height)
                        ccb:setPosition(self.CellSize.x/2, -self.CellSize.y)                        
                    end
                    a2:addChild(ccb1)
                    a2:addChild(ccb)

                    self.unrecycleCell.detailCell={cell = a2}
--                    self.unrecycleCell.detailCell.cell:retain()
--                else
--                    a2 = self.unrecycleCell.detailCell.cell
--                    ccb = self.unrecycleCell.detailCell.ccb
--                    items = self.unrecycleCell.detailCell.items
--                    ccb1 = self.unrecycleCell.detailCell.ccb1
--                    items1 = self.unrecycleCell.detailCell.items1
--                end

                local dataconfig = self.data[tonumber(a1+1)]

                items.activityNameLabel:setString(dataconfig.title_content)
                local pic = string.gsub(dataconfig.pic,"p_","post_")
                setSpriteFrameByName(items.bg,pic)

                print("buttonid==",dataconfig.button)
                if tonumber(dataconfig.button) ~= 0 then
                    items1.gotoBtn:setVisible(true)
                    items1.gotoBtn:setSwallowsTouch(true)
                    items1.gotoBtn:setTouchPriority(self.touchPriority-1)
                    items1.gotoBtn:addHandleOfControlEvent(function()
                        print("i..am...gotoBtn..")
                        GameScene:shiftLayerById(tonumber(dataconfig.button))

                    end, CCControlEventTouchUpInside)
                else
                    items1.gotoBtn:setVisible(false)
                end

                items1.bg = tolua.cast(items1.bg, "CCScale9Sprite")
                items1.bg:setPreferredSize(CCSizeMake(630,sizet.height+30))
                items1.labelnode:removeAllChildrenWithCleanup(true)
                items1.labelnode:addChild(sizet.container)
                items1.labelnode:setPositionY(sizet.height-20)
            else
                local cellCCB,ccbDocumentControler = 0,0
                local first = true
                if not a2 then
                    a2 = CCTableViewCell:create()
                    cellCCB, ccbDocumentControler = CCBReaderLoad("post2/cell_post_new", nil, true, "cell_post_new")
                    self.celldict[a2] = {cell = a2,cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                else
                    first = false
                    cellCCB = self.celldict[a2].cellCCB
                    ccbDocumentControler = self.celldict[a2].ccbDocumentControler
                end
                local dataconfig = self.data[tonumber(a1+1)]
                
                ccbDocumentControler.activityNameLabel:setString(dataconfig.title_content)
                local pic = string.gsub(dataconfig.pic,"p_","post_")
                setSpriteFrameByName(ccbDocumentControler.bg,pic)
                if a1+1 > 1 then
                    cellCCB:setPosition(self.CellSize.x/2,-self.CellSize.y + (a1)*15)
                else
                    cellCCB:setPosition(self.CellSize.x/2,-self.CellSize.y)
                end
                

                if first then
                    a2:addChild(cellCCB)
                end
            end
            
            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.data)
        elseif fn == "cellTouched" then

            local index = a1:getIdx()+1
            local scrollH =  self.rootItems.listscroll:getContentSize().height
            local num =  table.getTableLength(self.data)

            local sizet = self:getSizeTableatIndex(index)
            local detailH = sizet.height

            print(index)

            if self.Selected and self.Selected == index then
                self.Selected = nil
                if (self.ListTableView:getLuaContentOffsetY()) > (scrollH - self.CellSize.y*num) then
                    self.ListTableView:setLuaContentOffset(0, 0)
                else
                    self.ListTableView:setLuaContentOffset(0, self.ListTableView:getLuaContentOffsetY()+detailH)
                end
            elseif self.Selected and self.Selected ~= index then
                self.Selected = index
                if self.CellSize.y*index + detailH < scrollH then
                    self.ListTableView:setLuaContentOffset(0,scrollH - self.CellSize.y*num - detailH)
                else
                    self.ListTableView:setLuaContentOffset(0, -self.CellSize.y*(num-index))
                end
            else
                self.Selected = index
                if self.CellSize.y*index + detailH < scrollH then
                    --print(scrollH,self.CellSize.y*num,detailH)
                    self.ListTableView:setLuaContentOffset(0,scrollH - self.CellSize.y*num - detailH)
                else
                    --print(scrollH,self.CellSize.y*num,detailH)
                    self.ListTableView:setLuaContentOffset(0, -self.CellSize.y*(num-index))
                end
            end

            self.ListTableView:reloadData()
        elseif fn == "scrollViewDidScroll" then
            self.isScroll = true
        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listscroll:getContentSize().width,
        viewheight = self.rootItems.listscroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.listscroll:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(self.touchPriority)
end

function post.close(self)
--    if self.unrecycleCell.detailCell then
--        self.unrecycleCell.detailCell.cell:release()
--    end
--    self.unrecycleCell = {}
    for k,v in pairs(self.sizeT) do
        v.container:release()
    end
    self.sizeT = {}
    self.Selected = 1

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.ListTableView = nil

    if self.callback then
        self.callback()
    end
end


return post