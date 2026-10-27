--


local qualitylunpan = {

    rootNode = nil,
    rootItems = nil,
    buttontouch = -101,

    lunpandata = {},
    showindex = 1,
    systemId = 259,
    itemNum = 0,
    rotation = {337.5, 22.5, 67.5, 112.5, 157.5, 202.5, 247.5, 292.5}
}

function qualitylunpan.setFixedString(self)
    ui.setLabelString(self.rootItems.itemLab,gameConfig.strings:string_common("fixedString","shop",19),18)
    ui.setLabelString(self.rootItems.listLab,gameConfig.strings:string_common("fixedString","shop",22),18)
    --ui.setLabelString(self.rootItems.haveFixedText,gameConfig.strings:string_common("fixedString","encounter",11),18)
    self.rootItems.haveFixedText:setString(gameConfig.strings:string_common("fixedString","shop",8))
    
    local useItemConfig = gamedata.config.gambling_items[tostring(self.systemId)]
    if not useItemConfig then
        cclog("error,no activity %d config",self.systemId)
        return
    end
    local itemConfigs = {}
    for i = 1,3 do
        itemConfigs[i] = {}
        local id,num = ui.getIDandNUM(useItemConfig[tostring(i)].once2)
        itemConfigs[i][1] = num
        id,num = ui.getIDandNUM(useItemConfig[tostring(i)].tenfold2)
        itemConfigs[i][2] = num
    end
    
    self.itemConfigs = itemConfigs
end

function qualitylunpan.init(self,size)
    self.contentsize = size
    self.show = true
    if gamedata.config.build[tostring(440)] and gamedata.config.build[tostring(440)].switch and gamedata.config.build[tostring(440)].switch == 1 then
        self.rootNode,self.rootItems = CCBReaderLoad("activityduanwu/activityduanwu_lunpan_yuandan", nil, true, "activityduanwu_lunpan_yuandan")
    else
        self.rootNode,self.rootItems = CCBReaderLoad("activityduanwu/activityduanwu_lunpan3", nil, true, "lunpan")
    end
    self:initgambling()
    self:setFixedString()

    self.rootItems.topnode:setPositionY(self.contentsize.y-180)


    self.rootItems.showNode:setPositionY(self.contentsize.y/2-390+460)


    ui.setLabelString(self.rootItems.timerText,nil,14)
    ui.setLabelString(self.rootItems.timerLabel,nil,21)

    for i = 1,3 do
        ui.setLabelString(self.rootItems["b_name"..i],nil,14)
    end

    -- 说明 规则
    --    self.rootItems.rulebutton:setTouchPriority(self.buttontouch)
    --    self.rootItems.rulebutton:setSwallowsTouch(true)
    --    self.rootItems.rulebutton:addHandleOfControlEvent(function()
    --
    --        gameWindows:openWindow("lunpanchange",{index= "rule",data={}},nil)
    --
    --    end, CCControlEventTouchUpInside)

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

    self:requestItemNum()
    return self.rootNode
end

function qualitylunpan.requestItemNum(self)
    if not self.itemId then
        local config = gamedata.config.gambling_items[tostring(self.systemId)]["1"]
        if config then
            local id,_ = ui.getIDandNUM(config.once2)
            self.itemId = id
        else
            cclog("error no "..tostring(self.systemId).." config")
        end
    end
    if self.itemId then
        UIRequest({type = 12001, order = 33004, cids = {self.itemId}})
    end
end

function qualitylunpan.setItemNum(self,itemNum)
    if itemNum[tostring(self.itemId)] then
        self.itemNum = itemNum[tostring(self.itemId)] or 0
        if self.rootItems then
            self.rootItems.haveFixedNum:setString(""..self.itemNum)
        end
    end
end

