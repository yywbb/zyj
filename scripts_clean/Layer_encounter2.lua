--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-7-28
-- Time: 下午4:43
-- To change this template use File | Settings | File Templates.
--

local encounter = {

    resource = nil,

    rootNode = nil,
    rootItems = nil,

    encounterData = nil,

    createdItems = {},
    sid = 1,
    maxsid = 0,
    iconListTableView = nil,
    isContentScroll = false,
    touchX = 0,
    contentoffsetx = 0,
    xnum = 0,
}

function encounter.clear(self)

    for k,v in pairs(self.createdItems) do
        self:removePage(k)
    end

    self.rootItems = nil

    self.createdItems = {}
    self.sid = 1
    self.maxsid = 0
    self.iconListTableView = nil
    self.isContentScroll = false
    self.touchX = 0
    self.contentoffsetx = 0
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function encounter.init(self,parent,toppos)
    self.toppos = toppos
    self.rootNode,self.rootItems = CCBReaderLoad("encounter2_new/encounter2", nil, true, "encounter")

    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)

    self.contentCellSize = {x = gameConfig.originSize.width, y= toppos}
    self.rootItems.touchLayer:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos))

    self.rootItems.encounterScroll = tolua.cast(self.rootItems.encounterScroll, "CCScrollView")
    self.rootItems.encounterScroll:setTouchPriority(-101)
    self.rootItems.encounterScroll:setTouchEnabled(false)

    --self.rootItems.encounterScroll:setPositionY(gameConfig.maiscenebottomheight)

    local function ccTouchBegan(x, y)
        self.isContentScroll = false
        self.touchX = x
        self.contentoffsetx = self.rootItems.encounterScroll:getContentOffset().x
        return true
    end

    local function ccTouchMoved(x, y)
        if math.abs(x - self.touchX) > 10 then
            self.isContentScroll = true
        end

        if math.abs(x - self.touchX) > 30 then
            local offsetX = self.contentoffsetx + (x - self.touchX)
            self.rootItems.encounterScroll:setContentOffset(ccp(offsetX, self.rootItems.encounterScroll:getContentOffset().y))
        end
    end

    local function ccTouchEnded(x, y)
        if self.touchX - x > 20 then
            if self.sid+1 <= self.maxsid then
                self:reload(self.sid+1)
            else
                self:reload(self.sid)
            end
        elseif self.touchX - x < -20 then
            if self.sid-1 >0 then
                self:reload(self.sid-1)
            else
                self:reload(self.sid)
            end
        else
            --self:reload(self.sid)
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

    self.rootItems.touchLayer:registerScriptTouchHandler(onTouch, false, -101, false)
    self.rootItems.touchLayer:setTouchPriority(-101)
    self.rootItems.touchLayer:setTouchEnabled(true)

    --if not GameScene:checkUpdate(1310) then
        self:reloadData()
    --end

end

function encounter.reloadData(self, data)

    for k,v in pairs(self.createdItems) do
        self:removePage(k)
    end

    if data then
        self.encounterData = data.encounters
    end

    if table.getTableLength(self.encounterData) == 0 then
        GameScene:shiftLayer("main","down")
        return
    end


    self.maxsid = table.getTableLength(self.encounterData)

    if not self.iconListTableView then
        self:createIconList()
    else
        self.iconListTableView:reloadData()
    end


    self.rootItems.container:removeAllChildrenWithCleanup(true)
    self.createdItems = {}
    self.rootItems.container:setContentSize(CCSize(1080 * self.maxsid,self.toppos))

    if table.getTableLength(self.encounterData) == 0 then
        self.maxsid = 1
        local CCB, ccbDoc = CCBReaderLoad("encounter2_new/container.ccbi", nil, true, "container")
        self.rootItems.container:addChild(CCB)
        --self.rootItems.noSprite:setVisible(true)
        self.rootItems.encounterScroll:setContentOffset(ccp(0, 0))
    else
        --self.rootItems.noSprite:setVisible(false)
        self:reload(self.sid,true)
    end
end

