--
-- Created by IntelliJ IDEA.
-- User: lichungeng
-- Date: 16/6/12
-- Time: 下午1:44
-- To change this template use File | Settings | File Templates.
--

local newdriver = {
    buttontouch = -103,
    data = {},


    superReward = {},

    bigpos = {},
    systemId = 311,
    itemNum = 0,
    cpnum = 0,
    cpday = 0,
    new_generals_lottery = {},

    steptimes = {
        [1] = 0.1,
        [2] = 0.3,
        [3] = 0.5,
        [4] = 0.68,
        [5] = 0.85,
    },

    isactivitynow = true,
}

function newdriver.setFixedString(self)

    if self.coveritems.extdesc then
        ui.setLabelString(self.coveritems.extdesc,nil,14)
    end    

    ui.setLabelString(self.coveritems.itemLab,gameConfig.strings:string_common("fixedString","shop",26),18)
    ui.setLabelString(self.coveritems.listLab,gameConfig.strings:string_common("fixedString","shop",22),18)
    --ui.setLabelString(self.coveritems.haveFixedText,gameConfig.strings:string_common("fixedString","encounter",11),18)
    self.coveritems.haveFixedText:setString(gameConfig.strings:string_common("fixedString","shop",8))

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


function newdriver.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("activitytigerchicken/tigerchicken",nil, true, "tigerchicken")
    self.coveritemsanimationManager = getAnimationManager(self.coveritems)
    self.coveritemsanimationManager:runAnimationsForSequenceNamed("one")

    self.coveritems.topnode:setPositionY(self.contentsize.y-((GameScene.topposY-1620)*0.1+130))
    self.coveritems.bottomnode:setPositionY((GameScene.topposY-1620)*0.2+300)
    self.coveritems.midnode:setPositionY((GameScene.topposY-1620)*0.6+800)
    self.coveritems.midnode:setScale(0.9+0.1*(GameScene.topposY-1620)/300)

    self:setFixedString()
    --
    if self.coveritems.listLab and self.coveritems.listButton then
        ui.setLabelString(self.coveritems.listLab,nil,18)
        self.coveritems.listButton:setTouchPriority(self.buttontouch)
        self.coveritems.listButton:setSwallowsTouch(true)
        self.coveritems.listButton:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            gameTouch:clickprofbytime(0.5)
            gameWindows:openWindow("turntablerecord",{systemId = self.systemId},nil)
        end, CCControlEventTouchUpInside)
    end

    self.coveritems.buyItem:setTouchPriority(self.buttontouch)
    self.coveritems.buyItem:setSwallowsTouch(true)
    self.coveritems.buyItem:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        if self.isactivitynow then    
            gameTouch:clickprofbytime(0.5)
            gameWindows:openWindow("buyItem",{id = self.itemId or 20612,num = self.itemNum},function (data)
                if data.id == self.itemId then
                    self:setItemNum({[tostring(data.id)] = data.num})
                end
            end)
        else
            runGamePrompt({msg = "本次活动已结束"})
            return
        end    

    end, CCControlEventTouchUpInside)
    --

    local activityConfig = gamedata.config.activity_time
    local generalConfig = gamedata.config.generalanimation
    local name = generalConfig[tostring(activityConfig[tostring(79)].generalanimation)].name
    self.coveritems["generalnode"]:removeAllChildrenWithCleanup(true)
    local Gneral1 = CCSkeletonAnimation:create(name .."/" .. name .. ".json", name .."/" .. name .. ".atlas",1)
    Gneral1:setAnimation("stand",true,0)
    Gneral1:setScale(1.5)
    Gneral1:setPosition(0,0)
    self.coveritems["generalnode"]:addChild(Gneral1)
    self.coveritems["generalnode"]:setScaleX(-1)

    self.talkccb, self.talkitems = CCBReaderLoad("activitytigerchicken/talk",nil, true, "talk")
    self.coveritems["talknode"]:addChild(self.talkccb)

    self.luckccb, self.luckitems = CCBReaderLoad("UIEffect/tigerchicken/tigerchicken_xingyun",nil, true, "tigerchicken_xingyun")
    self.coveritems["luckeffect"]:addChild(self.luckccb)
    self.luckbanimationManager = getAnimationManager(self.luckitems)
    self.luckccb:setVisible(false)


    self.coveritems["tipbutton"]:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then return end
        ui.popCommonRule(nil,nil,gamedata.config.activity_probability[tostring(312)][tostring(self.cpnum)].instructions)
    end, CCControlEventTouchUpInside)
    self.coveritems["tipbutton"]:setSwallowsTouch(true)
    self.coveritems["tipbutton"]:setTouchPriority(-104)

    --ui.setLabelString(self.coveritems["tentext"],"开始十次",19)
    self.coveritems["tenbutton"]:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then return end
        if self.isactivitynow then    
            if self.itemConfigs[2] > self.itemNum then
                gameWindows:openWindow("buyItem",{id = self.itemId or 20612,num = self.itemNum},function (data)
                    if data.id == self.itemId then
                        self:setItemNum({[tostring(data.id)] = data.num})
                    end
                end)
            else
                gameTouch:clickprofbytime(1)
                UIRequest({type = 5021,method = 10,useId = self.itemId,useNum = self.itemConfigs[2]})
            end
        else
            runGamePrompt({msg = "本次活动已结束"})
            return
        end    

    end, CCControlEventTouchUpInside)
    self.coveritems["tenbutton"]:setSwallowsTouch(true)
    self.coveritems["tenbutton"]:setTouchPriority(-104)

    --ui.setLabelString(self.coveritems["onetext"],"开始一次",19)
    self.coveritems["onebutton"]:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then return end
        if self.isactivitynow then    
            if self.data.freetime > 0 and self.itemConfigs[1] > self.itemNum then
                gameWindows:openWindow("buyItem",{id = self.itemId or 20612,num = self.itemNum},function (data)
                    if data.id == self.itemId then
                        self:setItemNum({[tostring(data.id)] = data.num})
                    end
                end)
            else
                gameTouch:clickprofbytime(1)
                UIRequest({type = 5021,method = 1,useId = self.itemId,useNum =  self.data.freetime > 0 and self.itemConfigs[1] or 0})
            end
        else
            runGamePrompt({msg = "本次活动已结束"})
            return
        end    

    end, CCControlEventTouchUpInside)
    self.coveritems["onebutton"]:setSwallowsTouch(true)
    self.coveritems["onebutton"]:setTouchPriority(-104)

    ui.setLabelString(self.coveritems["exchangeText"],"兑换",19)
    self.coveritems["exchangeBtn"]:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then return end
        --GameScene:shiftLayerById(312)

        UIRequest({type = 5022})

    end, CCControlEventTouchUpInside)
    self.coveritems["exchangeBtn"]:setSwallowsTouch(true)
    self.coveritems["exchangeBtn"]:setTouchPriority(-104)

    self:initgambling()
    self:requestItemNum()
    return self.coverccb
