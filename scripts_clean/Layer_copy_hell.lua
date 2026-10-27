--深渊副本
-- require"AstarPath"

local hellcopy = {
    rootNode = nil,
    rootItems = nil,
    touchPriority = -102,
    data = nil,
    bossNum = 3,
    disPosition = 260,
    isCoolDown = true,
    challengeNumber = 0,
}

-- 查询请求
function hellcopy.hellRequest()
    UIRequest({type = 6111})
    UIRequest({type = 6117, id = 397})
    UIRequest({type = 6113, param = 0, gold = 0})
end

-- 初始化
function hellcopy.init(self, parent, toppos, param)
    self:initNode(parent, toppos)
    self:initFixedString()
    self:initEvent()

    self:hellRequest()
end

-- 初始化界面
function hellcopy.initNode(self, parent, toppos)
    self.rootNode, self.rootItems = CCBReaderLoad("copyhell/copyhell", nil, true, "copyhell")
    self.rootNode:setPosition(0,0)
    self.rootItems.topNode:setPositionY(toppos)
    ui.setScreenPositionY(self.rootItems.middleNode, toppos, self.disPosition)
    -- ui.setScreenPositionY(self.rootItems.bottomNode, toppos, self.disPosition)
    self.rootItems.bottomNode:setPositionY(200)

    self.rootItems.common_back_btn:setSwallowsTouch(true)
    self.rootItems.common_back_btn:setTouchPriority(-106)
    self.rootItems.common_back_btn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("daily")
    end, CCControlEventTouchUpInside)
    
    parent:addChild(self.rootNode)
    self.monsterConfig = gamedata.config.monster
    self.monsterBuffConfig = gamedata.config.hell_monsterBuff
    self.copyMonsterBuffConfig = gamedata.config.copy_monster
    self.playerBuffConfig = gamedata.config.hell_playerBuff
end

-- 初始化文本
function hellcopy.initFixedString(self)
    ui.setLabelString(self.rootItems.refreshTimeTxt, gameConfig.strings:string_common("hell", 2), 67)
    ui.setLabelString(self.rootItems.bossRefreshTimeContentTxt, gameConfig.strings:string_common("hell", 3), 67)
    -- ui.setLabelString(self.rootItems.backTxt, gameConfig.strings:string_common("hell", 4), 16)
    ui.setLabelString(self.rootItems.buyBuffTxt, gameConfig.strings:string_common("hell", 5), 18)
    -- ui.setLabelString(self.rootItems.titleTxt, gameConfig.strings:string_common("hell", 8), 16)
    ui.setLabelString(self.rootItems.playerBuffTxt1, gameConfig.strings:string_common("hell", 33), 69)
    -- ui.setLabelString(self.rootItems.descTxt, gameConfig.strings:string_common("hell", 35), 69)
end

-- 初始化点击事件
function hellcopy.initEvent(self)
    --ToDo
    self:initBackBtn()
    self:initClearRewardBtn()
    self:initBuyBuffBtn()
    self:initChallengeBtns()
end

-- 返回按钮
function hellcopy.initBackBtn(self)
    local _callback = function()
        gamedata.music:PlayOptSound("tuichu")
        GameScene:shiftLayerById(40)
    end

    self:commonBtn("backBtn", _callback)
end

-- 通关奖励按钮
function hellcopy.initClearRewardBtn(self)
    local _callback = function()
        local _isAllClear = self.data.isAllClear
        -- gameWindows:openWindow("hellAllReward", _isAllClear)
        gameWindows:openWindow("hellRewardPreview", _isAllClear)
    end
    self:commonBtn("clearRewardBtn", _callback)
end

-- 全部挑战按钮
function hellcopy.initChallengeBtns(self)
    for i = 1, self.bossNum do
        self:initChallengeBtn(i)
    end
end

