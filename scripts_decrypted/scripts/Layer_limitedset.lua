
-- Date: 2019年7月24日
-- 入口集合

local limitedset = {
    --ui节点
    rootNode = nil,
    rootItems = nil,
    buttontouch = -103,

    prompttimenum = {week=3,hour=20,min=20,sec=0},
    begintimenum = {week=3,hour=20,min=30,sec=0},
    endtimenum = {week=3,hour=21,min=0,sec=0},
    finaltimenum = {week=3,hour=21,min=10,sec=0},

    servicewarconfig ={{1,1},{2,2},{3,62},{63,63},{64,64},{65,67},{68,68},{69,71},{72,72},{73,73},{74,76},{77,77},{78,80},{81,81},{82,82},{83,85},{86,86},{87,89},{90,90}},

    servicewarconfig_shenbang ={{1,1},{2,2},{3,62},{63,63},{64,64},{65,67},{68,68},{69,71},{72,72},{73,75},{76,76},{77,77},{78,80},{81,81},{82,84},{85,85},{86,88},{89,89},{90,91},{91,110},{111,111},{112,112},{113,115},{116,116},{117,119},{120,120},{121,123},{124,124}},

    honorbattleconfig ={{0,0},{1,1},{2,2},{3,62},{63,63},{64,64},{65,65},{66,68},{69,69},{70,70},{71,73},{74,74},{75,75},{76,76},{77,79},{80,80},{81,81},{82,84},{85,85},{86,86},{87,87},{88,90},{91,91},{92,92},{93,95},{96,96}},

    competitionconfig ={{0,0},{1,1},{2,2},{3,62},{63,63},{64,64},{65,65},{66,66},{67,67},{68,68},{69,69},{70,70},{71,71},{72,72},{73,73},{74,74},{75,75},{76,76},{77,77},{78,78},{79,79},{80,80},{81,81},{82,82},{83,83},{84,84},{85,85},{86,86},{87,87}},
   
    hintconfig = {
        {
            name = "rootItems",
            type = "self",
            config = {
                servicewar = {212},
                honorwar = {381,452},
                -- boss = {21},
                -- daoguan = {355},        --为啥一样
                cup = {27},
                guildWar = {144},
                wudaohui = {191},
                sanjieliankao = {468},  --为啥一样
                godCompetition = {634},
            },
        },
    },

    systemids = {212,381,21,355,27,144,191,468,634},

    godStatus = 0,
}

function limitedset.init(self,parent,toppos)
    self.rootNode,self.rootItems = CCBReaderLoad("limited/limitedset", nil, true, "limitedset")
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)

    local viewH = toppos - 600 - 160
    local contentH = 1400
    self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    self.rootItems.scrollnode:setTouchPriority(self.buttontouch - 1)
    self.rootItems.scrollnode:setViewSize(CCSizeMake(gameConfig.originSize.width,viewH))

    self.rootItems.container:setPosition(0,viewH - contentH)

    self:initFixedString()
    self:addeffectLayer()
    self:reloadData()
end

function limitedset.reloadData(self, data)
    
    self:honorBattle()          --巅峰对决
    self:serviceWar()           --跨服战
    self:requestWorldBossdata() --群仙屠龙
    self:daoguanUpdateTime()    --道馆守卫
    self:betCup()               --杯赛押注
    UIRequest({type = 2149})    --公会战
    self:sanjieliankaoUpdateTime()  --三界联考
    self:setwudaohuiUpdateTime()    --武道会
    self:godCompetitionMain()  --封神赛

    --公用未开启置灰
    for i,v in ipairs(self.systemids) do
        local config = gamedata.config.build[tostring(v)]
        if config and config.switch == 1 and GameScene.roleinfo.level < config.level then
            self.rootItems["openNode"..i]:setVisible(true)
            self.rootItems["openLab"..i]:setString(gamedata.config.build[tostring(v)].level.."级开启")
        else
            self.rootItems["openNode"..i]:setVisible(false)
        end
    end
end

function limitedset.requestWorldBossdata(self)

    if not GameScene:checkopenlevelbyId(21,true) then
        self.rootItems.boss:addHandleOfControlEvent(function()
            self:skipEffect(3,function (  )
                GameScene:checkopenlevelbyId(468)
            end)
        end, CCControlEventTouchUpInside)
        return
    end

    local nowtime = os.date("*t", gamedata:time())
    local nowtimesec = nowtime.hour*3600 + nowtime.min* 60 + nowtime.sec


    if (nowtimesec > GameScene.layers["main"].module.bosstime[1].beginT and nowtimesec < GameScene.layers["main"].module.bosstime[1].endT) or (nowtimesec > GameScene.layers["main"].module.bosstime[2].beginT and nowtimesec < GameScene.layers["main"].module.bosstime[2].endT) then

        --请求Boss击杀状态
        if nowtimesec <= GameScene.layers["main"].module.bosstime[1].beginT then             
        elseif nowtimesec < GameScene.layers["main"].module.bosstime[1].endT then
            UIRequest({type = 3400,mainRequest = 1}) -- 龙
        elseif nowtimesec <= GameScene.layers["main"].module.bosstime[2].beginT then
        elseif nowtimesec < GameScene.layers["main"].module.bosstime[2].endT then
            UIRequest({type = 3410,mainRequest = 1}) -- 凤
        end
        
    end
    GameScene.layers["main"].module.isBossOver = false
    ui.setLabelString(self.rootItems.bossKillLb, "",24,30)
    gameTimer:rigistTime("limited_bossbegintimer",99999)
    gameTimer:rigistTimeFunc("limited_bossbegintimer",function()
        ui.setLabelString(self.rootItems.bossKillLb, "",24,30)
        ui.sethint(self.rootItems.hint_boss,false)
        local nowtime = os.date("*t", gamedata:time())
        local nowtimesec = nowtime.hour*3600 + nowtime.min* 60 + nowtime.sec
        -- print("limited_bossbegintimer===",ui.makeTimeText(GameScene.layers["main"].module.bosstime[1].beginT-nowtimesec))

        if nowtimesec < GameScene.layers["main"].module.bosstime[1].beginT-600 or (nowtimesec > GameScene.layers["main"].module.bosstime[1].endT and nowtimesec < GameScene.layers["main"].module.bosstime[2].beginT-600) or nowtimesec > GameScene.layers["main"].module.bosstime[2].endT then
            self.rootItems.timeNode3:setVisible(false)

            self.rootItems.boss:addHandleOfControlEvent(function()
                self:skipEffect(3,function (  )
                    runGamePrompt({msg = "不在活动时间内"})
                end)
            end, CCControlEventTouchUpInside)
        else
            self.rootItems.timeNode3:setVisible(true)
            ui.setLabelString(self.rootItems.bossKillLb, "",24,30)

            self.rootItems.boss:setSwallowsTouch(true)
            self.rootItems.boss:setTouchPriority(self.buttontouch)
            if nowtimesec <= GameScene.layers["main"].module.bosstime[1].beginT then

                ui.setLabelString(self.rootItems.bosstimeLb, "开启倒计时:",14,30)
                ui.setLabelString(self.rootItems.bosstime,ui.makeTimeText(GameScene.layers["main"].module.bosstime[1].beginT-nowtimesec),24,30)

                self.rootItems.boss:addHandleOfControlEvent(function()

                    self:skipEffect(3,function (  )
                        runGamePrompt({msg = GameScene.layers["main"].module.bosstime[1].openTipText})
                        GameScene:shiftLayerById(21,{page = "onepage"})
                    end)
                end, CCControlEventTouchUpInside)                
            elseif nowtimesec < GameScene.layers["main"].module.bosstime[1].endT then
                
                --进行中就不展示了
                if GameScene.layers["main"].module.isBossOver then

                    ui.setLabelString(self.rootItems.bossKillLb, "已被击杀",24,30)
                    ui.setLabelString(self.rootItems.bosstimeLb, "",14,30)
                    ui.setLabelString(self.rootItems.bosstime,"",24,30)

                else
                    ui.sethint(self.rootItems.hint_boss,true)
                    ui.setLabelString(self.rootItems.bosstimeLb, "结束倒计时:",14,30)
                    ui.setLabelString(self.rootItems.bosstime,ui.makeTimeText(GameScene.layers["main"].module.bosstime[1].endT-nowtimesec),24,30)
                end
                
                self.rootItems.boss:addHandleOfControlEvent(function()

                    self:skipEffect(3,function (  )
                        GameScene:shiftLayerById(21,{page = "onepage"})
                    end)

                end, CCControlEventTouchUpInside)
            elseif nowtimesec <= GameScene.layers["main"].module.bosstime[2].beginT then

                ui.setLabelString(self.rootItems.bosstimeLb, "开启倒计时:",14,30)
                ui.setLabelString(self.rootItems.bosstime,ui.makeTimeText(GameScene.layers["main"].module.bosstime[2].beginT-nowtimesec),24,30)

                self.rootItems.boss:addHandleOfControlEvent(function()

                    self:skipEffect(3,function (  )
                        runGamePrompt({msg = GameScene.layers["main"].module.bosstime[2].openTipText})
                        GameScene:shiftLayerById(21,{page = "twopage"})
                    end)
                    
                end, CCControlEventTouchUpInside)
            elseif nowtimesec < GameScene.layers["main"].module.bosstime[2].endT then
                if GameScene.layers["main"].module.isBossOver then
                    ui.setLabelString(self.rootItems.bossKillLb, "已被击杀",24,30)
                    ui.setLabelString(self.rootItems.bosstimeLb, "",14,30)
                    ui.setLabelString(self.rootItems.bosstime,"",24,30)
                else
                    ui.sethint(self.rootItems.hint_boss,true)
                    ui.setLabelString(self.rootItems.bosstimeLb, "结束倒计时:",14,30)
                    ui.setLabelString(self.rootItems.bosstime,ui.makeTimeText(GameScene.layers["main"].module.bosstime[2].endT-nowtimesec),24,30)
                end
                self.rootItems.boss:addHandleOfControlEvent(function()

                    self:skipEffect(3,function (  )
                        GameScene:shiftLayerById(21,{page = "twopage"})
                    end)

                    
                end, CCControlEventTouchUpInside)
            end
        end

        if gameTimer.times["limited_bossbegintimer"] <= 0 then
            gameTimer:rigistTime("limited_bossbegintimer",99999)
        end
    end)
