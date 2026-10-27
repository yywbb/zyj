--
-- Created by IntelliJ IDEA.
-- User: jkp
-- Date: 18-9-5
-- Time: 下午1:17
--

local zhongqiuactivity = {

    resource = nil,

    rootNode = nil,
    rootItems = nil,
    ListTableView = nil,
    activeListTableView = nil,
    buyListTableView = nil,

    pageindex = {
        daily = 1,
        power = 2,
        active = 3,
        buy = 4,
    },

    taskconfig = {},
    dayconfig = {},
    showData = {},
    status = {},
    status2 = {},
    status3 = {},
    data = {},
    buyconfig = {},

    pageconfig = {"daily","power","active","buy"},
    --pagename = {"","","",""},
    pagename = {"登录有礼","充值好礼","活跃活动","超值商店"},
    
    selectpage = "daily",
    hintconfig = {
        {
            name = "rootItems",
            type = "self",
            config = {
                400, 401,402,403
            },
        },
    },

    normalCellSize = {x=1080,y=236+14},
    activeCellSize = {x=1080,y=236+14},
    buyCellSize = {x=1080,y=236+14},

    --主界面Icon
    mainIcon = "b_mainicon_n_sanrikuanghuan"
    -- mainIcon = "b_n_mainicon_shengdankuanghuan"
    -- mainIcon = "b_n_mainicon_qingmingjie"

}

function zhongqiuactivity.shiftPage(self,type)
    local ispagechange = self.selectpage ~= type
    self.selectpage = type

    self:ReloadData(nil,ispagechange)
end

function zhongqiuactivity.init(self,parent,toppos,param)

    self.rootNode,self.rootItems = CCBReaderLoad("start2/sanrikuanghuan", nil, true, "sanrikuanghuan")
    -- self.rootNode,self.rootItems = CCBReaderLoad("start2/shengdankuanghuan", nil, true, "shengdankuanghuan")
    -- self.rootNode,self.rootItems = CCBReaderLoad("start2/qingming", nil, true, "qingming")

    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.listTitle:setVisible(false)
    self.rootItems.topnode:setPositionY(toppos)

    self.rootItems.listScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-740-160)) --三日
    self.rootItems.activeListScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-680-160))--三日
    self.rootItems.buyListScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-680-160)) --三日

    -- self.rootItems.listScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-740-160+85)) --万圣
    -- self.rootItems.activeListScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-680-160+85))--万圣
    -- self.rootItems.buyListScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-680-160+85)) --万圣

    -- self.rootItems.listScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-740-160+20)) --清明
    -- self.rootItems.activeListScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-680-160+10))--清明
    -- self.rootItems.buyListScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-680-160+10)) --清明

    -- 表数据
    self.taskconfig = gamedata.config.festival_day_task or {}
    self.dayconfig = gamedata.config.festival_day or {}
    local tiemconfig = gamedata.config.peak_time["10"] or {}
    if tiemconfig and tiemconfig ~= "" then
        
        local endString = ""
        local awardString = ""
        
        local year_end, month_end, day_end, hour_end, min_end, sec_end = ui.getDate(tiemconfig["end"])
        if tonumber(hour_end) < 1 and tonumber(min_end) < 1 and tonumber(sec_end) < 1 then
            local endt = os.time({year=tonumber(year_end),month=tonumber(month_end),day=tonumber(day_end),hour=tonumber(hour_end),min=tonumber(min_end),sec=tonumber(sec_end),isdst=false}) - 2
            local endtab = os.date("*t",endt)
            endString = endtab.month.."月"..endtab.day.."日24时"
        end
        local award_year, award_month, award_day, award_hour, award_min, award_sec = ui.getDate(tiemconfig["award"])
        if tonumber(award_hour) < 1 and tonumber(award_min) < 1 and tonumber(award_sec) < 1 then
            local awardt = os.time({year=tonumber(award_year),month=tonumber(award_month),day=tonumber(award_day),hour=tonumber(award_hour),min=tonumber(award_min),sec=tonumber(award_sec),isdst=false}) - 2
            local awardtab = os.date("*t",awardt)
            awardString = awardtab.month.."月"..awardtab.day.."日24时"
        end
        if self.rootItems.start_time2 then
            self.rootItems.start_time2:setString(endString)
            ui.setLabelString(self.rootItems.start_time1,nil,23)
            ui.setLabelString(self.rootItems.start_time2,nil,14)
        end
        if self.rootItems.end_time2 then
            self.rootItems.end_time2:setString(awardString)
            ui.setLabelString(self.rootItems.end_time1,nil,23)
            ui.setLabelString(self.rootItems.end_time2,nil,14)
        end

    end
    --
    self:initPageShow()
    self:request()

