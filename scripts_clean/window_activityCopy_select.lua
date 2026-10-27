--活动副本的选择

local activityCopySelect = {
    rootNode = nil,
    rootItems = nil,

    selectData = {},
    activityListTableView = nil,
    CellSize = {x = 980,y = 240},
    bgindex = {"bgexp","bgcoin","bgFrogeStone","bgEquipStarStone","bgZhenfu","bgForging"},
    data = {},
    ccbDocument = {},
}

function activityCopySelect.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("copy2/tc_huodong_finish", nil, true, "tc_huodong_finish")
    self.touchPriority = touchPriority
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("activityCopySelect")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.oneFinishLab,nil,18)
    self.rootItems.oneFinishBtn:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        if self.selectData and next(self.selectData) then
            local isRequest = false
            for k,v in pairs(self.selectData) do
                if v.isSelect == 1 and v.usenum > 0 and v.openLevel == 1 then
                    isRequest = true
                    break
                end
            end
            if isRequest == true then
                UIRequest({type = 1348, data = self.selectData})
            else
                runGamePrompt({msg = "当前选择为空"})
            end
        else
            runGamePrompt({msg = "当前选择为空"})
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.oneFinishBtn:setSwallowsTouch(true)
    self.rootItems.oneFinishBtn:setTouchPriority(self.touchPriority)
    self:reload(data,callback)

    return self.rootNode
end

function activityCopySelect.reload(self,data,callback)
    self.callback = callback
    self.data = data
    for i,v in pairs(self.data) do
        local buynum = 0
        if tonumber(v["function"]) == 1 then
            buynum = GameScene.vipstatus.exp_copy_times
            v.isLevelOpen = 1
        elseif tonumber(v["function"]) == 2 then
            buynum = GameScene.vipstatus.coin_copy_times
            v.isLevelOpen = 1
        elseif tonumber(v["function"]) == 3 then
            buynum = GameScene.vipstatus.stone_copy_times
            if not GameScene:checkopenlevelbyId(173,true) then
                v.isLevelOpen = 0
            else
                v.isLevelOpen = 1
            end
        elseif tonumber(v["function"]) == 4 then
            buynum = GameScene.vipstatus.upstar_times
            if not GameScene:checkopenlevelbyId(206,true) then
                v.isLevelOpen = 0
            else
                v.isLevelOpen = 1
            end
        elseif tonumber(v["function"]) == 5 then
            buynum = GameScene.vipstatus.zhenfu_times
            if not GameScene:checkopenlevelbyId(207,true) then
                v.isLevelOpen = 0
            else
                v.isLevelOpen = 1
            end
        elseif tonumber(v["function"]) == 6 then
            buynum = GameScene.vipstatus.forging_copy_times
            if not GameScene:checkopenlevelbyId(389,true) then
                v.isLevelOpen = 0
            else
                v.isLevelOpen = 1
            end
        end
        v.maxnum = v.times - v.usedTimes + buynum
        if v.isLevelOpen and v.isLevelOpen == 0 then
            v.usenum = 0
            v.isVisible = 0
        else
            v.usenum = v.times - v.usedTimes + buynum
            v.isVisible = 1
        end
    end
    for i=1,table.getTableLength(self.data) do
        --print(i)
        self.selectData[i] = {}
        self.selectData[i].index = i
        if self.data[tostring(i)] then
            if self.data[tostring(i)].usenum > 0 and self.data[tostring(i)].isVisible == 1 then
                self.selectData[i].isSelect = 1
            else
                self.selectData[i].isSelect = 0
            end
            if self.data[tostring(i)].openLevel and self.data[tostring(i)].openLevel > 1 then
                self.selectData[i].openLevel = 1
            else
                self.selectData[i].openLevel = 0
            end
            self.selectData[i].id = self.data[tostring(i)].id
            self.selectData[i].maxnum = self.data[tostring(i)].maxnum
            self.selectData[i].usenum = self.data[tostring(i)].usenum

        end
    end

    if self.activityListTableView == nil then
        self:createActivityList()
    else
        self.activityListTableView:reloadData()
    end

end

