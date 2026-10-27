local daoGuanFightNote = {
    rootNode = nil,
    rootItems = nil,
    systemListTableView = nil,
    playerListTableView = nil,
    normalCellSize = {x=900, y=60},
}

-- 打开道馆战报窗口
function daoGuanFightNote.open(self, touchPriority, data, callback)
    self.rootNode, self.rootItems = CCBReaderLoad("daoguanshouwei/daoguanshouwei_zhanbao", nil, true, "shouweijiangli")
    self:initFixedString()
    self.touchPriority = touchPriority
    self:initEvent()
    self.rootItems.systemNode:setVisible(false)
    self.rootItems.individualNode:setVisible(true)
    self.rootItems.systemContent:setVisible(false)
    self.rootItems.individualContent:setVisible(true)
    self:reload(data, callback)

    return self.rootNode
end

-- 道馆战报点击事件
function daoGuanFightNote.initEvent(self)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("daoGuanFightNote")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.systemBtn:addHandleOfControlEvent(function()
        self.rootItems.systemNode:setVisible(true)
        self.rootItems.individualNode:setVisible(false)
        self.rootItems.systemContent:setVisible(true)
        self.rootItems.individualNode:setVisible(false)
        self.rootItems.systemContent:setPositionX(90)
        self.rootItems.individualContent:setPositionX(9999)
    end, CCControlEventTouchUpInside)
    self.rootItems.systemBtn:setSwallowsTouch(true)
    self.rootItems.systemBtn:setTouchPriority(self.touchPriority)

    self.rootItems.individualBtn:addHandleOfControlEvent(function()
        self.rootItems.systemNode:setVisible(false)
        self.rootItems.individualNode:setVisible(true)
        self.rootItems.systemContent:setVisible(false)
        self.rootItems.individualNode:setVisible(true)
        self.rootItems.systemContent:setPositionX(9999)
        self.rootItems.individualContent:setPositionX(90)
    end, CCControlEventTouchUpInside)
    self.rootItems.individualBtn:setSwallowsTouch(true)
    self.rootItems.individualBtn:setTouchPriority(self.touchPriority)
end

-- 道馆战报回调刷新界面
function daoGuanFightNote.reload(self, data, callback)
    printT(data, "daoGuanFightNote data ")
    self.data = data

    self.rootItems.systemContent:setPositionX(9999)
    self.rootItems.individualContent:setPositionX(90)
    
    self:getPlayerSizeTable()
    --创建表
    if self.playerTableView then
        self.playerTableView:reloadData()
        self.playerTableView:setLuaContentOffset(0, self.rootItems.individualContent:getContentSize().height - self.allsizeH)
    else
        self:createList()
    end

    --创建richlabel 和创建表
    self:getSystemSizeTable()
    --创建表
    if self.systemListTableView then
        self.systemListTableView:reloadData()
        self.systemListTableView:setLuaContentOffset(0, self.rootItems.systemContent:getContentSize().height - self.allsizeH)
    else
        self:createSystemList()
    end
end

--
function daoGuanFightNote.getPlayerSizeTable(self)
    self.allsizeH = 0
    self.playerT = {}

    for i= 1, table.getTableLength(self.data.playerData) do
        if self.data.playerData[tostring(i)] and self.data.playerData[tostring(i)] ~= "" then
            local legionRichData = self.data.playerData[tostring(i)]
            local str = gameConfig.strings:daoguanZhanbaoRichLabel(legionRichData)
            local container = CCNode:create()
            container:setAnchorPoint(ccp(0,1))
            container:setContentSize(CCSizeMake(900,20))
            container:retain()
            self.playerT[i] = {
                height = ui.createRichLabel(str,container,false) + 20,
                container = container
            }
            self.allsizeH = self.allsizeH + self.playerT[i].height
        end
    end
end

function daoGuanFightNote.getSystemSizeTable(self)
    self.allsizeH = 0
    self.systemT = {}
    
    for i= 1, table.getTableLength(self.data.systemData) do
        if self.data.systemData[tostring(i)] and self.data.systemData[tostring(i)] ~= "" then
            local legionRichData = self.data.systemData[tostring(i)]
            local str = gameConfig.strings:daoguanZhanbaoRichLabel(legionRichData)
            local container = CCNode:create()
            container:setAnchorPoint(ccp(0,1))
            container:setContentSize(CCSizeMake(900,20))
            container:retain()
            self.systemT[i] = {
                height = ui.createRichLabel(str,container,false) + 20,
                container = container
            }
            self.allsizeH = self.allsizeH + self.systemT[i].height
        end
    end
end


--创建表
function daoGuanFightNote.createList(self)
    print("createList")
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn,myTable,a1,a2)
        local r
        if fn == "cellSize" then
            --r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "hasFixedCellSize" then
            r = false
        elseif fn == "cellSizeForIndex" then
            r = CCSizeMake(self.normalCellSize.x, self.playerT[a1+1].height)
        elseif fn == "isRecycle" then
            return false
        elseif fn == "cellAtIndex" then
            local cellCCB = 0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB = self.playerT[a1+1].container

                celldict[a2] = {cellCCB = cellCCB}
            else
                first =false
                cellCCB = celldict[a2].cellCCB
            end
            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.playerT)
        elseif fn == "scrollViewDidScroll" then

        end

        return r
    end)
    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.individualContent:getContentSize().width,
        viewheight = self.rootItems.individualContent:getContentSize().height,
        dire = 1
    })
    self.rootItems.individualContent:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(self.touchPriority-1)
end

--创建表
function daoGuanFightNote.createSystemList(self)
    print("createSystemList")
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn,myTable,a1,a2)
        local r
        if fn == "cellSize" then
            --r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "hasFixedCellSize" then
            r = false
        elseif fn == "cellSizeForIndex" then
            r = CCSizeMake(self.normalCellSize.x, self.systemT[a1+1].height)
        elseif fn == "isRecycle" then
            return false
        elseif fn == "cellAtIndex" then
            local cellCCB = 0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB = self.systemT[a1+1].container

                celldict[a2] = {cellCCB = cellCCB}
            else
                first =false
                cellCCB = celldict[a2].cellCCB
            end
            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.systemT)
        elseif fn == "scrollViewDidScroll" then

        end

        return r
    end)
    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.systemContent:getContentSize().width,
        viewheight = self.rootItems.systemContent:getContentSize().height,
        dire = 1
    })
    self.rootItems.systemContent:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(self.touchPriority-1)
end

-- 道馆战报关闭按钮
function daoGuanFightNote.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.playerListTableView = nil
    self.systemListTableView = nil

    if self.callback then
        self.callback()
    end
end

function daoGuanFightNote.initFixedString( self )

end

return daoGuanFightNote!  