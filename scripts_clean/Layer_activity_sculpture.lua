--
-- Author: songyibo
-- Date: 2021-03-01 10:51:19
--

local sculpture = {
    touchPriority = -103,

    rewardCellSize = {x=1080,y=224},
    taskCellSize = {x=1080,y=224},
    shopCellSize = {x=1080,y=330},

    --标签显示
    pageconfig = {"reward","daily","challenge","shop"},
    pagename = {gameConfig.strings:string_common("sculpture",1),gameConfig.strings:string_common("sculpture",2),gameConfig.strings:string_common("sculpture",3),gameConfig.strings:string_common("sculpture",4)},
    selectpage = "reward",

    listTableView_reward        = nil,
    listTableView_daily         = nil,
    listTableView_challenge     = nil,
    listTableView_shop          = nil,

    ranklist                    = nil,
}

--成长计划的初始化
function sculpture.init(self,size)
    self.contentsize = size
    self.show = true
    self.cpnum = GameScene.layers["activity"].module.dailyCpActivityTimeStatus[180].cpnum or 1
    self.cpday = GameScene.layers["activity"].module.dailyCpActivityTimeStatus[180].cpday or 1

    self:initUI()
    self:shiftShow("activity")


    self.rootItems.rewardscroll:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-160-780))
    self.rootItems.dailyscroll:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-160-780))
    self.rootItems.challengescroll:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-160-780))
    self.rootItems.shopscroll:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-160-780))

    self.rewardConfig       = gamedata.config["sculpture_dividend_reward_"..self.cpnum]
    self.dailyConfig        = gamedata.config["sculpture_dividend_daily_task_"..self.cpnum]
    self.challengeConfig    = gamedata.config["sculpture_dividend_challenge_task_"..self.cpnum]
    self.shopConfig         = gamedata.config["sculpture_dividend_shop_"..self.cpnum]

    self:restData()
    -- self:reloaddata()
    return self.rootNode
end

function sculpture.restData(self)
    self.firstreload = true
    local t = {
        active          = 0,        --激活状态
        level           = 1,
        exp             = 0,
        picId           = 1,
        reward          = {},
        daily           = {},
        challenge       = {},
        shop            = {},
    }

    for i=1,table.getTableLength(self.rewardConfig) do
        if self.rewardConfig[tostring(i)].reward ~= "" then
            table.insert(t.reward,{level = i,status = 0})
        end
    end

    for i=1,table.getTableLength(self.dailyConfig) do
        table.insert(t.daily,{id = i,status = 0,now = 0})
    end

    for i=1,table.getTableLength(self.challengeConfig) do
        table.insert(t.challenge,{id = i,status = 0,now = 0})
    end

    for i=1,table.getTableLength(self.shopConfig) do
        table.insert(t.shop,{id = i,num = 0})
    end

    self.data = t
end

function sculpture.initUI(self)
    self.rootNode, self.rootItems = CCBReaderLoad("activityreward_new/diaosuhongli",nil, true, "diaosuhongli")
    self.rootItems.topnode:setPositionY(self.contentsize.y-180)
    self.rootItems.ranktopnode:setPositionY(self.contentsize.y-180)
    --显示页签得按钮
    for k=1,4 do
        self.rootItems["planbutton"..k]:setSwallowsTouch(true)
        self.rootItems["planbutton"..k]:setTouchPriority(self.touchPriority - 3)
        self.rootItems["planbutton"..k]:addHandleOfControlEvent(function()
            self:shiftPage(self.pageconfig[k])
        end,CCControlEventTouchUpInside)
    end

    self.rootItems.barsprite:removeFromParentAndCleanup(false)
    self.rootItems.expbar = CCProgressTimer:create(self.rootItems.barsprite)
    self.rootItems.expbar:setAnchorPoint(ccp(0.5, 0.5))
    self.rootItems.expbar:setType(kCCProgressTimerTypeBar)
    self.rootItems.expbar:setMidpoint(ccp(0, 0.5))
    self.rootItems.expbar:setBarChangeRate(ccp(1, 0))
    self.rootItems.expbar:setPercentage(0)
    self.rootItems.barnode:addChild(self.rootItems.expbar)

    
    self.rootItems.swallowbtn:setSwallowsTouch(true)
    self.rootItems.swallowbtn:setTouchPriority(self.touchPriority - 2)
    self.rootItems.swallowbtn:addHandleOfControlEvent(function()
    end, CCControlEventTouchUpInside)

    self.rootItems.btnRank:setTouchPriority(self.touchPriority - 2)
    self.rootItems.btnRank:addHandleOfControlEvent(function()
        self:shiftShow("rank")
        UIRequest({type = 8133})
    end, CCControlEventTouchUpInside)

    self.rootItems.common_back_btn:setTouchPriority(self.touchPriority - 2)
    self.rootItems.common_back_btn:addHandleOfControlEvent(function()
        self:shiftShow("activity")
    end, CCControlEventTouchUpInside)

    self:setRefreshTime()

    ui.setLabelString(self.rootItems.fixedlab,nil,1029,36)
    ui.setLabelString(self.rootItems.propNum,nil,1030,36)
