--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/12/17
-- Time: 15:52
-- To change this template use File | Settings | File Templates.
--



local qiankunluselect = {
    rootNode = nil,
    rootItems = nil,
    maxNum = 1,
    data = {
        general =  {name = "伙 伴", data = {}, ccb = "windows/cell_generalselect"},
        equip =    {name = "装 备", data = {}, ccb = "windows/cell_equipselect"},
        treasure = {name = "宝 物", data = {}, ccb = "windows/cell_equipselect"},
        fashion =  {name = "时 装", data = {}, ccb = "windows/cell_equipselect"},
        pet =      {name = "魔 宠", data = {}, ccb = "windows/cell_equipselect"},
        artifact = {name = "神 器", data = {}, ccb = "windows/cell_equipselect"},
        redfragment = {name = "精 华", data = {}, ccb = "windows/cell_generalselect"},
        exclusiveArtifact = {name = "专属神器",data = {}, ccb = "windows/cell_exclusiveselect"}
    },

    -- showdata = {},

    generalshowdata = {},
    equipshowdata = {},
    treasureshowdata = {},
    fashionshowdata = {},
    petshowdata = {},
    artifactshowdata = {},
    redfragmentshowdata = {},
    exclusiveArtifactshowdata = {},

    selectedData = {},
    generalListTableView  = nil,
    equipListTableView = nil,
    treasureListTableView  = nil,
    fashionListTableView = nil,
    petListTableView = nil,
    artifactListTableView = nil,
    redfragmentListTableView  = nil,
    exclusiveArtifactListTableView = nil,


    treasureIndex = 1,
    exceptdata = {},

    pageconfig = {"general","equip","treasure","fashion","pet","artifact","redfragment"},
    -- pageconfig = {"general","equip","treasure","fashion","pet","redfragment"},
    selectpage = "general",

    treasureConfig = {"horse","treasure"},

}

function qiankunluselect.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("qiankunlu/tc_qiankunlu", nil, true, "select_list")

    self.touchPriority = touchPriority
    self:reload(data,callback)


    self.rootItems["horseOnpoint"]:setVisible(self.treasureIndex == 1)
    self.rootItems["treasureOnpoint"]:setVisible(self.treasureIndex == 2)
    for i,v in ipairs(self.treasureConfig) do
        self.rootItems[v.."Button"]:addHandleOfControlEvent(function()
            self.treasureIndex = i
            self:shiftpage(self.selectpage)

            self.rootItems["horseOnpoint"]:setVisible(self.treasureIndex == 1)
            self.rootItems["treasureOnpoint"]:setVisible(self.treasureIndex == 2)

        end, CCControlEventTouchUpInside)
        self.rootItems[v.."Button"]:setSwallowsTouch(true)
        self.rootItems[v.."Button"]:setTouchPriority(self.touchPriority-2)
    end


    return self.rootNode
end


function qiankunluselect.shiftpage(self,page)

    if self.selectpage ~= page then
        self.selectedData = {}
    end

    self.selectpage = page
    for k,v in ipairs(self.pageconfig) do
        if self.rootItems["tabon"..k] then
            if v == page then
                setSpriteFrameByName(self.rootItems["tabon"..k], gameConfig.images.pageButtonON)
            else
                setSpriteFrameByName(self.rootItems["tabon"..k], gameConfig.images.pageButtonOFF)
            end
        end
    end

    if self.selectpage == "fashion" then
        for k,v in pairs(self.data[self.selectpage].data) do
            v.cid = v.id
        end
    end

    if self.selectpage == "treasure" then
        self[self.selectpage.."showdata"] = self.data[self.selectpage].data[self.treasureConfig[self.treasureIndex]]
    else
        self[self.selectpage.."showdata"] = self.data[self.selectpage].data
    end
    

    self.rootItems.listscrollgeneral:setPositionX(9999)
    self.rootItems.listscrolltreasure:setPositionX(9999)
    self.rootItems.listscrollequip:setPositionX(9999)
    self.rootItems.listscrollfashion:setPositionX(9999)
    self.rootItems.listscrollartifact:setPositionX(9999)
    self.rootItems.listscrollpet:setPositionX(9999)
    self.rootItems.listscrollredfragment:setPositionX(9999)
    self.rootItems.listscrollexclusiveartifact:setPositionX(9999)

    if self.selectpage == "general" then
        self.rootItems.listscrollgeneral:setPositionX(0)
        if not self.generalListTableView then
            self:createGeneralSelectList()
        else
            self.generalListTableView:reloadData()
            self.generalListTableView:setLuaContentOffset(0, self.rootItems.listscrollgeneral:getContentSize().height - table.getTableLength(self.generalshowdata)*230)
        end
    elseif self.selectpage == "equip" then
        self.rootItems.listscrollequip:setPositionX(0)
        if not self.equipListTableView then
            self:createEquipSelectList()
        else
            self.equipListTableView:reloadData()
            self.equipListTableView:setLuaContentOffset(0, self.rootItems.listscrollequip:getContentSize().height - table.getTableLength(self.equipshowdata)*230)
        end
    elseif self.selectpage == "treasure" then
        self.rootItems.listscrolltreasure:setPositionX(0)
        if not self.treasureListTableView then
            self:createTreasureSelectList()
        else
            self.treasureListTableView:reloadData()
            self.treasureListTableView:setLuaContentOffset(0, self.rootItems.listscrolltreasure:getContentSize().height - table.getTableLength(self.treasureshowdata)*230)
        end
    elseif self.selectpage == "pet" then
        self.rootItems.listscrollpet:setPositionX(0)    
        if not self.petListTableView then
            self:createPetSelectList()
        else
            self.petListTableView:reloadData()
            if self.rootItems.listscrollpet then
                self.petListTableView:setLuaContentOffset(0, self.rootItems.listscrollpet:getContentSize().height - table.getTableLength(self.petshowdata)*230)
            end
        end
    elseif  self.selectpage == "artifact" then
        self.rootItems.listscrollartifact:setPositionX(0)   
        if not self.artifactListTableView then
            printT(self.artifactshowdata,"  qiankunluselect ")
            self:createartifactSelectList()
        else
            self.artifactListTableView:reloadData()
            if self.rootItems.listscrollartifact then
                self.artifactListTableView:setLuaContentOffset(0, self.rootItems.listscrollartifact:getContentSize().height - table.getTableLength(self.artifactshowdata)*230)
            end
        end
    elseif self.selectpage == "exclusiveArtifact" then
        self.rootItems.listscrollexclusiveartifact:setPositionX(0)
        if not self.exclusiveArtifactListTableView then
            printT(self.exclusiveArtifactshowdata,"  qiankunluselect ")
            self:createExclusiveartifactSelectList()
        else
            self.exclusiveArtifactListTableView:reloadData()
            if self.rootItems.listscrollexclusiveartifact then
                self.exclusiveArtifactListTableView:setLuaContentOffset(0, self.rootItems.listscrollexclusiveartifact:getContentSize().height - table.getTableLength(self.exclusiveArtifactshowdata)*230)
            end
        end

    elseif self.selectpage == "redfragment" then
        self.rootItems.listscrollredfragment:setPositionX(0)
        if not self.redfragmentListTableView then
            self:createRedfragmentSelectList()
        else
            self.redfragmentListTableView:reloadData()
            self.redfragmentListTableView:setLuaContentOffset(0, self.rootItems.listscrollredfragment:getContentSize().height - table.getTableLength(self.redfragmentshowdata)*230)
        end
    else
        self.rootItems.listscrollfashion:setPositionX(0)
        if not self.fashionListTableView then
            self:createFashionSelectList()
        else
            self.fashionListTableView:reloadData()
            self.fashionListTableView:setLuaContentOffset(0, self.rootItems.listscrollfashion:getContentSize().height - table.getTableLength(self.fashionshowdata)*230)
        end
    end

    self:setSelectNum()
