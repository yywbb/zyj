--
-- Author: songyibo
-- Date: 2021-03-18 13:40:24
--

local qilingSelect = {
    rootNode = nil,
    rootItems = nil,
    cellNorSize = {x=860,y=220},
    qilingSelect = nil,
    unrecycleCell = {},
    data = {},
    selectindex = 0,
    selectdatas = {},
    maxNum = 10,
}

function qilingSelect.open(self,touchPriority,data,callback)
    printT(data,"qilingSelect")

    self.rootNode, self.rootItems = CCBReaderLoad("zhuanshushenqi/tc_qilingronglianselect", nil, true, "tc_qilingxiangqianselect")
    self.touchPriority = touchPriority
    self.callback = callback

    self:makeData(data.data)
    self.selectdatas = data.selectdatas

    self.rootItems.closeBtn:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("qilingRefiningSelect")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeBtn:setSwallowsTouch(true)
    self.rootItems.closeBtn:setTouchPriority(self.touchPriority)


    for i=0,6 do
        self.rootItems["point"..i]:setVisible(self.selectindex == i)
        self.rootItems["button"..i]:addHandleOfControlEvent(function()

            if self.selectindex == i then
                return
            end

            self.qilingSelect = nil
            self.rootItems["point"..self.selectindex]:setVisible(false)
            self.rootItems["point"..i]:setVisible(true)
            self.selectindex = i
            self:reload()

        end, CCControlEventTouchUpInside)
        self.rootItems["button"..i]:setSwallowsTouch(true)
        self.rootItems["button"..i]:setTouchPriority(self.touchPriority)
    end

    ui.setLabelString(self.rootItems.doLab, nil, 19)
    self.rootItems.doButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("qilingRefiningSelect")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:setTouchPriority(self.touchPriority)

    self:reload()

    return self.rootNode
end

function qilingSelect.makeData(self,data)
    self.data = data
    for i,v in ipairs(self.data[0]) do
        local qiLingData = v
        local qilingConfig = gamedata.config.exclusive_device_spirit[tostring(qiLingData.cid)]
        qiLingData.quality = qilingConfig.quality
        qiLingData.randomAttrInfo = gameWindows.windows["qilingInfo"].module.getRandomAttrInfo(qiLingData)
        qiLingData.randomAttrInfo.fixedH = 150 + qiLingData.randomAttrInfo.lineNum * 40
    end

    -- printT(self.data,"qilingSelect")
end

function qilingSelect.reload(self)
    if not self.ListTableView then
        self:createList()
    else
        self.ListTableView:reloadData()
        local line = table.getTableLength(self.data[self.selectindex])
        self.ListTableView:setLuaContentOffset(0,  self.rootItems.listscroll:getContentSize().height - self.cellNorSize.y*line )
    end
    self.rootItems.gotonode:setScale(0.9)
    ui.setGoto(self.rootItems.gotonode,table.getTableLength(self.data[self.selectindex]) == 0,"qiling")
    self:updateSelectNum()
end



