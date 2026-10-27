--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/25
-- Time: 15:30
-- To change this template use File | Settings | File Templates.
--

local vipWeekGift = {
    isscrolltouched = false,
    ListTableView = nil,
    normalCellSize = {x=1080,y=242},
    showweekgiftData = {},
    weekgiftData = {}
}


function vipWeekGift.init(self,size)
    self.contentsize = size
    self.show = true
    local now = os.date("*t", gamedata:time())
    local _str = now.year.."_"..now.month.."_"..now.day
    CCUserDefault:sharedUserDefault():setStringForKey("vipGift_localInfoString"..GameScene.roleinfo.id, _str) 

    self.coverccb, self.coveritems = CCBReaderLoad("activityreward_new/activity_vipweekgift",nil, true, "vipWeekGift")

    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    self.coveritems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-640-180))

    gameTouch:rigistFunc("end","vipWeekGift",touchend)
    self:setRefreshTime()

    self.coveritems["swallow_btn"]:setSwallowsTouch(true)
    self.coveritems["swallow_btn"]:setTouchPriority(-200)
    self.coveritems["swallow_btn"]:addHandleOfControlEvent(function()
    end, CCControlEventTouchUpInside)
    
    return self.coverccb
end

function vipWeekGift.setRefreshTime(self)
    local nowtime = os.date("*t", gamedata:time())
    printT(nowtime,"nowtime")
    local wday = ((nowtime.wday-1) < 1) and 7 or (nowtime.wday-1)

    local timediff = (8 - wday)*86400 - nowtime.hour * 3600 - nowtime.min * 60 - nowtime.sec
    if timediff > 0 then
        gameTimer:rigistTime("vipWeekGiftRefreshTime",timediff)
        gameTimer:rigistTimeFunc("vipWeekGiftRefreshTime", function()
            if gameTimer.times["vipWeekGiftRefreshTime"] <= 0 then
                gameTimer:UnrigistTimeFunc("vipWeekGiftRefreshTime")
                self:setRefreshTime()
            else
                ui.setLabelString(self.coveritems.time,ui.makeTimeDayText(gameTimer.times["vipWeekGiftRefreshTime"],"day"),22,34)   
            end
        end)
    else
        self:setRefreshTime()       
    end
end

function vipWeekGift.reloaddata(self,data)

    if not self.show then return end
    self.showweekgiftData = {}
    for k,v in pairs(gamedata.config.vip_weekgift or {}) do
        table.insert(self.showweekgiftData,table.copy(v))
    end

    local sortfunc = function (a,b)
        if a["vip"] >= b["vip"] then
            return false
        elseif a["vip"] < b["vip"] then
            return true
        end
    end
    table.sort(self.showweekgiftData,sortfunc)
        
    for i,v in ipairs(self.showweekgiftData) do
        v.buytime = data.weekgift[tostring(i)] or 0
        v.status = ((v.num - v.buytime) > 0 and 1 or 0)
    end

    gamedata.sortData(self.showweekgiftData,"status","vip",nil,nil,nil,nil,false,true)


    if self.coveritems then
        if not self.ListTableView then
            self:createList()
        else
            self.ListTableView:reloadData()
        end
    end
end

function vipWeekGift.createList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("shop/cell_shop", nil, true, "cell_shop")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setWeekGift(ccbDocumentControler,self.showweekgiftData[a1+1],a1+1)

            cellCCB:setPosition(self.normalCellSize.x/2, 14)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.showweekgiftData)
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

function vipWeekGift.setWeekGift(self,item,data,index)
    print("setWeekGift")

    if item.buytypedesc then
        item.buytypedesc:setString("本周还可购买            次")
    end

    local giftdata = data or {}
    local configdata =  gamedata.config.props[tostring(giftdata.id)]

    ui.setIconLv(item,{cid = giftdata.id})
    ui.setLabelString(item.name,configdata.name, configdata.quality~=0 and 2*configdata.quality-1 or 1)
    item.price:setString(giftdata.gold)

    local reward = ui.getIDandNUMs(configdata.param2)
    local desc = "内含有："
    for i,v in ipairs(reward) do
        local config = ui.IDconfig(v.cid)
        desc = desc..config.name..v.num.."个"
        if i == #reward then
            desc = desc.."。"
        else
            desc = desc.."，"
        end
    end
    item.desc:setString(desc)

    item.il_button:setTouchPriority(-102)
    item.il_button:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        if configdata.param2 then
            
            gameWindows:openWindow("getStaff",{data = reward,type = configdata.name},nil)
        end
    end, CCControlEventTouchUpInside)

    item.buytimenode:setVisible(true)
    if item.time then
        item.time:setVisible(false)
    end
    if item.spritecoin and item.spritegold then
        item.spritecoin:setVisible(false)
        item.spritegold:setVisible(true)
    end

    item.buyButton:setTouchPriority(-102)
    ui.setLabelString(item.buytext,gameConfig.strings:string_common("shop_list",3),18)

    if (data.status == 1) then
        ui.setLabelString(item.buytime, giftdata.num - data.buytime, 13)
        --
        if giftdata.vip > GameScene.vip.vip then
            ui.addGray("CCControlButton",item["buyButton"])
            ui.addGray("CCLabelTTF",item["buytext"])
            --
            item.buyButton:addHandleOfControlEvent(function()
                if gameTouch.isScrollling then return end
                print("buyButton clicked")
                gameTouch:clickprofbytime(1)
                runGamePrompt({msg = "贵族"..giftdata.vip.."以上可购买"})
                gamedata.music:PlayOptSound("ccgm")
            end, CCControlEventTouchUpInside)
        else
            ui.removeGray("CCControlButton",item["buyButton"])
            ui.removeGray("CCLabelTTF",item["buytext"])
            --
            item.buyButton:addHandleOfControlEvent(function()
                if gameTouch.isScrollling then return end
                print("buyButton clicked")
                gameTouch:clickprofbytime(1)
                UIRequest({type = 4891, vip = giftdata.vip, xgold = giftdata.gold})
                gamedata.music:PlayOptSound("ccgm")
            end, CCControlEventTouchUpInside)
        end
    else
        ui.setLabelString(item.buytime, "0", 13)
        --
        ui.addGray("CCControlButton",item["buyButton"])
        ui.addGray("CCLabelTTF",item["buytext"])
        --
        item.buyButton:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            print("buyButton clicked")
            gameTouch:clickprofbytime(1)
            runGamePrompt({msg = "本周购买次数已用完"})
            gamedata.music:PlayOptSound("ccgm")
        end, CCControlEventTouchUpInside)

    end
end


function vipWeekGift.clear(self)
    gameTimer:UnrigistTimeFunc("vipWeekGiftRefreshTime")

    self.show = false
    self.ListTableView = nil
    self.weekgiftData = {}
    self.status = {}
    self.index = 1
    self.coverccb = nil
    self.coveritems = nil
    self.showweekgiftData = {}
end

return vipWeekGift