end

function newdriver.requestItemNum(self)
    if not self.itemId then
        local config = gamedata.config.gambling_items[tostring(self.systemId)]["1"]
        if config then
            local id,_ = ui.getIDandNUM(config.once2)
            self.itemId = id
        end
    end
    if self.itemId then
        UIRequest({type = 12001, order = 33006, cids = {self.itemId}})
    end
end

function newdriver.setItemNum(self,itemNum)
    if itemNum[tostring(self.itemId)] then
        self.itemNum = itemNum[tostring(self.itemId)] or 0
        if self.coveritems then
            self.coveritems.haveFixedNum:setString(""..self.itemNum)
        end
    end
end

function newdriver.reloaddata(self,data)

    if data.cpnum then
        self.cpnum = data.cpnum
    end

    if data.cpday then
        self.cpday = data.cpday
    end
    --

    self.new_generals_lottery = {}
    if self.cpnum > 0 then
        self.new_generals_lottery = gamedata.config["new_generals_lottery_"..self.cpnum]
    else
        self.new_generals_lottery = gamedata.config.new_generals_lottery
    end

    self.data = data.data or self.data
    if not self.show then return end

    --
    local cpnum = self.cpnum or 0
    local cpday = self.cpday or 0
    local endString = ""
    local endstr = ""
    if gamedata.config.activity_time["80"]["open_type"] and gamedata.config.activity_time["80"]["open_type"] == 5 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", nowtime)
        local timediff = nowtime + 86400*(gamedata.config.activity_time["80"]["continued_time"..((cpnum == 1) and ("_1") or "")]-cpday+1) - temp.hour*3600 - temp.min*60 - temp.sec
        local endtab = os.date("*t", timediff-2)
        endString = endtab.year.."年"..endtab.month.."月"..endtab.day.."日24时"
        endstr = "兑换截止时间"
        --
        local timediff2 = 86400*(gamedata.config.activity_time["79"]["continued_time"..((cpnum == 1) and ("_1") or "")]-cpday+1) - temp.hour*3600 - temp.min*60 - temp.sec
        if (cpday > 0) and (timediff2 > 0) then
            self.isactivitynow = true
            endstr = "活动截止时间"
            endtab = os.date("*t", timediff2+nowtime-2)
            endString = endtab.year.."年"..endtab.month.."月"..endtab.day.."日24时"
        else
            self.isactivitynow = false
        end    

    elseif gamedata.config.activity_time["80"]["open_type"] and gamedata.config.activity_time["80"]["open_type"] == 1 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", GameScene.roleinfo.servertime)
        local timediff = 0
        timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["80"]["continued_time"]+(gamedata.config.activity_time["80"]["days_later"] or 0)) - temp.hour*3600 - temp.min*60 - temp.sec
        if timediff < nowtime then
            timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["80"]["continued_time"]+(gamedata.config.activity_time["80"]["days_later2"] or 0)) - temp.hour*3600 - temp.min*60 - temp.sec
        end
        local endtab = os.date("*t", timediff-2)
        endString = endtab.year.."年"..endtab.month.."月"..endtab.day.."日24时"
        endstr = "兑换截止时间"
        --
        local timediff2 = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["79"]["continued_time"]+(gamedata.config.activity_time["79"]["days_later"] or 0)) - temp.hour*3600 - temp.min*60 - temp.sec
        if timediff2 < nowtime then
            timediff2 = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["79"]["continued_time"]+(gamedata.config.activity_time["79"]["days_later2"] or 0)) - temp.hour*3600 - temp.min*60 - temp.sec
        end
        if timediff2 > nowtime then
            self.isactivitynow = true
            endstr = "活动截止时间"
            endtab = os.date("*t", timediff2-2)
            endString = endtab.year.."年"..endtab.month.."月"..endtab.day.."日24时"
        else
            self.isactivitynow = false
        end    
    elseif gamedata.config.activity_time["80"]["end"] and gamedata.config.activity_time["80"]["end"] ~= "" then
        local year, month, day, hour, min, sec = ui.getDate(gamedata.config.activity_time["80"]["end"])
        endString = year.."年"..month.."月"..day.."日"
        if tonumber(hour) < 1 and tonumber(min) < 1 and tonumber(sec) < 1 then
            local endt = os.time({year=tonumber(year),month=tonumber(month),day=tonumber(day),hour=tonumber(hour),min=tonumber(min),sec=tonumber(sec),isdst=false}) - 2
            local endtab = os.date("*t",endt)
            endString = endtab.year.."年"..endtab.month.."月"..endtab.day.."日24时"
        end
        endstr = "兑换截止时间"
        --
        local nowtime = gamedata:time()
        local year2, month2, day2, hour2, min2, sec2 = ui.getDate(gamedata.config.activity_time["79"]["end"])
        local endt2 = os.time({year=tonumber(year2),month=tonumber(month2),day=tonumber(day2),hour=tonumber(hour2),min=tonumber(min2),sec=tonumber(sec2),isdst=false})
        if endt2 > nowtime then
            self.isactivitynow = true
            endstr = "活动截止时间"
            endtab = os.date("*t", endt2-2)
            endString = endtab.year.."年"..endtab.month.."月"..endtab.day.."日24时"
        else
            self.isactivitynow = false
        end    

    end
    self.coveritems.endtime:setString(endString)
    if self.coveritems.endstr then
        self.coveritems.endstr:setString(endstr)
    end
    --
    if self.isactivitynow then
        ui.removeGray("CCControlButton",self.coveritems.onebutton)
        ui.removeGray("CCControlButton",self.coveritems.tenbutton)
        ui.removeGray("CCControlButton",self.coveritems.buyItem)
    else
        ui.addGray("CCControlButton",self.coveritems.onebutton)
        ui.addGray("CCControlButton",self.coveritems.tenbutton)
        ui.addGray("CCControlButton",self.coveritems.buyItem)
    end    
    --

    self:setRewards()

    self:setLucky()

    ui.setLabelString(self.coveritems.points,"X"..self.data.points,14)
    ui.setLabelString(self.coveritems.pointsdes,"当前拥有",14)



    if self.data.freetime>0 then
        self.coveritems["onegold"]:setVisible(true)
        local labelnum = self.itemNum >= self.itemConfigs[1] and 13 or 29
        ui.setLabelString(self.coveritems["oneconsume"],self.itemConfigs[1],labelnum)
        self.coveritems["oneconsume"]:setPositionX(-262)
    else
        self.coveritems["onegold"]:setVisible(false)
        ui.setLabelString(self.coveritems["oneconsume"],"本次免费",13)
        self.coveritems["oneconsume"]:setPositionX(-312)
    end
    local labelnum = self.itemNum >= self.itemConfigs[2] and 13 or 29
    ui.setLabelString(self.coveritems["tenconsume"],self.itemConfigs[2],labelnum)
