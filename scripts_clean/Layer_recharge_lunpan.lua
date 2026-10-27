--


local rechargelunpan = {

    rootNode = nil,
    rootItems = nil,
    buttontouch = -101,

    lunpandata = {},
    systemId = 261,
    rotation = {337.5, 22.5, 67.5, 112.5, 157.5, 202.5, 247.5, 292.5}
}

function rechargelunpan.setFixedString(self)
    ui.setLabelString(self.rootItems.listLab,gameConfig.strings:string_common("fixedString","shop",22),18)
    
end


function rechargelunpan.init(self,size)
    self.contentsize = size
    self.show = true

    self.rootNode,self.rootItems = CCBReaderLoad("activityduanwu/activityduanwu_lunpan4", nil, true, "lunpan")

    self.rootItems.ruleBtn:addHandleOfControlEvent(function()
        local cpnum = GameScene.layers["activity"].module.dailyCpActivityTimeStatus[66] and GameScene.layers["activity"].module.dailyCpActivityTimeStatus[66].cpnum or 0
        ui.popCommonRule(nil,nil,gamedata.config.activity_probability[tostring(261)][tostring(cpnum)].instructions)
    end, CCControlEventTouchUpInside)
    self.rootItems.ruleBtn:setSwallowsTouch(true)
    self.rootItems.ruleBtn:setTouchPriority(self.buttontouch)
    self.rootItems.topnode:setPositionY(self.contentsize.y-180)


    self.rootItems.showNode:setPositionY(self.contentsize.y/2-390+360)
    self:initgambling()
    self:setFixedString()

    ui.setLabelString(self.rootItems.timerText,nil,14)
    ui.setLabelString(self.rootItems.timerLabel,nil,21)
    ui.setLabelString(self.rootItems.txtDos,nil,26)

    ui.setLabelString(self.rootItems.scoreText,nil,14)

    if self.rootItems.listLab and self.rootItems.listButton then
        ui.setLabelString(self.rootItems.listLab,nil,18)
        self.rootItems.listButton:setTouchPriority(self.buttontouch)
        self.rootItems.listButton:setSwallowsTouch(true)
        self.rootItems.listButton:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            gameTouch:clickprofbytime(0.5)
            gameWindows:openWindow("turntablerecord",{systemId = self.systemId},nil)
        end, CCControlEventTouchUpInside)
    end
    
    if self.rootItems.rechargebutton then
        self.rootItems.rechargebutton:setTouchPriority(self.buttontouch)
        self.rootItems.rechargebutton:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            gameWindows:openWindow("recharge",{pagetype = "info"})
        end, CCControlEventTouchUpInside)
    end
    -- 说明 规则
    --    self.rootItems.rulebutton:setTouchPriority(self.buttontouch)
    --    self.rootItems.rulebutton:setSwallowsTouch(true)
    --    self.rootItems.rulebutton:addHandleOfControlEvent(function()
    --
    --        gameWindows:openWindow("lunpanchange",{index= "rule",data={}},nil)
    --
    --    end, CCControlEventTouchUpInside)


    local goodsconfig = gamedata.dailyCpActivityConfig("points_canival_item",66)
    -- local goodsconfig = gamedata.config.points_canival_item or {}

    for k,v in pairs(goodsconfig) do
        local getdata = ui.getIDandNUMs(v.reward)

        if getdata and next(getdata[1]) then
            ui.setNewIcon(self.rootItems,getdata[1],tonumber(k)-1)

            local id = (tonumber(k)-1) or 0
            local key_Ex
            if id == nil or id == 0 then
                key_Ex = ""
            else
                key_Ex = "_"..id
            end

            self.rootItems["i_button"..key_Ex]:setTouchPriority(self.buttontouch)
            self.rootItems["i_button"..key_Ex]:setSwallowsTouch(true)
            self.rootItems["i_button"..key_Ex]:addHandleOfControlEvent(function()
                ui.setPopwindowByCid(getdata[1].cid)
            end, CCControlEventTouchUpInside)
        end


    end


    return self.rootNode
end


