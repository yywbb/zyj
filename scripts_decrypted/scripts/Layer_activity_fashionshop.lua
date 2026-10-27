--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/25
-- Time: 15:30
-- To change this template use File | Settings | File Templates.
--

local fashionshop = {
    isscrolltouched = false,
    ListTableView = nil,
    normalCellSize = {x=1080,y=228+14},
    -- m_iFreshTimes = nil,
}

LX_BASEGOLD = 50



function fashionshop.init(self,size)
    self.contentsize = size
    self.show = true

    if gamedata.config.build[tostring(274)] and gamedata.config.build[tostring(274)].switch and gamedata.config.build[tostring(274)].switch == 1 then
        self.coverccb, self.coveritems = CCBReaderLoad("activityqixi/activityqixi",nil, true, "fashionshop")
        self.normalCellSize.y = 194
        self.coveritems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-640-180))
        --
        if self.coveritems.generalNode then
            self.coveritems["generalNode"]:removeAllChildrenWithCleanup(true)
            local name = "wangmuniangniang"
            local Gneral1 = CCSkeletonAnimation:create(name .."/" .. name .. ".json", name .."/" .. name .. ".atlas",1) --
            Gneral1:setAnimation("stand",true,0)
            Gneral1:setScale(2)
            Gneral1:setPosition(0,0)
            self.coveritems["generalNode"]:addChild(Gneral1)
        end
    else
        self.coverccb, self.coveritems = CCBReaderLoad("activitypentakill/activitypentakill",nil, true, "fashionshop")
        self.normalCellSize.y = 242
        self.coveritems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-640-180))

        
        if self.coveritems.changebg1 and self.coveritems.changebg2 and GameScene.layers["activity"].module.dailyCpActivityTimeStatus[52] then

            local cpnum = GameScene.layers["activity"].module.dailyCpActivityTimeStatus[52].cpnum or 0
            --单数火影 双数pantkill
            if cpnum%2 == 1 then
                self.coveritems.changebg2:setVisible(true)
                self.coveritems.changebg1:setVisible(false)
                if self.coveritems.changebg3 then
                    self.coveritems.changebg3:setVisible(false)
                end
                if self.coveritems.changebg4 then
                    self.coveritems.changebg4:setVisible(false)
                end
                if self.coveritems.changebg5 then
                    self.coveritems.changebg5:setVisible(false)
                end
                if self.coveritems.changebg6 then
                    self.coveritems.changebg6:setVisible(false)
                end
            else
                self.coveritems.changebg2:setVisible(false)
                self.coveritems.changebg1:setVisible(true)
                if self.coveritems.changebg3 then
                    self.coveritems.changebg3:setVisible(false)
                end
                if self.coveritems.changebg4 then
                    self.coveritems.changebg4:setVisible(false)
                end
                if self.coveritems.changebg5 then
                    self.coveritems.changebg5:setVisible(false)
                end
                if self.coveritems.changebg6 then
                    self.coveritems.changebg6:setVisible(false)
                end
            end


            -- if gamedata.config.activity_time["52"] and gamedata.config.activity_time["52"].icon and gamedata.config.activity_time["52"].icon == "activity_chunjie" then
            --     self.coveritems.changebg2:setVisible(false)
            --     self.coveritems.changebg1:setVisible(false)
            --     if self.coveritems.changebg3 then
            --         self.coveritems.changebg3:setVisible(false)
            --     end
            --     if self.coveritems.changebg4 then
            --         self.coveritems.changebg4:setVisible(false)
            --     end
            --     if self.coveritems.changebg5 then
            --         self.coveritems.changebg5:setVisible(false)
            --     end
            --     if self.coveritems.changebg6 then
            --         self.coveritems.changebg6:setVisible(true)
            --     end
            -- elseif gamedata.config.activity_time["52"] and gamedata.config.activity_time["52"].icon and gamedata.config.activity_time["52"].icon == "activity_shengdan" then
            --     self.coveritems.changebg2:setVisible(false)
            --     self.coveritems.changebg1:setVisible(false)
            --     if self.coveritems.changebg3 then
            --         self.coveritems.changebg3:setVisible(false)
            --     end
            --     if self.coveritems.changebg4 then
            --         self.coveritems.changebg4:setVisible(false)
            --     end
            --     if self.coveritems.changebg5 then
            --         self.coveritems.changebg5:setVisible(true)
            --     end
            --     if self.coveritems.changebg6 then
            --         self.coveritems.changebg6:setVisible(false)
            --     end
            -- elseif gamedata.config.activity_time["52"] and gamedata.config.activity_time["52"].icon and gamedata.config.activity_time["52"].icon == "activity_shamate" then
            --     self.coveritems.changebg2:setVisible(false)
            --     self.coveritems.changebg1:setVisible(false)
            --     if self.coveritems.changebg3 then
            --         self.coveritems.changebg3:setVisible(false)
            --     end
            --     if self.coveritems.changebg4 then
            --         self.coveritems.changebg4:setVisible(true)
            --     end
            --     if self.coveritems.changebg5 then
            --         self.coveritems.changebg5:setVisible(false)
            --     end
            --     if self.coveritems.changebg6 then
            --         self.coveritems.changebg6:setVisible(false)
            --     end
            -- elseif gamedata.config.activity_time["52"] and gamedata.config.activity_time["52"].icon and gamedata.config.activity_time["52"].icon == "activity_xiaodingdang" then
            --     self.coveritems.changebg2:setVisible(false)
            --     self.coveritems.changebg1:setVisible(false)
            --     if self.coveritems.changebg3 then
            --         self.coveritems.changebg3:setVisible(true)
            --     end
            --     if self.coveritems.changebg4 then
            --         self.coveritems.changebg4:setVisible(false)
            --     end
            --     if self.coveritems.changebg5 then
            --         self.coveritems.changebg5:setVisible(false)
            --     end
            --     if self.coveritems.changebg6 then
            --         self.coveritems.changebg6:setVisible(false)
            --     end
            -- elseif gamedata.config.activity_time["52"] and gamedata.config.activity_time["52"].icon and gamedata.config.activity_time["52"].icon == "activity_huoying" then
            --     self.coveritems.changebg2:setVisible(true)
            --     self.coveritems.changebg1:setVisible(false)
            --     if self.coveritems.changebg3 then
            --         self.coveritems.changebg3:setVisible(false)
            --     end
            --     if self.coveritems.changebg4 then
            --         self.coveritems.changebg4:setVisible(false)
            --     end
            --     if self.coveritems.changebg5 then
            --         self.coveritems.changebg5:setVisible(false)
            --     end
            --     if self.coveritems.changebg6 then
            --         self.coveritems.changebg6:setVisible(false)
            --     end
            -- else
            --     self.coveritems.changebg2:setVisible(false)
            --     self.coveritems.changebg1:setVisible(true)
            --     if self.coveritems.changebg3 then
            --         self.coveritems.changebg3:setVisible(false)
            --     end
            --     if self.coveritems.changebg4 then
            --         self.coveritems.changebg4:setVisible(false)
            --     end
            --     if self.coveritems.changebg5 then
            --         self.coveritems.changebg5:setVisible(false)
            --     end
            --     if self.coveritems.changebg6 then
            --         self.coveritems.changebg6:setVisible(false)
            --     end
            -- end
        end
    end

    --
    if self.coveritems.showpropicon then
        local showpropid = 20294
        if gamedata.config.activity_time["52"] and gamedata.config.activity_time["52"].param and gamedata.config.activity_time["52"].param > 0 then
            showpropid = gamedata.config.activity_time["52"].param
        end
        if ui.IDconfig(showpropid) and ui.IDconfig(showpropid).icon then
            setSpriteFrameByName(self.coveritems.showpropicon,ui.IDconfig(showpropid).icon)
        end
    end
    --

    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    -- printT(self.coveritems,"self.coveritems====")

    --todo
    self.normalCellSize.y = 194
    --
    -- local endString = ""
    -- if gamedata.config.activity_time["52"]["end"] and gamedata.config.activity_time["52"]["end"] ~= "" then
    --     local year, month, day, hour, min, sec = ui.getDate(gamedata.config.activity_time["52"]["end"])
    --     endString = year.."."..month.."."..day
    --     if tonumber(hour) < 1 and tonumber(min) < 1 and tonumber(sec) < 1 then
    --         local endt = os.time({year=tonumber(year),month=tonumber(month),day=tonumber(day),hour=tonumber(hour),min=tonumber(min),sec=tonumber(sec),isdst=false}) - 1
    --         local endtab = os.date("*t",endt)
    --         endString = endtab.year.."."..endtab.month.."."..endtab.day
    --     end
    -- end

    -- -- local otimestring = gameConfig.strings:string_common("limitex",6)..endString
    -- self.coveritems.m_oTimeNum:setString(string.format(gameConfig.strings:string_common("limitex",6),endString))
    -- --
    local updatatimestring = gameConfig.strings:string_common("fixedString","activity_cumulativerecharge",4)
    self.coveritems.m_oTimeNum:setString(updatatimestring)

    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","fashionshop",touchbegin)

    local function touchend(pos)
        if self.coveritems.listnode and ui.isTouched(self.coveritems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","fashionshop",touchend)

    self:updatatime()

    return self.coverccb
end

function fashionshop.updatatime(self)

--    local status,remintime = ui.checkDateActive(gamedata.config.activity_time["52"]["begin"],gamedata.config.activity_time["52"]["end"])
--
--    if self.coveritems.m_oTimeNum and remintime and remintime > 0 then
--        gameTimer:rigistTime("fashionshopupdata",remintime)
--
--        if gameTimer.times["fashionshopupdata"] and gameTimer.times["fashionshopupdata"] > 0 then
--            gameTimer:rigistTimeFunc("fashionshopupdata", function()
--                if gameTimer.times["fashionshopupdata"] <= 0 then
--                    if gameTimer.times["fashionshopupdata"] then
--                        print("finish")
--                        gameTimer:UnrigistTimeFunc("fashionshopupdata")
--                    end
--                elseif self.coveritems.m_oTimeNum then
--                    local updatatimestring = gameConfig.strings:string_common("fixedString","activity_cumulativerecharge",4) .. ui.makeTimeDayText(gameTimer.times["fashionshopupdata"],"day")
--                    self.coveritems.m_oTimeNum:setString(updatatimestring)
--                    -- ui.setStringWithStrokeAndShadow(self.coveritems.m_oTimeNum,nil,1)
--                end
--            end)
--        end
--    end
    -- local otimestring = gameConfig.strings:string_common("limitex",6)..endString
    -- self.coveritems.m_oTimeNum:setString(string.format(gameConfig.strings:string_common("limitex",6),endString))
    --

    if gamedata.config.copy_time and gamedata.config.copy_time["1"] and gamedata.config.copy_time["1"]["close"] then
        local endString = ""
        if GameScene.layers["activity"].module.dailyCpActivityTimeStatus[52] then
            local cpnum = GameScene.layers["activity"].module.dailyCpActivityTimeStatus[52].cpnum
            local cpday = GameScene.layers["activity"].module.dailyCpActivityTimeStatus[52].cpday


            local activityConfig = gamedata.config.activity_time[tostring(52)]
            local nowtime = gamedata:time()
            local temp = os.date("*t", nowtime)
            local timediff = nowtime + 86400*(activityConfig["continued_time"]-cpday) - temp.hour*3600 - temp.min*60 - temp.sec
            local endtab = os.date("*t", timediff-2)
            endString = endtab.month.."月"..endtab.day.."日24时"
            self.coveritems.m_oTimeNum:setString("活动道具掉落截止时间:"..endString)
        end
        
    end
end


function fashionshop.reloaddata(self,data,scoredata)
    -- self.m_iFreshTimes = data._freshTimes
    -- local nextindex = self.m_iFreshTimes+1
    -- if nextindex > table.getTableLength(gamedata.config.buycount_price) then
    --     nextindex = table.getTableLength(gamedata.config.buycount_price)
    -- end
    if scoredata and scoredata.num then
        local scorestring = "x"..scoredata.num
        self.coveritems.scoreLabel:setString(scorestring)
    end
    self.data = data
    self.scoreLabel = scoredata
    printT(self.data,"self.data==")
    if not self.show then return end
    if self.coveritems then
        if not self.ListTableView then
            self:createList()
        else
            self.ListTableView:reloadData()
        end
    end
end

function fashionshop.createList(self)
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
--                if gamedata.config.build[tostring(274)] and gamedata.config.build[tostring(274)].switch and gamedata.config.build[tostring(274)].switch == 1 then
                    cellCCB, ccbDocumentControler = CCBReaderLoad("activityqixi/cell_activityqixi", nil, true, "activitypentakill")
--                else
--                    cellCCB, ccbDocumentControler = CCBReaderLoad("activitypentakill/cell_activitypentakill", nil, true, "activitypentakill")
--                end
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
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

function fashionshop.setCell(self,item,destIndex)
    local tmpData = self.data[tostring(destIndex)]
    local tmpCanDothat = true
    local canExchangeNum = 99999999
    item.m_oExchangeNum:setString(string.format(gameConfig.strings:string_common("limitex",1),tmpData._once))

    ui.setLabelString(item.m_obtttf,gameConfig.strings:string_common("limitex",3),18)
    item.m_obutton:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if GameScene.layers["activity"].module.isContentScroll then  return end
            if tmpData._exchange[tostring(1)] >= 80001 and tmpData._exchange[tostring(1)] <= 81000 then
                if tmpData._status ~= 0 then
                    runGamePrompt({msg = gameConfig.strings:string_common("activity_fashion",2)})
                elseif not tmpCanDothat then
                    runGamePrompt({msg = gameConfig.strings:string_common("exchange",1)})
                else
                    local cb = function( num )
                        UIRequest({type = 4401,_id = tmpData._id,_num = num})
                    end
                    ui.exchangeMore(cb,canExchangeNum,tmpData._once,tmpData._max)
                end
            else
                if tmpData._once > 0 then
                    if tmpCanDothat then
                        local cb = function( num )
                            UIRequest({type = 4401,_id = tmpData._id,_num = num})
                        end
                        ui.exchangeMore(cb,canExchangeNum,tmpData._once,tmpData._max)
                    else
                        runGamePrompt({msg = gameConfig.strings:string_common("exchange",1)})
                    end
                elseif tmpData._once <= 0 then
                    runGamePrompt({msg = gameConfig.strings:string_common("guild_shop",6)})
                end
            end
    end, CCControlEventTouchUpInside)
    item.m_obutton:setTouchPriority(-103)

    if tmpData._exchange[tostring(1)] >= 80001 and tmpData._exchange[tostring(1)] <= 81000 then
        if tmpData._status ~= 0 or tmpData._once <= 0 then
            ui.addGray("CCControlButton",item.m_obutton)
        else
            ui.removeGray("CCControlButton",item.m_obutton)
        end
    else
        if tmpData._once <= 0 then
            ui.addGray("CCControlButton",item.m_obutton)
        else
            ui.removeGray("CCControlButton",item.m_obutton)
        end
    end

    -- printT(tmpData,"tmpData===")
    item["m_oDeng"]:setVisible(false)
    item["m_oGet3"]:setVisible(false)
    local tmpAddIndexs = 1
    canExchangeNum = (canExchangeNum > tmpData._once) and tmpData._once or canExchangeNum
    for i=1,5 do
        if item["m_oNeed"..i] then
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
                    if tmpData._item[tmpCheackIndex].cid == 1000 then
                        canExchangeNum = (math.floor(GameScene.roleinfo.coin/tmpStrNum) < canExchangeNum) and math.floor(GameScene.roleinfo.coin/tmpStrNum)  or canExchangeNum
                    elseif tmpData._item[tmpCheackIndex].cid == 1001 then
                        canExchangeNum = (math.floor(GameScene.roleinfo.gold/tmpStrNum) < canExchangeNum) and math.floor(GameScene.roleinfo.gold/tmpStrNum)  or canExchangeNum
                    elseif self.scoreLabel then
                        canExchangeNum = (math.floor(tmpData._nums[tmpCheackIndex].num/tmpStrNum) < canExchangeNum) and math.floor(tmpData._nums[tmpCheackIndex].num/tmpStrNum) or canExchangeNum
                    else
                        canExchangeNum = 0
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
                        print("cid===",tmpData._item[tmpCheackIndex].cid)
                        ui.setPopwindowByCid(tmpData._item[tmpCheackIndex].cid)
                    end, CCControlEventTouchUpInside)
                    item[tmpBtIndex]:setTouchPriority(-103)
                end
            end
        end
    end

    if tmpAddIndexs < 6 then
        if item["m_oNeed"..tmpAddIndexs] then
            item["m_oNeed"..tmpAddIndexs]:setVisible(true)
            setSpriteFrameByName(item["m_oJia"..tmpAddIndexs],"spr_136.png")
            item["m_oJia"..tmpAddIndexs]:setVisible(true)
        end
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



function fashionshop.clear(self)
    gameTouch:UnrigistFunc("begin","fashionshop")
    gameTouch:UnrigistFunc("end","fashionshop")

    gameTimer:UnrigistTimeFunc("fashionshopupdata")

    self.show = false
    self.ListTableView = nil
    self.data = {}
    -- self.status = {}
    -- self.index = 1
    if self.coverccb then
        self.coverccb:removeAllChildrenWithCleanup(true)
        self.coverccb:removeFromParentAndCleanup(true)
        self.coverccb = nil
        self.coveritems = nil
    end
end

return fashionshop �Y  