end

function newdriver.setLucky(self)

    ui.setLabelString(self.coveritems.luck,self.data.lucky.."/"..gamedata.config.global_kv.new_generals_value_up.value,14)
    local persent = self.data.lucky*100/tonumber(gamedata.config.global_kv.new_generals_value_up.value)
    if not self.coveritems.luckyprocess then
        local luckSpr = CCSprite:createWithSpriteFrame(ui.itemcache:getSpriteFrame("laohuji_09.png"))
        self.coveritems.luckyprocess = CCProgressTimer:create(luckSpr)
        self.coveritems.luckyprocess:setAnchorPoint(ccp(0.5,0))
        self.coveritems.luckyprocess:setType(kCCProgressTimerTypeBar)
        self.coveritems.luckyprocess:setMidpoint(ccp(0.5,0))
        self.coveritems.luckyprocess:setBarChangeRate(ccp(0,1))
        self.coveritems.luckyprocess:setPercentage(persent)
        self.coveritems.processNode:addChild(self.coveritems.luckyprocess)
    else
        local processSpr = CCProgressTo:create(0.2,persent)
        self.coveritems.luckyprocess:runAction(processSpr)
    end

    if persent>=100 then
        self.luckccb:setVisible(true)
        self.luckbanimationManager:runAnimationsForSequenceNamed("1")
    else
        self.luckccb:setVisible(false)
    end

    self:setSuperRewardActive(persent>=100)