function qualitylunpan.setpage(self,page)

    if page then
        self.showindex = page
    end

    for i = 1,3 do
        if i == self.showindex then
            self.rootItems["b_bg"..i]:setVisible(false)
            self.rootItems["bg"..i]:setVisible(true)
        else
            self.rootItems["b_bg"..i]:setVisible(true)
            self.rootItems["bg"..i]:setVisible(false)
        end
    end

    --

    if self.lunpandata and self.lunpandata.lotteryStatus and self.lunpandata.lotteryStatus == self.showindex then
       --
        local priceconfig = gamedata.config.carnival_price or {}
        local maxnum = priceconfig[tostring(self.lunpandata.lotteryStatus)] and priceconfig[tostring(self.lunpandata.lotteryStatus)].second or 0
        --local price = priceconfig[tostring(self.lunpandata.lotteryStatus)] and priceconfig[tostring(self.lunpandata.lotteryStatus)].gold or 0
        if self.lunpandata.lotteryNums >= maxnum then
            ui.addGray("CCControlButton",self.rootItems.doButton)
            ui.addGray("CCControlButton",self.rootItems.doButtonMore)
            self.rootItems.spendnode:setVisible(false)
            self.rootItems.spendnodeMore:setVisible(false)

            ui.setLabelString(self.rootItems.doLab,gameConfig.strings:string_common("fixedString","shop",21),19)
            self.rootItems.doButton:setTouchPriority(self.buttontouch)
            self.rootItems.doButton:setSwallowsTouch(true)
            self.rootItems.doButton:addHandleOfControlEvent(function()
                if gamedata.config.build[tostring(354)] and gamedata.config.build[tostring(354)].switch == 1 then
                    runGamePrompt({msg = "购买次数已满"})
                else
                    runGamePrompt({msg = gameConfig.strings:string_common("lunpan",4)})
                end
                --runGamePrompt({msg = gameConfig.strings:string_common("lunpan",4)})
            end, CCControlEventTouchUpInside)

            if gamedata.config.build[tostring(354)] and gamedata.config.build[tostring(354)].switch == 1 then
                ui.setLabelString(self.rootItems.doLabMore,gameConfig.strings:string_common("fixedString","shop",20),19)
            else
                ui.setLabelString(self.rootItems.doLabMore,gameConfig.strings:string_common("fixedString","shop",20),19)
            end

            self.rootItems.doButtonMore:setTouchPriority(self.buttontouch)
            self.rootItems.doButtonMore:setSwallowsTouch(true)
            self.rootItems.doButtonMore:addHandleOfControlEvent(function()
                if gamedata.config.build[tostring(354)] and gamedata.config.build[tostring(354)].switch == 1 then
                    runGamePrompt({msg = "购买次数已满"})
                else
                    runGamePrompt({msg = gameConfig.strings:string_common("lunpan",4)})
                end
                --runGamePrompt({msg = gameConfig.strings:string_common("lunpan",4)})
            end, CCControlEventTouchUpInside)
        else
            ui.removeGray("CCControlButton",self.rootItems.doButton)
            self.rootItems.spendnode:setVisible(true)
            ui.setLabelString(self.rootItems.spendText,nil,18)
            ui.setLabelString(self.rootItems.spendLabel,self.itemConfigs[self.showindex][1],21)
            ui.setLabelString(self.rootItems.doLab,gameConfig.strings:string_common("fixedString","shop",21),19)
            self.rootItems.doButton:setTouchPriority(self.buttontouch)
            self.rootItems.doButton:setSwallowsTouch(true)
            self.rootItems.doButton:addHandleOfControlEvent(function()
                if GameScene.layers["activity"].module.isContentScroll then  return end
                if self.itemConfigs[self.showindex][1] > self.itemNum then
                    gameWindows:openWindow("buyItem",{id = self.itemId or 20612,num = self.itemNum},function (data)
                        if data.id == self.itemId then
                            self:setItemNum({[tostring(data.id)] = data.num})
                        end
                    end)
                else
                    gameTouch:clickprofbytime(1)
                    UIRequest({type = 4651,num = 1,useId = self.itemId,useNum = self.itemConfigs[self.showindex][1]})
                end
            end, CCControlEventTouchUpInside)
            --
            local donum = 10
            if ((maxnum - self.lunpandata.lotteryNums) <= donum) and ((maxnum - self.lunpandata.lotteryNums) > 1) then
                donum = maxnum - self.lunpandata.lotteryNums
            end

            if gamedata.config.build[tostring(354)] and gamedata.config.build[tostring(354)].switch == 1 then
                ui.setLabelString(self.rootItems.doLabMore,string.format(gameConfig.strings:string_common("fixedString","shop",23),gameConfig.strings:getLanguageNum(donum)),19)
            else
                ui.setLabelString(self.rootItems.doLabMore,string.format(gameConfig.strings:string_common("fixedString","shop",23),gameConfig.strings:getLanguageNum(donum)),19)
            end


            if (maxnum - self.lunpandata.lotteryNums) < donum then
                ui.addGray("CCControlButton",self.rootItems.doButtonMore)
                self.rootItems.spendnodeMore:setVisible(false)
                self.rootItems.doButtonMore:setTouchPriority(self.buttontouch)
                self.rootItems.doButtonMore:setSwallowsTouch(true)
                self.rootItems.doButtonMore:addHandleOfControlEvent(function()
                    if GameScene.layers["activity"].module.isContentScroll then  return end
                    if gamedata.config.build[tostring(354)] and gamedata.config.build[tostring(354)].switch == 1 then
                        runGamePrompt({msg = gameConfig.strings:string_common("lunpan",6)})
                    else
                        runGamePrompt({msg = gameConfig.strings:string_common("lunpan",5)})
                    end
        
                end, CCControlEventTouchUpInside)
            else
                ui.removeGray("CCControlButton",self.rootItems.doButtonMore)
                self.rootItems.spendnodeMore:setVisible(true)
                ui.setLabelString(self.rootItems.spendTextMore,nil,18)
                local price = donum < 10 and self.itemConfigs[self.showindex][1]*donum or self.itemConfigs[self.showindex][2]
                ui.setLabelString(self.rootItems.spendLabelMore,price,21)
                self.rootItems.doButtonMore:setTouchPriority(self.buttontouch)
                self.rootItems.doButtonMore:setSwallowsTouch(true)
                self.rootItems.doButtonMore:addHandleOfControlEvent(function()
                    if GameScene.layers["activity"].module.isContentScroll then  return end
                    if price > self.itemNum then
                        gameWindows:openWindow("buyItem",{id = self.itemId or 20612,num = self.itemNum},function (data)
                            if data.id == self.itemId then
                                self:setItemNum({[tostring(data.id)] = data.num})
                            end
                        end)
                    else
                        gameTouch:clickprofbytime(1)
                        UIRequest({type = 4651,num = donum,useId = self.itemId,useNum = price})
                    end
                end, CCControlEventTouchUpInside)
            end

        end

    else
        ui.addGray("CCControlButton",self.rootItems.doButton)
        ui.addGray("CCControlButton",self.rootItems.doButtonMore)
        self.rootItems.spendnode:setVisible(false)
        self.rootItems.spendnodeMore:setVisible(false)

        ui.setLabelString(self.rootItems.doLab,gameConfig.strings:string_common("fixedString","shop",21),19)
        self.rootItems.doButton:setTouchPriority(self.buttontouch)
        self.rootItems.doButton:setSwallowsTouch(true)
        self.rootItems.doButton:addHandleOfControlEvent(function()
            if gamedata.config.build[tostring(354)] and gamedata.config.build[tostring(354)].switch == 1 then
                runGamePrompt({msg = gameConfig.strings:carnival_goto2(self.lunpandata.lotteryStatus)})
            else
                runGamePrompt({msg = gameConfig.strings:carnival_goto(self.lunpandata.lotteryStatus)})
            end
            --runGamePrompt({msg = gameConfig.strings:carnival_goto(self.lunpandata.lotteryStatus)})
        end, CCControlEventTouchUpInside)

        if gamedata.config.build[tostring(354)] and gamedata.config.build[tostring(354)].switch == 1 then
            ui.setLabelString(self.rootItems.doLabMore,string.format(gameConfig.strings:string_common("fixedString","shop",23),gameConfig.strings:getLanguageNum(10)),19)
        else
            ui.setLabelString(self.rootItems.doLabMore,string.format(gameConfig.strings:string_common("fixedString","shop",23),gameConfig.strings:getLanguageNum(10)),19)
        end

        self.rootItems.doButtonMore:setTouchPriority(self.buttontouch)
        self.rootItems.doButtonMore:setSwallowsTouch(true)
        self.rootItems.doButtonMore:addHandleOfControlEvent(function()
            if gamedata.config.build[tostring(354)] and gamedata.config.build[tostring(354)].switch == 1 then
                runGamePrompt({msg = gameConfig.strings:carnival_goto2(self.lunpandata.lotteryStatus)})
            else
                runGamePrompt({msg = gameConfig.strings:carnival_goto(self.lunpandata.lotteryStatus)})
            end
        end, CCControlEventTouchUpInside)

    end

    local goodsconfig = gamedata.config.carnival_lottery or {}

    for k,v in pairs(goodsconfig) do
        local getdata = ui.getIDandNUMs(v["reward"..self.showindex])

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

