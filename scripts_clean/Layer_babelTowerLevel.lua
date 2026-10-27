--
-- Author: songyibo
-- Date: 2019-03-22 10:38:12
--

local babelTowerLevel = {
    rootNode = nil,
    rootItems = nil,
    touchPriority = -102,
    levelIndex = 1,
}

function babelTowerLevel.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("tongtianta/tongtianta_challenge", nil, true, "tongtianta_challenge")

    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)

    if gameConfig.topposY > 1920 then
        self.rootItems.middleNode:setPositionY(880 + (gameConfig.topposY - 1920))
    else
        self.rootItems.middleNode:setPositionY(880)
    end
    -- self.rootItems["closeButton"]:setSwallowsTouch(true)
    -- self.rootItems["closeButton"]:setTouchPriority(self.touchPriority)
    -- self.rootItems["closeButton"]:addHandleOfControlEvent(function()
    --     GameScene:shiftLayerById(450)
    --     print("closeButton")
    -- end, CCControlEventTouchUpInside)
  	
  	self.rootItems["btnRule"]:setSwallowsTouch(true)
    self.rootItems["btnRule"]:setTouchPriority(self.touchPriority)
    self.rootItems["btnRule"]:addHandleOfControlEvent(function()
        gameWindows:openWindow("babelTowerRule")
        print("btnRule")
    end, CCControlEventTouchUpInside)

    self.rootItems["shop"]:setSwallowsTouch(true)
    self.rootItems["shop"]:setTouchPriority(self.touchPriority)
    self.rootItems["shop"]:addHandleOfControlEvent(function()
        GameScene:shiftLayerById(451)
        print("shop")
    end, CCControlEventTouchUpInside)

    self.rootItems["award"]:setSwallowsTouch(true)
    self.rootItems["award"]:setTouchPriority(self.touchPriority)
    self.rootItems["award"]:addHandleOfControlEvent(function()
        gameWindows:openWindow("babelTowerAward",self.mapData)
        print("award")
    end, CCControlEventTouchUpInside)
    
    self.rootItems["abovebutton"]:setSwallowsTouch(true)
    self.rootItems["abovebutton"]:setTouchPriority(self.touchPriority)
    self.rootItems["abovebutton"]:addHandleOfControlEvent(function()
        if self.levelIndex == 1 then
            runGamePrompt({msg = gameConfig.strings:string_common("babelTower",25)})
            return
        end
        self.levelIndex = self.levelIndex - 1
        self.levelIndex = math.max(self.levelIndex,1)
        self:refreshUI()
    end, CCControlEventTouchUpInside)

    self.rootItems["nextbutton"]:setSwallowsTouch(true)
    self.rootItems["nextbutton"]:setTouchPriority(self.touchPriority)
    self.rootItems["nextbutton"]:addHandleOfControlEvent(function()
        local maxLevel = table.getTableLength(gamedata.config.tongtianta_guaiwu[tostring(self.mapId)])
        if self.levelIndex == maxLevel then
            runGamePrompt({msg = gameConfig.strings:string_common("babelTower",26)})
            return
        end
        --本层通关
        if self.data[tostring(self.levelIndex)] and self.data[tostring(self.levelIndex)].passStatus1 == 1 and self.data[tostring(self.levelIndex)].dailyKillStatus == 1 then
            self:nextLevel()
        else
            runGamePrompt({msg = gameConfig.strings:string_common("babelTower",15)})
        end
        
    end, CCControlEventTouchUpInside)

    self.rootItems["battlebutton"]:setSwallowsTouch(true)
    self.rootItems["battlebutton"]:setTouchPriority(self.touchPriority)
    self.rootItems["battlebutton"]:addHandleOfControlEvent(function()
        if self.data[tostring(self.levelIndex)] and self.data[tostring(self.levelIndex)].challengeTime >= self.levelConfig.challenge then
            runGamePrompt({msg = gameConfig.strings:string_common("babelTower",18)})
        else
            UIRequest({type = 7013,levelId = self.levelIndex})
        end
    end, CCControlEventTouchUpInside)

    self.rootItems["endChallenge"]:setSwallowsTouch(true)
    self.rootItems["endChallenge"]:setTouchPriority(self.touchPriority)
    self.rootItems["endChallenge"]:addHandleOfControlEvent(function()

        local executeFunc = function (  )
            UIRequest({type = 7014})
            self.levelIndex = 1
        end
        gameWindows:openWindow("confirm",{msg = gameConfig.strings:string_common("babelTower",22)},executeFunc)

        
    end, CCControlEventTouchUpInside)


    self.rootItems["lookBtn"]:setSwallowsTouch(true)
    self.rootItems["lookBtn"]:setTouchPriority(self.touchPriority)
    self.rootItems["lookBtn"]:addHandleOfControlEvent(function()

        local data = self.data[tostring(self.levelIndex)]
        if not data then
            data = {
                passStatus1        = 0,
                autoBattleStatus   = 0,
                passStatus3        = 0,
                passStatus2        = 0,
                dailyKillStatus    = 0,
                challengeTime      = 0,
                firstKillStatus    = 0,
                level              = self.levelIndex,
                mapId              = self.mapId,
            }
        end
        gameWindows:openWindow("babelTowerLevelDetails",data)
    end, CCControlEventTouchUpInside)


    self:initFixedString()
    self:reload(param)
