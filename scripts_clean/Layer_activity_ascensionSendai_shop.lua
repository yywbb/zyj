
local ascensionSendai_shop = {
    rootNode = nil,
    rootItems = nil,

    isscrolltouched = false,
    buttontouch = -103,

    rewardCellSize = {x=1080, y=280},
    time = 0,
    shengxianbi = 0,
    rewardData = nil,

    listTableView = nil,

    config = {},

}

function ascensionSendai_shop.init(self, size)

    self.show = true
    self.contentsize = size
    self.rootNode, self.rootItems = CCBReaderLoad("shengxiantai/shengxiantai_shop",nil, true, "shengxiantai_shop")

    self.rootItems.topnode:setPositionY(self.contentsize.y-180)
    self.rootItems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width, self.contentsize.y-520-462))

    --去升仙台
    ui.setLabelString(self.rootItems.backText,nil,18)
    self.rootItems.backBtn:setTouchPriority(-102)
    self.rootItems.backBtn:setSwallowsTouch(true)
    self.rootItems.backBtn:addHandleOfControlEvent(function()
        GameScene:shiftLayerById(664)
    end,CCControlEventTouchUpInside)

    self.config = gamedata.config.shengxian_shop or {}

    local function touchbegin(pos)
        self.isscrolltouched = false
        self.touchbegin = {x = pos.x, y = pos.y}
    end
    gameTouch:rigistFunc("begin","ascensionSendai_shop",touchbegin)

    local function touchend(pos)
        if math.abs(pos.x - (self.touchbegin and self.touchbegin.x or pos.x)) > 20 or math.abs(pos.y - (self.touchbegin and self.touchbegin.y or pos.y)) > 20 then
            self.isscrolltouched = false
        elseif self.rootItems.listnode and ui.isTouched(self.rootItems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","ascensionSendai_shop",touchend)

    return self.rootNode
end

function ascensionSendai_shop.reloadData(self, data)
    print("升仙台商店 reloadData")
    self.time = data.shopdata.time
    self.shengxianbi = data.shopdata.shengxianbi
    self.rewardData = data.data

    self.rootItems.contribution:setString(self.shengxianbi)
    --倒计时
    gameTimer:rigistTime("ascensionSendai_shop", self.time)
    gameTimer:rigistTimeFunc("ascensionSendai_shop",function()
        if gameTimer.times["ascensionSendai_shop"] >= 0 then
            self.rootItems.uptime:setString(ui.makeTimeText(gameTimer.times["ascensionSendai_shop"], "hour"))
        end
        if gameTimer.times["ascensionSendai_shop"] == 0 then
            UIRequest({type = 8856})
            gameTimer:UnrigistTimeFunc("ascensionSendai_shop")
        end
    end)

    if not self.listTableView then
        self:createRewardList()
    else
        self.listTableView:reloadData()
    end
end

function ascensionSendai_shop.createRewardList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("shengxiantai/cell_shengxiantai_shop", nil, true, "cell_shengxiantai_shop")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                --ui.tableviewAnimation(self.listTableView,cellCCB,self.rewardCellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            if self.rewardData[tostring((a1+1)*2-1)] then
                ccbDocumentControler.propnode1:setVisible(true)
                self:setone(self.rewardData[tostring((a1+1)*2-1)],ccbDocumentControler,1)
            else
                ccbDocumentControler.propnode1:setVisible(false)
            end

            if self.rewardData[tostring((a1+1)*2)] then
                ccbDocumentControler.propnode2:setVisible(true)
                self:setone(self.rewardData[tostring((a1+1)*2)],ccbDocumentControler,2)
            else
                ccbDocumentControler.propnode2:setVisible(false)
            end

            cellCCB:setPosition(self.rewardCellSize.x/2, -8)

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = math.ceil(table.getTableLength(self.rewardData)/2)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.listTableView = ui.createLuaTableView({
        handle = rankListHandle,
        viewwidth = self.rootItems.listnode:getContentSize().width,
        viewheight = self.rootItems.listnode:getContentSize().height,
        dire = 1
    })
    self.listTableView:setTouchPriority(-101)
    self.rootItems.listnode:addChild(self.listTableView)
end

function ascensionSendai_shop.setone(self,data,items,index)
    if not data then
        return
    end

    local config = self.config[tostring(data.id)]
    if not config then
        return
    end

    local key_Ex
    local icon_key
    if index == nil or index == 1 then
        key_Ex = ""
        icon_key = ""
    else
        key_Ex = "_2"
        icon_key = "_1"
    end

    if (config.limit and config.limit > 0) then
        if config.limit - data.num > 0 then
            items["desc"..key_Ex]:setString("剩余次数: "..(config.limit-data.num))
        else
            items["desc"..key_Ex]:setString("剩余次数: ".."0")
        end
    else
        items["desc"..key_Ex]:setString("")
    end

    if config.lv and config.lv > 0 then
        items["needlv"..key_Ex]:setString(gameConfig.strings:string_common("sports",20))
        if GameScene.roleinfo.level >= config.lv then
            items["needlv2"..key_Ex]:setString(config.lv)
            items["shadowNode"..key_Ex]:setVisible(false)
        else
            items["needlv2"..key_Ex]:setString(config.lv)
            items["shadowNode"..key_Ex]:setVisible(true)
        end
    else
        items["needlv"..key_Ex]:setString("")
        items["needlv2"..key_Ex]:setString("")
        items["shadowNode"..key_Ex]:setVisible(false)
    end
    --
    local id,num = ui.getIDandNUM(config.reward)
    local propConfig = ui.IDconfig(id)
    local id2,num2 = ui.getIDandNUM(config.consume) --仙玉消耗数量

    ui.setLabelString(items["propname"..key_Ex], propConfig.name, (propConfig.quality>1 and propConfig.quality or 1)*2-1)
    ui.setNewIcon(items,{cid = id, num = num}, index-1)
    items["prestige"..key_Ex]:setString(num2)
    --
    items["i_button"..icon_key]:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if propConfig.staffType == "token_fragment" then
            ui.setPopwindowByCid(id,{cid = id})
        else
            ui.setPopwindowByCid(id)
        end
    end, CCControlEventTouchUpInside)
    items["i_button"..icon_key]:setTouchPriority(-102)
    --兑换
    ui.setLabelString(items["exchangeText"..key_Ex], gameConfig.strings:string_common("sports",2), 18)
    items["exchange"..key_Ex]:setTouchPriority(-102)
    items["exchange"..key_Ex]:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        if not self.isscrolltouched then return end
        gameTouch:clickprofbytime(0.5)
        if config.lv and config.lv > GameScene.roleinfo.level then
            runGamePrompt({msg = config.lv..gameConfig.strings:string_common("sports",24)})
        elseif (config.limit and config.limit > 0) and (data.num >= config.limit) then
            -- runGamePrompt({msg = "超出兑换次数限制"})
            runGamePrompt({msg = gameConfig.strings:string_common("sports",12)})
        elseif (self.shengxianbi < num2) then
            runGamePrompt({msg = "升仙币不足"})
        else
            local exchangeNum = config.limit-data.num
            if exchangeNum > 1 then
                local function shopExchangeRequest(num)
                    if self.shengxianbi < num2*num then
                        runGamePrompt({msg = "升仙币不足"})
                    else
                        UIRequest({type = 8857, id = data.id, num = num, price = num2*num})
                    end
                end
                gameWindows:openWindow("shopExchange",{cid = id, num = num, cost = {{cid = id2, num = num2}}, exchangeNum = exchangeNum}, shopExchangeRequest)
            else
                UIRequest({type = 8857, id = data.id, num = 1})
            end
        end
    end, CCControlEventTouchUpInside)

    if (config.limit and config.limit > 0) and (data.num >= config.limit) then
        ui.addGray("CCControlButton",items["exchange"..key_Ex])
        ui.addGray("CCLabelTTF",items["exchangeText"..key_Ex])
    elseif config.lv and config.lv > GameScene.roleinfo.level then
        ui.addGray("CCControlButton",items["exchange"..key_Ex])
        ui.addGray("CCLabelTTF",items["exchangeText"..key_Ex])
    else
        ui.removeGray("CCControlButton",items["exchange"..key_Ex])
        ui.removeGray("CCLabelTTF",items["exchangeText"..key_Ex])
    end

end

function ascensionSendai_shop.clear(self)
    self.show = false

    gameTouch:UnrigistFunc("begin","ascensionSendai_shop")
    gameTouch:UnrigistFunc("end","ascensionSendai_shop")
    if gameTimer.times["ascensionSendai_shop"] then
        gameTimer:UnrigistTimeFunc("ascensionSendai_shop")
    end

    if self.rootNode then   
        self.rootNode:removeAllChildrenWithCleanup(true)
        self.rootNode:removeFromParentAndCleanup(true)
        self.rootNode = nil
        self.rootItems = nil
    end

    self.rewardData = nil
    self.config = {}
    self.listTableView = nil
    
end

return ascensionSendai_shop
