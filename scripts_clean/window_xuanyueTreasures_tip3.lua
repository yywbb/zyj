--
-- Author: songyibo
-- Date: 2019-12-20 09:56:25
--

local xueyue_tip3 = {
    rootNode = nil,
    rootItems = nil,
    needcallback = true,
    data= {},

    cancelTip = "xueyuemibao3"
}

function xueyue_tip3.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("xuanyuemibao/mibaotuisong", nil, true, "mibaotuisong3")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function xueyue_tip3.reload(self,data,callback)
    self.callback = callback

    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("xuanyueTreasureTip3")
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.goLab,"立即前往",19)
    self.rootItems.goButton:setSwallowsTouch(true)
    self.rootItems.goButton:setTouchPriority(self.touchPriority)
    self.rootItems.goButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("xuanyueTreasureTip3")
        GameScene:shiftLayer("xuanyueTreasures3","up")
    end, CCControlEventTouchUpInside)

    if gamedata.config:getConfigByName("global_kv").xuanyue3_denglu_reward then
    	local reward = ui.getIDandNUMs(gamedata.config:getConfigByName("global_kv").xuanyue3_denglu_reward.value)

    	for i=1,3 do
	        if reward[i] then
	            ui.setNewIconName(self.rootItems, {cid = reward[i].cid},i - 1)
	            -- items["i_button_"..i]:setTouchPriority(self.touchPriority)
	            -- items["i_button_"..i]:addHandleOfControlEvent(function()
	            --     if self.isContentScroll then return end
	            --     ui.setPopwindowByCid(highReward[i].cid)
	            -- end, CCControlEventTouchUpInside)
	        end
	    end
    end
    

end

function xueyue_tip3.close(self)

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
        self.callback = nil
    end
end

return xueyue_tip3