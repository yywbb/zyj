--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/6/28
-- Time: 17:13
-- To change this template use File | Settings | File Templates.
--



local deployment = {

    rootNode = nil,
    rootItems = nil,

    data = {},
    slotSpirit = {},
    buttontouch = -103,
    ListTableView = nil,

    position = {},
    celldict = {},

    zhenfa = {},

    showindex = 1,

    isfirst = true,
}

function deployment.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("soulzhen/soulzhen", nil, true, "soulzhen")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.midnode:setPositionY((toppos-1620)*0.5+740)

    self:initFixedString()

    for i=1,7 do
        self.position[i] = {}
        self.position[i].x = self.rootItems["general"..i]:getPositionX()
        self.position[i].y = self.rootItems["general"..i]:getPositionY()
    end


    self.rootItems.closeButton:addHandleOfControlEvent(function()
        print("back")
        --GameScene:shiftLayer("slotsInfo","up")
        GameScene:shiftLayer(GameScene.priorLayer,"up")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.buttontouch-1)


    local touchedGeneral = nil
    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.touchlayer,x,y) then
            for k,v in pairs(self.requesttable) do
                if self.postable[v].has and ui.isTouched(self.rootItems["general"..v],x,y) then
                    touchedGeneral = {node = self.rootItems["general"..v], sid = k,touchx = x, touchy = y }
                    touchedGeneral.node:setZOrder(1)
                    return true
                end
            end
        end
    end

    local function ccTouchMoved(x, y)
        if touchedGeneral then
            touchedGeneral.node:setPosition(self.postable[touchedGeneral.sid].x+(x-touchedGeneral.touchx)/GameScene.scaleNum,self.postable[touchedGeneral.sid].y+(y-touchedGeneral.touchy)/GameScene.scaleNum)
        end
    end

    local function ccTouchEnded(x, y)
        if touchedGeneral then
            local haschange = false
            for k,v in pairs(self.requesttable) do
                if k ~= touchedGeneral.sid and self.postable[v].has and ui.iscontendbynode(self.rootItems["general"..v],touchedGeneral.node:getPositionX(),touchedGeneral.node:getPositionY()) then
                    haschange = true
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
                gameTouch:clickprofbytime(1)
            end
            --确定变阵
            self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.5),CCCallFunc:create(function()
                local needchange = false
                for k,v in pairs(self.requesttable) do
                    if k~=v then
                        needchange = true
                    end
                end
                if needchange then
                    self.rootItems.touchlayer:setTouchEnabled(false)

                    UIRequest{type = 1009, ids = self.requesttable}
                end
            end)))
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

    self.data.slots = param or GameScene.layers["slotsInfo"].module.arrangedata or {}
    self.data.protagonist = GameScene.protagonist or {}

    self:reloadData()

    --
    self.zhenfa = gamedata.config.lingzhentu_zhenfa or {}
    --self:createList()
    --

    UIRequest({type = 4200})

    guide.controller:addComplete(198,function()
        UIRequest({type = 2882,opt=1,sysID=198})
    end)

end


function  deployment.reloadSlot(self)
    self.requesttable = {}
    self.postable = {}

    for i=1,7 do
        self.rootItems["general"..i]:setPosition(self.position[i].x,self.position[i].y)
        --
        self.rootItems["general"..i]:removeAllChildrenWithCleanup(true)
        self.postable[i] = {}
        if self.data.slots and self.data.slots[tostring(i)] and self.data.slots[tostring(i)].general and self.data.slots[tostring(i)].general.cid and self.data.slots[tostring(i)].general.cid > 0 then

            self.postable[i].ccb, self.postable[i].item = CCBReaderLoad("icons/new_IconLv", nil, true, "cell_buzhen")
            local config = gamedata.config.general[tostring(self.data.slots[tostring(i)].general.cid)]
            local g_data = {
                cid = self.data.slots[tostring(i)].general.cid,
                quality = config.quality,
                icon = config.icon,
                name = config.name,
                actor = config.actor,
                level = self.data.slots[tostring(i)].general.level1,
                level2 = self.data.slots[tostring(i)].general.level2,
                skilllevel = self.data.slots[tostring(i)].general.skilllevel,
            }
            -- 设置头像
            local generalData = self.data.slots[tostring(i)].general
            if generalData.illusionGeneralCid == nil then
                local gdata = ui.getConfigGeneral(generalData)
                if next(gdata) and config.fashion_id == 0 then
                    g_data.icon = gdata.icon
                end
            end
            ui.setIconLv(self.postable[i].item,g_data,nil,nil,true)

            self.postable[i].x =self.rootItems["general"..i]:getPositionX()
            self.postable[i].y = self.rootItems["general"..i]:getPositionY()
            self.requesttable[i] = i
            self.postable[i].has = true
            self.postable[i].lead = false
            self.postable[i].lock = false
            self.postable[i].ccb:setPosition(100,90)
            self.rootItems["general"..i]:addChild(self.postable[i].ccb)

        else

            self.postable[i].ccb, self.postable[i].item = CCBReaderLoad("icons/new_IconLv", nil, true, "cell_buzhen2")
            self.postable[i].x =self.rootItems["general"..i]:getPositionX()
            self.postable[i].y = self.rootItems["general"..i]:getPositionY()
            self.requesttable[i] = i
            self.postable[i].has = false
            self.postable[i].lead = false
            self.postable[i].lock = false
            self.postable[i].ccb:setPosition(100,90)
            self.rootItems["general"..i]:addChild(self.postable[i].ccb)
            ui.setIconLv(self.postable[i].item,{cid = 0})

        end

    end

