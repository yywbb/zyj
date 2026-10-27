--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-9
-- Time: 下午6:52
-- To change this template use File | Settings | File Templates.
--

local equipsList = {

    resource = nil,

    rootNode = nil,
    rootItems = nil,

    equipListTableView = nil,
    treasureListTableView = nil,
    fragmentListTableView = nil,
    propsListTableView = nil,


    equipshowData = nil,
    equipsData = nil,
    weaponData = nil,
    armorData = nil,
    headData = nil,
    accessoryData = nil,

    treasureshowData = nil,
    treasuresData =nil,
    treasureData = nil,
    horseData = nil,

    fragmentShowData = nil,
    fragmentequipData = nil,
    fragmenttreasureData = nil,
    fragmentmeterialData = nil,

    propsData = nil,
    oldpropnum = 0,

    propShowData = nil,
    proppropsData = nil,
    propproptype1Data = nil,
    propproptype2Data = nil,
    propproptype3Data = nil,
    propproptype4Data = nil,


    -- pageconfig = {"equip","treasure","fragment","props"} ,
    -- pagename = {gameConfig.strings:string_common("equips",0),gameConfig.strings:string_common("equips",1),gameConfig.strings:string_common("equips",2),gameConfig.strings:string_common("equips",3)},
    -- selectpage = "equip",

    pageconfig = {"props","equip","treasure","fragment"} ,
    pagename = {gameConfig.strings:string_common("equips",3),gameConfig.strings:string_common("equips",0),gameConfig.strings:string_common("equips",1),gameConfig.strings:string_common("equips",2)},
    selectpage = "props",
    equiptypeconfig = {"equips","weapon","armor","head","accessory"},
    equipselectpage = "equips",

    treasuretypeconfig = {"treasures","horse","treasure"},
    treasureselectpage = "treasures",

    fragmenttypeconfig = {"equip","treasure","meterial"},
    fragmentselectpage = "equip",
    rigistTime = {},

    proptypeconfig = {"props","proptype1","proptype2","proptype3","proptype4"},
    propselectpage = "props",

    CellSize = {x=1080,y=270},

    hintconfig = {
        {
            name = "rootItems",
            type = "self",
            config = {
                title4 = {111},
                title1 = {8},
            },
        },
    },
    isscrolltouched = false,

    recoveryOpen = false,
    ccbDocument = {},
    slotDataTem = {},
    protagonistPosition = 1,

    bagiconbg_Y = 0,
    toppos = 0,
}


function equipsList.shiftPage(self,type)
    self.selectpage = type

    if type ==  "equip" then
        if self.rootItems.topNodeProps then
            self.rootItems.topNodeProps:setVisible(false)
        end    
        self.rootItems.topNodeEquip:setVisible(true)
        self.rootItems.topNodeTreasure:setVisible(false)
        self.rootItems.topNodeFragment:setVisible(false)
        self.rootItems.listEquip:setPositionX(0)
        self.rootItems.listTreasure:setPositionX(-9999)
        self.rootItems.listFragment:setPositionX(-9999)
        self.rootItems.listProp:setPositionX(-9999)

        if self.rootItems.hasnumstr then
            self.rootItems.hasnumstr:setVisible(true)
            -- self.rootItems.topbg1:setVisible(true)
            -- self.rootItems.topbg2:setVisible(false)
            self.rootItems.bagiconbg:setPositionY(self.bagiconbg_Y-50)
        end
        self.rootItems.bagiconbg:setContentSize(CCSizeMake(gameConfig.originSize.width-40,self.toppos-gameConfig.maiscenebottomheight-840-30-50))
        self.rootItems.listEquip:setContentSize(CCSizeMake(gameConfig.originSize.width,self.toppos-gameConfig.maiscenebottomheight-840-28-30-50))

        self:shiftEquipPage(self.equipselectpage)
    elseif type ==  "treasure" then
        if self.rootItems.topNodeProps then
            self.rootItems.topNodeProps:setVisible(false)
        end    
        self.rootItems.topNodeEquip:setVisible(false)
        self.rootItems.topNodeTreasure:setVisible(true)
        self.rootItems.topNodeFragment:setVisible(false)

        self.rootItems.listEquip:setPositionX(-9999)
        self.rootItems.listTreasure:setPositionX(0)
        self.rootItems.listFragment:setPositionX(-9999)
        self.rootItems.listProp:setPositionX(-9999)

        if self.rootItems.hasnumstr then
            self.rootItems.hasnumstr:setVisible(true)
            -- self.rootItems.topbg1:setVisible(true)
            -- self.rootItems.topbg2:setVisible(false)
            self.rootItems.bagiconbg:setPositionY(self.bagiconbg_Y-50)
        end
        self.rootItems.bagiconbg:setContentSize(CCSizeMake(gameConfig.originSize.width-40,self.toppos-gameConfig.maiscenebottomheight-840-30-50))
        self.rootItems.listTreasure:setContentSize(CCSizeMake(gameConfig.originSize.width,self.toppos-gameConfig.maiscenebottomheight-840-28-30-50))

        self:shiftTreasurePage(self.treasureselectpage)
    elseif type ==  "fragment" then
        if self.rootItems.topNodeProps then
            self.rootItems.topNodeProps:setVisible(false)
        end    
        self.rootItems.topNodeEquip:setVisible(false)
        self.rootItems.topNodeTreasure:setVisible(false)
        self.rootItems.topNodeFragment:setVisible(true)

        self.rootItems.listEquip:setPositionX(-9999)
        self.rootItems.listTreasure:setPositionX(-9999)
        self.rootItems.listFragment:setPositionX(0)
        self.rootItems.listProp:setPositionX(-9999)

        if self.rootItems.hasnumstr then
            self.rootItems.hasnumstr:setVisible(false)
            -- self.rootItems.topbg1:setVisible(false)
            -- self.rootItems.topbg2:setVisible(true)
            self.rootItems.bagiconbg:setPositionY(self.bagiconbg_Y)
        end    
        self.rootItems.bagiconbg:setContentSize(CCSizeMake(gameConfig.originSize.width-40,self.toppos-gameConfig.maiscenebottomheight-840-30))
        self.rootItems.listFragment:setContentSize(CCSizeMake(gameConfig.originSize.width,self.toppos-gameConfig.maiscenebottomheight-840-40-30))

        self:shiftFragmentPage(self.fragmentselectpage)
    elseif type ==  "props" then
        if self.rootItems.topNodeProps then
            self.rootItems.topNodeProps:setVisible(true)
        end    
        self.rootItems.topNodeEquip:setVisible(false)
        self.rootItems.topNodeTreasure:setVisible(false)
        self.rootItems.topNodeFragment:setVisible(false)

        self.rootItems.listEquip:setPositionX(-9999)
        self.rootItems.listTreasure:setPositionX(-9999)
        self.rootItems.listFragment:setPositionX(-9999)
        self.rootItems.listProp:setPositionX(0)

        if self.rootItems.hasnumstr then
            self.rootItems.hasnumstr:setVisible(false)
            -- self.rootItems.topbg1:setVisible(false)
            -- self.rootItems.topbg2:setVisible(true)
            self.rootItems.bagiconbg:setPositionY(self.bagiconbg_Y)
        end
        self.rootItems.bagiconbg:setContentSize(CCSizeMake(gameConfig.originSize.width-40,self.toppos-gameConfig.maiscenebottomheight-840-30))
        self.rootItems.listProp:setContentSize(CCSizeMake(gameConfig.originSize.width,self.toppos-gameConfig.maiscenebottomheight-840-40-30))

        self:showProps(self.propselectpage)
    end

    -- if type == "equip" and self.equipselectpage == "equips" then
    --     local equipnum = table.getTableLength(self.equipshowData)
    --     if equipnum>gameConfig.bagLimit_equip then
    --         -- runGamePrompt({msg="您的装备已超过"..gameConfig.bagLimit_equip.."件，请及时处理。"})
    --         --runGamePrompt({msg=gameConfig.strings:equipExced(gameConfig.bagLimit_equip)})
    --         local cb = function()
    --             gameTouch:clickprofbytime(0.5)
    --             GameScene:shiftLayer("qiankunlu","up")
    --         end
    --         gameWindows:openWindow("guildmsg",{msg = "由于装备过多，建议及时处理，\n否则会造成游戏卡顿。", button_lab = "前 往"},cb)
    --     end
    -- elseif type ==  "treasure" and self.treasureselectpage == "treasures" then
    --     local equipnum = table.getTableLength(self.treasureshowData)
    --     if equipnum>gameConfig.bagLimit_treasure then
    --         -- runGamePrompt({msg="您的宝物已超过"..gameConfig.bagLimit_equip.."件，请及时处理。"})
    --         --runGamePrompt({msg=gameConfig.strings:tresureExced(gameConfig.bagLimit_equip)})
    --         gameWindows:openWindow("guildmsg",{msg = "由于宝物过多，建议及时处理，\n否则会造成游戏卡顿。", button_lab = "确 定"},nil)
    --     end
    -- end
