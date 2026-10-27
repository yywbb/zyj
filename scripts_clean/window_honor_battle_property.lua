local honorBattleProperty = {
    rootNode = nil,
    rootItems = nil,
    minNum = 1,
    maxNum = 10,
}

function honorBattleProperty.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function honorBattleProperty.open(self, touchPriority, data, callback)
    self.battleid = data.id
    self.mark = data.mark
    self.odds = data.odds
    self.isBet = data.isBet
    self.floorOdds = data.floorOdds
    self.oddsCount = 1

    self:initNode(touchPriority)
    self:initConfig()
    self:initEventBtn()
    self:initHeadIcon()
    self:initFixedString()
    self:refreshOkBtn()

    return self.rootNode, true
end

function honorBattleProperty.initNode(self, touchPriority)
    self.rootNode, self.rootItems = CCBReaderLoad("rongyaozhizhan/rongyaozhizhan_property", nil, true, "rongyaozhizhan_property")
    self.touchPriority = touchPriority
end

function honorBattleProperty.initConfig(self)
    self.oddsConfig = gamedata.config.glory_battle_odds
    self.lvbetConfig = gamedata.config.glory_battle_lvbet
    self.globalkvConfig = gamedata.config.global_kv
    self.maxNum = tonumber(self.globalkvConfig.glory_battle_yazhu.value)
end

function honorBattleProperty.initEventBtn(self)
    self:initCloseBtn()
    self:initMinusBtn()
    self:initAddBtn()
    self:initCancelBtn()
    self:initOkBtn()
end

function honorBattleProperty.initCloseBtn(self)
    local _cb = function()
        gameWindows:closeWindow("honorBattleProperty")
    end

    self:commonBtn(self.rootItems, "closeButton", _cb)
end

function honorBattleProperty.initMinusBtn(self)
    local _cb = function()
        if self.oddsCount > self.minNum then
            self.oddsCount = self.oddsCount - 1
            self.rootItems.buyNum:setString(self:getCurrentPrice())
        end
    end

    self:commonBtn(self.rootItems, "minusBtn", _cb)
end

function honorBattleProperty.initAddBtn(self)
    local _cb = function()
        if self.oddsCount < self.maxNum and self:getCurrentPrice(self.oddsCount + 1) <= self:getPlayerCoin() then
            self.oddsCount = self.oddsCount + 1
            self.rootItems.buyNum:setString(self:getCurrentPrice())
        end
    end

    self:commonBtn(self.rootItems, "addBtn", _cb)
end

function honorBattleProperty.initCancelBtn(self)
    local _cb = function()
        gameWindows:closeWindow("honorBattleProperty")
    end

    self:commonBtn(self.rootItems, "cancelBtn", _cb)
end

function honorBattleProperty.initOkBtn(self)
    local _cb = function()
        if self.isBet == 0 then
            if self:getPlayerCoin() >= self:getCurrentPrice() then
                --todo ? self:getCurrentPrice() or self.oddsCount
                UIRequest({
                    type = 6509, 
                    id = self.battleid,
                    mark=self.mark,
                    money=self:getCurrentPrice()
                    })
                gameWindows:closeAllWindowDirect()
            else
                runGamePrompt({msg = gameConfig.strings:string_common("honorBattle2", 23)})
            end
        end
    end

    self:commonBtn(self.rootItems, "okBtn", _cb)
end

function honorBattleProperty.getCurrentPayback( self, count )
    return self.floorOdds * self.odds * (count and count or self.oddsCount)
end

function honorBattleProperty.getCurrentPrice(self, count)
    return self.floorOdds * (count and count or self.oddsCount)
end

function honorBattleProperty.getMaxPrice(self)
    return self.floorOdds * self.maxNum
end

function honorBattleProperty.initHeadIcon(self)
    ui.setNewIcon(self.rootItems, {cid = GameScene.roleinfo.profile}, 0)
end

function honorBattleProperty.initFixedString(self)
    self.rootItems.nameLab:setString(GameScene.roleinfo.name)
    local _str = gameConfig.strings:string_common("honorBattle2", 8)..self.odds..gameConfig.strings:string_common("honorBattle2", 17)
    self.rootItems.oddsTxt:setString(_str)
    self.rootItems.getLab:setString(gameConfig.strings:string_common("honorBattle2", 18)..self:getCurrentPayback())
    ui.setLabelString(self.rootItems.cancelLab, gameConfig.strings:string_common("honorBattle2", 19), 19)
    ui.setLabelString(self.rootItems.okLab, gameConfig.strings:string_common("honorBattle2", 20), 19)
    self.rootItems.petmaxDescLab:setString(gameConfig.strings:string_common("honorBattle2", 21)..self:getMaxPrice())
    self.rootItems.owncoinLab:setString(gameConfig.strings:string_common("honorBattle2", 22)..self:getPlayerCoin())
    self.rootItems.buyNum:setString(self:getCurrentPrice())
end

function honorBattleProperty.getPlayerCoin(self)
    local _price = 0

    --todo
    -- if self.globalkvConfig[""].value then

    local _coinType = 0 

    if _coinType == 0 then
        _price = GameScene.roleinfo.coin
    elseif _coinType == 1 then
        _price = GameScene.roleinfo.gold
    end

    return _price
end

function honorBattleProperty.refreshOkBtn(self)
    if self.isBet == 0 then
        ui.removeGray("CCControlButton", self.rootItems.okBtn)
    else
        ui.addGray("CCControlButton", self.rootItems.okBtn)
    end
end

-- 通用按钮
function honorBattleProperty.commonBtn(self, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)
    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(touchPriority or (self.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return honorBattleProperty