--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-23
-- Time: 下午3:17
-- To change this template use File | Settings | File Templates.
--

local sports = {

    resource = nil,


    rootNode = nil,
    rootItems = nil,
    rankListTableView = nil,
    top10ListTableView = nil,
    rewardListTableView = nil,
    firstrewardListTableView = nil,

    data = nil,

    rankCellSize = {x=1080,y=225+14},
    rewardCellSize = {x=1080,y=225+14},
    firstrewardCellSize = {x=1080,y=225+14},

    rankData = nil,
    top10Data = nil,
    rewardData = nil,
    myData = nil,
    athletics_boss = 0,
    firstRewardTempData = nil,
    firstRewardData = nil,

    -- pageconfig = {"rank","top10","reward","first"},
    pageconfig = {"rank","top10","first"},
    -- pagename = {"竞技","前十","兑换",},
    -- pagename = {gameConfig.strings:string_common("sports",0),gameConfig.strings:string_common("sports",1),gameConfig.strings:string_common("sports",2),gameConfig.strings:string_common("sports",17),},
    pagename = {gameConfig.strings:string_common("sports",0),gameConfig.strings:string_common("sports",1),gameConfig.strings:string_common("sports",17),},
    selectpage = "rank",
    -- statusconfig = {
    --     [0] = "查看",
    --     [1] = "挑战",
    --     [2] = "反击",
    --     [3] = "刷新",
    --     [4] = "查看",

    -- },
    -- rewardstatusconfig = {
    --     [1] = "领取",
    --     [2] = "领取",
    --     [3] = "兑换",
    -- },
    statusconfig = {
        [0] = gameConfig.strings:string_common("sports",3),
        [1] = gameConfig.strings:string_common("sports",4),
        [2] = gameConfig.strings:string_common("sports",5),
        [3] = gameConfig.strings:string_common("sports",6),
        [4] = gameConfig.strings:string_common("sports",3),

    },
    rewardstatusconfig = {
        [1] = gameConfig.strings:string_common("sports",7),
        [2] = gameConfig.strings:string_common("sports",7),
        [3] = gameConfig.strings:string_common("sports",8),
    },
    isscrolltouched = false,
}

function sports.init(self,parent,toppos)
    self.rootNode,self.rootItems = CCBReaderLoad("n_sports2/n_sports2", nil, true, "sports2")

    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)

    self.rootItems.top10ccb:setPositionY(toppos-gameConfig.navigationheight-400)

    self.rootItems.rankSroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.navigationheight-10))
    self.rootItems.top10Sroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.navigationheight-249))
    self.rootItems.rewardScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.navigationheight-10))
    self.rootItems.firstScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.navigationheight-10))
    --奖励兑换列表已经被移到商店同一窗口
    self.rootItems.rewardScroll:setVisible(false)
    self.rootItems.rewardScroll:setPositionX(9999)    
    self:shiftPage(self.selectpage)

    self.rootItems.common_back_btn:setSwallowsTouch(true)
    self.rootItems.common_back_btn:setTouchPriority(-102)
    self.rootItems.common_back_btn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("daily")
    end, CCControlEventTouchUpInside)

    self.rootItems.helpButton:setTouchPriority(-102)
    self.rootItems.helpButton:addHandleOfControlEvent(function()
        gameWindows:openWindow("sportshelp",nil)
    end, CCControlEventTouchUpInside)

    self.rootItems.gotoShopButton:setTouchPriority(-102)
    self.rootItems.gotoShopButton:addHandleOfControlEvent(function()
        print("去商店")
        -- gameWindows:openWindow("sportshelp",nil)
        GameScene:shiftLayerById(167)
    end, CCControlEventTouchUpInside)
    

    local firstrewardTem = gamedata.config.athletics_rewards3
    self.firstRewardTempData = {}
    for k,v in pairs(firstrewardTem) do
        table.insert(self.firstRewardTempData, v)
    end

    local rankSort = function(a, b)
        return a.rank < b.rank
    end
    table.sort( self.firstRewardTempData, rankSort )

    --
    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","sports",touchbegin)
    local function touchend(pos)
        if self.rootItems.rankSroll and ui.isTouched(self.rootItems.rankSroll,pos.x,pos.y) then
            self.isscrolltouched = true
        end
        if self.rootItems.top10Sroll and ui.isTouched(self.rootItems.top10Sroll,pos.x,pos.y) then
            self.isscrolltouched = true
        end
        if self.rootItems.rewardScroll and ui.isTouched(self.rootItems.rewardScroll,pos.x,pos.y) then
            self.isscrolltouched = true
        end
        if self.rootItems.firstScroll and ui.isTouched(self.rootItems.firstScroll,pos.x,pos.y) then
            self.isscrolltouched = true
        end                
    end
    gameTouch:rigistFunc("end","sports",touchend)
    --