function encounter.createIconList(self)
    print("reloadIconList")

    local celldict = {}
    local IconListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(180, 180)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("icons/activity_icon.ccbi", nil, true, "encounter_icon")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimationH(self.iconListTableView,cellCCB,180,180,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local celldata = self.encounterData[tostring(a1+1)]

            self:setEncounterIcon(ccbDocumentControler,celldata)

            if self.iconListTableView then
                cellCCB:setPosition(180/2, 180/2)
            end

            ccbDocumentControler.i_selected:setVisible(false)
            ccbDocumentControler.i_quality_k:setScale(0.89)
            ccbDocumentControler.i_quality_d:setScale(0.89)

            ccbDocumentControler.i_selectEffect:removeAllChildrenWithCleanup(true)

            cellCCB:setScale(1)
            if a1+1 == self.sid then
                local eccb,eitem = CCBReaderLoad("UIEffect/zhenrongxuanzhong/zhenrongxuanzhong", nil, true, "zhenrongxuanzhong")
                ccbDocumentControler.i_selectEffect:addChild(eccb)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.encounterData)
        elseif fn == "cellTouched" then
            self:reload(a1:getIdx()+1)
        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.iconListTableView = ui.createLuaTableView({
        handle = IconListHandle,
        viewwidth = self.rootItems.listscroll:getContentSize().width,
        viewheight = self.rootItems.listscroll:getContentSize().height,
        dire = 0
    })
    self.iconListTableView:setTouchPriority(-101)
    self.rootItems.listscroll:addChild(self.iconListTableView)

end

function encounter.loadPage(self,sid)
    if not self.createdItems[sid] and sid >=1 and sid<= self.maxsid then
        local configdata = {type = ""}
        if self.encounterData[tostring(sid)] then
            configdata = gamedata.config.encounter[tostring(self.encounterData[tostring(sid)].cid)] or {type = ""}
        end
        local CCB, ccbDoc = 0,0
        if configdata.type == "exp" then
            CCB, ccbDoc = CCBReaderLoad("encounter2_new/n_cell_encounter2_1.ccbi", nil, true, "n_cell_encounter2_1")
            --ui.setSpriteTextureRect(ccbDoc.ccb_bg,0,0,1080,1100)
            ccbDoc.ccb_topNode:setPositionY(self.toppos-250)
            --ccbDoc.ccb_midNode:setPositionY((self.toppos-gameConfig.maiscenebottomheight)/2+gameConfig.maiscenebottomheight)
            ccbDoc.ccb_bottomNode:setPositionY(gameConfig.maiscenebottomheight+300)
            self:setEncounterExp(ccbDoc,self.encounterData[tostring(sid)])
        elseif configdata.type == "search" then
            CCB, ccbDoc = CCBReaderLoad("encounter2_new/n_cell_encounter2_3.ccbi", nil, true, "n_cell_encounter2_3")
            --ui.setSpriteTextureRect(ccbDoc.ccb_bg,0,0,1080,1100)
            ccbDoc.ccb_topNode:setPositionY(self.toppos-250)
            --ccbDoc.ccb_midNode:setPositionY((self.toppos-gameConfig.maiscenebottomheight)/2+gameConfig.maiscenebottomheight)
            ccbDoc.ccb_bottomNode:setPositionY(gameConfig.maiscenebottomheight+300)
            self:setEncounterSearch(ccbDoc,self.encounterData[tostring(sid)])
        elseif configdata.type == "battle" then
            CCB, ccbDoc = CCBReaderLoad("encounter2_new/n_cell_encounter2_4.ccbi", nil, true, "n_cell_encounter2_4")
            --ui.setSpriteTextureRect(ccbDoc.ccb_bg,0,0,1080,1100)
            ccbDoc.ccb_topNode:setPositionY(self.toppos-250)
            --ccbDoc.ccb_midNode:setPositionY((self.toppos-gameConfig.maiscenebottomheight)/2+gameConfig.maiscenebottomheight)
            ccbDoc.ccb_bottomNode:setPositionY(gameConfig.maiscenebottomheight+300)
            self:setEncounterBattle(ccbDoc,self.encounterData[tostring(sid)])
        elseif configdata.type == "general" then
            CCB, ccbDoc = CCBReaderLoad("encounter2_new/n_cell_encounter2_2.ccbi", nil, true, "n_cell_encounter2_2")
            --ui.setSpriteTextureRect
            ccbDoc.ccb_topNode:setPositionY(self.toppos-250)
            --ccbDoc.ccb_midNode:setPositionY((self.toppos-gameConfig.maiscenebottomheight)/2+gameConfig.maiscenebottomheight)
            ccbDoc.ccb_bottomNode:setPositionY(gameConfig.maiscenebottomheight+300)
            self:setEncounterGeneral(ccbDoc,self.encounterData[tostring(sid)])
        elseif configdata.type == "shop" then
            CCB, ccbDoc = CCBReaderLoad("encounter2_new/n_cell_encounter2_5.ccbi", nil, true, "n_cell_encounter2_5")
            --ui.setSpriteTextureRect(ccbDoc.ccb_bg,0,0,1080,1100)
            ccbDoc.ccb_topNode:setPositionY(self.toppos-250)
            --ccbDoc.ccb_midNode:setPositionY((self.toppos-gameConfig.maiscenebottomheight)/2+gameConfig.maiscenebottomheight)
            ccbDoc.ccb_bottomNode:setPositionY(gameConfig.maiscenebottomheight+300)
            self:setEncounterShop(ccbDoc,self.encounterData[tostring(sid)])
        else
            CCB, ccbDoc = CCBReaderLoad("encounter2_new/container.ccbi", nil, true, "container")
        end
        CCB:setPosition(1080*(sid-1),0)
        self.rootItems.container:addChild(CCB)
        self.createdItems[sid] = {ccb = CCB,item = ccbDoc}
    end
