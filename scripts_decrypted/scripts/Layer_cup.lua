--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/7
-- Time: 下午1:52
-- To change this template use File | Settings | File Templates.
--

local cup = {

    resource = nil,
    retainresource  = {"cup/cup"},

    rootNode = nil,
    rootItems = nil,

    pageconfig = {"self","tops","rank"} ,
    -- pagename = {"赛场","比赛","排名"},
    pagename = {gameConfig.strings:string_common("cup",0),gameConfig.strings:string_common("cup",1),gameConfig.strings:string_common("goddownrank",8)},
    selectpage = "self",



    statusdata = {},
    topsdata = {},
    rankdata = {},

    touchX = nil,
    topspage = 1,
    topsapageconfig = {8,4,2},
    betcoonfig = {3,5,10},
    topsitems = {},

    selfTableView = nil,
    selfCellSize = {x =1080,y=242},

    rankTableView = nil,
    rankCellSize = {x =940,y=110},

    requestByTime = {
        {hour= 9,min = 20, sec = 0, request = {type = 2100}, },
        {hour= 9,min = 40, sec = 0, request = {type = 2100}, },
        {hour= 10,min = 0, sec = 0, request = {type = 2100}, },
        {hour= 10,min = 20, sec = 0, request = {type = 2100}, },
        {hour= 10,min = 40, sec = 0, request = {type = 2100}, },
        {hour= 11,min = 0, sec = 0, request = {type = 2100}, },
        {hour= 11,min = 20, sec = 0, request = {type = 2100}, },
        {hour= 11,min = 40, sec = 0, request = {type = 2100}, },
        {hour= 12,min = 0, sec = 0, request = {type = 2100}, },

        {hour= 14,min = 1, sec = 1, request = {type = 2102}, },
        {hour= 14,min = 30, sec = 1, request = {type = 2102}, },
        {hour= 16,min = 1, sec = 1, request = {type = 2102}, },
        {hour= 16,min = 30, sec = 1, request = {type = 2102}, },
        {hour= 19,min = 1, sec = 1, request = {type = 2102}, },
        {hour= 19,min = 30, sec = 1, request = {type = 2102}, },

        {hour= 14,min = 30, sec = 0, request = {type = 21021, round = 10}, },
        {hour= 16,min = 30, sec = 0, request = {type = 21021, round = 11}, },
        {hour= 19,min = 30, sec = 0, request = {type = 21021, round = 12}, },


    },
    canJoinCupTime = -1 ,--  -1:初始值 无效 0：不能报名时间段 1 可以报名时间段
    isscrolltouched = false,
    rewardNum = 1,
}

function cup.shiftPage(self,type)
    self.selectpage = type

    for k,v in ipairs(self.pageconfig) do
        if v == type then
            self.rootItems[v.."node"]:setVisible(true)
            self.rootItems[v.."node"]:setPositionX(0)
        else
            self.rootItems[v.."node"]:setVisible(false)
            self.rootItems[v.."node"]:setPositionX(9999)
        end
    end

    if self.selectpage == "self" then
        if not next(self.statusdata) then
            UIRequest({type = 2100})
        else
            self:reloadStatus()
        end
        if self.rootItems.rule then
            self.rootItems.rule:setVisible(true)
        end
    elseif self.selectpage == "tops" then
        if not next(self.topsdata) then
            if not next(self.statusdata) then
                UIRequest({type = 2100})
            end
            UIRequest({type = 2102})
        else
            self:reloadTops()
        end
        if self.rootItems.rule then
            self.rootItems.rule:setVisible(true)
        end
    elseif self.selectpage == "rank" then
        if not next(self.rankdata) then
            UIRequest({type = 2107})
        else
            self:reloadRank()
        end
        if self.rootItems.rule then
            if gameConfig:checkBuildOpen(212) then
                self.rootItems.rule:setVisible(true)
            else
                self.rootItems.rule:setVisible(false)
            end
        end
    end
end

