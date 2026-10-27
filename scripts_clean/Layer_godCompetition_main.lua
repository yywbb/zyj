--
-- Created by IntelliJ IDEA.
-- User: jkp
-- Date: 22/2/23
-- Time: 17:35
-- To change this template use File | Settings | File Templates.
--

local godCompetitionMain = {

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
    --boss战，海选赛，小组赛，冠军赛
    pages = {"boss","personal","group","champion"},
    selectpage = "",
    pageNum = 1,
    bossIndex = 0,
    bossbuffindex = 0,

    buttontouch = -103,

    godStatus = {},
    godComRoleBattles = {},
    godtop = {},
    godplayers = {},
    
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
        [3] = { ["min"] = 64, ["max"] = 75},
        [4] = { ["min"] = 76, ["max"] = 79},
        [5] = { ["min"] = 80, ["max"] = 83},
        [6] = { ["min"] = 84, ["max"] = 87}
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
                -- achievement = {452},
            },
        },
    },
}

function godCompetitionMain.showNode( self,node,isshow )
    if isshow then
        node:setPositionX(0)    
        node:setVisible(true) 
    else
        node:setPositionX(-9999)    
        node:setVisible(false) 
    end
end

function godCompetitionMain.init(self,parent,toppos,param)
    
    self.rootNode,self.rootItems = CCBReaderLoad("fengshensai/fengshensai_main", nil, true, "fengshensai_main")
    self.rootNode:setPosition(-GameScene.viewSize.width/2,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.bg:setPositionY(toppos)
    self.rootItems.midnode1:setPositionY((toppos)/2+50)
    self.rootItems.midnode2:setPositionY((toppos-430)/2)
    self.rootItems.haswarNode:setPositionY(580-((toppos-430)/2-700))
    self.rootItems.listnode:setContentSize(CCSizeMake(1080, 840+(GameScene.topposY-1620-180)))
    self.rootItems.mask:setPositionY(self.rootItems.listnode:getContentSize().height)
    self.rootItems.maskbottom:setPositionY(180-20)

    --页面按钮设置
    self:initGodCompetitionButton(self.rootItems)

    --设置boss形象
    self:setBossSpineShow(self.rootItems)

    --底部导航栏设置
    for i=1,6 do
        ui.setLabelString(self.rootItems["fixedStr"..i],nil,14)
        self.rootItems["scheduleBtn"..i]:setTouchPriority(self.buttontouch)
        self.rootItems["scheduleBtn"..i]:addHandleOfControlEvent(function()
            if self.godStatus.group <= 0 then
                runGamePrompt({msg = "您所在区服未开赛"})
            elseif self.godStatus.status < self.battleNumConfig[i]["min"] then
                runGamePrompt({msg = "当前赛事未开启"})
            else
                self:shiftPageNum(i)
            end
        end, CCControlEventTouchUpInside)
    end

    --封神赛阶段表
    self.timeconfig = gamedata.config.apex_battle_time

    --boss战倒计时
    local bwday = self.timeconfig["1"].over_week+1
    if bwday > 7 then bwday = 1 end
    local hour,min,sec = ui.getGangBattleTime(self.timeconfig["1"].over_time)
    local nowtime = os.date("*t", gamedata:time())
    local diff = (bwday-nowtime.wday)*86400+(hour-nowtime.hour)*3600+(min-nowtime.min)*60+sec-nowtime.sec
    if diff < 0 then diff = diff+86400*7 end
    --倒计时结束后请求  否则更新时间显示
    gameTimer:rigistTime("worldwarendtimer_boss",diff+1)
    gameTimer:rigistTimeFunc("worldwarendtimer_boss",function()
        if self.godStatus and self.godStatus.status and self.godStatus.status < self.battleNumConfig[1]["max"] and self.godStatus.period > 0 then
            if gameTimer.times["worldwarendtimer_boss"] <= 0 then
                ui.setLabelString(self.rootItems.time_title,"",21)
                ui.setLabelString(self.rootItems.boss_endtime,"",14)
                UIRequest({type = 8251, param = "update"})
            else
                ui.setLabelString(self.rootItems.time_title,"距离BOSS战结束: ",21)
                ui.setLabelString(self.rootItems.boss_endtime,ui.makeTimeDayText(gameTimer.times["worldwarendtimer_boss"],"day"),14)
            end
        else
            ui.setLabelString(self.rootItems.time_title,"",21)
            ui.setLabelString(self.rootItems.boss_endtime,"",14)
        end
    end)

    --封神赛倒计时
    ui.setLabelString(self.rootItems.endtimelab,"距离封神赛结束时间: ",21)
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
            UIRequest({type = 8251, param = "update"})
        else
            ui.setLabelString(self.rootItems.endtime,ui.makeTimeDayText(gameTimer.times["worldwarendtimer"],"day"),14)
        end
    end)
    --

    --左右按键设置
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

    --
    local function touchbegin(pos)
        self.isscrolltouched = false
        self.touchbegin = {x = pos.x, y = pos.y}
    end
    gameTouch:rigistFunc("begin","godCompetition",touchbegin)

    local function touchend(pos)
        if self.rootItems.listnode and ui.isTouched(self.rootItems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","godCompetition",touchend)

    --
    UIRequest({type = 8250})
    -- self:shiftPageNum(1)

end

function godCompetitionMain.initGodCompetitionButton(self, items)
    --返回
    if items.closeButton then
        items.closeButton:setTouchPriority(self.buttontouch)
        items.closeButton:addHandleOfControlEvent(function()
            if self.bossIndex ~= 0 then
                self.bossIndex = 0
                self:shiftPageNum(1)
            else
                GameScene:shiftLayer("main","down")
            end
        end, CCControlEventTouchUpInside)
    end

    --boss战主页按钮
    for i=1,8 do
        if items["bossmainbtn"..i] then
            items["bossmainbtn"..i]:setTouchPriority(self.buttontouch)
            items["bossmainbtn"..i]:addHandleOfControlEvent(function()
                self:bossMainButtonCallBack(i)
            end, CCControlEventTouchUpInside)
        end
    end

    --boss挑战页按钮
    for i=1,2 do
        if items["bossbattlebtn"..i] then
            items["bossbattlebtn"..i]:setTouchPriority(self.buttontouch)
            items["bossbattlebtn"..i]:addHandleOfControlEvent(function()
                self:bossBattleButtonCallBack(i)
            end, CCControlEventTouchUpInside)
        end
    end

    --海选、冠军赛页按钮
    for i=1,4 do
        if items["fengshensaibtn"..i] then
            items["fengshensaibtn"..i]:setTouchPriority(self.buttontouch)
            items["fengshensaibtn"..i]:addHandleOfControlEvent(function()
                self:fengshensaiButtonCallBack(i)
            end, CCControlEventTouchUpInside)
        end
    end

    --布阵
    ui.setLabelString(items.arrayLab,"布 阵",18)
    items.arrayBtn:setTouchPriority(self.buttontouch)
    items.arrayBtn:addHandleOfControlEvent(function()
        --进布阵界面
        local data = {
            bossindex = self.bossbuffindex,
            bossBuff = self.godStatus["buff"..self.bossbuffindex] or {},
            period = self.godStatus.period,
            resttime = gameTimer.times["worldwarupdatetimer"],
            type = "pvp", --PVP阶段
        }
        GameScene:shiftLayer("godCompetitionSlotsDetail",nil,data)
    end, CCControlEventTouchUpInside)

    --pvp时间表
    items.timeButton:setTouchPriority(self.buttontouch)
    items.timeButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        gameWindows:openWindow("godCompetitionTime")
    end, CCControlEventTouchUpInside)