end

--设置页签隐藏显示
function zhongqiuactivity.initPageShow(self)


    -- local pageconfig = {"daily","power","active","buy"}
    -- local hintconfig = {400, 401,402,403}
    -- local showPages = {
    -- }

    -- self.pagename = {}
    -- self.pageconfig = {}
    -- self.pageindex = {}

    -- self.hintconfig.config = {}

    -- for i=1,4 do
    --     showPages[i] = false
    --     local pageConfig = gamedata.config.festival_day[tostring(i)]
    --     for j=1,20 do
    --         if pageConfig["task"..j] and pageConfig["task"..j] > 0 then
    --             showPages[i] = true
    --             break
    --         end
    --     end
    --     if showPages[i] then
    --         table.insert(self.pagename,pageConfig.name)
    --         table.insert(self.pageconfig,pageconfig[i])
    --         self.pageindex[pageconfig[i]] = i
    --         table.insert(self.hintconfig.config,hintconfig[i])
    --     end
    -- end

    -- self.selectpage = pageconfig[1]
    -- self.rootItems.pageNode:setPositionX((4-#self.pageconfig)*0.5 * 1080/4*0.9)



    local showPages = {
    }
    local posX = 145


    for i=1,4 do
        showPages[i] = false
        local pageConfig = gamedata.config.festival_day[tostring(i)]
        for j=1,20 do
            if pageConfig["task"..j] and pageConfig["task"..j] > 0 then
                showPages[i] = true
                break
            end
        end

        if showPages[i] then
            self.rootItems["buttonnode"..i]:setVisible(true)
            self.rootItems["buttonnode"..i]:setPositionX(posX)
            posX = posX + 265
        else
            self.rootItems["buttonnode"..i]:setVisible(false)
            self.rootItems["buttonnode"..i]:setPositionX(9999)
        end
    end

    if gamedata.config.system_intro["58"] then
        self.rootItems["desc"]:setString(gamedata.config.system_intro["58"].intro)
    end

    
end

function zhongqiuactivity.clear(self)
    self.taskconfig = {}
    self.dayconfig = {}
    self.showData = {}
    self.buyconfig = {}
    self.data = {}
    self.status = {}
    self.status2 = {}
    self.status3 = {}
    self.rootItems = nil
    self.ListTableView = nil
    self.activeListTableView = nil
    self.buyListTableView = nil
    self.selectpage = "daily"

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function zhongqiuactivity.setNormal(self,item,data,index)
    print("setNormal")

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

    -- 设置按键
    -- doNode1 : 前往
    -- doNode2 : 领取
    item.doButton1:setTouchPriority(-103)
    item.doButton2:setTouchPriority(-103)
    item.yilingqu:setVisible(false)
    item.doNode1:setVisible(false)
    item.doNode2:setVisible(false)
    item.doButton2:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        if self.status[tostring(data.id)] and self.status[tostring(data.id)] == 1 then
            gameTouch:clickprofbytime(1)
            print("领 取！！！")
            -- UIRequest({type = 6402, id = data.id})

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
                            UIRequest({type = 6402, id = data.id})
                        elseif index == 2 then -- 一键领取
                            UIRequest({type = 6402, id = data.id, rewardData = rewardData})
                        end
                    end
                    gameWindows:openWindow("onekeyall", nil, callback)
                else
                    UIRequest({type = 6402, id = data.id, rewardData = rewardData})
                end
            else
                UIRequest({type = 6402, id = data.id})
            end

        end
    end, CCControlEventTouchUpInside)

    if self.status[tostring(data.id)] and self.status[tostring(data.id)] == 1 then -- 领取
        item.doNode2:setVisible(true)
        --item.doLab2:setString("领 取")
        item.doLab2:setString(gameConfig.strings:string_common("moreCommon",6))
        ui.removeGray("CCControlButton",item.doButton2)
        ui.removeGray("CCLabelTTF",item.doLab2)
        ui.setLabelString(item.doLab2,nil,18)
    elseif self.status[tostring(data.id)] and self.status[tostring(data.id)] == 2 then -- 已领取
        item.yilingqu:setVisible(true)
    else -- 未达成
        item.doNode2:setVisible(true)
        --item.doLab2:setString("未达成")
        item.doLab2:setString(gameConfig.strings:string_common("moreCommon",7))
        ui.addGray("CCControlButton",item.doButton2)
        ui.addGray("CCLabelTTF",item.doLab2)
        ui.setLabelString(item.doLab2,nil,18)
    end

    -- 设置Lable
    item.title:setVisible(false)
    item.spritegold:setVisible(false)
    item.btn_title_1:setVisible(false)
    item.btn_title:setPositionX(890)
    if self.selectpage == "daily" then
        item.btn_title:setString(data.name..data.target.."天")
    elseif self.selectpage == "power" then
        item.btn_title:setString(data.name)

        if data.desc and tonumber(data.desc) == 1 then
            item.title:setVisible(true)
            local n = math.min(self.status3["2"],data.target)
            item.title:setString(data.name.." （"..n.."/"..data.target.."）")
        end
        
    end
    ui.setLabelString(item.btn_title, nil, 14)

end

function zhongqiuactivity.setActiveCell(self,item,data,index)
    print("setActiveCell")
    if self.selectpage ~= "active" then return end

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

    -- 设置按键
    -- doNode1 : 前往
    -- doNode2 : 领取
    item.doButton1:setTouchPriority(-103)
    item.doButton2:setTouchPriority(-103)
    item.yilingqu:setVisible(false)
    item.doNode1:setVisible(false)
    item.doNode2:setVisible(false)
    item.doButton2:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        if self.status[tostring(data.id)] and self.status[tostring(data.id)] == 1 then
            gameTouch:clickprofbytime(1)
            print("领 取！！！")
            -- UIRequest({type = 6402, id = data.id})
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
                            UIRequest({type = 6402, id = data.id})
                        elseif index == 2 then -- 一键领取
                            UIRequest({type = 6402, id = data.id, rewardData = rewardData})
                        end
                    end
                    gameWindows:openWindow("onekeyall", nil, callback)
                else
                    UIRequest({type = 6402, id = data.id, rewardData = rewardData})
                end
            else
                UIRequest({type = 6402, id = data.id})
            end
        end
    end, CCControlEventTouchUpInside)

    if self.status[tostring(data.id)] and self.status[tostring(data.id)] == 1 then -- 领取
        item.doNode2:setVisible(true)
        --item.doLab2:setString("领 取")
        item.doLab2:setString(gameConfig.strings:string_common("moreCommon",6))
        ui.removeGray("CCControlButton",item.doButton2)
        ui.removeGray("CCLabelTTF",item.doLab2)
        ui.setLabelString(item.doLab2,nil,18)
    elseif self.status[tostring(data.id)] and self.status[tostring(data.id)] == 2 then -- 已领取
        item.yilingqu:setVisible(true)
    else -- 未达成
        item.doNode2:setVisible(true)
        --item.doLab2:setString("未达成")
        item.doLab2:setString(gameConfig.strings:string_common("moreCommon",7))
        ui.addGray("CCControlButton",item.doButton2)
        ui.addGray("CCLabelTTF",item.doLab2)
        ui.setLabelString(item.doLab2,nil,18)
    end

    -- 设置Lable
    item.title:setVisible(false)
    item.spritegold:setVisible(false)
    item.btn_title_1:setVisible(false)
    item.btn_title:setPositionX(890)
    item.title:setVisible(true)
    item.title:setString(data.name)
    if self.status3[tostring(data.type)] and tonumber(self.status3[tostring(data.type)]) >= tonumber(data.target) then
        item.btn_title:setString("进度:（"..data.target.."/"..data.target.."）")
    else
        item.btn_title:setString("进度:（"..self.status3[tostring(data.type)].."/"..data.target.."）")
    end
    
    ui.setLabelString(item.btn_title, nil, 14)

