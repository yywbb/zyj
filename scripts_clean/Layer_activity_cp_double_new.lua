--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/6/8
-- Time: 11:32
-- To change this template use File | Settings | File Templates.
--


local double = {
    isscrolltouched = false,
    buttontouch = -103,

    data = {},
    status = {},
    index = 1,
    ListTableView = nil,
    normalCellSize = {x=1080,y=228+14},

    multiple = 2,

}


function double.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("activityreward_new/shuangbeifanhuan2",nil, true, "reward")

    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    self.coveritems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-160-600))

    local activityConfig = gamedata.config.activity_time
    local generalConfig = gamedata.config.generalanimation
    local name = generalConfig[tostring(activityConfig[tostring(87)].generalanimation)].name
    self.coveritems["generalNode"]:removeAllChildrenWithCleanup(true)
    local Gneral1 = CCSkeletonAnimation:create(name .."/" .. name .. ".json", name .."/" .. name .. ".atlas",1) -- yudi
    Gneral1:setAnimation("stand",true,0)
    Gneral1:setScale(2)
    Gneral1:setPosition(0,0)
    self.coveritems["generalNode"]:addChild(Gneral1)

    self.coveritems["rechargebutton"]:setTouchPriority(self.buttontouch)
    self.coveritems["rechargebutton"]:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        --GameScene:shiftLayer("recharge","up")
        gameWindows:openWindow("recharge",{pagetype = "info"})
    end, CCControlEventTouchUpInside)

    if self.coveritems.rechargetimes then
        if gamedata.config.global_kv.recharge_times and (tonumber(gamedata.config.global_kv.recharge_times.value) > 900) then
            self.coveritems.rechargetimes:setString("不限次数")
        elseif gamedata.config.global_kv.recharge_times then
            self.coveritems.rechargetimes:setString("仅限"..((tonumber(gamedata.config.global_kv.recharge_times.value) < 11) and (gameConfig.strings.bigNum[tonumber(gamedata.config.global_kv.recharge_times.value)]) or gamedata.config.global_kv.recharge_times.value).."次")
        else
            self.coveritems.rechargetimes:setString("仅限一次")
        end
    end
    --todo 活动时间
    -- if self.coveritems.time and gamedata.config.activity_time["6"]["end"] then
    --     local year1,month1,day1 = ui.getDate(gamedata.config.activity_time["6"]["end"])
    --     self.coveritems.time:setString(gameConfig.strings:YearMonthDay(year1,month1,day1))
    -- elseif self.coveritems.time then
    --     self.coveritems.time:setString("")
    -- end


    -- todo
    if gamedata.config.activity_time["87"] and gamedata.config.activity_time["87"].param and tonumber(gamedata.config.activity_time["87"].param) > 0 then
        self.multiple = tonumber(gamedata.config.activity_time["87"].param)
    end

    if self.coveritems.activity_title then
        self.coveritems.activity_title:setString("充值元宝，"..gameConfig.strings.bigNum[self.multiple-1].."倍返还")
        self.coveritems.desc1:setString("活动期间，以下额度均能获得"..gameConfig.strings.bigNum[self.multiple].."倍 \n元宝。每个额度")
    end


    ui.setStringWithStrokeAndShadow(self.coveritems.time,nil,1)

    ui.setStringWithStrokeAndShadow(self.coveritems.desc1,nil,1)
    ui.setStringWithStrokeAndShadow(self.coveritems.desc2,nil,1)
    ui.setStringWithStrokeAndShadow(self.coveritems.desc,nil,30)
    --ui.setStringWithStrokeAndShadow(self.coveritems.time,nil,1)
    if self.coveritems.desc3 then
        ui.setStringWithStrokeAndShadow(self.coveritems.desc3,nil,1)
    end

    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","double_cp",touchbegin)

    local function touchend(pos)
        if self.coveritems.listnode and ui.isTouched(self.coveritems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","double_cp",touchend)
    --

    return self.coverccb
end

function double.reloaddata(self,data)
    if not self.show then return end
    --todo

    local cpnum = data and data.cpnum or 0
    local cpday = data and data.cpday or 0
    -- 活动时间
    local timediff = 0
    if self.coveritems.time and gamedata.config.activity_time["87"]["open_type"] and gamedata.config.activity_time["87"]["open_type"] == 5 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", nowtime)
        timediff = 86400*(gamedata.config.activity_time["87"]["continued_time"..((cpnum == 1) and ("_1") or "")]-cpday+1) - temp.hour*3600 - temp.min*60 - temp.sec
    elseif self.coveritems.time and gamedata.config.activity_time["87"]["open_type"] and gamedata.config.activity_time["87"]["open_type"] == 2 then
        self.coveritems.time:setString("")
        self.coveritems.desc:setString("")
    elseif self.coveritems.time and gamedata.config.activity_time["87"]["open_type"] and gamedata.config.activity_time["87"]["open_type"] == 1 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", GameScene.roleinfo.servertime)
        timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["87"]["continued_time"]+(gamedata.config.activity_time["87"]["days_later"] or 0))- nowtime - temp.hour*3600 - temp.min*60 - temp.sec
        if timediff < 0 then
            timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["87"]["continued_time"]+(gamedata.config.activity_time["87"]["days_later2"] or 0))- nowtime - temp.hour*3600 - temp.min*60 - temp.sec
        end
    elseif self.coveritems.time and gamedata.config.activity_time["87"]["end"] and gamedata.config.activity_time["87"]["end"] ~= "" then
        local year1,month1,day1,hour1,minute1,second1 = ui.getDate(gamedata.config.activity_time["87"]["end"])
        local time1 = os.time({year=year1, month=month1, day=day1, hour=hour1, min = minute1, sec =  second1})
        local nowtime = gamedata:time()
        timediff = time1-nowtime;
    elseif self.coveritems.time then
        self.coveritems.time:setString("")
        self.coveritems.desc:setString("")
    end

    if self.coveritems.time and timediff and timediff > 0 then
        gameTimer:rigistTime("Activitydoublenew_cp",timediff)

        if gameTimer.times["Activitydoublenew_cp"] and gameTimer.times["Activitydoublenew_cp"] > 0 then
            gameTimer:rigistTimeFunc("Activitydoublenew_cp", function()
                if gameTimer.times["Activitydoublenew_cp"] <= 0 then
                    if gameTimer.times["Activitydoublenew_cp"] then
                        gameTimer:UnrigistTimeFunc("Activitydoublenew_cp")
                    end
                else
                    self.coveritems.time:setString(ui.makeTimeDayText(gameTimer.times["Activitydoublenew_cp"],"day"))
                    ui.setStringWithStrokeAndShadow(self.coveritems.time,nil,1)
                end
            end)
        end
    end
    --

    self.status = data and data.rechargedouble or {}

    self.data = {}
    local recharge = gamedata.config.recharge or {}
    for k,v in pairs(recharge) do
        if v.isdouble and v.isdouble > 1 then
            table.insert(self.data,v)
        end
    end

    local sortfunc = function (a,b)
        return a["rmb"] < b["rmb"]
    end
    table.sort(self.data,sortfunc)

    if self.coveritems then
        if not self.ListTableView then
            self:createList()
        else
            self.ListTableView:reloadData()
        end
    end

