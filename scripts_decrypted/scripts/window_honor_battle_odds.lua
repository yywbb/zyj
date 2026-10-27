local honorBattleOdds = {
    cellSize1 = {width = 920, height = 350},
    cellSize2 = {width = 920, height = 430},

    rootNode = nil,
    rootItems = nil,

    listTableView = nil,

    ccbDocument = {},
}

function honorBattleOdds.close(self)
    gameTouch:UnrigistFunc("begin", "honorBattleOdds")
    gameTouch:UnrigistFunc("end", "honorBattleOdds")
    for i=1,3 do
        local _timerName = "honorBattleOdds"..i
        gameTimer:UnrigistTime(_timerName)
        gameTimer:UnrigistTimeFunc(_timerName)
    end
    self.ccbDocument = {}

    self.listTableView = nil

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)

    self.rootNode = nil
    self.rootItems = nil
end

function honorBattleOdds.open(self, touchPriority, data, callback)
    self.listTableView = nil
    self:initNode(touchPriority)
    self:initActivityScroll()
    self:initCloseBtn()

    self.data = data

    if data.betdata then
        self.betdata = data.betdata
        self:initConfig()
        --self:reloadOdds()
    else
        self.rootItems.oddsNode:setVisible(false)
        self.rootItems.detailnode:setPositionY(260)
    end

    self:refreshData()

    return self.rootNode
end

function honorBattleOdds.refreshData( self )
    UIRequest({type=6506,phase = self.data.phase,id = self.data.id})
end

-- 初始化界面
function honorBattleOdds.initNode(self, touchPriority)
    self.rootNode, self.rootItems = CCBReaderLoad("rongyaozhizhan/tc_bisaiinfo", nil, true, "tc_bisaiinfo")
    self.touchPriority = touchPriority
    self.rootItems.oddsNode:setVisible(true)
    ui.setLabelString(self.rootItems.titleTxt,"比赛详情",65)
end