end

function godCompetitionMain.bossMainButtonCallBack(self,index)
    if index == 1 then --赛区
        UIRequest({type = 8277})
    elseif index == 2 then --历届冠军
        UIRequest({type = 8276})
    elseif index == 3 then --总奖励
        gameWindows:openWindow("godCompetition_hurtlist",{index = "rewardshow",shenbang = self.pageNum >= 7})  --排行奖励或boss奖励,根据阶段显示,需修改
    elseif index == 4 then --挑战记录
        gameWindows:openWindow("godcompetition_battleRecord")
    elseif index == 5 then --伤害排行
        gameWindows:openWindow("godCompetition_hurtlist",{index = "hurtlist"})
    elseif index == 6 then --伤害奖励
        gameWindows:openWindow("godCompetition_reward")
    elseif index == 7 then --说明
        gameWindows:openWindow("godcompetitionRule")
    elseif index == 8 then --增益
        local data = {
            buff1 = self.godStatus["buff1"] or {},
            buff2 = self.godStatus["buff2"] or {},
            buff3 = self.godStatus["buff3"] or {},
            period = self.godStatus.period,
            bossid = self.godStatus.bossid,
            opentype = "boss",
        }
        gameWindows:openWindow("godcompetition_bossinfos",data)
    end
end

function godCompetitionMain.bossBattleButtonCallBack(self,index)
    if index == 1 then --BOSS属性
        gameWindows:openWindow("godcompetition_bossskillinfo",{bossIndex = self.bossIndex})
    elseif index == 2 then --挑战说明
        gameWindows:openWindow("godcompetitionRule")
    end
end

function godCompetitionMain.fengshensaiButtonCallBack(self,index)
    if index == 1 then --奖励预览
        gameWindows:openWindow("godCompetition_hurtlist",{index = "rewardshow",shenbang = self.pageNum >= 7})  --排行奖励或boss奖励,根据阶段显示,需修改
    elseif index == 2 then --星级排行
        UIRequest({type = 8278})
    elseif index == 3 then --增益
        local data = {
            buff1 = self.godStatus["buff1"] or {},
            buff2 = self.godStatus["buff2"] or {},
            buff3 = self.godStatus["buff3"] or {},
            period = self.godStatus.period,
            bossid = self.godStatus.bossid,
            opentype = "pvp",
        }
        gameWindows:openWindow("godcompetition_bossinfos",data)
    elseif index == 4 then --说明
        gameWindows:openWindow("godcompetitionRule")
    end
end

