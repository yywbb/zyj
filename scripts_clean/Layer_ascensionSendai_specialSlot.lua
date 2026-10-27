
local ascensionSendaiSlot2 = {

    rootNode = nil,
    rootItems = nil,

    buttontouch = -103,
    ListTableView = nil,
    showgenerals = {},

    position = {},
    celldict = {},

    slots = {generals = {}},

    param = {},

    data = {},
    specialSlot = {}, --特殊阵容 人数<7的阵容
    enemySlot = {}, --敌方阵容

    iconIndex = 14,

    battleEvent = {}, --战斗事件
    battleNum = 7, --战斗人数
    warNum = 7, --阵容数

    specialInit = 0,
}

function ascensionSendaiSlot2.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("shengxiantai/shengxiantai_dianxian2", nil, true, "shengxiantai_dianxian2")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    ui.setLabelString(self.rootItems.doLab,"挑 战",19)

    self.rootItems.topnode:setPositionY(toppos)
    -- self.rootItems.midnode:setPositionY((toppos-700))
    self.rootItems.bg:setPositionY(toppos/2)
    self.rootItems.midgeneralnode:setContentSize(CCSizeMake(500,850))

    if param and param.battleId > 0 then
        self.param = param
        self.battleEvent = gamedata.config.shengxian_battle[tostring(param.battleId)]
        self.battleNum = self.battleEvent.num
        self.specialSlot = {}

        for i=1,self.warNum do
            if self.battleEvent["p"..i] == 0 then
                self.specialSlot[tostring(i)] = -1
                self.enemySlot[tostring(i)] = -1
            else
                self.specialSlot[tostring(i)] = 0
                self.enemySlot[tostring(i)] = self.battleEvent["p"..i]
            end
        end
    end
    printT(self.battleEvent,"jkp-battleEvent")

    for i=1,self.warNum do
        self.position[i] = {}
        self.position[i].x = self.rootItems["general"..i]:getPositionX()
        self.position[i].y = self.rootItems["general"..i]:getPositionY()
        self.rootItems["general"..i]:setPositionY(self.position[i].y)
        self.rootItems["obz"..i]:setPositionY(self.position[i].y)
        --设置敌方阵容
        if self.enemySlot[tostring(i)] == -1 then
            -- self.rootItems["d_general"..i]:setVisible(false)
        else
            self.rootItems["d_general"..i]:setVisible(true)
            ui.setNewIcon(self.rootItems, {cid = self.enemySlot[tostring(i)]}, self.warNum+(i-1))
        end
    end

    --返回
    self.rootItems.backBtn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("ascensionSendai")
    end, CCControlEventTouchUpInside)
    self.rootItems.backBtn:setSwallowsTouch(true)
    self.rootItems.backBtn:setTouchPriority(self.buttontouch-1)
    --挑战
    self.rootItems.doButton:addHandleOfControlEvent(function()
        print("挑战") --获取参战伙伴iid
        local slotGenerals = {}
        if self.battleNum == self.warNum then
            print("7 VS 7")
            slotGenerals = table.copy(self.slots.generals)
            for i=1,table.getTableLength(slotGenerals) do
                for j=1,table.getTableLength(self.showgenerals) do
                    if slotGenerals[tostring(i)] == self.showgenerals[j].cid then
                        slotGenerals[tostring(i)] = self.showgenerals[j].iid
                    end
                end
            end
        else 
            --特殊战斗阵容
            slotGenerals = table.copy(self.specialSlot)
            for i=1,table.getTableLength(slotGenerals) do
                for j=1,table.getTableLength(self.showgenerals) do
                    if slotGenerals[tostring(i)] == self.showgenerals[j].cid then
                        slotGenerals[tostring(i)] = self.showgenerals[j].iid
                    end
                end
            end
        end
        printT(slotGenerals,"jkp-slotGenerals")
        printT(self.enemySlot,"jkp-enemySlot")
        --战斗接口
        local count = 0 
        for k,v in pairs(slotGenerals) do
            if v > 0 then
                count = count + 1
            end
        end
        if count > 0 then
            print("战斗")
            UIRequest({type = 8854, pointId = self.param.pointId, event = {id = self.param.event.id, type = self.param.event.type}, selectId = slotGenerals})
        else
            runGamePrompt({msg = "请至少上阵一名伙伴"})
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:setTouchPriority(self.buttontouch-1)

    --触摸操作
    local touchedGeneral = nil
    local touchgeneral = nil
    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.touchlayer,x,y) then
            if ui.isTouched(self.rootItems.midgeneralnode,x,y) then
                print("midgeneralnode")
                for k,v in pairs(self.requesttable) do
                    if self.postable[v].has and ui.isTouched(self.rootItems["general"..v],x,y) then
                        print(k,v)
                        touchedGeneral = {node = self.rootItems["general"..v], sid = k, touchx = x, touchy = y }
                        touchedGeneral.node:setZOrder(1)
                        return true
                    end
                end
            elseif ui.isTouched(self.rootItems.listscroll,x,y) then
                print("listscroll")
                -- printT(self.celldict,"celldict")
                for k,v in pairs(self.celldict) do
                    if ui.isTouched(v.cellCCB,x,y) then
                        touchgeneral = {node = self.rootItems.touchgeneral, index = v.index, touchx = x, touchy = y }
                        touchgeneral.node:setZOrder(1)
                        self.rootItems.touchgeneral:setVisible(false)
                        ui.setNewIcon(self.rootItems,self.showgenerals[v.index], self.iconIndex)
                        touchgeneral.node:setPosition(touchgeneral.touchx,touchgeneral.touchy)
                        return true
                    end
                end
            end
        end
    end

    local function ccTouchMoved(x, y)
        if touchedGeneral then
            touchedGeneral.node:setPosition(self.postable[touchedGeneral.sid].x+(x-touchedGeneral.touchx)/GameScene.scaleNum,self.postable[touchedGeneral.sid].y+(y-touchedGeneral.touchy)/GameScene.scaleNum)
        elseif touchgeneral then
            touchgeneral.node:setPosition((x)/GameScene.scaleNum,(y)/GameScene.scaleNum)
            if (y-touchgeneral.touchy > 50)  or (y-touchgeneral.touchy < -50) then
                self.rootItems.touchgeneral:setVisible(true)
                for k,v in pairs(self.celldict) do
                    if v.index == touchgeneral.index then
                        -- v.cellCCB:setVisible(false)
                    end
                end
            end
        end
    end

    local function ccTouchEnded(x, y)
        if touchedGeneral then
            local haschange = false
            local lowerSlot = false
            for k,v in pairs(self.requesttable) do
                if self.battleNum == self.warNum then
                    if k ~= touchedGeneral.sid and ui.iscontendbynode(self.rootItems["general"..v],touchedGeneral.node:getPositionX(),touchedGeneral.node:getPositionY()) then
                        haschange = true
                        print(v,touchedGeneral.sid)
                        local moveto =  CCMoveTo:create(0.2, ccp(self.postable[k].x,self.postable[k].y))
                        touchedGeneral.node:runAction(moveto)
                        local moveto2 =  CCMoveTo:create(0.2, ccp(self.postable[touchedGeneral.sid].x,self.postable[touchedGeneral.sid].y))
                        self.rootItems["general"..v]:runAction(moveto2)
                        local postemp = self.requesttable[k]
                        self.requesttable[k] = self.requesttable[touchedGeneral.sid]
                        self.requesttable[touchedGeneral.sid] = postemp
                        break
                    end
    
                    if ui.iscontendbynode(self.rootItems.generalsNode, touchedGeneral.node:getPositionX(),touchedGeneral.node:getPositionY()) then
                        haschange = true
                        self.slots.generals[tostring(self.requesttable[touchedGeneral.sid])] = 0
                        lowerSlot = true
                        break
                    end
                else
                    if self.specialSlot[tostring(k)] >= 0 then
                        if k ~= touchedGeneral.sid and ui.iscontendbynode(self.rootItems["general"..v],touchedGeneral.node:getPositionX(),touchedGeneral.node:getPositionY()) then
                            haschange = true
                            print(v,touchedGeneral.sid)
                            local moveto =  CCMoveTo:create(0.2, ccp(self.postable[k].x,self.postable[k].y))
                            touchedGeneral.node:runAction(moveto)
                            local moveto2 =  CCMoveTo:create(0.2, ccp(self.postable[touchedGeneral.sid].x,self.postable[touchedGeneral.sid].y))
                            self.rootItems["general"..v]:runAction(moveto2)
                            local postemp = self.requesttable[k]
                            self.requesttable[k] = self.requesttable[touchedGeneral.sid]
                            self.requesttable[touchedGeneral.sid] = postemp
                            break
                        end
                        if ui.iscontendbynode(self.rootItems.generalsNode, touchedGeneral.node:getPositionX(),touchedGeneral.node:getPositionY()) then
                            haschange = true
                            self.specialSlot[tostring(self.requesttable[touchedGeneral.sid])] = 0
                            lowerSlot = true
                            break
                        end
                    end
                end
            end
            if not haschange then
                local moveto2 = CCMoveTo:create(0.2, ccp(self.postable[touchedGeneral.sid].x, self.postable[touchedGeneral.sid].y))
                touchedGeneral.node:runAction(moveto2)
            end
            touchedGeneral.node:setZOrder(0)
            touchedGeneral = nil
            --同步动作时间
            local time = 0.3
            if lowerSlot then
                time = 0.1
            end
            if haschange then
                gameTouch:clickprofbytime(time)
            end
            --确定变阵
            self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(time),CCCallFunc:create(function()
                printT(self.requesttable, "jkp-requesttable")
                local needchange = false
                for k,v in pairs(self.requesttable) do
                    if k ~= v then
                        needchange = true
                    end
                end
                --变阵
                if needchange then
                    if self.battleNum == self.warNum then
                        for i = 1,self.warNum do
                            CCUserDefault:sharedUserDefault():setIntegerForKey("ascensionSendai"..i..GameScene.roleinfo.id, self.slots.generals[tostring(self.requesttable[i])] or 0)
                        end
                        self.needgeneralreset = true
                        self.needslotreset = true
                        self.rootItems.touchlayer:setTouchEnabled(false)
                        UIRequest({type = 88591})
                    else
                        local cids = {}
                        for i=1,self.warNum do
                            cids[tostring(i)] = self.specialSlot[tostring(self.requesttable[i])]
                        end
                        for i=1,self.warNum do
                            self.specialSlot[tostring(i)] = cids[tostring(i)]
                        end
                        self.needgeneralreset = true
                        self.needslotreset = true
                        self.rootItems.touchlayer:setTouchEnabled(false)
                        self:reloadData()
                    end
                end
                --下阵
                if lowerSlot then
                    if self.battleNum == self.warNum then
                        for i = 1,self.warNum do
                            CCUserDefault:sharedUserDefault():setIntegerForKey("ascensionSendai"..i..GameScene.roleinfo.id, self.slots.generals[tostring(self.requesttable[i])] or 0)
                        end
                        self.needgeneralreset = true
                        self.needslotreset = true
                        self.rootItems.touchlayer:setTouchEnabled(false)
                        UIRequest({type = 88591})
                    else
                        self.needgeneralreset = true
                        self.needslotreset = true
                        self.rootItems.touchlayer:setTouchEnabled(false)
                        self:reloadData()
                    end
                end
            end)))
        end

        if touchgeneral then
            self.rootItems.touchgeneral:setVisible(false)

            for k,v in pairs(self.celldict) do
                if v.index == touchgeneral.index then
                    v.cellCCB:setVisible(true)
                end
            end
            for k,v in pairs(self.requesttable) do
                if ui.isTouched(self.rootItems["general"..v],x,y) then
                    local changeOn = true
                    if self.showgenerals[touchgeneral.index].newhp <= 0 then
                        changeOn = false
                        runGamePrompt({msg = "该伙伴已战败，无法上阵"})
                    else
                        if self.battleNum == self.warNum then
                            for m,n in pairs(self.slots.generals) do
                                if n == self.showgenerals[touchgeneral.index].cid then
                                    changeOn = false
                                    runGamePrompt({msg = "该伙伴已上阵，请重新选择"})
                                    break
                                end
                            end
                        else
                            for m,n in pairs(self.specialSlot) do
                                if v == tonumber(m) and n == -1 then
                                    changeOn = false
                                    runGamePrompt({msg = "该阵位无法上阵伙伴，请选择其它阵位"})
                                    break
                                elseif n == self.showgenerals[touchgeneral.index].cid then
                                    changeOn = false
                                    runGamePrompt({msg = "该伙伴已上阵，请重新选择"})
                                    break
                                end
                            end
                        end
                    end
                    if changeOn then
                        print("battleNum = ",self.battleNum)
                        print("warNum = ",self.warNum)
                        self.needgeneralreset = true
                        self.needslotreset = true
                        if self.battleNum == self.warNum then
                            printT(self.slots.generals,"jkp-slots1")
                            CCUserDefault:sharedUserDefault():setIntegerForKey("ascensionSendai"..v..GameScene.roleinfo.id, self.showgenerals[touchgeneral.index].cid)
                            UIRequest({type = 88591})
                        else
                            self.specialSlot[tostring(v)] = self.showgenerals[touchgeneral.index].cid
                            self:reloadData()
                        end
                    end
                    break
                end
            end
            touchgeneral = nil
        end
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then
            return ccTouchBegan(x, y)
        elseif eventType == "moved" then
            return ccTouchMoved(x, y)
        elseif eventType == "ended" then
            return ccTouchEnded(x, y)
        end
    end

    local touchPriority = self.buttontouch

    self.rootItems.touchlayer:registerScriptTouchHandler(onTouch, false, touchPriority, false)
    self.rootItems.touchlayer:setTouchPriority(touchPriority)
    self.rootItems.touchlayer:setTouchEnabled(true)

    self.needslotreset = true
    self.needgeneralreset = true

    UIRequest({type = 8859})
