

local playerreturn = {

    resource = nil,

    rootNode = nil,
    rootItems = nil,
    dailyListTableView = nil,
    powerListTableView = nil,
    levelListTableView = nil,
    buyListTableView = nil,

    data = {},

    taskconfig = {},
    dailyconfig = {},
    powerconfig = {},
    levelconfig = {},
    buyconfig = {},

    playerreturn = {},

    pageconfig = {"daily","power","level","buy"},
    pagename = {"","","",""},
    selectpage = "daily",
    hintconfig = {
        {
            name = "rootItems",
            type = "self",
            config = {
                title1 = {247},
                title2 = {248},
                title3 = {249},
                title4 = {250},
            },
        },
    },


    normalCellSize = {x=1080,y=282+14},
    gotoCellSize = {x=1080,y=228+14},
}

function playerreturn.shiftPage(self,type)
    self.selectpage = type or "daily"
    if self.selectpage == "power" then
        self.rootItems.dailylistScroll:setPositionX(9999)
        self.rootItems.powerlistScroll:setPositionX(0)
        self.rootItems.levellistScroll:setPositionX(9999)
        self.rootItems.buylistScroll:setPositionX(9999)
    elseif self.selectpage == "level" then
        self.rootItems.dailylistScroll:setPositionX(9999)
        self.rootItems.powerlistScroll:setPositionX(9999)
        self.rootItems.levellistScroll:setPositionX(0)
        self.rootItems.buylistScroll:setPositionX(9999)
    elseif self.selectpage == "buy" then
        self.rootItems.dailylistScroll:setPositionX(9999)
        self.rootItems.powerlistScroll:setPositionX(9999)
        self.rootItems.levellistScroll:setPositionX(9999)
        self.rootItems.buylistScroll:setPositionX(0)
    else
        self.rootItems.dailylistScroll:setPositionX(0)
        self.rootItems.powerlistScroll:setPositionX(9999)
        self.rootItems.levellistScroll:setPositionX(9999)
        self.rootItems.buylistScroll:setPositionX(9999)
    end
end

function playerreturn.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("activityplayerreturn/playerreturn", nil, true, "playerreturn")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)

    self.rootItems.dailylistScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-550-160))
    self.rootItems.powerlistScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-550-160))
    self.rootItems.levellistScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-550-160))
    self.rootItems.buylistScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-550-160))

    self.taskconfig = gamedata.config.player_back_task or {}
    --
    self.dailyconfig = {}
    self.powerconfig = {}
    self.levelconfig = {}
    self.buyconfig = {}

    for k,v in pairs(self.taskconfig) do
        v.sortdata = 2
        if v.type_page and v.type_page == 1 then
            table.insert(self.dailyconfig,v)
            self.pagename[1] = v.page_name
        elseif v.type_page and v.type_page == 2 then
            table.insert(self.powerconfig,v)
            self.pagename[2] = v.page_name
        elseif v.type_page and v.type_page == 3 then
            table.insert(self.levelconfig,v)
            self.pagename[3] = v.page_name
        elseif v.type_page and v.type_page == 4 then
            table.insert(self.buyconfig,v)
            self.pagename[4] = v.page_name
        end
    end
    local sortById = function(a,b) return a.id < b.id end
    table.sort(self.dailyconfig, sortById)
    table.sort(self.powerconfig, sortById)
    table.sort(self.levelconfig, sortById)
    table.sort(self.buyconfig, sortById)
    --

    self:request()
end

function playerreturn.clear(self)

    self.dailyListTableView = nil
    self.powerListTableView = nil
    self.levelListTableView = nil
    self.buyListTableView = nil

    self.data = {}

    self.taskconfig = {}
    self.dailyconfig = {}
    self.powerconfig = {}
    self.levelconfig = {}
    self.buyconfig = {}

    self.playerreturn = {}

    self.selectpage = "daily"
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end