--设置boss显示形象
function godCompetitionMain.setBossSpineShow(self, items)
    local animationConfig = gamedata.config.generalanimation
    local bossConfig = gamedata.config.apex_boss
    for k,v in pairs(bossConfig) do
        if v.id == 1 then
            items.bossSpine1:removeAllChildrenWithCleanup(true)
            local name = animationConfig[tostring(v.animationid)].name
            local Gneral1 = CCSkeletonAnimation:create(name .."/" .. name .. ".json", name .."/" .. name .. ".atlas",1)
            Gneral1:setAnimation("stand",true,0)
            Gneral1:setScale(0.8)
            Gneral1:setPosition(0,-50)
            items.bossSpine1:addChild(Gneral1)
        elseif v.id == 2 then
            items.bossSpine2:removeAllChildrenWithCleanup(true)
            local name = animationConfig[tostring(v.animationid)].name
            local Gneral1 = CCSkeletonAnimation:create(name .."/" .. name .. ".json", name .."/" .. name .. ".atlas",1)
            Gneral1:setAnimation("stand",true,0)
            Gneral1:setScale(0.8)
            Gneral1:setPosition(0,-50)
            items.bossSpine2:addChild(Gneral1)
        else
            items.bossSpine3:removeAllChildrenWithCleanup(true)
            local name = animationConfig[tostring(v.animationid)].name
            local Gneral1 = CCSkeletonAnimation:create(name .."/" .. name .. ".json", name .."/" .. name .. ".atlas",1)
            Gneral1:setAnimation("stand",true,0)
            Gneral1:setScale(0.8)
            Gneral1:setPosition(0,-50)
            items.bossSpine3:addChild(Gneral1)
        end
    end
end

function godCompetitionMain.setTime(self,state)
    print("state = ",state)
    local showtime = {{66,67},{70,71},{74,75},{78,79},{82,83},{86,87}}
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
    local timestring = "下"..(gameConfig.strings.bigNum[1]).."轮比赛：".."周"..gameConfig.strings:string_common("wdayNum",(timeconfig1.open_week+1)>7 and 1 or (timeconfig1.open_week+1)).." "..hour1..":"..min1.." ~ ".."周"..gameConfig.strings:string_common("wdayNum",(timeconfig2.over_week+1)>7 and 1 or (timeconfig2.over_week+1)).." "..hour2..":"..min2
    ui.setLabelString(self.rootItems["showtime1"],timestring,13) 
end

--导航栏切换
function godCompetitionMain.shiftPageNum(self,num)
    self.pageNum = num

    for i=1,6 do
        if self.godStatus.group > 0 and i == self.pageNum then
            self.rootItems["selectnum"..i]:setVisible(true)
        else
            self.rootItems["selectnum"..i]:setVisible(false)
        end
    end

    if self.pageNum == 1 then
        self:showNode(self.rootItems.midnode1,true)
        self:showNode(self.rootItems.midnode2,false)
    else
        self:showNode(self.rootItems.midnode1,false)
        self:showNode(self.rootItems.midnode2,true)
    end

    --boss战时间显示
    self.rootItems.time_title:setVisible(false)
    self.rootItems.boss_endtime:setVisible(false)
    if self.pageNum == 1 then --boss战
        self.rootItems.time_title:setVisible(true)
        self.rootItems.boss_endtime:setVisible(true)
        self:shiftPage("boss")
    elseif self.pageNum == 2 then--海选赛
        self:shiftPage("personal") 
    elseif self.pageNum == 3 then --小组赛
        self:shiftPage("group")
    else --冠军赛
        if self.pageNum == 4 then
            self:showNode(self.rootItems.championccbnode1,true)
            self:showNode(self.rootItems.championccbnode2,false)
            self:showNode(self.rootItems.championccbnode3,false)
        elseif self.pageNum == 5 then
            self:showNode(self.rootItems.championccbnode1,false)
            self:showNode(self.rootItems.championccbnode2,true)
            self:showNode(self.rootItems.championccbnode3,false)
        else
            self:showNode(self.rootItems.championccbnode1,false)
            self:showNode(self.rootItems.championccbnode2,false)
            self:showNode(self.rootItems.championccbnode3,true)
        end
        self:shiftPage("champion")
    end
    
end

