
local sendai_battle = {
    rootNode = nil,
    rootItems = nil,

    enemySlot = {},
    ListTableView = nil,

    data = {},
    typeId = 1,

    monsterConfig = {}, --怪物表
}

function sendai_battle.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("shengxiantai/tc_sxt_battle", nil, true, "tc_sxt_battle")
    self.touchPriority = touchPriority

    self.data = data
    self.callback = callback
    self.typeId = data.id

    self.monsterConfig = gamedata.config.shengxian_monster

    --返回
    self.rootItems.closeBtn:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("sendai_battle")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeBtn:setSwallowsTouch(true)
    self.rootItems.closeBtn:setTouchPriority(self.touchPriority)
    --挑战
    self.rootItems.doButton:addHandleOfControlEvent(function()
        
        GameScene:shiftLayer("ascensionSendaiSlot2", nil, {pointId = self.data.pointId, event = {id = self.data.event.id, type = self.data.event.type}, battleId = self.data.config.id})
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:setTouchPriority(self.touchPriority)
        gameWindows:closeWindowDirect("sendai_battle")
    ui.setLabelString(self.rootItems.doLab, nil, 19)
    --显示奖励
    local rewards = ui.getIDandNUMs(data.config.reward)
    for i=1,5 do
        self.rootItems["reward"..i]:setVisible(false)
        if rewards[i] then
            self.rootItems["reward"..i]:setVisible(true)
            ui.setNewIcon(self.rootItems, { cid = rewards[i].cid, num = rewards[i].num }, i-1)
        end
    end
    --显示条件
    if data.config.num < 7 then
        self.rootItems.title4:setString("仅能上阵"..data.config.num.."名伙伴")
        self.rootItems.title4:setVisible(true)
    else
        self.rootItems.title4:setVisible(false)
    end

    UIRequest({type = 8860, pointId = data.pointId, eventId = self.data.event.id})

    return self.rootNode
end

function sendai_battle.reloadData(self, data)
    self.enemySlot = {}
    if data.enemyData and next(data.enemyData) then
        self.enemySlot = data.enemyData
    else
        local battleConfig = gamedata.config.shengxian_battle[tostring(self.data.config.id)]
        local index = 0
        for i=1,7 do
            if battleConfig["p"..i] > 0 then
                index = index + 1
                local data = {}
                data.iid = battleConfig["p"..i]
                data.newhp = 100
                data.maxhp = 100
                data.anger = 0
                self.enemySlot[tostring(index)] = data
            end
        end
    end
    printT(self.enemySlot,"jkp-enemySlot")
    
    --显示敌方阵容
    if not self.ListTableView then
        self:createList()
    else
        self.ListTableView:reloadData()
    end
end

function sendai_battle.createList(self)
    print("createList")

    local celldict = {}
    local unrecycleCell = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(160, 230)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("shengxiantai/shengxiantai_general", nil, true, "shengxiantai_general")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler,index = a1+1 }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
                celldict[a2].index = a1+1
            end
            --
            self:setCell(ccbDocumentControler, self.enemySlot[tostring(a1+1)], a1+1)
            --
            cellCCB:setScale(0.8)
            cellCCB:setPosition(80, 115)

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.enemySlot)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listscroll:getContentSize().width,
        viewheight = self.rootItems.listscroll:getContentSize().height,
        dire = 0
    })
    self.rootItems.listscroll:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(self.touchPriority+1)
end

function sendai_battle.setCell(self, items, data, index)
    local monsterConfig = self.monsterConfig[tostring(data.iid)]
    ui.setNewIcon(items, {cid = data.iid})
    if monsterConfig.quality and monsterConfig.quality >= 7 then
        ui.setLabelString(items.name, monsterConfig.name, 213)
    else
        ui.setLabelString(items.name, monsterConfig.name, ((monsterConfig.quality and monsterConfig.quality ~= 0) and monsterConfig.quality or 1)*2-1)
    end
    --显示血量
    ui.setSpriteTextureRect2(items.hp, 0, 0, 151*data.newhp/data.maxhp, items.hp:getContentSize().height)
    --显示怒气
    for i=1,4 do
        if i <= data.anger then
            items["nuqi"..i]:setVisible(true)
        else
            items["nuqi"..i]:setVisible(false)
        end
    end
    --
    if data.newhp <= 0 then
        items.shibainode:setVisible(true)
    else
        items.shibainode:setVisible(false)
    end

end

function sendai_battle.close(self)

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.ListTableView = nil

    self.enemySlot = {}
    self.data = {}
    self.monsterConfig = {}

    if self.callback then
        self.callback()
    end
end

return sendai_battle

