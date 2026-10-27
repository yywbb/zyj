--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/31
-- Time: 上午10:58
-- To change this template use File | Settings | File Templates.
--

local passkill = {

    rootNode = nil,
    rootItems = nil,
    buttontouch = -101,

    passkilldata = {},
    firstnum = 0,
    isopen = false,

    isauto = false,


    pi = math.pi,
    ScaleY = math.sin(math.pi/5.5),
    R = 400,
    Scale = 0.45,
    angle = 2*math.pi/3,
    slotpos = {},
    rotaAngle =0,
    frontid = 1,

}

function passkill.findZorder(self,angle)
    local pi = self.pi
    if math.abs(angle) > 2*pi then
        angle = math.mod(angle,2*pi)
    end

    if angle<0 then
        angle = angle + 2*self.pi
    end
    if angle> pi/7 and angle<= 3*pi/7 then
        return 4
    elseif angle> 3*pi/7 and angle<= 5*pi/7 then
        return 3
    elseif angle> 5*pi/7 and angle<= 7*pi/7 then
        return 2
    elseif angle> 7*pi/7 and angle<= 9*pi/7 then
        return 2
    elseif angle> 9*pi/7 and angle<= 11*pi/7 then
        return 3
    elseif angle> 11*pi/7 and angle<= 13*pi/7 then
        return 4
    else
        return 5
    end
end

function passkill.setOneSlot(self,i)
    self.slotpos[i].x = self.R*math.sin(self.slotpos[i].angle)
    self.slotpos[i].y = -self.R*math.cos(self.slotpos[i].angle)
    self.slotpos[i].sx = 1-(1-self.Scale)*(self.slotpos[i].y+self.R)/(2*self.R)
    self.slotpos[i].sy = self.slotpos[i].sx/self.ScaleY

    self.rootItems["slot"..i]:setPosition(self.slotpos[i].x, self.slotpos[i].y)
    self.rootItems["slot"..i]:setScaleX(self.slotpos[i].sx)
    self.rootItems["slot"..i]:setScaleY(self.slotpos[i].sy)

    local Zorder   =  self:findZorder(self.slotpos[i].angle)
    self.rootItems["slot"..i]:setZOrder(Zorder)
    -- self.slotpos[i].item.button_slot:setSwallowsTouch(true)
    -- self.slotpos[i].item.button_slot:setTouchPriority(-Zorder)
    -- if self.slotpos[i].item.namenode then
    --     self.slotpos[i].item.namenode:setVisible(i==self.frontid)
    -- end
end

function passkill.initSlot(self)
    self.rootItems.slotNode:setScaleY(self.ScaleY)

    for i=1,3 do
        self.slotpos[i]={}
        self.slotpos[i].angle = (i-1)*self.angle
        self:setOneSlot(i)
    end

    self:setSlot()
    self:frontshow(frontid)
end

function passkill.frontshow(self,id)
    self.frontid = id or self.frontid
end

function passkill.setSlot(self)
    self.rootItems.rotanode:setRotation(-math.deg(self.rotaAngle))
    for i=1,3 do
        self.slotpos[i].angle = (i-1)*self.angle + self.rotaAngle

        local x  =  self.R*math.sin(self.slotpos[i].angle)
        local y  =  -self.R*math.cos(self.slotpos[i].angle)
        self.slotpos[i].sx = 1-(1-self.Scale)*(y+self.R)/(2*self.R)
        self.slotpos[i].sy = self.slotpos[i].sx/self.ScaleY

        self.rootItems["slot"..i]:setRotation(math.deg(self.rotaAngle))
        self.rootItems["slot"..i]:setScaleX(self.slotpos[i].sx)
        self.rootItems["slot"..i]:setScaleY(self.slotpos[i].sy)
        self.rootItems["slot"..i]:setZOrder(self:findZorder(self.slotpos[i].angle))
        -- if self.slotpos[i].item.namenode then
        --     self.slotpos[i].item.namenode:setVisible(i==self.frontid)
        -- end
    end
end



