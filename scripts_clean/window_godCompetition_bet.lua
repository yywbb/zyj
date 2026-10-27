--新增的押注界面
local godCompetitionBet = {
    cellSize1 = {width = 920, height = 350},
    cellSize2 = {width = 920, height = 430},

    rootNode = nil,
    rootItems = nil,

    minNum = 1,
    maxNum = 10,
    ccbDocument = {},
}

--TODO   add  new  Window
function godCompetitionBet.close(self)

    self.ccbDocument = {}

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)

    self.rootNode = nil
    self.rootItems = nil
    self.selectOdds =1
end

function godCompetitionBet.open(self, touchPriority, data, callback)

    self.listTableView = nil
    self:initNode(touchPriority)
    self:initCloseBtn()
    self.oddsCount = 1
    self.data = data
    self.battledata = data.battledata
    if data.betdata then
        self.betdata = data.betdata
        self:initConfig()
        self.floorOdds = self:getFloorOdds()
        self:reloadOdds()--这个不需要请求了  就直接在这儿处理
        self:initIcon()
        self.rootItems.label_l_name:setString(data.player1.name)
        self.rootItems.label_r_name:setString(data.player2.name)
        self.rootItems.label_l_power:setString(gameConfig.strings:string_common("honorBattle2", 6)..self:getTotalPower("a"))
        self.rootItems.label_r_power:setString(gameConfig.strings:string_common("honorBattle2", 6)..self:getTotalPower("b"))
        self:initMinusBtn()
        self:initAddBtn()
        self:initMinusTenBtn()
        self:initAddTenBtn()
    end

    return self.rootNode
end

--TODO  addTen  change  choosechange
function godCompetitionBet.initIcon(self)
    printT(self.data.player1)
    ui.setNewIcon(self.rootItems,{cid = self.data.player1.profile},0)
    ui.setNewIcon(self.rootItems,{cid = self.data.player2.profile},1)
end

-- 初始化界面
function godCompetitionBet.initNode(self, touchPriority)
    self.rootNode, self.rootItems = CCBReaderLoad("fengshensai/tc_jingcai", nil, true, "tc_jingcai")
    self.touchPriority = touchPriority
    self.rootItems.oddsNode:setVisible(true)
end

-- 初始化配置表
function godCompetitionBet.initConfig(self)
    self.oddsConfig = gamedata.config.apex_battle_odds
    self.lvbetConfig = gamedata.config.apex_battle_lvbet
    self.maxrate = tonumber(gamedata.config.global_kv.apex_fudong_up.value)
    self.minrate = tonumber(gamedata.config.global_kv.apex_fudong_down.value)
    self.globalkvConfig = gamedata.config.global_kv

    self.maxNum = self.betdata.restbetcount
end

-- 初始化关闭按钮
function godCompetitionBet.initCloseBtn(self)
    ui.setLabelString(self.rootItems.betconcelTxt, gameConfig.strings:string_common("honorBattle2", 19), 19)
    local _cb = function()
        gameWindows:closeWindow("godCompetitionBet")
    end

    self:commonBtn(self.rootItems, "cancelBtn", _cb)
end

------------------------------------------------------

function godCompetitionBet.reloadOdds( self )

    if self.data.betdata.result>=0 then
        if self.data.betdata.bet>0 then
            self.selectOdds = self.data.betdata.betnum
        else
            self.selectOdds = 0
        end
    else
        if self.data.betdata.bet>0 then
            self.selectOdds = self.data.betdata.betnum
        else
            self.selectOdds = self.selectOdds or 1
        end
    end

    self:chooseOdds()

    for i = 1, 6 do
        self:initChooseOddsBtn(i,self.data.betdata.result<0 and self.data.betdata.bet<=0)
    end

    self:initOddsBtn()

    self:initFixedString() --显示当前的押注情况 

end

function godCompetitionBet.getTotalPower(self, powerType)
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

function godCompetitionBet.getOdds( self,idx )
    local _odds = math.pow(math.pow(self:getTotalPower("a") / self:getTotalPower("b"), 2.3), self.oddsConfig[tostring(idx)].odds) + 1
    _odds = _odds - _odds%0.01
    _odds = math.max(_odds,self.minrate)
    _odds = math.min(_odds,self.maxrate)
    return _odds
end

function godCompetitionBet.getBetNum( self,num )
    return (4-num)..":"..(num-1)
end

--获取底注
function godCompetitionBet.getFloorOdds(self)
    local idx = 1
    local _row = self.lvbetConfig[tostring(idx)]
    while _row and GameScene.roleinfo.level >= _row.interval do
        idx = idx + 1
        _row = self.lvbetConfig[tostring(idx)]
    end
    return self.lvbetConfig[tostring(idx-1)].lv_bet
end

