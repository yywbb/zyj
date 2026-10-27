--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/7/4
-- Time: 14:15
-- To change this template use File | Settings | File Templates.
--

local goddown = {
    xgold = 0,
    goddownstatus = {},
    buttontouch = -103,
    animationManager = nil,
    boxid = 1,

    cpnum = 0,
    cpday = 0,
}

function goddown.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("activitypigNew/activitypig",nil, true, "activitypig")
    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    self.coveritems.midnode:setPositionY(self.contentsize.y/2-100)

    --
    self.pigNode,self.pigItems = CCBReaderLoad("UIEffect/zhubajie/zhubajie", nil, true, "pig")
    self.pigNode:setPosition(0,0)
    self.coveritems.pignode:addChild(self.pigNode)
    self.coveritems.pignode:setScale(1)
    self.animationManager = getAnimationManager(self.pigItems)
    self.animationManager:runAnimationsForSequenceNamed("stand")
    --
    --说明
    self.coveritems.ruleButton:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        print("ruleButton")
        gameWindows:openWindow("goddownRule")
    end, CCControlEventTouchUpInside)
    self.coveritems.ruleButton:setSwallowsTouch(true)
    self.coveritems.ruleButton:setTouchPriority(self.buttontouch)
    --排行榜
    self.coveritems.rankButton:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        -- print("rankButton")
        -- GameScene:shiftLayerById(315)

        UIRequest({type = 5017})
    end, CCControlEventTouchUpInside)
    self.coveritems.rankButton:setSwallowsTouch(true)
    self.coveritems.rankButton:setTouchPriority(self.buttontouch)
    --兑换
    self.coveritems.shopButton:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        -- print("shopButton")
        -- GameScene:shiftLayerById(314)
        UIRequest({type = 5015})
        -- gameWindows:openWindow("cp_goddownShop")
    end, CCControlEventTouchUpInside)
    self.coveritems.shopButton:setSwallowsTouch(true)
    self.coveritems.shopButton:setTouchPriority(self.buttontouch)
    --
    --
    return self.coverccb
end


