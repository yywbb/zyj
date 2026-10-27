--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/2/4
-- Time: 14:31
-- To change this template use File | Settings | File Templates.
--

local honorwarNow = {

    groupListTableView = nil,
    groupindex = 1,
    ListTableView = nil,
    resource = nil,

    rootNode = nil,
    rootItems = nil,

    grouprootNode = nil,
    grouprootItems = nil,

    championrootNode1 = nil,
    championrootItems1 = nil,
    championrootNode2 = nil,
    championrootItems2 = nil,
    championrootNode3 = nil,
    championrootItems3 = nil,

    normalCellSize = {x = 1080, y = 420},

    championListccb = {},
    championListccb2 = {},
    pages = {"main","personal","group","champion"},
    selectpage = "personal",
    pageNum = 1,

    buttontouch = -103,

    HonorWarStatus = {},
    HonorWarLastChampion = {},
    honorwarrolebattles = {},
    honorwarplayers = {},
    honorwartop = {},
    isOpenStatus = 0,

    moveIndex = 0,
    originalIndex = 0,
    lastPos = 0,
    isCanPause = true,
    groupname = {
        [1] = "A组",
        [2] = "B组",
        [3] = "C组",
        [4] = "D组",
        [5] = "E组",
        [6] = "F组",
        [7] = "G组",
        [8] = "H组",
    },

    battleNumConfig = {
        [1] = { ["min"] = 0, ["max"] = 2},
        [2] = { ["min"] = 3, ["max"] = 63},
        [3] = { ["min"] = 64, ["max"] = 79},
        [4] = { ["min"] = 80, ["max"] = 85},
        [5] = { ["min"] = 86, ["max"] = 90},
        [6] = { ["min"] = 91, ["max"] = 96}
    },

    descConfig = {
        [1] = "",
        [2] = gameConfig.strings:string_common("fixedString","servicewar",18),
        [3] = gameConfig.strings:string_common("fixedString","servicewar",19),
        [4] = "",
        [5] = "",
        [6] = "",
    },

    ccbDocument= {},
    timers = {},

    hintconfig = {
        {
            name = "rootItems",
            config = {
                achievement = {452},
            },
        },
    },
}

function honorwarNow.showNode( self,node,isshow )
    if isshow then
        node:setPositionX(0)    
        node:setVisible(true) 
    else
        node:setPositionX(-9999)    
        node:setVisible(false) 
    end
end