function passkill.init(self,parent,toppos,param)

    self.rootNode,self.rootItems = CCBReaderLoad("passkill/passkill", nil, true, "passkill")
    parent:addChild(self.rootNode)

   
    self.rootItems.topnode:setPositionY(toppos)
    
    self.rootItems.showNode:setPositionY((toppos-550-315)/2+315)

    local phoName = CCSprite:create("public/publicsprite/spr_115.png")

    self.rootItems.starbarProcess = CCProgressTimer:create(phoName)
    self.rootItems.starbarProcess:setAnchorPoint(ccp(0.0, 0.5))
    self.rootItems.starbarProcess:setType(kCCProgressTimerTypeBar)
    self.rootItems.starbarProcess:setMidpoint(ccp(0, 0.5))
    self.rootItems.starbarProcess:setBarChangeRate(ccp(1, 0))
    self.rootItems.starbarProcess:setPosition(ccp(-370.0, 3))
    self.rootItems.starbarProcess:setPercentage(0)
    self.rootItems.starbarProcess:setScaleX(1.0)
    self.rootItems.starbarNode:addChild(self.rootItems.starbarProcess)
   
    -- 说明 规则
    self.rootItems.rulebutton:setTouchPriority(self.buttontouch)
    self.rootItems.rulebutton:setSwallowsTouch(true)
    self.rootItems.rulebutton:addHandleOfControlEvent(function()
        print("rulebutton=")    
        ui.popCommonRule(175)
    end, CCControlEventTouchUpInside)

    -- 去商店按钮
    self.rootItems.shopBtn:setTouchPriority(self.buttontouch)
    self.rootItems.shopBtn:setSwallowsTouch(true)
    self.rootItems.shopBtn:addHandleOfControlEvent(function()
        print("shopBtn=")   
        
        GameScene:shiftLayerById(185)
        -- gameWindows:openWindow("passkillrank",{index= "rank"},nil) 
    end, CCControlEventTouchUpInside)


    --战斗记录
    self.rootItems.recordBtn:setTouchPriority(self.buttontouch)
    self.rootItems.recordBtn:setSwallowsTouch(true)
    self.rootItems.recordBtn:addHandleOfControlEvent(function()
        gameWindows:openWindow("overpassRecord") 
    end, CCControlEventTouchUpInside)

    self.rootItems.common_back_btn:setSwallowsTouch(true)
    self.rootItems.common_back_btn:setTouchPriority(self.buttontouch)
    self.rootItems.common_back_btn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("daily")
    end, CCControlEventTouchUpInside)

    --
    if self.rootItems.autobutton then
        self.rootItems.autosprite:setVisible(self.isauto)
        self.rootItems.autobutton:setTouchPriority(self.buttontouch)
        self.rootItems.autobutton:setSwallowsTouch(true)
        self.rootItems.autobutton:addHandleOfControlEvent(function()
            self.isauto = not self.isauto
            self.rootItems.autosprite:setVisible(self.isauto)
        end, CCControlEventTouchUpInside)
    end

    UIRequest({type = 3820})
    self:initTouchLayer()
    self:initSlot()
    self:reloadHint()
end

function passkill.initTouchLayer(self)
    local function ccTouchBegan(x, y)
        self.istouchmove = false
        self.touchpos = {x=x,y=y }
        self.movex = x
        return true
    end

    local function ccTouchMoved(x, y)
       if math.abs(x - self.touchpos.x) > 20 then
            if self.timer then
                CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.timer)
                self.timer = nil
            end

            self.istouchmove = true
            self:moveslot(x - self.movex)
            self.movex = x
        end
    end

    local function ccTouchEnded(x, y)
        if self.istouchmove then
            self:moveSlotAnimation(x - self.movex,x>self.touchpos.x)
        end
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then
            return ccTouchBegan(x, y)
        elseif eventType == "moved" then
            return ccTouchMoved(x, y)
        elseif eventType == "ended" then
            return ccTouchEnded(x, y)
        end
    end

    self.rootItems.touchLayer:registerScriptTouchHandler(onTouch, false, -12, false)
    self.rootItems.touchLayer:setTouchPriority(self.buttontouch)
    self.rootItems.touchLayer:setTouchEnabled(true)
end