end

function sports.setRankCell(self,data,items,isTop10)
    --printT(data)

    --todo
    --part
    if items.duanNode then
        ui.setWudaoPart(items,data.part_point or 0)
    end

    ui.setIconLv(items,{cid = data.icon, level = data.level ,title = data.title,iconBox = data.iconBox})

    local status = 0
    if not isTop10 then
        status = data.status
    end

    items.power:setString(data.power > 0 and data.power or "?")
    -- items.name:setString(data.name)
    items.rank:setString(data.rank)
    local isPlayFight = 1
    --items.prestige:setString(data.prestige)
    if not isTop10 then
        if data.rank > self.myData.rank then
            isPlayFight = 0;
            items.buttontext:setString(gameConfig.strings:string_common("sports",21))
            ui.setLabelString(items.buttontext,nil,129)
        else
            items.buttontext:setString(self.statusconfig[status])
            ui.setLabelString(items.buttontext,nil,18)
        end
    else
        items.buttontext:setString(self.statusconfig[status])
        ui.setLabelString(items.buttontext,nil,18)
    end
    
    -- ui.setLabelString(items.name,nil,21)

    if items.rank1 and items.rank2 and items.rank3 then
        for i = 1,3 do
            items["rank"..i]:setVisible(data.rank == i)    
        end    
        items["rank"]:setVisible(data.rank > 3) 
    end

    -- 添加段位排名闪烁
    ui.setWudaoDuanweiRankEffect(items,data,0,37/34,21)

    if status == 4 then
        items.button:setVisible(false)
        items.buttontext:setVisible(false)
    else
        items.button:setVisible(true)
        items.buttontext:setVisible(true)
    end

    if status == 3 then
        setControlButtonFrame(items.button,"b_s_button1","b_s_button1_h","b_s_button1")
    else
        setControlButtonFrame(items.button,"b_s_button2","b_s_button2_h","b_s_button2")
    end


    items.buttonnode:setVisible(not (status == 0 and data.rid > gameConfig.npcRidlimit))

    items.button:setTouchPriority(-102)
    items.button:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end     
        if not self.isscrolltouched then return end

        print("status===",status)
        print("self.myData.athletics===",self.myData.athletics)
        gameTouch:clickprofbytime(0.5)
         if status == 0 then
             if data.rid <gameConfig.npcRidlimit then
                GameScene:addtempLayers("other_slotinfo",data)
             end
         elseif status == 1 or status == 2 then
             if self.myData.athletics <=0 then
                 shortathletics()
             else
                UIRequest({type = 1611, rank = data,isFight = isPlayFight})
             end
         elseif status == 3 then
             UIRequest({type = 1610})
         end

    end, CCControlEventTouchUpInside)

    --
    local config = gamedata.config.athletics_rewards or {}
    local day = {}
    local dayreward = {}
    for k,v in pairs(config) do
        table.insert(day,v)
    end
    local sortById = function(a,b) return a.rank > b.rank end
    table.sort(day, sortById)
    for k,v in ipairs(day) do
        if data.rank <= v.rank then
            dayreward = v.day
        end
    end
    --
    items.num1:setString("?")
    items.num3:setString("?")
    local rewards = ui.getIDandNUMs(dayreward) or {}
    for k,v in pairs(rewards) do
        if v.cid == 1005 then
            items.num1:setString(v.num or "?")
        elseif v.cid == 1000 then
            items.num3:setString(v.num or "?")
        end
    end
    --
end