function honorBattleOdds.initActivityScroll(self)
    local function touchBegin(pos)
        self.isscrolltouched = false
        self.touchbegin = {x = pos.x, y = pos.y}
    end

    local function touchEnd(pos)
        if math.abs(pos.x - (self.touchbegin and self.touchbegin.x or pos.x)) > 20 or 
           math.abs(pos.y - (self.touchbegin and self.touchbegin.y or pos.y)) > 20 then
            self.isscrolltouched = false
        elseif self.rootItems["listScroll"] and ui.isTouched(self.rootItems["listScroll"], pos.x, pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("begin", "honorBattleOdds", touchBegin)
    gameTouch:rigistFunc("end", "honorBattleOdds", touchEnd)
end

-- 初始化配置表
function honorBattleOdds.initConfig(self)
    self.oddsConfig = gamedata.config.glory_battle_odds
    self.lvbetConfig = gamedata.config.glory_battle_lvbet
    self.maxrate = tonumber(gamedata.config.global_kv.glory_fudong_up.value)
    self.minrate = tonumber(gamedata.config.global_kv.glory_fudong_down.value)
end

-- 初始化关闭按钮
function honorBattleOdds.initCloseBtn(self)
    local _cb = function()
        gameWindows:closeWindow("honorBattleOdds")
    end

    self:commonBtn(self.rootItems, "closeButton", _cb)
end

------------------------------------------------------

function honorBattleOdds.reloadOdds( self )

    self:reloadOddsStatus()

end

function honorBattleOdds.getTotalPower(self, powerType)
    local _totalPower = 0

    local rid = self.battledata.players["rid_"..powerType]

    for i=1,3 do
        local onebattle = self.battledata[tostring(i)]
        if onebattle.rid_a == rid then
            _totalPower = _totalPower + onebattle.power_a
        elseif onebattle.rid_b == rid then
            _totalPower = _totalPower + onebattle.power_b
        end
    end

    return _totalPower
end

function honorBattleOdds.getOdds( self,idx )
    local _odds = math.pow(math.pow(self:getTotalPower("a") / self:getTotalPower("b"), 2.3), self.oddsConfig[tostring(idx)].odds) + 1
    _odds = _odds - _odds%0.01
    _odds = math.max(_odds,self.minrate)
    _odds = math.min(_odds,self.maxrate)
    return _odds
end

function honorBattleOdds.getBetNum( self,num )
    if num <= 4 then
        return (4-num)..":"..(num-1)
    else
        if num == 5 then
            return self.data.players[self.battledata.players.rid_a].name.."获胜"
        else
            return self.data.players[self.battledata.players.rid_b].name.."获胜"
        end
    end
end

function honorBattleOdds.getFloorOdds(self)
    local idx = 1
    local _row = self.lvbetConfig[tostring(idx)]
    while _row and GameScene.roleinfo.level >= _row.interval do
        idx = idx + 1
        _row = self.lvbetConfig[tostring(idx)]
    end
    return self.lvbetConfig[tostring(idx-1)].lv_bet
end

function honorBattleOdds.getProfit( self )
    if self.betdata.betnum == 0 then return end

    return self:getFloorOdds()*self.betdata.betcount*self:getOdds(self.betdata.betnum)
end

function honorBattleOdds.reloadOddsStatus( self )
    if self.betdata.result < 0 and self.betdata.bet <= 0 then
        self.rootItems.betBtnNode:setVisible(true)
        self.rootItems.betStatusNode:setVisible(false)

        self:initOddsBtn()
    else
        self.rootItems.betBtnNode:setVisible(false)
        self.rootItems.betStatusNode:setVisible(true)
        self:initFixedString()
    end
end
-- 固定文字
function honorBattleOdds.initFixedString(self)
    self.rootItems.statusdesc:removeAllChildrenWithCleanup(true)

    local descT = {}
    local _str = "押注结果: "

    if self.betdata.betnum <= 4 then
        _str = "押注比分: "
    end

    -- 结束了
    if self.betdata.result >= 0 then
        

        -- 未押注
        if self.betdata.bet == 0 then
            descT = {
                {fontID = 11,content = "本场比赛您未押注"},
            }
        -- 押注成功
        elseif self.betdata.bet == 3 then
            descT = {
                {fontID = 14,content = _str..self:getBetNum(self.betdata.betnum)},
                {},
                {fontID = 14,content = gameConfig.strings:string_common("honorBattle2", 12)},
                {fontID = 0,content = "obj_s_coin",scale = 0.7},
                {fontID = 14,content = self:getProfit()},
            }
        -- 押注失败
        else
            descT = {
                {fontID = 14,content = _str..self:getBetNum(self.betdata.betnum)},
                {},
                {fontID = 14,content = gameConfig.strings:string_common("honorBattle2", 11)},
            }
        end
        table.insert( descT, {} )
        local _str1 = gameConfig.strings:string_common("honorBattle2", 14)
        table.insert( descT, {fontID = 18,content = _str1..self:getBetNum(self.betdata.resultnum)} )
    else
        if self.betdata.bet > 0 then
            descT = {
                {fontID = 14,content = _str..self:getBetNum(self.betdata.betnum)},
                {},
                {fontID = 14,content = "赔率: "..self:getOdds(self.betdata.betnum)},
                {},
                {fontID = 14,content = "押注成功可获得: "},
                {fontID = 0,content = "obj_s_coin",scale = 0.7},
                {fontID = 14,content = self:getProfit()},
            }
        end
    end 
    ui.createRichLabel(descT,self.rootItems.statusdesc,false,{horizontal = "center",vertical = "center"})

    if self.betdata.bet == 1 then
        setSpriteFrameByName(self.rootItems.statusspr, "_0015_2")
    elseif self.betdata.bet == 2 then
        setSpriteFrameByName(self.rootItems.statusspr, "_0009_1_2")
    elseif self.betdata.bet == 3 then
        setSpriteFrameByName(self.rootItems.statusspr, "_0009_1")
    else
        setSpriteFrameByName(self.rootItems.statusspr, "alpha")
    end

end

function honorBattleOdds.initOddsBtn(self)

    ui.setLabelString(self.rootItems.betrestcounttxt, "本轮剩余押注次数: "..self.betdata.restbetcount, 14)

    ui.setLabelString(self.rootItems.betBtnTxt, gameConfig.strings:string_common("honorBattle2", 10), 19)
    local honorwarstatus = GameScene.layers["honorBattle"].module.HonorWarStatus.status
    if honorwarstatus ~= self.betdata.betstatus or self.betdata.restbetcount <=0 then
        ui.addGray("CCControlButton", self.rootItems.betBtn)
    else
        ui.removeGray("CCControlButton", self.rootItems.betBtn)
    end

    local _cb = function()
        -- 比赛开始前
        local honorwarstatus = GameScene.layers["honorBattle"].module.HonorWarStatus.status
        if honorwarstatus > self.betdata.betstatus then
            runGamePrompt({msg = "押注时间已过"})
        elseif honorwarstatus < self.betdata.betstatus then
            runGamePrompt({msg = "押注时间未到"})
        elseif self.betdata.restbetcount <= 0 then
            runGamePrompt({msg = "本轮押注次数已用完"})
        else
            --此处要注释掉  不能再打开这个界面了
            --[[    gameWindows:openWindow("honorBattleProperty", {
                    id = self.data.id,
                    mark = self.selectOdds,
                    odds = self:getOdds(self.selectOdds), 
                    isBet = self.betdata.bet, 
                    floorOdds = self:getFloorOdds()
                })
            --]]
            --TODO  此处改成打开押注界面  HX
            gameWindows:openWindow("honorBet",{
                phase = self.data.phase,
                id = self.data.id,
                player1 = self.data.players[self.battledata.players.rid_a],
                player2 = self.data.players[self.battledata.players.rid_b],
                betdata = self.betdata,
                battledata = self.battledata,
                })
        end
    end
    self:commonBtn(self.rootItems, "betBtn", _cb)
end

--------------------------------------------------------------------

-- 刷新数据
function honorBattleOdds.reloadData(self, data)
    self.battledata = data

    if self.data.betdata then 
        self:reloadOdds() --注释了其中的部分代码  下方的选择赔率没了
    end

    for i=1,3 do
        local v = self.battledata[tostring(i)]
        if v.result < 0 and v.time > 0 then 
            local _timerName = "honorBattleOdds"..i
            gameTimer:rigistTime(_timerName,v.time+1)
        end
    end

    if self.battledata then
        if not self.listTableView then
            self:creatList()
        else
            self.listTableView:reloadData()
        end
    end
end

-- 初始化listTable
function honorBattleOdds.creatList(self)
    local _cellDict = {}
    local _listHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local _r
        if fn == "cellSize" then
        
        elseif fn == "hasFixedCellSize" then
            _r = false
        elseif fn == "cellSizeForIndex" then
            if a1 + 1 < 3 then
                _r = CCSizeMake(self.cellSize1.width, self.cellSize1.height)
            else
                _r = CCSizeMake(self.cellSize2.width, self.cellSize2.height)
            end
        elseif fn == "isRecycle" then
            self.ccbDocument[tostring(a1+1)] = nil
            return false
        elseif fn == "cellAtIndex" then
            self.ccbDocument[tostring(a1+1)] = {}
            local ccbdoc = self.ccbDocument[tostring(a1+1)]
            local _first = true

            if not a2 then
                a2 = CCTableViewCell:create()
                if a1 + 1 < 3 then
                    ccbdoc._cellCCB, ccbdoc._ccbDocumentControler = CCBReaderLoad("rongyaozhizhan/cell_bisaiinfo2", nil, true, "cell_bisaiinfo2")
                else
                    ccbdoc._cellCCB, ccbdoc._ccbDocumentControler = CCBReaderLoad("rongyaozhizhan/cell_bisaiinfo3", nil, true, "cell_bisaiinfo3")
                end
                _cellDict[a2] = {cellCCB = ccbdoc._cellCCB, ccbDocumentControler = ccbdoc._ccbDocumentControler,index = a1+1 }
            else
                _first = false
                ccbdoc._cellCCB = _cellDict[a2].cellCCB
                ccbdoc._ccbDocumentControler = _cellDict[a2].ccbDocumentControler
            end

            self:setCell(ccbdoc._ccbDocumentControler, self.battledata[tostring(a1 + 1)], a1 + 1)

            if a1 + 1 < 3 then
                ccbdoc._cellCCB:setPosition(self.cellSize1.width / 2, -self.cellSize1.height)
            else
                ccbdoc._cellCCB:setPosition(self.cellSize2.width / 2, -self.cellSize2.height)
            end

            if _first then
                a2:addChild(ccbdoc._cellCCB)
            end

            _r = a2
        elseif fn == "numberOfCells" then
            _r = 3
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end

        return _r
    end)

    self.listTableView = ui.createLuaTableView({
        handle = _listHandle,
        viewwidth = self.rootItems["listScroll"]:getContentSize().width,
        viewheight = self.rootItems["listScroll"]:getContentSize().height,
        dire = 1
    })
    self.rootItems["listScroll"]:addChild(self.listTableView)
    self.listTableView:setTouchPriority(self.touchPriority - 1)
    self.listTableView:setTouchEnabled(false)