end

function sculpture.getSculpturePic(picId)
    return "diaosu"..picId
end

function sculpture.reloadRank(self,ranklist)
    self.ranklist = ranklist

    for i=1,3 do
        local key_Ex
        if i == 1 then
            key_Ex = ""
        else
            key_Ex = "_"..(i - 1)
        end

        if self.ranklist[tostring(i)] then
            self.rootItems["r_none"..key_Ex]:setVisible(false)
            self.rootItems["r_pic"..key_Ex]:setVisible(true)
            setSpriteFrameByName(self.rootItems["r_pic"..key_Ex],self.getSculpturePic(self.ranklist[tostring(i)].picId))

            self.rootItems["r_name"..key_Ex]:setString(gameConfig.strings:string_common("sculpture",6)..self.ranklist[tostring(i)].name)
            local time = os.date("*t", self.ranklist[tostring(i)].time)
            self.rootItems["r_time"..key_Ex]:setString(gameConfig.strings:string_common("sculpture",7)..string.format(gameConfig.strings:string_common("sculpture",8),time.year,time.month,time.day,time.hour,time.min ))
        else
            self.rootItems["r_none"..key_Ex]:setVisible(true)
            self.rootItems["r_pic"..key_Ex]:setVisible(false)

            self.rootItems["r_name"..key_Ex]:setString(gameConfig.strings:string_common("sculpture",6).."??????")
            self.rootItems["r_time"..key_Ex]:setString(gameConfig.strings:string_common("sculpture",7).."??????")
        end

        setSpriteFrameByName(self.rootItems["r_bg"..key_Ex],"diaosuhongli_bg"..(i+4))
    end

end

function sculpture.setRefreshTime(self)
    local nowtime = os.date("*t", gamedata:time())
    local timediff = (24 - nowtime.hour - 1) * 3600 + (60 - nowtime.min - 1) * 60 + (60 - nowtime.sec)
    if timediff > 0 then
        gameTimer:rigistTime("sculptureDailyRefreshTime",timediff)
        gameTimer:rigistTimeFunc("sculptureDailyRefreshTime", function()
            if gameTimer.times["sculptureDailyRefreshTime"] <= 0 then
                gameTimer:UnrigistTimeFunc("sculptureDailyRefreshTime")
                self:setRefreshTime()
            else
                ui.setLabelString(self.rootItems.resettime,ui.makeTimeDayText(gameTimer.times["sculptureDailyRefreshTime"],"hour"),1030,29)   
            end
        end)
    else
        self:setRefreshTime()       
    end
    ui.setLabelString(self.rootItems.resetlab,nil,1029,29)
    ui.setLabelString(self.rootItems.endlab,nil,1029,36)

    local timediff = GameScene.layers["activity"].module:getActivityRemainingTime(180)
    if timediff > 0 then
        gameTimer:rigistTime("sculptureEndRefreshTime", timediff)
        gameTimer:rigistTimeFunc("sculptureEndRefreshTime",function()

            if gameTimer.times["sculptureEndRefreshTime"] <= 0 then
                gameTimer:UnrigistTimeFunc("sculptureEndRefreshTime")
                self:setRefreshTime()
            else
                ui.setLabelString(self.rootItems.endtime,ui.makeTimeDayText(gameTimer.times["sculptureEndRefreshTime"],"day"),1030,36)   
            end
        end)
    end