end

function newdriver.clearLucky(self,callback)
    if self.coveritems.luckyprocess then
        local processSpr = CCProgressTo:create(0.2,0)
        self.coveritems.luckyprocess:runAction(CCSequence:createWithTwoActions(processSpr, CCCallFunc:create(function()
            if callback then callback() end
        end)))
    end
end

function newdriver.setSuperRewardActive(self,isactivity)
    for k,v in pairs(self.superReward) do
        v.animationManager:runAnimationsForSequenceNamed(isactivity and "effect" or "big")
    end
end

function newdriver.setOneReward(self,idx,data)
    local cid,num = ui.getIDandNUM(data.itemid)

    ui.setNewIcon(self.coveritems,{cid = cid,num = num},idx-1)

    if data.label and data.label==1 then
        self.superReward[idx] = {}
        self.superReward[idx].node,self.superReward[idx].item = CCBReaderLoad("UIEffect/tigerchicken/tigerchicken_bigjiangli",nil, true, "tigerchicken_bigjiangli")
        self.coveritems["bigjianglinode"..self:getKeyext(idx)]:addChild(self.superReward[idx].node)
        self.superReward[idx].animationManager = getAnimationManager(self.superReward[idx].item)
        self.superReward[idx].animationManager:runAnimationsForSequenceNamed("big")

        if #self.bigpos ==0 or idx > self.bigpos[#self.bigpos] then
            self.bigpos[#self.bigpos+1] = idx
        end
    end
end

function newdriver.setRewards(self)
    --
    if self.superReward and next(self.superReward) then return end
    if not self.new_generals_lottery then return end
    for i=1,table.getTableLength(self.new_generals_lottery) do
        self:setOneReward(i,self.new_generals_lottery[tostring(i)])
    end
end

function newdriver.getKeyext(self,id)
    local key_Ex
    if id == nil or id == 1 then
        key_Ex = ""
    else
        key_Ex = "_"..(id-1)
    end
    return key_Ex
end

function newdriver.showLocator(self,idx,issingle)
    print("showLocator",idx,issingle)
    if issingle then
        for i=1,12 do
            self.coveritems["locator"..self:getKeyext(i)]:setVisible(i==idx)
        end
    else
        local locator = self.coveritems["locator"..self:getKeyext(idx)]
        locator:setVisible(true)
        locator:setScale(1.5)
        local scaleTo = CCScaleTo:create(0.2, 1)
        local backOut = CCEaseOut:create(scaleTo,5)
        locator:runAction(backOut)
    end

end

function newdriver.randomReward(self,idx,reward)
    print("randomReward",idx)
    local total = 12
    local totalsteps = 2*total+idx

    local delaytime = 0
    for i=1,totalsteps do

        if totalsteps - i >= #self.steptimes then
            delaytime = delaytime + 0.1
        else
            delaytime = delaytime + self.steptimes[#self.steptimes-(totalsteps - i)]
        end

        print("delaytime===========",delaytime)
        local location = math.mod(i,total)
        if location == 0 then location = total end
        self.coveritems["locator"..self:getKeyext(location)]:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(delaytime), CCCallFunc:create(function()
            print("delaytime",i)
            self:showLocator(location,true)
            if i== totalsteps then
                self:playTargetReward(location,function() self:showReward(reward) end)
            end
        end)))
    end

