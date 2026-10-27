--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/25
-- Time: 15:30
-- To change this template use File | Settings | File Templates.
--

local cardgift = {
    isscrolltouched = false,
    buttontouch = -103,

    data = {},
    status = {},
    index = 1,
    ListTableView = nil,
    normalCellSize = {x=1080,y=228+14},
}


function cardgift.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("activityreward_new/yuekasongli2",nil, true, "reward")

    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    self.coveritems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-640-160-180))

    local activityConfig = gamedata.config.activity_time
    local generalConfig = gamedata.config.generalanimation
    local name = generalConfig[tostring(activityConfig[tostring(8)].generalanimation)].name
    self.coveritems["generalNode"]:removeAllChildrenWithCleanup(true)
    -- local Gneral1 = CCSkeletonAnimation:create("guanyu/guanyu.json","guanyu/guanyu.atlas",1)
    local Gneral1 = CCSkeletonAnimation:create(name .."/" .. name .. ".json", name .."/" .. name .. ".atlas",1)
    Gneral1:setAnimation("stand",true,0)
    Gneral1:setScale(2)
    Gneral1:setPosition(0,0)
    self.coveritems["generalNode"]:addChild(Gneral1)

    self.coveritems["rechargeButton"]:setTouchPriority(self.buttontouch)
    self.coveritems["rechargeButton"]:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        --GameScene:shiftLayer("recharge","up")
        gameWindows:openWindow("recharge",{pagetype = "info"})
    end, CCControlEventTouchUpInside)


    --todo 活动时间
    -- if self.coveritems.time and gamedata.config.activity_time["8"]["end"] then
    --     local year1,month1,day1 = ui.getDate(gamedata.config.activity_time["8"]["end"])
    --     self.coveritems.time:setString(gameConfig.strings:YearMonthDay(year1,month1,day1))
    -- elseif self.coveritems.time then
    --     self.coveritems.time:setString("")
    -- end

    -- 活动时间
    local timediff = 0
    if self.coveritems.time and gamedata.config.activity_time["8"]["open_type"] and gamedata.config.activity_time["8"]["open_type"] == 2 then
        self.coveritems.time:setString("")
        self.coveritems.desc1:setString("")
    elseif self.coveritems.time and gamedata.config.activity_time["8"]["open_type"] and gamedata.config.activity_time["8"]["open_type"] == 1 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", GameScene.roleinfo.servertime)
        timediff = GameScene.roleinfo.servertime + 86400*gamedata.config.activity_time["8"]["continued_time"] - nowtime - temp.hour*3600 - temp.min*60 - temp.sec

    elseif self.coveritems.time and gamedata.config.activity_time["8"]["end"] and gamedata.config.activity_time["8"]["end"] ~= "" then
        local year1,month1,day1,hour1,minute1,second1 = ui.getDate(gamedata.config.activity_time["8"]["end"])
        local time1 = os.time({year=year1, month=month1, day=day1, hour=hour1, min = minute1, sec =  second1})
        local nowtime = gamedata:time()
        timediff = time1-nowtime;
    elseif self.coveritems.time then
        self.coveritems.time:setString("")
        self.coveritems.desc1:setString("")
    end

    if self.coveritems.time and timediff and timediff > 0 then
        gameTimer:rigistTime("ActivityNewcardgift",timediff)
        if gameTimer.times["ActivityNewcardgift"] and gameTimer.times["ActivityNewcardgift"] > 0 then
            gameTimer:rigistTimeFunc("ActivityNewcardgift", function()
                if gameTimer.times["ActivityNewcardgift"] <= 0 then
                    if gameTimer.times["ActivityNewcardgift"] then
                        gameTimer:UnrigistTimeFunc("ActivityNewcardgift")
                    end
                else
                    self.coveritems.time:setString(ui.makeTimeDayText(gameTimer.times["ActivityNewcardgift"],"day"))
                    ui.setStringWithStrokeAndShadow(self.coveritems.time,nil,1)
                end
            end)
        end
    end

    ui.setStringWithStrokeAndShadow(self.coveritems.desc1,nil,1)
    ui.setStringWithStrokeAndShadow(self.coveritems.time,nil,1)
    -- ui.setStringWithStrokeAndShadow(self.coveritems.rechargeLab,nil,1)

    --
    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","cardgift",touchbegin)

    local function touchend(pos)
        if self.coveritems.listnode and ui.isTouched(self.coveritems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","cardgift",touchend)
    --


    return self.coverccb
end

function cardgift.reloaddata(self,data)

    if not self.show then return end
    --todo
    self.status = data or {}
    printT(data,"data------------")
    self.coveritems.rechangermb:setString((data[tostring(5)] or 0) .. "元")
    self.data = gamedata.config.monthcardgift or {}
    if self.coveritems then
        if not self.ListTableView then
            self:createList()
        else
            self.ListTableView:reloadData()
        end
    end

end

function cardgift.clear(self)

    gameTouch:UnrigistFunc("begin","cardgift")
    gameTouch:UnrigistFunc("end","cardgift")

    if gameTimer.times["ActivityNewcardgift"] then
        gameTimer:UnrigistTimeFunc("ActivityNewcardgift")
    end
    self.show = false
    self.ListTableView = nil
    self.data = {}
    self.status = {}
    self.index = 1
    self.coverccb = nil
    self.coveritems = nil
end

function cardgift.createList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_reward2", nil, true, "cell_reward2")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCell(ccbDocumentControler,self.data[tostring(a1+1)])

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


function cardgift.setCell(self,item,data)
    print("setCell")
    if data.rmb == 0 then
        -- item.des1:setString("月卡用户立即获得")
        item.des1:setString(gameConfig.strings:string_common("activityLg",1))
    else
        item.des1:setString(gameConfig.strings:addRechage(data.rmb))
    end
    local cid, num = ui.getIDandNUM(data.reward)
    item.des2:setString(gameConfig.strings:rewardName(ui.IDconfig(cid).name))
    ui.setNewIcon(item,{cid = cid, num = num})

    item.getbutton:setTouchPriority(-102)

    --
    item["i_button"]:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if GameScene.layers["activity"].module.isContentScroll then  return end
        ui.setPopwindowByCid(cid)
    end, CCControlEventTouchUpInside)
    item["i_button"]:setTouchPriority(-103)
    --

    if self.status[tostring(data.id)] == 0 then
        item.nonenode:setVisible(true)
        item.hasnode:setVisible(false)
        item.getNode:setVisible(false)
        item.gettext:setString(gameConfig.strings:string_common("buttontext","lingqu"))
        ui.setStringWithStrokeAndShadow(item.gettext,nil,1)
        item.getbutton:addHandleOfControlEvent(function()

        end, CCControlEventTouchUpInside)
        ui.addGray("CCControlButton",item.getbutton)
        ui.addGray("CCLabelTTF",item.gettext)
    elseif self.status[tostring(data.id)] == 1 then
        item.nonenode:setVisible(false)
        item.hasnode:setVisible(false)
        item.getNode:setVisible(true)
        item.gettext:setString(gameConfig.strings:string_common("buttontext","lingqu"))
        ui.setStringWithStrokeAndShadow(item.gettext,nil,1)
        item.getbutton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            if gameTouch.isScrollling then return end
            UIRequest({type = 2093, cid = data.id})
        end, CCControlEventTouchUpInside)
        ui.removeGray("CCControlButton",item.getbutton)
        ui.removeGray("CCLabelTTF",item.gettext)
    elseif self.status[tostring(data.id)] == 2 then
        item.nonenode:setVisible(false)
        item.getNode:setVisible(false)
        item.hasnode:setVisible(true)
        item.gettext:setString(gameConfig.strings:string_common("buttontext","yilingqu"))
        ui.setStringWithStrokeAndShadow(item.gettext,nil,1)
        item.getbutton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            if gameTouch.isScrollling then return end
            runGamePrompt({msg = gameConfig.strings:string_common("buttontext","yilingqu")})
        end, CCControlEventTouchUpInside)
        ui.addGray("CCControlButton",item.getbutton)
        ui.addGray("CCLabelTTF",item.gettext)
    end




end



return cardgift  �(  