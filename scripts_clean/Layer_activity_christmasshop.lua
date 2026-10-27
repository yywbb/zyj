--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/25
-- Time: 15:30
-- To change this template use File | Settings | File Templates.
--

local christmasshop = {
    isscrolltouched = false,
    ListTableView = nil,
    normalCellSize = {x=1080,y=228+14},
    -- m_iFreshTimes = nil,
}

LX_BASEGOLD = 50


function christmasshop.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("activityshengdan/activityshengdan",nil, true, "christmasshop")

    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    self.coveritems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-640-180))
    -- printT(self.coveritems,"self.coveritems====")

    local updatatimestring = gameConfig.strings:string_common("fixedString","activity_cumulativerecharge",4)
    self.coveritems.m_oTimeNum:setString(updatatimestring)

    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","christmasshop",touchbegin)

    local function touchend(pos)
        if self.coveritems.listnode and ui.isTouched(self.coveritems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","christmasshop",touchend)

    self:updatatime()

    return self.coverccb
end

function christmasshop.updatatime(self)

    local status,remintime = ui.checkDateActive(gamedata.config.activity_time["62"]["begin"],gamedata.config.activity_time["62"]["end"])

    if self.coveritems.m_oTimeNum and remintime and remintime > 0 then
        gameTimer:rigistTime("christmasshopupdata",remintime)

        if gameTimer.times["christmasshopupdata"] and gameTimer.times["christmasshopupdata"] > 0 then
            gameTimer:rigistTimeFunc("christmasshopupdata", function()
                if gameTimer.times["christmasshopupdata"] <= 0 then
                    if gameTimer.times["christmasshopupdata"] then
                        print("finish")
                        gameTimer:UnrigistTimeFunc("christmasshopupdata")
                    end
                elseif self.coveritems.m_oTimeNum then
                    local updatatimestring = gameConfig.strings:string_common("fixedString","activity_cumulativerecharge",4) .. ui.makeTimeDayText(gameTimer.times["christmasshopupdata"],"day")
                    self.coveritems.m_oTimeNum:setString(updatatimestring)
                    -- ui.setStringWithStrokeAndShadow(self.coveritems.m_oTimeNum,nil,1)
                end
            end)
        end
    end

end

function christmasshop.reloaddata(self,data,scoredata)

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

function christmasshop.createList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityshengdan/cell_activityshengdan", nil, true, "cell_activityshengdan")
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

function christmasshop.setCell(self,item,destIndex)
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
                    UIRequest({type = 4406,_id = tmpData._id,_num = num})
                end
                ui.exchangeMore(cb,canExchangeNum,tmpData._once,tmpData._max)
            end
        else
            if tmpData._once > 0 then
                if tmpCanDothat then
                    local cb = function( num )
                        UIRequest({type = 4406,_id = tmpData._id,_num = num})
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
    for i=1,3 do
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
                    canExchangeNum = canExchangeNum > tmpData._once and math.floor(GameScene.roleinfo.coin/tmpStrNum)  or canExchangeNum
                elseif tmpData._item[tmpCheackIndex].cid == 1001 then
                    canExchangeNum = canExchangeNum > tmpData._once and math.floor(GameScene.roleinfo.gold/tmpStrNum)  or canExchangeNum
                elseif self.scoreLabel then
                    canExchangeNum = canExchangeNum > tmpData._once and math.floor(tmpData._nums[tmpCheackIndex].num/tmpStrNum) or canExchangeNum
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

    if tmpAddIndexs < 4 then
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



function christmasshop.clear(self)
    gameTouch:UnrigistFunc("begin","christmasshop")
    gameTouch:UnrigistFunc("end","christmasshop")

    gameTimer:UnrigistTimeFunc("christmasshopupdata")

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

return christmasshop