end

function qiankunluselect.setSelectNum(self)
    local num = 0
    if next(self.selectedData) then
        num = table.getTableLength(self.selectedData)
    end
    self.rootItems.select_num:setString(num.."/"..self.maxNum)
end

function qiankunluselect.reload(self,data,callback)
    self.callback = callback

    printT(data,"reloaddata===")
    -- 化魂时用于筛选
    if next(data.exceptdata) then
        self.exceptdata = data.exceptdata
    end
    self.page = data.page or {}
    

    if data.choose and next(data.choose) then
       for k,v in pairs(data.choose) do
            local temconfig = {}
            if v["cid"] then
                temconfig = ui.IDconfig(v["cid"])
            else
                temconfig = ui.IDconfig(v["id"])
            end

            self.selectedData[tostring((v.cid or "")..(v.iid or ""))] = v
            if (v.type and (v.type == "horse" or v.type == "treasure")) or (temconfig.staffType == "treasure_fragment") then
                self.selectpage = "treasure"
            elseif (v.type and (v.type == "head" or v.type == "weapon" or v.type == "accessory" or v.type == "armor" or v.type == "shoe" or v.type == "accessories")) or temconfig.staffType == "equip_fragment" then
                self.selectpage = "equip"
            elseif temconfig.staffType == "general" then
                self.selectpage = "general"
            elseif temconfig.staffType == "fashion" then
                self.selectpage = "fashion"
            elseif temconfig.staffType == "pet" then
                self.selectpage = "pet"
            elseif temconfig.staffType == "artifact" then
                self.selectpage = "artifact"
            elseif temconfig.staffType == "red_fragment" then
                self.selectpage = "redfragment"
            elseif temconfig.staffType == "exclusive" then
                self.selectpage = "exclusiveArtifact"
            end
       end
    end

    self.data.equip.data = data.equip or {}
    self.data.treasure.data = {horse = {},treasure = {}}

    local treasureData = data.treasure or {}
    for i,v in ipairs(treasureData) do
        local temconfig = {}
        if v["cid"] then
            temconfig = ui.IDconfig(v["cid"])
        else
            temconfig = ui.IDconfig(v["id"])
        end

        if temconfig.staffType == "treasure_fragment" and temconfig.page == "horse" then
            table.insert(self.data.treasure.data.horse,v)
        elseif temconfig.staffType == "treasure_fragment" and temconfig.page == "treasure" then
            table.insert(self.data.treasure.data.treasure,v)
        elseif v.type and v.type == "horse" then
            table.insert(self.data.treasure.data.horse,v)
        elseif v.type and v.type == "treasure" then
            table.insert(self.data.treasure.data.treasure,v)
        end
    end


    self.data.fashion.data = data.fashion or {}
    self.data.pet.data = data.pet or {}
    self.data.artifact.data = data.artifact or {}
    self.data.redfragment.data = data.redfragment or {}
    self.data.exclusiveArtifact.data = data.exclusiveArtifact or {}

    if data.page and data.page == "lianhua" then
        self.data.general.data = data.generalfragment or {}
        self.maxNum = data.maxNum or 5

        self.pageconfig = {"general","equip","treasure"}

        -- self.rootItems["tablab1"]:setString("伙伴")
        -- self.rootItems["tab1"]:setVisible(true)
        -- self.rootItems["tab2"]:setVisible(true)
        -- self.rootItems["tab3"]:setVisible(false)
        -- self.rootItems["tab4"]:setVisible(false)
        -- self.rootItems["tab6"]:setVisible(false)
        -- if self.rootItems["tab5"] then
        --     self.rootItems["tab5"]:setVisible(false)
        -- end 
        -- if self.rootItems["tab6"] then
        --     self.rootItems["tab6"]:setVisible(false)
        -- end        
    elseif data.page and data.page == "huahun" then
        self.data.general.data = data.general or {}
        self.maxNum = data.maxNum or 5

        self.pageconfig = {"general"}

        -- self.rootItems["tablab1"]:setString("伙伴")
        -- self.rootItems["tab1"]:setVisible(true)
        -- self.rootItems["tab2"]:setVisible(false)
        -- self.rootItems["tab3"]:setVisible(false)
        -- self.rootItems["tab4"]:setVisible(false)
        -- if self.rootItems["tab5"] then
        --     self.rootItems["tab5"]:setVisible(false)
        -- end
        -- if self.rootItems["tab6"] then
        --     self.rootItems["tab6"]:setVisible(false)
        -- end        
    elseif data.page and data.page == "fenjie" then
        self.data.general.data = data.generalfragment or {}
        self.maxNum = data.maxNum or 5

        self.pageconfig = {"redfragment"}

        -- self.rootItems["tablab1"]:setString("伙伴")
        -- self.rootItems["tab1"]:setVisible(false)
        -- self.rootItems["tab2"]:setVisible(false)
        -- self.rootItems["tab3"]:setVisible(false)
        -- self.rootItems["tab4"]:setVisible(false)
        -- if self.rootItems["tab5"] then
        --     self.rootItems["tab5"]:setVisible(false)
        -- end  
        -- if self.rootItems["tab6"] then
        --     self.rootItems["tab6"]:setVisible(true)
        --     self.rootItems["tab6"]:setPositionX(100)
        -- end   
        self.selectpage = "redfragment"  
    else
        self.data.general.data = data.general or {}
        self.maxNum = 1


        self.pageconfig = {"general","equip","treasure","fashion","artifact"}
        if gamedata.config.build[tostring(375)] and gamedata.config.build[tostring(375)].switch and gamedata.config.build[tostring(375)].switch == 1 then 
            self.pageconfig[#self.pageconfig+1] = "pet"  
        end 

        if gamedata.config.build[tostring(611)] and gamedata.config.build[tostring(611)].switch and gamedata.config.build[tostring(611)].switch == 1 then 
            self.pageconfig[#self.pageconfig+1] = "exclusiveArtifact"  
        end 

        self.rootItems.titlescroll = tolua.cast(self.rootItems.titlescroll, "CCScrollView")
        self.rootItems.titlescroll:setTouchPriority(self.touchPriority)
    end

    printT(self.pageconfig,"self.pageconfig")

    self.rootItems.title_container:setContentSize(CCSize((200*(#self.pageconfig) + 20)*0.88,108))
    for i = 1,7 do
        if i<=#self.pageconfig then
            self.rootItems["tab"..i]:setVisible(true)
            self.rootItems["tablab"..i]:setString(self.data[self.pageconfig[i]].name)

            self.rootItems["tabbutton"..i]:addHandleOfControlEvent(function()
                if gameTouch.ismove then return end

                self:shiftpage(self.pageconfig[i])
            end, CCControlEventTouchUpInside)
            -- self.rootItems["tabbutton"..i]:setSwallowsTouch(true)
            self.rootItems["tabbutton"..i]:setTouchPriority(self.touchPriority-2)
            
        else
            self.rootItems["tab"..i]:setVisible(false)
        end
    end

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("qiankunluselect")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.doLab,nil,19)
    self.rootItems.doButton:addHandleOfControlEvent(function()
        -- print("ok")

        gameWindows:closeWindowDirect("qiankunluselect")

    end, CCControlEventTouchUpInside)
    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:setTouchPriority(self.touchPriority)

    --
    self:shiftpage(self.selectpage)
end

function qiankunluselect.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.selectpage = "general"
    self.maxNum = 1
    self.treasureIndex = 1

    if self.unrecycleCell and self.unrecycleCell.detailCell then
        self.unrecycleCell.detailCell.cell:release()
    end
    self.unrecycleCell = {}

    if self.callback then
        local data = {}
        for k,v in pairs(self.selectedData) do
            table.insert(data,v)
        end
        self.callback(data)
    end

    -- self.data = {
    --     general = {data = {}, ccb = "windows/cell_generalselect"},
    --     equip = {data = {}, ccb = "windows/cell_equipselect"},
    --     treasure = {data = {}, ccb = "windows/cell_equipselect"},
    --     fashion = {data = {}, ccb = "windows/cell_equipselect"},
    --     pet = {data = {}, ccb = "windows/cell_equipselect"},
    --     artifact = {data = {}, ccb = "windows/cell_equipselect"},
    --     redfragment = {data = {}, ccb = "windows/cell_generalselect"},
    -- }
    self.data = {
        general =  {name = "伙 伴", data = {}, ccb = "windows/cell_generalselect"},
        equip =    {name = "装 备", data = {}, ccb = "windows/cell_equipselect"},
        treasure = {name = "宝 物", data = {}, ccb = "windows/cell_equipselect"},
        fashion =  {name = "时 装", data = {}, ccb = "windows/cell_equipselect"},
        pet =      {name = "魔 宠", data = {}, ccb = "windows/cell_equipselect"},
        artifact = {name = "神 器", data = {}, ccb = "windows/cell_equipselect"},
        redfragment = {name = "精 华", data = {}, ccb = "windows/cell_generalselect"},
        exclusiveArtifact = {name = "专属神器",data = {}, ccb = "windows/cell_exclusiveselect"}
    }

    self.redfragmentListTableView  = nil
    self.generalListTableView  = nil
    self.equipListTableView = nil
    self.treasureListTableView = nil
    self.fashionListTableView = nil
    self.petListTableView = nil
    self.artifactListTableView = nil
    self.exclusiveArtifactListTableView = nil
    self.selectedData = {}

    self.redfragmentshowdata = {}
    self.generalshowdata = {}
    self.equipshowdata = {}
    self.treasureshowdata = {}
    self.fashionshowdata = {}
    self.petshowdata = {}
    self.artifactshowdata = {}
    self.exclusiveArtifactshowdata = {}
    self.exceptdata = {}
    self.page = {}
end

function qiankunluselect.setGeneral(self, item, data)
    item.onwhere:setVisible(false)
   
    if self.page == "lianhua" then
        local descString = ""
        printT(data,"data ----    ")
        if ((data.cid >= 10101 and data.cid <= 11000) or (data.cid >= 160001 and data.cid <= 161000) or (data.cid >= 170001 and data.cid <= 171000) or (data.cid >= 162001 and data.cid <= 163000) or (data.cid >= 164001 and data.cid <= 165000) or (data.cid >= 174001 and data.cid <= 175000)) and ((not data.fragmentCid)or (data.fragmentCid == 0)) then
            if data.level1 > 1 then 
                descString = "（重生后可以炼化）"
                item.onwhere:setVisible(true)
            end
        end
        if ((data.cid >= 10101 and data.cid <= 11000) or (data.cid >= 160001 and data.cid <= 161000) or (data.cid >= 170001 and data.cid <= 171000) or (data.cid >= 162001 and data.cid <= 163000) or (data.cid >= 164001 and data.cid <= 165000) or (data.cid >= 174001 and data.cid <= 175000)) and ((not data.fragmentCid)or (data.fragmentCid == 0)) then
            if self.exceptdata[tostring(data.iid)] then 
                -- descString = "（王的男人/天庭银座/封神赛已添加）"
                descString = "（王的男人/天庭银座已添加）"
                item.onwhere:setVisible(true)
            end
        end
        item.onwhere:setString(descString)
    end



























    -- 设置头像
    if data.illusionGeneralCid == nil then
        local configGeneral = gamedata.config.general[tostring(data.cid)]
        local gdata = ui.getConfigGeneral(data)
        if next(gdata) and configGeneral.fashion_id == 0 then    
            data.icon = gdata.icon
        end
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
       
    if data.num and data.num > 0 then
        setSpriteFrameByName(item["il_fragment"], "b_soulsprite")
    else
        setSpriteFrameByName(item["il_fragment"], "alpha")
    end
    -- print("setGeneral=cid==",data.cid)
    -- printT(data)
    local configdata =  gamedata.config.general[tostring(data.cid)]
    if configdata.quality and configdata.quality >= 7 then
        ui.setLabelString(item.name,configdata.name..((data.level2 and data.level2>0) and "+"..data.level2 or ""), 213)
    else
        ui.setLabelString(item.name,configdata.name..((data.level2 and data.level2>0) and "+"..data.level2 or ""), configdata.quality and 2*configdata.quality-1 or 1)
    end

    item.power:setString(data.power and ("战斗力: "..data.power) or ("数量: "..(data.num or 0)))

    setSpriteFrameByName(item["type"], gameConfig.images[configdata.actor])

    item.notice:setVisible(false)

    setSpriteFrameByName(item["ison"], "alpha")

    --
    --
    if item.donumnode then
        if self.page == "lianhua" and data.num and data.num > 0 then
            item.donumnode:setVisible(true)
            item.power2:setString("拥有数量: "..(data.num or 0))
        else
            item.donumnode:setVisible(false)    
        end
    
        --
        item.donum:setString(self.selectedData[tostring((data.cid or "")..(data.iid or ""))] and self.selectedData[tostring((data.cid or "")..(data.iid or ""))].num or 0)
        --
        item.selectButton:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end

            if self.selectedData[tostring((data.cid or "")..(data.iid or ""))] then
                self:setGeneralNum(item,data,0)
            else
                self:setGeneralNum(item,data,data.num or 1)
            end 
               
        end, CCControlEventTouchUpInside)
        item.selectButton:setSwallowsTouch(true)
        item.selectButton:setTouchPriority(self.touchPriority)
        --
        item.sub1:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            local donum = self.selectedData[tostring((data.cid or "")..(data.iid or ""))] and self.selectedData[tostring((data.cid or "")..(data.iid or ""))].num or 0
            self:setGeneralNum(item,data,donum-1)              
        end, CCControlEventTouchUpInside)
        item.sub1:setSwallowsTouch(true)
        item.sub1:setTouchPriority(self.touchPriority)
        --
        item.sub10:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            local donum = self.selectedData[tostring((data.cid or "")..(data.iid or ""))] and self.selectedData[tostring((data.cid or "")..(data.iid or ""))].num or 0
            self:setGeneralNum(item,data,donum-10)              
        end, CCControlEventTouchUpInside)
        item.sub10:setSwallowsTouch(true)
        item.sub10:setTouchPriority(self.touchPriority)
        --
        item.add1:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            local donum = self.selectedData[tostring((data.cid or "")..(data.iid or ""))] and self.selectedData[tostring((data.cid or "")..(data.iid or ""))].num or 0
            self:setGeneralNum(item,data,donum+1)              
        end, CCControlEventTouchUpInside)
        item.add1:setSwallowsTouch(true)
        item.add1:setTouchPriority(self.touchPriority)
        --
        item.add10:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            local donum = self.selectedData[tostring((data.cid or "")..(data.iid or ""))] and self.selectedData[tostring((data.cid or "")..(data.iid or ""))].num or 0
            self:setGeneralNum(item,data,donum+10)              
        end, CCControlEventTouchUpInside)
        item.add10:setSwallowsTouch(true)
        item.add10:setTouchPriority(self.touchPriority)


    end
    --
