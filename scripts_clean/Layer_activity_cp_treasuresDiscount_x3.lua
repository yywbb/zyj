--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 16/2/27
-- Time: 上午午10:57
-- To change this template use File | Settings | File Templates.
--
--地榜
local treasuresDiscount_x3 = {
    buttontouch = -103,

    ListTableView = nil,
    normalCellSize = {x=1080, y=245},
    -- taskTab = {},
    data = {},
    treasuresStatus = {},
    index = nil,
    goldNum = nil,
    isscrolltouched = false,

    activityid = "159",
    configname = "rank_shop_3",
    requestid = 4023,
    activityindex = 3,

}

function treasuresDiscount_x3.init(self, size)
    self.contentsize = size
    self.show = true
    self.coverccb, self.coveritems = CCBReaderLoad("activityreward_new/kuafubangduihuan",nil, true, "kuafubangduihuan")
    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    self.coveritems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-640-200+35))-- -160-180

    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","cp_treasuresDiscount_x3",touchbegin)

    local function touchend(pos)
        if self.coveritems.listnode and ui.isTouched(self.coveritems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","cp_treasuresDiscount_x3",touchend)


    self.coveritems["shopbg_"..self.activityindex]:setVisible(true)
    self.coveritems["shopcontent_"..self.activityindex]:setVisible(true)


    local activityConfig = gamedata.config:getConfigByName("activity_time") or {}
    local generalConfig = gamedata.config:getConfigByName("generalanimation") or {}
    -- if activityConfig[tostring(24)].generalanimation ~= 0 then
    -- local name = generalConfig[tostring(activityConfig[self.activityid].generalanimation)].name
    -- self.coveritems["generalNode"]:removeAllChildrenWithCleanup(true)
    -- local Gneral1 = CCSkeletonAnimation:create(name .."/" .. name .. ".json", name .."/" .. name .. ".atlas",1) -- yudi
    -- Gneral1:setAnimation("stand",true,0)
    -- Gneral1:setScale(2)
    -- Gneral1:setPosition(0,0)
    -- self.coveritems["generalNode"]:addChild(Gneral1)
    -- end

    --
    -- if self.coveritems.title and activityConfig[self.activityid] then
    --     self.coveritems.title:setString(activityConfig[self.activityid].name or "")
    -- end
    --



    self:onInit()
    -- self:reloadData()
    return self.coverccb
end

function treasuresDiscount_x3.onInit(self)
    -- if self.coveritems.aboutBtn then
    --     self.coveritems.aboutBtn:setVisible(false)
    --     self.coveritems.aboutBtn:setTouchPriority(self.buttontouch)
    --     self.coveritems.aboutBtn:setSwallowsTouch(true)
    --     self.coveritems.aboutBtn:addHandleOfControlEvent(function()
    --     -- 说明
    --         if GameScene.layers["activity"].module.isContentScroll then  return end
    --         gameWindows:openWindow("multipleRebateHelp", {explain = nil, title = "物品兑换限制"}, nil)
    --     end, CCControlEventTouchUpInside)
    -- end

    -- ui.setLabelString(self.coveritems.describe, nil, 14)

end

function treasuresDiscount_x3.reloaddata(self, data)
    if not self.show then return end

   
    self.endTime = ""
   -- 活动时间
    local timediff = 0
    if self.coveritems.time and gamedata.config:getConfigByName("activity_time")[self.activityid]["open_type"] and gamedata.config:getConfigByName("activity_time")[self.activityid]["open_type"] == 2 then
        self.coveritems.timeNode:setVisible(false)
    elseif self.coveritems.time and gamedata.config:getConfigByName("activity_time")[self.activityid]["open_type"] and gamedata.config:getConfigByName("activity_time")[self.activityid]["open_type"] == 1 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", GameScene.roleinfo.servertime)
        timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config:getConfigByName("activity_time")[self.activityid]["continued_time"]+(gamedata.config:getConfigByName("activity_time")[self.activityid]["days_later"] or 0)) - nowtime - temp.hour*3600 - temp.min*60 - temp.sec
        if timediff < 0 then
            timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config:getConfigByName("activity_time")[self.activityid]["continued_time"]+(gamedata.config:getConfigByName("activity_time")[self.activityid]["days_later2"] or 0))- nowtime - temp.hour*3600 - temp.min*60 - temp.sec
        end

    elseif self.coveritems.time and gamedata.config:getConfigByName("activity_time")[self.activityid]["end"] and gamedata.config:getConfigByName("activity_time")[self.activityid]["end"] ~= "" then
        local year1,month1,day1,hour1,minute1,second1 = ui.getDate(gamedata.config:getConfigByName("activity_time")[self.activityid]["end"])
        local time1 = os.time({year=year1, month=month1, day=day1, hour=hour1, min = minute1, sec =  second1})
        local nowtime = gamedata:time()
        timediff = time1-nowtime
    end

     self.timerName = "cp_treasuresDiscount_x_"..self.activityid

     if self.coveritems.time and timediff and timediff > 0 then
        gameTimer:rigistTime(self.timerName,timediff)

        if gameTimer.times[self.timerName] and gameTimer.times[self.timerName] > 0 then
            gameTimer:rigistTimeFunc(self.timerName, function()
                if gameTimer.times[self.timerName] <= 0 then
                    if gameTimer.times[self.timerName] then
                        gameTimer:UnrigistTimeFunc(self.timerName)
                    end
                else
                    self.coveritems.time:setString(ui.makeTimeDayText(gameTimer.times[self.timerName],"day"))
                    ui.setStringWithStrokeAndShadow(self.coveritems.time,nil,1)
                end
            end)
        end
    end

    
    ui.setStringWithStrokeAndShadow(self.coveritems.time,nil,1)
    -- self.coveritems.time:setString(self.endTime)
    self.treasuresStatus = data.activityTreasure
    if self.coveritems then
        if not self.ListTableView then
            self:createList()
        else
            self.ListTableView:reloadData() -- 刷新列表
            print("is ListTableView")
        end
    end

