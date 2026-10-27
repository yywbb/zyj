--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/1/30
-- Time: 下午4:37
-- To change this template use File | Settings | File Templates.
--


local daily = {

    resource = nil,

    rootNode = nil,
    rootItems = nil,
    ListTableView = nil,
    ListTableViewTwo = nil,
    ListTableViewThree = nil,

    statusdata = {},
    config = {},
    configTwo = {},
    configThree = {},

    hintext = {
        [24] = {24,25,26},
        [25] = {24,25,26},
        [26] = {24,25,26},
        [175] = {175,573},
    },


    -- 活动时间
    begintimenum = {week=3,hour=20,min=30,sec=0},
    endtimenum = {week=3,hour=21,min=0,sec=0},
    finaltimenum = {week=3,hour=21,min=10,sec=0},


    -- 王者之战时间
    kingBegintimenum = {week=1,hour=0,min=0,sec=0},
    kingEndtimenum = {week=1,hour=24,min=0,sec=0},

    isopen = false,

    servicewaropen = false,

    kingBattleOpen = false,
    kingTimeStatus = 0,
    kingIsopen = false,

    -- pageconfig = {"jingji","qiqu"} ,
    -- pagename = {"人界","仙界"},
    -- selectpage = "jingji",

    pageconfig = {"richang","shilian","jingji"} ,
    pagename = {"日常","试炼","竞技"},
    selectpage = "richang",

    presentPage = 1,
    contentCellSize = {x= 1080,y=432}
}

function daily.makeConfig(self)
    self.config = {}
    self.configTwo = {}
    self.configThree = {}

    for i=1, table.getTableLength(gamedata.config.daily) do
        if gamedata.config.daily[tostring(i)].table == 1 then
            table.insert(self.config,gamedata.config.daily[tostring(i)])
        elseif gamedata.config.daily[tostring(i)].table == 2 then
            table.insert(self.configTwo,gamedata.config.daily[tostring(i)])
        elseif gamedata.config.daily[tostring(i)].table == 3 then
            table.insert(self.configThree,gamedata.config.daily[tostring(i)])
        end
    end

    -- if #self.configTwo == 0 then
    --     self.pageconfig = {"richang"}
    -- end
end

function daily.setPageTitleShow( self)
    for i,v in ipairs(self.pageconfig) do
        if v == self.selectpage then
            setSpriteFrameByName(self.rootItems["buttonsprite"..i], gameConfig.images.pageButtonON)
        else
            setSpriteFrameByName(self.rootItems["buttonsprite"..i], gameConfig.images.pageButtonOFF)
        end
    end
end

function daily.shiftPage(self,type,isfirst)
    self.selectpage = type or self.selectpage

    for i,v in ipairs(self.pageconfig) do
        if v == self.selectpage then
            self:setPage(i,isfirst)
            break
        end
    end
    
end