end

function qiankunluselect.setExclusiveArtifact(self,item,data)

    ui.setIconLv(item,{cid=data.cid,quality = 7})
    
    local configdata =  ui.IDconfig(tostring(data.cid))

    ui.setLabelString(item.name,configdata.name.."+"..data.intensify_level,213)
    item.att:setString("洗礼+"..data.baptism_level)

    local upconfigall = gamedata.config.fashionintentify and gamedata.config.fashionintentify[tostring(data.id)] or {}
    local upconfig = upconfigall[tostring(data.level)] or {}
end

function qiankunluselect.setGeneralNum(self, item, data, donum)


            if donum > 0 and self.page == "lianhua" and ((data.cid >= 10101 and data.cid <= 11000) or (data.cid >= 160001 and data.cid <= 161000) or (data.cid >= 170001 and data.cid <= 171000) or (data.cid >= 162001 and data.cid <= 163000) or (data.cid >= 164001 and data.cid <= 165000) or (data.cid >= 174001 and data.cid <= 175000)) and ((not data.fragmentCid) or (data.fragmentCid == 0)) then
                if self.exceptdata[tostring(data.iid)] then 
                    runGamePrompt({msg = "王的男人/天庭银座/封神赛已添加的伙伴无法炼化！"})
                    return
                end
            end

            if donum > 0 and self.page == "lianhua" and ((data.cid >= 10101 and data.cid <= 11000) or (data.cid >= 160001 and data.cid <= 161000) or (data.cid >= 170001 and data.cid <= 171000) or (data.cid >= 162001 and data.cid <= 163000) or (data.cid >= 164001 and data.cid <= 165000) or (data.cid >= 174001 and data.cid <= 175000)) and ((not data.fragmentCid) or (data.fragmentCid == 0)) then
                if data.level1 > 1 then
                    runGamePrompt({msg = "重生后可以炼化"})
                    return
                end
            end


            if donum <= 0 then
                self.selectedData[tostring((data.cid or "")..(data.iid or ""))] = nil
            else
                if self.maxNum == 1 then
                    self.selectedData = {}
                    self.selectedData[tostring((data.cid or "")..(data.iid or ""))] = table.copy(data)
                    if donum < (data.num or 1) then
                        self.selectedData[tostring((data.cid or "")..(data.iid or ""))].num = donum 
                    end   
                elseif self.maxNum > 1 then
                    if self.selectedData[tostring((data.cid or "")..(data.iid or ""))] or (table.getTableLength(self.selectedData) < self.maxNum) then
                        self.selectedData[tostring((data.cid or "")..(data.iid or ""))] = table.copy(data)
                        if donum < (data.num or 1) then
                            self.selectedData[tostring((data.cid or "")..(data.iid or ""))].num = donum 
                        end   
                    else
                        runGamePrompt({msg = "最多可选"..self.maxNum.."个"})
                    end
                end
            end

            item.donum:setString(self.selectedData[tostring((data.cid or "")..(data.iid or ""))] and self.selectedData[tostring((data.cid or "")..(data.iid or ""))].num or 0)

            self:setSelectNum()
            self.generalListTableView:reloadData()

