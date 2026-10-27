--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/2/4
-- Time: 14:31
-- To change this template use File | Settings | File Templates.
--

local servicewarNow = {

    groupListTableView = nil,
    groupindex = 1,
    ListTableView = nil,
    resource = nil,

    rootNode = nil,
    rootItems = nil,

    grouprootNode = nil,
    grouprootItems = nil,

    championrootNode1 = nil,
    championrootItems1 = nil,
    championrootNode2 = nil,
    championrootItems2 = nil,
    championrootNode3 = nil,
    championrootItems3 = nil,

    normalCellSize = {x = 950, y = 240},

    pageconfig = {"personal","group","champion"} ,
    -- pagename = {"个人战绩","小组赛","冠军赛"},
    pagename = {gameConfig.strings:string_common("fixedString","servicewar",9),gameConfig.strings:string_common("fixedString","servicewar",10),gameConfig.strings:string_common("fixedString","servicewar",11)},
    selectpage = "personal",

    buttontouch = -103,

    worldwarstatus = {},
    worldwarrolebattles = {},
    worldwarplayers = {},
    worldwartop = {},
    isOpenStatus = 0,

    groupname = {
        [1] = "A组",
        [2] = "B组",
        [3] = "C组",
        [4] = "D组",
        [5] = "E组",
        [6] = "F组",
        [7] = "G组",
        [8] = "H组",
    },

    pageNum = 1,
    lastPageNum = 1,
    --当前赛区
    selectDivision = nil,
    worldwarstatusShenbang = {},
    worldwarrolebattlesShenbang = {},
    worldwartopShenbang = {},
    worldwarplayersShenbang = {},
}

function servicewarNow.shiftPage(self,type,notcheck)
    print("shiftPage",type)
    self.selectpage = type
    if type == "personal" then
        self.rootItems.personalNode:setPositionX(0)
        self.rootItems.groupNode:setPositionX(-9999)
        self.rootItems.championNode:setPositionX(-9999)
        --self.rootItems.questNode:setVisible(false)
        if next(self.worldwarstatus) and next(self.worldwarrolebattles) then
            self:ReloadData()
        else
            UIRequest({type = 4703})
        end
    elseif type == "group" then
        self.rootItems.personalNode:setPositionX(-9999)
        self.rootItems.groupNode:setPositionX(0)
        self.rootItems.championNode:setPositionX(-9999)

        --self.rootItems.questNode:setVisible(true)
        if next(self.worldwartop) then
            self:ReloadTop()
        else
            UIRequest({type = 4708,division = self.selectDivision})
        end
    elseif type == "champion" then
        self.rootItems.personalNode:setPositionX(-9999)
        self.rootItems.groupNode:setPositionX(-9999)
        self.rootItems.championNode:setPositionX(0)
        --self.rootItems.questNode:setVisible(true)
        if next(self.worldwartop) then
            self:ReloadTop()
        else
            UIRequest({type = 4708,division = self.selectDivision})
        end
    elseif type == "s_personal" then --突围赛
        self.rootItems.personalNode:setPositionX(0)
        self.rootItems.groupNode:setPositionX(-9999)
        self.rootItems.championNode:setPositionX(-9999)
        if next(self.worldwarstatusShenbang) and next(self.worldwarrolebattlesShenbang) then
            self:ReloadData()
        else
            UIRequest({type = 4720})
        end
    elseif type == "s_champion" then --神榜冠军赛
        self.rootItems.personalNode:setPositionX(-9999)
        self.rootItems.groupNode:setPositionX(-9999)
        self.rootItems.championNode:setPositionX(0)
        --self.rootItems.questNode:setVisible(true)
        if next(self.worldwartopShenbang) then
            self:ReloadTop()
        else
            UIRequest({type = 4721})
        end
    end
end

function servicewarNow.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("kuafuzhan/kuafuzhan_now", nil, true, "kuafuzhan_now")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.midnode:setPositionY((toppos-260)/2)

    self.rootItems.timeRuleButton:setTouchPriority(-103)
    self.rootItems.timeRuleButton:addHandleOfControlEvent(function()
        gameWindows:openWindow("servicewarrule",{opt = 4,shenbang = (self.worldwarstatus.s_open and self.worldwarstatus.s_open == 1)})
    end, CCControlEventTouchUpInside)

    if GameScene.priorLayer == "limitedset" or GameScene.priorLayer == "daily" then
        self.priorLayer = GameScene.priorLayer
    end

    if self.rootItems.closeButton then
        self.rootItems.closeButton:setTouchPriority(-103)
        self.rootItems.closeButton:addHandleOfControlEvent(function()
            if self.priorLayer then
                GameScene:shiftLayer(self.priorLayer)
            else
                GameScene:shiftLayer("main","down")
            end
        end, CCControlEventTouchUpInside)
    end

    for i=1,10 do
        ui.setLabelString(self.rootItems["fixedStr"..i],nil,14)
        self.rootItems["scheduleBtn"..i]:setTouchPriority(self.buttontouch)
        self.rootItems["scheduleBtn"..i]:addHandleOfControlEvent(function()
            local battleStatus = self:getBattleStatus()
            if battleStatus < i then
                runGamePrompt({msg = "当前赛事未开启"})
            else
                self:shiftPageNum(i)
            end
        end, CCControlEventTouchUpInside)
    end


    if GameScene.hintdata[tostring(212)] == 0 then
        ui.sethint(self.rootItems.hint_servicewarAfter,false)
    else
        ui.sethint(self.rootItems.hint_servicewarAfter,true)
    end

    --
    self.grouprootNode,self.grouprootItems = CCBReaderLoad("kuafuzhan/kuafuzhan_bisai", nil, true, "kuafuzhan_bisai")
    self.grouprootNode:setPosition(0,0)
    self.rootItems.groupccbnode:addChild(self.grouprootNode)


    self.championrootNode1,self.championrootItems1 = CCBReaderLoad("kuafuzhan/kuafuzhan_bisai8", nil, true, "kuafuzhan_bisai8")
    self.championrootNode1:setPosition(0,0)
    self.rootItems.championccbnode1:addChild(self.championrootNode1)

    self.championrootNode2,self.championrootItems2 = CCBReaderLoad("kuafuzhan/kuafuzhan_bisai4", nil, true, "kuafuzhan_bisai4")
    self.championrootNode2:setPosition(0,0)
    self.rootItems.championccbnode2:addChild(self.championrootNode2)

    self.championrootNode3,self.championrootItems3 = CCBReaderLoad("kuafuzhan/kuafuzhan_bisai2", nil, true, "kuafuzhan_bisai2")
    self.championrootNode3:setPosition(0,0)
    self.rootItems.championccbnode3:addChild(self.championrootNode3)


    -- self.championrootNode,self.championrootItems = CCBReaderLoad("kuafuzhan/kuafuzhan_bisai", nil, true, "kuafuzhan_bisai")
    -- self.championrootNode:setPosition(0,0)
    -- self.rootItems.championccbnode:addChild(self.championrootNode)
    -- --
    ui.setLabelString(self.rootItems.endtimelab,gameConfig.strings:string_common("fixedString","servicewar",20),21)
    --
    local tt = tostring(table.getTableLength(gamedata.config.cross_battle_time))
    local wday = gamedata.config.cross_battle_time[tt].over_week+1
    if wday > 7 then wday = 1 end
    local hour,min,sec = ui.getGangBattleTime(gamedata.config.cross_battle_time[tt].over_time)
    local nowtime = os.date("*t", gamedata:time())
    local diff = (wday-nowtime.wday)*86400+(hour-nowtime.hour)*3600+(min-nowtime.min)*60+sec-nowtime.sec
    if diff < 0 then diff = diff+86400*7 end

    gameTimer:rigistTime("worldwarendtimer",diff+1)
    gameTimer:rigistTimeFunc("worldwarendtimer",function()
        if gameTimer.times["worldwarendtimer"] <= 0 then
            ui.setLabelString(self.rootItems.endtimelab,"",21)
            ui.setLabelString(self.rootItems.endtime,"",14)
            UIRequest({type = 4702, param = "update"})
        else
            ui.setLabelString(self.rootItems.endtime,ui.makeTimeDayText(gameTimer.times["worldwarendtimer"],"day"),14)
        end
    end)
    --

    local showtime = {{65,67},{69,71},{74,76},{78,80},{83,85},{87,89}}
    for i = 1,6 do
        -- local timeconfig1 = gamedata.config.cross_battle_time[tostring(showtime[i][1])]
        -- local timeconfig2 = gamedata.config.cross_battle_time[tostring(showtime[i][2])]
        -- local hour1,min1,sec1 = ui.getGangBattleTime(timeconfig1.open_time)
        -- local hour2,min2,sec2 = ui.getGangBattleTime(timeconfig2.over_time)
        -- if math.floor(min1/10) < 1 then
        --     min1 = "0"..min1
        -- end
        -- if math.floor(min2/10) < 1 then
        --     min2 = "0"..min2
        -- end
        -- local timestring = "第"..(gameConfig.strings.bigNum[((i>3) and (i-3) or i)]).."轮比赛：".."周"..gameConfig.strings:string_common("wdayNum",(timeconfig1.open_week+1)>7 and 1 or (timeconfig1.open_week+1)).." "..hour1..":"..min1.." ~ ".."周"..gameConfig.strings:string_common("wdayNum",(timeconfig2.over_week+1)>7 and 1 or (timeconfig2.over_week+1)).." "..hour2..":"..min2
        ui.setLabelString(self.rootItems["showtime"..i],"")
    end

    --
    if self.rootItems.group_right then
        self.rootItems.group_right:setTouchPriority(-103)
        self.rootItems.group_right:addHandleOfControlEvent(function()
            if self.groupListTableView then
                local setx = self.groupListTableView:getLuaContentOffsetX()
                if setx - 140 < -420 then
                    self.groupListTableView:setContentOffsetInDuration(ccp(-420 ,0),0.2)
                else
                    self.groupListTableView:setContentOffsetInDuration(ccp(setx - 140 ,0),0.2)
                end
                --self:checkSetX()
            end
        end, CCControlEventTouchUpInside)
    end
    --
    if self.rootItems.group_left then
        self.rootItems.group_left:setTouchPriority(-103)
        self.rootItems.group_left:addHandleOfControlEvent(function()
            if self.groupListTableView then
                local setx = self.groupListTableView:getLuaContentOffsetX()
                if setx + 140 > 0 then
                    self.groupListTableView:setContentOffsetInDuration(ccp(0 ,0),0.2)
                else
                    self.groupListTableView:setContentOffsetInDuration(ccp(setx + 140 ,0),0.2)
                end
                --self:checkSetX()
            end
        end, CCControlEventTouchUpInside)
    end

    --
    --self:shiftPage(self.selectpage)
    self:shiftPageNum(self.pageNum)
    UIRequest({type = 4717})
    -- self:createDivisionNode()
end