function daily.init(self,parent,toppos)
    self.rootNode,self.rootItems = CCBReaderLoad("daily/daily", nil, true, "daily")

    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.listScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-180-120-440))
    self.rootItems.listScrollTwo:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-180-120-440))
    self.rootItems.listScrollThree:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-180-120-440))

    self:makeConfig()
    -- self.config = gamedata.config.daily

    -- 武道会时间设置与判断
    self:setTimeData()

    -- 王者之战时间设置与判断
    self:setKingBattleTimeData()

    --
    local servicewarday = gamedata.config.global_kv.cross_battle_openday and tonumber(gamedata.config.global_kv.cross_battle_openday.value) or 0
    if (gamedata:time() - GameScene.roleinfo.servertime) > servicewarday*86400 then
        self.servicewaropen = true
    else
        self.servicewaropen = false
    end
    --

    --
    local kingBattleday = (gamedata.config.king_config and gamedata.config.king_config.king_server_start_time) and tonumber(gamedata.config.king_config.king_server_start_time.value) or 0
    local kingBattleOpenDay = (gamedata.config.king_config and gamedata.config.king_config.king_start_time) and tonumber(gamedata.config.king_config.king_start_time.value) or 0
    local kingNowtime = os.date("*t", GameScene.roleinfo.servertime+kingBattleday*86400)
    local kingDaynums = (kingNowtime.wday == 1 and 7 or (kingNowtime.wday-1))
    if (gamedata:time() - GameScene.roleinfo.servertime) > (kingBattleday+7)*86400 then
        self.kingBattleOpen = true
    elseif (gamedata:time() - GameScene.roleinfo.servertime) > kingBattleday*86400 then
        
        local kingNowtime2 = os.date("*t", gamedata:time())
        local kingDaynums2 = (kingNowtime2.wday == 1 and 7 or (kingNowtime2.wday-1))    
        if kingDaynums > kingBattleOpenDay then
            local time1 = GameScene.roleinfo.servertime + kingBattleday*86400 - (kingDaynums-kingBattleOpenDay)*86400
            local time2 = GameScene.roleinfo.servertime + kingBattleday*86400 - (kingDaynums-kingBattleOpenDay)*86400+7*86400
            if (gamedata:time() > time1) and (gamedata:time() < time2) then
                self.kingBattleOpen = false
                self.kingTimeStatus = 0
            else
                self.kingBattleOpen = true
            end
        else
            if kingDaynums2 >= kingBattleOpenDay then
                self.kingBattleOpen = true
            else
                self.kingBattleOpen = false
                self.kingTimeStatus = 0
            end
        end
    else
        self.kingBattleOpen = false
        self.kingTimeStatus = 1
    end

    

    -- if self.selectpage == self.pageconfig[1] then
    if self.ListTableView then
        self.ListTableView:reloadData()
    else
        self:createList()
    end
    -- elseif self.selectpage == self.pageconfig[2] then
    if self.ListTableViewTwo then
        self.ListTableViewTwo:reloadData()
    else
        self:createListTwo()
    end
    -- end
    if self.ListTableViewThree then
        self.ListTableViewThree:reloadData()
    else
        self:createListThree()
    end
    

    --UIRequest({type = 1200})
    self:setHint()
    self:setPageView()

    self:shiftPage(nil,true)
end

function daily.setPageView(self)
    self.rootItems.pageview = tolua.cast(self.rootItems.pageview, "CCScrollView")
    -- self.rootItems.pageview:setTouchPriority(-102)
    self.rootItems.pageview:setTouchEnabled(false)

    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.touchLayer,x,y) then

            self.isContentScroll = false
            self.touchX = x
            self.touchY = y
            self.pagemoved = false
            self.contentoffsetx = self.rootItems.pageview:getContentOffset().x
            return true
        end
    end

    local function ccTouchMoved(x, y)
        if math.abs(x - self.touchX) > 10 then
            self.isContentScroll = true
        end

        if math.abs(x - self.touchX) > 30 and math.abs(y - self.touchY)/math.abs(x - self.touchX) <0.3 then
            self.pagemoved = true
            local offsetX = self.contentoffsetx + (x - self.touchX)
            self.rootItems.pageview:setContentOffset(ccp(offsetX, self.rootItems.pageview:getContentOffset().y))
        end
    end

    local function ccTouchEnded(x, y)
        local moveX = self.touchX -x
        print("moveX",moveX)

        if moveX > 100 and self.pagemoved then
            if self.presentPage+1 <= 3 then
                self:setPage(self.presentPage+1)
            else
                self:setPage(self.presentPage)
            end
        elseif moveX < -100 and self.pagemoved then
            if self.presentPage-1 >0 then
                self:setPage(self.presentPage-1)
            else
                self:setPage(self.presentPage)
            end
        else
            self:setPage(self.presentPage)
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

    self.rootItems.touchLayer:registerScriptTouchHandler(onTouch, false, -105, false)
    self.rootItems.touchLayer:setTouchPriority(-105)
    self.rootItems.touchLayer:setTouchEnabled(true)
end