function honorwarNow.init(self,parent,toppos,param)
    
    self.rootNode,self.rootItems = CCBReaderLoad("rongyaozhizhan/rongyaozhizhan", nil, true, "rongyaozhizhan")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.bg:setPositionY(toppos)
    self.rootItems.midnode:setPositionY((toppos-260)/2)
    self.rootItems.haswarNode:setPositionY(580-((toppos-260)/2-700))
    self.rootItems.listnode:setContentSize(CCSizeMake(1080, 840+(GameScene.topposY-1620)))
    self.rootItems.mask:setPositionY(self.rootItems.listnode:getContentSize().height)
    self.rootItems.maskbottom:setPositionY(180-15)
    if self.rootItems.closeButton then
        self.rootItems.closeButton:setTouchPriority(-103)
        self.rootItems.closeButton:addHandleOfControlEvent(function()
            --GameScene:shiftLayer(GameScene.priorLayer,"up")
            GameScene:shiftLayer("main","down")
        end, CCControlEventTouchUpInside)
    end
    
    self.rootItems.ruleButton:setTouchPriority(self.buttontouch)
    self.rootItems.ruleButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        --todo 规则
        --GameScene:shiftLayer("honorBattleArray","up")
        gameWindows:openWindow("honorBattleRule")
    end, CCControlEventTouchUpInside)
    --时间
    self.rootItems.timeButton:setTouchPriority(self.buttontouch)
    self.rootItems.timeButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        gameWindows:openWindow("honorTime")
    end, CCControlEventTouchUpInside)

    self.rootItems.buffBtn:setTouchPriority(self.buttontouch)
    self.rootItems.buffBtn:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        --buff详情
        if self.HonorWarStatus and self.HonorWarStatus.buff_one ~=0 then
        gameWindows:openWindow("honorBuff",{
            number = self.HonorWarStatus.number,
            buff_one = self.HonorWarStatus.buff_one,
            buff_two = self.HonorWarStatus.buff_two,
            buff_three = self.HonorWarStatus.buff_three
            })
        else
            runGamePrompt({msg = gameConfig.strings:string_common("honorBattle2",39)})

        end
        
    end, CCControlEventTouchUpInside)

    self.rootItems.rewardButton:setTouchPriority(self.buttontouch)
    self.rootItems.rewardButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        --todo 查看奖励
        gameWindows:openWindow("honorBattleReward")
    end, CCControlEventTouchUpInside)

    self.rootItems.listButton:setTouchPriority(self.buttontouch)
    self.rootItems.listButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        --todo 赛区
        UIRequest({type = 6511})
    end, CCControlEventTouchUpInside)

    --
    self.rootItems.rankButton:setTouchPriority(self.buttontouch)
    self.rootItems.rankButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        --todo 积分排名
        UIRequest({type = 6514})
    end, CCControlEventTouchUpInside)
    --
    self.rootItems.pastButton:setTouchPriority(self.buttontouch)
    self.rootItems.pastButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        --todo 历届冠军
        UIRequest({type = 6510})
    end, CCControlEventTouchUpInside)

    --
    self.rootItems.achievementButton:setTouchPriority(self.buttontouch)
    self.rootItems.achievementButton:addHandleOfControlEvent(function()
        gameWindows:openWindow("glory_battle_achievement")
    end, CCControlEventTouchUpInside)
    self.rootItems.achievementButton:setVisible(gameConfig:checkBuildOpen(452))


    ui.setLabelString( self.rootItems.arrayLab,"布 阵",18)
    self.rootItems.arrayBtn:setTouchPriority(self.buttontouch)
    self.rootItems.arrayBtn:addHandleOfControlEvent(function()
        self.arrayData = table.copy(GameScene.layers["slotsInfo"].module.slotdata)
        
        local hasRole = 0
        for k,v in pairs(self.arrayData) do
            if v.general then
                hasRole = hasRole+1
            end
        end
        if hasRole>=3 then 
            GameScene:shiftLayer("honorBattleArray","up",{resttime = gameTimer.times["worldwarupdatetimer"]})
        else 
            runGamePrompt({msg = gameConfig.strings:string_common("honorBattle2",37)})
        end
    end, CCControlEventTouchUpInside)

    for i=1,6 do
        ui.setLabelString(self.rootItems["fixedStr"..i],nil,14)
        self.rootItems["scheduleBtn"..i]:setTouchPriority(self.buttontouch)
        self.rootItems["scheduleBtn"..i]:addHandleOfControlEvent(function()
            if self.HonorWarStatus.list<=0 then
                runGamePrompt({msg = gameConfig.strings:string_common("honorBattle2",42)})
            elseif self.HonorWarStatus.status < self.battleNumConfig[i]["min"] then
                runGamePrompt({msg = gameConfig.strings:string_common("honorBattle2",43)})
            else
                --self.pageNum = i
                self:shiftPageNum(i)
            end
        end, CCControlEventTouchUpInside)
    end

    self.timeconfig = gamedata.config.glory_battle_time

    -- --倒计时
    ui.setLabelString(self.rootItems.endtimelab,gameConfig.strings:string_common("honorBattle2",36),21)
    --

    local tt = 0 
    for k,v in pairs(self.timeconfig) do
        if tonumber(k) > tt then
            tt = tonumber(k)
        end
    end
    tt = tostring(tt)
    local wday = self.timeconfig[tt].over_week+1
    if wday > 7 then wday = 1 end
    local hour,min,sec = ui.getGangBattleTime(self.timeconfig[tt].over_time)
    local nowtime = os.date("*t", gamedata:time())
    local diff = (wday-nowtime.wday)*86400+(hour-nowtime.hour)*3600+(min-nowtime.min)*60+sec-nowtime.sec
    if diff < 0 then diff = diff+86400*7 end
    --倒计时结束后请求  否则更新时间显示
    gameTimer:rigistTime("worldwarendtimer",diff+1)
    gameTimer:rigistTimeFunc("worldwarendtimer",function()
        if gameTimer.times["worldwarendtimer"] <= 0 then
            ui.setLabelString(self.rootItems.endtimelab,"",21)
            ui.setLabelString(self.rootItems.endtime,"",14)
            UIRequest({type = 6503, param = "update"})
        else
            ui.setLabelString(self.rootItems.endtime,ui.makeTimeDayText(gameTimer.times["worldwarendtimer"],"day"),14)
        end
    end)
    --

    --[[local showtime = {{65,67},{69,71},{74,76},{78,80},{83,85},{87,89}}
    for i = 1,6 do
        local timeconfig1 = self.timeconfig[tostring(showtime[i][1])]
        local timeconfig2 = self.timeconfig[tostring(showtime[i][2])]
        local hour1,min1,sec1 = ui.getGangBattleTime(timeconfig1.open_time)
        local hour2,min2,sec2 = ui.getGangBattleTime(timeconfig2.over_time)
        if math.floor(min1/10) < 1 then
            min1 = "0"..min1
        end
        if math.floor(min2/10) < 1 then
            min2 = "0"..min2
        end
        print("+++++++++++++++")
        local timestring = "第"..(gameConfig.strings.bigNum[((i>3) and (i-3) or i)]).."轮比赛：".."周"..gameConfig.strings:string_common("wdayNum",(timeconfig1.open_week+1)>7 and 1 or (timeconfig1.open_week+1)).." "..hour1..":"..min1.." ~ ".."周"..gameConfig.strings:string_common("wdayNum",(timeconfig2.over_week+1)>7 and 1 or (timeconfig2.over_week+1)).." "..hour2..":"..min2
        ui.setLabelString(self.rootItems["showtime"..i],timestring,13)
    end
--]]
    if self.rootItems.group_right then
        self.rootItems.group_right:setTouchPriority(-103)
        self.rootItems.group_right:addHandleOfControlEvent(function()
            if self.groupListTableView then
                local setx = self.groupListTableView:getLuaContentOffsetX()
                if setx - 140 < -240 then
                    self.groupListTableView:setContentOffsetInDuration(ccp(-240 ,0),0.2)
                else
                    self.groupListTableView:setContentOffsetInDuration(ccp(setx - 140 ,0),0.2)
                end
                --self:checkSetX()
            end
        end, CCControlEventTouchUpInside)
    end
    --
    if self.rootItems.group_left then
        self.rootItems.group_left:setTouchPriority(-103)
        self.rootItems.group_left:addHandleOfControlEvent(function()
            if self.groupListTableView then
                local setx = self.groupListTableView:getLuaContentOffsetX()
                if setx + 140 > 0 then
                    self.groupListTableView:setContentOffsetInDuration(ccp(0 ,0),0.2)
                else
                    self.groupListTableView:setContentOffsetInDuration(ccp(setx + 140 ,0),0.2)
                end
                --self:checkSetX()
            end
        end, CCControlEventTouchUpInside)
    end

    self.pausetime = 0

    local socket = require "socket"
    local lasttick = socket.gettime()

    self.scheduleScript = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
        local thistick = socket.gettime()
        if self.pausetime > 0 then
            self.pausetime = self.pausetime-(thistick-lasttick)
        else
            self:moveChampion((thistick-lasttick)*60*1)
        end

        lasttick = socket.gettime()

        --local containerX = self.rootItems.container:getPositionX()
       --self.rootItems.main_left:setVisible(containerX<0)  
       --self.rootItems.main_right:setVisible(containerX>-2620) 

        -- self.rootItems.main_left:setVisible(false)  
        -- self.rootItems.main_right:setVisible(false)
    end, 0, false)

    --AddClickMethod
    
    local touchX = 0
    local function ccTouchBegan(x, y)
        self.pausetime = 2.5
        touchX = x
        return true
    end

    local function ccTouchMoved(x, y)
        --TODO 设置左右方向
        --设置当前index  先处理第一个index的距离 (左右也要区分)
        --根据位置设置首尾
        --位移
        --
        self.pausetime = 2.5
        self:moveChampion((touchX-x)/GameScene.scaleNum)
        touchX = x
    end

    local function ccTouchEnded(x, y)
        self.pausetime = 2.5
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

    local touchPriority = self.buttontouch-1

    self.rootItems.touchlayer:registerScriptTouchHandler(onTouch, false, touchPriority, false)
    self.rootItems.touchlayer:setTouchPriority(touchPriority)
    self.rootItems.touchlayer:setTouchEnabled(true)
    --End


    local function touchbegin(pos)
        self.isscrolltouched = false
        self.touchbegin = {x = pos.x, y = pos.y}
    end

    gameTouch:rigistFunc("begin","honorwar",touchbegin)

    local function touchend(pos)
        if self.rootItems.listnode and ui.isTouched(self.rootItems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","honorwar",touchend)

    UIRequest({type = 6503})
    UIRequest({type = 6516})
end

function honorwarNow.setTime(self,state)
    local showtime = {{66,68},{71,73},{77,79},{82,84},{88,90},{93,95}}
    self:setTimeVisible(showtime[state][2])
    local timeconfig1 = self.timeconfig[tostring(showtime[state][1])]
        local timeconfig2 = self.timeconfig[tostring(showtime[state][2])]
        local hour1,min1,sec1 = ui.getGangBattleTime(timeconfig1.open_time)
        local hour2,min2,sec2 = ui.getGangBattleTime(timeconfig2.over_time)
        if math.floor(min1/10) < 1 then
            min1 = "0"..min1
        end
        if math.floor(min2/10) < 1 then
            min2 = "0"..min2
        end
        --print("+++++++++++++++")
        local timestring = "下"..(gameConfig.strings.bigNum[1]).."轮比赛：".."周"..gameConfig.strings:string_common("wdayNum",(timeconfig1.open_week+1)>7 and 1 or (timeconfig1.open_week+1)).." "..hour1..":"..min1.." ~ ".."周"..gameConfig.strings:string_common("wdayNum",(timeconfig2.over_week+1)>7 and 1 or (timeconfig2.over_week+1)).." "..hour2..":"..min2
        ui.setLabelString(self.rootItems["showtime1"],timestring,13)
end

function honorwarNow.shiftPage(self,type,notcheck)
    self.selectpage = type

    if type == "main" then
        self:showNode(self.rootItems.mainNode,true)
        self:showNode(self.rootItems.personalNode,false)
        self:showNode(self.rootItems.groupNode,false)
        self:showNode(self.rootItems.championNode,false)
        self.rootItems.groupNode2:setVisible(false)
        self.rootItems.championNode2:setVisible(false)

        if next(self.HonorWarLastChampion) then
            self:reloadMain()
        else
            UIRequest({type = 6513})
        end
 
    elseif type == "personal" then 
        self:showNode(self.rootItems.mainNode,false)
        self:showNode(self.rootItems.personalNode,true)
        self:showNode(self.rootItems.groupNode,false)
        self:showNode(self.rootItems.championNode,false)
        self.rootItems.groupNode2:setVisible(false)
        self.rootItems.championNode2:setVisible(false)

        if next(self.honorwarrolebattles) then
            self:reloadPersonal()
        else
            UIRequest({type = 6504})
        end
    elseif type == "group" then
        self:showNode(self.rootItems.mainNode,false)
        self:showNode(self.rootItems.personalNode,false)
        self:showNode(self.rootItems.groupNode,true)
        self:showNode(self.rootItems.championNode,false)
        self.rootItems.groupNode2:setVisible(true)
        self.rootItems.championNode2:setVisible(false)

        if next(self.honorwartop) then
            self:ReloadTop()
        else
            UIRequest({type = 6508})
        end
    elseif type == "champion" then
        self:showNode(self.rootItems.mainNode,false)
        self:showNode(self.rootItems.personalNode,false)
        self:showNode(self.rootItems.groupNode,false)
        self:showNode(self.rootItems.championNode,true)
        self.rootItems.groupNode2:setVisible(true)
        --self.rootItems.championNode2:setVisible(true)

        if next(self.honorwartop) then
            self:ReloadTop()
        else
            UIRequest({type = 6508})
        end
    end

    self.rootItems.myinfonode:setVisible(type == "main")

    if self.HonorWarStatus.list>0 and self.HonorWarStatus.status>0 and type ~= "personal"  then
        local canSignUp = type == "main" and self.HonorWarStatus.competition<=0 and self.HonorWarStatus.status==1
        self.rootItems.signupNode:setVisible(canSignUp) 

        local canArray = self.HonorWarStatus.competition>0 and self:checkArrayStatus() and self.HonorWarStatus.iscanArray==1
        self.rootItems.arrayNode:setVisible(canArray)
    else
        self.rootItems.arrayNode:setVisible(false)
        self.rootItems.signupNode:setVisible(false)
        --self.rootItems.info.setString()
        if type == "main" then
            if self.HonorWarStatus.list > 0 then
                ui.setLabelString(self.rootItems.info,"新一届巅峰对决准备中", 14)
            else
                ui.setLabelString(self.rootItems.info,"开服天数≥12天开启巅峰对决", 14) 
            end
        else 
            self.rootItems.info:setString("")
        end

    end
end

function honorwarNow.checkArrayStatus( self )
    --local arraystatus = {1,64,69,75,80,86,91}
    local arraystatus = {1,64,69,75,80,86,91}
    for k,v in ipairs(arraystatus) do
        if self.HonorWarStatus.status == v then
            return true
        end
    end
    return false
end

function honorwarNow.shiftPageNum(self,num)
    self.pageNum = num

    for i=1,6 do
        if self.HonorWarStatus.list>0 and i == self.pageNum then
            self.rootItems["selectnum"..i]:setVisible(true)
            --setSpriteFrameByName(self.rootItems["statusnum"..i], "kuafuzha_n_4")
        else
            self.rootItems["selectnum"..i]:setVisible(false)
            --setSpriteFrameByName(self.rootItems["statusnum"..i], "kuafuzha_n_4_h")
        end
    end

    if self.pageNum == 1 then
        self:shiftPage("main")
    elseif self.pageNum == 2 then
        self:shiftPage("personal")
    elseif self.pageNum ==3 then
        self:shiftPage("group")
    else
        if self.pageNum == 4 then
            self.rootItems.championccbnode1:setVisible(true)
            self.rootItems.championccbnode2:setVisible(false)
            self.rootItems.championccbnode3:setVisible(false)
            self.rootItems.championccbnode1:setPositionX(0)
            self.rootItems.championccbnode2:setPositionX(-9999)
            self.rootItems.championccbnode3:setPositionX(-9999)
        elseif self.pageNum == 5 then
            self.rootItems.championccbnode1:setVisible(false)
            self.rootItems.championccbnode2:setVisible(true)
            self.rootItems.championccbnode3:setVisible(false)
            self.rootItems.championccbnode1:setPositionX(-9999)
            self.rootItems.championccbnode2:setPositionX(0)
            self.rootItems.championccbnode3:setPositionX(-9999)
        else
            self.rootItems.championccbnode1:setVisible(false)
            self.rootItems.championccbnode2:setVisible(false)
            self.rootItems.championccbnode3:setVisible(true)
            self.rootItems.championccbnode1:setPositionX(-9999)
            self.rootItems.championccbnode2:setPositionX(-9999)
            self.rootItems.championccbnode3:setPositionX(0)

        end

        self:shiftPage("champion")
    end
    
end

function honorwarNow.updatatime(self)
    local timeconfig = self.timeconfig or {}

    local tt = "1"
    if self.timeconfig[tostring(self.HonorWarStatus.status+1)] then
        tt = tostring(self.HonorWarStatus.status+1)
    end
    local wday = self.timeconfig[tt].open_week+1
    if wday > 7 then wday = 1 end
    local hour,min,sec = ui.getGangBattleTime(self.timeconfig[tt].open_time)
    local nowtime = os.date("*t", gamedata:time())
    local diff = (wday-nowtime.wday)*86400+(hour-nowtime.hour)*3600+(min-nowtime.min)*60+sec-nowtime.sec
    if diff < 0 then diff = diff+86400*7 end

    gameTimer:rigistTime("worldwarupdatetimer",diff+1)
    gameTimer:rigistTimeFunc("worldwarupdatetimer",function()
        print("worldwarupdatetimer",gameTimer.times["worldwarupdatetimer"])
        if gameTimer.times["worldwarupdatetimer"] <= 0 then
            self.honorwarrolebattles = {}
            self.honorwartop = {}
            UIRequest({type = 6503, param = "update"})
        end
    end)
    --
end

function honorwarNow.getBattleNum( self,data )
    for k,v in ipairs(self.battleNumConfig) do
        if (data.status or 0) <= v.max then
            return k
        end
    end
end

function honorwarNow.ReloadData(self,data)

    if data and data.HonorWarStatus then
        self.HonorWarStatus = data.HonorWarStatus
    end
    local wardata = self.HonorWarStatus
    --第几届跨服战
    self.rootItems.title:setString(wardata.number)

    local zoneconfig = gamedata.config.glory_battle_interval[tostring(wardata.list)]
    self.rootItems.zoneLab:setString(zoneconfig and zoneconfig.name or "未开赛")

    self.rootItems.competitionbg = tolua.cast(self.rootItems.competitionbg, "CCScale9Sprite")
    if wardata.competition > 0 then
        self.rootItems.recordLab:setString(wardata.win.."胜"..wardata.lose.."负")
        self.rootItems.rankLab:setString(wardata.rank)
        self.rootItems.starLab:setString(wardata.star)
        self.rootItems.competitionInfo:setVisible(true)
        self.rootItems.competitionbg:setPreferredSize(CCSizeMake(450,300))
    else
        self.rootItems.competitionInfo:setVisible(false)
        self.rootItems.competitionbg:setPreferredSize(CCSizeMake(450,150))
    end

    local battleStatus = self:getBattleNum(wardata)
    for i=1,6 do
        if self.HonorWarStatus.list > 0 and i <= battleStatus then
            setSpriteFrameByName(self.rootItems["statusnum"..i], "kuafuzha_n_4")
        else
            setSpriteFrameByName(self.rootItems["statusnum"..i], "kuafuzha_n_4_h")
        end
    end

    self.rootItems.desc:setString(self.descConfig[battleStatus])

    if self.HonorWarStatus.list > 0 then
        self:updatatime()
        self:shiftPageNum(battleStatus)
        if battleStatus>1 then
            UIRequest({type = 6504})
        end        
    else
        self:shiftPageNum(1)
    end
end

function honorwarNow.ReloadLiveness( self,t )
    self.weekliveness = t.weekliveness
    local needliveness = tonumber(gamedata.config.global_kv.glory_active_num.value)
    ui.setLabelString( self.rootItems.weekliveness,self.weekliveness,self.weekliveness>=needliveness and 14 or 11)
    ui.setLabelString( self.rootItems.signupdesc,"上周活跃度达到"..needliveness.."可报名",18)
    
    ui.setLabelString( self.rootItems.signupLab,"报 名",18)
    if self.weekliveness>=needliveness then 
        ui.removeGray("CCControlButton",self.rootItems.signupBtn)
    else
        ui.addGray("CCControlButton",self.rootItems.signupBtn)
    end
    self.rootItems.signupBtn:setTouchPriority(self.buttontouch)
    self.rootItems.signupBtn:addHandleOfControlEvent(function()
        if self.weekliveness>=needliveness then
            UIRequest({type = 6515})
        --else
       --     runGamePrompt({msg = "上周活跃度不足"})
        end
    end, CCControlEventTouchUpInside)
end

function honorwarNow.setOneChampion( self,data,item,config )

    item.p_zone_lab:setString(config.name)
    ui.setLabelString(item.p_zone_lab,config.name,21)
    setSpriteFrameByName(item.taizi,"rongyaozhizhantaizi_"..config.id)

    if data and data.rid>0 then
        --名字，服务器，赛区，是否本服
        item.p_name:setString(data.name)
        item.p_server_name:setString("S"..data.serviceid.." "..data.servicename)

        local selfserverId = gameWindows.windows["roleinfo"].module.SelectedServer.id
        item.p_serverthis:setVisible(selfserverId == data.serviceid)

        --人物形象
        item.p_general:removeAllChildrenWithCleanup(true)
        if data.profile >0 then
            local generalanimationId = gamedata.config.general[tostring(data.profile)].animationid
            local generalName = gamedata.config.generalanimation[tostring(generalanimationId)].name
            local wing = {level = data.w_l,color = data.w_c}
            local Gneral1 = ui.itemcache:loadSkeleton(generalName,wing)
            Gneral1:setAnimation("stand",true,0)
            Gneral1:setScale(1.2)
            Gneral1:setPosition(0,0)
            item.p_general:addChild(Gneral1.root or Gneral1)
        end
        item.noneSprite:setVisible(false)
    else
        item.p_name:setString("???")
        item.p_server_name:setString("???")
        item.p_serverthis:setVisible(false)
        item.noneSprite:setVisible(true)
    end
end

function honorwarNow.moveChampion( self,dis )
    if not next(self.championListccb) then return end

    local championnum = table.getTableLength(gamedata.config.glory_battle_interval)
    local onewidth = 510
    local showwidth = 1080
    local shownum  = math.ceil(showwidth/onewidth)--3

    self.champion_move_x = (self.champion_move_x or 0) + dis

    if self.champion_move_x < 0 then
        self.champion_move_x = self.champion_move_x - math.floor(self.champion_move_x/(onewidth*championnum))
    end

    local disidx = math.ceil(self.champion_move_x/onewidth)

    local showidx = math.mod(disidx,championnum)
    if showidx == 0 then showidx = championnum end

    for i = 0, 6 do
        local ccbidx = showidx+i
        if ccbidx>7 then ccbidx = ccbidx - 7 end
        if ccbidx <=0 then  ccbidx  =ccbidx +7 end
        ccbidx = math.abs(ccbidx)
        local ccbposx = (disidx-1+i)*onewidth-self.champion_move_x
        self.championListccb["champion"..ccbidx].CCB:setPosition(ccbposx+onewidth/2,150)
    end
end

function honorwarNow.reloadMain( self,data )

    if data and data.HonorWarLastChampion then
        self.HonorWarLastChampion = data.HonorWarLastChampion
    end
    
    
    for i,config in pairs(gamedata.config.glory_battle_interval) do
        if not self.championListccb["champion"..i] then
            local oneccb = {}
            oneccb.CCB,oneccb.Item = CCBReaderLoad("rongyaozhizhan/cell_player",nil, true, "cell_player")
            self.rootItems.touchlayer:addChild(oneccb.CCB)
            self.championListccb["champion"..i] = oneccb
        end

        local onedata = self.HonorWarLastChampion[tostring(i)]
        local oneitem = self.championListccb["champion"..i].Item

        self:setOneChampion(onedata,oneitem,config)
    end

    if self.HonorWarStatus.list>0 then 
        self.champion_move_x = 0
        self:moveChampion((self.HonorWarStatus.list-1)*510-285)
    else
        self:moveChampion(0)   
    end
end

function honorwarNow.reloadPersonal( self,data )

    self.rootItems.nowarNode:setVisible(true)
    self.rootItems.haswarNode:setVisible(false)
    if self.HonorWarStatus.competition < 1 then
        self.rootItems.nowardesc:setString(gameConfig.strings:string_common("honorBattle2",34))
    elseif self.HonorWarStatus.status < 3 then
        self.rootItems.nowardesc:setString(gameConfig.strings:string_common("honorBattle2",35))
    else
        self.rootItems.nowarNode:setVisible(false)
        self.rootItems.haswarNode:setVisible(true)
    end

    if data and data.honorwarrolebattles then
        self.honorwarrolebattles = {}
        for k,v in pairs(data.honorwarrolebattles) do
            if v.result < 0 and v.time > 0 then 
                local _timerName = "honorwarrolebattles"..v.id
                gameTimer:rigistTime(_timerName,v.time+1)
                self.timers["honorwarrolebattles"..v.id] = 1
            end
            v.k = tonumber(k)
            table.insert(self.honorwarrolebattles,v)
        end
        local sortfunc = function (a,b)
            return a.k > b.k
        end
        table.sort(self.honorwarrolebattles,sortfunc)
    end

    if self.rootItems then
        if not self.ListTableView then
            self:createList()
        else
            self.ListTableView:reloadData()
        end
    end

    --
    if self.rootItems.getallNode then
        if gameConfig:checkBuildOpen(352) then
            --
            local hasreward = false
            for k,v in pairs(self.honorwarrolebattles) do
                if v.reward and v.reward == 1 then
                    hasreward = true
                    break
                end
            end
            self.rootItems.getallNode:setVisible(true)
            --ui.setLabelString(self.rootItems.getallLab,nil,18)
            self.rootItems.getallButton:setTouchPriority(self.buttontouch)
            if hasreward then
                self.rootItems.getRewardHintNode:setVisible(true)
                ui.removeGray("CCControlButton",self.rootItems.getallButton)
                self.rootItems.getallButton:addHandleOfControlEvent(function()
                    gameTouch:clickprofbytime(1)
                    UIRequest({type = 6505, phase = 0, id = ""})
                end, CCControlEventTouchUpInside)
            else
                self.rootItems.getRewardHintNode:setVisible(false)
                ui.addGray("CCControlButton",self.rootItems.getallButton)
                self.rootItems.getallButton:addHandleOfControlEvent(function()
                    gameTouch:clickprofbytime(0.5)
                    runGamePrompt({msg = "没有可领取的奖励"})
                end, CCControlEventTouchUpInside)
            end
        else
            self.rootItems.getallNode:setVisible(false)
        end
    end
end
--创建个人界面的列表
function honorwarNow.createList(self)
    local  celldict = {}
    --创建handle
    local ListHandle = LuaEventHandler:create(
        function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "isRecycle" then
            self.ccbDocument[tostring(a1+1)] = nil
            return true
        elseif fn == "cellAtIndex" then
            self.ccbDocument[tostring(a1+1)] = {}
            local ccbdoc = self.ccbDocument[tostring(a1+1)]
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                ccbdoc.cellCCB, ccbdoc.ccbDocumentControler = CCBReaderLoad("rongyaozhizhan/cell_yuxuan",nil,true,"cell_yuxuan")
                celldict[a2] = {cellCCB = ccbdoc.cellCCB,ccbDocumentControler = ccbdoc.ccbDocumentControler,index = a1+1}
            else
                first = false
                ccbdoc.cellCCB = celldict[a2].cellCCB
                ccbdoc.ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCell(ccbdoc.ccbDocumentControler,self.honorwarrolebattles[a1+1],a1+1)

            ccbdoc.cellCCB:setPosition(self.normalCellSize.x/2,0)
            if first then
                a2:addChild(ccbdoc.cellCCB)
            end
            r = a2
        elseif fn=="numberOfCells" then
            r = #self.honorwarrolebattles
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)
    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listnode:getContentSize().width,
        viewheight = self.rootItems.listnode:getContentSize().height,
        dire = 1
    })

    self.rootItems.listnode:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(-101)