end

function  ascensionSendaiSlot2.reloadGeneral(self)
    self.showgenerals = {}
    if self.data.sendaiGenerals and next(self.data.sendaiGenerals) then --武将镜像战斗数据
        local sendaiGenerals = table.copy(self.data.sendaiGenerals) or {}
        for k,v in pairs(sendaiGenerals) do
            v.newstate = 1 --正常
            if self.battleNum == self.warNum then
                for i,j in pairs(self.slots.generals) do
                    if j == v.cid then
                        v.newstate = 2 --在阵
                    end
                end
            else
                for i,j in pairs(self.specialSlot) do
                    if j == v.cid then
                        v.newstate = 2 --在阵
                    end
                end
            end
            if v.newhp <= 0 then
                v.newstate = 0 --战败
            end
            table.insert(self.showgenerals,v)
        end
    end
    --镜像数据续要添加 在阵、正常、死亡排序
    local sortBy = function(a,b)
        if a.newstate and b.newstate then
            if a.newstate == b.newstate then
                if a.quality == b.quality then
                    if a.level1 == b.level1 then
                        if a.level2 == b.level2 then
                            return a.cid > b.cid
                        else
                            return a.level2 > b.level2
                        end
                    else
                        return a.level1 > b.level1
                    end
                else
                    return a.quality > b.quality
                end
            else
                return a.newstate > b.newstate
            end
        else
            if a.quality == b.quality then
                if a.level1 == b.level1 then
                    if a.level2 == b.level2 then
                        return a.cid > b.cid
                    else
                        return a.level2 > b.level2
                    end
                else
                    return a.level1 > b.level1
                end
            else
                return a.quality > b.quality
            end
        end
        
    end
    table.sort(self.showgenerals, sortBy)
    -- printT(self.showgenerals, "jkp-showgenerals")

    if not self.ListTableView then
        self:createList()
    else
        self.ListTableView:reloadData()
    end