function daily.setPage(self,page,first)
    self.presentPage = page
    print("setPage",self.presentPage,first)
    self.selectpage = self.pageconfig[self.presentPage]

    local endfunc = function ()
        if self.selectpage == self.pageconfig[1] then
            self.rootItems.listScroll:setPositionX(0)
            self.rootItems.listScrollTwo:setPositionX(9999)
            self.rootItems.listScrollThree:setPositionX(9999)

            self.ListTableView:reloadData()
        elseif self.selectpage == self.pageconfig[2] then
            self.rootItems.listScroll:setPositionX(9999)
            self.rootItems.listScrollTwo:setPositionX(0)
            self.rootItems.listScrollThree:setPositionX(9999)

            self.ListTableViewTwo:reloadData()
            
        elseif self.selectpage == self.pageconfig[3] then
            self.rootItems.listScroll:setPositionX(9999)
            self.rootItems.listScrollTwo:setPositionX(9999)
            self.rootItems.listScrollThree:setPositionX(0)

            self.ListTableViewThree:reloadData()
        end
        self:setPageTitleShow()
    end

    if first then
        self.rootItems.pageview:setContentOffset(ccp(-(self.presentPage-1) * self.contentCellSize.x, self.rootItems.pageview:getContentOffset().y))
        endfunc()
    else
        local moveto = CCMoveTo:create(0.2, ccp(-self.contentCellSize.x*(self.presentPage-1), 0))
        self.rootItems.container:runAction(CCSequence:createWithTwoActions(moveto,CCCallFunc:create(function()
            endfunc()
        end)))
    end
    
end

function daily.setHint(self)
    local hint = false
    for i,v in ipairs(self.config) do
        local config = v
        if self.hintext[config.systemid] then
            for k,v in pairs(self.hintext[config.systemid]) do
                if GameScene.hintdata[tostring(v)] and GameScene.hintdata[tostring(v)] ~= 0 then
                    hint = true
                    break
                end
            end
        else
            if tonumber(config.systemid) == 613 then
                if GameScene.hintdata["614"] and GameScene.hintdata["614"] ~= 0 then
                    hint = true
                end
                if GameScene.hintdata["615"] and GameScene.hintdata["615"] ~= 0 then
                    hint = true
                end
            else
                hint = GameScene.hintdata[tostring(config.systemid)] and GameScene.hintdata[tostring(config.systemid)] ~= 0
            end
        end
        if hint then
            break
        end
    end
    ui.sethint(self.rootItems["hint_title1"],hint)

    local hint2 = false
    for i,v in ipairs(self.configTwo) do
        local config = v
        if self.hintext[config.systemid] then
            for k,v in pairs(self.hintext[config.systemid]) do
                if GameScene.hintdata[tostring(v)] and GameScene.hintdata[tostring(v)] ~= 0 then
                    hint2 = true
                    break
                end
            end
        else
            hint2 = GameScene.hintdata[tostring(config.systemid)] and GameScene.hintdata[tostring(config.systemid)] ~= 0
        end
        if hint2 then
            break
        end
    end
    ui.sethint(self.rootItems["hint_title2"],hint2)

    local hint3 = false
    for i,v in ipairs(self.configThree) do
        local config = v
        if self.hintext[config.systemid] then
            for k,v in pairs(self.hintext[config.systemid]) do
                if GameScene.hintdata[tostring(v)] and GameScene.hintdata[tostring(v)] ~= 0 then
                    hint3 = true
                    break
                end
            end
        else
            hint3 = GameScene.hintdata[tostring(config.systemid)] and GameScene.hintdata[tostring(config.systemid)] ~= 0
        end
        if hint3 then
            break
        end
    end
    ui.sethint(self.rootItems["hint_title3"],hint3)

end

function daily.clear(self)
    self.ListTableView = nil
    self.ListTableViewTwo = nil
    self.ListTableViewThree = nil

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.isopen = false
    self.kingIsopen = false
    self.kingBattleOpen = false
    self.kingTimeStatus = 0
