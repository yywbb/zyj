
--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 18/3/8
-- Time: 15:00
-- To change this template use File | Settings | File Templates.
--

local exclusiveArtifact_rewardlist = {
    rootNode = nil,
    rootItems = nil,


}

function exclusiveArtifact_rewardlist.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("zhuanshushenqi/tc_qilingjingliyulan", nil, true, "bosschallenge_jingliyulan")
    self.touchPriority = touchPriority
    self.callback = callback

    self.rootItems.closeBtn:addHandleOfControlEvent(function()
        gameWindows:closeWindow("exclusiveArtifact_rewardlist")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeBtn:setSwallowsTouch(true)
    self.rootItems.closeBtn:setTouchPriority(self.touchPriority)

    self:reload(data)
    return self.rootNode
end

function exclusiveArtifact_rewardlist.reload(self,data)

    local dataconfig = gamedata.config.exclusive_device_spirit_copy[tostring(data.id)][tostring(data.difficulty)]
    local reward = ui.getIDRandNums(dataconfig.successful_reward) or {}

    for i = 1,18 do
        if self.rootItems["prop"..i] then
            if reward[i] and reward[i][1] and reward[i][1] > 0 then

                self.rootItems["prop"..i]:setVisible(true)
                ui.setNewIcon(self.rootItems,{cid = reward[i][1], num = reward[i][2]},i-1)

                --随机掉落
                local spritetemp = CCSprite:create("public/language/suijidiaoluozi.png")
                if spritetemp then
                    spritetemp:setPosition(110,110)
                    self.rootItems["prop"..i]:addChild(spritetemp)
                end

                local key_Ex = ""
                if i == 1 then
                    key_Ex = ""
                else
                    key_Ex = "_"..(i-1)
                end
                self.rootItems["i_button"..key_Ex]:addHandleOfControlEvent(function()
                    ui.setPopwindowByCid(reward[i][1])
                end, CCControlEventTouchUpInside)
                self.rootItems["i_button"..key_Ex]:setTouchPriority(self.touchPriority)
            else
                self.rootItems["prop"..i]:setVisible(false)
            end
        end
    end

    local reward2 = ui.getIDRandNums(dataconfig.failure_reward) or {}
    for i = 1,12 do
        if self.rootItems["prop_f"..i] then
            if reward2[i] and reward2[i][1] and reward2[i][1] > 0 then
                local num = reward2[i][2]
                if reward2[i][3] and (reward2[i][3] > reward2[i][2]) then
                    num = reward2[i][2].."~"..reward2[i][3]
                end
                self.rootItems["prop_f"..i]:setVisible(true)
                ui.setNewIcon_f(self.rootItems,{cid = reward2[i][1], num = num},i-1)
                
                local key_Ex = ""
                if i == 1 then
                    key_Ex = ""
                else
                    key_Ex = "_"..(i-1)
                end
                self.rootItems["i_button_f"..key_Ex]:addHandleOfControlEvent(function()
                    ui.setPopwindowByCid(reward2[i][1])
                end, CCControlEventTouchUpInside)
                self.rootItems["i_button_f"..key_Ex]:setTouchPriority(self.touchPriority)
            else
                self.rootItems["prop_f"..i]:setVisible(false)
            end
        end
    end
end

function exclusiveArtifact_rewardlist.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return exclusiveArtifact_rewardlist