function passkill.moveslot(self,dis)
    print("main.moveslot(self,dis)-----------------")
    self.rotaAngle = self.rotaAngle + (dis or 0)*(self.pi/1800)
    self:setSlot()
end

function passkill.moveSlotAnimation(self,dis,direct)
    if math.abs(self.rotaAngle) > 2*self.pi then
        self.rotaAngle = math.mod(self.rotaAngle,2*self.pi)
    end

    if self.rotaAngle<0 then
        self.rotaAngle = self.rotaAngle + 2*self.pi
    end

    local stepdis = (direct and 1 or -1)*100
    local targetAngle =  self.rotaAngle

    for i=1,7 do
        if self.rotaAngle > (i-1)*self.angle and self.rotaAngle <= i*self.angle then
            if direct then
                targetAngle = i*self.angle
                self.frontid = 8-i
            else
                targetAngle = (i-1)*self.angle
                self.frontid = 9-i
            end

            if self.frontid>7 then
                self.frontid = 1
            elseif self.frontid<0 then
                self.frontid = 7
            end
            break
        end
    end

    self.timer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
        local newangle = self.rotaAngle + stepdis*(self.pi/1800)
        if direct then
            if newangle >= targetAngle then
                self.rotaAngle = targetAngle
                self:setSlot()
                self:frontshow()
                CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.timer)
                return
            end
        else
            if newangle <= targetAngle then
                self.rotaAngle = targetAngle
                self:setSlot()
                self:frontshow()
                CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.timer)
                return
            end
        end
        self.rotaAngle = newangle
        self:setSlot()
    end, 0, false)
end

function passkill.reloadHint(self)
    print("reloadHint",GameScene.hintdata["573"])
    if GameScene.hintdata and GameScene.hintdata and GameScene.hintdata["573"] and GameScene.hintdata["573"] ~= 0 then
        self.rootItems.hint_record:setVisible(true)
    else
        self.rootItems.hint_record:setVisible(false)
    end
end


function passkill.reloaddata(self,data)
    -- self.beforeNum = data.xc_dayprogress
    if not data then return end

    self.passkilldata = data
    -- printT(self.passkilldata,"passkilldata===")
    -- printT(gamedata.config.through_param,"through_param===")

    -- print("victorynum===",self.passkilldata.basic.victorynum)
    -- printT(self.rootItems)


    local paramconfig = gamedata.config.through_param[tostring(1)]
    local buycountconfig = gamedata.config.buycount_price

    -- ui.setLabelString(self.rootItems.victorynumText,nil,13)
    ui.setLabelString(self.rootItems.victorynumLabel,self.passkilldata.basic.victorynum,21)

    local canfightnum = paramconfig.challenge_max + GameScene.vipstatus.through_times - self.passkilldata.basic.fightnum
    ui.setLabelString(self.rootItems.canfightnumText,nil,13)
    ui.setLabelString(self.rootItems.canfightnumLabel,canfightnum,21)


    ui.setLabelString(self.rootItems.killcoinnumLabel,self.passkilldata.basic.killcoinnum,21)
    ui.setLabelString(self.rootItems.killscorenumLabel,self.passkilldata.basic.killscorenum,21)

    -- 刷新次数
    local resetnum = paramconfig.refresh_max - self.passkilldata.basic.resetnum

    local buyGoldnum = 0
    if resetnum > 0 then
        self.rootItems.freeNode:setVisible(true)
        self.rootItems.goldNode:setVisible(false)

        ui.setLabelString(self.rootItems.freeresetText,nil,13)
        ui.setLabelString(self.rootItems.freeresetLabel,resetnum,21)
        
    else
        self.rootItems.freeNode:setVisible(false)
        self.rootItems.goldNode:setVisible(true)
        local restnum = self.passkilldata.basic.resetnum
        if self.passkilldata.basic.resetnum >= 59 then
            restnum = 59
        end
        buyGoldnum = buycountconfig[tostring(restnum+1)]["refresh_cost"]

        ui.setLabelString(self.rootItems.resetgold,buyGoldnum,21)
    end


    -- 到积分排名界面 按钮
    ui.setLabelString(self.rootItems.rankText,nil,19)
    self.rootItems.rankBtn:setTouchPriority(self.buttontouch)
    self.rootItems.rankBtn:setSwallowsTouch(true)
    self.rootItems.rankBtn:addHandleOfControlEvent(function()
        print("rankBtn=")    
        
        GameScene:shiftLayer("passkillrank","up")
        -- gameWindows:openWindow("passkillrank",{index= "rule"},nil) 

    end, CCControlEventTouchUpInside)

    -- 刷新按钮
    ui.setLabelString(self.rootItems.resetText,nil,19)
    self.rootItems.resetBtn:setTouchPriority(self.buttontouch)
    self.rootItems.resetBtn:setSwallowsTouch(true)
    self.rootItems.resetBtn:addHandleOfControlEvent(function()
        print("resetBtn=")
        gameTouch:clickprofbytime(1)
        if not self.isopen then
            runGamePrompt({msg = gameConfig.strings:string_common("passkill",3)})
            return
        end

        UIRequest({type = 3826,spend = buyGoldnum})
        -- gameWindows:openWindow("passkillrank",{index= "rule"},nil) 

    end, CCControlEventTouchUpInside)

    -- 倒计时
    ui.setLabelString(self.rootItems.timerLabel,nil,26) 

    -- 设置今日进度条进度
    local processNum = 100*(self.passkilldata.basic.victorynum < paramconfig.challeng_award3 and self.passkilldata.basic.victorynum/paramconfig.challeng_award3 or 1)
    local greento = CCProgressFromTo:create(0.2,self.firstnum,processNum)
    self.rootItems.starbarProcess:runAction(greento)


    self.firstnum = processNum

    -- 设置宝箱信息状态
    for i =1, 3 do
        self:setrewardbox(i)
    end

    -- 设置被挑战者信息
    for i=1,3 do
        self:setFightGenerals(i)
    end

    self:updatetimeFunc()
    