end

-- 设置cell
function honorBattleOdds.setCell(self, item, data, index)
    self:initFixedItems(item, data, index)
    self:setGeneralIcon(item, data, index)
    self:setLookBtn(item, index)
end

-- 设置cell文字
function honorBattleOdds.initFixedItems(self, item, data, round)
    item.round:setString(round)
    local _str = ""

    if round == 1 then
        _str = "1v1"
    elseif round == 2 then
        _str = "2v2"
    elseif round == 3 then
        _str = "4v4"
    end

    item.titleTxt:setString(_str)
    local name_a = self.data.players[data.rid_a].name
    item.playerNameLeftTxt:setString(name_a)
    item.powerLeftTxt:setString(data.power_a)
    local name_b = self.data.players[data.rid_b].name
    item.playerNameRightTxt:setString(name_b)
    item.powerRightTxt:setString(data.power_b)
    item.lookInfoTxt:setString(gameConfig.strings:string_common("honorBattle2", 7))

    item.resultspr:setVisible(data.result>=0)
    item.resultspr:setPositionX(data.result==1 and 60 or 870)
    item.sp_first_left:setVisible(data.power_a>data.power_b and data.result<0)
    item.sp_first_right:setVisible(data.power_a<data.power_b and data.result<0)
    if data.result < 0 then
        self:iconOrButtonIsShow(item, false)
        self:createTimer(item, data.time, round)
        item.winOrLoseTxt:setString("")
    else
        self:iconOrButtonIsShow(item, true)
        if data.result == 0 then
            item.winOrLoseTxt:setString("")--gameConfig.strings:string_common("honorBattle2", 4))
        elseif data.result == 1 then
            item.winOrLoseTxt:setString("")--gameConfig.strings:string_common("honorBattle2", 5))
        end
    end