end

function honorwarNow.setCell(self,item,data,index)

    item.name_a:setString(data.name_a)
    item.power_a:setString(data.power_a)
    ui.setNewIcon(item,{cid = data.profile_a,title = data.title_a,iconBox = iconBox_a})
    
    item.name_b:setString(data.name_b)
    item.power_b:setString(data.power_b)
    ui.setNewIcon(item,{cid = data.profile_b,title = data.title_b,iconBox = iconBox_b},1)

    local phasecount ={0,60,61,62,63,64,65}
    item.round:setString(tostring(phasecount[data.phase]+data.round))
    item.resultspr:setVisible(data.result>=0)
    item.resultspr:setPositionX(data.result==1 and 80 or 1000)
    --item.resultspr:setVisible(data.result<=0)
    --暂时没有图
    --item.sp_first_left:setVisible(data.power_a>data.power_b and data.result<0)
    --item.sp_first_right:setVisible(data.power_a<data.power_b and data.result<0)
    

    item.statusnode:setVisible(data.reward<=0)
    item.rewardnode:setVisible(data.reward>0)
    ui.setLabelString(item.rewardlab,data.reward == 1 and "奖励" or "已领取",18)

    item.rewardhint:setVisible(data.reward==1)
    if data.reward==1 then
        ui.removeGray("CCControlButton",item.rewardbtn)
    else
        ui.addGray("CCControlButton",item.rewardbtn)
    end

    item.rewardbtn:setTouchPriority(self.buttontouch)
    item.rewardbtn:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        if not self.isscrolltouched then return end
        if data.reward == 1 then
            UIRequest({
                    type = 6505, 
                    phase = data.phase, 
                    id = data.id,
                })
        else
            runGamePrompt({msg = "已领取"})
        end
    end, CCControlEventTouchUpInside)

    if data.result >=0 then
        item.statuslab:setString("本场比分："..(4-data.resultnum)..":"..(data.resultnum-1))
    else
        item.statuslab:setString("--")
    end

    item.showButton:setTouchPriority(self.buttontouch)
    item.showButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        gameWindows:openWindow("honorBattleOdds",{
                phase = data.phase,
                id = data.id,
                players = {
                    [data.rid_a] = {
                                    name = data.name_a,
                                    profile = data.profile_a,
                                    power = data.power_a,
                                },
                    [data.rid_b] = {
                                    name = data.name_b,
                                    profile = data.profile_b,
                                    power = data.power_b,
                                },
                }
            })
    end, CCControlEventTouchUpInside)

    local _timerName = "honorwarrolebattles"..data.id
    if gameTimer.times[_timerName] and gameTimer.times[_timerName] >0 then
        gameTimer:rigistTimeFunc(_timerName, function()
            if self.ccbDocument[tostring(index)] then
                self.ccbDocument[tostring(index)].ccbDocumentControler.statuslab:setString(ui.makeTimeText(gameTimer.times[_timerName]))
            end            
            if gameTimer.times[_timerName] <= 0 then 
                gameTimer:UnrigistTime(_timerName)
                gameTimer:UnrigistTimeFunc(_timerName)
            end
        end)
    end
