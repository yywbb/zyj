local greatGiftByAD = {
    rootNode = nil,
    rootItems = nil,
    adOnceRed = true,
}

function greatGiftByAD.open(self,touchPriority,data,callback)
    print("greatGiftByAD.open===")
    self.rootNode, self.rootItems = CCBReaderLoad("mianfeihaoli/window_mianfeihaoli", nil, true, "window_mianfeihaoli")
    self.touchPriority = touchPriority

    local config = gamedata.config.free_gift
    printT(config,"config")
    printT(self.rootItems,"self.rootItems")
    UIRequest({type=8091})
    self:reload(data,callback)
    self.adOnceRed = false
    return self.rootNode,true
end

function greatGiftByAD.reload(self,data,callback)
    self.callback = callback
    printT(data,"data")

    --5格奖励
    for i=1,5 do
        local config_i = gamedata.config.free_gift[tostring(i)]
        local reward = ui.getIDandNUMs(config_i.reward)
        print(config_i.reward,"config_i.reward")
        ui.setNewIcon(self.rootItems,{cid = reward[1].cid, num = reward[1].num},i - 1)
        self.rootItems["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
            ui.setPopwindowByCid(reward[1].cid)
        end, CCControlEventTouchUpInside)
        self.rootItems["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(self.touchPriority)
    end

    self:updateAdButtonStatus(data)
    local adButtonStatus = self:getAdButtonStatus(data)
    printT(adButtonStatus,"adButtonStatus")
    self.rootItems.adButton:setSwallowsTouch(true)
    self.rootItems.adButton:setTouchPriority(self.touchPriority)
    self.rootItems.adButton_1:setSwallowsTouch(true)
    self.rootItems.adButton_1:setTouchPriority(self.touchPriority)
    self:changeButtonStatus(adButtonStatus.type,adButtonStatus.items)

end

function greatGiftByAD.updateAdButtonStatus(self,data)
    for i=1,5 do
        if data.adStatus then
            local adStatusNum = data.adStatus["status"..i] or 0
            print("status"..i..":"..adStatusNum)
            if adStatusNum == 0 then
                self.rootItems["received_"..i]:setVisible(false)
                self.rootItems["aviliable_"..i]:setVisible(false)
            elseif adStatusNum == 1 then
                self.rootItems["received_"..i]:setVisible(false)
                self.rootItems["aviliable_"..i]:setVisible(true)
            elseif adStatusNum == 2 then
                self.rootItems["received_"..i]:setVisible(true)
                self.rootItems["aviliable_"..i]:setVisible(false)
            end
        else
            print("data is nil!")
        end
    end
end

function greatGiftByAD.getAdButtonStatus(self,data)
    for i=1,5 do
        if data.adStatus then
            local adStatusNum = data.adStatus["status"..i] or 0
            if adStatusNum == 0 then
                return {items = i,type = 0}
            elseif adStatusNum == 1 then
                return {items = i,type = 1}
            end
        else
            print("data is nil!")
        end
    end
    return {items = 0,type = 2}
end

function greatGiftByAD.changeButtonStatus(self,type,items)
    if type == 2 then
        self.rootItems.buttonNode_1:setVisible(false)
        self.rootItems.buttonNode:setVisible(true)
        ui.addGray("CCControlButton",self.rootItems.adButton)
        ui.setLabelString(self.rootItems.adButtonText,gameConfig.strings:string_common("fixedString","greatGiftByAD",3),18)
        self.rootItems.adButton:addHandleOfControlEvent(function()
            runGamePrompt({msg = gameConfig.strings:string_common("fixedString","greatGiftByAD",4)})
        end, CCControlEventTouchUpInside)
        -- GameScene.layers["main"].module:reloadFirstRechargeStatus(t.firstRecharge)
    elseif type == 1 then
        self.rootItems.buttonNode_1:setVisible(false)
        self.rootItems.buttonNode:setVisible(true)
        ui.removeGray("CCControlButton",self.rootItems.adButton)
        ui.setLabelString(self.rootItems.adButtonText,gameConfig.strings:string_common("fixedString","greatGiftByAD",2),18)
        self.rootItems.adButton:addHandleOfControlEvent(function()
            UIRequest({type=8092,index = items})
        end, CCControlEventTouchUpInside)
    elseif type == 0 then
        self.rootItems.buttonNode_1:setVisible(true)
        self.rootItems.buttonNode:setVisible(false)
        ui.setLabelString(self.rootItems.adButtonText_1,gameConfig.strings:string_common("fixedString","greatGiftByAD",1),18)
        self.rootItems.adButton_1:addHandleOfControlEvent(function()
            gamedata.sdk:showAd(3,{type=8093,index=items})
        end, CCControlEventTouchUpInside)
    end
end

function greatGiftByAD.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return greatGiftByAD