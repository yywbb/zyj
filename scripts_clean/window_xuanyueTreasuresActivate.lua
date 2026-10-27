--
-- Author: songyibo
-- Date: 2019-08-20 16:29:14
--

local xuanyueTreasuresActivate = {
    rootNode = nil,
    rootItems = nil,
}

function xuanyueTreasuresActivate.open(self,touchPriority,data,callback)
    self.touchPriority = touchPriority
    self.id = data.id

    self.rootNode,self.rootItems = CCBReaderLoad("xuanyuemibao/mibaojianglijihuo", nil, true, "mibaojianglijihuo")

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("xuanyueTreasuresActivate")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems["goButton"]:setSwallowsTouch(true)
    self.rootItems["goButton"]:setTouchPriority(self.touchPriority)
    self.rootItems["goButton"]:addHandleOfControlEvent(function()
        GameScene:shiftLayer("xuanyueTreasures","up")
    end, CCControlEventTouchUpInside)
    

    self:initFixedString()
    self:reload()

    return self.rootNode
end

function xuanyueTreasuresActivate.reload(self)

	local config = gamedata.config:getConfigByName("xuanyue_reward")[tostring(self.id)]
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

function xuanyueTreasuresActivate.initFixedString(self)
	ui.setLabelString(self.rootItems.goLab,gameConfig.strings:string_common("xuanyueTreasures",12),18)
end

function xuanyueTreasuresActivate.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end	
end
return xuanyueTreasuresActivate