function sports.setRewardCell(self,data,items)

    --todo
    --part
    if items.duanNode then
        ui.setWudaoPart(items,data.part_point or 0)
    end

    local config = gamedata.config.athletics_rewards2[tostring(data.id)]
    print("i..config...:")
    printT(config)
    if (config.buttontype == 1) and (config.limit and config.limit > 0) then
        if data.status == -1 then
            items.desc:setString(gameConfig.strings:butStates(config.limit))
        else
            items.desc:setString(gameConfig.strings:butStates(config.limit-data.status))
        end
        -- items.desc:setString("今日还可购买"..(config.limit-data.status).."次")
    else
        items.desc:setString("")
    end

    if config.buttontype == 1 then
        if config.rank == 0 then
            items.buynum:setVisible(false)
            items.buynumText:setVisible(false)
        end
        items.buynum:setString(config.rank)
        -- items.desc:setString(gameConfig.strings:string_common("sports",9))
        items.prestige:setString(config.prestige)
        items.prestigeSprite:setVisible(true)
        setControlButtonFrame(items.exchange,"b_s_button2","b_s_button2_h","b_s_button2")
    else
        -- items.desc:setString("需要达到排名")
        -- items.desc:setString(gameConfig.strings:string_common("sports",10))
        items.prestige:setString(config.rank)
        items.prestigeSprite:setVisible(false)
        setControlButtonFrame(items.exchange,"b_s_button1","b_s_button1_h","b_s_button1")
    end


    local id,num = ui.getIDandNUM(config.reward)

    local propConfig =  ui.IDconfig(id)

    items.propname:setString(config.name)
    ui.setLabelString(items.propname,nil,(propConfig.quality>1 and propConfig.quality or 1)*2-1)

    ui.setNewIcon(items,{cid = id, num = num})
    --
    items["i_button"]:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end

        ui.setPopwindowByCid(id)
    end, CCControlEventTouchUpInside)
    items["i_button"]:setTouchPriority(-102)
    --

    if config.buttontype == 1 then
        -- items.exchangeText:setString("兑换")
        items.exchangeText:setString(gameConfig.strings:string_common("sports",2))
    else
        -- items.exchangeText:setString("领取")
        items.exchangeText:setString(gameConfig.strings:string_common("sports",7))
    end
    ui.setLabelString(items.exchangeText,nil,18)

    items.exchange:setTouchPriority(-102)
    items.exchange:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        if not self.isscrolltouched then return end
        gameTouch:clickprofbytime(0.5)

        if (config.buttontype == 1) and (self.myData.prestige < config.prestige) then
            -- runGamePrompt({msg = "积分不足"})
            runGamePrompt({msg = gameConfig.strings:string_common("sports",11)})
        elseif (config.buttontype == 1) and (config.limit and config.limit > 0) and (data.status >= config.limit) then
            -- runGamePrompt({msg = "超出兑换次数限制"})
            runGamePrompt({msg = gameConfig.strings:string_common("sports",12)})
        elseif (config.buttontype == 2) and (data.status < 2) then
            -- runGamePrompt({msg = "未达到领取条件"})
            runGamePrompt({msg = gameConfig.strings:string_common("sports",13)})
        else
            UIRequest({type = 1614, id = data.id,num = 1})
        end

    end, CCControlEventTouchUpInside)


    if (config.buttontype == 1) and (self.myData.prestige < config.prestige) then
        ui.addGray("CCControlButton",items.exchange)
        ui.addGray("CCLabelTTF",items.exchangeText)
    elseif (config.buttontype == 1) and (config.limit and config.limit > 0) and (data.status >= config.limit) then
        ui.addGray("CCControlButton",items.exchange)
        ui.addGray("CCLabelTTF",items.exchangeText)
    elseif (config.buttontype == 2) and (data.status < 2) then
        ui.addGray("CCControlButton",items.exchange)
        ui.addGray("CCLabelTTF",items.exchangeText)
    else
        ui.removeGray("CCControlButton",items.exchange)
        ui.removeGray("CCLabelTTF",items.exchangeText)
    end


end