end

function deployment.reloadData(self,data)
    if data then self.data.slots = data end

    self:reloadSlot()
    self.rootItems.touchlayer:setTouchEnabled(true)

end

function deployment.reloadSlotSpirit(self,data)
    if data then self.slotSpirit = data end
    --
    if self.isfirst then
        self.showindex = self.slotSpirit.use or 1
    end
    self.isfirst = false
    --
    if not self.ListTableView then
        self:createList()
        if self.showindex > 5 then
            self.ListTableView:setLuaContentOffset(0 - (self.showindex - 5) * 180, 0)
        end
    else
        self.ListTableView:reloadData()
    end

    --
    self:setSlotSpirit()

end

function deployment.createList(self)
    print("createList")

    self.celldict = {}
    local unrecycleCell = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(180, 180)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("soulzhen/soulzhenicon2", nil, true, "soulzhenicon2")
                self.celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler,index = a1+1 }
            else
                first = false
                cellCCB = self.celldict[a2].cellCCB
                ccbDocumentControler = self.celldict[a2].ccbDocumentControler
                self.celldict[a2].index = a1+1
            end
            --
            self.celldict[a2].cellCCB:setVisible(true)
            --
            ccbDocumentControler.z_selectEffect:removeAllChildrenWithCleanup(true)
            if a1+1 == self.showindex then
                local eccb,eitem = CCBReaderLoad("UIEffect/zhenrongxuanzhong/zhenrongxuanzhong", nil, true, "zhenrongxuanzhong")
                ccbDocumentControler.z_selectEffect:addChild(eccb)
            end
            --
            ccbDocumentControler.z_uselab:setString(gameConfig.strings:string_common("fixedString","deployment",9))
            ccbDocumentControler.z_name:setString(self.zhenfa[tostring(a1+1)].name or "")
            ui.setLabelString(ccbDocumentControler.z_level,"等级:"..(self.slotSpirit.level[tostring(a1+1)] or 1),13)
            --
            if a1+1 == self.slotSpirit.use then
                ccbDocumentControler.z_use:setVisible(true)
            else
                ccbDocumentControler.z_use:setVisible(false)
            end
            --
            cellCCB:setPosition(90, 90)

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.zhenfa)
        elseif fn == "cellTouched" then
            gameTouch:clickprofbytime(0.5)
            if a1:getIdx()+1 ~= self.showindex then
                self.showindex = a1:getIdx()+1
                self:reloadSlotSpirit()
            end
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

--
function deployment.setSlotSpiritShow(self)
    local zhenconfig = gamedata.config.lingzhentu_zhenfa or {}
    if not zhenconfig[tostring(self.showindex)] then return end
    --
    self.rootItems.zhenname:setString(zhenconfig[tostring(self.showindex)].name or "")
    ui.setLabelString(self.rootItems.zhendesc,zhenconfig[tostring(self.showindex)].desc or "",14)
    --
    local condconfig = gamedata.config.lingzhentu_cond or {}
    if not condconfig[tostring(self.showindex)] then return end
    for i = 1,7 do
        if condconfig[tostring(self.showindex)][tostring(i)] then
            ui.setLabelString(self.rootItems["activation_desc"..(i==1 and "" or ("_"..(i-1)))],condconfig[tostring(self.showindex)][tostring(i)].desc or "",13)
        else
            ui.setLabelString(self.rootItems["activation_desc"..(i==1 and "" or ("_"..(i-1)))],"",13)
        end
    end
    --
    --
    local level = 1
    if self.slotSpirit.level and self.slotSpirit.level[tostring(self.showindex)] then
        level = self.slotSpirit.level[tostring(self.showindex)]
    end
    local jihuoconfig = gamedata.config.lingzhentu_jihuo or {}
    if not jihuoconfig[tostring(self.showindex)] then return end
    for i = 1,7 do
        if jihuoconfig[tostring(self.showindex)][tostring(i)] and jihuoconfig[tostring(self.showindex)][tostring(i)]["addition"..level] and jihuoconfig[tostring(self.showindex)][tostring(i)]["addition"..level] ~= "" then
            ui.setLabelString(self.rootItems["activationLab"..i],gameConfig.strings:slotSpiritActivation(i),4)
            local attr,num = ui.getSTRandNUM(jihuoconfig[tostring(self.showindex)][tostring(i)]["addition"..level])
            ui.setLabelString(self.rootItems["activationAttr"..i],(gameConfig.strings.attr_type[attr] or "").." +"..(num or 0),2)
        else
            ui.setLabelString(self.rootItems["activationLab"..i],"",4)
            ui.setLabelString(self.rootItems["activationAttr"..i],"",2)
        end
    end
    --
    self:setSlotSpiritActivation()