end

function limitedset.sanjieliankaoUpdateTime(self,data)
    --  local datas = {
    --   { kstype =1, status = 1,currentnum = 0, rightnum = 0, currentTimuid = 0, useAlltime = 0,jifen = 0},
    --   { kstype =2,status = 2, currentnum = 5, rightnum = 2, currentTimuid = 3, useAlltime = 0,jifen = 0},
    --   { kstype =3,status = 3, currentnum = 5, rightnum = 1, currentTimuid = 5, useAlltime = 0,jifen = 0},
    -- }

    -- UIRequest({type = 7002})
    --三界联考按钮
    self.rootItems.sanjieliankaobtn:setSwallowsTouch(true)
    self.rootItems.sanjieliankaobtn:setTouchPriority(self.buttontouch)
    self.rootItems.sanjieliankaobtn:addHandleOfControlEvent(function()

        self:skipEffect(8,function (  )
            if not GameScene:checkopenlevelbyId(468) then
                return
            end
            if GameScene.layers["main"].module and GameScene.layers["main"].module.sanjieliankaoIsout then
                runGamePrompt({msg = "不在活动时间内"})
                return
            end
            GameScene:shiftLayer("examination","up")
        end)

    end, CCControlEventTouchUpInside)  


    if not GameScene:checkopenlevelbyId(468,true) then
        return
    end

    if data and next(data) ~= nil  then
       GameScene.layers["main"].module.examinationData = data.data
    end

    
    print("sanjieliankaoUpdateTime")
    GameScene.layers["main"].module.sanjieliankaoIsout =  false

    ui.setLabelString(self.rootItems.sanjieliankaotimeLb, "",14,30)
    ui.setLabelString(self.rootItems.sanjieliankaotime,"",24,30)


    if next(GameScene.layers["main"].module.examinationData) == nil  then
        return
    end     
    
    local opentype = 0
    for i,v in pairs(GameScene.layers["main"].module.examinationData) do
       if v.kstype == 2 and ( v.status == 1 or v.status ==2 or v.status ==4 )   then
           opentype = 1
       elseif v.kstype == 3 and ( v.status == 1 or v.status ==2 or v.status ==4  )   then
           opentype = 2
       end 
    end

    print(opentype,"sanjieliankaoUpdateTime opentype")

    if opentype == 0 then return end

    -- gamedata.cache.examination

    local times = GameScene.layers["examination"].module:gettimes(opentype)
    -- local _nowTime = self:getNowTime()
    -- local _allTimes = _nowTime.hour*3600 + _nowTime.min*60 + _nowTime.sec

    -- printT(_nowTime)
    printT(times,"sanjieliankaoUpdateTime times")
    local _remainTime = 0
    if not times then
            print("sanjieliankaoUpdateTime 1")

        gameTimer:rigistTime("limited_examination_main_flesh", 7 * 24 * 3600)
        gameTimer:rigistTimeFunc("limited_examination_main_flesh", function()
            if GameScene.layers["examination"].module:gettimes(opentype) then
                gameTimer:UnrigistTimeFunc("limited_examination_main_flesh")
                self:sanjieliankaoUpdateTime()
            end

            if gameTimer.times["limited_examination_main_flesh"] == 0 then
                gameTimer:rigistTime("limited_examination_main_flesh", 7 * 24 * 3600)
            end
        end)
    
    elseif times.prompt <= times.now and times.now < times.open then
                    print("sanjieliankaoUpdateTime 2")

        GameScene.layers["main"].module.sanjieliankaoIsout = true

        _remainTime = times.open - times.now
        
        gameTimer:rigistTime("limited_examination_reading", _remainTime)
        gameTimer:rigistTimeFunc("limited_examination_reading", function()
            if gameTimer.times["limited_examination_reading"] >= 0 then

                ui.setLabelString(self.rootItems.sanjieliankaotimeLb, "开启倒计时:",14,30)
                ui.setLabelString(self.rootItems.sanjieliankaotime,ui.makeTimeText(gameTimer.times["limited_examination_reading"], "hour"),24,30)
            end

            if gameTimer.times["limited_examination_reading"] == 0 then
                print("limited_examination_reading====0000")
                gameTimer:UnrigistTimeFunc("limited_examination_reading")

                self:sanjieliankaoUpdateTime()
            end
        end)
    elseif times.open <= times.now and times.now < times.over then
                    print("sanjieliankaoUpdateTime 3")

        GameScene.layers["main"].module.sanjieliankaoIsout = false

        _remainTime = times.over - times.now
        gameTimer:rigistTime("limited_examination_start", _remainTime)
        gameTimer:rigistTimeFunc("limited_examination_start", function()
            if gameTimer.times["limited_examination_start"] >= 0 then

                ui.setLabelString(self.rootItems.sanjieliankaotimeLb, "结束倒计时:",14,30)
                ui.setLabelString(self.rootItems.sanjieliankaotime,ui.makeTimeText(gameTimer.times["limited_examination_start"], "hour"),24,30)
            end

            if gameTimer.times["limited_examination_start"] == 0 then
                print("limited_examination_start====0000")
                gameTimer:UnrigistTimeFunc("limited_examination_start")

                self:sanjieliankaoUpdateTime()
            end
        end)
    elseif times.over <= times.now and times.now < times.finaly then
                    print("sanjieliankaoUpdateTime 4")

        GameScene.layers["main"].module.sanjieliankaoIsout = false

        _remainTime = times.finaly - times.now

        gameTimer:rigistTime("limited_examination_rewards", _remainTime)
        gameTimer:rigistTimeFunc("limited_examination_rewards",function()
            if gameTimer.times["limited_examination_rewards"] >= 0 then
                ui.setLabelString(self.rootItems.sanjieliankaotimeLb, "",14,30)
                ui.setLabelString(self.rootItems.sanjieliankaotime,"",24,30)

                --ui.setLabelString(self.rootItems.sanjieliankaotime, "结束倒计时:"..ui.makeTimeText(gameTimer.times["limited_examination_rewards"], "hour"), 26)
            end
            
            if gameTimer.times["limited_examination_rewards"] == 0 then
                print("limited_examination_rewards====0000")  
                gameTimer:UnrigistTimeFunc("limited_examination_rewards")

                self:sanjieliankaoUpdateTime()
            end
        end)
    else
        print("活动结束活动结束活动结束活动结束===")
        -- 这是武道会的变量还没有更改
        GameScene.layers["main"].module.sanjieliankaoIsout = true
        --ui.setLabelString(self.rootItems.sanjieliankaotime, gameConfig.strings:string_common("examination", 26), 21)
        --活动结束什么都不显示
        ui.setLabelString(self.rootItems.sanjieliankaotimeLb, "",14,30)
        ui.setLabelString(self.rootItems.sanjieliankaotime,"",24,30)
    end

end

function limitedset.setSanjieliankaoHint(self,data)
    ui.sethint(self.rootItems.hint_sanjieliankao,false)

    local hint = false

    if data.data and data.data["2"] and data.data["2"].status and data.data["2"].status ~= 3 then
        hint = true
    end

    if data.data and data.data["3"] and data.data["3"].status and data.data["3"].status ~= 3 then
        hint = true
    end

    if (not GameScene.layers["main"].module.sanjieliankaoIsout) and hint then
        ui.sethint(self.rootItems.hint_sanjieliankao,true)
    end
end