function cup.init(self,parent,toppos,params)
    self.rootNode,self.rootItems = CCBReaderLoad("cup/cup", nil, true, "cup")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.selfbattletop:setPositionY(toppos)

    self.rootItems.nobattlemid:setPositionY((GameScene.topposY-1620)*0.5+450)

    self.rootItems.topstop:setPositionY(toppos)
    self.rootItems.topsmid:setPositionY((GameScene.topposY-1620)*0.5+360)
    self.rootItems.topsbottom:setPositionY((GameScene.topposY-1620)*0.2+430)
    self.rootItems.ranknode:setPositionY((GameScene.topposY-1620)/2)


    self.rootItems.touchLayer:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-440-gameConfig.labelnodeheight))
    self.rootItems.selfbattlescroll:setContentSize(CCSizeMake(gameConfig.originSize.width,(GameScene.topposY-1620)+750))

    self.rootItems.rule:setTouchPriority(-103)
    self.rootItems.rule:addHandleOfControlEvent(function()
        if self.selectpage == "rank" then
            gameWindows:openWindow("servicewarrule",{opt = 2})
        else
            gameWindows:openWindow("cup",{type = "rule",rewardNum = self.rewardNum},nil)
        end
    end, CCControlEventTouchUpInside)

    self.rootItems.common_back_btn:setSwallowsTouch(true)
    self.rootItems.common_back_btn:setTouchPriority(-103)
    self.rootItems.common_back_btn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("daily")
    end, CCControlEventTouchUpInside)

    self.rootItems.joinbutton:addHandleOfControlEvent(function()
        UIRequest({type = 2101})
    end,CCControlEventTouchUpInside)
    self.rootItems.joinbutton:setTouchPriority(-103)
    self.rootItems.joinbutton:setSwallowsTouch(true)

    self.rootItems.joinedbutton:addHandleOfControlEvent(function()
        runGamePrompt({msg = "已经报名"})
    end,CCControlEventTouchUpInside)
    self.rootItems.joinedbutton:setTouchPriority(-103)
    self.rootItems.joinedbutton:setSwallowsTouch(true)

    self.rootItems.nojoinbutton:addHandleOfControlEvent(function()
        runGamePrompt({msg = "非报名时间"})
    end,CCControlEventTouchUpInside)
    self.rootItems.nojoinbutton:setTouchPriority(-103)
    self.rootItems.nojoinbutton:setSwallowsTouch(true)

    self.rootItems.joinbutton2:addHandleOfControlEvent(function()
        UIRequest({type = 2101})
    end,CCControlEventTouchUpInside)
    self.rootItems.joinbutton2:setTouchPriority(-103)
    self.rootItems.joinbutton2:setSwallowsTouch(true)

    self.rootItems.joinedbutton2:addHandleOfControlEvent(function()
        runGamePrompt({msg = "已经报名"})
    end,CCControlEventTouchUpInside)
    self.rootItems.joinedbutton2:setTouchPriority(-103)
    self.rootItems.joinedbutton2:setSwallowsTouch(true)

    self.rootItems.nojoinbutton2:addHandleOfControlEvent(function()
        runGamePrompt({msg = "非报名时间"})
    end,CCControlEventTouchUpInside)
    self.rootItems.nojoinbutton2:setTouchPriority(-103)
    self.rootItems.nojoinbutton2:setSwallowsTouch(true)

    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.touchLayer,x,y) then
            self.isContentScroll = false
            self.touchX = x
            self.contentoffsetx = self.rootItems.pagenode:getPositionX()
            return true
        end
    end

    local function ccTouchMoved(x, y)
        if math.abs(x - self.touchX) > 10 then
            self.isContentScroll = true
        end

        if math.abs(x - self.touchX) > 20 then
            local offsetX = self.contentoffsetx + (x - self.touchX)
            self.rootItems.pagenode:setPositionX(offsetX)
        end
    end

    local function ccTouchEnded(x, y)
        if self.touchX - x > 20 then
            if self.topspage+1 <=3 then
                self:setTopsPage(self.topspage+1)
            else
                self:setTopsPage(self.topspage)
            end
        elseif self.touchX - x < -20 then
            if self.topspage-1 >0 then
                self:setTopsPage(self.topspage-1)
            else
                self:setTopsPage(self.topspage)
            end
        else

        end
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

    self.rootItems.touchLayer:registerScriptTouchHandler(onTouch, false, -102, false)
    self.rootItems.touchLayer:setTouchPriority(-102)
    self.rootItems.touchLayer:setTouchEnabled(true)

    gameTimer:rigistTime("cuptimer",99)
    gameTimer:rigistTimeFunc("cuptimer",function()
        local nowtime = os.date("*t", gamedata:time())
        if self.canJoinCupTime ~= 0 and nowtime.hour < 9  then
            self.canJoinCupTime = 0
            self:changeButton()
        elseif  self.canJoinCupTime ~= 1 and nowtime.hour >= 9  then
            self.canJoinCupTime = 1
            self:changeButton()
        end        
        for k,v in ipairs(self.requestByTime) do

            if nowtime.hour == v.hour and nowtime.min == v.min and nowtime.sec == v.sec and not v.hassend then
                UIRequest(v.request)
            end
        end
        if gameTimer.times["cuptimer"] <= 0 then
            gameTimer:rigistTime("cuptimer",99)
        end
    end)