end

function babelTowerLevel.nextLevel(self)

    self.levelIndex = self.levelIndex + 1
    self.levelIndex = math.min(self.levelIndex,20)
    if not self.data[tostring(self.levelIndex)] then
        self.data[tostring(self.levelIndex)] = {
             passStatus1        = 0,
             autoBattleStatus   = 0,
             passStatus3        = 0,
             passStatus2        = 0,
             dailyKillStatus    = 0,
             challengeTime      = 0,
             firstKillStatus    = 0,
             level              = self.levelIndex,
             mapId              = self.mapId,
        }
    end

    self:refreshUI()
end

function babelTowerLevel.battleCallback(self,data)
    printT(data,"battleCallback")
    if data then
        if data.mapId then
            self.mapId = data.mapId
        end
        
        if data.data then
            self.data = data.data
        end

        if data.mapData then
            self.mapData = data.mapData
        end
    end
    local maxLevel = table.getTableLength(gamedata.config.tongtianta_guaiwu[tostring(self.mapId)])
    if ((self.data[tostring(self.levelIndex)].passStatus1 == 1 and self.data[tostring(self.levelIndex)].passStatus2 == 1 and self.data[tostring(self.levelIndex)].passStatus3 == 1) or (self.data[tostring(self.levelIndex)].challengeTime >= self.levelConfig.challenge and self.data[tostring(self.levelIndex)].passStatus1 == 1)) and self.levelIndex < maxLevel and self.data[tostring(self.levelIndex)].dailyKillStatus == 1 then


        local effectNode,effectItems = CCBReaderLoad("appear/appear", nil, true, "appear")
        self.rootItems.effectNode:addChild(effectNode)
        effectNode:setScale(3)
        local animationManager = getAnimationManager(effectItems)
        animationManager:setAnimationCompletedCallback(function()
            effectNode:removeFromParentAndCleanup(true)
        end)
        animationManager:runAnimationsForSequenceNamed("appear")

        gameTouch:clickprofbytime(0.5)
        self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.5), CCCallFunc:create(function()
                    self:nextLevel()
                end)))
        --三星通关并且没有挑战次数 自动跳转到下一关
        return
    end
    self:refreshUI()
end

function babelTowerLevel.reload(self,data)
    printT(data,"babelTowerLevel")
    if data then
        if data.mapId then
            self.mapId = data.mapId
        end
    	

        if data.data then
            self.data = data.data
        end

        if data.mapData then
            self.mapData = data.mapData
        end
    end
    
    self:refreshUI()
end

