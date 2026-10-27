--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/18
-- Time: 下午4:18
-- To change this template use File | Settings | File Templates.
--
local generalexp = {
    rootNode = nil,
    rootItems = nil,

    counttimers = {},
}


function generalexp.open(self,touchPriority,data,callback)
    self.root = CCNode:create()

    self.touchPriority = touchPriority
    self.data = data.data

    self.type = data.type
    self.awakenConfig = gamedata.config.general_awaken
    if data.type == "normal" then
        self.rootNode, self.rootItems = CCBReaderLoad("backGround/tc_huobanjingyan", nil, true, "tc_huobanjingyan")
        self:relaodExp(data,callback)
    elseif data.type == "wipe" then
        self.rootNode, self.rootItems = CCBReaderLoad("backGround/tc_huobanjingyanWipe", nil, true, "tc_huobanjingyanWipe")
        self:reloadReward(data,callback)
        self:relaodExp(data,callback)
    end
    self.root:addChild(self.rootNode)

    self.callback = callback

    -- ui.setLabelString(self.rootItems.confirmtext,"确 定",18)
    ui.setLabelString(self.rootItems.confirmtext,gameConfig.strings:string_common("popups","queding"),18)
    self.rootItems.confirm:addHandleOfControlEvent(function()
        for k,v in pairs(self.counttimers) do
            CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(v)
        end
        gameWindows:closeWindow("generalexp")
        if self.type == "wipe" then
            GameScene:coin_effect(1,540,600,0.5)
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.confirm:setSwallowsTouch(true)
    self.rootItems.confirm:setTouchPriority(self.touchPriority)

    return self.root
end

function generalexp.reloadReward(self,data,callback)
    
    local exp = self.data.exp
    self.rootItems.exp:setString(self.data.exp.rolegetexp)
    self.rootItems.coin:setString(self.data.coin)

    self.rootItems.barsprite:removeFromParentAndCleanup(false)

    self.rootItems.userexpbar = CCProgressTimer:create(self.rootItems.barsprite)
    self.rootItems.userexpbar:setAnchorPoint(ccp(0, 0.5))
    self.rootItems.userexpbar:setType(kCCProgressTimerTypeBar)
    self.rootItems.userexpbar:setMidpoint(ccp(0, 0.5))
    self.rootItems.userexpbar:setBarChangeRate(ccp(1, 0))
    self.rootItems.userexpbar:setPosition(ccp(-346, 0.5))

    self.rootItems["userexpnode"]:addChild(self.rootItems.userexpbar)

    self.rootItems.userexpbar:setPercentage(100*exp.oldexp/gamedata.config.role_exp[tostring(exp.oldlevel)].nextexp)
    ui.setLabelString(self.rootItems.userlv,"等级: "..exp.oldlevel,46)
    --ui.setLabelString(self.rootItems.userexp,exp.oldlevel,14)


    local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(1), CCCallFunc:create(function()
        if exp.newlevel == exp.oldlevel then
            local ProgressFromTo = CCProgressFromTo:create(0.4,
                100*exp.oldexp/gamedata.config.role_exp[tostring(exp.oldlevel)].nextexp,
                100*exp.newexp/gamedata.config.role_exp[tostring(exp.newlevel)].nextexp)
            self.rootItems.userexpbar:runAction(ProgressFromTo)
        else
            local ProgressFromTo1 = CCProgressFromTo:create(0.4,
                100*exp.oldexp/gamedata.config.role_exp[tostring(exp.oldlevel)].nextexp,
                100)
            local cb = function()
                ui.setLabelString(self.rootItems.userlv,"等级: "..exp.newlevel,46)
                local ProgressFromTo2 = CCProgressFromTo:create(0.4,
                    0,
                    100*exp.newexp/gamedata.config.role_exp[tostring(exp.newlevel)].nextexp)
                self.rootItems.userexpbar:runAction(ProgressFromTo2)
            end
            self.rootItems.userexpbar:runAction(CCSequence:createWithTwoActions(ProgressFromTo1,CCCallFunc:create(cb)))
        end
    end))

    self.root:runAction(sequence)
end

function generalexp.relaodExp(self)
    local haslevelup = 0

    for i=1,7 do
        if self.data.slots[tostring(i)] and self.data.slots[tostring(i)].general and self.data.slots[tostring(i)].general ~= 0 then

            local config = gamedata.config:getConfigByName("general")[tostring(self.data.generalexp[tostring(i)].cid)]
            local expdata = self.data.generalexp[tostring(i)]
            local data = {
                quality = config.quality,
                icon = config.icon,
                name = config.name,
                exp = expdata.exp,
                level = expdata.level,
                level2 = expdata.level2,
                levelup = expdata.levelup,
                awakenicon = (config.awaken > 0 and expdata.skilllevel > 0 ) and   self.awakenConfig[tostring(expdata.skilllevel)].icon or nil,
                awakenstage = (config.awaken > 0 and expdata.skilllevel > 0 ) and  self.awakenConfig[tostring(expdata.skilllevel)].stage or nil,
                exchange =  self.data.exchange or 0
            }
            self.counttimers[i] = ui.setGeneralIconL(data,self.rootItems,i-1)
            if expdata.levelup and expdata.levelup == 1 then
                haslevelup = 1
            end
        else
            self.rootItems["general"..i]:setVisible(false)
        end
    end

    self.rootItems.confirm:setEnabled(false)
    local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(1), CCCallFunc:create(function()
        self.rootItems.confirm:setEnabled(true)
    end))
    self.rootItems.confirm:runAction(sequence)

    if haslevelup == 1 then
        gamedata.music:PlayOptSound("wjsj")
    end
end

function generalexp.close(self)
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil

    for k,v in pairs(self.counttimers) do
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(v)
    end
    self.counttimers = {}
    
    if self.callback then
        self.callback()
    end
end

return generalexp