end

function honorwarNow.ReloadPlayers(self,data)
    if data and data.honorwarplayers then
        self.honorwarplayers = data.honorwarplayers
    end
    --判断如果是海选阶段    就设置组数据
    if self.selectpage == "group" then
        self:setGroupIndex()
        self:setGroupData(self.groupindex)
        if self.groupindex>=7 then
            self.groupListTableView:setContentOffsetInDuration(ccp(-240 ,0),0.2)
        end
    elseif self.selectpage == "champion" then
        self:setChampionData()
    end
end
function honorwarNow.setGroupIndex(self)
    local datatemp = self.honorwartop["1"] or {}
    for index=1,8 do
        for i = 1,4 do
            local battledata = datatemp[tostring(4*(index-1)+i)]
            local player1 = self.honorwarplayers[tostring(battledata.p_id1)] or {}
            local player2 = self.honorwarplayers[tostring(battledata.p_id2)] or {}
            if player1.rid ==GameScene.roleinfo.id or player2.rid == GameScene.roleinfo.id then 
                self.groupindex = index
            end
        end
    end
end
function honorwarNow.ReloadTop(self,data)
    if data and data.honorwartop then
        self.honorwartop = data.honorwartop
    end

    if next(self.honorwarplayers) then
        self:ReloadPlayers()
    else
        UIRequest({type = 6512})
    end
