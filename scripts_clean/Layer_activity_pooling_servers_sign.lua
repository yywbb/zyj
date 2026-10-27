local poolingServersSign = {
    rootItems = nil,
    rootNode = nil,
    touchPriority = -101,
    activityId = 120,
    spineType = {
        [1] = "stand",
        [2] = "tiao_1",
        [3] = "tiao_2",
        [4] = "tiao_3",
        [5] = "tiao_4",
        [6] = "run",
    },
    deltaTime = 0.05,

    npcPosition = {
        [0] = 0,
        [1] = 3,
        [2] = 4,
        [3] = 5,
        [4] = 10,
        [5] = 11,
        [6] = 12,
        [7] = 14,
    }
}

--清空数据
function poolingServersSign.clear(self)
    gameTimer:UnrigistTime("PoolingServersSign")
    gameTimer:UnrigistTimeFunc("PoolingServersSign")
    self.show = false

    if self.rootNode then
        self.rootNode:removeAllChildrenWithCleanup(true)
        self.rootNode:removeFromParentAndCleanup(true)
        self.rootItems = nil
        self.rootNode = nil
    end
end

function poolingServersSign.init(self, size)
    self.contentsize = size
    self.show = true
    self:initNode()
    self:initConfig()
    self:initFixedString()
    self:initReward()

    UIRequest({type = 6101})

    return self.rootNode
end

function poolingServersSign.initNode(self)
	self.rootNode, self.rootItems = CCBReaderLoad("activityhefu/hefuqiandao", nil, true, "hefuqiandao")
    self.rootItems.topnode:setPositionY(self.contentsize.y - 180)
end

function poolingServersSign.initConfig(self)
	self.suitSignConfig = gamedata.config.suit_sign
end

function poolingServersSign.initFixedString(self)
	ui.setLabelString(self.rootItems.endTimerTxt1, gameConfig.strings:string_common("poolingServerSign", 1), 63)
	ui.setLabelString(self.rootItems.descTxt, gameConfig.strings:string_common("poolingServerSign", 2), 63)
	ui.setLabelString(self.rootItems.goTxt, gameConfig.strings:string_common("poolingServerSign", 3), 19)

    local _list = {}
    table.insert(_list, {node = self.rootItems.endTimerTxt1})
    table.insert(_list, {node = self.rootItems.time})
    ui.setCCNodeListRight(_list)
end

function poolingServersSign.initReward(self)
	for i = 1, table.getTableLength(self.suitSignConfig) do
        if i == 7 then
            self["ccbNode"..i], self["ccbItems"..i] = CCBReaderLoad("activityhefu/hefuhaoli_seven", nil, true, "hefuhaoli_seven")
        else
            local _num1 = math.mod(i, 2)

            if _num1 == 1 then
                self["ccbNode"..i], self["ccbItems"..i] = CCBReaderLoad("activityhefu/hefuhaoli_box1", nil, true, "hefuhaoli_box1")
            else
                self["ccbNode"..i], self["ccbItems"..i] = CCBReaderLoad("activityhefu/hefuhaoli_box2", nil, true, "hefuhaoli_box2")
            end
        end

        self.rootItems["rewardNode"..i]:addChild(self["ccbNode"..i])
        setSpriteFrameByName(self["ccbItems"..i]["rewardDay"], "hefu_"..i)

        local _cb = function()
            gameWindows:openWindow("poolingServersSignReward", {day = i})
        end

        self:commonBtn(self["ccbItems"..i], "rewardBtn", _cb)
	end
end

function poolingServersSign.reloadData(self, data)
	self.day = data.day
    self.currentPosition = data.getRewardCount
    self.getRewardStatus = data.getRewardStatus

	self:createTimer()
	self:setRewardCheck()
    self:initAnimation()
    self:setRunBtn()
end

function poolingServersSign.createTimer(self)
    local _diffTime = self:getDiffTime()
    if _diffTime and _diffTime > 0 then
        gameTimer:rigistTime("PoolingServersSign", _diffTime)

        if gameTimer.times["PoolingServersSign"] and gameTimer.times["PoolingServersSign"] > 0 then
            gameTimer:rigistTimeFunc("PoolingServersSign", function()
                if gameTimer.times["PoolingServersSign"] <= 0 then
                    ui.setLabelString(self.rootItems.time, ui.makeTimeDayText(gameTimer.times["PoolingServersSign"], "day"), 63)
                    
                    if gameTimer.times["PoolingServersSign"] then
                        gameTimer:UnrigistTimeFunc("PoolingServersSign")
                    end
                else
                    ui.setLabelString(self.rootItems.time, ui.makeTimeDayText(gameTimer.times["PoolingServersSign"], "day"), 63)
                end
            end)
        end
    end
