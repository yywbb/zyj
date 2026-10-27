
local fashionPreview = {
    rootNode = nil,
    rootItems = nil,
    cellSize = {width = 940,height = 100},
    ListTableView = nil,
    upList = {},
    cover_id = 0,
    level = 1,
}

function fashionPreview.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("shizhuang/shizhuang_qianghuayulan", nil, true, "fashionPreview")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function fashionPreview.reload(self,data,callback)
    self.callback = callback
    --
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("fashionPreview")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    --
    if not data then return end
    --
    self.level = data.level or 1
    self.cover_id = data.cover_id or 0
    ui.setLabelString(self.rootItems.levelLab,nil,14)
    ui.setLabelString(self.rootItems.level,data.level or 1,14)
    --
    self.upList = {}
    local upconfigall = gamedata.config.fashionintentify and gamedata.config.fashionintentify[tostring(data.cover_id)] or {}
    for i = 1, table.getTableLength(upconfigall) do
        if upconfigall[tostring(i)] and upconfigall[tostring(i)]["add_attribute"] and upconfigall[tostring(i)]["add_attribute"] ~= "" then
            local attr,num = ui.getATTRandNUM(upconfigall[tostring(i)]["add_attribute"])
            table.insert(self.upList,{level = i, attr = attr, num = num})
        end
    end
    --
    self:createList()
end

function fashionPreview.close(self)
    self.cover_id = 0
    self.level = 1
    self.upList = {}
    self.ListTableView = nil
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

function fashionPreview.createList(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.cellSize.width, self.cellSize.height)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("shizhuang/cell_shizhuangup", nil, true, "cell_shizhuangup")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            cellCCB:setPosition(self.cellSize.width/2, 0)

            ui.setLabelString(ccbDocumentControler.y_name,"强化到"..self.upList[a1+1].level.."级",14)
            ui.setLabelString(ccbDocumentControler.y_attr,"强化属性:  "..(gameConfig.strings.attr_type[self.upList[a1+1].attr] or "").." +"..self.upList[a1+1].num,14)
            if self.level >= self.upList[a1+1].level then
                ccbDocumentControler.y_activate_yes:setVisible(true)
                ccbDocumentControler.y_activate_no:setVisible(false)
            else
                ccbDocumentControler.y_activate_yes:setVisible(false)
                ccbDocumentControler.y_activate_no:setVisible(true)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.upList)
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
    self.ListTableView:setTouchPriority(self.touchPriority)
    self.rootItems.listnode:addChild(self.ListTableView)
end

return fashionPreview