function rechargelunpan.actionShowSet(self,data)
    if not data then return end
    gameTouch:clickprofbytime(4.5)

    local rotationnum = self.rotation[tonumber(data.rewardpos or 1)]

    local nowrotationnum = math.mod(self.rootItems.rotateNode:getRotation(),360)

    local rotationbynum = 4*360 - nowrotationnum + rotationnum

    local rotationby = CCRotateBy:create(4, rotationbynum)
    local rotationOut = CCEaseSineOut:create(rotationby)

    self.rootItems.rotateNode:runAction(CCSequence:createWithTwoActions(rotationOut,CCCallFunc:create(function()
        if data.reward then
            showRewardPopupWindow(data.reward, nil, nil)
        end

        UIRequest({type = 1001})
        self:reloaddata(data.integralturntable)
    end)))

end


function rechargelunpan.reloaddata(self,data)
    if not self.show then return end
    if not data then return end

    self.lunpandata = data

    ui.setLabelString(self.rootItems.scoreLabel,self.lunpandata.lotteryScore or 0,21)

    local spend_str = gamedata.config.global_kv.points_carnival_consume_one and gamedata.config.global_kv.points_carnival_consume_one.value or "1019,0;"
    local spendmore_str = gamedata.config.global_kv.points_carnival_consume_tenth and gamedata.config.global_kv.points_carnival_consume_tenth.value or "1019,0;"

    local spend_cid, spend_num = ui.getIDandNUM(spend_str)
    local spend_num10 = spend_num * 10
    local spend_num100 = spend_num * 100
    -- local spendmore_cid, spendmore_num = ui.getIDandNUM(spendmore_str)

    if spend_num100 > 0 then
        self.rootItems.spendnode:setVisible(true)
        ui.setLabelString(self.rootItems.spendText,nil,18)
        ui.setLabelString(self.rootItems.spendLabel,spend_num100,21)
    else
        self.rootItems.spendnode:setVisible(false)
    end

    local curNum = math.min(math.floor(self.lunpandata.lotteryScore/spend_num),10)
    local count = curNum * spend_num
    if curNum >= 0 then
        self.rootItems.spendnodeMore:setVisible(true)
        ui.setLabelString(self.rootItems.spendTextMore,nil,18)
        if count <= spend_num10 and curNum > 0 then
            spend_num10 = count
        end
        ui.setLabelString(self.rootItems.spendLabelMore,spend_num10,21)
    else
        self.rootItems.spendnodeMore:setVisible(false)
    end

    if spend_num100 > self.lunpandata.lotteryScore then
        ui.addGray("CCControlButton",self.rootItems.doButton)
    else
        ui.removeGray("CCControlButton",self.rootItems.doButton)
    end

    if spend_num > self.lunpandata.lotteryScore then
        ui.addGray("CCControlButton",self.rootItems.doButtonMore)
    else
        ui.removeGray("CCControlButton",self.rootItems.doButtonMore)
    end

    -- 抽奖 按钮
    ui.setLabelString(self.rootItems.doLab,nil,19)
    self.rootItems.doButton:setTouchPriority(self.buttontouch)
    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:addHandleOfControlEvent(function()

        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameTouch:clickprofbytime(1)

        if spend_num100 > self.lunpandata.lotteryScore then
            runGamePrompt({msg = gameConfig.strings:string_common("ui",56)})
        else
            UIRequest({type = 4661,num = 100})
        end

    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.doLabMore,self:getNum(spend_num),19)
    self.rootItems.doButtonMore:setTouchPriority(self.buttontouch)
    self.rootItems.doButtonMore:setSwallowsTouch(true)
    self.rootItems.doButtonMore:addHandleOfControlEvent(function()

        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameTouch:clickprofbytime(1)
        if spend_num10 > self.lunpandata.lotteryScore then
            runGamePrompt({msg = gameConfig.strings:string_common("ui",56)})
        else
            UIRequest({type = 4661,num = curNum})
        end

    end, CCControlEventTouchUpInside)



    self:updatetimeFunc()

end


