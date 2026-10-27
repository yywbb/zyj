
local starGetRewardPreview = {
    rootNode = nil,
    rootItems = nil,
    rewardlevel = 1,
    maxlv = 1,
}

function starGetRewardPreview.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("activitystar/star_yulan", nil, true, "star_yulan")

    self.touchPriority = touchPriority
    --
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindowDirect("starGetRewardPreview")
        gameWindows:openWindow("starGetReward",data)
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    --
    ui.setLabelString(self.rootItems.backtext,nil,19)
    self.rootItems.backButton:addHandleOfControlEvent(function()
        gameWindows:closeWindowDirect("starGetRewardPreview")
        gameWindows:openWindow("starGetReward",data)
    end, CCControlEventTouchUpInside)
    self.rootItems.backButton:setSwallowsTouch(true)
    self.rootItems.backButton:setTouchPriority(self.touchPriority)
    --
    self.rootItems.leftButton:addHandleOfControlEvent(function()
        if self.rewardlevel > 1 then
            self.rewardlevel = self.rewardlevel-1
            self:reload(self.rewardlevel)
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.leftButton:setSwallowsTouch(true)
    self.rootItems.leftButton:setTouchPriority(self.touchPriority)
    --
    self.rootItems.rightButton:addHandleOfControlEvent(function()
        if self.rewardlevel < self.maxlv then
            self.rewardlevel = self.rewardlevel+1
            self:reload(self.rewardlevel)
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.rightButton:setSwallowsTouch(true)
    self.rootItems.rightButton:setTouchPriority(self.touchPriority)
    --
    local lvconfig = gamedata.config.watchstar_lv_reward or {}
    self.maxlv = table.getTableLength(lvconfig)
    self.rewardlevel = data.rewardlevel or 1
    --

    self:reload(self.rewardlevel)

    return self.rootNode
end

function starGetRewardPreview.reload(self,rewardlevel)

    if self.rewardlevel > 1 then
        self.rootItems.leftButton:setVisible(true)
    else
        self.rootItems.leftButton:setVisible(false)
    end

    if self.rewardlevel < self.maxlv then
        self.rootItems.rightButton:setVisible(true)
    else
        self.rootItems.rightButton:setVisible(false)
    end

    local lvconfig = gamedata.config.watchstar_lv_reward or {}
    if lvconfig[tostring(rewardlevel)] and lvconfig[tostring(rewardlevel)].name then
        self.rootItems.title:setString(lvconfig[tostring(rewardlevel)].name)
    end

    for k, v in pairs(gamedata.config.watchstar_reward) do
        local star = v.star;
        local rewards = ui.getIDandNUMs(v["rewards"..rewardlevel] or v.rewards)
        ui.setNewIconGuanxin(self.rootItems,{num = rewards[1].num,cid = rewards[1].cid,starnum = star},tonumber(k)-1)
        self.rootItems["i_button"..(tonumber(k) == 1 and "" or "_" ..((tonumber(k)-1)))]:setTouchPriority(self.touchPriority)
        self.rootItems["i_button"..(tonumber(k) == 1 and "" or "_" ..((tonumber(k)-1)))]:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            ui.setPopwindowByCid(rewards[1].cid)
        end,CCControlEventTouchUpInside)
        self.rootItems["starnum"..(tonumber(k) == 1 and "" or "_" ..((tonumber(k)-1)))]:setString(tostring(star).."星辰")

        self.rootItems["lingqu"..(tonumber(k) == 1 and "" or "_" ..((tonumber(k)-1)))]:setVisible(false)

        self.rootItems["kelingqu"..(tonumber(k) == 1 and "" or "_" ..((tonumber(k)-1)))]:setVisible(false)
    end


end

function starGetRewardPreview.close(self)
    self.maxlv = 1
    self.rewardlevel = 1
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return starGetRewardPreview

