--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-9
-- Time: 下午6:52
-- To change this template use File | Settings | File Templates.
--

local startactivity = {

    resource = nil,

    rootNode = nil,
    rootItems = nil,
    ListTableView = nil,

    selectday = 1,
    pageindex = {
        daily = 1,
        power = 2,
        level = 3,
        buy = 4,
    },
    taskconfig = {},
    dayconfig = {},
    showData = {},
    status = {},
    status2 = {},
    status3 = {},
    data = {},
    isinit = true,

    pageconfig = {"daily","power","level","buy"},
    pagename = {"","","",""},
    --pagename = {gameConfig.strings:string_common("startactivity",0),gameConfig.strings:string_common("startactivity",1),gameConfig.strings:string_common("startactivity",2),gameConfig.strings:string_common("startactivity",3)},
    selectpage = "daily",
    hintconfig = {
        {
            name = "rootItems",
            type = "self",
            config = {
                day1 = {82,83,84,85},
                day2 = {86,87,88,89},
                day3 = {90,91,92,93},
                day4 = {94,95,96,97},
                day5 = {98,99,100,101},
                day6 = {102,103,104,105},
                day7 = {106,107,108,109},
            },
        },
    },



    normalCellSize = {x=1080,y=282+14},
}

function startactivity.shiftPage(self,type)
    local ispagechange = self.selectpage ~= type
    self.selectpage = type

    self:ReloadData(nil,ispagechange)
end

function startactivity.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("start2/n_kaifuqiri", nil, true, "kaifuqiri")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.targetday = nil
    if param and param.selectday then
        self.targetday = param.selectday
    end


    self.rootItems.topnode:setPositionY(toppos)

    self.rootItems.listScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-550-160))

--    self.rootItems["generalNode"]:removeAllChildrenWithCleanup(true)
--    local Gneral1 = CCSkeletonAnimation:create("change/change.json","change/change.atlas",1)
--    Gneral1:setAnimation("stand",true,0)
--    Gneral1:setScale(2.2)
--    Gneral1:setPosition(0,0)
--    self.rootItems["generalNode"]:addChild(Gneral1)
    --
    ui.setLabelString(self.rootItems["timelab"..1],nil,121)
    ui.setLabelString(self.rootItems["timelab"..2],nil,26)
    ui.setLabelString(self.rootItems["timelab"..3],nil,121)
    ui.setLabelString(self.rootItems["timelab"..4],nil,27)
    --

    for i = 1,7 do

        self.rootItems["isday"..i]:setVisible(false)
        self.rootItems["button_day"..i]:setTouchPriority(-102)
        self.rootItems["button_day"..i]:addHandleOfControlEvent(function()
            --if self.day and self.day+0 < i then
            --    runGamePrompt({msg = "活动未开启"})
            --    return
            --end
            local ispagechange = self.selectday ~= i
            self.selectday = i
            self:ReloadData(nil,ispagechange)
        end, CCControlEventTouchUpInside)
    end
    self.rootItems["isday"..self.selectday]:setVisible(true)
    --
    self.rootItems.button_help:setTouchPriority(-102)
    self.rootItems.button_help:addHandleOfControlEvent(function()
        gameWindows:openWindow("startactivityhelp",{})
    end, CCControlEventTouchUpInside)
    --
    self.taskconfig = gamedata.config.begin7day_task or {}
    self.dayconfig = gamedata.config.begin7day or {}
    --
    local showid = 10404
    if self.taskconfig["80007"].show and self.taskconfig["80007"].show > 0 then
        showid = self.taskconfig["80007"].show
    end
    ui.setLabelString(self.rootItems.generalname_7,"“"..gamedata.config.general[tostring(showid)].name.."”",9)
    --
    self:request()
end

