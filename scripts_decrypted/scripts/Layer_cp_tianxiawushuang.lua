

local sevendayactivity = {

    resource = nil,

    rootNode = nil,
    rootItems = nil,
    ListTableView = nil,
    buyListTableView = nil,
    powerListTableView = nil,

    selectday = 1,
    pageindex = {
        daily = 1,
        power = 2,
        level = 3,
        buy = 4,
    },
    taskconfig = {},
    dayconfig = {},
    buyconfig = {},
    showData = {},
    status = {},
    status2 = {},
    status3 = {},
    data = {},
    isinit = true,

    pageconfig = {"daily","power","level","buy"},
    pagename = {"","","",""},
    selectpage = "daily",
    hintconfig = {
        {
            name = "rootItems",
            type = "self",
            config = {
                day1 = {497,498,499,500},
                day2 = {501,502,503,504},
                day3 = {505,506,507,508},
                day4 = {509,510,511,512},
                day5 = {513,514,515,516},
                day6 = {517,518,519,520},
                day7 = {521,522,523,524},
            },
        },
    },


    normalCellSize = {x=1080,y=282+14},
    buyCellSize = {x=1080,y=226+14},
    gotoCellSize = {x=1080,y=228+14},  

    isnewcp = false,
    newcpnum = 0,

}

function sevendayactivity.shiftPage(self,type)
    local ispagechange = self.selectpage ~= type
    self.selectpage = type

    self:ReloadData(nil,ispagechange)
end

function sevendayactivity.init(self,parent,toppos,param)

    local fixh = 0
    self.rootNode,self.rootItems = CCBReaderLoad("start2/tianxiawushuang", nil, true, "dianfeng")
    fixh = 40

    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.targetday = nil
    if param and param.selectday then
        self.targetday = param.selectday
    end


    self.rootItems.topnode:setPositionY(toppos)

    self.rootItems.listScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-550-160-fixh))
    self.rootItems.buylistScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-550-160-fixh))
    self.rootItems.powerlistScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-550-160-fixh))

    ui.setLabelString(self.rootItems["timelab"..1],nil,121)
    ui.setLabelString(self.rootItems["timelab"..2],nil,26)
    ui.setLabelString(self.rootItems["timelab"..3],nil,121)
    ui.setLabelString(self.rootItems["timelab"..4],nil,27)
    

    for i = 1,7 do
        self.rootItems["isday"..i]:setVisible(false)
        self.rootItems["button_day"..i]:setTouchPriority(-102)
        self.rootItems["button_day"..i]:addHandleOfControlEvent(function()
        --            if self.day and self.day+0 < i then
        --                runGamePrompt({msg = "活动未开启"})
        --                return
        --            end
            local ispagechange = self.selectday ~= i
            self.selectday = i
            self:ReloadData(nil,ispagechange)
        end, CCControlEventTouchUpInside)
    end
    self.rootItems["isday"..self.selectday]:setVisible(true)
    --
    self.rootItems.button_help:setTouchPriority(-102)
    self.rootItems.button_help:addHandleOfControlEvent(function()
    --gameWindows:openWindow("startactivityhelp",{})
    --
    end, CCControlEventTouchUpInside)
    --

    self:request()
end