-- 单一挑战按钮
function hellcopy.initChallengeBtn(self, id)
    local _callback = function()
        if self.data and next(self.data) and
            self.data.boss and next(self.data.boss) then
            if self.data.boss[tostring(id)].isClear == 0 then
                gameWindows:openWindow("hellBossInfo", {boss = self.data.boss[tostring(id)], id = id ,dropShowCount = self.dropShowCount})
            else
                runGamePrompt({msg = gameConfig.strings:string_common("hell", 16)})
            end
        end
    end

    self:commonBtn("challengeBtn"..id, _callback)
end

-- 购买buff按钮
function hellcopy.initBuyBuffBtn(self)
    local _callback = function()
        if self.data.isAllClear > 0 then
            runGamePrompt({msg = gameConfig.strings:string_common("hell", 23)})
        else
            gameWindows:openWindow("hellBuyBuff")
        end
    end
    self:commonBtn("buyBuffBtn", _callback)
end

function hellcopy.refreshPlayerBuff(self, data)
    if data.currentBuff == 0 then
        ui.setLabelString(self.rootItems.playerBuffTxt2, gameConfig.strings:string_common("hell", 34), 69) 
    else
        local _cid = data.buffCid1

        if _cid > 0 then
            _cid = tostring(_cid)
            local _buffName = self.playerBuffConfig[_cid].desc
            local _buffValue = data.buffValue1

            -- if self.playerBuffConfig[_cid].showMethod == 0 then
                if self.playerBuffConfig[_cid].method == "percent" then

                elseif self.playerBuffConfig[_cid].method == "value" then
                    _buffValue = _buffValue / 100
                end
            -- elseif self.playerBuffConfig[_cid].showMethod == 1 then
            --     _buffValue = _buffValue / 100
            -- end

            _buffValue = math.floor(_buffValue + 0.5)

            if self.playerBuffConfig[_cid].kind == "0" then
                ui.setLabelString(self.rootItems.playerBuffTxt2, _buffName.._buffValue.."%", 75)
                -- if self.playerBuffConfig[_cid].showMethod == 0 then
                --     ui.setLabelString(self.rootItems.playerBuffTxt2, _buffName.._buffValue.."%", 75)
                -- elseif self.playerBuffConfig[_cid].showMethod == 1 then
                --     ui.setLabelString(self.rootItems.playerBuffTxt2, _buffName.._buffValue, 75)
                -- end
            elseif self.playerBuffConfig[_cid].kind == "1" then
                ui.setLabelString(self.rootItems.playerBuffTxt2, _buffName.._buffValue.."%", 76)
                -- if self.playerBuffConfig[_cid].showMethod == 0 then
                --     ui.setLabelString(self.rootItems.playerBuffTxt2, _buffName.._buffValue.."%", 76)
                -- elseif self.playerBuffConfig[_cid].showMethod == 1 then
                --     ui.setLabelString(self.rootItems.playerBuffTxt2, _buffName.._buffValue, 76)
                -- end
            end
        end
    end
end

-- 刷新数据
function hellcopy.reloadData(self, data, isRefreshBoss)
    if isRefreshBoss then
        gameTimer:UnrigistTime("hellBossBuff")
        gameTimer:UnrigistTimeFunc("hellBossBuff")
        self.data.buffRefreshTime = data.buffRefreshTime

        if data.boss and next(data.boss) and
            self.data.boss and next(self.data.boss) then

            for i = 1, self.bossNum do
                local _id = tostring(i)
                self.data.boss[_id].iid = data.boss[_id].iid
                self.data.boss[_id].cid = data.boss[_id].cid
                self.data.boss[_id].buffCid = data.boss[_id].buffCid
                self.data.boss[_id].value = data.boss[_id].value
            end
        end
    else
        self.data = data or self.data
    end
    
    printT(self.data)

    --属性强度
    self:setBossIntensify()
    self:refreshRewardPreview()

    self:refreshBossItems()
    self:bossBuffRfreshTime()

    self:refreshBuyBuffBtn()
    self:refreshHint()
end

