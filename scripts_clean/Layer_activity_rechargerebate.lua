--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/4/12
-- Time: 14:13
-- To change this template use File | Settings | File Templates.
--  ui.setLabelString()     741


local rechargerebate = {
    buttontouch = -103,
    data = {},
    activitytype = 1,
}


function rechargerebate.init(self,size)
    self.contentsize = size
    self.show = true

    if gamedata.config.build[tostring(274)] and gamedata.config.build[tostring(274)].switch and gamedata.config.build[tostring(274)].switch == 1 then
        self.coverccb, self.coveritems = CCBReaderLoad("activityqixi/qixi_chongzhifanli",nil, true, "chongzhifanli")
    else
        self.coverccb, self.coveritems = CCBReaderLoad("activityreward_new/chongzhifanli",nil, true, "chongzhifanli")
    end
    self.coveritems.topnode:setPositionY(self.contentsize.y-180)

    --
    local activityConfig = gamedata.config.activity_time
    if activityConfig[tostring(69)].param and activityConfig[tostring(69)].param == 2 then
        self.activitytype = 2
    else
        self.activitytype = 1
    end

    if self.activitytype == 2 then
        self.coveritems.sprite_recharge:setVisible(false)
        self.coveritems.sprite_consume:setVisible(true)
        ui.setLabelString(self.coveritems.rechargeLab,gameConfig.strings:string_common("rebate",2),14)
    else
        self.coveritems.sprite_recharge:setVisible(true)
        self.coveritems.sprite_consume:setVisible(false)
        ui.setLabelString(self.coveritems.rechargeLab,gameConfig.strings:string_common("rebate",1),14)
    end

    ui.setLabelString(self.coveritems.timeLab,gameConfig.strings:string_common("rebate",3),14)
    ui.setLabelString(self.coveritems.returnLab,gameConfig.strings:string_common("rebate",4),14)

    --
    local bateconfig = gamedata.config.rebate and gamedata.config.rebate[tostring(self.activitytype)] or {}
    self.coveritems.reward1:setPositionX(741*bateconfig.rmb1/bateconfig.rmb3)
    self.coveritems.reward2:setPositionX(741*bateconfig.rmb2/bateconfig.rmb3)
    self.coveritems.reward3:setPositionX(741)
    self.coveritems.desc:setString(gameConfig.strings:rebatedesc(self.activitytype,(bateconfig.proportion or 0)*100,bateconfig.max or 0))
    --
    -- 活动时间
    local timediff = 0
    if self.coveritems.time and gamedata.config.activity_time["69"]["open_type"] and gamedata.config.activity_time["69"]["open_type"] == 2 then
        self.coveritems.timenode:setVisible(false)
    elseif self.coveritems.time and gamedata.config.activity_time["69"]["open_type"] and gamedata.config.activity_time["69"]["open_type"] == 1 then
        self.coveritems.timenode:setVisible(true)
        local nowtime = gamedata:time()
        local temp = os.date("*t", GameScene.roleinfo.servertime)
        timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["69"]["continued_time"]+(gamedata.config.activity_time["69"]["days_later"] or 0))- nowtime - temp.hour*3600 - temp.min*60 - temp.sec
        if timediff < 0 then
            timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["69"]["continued_time"]+(gamedata.config.activity_time["69"]["days_later2"] or 0))- nowtime - temp.hour*3600 - temp.min*60 - temp.sec
        end
    elseif self.coveritems.time and gamedata.config.activity_time["69"]["end"] and gamedata.config.activity_time["69"]["end"] ~= "" then
        self.coveritems.timenode:setVisible(true)
        local year1,month1,day1,hour1,minute1,second1 = ui.getDate(gamedata.config.activity_time["69"]["end"])
        local time1 = os.time({year=year1, month=month1, day=day1, hour=hour1, min = minute1, sec =  second1})
        local nowtime = gamedata:time()
        timediff = time1-nowtime;
    elseif self.coveritems.time then
        self.coveritems.timenode:setVisible(false)
    end

    if self.coveritems.time and timediff and timediff > 0 then
        gameTimer:rigistTime("Activityrebate",timediff)

        if gameTimer.times["Activityrebate"] and gameTimer.times["Activityrebate"] > 0 then
            gameTimer:rigistTimeFunc("Activityrebate", function()
                if gameTimer.times["Activityrebate"] <= 0 then
                    if gameTimer.times["Activityrebate"] then
                        gameTimer:UnrigistTimeFunc("Activityrebate")
                    end
                else
                    ui.setLabelString(self.coveritems.time,ui.makeTimeDayText(gameTimer.times["Activityrebate"],"day"),23)
                end
            end)
        end
    end

    --
    return self.coverccb