function servicewarNow.createDivisionNode(self)

    self.oldDivision = nil
    self.selectDivision = self.worldwarstatus.curDivision
    self.divisionNum = self.worldwarstatus.divisionNum
    local offy = 3
    local cellWidth = 250
    local cellHeight = 50
    local openstatus = false

    local function divisionNodeStatus()
        openstatus = not openstatus
        if openstatus then
            self.divisionSelectNode.items.scrollNode:setVisible(true)
            self.divisionSelectNode.items.scroll_bg:runAction(CCScaleTo:create(0.1,1,1))
            for i=1,self.divisionNum do
                self.divisionSelectNode.division_scroll_cells[i].node:stopAllActions()
                local moveto = CCMoveTo:create(0.5,ccp(cellWidth/2,(self.divisionNum - i)* (cellHeight + offy)))
                local backout = CCEaseBackOut:create(moveto)
                self.divisionSelectNode.division_scroll_cells[i].node:runAction(backout)
            end
        else
            for i=1,self.divisionNum do
                self.divisionSelectNode.division_scroll_cells[i].node:stopAllActions()
                local moveto = CCMoveTo:create(0.5,ccp(cellWidth/2,(self.divisionNum)* (cellHeight + offy)))
                local backout = CCEaseBackOut:create(moveto)
                self.divisionSelectNode.division_scroll_cells[i].node:runAction(CCSequence:createWithTwoActions(backout, CCCallFunc:create(function()
                    self.divisionSelectNode.items.scrollNode:setVisible(false)
                end)))
            end
            self.divisionSelectNode.items.scroll_bg:runAction(CCScaleTo:create(0.2,1,0))
        end
    end

    local node,items = CCBReaderLoad("kuafuzhan/saiquxuanze", nil, true, "saiquxuanze")
    self.rootItems.divisionSelectNode:setScale(1.3)
    self.rootItems.divisionSelectNode:addChild(node)
    self.divisionSelectNode = {node = node,items = items}

    items.scrollNode:setVisible(false)
    items.openbtn1:setSwallowsTouch(true)
    items.openbtn1:setTouchPriority(self.buttontouch - 1)
    items.openbtn1:addHandleOfControlEvent(function()
        divisionNodeStatus()
    end, CCControlEventTouchUpInside)

    items.openbtn2:setSwallowsTouch(true)
    items.openbtn2:setTouchPriority(self.buttontouch - 1)
    items.openbtn2:addHandleOfControlEvent(function()
        divisionNodeStatus()
    end, CCControlEventTouchUpInside)

    items.division_scroll = tolua.cast(items.division_scroll, "CCScrollView")
    items.division_scroll:setTouchPriority(self.buttontouch-2)
    items.container:setContentSize(CCSize(cellWidth,self.divisionNum * (cellHeight + offy)))
    items.container:setPositionY(290 - items.container:getContentSize().height)

    self.divisionSelectNode.division_scroll_cells = {}
    for i=1,self.divisionNum do
        local cell_node,cell_items = CCBReaderLoad("kuafuzhan/cell_saiquxuanze", nil, true, "cell_saiquxuanze")
        cell_node:setPosition(cellWidth/2,(self.divisionNum)* (cellHeight + offy))
        items.container:addChild(cell_node)
        cell_items.flag:setVisible(i == self.worldwarstatus.curDivision)
        cell_items.label:setString(gameConfig.strings:servicewar_division(i))
        cell_items.label:setColor((i == self.selectDivision and ccc3(255,255,255) or ccc3(145,145,145)))
        self.divisionSelectNode.division_scroll_cells[i] = {node = cell_node,items = cell_items}
        
        cell_items.button:setSwallowsTouch(true)
        cell_items.button:setTouchPriority(self.buttontouch - 1)
        cell_items.button:addHandleOfControlEvent(function()
            if gameTouch.ismove then return end
            
            divisionNodeStatus()
            self:shiftDivision(i)
        end, CCControlEventTouchUpInside)

    end
    self:reloadDivisionNode()
end

function servicewarNow.shiftDivision(self,division)
    print("shiftDivision",i)
    if self.selectDivision == division then
        return
    end
    self.oldDivision = self.selectDivision
    self.selectDivision = division
    self:reloadDivisionNode()


    self.worldwartop = {}
    self.worldwarplayers = {}
    self:shiftPage(self.selectpage)
end

function servicewarNow.setGetallNode(self)
    --海选 突围领取按钮状态
    if self.rootItems.getallNode then
        if gameConfig:checkBuildOpen(352) then
            --
            local hasreward = false
            local hasreward2 = false

            for k,v in pairs(self.worldwarrolebattlesShenbang) do
                if v.reward and v.reward == 1 then
                    hasreward2 = true
                    break
                end
            end

            for k,v in pairs(self.worldwarrolebattles) do
                if v.reward and v.reward == 1 then
                    hasreward = true
                    break
                end
            end

            self.rootItems.getallNode:setVisible(true)
            ui.setLabelString(self.rootItems.getallLab,nil,18)
            self.rootItems.getallButton:setTouchPriority(self.buttontouch)
            self.rootItems.getRewardHintNode:setVisible(hasreward)
            self.rootItems.getRewardHintNode2:setVisible(hasreward2)
            if (hasreward and self.pageNum == 2) or (hasreward2 and self.pageNum == 7) then
                ui.removeGray("CCControlButton",self.rootItems.getallButton)
                self.rootItems.getallButton:addHandleOfControlEvent(function()
                    gameTouch:clickprofbytime(1)
                    UIRequest({type = (self.pageNum == 2 and 4714 or 4723), phase = 0, id = 0})
                end, CCControlEventTouchUpInside)
            else
                ui.addGray("CCControlButton",self.rootItems.getallButton)
                self.rootItems.getallButton:addHandleOfControlEvent(function()
                    gameTouch:clickprofbytime(0.5)
                    runGamePrompt({msg = "没有可领取的奖励"})
                end, CCControlEventTouchUpInside)
            end
            
        else
            self.rootItems.getallNode:setVisible(false)
        end

    end
end

function servicewarNow.reloadDivisionNode(self)
    if self.oldDivision ~= self.selectDivision then
        if self.oldDivision then
            self.divisionSelectNode.division_scroll_cells[self.oldDivision].items.label:setColor(ccc3(145,145,145))
            setControlButtonFrame(self.divisionSelectNode.division_scroll_cells[self.oldDivision].items.button,"kuafuzhan_sq_di2","kuafuzhan_sq_di2","kuafuzhan_sq_di2")
        end

        self.divisionSelectNode.division_scroll_cells[self.selectDivision].items.label:setColor(ccc3(255,255,255))
        setControlButtonFrame(self.divisionSelectNode.division_scroll_cells[self.selectDivision].items.button,"kuafuzhan_sq_di1","kuafuzhan_sq_di1","kuafuzhan_sq_di1")
    end
    self.divisionSelectNode.items.currentDivisionLable:setString(gameConfig.strings:servicewar_division(self.selectDivision))
end

--神榜特殊显示处理
function servicewarNow.shiftHandleForShenbang(self)
    if (not next(self.worldwarstatus)) or self.worldwarstatus.s_open == 0 then
        return
    end

    self:setGetallNode()
    self.rootItems.divisionSelectNode:setVisible(self.pageNum >= 3 and self.pageNum <= 6)
    self.rootItems.shiftButton_guanjun:setVisible(self.pageNum >= 3 and self.pageNum <= 6)
    self.rootItems.bg_normal:setVisible(self.pageNum <= 6)
    self.rootItems.shiftNodeNormal:setVisible(self.pageNum <= 6)
    self.rootItems.shiftButton_jinji:setVisible(self.pageNum >= 7)

    self.rootItems.shiftButton_jinji:setScale(1.2)
    self.rootItems.shiftButton_jinji:setPositionY(220)
    if self.pageNum == 7 then
        if self.worldwarstatus.promotion < 1 then
        elseif self.worldwarstatus.status < gameConfig.serverWarStage.End_S_Audition then
        else
            self.rootItems.shiftButton_jinji:setScale(0.8)
            self.rootItems.shiftButton_jinji:setPositionY(150)
        end
    end

    self.rootItems.bg_shenbang:setVisible(self.pageNum >= 7)
    self.rootItems.shiftNodeShenbang:setVisible(self.pageNum >= 7)

    if self.worldwarstatus.status < gameConfig.serverWarStage.Began_S_Audition then
        ui.addGray("CCControlButton",self.rootItems.shiftButton_guanjun)
    else
        ui.removeGray("CCControlButton",self.rootItems.shiftButton_guanjun)
    end
    self.rootItems.shiftButton_guanjun:setTouchPriority(self.buttontouch)
    self.rootItems.shiftButton_guanjun:addHandleOfControlEvent(function()
        if self.worldwarstatus.status < gameConfig.serverWarStage.Began_S_Audition then
            runGamePrompt({msg = "冠军赛未开始"})
            return
        end
        self:shiftPageNum(self:getBattleStatus())
    end, CCControlEventTouchUpInside)

    self.rootItems.shiftButton_jinji:setTouchPriority(self.buttontouch)
    self.rootItems.shiftButton_jinji:addHandleOfControlEvent(function()
        self:shiftPageNum(6)
        self:shiftDivision(self.worldwarstatus.curDivision)
    end, CCControlEventTouchUpInside)


    if next(self.worldwarstatus) and next(self.worldwarrolebattles) then
    else
        UIRequest({type = 4703})
    end

    if  next(self.worldwarstatusShenbang) and next(self.worldwarrolebattlesShenbang) then
    else
        if self.pageNum >= 7 then
            UIRequest({type = 4720})
        end
    end    
end

function servicewarNow.shiftPageNum(self,num)
    self.pageNum = num
    self:shiftHandleForShenbang()

    for i=1,10 do
        if i == self.pageNum then
            self.rootItems["selectnum"..i]:setVisible(true)
            --setSpriteFrameByName(self.rootItems["statusnum"..i], "kuafuzha_n_4")
        else
            self.rootItems["selectnum"..i]:setVisible(false)
            --setSpriteFrameByName(self.rootItems["statusnum"..i], "kuafuzha_n_4_h")
        end
    end

    if self.pageNum == 2 and self.worldwarstatus then
        self.rootItems.desc:setString(gameConfig.strings:string_common("fixedString","servicewar",18))
    elseif self.pageNum == 3 and self.worldwarstatus then
        self.rootItems.desc:setString(gameConfig.strings:string_common("fixedString","servicewar",69))
    elseif self.pageNum == 4 and self.worldwarstatus then
        self.rootItems.desc:setString(gameConfig.strings:string_common("fixedString","servicewar",70))
    elseif self.pageNum == 5 and self.worldwarstatus then
        self.rootItems.desc:setString(gameConfig.strings:string_common("fixedString","servicewar",71))
    elseif self.pageNum == 6 and self.worldwarstatus then
        if self.worldwarstatus.s_open == 1 then
            self.rootItems.desc:setString(gameConfig.strings:string_common("fixedString","servicewar",73))
        else
            self.rootItems.desc:setString(string.format(gameConfig.strings:string_common("fixedString","servicewar",72), gameConfig.strings:string_common("fixedString","servicewarlist",self.worldwarstatus.list)))
        end
    elseif self.pageNum == 7 and self.worldwarstatus then
        self.rootItems.desc:setString(gameConfig.strings:string_common("fixedString","servicewar",74))
    elseif self.pageNum == 8 and self.worldwarstatus then
        self.rootItems.desc:setString(gameConfig.strings:string_common("fixedString","servicewar",70))
    elseif self.pageNum == 9 and self.worldwarstatus then
        self.rootItems.desc:setString(gameConfig.strings:string_common("fixedString","servicewar",71))
    elseif self.pageNum == 10 and self.worldwarstatus then
        self.rootItems.desc:setString(string.format(gameConfig.strings:string_common("fixedString","servicewar",72), gameConfig.strings:string_common("fixedString","servicewarlist",5)))
    else
        self.rootItems.desc:setString("")
    end

    if self.pageNum <= 2 then
        self:shiftPage("personal")
    elseif self.pageNum ==3 then
        self:shiftPage("group")
    elseif self.pageNum <= 6 then
        if self.pageNum == 4 then
            setSpriteFrameByName(self.rootItems["championSpr"], "kuafuzhan8jin4")
            self.rootItems.championccbnode1:setVisible(true)
            self.rootItems.championccbnode2:setVisible(false)
            self.rootItems.championccbnode3:setVisible(false)
            self.rootItems.championccbnode1:setPositionX(0)
            self.rootItems.championccbnode2:setPositionX(-9999)
            self.rootItems.championccbnode3:setPositionX(-9999)
        elseif self.pageNum == 5 then
            setSpriteFrameByName(self.rootItems["championSpr"], "kuafuzhan4jin2")
            self.rootItems.championccbnode1:setVisible(false)
            self.rootItems.championccbnode2:setVisible(true)
            self.rootItems.championccbnode3:setVisible(false)
            self.rootItems.championccbnode1:setPositionX(-9999)
            self.rootItems.championccbnode2:setPositionX(0)
            self.rootItems.championccbnode3:setPositionX(-9999)
        else
            setSpriteFrameByName(self.rootItems["championSpr"], (self.worldwarstatus.s_open == 1 and "kuafuzhan_jinjisaiguanjun" or "zongguanjun"))
            self.rootItems.championccbnode1:setVisible(false)
            self.rootItems.championccbnode2:setVisible(false)
            self.rootItems.championccbnode3:setVisible(true)
            self.rootItems.championccbnode1:setPositionX(-9999)
            self.rootItems.championccbnode2:setPositionX(-9999)
            self.rootItems.championccbnode3:setPositionX(0)
        end

        self:shiftPage("champion")
    elseif self.pageNum == 7 then
        self:shiftPage("s_personal")
    elseif self.pageNum <= 10 then
        if self.pageNum == 8 then
            setSpriteFrameByName(self.rootItems["championSpr"], "kuafuzhan8jin4_2")
            self.rootItems.championccbnode1:setVisible(true)
            self.rootItems.championccbnode2:setVisible(false)
            self.rootItems.championccbnode3:setVisible(false)
            self.rootItems.championccbnode1:setPositionX(0)
            self.rootItems.championccbnode2:setPositionX(-9999)
            self.rootItems.championccbnode3:setPositionX(-9999)
        elseif self.pageNum == 9 then
            setSpriteFrameByName(self.rootItems["championSpr"], "kuafuzhan4jin2_2")
            self.rootItems.championccbnode1:setVisible(false)
            self.rootItems.championccbnode2:setVisible(true)
            self.rootItems.championccbnode3:setVisible(false)
            self.rootItems.championccbnode1:setPositionX(-9999)
            self.rootItems.championccbnode2:setPositionX(0)
            self.rootItems.championccbnode3:setPositionX(-9999)
        else
            setSpriteFrameByName(self.rootItems["championSpr"], "kuafuzhan_zongguanjun")
            self.rootItems.championccbnode1:setVisible(false)
            self.rootItems.championccbnode2:setVisible(false)
            self.rootItems.championccbnode3:setVisible(true)
            self.rootItems.championccbnode1:setPositionX(-9999)
            self.rootItems.championccbnode2:setPositionX(-9999)
            self.rootItems.championccbnode3:setPositionX(0)
        end
        self:shiftPage("s_champion")
    end

    self:setCountDown()