end   

function qiankunluselect.setEquipsFragmentNum(self, item, data, donum)

    if donum <= 0 then
        self.selectedData[tostring((data.cid or "")..(data.iid or ""))] = nil
    else
        if self.maxNum == 1 then
            self.selectedData = {}
            self.selectedData[tostring((data.cid or "")..(data.iid or ""))] = table.copy(data)
            if donum < (data.num or 1) then
                self.selectedData[tostring((data.cid or "")..(data.iid or ""))].num = donum 
            end   
        elseif self.maxNum > 1 then
            if self.selectedData[tostring((data.cid or "")..(data.iid or ""))] or (table.getTableLength(self.selectedData) < self.maxNum) then
                self.selectedData[tostring((data.cid or "")..(data.iid or ""))] = table.copy(data)
                if donum < (data.num or 1) then
                    self.selectedData[tostring((data.cid or "")..(data.iid or ""))].num = donum 
                end   
            else
                runGamePrompt({msg = "最多可选"..self.maxNum.."个"})
            end
        end
    end

    item.donum:setString(self.selectedData[tostring((data.cid or "")..(data.iid or ""))] and self.selectedData[tostring((data.cid or "")..(data.iid or ""))].num or 0)

    self:setSelectNum()

    if  self.selectpage == "equip" then
        self.equipListTableView:reloadData()
    elseif self.selectpage == "treasure" then
        self.treasureListTableView:reloadData()
    end
end  


function qiankunluselect.setEquip(self, item, data)
    -- ui.setIconLv(item,data)
    -- 装备升星星级展示
    ui.setIconLv(item,data,nil,data)
    -- 装备升星属性提升展示
    ui.setEquipStarPropertyshow(item,data)
    
    local configdata =  ui.IDconfig(tostring(data.cid))

    item.generalname:setString("")
    item.notOn:setVisible(true)

    item.notice:setVisible(false)
    item.notOn:setVisible(false)
    printT(configdata,"setEquip")
    printT(data)

    if configdata.staffType == "equip_fragment" or configdata.staffType == "treasure_fragment" then
        if configdata.quality >= 7 then
            ui.setLabelString(item.name,configdata.name, 213)
        else
            ui.setLabelString(item.name,configdata.name, configdata.quality and 2*configdata.quality-1 or 1)
        end
    else
        if configdata.quality >= 7 then
            if configdata.type == "treasure" or configdata.type == "horse" then
                ui.setLabelString(item.name,configdata.name..(data.level2>0 and "+"..data.level2 or ""), 213)
            else
                ui.setLabelString(item.name,ui.getEquipStageName(data), 213)
            end
        else
            if configdata.type == "treasure" or configdata.type == "horse" then
                ui.setLabelString(item.name,configdata.name..(data.level2>0 and "+"..data.level2 or ""), configdata.quality and 2*configdata.quality-1 or 1)
            else
                ui.setLabelString(item.name,ui.getEquipStageName(data), configdata.quality and 2*configdata.quality-1 or 1)
            end
        end
        ui.setEquipPromote(item.att1,item.att2,data)
    end

    if item.donumnode then
        if self.page == "lianhua" and data.num and data.num > 0 and (configdata.staffType == "equip_fragment" or configdata.staffType == "treasure_fragment") then
            item.donumnode:setVisible(true)
            item.generalname:setString("拥有数量: "..(data.num or 0))
        else
            item.donumnode:setVisible(false)    
        end
    
        --
        item.donum:setString(self.selectedData[tostring((data.cid or "")..(data.iid or ""))] and self.selectedData[tostring((data.cid or "")..(data.iid or ""))].num or 0)
        --
        item.selectButton:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end

            if self.selectedData[tostring((data.cid or "")..(data.iid or ""))] then
                self:setEquipsFragmentNum(item,data,0)
            else
                self:setEquipsFragmentNum(item,data,data.num or 1)
            end 
               
        end, CCControlEventTouchUpInside)
        item.selectButton:setSwallowsTouch(true)
        item.selectButton:setTouchPriority(self.touchPriority-1)
        --
        item.sub1:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            local donum = self.selectedData[tostring((data.cid or "")..(data.iid or ""))] and self.selectedData[tostring((data.cid or "")..(data.iid or ""))].num or 0
            self:setEquipsFragmentNum(item,data,donum-1)              
        end, CCControlEventTouchUpInside)
        item.sub1:setSwallowsTouch(true)
        item.sub1:setTouchPriority(self.touchPriority-1)
        --
        item.sub10:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            local donum = self.selectedData[tostring((data.cid or "")..(data.iid or ""))] and self.selectedData[tostring((data.cid or "")..(data.iid or ""))].num or 0
            self:setEquipsFragmentNum(item,data,donum-10)              
        end, CCControlEventTouchUpInside)
        item.sub10:setSwallowsTouch(true)
        item.sub10:setTouchPriority(self.touchPriority-1)
        --
        item.add1:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            local donum = self.selectedData[tostring((data.cid or "")..(data.iid or ""))] and self.selectedData[tostring((data.cid or "")..(data.iid or ""))].num or 0
            print("donum",donum)
            self:setEquipsFragmentNum(item,data,donum+1)              
        end, CCControlEventTouchUpInside)
        item.add1:setSwallowsTouch(true)
        item.add1:setTouchPriority(self.touchPriority-1)
        --
        item.add10:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            local donum = self.selectedData[tostring((data.cid or "")..(data.iid or ""))] and self.selectedData[tostring((data.cid or "")..(data.iid or ""))].num or 0
            self:setEquipsFragmentNum(item,data,donum+10)              
        end, CCControlEventTouchUpInside)
        item.add10:setSwallowsTouch(true)
        item.add10:setTouchPriority(self.touchPriority-1)


    end
