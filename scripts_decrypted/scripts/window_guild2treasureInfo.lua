--
-- 工会战城池详细信息 treasureInfo
-- User: zhangzhixin
-- Date: 2016/1/26
-- To change this template use File | Settings | File Templates.
--

local windowTreasureInfo = {
    rootNode = nil,
    rootItems = nil,
    png = { --图片名字 已经隐藏图片资源保存图片
        [1] = "gonghuizhan_weikaiqi.png", --报名未开启
        [2] = "gonghuizhan_01",     --报名攻打
        [3] = "gonghuizhan_25.png", --已报名
        [4] = "gonghuizhan_02.png", --报名已截止
        [5] = "gonghuizhan_03",     --进入战场
        [6] = "gonghuizhan_24", --查看战斗
        [7] = "gonghuizhan_24", --查看战斗
        [8] = "gonghuizhan_24",  --查看战斗
    },
    time = {
        [0] = {wday = 5,hour = 9,min= 59,sec = 60}, --报名开始
        [1] = {wday = 6,hour = 23,min= 59,sec = 60},--报名结束
        [2] = {wday = 7,hour = 19,min= 59,sec = 60},--可进入战场
        [3] = {wday = 7,hour = 20,min= 29,sec = 60},--可看第一场
        [4] = {wday = 7,hour = 21,min= 59,sec = 60},--可领奖
    },

    --
}

function windowTreasureInfo.open(self,touchPriority,data,callback)

    if gamedata.config.gang2_battleTime and gamedata.config.gang2_battleTime["1"] and gamedata.config.gang2_battleTime["1"]["1"] and gamedata.config.gang2_battleTime["1"]["1"].weektime_open and gamedata.config.gang2_battleTime["1"]["1"].weektime_open > 0 then
        local hour_1,min_1,sec_1 = ui.getGangBattleTime(gamedata.config.gang2_battleTime["1"]["5"].overtime)
        local hour_2,min_2,sec_2 = ui.getGangBattleTime(gamedata.config.gang2_battleTime["2"]["5"].overtime)
        local nowtime = os.date("*t", gamedata:time())
        local thistimes = "1"
        if (nowtime.wday > (gamedata.config.gang2_battleTime["2"]["5"].weektime_over>6 and 1 or (gamedata.config.gang2_battleTime["2"]["5"].weektime_over+1)) ) or ((nowtime.wday == (gamedata.config.gang2_battleTime["2"]["5"].weektime_over>6 and 1 or (gamedata.config.gang2_battleTime["2"]["5"].weektime_over+1))) and (nowtime.hour > hour_2 or ((nowtime.hour == hour_2) and (nowtime.min > min_2)))) then
            thistimes = "1"
        elseif (nowtime.wday > (gamedata.config.gang2_battleTime["1"]["5"].weektime_over>6 and 1 or (gamedata.config.gang2_battleTime["1"]["5"].weektime_over+1))) or ((nowtime.wday == (gamedata.config.gang2_battleTime["1"]["5"].weektime_over>6 and 1 or (gamedata.config.gang2_battleTime["1"]["5"].weektime_over+1))) and (nowtime.hour > hour_1 or ((nowtime.hour == hour_1) and (nowtime.min > min_1)))) then
            thistimes = "2"
        end
        --
        local hour0,min0,sec0 = ui.getGangBattleTime(gamedata.config.gang2_battleTime[thistimes]["1"].opentime)
        local hour1,min1,sec1 = ui.getGangBattleTime(gamedata.config.gang2_battleTime[thistimes]["1"].overtime)
        local hour2,min2,sec2 = ui.getGangBattleTime(gamedata.config.gang2_battleTime[thistimes]["2"].opentime)
        local hour3,min3,sec3 = ui.getGangBattleTime(gamedata.config.gang2_battleTime[thistimes]["3"].overtime)
        local hour4,min4,sec4 = ui.getGangBattleTime(gamedata.config.gang2_battleTime[thistimes]["5"].opentime)
        --
        self.time[0].wday = (gamedata.config.gang2_battleTime[thistimes]["1"].weektime_open > 6) and 1 or (gamedata.config.gang2_battleTime[thistimes]["1"].weektime_open + 1)
        self.time[0].hour,self.time[0].min,self.time[0].sec = hour0,min0,sec0
        self.time[1].wday = (gamedata.config.gang2_battleTime[thistimes]["1"].weektime_over > 6) and 1 or (gamedata.config.gang2_battleTime[thistimes]["1"].weektime_over + 1)
        self.time[1].hour,self.time[1].min,self.time[1].sec = hour1,min1,sec1
        self.time[2].wday = (gamedata.config.gang2_battleTime[thistimes]["2"].weektime_open > 6) and 1 or (gamedata.config.gang2_battleTime[thistimes]["2"].weektime_open + 1)
        self.time[2].hour,self.time[2].min,self.time[2].sec = hour2,min2,sec2
        self.time[3].wday = (gamedata.config.gang2_battleTime[thistimes]["3"].weektime_over > 6) and 1 or (gamedata.config.gang2_battleTime[thistimes]["3"].weektime_over + 1)
        self.time[3].hour,self.time[3].min,self.time[3].sec = hour3,min3,sec3
        self.time[4].wday = (gamedata.config.gang2_battleTime[thistimes]["5"].weektime_open > 6) and 1 or (gamedata.config.gang2_battleTime[thistimes]["5"].weektime_open + 1)
        self.time[4].hour,self.time[4].min,self.time[4].sec = hour4,min4,sec4
    end

    --

    self.touchPriority = touchPriority
    self.root = CCNode:create()
	self.rootNode, self.rootItems = CCBReaderLoad("gonghuizhan/gonghuizhan_tc_baozanginfo", nil, true, "treasureInfo")
	print("windowTreasureInfo gonghuizhan_tc_baozanginfo rootItems ============")
	-- printT(self.rootItems)
    self.cityawardData = gamedata.config.gang2_cityaward
    -- print("工会战配置 gamedata.config.gang2_cityaward")
    -- printT(self.cityawardData)
    -- printT(data,"data ==========")

    self.isleader = data and data.isleader or 0 --是不是工会会长或者副会长
    self.id = data and data.id or 1
    self.root:addChild(self.rootNode)
    UIRequest({ type=2131,id = data.id})
    return self.root