function playerreturn.createdailyList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityplayerreturn/p_cell_reward1", nil, true, "p_cell_reward1")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setNormal(ccbDocumentControler,self.dailyconfig[a1+1])

            cellCCB:setPosition(self.normalCellSize.x/2, 14)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.dailyconfig)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.dailyListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.dailylistScroll:getContentSize().width,
        viewheight = self.rootItems.dailylistScroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.dailylistScroll:addChild(self.dailyListTableView)
    self.dailyListTableView:setTouchPriority(-101)
end

function playerreturn.createpowerList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityplayerreturn/p_cell_reward2", nil, true, "p_cell_reward2")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setGoto(ccbDocumentControler,self.powerconfig[a1+1])

            cellCCB:setPosition(self.gotoCellSize.x/2, 14)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.powerconfig)
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

function playerreturn.createlevelList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityplayerreturn/p_cell_reward1", nil, true, "p_cell_reward1")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setNormal(ccbDocumentControler,self.levelconfig[a1+1])

            cellCCB:setPosition(self.normalCellSize.x/2, 14)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.levelconfig)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.levelListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.levellistScroll:getContentSize().width,
        viewheight = self.rootItems.levellistScroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.levellistScroll:addChild(self.levelListTableView)
    self.levelListTableView:setTouchPriority(-101)
end

function playerreturn.createbuyList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityplayerreturn/p_cell_reward3", nil, true, "p_cell_reward1")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setBuy(ccbDocumentControler,self.buyconfig[a1+1],a1+1)

            cellCCB:setPosition(self.normalCellSize.x/2, 14)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.buyconfig)
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


function playerreturn.setNormal(self,item,data)

    local playertype = self.data.playertype or 1
    item.title:setString(data.name)

    local rewards = ui.getIDandNUMs(data["rewards"..playertype])

    for i = 1,4 do
        local key_Ex = ""
        if i == 1 then
            key_Ex = ""
        else
            key_Ex = "_"..(i-1)
        end
        item["reward"..i]:setVisible(false)
        item["i_button"..key_Ex]:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
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

    item.doButton:setTouchPriority(-103)
    if self.data.status and self.data.status[tostring(data.id-82000)] and self.data.status[tostring(data.id-82000)] == 1 then
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
            UIRequest({type = 3773, id = data.id,})
        end, CCControlEventTouchUpInside)
    elseif self.data.status and self.data.status[tostring(data.id-82000)] and self.data.status[tostring(data.id-82000)] == 2 then
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
    else
        item.nonelab:setString(gameConfig.strings:string_common("moreCommon",4))
        item.nonenode:setVisible(true)
        item.doNode:setVisible(false)
        item.hasnode:setVisible(false)
        --
        item.doLab:setString(gameConfig.strings:string_common("moreCommon",6))
        ui.setLabelString(item.doLab,nil,18)
        item.doButton:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            -- runGamePrompt({msg = "未完成"})
            runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",7)})
        end, CCControlEventTouchUpInside)
    end

    --pos
    if data.desc and (data.desc == 1 or data.desc == "1") then
        local num = ui.Split(data.target, ",") or {}
        if num[1] then
            num[1] = tonumber(num[1]) or 0
        end

        if data.type == 1 then
            item.title:setString(data.name.."        ( "..((self.data.loginday or 0)<=(num[1] or 0) and (self.data.loginday or 0) or (num[1] or 0)).."/"..(num[1] or 0).." ) ")
--        elseif data.type == 14 then
--            item.title:setString(data.name.."        ( "..((self.data.singlerecharge or 0)<=(num[1] or 0) and (self.data.singlerecharge or 0) or (num[1] or 0)).."/"..(num[1] or 0).." ) ")
        elseif data.type == 15 then
            item.title:setString(data.name.."        ( "..((self.data.cumulativerecharge or 0)<=(num[1] or 0) and (self.data.cumulativerecharge or 0) or (num[1] or 0)).."/"..(num[1] or 0).." ) ")
        end
    end

end


