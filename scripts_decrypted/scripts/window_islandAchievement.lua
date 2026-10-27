--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/10
-- Time: 下午3:45
-- To change this template use File | Settings | File Templates.
--

local islandAchievement = {
    rootNode = nil,
    rootItems = nil,
    rankTemp = nil,
    point = nil,


    -- data ={
    --     task = {data= {}, tableview = nil, des="个人当前最高积分", des2="活动结束后，积分保存至下次活动开始",deslabel = 49,point = 0,request = 2114},
    --     total = {data= {}, tableview = nil, des="全服当前最高积分", des2="活动结束后，积分保存至下次活动开始",deslabel = 49,point = 0 ,request = 2117},
    --     rank = {data= {}, tableview = nil, des="个人当前最高积分", des2="排行奖励，每周一通过邮件发送！",deslabel = 21,point = 0,request = 2116}
    -- },
    data ={
        task = {data= {}, tableview = nil, des=gameConfig.strings:string_common("penglaiReward",0), des2=gameConfig.strings:string_common("penglaiReward",1),deslabel = 21,point = 0,request = 2114},
        total = {data= {}, tableview = nil, des=gameConfig.strings:string_common("penglaiReward",2), des2=gameConfig.strings:string_common("penglaiReward",3),deslabel = 21,point = 0 ,request = 2117},
        rank = {data= {}, tableview = nil, des=gameConfig.strings:string_common("penglaiReward",4), des2=gameConfig.strings:string_common("penglaiReward",5),deslabel = 21,point = 0,request = 2116},
        daily = {data= {}, tableview = nil, des=gameConfig.strings:string_common("penglaiReward",4), des2=gameConfig.strings:string_common("penglaiReward",14),deslabel = 21,point = 0,request = nil}
    },
    self = 0,
    total = 0,

    -- pageconfig = {"task","total","rank","daily" },
    -- -- titleconfig = {"成就","全服","排行" },
    -- titleconfig = {gameConfig.strings:string_common("penglaiReward",6),gameConfig.strings:string_common("penglaiReward",7),gameConfig.strings:string_common("penglaiReward",8),gameConfig.strings:string_common("penglaiReward",15) },
    -- selectpage = "task",

    pageconfig = {"total","rank","daily" },
    -- titleconfig = {"成就","全服","排行" },
    titleconfig = {gameConfig.strings:string_common("penglaiReward",7),gameConfig.strings:string_common("penglaiReward",8),gameConfig.strings:string_common("penglaiReward",15) },
    selectpage = "total",
}

function islandAchievement.shiftpage(self,page)
    print("i...am...shiftpage",page)
    self.selectpage = page
    for k,v in ipairs(self.pageconfig) do
        if v == page then
            setSpriteFrameByName(self.rootItems["buttonsprite"..k], gameConfig.images.pageButtonON)
            self.rootItems[v.."scroll"]:setPositionX(0)
            ui.setLabelString(self.rootItems.des1,self.data[page].des,18)
            ui.setLabelString(self.rootItems.des2,self.data[page].des2,self.data[page].deslabel)
            ui.setLabelString(self.rootItems.point,self.data[page].point,18)
        else
            setSpriteFrameByName(self.rootItems["buttonsprite"..k], gameConfig.images.pageButtonOFF)
            self.rootItems[v.."scroll"]:setPositionX(9999)
        end
    end

    if page == "daily" then
        self.rootItems.des1:setVisible(false)
        self.rootItems.point:setVisible(false)
    else
        self.rootItems.des1:setVisible(true)
        self.rootItems.point:setVisible(true)
    end


    if self.selectpage == "rank" then
        self.rootItems.mypaimingNode:setVisible(true)
    else
        self.rootItems.mypaimingNode:setVisible(false)
    end


    if not next(self.data[page].data) then
        -- if page == "task" then
        --     print("movetype1",self.movetype)
        --     UIRequest({type = self.data[page].request,update = self.movetype })
        -- else
        print("movetype1",self.movetype)
        if self.data[page].request then  
            UIRequest({type = self.data[page].request, update = self.movetype})
        else
            self:relaodDaily()
        end
        
    end

end

function islandAchievement.open(self,touchPriority,data,callback)
    print("i...am...open...")
    print("i...am..data.",data)
    self.touchPriority = touchPriority
    self.rootNode, self.rootItems = CCBReaderLoad("island2/island_pop", nil, true, "island_pop")
    self:reload(data,callback)

    return self.rootNode