end

function servicewarNow.setCountDown(self)
    --bettime
    if self.rootItems.bettime then 
        if self.worldwarstatus and self.worldwarstatus.status and self.worldwarstatus.status > 0 then
            local bettime = 0
            local bettimestr = ""
            local now = os.date("*t", gamedata:time())
            if self.pageNum == 3 and self.worldwarstatus.status == gameConfig.serverWarStage.Guess_64To32 then
                local hour,min,sec = ui.getGangBattleTime(gamedata.config.cross_battle_time[tostring(self.worldwarstatus.status)].over_time)
                bettime = hour*3600+min*60+sec-now.hour*3600-now.min*60-now.sec
                bettimestr = "64进32押注结束倒计时："
            elseif self.pageNum == 3 and self.worldwarstatus.status == gameConfig.serverWarStage.Guess_32To16 then
                local hour,min,sec = ui.getGangBattleTime(gamedata.config.cross_battle_time[tostring(self.worldwarstatus.status)].over_time)
                bettime = hour*3600+min*60+sec-now.hour*3600-now.min*60-now.sec
                bettimestr = "32进16押注结束倒计时："
            elseif self.pageNum == 3 and self.worldwarstatus.status == gameConfig.serverWarStage.Guess_16To8 then
                local hour,min,sec = ui.getGangBattleTime(gamedata.config.cross_battle_time[tostring(self.worldwarstatus.status)].over_time)
                bettime = hour*3600+min*60+sec-now.hour*3600-now.min*60-now.sec
                bettimestr = "16进8押注结束倒计时："
            elseif self.pageNum == 4 and self.worldwarstatus.status == gameConfig.serverWarStage.Guess_8To4 then
                local hour,min,sec = ui.getGangBattleTime(gamedata.config.cross_battle_time[tostring(self.worldwarstatus.status)].over_time)
                bettime = hour*3600+min*60+sec-now.hour*3600-now.min*60-now.sec
                bettimestr = "8进4押注结束倒计时："
            elseif self.pageNum == 5 and self.worldwarstatus.status == gameConfig.serverWarStage.Guess_4To2 then
                local hour,min,sec = ui.getGangBattleTime(gamedata.config.cross_battle_time[tostring(self.worldwarstatus.status)].over_time)
                bettime = hour*3600+min*60+sec-now.hour*3600-now.min*60-now.sec
                bettimestr = "半决赛押注结束倒计时："
            elseif self.pageNum == 6 and self.worldwarstatus.status == gameConfig.serverWarStage.Guess_2To1 then
                local hour,min,sec = ui.getGangBattleTime(gamedata.config.cross_battle_time[tostring(self.worldwarstatus.status)].over_time)
                bettime = hour*3600+min*60+sec-now.hour*3600-now.min*60-now.sec
                bettimestr = "决赛押注结束倒计时："
            elseif self.pageNum == 8 and self.worldwarstatus.status == gameConfig.serverWarStage.Guess_S_8To4 then
                local hour,min,sec = ui.getGangBattleTime(gamedata.config.cross_battle_time[tostring(self.worldwarstatus.status)].over_time)
                bettime = hour*3600+min*60+sec-now.hour*3600-now.min*60-now.sec
                bettimestr = "8进4押注结束倒计时："
            elseif self.pageNum == 9 and self.worldwarstatus.status == gameConfig.serverWarStage.Guess_S_4To2 then
                local hour,min,sec = ui.getGangBattleTime(gamedata.config.cross_battle_time[tostring(self.worldwarstatus.status)].over_time)
                bettime = hour*3600+min*60+sec-now.hour*3600-now.min*60-now.sec
                bettimestr = "半决赛押注结束倒计时："
            elseif self.pageNum == 10 and self.worldwarstatus.status == gameConfig.serverWarStage.Guess_S_2To1 then
                local hour,min,sec = ui.getGangBattleTime(gamedata.config.cross_battle_time[tostring(self.worldwarstatus.status)].over_time)
                bettime = hour*3600+min*60+sec-now.hour*3600-now.min*60-now.sec
                bettimestr = "决赛押注结束倒计时："
            end
            if bettime > 0 then
                self.rootItems.bettime:setVisible(true)
                gameTimer:rigistTime("servicewar_bettime",bettime)
                if gameTimer.times["servicewar_bettime"] and gameTimer.times["servicewar_bettime"] > 0 then
                    gameTimer:rigistTimeFunc("servicewar_bettime", function()
                        if gameTimer.times["servicewar_bettime"] <= 0 then
                            self.rootItems.bettime:setVisible(false)
                            if gameTimer.times["servicewar_bettime"] then
                                gameTimer:UnrigistTimeFunc("servicewar_bettime")
                            end
                        else
                            ui.setLabelString(self.rootItems.bettime,bettimestr..ui.makeTimeDayText(gameTimer.times["servicewar_bettime"],"hour"),23)
                        end
                    end)
                end
            else
                self.rootItems.bettime:setVisible(false)
            end    
        else
            self.rootItems.bettime:setVisible(false)
        end    
    end
end

function servicewarNow.updatatime(self)
    local timeconfig = gamedata.config.cross_battle_time or {}

    local tt = "1"
    if gamedata.config.cross_battle_time[tostring(self.worldwarstatus.status+1)] then
        tt = tostring(self.worldwarstatus.status+1)
    end
    local wday = gamedata.config.cross_battle_time[tt].open_week+1
    if wday > 7 then wday = 1 end
    local hour,min,sec = ui.getGangBattleTime(gamedata.config.cross_battle_time[tt].open_time)
    local nowtime = os.date("*t", gamedata:time())
    local diff = (wday-nowtime.wday)*86400+(hour-nowtime.hour)*3600+(min-nowtime.min)*60+sec-nowtime.sec
    if diff < 0 then diff = diff+86400*7 end

    gameTimer:rigistTime("worldwarupdatetimer",diff+1)
    gameTimer:rigistTimeFunc("worldwarupdatetimer",function()
        if gameTimer.times["worldwarupdatetimer"] <= 0 then
            UIRequest({type = 4702, param = "update"})
        end
    end)
    --

end

function servicewarNow.getBattleStatus(self)
    local battleStatus = 1
    if self.worldwarstatus.status <= gameConfig.serverWarStage.Upload_Array then
        battleStatus = 1
    elseif self.worldwarstatus.status >= gameConfig.serverWarStage.Began_Audition and self.worldwarstatus.status <= gameConfig.serverWarStage.Show_Audition then
        battleStatus = 2
    elseif self.worldwarstatus.status >= gameConfig.serverWarStage.Guess_64To32 and self.worldwarstatus.status <= (self.worldwarstatus.s_open == 1 and gameConfig.serverWarStage.Show_64To8 or gameConfig.serverWarStage.Battle_64To8_3) then
        battleStatus = 3
    elseif self.worldwarstatus.status >= gameConfig.serverWarStage.Guess_8To4 and self.worldwarstatus.status <= (self.worldwarstatus.s_open == 1 and gameConfig.serverWarStage.Battle_8To4_3 or gameConfig.serverWarStage.Show_result_4) then
        battleStatus = 4
    elseif self.worldwarstatus.status >= gameConfig.serverWarStage.Guess_4To2 and self.worldwarstatus.status <= gameConfig.serverWarStage.Battle_4To2_3 then
        battleStatus = 5
    elseif self.worldwarstatus.status >= gameConfig.serverWarStage.Guess_2To1 and self.worldwarstatus.status <= gameConfig.serverWarStage.Show_Champion then
        battleStatus = 6
    elseif self.worldwarstatus.status >= gameConfig.serverWarStage.Began_S_Audition and self.worldwarstatus.status <= gameConfig.serverWarStage.Show_S_Audition then
        battleStatus = 7
    elseif self.worldwarstatus.status >= gameConfig.serverWarStage.Guess_S_8To4 and self.worldwarstatus.status <= gameConfig.serverWarStage.Battle_S_8To4_3 then
        battleStatus = 8
    elseif self.worldwarstatus.status >= gameConfig.serverWarStage.Guess_S_4To2 and self.worldwarstatus.status <= gameConfig.serverWarStage.Battle_S_4To2_3 then
        battleStatus = 9
    elseif self.worldwarstatus.status >= gameConfig.serverWarStage.Guess_S_2To1 and self.worldwarstatus.status <= gameConfig.serverWarStage.Show_S_Champion then
        battleStatus = 10
    end
    return battleStatus
end

function servicewarNow.initDataForShenbang(self)
    --神榜开启并且分组>0
    if self.worldwarstatus.s_open == 1 and self.worldwarstatus.divisionNum > 0 and not self.selectDivision then
        self:createDivisionNode()
    end
end

