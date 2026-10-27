local windowTreasureTips = {
    rootNode = nil,
    rootItems = nil,
}

function windowTreasureTips.open(self,touchPriority,data,callback)
    self.touchPriority = touchPriority
    self.root = CCNode:create()
    self.rootNode, self.rootItems = CCBReaderLoad("gonghuizhan/gonghuizhan_tc_baoming", nil, true, "treasureTips")
    print("windowTreasureTips gonghuizhan_tc_baozanginfo rootItems ============")
    printT(self.rootItems)
    self:loadTreasureTips(data)
    self.root:addChild(self.rootNode)
    return self.root
end

function windowTreasureTips.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end
-- {num = self.data.guildnum,name = self.data.guildnum.name,guildid =self.data.guildid }
function windowTreasureTips.loadTreasureTips(self,aiData)
    print("windowTreasureTips.loadTreasureTips")
    printT(aiData)
    ui.setLabelString(self.rootItems.name,aiData.name,1)
    if aiData.guildid ~= 0 or aiData.guildid ~= "0" then
        ui.setLabelString(self.rootItems.num,gameConfig.strings:string_common("guild_treasureinfo",9),23)
    else
        ui.setLabelString(self.rootItems.num,gameConfig.strings:string_common("guild_treasureinfo",8),23)
    end
    ui.setLabelString(self.rootItems.attkCondition,gameConfig.strings:string_common("guild_treasureinfo",14),49)
    ui.setLabelString(self.rootItems.signUpNum,aiData.num,23)
    local width = self.rootItems.name:getContentSize().width
    if width > 114 then
        self.rootItems.text1:setString(gameConfig.strings:string_common("guild_treasureinfo",13))
    elseif width > 76 then
        self.rootItems.text1:setString(gameConfig.strings:string_common("guild_treasureinfo",12))
    else 
        self.rootItems.text1:setString(gameConfig.strings:string_common("guild_treasureinfo",11))
    end
    self.rootItems.cancleButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("guildtreasuretips")
    end, CCControlEventTouchUpInside)
    self.rootItems.cancleButton:setTouchPriority(self.touchPriority)
    self.rootItems.cancleButton:setSwallowsTouch(true)
    ui.setLabelString(self.rootItems.certainLabel,gameConfig.strings:string_common("guild_treasureinfo",15),19)
    self.rootItems.certainButton:addHandleOfControlEvent(function()
        UIRequest({type = 2132,id = aiData.id})
    end, CCControlEventTouchUpInside)

    self.rootItems.certainButton:setTouchPriority(self.touchPriority)
    self.rootItems.certainButton:setSwallowsTouch(true) 
    ui.setLabelString(self.rootItems.cancleLabel,gameConfig.strings:string_common("guild_treasureinfo",16),19)   
end

return windowTreasureTips