end

function equipsList.shiftEquipPage(self,type)
    local relocat = self.equipselectpage ~= type
    self.equipselectpage = type
    self.equipshowData =  self[type.."Data"]

    if not GameScene:checkUpdate(10025,type) and not GameScene:checkUpdate(10025,"equips") then
        if not self.equipListTableView then
            self:createEquipsList()
        else
            if relocat then
                self.equipListTableView:setLuaContentOffset(0, self.rootItems.listEquip:getContentSize().height - math.ceil(table.getTableLength(self.equipshowData)/5)*self.CellSize.y) -- table.getTableLength(self.equipshowData)
            end
            self.equipListTableView:reloadData()
        end
    end

    for k,v in ipairs(self.equiptypeconfig) do
        if v == type then
        --    self.rootItems[v.."Onbg"]:setVisible(true)
           self.rootItems[v.."Onpoint"]:setVisible(true)
        else
            -- self.rootItems[v.."Onbg"]:setVisible(false)
            self.rootItems[v.."Onpoint"]:setVisible(false)
        end
    end


    ui.setGoto(self.rootItems.gotonode,table.getTableLength(self.equipshowData) == 0,self.equipselectpage)

    --
    if self.rootItems.hasnumstr then
        ui.setLabelString(self.rootItems.hasnumstr,"当前拥有装备："..table.getTableLength(self.equipshowData).."/1000",14)
    end 

end

function equipsList.shiftTreasurePage(self,type)
    local relocat = self.treasureselectpage ~= type
    self.treasureselectpage = type
    self.treasureshowData =  self[type.."Data"]

    if not GameScene:checkUpdate(10025,type) and not GameScene:checkUpdate(10025,"treasures") then
        if not self.treasureListTableView then
            self:createTreasureList()
        else
            if relocat then  
                self.treasureListTableView:setLuaContentOffset(0, self.rootItems.listTreasure:getContentSize().height - math.ceil(table.getTableLength(self.treasureshowData)/5)*self.CellSize.y) -- table.getTableLength(self.treasureshowData)
            end
            self.treasureListTableView:reloadData()
        end
    end

    for k,v in ipairs(self.treasuretypeconfig) do
        if v == type then
            -- self.rootItems[v.."Onbg"]:setVisible(true)
            self.rootItems[v.."Onpoint"]:setVisible(true)
        else
            -- self.rootItems[v.."Onbg"]:setVisible(false)
            self.rootItems[v.."Onpoint"]:setVisible(false)
        end
    end

    ui.setGoto(self.rootItems.gotonode,table.getTableLength(self.treasureshowData) == 0,self.treasureselectpage)

    --
    if self.rootItems.hasnumstr then
        ui.setLabelString(self.rootItems.hasnumstr,"当前拥有宝物："..table.getTableLength(self.treasureshowData).."/1000",14)
    end 
end

function equipsList.shiftFragmentPage(self,type)
    local relocat = self.fragmentselectpage ~= type
    self.fragmentselectpage = type
    self.fragmentShowData =  self["fragment"..type.."Data"]

    if not GameScene:checkUpdate(11071,type) then
        if not self.fragmentListTableView then
            self:createFragmentList()
            self["oldfragmentnum"..type] = math.ceil(table.getTableLength(self.fragmentShowData)/5)
        else
            if relocat or type == "treasure" then
                self.fragmentListTableView:setLuaContentOffset(0, self.rootItems.listFragment:getContentSize().height - math.ceil(table.getTableLength(self.fragmentShowData)/5)*self.CellSize.y) -- table.getTableLength(self.fragmentShowData)
            elseif self["oldfragmentnum"..type] and self["oldfragmentnum"..type] ~= math.ceil(table.getTableLength(self.fragmentShowData)/5) then
                self.fragmentListTableView:setLuaContentOffset(0, self.fragmentListTableView:getLuaContentOffsetY() + (self["oldfragmentnum"..type] - math.ceil(table.getTableLength(self.fragmentShowData)/5)*self.CellSize.y)) -- table.getTableLength(self.fragmentShowData)
                self["oldfragmentnum"..type] = nil
            end
            self.fragmentListTableView:reloadData()
        end
    else
        self["oldfragmentnum"..type] = math.ceil(table.getTableLength(self.fragmentShowData)/5)
    end

    for k,v in ipairs(self.fragmenttypeconfig) do
        if v == type then
            -- self.rootItems["fragment"..v.."Onbg"]:setVisible(true)
            self.rootItems["fragment"..v.."Onpoint"]:setVisible(true)
        else
            -- self.rootItems["fragment"..v.."Onbg"]:setVisible(false)
            self.rootItems["fragment"..v.."Onpoint"]:setVisible(false)
        end
    end


    ui.setGoto(self.rootItems.gotonode,table.getTableLength(self.fragmentShowData) == 0,self.fragmentselectpage.."fragment")
end

