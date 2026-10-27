--
-- Created by IntelliJ IDEA.
-- User: lipurpose
-- Date: 18/5/28
-- Time: 20:00
-- To change this template use File | Settings | File Templates.
--

local weekCard = {
    buttontouch = -109,
}


function weekCard.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("shop/zhouka",nil, true, "zhouka")
    
    self:initFixedString()
    self.coveritems.topnode:setPositionY(self.contentsize.y-180 + 60)
    self.coveritems.midnode:setPositionY((self.contentsize.y-180)/2 + 60)
    self.coveritems.bottomnode:setPositionY(0 + gameConfig.maiscenebottomheight/3-20)
    self.coveritems.tequanBtn:setTouchPriority(self.buttontouch)
    self.coveritems.tequanBtn:addHandleOfControlEvent(function ()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameWindows:openWindow("weekCardDouble")
    end, CCControlEventTouchUpInside)

    self.coveritems.getButton:setTouchPriority(self.buttontouch)
    self.coveritems.getButton:addHandleOfControlEvent(function ()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        if self.data.getState == 1 then
            gameTouch:clickprofbytime(0.5)
            UIRequest{type = 5803}
        elseif self.data.getState == 2 then
            runGamePrompt({msg = gameConfig.strings:string_common("activity",11)})
        else
            runGamePrompt({msg = gameConfig.strings:string_common("activity",12)})
        end
    end, CCControlEventTouchUpInside)

    self.coveritems.haveGetBtn:setTouchPriority(self.buttontouch)
    self.coveritems.haveGetBtn:addHandleOfControlEvent(function ()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        if self.data.getState == 2 then
            runGamePrompt({msg = gameConfig.strings:string_common("activity",11)})
        end
    end, CCControlEventTouchUpInside)

    local activeFunc = function ()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        if self.propHave >= self.actNum then
            gameTouch:clickprofbytime(0.5)
            UIRequest{type = 5802,useId = self.actProp,useNum = self.actNum}
        else
            local name = ui.IDconfig(self.actProp).name
            runGamePrompt({msg = name..gameConfig.strings:string_common("friendcopy",2)})
        end
    end

    self.coveritems.activeBtn:setTouchPriority(self.buttontouch)
    self.coveritems.activeBtn:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameWindows:openWindow("confirm",{msg = gameConfig.strings:string_common("activity",17)},activeFunc)
    end, CCControlEventTouchUpInside)
    self.coveritems.appendBuy:addHandleOfControlEvent(activeFunc, CCControlEventTouchUpInside)

    self.actProp,self.actNum = ui.getIDandNUM(gamedata.config.weekcardgift[tostring("1")].cost)
    self.propHave = 0
    local idconfig = ui.IDconfig(self.actProp)
    setSpriteFrameByName(self.coveritems.useIcon2,idconfig.icon)
    setSpriteFrameByName(self.coveritems.useIcon,idconfig.icon)
    setSpriteFrameByName(self.coveritems.itemIcon,idconfig.icon)
    self:setTimeShow()

    if self.coveritems.iteminfobutton then
        self.coveritems.iteminfobutton:setTouchPriority(self.buttontouch)
        self.coveritems.iteminfobutton:addHandleOfControlEvent(function ()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            if self.actProp and self.actProp > 0 then
                ui.setPopwindowByCid(self.actProp)
            end    
        end, CCControlEventTouchUpInside)
    end
    
    return self.coverccb
end