function goddown.reloaddata(self,data)
    if not self.show then return end
    if not data then return end
    gameTouch:clickprofbytime(0.5)
    self.goddownstatus = data and data.goddownstatus

    self.cpnum = data and data.cpnum or 0
    self.cpday = data and data.cpday or 0
    --
    self:initFixedString()
    -- 活动时间
    local timediff = 0
    local timediff2 = 0
    if self.coveritems.activitytime1 and gamedata.config.activity_time["82"]["open_type"] and gamedata.config.activity_time["82"]["open_type"] == 5 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", nowtime)
        timediff = 86400*(gamedata.config.activity_time["82"]["continued_time"..((self.cpnum == 1) and ("_1") or "")]-self.cpday+1) - temp.hour*3600 - temp.min*60 - temp.sec
        if self.cpday > 0 then 
            timediff2 = 86400*(gamedata.config.activity_time["81"]["continued_time"..((self.cpnum == 1) and ("_1") or "")]-self.cpday+1) - temp.hour*3600 - temp.min*60 - temp.sec
        else
            timediff2 = 0
        end    
    elseif self.coveritems.activitytime1 and gamedata.config.activity_time["82"]["open_type"] and gamedata.config.activity_time["82"]["open_type"] == 2 then
        
    elseif self.coveritems.activitytime1 and gamedata.config.activity_time["82"]["open_type"] and gamedata.config.activity_time["82"]["open_type"] == 1 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", GameScene.roleinfo.servertime)
        timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["82"]["continued_time"]+(gamedata.config.activity_time["82"]["days_later"] or 0)) - temp.hour*3600 - temp.min*60 - temp.sec
        if timediff < nowtime then
            timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["82"]["continued_time"]+(gamedata.config.activity_time["82"]["days_later2"] or 0)) - temp.hour*3600 - temp.min*60 - temp.sec
        end
        --
        timediff2 = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["81"]["continued_time"]+(gamedata.config.activity_time["81"]["days_later"] or 0)) - temp.hour*3600 - temp.min*60 - temp.sec
        if timediff2 < nowtime then
            timediff2 = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["81"]["continued_time"]+(gamedata.config.activity_time["81"]["days_later2"] or 0)) - temp.hour*3600 - temp.min*60 - temp.sec
        end
    elseif self.coveritems.activitytime1 and gamedata.config.activity_time["82"]["end"] and gamedata.config.activity_time["82"]["end"] ~= "" then
        local year1,month1,day1,hour1,minute1,second1 = ui.getDate(gamedata.config.activity_time["82"]["end"])
        local time1 = os.time({year=year1, month=month1, day=day1, hour=hour1, min = minute1, sec =  second1})
        local nowtime = gamedata:time()
        timediff = time1-nowtime
        --
        local year2,month2,day2,hour2,minute2,second2 = ui.getDate(gamedata.config.activity_time["81"]["end"])
        local time2 = os.time({year=year2, month=month2, day=day2, hour=hour2, min = minute2, sec = second2})
        timediff2 = time2-nowtime
    elseif self.coveritems.activitytime1 then
        
    end

    print(timediff,"timediff")
    if self.coveritems.activitytime1 and timediff and timediff > 0 then
        ui.setLabelString(self.coveritems.fixlab10,gameConfig.strings:string_common("fixedString","goddown",13),128)
        ui.setLabelString(self.coveritems.fixlab11,gameConfig.strings:string_common("fixedString","goddown",14),128)

        gameTimer:rigistTime("ActivityGoddownCP",timediff)        
        gameTimer:rigistTime("ActivityGoddownCP2",timediff2)
        self.leavTime = gameTimer.times["ActivityGoddownCP2"]
        if gameTimer.times["ActivityGoddownCP"] and gameTimer.times["ActivityGoddownCP"] > 0 then
            gameTimer:rigistTimeFunc("ActivityGoddownCP", function()
                if gameTimer.times["ActivityGoddownCP"] <= 0 then
                    if gameTimer.times["ActivityGoddownCP"] then
                        gameTimer:UnrigistTimeFunc("ActivityGoddownCP")
                    end
                else
                    ui.setLabelString(self.coveritems.activitytime2,ui.makeTimeDayText(gameTimer.times["ActivityGoddownCP"],"day2"),14)
                    if gameTimer.times["ActivityGoddownCP2"] and gameTimer.times["ActivityGoddownCP2"] > 0 then
                        local _tempTime2 = gameTimer.times["ActivityGoddownCP2"]
                        ui.setLabelString(self.coveritems.activitytime1,ui.makeTimeDayText(_tempTime2 >= 0 and _tempTime2 or 0,"day2"),14)
                    else
                        ui.addGray("CCControlButton",self.coveritems.doButton)
                        ui.setLabelString(self.coveritems.fixlab8,gameConfig.strings:string_common("fixedString","goddown",15),14)
                        --UIRequest({type = 5010})
                        ui.setLabelString(self.coveritems.activitytime1,gameConfig.strings:string_common("fixedString","goddown",17),14)
                    end
                end
            end)
        end
    else
        ui.setLabelString(self.coveritems.fixlab10,"",128)
        ui.setLabelString(self.coveritems.fixlab11,"",128)
    end


    if gameTimer.times["ActivityGoddownCP2"] and gameTimer.times["ActivityGoddownCP2"] > 0 then
        ui.removeGray("CCControlButton",self.coveritems.doButton)
        ui.setLabelString(self.coveritems.fixlab8,gameConfig.strings:string_common("fixedString","goddown",8),14)       
    else
        ui.addGray("CCControlButton",self.coveritems.doButton)
        ui.setLabelString(self.coveritems.fixlab8,gameConfig.strings:string_common("fixedString","goddown",15),14)
    end


    ui.setLabelString(self.coveritems.points,self.goddownstatus.point or 0,14)
    ui.setLabelString(self.coveritems.cdtime,"",14)
    self.coveritems.goldnode:setVisible(false)

    local goddown_contribution_reward = {}
    if self.cpnum and self.cpnum > 0 then
        goddown_contribution_reward = gamedata.config["goddown_contribution_reward_"..self.cpnum] or {}
    else
        goddown_contribution_reward = gamedata.config.goddown_contribution_reward
    end
    for i = 1,table.getTableLength(goddown_contribution_reward) do
        self.boxid = i
        if self.goddownstatus.boxstatus and self.goddownstatus.boxstatus[tostring(i)] and self.goddownstatus.boxstatus[tostring(i)] < 2 then
            break
        end
    end
    local rewardconfig = goddown_contribution_reward and goddown_contribution_reward[tostring(self.boxid)] or {}
    if not rewardconfig.cond then return end
    local needext = ""
    local rewards = ui.getIDandNUMs(rewardconfig.reward) or {}
    --
    if self.goddownstatus.boxstatus and self.goddownstatus.boxstatus[tostring(self.boxid)] and self.goddownstatus.boxstatus[tostring(self.boxid)] == 1 then
        if self.coveritems.boxfinish then
            self.coveritems.boxfinish:setVisible(false)
        end
        needext = gameConfig.strings:string_common("activity_goddown",1)
        setSpriteFrameByName(self.coveritems.box_sprite,"box4_1")
        self.coveritems.boxButton:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            print("boxButton")
            gameTouch:clickprofbytime(1)
            UIRequest({type = 5014,id = self.boxid or 1})
        end, CCControlEventTouchUpInside)
        self.coveritems.boxButton:setSwallowsTouch(true)
        self.coveritems.boxButton:setTouchPriority(self.buttontouch)
    elseif self.goddownstatus.boxstatus and self.goddownstatus.boxstatus[tostring(self.boxid)] and self.goddownstatus.boxstatus[tostring(self.boxid)] == 2 then
        if self.coveritems.boxfinish then
            self.coveritems.boxfinish:setVisible(true)
        end
        needext = gameConfig.strings:string_common("activity_goddown",7)
        setSpriteFrameByName(self.coveritems.box_sprite,"box4_2")
        self.coveritems.boxButton:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            print("boxButton")
            gameWindows:openWindow("getStaff",{data = rewards, type = gameConfig.strings:string_common("layer_copy",4)},nil)
        end, CCControlEventTouchUpInside)
        self.coveritems.boxButton:setSwallowsTouch(true)
        self.coveritems.boxButton:setTouchPriority(self.buttontouch)
    else
        if self.coveritems.boxfinish then
            self.coveritems.boxfinish:setVisible(false)
        end
        needext = ""
        setSpriteFrameByName(self.coveritems.box_sprite,"box4_0")
        self.coveritems.boxButton:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            print("boxButton")
            gameWindows:openWindow("getStaff",{data = rewards, type = gameConfig.strings:string_common("layer_copy",3)},nil)
        end, CCControlEventTouchUpInside)
        self.coveritems.boxButton:setSwallowsTouch(true)
        self.coveritems.boxButton:setTouchPriority(self.buttontouch)
    end
    --
    local needcid,neednum = ui.getIDandNUM(rewardconfig.cond)
    ui.setLabelString(self.coveritems.neednum,self.goddownstatus.allpoint or 0,14)
    ui.setLabelString(self.coveritems.needLab,"/"..neednum,21)
    --
    --
    self.xgold = 0
    ui.setLabelString(self.coveritems.xgold,self.xgold,18)
    if gameTimer.times["goddown_reward"] then
        gameTimer:UnrigistTimeFunc("goddown_reward")
    end
    if self.goddownstatus.status and self.goddownstatus.status == 1 then
        --
        local cdminute = gamedata.config.global_kv.goddown_time_cost and tonumber(gamedata.config.global_kv.goddown_time_cost.value) or 2
        if self.goddownstatus.cdtime > 0 then
            self.coveritems.goldnode:setVisible(true)
            self.xgold = math.ceil(self.goddownstatus.cdtime/(60*cdminute))
            ui.setLabelString(self.coveritems.xgold,self.xgold,18)
            ui.setLabelString(self.coveritems.cdtime,gameConfig.strings:string_common("activity_goddown",5)..ui.makeTimeText(self.goddownstatus.cdtime,"hour"),14)
            gameTimer:rigistTime("goddown_reward", self.goddownstatus.cdtime+1)
            gameTimer:rigistTimeFunc("goddown_reward",function()
                if (gameTimer.times["goddown_reward"] >= 0) and (gameTimer.times["goddown_reward"] <= self.goddownstatus.cdtime) then
                    ui.setLabelString(self.coveritems.cdtime,gameConfig.strings:string_common("activity_goddown",5)..ui.makeTimeText(gameTimer.times["goddown_reward"],"hour"),14)
                    self.xgold = math.ceil(gameTimer.times["goddown_reward"]/(60*cdminute))
                    ui.setLabelString(self.coveritems.xgold,self.xgold,18)
                end
                if gameTimer.times["goddown_reward"] <= 0 then
                    self.xgold = 0
                    ui.setLabelString(self.coveritems.xgold,self.xgold,18)
                    UIRequest({type = 5010, update = true})
                    gameTimer:UnrigistTimeFunc("goddown_reward")
                end
            end)
        end
        --
        ui.setLabelString(self.coveritems.doLab,gameConfig.strings:string_common("activity_goddown",4),19)
        self.coveritems.doButton:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            print("doButton1")
            --
            if gameTimer.times["ActivityGoddownCP2"] and gameTimer.times["ActivityGoddownCP2"] > 0 then
            else    
                runGamePrompt({msg = gameConfig.strings:string_common("fixedString","goddown",16)})
                return
            end
            local cb = function()
                gameTouch:clickprofbytime(1)
                UIRequest({type = 5013, xgold = self.xgold})
            end
            gameWindows:openWindow("guildmsg",{msg = gameConfig.strings:goddownImmediateMsg(self.xgold)},cb)

        end, CCControlEventTouchUpInside)
        self.coveritems.doButton:setSwallowsTouch(true)
        self.coveritems.doButton:setTouchPriority(self.buttontouch)
    elseif self.goddownstatus.status and self.goddownstatus.status == 2 then
        ui.setLabelString(self.coveritems.doLab,gameConfig.strings:string_common("activity_goddown",3),19)
        self.coveritems.doButton:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            print("doButton2")
            if gameTimer.times["ActivityGoddownCP2"] and gameTimer.times["ActivityGoddownCP2"] > 0 then
            else    
                runGamePrompt({msg = gameConfig.strings:string_common("fixedString","goddown",16)})
                return
            end
            gameTouch:clickprofbytime(1)
            UIRequest({type = 5012})
        end, CCControlEventTouchUpInside)
        self.coveritems.doButton:setSwallowsTouch(true)
        self.coveritems.doButton:setTouchPriority(self.buttontouch)
    else
        ui.setLabelString(self.coveritems.doLab,gameConfig.strings:string_common("activity_goddown",2),19)
        self.coveritems.doButton:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            print("doButton0")
            if gameTimer.times["ActivityGoddownCP2"] and gameTimer.times["ActivityGoddownCP2"] > 0 then
            else    
                runGamePrompt({msg = gameConfig.strings:string_common("fixedString","goddown",16)})
                return
            end
            --
            gameTouch:clickprofbytime(0.5)
            gameWindows:openWindow("goddownSelect",{querynum = 5011})
            
        end, CCControlEventTouchUpInside)
        self.coveritems.doButton:setSwallowsTouch(true)
        self.coveritems.doButton:setTouchPriority(self.buttontouch)
    end
    --
    --
    if self.animationManager and self.goddownstatus.status and self.goddownstatus.status == 1 then
        if self.goddownstatus.selected >= 1 and self.goddownstatus.selected <= 3 then
            self.animationManager:runAnimationsForSequenceNamed("run"..self.goddownstatus.selected)
        end
    elseif self.animationManager then
        self.animationManager:runAnimationsForSequenceNamed("stand")
    end