end

function qiankunluselect.setFashion(self, item, data)
    printT(ui.IDconfig(tostring(data.id)),"IDconfig====")
    ui.setIconLv(item,{cid=data.id,level=data.level})
    

    local configdata =  ui.IDconfig(tostring(data.id))

    item.generalname:setString("")
    item.notOn:setVisible(true)

    item.notice:setVisible(false)
    item.notOn:setVisible(false)
    -- if configdata.type == "treasure" or configdata.type == "horse" then
        if configdata.quality >= 7 then
            ui.setLabelString(item.name,configdata.name, 213)
        else
            ui.setLabelString(item.name,configdata.name, configdata.quality and 2*configdata.quality-1 or 1)
        end
    -- else
        -- ui.setLabelString(item.name,ui.getEquipStageName(data), configdata.quality and 2*configdata.quality-1 or 1)
    -- end
    -- ui.setLabelString(item.name,configdata.name..(data.level2>0 and "+"..data.level2 or ""), configdata.quality and 2*configdata.quality-1 or 1)
    -- ui.setEquipPromote(item.att1,item.att2,data)
    local upconfigall = gamedata.config.fashionintentify and gamedata.config.fashionintentify[tostring(data.id)] or {}
    local upconfig = upconfigall[tostring(data.level)] or {}

    for i = 1,2 do
        if upconfig["intentify_add"..i] and upconfig["intentify_add"..i] ~= "" then
            local attr,num = ui.getATTRandNUM(upconfig["intentify_add"..i])
            local tempstring = (gameConfig.strings.attr_type[attr] or "").."+"..(num or 0)
            -- ui.setLabelString(item["att"..i],tempstring,13)
            item["att"..i]:setString(tempstring)
            -- ui.setLabelString(item["basic_num"..i],,21)
        else
            -- ui.setLabelString(item["att"..i],"",13)
            item["att"..i]:setString("")
            -- ui.setLabelString(item["basic_num"..i],"",21)
        end
    end
end

function qiankunluselect.createGeneralSelectList(self)

    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(922, 230)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("qiankunlu/cell_qiankunluselect", nil, true, "qiankunlu/cell_qiankunluselect")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            if self.selectedData[tostring((self.generalshowdata[(a1+1)].cid or "")..(self.generalshowdata[(a1+1)].iid or ""))] then
                ccbDocumentControler.isSelect:setVisible(true)
            else
                ccbDocumentControler.isSelect:setVisible(false)
            end

            self:setGeneral(ccbDocumentControler,self.generalshowdata[(a1+1)])

            cellCCB:setPosition(922/2, 0)
            cellCCB:setScale(0.96)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.generalshowdata)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.generalListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listscrollgeneral:getContentSize().width,
        viewheight = self.rootItems.listscrollgeneral:getContentSize().height,
        dire = 1
    })
    self.rootItems.listscrollgeneral:addChild(self.generalListTableView)
    self.generalListTableView:setTouchPriority(self.touchPriority)
end


function qiankunluselect.createEquipSelectList(self)

    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(922, 230)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("windows/cell_equipselect", nil, true, "windows/cell_equipselect")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            if self.selectedData[tostring((self.equipshowdata[(a1+1)].cid or "")..(self.equipshowdata[(a1+1)].iid or ""))] then
                ccbDocumentControler.isSelect:setVisible(true)
            else
                ccbDocumentControler.isSelect:setVisible(false)
            end

            self:setEquip(ccbDocumentControler,self.equipshowdata[(a1+1)])

            cellCCB:setPosition(922/2, 0)
            cellCCB:setScale(0.96)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.equipshowdata)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.equipListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listscrollequip:getContentSize().width,
        viewheight = self.rootItems.listscrollequip:getContentSize().height,
        dire = 1
    })
    self.rootItems.listscrollequip:addChild(self.equipListTableView)
    self.equipListTableView:setTouchPriority(self.touchPriority)
end

function qiankunluselect.createTreasureSelectList(self)

    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(922, 230)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("windows/cell_equipselect", nil, true, "windows/cell_equipselect")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            if self.selectedData[tostring((self.treasureshowdata[(a1+1)].cid or "")..(self.treasureshowdata[(a1+1)].iid or ""))] then
                ccbDocumentControler.isSelect:setVisible(true)
            else
                ccbDocumentControler.isSelect:setVisible(false)
            end

            self:setEquip(ccbDocumentControler,self.treasureshowdata[(a1+1)])

            cellCCB:setPosition(922/2, 0)
            cellCCB:setScale(0.96)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.treasureshowdata)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.treasureListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listscrolltreasure:getContentSize().width,
        viewheight = self.rootItems.listscrolltreasure:getContentSize().height,
        dire = 1
    })
    self.rootItems.listscrolltreasure:addChild(self.treasureListTableView)
    self.treasureListTableView:setTouchPriority(self.touchPriority)
end


function qiankunluselect.createFashionSelectList(self)

    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(922, 230)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("windows/cell_equipselect", nil, true, "windows/cell_equipselect")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            if self.selectedData[tostring((self.fashionshowdata[(a1+1)].cid or "")..(self.fashionshowdata[(a1+1)].iid or ""))] then
                ccbDocumentControler.isSelect:setVisible(true)
            else
                ccbDocumentControler.isSelect:setVisible(false)
            end

            self:setFashion(ccbDocumentControler,self.fashionshowdata[(a1+1)])

            cellCCB:setPosition(922/2, 0)
            cellCCB:setScale(0.96)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.fashionshowdata)
        elseif fn == "cellTouched" then
            if self.selectedData[tostring((self.fashionshowdata[(a1:getIdx()+1)].cid or "")..(self.fashionshowdata[(a1:getIdx()+1)].iid or ""))] then
                self.selectedData[tostring((self.fashionshowdata[(a1:getIdx()+1)].cid or "")..(self.fashionshowdata[(a1:getIdx()+1)].iid or ""))] = nil
            else
                if self.maxNum == 1 then
                    self.selectedData = {}
                    self.selectedData[tostring((self.fashionshowdata[(a1:getIdx()+1)].cid or "")..(self.fashionshowdata[(a1:getIdx()+1)].iid or ""))] = self.fashionshowdata[(a1:getIdx()+1)]
                elseif self.maxNum > 1 then
                    if table.getTableLength(self.selectedData) < self.maxNum then
                        self.selectedData[tostring((self.fashionshowdata[(a1:getIdx()+1)].cid or "")..(self.fashionshowdata[(a1:getIdx()+1)].iid or ""))] = self.fashionshowdata[(a1:getIdx()+1)]
                    else
                        runGamePrompt({msg = "最多可选"..self.maxNum.."个"})
                    end
                end
            end
            self:setSelectNum()
            self.fashionListTableView:reloadData()

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.fashionListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listscrollfashion:getContentSize().width,
        viewheight = self.rootItems.listscrollfashion:getContentSize().height,
        dire = 1
    })
    self.rootItems.listscrollfashion:addChild(self.fashionListTableView)
    self.fashionListTableView:setTouchPriority(self.touchPriority)
end