function startactivity.clear(self)
    self.isinit = true
    self.selectday = 1
    self.taskconfig = {}
    self.dayconfig = {}
    self.showData = {}
    self.data = {}
    self.status = {}
    self.status2 = {}
    self.status3 = {}
    self.rootItems = nil
    self.ListTableView = nil
    self.selectpage = "daily"

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function startactivity.setNormal(self,item,data,index)
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
    if self.status[tostring(data.id-80000)] and self.status[tostring(data.id-80000)] == 1 then
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
                -- UIRequest({type = 3611, id = data.id,})

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
                                UIRequest({type = 3611, id = data.id})
                            elseif index == 2 then -- 一键领取
                                UIRequest({type = 3611, id = data.id, rewardData = rewardData})
                            end
                        end
                        gameWindows:openWindow("onekeyall", nil, callback)
                    else
                        UIRequest({type = 3611, id = data.id, rewardData = rewardData})
                    end
                else
                    UIRequest({type = 3611, id = data.id})
                end
                
            end
        end, CCControlEventTouchUpInside)
    elseif self.status[tostring(data.id-80000)] and self.status[tostring(data.id-80000)] == 2 then
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
        item.nonenode:setVisible(true)
        item.doNode:setVisible(false)
        item.hasnode:setVisible(false)
        --
        if item.nonelab and self.day and self.day+0 > 7 then
            item.nonelab:setString(gameConfig.strings:string_common("moreCommon","yijieshu"))
        elseif item.nonelab then
            item.nonelab:setString(gameConfig.strings:string_common("moreCommon",4))
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
    if data.type == 2 then
        item.title:setString(data.name.."    ( "..(self.status2["1"] or 0).."/"..(num[1] or 0).." ) ")
    elseif data.type == 7 then
        item.title:setString(data.name.."    ( "..(self.status2[tostring(num[1])] or 0).."/"..(num[2] or 0).." ) ")
    elseif data.type == 8 then
        item.title:setString(data.name.."    ( "..(self.status2["6"] or 0).."/"..(num[1] or 0).." ) ")
    elseif data.type == 10 then
        item.title:setString(data.name.."    ( "..(self.status2[tostring(num[1]+4)] or 0).."/"..(num[2] or 0).." ) ")
    elseif data.type == 16 then
        item.title:setString(data.name.."    ( "..(self.status2["10"] or 0).."/"..(num[1] or 0).." ) ")
    elseif data.type == 18 then
        item.title:setString(data.name.."    ( "..(self.status2["11"] or 0).."/"..(num[1] or 0).." ) ")
    elseif data.type == 23 then
        item.title:setString(data.name.."    ( "..(GameScene.roleinfo.level or 1).."/"..(num[1] or 0).." ) ")
    elseif data.type == 20 then
        item.title:setString(data.name.."    ( "..(GameScene.protagonist.level2 or 0).."/"..(num[1] or 0).." ) ")
    end

end

