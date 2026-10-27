local poolingServersOnline = {
    rootItems = nil,
    rootNode = nil,
    touchPriority = -101,
    activityId = 119,
    rewardCount = 4,
    totalRewardCount = 3,
}

--清空数据
function poolingServersOnline.clear(self)
    gameTimer:UnrigistTime("PoolingServersOnlineFinal")
    gameTimer:UnrigistTimeFunc("PoolingServersOnlineFinal")
    gameTimer:UnrigistTime("PoolingServersOnline")
    gameTimer:UnrigistTimeFunc("PoolingServersOnline")

    self.show = false

    if self.rootNode then
        self.rootNode:removeAllChildrenWithCleanup(true)
        self.rootNode:removeFromParentAndCleanup(true)
        self.rootItems = nil
        self.rootNode = nil
    end
end

function poolingServersOnline.init(self, size)
    self.contentsize = size
    self.show = true
    self:initNode()
    self:initConfig()
    self:initFixedString()
    self:initReward()
        
    UIRequest({type = 6105})


    return self.rootNode
end

function poolingServersOnline.initNode(self)
	self.rootNode, self.rootItems = CCBReaderLoad("activityhefu/hefuonline", nil, true, "hefuonline")
    self.rootItems.topnode:setPositionY(self.contentsize.y - 180)
    self.rootItems.middleNode:setPositionY(self.contentsize.y - 180 - 620 - (GameScene.topposY - 1620) * 0.5) 
end

function poolingServersOnline.initConfig(self)
    self.suitLineConfig = gamedata.config.suit_line
    self.suitLineFilesConfig = gamedata.config.suit_line_files
end

function poolingServersOnline.initFixedString(self)
    ui.setLabelString(self.rootItems.endTimerTxt1, gameConfig.strings:string_common("poolingServerOnline", 1), 64)
    ui.setLabelString(self.rootItems.desc1, gameConfig.strings:string_common("poolingServerOnline", 2), 66)
    ui.setLabelString(self.rootItems.title2, gameConfig.strings:string_common("poolingServerOnline", 3), 65)
    ui.setLabelString(self.rootItems.desc2, gameConfig.strings:string_common("poolingServerOnline", 4), 66)
    for i = 1, 7 do
         ui.setLabelString(self.rootItems["getTxt"..i], gameConfig.strings:string_common("poolingServerOnline", 5), 18)
    end

    local _list = {}
    table.insert(_list, {node = self.rootItems.endTimerTxt1})
    table.insert(_list, {node = self.rootItems.time})
    ui.setCCNodeListRight(_list)
end

function poolingServersOnline.initReward(self)
    self:initEveryDayReward()
    self:initTotalReward()
end

function poolingServersOnline.initEveryDayReward(self)
    for i = 1, self.rewardCount do
        local _reward = self.suitLineConfig[tostring(i)].reward

        local _t = ui.Split(_reward, ";")
        local _usedata = {}

        for k,v in pairs(_t) do
            if v ~= "" or v == nil then
                table.insert(_usedata, ui.Split(v, ","))
            end
        end

        local _key_Ex = ""
        
        if i == 1 then
            _key_Ex = ""
        else
            _key_Ex = "_"..(i - 1)
        end

        ui.setNewIcon(self.rootItems, {cid = _usedata[1][1], num = _usedata[1][2]}, i - 1)
        
        local _cb = function()
            if self.cb and self:cb() then
                return
            end

            if _usedata[1][1] and _usedata[1][1] ~="" then
                ui.setPopwindowByCid(_usedata[1][1])
            end
        end

        self:commonBtn(self.rootItems, "i_button".._key_Ex, _cb)
    end
end

function poolingServersOnline.initTotalReward(self)
    for i = 1, self.totalRewardCount do
        local _reward = self.suitLineFilesConfig[tostring(i)].reward

        local _t = ui.Split(_reward, ";")
        local _usedata = {}

        for k,v in pairs(_t) do
            if v ~= "" or v == nil then
                table.insert(_usedata, ui.Split(v, ","))
            end
        end

        local _key_Ex = "_"..(i - 1 + self.rewardCount)

        ui.setNewIcon(self.rootItems, {cid = _usedata[1][1], num = _usedata[1][2]}, i - 1 + self.rewardCount)
        
        local _cb = function()
            if self.cb and self:cb() then
                return
            end

            if _usedata[1][1] and _usedata[1][1] ~="" then
                ui.setPopwindowByCid(_usedata[1][1])
            end
        end

        self:commonBtn(self.rootItems, "i_button".._key_Ex, _cb)
    end
end

function poolingServersOnline.reloadData(self, data)
    self.day = data.day
    self.currentGift = data.currentGift
    self.currentCoolDown = data.currentCoolDown
    self.totalGet = data.totalGet
    self.totalReward = data.totalReward

    self:createFinalTimer()
    self:createTimer()
    self:setRewardCheck()
    self:setBtnGray()
    self:setBtn()
end

function poolingServersOnline.createFinalTimer(self)
    if self.currentCoolDown and self.currentCoolDown > 0 then
        gameTimer:rigistTime("PoolingServersOnline", self.currentCoolDown)

        if gameTimer.times["PoolingServersOnline"] and gameTimer.times["PoolingServersOnline"] > 0 then
            gameTimer:rigistTimeFunc("PoolingServersOnline", function()
                if gameTimer.times["PoolingServersOnline"] <= 0 then
                    self.currentCoolDown = 0
                    self:setEverydayBtnGray()
                    self.rootItems.coolDown:setString(ui.makeTimeDayText(0, "hour"))

                    if gameTimer.times["PoolingServersOnline"] then
                        gameTimer:UnrigistTimeFunc("PoolingServersOnline")
                    end
                else
                    self.rootItems.coolDown:setString(ui.makeTimeDayText(gameTimer.times["PoolingServersOnline"], "hour"))
                end
            end)
        end
    end