--界面切换
function godCompetitionMain.shiftPage(self,type,notcheck)
    self.selectpage = type

    if type ~= "boss" then
        self:showNode(self.rootItems.selectBossBtnNode,false)
        self:showNode(self.rootItems.battleBossBtnNode,false)
        self:showNode(self.rootItems.fengshensaiBtnNode,true)
    end

    if type == "boss" then

        self:showNode(self.rootItems.selectBossBtnNode,true)
        self:showNode(self.rootItems.battleBossBtnNode,false)
        self:showNode(self.rootItems.fengshensaiBtnNode,false)

        self:initBossPage()
 
    elseif type == "personal" then 
        self.rootItems.groupNode2:setVisible(false)

        self:showNode(self.rootItems.personalNode,true)
        self:showNode(self.rootItems.groupNode,false)
        self:showNode(self.rootItems.championNode,false)

        if next(self.godComRoleBattles) then
            self:reloadPersonal()
        else
            UIRequest({type = 8279})
        end
    elseif type == "group" then
        self.rootItems.groupNode2:setVisible(true)

        self:showNode(self.rootItems.personalNode,false)
        self:showNode(self.rootItems.groupNode,true)
        self:showNode(self.rootItems.championNode,false)
        
        if next(self.godtop) then
            self:ReloadTop()
        else
            UIRequest({type = 8280})
        end
    elseif type == "champion" then
        self.rootItems.groupNode2:setVisible(true)

        self:showNode(self.rootItems.personalNode,false)
        self:showNode(self.rootItems.groupNode,false)
        self:showNode(self.rootItems.championNode,true)
        
        if next(self.godtop) then
            self:ReloadTop()
        else
            UIRequest({type = 8280})
        end
    end

    self.rootItems.info:setString("")
    self.rootItems.arrayNode:setVisible(false)
    if next(self.godStatus) and self.godStatus.group > 0 then
        if type == "boss" and self.bossIndex == 0 then --boss界面
            -- ui.setLabelString(self.rootItems.info,"新一届封神赛准备中", 14)
        elseif type == "group" or type == "champion" then --冠军赛界面
            local canArray = self.godStatus.competition > 0 and self:checkArrayStatus() and self.godStatus.iscanArray == 1
            self.rootItems.arrayNode:setVisible(canArray)
        end
    else
        local day = gamedata.config.apex_battle_interval["1"].start_limit
        ui.setLabelString(self.rootItems.info,"开服天数≥"..day.."天开启封神赛", 14)
    end

end

--BOSS页面
function godCompetitionMain.initBossPage(self)
    
    self.rootItems.selectBossNode:setVisible(true)
    self.rootItems.battleBossNode:setVisible(false)

    for i=1,3 do
        self.rootItems["selectBossbtn"..i]:setTouchPriority(self.buttontouch)
        self.rootItems["selectBossbtn"..i]:addHandleOfControlEvent(function()
            if self.godStatus.group > 0 then
                if self.godStatus.status == 0 then
                    runGamePrompt({msg = "BOSS战未开启"})
                elseif self.godStatus.status == 1 then
                    self:reloadBossBattlePage(i)
                else
                    runGamePrompt({msg = "BOSS战已结束"})
                end
            else
                runGamePrompt({msg = "您所在的区服未开赛"})
            end
            
        end, CCControlEventTouchUpInside)
    end
    
end

function godCompetitionMain.reloadBossBattlePage(self, index)
    
    self:showNode(self.rootItems.selectBossBtnNode,false)
    self:showNode(self.rootItems.battleBossBtnNode,true)
    self:showNode(self.rootItems.fengshensaiBtnNode,false)

    self.rootItems.selectBossNode:setVisible(false)
    self.rootItems.battleBossNode:setVisible(true)

    --设置形象
    if self.bossIndex ~= index then
        self.bossIndex = index --设置ID
        local animationConfig = gamedata.config.generalanimation
        local bossConfig = gamedata.config.apex_boss
        self.rootItems.fssBossSpine:removeAllChildrenWithCleanup(true)
        for k,v in pairs(bossConfig) do
            if v.id == self.bossIndex then
                local name = animationConfig[tostring(v.animationid)].name
                local Gneral1 = CCSkeletonAnimation:create(name .."/" .. name .. ".json", name .."/" .. name .. ".atlas",1)
                Gneral1:setAnimation("stand",true,0)
                Gneral1:setScale(1.5)
                Gneral1:setPosition(0,-60)
                self.rootItems.fssBossSpine:addChild(Gneral1)
                self.rootItems.bossNameText:setString(v.name)
            end
        end
    end

    if self.godStatus and next(self.godStatus) then
        --设置挑战次数
        self.rootItems.battleboss_num:setString(tonumber(gamedata.config.global_kv.apex_boss_num.value) - self.godStatus.num)
        ui.setLabelString(self.rootItems.apexboss_num, "/"..gamedata.config.global_kv.apex_boss_num.value, 14, 36)
        if self.godStatus.num >= tonumber(gamedata.config.global_kv.apex_boss_num.value) then
            ui.setLabelString(self.rootItems.battleboss_num, nil, 11, 36)
        else
            ui.setLabelString(self.rootItems.battleboss_num, nil, 3, 36)
        end
        --伤害
        local bossOneHP = 10000000000
        local hpNum = 0
        local nowHP = self.godStatus["newDamage"..self.bossIndex]
        if self.godStatus["newDamage"..self.bossIndex] > bossOneHP then
            hpNum = math.floor(self.godStatus["newDamage"..self.bossIndex]/bossOneHP)
            -- nowHP = self.godStatus["newDamage"..self.bossIndex] - bossOneHP*hpNum
            nowHP = bossOneHP
        end
        
        self.rootItems.bossblood:setString("我的伤害："..ui.makeshortnum(self.godStatus["newDamage"..self.bossIndex]))
        -- if hpNum > 0 then
        --     if hpNum % 3 == 0 then
        --         setSpriteFrameByName(self.rootItems.bossbloodbar1,"fss_processbar1")
        --         setSpriteFrameByName(self.rootItems.bossbloodbar2,"processbar14")
        --     elseif hpNum % 3 == 1 then
        --         setSpriteFrameByName(self.rootItems.bossbloodbar1,"fss_processbar2")
        --         setSpriteFrameByName(self.rootItems.bossbloodbar2,"fss_processbar1")
        --     else
        --         setSpriteFrameByName(self.rootItems.bossbloodbar1,"processbar14")
        --         setSpriteFrameByName(self.rootItems.bossbloodbar2,"fss_processbar2")
        --     end
        --     ui.setSpriteTextureRect2(self.rootItems.bossbloodbar1,0,0,1008,41)
        --     ui.setSpriteTextureRect2(self.rootItems.bossbloodbar2,0,0,1008 * nowHP / bossOneHP,41)
        -- else
        --     ui.setSpriteTextureRect2(self.rootItems.bossbloodbar1,0,0,1008 * nowHP / bossOneHP,41)
        --     ui.setSpriteTextureRect2(self.rootItems.bossbloodbar2,0,0,0,41)
        -- end

        ui.setSpriteTextureRect2(self.rootItems.bossbloodbar1,0,0,1008 * nowHP / bossOneHP,41)
        ui.setSpriteTextureRect2(self.rootItems.bossbloodbar2,0,0,0,41)
        
    else
        self.rootItems.bossblood:setString("我的伤害：0")
        ui.setSpriteTextureRect2(self.rootItems.bossbloodbar1,0,0,0,41)
        ui.setSpriteTextureRect2(self.rootItems.bossbloodbar2,0,0,0,41)
    end

    ui.setLabelString(self.rootItems.bossbuzhenbtn, nil, 18)
    self.rootItems["squadbtn"]:setTouchPriority(self.buttontouch)
    self.rootItems["squadbtn"]:addHandleOfControlEvent(function()
        --布阵
        self:gotoGodCompetitionSlots()

    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.bossbattlebtn, nil, 18)
    self.rootItems["challengebossbtn"]:setTouchPriority(self.buttontouch)
    self.rootItems["challengebossbtn"]:addHandleOfControlEvent(function()
        --挑战
        if self.godStatus.num >= tonumber(gamedata.config.global_kv.apex_boss_num.value) then
            runGamePrompt({msg = "今日挑战次数不足"})
        else
            local bossConfig = gamedata.config.apex_boss
            local bossId = 0
            for k,v in pairs(bossConfig) do
                if v.id == self.bossIndex then
                    bossId = v.bossid
                end
            end
            UIRequest({type = 8258, bossid = bossId})
        end
    end, CCControlEventTouchUpInside)

