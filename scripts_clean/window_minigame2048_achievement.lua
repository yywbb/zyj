
local game2048achievement = {
    rewardCellSize = {x=940, y=200},

    isscrolltouched = false,

    rootNode = nil,
    rootItems = nil,
    normaltableview = nil, 

    normaldata = {},
    activennum = 0,

    callback = nil,
}

function game2048achievement.open(self,touchPriority,data,callback)
    self.touchPriority = touchPriority

    self.callback = callback

    self.rootNode,self.rootItems = CCBReaderLoad("minigame/2048_chengjiu", nil, true, "2048_chengjiu")

    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
    	gameWindows:closeWindow("game2048achievement")
    end,CCControlEventTouchUpInside)

    --一键领取
    ui.setLabelString(self.rootItems.allbuttontext, nil, 19)
    self.rootItems.allbutton:setTouchPriority(self.touchPriority)
    self.rootItems.allbutton:setSwallowsTouch(true)
    self.rootItems.allbutton:addHandleOfControlEvent(function()
        if self.activennum > 0 then
            UIRequest({type = 1606})
        else
            -- runGamePrompt({msg = "无可领取的奖励"})
            runGamePrompt({msg = gameConfig.strings:string_common("task",3)})
        end
    end,CCControlEventTouchUpInside)

    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","game2048achievement",touchbegin)
    local function touchend(pos)
        if self.rootItems.listnode and ui.isTouched(self.rootItems.listnode, pos.x, pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","game2048achievement",touchend)

    UIRequest({type = 1605})

    return self.rootNode
end

function game2048achievement.reloadData(self,data)
    local oldnumnormal = table.getTableLength(self.normaldata)

    self.normaldata = {}
    self.activennum = 0
    for k,v in pairs(data.tasks) do
        table.insert(self.normaldata,v)
        if v.status == 1 then self.activennum = self.activennum + 1  end
    end
    local sortbyid = function(a,b) return a.status == b.status and a.cid< b.cid or a.status > b.status end
    table.sort(self.normaldata,sortbyid)

    local newnumnormal = table.getTableLength(self.normaldata)
    if self.normaltableview then
        self.normaltableview:reloadData()
        self.normaltableview:setLuaContentOffset(0, self.normaltableview:getLuaContentOffsetY() - (newnumnormal - oldnumnormal)*self.rewardCellSize.y)
    else
        self:createRewardList()
    end

    if self.activennum > 0 then
        ui.removeGray("CCControlButton",self.rootItems.allbutton)
    else
        ui.addGray("CCControlButton",self.rootItems.allbutton)
    end
end

function game2048achievement.createRewardList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("minigame/cell_2048_chengjiu", nil, true, "cell_2048_chengjiu")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                --ui.tableviewAnimation(self.normaltableview,cellCCB,self.rewardCellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCell(ccbDocumentControler,self.normaldata[a1+1])

            cellCCB:setPosition(self.rewardCellSize.x/2, 0)

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.normaldata)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.normaltableview = ui.createLuaTableView({
        handle = rankListHandle,
        viewwidth = self.rootItems.listnode:getContentSize().width,
        viewheight = self.rootItems.listnode:getContentSize().height,
        dire = 1
    })
    self.normaltableview:setTouchPriority(self.touchPriority+1)
    self.rootItems.listnode:addChild(self.normaltableview)
end

function game2048achievement.setCell(self,item,data)
    local config = gamedata.config.task_2048[tostring(data.cid)]
    local rewards = ui.getIDandNUMs(config.reward)
    for i=1,#rewards do
        if rewards[i] then
            item["reward"..i]:setVisible(true)
            ui.setNewIcon(item, {cid = rewards[i].cid, num = rewards[i].num}, i-1)
            local key_Ex
            if i == 1 then
                key_Ex = ""
            else
                key_Ex = "_"..i
            end
            item["i_button"..key_Ex]:setTouchPriority(self.touchPriority)
            item["i_button"..key_Ex]:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                if gameTouch.isScrollling then return end
                ui.setPopwindowByCid(rewards[i].cid)
            end, CCControlEventTouchUpInside)
        else
            item["reward"..i]:setVisible(false)
        end
    end

    item.desc:setString(config.desc)
    item.attr:setPositionX(item.desc:getPositionX()+item.desc:getContentSize().width + 20)
    item.attr:setString("("..data.now.."/"..config.target..")")

    item.nonenode:setVisible(false)
    item.hasnode:setVisible(false)
    item.doNode:setVisible(false)
    if data.status == 0 then --未达成
        item.nonenode:setVisible(true)
    elseif data.status == 1 then
        item.doNode:setVisible(true)
        -- ui.setLabelString(item.buttontext, "领 取" ,18)
        ui.setLabelString(item.doLab, gameConfig.strings:string_common("moreCommon",6), 18)
        item.doButton:setTouchPriority(self.touchPriority)
        item.doButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            UIRequest({type = 1606, id = data.cid})
        end, CCControlEventTouchUpInside)
    else --已领取
        item.hasnode:setVisible(true)
    end
    
end

function game2048achievement.close(self)
    gameTouch:UnrigistFunc("begin","game2048achievement")
    gameTouch:UnrigistFunc("end","game2048achievement")

    self.normaltableview = nil

    if self.rootNode then
        self.rootNode:removeAllChildrenWithCleanup(true)
        self.rootNode:removeFromParentAndCleanup(true)
        self.rootNode = nil
        self.rootItems = nil
    end

    if self.callback then
        self.callback()
    end

end

return game2048achievement