function qilingSelect.setNormal(self,items,index)
    local qiLingData = self.data[self.selectindex][index]
    local hight = qiLingData.randomAttrInfo.fixedH
    local useSize = hight + self.cellNorSize.y
	items.detalBtn:setTouchPriority(self.touchPriority - 1)
    items.detalBtn:setSwallowsTouch(true)
    items.detalBtn:addHandleOfControlEvent(function()
        local location
        self.qilingSelect,location = ui.tableviewLocation(
            self.ListTableView,
            #self.data[self.selectindex],
            index,
            self.rootItems.listscroll,
            self.qilingSelect,
            useSize,
            self.cellNorSize.y
        )
        self.ListTableView:reloadData()
        self.ListTableView:setLuaContentOffset(0,location)
    end, CCControlEventTouchUpInside)

    local qilingConfig = gamedata.config.exclusive_device_spirit[tostring(qiLingData.cid)]
    local intensifyConfig = gamedata.config.exclusive_device_spirit_intensify[tostring(qilingConfig.intensify_bonus_way)][tostring(qiLingData.level)]

    items.name:setString(qilingConfig.name)
    if qilingConfig.quality and qilingConfig.quality >= 7 then
        ui.setLabelString(items.name,nil, 213)
    else
        ui.setLabelString(items.name,nil,((qilingConfig.quality and qilingConfig.quality ~= 0) and qilingConfig.quality or 1)*2-1)
    end
    ui.setNewIcon(items, {cid = qiLingData.cid, num = qiLingData.level > 0 and "+"..qiLingData.level or "",ison = qiLingData.ison})

    local attrValue = qilingConfig.method == "percent" and qilingConfig.value * 100 or qilingConfig.value
    items.attr:setString(gameConfig.strings:attributeValue(qilingConfig.attribute,qilingConfig.method,attrValue))
    
    items.equipedNode:setVisible(false)
    items.selectNode:setVisible(true)
    items.doNode:setVisible(false)
    items.autosprite:setVisible(self:isQilingSelect(qiLingData))

    items.selectBtn:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        
        if self:isQilingSelect(qiLingData) then
            self:removeQilingSelect(qiLingData)
            items.autosprite:setVisible(false)
        else
            if self:insertQilingData(qiLingData) then
                items.autosprite:setVisible(true)
            end
        end
        self:updateSelectNum()
    end, CCControlEventTouchUpInside)
    items.selectBtn:setSwallowsTouch(true)
    items.selectBtn:setTouchPriority(self.touchPriority-1)

    items["i_button"]:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        gameWindows:openWindow("qilingInfo",{iid = qiLingData.iid,opt = 4})
    end, CCControlEventTouchUpInside)
    items["i_button"]:setSwallowsTouch(true)
    items["i_button"]:setTouchPriority(self.touchPriority-1)
end

function qilingSelect.insertQilingData(self,data)
    if #self.selectdatas >= self.maxNum then
        runGamePrompt({msg = "最多可选"..self.maxNum.."个"})
        return nil
    end
    table.insert(self.selectdatas,data)
    return true
end