end

function daily.ReloadData(self,data)
    print("ReloadPropsData")

    self.statusdata = data

    if self.selectpage == self.pageconfig[1] then
        if self.ListTableView then
            self.ListTableView:reloadData()
        else
            self:createList()
        end
    elseif self.selectpage == self.pageconfig[2] then
        if self.ListTableViewTwo then
            self.ListTableViewTwo:reloadData()
        else
            self:createListTwo()
        end
    elseif self.selectpage == self.pageconfig[3] then
        if self.ListTableViewThree then
            self.ListTableViewThree:reloadData()
        else
            self:createListThree()
        end
    end
    
end

function daily.setone(self,data,items,index)
    local key_Ex
    local icon_key
    if index == nil or index == 1 then
        key_Ex = ""
    else
        key_Ex = "2"
    end

    if not data then
        return
    end

    items["openlab"..key_Ex]:setVisible(false)
    items["open2lab"..key_Ex]:setVisible(false)
    if not GameScene:checkopenlevelbyId(data.systemid,true) then
        setSpriteFrameByName(items["bg"..key_Ex], data.bgname)
        setControlButtonFrame(items["button"..key_Ex],"alpha","alphang","alpha")
        items["opennode"..key_Ex]:setVisible(true)
        items["bg"..key_Ex]:setColor(ccc3(170,170,170))
        items["hint"..key_Ex]:setVisible(false)
        ui.setLabelString(items["openlevel"..key_Ex],gamedata.config.build[tostring(data.systemid)].level or "?",14)
        ui.setLabelString(items["openlab"..key_Ex],"开启等级: ",14)
        items["openlab"..key_Ex]:setVisible(true)
    else
        items["opennode"..key_Ex]:setVisible(false)
        setControlButtonFrame(items["button"..key_Ex],data.bgname,data.bgname,data.bgname)

        local hint = false
        if self.hintext[data.systemid] then
            for k,v in pairs(self.hintext[data.systemid]) do
                if GameScene.hintdata[tostring(v)] and GameScene.hintdata[tostring(v)] ~= 0 then
                    hint = true
                    break
                end
            end
        else
            hint = GameScene.hintdata[tostring(data.systemid)] and GameScene.hintdata[tostring(data.systemid)] ~= 0
        end
    
        if tonumber(data.systemid) == 380 then
            if GameScene.hintdata[tostring(404)] and GameScene.hintdata[tostring(404)] ~= 0 then
                hint = true
            end
            if GameScene.hintdata[tostring(425)] and GameScene.hintdata[tostring(425)] ~= 0 then
                hint = true
            end
        end

        if tonumber(data.systemid) == 613 or tonumber(data.systemid) == 614 then
            if GameScene.hintdata[tostring(614)] and GameScene.hintdata[tostring(614)] ~= 0 then
                hint = true
            end
            if GameScene.hintdata[tostring(615)] and GameScene.hintdata[tostring(615)] ~= 0 then
                hint = true
            end
        end
    
        ui.sethint(items["hint"..key_Ex],hint)
    end

    -- 新字标
    items["new"..key_Ex]:removeAllChildrenWithCleanup(true)
    if guide.controller then
        if tonumber(data.systemid) == 613 then
            data.systemid = 614
        end
        if guide.controller:isNewSystemByid(data.systemid) and GameScene:checkopenlevelbyId(data.systemid,true) then
            local ccb,Items = CCBReaderLoad("talk/new", nil, true, "new")
            items["new"..key_Ex]:addChild(ccb)
        end
    end

    items["descText"..key_Ex]:setVisible(false)
    if tonumber(data.systemid) == 191 then
        local tempconfig = gamedata.config.wudao_time
        printT(tempconfig,"tempconfig == ")
        ui.setLabelString(items["descText"..key_Ex],tempconfig[tostring(1)].desc or "",23)
        items["descText"..key_Ex]:setVisible(true)
    end

    if tonumber(data.systemid) == 212 and not self.servicewaropen then
        local servicewarday = gamedata.config.global_kv.cross_battle_openday and tonumber(gamedata.config.global_kv.cross_battle_openday.value) or 0
        setSpriteFrameByName(items["bg"..key_Ex], data.bgname)
        setControlButtonFrame(items["button"..key_Ex],"alpha","alphang","alpha")
        items["opennode"..key_Ex]:setVisible(true)
        items["bg"..key_Ex]:setColor(ccc3(170,170,170))
        items["hint"..key_Ex]:setVisible(false)
        ui.setLabelString(items["openlevel"..key_Ex],"",14)
        ui.setLabelString(items["open2lab"..key_Ex],"开服"..servicewarday.."天后开启",14)
        items["open2lab"..key_Ex]:setVisible(true)
    end

    if tonumber(data.systemid) == 355 then
        ui.setLabelString(items["descText"..key_Ex],"每日 11:00~13:00\n 20:00~22:00 开启",23)
        items["descText"..key_Ex]:setVisible(true)
    end

    if tonumber(data.systemid) == 380 and not self.kingBattleOpen then
        local kingBattleday = (gamedata.config.king_config and gamedata.config.king_config.king_server_start_time) and tonumber(gamedata.config.king_config.king_server_start_time.value) or 0
        setSpriteFrameByName(items["bg"..key_Ex], data.bgname)
        setControlButtonFrame(items["button"..key_Ex],"alpha","alphang","alpha")
        items["opennode"..key_Ex]:setVisible(true)
        items["bg"..key_Ex]:setColor(ccc3(170,170,170))
        items["hint"..key_Ex]:setVisible(false)
        ui.setLabelString(items["openlevel"..key_Ex],"",14)
        if self.kingTimeStatus == 1 then
            ui.setLabelString(items["open2lab"..key_Ex],"开服"..kingBattleday.."天后开启",14)
        else
            ui.setLabelString(items["open2lab"..key_Ex],"赛季中途不能进入",14)
        end
        items["open2lab"..key_Ex]:setVisible(true)

        local kingbattleTimeConfig = gamedata.config.king_time
        ui.setLabelString(items["descText"..key_Ex],kingbattleTimeConfig[tostring(1)].desc,23)
        items["descText"..key_Ex]:setVisible(true)
    end

    items["button"..key_Ex]:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end

        if tonumber(data.systemid) == 191 and self.isopen == false then
            runGamePrompt({msg = "不在活动时间内"})
            return
        end

        if tonumber(data.systemid) == 212 and not self.servicewaropen then
            local servicewarday = gamedata.config.global_kv.cross_battle_openday and tonumber(gamedata.config.global_kv.cross_battle_openday.value) or 0
            runGamePrompt({msg = "开服"..servicewarday.."天后开启"})
            return
        end

        if tonumber(data.systemid) == 355 then
            local times = GameScene.layers["daoGuanMain"].module:gettimes()
            if times then
                if times.now<times.open then
                    runGamePrompt({msg="即将开启！"})
                    return
                end
            else
                runGamePrompt({msg="不在活动时间内"})
                return
            end 
        end

        if tonumber(data.systemid) == 380 then
            if not self.kingBattleOpen then
                if self.kingTimeStatus == 1 then
                    local kingBattleday = (gamedata.config.king_config and gamedata.config.king_config.king_server_start_time) and tonumber(gamedata.config.king_config.king_server_start_time.value) or 0
                    runGamePrompt({msg = "开服"..kingBattleday.."天后开启"})
                else
                    runGamePrompt({msg = "赛季中途不能进入游戏"})
                end
                return
            end
            if self.kingIsopen == false then
                runGamePrompt({msg = "不在活动时间内"})
                return
            end
        end

        GameScene:shiftLayerById(data.systemid)

    end, CCControlEventTouchUpInside)
    items["button"..key_Ex]:setTouchPriority(-102)