end


function goddown.clear(self)

    if gameTimer.times["goddown_reward"] then
        gameTimer:UnrigistTimeFunc("goddown_reward")
    end

    if gameTimer.times["ActivityGoddownCP"] then
        gameTimer:UnrigistTimeFunc("ActivityGoddownCP")
    end


    self.boxid = 1
    self.xgold = 0
    self.goddownstatus = {}
    self.show = false
    self.animationManager = nil
    self.data = nil
    self.coverccb = nil
    self.coveritems = nil
end

function goddown.initFixedString(self)
    self.coveritems.fixlab1:setString(gameConfig.strings:string_common("fixedString","goddown",1))
    self.coveritems.fixlab2:setString(gameConfig.strings:string_common("fixedString","goddown",2))
    self.coveritems.fixlab3:setString(gameConfig.strings:string_common("fixedString","goddown",3))
    self.coveritems.fixlab4:setString(gameConfig.strings:string_common("fixedString","goddown",4))
    self.coveritems.fixlab5:setString(gameConfig.strings:string_common("fixedString","goddown",5))
    self.coveritems.fixlab6:setString(gameConfig.strings:string_common("fixedString","goddown",6))
    self.coveritems.fixlab7:setString(gameConfig.strings:string_common("fixedString","goddown",7))
    ui.setLabelString(self.coveritems.fixlab8,gameConfig.strings:string_common("fixedString","goddown",8),14)
end


return goddown