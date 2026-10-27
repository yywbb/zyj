--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-9
-- Time: 下午6:52
-- To change this template use File | Settings | File Templates.
--

local treasureup = {

    resource = nil,

    titleCellSize = {x=196,y=200},
    treasureListTableView = nil,

    rootNode = nil,
    rootItems = nil,

    pageconfig = {"up","refine","upstar"},
    pagename = {"强 化","精 炼", "升 星"},

    selectpage = "up",

    sid = 1,
    data = {},
    treasures = {},
    xtreasures = {},
    treasuresdata = nil,
    selectData = {},
    uplevel1 = 1,
    delaybutton = false,

    chooseData = {},

    xcoin = 0,
    refine_xcoin = 0,
    refinePropNum = 0,
    refinePropcid = 0,
    refinePropx = 0,

    propid = {
        treasure = {26410,26411,26412,26414},
        horse = {26407,26408,26409,26413},
    },

    resolvequality = 3,

    curSkillLevel = {0,0,0,0,0,0},
}

function treasureup.shiftPage(self,type)

    self.chooseData = {}
    if type == "refine" then
        if not GameScene:checkopenlevelbyId(137) then
            if self.selectpage == "refine" then
                setSpriteFrameByName(self.rootItems["buttonsprite2"], gameConfig.images.pageButtonON)
                setSpriteFrameByName(self.rootItems["buttonsprite1"], gameConfig.images.pageButtonOFF)
            else
                setSpriteFrameByName(self.rootItems["buttonsprite1"], gameConfig.images.pageButtonON)
                setSpriteFrameByName(self.rootItems["buttonsprite2"], gameConfig.images.pageButtonOFF)
            end
            return
        end
    elseif type == "upstar" then
        if not GameScene:checkopenlevelbyId(666) then
            if self.selectpage == "upstar" then
                setSpriteFrameByName(self.rootItems["buttonsprite2"], gameConfig.images.pageButtonON)
                setSpriteFrameByName(self.rootItems["buttonsprite1"], gameConfig.images.pageButtonOFF)
            else
                setSpriteFrameByName(self.rootItems["buttonsprite1"], gameConfig.images.pageButtonON)
                setSpriteFrameByName(self.rootItems["buttonsprite2"], gameConfig.images.pageButtonOFF)
            end
            return
        end
    else

    end

    self.selectData = {}
    self.uplevel1 = 1

    self.selectpage = type
    if self.selectpage == "refine" then
        self:setPage_refine()
        if (guide.controller == nil or next(guide.controller) ==nil or not guide.controller.isOnGuide) then
            guide.controller:addComplete(137,function()
                UIRequest({type = 2882,opt=1,sysID=137})
            end)
        end
    elseif self.selectpage == "upstar" then
        self:setPage_upstar()
        if guide.controller then
            guide.controller:NewSystem(666)
        end
    else
        self:setPage_up()
    end

end

function treasureup.resetquicknode( self,status)

    if status == "open" then
        local index = 1
        for i=2,5 do
            self.quickItems["q_node"..i]:stopAllActions()
            if i==self.resolvequality then
                self.quickItems["q_node"..i]:setZOrder(1)
                self.quickItems["q_node"..i]:setPosition(60,0)
            else
                local moveto = CCMoveTo:create(0.5,ccp(60,index*68))
                local backout = CCEaseBackOut:create(moveto)
                self.quickItems["q_node"..i]:setZOrder(0)
                self.quickItems["q_node"..i]:runAction(backout)
                index = index +1
            end
        end
        self.quickstatus = true
    else
        for i=2,5 do
            self.quickItems["q_node"..i]:stopAllActions()
            if i==self.resolvequality then
                self.quickItems["q_node"..i]:setZOrder(1)
                self.quickItems["q_button"..i]:setTouchPriority(-107)
            else
                self.quickItems["q_node"..i]:setZOrder(0)
                self.quickItems["q_button"..i]:setTouchPriority(-106)
            end
            local moveto = CCMoveTo:create(0.3,ccp(60,0))
            local backout = CCEaseBackIn:create(moveto)
            self.quickItems["q_node"..i]:runAction(backout)
        end
        self.quickstatus = false
    end

end

function treasureup.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("equip_new/baowu_qianghua2", nil, true, "up")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)

    -- 自动添加品质获取
    local quality = CCUserDefault:sharedUserDefault():getIntegerForKey("treasureupQuality"..GameScene.roleinfo.id)
    if quality and quality > 3 then
        self.resolvequality = quality
    end
    print("self.resolvequality = ",self.resolvequality)

    --返回
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        GameScene:shiftLayer(GameScene.priorLayer,"up",{selectpage = "treasure", sid = self.sid or 1})
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(-103)
    --去挑战
    self.rootItems.gotorob:addHandleOfControlEvent(function()
        GameScene:shiftLayerById(25)
    end, CCControlEventTouchUpInside)
    self.rootItems.gotorob:setSwallowsTouch(true)
    self.rootItems.gotorob:setTouchPriority(-103)
    --说明
    self.rootItems.btnRule:addHandleOfControlEvent(function()
        ui.popCommonRule(666)
    end, CCControlEventTouchUpInside)
    self.rootItems.btnRule:setSwallowsTouch(true)
    self.rootItems.btnRule:setTouchPriority(-103)
    --技能升星
    self.rootItems.upstarSKillButton:addHandleOfControlEvent(function()
        local skilldata = {}
        for k,v in pairs(gamedata.config.treasure2_star) do
            if v.show > 0 then
                table.insert(skilldata,{id = v.id, activated = v[self.data.type.."_activated"]})
            end
        end
        table.sort(skilldata, function (a,b)
            return a.id < b.id
        end)
        gameWindows:openWindow("treasureUpStarSill", {quality = self.data.quality, curSkillLevel = self.curSkillLevel, skilldata = skilldata}, nil)
    end, CCControlEventTouchUpInside)
    self.rootItems.upstarSKillButton:setSwallowsTouch(true)
    self.rootItems.upstarSKillButton:setTouchPriority(-103)
    --
    if param and param.page then
        self.selectpage = param.page
    end

    if param and param.data then
        self.data = param.data
    end

    if param and param.sid then
        self.sid = param.sid
    end
    
    self.rootItems.attrscroll1 = tolua.cast(self.rootItems.attrscroll1, "CCScrollView")
    self.rootItems.attrscroll1:setTouchPriority(-103)

    self.rootItems.attrscroll2 = tolua.cast(self.rootItems.attrscroll2, "CCScrollView")
    self.rootItems.attrscroll2:setTouchPriority(-103)

    -- 一键添加品质选择
    self.quickNode,self.quickItems = CCBReaderLoad("qiankunlu/qiankunlu_fast", nil, true, "qiankunlu_fast")
    self.rootItems.quicknode:addChild(self.quickNode) 
    self.quickani = getAnimationManager(self.quickItems)

    self.quickItems["q_node"..self.resolvequality]:setZOrder(1)
    ui.setLabelString(self.quickItems["quickdesc"],"自动添加",14)

    for i=2,5 do
        self.quickItems["q_button"..i]:setSwallowsTouch(true)
        self.quickItems["q_button"..i]:setTouchPriority(self.resolvequality == i and -107 or -106)
        self.quickItems["q_button"..i]:addHandleOfControlEvent(function()
            print("q_button ----",i)
            if self.quickstatus == true then
                if i == 5 then
                    local function callback(num)
                        self.resolvequality = tonumber(num)
                        self.quickstatus = not self.quickstatus
                        self:resetquicknode(self.quickstatus and "open" or "close")
                        CCUserDefault:sharedUserDefault():setIntegerForKey("treasureupQuality"..GameScene.roleinfo.id, self.resolvequality)
                    end
                    gameWindows:openWindow("confirm",{msg = "橙色宝物为高级宝物，确定要自动添加强化吗？", oldQuality = self.resolvequality, newQuality = i}, callback)
                else
                    self.resolvequality = i;
                    self.quickstatus = not self.quickstatus
                    self:resetquicknode(self.quickstatus and "open" or "close")
                    CCUserDefault:sharedUserDefault():setIntegerForKey("treasureupQuality"..GameScene.roleinfo.id, self.resolvequality)
                end
            else
                self.quickstatus = not self.quickstatus
                self:resetquicknode(self.quickstatus and "open" or "close")
            end

        end, CCControlEventTouchUpInside)
    end


    self:ReloadData()
end

function treasureup.clear(self)
    self.sid = 1
    self.xtreasures = {}
    self.treasures = {}
    self.data = {}
    self.xcoin = 0
    self.refine_xcoin = 0
    self.refinePropNum = 0
    self.refinePropcid = 0
    self.refinePropx = 0
    self.selectData = {}
    self.uplevel1 = 1
    self.delaybutton = false
    self.selectpage = "up"
    self.treasureListTableView = nil
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.chooseData = {}
    self.quickstatus = false   
    self.spendPropsData = {}

    self.curSkillLevel = {0,0,0,0,0,0}
end


function treasureup.setTreasuresData(self,data)
    self.treasuresdata = {}
    -- printT(data,"data====")
    for k,v in pairs(data) do
        if k then
            if v.level2 == 0 and v.level3 == 0 then
                v.showorder = tonumber(k)
                table.insert(self.treasuresdata,v)
            end
        end
    end

    local sortByK = function(a,b) return a.showorder > b.showorder end
    table.sort(self.treasuresdata, sortByK)

end


----------------------------------------------------------------------------
-- 设置展示物品
function treasureup.setShowItems(self)
    -- print("setShowItems==")
    -- printT(self.chooseData)

    self.selectData = {}
    for i=1,5 do
        if self.chooseData and next(self.chooseData) and i <= #self.chooseData then
            -- print("setHasItems",i)
            self:setHasItems(self.chooseData[tonumber(i)],i+8)

            self.selectData[self.chooseData[tonumber(i)].iid] = self.chooseData[tonumber(i)]
        else
            -- print("setNothingItems",i)
            self:setNothingItems(i+8)
        end
    end
    if self.data then
        self:setexp_up()
    end
    
end