function equipsList.showProps(self,type)

    if self.selectpage ~= "props" then
        return
    end
    if not type then type = self.propselectpage end 

    local relocat = self.propselectpage ~= type
    self.propselectpage = type
    self.propShowData =  self["prop"..type.."Data"]

    for k,v in ipairs(self.proptypeconfig) do
        if v == type then
        --    self.rootItems[v.."Onbg"]:setVisible(true)
           self.rootItems[v.."Onpoint"]:setVisible(true)
        else
            -- self.rootItems[v.."Onbg"]:setVisible(false)
            self.rootItems[v.."Onpoint"]:setVisible(false)
        end
    end
    
    if self.rootItems then
        if not GameScene:checkUpdate(1200) then
            if not self.propsListTableView then
                self:createPropsList()
                self.oldpropnum = self.propShowData and math.ceil(table.getTableLength(self.propShowData)/5)
            else

                local newnum = self.propShowData and math.ceil(table.getTableLength(self.propShowData)/5) or 0
                print("self.oldpropnum-newnum5",self.oldpropnum,newnum)
                if relocat then
                    self.propsListTableView:setLuaContentOffset(0, self.rootItems.listProp:getContentSize().height - math.ceil(table.getTableLength(self.propShowData)/5)*self.CellSize.y) -- table.getTableLength(self.propShowData)
                else
                    self.propsListTableView:setLuaContentOffset(0, self.propsListTableView:getLuaContentOffsetY() + (self.oldpropnum-newnum)*self.CellSize.y) -- (self.oldpropnum-newnum)
                end 
                self.oldpropnum = newnum
                self.propsListTableView:reloadData()
            end
        end
    end
    ui.setGoto(self.rootItems.gotonode,table.getTableLength(self.propShowData) == 0,"props")
end

function equipsList.setEquipDataByType(self, type, data)
    self[type.."Data"] = data
end

function equipsList.ReloadFragmentData(self,data)

    if data.equipfragments then
        self.fragmentequipData = data.equipfragments
    end

    if data.treasurefragments then
        self.fragmenttreasureData = data.treasurefragments
    end

    if data.meterialfragments then
        self.fragmentmeterialData = data.meterialfragments
    end
end

function equipsList.ReloadPropsData(self,data)
    print("ReloadPropsData")
    
    local time1length = table.getTableLength(data.props)
    local time2length = 0
    
    if self.propShowData then
        self.oldpropnum = math.ceil(table.getTableLength(self.propShowData)/5)
    else
        self.oldpropnum = self.propsData and math.ceil(table.getTableLength(self.propsData)/5) or math.ceil((time1length+time2length)/5)
    end

    self.propsData = {}
    if self.countdownGiftData and next(self.countdownGiftData) then

        for k,v in pairs(self.countdownGiftData) do
            v.proptype = 1
            local configdata = ui.IDconfig(v.cid)
            v.quality = configdata.quality
            table.insert(self.propsData,v)
        end
        if data.props and next(data.props) then 
            for k,v in pairs(data.props) do
                v.proptype = 2
                local configdata = ui.IDconfig(v.cid)
                v.quality = configdata.quality
                table.insert(self.propsData,v)
            end
        end

    else
        if data.props and next(data.props) then 
            for k,v in pairs(data.props) do
                v.proptype = 2
                local configdata = ui.IDconfig(v.cid)
                v.quality = configdata.quality
                table.insert(self.propsData,v)
            end
        end
        --self.propsData = data.props
    end

    ui.sortData2(self.propsData, "proptype","priority","quality",nil,nil,true)
    printT(self.propsData,"self.propsData   ---  ")
    --self.propsData = data.props

    self.proppropsData = self.propsData or {}
    self["propproptype1Data"] = {}
    self["propproptype2Data"] = {}
    self["propproptype3Data"] = {}
    self["propproptype4Data"] = {}

    for k,v in ipairs(self.propsData) do
        local configdata = ui.IDconfig(v.cid)
        if configdata.classification and self["propproptype"..configdata.classification.."Data"] then
            table.insert(self["propproptype"..configdata.classification.."Data"],v)
        end    
    end     

end

--限时道具
function equipsList.ReloadLimitPropsData(self,data)
    printT(data,"ReloadLimitPropsData --- ")

    if not GameScene:checkUpdate(5901) then
        self.countdownGiftData = data.countdownGift
        GameScene:checkUpdate(1200)
    end


end


function equipsList.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("equip_new/equipList", nil, true, "equipList")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)
    -- self.rootItems.toptitle:setPositionY(toppos)
    self.rootItems.gotonode:setPositionY(toppos/3)

    self.bagiconbg_Y = self.rootItems.bagiconbg:getPositionY()
    self.toppos = toppos

    -- self.rootItems.listEquip:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.labelnodeheight-60))
    -- self.rootItems.listTreasure:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.labelnodeheight-60))
    -- self.rootItems.listFragment:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.labelnodeheight))
    -- self.rootItems.listProp:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.labelnodeheight))

    -- 添加虞姬角色
    self.rootItems["generalNode"]:removeAllChildrenWithCleanup(true)
    local name = "yuji"
    local Gneral1 = CCSkeletonAnimation:create(name .."/" .. name .. ".json", name .."/" .. name .. ".atlas",1)
    Gneral1:setAnimation("stand",true,0)
    Gneral1:setScale(2)
    Gneral1:setPosition(0,0)
    self.rootItems["generalNode"]:addChild(Gneral1)

    --
    if gameConfig:checkBuildOpen(257) then
        self.recoveryOpen = true
    end
    --

    self.slotDataTem = GameScene.layers["slotsInfo"].module.slotdata
    for k,v in pairs(self.slotDataTem) do
        if v and v.general and v.general.iid and v.general.iid == GameScene.protagonist.iid then
            self.protagonistPosition = v.sid
        end
    end

    for k,v in ipairs(self.equiptypeconfig) do
        self.rootItems[v.."Button"]:setSwallowsTouch(true)
        self.rootItems[v.."Button"]:setTouchPriority(-105)
        self.rootItems[v.."Button"]:addHandleOfControlEvent(function()
             self:shiftEquipPage(v)
        end, CCControlEventTouchUpInside)
    end

    for k,v in ipairs(self.treasuretypeconfig) do
        self.rootItems[v.."Button"]:setSwallowsTouch(true)
        self.rootItems[v.."Button"]:setTouchPriority(-105)
        self.rootItems[v.."Button"]:addHandleOfControlEvent(function()
            self:shiftTreasurePage(v)
        end, CCControlEventTouchUpInside)
    end

    for k,v in ipairs(self.fragmenttypeconfig) do
        self.rootItems["fragment"..v.."Button"]:setSwallowsTouch(true)
        self.rootItems["fragment"..v.."Button"]:setTouchPriority(-105)
        self.rootItems["fragment"..v.."Button"]:addHandleOfControlEvent(function()
            self:shiftFragmentPage(v)
        end, CCControlEventTouchUpInside)
    end

    for k,v in ipairs(self.proptypeconfig) do
        self.rootItems[v.."Button"]:setSwallowsTouch(true)
        self.rootItems[v.."Button"]:setTouchPriority(-105)
        self.rootItems[v.."Button"]:addHandleOfControlEvent(function()
            self:showProps(v)
        end, CCControlEventTouchUpInside)
    end

    if param then
        if param.selectpage then
            self.selectpage = param.selectpage
        end
        if param.equipselectpage then
            self.equipselectpage = param.equipselectpage
        end
        if param.treasureselectpage then
            self.treasureselectpage = param.treasureselectpage
        end
        if param.propselectpage then
            self.propselectpage = param.propselectpage
        end
    end

    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","equipsList",touchbegin)
    local function touchend(pos)
        if self.rootItems.listEquip and ui.isTouched(self.rootItems.listEquip,pos.x,pos.y) then
            self.isscrolltouched = true
        end
        if self.rootItems.listTreasure and ui.isTouched(self.rootItems.listTreasure,pos.x,pos.y) then
            self.isscrolltouched = true
        end
        if self.rootItems.listFragment and ui.isTouched(self.rootItems.listFragment,pos.x,pos.y) then
            self.isscrolltouched = true
        end
        if self.rootItems.listProp and ui.isTouched(self.rootItems.listProp,pos.x,pos.y) then
            self.isscrolltouched = true
        end                
    end
    gameTouch:rigistFunc("end","equipsList",touchend)
    -- UIRequest({type =5901})

    self:shiftPage(self.selectpage)