end


function passkill.updatetimeFunc( self )
    local nowtime = os.date("*t", gamedata:time())

    local daynums = (nowtime.wday == 1 and 7 or (nowtime.wday-1))
    local alltimes = (daynums - 1)*24*3600 + nowtime.hour*3600 + nowtime.min*60 + nowtime.sec - 1


    -- 数据统计时间段
    -- local begintimenum = {week=3,hour=17,min=2,sec=0}
    -- local endtimenum = {week=3,hour=17,min=3,sec=0}
    local begintimenum = {week=7,hour=23,min=0,sec=0}
    local endtimenum = {week=7,hour=24,min=0,sec=0}


    -- if nowtime.wday == 1 and nowtime.hour >= 23 and nowtime.hour < 24 then
    if alltimes >= self:gettimenum(begintimenum) and alltimes < self:gettimenum(endtimenum) then
        local remaintime = self:gettimenum(endtimenum) - alltimes
        -- self.rootItems.timerText:setString("统计数据倒计时：")
        self.rootItems.timerText:setString(gameConfig.strings:string_common("passkill",4))

        self.isopen = false
        print("isopen===1111",self.isopen)

        gameTimer:rigistTime("passkill_statisticstime", remaintime)
        gameTimer:rigistTimeFunc("passkill_statisticstime",function()
            if gameTimer.times["passkill_statisticstime"] >= 0 then

                if nowtime.wday == 1 then
                    ui.setLabelString(self.rootItems.timerLabel,ui.makeTimeText(gameTimer.times["passkill_statisticstime"],"hour"),26)
                else
                    ui.setLabelString(self.rootItems.timerLabel,ui.makeTimeDayText(gameTimer.times["passkill_statisticstime"],"day"),26)
                end
            end
            if gameTimer.times["passkill_statisticstime"] == 0 then
                self.isopen = true
                -- print("passkill_statisticstime===",0)
                -- UIRequest({type=3820})
                self:updatetimeFunc()
                gameTimer:UnrigistTimeFunc("passkill_statisticstime")
            end
        end)
    else
        local remaintime = self:gettimenum(begintimenum) - alltimes
        -- local remaintime = 7*24*3600 + self:gettimenum(begintimenum) - alltimes
        
        self.isopen = true
        print("isopen===2222",self.isopen)
        if remaintime <= 0 then
            return
        end  

        -- self.rootItems.timerText:setString("结算倒计时：")
        self.rootItems.timerText:setString(gameConfig.strings:string_common("passkill",5))
        gameTimer:rigistTime("passkill_rewardtime", remaintime)
        gameTimer:rigistTimeFunc("passkill_rewardtime",function()
            if gameTimer.times["passkill_rewardtime"] >= 0 then

                if nowtime.wday == 1 then
                    ui.setLabelString(self.rootItems.timerLabel,ui.makeTimeText(gameTimer.times["passkill_rewardtime"],"hour"),26)
                else
                    ui.setLabelString(self.rootItems.timerLabel,ui.makeTimeDayText(gameTimer.times["passkill_rewardtime"],"day"),26)
                end
            end
            if gameTimer.times["passkill_rewardtime"] == 0 then
                self.isopen = false
                -- print("passkill_rewardtime===",0)
                -- UIRequest({type=3820})
                self:updatetimeFunc()
                gameTimer:UnrigistTimeFunc("passkill_rewardtime")
            end
        end)
    
    end

