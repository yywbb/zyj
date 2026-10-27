--公会守卫

local socket = require("socket")

local guildguard = {

    rootNode = nil,
    rootItems = nil,
    buttontouch = -102,
    guardHpTab = {},
    boxStutas = {},
    totalScore  = 0,
    limitNum = 0,
    mouseappearTab = {  [1] = "gonghui2/cell_dishu_mowang",
                        [2] = "gonghui2/cell_dishu_mowangjin",
                        [3] = "gonghui2/cell_dishu_guowang",
                        [4] = "gonghui2/cell_dishu_box",
                        },
    animationTab = {    [1] = "xiaodishu",
                        [2] = "dadishu",
                        [3] = "ciwei",
                        },
    animationTabCtrl = {},
    hpnum = 0,
    mouseHoleTab = {},
    battleMouseStatus = {},

    scoreNum = 0,
    combEffectNode = nil,
    combEffectItem = nil,
    startEffectNode = nil, 
    startEffectItem = nil,
    scoreEffectNode = nil, 
    scoreEffectItem = nil,
    dabaojianEffectNode = nil, 
    dabaojianEffectItem = nil,

    playtimer = nil,
    mouseHoleData = {},
    data = nil,

    timeOpen = 0,

}

function guildguard.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("gonghui2/gonghui_shouwei", nil, true, "gonghui_shouwei")
    parent:addChild(self.rootNode)
    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.middleNode:setPositionY(toppos/2-170)
    self:initFixedString()

    --生命值
    self.hpnum = tonumber(gamedata.config.global_kv.guild_box_life.value)

    -- local nowtime = os.date("*t", gamedata:time())
    -- local daynums = (nowtime.wday == 1 and 7 or (nowtime.wday-1))
    -- local guildTimeConfig = gamedata.config.guild_time
    -- if guildTimeConfig[tostring(daynums)].open == 0 then
    --     self.timeOpen = 0
    -- elseif guildTimeConfig[tostring(daynums)].open == 1 then
    --     self.timeOpen = 1
    -- end
    -- print("self.timeOpen  ---  ",self.timeOpen)

    -- if self.timeOpen == 1 then
    --     ui.removeGray("CCControlButton",self.rootItems.recordBtn)
    --     ui.removeGray("CCControlButton",self.rootItems.startBtn)
    --     self.rootItems.fixedTimeStr:setVisible(false)
    --     self.rootItems.limitTimeNode:setVisible(true)
    -- else
    --     ui.addGray("CCControlButton",self.rootItems.recordBtn)
    --     ui.addGray("CCControlButton",self.rootItems.startBtn)
    --     self.rootItems.fixedTimeStr:setVisible(true)
    --     self.rootItems.limitTimeNode:setVisible(false)
    -- end
    local guildTimeConfig = gamedata.config.guild_time

    ui.setLabelString(self.rootItems.fixedTimeStr,guildTimeConfig[tostring(1)].desc,14)

    --返回
    self.rootItems.backBtn:setTouchPriority(self.buttontouch)
    self.rootItems.backBtn:setSwallowsTouch(true)
    self.rootItems.backBtn:addHandleOfControlEvent(function()
        print("backbutton=")    
        gamedata.music:PlayOptSound("tuichu")
        UIRequest({type = 2230,param = "main"})
        
    end, CCControlEventTouchUpInside)

    --排行榜
    self.rootItems.rankBtn:setTouchPriority(self.buttontouch)
    self.rootItems.rankBtn:setSwallowsTouch(true)
    self.rootItems.rankBtn:addHandleOfControlEvent(function()
        --UIRequest({type = 5155,id =1})
        GameScene:shiftLayer("guardRank","up")
    end, CCControlEventTouchUpInside)

    --说明
    self.rootItems.ruleBtn:setTouchPriority(self.buttontouch)
    self.rootItems.ruleBtn:setSwallowsTouch(true)
    self.rootItems.ruleBtn:addHandleOfControlEvent(function()
        gameWindows:openWindow("guard_rule",nil, nil)
    end, CCControlEventTouchUpInside)

    --开始
    self.rootItems.startBtn:setTouchPriority(self.buttontouch)
    self.rootItems.startBtn:setSwallowsTouch(true)
    self.rootItems.startBtn:addHandleOfControlEvent(function()

        if self.timeOpen == 1 then
            if not gameTimer.times["guard_ready"] and not self.playtimer then
                if self.limitNum > 0 then
                    UIRequest({type = 5151,id = 0})
                else
                    runGamePrompt({msg = gameConfig.strings:string_common("guild_guard",2)})
                end
            else
                print("1111-----   ")
                --runGamePrompt({msg = "当前不可点击"})
            end
        else
            runGamePrompt({msg = guildTimeConfig[tostring(1)].desc})
        end

    end, CCControlEventTouchUpInside)

    local costcid,costgold = ui.getIDandNUM(gamedata.config.global_kv.guide_consume.value)
    local vipLv = 1
    for i = 1, table.getTableLength(gamedata.config.vip)-1 do
        if gamedata.config.vip[tostring(i)] and gamedata.config.vip[tostring(i)].guild_start and gamedata.config.vip[tostring(i)].guild_start == 0 then
            vipLv = vipLv + 1
        end
    end

    
    if gamedata.config.vip[tostring(GameScene.roleinfo.vip)].guild_start == 1 then
        self.rootItems.recordCostNode:setVisible(false)

        if gameConfig:checkBuildOpen(165) then
            ui.setLabelString(self.rootItems.vipfreeLab,"",14)
        else
            ui.setLabelString(self.rootItems.vipfreeLab,gameConfig.strings:guildvipLv(vipLv),14)
        end
        ui.setLabelString(self.rootItems.vipfreeLab2,gameConfig.strings:string_common("guild_guard",16),14)
    else
        self.rootItems.recordCostNode:setVisible(true)
        --self.rootItems.costGolenumLab:setString(costgold)
        ui.setLabelString(self.rootItems.costGolenumLab,costgold,14)
        ui.setLabelString(self.rootItems.vipfreeLab,"",14)
        ui.setLabelString(self.rootItems.vipfreeLab2,"",14)
    end


    self.rootItems["dabaojianEffectNode"]:setVisible(false)
    self.dabaojianEffectNode, self.dabaojianEffectItem = CCBReaderLoad("UIEffect/dadishu/dabaojian_false", nil, true, "dabaojian_false")
    self.rootItems["dabaojianEffectNode"]:addChild(self.dabaojianEffectNode)
    self.dabaojianAnimationManager = getAnimationManager(self.dabaojianEffectItem)


    --记录开始
    self.rootItems.recordBtn:setTouchPriority(self.buttontouch)
    self.rootItems.recordBtn:setSwallowsTouch(true)
    self.rootItems.recordBtn:addHandleOfControlEvent(function()
        if self.timeOpen == 1 then
            if not gameTimer.times["guard_ready"] and not self.playtimer then
                if self.limitNum > 0 then
                    if gamedata.config.vip[tostring(GameScene.roleinfo.vip)].guild_start == 1 then
                        UIRequest({type = 5151,id = 1})
                    else
                        UIRequest({type = 5151,id = 1,gold = costgold })
                    end
                else
                    runGamePrompt({msg = gameConfig.strings:string_common("guild_guard",2)})
                end
            end
        else
            runGamePrompt({msg = guildTimeConfig[tostring(1)].desc})
        end

    end, CCControlEventTouchUpInside)

    --生命
    for i=1,self.hpnum do
        self.guardHpTab["hpCcb"..i],self.guardHpTab["hpItem"..i] = CCBReaderLoad("gonghui2/cell_xin.ccbi", nil, true, "cell_xin")
        self.guardHpTab["hpAnimation"..i] = getAnimationManager(self.guardHpTab["hpItem"..i])
        self.rootItems["hpNode"..i]:addChild(self.guardHpTab["hpCcb"..i])
    end

    self.rootItems["r_button"]:setSwallowsTouch(true)
    self.rootItems["r_button"]:setTouchPriority(self.buttontouch)
    self.rootItems["r_button"]:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            gameWindows:openWindow("guardrewardview",self.data,nil)
    end, CCControlEventTouchUpInside)


    -- 打地鼠
    for i=1,9 do
        self.rootItems["mouseBtn"..i]:setTouchPriority(self.buttontouch)
        self.rootItems["mouseBtn"..i]:setSwallowsTouch(true)
        self.rootItems["mouseBtn"..i]:addHandleOfControlEvent(function()
            --self.battleMouseStatus[i] = 0
            if self.mouseHoleData[i] then
                self.mouseHoleTab["animationManager"..i]:setAnimationCompletedCallback(function()
                    if self.mouseHoleTab["effectNode"..i] then
                        self.mouseHoleTab["effectNode"..i]:removeFromParentAndCleanup(true)
                        self.mouseHoleTab["effectNode"..i] = nil
                        -- self.mouseHoleTab["items"..i].animationNode:removeAllChildrenWithCleanup(true)
                        -- self.mouseHoleTab["items"..i].animationNode = nil
                        self.mouseHoleTab["items"..i] = nil
                        self.mouseHoleTab["animationManager"..i] = nil
                        if self.animationTabCtrl and self.mouseHoleData and self.mouseHoleData[i] and self.mouseHoleData[i].id and self.animationTabCtrl[self.mouseHoleData[i].id] then
                            self.animationTabCtrl[self.mouseHoleData[i].id] = nil
                        end
                        self.mouseHoleData[i] = nil
                        self.battleMouseStatus[i] = 1
                    end
                end)

                if self.mouseHoleData[i].id and (self.mouseHoleData[i].id ==1 or self.mouseHoleData[i].id ==2) then
                    local scoreconfig = gamedata.config.guild_integral
                    local maxbattleNum = tonumber(gamedata.config.global_kv.guide_even_up.value)
                    local curretScore = 0
                    local rewardidx=(self.battleNum and self.battleNum+1) or 1
                    if tonumber(rewardidx)>maxbattleNum then
                        rewardidx = maxbattleNum
                    end
                    curretScore = scoreconfig[tostring(self.mouseHoleData[i].id)]["second"..rewardidx]
                    if self.mouseHoleTab["items"..i] and self.mouseHoleTab["items"..i].curretScoreLab then
                        self.mouseHoleTab["items"..i].curretScoreLab:setString("+"..curretScore)
                    end
                end

                if self.animationTabCtrl[self.mouseHoleData[i].id] then
                    print("  22222   "..self.mouseHoleData[i].id)
                    self.animationTabCtrl[self.mouseHoleData[i].id]:setAnimation("aizou",true,0)
                end

                self.mouseHoleTab["animationManager"..i]:runAnimationsForSequenceNamed("aizou")

                local battleEffectCCb,battleEffectItem = CCBReaderLoad("UIEffect/dadishu/dabaojian_attck".. math.random(1,3) ..".ccbi", nil, true, "dabaojian")
                self.rootItems["battleEffectNode"..i]:addChild(battleEffectCCb)
                local battleAnimation = getAnimationManager(battleEffectItem)
                battleAnimation:setAnimationCompletedCallback(function()
                    print("complete")
                    battleEffectCCb:removeAllChildrenWithCleanup(true)
                    battleEffectCCb:removeFromParentAndCleanup(true)
                    battleEffectCCb = nil
                    battleEffectItem = nil
                end)
                battleAnimation:runAnimationsForSequenceNamed("Default Timeline")
                UIRequest({type = 5153, point = i,status = 1})
            end
        end, CCControlEventTouchUpInside)

    end
    UIRequest({type = 5150})

