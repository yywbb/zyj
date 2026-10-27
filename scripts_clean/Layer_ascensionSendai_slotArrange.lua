
local ascensionSendaiSlot = {

    rootNode = nil,
    rootItems = nil,

    buttontouch = -103,
    ListTableView = nil,
    showgenerals = {},

    position = {},
    celldict = {},

    slots = {generals = {}, illusionCid = {}},

    data = {},
    param = nil,

    state = 1, --1:布阵上传，2：布阵
    playerGenerals = nil,

    generalConfig = {},
}

function ascensionSendaiSlot.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("shengxiantai/shengxiantai_dianxian1", nil, true, "shengxiantai_dianxian1")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.param = param or nil
    ui.setLabelString(self.rootItems.doLab,"布 阵",19)

    self.rootItems.topnode:setPositionY(toppos)
    -- self.rootItems.midnode:setPositionY((toppos-700))
    self.rootItems.bg:setPositionY(toppos/2)
    self.rootItems.midgeneralnode:setContentSize(CCSizeMake(800,750))

    self.generalConfig = gamedata.config.general

    for i=1,7 do
        self.position[i] = {}
        self.position[i].x = self.rootItems["general"..i]:getPositionX()
        self.position[i].y = self.rootItems["general"..i]:getPositionY()
        self.rootItems["general"..i]:setPositionY(self.position[i].y)
        self.rootItems["obz"..i]:setPositionY(self.position[i].y)
    end

    --返回
    self.rootItems.backBtn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("ascensionSendai")
    end, CCControlEventTouchUpInside)
    self.rootItems.backBtn:setSwallowsTouch(true)
    self.rootItems.backBtn:setTouchPriority(self.buttontouch-1)
    --上传或布阵
    self.rootItems.doButton:addHandleOfControlEvent(function()
        if self.state == 1 then
            local slotsnum = 0
            for i=1,table.getTableLength(self.slots.generals) do
                if self.slots.generals[tostring(i)] > 0 then
                    slotsnum = slotsnum + 1
                end
            end
            if slotsnum > 0 then
                local callback =  function()
                    print("上传")
                    local slotGenerals = table.copy(self.slots.generals)
                    for i=1,table.getTableLength(self.showgenerals) do
                       for j=1,table.getTableLength(slotGenerals) do
                            if self.showgenerals[i].cid == slotGenerals[tostring(j)] then
                                slotGenerals[tostring(j)] = self.showgenerals[i].iid
                            end
                       end
                    end
                    printT(slotGenerals,"jkp-slotCid")
                    UIRequest({type = 8858, slotGenerals = slotGenerals})
                end
                gameWindows:openWindow("confirm",{msg = "本轮升仙台期间阵容不可再更改，是否确认？"}, callback)
            else
                runGamePrompt({msg = "请至少上阵一名伙伴"})
            end
        elseif self.state == 2 then
            runGamePrompt({msg = "布阵成功"})
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
                        ui.setNewIcon(self.rootItems,self.showgenerals[v.index],0)
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
            end
            if not haschange then
                local moveto2 =  CCMoveTo:create(0.2, ccp(self.postable[touchedGeneral.sid].x,self.postable[touchedGeneral.sid].y))
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
                printT(self.requesttable,"jkp-requesttable")
                local needchange = false
                for k,v in pairs(self.requesttable) do
                    if k ~= v then
                        needchange = true
                    end
                end
                --变阵
                if needchange then
                    for i = 1,7 do
                        CCUserDefault:sharedUserDefault():setIntegerForKey("ascensionSendai"..i..GameScene.roleinfo.id, self.slots.generals[tostring(self.requesttable[i])] or 0)
                    end
                    self.rootItems.touchlayer:setTouchEnabled(false)
                    UIRequest({type = 88591})
                end
                --下阵
                if lowerSlot then
                    for i = 1,7 do
                        CCUserDefault:sharedUserDefault():setIntegerForKey("ascensionSendai"..i..GameScene.roleinfo.id, self.slots.generals[tostring(self.requesttable[i])] or 0)
                    end
                    self.rootItems.touchlayer:setTouchEnabled(false)
                    UIRequest({type = 88591})
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
                    for m,n in pairs(self.slots.generals) do
                        if n == self.showgenerals[touchgeneral.index].cid then
                            changeOn = false
                            runGamePrompt({msg = "该伙伴已上阵，请重新选择"})
                            break
                        end
                        if self.state == 1 and self.showgenerals[touchgeneral.index].illusionGeneralCid then
                            if n > 0 then
                                local liiCid = self.showgenerals[touchgeneral.index].illusionGeneralCid
                                if self.generalConfig[tostring(n)].init_cid == self.generalConfig[tostring(liiCid)].init_cid then
                                    changeOn = false
                                    runGamePrompt({msg = "该伙伴已上阵，请重新选择"})
                                    break
                                end
                            end
                        end
                    end
                    --判断幻化武将是否重复上阵
                    if self.state == 1 then
                        for m,n in pairs(self.slots.illusionCid) do
                            if n > 0 then
                                local listCid = self.showgenerals[touchgeneral.index].cid
                                if self.generalConfig[tostring(n)].init_cid == self.generalConfig[tostring(listCid)].init_cid then
                                    changeOn = false
                                    runGamePrompt({msg = "该伙伴已上阵，请重新选择"})
                                    break
                                end
                            end
                        end
                    elseif self.state == 2 then
                        if self.showgenerals[touchgeneral.index].newhp <= 0 then
                            changeOn = false
                            runGamePrompt({msg = "该伙伴已战败，无法上阵"})
                        end
                    end

                    if changeOn then
                        CCUserDefault:sharedUserDefault():setIntegerForKey("ascensionSendai"..v..GameScene.roleinfo.id, self.showgenerals[touchgeneral.index].cid)
                        UIRequest({type = 88591})
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

    UIRequest({type = 8859})
end

function  ascensionSendaiSlot.reloadGeneral(self)
    for i=1,7 do
        local cid = CCUserDefault:sharedUserDefault():getIntegerForKey("ascensionSendai"..i..GameScene.roleinfo.id) or 0
        self.slots.generals[tostring(i)] = cid
    end
    self.showgenerals = {}
    if self.data.sendaiGenerals and next(self.data.sendaiGenerals) then --武将镜像战斗数据
        self.state = 2
        local sendaiGenerals = table.copy(self.data.sendaiGenerals) or {}
        for k,v in pairs(sendaiGenerals) do
            v.newstate = 1 --正常
            for i,j in pairs(self.slots.generals) do
                if j == v.cid then
                    v.newstate = 2 --在阵
                    if v.newhp <= 0 then
                        CCUserDefault:sharedUserDefault():setIntegerForKey("ascensionSendai"..i..GameScene.roleinfo.id, 0)
                        self.slots.generals[tostring(i)] = 0
                    end
                    break
                end
            end
            if v.newhp <= 0 then
                v.newstate = 0 --战败
            end
            table.insert(self.showgenerals,v)
        end
    else
        self.state = 1
        if self.playerGenerals == nil then
            self.playerGenerals = table.copy(self.data.generals) or {}
        end
        for k,v in pairs(self.playerGenerals) do
            v.newstate = 1 --正常
            for i,j in pairs(self.slots.generals) do
                if j == 0 then
                    self.slots.illusionCid[tostring(i)] = 0
                else
                    if j == v.cid then
                        v.newstate = 2 --在阵
                        if v.illusionGeneralCid then
                            self.slots.illusionCid[tostring(i)] = v.illusionGeneralCid
                        else
                            self.slots.illusionCid[tostring(i)] = 0
                        end
                        break
                    end
                end
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
    --
    for i,j in pairs(self.slots.generals) do
        local index = 0
        for k,v in pairs(self.showgenerals) do
            if j == v.cid then
                index = i
                break
            end
        end
        if index == 0 then
            CCUserDefault:sharedUserDefault():setIntegerForKey("ascensionSendai"..i..GameScene.roleinfo.id, 0)
            self.slots.generals[tostring(i)] = 0
        end
    end
    --

    if not self.ListTableView then
        self:createList()
    else
        -- if self.ListTableView:getLuaContentOffsetX() < self.rootItems.listscroll:getContentSize().width - table.getTableLength(self.showgenerals)*200 then
        --     self.ListTableView:setLuaContentOffset(self.rootItems.listscroll:getContentSize().width - table.getTableLength(self.showgenerals)*200, 0)
        -- end
        self.ListTableView:reloadData()
    end
end

function ascensionSendaiSlot.reloadSlot(self)
    self.requesttable = {}
    self.postable = {}
    local requesttable = self.requesttable
    local postable = self.postable

    for i=1,7 do
        self.rootItems["general"..i]:setPosition(self.position[i].x,self.position[i].y)
        self.rootItems["general"..i]:removeAllChildrenWithCleanup(true)
        postable[i] = {}
        if self.slots.generals[tostring(i)] and self.slots.generals[tostring(i)] > 0 then
            if self.showgenerals then
                local generalData = {}
                for j=1, table.getTableLength(self.showgenerals) do
                    if self.slots.generals[tostring(i)] == self.showgenerals[j].cid then
                        generalData = self.showgenerals[j]
                        break
                    end
                end
                if next(generalData) then
                    postable[i].ccb, postable[i].item = CCBReaderLoad("slotsInfo/generalInfo", nil, true, "cell_buzhen")
                    local config = self.generalConfig[tostring(generalData.cid)]
                    local g_data = {
                        quality = config.quality,
                        icon = config.icon,
                        name = config.name,
                        actor = config.actor,
                        level = generalData.level1,
                        level2 = generalData.level2,
                    }
                    -- 设置头像
                    if self.state == 1 then
                        if generalData.illusionGeneralCid == nil then
                            local gdata = ui.getConfigGeneral(generalData)
                            if next(gdata) and config.fashion_id == 0 then
                                g_data.icon = gdata.icon
                            end
                        else
                            local config = self.generalConfig[tostring(generalData.illusionGeneralCid)]
                            g_data.quality = config.quality
                            g_data.icon = config.icon
                            g_data.name = config.name
                        end
                    else
                        if generalData.illusionCid == 0 then
                            local gdata = ui.getConfigGeneral(generalData)
                            if next(gdata) and config.fashion_id == 0 then
                                g_data.icon = gdata.icon
                            end
                        else
                            local config = self.generalConfig[tostring(generalData.illusionCid)]
                            g_data.quality = config.quality
                            g_data.icon = config.icon
                            g_data.name = config.name
                        end
                    end
                    ui.setGeneralIconL2(g_data, postable[i].item)
                    --
                    postable[i].x =self.rootItems["general"..i]:getPositionX()
                    postable[i].y = self.rootItems["general"..i]:getPositionY()
                    requesttable[i] = i
                    postable[i].has = true
                    postable[i].lead = false
                    postable[i].lock = false
                    postable[i].ccb:setPosition(175,90)
                    self.rootItems["general"..i]:addChild(postable[i].ccb)
                end
            end
        else
            postable[i].ccb, postable[i].item = CCBReaderLoad("slotsInfo/generalInfo2", nil, true, "cell_buzhen2")
            postable[i].x =self.rootItems["general"..i]:getPositionX()
            postable[i].y = self.rootItems["general"..i]:getPositionY()
            requesttable[i] = i
            postable[i].has = false
            postable[i].lead = false
            postable[i].lock = false
            postable[i].ccb:setPosition(175,90)
            self.rootItems["general"..i]:addChild(postable[i].ccb)

            postable[i].item.add:setVisible(true)
            postable[i].item.lock:setVisible(false)
            postable[i].item.openlevel:setVisible(false)

            local slotconfig = gamedata.config.general_slot
            local nextlevel = slotconfig[tostring(i)]
            if GameScene.roleinfo.level < nextlevel then
                postable[i].lock = true
                postable[i].item.add:setVisible(false)
                postable[i].item.lock:setVisible(true)
                postable[i].item.openlevel:setVisible(true)
                ui.setLabelString(postable[i].item.openlevel,nextlevel.."级开启",13)
            end
        end
    end
end

function ascensionSendaiSlot.reloadData(self,data)
    if data then self.data = data end

    self:reloadGeneral()
    if self.state == 1 then
        local index = 0
        for k,v in pairs(self.slots.generals) do
            if v > 0 then
                for i,j in pairs(self.slots.illusionCid) do
                    if j > 0 and self.generalConfig[tostring(v)].init_cid == self.generalConfig[tostring(j)].init_cid then
                        CCUserDefault:sharedUserDefault():setIntegerForKey("ascensionSendai"..k..GameScene.roleinfo.id, 0)
                        self.slots.generals[tostring(k)] = 0
                        index = index + 1
                    end
                end
            end
        end
        printT(self.slots,"jkp-slots")
        if index > 0 then
            self:reloadGeneral()
        end
    end
    self:reloadSlot()

    self.rootItems.touchlayer:setTouchEnabled(true)

    --战斗前上传伙伴镜像后回升仙台挑战弹窗界面
    if data.type == 8858 and self.param and next(self.param) then
        print("回战斗事件弹窗")
        self.rootItems.title:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.4),CCCallFunc:create(function()
            GameScene:shiftLayer("ascensionSendai", nil, {pointId = self.param.pointId, eventId = self.param.event.id, battleId = self.param.battleId})
        end)))
    end
