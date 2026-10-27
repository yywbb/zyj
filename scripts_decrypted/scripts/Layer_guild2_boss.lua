
--

local guildboss = {

    resource = nil,

    rootNode = nil,
    rootItems = nil,

    buttontouch = -101,

    gangboss = {},
}

function guildboss.init(self,parent,toppos)
    self.rootNode,self.rootItems = CCBReaderLoad("gonghui2/gonghui_boss", nil, true, "gonghui_boss")
    parent:addChild(self.rootNode)

    self.topposy = toppos
    self.rootItems.topnode:setPositionY(toppos)

    --
    self.rootItems.bossnode:removeAllChildrenWithCleanup(true)
    self.long = nil
    self.long = CCSkeletonAnimation:create("jinyankongquelongwang1/jinyankongquelongwang1.json", "jinyankongquelongwang1/jinyankongquelongwang1.atlas", 1)
    self.long:setAnimation("stand",true,0)
    self.rootItems.bossnode:addChild(self.long)
    self.rootItems.bossnode:setScale(1.8)

    --
    ui.setLabelString(self.rootItems.reviveLab, gameConfig.strings:string_common("guild_boss",1),21)
    ui.setLabelString(self.rootItems.plusLab, gameConfig.strings:string_common("guild_boss",2),18)
    ui.setLabelString(self.rootItems.doLab, gameConfig.strings:string_common("guild_boss",3),19)
    ui.setLabelString(self.rootItems.inspireLab, gameConfig.strings:string_common("guild_boss",4),19)
    --

    self.rootItems.roleRankButton:setTouchPriority(-101)
    self.rootItems.roleRankButton:addHandleOfControlEvent(function()
        gameWindows:openWindow("gangrank2",nil)
    end, CCControlEventTouchUpInside)

    self.rootItems.rankButton:setTouchPriority(-101)
    self.rootItems.rankButton:addHandleOfControlEvent(function()
        GameScene:shiftLayer("gangbossrank","up")
    end, CCControlEventTouchUpInside)


    self.rootItems.addButton:setTouchPriority(-101)
    self.rootItems.addButton:addHandleOfControlEvent(function()
        GangBossBuyTimes()
    end, CCControlEventTouchUpInside)

    self.rootItems.backbutton:setTouchPriority(-101)
    self.rootItems.backbutton:addHandleOfControlEvent(function()
        UIRequest({type = 2230,param = "activity"})
    end, CCControlEventTouchUpInside)

    --
    self.rootItems.rulebutton:setTouchPriority(-101)
    self.rootItems.rulebutton:addHandleOfControlEvent(function()
        gameWindows:openWindow("gangbossRule",nil)
    end, CCControlEventTouchUpInside)

    --
    self:setSkipButton()
    UIRequest({type = 4840})
    --self:reloaddata()
end

function guildboss.setSkipButton(self)
    self.skipBattle = false
    local limit = gamedata.config.global_kv.worldboss_leapfrog_fighting and tonumber(gamedata.config.global_kv.worldboss_leapfrog_fighting.value) or 0
    if GameScene.roleinfo.level < limit then
        self.rootItems.skipBtnNode:setVisible(false)
        return
    end
    self.rootItems.skipBtnNode:setVisible(true)
    local guildId = GameScene.layers["gang_main"].module.gang and GameScene.layers["gang_main"].module.gang.id or 0
    local skipBattle = CCUserDefault:sharedUserDefault():getBoolForKey("guild_boss_skip_"..guildId)
    if skipBattle then
        self.skipBattle = true
    end
    self.rootItems.skipsprite:setVisible(self.skipBattle)
    self.rootItems.skipbutton:setTouchPriority(-101)
    self.rootItems.skipbutton:addHandleOfControlEvent(function()

        self.skipBattle = (not self.skipBattle)
        self.rootItems.skipsprite:setVisible(self.skipBattle)
        CCUserDefault:sharedUserDefault():setBoolForKey("guild_boss_skip_"..guildId,self.skipBattle)
    end, CCControlEventTouchUpInside)
end

function guildboss.battleCallback(self,t)
    local gangpoint = 0
    local index = 0
    t.reward = {}
    if t.n_reward and next(t.n_reward) then
        for k,v in pairs(t.n_reward) do
            if v.cid == 1006 then
                gangpoint = v.num
            else
                index = index+1
                t.reward[tostring(index)] = v
            end
        end
    end

    local callBackFunc = function()
        if gangpoint and gangpoint > 0 then
            runGamePrompt({msg = gameConfig.strings:string_common("guild_boss",15)..gangpoint})
        end
    end


    if not self.skipBattle then
        RunbattleCallBack("worldboss", t, callBackFunc)
    else
        if self.rootNode then
            self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.3), CCCallFunc:create(function()
                showRewardPopupWindow(t.reward,nil,callBackFunc)
            end)))
        end
    end
    