end

function encounter.removePage(self,sid)
    if self.createdItems[sid] and self.encounterData[tostring(sid)] then
        gameTimer:UnrigistTime("encounter_"..self.encounterData[tostring(sid)].iid)
        gameTimer:UnrigistTimeFunc("encounter_"..self.encounterData[tostring(sid)].iid)
        self.createdItems[sid].ccb:removeAllChildrenWithCleanup(true)
        self.createdItems[sid].ccb:removeFromParentAndCleanup(true)
        self.createdItems[sid] = nil
    end
end

function encounter.loadPages(self)
    for k,v in pairs(self.createdItems) do
        if k>= self.sid-1 and k<= self.sid+1 then
        else
            self:removePage(k)
        end
    end
    self:loadPage(self.sid)
    self:loadPage(self.sid+1)
    self:loadPage(self.sid-1)
end

function encounter.reload(self,sid,isfirst)
    if sid > self.maxsid then
        sid = self.maxsid
    end
    self.sid = sid

    if self.rootItems then
        if isfirst then
            self.rootItems.container:setPosition(ccp(-1080*(self.sid-1), 0))
            self:loadPages()
        else
            self.iconListTableView:reloadData()

            if  180 * self.sid >  self.rootItems.listscroll:getContentSize().width - self.iconListTableView:getLuaContentOffsetX() then
                self.iconListTableView:setContentOffsetInDuration(ccp(self.rootItems.listscroll:getContentSize().width - 180 * self.sid,0),0.2)
            elseif 180 * (self.sid-1) < -self.iconListTableView:getLuaContentOffsetX() then
                self.iconListTableView:setContentOffsetInDuration(ccp(-180 * (self.sid-1) ,0),0.2)
            end

            local moveto = CCMoveTo:create(0.2, ccp(-1080*(self.sid-1), 0))
            self.rootItems.container:runAction(CCSequence:createWithTwoActions(moveto,CCCallFunc:create(function()
                self:loadPages()
            end)))
        end
        --self.rootItems.encounterScroll:setContentOffsetInDuration(ccp(-1080*(self.sid-1), 0), 0.2)
    end
end

function encounter.setEncounterIcon(self,item,data)
    local configdata = gamedata.config.encounter[tostring(data.cid)] or {}

    ui.setNavigationIcon2(item,{icon = gameConfig.images["encounter_icon_"..configdata.type],name = gameConfig.strings.encounterType[configdata.type],quality = configdata.quality})
end

function encounter.setTimer(self,data,timeUpdelete)
    local now = gamedata:time()
    if data.time - (now - data.beginT) > 0 then
        gameTimer:rigistTime("encounter_"..data.iid, data.time - (now - data.beginT))
    else
        if  timeUpdelete  then
            UIRequest({type = 13111, iid = data.iid})
        end
    end
end