end

function equipsList.clear(self)
    self.recoveryOpen = false

    gameTouch:UnrigistFunc("begin","equipsList")
    gameTouch:UnrigistFunc("end","equipsList")   


    for k,v in pairs(self.rigistTime) do
        if gameTimer.times[k] then
            gameTimer:UnrigistTimeFunc(k)
        end
    end
    self.rigistTime = {}

    self.isscrolltouched = false
    self.rootItems = nil
    self.equipListTableView = nil
    self.treasureListTableView = nil
    self.fragmentListTableView = nil
    self.propsListTableView = nil

    self.selectpage = "props"
    self.equipselectpage = "equips"
    self.treasureselectpage = "treasures"
    self.fragmentselectpage = "equip"

    self.slotDataTem = {}
    self.protagonistPosition = 1

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function equipsList.setone(self,data,items,index,selectpage)

    local key_Ex
    local id = index-1
    if id == nil or id == 0 then
        key_Ex = ""
    else
        key_Ex = "_"..id
    end

    if self.selectpage == "props" then
        ui.setPropIcon(items, {cid = data.cid, num = data.num}, index-1)
    elseif self.selectpage == "equip" then
        ui.setPropIcon(items, {cid = data.cid, num = data.num}, index-1, data)
        local configdata =  gamedata.config.equip[tostring(data.cid)]
        -- 装备可能有进阶后的属性
        if configdata.quality and configdata.quality >= 7 then
            ui.setLabelString(items["i_name"..key_Ex],ui.getEquipStageName(data) or "", 213)
        else
            ui.setLabelString(items["i_name"..key_Ex],ui.getEquipStageName(data) or "", configdata.quality and 2*configdata.quality-1 or 1)
        end
    elseif self.selectpage == "treasure" then
        ui.setPropIcon(items, {cid = data.cid, num = data.num}, index-1, data)
        local configdata =  gamedata.config.equip[tostring(data.cid)]
        if configdata.quality and configdata.quality >= 7 then
            ui.setLabelString(items["i_name"..key_Ex],configdata.name..(data.level2>0 and "+"..data.level2 or ""), 213)
        else
            ui.setLabelString(items["i_name"..key_Ex],configdata.name..(data.level2>0 and "+"..data.level2 or ""), configdata.quality and 2*configdata.quality-1 or 1)
        end
    elseif self.selectpage == "fragment" then
        ui.setPropIcon(items, {cid = data.cid}, index-1)
        local configdata = ui.IDconfig(data.cid)
        -- printT(configdata,"configdata")
        if configdata.staffType == "equip_fragment" then
            if items["barNode"..key_Ex] then
                items["barNode"..key_Ex]:setVisible(true)
                ui.setLabelString(items["barLabel"..key_Ex], data.num.."/"..configdata.num, 14)
                ui.setSpriteTextureRect2(items["bar_bright"..key_Ex],0,0,154*(data.num < configdata.num and data.num/configdata.num or 1),30)
            end
        elseif configdata.staffType == "treasure_fragment" then
            if items["i_num"..key_Ex] then
                if not data.num or data.num == "" then
                    items["i_num"..key_Ex]:setString("")
                else
                    items["i_num"..key_Ex]:setString(data.num and data.num or "")
                end
                ui.setLabelString(items["i_num"..key_Ex], nil, 13)
            end
            if items["barNode"..key_Ex] then
                items["barNode"..key_Ex]:setVisible(false)
            end
        end
    end 

    items["i_button"..key_Ex]:setTouchPriority(-104)
    -- items["i_button"..key_Ex]:setSwallowsTouch(true)
    items["i_button"..key_Ex]:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        -- pageconfig = {"props","equip","treasure","fragment"}
        if self.selectpage == "props" then
            ui.setPopwindowByCid(data.cid, {data = data, propsData = self.propsData})
        elseif self.selectpage == "equip" then
            local generalsidTem = 1
            local generalSid = 1
            for k,v in pairs(self.slotDataTem) do
                if data.generalcid and v.general and data.generalcid == v.general.cid then
                    generalsidTem = v.sid
                    break
                end
            end
            if GameScene.protagonist.general and (data.generalcid == GameScene.protagonist.general.cid) then
                generalSid = 1
            elseif generalsidTem < self.protagonistPosition then
                generalSid = generalsidTem + 1
            else
                generalSid = generalsidTem
            end
            gameWindows:openWindow("equipInfo",{equip = data, sid = generalSid, pagetype = "info",index = generalSid})
        elseif self.selectpage == "treasure" then
            gameWindows:openWindow("equipInfo",{equip = data, opt = 1, pagetype = "info"})
        else
            ui.setPopwindowByCid(data.cid, data)
        end
        -- 
    end, CCControlEventTouchUpInside)
end