end

--去布阵界面
function godCompetitionMain.gotoGodCompetitionSlots( self )
    local data = {
        bossindex = self.bossIndex,
        bossBuff = self.godStatus["buff"..self.bossIndex] or {},
        period = self.godStatus.period,
        type = "boss", --boss阶段
    }
    GameScene:shiftLayer("godCompetitionSlotsDetail",nil,data)
end

--上传阵容阶段判断
function godCompetitionMain.checkArrayStatus( self )
    local arraystatus = {64,68,72,76,80,84}
    for k,v in ipairs(arraystatus) do
        if self.godStatus.status == v then
            return true
        end
    end
    return false
end

function godCompetitionMain.updatatime(self)
    local timeconfig = self.timeconfig or {}

    local tt = "1"
    if self.timeconfig[tostring(self.godStatus.status+1)] then
        tt = tostring(self.godStatus.status+1)
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
            self.godComRoleBattles = {}
            self.godtop = {}
            UIRequest({type = 8251, param = "update"})
        end
    end)
    --
end

--获取当前封神赛阶段
function godCompetitionMain.getBattleNum( self,data )
    for k,v in ipairs(self.battleNumConfig) do
        if (data.status or 0) <= v.max then
            return k
        end
    end
end

--载入数据
function godCompetitionMain.ReloadBossData(self,data)

    if data and data.godStatus then
        self.godStatus = data.godStatus
    end

    local goddata = self.godStatus
    --第几届跨服战
    self.rootItems.title:setString(goddata.period)
    --赛区
    local zoneconfig = gamedata.config.apex_battle_interval[tostring(goddata.group)]
    --最高伤害的boss
    if goddata.bossid > 0 then
        self.bossbuffindex = gamedata.config.apex_boss[tostring(goddata.bossid)].id
        
        for i=1,3 do
            if i == self.bossbuffindex then
                self.rootItems["highbuff"..i]:setVisible(true)
            else
                self.rootItems["highbuff"..i]:setVisible(false)
            end
        end
    end

    self.rootItems.bossdamage1:setString(ui.makeshortnum(goddata.damage1))
    self.rootItems.bossdamage2:setString(ui.makeshortnum(goddata.damage2))
    self.rootItems.bossdamage3:setString(ui.makeshortnum(goddata.damage3))

    local battleStatus = self:getBattleNum(goddata)
    for i=1,6 do
        if goddata.group > 0 and i <= battleStatus then
            setSpriteFrameByName(self.rootItems["statusnum"..i], "kuafuzha_n_4")
        else
            setSpriteFrameByName(self.rootItems["statusnum"..i], "kuafuzha_n_4_h")
        end
    end

    if goddata.period > 0 and goddata.group > 0 then
        self:updatatime()

        if self.bossIndex ~= 0 then --boss战斗页面刷新
            self:reloadBossBattlePage(self.bossIndex)
        else
            self:shiftPageNum(battleStatus)
        end
        --pvp
        if battleStatus > 1 then
            UIRequest({type = 8279})
        end
    else
        self:shiftPageNum(1)
    end