end

function windowTreasureInfo.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    gameTimer:UnrigistTimeFunc("windowTreasureInfo")
end

function windowTreasureInfo.reload(self,data )
    printT(data,"data ==========") 
    self:loadTreasureInfo(data.treasureInfo)

end

function windowTreasureInfo.guildnumberdata(self,aiData)
    self.guildnumberdata = aiData
    print("windowTreasureInfo.guildnumberdata(self,aiData) ========")
    printT(aiData)
end
function windowTreasureInfo.changeState(self,aiData)
    self.data.guildstate = 2
    self:loadTreasureInfo(self.data)     
end
--报名和报名截止
function windowTreasureInfo.changeShow( self,aiBool )
    self.rootItems.noSignUpNode:setVisible(not aiBool)
    self.rootItems.signUpNode:setVisible(aiBool)
    self.rootItems.signUp:setTouchEnabled(aiBool)
    self.rootItems.signUp:setSwallowsTouch(aiBool)
    ui.removeGray("CCControlButton",self.rootItems.signUp)
end
function windowTreasureInfo.showATK(self,aiType)
    
    if aiType == 0 then -- 报名未开启
        self:changeShow(false)
        setSpriteFrameByName(self.rootItems.noSignUp,self.png[1])
        self.rootItems.explain3:setVisible(false)
        self.rootItems.countdown:setVisible(false)
    elseif aiType == 1 then --报名攻打
        self:changeShow(true)
        setControlButtonFrame(self.rootItems.signUp,self.png[2],self.png[2],self.png[2])
        self.rootItems.explain3:setVisible(true)
        self.rootItems.explain3:setString(gameConfig.strings:string_common("guild_treasureinfo",3))
        self.rootItems.countdown:setVisible(true)  
        self:updatetimeFunc(1)    
    elseif aiType == 2 then --已报名
        self:changeShow(false)
        setSpriteFrameByName(self.rootItems.noSignUp,self.png[3])  
        self.rootItems.explain3:setVisible(true)
        self.rootItems.explain3:setString(gameConfig.strings:string_common("guild_treasureinfo",3))
        self.rootItems.countdown:setVisible(true) 
        self:updatetimeFunc(2)                
    elseif aiType == 3 then --报名截止
        self:changeShow(false)
        setSpriteFrameByName(self.rootItems.noSignUp,self.png[4])  
        self.rootItems.explain3:setVisible(true)
        self.rootItems.explain3:setString(gameConfig.strings:string_common("guild_treasureinfo",4))
        self.rootItems.countdown:setVisible(true) 
        self:updatetimeFunc(3)        
    elseif aiType == 4 then --进入战场
        self:changeShow(true)
        setControlButtonFrame(self.rootItems.signUp,self.png[5],self.png[5],self.png[5])
        self.rootItems.explain3:setVisible(true)
        self.rootItems.explain3:setString(gameConfig.strings:string_common("guild_treasureinfo",5))
        self.rootItems.countdown:setVisible(true) 
        self:updatetimeFunc(4)                
    elseif aiType == 5 then --战前准备
        self:changeShow(true)
        setControlButtonFrame(self.rootItems.signUp,self.png[6],self.png[6],self.png[6])
        ui.addGray("CCControlButton",self.rootItems.signUp)
        self.rootItems.explain3:setVisible(true)
        self.rootItems.explain3:setString(gameConfig.strings:string_common("guild_treasureinfo",22))
        self.rootItems.countdown:setVisible(true)
        self:updatetimeFunc(5)                  
    elseif aiType == 6 then --查看战斗
        self:changeShow(true)
        setControlButtonFrame(self.rootItems.signUp,self.png[7],self.png[7],self.png[7])
        self.rootItems.explain3:setVisible(true)
        self.rootItems.explain3:setString(gameConfig.strings:string_common("guild_treasureinfo",19))
        self.rootItems.countdown:setVisible(true) 
        self:updatetimeFunc(6)              
    elseif aiType == 7 then --没有公会参战
        self:changeShow(true)
        setControlButtonFrame(self.rootItems.signUp,self.png[8],self.png[8],self.png[8]) 
        self.rootItems.countdown:setVisible(false)  
        self.rootItems.explain3:setVisible(false)            
    elseif aiType == 8 then --截止战斗无倒计时 
        self:changeShow(false)
        setSpriteFrameByName(self.rootItems.noSignUp,self.png[4]) 
        self.rootItems.countdown:setVisible(false)  
        self.rootItems.explain3:setVisible(false)
    end