function qiankunluselect.createPetSelectList(self)

    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(922, 230)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("windows/cell_equipselect", nil, true, "windows/cell_equipselect")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            if self.selectedData[tostring((self.petshowdata[(a1+1)].cid or "")..(self.petshowdata[(a1+1)].iid or ""))] then
                ccbDocumentControler.isSelect:setVisible(true)
            else
                ccbDocumentControler.isSelect:setVisible(false)
            end

            self:setPet(ccbDocumentControler,self.petshowdata[(a1+1)])

            cellCCB:setPosition(922/2, 0)
            cellCCB:setScale(0.96)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.petshowdata)
        elseif fn == "cellTouched" then
            if self.selectedData[tostring((self.petshowdata[(a1:getIdx()+1)].cid or "")..(self.petshowdata[(a1:getIdx()+1)].iid or ""))] then
                self.selectedData[tostring((self.petshowdata[(a1:getIdx()+1)].cid or "")..(self.petshowdata[(a1:getIdx()+1)].iid or ""))] = nil
            else
                if self.maxNum == 1 then
                    self.selectedData = {}
                    self.selectedData[tostring((self.petshowdata[(a1:getIdx()+1)].cid or "")..(self.petshowdata[(a1:getIdx()+1)].iid or ""))] = self.petshowdata[(a1:getIdx()+1)]
                elseif self.maxNum > 1 then
                    if table.getTableLength(self.selectedData) < self.maxNum then
                        self.selectedData[tostring((self.petshowdata[(a1:getIdx()+1)].cid or "")..(self.petshowdata[(a1:getIdx()+1)].iid or ""))] = self.petshowdata[(a1:getIdx()+1)]
                    else
                        runGamePrompt({msg = "最多可选"..self.maxNum.."个"})
                    end
                end
            end
            self:setSelectNum()
            self.petListTableView:reloadData()

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.petListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listscrollpet:getContentSize().width,
        viewheight = self.rootItems.listscrollpet:getContentSize().height,
        dire = 1
    })
    self.rootItems.listscrollpet:addChild(self.petListTableView)
    self.petListTableView:setTouchPriority(self.touchPriority)
end

function qiankunluselect.setPet(self, item, data)

    ui.setIconLv(item,{cid = data.cid})
    
    local configdata = gamedata.config.pet3_attr[tostring(data.cid)][tostring(data.level)]

    item.generalname:setString("")

    item.notice:setVisible(false)
    item.notOn:setVisible(false)

    setSpriteFrameByName(item["il_icon"], configdata.icon and configdata.icon or "alpha")
    ui.setSpriteTextureRect(item["il_icon"],0,0,150,150)

    setSpriteFrameByName(item["il_kuang"], "b_iconk"..(configdata.quality and configdata.quality>1 and configdata.quality or 1))
    setSpriteFrameByName(item["il_quality"], "b_iconbg"..(configdata.quality and configdata.quality>1 and configdata.quality or 1))

    if configdata.quality >= 7 then
        ui.setLabelString(item.name,configdata.name, 213)
    else
        ui.setLabelString(item.name,configdata.name, configdata.quality and 2*configdata.quality-1 or 1)
    end

    item["att1"]:setString("图鉴等级："..(data.collectlevel or 0))
    item["att2"]:setString("")

end


function qiankunluselect.lockCallback(self,t)
    --神器加锁数据 无需重新排序
    for i,v in ipairs(self.artifactshowdata) do
        if v.iid == t.artifactSid then
            v.isLockState = t.isLock
            break
        end
    end

    if  self.selectpage == "artifact" then
        self.artifactListTableView:reloadData()
    end
end

function qiankunluselect.createartifactSelectList(self)
    -- CCSizeMake(922, 230)
    -- CCSizeMake(922, 860)

    self.cellNorSize = {x = 922,y = 230}
    self.cellDelSize = {x = 922,y = 800}

    self.artifactSelect = nil
    self.unrecycleCell = {}

    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then

        elseif fn == "hasFixedCellSize" then
            r = false
        elseif fn == "cellSizeForIndex" then
            if self.artifactSelect and self.artifactSelect == a1+1 then

                r = CCSizeMake(self.cellDelSize.x, self.cellDelSize.y)
            else
                r = CCSizeMake(self.cellNorSize.x, self.cellNorSize.y)
            end
        elseif fn == "isRecycle" then
            for k,v in pairs (self.unrecycleCell) do
                if a2 == v.cell then
                    print("unrecycleCELL ")
                    return false
                end
            end
            return true
        elseif fn == "cellAtIndex" then
            if self.artifactSelect and self.artifactSelect == a1+1 then
                local ccb, items,ccb1, items1
                local artifact = self.artifactshowdata[a1 + 1]

                if self.unrecycleCell.detailCell == nil then
                    a2 = CCTableViewCell:create()
                    ccb, items =  CCBReaderLoad("shenqi_new/cell_shenqichongzhu", nil, true, "cell_shenqichongzhu")
                    ccb1, items1 =  CCBReaderLoad("shenqi_new/cell_shenqiselect_content", nil, true, "cell_shenqiselect_content")
                    items1.touchBtn:addHandleOfControlEvent(function()
                        
                    end, CCControlEventTouchUpInside)
                    items1.touchBtn:setSwallowsTouch(true)
                    items1.touchBtn:setTouchPriority(self.touchPriority - 2)

                    local scrollnode = tolua.cast(items1.scrollnode, "CCScrollView")
                    scrollnode:setTouchPriority(self.touchPriority - 3)

                    gameWindows.windows["artifactSelect"].module:initCellDetalFixedString(items1)

                    ccb1:setPosition(self.cellNorSize.x/2, -self.cellDelSize.y)

                    a2:addChild(ccb1)
                    ccb:setPosition(self.cellNorSize.x/2, -self.cellNorSize.y)

                    a2:addChild(ccb)

                    self.unrecycleCell.detailCell={cell = a2, ccb =ccb, items=items,ccb1 =ccb1, items1=items1}
                    self.unrecycleCell.detailCell.cell:retain()
                else
                    a2 = self.unrecycleCell.detailCell.cell
                    ccb = self.unrecycleCell.detailCell.ccb
                    items = self.unrecycleCell.detailCell.items
                    ccb1 = self.unrecycleCell.detailCell.ccb1

                    ccb1:setPosition(self.cellNorSize.x/2, -self.cellDelSize.y)

                    items1 = self.unrecycleCell.detailCell.items1
                end
                
                ccb:setScale(0.9)
                ccb1:setScale(0.87)
                gameWindows.windows["artifactSelect"].module.setNormal(self,items,self.artifactshowdata[a1 + 1],function(data)
                    
                end,true,a1 + 1,#self.artifactshowdata,self.rootItems.listscrollartifact,true)


                local useSize = self.cellDelSize.y
                items.detalBtn:setTouchPriority(self.touchPriority - 1)
                items.detalBtn:setSwallowsTouch(true)
                items.detalBtn:addHandleOfControlEvent(function()
                    local location
                    self.artifactSelect,location = ui.tableviewLocation(
                        self.artifactListTableView,
                        #self.artifactshowdata,
                        a1 + 1,
                        self.rootItems.listscrollartifact,
                        self.artifactSelect,
                        useSize,
                        self.cellNorSize.y
                    )
                    self.artifactListTableView:reloadData()
                    self.artifactListTableView:setLuaContentOffset(0,location)
                end, CCControlEventTouchUpInside)


                gameWindows.windows["artifactSelect"].module.setDetail(self,items1,self.artifactshowdata[a1+1],true,false)
    
                if self.selectedData[tostring((self.artifactshowdata[a1+1].cid or "")..(self.artifactshowdata[a1+1].iid or ""))] then
                    items.autosprite:setVisible(true)
                else
                    items.autosprite:setVisible(false)
                end

                items.selectBtn:addHandleOfControlEvent(function()
                    self:selectArtifact(a1+1)
                end, CCControlEventTouchUpInside)
                items.selectBtn:setSwallowsTouch(true)
                items.selectBtn:setTouchPriority(self.touchPriority - 1)
            else
                local cellCCB,ccbDocumentControler = 0,0
                local first = true
                if not a2 then
                    a2 = CCTableViewCell:create()
                    cellCCB, ccbDocumentControler = CCBReaderLoad("shenqi_new/cell_shenqichongzhu", nil, true, "cell_shenqichongzhu")
                    gameWindows.windows["artifactSelect"].module:initCellFixedString(ccbDocumentControler)
                    celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                    -- ui.tableviewAnimation(self.ListTableView,cellCCB,self.cellNorSize.x/2,-self.cellNorSize.y,a1)
                else
                    first = false
                    cellCCB = celldict[a2].cellCCB
                    ccbDocumentControler = celldict[a2].ccbDocumentControler
                end

                gameWindows.windows["artifactSelect"].module.setNormal(self,ccbDocumentControler,self.artifactshowdata[a1+1],function(data)
                end,false,a1 + 1,#self.artifactshowdata,self.rootItems.listscrollartifact,true)
                local useSize = self.cellDelSize.y
                ccbDocumentControler.detalBtn:setTouchPriority(self.touchPriority - 1)
                ccbDocumentControler.detalBtn:setSwallowsTouch(true)
                ccbDocumentControler.detalBtn:addHandleOfControlEvent(function()
                    local location
                    self.artifactSelect,location = ui.tableviewLocation(
                        self.artifactListTableView,
                        #self.artifactshowdata,
                        a1 + 1,
                        self.rootItems.listscrollartifact,
                        self.artifactSelect,
                        useSize,
                        self.cellNorSize.y
                    )
                    self.artifactListTableView:reloadData()
                    self.artifactListTableView:setLuaContentOffset(0,location)
                end, CCControlEventTouchUpInside)

                if self.selectedData[tostring((self.artifactshowdata[a1+1].cid or "")..(self.artifactshowdata[a1+1].iid or ""))] then
                    ccbDocumentControler.autosprite:setVisible(true)
                else
                    ccbDocumentControler.autosprite:setVisible(false)
                end
                
                ccbDocumentControler.selectBtn:addHandleOfControlEvent(function()
                    self:selectArtifact(a1+1)
                end, CCControlEventTouchUpInside)
                ccbDocumentControler.selectBtn:setSwallowsTouch(true)
                ccbDocumentControler.selectBtn:setTouchPriority(self.touchPriority - 1)

                if first then
                    a2:addChild(cellCCB)
                end
                cellCCB:setScale(0.9)
                cellCCB:setPosition(self.cellNorSize.x/2, -self.cellNorSize.y)
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = #self.artifactshowdata
        end
        return r
    end)

    self.artifactListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listscrollartifact:getContentSize().width,
        viewheight = self.rootItems.listscrollartifact:getContentSize().height,
        dire = 1
    })
    self.rootItems.listscrollartifact:addChild(self.artifactListTableView)
    self.artifactListTableView:setTouchPriority(self.touchPriority)