-----
    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","cup",touchbegin)

    local function touchend(pos)
        if self.rootItems.selfbattlescroll and ui.isTouched(self.rootItems.selfbattlescroll,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","cup",touchend)

-----
    self:initFixedString()

    if params and params.page then
        self.selectpage = params.page
    end

    --
    local now = os.date("*t", gamedata:time())
    if now.hour >= 16 then
        self.topspage = 3
    elseif now.hour >= 14 then
        self.topspage = 2
    else
        self.topspage = 1
    end    

    self:shiftPage(self.selectpage)

    --war_time
    self:setWarTime()

--    UIRequest({type = 2100})
--    UIRequest({type = 2102})
end

function cup.creatSelfBattleList(self)
    local celldict = {}
    local selfListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.selfCellSize.x, self.selfCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("cup/cell_cup.ccbi", nil, true, "cell_cup")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.selfTableView,cellCCB,self.selfCellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            --printT(self.statusdata.battles[tostring(a1+1)])

            local enemy = self.statusdata.battles[tostring(a1+1)].enemy

            ui.setIconLv(ccbDocumentControler,{cid = enemy.profile,level = enemy.level,title = enemy.title,iconBox = enemy.iconBox})
            -- ui.setLabelString(ccbDocumentControler.name,enemy.name,1)

            -- 添加段位排名闪烁
            ui.setWudaoDuanweiRankEffect(ccbDocumentControler,enemy,0,38/34,1)


            ccbDocumentControler.round:setString(self.statusdata.battles[tostring(a1+1)].round)

            --ccbDocumentControler.result:setString(self.statusdata.battles[tostring(a1+1)].result == 1  and "胜利！" or "失败！")

            ccbDocumentControler.resultV:setVisible(self.statusdata.battles[tostring(a1+1)].result == 1)
            ccbDocumentControler.resultF:setVisible(self.statusdata.battles[tostring(a1+1)].result ~= 1)

            ccbDocumentControler.doButton:setTouchPriority(-103)

            if  self.statusdata.battles[tostring(a1+1)].result == 1 and self.statusdata.battles[tostring(a1+1)].reward == 0 then
                setControlButtonFrame(ccbDocumentControler.doButton, "b_s_button2","b_s_button2","b_s_button2")
                -- ui.setLabelString(ccbDocumentControler.doLab,"领 取",18)
                ui.setLabelString(ccbDocumentControler.doLab,gameConfig.strings:string_common("moreCommon",6),18)
                ccbDocumentControler.doButton:addHandleOfControlEvent(function()
                    if not self.isscrolltouched then return end
                    if gameTouch.isScrollling then return end
                     UIRequest({type = 2104, id = self.statusdata.battles[tostring(a1+1)].id, round = self.statusdata.battles[tostring(a1+1)].round})
                end, CCControlEventTouchUpInside)
            else
                setControlButtonFrame(ccbDocumentControler.doButton, "b_s_button1","b_s_button1","b_s_button1")
                -- ui.setLabelString(ccbDocumentControler.doLab,"重 播",18)
                ui.setLabelString(ccbDocumentControler.doLab,gameConfig.strings:string_common("moreCommon",17),18)
                ccbDocumentControler.doButton:addHandleOfControlEvent(function()
                    if not self.isscrolltouched then return end
                    if gameTouch.isScrollling then return end
                    UIRequest({type = 2103, id = self.statusdata.battles[tostring(a1+1)].id,round = self.statusdata.battles[tostring(a1+1)].round,isself=true})
                end, CCControlEventTouchUpInside)
            end

            --todo
            --part
            if ccbDocumentControler.duanNode then
                ui.setWudaoPart(ccbDocumentControler,enemy.part_point or 0)
            end

            if self.selfTableView then
                cellCCB:setPosition(self.selfCellSize.x/2, 0)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.statusdata.battles)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.selfTableView = ui.createLuaTableView({
        handle = selfListHandle,
        viewwidth = self.rootItems.selfbattlescroll:getContentSize().width,
        viewheight = self.rootItems.selfbattlescroll:getContentSize().height,
        dire = 1
    })
    self.selfTableView:setTouchPriority(-101)
    self.rootItems.selfbattlescroll:addChild(self.selfTableView)
end

function cup.clear(self)
    self.selfTableView = nil
    self.rankTableView = nil
    self.topsitems = {}
    gameTimer:UnrigistTimeFunc("cuptime")
    gameTimer:UnrigistTimeFunc("cuptimer")
    gameTimer:UnrigistTimeFunc("cupranktimer")
    self.selectpage = "self"
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.rewardNum = 1
    self.statusdata = {}
    self.topsdata = {}
    self.rankdata = {}
    self.canJoinCupTime = -1
    gameTouch:UnrigistFunc("begin","cup")
    gameTouch:UnrigistFunc("end","cup")
    if gameTimer.times["cup_bettime"] then
        gameTimer:UnrigistTimeFunc("cup_bettime")
    end
