--


local activitylunpan = {

    rootNode = nil,
    rootItems = nil,
    buttontouch = -101,

    lunpandata = {},
    systemId = 258,
    rotation = {337.5, 22.5, 67.5, 112.5, 157.5, 202.5, 247.5, 292.5},
    itemNum = 0,
}

function activitylunpan.setFixedString(self)
    ui.setLabelString(self.rootItems.itemLab,gameConfig.strings:string_common("fixedString","shop",19),18)
    --ui.setLabelString(self.rootItems.haveFixedText,gameConfig.strings:string_common("fixedString","encounter",11),18)
    self.rootItems.haveFixedText:setString(gameConfig.strings:string_common("fixedString","encounter",11))

    local useItemConfig = gamedata.config.gambling_items[tostring(self.systemId)]["1"]
    if not useItemConfig then
        cclog("error,no activity %d config",self.systemId)
        return
    end
    local itemConfigs = {}
    local id,num = ui.getIDandNUM(useItemConfig.once2)
    itemConfigs[1] = num
    id,num = ui.getIDandNUM(useItemConfig.tenfold2)
    itemConfigs[2] = num
    self.itemConfigs = itemConfigs
end

function activitylunpan.init(self,size)
    self.contentsize = size
    self.show = true

    self.rootNode,self.rootItems = CCBReaderLoad("activityduanwu/activityduanwu_lunpan2", nil, true, "lunpan")

    self.rootItems.ruleBtn:addHandleOfControlEvent(function()
        local cpnum = GameScene.layers["activity"].module.dailyCpActivityTimeStatus[63] and GameScene.layers["activity"].module.dailyCpActivityTimeStatus[63].cpnum or 0
        ui.popCommonRule(nil,nil,gamedata.config.activity_probability[tostring(258)][tostring(cpnum)].instructions)
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

    ui.setLabelString(self.rootItems.allGoldLab,nil,18)

    if self.rootItems.listLab and self.rootItems.listButton then
        ui.setLabelString(self.rootItems.listLab,nil,18)
        self.rootItems.listButton:setTouchPriority(self.buttontouch)
        self.rootItems.listButton:setSwallowsTouch(true)
        self.rootItems.listButton:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            gameTouch:clickprofbytime(0.5)
            gameWindows:openWindow("turntablerecord",{typeindex = 1},nil)
        end, CCControlEventTouchUpInside)
    end

    self.rootItems.buyItem:setTouchPriority(self.buttontouch)
    self.rootItems.buyItem:setSwallowsTouch(true)
    self.rootItems.buyItem:addHandleOfControlEvent(function()

        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameTouch:clickprofbytime(0.5)
        gameWindows:openWindow("buyItem",{id = self.itemId or 20612,num = self.itemNum},function (data)
            if data.id == self.itemId then
                self:setItemNum({[tostring(data.id)] = data.num})
            end
        end)

    end, CCControlEventTouchUpInside)

    -- 说明 规则
--    self.rootItems.rulebutton:setTouchPriority(self.buttontouch)
--    self.rootItems.rulebutton:setSwallowsTouch(true)
--    self.rootItems.rulebutton:addHandleOfControlEvent(function()
--
--        gameWindows:openWindow("lunpanchange",{index= "rule",data={}},nil)
--
--    end, CCControlEventTouchUpInside)

    -- local goodsconfig = gamedata.config.turntable or {}
    local goodsconfig = gamedata.dailyCpActivityConfig("turntable",63)

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

            if v.Percentage and v.Percentage > 0.0001 then
                self.rootItems["i_num"..key_Ex]:setVisible(false)
                self.rootItems["getGold"..k]:setVisible(true)
                self.rootItems["getGoldNum"..k]:setString((v.Percentage*100).."%")
            else
                self.rootItems["i_num"..key_Ex]:setVisible(true)
                self.rootItems["getGold"..k]:setVisible(false)
            end

            self.rootItems["i_button"..key_Ex]:setTouchPriority(self.buttontouch)
            self.rootItems["i_button"..key_Ex]:setSwallowsTouch(true)
            self.rootItems["i_button"..key_Ex]:addHandleOfControlEvent(function()
                ui.setPopwindowByCid(getdata[1].cid)
            end, CCControlEventTouchUpInside)
        end


    end
    self:requestItemNum()
    return self.rootNode
end

function activitylunpan.requestItemNum(self)
    if not self.itemId then
        local config = gamedata.config.gambling_items[tostring(self.systemId)]["1"]
        if config then
            local id,_ = ui.getIDandNUM(config.once2)
            self.itemId = id
        end
    end
    if self.itemId then
        UIRequest({type = 12001, order = 33001, cids = {self.itemId}})
    end
end

function activitylunpan.setItemNum(self,itemNum)
    if itemNum[tostring(self.itemId)] then
        self.itemNum = itemNum[tostring(self.itemId)] or 0
        if self.rootItems then
            self.rootItems.haveFixedNum:setString("x"..self.itemNum)
        end
    end
end


function activitylunpan.actionShowSet(self,data)
    self:requestItemNum()
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
        self:reloaddata(data.turntable)
    end)))

end


