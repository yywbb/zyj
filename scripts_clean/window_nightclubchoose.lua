
--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/10
-- Time: 下午3:45
-- To change this template use File | Settings | File Templates.
--

local clubchoose = {
    root = nil,
    rootNode = nil,
    rootItems = nil,

    titleCellSize = {x = 1040, y = 230}
}


function clubchoose.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority
    self.callback = callback

    self.rootNode, self.rootItems = CCBReaderLoad("nightclub/nightclub_selectgeneral", nil, true, "clubchoose")

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        callback(nil)
        self.callback = nil
        gameWindows:closeWindow("clubchoose")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self:reloadTable(data)

    self.root:addChild(self.rootNode)
    return self.root
end

function clubchoose.reloadTable(self,destTable)
    self.NavigationTableView = nil
    self.realPageTable = destTable
    printT(self.realPageTable,"self.realPageTable  ---   ")
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
                cellCCB, items = CCBReaderLoad("nightclub/cell_selectgeneral", nil, true, "cell_selectgeneral")
                activityTable[a2] = {cellCCB=cellCCB,items=items }
                ui.tableviewAnimationH(self.NavigationTableView,cellCCB,self.titleCellSize.x, self.titleCellSize.y,a1)
            else
                first = false
                cellCCB = activityTable[a2].cellCCB
                items = activityTable[a2].items
            end

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

function clubchoose.setNormal(self,item,data,index,isChoose)
    -- 设置头像
    if data.illusionGeneralCid == nil then
        local configGeneral = gamedata.config.general[tostring(data.cid)]
        local gdata = ui.getConfigGeneral(data)
        if next(gdata) and configGeneral.fashion_id == 0 then    
            data.icon = gdata.icon
        end
    end
    ui.setNewIcon(item,data)

    -- item.power:setString("战斗力: "..data.power)
    item.num2:setString(tostring(data.power))
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

    
    -- item.level:setString("等级："..data.level1)
    -- item.aptitude:setString("资质："..(configdata.basic+configdata.grow))
    local configdata = gamedata.config.general[tostring(data.cid)]
    local tmpStr = ""
    if data.level2>13 then
        tmpStr = tmpStr..configdata.name..(data.level2>0 and " +"..data.level2 or "")
    else    
        tmpStr = tmpStr..configdata.name..(data.level2>0 and " +"..data.level2 or "")
    end
    tmpStr = tmpStr.."  "..gameConfig.strings:string_common("general",16)..data.level1
    item.name:setString(tmpStr)

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

    if not isChoose then
        item.showIsTrue:setVisible(false)
        item.showLable:setVisible(true)
        item.showButton:setVisible(true)
        item.showButton:setTouchPriority(self.touchPriority)
        item.showButton:setSwallowsTouch(true)
        item.showButton:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            self.callback(index)
            self.callback = nil
            gameWindows:closeWindow("clubchoose")
        end, CCControlEventTouchUpInside)
    else
        item.showIsTrue:setVisible(true)
        item.showLable:setVisible(false)
        item.showButton:setVisible(false)
    end


end

function clubchoose.close(self)  
    self.isscrolltouched = false    
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

return clubchoose