end

function poolingServersOnline.createTimer(self)
    local _diffTime = self:getDiffTime()
    
    if _diffTime and _diffTime > 0 then
        gameTimer:rigistTime("PoolingServersOnlineFinal", _diffTime)

        if gameTimer.times["PoolingServersOnlineFinal"] and gameTimer.times["PoolingServersOnlineFinal"] > 0 then
            gameTimer:rigistTimeFunc("PoolingServersOnlineFinal", function()
                if gameTimer.times["PoolingServersOnlineFinal"] <= 0 then
                    ui.setLabelString(self.rootItems.time, ui.makeTimeDayText(gameTimer.times["PoolingServersOnlineFinal"], "day"), 64)
                    if gameTimer.times["PoolingServersOnlineFinal"] then
                        gameTimer:UnrigistTimeFunc("PoolingServersOnlineFinal")
                    end
                else
                    ui.setLabelString(self.rootItems.time, ui.makeTimeDayText(gameTimer.times["PoolingServersOnlineFinal"], "day"), 64)
                end
            end)
        end
    end
end

function poolingServersOnline.getDiffTime(self)
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

function poolingServersOnline.setRewardCheck(self)
    self:setEveryDayRewardCheck()
    self:setTotalRewardCheck()
end

function poolingServersOnline.setEveryDayRewardCheck(self)
    for i = 1, self.rewardCount do
        local _key_Ex = ""

        if i == 1 then
            _key_Ex = ""
        else
            _key_Ex = "_"..(i - 1)
        end


        if i < self.currentGift or self.currentGift == -1 then
            self.rootItems["i_select".._key_Ex]:setVisible(true)
            ui.addGray("CCSprite", self.rootItems["i_quality".._key_Ex])
            ui.addGray("CCSprite", self.rootItems["i_icon".._key_Ex])
        else
            self.rootItems["i_select".._key_Ex]:setVisible(false)
            ui.removeGray("CCSprite", self.rootItems["i_quality".._key_Ex])
            ui.removeGray("CCSprite", self.rootItems["i_icon".._key_Ex])
        end
    end
end

function poolingServersOnline.setTotalRewardCheck(self)
    for i = 1, self.totalRewardCount do
        local _key_Ex = "_"..(i - 1 + self.rewardCount)

        if self.totalReward[tostring(i)] == 2 then
            self.rootItems["i_select".._key_Ex]:setVisible(true)
            ui.addGray("CCSprite", self.rootItems["i_quality".._key_Ex])
            ui.addGray("CCSprite", self.rootItems["i_icon".._key_Ex])
        else
            self.rootItems["i_select".._key_Ex]:setVisible(false)
            ui.removeGray("CCSprite", self.rootItems["i_quality".._key_Ex])
            ui.removeGray("CCSprite", self.rootItems["i_icon".._key_Ex])
        end

        self.rootItems["totalCount"..i]:setString("("..self.totalGet.."/"..self.suitLineFilesConfig[tostring(i)].day..")")
    end
end

function poolingServersOnline.setBtnGray(self)
    self:setEverydayBtnGray()
    self:setTotalBtnGray()
end

function poolingServersOnline.setEverydayBtnGray(self)
    for i = 1, self.rewardCount do
        if self.currentGift == -1 then
            self:setEverydayBtnGray2(true, i)
        else
            if i < self.currentGift then
                self:setEverydayBtnGray2(true, i)
            elseif self.currentGift == i then
                if self.currentCoolDown == 0 then
                    self:setEverydayBtnGray2(false, i)
                else
                    self:setEverydayBtnGray2(true, i)
                end
            else
                self:setEverydayBtnGray2(true, i)
            end
        end
    end
end

function poolingServersOnline.setEverydayBtnGray2(self, isGray, num)
    if isGray == true then
        ui.addGray("CCControlButton", self.rootItems["getBtn"..num])
    else
        ui.removeGray("CCControlButton", self.rootItems["getBtn"..num])
    end
end

function poolingServersOnline.setTotalBtnGray(self)
    for i = 1, self.totalRewardCount do
        if self.totalReward[tostring(i)] == 1 then
            ui.removeGray("CCControlButton", self.rootItems["getBtn"..(i + self.rewardCount)])
        else
            ui.addGray("CCControlButton", self.rootItems["getBtn"..(i + self.rewardCount)])
        end
    end
end

function poolingServersOnline.setBtn(self)
    self:setEverydayBtn()
    self:setTotalBtn()
end

function poolingServersOnline.setEverydayBtn(self)
    for i = 1, self.rewardCount do
        local _cb = function()
            if i < self.currentGift then

            elseif self.currentGift == i then
                if self.currentCoolDown == 0 then
                    UIRequest({type = 6106, rewardType = 0})
                else

                end
            else

            end
        end

        self:commonBtn(self.rootItems, "getBtn"..i, _cb)
    end
end

function poolingServersOnline.setTotalBtn(self)
    for i = 1, self.totalRewardCount do
        local _cb = function()
            if self.totalReward[tostring(i)] == 0 then

            elseif self.totalReward[tostring(i)] == 1 then
                UIRequest({type = 6106, rewardType = 1, id = i})
            elseif self.totalReward[tostring(i)] == 2 then

            end
        end

        self:commonBtn(self.rootItems, "getBtn"..(i + self.rewardCount), _cb)
    end
end

-- 通用按钮
function poolingServersOnline.commonBtn(self, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)

    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(touchPriority or (self.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return poolingServersOnline   E.  