function servicewarNow.ReloadData(self,data)

    if data and data.worldwarstatus then
        self.worldwarstatus = data.worldwarstatus
    end

    if self.worldwarstatus.status < gameConfig.serverWarStage.Began_Audition then
        GameScene:shiftLayer("main","down")
        return
    end

    self:initDataForShenbang()

    print("pageNum",self.pageNum)
    --第几届跨服战
    self.rootItems.title:setString( gameConfig.strings:servicewar_title_num(self.worldwarstatus.number) )

    if self.pageNum == 1 then
        self.rootItems.nowarNode:setVisible(true)
        self.rootItems.haswarNode:setVisible(false)

        if self.worldwarstatus.competition < 1 then
            self.rootItems.nowardesc:setString(gameConfig.strings:string_common("fixedString","servicewar",22))
        elseif self.worldwarstatus.status < gameConfig.serverWarStage.End_Audition then
            self.rootItems.nowardesc:setString(gameConfig.strings:string_common("fixedString","servicewar",23))
        else
            self.rootItems.nowardesc:setString(gameConfig.strings:string_common("fixedString","servicewar",23))
        end


    elseif self.pageNum == 2 then
        self.rootItems.nowarNode:setVisible(true)
        self.rootItems.haswarNode:setVisible(false)
        if self.worldwarstatus.competition < 1 then
            self.rootItems.nowardesc:setString(gameConfig.strings:string_common("fixedString","servicewar",22))
        elseif self.worldwarstatus.status < gameConfig.serverWarStage.End_Audition then
            self.rootItems.nowardesc:setString(gameConfig.strings:string_common("fixedString","servicewar",23))
        else
            self.rootItems.nowarNode:setVisible(false)
            self.rootItems.haswarNode:setVisible(true)
        end
    elseif self.pageNum == 7 then
        self.rootItems.nowarNode:setVisible(true)
        self.rootItems.haswarNode:setVisible(false)

        if self.worldwarstatus.promotion < 1 then
            self.rootItems.nowardesc:setString(gameConfig.strings:string_common("fixedString","servicewar",22))
        elseif self.worldwarstatus.status < gameConfig.serverWarStage.End_S_Audition then
            self.rootItems.nowardesc:setString(gameConfig.strings:string_common("fixedString","servicewar",68))
        else
            self.rootItems.nowarNode:setVisible(false)
            self.rootItems.haswarNode:setVisible(true)
        end
    end


    local battleStatus = self:getBattleStatus()

    for i=1,10 do
        if self.worldwarstatus.list > 0 then
            if self.worldwarstatus.status then

                if i <= battleStatus then
                    --self.rootItems["selectnum"..i]:setVisible(true)
                    setSpriteFrameByName(self.rootItems["statusnum"..i], "kuafuzha_n_4")
                else
                    --self.rootItems["selectnum"..i]:setVisible(false)
                    setSpriteFrameByName(self.rootItems["statusnum"..i], "kuafuzha_n_4_h")
                end
            else
                --self.rootItems["selectnum"..i]:setVisible(false)
                setSpriteFrameByName(self.rootItems["statusnum"..i], "kuafuzha_n_4_h")
            end
        else
            --self.rootItems["selectnum"..i]:setVisible(false)
            setSpriteFrameByName(self.rootItems["statusnum"..i], "kuafuzha_n_4_h")
        end
    end

    if self.isOpenStatus == 0 then
        self.isOpenStatus = 1
        if GameScene.priorLayer == "servicewarAfter" then
            self:shiftPageNum(self.lastPageNum)
        else
            self:shiftPageNum(battleStatus)
        end
    end

    if data and data.worldwarrolebattles then
        self.worldwarrolebattles = {}
        for k,v in pairs(data.worldwarrolebattles) do
            v.k = tonumber(k)
            table.insert(self.worldwarrolebattles,v)
        end
        local sortfunc = function (a,b)
            return a.k > b.k
        end
        table.sort(self.worldwarrolebattles,sortfunc)
    end

    if data and data.worldwarrolebattlesShenbang then
        self.worldwarrolebattlesShenbang = {}
        for k,v in pairs(data.worldwarrolebattlesShenbang) do
            v.k = tonumber(k)
            table.insert(self.worldwarrolebattlesShenbang,v)
        end
        local sortfunc = function (a,b)
            return a.k > b.k
        end
        table.sort(self.worldwarrolebattlesShenbang,sortfunc)
    end
    --

    if self.worldwarstatus.list == 1 then
        self.rootItems.listSprite1:setVisible(true)
        self.rootItems.listSprite2:setVisible(false)
        self.rootItems.listSprite3:setVisible(false)
        self.rootItems.listSprite4:setVisible(false)
        self.rootItems.listSprite5:setVisible(false)
    elseif self.worldwarstatus.list == 2 then
        self.rootItems.listSprite1:setVisible(false)
        self.rootItems.listSprite2:setVisible(true)
        self.rootItems.listSprite3:setVisible(false)
        self.rootItems.listSprite4:setVisible(false)
        self.rootItems.listSprite5:setVisible(false)
    elseif self.worldwarstatus.list == 3 then
        self.rootItems.listSprite1:setVisible(false)
        self.rootItems.listSprite2:setVisible(false)
        self.rootItems.listSprite3:setVisible(true)
        self.rootItems.listSprite4:setVisible(false)
        self.rootItems.listSprite5:setVisible(false)
    elseif self.worldwarstatus.list == 4 then
        self.rootItems.listSprite1:setVisible(false)
        self.rootItems.listSprite2:setVisible(false)
        self.rootItems.listSprite3:setVisible(false)
        self.rootItems.listSprite4:setVisible(true)
        self.rootItems.listSprite5:setVisible(false)
    elseif self.worldwarstatus.list == 5 then
        self.rootItems.listSprite1:setVisible(false)
        self.rootItems.listSprite2:setVisible(false)
        self.rootItems.listSprite3:setVisible(false)
        self.rootItems.listSprite4:setVisible(false)
        self.rootItems.listSprite5:setVisible(true)
    else
        self.rootItems.listSprite1:setVisible(true)
        self.rootItems.listSprite2:setVisible(false)
        self.rootItems.listSprite3:setVisible(false)
        self.rootItems.listSprite4:setVisible(false)
        self.rootItems.listSprite5:setVisible(false)
    end

    if self.worldwarstatus.status > 1 and self.worldwarstatus.status <= gameConfig.serverWarStage.Show_Audition then
        ui.setLabelString(self.rootItems.phase,gameConfig.strings:string_common("fixedString","servicewar",15),21)
    elseif self.worldwarstatus.status >= gameConfig.serverWarStage.Guess_64To32 and self.worldwarstatus.status <= (self.worldwarstatus.s_open == 1 and gameConfig.serverWarStage.Show_64To8 or gameConfig.serverWarStage.Battle_64To8_3) then
        ui.setLabelString(self.rootItems.phase,gameConfig.strings:string_common("fixedString","servicewar",10),21)
    elseif self.worldwarstatus.status >= gameConfig.serverWarStage.Guess_8To4 and self.worldwarstatus.status <= gameConfig.serverWarStage.Show_Champion then
        ui.setLabelString(self.rootItems.phase,self.worldwarstatus.s_open == 1 and gameConfig.strings:string_common("fixedString","servicewar",66) or gameConfig.strings:string_common("fixedString","servicewar",11),21)
    elseif self.worldwarstatus.status >= gameConfig.serverWarStage.Began_S_Audition then
        ui.setLabelString(self.rootItems.phase,gameConfig.strings:string_common("fixedString","servicewar",11),21)
    else
        ui.setLabelString(self.rootItems.phase,"",21)
    end

    --
    self.rootItems.listButton:setTouchPriority(self.buttontouch)
    self.rootItems.listButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        --todo 榜
        gameWindows:openWindow("servicewarchampionlist",{index = "matchinfo"})
    end, CCControlEventTouchUpInside)
    --
    self.rootItems.ruleButton:setTouchPriority(self.buttontouch)
    self.rootItems.ruleButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        --todo 规则
        gameWindows:openWindow("servicewarrule",{opt = 1,shenbang = (self.worldwarstatus.s_open and self.worldwarstatus.s_open == 1)})
    end, CCControlEventTouchUpInside)
    --
    self.rootItems.rankButton:setTouchPriority(self.buttontouch)
    self.rootItems.rankButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        --todo 积分排名
        gameWindows:openWindow("servicewarchampionlist",{index = (self.pageNum >= 7 and "scorerank_s" or "scorerank"),worldwarstatus = self.worldwarstatus.status,division = self.selectDivision})
    end, CCControlEventTouchUpInside)
    --
    self.rootItems.rewardButton:setTouchPriority(self.buttontouch)
    self.rootItems.rewardButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        --todo 查看奖励
        gameWindows:openWindow("servicewarchampionlist",{index = "rewardshow",shenbang = self.pageNum >= 7})
    end, CCControlEventTouchUpInside)
    --

    --
    if self.rootItems and (self.pageNum == 2 or self.pageNum == 7) then
        if not self.ListTableView then
            self:createList()
        else
            local cellNum = (self.pageNum == 2 and table.getTableLength(self.worldwarrolebattles) or table.getTableLength(self.worldwarrolebattlesShenbang))
            self.ListTableView:setLuaContentOffset(0, self.rootItems.listnode:getContentSize().height - cellNum*self.normalCellSize.y)
            self.ListTableView:reloadData()
        end
    end
    self:setGetallNode()
    --
    self:updatatime()

    self:setCountDown()
end

function servicewarNow.setChampionNode(self,t)
   if t then
        self.rootItems.servicewarAfternode:setVisible(true)
   else
        self.rootItems.servicewarAfternode:setVisible(false)
   end

    self.rootItems.servicewarAfterBtn:setTouchPriority(self.buttontouch)
    self.rootItems.servicewarAfterBtn:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        GameScene:shiftLayer("servicewarAfter","up")
    end, CCControlEventTouchUpInside)

end


function  servicewarNow.createList(self)
    local  celldict1 = {}
    local  celldict2 = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true

            local celldata = (self.pageNum == 7 and self.worldwarrolebattlesShenbang[a1+1] or self.worldwarrolebattles[a1+1])

            if (celldata.phase == 1) and not celldict1[a2] then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("kuafuzhan/cell_gerenzhanji2",nil,true,"cell_gerenzhanji2")
                celldict1[a2] = {cellCCB = cellCCB,ccbDocumentControler = ccbDocumentControler}
            elseif (celldata.phase >= 2) and not celldict2[a2] then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("kuafuzhan/cell_gerenzhanji",nil,true,"cell_gerenzhanji")
                celldict2[a2] = {cellCCB = cellCCB,ccbDocumentControler = ccbDocumentControler}
            else
                first = false
                if celldata.phase == 1 then
                    cellCCB = celldict1[a2].cellCCB
                    ccbDocumentControler = celldict1[a2].ccbDocumentControler
                else
                    cellCCB = celldict2[a2].cellCCB
                    ccbDocumentControler = celldict2[a2].ccbDocumentControler
                end
            end

            self:setCell(ccbDocumentControler,celldata,a1+1)

            cellCCB:setPosition(self.normalCellSize.x/2,0)
            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn=="numberOfCells" then
            if self.pageNum == 7 then
                r = table.getTableLength(self.worldwarrolebattlesShenbang)
            else
                r = table.getTableLength(self.worldwarrolebattles)
            end
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)
    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listnode:getContentSize().width,
        viewheight = self.rootItems.listnode:getContentSize().height,
        dire = 1
    })

    self.rootItems.listnode:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(-101)
end

function servicewarNow.setCell(self,item,data,index)

    ui.setNewIcon(item,{cid = data.profile,title = data.title,iconBox = data.iconBox})
    item.name:setString(data.name)
    ui.setLabelString(item.server_name,(data.server_name ~= "") and ("("..data.server_name..")") or "",14)
    ui.setLabelString(item.number,data.win_count..":"..data.lose_count,13)
    ui.setLabelString(item.result,(data.result == 1) and gameConfig.strings:string_common("fixedString","servicewar",12) or gameConfig.strings:string_common("fixedString","servicewar",13),13)

    ui.setLabelString(item.showLab,gameConfig.strings:string_common("fixedString","servicewar",16),18)
    ui.setLabelString(item.getLab,gameConfig.strings:string_common("fixedString","servicewar",17),18)
    --
    item.showButton:setTouchPriority(-103)
    item.getButton:setTouchPriority(-103)
    --
    if data.phase == 1 then
        ui.setLabelString(item.phase,gameConfig.strings:string_common("fixedString","servicewar",15),23)
        ui.setLabelString(item.round,gameConfig.strings:servicewar_now_round(data.round),14)
        ui.setLabelString(item.point,gameConfig.strings:servicewar_now_point(data.point),21)
        for i = 1,3 do
            if data.star >= i then
                item["star"..i]:setVisible(true)
            else
                item["star"..i]:setVisible(false)
            end
        end
        --
        item.showButton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)

            if self.worldwarstatus.s_open and self.pageNum >= 7 then
                UIRequest({type = 4727,id = data.id})
            else
                UIRequest({type = 4711,id = data.id})
            end
            
        end, CCControlEventTouchUpInside)
        --

    else
        ui.setLabelString(item.phase,gameConfig.strings:string_common("fixedString","servicewar",(data.phase == 3) and 11 or 10),23)
        ui.setLabelString(item.round,gameConfig.strings:servicewar_now_round(data.round),14)
        --
        item.showButton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            -- todo 淘汰赛战报弹窗
            gameWindows:openWindow("servicewarbet",{shenbang = self.pageNum >= 7,division = self.worldwarstatus.curDivision,index = "battleinfo",battleid = data.id})
        end, CCControlEventTouchUpInside)
        --

    end

    --
    if data.reward == 1 then
        item.showNode:setVisible(false)
        item.getNode:setVisible(true)
        ui.removeGray("CCControlButton",item.getButton)
        item.getButton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            UIRequest({type = (self.pageNum == 2 and 4714 or 4723), phase = data.phase, id = data.id})
        end, CCControlEventTouchUpInside)
    elseif data.reward == 2 then
        item.showNode:setVisible(true)
        item.getNode:setVisible(false)
        ui.addGray("CCControlButton",item.getButton)
        item.getButton:addHandleOfControlEvent(function()
            runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",5)})
        end, CCControlEventTouchUpInside)
    else
        item.showNode:setVisible(true)
        item.getNode:setVisible(false)
        ui.addGray("CCControlButton",item.getButton)
        item.getButton:addHandleOfControlEvent(function()
        --
        end, CCControlEventTouchUpInside)
    end
    --
end

function servicewarNow.ReloadPlayers(self,data)
    print("ReloadPlayers")
    printT(self.worldwarplayers)
    printT(self.worldwarplayersShenbang)
    if data and data.worldwarplayers then
        self.worldwarplayers = data.worldwarplayers
    end

    if data and data.worldwarplayersShenbang then
        self.worldwarplayersShenbang = data.worldwarplayersShenbang
    end

    if self.selectpage == "group" then
        self:setGroupIndexDefault()
        self:setGroupData(self.groupindex)
    elseif self.selectpage == "champion" then
        self:setChampionData()
    elseif self.selectpage == "s_champion" then
        self:setChampionData()
    end

end

--获取自己在小组赛里面的分组
function servicewarNow.setGroupIndexDefault(self)
    self.groupindex = 1
    if self.worldwarstatus and self.worldwarstatus.competition == 1 then
        local datatemp = self.worldwartop["1"] or {}
        for k=1,8 do
            for i = 1,4 do
                if datatemp[tostring(4*(k-1)+i)] then
                    local player1 = self.worldwarplayers[tostring(datatemp[tostring(4*(k-1)+i)].p_id1)] or {}
                    local player2 = self.worldwarplayers[tostring(datatemp[tostring(4*(k-1)+i)].p_id2)] or {}
                    if player1.isself == 1 or player2.isself == 1 then
                        self.groupindex = k
                        return
                    end
                end
            end
        end
    end
