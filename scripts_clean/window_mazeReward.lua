--迷宫奖励
--zhangzhixin

local mazereward = {
    rootNode = nil,
    rootItems = nil,

	isloadReward = true,
	CellSize = {x= 930 ,y = 235}
}

function mazereward.open( self,touchPriority,data,callback )

    print("mazereward.open =========")
    printT(data)
    self.taskConfig = gamedata.config.maze_task
    printT(self.taskConfig)
    self.data = data
    self.rootNode, self.rootItems = CCBReaderLoad("migong/migong_jiangli", nil, true, "mazereward")

    self.touchPriority = touchPriority
    self.callback = callback

    if  self.rootItems.closeButton then
        self.rootItems.closeButton:addHandleOfControlEvent(function()
            gameWindows:closeWindow("mazereward")
        end, CCControlEventTouchUpInside)
        self.rootItems.closeButton:setSwallowsTouch(true)
        self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    end

    self:load(data)

    return self.rootNode
end

function mazereward.close(self )
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.isloadReward = false

    if self.callback then
        self.callback()
    end
end

function mazereward.load(self,aiData)
    self:createRewardList()
end


function mazereward.createRewardList(self)
    local celldict = {}
    local rewardListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.CellSize.x, self.CellSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("migong/cell_jiangli", nil, true, "cell_reward")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.rewardListTableView,cellCCB,self.CellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setReward(ccbDocumentControler,self.data[tostring(a1+1)] ,a1)
            if self.rewardListTableView then
                cellCCB:setPosition(self.CellSize.x/2, 0)
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

    self.rewardListTableView = ui.createLuaTableView({
        handle = rewardListHandle,
        viewwidth = self.rootItems.scrollnode:getContentSize().width,
        viewheight = self.rootItems.scrollnode:getContentSize().height,
        dire = 1
    })
    self.rootItems.scrollnode:addChild(self.rewardListTableView)
    self.rewardListTableView:setTouchPriority(self.touchPriority )	
end

function mazereward.setReward(self,aiItem,aiData,aiIndx)
    print("mazereward.setReward ===========")
    aiItem.descText:setString(aiData.desc)
    if aiData.state == 2 then
        aiItem.buttonNode:setVisible(false)
        aiItem.noneNode:setVisible(false)
        aiItem.getNode:setVisible(true)
        aiItem.getButton:setTouchEnabled(false)
    elseif aiData.state == 1 then
        aiItem.buttonNode:setVisible(true)
        aiItem.noneNode:setVisible(false)
        aiItem.getNode:setVisible(false)
        aiItem.getButton:setTouchEnabled(true)
    elseif aiData.state == 0 then
        aiItem.buttonNode:setVisible(false)
        aiItem.noneNode:setVisible(true)
        aiItem.getNode:setVisible(false)
        aiItem.getButton:setTouchEnabled(false)
    end
    for i = 1,5 do
        aiItem["item"..i]:setVisible(false)
    end    
    local t =  ui.Split( aiData.reward,";")
    for k,v in pairs(t) do
        if v ~= nil and v ~= "" then
            local temp = ui.Split( v,",")
            ui.setNewIcon(aiItem,{cid = tonumber(temp[1]),num = tonumber(temp[2]) },k-1)
            aiItem["item"..k]:setVisible(true)
        end
    end
    aiItem.getButton:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        print("领取奖励index = "..aiData.type .." id ="..aiData.id)
        UIRequest({type = 3809 ,index = aiData.type ,id = aiData.id })
    end, CCControlEventTouchUpInside)
    aiItem.getButton:setTouchPriority(self.touchPriority-1)    
end

function mazereward.reload( self,aiData )
    self.data = aiData
    self.rewardListTableView:reloadData()
end

return mazereward