function limitedset.daoguanUpdateTime(self)
    print("daoguanUpdateTime")

    -- UIRequest({type = 5301})
    --道馆按钮
    self.rootItems.daoguanbtn:setSwallowsTouch(true)
    self.rootItems.daoguanbtn:setTouchPriority(self.buttontouch)
    self.rootItems.daoguanbtn:addHandleOfControlEvent(function()

        self:skipEffect(4,function (  )
            if not GameScene:checkopenlevelbyId(355) then
                return
            end

            if GameScene.layers["main"].module and GameScene.layers["main"].module.daoguanIsout then
                runGamePrompt({msg = "不在活动时间内"})
                return
            end

            GameScene.layers["daoGuanMain"].module.daoguanOnceHint = true
            GameScene:shiftLayer("daoGuanMain","up")
        end)
    end, CCControlEventTouchUpInside)  


    if not GameScene:checkopenlevelbyId(355,true) then
        return
    end

    GameScene.layers["main"].module.daoguanIsout = true

    

    ui.setLabelString(self.rootItems.daoguantime,"", 14,30)
    ui.setLabelString(self.rootItems.daoguantimeLb,"", 24,30)


    local times = GameScene.layers["daoGuanMain"].module:gettimes()
    
    printT(times)
    local _remainTime = 0

    if not times then
        gameTimer:rigistTime("limited_daoguan_main_flesh", 7 * 24 * 3600)
        gameTimer:rigistTimeFunc("limited_daoguan_main_flesh", function()
            if GameScene.layers["daoGuanMain"].module:gettimes() then
                gameTimer:UnrigistTimeFunc("limited_daoguan_main_flesh")
                self:daoguanUpdateTime()
            end

            if gameTimer.times["limited_daoguan_main_flesh"] == 0 then
                gameTimer:rigistTime("limited_daoguan_main_flesh", 7 * 24 * 3600)
            end
        end)
    
    elseif times.prompt <= times.now and times.now < times.open then
        GameScene.layers["main"].module.daoguanIsout = true

        _remainTime = times.open - times.now
        
        gameTimer:rigistTime("limited_daoguan_reading", _remainTime)
        gameTimer:rigistTimeFunc("limited_daoguan_reading", function()
            if gameTimer.times["limited_daoguan_reading"] >= 0 then

                ui.setLabelString(self.rootItems.daoguantimeLb,"开启倒计时:", 14,30)
                ui.setLabelString(self.rootItems.daoguantime,ui.makeTimeText(gameTimer.times["limited_daoguan_reading"], "hour"), 24,30)

            end

            if gameTimer.times["limited_daoguan_reading"] == 0 then
                print("limited_daoguan_reading====0000")
                gameTimer:UnrigistTimeFunc("limited_daoguan_reading")

                self:daoguanUpdateTime()
            end
        end)
    elseif times.open <= times.now and times.now < times.over then
        GameScene.layers["main"].module.daoguanIsout = false

        _remainTime = times.over - times.now
        gameTimer:rigistTime("limited_daoguan_start", _remainTime)
        gameTimer:rigistTimeFunc("limited_daoguan_start", function()
            if gameTimer.times["limited_daoguan_start"] >= 0 then

                ui.setLabelString(self.rootItems.daoguantimeLb,"结束倒计时:", 14,30)
                ui.setLabelString(self.rootItems.daoguantime,ui.makeTimeText(gameTimer.times["limited_daoguan_start"], "hour"), 24,30)
            end

            if gameTimer.times["limited_daoguan_start"] == 0 then
                print("limited_daoguan_start====0000")
                gameTimer:UnrigistTimeFunc("limited_daoguan_start")

                self:daoguanUpdateTime()
            end
        end)
    elseif times.over <= times.now and times.now < times.finaly then
        GameScene.layers["main"].module.daoguanIsout = false

        _remainTime = times.finaly - times.now

        gameTimer:rigistTime("limited_daoguan_rewards", _remainTime)
        gameTimer:rigistTimeFunc("limited_daoguan_rewards",function()
            if gameTimer.times["limited_daoguan_rewards"] >= 0 then
                ui.setLabelString(self.rootItems.daoguantime,"", 14,30)
                ui.setLabelString(self.rootItems.daoguantimeLb,"", 24,30)
                --ui.setLabelString(self.rootItems.daoguantime, gameConfig.strings:string_common("daoguanshouwei", 25)..ui.makeTimeText(gameTimer.times["limited_daoguan_rewards"], "hour"), 26)
            end
            
            if gameTimer.times["limited_daoguan_rewards"] == 0 then
                print("limited_daoguan_rewards====0000")  
                gameTimer:UnrigistTimeFunc("limited_daoguan_rewards")

                self:daoguanUpdateTime()
            end
        end)
    else
        print("活动结束活动结束活动结束活动结束===")
        -- 这是武道会的变量还没有更改
        GameScene.layers["main"].module.daoguanIsout = true
        ui.setLabelString(self.rootItems.daoguantime,"", 14,30)
        ui.setLabelString(self.rootItems.daoguantimeLb,"", 24,30)
        --ui.setLabelString(self.rootItems.daoguantime, gameConfig.strings:string_common("daoguanshouwei", 26), 21)
        self:setDaoguanHint()
    end

    self:setDaoguanHint()
end

function limitedset.setDaoguanHint(self)
    
    print("setDaoguanHint",GameScene.hintdata["355"],GameScene.layers["daoGuanMain"].module.daoguanOnceHint)
    local isopen = true
    local times = GameScene.layers["daoGuanMain"].module:gettimes()
    if times then
        if times.now < times.open then
            isopen = false
        end
    else
        isopen = false
    end

    local hint = GameScene.hintdata["355"] and GameScene.hintdata["355"] or 0
    ui.sethint(self.rootItems.hint_daoguan,false)
    if hint ~= 0 and isopen then
        --有可领奖
        if hint == 1 then
            ui.sethint(self.rootItems.hint_daoguan,true)
        --有可攻打 也有可领奖
        elseif hint == 11 then
            ui.sethint(self.rootItems.hint_daoguan,true)
        --有可攻打 并且没提示过
        elseif hint == 10 and (not GameScene.layers["daoGuanMain"].module.daoguanOnceHint) then
            ui.sethint(self.rootItems.hint_daoguan,true)
        end
    end
end

