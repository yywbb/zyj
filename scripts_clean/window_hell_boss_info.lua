hellBossInfo = {
	root = nil,
    rootNode = nil,
    rootItems = nil,
    touchPriority = -102,
    isCoolDown = true,
    data = nil
}

-- 打开界面
function hellBossInfo.open(self, touchPriority, data, callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority
    self.monsterConfig = gamedata.config.monster
    self.monsterBuffConfig = gamedata.config.hell_monsterBuff
    self.copyMonsterBuffConfig = gamedata.config.copy_monster
	self:initNode()
    self:initFixedString()
    self:initEvent(data.id)
    self:reloadData(data)

    return self.root
end

-- 初始化ccb
function hellBossInfo.initNode(self)
	self.rootNode, self.rootItems = CCBReaderLoad("copyhell/copyhell_guaiinfo", nil, true, "copyhell_guaiinfo")
    self.rootNode:setPosition(0, 0)
	self.root:addChild(self.rootNode)
end

-- 初始化文字
function hellBossInfo.initFixedString(self)
	ui.setLabelString(self.rootItems.titleTxt, gameConfig.strings:string_common("hell", 29), 69)
	ui.setLabelString(self.rootItems.bossBuffTxt, gameConfig.strings:string_common("hell", 30))
	ui.setLabelString(self.rootItems.bossRefreshTimeContentTxt, gameConfig.strings:string_common("hell", 31))
	ui.setLabelString(self.rootItems.challengeTxt, gameConfig.strings:string_common("hell", 6), 18)
end

-- 初始化点击事件
function hellBossInfo.initEvent(self, bossid)
	self:initCloseBtn()
	self:initChallengeBtn(bossid)
end

-- 初始化关闭按钮
function hellBossInfo.initCloseBtn(self)
    local _callback = function()
        gameWindows:closeWindow("hellBossInfo")
    end

    self:commonBtn("closeBtn", _callback)
end

-- 初始化关闭按钮
function hellBossInfo.initChallengeBtn(self, bossid)
    local _callback = function()
        UIRequest({type = 6112, param = bossid})
    end

    self:commonBtn("challengeBtn", _callback)
end

-- 初始化关闭按钮
function hellBossInfo.reloadData(self, data)
	self.data = data
	self:initBossInfo(self.data.boss)
	self.data.buffRefreshTime = gameTimer.times["hellBossBuff"] or 0
    self:bossBuffRfreshTime()
end

-- 初始化boss信息
function hellBossInfo.initBossInfo(self, bossData)
	local _bossid = self.monsterConfig[tostring(bossData.cid)].bossid
    local _bossCid = self.monsterConfig[tostring(bossData.cid)]["p".._bossid]
    local _buffName = self.monsterBuffConfig[tostring(bossData.buffCid)].desc
    local _buffValue = bossData.value

    -- if self.monsterBuffConfig[tostring(bossData.buffCid)].showMethod == 0 then
        if self.monsterBuffConfig[tostring(bossData.buffCid)].method == "value" then
            _buffValue = _buffValue / 100
        end
    -- elseif self.monsterBuffConfig[tostring(bossData.buffCid)].showMethod == 1 then
    --      _buffValue = _buffValue / 100
    -- end

    _buffValue = math.floor(_buffValue + 0.5)
    _bossCid = self.copyMonsterBuffConfig[tostring(_bossCid)].generalid
    self:setBossSpine(_bossCid)

    ui.setLabelString(self.rootItems.bossName, ui.IDconfig(_bossCid).name, 69,38)

    if self.monsterBuffConfig[tostring(bossData.buffCid)].kind == "0" then
        ui.setLabelString(self.rootItems.buffTxt2, _buffName.._buffValue.."%", 1011)
        -- if self.monsterBuffConfig[tostring(bossData.buffCid)].showMethod == 0 then
        --     ui.setLabelString(self.rootItems.buffTxt, gameConfig.strings:string_common("hell", 9).._buffName.._buffValue.."%", 26)
        -- elseif self.monsterBuffConfig[tostring(bossData.buffCid)].showMethod == 1 then
        --     ui.setLabelString(self.rootItems.buffTxt, gameConfig.strings:string_common("hell", 9).._buffName.._buffValue, 26)
        -- end
    elseif self.monsterBuffConfig[tostring(bossData.buffCid)].kind == "1" then
        ui.setLabelString(self.rootItems.buffTxt2, _buffName.._buffValue.."%", 1012)
        -- if self.monsterBuffConfig[tostring(bossData.buffCid)].showMethod == 0 then
        --     ui.setLabelString(self.rootItems.buffTxt, gameConfig.strings:string_common("hell", 9).._buffName.._buffValue.."%", 27)
        -- elseif self.monsterBuffConfig[tostring(bossData.buffCid)].showMethod == 1 then
        --     ui.setLabelString(self.rootItems.buffTxt, gameConfig.strings:string_common("hell", 9).._buffName.._buffValue, 27)
        -- end
    end

    ui.setLabelString(self.rootItems.buffTxt,gamedata.config.hell_difficulty[tostring(GameScene.roleinfo.level)]["show"..self.data.dropShowCount] > 0 and ("全属+"..(gamedata.config.hell_difficulty[tostring(GameScene.roleinfo.level)]["show"..self.data.dropShowCount]*100).."%") or "", 1011)
end

-- 设置boss的spine
function hellBossInfo.setBossSpine(self, cid)
    self.rootItems["bossNode"]:removeAllChildrenWithCleanup(true)
    local _generalName = gamedata.config.generalanimation[tostring(ui.IDconfig(cid).animationid)].name
    local _gneral = ui.itemcache:loadSkeleton(_generalName)
    _gneral:setAnimation("stand", true, 0)
    _gneral:setScale(1.5)
    self.rootItems["bossNode"]:addChild(_gneral.root or _gneral)    
end

-- 刷新boss buff时间
function hellBossInfo.bossBuffRfreshTime(self)
    if not gameTimer.times["windowHellBossBuff"] and self.data.buffRefreshTime > 0 then
        gameTimer:rigistTime("windowHellBossBuff", self.data.buffRefreshTime)
    end

    gameTimer:rigistTimeFunc("windowHellBossBuff", function()
        ui.setLabelString(self.rootItems.bossRefreshTimeTxt, ui.makeTimeText(gameTimer.times["windowHellBossBuff"], "minute"))
        if gameTimer.times["windowHellBossBuff"] < 0 then
            gameTimer:UnrigistTime("windowHellBossBuff")
            gameTimer:UnrigistTimeFunc("windowHellBossBuff")
        end
    end)
end

-- 关闭
function hellBossInfo.close(self)
    gameTimer:UnrigistTime("windowHellBossBuff")
    gameTimer:UnrigistTimeFunc("windowHellBossBuff")

    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil
end

-- 通用按钮
function hellBossInfo.commonBtn(self, btnName, callback)
    self.rootItems[btnName]:setSwallowsTouch(true)
    self.rootItems[btnName]:setTouchPriority(self.touchPriority - 1)
    self.rootItems[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return hellBossInfo