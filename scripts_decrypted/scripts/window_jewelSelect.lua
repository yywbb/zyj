--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/6/6
-- Time: 14:33
-- To change this template use File | Settings | File Templates.
--


local jewelSelect = {
    rootNode = nil,
    rootItems = nil,
    pageconfig = {"attack","defence","life","skill"},
    selectpage = 1,
    CellSize = {x=924,y=228},
    jewelGoId = {120001,120101,120201,120301},
    canTouch = false,
}

function jewelSelect.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("duanzaoshenqi/tc_baoshixiangqian", nil, true, "tc_baoshixiangqian")
    self:initFixedString()
    self.rootItems.jewelGo:setVisible(false)
    --
    self.touchPriority = touchPriority
    --
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("jewelSelect")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    --
    self.rootItems.goToCast:addHandleOfControlEvent(function()
        local cid = self.jewelGoId[self.selectpage]
        gameWindows:openWindow("dropTips",{cid = cid},nil)
    end, CCControlEventTouchUpInside)
    self.rootItems.goToCast:setSwallowsTouch(true)
    self.rootItems.goToCast:setTouchPriority(self.touchPriority - 1)
    --
    for i = 1, 4 do
        self.rootItems["tabbutton"..i]:addHandleOfControlEvent(function ()
            if self.canTouch then
                self:shiftPage(i)
            end
        end,CCControlEventTouchUpInside)
        self.rootItems["tabbutton"..i]:setSwallowsTouch(true)
        self.rootItems["tabbutton"..i]:setTouchPriority(self.touchPriority)
    end
    
    self:initData(data)
    self:reloadData()
    return self.rootNode
end

function jewelSelect.setButtonState(self,pos)
    for i = 1,4 do
        self.rootItems["tabbutton"..i]:setTouchEnabled(pos ~= i)
        local setSp = pos == i and gameConfig.images.pageButtonON or gameConfig.images.pageButtonOFF
        setSpriteFrameByName(self.rootItems["tabon"..i], setSp)
    end
end

function jewelSelect.initData(self,data)
    self.data = data
    self.excTabel = {}
    self.selectJewel = nil
    self.selectItem = nil
    for i = 1,4 do
        if self.data.artifact["jewel"..i] > 0 then
            local jewelType = gamedata.config.trump_gem[tostring(self.data.artifact["jewel"..i])].type
            self.excTabel[jewelType] = true
        end
    end
    for i = 1,4 do
        if not self.excTabel[i] then
            self.selectpage = i
            break
        end
    end
end

function jewelSelect.shiftPage(self,type)
    self.selectpage = type or self.selectpage
    self:setButtonState(self.selectpage)
    self.rootItems.jewelGo:setVisible(false)
    if #self.jewelDatas[self.pageconfig[self.selectpage]] <= 0 then
        self.rootItems.jewelGo:setVisible(true)
    end
    
    if not self.ListTableView then
        self:createList()
    else
        self.ListTableView:setLuaContentOffset(0, self.rootItems.listscroll:getContentSize().height - (#self.jewelDatas[self.pageconfig[self.selectpage]])*self.CellSize.y)
        self.ListTableView:reloadData()
    end
end

function jewelSelect.initFixedString(self)
    --ui.setLabelString(self.rootItems.doLab,gameConfig.strings:string_common("artifact",6),19)
    self.rootItems.fixed1:setString(gameConfig.strings:string_common("artifact",11))
    self.rootItems.tablab1:setString(gameConfig.strings:string_common("attr_type","atk"))
    self.rootItems.tablab2:setString(gameConfig.strings:string_common("attr_type","def"))
    self.rootItems.tablab3:setString(gameConfig.strings:string_common("attr_type","hp"))
    self.rootItems.tablab4:setString(gameConfig.strings:string_common("fixedString","general",1))
end

function jewelSelect.setlistCell(self,items,data)
    ui.setNewIcon(items,{cid = data.cid},0)
    
    local config =  gamedata.config.trump_gem[tostring(data.cid)]
    --items.name:setString(config.name)
    if config.quality >= 7 then
        ui.setLabelString(items.name,config.name,213)
    else
        ui.setLabelString(items.name,config.name,((config.quality and config.quality ~= 0) and config.quality or 1)*2 - 1)
    end
    ui.setAttrStr(items["attr"],data)
    items.fixed1:setVisible(self.excTabel[config.type])
    items.btnNode:setVisible(not self.excTabel[config.type])
    --
    if data.num > 0 then
        ui.setLabelString(items.doLab,gameConfig.strings:string_common("artifact",6),19)
        setControlButtonFrame(items.button1,"b_n_button1","b_n_button1","b_n_button1")

        ui.removeGray("CCSprite", items["i_quality"])
        ui.removeGray("CCSprite", items["i_icon"])
        ui.removeGray("CCSprite", items["i_k_quality"])
    else
        ui.setLabelString(items.doLab,gameConfig.strings:string_common("ui",19),19)
        setControlButtonFrame(items.button1,"b_n_button2","b_n_button2","b_n_button2")

        ui.addGray("CCSprite", items["i_quality"])
        ui.addGray("CCSprite", items["i_icon"])
        ui.addGray("CCSprite", items["i_k_quality"])
    end
    
    items.button1:addHandleOfControlEvent(function()
        if data.num > 0 then
            local config = gamedata.config.trump_gem[tostring(data.cid)]
            if GameScene.roleinfo.level < config.gem_lvbet then
                return runGamePrompt({msg = gameConfig.strings:string_format({"artifact",101},{config.gem_lvbet})})
            end
            gameWindows:closeWindow("jewelSelect")
            gameTouch:clickprofbytime(0.5)
            UIRequest({type = 5505,iid = self.data.artifact.iid,jewelCid = data.cid,pos = self.data.pos})
        else
            gameWindows:openWindow("dropTips",{cid = data.cid},nil)
        end
    end, CCControlEventTouchUpInside)
    items.button1:setSwallowsTouch(true)
    items.button1:setTouchPriority(self.touchPriority - 1)
end



function jewelSelect.createList(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.CellSize.x, self.CellSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("duanzaoshenqi/cell_baoshixiangqan", nil, true, "cell_baoshixiangqan")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                cellCCB:setPosition(self.CellSize.x/2, 0)
                self:initCellFixedString(ccbDocumentControler)
                a2:addChild(cellCCB)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            self:setlistCell(ccbDocumentControler,self.jewelDatas[self.pageconfig[self.selectpage]][a1 + 1])
            r = a2

        elseif fn == "numberOfCells" then
            r = #self.jewelDatas[self.pageconfig[self.selectpage]]
        elseif fn == "cellTouched" then

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

function jewelSelect.initCellFixedString(self,cellItems)
    cellItems.fixed1:setString(gameConfig.strings:string_common("artifact",16))
end


function jewelSelect.reloadData(self,data)
    if not GameScene.layers["artifactList"].module.jewelData then 
        GameScene:addUpdate(10031)
    end
    if GameScene:checkUpdate(10031) then
        return
    end
    self.jewelDatas = GameScene.layers["artifactList"].module.jewelData
    local sortFunc = function(a,b)
        return a.cid > b.cid
    end
    for i = 1,4 do
        table.sort(self.jewelDatas[self.pageconfig[i]],sortFunc)
    end
    self.canTouch = true
    self:shiftPage()
end


function jewelSelect.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)

    self.ListTableView = nil
    self.rootNode = nil
    self.rootItems = nil

    self.jewelDatas = nil
    self.canTouch = false
    if self.callback then
        self.callback()
    end
end

return jewelSelect »!  