function limitedset.gonghuizhanUpdateTime(self,gangdata)
    printT(gangdata,"gangdata===")

    ui.setLabelString(self.rootItems.guildWartimeLb,"",14,30)
    ui.setLabelString(self.rootItems.guildWartime,"",24,30)

    if not gangdata or ( not next(gangdata)) then 
        ui.setButtonFunc(self.rootItems.guildWar,true,self.buttontouch,function()

            self:skipEffect(6,function (  )
                runGamePrompt({msg = "未加入公会，无法参加公会战"})
            end)
            
        end)
        return 
    else
        self.gangdata = gangdata
    end


    local globalconfig = gamedata.config:getConfigByName("global_kv")
    
    ui.setButtonFunc(self.rootItems.guildWar,true,self.buttontouch,function()
        self:skipEffect(6,function (  )
            
            if gamedata:time() - self.gangdata.initiationtime < 24*60*60 then
                runGamePrompt({msg = "加入公会时间不足，无法参加公会战"})
                return
            end

            if tonumber(self.gangdata.level) >= tonumber(globalconfig.gang2_signup_minlevel.value) then
                UIRequest({type = 2130, param = "main"})
            else
                runGamePrompt({msg = "公会等级不足，无法参加公会战"})
            end
        end)
    end)

    if gamedata.config:getConfigByName("gang2_battleTime") and gamedata.config:getConfigByName("gang2_battleTime")["1"] and gamedata.config:getConfigByName("gang2_battleTime")["1"]["1"] and gamedata.config:getConfigByName("gang2_battleTime")["1"]["1"].weektime_open and gamedata.config:getConfigByName("gang2_battleTime")["1"]["1"].weektime_open > 0 then
        
    else
        return
    end

    if  tonumber(self.gangdata.level) < tonumber(globalconfig.gang2_signup_minlevel.value) then
        return
    end

    local battletimeconfig = gamedata.config:getConfigByName("gang2_battleTime")

    -- 夺宝战 报名时间
    local hour1,min1,sec1 = ui.getGangBattleTime(battletimeconfig["1"]["1"]["opentime"])
    local hour2,min2,sec2 = ui.getGangBattleTime(battletimeconfig["1"]["1"]["overtime"])
    print("hour1,min1,sec1==",hour1,min1,sec1)
    print("hour2,min2,sec2==",hour2,min2,sec2)

    self.begintimenum1 = {week=battletimeconfig["1"]["1"]["weektime_open"], hour=hour1, min=min1, sec=sec1}
    self.endtimenum1 = {week=battletimeconfig["1"]["1"]["weektime_over"], hour=hour2, min=min2, sec=sec2}

    -- 夺宝战 入场时间
    local hour1,min1,sec1 = ui.getGangBattleTime(battletimeconfig["1"]["2"]["opentime"])
    local hour2,min2,sec2 = ui.getGangBattleTime(battletimeconfig["1"]["2"]["overtime"])

    self.beginreadingnum1 = {week=battletimeconfig["1"]["2"]["weektime_open"], hour=hour1, min=min1, sec=sec1}
    self.endreadingnum1 = {week=battletimeconfig["1"]["2"]["weektime_over"], hour=hour2, min=min2, sec=sec2}

    -- 夺宝战 攻打时间
    local hour1,min1,sec1 = ui.getGangBattleTime(battletimeconfig["1"]["3"]["opentime"])
    local hour2,min2,sec2 = ui.getGangBattleTime(battletimeconfig["1"]["4"]["overtime"])

    self.beginfightingnum1 = {week=battletimeconfig["1"]["3"]["weektime_open"], hour=hour1, min=min1, sec=sec1}
    self.endfightingnum1 = {week=battletimeconfig["1"]["4"]["weektime_over"], hour=hour2, min=min2, sec=sec2}

    -- 夺宝战 领奖时间
    local hour1,min1,sec1 = ui.getGangBattleTime(battletimeconfig["1"]["5"]["opentime"])
    local hour2,min2,sec2 = ui.getGangBattleTime(battletimeconfig["1"]["5"]["overtime"])

    self.beginrewardnum1 = {week=battletimeconfig["1"]["5"]["weektime_open"], hour=hour1, min=min1, sec=sec1}
    self.endrewardgnum1 = {week=battletimeconfig["1"]["5"]["weektime_over"], hour=hour2, min=min2, sec=sec2}

    -----------------------------------------------------------
    -----------------------------------------------------------
    -- 第二场 公会战 
    
    -- 夺宝战 报名时间
    local hour1,min1,sec1 = ui.getGangBattleTime(battletimeconfig["2"]["1"]["opentime"])
    local hour2,min2,sec2 = ui.getGangBattleTime(battletimeconfig["2"]["1"]["overtime"])

    self.begintimenum2 = {week=battletimeconfig["2"]["1"]["weektime_open"], hour=hour1, min=min1, sec=sec1}
    self.endtimenum2 = {week=battletimeconfig["2"]["1"]["weektime_over"], hour=hour2, min=min2, sec=sec2}

    -- 夺宝战 入场时间
    local hour1,min1,sec1 = ui.getGangBattleTime(battletimeconfig["2"]["2"]["opentime"])
    local hour2,min2,sec2 = ui.getGangBattleTime(battletimeconfig["2"]["2"]["overtime"])

    self.beginreadingnum2 = {week=battletimeconfig["2"]["2"]["weektime_open"], hour=hour1, min=min1, sec=sec1}
    self.endreadingnum2 = {week=battletimeconfig["2"]["2"]["weektime_over"], hour=hour2, min=min2, sec=sec2}

    -- 夺宝战 攻打时间
    local hour1,min1,sec1 = ui.getGangBattleTime(battletimeconfig["2"]["3"]["opentime"])
    local hour2,min2,sec2 = ui.getGangBattleTime(battletimeconfig["2"]["4"]["overtime"])

    self.beginfightingnum2 = {week=battletimeconfig["2"]["3"]["weektime_open"], hour=hour1, min=min1, sec=sec1}
    self.endfightingnum2 = {week=battletimeconfig["2"]["4"]["weektime_over"], hour=hour2, min=min2, sec=sec2}

    -- 夺宝战 领奖时间
    local hour1,min1,sec1 = ui.getGangBattleTime(battletimeconfig["2"]["5"]["opentime"])
    local hour2,min2,sec2 = ui.getGangBattleTime(battletimeconfig["2"]["5"]["overtime"])

    self.beginrewardnum2 = {week=battletimeconfig["2"]["5"]["weektime_open"], hour=hour1, min=min1, sec=sec1}
    self.endrewardgnum2 = {week=battletimeconfig["2"]["5"]["weektime_over"], hour=hour2, min=min2, sec=sec2}

    gameTimer:rigistTime("limited_guildwarbegintimer",99999)
    gameTimer:rigistTimeFunc("limited_guildwarbegintimer",function()

        local nowtime = os.date("*t", gamedata:time())
        local daynums = (nowtime.wday == 1 and 7 or (nowtime.wday-1))
        local alltimes = (daynums-1)*24*3600 + nowtime.hour*3600 + nowtime.min*60 + nowtime.sec - 1

        local begintimenum = 0
        local endtimenum = 0

        if alltimes >= self:gettimenum(self.endrewardgnum1) and alltimes < self:gettimenum(self.endrewardgnum2) then
            -- 夺宝战 报名时间(第二轮)
            begintimenum = self.begintimenum2
            endtimenum = self.endtimenum2

            -- 夺宝战 入场时间
            self.beginreadingnum = self.beginreadingnum2
            self.endreadingnum = self.endreadingnum2

            -- 夺宝战 攻打时间
            self.beginfightingnum = self.beginfightingnum2
            self.endfightingnum = self.endfightingnum2

            -- 夺宝战 领奖时间
            self.beginrewardnum = self.beginrewardnum2
            self.endrewardgnum = self.endrewardgnum2
        else
            -- 夺宝战 报名时间（第一轮
            begintimenum = self.begintimenum1
            endtimenum = self.endtimenum1

            -- 夺宝战 入场时间
            self.beginreadingnum = self.beginreadingnum1
            self.endreadingnum = self.endreadingnum1

            -- 夺宝战 攻打时间
            self.beginfightingnum = self.beginfightingnum1
            self.endfightingnum = self.endfightingnum1

            -- 夺宝战 领奖时间 
            self.beginrewardnum = self.beginrewardnum1
            self.endrewardgnum = self.endrewardgnum1
        end

        local remaintime = 0
        local now = ""

        if self:gettimenum(begintimenum) <= alltimes and alltimes < self:gettimenum(endtimenum) then
            --报名已开始 截止倒计时
            now = "报名倒计时:"
            remaintime = self:gettimenum(endtimenum) - alltimes

        elseif self:gettimenum(endtimenum) <= alltimes and alltimes < self:gettimenum(self.beginreadingnum) then
            
            --报名已结束，距离正式开战倒计时
            now = "开战倒计时:"
            remaintime = self:gettimenum(self.beginreadingnum) - alltimes

        elseif self:gettimenum(self.beginreadingnum) <= alltimes and alltimes < self:gettimenum(self.endreadingnum) then
            
            --夺宝战入场，截止倒计时
            now = "入场倒计时:"
            remaintime = self:gettimenum(self.endreadingnum) - alltimes


        elseif self:gettimenum(self.beginfightingnum) <= alltimes and alltimes < self:gettimenum(self.endfightingnum) then
            
            --战斗已开始
            now = "结束倒计时:"
            remaintime = self:gettimenum(self.endfightingnum) - alltimes

        elseif self:gettimenum(self.beginrewardnum) <= alltimes and alltimes < self:gettimenum(self.endrewardgnum) then
            
        elseif self:gettimenum(self.endrewardgnum1) <= alltimes and alltimes < self:gettimenum(self.begintimenum2) then
            
        else
            
        end
        
        if now == "" then
            --按钮不能点？
            ui.setLabelString(self.rootItems.guildWartimeLb,"",14,30)
            ui.setLabelString(self.rootItems.guildWartime,"",24,30)
        else
            ui.setLabelString(self.rootItems.guildWartimeLb,now,14,30)
            ui.setLabelString(self.rootItems.guildWartime,ui.makeTimeText(remaintime),24,30)
        end

        if gameTimer.times["limited_guildwarbegintimer"] <= 0 then
            gameTimer:rigistTime("limited_guildwarbegintimer",99999)
        end
    end)
end
-- 公会战倒数时间计算（秒
function limitedset.gettimenum(self,times,minnum)
    -- print("minnum===",minnum)
    local min = 0
    if minnum then
        min = minnum
    end
    local alltimes = 0
    alltimes = (times.week and (times.week-1) or 0)*24*3600 + (times.hour or 0)*3600 + times.min*60 + times.sec + min*60
    return alltimes
end


function limitedset.skipEffect(self,index,callback)
    
    if gameTouch.ismove then return end

    gameTouch:clickprofbytime(0.5)
    self.rootItems["node"..index]:setScale(0)
    self.rootItems["node"..index]:setRotation(0)

    local scaleto = CCScaleTo:create(0.33, 1)
    local action1 = CCSequence:createWithTwoActions(CCEaseBackOut:create(scaleto), CCCallFunc:create(function()

        if not GameScene:checkopenlevelbyId(self.systemids[index]) then
            return
        end

        callback()
    end))
    local rotationby1 = CCRotateBy:create(0.2, -10)
    local rotationby2 = CCRotateBy:create(0.13, 10)

    local action2 = CCSequence:createWithTwoActions(rotationby1,rotationby2)
    local action3 = CCSpawn:createWithTwoActions(action1,action2)

    self.rootItems["node"..index]:runAction(action3)
end