end

function guildboss.reloaddata(self,data)

    if data and data.gangboss then
        self.gangboss = data.gangboss or {}
    end

    local bossconfig = gamedata.config.gang2_boss and gamedata.config.gang2_boss[tostring(self.gangboss.id)] or {}
    --
    ui.setLabelString(self.rootItems.bossLv, "等级."..bossconfig.boss_level,21)
    if self.gangboss.hp > 0 then
        ui.setLabelString(self.rootItems.bossblood, self.gangboss.hp.." / "..bossconfig.hp,14)
        ui.setSpriteTextureRect2(self.rootItems.bossbloodbar,0,0,1008 * (self.gangboss.hp > bossconfig.hp and bossconfig.hp or self.gangboss.hp) / bossconfig.hp,41)
        self.rootItems.reviveNode:setVisible(false)
    else
        ui.setLabelString(self.rootItems.bossblood, "",14)
        ui.setSpriteTextureRect2(self.rootItems.bossbloodbar,0,0,0,41)
        self.rootItems.reviveNode:setVisible(true)
        --
        if self.gangboss.revive > 0 then
            gameTimer:rigistTime("gangbosstime", self.gangboss.revive+2)
            gameTimer:rigistTimeFunc("gangbosstime",function()
                if gameTimer.times["gangbosstime"] > 0 then
                    ui.setLabelString(self.rootItems.reviveTime,ui.makeTimeText(gameTimer.times["gangbosstime"],"hour"),14)
                else
                    UIRequest({type = 4840})
                    gameTimer:UnrigistTimeFunc("gangbosstime")
                end
            end)
        end
    end
    --
    ui.setLabelString(self.rootItems.plus,self.gangboss.plus..(self.gangboss.plus > 0 and "%" or "") ,21)

    --inspire
    local spendgold = 0
    --old gold method 
 --   local spend = ui.getIDandNUMs(gamedata.config.global_kv.sociaty_boss_consume.value)
  --  for k,v in pairs(spend) do
  --      if v.cid == 1001 then
   --         spendgold = v.num
   --     end
  --  end
    --new gold method 
    local encourageID = self.gangboss.inspire+1
    if encourageID > table.getTableLength(gamedata.config.gang2_boss_encouraging) then
        encourageID = table.getTableLength(gamedata.config.gang2_boss_encouraging)
    end

    local spend = ui.getIDandNUMs(gamedata.config.gang2_boss_encouraging[tostring(encourageID)].money)
    printT(spend)
    for k,v in pairs(spend) do
        if v.cid == 1001 then
           spendgold = v.num
        end
    end

    local needvip = 0
    for i = 1, table.getTableLength(gamedata.config.vip) do
        if gamedata.config.vip[tostring(i)] and gamedata.config.vip[tostring(i)].vip_inspire and tonumber(gamedata.config.vip[tostring(i)].vip_inspire) > 0 then
            needvip = i
            break
        end
    end
    --
    --local maxinspire = gamedata.config.global_kv.sociaty_boss_inspire and tonumber(gamedata.config.global_kv.sociaty_boss_inspire.value) or 0
    local maxinspire = table.getTableLength(gamedata.config.gang2_boss_encouraging)
    if GameScene.roleinfo.vip >= needvip then
        ui.setLabelString(self.rootItems.inspireNum,gameConfig.strings:string_common("guild_boss",7)..(self.gangboss.inspire > maxinspire and 0 or maxinspire-self.gangboss.inspire).."/"..maxinspire,14)
        ui.setLabelString(self.rootItems.spendgold,spendgold,18)
        --
        if self.gangboss.inspire >= maxinspire then
            ui.addGray("CCControlButton",self.rootItems.inspireButton)
            self.rootItems.spendNode:setVisible(false)
            self.rootItems.inspireButton:setTouchPriority(-101)
            self.rootItems.inspireButton:addHandleOfControlEvent(function()
                runGamePrompt({msg = gameConfig.strings:string_common("guild_boss",8)})
            end, CCControlEventTouchUpInside)
        else
            ui.removeGray("CCControlButton",self.rootItems.inspireButton)
            self.rootItems.spendNode:setVisible(true)
            self.rootItems.inspireButton:setTouchPriority(-101)
            self.rootItems.inspireButton:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(1)
                UIRequest({type = 4843,xgold = spendgold or 0})
            end, CCControlEventTouchUpInside)
        end
    else
        self.rootItems.spendNode:setVisible(false)
        ui.addGray("CCControlButton",self.rootItems.inspireButton)
        ui.setLabelString(self.rootItems.inspireNum,"",14)
        --
        self.rootItems.inspireButton:setTouchPriority(-101)
        self.rootItems.inspireButton:addHandleOfControlEvent(function()
            runGamePrompt({msg = gameConfig.strings:string_common("guild_boss",6)..needvip})
        end, CCControlEventTouchUpInside)
    end
    --

    --
    ui.setLabelString(self.rootItems.challenge,gameConfig.strings:string_common("guild_boss",9)..self.gangboss.challenge,18)

    if self.gangboss.hp <= 0 then
        ui.addGray("CCControlButton",self.rootItems.doButton)
        --
        self.rootItems.doButton:setTouchPriority(-101)
        self.rootItems.doButton:addHandleOfControlEvent(function()
            runGamePrompt({msg = gameConfig.strings:string_common("guild_boss",10)})
        end, CCControlEventTouchUpInside)
    elseif self.gangboss.challenge <= 0 then
        ui.addGray("CCControlButton",self.rootItems.doButton)
        --
        self.rootItems.doButton:setTouchPriority(-101)
        self.rootItems.doButton:addHandleOfControlEvent(function()
            runGamePrompt({msg = gameConfig.strings:string_common("guild_boss",11)})
        end, CCControlEventTouchUpInside)
    else
        ui.removeGray("CCControlButton",self.rootItems.doButton)
        --
        self.rootItems.doButton:setTouchPriority(-101)
        self.rootItems.doButton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1.5)
            UIRequest({type = 4844})
        end, CCControlEventTouchUpInside)
    end

    --
    local award = bossconfig.awards or 0
    if gamedata.config.worlddrop and gamedata.config.worlddrop[tostring(award)] then
        local drops = ui.getIDRandNums(gamedata.config.worlddrop[tostring(award)].drop)
        local rewards = {}
        for k,v in ipairs(drops) do
            table.insert(rewards,{cid = v[1],num = v[2]})
        end
        self.rootItems.rewardButton:setTouchPriority(-101)
        self.rootItems.rewardButton:addHandleOfControlEvent(function()
            gameWindows:openWindow("getStaff",{data = rewards, type = gameConfig.strings:string_common("layer_copy",3)},nil)
        end, CCControlEventTouchUpInside)
    end
