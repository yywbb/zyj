--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/26
-- Time: 下午6:47
-- To change this template use File | Settings | File Templates.
--

local dragonboat = {
    buttontouch = -103,

    m_iUsedOnce = nil, -- 单次消耗
    
    m_iWinnerIndex = nil,
    m_iHasNum = nil,

    m_iRunNowIndex = nil, -- 当前比赛
    m_iBeganIndex = nil, -- 进入下标
    m_iTotalTimes = nil, -- 比赛总时间
    m_tPointArray = nil,
    m_tMingciArray = nil,
    m_iPreFrist = nil,
    tmpAction = {{},{},{}},

}

local QRIL_MAX_BOAT_NUM = 3
local QRIL_BASE_TIME = 5 -- 5秒一个间隔
local QRIL_DRAGON_POINT = {-540,-140,140,540}
local QRIL_DEBUG_ANIMATION = false
local QRIL_DEBUG_INDEX = 1

function dragonboat.init(self,size)
    self.contentsize = size
    self.show = true
    self.m_iWinnerIndex = 0
    self.m_iHasNum = 0
    self.m_iPreFrist = 0
    -- 毒镖
    local tmpWinData = ui.getIDRandNums(gamedata.config.dragonBoatRace_guessReward["1"]["win_reward"])
    local tmpLosData = ui.getIDRandNums(gamedata.config.dragonBoatRace_guessReward["1"]["fail_reward"])
    local tmpCid,tmpNums = ui.getIDandNUM(gamedata.config.dragonBoatRace_guessReward["1"]["use"])
    local tmpTimes11 = ui.getIDRandNum(gamedata.config.dragonBoatRace_guessReward["1"]["time1"])
    local tmpTimes12 = ui.getIDRandNum(gamedata.config.dragonBoatRace_guessReward["1"]["time2"])
    local tmpTimes13 = ui.getIDRandNum(gamedata.config.dragonBoatRace_guessReward["1"]["time3"])
    local tmpTimes21 = ui.getIDRandNum(gamedata.config.dragonBoatRace_guessReward["2"]["time1"])
    local tmpTimes22 = ui.getIDRandNum(gamedata.config.dragonBoatRace_guessReward["2"]["time2"])
    local tmpTimes23 = ui.getIDRandNum(gamedata.config.dragonBoatRace_guessReward["2"]["time3"])

    if QRIL_DEBUG_ANIMATION then
        tmpTimes11[1] = 18
        tmpTimes11[2] = 23

        tmpTimes12[1] = tmpTimes11[1]
        tmpTimes12[2] = tmpTimes11[2] + 1

        tmpTimes13[1] = tmpTimes12[1] + 1
        tmpTimes13[2] = tmpTimes12[2] + 1

        tmpTimes21[1] = tmpTimes13[1]
        tmpTimes21[2] = tmpTimes13[2] + 1

        tmpTimes22[1] = tmpTimes21[1]
        tmpTimes22[2] = tmpTimes21[2] + 1

        tmpTimes23[1] = tmpTimes22[1]
        tmpTimes23[2] = tmpTimes22[2] + 1
    end
    self.m_iTotalTimes = {ui.getTimeReducing(tmpTimes12,tmpTimes13),ui.getTimeReducing(tmpTimes22,tmpTimes23)}
    self.m_iBeganTimes = {ui.getDragonTime(tmpTimes12),ui.getDragonTime(tmpTimes22)}
    self.m_iWaitTimes = {ui.getDragonTime(tmpTimes11),ui.getDragonTime(tmpTimes21)}
    self.m_iEndsTimes = {ui.getDragonTime(tmpTimes13),ui.getDragonTime(tmpTimes23)}
    self.m_iUsedOnce = tmpNums

    self.coverccb, self.coveritems = CCBReaderLoad("activityduanwu/activityduanwu_dragonboat",nil, true, "dragonboat")
    self.animationManager = getAnimationManager(self.coveritems)
    self.coveritems.topnode:setPositionY(self.contentsize.y-180)

    ui.setLabelString(self.coveritems.m_oTipall,nil,14)
    ui.setLabelString(self.coveritems.time,nil,26)

    -- 船
    for i=1,3 do
        self["m_iStake"..i] = 0
        ui.setLabelString(self.coveritems["m_oStake"..i],tostring(self.m_iUsedOnce),21)
        ui.setLabelString(self.coveritems["m_oBtName"..i],nil,19)
        ui.setLabelString(self.coveritems["m_oTips"..i],nil,14)
        self["m_oBoatccb"..i], self["m_oBoatItem"..i] = CCBReaderLoad("UIEffect/longzhou/longzhou"..i,nil, true, "dragonboat"..i)
        self["m_oAm"..i] = getAnimationManager(self["m_oBoatItem"..i])
        self.coveritems["m_oBoatNode"..i]:addChild(self["m_oBoatccb"..i])
    end

    -- 浪
    for i=1,6 do
        self["m_oLangccb"..i], self["m_oLangItem"..i] = CCBReaderLoad("activityduanwu/activityduanwu_langhua",nil, true, "langhua")
        self["m_oLangAm"..i] = getAnimationManager(self["m_oLangItem"..i])
        self.coveritems["m_oLang"..i]:addChild(self["m_oLangccb"..i])
    end

    -- 山
    self.shanccb, self.shanItem = CCBReaderLoad("activityduanwu/activityduanwu_shan",nil, true, "duanwushan")
    self.shananimation = getAnimationManager(self.shanItem)
    self.coveritems.shan_node:addChild(self.shanccb)


    self.coveritems.rulebutton:setTouchPriority(self.buttontouch)
    self.coveritems.rulebutton:addHandleOfControlEvent(function ()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameWindows:openWindow("dragonboatrule",{windata = tmpWinData,
                                                losdata = tmpLosData,
                                                time1 = {tmpTimes11,tmpTimes12,tmpTimes13},
                                                time2 = {tmpTimes21,tmpTimes22,tmpTimes23},}
                            ,nil) 
    end, CCControlEventTouchUpInside)

    -- 初始化模拟数据began
    self:initArray()
    -- 结束初始化数据ends
    return self.coverccb