end

function daily.createList(self)
    print("createPropsList")

    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(1080, 320)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("daily/cell_daily", nil, true, "cell")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            ui.tableviewAnimation(self.ListTableView,cellCCB,1080/2,0,a1,true)

            self:setone(self.config[(a1+1)*2-1] or self.config[tostring((a1+1)*2-1)],ccbDocumentControler,1)

            if self.config[(a1+1)*2] or self.config[tostring((a1+1)*2)] then
                self:setone(self.config[(a1+1)*2] or self.config[tostring((a1+1)*2)],ccbDocumentControler,2)
                ccbDocumentControler.node2:setVisible(true)
            else
                ccbDocumentControler.node2:setVisible(false)
            end

            -- if self.ListTableView then
            --     cellCCB:setPosition(540,0)
            -- end

            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            -- r = table.getTableLength(self.config)
            r = math.ceil(table.getTableLength(self.config)/2)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listScroll:getContentSize().width,
        viewheight = self.rootItems.listScroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.listScroll:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(-1)
end

function daily.createListTwo(self)
    print("createListTwo")

    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(1080, 320)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("daily/cell_daily", nil, true, "cell")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            ui.tableviewAnimation(self.ListTableViewTwo,cellCCB,1080/2,0,a1,true)
            self:setone(self.configTwo[(a1+1)*2-1] or self.configTwo[tostring((a1+1)*2-1)],ccbDocumentControler,1)

            if self.configTwo[(a1+1)*2] or self.configTwo[tostring((a1+1)*2)] then
                self:setone(self.configTwo[(a1+1)*2] or self.configTwo[tostring((a1+1)*2)],ccbDocumentControler,2)
                ccbDocumentControler.node2:setVisible(true)
            else
                ccbDocumentControler.node2:setVisible(false)
            end

            -- if self.ListTableViewTwo then
            --     cellCCB:setPosition(1080/2,0)
            -- end

            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            -- r = table.getTableLength(self.configTwo)
            r = math.ceil(table.getTableLength(self.configTwo)/2)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ListTableViewTwo = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listScrollTwo:getContentSize().width,
        viewheight = self.rootItems.listScrollTwo:getContentSize().height,
        dire = 1
    })
    self.rootItems.listScrollTwo:addChild(self.ListTableViewTwo)
    self.ListTableViewTwo:setTouchPriority(-1)