end

function cup.reloadStatus(self,data,rewardNum)
    printT(data,"cup.reloadStatus ============")
    if data then
        self.statusdata = data
    end
    if rewardNum then
        self.rewardNum = rewardNum
    end

    if gameConfig:checkBuildOpen(154) then
        self.rootItems.des11:setString("呦呦，快来参加比赛啊，\n        自动报名明日杯赛")
        self.rootItems.des12:setString("贵族5")
        self.rootItems.des13:setString("贵族5自动报名明日杯赛")
    else
        self.rootItems.des11:setString("呦呦，快来参加比赛啊!")
        self.rootItems.des12:setString("")
        self.rootItems.des13:setString("")
    end

    if table.getTableLength(self.statusdata.battles) >0 then
        self.rootItems.nobattleNode:setPosition(ccp(9999,9999))
        self.rootItems.nobattleNode:setVisible(false)
        self.rootItems.selfbattleNode:setPosition(ccp(0,0))
        self.rootItems.selfbattleNode:setVisible(true)

        ui.setLabelString(self.rootItems.getallLab,"全部领取",18)

        local hasreward = false
        for k,v in pairs(self.statusdata.battles) do
            if v.result ==1 and v.reward ==0 then
                hasreward = true
            end
        end

        if not hasreward then
            ui.addGray("CCControlButton",self.rootItems.getallButton)
            self.rootItems.getallButton:addHandleOfControlEvent(function()
                runGamePrompt({msg = "无奖励可领取"})
            end, CCControlEventTouchUpInside)
        else
            ui.removeGray("CCControlButton",self.rootItems.getallButton)
            self.rootItems.getallButton:addHandleOfControlEvent(function()
                UIRequest({type = 2106})
            end, CCControlEventTouchUpInside)
        end

        if  self.selfTableView then
            self.selfTableView:reloadData()
        else
            self:creatSelfBattleList()
        end

        self.rootItems.mamian2:removeAllChildrenWithCleanup(true)
        local ma = CCSkeletonAnimation:create("mamian/mamian.json","mamian/mamian.atlas",2)
        ma:setAnimation("stand",true,0)
        self.rootItems.mamian2:addChild(ma)

        if self.statusdata.tomorrow == 1 then
            ui.addGray("CCControlButton",self.rootItems.joinbutton2)
            self.rootItems.joinbutton2:addHandleOfControlEvent(function()
            end, CCControlEventTouchUpInside)
        else
            ui.removeGray("CCControlButton",self.rootItems.joinbutton2)
            self.rootItems.joinbutton2:addHandleOfControlEvent(function()
                UIRequest({type = 2101})
            end, CCControlEventTouchUpInside)
        end

    else
        self.rootItems.nobattleNode:setPosition(ccp(0,0))
        self.rootItems.nobattleNode:setVisible(true)
        self.rootItems.selfbattleNode:setPosition(ccp(9999,9999))
        self.rootItems.selfbattleNode:setVisible(false)

        self.rootItems.niutou:removeAllChildrenWithCleanup(true)
        local niu = CCSkeletonAnimation:create("niutou/niutou.json","niutou/niutou.atlas",2)
        niu:setAnimation("stand",true,0)
        self.rootItems.niutou:addChild(niu)
        self.rootItems.mamian:removeAllChildrenWithCleanup(true)
        local ma = CCSkeletonAnimation:create("mamian/mamian.json","mamian/mamian.atlas",2)
        ma:setAnimation("stand",true,0)
        self.rootItems.mamian:addChild(ma)

        if self.statusdata.tomorrow == 1 then
            ui.addGray("CCControlButton",self.rootItems.joinbutton)

            self.rootItems.joinbutton:addHandleOfControlEvent(function()
            end, CCControlEventTouchUpInside)

            if gameTimer.times["cuptime"] and gameTimer.times["cuptime"] ~= 0 then
                gameTimer:rigistTimeFunc("cuptime",function()
                    if  gameTimer.times["cuptime"] == 0 then
                        -- ui.setLabelString(self.rootItems.selfdes,"比赛中......",12)
                        ui.setLabelString(self.rootItems.selfdes,gameConfig.strings:string_common("cup",2),121)
                        ui.setLabelString(self.rootItems.time,"",26)
                    else
                        -- ui.setLabelString(self.rootItems.selfdes,"开赛倒计时: ",12)
                        ui.setLabelString(self.rootItems.selfdes,gameConfig.strings:string_common("cup",3),121)
                        ui.setLabelString(self.rootItems.time,ui.makeTimeText(gameTimer.times["cuptime"]),26)
                    end
                end)
            end
        else
            self.rootItems.selfdes:setString("")
            self.rootItems.time:setString("")
            ui.removeGray("CCControlButton",self.rootItems.joinbutton)
            self.rootItems.joinbutton:setTouchPriority(-103)
            self.rootItems.joinbutton:addHandleOfControlEvent(function()
                UIRequest({type = 2101})
            end, CCControlEventTouchUpInside)
        end
    end