-- 武道会 判断为哪个活动倒计时
function limitedset.setwudaohuiUpdateTime( self )

    ui.setLabelString(self.rootItems.wudaohuitimeLb,"",14,30)
    ui.setLabelString(self.rootItems.wudaohuitime,"",24,30)
    -- UIRequest({type = 4100})
    GameScene.layers["main"].module.isout = true
    --武道会按钮
    self.rootItems.wudaohuibtn:setSwallowsTouch(true)
    self.rootItems.wudaohuibtn:setTouchPriority(self.buttontouch)
    self.rootItems.wudaohuibtn:addHandleOfControlEvent(function()

        self:skipEffect(7,function (  )
            if not GameScene:checkopenlevelbyId(191) then
                return
            end

            print("isout",GameScene.layers["main"].module.isout)
            
            if GameScene.layers["main"].module and GameScene.layers["main"].module.isout == true then
                runGamePrompt({msg = "不在活动时间内"})
                return
            end
            GameScene:shiftLayerById(191)
        end)
        
    end, CCControlEventTouchUpInside) 

    if not GameScene:checkopenlevelbyId(191,true) then
        return
    end

    

    if gamedata.config:getConfigByName("wudao_time") and gamedata.config:getConfigByName("wudao_time")["1"] and gamedata.config:getConfigByName("wudao_time")["1"].open_week and gamedata.config:getConfigByName("wudao_time")["1"].open_week > 0 then
    else
        return
    end

    local nowtime = os.date("*t", gamedata:time())
    local daynums = (nowtime.wday == 1 and 7 or (nowtime.wday-1))

    local updatestatus = false
    for k,v in pairs(gamedata.config:getConfigByName("wudao_time")) do
        if tonumber(v.open_week) == daynums then
            local hour1,min1,sec1 = ui.getGangBattleTime(v["open_time"])
            local hour2,min2,sec2 = ui.getGangBattleTime(v["over_time"])
            local hour3,min3,sec3 = ui.getGangBattleTime(v["finaly_time"])
            local hour4,min4,sec4 = ui.getGangBattleTime(v["prompt_time"])
            
            self.begintimenum = {week=v["open_week"], hour=hour1, min=min1, sec=sec1}
            self.endtimenum = {week=v["open_week"], hour=hour2, min=min2, sec=sec2}
            self.finaltimenum = {week=v["open_week"], hour=hour3, min=min3, sec=sec3}
            self.prompttimenum = {week=v["open_week"], hour=hour4, min=min4, sec=sec4}
            updatestatus = true
            break
        end
    end

    if updatestatus == false then
        return
    end

    gameTimer:rigistTime("limited_wudaohui_main_flesh", 2*24*3600)
    gameTimer:rigistTimeFunc("limited_wudaohui_main_flesh",function()
        local nowtime = os.date("*t", gamedata:time())
        local daynums = (nowtime.wday == 1 and 7 or (nowtime.wday-1))
        local alltimes = (daynums-1)*24*3600 + nowtime.hour*3600 + nowtime.min*60 + nowtime.sec - 1

        if (self:gettimenum(self.prompttimenum) <= alltimes and alltimes < self:gettimenum(self.begintimenum)) or (self:gettimenum(self.begintimenum) <= alltimes and alltimes < self:gettimenum(self.endtimenum)) or (self:gettimenum(self.endtimenum) <= alltimes and alltimes < self:gettimenum(self.finaltimenum)) then
            self:wudaohuiUpdatetime()
            gameTimer:UnrigistTimeFunc("limited_wudaohui_main_flesh")
        end
        if gameTimer.times["limited_wudaohui_main_flesh"] == 0 then
            gameTimer:UnrigistTimeFunc("limited_wudaohui_main_flesh")
            self:wudaohuiUpdatetime()
        end
    end)

    self:wudaohuiUpdatetime()
end


function limitedset.wudaohuiUpdatetime( self )
    print("wudaohuiUpdatetime")
    printT(self.endtimenum,"self.endtimenum")
    printT(self.finaltimenum,"self.finaltimenum")

    GameScene.layers["main"].module.isout = true

    local nowtime = os.date("*t", gamedata:time())
    local daynums = (nowtime.wday == 1 and 7 or (nowtime.wday-1))
    local alltimes = (daynums - 1)*24*3600 + nowtime.hour*3600 + nowtime.min*60 + nowtime.sec - 1

    local remaintime = 0

    if self:gettimenum(self.prompttimenum) <= alltimes and alltimes < self:gettimenum(self.begintimenum) then
        GameScene.layers["main"].module.isout = true

        remaintime = self:gettimenum(self.begintimenum) - alltimes

        gameTimer:rigistTime("limited_wudaohui_reading", remaintime)
        gameTimer:rigistTimeFunc("limited_wudaohui_reading",function()           
            if gameTimer.times["limited_wudaohui_reading"] >= 0 then

                ui.setLabelString(self.rootItems.wudaohuitimeLb,"开启倒计时:",14,30)
                ui.setLabelString(self.rootItems.wudaohuitime,ui.makeTimeText(gameTimer.times["limited_wudaohui_reading"],"hour"),24,30)

            end
            if gameTimer.times["limited_wudaohui_reading"] == 0 then
                gameTimer:UnrigistTimeFunc("limited_wudaohui_reading")
                self:wudaohuiUpdatetime()
            end
        end)


    elseif self:gettimenum(self.begintimenum) <= alltimes and alltimes < self:gettimenum(self.endtimenum) then
        print("333333")
        GameScene.layers["main"].module.isout = false

        remaintime = self:gettimenum(self.endtimenum) - alltimes

        gameTimer:rigistTime("limited_wudaohui_start", remaintime)
        gameTimer:rigistTimeFunc("limited_wudaohui_start",function()   
            if gameTimer.times["limited_wudaohui_start"] >= 0 then

                ui.setLabelString(self.rootItems.wudaohuitimeLb,"结束倒计时:",14,30)
                ui.setLabelString(self.rootItems.wudaohuitime,ui.makeTimeText(gameTimer.times["limited_wudaohui_start"],"hour"),24,30)

            end
            if gameTimer.times["limited_wudaohui_start"] == 0 then
                gameTimer:UnrigistTimeFunc("limited_wudaohui_start")
                self:wudaohuiUpdatetime()
            end
        end)
    elseif self:gettimenum(self.endtimenum) <= alltimes and alltimes < self:gettimenum(self.finaltimenum) then
        print("4444444")
        GameScene.layers["main"].module.isout = false

        remaintime = self:gettimenum(self.finaltimenum) - alltimes

        gameTimer:rigistTime("limited_wudaohui_rewards", remaintime)
        gameTimer:rigistTimeFunc("limited_wudaohui_rewards",function()
            if gameTimer.times["limited_wudaohui_rewards"] >= 0 then
                ui.setLabelString(self.rootItems.wudaohuitimeLb,"",14,30)
                ui.setLabelString(self.rootItems.wudaohuitime,"",24,30)

                --ui.setLabelString(self.rootItems.wudaohuitime,"待关闭:"..ui.makeTimeText(gameTimer.times["limited_wudaohui_rewards"],"minute"),26)
            end
            if gameTimer.times["limited_wudaohui_rewards"] == 0 then
                gameTimer:UnrigistTimeFunc("limited_wudaohui_rewards")
                self:wudaohuiUpdatetime()
            end
        end)
    else
        print("活动结束活动结束活动结束活动结束===")
        GameScene.layers["main"].module.isout = true
        ui.setLabelString(self.rootItems.wudaohuitimeLb,"",14,30)
        ui.setLabelString(self.rootItems.wudaohuitime,"",24,30)
    end
end

function limitedset.setWudaohuiHint(self,data)
    
    ui.sethint(self.rootItems.hint_wudaohui,false)

    local globalconfig = gamedata.config:getConfigByName("global_kv")
    local fightnum = (globalconfig.wudao_challenge_times and globalconfig.wudao_challenge_times.value or 0) - data.fightnum

    if (not GameScene.layers["main"].module.isout) and (fightnum > 0) then
        ui.sethint(self.rootItems.hint_wudaohui,true)
    end

    if data.rewardstatue1 == 1 or data.rewardstatue2 == 1 or data.rewardstatue3 == 1 then
        ui.sethint(self.rootItems.hint_wudaohui,true)
    end

end