end

function newdriver.randomRewardbig(self,idx,reward)
    local bigidx = 1
    for k,v in ipairs(self.bigpos) do
        if v==idx then bigidx = k end
    end

    local total = 4
    local totalsteps = 2*total+bigidx

    local delaytime = 0
    for i=1,totalsteps do

        if totalsteps - i >= 3 then
            delaytime = delaytime + 0.1
        else
            delaytime = delaytime + self.steptimes[#self.steptimes-(totalsteps - i)]
        end

        local location = math.mod(i,total)
        if location == 0 then location = total end
        print("location1==",location)
        location = self.bigpos[location]
        print("location2==",location)
        self.coveritems["locator"..self:getKeyext(location)]:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(delaytime), CCCallFunc:create(function()
            self:showLocator(location,true)
            if i== totalsteps then
                self:playTargetReward(location,function() self:showReward(reward) end)
            end
        end)))
    end
end

function newdriver.randomRewardTen(self,idxs,reward)

    self.coveritemsanimationManager:runAnimationsForSequenceNamed("ten")
    local total = table.getTableLength(idxs)

    local step = 1
    local function onereward()
        if step > total then
            self:showReward(reward)

        else
            local idx = idxs[tostring(step)]
            if self.data.lucky >= tonumber(gamedata.config.global_kv.new_generals_value_up.value) or self.new_generals_lottery[tostring(idx)].label ==1 then
                self.data.lucky = 0
            else
                self.data.lucky = self.data.lucky +1
            end
            self:showLocator(idx)
            self:setLucky()

            if self.data.lucky >= tonumber(gamedata.config.global_kv.new_generals_value_up.value) then
                self.coveritems["locator"..self:getKeyext(idx)]:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.5),CCCallFunc:create(function()
                    self:playTargetReward(idx,function()
                        step = step +1
                        onereward()
                    end)
                end)))
            else
                self:playTargetReward(idx,function()
                    step = step +1
                    onereward()
                end)
            end
        end
    end
    onereward()