end

function islandAchievement.reload(self,data,callback)
    print("i...am...reload...")
    self.callback = callback
    self.data.task.point = data.point
    self.data.rank.point = data.point
    self.movetype = data.movetype
    print("movetype2",self.movetype)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("penglaiReward")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    for i = 1,4 do
        self.rootItems["buttontext"..i]:setString(self.titleconfig[i])
        self.rootItems["button"..i]:addHandleOfControlEvent(function()
            self:shiftpage(self.pageconfig[i])
        end, CCControlEventTouchUpInside)
        self.rootItems["button"..i]:setSwallowsTouch(true)
        self.rootItems["button"..i]:setTouchPriority(self.touchPriority-2)
    end


    local config = gamedata.config.penglai2_rankrewards
    self.rankTemp = {}

    for k,v in pairs(config) do
        print(k,v)
        table.insert(self.rankTemp,v)
    end

    local function sortfunction( a, b )
        return tonumber(a.rank) < tonumber(b.rank)
    end

    table.sort(self.rankTemp, sortfunction)

    print("i..am..self.rankTemp:")
    printT(self.rankTemp)


    self:shiftpage(self.selectpage)
end

function islandAchievement.relaodTask(self,t)
    self.data.task.data = t.task
    if self.data.task.tableview ~= nil then
        self.data.task.tableview = nil
        self.rootItems.taskscroll:removeAllChildrenWithCleanup(true)
    end
    print("task====")
    printT(t)
    self:createTaskList()
end

function islandAchievement.relaodTotal(self,data)
    self.data.total.point = data.globalpoint
    self.data.total.data = data.global

    ui.setLabelString(self.rootItems.point,self.data.total.point,18)

    if self.data.total.tableview ~= nil then
        self.data.total.tableview = nil
        self.rootItems.totalscroll:removeAllChildrenWithCleanup(true)
    end
    self:createTotalList()
end

function islandAchievement.relaodRank(self,data)
    self.data.rank.data = data.rank
    print("i...am...relaodRank")
    -- local celldata = self.data.rank.data[tostring(1)].param

    if self.data.rank.tableview ~= nil then
        self.data.rank.tableview = nil
    end
    self:createRankList()

    self:setMyrank()
end

function islandAchievement.relaodDaily(self)
    self.data.daily.data = gamedata.config.penglai2_dailyrewards

    print("i...am...relaodDaily")
    -- printT(self.data.daily.data)
    -- local celldata = self.data.rank.data[tostring(1)].param

    if self.data.daily.tableview ~= nil then
        self.data.daily.tableview = nil
    end
    self:createDailyList()

end

function islandAchievement.setMyrank(self)
    -- local  myrankstring = "未上榜"
    local  myrankstring = gameConfig.strings:string_common("popups","weishangbang")

    ui.setLabelString(self.rootItems.rankText,nil,18)
    
    if self.data.rank.data[tostring(1)].param ~= -1 then
        print("myrank:",self.data.rank.data[tostring(1)].param)
        -- printT(self.data.rank.data)

        self.rootItems.myrankText:setVisible(true)
        self.rootItems.myrankLabel:setVisible(true)
        self.rootItems.norankLabel:setVisible(false)

        myrankstring = self.data.rank.data[tostring(1)].param
        self.rootItems.myrankLabel:setString(myrankstring)
    else
        self.rootItems.norankLabel:setVisible(true)
        self.rootItems.myrankText:setVisible(false)
        self.rootItems.myrankLabel:setVisible(false)
        
        ui.setLabelString(self.rootItems.norankLabel, myrankstring, 18)
    end
    -- self.rootItems.pointtotalLabel:setString(self.data.rank.point)
end

function islandAchievement.resetpenglaitotal(self,id)
    self.data.total.data[tostring(id)] = 2
    self.data.total.tableview:reloadData()
end

function islandAchievement.resetpenglaitask(self,data)
    self.data.task.data = data.task
    self.data.task.tableview:reloadData()
end

function islandAchievement.createTaskList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("island2/taskcell.ccbi", nil, true, "taskcell")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local celldata = self.data.task.data[tostring(a1+1)]

            local config = gamedata.config.penglai2_task[tostring(celldata.cid)]

            -- printT(config)
            ccbDocumentControler.des:setString(config.desc)
            ccbDocumentControler.now:setString(celldata.now)
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
                    local celldata = self.data.task.data[tostring(a1+1)]
                    if gameTouch.isScrollling then return end
                    print("cellid=",celldata.cid)
                    UIRequest({type = 2115, id = celldata.cid, seq = a1+1})
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
            r = table.getTableLength(self.data.task.data)
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