function limitedset.betCup(self)

    -- UIRequest({type = 2102})
    --杯赛押注
    self.rootItems.cupbtn:setSwallowsTouch(true)
    self.rootItems.cupbtn:setTouchPriority(self.buttontouch)
    self.rootItems.cupbtn:addHandleOfControlEvent(function()

        self:skipEffect(5,function (  )
            if not GameScene:checkopenlevelbyId(27) then
                return
            end
            GameScene:shiftLayer("cup","up",{page = "tops"})
        end)
        
    end, CCControlEventTouchUpInside) 

    if not GameScene:checkopenlevelbyId(27,true) then
        return
    end
    
    local now = os.date("*t", gamedata:time())
    if now.hour >= 16 then
        self.topspage = 3
    elseif now.hour >= 14 then
        self.topspage = 2
    else
        self.topspage = 1
    end   

    local bettime = 0
    local bettimestr = ""
    local title = ""
    local now = os.date("*t", gamedata:time())
    if self.topspage == 3 and now.hour >= 16 and now.hour < 19 then
        bettime = 19*3600-now.hour*3600-now.min*60-now.sec
        title = ""
        bettimestr = "决赛倒计时:"
    elseif self.topspage == 2 and now.hour >= 14 and now.hour < 16 then
        bettime = 16*3600-now.hour*3600-now.min*60-now.sec
        title = ""
        bettimestr = "四进二倒计时:"
    elseif self.topspage == 1 and now.hour >= 12 and now.hour < 14 then
        bettime = 14*3600-now.hour*3600-now.min*60-now.sec
        title = ""
        bettimestr = "八进四倒计时:"
    end

    
    if bettime > 0 then
        self.betIsOut = false
        ui.setLabelString(self.rootItems.betProgress,title,14,30)
        ui.setLabelString(self.rootItems.bettimeLb,bettimestr,14,30)

        gameTimer:rigistTime("limited_cup_bettime",bettime)
        if gameTimer.times["limited_cup_bettime"] and gameTimer.times["limited_cup_bettime"] > 0 then
            gameTimer:rigistTimeFunc("limited_cup_bettime", function()
                

                if gameTimer.times["limited_cup_bettime"] <= 0 then

                    ui.setLabelString(self.rootItems.betProgress,"",14,30)
                    ui.setLabelString(self.rootItems.bettimeLb,"",14,30)
                    ui.setLabelString(self.rootItems.bettime,"",24,30)

                    if gameTimer.times["limited_cup_bettime"] then
                        gameTimer:UnrigistTimeFunc("limited_cup_bettime")
                    end
                    self.betIsOut = true
                else
                    self.betIsOut = false
                    ui.setLabelString(self.rootItems.bettime,ui.makeTimeDayText(gameTimer.times["limited_cup_bettime"],"hour"),24,30)
                end
            end)
        end
    else
        self.betIsOut = true
        ui.setLabelString(self.rootItems.betProgress,"",14,30)
        ui.setLabelString(self.rootItems.bettimeLb,"",14,30)
        ui.setLabelString(self.rootItems.bettime,"",14,30)
    end       
end


function limitedset.setCupHint(self,data)

    print("setCupHint",self.betIsOut,data.betnum)
    ui.sethint(self.rootItems.hint_cup,false)
    if data.betnum < 3 and (not self.betIsOut) then
        ui.sethint(self.rootItems.hint_cup,true)
    end
end



function limitedset.goServiceWar(self)

    
    gameTouch:clickprofbytime(0.5)
    local scaleto1 = CCScaleTo:create(0.15, 1.2)
    local scaleto2 = CCScaleTo:create(0.15, 1)

    local action1 = CCSequence:createWithTwoActions(CCDelayTime:create(0.3), CCCallFunc:create(function()
        if gamedata.config:getConfigByName("build")[tostring(212)] and gamedata.config:getConfigByName("build")[tostring(212)].switch and gamedata.config:getConfigByName("build")[tostring(212)].switch == 1 then
            UIRequest({type = 4702,param =  "goto"})
        else
            runGamePrompt({msg = "敬请期待"})
        end
    end))

    local action2 = CCSequence:createWithTwoActions(CCEaseBackOut:create(scaleto1),CCEaseBackOut:create(scaleto2))
    local action3 = CCSpawn:createWithTwoActions(action1,action2)

    self.rootItems["servicewarBg"]:setScale(1)
    self.rootItems["servicewarBg"]:runAction(action3)
end

function limitedset.serviceWar(self)
    ui.setLabelString(self.rootItems.servicewartimeLb,"",14,30)
    ui.setLabelString(self.rootItems.servicewartime,"",24,30)

    setSpriteFrameByName(self.rootItems.icon_servicewar,"renbang")

    if gamedata.config:getConfigByName("build")[tostring(212)] and gamedata.config:getConfigByName("build")[tostring(212)].switch and gamedata.config:getConfigByName("build")[tostring(212)].switch == 1 then
        self.rootItems.timeNode1:setVisible(true)
        self.rootItems.noOpen1:setVisible(false)
        ui.removeGray("CCSprite",self.rootItems.servicewarBg)
    else
        self.rootItems.timeNode1:setVisible(false)
        self.rootItems.noOpen1:setVisible(true)
        ui.addGray("CCSprite",self.rootItems.servicewarBg)
        return
    end

    UIRequest({type = 4702})    --请求icon
    
end

function limitedset.goHonorBattle(self)

    gameTouch:clickprofbytime(0.5)
    local scaleto1 = CCScaleTo:create(0.15, 1.2)
    local scaleto2 = CCScaleTo:create(0.15, 1)

    local action1 = CCSequence:createWithTwoActions(CCDelayTime:create(0.3), CCCallFunc:create(function()
        if gamedata.config:getConfigByName("build")[tostring(381)] and gamedata.config:getConfigByName("build")[tostring(381)].switch and gamedata.config:getConfigByName("build")[tostring(381)].switch == 1 then
            GameScene:shiftLayer("honorBattle","up")
        else
            runGamePrompt({msg = "敬请期待"})
        end
    end))

    local action2 = CCSequence:createWithTwoActions(CCEaseBackOut:create(scaleto1),CCEaseBackOut:create(scaleto2))
    local action3 = CCSpawn:createWithTwoActions(action1,action2)

    self.rootItems["honorBattleBg"]:setScale(1)
    self.rootItems["honorBattleBg"]:runAction(action3)
    
    
end

function limitedset.honorBattle(self)
    self.rootItems.des2_1:setVisible(false)
    ui.setLabelString(self.rootItems.honorBattletimeLb,"",14,30)
    ui.setLabelString(self.rootItems.honorBattletime,"",24,30)

    --巅峰对决
    setSpriteFrameByName(self.rootItems.icon_honorbattle,"ryzzbang_tianshu")


    if gamedata.config:getConfigByName("build")[tostring(381)] and gamedata.config:getConfigByName("build")[tostring(381)].switch and gamedata.config:getConfigByName("build")[tostring(381)].switch == 1 then
        self.rootItems.timeNode2:setVisible(true)
        self.rootItems.noOpen2:setVisible(false)
        ui.removeGray("CCSprite",self.rootItems.honorBattleBg)
    else
        self.rootItems.timeNode2:setVisible(false)
        self.rootItems.noOpen2:setVisible(true)
        ui.addGray("CCSprite",self.rootItems.honorBattleBg)
        return
    end

    UIRequest({type = 6503})    --请求icon
    local honor_battle_timeconfig = gamedata.config:getConfigByName("glory_battle_time")
    gameTimer:rigistTime("limited_honorbattlebegintimer",99999)
    gameTimer:rigistTimeFunc("limited_honorbattlebegintimer",function()
        local nowtime = os.date("*t", gamedata:time())
        local daynums = (nowtime.wday == 1 and 7 or (nowtime.wday-1))
        local alltimes = (daynums-1)*24*3600 + nowtime.hour*3600 + nowtime.min*60 + nowtime.sec - 1

        local servertime = GameScene.roleinfo.servertime
        local servertimeT =  os.date("*t", servertime)
        local startTime = servertime - servertimeT.hour * 3600 - servertimeT.min * 60 - servertimeT.sec

        if gamedata:time() - startTime < 11*86400 then
            --未开启
            self.rootItems.des2_1:setVisible(true)
            ui.removeGray("CCSprite",self.rootItems.honorBattleBg)
            local endtime = 11*86400 - (gamedata:time() - startTime)
            ui.setLabelString(self.rootItems.honorBattletimeLb,"开启倒计时:",14,30)
            ui.setLabelString(self.rootItems.honorBattletime,ui.makeTimeDayText(endtime,"day"),24,30)

            ui.labelFollow(self.rootItems.honorBattletimeLb,self.rootItems.honorBattletime)
        else
            self.rootItems.des2_1:setVisible(false)
            
            for i=1, #self.honorbattleconfig do
                local config1 = honor_battle_timeconfig[tostring(self.honorbattleconfig[i][1])]
                local config2 = honor_battle_timeconfig[tostring(self.honorbattleconfig[i][2])]
                local hour1,min1,sec1 = ui.getGangBattleTime(config1["open_time"])
                local hour2,min2,sec2 = ui.getGangBattleTime(config2["over_time"])
                self.beginhonortime = {week=config1["open_week"], hour=hour1, min=min1, sec=sec1}
                self.endhonortime = {week=config2["over_week"], hour=hour2, min=min2, sec=sec2}
            
                if (self:gettimenum(self.beginhonortime) <= alltimes and alltimes < self:gettimenum(self.endhonortime)) then

                    ui.setLabelString(self.rootItems.honorBattletimeLb,"巅峰对决"..config1["name"]..":",14,30)
                    ui.setLabelString(self.rootItems.honorBattletime,ui.makeTimeDayText(self:gettimenum(self.endhonortime) - alltimes,"day"),24,30)
                    ui.labelFollow(self.rootItems.honorBattletimeLb,self.rootItems.honorBattletime)
                    break
                end
            end
        end
        

        if gameTimer.times["limited_honorbattlebegintimer"] <= 0 then
            gameTimer:rigistTime("limited_honorbattlebegintimer",99999)
        end
    end)    
    
end