end

function ascensionSendaiSlot2.reloadSlot(self)
    self.requesttable = {}
    self.postable = {}
    local requesttable = self.requesttable
    local postable = self.postable

    for i=1,self.warNum do
        self.rootItems["general"..i]:setPosition(self.position[i].x,self.position[i].y)
        self.rootItems["general"..i]:removeAllChildrenWithCleanup(true)
        postable[i] = {}
        local generalData = {}
        if self.battleNum == self.warNum then
            if self.showgenerals and self.slots.generals[tostring(i)] and self.slots.generals[tostring(i)] > 0 then
                for j=1, table.getTableLength(self.showgenerals) do
                    if self.slots.generals[tostring(i)] == self.showgenerals[j].cid then
                        generalData = self.showgenerals[j]
                        break
                    end
                end
            end
        else
            if self.showgenerals and self.specialSlot then
                if self.specialSlot[tostring(i)] == -1 then
                    -- self.rootItems["obz"..i]:setVisible(false)
                    self.rootItems["general"..i]:setVisible(false)
                else
                    self.rootItems["obz"..i]:setVisible(true)
                    self.rootItems["general"..i]:setVisible(true)
                end
                for j=1, table.getTableLength(self.showgenerals) do
                    if self.specialSlot[tostring(i)] == self.showgenerals[j].cid then
                        generalData = self.showgenerals[j]
                        break
                    end
                end
            end
        end

        if next(generalData) then
            postable[i].ccb, postable[i].item = CCBReaderLoad("icons/new_icon", nil, true, "cell_icon")
            local config = gamedata.config.general[tostring(generalData.cid)]
            local g_data = {
                quality = config.quality,
                icon = config.icon,
                name = config.name,
                actor = config.actor,
                level = generalData.level1,
                level2 = generalData.level2,
            }
            -- 设置头像
            if generalData.illusionCid == 0 then
                local gdata = ui.getConfigGeneral(generalData)
                if next(gdata) and config.fashion_id == 0 then
                    g_data.icon = gdata.icon
                end
            else
                local config = gamedata.config.general[tostring(generalData.illusionCid)]
                g_data.quality = config.quality
                g_data.icon = config.icon
                g_data.name = config.name
                g_data.staffType = "phantom"
            end
            ui.setNewIcon(postable[i].item, g_data)
            --
            postable[i].x = self.rootItems["general"..i]:getPositionX()
            postable[i].y = self.rootItems["general"..i]:getPositionY()
            requesttable[i] = i
            postable[i].has = true
            postable[i].lead = false
            postable[i].lock = false
            postable[i].ccb:setPosition(90,90)
            self.rootItems["general"..i]:addChild(postable[i].ccb)
        else
            postable[i].ccb, postable[i].item = CCBReaderLoad("shengxiantai/icon_add", nil, true, "icon_add")
            postable[i].x = self.rootItems["general"..i]:getPositionX()
            postable[i].y = self.rootItems["general"..i]:getPositionY()
            requesttable[i] = i
            postable[i].has = false
            postable[i].lead = false
            postable[i].lock = false
            postable[i].ccb:setPosition(90,90)
            self.rootItems["general"..i]:addChild(postable[i].ccb)
        end
    end