end

function sculpture.shiftShow(self,type)
    self.rootItems.ranknode:setPositionX(type == "rank" and 0 or 9999)
    self.rootItems.activitynode:setPositionX(type == "activity" and 0 or 9999)
    self.rootItems.ranknode:setVisible(type == "rank")
    self.rootItems.activitynode:setVisible(type == "activity")
end

--按钮高亮状态的显示
function  sculpture.shiftlayerpage(self,page)
    for km,vm in ipairs(self.pageconfig) do
        if vm == page then
            self.rootItems[vm.."scroll"]:setPositionX(0)
            self.rootItems[vm.."scroll"]:setVisible(true)
            setSpriteFrameByName(self.rootItems["btnspr"..km], gameConfig.images.pageButtonON)
        else
            self.rootItems[vm.."scroll"]:setPositionX(9999)
            self.rootItems[vm.."scroll"]:setVisible(false)
            setSpriteFrameByName(self.rootItems["btnspr"..km], gameConfig.images.pageButtonOFF)
        end
    end
    self.rootItems.timeNode:setVisible(page == "daily")
    self.rootItems.propNode:setVisible(page == "shop" and self.data.active and self.data.active == 1)
end

--选择页签按钮的修改
function sculpture.shiftPage(self,type)
    print("shiftPage",type)
    if type then
        self.selectpage = type
    end
    self:shiftlayerpage(self.selectpage)

    if self["listTableView_"..type] then
        if self["listTableView_"..type]._fresh then
            print("刷新   "..type)
            self["listTableView_"..type]._fresh = false
            self["listTableView_"..type]:reloadData()
        end
    else
        print("创建   "..type)
        self["create_list_"..type](self)
    end
end


function sculpture.makeData(self,data)
    printT(data,"makeData")
    -- data = {
    --     active          = 1,        --激活状态
    --     level           = 5,
    --     exp             = 50,
    --     picId           = 1,
    --     reward          = {
    --     },
    --     daily           = {},
    --     challenge       = {},
    --     shop            = {},
    --     props           = {}
    -- }



    -- for i=1,table.getTableLength(self.rewardConfig) do
    --     data.reward[tostring(i)] = {level = i,status = 0}
    -- end

    -- for i=1,table.getTableLength(self.dailyConfig) do
    --     data.daily[tostring(i)] = {id = i,status = 0,now = 30}
    -- end

    -- for i=1,table.getTableLength(self.challengeConfig) do
    --     data.challenge[tostring(i)] = {id = i,status = 0,now = 30}
    -- end

    -- for i=1,table.getTableLength(self.shopConfig) do
    --     data.shop[tostring(i)] = {id = i,num = 1}
    -- end

    if data.active then
        self.data.active   = data.active
    end

    if data.level then
        self.data.level    = data.level
    end

    if data.exp then
        self.data.exp      = data.exp
    end

    if data.props then
        self.data.props    = data.props
        --刷新商店
        if self["listTableView_shop"] then
            self["listTableView_shop"]._fresh = true
        end
        
    end

    if data.picId then
        self.data.picId   = data.picId
    end



    if data.reward and next(data.reward) then
        local rewardData = {}
        for i=1,table.getTableLength(data.reward) do
            local level = data.reward[tostring(i)].level
            if self.rewardConfig[tostring(level)] and self.rewardConfig[tostring(level)].reward ~= "" then
                table.insert(rewardData,data.reward[tostring(i)])
            end
        end

        local sortfunc = function (a,b)
            if a.status == b.status then
                return a.level < b.level
            elseif a.status == 1 and b.status ~= 1 then
                return true
            elseif a.status ~= 1 and b.status == 1 then
                return false
            else
                return a.status < b.status
            end
        end
        table.sort(rewardData,sortfunc)
        self.data.reward = rewardData
    end


    if data.daily and next(data.daily) then
        local dailyData = {}
        for i=1,table.getTableLength(data.daily) do
            local v = data.daily[tostring(i)]
            if self.dailyConfig[tostring(v.id)] then
                v.order = self.dailyConfig[tostring(v.id)].order
                table.insert(dailyData,v)
            end
            
            table.sort(dailyData,function ( a,b)
                return a.order < b.order
            end)
            self.data.daily = dailyData
        end
    end


    if data.challenge and next(data.challenge) then
        local challengeData = {}
        for i=1,table.getTableLength(data.challenge) do
            local v = data.challenge[tostring(i)]
            if self.challengeConfig[tostring(v.id)] then
                v.order = self.challengeConfig[tostring(v.id)].order
                table.insert(challengeData,v)
            end
            
            local sortfunc = function (a,b)
                if a.status == b.status then
                    return a.order < b.order
                elseif a.status == 1 and b.status ~= 1 then
                    return true
                elseif a.status ~= 1 and b.status == 1 then
                    return false
                else
                    return a.status < b.status
                end
            end
            table.sort(challengeData,sortfunc)
            self.data.challenge = challengeData
        end
    end

    if data.shop and next(data.shop) then
        local shopData = {}
        for i=1,table.getTableLength(data.shop) do
            local v = data.shop[tostring(i)]
            if self.shopConfig[tostring(v.id)] then
                v.order = self.shopConfig[tostring(v.id)].order
                table.insert(shopData,v)
            end
        end

        table.sort(shopData,function ( a,b)
            return a.order < b.order
        end)
        self.data.shop = shopData
    end

    printT(self.data,"makeData")