function limitedset.updateServiceIcon(self, data)
    local worldwarstatus = {}
    if data and data.worldwarstatus then
        worldwarstatus = data.worldwarstatus or {}
    end

    if worldwarstatus.list == 1 then
        setSpriteFrameByName(self.rootItems.icon_servicewar,"renbang")
    elseif worldwarstatus.list == 2 then
        setSpriteFrameByName(self.rootItems.icon_servicewar,"dibang")
    elseif worldwarstatus.list == 3 then
        setSpriteFrameByName(self.rootItems.icon_servicewar,"tianbang")
    elseif worldwarstatus.list == 4 then
        setSpriteFrameByName(self.rootItems.icon_servicewar,"xianbang")
    elseif worldwarstatus.list == 5 then
        setSpriteFrameByName(self.rootItems.icon_servicewar,"shenbang")
    end

    local cross_battle_timeconfig = gamedata.config:getConfigByName("cross_battle_time")
    gameTimer:rigistTime("limited_servicewarbegintimer",99999)
    gameTimer:rigistTimeFunc("limited_servicewarbegintimer",function()
        local nowtime = os.date("*t", gamedata:time())
        local daynums = (nowtime.wday == 1 and 7 or (nowtime.wday-1))
        local alltimes = (daynums-1)*24*3600 + nowtime.hour*3600 + nowtime.min*60 + nowtime.sec - 1
        
        local servertime = GameScene.roleinfo.servertime
        local servertimeT =  os.date("*t", servertime)
        local startTime = servertime - servertimeT.hour * 3600 - servertimeT.min * 60 - servertimeT.sec
        
        if gamedata:time() - startTime < 7*86400 then
            --未开启
            self.rootItems.des1_1:setVisible(true)
            
            local endtime = 7*86400 - (gamedata:time() - startTime)
            ui.setLabelString(self.rootItems.servicewartimeLb,"开启倒计时:",14,30)
            ui.setLabelString(self.rootItems.servicewartime,ui.makeTimeDayText(endtime,"day"),24,30)
        else
            --开服7天后已开启
            self.rootItems.des1_1:setVisible(false)
            local servicewarconfig = self.servicewarconfig
            if  worldwarstatus.s_open and worldwarstatus.s_open == 1 then
                servicewarconfig = self.servicewarconfig_shenbang
                cross_battle_timeconfig = gamedata.config.cross_battle_champion_time
            end
            for i=1, #servicewarconfig do
                local config1 = cross_battle_timeconfig[tostring(servicewarconfig[i][1])]
                local config2 = cross_battle_timeconfig[tostring(servicewarconfig[i][2])]
                local hour1,min1,sec1 = ui.getGangBattleTime(config1["open_time"])
                local hour2,min2,sec2 = ui.getGangBattleTime(config2["over_time"])
                self.begintime = {week=config1["open_week"], hour=hour1, min=min1, sec=sec1}
                self.endtime = {week=config2["over_week"], hour=hour2, min=min2, sec=sec2}

                if (self:gettimenum(self.begintime) <= alltimes and alltimes < self:gettimenum(self.endtime)) then

                    ui.setLabelString(self.rootItems.servicewartimeLb,"跨服战"..config1["name"]..":",14,30)
                    ui.setLabelString(self.rootItems.servicewartime,ui.makeTimeDayText(self:gettimenum(self.endtime) - alltimes,"day"),24,30)

                    break
                end
            end

        end

        if gameTimer.times["limited_servicewarbegintimer"] <= 0 then
            gameTimer:rigistTime("limited_servicewarbegintimer",99999)
        end
    end)   
end

function limitedset.updateHonorIcon(self, data)
    local wardata = {}
    if data and data.HonorWarStatus then
        wardata = data.HonorWarStatus
    end

    if wardata.list > 0 and wardata.status > 0 then
        local intervalConfig = gamedata.config:getConfigByName("glory_battle_interval")
        local _iconName = intervalConfig[tostring(wardata.list)].icon
        setSpriteFrameByName(self.rootItems.icon_honorbattle, _iconName)
    else
        if wardata.list > 0 then
            ui.setLabelString(self.rootItems.des2_1,"新一届巅峰对决准备中",14,30)
        else
            ui.setLabelString(self.rootItems.des2_1,"开服11天内不能参加巅峰对决",14,30)
        end
        setSpriteFrameByName(self.rootItems.icon_honorbattle,"ryzzbang_tianshu")
    end 
end

function limitedset.updateGodCompettionIcon(self, data)
    local wardata = {}
    if data and data.godStatus then
        wardata = data.godStatus
    end

    self.godStatus = wardata.status

    if wardata.group > 0 and wardata.status > 0 then
        local intervalConfig = gamedata.config.apex_battle_interval
        local _iconName = intervalConfig[tostring(wardata.group)].icon
        self.rootItems.icon_godcomtition:setVisible(true)
        setSpriteFrameByName(self.rootItems.icon_godcomtition, _iconName)
    else
        if wardata.group > 0 then
            ui.setLabelString(self.rootItems.des_godcom,"新一届封神赛准备中",14,30)
        else
            local day = gamedata.config.apex_battle_interval["1"].start_limit
            ui.setLabelString(self.rootItems.des_godcom,"开服天数≥"..day.."天开启封神赛",14,30)
        end
        -- setSpriteFrameByName(self.rootItems.icon_godcomtition,"ryzzbang_tianshu")
        self.rootItems.icon_godcomtition:setVisible(false)
    end 
end

function limitedset.addeffectLayer(self)
    self.effectLayer = CCLayer:create()
    self.rootNode:addChild(self.effectLayer)

    local function ccTouchBegan(x, y, pTouch)
        print("effectLayer touched")
        -- if not self.tishianimationManager then
        --     self.tishiNode,self.tishiitem = CCBReaderLoad("UIEffect/xinshouyindao/xinshouyindao_tishi.ccbi", nil, true, "xinshouyindao_tishi")
        --     self.effectLayer:addChild(self.tishiNode)
        --     self.tishiNode:setScale(0.5)
        --     self.tishianimationManager = getAnimationManager(self.tishiitem)
        -- end
        -- local point = pTouch:getLocation()
        -- self.tishiNode:setPosition(x/gameConfig.scaleNum, y/gameConfig.scaleNum)
        -- self.tishianimationManager:runAnimationsForSequenceNamed("focus")
        
        return true
    end

    local function ccTouchMoved(x, y, pTouch)
    end

    local function ccTouchEnded(x, y, pTouch)

        local originx = 0
        local originy = gameConfig.topposY - 600

        local touchX = x/gameConfig.scaleNum
        local touchY = y/gameConfig.scaleNum - originy

        local maxY = 600/1080*(1080 - touchX)

        if touchY > 0 then
            if touchY < maxY then
                self:goHonorBattle()
            else
                self:goServiceWar()
            end
        end
    end

    local function onTouch(eventType, x, y, pTouch)
        if eventType == "began" then
            return ccTouchBegan(x, y, pTouch)
        elseif eventType == "moved" then
            return ccTouchMoved(x, y, pTouch)
        elseif eventType == "ended" then
            return ccTouchEnded(x, y, pTouch)
        end
    end

    self.effectLayer:registerScriptTouchHandler(onTouch, false, gameConfig.touchPriority.guide, false)
    self.effectLayer:setTouchPriority(gameConfig.touchPriority.guide)
    self.effectLayer:setTouchEnabled(true)
end

