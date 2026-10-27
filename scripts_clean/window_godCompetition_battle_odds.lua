local godCompetitionBattleOdds = {
    cellSize1 = {width = 920, height = 350},
    cellSize2 = {width = 920, height = 430},

    rootNode = nil,
    rootItems = nil,

    ccbDocument = {},

    pageIndex = 1,
}

function godCompetitionBattleOdds.close(self)
    for i=1,3 do
        local _timerName = "godCompetitionBattleOdds"..i
        gameTimer:UnrigistTime(_timerName)
        gameTimer:UnrigistTimeFunc(_timerName)
    end
    self.ccbDocument = {}
    self.pageIndex = 1

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)

    self.rootNode = nil
    self.rootItems = nil
end

function godCompetitionBattleOdds.open(self, touchPriority, data, callback)

    self:initNode(touchPriority)

    self.data = data
    printT(data,"jkp-data")

    if data.betdata then
        self.betdata = data.betdata
        self:initConfig()
    else
        self.rootItems.oddsNode:setVisible(false)
        -- self.rootItems.detailnode:setPositionY(260)
    end

    self:refreshData()

    return self.rootNode
end

function godCompetitionBattleOdds.refreshData( self )
    UIRequest({type = 8273, phase = self.data.phase, id = self.data.id})
end

-- 初始化界面
function godCompetitionBattleOdds.initNode(self, touchPriority)
    self.rootNode, self.rootItems = CCBReaderLoad("fengshensai/tc_battleinfo", nil, true, "tc_battleinfo")
    self.touchPriority = touchPriority
    self.rootItems.oddsNode:setVisible(true)
    ui.setLabelString(self.rootItems.title,"比赛详情",65)

    local close_cb = function()
        gameWindows:closeWindow("godCompetitionBattleOdds")
    end
    self:commonBtn(self.rootItems, "closeBtn", close_cb)

    for i=1,3 do
        if i == self.pageIndex then
            self.rootItems["battleinfo"..i]:setVisible(true)
        else
            self.rootItems["battleinfo"..i]:setVisible(false)
        end

        local battle_cb = function()
            if self.pageIndex ~= i then
                self.pageIndex = i
                for k=1,3 do
                    if k == self.pageIndex then
                        self.rootItems["battleinfo"..k]:setVisible(true)
                    else
                        self.rootItems["battleinfo"..k]:setVisible(false)
                    end
                end
                self:setViewInfo(self.rootItems,self.battledata[tostring(self.pageIndex)])
            end
        end
        self:commonBtn(self.rootItems, "infoButton"..i, battle_cb)
    end

    --查看战斗
    local look_cb = function()
        UIRequest({type = 8274, idx = self.pageIndex, id = self.data.id})
    end
    self:commonBtn(self.rootItems, "lookBtn", look_cb)

end

-- 初始化配置表
function godCompetitionBattleOdds.initConfig(self)
    self.oddsConfig = gamedata.config.apex_battle_odds
    self.lvbetConfig = gamedata.config.apex_battle_lvbet
    self.maxrate = tonumber(gamedata.config.global_kv.apex_fudong_up.value)
    self.minrate = tonumber(gamedata.config.global_kv.apex_fudong_down.value)
end

------------------------------------------------------

function godCompetitionBattleOdds.reloadOdds( self )

    if self.betdata.result < 0 and self.betdata.bet <= 0 then
        self.rootItems.betBtnNode:setVisible(true)
        self.rootItems.betStatusNode:setVisible(false)

        self:initOddsBtn()
    else
        self.rootItems.betBtnNode:setVisible(false)
        self.rootItems.betStatusNode:setVisible(true)
        self:initFixedString()
    end

    -- self.rootItems.betBtnNode:setVisible(true)
    -- self.rootItems.betStatusNode:setVisible(false)
    -- self:initOddsBtn()

end

function godCompetitionBattleOdds.getTotalPower(self, powerType)
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

