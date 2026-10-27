

local october1st = {

    resource = nil,

    rootNode = nil,
    rootItems = nil,
    ListTableView = nil,
    buyListTableView = nil,

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
    status4 = {},
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
                day1 = {217,218,219,220},
                day2 = {221,222,223,224},
                day3 = {225,226,227,228},
                day4 = {229,230,231,232},
                day5 = {233,234,235,236},
                day6 = {237,238,239,240},
                day7 = {241,242,243,244},
            },
        },
    },


    normalCellSize = {x=1080,y=282+14},
    buyCellSize = {x=1080,y=226+14},

    --主界面Icon
    -- mainIcon = "b_n_mainicon_shiyi", -- 七日狂欢
    -- mainIcon = "b_n_mainicon_chunjie",
    -- mainIcon = "b_n_mainicon_yuandankuanghuan",
    -- mainIcon = "b_n_mainicon_yuanxiao2",
    mainIcon = "b_n_mainicon_7zhounianqing_1", -- 周年庆
    -- mainIcon = "b_mainicon_n_wuyi",

    openType = 4,
}

function october1st.setShowType(self,type)
    self.openType = type
    if self.openType == 4 then
        self.mainIcon = "b_n_mainicon_7zhounianqing_1"
    elseif self.openType == 7 then
        self.mainIcon = "b_n_mainicon_7zhounianqing_2"
    end
end

function  october1st.shiftlayerpage(self,page)
    for km,vm in ipairs(self.pageconfig) do
        if vm == page then
            setSpriteFrameByName(self.rootItems["buttonsprite"..km], "b_n_button_tab2_guoqing")
            self.rootItems["buttonnode"..km]:setZOrder(1)
        else
            setSpriteFrameByName(self.rootItems["buttonsprite"..km], "b_n_button_tab1_guoqing")
            self.rootItems["buttonnode"..km]:setZOrder(0)
        end
    end
end

function october1st.shiftPage(self,type)

    local ispagechange = self.selectpage ~= type
    self.selectpage = type

    self:ReloadData(nil,ispagechange)
end

function october1st.init(self,parent,toppos,param)

    -- self.rootNode,self.rootItems = CCBReaderLoad("start2/qiri", nil, true, "qiri")
    -- self.rootNode,self.rootItems = CCBReaderLoad("start2/chunjie", nil, true, "chunjie")
    -- self.rootNode,self.rootItems = CCBReaderLoad("start2/yuandanqiri", nil, true, "yuandanqiri")
    -- self.rootNode,self.rootItems = CCBReaderLoad("start2/yuanxiao", nil, true, "yuanxiao")
    self.rootNode,self.rootItems = CCBReaderLoad(self.openType == 4 and "7zhounian/7zhounian_7days" or "7zhounian/7zhounian_7days", nil, true, "7zhounian_7days")
    -- self.rootNode,self.rootItems = CCBReaderLoad("start2/wuyi", nil, true, "wuyi")

    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.targetday = nil
    if param and param.selectday then
        self.targetday = param.selectday
    end


    self.rootItems.topnode:setPositionY(toppos)

    self.rootItems.listScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-550-160))
    self.rootItems.buylistScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-550-160))

    ui.setLabelString(self.rootItems["timelab"..1],nil,121)
    ui.setLabelString(self.rootItems["timelab"..2],nil,26)
    ui.setLabelString(self.rootItems["timelab"..3],nil,121)
    ui.setLabelString(self.rootItems["timelab"..4],nil,27)
    --

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
        --todo
    end, CCControlEventTouchUpInside)
    --

    --

    self:request()
end