function playerreturn.setGoto(self,item,data)

    local playertype = self.data.playertype or 1
    item.title:setString(data.name)
    item.desc:setString(data.name..gameConfig.strings:string_common("fixedString","playerrecall",5)..data["param"..self.data.playertype]..gameConfig.strings:string_common("fixedString","playerrecall",6))

    ui.setLabelString(item.gotoLab,nil,18)
    item.gotoButton:setTouchPriority(-103)
    item.gotoButton:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        gameTouch:clickprofbytime(1)
        --
        if data.systemid and data.systemid == 191 then
            if gamedata.config.wudao_time and gamedata.config.wudao_time["1"] and gamedata.config.wudao_time["1"].open_week and gamedata.config.wudao_time["1"].open_week > 0 then
                local nowtime = os.date("*t", gamedata:time())
                local daynums = (nowtime.wday == 1 and 7 or (nowtime.wday-1))
                local alltimes = (daynums - 1)*24*3600 + nowtime.hour*3600 + nowtime.min*60 + nowtime.sec - 1
                local isopen = false
                for k,v in pairs(gamedata.config.wudao_time) do
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
    elseif data.type and data.type == 2 then
        setSpriteFrameByName(item["i_icon"],"icons_penglaixiandong")
    elseif data.type and data.type == 3 then
        setSpriteFrameByName(item["i_icon"],"icons_mieshendian")
    elseif data.type and data.type == 4 then
        setSpriteFrameByName(item["i_icon"],"icons_jingjichang")
    elseif data.type and data.type == 5 then
        setSpriteFrameByName(item["i_icon"],"icons_guanjunshilian")
    elseif data.type and data.type == 6 then
        setSpriteFrameByName(item["i_icon"],"icons_tiaozhan")
    elseif data.type and data.type == 7 then
        setSpriteFrameByName(item["i_icon"],"icons_haoyoufuben")
    elseif data.type and data.type == 8 then
        setSpriteFrameByName(item["i_icon"],"icons_boss")
    elseif data.type and data.type == 9 then
        setSpriteFrameByName(item["i_icon"],"icons_beisai")
    elseif data.type and data.type == 10 then
        setSpriteFrameByName(item["i_icon"],"icons_wangdenanren")
    elseif data.type and data.type == 11 then
        setSpriteFrameByName(item["i_icon"],"icons_tiantingyinzuo")
    elseif data.type and data.type == 12 then
        setSpriteFrameByName(item["i_icon"],"icons_wudaohui")
    elseif data.type and data.type == 13 then
        setSpriteFrameByName(item["i_icon"],"icons_guoguanzhanjiang")
    else
        setSpriteFrameByName(item["i_icon"],"alpha")
    end



end

function playerreturn.setBuy(self,item,data,index)

    local playertype = self.data.playertype or 1
    item.title:setString(data.name)

    local rewards = ui.getIDandNUMs(data["rewards"..playertype])

    for i = 1,4 do
        local key_Ex = ""
        if i == 1 then
            key_Ex = ""
        else
            key_Ex = "_"..(i-1)
        end
        item["reward"..i]:setVisible(false)
        item["i_button"..key_Ex]:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
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

    local hasnum = 0
    local donum = self.data.exchange and self.data.exchange[tostring(index)] or 0
    if data.times and data.times > 0 then
        if data.times - donum > 0 then
            hasnum = data.times - donum
        end
    end

    item.buyNum:setString(gameConfig.strings:string_common("fixedString","playerrecall",4)..hasnum)

    local xgold = 0
    local xprop = {}
    if data.target and data.target ~= "" then
        xprop = ui.getIDandNUMs(data.target)
    end
    for k,v in pairs(xprop) do
        if v.cid == 1001 then
            xgold = v.num
        end
    end

    ui.setLabelString(item.xgold,xgold,14)

    --
    ui.setLabelString(item.doLab,nil,18)
    item.doButton:setTouchPriority(-103)

    if hasnum > 0 then
        ui.removeGray("CCControlButton",item["doButton"])
        item.doButton:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            gameTouch:clickprofbytime(1)
            UIRequest({type = 3773, id = data.id, xgold = xgold})
        end, CCControlEventTouchUpInside)
    else
        ui.addGray("CCControlButton",item["doButton"])
        item.doButton:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            gameTouch:clickprofbytime(1)
            runGamePrompt({msg = gameConfig.strings:string_common("lead",5)})
        end, CCControlEventTouchUpInside)
    end

end


function playerreturn.request(self)

    UIRequest({type = 3772})