end

function honorwarNow.openBattleDetail( self,battledata,betstatus,restbetcount )
    --TODO  把传入的1 和2  干掉
    local player1 = self.honorwarplayers[tostring(battledata.p_id1)] or {}
    local player2 = self.honorwarplayers[tostring(battledata.p_id2)] or {}
    local data = {
        phase = battledata.phase,
        id=battledata.id,
        players = {
            [player1.rid] = player1,
            [player2.rid] = player2,
        }

    }
    if self.HonorWarStatus.status>=betstatus then
        data.betdata = {
            result = battledata.result,
            resultnum = battledata.resultnum,
            bet = battledata.bet,
            betnum = battledata.betnum,
            betcount = battledata.betcount,
            betstatus = betstatus,
            restbetcount = restbetcount,
        }
    end
    gameWindows:openWindow("honorBattleOdds",data)
end

function honorwarNow.setGeneralIcon( self,item,data,idx,iswin )
    local key = ""
    if idx>1 then
        key = "_"..(idx-1)
    end

    if data then
        local config = ui.IDconfig(data.profile)
        local icon = config and config.icon or "obj_icon_pz_general"
        setSpriteFrameByName(item["i_icon"..key],icon)
        ui.setSpriteTextureRect(item["i_icon"..key],0,0,150,150)

        item["i_name"..key]:setString(data.name)
        --ui.setLabelString(item["i_name"..key],data.name,13)
        ui.setLabelString(item["i_servername"..key],data.server_name,13)

        item["i_iswin"..key]:setVisible(iswin)
    else
        setSpriteFrameByName(item["i_icon"..key],"obj_icon_pz_general")
        ui.setSpriteTextureRect(item["i_icon"..key],0,0,150,150)
        item["i_name"..key]:setString("")
        ui.setLabelString(item["i_servername"..key],"",13)
        item["i_iswin"..key]:setVisible(false)
    end
