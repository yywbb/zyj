
local guardrewardview = {
    rootNode = nil,
    rootItems = nil,
    ListTableView = nil,
    normalCellSize = {x=880,y=230},
}

function guardrewardview.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("gonghui2/shouweijiangli", nil, true, "shouweijiangli")
    self:initFixedString()
    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function guardrewardview.reload(self,data,callback)
    self.callback = callback
    self.data = data

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("guardrewardview")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.scorenum,self.data.totalScore,14)
    -- self.rewarddata = gamedata.config.guild_box or {}

    local showTable = {}
    for k,v in pairs(gamedata.config.guild_box) do
        v.sortId = v.id
        if self.data.boxstatus[tostring(v.id)] == 2 then
            v.sortId = v.sortId + 100
        end
        table.insert(showTable,v)
    end

    local sortfunc = function(a,b)
        if a["sortId"] < b["sortId"] then
            return true
        else
            return false
        end
    end
    table.sort(showTable,sortfunc)
    self.rewarddata = showTable

    print("::guardrewardview.reload:::")
    printT(self.rewarddata)
    if not self.ListTableView then
        self:createTable()
    else
        self.ListTableView:reloadData()
    end
    --self.ListTableView:setLuaContentOffset(0,self.rootItems.listnode:getContentSize().height-(table.getTableLength(self.rewarddata)-self.data.level+1)*self.normalCellSize.y)

end

function guardrewardview.createTable( self,data )
    
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(930, 210)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("gonghui2/cell_shouweijiangli", nil, true, "cell_shouweijiangli")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCell(ccbDocumentControler,self.rewarddata[a1+1],a1+1)
            --
            cellCCB:setPosition(self.normalCellSize.x/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.rewarddata)
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
    self.rootItems.listnode:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(self.touchPriority)
end

function guardrewardview.setCell(self,item,data,index)
    item.scoreLab:setString(gameConfig.strings:string_common("guild_guard",24)..data.files)
    local rewardDetail = ui.getIDandNUMs(data.box)
    for i=1,4 do
        if rewardDetail[i] then
            item["reward"..i]:setVisible(true)
            ui.setNewIcon(item,{cid = rewardDetail[i].cid,num = rewardDetail[i].num},i-1)
        else
            item["reward"..i]:setVisible(false)
        end
    end

    if self.data.boxstatus[tostring(data.id)] == 0 then
        item.getNode:setVisible(false)
        item.nonenode:setVisible(true)
        item.receivedNode:setVisible(false)
    elseif self.data.boxstatus[tostring(data.id)] == 1 then
        item.getNode:setVisible(true)
        item.nonenode:setVisible(false)
        item.receivedNode:setVisible(false)
    elseif self.data.boxstatus[tostring(data.id)] == 2 then
        item.getNode:setVisible(false)
        item.nonenode:setVisible(false)
        item.receivedNode:setVisible(true)
    end

    ui.setLabelString(item.gettext,gameConfig.strings:string_common("guild_guard",21),19)

    item.getbutton:addHandleOfControlEvent(function()
        UIRequest({type = 5154, pos = data.id})
    end, CCControlEventTouchUpInside)
    item.getbutton:setSwallowsTouch(true)
    item.getbutton:setTouchPriority(self.touchPriority-1)

end

function guardrewardview.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.ListTableView = nil

    if self.callback then
        self.callback()
    end
end

function guardrewardview.initFixedString( self )


end

return guardrewardview