end


function daily.createListThree(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(1080, 320)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("daily/cell_daily", nil, true, "cell")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            ui.tableviewAnimation(self.ListTableViewThree,cellCCB,1080/2,0,a1,true)
            self:setone(self.configThree[(a1+1)*2-1] or self.configThree[tostring((a1+1)*2-1)],ccbDocumentControler,1)

            if self.configThree[(a1+1)*2] or self.configThree[tostring((a1+1)*2)] then
                self:setone(self.configThree[(a1+1)*2] or self.configThree[tostring((a1+1)*2)],ccbDocumentControler,2)
                ccbDocumentControler.node2:setVisible(true)
            else
                ccbDocumentControler.node2:setVisible(false)
            end

            -- if self.ListTableViewThree then
            --     cellCCB:setPosition(1080/2,0)
            -- end


            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            -- r = table.getTableLength(self.configTwo)
            r = math.ceil(table.getTableLength(self.configThree)/2)
        elseif fn == "cellTouched" then
            
        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ListTableViewThree = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listScrollThree:getContentSize().width,
        viewheight = self.rootItems.listScrollThree:getContentSize().height,
        dire = 1
    })
    self.rootItems.listScrollThree:addChild(self.ListTableViewThree)
    self.ListTableViewThree:setTouchPriority(-1)
end