end

function honorwarNow.setBattleStatusWithdata( self,item,battledata,idx,betstatus,totalbetcount)
    if item["w_"..idx.."_1"] then
        item["w_"..idx.."_1"]:setVisible(battledata.result==1)
    end
    if item["w_"..idx.."_2"] then
        item["w_"..idx.."_2"]:setVisible(battledata.result==0)
    end

    local maxbetcount = tonumber(gamedata.config.global_kv.glory_battle_yazhu.value)
    local restbetcount = maxbetcount - totalbetcount
    
    item["w_button_c"..idx]:setVisible(self.HonorWarStatus.status ~= betstatus or battledata.bet > 0)
    item["w_button_j"..idx]:setVisible(self.HonorWarStatus.status == betstatus and battledata.bet <= 0)

    ui.removeGray("CCControlButton",item["w_button_c"..idx])
    --查看详情界面  两个按钮 都是查看详情界面 
    item["w_button_c"..idx]:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        self:openBattleDetail(battledata,betstatus,restbetcount)
    end, CCControlEventTouchUpInside)
    -------押注按钮点击处理    此处  要传入   当前界面的头像信息  和战斗力信息  和赔率信息
    item["w_button_j"..idx]:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        self:openBattleDetail(battledata,betstatus,restbetcount)
    end, CCControlEventTouchUpInside)

    if battledata.bet == 1 then
        setSpriteFrameByName(item["w_bet_s"..idx], "_0015_2")
    elseif battledata.bet == 2 then
        setSpriteFrameByName(item["w_bet_s"..idx], "_0009_1_2")
    elseif battledata.bet == 3 then
        setSpriteFrameByName(item["w_bet_s"..idx], "_0009_1")
    else
        setSpriteFrameByName(item["w_bet_s"..idx], "alpha")
    end
end