end

function sculpture.reloaddata(self,data,method)
    if not self.show then return end

    for km,vm in ipairs(self.pageconfig) do
        if data[vm] and self["listTableView_"..vm] then
            self["listTableView_"..vm]._fresh = true
        end
    end
    
    local islevelup = false
    local issculpture = false
    local issculpturechange = false
    local olddata = nil
    if not self.firstreload then
        olddata = table.copy(self.data)
    end

    self:makeData(data)
    if olddata then

        if self.data.level > olddata.level then
            islevelup = true
        end

        if self.data.exp ~= olddata.exp or self.data.level ~= olddata.level then
            issculpture = true
        end

        if self.data.picId ~= olddata.picId then
            issculpturechange = true
        end
        print("reloaddata",islevelup,issculpture,issculpturechange)
    end

    if issculpture then
        self:addSculptureAni(issculpturechange)
    else
        self:refreshUI()
    end
    
    self:refreshExp(islevelup)
    self:shiftPage(self.selectpage)
    self:reloadHint()
    self.firstreload = false
end


function sculpture.addSculptureAni(self,issculpturechange)

    local cb = function (  )
        self:refreshUI()
    end

    if issculpturechange then
        gameTouch:clickprofbytime(2)
        ui.addEffectAutoRemove(self.rootItems.animationnode,"UIEffect/diaosueffect/diaosutexiao_dadzao","play")
        ui.addEffectAutoRemove(self.rootItems.animationnode,"UIEffect/diaosueffect/diaosutexiao_up","play",cb)
    else
        ui.addEffectAutoRemove(self.rootItems.animationnode,"UIEffect/diaosueffect/diaosutexiao_dadzao","play",cb)
    end
end

function sculpture.reloadHint(self)
        
    ui.sethint(self.rootItems.hint1,false)
    for i,v in ipairs(self.data.reward) do
        if v.status == 1 then
            ui.sethint(self.rootItems.hint1,true)
            break
        end
    end

    ui.sethint(self.rootItems.hint2,false)
    for i,v in ipairs(self.data.daily) do
        if v.status == 1 then
            ui.sethint(self.rootItems.hint2,true)
            break
        end
    end

    ui.sethint(self.rootItems.hint3,false)
    for i,v in ipairs(self.data.challenge) do
        if v.status == 1 then
            ui.sethint(self.rootItems.hint3,true)
            break
        end
    end
end