end

function zhongqiuactivity.setBuyCell(self,item,data,index)
    print("setBuyCell")

    if self.selectpage ~= "buy" then return end

    local buydata = self.buyconfig[tostring(data.id)] or {}

    local rewards = ui.getIDandNUMs(buydata.rewards)
    local target = ui.getIDandNUMs(buydata.target)

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

    item.doButton1:setTouchPriority(-103)
    item.doButton2:setTouchPriority(-103)
    item.yilingqu:setVisible(false)
    item.doNode1:setVisible(false)
    item.doNode2:setVisible(true)
    --item.doLab2:setString("购买")
    item.doLab2:setString(gameConfig.strings:string_common("moreCommon","guomai"))

    ui.removeGray("CCControlButton",item.doButton2)
    ui.removeGray("CCLabelTTF",item.doLab2)
    ui.setLabelString(item.doLab2,nil,18)

    item.doButton2:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        gameTouch:clickprofbytime(1)
        if self.status2[tostring(buydata.index)] >= buydata.times then
            runGamePrompt({msg = "购买次数不足"})
        -- elseif GameScene.roleinfo.gold < target[1].num then
        --     runGamePrompt({msg = "元宝不足"})
        else
            print("购 买！！！")
            -- UIRequest({type = 6402, id = buydata.id, xgold = target[1].num or 0, cid = target[1].cid})
            local dotimes = self.status2[tostring(buydata.index)]
            local count = self:getCanBuyNum((buydata.times-dotimes), buydata.target)
            local cb = function( num )
                if num > 1 then
                    local rewardData = {}
                    for i=1,num do
                        table.insert(rewardData, buydata.id)
                    end
                    UIRequest({type = 6402, id = buydata.id, xgold = target[1].num or 0, cid = target[1].cid, rewardData = rewardData})
                else
                    UIRequest({type = 6402, id = buydata.id, xgold = target[1].num or 0, cid = target[1].cid})
                end
            end
            ui.exchangeMore(cb,9999,count,count,"buy")
        end
    end, CCControlEventTouchUpInside)

    item.title:setVisible(true)
    item.spritegold:setVisible(true)
    item.btn_title_1:setVisible(true)
    item.btn_title:setPositionX(833)
    item.btn_title_1:setString(tostring(target[1].num))
    
    item.title:setString("限购"..buydata.times.."次".."（")
    if item.title_num then
        if self.status2[tostring(buydata.index)] and (tonumber(buydata.times) - tonumber(self.status2[tostring(buydata.index)])) <= 0 then
            item.title_num:setString("0")
            ui.setLabelString(item.title_num, nil, 1001)
        else
            if self.status2[tostring(buydata.index)] then
                item.title_num:setString(tonumber(buydata.times) - tonumber(self.status2[tostring(buydata.index)]))
                ui.setLabelString(item.title_num, nil, 23)
            end
        end
        local posX = item.title:getPositionX() + item.title:getContentSize().width
        item.title_num:setPositionX(posX)
    else
        item.title:setString("限购"..buydata.times.."次".."（"..self.status2[tostring(buydata.index)].."/"..buydata.times.."）")
    end
    if item.title_end then
        item.title_end:setString("/"..buydata.times.."）")
        local posX = item.title_num:getPositionX() + item.title_num:getContentSize().width
        item.title_end:setPositionX(posX)
    end
    
    ui.setLabelString(item.btn_title, nil, 14)
    if GameScene.roleinfo.gold < target[1].num then
        ui.setLabelString(item.btn_title_1, nil, 1001)
    else
        ui.setLabelString(item.btn_title_1, nil, 14)
    end

    if self.status2[tostring(buydata.index)] >= buydata.times then
        ui.addGray("CCControlButton",item.doButton2)
        ui.addGray("CCLabelTTF",item.doLab2)
    end
    