function sevendayactivity.clear(self)
    self.isnewcp = false
    self.newcpnum = 0
    self.isinit = true
    self.selectday = 1
    self.taskconfig = {}
    self.dayconfig = {}
    self.buyconfig = {}
    self.showData = {}
    self.data = {}
    self.status = {}
    self.status2 = {}
    self.status3 = {}
    self.rootItems = nil
    self.ListTableView = nil
    self.buyListTableView = nil
    self.powerListTableView = nil
    self.selectpage = "daily"

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function sevendayactivity.setGoto(self,item,data,index)

    item.title:setString(data.name)
    item.desc:setString(data.name)

    ui.setLabelString(item.gotoLab,nil,18)
    item.gotoButton:setTouchPriority(-103)
    item.gotoButton:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        gameTouch:clickprofbytime(1)
        --
        if data.systemid and data.systemid == 191 then
            if gamedata.config:getConfigByName("wudao_time") and gamedata.config:getConfigByName("wudao_time")["1"] and gamedata.config:getConfigByName("wudao_time")["1"].open_week and gamedata.config:getConfigByName("wudao_time")["1"].open_week > 0 then
                local nowtime = os.date("*t", gamedata:time())
                local daynums = (nowtime.wday == 1 and 7 or (nowtime.wday-1))
                local alltimes = (daynums - 1)*24*3600 + nowtime.hour*3600 + nowtime.min*60 + nowtime.sec - 1
                local isopen = false
                for k,v in pairs(gamedata.config:getConfigByName("wudao_time")) do
                    if tonumber(v.open_week) == daynums then
                        local hour1,min1,sec1 = ui.getGangBattleTime(v["open_time"])
                        local hour2,min2,sec2 = ui.getGangBattleTime(v["over_time"])
                        local hour3,min3,sec3 = ui.getGangBattleTime(v["finaly_time"])

                        local begintimenum = {week=v["open_week"], hour=hour1, min=min1, sec=sec1}
                        local endtimenum = {week=v["open_week"], hour=hour2, min=min2, sec=sec2}
                        local finaltimenum = {week=v["open_week"], hour=hour3, min=min3, sec=sec3}
                        --
                        if self:gettimenum(begintimenum) <= alltimes and alltimes < self:gettimenum(endtimenum) then
                            isopen = true
                        elseif self:gettimenum(endtimenum) <= alltimes and alltimes < self:gettimenum(finaltimenum) then
                            isopen = true
                        end
                    end
                end
                --
                if isopen then
                    GameScene:shiftLayerById(data.systemid)
                else
                    runGamePrompt({msg = "不在武道会开启时间内"})
                    return
                end
            else
                runGamePrompt({msg = "不在武道会开启时间内"})
                return
            end
        else
            GameScene:shiftLayerById(data.systemid)
        end
    --

    end, CCControlEventTouchUpInside)

    ui.setNewIcon(item,{cid = 1000})
    if data.icon and data.icon ~= "" then
        setSpriteFrameByName(item["i_icon"],data.icon)
    else
        setSpriteFrameByName(item["i_icon"],"alpha")
    end

    --
    if self.selectday+0 == self.day+0 then
        item.gotoNode:setVisible(true)
    else
        item.gotoNode:setVisible(false)
    end

end