end

function qiankunluselect.createExclusiveartifactSelectList(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(922, 230)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("windows/cell_exclusiveselect", nil, true, "cell_exclusiveselect")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            if self.selectedData[tostring(self.exclusiveArtifactshowdata[(a1+1)].generalIid or "")] then
                ccbDocumentControler.isSelect:setVisible(true)
            else
                ccbDocumentControler.isSelect:setVisible(false)
            end

            self:setExclusiveArtifact(ccbDocumentControler,self.exclusiveArtifactshowdata[(a1+1)])

            cellCCB:setPosition(922/2, 0)
            cellCCB:setScale(0.96)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.exclusiveArtifactshowdata)
        elseif fn == "cellTouched" then

            if self.selectedData[tostring((self.exclusiveArtifactshowdata[(a1:getIdx()+1)].generalIid or ""))] then
                self.selectedData[tostring((self.exclusiveArtifactshowdata[(a1:getIdx()+1)].generalIid or ""))] = nil
            else
                self.selectedData = {}
                self.selectedData[tostring((self.exclusiveArtifactshowdata[(a1:getIdx()+1)].generalIid or ""))] = self.exclusiveArtifactshowdata[(a1:getIdx()+1)]
            end
            self:setSelectNum()
            self.exclusiveArtifactListTableView:reloadData()

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.exclusiveArtifactListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listscrollexclusiveartifact:getContentSize().width,
        viewheight = self.rootItems.listscrollexclusiveartifact:getContentSize().height,
        dire = 1
    })
    self.rootItems.listscrollexclusiveartifact:addChild(self.exclusiveArtifactListTableView)
    self.exclusiveArtifactListTableView:setTouchPriority(self.touchPriority)
end

function qiankunluselect.selectArtifact(self,index)
    print("selectArtifact",index)
    if self.selectedData[tostring((self.artifactshowdata[index].cid or "")..(self.artifactshowdata[index].iid or ""))] then
        self.selectedData[tostring((self.artifactshowdata[index].cid or "")..(self.artifactshowdata[index].iid or ""))] = nil
    else
        if self.maxNum == 1 then
            self.selectedData = {}
            self.selectedData[tostring((self.artifactshowdata[index].cid or "")..(self.artifactshowdata[index].iid or ""))] = self.artifactshowdata[index]
        elseif self.maxNum > 1 then
            if table.getTableLength(self.selectedData) < self.maxNum then
                self.selectedData[tostring((self.artifactshowdata[index].cid or "")..(self.artifactshowdata[index].iid or ""))] = self.artifactshowdata[index]
            else
                runGamePrompt({msg = "最多可选"..self.maxNum.."个"})
            end
        end
    end
    self:setSelectNum()
    self.artifactListTableView:reloadData()
end

function qiankunluselect.createartifactSelectList2( self )
    -- body

    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(922, 230)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("shenqi_new/cell_shenqichongzhu", nil, true, "cell_shenqichongzhu")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            -- if self.selectedData[tostring((self.artifactshowdata[(a1+1)].cid or "")..(self.artifactshowdata[(a1+1)].iid or ""))] then
            --     ccbDocumentControler.isSelect:setVisible(true)
            -- else
            --     ccbDocumentControler.isSelect:setVisible(false)
            -- end

            -- self:setartifact(ccbDocumentControler,self.artifactshowdata[(a1+1)])

            cellCCB:setPosition(922/2, 0)
            cellCCB:setScale(0.9)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.artifactshowdata)
        elseif fn == "cellTouched" then
            if self.selectedData[tostring((self.artifactshowdata[(a1:getIdx()+1)].cid or "")..(self.artifactshowdata[(a1:getIdx()+1)].iid or ""))] then
                self.selectedData[tostring((self.artifactshowdata[(a1:getIdx()+1)].cid or "")..(self.artifactshowdata[(a1:getIdx()+1)].iid or ""))] = nil
            else
                if self.maxNum == 1 then
                    self.selectedData = {}
                    self.selectedData[tostring((self.artifactshowdata[(a1:getIdx()+1)].cid or "")..(self.artifactshowdata[(a1:getIdx()+1)].iid or ""))] = self.artifactshowdata[(a1:getIdx()+1)]
                elseif self.maxNum > 1 then
                    if table.getTableLength(self.selectedData) < self.maxNum then
                        self.selectedData[tostring((self.artifactshowdata[(a1:getIdx()+1)].cid or "")..(self.artifactshowdata[(a1:getIdx()+1)].iid or ""))] = self.artifactshowdata[(a1:getIdx()+1)]
                    else
                        runGamePrompt({msg = "最多可选"..self.maxNum.."个"})
                    end
                end
            end
            self:setSelectNum()
            self.artifactListTableView:reloadData()

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.artifactListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listscrollartifact:getContentSize().width,
        viewheight = self.rootItems.listscrollartifact:getContentSize().height,
        dire = 1
    })
    self.rootItems.listscrollartifact:addChild(self.artifactListTableView)
    self.artifactListTableView:setTouchPriority(self.touchPriority)