end

function windowTreasureInfo.setATKCallback( self,aiType )
    if aiType == 0 then
        print("报名未开启")
    elseif aiType == 1 then
        local cityconfig = gamedata.config.gang2_cityaward[tostring(self.id)]

        if self.isleader == 0 then
            runGamePrompt({msg = "请让公会会长或副会长前来报名参加"})
        elseif tonumber(self.data.guildlevel) < tonumber(cityconfig.level) then
            runGamePrompt({msg = gameConfig.strings:guildWarBMLv(cityconfig.level)})
        elseif self.data.guildnum > 0 then
            gameWindows:openWindow("guildtreasuretips",{num = self.data.guildnum,name = self.cityawardData[tostring(self.id)].name,guildid =self.data.guildid ,id = self.id })
        elseif self.data.guildnum <= 0 then
            runGamePrompt({msg = "您的公会已报满"})
        end
    elseif aiType == 2 then
        print("已报名")
    elseif aiType == 3 then
        print("报名截止")
    elseif aiType == 4 then
        print("进入战场")
        --GameScene:shiftLayer("guildprepare","up",{ pointId = self.id })
        UIRequest({type = 2134, id = self.id})
    elseif aiType == 5 then
        print("战前准备")
        runGamePrompt({msg = "正在攻打中，请稍后"})
        -- GameScene:shiftLayer("guildprepare","up",{ pointId = self.id })
    elseif aiType == 6 then
        print("查看战斗")
        UIRequest({type = 2138, id = self.id})
    elseif aiType == 7 then
        print("没有公会参战")
        runGamePrompt({msg = "没有公会参战"})
    elseif aiType == 8 then
        print("无工会报名攻打此据点 截止战斗无倒计时")
        runGamePrompt({msg = "没有公会报名"})
    end    