function startactivity.setbuynode(self,data)
    print("setbuynode")
    -- self.rootItems.buy_desc:setString("仅限前"..(reward[4] or 0).."名购买 (剩余"..(reward[4]-self.status3[tostring(self.showData[1].id-(buyid-1))] or 0).."件)")
    --setSpriteFrameByName(PageCursor.selectedpoint, "cursorpageoff.png")
    local buyid = 90000
    for k,v in pairs(gamedata.config.begin7day_task) do
        if v.type+0 == 22 and v.id+0 < buyid+0 then
            buyid = v.id
        end
    end

    local target = ui.Split(self.showData[1].target or "", ";")
    local reward = ui.Split(target[1] or "", ",")
    if not (reward[1] and reward[1]+0 > 0) then
       return
    end
    self.rootItems.buy_name:setString(gamedata.config.props[tostring(reward[1])].name)
    ui.setLabelString(self.rootItems.buy_name,nil, gamedata.config.props[tostring(reward[1])].quality and 2*gamedata.config.props[tostring(reward[1])].quality-1 or 1)
    ui.setNewIcon(self.rootItems,{cid = reward[1]+0})
    self.rootItems.goldold:setString("原价: "..(reward[2] or 0))
    ui.setLabelString(self.rootItems.goldold,nil,18)
    --
    local discount = ui.Split(self.showData[1].discount or "", ";")
    local sale = {}
    for i = 1,4 do
        table.insert(sale,ui.Split(discount[i] or "", ","))
    end
    --
    local index = 4
    local nums = {0,0,0,0}
    --
    for i = 4,1,-1 do
        self.rootItems["pointok"..i]:setVisible(false)
        self.rootItems["num"..i]:setVisible(false)
        setSpriteFrameByName(self.rootItems["point"..i], "sta_11")
        setSpriteFrameByName(self.rootItems["zhe"..i], (i==1 and "f_" or "")..sale[i][1].."zhe")
        ui.addGray("CCSprite",self.rootItems["zhe"..i])
        self.rootItems["end"..i]:setVisible(false)
        self.rootItems["pointNode"..i]:setScale(1)
        ui.setLabelString(self.rootItems["gold"..i],math.floor(reward[2]*sale[i][1]/10),21)
        local nnum = 0
        for j = 1,i do
            nnum = nnum + sale[j][2]
            nums[i] = nnum
        end
        if i == 4 then
            ui.setLabelString(self.rootItems["num"..i],"不限量",13)
        elseif nnum > (self.status3[tostring(self.showData[1].id-(buyid-1))] or 0) then
            index = i
            ui.setLabelString(self.rootItems["num"..i],"剩余: "..sale[i][2],13)
        else
            ui.setLabelString(self.rootItems["num"..i],"剩余: 0",13)
            setSpriteFrameByName(self.rootItems["point"..i], "sta_13")
            --ui.addGray("CCSprite",self.rootItems["zhe"..i])
            self.rootItems["end"..i]:setVisible(true)
        end
    end
    if self.selectday <= self.day then
        self.rootItems["pointok"..index]:setVisible(true)
        self.rootItems["num"..index]:setVisible(true)
        ui.removeGray("CCSprite",self.rootItems["zhe"..index])
        setSpriteFrameByName(self.rootItems["point"..index], "sta_12")
        self.rootItems["pointNode"..index]:setScale(1.2)
    end
    -- 852  , 284
    if index == 4 then
        self.rootItems["pos"]:setScaleX(1)
    else
        ui.setLabelString(self.rootItems["num"..index],"剩余: "..(nums[index]-(self.status3[tostring(self.showData[1].id-(buyid-1))] or 0)),13)
        self.rootItems["pos"]:setScaleX((284*(index-1)+284*((sale[index][2]-(nums[index]-(self.status3[tostring(self.showData[1].id-(buyid-1))] or 0)))/sale[index][2]))/852)
    end
    --
    local xgold = math.floor(reward[2]*sale[index][1]/10)
    --
    ui.setLabelString(self.rootItems.buy_desc,nil,22)
    --
    self.rootItems["i_button"]:addHandleOfControlEvent(function()
        ui.setPopwindowByCid(reward[1]+0)
    end, CCControlEventTouchUpInside)
    self.rootItems["i_button"]:setTouchPriority(-103)

    if self.status[tostring(self.showData[1].id-80000)] and self.status[tostring(self.showData[1].id-80000)] == 1 then
        ui.removeGray("CCControlButton",self.rootItems.buyButton)
        ui.removeGray("CCLabelTTF",self.rootItems.buyLab)
        -- self.rootItems.buyLab:setString("购 买")
        self.rootItems.buyLab:setString(gameConfig.strings:string_common("moreCommon","guomai"))
        ui.setLabelString(self.rootItems.buyLab,nil,19)
        self.rootItems.buyButton:setTouchPriority(-102)
        self.rootItems.buyButton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            if xgold > 500 then
                local function bagCB()
                    UIRequest({type = 3611, id = self.showData[1].id, index = index, xgold = xgold or 0})            
                end
                local cost = {{cid = 1001, num = xgold or 0}}
                gameWindows:openWindow("shopExchange",{cid = reward[1]+0, num = 1, cost = cost, exchangeNum = 1, ccbtype = 2}, bagCB)
            else
                UIRequest({type = 3611, id = self.showData[1].id, index = index, xgold = xgold or 0})
            end
        end, CCControlEventTouchUpInside)
    elseif self.status[tostring(self.showData[1].id-80000)] and self.status[tostring(self.showData[1].id-80000)] == 2 then
        ui.addGray("CCControlButton",self.rootItems.buyButton)
        ui.addGray("CCLabelTTF",self.rootItems.buyLab)
        -- self.rootItems.buyLab:setString("已购买")
        self.rootItems.buyLab:setString(gameConfig.strings:string_common("moreCommon",10))
        ui.setLabelString(self.rootItems.buyLab,nil,19)
        self.rootItems.buyButton:setTouchPriority(-102)
        self.rootItems.buyButton:addHandleOfControlEvent(function()
            print("buy")
            -- runGamePrompt({msg = "已购买"})
            runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",10)})
        end, CCControlEventTouchUpInside)
    else
        ui.addGray("CCControlButton",self.rootItems.buyButton)
        ui.addGray("CCLabelTTF",self.rootItems.buyLab)
        -- self.rootItems.buyLab:setString("购 买")
        self.rootItems.buyLab:setString(gameConfig.strings:string_common("moreCommon","guomai"))
        ui.setLabelString(self.rootItems.buyLab,nil,19)
        self.rootItems.buyButton:setTouchPriority(-102)
        self.rootItems.buyButton:addHandleOfControlEvent(function()
            print("buy")
            -- runGamePrompt({msg = "无法购买"})
            runGamePrompt({msg = gameConfig.strings:string_common("startactivity",4)})
        end, CCControlEventTouchUpInside)
    end
