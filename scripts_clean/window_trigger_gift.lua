

local triggerGift = {
    rootNode = nil,
    rootItems = nil,
    iid = 0,
}

function triggerGift.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("activityreward_new/xianshilibao", nil, true, "xianshilibao")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function triggerGift.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("triggerGift")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    --
    if not (data and data.cid) then return end
    self.iid = data.iid or 0
    --
    local allconfig = gamedata.config.trigger_gift or {}
    local rewardconfig = allconfig[tostring(data.cid)] or {}
    local rewards = {}
    if rewardconfig.gift_id and rewardconfig.gift_id ~= "" then
        rewards = ui.getIDandNUMs(rewardconfig.gift_id)
    end

    ui.setLabelString(self.rootItems.name,rewardconfig.name or "",1)

    for i = 1,4 do
        if rewards[i] then
            self.rootItems["reward"..i]:setVisible(true)
            ui.setNewIconName(self.rootItems,rewards[i],i-1)
            --
            self.rootItems["in_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
                ui.setPopwindowByCid(rewards[i].cid)
            end, CCControlEventTouchUpInside)
            self.rootItems["in_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(self.touchPriority)
        else
            self.rootItems["reward"..i]:setVisible(false)
        end
    end

    --
    local price = {}
    if rewardconfig.price and rewardconfig.price ~= "" then
        price = ui.getIDandNUMs(rewardconfig.price)
    end
    if price[1] then
        if price[1].cid == 1000 then
            self.rootItems.xcoin:setVisible(true)
            self.rootItems.xgold:setVisible(false)
            if price[1].num > GameScene.roleinfo.coin then
                ui.setLabelString(self.rootItems.xnum,price[1].num,24)
            else
                ui.setLabelString(self.rootItems.xnum,price[1].num,14)
            end
        elseif price[1].cid == 1001 then
            self.rootItems.xcoin:setVisible(false)
            self.rootItems.xgold:setVisible(true)
            if price[1].num > GameScene.roleinfo.gold then
                ui.setLabelString(self.rootItems.xnum,price[1].num,24)
            else
                ui.setLabelString(self.rootItems.xnum,price[1].num,14)
            end
        end
    else
        ui.setLabelString(self.rootItems.xnum,"",14)
        self.rootItems.xcoin:setVisible(false)
        self.rootItems.xgold:setVisible(false)
    end

    --
    ui.setLabelString(self.rootItems.buyLab,nil,19)
    self.rootItems.buyButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        gameWindows:closeWindowDirect("triggerGift")
        --
        UIRequest({type = 4801, iid = data.iid, price = price})
    end, CCControlEventTouchUpInside)
    self.rootItems.buyButton:setSwallowsTouch(true)
    self.rootItems.buyButton:setTouchPriority(self.touchPriority)

    --
    if gameTimer.times["triggergift"..self.iid] and gameTimer.times["triggergift"..self.iid] > 0 then
        gameTimer:rigistTimeFunc("triggergift"..self.iid,function()
            if gameTimer.times["triggergift"..self.iid] > 0 then
                if self.rootItems and self.rootItems.time then
                    ui.setLabelString(self.rootItems.time,"倒计时："..ui.makeTimeText(gameTimer.times["triggergift"..self.iid],"hour"),22)
                end
            else
                gameTimer:UnrigistTime("triggergift"..self.iid)
                gameTimer:UnrigistTimeFunc("triggergift"..self.iid)
                gameWindows:closeWindowDirect("triggerGift")
            end
        end)
    else
        gameWindows:closeWindowDirect("triggerGift")
    end


end

function triggerGift.close(self)

    if gameTimer.times["triggergift"..self.iid] then
        gameTimer:UnrigistTimeFunc("triggergift"..self.iid)
    end

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return triggerGift