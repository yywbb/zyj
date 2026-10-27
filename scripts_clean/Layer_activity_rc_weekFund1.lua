--
-- Author: songyibo
-- Date: 2020-07-01 16:45:07
--

local weekfund = {
    buttontouch = -103,
    data = {},
    ListTableView = nil,
    normalCellSize = {x=1080,y=230},
    activityid = 171,
    awardRequest = 8080,
    giftid = 9,
}


function weekfund.init(self,size)
    self.contentsize = size
    self.show = true

    self.rootNode, self.rootItems = CCBReaderLoad("activityreward_new/zhoujijin",nil, true, "zhoujijin")
    self.rootItems.topnode:setPositionY(self.contentsize.y-180)
    self.rootItems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-160-510))

    return self.rootNode
end

function weekfund.makeData(self,data)
	self.cpnum = GameScene.layers["activity"].module.dailyCpActivityTimeStatus[self.activityid].cpnum or 1
    self.cpday = GameScene.layers["activity"].module.dailyCpActivityTimeStatus[self.activityid].cpday or 1

    print("self.cpnum",self.activityid,self.cpnum,self.cpday)
    self.rewardConfig = gamedata.config["week_growup_rc_"..self.cpnum]
    self.moneyConfig = gamedata.config["week_growup_money_rc_1"]
    self.rechargeGear = self.moneyConfig[tostring(self.cpnum)].gear
    self.rechargeStatus = data.rechargeStatus
    self.data = {}

    for i=1,table.getTableLength(data.status) do
        self.data[i] = table.copy(self.rewardConfig[tostring(i)])
        self.data[i]._status = data.status[tostring(i)]
    end

    local sortfunc = function (a,b)
        if a._status == b._status then
            return a.day < b.day
        elseif a._status == 1 and b._status ~= 1 then
            return true
        elseif a._status ~= 1 and b._status == 1 then
            return false
        else
            return a._status < b._status
        end
    end

    table.sort(self.data,sortfunc)
end

function weekfund.reloaddata(self,data)
    if not self.show then return end
    if not data then return end
    if not GameScene.layers["activity"].module.dailyCpActivityTimeStatus[self.activityid] then
        return
    end
    self:makeData(data)

    -- 活动时间
    local timediff = 0
    if gamedata.config.activity_time[tostring(self.activityid)]["open_type"] == 1 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", GameScene.roleinfo.servertime)
        timediff = GameScene.roleinfo.servertime + 86400*gamedata.config.activity_time[tostring(self.activityid)]["continued_time"] - nowtime - temp.hour*3600 - temp.min*60 - temp.sec
    elseif gamedata.config.activity_time[tostring(self.activityid)]["open_type"] == 3 then
        local year1,month1,day1,hour1,minute1,second1 = ui.getDate(gamedata.config.activity_time[tostring(self.activityid)]["end"])
        local time1 = os.time({year=year1, month=month1, day=day1, hour=hour1, min = minute1, sec =  second1})
        local nowtime = gamedata:time()
        timediff = time1-nowtime
    elseif gamedata.config.activity_time[tostring(self.activityid)]["open_type"] == 5 then
        timediff = GameScene.layers["activity"].module:getDailyCpActivityTime(self.activityid)
    elseif gamedata.config.activity_time[tostring(self.activityid)]["open_type"] == 7 then
        timediff = GameScene.layers["activity"].module:getDailyCpActivityTime(self.activityid)
    end

    if self.rootItems.time and timediff and timediff > 0 then
        gameTimer:rigistTime("weekfund"..self.activityid,timediff)
        self.rootItems.time:setString(ui.makeTimeDayText(gameTimer.times["weekfund"..self.activityid],"day"))
        if gameTimer.times["weekfund"..self.activityid] and gameTimer.times["weekfund"..self.activityid] > 0 then
            gameTimer:rigistTimeFunc("weekfund"..self.activityid, function()
                if gameTimer.times["weekfund"..self.activityid] <= 0 then
                    if gameTimer.times["weekfund"..self.activityid] then
                        gameTimer:UnrigistTimeFunc("weekfund"..self.activityid)
                    end
                else
                    self.rootItems.time:setString(ui.makeTimeDayText(gameTimer.times["weekfund"..self.activityid],"day"))
                end
            end)
        end
    end

    self.rootItems.buyNode:setVisible(self.rechargeStatus == 0)
    self.rootItems.yijihuo:setVisible(self.rechargeStatus == 1)
    self.rootItems.buyLab:setString(gamedata.config.recharge[tostring(self.rechargeGear)].rmb.."元")
    ui.setLabelString(self.rootItems.buyLab,nil,18,55)
    self.rootItems.bei1:setString(gamedata.config.recharge[tostring(self.rechargeGear)].rmb.."y")
    self.rootItems.bei2:setString((self.moneyConfig[tostring(self.cpnum)].ratio or 60).."b!")

    self.rootItems.timeLab:setString(self.rechargeStatus == 0 and gameConfig.strings:string_common("weekfund",1) or gameConfig.strings:string_common("weekfund",2))
    self.rootItems.time:setPositionX(self.rootItems.timeLab:getPositionX() + self.rootItems.timeLab:getContentSize().width + 5)

    ui.setLabelString(self.rootItems.tip,nil,1027,24)
    ui.setLabelString(self.rootItems.timeLab,nil,1027,34)

    self.rootItems.buybutton:setTouchPriority(-102)
    self.rootItems.buybutton:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end

        if RechargeLimit(gamedata.config.recharge[tostring(self.rechargeGear)].rmb) then
            return
        end
            
        if self.rechargeStatus == 0 then
            if sdk:isValid() then
                UIRequest({type = 115,cid = tonumber(self.rechargeGear),bagid=self.giftid})
            else
                runGamePrompt({msg = gameConfig.strings:string_common("popups","change_qudao")})
            end
        end
    end, CCControlEventTouchUpInside)


    if not self.ListTableView then
        self:createList()
    else
        self.ListTableView:reloadData()
    end
