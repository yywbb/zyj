--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 16/2/14
-- Time: 下午4:50
-- To change this template use File | Settings | File Templates.
--

local playerback = {
    rootNode = nil,
    rootItems = nil,
    data = {},
    rewardcell = {},
}

function playerback.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("mowangzailin/mowangzailin_reward", nil, true, "mowangzailin_reward")

    self.touchPriority = touchPriority

    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("playerback")
    end, CCControlEventTouchUpInside)

    UIRequest({type = 6811})

    return self.rootNode
end

function playerback.reload(self,data,callback)

    self.data = data.playerback or {}

    if not (self.data.status and self.data.status > 0) then
        --runGamePrompt({msg = "活动已结束"})
        gameWindows:closeWindowDirect("playerback")
        return
    end 

    ui.setLabelString(self.rootItems.doLab,"领 取",19)
    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:setTouchPriority(self.touchPriority)
    self.rootItems.doButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        if self.data.rewardstatus and self.data.rewardstatus > 0 then
            runGamePrompt({msg = "今日已领取"})
        else    
            UIRequest({type = 6812})
        end
    end, CCControlEventTouchUpInside)
    --
    if self.data.rewardstatus and self.data.rewardstatus > 0 then
        ui.addGray("CCControlButton",self.rootItems.doButton)
    else    
        ui.removeGray("CCControlButton",self.rootItems.doButton)
    end
    --

    local dayconfig = gamedata.config.lord_again[tostring(self.data.backday)][tostring(self.data.backlevel)] or {}
    for i = 1,7 do
        if dayconfig["reward"..i] then
            self.rootItems["reward"..i]:setVisible(true)
            local reward = ui.getIDandNUMs(dayconfig["reward"..i])
            --
            self.rootItems["showbutton"..((i>1) and ("_"..(i-1)) or "")]:setSwallowsTouch(true)
            self.rootItems["showbutton"..((i>1) and ("_"..(i-1)) or "")]:setTouchPriority(self.touchPriority)
            self.rootItems["showbutton"..((i>1) and ("_"..(i-1)) or "")]:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(0.5)
                gameWindows:openWindow("getStaff",{data = reward,type = "礼包"},nil)
            end, CCControlEventTouchUpInside)
            --
            if self.data.reward and self.data.reward[tostring(i)] and self.data.reward[tostring(i)] > 0 then
                setSpriteFrameByName(self.rootItems["boxicon1"..((i>1) and ("_"..(i-1)) or "")],"huiguibox"..i.."_1")
                setSpriteFrameByName(self.rootItems["boxicon2"..((i>1) and ("_"..(i-1)) or "")],"huiguibox"..i.."_1")
            else
                setSpriteFrameByName(self.rootItems["boxicon1"..((i>1) and ("_"..(i-1)) or "")],"huiguibox"..i.."_0")
                setSpriteFrameByName(self.rootItems["boxicon2"..((i>1) and ("_"..(i-1)) or "")],"huiguibox"..i.."_0")
            end 
            --
            if self.data.rewardstatus and (self.data.rewardstatus == 0) and self.data.rewardday and (self.data.rewardday+1 == i) then
                self.rootItems["effect1"..((i>1) and ("_"..(i-1)) or "")]:setVisible(true)
                self.rootItems["effect2"..((i>1) and ("_"..(i-1)) or "")]:setVisible(true)
            else
                self.rootItems["effect1"..((i>1) and ("_"..(i-1)) or "")]:setVisible(false)
                self.rootItems["effect2"..((i>1) and ("_"..(i-1)) or "")]:setVisible(false)
            end
        else
            self.rootItems["reward"..i]:setVisible(false)
        end    
    end    
    --
    if gameTimer.times["playerbackend"] and gameTimer.times["playerbackend"] > 0 then
        gameTimer:rigistTimeFunc("playerbackend",function()
            if gameTimer.times["playerbackend"] <= 0 then
                gameTimer:UnrigistTimeFunc("playerbackend")
                UIRequest({type = 6811})
            else
                ui.setLabelString(self.rootItems.time,"领奖结束倒计时:\n"..ui.makeTimeDayText(gameTimer.times["playerbackend"],"day2"),21)
            end
        end)
    end

end

function playerback.close(self)

    if gameTimer.times["playerbackend"] then
        gameTimer:UnrigistTimeFunc("playerbackend")
    end

    self.data = {}
    self.rewardcell = {}
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
        self.callback = nil
    end
end

return playerback