function treasureup.setHasItems(self,data,num)
    local key_Ex
    if num == nil or num == 1 then
        key_Ex = ""
    else
        key_Ex = "_"..(num-1)
    end
    self.rootItems["i_soulsprite"..key_Ex]:setVisible(true)
    if data.fragmentCid and data.fragmentCid > 0 then
        data.staffType = "general_fragment"
    end
    -- ui.setNewIcon(self.rootItems,data,num-1)
    ui.setNewIcon(self.rootItems,{cid = data.cid, num = "等级:"..data.level1},num-1)


    self.rootItems["i_button"..key_Ex]:addHandleOfControlEvent(function()
        -- ui.setPopwindowByCid(data.cid)
        local cb = function( temdata )
            -- printT(temdata)
            self.chooseData = temdata
            self:setShowItems()
        end
        gameWindows:openWindow("treasureupSelect",{  general = {}, 
                                                    equip = {}, 
                                                    treasure = self.treasures, 
                                                    generalfragment = {},
                                                    choose = self.chooseData,
                                                    infodata = self.data,
                                                    },cb)
    end, CCControlEventTouchUpInside)
    self.rootItems["i_button"..key_Ex]:setTouchPriority(-101)

end

function treasureup.setNothingItems(self,num)
    local key_Ex
    if num == nil or num == 1 then
        key_Ex = ""
    else
        key_Ex = "_"..(num-1)
    end

    self.rootItems["i_button"..key_Ex]:addHandleOfControlEvent(function()
        -- ui.setPopwindowByCid(data.cid)
        local cb = function( temdata )
            -- printT(temdata,"temdata")
            self.chooseData = temdata
            self:setShowItems()
        end
        gameWindows:openWindow("treasureupSelect",{ general = {}, 
                                                    equip = {}, 
                                                    treasure = self.treasures, 
                                                    generalfragment = {},
                                                    choose = self.chooseData,
                                                    infodata = self.data,
                                                    },cb)
    end, CCControlEventTouchUpInside)

    setSpriteFrameByName(self.rootItems["i_icon"..key_Ex], "obj_add2")
    setSpriteFrameByName(self.rootItems["i_k_quality"..key_Ex], "b_iconk1")
    setSpriteFrameByName(self.rootItems["i_quality"..key_Ex], "b_iconbg1")
    self.rootItems["i_soulsprite"..key_Ex]:setVisible(false)
    self.rootItems["i_soulnode"..key_Ex]:removeAllChildrenWithCleanup(true)
    self.rootItems["i_suitNode"..key_Ex]:removeAllChildrenWithCleanup(true)
    ui.setLabelString(self.rootItems["i_num"..key_Ex],"",13)
    
end

function treasureup.createTreasureList(self,alldata)
    -- print("createList")
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(196, 200)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = {},{}
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("icons/new_Icon_chong.ccbi", nil, true, "Icon")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            --
            local celldata = self.treasures[a1+1] or {}
            if celldata.iid then
                ui.setNewIcon(ccbDocumentControler,{cid = celldata.cid, num = "等级:"..celldata.level1})
            end
            ccbDocumentControler["i_select"]:setVisible(false)
            if self.selectData[celldata.iid] then
                ccbDocumentControler["i_select"]:setVisible(true)
                ccbDocumentControler["i_k_quality"]:setColor(ccc3(150,150,150))
                ccbDocumentControler["i_quality"]:setColor(ccc3(150,150,150))
                ccbDocumentControler["i_icon"]:setColor(ccc3(150,150,150))
            else
                ccbDocumentControler["i_k_quality"]:setColor(ccc3(255,255,255))
                ccbDocumentControler["i_quality"]:setColor(ccc3(255,255,255))
                ccbDocumentControler["i_icon"]:setColor(ccc3(255,255,255))
            end

            if ccbDocumentControler.i_button then
                ccbDocumentControler.i_button:setTouchPriority(-104)
                ccbDocumentControler.i_button:addHandleOfControlEvent(function()
                    if gameTouch.isScrollling then return end
                    if not self.selectData[celldata.iid] then
                        if self.uplevel1 < self.data.maxlv1 then
                            self.selectData[celldata.iid] = celldata
                            ccbDocumentControler["i_select"]:setVisible(true)
                            ccbDocumentControler["i_k_quality"]:setColor(ccc3(150,150,150))
                            ccbDocumentControler["i_quality"]:setColor(ccc3(150,150,150))
                            ccbDocumentControler["i_icon"]:setColor(ccc3(150,150,150))
                            self:setexp_up()
                        else
                            runGamePrompt({msg = "强化等级已达上限"})
                        end
                    else
                        self.selectData[celldata.iid] = nil
                        ccbDocumentControler["i_select"]:setVisible(false)
                        ccbDocumentControler["i_k_quality"]:setColor(ccc3(255,255,255))
                        ccbDocumentControler["i_quality"]:setColor(ccc3(255,255,255))
                        ccbDocumentControler["i_icon"]:setColor(ccc3(255,255,255))
                        self:setexp_up()
                        --
                        self.selectall = false
                    end
                end, CCControlEventTouchUpInside)
            end
            --

            cellCCB:setPosition(100,100)

            if first then
                a2:addChild(cellCCB)
            end


            r = a2
        elseif fn == "numberOfCells" then
            r =  table.getTableLength(self.treasures)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.treasureListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.up_list:getContentSize().width,
        viewheight = self.rootItems.up_list:getContentSize().height,
        dire = 0,
    })
    self.treasureListTableView:setTouchPriority(-102)
    self.rootItems.up_list:addChild(self.treasureListTableView)
end

----------------------------------------------------------------------------

function treasureup.ReloadData(self,data)
    if data then self.data = data end

    if GameScene:checkUpdate(10025,"offtreasures") then

    else
        self.treasures = {}
        self.xtreasures = {}

        for k,v in ipairs(self.treasuresdata) do
            table.insert(self.treasures,v)
            if self.data.cid and v.cid == self.data.cid and self.data.iid and v.iid ~= self.data.iid and v.level2 == 0 and v.level3 == 0 then
                table.insert(self.xtreasures,v)
            end
        end
        ----
        self:shiftPage(self.selectpage)
    end
end

-----------------------------------------------------------------------------

