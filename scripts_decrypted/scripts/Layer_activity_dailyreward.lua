--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/25
-- Time: 15:30
-- To change this template use File | Settings | File Templates.
--

local dailyreward = {
    isscrolltouched = false,
    buttontouch = -103,

    data = {},
    day = 1,
    status = {},
    ListTableView = nil,
    normalCellSize = {x=1080,y=282+14},
}


function dailyreward.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("activityreward_new/tiantianhaoli2",nil, true, "reward")

    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    self.coveritems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-160-640))

    local activityConfig = gamedata.config.activity_time
    local generalConfig = gamedata.config.generalanimation
    local name = generalConfig[tostring(activityConfig[tostring(14)].generalanimation)].name
    self.coveritems["generalNode"]:removeAllChildrenWithCleanup(true)
    -- local Gneral1 = CCSkeletonAnimation:create("hexiangu/hexiangu.json","hexiangu/hexiangu.atlas",1)
    local Gneral1 = CCSkeletonAnimation:create(name .."/" .. name .. ".json", name .."/" .. name .. ".atlas",1) 
    Gneral1:setAnimation("stand",true,0)
    Gneral1:setScale(2)
    Gneral1:setPosition(0,0)
    self.coveritems["generalNode"]:addChild(Gneral1)

    self.coveritems.rechargebutton:setTouchPriority(self.buttontouch)
    self.coveritems.rechargebutton:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameWindows:openWindow("recharge",{pagetype = "info"})
    end, CCControlEventTouchUpInside)

    ui.setStringWithStrokeAndShadow(self.coveritems.desc,nil,1)
    ui.setStringWithStrokeAndShadow(self.coveritems.desc1,nil,1)
    -- ui.setStringWithStrokeAndShadow(self.coveritems.desc2,nil,1)
    ui.setStringWithStrokeAndShadow(self.coveritems.desc3,nil,11)
    ui.setStringWithStrokeAndShadow(self.coveritems.desc4,nil,11)
    if self.coveritems.desc2_2 and self.coveritems.desc2_3 then
        ui.setStringWithStrokeAndShadow(self.coveritems.desc2_2,nil,1)
        ui.setStringWithStrokeAndShadow(self.coveritems.desc2_3,nil,1)
    end


    local function touchbegin(pos)
        self.isscrolltouched = false
        self.touchbegin = {x = pos.x, y = pos.y}
    end

    gameTouch:rigistFunc("begin","dailyreward",touchbegin)

    local function touchend(pos)
        if math.abs(pos.x - (self.touchbegin and self.touchbegin.x or pos.x)) > 20 or math.abs(pos.y - (self.touchbegin and self.touchbegin.y or pos.y)) > 20 then
            self.isscrolltouched = false
        elseif self.coveritems.listnode and ui.isTouched(self.coveritems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","dailyreward",touchend)
    --

    return self.coverccb
end

function dailyreward.reloaddata(self,data)
    if not self.show then return end
    --todo
    if not data then return end
    self.status = data.status or {}

    if data.rmb then
       self.coveritems.rmb:setString(gameConfig.strings:money(data.rmb))
    end

    -- ui.setStringWithStrokeAndShadow(self.coveritems.desc2,nil,1)
    ui.setStringWithStrokeAndShadow(self.coveritems.rmb,nil,1)

    --修改时间

    
    local nowtime = os.date("*t", gamedata:time())
    gameTimer:rigistTime("ActivityDailyreward",(23 - nowtime.hour) * 3600 + (59 - nowtime.min) * 60 +  (60 - nowtime.sec))

    if gameTimer.times["ActivityDailyreward"] and gameTimer.times["ActivityDailyreward"] > 0 then
        gameTimer:rigistTimeFunc("ActivityDailyreward", function()
            if gameTimer.times["ActivityDailyreward"] <= 0.5 then
                if gameTimer.times["ActivityDailyreward"] then
                    gameTimer:UnrigistTimeFunc("ActivityDailyreward")
                end
            else
                self.coveritems.time:setString(ui.makeTimeDayText(gameTimer.times["ActivityDailyreward"],"day"))
                ui.setStringWithStrokeAndShadow(self.coveritems.time,nil,1)
            end
        end)
    end

    -- if data.time then
    --     if math.ceil((data.time+0)/(3600*24)) >= 1 then
    --         self.coveritems.time:setString(gameConfig.strings:andDay(math.ceil((data.time+0)/(3600*24))))
    --     else
    --         self.coveritems.time:setString(gameConfig.strings:andDay(1))
    --     end
    -- end

    -- ui.setStringWithStrokeAndShadow(self.coveritems.desc1,nil,1)
    ui.setStringWithStrokeAndShadow(self.coveritems.time,nil,1)

    self.day = data.day or 1
    local showTable = {}

    local config = gamedata.dailyCpActivityConfig("daydaygift_item",14)
    for k,v in pairs(config) do
        if v.day and v.day == self.day then
           table.insert(showTable,v)
        end
    end
    table.sort(showTable, function(a,b) return a.id < b.id end)

    self.data = {}
    for k,v in ipairs(showTable) do
        if self.status[tostring(k)] == 1 then
            v.index = k
            table.insert(self.data,v)
        end
    end

    for k,v in ipairs(showTable) do
        if self.status[tostring(k)] == 0 then
            v.index = k
            table.insert(self.data,v)
        end
    end

    for k,v in ipairs(showTable) do
        if self.status[tostring(k)] == 2 then
            v.index = k
            table.insert(self.data,v)
        end
    end

    if self.coveritems then
        if not self.ListTableView then
            self:createList()
        else
            if self.ListTableView:getLuaContentOffsetY() < self.coveritems.listnode:getContentSize().height - table.getTableLength(self.data)*self.normalCellSize.y then
                self.ListTableView:setLuaContentOffset(0, self.coveritems.listnode:getContentSize().height - table.getTableLength(self.data)*self.normalCellSize.y)
            end
            self.ListTableView:reloadData()
        end
    end

end

function dailyreward.clear(self)
    gameTouch:UnrigistFunc("begin","dailyreward")
    gameTouch:UnrigistFunc("end","dailyreward")

    if gameTimer.times["ActivityDailyreward"] then
        gameTimer:UnrigistTimeFunc("ActivityDailyreward")
    end
    self.show = false
    self.ListTableView = nil
    self.data = {}
    self.status = {}
    self.day = 1
    self.coverccb = nil
    self.coveritems = nil
end

function dailyreward.createList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_reward1", nil, true, "cell_reward1")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCell(ccbDocumentControler,self.data[a1+1])

            cellCCB:setPosition(self.normalCellSize.x/2, 14)
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
        viewwidth = self.coveritems.listnode:getContentSize().width,
        viewheight = self.coveritems.listnode:getContentSize().height,
        dire = 1
    })
    self.coveritems.listnode:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(-101)