-- 刷新全通奖励状态
function hellcopy.reloadIsAllClear(self, data)
    self.data.isAllClear = data
    self:refreshHint()
end

-- 刷新所有boss信息
function hellcopy.refreshBossItems(self)
    if self.data and next(self.data) and
       self.data.boss and next(self.data.boss) then
        for i = 1, self.bossNum do
            local bossData = nil 
            if self.data.boss[tostring(i)] and next(self.data.boss[tostring(i)]) then
                local _bossData = self.data.boss[tostring(i)]
                self:refreshBossItem(i, _bossData)
            end
        end
    end
end

-- 刷新一个boss信息
function hellcopy.refreshBossItem(self, id, bossData)
    local _bossid = self.monsterConfig[tostring(bossData.cid)].bossid
    local _bossCid = self.monsterConfig[tostring(bossData.cid)]["p".._bossid]
    local _buffName = self.monsterBuffConfig[tostring(bossData.buffCid)].desc
    local _buffValue = bossData.value

    if self.monsterBuffConfig[tostring(bossData.buffCid)].showMethod == 0 then
        if self.monsterBuffConfig[tostring(bossData.buffCid)].method == "value" then
            _buffValue = _buffValue / 100
        end
    elseif self.monsterBuffConfig[tostring(bossData.buffCid)].showMethod == 1 then
         _buffValue = _buffValue / 100
    end

    _buffValue = math.floor(_buffValue + 0.5)
    _bossCid = self.copyMonsterBuffConfig[tostring(_bossCid)].generalid
    self:setBossSpine(id, _bossCid, bossData.isClear)
    self:setBossIsClearEffect(id, bossData.isClear)
    self:setBossBG(id, bossData.isClear)
    self:setChallengeBtn(id, bossData.isClear)

    ui.setLabelString(self.rootItems["bossNameTxt"..id],"BOSS:"..ui.IDconfig(_bossCid).name, 69,38)

    if self.monsterBuffConfig[tostring(bossData.buffCid)].kind == "0" then
        if self.monsterBuffConfig[tostring(bossData.buffCid)].showMethod == 0 then
            ui.setLabelString(self.rootItems["bossBuffTxt"..id.."_1"], gameConfig.strings:string_common("hell", 9).._buffName.._buffValue.."%", 1011)
        elseif self.monsterBuffConfig[tostring(bossData.buffCid)].showMethod == 1 then
            ui.setLabelString(self.rootItems["bossBuffTxt"..id.."_1"], gameConfig.strings:string_common("hell", 9).._buffName.._buffValue, 1011)
        end
    elseif self.monsterBuffConfig[tostring(bossData.buffCid)].kind == "1" then
        if self.monsterBuffConfig[tostring(bossData.buffCid)].showMethod == 0 then
            ui.setLabelString(self.rootItems["bossBuffTxt"..id.."_1"], gameConfig.strings:string_common("hell", 9).._buffName.._buffValue.."%", 1012)
        elseif self.monsterBuffConfig[tostring(bossData.buffCid)].showMethod == 1 then
            ui.setLabelString(self.rootItems["bossBuffTxt"..id.."_1"], gameConfig.strings:string_common("hell", 9).._buffName.._buffValue, 1012)
        end
    end

    if bossData.isClear == 1 then
        -- ui.setLabelString(self.rootItems["bossBuffTxt"..id.."_2"],"", 1011)
        ui.setLabelString(self.rootItems["bossBuffTxt"..id.."_1"], "", 1012)
    else
        -- ui.setLabelString(self.rootItems["bossBuffTxt"..id.."_2"],gamedata.config.hell_difficulty[tostring(GameScene.roleinfo.level)]["show"..self.dropShowCount] > 0 and ("强度:全属+"..(gamedata.config.hell_difficulty[tostring(GameScene.roleinfo.level)]["show"..self.dropShowCount]*100).."%") or "", 1011)
    end
end