end

function poolingServersSign.getDiffTime(self)
    -- 活动时间
    local _timediff = 0
    local _activityId = tostring(self.activityId)
    local _nowTime = gamedata:time()

    if self.rootItems.time then
        if gamedata.config.activity_time[_activityId]["open_type"] and
           gamedata.config.activity_time[_activityId]["open_type"] == 6 then 
            local _temp = os.date("*t", _nowTime)
            _timediff = 86400 * (gamedata.config.activity_time[_activityId]["continued_time"] - self.day) - _temp.hour * 3600 - _temp.min * 60 - _temp.sec
        else
            self.rootItems.time:setString("")
            self.rootItems.desc1:setString("")
        end
    end

    return _timediff
end

function poolingServersSign.setRewardCheck(self)
	for i = 1, 7 do
        if i <= self.currentPosition then
            local _playAnimation = getAnimationManager(self["ccbItems"..i])
            _playAnimation:runAnimationsForSequenceNamed("hui")
        end
    end
end

-- npc 动画
function poolingServersSign.setNpcAnimation(self, animationType, isInit)
    if self.currentPosition < 7 then
        if isInit then
            self.rootItems.npcNode:removeAllChildrenWithCleanup(true)
            local _spineName = "poolingServerSign"
            self.npcSpine = CCSkeletonAnimation:create(_spineName.."/".._spineName..".json", _spineName.."/".._spineName..".atlas", 1)
        end

        self.npcSpine:setAnimation(animationType, true, 0)
        self.npcSpine:setScale(0.7)
        self.npcSpine:setPosition(0,0)

        if isInit then
            self.rootItems.npcNode:addChild(self.npcSpine)
        end
    end
end

function poolingServersSign.changeNpcAnimation(self, animationType, isLoop)
    if self.npcSpine then
        self.npcSpine:setAnimation(animationType, isLoop ~= false and true or false, 0)
    end
end

function poolingServersSign.initAnimation(self)
    self:setNpcAnimation(self.spineType[1], true)
    local _x, _y = self.rootItems["target"..self.npcPosition[self.currentPosition]]:getPosition()
    
    self.rootItems.npcNode:setPosition(_x, _y)

    if self.currentPosition >= 4 then
        self.rootItems.npcNode:setScaleX(-1)
    end
end

function poolingServersSign.setRunBtn(self)
    self:setRunBtnGray()

    local _cb = function()
        if self.getRewardStatus == 1 then
            gameTouch:clickprofbytime(5)
            UIRequest({type = 6102})
        else
            runGamePrompt({msg = gameConfig.strings:string_common("poolingServerSign", 4)})
        end
    end
    self:commonBtn(self.rootItems, "goBtn", _cb)
end

function poolingServersSign.setRunBtnGray(self)
    if self.getRewardStatus == 1 then
        ui.removeGray("CCControlButton", self.rootItems.goBtn)
    else
        ui.addGray("CCControlButton", self.rootItems.goBtn)
    end
end

function poolingServersSign.getReward(self, data)
    self.reward = data.reward
    self["sign"..self.currentPosition + 1](self)
    self.getRewardStatus = 2 
    self:setRunBtnGray()
end

function poolingServersSign.stand(self)
    self:changeNpcAnimation(self.spineType[1])
end

function poolingServersSign.run(self)
    self:changeNpcAnimation(self.spineType[6])
end

function poolingServersSign.JumpToTop(self)
    self:changeNpcAnimation(self.spineType[2])
    self.npcSpine:addAnimation(self.spineType[3], true, 0, 0)
end

function poolingServersSign.JumpToFloor1(self)
    self:changeNpcAnimation(self.spineType[4])
end

function poolingServersSign.JumpToFloor2(self, cb)
    self:changeNpcAnimation(self.spineType[5], false)
    self.npcSpine:addAnimation(self.spineType[1], true, 0, 0)

    self.rootItems.npcNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.2), CCCallFunc:create(function()
        if cb then
            cb()
        end
    end)))
end

function poolingServersSign.sign1(self)
    self:run()
    
    local _cbBox = function()
        self:openBox(1)
    end

    local _cbUp2 = function()
        self:jump(2, 3, 3, 0.2, 0.2, _cbBox)
    end

    local _cbRun = function()
        self:run()
        local _startX, _startY = self:getTargetPosition(2)
        local _endX, _endY = self:getTargetPosition(3)
        local _diffPosition = self:getDiffPosition(_startX, _endX, 0.5)
        self:moveNpcNodeX(_diffPosition, _endX, _cbUp2)
    end

    local _cbUp = function()
        self:jump(1, 1, 2, 0.5, 0.2, nil, _cbRun)
    end

    local _startX, _startY = self:getTargetPosition(0)
    local _endX, _endY = self:getTargetPosition(1)
    local _diffPosition = self:getDiffPosition(_startX, _endX, 0.5)

    self:moveNpcNodeX(_diffPosition, _endX, _cbUp)