end

function qualitylunpan.actionShowSet(self,data)
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
        self:reloaddata(data.carnival)
    end)))

end


function qualitylunpan.reloaddata(self,data)
    if not self.show then return end
    if not data then return end

    self.lunpandata = data

    for i = 1,3 do
        self.rootItems["b_button"..i]:setTouchPriority(self.buttontouch)
        self.rootItems["b_button"..i]:setSwallowsTouch(true)
        self.rootItems["b_button"..i]:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            self:setpage(i)
        end, CCControlEventTouchUpInside)
    end

    if self.lunpandata and self.lunpandata.lotteryStatus then
        gameTouch:clickprofbytime(0.5)
        self:setpage(self.lunpandata.lotteryStatus)
        --
        local priceconfig = gamedata.config.carnival_price or {}
        local maxnum1 = priceconfig["1"] and priceconfig["1"].second or 0
        local maxnum2 = priceconfig["2"] and priceconfig["2"].second or 0
        local maxnum3 = priceconfig["3"] and priceconfig["3"].second or 0
        --
        if self.lunpandata.lotteryStatus == 1 then
            ui.setLabelString(self.rootItems["b_num1"],(maxnum1-self.lunpandata.lotteryNums).."/"..maxnum1,14)
            ui.setLabelString(self.rootItems["b_num2"],maxnum2.."/"..maxnum2,14)
            ui.setLabelString(self.rootItems["b_num3"],maxnum3.."/"..maxnum3,14)

            if gamedata.config.build[tostring(354)] and gamedata.config.build[tostring(354)].switch == 1 then
                ui.setLabelString(self.rootItems["desc"],gameConfig.strings:carnival_num2(1,maxnum1-self.lunpandata.lotteryNums),14)
            else
                ui.setLabelString(self.rootItems["desc"],gameConfig.strings:carnival_num(1,maxnum1-self.lunpandata.lotteryNums),14)
            end

            if self.rootItems.effect1 and self.rootItems.effect2 and self.rootItems.effect3 then
                self.rootItems.effect1:setVisible(true)
                self.rootItems.effect2:setVisible(false)
                self.rootItems.effect3:setVisible(false)
            end
        elseif self.lunpandata.lotteryStatus == 2 then
            ui.setLabelString(self.rootItems["b_num1"],"0/"..maxnum1,14)
            ui.setLabelString(self.rootItems["b_num2"],(maxnum2-self.lunpandata.lotteryNums).."/"..maxnum2,14)
            ui.setLabelString(self.rootItems["b_num3"],maxnum3.."/"..maxnum3,14)

            if gamedata.config.build[tostring(354)] and gamedata.config.build[tostring(354)].switch == 1 then
                ui.setLabelString(self.rootItems["desc"],gameConfig.strings:carnival_num2(2,maxnum2-self.lunpandata.lotteryNums),14)
            else
                ui.setLabelString(self.rootItems["desc"],gameConfig.strings:carnival_num(2,maxnum2-self.lunpandata.lotteryNums),14)
            end

            --ui.setLabelString(self.rootItems["desc"],gameConfig.strings:carnival_num(2,maxnum2-self.lunpandata.lotteryNums),14)
            if self.rootItems.effect1 and self.rootItems.effect2 and self.rootItems.effect3 then
                self.rootItems.effect1:setVisible(false)
                self.rootItems.effect2:setVisible(true)
                self.rootItems.effect3:setVisible(false)
            end
        elseif self.lunpandata.lotteryStatus == 3 then
            ui.setLabelString(self.rootItems["b_num1"],"0/"..maxnum1,14)
            ui.setLabelString(self.rootItems["b_num2"],"0/"..maxnum2,14)
            ui.setLabelString(self.rootItems["b_num3"],(maxnum3-self.lunpandata.lotteryNums).."/"..maxnum3,14)
            if gamedata.config.build[tostring(354)] and gamedata.config.build[tostring(354)].switch == 1 then
                ui.setLabelString(self.rootItems["desc"],gameConfig.strings:carnival_num2(3,maxnum3-self.lunpandata.lotteryNums),14)
            else
                ui.setLabelString(self.rootItems["desc"],gameConfig.strings:carnival_num(3,maxnum3-self.lunpandata.lotteryNums),14)
            end
            --ui.setLabelString(self.rootItems["desc"],gameConfig.strings:carnival_num(3,maxnum3-self.lunpandata.lotteryNums),14)
            if self.rootItems.effect1 and self.rootItems.effect2 and self.rootItems.effect3 then
                self.rootItems.effect1:setVisible(false)
                self.rootItems.effect2:setVisible(false)
                if maxnum3 > self.lunpandata.lotteryNums then
                    self.rootItems.effect3:setVisible(true)
                else
                    self.rootItems.effect3:setVisible(false)
                end
            end
        end
    end

    self:updatetimeFunc()