function rechargelunpan.updatetimeFunc( self )

    local timediff = 0
    if gamedata.config.activity_time["66"]["open_type"] and gamedata.config.activity_time["66"]["open_type"] == 2 then
        self.rootItems.timerText:setVisible(false)
        self.rootItems.timerLabel:setVisible(false)
    elseif gamedata.config.activity_time["66"]["open_type"] and gamedata.config.activity_time["66"]["open_type"] == 1 then
        self.rootItems.timerText:setVisible(true)
        self.rootItems.timerLabel:setVisible(true)
        local nowtime = gamedata:time()
        local temp = os.date("*t", GameScene.roleinfo.servertime)
        timediff = GameScene.roleinfo.servertime + 86400*gamedata.config.activity_time["66"]["continued_time"] - nowtime - temp.hour*3600 - temp.min*60 - temp.sec
    elseif gamedata.config.activity_time["66"]["open_type"] and gamedata.config.activity_time["66"]["open_type"] == 7 then
        timediff = GameScene.layers["activity"].module:getDailyCpActivityTime(66)
    elseif gamedata.config.activity_time["66"]["end"] and gamedata.config.activity_time["66"]["end"] ~= "" then
        self.rootItems.timerText:setVisible(true)
        self.rootItems.timerLabel:setVisible(true)
        local year1,month1,day1,hour1,minute1,second1 = ui.getDate(gamedata.config.activity_time["66"]["end"])
        local time1 = os.time({year=year1, month=month1, day=day1, hour=hour1, min = minute1, sec =  second1})
        local nowtime = gamedata:time()
        timediff = time1-nowtime;
    else
        self.rootItems.timerText:setVisible(false)
        self.rootItems.timerLabel:setVisible(false)
    end

    if timediff > 0 then
        gameTimer:rigistTime("rechargelunpan_rewardtime", timediff)
        gameTimer:rigistTimeFunc("rechargelunpan_rewardtime",function()

            if gameTimer.times["rechargelunpan_rewardtime"] >= 0 then
                ui.setLabelString(self.rootItems.timerLabel,ui.makeTimeDayText(gameTimer.times["rechargelunpan_rewardtime"],"day"),26)
            end
            if gameTimer.times["rechargelunpan_rewardtime"] <= 0 then
                gameTimer:UnrigistTimeFunc("rechargelunpan_rewardtime")
            end
        end)
    end
end



function rechargelunpan.clear(self)
    self.show = false

    if self.rootNode then
        self.rootNode:removeAllChildrenWithCleanup(true)
        self.rootNode:removeFromParentAndCleanup(true)
        self.rootNode = nil
        self.rootItems = nil
    end


    self.lunpandata = {}

    gameTimer:UnrigistTimeFunc("rechargelunpan_rewardtime")

end

function rechargelunpan.initgambling(self)
    if gamedata.config.build[tostring(354)] and gamedata.config.build[tostring(354)].switch == 1 then
        self.rootItems["gamblingNode"]:setVisible(false)
        -- ui.setLabelString(self.rootItems.doLabMore,gameConfig.strings:string_common("fixedString","shop",20),19)
        ui.setLabelString(self.rootItems.doLab,gameConfig.strings:string_common("fixedString","shop",29),19)
       if false and self.rootItems["gamblingNode"] then
            self.rootItems["gamblingNode"]:setVisible(true)
            ui.setLabelString(self.rootItems.doLabMore,"购买十次",19)
            ui.setLabelString(self.rootItems.doLab,"购买一次",19)
            local gamblingconfig = gamedata.config.gambling
            local rewardPropCid,rewardPropNum = ui.getIDandNUM(gamblingconfig["7"]["reward1"])
            local richdata = ui.IDconfig(rewardPropCid)
            richdata.num = rewardPropNum
            richdata.cid = rewardPropCid
            ui.setNewIcon(self.rootItems,richdata,8)
            self.rootItems["i_num_8"]:setScale(1.2)
            ui.setLabelString(self.rootItems.fixedcostLab1,"购买",18)
            ui.setLabelString(self.rootItems.fixedcostLab2,"送领奖",18)
        end
    end
end


function rechargelunpan.UIUpdateData(self, isreset)
    if isreset then
        UIRequest({type = 4660})
    end
end


function rechargelunpan.getNum( self,oncenum )
    local curNum = math.floor(self.lunpandata.lotteryScore/oncenum)
    local str = "转十次"
    if curNum == 9 then
        str = "转九次"
    elseif curNum == 8 then
        str = "转八次"
    elseif curNum == 7 then
        str = "转七次"
    elseif curNum == 6 then
        str = "转六次"
    elseif curNum == 5 then
        str = "转五次"
    elseif curNum == 4 then
        str = "转四次"
    elseif curNum == 3 then
        str = "转三次"
    elseif curNum == 2 then
        str = "转二次"
    elseif curNum == 1 then
        str = "转一次"
    end
    return str
end



return rechargelunpan