--公会守卫奖励弹窗

local guardReward = {
    rootNode = nil,
    rootItems = nil,
    data = {},
    boxRewardTab = {}
}

function guardReward.open(self,touchPriority,data,callback)
    self.touchPriority = touchPriority
    self.data = data

    self.rootNode, self.rootItems = CCBReaderLoad("gonghui2/gonghui_shouweijiangli", nil, true, "gonghui_shouweijiangli")
    self:reload(self.data,callback)
    
    return self.rootNode
end


function guardReward.reload(self,data,callback)
    print(callback,"callback   ---  ")
    printT(data)
    self.callback = callback

    ui.setLabelString(self.rootItems.hightScoreLab,(data.hightScore > data.guardDataTab.score and data.hightScore or data.guardDataTab.score),50)
    self.rootItems.currentScore:setString(data.guardDataTab.score)

    if data.guardDataTab.hightStatus and data.guardDataTab.hightStatus == 1 then
        self.rootItems.hightSpr:setVisible(true)
    else
        self.rootItems.hightSpr:setVisible(false)
    end

    for i=1,4 do
        if data.guardDataTab.boxTab[tostring(i)] then
            self.rootItems["boxRewardNode"..i]:setVisible(true)
            self.boxRewardTab["boxCcb"..i],self.boxRewardTab["boxItem"..i] = CCBReaderLoad("gonghui2/cell_shouwejianglibox.ccbi", nil, true, "cell_shouwejianglibox")
            ui.setLabelString(self.boxRewardTab["boxItem"..i].fixedStr1,gameConfig.strings:string_common("guild_guard",14))
            self.boxRewardTab["boxAnimation"..i] = getAnimationManager(self.boxRewardTab["boxItem"..i])
            self.rootItems["boxRewardNode"..i]:addChild(self.boxRewardTab["boxCcb"..i])
            self.boxRewardTab["boxAnimation"..i]:runAnimationsForSequenceNamed("box")

            self.boxRewardTab["boxItem"..i].openBtn:addHandleOfControlEvent(function()
                self.boxRewardTab["boxAnimation"..i]:runAnimationsForSequenceNamed("jiangli")
            end, CCControlEventTouchUpInside)
            self.boxRewardTab["boxItem"..i].openBtn:setSwallowsTouch(true)
            self.boxRewardTab["boxItem"..i].openBtn:setTouchPriority(self.touchPriority)

            local rewardcid,rewardnum = ui.getIDandNUM(gamedata.config.guild_box_total[tostring(data.guardDataTab.boxTab[tostring(i)])].type)
            ui.setNewIcon(self.boxRewardTab["boxItem"..i],{cid = rewardcid,num = rewardnum })

        else
            self.rootItems["boxRewardNode"..i]:setVisible(false)
        end
    end

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        if self.callback then
            self.callback()
            self.callback = nil
            -- showRewardPopupWindow(t.reward,nil,function()
                
            -- end)
            -- UIRequest({type = 1001})
        end
        gameWindows:closeWindowDirect("guardReward")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

end

function guardReward.close(self)
    
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    
    if guide.controller then
        guide.controller:setGuideLayerVisible(true)
    end

    if self.callback then
        self.callback()
    end
    
end

return guardReward