function sports.createRankList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("n_sports2/cell_n_sports2_rank.ccbi", nil, true, "rankcell")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.rankListTableView,cellCCB,self.rankCellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setRankCell(self.rankData[tostring(a1+1)],ccbDocumentControler)

            if self.rankListTableView then
                cellCCB:setPosition(self.rankCellSize.x/2, 0)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.rankData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.rankListTableView = ui.createLuaTableView({
        handle = rankListHandle,
        viewwidth = self.rootItems.rankSroll:getContentSize().width,
        viewheight = self.rootItems.rankSroll:getContentSize().height,
        dire = 1
    })
    self.rankListTableView:setTouchPriority(-101)
    self.rootItems.rankSroll:addChild(self.rankListTableView)
end

function sports.createTop10List(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("n_sports2/cell_n_sports2_rank2.ccbi", nil, true, "rankcell")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.top10ListTableView,cellCCB,self.rankCellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setRankCell(self.top10Data[tostring(a1+1)],ccbDocumentControler,true)

            if self.top10ListTableView then
                cellCCB:setPosition(self.rankCellSize.x/2, 0)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.top10Data)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.top10ListTableView = ui.createLuaTableView({
        handle = rankListHandle,
        viewwidth = self.rootItems.top10Sroll:getContentSize().width,
        viewheight = self.rootItems.top10Sroll:getContentSize().height,
        dire = 1
    })
    self.top10ListTableView:setTouchPriority(-101)
    self.rootItems.top10Sroll:addChild(self.top10ListTableView)
end

function sports.createRewardList(self)
    local celldict = {}
    local rankListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.rewardCellSize.x, self.rewardCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("n_sports2/cell_n_sports2_prop.ccbi", nil, true, "propcell")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.rewardListTableView,cellCCB,self.rewardCellSize.x/2, 14,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setRewardCell(self.rewardData[tostring(a1+1)],ccbDocumentControler)

            if self.rewardListTableView then
                cellCCB:setPosition(self.rewardCellSize.x/2, 14)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.rewardData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.rewardListTableView = ui.createLuaTableView({
        handle = rankListHandle,
        viewwidth = self.rootItems.rewardScroll:getContentSize().width,
        viewheight = self.rootItems.rewardScroll:getContentSize().height,
        dire = 1
    })
    self.rewardListTableView:setTouchPriority(-101)
    self.rootItems.rewardScroll:addChild(self.rewardListTableView)
end

function sports.createFirstRewardList(self)
    local celldict = {}
    local rankListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.firstrewardCellSize.x, self.firstrewardCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("n_sports2/cell_n_sports2_first.ccbi", nil, true, "cell_n_sports2_first")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.firstrewardListTableView,cellCCB,self.firstrewardCellSize.x/2, 14,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local config = self.firstRewardTempData[tonumber(a1 + 1)]

            ccbDocumentControler.rankNumLabel:setString(config.rank)

            
            if self.firstRewardData[tostring(a1+1)] == 0 then
                ccbDocumentControler.noneNode:setVisible(true)
                ccbDocumentControler.getNode:setVisible(false)
            else
                ccbDocumentControler.noneNode:setVisible(false)
                ccbDocumentControler.getNode:setVisible(true)
            end
            

            local prop = ui.getIDandNUMs(config.reward)

            for i=1,5 do
                if i < #prop or i == #prop then
                    ui.setNewIcon(ccbDocumentControler,prop[i],i-1)
                else
                    ccbDocumentControler["ccbitem"..i]:setVisible(false)
                end
            end


            if self.firstrewardListTableView then
                cellCCB:setPosition(self.firstrewardCellSize.x/2, 14)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(gamedata.config.athletics_rewards3)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.firstrewardListTableView = ui.createLuaTableView({
        handle = rankListHandle,
        viewwidth = self.rootItems.firstScroll:getContentSize().width,
        viewheight = self.rootItems.firstScroll:getContentSize().height,
        dire = 1
    })
    self.firstrewardListTableView:setTouchPriority(-101)
    self.rootItems.firstScroll:addChild(self.firstrewardListTableView)
end