end

function guildguard.readyStart(self,data)
    self.scoreNum = data.score
    --self.rootItems.attackSpr:setVisible(false)

    self.rootItems.startscoreNode:setVisible(true)
    self.rootItems.bottomNode:setVisible(false)
    self.rootItems.combNumNode:setVisible(true)


    if self.combEffectNode then
        --self.combEffectNode:removeFromParentAndCleanup(true)
        self.rootItems["combNumNode"]:removeAllChildrenWithCleanup(true)
        self.combEffectNode = nil
    end
    self.combEffectNode, self.combEffectItem = CCBReaderLoad("gonghui2/gonghui_shouweicomb", nil, true, "gonghui_shouweicomb")
    self.rootItems["combNumNode"]:addChild(self.combEffectNode)
    self.combEffectAnimationManager = getAnimationManager(self.combEffectItem)
    self.rootItems.combNumNode:setVisible(false)

    local timenum = 4
    gameTimer:rigistTime("guard_ready", timenum)

    if self.startEffectNode then
        --self.startEffectNode:removeFromParentAndCleanup(true)
        self.rootItems["startEffectNode"]:removeAllChildrenWithCleanup(true)
        self.startEffectNode = nil
    end
    self.startEffectNode, self.startEffectItem = CCBReaderLoad("gonghui2/gonghui_shouweistart", nil, true, "gonghui_shouweistart")
    self.rootItems["startEffectNode"]:addChild(self.startEffectNode)
    self.startEffectAnimationManager = getAnimationManager(self.startEffectItem)
    self.startEffectAnimationManager:runAnimationsForSequenceNamed("Default Timeline")

    if self.scoreEffectNode then
        --self.scoreEffectNode:removeFromParentAndCleanup(true)
        self.rootItems["startscoreNode"]:removeAllChildrenWithCleanup(true)
        self.scoreEffectNode = nil
    end
    self.scoreEffectNode, self.scoreEffectItem = CCBReaderLoad("gonghui2/gonghui_shouweidangqianfenshu", nil, true, "gonghui_shouweidangqianfenshu")
    self.rootItems["startscoreNode"]:addChild(self.scoreEffectNode)
    self.scoreEffectAnimationManager = getAnimationManager(self.scoreEffectItem)
    self.scoreEffectAnimationManager:runAnimationsForSequenceNamed("Default Timeline")
    self.scoreEffectItem.ScoreLab:setString(self.scoreNum)

    gameTimer:rigistTimeFunc("guard_ready",function()
        if gameTimer.times["guard_ready"] > 0 then
            
        end
        if gameTimer.times["guard_ready"] == 0 then

            gameTimer:UnrigistTimeFunc("guard_ready")
            gameTimer.times["guard_ready"] = nil

            --开始游戏
            self.timenow = socket:gettime()
            self.playinterval = 0
            self.isAppear = 0
            self.playtimer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
                if socket:gettime()-self.timenow >self.playinterval then
                    if self.hpnum > 0 and self.isAppear == 0 then
                        UIRequest({type = 5152})
                    end
                    self.timenow = socket:gettime()
                    self.playinterval = self:getGuardInterval(self.scoreNum)
                end
            end, 0, false)
        end
    end)