function equipsList.setEquip(self,item,data)
    -- print("setEquipNormal")
    -- printT(data)
    -- ui.setIconLv(item,data)
    -- 装备升星星级展示
    ui.setIconLv(item,data,nil,data)
    -- 装备升星属性提升展示
    ui.setEquipStarPropertyshow(item,data)

    local configdata =  gamedata.config.equip[tostring(data.cid)]

    if data.type ~= "horse" and data.type ~= "treasure" then
        -- 装备可能有进阶后的属性
        if configdata.quality >= 7 then
            ui.setLabelString(item.name,ui.getEquipStageName(data) or "", 213)
        else
            ui.setLabelString(item.name,ui.getEquipStageName(data) or "", configdata.quality and 2*configdata.quality-1 or 1)
        end
    else
        if configdata.quality >= 7 then
            ui.setLabelString(item.name,configdata.name..(data.level2>0 and "+"..data.level2 or ""), 213)
        else
            ui.setLabelString(item.name,configdata.name..(data.level2>0 and "+"..data.level2 or ""), configdata.quality and 2*configdata.quality-1 or 1)
        end
    end
    
    local generalsidTem = 1
    local generalSid = 1

    for k,v in pairs(self.slotDataTem) do
        if data.generalcid and v.general and data.generalcid == v.general.cid then
            generalsidTem = v.sid
            break
        end
    end


    if data.generalcid and data.generalcid > 0 then
        -- if gamedata.config.general[tostring(data.generalcid)].name == "主角" then
        if gamedata.config.general[tostring(data.generalcid)].name == gameConfig.strings:string_common("equips",5) then
            -- item.generalname:setString("装备于: "..GameScene.roleinfo.name)
            item.generalname:setString(gameConfig.strings:equipName(GameScene.roleinfo.name))
        else
            -- item.generalname:setString("装备于: "..gamedata.config.general[tostring(data.generalcid)].name)
            item.generalname:setString(gameConfig.strings:equipName(gamedata.config.general[tostring(data.generalcid)].name))
        end
        item.notOn:setVisible(false)

        if GameScene.protagonist.general and (data.generalcid == GameScene.protagonist.general.cid) then
            generalSid = 1
        elseif generalsidTem < self.protagonistPosition then
            generalSid = generalsidTem + 1
        else
           generalSid = generalsidTem
        end


    else
        item.generalname:setString("")
        item.notOn:setVisible(true)
    end

    ui.setEquipPromote(item["att1"],item["att2"],data,item["att3"])

    item.il_button:setSwallowsTouch(true)
    item.il_button:setTouchPriority(-104)
    item.il_button:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        print("iconButton clicked")
        gameWindows:openWindow("equipInfo",{equip = data, opt = 1, pagetype = "info"})

    end, CCControlEventTouchUpInside)


    if configdata.type == "horse" or configdata.type == "treasure" then
        ui.setLabelString(item.buttontext1,"精炼",18)
        if not GameScene:checkopenlevelbyId(137,true) then
            ui.addGray("CCControlButton",item.button1)
        else
            ui.removeGray("CCControlButton",item.button1)
        end
    else
        ui.removeGray("CCControlButton",item.button1)
        ui.removeGray("CCLabelTTF",item.buttontext1)
        if not GameScene:checkopenlevelbyId(53,true) then
            ui.addGray("CCControlButton",item.button1)
            ui.addGray("CCLabelTTF",item.buttontext1)
        end
        ui.setLabelString(item.buttontext1,"洗炼",18)
        if configdata.quality < 3 then
            ui.addGray("CCControlButton",item.button1)
            ui.addGray("CCLabelTTF",item.buttontext1)
        end

        if not (data.generalcid and data.generalcid > 0) then
            ui.addGray("CCControlButton",item.button1)
            ui.addGray("CCLabelTTF",item.buttontext1)
        end
    end
    --ui.setLabelString(item.buttontext1,gameConfig.strings:string_common("equips",6),18)
    item.button1:setSwallowsTouch(true)
    item.button1:setTouchPriority(-102)
    item.button1:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end

        if not (data.generalcid and data.generalcid > 0) then
            runGamePrompt({msg = "未穿戴的装备无法进行操作"})
            return
        end
        gameTouch:clickprofbytime(0.5)
        print("refineButton clicked")

        if configdata.type == "horse" or configdata.type == "treasure" then
            if not GameScene:checkopenlevelbyId(137) then return end
            --gameWindows:openWindow("equipInfo",{equip = data, opt = 1, pagetype = "refine"})
            GameScene:shiftLayer("treasureup","up",{page = "refine",data = data,})
        else
            if not GameScene:checkopenlevelbyId(53) then return end
            if configdata.quality < 3 then
                runGamePrompt({msg = "该装备无法洗炼"})
            else
                -- gameWindows:openWindow("equipInfo",{equip = data, opt = 1, pagetype = "xilian"})
                --GameScene:shiftLayer("equipsup","up",{page = "xilian",data = data,sid = self.sid or 1})
                GameScene:shiftLayer("equipsup","up",{page = "xilian",data = data,sid = generalSid or 1})
            end
        end
    end, CCControlEventTouchUpInside)

    if configdata.type == "horse" or configdata.type == "treasure" then
        --ui.setLabelString(item.buttontext2,"升华",18)
        ui.setLabelString(item.buttontext2,gameConfig.strings:string_common("equips",8),18)
        ui.removeGray("CCControlButton",item.button2)
        ui.removeGray("CCLabelTTF",item.buttontext2)
    else
        -- ui.setLabelString(item.buttontext2,"强化",18)
        ui.setLabelString(item.buttontext2,gameConfig.strings:string_common("equips",8),18)
        ui.removeGray("CCControlButton",item.button2)
        ui.removeGray("CCLabelTTF",item.buttontext2)

        if not (data.generalcid and data.generalcid > 0) then
            ui.addGray("CCControlButton",item.button2)
            ui.addGray("CCLabelTTF",item.buttontext2)
        end

    end
    item.button2:setSwallowsTouch(true)
    item.button2:setTouchPriority(-102)
    item.button2:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        if not (data.generalcid and data.generalcid > 0) then
            runGamePrompt({msg = "未穿戴的装备无法进行操作"})
            return
        end
        gameTouch:clickprofbytime(0.5)
        print("strengthenButton clicked")
        if configdata.type == "horse" or configdata.type == "treasure" then
            --gameWindows:openWindow("equipInfo",{equip = data, opt = 1, pagetype = "treasureRefine"})
            --runGamePrompt({msg = gameConfig.strings:string_common("moreCommon","gongneng2")})
            GameScene:shiftLayer("treasureup","up",{page = "up",data = data,})
        else
            -- gameWindows:openWindow("equipInfo",{equip = data, opt = 1, pagetype = "up"})
            --GameScene:shiftLayer("equipsup","up",{page = "up",data = data,sid = self.sid or 1})
            GameScene:shiftLayer("equipsup","up",{page = "up",data = data,sid = generalSid or 1})
        end
    end, CCControlEventTouchUpInside)

    print("setEquipNormal__end")
end

function equipsList.createEquipsList(self)
    local celldict = {}
    local equipsListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.CellSize.x, self.CellSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("equip_new/cell_prop_icon", nil, true, "cell_equip")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.equipListTableView,cellCCB,self.CellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            -- self:setEquip(ccbDocumentControler,self.equipshowData[a1+1] or self.equipshowData[tostring(a1+1)])
            for i=4,0,-1 do
                if self.equipshowData[(a1+1)*5-i] or self.equipshowData[tostring((a1+1)*5-i)] then
                    self:setone(self.equipshowData[(a1+1)*5-i] or self.equipshowData[tostring((a1+1)*5-i)],ccbDocumentControler,5-i,self.selectpage)
                    ccbDocumentControler["cell_icon"..(5-i)]:setVisible(true)
                else
                    ccbDocumentControler["cell_icon"..(5-i)]:setVisible(false)
                end
            end

            if self.equipListTableView then
                cellCCB:setPosition(self.CellSize.x/2, 0)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            -- r = table.getTableLength(self.equipshowData)
            r = math.ceil(table.getTableLength(self.equipshowData)/5)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.equipListTableView = ui.createLuaTableView({
        handle = equipsListHandle,
        viewwidth = self.rootItems.listEquip:getContentSize().width,
        viewheight = self.rootItems.listEquip:getContentSize().height,
        dire = 1
    })
    self.rootItems.listEquip:addChild(self.equipListTableView)
    self.equipListTableView:setTouchPriority(-101)