function treasureup.setPage_refine(self)
    self.rootItems.btnRule:setVisible(false)
    self.rootItems.upstarSKillButton:setVisible(false)
    self.rootItems.upstarnode:setVisible(false)
    self.rootItems.refinenode:setVisible(true)
    self.rootItems.upnode:setVisible(false)
    self.rootItems.up_list:setPositionX(9999)

    if self.data and next(self.data) then

        self.refine_xcoin = 0
        --
        ui.setLabelString(self.rootItems.refine_xcoin_lab, nil, 13)
        --
        local refineconfig = gamedata.config.treasure2_refine or {}
        local configdata =  gamedata.config.equip[tostring(self.data.cid)]
        self.data.maxlv2 = table.getTableLength(gamedata.config.treasure2_refine)
        if configdata.maxlevel2 and (self.data.maxlv2 > (configdata.maxlevel2+0)) then
            self.data.maxlv2 = configdata.maxlevel2+0
        end
        --
        ui.setNewIcon(self.rootItems,{cid = self.data.cid, num = ""})
        ui.setNewIcon(self.rootItems,{cid = self.data.cid, num = ""},1)

        ui.setLabelString(self.rootItems.refine_name,configdata.name..(self.data.level2>0 and "+"..self.data.level2 or ""), configdata.quality and 2*configdata.quality-1 or 1)

        ui.setLabelString(self.rootItems.refine_attr1, gameConfig.strings.attr_type[configdata.refine]..":", 14)
        ui.setLabelString(self.rootItems.refine_next_attr1, gameConfig.strings.attr_type[configdata.refine]..":", 14)

        local refinenum = 0
        for i = 1,self.data.level2 do
            if configdata["refine-grow"..i] then
                refinenum = refinenum + configdata["refine-grow"..i]
            end
        end
        ui.setLabelString(self.rootItems.refine_attrnum1, refinenum, 14)
        ui.setLabelString(self.rootItems.refine_xcoin, "0", 13)
        print("level2.maxlv2===",self.data.level2 , self.data.maxlv2)
        if self.data.level2 >= self.data.maxlv2 then
            ui.setLabelString(self.rootItems.refine_next_attrnum1, refinenum, 14)
            ui.setLabelString(self.rootItems.refine_next_name,configdata.name..(self.data.level2>0 and "+"..self.data.level2 or ""), configdata.quality and 2*configdata.quality-1 or 1)
            self.rootItems.refine_prop1:setVisible(false)
            self.rootItems.refine_prop2:setVisible(false)
            self.rootItems.refine_attrnode:setPositionX(0)
            self.rootItems.refine_next_attrnode:setVisible(false)
            ui.addGray("CCControlButton",self.rootItems.refine_refineButton)
            self.rootItems.maxDescText:setVisible(true)
            self.rootItems.coinNode:setVisible(false)
            self.rootItems.refine_prop_title:setVisible(false)
        else
            self.rootItems.maxDescText:setVisible(false)
            self.rootItems.refine_prop_title:setVisible(true)
            self.rootItems.refine_attrnode:setPositionX(-260)
            self.rootItems.refine_next_attrnode:setVisible(true)
            ui.setLabelString(self.rootItems.refine_next_attrnum1, refinenum+(configdata["refine-grow"..(self.data.level2+1)] and configdata["refine-grow"..(self.data.level2+1)] or 0), 14)
            ui.setLabelString(self.rootItems.refine_next_name,configdata.name..("+"..self.data.level2+1), configdata.quality and 2*configdata.quality-1 or 1)
            self.rootItems.refine_prop1:setVisible(true)
            self.rootItems.refine_prop2:setVisible(true)
            ui.setNewIcon(self.rootItems,{ cid = self.data.cid, num = table.getTableLength(self.xtreasures).."/"..(refineconfig[tostring(self.data.level2+1)]["oneself"..self.data.quality] or 0) },2)
            ui.setLabelString(self.rootItems["i_num_2"],nil,table.getTableLength(self.xtreasures)+0 < (refineconfig[tostring(self.data.level2+1)]["oneself"..self.data.quality] or 0)+0 and 24 or 22)
            --
            self.rootItems["i_button_2"]:addHandleOfControlEvent(function()
                ui.setPopwindowByCid(self.data.cid)
            end, CCControlEventTouchUpInside)
            self.rootItems["i_button_2"]:setTouchPriority(-103)

            local spendselfNum = refineconfig[tostring(self.data.level2+1)]["oneself"..self.data.quality]
            -- print("spendselfNum===",spendselfNum)
            if tonumber(spendselfNum) == 0 then
                self.rootItems.refine_prop1:setVisible(false)
                self.rootItems.refine_prop2:setPositionX(0)
            else
                self.rootItems.refine_prop1:setVisible(true)
                self.rootItems.refine_prop2:setPositionX(110)
            end
            --
            local xprops = ui.getIDandNUMs(refineconfig[tostring(self.data.level2+1)]["num"..self.data.quality]) or {}
            for k,v in pairs(xprops) do
               if v.cid == 1000 then
                   self.refine_xcoin = v.num or 0
                   ui.setLabelString(self.rootItems.refine_xcoin, v.num, 13)
               else
                   self.refinePropcid = v.cid or 0
                   self.refinePropx = v.num or 0
                   UIRequest({type = 12001, order = 11005, cids = {v.cid}})
                   ui.setNewIcon(self.rootItems,{ cid = v.cid, num = v.num } ,3)
                   --
                   self.rootItems["i_button_3"]:addHandleOfControlEvent(function()
                       ui.setPopwindowByCid(v.cid)
                   end, CCControlEventTouchUpInside)
                   self.rootItems["i_button_3"]:setTouchPriority(-103)
                   --
               end
            end
        end

        --
        ui.setLabelString(self.rootItems.refine_refineLab,nil,19)
        self.rootItems.refine_refineButton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)

            if self.data.level2 >= self.data.maxlv2 then
                runGamePrompt({msg = "精炼等级已达上限"})
            elseif self.refine_xcoin > GameScene.roleinfo.coin then
                --runGamePrompt({msg = "银币不足"})
                shortCoin()
            elseif self.refinePropNum < self.refinePropx then
                runGamePrompt({msg = "道具不足"})
            elseif table.getTableLength(self.xtreasures) < (refineconfig[tostring(self.data.level2+1)]["oneself"..self.data.quality] or 0) then
                runGamePrompt({msg = "宝物不足"})
            else
                local ids = {}
                for i = 1, (refineconfig[tostring(self.data.level2+1)]["oneself"..self.data.quality] or 0) do
                    if self.xtreasures[i] then
                        table.insert(ids,self.xtreasures[i].iid)
                    end
                end
                local xprops = ui.getIDandNUMs(refineconfig[tostring(self.data.level2+1)]["num"..self.data.quality]) or {}
                UIRequest({type= 1119, iid = self.data.iid, xprops = xprops, ids = ids})
                --
                self.rootItems.refine_effect:removeAllChildrenWithCleanup(true)
                local qianghuaNode,qianghuaItems = CCBReaderLoad("UIEffect/jinglian/jinglian", nil, true, "jinglian")
                qianghuaNode:setPosition(0,0)
                self.rootItems.refine_effect:addChild(qianghuaNode)
                self.rootItems.refine_effect:setScale(1)
                local animationManager = getAnimationManager(qianghuaItems)
                animationManager:setAnimationCompletedCallback(function()
                    self.rootItems.refine_effect:removeAllChildrenWithCleanup(true)
                end)
                animationManager:runAnimationsForSequenceNamed("jinglian")
                gamedata.music:PlayOptSound("xlshjhtp")
                --
            end

        end, CCControlEventTouchUpInside)
        self.rootItems.refine_refineButton:setSwallowsTouch(true)
        self.rootItems.refine_refineButton:setTouchPriority(-103)
        --
        --


        local num = 0
        for i = 1,6 do
           if configdata["refine-level"..i] and configdata["refine-level"..i] ~= "" then
               local str = configdata["refine-attr"..i]
               local ii = string.find(str, ";") or string.find(str, "；")
               if ii then
                    num = num + 1
                   local ss = gameConfig.strings.attr_type[string.sub(str, 1, ii-1)].." +"..( tonumber(string.sub(str, ii+1))<=1 and ((tonumber(string.sub(str, ii+1))*100).."%") or tonumber(string.sub(str, ii+1)))
                   if self.data.level2 < configdata["refine-level"..i] then
                       self.rootItems["refine_refine"..i]:setString(ss.."  (宝物+"..configdata["refine-level"..i].."解锁)")
                       ui.setLabelString(self.rootItems["refine_refine"..i],nil,29)
                   else
                       self.rootItems["refine_refine"..i]:setString(ss)
                       ui.setLabelString(self.rootItems["refine_refine"..i],nil,14)
                   end
                   if self.data.level2+1 < configdata["refine-level"..i] then
                       self.rootItems["refine_next_refine"..i]:setString(ss.."  (宝物+"..configdata["refine-level"..i].."解锁)")
                       ui.setLabelString(self.rootItems["refine_next_refine"..i],nil,29)
                   else
                       self.rootItems["refine_next_refine"..i]:setString(ss)
                       ui.setLabelString(self.rootItems["refine_next_refine"..i],nil,14)
                   end

               else
                   self.rootItems["refine_refine"..i]:setString("")
                   self.rootItems["refine_next_refine"..i]:setString("")
                   ui.setLabelString(self.rootItems["refine_refine"..i],nil,14)
                   ui.setLabelString(self.rootItems["refine_next_refine"..i],nil,14)
               end
           else
               self.rootItems["refine_refine"..i]:setString("")
               self.rootItems["refine_next_refine"..i]:setString("")
               ui.setLabelString(self.rootItems["refine_refine"..i],nil,14)
               ui.setLabelString(self.rootItems["refine_next_refine"..i],nil,14)
           end
        end

        self.rootItems["refine_continer1"]:setContentSize(CCSizeMake(500,50 * num))
        self.rootItems["refine_continer2"]:setContentSize(CCSizeMake(500,50 * num))
        
        self.rootItems["refine_continer1"]:setPositionY(210 - 50 * num)
        self.rootItems["refine_continer2"]:setPositionY(210 - 50 * num)

        self.rootItems["refine_label1"]:setPositionY(50 * num - 300)
        self.rootItems["refine_label2"]:setPositionY(50 * num - 300)
    else


        for i = 1,6 do
            ui.setLabelString(self.rootItems["refine_refine"..i],nil,14)
            ui.setLabelString(self.rootItems["refine_next_refine"..i],nil,14)
        end

        ui.setLabelString(self.rootItems.refine_refineLab,nil,19)
        self.rootItems.refine_refineButton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            runGamePrompt({msg ="请选择精炼的宝物"})
        end, CCControlEventTouchUpInside)
        self.rootItems.refine_refineButton:setSwallowsTouch(true)
        self.rootItems.refine_refineButton:setTouchPriority(-103)

        self:setRawItem(0)

    end
   
end

-----------------------------------------------------------------

