--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/25
-- Time: 15:30
-- To change this template use File | Settings | File Templates.
--

local limitex = {
    isscrolltouched = false,
    ListTableView = nil,
    normalCellSize = {x=1080,y=228+14},
    m_iFreshTimes = nil,
}

LX_BASEGOLD = 50


function limitex.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("activityxianshi/activityxianshi",nil, true, "limitex")

    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    self.coveritems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-640-180))


    ui.setLabelString(self.coveritems.m_obtttf,gameConfig.strings:string_common("limitex",2),18)
    self.coveritems.m_obutton:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        local nextindex = self.m_iFreshTimes+1
        if nextindex > table.getTableLength(gamedata.config.buycount_price) then
            nextindex = table.getTableLength(gamedata.config.buycount_price)
        end
        local tmpGold = tonumber(gamedata.config.buycount_price[tostring(nextindex)]["limitexchange_cost"])
        --if tmpGold > GameScene.roleinfo.gold then
        --    runGamePrompt({msg = gameConfig.strings:string_common("guild_shangxiang",3)})
        --else
        UIRequest({type = 5054,gold = tmpGold})
    --end
    end, CCControlEventTouchUpInside)
    self.coveritems.m_obutton:setTouchPriority(-103)

    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","limitex",touchbegin)

    local function touchend(pos)
        if self.coveritems.listnode and ui.isTouched(self.coveritems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","limitex",touchend)

    --
    if self.coveritems.freshLab then
        local refreshConfig = gamedata.config.limit_time_exchangetime or {}
        self.coveritems.freshLab:setString(string.format(gameConfig.strings:string_common("limitex",7),(refreshConfig["1"] and refreshConfig["1"].time or 9),(refreshConfig["2"] and refreshConfig["2"].time or 21)).."，\n  红色伙伴精华每日最多兑换5次")
    end
    self:setRefreshTime()

    return self.coverccb
end

function limitex.setRefreshTime(self)
    local nowtime = os.date("*t", gamedata:time())
    local refreshConfig = gamedata.config.limit_time_exchangetime or {}
    for i = 1,table.getTableLength(refreshConfig) do
        if refreshConfig[tostring(i)] and refreshConfig[tostring(i)].time > nowtime.hour then
            gameTimer:rigistTime("limitexRefreshTime",(refreshConfig[tostring(i)].time-nowtime.hour)*3600-nowtime.min*60-nowtime.sec+1)
            if gameTimer.times["limitexRefreshTime"] and gameTimer.times["limitexRefreshTime"] > 0 then
                gameTimer:rigistTimeFunc("limitexRefreshTime", function()
                    if gameTimer.times["limitexRefreshTime"] <= 0 then
                        gameTimer:UnrigistTimeFunc("limitexRefreshTime")
                        UIRequest({type = 5052})
                        self:setRefreshTime()
                    end
                end)
            end
            --
            return
        end
    end
    --
end

function limitex.reloaddata(self,data)

    local cpnum = data and data.cpnum or 0
    local cpday = data and data.cpday or 0
    --
    local endString = ""
    if gamedata.config.activity_time["95"]["open_type"] and gamedata.config.activity_time["95"]["open_type"] == 5 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", nowtime)
        local timediff = nowtime + 86400*(gamedata.config.activity_time["95"]["continued_time"..((cpnum == 1) and ("_1") or "")]-cpday+1) - temp.hour*3600 - temp.min*60 - temp.sec
        local endtab = os.date("*t", timediff-2)
        endString = endtab.month.."月"..endtab.day.."日24时"
    elseif gamedata.config.activity_time["95"]["open_type"] and gamedata.config.activity_time["95"]["open_type"] == 1 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", GameScene.roleinfo.servertime)
        local timediff = 0
        timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["95"]["continued_time"]+(gamedata.config.activity_time["95"]["days_later"] or 0)) - temp.hour*3600 - temp.min*60 - temp.sec
        if timediff < nowtime then
            timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["95"]["continued_time"]+(gamedata.config.activity_time["95"]["days_later2"] or 0)) - temp.hour*3600 - temp.min*60 - temp.sec
        end
        local endtab = os.date("*t", timediff-2)
        --endString = endtab.year..gameConfig.strings:string_common("goddownrank",13)..endtab.month..gameConfig.strings:string_common("goddownrank",14)..endtab.day..gameConfig.strings:string_common("goddownrank",15)
        endString = endtab.month.."月"..endtab.day.."日24时"
    elseif gamedata.config.activity_time["95"]["end"] and gamedata.config.activity_time["95"]["end"] ~= "" then
        local year, month, day, hour, min, sec = ui.getDate(gamedata.config.activity_time["95"]["end"])
        endString = year.."."..month.."."..day
        if tonumber(hour) < 1 and tonumber(min) < 1 and tonumber(sec) < 1 then
            local endt = os.time({year=tonumber(year),month=tonumber(month),day=tonumber(day),hour=tonumber(hour),min=tonumber(min),sec=tonumber(sec),isdst=false}) - 2
            local endtab = os.date("*t",endt)
            --endString = endtab.year.."."..endtab.month.."."..endtab.day
            endString = endtab.month.."月"..endtab.day.."日24时"
        end
    end

    self.coveritems.m_oTimeNum:setString(string.format(gameConfig.strings:string_common("limitex",6),endString))
    --

    --
    self.m_iFreshTimes = data._freshTimes
    local nextindex = self.m_iFreshTimes+1
    if nextindex > table.getTableLength(gamedata.config.buycount_price) then
        nextindex = table.getTableLength(gamedata.config.buycount_price)
    end
    ui.setLabelString(self.coveritems.m_oGoldNum,gamedata.config.buycount_price[tostring(nextindex)]["limitexchange_cost"],14)
    self.data = data._item
    -- printT(self.data,"self.data==")
    if not self.show then return end
    if self.coveritems then
        if not self.ListTableView then
            self:createList()
        else
            self.ListTableView:reloadData()
        end
    end
