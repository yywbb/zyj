
--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 18/3/8
-- Time: 15:00
-- To change this template use File | Settings | File Templates.
--

local bosschallenge_rewardlist = {
    rootNode = nil,
    rootItems = nil,
}

function bosschallenge_rewardlist.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("bosschallenge/bosschallenge_jingliyulan2", nil, true, "bosschallenge_jingliyulan")
    self.touchPriority = touchPriority
    self.callback = callback

    if self.rootItems.desc then
        ui.setLabelString(self.rootItems.desc,nil,14)
    end       

    self:reload(data)
    return self.rootNode
end

function bosschallenge_rewardlist.reload(self,data)

    local dataconfig = gamedata.config.heroboss[tostring(data.bossid)]
    local reward = ui.getIDRandNums(dataconfig.award) or {}

    for i = 1,12 do
        if self.rootItems["prop"..i] then
            if reward[i] and reward[i][1] and reward[i][1] > 0 then
                local num = reward[i][2]
                if reward[i][3] and (reward[i][3] > reward[i][2]) then
                    num = reward[i][2].."~"..reward[i][3]
                end
                self.rootItems["prop"..i]:setVisible(true)
                ui.setNewIcon(self.rootItems,{cid = reward[i][1], num = num},i-1)

                if reward[i][4] and reward[i][4] ~= 100 then
                    local spritetemp = CCSprite:create("public/language/suijidiaoluozi.png")
                    if spritetemp then
                        spritetemp:setPosition(110,110)
                        self.rootItems["prop"..i]:addChild(spritetemp)
                    end
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

    local reward2 = ui.getIDRandNums(dataconfig.reward) or {}
    for i = 1,12 do
        if self.rootItems["prop"..(i+12)] then
            if reward2[i] and reward2[i][1] and reward2[i][1] > 0 then
                local num = reward2[i][2]
                if reward2[i][3] and (reward2[i][3] > reward2[i][2]) then
                    num = reward2[i][2].."~"..reward2[i][3]
                end
                self.rootItems["prop"..(i+12)]:setVisible(true)
                ui.setNewIcon(self.rootItems,{cid = reward2[i][1], num = num},i+11)

                if reward2[i][4] and reward2[i][4] ~= 100 then
                    local spritetemp = CCSprite:create("public/language/suijidiaoluozi.png")
                    if spritetemp then
                        spritetemp:setPosition(110,110)
                        self.rootItems["prop"..(i+12)]:addChild(spritetemp)
                    end
                end
                
                local key_Ex = "_"..(i+11)
                self.rootItems["i_button"..key_Ex]:addHandleOfControlEvent(function()
                    ui.setPopwindowByCid(reward2[i][1])
                end, CCControlEventTouchUpInside)
                self.rootItems["i_button"..key_Ex]:setTouchPriority(self.touchPriority)
            else
                self.rootItems["prop"..(i+12)]:setVisible(false)
            end
        end
    end

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("bosschallenge_rewardlist")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end

function bosschallenge_rewardlist.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return bosschallenge_rewardlist