end

function double.clear(self)
    gameTouch:UnrigistFunc("begin","double_cp")
    gameTouch:UnrigistFunc("end","double_cp")

    if gameTimer.times["Activitydoublenew_cp"] then
        gameTimer:UnrigistTimeFunc("Activitydoublenew_cp")
    end
    self.show = false
    self.ListTableView = nil
    self.data = {}
    self.status = {}
    self.index = 1
    self.coverccb = nil
    self.coveritems = nil
end

function double.createList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_reward8", nil, true, "cell_reward8")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCell(ccbDocumentControler,self.data[(a1+1)],a1+1)

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


function double.setCell(self,item,data,index)
    print("setCell")

    item.name:setString(gameConfig.strings:money(data.rmb))
    -- item.desc:setString(gameConfig.strings:moneyGold(data.rmb,(data.gold*2)))
    item.desc:setString(data.gold .. " (充值获得) + "..data.gold .. "x"..(self.multiple-1).." (额外返还) =   "..(data.gold*self.multiple).." 元宝")
    ui.setNewIcon(item,{cid = 1001, num = data.gold*self.multiple})

    if item["b_sprite"] then
        if self.multiple == 4 then
            setSpriteFrameByName(item["b_sprite"],"obj_fourfold")
        elseif self.multiple == 3 then
            setSpriteFrameByName(item["b_sprite"],"obj_triple")
        elseif self.multiple == 2 then
            setSpriteFrameByName(item["b_sprite"],"obj_double")
        else
            setSpriteFrameByName(item["b_sprite"],"alpha")
        end
    end

    -- ui.setLabelString(item["rechargeLab"],nil,18)
    item["rechargeButton"]:setTouchPriority(self.buttontouch)
    item["rechargeButton"]:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if GameScene.layers["activity"].module.isContentScroll then  return end
        --GameScene:shiftLayer("recharge","up")
        gameWindows:openWindow("recharge",{pagetype = "info"})
    end, CCControlEventTouchUpInside)

    if self.status[tostring(2*index-1)] and self.status[tostring(2*index-1)] == 1 then
        item.rechargeNode:setVisible(false)
        item.hasnode:setVisible(true)
        if item.times then
            item.times:setVisible(false)
        end
    else
        item.rechargeNode:setVisible(true)
        item.hasnode:setVisible(false)
        if item.times then
            local times = 999
            if gamedata.config.global_kv.recharge_times then
                times = tonumber(gamedata.config.global_kv.recharge_times.value) - self.status[tostring(2*index)]
            end
            item.times:setVisible(true)
            item.times:setString((times < 900) and ("剩余 "..times.." 次") or "")
        end
    end

end



return double