function sevendayactivity.setNormal(self,item,data,index)
    print("setNormal")

    item.title:setString(data.name)

    local rewards = ui.getIDandNUMs(data.rewards)

    for i = 1,4 do
        local key_Ex = ""
        if i == 1 then
            key_Ex = ""
        else
            key_Ex = "_"..(i-1)
        end
        item["reward"..i]:setVisible(false)
        item["i_button"..key_Ex]:addHandleOfControlEvent(function()
            if rewards[i] and rewards[i]~="" then
                ui.setPopwindowByCid(rewards[i].cid)
            end
        end, CCControlEventTouchUpInside)
        item["i_button"..key_Ex]:setTouchPriority(-103)
        if rewards[i] and rewards[i]~="" then
            item["reward"..i]:setVisible(true)
            ui.setNewIcon(item,rewards[i],i-1)
        end
    end

    local selectpageindex = 1
    for k,v in ipairs(self.pageconfig) do
        if self.selectpage == v then
            selectpageindex = tonumber(k)
        end
    end

    item.doButton:setTouchPriority(-103)
    if self.status[tostring(data.id)] and self.status[tostring(data.id)] == 1 then    --todo id
        item.nonenode:setVisible(false)
        item.doNode:setVisible(true)
        item.hasnode:setVisible(false)
        -- item.doLab:setString("领取")
        item.doLab:setString(gameConfig.strings:string_common("moreCommon",6))
        ui.setLabelString(item.doLab,nil,18)
        item.doButton:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            gameTouch:clickprofbytime(1)
            print("getbutton clicked")
            if self.selectday+0 > self.day+0 then
                -- runGamePrompt({msg = "第"..self.selectday.."天可领取"})
                runGamePrompt({msg = gameConfig.strings:dayGet(self.selectday)})
            else
                
                local allShow = true
                local onekeyStr = CCUserDefault:sharedUserDefault():getStringForKey("onekeyall_")
                if onekeyStr and onekeyStr ~= "" then
                    local now = os.date("*t", gamedata:time())
                    local _t = string.split(onekeyStr,"_")
                    if tonumber(_t[1]) == 0 and tonumber(_t[2]) == now.year and tonumber(_t[3]) == now.month and tonumber(_t[4]) == now.day then
                        allShow = false
                    end
                end
                print("allShow = ",allShow)

                local rewardData = ui.getCanReceiveData(self.showData, 4)
                if #rewardData > 1 then
                    if allShow then
                        local function callback(index)
                            if index == 1 then
                                UIRequest({type = 4889, id = data.id, selectday = self.selectday, selectpage = selectpageindex})
                            elseif index == 2 then -- 一键李领取
                                UIRequest({type = 4889, id = data.id, selectday = self.selectday, selectpage = selectpageindex, rewardData = rewardData})
                            end
                        end
                        gameWindows:openWindow("onekeyall", nil, callback)
                    else
                        UIRequest({type = 4889, id = data.id, selectday = self.selectday, selectpage = selectpageindex, rewardData = rewardData})
                    end
                else
                    UIRequest({type = 4889, id = data.id, selectday = self.selectday, selectpage = selectpageindex})
                end

            end
        end, CCControlEventTouchUpInside)
    elseif self.status[tostring(data.id)] and self.status[tostring(data.id)] == 2 then      --todo
        item.nonenode:setVisible(false)
        item.doNode:setVisible(false)
        item.hasnode:setVisible(true)
        -- item.doLab:setString("已领取")
        item.doLab:setString(gameConfig.strings:string_common("moreCommon",5))
        ui.setLabelString(item.doLab,nil,18)
        item.doButton:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            -- runGamePrompt({msg = "已领取"})
            runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",5)})
        end, CCControlEventTouchUpInside)
    elseif self.status[tostring(data.id)] and self.status[tostring(data.id)] == 3 then      --todo
        item.nonelab:setString(gameConfig.strings:string_common("moreCommon",3))
        item.nonenode:setVisible(true)
        item.doNode:setVisible(false)
        item.hasnode:setVisible(false)
        -- item.doLab:setString("领取")
        item.doLab:setString(gameConfig.strings:string_common("moreCommon",6))
        ui.setLabelString(item.doLab,nil,18)
        item.doButton:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            -- runGamePrompt({msg = "已过期"})
            runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",3)})
        end, CCControlEventTouchUpInside)
    else
        item.nonelab:setString(gameConfig.strings:string_common("moreCommon",4))
        item.nonenode:setVisible(true)
        item.doNode:setVisible(false)
        item.hasnode:setVisible(false)
        --
        if item.nonelab and self.day and self.day+0 > 7 then
            item.nonelab:setString(gameConfig.strings:string_common("moreCommon","yijieshu"))
        end
        -- item.doLab:setString("领取")
        item.doLab:setString(gameConfig.strings:string_common("moreCommon",6))
        ui.setLabelString(item.doLab,nil,18)
        item.doButton:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            -- runGamePrompt({msg = "未完成"})
            runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",7)})
        end, CCControlEventTouchUpInside)
    end

    --pos
    local num = ui.Split(data.target, ",") or {}
    if num[1] then
        num[1] = tonumber(num[1]) or 0
    end

    if data.type and data.desc and tonumber(data.desc) == 1 then     --todo
        if (data.type == 33) and (self.day ~= self.selectday) then

        else    
            item.title:setString(data.name.."    ( "..((self.status2[tostring(data.type)] or 0)<=(num[1] or 0) and (self.status2[tostring(data.type)] or 0) or (num[1] or 0)).."/"..(num[1] or 0).." ) ")
        end   
    end