function islandAchievement.createTotalList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("island2/totalcell.ccbi", nil, true, "totalcell")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local config = gamedata.config.penglai2_globalpoint[tostring(a1+1)]
            print("config:=")
            -- printT(ccbDocumentControler)
            printT(config)
            printT(gamedata.config.penglai2_globalpoint)
            local celldata = self.data.total.data[tostring(a1+1)]

            ccbDocumentControler.point:setString(config.point)


            local prop = ui.getIDandNUMs(config.reward)

            for i,v in ipairs(prop) do
                ui.setNewIcon(ccbDocumentControler,prop[i],i-1)
            end
            -- if #prop == 1 then
                -- ccbDocumentControler.secondPropCCB:setVisible(false)
            -- end
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
                    UIRequest({type = 2118, id = a1+1})
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
            r = 5
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

function islandAchievement.createRankList(self)
    print("i...am...relaodRank")
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("island2/paihangcell.ccbi", nil, true, "paihangcell")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local rankdata = self.rankTemp[tonumber(a1+1)]
            local lastrankdata = self.rankTemp[tonumber(a1)]
            print("celll..")
            printT(rankdata)
            local ranknumstring = {}
            if (a1+1)>10 then
                ranknumstring = (lastrankdata.rank+1).."~"..rankdata.rank
            else
                ranknumstring = rankdata.rank
            end

            ui.setLabelString(ccbDocumentControler.rankNumText, nil, 21)
            ui.setLabelString(ccbDocumentControler.rankNumLabel, ranknumstring, 21)
            

            local prop = ui.getIDandNUMs(rankdata.reward)
            print("i...am..prop")
            -- printT(prop)

            for i=1,4 do
                if i < #prop or i == #prop then
                    ui.setNewIcon(ccbDocumentControler,prop[i],i-1)
                    ccbDocumentControler["ccbitem"..i]:setVisible(true)
                else
                    ccbDocumentControler["ccbitem"..i]:setVisible(false)
                end
            end


            cellCCB:setPosition(930/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(gamedata.config.penglai2_rankrewards)
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


function islandAchievement.createDailyList(self)
    print("i...am...relaodDaily")
    local celldict = {}
    local dailyListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(930, 200)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("island2/paihangcell.ccbi", nil, true, "paihangcell")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            ccbDocumentControler.rankNumText:setVisible(false)


            local dailydata = self.data.daily.data[tostring(a1+1)]
            print("dailyitem===")
            -- printT(dailydata)


            -- ui.setLabelString(ccbDocumentControler.rankNumLabel, dailydata.point.."仙元", 14)
            ui.setLabelString(ccbDocumentControler.rankNumLabel, gameConfig.strings:toYy(dailydata.point), 21)
            

            local prop = ui.getIDandNUMs(dailydata.reward)
            print("i...am..prop")
            -- printT(prop)

            for i=1,4 do
                if i < #prop or i == #prop then
                    ui.setNewIcon(ccbDocumentControler,prop[i],i-1)
                    ccbDocumentControler["ccbitem"..i]:setVisible(true)
                else
                    ccbDocumentControler["ccbitem"..i]:setVisible(false)
                end
            end


            cellCCB:setPosition(930/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.data.daily.data)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            ----gameTouch.isScrollling = true
        end
        return r
    end)

    self.data.daily.tableview = ui.createLuaTableView({
        handle = dailyListHandle,
        viewwidth = self.rootItems.dailyscroll:getContentSize().width,
        viewheight = self.rootItems.dailyscroll:getContentSize().height,
        dire = 1
    })
    self.data.daily.tableview:setTouchPriority(self.touchPriority)
    self.rootItems.dailyscroll:addChild(self.data.daily.tableview)
end

function islandAchievement.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.data.task.tableview = nil
    self.data.rank.tableview = nil
    self.data.total.tableview = nil
    self.data.daily.tableview = nil

    self.data.task.data = {}
    self.data.rank.data = {}
    self.data.total.data = {}
    self.data.daily.data = {}

    if self.callback then
        self.callback()
    end
end

return islandAchievement   �X  