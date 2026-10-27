--
-- Created by IntelliJ IDEA.
-- User: lichungeng
-- Date: 16/6/17
-- Time: 下午3:54
-- To change this template use File | Settings | File Templates.
--

local tigerchickenshop = {
    rewardCellSize = {x=1080, y=320},

    resource = nil,

    rootNode = nil,
    rootItems = nil,
    rewardListTableView = nil,

    rewards = {},
    rewardData = {},
    myData = {},

    isscrolltouched = false,
}

function tigerchickenshop.init(self,size)
    self.contentsize = size
    self.show = true

    self.rootNode,self.rootItems = CCBReaderLoad("activitytigerchicken/tigerchicken_duihuan", nil, true, "shop")

    self.rootItems.topnode:setPositionY(self.contentsize.y-180)
    self.rootItems.rewardScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-gameConfig.maiscenebottomheight-520))


    self.rewards = gamedata.dailyCpActivityConfig("new_generals_exchange",45)
    -- self.rewards = gamedata.config.new_generals_exchange or {}
    --
    local endString = ""
    if gamedata.config.activity_time["45"]["open_type"] and gamedata.config.activity_time["45"]["open_type"] == 1 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", GameScene.roleinfo.servertime)
        local timediff = 0
        timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["45"]["continued_time"]+(gamedata.config.activity_time["45"]["days_later"] or 0)) - temp.hour*3600 - temp.min*60 - temp.sec
        if timediff < nowtime then
            timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["45"]["continued_time"]+(gamedata.config.activity_time["45"]["days_later2"] or 0)) - temp.hour*3600 - temp.min*60 - temp.sec
        end
        local endtab = os.date("*t", timediff-1)
        endString = endtab.year.."年"..endtab.month.."月"..endtab.day.."日24时"

    elseif gamedata.config.activity_time["45"]["end"] and gamedata.config.activity_time["45"]["end"] ~= "" then
        local year, month, day, hour, min, sec = ui.getDate(gamedata.config.activity_time["45"]["end"])
        endString = year.."年"..month.."月"..day.."日"
        if tonumber(hour) < 1 and tonumber(min) < 1 and tonumber(sec) < 1 then
            local endt = os.time({year=tonumber(year),month=tonumber(month),day=tonumber(day),hour=tonumber(hour),min=tonumber(min),sec=tonumber(sec),isdst=false}) - 1
            local endtab = os.date("*t",endt)
            endString = endtab.year.."年"..endtab.month.."月"..endtab.day.."日24时"
        end
    end
    ui.setLabelString(self.rootItems.timedes,"结束时间: "..endString,14)
    --
    local function touchbegin(pos)
        self.isscrolltouched = false
        self.touchbegin = {x = pos.x, y = pos.y}
    end

    gameTouch:rigistFunc("begin","tigerchickenshop",touchbegin)

    local function touchend(pos)
        if math.abs(pos.x - (self.touchbegin and self.touchbegin.x or pos.x)) > 20 or math.abs(pos.y - (self.touchbegin and self.touchbegin.y or pos.y)) > 20 then
            self.isscrolltouched = false
        elseif self.rootItems.rewardScroll and ui.isTouched(self.rootItems.rewardScroll,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","tigerchickenshop",touchend)
    --
    UIRequest({type = 1406})
    return self.rootNode
end

function tigerchickenshop.relaodpoint(self,data)
    if not self.show then return end
    self.myData = {point = data.points}
    ui.setLabelString(self.rootItems.pointnum,self.myData.point or 0,21)
    if  self.rewardListTableView then
        self.rewardListTableView:reloadData()
    end
end


function tigerchickenshop.reloaddata(self,data)
    print("tigerchickenshop.reloadrank==")
    if not self.show then return end

    if data then
        self.rewardData = data.data or {}
    else
        --return
    end


    if not self.rewardListTableView then
        self:createRewardList()
    else
        if self.rewardListTableView:getLuaContentOffsetY() < self.rootItems.rewardScroll:getContentSize().height - table.getTableLength(self.rewards)*self.rewardCellSize.y then
            self.rewardListTableView:setLuaContentOffset(0, self.rootItems.rewardScroll:getContentSize().height - table.getTableLength(self.rewards)*self.rewardCellSize.y)
        end
        self.rewardListTableView:reloadData()
    end

end


function tigerchickenshop.createRewardList(self)
    local celldict = {}
    local rankListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.rewardCellSize.x, self.rewardCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("activitytigerchicken/cell_tigerchicken_shop.ccbi", nil, true, "tigerchicken_duihuan")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                --ui.tableviewAnimation(self.rewardListTableView,cellCCB,self.rewardCellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setone(self.rewards[tostring((a1+1)*2-1)],ccbDocumentControler,1)
            self:setone(self.rewards[tostring((a1+1)*2)],ccbDocumentControler,2)

            --if self.rewardListTableView then
                cellCCB:setPosition(self.rewardCellSize.x/2, 0)
            --end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.rewards)/2
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.rewardListTableView = ui.createLuaTableView({
        handle = rankListHandle,
        viewwidth = self.rootItems.rewardScroll:getContentSize().width,
        viewheight = self.rootItems.rewardScroll:getContentSize().height,
        dire = 1
    })
    self.rewardListTableView:setTouchPriority(-102)
    self.rootItems.rewardScroll:addChild(self.rewardListTableView)
end


function tigerchickenshop.setone(self,data,items,index)
    print("index==",index)
    -- printT(data)

    local key_Ex
    local icon_key
    local exchangeNum = 99999999
    if index == nil or index == 1 then
        key_Ex = ""
        icon_key = ""
    else
        key_Ex = "_1"
        icon_key = "_1"
    end


    if not data then
        return
    end

    if (data.limit and data.limit > 0) then
        items["changenum"..key_Ex]:setString("可兑换次数"..(data.limit-(self.rewardData[tostring(data.id)] or 0)))
    else
        items["changenum"..key_Ex]:setString("")
    end
    ui.setLabelString(items["changenum"..key_Ex],nil,13)

    if data.item and data.item ~= "" then
        local id1,num1 = ui.getIDandNUM(data.item)
        ui.setNewIconName(items,{cid = id1, num = num1},index-1)
        --
        items["in_button"..key_Ex]:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            ui.setPopwindowByCid(id1)
        end, CCControlEventTouchUpInside)
        items["in_button"..key_Ex]:setTouchPriority(-102)
        --
    end

    if data.number and data.number ~= "" then
        items["pointnode"..key_Ex]:setVisible(true)
        local id1,num1 = ui.getIDandNUM(data.number)
        ui.setLabelString(items["pointnum"..key_Ex],num1,14)
        exchangeNum = exchangeNum > math.floor((self.myData.point or 0)/num1) and math.floor((self.myData.point or 0)/num1) or exchangeNum
    else
        items["pointnode"..key_Ex]:setVisible(false)
    end

    if data.num and data.num ~= "" then
        items["propnode"..key_Ex]:setVisible(true)
        local id1,num1 = ui.getIDandNUM(data.num)
        ui.setLabelString(items["propnum"..key_Ex],num1,14)
        ui.setNewIcon(items,{cid = id1},index-1)
        --
        items["i_button_"..(2*(index-1)+1)]:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            ui.setPopwindowByCid(id1)
        end, CCControlEventTouchUpInside)
        items["i_button_"..(2*(index-1)+1)]:setTouchPriority(-102)
        --
    else
        items["propnode"..key_Ex]:setVisible(false)
    end

    --
    ui.setLabelString(items["buttontext"..key_Ex],nil,18)


    items["button"..key_Ex]:setTouchPriority(-102)
    items["button"..key_Ex]:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameTouch:clickprofbytime(1)
        --
        if (data.limit and data.limit > 0) and ((data.limit-(self.rewardData[tostring(data.id)] or 0)) < exchangeNum) then
            exchangeNum = data.limit-(self.rewardData[tostring(data.id)] or 0)
        end
        if (data.limit and data.limit > 0) and ((data.limit-(self.rewardData[tostring(data.id)] or 0)) <= 0) then
            runGamePrompt({msg = "兑换次数不足"})
        else
            local cb = function( num )
                UIRequest({type = 1409, pos = data.id,num = num})
            end
            ui.exchangeMore(cb,exchangeNum)
        end

    end, CCControlEventTouchUpInside)


    if (data.limit and data.limit > 0) and ((data.limit-(self.rewardData[tostring(data.id)] or 0)) <= 0) then
        ui.addGray("CCControlButton",items["button"..key_Ex])
    else
        ui.removeGray("CCControlButton",items["button"..key_Ex])
    end

end



function tigerchickenshop.clear(self)
    self.show = false

    gameTouch:UnrigistFunc("begin","tigerchickenshop")
    gameTouch:UnrigistFunc("end","tigerchickenshop")

    self.rewards = {}
    self.rewardData = {}
    self.myData = {}

    self.rewardListTableView = nil

    if self.rootNode then
        self.rootNode:removeAllChildrenWithCleanup(true)
        self.rootNode:removeFromParentAndCleanup(true)
        self.rootNode = nil
        self.rootItems = nil
    end

end


return tigerchickenshop