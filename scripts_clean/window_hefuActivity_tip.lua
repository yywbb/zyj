--
-- Author: songyibo
-- Date: 2019-12-20 09:56:25
--

local hefuActivity_tip = {
    rootNode = nil,
    rootItems = nil,
    needcallback = true,
    data = {},
    pageconfig = {"165","164","119","120","121"},
    sysconfig = {582,581,393,394,395},
    page = "165",
    pageindex = 1,
    activityid = 165,
    sysid = 582,

    cancelTip = "hefuActivity"
}

function hefuActivity_tip.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("activityhefu/hefutuisong", nil, true, "hefutuisong")

    self.touchPriority = touchPriority

    ui.setLabelString(self.rootItems.goLab,nil,18)
    ui.setLabelString(self.rootItems.desc1,nil,18,30)

    for km,vm in ipairs(self.pageconfig) do
        ui.setLabelString(self.rootItems["btn_text"..km],nil,18,30)
        self.rootItems["button"..km]:setSwallowsTouch(true)
        self.rootItems["button"..km]:setTouchPriority(self.touchPriority)
        self.rootItems["button"..km]:addHandleOfControlEvent(function()
            self.pageindex = km
            print("pageindex == ",self.pageindex)
            self.activityid = tonumber(self.pageconfig[self.pageindex])
            self.sysid = self.sysconfig[self.pageindex]
            self:setHeFuButton(self.pageindex)
        end, CCControlEventTouchUpInside)
    end

    self:reload(data,callback)

    return self.rootNode
end

function hefuActivity_tip.reload(self,data,callback)
    self.callback = callback

    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("hefuActivity")
    end, CCControlEventTouchUpInside)

    self.rootItems.goButton:setSwallowsTouch(true)
    self.rootItems.goButton:setTouchPriority(self.touchPriority)
    self.rootItems.goButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("hefuActivity")
        GameScene:shiftLayerById(self.sysid)
    end, CCControlEventTouchUpInside)

    self:setHeFuButton(self.pageindex)

    self.day = data.day
    --设置时间
    self:createTimer()

end

function hefuActivity_tip.setHeFuButton(self, index)
    setSpriteFrameByName(self.rootItems.bg, "hefutuisongbg_"..index)
    self.page = self.pageconfig[index]
    for km,vm in ipairs(self.pageconfig) do
        if vm == self.page then
            setSpriteFrameByName(self.rootItems["btn_image"..km], "hefuButton_h")
        else
            setSpriteFrameByName(self.rootItems["btn_image"..km], "hefuButton")
        end
    end
end

function hefuActivity_tip.createTimer(self)
    local _diffTime = self:getDiffTime()
    if _diffTime and _diffTime > 0 then
        gameTimer:rigistTime("hefuActivityTime", _diffTime)

        if gameTimer.times["hefuActivityTime"] and gameTimer.times["hefuActivityTime"] > 0 then
            gameTimer:rigistTimeFunc("hefuActivityTime", function()
                if gameTimer.times["hefuActivityTime"] <= 0 then
                    ui.setLabelString(self.rootItems.time, ui.makeTimeDayText(gameTimer.times["hefuActivityTime"], "day"), 23)
                    
                    if gameTimer.times["hefuActivityTime"] then
                        gameTimer:UnrigistTimeFunc("hefuActivityTime")
                    end
                else
                    ui.setLabelString(self.rootItems.time, ui.makeTimeDayText(gameTimer.times["hefuActivityTime"], "day"), 23)
                end
            end)
        end
    end
end

function hefuActivity_tip.getDiffTime(self)
    -- 活动时间
    local _timediff = 0
    local _activityId = tostring(self.activityid)
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

function hefuActivity_tip.close(self)

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.pageindex = 1

    gameTimer:UnrigistTime("hefuActivityTime")
    gameTimer:UnrigistTimeFunc("hefuActivityTime")

    if self.callback then
        self.callback()
        self.callback = nil
    end
end

return hefuActivity_tip