function sports.relaodRank(self,rankData,top10Data,myData,athletics_boss)
    if rankData then
        self.rankData = rankData
    end
    if top10Data then
        self.top10Data = top10Data
    end
    if myData then
        self.myData = myData
    end
    if athletics_boss then
        self.athletics_boss = athletics_boss
    end
    --
    local myindex = 1
    for k,v in pairs(self.rankData) do
        if v.rank < self.myData.rank then
            myindex = myindex + 1
        end
        if v.rank == self.myData.rank then
            ui.setLabelString(self.rootItems.fightNum,v.power,13)
        end
    end
    --

    local athleticsbossmax = 0
    if gamedata.config.global_kv["athletics_top_"..self.myData.rank.."_boss"] then
        athleticsbossmax = tonumber(gamedata.config.global_kv["athletics_top_"..self.myData.rank.."_boss"].value)
    end

    self.rootItems.rank:setString(self.myData.rank)
    self.rootItems.prestige:setString(self.myData.prestige)
    self.rootItems.challenge:setString(self.myData.athletics)

    --
    local config = gamedata.config.athletics_rewards or {}
    local day = {}
    local dayreward = {}
    for k,v in pairs(config) do
        table.insert(day,v)
    end
    local sortById = function(a,b) return a.rank > b.rank end
    table.sort(day, sortById)
    for k,v in ipairs(day) do
        if self.myData.rank <= v.rank then
            dayreward = v.day
        end
    end
    --
    self.rootItems.num1:setString("?")
    self.rootItems.num2:setString("?")
    self.rootItems.num3:setString("?")
    local rewards = ui.getIDandNUMs(dayreward) or {}
    for k,v in pairs(rewards) do
        if v.cid == 1005 then
            self.rootItems.num1:setString(v.num or "?")
        elseif v.cid == 1001 then
            self.rootItems.num2:setString(v.num or "?")
        elseif v.cid == 1000 then
            self.rootItems.num3:setString(v.num or "?")
        end
    end
    --
    ui.setLabelString(self.rootItems.rank,nil,13)
    ui.setLabelString(self.rootItems.prestige,nil,13)
    ui.setLabelString(self.rootItems.challenge,nil,13)
    ui.setLabelString(self.rootItems.num1,nil,13)
    ui.setLabelString(self.rootItems.num2,nil,13)
    ui.setLabelString(self.rootItems.num3,nil,13)
    --
    if self.rootItems.nmtwdesc then
        ui.setLabelString(self.rootItems.nmtwdesc,nil,24)
    end
    ui.setLabelString(self.rootItems.kickbossLab,gameConfig.strings:string_common("sports",4),19)
    self.rootItems.kickbossButton:setTouchPriority(-102)
    self.rootItems.kickbossButton:addHandleOfControlEvent(function()
        print("isscrolltouched===",self.isscrolltouched)

        -- if not self.isscrolltouched then return end
        print("num===",self.athletics_boss,athleticsbossmax,self.myData.athletics)
        if self.athletics_boss+1 > athleticsbossmax then
            runGamePrompt({msg = gameConfig.strings:string_common("sports",18)})
        elseif self.myData.athletics <=0 then
            shortathletics()
        else
            UIRequest({type = 1616})
        end
    end, CCControlEventTouchUpInside)

    if self.athletics_boss+1 > athleticsbossmax then
        ui.addGray("CCControlButton",self.rootItems.kickbossButton)
        ui.addGray("CCLabelTTF",self.rootItems.kickbossLab)
    else
        ui.removeGray("CCControlButton",self.rootItems.kickbossButton)
        ui.removeGray("CCLabelTTF",self.rootItems.kickbossLab)
    end

    if self.myData.rank <= 5 then
        self.rootItems.kickbossNode:setVisible(true)
        print("剩余次数＝＝＝",athleticsbossmax-self.athletics_boss)
        self.rootItems.kickbossnum:setString("剩余次数: "..((athleticsbossmax-self.athletics_boss)>0 and (athleticsbossmax-self.athletics_boss) or 0).."/"..athleticsbossmax)
        ui.setLabelString(self.rootItems.kickbossnum,nil,111)
    else
        self.rootItems.kickbossNode:setVisible(false)
    end

    if self.selectpage == "rank" then
        if not self.rankListTableView then
            self:createRankList()
            if myindex*self.rankCellSize.y > self.rootItems.rankSroll:getContentSize().height then
                self.rankListTableView:setLuaContentOffset(0, 0 - (table.getTableLength(self.rankData)-myindex)*self.rankCellSize.y)
            else
                self.rankListTableView:setLuaContentOffset(0, self.rootItems.rankSroll:getContentSize().height - table.getTableLength(self.rankData)*self.rankCellSize.y)
            end
        else
            if myindex*self.rankCellSize.y > self.rootItems.rankSroll:getContentSize().height then
                self.rankListTableView:setLuaContentOffset(0, 0 - (table.getTableLength(self.rankData)-myindex)*self.rankCellSize.y)
            else
                self.rankListTableView:setLuaContentOffset(0, self.rootItems.rankSroll:getContentSize().height - table.getTableLength(self.rankData)*self.rankCellSize.y)
            end
            self.rankListTableView:reloadData()
        end
    elseif self.selectpage == "top10" then
        if not self.top10ListTableView then
            self:createTop10List()
        else
            self.top10ListTableView:reloadData()
        end
    end