function honorwarNow.setBattleStatusEmpty( self,item,idx )
    if item["w_"..idx.."_1"] then
        item["w_"..idx.."_1"]:setVisible(false)
    end
    if item["w_"..idx.."_2"] then
        item["w_"..idx.."_2"]:setVisible(false)
    end
    item["w_button_c"..idx]:setVisible(true)
    item["w_button_j"..idx]:setVisible(false)
    ui.addGray("CCControlButton",item["w_button_c"..idx])
    --
    item["w_button_c"..idx]:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        runGamePrompt({msg = gameConfig.strings:string_common("fixedString","servicewar",24)})
    end, CCControlEventTouchUpInside)
    --
    item["w_button_j"..idx]:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
    end, CCControlEventTouchUpInside)

    setSpriteFrameByName(item["w_bet_s"..idx], "alpha")
end

function honorwarNow.setGroup8_1( self,item,battledata,idx,totalbetcount )
    --printT(battledata,"====64强：")
    if battledata then 
        local player1 = self.honorwarplayers[tostring(battledata.p_id1)] or {}
        local player2 = self.honorwarplayers[tostring(battledata.p_id2)] or {}

        self:setGeneralIcon(item,player1,idx*2-1,battledata.result==1)
        self:setGeneralIcon(item,player2,idx*2,battledata.result==0)

        self:setBattleStatusWithdata(item,battledata,idx,65,totalbetcount)--65
       -- showtime = {{65,67},{69,71},{74,76},{78,80},{83,85},{87,89}}
        
        self:setTime(1)
        
    else
        self:setGeneralIcon(item,nil,idx*2-1,false)
        self:setGeneralIcon(item,nil,idx*2,false)

        self:setBattleStatusEmpty(item,idx)
    end
end
function honorwarNow.setTimeVisible( self,maxState)   
    self.rootItems.groupNode2:setVisible(not(self.HonorWarStatus.status > maxState))     --self.HonorWarStatus.status 
end
function honorwarNow.setGroup8_2( self,item,battledata,idx,totalbetcount )
    --print("====32强："..battledata)
    if battledata then 
        local player1 = self.honorwarplayers[tostring(battledata.p_id1)] or {}
        local player2 = self.honorwarplayers[tostring(battledata.p_id2)] or {}
        local winner = nil
        if battledata.result == 1 then
            winner = player1
        elseif battledata.result == 0 then
            winner = player2
        end
        self:setGeneralIcon(item,winner,idx+8,false)

        self:setBattleStatusWithdata(item,battledata,idx+4,70,totalbetcount)--70
        self:setTime(2)
    else
        self:setGeneralIcon(item,nil,idx+8,false)
        self:setBattleStatusEmpty(item,idx+4)
    end
end

function honorwarNow.setGroup8_3( self,item,battledata,idx,totalbetcount )
    if battledata then 
        local player1 = self.honorwarplayers[tostring(battledata.p_id1)] or {}
        local player2 = self.honorwarplayers[tostring(battledata.p_id2)] or {}

        local winner = nil
        if battledata.result == 1 then
            winner = player1
        elseif battledata.result == 0 then
            winner = player2
        end
        self:setGeneralIcon(item,winner,idx+10,false)

        self:setGeneralIcon(item,player1,idx+8,battledata.result==1)
        self:setGeneralIcon(item,player2,idx+9,battledata.result==0)

        self:setBattleStatusWithdata(item,battledata,idx+6,76,totalbetcount)--76
        self:setTime(3)
    else
        self:setGeneralIcon(item,nil,idx+10,false)
        self:setBattleStatusEmpty(item,idx+6)
    end
end

function honorwarNow.setGroup8( self,item,battledata,idx,totalbetcount )
    if battledata then 
        local player1 = self.honorwarplayers[tostring(battledata.p_id1)] or {}
        local player2 = self.honorwarplayers[tostring(battledata.p_id2)] or {}

        self:setGeneralIcon(item,player1,idx*2-1,battledata.result==1)
        self:setGeneralIcon(item,player2,idx*2,battledata.result==0)

        self:setBattleStatusWithdata(item,battledata,idx,81,totalbetcount)--81
        self:setTime(4)
    else
        self:setGeneralIcon(item,nil,idx*2-1,false)
        self:setGeneralIcon(item,nil,idx*2,false)

        self:setBattleStatusEmpty(item,idx)
    end
end

function honorwarNow.setGeneralAnimation(self,item,data,idx,islose )
    local key = ""
    if idx>1 then
        key = "_"..(idx-1)
    end

    item["i_generalnode"..key]:removeAllChildrenWithCleanup(true)

    if data then
        local config = ui.IDconfig(data.profile)
        local generalName = gamedata.config.generalanimation[tostring(config.animationid)].name
        local General = ui.itemcache:loadSkeleton(generalName,wing)
        General:setAnimation("stand",true,0)
        General:setScale(1.2)
        General:setScaleX(1.2)
        General:setPosition(0,0)
        item["i_generalnode"..key]:addChild(General.root or General)

        if islose then
            ui.addGray("CCNode",General)
        end

        item["i_name"..key]:setString(data.name)
        ui.setLabelString(item["i_servername"..key],data.server_name,13)
        item["i_islose"..key]:setVisible(islose)
    else
        item["i_name"..key]:setString("??")
        ui.setLabelString(item["i_servername"..key],"??",13)
        item["i_islose"..key]:setVisible(false)
    end
end

function honorwarNow.setGroup4( self,item,battledata,idx,totalbetcount )
    if battledata then 
        local player1 = self.honorwarplayers[tostring(battledata.p_id1)] or {}
        local player2 = self.honorwarplayers[tostring(battledata.p_id2)] or {}

        self:setGeneralAnimation(item,player1,idx*2-1,battledata.result==0)
        self:setGeneralAnimation(item,player2,idx*2,battledata.result==1)

        self:setBattleStatusWithdata(item,battledata,idx,87,totalbetcount)--87
        self:setTime(5)
    else
        self:setGeneralAnimation(item,nil,idx*2-1,false)
        self:setGeneralAnimation(item,nil,idx*2,false)

        self:setBattleStatusEmpty(item,idx)
    end
end

function honorwarNow.setGroup2( self,item,battledata,idx,totalbetcount )
    if battledata then 
        local player1 = self.honorwarplayers[tostring(battledata.p_id1)] or {}
        local player2 = self.honorwarplayers[tostring(battledata.p_id2)] or {}

        self:setGeneralAnimation(item,player1,1,battledata.result==0)
        self:setGeneralAnimation(item,player2,2,battledata.result==1)

        self.rootItems.championSpr:setVisible(battledata.result>=0)
        self.rootItems.championSpr:setPositionX(battledata.result==1 and -290 or 290)

        self:setBattleStatusWithdata(item,battledata,idx,92,totalbetcount)--92
        self:setTime(6)
    else
        self:setGeneralAnimation(item,nil,1,false)
        self:setGeneralAnimation(item,nil,2,false)
        self.rootItems.championSpr:setVisible(false)
        self:setBattleStatusEmpty(item,idx)
    end