function godCompetitionBattleOdds.getOdds( self,idx )
    local _odds = math.pow(math.pow(self:getTotalPower("a") / self:getTotalPower("b"), 2.3), self.oddsConfig[tostring(idx)].odds) + 1
    _odds = _odds - _odds%0.01
    _odds = math.max(_odds,self.minrate)
    _odds = math.min(_odds,self.maxrate)
    return _odds
end

function godCompetitionBattleOdds.getBetNum( self,num )
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

function godCompetitionBattleOdds.getFloorOdds(self)
    local idx = 1
    local _row = self.lvbetConfig[tostring(idx)]
    while _row and GameScene.roleinfo.level >= _row.interval do
        idx = idx + 1
        _row = self.lvbetConfig[tostring(idx)]
    end
    return self.lvbetConfig[tostring(idx-1)].lv_bet
end

function godCompetitionBattleOdds.getProfit( self )
    if self.betdata.betnum == 0 then return end

    return self:getFloorOdds()*self.betdata.betcount*self:getOdds(self.betdata.betnum)
end

-- 固定文字
function godCompetitionBattleOdds.initFixedString(self)
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

function godCompetitionBattleOdds.initOddsBtn(self)

    ui.setLabelString(self.rootItems.betrestcounttxt, "本轮剩余押注次数: "..self.betdata.restbetcount, 14)

    ui.setLabelString(self.rootItems.betBtnTxt, gameConfig.strings:string_common("honorBattle2", 10), 19)
    local godstatus = GameScene.layers["godCompetitionMain"].module.godStatus.status
    if godstatus ~= self.betdata.betstatus or self.betdata.restbetcount <= 0 then
        ui.addGray("CCControlButton", self.rootItems.betBtn)
    else
        ui.removeGray("CCControlButton", self.rootItems.betBtn)
    end

    local _cb = function()
        -- 比赛开始前
        local godstatus = GameScene.layers["godCompetitionMain"].module.godStatus.status
        if godstatus > self.betdata.betstatus then
            runGamePrompt({msg = "押注时间已过"})
        elseif godstatus < self.betdata.betstatus then
            runGamePrompt({msg = "押注时间未到"})
        elseif self.betdata.restbetcount <= 0 then
            runGamePrompt({msg = "本轮押注次数已用完"})
        else
            --TODO  此处改成打开押注界面  HX
            gameWindows:openWindow("godCompetitionBet",{
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
function godCompetitionBattleOdds.reloadData(self, data)
    self.battledata = data

    if self.data.betdata then 
        self:reloadOdds()
    end

    for i=1,3 do
        local v = self.battledata[tostring(i)]
        if v.result < 0 and v.time > 0 then 
            local _timerName = "godCompetitionBattleOdds"..i
            gameTimer:rigistTime(_timerName,v.time+1)
        end
    end

    self:setViewInfo(self.rootItems,self.battledata[tostring(self.pageIndex)])

end

-- 设置阵容页面
function godCompetitionBattleOdds.setViewInfo(self, item, data)

    local name_a = self.data.players[data.rid_a].name
    item.playerName1:setString(name_a)
    item.power1:setString(data.power_a)
    local name_b = self.data.players[data.rid_b].name
    item.playerName2:setString(name_b)
    item.power2:setString(data.power_b)
    --显示胜利方
    item.resultspr:setVisible(data.result>=0)
    item.resultspr:setPositionX(data.result==1 and 420 or 980)
    --显示攻击方
    item.sp_first_left:setVisible(data.power_a>data.power_b and data.result<0)
    item.sp_first_right:setVisible(data.power_a<data.power_b and data.result<0)
    --设置战斗倒计时和可查看状态
    if data.result < 0 then
        item.lookNode:setVisible(false)
        self:createTimer(item, data.time)
        item.winOrLoseTxt:setString("")
    else
        item.lookNode:setVisible(true)
        item.winOrLoseTxt:setString("")
    end
    --设置武将信息
    self:setGeneralIcon(item, data)
end

function godCompetitionBattleOdds.createTimer(self, item, time)
    local _timerName = "godCompetitionBattleOdds"..self.pageIndex
    if gameTimer.times[_timerName] and gameTimer.times[_timerName] >0 then
        gameTimer:rigistTimeFunc(_timerName, function()
            if gameTimer.times[_timerName] <= 0 then 
                gameTimer:UnrigistTime(_timerName)
                gameTimer:UnrigistTimeFunc(_timerName)
                UIRequest({type = 8273,phase = self.data.phase,id = self.data.id})
            else
                if item.winOrLoseTxt then
                    item.winOrLoseTxt:setString(ui.makeTimeText(gameTimer.times[_timerName]))
                end
            end
        end)
    end
end

function godCompetitionBattleOdds.setGeneralIcon(self, item, data)
    --显示武将头像
    for i=1,7 do
        --左
        self.rootItems["general1_"..i]:removeAllChildrenWithCleanup(true)
        local generala = data["general"..i.."_a"]
        if generala and generala > 0 then
            local oldcid = data["oldcid"..i.."_a"]
            local oldconfigdata = gamedata.config.general[tostring(oldcid)] or {}

            local cellCCB, ccbItem = CCBReaderLoad("icons/new_icon", nil, true, "new_icon")
            cellCCB:setScale(0.96)
            if next(oldconfigdata) then
                ui.setNewIcon(ccbItem, {cid = generala, quality = oldconfigdata.quality})
            else
                ui.setNewIcon(ccbItem, {cid = generala})
            end

            cellCCB:setPosition(81,81)
            self.rootItems["general1_"..i]:addChild(cellCCB)
        end 
        --右
        self.rootItems["general2_"..i]:removeAllChildrenWithCleanup(true)
        local generalb = data["general"..i.."_b"]
        if generalb and generalb > 0 then
            local oldcid = data["oldcid"..i.."_b"]
            local oldconfigdata = gamedata.config.general[tostring(oldcid)] or {}
            
            local cellCCB, ccbItem = CCBReaderLoad("icons/new_icon", nil, true, "new_icon")
            cellCCB:setScale(0.96)
            if next(oldconfigdata) then
                ui.setNewIcon(ccbItem, {cid = generalb, quality = oldconfigdata.quality})
            else
                ui.setNewIcon(ccbItem, {cid = generalb})
            end
            
            cellCCB:setPosition(81,81)
            self.rootItems["general2_"..i]:addChild(cellCCB)
        end 
    end

    --显示宠物头像
    self.rootItems["general1_pet"]:removeAllChildrenWithCleanup(true)
    local peta_cid = data["pet_a"]
    if peta_cid and peta_cid > 0 then
        petConfig = gamedata.config.pet3_attr[tostring(peta_cid)] or {}
        local cellCCB, ccbItem = CCBReaderLoad("icons/new_icon", nil, true, "new_icon")
        cellCCB:setScale(0.96)
        if next(petConfig) then
            ui.setNewIcon(ccbItem, {cid = peta_cid, quality = petConfig.quality})
        else
            ui.setNewIcon(ccbItem, {cid = peta_cid})
        end

        cellCCB:setPosition(81,81)
        self.rootItems["general1_pet"]:addChild(cellCCB)
    end

    self.rootItems["general2_pet"]:removeAllChildrenWithCleanup(true)
    local petb_cid = data["pet_b"]
    if petb_cid and petb_cid > 0 then
        petConfig = gamedata.config.pet3_attr[tostring(petb_cid)] or {}
        local cellCCB, ccbItem = CCBReaderLoad("icons/new_icon", nil, true, "new_icon")
        cellCCB:setScale(0.96)
        if next(petConfig) then
            ui.setNewIcon(ccbItem, {cid = petb_cid, quality = petConfig.quality})
        else
            ui.setNewIcon(ccbItem, {cid = petb_cid})
        end

        cellCCB:setPosition(81,81)
        self.rootItems["general2_pet"]:addChild(cellCCB)
    end
end

-- 通用按钮
function godCompetitionBattleOdds.commonBtn(self, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)
    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(touchPriority or (self.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return godCompetitionBattleOdds