function october1st.clear(self)
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
    self.status4 = {}
    self.rootItems = nil
    self.ListTableView = nil
    self.buyListTableView = nil
    self.selectpage = "daily"

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function october1st.setNormal(self,item,data,index)
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

    item.doButton:setTouchPriority(-103)
    if self.status[tostring(data.id-80500)] and self.status[tostring(data.id-80500)] == 1 then
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
                -- UIRequest({type = 3766, id = data.id,})

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
                                UIRequest({type = 3766, id = data.id})
                            elseif index == 2 then -- 一键领取
                                UIRequest({type = 3766, id = data.id, rewardData = rewardData})
                            end
                        end
                        gameWindows:openWindow("onekeyall", nil, callback)
                    else
                        UIRequest({type = 3766, id = data.id, rewardData = rewardData})
                    end
                else
                    UIRequest({type = 3766, id = data.id})
                end

            end
        end, CCControlEventTouchUpInside)
    elseif self.status[tostring(data.id-80500)] and self.status[tostring(data.id-80500)] == 2 then
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
    elseif self.status[tostring(data.id-80500)] and self.status[tostring(data.id-80500)] == 3 then
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

    if data.type == 3 then
        item.title:setString(data.name.."    ( "..((self.status2["1"] or 0)<=(num[1] or 0) and (self.status2["1"] or 0) or (num[1] or 0)).."/"..(num[1] or 0).." ) ")
    elseif data.type == 4 then
        item.title:setString(data.name.."    ( "..((self.status2["2"] or 0)<=(num[1] or 0) and (self.status2["2"] or 0) or (num[1] or 0)).."/"..(num[1] or 0).." ) ")
    elseif data.type == 5 then
        item.title:setString(data.name.."    ( "..((self.status2["3"] or 0)<=(num[1] or 0) and (self.status2["3"] or 0) or (num[1] or 0)).."/"..(num[1] or 0).." ) ")
    elseif data.type == 6 then
        item.title:setString(data.name.."    ( "..((self.status2["4"] or 0)<=(num[1] or 0) and (self.status2["4"] or 0) or (num[1] or 0)).."/"..(num[1] or 0).." ) ")
    elseif data.type == 7 then
        item.title:setString(data.name.."    ( "..((self.status2["5"] or 0)<=(num[1] or 0) and (self.status2["5"] or 0) or (num[1] or 0)).."/"..(num[1] or 0).." ) ")
    elseif data.type == 8 then
        item.title:setString(data.name.."    ( "..((self.status2["6"] or 0)<=(num[1] or 0) and (self.status2["6"] or 0) or (num[1] or 0)).."/"..(num[1] or 0).." ) ")
    elseif data.type == 9 then
        item.title:setString(data.name.."    ( "..((self.status2["7"] or 0)<=(num[1] or 0) and (self.status2["7"] or 0) or (num[1] or 0)).."/"..(num[1] or 0).." ) ")
    elseif data.type == 10 then
        item.title:setString(data.name.."    ( "..((self.status2["8"] or 0)<=(num[1] or 0) and (self.status2["8"] or 0) or (num[1] or 0)).."/"..(num[1] or 0).." ) ")
    elseif data.type == 11 then
        item.title:setString(data.name.."    ( "..((self.status2["9"] or 0)<=(num[1] or 0) and (self.status2["9"] or 0) or (num[1] or 0)).."/"..(num[1] or 0).." ) ")
    elseif data.type == 12 then
        item.title:setString(data.name.."    ( "..((self.status2["10"] or 0)<=(num[1] or 0) and (self.status2["10"] or 0) or (num[1] or 0)).."/"..(num[1] or 0).." ) ")
    elseif data.type == 13 then
        item.title:setString(data.name.."    ( "..((self.status2["11"] or 0)<=(num[1] or 0) and (self.status2["11"] or 0) or (num[1] or 0)).."/"..(num[1] or 0).." ) ")
    elseif data.type == 14 then
        item.title:setString(data.name.."    ( "..((self.status2["12"] or 0)<=(num[1] or 0) and (self.status2["12"] or 0) or (num[1] or 0)).."/"..(num[1] or 0).." ) ")
    elseif data.type == 15 then
        item.title:setString(data.name.."    ( "..((self.status2["13"] or 0)<=(num[1] or 0) and (self.status2["13"] or 0) or (num[1] or 0)).."/"..(num[1] or 0).." ) ")
    elseif data.type == 16 then
        item.title:setString(data.name.."    ( "..((self.status2["14"] or 0)<=(num[1] or 0) and (self.status2["14"] or 0) or (num[1] or 0)).."/"..(num[1] or 0).." ) ")
    elseif data.type == 17 then
        item.title:setString(data.name.."    ( "..((self.status2["15"] or 0)<=(num[1] or 0) and (self.status2["15"] or 0) or (num[1] or 0)).."/"..(num[1] or 0).." ) ")
    elseif data.type == 18 then
        item.title:setString(data.name.."    ( "..((self.status2["16"] or 0)<=(num[1] or 0) and (self.status2["16"] or 0) or (num[1] or 0)).."/"..(num[1] or 0).." ) ")
    elseif (data.type == 20) and ((self.selectday+0) == (self.day+0)) then
        item.title:setString(data.name.."    ( "..((self.status2["18"] or 0)<=(num[1] or 0) and (self.status2["18"] or 0) or (num[1] or 0)).."/"..(num[1] or 0).." ) ")
    end

    --
    if data.Recharge and data.Recharge > 0 and data.type == 2 then
        local recharge = data.Recharge or 1
        item.title:setString(data.name.."    ( 已领取 "..(self.status4[tostring(data.id-80507)] or 0).."/"..recharge.."次 ) ")
    end