function qilingSelect.updateSelectNum(self)
    self.rootItems.selectLab:setString(gameConfig.strings:string_common("exclusiveArtifactNew",13)..#self.selectdatas.."/"..self.maxNum)
end

function qilingSelect.isQilingSelect(self,data)
    
    for i,v in ipairs(self.selectdatas) do
        if v.iid == data.iid then
            return true
        end
    end
    return false
end

function qilingSelect.removeQilingSelect(self,data)
    for i,v in ipairs(self.selectdatas) do
        if v.iid == data.iid then
            table.remove(self.selectdatas,i)
            break
        end
    end
end

function qilingSelect.setDetail(self,items,index)
    items.randomAttrNode:removeAllChildrenWithCleanup(true)

    local qiLingData = self.data[self.selectindex][index]
    -- local lineH = 40
    -- local fixedH = 0
    -- for i=1,4 do
    --     if qiLingData.randomAttrInfo[i] then
    --         local randomAttrInfo = qiLingData.randomAttrInfo[i]
    --         items["r_attr_node"..i]:setVisible(true)
    --         items["r_attr_node"..i]:setPositionY(-70 - fixedH)
    --         items["r_attr_name"..i]:setString(randomAttrInfo.name)
    --         items["r_attr_desc"..i]:setString(randomAttrInfo.desc[1])
    --         items["r_attr_desc"..i]:setDimensions(CCSizeMake(items["r_attr_desc"..i]:getContentSize().width,lineH * randomAttrInfo.lineNum))
    --         fixedH = fixedH + lineH * randomAttrInfo.lineNum
    --     else
    --         items["r_attr_node"..i]:setVisible(false)
    --     end
    -- end
    local fixedH = 0
    local lineH = 40
    for i,v in ipairs(qiLingData.randomAttrInfo) do
        local lineNum = 0
        local node, items_random = CCBReaderLoad("zhuanshushenqi/cell_suijishuxing", nil, true, "cell_suijishuxing")
        node:setPositionY(-fixedH)
        items.randomAttrNode:addChild(node)
        items_random["r_attr_tipnode"]:setVisible(false)
        items_random["r_attr_name"]:setString(qiLingData.randomAttrInfo[i].name)
        ui.createRichLabel({
            {fontID = 1031,content = qiLingData.randomAttrInfo[i].desc[1]},
            {fontID = 1032,content = qiLingData.randomAttrInfo[i].desc[2]},
        },items_random["r_attr_desc"],false,{min_line_dis = 2})
        fixedH = fixedH + qiLingData.randomAttrInfo[i].lineNum * lineH
    end

    items["r_attr_bg"] = tolua.cast(items["r_attr_bg"], "CCScale9Sprite")
    items["r_attr_bg"]:setPreferredSize(CCSizeMake(800,qiLingData.randomAttrInfo.fixedH))
end

function qilingSelect.createList(self)
    printT(self.data,"qilingSelect_createList")
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then

        elseif fn == "hasFixedCellSize" then
            r = false
        elseif fn == "cellSizeForIndex" then
            if self.qilingSelect and self.qilingSelect == a1+1 then
                local qiLingData = self.data[self.selectindex][a1+1]
                r = CCSizeMake(self.cellNorSize.x, self.cellNorSize.y + qiLingData.randomAttrInfo.fixedH)
            else
                r = CCSizeMake(self.cellNorSize.x, self.cellNorSize.y)
            end
        elseif fn == "isRecycle" then
            for k,v in pairs (self.unrecycleCell) do
                if a2 == v.cell then
                    return false
                end
            end
            return true
        elseif fn == "cellAtIndex" then
            if self.qilingSelect and self.qilingSelect == a1+1 then
                local ccb, items,ccb1, items1
                if self.unrecycleCell.detailCell == nil then
                    a2 = CCTableViewCell:create()
                    ccb, items =  CCBReaderLoad("zhuanshushenqi/cell_qilingselect", nil, true, "cell_qilingselect")
                    ccb1, items1 =  CCBReaderLoad("zhuanshushenqi/cell_qilingselect_pop", nil, true, "cell_qilingselect_pop")

                    ccb1:setPosition(self.cellNorSize.x/2, -self.cellNorSize.y)
                    a2:addChild(ccb1)
                    ccb:setPosition(self.cellNorSize.x/2, -self.cellNorSize.y)
                    a2:addChild(ccb)
                    self.unrecycleCell.detailCell={cell = a2, ccb =ccb, items=items,ccb1 =ccb1, items1=items1}
                    self.unrecycleCell.detailCell.cell:retain()
                else
                    a2 = self.unrecycleCell.detailCell.cell
                    ccb = self.unrecycleCell.detailCell.ccb
                    items = self.unrecycleCell.detailCell.items
                    ccb1 = self.unrecycleCell.detailCell.ccb1

                    ccb1:setPosition(self.cellNorSize.x/2, -self.cellNorSize.y)
                    items1 = self.unrecycleCell.detailCell.items1
                end

                self:setNormal(items,a1+1)
                self:setDetail(items1,a1+1)
            else
                local cellCCB,ccbDocumentControler = 0,0
                local first = true
                if not a2 then
                    a2 = CCTableViewCell:create()
                    cellCCB, ccbDocumentControler = CCBReaderLoad("zhuanshushenqi/cell_qilingselect", nil, true, "cell_qilingselect")
                    celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                else
                    first = false
                    cellCCB = celldict[a2].cellCCB
                    ccbDocumentControler = celldict[a2].ccbDocumentControler
                end
                cellCCB:setPosition(self.cellNorSize.x/2, -self.cellNorSize.y)
                self:setNormal(ccbDocumentControler,a1+1)
                if first then
                    a2:addChild(cellCCB)
                end
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = #self.data[self.selectindex]
        elseif fn == "cellTouched" then
        elseif fn == "scrollViewDidScroll" then

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

function qilingSelect.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback(self.selectdatas)
        self.callback = nil
    end
    if self.unrecycleCell.detailCell then
        self.unrecycleCell.detailCell.cell:release()
    end
    self.qilingSelect = nil
    self.unrecycleCell = {}
    self.ListTableView = nil
    self.data = {}
    self.selectindex = 0
    self.selectdatas = {}
end

return qilingSelect
  �3  