end

function cup.setTopsPage(self,page)
    self.topspage = page

    local moveto = CCMoveTo:create(0.2, ccp(-1080*(self.topspage-1), 0))
    self.rootItems.pagenode:runAction(moveto)

    --self.rootItems.betnum:setString(self.betcoonfig[self.topspage])
    for k,v in ipairs(self.topsapageconfig) do
        if self.topspage  == k then
            self.rootItems["select"..v]:setVisible(true)
        else
            self.rootItems["select"..v]:setVisible(false)
        end
    end

    -- if gamedata.config.cup_bet_consume and gamedata.config.cup_bet_consume[tostring(self.topspage)] then
    --     print("  self.topspage  ",self.topspage)
    --    local cid,num = ui.getIDandNUM(gamedata.config.cup_bet_consume[tostring(self.topspage)].consume)
    --    UIRequest({type = 12001, cids = {cid}, order=21001})
    -- end

    --bettime
    if self.rootItems.bettime and self.rootItems.bettime_desc then 
        ui.setLabelString(self.rootItems.bettime_desc,nil,21)
        local bettime = 0
        local bettimestr = ""
        local now = os.date("*t", gamedata:time())
        if self.topspage == 3 and now.hour >= 16 and now.hour < 19 then
            bettime = 19*3600-now.hour*3600-now.min*60-now.sec
            bettimestr = "决赛押注结束倒计时："
        elseif self.topspage == 2 and now.hour >= 14 and now.hour < 16 then
            bettime = 16*3600-now.hour*3600-now.min*60-now.sec
            bettimestr = "四进二押注结束倒计时："
        elseif self.topspage == 1 and now.hour >= 12 and now.hour < 14 then
            bettime = 14*3600-now.hour*3600-now.min*60-now.sec
            bettimestr = "八进四押注结束倒计时："
        end    
        if bettime > 0 then
            self.rootItems.bettime:setVisible(true)
            self.rootItems.bettime_desc:setVisible(true)
            gameTimer:rigistTime("cup_bettime",bettime)
            if gameTimer.times["cup_bettime"] and gameTimer.times["cup_bettime"] > 0 then
                gameTimer:rigistTimeFunc("cup_bettime", function()
                    if gameTimer.times["cup_bettime"] <= 0 then
                        self.rootItems.bettime:setVisible(false)
                        self.rootItems.bettime_desc:setVisible(false)
                        if gameTimer.times["cup_bettime"] then
                            gameTimer:UnrigistTimeFunc("cup_bettime")
                        end
                    else
                        ui.setLabelString(self.rootItems.bettime,bettimestr..ui.makeTimeDayText(gameTimer.times["cup_bettime"],"hour"),23)
                    end
                end)
            end
        else
            self.rootItems.bettime:setVisible(false)
            self.rootItems.bettime_desc:setVisible(false)
        end    
    end

end

function cup.setpropnum(self,nums)

    printT(nums,"setpropnum")

    -- if gamedata.config.cup_bet_consume and gamedata.config.cup_bet_consume[tostring(self.topspage)] then
    --     local cid,num = ui.getIDandNUM(gamedata.config.cup_bet_consume[tostring(self.topspage)].consume)

        -- if nums[tostring(cid)] >= num then
        --     ui.setLabelString(self.rootItems.betnum,ui.IDconfig(cid).name.." "..num,14)
        -- else
        --     ui.setLabelString(self.rootItems.betnum,ui.IDconfig(cid).name.." "..num,11)
        -- end
    -- end
end