end


function qualitylunpan.updatetimeFunc( self )
    local nowtime = os.date("*t", gamedata:time())
    local remaintime = 0

    local isnow,remaintime = ui.checkDateActive(gamedata.config.activity_time["64"]["begin"],gamedata.config.activity_time["64"]["end"])

    if not isnow then
        return
    end

    gameTimer:rigistTime("carnival_rewardtime", remaintime)
    gameTimer:rigistTimeFunc("carnival_rewardtime",function()

        if gameTimer.times["carnival_rewardtime"] >= 0 then
            ui.setLabelString(self.rootItems.timerLabel,ui.makeTimeDayText(gameTimer.times["carnival_rewardtime"],"day"),26)
        end
        if gameTimer.times["carnival_rewardtime"] <= 0 then
            gameTimer:UnrigistTimeFunc("carnival_rewardtime")
        end
    end)
end



function qualitylunpan.clear(self)
    self.show = false

    self.showindex = 1

    if self.rootNode then
        self.rootNode:removeAllChildrenWithCleanup(true)
        self.rootNode:removeFromParentAndCleanup(true)
        self.rootNode = nil
        self.rootItems = nil
    end

    self.itemNum = 0
    self.lunpandata = {}

    gameTimer:UnrigistTimeFunc("carnival_rewardtime")

end


function qualitylunpan.UIUpdateData(self, isreset)
    if isreset then
        UIRequest({type = 4650})
        self:requestItemNum()
    end
end

function qualitylunpan.initgambling(self)
    if gamedata.config.build[tostring(354)] and gamedata.config.build[tostring(354)].switch == 1 then
        self.rootItems["gamblingNode"]:setVisible(false)
        ui.setLabelString(self.rootItems.doLab,gameConfig.strings:string_common("fixedString","shop",21),19)
        if false and self.rootItems["gamblingNode"] then
            self.rootItems["gamblingNode"]:setVisible(true)
            --ui.setLabelString(self.rootItems.doLabMore,"购买十次",19)
            ui.setLabelString(self.rootItems.doLab,"购买一次",19)
            local gamblingconfig = gamedata.config.gambling
            local rewardPropCid,rewardPropNum = ui.getIDandNUM(gamblingconfig["6"]["reward1"])
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


return qualitylunpan