end

function passkill.gettimenum(self,times,minnum)
    -- print("minnum===",minnum)
    local min = 0
    if minnum then
        min = minnum
    end
    local alltimes = 0
    alltimes = (times.week and (times.week-1) or 0)*24*3600 + (times.hour or 0)*3600 + times.min*60 + times.sec + min*60
    return alltimes
end


function passkill.setFightGenerals( self, itemNum )
    local key_Ex
    if itemNum == nil or itemNum == 1 then
        key_Ex = ""
    else
        key_Ex = "_"..(itemNum-1)
    end
    print("key_Ex==",key_Ex)

    local generalsdata = self.passkilldata.generals


    ui.setLabelString(self.rootItems["name"..key_Ex],generalsdata["generalname"..itemNum],14)
    self.rootItems["powerLabel"..key_Ex]:setString(generalsdata["generalpower"..itemNum])

    if  self.rootItems["generalNode"..key_Ex] then
        self.rootItems["generalNode"..key_Ex]:removeAllChildrenWithCleanup(true)
    end

    local firstconfig = gamedata.config.general[tostring(generalsdata["generalcid"..itemNum])]
    local mowang = gamedata.config.generalanimation[tostring(firstconfig.animationid)].name

    local wing = {level = generalsdata["generalwing_level"..itemNum],color = generalsdata["generalwing_color"..itemNum]}
    --local Gneral = CCSkeletonAnimation:create(mowang.."/"..mowang..".json",mowang.."/"..mowang..".atlas",1)
    local Gneral = ui.itemcache:loadSkeleton(mowang,wing)
    Gneral:setAnimation("stand",true,0)
    Gneral:setScale(1.2)
    self.rootItems["generalNode"..key_Ex]:addChild(Gneral.root or Gneral)

    ui.setLabelString(self.rootItems["reward"..key_Ex],generalsdata["generalstatus"..itemNum] or 0,14)

    self.rootItems["generalNode"..key_Ex]:setVisible(true)
    self.rootItems["win"..key_Ex]:setVisible(false)
    
    self.rootItems["fightBtn"..key_Ex]:setTouchPriority(self.buttontouch)
    self.rootItems["fightBtn"..key_Ex]:setSwallowsTouch(true)
    self.rootItems["fightBtn"..key_Ex]:addHandleOfControlEvent(function()
        print("fightBtn=",self.isopen)
        gameTouch:clickprofbytime(1.5)
         -- = true
        if not self.isopen then
            runGamePrompt({msg = gameConfig.strings:string_common("passkill",3)})
            return
        end
        print("fightnum...over",self.isopen)

        -- if generalsdata["generalstatus"..itemNum] == 1 then
        --     runGamePrompt({msg = gameConfig.strings:string_common("passkill",1)})
        --     return
        -- end


        local paramconfig = gamedata.config.through_param[tostring(1)]
        local buycountconfig = gamedata.config.buycount_price

        local canfightnum = paramconfig.challenge_max + GameScene.vipstatus.through_times - self.passkilldata.basic.fightnum
    

        if canfightnum <= 0 then
            passkillBuyTimes()
            return
        end

        
        UIRequest({type = 3824,rid = generalsdata["generalrid"..itemNum],isauto = self.isauto})
        
        

        -- gameWindows:openWindow("passkillrank",{index= "rule"},nil) 

    end, CCControlEventTouchUpInside)
