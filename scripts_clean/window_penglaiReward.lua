--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/23
-- Time: 下午1:29
-- To change this template use File | Settings | File Templates.
--

local penglai = {
    rootNode = nil,
    rootItems = nil,


    -- data ={
    --     task = {data= {}, tableview = nil, des="个人当前最高积分", des2="活动结束后，积分保存至下次活动开始",deslabel = 49,point = 0,request = 2048},
    --     total = {data= {}, tableview = nil, des="全服当前最高积分", des2="活动结束后，积分保存至下次活动开始",deslabel = 49,point = 0 ,request = 2046},
    --     rank = {data= {}, tableview = nil, des="个人当前最高积分", des2="排行奖励，每周一通过邮件发送！",deslabel = 21,point = 0,request = 2044}
    -- },
    data ={
        task = {data= {}, tableview = nil, des=gameConfig.strings:string_common("penglaiReward",0), des2=gameConfig.strings:string_common("penglaiReward",1),deslabel = 49,point = 0,request = 2048},
        total = {data= {}, tableview = nil, des=gameConfig.strings:string_common("penglaiReward",2), des2=gameConfig.strings:string_common("penglaiReward",3),deslabel = 49,point = 0 ,request = 2046},
        rank = {data= {}, tableview = nil, des=gameConfig.strings:string_common("penglaiReward",4), des2=gameConfig.strings:string_common("penglaiReward",5),deslabel = 21,point = 0,request = 2044}
    },
    self = 0,
    total = 0,

    pageconfig = {"task","total","rank" },
    -- titleconfig = {"成就","全服","排行" },
    titleconfig = {gameConfig.strings:string_common("penglaiReward",6),gameConfig.strings:string_common("penglaiReward",7),gameConfig.strings:string_common("penglaiReward",8) },
    selectpage = "task",
}

function penglai.shiftpage(self,page)
    self.selectpage = page
    for k,v in ipairs(self.pageconfig) do
        if v == page then
            setSpriteFrameByName(self.rootItems["buttonsprite"..k], gameConfig.images.pageButtonON)
            self.rootItems[v.."scroll"]:setPosition(0,-116)
            ui.setLabelString(self.rootItems.des1,self.data[page].des,49)
            ui.setLabelString(self.rootItems.des2,self.data[page].des2,self.data[page].deslabel)
            ui.setLabelString(self.rootItems.point,self.data[page].point,26)
        else
            setSpriteFrameByName(self.rootItems["buttonsprite"..k], gameConfig.images.pageButtonOFF)
            self.rootItems[v.."scroll"]:setPosition(9999,171)
        end
    end


    if not next(self.data[page].data) then
        UIRequest({type = self.data[page].request})
    end

end

function penglai.open(self,touchPriority,data,callback)

    self.touchPriority = touchPriority
    self.rootNode, self.rootItems = CCBReaderLoad("island/island_pop", nil, true, "island_pop")
    self:reload(data,callback)

    return self.rootNode
end

function penglai.reload(self,data,callback)
    self.callback = callback
    self.data.task.point = data.point
    self.data.rank.point = data.point

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("penglaiReward")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    for i = 1,3 do
        self.rootItems["buttontext"..i]:setString(self.titleconfig[i])
        self.rootItems["button"..i]:addHandleOfControlEvent(function()
            self:shiftpage(self.pageconfig[i])
        end, CCControlEventTouchUpInside)
        self.rootItems["button"..i]:setSwallowsTouch(true)
        self.rootItems["button"..i]:setTouchPriority(self.touchPriority-2)
    end

    self:shiftpage(self.selectpage)
end

function penglai.relaodTask(self,t)
    self.data.task.data = t.status
    if not self.data.task.tableview then
        self:createTaskList()
    else
        self.data.task.tableview:reloadData()
    end
end

function penglai.relaodTotal(self,t)
    self.data.total.point = t.totalpoint
    self.data.total.data = t.status

    ui.setLabelString(self.rootItems.point,self.data.total.point,26)

    if not self.data.total.tableview then
        self:createTotalList()
    else
        self.data.total.tableview:reloadData()
    end
end