-- 设置boss的显示状态
function hellcopy.setBossBG(self, id, isClear)
    if isClear == 1 then
        ui.addGray("CCSprite", self.rootItems["bossBG"..id])
    else
        ui.removeGray("CCSprite", self.rootItems["bossBG"..id])
    end 
end

-- 设置boss的spine
function hellcopy.setBossSpine(self, id, cid, isClear)
    self.rootItems["bossNode"..id]:removeAllChildrenWithCleanup(true)
    local _generalName = gamedata.config.generalanimation[tostring(ui.IDconfig(cid).animationid)].name
    local _gneral = ui.itemcache:loadSkeleton(_generalName)
    _gneral:setAnimation("stand", true, 0)
    _gneral:setScale(1.0)
    self.rootItems["bossNode"..id]:addChild(_gneral.root or _gneral)

    if isClear == 1 then
        ui.addGray("CCNode", _gneral.root or _gneral)
    else
        ui.removeGray("CCNode", _gneral.root or _gneral)
    end     
end

-- 设置boss的完成特效
function hellcopy.setBossIsClearEffect(self, id, isClear)
    isClear = (isClear == 1)
    self.rootItems["winEffectNode"..id]:setVisible(isClear)
end

-- 设置挑战按钮文字
function hellcopy.setChallengeBtn(self, id, isClear)
    local _clearTxt = gameConfig.strings:string_common("hell", 6)

    if isClear == 1 then
        ui.addGray("CCControlButton", self.rootItems["challengeBtn"..id])
        _clearTxt = gameConfig.strings:string_common("hell", 7)
    else
        ui.removeGray("CCControlButton", self.rootItems["challengeBtn"..id])
    end

    ui.setLabelString(self.rootItems["challengeBtnTxt"..id], _clearTxt, 18)
end

-- 刷新时间
function hellcopy.bossBuffRfreshTime(self)
    if not gameTimer.times["hellBossBuff"] and self.data.buffRefreshTime > 0 then
        gameTimer:rigistTime("hellBossBuff", self.data.buffRefreshTime)
    end

    gameTimer:rigistTimeFunc("hellBossBuff", function()
        ui.setLabelString(self.rootItems.bossRefreshTimeTxt, ui.makeTimeText(gameTimer.times["hellBossBuff"], "minute"), 68)
        if gameTimer.times["hellBossBuff"] <= 0 then
            gameTimer:UnrigistTime("hellBossBuff")
            gameTimer:UnrigistTimeFunc("hellBossBuff")
            if gameWindows.windows["hellBossInfo"].show then
                gameWindows:closeWindow("hellBossInfo")
            end
            UIRequest({type = 6111})
        end
    end)
end

-- 刷新购买buff按钮状态
function hellcopy.refreshBuyBuffBtn(self)
    if self.data.isAllClear > 0 then
        ui.addGray("CCControlButton", self.rootItems["buyBuffBtn"])
    else
        ui.removeGray("CCControlButton", self.rootItems["buyBuffBtn"])
    end
end

function hellcopy.refreshHint(self)
    if self.data.isAllClear == 1 then
        self.rootItems.hintNode:setVisible(true)
    else
        self.rootItems.hintNode:setVisible(false)
    end
end

-- 移除Layer
function hellcopy.clear(self)
    for i = 1, self.bossNum do
        self:clearSpine(i)
    end

    gameTimer:UnrigistTime("hellBossBuff")
    gameTimer:UnrigistTimeFunc("hellBossBuff")


    self.rootNode:stopAllActions()
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.data = nil
    self.challengeNumber = 0

    self.dropShowCount = nil
    if self.showtimer then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.showtimer)
        self.showtimer = nil
    end

end

-- 移除Boss的spine
function hellcopy.clearSpine(self, id)
    self.rootItems["bossNode"..id]:removeAllChildrenWithCleanup(true)
    self.rootItems["bossNode"..id]:removeFromParentAndCleanup(true)
    self.rootItems["bossNode"..id] = nil
end