function godCompetitionBet.chooseOdds(self)
    for i = 1, 6 do
        self.rootItems["oddsEffect"..i]:setVisible(self.selectOdds == i)
    end
    self:getCurrentPayback()
end

function godCompetitionBet.initChooseOddsBtn(self, index,iscanbet)
    if index <= 6 then
        self.rootItems["oddsTxt"..index]:setString(gameConfig.strings:string_common("honorBattle2", 8)..self:getOdds(index))
    end

    local _cb = function()
        self.selectOdds = index
        self:chooseOdds()
    end
    self:commonBtn(self.rootItems, "chooseOddsBtn"..index, iscanbet and _cb or function() end)
end

function godCompetitionBet.initOddsBtn(self)

    ui.setLabelString(self.rootItems.betBtnTxt, gameConfig.strings:string_common("honorBattle2", 10), 19)
    local godstatus = GameScene.layers["godCompetitionMain"].module.godStatus.status
    if godstatus > self.betdata.betstatus then
        ui.addGray("CCControlButton", self.rootItems.betBtn)
    else
        ui.removeGray("CCControlButton", self.rootItems.betBtn)
    end

    ---add
    local _cb = function()
        if self.betdata.bet == 0 then
            if self:getPlayerCoin() >= self:getCurrentPrice() then
                UIRequest({
                    type = 8275, 
                    id = self.data.id,
                    mark=self.selectOdds,
                    money=self:getCurrentPrice()
                    })
                gameWindows:closeAllWindowDirect()
            else
                runGamePrompt({msg = gameConfig.strings:string_common("honorBattle2", 23)})
            end
        end
    end
    self:commonBtn(self.rootItems, "betBtn", _cb)
end
--------------------------------------------------------------------

-- 通用按钮
function godCompetitionBet.commonBtn(self, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)
    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(touchPriority or (self.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

function godCompetitionBet.initFixedString(self)
    self.rootItems.label_limt:setString(gameConfig.strings:string_common("honorBattle2", 21)..self:getMaxPrice())
    self.rootItems.label_canuse:setString(gameConfig.strings:string_common("honorBattle2", 22)..self:getPlayerCoin())
    self.rootItems.buynum:setString(self:getCurrentPrice())
end

function godCompetitionBet.getCurrentPayback( self, count )
    return self.rootItems.label_totalGet:setString(gameConfig.strings:string_common("honorBattle2", 18).. self.floorOdds * self:getOdds(self.selectOdds) * (count and count or self.oddsCount))
end

function godCompetitionBet.getCurrentPrice(self, count)
    return self.floorOdds * (count and count or self.oddsCount)
end

function godCompetitionBet.getMaxPrice(self)
    return self.floorOdds * self.maxNum
end

function godCompetitionBet.getPlayerCoin(self)
    local _price = 0

    local _coinType = 0 

    if _coinType == 0 then
        _price = GameScene.roleinfo.coin
    elseif _coinType == 1 then
        _price = GameScene.roleinfo.gold
    end

    return _price
end

function godCompetitionBet.initMinusBtn(self)
    local _cb = function()
        if self.oddsCount > self.minNum then
            self.oddsCount = self.oddsCount - 1
            self.rootItems.buynum:setString(self:getCurrentPrice())
            self:getCurrentPayback()
        end
    end

    self:commonBtn(self.rootItems, "sub1", _cb)
end

function godCompetitionBet.initMinusTenBtn(self)
    local _cb = function()
        if self.oddsCount - 10 < self.minNum then
            self.oddsCount = self.minNum
        else
            self.oddsCount = self.oddsCount-10
        end
        self.rootItems.buynum:setString(self:getCurrentPrice())
        self:getCurrentPayback()
    end

    self:commonBtn(self.rootItems, "sub10", _cb)
end

function godCompetitionBet.initAddTenBtn(self)
    local _cb = function()
        if self.oddsCount+10 > self.maxNum and self:getCurrentPrice(maxNum) <= self:getPlayerCoin() then
            self.oddsCount = self.maxNum
        else
            if self:getCurrentPrice(self.oddsCount+10) <= self:getPlayerCoin() then
            self.oddsCount = self.oddsCount+10  
            end
        end
        self.rootItems.buynum:setString(self:getCurrentPrice())
        self:getCurrentPayback()
    end

    self:commonBtn(self.rootItems, "add10", _cb)
end

function godCompetitionBet.initAddBtn(self)
    local _cb = function()
        if self.oddsCount < self.maxNum and self:getCurrentPrice(self.oddsCount + 1) <= self:getPlayerCoin() then
            self.oddsCount = self.oddsCount + 1
            self.rootItems.buynum:setString(self:getCurrentPrice())
            self:getCurrentPayback()
        end
    end

    self:commonBtn(self.rootItems, "add1", _cb)
end


return godCompetitionBet