function penglai.relaodRank(self,t)
    self.data.rank.data = t.players
    if not self.data.rank.tableview then
        self:createRankList()
    else
        self.data.rank.tableview:reloadData()
    end
end

function penglai.resetpenglaitotal(self,id)
    self.data.total.data[tostring(id)] = 2
    self.data.total.tableview:reloadData()
end

function penglai.resetpenglaitask(self,id)
    self.data.task.data[tostring(id)].status = 2
    self.data.task.tableview:reloadData()
end

function penglai.createTaskList(self)
    local celldict = {}
    local taskListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(930, 200)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("island/taskcell.ccbi", nil, true, "taskcell")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local config = gamedata.config.penglai2_task[tostring(a1+1)]
            local celldata = self.data.task.data[tostring(a1+1)]

            --printT(config)
            ccbDocumentControler.des:setString(config.desc)
            ccbDocumentControler.now:setString(celldata.num)
            ccbDocumentControler.total:setString(config.num)

            local prop = ui.getIDandNUMs(config.reward)
            -- local rewards ="奖励: "
            local rewards =gameConfig.strings:string_common("penglaiReward",9)

            for k,v in ipairs(prop) do
                local temp = rewards .. ui.IDconfig(v.cid).name.."x"..v.num.."  "
                rewards = temp
            end
            ccbDocumentControler.reward:setString(rewards)

            ccbDocumentControler.button:setTouchPriority(self.touchPriority-1)

            ui.setNewIcon(ccbDocumentControler,{cid = prop[1].cid})

            -- ui.setLabelString(ccbDocumentControler.buttontext,"领 取",18)
            ui.setLabelString(ccbDocumentControler.buttontext,gameConfig.strings:string_common("penglaiReward",10),18)
            if celldata.status == 0 then
                ccbDocumentControler.getNode:setVisible(false)
                ccbDocumentControler.buttonNode:setVisible(true)
                ui.addGray("CCControlButton",ccbDocumentControler.button)
                ui.addGray("CCLabelTTF",ccbDocumentControler.buttontext)

                ccbDocumentControler.button:addHandleOfControlEvent(function()
                    if gameTouch.isScrollling then return end
                    -- runGamePrompt({msg = "未达成"})
                    runGamePrompt({msg = gameConfig.strings:string_common("penglaiReward",11)})
                end, CCControlEventTouchUpInside)
            elseif celldata.status == 1 then
                ccbDocumentControler.getNode:setVisible(false)
                ccbDocumentControler.buttonNode:setVisible(true)
                ui.removeGray("CCControlButton",ccbDocumentControler.button)
                ui.removeGray("CCLabelTTF",ccbDocumentControler.buttontext)
                ccbDocumentControler.button:addHandleOfControlEvent(function()
                    if gameTouch.isScrollling then return end
                    UIRequest({type = 2049, id = a1+1})
                end, CCControlEventTouchUpInside)

            elseif celldata.status == 2 then
                ccbDocumentControler.getNode:setVisible(true)
                ccbDocumentControler.buttonNode:setVisible(false)
                ccbDocumentControler.button:addHandleOfControlEvent(function()

                end, CCControlEventTouchUpInside)
            end


            cellCCB:setPosition(930/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(gamedata.config.penglai2_task)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.data.task.tableview = ui.createLuaTableView({
        handle = taskListHandle,
        viewwidth = self.rootItems.taskscroll:getContentSize().width,
        viewheight = self.rootItems.taskscroll:getContentSize().height,
        dire = 1
    })
    self.data.task.tableview:setTouchPriority(self.touchPriority)
    self.rootItems.taskscroll:addChild(self.data.task.tableview)
end

function penglai.createTotalList(self)
    local celldict = {}
    local totalListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(930, 200)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("island/totalcell.ccbi", nil, true, "totalcell")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local config = gamedata.config.penglai_reward[tostring(a1+1)]
            local celldata = self.data.total.data[tostring(a1+1)]

            ccbDocumentControler.point:setString(config.stone)


            local prop = ui.getIDandNUMs(config.reward)

            for i=1,2  do
                ui.setNewIcon(ccbDocumentControler,prop[i],i-1)
            end
            -- ui.setLabelString(ccbDocumentControler.buttontext,"领 取",18)
            ui.setLabelString(ccbDocumentControler.buttontext,gameConfig.strings:string_common("penglaiReward",10),18)
            ccbDocumentControler.button:setTouchPriority(self.touchPriority-1)
            if celldata == 0 then
                ccbDocumentControler.getNode:setVisible(false)
                ccbDocumentControler.buttonNode:setVisible(true)
                ui.addGray("CCControlButton",ccbDocumentControler.button)
                ui.addGray("CCLabelTTF",ccbDocumentControler.buttontext)
                ccbDocumentControler.button:addHandleOfControlEvent(function()
                    if gameTouch.isScrollling then return end
                    -- runGamePrompt({msg = "未完成"})
                    runGamePrompt({msg = gameConfig.strings:string_common("penglaiReward",12)})
                end, CCControlEventTouchUpInside)
            elseif celldata == 1 then
                ccbDocumentControler.getNode:setVisible(false)
                ccbDocumentControler.buttonNode:setVisible(true)
                ui.removeGray("CCControlButton",ccbDocumentControler.button)
                ui.removeGray("CCLabelTTF",ccbDocumentControler.buttontext)
                ccbDocumentControler.button:addHandleOfControlEvent(function()
                    if gameTouch.isScrollling then return end
                    UIRequest({type = 2047, id = a1+1})
                end, CCControlEventTouchUpInside)
            elseif celldata == 2 then
                ccbDocumentControler.getNode:setVisible(true)
                ccbDocumentControler.buttonNode:setVisible(false)
                ccbDocumentControler.button:addHandleOfControlEvent(function()

                end, CCControlEventTouchUpInside)
            end

            cellCCB:setPosition(930/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(gamedata.config.penglai_reward)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.data.total.tableview = ui.createLuaTableView({
        handle = totalListHandle,
        viewwidth = self.rootItems.totalscroll:getContentSize().width,
        viewheight = self.rootItems.totalscroll:getContentSize().height,
        dire = 1
    })
    self.data.total.tableview:setTouchPriority(self.touchPriority)
    self.rootItems.totalscroll:addChild(self.data.total.tableview)
end

function penglai.createRankList(self)
    local celldict = {}
    local rankListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(930, 200)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("island/rankcell.ccbi", nil, true, "rankcell")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end


            local config = gamedata.config.penglai_rank[tostring(a1+1)]
            local celldata = self.data.rank.data[tostring(a1+1)]
            ccbDocumentControler.rank:setString(a1+1)
            ui.setLabelString(ccbDocumentControler.name,celldata.name,21)
            ccbDocumentControler.point:setString(celldata.param)

            ui.setNewIcon(ccbDocumentControler,{cid = celldata.profile})

            setSpriteFrameByName(ccbDocumentControler.reward,  config.icon)

            --todo   预览弹窗

            ccbDocumentControler.view:setTouchPriority(self.touchPriority-1)
            ccbDocumentControler.view:addHandleOfControlEvent(function()
                -- gameWindows:openWindow("getStaff",{data = ui.getIDandNUMs(config.reward),type = "奖励预览"},nil)
                gameWindows:openWindow("getStaff",{data = ui.getIDandNUMs(config.reward),type = gameConfig.strings:string_common("penglaiReward",13)},nil)
            end, CCControlEventTouchUpInside)

            cellCCB:setPosition(930/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.data.rank.data)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            ----gameTouch.isScrollling = true
        end
        return r
    end)

    self.data.rank.tableview = ui.createLuaTableView({
        handle = rankListHandle,
        viewwidth = self.rootItems.rankscroll:getContentSize().width,
        viewheight = self.rootItems.rankscroll:getContentSize().height,
        dire = 1
    })
    self.data.rank.tableview:setTouchPriority(self.touchPriority)
    self.rootItems.rankscroll:addChild(self.data.rank.tableview)
end

function penglai.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.data.task.tableview = nil
    self.data.rank.tableview = nil
    self.data.total.tableview = nil

    self.data.task.data = {}
    self.data.rank.data = {}
    self.data.total.data = {}

    if self.callback then
        self.callback()
    end
end

return penglai