end

function poolingServersSign.sign2(self)
    self:run()
    
    local _cbBox = function()
        self:openBox(2)
    end

    local _cbUp = function()
        self:jump(3, 4, 4, 0.2, 0.2, _cbBox)
    end

    local _startX, _startY = self:getTargetPosition(3)
    local _endX, _endY = self:getTargetPosition(4)
    local _diffPosition = self:getDiffPosition(_startX, _endX, 0.3)
    self:moveNpcNodeX(_diffPosition, _endX, _cbUp)
end

function poolingServersSign.sign3(self)
    self:run()

    local _cbBox = function()
        self:openBox(3)
    end

    local _cbUp = function() 
        self:jump(4, 5, 5, 0.2, 0.2, _cbBox)
    end

    local _startX, _startY = self:getTargetPosition(4)
    local _endX, _endY = self:getTargetPosition(5)
    local _diffPosition = self:getDiffPosition(_startX, _endX, 0.3)
    self:moveNpcNodeX(_diffPosition, _endX, _cbUp)
end

function poolingServersSign.sign4(self)
    self:run()

    local _cbBox = function()
        self:openBox(4)
    end

    local _cbUp3 = function()
         self:jump(7, 10, 10, 0.2, 0.2, _cbBox)
    end

    local _cbRun2 = function()
        self:run()
        local _startX, _startY = self:getTargetPosition(9)
        local _endX, _endY = self:getTargetPosition(10)
        local _diffPosition = self:getDiffPosition(_startX, _endX, 0.3)
        self:moveNpcNodeX(_diffPosition, _endX, _cbUp3)
    end

    local _cbUp2 = function()
        self.rootItems.npcNode:setScaleX(-1)

        self:jump(6, 8, 9, 0.5, 0.2, nil, _cbRun2)
    end

    local _cbRun = function()
        self:run()
        local _startX, _startY = self:getTargetPosition(7)
        local _endX, _endY = self:getTargetPosition(8)
        local _diffPosition = self:getDiffPosition(_startX, _endX, 0.3)
        self:moveNpcNodeX(_diffPosition, _endX, _cbUp2)
    end

    local _cbUp = function() 
        self:jump(5, 6, 7, 0.5, 0.2, nil, _cbRun)
    end

    local _startX, _startY = self:getTargetPosition(5)
    local _endX, _endY = self:getTargetPosition(6)
    local _diffPosition = self:getDiffPosition(_startX, _endX, 0.3)
    self:moveNpcNodeX(_diffPosition, _endX, _cbUp)
end

function poolingServersSign.sign5(self)
    self:run()

    local _cbBox = function()
        self:openBox(5)
    end

    local _cbUp = function()
        self:jump(8, 11, 11, 0.2, 0.2, _cbBox)
    end

    local _startX, _startY = self:getTargetPosition(10)
    local _endX, _endY = self:getTargetPosition(11)
    local _diffPosition = self:getDiffPosition(_startX, _endX, 0.3)
    self:moveNpcNodeX(_diffPosition, _endX, _cbUp)
end

function poolingServersSign.sign6(self)
    self:run()
    
    local _cbBox = function()
        self:openBox(6)
    end

    local _cbUp = function()
        self:jump(9, 12, 12, 0.2, 0.2, _cbBox)
    end

    local _startX, _startY = self:getTargetPosition(11)
    local _endX, _endY = self:getTargetPosition(12)
    local _diffPosition = self:getDiffPosition(_startX, _endX, 0.3)
    self:moveNpcNodeX(_diffPosition, _endX, _cbUp)
end

function poolingServersSign.sign7(self)
    self:run()

    local _cbBox = function()
        self.rootItems.npcNode:removeAllChildrenWithCleanup(true)
        self:openBox(7)
    end

    local _cbRun = function()
        self:run()
        local _startX, _startY = self:getTargetPosition(14)
        local _endX, _endY = self:getTargetPosition(15)
        local _diffPosition = self:getDiffPosition(_startX, _endX, 0.3)
        self:moveNpcNodeX(_diffPosition, _endX, _cbBox)
    end

    local _cbUp1 = function()
        self:jump(10, 13, 14, 0.5, 0.2, nil, _cbRun)
    end

    local _startX, _startY = self:getTargetPosition(12)
    local _endX, _endY = self:getTargetPosition(13)
    local _diffPosition = self:getDiffPosition(_startX, _endX, 0.3)
    self:moveNpcNodeX(_diffPosition, _endX, _cbUp1)