end

function zhongqiuactivity.getCanBuyNum(self, maxnum, once)
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

function zhongqiuactivity.createList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("start2/cell_zhongqiu", nil, true, "cell_520")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            --设置cell内容
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

function zhongqiuactivity.createActiveList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("start2/cell_zhongqiu", nil, true, "cell_520")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            --设置cell内容
            self:setActiveCell(ccbDocumentControler,self.showData[a1+1],a1+1)

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

    self.activeListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.activeListScroll:getContentSize().width,
        viewheight = self.rootItems.activeListScroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.activeListScroll:addChild(self.activeListTableView)
    self.activeListTableView:setTouchPriority(-101)
end

function zhongqiuactivity.createBuyList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("start2/cell_zhongqiu", nil, true, "cell_zhongqiu")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            --设置cell内容
            self:setBuyCell(ccbDocumentControler, self.showData[a1+1], a1+1)

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
        viewwidth = self.rootItems.buyListScroll:getContentSize().width,
        viewheight = self.rootItems.buyListScroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.buyListScroll:addChild(self.buyListTableView)
    self.buyListTableView:setTouchPriority(-101)
end


function zhongqiuactivity.request(self)

    UIRequest({type = 6401, ids = nil,})

end

function zhongqiuactivity.reloadHint(self)

    for k,v in pairs(self.dayconfig) do
        if GameScene.hintdata and GameScene.hintdata and GameScene.hintdata[tostring(self.hintconfig[1].config[tonumber(k)])] ~= 0 then
            ui.sethint(self.rootItems["hint_title"..k], true)
        else
            ui.sethint(self.rootItems["hint_title"..k], false)
        end
        --ui.sethint(self.rootItems["hint_title"..k], true)
    end

end

