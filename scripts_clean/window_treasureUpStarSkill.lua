
local treasureUpStarSill = {
    rootNode = nil,
    rootItems = nil,
    normalCellSize = {x = 930,y = 230},
    ListTableView = nil,
    stages = {"","","","","",""},
    skilldata = {},
    selectpage = 1,
}

function treasureUpStarSill.open(self,touchPriority,data,callback)
    self.touchPriority = touchPriority

    printT(data,"treasureUpStarSill")
    self.rootNode,self.rootItems = CCBReaderLoad("equip_new/tc_upstarskill", nil, true, "tc_upstarskill")

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("treasureUpStarSill")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.curSkillLevel = data.curSkillLevel
    self.skilldata = data.skilldata

    for i=1,6 do
        local breakskill = gamedata.config.breakskill[tostring(self.skilldata[i].activated)]
        self.stages[i] = breakskill.name
        ui.setLabelString(self.rootItems["tablab"..i], self.stages[i], 19)
        self.rootItems["tabbutton"..i]:addHandleOfControlEvent(function()
            self:shiftpage(i)
        end, CCControlEventTouchUpInside)
        self.rootItems["tabbutton"..i]:setSwallowsTouch(true)
        self.rootItems["tabbutton"..i]:setTouchPriority(self.touchPriority-2)
    end

    if data.quality == 5 then
        self.rootItems.tab3:setVisible(false)
        self.rootItems.tab4:setVisible(false)
        self.rootItems.tab5:setVisible(false)
        self.rootItems.tab6:setVisible(false)
    elseif data.quality == 6 then
        self.rootItems.tab5:setVisible(false)
        self.rootItems.tab6:setVisible(false)
    end
    
    self:shiftpage(self.selectpage)
    self:initFixedString()
    return self.rootNode
end


function treasureUpStarSill.shiftpage(self,page)
    self.selectpage = page
    for i=1,6 do
        if i == page then
            setSpriteFrameByName(self.rootItems["tabon"..i], gameConfig.images.pageButtonON)
        else
            setSpriteFrameByName(self.rootItems["tabon"..i], gameConfig.images.pageButtonOFF)
        end
    end

    self:reload()
end

function treasureUpStarSill.reload(self)
    
    if self.ListTableView then
        self.ListTableView:reloadData()

        local r = 0
        if self.curSkillLevel[self.selectpage] and self.curSkillLevel[self.selectpage] > 0 then
            r = 6
        else
            r = 5
        end
        self.ListTableView:setLuaContentOffset(0, self.rootItems.listnode:getContentSize().height - r*self.normalCellSize.y)
    else
        self:createList()
    end
	
end

function treasureUpStarSill.setCell(self,items,index)

    items.activate_no:setVisible(false)
    items.activate_yes:setVisible(false)

    local isActivity = false
    --第一个位置展示激活等级 
    if self.curSkillLevel[self.selectpage] and self.curSkillLevel[self.selectpage] > 0 then
        isActivity = true
    end

    if isActivity and index == 1 then
        index = self.curSkillLevel[self.selectpage]
        items.activate_yes:setVisible(true)
    elseif isActivity then
        index = index - 1
    end
    
    local skillid = self.skilldata[self.selectpage]["activated"] + index - 1
    local breakskill = gamedata.config.breakskill[tostring(skillid)]
    printT(breakskill,"breakskill")
    if breakskill then
        ui.setLabelString(items.skillname,breakskill.name,1010,34)
        ui.setLabelString(items.level,"等级."..index,1008,34)
        items.desNode:removeAllChildrenWithCleanup(true)

        -- local rich = {
        --     {fontID = 1013,content = "自身剩余生命值每低于生命上限的"},
        --     {fontID = 1014,content = "10%"},
        --     {fontID = 1013,content = "，受到的伤害减少"},
        --     {fontID = 1014,content = "10%"},
        --     {fontID = 1013,content = "。"},
        -- }
        -- ui.createRichLabel(rich,items.desNode)

        print(breakskill.desc)
        print(LoadJsonStringToTable(breakskill.desc))
        ui.createRichLabel(LoadJsonStringToTable(breakskill.desc),items.desNode)
    end
end

function treasureUpStarSill.createList(self)
    print("createList")

    local celldict = {}
    local unrecycleCell = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("general_new/cell_upstarskill", nil, true, "cell_upstarskill")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCell(ccbDocumentControler, a1+1)

            cellCCB:setPosition(self.normalCellSize.x/2, 0)
            if first then
                a2:addChild(cellCCB)
            end
            r = a2

        elseif fn == "numberOfCells" then
            if self.curSkillLevel[self.selectpage] and self.curSkillLevel[self.selectpage] > 0 then
                r = 6
            else
                r = 5
            end
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
    self.rootItems.listnode:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(self.touchPriority)
end

function treasureUpStarSill.initFixedString(self)
end

function treasureUpStarSill.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.ListTableView = nil
    if self.callback then
        self.callback()
    end	
    self.skilldata = {}
    self.selectpage = 1
end
return treasureUpStarSill