end

function honorwarNow.setGroupData(self,index)
    if self.rootItems then
        if not self.groupListTableView then
            self:creategroupList()
        else
            self.groupListTableView:reloadData()
        end
    end

    self:checkSetX()

    if not self.grouprootNode or not self.grouprootItems then
        self.grouprootNode,self.grouprootItems = CCBReaderLoad("rongyaozhizhan/rongyaozhizhan_bisai", nil, true, "rongyaozhizhan_bisai")
        self.grouprootNode:setPosition(0,0)
        self.rootItems.groupccbnode:addChild(self.grouprootNode)
    end

    local datatemp = self.honorwartop["1"] or {}
    --执行4次   每次处理两头像
    for i = 1,4 do
        self:setGroup8_1(self.grouprootItems,datatemp[tostring(4*(index-1)+i)],i,datatemp.totalbetcount)
    end

    local datatemp2 = self.honorwartop["2"] or {}
    for i = 1,2 do
        self:setGroup8_2(self.grouprootItems,datatemp2[tostring(2*(index-1)+i)],i,datatemp2.totalbetcount)
    end

    local datatemp3 = self.honorwartop["3"] or {}
    self:setGroup8_3(self.grouprootItems,datatemp3[tostring(index)],1,datatemp3.totalbetcount)
end

function honorwarNow.setChampionData(self)
    if self.pageNum == 4 then
        if not self.championrootNode1 or not self.championrootItems1 then
            self.championrootNode1,self.championrootItems1 = CCBReaderLoad("rongyaozhizhan/rongyaozhizhan_bisai8", nil, true, "rongyaozhizhan_bisai8")
            self.championrootNode1:setPosition(0,0)
            self.rootItems.championccbnode1:addChild(self.championrootNode1)           
        end

        local datatemp = self.honorwartop["4"] or {}
        for i = 1,4 do
            self:setGroup8(self.championrootItems1,datatemp[tostring(i)],i,datatemp.totalbetcount)
        end
        self.rootItems.championSpr:setVisible(false)
    elseif self.pageNum == 5 then
        if not self.championrootNode2 or not self.championrootItems2 then
            self.championrootNode2,self.championrootItems2 = CCBReaderLoad("rongyaozhizhan/rongyaozhizhan_bisai4", nil, true, "rongyaozhizhan_bisai4")
            self.championrootNode2:setPosition(0,0)
            self.rootItems.championccbnode2:addChild(self.championrootNode2)           
        end
        
        local datatemp2 = self.honorwartop["5"] or {}
        for i = 1,2 do
            self:setGroup4(self.championrootItems2,datatemp2[tostring(i)],i,datatemp2.totalbetcount)
        end
        self.rootItems.championSpr:setVisible(false)
    else
        if not self.championrootNode3 or not self.championrootItems3 then
            self.championrootNode3,self.championrootItems3 = CCBReaderLoad("rongyaozhizhan/rongyaozhizhan_bisai2", nil, true, "rongyaozhizhan_bisai2")
            self.championrootNode3:setPosition(0,0)
            self.rootItems.championccbnode3:addChild(self.championrootNode3)           
        end

        local datatemp3 = self.honorwartop["6"] or {}
        self:setGroup2(self.championrootItems3,datatemp3[tostring(1)],1,datatemp3.totalbetcount)
    end
end


function honorwarNow.creategroupList(self)
    local celldict = {}
    local groupListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(140,120)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("rongyaozhizhan/rongyaozhizhan_icon2.ccbi", nil, true, "rongyaozhizhan")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            cellCCB:setScale(1)
            cellCCB:setPosition(70, 60)

            ui.setLabelString(ccbDocumentControler.z_lab,self.groupname[a1+1],14)

            if self.groupindex == a1+1 then
                ccbDocumentControler.z_select:setVisible(true)
            else
                ccbDocumentControler.z_select:setVisible(false)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = 8
        elseif fn == "cellTouched" then
            gameTouch:clickprofbytime(0.5)
            --
            self.groupindex = a1:getIdx()+1
            self:setGroupData(self.groupindex)

        elseif fn == "scrollViewDidScroll" then
            self:checkSetX()
        end
        return r
    end)

    self.groupListTableView = ui.createLuaTableView({
        handle = groupListHandle,
        viewwidth = self.rootItems.groupList:getContentSize().width,
        viewheight = self.rootItems.groupList:getContentSize().height,
        dire = 0
    })
    self.rootItems.groupList:addChild(self.groupListTableView)
    self.groupListTableView:setTouchPriority(-102)
end

function honorwarNow.checkSetX(self)
    if self.groupListTableView and self.rootItems.groupnode_left and self.rootItems.groupnode_right then
        local setx = self.groupListTableView:getLuaContentOffsetX()
        if setx > -20 then
            self.rootItems.groupnode_left:setVisible(false)
            self.rootItems.groupnode_right:setVisible(true)
        elseif setx < -200 then
            self.rootItems.groupnode_left:setVisible(true)
            self.rootItems.groupnode_right:setVisible(false)
        else
            self.rootItems.groupnode_left:setVisible(true)
            self.rootItems.groupnode_right:setVisible(true)
        end
    end
end

function honorwarNow.clear(self)
    gameTouch:UnrigistFunc("begin","honorwar")
    gameTouch:UnrigistFunc("end","honorwar")
    gameTimer:UnrigistTimeFunc("worldwarupdatetimer")
    gameTimer:UnrigistTimeFunc("worldwarendtimer")
    for k,v in pairs(self.timers) do
        gameTimer:UnrigistTime(k)
        gameTimer:UnrigistTimeFunc(k)
    end

    if self.scheduleScript then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.scheduleScript)
        self.scheduleScript = nil
    end
    self.timers = {}
    self.ccbDocument = {}
    self.selectpage = "personal"
    self.groupindex = 1
    self.pageNum = 1
    self.groupListTableView = nil
    self.ListTableView = nil
    self.championListccb = {}
    self.championListccb2 = {}
    self.honorwartop = {}
    self.HonorWarLastChampion = {}
    self.HonorWarStatus = {}
    self.honorwarrolebattles = {}
    self.rootItems = nil
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.grouprootNode = nil
    self.grouprootItems = nil
    self.championrootNode1 = nil
    self.championrootItems1 = nil
    self.championrootNode2 = nil
    self.championrootItems2 = nil
    self.championrootNode3 = nil
    self.championrootItems3 = nil
    self.isOpenStatus = 0
    self.champion_move_x = 0
end

return honorwarNow ��  