end

function guildboss.setNotify(self,data)

    local ccbconfig = {
        [0] = "attck"..math.random(1,7),
    }

    local ccb,item = CCBReaderLoad("worldboss2/"..ccbconfig[0]..".ccbi", nil, true, ccbconfig[0])
    ccb:setPosition(ccp(math.random(1,400),math.random(1,400)))
    ccb:setScale(1.5)
    self.rootItems.damagenode:addChild(ccb)
    item.damage:setString(data.damage)
    ui.setLabelString(item.name,data.name,1)

    local animationManager = getAnimationManager(item)
    animationManager:setAnimationCompletedCallback(function()
        ccb:removeFromParentAndCleanup(true)
    end)
    animationManager:runAnimationsForSequenceNamed("Default Timeline")

    local red = CCTintTo:create(0.2,255,0,0)
    local back = CCTintTo:create(0.3,255,255,255)
    local sq = CCSequence:createWithTwoActions(red,back)
    self.long:runAction(sq)

    if data.status and data.status == 0 then
        UIRequest({type = 4840})
    else
        local bossconfig = gamedata.config.gang2_boss and gamedata.config.gang2_boss[tostring(self.gangboss.id)] or {}
        ui.setLabelString(self.rootItems.bossblood, data.hp.." / "..bossconfig.hp,14)
        ui.setSpriteTextureRect2(self.rootItems.bossbloodbar,0,0,1008 * (data.hp > bossconfig.hp and bossconfig.hp or data.hp) / bossconfig.hp,41)
    end

end


function guildboss.clear(self)
    gameTimer:UnrigistTimeFunc("gangbosstime")
    self.long = nil
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function guildboss.UIUpdateData(self,isreset)
    if GameScene.layers["guildboss"].show then
        UIRequest({type = 4840})
    end
end

return guildboss
  �1  