end

function servicewarNow.ReloadTop(self,data)
    print("ReloadTop")
    if data and data.worldwartop then
        self.worldwartop = data.worldwartop
    end

    if data and data.worldwartopShenbang then
        self.worldwartopShenbang = data.worldwartopShenbang
    end

    if self.pageNum > 7 then
        if next(self.worldwarplayersShenbang) then
            self:ReloadPlayers()
        else
            UIRequest({type = 4724})
        end
    else
        if next(self.worldwarplayers) then
            self:ReloadPlayers()
        else
            UIRequest({type = 4712,division = self.selectDivision})
        end
    end

end


function servicewarNow.setGroupData(self,index)



    if self.rootItems then
        if not self.groupListTableView then
            self:creategroupList()
        else
            self.groupListTableView:reloadData()
        end
    end

    if self.worldwarstatus and self.worldwarstatus.status and self.worldwarstatus.status >= (self.worldwarstatus.s_open == 1 and gameConfig.serverWarStage.Show_64To8 or gameConfig.serverWarStage.Battle_64To8_3) then
        setSpriteFrameByName(self.rootItems["xiaozuguanjunSpr"], "xiaozuguanjun2")
    else
        setSpriteFrameByName(self.rootItems["xiaozuguanjunSpr"], "xiaozuguanjun")
    end


    self:checkSetX()
    --
    local betplayers = self.worldwartop.betplayers or {}
    --
    local datatemp = self.worldwartop["1"] or {}

    for i = 1,4 do
        if datatemp[tostring(4*(index-1)+i)] then
            local player1 = self.worldwarplayers[tostring(datatemp[tostring(4*(index-1)+i)].p_id1)] or {}
            local player2 = self.worldwarplayers[tostring(datatemp[tostring(4*(index-1)+i)].p_id2)] or {}
            ui.setLabelString(self.grouprootItems["i_name_"..(2*i-1)],player1.name,1028)
            ui.setLabelString(self.grouprootItems["i_name_"..(2*i)],player2.name,1028)
            ui.setLabelString(self.grouprootItems["i_servername_"..(2*i-1)],player1.server_name,13)
            ui.setLabelString(self.grouprootItems["i_servername_"..(2*i)],player2.server_name,13)
            setSpriteFrameByName(self.grouprootItems["i_icon_"..(2*i-1)], ui.IDconfig(player1.profile) and ui.IDconfig(player1.profile).icon or "obj_icon_pz_general")
            setSpriteFrameByName(self.grouprootItems["i_icon_"..(2*i)], ui.IDconfig(player2.profile) and ui.IDconfig(player2.profile).icon or "obj_icon_pz_general")
            ui.setSpriteTextureRect(self.grouprootItems["i_icon_"..(2*i-1)],0,0,150,150)
            ui.setSpriteTextureRect(self.grouprootItems["i_icon_"..(2*i)],0,0,150,150)
            --
            local result = datatemp[tostring(4*(index-1)+i)].result or -1
            if result == 1 then
                self.grouprootItems["w_"..i.."_1"]:setVisible(true)
                self.grouprootItems["w_"..i.."_2"]:setVisible(false)
            elseif result == 0 then
                self.grouprootItems["w_"..i.."_1"]:setVisible(false)
                self.grouprootItems["w_"..i.."_2"]:setVisible(true)
            else
                self.grouprootItems["w_"..i.."_1"]:setVisible(false)
                self.grouprootItems["w_"..i.."_2"]:setVisible(false)
            end
            --button   todo
            self.grouprootItems["w_button_c"..i]:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(1)

                if self.worldwarstatus.s_open == 1 and self.worldwarstatus.curDivision ~= self.selectDivision and self.pageNum < 7 and self.worldwarstatus.status == gameConfig.serverWarStage.Guess_64To32 then
                    runGamePrompt({msg = gameConfig.strings:string_common("fixedString","servicewar",67)})
                elseif self.worldwarstatus.status > gameConfig.serverWarStage.Guess_64To32 then
                    gameWindows:openWindow("servicewarbet",{shenbang = self.pageNum > 7,division = self.selectDivision,index = "battleinfo",battleid = datatemp[tostring(4*(index-1)+i)].id})
                else
                    runGamePrompt({msg = gameConfig.strings:string_common("fixedString","servicewar",24)})
                end
            end, CCControlEventTouchUpInside)
            --
            self.grouprootItems["w_button_j"..i]:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(1)
                gameWindows:openWindow("servicewarbet",{shenbang = self.pageNum > 7,division = self.selectDivision,index = "bet",battleid = datatemp[tostring(4*(index-1)+i)].id,battlefieldid1 = 65,battlefieldid2 = 67})
            end, CCControlEventTouchUpInside)
            --
            if self.worldwarstatus.s_open == 1 and self.worldwarstatus.curDivision ~= self.selectDivision and self.pageNum < 7 and self.worldwarstatus.status == gameConfig.serverWarStage.Guess_64To32 then
                self.grouprootItems["w_button_c"..i]:setVisible(true)
                self.grouprootItems["w_button_j"..i]:setVisible(false)
                ui.addGray("CCControlButton",self.grouprootItems["w_button_c"..i])
            elseif self.worldwarstatus.status == gameConfig.serverWarStage.Guess_64To32 then
                self.grouprootItems["w_button_c"..i]:setVisible(false)
                self.grouprootItems["w_button_j"..i]:setVisible(true)
            elseif self.worldwarstatus.status > gameConfig.serverWarStage.Guess_64To32 then
                self.grouprootItems["w_button_c"..i]:setVisible(true)
                self.grouprootItems["w_button_j"..i]:setVisible(false)
                ui.removeGray("CCControlButton",self.grouprootItems["w_button_c"..i])
            else
                self.grouprootItems["w_button_c"..i]:setVisible(true)
                self.grouprootItems["w_button_j"..i]:setVisible(false)
                ui.addGray("CCControlButton",self.grouprootItems["w_button_c"..i])
            end
            --
            if self.grouprootItems["i_isbet_"..(2*i-1)] and self.grouprootItems["i_isbet_"..(2*i)] then
                self.grouprootItems["i_isbet_"..(2*i-1)]:setVisible(false)
                self.grouprootItems["i_isbet_"..(2*i)]:setVisible(false)
                
                if self.worldwarstatus.status <= (self.worldwarstatus.s_open == 1 and gameConfig.serverWarStage.Show_64To8 or gameConfig.serverWarStage.Battle_64To8_3) then
                    for k,v in pairs(betplayers) do
                        if v == datatemp[tostring(4*(index-1)+i)].p_id1 then
                            self.grouprootItems["i_isbet_"..(2*i-1)]:setVisible(true)
                        elseif v == datatemp[tostring(4*(index-1)+i)].p_id2 then
                            self.grouprootItems["i_isbet_"..(2*i)]:setVisible(true)
                        end
                    end
                end

            end
            --
            if self.grouprootItems["w_bet_s"..i] and datatemp[tostring(4*(index-1)+i)].bet then
                if datatemp[tostring(4*(index-1)+i)].bet == 1 then
                    setSpriteFrameByName(self.grouprootItems["w_bet_s"..i], "_0015_2")
                elseif datatemp[tostring(4*(index-1)+i)].bet == 2 then
                    setSpriteFrameByName(self.grouprootItems["w_bet_s"..i], "_0009_1_2")
                elseif datatemp[tostring(4*(index-1)+i)].bet == 3 then
                    setSpriteFrameByName(self.grouprootItems["w_bet_s"..i], "_0009_1")
                else
                    setSpriteFrameByName(self.grouprootItems["w_bet_s"..i], "alpha")
                end
            end
        else
            ui.setLabelString(self.grouprootItems["i_name_"..(2*i-1)],"",1028)
            ui.setLabelString(self.grouprootItems["i_servername_"..(2*i-1)],"",13)
            ui.setLabelString(self.grouprootItems["i_name_"..(2*i)],"",1028)
            ui.setLabelString(self.grouprootItems["i_servername_"..(2*i)],"",13)
            setSpriteFrameByName(self.grouprootItems["i_icon_"..(2*i-1)], "obj_icon_pz_general")
            setSpriteFrameByName(self.grouprootItems["i_icon_"..(2*i)], "obj_icon_pz_general")
            ui.setSpriteTextureRect(self.grouprootItems["i_icon_"..(2*i-1)],0,0,150,150)
            ui.setSpriteTextureRect(self.grouprootItems["i_icon_"..(2*i)],0,0,150,150)
            self.grouprootItems["w_"..i.."_1"]:setVisible(false)
            self.grouprootItems["w_"..i.."_2"]:setVisible(false)
            --
            self.grouprootItems["w_button_c"..i]:setVisible(true)
            self.grouprootItems["w_button_j"..i]:setVisible(false)
            ui.addGray("CCControlButton",self.grouprootItems["w_button_c"..i])
            --
            self.grouprootItems["w_button_c"..i]:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(1)
                runGamePrompt({msg = gameConfig.strings:string_common("fixedString","servicewar",24)})
            end, CCControlEventTouchUpInside)
            --
            self.grouprootItems["w_button_j"..i]:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(1)
             end, CCControlEventTouchUpInside)
            --
            if self.grouprootItems["i_isbet_"..(2*i-1)] and self.grouprootItems["i_isbet_"..(2*i)] then
                self.grouprootItems["i_isbet_"..(2*i-1)]:setVisible(false)
                self.grouprootItems["i_isbet_"..(2*i)]:setVisible(false)
            end
            --
            if self.grouprootItems["w_bet_s"..i] then
                setSpriteFrameByName(self.grouprootItems["w_bet_s"..i], "alpha")
            end
        end
    end

    --
    local datatemp2 = self.worldwartop["2"] or {}
    for i = 1,2 do
        if datatemp2[tostring(2*(index-1)+i)] then
            local result = datatemp2[tostring(2*(index-1)+i)].result or -1
            if result == 1 then
                self.grouprootItems["w_"..(4+i).."_1"]:setVisible(true)
                self.grouprootItems["w_"..(4+i).."_2"]:setVisible(false)
            elseif result == 0 then
                self.grouprootItems["w_"..(4+i).."_1"]:setVisible(false)
                self.grouprootItems["w_"..(4+i).."_2"]:setVisible(true)
            else
                self.grouprootItems["w_"..(4+i).."_1"]:setVisible(false)
                self.grouprootItems["w_"..(4+i).."_2"]:setVisible(false)
            end
            --button   todo
            self.grouprootItems["w_button_c"..(4+i)]:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(1)
                if self.worldwarstatus.s_open == 1 and self.worldwarstatus.curDivision ~= self.selectDivision and self.pageNum < 7 and self.worldwarstatus.status == gameConfig.serverWarStage.Guess_32To16 then
                    runGamePrompt({msg = gameConfig.strings:string_common("fixedString","servicewar",67)})
                elseif self.worldwarstatus.status > gameConfig.serverWarStage.Guess_32To16 then
                    gameWindows:openWindow("servicewarbet",{shenbang = self.pageNum > 7,division = self.selectDivision,index = "battleinfo",battleid = datatemp2[tostring(2*(index-1)+i)].id})
                else
                    runGamePrompt({msg = gameConfig.strings:string_common("fixedString","servicewar",24)})
                end
            end, CCControlEventTouchUpInside)
            --
            self.grouprootItems["w_button_j"..(4+i)]:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(1)
                gameWindows:openWindow("servicewarbet",{shenbang = self.pageNum > 7,division = self.selectDivision,index = "bet",battleid = datatemp2[tostring(2*(index-1)+i)].id,battlefieldid1 = 69,battlefieldid2 = 71})
            end, CCControlEventTouchUpInside)
            --
            if self.worldwarstatus.s_open == 1 and self.worldwarstatus.curDivision ~= self.selectDivision and self.pageNum < 7 and self.worldwarstatus.status == gameConfig.serverWarStage.Guess_32To16 then
                self.grouprootItems["w_button_c"..(4+i)]:setVisible(true)
                self.grouprootItems["w_button_j"..(4+i)]:setVisible(false)
                ui.addGray("CCControlButton",self.grouprootItems["w_button_c"..(4+i)])
            elseif self.worldwarstatus.status == gameConfig.serverWarStage.Guess_32To16 then
                self.grouprootItems["w_button_c"..(4+i)]:setVisible(false)
                self.grouprootItems["w_button_j"..(4+i)]:setVisible(true)
            elseif self.worldwarstatus.status > gameConfig.serverWarStage.Guess_32To16 then
                self.grouprootItems["w_button_c"..(4+i)]:setVisible(true)
                self.grouprootItems["w_button_j"..(4+i)]:setVisible(false)
                ui.removeGray("CCControlButton",self.grouprootItems["w_button_c"..(4+i)])
            else
                self.grouprootItems["w_button_c"..(4+i)]:setVisible(true)
                self.grouprootItems["w_button_j"..(4+i)]:setVisible(false)
                ui.addGray("CCControlButton",self.grouprootItems["w_button_c"..(4+i)])
            end
            --
            if self.grouprootItems["w_bet_s"..(4+i)] and datatemp2[tostring(2*(index-1)+i)].bet then
                if datatemp2[tostring(2*(index-1)+i)].bet == 1 then
                    setSpriteFrameByName(self.grouprootItems["w_bet_s"..(4+i)], "_0015_2")
                elseif datatemp2[tostring(2*(index-1)+i)].bet == 2 then
                    setSpriteFrameByName(self.grouprootItems["w_bet_s"..(4+i)], "_0009_1_2")
                elseif datatemp2[tostring(2*(index-1)+i)].bet == 3 then
                    setSpriteFrameByName(self.grouprootItems["w_bet_s"..(4+i)], "_0009_1")
                else
                    setSpriteFrameByName(self.grouprootItems["w_bet_s"..(4+i)], "alpha")
                end
            end
        else
            self.grouprootItems["w_"..(4+i).."_1"]:setVisible(false)
            self.grouprootItems["w_"..(4+i).."_2"]:setVisible(false)
            --
            self.grouprootItems["w_button_c"..(4+i)]:setVisible(true)
            self.grouprootItems["w_button_j"..(4+i)]:setVisible(false)
            ui.addGray("CCControlButton",self.grouprootItems["w_button_c"..(4+i)])
            --
            self.grouprootItems["w_button_c"..(4+i)]:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(1)
                runGamePrompt({msg = gameConfig.strings:string_common("fixedString","servicewar",24)})
            end, CCControlEventTouchUpInside)
            --
            self.grouprootItems["w_button_j"..(4+i)]:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(1)
            end, CCControlEventTouchUpInside)
            --
            if self.grouprootItems["w_bet_s"..(4+i)] then
                setSpriteFrameByName(self.grouprootItems["w_bet_s"..(4+i)], "alpha")
            end
        end
    end
    --
    local datatemp3 = self.worldwartop["3"] or {}
    if self.grouprootItems["i_isbet"] and self.grouprootItems["i_isbet"] then
        self.grouprootItems["i_isbet"]:setVisible(false)
        self.grouprootItems["i_isbet"]:setVisible(false)
    end
    if datatemp3[tostring(index)] then
        local player1 = self.worldwarplayers[tostring(datatemp3[tostring(index)].p_id1)] or {}
        local player2 = self.worldwarplayers[tostring(datatemp3[tostring(index)].p_id2)] or {}
        local result = datatemp3[tostring(index)].result or -1
        if result == 1 then
            self.grouprootItems["w_7_1"]:setVisible(true)
            self.grouprootItems["w_7_2"]:setVisible(false)
            --
            ui.setLabelString(self.grouprootItems["i_name"],player1.name,1028)
            ui.setLabelString(self.grouprootItems["i_servername"],player1.server_name,13)
            setSpriteFrameByName(self.grouprootItems["i_icon"], ui.IDconfig(player1.profile) and ui.IDconfig(player1.profile).icon or "obj_icon_pz_general")
            ui.setSpriteTextureRect(self.grouprootItems["i_icon"],0,0,150,150)
        elseif result == 0 then
            self.grouprootItems["w_7_1"]:setVisible(false)
            self.grouprootItems["w_7_2"]:setVisible(true)
            --
            ui.setLabelString(self.grouprootItems["i_name"],player2.name,1028)
            ui.setLabelString(self.grouprootItems["i_servername"],player2.server_name,13)
            setSpriteFrameByName(self.grouprootItems["i_icon"], ui.IDconfig(player2.profile) and ui.IDconfig(player2.profile).icon or "obj_icon_pz_general")
            ui.setSpriteTextureRect(self.grouprootItems["i_icon"],0,0,150,150)
        else
            self.grouprootItems["w_7_1"]:setVisible(false)
            self.grouprootItems["w_7_2"]:setVisible(false)
            --
            ui.setLabelString(self.grouprootItems["i_name"],"",1028)
            ui.setLabelString(self.grouprootItems["i_servername"],"",13)
            setSpriteFrameByName(self.grouprootItems["i_icon"],"obj_icon_pz_general")
            ui.setSpriteTextureRect(self.grouprootItems["i_icon"],0,0,150,150)
        end
        --button   todo
        self.grouprootItems["w_button_c"..7]:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            if self.worldwarstatus.s_open == 1 and self.worldwarstatus.curDivision ~= self.selectDivision and self.pageNum < 7 and self.worldwarstatus.status == gameConfig.serverWarStage.Guess_16To8 then
                runGamePrompt({msg = gameConfig.strings:string_common("fixedString","servicewar",67)})
            elseif self.worldwarstatus.status > gameConfig.serverWarStage.Guess_16To8 then
                gameWindows:openWindow("servicewarbet",{shenbang = self.pageNum > 7,division = self.selectDivision,index = "battleinfo",battleid = datatemp3[tostring(index)].id})
            else
                runGamePrompt({msg = gameConfig.strings:string_common("fixedString","servicewar",24)})
            end
        end, CCControlEventTouchUpInside)
        --
        self.grouprootItems["w_button_j"..7]:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            gameWindows:openWindow("servicewarbet",{shenbang = self.pageNum > 7,division = self.selectDivision,index = "bet",battleid = datatemp3[tostring(index)].id,battlefieldid1 = 74,battlefieldid2 = 76})
        end, CCControlEventTouchUpInside)
        --
        if self.worldwarstatus.s_open == 1 and self.worldwarstatus.curDivision ~= self.selectDivision and self.pageNum < 7 and self.worldwarstatus.status == gameConfig.serverWarStage.Guess_16To8 then
            self.grouprootItems["w_button_c"..7]:setVisible(true)
            self.grouprootItems["w_button_j"..7]:setVisible(false)
            ui.addGray("CCControlButton",self.grouprootItems["w_button_c"..7])
        elseif self.worldwarstatus.status == gameConfig.serverWarStage.Guess_16To8 then
            self.grouprootItems["w_button_c"..7]:setVisible(false)
            self.grouprootItems["w_button_j"..7]:setVisible(true)
        elseif self.worldwarstatus.status > gameConfig.serverWarStage.Guess_16To8 then
            self.grouprootItems["w_button_c"..7]:setVisible(true)
            self.grouprootItems["w_button_j"..7]:setVisible(false)
            ui.removeGray("CCControlButton",self.grouprootItems["w_button_c"..7])
        else
            self.grouprootItems["w_button_c"..7]:setVisible(true)
            self.grouprootItems["w_button_j"..7]:setVisible(false)
            ui.addGray("CCControlButton",self.grouprootItems["w_button_c"..7])
        end
        --
        if self.grouprootItems["w_bet_s"..7] and datatemp3[tostring(index)].bet then
            if datatemp3[tostring(index)].bet == 1 then
                setSpriteFrameByName(self.grouprootItems["w_bet_s"..7], "_0015_2")
            elseif datatemp3[tostring(index)].bet == 2 then
                setSpriteFrameByName(self.grouprootItems["w_bet_s"..7], "_0009_1_2")
            elseif datatemp3[tostring(index)].bet == 3 then
                setSpriteFrameByName(self.grouprootItems["w_bet_s"..7], "_0009_1")
            else
                setSpriteFrameByName(self.grouprootItems["w_bet_s"..7], "alpha")
            end
        end
    else
        self.grouprootItems["w_7_1"]:setVisible(false)
        self.grouprootItems["w_7_2"]:setVisible(false)
        --
        ui.setLabelString(self.grouprootItems["i_name"],"",1028)
        ui.setLabelString(self.grouprootItems["i_servername"],"",13)
        setSpriteFrameByName(self.grouprootItems["i_icon"],"obj_icon_pz_general")
        ui.setSpriteTextureRect(self.grouprootItems["i_icon"],0,0,150,150)
        --
        self.grouprootItems["w_button_c"..7]:setVisible(true)
        self.grouprootItems["w_button_j"..7]:setVisible(false)
        ui.addGray("CCControlButton",self.grouprootItems["w_button_c"..7])
        --
        self.grouprootItems["w_button_c"..7]:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            runGamePrompt({msg = gameConfig.strings:string_common("fixedString","servicewar",24)})
        end, CCControlEventTouchUpInside)
        --
        self.grouprootItems["w_button_j"..7]:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
        end, CCControlEventTouchUpInside)
        --
        if self.grouprootItems["w_bet_s"..7] then
            setSpriteFrameByName(self.grouprootItems["w_bet_s"..7], "alpha")
        end
    end
    --