end

function treasuresDiscount_x3.createList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_zhenpinzhekou2", nil, true, "cell_zhenpinzhekou")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            local data = gamedata.config:getConfigByName(self.configname) or {}
            self:setCell(ccbDocumentControler, data[tostring(a1+1)], a1+1)
            cellCCB:setPosition(self.normalCellSize.x/2, 14)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            -- print("self.treasuresStatus ====="..table.getTableLength(self.treasuresStatus))
            r = table.getTableLength(self.treasuresStatus)
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

function treasuresDiscount_x3.setCell(self, item, cellData, index)

    local data = cellData
    local props = ui.getIDandNUMs(data.generals) or {}
    local consumnum = #props

    local treasuresStatus = self.treasuresStatus[tostring(index)]
    local goldCellTab = ui.getIDandNUMs(data.target) or {}
    local item_num = #goldCellTab
    for k,v in pairs(goldCellTab) do
        table.insert(props, v)
    end

    local remaining_num = (data.count - treasuresStatus.num) or 0
    local notprops = false
    local canExchangeMax = 99999999

    self.goldNum = props[1] and props[1].num or 0
    item.surplusNum:setString(((data.count - treasuresStatus.num) < 0 and 0 or (data.count - treasuresStatus.num)) .. "/" .. data.count) -- 剩余次数

    setSpriteFrameByName(item.discountLv, (data.discount .. "zhe") or "alpha")
    ui.setLabelString(item.exchangeLab, nil, 18)

    for i=1, 5 do
        if item["reward"..i] then
            if props[i] and props[i].cid then
                item["reward"..i]:setVisible(true)
                local config = ui.IDconfig(props[i].cid)
                if config then
                    if i<= consumnum then
                        local hasnum = treasuresStatus[tostring(props[i].cid)] or 0
                        if props[i].cid == 1000 or props[i].cid == 1001 then
                            ui.setNewIcon(item,{cid = props[i].cid, num = props[i].num,},i-1)
                        else
                            ui.setNewIcon(item,{cid = props[i].cid, num = hasnum.."/"..props[i].num,},i-1)
                        end

                        if canExchangeMax > math.floor(hasnum/props[i].num) then
                            canExchangeMax = math.floor(hasnum/props[i].num)
                        end

                        if hasnum< props[i].num then
                            notprops = true
                            ui.setLabelString(item["i_num"..(i-1==0 and "" or "_"..(i-1))], nil, 24)
                        end
                    else
                        ui.setNewIcon(item,{cid = props[i].cid, num = props[i].num,},i-1)
                    end
                    --
                    item["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
                        if not self.isscrolltouched then return end
                        if gameTouch.isScrollling then return end
                        ui.setPopwindowByCid(props[i].cid)
                    end, CCControlEventTouchUpInside)
                    item["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(-103)
                    --
                end
                if i<= consumnum then
                    item["reward"..i]:setPositionX(100+(i-1)*120)
                else
                    item["reward"..i]:setPositionX(150+(i-1)*120)
                end
                item.esprite:setPositionX(186+(consumnum-1)*120)
            else
                item["reward"..i]:setVisible(false)
                --
                item["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
                    if not self.isscrolltouched then return end
                    if gameTouch.isScrollling then return end
                    --
                end, CCControlEventTouchUpInside)
                item["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(-103)
                --
            end
        end
    end

    item.exchangeBtn:setTouchPriority(self.buttontouch)
    item.exchangeBtn:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        local bagCB = function(num)
            gameTouch:clickprofbytime(1)
            UIRequest({type = self.requestid, treasures = index, goldNum = props[1].num, num = num})            
        end
        if treasuresStatus.status == 1 then
            if notprops then -- 判断兑换条件是否满足
                bagCB(1)
            else
                if remaining_num > 5 then -- 多次弹窗
                    if props[1].cid == 1001 and consumnum == 1 and item_num == 1 then -- 元宝单对单
                        local cost = {{cid = props[1].cid, num = props[1].num}}
                        gameWindows:openWindow("shopExchange",{cid = goldCellTab[1].cid, num = goldCellTab[1].num, cost = cost, exchangeNum = (canExchangeMax < remaining_num) and canExchangeMax or remaining_num}, bagCB)
                    else
                        ui.exchangeMore(bagCB, canExchangeMax, data.count - treasuresStatus.num, data.count)
                    end
                else -- 单次弹窗
                    if props[1].cid == 1001 and props[1].num > 500 then
                        if consumnum == 1 and item_num == 1 then
                            local cost = {{cid = props[1].cid, num = props[1].num}}
                            gameWindows:openWindow("shopExchange",{cid = goldCellTab[1].cid, num = goldCellTab[1].num, cost = cost, exchangeNum = remaining_num, ccbtype = 2}, bagCB)
                        else
                            gameWindows:openWindow("confirm",{msg = "是否确认兑换/购买"}, bagCB)
                        end
                    else
                        bagCB(1)
                    end
                end
            end
        else
            bagCB(1)
        end
    end, CCControlEventTouchUpInside)

    if treasuresStatus.status == 1 then
		-- 正常
        ui.removeGray("CCControlButton",item.exchangeBtn)
        ui.removeGray("CCLabelTTF",item.exchangeLab)		
	else
		-- 置灰
        ui.addGray("CCControlButton",item.exchangeBtn)
        ui.addGray("CCLabelTTF",item.exchangeLab)
    end
end

function treasuresDiscount_x3.clear(self)
    if self.coverccb then
        self.ListTableView = nil
        self.coverccb:removeAllChildrenWithCleanup(true)
        self.coverccb:removeFromParentAndCleanup(true)
        self.coverccb = nil
        self.coveritems = nil
        self.data = {}
        self.treasuresStatus = {}
        gameTouch:UnrigistFunc("begin","cp_treasuresDiscount_x3")
        gameTouch:UnrigistFunc("end","cp_treasuresDiscount_x3")
         if self.timerName and gameTimer.times[self.timerName] then
            gameTimer:UnrigistTimeFunc(self.timerName)
        end
    end
    self.show = false
end


return treasuresDiscount_x3
