--
-- Author: songyibo
-- Date: 2019-12-20 09:58:48
--

local xuanyueTreasuresActivate3 = {
    rootNode = nil,
    rootItems = nil,
}

function xuanyueTreasuresActivate3.open(self,touchPriority,data,callback)
    self.touchPriority = touchPriority
    self.id = data.id

    self.rootNode,self.rootItems = CCBReaderLoad("xuanyuemibao/mibaojianglijihuo", nil, true, "mibaojianglijihuo3")

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("xuanyueTreasuresActivate3")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems["goButton"]:setSwallowsTouch(true)
    self.rootItems["goButton"]:setTouchPriority(self.touchPriority)
    self.rootItems["goButton"]:addHandleOfControlEvent(function()
        GameScene:shiftLayer("xuanyueTreasures3","up")
    end, CCControlEventTouchUpInside)
    

    self:initFixedString()
    self:reload()

    return self.rootNode
end

function xuanyueTreasuresActivate3.reload(self)

	local config = gamedata.config:getConfigByName("xuanyue3_reward")[tostring(self.id)]
    local lowReward = ui.getIDandNUMs(config.reward1)
    local highReward = ui.getIDandNUMs(config.reward2)

    ui.setNewIconName(self.rootItems, {cid = lowReward[1].cid})
    -- items["i_button"]:setTouchPriority(self.touchPriority)
    -- items["i_button"]:addHandleOfControlEvent(function()
    --     if self.isContentScroll then return end
    --     ui.setPopwindowByCid(lowReward[1].cid)
    -- end, CCControlEventTouchUpInside)

    for i=1,2 do
        if highReward[i] then
            ui.setNewIconName(self.rootItems, {cid = highReward[i].cid},i)
            -- items["i_button_"..i]:setTouchPriority(self.touchPriority)
            -- items["i_button_"..i]:addHandleOfControlEvent(function()
            --     if self.isContentScroll then return end
            --     ui.setPopwindowByCid(highReward[i].cid)
            -- end, CCControlEventTouchUpInside)
        end
    end
end

function xuanyueTreasuresActivate3.initFixedString(self)
	ui.setLabelString(self.rootItems.goLab,gameConfig.strings:string_common("xuanyueTreasures",12),18)
end

function xuanyueTreasuresActivate3.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end	
end
return xuanyueTreasuresActivate3