end

function guildguard.getMouseData( self,data )
    printT(data,"getMouseData  --- ")
    
    --传入地鼠洞的状态
    self.isAppear = 1
    self.mouseHoleData = {}
    local mouseNum = data.mouseNum or 0
    local mouseTab = data.mouseTab or {}
    if mouseTab and next(mouseTab) then
        for k,v in pairs(mouseTab) do 
            self.mouseHoleData[v.point] = {}
            self.mouseHoleData[v.point].point = point
            self.mouseHoleData[v.point].id = v.id

            local i=v.point
            if self.mouseHoleTab["effectNode"..i] then
                self.mouseHoleTab["effectNode"..i]:removeFromParentAndCleanup(true)
                self.mouseHoleTab["effectNode"..i] = nil
                -- self.mouseHoleTab["items"..i].animationNode:removeAllChildrenWithCleanup(true)
                -- self.mouseHoleTab["items"..i].animationNode = nil
                self.mouseHoleTab["items"..i] = nil
                self.mouseHoleTab["animationManager"..i] = nil
                self.rootItems["mouseNode"..i]:stopAllActions()
            end
            -- print(" ---  "..self.mouseappearTab[self.mouseHoleData[i].id])
            self.mouseHoleTab["effectNode"..i], self.mouseHoleTab["items"..i] = CCBReaderLoad(self.mouseappearTab[self.mouseHoleData[i].id], nil, true, "dishueffect"..self.mouseHoleData[i].id)

            local generalName = self.animationTab[self.mouseHoleData[i].id]
            if generalName then
                if self.animationTabCtrl[self.mouseHoleData[i].id] then
                    self.animationTabCtrl[self.mouseHoleData[i].id] = nil
                end
                -- print("  generalName  "..generalName)
                local Gneral1 = ui.itemcache:loadSkeleton(generalName)
                Gneral1:setAnimation("stand",true,0)
                Gneral1:setScale(1)
                Gneral1:setPosition(0,0)
                self.animationTabCtrl[self.mouseHoleData[i].id] = Gneral1
                self.mouseHoleTab["items"..i].animationNode:addChild(Gneral1.root or Gneral1)
            end
            self.rootItems["mouseNode"..i]:addChild(self.mouseHoleTab["effectNode"..i])
            self.mouseHoleTab["animationManager"..i] = getAnimationManager(self.mouseHoleTab["items"..i])
            self.mouseHoleTab["animationManager"..i]:runAnimationsForSequenceNamed("chuxian")

            self.rootItems["mouseNode"..i]:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(self:getGuardSpeed(self.scoreNum)), CCCallFunc:create(function()
                if self.battleMouseStatus[i] and self.battleMouseStatus[i] == 1 then
                    self.battleMouseStatus[i] = 0
                    if self.mouseHoleTab["effectNode"..i] then
                        self.mouseHoleTab["effectNode"..i]:removeFromParentAndCleanup(true)
                        self.mouseHoleTab["effectNode"..i] = nil
                        self.mouseHoleTab["items"..i] = nil
                        self.mouseHoleTab["animationManager"..i] = nil
                    end
                else

                    self.mouseHoleTab["animationManager"..i]:runAnimationsForSequenceNamed("likai")
                    self.mouseHoleTab["effectNode"..i]:removeFromParentAndCleanup(true)
                    self.mouseHoleTab["effectNode"..i] = nil
                    self.mouseHoleTab["items"..i] = nil
                    self.mouseHoleTab["animationManager"..i] = nil
                    self.battleMouseStatus[i] = 0
                    self.mouseHoleData[i] = nil
                    UIRequest({type = 5153, point = i,status = 0})
                end
            end)))
        end
    end