function cup.setpos(self,stage,itemTable,dataTable,id)
    local key_Ex
    if id == nil or id == 0 then
        key_Ex = ""
    else
        key_Ex = "_"..id
    end

    if dataTable.profile then

        itemTable["g_datanode"..key_Ex]:setVisible(true)
        itemTable["g_nonode"..key_Ex]:setVisible(false)

        local config = ui.IDconfig(dataTable.profile)
        setSpriteFrameByName(itemTable["g_quality"..key_Ex], gameConfig.images["l_g_q_back_"..config.quality])
        setSpriteFrameByName(itemTable["g_icon"..key_Ex],config["icon"])
        itemTable["g_level"..key_Ex]:setString("等级. "..dataTable.level)
        -- itemTable["g_name"..key_Ex]:setString(dataTable.name == "主角" and GameScene.roleinfo.name or dataTable.name)
        itemTable["g_name"..key_Ex]:setString(dataTable.name == gameConfig.strings:string_common("cup",4) and GameScene.roleinfo.name or dataTable.name)
        itemTable["g_isbet"..key_Ex]:setVisible(dataTable.isbet)

        if dataTable.result == -1 then
            setSpriteFrameByName(itemTable["g_result"..key_Ex],gameConfig.images.alpha)
        elseif dataTable.result == 0 then
            setSpriteFrameByName(itemTable["g_result"..key_Ex],gameConfig.images.losesprite)
        elseif dataTable.result == 1 then
            setSpriteFrameByName(itemTable["g_result"..key_Ex],gameConfig.images.winsprite)
        end
    else

        setSpriteFrameByName(itemTable["g_quality"..key_Ex], gameConfig.images["l_g_q_back_default"])
        itemTable["g_datanode"..key_Ex]:setVisible(false)

        print("-------",self.betstage,stage)
        if self.betstage == stage  then
            itemTable["g_nonode"..key_Ex]:setVisible(true)
        else
            itemTable["g_nonode"..key_Ex]:setVisible(false)
        end
        
    end
end


function cup.setOneTopBattle(self,stage,item,data,ida,idb,i)
    --print(data.a.name,data.b.name,ida,idb,i)
    if data then
        if data.status == -1 or data.see ==0 then
            if data.bet~=-1 then
                setSpriteFrameByName(item["betsprite"..i],gameConfig.images.hasbet)
                if data.bet == 0 then
                    self:setpos(stage,item,table.merge(data.a,{result = -1,isbet = false}),ida)
                    self:setpos(stage,item,table.merge(data.b,{result = -1,isbet = true}),idb)
                else
                    self:setpos(stage,item,table.merge(data.a,{result = -1,isbet = true}),ida)
                    self:setpos(stage,item,table.merge(data.b,{result = -1,isbet = false}),idb)
                end
            else
                setSpriteFrameByName(item["betsprite"..i],gameConfig.images.betsprite)
                self:setpos(stage,item,table.merge(data.a,{result = -1,isbet = false}),ida)
                self:setpos(stage,item,table.merge(data.b,{result = -1,isbet = false}),idb)
            end
        elseif data.status == 0 then
            if data.bet~=-1 then
                if data.bet == 0 then
                    setSpriteFrameByName(item["betsprite"..i],gameConfig.images.betright)
                    self:setpos(stage,item,table.merge(data.a,{result = 0,isbet = false}),ida)
                    self:setpos(stage,item,table.merge(data.b,{result = 1,isbet = true}),idb)
                else
                    setSpriteFrameByName(item["betsprite"..i],gameConfig.images.betwrong)
                    self:setpos(stage,item,table.merge(data.a,{result = 0,isbet = true}),ida)
                    self:setpos(stage,item,table.merge(data.b,{result = 1,isbet = false}),idb)
                end
            else
                setSpriteFrameByName(item["betsprite"..i],gameConfig.images.checksprite)
                self:setpos(stage,item,table.merge(data.a,{result = 0,isbet = false}),ida)
                self:setpos(stage,item,table.merge(data.b,{result = 1,isbet = false}),idb)
            end

        elseif data.status == 1 then
            if data.bet~=-1 then
                if data.bet == 0 then
                    setSpriteFrameByName(item["betsprite"..i],gameConfig.images.betwrong)
                    self:setpos(stage,item,table.merge(data.a,{result = 1,isbet = false}),ida)
                    self:setpos(stage,item,table.merge(data.b,{result = 0,isbet = true}),idb)
                else
                    setSpriteFrameByName(item["betsprite"..i],gameConfig.images.betright)
                    self:setpos(stage,item,table.merge(data.a,{result = 1,isbet = true}),ida)
                    self:setpos(stage,item,table.merge(data.b,{result = 0,isbet = false}),idb)
                end
            else
                setSpriteFrameByName(item["betsprite"..i],gameConfig.images.checksprite)
                self:setpos(stage,item,table.merge(data.a,{result = 1,isbet = false}),ida)
                self:setpos(stage,item,table.merge(data.b,{result = 0,isbet = false}),idb)
            end

        end
        item["betbutton"..i]:setTouchPriority(-103)
        item["betbutton"..i]:addHandleOfControlEvent(function()
            gameWindows:openWindow("cup",{type = "bet", data = data},nil)
        end, CCControlEventTouchUpInside)
    else
        setSpriteFrameByName(item["betsprite"..i],gameConfig.images.alpha)
        self:setpos(stage,item,{},ida)
        self:setpos(stage,item,{},idb)
        item["betbutton"..i]:setTouchPriority(-103)
        item["betbutton"..i]:addHandleOfControlEvent(function()

        end, CCControlEventTouchUpInside)

    end
end