end

function dragonboat.initArray(self)
    local function tmpRedOnce(destPreNum)
        local tmpReturnNum = destPreNum
        repeat
            tmpReturnNum = 1 + (math.floor(math.random()*100)%#QRIL_DRAGON_POINT)
        until destPreNum ~= tmpReturnNum
        return tmpReturnNum
    end
    local tmpOnce = math.floor(self.m_iTotalTimes[1]/QRIL_BASE_TIME)
    self.m_tPointArray = {{},{},{}}
    for i=1,tmpOnce do
        if i == tmpOnce then
            table.insert(self.m_tPointArray[1],4)
            local tmpSec = 0
            if (math.floor(math.random()*100)%2) == 0 then
                tmpSec = 3
            else
                tmpSec = 2
            end
            table.insert(self.m_tPointArray[2],tmpSec)
            if tmpSec == 3 then
                if (math.floor(math.random()*100)%2) == 0 then
                    table.insert(self.m_tPointArray[3],2)
                else
                    table.insert(self.m_tPointArray[3],1)
                end
            else
                table.insert(self.m_tPointArray[3],1)
            end
        else
            local tmpIndex1 = (i == 1 and 0) or self.m_tPointArray[1][i - 1]
            local tmpIndex2 = (i == 1 and 0) or self.m_tPointArray[2][i - 1]
            local tmpIndex3 = (i == 1 and 0) or self.m_tPointArray[3][i - 1]
            table.insert(self.m_tPointArray[1],tmpRedOnce(tmpIndex1))
            table.insert(self.m_tPointArray[2],tmpRedOnce(tmpIndex2))
            table.insert(self.m_tPointArray[3],tmpRedOnce(tmpIndex3))
        end
    end
    -- for i,v in ipairs(self.m_tPointArray) do
    --     print("第===="..i.."条船")
    --     for j,k in ipairs(v) do
    --         print("第==="..j.."==步===:",k)
    --     end
    -- end
end

function dragonboat.resetMingCi(self)
    self.m_tMingciArray = {}
    self.m_tMingciArray[self.m_iWinnerIndex] = 1
    if self.m_iWinnerIndex == 1 then
        if (math.floor(math.random()*100)%2) == 0 then
            self.m_tMingciArray[2] = 2
            self.m_tMingciArray[3] = 3
        else
            self.m_tMingciArray[2] = 3
            self.m_tMingciArray[3] = 2
        end
    elseif self.m_iWinnerIndex == 2 then
        if (math.floor(math.random()*100)%2) == 0 then
            self.m_tMingciArray[1] = 2
            self.m_tMingciArray[3] = 3
        else
            self.m_tMingciArray[1] = 3
            self.m_tMingciArray[3] = 2
        end
    else
        if (math.floor(math.random()*100)%2) == 0 then
            self.m_tMingciArray[2] = 2
            self.m_tMingciArray[1] = 3
        else
            self.m_tMingciArray[2] = 3
            self.m_tMingciArray[1] = 2
        end
    end
end

function dragonboat.resetAction(self)
    local tmpReturnNum = 0
    local beginD = gamedata.config.activity_time["40"]["begin"]
    local endD = gamedata.config.activity_time["40"]["end"]
    local now = gamedata:time()
    local nowtime = os.date("*t", now)


    local b_year,b_month,b_day,b_hour,b_minute,b_second = ui.getDate(beginD)
    local e_year,e_month,e_day,e_hour,e_minute,e_second = ui.getDate(endD)

    local begint = os.time({year=tonumber(b_year), month=tonumber(b_month),day=tonumber(b_day),hour=tonumber(b_hour),min=tonumber(b_minute),sec=tonumber(b_second)})
    local endt = os.time({year=tonumber(e_year), month=tonumber(e_month),day=tonumber(e_day),hour=tonumber(e_hour),min=tonumber(e_minute),sec=tonumber(e_second)})

    local tmpWaitTimes = ui.getDragonTime({nowtime.hour,nowtime.min}) + nowtime.sec - self.m_iWaitTimes[self.m_iRunNowIndex]
    local tmpBeganTime = ui.getDragonTime({nowtime.hour,nowtime.min}) + nowtime.sec -self.m_iBeganTimes[self.m_iRunNowIndex]
    local tmpEndsTimes = ui.getDragonTime({nowtime.hour,nowtime.min}) + nowtime.sec - self.m_iEndsTimes[self.m_iRunNowIndex]
    if now < begint then -- 还没开始
        tmpReturnNum = -1
    elseif now > endt then -- 已经结束
        tmpReturnNum = -2
    else -- 可以进行
        if tmpWaitTimes < 0 then -- 还没开始
            tmpReturnNum = 0
        elseif tmpWaitTimes >= 0 and tmpBeganTime < 0 and tmpEndsTimes < 0 then -- 可以开始投注了
            tmpReturnNum = 1
        elseif tmpBeganTime >= 0 and tmpEndsTimes < 0 then -- 开始比赛了
            tmpReturnNum = 2
        elseif tmpEndsTimes >= 0 then -- 比赛结束
            tmpReturnNum = 3
        end
    end

    print("tmpReturnNum=====:",tmpReturnNum,tmpWaitTimes,tmpBeganTime,tmpEndsTimes,self.m_iRunNowIndex)

    for i=1,3 do
        if i == self.m_iPreFrist then
            self["m_oBoatItem"..i].m_oPreFrist:setVisible(true)
        else
            self["m_oBoatItem"..i].m_oPreFrist:setVisible(false)
        end
    end
    if tmpReturnNum == 2 then
        self.animationManager:runAnimationsForSequenceNamed("play")
        self.shananimation:runAnimationsForSequenceNamed("play")

        for i=1,6 do
            self["m_oLangAm"..i]:runAnimationsForSequenceNamed("play")
        end
    else
        if tmpReturnNum == 1 then -- free
            self.animationManager:runAnimationsForSequenceNamed("free")
        else
            self.animationManager:runAnimationsForSequenceNamed("wait")
        end
        self.shananimation:runAnimationsForSequenceNamed("free")
        for i=1,3 do
            self.coveritems["m_oBoatNode"..i]:stopAllActions()
            self.coveritems["m_oBoatNode"..i]:setPositionX(QRIL_DRAGON_POINT[2])
            self["m_oAm"..i]:runAnimationsForSequenceNamed("0")
        end
        for i=1,6 do
            self["m_oLangAm"..i]:runAnimationsForSequenceNamed("free")
        end
    end
    if tmpReturnNum == -1 or tmpReturnNum == -2 then
        self.coveritems.time:setVisible(false)
        self.coveritems.times_name:setVisible(false)
    else
        self.coveritems.time:setVisible(true)
        self.coveritems.times_name:setVisible(true)
        if gameTimer.times.dragonboat_rewardtime then
            gameTimer:UnrigistTimeFunc("dragonboat_rewardtime")
        end
        local remaintime = 0
        local tmpStr = ""
        if tmpReturnNum == 0 then
            tmpStr = "距押注开始："
            remaintime = -tmpWaitTimes
        elseif tmpReturnNum == 1 then
            tmpStr = "距比赛开始："
            remaintime = -tmpBeganTime
        elseif tmpReturnNum == 2 then
            tmpStr = "距比赛结束："
            remaintime = -tmpEndsTimes
        elseif tmpReturnNum == 3 then
            local tmpShi1,tmpFen1,tmpMiao1 = ui.getTimeDragon(self.m_iWaitTimes[1])
            local tmpNextTimes = os.time({year=nowtime.year, month=nowtime.month,day=nowtime.day+1,
                                    hour=tmpShi1,
                                    min=tmpFen1,
                                    sec=tmpMiao1})
            if tmpNextTimes - now + self.m_iWaitTimes[self.m_iRunNowIndex] > endt - now then -- 超过时间了
                tmpStr = "距活动结束："
                remaintime = endt - now
            else
                tmpStr = "距押注开始："
                remaintime = tmpNextTimes - now + self.m_iWaitTimes[self.m_iRunNowIndex]
            end
        end
        remaintime = remaintime + 1
        ui.setLabelString(self.coveritems.times_name,tmpStr,14)
        gameTimer:rigistTime("dragonboat_rewardtime", remaintime)
        gameTimer:rigistTimeFunc("dragonboat_rewardtime",function()
        
            if gameTimer.times["dragonboat_rewardtime"] >= 0 then
                ui.setLabelString(self.coveritems.time,ui.makeTimeText(gameTimer.times["dragonboat_rewardtime"],"hour"),26)
            end
            if gameTimer.times["dragonboat_rewardtime"] == 0 then
                gameTimer:UnrigistTimeFunc("dragonboat_rewardtime")
                UIRequest({type = 3901})
            end
        end)

        if tmpReturnNum == 1 or tmpReturnNum == 2 then
            self.m_iBeganIndex = ui.getDragonTime({nowtime.hour,nowtime.min}) + nowtime.sec - self.m_iBeganTimes[self.m_iRunNowIndex]
        end
    end

    return tmpReturnNum
end

function dragonboat.reloaddata(self,data)
    local nowtime = os.date("*t", gamedata:time())
    self.m_iHasNum = data._ids["1"]
    self.m_iWinnerIndex = data._ids["2"]
    self.m_iRunNowIndex = data._ids["6"]
    self.m_iPreFrist = data._ids["7"]
    if QRIL_DEBUG_ANIMATION then
        self.m_iWinnerIndex = 2
        self.m_iRunNowIndex = QRIL_DEBUG_INDEX
    end
    ui.setLabelString(self.coveritems.m_oHasNum,tostring(self.m_iHasNum),21)
    local tmpRunTimes = self:resetAction()
    if tmpRunTimes == 2 or tmpRunTimes == 1 then
        if self.m_iWinnerIndex ~= 0 and self.m_iBeganIndex >= 0 and self.m_iBeganIndex < self.m_iTotalTimes[self.m_iRunNowIndex] then
            self:resetMingCi()
            self:play()
        else
            for i=1,3 do
                self["m_iStake"..i] = data._ids[""..2+i]
                ui.setLabelString(self.coveritems["m_oHasStake"..i],tostring(self["m_iStake"..i]),21)
                self.coveritems["m_oBtStake"..i]:addHandleOfControlEvent(function ()
                    if GameScene.layers["activity"].module.isContentScroll then  return end
                    if self.m_iHasNum > 0 then
                        gameTouch:clickprofbytime(0.5)
                        UIRequest({type = 3902,ids = {i}})
                    else
                        gameWindows:openWindow("dropTips",{cid = 1010},nil)
                        -- runGamePrompt({msg = gameConfig.strings:string_common("dragonboat",2)})
                    end
                end, CCControlEventTouchUpInside)
            end
        end
    end
end

function dragonboat.play(self,data)
    local function tmpRunDone()
        for i,v in ipairs(self.m_tMingciArray) do
            if v == 1 then
                runGamePrompt({msg=string.format(gameConfig.strings:string_common("dragonboat",1),i)})
                break
            end
        end
        if QRIL_DEBUG_ANIMATION then
            QRIL_DEBUG_INDEX = QRIL_DEBUG_INDEX + 1
            if QRIL_DEBUG_INDEX > 2  then
                QRIL_DEBUG_INDEX = 1
            end
        end
    end
    local tmpBis = self.m_iBeganIndex/self.m_iTotalTimes[self.m_iRunNowIndex]
    local tmpTiaoWid = self.coveritems.m_optiao:getContentSize().width - self.coveritems.m_odian:getContentSize().width
    self.coveritems.m_odian:setPositionX(tmpTiaoWid*tmpBis)
    local tmpdianAction = CCSequence:createWithTwoActions(CCMoveTo:create(self.m_iTotalTimes[self.m_iRunNowIndex]-self.m_iBeganIndex,ccp(tmpTiaoWid,0)),
                                                          CCCallFuncN:create(tmpRunDone))
    self.coveritems.m_odian:runAction(tmpdianAction)
    local function getSpeedFuc(destType,destNum)
        local tmpDoingNum = destNum
        if destNum == 3 then
            tmpDoingNum = 3
        elseif destNum == -3 then
            tmpDoingNum = 0
        elseif destNum > 0 and destNum  < 3 then
            tmpDoingNum = 2
        else
            tmpDoingNum = 1
        end
        local function returnFuc()
            self["m_oAm"..destType]:runAnimationsForSequenceNamed(""..tmpDoingNum)
        end
        return returnFuc
    end
    local tmpTotalLens = #self.m_tPointArray[1]
    local tmpBeganIndex = math.ceil(self.m_iBeganIndex/QRIL_BASE_TIME) + 1

    self:releaseAction()
    local tmpPointY = {self.coveritems.m_oBoatNode1:getPositionY(),
                       self.coveritems.m_oBoatNode2:getPositionY(),
                       self.coveritems.m_oBoatNode3:getPositionY()}
    local tmpPointX = {2,2,2}
    local function tmpDoOnceAction(tmpDoIndex,i)
        local tmpIndexfirst = self.m_tMingciArray[tmpDoIndex]

        local action1 = CCCallFuncN:create(getSpeedFuc(tmpDoIndex,self.m_tPointArray[tmpIndexfirst][i] - tmpPointX[tmpDoIndex]))
        action1:retain()
        local action2 = CCMoveTo:create(QRIL_BASE_TIME,
            ccp(QRIL_DRAGON_POINT[self.m_tPointArray[tmpIndexfirst][i]],tmpPointY[tmpDoIndex]))
        action2:retain()

        table.insert(self.tmpAction[tmpDoIndex], action1)
        table.insert(self.tmpAction[tmpDoIndex], action2)
        tmpPointX[tmpDoIndex] = self.m_tPointArray[tmpIndexfirst][i]
    end
    for i=tmpBeganIndex,tmpTotalLens do
        tmpDoOnceAction(1,i)
        tmpDoOnceAction(2,i)
        tmpDoOnceAction(3,i)
    end


    local func = nil
    func = function (node,actions)
        local action = table.remove(actions,1)
        if action then
            node:runAction(CCSequence:createWithTwoActions(action, CCCallFunc:create(function()
                func(node,actions)
            end)))
        end
    end

    func(self.coveritems.m_oBoatNode1,self.tmpAction[1])
    func(self.coveritems.m_oBoatNode2,self.tmpAction[2])
    func(self.coveritems.m_oBoatNode3,self.tmpAction[3])
end

function dragonboat.updatetimeFunc( self )
    local nowtime = os.date("*t", gamedata:time())
    local remaintime = 0

    local isnow,remaintime = ui.checkDateActive(gamedata.config.activity_time["38"]["begin"],gamedata.config.activity_time["38"]["end"])
    -- local year,month,day,hour,minute,second = ui.getDate(gamedata.config.activity_time["38"]["end"])
    print("isnow,remaintime===",isnow,remaintime)
    if not isnow then
        return
    end

end


function dragonboat.releaseAction(self)
    for i=1,3 do
        for k,v in ipairs(self.tmpAction[i]) do
            v:release()
        end
    end
    self.tmpAction = {{},{},{}}
end

function dragonboat.clear(self)
    self.show = false
    gameTimer:UnrigistTimeFunc("dragonboat_rewardtime")
    gameTimer:UnrigistTimeFunc("dragonboat_updateboat")
    self.coverccb = nil
    self.coveritems = nil
    self.animationManager = nil
    for i=1,3 do
        self["m_oBoatItem"..i] = nil
        self["m_oBoatccb"..i] = nil
        self["m_oAm"..i] = nil
    end
    for i=1,6 do
        self["m_oLangItem"..i] = nil
        self["m_oLangccb"..i] = nil
        self["m_oLangAm"..i] = nil
    end
    self.shanccb = nil
    self.shanItem = nil
    self.shananimation = nil

    self.m_tPointArray = nil
    self.m_iTotalTimes = nil
    self.m_iBeganTimes = nil
    self.m_iWaitTimes = nil
    self.m_iEndsTimes = nil
    self.m_iUsedOnce = nil

    self.m_iRunNowIndex = nil
    self.m_iBeganIndex = nil
    self.m_iTotalTimes = nil
    self.m_tPointArray = nil
    self.m_tMingciArray = nil

    self:releaseAction()
end


return dragonboatLK  