--创建活动界面
function activityCopySelect.createActivityList( self )
    local celldict = {}
    local listHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.CellSize.x, self.CellSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("copy2/cell_finish_huodong", nil, true, "cell_finish_huodong")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.activityListTableView,cellCCB,self.CellSize.x/2, 0,a1)
          
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            self:setCell(ccbDocumentControler,self.data[tostring(a1 + 1)],a1+1)
            if self.activityListTableView then
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

    self.activityListTableView = ui.createLuaTableView({
        handle = listHandle,
        viewwidth = self.rootItems.listNode:getContentSize().width,
        viewheight = self.rootItems.listNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.listNode:addChild(self.activityListTableView)
    self.activityListTableView:setTouchPriority(self.touchPriority+1)
end

--设置金币cell
function activityCopySelect.setCell(self,aiCell,aiData,index)
    -- self.selectData[index] = {}
    -- self.selectData[index].index = index
    local fixstring = ""
    if tonumber(aiData["function"]) == 2 or tonumber(aiData["function"]) == 4 or tonumber(aiData["function"]) == 5 then
        fixstring = "需100%伤害"
    end 

    if aiData.isOpen == 1 then
        for i=1,6 do
            ui.removeGray("CCSprite",aiCell[self.bgindex[i]])
        end
        aiCell.times:setVisible(true)
        aiCell.timestext:setVisible(true)
        ui.setLabelString(aiCell.timestext,nil,22)
        
        if aiData.maxnum <= 0 then
            ui.setLabelString(aiCell.times,0,24) 
        else
            ui.setLabelString(aiCell.times,aiData.maxnum,22)
        end
        self.selectData[index].maxnum = aiData.maxnum
        self.selectData[index].usenum = aiData.usenum
        aiCell.usenum:setString(aiData.usenum)
        if aiData.usenum > 0 and aiData.isVisible == 1 then
            aiCell.isSelect:setVisible(true)
            self.selectData[index].isSelect = 1
        else
            aiCell.isSelect:setVisible(false)
            self.selectData[index].isSelect = 0
        end
    else
        for i=1,6 do
            ui.addGray("CCSprite",aiCell[self.bgindex[i]])
        end
        aiCell.times:setVisible(false)
        aiCell.timestext:setVisible(false)
        self.selectData[index].usenum = 0
        aiCell.isSelect:setVisible(false)
        self.selectData[index].isSelect = 0
    end
    
    if self.data[tostring(index)].isLevelOpen == 0 or self.data[tostring(index)].openLevel <= 1 then
        for i=1,6 do
            ui.addGray("CCSprite",aiCell[self.bgindex[i]])
        end
        aiCell.times:setVisible(false)
        aiCell.timestext:setVisible(false)
        self.selectData[index].usenum = 0
        aiCell.isSelect:setVisible(false)
        self.selectData[index].isSelect = 0

    end
    aiCell.selectButton:setTouchPriority(self.touchPriority)
    aiCell.selectButton:addHandleOfControlEvent(function()
        if gameTouch.isScrollling  then return end
        if aiData.isLevelOpen ~= 1 then
            runGamePrompt({msg = "当前未开启！！！"})
        elseif aiData.isOpen ~= 1 then
            runGamePrompt({msg = "明天就能打哦~"})
        elseif aiData.openLevel <= 1 then
            runGamePrompt({msg = fixstring.."通过关卡后才可以扫荡"})
        elseif self.selectData[index].usenum == 0 then
            runGamePrompt({msg = "请选择挑战次数"})
        else
            if self.selectData[index].isSelect == 0 then
                self.selectData[index].isSelect = 1
                self.data[tostring(index)].isVisible = 1
                aiCell.isSelect:setVisible(true)
            else
                self.selectData[index].isSelect = 0
                self.data[tostring(index)].isVisible = 0
                aiCell.isSelect:setVisible(false)
            end
        end
    end, CCControlEventTouchUpInside)

    for i=1,6 do
        if tonumber(aiData["function"]) == i then
            aiCell[self.bgindex[i]]:setVisible(true)
        else
            aiCell[self.bgindex[i]]:setVisible(false)
        end
    end

    aiCell.add1:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end 
        print("add1   ----")
        if aiData.isLevelOpen ~= 1 then
            runGamePrompt({msg = "当前未开启！！！"})
        elseif aiData.isOpen ~= 1 then
            runGamePrompt({msg = "明天就能打哦~"})
        elseif aiData.openLevel <= 1 then
            runGamePrompt({msg = fixstring.."通过关卡后才可以扫荡"})
        else
            if tonumber(aiData["function"]) == 1 then
                if self.selectData[index].usenum >= aiData.maxnum then
                    --runGamePrompt({msg = "您没有挑战次数了！"})
                    activityExpBuyTimes()
                else
                    self:numchange(aiCell,1,index)
                end
            elseif tonumber(aiData["function"]) == 2 then
                if self.selectData[index].usenum >= aiData.maxnum then
                    --runGamePrompt({msg = "您没有挑战次数了！"})
                    activityCoinBuyTimes()
                else
                    self:numchange(aiCell,1,index)
                end
            elseif tonumber(aiData["function"]) == 3 then
                if self.selectData[index].usenum >= aiData.maxnum then
                    --runGamePrompt({msg = "您没有挑战次数了！"})
                    activityForgeStoneBuyTimes()
                else
                    self:numchange(aiCell,1,index)
                end
            elseif tonumber(aiData["function"]) == 4 then
                if self.selectData[index].usenum >= aiData.maxnum then
                    --runGamePrompt({msg = "您没有挑战次数了！"})
                    activityEquipStarBuyTimes()
                else
                    self:numchange(aiCell,1,index)
                end
            elseif tonumber(aiData["function"]) == 5 then
                if self.selectData[index].usenum >= aiData.maxnum then
                    --runGamePrompt({msg = "您没有挑战次数了！"})
                    activityZhenfuBuyTimes()
                else
                    self:numchange(aiCell,1,index)
                end
            elseif tonumber(aiData["function"]) == 6 then
                if self.selectData[index].usenum >= aiData.maxnum then
                    --runGamePrompt({msg = "您没有挑战次数了！"})
                    activityForgingBuyTimes()
                else
                    self:numchange(aiCell,1,index)
                end

            end
        end
    end, CCControlEventTouchUpInside)
    aiCell.add1:setSwallowsTouch(true)
    aiCell.add1:setTouchPriority(self.touchPriority)

    aiCell.sub1:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        print("sub1   ----")
        if aiData.isLevelOpen ~= 1 then
            runGamePrompt({msg = "当前未开启！！！"})
        elseif aiData.isOpen ~= 1 then
            runGamePrompt({msg = "明天就能打哦~"})
        elseif aiData.openLevel <= 1 then
            runGamePrompt({msg = fixstring.."通过关卡后才可以扫荡"})
        else
            self:numchange(aiCell,-1,index)
        end
    end, CCControlEventTouchUpInside)
    aiCell.sub1:setSwallowsTouch(true)
    aiCell.sub1:setTouchPriority(self.touchPriority)
    self:numchange(aiCell,0,index)

    --
    if aiCell.passdesc then
        if aiData.isOpen == 1 and aiData.passLevel and aiData.passLevel > 0 then
            if tonumber(aiData["function"]) == 1 then
                if gamedata.config.exp_copy[tostring(aiData.passLevel)] then
                    aiCell.passdesc:setString("当前挑战的副本："..gamedata.config.exp_copy[tostring(aiData.passLevel)].name)
                else
                    aiCell.passdesc:setString("")
                end    
            elseif tonumber(aiData["function"]) == 2 then
                if gamedata.config.coin_copy[tostring(aiData.passLevel)] then
                    aiCell.passdesc:setString("当前挑战的副本："..gamedata.config.coin_copy[tostring(aiData.passLevel)].name)
                else
                    aiCell.passdesc:setString("")
                end    
            elseif tonumber(aiData["function"]) == 3 then
                if gamedata.config.stone_copy[tostring(aiData.passLevel)] then
                    aiCell.passdesc:setString("当前挑战的副本："..gamedata.config.stone_copy[tostring(aiData.passLevel)].name)
                else
                    aiCell.passdesc:setString("")
                end    
            elseif tonumber(aiData["function"]) == 4 then
                if gamedata.config.upstar_huodong[tostring(aiData.passLevel)] then
                    aiCell.passdesc:setString("当前挑战的副本："..gamedata.config.upstar_huodong[tostring(aiData.passLevel)].name)
                else
                    aiCell.passdesc:setString("")
                end    
            elseif tonumber(aiData["function"]) == 5 then
                if gamedata.config.zhenfu_huodong[tostring(aiData.passLevel)] then
                    aiCell.passdesc:setString("当前挑战的副本："..gamedata.config.zhenfu_huodong[tostring(aiData.passLevel)].name)
                else
                    aiCell.passdesc:setString("")
                end    
            elseif tonumber(aiData["function"]) == 6 then
                if gamedata.config.forging_copy[tostring(aiData.passLevel)] then
                    aiCell.passdesc:setString("当前挑战的副本："..gamedata.config.forging_copy[tostring(aiData.passLevel)].name)
                else
                    aiCell.passdesc:setString("")
                end    
            end
        else
            aiCell.passdesc:setString("")
        end    
    end        


end

function activityCopySelect.numchange(self,aiCell,num,index)
    if self.selectData[index].usenum == self.selectData[index].maxnum and self.selectData[index].usenum+num > self.selectData[index].maxnum then
        runGamePrompt({msg = "达到可挑战上限"})
    end
    self.selectData[index].usenum = self.selectData[index].usenum + num

    if self.selectData[index].usenum > self.selectData[index].maxnum then
        self.selectData[index].usenum =  self.selectData[index].maxnum
    end
    
    if self.selectData[index].usenum <= 0 then
        self.selectData[index].usenum = 0

        self.selectData[index].isSelect = 0
        self.data[tostring(index)].isVisible = 0
        aiCell.isSelect:setVisible(false)

    end
    self.data[tostring(index)].usenum = self.selectData[index].usenum

    aiCell.usenum:setString(self.selectData[index].usenum)

end

function activityCopySelect.close(self)

    if self.callback then
        self.callback()
    end
    self.selectData={}
    self.data = {}
    self.activityListTableView = nil
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

end

return activityCopySelect