end

function guildguard.getGuardLv( self,data )
    local guardLv = 0
    local config = gamedata.config.guild_play
    self.maxguardLvnum = self.maxguardLvnum or table.getTableLength(config)
    for i=1,self.maxguardLvnum do
        if config[tostring(i)].lower <= data and data >= config[tostring(i)].lower then
            guardLv = i
        end
    end
    return guardLv
end

function guildguard.getGuardInterval( self,data )
    local guardLv = self:getGuardLv(data)
    local config = gamedata.config.guild_play
    return ((config[tostring(guardLv)].interval)/100)
end

function guildguard.getGuardSpeed(self,data)
    local guardLv = self:getGuardLv(data)
    return (gamedata.config.guild_play[tostring(guardLv)].speed/100-0.2)
end

function guildguard.catchMouseData(self,data)
    printT(data,"catchMouseData  --- ")
    local hpnum2 = 0
    self.isAppear = 0
    --local combNum = 0
    if data.status == 0 then
        hpnum2 = data.mouseData.hp or 0
        self.scoreNum = self.scoreNum + data.mouseData.score
        self.powerSatus = data.mouseData.powerSatus or 0
        self.battleNum = data.mouseData.battleNum or 0


    else
        return
    end


    if self.battleNum and self.battleNum == 2 then
        self.rootItems.combNumNode:setVisible(true)
        self.combEffectAnimationManager:runAnimationsForSequenceNamed("comb")
        self.combEffectItem.combnum:setString(self.battleNum)
    elseif self.battleNum and self.battleNum > 2 then
        self.rootItems.combNumNode:setVisible(true)
        self.combEffectAnimationManager:runAnimationsForSequenceNamed("comb02")
        self.combEffectItem.combnum:setString(self.battleNum)
    elseif self.battleNum and self.battleNum == 0 then
        self.rootItems.combNumNode:setVisible(false)
        --self.combEffectAnimationManager:runAnimationsForSequenceNamed("comb03") 
    end

    print("self.scoreNum   ---  ",self.scoreNum)
    self.scoreEffectItem.ScoreLab:setString(self.scoreNum)

    if self.hpnum ~= hpnum2 then
        if self.hpnum > hpnum2 then
            self.rootItems["dabaojianEffectNode"]:setVisible(true)
            self.dabaojianAnimationManager:runAnimationsForSequenceNamed("Default Timeline")
        end
        self.hpnum = hpnum2
        self.guardHpTab["hpAnimation"..(self.hpnum+1)]:runAnimationsForSequenceNamed("posui")
    end

    if self.hpnum == 0 then
        UIRequest({ type = 5156 ,highScore = self.highScore})
    end