function cup.reloadTops(self,data)
    if data then
        self.topsdata = data.cuptopbattles
        self.betnum = 3-data.betnum
    end

    self.rootItems.restbet:setString(self.betnum)


    self.betstage = -1
    local now = os.date("*t", gamedata:time())
    if now.hour >= 16 and now.hour < 19 then
        self.betstage = 2
    elseif now.hour >= 14 and now.hour < 16 then
        self.betstage = 4
    elseif now.hour >= 12 and now.hour < 14 then
        self.betstage = 8
    end

    for k,v in ipairs(self.topsapageconfig) do
        if not self.topsitems[v] then
            self.topsitems[v] = {}
            self.topsitems[v].ccb, self.topsitems[v].item = CCBReaderLoad("cup/guess"..v, nil, true, "guess"..v)
            self.topsitems[v].ccb:setPosition(1080*(k-1),0)
            self.rootItems.pagenode:addChild(self.topsitems[v].ccb)
        end

        self.rootItems["pagebutton"..v]:setTouchPriority(-103)
        self.rootItems["pagebutton"..v]:addHandleOfControlEvent(function()
             self:setTopsPage(k)
        end, CCControlEventTouchUpInside)

        if v==8 then
            for i=1,4 do
                self:setOneTopBattle(v,self.topsitems[v].item,self.topsdata[tostring(v)][tostring(i)],i*2-2,i*2-1,i)
            end
        elseif v==4 then
            for i=1,2 do
                self:setOneTopBattle(v,self.topsitems[v].item,self.topsdata[tostring(v)][tostring(i)],i*2-2,i*2-1,i)
            end
        elseif v==2 then
            self:setOneTopBattle(v,self.topsitems[v].item,self.topsdata[tostring(v)][tostring(1)],0,1,1)
        end
    end

    self:setTopsPage(self.topspage)

end
--设置报名时间显示 1 报名截止 2报名时间内
function cup.setTimeDescText(self,aiType)
    if aiType == 1 then
        ui.setLabelString(self.rootItems.timeDescText,gameConfig.strings:string_common("cup",6),13)
    else
        ui.setLabelString(self.rootItems.timeDescText,gameConfig.strings:string_common("cup",5),13)
    end
end
--修改报名按钮显示
function cup.setButtonShow( self,aiType )
    if aiType == 1 then --报名时间、 但没有报名
        self.rootItems["joinbutton"]:setPositionX(0)
        self.rootItems["joinedbutton"]:setPositionX(999999999999)
        self.rootItems["nojoinbutton"]:setPositionX(999999999999)
        self.rootItems["joinbutton2"]:setPositionX(543)
        self.rootItems["joinedbutton2"]:setPositionX(999999999999)
        self.rootItems["nojoinbutton2"]:setPositionX(999999999999)
    elseif aiType == 2 then --报名时间、已经报名
        self.rootItems["joinbutton"]:setPositionX(999999999999)
        self.rootItems["joinedbutton"]:setPositionX(0)
        self.rootItems["nojoinbutton"]:setPositionX(999999999999)
        self.rootItems["joinbutton2"]:setPositionX(999999999999)
        self.rootItems["joinedbutton2"]:setPositionX(543)
        self.rootItems["nojoinbutton2"]:setPositionX(999999999999)
    else--非报名时间
        self.rootItems["joinbutton"]:setPositionX(999999999999)
        self.rootItems["joinedbutton"]:setPositionX(999999999999)
        self.rootItems["nojoinbutton"]:setPositionX(0)
        self.rootItems["joinbutton2"]:setPositionX(999999999999)
        self.rootItems["joinedbutton2"]:setPositionX(999999999999)
        self.rootItems["nojoinbutton2"]:setPositionX(543)
    end
end
function cup.changeButton(self)
    --时间段修改和请求变化都会出发变化
    if self.canJoinCupTime == 0 then --非报名时间 
        self:setButtonShow(3)
        self:setTimeDescText(1)
    elseif self.canJoinCupTime == 1 and  self.statusdata.tomorrow == 0 then --报名时间、 但没有报名
        self:setButtonShow(1)
        self:setTimeDescText(2)
    elseif self.canJoinCupTime == 1 and  self.statusdata.tomorrow == 1 then --报名时间、已经报名
        self:setButtonShow(2)
        self:setTimeDescText(2)
    end
end

