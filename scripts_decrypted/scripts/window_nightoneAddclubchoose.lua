

local oneAddclubchoose = {
    root = nil,
    rootNode = nil,
    rootItems = nil,
    selectData = {},
    maxNum = 1,

    titleCellSize = {x = 1040, y = 230},

}

function oneAddclubchoose.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority
    self.callback = callback

    self.rootNode, self.rootItems = CCBReaderLoad("nightclub/nightclub_selectgeneral2", nil, true, "oneAddclubchoose")
    self:initFixedString()

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("oneAddclubchoose")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.showButton:addHandleOfControlEvent(function()
        if self.callback then
            local data = {}
            for k,v in pairs(self.selectData) do
                table.insert(data,v)
            end
            self.callback(data)
            self.callback = nil
        end
        gameWindows:closeWindow("oneAddclubchoose")

    end, CCControlEventTouchUpInside)
    self.rootItems.showButton:setSwallowsTouch(true)
    self.rootItems.showButton:setTouchPriority(self.touchPriority)
    self.maxNum = data.num or 1
    self.rootItems.generalsnumLab:setString(gameConfig.strings:friendnightStr3(0,self.maxNum))

    for i,v in pairs(data.generals) do
        if v.selectSpr then
            self.selectData[tostring((v.cid or "")..(v.iid or ""))] = i
            self:setSelectNum()
        end
    end

    self:reloadTable(data.generals)
    self.root:addChild(self.rootNode)
    return self.root
end

function oneAddclubchoose.reloadTable(self,destTable)
    printT(destTable,"destTable   ---    ")
    self.NavigationTableView = nil
    self.realPageTable = destTable
    local activityTable = {}
    local NavigationHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.titleCellSize.x, self.titleCellSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,items = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, items = CCBReaderLoad("nightclub/cell_selectgeneral2", nil, true, "cell_selectgeneral2")
                activityTable[a2] = {cellCCB=cellCCB,items=items }
                ui.tableviewAnimationH(self.NavigationTableView,cellCCB,self.titleCellSize.x, self.titleCellSize.y,a1)
            else
                first = false
                cellCCB = activityTable[a2].cellCCB
                items = activityTable[a2].items
            end
            self:initFixedStringForCell(items)

            self:setNormal(items,self.realPageTable[tostring(a1+1)],a1+1,self.realPageTable[tostring(a1+1)].isClub)

            cellCCB:setAnchorPoint(ccp(0.5, 0.5))
            cellCCB:setScale(1)
            if self.NavigationTableView then
                cellCCB:setPosition(self.titleCellSize.x/2,self.titleCellSize.y/2)
            end
            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.realPageTable)
        elseif fn == "cellTouched" then
        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)
    self.NavigationTableView = ui.createLuaTableView({
        handle = NavigationHandle,
        viewwidth = self.rootItems.m_oTableView:getContentSize().width,
        viewheight = self.rootItems.m_oTableView:getContentSize().height,
        dire = 1
    })
    self.rootItems.m_oTableView:addChild(self.NavigationTableView)
    self.NavigationTableView:setTouchPriority(self.touchPriority)
end

function oneAddclubchoose.setNormal(self,item,data,index,isChoose)
    -- 设置头像
    if data.illusionGeneralCid == nil then
        local configGeneral = gamedata.config.general[tostring(data.cid)]
        local gdata = ui.getConfigGeneral(data)
        if next(gdata) and configGeneral.fashion_id == 0 then    
            data.icon = gdata.icon
        end
    end
    ui.setNewIcon(item,data)

    --ui.setLabelString(item.num2,tostring(data.power),47)
    item.num2:setString(data.power)
    if data.ison == 2 then
        item.shuxing:setString(gameConfig.strings:string_common("nightclub",19))
    elseif data.ison == 1 then
        item.shuxing:setString(gameConfig.strings:string_common("nightclub",18))
    else
        item.shuxing:setString("")
    end

    if data.quality >= 6 then
        item.hunpo:setString(gameConfig.strings:string_common("nightclub",44)..data.hunponum)
    else
        item.hunpo:setString(gameConfig.strings:string_common("nightclub",20)..data.hunponum)
    end
    
    local configdata = gamedata.config.general[tostring(data.cid)]
    local tmpStr = ""
    if data.level2>13 then
        tmpStr = tmpStr..configdata.name..(data.level2>0 and " +"..data.level2 or "")
    else    
        tmpStr = tmpStr..configdata.name..(data.level2>0 and " +"..data.level2 or "")
    end
    tmpStr = tmpStr.."  "..gameConfig.strings:string_common("general",16)..data.level1
    ui.setLabelString(item.name,tmpStr,18)

    if data.skilllevel > 0 and configdata.awaken > 0  then
        item.juexing_icon:setVisible(true)
        item.juexing_name:setVisible(true)
        item.name:setPositionX(310)
        setSpriteFrameByName(item.juexing_icon,gamedata.config.general_awaken[tostring(data.skilllevel)].icon)
        ui.setLabelString(item.juexing_name,gamedata.config.general_awaken[tostring(data.skilllevel)].stage,18)        
    else
        item.juexing_icon:setVisible(false)
        item.juexing_name:setVisible(false)
        item.name:setPositionX(240)
    end 

    if data.selectSpr and data.selectSpr == 1 then
        item.attrstatus2:setVisible(true)
        self.selectData[tostring((data.cid or "")..(data.iid or ""))] = index
        --self:setSelectNum()
    else
        item.attrstatus2:setVisible(false)
        self.selectData[tostring((data.cid or "")..(data.iid or ""))] = nil
    end


    if not isChoose then
        item.showIsTrueNode:setVisible(false)
        item.showSureNode:setVisible(true)

        item.attrButton2:setTouchPriority(self.touchPriority)
        item.attrButton2:setSwallowsTouch(true)
        item.attrButton2:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            if self.selectData[tostring((data.cid or "")..(data.iid or ""))] then
                self.selectData[tostring((data.cid or "")..(data.iid or ""))] = nil
                data.selectSpr = nil
                item.attrstatus2:setVisible(false)
            else
                if table.getTableLength(self.selectData) < self.maxNum then
                    self.selectData[tostring((data.cid or "")..(data.iid or ""))] = index
                    data.selectSpr = 1
                    item.attrstatus2:setVisible(true)
                else
                    --runGamePrompt({msg = "最多可选"..self.maxNum.."个"})
                    runGamePrompt({msg = gameConfig.strings:xzNum(self.maxNum)})
                end
            end
            self:setSelectNum()
        end, CCControlEventTouchUpInside)

    else
        item.showIsTrueNode:setVisible(true)
        item.showSureNode:setVisible(false)
    end


end

function oneAddclubchoose.setSelectNum(self)
    local num = 0
    if next(self.selectData) then
        num = table.getTableLength(self.selectData)
    end
    --self.rootItems.generalsnumLab:setString("当前已选择勇士："..num.."/"..self.maxNum)
    self.rootItems.generalsnumLab:setString(gameConfig.strings:friendnightStr3(num,self.maxNum))
end


function oneAddclubchoose.close(self)  
    self.isscrolltouched = false    
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.maxNum = 1
    self.selectData = {}
    if self.callback then
        self.callback = nil
    end

end

function oneAddclubchoose.initFixedString(self) 
    
    ui.setLabelString(self.rootItems.showLable,gameConfig.strings:string_common("fixedString","nightclub",23),18)
end

function oneAddclubchoose.initFixedStringForCell(self,items) 
end



return oneAddclubchoose   �!  