end

function guildguard.reloaddata(self,data)
    print("reloaddata===")
    printT(data)

    local nowtime = os.date("*t", gamedata:time())
    local daynums = (nowtime.wday == 1 and 7 or (nowtime.wday-1))
    local guildTimeConfig = gamedata.config.guild_time
    if guildTimeConfig[tostring(daynums)].open == 0 then
        self.timeOpen = 0
    elseif guildTimeConfig[tostring(daynums)].open == 1 then
        self.timeOpen = 1
    end
    print("self.timeOpen  ---  ",self.timeOpen)

    if self.timeOpen == 1 then
        ui.removeGray("CCControlButton",self.rootItems.recordBtn)
        ui.removeGray("CCControlButton",self.rootItems.startBtn)
        self.rootItems.fixedTimeStr:setVisible(false)
        self.rootItems.limitTimeNode:setVisible(true)
    else
        ui.addGray("CCControlButton",self.rootItems.recordBtn)
        ui.addGray("CCControlButton",self.rootItems.startBtn)
        self.rootItems.fixedTimeStr:setVisible(true)
        self.rootItems.limitTimeNode:setVisible(false)
    end



    self.rootItems.startscoreNode:setVisible(false)
    self.rootItems.bottomNode:setVisible(true)
    self.rootItems.combNumNode:setVisible(false)

    if not data then
        return
    end

    if self.playtimer then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.playtimer)
        self.playtimer = nil
        self.hpnum = tonumber(gamedata.config.global_kv.guild_box_life.value)
        for i=1,self.hpnum do
            self.guardHpTab["hpAnimation"..i]:runAnimationsForSequenceNamed("youxin")
        end
    end

    self.data = data
    self.boxStutas = data and data.boxstatus or {}
    self.totalScore = data and data.totalScore or 0
    self.highScore = data.highScore or 0

    local hashint = false
    for k,v in pairs(self.boxStutas) do
        if v == 1 then
            hashint = true
        end
    end
    ui.sethint(self.rootItems.hint_boxNode,hashint)

    
    ui.setLabelString(self.rootItems.fixedStr4,gameConfig.strings:string_common("guild_guard",4),11)
    ui.setLabelString(self.rootItems.hightScoreLab,data.highScore,11)
    ui.setLabelString(self.rootItems.currentScoreLab,self.totalScore,14)
    self.limitNum = tonumber(gamedata.config.gang2_level[tostring(data.guildLv)].topy) - tonumber(data.gametime)
    print("::self.limitNum:::"..self.limitNum)
    ui.setLabelString(self.rootItems.limitNumLab,self.limitNum,21)