-- 通用按钮
function hellcopy.commonBtn(self, btnName, callback)
    self.rootItems[btnName]:setSwallowsTouch(true)
    self.rootItems[btnName]:setTouchPriority(self.touchPriority - 1)
    self.rootItems[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

-- 通用按钮
function hellcopy.commonClose(self, name)
    if gameWindows.windows[name].show then
        gameWindows:closeWindow(name)
    end
end


--检测boss 死亡播放特效
function hellcopy.detailBossDead(self,id)
    self.rootItems["deadEffectNode"..id]:removeAllChildrenWithCleanup(true)

    local seqStr = ""
    for i=1,3 do
        if i ~= id and self.data.boss[tostring(i)] and self.data.boss[tostring(i)].isClear == 0 then
            seqStr = seqStr..i
        end
    end
    print("detailBossDead",seqStr)
    if seqStr ~= "" then
        local ccb, items = CCBReaderLoad("UIEffect/tongji/tongjieffect_"..id, nil, true, "tongjieffect")
        self.rootItems["deadEffectNode"..id]:addChild(ccb)
        local animationManager = getAnimationManager(items)
        animationManager:setAnimationCompletedCallback(function()
            self.rootItems["deadEffectNode"..id]:removeAllChildrenWithCleanup(true)


            for i=1,3 do
                if i ~= id and self.data.boss[tostring(i)] and self.data.boss[tostring(i)].isClear == 0 then
                    local ccb, items = CCBReaderLoad("UIEffect/tongji/tongji_change", nil, true, "tongji_change")
                    ccb:setPosition(self.rootItems["bossBuffTxt"..i.."_2"]:getPositionX(),self.rootItems["bossBuffTxt"..i.."_2"]:getPositionY())
                    self.rootItems["bossInfo"..i]:addChild(ccb,1000)
                    local animationManager = getAnimationManager(items)
                    animationManager:setAnimationCompletedCallback(function()
                        ccb:removeFromParentAndCleanup(true)
                    end)
                    animationManager:runAnimationsForSequenceNamed("play")
                end
            end
        end)
        animationManager:runAnimationsForSequenceNamed(seqStr)

    end
    
end

function hellcopy.setBossIntensify(self)

    local dropShowCountOld = self.dropShowCount
    local dropShowCount = 1
    
    for i = 1, self.bossNum do
        if self.data and next(self.data) and
           self.data.boss and next(self.data.boss) then
            if self.data.boss[tostring(i)].isClear ~= 0 then
                dropShowCount = dropShowCount + 1
            end
        end
    end

    if dropShowCount <= 3 then
        if dropShowCountOld and dropShowCount > dropShowCountOld then
            self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(2), CCCallFunc:create(function()
                local startValue = gamedata.config.hell_difficulty[tostring(GameScene.roleinfo.level)]["show"..dropShowCountOld]*100
                local endValue = gamedata.config.hell_difficulty[tostring(GameScene.roleinfo.level)]["show"..dropShowCount]*100

                
                local time = 30
                local delay = 1/time

                local donum = 0
                if endValue > 0 then
                    donum = math.max(1,(endValue - startValue)/time)
                end

                local n = 0
                self.showtimer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
                    startValue = math.floor(startValue + donum)
                    n = n + 1
                    if startValue >= endValue then
                        startValue = endValue
                        self:setIntensifyLabel(startValue)
                        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.showtimer)
                        self.showtimer = nil
                    end
                    self:setIntensifyLabel(startValue)
                end, delay, false)
            end)))

        else
            local value = gamedata.config.hell_difficulty[tostring(GameScene.roleinfo.level)]["show"..dropShowCount]*100
            self:setIntensifyLabel(value)
        end
    else
        self:setIntensifyLabel(0)
    end

    self.dropShowCount = dropShowCount
end