end


function equipsList.createTreasureList(self)
    local celldict = {}
    local treasureListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.CellSize.x, self.CellSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("equip_new/cell_prop_icon", nil, true, "cell_equip")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.treasureListTableView,cellCCB,self.CellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            -- self:setEquip(ccbDocumentControler,self.treasureshowData[tostring(a1+1)])
            for i=4,0,-1 do
                if self.treasureshowData[(a1+1)*5-i] or self.treasureshowData[tostring((a1+1)*5-i)] then
                    self:setone(self.treasureshowData[(a1+1)*5-i] or self.treasureshowData[tostring((a1+1)*5-i)],ccbDocumentControler,5-i,self.selectpage)
                    ccbDocumentControler["cell_icon"..(5-i)]:setVisible(true)
                else
                    ccbDocumentControler["cell_icon"..(5-i)]:setVisible(false)
                end
            end

            if self.treasureListTableView then
                cellCCB:setPosition(self.CellSize.x/2, 0)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            -- r = table.getTableLength(self.treasureshowData)
            r = math.ceil(table.getTableLength(self.treasureshowData)/5)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.treasureListTableView = ui.createLuaTableView({
        handle = treasureListHandle,
        viewwidth = self.rootItems.listTreasure:getContentSize().width,
        viewheight = self.rootItems.listTreasure:getContentSize().height,
        dire = 1
    })
    self.rootItems.listTreasure:addChild(self.treasureListTableView)
    self.treasureListTableView:setTouchPriority(-101)
end


function equipsList.setFragment(self,item,data)
    print("setFragment") 
    local configdata = ui.IDconfig(data.cid)

    ui.setIconLv(item,data)
    if configdata.quality >= 7 then
        ui.setLabelString(item.name,configdata.name, 213)
    else
        ui.setLabelString(item.name,configdata.name, configdata.quality and 2*configdata.quality-1 or 1)
    end

    item.button:setSwallowsTouch(true)
    item.button:setTouchPriority(-102)
    if configdata.staffType == "equip_fragment"  then
        ui.setLabelString(item.num, data.num.."/"..configdata.num, 14)
        item.desc:setString(gameConfig.strings:collectSuit(configdata.num,gameConfig.strings.quality[configdata.quality],gameConfig.strings.equipType[configdata.type],gamedata.config.equip[tostring(configdata.equip)].name))

        ui.setLabelString(item.buttontext,gameConfig.strings:string_common("buttontext","hecheng"),18)

        if data.num < configdata.num then
            if gamedata.config.drop and gamedata.config.drop[tostring(data.cid)] then
                -- ui.setLabelString(item.buttontext,"去获取",18)
                ui.setLabelString(item.buttontext,gameConfig.strings:string_common("moreCommon",18),18)
                ui.removeGray("CCLabelTTF",item.buttontext)
                ui.removeGray("CCControlButton",item.button)
                setControlButtonFrame(item.button,"b_s_button1","b_s_button1_h","b_s_button1")
                item.button:addHandleOfControlEvent(function()
                    if not self.isscrolltouched then return end
                    if gameTouch.isScrollling then return end
                    gameWindows:openWindow("dropTips",{cid =data.cid, num = data.num, },nil)
                end, CCControlEventTouchUpInside)
            else
                setControlButtonFrame(item.button,"b_s_button2","b_s_button2_h","b_s_button2")
                ui.addGray("CCLabelTTF",item.buttontext)
                ui.addGray("CCControlButton",item.button)
                item.button:addHandleOfControlEvent(function()
                    if not self.isscrolltouched then return end
                    if gameTouch.isScrollling then return end
                    gameTouch:clickprofbytime(0.5)
                    -- runGamePrompt({msg = "碎片不足"})
                    runGamePrompt({msg = gameConfig.strings:string_common("equips",9)})
                end, CCControlEventTouchUpInside)
            end
        else
            setControlButtonFrame(item.button,"b_s_button2","b_s_button2_h","b_s_button2")
            ui.removeGray("CCLabelTTF",item.buttontext)
            ui.removeGray("CCControlButton",item.button)
            item.button:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                if gameTouch.isScrollling then return end
                gameTouch:clickprofbytime(0.5)

                local total = math.floor(data.num/configdata.num)

                local cb = function(usenum)
                    UIRequest({type = 1108, ids = {configdata.equip,usenum}})
                end
                if total>1 then
                    gameWindows:openWindow("equipbynum",{id = data.cid,total=total},cb)
                else
                    cb(total)
                end
                gamedata.music:PlayOptSound("hc")
            end, CCControlEventTouchUpInside)
        end
    elseif configdata.staffType == "treasure_fragment"  then
        ui.setLabelString(item.num, data.num, 14)
        item.desc:setString(gameConfig.strings:collectTrs(gameConfig.strings.fragmentnum[configdata.num],gameConfig.strings.quality[configdata.quality],gamedata.config.equip[tostring(configdata.equip)].name))

        ui.setLabelString(item.buttontext,gameConfig.strings:string_common("equips",10),18)
        ui.removeGray("CCLabelTTF",item.buttontext)
        ui.removeGray("CCControlButton",item.button)
        setControlButtonFrame(item.button,"b_s_button1","b_s_button1_h","b_s_button1")
        item.button:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            gameTouch:clickprofbytime(0.5)
            --todo 去抢夺
            GameScene:shiftLayer("rob","up",{page = configdata.type, cid = configdata.id})
        end, CCControlEventTouchUpInside)
    elseif configdata.staffType == "meterial_fragment"  then

        local type = "horse"
        if configdata.equip >= 20039 and configdata.equip >= 20041 then
            type = "treasure"
        end
        item.desc:setString(gameConfig.strings:collectMes(gameConfig.strings.fragmentnum[configdata.num],gameConfig.strings.equipType[type],gamedata.config.props[tostring(configdata.equip)].name))
        ui.setLabelString(item.num, data.num, 14)
        ui.setLabelString(item.buttontext,gameConfig.strings:string_common("equips",10),18)
        ui.removeGray("CCLabelTTF",item.buttontext)
        ui.removeGray("CCControlButton",item.button)
        setControlButtonFrame(item.button,"b_s_button1","b_s_button1_h","b_s_button1")
        item.button:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            gameTouch:clickprofbytime(0.5)
            --todo 去抢夺
            GameScene:shiftLayer("rob","up",{page = configdata.type, cid = configdata.id})
        end, CCControlEventTouchUpInside)
    end

    item.il_button:setTouchPriority(-102)
    item.il_button:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        print("iconButton clicked")
        ui.setPopwindowByCid(data.cid)
    end, CCControlEventTouchUpInside)

end