function sculpture.refreshExp(self,islevelup)
    

    local curConfig = self.rewardConfig[tostring(self.data.level)]
    local nextConfig = self.rewardConfig[tostring(self.data.level + 1)]
    local isMax = (not nextConfig)

    if (not islevelup) and isMax then
        ui.setLabelString(self.rootItems.progresslab,"Max",14)
        self.rootItems.expbar:setPercentage(100)
        return
    end

    local curExp = 0
    local nextExp = 0

    if nextConfig then
        curExp = self.data.exp
        nextExp = nextConfig.experience
        ui.setLabelString(self.rootItems.progresslab,curExp.."/"..nextExp,14)
    else
        curExp = 1
        nextExp = 1
        ui.setLabelString(self.rootItems.progresslab,"Max",14)
    end
    

    if self.firstreload then
        self.rootItems.expbar:setPercentage(curExp/nextExp * 100)
    else
        local processTo = CCProgressTo:create(0.3,curExp/nextExp * 100)
        if islevelup then
        local processTo2 = CCProgressTo:create(0.3,100)
            self.rootItems.expbar:runAction(CCSequence:createWithTwoActions(processTo2,processTo))
        else
            self.rootItems.expbar:runAction(processTo)
        end
    end
    
end

function sculpture.refreshUI(self,issculpturechange)
    ui.setLabelString(self.rootItems.propNum,self.data.props[tostring(192083)] or 0,1030,36)
    self.rootItems.inactivenode:setVisible(self.data.active == 0)
    self.rootItems.activenode:setVisible(self.data.active == 1)

    
    setSpriteFrameByName(self.rootItems.sculpturesprite, self.getSculpturePic(self.data.picId))
    if self.data.active == 0 then
        self.rootItems.sculptureButton:setTouchPriority(self.touchPriority - 3)
        self.rootItems.sculptureButton:addHandleOfControlEvent(function()
            if RechargeLimit and RechargeLimit(6) then
                return
            end
            UIRequest({type = 115,cid = tonumber(gamedata.config.sculpture_dividend_recharge[tostring(self.cpnum)].recharge_id),bagid=13})

        end, CCControlEventTouchUpInside)
    else
        self.rootItems.level:setString("等级."..self.data.level)
    end

end

function sculpture.create_list_reward(self)
    local celldict = {}
    local unrecycleCell = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.rewardCellSize.x, self.rewardCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_diaosujiangli", nil, true, "cell_diaosujiangli")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            self:set_cell_reward(ccbDocumentControler,self.data.reward[a1 + 1])
            cellCCB:setPosition(self.rewardCellSize.x/2, 0)
            cellCCB:setScale(0.98)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.data.reward)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.listTableView_reward = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.rewardscroll:getContentSize().width,
        viewheight = self.rootItems.rewardscroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.rewardscroll:addChild(self.listTableView_reward)
    self.listTableView_reward:setTouchPriority(self.touchPriority)
end

function sculpture.set_cell_reward(self,items,data)
    local config = self.rewardConfig[tostring(data.level)]
    setSpriteFrameByName(items.spr, config.picture)

    local rewards = gamedata.getIDandNUMs(config.reward)

    for i=1,3 do
        if rewards[i] then
            items["icon"..i]:setVisible(true)
            ui.setNewIcon(items,rewards[i],i-1)
            items["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
                if gameTouch.isScrollling then return end
                ui.setPopwindowByCid(rewards[i].cid)

            end, CCControlEventTouchUpInside)
            items["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(self.touchPriority - 1)
        else
            items["icon"..i]:setVisible(false)
        end
    end
    items.nonenode:setVisible(data.status == 0)
    items.getNode:setVisible(data.status == 1)
    items.hasnode:setVisible(data.status == 2)

    ui.setLabelString(items.getlab,gameConfig.strings:string_common("buttontext","lingqu"),18)
    items.getbtn:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        UIRequest({type = 8131, method = 1, param = data.level})
    end, CCControlEventTouchUpInside)
    items.getbtn:setTouchPriority(self.touchPriority - 1)

    ui.setLabelString(items.level,data.level,18,data.level > 99 and 44 or 60)
end

function sculpture.create_list_daily(self)
    local celldict = {}
    local unrecycleCell = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.taskCellSize.x, self.taskCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_diaosurenwu", nil, true, "cell_diaosurenwu")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            self:set_cell_task(ccbDocumentControler,self.data.daily[a1 + 1],"daily")
            cellCCB:setScale(0.98)
            cellCCB:setPosition(self.taskCellSize.x/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.data.daily)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.listTableView_daily = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.dailyscroll:getContentSize().width,
        viewheight = self.rootItems.dailyscroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.dailyscroll:addChild(self.listTableView_daily)
    self.listTableView_daily:setTouchPriority(self.touchPriority)
end

