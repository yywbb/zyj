

local hadesAllReward = {
    rootNode = nil,
    rootItems = nil,
}

function hadesAllReward.open(self,touchPriority,data,callback)
    
    self.rootNode, self.rootItems = CCBReaderLoad("copydiyu/copydiyu_jiangliyulan", nil, true, "copydiyu_jiangliyulan")
    
    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function hadesAllReward.reload(self,data,callback)
    self.callback = callback

    local rewardnum = data.mapboxreward and #data.mapboxreward or 0
    for i = 1,5 do
        if data.mapboxreward[i] then
            self.rootItems["reward"..i]:setVisible(true)
            ui.setNewIcon(self.rootItems,data.mapboxreward[i],i-1)
            self.rootItems["i_button"..((i>1) and ("_"..(i-1)) or "")]:addHandleOfControlEvent(function()
                ui.setPopwindowByCid(data.mapboxreward[i].cid)
            end, CCControlEventTouchUpInside)
            self.rootItems["i_button"..((i>1) and ("_"..(i-1)) or "")]:setSwallowsTouch(true)
            self.rootItems["i_button"..((i>1) and ("_"..(i-1)) or "")]:setTouchPriority(self.touchPriority)
            --
            self.rootItems["reward"..i]:setPositionX(0-(rewardnum-1)*85+170*(i-1))
        else
            self.rootItems["reward"..i]:setVisible(false)
        end
    end    
    --
    if data.mapboxstatus and data.mapboxstatus == 1 then
        ui.setLabelString(self.rootItems.rewardTxt,"领 取",19)
        ui.removeGray("CCControlButton", self.rootItems["rewardBtn"])
        self.rootItems.rewardBtn:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            gameWindows:closeWindow("hadesAllReward")
            UIRequest({type = 1372,mapid = data.mapid})
        end, CCControlEventTouchUpInside)
        self.rootItems.rewardBtn:setSwallowsTouch(true)
        self.rootItems.rewardBtn:setTouchPriority(self.touchPriority)

    elseif data.mapboxstatus and data.mapboxstatus == 2 then
         ui.setLabelString(self.rootItems.rewardTxt,"已领取",19)
        ui.addGray("CCControlButton", self.rootItems["rewardBtn"])
        self.rootItems.rewardBtn:addHandleOfControlEvent(function()
            runGamePrompt({msg = "已领取过本关通关奖励"})
        end, CCControlEventTouchUpInside)
        self.rootItems.rewardBtn:setSwallowsTouch(true)
        self.rootItems.rewardBtn:setTouchPriority(self.touchPriority)
    else
        ui.setLabelString(self.rootItems.rewardTxt,"领 取",19)
        ui.addGray("CCControlButton", self.rootItems["rewardBtn"])
        self.rootItems.rewardBtn:addHandleOfControlEvent(function()
            runGamePrompt({msg = "通关第"..((data.mapid - 42100)*5).."关可领取"})
        end, CCControlEventTouchUpInside)
        self.rootItems.rewardBtn:setSwallowsTouch(true)
        self.rootItems.rewardBtn:setTouchPriority(self.touchPriority)
    end    
end

function hadesAllReward.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return hadesAllReward