function treasureup.setPage_upstar(self)
    self.rootItems.btnRule:setVisible(true)
    self.rootItems.upstarSKillButton:setVisible(true)
    self.rootItems.upstarnode:setVisible(true)
    self.rootItems.refinenode:setVisible(false)
    self.rootItems.upnode:setVisible(false)
    self.rootItems.up_list:setPositionX(9999)

    printT(self.data,"jkp-data")
    local treasureConfig = gamedata.config.equip[tostring(self.data.cid)] --宝物
    local upstarConfig = gamedata.config.treasure2_star or {} --升星数据
    local maxlv3 = tonumber(treasureConfig.up_star)
    --设置星星
    local starnum = math.mod(self.data.level3, 5) 
    if starnum == 0 then
        starnum = 5
    end
    local numtemp = math.floor(self.data.level3/5)
    local img_xing = "shengxing_"..numtemp
    for i=1,5 do
        if i <= starnum and self.data.level3 > 0 then
            setSpriteFrameByName(self.rootItems["star"..i], upstarConfig[tostring(self.data.level3)]["icon"] or "alpha")
        else
            setSpriteFrameByName(self.rootItems["star"..i], img_xing or "alpha")
        end
    end

    ui.setNewIcon(self.rootItems, {cid = self.data.cid, num = ""}, 4)
    ui.setLabelString(self.rootItems.upstar_name, treasureConfig.name..(self.data.level2>0 and "+"..self.data.level2 or ""), treasureConfig.quality and 2*treasureConfig.quality-1 or 1)

    if treasureConfig.quality < 5 then
        ui.setLabelString(self.rootItems.upstarLab, nil, 19)
        self.rootItems.upstarButton:addHandleOfControlEvent(function()
            runGamePrompt({msg = "橙色品质以下的宝物无法升星"}) 
        end, CCControlEventTouchUpInside)
        self.rootItems.upstarButton:setSwallowsTouch(true)
        self.rootItems.upstarButton:setTouchPriority(-103)
        ui.addGray("CCLabelTTF",self.rootItems.upstarLab)
        ui.addGray("CCControlButton",self.rootItems.upstarButton)

        self.rootItems.coinNode:setVisible(false)
        self.rootItems.upstar_prop1:setVisible(false)
        self.rootItems.upstar_prop2:setVisible(false)
        self.rootItems.needlevelLab:setVisible(false)
        self.rootItems.needlevel:setVisible(false)
        self.rootItems.maxuplevelLab:setVisible(false)
        self.rootItems.maxuplevel:setVisible(false)
        self.rootItems.upstar_info_node:setVisible(false)
        self.rootItems.notupstarLab:setVisible(true)
        ui.setLabelString(self.rootItems.notupstarLab, nil, 19, 58)
        return
    end

    --属性显示
    local skilldata = {}
    for k,v in pairs(upstarConfig) do
        if v.show > 0 then
            table.insert(skilldata,{id = v.id, activated = v[self.data.type.."_activated"]})
        end
    end
    table.sort(skilldata, function (a,b)
        return a.id < b.id
    end)

    local newInfo = upstarConfig[tostring(self.data.level3)] or {}
    local nextInfo = upstarConfig[tostring(self.data.level3+1)] or {}
    if newInfo and next(newInfo) then
        self.rootItems.upattnode:setVisible(true)
        self:setNewStarInfo(self.rootItems, newInfo, skilldata)
    else
        self.rootItems.upattnode:setVisible(false)
    end

    if nextInfo and next(nextInfo) then
        self.rootItems.upnextattnode:setVisible(true)
        self:setNextStarInfo(self.rootItems, nextInfo, skilldata)
        if treasureConfig.quality == 5 and nextInfo.id > 15 then
            self.rootItems.upnextattnode:setVisible(false)
        elseif treasureConfig.quality == 6 and nextInfo.id > 25 then
            self.rootItems.upnextattnode:setVisible(false)
        end
    else
        self.rootItems.upnextattnode:setVisible(false)
    end

    if treasureConfig.quality == 5 then
        self.rootItems.skillnode3:setVisible(false)
        self.rootItems.skillnode4:setVisible(false)
        self.rootItems.skillnode5:setVisible(false)
        self.rootItems.skillnode6:setVisible(false)

        self.rootItems.nextskillnode3:setVisible(false)
        self.rootItems.nextskillnode4:setVisible(false)
        self.rootItems.nextskillnode5:setVisible(false)
        self.rootItems.nextskillnode6:setVisible(false)
    elseif treasureConfig.quality == 6 then
        self.rootItems.skillnode3:setVisible(true)
        self.rootItems.skillnode4:setVisible(true)
        self.rootItems.skillnode5:setVisible(false)
        self.rootItems.skillnode6:setVisible(false)

        self.rootItems.nextskillnode3:setVisible(true)
        self.rootItems.nextskillnode4:setVisible(true)
        self.rootItems.nextskillnode5:setVisible(false)
        self.rootItems.nextskillnode6:setVisible(false)
    end

    -- 获取消耗物品的数据
    local lv3Num = self.data.level3+1
    if lv3Num > maxlv3 then
        lv3Num = maxlv3
    end
    if self.data.level3 >= lv3Num then
        self.rootItems.coinNode:setVisible(false)
        self.rootItems.upstar_prop1:setVisible(false)
        self.rootItems.upstar_prop2:setVisible(false)
        self.rootItems.upstar_maxDescText:setVisible(true)
        self.rootItems.needlevelLab:setVisible(false)
        self.rootItems.needlevel:setVisible(false)
        self.rootItems.buttonNode:setVisible(false)
        --星级上线
        ui.setLabelString(self.rootItems.maxuplevelLab,nil,14,36)
        ui.setLabelString(self.rootItems.maxuplevel,self.data.level3.."/"..maxlv3,22,36)
        return
    else
        self.rootItems.coinNode:setVisible(true)
        self.rootItems.upstar_prop1:setVisible(true)
        self.rootItems.upstar_prop2:setVisible(true)
        self.rootItems.upstar_maxDescText:setVisible(false)
        self.rootItems.needlevelLab:setVisible(true)
        self.rootItems.needlevel:setVisible(true)
        self.rootItems.buttonNode:setVisible(true)
    end
    local needLevel = 0
    if upstarConfig[tostring(self.data.level3 + 1)] and upstarConfig[tostring(self.data.level3 + 1)].num and upstarConfig[tostring(self.data.level3 + 1)].num > 0 then
        needLevel = upstarConfig[tostring(self.data.level3 + 1)].num
    end
    if needLevel > 0 then
        self.rootItems.needlevelLab:setVisible(true)
        self.rootItems.needlevel:setVisible(true)
        ui.setLabelString(self.rootItems.needlevelLab,nil,14,36)
        if self.data.level2 < needLevel then
            ui.setLabelString(self.rootItems.needlevel,needLevel.."级",24,36)
        else
            ui.setLabelString(self.rootItems.needlevel,needLevel.."级",22,36)
        end
    else
        self.rootItems.needlevelLab:setVisible(false)
        self.rootItems.needlevel:setVisible(false)
    end

    --星级上线
    ui.setLabelString(self.rootItems.maxuplevelLab,nil,14,36)
    ui.setLabelString(self.rootItems.maxuplevel,self.data.level3.."/"..maxlv3,22,36)

    local spenddata = upstarConfig[tostring(lv3Num)]["cost_"..self.data.quality] or {}
    local spendtemp = {}
    for k,v in pairs(gamedata.getIDandNUMs(spenddata)) do
        table.insert(spendtemp,v.cid)
    end
    UIRequest({type = 12001, order = 34401, cids = spendtemp})
    
    -- ui.setNewIcon(self.rootItems, {cid = self.data.cid, num = ""}, 5)
    -- ui.setNewIcon(self.rootItems, {cid = self.data.cid, num = ""}, 6)

    ui.setLabelString(self.rootItems.upstar_xcoin_lab, nil, 13)
    ui.setLabelString(self.rootItems.upstarLab, nil, 19)
    --升星
    self.rootItems.upstarButton:addHandleOfControlEvent(function()
        if self.data.level3 >= maxlv3 then
            local name = "典籍"
                if self.data.type == "horse" then
                    name = "坐骑"
                end
            if self.data.quality >= 5 then
                runGamePrompt({msg = name.."升星已达到最高等级"})
            else
                runGamePrompt({msg = "橙色以上"..name.."才可升星"}) 
            end
            return
        end

        local upstarConfig = gamedata.config.treasure2_star or {}
        local needLevel = 0
        if upstarConfig[tostring(self.data.level3 + 1)] and upstarConfig[tostring(self.data.level3 + 1)].num and upstarConfig[tostring(self.data.level3 + 1)].num > 0 then
            needLevel = upstarConfig[tostring(self.data.level3 + 1)].num
        end

        if self.data.level2 < needLevel then
            runGamePrompt({msg = "精炼等级不足"})
            return
        end

        local spenddata = upstarConfig[tostring(self.data.level3+1)]["cost_"..self.data.quality] or {}
        local spengtemp = {}
        spengtemp = gamedata.getIDandNUMs(spenddata)
        for i,v in ipairs(spengtemp) do
            if v.cid == 1000 then
                if (self.spendPropsData[tostring(v.cid)] or 0) < v.num then
                    shortCoin()
                    return
                end
            elseif ((self.spendPropsData[tostring(v.cid)] or 0) < v.num) then
                runGamePrompt({msg = gameConfig.strings:string_common("equipUp",5)})
                return
            end
        end
        UIRequest({type = 1127, iid = self.data["iid"], props = spengtemp})
    end, CCControlEventTouchUpInside)
    self.rootItems.upstarButton:setSwallowsTouch(true)
    self.rootItems.upstarButton:setTouchPriority(-103)

end

function treasureup.setNewStarInfo(self, items, config, skilldata)
    ui.setLabelString(items.fixed1, nil, 18)
    ui.setLabelString(items.lab1, nil, 14)
    ui.setLabelString(items.lab2, nil, 14)
    ui.setLabelString(items.lab3, nil, 14)

    ui.setLabelString(items.atk, config.atk, 14)
    ui.setLabelString(items.def, config.def, 14)
    ui.setLabelString(items.hp, config.hp, 14)

    for i=1,#skilldata do
        local breakskill = gamedata.config.breakskill[tostring(skilldata[i].activated)]
        items["skillName"..i]:setString(breakskill.name)
        ui.setLabelString(items["skilllevelMax"..i],nil,24,34)
        
        local level = config.id - skilldata[i].id + 1
        if level > 5 then
            level = 5
        end
        if level < 0 then
            level = 0
        end
        --未开启
        if level == 0 then
            ui.setLabelString(items["skilllevel"..i], "星级+"..skilldata[i].id.."开启", 14)
            items["skillName"..i]:setColor(ui.grayColor)
        else
            ui.setLabelString(items["skilllevel"..i],"等级."..level, 1008, 34)
            ui.setLabelString(items["skillName"..i], nil, 14)
        end
        items["skilllevelMax"..i]:setVisible(level == 5)

        self.curSkillLevel[i] = level
    end
end

function treasureup.setNextStarInfo(self, items, config, skilldata)
    ui.setLabelString(items.fixed2, nil, 18)
    ui.setLabelString(items.lab4, nil, 14)
    ui.setLabelString(items.lab5, nil, 14)
    ui.setLabelString(items.lab6, nil, 14)

    ui.setLabelString(items.next_atk, config.atk, 23)
    ui.setLabelString(items.next_def, config.def, 23)
    ui.setLabelString(items.next_hp, config.hp, 23)

    local nextSkillLevel = {0,0,0,0,0,0}
    for i=1,#skilldata do
        local breakskill = gamedata.config.breakskill[tostring(skilldata[i].activated)]
        items["next_skillName"..i]:setString(breakskill.name)
        ui.setLabelString(items["next_skilllevelMax"..i],nil,24,34)
        
        local level = config.id - skilldata[i].id + 1
        if level > 5 then
            level = 5
        end
        if level < 0 then
            level = 0
        end
        nextSkillLevel[i] = level
        --未开启
        if nextSkillLevel[i] == 0 then
            ui.setLabelString(items["next_skilllevel"..i], "星级+"..skilldata[i].id.."开启", 14)
            items["next_skillName"..i]:setColor(ui.grayColor)
        else
            items["next_skilllevel"..i]:setString("等级."..nextSkillLevel[i])
            if nextSkillLevel[i] > self.curSkillLevel[i] then
                ui.setLabelString(items["next_skillName"..i],nil,14)
                ui.setLabelString(items["next_skilllevel"..i],nil,23)
            else
                ui.setLabelString(items["next_skillName"..i],nil,14)
                ui.setLabelString(items["next_skilllevel"..i],nil,1008,34)
            end

        end

        items["next_skilllevelMax"..i]:setVisible(level == 5)
    end

end

-- 升星消耗物品数据
function treasureup.setSpendPropsData(self,data)
    printT(data,"spendPropsData")
    self.spendPropsData = {}
    self.spendPropsData = data

    local upstarConfig = gamedata.config.treasure2_star or {}
    local spenddata = ""
    if upstarConfig[tostring(self.data.level3 + 1)] then
        spenddata = upstarConfig[tostring(self.data.level3 + 1)]["cost_"..self.data.quality]
    end
    local spengtemp = {}
    if spenddata ~= "" then
        spengtemp = gamedata.getIDandNUMs(spenddata)
    end
    local spendcoin = 0
    for i,v in ipairs(spengtemp) do
        if v.cid == 1000 then
            spendcoin = v.num
        end
    end
    if (self.spendPropsData[tostring(1000)] or 0) < spendcoin then
        ui.setLabelString(self.rootItems["upstar_xcoin"], spendcoin, 24)
    else
        ui.setLabelString(self.rootItems["upstar_xcoin"], spendcoin, 14)
    end

    self:setNeedItems()
end

-- 设置升星消耗物品
function treasureup.setNeedItems(self)

    local upstarConfig = gamedata.config.treasure2_star or {}
    local spendtemp = {}

    local spenddata = ""
    if upstarConfig[tostring(self.data.level3 + 1)] then
        spenddata = upstarConfig[tostring(self.data.level3 + 1)]["cost_"..self.data.quality]
    end
    local getData = {}
    if spenddata ~= "" then
        getData = gamedata.getIDandNUMs(spenddata)
    end
    for k,v in pairs(getData) do
        if v.cid ~= 1000 then
            table.insert(spendtemp,v)
        end
    end
    for i=1,2 do
        if spendtemp and next(spendtemp) and i <= #spendtemp then
            self:setHasItems_upStar(spendtemp[tonumber(i)], i+5, self.spendPropsData)
            self.rootItems["upstar_prop"..i]:setVisible(true)
        else
            self.rootItems["upstar_prop"..i]:setVisible(false)
        end
    end
end

