--
-- Author: songyibo
-- Date: 2018-09-26 15:07:27
--

local cp_tigerchickenshop = {
    rewardCellSize = {x=900, y=280},

    resource = nil,

    rootNode = nil,
    rootItems = nil,
    rewardListTableView = nil,

    rewards = {},
    rewardData = {},
    myData = {},

    cpnum = 0,
    cpday = 0,

    isscrolltouched = false,
}

function cp_tigerchickenshop.open(self,touchPriority,data,callback)
    self.touchPriority = touchPriority

    self.rootNode,self.rootItems = CCBReaderLoad("activitytigerchicken/tigerchicken_duihuanNew", nil, true, "shop")

    --self.rewards = gamedata.config.new_generals_exchange or {}
    --

    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
   
    	gameWindows:closeWindow("cp_tigerchickenshop")

    end,CCControlEventTouchUpInside)

    
    
    if data then
    	self:reloaddata(data)
    end

    UIRequest({type = 5020})
    return self.rootNode
end

function cp_tigerchickenshop.relaodpoint(self,data)
    self.myData = {point = data.points}
    ui.setLabelString(self.rootItems.pointnum,self.myData.point or 0,21)
    if  self.rewardListTableView then
        self.rewardListTableView:reloadData()
    end
end


function cp_tigerchickenshop.reloaddata(self,data)
    print("cp_tigerchickenshop.reloadrank==")

    if data then
        self.cpnum = data.cpnum or 0
        self.cpday = data.cpday or 0
        self.rewardData = data.data or {}
    else
        --return
    end

    --
    if self.cpnum > 0 then
        self.rewards = gamedata.config["new_generals_exchange_"..self.cpnum] or {}
    else
        self.rewards = gamedata.config.new_generals_exchange or {}
    end
    --

    if not self.rewardListTableView then
        self:createRewardList()
    else
        if self.rewardListTableView:getLuaContentOffsetY() < self.rootItems.rewardScroll:getContentSize().height - table.getTableLength(self.rewards)*self.rewardCellSize.y then
            self.rewardListTableView:setLuaContentOffset(0, self.rootItems.rewardScroll:getContentSize().height - table.getTableLength(self.rewards)*self.rewardCellSize.y)
        end
        self.rewardListTableView:reloadData()
    end

end


function cp_tigerchickenshop.createRewardList(self)
    local celldict = {}
    local rankListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.rewardCellSize.x, self.rewardCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("activitytigerchicken/cell_tigerchicken_shopNew.ccbi", nil, true, "tigerchicken_duihuan")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                --ui.tableviewAnimation(self.rewardListTableView,cellCCB,self.rewardCellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setone(self.rewards[tostring((a1+1)*2-1)],ccbDocumentControler,1)
            self:setone(self.rewards[tostring((a1+1)*2)],ccbDocumentControler,2)

            --if self.rewardListTableView then
                cellCCB:setPosition(self.rewardCellSize.x/2, 0)
            --end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.rewards)/2
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.rewardListTableView = ui.createLuaTableView({
        handle = rankListHandle,
        viewwidth = self.rootItems.rewardScroll:getContentSize().width,
        viewheight = self.rootItems.rewardScroll:getContentSize().height,
        dire = 1
    })
    self.rewardListTableView:setTouchPriority(self.touchPriority)
    self.rootItems.rewardScroll:addChild(self.rewardListTableView)
end


function cp_tigerchickenshop.setone(self,data,items,index)
    print("index==",index)
    -- printT(data)

    local key_Ex
    local icon_key
    local exchangeNum = 99999999
    if index == nil or index == 1 then
        key_Ex = ""
        icon_key = ""
    else
        key_Ex = "_1"
        icon_key = "_1"
    end


    if not data then
        return
    end

    if (data.limit and data.limit > 0) then
        items["changenum"..key_Ex]:setString("可兑换次数"..(data.limit-(self.rewardData[tostring(data.id)] or 0)))
    else
        items["changenum"..key_Ex]:setString("")
    end
    ui.setLabelString(items["changenum"..key_Ex],nil,13)

    if data.item and data.item ~= "" then
        local id1,num1 = ui.getIDandNUM(data.item)
        ui.setNewIconName(items,{cid = id1, num = num1},index-1)
        --
        items["in_button"..key_Ex]:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            ui.setPopwindowByCid(id1)
        end, CCControlEventTouchUpInside)
        items["in_button"..key_Ex]:setTouchPriority(self.touchPriority)
        --
    end

    if data.number and data.number ~= "" then
        items["pointnode"..key_Ex]:setVisible(true)
        local id1,num1 = ui.getIDandNUM(data.number)
        ui.setLabelString(items["pointnum"..key_Ex],num1,14)
        exchangeNum = exchangeNum > math.floor((self.myData.point or 0)/num1) and math.floor((self.myData.point or 0)/num1) or exchangeNum
    else
        items["pointnode"..key_Ex]:setVisible(false)
    end

    if data.num and data.num ~= "" then
        items["propnode"..key_Ex]:setVisible(true)
        local id1,num1 = ui.getIDandNUM(data.num)
        ui.setLabelString(items["propnum"..key_Ex],num1,14)
        ui.setNewIcon(items,{cid = id1},index-1)
        --
        items["i_button_"..(2*(index-1)+1)]:addHandleOfControlEvent(function()

        	if gameTouch.isScrollling then return end

            ui.setPopwindowByCid(id1)
        end, CCControlEventTouchUpInside)
        items["i_button_"..(2*(index-1)+1)]:setTouchPriority(self.touchPriority)
        --
    else
        items["propnode"..key_Ex]:setVisible(false)
    end

    --
    ui.setLabelString(items["buttontext"..key_Ex],nil,18)


    items["button"..key_Ex]:setTouchPriority(self.touchPriority)
    items["button"..key_Ex]:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end

        gameTouch:clickprofbytime(1)
        --
        if (data.limit and data.limit > 0) and ((data.limit-(self.rewardData[tostring(data.id)] or 0)) < exchangeNum) then
            exchangeNum = data.limit-(self.rewardData[tostring(data.id)] or 0)
        end
        if (data.limit and data.limit > 0) and ((data.limit-(self.rewardData[tostring(data.id)] or 0)) <= 0) then
            runGamePrompt({msg = "兑换次数不足"})
        else
            local cb = function( num )
                UIRequest({type = 5023, pos = data.id,num = num})
            end
            ui.exchangeMore(cb,exchangeNum)
        end

    end, CCControlEventTouchUpInside)


    if (data.limit and data.limit > 0) and ((data.limit-(self.rewardData[tostring(data.id)] or 0)) <= 0) then
        ui.addGray("CCControlButton",items["button"..key_Ex])
    else
        ui.removeGray("CCControlButton",items["button"..key_Ex])
    end

end



function cp_tigerchickenshop.close(self)


    self.rewards = {}
    self.rewardData = {}
    self.myData = {}

    self.rewardListTableView = nil

    if self.rootNode then
        self.rootNode:removeAllChildrenWithCleanup(true)
        self.rootNode:removeFromParentAndCleanup(true)
        self.rootNode = nil
        self.rootItems = nil
    end

end


return cp_tigerchickenshop

   �  