function zhongqiuactivity.ReloadData(self,data,ispagechange)
    print("ReloadData")

    printT(data, "data")

    self.data = data or self.data
    self.status = self.data["1"] or {} --任务状态        
    self.status2 = self.data["2"] or {}--珍品折扣兑换次数
    self.status3 = self.data["3"] or {}--任务类型数据

    if self.data["0"] and self.data["0"]["1"] and self.data["0"]["1"] > 0 then
    else 
        GameScene:shiftLayer("main","down")   
        return   
    end    

    self.showData = {}
    for k,v in pairs(self.dayconfig) do

        if GameScene.hintdata and GameScene.hintdata and GameScene.hintdata[tostring(self.hintconfig[1].config[tonumber(k)])] ~= 0 then
            ui.sethint(self.rootItems["hint_title"..k], true)
        else
            ui.sethint(self.rootItems["hint_title"..k], false)
        end

        if tostring(k) == tostring(self.pageindex[self.selectpage]) then
            for i = 1, 20 do
                if v["task"..i] and v["task"..i] > 0 then
                    if self.status[tostring(v["task"..i])] == 1 then
                        self.taskconfig[tostring(v["task"..i])].sortdata = 4
                    elseif self.status[tostring(v["task"..i])] == 0 then
                        self.taskconfig[tostring(v["task"..i])].sortdata = 3
                    elseif self.status[tostring(v["task"..i])] == 2 then
                        self.taskconfig[tostring(v["task"..i])].sortdata = 2
                    else
                        self.taskconfig[tostring(v["task"..i])].sortdata = 1
                    end
                    table.insert(self.showData, self.taskconfig[tostring(v["task"..i])])
                end
            end
        end
    end
    -- 排序
    local sortfunc = function(a,b)
        if a["sortdata"] == b["sortdata"] then
            return a.id<b.id
        else
            return a["sortdata"] > b["sortdata"]
        end
    end
    table.sort(self.showData,sortfunc)

    if self.selectpage == "buy" then
        self.rootItems.listTitle:setVisible(false)
        self.buyconfig = {}
        local buyconfig = {}
        for k,v in pairs(self.taskconfig) do
            for kk,vv in pairs(self.dayconfig[tostring(self.pageindex[self.selectpage])]) do
                if tostring(k) == tostring(vv)  then
                    table.insert(buyconfig,v) --todo 珍品折扣
                end
            end
        end
        local sortById = function(a,b) return a.id < b.id end
        table.sort(buyconfig, sortById)

        for k,v in ipairs(buyconfig) do
            v.index = tonumber(k)
            self.buyconfig[tostring(v.id)] = v
        end

        -- 设置滚动层位置
        self.rootItems.listScroll:setPositionX(9999)
        self.rootItems.activeListScroll:setPositionX(9999)
        self.rootItems.buyListScroll:setPositionX(0)
        if not self.buyListTableView then
             self:createBuyList()
        else
            self.buyListTableView:reloadData()
            if ispagechange then
                self.buyListTableView:setLuaContentOffset(0, self.rootItems.buyListScroll:getContentSize().height - table.getTableLength(self.buyconfig)*self.buyCellSize.y)
            end
        end
    elseif self.selectpage == "active" then
        self.rootItems.listTitle:setVisible(false)

        self.rootItems.listScroll:setPositionX(9999)
        self.rootItems.activeListScroll:setPositionX(0)
        self.rootItems.buyListScroll:setPositionX(9999)
        if not self.activeListTableView then
             self:createActiveList()
        else
            self.activeListTableView:reloadData()
            if ispagechange then
                self.activeListTableView:setLuaContentOffset(0, self.rootItems.activeListScroll:getContentSize().height - table.getTableLength(self.showData)*self.activeCellSize.y)
            end
        end

    else
        self.rootItems.listTitle:setVisible(true)
        if self.selectpage == "daily" then
            self.rootItems.listTitle:setString("当前累计登录："..self.status3["1"].."天")
        elseif self.selectpage == "power" then
            self.rootItems.listTitle:setString("当前累计充值："..self.status3["2"].."元")
        end

        self.rootItems.listScroll:setPositionX(0)
        self.rootItems.activeListScroll:setPositionX(9999)
        self.rootItems.buyListScroll:setPositionX(9999)
        if not self.ListTableView then
             self:createList()
        else
            self.ListTableView:reloadData()
            if ispagechange then
                self.ListTableView:setLuaContentOffset(0, self.rootItems.listScroll:getContentSize().height - table.getTableLength(self.showData)*self.normalCellSize.y)
            end
        end
    end
end

function zhongqiuactivity.UIUpdateData(self, isreset)
    if isreset then
        self:request()
    end
end

return zhongqiuactivity
�{  