end

function rechargerebate.reloaddata(self,data)
    if not self.show then return end
    if data and data.data then
        self.data = data.data or {}
    end

    local bateconfig = gamedata.config.rebate and gamedata.config.rebate[tostring(self.activitytype)] or {}

    ui.setLabelString(self.coveritems.rechargeNum,(self.data.num or 0)..(self.activitytype == 1 and gameConfig.strings:string_common("rebate",7) or ""),21)
    ui.setLabelString(self.coveritems.returnNum,self.data.rebate or 0,21)

    ui.setSpriteTextureRect2(self.coveritems.pos,0,0,741 * ((self.data.num > bateconfig.rmb3) and bateconfig.rmb3 or self.data.num) / bateconfig.rmb3, 31)

    for i = 1,3 do
        if self.activitytype == 1 then
            ui.setLabelString(self.coveritems["num"..i],gameConfig.strings:string_common("rebate",5)..bateconfig["rmb"..i]..gameConfig.strings:string_common("rebate",7),14)
        else
            ui.setLabelString(self.coveritems["num"..i],gameConfig.strings:string_common("rebate",6)..bateconfig["rmb"..i]..gameConfig.strings:string_common("rebate",8),14)
        end
        --
        local reward = ui.getIDandNUMs(bateconfig["reward"..i])
        if self.data["status"..i] and self.data["status"..i] == 1 then
            setSpriteFrameByName(self.coveritems["box"..i], "box4_1")
            self.coveritems["button"..i]:setTouchPriority(self.buttontouch)
            self.coveritems["button"..i]:addHandleOfControlEvent(function()
                if GameScene.layers["activity"].module.isContentScroll then  return end
                gameTouch:clickprofbytime(1)
                UIRequest({type = 4851,index = i})
            end, CCControlEventTouchUpInside)
        elseif self.data["status"..i] and self.data["status"..i] == 2 then
            setSpriteFrameByName(self.coveritems["box"..i], "box4_2")
            self.coveritems["button"..i]:setTouchPriority(self.buttontouch)
            self.coveritems["button"..i]:addHandleOfControlEvent(function()
                if GameScene.layers["activity"].module.isContentScroll then  return end
                gameTouch:clickprofbytime(0.5)
                gameWindows:openWindow("getStaff",{data = reward,type = gameConfig.strings:string_common("moreCommon",5)},nil)
            end, CCControlEventTouchUpInside)
        else
            setSpriteFrameByName(self.coveritems["box"..i], "box4_0")
            self.coveritems["button"..i]:setTouchPriority(self.buttontouch)
            self.coveritems["button"..i]:addHandleOfControlEvent(function()
                if GameScene.layers["activity"].module.isContentScroll then  return end
                gameTouch:clickprofbytime(0.5)
                gameWindows:openWindow("getStaff",{data = reward,type = gameConfig.strings:string_common("task",6)},nil)
            end, CCControlEventTouchUpInside)
        end
    end

end



function rechargerebate.clear(self)

    if gameTimer.times["Activityrebate"] then
        gameTimer:UnrigistTimeFunc("Activityrebate")
    end
    self.data = {}
    self.show = false
    self.coverccb = nil
    self.coveritems = nil
end





return rechargerebate