function equipsList.createFragmentList(self)
    local celldict = {}
    local unrecycleCell = {}
    local fragmentListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.CellSize.x, self.CellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("equip_new/cell_prop_icon", nil, true, "cell_fragment")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.fragmentListTableView,cellCCB,self.CellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            -- self:setFragment(ccbDocumentControler,self.fragmentShowData[tostring(a1+1)])
            for i=4,0,-1 do
                if self.fragmentShowData[(a1+1)*5-i] or self.fragmentShowData[tostring((a1+1)*5-i)] then
                    self:setone(self.fragmentShowData[(a1+1)*5-i] or self.fragmentShowData[tostring((a1+1)*5-i)],ccbDocumentControler,5-i,self.selectpage)
                    ccbDocumentControler["cell_icon"..(5-i)]:setVisible(true)
                else
                    ccbDocumentControler["cell_icon"..(5-i)]:setVisible(false)
                end
            end

            if self.fragmentListTableView then
                cellCCB:setPosition(self.CellSize.x/2, 0)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            -- r = table.getTableLength(self.fragmentShowData)
            r = math.ceil(table.getTableLength(self.fragmentShowData)/5)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.fragmentListTableView = ui.createLuaTableView({
        handle = fragmentListHandle,
        viewwidth = self.rootItems.listFragment:getContentSize().width,
        viewheight = self.rootItems.listFragment:getContentSize().height,
        dire = 1
    })
    self.rootItems.listFragment:addChild(self.fragmentListTableView)
    self.fragmentListTableView:setTouchPriority(-101)
end

