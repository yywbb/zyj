
local upStarSill = {
    rootNode = nil,
    rootItems = nil,
    normalCellSize = {x = 930,y = 230},
    ListTableView = nil,
    stages = {"C","B","A","S","SS","SSS"},
    selectpage = 1,
}

function upStarSill.open(self,touchPriority,data,callback)
    self.touchPriority = touchPriority

    printT(data,"upStarSill")
    self.rootNode,self.rootItems = CCBReaderLoad("general_new/tc_upstarskill", nil, true, "tc_upstarskill")

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("upStarSkill")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.curSkillLevel = data.curSkillLevel

    local upstarConfig = gamedata.config.general_star
    local skills = {}
    for i=1,table.getTableLength(upstarConfig) do
        local v = upstarConfig[tostring(i)]
        if v.star_class == 0 then
            if not skills[v.stage] then
                skills[v.stage] = {}
            end
            table.insert(skills[v.stage],v.activated)
        end
    end

    self.skills = skills
    printT(self.skills,"skills")

    for i = 1,6 do
        self.rootItems["tabbutton"..i]:addHandleOfControlEvent(function()
            self:shiftpage(i)
        end, CCControlEventTouchUpInside)
        self.rootItems["tabbutton"..i]:setSwallowsTouch(true)
        self.rootItems["tabbutton"..i]:setTouchPriority(self.touchPriority-2)
    end

    self:shiftpage(self.selectpage)
    self:initFixedString()
    return self.rootNode
end


function upStarSill.shiftpage(self,page)
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

function upStarSill.reload(self)
    
    if self.ListTableView then
        self.ListTableView:reloadData()

        local stage = self.stages[self.selectpage]
        local r = 0
        if self.curSkillLevel[self.selectpage] and self.curSkillLevel[self.selectpage] > 0 then
            r = table.getTableLength(self.skills[stage]) + 1
        else
            r = table.getTableLength(self.skills[stage])
        end
        self.ListTableView:setLuaContentOffset(0, self.rootItems.listnode:getContentSize().height - r*self.normalCellSize.y)
    else
        self:createList()
    end
	
end

function upStarSill.setCell(self,items,index)

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
    
    local stage = self.stages[self.selectpage]
    local skill = self.skills[stage][index]
    local breakskill = gamedata.config.breakskill[tostring(skill)]

    printT(breakskill,"breakskill")
    if breakskill then

        ui.setLabelString(items.skillname,breakskill.name,1010,34)
        ui.setLabelString(items.level,"等级."..index,1008,34)
        items.desNode:removeAllChildrenWithCleanup(true)

        local rich = {
            {fontID = 1013,content = "自身剩余生命值每低于生命上限的"},
            {fontID = 1014,content = "10%"},
            {fontID = 1013,content = "，受到的伤害减少"},
            {fontID = 1014,content = "10%"},
            {fontID = 1013,content = "。"},
        }
        -- ui.createRichLabel(rich,items.desNode)

        print(breakskill.desc)
        print(LoadJsonStringToTable(breakskill.desc))
        ui.createRichLabel(LoadJsonStringToTable(breakskill.desc),items.desNode)
    end
end


function upStarSill.createList(self)
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
            local stage = self.stages[self.selectpage]
            if self.curSkillLevel[self.selectpage] and self.curSkillLevel[self.selectpage] > 0 then
                r = table.getTableLength(self.skills[stage]) + 1
            else
                r = table.getTableLength(self.skills[stage])
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

function upStarSill.initFixedString(self)
end

function upStarSill.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.ListTableView = nil
    if self.callback then
        self.callback()
    end	
    self.selectpage = 1
end
return upStarSill