end

function godCompetitionMain.reloadPersonal( self,data )

    self.rootItems.nowarNode:setVisible(true)
    self.rootItems.haswarNode:setVisible(false)
    if self.godStatus.competition < 1 then
        self.rootItems.nowardesc:setString("封神赛火热进行中，可以在小组赛或冠军赛中进行押注哦！")
    elseif self.godStatus.status < 3 then
        self.rootItems.nowardesc:setString("  海选赛筹备中，周四13点－18点开始进行海选赛，每5分钟进行一轮")
    else
        self.rootItems.nowarNode:setVisible(false)
        self.rootItems.haswarNode:setVisible(true)
    end

    if data and data.godComRoleBattles then
        self.godComRoleBattles = {}
        for k,v in pairs(data.godComRoleBattles) do
            if v.result < 0 and v.time > 0 then 
                local _timerName = "godComRoleBattles"..v.id
                gameTimer:rigistTime(_timerName,v.time+1)
                self.timers["godComRoleBattles"..v.id] = 1
            end
            v.k = tonumber(k)
            table.insert(self.godComRoleBattles,v)
        end
        local sortfunc = function (a,b)
            return a.k > b.k
        end
        table.sort(self.godComRoleBattles,sortfunc)
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
        local hasreward = false
        for k,v in pairs(self.godComRoleBattles) do
            if v.reward and v.reward == 1 then
                hasreward = true
                break
            end
        end
        self.rootItems.getallNode:setVisible(true)
        ui.setLabelString(self.rootItems.getallLab,nil,18)
        self.rootItems.getallButton:setTouchPriority(self.buttontouch)
        if hasreward then
            self.rootItems.getRewardHintNode:setVisible(true)
            ui.removeGray("CCControlButton",self.rootItems.getallButton)
            self.rootItems.getallButton:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(1)
                UIRequest({type = 8272, phase = 0, id = ""})
            end, CCControlEventTouchUpInside)
        else
            self.rootItems.getRewardHintNode:setVisible(false)
            ui.addGray("CCControlButton",self.rootItems.getallButton)
            self.rootItems.getallButton:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(0.5)
                runGamePrompt({msg = "没有可领取的奖励"})
            end, CCControlEventTouchUpInside)
        end
    end
end

--创建个人界面的列表
function godCompetitionMain.createList(self)
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
                ccbdoc.cellCCB, ccbdoc.ccbDocumentControler = CCBReaderLoad("fengshensai/cell_yuxuan",nil,true,"cell_yuxuan")
                celldict[a2] = {cellCCB = ccbdoc.cellCCB,ccbDocumentControler = ccbdoc.ccbDocumentControler,index = a1+1}
            else
                first = false
                ccbdoc.cellCCB = celldict[a2].cellCCB
                ccbdoc.ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCell(ccbdoc.ccbDocumentControler,self.godComRoleBattles[a1+1],a1+1)

            ccbdoc.cellCCB:setPosition(self.normalCellSize.x/2,0)
            if first then
                a2:addChild(ccbdoc.cellCCB)
            end
            r = a2
        elseif fn=="numberOfCells" then
            r = #self.godComRoleBattles
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

