--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/12/28
-- Time: 10:15
-- To change this template use File | Settings | File Templates.
--

local boxselect = {
    rootNode = nil,
    rootItems = nil,

    usenum = 1,
    hasnum = 0,
    choose = 0,

    propcids = {},
    isOnce = true,
    data = {},
    ListTableView = nil,

    normalCellSize = {x = 270,y = 400}
}

function boxselect.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("windows/tc_duocikaiqi", nil, true, "tc_duocikaiqi")

    self.touchPriority = touchPriority
    self.isOnce = true

    -- 添加输入数字功能 
    ui.creatInputEditBoxForNum(self.rootItems.inputNumNode,self.rootItems.usenum,touchPriority,function (num)
        self.usenum = 0
        self:numchange(num)
    end)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("boxselect")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.add1:addHandleOfControlEvent(function()
        self:numchange(1)
        self.isOnce = false
    end, CCControlEventTouchUpInside)
    self.rootItems.add1:setSwallowsTouch(true)
    self.rootItems.add1:setTouchPriority(self.touchPriority)

    self.rootItems.add10:addHandleOfControlEvent(function()
        self:numchange(10)
        self.isOnce = false
    end, CCControlEventTouchUpInside)
    self.rootItems.add10:setSwallowsTouch(true)
    self.rootItems.add10:setTouchPriority(self.touchPriority)

    self.rootItems.add100:addHandleOfControlEvent(function()
        self:numchange(100)
        self.isOnce = false
    end, CCControlEventTouchUpInside)
    self.rootItems.add100:setSwallowsTouch(true)
    self.rootItems.add100:setTouchPriority(self.touchPriority)


    self.rootItems.sub1:addHandleOfControlEvent(function()
        self:numchange(-1)
        self.isOnce = false
    end, CCControlEventTouchUpInside)
    self.rootItems.sub1:setSwallowsTouch(true)
    self.rootItems.sub1:setTouchPriority(self.touchPriority)

    self.rootItems.sub10:addHandleOfControlEvent(function()
        self:numchange(-10)
        self.isOnce = false
    end, CCControlEventTouchUpInside)
    self.rootItems.sub10:setSwallowsTouch(true)
    self.rootItems.sub10:setTouchPriority(self.touchPriority)

    self.rootItems.sub100:addHandleOfControlEvent(function()
        self:numchange(-100)
        self.isOnce = false
    end, CCControlEventTouchUpInside)
    self.rootItems.sub100:setSwallowsTouch(true)
    self.rootItems.sub100:setTouchPriority(self.touchPriority)


    -- ui.setLabelString(self.rootItems.doLab,"确 定",19)
    ui.setLabelString(self.rootItems.doLab,gameConfig.strings:string_common("popups","queding"),19)
    self.rootItems.doButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        if not (self.choose and tonumber(self.choose) > 0) then
            -- runGamePrompt({msg = "请选择一种获得物品"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","boxselect")})
        elseif self.usenum >0 then
            if self.usenum <= self.hasnum then
                UIRequest({type = 1201,cid = self.data.id, num = self.usenum, choose = self.choose})
            end

            gameWindows:closeWindowDirect("boxselect")

        else
            -- runGamePrompt({msg = "请选择数量"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","ch_num")})
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:setTouchPriority(self.touchPriority)

    self:reload(data,callback)

    return self.rootNode
end

function boxselect.setbuydata(self)
    self.rootItems.usenum:setString("x"..self.usenum)
end

function boxselect.numchange(self,num)
    if self.usenum == self.hasnum and self.usenum+num > self.hasnum then
        runGamePrompt({msg = gameConfig.strings:string_common("popups","boxopenmax")})
    end
    if self.usenum == 1 then
        if num == 10 and self.isOnce == true then
            self.usenum = 10
        else
            self.usenum = self.usenum + num
        end
    else
        self.usenum = self.usenum + num
    end

    if self.usenum > self.hasnum then
        self.usenum =  self.hasnum
    elseif self.usenum <= 0 then
        self.usenum = 0
    end
    self:setbuydata()
end

function boxselect.setPropdata(self)
    for i = 1,4 do
        if self.propcids[i] and self.propcids[i].cid and tonumber(self.propcids[i].cid) == tonumber(self.choose) then
            self.rootItems["select"..i]:setVisible(true)
        else
            self.rootItems["select"..i]:setVisible(false)
        end
    end
end

function boxselect.reload(self,data,callback)
    self.callback = callback

    if data then
        self.data = data
    end

    self.usenum = 1
    self.hasnum = self.data.num or 0
    self.choose = 0
    self.propcids = {}

    --
    local boxconfig = gamedata.config.props[tostring(self.data.id)] or {}
    if boxconfig["function"] and boxconfig["function"] == "box4" then
        self.propcids = ui.getIDandNUMs(boxconfig.param1)
    else
        self.propcids = ui.getGeneralID(boxconfig.param1)
    end    
    --
    -- for i = 1,4 do
    --     if self.propcids[i] and self.propcids[i].cid then
    --         self.rootItems["propnode"..i]:setVisible(true)
    --         ui.setNewIcon(self.rootItems,{cid = self.propcids[i].cid, num = self.propcids[i].num or 1},i-1)
    --         ui.setLabelString(self.rootItems["propname"..i],ui.IDconfig(self.propcids[i].cid).name or "",((ui.IDconfig(self.propcids[i].cid).quality and ui.IDconfig(self.propcids[i].cid).quality ~= 0) and ui.IDconfig(self.propcids[i].cid).quality or 1)*2)
    --         --
    --         self.rootItems["i_button"..(i<2 and "" or ("_"..(i-1)))]:addHandleOfControlEvent(function()
    --             ui.setPopwindowByCid(self.propcids[i].cid)
    --         end, CCControlEventTouchUpInside)
    --         self.rootItems["i_button"..(i<2 and "" or ("_"..(i-1)))]:setTouchPriority(self.touchPriority)
    --         --
    --         self.rootItems["selectButton"..i]:addHandleOfControlEvent(function()
    --             self.choose = self.propcids[i].cid or 0
    --             self:setPropdata()
    --         end, CCControlEventTouchUpInside)
    --         self.rootItems["selectButton"..i]:setSwallowsTouch(true)
    --         self.rootItems["selectButton"..i]:setTouchPriority(self.touchPriority-1)
    --     else
    --         self.rootItems["propnode"..i]:setVisible(false)
    --     end
    -- end


    if self.ListTableView then
        self.ListTableView:reloadData()
    else
        self:createList()
    end
    -- self:setPropdata()
    self:setbuydata()
end

function boxselect.setCell(self,items,index)


    ui.setNewIcon(items,{cid = self.propcids[index].cid, num = self.propcids[index].num or 1})

    ui.setLabelString(items.propname,ui.IDconfig(self.propcids[index].cid).name or "",((ui.IDconfig(self.propcids[index].cid).quality and ui.IDconfig(self.propcids[index].cid).quality ~= 0) and ui.IDconfig(self.propcids[index].cid).quality or 1)*2)


    items["i_button"]:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        if ui.IDconfig(self.propcids[index].cid).staffType == "token_fragment" then
            ui.setPopwindowByCid(self.propcids[index].cid,{cid = self.propcids[index].cid})
        else
            ui.setPopwindowByCid(self.propcids[index].cid)
        end
    end, CCControlEventTouchUpInside)
    items["i_button"]:setTouchPriority(self.touchPriority)
            --
    items["selectButton"]:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        self.choose = self.propcids[index].cid or 0
        self.ListTableView:reloadData()
    end, CCControlEventTouchUpInside)
    items["selectButton"]:setSwallowsTouch(true)
    items["selectButton"]:setTouchPriority(self.touchPriority-1)


    if self.choose and self.choose == self.propcids[index].cid then
        items.select:setVisible(true)
    else
        items.select:setVisible(false)
    end
end

function boxselect.createList(self)
    print("createList")
    printT(self.propcids,"self.propcids")
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("windows/cell_duocikaiqi", nil, true, "cell_duocikaiqi")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            -- self:setCell(ccbDocumentControler,self.data[a1+1],a1+1)
            self:setCell(ccbDocumentControler, a1+1)

            -- ccbDocumentControler:setPosition(0, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            -- r = table.getTableLength(self.data)
            r = table.getTableLength(self.propcids)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listnode:getContentSize().width,
        viewheight = self.rootItems.listnode:getContentSize().height,
        dire = 0
    })
    self.rootItems.listnode:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(self.touchPriority)
end


function boxselect.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.isOnce = true
    self.ListTableView = nil
    if self.callback then
        self.callback()
    end

end

return boxselect
  �(  