end

function honorBattleOdds.createTimer(self, item, time, round)
    local _timerName = "honorBattleOdds"..round
    if gameTimer.times[_timerName] and gameTimer.times[_timerName] >0 then
        gameTimer:rigistTimeFunc(_timerName, function()
            if gameTimer.times[_timerName] <= 0 then 
                gameTimer:UnrigistTime(_timerName)
                gameTimer:UnrigistTimeFunc(_timerName)
                UIRequest({type=6506,phase = self.data.phase,id = self.data.id})
            else
                if self.ccbDocument[tostring(round)] then
                    self.ccbDocument[tostring(round)]._ccbDocumentControler.winOrLoseTxt:setString(ui.makeTimeText(gameTimer.times[_timerName]))
                end
            end
        end)
    end
end

function honorBattleOdds.iconOrButtonIsShow(self, item, isShow)
    item.vsIcon:setVisible(not isShow)
    item.lookNode:setVisible(isShow)
end

function honorBattleOdds.setGeneralIcon(self, item, data, round)
    local count = {2,2,4}
    for i=1,count[round] do
        local generala = data["general"..i.."_a"]
        if generala and generala >0 then
            local oldcid = data["oldcid"..i.."_a"]
            local oldconfigdata = gamedata.config.general[tostring(oldcid)] or {}
            if next(oldconfigdata) then
                ui.setNewIcon(item, {cid = generala, quality = oldconfigdata.quality}, i-1)
            else
                ui.setNewIcon(item, {cid = generala}, i-1)
            end
        else
            item["formationLeft"..i]:setVisible(false)
        end 
        local generalb = data["general"..i.."_b"]
        if generalb and generalb >0 then
            local oldcid = data["oldcid"..i.."_b"]
            local oldconfigdata = gamedata.config.general[tostring(oldcid)] or {}
            if next(oldconfigdata) then
                ui.setNewIcon(item, {cid = generalb, quality = oldconfigdata.quality}, i-1+count[round])
            else
                ui.setNewIcon(item, {cid = generalb}, i-1+count[round])
            end
        else
            item["formationRight"..i]:setVisible(false)
        end 
    end
end

function honorBattleOdds.setLookBtn(self, item, round)
    local _cb = function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end

        UIRequest({type = 6507, idx = round,id=self.data.id})
    end

    self:commonBtn(item, "lookBtn", _cb, self.touchPriority - 2,true)
end

-- 通用按钮
function honorBattleOdds.commonBtn(self, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)
    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(touchPriority or (self.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return honorBattleOdds wF  