function sculpture.create_list_challenge(self)
    local celldict = {}
    local unrecycleCell = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.taskCellSize.x, self.taskCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_diaosurenwu", nil, true, "cell_diaosurenwu")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            self:set_cell_task(ccbDocumentControler,self.data.challenge[a1 + 1],"challenge")
            cellCCB:setScale(0.98)
            cellCCB:setPosition(self.taskCellSize.x/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.data.challenge)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.listTableView_challenge = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.challengescroll:getContentSize().width,
        viewheight = self.rootItems.challengescroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.challengescroll:addChild(self.listTableView_challenge)
    self.listTableView_challenge:setTouchPriority(self.touchPriority)
end

function sculpture.set_cell_task(self,items,data,tag)

    items.node1:setVisible(false)
    items.node2:setVisible(false)
    items.getNode:setVisible(false)
    items.rechargeNode:setVisible(false)
    items.hasnode:setVisible(false)
    items.nonenode:setVisible(false)
    items.timeslab:setString("")
    items.progresslab:setString("")

    --icon显示 描述信息
    local config = self[tag.."Config"][tostring(data.id)]
    items.name:setString(config.name)
    if config.type ~= 1 and config.type ~= 4 then
        items.progresslab:setString(string.format("（%d/%d）", math.min(data.now,config.param1),config.param1))
        items.progresslab:setPositionX(items.name:getPositionX() + items.name:getContentSize().width + 3)
    end
    items.desc:setString(config.desc)

    local props1 = gamedata.getIDandNUMs(config.param2)[1]
    local props2 = gamedata.getIDandNUMs(config.reward)[1]
    if config.type ~= 4 then
        ui.setNewIcon(items,props2)
        items["i_button"]:setTouchPriority(self.touchPriority - 1)
        items["i_button"]:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            ui.setPopwindowByCid(props2["cid"])
        end, CCControlEventTouchUpInside)
    else
        ui.setNewIcon(items,props1)
        ui.setNewIcon(items,props2,1)
        if props1 and props1.cid == 1001 and GameScene.roleinfo.gold < props1.num then
            ui.setLabelString(items["i_num"], nil, 24)
        else
            ui.setLabelString(items["i_num"], nil, 13)
        end

        items["i_button"]:setTouchPriority(self.touchPriority - 1)
        items["i_button"]:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            ui.setPopwindowByCid(props1["cid"])
        end, CCControlEventTouchUpInside)

        items["i_button_1"]:setTouchPriority(self.touchPriority - 1)
        items["i_button_1"]:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            ui.setPopwindowByCid(props2["cid"])
        end, CCControlEventTouchUpInside)
    end

    ui.setLabelString(items.getlab,gameConfig.strings:string_common("buttontext",config.type == 4 and "goumai" or "lingqu"),18)
    --领取 购买按钮
    if config.type == 1 and data.now >= config.param1 then
        ui.addGray("CCControlButton",items.getbtn)
        ui.addGray("CCLabelTTF",items.getlab)
    elseif config.type == 4 and data.now >= config.param1 then
        ui.addGray("CCControlButton",items.getbtn)
        ui.addGray("CCLabelTTF",items.getlab)
    else
        ui.removeGray("CCControlButton",items.getbtn)
        ui.removeGray("CCLabelTTF",items.getlab)
    end

    items["getbtn"]:setTouchPriority(self.touchPriority - 1)
    items["getbtn"]:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        if config.type == 1 and data.now >= config.param1 then
            runGamePrompt({msg = gameConfig.strings:string_common("huanhua",18)})
        elseif config.type == 4 then
            if data.now >= config.param1 then
                runGamePrompt({msg = gameConfig.strings:string_common("huanhua",19)})
            elseif props1 and props1.cid == 1001 and GameScene.roleinfo.gold < props1.num then
                shortGold()
            else
                local cb = function ()
                    UIRequest({type = 8131,method = (tag == "daily" and 2 or 3),param = data.id})
                end
                if props1 and next(props1) then
                    local rich = {
                        {fontID = 1,content = "是否消耗",},
                        {fontID = 11,content = props1.num..ui.IDconfig(props1.cid).name,},
                        {fontID = 1,content = "购买",},
                        {fontID = 11,content = ui.IDconfig(props2.cid).name,},
                        {fontID = 1,content = "？",},
                    }
                    gameWindows:openWindow("confirm",{rich = rich}, cb)
                else
                    cb()
                end
            end
        else
            UIRequest({type = 8131,method = (tag == "daily" and 2 or 3),param = data.id})
        end

    end, CCControlEventTouchUpInside)

    
    ui.setLabelString(items.rechargelab,gameConfig.strings:string_common("buttontext","chongzhi"),18)
    items["rechargebtn"]:setTouchPriority(self.touchPriority - 1)
    items["rechargebtn"]:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        gameWindows:openWindow("recharge",{pagetype = "info"})
    end, CCControlEventTouchUpInside)


    if config.type == 1 then
        items.node2:setVisible(true)
        items.getNode:setVisible(true)
        items.timeslab:setString(gameConfig.strings:string_common("huanhua",16)..math.max(0,(config.param1 - data.now)))
    elseif config.type == 3 then
        items.node2:setVisible(true)
        if data.status == 0 then
            items.rechargeNode:setVisible(true)
        elseif data.status == 1 then
            items.getNode:setVisible(true)
        elseif data.status == 2 then
            items.hasnode:setVisible(true)
        end
    elseif config.type == 4 then
        items.node1:setVisible(true)
        items.getNode:setVisible(true)
        items.timeslab:setString(gameConfig.strings:string_common("huanhua",17)..math.max(0,(config.param1 - data.now)))
    else
        items.node2:setVisible(true)
        if data.status == 0 then
            items.nonenode:setVisible(true)
        elseif data.status == 1 then
            items.getNode:setVisible(true)
        elseif data.status == 2 then
            items.hasnode:setVisible(true)
        end
    end