end

function sevendayactivity.setbuyCell(self,item,data,index)
    --
    local configdata = self.buyconfig[tostring(data.id)] or {}
    printT(configdata,"jkp-configdata2")

    local target = ui.getIDandNUMs(configdata.target) or {}
    local rewards = ui.getIDandNUMs(configdata.rewards) or {}

    local props = {}
    for k,v in pairs(target) do
        table.insert(props,v)
    end
    for k,v in pairs(rewards) do
        table.insert(props,v)
    end

    for i = 1,4 do
        local key_Ex = ""
        if i == 1 then
            key_Ex = ""
        else
            key_Ex = "_"..(i-1)
        end
        if props[i] then
            item["m_prop"..i]:setVisible(true)
            ui.setNewIcon(item,props[i],i-1)
            item["i_button"..key_Ex]:addHandleOfControlEvent(function()
                ui.setPopwindowByCid(props[i].cid)
            end, CCControlEventTouchUpInside)
            item["i_button"..key_Ex]:setTouchPriority(-103)
        else
            item["m_prop"..i]:setVisible(false)
            item["i_button"..key_Ex]:addHandleOfControlEvent(function()
                print("noprop")
            end, CCControlEventTouchUpInside)
            item["i_button"..key_Ex]:setTouchPriority(-103)
        end
    end

    for i = 1,3 do
        if i == table.getTableLength(target) then
            setSpriteFrameByName(item["m_sprite"..i],"spr_136")
        elseif i < table.getTableLength(props) then
            setSpriteFrameByName(item["m_sprite"..i],"spr_135")
        else
            setSpriteFrameByName(item["m_sprite"..i],"alpha")
        end
    end

    --
    if configdata.labal and configdata.labal > 0 then
        setSpriteFrameByName(item["m_zhe"],configdata.labal.."zhe")
    else
        setSpriteFrameByName(item["m_zhe"],"alpha")
    end
    --

    local selectpageindex = 1
    for k,v in ipairs(self.pageconfig) do
        if self.selectpage == v then
            selectpageindex = tonumber(k)
        end
    end

    ui.setLabelString(item.m_doLab,nil,18)
    local dotimes = self.status3[tostring(configdata.index)] or 0
    if self.selectday+0 > self.day+0 then
        item.m_exchangeNum:setString(gameConfig.strings:string_common("fixedString","tigerChicken",4)..(configdata.times))
        ui.addGray("CCControlButton",item["m_doButton"])
        item["m_doButton"]:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            runGamePrompt({msg = gameConfig.strings:dayGet2(self.selectday)})
        end, CCControlEventTouchUpInside)
        item["m_doButton"]:setTouchPriority(-103)
    elseif configdata.times and configdata.times > 0 then
        if dotimes >= configdata.times then
            item.m_exchangeNum:setString(gameConfig.strings:string_common("fixedString","tigerChicken",4).."0")
            ui.addGray("CCControlButton",item["m_doButton"])
            item["m_doButton"]:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(1)
                runGamePrompt({msg = gameConfig.strings:string_common("fixedString","tigerChicken",5)})
            end, CCControlEventTouchUpInside)
            item["m_doButton"]:setTouchPriority(-103)
        else
            item.m_exchangeNum:setString(gameConfig.strings:string_common("fixedString","tigerChicken",4)..(configdata.times-dotimes))
            ui.removeGray("CCControlButton",item["m_doButton"])
            item["m_doButton"]:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(1)
                local count = self:getCanBuyNum((configdata.times-dotimes), configdata.target)
                local cb = function( num )
                    if num > 1 then
                        local rewardData = {}
                        for i=1,num do
                            table.insert(rewardData, configdata.id)
                        end
                        UIRequest({type = 4889, id = configdata.id, xprop = target, selectday = self.selectday, selectpage = selectpageindex, rewardData = rewardData})
                    else
                        UIRequest({type = 4889, id = configdata.id, xprop = target, selectday = self.selectday, selectpage = selectpageindex})
                    end
                end
                ui.exchangeMore(cb,9999,count,count)
            end, CCControlEventTouchUpInside)
            item["m_doButton"]:setTouchPriority(-103)
        end
    else
        item.m_exchangeNum:setString("")
        ui.removeGray("CCControlButton",item["m_doButton"])
        item["m_doButton"]:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            local count = self:getCanBuyNum((configdata.times-dotimes), configdata.target)
            local cb = function( num )
                if num > 1 then
                    local rewardData = {}
                    for i=1,num do
                        table.insert(rewardData, configdata.id)
                    end
                    UIRequest({type = 4889, id = configdata.id, xprop = target, selectday = self.selectday, selectpage = selectpageindex, rewardData = rewardData})
                else
                    UIRequest({type = 4889, id = configdata.id, xprop = target, selectday = self.selectday, selectpage = selectpageindex})
                end
            end
            ui.exchangeMore(cb,9999,count,count)
        end, CCControlEventTouchUpInside)
        item["m_doButton"]:setTouchPriority(-103)
    end