end

function deployment.setSlotSpiritActivation(self)
    if self.slotSpirit.use and self.slotSpirit.use == self.showindex then
        local activationNum = 0
        for k,v in pairs(self.slotSpirit.activation or {}) do
            if v == 1 then
                activationNum = activationNum+1
            end
        end
        for i = 1,7 do
            if self.slotSpirit.activation and self.slotSpirit.activation[tostring(i)] and self.slotSpirit.activation[tostring(i)] == 1 then
                ui.setLabelString(self.rootItems["activation_desc"..(i==1 and "" or ("_"..(i-1)))],nil,4)
            else
                ui.setLabelString(self.rootItems["activation_desc"..(i==1 and "" or ("_"..(i-1)))],nil,13)
            end
            if activationNum >= i then
                -- ui.removeGray("CCLabelTTF",self.rootItems["activationLab"..i])
                -- ui.removeGray("CCLabelTTF",self.rootItems["activationAttr"..i])
                ui.setLabelString(self.rootItems["activationLab"..i],nil,4)
                ui.setLabelString(self.rootItems["activationAttr"..i],nil,2)
            else
                -- ui.addGray("CCLabelTTF",self.rootItems["activationLab"..i])
                -- ui.addGray("CCLabelTTF",self.rootItems["activationAttr"..i])
                ui.setLabelString(self.rootItems["activationLab"..i],nil,13)
                ui.setLabelString(self.rootItems["activationAttr"..i],nil,13)
            end
        end
    else
        for i = 1,7 do
            ui.setLabelString(self.rootItems["activation_desc"..(i==1 and "" or ("_"..(i-1)))],nil,13)
            -- ui.addGray("CCLabelTTF",self.rootItems["activationLab"..i])
            -- ui.addGray("CCLabelTTF",self.rootItems["activationAttr"..i])
            ui.setLabelString(self.rootItems["activationLab"..i],nil,13)
            ui.setLabelString(self.rootItems["activationAttr"..i],nil,13)
        end
    end
end

function deployment.reloadPower(self,power)
    if self.slotSpirit.power then
        self.slotSpirit.power = power
        self.rootItems.power:setString(self.slotSpirit.power)
    end
end

function deployment.setSlotSpirit(self)
    if self.slotSpirit.power then
        self.rootItems.power:setString(self.slotSpirit.power)
    end
    if self.slotSpirit.add then
        ui.setLabelString(self.rootItems.addNum,self.slotSpirit.add..(self.slotSpirit.add>0 and "%" or ""),14)
    end
    --
    if self.slotSpirit.use and (self.slotSpirit.use == self.showindex) then
        ui.addGray("CCControlButton", self.rootItems.useButton)
    else
        ui.removeGray("CCControlButton", self.rootItems.useButton)
    end
    ui.setLabelString(self.rootItems.useLab,nil,18)
    ui.setLabelString(self.rootItems.upLab,nil,18)
    self.rootItems.useButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        if self.slotSpirit.use and (self.slotSpirit.use == self.showindex) then
            --runGamePrompt({msg = "使用中"})
            runGamePrompt({msg = gameConfig.strings:string_common("slotspirit",1)})
        else
            UIRequest{type = 4201, id = self.showindex}
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.useButton:setSwallowsTouch(true)
    self.rootItems.useButton:setTouchPriority(self.buttontouch-1)
    --
    self.rootItems.addButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        UIRequest{type = 4204, opt = "addmain"}
    end, CCControlEventTouchUpInside)
    self.rootItems.addButton:setSwallowsTouch(true)
    self.rootItems.addButton:setTouchPriority(self.buttontouch-1)
    --
    self.rootItems.upButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        --
        gameWindows:openWindow("deploymentLevelUp",{slotSpirit = self.slotSpirit, showindex = self.showindex })
    end, CCControlEventTouchUpInside)
    self.rootItems.upButton:setSwallowsTouch(true)
    self.rootItems.upButton:setTouchPriority(self.buttontouch-1)
    --

    self:setSlotSpiritShow()
end

function deployment.clear(self)
    self.isfirst = true
    self.ListTableView = nil
    self.data = {}
    self.slotSpirit = {}
    self.celldict = {}
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function deployment.initFixedString(self)
    self.rootItems.fixlab2:setString(gameConfig.strings:string_common("fixedString","deployment",2))
    self.rootItems.fixlab3:setString(gameConfig.strings:string_common("fixedString","deployment",3))
    self.rootItems.fixlab4:setString(gameConfig.strings:string_common("fixedString","deployment",4))
    self.rootItems.fixlab5:setString(gameConfig.strings:string_common("fixedString","deployment",5))
end

return deployment