end


function dailyreward.setCell(self,item,data)
    print("setCell")

    item.doButton:setTouchPriority(-102)
    if self.status[tostring(data.index)] and self.status[tostring(data.index)] == 1 then
        item.nonenode:setVisible(false)
        item.doNode:setVisible(true)
        item.hasnode:setVisible(false)
        ui.removeGray("CCControlButton",item.doButton)
        ui.removeGray("CCLabelTTF",item.doLab)
        -- item.doLab:setString("领取")
        item.doLab:setString(gameConfig.strings:string_common("moreCommon",6))
        ui.setStringWithStrokeAndShadow(item.doLab,nil,1)
        item.doButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            if gameTouch.isScrollling then return end
            gameTouch:clickprofbytime(1)
            print("getbutton clicked")
            UIRequest({type = 2023, id = data.index or 1})
        end, CCControlEventTouchUpInside)
    elseif self.status[tostring(data.index)] and self.status[tostring(data.index)] == 2 then
        item.nonenode:setVisible(false)
        item.doNode:setVisible(false)
        item.hasnode:setVisible(true)
        ui.addGray("CCControlButton",item.doButton)
        ui.addGray("CCLabelTTF",item.doLab)
        item.doLab:setString(gameConfig.strings:string_common("moreCommon",5))
        ui.setStringWithStrokeAndShadow(item.doLab,nil,1)
        item.doButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            if gameTouch.isScrollling then return end
            runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",5)})
        end, CCControlEventTouchUpInside)
    else
        item.nonenode:setVisible(true)
        item.doNode:setVisible(false)
        item.hasnode:setVisible(false)
        ui.addGray("CCControlButton",item.doButton)
        ui.addGray("CCLabelTTF",item.doLab)
        item.doLab:setString(gameConfig.strings:string_common("moreCommon",6))
        ui.setStringWithStrokeAndShadow(item.doLab,nil,1)
        item.doButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            if gameTouch.isScrollling then return end
            runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",7)})
        end, CCControlEventTouchUpInside)
    end
    item.lavenum:setVisible(true)
    if self.status[tostring(data.index)] and self.status[tostring(data.index)] == 2 then
        -- item.lavenum:setString("剩余次数：0/1")
        item.lavenum:setString(gameConfig.strings:string_common("activityLg",2))
    else
        -- item.lavenum:setString("剩余次数：1/1")
        item.lavenum:setString(gameConfig.strings:string_common("activityLg",3))
    end

    item.title:setString(gameConfig.strings:DayRechage(data.rmb))
    local props = ui.getIDandNUMs(data.reward) or {}

    for i=1, 4 do
        if props[i] and props[i].cid then
            item["reward"..i]:setVisible(true)
            local config = ui.IDconfig(props[i].cid)
            if config then
                ui.setNewIcon(item,{cid = props[i].cid, num = props[i].num,},i-1)
                --
                item["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
                    if not self.isscrolltouched then return end
                    if GameScene.layers["activity"].module.isContentScroll then  return end
                    ui.setPopwindowByCid(props[i].cid)
                end, CCControlEventTouchUpInside)
                item["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(-103)
                --
            end
        else
            item["reward"..i]:setVisible(false)
        end
    end

    item.typenode:setVisible(false)
    item.reward4:setVisible(false)
end



return dailyreward   �0  