function encounter.setEncounterExp(self,item,data)
    self:setTimer(data,true)

    if item.halfLab then
        item.halfLab:setVisible(false)
    end
    local modulus = 1

    if gameTimer.times["encounter_"..data.iid] and gameTimer.times["encounter_"..data.iid] > 0 then
        gameTimer:rigistTimeFunc("encounter_"..data.iid,function()
            if gameTimer.times["encounter_"..data.iid] > 0 then
                if item and item.time then
                    item.time:setString(ui.makeTimeText(gameTimer.times["encounter_"..data.iid],"hour"))
                end
            else
                if item and item.time then
                    item.time:setString("00:00:00")
                end
                UIRequest({type = 13111, iid = data.iid})
            end
        end)
    else

        item.time:setString("00:00:00")
        UIRequest({type = 13111, iid = data.iid})
    end

    ui.setLabelString(item.doLab,nil,19)
    item.doButton:setTouchPriority(-101)
    item.doButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        UIRequest({type = 1311, iid = data.iid, method = 1})
        gamedata.music:PlayOptSound("lmqy")
    end, CCControlEventTouchUpInside)

    local ad = require"adChannel"
    if ad:showOrNot() then
        --看广告双倍
        item.goldNode:setVisible(false)
        item.adNode:setVisible(true)
        ui.setLabelString(item.doLab2,gameConfig.strings:string_common("fixedString","encounter",31),19)
        item.doButton2:setTouchPriority(-101)
        item.doButton2:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            gamedata.sdk:showAd(2,{type = 1311, iid = data.iid, method = 3, modulus = modulus, xgold = math.floor(tonumber(gamedata.config.global_kv.adventure_exp_cost.value)*modulus) or 0})
            gamedata.music:PlayOptSound("lmqy")
        end, CCControlEventTouchUpInside)
    else
        --消费元宝双倍
        if ui.CheckHuodongByParam(2) then
            modulus =  ui.GetHuodongModulus(2)
        -- if ui.CheckHuodongByParam(1) then
        --     modulus =  ui.GetHuodongModulus(1)
            if item.halfLab then
                item.halfLab:setVisible(true)
                ui.setLabelString(item.halfLab,gameConfig.strings:string_common("activityeveryday",7),24)
            end
        end

        ui.setLabelString(item.doLab2,nil,19)
        item.doButton2:setTouchPriority(-101)
        item.doButton2:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)

            local configdata = gamedata.config.encounter[tostring(data.cid)] or {}
            local cb = function()
                UIRequest({type = 1311, iid = data.iid, method = 2, modulus = modulus, xgold = math.floor(tonumber(gamedata.config.global_kv.adventure_exp_cost.value)*modulus) or 0})
            end
            --gameWindows:openWindow("confirm",{msg = configdata.prompt}, cb)
            local rich = {
                {fontID = 1,content = "是否消耗 ",},
                {fontID = 0,content = "obj_s_gold",},
                {fontID = 11,content = " "..math.floor(tonumber(gamedata.config.global_kv.adventure_exp_cost.value)*modulus),},
                {fontID = 1,content = " 获得双倍道具？",},
            }
            gameWindows:openWindow("confirm",{rich = rich}, cb)

            gamedata.music:PlayOptSound("lmqy")
        end, CCControlEventTouchUpInside)
        item.goldnum:setString( math.floor(tonumber(gamedata.config.global_kv.adventure_exp_cost.value)*modulus) or 0 )
    end

    --
    local configdata = gamedata.config.encounter[tostring(data.cid)] or {}
    local i_buf = string.find(configdata.param, ";",1)
    if i_buf then
        local rewardstr =  string.sub(configdata.param,i_buf+1,string.len(configdata.param))
        local reward_cid,reward_num  = ui.getIDandNUM(rewardstr)
        ui.setNewIcon(item,{cid = reward_cid})
        item.num:setString("X"..reward_num)
        item.i_button:setTouchPriority(-102)
        item.i_button:addHandleOfControlEvent(function()
            ui.setPopwindowByCid(reward_cid)
        end, CCControlEventTouchUpInside)
    end

end