end


function servicewarNow.setChampionData(self)
    --
    local worldwartop = self.pageNum > 7 and self.worldwartopShenbang or self.worldwartop
    local worldwarplayers = self.pageNum > 7 and self.worldwarplayersShenbang or self.worldwarplayers
    local betplayers = worldwartop.betplayers or {}

    if self.pageNum == 4 or self.pageNum == 8 then
        -- --
        local datatemp = (self.pageNum > 7 and self.worldwartopShenbang["1"] or self.worldwartop["4"]) or {}
        local Guess_8To4 = (self.pageNum == 4 and gameConfig.serverWarStage.Guess_8To4 or gameConfig.serverWarStage.Guess_S_8To4)
        for i = 1,4 do
            if datatemp[tostring(i)] then

                local player1 = worldwarplayers[tostring(datatemp[tostring(i)].p_id1)] or {}
                local player2 = worldwarplayers[tostring(datatemp[tostring(i)].p_id2)] or {}
                ui.setLabelString(self.championrootItems1["i_name_"..(2*i-1)],player1.name,1028)
                ui.setLabelString(self.championrootItems1["i_name_"..(2*i)],player2.name,1028)
                ui.setLabelString(self.championrootItems1["i_servername_"..(2*i-1)],player1.server_name,13)
                ui.setLabelString(self.championrootItems1["i_servername_"..(2*i)],player2.server_name,13)
                setSpriteFrameByName(self.championrootItems1["i_icon_"..(2*i-1)], ui.IDconfig(player1.profile) and ui.IDconfig(player1.profile).icon or "obj_icon_pz_general")
                setSpriteFrameByName(self.championrootItems1["i_icon_"..(2*i)], ui.IDconfig(player2.profile) and ui.IDconfig(player2.profile).icon or "obj_icon_pz_general")
                ui.setSpriteTextureRect(self.championrootItems1["i_icon_"..(2*i-1)],0,0,150,150)
                ui.setSpriteTextureRect(self.championrootItems1["i_icon_"..(2*i)],0,0,150,150)

                local result = datatemp[tostring(i)].result or -1
                if result == 1 then
                    self.championrootItems1["w_"..i.."_1"]:setVisible(true)
                    self.championrootItems1["w_"..i.."_2"]:setVisible(false)
                elseif result == 0 then
                    self.championrootItems1["w_"..i.."_1"]:setVisible(false)
                    self.championrootItems1["w_"..i.."_2"]:setVisible(true)
                else
                    self.championrootItems1["w_"..i.."_1"]:setVisible(false)
                    self.championrootItems1["w_"..i.."_2"]:setVisible(false)
                end
                
                --button   todo
                self.championrootItems1["w_button_c"..i]:addHandleOfControlEvent(function()
                    gameTouch:clickprofbytime(1)
                    if self.worldwarstatus.s_open == 1 and self.worldwarstatus.curDivision ~= self.selectDivision and self.pageNum < 7 and self.worldwarstatus.status == gameConfig.serverWarStage.Guess_8To4 then
                        runGamePrompt({msg = gameConfig.strings:string_common("fixedString","servicewar",67)})
                    elseif self.worldwarstatus.status > Guess_8To4 then
                        gameWindows:openWindow("servicewarbet",{shenbang = self.pageNum > 7,division = self.selectDivision,index = "battleinfo",battleid = datatemp[tostring(i)].id})
                    else
                        runGamePrompt({msg = gameConfig.strings:string_common("fixedString","servicewar",24)})
                    end
                end, CCControlEventTouchUpInside)
                --
                self.championrootItems1["w_button_j"..i]:addHandleOfControlEvent(function()
                    gameTouch:clickprofbytime(1)
                    gameWindows:openWindow("servicewarbet",{shenbang = self.pageNum > 7,division = self.selectDivision,index = "bet",battleid = datatemp[tostring(i)].id,battlefieldid1 = 78,battlefieldid2 = 80})
                end, CCControlEventTouchUpInside)
                --
                if self.worldwarstatus.s_open == 1 and self.worldwarstatus.curDivision ~= self.selectDivision and self.pageNum < 7 and self.worldwarstatus.status == gameConfig.serverWarStage.Guess_8To4 then
                    self.championrootItems1["w_button_c"..i]:setVisible(true)
                    self.championrootItems1["w_button_j"..i]:setVisible(false)
                    ui.addGray("CCControlButton",self.championrootItems1["w_button_c"..i])
                elseif self.worldwarstatus.status == Guess_8To4 then
                    self.championrootItems1["w_button_c"..i]:setVisible(false)
                    self.championrootItems1["w_button_j"..i]:setVisible(true)
                elseif self.worldwarstatus.status > Guess_8To4 then
                    self.championrootItems1["w_button_c"..i]:setVisible(true)
                    self.championrootItems1["w_button_j"..i]:setVisible(false)
                    ui.removeGray("CCControlButton",self.championrootItems1["w_button_c"..i])
                else
                    self.championrootItems1["w_button_c"..i]:setVisible(true)
                    self.championrootItems1["w_button_j"..i]:setVisible(false)
                    ui.addGray("CCControlButton",self.championrootItems1["w_button_c"..i])
                end


                if self.championrootItems1["i_isbet_"..(2*i-1)] and self.championrootItems1["i_isbet_"..(2*i)] then
                    self.championrootItems1["i_isbet_"..(2*i-1)]:setVisible(false)
                    self.championrootItems1["i_isbet_"..(2*i)]:setVisible(false)
                    if self.worldwarstatus.status <= (self.worldwarstatus.s_open == 1 and gameConfig.serverWarStage.Battle_8To4_3 or gameConfig.serverWarStage.Show_result_4) then
                        for k,v in pairs(betplayers) do
                            if v == datatemp[tostring(i)].p_id1 then
                                self.championrootItems1["i_isbet_"..(2*i-1)]:setVisible(true)
                            elseif v == datatemp[tostring(i)].p_id2 then
                                self.championrootItems1["i_isbet_"..(2*i)]:setVisible(true)
                            end
                        end
                    end
                end
                if self.championrootItems1["w_bet_s"..i] and datatemp[tostring(i)].bet then
                    if datatemp[tostring(i)].bet == 1 then
                        setSpriteFrameByName(self.championrootItems1["w_bet_s"..i], gameConfig.images.hasbet)
                    elseif datatemp[tostring(i)].bet == 2 then
                        setSpriteFrameByName(self.championrootItems1["w_bet_s"..i], gameConfig.images.betwrong)
                    elseif datatemp[tostring(i)].bet == 3 then
                        setSpriteFrameByName(self.championrootItems1["w_bet_s"..i], gameConfig.images.betright)
                    else
                        setSpriteFrameByName(self.championrootItems1["w_bet_s"..i], "alpha")
                    end
                end
            else
                ui.setLabelString(self.championrootItems1["i_name_"..(2*i-1)],"",1028)
                ui.setLabelString(self.championrootItems1["i_name_"..(2*i)],"",1028)
                ui.setLabelString(self.championrootItems1["i_servername_"..(2*i-1)],"",13)
                ui.setLabelString(self.championrootItems1["i_servername_"..(2*i)],"",13)
                setSpriteFrameByName(self.championrootItems1["i_icon_"..(2*i-1)], "obj_icon_pz_general")
                setSpriteFrameByName(self.championrootItems1["i_icon_"..(2*i)], "obj_icon_pz_general")
                ui.setSpriteTextureRect(self.championrootItems1["i_icon_"..(2*i-1)],0,0,150,150)
                ui.setSpriteTextureRect(self.championrootItems1["i_icon_"..(2*i)],0,0,150,150)
                self.championrootItems1["w_"..i.."_1"]:setVisible(false)
                self.championrootItems1["w_"..i.."_2"]:setVisible(false)
                --
                self.championrootItems1["w_button_c"..i]:setVisible(true)
                self.championrootItems1["w_button_j"..i]:setVisible(false)
                ui.addGray("CCControlButton",self.championrootItems1["w_button_c"..i])
                --
                self.championrootItems1["w_button_c"..i]:addHandleOfControlEvent(function()
                    gameTouch:clickprofbytime(1)
                    runGamePrompt({msg = gameConfig.strings:string_common("fixedString","servicewar",24)})
                end, CCControlEventTouchUpInside)
                --
                self.championrootItems1["w_button_j"..i]:addHandleOfControlEvent(function()
                    gameTouch:clickprofbytime(1)
                end, CCControlEventTouchUpInside)
                --
                if self.championrootItems1["i_isbet_"..(2*i-1)] and self.championrootItems1["i_isbet_"..(2*i)] then
                    self.championrootItems1["i_isbet_"..(2*i-1)]:setVisible(false)
                    self.championrootItems1["i_isbet_"..(2*i)]:setVisible(false)
                end
                
                if self.championrootItems1["w_bet_s"..i] then
                    setSpriteFrameByName(self.championrootItems1["w_bet_s"..i], "alpha")
                end
            end
        end
         
    elseif self.pageNum == 5 or self.pageNum == 9 then
        
        local datatemp2 = (self.pageNum > 7 and self.worldwartopShenbang["2"] or self.worldwartop["5"]) or {}
        local Guess_4To2 = (self.pageNum == 5 and gameConfig.serverWarStage.Guess_4To2 or gameConfig.serverWarStage.Guess_S_4To2)

        for i = 1,2 do
            if datatemp2[tostring(i)] then

                self.championrootItems2["i_tipNode_"..(2*i-1)]:setVisible(self.worldwarstatus.s_open == 1 and self.pageNum == 5)
                self.championrootItems2["i_tipNode_"..(2*i)]:setVisible(self.worldwarstatus.s_open == 1 and self.pageNum == 5)

                local player1 = worldwarplayers[tostring(datatemp2[tostring(i)].p_id1)] or {}
                local player2 = worldwarplayers[tostring(datatemp2[tostring(i)].p_id2)] or {}
                ui.setLabelString(self.championrootItems2["i_name_"..(2*i-1)],player1.name,1028)
                ui.setLabelString(self.championrootItems2["i_name_"..(2*i)],player2.name,1028)

                ui.setLabelString(self.championrootItems2["i_servername_"..(2*i-1)],player1.server_name,13)
                ui.setLabelString(self.championrootItems2["i_servername_"..(2*i)],player2.server_name,13)
                setSpriteFrameByName(self.championrootItems2["i_icon_"..(2*i-1)], ui.IDconfig(player1.profile) and ui.IDconfig(player1.profile).icon or "obj_icon_pz_general")
                setSpriteFrameByName(self.championrootItems2["i_icon_"..(2*i)], ui.IDconfig(player2.profile) and ui.IDconfig(player2.profile).icon or "obj_icon_pz_general")
                ui.setSpriteTextureRect(self.championrootItems2["i_icon_"..(2*i-1)],0,0,150,150)
                ui.setSpriteTextureRect(self.championrootItems2["i_icon_"..(2*i)],0,0,150,150)
                local result = datatemp2[tostring(i)].result or -1
                if result == 1 then
                    self.championrootItems2["w_"..i.."_1"]:setVisible(true)
                    self.championrootItems2["w_"..i.."_2"]:setVisible(false)
                elseif result == 0 then
                    self.championrootItems2["w_"..i.."_1"]:setVisible(false)
                    self.championrootItems2["w_"..i.."_2"]:setVisible(true)
                else
                    self.championrootItems2["w_"..i.."_1"]:setVisible(false)
                    self.championrootItems2["w_"..i.."_2"]:setVisible(false)
                end
                --button   todo
                self.championrootItems2["w_button_c"..i]:addHandleOfControlEvent(function()
                    gameTouch:clickprofbytime(1)
                    if self.worldwarstatus.s_open == 1 and self.worldwarstatus.curDivision ~= self.selectDivision and self.pageNum < 7 and self.worldwarstatus.status == gameConfig.serverWarStage.Guess_4To2 then
                        runGamePrompt({msg = gameConfig.strings:string_common("fixedString","servicewar",67)})
                    elseif self.worldwarstatus.status > Guess_4To2 then
                        gameWindows:openWindow("servicewarbet",{shenbang = self.pageNum > 7,division = self.selectDivision,index = "battleinfo",battleid = datatemp2[tostring(i)].id})
                    else
                        runGamePrompt({msg = gameConfig.strings:string_common("fixedString","servicewar",24)})
                    end
                end, CCControlEventTouchUpInside)
                --
                self.championrootItems2["w_button_j"..i]:addHandleOfControlEvent(function()
                    gameTouch:clickprofbytime(1)
                    gameWindows:openWindow("servicewarbet",{shenbang = self.pageNum > 7,division = self.selectDivision,index = "bet",battleid = datatemp2[tostring(i)].id,battlefieldid1 = 83,battlefieldid2 = 85})
                end, CCControlEventTouchUpInside)
                --
                if self.worldwarstatus.s_open == 1 and self.worldwarstatus.curDivision ~= self.selectDivision and self.pageNum < 7 and self.worldwarstatus.status == gameConfig.serverWarStage.Guess_4To2 then
                    self.championrootItems2["w_button_c"..i]:setVisible(true)
                    self.championrootItems2["w_button_j"..i]:setVisible(false)
                    ui.addGray("CCControlButton",self.championrootItems2["w_button_c"..i])
                elseif self.worldwarstatus.status == Guess_4To2 then
                    self.championrootItems2["w_button_c"..i]:setVisible(false)
                    self.championrootItems2["w_button_j"..i]:setVisible(true)
                elseif self.worldwarstatus.status > Guess_4To2 then
                    self.championrootItems2["w_button_c"..i]:setVisible(true)
                    self.championrootItems2["w_button_j"..i]:setVisible(false)
                    ui.removeGray("CCControlButton",self.championrootItems2["w_button_c"..i])
                else
                    self.championrootItems2["w_button_c"..i]:setVisible(true)
                    self.championrootItems2["w_button_j"..i]:setVisible(false)
                    ui.addGray("CCControlButton",self.championrootItems2["w_button_c"..i])
                end
                if self.championrootItems2["i_isbet_"..(2*i-1)] and self.championrootItems2["i_isbet_"..(2*i)] then
                    self.championrootItems2["i_isbet_"..(2*i-1)]:setVisible(false)
                    self.championrootItems2["i_isbet_"..(2*i)]:setVisible(false)
                    if self.worldwarstatus.status <= gameConfig.serverWarStage.Battle_4To2_3 then
                        for k,v in pairs(betplayers) do
                            if v == datatemp2[tostring(i)].p_id1 then
                                self.championrootItems2["i_isbet_"..(2*i-1)]:setVisible(true)
                            elseif v == datatemp2[tostring(i)].p_id2 then
                                self.championrootItems2["i_isbet_"..(2*i)]:setVisible(true)
                            end
                        end
                    end
                end
                if self.championrootItems2["w_bet_s"..i] and datatemp2[tostring(i)].bet then
                    if datatemp2[tostring(i)].bet == 1 then
                        setSpriteFrameByName(self.championrootItems2["w_bet_s"..i], gameConfig.images.hasbet)
                    elseif datatemp2[tostring(i)].bet == 2 then
                        setSpriteFrameByName(self.championrootItems2["w_bet_s"..i], gameConfig.images.betwrong)
                    elseif datatemp2[tostring(i)].bet == 3 then
                        setSpriteFrameByName(self.championrootItems2["w_bet_s"..i], gameConfig.images.betright)
                    else
                        setSpriteFrameByName(self.championrootItems2["w_bet_s"..i], "alpha")
                    end
                end
            else
                ui.setLabelString(self.championrootItems2["i_name_"..(2*i-1)],"",1028)
                ui.setLabelString(self.championrootItems2["i_name_"..(2*i)],"",1028)

                ui.setLabelString(self.championrootItems2["i_servername_"..(2*i-1)],"",13)
                ui.setLabelString(self.championrootItems2["i_servername_"..(2*i)],"",13)
                setSpriteFrameByName(self.championrootItems2["i_icon_"..(2*i-1)], "obj_icon_pz_general")
                setSpriteFrameByName(self.championrootItems2["i_icon_"..(2*i)], "obj_icon_pz_general")
                ui.setSpriteTextureRect(self.championrootItems2["i_icon_"..(2*i-1)],0,0,150,150)
                ui.setSpriteTextureRect(self.championrootItems2["i_icon_"..(2*i)],0,0,150,150)
                self.championrootItems2["w_"..i.."_1"]:setVisible(false)
                self.championrootItems2["w_"..i.."_2"]:setVisible(false)
                self.championrootItems2["w_button_c"..i]:setVisible(true)
                self.championrootItems2["w_button_j"..i]:setVisible(false)
                ui.addGray("CCControlButton",self.championrootItems2["w_button_c"..i])
                --
                self.championrootItems2["w_button_c"..i]:addHandleOfControlEvent(function()
                    gameTouch:clickprofbytime(1)
                    runGamePrompt({msg = gameConfig.strings:string_common("fixedString","servicewar",24)})
                end, CCControlEventTouchUpInside)
                --
                self.championrootItems2["w_button_j"..i]:addHandleOfControlEvent(function()
                    gameTouch:clickprofbytime(1)
                end, CCControlEventTouchUpInside)
                --
                if self.championrootItems2["w_bet_s"..i] then
                    setSpriteFrameByName(self.championrootItems2["w_bet_s"..i], "alpha")
                end

                if self.championrootItems2["i_isbet_"..(2*i-1)] and self.championrootItems2["i_isbet_"..(2*i)] then
                    self.championrootItems2["i_isbet_"..(2*i-1)]:setVisible(false)
                    self.championrootItems2["i_isbet_"..(2*i)]:setVisible(false)
                end


            end
        end

    elseif self.pageNum == 6 or self.pageNum == 10 then
        local datatemp3 = (self.pageNum > 7 and self.worldwartopShenbang["3"] or self.worldwartop["6"]) or {}
        local Guess_2To1 = (self.pageNum == 6 and gameConfig.serverWarStage.Guess_2To1 or gameConfig.serverWarStage.Guess_S_2To1)

        if datatemp3["1"] then
            self.championrootItems3["i_tipNode"]:setVisible(self.worldwarstatus.s_open == 1 and self.pageNum == 6)
            self.championrootItems3["i_tipNode_1"]:setVisible(self.worldwarstatus.s_open == 1 and self.pageNum == 6)
            local player1 = worldwarplayers[tostring(datatemp3[tostring(1)].p_id1)] or {}
            local player2 = worldwarplayers[tostring(datatemp3[tostring(1)].p_id2)] or {}

            ui.setLabelString(self.championrootItems3["i_name"],player1.name,1028)
            ui.setLabelString(self.championrootItems3["i_name_1"],player2.name,1028)

            ui.setLabelString(self.championrootItems3["i_servername"],player1.server_name,13)
            ui.setLabelString(self.championrootItems3["i_servername_1"],player2.server_name,13)
            setSpriteFrameByName(self.championrootItems3["i_icon"], ui.IDconfig(player1.profile) and ui.IDconfig(player1.profile).icon or "obj_icon_pz_general")
            setSpriteFrameByName(self.championrootItems3["i_icon_1"], ui.IDconfig(player2.profile) and ui.IDconfig(player2.profile).icon or "obj_icon_pz_general")
            ui.setSpriteTextureRect(self.championrootItems3["i_icon"],0,0,150,150)
            ui.setSpriteTextureRect(self.championrootItems3["i_icon_1"],0,0,150,150)
            local player1 = worldwarplayers[tostring(datatemp3["1"].p_id1)] or {}
            local player2 = worldwarplayers[tostring(datatemp3["1"].p_id2)] or {}
            local result = datatemp3["1"].result or -1
            if result == 1 then
                self.championrootItems3["w_1_1"]:setVisible(true)
                self.championrootItems3["w_1_2"]:setVisible(false)
            elseif result == 0 then
                self.championrootItems3["w_1_1"]:setVisible(false)
                self.championrootItems3["w_1_2"]:setVisible(true)
            else
                self.championrootItems3["w_1_1"]:setVisible(false)
                self.championrootItems3["w_1_2"]:setVisible(false)
            end
            --button   todo
            self.championrootItems3["w_button_c1"]:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(1)
                if self.worldwarstatus.s_open == 1 and self.worldwarstatus.curDivision ~= self.selectDivision and self.pageNum < 7 and self.worldwarstatus.status == gameConfig.serverWarStage.Guess_2To1 then
                    runGamePrompt({msg = gameConfig.strings:string_common("fixedString","servicewar",67)})
                elseif self.worldwarstatus.status > Guess_2To1 then
                    gameWindows:openWindow("servicewarbet",{shenbang = self.pageNum > 7,division = self.selectDivision,index = "battleinfo",battleid = datatemp3["1"].id})
                else
                    runGamePrompt({msg = gameConfig.strings:string_common("fixedString","servicewar",24)})
                end
            end, CCControlEventTouchUpInside)
            --
            self.championrootItems3["w_button_j1"]:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(1)
                gameWindows:openWindow("servicewarbet",{shenbang = self.pageNum > 7,division = self.selectDivision,index = "bet",battleid = datatemp3["1"].id,battlefieldid1 = 87,battlefieldid2 = 89})
            end, CCControlEventTouchUpInside)
            --
            if self.worldwarstatus.s_open == 1 and self.worldwarstatus.curDivision ~= self.selectDivision and self.pageNum < 7 and self.worldwarstatus.status == gameConfig.serverWarStage.Guess_2To1 then
                self.championrootItems3["w_button_c1"]:setVisible(true)
                self.championrootItems3["w_button_j1"]:setVisible(false)
                ui.addGray("CCControlButton",self.championrootItems3["w_button_c1"])
            elseif self.worldwarstatus.status == Guess_2To1 then
                self.championrootItems3["w_button_c1"]:setVisible(false)
                self.championrootItems3["w_button_j1"]:setVisible(true)
            elseif self.worldwarstatus.status > Guess_2To1 then
                self.championrootItems3["w_button_c1"]:setVisible(true)
                self.championrootItems3["w_button_j1"]:setVisible(false)
                ui.removeGray("CCControlButton",self.championrootItems3["w_button_c1"])
            else
                self.championrootItems3["w_button_c1"]:setVisible(true)
                self.championrootItems3["w_button_j1"]:setVisible(false)
                ui.addGray("CCControlButton",self.championrootItems3["w_button_c1"])
            end
            
            if self.championrootItems3["i_isbet"] and self.championrootItems3["i_isbet_1"] then
                self.championrootItems3["i_isbet"]:setVisible(false)
                self.championrootItems3["i_isbet_1"]:setVisible(false)
                if self.worldwarstatus.status <= gameConfig.serverWarStage.Battle_2To1_3 then
                    for k,v in pairs(betplayers) do
                        if v == datatemp3["1"].p_id1 then
                            self.championrootItems3["i_isbet"]:setVisible(true)
                        elseif v == datatemp3["1"].p_id2 then
                            self.championrootItems3["i_isbet_1"]:setVisible(true)
                        end
                    end
                end
            end
            --
            if self.championrootItems3["w_bet_s1"] and datatemp3["1"].bet then
                if datatemp3["1"].bet == 1 then
                    setSpriteFrameByName(self.championrootItems3["w_bet_s1"], gameConfig.images.hasbet)
                elseif datatemp3["1"].bet == 2 then
                    setSpriteFrameByName(self.championrootItems3["w_bet_s1"], gameConfig.images.betwrong)
                elseif datatemp3["1"].bet == 3 then
                    setSpriteFrameByName(self.championrootItems3["w_bet_s1"], gameConfig.images.betright)
                else
                    setSpriteFrameByName(self.championrootItems3["w_bet_s1"], "alpha")
                end
            end
        else

            ui.setLabelString(self.championrootItems3["i_name"],"",1028)
            ui.setLabelString(self.championrootItems3["i_name_1"],"",1028)

            ui.setLabelString(self.championrootItems3["i_servername"],"",13)
            ui.setLabelString(self.championrootItems3["i_servername_1"],"",13)
            setSpriteFrameByName(self.championrootItems3["i_icon"], "obj_icon_pz_general")
            setSpriteFrameByName(self.championrootItems3["i_icon_1"], "obj_icon_pz_general")
            ui.setSpriteTextureRect(self.championrootItems3["i_icon"],0,0,150,150)
            ui.setSpriteTextureRect(self.championrootItems3["i_icon_1"],0,0,150,150)

            self.championrootItems3["w_1_1"]:setVisible(false)
            self.championrootItems3["w_1_2"]:setVisible(false)
            --
            ui.setLabelString(self.championrootItems3["i_servername"],"",13)
            setSpriteFrameByName(self.championrootItems3["i_icon"],"obj_icon_pz_general")
            ui.setSpriteTextureRect(self.championrootItems3["i_icon"],0,0,150,150)
            --
            self.championrootItems3["w_button_c1"]:setVisible(true)
            self.championrootItems3["w_button_j1"]:setVisible(false)
            ui.addGray("CCControlButton",self.championrootItems3["w_button_c1"])
            --
            self.championrootItems3["w_button_c1"]:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(1)
                runGamePrompt({msg = gameConfig.strings:string_common("fixedString","servicewar",24)})
            end, CCControlEventTouchUpInside)
            --
            self.championrootItems3["w_button_j1"]:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(1)
            end, CCControlEventTouchUpInside)
            --
            if self.championrootItems3["w_bet_s1"] then
                setSpriteFrameByName(self.championrootItems3["w_bet_s1"], "alpha")
            end

            if self.championrootItems3["i_isbet"] and self.championrootItems3["i_isbet_1"] then
                self.championrootItems3["i_isbet"]:setVisible(false)
                self.championrootItems3["i_isbet_1"]:setVisible(false)
            end
        end
           
    end
