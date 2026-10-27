--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/10/25
-- Time: 上午10:33
-- To change this template use File | Settings | File Templates.
--

local soullist = {

    resource = nil,


    rootNode = nil,
    rootItems = nil,

    pageconfig = {"star2","star3","star4","star5" } ,
    -- pagename = {"绿色","蓝色","紫色","橙色"},
    pagename = {gameConfig.strings:string_common("soulResolve",0),gameConfig.strings:string_common("soulResolve",1),gameConfig.strings:string_common("soulResolve",2),gameConfig.strings:string_common("soulResolve",3)},
    selectpage = "star2",

    ListTableView = nil,

    Selected = {},

    showData = nil,
    star2Data = nil,
    star3Data = nil,
    star4Data = nil,
    star5Data = nil,

    normalCellSize = {x=1080,y=242},
}

function soullist.shiftPage(self,type)
    self.selectpage = type
    self.showData =  self[type.."Data"]

    self.Selected = {}
    if self.rootItems.allSelect then
        self.rootItems.allSelect:setVisible((table.getTableLength(self.Selected) > 0) and (table.getTableLength(self.Selected) >= table.getTableLength(self.showData)))
    end
    self.ListTableView:setLuaContentOffset(0, self.rootItems.listScroll:getContentSize().height - table.getTableLength(self.showData)*242)
    self.ListTableView:reloadData()
end

function soullist.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("soul/soulDisapart", nil, true, "soulDisapart")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.toptitle:setPositionY(toppos)

    self.rootItems.listScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.labelnodeheight-130))

    ui.setLabelString(self.rootItems.allText,nil,14)
    -- ui.setLabelString(self.rootItems.noText,"返 回",18)
    ui.setLabelString(self.rootItems.noText,gameConfig.strings:string_common("moreCommon","fanhui"),18)
    self.rootItems.yesButton:setTouchPriority(-111)
    self.rootItems.yesButton:setSwallowsTouch(true)
    self.rootItems.yesButton:addHandleOfControlEvent(function()
        if table.getTableLength(self.Selected) > 0 then
            local ids = {}
            for k,v in pairs(self.Selected) do
                table.insert(ids,v)
            end
            gameTouch:clickprofbytime(1)
            UIRequest({type = 2506, ids = ids})
            gamedata.music:PlayOptSound("fj")
        else
            -- runGamePrompt({msg = "请选择需要分解的命格"})
            runGamePrompt({msg = gameConfig.strings:string_common("soulResolve",4)})
        end
    end, CCControlEventTouchUpInside)

    self.rootItems.allButton:setSwallowsTouch(true)
    self.rootItems.allButton:setTouchPriority(-111)
    self.rootItems.allButton:addHandleOfControlEvent(function()
        if table.getTableLength(self.showData) <= 0 then
            -- runGamePrompt({msg ="无命格可分解"})
            runGamePrompt({msg =gameConfig.strings:string_common("soulResolve",5)})
            return
        end

        if table.getTableLength(self.Selected) == table.getTableLength(self.showData) then
            self.Selected = {}
        else
            for k,v in pairs(self.showData) do
                if not self.Selected[v.iid] then
                    self.Selected[v.iid] = v.iid
                end
            end
        end

        if self.rootItems.allSelect then
            self.rootItems.allSelect:setVisible((table.getTableLength(self.Selected) > 0) and (table.getTableLength(self.Selected) >= table.getTableLength(self.showData)))
        end
        self.ListTableView:reloadData()
    end, CCControlEventTouchUpInside)

    -- ui.setLabelString(self.rootItems.yesText,"确 定",18)
    ui.setLabelString(self.rootItems.yesText,gameConfig.strings:string_common("moreCommon","queding"),18)
    self.rootItems.noButton:setTouchPriority(-111)
    self.rootItems.noButton:setSwallowsTouch(true)
    self.rootItems.noButton:addHandleOfControlEvent(function()
        GameScene:shiftLayer("soul","down",{page = "list"})
    end, CCControlEventTouchUpInside)


    self.souls = param and param.souls or GameScene.layers.soul.module.listallData
    self:ReloadData()
end

function soullist.clear(self)

    self.rootItems = nil
    self.ListTableView = nil
    self.Selected = {}
    self.selectpage = nil
    self.showData = nil
    self.star2Data = nil
    self.star3Data = nil
    self.star4Data = nil
    self.star5Data = nil

    self.selectpage = "star2"
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function soullist.setNormal(self,item,data,sid)

    item.isSelect:setVisible(not not self.Selected[data.iid])

    ui.setIconLv(item,data)
    local config =  gamedata.config.soul[tostring(data.cid)]
    ui.setLabelString(item.name,config.name, config.quality and 2*config.quality-1 or 1)

    ui.setSoulPromote(item["att1"],item["att2"],data)
end



function soullist.createsoullist(self)
    local celldict = {}
    local soullistHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("soul/cell_soulselect", nil, true, "cell_soulselect")
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

            if self.rootItems.allSelect then
                self.rootItems.allSelect:setVisible((table.getTableLength(self.Selected) > 0) and (table.getTableLength(self.Selected) >= table.getTableLength(self.showData)))
            end

            self.ListTableView:reloadData()
        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = soullistHandle,
        viewwidth = self.rootItems.listScroll:getContentSize().width,
        viewheight = self.rootItems.listScroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.listScroll:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(-101)
end


function soullist.ReloadData(self,data)

    if data then self.souls = data end

    if not GameScene:checkUpdate(10026,"all") then


        self.showData = {}
        self.star2Data = {}
        self.star3Data = {}
        self.star4Data = {}
        self.star5Data = {}
        self.Selected = {}

        if not self.souls or table.getTableLength(self.souls) ==0 then
        else
            for i=1, table.getTableLength(self.souls) do
                if self.souls[tostring(i)].generalcid and  self.souls[tostring(i)].generalcid > 0 then
                else
                    table.insert(self["star"..gamedata.config.soul[tostring(self.souls[tostring(i)].cid)]["quality"].."Data"],self.souls[tostring(i)])
                end
            end
        end


        local def = "star2"
        if table.getTableLength(self.star2Data) > 0 then
            def = "star2"
        elseif table.getTableLength(self.star3Data) > 0 then
            def = "star3"
        elseif table.getTableLength(self.star4Data) > 0 then
            def = "star4"
        end

        self.showData = self[(self.selectedPage or def).."Data"]
        self.selectpage = self.selectpage or def

        if self.rootItems then
            if not self.ListTableView then
                self:createsoullist()
            else
                self.ListTableView:reloadData()
            end
            self:shiftPage(self.selectpage)
        end

    end
end

function soullist.UIUpdateData(self, isreset)
    self:ReloadData()
end

return soullist  �"  