end

function weekfund.createList(self)
    print("createList")

    local celldict = {}
    local unrecycleCell = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_reward9", nil, true, "cell_reward9")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCell(ccbDocumentControler, self.data[a1+1], a1+1)

            cellCCB:setPosition(self.normalCellSize.x/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.data)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listnode:getContentSize().width,
        viewheight = self.rootItems.listnode:getContentSize().height,
        dire = 1
    })
    self.rootItems.listnode:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(-101)
end


function weekfund.setCell(self,item,data,index)

    item.title:setString("第"..data.day.."天")
    ui.setLabelString(item.doLab,gameConfig.strings:string_common("buttontext","lingqu"),19)
    item.doButton:setTouchPriority(-102)

    item.hasnode:setVisible(data._status == 2)
    item.doNode:setVisible(data._status ~= 2)

    item.doButton:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        if gameTouch.isScrollling then return end
        gameTouch:clickprofbytime(1)
        if data._status == 1 then
            UIRequest({type = self.awardRequest, id = data.day})
        elseif data._status == 0 and self.rechargeStatus == 0 then
            runGamePrompt({msg = gameConfig.strings:string_common("weekfund",3)})
        elseif data._status == 0 and self.rechargeStatus == 1 then
            runGamePrompt({msg = string.format(gameConfig.strings:string_common("weekfund",4), data.day)})
        end
    end, CCControlEventTouchUpInside)

    if data._status == 0 then
        ui.addGray("CCControlButton",item.doButton)
        ui.addGray("CCLabelTTF",item.doLab)
    else
        ui.removeGray("CCControlButton",item.doButton)
        ui.removeGray("CCLabelTTF",item.doLab)
    end
    
    local props = ui.getIDandNUMs(data.reward) or {}
    for i=1, 5 do
        if props[i] and props[i].cid then
            item["reward"..i]:setVisible(true)
            local config = ui.IDconfig(props[i].cid)
            if config then
                ui.setNewIcon(item,{cid = props[i].cid, num = props[i].num,},i-1)
                item["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
                    if GameScene.layers["activity"].module.isContentScroll then  return end
                    ui.setPopwindowByCid(props[i].cid)
                end, CCControlEventTouchUpInside)
                item["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(-103)
            end
        else
            item["reward"..i]:setVisible(false)
            item["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
                print("i_button")
            end, CCControlEventTouchUpInside)
            item["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(-103)
            --
        end
    end

end

function weekfund.clear(self)
    if gameTimer.times["weekfund"..self.activityid] then
        gameTimer:UnrigistTimeFunc("weekfund"..self.activityid)
    end
    self.show = false
    self.ListTableView = nil
    self.data = {}
    self.rootNode = nil
    self.rootItems = nil
end

return weekfund