end



function playerreturn.ReloadData(self,data)
    print("ReloadData")

    self.data = data or self.data

    if self.data.playertype and self.data.playertype > 0 then
        print(self.data.playertype)
    else
        GameScene:shiftLayer("main","down")
        return
    end

    self.rootItems.backButton:setTouchPriority(-103)
    if self.data.usecode and self.data.usecode == 0 then
        ui.removeGray("CCControlButton",self.rootItems.backButton)
        ui.setLabelString(self.rootItems.backLab,gameConfig.strings:string_common("fixedString","playerrecall",3),18)
        self.rootItems.backButton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            gameWindows:openWindow("playerreturncdk",nil)
        end, CCControlEventTouchUpInside)
    else
        ui.addGray("CCControlButton",self.rootItems.backButton)
        ui.setLabelString(self.rootItems.backLab,gameConfig.strings:string_common("fixedString","playerrecall",2),18)
        self.rootItems.backButton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            runGamePrompt({msg = gameConfig.strings:string_common("fixedString","playerrecall",2)})
        end, CCControlEventTouchUpInside)
    end

    --
    if self.data.playertype and gamedata.config.global_kv["player_back_time"..self.data.playertype] then
        self.rootItems.backtype:setString(gamedata.config.global_kv["player_back_time"..self.data.playertype].desc)
    else
        self.rootItems.backtype:setString("")
    end

    local timelimit = 0
    if gamedata.config.global_kv.player_comeback_timelimit then
        timelimit = tonumber(gamedata.config.global_kv.player_comeback_timelimit.value)
    end

    if self.data.loginday and timelimit-self.data.loginday >= 0 then
        ui.setLabelString(self.rootItems.time,(timelimit-self.data.loginday+1)..gameConfig.strings:string_common("fixedString","activity_signin",4),22)
    else
        ui.setLabelString(self.rootItems.time,"",22)
        GameScene:shiftLayer("main","down")
        return
    end
    --

    for k,v in pairs(self.dailyconfig) do
        if self.data.status and self.data.status[tostring(v.id-82000)] and self.data.status[tostring(v.id-82000)] == 1 then
            self.dailyconfig[k].sortdata = 3
        elseif self.data.status and self.data.status[tostring(v.id-82000)] and self.data.status[tostring(v.id-82000)] == 2 then
            self.dailyconfig[k].sortdata = 1
        else
            self.dailyconfig[k].sortdata = 2
        end
    end
    for k,v in pairs(self.levelconfig) do
        if self.data.status and self.data.status[tostring(v.id-82000)] and self.data.status[tostring(v.id-82000)] == 1 then
            self.levelconfig[k].sortdata = 3
        elseif self.data.status and self.data.status[tostring(v.id-82000)] and self.data.status[tostring(v.id-82000)] == 2 then
            self.levelconfig[k].sortdata = 1
        else
            self.levelconfig[k].sortdata = 2
        end
    end

    local sortById = function(a,b)
        if a.sortdata == b.sortdata then
            return a.id < b.id
        else
            return a.sortdata > b.sortdata
        end
    end
    table.sort(self.dailyconfig, sortById)
    table.sort(self.levelconfig, sortById)
    --

    if not self.dailyListTableView then
        self:createdailyList()
    else
        self.dailyListTableView:reloadData()
    end

    if not self.powerListTableView then
        self:createpowerList()
    else
        self.powerListTableView:reloadData()
    end

    if not self.levelListTableView then
        self:createlevelList()
    else
        self.levelListTableView:reloadData()
    end

    if not self.buyListTableView then
        self:createbuyList()
    else
        self.buyListTableView:reloadData()
    end

    self:shiftPage(self.selectpage)

end

function playerreturn.gettimenum(self,times,minnum)
    local min = 0
    if minnum then
        min = minnum
    end
    local alltimes = 0
    alltimes = (times.week and (times.week-1) or 0)*24*3600 + (times.hour or 0)*3600 + times.min*60 + times.sec + min*60
    return alltimes
end

function playerreturn.UIUpdateData(self, isreset)
    if isreset then
        self:request()
    end
end

return playerreturn
  �e  