-- 升星消耗物品显示
function treasureup.setHasItems_upStar(self,data,num,spendPropsData)
    printT(data,"treasureup-data")
    local key_Ex
    if num == nil or num == 1 then
        key_Ex = ""
    else
        key_Ex = "_"..(num-1)
    end

    self.rootItems["i_button"..key_Ex]:addHandleOfControlEvent(function()
        ui.setPopwindowByCid(data.cid)
    end, CCControlEventTouchUpInside)
    
    ui.setNewIcon(self.rootItems,{cid=data.cid, num=((spendPropsData[tostring(data.cid)] or 0).."/"..data.num)}, num-1)
    if (spendPropsData[tostring(data.cid)] or 0) >= data.num then
        ui.setLabelString(self.rootItems["i_num"..key_Ex],nil,13)
    else
        ui.setLabelString(self.rootItems["i_num"..key_Ex],nil,24)
    end
end

-----------------------------------------------------------------

function treasureup.setPage_up(self)
    self.rootItems.btnRule:setVisible(false)
    self.rootItems.upstarSKillButton:setVisible(false)
    self.rootItems.upstarnode:setVisible(false)
    self.rootItems.refinenode:setVisible(false)
    self.rootItems.upnode:setVisible(true)
    self.rootItems.up_list:setPositionX(-482)
    
    if self.data and next(self.data) then

        self.rootItems.upbomNode:setVisible(true)

        local configdata =  gamedata.config.equip[tostring(self.data.cid)]
        self.data.maxlv1 = table.getTableLength(gamedata.config.treasure2_strengthen)
        if configdata.maxlevel and (self.data.maxlv1 > (configdata.maxlevel+0)) then
            self.data.maxlv1 = configdata.maxlevel+0
        end
        if self.data.maxlv1 > GameScene.roleinfo.level then
            self.data.maxlv1 = GameScene.roleinfo.level
        end
        --
        ui.setNewIcon(self.rootItems,{cid = self.data.cid},7)
        self.rootItems["i_num_4"]:setVisible(true)
        ui.setLabelString(self.rootItems["i_num_4"], "等级." .. self.data.level1, 13)
        ui.setLabelString(self.rootItems.up_name,configdata.name..(self.data.level2>0 and "+"..self.data.level2 or ""), configdata.quality and 2*configdata.quality-1 or 1)

        local type1,num1,type2,num2 = ui.setEquipPromote(nil,nil,self.data)

        self.rootItems.up_attr1:setString(type1)
        self.rootItems.up_attrnum1:setString(num1)
        self.rootItems.up_attr2:setString(type2)
        self.rootItems.up_attrnum2:setString(num2)

        self.rootItems.up_attrnum_up1:setString("")
        self.rootItems.up_attrnum_up2:setString("")

        self.rootItems.up_level:setString(self.data.level1)
        self.rootItems.up_levelup:setString("")
        self.rootItems.up_exp:setString(self.data.exp)
        --
        ui.setLabelString(self.rootItems.up_attrnum1,nil,14)
        ui.setLabelString(self.rootItems.up_attrnum2,nil,14)
        ui.setLabelString(self.rootItems.up_attrnum_up1,nil,23)
        ui.setLabelString(self.rootItems.up_attrnum_up2,nil,23)
        ui.setLabelString(self.rootItems.up_levelup,nil,22)
        ui.setLabelString(self.rootItems.up_level,nil,21)
        ui.setLabelString(self.rootItems.up_exp,nil,13)
        --
        ui.setLabelString(self.rootItems.up_lab1,nil,13)
        ui.setLabelString(self.rootItems.up_lab2,nil,13)
        ui.setLabelString(self.rootItems.up_levelLab,nil,21)

        self:shift_up_consume_page(self.consume_page or "prop")

    else
        self.rootItems.upbomNode:setVisible(false)
        --ui.setNewIcon(self.rootItems,{cid = self.data.cid},7)
        ui.setLabelString(self.rootItems.up_attrnum1,nil,14)
        ui.setLabelString(self.rootItems.up_attrnum2,nil,14)
        ui.setLabelString(self.rootItems.up_attrnum_up1,nil,23)
        ui.setLabelString(self.rootItems.up_attrnum_up2,nil,23)
        self:setRawItem(4)
    end
end

function treasureup.shift_up_consume_page( self,consumepage )
    self.consume_page = consumepage

    if self.consume_page == "treasure" then
        self:setPage_up_consum_treasure()
    elseif self.consume_page == "prop" then
        self.selectData = {}
        self:setexp_up()
        self:setPage_up_consum_prop()
    end
 
    self.rootItems.treasure_consume_node:setPositionX(self.consume_page == "treasure" and 0 or 99999)
    self.rootItems.prop_consume_node:setPositionX(self.consume_page == "prop" and 0 or 99999)

    setSpriteFrameByName(self.rootItems.consumpagelab,self.consume_page == "treasure" and "jingyanbaowubt" or "putongbaowubt")
    --ui.setLabelString(self.rootItems.consumpagelab,self.consume_page == "treasure" and "使用经验宝物" or "使用普通宝物",13)
    self.rootItems.consumpagebtn:addHandleOfControlEvent(function()
        self:shift_up_consume_page(self.consume_page == "treasure" and "prop" or "treasure")

    end, CCControlEventTouchUpInside)
    self.rootItems.consumpagebtn:setSwallowsTouch(true)
    self.rootItems.consumpagebtn:setTouchPriority(-103)

end