end
--初始化宝藏界面
function windowTreasureInfo.loadTreasureInfo( self,aiData )
    print("windowTreasureInfo.loadTreasureInfo( self,aiData )")
    printT(aiData)
    self.data = aiData
    self.rootItems.titleText:setString("宝藏"..self.id)
    if aiData.guildname == "" or aiData.guildname == nil then
        self.rootItems.icon_atk:setVisible(false)
        self.rootItems.icon_lv:setVisible(false)
        self.rootItems.level:setVisible(false)
        self.rootItems.atk:setVisible(false)
        ui.setLabelString(self.rootItems.name,gameConfig.strings:string_common("guild_treasureinfo",7),1)
        self.rootItems.name:setPositionX(self.rootItems.name:getContentSize().width*0.5 )
    else
        ui.setLabelString(self.rootItems.level,aiData.guildlevel,14)
        ui.setLabelString(self.rootItems.name,aiData.guildname,1)
        self.rootItems.atk:setString(aiData.guildatk)  --font
    end
    local idAndNum1 = ui.Split(self.cityawardData[tostring(self.id)].president,",")
    ui.setNewIconName(self.rootItems,{cid = tonumber(idAndNum1[1]),num = tonumber(  ui.Split(idAndNum1[2] ,";")[1] )})
    local idAndNum2 = ui.Split(self.cityawardData[tostring(self.id)].vice_president,",")
    ui.setNewIconName(self.rootItems,{cid = tonumber( idAndNum2[1]),num = tonumber( ui.Split(idAndNum2[2] ,";")[1])},1)
    local idAndNum3 = ui.Split(self.cityawardData[tostring(self.id)].member,",")
    ui.setNewIconName(self.rootItems,{cid = tonumber( idAndNum3[1]),num = tonumber( ui.Split(idAndNum3[2] ,";")[1])},2)
    ui.setLabelString(self.rootItems.itemTime,gameConfig.strings:gangbattletime3(self.time[4].wday,self.time[4].hour,self.time[4].min,self.time[4].sec),4)
    ui.setLabelString(self.rootItems.defense,aiData.guilddefense,24)
    -- ui.setLabelString(self.rootItems.changeDefense,tonumber(self.cityawardData[tostring(self.id)].att)*100 .."%",24)
    ui.setLabelString(self.rootItems.changeDefense, (gamedata.config.global_kv.def_reduce.value or 0),24)
    ui.setLabelString(self.rootItems.atkPercent,aiData.guildatkpercent.."%",24)

    ui.setLabelString(self.rootItems.lookSignUpLabel,gameConfig.strings:string_common("guild_treasureinfo",18),19)
    ui.setLabelString(self.rootItems.lookWarLabel,gameConfig.strings:string_common("guild_treasureinfo",17),19)
    self:showATK(aiData.guildstate)
    self.rootItems.signUp:addHandleOfControlEvent(function()
        self:setATKCallback( aiData.guildstate ) 
    end, CCControlEventTouchUpInside)
    self.rootItems.signUp:setTouchPriority(self.touchPriority)

    self.rootItems.explain1:setString(gameConfig.strings:gangbattletime1(self.time[0].wday,self.time[0].hour,self.time[0].min,self.time[0].sec,self.time[1].wday,self.time[1].hour,self.time[1].min,self.time[1].sec))
    self.rootItems.explain2:setString(gameConfig.strings:gangbattletime2(self.time[2].wday,self.time[2].hour,self.time[2].min,self.time[2].sec))
    
    self.rootItems.lookSignUp:addHandleOfControlEvent(function()
        print("查看报名")
        gameTouch:clickprofbytime(0.5)
        UIRequest({type = 2133, id = self.id,guildid = self.data.guildid})
    end, CCControlEventTouchUpInside)
    self.rootItems.lookSignUp:setTouchPriority(self.touchPriority)


    self.rootItems.lookWar:addHandleOfControlEvent(function()
        print("上轮战报")
        gameTouch:clickprofbytime(0.5)
        UIRequest({type = 2138, id = self.id})
    end, CCControlEventTouchUpInside)
    self.rootItems.lookWar:setTouchPriority(self.touchPriority)


    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("guildtreasureinfo")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.rootItems.closeButton:setSwallowsTouch(true)   

    --
    local effectconfig = gamedata.config.gang2battle_youhua_type
    if effectconfig and self.rootItems.effect then
        if gamedata.config.gang2_cityaward and gamedata.config.gang2_cityaward[tostring(self.id)] and gamedata.config.gang2_cityaward[tostring(self.id)].bonus_id then
            self.rootItems.effect:setString(effectconfig[tostring(gamedata.config.gang2_cityaward[tostring(self.id)].bonus_id)] and effectconfig[tostring(gamedata.config.gang2_cityaward[tostring(self.id)].bonus_id)].name or "")
        end
    end