end

function october1st.setbuyCell(self,item,data,index)
    --
    local configdata = self.buyconfig[tostring(data.id)] or {}
    printT(configdata,"jkp-configdata3")

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
                        UIRequest({type = 3766, id = configdata.id,xprop = target, rewardData = rewardData})
                    else
                        UIRequest({type = 3766, id = configdata.id,xprop = target})
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
                    UIRequest({type = 3766, id = configdata.id,xprop = target, rewardData = rewardData})
                else
                    UIRequest({type = 3766, id = configdata.id,xprop = target})
                end
            end
            ui.exchangeMore(cb,9999,count,count)
        end, CCControlEventTouchUpInside)
        item["m_doButton"]:setTouchPriority(-103)
    end

end

function october1st.getCanBuyNum(self, maxnum, once)
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

function october1st.createList(self)
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

function october1st.createbuyList(self)
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



function october1st.request(self)

    local ids = {
        [1] = 0,
        [2] = self.selectday,
        [3] = self.pageindex[self.selectpage]
    }
    UIRequest({type = 3765, ids = nil,})

end

function october1st.reloadHint(self)
    for k,v in pairs(self.dayconfig) do
        if tostring(k) == tostring(self.selectday) then
            for kk,vv in pairs(v) do
                ui.sethint(self.rootItems["hint_title"..kk], GameScene.hintdata and GameScene.hintdata[tostring(self.hintconfig[1].config["day"..self.selectday][tonumber(kk)])]~=0)
            end
        end
    end
    --self:checkHint()
end

function october1st.checkHint(self)
    if self.day then
        for i=1,7 do
            if self.day+0<i then
                ui.sethint(self.rootItems["hint_day"..i],false)
            end
        end
    end
end