function babelTowerLevel.refreshUI(self)
    self.levelConfig = gamedata.config.tongtianta_guaiwu[tostring(self.mapId)][tostring(self.levelIndex)]

    local maxLevel = table.getTableLength(gamedata.config.tongtianta_guaiwu[tostring(self.mapId)])
    local levelData = self.data[tostring(self.levelIndex)]


    local conditionConfig = gamedata.config.tongtianta_tongguantiaojian

	for i=1,3 do
       local des = gameConfig.strings:babelTowerPassCondition(self.levelConfig["through_conditions"..i],self.levelConfig["attribute"..i],self.levelConfig["attribute"..i.."_"..i])
		self.rootItems["condition"..i]:setString(des)

        if levelData and levelData["passStatus"..i] == 1 then
            ui.removeGray("CCSprite", self.rootItems["xing"..i])
            self.rootItems["condition"..i]:setColor(ccc3(255,255,255))
        else
            ui.addGray("CCSprite", self.rootItems["xing"..i])
            self.rootItems["condition"..i]:setColor(ccc3(128,128,128))
        end
	end

    ui.setLabelString(self.rootItems.recommendPower,self.levelConfig.power,134)
    self.rootItems.g_power:setString(GameScene.roleinfo.g_power)
    if GameScene.roleinfo.g_power >= self.levelConfig.power then
        self.rootItems.g_power:setColor(ccc3(0,255,0))
    else
        self.rootItems.g_power:setColor(ccc3(255,0,0))
    end
    -- ui.setLabelString(self.rootItems.g_power,(GameScene.roleinfo.g_power or 0),134)

    if levelData then
        local canChallengeTime = self.levelConfig.challenge - levelData.challengeTime
        self.rootItems.challengeTime:setString(canChallengeTime)

        if canChallengeTime > 0 then
            self.rootItems.challengeTime:setColor(ccc3(255,255,255))
        else
            self.rootItems.challengeTime:setColor(ccc3(255,0,0))
        end
    else
        self.rootItems.challengeTime:setString(self.levelConfig.challenge)
    end
    
    self.rootItems.allTime:setString("/"..self.levelConfig.challenge)


    --人物形象
    self.rootItems.generalNode:removeAllChildrenWithCleanup(true)
    local generalConfig = ui.IDconfig(self.levelConfig.icon)
    self.rootItems.name:setString(self.levelConfig.name      )


    local generalName = gamedata.config.generalanimation[tostring(generalConfig.animationid)].name
    local Gneral1 = ui.itemcache:loadSkeleton(generalName)
    Gneral1:setScale(2)
    Gneral1:setPosition(0,0)
    self.rootItems.generalNode:addChild(Gneral1.root or Gneral1)

    if levelData and levelData.dailyKillStatus == 1 then
        --已三星通关
        self.rootItems.nonenode:setVisible(true)

        if Gneral1.root then
            ui.removeGray("CCNode",Gneral1.root)
        else
            ui.addGray("CCNode",Gneral1)
        end
        Gneral1:setAnimation("stand",false,0)
    else
        self.rootItems.nonenode:setVisible(false)
        Gneral1:setAnimation("stand",true,0)
    end

    --判断能不能扫荡
    local maxChallengeLevel = 1
    for i=1,maxLevel do
        local v = self.data[tostring(i)]
        if v then
            if v.dailyKillStatus == 1 then
                maxChallengeLevel = i
            else
                maxChallengeLevel = i
                break
            end
        else
            maxChallengeLevel = i
            break
        end
    end
    local auto = false
    if self.data[tostring(maxChallengeLevel)] and self.data["1"].autoBattleStatus == 0 and self.data[tostring(maxChallengeLevel)].passStatus1 == 1 and self.data[tostring(maxChallengeLevel)].passStatus2 == 1 and  self.data[tostring(maxChallengeLevel)].passStatus3 == 1 then
        if maxChallengeLevel == maxLevel then
            --最后一关已经打过 不显示自动扫荡
            if self.data[tostring(maxChallengeLevel)].dailyKillStatus == 0 then
                auto = true
            end
        else
            auto = true
        end
    end

    if auto then
        ui.removeGray("CCControlButton", self.rootItems["autobutton"])
    else
        ui.addGray("CCControlButton", self.rootItems["autobutton"])
    end

    self.rootItems["autobutton"]:setSwallowsTouch(true)
    self.rootItems["autobutton"]:setTouchPriority(self.touchPriority)
    self.rootItems["autobutton"]:addHandleOfControlEvent(function()
        if not auto then
            runGamePrompt({msg = gameConfig.strings:string_common("babelTower",17)})
        else
            gameTouch:clickprofbytime(0.3)
            UIRequest({type = 7016})
        end

        -- local reward = {
        --     ["1"] = {
        --     },
        --     ["2"] = {
        --     },
        --     ["3"] = {
        --     },
        --     ["4"] = {
        --     },
        --     ["5"] = {
        --     },
        --     ["6"] = {
        --     },
        --     ["7"] = {
        --     },
        --     ["8"] = {
        --     },
        --     ["9"] = {
        --     },
        --     ["10"] = {
        --     }
        -- }


        -- gameWindows:openWindow("babelTowerAutoBattle",reward)
    end, CCControlEventTouchUpInside)



    if self.data[tostring(self.levelIndex)] and self.data[tostring(self.levelIndex)].passStatus1 == 1 and self.data[tostring(self.levelIndex)].dailyKillStatus == 1 and self.levelIndex < maxLevel then
        ui.removeGray("CCControlButton", self.rootItems["nextbutton"])
    else
        ui.addGray("CCControlButton", self.rootItems["nextbutton"])
    end

    if self.levelIndex ~= 1 then
        ui.removeGray("CCControlButton", self.rootItems["abovebutton"])
    else
        ui.addGray("CCControlButton", self.rootItems["abovebutton"])
    end

    if self.data[tostring(self.levelIndex)] and self.data[tostring(self.levelIndex)].challengeTime >= self.levelConfig.challenge then
        ui.addGray("CCControlButton", self.rootItems["battlebutton"])
    else
        ui.removeGray("CCControlButton", self.rootItems["battlebutton"])
    end


    local hint = false
    for i=1,6 do
        if self.mapData["awardStatus"..i] == 1 then
            hint = true
            break
        end
    end

    if hint then
        self.rootItems.hit_award:setVisible(true)
    else
        self.rootItems.hit_award:setVisible(false)
    end