function treasureup.setPage_up_consum_prop( self )

    self.rootItems.quicknode:setVisible(false)

    local propids = self.propid[self.data.type]

    self.expup =
    {
        upnum1 = 0,
        upnum2 = 0,
        upnum3 = 0,
        upnum4 = 0,

        num1 = 0,
        num2 = 0,
        num3 = 0,
        num4 = 0,

        l_num1 = 0,
        l_num2 = 0,
        l_num3 = 0,
        l_num4 = 0,

        maxlv = self.data.maxlv1,
        l_exp = self.data.exp,
        l_level = self.data.level1,
        quality = self.data.quality,
        up_exp = 0,
        up_exp1 = 0,
    }


    -- self.expup.quality = generalConfig.quality or 3

    -- self.expup.l_exp = self.data.general.exp or 0
    -- self.expup.l_level = self.data.general.level1 or 1
    -- self.expup.maxlv = gamedata.config.global_kv and tonumber(gamedata.config.global_kv.general_level.value)*GameScene.roleinfo.level or 1
    -- if self.expup.maxlv > table.getTableLength(gamedata.config.general_exp) then
    --     self.expup.maxlv = table.getTableLength(gamedata.config.general_exp)
    -- end
    -- --
    -- if self.data.general.level1 >= self.expup.maxlv then
    --     self.rootItems.upnextattnode:setVisible(false)
    -- else
    --     self.rootItems.upnextattnode:setVisible(true)
    -- end
    --
    ------

    local equipconfig = gamedata.config.equip
    local expconfig = gamedata.config.treasure2_strengthen

    for k,v in ipairs(propids) do
        ui.setNewIconName(self.rootItems,{cid = v},k-1)
        self.expup["upnum"..k] = gamedata.config.equip[tostring(v)].exp 
        ui.setLabelString(self.rootItems["up_explab"..k],"EXP:"..self.expup["upnum"..k],13)
    end
    -- ui.setNewIconName(self.rootItems,{cid = 20196},0)
    -- ui.setNewIconName(self.rootItems,{cid = 20197},1)
    -- ui.setNewIconName(self.rootItems,{cid = 20198},2)
    -- ui.setNewIconName(self.rootItems,{cid = 20199},3)

    -- self.expup.upnum1 = gamedata.config.props["20196"].param1 or 0
    -- self.expup.upnum2 = gamedata.config.props["20197"].param1 or 0
    -- self.expup.upnum3 = gamedata.config.props["20198"].param1 or 0
    -- self.expup.upnum4 = gamedata.config.props["20199"].param1 or 0

    -- self.rootItems.up_explab1:setString("EXP:"..self.expup.upnum1)
    -- self.rootItems.up_explab2:setString("EXP:"..self.expup.upnum2)
    -- self.rootItems.up_explab3:setString("EXP:"..self.expup.upnum3)
    -- self.rootItems.up_explab4:setString("EXP:"..self.expup.upnum4)


    UIRequest({type = 12001, order = 12101, cids = propids})

    ----
    local beginFunc = function(index,quick)
        if quick then
            if self.expup["num"..index] == self.expup["l_num"..index] then return end
        else
            if self.expup["l_num"..index] < 1 then return end
        end

        self["effect_begin"..index] = false
        self["effect_end"..index] = false
        --
        self.rootItems["selectEffectNode"..index]:stopAllActions()
        self.rootItems["selectEffectNode"..index]:removeAllChildrenWithCleanup(true)
        local qianghuaNode,qianghuaItems = CCBReaderLoad("UIEffect/cailiaoxuanzhong/cailiaoxuanzhong", nil, true, "cailiaoxuanzhong")
        qianghuaNode:setPosition(0,0)
        self.rootItems["selectEffectNode"..index]:addChild(qianghuaNode)
        self.rootItems["selectEffectNode"..index]:setScale(1)
        local animationManager = getAnimationManager(qianghuaItems)
        animationManager:runAnimationsForSequenceNamed("zhenrongxuanzhong")
        --
        self.rootItems["selectEffectNode"..index]:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1),CCCallFunc:create(function()
            self["effect_begin"..index] = true
            if self["effect_end"..index] then
                self.rootItems["selectEffectNode"..index]:removeAllChildrenWithCleanup(true)
            end
        end)))
    end

    local endFunc = function(index)
        self["effect_end"..index] = true
        if self["effect_begin"..index] then
            self.rootItems["selectEffectNode"..index]:removeAllChildrenWithCleanup(true)
        end
    end
    --
    local Func1 = function(donum)
        local xdonum = donum or 1

        if (self.expup.l_level+1 > self.expup.maxlv) then 
            --runGamePrompt({msg = "经验值已满"})
            runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",17)})
            return
        end

        if self.expup.l_num1 < xdonum then
            xdonum = self.expup.l_num1
        end    

        local l_exp = self.expup.l_exp
        local l_level = self.expup.l_level
        for i=1,xdonum do
            l_exp = l_exp+self.expup.upnum1
            if l_level+1 <= self.expup.maxlv and l_exp >= expconfig[tostring(l_level+1)]["quality"..self.expup.quality] then
                l_level = l_level + 1
                l_exp = l_exp - expconfig[tostring(l_level)]["quality"..self.expup.quality]

                if l_level+1 > self.expup.maxlv then
                    xdonum = i
                    break
                end
            end
        end

        if self.expup.l_num1 > 0 then
            self.expup.l_num1 = self.expup.l_num1-xdonum
            self.expup.l_exp = self.expup.l_exp+self.expup.upnum1*xdonum
            --runGamePrompt({msg = "经验+"..self.expup.upnum1})
            runGamePrompt({msg = gameConfig.strings:expNum(self.expup.upnum1*xdonum)})
        else
            --runGamePrompt({msg = "材料已消耗完"})
            runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",18)})
            endFunc(1)
        end

        while self.expup.l_level+1 <= self.expup.maxlv and self.expup.l_exp >= expconfig[tostring(self.expup.l_level+1)]["quality"..self.expup.quality] do
            if self.expup.l_level+1 > self.expup.maxlv then break end
            self.expup.l_level = self.expup.l_level + 1
            self.expup.l_exp = self.expup.l_exp - expconfig[tostring(self.expup.l_level)]["quality"..self.expup.quality]
        end

        self:setData_up(self.expup)
    end

    local Func2 = function(donum)
        local xdonum = donum or 1

        if (self.expup.l_level+1 > self.expup.maxlv) then 
            --runGamePrompt({msg = "经验值已满"})
            runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",17)})
            return
        end

        if self.expup.l_num2 < xdonum then
            xdonum = self.expup.l_num2
        end    

        local l_exp = self.expup.l_exp
        local l_level = self.expup.l_level
        for i=1,xdonum do
            l_exp = l_exp+self.expup.upnum2
            if l_level+1 <= self.expup.maxlv and l_exp >= expconfig[tostring(l_level+1)]["quality"..self.expup.quality] then
                l_level = l_level + 1
                l_exp = l_exp - expconfig[tostring(l_level)]["quality"..self.expup.quality]

                if l_level+1 > self.expup.maxlv then
                    xdonum = i
                    break
                end
            end
        end

        if self.expup.l_num2 > 0 then
            self.expup.l_num2 = self.expup.l_num2-xdonum
            self.expup.l_exp = self.expup.l_exp+self.expup.upnum2*xdonum
            --runGamePrompt({msg = "经验+"..self.expup.upnum2})
            runGamePrompt({msg = gameConfig.strings:expNum(self.expup.upnum2*xdonum)})
        else
            --runGamePrompt({msg = "材料已消耗完"})
            runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",18)})
            endFunc(1)
        end

        while self.expup.l_level+1 <= self.expup.maxlv and self.expup.l_exp >= expconfig[tostring(self.expup.l_level+1)]["quality"..self.expup.quality] do
            if self.expup.l_level+1 > self.expup.maxlv then break end
            self.expup.l_level = self.expup.l_level + 1
            self.expup.l_exp = self.expup.l_exp - expconfig[tostring(self.expup.l_level)]["quality"..self.expup.quality]
        end

        self:setData_up(self.expup)
    end

    local Func3 = function(donum)
        local xdonum = donum or 1

        if (self.expup.l_level+1 > self.expup.maxlv) then 
            --runGamePrompt({msg = "经验值已满"})
            runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",17)})
            return
        end

        if self.expup.l_num3 < xdonum then
            xdonum = self.expup.l_num3
        end    

        local l_exp = self.expup.l_exp
        local l_level = self.expup.l_level
        for i=1,xdonum do
            l_exp = l_exp+self.expup.upnum3
            if l_level+1 <= self.expup.maxlv and l_exp >= expconfig[tostring(l_level+1)]["quality"..self.expup.quality] then
                l_level = l_level + 1
                l_exp = l_exp - expconfig[tostring(l_level)]["quality"..self.expup.quality]

                if l_level+1 > self.expup.maxlv then
                    xdonum = i
                    break
                end
            end
        end

        if self.expup.l_num3 > 0 then
            self.expup.l_num3 = self.expup.l_num3-xdonum
            self.expup.l_exp = self.expup.l_exp+self.expup.upnum3*xdonum
            --runGamePrompt({msg = "经验+"..self.expup.upnum3})
            runGamePrompt({msg = gameConfig.strings:expNum(self.expup.upnum3*xdonum)})
        else
            --runGamePrompt({msg = "材料已消耗完"})
            runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",18)})
            endFunc(1)
        end

        while self.expup.l_level+1 <= self.expup.maxlv and self.expup.l_exp >= expconfig[tostring(self.expup.l_level+1)]["quality"..self.expup.quality] do
            if self.expup.l_level+1 > self.expup.maxlv then break end
            self.expup.l_level = self.expup.l_level + 1
            self.expup.l_exp = self.expup.l_exp - expconfig[tostring(self.expup.l_level)]["quality"..self.expup.quality]
        end

        self:setData_up(self.expup)
    end

    local Func4 = function(donum)

        local xdonum = donum or 1

        if (self.expup.l_level+1 > self.expup.maxlv) then 
            --runGamePrompt({msg = "经验值已满"})
            runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",17)})
            return
        end

        if self.expup.l_num4 < xdonum then
            xdonum = self.expup.l_num4
        end    

        local l_exp = self.expup.l_exp
        local l_level = self.expup.l_level
        for i=1,xdonum do
            l_exp = l_exp+self.expup.upnum4
            if l_level+1 <= self.expup.maxlv and l_exp >= expconfig[tostring(l_level+1)]["quality"..self.expup.quality] then
                l_level = l_level + 1
                l_exp = l_exp - expconfig[tostring(l_level)]["quality"..self.expup.quality]

                if l_level+1 > self.expup.maxlv then
                    xdonum = i
                    break
                end
            end
        end

        if self.expup.l_num4 > 0 then
            self.expup.l_num4 = self.expup.l_num4-xdonum

            self.expup.l_exp = self.expup.l_exp+self.expup.upnum4*xdonum
            --runGamePrompt({msg = "经验+"..self.expup.upnum4})
            runGamePrompt({msg = gameConfig.strings:expNum(self.expup.upnum4*xdonum)})
        else
            --runGamePrompt({msg = "材料已消耗完"})
            runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",18)})
            endFunc(1)
        end

        while self.expup.l_level+1 <= self.expup.maxlv and self.expup.l_exp >= expconfig[tostring(self.expup.l_level+1)]["quality"..self.expup.quality] do
            if self.expup.l_level+1 > self.expup.maxlv then break end
            self.expup.l_level = self.expup.l_level + 1
            

            self.expup.l_exp = self.expup.l_exp - expconfig[tostring(self.expup.l_level)]["quality"..self.expup.quality]
        end

        self:setData_up(self.expup)
    end

    local reduce1 = function(donum)
        local xdonum = donum or 1

        if (self.expup.l_num1+xdonum) > self.expup.num1 then
            xdonum = self.expup.num1-self.expup.l_num1 
        end    

        if self.expup.l_num1 < self.expup.num1 then
            self.expup.l_num1 = self.expup.l_num1+xdonum
            self.expup.l_exp = self.expup.l_exp-self.expup.upnum1*xdonum
        end

        while self.expup.l_exp < 0 do
            self.expup.up_exp1 = expconfig[tostring(self.expup.l_level)]["quality"..self.expup.quality]
            self.expup.l_exp = self.expup.l_exp + self.expup.up_exp1
            self.expup.l_level = self.expup.l_level - 1
            if self.expup.l_level < 1 then break end
        end

        self:setData_up(self.expup)
    end

    local reduce2 = function(donum)
        local xdonum = donum or 1

        if (self.expup.l_num2+xdonum) > self.expup.num2 then
            xdonum = self.expup.num2-self.expup.l_num2 
        end    

        if self.expup.l_num2 < self.expup.num2 then
            self.expup.l_num2 = self.expup.l_num2+xdonum
            self.expup.l_exp = self.expup.l_exp-self.expup.upnum2*xdonum
        end

        while self.expup.l_exp < 0 do
            self.expup.up_exp1 = expconfig[tostring(self.expup.l_level)]["quality"..self.expup.quality]
            self.expup.l_exp = self.expup.l_exp + self.expup.up_exp1
            self.expup.l_level = self.expup.l_level - 1
            if self.expup.l_level < 1 then break end
        end

        self:setData_up(self.expup)
    end
    local reduce3 = function(donum)
        local xdonum = donum or 1

        if (self.expup.l_num3+xdonum) > self.expup.num3 then
            xdonum = self.expup.num3-self.expup.l_num3
        end    

        if self.expup.l_num3 < self.expup.num3 then
            self.expup.l_num3 = self.expup.l_num3+xdonum
            self.expup.l_exp = self.expup.l_exp-self.expup.upnum3*xdonum
        end

        while self.expup.l_exp < 0 do
            self.expup.up_exp1 = expconfig[tostring(self.expup.l_level)]["quality"..self.expup.quality]
            self.expup.l_exp = self.expup.l_exp + self.expup.up_exp1
            self.expup.l_level = self.expup.l_level - 1
            if self.expup.l_level < 1 then break end
        end

        self:setData_up(self.expup)
    end
    local reduce4 = function(donum)
        local xdonum = donum or 1

        if (self.expup.l_num4+xdonum) > self.expup.num4 then
            xdonum = self.expup.num4-self.expup.l_num4 
        end    

        if self.expup.l_num4 < self.expup.num4 then
            self.expup.l_num4 = self.expup.l_num4+xdonum
            self.expup.l_exp = self.expup.l_exp-self.expup.upnum4*xdonum
        end

        while self.expup.l_exp < 0 do
            self.expup.up_exp1 = expconfig[tostring(self.expup.l_level)]["quality"..self.expup.quality]
            self.expup.l_exp = self.expup.l_exp + self.expup.up_exp1
            self.expup.l_level = self.expup.l_level - 1
            if self.expup.l_level < 1 then break end
        end

        self:setData_up(self.expup)
    end

    if not self.delaybutton then
        ui.creatDelayButton(self.rootItems["add1"],-103,Func1,beginFunc,endFunc,1)
        ui.creatDelayButton(self.rootItems["add2"],-103,Func2,beginFunc,endFunc,2)
        ui.creatDelayButton(self.rootItems["add3"],-103,Func3,beginFunc,endFunc,3)
        ui.creatDelayButton(self.rootItems["add4"],-103,Func4,beginFunc,endFunc,4)

        ui.creatDelayButton(self.rootItems["reduce1"],-103,reduce1)
        ui.creatDelayButton(self.rootItems["reduce2"],-103,reduce2)
        ui.creatDelayButton(self.rootItems["reduce3"],-103,reduce3)
        ui.creatDelayButton(self.rootItems["reduce4"],-103,reduce4)

        self.delaybutton = true
    end
    --
    local quickFunc1 = function(isend)
        if (self.expup.l_level+1 > self.expup.maxlv) then --and (self.expup.l_exp >= gamedata.config.general_exp[tostring(self.expup.l_level)][tostring(self.expup.quality)..'exp']) then
            return true
        end

        if self.expup.l_num1 > 0 then
            self.expup.l_num1 = self.expup.l_num1-1
            self.expup.l_exp = self.expup.l_exp+self.expup.upnum1
        else
            return
        end

        while  self.expup.l_level+1 <= self.expup.maxlv and  self.expup.l_exp >= expconfig[tostring(self.expup.l_level+1)]["quality"..self.expup.quality] do
            
            self.expup.l_level = self.expup.l_level + 1
            self.expup.l_exp = self.expup.l_exp - expconfig[tostring(self.expup.l_level)]["quality"..self.expup.quality]
        end

    end
    local quickFunc2 = function(isend)
        if (self.expup.l_level+1 > self.expup.maxlv) then --and (self.expup.l_exp >= gamedata.config.general_exp[tostring(self.expup.l_level)][tostring(self.expup.quality)..'exp']) then
            return true
        end

        if self.expup.l_num2 > 0 then
            self.expup.l_num2 = self.expup.l_num2-1
            self.expup.l_exp = self.expup.l_exp+self.expup.upnum2
        else
            return
        end

        while  self.expup.l_level+1 <= self.expup.maxlv and  self.expup.l_exp >= expconfig[tostring(self.expup.l_level+1)]["quality"..self.expup.quality] do
            
            self.expup.l_level = self.expup.l_level + 1
            self.expup.l_exp = self.expup.l_exp - expconfig[tostring(self.expup.l_level)]["quality"..self.expup.quality]
        end

    end
    local quickFunc3 = function(isend)
        if (self.expup.l_level+1 > self.expup.maxlv) then --and (self.expup.l_exp >= gamedata.config.general_exp[tostring(self.expup.l_level)][tostring(self.expup.quality)..'exp']) then
            return true
        end

        if self.expup.l_num3 > 0 then
            self.expup.l_num3 = self.expup.l_num3-1
            self.expup.l_exp = self.expup.l_exp+self.expup.upnum3
        else
            return
        end

        while self.expup.l_level+1 <= self.expup.maxlv and self.expup.l_exp >= expconfig[tostring(self.expup.l_level+1)]["quality"..self.expup.quality] do
            
            self.expup.l_level = self.expup.l_level + 1
            self.expup.l_exp = self.expup.l_exp - expconfig[tostring(self.expup.l_level)]["quality"..self.expup.quality]
        end

    end

    local quickFunc4 = function(isend)
        if (self.expup.l_level+1 > self.expup.maxlv) then --and (self.expup.l_exp >= gamedata.config.general_exp[tostring(self.expup.l_level)][tostring(self.expup.quality)..'exp']) then
            return true
        end

        if self.expup.l_num4 > 0 then
            self.expup.l_num4 = self.expup.l_num4-1
            self.expup.l_exp = self.expup.l_exp+self.expup.upnum4
        else
            return
        end

        while self.expup.l_level+1 <= self.expup.maxlv and self.expup.l_exp >= expconfig[tostring(self.expup.l_level+1)]["quality"..self.expup.quality] do
            
            self.expup.l_level = self.expup.l_level + 1
            
            self.expup.l_exp = self.expup.l_exp - expconfig[tostring(self.expup.l_level)]["quality"..self.expup.quality]
        end

    end

    local quickAdd = function()
        local isend = false
        for i=1,self.expup.l_num1 do
            if isend then
                break
            else
                isend = quickFunc1(isend)
            end
        end
        for i=1,self.expup.l_num2 do
            if isend then
                break
            else
                isend = quickFunc2(isend)
            end
        end
        for i=1,self.expup.l_num3 do
            if isend then
                break
            else
                isend = quickFunc3(isend)
            end
        end
        for i=1,self.expup.l_num4 do
            if isend then
                break
            else
                isend = quickFunc4(isend)
            end
        end
        
        self:setData_up(self.expup)
        for i = 1,4 do
            beginFunc(i,1)
            endFunc(i)
        end
    end

    -----
    ui.setLabelString(self.rootItems.up_upLab,"确定",19)
    self.rootItems.up_upButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)

        local props = {}

        for k,v in ipairs(propids) do
            table.insert(props,{cid = v, num = self.expup["num"..k] - self.expup["l_num"..k]})
        end

        -- table.insert(props,{cid = 20196, num = self.expup.num1 - self.expup.l_num1})
        -- table.insert(props,{cid = 20197, num = self.expup.num2 - self.expup.l_num2})
        -- table.insert(props,{cid = 20198, num = self.expup.num3 - self.expup.l_num3})
        -- table.insert(props,{cid = 20199, num = self.expup.num4 - self.expup.l_num4})



        --if self.expup.l_level+1 > self.expup.maxlv then
        --runGamePrompt({msg = "已到最高级"})
        --    runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",17)})
        if (self.expup.num1+self.expup.num2+self.expup.num3+self.expup.num4-self.expup.l_num1-self.expup.l_num2-self.expup.l_num3-self.expup.l_num4)<1 then
            --runGamePrompt({msg = "请选择消耗材料"})
            runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",19)})
        else
            UIRequest({type = 1210, iid = self.data.iid, cids = props,xcoin = self.xcoin})
