--
-- 工会战城池详细信息 treasureInfo
-- User: zhangzhixin
-- Date: 2016/1/26
-- To change this template use File | Settings | File Templates.
--
--
local windowTreasureCheckList = {
    rootNode = nil,
    rootItems = nil,
    CellSize = {x =  930,y =80 },
    png = {
        [1] = "gonghuizhan_yibaoming.png",
        [2] = "gonghuizhan_weibaoming.png",

    },
}
--
function windowTreasureCheckList.open( self,touchPriority,data,callback )
    print("windowTreasureCheckList =======")
    printT(data,"sdfasfsafdasf=====")
    self.touchPriority = touchPriority
    self.root = CCNode:create()
    self.rootNode, self.rootItems = CCBReaderLoad("gonghuizhan/tc_chakanbaoming", nil, true, "treasureList")
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("guildtreasurechecklist")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.rootItems.closeButton:setSwallowsTouch(true)         
    self.root:addChild(self.rootNode)
    self.guildid = data.guildid
    -- 
    self:loadTreasureCheckList(data)
    return self.root
end
--
function windowTreasureCheckList.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end
--listscroll
function windowTreasureCheckList.loadTreasureCheckList( self,aiData )
    print("windowTreasureList.loadTreasureList ========")

    self.data = aiData
    if  self.guildid == 0 or self.guildid == "0" then
        ui.setLabelString(self.rootItems.condition,gameConfig.strings:string_common("guild_treasureinfo",9),23)
        self.rootItems.conditionDesc:setString(gameConfig.strings:string_common("guild_treasureinfo",21))
    else
        ui.setLabelString(self.rootItems.condition,gameConfig.strings:string_common("guild_treasureinfo",8),23)
        self.rootItems.conditionDesc:setString(gameConfig.strings:string_common("guild_treasureinfo",20))        
    end
    if aiData.treasureChechList.isSignUp == 1 then
        setSpriteFrameByName(self.rootItems.isSignUp, self.png[1])
    else
        setSpriteFrameByName(self.rootItems.isSignUp, self.png[2])
    end
    self:createlist()
end

function windowTreasureCheckList.createlist( self  )
    local celldict = {}

    local listHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.CellSize.x, self.CellSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("gonghuizhan/cell_chakanbaoming", nil, true, "cell_checklist")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.listTableView,cellCCB,self.CellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            self:setCell(ccbDocumentControler,self.data.treasureChechList.cellData[tostring(a1 + 1)],a1)

            if self.listTableView then
                cellCCB:setPosition(self.CellSize.x/2, 0)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.data.treasureChechList.cellData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.listTableView = ui.createLuaTableView({
        handle = listHandle,
        viewwidth = self.rootItems.listscroll:getContentSize().width,
        viewheight = self.rootItems.listscroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.listscroll:addChild(self.listTableView)
    self.listTableView:setTouchPriority(self.touchPriority)
end

function windowTreasureCheckList.setCell( self,aiCell,aiData,aiIndex )
    aiCell.rank:setString(aiIndex+1)
    -- print("windowTreasureCheckList.setCell ===========")
    -- printT(aiData)
    ui.setLabelString(aiCell.name,aiData.name,13)
    ui.setLabelString(aiCell.level,aiData.level,13)
    ui.setLabelString(aiCell.atk,aiData.atk,10)
    ui.setLabelString(aiCell.contribute,aiData.contribution,22)

end
return windowTreasureCheckList