function equipsList.createPropsList(self)
    local celldict = {}
    local propsListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.CellSize.x, self.CellSize.y)

        elseif fn == "isRecycle" then
            if celldict[a2] then
                if celldict[a2].index and self.propShowData[celldict[a2].index] and self.propShowData[celldict[a2].index].iid and self.propShowData[celldict[a2].index].iid > 0 then
                    if gameTimer.times["limitProp_"..self.propShowData[celldict[a2].index].iid] then
                        gameTimer:UnrigistTimeFunc("limitProp_"..self.propShowData[celldict[a2].index].iid)
                    end
                end
            end
            return true
        elseif fn == "cellAtIndex" then
            self.ccbDocument[tostring(a1+1)] = {}
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                -- cellCCB, ccbDocumentControler = CCBReaderLoad("equip_new/cell_prop", nil, true, "cell_prop")
                -- celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler,index = a1+1 }
                --ui.tableviewAnimation(self.propsListTableView,cellCCB,self.CellSize.x/2, 0,a1)
                self.ccbDocument[tostring(a1+1)].cellCCB, self.ccbDocument[tostring(a1+1)].ccbDocumentControler = CCBReaderLoad("equip_new/cell_prop_icon", nil, true, "cell_prop")
                celldict[a2] = {cellCCB=self.ccbDocument[tostring(a1+1)].cellCCB,ccbDocumentControler=self.ccbDocument[tostring(a1+1)].ccbDocumentControler,index = a1+1 }
                ui.tableviewAnimation(self.propsListTableView,self.ccbDocument[tostring(a1+1)].cellCCB,self.CellSize.x/2, 0,a1)
            else
                first = false
                -- cellCCB = celldict[a2].cellCCB
                -- ccbDocumentControler = celldict[a2].ccbDocumentControler
                self.ccbDocument[tostring(a1+1)].cellCCB = celldict[a2].cellCCB
                self.ccbDocument[tostring(a1+1)].ccbDocumentControler = celldict[a2].ccbDocumentControler

            end

            -- self:setProps(ccbDocumentControler,self.propsData[a1+1])
            for i=4,0,-1 do
                if self.propShowData[(a1+1)*5-i] or self.propShowData[tostring((a1+1)*5-i)] then
                    self:setone(self.propShowData[(a1+1)*5-i] or self.propShowData[tostring((a1+1)*5-i)],self.ccbDocument[tostring(a1+1)].ccbDocumentControler,5-i,self.selectpage)
                    self.ccbDocument[tostring(a1+1)].ccbDocumentControler["cell_icon"..(5-i)]:setVisible(true)
                else
                    self.ccbDocument[tostring(a1+1)].ccbDocumentControler["cell_icon"..(5-i)]:setVisible(false)
                end
            end
            -- self:setProps(self.ccbDocument[tostring(a1+1)].ccbDocumentControler,self.propShowData[a1+1])

            if self.propsListTableView then
                --cellCCB:setPosition(self.CellSize.x/2, 0)
                self.ccbDocument[tostring(a1+1)].cellCCB:setPosition(self.CellSize.x/2, 0)
            end

            if first then
                --a2:addChild(cellCCB)
                a2:addChild(self.ccbDocument[tostring(a1+1)].cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            -- r = table.getTableLength(self.propShowData)
            r = math.ceil(table.getTableLength(self.propShowData)/5)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.propsListTableView = ui.createLuaTableView({
        handle = propsListHandle,
        viewwidth = self.rootItems.listProp:getContentSize().width,
        viewheight = self.rootItems.listProp:getContentSize().height,
        dire = 1
    })
    self.rootItems.listProp:addChild(self.propsListTableView)
    self.propsListTableView:setTouchPriority(-101)
end


function equipsList.setProps(self,item,data)
    print("setProps")
   
    local configdata = ui.IDconfig(data.cid)
    ui.setLabelString(item.num, data.num or 1, 14)

    ui.setIconLv(item,{cid = data.cid})
    ui.setLabelString(item.name,configdata.name, configdata.quality~=0 and 2*configdata.quality-1 or 1)

    item.desc:setString(configdata.desc)

    --limitTime
    if data.proptype and data.proptype == 1 then
        if item.limitTime then
            if gameTimer.times["limitProp_"..data.iid] and gameTimer.times["limitProp_"..data.iid] > 0 then
                --倒计时
                self.rigistTime["limitProp_"..data.iid] = 1
                gameTimer:rigistTimeFunc("limitProp_"..data.iid,function()
                    if gameTimer.times["limitProp_"..data.iid] > 0 then
                        item.limitTime:setString(ui.makeTimeText(gameTimer.times["limitProp_"..data.iid],"hour").."后开启")
                        --ui.setLabelString(self.ccbDocument[tostring(index)].ccbDocumentControler.freshtime,gameConfig.strings:string_common("shop_list",7)..ui.makeTimeText(gameTimer.times["newShoplimitTime"..data.id],"hour"),137)
                    end
                    if gameTimer.times["limitProp_"..data.iid] == 0 then
                        item.limitTime:setString("")
                        -- UIRequest({type = 5901})
                        gameTimer:UnrigistTimeFunc("limitProp_"..data.iid)
                    end
                end)
                --按钮
                ui.addGray("CCControlButton",item.button)
                ui.addGray("CCLabelTTF",item.buttontext)

            else
                --倒计时
                item.limitTime:setString("")
                --按钮
                ui.removeGray("CCControlButton",item.button)
                ui.removeGray("CCLabelTTF",item.buttontext)
            end

        end

    else
        if item.limitTime then
            item.limitTime:setString("")
        end
        ui.removeGray("CCControlButton",item.button)
        ui.removeGray("CCLabelTTF",item.buttontext)
    end


    item.il_button:setTouchPriority(-102)
    item.il_button:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        print("iconButton clicked")
        --printT(data)
        gameWindows:openWindow("propInfo", {prop = data, pagetype = "info"})
    end, CCControlEventTouchUpInside)
    
    item.button:setSwallowsTouch(true)
    item.button:setTouchPriority(-102)

    if configdata.type == "keybox" then
        item.doNode:setVisible(true)

        local realnum = math.min(self:findkeynum(configdata),data.num)
        if realnum <= 0 then
            -- ui.setLabelString(item.buttontext,"无钥匙",18)
            ui.setLabelString(item.buttontext,gameConfig.strings:string_common("equips",11),18)
            item.button:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                if gameTouch.isScrollling then return end
                -- runGamePrompt({msg = "无对应的钥匙"})
                -- runGamePrompt({msg = gameConfig.strings:string_common("equips",12)})
                -- local cb = function()
                --     GameScene:shiftLayerById(41) --跳转到道具商城
                -- end
                -- gameWindows:openWindow("confirm",{msg = gameConfig.strings:string_common("equips",19)},cb)
                --随身商店
                UIRequest({type=3200, mobileShopId=5})
            end, CCControlEventTouchUpInside)
        elseif realnum ==1 then
            -- ui.setLabelString(item.buttontext,"打开",18)
            ui.setLabelString(item.buttontext,gameConfig.strings:string_common("equips",13),18)
            item.button:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                if gameTouch.isScrollling then return end
                gameTouch:clickprofbytime(0.5)
                UIRequest({type= 1201, cid =data.cid,num=1})
                gamedata.music:PlayOptSound("sydj")
            end, CCControlEventTouchUpInside)
        else
            ui.setLabelString(item.buttontext,gameConfig.strings:string_common("equips",13),18)
            item.button:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                if gameTouch.isScrollling then return end
                gameWindows:openWindow("propusebynum",{id = data.cid})
            end, CCControlEventTouchUpInside)
        end
    elseif configdata.type == "box101" then
        item.doNode:setVisible(true)
        
        ui.setLabelString(item.buttontext,gameConfig.strings:string_common("equips",13),18)
        item.button:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            if data.limitTime > 0 then
                runGamePrompt({msg = "当前时间点不能开启宝箱"})
            else
                gameTouch:clickprofbytime(0.5)
                UIRequest({type= 5902,iid = data.iid,cid =data.cid,num=1})
                gamedata.music:PlayOptSound("sydj")
            end
            
        end, CCControlEventTouchUpInside)

    elseif configdata.type == "box" then
        item.doNode:setVisible(true)
        -- ui.setLabelString(item.buttontext,"打开",18)
        ui.setLabelString(item.buttontext,gameConfig.strings:string_common("equips",13),18)
        item.button:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            if configdata["function"] and (configdata["function"] == "box3" or configdata["function"] == "box4" ) then
                gameWindows:openWindow("boxselect",{id = data.cid, num = data.num})
                -- local boxconfig = gamedata.config.props[tostring(data.cid)] or {}
                -- if boxconfig["function"] and boxconfig["function"] == "box4" then
                --     self.propcids = ui.getIDandNUMs(boxconfig.param1)
                -- else
                --     self.propcids = ui.getGeneralID(boxconfig.param1)
                -- end 
                -- local num = table.getTableLength(self.propcids)
                -- if num > 4 then
                --     gameWindows:openWindow("boxselect6",{id = data.cid, num = data.num})
                -- else
                --     gameWindows:openWindow("boxselect",{id = data.cid, num = data.num})
                -- end
            elseif data.num <=1 then
                gameTouch:clickprofbytime(0.5)
                UIRequest({type= 1201, cid =data.cid,num=1})
                gamedata.music:PlayOptSound("sydj")
            else
                gameWindows:openWindow("propusebynum",{id = data.cid})
            end
        end, CCControlEventTouchUpInside)
    elseif configdata.type == "vipbox" then
        item.doNode:setVisible(true)
        --ui.setLabelString(item.buttontext,"打开",18)
        ui.setLabelString(item.buttontext,gameConfig.strings:string_common("equips",13),18)
        item.button:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            gameTouch:clickprofbytime(0.5)
            UIRequest({type= 1201, cid =data.cid,num=1})
            gamedata.music:PlayOptSound("sydj")
        end, CCControlEventTouchUpInside)
    elseif configdata.type == "value" then
        item.doNode:setVisible(true)
        -- ui.setLabelString(item.buttontext,"使用",18)
        ui.setLabelString(item.buttontext,gameConfig.strings:string_common("equips",15),18)
        item.button:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            if data.num <=1 then
                gameTouch:clickprofbytime(0.5)
                UIRequest({type= 1201, cid =data.cid,num=1})
                gamedata.music:PlayOptSound("sydj")
            else
                gameWindows:openWindow("propusebynum",{id = data.cid})
            end
        end, CCControlEventTouchUpInside)
    elseif data.cid == 20018 then
        item.doNode:setVisible(true)
        -- ui.setLabelString(item.buttontext,"使用",18)
        ui.setLabelString(item.buttontext,gameConfig.strings:string_common("equips",15),18)
        item.button:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            gameTouch:clickprofbytime(0.5)
            -- gameWindows:openWindow("useropt",{type = "rename"},nil)
            UIRequest({type = 12001, order = 33092, cids = {data.cid}})


            gamedata.music:PlayOptSound("sydj")
        end, CCControlEventTouchUpInside)
    else
        item.doNode:setVisible(false)
    end

    --
    if item.recoveryButton then
        item.recoveryButton:setSwallowsTouch(true)
        item.recoveryButton:setTouchPriority(-102)
        if self.recoveryOpen and configdata.labal and configdata.labal == 1 then
            item.recoveryButton:setVisible(true)
            if data.num < configdata.props_num then
                ui.addGray("CCControlButton",item.recoveryButton)
                item.recoveryButton:addHandleOfControlEvent(function()
                    if not self.isscrolltouched then return end
                    if gameTouch.isScrollling then return end
                    gameTouch:clickprofbytime(0.5)
                    --
                    runGamePrompt({msg = gameConfig.strings:recovery_need_num(configdata.props_num)})
                    --
                    gamedata.music:PlayOptSound("sydj")
                end, CCControlEventTouchUpInside)
            else
                ui.removeGray("CCControlButton",item.recoveryButton)
                item.recoveryButton:addHandleOfControlEvent(function()
                    if not self.isscrolltouched then return end
                    if gameTouch.isScrollling then return end
                    gameTouch:clickprofbytime(0.5)
                    --
                    gameWindows:openWindow("propsRecovery",{cid = data.cid, num = data.num},nil)
                    --
                    gamedata.music:PlayOptSound("sydj")
                end, CCControlEventTouchUpInside)
            end
        else
            item.recoveryButton:setVisible(false)
        end
    end
end

function equipsList.findkeynum(self,boxconfig)
    --printT(boxconfig)
    local num = 0
    for k,v in pairs(self.propsData) do
        if tostring(v.cid) == boxconfig.param1 then

            num = v.num
            break
        end
    end

    --print(num)
    return num
end


function equipsList.setPage(self)
   self:shiftPage(self.selectpage)
end

function equipsList.UIUpdateData(self,isreset)
    self:setPage()
end

return equipsList
