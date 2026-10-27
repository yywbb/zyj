--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-9
-- Time: 下午6:52
-- To change this template use File | Settings | File Templates.
--

local equipsResolveList = {

    resource = nil,


    rootNode = nil,
    rootItems = nil,
    ListTableView = nil,

    Selected = {},
    selectedPage = nil,
    allSelect = false,

    showData = nil,
    star2Data = nil,
    star3Data = nil,
    star4Data = nil,
    star5Data = nil,

    typeconfig = {"star2","star3","star4","star5"},

    pageconfig = {"star2","star3","star4","star5"},
    -- pagename = {"绿色","蓝色","紫色","橙色",},
    pagename = {gameConfig.strings:string_common("equipResolve",0),gameConfig.strings:string_common("equipResolve",1),gameConfig.strings:string_common("equipResolve",2),gameConfig.strings:string_common("equipResolve",3),},
    selectpage = "star2",

    normalCellSize = {x=1080,y=242},
}

function equipsResolveList.shiftPage(self,type)
    self.selectedPage = type
    self.selectpage = type
    self.showData =  self[type.."Data"]


    self.Selected = {}
    self.allSelect = false
    -- self.rootItems.allText:setString("全选")
    self.rootItems.allText:setString(gameConfig.strings:string_common("equipResolve",4))
    self.rootItems.allSelect:setVisible(false)

    if self.ListTableView then
        self.ListTableView:setLuaContentOffset(0, self.rootItems.listScroll:getContentSize().height - table.getTableLength(self.showData)*242)
        self.ListTableView:reloadData()
    end

end

function equipsResolveList.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("equip_new/equipDisapart", nil, true, "equipDisapart")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.toptitle:setPositionY(toppos)

    self.rootItems.listScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.labelnodeheight-130))


    -- ui.setLabelString(self.rootItems.noText,"返 回",18)
    -- ui.setLabelString(self.rootItems.yesText,"确 定",18
    ui.setLabelString(self.rootItems.noText,gameConfig.strings:string_common("buttontext","fanhui"),18)
    ui.setLabelString(self.rootItems.yesText,gameConfig.strings:string_common("buttontext","queding"),18)
    self.rootItems.yesButton:setTouchPriority(-102)
    self.rootItems.yesButton:addHandleOfControlEvent(function()
        if table.getTableLength(self.Selected) > 0 then
            gameTouch:clickprofbytime(1)
            local ids = {}
            for k,v in pairs(self.Selected) do
                table.insert(ids,v)
            end
            UIRequest({type = 1104, ids = ids})
            gamedata.music:PlayOptSound("fj")
        else
            -- runGamePrompt({msg = "请选择需要分解的装备"})
            runGamePrompt({msg = gameConfig.strings:string_common("equipResolve",5)})
        end
    end, CCControlEventTouchUpInside)


    self.rootItems.allButton:setSwallowsTouch(true)
    self.rootItems.allButton:setTouchPriority(-102)
    self.rootItems.allButton:addHandleOfControlEvent(function()
        if table.getTableLength(self.showData) <= 0 then
            -- runGamePrompt({msg ="无装备可分解"})
            runGamePrompt({msg =gameConfig.strings:string_common("equipResolve",6)})
            return
        end

        self.Selected = {}
        if self.allSelect then
            self.allSelect = false
            self.rootItems.allText:setString(gameConfig.strings:string_common("equipResolve",4))
            self.rootItems.allSelect:setVisible(false)
        else
            self.allSelect = true
            self.rootItems.allText:setString("")
            self.rootItems.allSelect:setVisible(true)
            for k,v in pairs(self.showData) do
                if not self.Selected[v.iid] then
                    self.Selected[v.iid] = v.iid
                end
            end
        end
        self.ListTableView:reloadData()
    end, CCControlEventTouchUpInside)

    self.rootItems.noButton:setTouchPriority(-102)
    self.rootItems.noButton:addHandleOfControlEvent(function()
        --GameScene:shiftLayer("main")
        GameScene:shiftLayer("equips","down",{selectpage = param.selectpage,equipselectpage = param.equipselectpage})
    end, CCControlEventTouchUpInside)

    self.equips = param.equips
    self:ReloadData()
end

function equipsResolveList.clear(self)

    self.rootItems = nil
    self.ListTableView = nil
    self.Selected = {}
    self.selectedPage = nil
    self.selectpage = nil
    self.showData = nil
    self.star2Data = nil
    self.star3Data = nil
    self.star4Data = nil
    self.star5Data = nil

    self.allSelect = false
    self.selectpage = "star2"

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function equipsResolveList.setNormal(self,item,data,sid)
    print("equipsResolveList.setNormal")

    ui.setIconLv(item,data)

    local config =  gamedata.config.equip[tostring(data.cid)]
    ui.setLabelString(item.name,config.name..(data.level2>0 and "+"..data.level2 or ""), config.quality and 2*config.quality-1 or 1)

    item.isSelect:setVisible(not not self.Selected[data.iid])

    ui.setEquipPromote(item["att1"],item["att2"],data)
end

function equipsResolveList.createEquipsList(self)
    local celldict = {}
    local equipsListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("equip_new/cell_equipselect", nil, true, "cell_equipselect")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setNormal(ccbDocumentControler,self.showData[a1+1],a1+1)

            cellCCB:setPosition(self.normalCellSize.x/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.showData)
        elseif fn == "cellTouched" then
            if self.Selected[self.showData[a1:getIdx()+1].iid] then
                self.Selected[self.showData[a1:getIdx()+1].iid] = nil
            else
                self.Selected[self.showData[a1:getIdx()+1].iid] = self.showData[a1:getIdx()+1].iid
            end

            self.ListTableView:reloadData()
        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = equipsListHandle,
        viewwidth = self.rootItems.listScroll:getContentSize().width,
        viewheight = self.rootItems.listScroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.listScroll:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(-101)
end



function equipsResolveList.ReloadData(self,data)
    print("equipsResolveList.ReloadData")
    if data then self.equips = data end

    if not GameScene:checkUpdate(10025,"equips") then
        self.showData = {}
        self.star2Data = {}
        self.star3Data = {}
        self.star4Data = {}
        self.star5Data = {}
        self.Selected = {}

        if not self.equips or table.getTableLength(self.equips) ==0 then
        else
            for i=1, table.getTableLength(self.equips) do
                if self.equips[tostring(i)].generalcid and  self.equips[tostring(i)].generalcid > 0 then
                else
                    table.insert(self["star"..gamedata.config.equip[tostring(self.equips[tostring(i)].cid)]["quality"].."Data"],self.equips[tostring(i)])
                end
            end
        end


        local def = "star5"
        if table.getTableLength(self.star2Data) > 0 then
            def = "star2"
        elseif table.getTableLength(self.star3Data) > 0 then
            def = "star3"
        elseif table.getTableLength(self.star4Data) > 0 then
            def = "star4"
        end

        self.showData = self[(self.selectedPage or def).."Data"]
        self.selectedPage = self.selectedPage or def

        if self.rootItems then
            if not self.ListTableView then
                self:createEquipsList()
            else
                self.ListTableView:reloadData()
            end
            self:shiftPage(self.selectedPage)
        end

    end
end


return equipsResolveList