function godCompetitionMain.setCell(self,item,data,index)

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
        if not self.isscrolltouched then return end
        gameTouch:clickprofbytime(1)
        if data.reward == 1 then
            UIRequest({
                    type = 8272, 
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
        gameWindows:openWindow("godCompetitionBattleOdds",{
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

    local _timerName = "godComRoleBattles"..data.id
    if gameTimer.times[_timerName] and gameTimer.times[_timerName] > 0 then
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

function godCompetitionMain.ReloadPlayers(self,data)
    if data and data.godplayers then
        self.godplayers = data.godplayers
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

function godCompetitionMain.setGroupIndex(self)
    local datatemp = self.godtop["1"] or {}
    for index=1,8 do
        for i = 1,4 do
            local battledata = datatemp[tostring(4*(index-1)+i)]
            local player1 = self.godplayers[tostring(battledata.p_id1)] or {}
            local player2 = self.godplayers[tostring(battledata.p_id2)] or {}
            if player1.rid == GameScene.roleinfo.id or player2.rid == GameScene.roleinfo.id then 
                self.groupindex = index
            end
        end
    end
end

function godCompetitionMain.ReloadTop(self,data)
    if data and data.godtop then
        self.godtop = data.godtop
    end

    if next(self.godplayers) then
        self:ReloadPlayers()
    else
        UIRequest({type = 8281})
    end
end

function godCompetitionMain.openBattleDetail( self,battledata,betstatus,restbetcount )
    --TODO  把传入的1 和2  干掉
    local player1 = self.godplayers[tostring(battledata.p_id1)] or {}
    local player2 = self.godplayers[tostring(battledata.p_id2)] or {}
    local data = {
        phase = battledata.phase,
        id = battledata.id,
        players = {
            [player1.rid] = player1,
            [player2.rid] = player2,
        }

    }
    if self.godStatus.status >= betstatus then
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
    gameWindows:openWindow("godCompetitionBattleOdds",data)
end

function godCompetitionMain.setGeneralIcon( self,item,data,idx,iswin )
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

function godCompetitionMain.setBattleStatusWithdata( self,item,battledata,idx,betstatus,totalbetcount)
    if item["w_"..idx.."_1"] then
        item["w_"..idx.."_1"]:setVisible(battledata.result==1)
    end
    if item["w_"..idx.."_2"] then
        item["w_"..idx.."_2"]:setVisible(battledata.result==0)
    end

    local maxbetcount = tonumber(gamedata.config.global_kv.apex_battle_yazhu.value)
    local restbetcount = maxbetcount - totalbetcount
    
    item["w_button_c"..idx]:setVisible(self.godStatus.status ~= betstatus or battledata.bet > 0)
    item["w_button_j"..idx]:setVisible(self.godStatus.status == betstatus and battledata.bet <= 0)

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

function godCompetitionMain.setBattleStatusEmpty( self,item,idx )
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

function godCompetitionMain.setGroup8_1( self,item,battledata,idx,totalbetcount )
    printT(battledata,"====64强")
    if battledata then 
        local player1 = self.godplayers[tostring(battledata.p_id1)] or {}
        local player2 = self.godplayers[tostring(battledata.p_id2)] or {}

        self:setGeneralIcon(item,player1,idx*2-1,battledata.result==1)
        self:setGeneralIcon(item,player2,idx*2,battledata.result==0)

        self:setBattleStatusWithdata(item,battledata,idx,65,totalbetcount)--65
        self:setTime(1)
        
    else
        self:setGeneralIcon(item,nil,idx*2-1,false)
        self:setGeneralIcon(item,nil,idx*2,false)

        self:setBattleStatusEmpty(item,idx)
    end
end

function godCompetitionMain.setTimeVisible( self,maxState)   
    self.rootItems.groupNode2:setVisible(not(self.godStatus.status > maxState))
end

function godCompetitionMain.setGroup8_2( self,item,battledata,idx,totalbetcount )
    printT(battledata,"====32强")
    if battledata then 
        local player1 = self.godplayers[tostring(battledata.p_id1)] or {}
        local player2 = self.godplayers[tostring(battledata.p_id2)] or {}
        local winner = nil
        if battledata.result == 1 then
            winner = player1
        elseif battledata.result == 0 then
            winner = player2
        end
        self:setGeneralIcon(item,winner,idx+8,false)

        self:setBattleStatusWithdata(item,battledata,idx+4,69,totalbetcount)--69
        self:setTime(2)
    else
        self:setGeneralIcon(item,nil,idx+8,false)
        self:setBattleStatusEmpty(item,idx+4)
    end
end

function godCompetitionMain.setGroup8_3( self,item,battledata,idx,totalbetcount )
    printT(battledata,"====8强")
    if battledata then 
        local player1 = self.godplayers[tostring(battledata.p_id1)] or {}
        local player2 = self.godplayers[tostring(battledata.p_id2)] or {}

        local winner = nil
        if battledata.result == 1 then
            winner = player1
        elseif battledata.result == 0 then
            winner = player2
        end
        self:setGeneralIcon(item,winner,idx+10,false)

        self:setGeneralIcon(item,player1,idx+8,battledata.result==1)
        self:setGeneralIcon(item,player2,idx+9,battledata.result==0)

        self:setBattleStatusWithdata(item,battledata,idx+6,73,totalbetcount)--73
        self:setTime(3)
    else
        self:setGeneralIcon(item,nil,idx+10,false)
        self:setBattleStatusEmpty(item,idx+6)
    end
end

function godCompetitionMain.setGroup8( self,item,battledata,idx,totalbetcount )
    if battledata then 
        local player1 = self.godplayers[tostring(battledata.p_id1)] or {}
        local player2 = self.godplayers[tostring(battledata.p_id2)] or {}

        self:setGeneralIcon(item,player1,idx*2-1,battledata.result==1)
        self:setGeneralIcon(item,player2,idx*2,battledata.result==0)

        self:setBattleStatusWithdata(item,battledata,idx,77,totalbetcount)--77
        self:setTime(4)
    else
        self:setGeneralIcon(item,nil,idx*2-1,false)
        self:setGeneralIcon(item,nil,idx*2,false)

        self:setBattleStatusEmpty(item,idx)
    end
end

function godCompetitionMain.setGeneralAnimation(self,item,data,idx,islose )
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

function godCompetitionMain.setGroup4( self,item,battledata,idx,totalbetcount )
    if battledata then 
        local player1 = self.godplayers[tostring(battledata.p_id1)] or {}
        local player2 = self.godplayers[tostring(battledata.p_id2)] or {}

        self:setGeneralAnimation(item,player1,idx*2-1,battledata.result==0)
        self:setGeneralAnimation(item,player2,idx*2,battledata.result==1)

        self:setBattleStatusWithdata(item,battledata,idx,81,totalbetcount)--81
        self:setTime(5)
    else
        self:setGeneralAnimation(item,nil,idx*2-1,false)
        self:setGeneralAnimation(item,nil,idx*2,false)

        self:setBattleStatusEmpty(item,idx)
    end
end

function godCompetitionMain.setGroup2( self,item,battledata,idx,totalbetcount )
    if battledata then 
        local player1 = self.godplayers[tostring(battledata.p_id1)] or {}
        local player2 = self.godplayers[tostring(battledata.p_id2)] or {}

        self:setGeneralAnimation(item,player1,1,battledata.result==0)
        self:setGeneralAnimation(item,player2,2,battledata.result==1)

        self.rootItems.championSpr:setVisible(battledata.result>=0)
        self.rootItems.championSpr:setPositionX(battledata.result==1 and -290 or 290)

        self:setBattleStatusWithdata(item,battledata,idx,85,totalbetcount)--85
        self:setTime(6)
    else
        self:setGeneralAnimation(item,nil,1,false)
        self:setGeneralAnimation(item,nil,2,false)
        self.rootItems.championSpr:setVisible(false)
        self:setBattleStatusEmpty(item,idx)
    end
end

function godCompetitionMain.setGroupData(self,index)
    if self.rootItems then
        if not self.groupListTableView then
            self:creategroupList()
        else
            self.groupListTableView:reloadData()
        end
    end

    self:checkSetX()

    if not self.grouprootNode or not self.grouprootItems then
        self.grouprootNode,self.grouprootItems = CCBReaderLoad("fengshensai/fengshensai_bisai", nil, true, "fengshensai_bisai")
        self.grouprootNode:setPosition(0,0)
        self.rootItems.groupccbnode:addChild(self.grouprootNode)
    end

    local datatemp = self.godtop["1"] or {}
    --执行4次   每次处理两头像
    for i = 1,4 do
        self:setGroup8_1(self.grouprootItems,datatemp[tostring(4*(index-1)+i)],i,datatemp.totalbetcount)
    end

    local datatemp2 = self.godtop["2"] or {}
    for i = 1,2 do
        self:setGroup8_2(self.grouprootItems,datatemp2[tostring(2*(index-1)+i)],i,datatemp2.totalbetcount)
    end

    local datatemp3 = self.godtop["3"] or {}
    self:setGroup8_3(self.grouprootItems,datatemp3[tostring(index)],1,datatemp3.totalbetcount)
end

function godCompetitionMain.setChampionData(self)
    if self.pageNum == 4 then
        if not self.championrootNode1 or not self.championrootItems1 then
            self.championrootNode1,self.championrootItems1 = CCBReaderLoad("fengshensai/fengshensai_bisai8", nil, true, "fengshensai_bisai8")
            self.championrootNode1:setPosition(0,0)
            self.rootItems.championccbnode1:addChild(self.championrootNode1)           
        end

        local datatemp = self.godtop["4"] or {}
        for i = 1,4 do
            self:setGroup8(self.championrootItems1,datatemp[tostring(i)],i,datatemp.totalbetcount)
        end
        self.rootItems.championSpr:setVisible(false)
    elseif self.pageNum == 5 then
        if not self.championrootNode2 or not self.championrootItems2 then
            self.championrootNode2,self.championrootItems2 = CCBReaderLoad("fengshensai/fengshensai_bisai4", nil, true, "fengshensai_bisai4")
            self.championrootNode2:setPosition(0,0)
            self.rootItems.championccbnode2:addChild(self.championrootNode2)           
        end
        
        local datatemp2 = self.godtop["5"] or {}
        for i = 1,2 do
            self:setGroup4(self.championrootItems2,datatemp2[tostring(i)],i,datatemp2.totalbetcount)
        end
        self.rootItems.championSpr:setVisible(false)
    else
        if not self.championrootNode3 or not self.championrootItems3 then
            self.championrootNode3,self.championrootItems3 = CCBReaderLoad("fengshensai/fengshensai_bisai2", nil, true, "fengshensai_bisai2")
            self.championrootNode3:setPosition(0,0)
            self.rootItems.championccbnode3:addChild(self.championrootNode3)           
        end

        local datatemp3 = self.godtop["6"] or {}
        self:setGroup2(self.championrootItems3,datatemp3[tostring(1)],1,datatemp3.totalbetcount)
    end
end


function godCompetitionMain.creategroupList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("fengshensai/fengshensai_icon2", nil, true, "fengshensai_icon2")
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

function godCompetitionMain.checkSetX(self)
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

function godCompetitionMain.clear(self)
    gameTouch:UnrigistFunc("begin","godCompetition")
    gameTouch:UnrigistFunc("end","godCompetition")
    gameTimer:UnrigistTimeFunc("worldwarupdatetimer")
    gameTimer:UnrigistTimeFunc("worldwarendtimer")
    gameTimer:UnrigistTimeFunc("worldwarendtimer_boss")
    for k,v in pairs(self.timers) do
        gameTimer:UnrigistTime(k)
        gameTimer:UnrigistTimeFunc(k)
    end

    self.timers = {}
    self.ccbDocument = {}
    self.selectpage = ""
    self.groupindex = 1
    self.pageNum = 1
    self.bossIndex = 0
    self.bossbuffindex = 0
   
    self.groupListTableView = nil
    self.ListTableView = nil
    self.championListccb = {}
    self.championListccb2 = {}
    
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

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.godStatus = {}
    self.godComRoleBattles = {}
    self.godtop = {}
    self.godplayers = {}
end

return godCompetitionMain