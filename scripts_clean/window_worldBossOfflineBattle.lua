--世界boss离线战斗
local worldBossOfflineBattle = {
    rootNode = nil,
    rootItems = nil,
   	callback = nil,
}

function worldBossOfflineBattle.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("worldboss2/tc_offlineBattle", nil, true, "tc_offlineBattle")
    
    ui.setLabelString(self.rootItems.doLab1,gameConfig.strings:string_common("popups","quxiao"),19)
    ui.setLabelString(self.rootItems.doLab2,gameConfig.strings:string_common("popups","queding"),19)
    --self.rootItems.desc:setString(string.format(gameConfig.strings:string_common("fixedString","exchangeMore",2),data.max))
    local costConfig = gamedata.config.global_kv.boss_off_line.value
    local costGold = gamedata.getIDandNUMs(costConfig)
    self.rootItems.costgold:setString("消耗元宝:".. costGold[1].num)
	self.touchPriority = touchPriority
    
    self.rootItems.doButton1:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("worldBossOfflineBattle")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton1:setSwallowsTouch(true)
    self.rootItems.doButton1:setTouchPriority(self.touchPriority)
    
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("worldBossOfflineBattle")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.doButton2:addHandleOfControlEvent(function()
        self.callback()
        self.callback = nil
        gameWindows:closeWindow("worldBossOfflineBattle")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton2:setSwallowsTouch(true)
    self.rootItems.doButton2:setTouchPriority(self.touchPriority)

    
    self:reload(data,callback)
    
	return self.rootNode
end

function worldBossOfflineBattle.reload(self,data,callback)
    self.data = data
    self.callback = callback
end

function worldBossOfflineBattle.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.callback = nil
end

return worldBossOfflineBattle