end

function poolingServersSign.jump(self, topId, startId, endId, maxTime1, maxTime2, cb1, cb2)
    local _topX, _topY = self:getTopPosition(topId)
    local _startX, _startY = self:getTargetPosition(startId)
    local _endX, _endY = self:getTargetPosition(endId)
    local _diffPosition1 = self:getDiffPosition(_startX, _topY, maxTime1)
    local _topLineDiffPosition1 = self:getLineDiff(_topY - _startY, maxTime1)
    local _count = maxTime1 / self.deltaTime
    self:JumpToTop()

    local _cbDown1 = function()
        if cb1 then
            cb1()
        end

        self:JumpToFloor1()
        local _diffPosition2 = self:getDiffPosition(_topX, _endX, maxTime2)
        local _topLineDiffPosition2 = self:getLineDiff(_endY - _topY, maxTime2)
        local _count = 1

        local _cbDown2 = function()
            self:JumpToFloor2(cb2)
        end
        self:moveNpcNode(_diffPosition2, _topLineDiffPosition2, _endX, _endY, "down", _count, _cbDown2)
    end

    self:moveNpcNode(_diffPosition1, _topLineDiffPosition1, _topX, _topY, "up", _count, _cbDown1)
end

function poolingServersSign.getTargetPosition(self, targetId)
    return self.rootItems["target"..targetId]:getPosition()
end

function poolingServersSign.getTopPosition(self, topId)
    return self.rootItems["top"..topId]:getPosition()
end

function poolingServersSign.getMiddelPosition(self, middleId)
    return self.rootItems["middle"..middleId]:getPosition()
end

function poolingServersSign.getDiffPosition(self, startPositionX, endPositionX, maxTime)
    return (endPositionX - startPositionX) / maxTime * self.deltaTime
end

function poolingServersSign.getLineDiff(self, diffPosition, maxTime)
    local _count = maxTime / self.deltaTime
    local _sum = 0

    for i = 1, _count do
        _sum = _sum + i
    end

    return diffPosition / _sum
end

function poolingServersSign.moveNpcNodeX(self, diffPosition, endPositionX, cb)
    self.rootItems.npcNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(self.deltaTime), CCCallFunc:create(function()
        local _currentPositionX = self.rootItems.npcNode:getPositionX()
        self.rootItems.npcNode:setPositionX(_currentPositionX + diffPosition)

        if (diffPosition > 0 and _currentPositionX >= endPositionX) or
           (diffPosition < 0 and _currentPositionX <= endPositionX) then
            self.rootItems.npcNode:setPositionX(endPositionX)
            if cb then
                cb()
            end
        else
            self:moveNpcNodeX(diffPosition, endPositionX, cb)
        end
    end)))
end

function poolingServersSign.moveNpcNode(self, diffPositionX, diffPositionY, endPositionX, endPositionY, moveType, count, cb)
    self.rootItems.npcNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(self.deltaTime), CCCallFunc:create(function()
        self.rootItems.npcNode:setPositionX(self.rootItems.npcNode:getPositionX() + diffPositionX)
        self.rootItems.npcNode:setPositionY(self.rootItems.npcNode:getPositionY() + diffPositionY * count)
        
        if moveType == "up" then
            count = count - 1
        elseif moveType == "down" then
            count = count + 1
        end

        if (diffPositionX > 0 and self.rootItems.npcNode:getPositionX() >= endPositionX) or
           (diffPositionX < 0 and self.rootItems.npcNode:getPositionX() <= endPositionX) then
            self.rootItems.npcNode:setPositionX(endPositionX)
        end

        if (diffPositionY > 0 and self.rootItems.npcNode:getPositionY() >= endPositionY) or
           (diffPositionY < 0 and self.rootItems.npcNode:getPositionY() <= endPositionY) then
            self.rootItems.npcNode:setPositionY(endPositionY)
            if cb then
                cb()
            end
        else
            self:moveNpcNode(diffPositionX, diffPositionY, endPositionX, endPositionY, moveType, count, cb)
        end
    end)))
end

function poolingServersSign.openBox(self, id)
    local _playAnimation = getAnimationManager(self["ccbItems"..id])
    _playAnimation:runAnimationsForSequenceNamed("play")
    _playAnimation:setAnimationCompletedCallback(function()
        local _cb = function()
            UIRequest({type = 6101})
        end
        gameTouch:setClickProf(false)
        showRewardPopupWindow(self.reward, nil, _cb)
    end)
end

-- 通用按钮
function poolingServersSign.commonBtn(self, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)

    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(touchPriority or (self.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return poolingServersSign