--            if self.expup.l_level > self.data.general.level1 then
--                local effectccb,effectitem = CCBReaderLoad("UIEffect/renwushengji/renwushengji", nil, true, "renwushengji")
--                self.rootItems.effectnode_top:removeAllChildrenWithCleanup(true)
--                self.rootItems.effectnode_top:addChild(effectccb)
--            end
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.up_upButton:setSwallowsTouch(true)
    self.rootItems.up_upButton:setTouchPriority(-103)
    --
    if self.rootItems.up_addButton then
        ui.setLabelString(self.rootItems.up_addLab,"一键添加",19)
        self.rootItems.up_addButton:addHandleOfControlEvent(function()
            if (self.expup.l_level+1 > self.expup.maxlv) then --and (self.expup.l_exp >= gamedata.config.general_exp[tostring(self.expup.l_level)][tostring(self.expup.quality)..'exp']) then
                --runGamePrompt({msg = "经验值已满"})
                runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",17)})
            elseif (self.expup.num1+self.expup.num2+self.expup.num3+self.expup.num4)<1 then
                --runGamePrompt({msg = "材料已消耗完"})
                runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",18)})
            else
                quickAdd()
            end

        end, CCControlEventTouchUpInside)
        self.rootItems.up_addButton:setSwallowsTouch(true)
        self.rootItems.up_addButton:setTouchPriority(-103)
    end
end


function treasureup.setPage_up_consum_treasure( self )

    self.rootItems.quicknode:setVisible(true)

    --
    --self:setexp_up()
    -- 宝物强化选中栏
    self:setShowItems()
    --
    ui.setLabelString(self.rootItems.up_upLab,"强化",19)
    self.rootItems.up_upButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)

        if table.getTableLength(self.selectData) < 1 then
            runGamePrompt({msg = "请选择消耗物品"})
        elseif self.data.level1 >= self.data.maxlv1 then
            runGamePrompt({msg = "强化等级已达上限"})
        elseif self.xcoin > GameScene.roleinfo.coin then
            --runGamePrompt({msg = "银币不足"})
            shortCoin()
        else
            local ids = {}
            for k,v in pairs(self.selectData) do
                table.insert(ids,v.iid)
            end
            UIRequest({type= 1118, iid = self.data.iid, xcoin = self.xcoin, ids = ids})

            self.rootItems.up_effect1:removeAllChildrenWithCleanup(true)
            local qianghuaNode1,qianghuaItems1 = CCBReaderLoad("UIEffect/qianghua/luzi_effect", nil, true, "luzieffect")
            qianghuaNode1:setPosition(0,0)
            self.rootItems.up_effect1:addChild(qianghuaNode1)
            self.rootItems.up_effect1:setScale(1)
            local animationManager1 = getAnimationManager(qianghuaItems1)
            animationManager1:setAnimationCompletedCallback(function()
                self.rootItems.up_effect1:removeAllChildrenWithCleanup(true)
            end)
            animationManager1:runAnimationsForSequenceNamed("luzieffect")

            if self.uplevel1 > self.data.level1 then
                self.rootItems.up_effect2:removeAllChildrenWithCleanup(true)
                local qianghuaNode,qianghuaItems = CCBReaderLoad("UIEffect/qianghua/qianghua", nil, true, "qianghua")
                qianghuaNode:setPosition(0,0)
                self.rootItems.up_effect2:addChild(qianghuaNode)
                self.rootItems.up_effect2:setScale(1)
                local animationManager = getAnimationManager(qianghuaItems)
                animationManager:setAnimationCompletedCallback(function()
                    self.rootItems.up_effect2:removeAllChildrenWithCleanup(true)
                end)
                animationManager:runAnimationsForSequenceNamed("qianghua")
                gamedata.music:PlayOptSound("xlshjhtp")
            end
        end
    end,CCControlEventTouchUpInside)
    self.rootItems.up_upButton:setSwallowsTouch(true)
    self.rootItems.up_upButton:setTouchPriority(-103)

    printT(self.data)
    
    local touchnum = 0
    ui.setLabelString(self.rootItems.up_addLab,"自动添加",19)
    self.rootItems.up_addButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)

        if self.uplevel1 >= self.data.maxlv1 then
            runGamePrompt({msg = "强化等级已达上限"})
            return
        end
        self.chooseData = self.chooseData or {}
        local choosenum = #self.chooseData
        local hastype = false
        local add = true
        for k,v in ipairs(self.treasures) do
            local tempconfig = gamedata.config.equip[tostring(v.cid)]
            printT(tempconfig,"tempconfig===")
            if self.uplevel1 >= self.data.maxlv1 then
                self:setShowItems()
                return

            elseif self.data.iid and v.iid == self.data.iid then

            elseif self.data.type == v.type and choosenum < 5 and (tonumber(tempconfig.adorn) == 0 or (v.quality <= self.resolvequality)) then
                self.selectData[v.iid] = v
                self:setexp_up()
                add = true
                for kk,vv in pairs(self.chooseData)  do
                    if vv.iid == v.iid then
                        add = false
                        break
                    end
                end
                if add ==  true then
                    table.insert(self.chooseData,v)
                    choosenum = choosenum + 1
                end
            end
            if v.quality > self.resolvequality then
                hastype = true
            end
        end
        if not next(self.chooseData) and hastype==false then
            runGamePrompt({msg = "没有可自动添加的品质宝物,请手动添加"})
        elseif not next(self.chooseData) and hastype==true then
            runGamePrompt({msg = "没有可自动添加的品质宝物,请手动添加"})
        elseif #(self.chooseData) < 5 and touchnum == #(self.chooseData) and hastype==false then
            runGamePrompt({msg = "没有可自动添加的品质宝物,请手动添加"})
        elseif #(self.chooseData) < 5 and touchnum == #(self.chooseData) and hastype==true then
            runGamePrompt({msg = "没有可自动添加的品质宝物,请手动添加"})
        end

        touchnum = #(self.chooseData)
        self:setShowItems()
    end, CCControlEventTouchUpInside)
    self.rootItems.up_addButton:setSwallowsTouch(true)
    self.rootItems.up_addButton:setTouchPriority(-103)