end

function guildguard.clear(self)

    if gameTimer.times["guard_ready"] then
        gameTimer:UnrigistTimeFunc("guard_ready")
        gameTimer.times["guard_ready"] = nil
    end

    if self.playtimer then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.playtimer)
        self.playtimer = nil
    end

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.buttontouch = -1
    self.guardHpTab = {}
    self.boxStutas = {}
    self.animationTabCtrl = {}
    self.totalScore  = 0
    self.battleMouseStatus = {}
    self.hpnum = 0
    self.scoreNum = 0
    self.mouseHoleTab = {}

    self.dabaojianEffectNode = nil
    self.dabaojianEffectItem = nil
    self.mouseHoleData = {}
    self.data = nil

end



function guildguard.UIUpdateData(self, isreset)
    if isreset then
        if self.playtimer then

        else
            UIRequest({type = 5150})
        end
    end
end

function guildguard.initFixedString( self )

    ui.setLabelString(self.rootItems.fixedStr1,gameConfig.strings:string_common("guild_guard",7),21)
    ui.setLabelString(self.rootItems.fixedStr2,gameConfig.strings:string_common("guild_guard",8),21)
    ui.setLabelString(self.rootItems.startLab,gameConfig.strings:string_common("guild_guard",9),19)
    ui.setLabelString(self.rootItems.recordLab,gameConfig.strings:string_common("guild_guard",10),19)
    ui.setLabelString(self.rootItems.fixedStr3,gameConfig.strings:string_common("guild_guard",11),14)

end

return guildguard �^  