function october1st.ReloadData(self,data,ispagechange)
    print("ReloadData")

    self:shiftlayerpage(self.selectpage)

    self.data = data or self.data
    self.status =  self.data["1"] or {}
    self.status2 = self.data["2"] or {}
    self.status3 = self.data["3"] or {}
    self.status4 = self.data["4"] or {}
    self.day = self.data["0"] and self.data["0"]["1"]+0 or 1

    --new
    if self.data["0"] and self.data["0"]["2"] and self.data["0"]["2"] >= 1 then
        self.taskconfig = gamedata.config.national_task_x1 or {}
        self.dayconfig = gamedata.config.national_7day_x1 or {}
    else
        self.taskconfig = gamedata.config.national_task or {}
        self.dayconfig = gamedata.config.national_7day or {}
    end    
    --
    self.buyconfig = {}
    local buyconfig = {}
    for k,v in pairs(self.taskconfig) do
        if v.type and v.type == 19 then
            table.insert(buyconfig,v)
        end
    end
    local sortById = function(a,b) return a.id < b.id end
    table.sort(buyconfig, sortById)
    --
    for k,v in ipairs(buyconfig) do
        v.index = tonumber(k)
        self.buyconfig[tostring(v.id)] = v
    end
    --
    local showid = 0
    if self.taskconfig["80507"] and self.taskconfig["80507"].show and self.taskconfig["80507"].show > 0 then
        showid = self.taskconfig["80507"].show
        ui.setLabelString(self.rootItems.generalname_7,"“"..ui.IDconfig(showid).name..((ui.IDconfig(showid).staffType == "general_fragment") and "魂魄" or "").."”",9)
    end
    --

    if self.isinit then
        self.isinit = false
        self.selectday = self.targetday and self.targetday or ((self.day+0 <= 7) and self.day+0 or 7)

        local rday = 3
        if gamedata.config.peak_time and gamedata.config.peak_time["4"] and gamedata.config.peak_time["4"].day then
            rday = gamedata.config.peak_time["4"].day
        end

        -- self.rootItems["timelab"..2]:setString((8-self.day > 0) and (8-self.day).."天" or "已结束")
        -- self.rootItems["timelab"..4]:setString((11-self.day > 0) and (11-self.day).."天" or "已结束")
        self.rootItems["timelab"..2]:setString((8-self.day > 0) and gameConfig.strings:Day(8-self.day) or gameConfig.strings:string_common("moreCommon","yijieshu"))
        self.rootItems["timelab"..4]:setString((8+rday-self.day > 0) and gameConfig.strings:Day(8+rday-self.day) or gameConfig.strings:string_common("moreCommon","yijieshu"))
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

    self.showData = {}
    for k,v in pairs(self.dayconfig) do
        if tostring(k) == tostring(self.selectday) then
            for kk,vv in pairs(v) do
                self.rootItems["buttontext"..kk]:setString(vv.name)

                ui.sethint(self.rootItems["hint_title"..kk], GameScene.hintdata and GameScene.hintdata[tostring(self.hintconfig[1].config["day"..self.selectday][tonumber(kk)])]~=0)

                if tostring(kk) == tostring(self.pageindex[self.selectpage]) then
                    for i = 1,20 do
                        if vv["task"..i] and vv["task"..i] > 0 then
                            if self.status[tostring(self.taskconfig[tostring(vv["task"..i])].id-80500)] == 1 then
                                self.taskconfig[tostring(vv["task"..i])].sortdata = 4
                            elseif self.status[tostring(self.taskconfig[tostring(vv["task"..i])].id-80500)] == 0 then
                                self.taskconfig[tostring(vv["task"..i])].sortdata = 3
                            elseif self.status[tostring(self.taskconfig[tostring(vv["task"..i])].id-80500)] == 3 then
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
    table.sort(self.showData,sortfunc)

    if self.selectpage == "buy" then
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
    self:initPageShow()
end

function october1st.initPageShow(self)
    local showPages = {
    }
    local posX = 145
    local shownum = 0
    for i=1,4 do
        showPages[i] = false
        local pageConfig = self.dayconfig["1"][tostring(i)]
        for j=1,20 do
            if pageConfig["task"..j] and tonumber(pageConfig["task"..j]) > 0 then
                showPages[i] = true
                break
            end
        end

        if showPages[i] then
            self.rootItems["buttonnode"..i]:setVisible(true)
            self.rootItems["buttonnode"..i]:setPositionX(posX)
            posX = posX + 265
            shownum = shownum + 1
        else
            self.rootItems["buttonnode"..i]:setVisible(false)
            self.rootItems["buttonnode"..i]:setPositionX(9999)
        end
    end
    printT(showPages,"showPages")
    -- for i=1,4 do
    --     self.rootItems["buttonnode"..i]:setPositionX(self.rootItems["buttonnode"..i]:getPositionX() + (4 - shownum) * 265 / 2)
    -- end
end

function october1st.UIUpdateData(self, isreset)
    if isreset then
        self:request()
    end
end

return october1st
�~  