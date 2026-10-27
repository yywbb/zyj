--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/30
-- Time: 下午3:12
-- To change this template use File | Settings | File Templates.
--


local select = {
    rootNode = nil,
    rootItems = nil,

    data = {},
    selectedData = {},
    ListTableView  = nil,
    type = nil,
}

function select.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("windows/select_list", nil, true, "select_list")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function select.reload(self,data,callback)
    self.callback = callback

    self.type = data.type
    -- self.rootItems.title:setString("选择"..self.typeConfig[data.type].title)
    self.rootItems.title:setString(gameConfig.strings:xzTitle(self.typeConfig[data.type].title))
    ui.setLabelString(self.rootItems.illusiondesc,"",13)
    if self.type == "illusion" then
        local illusionConfig = gamedata.config.illusion[tostring(data.param.cid)]
        local illusionGeneralConfig = gamedata.config.general[tostring(illusionConfig.general_id)]
        
        ui.setLabelString(self.rootItems.illusiondesc,gameConfig.strings:string_common("huanhua",5)..illusionGeneralConfig.name,13)
    end

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("selectlist")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)


    -- ui.setLabelString(self.rootItems.oklab,"确 定",18)
    ui.setLabelString(self.rootItems.oklab,gameConfig.strings:string_common("popups","queding"),18)
    self.rootItems.okButton:addHandleOfControlEvent(function()
        print("ok")
        gameTouch:clickprofbytime(0.5)
        if self.typeConfig[data.type].needconfirm then
            if not next(self.selectedData) then
                -- runGamePrompt({msg = "尚未选择"})
                runGamePrompt({msg = gameConfig.strings:string_common("popups","shangxz")})
            else
                local cb = function()
                    gameWindows:closeWindowDirect("selectlist")
                end
                -- gameWindows:openWindow("confirm",{msg = "是否确认操作？"},cb)
                gameWindows:openWindow("confirm",{msg = gameConfig.strings:string_common("popups","querencz")},cb)
            end
        else
            gameWindows:closeWindow("selectlist")
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.okButton:setSwallowsTouch(true)
    self.rootItems.okButton:setTouchPriority(self.touchPriority)

    UIRequest({type = 10029, param = self.type, param2 = data.param,param3 = data.param2,param4 = data.param3 or 0})
end

function select.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback(self.selectedData)
    end

    self.data = {}
    self.selectedData = {}
end

function select.setGeneral(item, data)
    printT(data,"jkp-data")
    -- 设置头像
    if data.illusionGeneralCid then
        local illusionGeneralConfig = gamedata.config.general[tostring(data.illusionGeneralCid)] 
        local gdata = ui.getConfigGeneralSion(data)
        local illusion_icon = illusionGeneralConfig.icon
        if next(gdata) and illusionGeneralConfig.fashion_id == 0 then
            illusion_icon = gdata.icon
        end 
        ui.setIconLv(item,{
            icon = illusion_icon,
            cid = data.illusion.cid,
            quality = illusionGeneralConfig.quality,
            level = data.level
        })
    else
        local configGeneral = gamedata.config.general[tostring(data.cid)]
        local gdata = ui.getConfigGeneral(data)
        data.icon = configGeneral.icon
        if next(gdata) and configGeneral.fashion_id == 0 then    
            data.icon = gdata.icon
        end
        ui.setIconLv(item,data)
    end
    
    if data.skilllevel and data.skilllevel > 0 and  gamedata.config.general[tostring(data.cid)].awaken > 0 then
        item.juexing_iocn:setVisible(true)
        item.juexing_stage:setVisible(true)
        item.name:setPositionX(367)
        setSpriteFrameByName(item.juexing_iocn,gamedata.config.general_awaken[tostring(data.skilllevel)].icon) 
        ui.setLabelString(item.juexing_stage,gamedata.config.general_awaken[tostring(data.skilllevel)].stage,18)
    else
        item.juexing_iocn:setVisible(false)
        item.juexing_stage:setVisible(false)
        item.name:setPositionX(299)
    end

    local configdata =  table.copy(gamedata.config.general[tostring(data.illusionGeneralCid or data.cid)])
    if configdata.quality and configdata.quality >= 7 then
        ui.setLabelString(item.name,configdata.name..(data.level2>0 and "+"..data.level2 or ""), 213)
    else
        ui.setLabelString(item.name,configdata.name..(data.level2>0 and "+"..data.level2 or ""), configdata.quality and 2*configdata.quality-1 or 1)
    end    

    if data.illusionGeneralCid then
        item.illusionDescLab:setVisible(true)
        local _generalConfig = gamedata.config.general[tostring(data.cid)]
        local _illusionGeneralConfig = gamedata.config.general[tostring(data.illusionGeneralCid)]

        local str = "("..string.format(gameConfig.strings:string_common("huanhua",6), _generalConfig.name)..")"
        if _illusionGeneralConfig.quality and _illusionGeneralConfig.quality >= 7 then
            ui.setLabelString(item.illusionDescLab,str, 213,29)
        else
            ui.setLabelString(item.illusionDescLab,str, _illusionGeneralConfig.quality and 2*_illusionGeneralConfig.quality-1 or 1,29)
        end

        item.illusionDescLab:setPositionX(item.name:getPositionX() + item.name:getContentSize().width + 3)
    else
        item.illusionDescLab:setVisible(false)
    end

    -- item.power:setString("战斗力: "..data.power)
    item.power:setString(gameConfig.strings:powerNum(data.power))
    setSpriteFrameByName(item["type"], gameConfig.images[configdata.actor])

    item.notice:setVisible(not not data.hasrelation)

    if data.hasrelation then
        -- local des = "可激活缘分"
        local des = gameConfig.strings:string_common("popups","activation")
        local first = true
        for k,v in pairs(data.hasrelation) do
            local destemp = des
            if first then
                des = destemp.."："..v
                first = false
            else
                des = destemp.."，"..v
            end
        end
        item.relation:setString(des)
    else
        item.relation:setString("")
    end

    if data.ison == 2 then
        setSpriteFrameByName(item["ison"], "obj_z_2")
    elseif data.ison == 1 then
        setSpriteFrameByName(item["ison"], "obj_z_1")
    else
        setSpriteFrameByName(item["ison"], "alpha")
    end

    if data.ison and data.ison >20 then
        if item["zhenrong_sp"] then
            local _zr = "godcompetition_"..(data.ison-20)
            print("封神赛 武将阵容:".._zr)
            setSpriteFrameByName(item["zhenrong_sp"],  _zr)
            item["zhenrong_sp"]:setVisible(true)
        end    
    else
        if item["zhenrong_sp"] then
            item["zhenrong_sp"]:setVisible(false)
        end   
    end        

end

function select.setEquip(item, data)

    -- ui.setIconLv(item,data)
    -- 装备升星星级展示
    ui.setIconLv(item,data,nil,data)
    -- 装备升星属性提升展示
    ui.setEquipStarPropertyshow(item,data)
    
    local configdata =  ui.IDconfig(tostring(data.cid))
    -- printT(configdata,"configdata====")
    if data.generalcid and data.generalcid > 0 then
        -- if gamedata.config.general[tostring(data.generalcid)].name == "主角" then
        --     item.generalname:setString("装备于: "..GameScene.roleinfo.name)
        -- else
        --     item.generalname:setString("装备于: "..gamedata.config.general[tostring(data.generalcid)].name)
        -- end
        if gamedata.config.general[tostring(data.generalcid)].name == gameConfig.strings:string_common("popups","zujue") then
            item.generalname:setString(gameConfig.strings:equipName(GameScene.roleinfo.name))
        else
            item.generalname:setString(gameConfig.strings:equipName(gamedata.config.general[tostring(data.generalcid)].name))
        end
        item.notOn:setVisible(false)
    else
        item.generalname:setString("")
        item.notOn:setVisible(true)
    end
    item.notice:setVisible(not not data.youyuan)

    if configdata.staffType == "soul" then
        if configdata.quality >= 7 then
            ui.setLabelString(item.name,configdata.name, 213)
        else
            ui.setLabelString(item.name,configdata.name, configdata.quality and 2*configdata.quality-1 or 1)
        end
        ui.setSoulPromote(item.att1,item.att2,data)
    else
        -- 进阶名字后缀修改
        if configdata.quality >= 7 then
            if configdata.type == "weapon" or configdata.type == "head" or configdata.type == "armor" or configdata.type == "accessory" then
                ui.setLabelString(item.name, ui.getEquipStageName(data), 213)
            else
                ui.setLabelString(item.name,configdata.name..(data.level2>0 and "+"..data.level2 or ""), 213)
            end
        else
            if configdata.type == "weapon" or configdata.type == "head" or configdata.type == "armor" or configdata.type == "accessory" then
                ui.setLabelString(item.name, ui.getEquipStageName(data), configdata.quality and 2*configdata.quality-1 or 1)
            else
                ui.setLabelString(item.name,configdata.name..(data.level2>0 and "+"..data.level2 or ""), configdata.quality and 2*configdata.quality-1 or 1)
            end
        end
        
        ui.setEquipPromote(item.att1,item.att2,data)
    end

end


function select.setIllusion(item, data)
    -- 设置头像
    local configGeneral = gamedata.config.general[tostring(data.cid)]
    local gdata = ui.getConfigGeneral(data)
    if next(gdata) and configGeneral.fashion_id == 0 then    
        data.icon = gdata.icon
    end
    ui.setIconLv(item,data)
    if data.skilllevel and data.skilllevel > 0 and  gamedata.config.general[tostring(data.cid)].awaken > 0 then
        item.juexing_iocn:setVisible(true)
        item.juexing_stage:setVisible(true)
        item.name:setPositionX(367)
        setSpriteFrameByName(item.juexing_iocn,gamedata.config.general_awaken[tostring(data.skilllevel)].icon) 
        ui.setLabelString(item.juexing_stage,gamedata.config.general_awaken[tostring(data.skilllevel)].stage,18)
    else
        item.juexing_iocn:setVisible(false)
        item.juexing_stage:setVisible(false)
        item.name:setPositionX(299)
    end
    local configdata =  gamedata.config.general[tostring(data.cid)]
    if configdata.quality and configdata.quality >= 7 then
        ui.setLabelString(item.name,configdata.name..(data.level2>0 and "+"..data.level2 or ""), 213)
    else
        ui.setLabelString(item.name,configdata.name..(data.level2>0 and "+"..data.level2 or ""), configdata.quality and 2*configdata.quality-1 or 1)
    end    

    item.power:setString(gameConfig.strings:powerNum(data.power))
    setSpriteFrameByName(item["type"], gameConfig.images[configdata.actor])

    item.relation:setString("")
    item.notice:setVisible(false)

    if data.ison == 2 then
        setSpriteFrameByName(item["ison"], "obj_z_2")
    elseif data.ison == 1 then
        setSpriteFrameByName(item["ison"], "obj_z_1")
    else
        setSpriteFrameByName(item["ison"], "alpha")
    end

    if data.illusionCond and data.illusionCond == 1 then
        item.illusiondesc:setString("("..gameConfig.strings:string_common("huanhua",11)..")")
    elseif data.illusionCond and data.illusionCond == 2 then
        item.illusiondesc:setString("("..gameConfig.strings:string_common("huanhua",2)..")")
    elseif data.illusionCond and data.illusionCond == 3 then
        item.illusiondesc:setString("("..gameConfig.strings:string_common("huanhua",12)..")")
    else
        item.illusiondesc:setString("")
    end

end

--[[
1 已存在幻化关系 不能幻化
2 不能幻化自身
3 上阵和助阵中不能出现相同的伙伴
]]

function select.checkIllusionCondition(data)
    
    if data.illusionCond and data.illusionCond == 1 then
        runGamePrompt({msg = gameConfig.strings:string_common("huanhua",3)})
        return true
    elseif data.illusionCond and data.illusionCond == 2 then
        runGamePrompt({msg = gameConfig.strings:string_common("huanhua",2)})
        return true
    elseif data.illusionCond and data.illusionCond == 3 then
        runGamePrompt({msg = gameConfig.strings:string_common("huanhua",4)})
        return true
    end
    return false
end

function select.reloadSelectList(self,datatable)

    self.data = datatable.data

    if table.getTableLength(self.data) == 0 then
        if self.typeConfig[self.type].gotoindex then
            ui.setGoto(self.rootItems.gotonode,true,self.typeConfig[self.type].gotoindex)
        else
        end
        return
    end


    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(960, 242)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad(self.typeConfig[self.type].ccb, nil, true, self.typeConfig[self.type].ccb)
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            if self.selectedData[tostring(a1+1)] then
                ccbDocumentControler.isSelect:setVisible(true)
            else
                ccbDocumentControler.isSelect:setVisible(false)
            end

            self.typeConfig[self.type].setFunc(ccbDocumentControler,self.data[tostring(a1+1)])

            ccbDocumentControler.il_button:setSwallowsTouch(true)
            ccbDocumentControler.il_button:setTouchPriority(self.touchPriority-1)
            ccbDocumentControler.il_button:addHandleOfControlEvent(function()
--                if self.data[tostring(a1+1)].cid and not self.typeConfig[self.type].nodetail then
--                    ui.setPopwindowByCid(self.data[tostring(a1+1)].cid)
--                end

            end, CCControlEventTouchUpInside)

            cellCCB:setPosition(960/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.data)
        elseif fn == "cellTouched" then
            if self.typeConfig[self.type].conditionFunc and self.typeConfig[self.type].conditionFunc(self.data[tostring(a1:getIdx()+1)]) then
                return
            end

            guide:setGuideProlayer(true)
            if self.selectedData[tostring(a1:getIdx()+1)] then
                self.selectedData[tostring(a1:getIdx()+1)] = nil
            else
                if self.typeConfig[self.type].maxNum == 1 then
                    self.selectedData = {}
                    self.selectedData[tostring(a1:getIdx()+1)] = self.data[tostring(a1:getIdx()+1)]
                elseif self.typeConfig[self.type].maxNum > 1 then
                    if table.getTableLength(self.selectedData) < self.typeConfig[self.type].maxNum then
                        self.selectedData[tostring(a1:getIdx()+1)] = self.data[tostring(a1:getIdx()+1)]
                    else
                        -- runGamePrompt({msg = "最多可选"..self.typeConfig[self.type].maxNum.."个"..self.typeConfig[self.type].title })
                        runGamePrompt({msg = gameConfig.strings:xzNumName(self.typeConfig[self.type].maxNum,self.typeConfig[self.type].title) })
                    end
                end
            end

            self.ListTableView:reloadData()
            if guide.controller then
                guide.controller:UIComplete(8031)
            end

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listscroll:getContentSize().width,
        viewheight = self.rootItems.listscroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.listscroll:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(self.touchPriority)
end

select.typeConfig = {
    change_weapon = {title = gameConfig.strings.equipType.weapon, maxNum = 1, setFunc = select.setEquip, ccb = "windows/cell_equipselect",gotoindex = "weapon"},
    change_armor = {title = gameConfig.strings.equipType.armor, maxNum = 1, setFunc = select.setEquip, ccb = "windows/cell_equipselect",gotoindex = "armor"},
    change_head = {title = gameConfig.strings.equipType.head, maxNum = 1, setFunc = select.setEquip, ccb = "windows/cell_equipselect",gotoindex = "head"},
    change_accessory = {title = gameConfig.strings.equipType.accessory, maxNum = 1, setFunc = select.setEquip, ccb = "windows/cell_equipselect",gotoindex = "accessory"},
    change_horse = {title = gameConfig.strings.equipType.horse, maxNum = 1, setFunc = select.setEquip, ccb = "windows/cell_equipselect",gotoindex = "horse"},
    change_treasure = {title = gameConfig.strings.equipType.treasure, maxNum = 1, setFunc = select.setEquip, ccb = "windows/cell_equipselect",gotoindex = "treasure"},
    -- inherit_selectgeneral = {title = "伙伴", maxNum = 1, setFunc = select.setGeneral, ccb = "windows/cell_generalselect",gotoindex = nil},
    -- changesoul = {title = "命格", maxNum = 1, setFunc = select.setEquip, ccb = "windows/cell_equipselect",gotoindex = "soul"},
    -- changegeneral = {title = "伙伴", maxNum = 1, setFunc = select.setGeneral, ccb = "windows/cell_generalselect",gotoindex = "general"},
    inherit_selectgeneral = {title = gameConfig.strings:string_common("popups","huoban"), maxNum = 1, setFunc = select.setGeneral, ccb = "windows/cell_generalselect",gotoindex = nil,nodetail = true},
    changesoul = {title = gameConfig.strings:string_common("popups","mingge"), maxNum = 1, setFunc = select.setEquip, ccb = "windows/cell_equipselect",gotoindex = "soul"},
    changegeneral = {title = gameConfig.strings:string_common("popups","huoban"), maxNum = 1, setFunc = select.setGeneral, ccb = "windows/cell_generalselect",gotoindex = "general"},
    change_weapon_all = {title = gameConfig.strings.equipType.weapon, maxNum = 1, setFunc = select.setEquip, ccb = "windows/cell_equipselect",gotoindex = "weapon"},
    change_armor_all = {title = gameConfig.strings.equipType.armor, maxNum = 1, setFunc = select.setEquip, ccb = "windows/cell_equipselect",gotoindex = "armor"},
    change_head_all = {title = gameConfig.strings.equipType.head, maxNum = 1, setFunc = select.setEquip, ccb = "windows/cell_equipselect",gotoindex = "head"},
    change_accessory_all = {title = gameConfig.strings.equipType.accessory, maxNum = 1, setFunc = select.setEquip, ccb = "windows/cell_equipselect",gotoindex = "accessory"},
    change_horse_all = {title = gameConfig.strings.equipType.horse, maxNum = 1, setFunc = select.setEquip, ccb = "windows/cell_equipselect",gotoindex = "horse"},
    change_treasure_all = {title = gameConfig.strings.equipType.treasure, maxNum = 1, setFunc = select.setEquip, ccb = "windows/cell_equipselect",gotoindex = "treasure"},
    change_equipstage_one = {title = gameConfig.strings.equipType.equip, maxNum = 1, setFunc = select.setEquip, ccb = "windows/cell_equipselect",gotoindex = "equipstage"},
    change_treasure_one = {title = gameConfig.strings.equipType.treasure, maxNum = 1, setFunc = select.setEquip, ccb = "windows/cell_equipselect",gotoindex = "treasure"},

    illusion = {title = gameConfig.strings:string_common("popups","huoban"), maxNum = 1, setFunc = select.setIllusion, ccb = "windows/cell_illusionselect",gotoindex = nil,conditionFunc = select.checkIllusionCondition},
    changegeneral_godcompetition = {title = gameConfig.strings:string_common("popups","huoban"), maxNum = 1, setFunc = select.setGeneral, ccb = "windows/cell_generalselect",gotoindex = "general"},

}

return select