-- 判断为哪个活动倒计时
function daily.setTimeData( self )
    if gamedata.config.wudao_time and gamedata.config.wudao_time["1"] and gamedata.config.wudao_time["1"].open_week and gamedata.config.wudao_time["1"].open_week > 0 then
    else
        return
    end

    local nowtime = os.date("*t", gamedata:time())

    local daynums = (nowtime.wday == 1 and 7 or (nowtime.wday-1))

    local updatestatus = false
    -- printT(gamedata.config.wudao_time,"wudao_time====")
    for k,v in pairs(gamedata.config.wudao_time) do
        if tonumber(v.open_week) == daynums then
            local hour1,min1,sec1 = ui.getGangBattleTime(v["open_time"])
            local hour2,min2,sec2 = ui.getGangBattleTime(v["over_time"])
            local hour3,min3,sec3 = ui.getGangBattleTime(v["finaly_time"])
            print("hour1,min1,sec1==",hour1,min1,sec1)
            print("hour2,min2,sec2==",hour2,min2,sec2)

            self.begintimenum = {week=v["open_week"], hour=hour1, min=min1, sec=sec1}
            self.endtimenum = {week=v["open_week"], hour=hour2, min=min2, sec=sec2}
            self.finaltimenum = {week=v["open_week"], hour=hour3, min=min3, sec=sec3}
            updatestatus = true
            break
        end
    end
    if updatestatus == false then
        self.isopen = false
        return
    end


    self:judgeOpenType()
end


function daily.judgeOpenType( self )
    local nowtime = os.date("*t", gamedata:time())
    print("nowtime===")
    printT(nowtime)
    local daynums = (nowtime.wday == 1 and 7 or (nowtime.wday-1))
    local alltimes = (daynums - 1)*24*3600 + nowtime.hour*3600 + nowtime.min*60 + nowtime.sec - 1

    if self:gettimenum(self.begintimenum) <= alltimes and alltimes < self:gettimenum(self.endtimenum) then
        print("start====time")
        self.isopen = true
    elseif self:gettimenum(self.endtimenum) <= alltimes and alltimes < self:gettimenum(self.finaltimenum) then
        print("end====time")
        self.isopen = true
    else
        print("out====time")
        self.isopen = false
    end
end

-- 代入时间计算秒数
function daily.gettimenum(self,times,minnum)
    -- print("minnum===",minnum)
    local min = 0
    if minnum then
        min = minnum
    end
    local alltimes = 0
    alltimes = (times.week and (times.week-1) or 0)*24*3600 + (times.hour or 0)*3600 + times.min*60 + times.sec + min*60
    return alltimes
end


-- 判断为哪个活动倒计时
function daily.setKingBattleTimeData( self )
    if gamedata.config.king_time and gamedata.config.king_time["1"] and gamedata.config.king_time["1"].open_week and gamedata.config.king_time["1"].open_week > 0 then
    else
        return
    end

    local nowtime = os.date("*t", gamedata:time())
    local daynums = (nowtime.wday == 1 and 7 or (nowtime.wday-1))

    local updatestatus = false
    for k,v in pairs(gamedata.config.king_time) do
        if tonumber(v.open_week) == daynums then
            local hour1,min1,sec1 = ui.getGangBattleTime(v["open_time"])
            local hour2,min2,sec2 = ui.getGangBattleTime(v["over_time"])
            print("hour1,min1,sec1==",hour1,min1,sec1)
            print("hour2,min2,sec2==",hour2,min2,sec2)

            self.kingBegintimenum = {week=v["open_week"], hour=hour1, min=min1, sec=sec1}
            self.kingEndtimenum = {week=v["open_week"], hour=hour2, min=min2, sec=sec2}
            updatestatus = true
            break
        end
    end
    if updatestatus == false then
        self.kingIsopen = false
        return
    end

    self:judgeOpenType2()
end


function daily.judgeOpenType2( self )
    local nowtime = os.date("*t", gamedata:time())
    local daynums = (nowtime.wday == 1 and 7 or (nowtime.wday-1))
    local alltimes = (daynums - 1)*24*3600 + nowtime.hour*3600 + nowtime.min*60 + nowtime.sec - 1

    if self:gettimenum(self.kingBegintimenum) <= alltimes and alltimes < self:gettimenum(self.kingEndtimenum) then
        self.kingIsopen = true
    else
        self.kingIsopen = false
    end
end

return daily   }  