function limitedset.godCompetitionMain(self)
    --封神赛
    self.rootItems.des_godcom:setVisible(false)
    ui.setLabelString(self.rootItems.godcomtition_timeLb,"",14,30)
    ui.setLabelString(self.rootItems.godcomtition_time,"",24,30)

    -- setSpriteFrameByName(self.rootItems.icon_godcomtition,"ryzzbang_tianshu")
    if gamedata.config.build[tostring(634)] then
        local bconfig = gamedata.config.build[tostring(634)]
        printT(bconfig,"jkp-bconfig")
        if bconfig and bconfig.switch == 1 and GameScene.roleinfo.level >= bconfig.level then
            self.rootItems.timeNode_godcom:setVisible(true)
            -- ui.removeGray("CCSprite",self.rootItems.godcomtitionBg)
        else
            self.rootItems.timeNode_godcom:setVisible(false)
            -- ui.addGray("CCSprite",self.rootItems.godcomtitionBg)
            return
        end
    end

    --设置数据
    UIRequest({type = 8251}) 
    local apex_battle_time = gamedata.config.apex_battle_time
    local intervalConfig = gamedata.config.apex_battle_interval
    gameTimer:rigistTime("limited_godcomtitionbegintimer",99999)
    gameTimer:rigistTimeFunc("limited_godcomtitionbegintimer",function()
        local nowtime = os.date("*t", gamedata:time())
        local daynums = (nowtime.wday == 1 and 7 or (nowtime.wday-1))
        local alltimes = (daynums-1)*24*3600 + nowtime.hour*3600 + nowtime.min*60 + nowtime.sec - 1

        local servertime = GameScene.roleinfo.servertime
        local servertimeT = os.date("*t", servertime)
        local startTime = servertime - servertimeT.hour * 3600 - servertimeT.min * 60 - servertimeT.sec
        print("time = ",gamedata:time() - startTime,intervalConfig["1"].start_limit*86400)

        if gamedata:time() - startTime < intervalConfig["1"].start_limit*86400 then
            print("未开启")
            self.rootItems.des_godcom:setVisible(true)
            ui.removeGray("CCSprite",self.rootItems.godcomtitionBg)
            local endtime = intervalConfig["1"].start_limit*86400 - (gamedata:time() - startTime)
            ui.setLabelString(self.rootItems.godcomtition_timeLb,"封神赛开启倒计时:",14,30)
            ui.setLabelString(self.rootItems.godcomtition_time,ui.makeTimeDayText(endtime,"day"),24,30)

            ui.labelFollow(self.rootItems.godcomtition_timeLb,self.rootItems.godcomtition_time)
        else
            self.rootItems.des_godcom:setVisible(false)
            for i=1, #self.competitionconfig do
                if self.godStatus >= self.competitionconfig[i][1] and self.godStatus <= self.competitionconfig[i][2] then
                    
                    local config1 = apex_battle_time[tostring(self.competitionconfig[i][1])]
                    local config2 = apex_battle_time[tostring(self.competitionconfig[i][2])]
                    ui.setLabelString(self.rootItems.godcomtition_timeLb,"封神赛"..config1["name"]..":",14,30)
                    if self.godStatus == 1 or self.godStatus == 71 then
                        local bwday = apex_battle_time[tostring(self.godStatus)].over_week+1
                        if bwday > 7 then bwday = 1 end
                        local hour,min,sec = ui.getGangBattleTime(apex_battle_time[tostring(self.godStatus)].over_time)
                        local diff = (bwday-nowtime.wday)*86400+(hour-nowtime.hour)*3600+(min-nowtime.min)*60+sec-nowtime.sec
                        if diff < 0 then diff = diff+86400*7 end
                        print("jkp-diff = ",diff)
                        ui.setLabelString(self.rootItems.godcomtition_time,ui.makeTimeDayText(diff,"day"),24,30)
                        if diff <= 0 then
                            UIRequest({type = 8251})
                        end
                    else
                        local hour1,min1,sec1 = ui.getGangBattleTime(config1["open_time"])
                        local hour2,min2,sec2 = ui.getGangBattleTime(config2["over_time"])
                        self.begingodcomtime = {week=config1["open_week"], hour=hour1, min=min1, sec=sec1}
                        self.endgodcomtime = {week=config2["over_week"], hour=hour2, min=min2, sec=sec2} 
                        ui.setLabelString(self.rootItems.godcomtition_time,ui.makeTimeDayText(self:gettimenum(self.endgodcomtime) - alltimes,"day"),24,30)
                        print("jkp-time = ",self:gettimenum(self.endgodcomtime) - alltimes)
                        if (self:gettimenum(self.endgodcomtime) - alltimes) <= 0 then
                            UIRequest({type = 8251})
                        end
                    end
                    ui.labelFollow(self.rootItems.godcomtition_timeLb,self.rootItems.godcomtition_time)

                    break
                end
            end

            if self.godStatus == -1 then
                local config1 = apex_battle_time[tostring(self.competitionconfig[1][1])]
                local config2 = apex_battle_time[tostring(self.competitionconfig[1][2])]
                local hour1,min1,sec1 = ui.getGangBattleTime(config1["open_time"])
                local hour2,min2,sec2 = ui.getGangBattleTime(config2["over_time"])
                self.begingodcomtime = {week=config1["open_week"], hour=hour1, min=min1, sec=sec1}
                self.endgodcomtime = {week=config2["over_week"], hour=hour2, min=min2, sec=sec2}

                ui.setLabelString(self.rootItems.godcomtition_timeLb,"封神赛开启倒计时:",14,30)
                ui.setLabelString(self.rootItems.godcomtition_time,ui.makeTimeDayText(self:gettimenum(self.endgodcomtime) - alltimes,"day"),24,30)
                ui.labelFollow(self.rootItems.godcomtition_timeLb,self.rootItems.godcomtition_time)
                
                print("jkp-time2 = ",self:gettimenum(self.endgodcomtime) - alltimes)
                if (self:gettimenum(self.endgodcomtime) - alltimes) <= 0 then
                    UIRequest({type = 8251})
                end
            end
        end
        
        if gameTimer.times["limited_godcomtitionbegintimer"] <= 0 then
            gameTimer:rigistTime("limited_godcomtitionbegintimer",99999)
        end
    end)    
    
    --封神赛按钮
    self.rootItems.godCompetitionbtn:setSwallowsTouch(true)
    self.rootItems.godCompetitionbtn:setTouchPriority(self.buttontouch)
    self.rootItems.godCompetitionbtn:addHandleOfControlEvent(function()

        self:skipEffect(9,function ( )
            GameScene:shiftLayer("godCompetitionMain","up")
        end)

    end, CCControlEventTouchUpInside)  
end

function limitedset.clear(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.effectLayer = nil
    self.tishianimationManager = nil
    gameTimer:UnrigistTimeFunc("limited_bossbegintimer")

    gameTimer:UnrigistTimeFunc("limited_examination_main_flesh")
    gameTimer:UnrigistTimeFunc("limited_examination_reading")
    gameTimer:UnrigistTimeFunc("limited_examination_start")
    gameTimer:UnrigistTimeFunc("limited_examination_rewards")

    gameTimer:UnrigistTimeFunc("limited_daoguan_main_flesh")
    gameTimer:UnrigistTimeFunc("limited_daoguan_reading")
    gameTimer:UnrigistTimeFunc("limited_daoguan_start")
    gameTimer:UnrigistTimeFunc("limited_daoguan_rewards")

    gameTimer:UnrigistTimeFunc("limited_guildwarbegintimer")

    gameTimer:UnrigistTimeFunc("limited_wudaohui_main_flesh")
    gameTimer:UnrigistTimeFunc("limited_wudaohui_reading")
    gameTimer:UnrigistTimeFunc("limited_wudaohui_start")
    gameTimer:UnrigistTimeFunc("limited_wudaohui_rewards")

    gameTimer:UnrigistTimeFunc("limited_servicewarbegintimer")
    gameTimer:UnrigistTimeFunc("limited_honorbattlebegintimer")

    gameTimer:UnrigistTimeFunc("limited_cup_bettime")

    gameTimer:UnrigistTimeFunc("limited_godcomtitionbegintimer")

    self.godStatus = 0
    
end

function limitedset.initFixedString(self)
    ui.setLabelString(self.rootItems.noOpen1,nil,24,30)
    ui.setLabelString(self.rootItems.noOpen2,nil,24,30)

    ui.setLabelString(self.rootItems.des1_1,nil,14,30)
    ui.setLabelString(self.rootItems.des2_1,nil,14,30)


    ui.setLabelString(self.rootItems.des3_1,nil,14,30)
    ui.setLabelString(self.rootItems.des3_2,nil,23,30)
    ui.setLabelString(self.rootItems.des3_3,nil,23,30)
    ui.setLabelString(self.rootItems.des3_4,nil,14,30)

    ui.setLabelString(self.rootItems.des4_1,nil,14,30)
    ui.setLabelString(self.rootItems.des4_2,nil,23,30)
    ui.setLabelString(self.rootItems.des4_3,nil,23,30)
    ui.setLabelString(self.rootItems.des4_4,nil,14,30)

    ui.setLabelString(self.rootItems.des5_1,nil,14,30)
    ui.setLabelString(self.rootItems.des5_2,nil,23,30)
    ui.setLabelString(self.rootItems.des5_3,nil,14,30)

    ui.setLabelString(self.rootItems.des6_1,nil,14,30)
    ui.setLabelString(self.rootItems.des6_2,nil,23,30)
    ui.setLabelString(self.rootItems.des6_3,nil,14,30)
    ui.setLabelString(self.rootItems.des6_4,nil,23,30)
    ui.setLabelString(self.rootItems.des6_5,nil,14,30)
    ui.setLabelString(self.rootItems.des6_6,nil,23,30)
    ui.setLabelString(self.rootItems.des6_7,nil,14,30)
    ui.setLabelString(self.rootItems.des6_8,nil,23,30)

    ui.setLabelString(self.rootItems.des7_1,nil,14,30)
    ui.setLabelString(self.rootItems.des7_2,nil,23,30)
    ui.setLabelString(self.rootItems.des7_3,nil,14,30)

    ui.setLabelString(self.rootItems.des8_1,nil,14,30)
    ui.setLabelString(self.rootItems.des8_2,nil,14,30)
    ui.setLabelString(self.rootItems.des8_3,nil,23,30)
    ui.setLabelString(self.rootItems.des8_4,nil,14,30)
    ui.setLabelString(self.rootItems.des8_5,nil,14,30)
    ui.setLabelString(self.rootItems.des8_6,nil,14,30)
    ui.setLabelString(self.rootItems.des8_7,nil,23,30)
    ui.setLabelString(self.rootItems.des8_8,nil,14,30)
end

return limitedset
( 