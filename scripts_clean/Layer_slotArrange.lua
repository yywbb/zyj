--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 16/2/2
-- Time: 下午1:48
-- To change this template use File | Settings | File Templates.
--



local slotarrange = {

    rootNode = nil,
    rootItems = nil,

    data = {},

    buttontouch = -103,
    ListTableView = nil,
    showgenerals = {},

    position = {},
    celldict = {},
}

function slotarrange.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("slotarrange/kingman_buzhen", nil, true, "kingman_buzhen")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.midnode:setPositionY((toppos-1620)*0.15+930)
    self.rootItems.bg:setPositionY(toppos/2)

    self.rootItems.midgeneralnode:setContentSize(CCSizeMake(800,(toppos-1620)*0.6+750))
    self.awakenConfig = gamedata.config.general_awaken
    for i=1,7 do
        self.position[i] = {}
        self.position[i].x = self.rootItems["general"..i]:getPositionX()
        self.position[i].y = self.rootItems["general"..i]:getPositionY()
        self.position[i].y = self.position[i].y*(((toppos-1620)*0.6+750)/750)
        self.rootItems["general"..i]:setPositionY(self.position[i].y)
        self.rootItems["obz"..i]:setPositionY(self.position[i].y)
    end

    self.rootItems.i_button:addHandleOfControlEvent(function()
        print("mochong")
        local cb = function( temiid )
            if temiid == self.data.slots.pet then
            else
                self.needpetreset = true
                UIRequest({type = 3703, param = self.data.param, generals = self.data.slots.generals, pet = temiid})
            end
        end
        gameWindows:openWindow("singlebosschongwuselect",{pets = self.data.pets, iid = self.data.slots.pet},cb)
    end, CCControlEventTouchUpInside)
    self.rootItems.i_button:setSwallowsTouch(true)
    self.rootItems.i_button:setTouchPriority(self.buttontouch-1)

    self.rootItems.backBtn:addHandleOfControlEvent(function()
        print("back")
        UIRequest({type = 3700})
    end, CCControlEventTouchUpInside)
    self.rootItems.backBtn:setSwallowsTouch(true)
    self.rootItems.backBtn:setTouchPriority(self.buttontouch-1)

    --
    if param.param and param.param.id and param.param.id == 140 then
        self.rootItems.otherBtn1:setVisible(true)
        self.rootItems.otherBtn2:setVisible(true)
        if param.param and param.param.param and param.param.param == 2 then
            self.rootItems.otherBg1:setVisible(false)
            self.rootItems.otherBg2:setVisible(true)
            self.rootItems.title:setString("魔吕布布阵")
        else
            self.rootItems.otherBg1:setVisible(true)
            self.rootItems.otherBg2:setVisible(false)
            self.rootItems.title:setString("如来布阵")
        end
    else
        self.rootItems.otherBg1:setVisible(false)
        self.rootItems.otherBg2:setVisible(false)
        self.rootItems.otherBtn1:setVisible(false)
        self.rootItems.otherBtn2:setVisible(false)
    end
    --
    self.rootItems.otherBtn1:addHandleOfControlEvent(function()
        print("otherBtn")
        if param.param and param.param.param and param.param.param == 2 then
            UIRequest({type = 3700,param = "noupdate"})
            UIRequest({type = 3702,id = 140,param = 1})
        else
            runGamePrompt({msg = "当前为如来布阵"})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.otherBtn1:setSwallowsTouch(true)
    self.rootItems.otherBtn1:setTouchPriority(self.buttontouch-1)
    --
    self.rootItems.otherBtn2:addHandleOfControlEvent(function()
        print("otherBtn")
        if param.param and param.param.param and param.param.param == 1 then
            UIRequest({type = 3700,param = "noupdate"})
            UIRequest({type = 3702,id = 140,param = 2})
        else
            runGamePrompt({msg = "当前为魔吕布布阵"})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.otherBtn2:setSwallowsTouch(true)
    self.rootItems.otherBtn2:setTouchPriority(self.buttontouch-1)
    --

    local touchedGeneral = nil
    local touchgeneral = nil
    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.touchlayer,x,y) then
            if ui.isTouched(self.rootItems.midgeneralnode,x,y) then
                print("midgeneralnode")
                for k,v in pairs(self.requesttable) do
                    if self.postable[v].has and ui.isTouched(self.rootItems["general"..v],x,y) then
                        print(k,v)
                        touchedGeneral = {node = self.rootItems["general"..v], sid = k,touchx = x, touchy = y }
                        touchedGeneral.node:setZOrder(1)
                        return true
                    end
                end
            elseif ui.isTouched(self.rootItems.listscroll,x,y) then
                print("listscroll")
                for k,v in pairs(self.celldict) do
                    if ui.isTouched(v.cellCCB,x,y) then
                        touchgeneral = {node = self.rootItems.touchgeneral, index = v.index, touchx = x, touchy = y }
                        touchgeneral.node:setZOrder(1)
                        self.rootItems.touchgeneral:setVisible(false)
                        ui.setNewIcon(self.rootItems,self.showgenerals[v.index],1)
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
                        v.cellCCB:setVisible(false)
                    end
                end
            end
        end
    end

    local function ccTouchEnded(x, y)
        if touchedGeneral then
            local haschange = false
            for k,v in pairs(self.requesttable) do
                if k ~= touchedGeneral.sid and self.postable[v].has and ui.iscontendbynode(self.rootItems["general"..v],touchedGeneral.node:getPositionX(),touchedGeneral.node:getPositionY()) then
                    haschange = true
                    print(v,touchedGeneral.sid)
                    local moveto =  CCMoveTo:create(0.2, ccp(self.postable[k].x,self.postable[k].y))
                    touchedGeneral.node:runAction(moveto)
                    local moveto2 =  CCMoveTo:create(0.2, ccp(self.postable[touchedGeneral.sid].x,self.postable[touchedGeneral.sid].y))
                    self.rootItems["general"..v]:runAction(moveto2)
                    local postemp = self.requesttable[k]
                    self.requesttable[k] = self.requesttable[touchedGeneral.sid]
                    self.requesttable[touchedGeneral.sid] = postemp
                    --                    touchedGeneral.node:setPosition(self.postable[i].x,self.postable[i].y)
                    --                    self.rootItems["general"..i]:setPosition(self.postable[touchedGeneral.sid].x,self.postable[touchedGeneral.sid].y)
                    break
                end
            end
            if not haschange then
                local moveto2 =  CCMoveTo:create(0.2, ccp(self.postable[touchedGeneral.sid].x,self.postable[touchedGeneral.sid].y))
                touchedGeneral.node:runAction(moveto2)
            end
            touchedGeneral.node:setZOrder(0)
            touchedGeneral = nil

            if haschange then
                gameTouch:clickprofbytime(0.5)
            end
            --确定变阵
            self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.5),CCCallFunc:create(function()
                printT(self.requesttable,"requesttable====")
                local needchange = false
                for k,v in pairs(self.requesttable) do
                    if k~=v then
                        needchange = true
                    end
                end
                if needchange then
                    local generals = {}
                    for i = 1,7 do
                        generals[tostring(i)] = self.data.slots.generals[tostring(self.requesttable[i])] or 0
                    end
                    self.needslotreset =true
                    self.rootItems.touchlayer:setTouchEnabled(false)
                    UIRequest({type = 3703, param = self.data.param, generals = generals, pet = self.data.slots.pet})
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
                    if (not self.postable[v].lead) and (not self.postable[v].lock) then
                        local generals = table.copy(self.data.slots.generals)
                        generals[tostring(v)] = self.showgenerals[touchgeneral.index].iid
                        self.needslotreset =true
                        self.needgeneralreset =true
                        UIRequest({type = 3703, param = self.data.param, generals = generals, pet = self.data.slots.pet})
                        break
                    end
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

    self.data = param

    self.needpetreset = true
    self.needslotreset = true
    self.needgeneralreset = true

    self:reloadData()
end

function slotarrange.reloadPet(self)
    ui.setNewIcon(self.rootItems,{cid = 0})
    if self.data.slots.pet and  self.data.slots.pet > 0 then
        if self.data.pets[tostring(self.data.slots.pet)] then
            local configdata = gamedata.config.pet3_attr[tostring(self.data.pets[tostring(self.data.slots.pet)].cid)][tostring(self.data.pets[tostring(self.data.slots.pet)].level)]
            setSpriteFrameByName(self.rootItems.i_icon, configdata.icon or "alpha")
            ui.setSpriteTextureRect(self.rootItems.i_icon,0,0,150,150)
        end
    end
end

function  slotarrange.reloadGeneral(self)
    self.showgenerals = {}
    local showgenerals = table.copy(self.data.generals) or {}
    for k,v in pairs(self.data.slots.generals) do
        if v > 0 and showgenerals[tostring(v)] then
            showgenerals[tostring(v)] = nil
        end
    end
    for k,v in pairs(showgenerals) do
        table.insert(self.showgenerals,v)
    end

    local sortBy = function(a,b)
        if a.quality == b.quality then
            if a.level1 == b.level1 then
                if a.level2 == b.level2 then
                    return a.cid>b.cid
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
    table.sort(self.showgenerals, sortBy)

    if not self.ListTableView then
        self:createList()
    else
        self.ListTableView:reloadData()
    end
end

function  slotarrange.reloadSlot(self)
    self.requesttable = {}
    self.postable = {}
    local requesttable = self.requesttable
    local postable = self.postable

    for i=1,7 do
        self.rootItems["general"..i]:setPosition(self.position[i].x,self.position[i].y)
        self.rootItems["general"..i]:removeAllChildrenWithCleanup(true)
        postable[i] = {}
        if self.data.slots and self.data.slots.generals and self.data.slots.generals[tostring(i)] and self.data.slots.generals[tostring(i)] > 0 then
            if self.data.protagonist and self.data.protagonist.iid and self.data.protagonist.iid == self.data.slots.generals[tostring(i)] then
                postable[i].ccb, postable[i].item = CCBReaderLoad("slotsInfo/generalInfo", nil, true, "cell_buzhen")
                local config = gamedata.config.general[tostring(self.data.protagonist.cid)]
                local g_data = {
                    quality = config.quality,
                    icon = config.icon,
                    name = config.name,
                    actor = config.actor,
                    level = self.data.protagonist.level1,
                    level2 = self.data.protagonist.level2,
                    awakenicon = -1,
                    awakenstage = -1,
                }
                -- 设置头像
                local generalData = self.data.generals[tostring(self.data.slots.generals[tostring(i)])] or {}
                if next(generalData) and generalData.illusionGeneralCid == nil then
                    local gdata = ui.getConfigGeneral(generalData)
                    if next(gdata) and config.fashion_id == 0 then
                        g_data.icon = gdata.icon
                    end
                end
                ui.setGeneralIconL2(g_data,postable[i].item)

                postable[i].x =self.rootItems["general"..i]:getPositionX()
                postable[i].y = self.rootItems["general"..i]:getPositionY()
                requesttable[i] = i
                postable[i].has = true
                postable[i].lead = true
                postable[i].lock = false
                postable[i].ccb:setPosition(175,90)
                self.rootItems["general"..i]:addChild(postable[i].ccb)
            elseif self.data.generals and self.data.generals[tostring(self.data.slots.generals[tostring(i)])] then
                postable[i].ccb, postable[i].item = CCBReaderLoad("slotsInfo/generalInfo", nil, true, "cell_buzhen")
                local config = gamedata.config.general[tostring(self.data.generals[tostring(self.data.slots.generals[tostring(i)])].cid)]
                
                local awakenicon,awakenstage = -1,-1
                if gamedata.config.general[tostring(self.data.generals[tostring(self.data.slots.generals[tostring(i)])].cid)].awaken > 0  and self.data.generals[tostring(self.data.slots.generals[tostring(i)])].skilllevel > 0 then
                    awakenicon = self.awakenConfig[tostring(self.data.generals[tostring(self.data.slots.generals[tostring(i)])].skilllevel)].icon
                end 
                if gamedata.config.general[tostring(self.data.generals[tostring(self.data.slots.generals[tostring(i)])].cid)].awaken > 0  and self.data.generals[tostring(self.data.slots.generals[tostring(i)])].skilllevel > 0 then
                    awakenstage = self.awakenConfig[tostring(self.data.generals[tostring(self.data.slots.generals[tostring(i)])].skilllevel)].stage
                end 

                local g_data = {
                    quality = config.quality,
                    icon = config.icon,
                    name = config.name,
                    actor = config.actor,
                    level = self.data.generals[tostring(self.data.slots.generals[tostring(i)])].level1,
                    level2 = self.data.generals[tostring(self.data.slots.generals[tostring(i)])].level2,
                    awakenicon = awakenicon,
                    awakenstage = awakenstage,
                }
                -- 设置头像
                local generalData = self.data.generals[tostring(self.data.slots.generals[tostring(i)])] or {}
                if next(generalData) and generalData.illusionGeneralCid == nil then
                    local gdata = ui.getConfigGeneral(generalData)
                    if next(gdata) and config.fashion_id == 0 then
                        g_data.icon = gdata.icon
                    end
                end
                ui.setGeneralIconL2(g_data,postable[i].item)
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

function slotarrange.reloadData(self,data)
    if data then self.data = data end

    self.rootItems.power:setString("战斗力:"..self.data.slots.power)

    if self.needpetreset then self:reloadPet() self.needpetreset = false end
    if self.needslotreset then self:reloadSlot() self.needslotreset = false end
    if self.needgeneralreset then self:reloadGeneral() self.needgeneralreset = false end

    self.rootItems.touchlayer:setTouchEnabled(true)

--    --
--    local config = gamedata.config.personalboss_att
--    local bossconfig = {}
--    for k,v in pairs(config) do
--        if tonumber(k)%100 == 1 and self.data.param.param == v["function"] then
--            bossconfig = v
--            break
--        end
--    end
--    self.rootItems.title:setString(bossconfig.name.."布阵")
    --
end



function slotarrange.createList(self)
    print("createList")

    self.celldict = {}
    local unrecycleCell = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(200, 200)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("icons/new_iconName2", nil, true, "new_iconName2")
                self.celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler,index = a1+1 }
            else
                first = false
                cellCCB = self.celldict[a2].cellCCB
                ccbDocumentControler = self.celldict[a2].ccbDocumentControler
                self.celldict[a2].index = a1+1
            end
            --
            self.celldict[a2].cellCCB:setVisible(true)
            -- 设置头像
            local generalData = self.showgenerals[a1+1]
            if generalData.illusionGeneralCid == nil then
                local configGeneral = gamedata.config.general[tostring(generalData.cid)]
                local gdata = ui.getConfigGeneral(generalData)
                if next(gdata) and configGeneral.fashion_id == 0 then
                    self.showgenerals[a1+1].icon = gdata.icon
                end
            end
            ui.setNewIconName(ccbDocumentControler,self.showgenerals[a1+1])
            --
            cellCCB:setPosition(100, 160)

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


function slotarrange.clear(self)
    self.ListTableView = nil
    self.data = {}
    self.celldict = {}
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

return slotarrange