function weekCard.setTimeShow(self)
    -- 活动时间
    local cpnum = 0
    local cpday = 0
    local timediff = 0
    if self.coveritems.timeNode then
        self.coveritems.timeNode:setVisible(true)
    end
    if self.coveritems.time and gamedata.config.activity_time["109"]["open_type"] and gamedata.config.activity_time["109"]["open_type"] == 5 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", nowtime)
        timediff = 86400*(gamedata.config.activity_time["109"]["continued_time"..((cpnum == 1) and ("_1") or "")]-cpday+1) - temp.hour*3600 - temp.min*60 - temp.sec
    elseif self.coveritems.time and gamedata.config.activity_time["109"]["open_type"] and gamedata.config.activity_time["109"]["open_type"] == 2 then
        if self.coveritems.timeNode then
            self.coveritems.timeNode:setVisible(false)
        end
    elseif self.coveritems.time and gamedata.config.activity_time["109"]["open_type"] and gamedata.config.activity_time["109"]["open_type"] == 1 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", GameScene.roleinfo.servertime)
        timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["109"]["continued_time"]+(gamedata.config.activity_time["109"]["days_later"] or 0)) - nowtime - temp.hour*3600 - temp.min*60 - temp.sec
        if timediff < 0 then
            timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["109"]["continued_time"]+(gamedata.config.activity_time["109"]["days_later2"] or 0))- nowtime - temp.hour*3600 - temp.min*60 - temp.sec
        end
    elseif self.coveritems.time and gamedata.config.activity_time["109"]["end"] and gamedata.config.activity_time["109"]["end"] ~= "" then
        local year1,month1,day1,hour1,minute1,second1 = ui.getDate(gamedata.config.activity_time["109"]["end"])
        local time1 = os.time({year=year1, month=month1, day=day1, hour=hour1, min = minute1, sec =  second1})
        local nowtime = gamedata:time()
        timediff = time1-nowtime;
    elseif self.coveritems.time then
        if self.coveritems.timeNode then
            self.coveritems.timeNode:setVisible(false)
        end
    end

    if self.coveritems.time and timediff and timediff > 0 then
        gameTimer:rigistTime("ActivityweekCard",timediff)

        if gameTimer.times["ActivityweekCard"] and gameTimer.times["ActivityweekCard"] > 0 then
            gameTimer:rigistTimeFunc("ActivityweekCard", function()
                if gameTimer.times["ActivityweekCard"] <= 0 then
                    if gameTimer.times["ActivityweekCard"] then
                        gameTimer:UnrigistTimeFunc("ActivityweekCard")
                    end
                else
                    self.coveritems.time:setString(ui.makeTimeDayText(gameTimer.times["ActivityweekCard"],"day"))
                    ui.setLabelString(self.coveritems.time,nil,23)
                end
            end)
        end
    end
    if self.coveritems.time then
        ui.setLabelString(self.coveritems.time,nil,23)
        ui.setLabelString(self.coveritems.desc1,gameConfig.strings:string_common("fixedString","activity_fashion",18),14)
    end
end

function weekCard.initFixedString(self)
    ui.setLabelString(self.coveritems.haveFixedText,gameConfig.strings:string_common("fixedString","shop",8),18)
end


function weekCard.reloadData(self,t)
    self.data = t.data
    self:setPropNum()
    local rewardData = ui.getIDandNUMs(gamedata.config.weekcardgift[tostring(1)].daygift)
    for i = 1,#rewardData do
        self.coveritems["reward"..i]:setVisible(true)
        ui.setNewIconName(self.coveritems,rewardData[i],i - 1)

        local k_add = (i - 1 == 0) and "" or "_"..(i-1)
        self.coveritems["i_button"..k_add]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            ui.setPopwindowByCid(rewardData[i].cid)
        end, CCControlEventTouchUpInside)
        self.coveritems["i_button"..k_add]:setTouchPriority(self.buttontouch)
    end
    for i = #rewardData + 1,4 do
        self.coveritems["reward"..i]:setVisible(false)
    end
    self:setGetState()
    if self.data.left > 0 then
        self.coveritems.leftDay:setString(gameConfig.strings:string_format({"activity",15},{""..self.data.left}))
    else
        self.coveritems.leftDay:setString(gameConfig.strings:string_common("activity",16))
    end
end

function weekCard.setGetState(self)
    self.coveritems.getNode:setVisible(self.data.getState == 1)
    self.coveritems.haveGetNode:setVisible(self.data.getState == 2)
    self.coveritems.activeNode:setVisible(self.data.getState == 0 and self.data.left <= 0)
    self.coveritems.appendBuy:setVisible(self.data.getState ~= 0 and self.data.left > 0)
    self.coveritems.useIcon2:setVisible(self.data.getState ~= 0 and self.data.left > 0)
    self.coveritems.useNum2:setVisible(self.data.getState ~= 0 and self.data.left > 0)
end

function weekCard.setPropNum(self,data)
    if not data then
        UIRequest({type = 12001, order = 33011, cids = {self.actProp}})
        return
    end
    local num = data[tostring(self.actProp)] or 0
    self.propHave = num

    local labelnum = self.propHave >= self.actNum and 19 or 19
    ui.setLabelString(self.coveritems.useNum2,"X"..self.actNum,labelnum)
    ui.setLabelString(self.coveritems.useNum,"X"..self.actNum,labelnum)
    ui.setLabelString(self.coveritems.haveNum,"X"..self.propHave,18)
end

function weekCard.getReward(self,t)
    showRewardPopupWindow(t.reward)
    self.data = t.data
    self:setGetState()
end

function weekCard.reSet(self,t)
    showRewardPopupWindow(t.reward)
    self.data = t.data
    if self.data.left > 0 then
        self.coveritems.leftDay:setString(gameConfig.strings:string_format({"activity",15},{""..self.data.left}))
    else
        self.coveritems.leftDay:setString(gameConfig.strings:string_common("activity",16))
    end
    self:setPropNum()
    self:setGetState()
end


function weekCard.clear(self)
    if gameTimer.times["ActivityweekCard"] then
        gameTimer:UnrigistTimeFunc("ActivityweekCard")
    end
    
    self.show = false
    self.tasklistview = nil
    self.tree = nil
    self.main = nil
    self.coverccb = nil
    self.coveritems = nil
    self.data = {}
    self.yulanindex= 0
end


return weekCard