end

function ascensionSendaiSlot2.reloadData(self,data)
    if data then self.data = data end
    --怪物信息
    self.enemySlotData = {}
    if self.data.enemyData and next(self.data.enemyData) then
        self.enemySlotData = self.data.enemyData
    else
        local index = 0
        for i=1,7 do
            if self.battleEvent["p"..i] > 0 then
                index = index + 1
                local eData = {}
                eData.iid = self.battleEvent["p"..i]
                eData.newhp = 100
                eData.maxhp = 100
                eData.anger = 0
                self.enemySlotData[tostring(index)] = eData
            end
        end
    end
    printT(self.enemySlotData,"jkp-enemySlotData")

    for i=1,7 do
        local cid = CCUserDefault:sharedUserDefault():getIntegerForKey("ascensionSendai"..i..GameScene.roleinfo.id) or 0
        for k,v in pairs(self.data.sendaiGenerals) do
            if v.cid == cid then
                if v.newhp <= 0 then
                    cid = 0
                    CCUserDefault:sharedUserDefault():setIntegerForKey("ascensionSendai"..i..GameScene.roleinfo.id, 0)
                end
            end
        end
        self.slots.generals[tostring(i)] = cid
        if self.specialInit == 0 and self.specialSlot[tostring(i)] >= 0 then
            self.specialSlot[tostring(i)] = cid
        end
        --设置怪物状态
        self.rootItems["d_shibainode"..i]:setVisible(false)
        if self.enemySlot[tostring(i)] > 0 then
            for k,v in pairs(self.enemySlotData) do
                if self.enemySlot[tostring(i)] == v.iid and v.newhp <= 0 then
                    self.rootItems["d_shibainode"..i]:setVisible(true)
                    break
                end
            end
        end
    end
    self.specialInit = 1

    if self.needgeneralreset then self:reloadGeneral() self.needgeneralreset = false end
    if self.needslotreset then self:reloadSlot() self.needslotreset = false end
    self.rootItems.touchlayer:setTouchEnabled(true)