function activitylunpan.reloaddata(self,data)
    if not self.show then return end
    if not data then return end

    self.lunpandata = data

    ui.setLabelString(self.rootItems.allGoldNum,self.lunpandata.goldNums or 0,14)
    
    local freetimes = gamedata.config.global_kv.turntable_lottery.value - self.lunpandata.lotteryFreeUsed

    if freetimes > 0 then
        self.rootItems.freenode:setVisible(true)
        self.rootItems.spendnode:setVisible(false)
        ui.setLabelString(self.rootItems.freeText,nil,18)
        ui.setLabelString(self.rootItems.freeLabel,freetimes,21)
    else
        self.rootItems.freenode:setVisible(false)
        self.rootItems.spendnode:setVisible(true)
        ui.setLabelString(self.rootItems.spendText,nil,18)
        ui.setLabelString(self.rootItems.spendLabel,self.itemConfigs[1],21)
    end

    if false and freetimes >= 10 then
        self.rootItems.freenodeMore:setVisible(true)
        self.rootItems.spendnodeMore:setVisible(false)
        ui.setLabelString(self.rootItems.freeTextMore,nil,18)
        ui.setLabelString(self.rootItems.freeLabelMore,freetimes,21)
    else
        self.rootItems.freenodeMore:setVisible(false)
        self.rootItems.spendnodeMore:setVisible(true)
        ui.setLabelString(self.rootItems.spendTextMore,nil,18)
        ui.setLabelString(self.rootItems.spendLabelMore,self.itemConfigs[2],21)
    end


    -- 抽奖 按钮
    ui.setLabelString(self.rootItems.doLab,nil,19)
    self.rootItems.doButton:setTouchPriority(self.buttontouch)
    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:addHandleOfControlEvent(function()

        if GameScene.layers["activity"].module.isContentScroll then  return end
        if freetimes < 1 and self.itemConfigs[1] > self.itemNum then
            gameWindows:openWindow("buyItem",{id = self.itemId or 20612,num = self.itemNum},function (data)
                if data.id == self.itemId then
                    self:setItemNum({[tostring(data.id)] = data.num})
                end
            end)
        else
            gameTouch:clickprofbytime(1)
            UIRequest({type = 4631,num = 1, useId = self.itemId,useNum = freetimes < 1 and self.itemConfigs[1] or 0})
        end
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.doLabMore,nil,19)
    self.rootItems.doButtonMore:setTouchPriority(self.buttontouch)
    self.rootItems.doButtonMore:setSwallowsTouch(true)
    self.rootItems.doButtonMore:addHandleOfControlEvent(function()

        if GameScene.layers["activity"].module.isContentScroll then  return end
        if self.itemConfigs[2] > self.itemNum then
            gameWindows:openWindow("buyItem",{id = self.itemId or 20612,num = self.itemNum},function (data)
                if data.id == self.itemId then
                    self:setItemNum({[tostring(data.id)] = data.num})
                end
            end)
        else
            gameTouch:clickprofbytime(1)
            UIRequest({type = 4631,num = 10, useId = self.itemId,useNum = self.itemConfigs[2]})
        end

    end, CCControlEventTouchUpInside)



    self:updatetimeFunc()

end


function activitylunpan.updatetimeFunc( self )
    local nowtime = os.date("*t", gamedata:time())
    local remaintime = 0
    local isnow = true
    if gamedata.config.activity_time["63"]["open_type"] and gamedata.config.activity_time["63"]["open_type"] == 7 then
        remaintime = GameScene.layers["activity"].module:getDailyCpActivityTime(63)
    else
        isnow,remaintime = ui.checkDateActive(gamedata.config.activity_time["63"]["begin"],gamedata.config.activity_time["63"]["end"])
    end

    if not isnow then
        return
    end

    gameTimer:rigistTime("turntable_rewardtime", remaintime)
    gameTimer:rigistTimeFunc("turntable_rewardtime",function()

        if gameTimer.times["turntable_rewardtime"] >= 0 then
            ui.setLabelString(self.rootItems.timerLabel,ui.makeTimeDayText(gameTimer.times["turntable_rewardtime"],"day"),26)
        end
        if gameTimer.times["turntable_rewardtime"] <= 0 then
            gameTimer:UnrigistTimeFunc("turntable_rewardtime")
        end
    end)
end



function activitylunpan.clear(self)
    self.show = false

    if self.rootNode then
        self.rootNode:removeAllChildrenWithCleanup(true)
        self.rootNode:removeFromParentAndCleanup(true)
        self.rootNode = nil
        self.rootItems = nil
    end
    self.itemNum = 0

    self.lunpandata = {}

    gameTimer:UnrigistTimeFunc("turntable_rewardtime")

end

function activitylunpan.initgambling(self)
    if gamedata.config.build[tostring(354)] and gamedata.config.build[tostring(354)].switch == 1 then
        self.rootItems["gamblingNode"]:setVisible(false)
        ui.setLabelString(self.rootItems.doLabMore,gameConfig.strings:string_common("fixedString","shop",20),19)
        ui.setLabelString(self.rootItems.doLab,gameConfig.strings:string_common("fixedString","shop",21),19)
        if false and self.rootItems["gamblingNode"] then
            
            local gamblingconfig = gamedata.config.gambling
            local rewardPropCid,rewardPropNum = ui.getIDandNUM(gamblingconfig["4"]["reward1"])
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


function activitylunpan.UIUpdateData(self, isreset)
    if isreset then
        UIRequest({type = 4630})
        self:requestItemNum()
    end
end


return activitylunpan 1  