end

function treasureup.setRawItem(self,num)
    
    local key_Ex
    if num == nil or num == 0 then
        key_Ex = ""
    else
        key_Ex = "_"..num
    end

    local treasureiid = 0
    self.rootItems["i_button"..key_Ex]:addHandleOfControlEvent(function()
        local cb = function(temdata)
            local tempTab = {}
            for k,v in pairs(temdata) do
                table.insert(tempTab,v)
            end
            self.data = tempTab[1]
            self:ReloadData()
        end
        gameWindows:openWindow("selectlist",{type = "change_treasure_one", param = {equipiid = treasureiid}},cb)
    end, CCControlEventTouchUpInside)
   
    setSpriteFrameByName(self.rootItems["i_icon"..key_Ex], "obj_add2")
    setSpriteFrameByName(self.rootItems["i_k_quality"..key_Ex], "b_iconk1")
    setSpriteFrameByName(self.rootItems["i_quality"..key_Ex], "b_iconbg1")
    self.rootItems["i_soulsprite"..key_Ex]:setVisible(false)
    self.rootItems["i_soulnode"..key_Ex]:removeAllChildrenWithCleanup(true)
    self.rootItems["i_suitNode"..key_Ex]:removeAllChildrenWithCleanup(true)
    ui.setLabelString(self.rootItems["i_num"..key_Ex],"",13)

end


function treasureup.setexp_up(self)

    local equipconfig = gamedata.config.equip
    local expconfig = gamedata.config.treasure2_strengthen

    self.uplevel1 = self.data.level1 or 1
    self.upexp = self.data.exp or 0

    if self.uplevel1 < self.data.maxlv1 then

        for k,v in pairs(self.selectData) do
            local exp = 0
            for i = 1,v.level1 do
                exp = exp + expconfig[tostring(i)]["quality"..v.quality]
            end
            self.upexp = self.upexp + (equipconfig[tostring(v.cid)].exp or 0) + exp
        end

        while self.upexp >= expconfig[tostring(self.uplevel1+1)]["quality"..self.data.quality] do
            self.upexp = self.upexp - expconfig[tostring(self.uplevel1+1)]["quality"..self.data.quality]
            self.uplevel1 = self.uplevel1 + 1
            if self.uplevel1 >= self.data.maxlv1 then break end
        end

    end


    if self.uplevel1 < self.data.maxlv1 then
        local nextexp = expconfig[tostring(self.uplevel1+1)]["quality"..self.data.quality] or 0

        self.rootItems.up_exp:setString(self.upexp.."/"..nextexp)
        ui.setSpriteTextureRect2(self.rootItems["up_expsprite"],0,0,844 * ((self.upexp >= nextexp) and 1 or (self.upexp / nextexp)),31)
    else
        self.rootItems.up_exp:setString("Max")
        ui.setSpriteTextureRect2(self.rootItems["up_expsprite"],0,0,844,31)
    end

    if self.uplevel1 > self.data.level1 then
        self.rootItems.up_levelup:setString("+"..(self.uplevel1 - self.data.level1))

        if equipconfig[tostring(self.data.cid)].attr1 and equipconfig[tostring(self.data.cid)].attr1 ~= "" then
            self.rootItems.up_attrnum_up1:setString("+"..(equipconfig[tostring(self.data.cid)].grow_1*(self.uplevel1 - self.data.level1)*(equipconfig[tostring(self.data.cid)].method1 == "value" and 1 or 100))..(equipconfig[tostring(self.data.cid)].method1 == "value" and "" or "%"))
        else
            self.rootItems.up_attrnum_up1:setString("")
        end

        if equipconfig[tostring(self.data.cid)].attr2 and equipconfig[tostring(self.data.cid)].attr2 ~= "" then
            self.rootItems.up_attrnum_up2:setString("+"..(equipconfig[tostring(self.data.cid)].grow_2*(self.uplevel1 - self.data.level1)*(equipconfig[tostring(self.data.cid)].method2 == "value" and 1 or 100))..(equipconfig[tostring(self.data.cid)].method2 == "value" and "" or "%"))
        else
            self.rootItems.up_attrnum_up2:setString("")
        end

    else
        self.rootItems.up_levelup:setString("")
        self.rootItems.up_attrnum_up1:setString("")
        self.rootItems.up_attrnum_up2:setString("")
    end
    ui.setLabelString(self.rootItems.up_exp,nil,13)
    ui.setLabelString(self.rootItems.up_levelup,nil,22)
    ui.setLabelString(self.rootItems.up_attrnum_up1,nil,23)
    ui.setLabelString(self.rootItems.up_attrnum_up2,nil,23)
    --
    self.xcoin = 0
    for k,v in pairs(self.selectData) do
        self.xcoin = self.xcoin + gamedata.config.global_kv["treasure_strengthen_coin"..v.quality].value
    end
    self.rootItems.up_xcoin:setString(self.xcoin)
    ui.setLabelString(self.rootItems.up_xcoin,nil,13)
end

function treasureup.setData_up( self )

    local level1 =  self.expup.l_level or self.data.level1

    local equipconfig = gamedata.config.equip
    local expconfig = gamedata.config.treasure2_strengthen

    self.rootItems["in_num"]:setString( "x"..self.expup.l_num1  )
    self.rootItems["in_num_1"]:setString( "x"..self.expup.l_num2  )
    self.rootItems["in_num_2"]:setString( "x"..self.expup.l_num3  )
    self.rootItems["in_num_3"]:setString( "x"..self.expup.l_num4  )
    ui.setLabelString(self.rootItems["in_num"],nil,13)
    ui.setLabelString(self.rootItems["in_num_1"],nil,13)
    ui.setLabelString(self.rootItems["in_num_2"],nil,13)
    ui.setLabelString(self.rootItems["in_num_3"],nil,13)

    local nextexp = 0
    if self.expup.l_level+0 < self.expup.maxlv then
        nextexp = expconfig[tostring(self.expup.l_level+1)]["quality"..self.expup.quality]
    end


    if self.expup.l_level+0 < self.expup.maxlv then
        ui.setLabelString(self.rootItems.up_exp,self.expup.l_exp.."/"..nextexp,13)
    else
        ui.setLabelString(self.rootItems.up_exp,"Max",13)
    end
    

    if self.expup.l_level > self.data.level1 then
        ui.setSpriteTextureRect2(self.rootItems["up_expsprite"],0,0,844 * 1 ,self.rootItems["up_expsprite"]:getContentSize().height)
    else
        ui.setSpriteTextureRect2(self.rootItems["up_expsprite"],0,0,844 * ((self.expup.l_exp>=nextexp) and 1 or (self.expup.l_exp / nextexp)),self.rootItems["up_expsprite"]:getContentSize().height)
    end

    if self.expup.l_level > self.data.level1 then
        self.rootItems.up_levelup:setString("+"..(self.expup.l_level - self.data.level1))

        if equipconfig[tostring(self.data.cid)].attr1 and equipconfig[tostring(self.data.cid)].attr1 ~= "" then
            self.rootItems.up_attrnum_up1:setString("+"..(equipconfig[tostring(self.data.cid)].grow_1*(self.expup.l_level - self.data.level1)*(equipconfig[tostring(self.data.cid)].method1 == "value" and 1 or 100))..(equipconfig[tostring(self.data.cid)].method1 == "value" and "" or "%"))
        else
            self.rootItems.up_attrnum_up1:setString("")
        end

        if equipconfig[tostring(self.data.cid)].attr2 and equipconfig[tostring(self.data.cid)].attr2 ~= "" then
            self.rootItems.up_attrnum_up2:setString("+"..(equipconfig[tostring(self.data.cid)].grow_2*(self.expup.l_level - self.data.level1)*(equipconfig[tostring(self.data.cid)].method2 == "value" and 1 or 100))..(equipconfig[tostring(self.data.cid)].method2 == "value" and "" or "%"))
        else
            self.rootItems.up_attrnum_up2:setString("")
        end

    else
        self.rootItems.up_levelup:setString("")
        self.rootItems.up_attrnum_up1:setString("")
        self.rootItems.up_attrnum_up2:setString("")
    end

    if self.expup.num1-self.expup.l_num1 > 0 then
        self.rootItems.reduceNode1:setVisible(true)
    else
        self.rootItems.reduceNode1:setVisible(false)
    end
    if self.expup.num2-self.expup.l_num2 > 0 then
        self.rootItems.reduceNode2:setVisible(true)
    else
        self.rootItems.reduceNode2:setVisible(false)
    end
    if self.expup.num3-self.expup.l_num3 > 0 then
        self.rootItems.reduceNode3:setVisible(true)
    else
        self.rootItems.reduceNode3:setVisible(false)
    end
    if self.expup.num4-self.expup.l_num4 > 0 then
        self.rootItems.reduceNode4:setVisible(true)
    else
        self.rootItems.reduceNode4:setVisible(false)
    end

    self.xcoin = 0
    for k,v in pairs(self.propid[self.data.type]) do
        local quality = gamedata.config.props[tostring(v)].quality
        local coinstep = gamedata.config.global_kv["treasure_strengthen_coin"..quality].value
        local num = self.expup["num"..k]-self.expup["l_num"..k]
        self.xcoin = self.xcoin + coinstep*num
    end
    self.rootItems.up_xcoin:setString(self.xcoin)
    ui.setLabelString(self.rootItems.up_xcoin,nil,13)
end


function treasureup.setPropNum(self,data)

    self.refinePropNum = data[tostring(self.refinePropcid)] or 0
    ui.setNewIcon(self.rootItems,{ cid = self.refinePropcid, num = self.refinePropNum.."/"..self.refinePropx } ,3)

    ui.setLabelString(self.rootItems["i_num_3"],nil,self.refinePropNum+0 < self.refinePropx+0 and 24 or 22)
end

function treasureup.setUpPropNum(self,data)

    local propids = self.propid[self.data.type]

    for k,v in ipairs(propids) do
        self.expup["num"..k] = data[tostring(v)] or 0
        self.expup["l_num"..k] = self.expup["num"..k]
    end

    self:setData_up(self.expup)
end


return treasureup
�S 