end

function sculpture.create_list_shop(self)
    local celldict = {}
    local unrecycleCell = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.shopCellSize.x, self.shopCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_diaosushop", nil, true, "cell_diaosushop")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:set_cell_shop(self.data.shop[(a1+1)*2-1],ccbDocumentControler,1)

            if self.data.shop[(a1+1)*2] then
                self:set_cell_shop(self.data.shop[(a1+1)*2],ccbDocumentControler,2)
                ccbDocumentControler.RightRewardNode:setVisible(true)
            else
                ccbDocumentControler.RightRewardNode:setVisible(false)
            end

            cellCCB:setPosition(self.shopCellSize.x/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = math.ceil(table.getTableLength(self.data.shop)/2)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.listTableView_shop = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.shopscroll:getContentSize().width,
        viewheight = self.rootItems.shopscroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.shopscroll:addChild(self.listTableView_shop)
    self.listTableView_shop:setTouchPriority(self.touchPriority)
end

function sculpture.set_cell_shop(self,data,items,index)
    printT(data,"set_cell_shop")
    local key_Ex
    local icon_key
    if index == nil or index == 1 then
        key_Ex = ""
        icon_key = ""
    else
        key_Ex = "_2"
        icon_key = "_1"
    end

    local config = self.shopConfig[tostring(data.id)]

    if not config  then
        print("notid===",data.id)
        return
    end
    printT(config)



    local timesstring = string.format(gameConfig.strings:string_common("sculpture",10), (config.number_limit-data.num))
    if config.number_limit and config.number_limit <= 0 then
        config.number_limit = 9999999
        timesstring = ""
    end    

    items["desc"..key_Ex]:setString(timesstring)
    ui.setLabelString(items["desc"..key_Ex],nil,13)
    
    local spenddata = ui.getIDandNUMs(config.cost)[1]
    local propnum = self.data.props[tostring(spenddata.cid)] or 0
    
    local spendConfig = ui.IDconfig(spenddata.cid)
    if propnum >= math.floor(spenddata.num) then
        ui.setLabelString(items["gold"..key_Ex],math.floor(spenddata.num),14)
    else
        ui.setLabelString(items["gold"..key_Ex],math.floor(spenddata.num),27)
    end
    setSpriteFrameByName(items["usesprite"..key_Ex], spendConfig.icon)

    local goods = ui.getIDandNUMs(config.goods)[1]
    local goodsConfig = ui.IDconfig(goods.cid)

    items["name"..key_Ex]:setString(goodsConfig.name)
    if goodsConfig.quality and goodsConfig.quality >= 7 then
        ui.setLabelString(items["name"..key_Ex],nil,213)
    else
        ui.setLabelString(items["name"..key_Ex],nil,((goodsConfig.quality and goodsConfig.quality ~= 0) and goodsConfig.quality or 1)*2-1)
    end

    if self.data.level < config.level_limit then
        items["limit"..key_Ex]:setString(string.format(gameConfig.strings:string_common("sculpture",9), config.level_limit))
        items["goldnode"..key_Ex]:setPositionY(0)
    else
        items["limit"..key_Ex]:setString("")
        items["goldnode"..key_Ex]:setPositionY(-20)
    end


    ui.setNewIcon(items,{cid = goods.cid, num = goods.num},index-1)
    --
    items["i_button"..icon_key]:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        ui.setPopwindowByCid(goods.cid)
    end, CCControlEventTouchUpInside)
    items["i_button"..icon_key]:setTouchPriority(self.touchPriority - 1)
    --

    ui.setLabelString(items["exchangeText"..key_Ex],nil,18)

    items["exchange"..key_Ex]:setTouchPriority(self.touchPriority - 1)
    items["exchange"..key_Ex]:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        gameTouch:clickprofbytime(0.5)

        if self.data.active == 0 then
            runGamePrompt({msg = gameConfig.strings:string_common("sculpture",5)})
            return
        end

        if self.data.level < config.level_limit then
            runGamePrompt({msg = string.format(gameConfig.strings:string_common("sculpture",9), config.level_limit)})
            return
        end

        if config.number_limit-data.num <= 0 then
            runGamePrompt({msg = "超出兑换次数限制"})
        elseif propnum < math.floor(spenddata.num) then
            runGamePrompt({msg = spendConfig.name.."数量不足"})
        else

            local limit = gamedata.config.global_kv.sculpture_dividend_storepw and tonumber(gamedata.config.global_kv.sculpture_dividend_storepw.value) or 0
            if spenddata.num >= limit then
                local cb = function (  )
                    UIRequest({type = 8132, id = data.id,spenddata = spenddata,num = 1})
                end

                local rich = {
                    {fontID = 1,content = "是否消耗 ",},
                    {fontID = 0,content = spendConfig.icon,scale = 0.5},
                    {fontID = 11,content = " "..spenddata.num,},
                    {fontID = 1,content = "，\n兑换",},
                    {fontID = 11,content = goodsConfig.name,},
                }
                gameWindows:openWindow("confirm",{rich = rich}, cb)
            else

                function shopExchangeRequest(num)
                    UIRequest({type = 8132, id = data.id,spenddata = spenddata,num = num})
                end

                gameWindows:openWindow("shopExchange",{cid = goods.cid,num = goods.num,cost = {spenddata},exchangeNum = config.number_limit-data.num,limit_cost = true},shopExchangeRequest)
            end
        end

    end, CCControlEventTouchUpInside)

    if self.data.active == 0 then
        ui.addGray("CCControlButton",items["exchange"..key_Ex])
        ui.addGray("CCLabelTTF",items["exchangeText"..key_Ex])
    elseif config.number_limit-data.num <= 0 then
        ui.addGray("CCControlButton",items["exchange"..key_Ex])
        ui.addGray("CCLabelTTF",items["exchangeText"..key_Ex])
    elseif self.data.level < config.level_limit then
        ui.addGray("CCControlButton",items["exchange"..key_Ex])
        ui.addGray("CCLabelTTF",items["exchangeText"..key_Ex])
    else
        ui.removeGray("CCControlButton",items["exchange"..key_Ex])
        ui.removeGray("CCLabelTTF",items["exchangeText"..key_Ex])
    end

end

function sculpture.clear(self)
    self.show                       = false
    self.selectpage                 = "reward"
    self.rootNode                   = nil
    self.rootItems                  = nil  
    self.listTableView_reward       = nil
    self.listTableView_daily        = nil
    self.listTableView_challenge    = nil
    self.listTableView_shop         = nil
    self.ranklist                   = nil

    self:restData()
    gameTimer:UnrigistTimeFunc("sculptureDailyRefreshTime")
    gameTimer:UnrigistTimeFunc("sculptureEndRefreshTime")
end

return sculpture