end
--更新时间
function windowTreasureInfo.updatetimeFunc(self,aiType)
    if aiType == nil or aiType == 0 then return nil end
    local time = 0
    local nowtime = os.date("*t", gamedata:time())

    if aiType == 1 or aiType == 2 then
        time = (((self.time[1].wday - nowtime.wday) >= 0) and (self.time[1].wday - nowtime.wday) or (self.time[1].wday - nowtime.wday + 6)  )*86400 + (self.time[1].hour - nowtime.hour)*3600 + (self.time[1].min - nowtime.min)*60 + self.time[1].sec - nowtime.sec + 1
    elseif aiType == 3 then
        time = (((self.time[2].wday - nowtime.wday) >= 0) and (self.time[2].wday - nowtime.wday) or (self.time[2].wday - nowtime.wday + 6)  )*86400 + (self.time[2].hour - nowtime.hour)*3600 + (self.time[2].min - nowtime.min)*60 + self.time[2].sec - nowtime.sec + 1
    elseif aiType ==5 or  aiType ==8 then
        time = (((self.time[3].wday - nowtime.wday) >= 0) and (self.time[3].wday - nowtime.wday) or (self.time[3].wday - nowtime.wday + 6)  )*86400 + (self.time[3].hour - nowtime.hour)*3600 + (self.time[3].min - nowtime.min)*60 + self.time[3].sec - nowtime.sec + 1
    elseif aiType ==7 then
        time = (((self.time[4].wday - nowtime.wday) >= 0) and (self.time[4].wday - nowtime.wday) or (self.time[4].wday - nowtime.wday + 6)  )*86400 + (self.time[4].hour - nowtime.hour)*3600 + (self.time[4].min - nowtime.min)*60 + self.time[4].sec - nowtime.sec + 1
    else--if aiType == 4  or  aiType == 6  then
        time = self.data.guildtime + 1
    end    
    print("time = "..time)
    gameTimer:rigistTime("windowTreasureInfo", time)
    gameTimer:rigistTimeFunc("windowTreasureInfo",function()
        if gameTimer.times["windowTreasureInfo"] >= 0 then
            self.rootItems.countdown:setString(ui.makeTimeText(gameTimer.times["windowTreasureInfo"],"hour"))
        end
        if gameTimer.times["windowTreasureInfo"] <= 0  then
            print("windowTreasureInfo===",0)
            UIRequest({ type=2131,id = self.id})
            gameTimer:UnrigistTimeFunc("windowTreasureInfo")
            if  gameWindows.windows["guildtreasuretips"].show  then
                gameWindows:closeWindow("guildtreasuretips")
            end            
        end

    end)
    
end

return windowTreasureInfo   yE  