--rank
function cup.reloadRank(self,data)

    --
    if data then
        self.rankdata = data
        self.rankdata.myrank = 0
        for k,v in pairs(self.rankdata.ranks) do
            if v.rid == GameScene.roleinfo.id then
                self.rankdata.myrank = tonumber(k)
            end
        end
    end
    --

    self.rootItems.c_bg:setVisible(false)
    self.rootItems.c_bg_self:setVisible(true)
    self.rootItems.c_name:setString(GameScene.roleinfo.name)
    self.rootItems.c_point:setString(self.rankdata.mypoint)
    if (self.rankdata.myrank) > 0 and (self.rankdata.myrank) <= 3 then
        self.rootItems.c_rank_top:setVisible(true)
        self.rootItems.c_rank:setVisible(false)
        setSpriteFrameByName(self.rootItems.c_rank_top, "b_n_zxt_"..(self.rankdata.myrank))
    else
        self.rootItems.c_rank_top:setVisible(false)
        self.rootItems.c_rank:setVisible(true)
        self.rootItems.c_rank:setString((self.rankdata.myrank == 0) and "未上榜" or self.rankdata.myrank)
    end
    --
    ui.setLabelString(self.rootItems.c_rank,nil,14)
    ui.setLabelString(self.rootItems.c_name,nil,14)
    ui.setLabelString(self.rootItems.c_point,nil,14)
    --
    ui.setLabelString(self.rootItems.fixlab2,self.rankdata.number..gameConfig.strings:string_common("fixedString","cuprank",2),21)
    --
    if  self.rankTableView then
        self.rankTableView:reloadData()
    else
        self:creatRankList()
    end

end

function cup.creatRankList(self)
    local celldict = {}
    local rankListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.rankCellSize.x, self.rankCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("kuafuzhan/cell_kuafuzhan_3.ccbi", nil, true, "cell_kuafuzhan")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.rankTableView,cellCCB,self.rankCellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            --
            ccbDocumentControler.c_bg:setVisible(true)
            ccbDocumentControler.c_bg_self:setVisible(false)
            ccbDocumentControler.c_name:setString(self.rankdata.ranks[tostring(a1+1)].name or "")
            ccbDocumentControler.c_point:setString(self.rankdata.ranks[tostring(a1+1)].params["1"] and self.rankdata.ranks[tostring(a1+1)].params["1"].i or 0)
            if (a1+1) > 0 and (a1+1) <= 3 then
                ccbDocumentControler.c_rank_top:setVisible(true)
                ccbDocumentControler.c_rank:setVisible(false)
                setSpriteFrameByName(ccbDocumentControler.c_rank_top, "b_n_zxt_"..(a1+1))
            else
                ccbDocumentControler.c_rank_top:setVisible(false)
                ccbDocumentControler.c_rank:setVisible(true)
                ccbDocumentControler.c_rank:setString(a1+1)
            end

            if self.rankTableView then
                cellCCB:setPosition(self.rankCellSize.x/2, 0)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.rankdata.ranks)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.rankTableView = ui.createLuaTableView({
        handle = rankListHandle,
        viewwidth = self.rootItems.rankscroll:getContentSize().width,
        viewheight = self.rootItems.rankscroll:getContentSize().height,
        dire = 1
    })
    self.rankTableView:setTouchPriority(-101)
    self.rootItems.rankscroll:addChild(self.rankTableView)
end


function cup.setWarTime(self)

    local wday = gamedata.config.cross_battle_time["1"].open_week+1
    if wday > 7 then wday = 1 end
    local hour,min,sec = ui.getGangBattleTime(gamedata.config.cross_battle_time["1"].open_time)
    local nowtime = os.date("*t", gamedata:time())
    local diff = (wday-nowtime.wday)*86400+(hour-nowtime.hour)*3600+(min-nowtime.min)*60+sec-nowtime.sec
    if diff < 0 then diff = diff+86400*7 end

    gameTimer:rigistTime("cupranktimer",diff+1)
    gameTimer:rigistTimeFunc("cupranktimer",function()
        if gameTimer.times["cupranktimer"] <= 0 then
            self:setWarTime()
        else
            ui.setLabelString(self.rootItems.war_time,ui.makeTimeDayText(gameTimer.times["cupranktimer"],"day"),21)
        end
    end)

end

function cup.initFixedString(self)
    ui.setLabelString(self.rootItems.fixlab1,gameConfig.strings:string_common("fixedString","cuprank",1),14)
    --ui.setLabelString(self.rootItems.fixlab2,gameConfig.strings:string_common("fixedString","cuprank",2),21)
    ui.setLabelString(self.rootItems.fixlab3,gameConfig.strings:string_common("fixedString","cuprank",3),14)
    ui.setLabelString(self.rootItems.fixlab4,gameConfig.strings:string_common("fixedString","cuprank",4),14)
    ui.setLabelString(self.rootItems.fixlab5,gameConfig.strings:string_common("fixedString","cuprank",5),23)

    if self.rootItems.cupRankInfo then
        if gameConfig:checkBuildOpen(212) then
            self.rootItems.cupRankInfo:setVisible(true)
        else
            self.rootItems.cupRankInfo:setVisible(false)
        end
    end
end

return cup
  ��  