function encounter.setEncounterSearch(self,item,data)
    self:setTimer(data,true)

    if item.halfLab then
        item.halfLab:setVisible(false)
    end
    local modulus = 1

    if gameTimer.times["encounter_"..data.iid] and gameTimer.times["encounter_"..data.iid] > 0 then
        gameTimer:rigistTimeFunc("encounter_"..data.iid,function()
            if gameTimer.times["encounter_"..data.iid] > 0 then
                if item and item.time then
                    item.time:setString(ui.makeTimeText(gameTimer.times["encounter_"..data.iid],"hour"))
                end
            else
                if item and item.time then
                    item.time:setString("00:00:00")
                end
                UIRequest({type = 13111, iid = data.iid})
            end
        end)
    else

        item.time:setString("00:00:00")
        UIRequest({type = 13111, iid = data.iid})
    end

    ui.setLabelString(item.doLab,nil,19)
    item.doButton:setTouchPriority(-101)
    item.doButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        UIRequest({type = 1311, iid = data.iid, method = 1})
        gamedata.music:PlayOptSound("lmqy")
    end, CCControlEventTouchUpInside)

    local ad = require"adChannel"
    if ad:showOrNot() then
        --看广告双倍
        item.goldNode:setVisible(false)
        item.adNode:setVisible(true)
        ui.setLabelString(item.doLab2,gameConfig.strings:string_common("fixedString","encounter",31),19)
        item.doButton2:setTouchPriority(-101)
        item.doButton2:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            gamedata.sdk:showAd(2,{type = 1311, iid = data.iid, method = 3, modulus = modulus, xgold = math.floor(tonumber(gamedata.config.global_kv.adventure_war_cost.value)*modulus) or 0})
            gamedata.music:PlayOptSound("lmqy")
        end, CCControlEventTouchUpInside)
    else
        --消费元宝双倍
        if ui.CheckHuodongByParam(2) then
            modulus =  ui.GetHuodongModulus(2)
        -- if ui.CheckHuodongByParam(1) then
        --     modulus =  ui.GetHuodongModulus(1)
            if item.halfLab then
                item.halfLab:setVisible(true)
                ui.setLabelString(item.halfLab,gameConfig.strings:string_common("activityeveryday",7),24)
            end
        end
        
        ui.setLabelString(item.doLab2,nil,19)
        item.doButton2:setTouchPriority(-101)
        item.doButton2:addHandleOfControlEvent(function()
             gameTouch:clickprofbytime(1)
             local configdata = gamedata.config.encounter[tostring(data.cid)] or {}
             local cb = function()
                UIRequest({type = 1311, iid = data.iid, method = 2, modulus = modulus, xgold = math.floor(tonumber(gamedata.config.global_kv.adventure_war_cost.value)*modulus) or 0})
             end
             --gameWindows:openWindow("confirm",{msg = configdata.prompt}, cb)
            local rich = {
                {fontID = 1,content = "是否消耗 ",},
                {fontID = 0,content = "obj_s_gold",},
                {fontID = 11,content = " "..math.floor(tonumber(gamedata.config.global_kv.adventure_war_cost.value)*modulus),},
                {fontID = 1,content = " 获得双倍宝物？",},
            }
            gameWindows:openWindow("confirm",{rich = rich}, cb)
    
             gamedata.music:PlayOptSound("lmqy")
        end, CCControlEventTouchUpInside)
    
        item.goldnum:setString( math.floor(tonumber(gamedata.config.global_kv.adventure_war_cost.value)*modulus) or 0 )    
    end

end

function encounter.setEncounterBattle(self,item,data)

    self:setTimer(data,true)
    if gameTimer.times["encounter_"..data.iid] and gameTimer.times["encounter_"..data.iid] > 0 then
        gameTimer:rigistTimeFunc("encounter_"..data.iid,function()
            if gameTimer.times["encounter_"..data.iid] > 0 then
                if item and item.time then
                    item.time:setString(ui.makeTimeText(gameTimer.times["encounter_"..data.iid],"hour"))
                end
            else
                if item and item.time then
                    item.time:setString("00:00:00")
                end
                UIRequest({type = 13111, iid = data.iid})
            end
        end)
    else

        item.time:setString("00:00:00")
        UIRequest({type = 13111, iid = data.iid})
    end

    ui.setLabelString(item.doLab,nil,19)
    item.doButton:setTouchPriority(-101)
    item.doButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        UIRequest({type = 1311, iid = data.iid, method = 2})
        gamedata.music:PlayOptSound("lmqy")
    end, CCControlEventTouchUpInside)

    ui.setLabelString(item.doLab2,nil,19)
    item.doButton2:setTouchPriority(-101)
    item.doButton2:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        UIRequest({type = 1311, iid = data.iid, method = 1})
        gamedata.music:PlayOptSound("lmqy")
    end, CCControlEventTouchUpInside)
    --
    local configdata = gamedata.config.encounter[tostring(data.cid)] or {}
    local i_buf = string.find(configdata.param, ";",1)
    if i_buf then
        local rewardstr =  string.sub(configdata.param,i_buf+1,string.len(configdata.param))
        local reward_cid,reward_num  = ui.getIDandNUM(rewardstr)
        ui.setNewIcon(item,{cid = reward_cid})
        item.num:setString("X"..reward_num)
        item.i_button:setTouchPriority(-102)
        item.i_button:addHandleOfControlEvent(function()
            ui.setPopwindowByCid(reward_cid)
        end, CCControlEventTouchUpInside)
    end
    --
