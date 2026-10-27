--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/25
-- Time: 15:30
-- To change this template use File | Settings | File Templates.
--

local chaozhifankui = {
    isscrolltouched = false,
    buttontouch = -103,

    ListTableView = nil,
    normalCellSize = {x=1080,y=230},
}


function chaozhifankui.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("2zhounian/guoqinghuikui",nil, true, "guoqinghuikui")

    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    self.coveritems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-310-640))

    self.coveritems.rechargebutton:setTouchPriority(self.buttontouch)
    self.coveritems.rechargebutton:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameWindows:openWindow("recharge",{pagetype = "info"})
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.coveritems.desc,gameConfig.strings:string_common("activity_zhounian",1),48)
    ui.setLabelString(self.coveritems.desc2,gameConfig.strings:string_common("activity_zhounian",14),14)
    self.coveritems.desc1:setString(gameConfig.strings:string_common("activity_zhounian",15))

    self.pkgconfig=gamedata.config.value_feedback_package

    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","chaozhifankui",touchbegin)

    local function touchend(pos)
        if self.coveritems.listnode and ui.isTouched(self.coveritems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","chaozhifankui",touchend)
    --

    return self.coverccb
end

function chaozhifankui.reloaddata(self,t)
    if not self.show then return end

    -- 活动时间
    local cpnum = data and data.cpnum or 0
    local cpday = data and data.cpday or 0
    local timediff = 0
    if self.coveritems.time and gamedata.config.activity_time["100"]["open_type"] and gamedata.config.activity_time["100"]["open_type"] == 5 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", nowtime)
        timediff = 86400*(gamedata.config.activity_time["100"]["continued_time"..((cpnum == 1) and ("_1") or "")]-cpday+1) - temp.hour*3600 - temp.min*60 - temp.sec
    elseif self.coveritems.time and gamedata.config.activity_time["100"]["open_type"] and gamedata.config.activity_time["100"]["open_type"] == 2 then
        self.coveritems.time:setString("")
        self.coveritems.desc1:setString("")
    elseif self.coveritems.time and gamedata.config.activity_time["100"]["open_type"] and gamedata.config.activity_time["100"]["open_type"] == 1 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", GameScene.roleinfo.servertime)
        timediff = GameScene.roleinfo.servertime + 86400*gamedata.config.activity_time["100"]["continued_time"] - nowtime - temp.hour*3600 - temp.min*60 - temp.sec

    elseif self.coveritems.time and gamedata.config.activity_time["100"]["end"] and gamedata.config.activity_time["100"]["end"] ~= "" then
        local year1,month1,day1,hour1,minute1,second1 = ui.getDate(gamedata.config.activity_time["100"]["end"])
        local time1 = os.time({year=year1, month=month1, day=day1, hour=hour1, min = minute1, sec =  second1})
        local nowtime = gamedata:time()
        timediff = time1-nowtime;
    elseif self.coveritems.time then
        self.coveritems.time:setString("")
        self.coveritems.desc1:setString("")
    end


    if self.coveritems.time and timediff and timediff > 0 then
        gameTimer:rigistTime("Activitychaozhi",timediff)

        if gameTimer.times["Activitychaozhi"] and gameTimer.times["Activitychaozhi"] > 0 then
            gameTimer:rigistTimeFunc("Activitychaozhi", function()
                if gameTimer.times["Activitychaozhi"] <= 0 then
                    if gameTimer.times["Activitychaozhi"] then
                        gameTimer:UnrigistTimeFunc("Activitychaozhi")
                    end
                else
                    self.coveritems.time:setString(ui.makeTimeDayText(gameTimer.times["Activitychaozhi"],"day"))
                    ui.setStringWithStrokeAndShadow(self.coveritems.time,nil,1)
                end
            end)
        end
    end

    ui.setStringWithStrokeAndShadow(self.coveritems.time,nil,1)
    ui.setStringWithStrokeAndShadow(self.coveritems.desc1,nil,1)


    ui.setLabelString(self.coveritems.propnum,t.pronum,14)


    local rewardconfig = gamedata.config.value_feedback

    for i=1,3 do
        local oneconfig = rewardconfig[tostring(i)]
        local status = t.data.status[tostring(i)]
        setSpriteFrameByName(self.coveritems["box"..i], "leijigoumailibao"..i..(status<=1 and "" or "_h"))

        self.coveritems["boxeffect"..i]:removeAllChildrenWithCleanup(true)
        if status == 1 then
            local ccb, item = CCBReaderLoad("UIEffect/guang/guang2.ccbi", nil, true, "guang2")
            self.coveritems["boxeffect"..i]:addChild(ccb)
        end
        
        local text = t.data.total.."/"..oneconfig.number
        ui.setLabelString(self.coveritems["boxdesc"..i],text,t.data.total>=oneconfig.number and 23 or 14)
        
        self.coveritems["s_button"..i]:setSwallowsTouch(true)
        self.coveritems["s_button"..i]:setTouchPriority(-102)
        self.coveritems["s_button"..i]:addHandleOfControlEvent(function()
            local tempdata = ui.getIDandNUMs(oneconfig.reward1)
            if status == 1 then
                UIRequest({type = 5317,id = i})
            elseif status == 0 then
                gameWindows:openWindow("getStaff",{data = tempdata,type = gameConfig.strings:string_common("task",6)},nil)
            else
                gameWindows:openWindow("getStaff",{data = tempdata,type = gameConfig.strings:string_common("moreCommon",5)},nil)
            end
        end, CCControlEventTouchUpInside)    
    end

    self.times = t.data.times
    self.pronum = t.pronum

    self:makelistdata()

    if self.coveritems then
        if not self.ListTableView then
            self:createList()
        else                                                                                                   
            self.ListTableView:reloadData()
        end
    end

end

function chaozhifankui.makelistdata( self )
    local listdata = {}
    for k,v in pairs(self.pkgconfig) do
        v.times = self.times[tostring(v.id)]
        table.insert(listdata,v)
    end

    local sortfunc = function( a,b )

        if a.limit - a.times <= 0 and b.limit - b.times > 0 then
            return false
        elseif a.limit - a.times > 0 and b.limit - b.times <= 0 then
            return true
        else
            return a.order < b.order
        end
    end

    table.sort(listdata,sortfunc)
    self.listdata = listdata
end

function chaozhifankui.clear(self)
    gameTouch:UnrigistFunc("begin","chaozhifankui")
    gameTouch:UnrigistFunc("end","chaozhifankui")

    if gameTimer.times["Activitychaozhi"] then
        gameTimer:UnrigistTimeFunc("Activitychaozhi")
    end
    self.show = false
    self.ListTableView = nil
    self.coverccb = nil
    self.coveritems = nil
end

function chaozhifankui.createList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("2zhounian/cell_2zhounianactivity", nil, true, "cell_2zhounianactivity")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCell(ccbDocumentControler, self.listdata[tostring(a1+1)] or self.listdata[a1+1])

            cellCCB:setPosition(self.normalCellSize.x/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            -- r = table.getTableLength(self.data)
            r = table.getTableLength(self.listdata)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

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


function chaozhifankui.setCell(self,item,data,index)
    print("setCell")

    local rewardid,rewardnum = ui.getIDandNUM(data.item)
    ui.setNewIcon(item,{cid = rewardid,num = rewardnum})

    local itemconfig = ui.IDconfig(rewardid)

    ui.setLabelString(item.name,itemconfig.name,itemconfig.quality~=0 and 2*itemconfig.quality-1 or 1)
    item.desc:setString(itemconfig.desc)

    item.buytypedesc:setString(gameConfig.strings:string_common("activity_zhounian",2))
    ui.setLabelString(item.buytime,data.limit-data.times,14)

    local _,costgold = ui.getIDandNUM(data.cost)
    local rate = tonumber(gamedata.config.global_kv.Anniversary_vouchers.value)
    local costprop = math.ceil(costgold/rate)

    local needprop = math.min(self.pronum,costprop)
    ui.setLabelString(item.priceprop,needprop>0 and needprop or "",13)
    item.spriteprop:setVisible(needprop>0)

    local needgold = (costprop-needprop)*rate
    ui.setLabelString(item.pricegold,needgold>0 and needgold or "",GameScene.roleinfo.gold>=needgold and 13 or 24)

    ui.setLabelString(item.buytext,gameConfig.strings:string_common("buttontext","goumai"),18)
    item.buyButton:setSwallowsTouch(true)
    item.buyButton:setTouchPriority(-102)
    item.buyButton:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if data.limit<=data.times then
            runGamePrompt({msg = gameConfig.strings:string_common("activity_zhounian",10)})
        elseif GameScene.roleinfo.gold<needgold then
            shortGold()
        else
            if needgold > 500 then
                local function bagCB()
                    UIRequest({type=5316,id=data.id})     
                end
                cost = {{cid = 1001, num = needgold}}
                gameWindows:openWindow("shopExchange",{cid = rewardid, num = rewardnum, cost = cost, exchangeNum = 1, ccbtype = 2}, bagCB)
            else
                UIRequest({type=5316,id=data.id})
            end
        end
    end, CCControlEventTouchUpInside) 

    if data.limit<=data.times then
        ui.addGray("CCControlButton",item.buyButton)
    else
        ui.removeGray("CCControlButton",item.buyButton)
    end
end


return chaozhifankui