end

function ascensionSendaiSlot2.createList(self)
    print("createList")

    self.celldict = {}
    local unrecycleCell = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(200, 300)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("shengxiantai/shengxiantai_general", nil, true, "shengxiantai_general")
                self.celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler,index = a1+1 }
            else
                first = false
                cellCCB = self.celldict[a2].cellCCB
                ccbDocumentControler = self.celldict[a2].ccbDocumentControler
                self.celldict[a2].index = a1+1
            end
            --
            self.celldict[a2].cellCCB:setVisible(true)
            self:setCell(ccbDocumentControler, a1+1)
            --
            cellCCB:setPosition(100, 150)

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.showgenerals)
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
    self.ListTableView:setTouchPriority(self.buttontouch+1)
end

function ascensionSendaiSlot2.setCell(self, items, index)
    -- 设置头像
    local generalData = self.showgenerals[index]
    local configGeneral = table.copy(gamedata.config.general[tostring(generalData.cid)])
    if generalData.illusionCid == 0 then
        local gdata = ui.getConfigGeneral(generalData)
        if next(gdata) and configGeneral.fashion_id == 0 then
            self.showgenerals[index].icon = gdata.icon
        end
    else
        local config = gamedata.config.general[tostring(generalData.illusionCid)]
        self.showgenerals[index].quality = config.quality
        self.showgenerals[index].icon = config.icon
        self.showgenerals[index].staffType = "phantom"
        configGeneral.name = config.name
    end
    ui.setNewIcon(items, self.showgenerals[index])

    items.shibainode:setVisible(false)
    items.yishangzhen_img:setVisible(false)
    if generalData.newstate == 0 then
        items.shibainode:setVisible(true)
    elseif generalData.newstate == 2 then
        items.yishangzhen_img:setVisible(true)
    end
    --显示助战
    if generalData.gid == 0 then
        items.zhuzhan_img:setVisible(true)
    else
        items.zhuzhan_img:setVisible(false)
    end
    --显示血量
    ui.setSpriteTextureRect2(items.hp, 0, 0, 151*generalData.newhp/generalData.maxhp, items.hp:getContentSize().height)
    --显示怒气
    local apnum = generalData.anger
    if apnum > 12 then
        apnum = 12
    end
    local apx, apy = 0, apnum%4
    for i=1,apnum do
        if i%4 == 0 then
            apx = apx + 1
        end
    end
    print("apx = ", apx)
    print("apy = ", apy)
    for i=1,4 do
        if apx == 0 then
            setSpriteFrameByName(items["nuqi"..i], "sxt_nuqi")
            if i <= apy then
                items["nuqi"..i]:setVisible(true)
            else
                items["nuqi"..i]:setVisible(false)
            end
        elseif apx == 1 then
            setSpriteFrameByName(items["nuqi"..i], "sxt_nuqi")
            items["nuqi"..i]:setVisible(true)
            if i <= apy then
                setSpriteFrameByName(items["nuqi"..i], "sxt_nuqi2")
            end
        elseif apx == 2 then
            items["nuqi"..i]:setVisible(true)
            setSpriteFrameByName(items["nuqi"..i], "sxt_nuqi2")
            if i <= apy then
                setSpriteFrameByName(items["nuqi"..i], "sxt_nuqi3")
            end
        elseif apx == 3 then
            items["nuqi"..i]:setVisible(true)
            setSpriteFrameByName(items["nuqi"..i], "sxt_nuqi3")
        end
    end

    if generalData.quality and generalData.quality >= 7 then
        ui.setLabelString(items.name,configGeneral.name, 213)
    else
        ui.setLabelString(items.name,configGeneral.name, ((generalData.quality and generalData.quality ~= 0) and generalData.quality or 1)*2-1)
    end
end


function ascensionSendaiSlot2.clear(self)
    self.ListTableView = nil
    self.data = {}
    self.celldict = {}
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.showgenerals = {}
    self.requesttable = {}
    self.postable = {}

    self.slots = {generals = {}}
    self.specialInit = 0

    self.param = nil

    self.enemySlot = {}
    self.enemySlotData = {}
    
end

return ascensionSendaiSlot2