end

function babelTowerLevel.forcedExitLevel(self)
    local proflayer = ui.addProflayer(CCDirector:sharedDirector():getRunningScene(),gameConfig.touchPriority.loading,gameConfig.Zorder.loading,ccc4(0,0,0,100),nil,nil,nil,nil,"forcedExitLevel")
    local loadingLayer,loadingLayerItem = CCBReaderLoad("loading/confirm.ccbi", nil, true, "confirm")
    loadingLayer:setPosition(gamedata.device.SCREEN_WIDTH/2,gamedata.device.SCREEN_HEIGHT/2)
    loadingLayer:setScale(gameConfig.scaleNum)
    proflayer:addChild(loadingLayer)
    loadingLayerItem.closeButton:setVisible(false)

    ui.setLabelString(loadingLayerItem.des,gameConfig.strings:string_common("babelTower",23),47)

    ui.setLabelString(loadingLayerItem.confirmtext,"确 定",18)
    loadingLayerItem.confirm:addHandleOfControlEvent(function()
        proflayer:removeFromParentAndCleanup(true)
        self.levelIndex = 1
        GameScene:shiftLayerById(450)
    end, CCControlEventTouchUpInside)
    loadingLayerItem.confirm:setSwallowsTouch(true)
    loadingLayerItem.confirm:setTouchPriority(gameConfig.touchPriority.loading-1)
end

function babelTowerLevel.initFixedString(self)
end

function babelTowerLevel.clear(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    -- self.levelIndex = 1
end

return babelTowerLevel