end


function newdriver.playReward(self,t)
    self:requestItemNum()
    gameTouch:clickprofbytime(7)
    self:setbuttonEnabled(false)
    local getnum = table.getTableLength(t.getindex)
    local totalluck = tonumber(gamedata.config.global_kv.new_generals_value_up.value)
    if getnum == 1 then
        if self.data.lucky>= totalluck and t.data.lucky == 0 and self.new_generals_lottery[tostring(t.getindex["1"])].label ==1 then
            self:clearLucky(function() self:randomRewardbig(t.getindex["1"],t.reward) end)
        else
            self:randomReward(t.getindex["1"],t.reward)
        end
    elseif getnum > 1 then
        self:randomRewardTen(t.getindex,t.reward)
    end
end

function newdriver.playTargetReward(self,idx,callback)
    print("playTargetReward")
    self.coveritems["generalnode"]:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.3), CCCallFunc:create(function()
        if self.new_generals_lottery[tostring(idx)].label ==1 then
            local ccb,item = CCBReaderLoad("UIEffect/tigerchicken/tigerchicken_lihua",nil, true, "tigerchicken_lihua")
            ccb:setPosition(ccp(540*GameScene.scaleNum,960*GameScene.scaleNum+gameConfig.fixH))
            ccb:setScale(GameScene.scaleNum)
            mainScene:addChild(ccb,10000)
            local animationManager = getAnimationManager(item)
            animationManager:setAnimationCompletedCallback(function()
                ccb:removeFromParentAndCleanup(true)
                if callback then callback() end
            end)
            animationManager:runAnimationsForSequenceNamed("Default Timeline")
        else
            if callback then callback() end
        end
    end)))
end

function newdriver.showReward(self,reward)
    gameTouch:setClickProf(false)
    showRewardPopupWindow(reward, nil,function() self:showLocator(0,true) UIRequest({type = 5020}) end)
    self.coveritemsanimationManager:runAnimationsForSequenceNamed("one")
    self:setbuttonEnabled(true)
end

function newdriver.setbuttonEnabled(self,bool)
    self.coveritems["onebutton"]:setTouchEnabled(bool)
    self.coveritems["tenbutton"]:setTouchEnabled(bool)
end

function newdriver.clear(self)
    self.data = {}
    self.show = false
    self.itemNum = 0
    self.superReward = {}

    self.coverccb = nil
    self.coveritems = nil
end

function newdriver.initgambling(self)
    if gamedata.config.build[tostring(354)] and gamedata.config.build[tostring(354)].switch == 1 then
        ui.setLabelString(self.coveritems.tentext,gameConfig.strings:string_common("fixedString","shop",24),19)
        ui.setLabelString(self.coveritems.onetext,gameConfig.strings:string_common("fixedString","shop",25),19)
        self.coveritems["gamblingNode"]:setVisible(false)
        if false and self.coveritems["gamblingNode"] then
            self.coveritems["gamblingNode"]:setVisible(true)
            ui.setLabelString(self.coveritems.tentext,"购买十次",19)
            ui.setLabelString(self.coveritems.onetext,"购买一次",19)
            local gamblingconfig = gamedata.config.gambling
            local rewardPropCid,rewardPropNum = ui.getIDandNUM(gamblingconfig["8"]["reward1"])
            local richdata = ui.IDconfig(rewardPropCid)
            ui.setLabelString(self.coveritems["tigerCostLab"],gameConfig.strings:tigerPropname(richdata.name),14)
        end
    end
end

return newdriver