end

function startactivity.createList(self)
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


function startactivity.request(self)

    local ids = {
        [1] = 0,
        [2] = self.selectday,
        [3] = self.pageindex[self.selectpage]
    }
    UIRequest({type = 3610, ids = nil,})

end

function startactivity.reloadHint(self)
    for k,v in pairs(self.dayconfig) do
        if tostring(k) == tostring(self.selectday) then
            for kk,vv in pairs(v) do
                ui.sethint(self.rootItems["hint_title"..kk], GameScene.hintdata and GameScene.hintdata[tostring(self.hintconfig[1].config["day"..self.selectday][tonumber(kk)])]~=0)
            end
        end
    end
    --self:checkHint()
end

function startactivity.checkHint(self)
    if self.day then
        for i=1,7 do
            if self.day+0<i then
                ui.sethint(self.rootItems["hint_day"..i],false)
            end
        end
    end
end


function startactivity.ReloadData(self,data,ispagechange)
    print("ReloadData")

    printT(data, "开服狂欢")

    self.data = data or self.data
    self.status =  self.data["1"] or {}
    self.status2 = self.data["2"] or {}
    self.status3 = self.data["3"] or {}
    self.day = self.data["0"] and self.data["0"]["1"]+0 or 1

    if self.isinit then
        self.isinit = false
        self.selectday = self.targetday and self.targetday or ((self.day+0 <= 7) and self.day+0 or 7)

        -- self.rootItems["timelab"..2]:setString((8-self.day > 0) and (8-self.day).."天" or "已结束")
        -- self.rootItems["timelab"..4]:setString((11-self.day > 0) and (11-self.day).."天" or "已结束")
        self.rootItems["timelab"..2]:setString((8-self.day > 0) and gameConfig.strings:Day(8-self.day) or gameConfig.strings:string_common("moreCommon","yijieshu"))
        self.rootItems["timelab"..4]:setString((11-self.day > 0) and gameConfig.strings:Day(11-self.day) or gameConfig.strings:string_common("moreCommon","yijieshu"))
        ui.setLabelString(self.rootItems["timelab"..2],nil,26)
        ui.setLabelString(self.rootItems["timelab"..4],nil,27)
    end

    self.showData = {}
    for k,v in pairs(self.dayconfig) do
       if tostring(k) == tostring(self.selectday) then
           for kk,vv in pairs(v) do
               self.rootItems["buttontext"..kk]:setString(vv.name)

               ui.sethint(self.rootItems["hint_title"..kk], GameScene.hintdata and GameScene.hintdata[tostring(self.hintconfig[1].config["day"..self.selectday][tonumber(kk)])]~=0)

               if tostring(kk) == tostring(self.pageindex[self.selectpage]) then
                   for i = 1,10 do
                       if vv["task"..i] and vv["task"..i] > 0 then
                            if self.status[tostring(self.taskconfig[tostring(vv["task"..i])].id-80000)] == 1 then
                                self.taskconfig[tostring(vv["task"..i])].sortdata = 4
                            elseif self.status[tostring(self.taskconfig[tostring(vv["task"..i])].id-80000)] == 0 then
                                self.taskconfig[tostring(vv["task"..i])].sortdata = 3
                            elseif self.status[tostring(self.taskconfig[tostring(vv["task"..i])].id-80000)] == 3 then
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
    --print("1234567890-----")
    --printT(self.showData)

    if self.selectpage == "buy" then
        self.rootItems.listScroll:setPositionX(-9999)
        self.rootItems.listbg:setVisible(false)
        self.rootItems.buynode:setVisible(true)
        self:setbuynode()
    elseif self.rootItems then
        self.rootItems.listScroll:setPositionX(0)
        self.rootItems.listbg:setVisible(true)
        self.rootItems.buynode:setVisible(false)
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

function startactivity.UIUpdateData(self, isreset)
    if isreset then
        self:request()
    end
end

return startactivity
 g[  