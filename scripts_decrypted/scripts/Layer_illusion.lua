

local huanhuaList = {

    rootNode = nil,
    rootItems = nil,
    data = nil,
    normalCellSize = {x=1080,y=252},
    pageconfig = {"huanhua"},
    pagename = {gameConfig.strings:string_common("huanhua",1)},
    selectpage = "huanhua",
    ListTableView = nil,
    hintconfig = {
        {
            name = "rootItems",
            type = "self",
            config = {
            },
        },
    },
    touchPriority = -101,
    enter = false,
}

function huanhuaList.handleHint(self)
    self.IllsionHints = getIllsionFromSqlite()
    printT(self.IllsionHints)
    clearIllusionToSqlite()
end

function huanhuaList.init(self,parent,toppos)
    
    self:handleHint()

    self.rootNode,self.rootItems = CCBReaderLoad("huanhua/huanhuaList", nil, true, "huanhuaList")

    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)

    self.rootItems.listNode:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-130))

    ui.setLabelString(self.rootItems.tipLab,nil,19,55)

    self.rootItems.ruleBtn:addHandleOfControlEvent(function()
        ui.popCommonRule(599,"huanhua/ruleText")
    end, CCControlEventTouchUpInside)
    self.rootItems.ruleBtn:setSwallowsTouch(true)
    self.rootItems.ruleBtn:setTouchPriority(self.touchPriority)
    
    self.selectpage = self.selectpage or "huanhua"
    -- self:shiftPage(self.selectpage)
    UIRequest({type = 8110})
    UIRequest({type = 8252, page = 1})
end

function huanhuaList.shiftPage(self,type)
    -- self.selectpage = type
    -- if type == "huanhua" then
    --     UIRequest({type = 8110})
    -- end
end

function huanhuaList.reloaddata(self,data)
    if data then
        self.data = data
    end

    if GameScene.layers["illusion"].show then
        self:updateUi()
    end
end


function huanhuaList.updateUi(self)

    self.rootItems.tipNode:setVisible(table.getTableLength(self.data) == 0)
    if not self.ListTableView then
        self:createList()
    else
        self.ListTableView:reloadData()
    end
end

function huanhuaList.createList(self)
    print("createList")

    local celldict = {}
    local unrecycleCell = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("huanhua/cell_huanhua", nil, true, "cell_huanhua")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.ListTableView,cellCCB,self.normalCellSize.x/2,0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCell(ccbDocumentControler,a1+1)

            if self.ListTableView then
                cellCCB:setPosition(self.normalCellSize.x/2, 0)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.data)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listNode:getContentSize().width,
        viewheight = self.rootItems.listNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.listNode:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(self.touchPriority)
end

function huanhuaList.setCell(self,items,index)
    local data = self.data[tostring(index)]

    local endtime = os.date("*t", data.endtime - 1)
    items.time:setString(string.format(gameConfig.strings:string_common("huanhua",9), endtime.month,endtime.day,24))

    local illusionConfig = gamedata.config.illusion[tostring(data.cid)]
    local illusionGeneralConfig = gamedata.config.general[tostring(illusionConfig.general_id)]

    if data.general and data.general.illusionGeneralCid then

        illusionGeneralConfig = gamedata.config.general[tostring(data.general.illusionGeneralCid)]
        items.resNode:setVisible(true)
        items.name1:setVisible(false)
        items.infoNode:setVisible(true)

        local generalConfig = gamedata.config.general[tostring(data.general.cid)]
        -- 设置头像
        ui.setNewIcon(items, {cid = data.general.cid})
        local gdata = ui.getConfigGeneralSion(data.general)
        if next(gdata) and illusionGeneralConfig.fashion_id == 0 then --非时装
            ui.setNewIcon(items, {cid = data.cid,icon = illusionGeneralConfig.icon,quality = illusionGeneralConfig.quality} ,1, nil, gdata)
        else
            ui.setNewIcon(items, {cid = data.cid,icon = illusionGeneralConfig.icon,quality = illusionGeneralConfig.quality} ,1)
        end

        if illusionGeneralConfig.quality and illusionGeneralConfig.quality >= 7 then
            ui.setLabelString(items["name2"],illusionGeneralConfig.name,213)
        else    
            ui.setLabelString(items["name2"],illusionGeneralConfig.name,((illusionGeneralConfig.quality and illusionGeneralConfig.quality ~= 0) and illusionGeneralConfig.quality or 1)*2-1)
        end
        items.desc:setString(string.format(gameConfig.strings:string_common("huanhua",6), generalConfig.name))
        items.attr:setString(data.general.illusion.attrWeaken > 0 and (gameConfig.strings:string_common("huanhua",7)..data.general.illusion.attrWeaken.."%") or "")
        ui.setLabelString(items.doLab, gameConfig.strings:string_common("huanhua",8), 18)

        items["i_button"]:addHandleOfControlEvent(function()
            
        end, CCControlEventTouchUpInside)
        items["i_button"]:setTouchPriority(self.touchPriority - 1)
    else

        items.resNode:setVisible(false)
        items.name1:setVisible(true)
        items.infoNode:setVisible(false)


        if illusionGeneralConfig.quality and illusionGeneralConfig.quality >= 7 then
            ui.setLabelString(items["name1"],illusionConfig.name,213)
        else    
            ui.setLabelString(items["name1"],illusionConfig.name,((illusionGeneralConfig.quality and illusionGeneralConfig.quality ~= 0) and illusionGeneralConfig.quality or 1)*2-1)
        end

        ui.setNewIcon(items, {cid = data.cid})
        ui.setLabelString(items.doLab, gameConfig.strings:string_common("huanhua",1), 18)

        items["i_button"]:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            ui.setPopwindowByCid(data.cid)
        end, CCControlEventTouchUpInside)
        items["i_button"]:setTouchPriority(self.touchPriority - 1)
    end


    items.doButton:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        if not data.general then
            --幻影对应的伙伴不能已存在幻化关系
            for k,v in pairs(self.data) do
                if v.general and (v.general.illusion.orange_id == illusionGeneralConfig.general_id)  then
                    runGamePrompt({msg = gameConfig.strings:string_common("huanhua",15)})
                    return
                end
            end


            local cb = function (select)
                printT(select,"select")
                for k,v in pairs(select) do
                    self.IllsionHints[data.cid] = nil
                    UIRequest({type = 8111,illusionIid = data.cid,generalIid = v.iid})
                end
                
            end
            gameWindows:openWindow("selectlist",{type = "illusion", param = {cid = data.cid, opt = 2}},cb)
        else

            UIRequest({type = 8112,illusionIid = data.cid,generalIid = data.general.iid})
        end
        
    end, CCControlEventTouchUpInside)
    items.doButton:setSwallowsTouch(true)
    items.doButton:setTouchPriority(self.touchPriority - 1)
    
    if self.IllsionHints[data.cid] and self.IllsionHints[data.cid].endtime > gamedata:time() and (not data.general) then
        ui.sethint(items.hintnode,true)
    else
        ui.sethint(items.hintnode,false)
    end
    
end

function huanhuaList.clear(self)
    self.rootItems = nil
    self.ListTableView = nil
    self.selectpage = "huanhua"
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end


return huanhuaList
d#  