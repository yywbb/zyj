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
        general = {data = {}, ccb = "windows/cell_generalselect"},
        equip = {data = {}, ccb = "windows/cell_equipselect"},
        treasure = {data = {}, ccb = "windows/cell_equipselect"},
    },

    showdata = {},

    selectedData = {},
    generalListTableView  = nil,
    equipListTableView = nil,
    treasureListTableView  = nil,


    uplevel1 = 1,

    -- pageconfig = {"general","equip","treasure" },
    -- selectpage = "general",


    pageconfig = {"treasure" },
    selectpage = "treasure",

}

function qiankunluselect.open(self,touchPriority,data,callback)
    -- print("qiankunluselect..open")
    -- printT(data)

    self.infodata = data.infodata
    
    self.rootNode, self.rootItems = CCBReaderLoad("equip_new/tc_baowu_qianghuaSelect", nil, true, "tc_baowu_qianghuaSelect")

    self.touchPriority = touchPriority
    self:reload(data,callback)


    return self.rootNode
end


function qiankunluselect.shiftpage(self,page)

    if self.selectpage ~= page then
        self.selectedData = {}
    end

    self.selectpage = page
    -- for k,v in ipairs(self.pageconfig) do
    --     if v == page then
    --         setSpriteFrameByName(self.rootItems["tabon"..k], gameConfig.images.pageButtonON)
    --     else
    --         setSpriteFrameByName(self.rootItems["tabon"..k], gameConfig.images.pageButtonOFF)
    --     end
    -- end

    self.showdata = self.data[self.selectpage].data

    if self.selectpage == "general" then
        self.rootItems.listscrolltreasure:setPositionX(9999)
        self.rootItems.listscrollequip:setPositionX(9999)
        self.rootItems.listscrollgeneral:setPositionX(0)
        if not self.generalListTableView then
            self:createGeneralSelectList()
        else
            self.generalListTableView:reloadData()
            self.generalListTableView:setLuaContentOffset(0, self.rootItems.listscrollgeneral:getContentSize().height - table.getTableLength(self.showdata)*230)
        end
    elseif self.selectpage == "equip" then
        self.rootItems.listscrollequip:setPositionX(0)
        self.rootItems.listscrollgeneral:setPositionX(9999)
        self.rootItems.listscrolltreasure:setPositionX(9999)
        if not self.equipListTableView then
            self:createEquipSelectList()
        else
            self.equipListTableView:reloadData()
            self.equipListTableView:setLuaContentOffset(0, self.rootItems.listscrollequip:getContentSize().height - table.getTableLength(self.showdata)*230)
        end
    else
        self.rootItems.listscrollequip:setPositionX(9999)
        self.rootItems.listscrollgeneral:setPositionX(9999)
        self.rootItems.listscrolltreasure:setPositionX(0)
        if not self.treasureListTableView then
            self:createTreasureSelectList()
        else
            self.treasureListTableView:reloadData()
            self.treasureListTableView:setLuaContentOffset(0, self.rootItems.listscrolltreasure:getContentSize().height - table.getTableLength(self.showdata)*230)
        end
    end


    ui.setGoto(self.rootItems.gotonode,table.getTableLength(self.showdata) == 0,self.selectpage)

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


    if data.choose and next(data.choose) then
       for k,v in pairs(data.choose) do
           self.selectedData[tostring((v.cid or "")..(v.iid or ""))] = v
           -- if v.type and (v.type == "horse" or v.type == "treasure") then
           --     self.selectpage = "treasure"
           -- elseif v.type and (v.type == "head" or v.type == "weapon" or v.type == "accessory" or v.type == "armor" or v.type == "shoe" or v.type == "accessories") then
           --     self.selectpage = "equip"
           -- else
           --     self.selectpage = "general"
           -- end
       end
    end

    self:setexp_up()

    -- self.data.equip.data = data.equip or {}
    -- self.data.treasure.data = data.treasure or {}
    -- print("selectreload==")
    -- printT(self.data.treasure.data)
    -- printT(data)
    for i,v in ipairs(data.treasure) do
        if v.type == self.infodata.type and v.iid ~= self.infodata.iid then
            table.insert(self.data.treasure.data,v)
        end
    end

    -- if data.page and data.page == "lianhua" then
    --     self.data.general.data = data.generalfragment or {}
    --     self.maxNum = 5
    --     self.rootItems["tablab1"]:setString("魂魄")
    --     self.rootItems["tab2"]:setVisible(true)
    --     self.rootItems["tab3"]:setVisible(true)
    -- elseif data.page and data.page == "huahun" then
    --     self.data.general.data = data.general or {}
    --     self.maxNum = 5
    --     self.rootItems["tablab1"]:setString("伙伴")
    --     self.rootItems["tab2"]:setVisible(false)
    --     self.rootItems["tab3"]:setVisible(false)
    -- else
        -- self.data.general.data = data.general or {}
        self.maxNum = 5
        self.rootItems["tablab1"]:setString("宝 物")
        self.rootItems["tab2"]:setVisible(false)
        self.rootItems["tab3"]:setVisible(false)
    -- end
    --

    -- for i = 1,3 do
    --     self.rootItems["tabbutton"..i]:addHandleOfControlEvent(function()
    --         self:shiftpage(self.pageconfig[i])
    --     end, CCControlEventTouchUpInside)
    --     self.rootItems["tabbutton"..i]:setSwallowsTouch(true)
    --     self.rootItems["tabbutton"..i]:setTouchPriority(self.touchPriority-2)
    -- end

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("treasureupSelect")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.doLab,nil,19)
    self.rootItems.doButton:addHandleOfControlEvent(function()
        -- print("ok")

        gameWindows:closeWindowDirect("treasureupSelect")

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
    self.selectpage = "treasure"
    self.maxNum = 1

    self.uplevel1 = 1

    if self.callback then
        local data = {}
        for k,v in pairs(self.selectedData) do
            table.insert(data,v)
        end
        self.callback(data)
    end

    self.data = {
        general = {data = {}, ccb = "windows/cell_generalselect"},
        equip = {data = {}, ccb = "windows/cell_equipselect"},
        treasure = {data = {}, ccb = "windows/cell_equipselect"},
    }

    self.generalListTableView  = nil
    self.equipListTableView = nil
    self.treasureListTableView = nil
    self.selectedData = {}
end

function qiankunluselect.setGeneral(self, item, data)
    ui.setIconLv(item,data)
    if data.num and data.num > 0 then
        setSpriteFrameByName(item["il_fragment"], "b_soulsprite")
    else
        setSpriteFrameByName(item["il_fragment"], "alpha")
    end
    -- print("setGeneral=cid==",data.cid)
    -- printT(data)
    local configdata =  gamedata.config.general[tostring(data.cid)]
    ui.setLabelString(item.name,configdata.name..((data.level2 and data.level2>0) and ("+"..(data.level2>10 and data.level2-10 or data.level2)) or ""), configdata.quality and 2*configdata.quality-1 or 1)

    item.power:setString(data.power and ("战斗力: "..data.power) or ("数量: "..(data.num or 0)))

    setSpriteFrameByName(item["type"], gameConfig.images[configdata.actor])

    item.notice:setVisible(false)

    setSpriteFrameByName(item["ison"], "alpha")
end

function qiankunluselect.setEquip(self, item, data)

    ui.setIconLv(item,data)
    local configdata =  ui.IDconfig(tostring(data.cid))

    item.generalname:setString("")
    item.notOn:setVisible(true)

    item.notice:setVisible(false)
    item.notOn:setVisible(false)

    ui.setLabelString(item.name,configdata.name..(data.level2>0 and "+"..data.level2 or ""), configdata.quality and 2*configdata.quality-1 or 1)
    ui.setEquipPromote(item.att1,item.att2,data)

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
                cellCCB, ccbDocumentControler = CCBReaderLoad("windows/cell_generalselect", nil, true, "windows/cell_generalselect")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            if self.selectedData[tostring((self.showdata[(a1+1)].cid or "")..(self.showdata[(a1+1)].iid or ""))] then
                ccbDocumentControler.isSelect:setVisible(true)
            else
                ccbDocumentControler.isSelect:setVisible(false)
            end

            self:setGeneral(ccbDocumentControler,self.showdata[(a1+1)])

            cellCCB:setPosition(922/2, 0)
            cellCCB:setScale(0.96)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.showdata)
        elseif fn == "cellTouched" then
            if self.selectedData[tostring((self.showdata[(a1:getIdx()+1)].cid or "")..(self.showdata[(a1:getIdx()+1)].iid or ""))] then
                self.selectedData[tostring((self.showdata[(a1:getIdx()+1)].cid or "")..(self.showdata[(a1:getIdx()+1)].iid or ""))] = nil
            else
                if self.maxNum == 1 then
                    self.selectedData = {}
                    self.selectedData[tostring((self.showdata[(a1:getIdx()+1)].cid or "")..(self.showdata[(a1:getIdx()+1)].iid or ""))] = self.showdata[(a1:getIdx()+1)]
                elseif self.maxNum > 1 then
                    if table.getTableLength(self.selectedData) < self.maxNum then
                        self.selectedData[tostring((self.showdata[(a1:getIdx()+1)].cid or "")..(self.showdata[(a1:getIdx()+1)].iid or ""))] = self.showdata[(a1:getIdx()+1)]
                    else
                        runGamePrompt({msg = "最多可选"..self.maxNum.."个"})
                    end
                end
            end
            self:setSelectNum()
            self.generalListTableView:reloadData()

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

            if self.selectedData[tostring((self.showdata[(a1+1)].cid or "")..(self.showdata[(a1+1)].iid or ""))] then
                ccbDocumentControler.isSelect:setVisible(true)
            else
                ccbDocumentControler.isSelect:setVisible(false)
            end

            self:setEquip(ccbDocumentControler,self.showdata[(a1+1)])

            cellCCB:setPosition(922/2, 0)
            cellCCB:setScale(0.96)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.showdata)
        elseif fn == "cellTouched" then
            if self.selectedData[tostring((self.showdata[(a1:getIdx()+1)].cid or "")..(self.showdata[(a1:getIdx()+1)].iid or ""))] then
                self.selectedData[tostring((self.showdata[(a1:getIdx()+1)].cid or "")..(self.showdata[(a1:getIdx()+1)].iid or ""))] = nil
            else
                if self.maxNum == 1 then
                    self.selectedData = {}
                    self.selectedData[tostring((self.showdata[(a1:getIdx()+1)].cid or "")..(self.showdata[(a1:getIdx()+1)].iid or ""))] = self.showdata[(a1:getIdx()+1)]
                elseif self.maxNum > 1 then
                    if table.getTableLength(self.selectedData) < self.maxNum then
                        self.selectedData[tostring((self.showdata[(a1:getIdx()+1)].cid or "")..(self.showdata[(a1:getIdx()+1)].iid or ""))] = self.showdata[(a1:getIdx()+1)]
                    else
                        runGamePrompt({msg = "最多可选"..self.maxNum.."个"})
                    end
                end
            end
            self:setSelectNum()
            self.equipListTableView:reloadData()

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

            if self.selectedData[tostring((self.showdata[(a1+1)].cid or "")..(self.showdata[(a1+1)].iid or ""))] then
                ccbDocumentControler.isSelect:setVisible(true)
            else
                ccbDocumentControler.isSelect:setVisible(false)
            end

            self:setEquip(ccbDocumentControler,self.showdata[(a1+1)])

            cellCCB:setPosition(922/2, 0)
            cellCCB:setScale(0.96)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.showdata)
        elseif fn == "cellTouched" then
            if self.selectedData[tostring((self.showdata[(a1:getIdx()+1)].cid or "")..(self.showdata[(a1:getIdx()+1)].iid or ""))] then
                -- print("touch11111")
                self.selectedData[tostring((self.showdata[(a1:getIdx()+1)].cid or "")..(self.showdata[(a1:getIdx()+1)].iid or ""))] = nil
            else
                if self.maxNum == 1 then
                    -- print("touch2222")
                    self.selectedData = {}
                    self.selectedData[tostring((self.showdata[(a1:getIdx()+1)].cid or "")..(self.showdata[(a1:getIdx()+1)].iid or ""))] = self.showdata[(a1:getIdx()+1)]
                elseif self.maxNum > 1 then
                    -- print("touch33333",self.uplevel1,self.infodata.maxlv1)

                    if table.getTableLength(self.selectedData) >= self.maxNum then
                        -- print("touch6666")
                        runGamePrompt({msg = "最多可选"..self.maxNum.."个"})
                    elseif self.uplevel1 >= self.infodata.maxlv1 then
                        -- print("touch44444")
                        runGamePrompt({msg = "强化等级已达上限"})
                    elseif table.getTableLength(self.selectedData) < self.maxNum then
                        -- print("touch55555")
                        self.selectedData[tostring((self.showdata[(a1:getIdx()+1)].cid or "")..(self.showdata[(a1:getIdx()+1)].iid or ""))] = self.showdata[(a1:getIdx()+1)]
                    end
                end
            end
            self:setSelectNum()
            self.treasureListTableView:reloadData()

            self:setexp_up()
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

function qiankunluselect.setexp_up(self)
    -- print("setexp_up====")
    -- printT(self.selectedData)

    local equipconfig = gamedata.config.equip
    local expconfig = gamedata.config.treasure2_strengthen
    -- print("infodata===")
    -- printT(self.infodata)
    self.uplevel1 = self.infodata.level1 or 1
    self.upexp = self.infodata.exp or 0

    if self.uplevel1 < self.infodata.maxlv1 then

        for k,v in pairs(self.selectedData) do
            local exp = 0
            for i = 1,v.level1 do
                exp = exp + expconfig[tostring(i)]["quality"..v.quality]
            end
            self.upexp = self.upexp + (equipconfig[tostring(v.cid)].exp or 0) + exp
        end

        while self.upexp >= expconfig[tostring(self.uplevel1+1)]["quality"..self.infodata.quality] do
            self.upexp = self.upexp - expconfig[tostring(self.uplevel1+1)]["quality"..self.infodata.quality]
            self.uplevel1 = self.uplevel1 + 1
            if self.uplevel1 >= self.infodata.maxlv1 then break end
        end

    end
    -- print("self.uplevel1==",self.uplevel1,self.infodata.maxlv1)

end


return qiankunluselect