end


function servicewarNow.creategroupList(self)
    local celldict = {}
    local groupListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(140,120)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("kuafuzhan/kuafuzhan_icon2.ccbi", nil, true, "Icon")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            cellCCB:setScale(1)
            cellCCB:setPosition(70, 60)

            ui.setLabelString(ccbDocumentControler.z_lab,self.groupname[a1+1],14)

            if self.groupindex == a1+1 then
                ccbDocumentControler.z_select:setVisible(true)
            else
                ccbDocumentControler.z_select:setVisible(false)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = 8
        elseif fn == "cellTouched" then
            gameTouch:clickprofbytime(0.5)
            --
            self.groupindex = a1:getIdx()+1
            self:setGroupData(self.groupindex)

        elseif fn == "scrollViewDidScroll" then
            self:checkSetX()
        end
        return r
    end)

    self.groupListTableView = ui.createLuaTableView({
        handle = groupListHandle,
        viewwidth = self.rootItems.groupList:getContentSize().width,
        viewheight = self.rootItems.groupList:getContentSize().height,
        dire = 0
    })
    self.rootItems.groupList:addChild(self.groupListTableView)
    self.groupListTableView:setTouchPriority(-102)
end

function servicewarNow.checkSetX(self)
    if self.groupListTableView and self.rootItems.groupnode_left and self.rootItems.groupnode_right then
        local setx = self.groupListTableView:getLuaContentOffsetX()
        if setx > -20 then
            self.rootItems.groupnode_left:setVisible(false)
            self.rootItems.groupnode_right:setVisible(true)
        elseif setx < -400 then
            self.rootItems.groupnode_left:setVisible(true)
            self.rootItems.groupnode_right:setVisible(false)
        else
            self.rootItems.groupnode_left:setVisible(true)
            self.rootItems.groupnode_right:setVisible(true)
        end
    end
end

function servicewarNow.clear(self)
    if gameTimer.times["servicewar_bettime"] then
        gameTimer:UnrigistTimeFunc("servicewar_bettime")
    end
    gameTimer:UnrigistTimeFunc("worldwarupdatetimer")
    gameTimer:UnrigistTimeFunc("worldwarendtimer")
    self.selectpage = "personal"
    self.groupindex = 1
    self.lastPageNum = self.pageNum
    self.pageNum = 1
    self.groupListTableView = nil
    self.ListTableView = nil
    self.worldwartop = {}
    self.worldwarplayers = {}
    self.worldwarstatus = {}
    self.worldwarrolebattles = {}
    self.rootItems = nil
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.grouprootNode = nil
    self.grouprootItems = nil
    self.championrootNode1 = nil
    self.championrootItems1 = nil
    self.championrootNode2 = nil
    self.championrootItems2 = nil
    self.championrootNode3 = nil
    self.championrootItems3 = nil
    self.isOpenStatus = 0

    self.selectDivision = nil
    self.worldwarstatusShenbang = {}
    self.worldwarrolebattlesShenbang = {}
    self.worldwartopShenbang = {}
    self.worldwarplayersShenbang = {}
end

return servicewarNow