end

function sports.relaodRewards(self,rewardData)
    if rewardData then
        self.rewardData = rewardData
    end

    if not self.rewardListTableView then
        self:createRewardList()
    else
        if self.rewardListTableView:getLuaContentOffsetY() < self.rootItems.rewardScroll:getContentSize().height - table.getTableLength(self.rewardData)*self.rewardCellSize.y then
            self.rewardListTableView:setLuaContentOffset(0, self.rootItems.rewardScroll:getContentSize().height - table.getTableLength(self.rewardData)*self.rewardCellSize.y-14)
        end
        self.rewardListTableView:reloadData()
    end
end


function sports.relaodRankStatus(self,data)
    if data then
        self.firstRewardData = data
    end

    if not self.firstrewardListTableView then
        self:createFirstRewardList()
    else
        self.firstrewardListTableView:reloadData()
    end
end

function sports.shiftPage(self,type)
    self.selectpage = type

    for k,v in ipairs(self.pageconfig) do
        if v == type then
            self.rootItems[v.."Node"]:setVisible(true)
            self.rootItems[v.."Node"]:setPositionX(0)
        else
            self.rootItems[v.."Node"]:setVisible(false)
            self.rootItems[v.."Node"]:setPositionX(9999)
        end
    end

    if self.selectpage == "rank" then
        if not self.rankData or not next(self.rankData) then
            UIRequest({type =1610})
        elseif not self.rankListTableView then
            self:createRankList()
        else
            self.rankListTableView:reloadData()
        end
    elseif self.selectpage == "top10" then
        if not self.top10Data or not next(self.top10Data) then
            UIRequest({type =1610})
        elseif not self.top10ListTableView then
            self:createTop10List()
            print("top10.create===")
        else
            print("top10.refresh===")
            self.top10ListTableView:reloadData()
        end
    elseif self.selectpage == "reward" then
        if not self.rewardData or not next(self.rewardData) then
            UIRequest({type = 1613})
        elseif not self.rewardListTableView then
            self:createRewardList()
        else
            self.rewardListTableView:reloadData()
        end
    elseif self.selectpage == "first" then
        print("i...am..first:")

        if not self.firstRewardData or not next(self.firstRewardData) then
            UIRequest({type = 1615})
        elseif not self.firstrewardListTableView then
            self:createFirstRewardList()
        else
            self.firstrewardListTableView:reloadData()
        end
        
    end
end

function sports.clear(self)
    self.selectpage = "rank"
    self.athletics_boss = 0
    self.firstRewardTempData = nil
    self.firstRewardData = nil
    self.rankData = nil
    self.top10Data = nil
    self.rewardData = nil
    self.myData = nil
    self.rankListTableView = nil
    self.top10ListTableView = nil
    self.rewardListTableView = nil
    self.firstrewardListTableView = nil
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    gameTouch:UnrigistFunc("begin","sports")
    gameTouch:UnrigistFunc("end","sports")    
end

function sports.UIUpdateData(self, isreset)
    if isreset then
        self:shiftPage(self.selectpage)
    end
end


return sports