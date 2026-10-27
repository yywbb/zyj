

local midautumnshop_x1 = {
    isscrolltouched = false,
    ListTableView = nil,
    normalCellSize = {x=1080,y=228},

    point = 0,
}


function midautumnshop_x1.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("activityzhongqiu/5zhounianduihuan",nil, true, "5zhounianduihuan")

    --

    local showpropid = 192152
    if self.coveritems.showpropicon then
        if gamedata.config.activity_time["208"] and gamedata.config.activity_time["208"].param and gamedata.config.activity_time["208"].param > 0 then
            showpropid = gamedata.config.activity_time["208"].param
        end
        if ui.IDconfig(showpropid) and ui.IDconfig(showpropid).icon then
            setSpriteFrameByName(self.coveritems.showpropicon,ui.IDconfig(showpropid).icon)
        end
    end
    --

    --排行榜
    if self.coveritems.ranklistbutton then
        if tonumber(showpropid) == 192660 then
            self.coveritems.ranklistbutton:setVisible(true)
            self.coveritems.ranklistbutton:addHandleOfControlEvent(function()
                gameWindows:openWindow("dayuanxiaorank", {point = self.point} )
            end, CCControlEventTouchUpInside)
            self.coveritems.ranklistbutton:setTouchPriority(-103)
        else
            self.coveritems.ranklistbutton:setVisible(false)
        end
    end
    --奖励预览
    if self.coveritems.rewardboxbutton then
        if tonumber(showpropid) == 192660 then
            self.coveritems.rewardboxbutton:setVisible(true)
            self.coveritems.rewardboxbutton:addHandleOfControlEvent(function()
                gameWindows:openWindow("dayuanxiao_rankreward")
            end, CCControlEventTouchUpInside)
            self.coveritems.rewardboxbutton:setTouchPriority(-103)
        else
            self.coveritems.rewardboxbutton:setVisible(false)
        end
    end

    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    self.coveritems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-700-280+100)) --周年兑换


    local updatatimestring = gameConfig.strings:string_common("fixedString","activity_cumulativerecharge",4)
    self.coveritems.m_oTimeNum:setString(updatatimestring)

    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","midautumnshop_x1touch",touchbegin)

    local function touchend(pos)
        if self.coveritems.listnode and ui.isTouched(self.coveritems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","midautumnshop_x1touch",touchend)

    self:updatatime()

    if gamedata.config.copy_time and gamedata.config.copy_time["1"] and gamedata.config.copy_time["1"]["close"] then
        local year, month, day, hour, min, sec = ui.getDate(gamedata.config.copy_time["1"]["close"])
        local endString = month.."月"..day.."日"..hour.."时"
        if tonumber(hour) < 1 and tonumber(min) < 1 and tonumber(sec) < 1 then
            local endt = os.time({year=tonumber(year),month=tonumber(month),day=tonumber(day),hour=tonumber(hour),min=tonumber(min),sec=tonumber(sec),isdst=false}) - 1
            local endtab = os.date("*t",endt)
            endString = endtab.month.."月"..endtab.day.."日24时"
            self.coveritems.m_oTimeNum2:setString("活动道具掉落截止时间:"..endString)
        end
    end

    return self.coverccb
end

function midautumnshop_x1.updatatime(self)

    local status,remintime = ui.checkDateActive(gamedata.config.activity_time["208"]["begin"],gamedata.config.activity_time["208"]["end"])

    if self.coveritems.m_oTimeNum and remintime and remintime > 0 then
        gameTimer:rigistTime("midautumnshop_x1",remintime)

        if gameTimer.times["midautumnshop_x1"] and gameTimer.times["midautumnshop_x1"] > 0 then
            gameTimer:rigistTimeFunc("midautumnshop_x1", function()
                if gameTimer.times["midautumnshop_x1"] <= 0 then
                    if gameTimer.times["midautumnshop_x1"] then
                        print("finish")
                        gameTimer:UnrigistTimeFunc("midautumnshop_x1")
                    end
                elseif self.coveritems.m_oTimeNum then
                    local updatatimestring = gameConfig.strings:string_common("fixedString","activity_cumulativerecharge",4) .. ui.makeTimeDayText(gameTimer.times["midautumnshop_x1"],"day")
                    self.coveritems.m_oTimeNum:setString(updatatimestring)
                end
            end)
        end
    end
end

function midautumnshop_x1.reloaddata(self,data,scoredata)
    if scoredata and scoredata.num then
        self.point = scoredata.num
        local scorestring = "x"..scoredata.num
        self.coveritems.scoreLabel:setString(scorestring)
    end
    self.data = data
    if not self.show then return end
    if self.coveritems then
        if not self.ListTableView then
            self:createList()
        else
            self.ListTableView:reloadData()
        end
    end
end

function midautumnshop_x1.createList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityzhongqiu/cell_activityzhongqiu", nil, true, "cell_activityzhongqiu")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCell(ccbDocumentControler,a1+1)

            cellCCB:setScale(0.9)
            cellCCB:setPosition(self.normalCellSize.x/2, 0)
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

function midautumnshop_x1.setCell(self,item,destIndex)
    local tmpData = self.data[tostring(destIndex)]
    local tmpCanDothat = true
    local canExchangeNum = 99999999
    item.m_oExchangeNum:setString(string.format(gameConfig.strings:string_common("limitex",1),tmpData._once))

    ui.setLabelString(item.m_obtttf,gameConfig.strings:string_common("limitex",3),18)
    item.m_obutton:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if GameScene.layers["activity"].module.isContentScroll then  return end

        if tmpData._status == 1 then
            runGamePrompt({msg = gameConfig.strings:string_common("activity_fashion",2)})
        elseif tmpData._levelLimit and tmpData._levelLimit > GameScene.roleinfo.level then
            runGamePrompt({msg = string.format("达到%d级才能兑换哦！", tmpData._levelLimit)})
        else
            if tmpData._exchange[tostring(1)] >= 80001 and tmpData._exchange[tostring(1)] <= 81000 then
                if tmpData._status ~= 0 then
                    runGamePrompt({msg = gameConfig.strings:string_common("activity_fashion",2)})
                elseif not tmpCanDothat then
                    runGamePrompt({msg = gameConfig.strings:string_common("exchange",1)})
                else
                    local  cb = function( num )
                        UIRequest({type = 4603,_id = tmpData._id,_num = num})
                    end
                    ui.exchangeMore(cb,canExchangeNum,tmpData._once,tmpData._max)     
                end
            else
                if tmpData._once > 0 then
                    if tmpCanDothat then
                        local  cb = function( num )
                            UIRequest({type = 4603,_id = tmpData._id,_num = num})
                        end
                        ui.exchangeMore(cb,canExchangeNum,tmpData._once,tmpData._max)                    
                    else
                        if tmpData._item["1"] and tmpData._item["1"].cid == 1001 then
                            shortGold()
                        else
                            runGamePrompt({msg = gameConfig.strings:string_common("exchange",1)})
                        end
                    end
                elseif tmpData._once <= 0 then
                    runGamePrompt({msg = gameConfig.strings:string_common("guild_shop",6)})
                end
            end
        end
        
    end, CCControlEventTouchUpInside)
    item.m_obutton:setTouchPriority(-103)


    if tmpData._status == 1 then
        ui.addGray("CCControlButton",item.m_obutton)
        ui.addGray("CCLabelTTF",item.m_obtttf)
    elseif tmpData._levelLimit and tmpData._levelLimit > GameScene.roleinfo.level then
        ui.addGray("CCControlButton",item.m_obutton)
        ui.addGray("CCLabelTTF",item.m_obtttf)
    else
        if tmpData._exchange[tostring(1)] >= 80001 and tmpData._exchange[tostring(1)] <= 81000 then
            if tmpData._status ~= 0 or tmpData._once <= 0 then
                ui.addGray("CCControlButton",item.m_obutton)
                ui.addGray("CCLabelTTF",item.m_obtttf)
            else
                ui.removeGray("CCControlButton",item.m_obutton)
                ui.removeGray("CCLabelTTF",item.m_obtttf)
            end
        else
            if tmpData._once <= 0 then
                ui.addGray("CCControlButton",item.m_obutton)
                ui.addGray("CCLabelTTF",item.m_obtttf)
            else
                ui.removeGray("CCControlButton",item.m_obutton)
                ui.removeGray("CCLabelTTF",item.m_obtttf)
            end
        end
    end

    item["m_oDeng"]:setVisible(false)
    item["m_oGet3"]:setVisible(false)
    local tmpAddIndexs = 1
    for i=1,4 do
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
                local tmpStrNum = tmpData._item[tmpCheackIndex].num
                ui.setNewIcon(item,{cid = tmpData._item[tmpCheackIndex].cid, num = tmpStrNum,},i-1)
                local newCanNum = math.floor(tmpData._nums[tmpCheackIndex].num/tmpData._item[tmpCheackIndex].num)
                if newCanNum <= canExchangeNum then
                    canExchangeNum = newCanNum
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

    if tmpAddIndexs < 5 then
        item["m_oNeed"..tmpAddIndexs]:setVisible(true)
        setSpriteFrameByName(item["m_oJia"..tmpAddIndexs],"spr_136.png")
        item["m_oJia"..tmpAddIndexs]:setVisible(true)
    else
        item["m_oDeng"]:setVisible(true)
        item["m_oGet3"]:setVisible(true)
    end
    ui.setNewIcon(item,{cid = tmpData._exchange["1"], num = tmpData._exchange["2"],},tmpAddIndexs - 1)

    item["i_button_"..(tmpAddIndexs-1)]:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if GameScene.layers["activity"].module.isContentScroll then  return end
        ui.setPopwindowByCid(tmpData._exchange["1"])
    end, CCControlEventTouchUpInside)
    item["i_button_"..(tmpAddIndexs-1)]:setTouchPriority(-103)

end



function midautumnshop_x1.clear(self)
    gameTouch:UnrigistFunc("begin","midautumnshop_x1touch")
    gameTouch:UnrigistFunc("end","midautumnshop_x1touch")

    gameTimer:UnrigistTimeFunc("midautumnshop_x1")

    self.show = false
    self.ListTableView = nil
    self.data = {}

    if self.coverccb then
        self.coverccb:removeAllChildrenWithCleanup(true)
        self.coverccb:removeFromParentAndCleanup(true)
        self.coverccb = nil
        self.coveritems = nil
    end
end

return midautumnshop_x17  