end

function ascensionSendaiSlot.createList(self)
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

function ascensionSendaiSlot.setCell(self, items, index)
    -- 设置头像
    local generalData = self.showgenerals[index]
    local configGeneral = table.copy(gamedata.config.general[tostring(generalData.cid)])
    if self.state == 1 then
        if generalData.illusionGeneralCid == nil then
            local gdata = ui.getConfigGeneral(generalData)
            if next(gdata) and configGeneral.fashion_id == 0 then
                self.showgenerals[index].icon = gdata.icon
            end
        else
            local config = self.generalConfig[tostring(generalData.illusionGeneralCid)]
            self.showgenerals[index].quality = config.quality
            self.showgenerals[index].icon = config.icon
            self.showgenerals[index].staffType = "phantom"
            configGeneral.name = config.name
        end
    elseif self.state == 2 then 
        if generalData.illusionCid == 0 then
            local gdata = ui.getConfigGeneral(generalData)
            if next(gdata) and configGeneral.fashion_id == 0 then
                self.showgenerals[index].icon = gdata.icon
            end
        else
            local config = self.generalConfig[tostring(generalData.illusionCid)]
            self.showgenerals[index].quality = config.quality
            self.showgenerals[index].icon = config.icon
            self.showgenerals[index].staffType = "phantom"
            configGeneral.name = config.name
        end
    end
    ui.setNewIcon(items, self.showgenerals[index])

    items.shibainode:setVisible(false)
    items.yishangzhen_img:setVisible(false)
    if self.state == 1 then
        for k,v in pairs(self.slots.generals) do
            if generalData.cid == v then --在阵
                items.yishangzhen_img:setVisible(true)
            end
        end
    elseif self.state == 2 then
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
                items["nuqi"..i]:setVisible(true)
                setSpriteFrameByName(items["nuqi"..i], "sxt_nuqi")
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
    end

    if generalData.quality and generalData.quality >= 7 then
        ui.setLabelString(items.name,configGeneral.name, 213)
    else
        ui.setLabelString(items.name,configGeneral.name, ((generalData.quality and generalData.quality ~= 0) and generalData.quality or 1)*2-1)
    end
end


function ascensionSendaiSlot.clear(self)
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

    self.slots = {generals = {}, illusionCid = {}}

    self.playerGenerals = nil

    self.param = nil
    self.generalConfig = {}
    
end

return ascensionSendaiSlot