end

function passkill.setrewardbox(self,itemNum)
    
    local paramconfig = gamedata.config.through_param[tostring(1)]


    local nowboxcoreNum = paramconfig["challeng_award"..itemNum] or 0
    local max = paramconfig.challeng_award3 or 1

    local distanceNum = 741*(nowboxcoreNum/max)
    print("boxnodedata=",nowboxcoreNum,max,distanceNum)

    self.rootItems["boxNode"..itemNum]:setPosition(-370.0+distanceNum,0)


    setSpriteFrameByName(self.rootItems["box"..itemNum], "box4".."_"..self.passkilldata.basic["boxstatus"..itemNum])
    ui.setLabelString(self.rootItems["boxscore"..itemNum],paramconfig["challeng_award"..itemNum],13)
    print("setrewardboxitem",paramconfig["challeng_award"..itemNum])


    -- self.rootItems["boxeffect"..itemNum]:removeAllChildrenWithCleanup(true)
    -- if  self.xianchidata["rewardstatus"..itemNum] == 1 then
    --     self.rootItems["boxeffect"..itemNum]:removeAllChildrenWithCleanup(true)

    --     local ccb, item = CCBReaderLoad("UIEffect/baoxiangkelingqu/baoxiangkelingqu.ccbi", nil, true, "baoxiangkelingqu")
    --     self.rootItems["boxeffect"..itemNum]:addChild(ccb)
    --     local ccb2, item2 = CCBReaderLoad("UIEffect/lizi/baoxiang.ccbi", nil, true, "baoxiang")
    --     self.rootItems["boxeffect"..itemNum]:addChild(ccb2)
    -- end
    self.rootItems["r_button"..itemNum]:setSwallowsTouch(true)
    self.rootItems["r_button"..itemNum]:setTouchPriority(-102)
    self.rootItems["r_button"..itemNum]:addHandleOfControlEvent(function()
        print("itemNum",itemNum)
        --
        local reward = ui.getIDandNUMs(paramconfig["challeng"..itemNum])
        if reward and reward[1] and paramconfig["award_grow"..itemNum] and paramconfig["award_grow"..itemNum] ~= "" then
            local openlevel = gamedata.config.build["175"].level or 0
            local param_level,param_num = ui.getIDandNUM(paramconfig["award_grow"..itemNum])
            reward[1].num = reward[1].num + (math.floor((GameScene.roleinfo.level-openlevel)/param_level)*param_num)
        end
        --
        
        if self.passkilldata.basic["boxstatus"..itemNum] == 0 then
            gameWindows:openWindow("getStaff",{data = reward,type = gameConfig.strings:string_common("task",6)},nil)
        elseif self.passkilldata.basic["boxstatus"..itemNum] == 1 then
            print("请求服务器id=",itemNum)
            -- if itemNum > self.xianchidata.xc_level then
            --     -- runGamePrompt({msg = "仙池等级不足，无法领取"})
            --     runGamePrompt({msg = gameConfig.strings:string_common("guild_xianchi",2)})
            --     return
            -- end
            gameTouch:clickprofbytime(1)
            UIRequest({type = 3827, id = itemNum})
        elseif self.passkilldata.basic["boxstatus"..itemNum] == 2 then
            gameWindows:openWindow("getStaff",{data = reward,type = gameConfig.strings:string_common("moreCommon",5)},nil)
        end
    end, CCControlEventTouchUpInside)

end


function passkill.clear(self)

    if self.timer then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.timer)
        self.timer = nil
    end

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.passkilldata = {}
    self.firstnum = 0

    gameTimer:UnrigistTimeFunc("passkill_rewardtime")
    gameTimer:UnrigistTimeFunc("passkill_statisticstime")


    self.isopen = false


end


function passkill.UIUpdateData(self, isreset)
    if isreset then
        UIRequest({type = 3820})
    end
end


return passkill