end

function encounter.setEncounterGeneral(self,item,data)

    if item.halfLab then
        item.halfLab:setVisible(false)
    end
    local modulus = 1
    if ui.CheckHuodongByParam(2) then
        modulus =  ui.GetHuodongModulus(2)
    -- if ui.CheckHuodongByParam(1) then
    --     modulus =  ui.GetHuodongModulus(1)
        if item.halfLab then
            item.halfLab:setVisible(true)
            ui.setLabelString(item.halfLab,gameConfig.strings:string_common("activityeveryday",7),24)
        end
    end

    item.num1:setString(math.floor(data.xgold*modulus))

    if item.discountSpr and data.isfragment and data.isfragment == 1 then
        setSpriteFrameByName(item.discountSpr, data.zhe .. "zhe.png")
    elseif item.discountSpr then
        setSpriteFrameByName(item.discountSpr, "alpha")   
    end
    
    local encounterConfig = gamedata.config.encounter
    item.num2:setString(encounterConfig[tostring(data.cid)].original_price or "?")
    --item.num2:setString(math.floor(tonumber(data.xgold)*1.5))

    item.hasgold:setString(GameScene.roleinfo.gold or 0)

    print("generalcid:"..data.generalcid)
    if data.generalcid then
        -- item.generalName:setString(gamedata.config.general[tostring(data.generalcid)].name)
        ui.setLabelString(item.generalName,gamedata.config.general[tostring(data.generalcid)].name,gamedata.config.general[tostring(data.generalcid)].quality* 2 - 1)
        item["generalNode"]:removeAllChildrenWithCleanup(true)
        local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(data.generalcid)].animationid)].name
        local Gneral = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        Gneral:setAnimation("stand",true,0)
        Gneral:setScale(2.5)
        Gneral:setPosition(item.generalNode:getContentSize().width/2,0)
        item["generalNode"]:addChild(Gneral)
    end

    self:setTimer(data,true)
    if gameTimer.times["encounter_"..data.iid] and gameTimer.times["encounter_"..data.iid] > 0 then
        gameTimer:rigistTimeFunc("encounter_"..data.iid,function()
            if gameTimer.times["encounter_"..data.iid] > 0 then
                if item and item.time then
                    item.time:setString(ui.makeTimeText(gameTimer.times["encounter_"..data.iid],"hour"))
                end
            else
                if item and item.time then
                    item.time:setString("00:00:00")
                end
                UIRequest({type = 13111, iid = data.iid})
            end
        end)
    else

        item.time:setString("00:00:00")
        UIRequest({type = 13111, iid = data.iid})
    end

    item.iconButton:setTouchPriority(-101)
    item.iconButton:addHandleOfControlEvent(function()
        ui.setPopwindowByCid(data.generalcid)
    end, CCControlEventTouchUpInside)

    ui.setLabelString(item.doLab,nil,19)
    item.doButton:setTouchPriority(-101)
    item.doButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        UIRequest({type = 1311, iid = data.iid, method = 2})
        gamedata.music:PlayOptSound("lmqy")
    end, CCControlEventTouchUpInside)

    ui.setLabelString(item.doLab2,nil,19)
    item.doButton2:setTouchPriority(-101)
    item.doButton2:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)

        local configdata = gamedata.config.encounter[tostring(data.cid)] or {}
        local cb = function()
            UIRequest({type = 1311, iid = data.iid, method = 1, isfragment = data.isfragment, modulus = modulus, xgold = math.floor(data.xgold*modulus)})
        end
        --gameWindows:openWindow("confirm",{msg = configdata.prompt}, cb)
        local rich = {
            {fontID = 1,content = "是否消耗 ",},
            {fontID = 0,content = "obj_s_gold",},
            {fontID = 11,content = " "..math.floor(data.xgold*modulus),},
            {fontID = 1,content = " 进行招募？",},
        }
        gameWindows:openWindow("confirm",{rich = rich}, cb)

        gamedata.music:PlayOptSound("lmqy")
    end, CCControlEventTouchUpInside)