end


function qiankunluselect.setartifact(self, item, data)

    ui.setIconLv(item,{cid = data.cid})
    
    local configdata = gamedata.config.trump[tostring(data.cid)] --[tostring(data.level)]

    item.generalname:setString("")

    item.notice:setVisible(false)
    item.notOn:setVisible(false)

    setSpriteFrameByName(item["il_icon"], configdata.icon and configdata.icon or "alpha")
    ui.setSpriteTextureRect(item["il_icon"],0,0,150,150)

    setSpriteFrameByName(item["il_kuang"], "b_iconk"..(configdata.quality and configdata.quality>1 and configdata.quality or 1))
    setSpriteFrameByName(item["il_quality"], "b_iconbg"..(configdata.quality and configdata.quality>1 and configdata.quality or 1))

    if configdata.quality >= 7 then
        ui.setLabelString(item.name,configdata.name.."+"..data.level1, 213)
    else
        ui.setLabelString(item.name,configdata.name.."+"..data.level1, configdata.quality and 2*configdata.quality-1 or 1)
    end

    item["att1"]:setString("神器评分："..(data.score or 0))
    item["att2"]:setString("")

end


--
function qiankunluselect.createRedfragmentSelectList(self)

    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(922, 230)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("qiankunlu/cell_qiankunluselect", nil, true, "qiankunlu/cell_qiankunluselect")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            if self.selectedData[tostring((self.redfragmentshowdata[(a1+1)].cid or "")..(self.redfragmentshowdata[(a1+1)].iid or ""))] then
                ccbDocumentControler.isSelect:setVisible(true)
            else
                ccbDocumentControler.isSelect:setVisible(false)
            end

            self:setRedfragment(ccbDocumentControler,self.redfragmentshowdata[(a1+1)])

            cellCCB:setPosition(922/2, 0)
            cellCCB:setScale(0.96)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.redfragmentshowdata)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.redfragmentListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listscrollredfragment:getContentSize().width,
        viewheight = self.rootItems.listscrollredfragment:getContentSize().height,
        dire = 1
    })
    self.rootItems.listscrollredfragment:addChild(self.redfragmentListTableView)
    self.redfragmentListTableView:setTouchPriority(self.touchPriority)
end

function qiankunluselect.setRedfragment(self, item, data)
    item.onwhere:setVisible(false)

    item.juexing_iocn:setVisible(false)
    item.juexing_stage:setVisible(false)
    item.name:setPositionX(299)
   
    ui.setIconLv(item,data)
       
    local configdata =  gamedata.config.redl_awake_item[tostring(data.cid)]
    if configdata.quality >= 7 then
        ui.setLabelString(item.name,configdata.name,213)
    else
        ui.setLabelString(item.name,configdata.name,configdata.quality and 2*configdata.quality-1 or 1)
    end

    item.power:setString("拥有数量: "..(data.num or 0))

    setSpriteFrameByName(item["type"], "alpha")

    item.notice:setVisible(false)

    setSpriteFrameByName(item["ison"], "alpha")

    --
    if item.donumnode then
        if self.page == "fenjie" and data.num and data.num > 0 then
            item.donumnode:setVisible(true)
            item.power2:setString("拥有数量: "..(data.num or 0))
        else
            item.donumnode:setVisible(false)    
        end
        --
        if gamedata.config.redl_awake_item[tostring(data.cid)] and gamedata.config.redl_awake_item[tostring(data.cid)].decompose and gamedata.config.redl_awake_item[tostring(data.cid)].decompose == 1 then 
            item.onwhere:setVisible(false)
        else    
            descString = "（该精华暂不可分解）"
            item.onwhere:setVisible(true)
            item.onwhere:setString(descString)
            item.donumnode:setVisible(false)  
        end
        --
        item.donum:setString(self.selectedData[tostring((data.cid or "")..(data.iid or ""))] and self.selectedData[tostring((data.cid or "")..(data.iid or ""))].num or 0)
        --
        item.selectButton:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end

            if self.selectedData[tostring((data.cid or "")..(data.iid or ""))] then
                self:setRedfragmentNum(item,data,0)
            else
                self:setRedfragmentNum(item,data,data.num or 1)
            end 
               
        end, CCControlEventTouchUpInside)
        item.selectButton:setSwallowsTouch(true)
        item.selectButton:setTouchPriority(self.touchPriority)
        --
        item.sub1:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            local donum = self.selectedData[tostring((data.cid or "")..(data.iid or ""))] and self.selectedData[tostring((data.cid or "")..(data.iid or ""))].num or 0
            self:setRedfragmentNum(item,data,donum-1)              
        end, CCControlEventTouchUpInside)
        item.sub1:setSwallowsTouch(true)
        item.sub1:setTouchPriority(self.touchPriority)
        --
        item.sub10:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            local donum = self.selectedData[tostring((data.cid or "")..(data.iid or ""))] and self.selectedData[tostring((data.cid or "")..(data.iid or ""))].num or 0
            self:setRedfragmentNum(item,data,donum-10)              
        end, CCControlEventTouchUpInside)
        item.sub10:setSwallowsTouch(true)
        item.sub10:setTouchPriority(self.touchPriority)
        --
        item.add1:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            local donum = self.selectedData[tostring((data.cid or "")..(data.iid or ""))] and self.selectedData[tostring((data.cid or "")..(data.iid or ""))].num or 0
            self:setRedfragmentNum(item,data,donum+1)              
        end, CCControlEventTouchUpInside)
        item.add1:setSwallowsTouch(true)
        item.add1:setTouchPriority(self.touchPriority)
        --
        item.add10:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            local donum = self.selectedData[tostring((data.cid or "")..(data.iid or ""))] and self.selectedData[tostring((data.cid or "")..(data.iid or ""))].num or 0
            self:setRedfragmentNum(item,data,donum+10)              
        end, CCControlEventTouchUpInside)
        item.add10:setSwallowsTouch(true)
        item.add10:setTouchPriority(self.touchPriority)


    end
    --
end

function qiankunluselect.setRedfragmentNum(self, item, data, donum)

    if gamedata.config.redl_awake_item[tostring(data.cid)] and gamedata.config.redl_awake_item[tostring(data.cid)].decompose and gamedata.config.redl_awake_item[tostring(data.cid)].decompose == 1 then 
        --
    else    
        runGamePrompt({msg = "该精华暂不可分解"})
        return
    end

    if donum <= 0 then
        self.selectedData[tostring((data.cid or "")..(data.iid or ""))] = nil
    else
        if self.maxNum == 1 then
            self.selectedData = {}
            self.selectedData[tostring((data.cid or "")..(data.iid or ""))] = table.copy(data)
            if donum < (data.num or 1) then
                self.selectedData[tostring((data.cid or "")..(data.iid or ""))].num = donum 
            end   
        elseif self.maxNum > 1 then
            if self.selectedData[tostring((data.cid or "")..(data.iid or ""))] or (table.getTableLength(self.selectedData) < self.maxNum) then
                self.selectedData[tostring((data.cid or "")..(data.iid or ""))] = table.copy(data)
                if donum < (data.num or 1) then
                    self.selectedData[tostring((data.cid or "")..(data.iid or ""))].num = donum 
                end   
            else
                runGamePrompt({msg = "最多可选"..self.maxNum.."个"})
            end
        end
    end

    item.donum:setString(self.selectedData[tostring((data.cid or "")..(data.iid or ""))] and self.selectedData[tostring((data.cid or "")..(data.iid or ""))].num or 0)

    self:setSelectNum()
    self.redfragmentListTableView:reloadData()

end   

return qiankunluselect
 �' 