end

function limitex.createList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityxianshi/cell_activityxianshi", nil, true, "limitex_cell")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.setLabelString(ccbDocumentControler.m_obtttf,gameConfig.strings:string_common("limitex",3),18)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCell(ccbDocumentControler,a1+1)

            cellCCB:setPosition(self.normalCellSize.x/2, 14)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.data)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            ----gameTouch.isScrollling = true
        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.coveritems.listnode:getContentSize().width,
        viewheight = self.coveritems.listnode:getContentSize().height,
        dire = 1
    })
    self.coveritems.listnode:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(-101)
end

function limitex.setCell(self,item,destIndex)
    local tmpData = self.data[tostring(destIndex)]
    local tmpCanDothat = true
    local canExchangeNum  = 99999999
    local needGold = 0

    item.m_oExchangeNum:setString(string.format(gameConfig.strings:string_common("limitex",1),tmpData._once))


    if tmpData._once > 0 then
        ui.removeGray("CCControlButton",item.m_obutton)
    else
        ui.addGray("CCControlButton",item.m_obutton)
    end
    -- printT(tmpData,"tmpData===")
    item["m_oDeng"]:setVisible(false)
    item["m_oGet3"]:setVisible(false)
    local tmpAddIndexs = 1
    for i=1,3 do
        item["m_oNeed"..i]:setVisible(false)
        if i > 1 then
            item["m_oJia"..i]:setVisible(false)
        end
        local tmpCheackIndex = tostring(i)
        if tmpData._item[tmpCheackIndex] then
            tmpAddIndexs = tmpAddIndexs + 1
            item["m_oNeed"..i]:setVisible(true)
            if i > 1 then
                setSpriteFrameByName(item["m_oJia"..i],"spr_135.png")
                item["m_oJia"..i]:setVisible(true)
            end
            local config = ui.IDconfig(tmpData._item[tmpCheackIndex].cid)
            if config then
                -- tmpData._nums[tmpCheackIndex].num.."/"..tmpData._item[tmpCheackIndex].num
                local tmpStrNum
                
                if tonumber(tmpData._item[tmpCheackIndex].cid) < 1000 or tonumber(tmpData._item[tmpCheackIndex].cid) > 1026 then
                    tmpStrNum = tmpData._nums[tmpCheackIndex].num.."/"..tmpData._item[tmpCheackIndex].num
                else
                    tmpStrNum = tmpData._item[tmpCheackIndex].num
                end
                ui.setNewIcon(item,{cid = tmpData._item[tmpCheackIndex].cid, num = tmpStrNum,},i-1)
                canExchangeNum = canExchangeNum > math.floor(tmpData._nums[tmpCheackIndex].num/tmpData._item[tmpCheackIndex].num) and math.floor(tmpData._nums[tmpCheackIndex].num/tmpData._item[tmpCheackIndex].num) or canExchangeNum
                if tmpData._item[tmpCheackIndex].cid == 1001 then
                    needGold = tmpStrNum or 0
                end
                local key_Ex
                if i == nil or i == 1 then
                    key_Ex = ""
                else
                    key_Ex = "_"..(i-1)
                end

                if tmpCanDothat and tmpData._nums[tmpCheackIndex].num < tmpData._item[tmpCheackIndex].num then
                    tmpCanDothat = false
                end

                if tmpData._nums[tmpCheackIndex].num < tmpData._item[tmpCheackIndex].num then
                    ui.setLabelString(item["i_num"..key_Ex],nil,24)
                else
                    ui.setLabelString(item["i_num"..key_Ex],nil,13)
                end

                local tmpBtIndex = "i_button"..(i>1 and "_"..i-1 or "")
                item[tmpBtIndex]:addHandleOfControlEvent(function()
                    if not self.isscrolltouched then return end
                    if GameScene.layers["activity"].module.isContentScroll then  return end
                    ui.setPopwindowByCid(tmpData._item[tmpCheackIndex].cid)
                end, CCControlEventTouchUpInside)
                item[tmpBtIndex]:setTouchPriority(-103)
            end
        end
    end

    if tmpAddIndexs < 4 then
        item["m_oNeed"..tmpAddIndexs]:setVisible(true)
        setSpriteFrameByName(item["m_oJia"..tmpAddIndexs],"spr_136.png")
        item["m_oJia"..tmpAddIndexs]:setVisible(true)
    else
        item["m_oDeng"]:setVisible(true)
        item["m_oGet3"]:setVisible(true)
    end
    ui.setNewIcon(item,{cid = tmpData._exchange["1"], num = tmpData._exchange["2"],},tmpAddIndexs - 1)
    item["i_button_"..(tmpAddIndexs - 1)]:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if GameScene.layers["activity"].module.isContentScroll then  return end
        ui.setPopwindowByCid(tmpData._exchange["1"])
    end, CCControlEventTouchUpInside)
    item["i_button_"..(tmpAddIndexs - 1)]:setTouchPriority(-103)

    item.m_obutton:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if GameScene.layers["activity"].module.isContentScroll then  return end
        if tmpData._level <= tmpData._selfLevel then
            if tmpData._vip <= tmpData._selfVip then
                if tmpData._once > 0 then
                    if tmpCanDothat then
                        local callback =  function(num)
                            UIRequest({type = 5053,_id = tmpData._IdIndex,_num = num})
                        end
                        if tmpData._max > 5 then
                            ui.exchangeMore(callback,canExchangeNum,tmpData._once,tmpData._max)
                        else
                            if needGold > 500 then
                                gameWindows:openWindow("confirm",{msg = "是否确认兑换/购买"}, callback)
                            else
                                callback(1)
                            end
                        end
                    else
                        runGamePrompt({msg = gameConfig.strings:string_common("exchange",1)})
                    end
                else
                    runGamePrompt({msg = gameConfig.strings:string_common("guild_shop",6)})
                end
            else
                runGamePrompt({msg = string.format(gameConfig.strings:string_common("limitex",5),tmpData._vip)})
            end
        else
            runGamePrompt({msg = string.format(gameConfig.strings:string_common("limitex",4),tmpData._level)})
        end
    end, CCControlEventTouchUpInside)
    item.m_obutton:setTouchPriority(-103)

end

function limitex.play(self,data)
    local function tmpActionDone()
        UIRequest({type = 5052})
    end
    showRewardPopupWindow(data._reward,nil,tmpActionDone)
end



function limitex.clear(self)
    gameTouch:UnrigistFunc("begin","limitex")
    gameTouch:UnrigistFunc("end","limitex")

    if gameTimer.times["limitexRefreshTime"] then
        gameTimer:UnrigistTimeFunc("limitexRefreshTime")
    end

    self.show = false
    self.ListTableView = nil
    self.data = {}
    self.status = {}
    self.index = 1
    self.coverccb = nil
    self.coveritems = nil
end

return limitexd9  