end

function encounter.setEncounterShop(self,item,data)
    --item.num2:setString(tostring(GameScene.roleinfo.gold or 0))

    if item.halfLab then
        item.halfLab:setVisible(false)
    end
    local modulus = 1
    if ui.CheckHuodongByParam(2) then
        modulus =  ui.GetHuodongModulus(2)
    -- if ui.CheckHuodongByParam(1) then
    --     modulus =  ui.GetHuodongModulus(1)
        if item.halfLab then
            item.halfLab:setVisible(true)
            ui.setLabelString(item.halfLab,gameConfig.strings:string_common("activityeveryday",7),24)
        end
    end

    item.hasgold:setString(GameScene.roleinfo.gold or 0)

    local equipcid = ""
    local num1 = "0"
    local configdata = gamedata.config.encounter[tostring(data.cid)] or {}
    local i_buf1 = string.find(configdata.param, ";",1)
    local i_buf2 = string.find(configdata.param, ",",i_buf1+1)
    if i_buf1 and i_buf2 then
        equipcid =  string.sub(configdata.param,i_buf1+1,i_buf2-1)
        num1 =  string.sub(configdata.param,i_buf2+1,string.len(configdata.param)-1)
        num1 = math.floor(tonumber(num1)*modulus)
        item.num1:setString(num1)
    end

    print("equipcid:"..equipcid)
    local equipConfig = gamedata.config.equip[tostring(equipcid)]
    --item.name:setString(equipConfig.name)
    if equipcid ~= "" then

        ui.setNewIconName(item,{cid = equipcid})
    end

    self:setTimer(data,true)
    if gameTimer.times["encounter_"..data.iid] and gameTimer.times["encounter_"..data.iid] > 0 then
        gameTimer:rigistTimeFunc("encounter_"..data.iid,function()
            if gameTimer.times["encounter_"..data.iid] > 0 then
                if item and item.time then
                    item.time:setString(ui.makeTimeText(gameTimer.times["encounter_"..data.iid],"hour"))
                end
            else
                if item and item.time then
                    item.time:setString("00:00:00")
                end
                UIRequest({type = 13111, iid = data.iid})
            end
        end)
    else

        item.time:setString("00:00:00")
        UIRequest({type = 13111, iid = data.iid})
    end


    item.in_button:setTouchPriority(-101)
    item.in_button:addHandleOfControlEvent(function()
        ui.setPopwindowByCid(equipcid)
    end, CCControlEventTouchUpInside)

    ui.setLabelString(item.doLab,nil,19)
    item.doButton:setTouchPriority(-101)
    item.doButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        UIRequest({type = 1311, iid = data.iid, method = 2})
        gamedata.music:PlayOptSound("lmqy")
    end, CCControlEventTouchUpInside)

    ui.setLabelString(item.doLab2,nil,19)
    item.doButton2:setTouchPriority(-101)
    item.doButton2:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)

        local configdata = gamedata.config.encounter[tostring(data.cid)] or {}
        local cb = function()
            UIRequest({type = 1311, iid = data.iid, method = 1, modulus = modulus, xgold = math.floor(0+num1)})
        end
        --gameWindows:openWindow("confirm",{msg = configdata.prompt}, cb)
        local rich = {
            {fontID = 1,content = "是否消耗 ",},
            {fontID = 0,content = "obj_s_gold",},
            {fontID = 11,content = " "..math.floor(0+num1),},
            {fontID = 1,content = " 进行购买？",},
        }
        gameWindows:openWindow("confirm",{rich = rich}, cb)

        gamedata.music:PlayOptSound("lmqy")
    end, CCControlEventTouchUpInside)

end


return encounter