end

function sevendayactivity.getCanBuyNum(self, maxnum, once)
    local count = 0
    for i=1, maxnum do
        local cid,num = ui.getIDandNUM(once)
        if cid == 1001 then
            if num * i <= GameScene.roleinfo.gold then
                count = count+1
            end
        elseif cid == 1034 then
            if num * i <= GameScene.roleinfo.yaoqi then
                count = count+1
            end
        end
    end
    if count == 0 then
        count = 1
    end
    return count
end

function sevendayactivity.createList(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("start2/n_cell_reward1", nil, true, "cell_reward1")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setNormal(ccbDocumentControler,self.showData[a1+1],a1+1)

            cellCCB:setPosition(self.normalCellSize.x/2, 14)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.showData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
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
    self.ListTableView:setTouchPriority(-101)
end

function sevendayactivity.createbuyList(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.buyCellSize.x, self.buyCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("start2/cell_shiyi", nil, true, "cell_shiyi")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setbuyCell(ccbDocumentControler,self.showData[a1+1],a1+1)

            cellCCB:setPosition(self.buyCellSize.x/2, 14)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.showData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.buyListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.buylistScroll:getContentSize().width,
        viewheight = self.rootItems.buylistScroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.buylistScroll:addChild(self.buyListTableView)
    self.buyListTableView:setTouchPriority(-101)
end


function sevendayactivity.createpowerList(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.gotoCellSize.x, self.gotoCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("start2/p_cell_reward2", nil, true, "p_cell_reward2")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setGoto(ccbDocumentControler,self.showData[a1+1],a1+1)

            cellCCB:setPosition(self.gotoCellSize.x/2, 14)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.showData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.powerListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.powerlistScroll:getContentSize().width,
        viewheight = self.rootItems.powerlistScroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.powerlistScroll:addChild(self.powerListTableView)
    self.powerListTableView:setTouchPriority(-101)
end


function sevendayactivity.request(self)

    local ids = {
        [1] = 0,
        [2] = self.selectday,
        [3] = self.pageindex[self.selectpage]
    }
    UIRequest({type = 4888, ids = nil,})

end

function sevendayactivity.reloadHint(self)
    for k,v in pairs(self.dayconfig) do
        if tostring(k) == tostring(self.selectday) then
            for kk,vv in pairs(v) do
                if GameScene.hintdata and GameScene.hintdata[tostring(self.hintconfig[1].config["day"..self.selectday][tonumber(kk)])] then
                    ui.sethint(self.rootItems["hint_title"..kk], GameScene.hintdata[tostring(self.hintconfig[1].config["day"..self.selectday][tonumber(kk)])] > 0)
                else
                    ui.sethint(self.rootItems["hint_title"..kk],false)
                end
            end
        end
    end
    --self:checkHint()
end

function sevendayactivity.checkHint(self)
    if self.day then
        for i=1,7 do
            if self.day+0<i then
                ui.sethint(self.rootItems["hint_day"..i],false)
            end
        end
    end
end


function sevendayactivity.ReloadData(self,data,ispagechange)
    print("ReloadData")

    self.data = data or self.data

    if not next(self.data) then
        self:request()
        return   
    end    

    self.status =  self.data["1"] or {}
    self.status2 = self.data["2"] or {}
    self.status3 = self.data["3"] or {}
    self.day = self.data["0"] and self.data["0"]["1"]+0 or 1


    --todo
    if not next(self.taskconfig) then
        --
        self.taskconfig = gamedata.config:getConfigByName("new_accelerate_task_2_rc_"..self.data["0"]["2"]) or {}
        self.dayconfig = gamedata.config:getConfigByName("new_accelerate_2_rc_"..self.data["0"]["2"]) or {}
        --
        self.buyconfig = {}
        local buyconfig = {}
        for k,v in pairs(self.taskconfig) do
            if v.type and v.type == 57 then          --todo 珍品折扣
                table.insert(buyconfig,v)
            end
        end
        local sortById = function(a,b) return a.id < b.id end
        -- table.sort(buyconfig, sortById)
        --
        for k,v in ipairs(buyconfig) do
            v.index = tonumber(v.id) - 84800
            self.buyconfig[tostring(v.id)] = v
        end
        --
        -- todo showid
        local showid = 0
        if self.taskconfig["83007"] and self.taskconfig["83007"].show and self.taskconfig["83007"].show > 0 then
            showid = self.taskconfig["83007"].show
            ui.setLabelString(self.rootItems.generalname_7,"“"..ui.IDconfig(showid).name..((ui.IDconfig(showid).staffType == "general_fragment") and "魂魄" or "").."”",9)
        else
            ui.setLabelString(self.rootItems.generalname_7,nil,9)
        end
        --
    end

    if self.isinit then
        self.isinit = false
        self.selectday = self.targetday and self.targetday or ((self.day+0 <= 7) and self.day+0 or 7)

        -- self.rootItems["timelab"..2]:setString((8-self.day > 0) and (8-self.day).."天" or "已结束")
        -- self.rootItems["timelab"..4]:setString((8-self.day > 0) and (8-self.day).."天" or "已结束")
        self.rootItems["timelab"..2]:setString((8-self.day > 0) and gameConfig.strings:Day(8-self.day) or gameConfig.strings:string_common("moreCommon","yijieshu"))
        self.rootItems["timelab"..4]:setString((8-self.day > 0) and gameConfig.strings:Day(8-self.day) or gameConfig.strings:string_common("moreCommon","yijieshu"))
        ui.setLabelString(self.rootItems["timelab"..2],nil,26)
        ui.setLabelString(self.rootItems["timelab"..4],nil,27)

        --
        if self.rootItems.timenode1 and self.rootItems.timenode2 then
            ui.setLabelString(self.rootItems["timedesc"..1],nil,121)
            ui.setLabelString(self.rootItems["timedesc"..2],nil,121)   
            if (self.day > 7) then
                self.rootItems.timenode1:setVisible(false)  
                self.rootItems.timenode2:setVisible(true)   
            else
                self.rootItems.timenode1:setVisible(true) 
                self.rootItems.timenode2:setVisible(false)    
            end    
        end    
        --
    end

    if self.selectpage == "buy" then
        --
        if self.hintconfig[1] and self.hintconfig[1].config and self.hintconfig[1].config["day"..self.selectday] and self.hintconfig[1].config["day"..self.selectday][4] then
            UIRequest({type = 10321,notupdate = 1,ids = {self.hintconfig[1].config["day"..self.selectday][4]}})
            if GameScene.hintdata and GameScene.hintdata[tostring(self.hintconfig[1].config["day"..self.selectday][4])] then
                GameScene.hintdata[tostring(self.hintconfig[1].config["day"..self.selectday][4])] = 0
            end    
        end
        --
    end    

    self.showData = {}
    for k,v in pairs(self.dayconfig) do
        if tostring(k) == tostring(self.selectday) then
            for kk,vv in pairs(v) do
                self.rootItems["buttontext"..kk]:setString(vv.name)

                if GameScene.hintdata and GameScene.hintdata[tostring(self.hintconfig[1].config["day"..self.selectday][tonumber(kk)])] then
                    ui.sethint(self.rootItems["hint_title"..kk], GameScene.hintdata[tostring(self.hintconfig[1].config["day"..self.selectday][tonumber(kk)])] > 0)
                else
                    ui.sethint(self.rootItems["hint_title"..kk],false)
                end

                if tostring(kk) == tostring(self.pageindex[self.selectpage]) then
                    for i = 1,20 do
                        if vv["task"..i] and vv["task"..i] > 0 then
                            if self.status[tostring(self.taskconfig[tostring(vv["task"..i])].id)] == 1 then                      --todo
                                self.taskconfig[tostring(vv["task"..i])].sortdata = 4
                            elseif self.status[tostring(self.taskconfig[tostring(vv["task"..i])].id)] == 0 then                  --todo
                                self.taskconfig[tostring(vv["task"..i])].sortdata = 3
                            elseif self.status[tostring(self.taskconfig[tostring(vv["task"..i])].id)] == 3 then                  --todo
                                self.taskconfig[tostring(vv["task"..i])].sortdata = 2
                            else
                                self.taskconfig[tostring(vv["task"..i])].sortdata = 1
                            end
                            table.insert(self.showData,self.taskconfig[tostring(vv["task"..i])])
                        end
                    end
                end
            end
        end
    end

    local sortfunc = function(a,b)
        if a["sortdata"] == b["sortdata"] then
            return a.id<b.id
        else
            return a["sortdata"] > b["sortdata"]
        end
    end
    
    if self.selectpage ~= "buy" then
        table.sort(self.showData,sortfunc)
    end

    if self.selectpage == "power" then
        self.rootItems.powerlistScroll:setPositionX(0)
        self.rootItems.buylistScroll:setPositionX(9999)
        self.rootItems.listScroll:setPositionX(9999)
        self.rootItems.listbg:setVisible(true)
        if not self.powerListTableView then
            self:createpowerList()
        else
            self.powerListTableView:reloadData()
            if ispagechange then
                self.powerListTableView:setLuaContentOffset(0, self.rootItems.powerlistScroll:getContentSize().height - table.getTableLength(self.showData)*self.gotoCellSize.y)
            end
        end
    elseif self.selectpage == "buy" then
        self.rootItems.powerlistScroll:setPositionX(9999)
        self.rootItems.buylistScroll:setPositionX(0)
        self.rootItems.listScroll:setPositionX(9999)
        self.rootItems.listbg:setVisible(true)
        if not self.buyListTableView then
            self:createbuyList()
        else
            self.buyListTableView:reloadData()
            if ispagechange then
                self.buyListTableView:setLuaContentOffset(0, self.rootItems.buylistScroll:getContentSize().height - table.getTableLength(self.showData)*self.buyCellSize.y)
            end
        end
    elseif self.rootItems then
        self.rootItems.powerlistScroll:setPositionX(9999)
        self.rootItems.buylistScroll:setPositionX(9999)
        self.rootItems.listScroll:setPositionX(0)
        self.rootItems.listbg:setVisible(true)
        if not self.ListTableView then
            self:createList()
        else
            self.ListTableView:reloadData()
            if ispagechange then
                self.ListTableView:setLuaContentOffset(0, self.rootItems.listScroll:getContentSize().height - table.getTableLength(self.showData)*self.normalCellSize.y)
            end
        end
    end

    --
    for i = 1,7 do
        self.rootItems["isday"..i]:setVisible(false)
        if self.day >= i then
            self.rootItems["hasday"..i]:setVisible(true)
        else
            self.rootItems["hasday"..i]:setVisible(false)
        end
    end
    self.rootItems["isday"..self.selectday]:setVisible(true)
    --
    --self:checkHint()
end

function sevendayactivity.UIUpdateData(self, isreset)
    if isreset then
        self:request()
    end
end

return sevendayactivity
l�  