-- 全部奖励预览按钮
function hellcopy.refreshRewardPreview(self)

    local rewards = {}
    if self.dropShowCount < 3 then
        ui.setLabelString(self.rootItems.rewardLab1,"缉拿", 14)
        ui.setLabelString(self.rootItems.rewardLab2,gameConfig.strings.bigNum[self.dropShowCount].."个", 14)
        rewards = ui.getIDandNUMs(gamedata.config.hell_difficulty[tostring(GameScene.roleinfo.level)]["dropShow"..self.dropShowCount])
    else

        ui.setLabelString(self.rootItems.rewardLab1,"全通", 14)
        ui.setLabelString(self.rootItems.rewardLab2,"奖励", 14)
        rewards = ui.getIDandNUMs(gamedata.config.hell_difficulty[tostring(GameScene.roleinfo.level)]["dropShow3"]..gamedata.config.hell_difficulty[tostring(GameScene.roleinfo.level)]["finalDrop"])
    end

    self:createRewardList(rewards)
end

function hellcopy.setIntensifyLabel(self,value)
    for i=1,3 do
        local bossData = self.data.boss[tostring(i)]
        if bossData.isClear == 1 then
            ui.setLabelString(self.rootItems["bossBuffTxt"..i.."_2"],"", 1011)
        else
            ui.setLabelString(self.rootItems["bossBuffTxt"..i.."_2"],value > 0 and ("强度:全属+"..value.."%") or "", 1011)
        end
    end
end


function hellcopy.createRewardList(self,rewards)

    self.rootItems.rewardList:removeAllChildrenWithCleanup(true)
    if (not next(rewards)) or self.dropShowCount > 3 then
        self.rootItems.rewardNode:setVisible(false)
        self.rootItems.buttonNode:setVisible(false)
        ui.setLabelString(self.rootItems["passlab"],"今日已通关", 1010,50)
        return
    end
    self.rootItems.buttonNode:setVisible(true)
    self.rootItems.rewardNode:setVisible(true)
    ui.setLabelString(self.rootItems["passlab"],"", 1010,50)
    

    local celldict = {}

    local listHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(150, 200)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("icons/new_icon", nil, true, "new_icon")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            ui.setNewIcon(ccbDocumentControler, rewards[a1+1])
            ccbDocumentControler["i_button"]:setTouchPriority(-103)
            ccbDocumentControler["i_button"]:addHandleOfControlEvent(function()
                if gameTouch.isScrollling then return end
                ui.setPopwindowByCid(rewards[a1+1].cid)
            end, CCControlEventTouchUpInside)

            cellCCB:setScale(0.7)
            cellCCB:setPosition(150/2, 200/2)

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then 
            r = table.getTableLength(rewards)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    local rewardList = ui.createLuaTableView({
        handle = listHandle,
        viewwidth = self.rootItems.rewardList:getContentSize().width,
        viewheight = self.rootItems.rewardList:getContentSize().height,
        dire = 0
    })
    self.rootItems.rewardList:addChild(rewardList)
    rewardList:setTouchPriority(self.touchPriority)
    -- rewardList:setBounceable(false)
end

-- 单一奖励预览按钮
function hellcopy.initRewardPreviewBtn(self, id)
    

    -- local _callback = function()
    --     if self.data and next(self.data) and
    --        self.data.boss and next(self.data.boss) then
    --         if self.data.boss[tostring(id)].isClear == 0 then
    --             gameWindows:openWindow("hellRewardPreview", self.dropShowCount)
    --         end
    --     end
    -- end
    -- self:commonBtn("rewardPreviewBtn"..id, _callback)
end


-- 零点刷新
function hellcopy.UIUpdateData(self,isreset)
    if isreset then
        self:hellRequest()
        -- 关闭刷新窗口
        self:commonClose("hellRefresh")
        -- 关闭通关奖励窗口
        self:commonClose("hellAllReward")
        -- 关闭boss信息窗口
        self:commonClose("hellBossInfo")
        -- 关闭购买buff窗口
        self:commonClose("hellBuyBuff")
        -- 关闭地狱奖励预览窗口
        self:commonClose("hellRewardPreview")
    end
end

return hellcopy