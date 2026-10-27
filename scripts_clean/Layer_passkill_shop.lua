--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-23
-- Time: 下午3:17
-- To change this template use File | Settings | File Templates.
--

local passkill_shop = {
    rewardCellSize = {x=1080, y=280},

    resource = nil,

    rootNode = nil,
    rootItems = nil,
    rewardListTableView = nil,

    rewardData = nil,
    myData = nil,

}

-- function passkill_shop.init(self,parent,toppos)
function passkill_shop.init(self,size)
    self.contentsize = size
    self.show = true

    self.rootNode,self.rootItems = CCBReaderLoad("passkill/passkill_shop", nil, true, "passkill_shop")


    self.rootItems.topnode:setPositionY(self.contentsize.y-180)

    self.rootItems.rewardScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-520-462))


    -- ui.setLabelString(self.rootItems.descText,nil,13)
    -- ui.setLabelString(self.rootItems.zhanjiangcoinText,nil,150)
    -- ui.setLabelString(self.rootItems.zhanjiangcoinLabel,nil,150)

    --去过关斩将链接
    
    ui.setLabelString(self.rootItems.gotoSportsText,nil,18)
    self.rootItems.gotoSportsBtn:setTouchPriority(-102)
    self.rootItems.gotoSportsBtn:setSwallowsTouch(true)
    self.rootItems.gotoSportsBtn:addHandleOfControlEvent(function()
        print("gotoSportsBt====")
        -- GameScene:shiftLayer("passkillmain","up")
        GameScene:shiftLayerById(175)

    end,CCControlEventTouchUpInside)

    
    
    return self.rootNode
end


function passkill_shop.reloadData(self,data)
    print("passkill_shop.reloadrank==")
    if not self.show then return end

    if data then
        self.passkillshop = data
    else
        return
    end
    -- ui.setLabelString(self.rootItems.zhanjiangcoinLabel,self.passkillshop.killcoinnum,21)
    self.rootItems.zhanjiangcoinLabel:setString(self.passkillshop.killcoinnum)

    --todo
    local costid,costnum = ui.getIDandNUM(gamedata.config.global_kv.through_refresh.value)
    local xgold = costnum or 0
    self.rootItems.resetgoldnode:setVisible(false)
--    local tempconfig = gamedata.config.buycount_price
--    local resetnum = self.passkillshop.changenum or 0
--    if resetnum > 59 then
--        resetnum = 59
--    end
--    if tempconfig[tostring(resetnum+1)] and tempconfig[tostring(resetnum+1)].through_refresh then
--        xgold = tempconfig[tostring(resetnum+1)].through_refresh
--    end
    if xgold > 0 then
        self.rootItems.resetgoldnode:setVisible(true)
        -- ui.setLabelString(self.rootItems.resetgold,xgold,21)
        self.rootItems.resetgold:setString(xgold)
    end
    --
    local hasresetnum = 0
    if gamedata.config.global_kv.through_times_up then
        hasresetnum = tonumber(gamedata.config.global_kv.through_times_up.value)-(self.passkillshop.changenum or 0)
    end
    if hasresetnum > 0 then
        ui.removeGray("CCControlButton",self.rootItems.resetbutton)
    else
        self.rootItems.resetgoldnode:setVisible(false)
        ui.addGray("CCControlButton",self.rootItems.resetbutton)
    end

    -- ui.setLabelString(self.rootItems.resetnum,gameConfig.strings:string_common("ui",71)..(hasresetnum > 0 and hasresetnum or 0),13)
    self.rootItems.resetnum:setString(gameConfig.strings:string_common("ui",71)..(hasresetnum > 0 and hasresetnum or 0))

    -- 刷新按钮
    self.rootItems.resetbutton:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then return end
        gameTouch:clickprofbytime(1)

        if gamedata.config.global_kv.through_times_up and tonumber(gamedata.config.global_kv.through_times_up.value) <= (self.passkillshop.changenum or 0) then
            runGamePrompt({msg = gameConfig.strings:string_common("ui",70)})
        elseif self.passkillshop.killcoinnum < xgold then
            runGamePrompt({msg = "斩将币不足"})
        else
            UIRequest({type = 3828, xgold = 0})       --已改为消耗斩将币，不消耗元宝
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.resetbutton:setSwallowsTouch(true)
    self.rootItems.resetbutton:setTouchPriority(-103)
    --

    if not self.rewardListTableView then
        self:createRewardList()
    else
        if self.rewardListTableView:getLuaContentOffsetY() < self.rootItems.rewardScroll:getContentSize().height - table.getTableLength(self.passkillshop.exchanged)*self.rewardCellSize.y then
            self.rewardListTableView:setLuaContentOffset(0, self.rootItems.rewardScroll:getContentSize().height - table.getTableLength(self.passkillshop.exchanged)*self.rewardCellSize.y)
        end
        self.rewardListTableView:reloadData()
    end

end


function passkill_shop.createRewardList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("passkill/cell_passkill_shop2.ccbi", nil, true, "cell_passkill_shop")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.rewardListTableView,cellCCB,self.rewardCellSize.x/2, -8,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            if self.passkillshop.exchanged[tostring((a1+1)*2-1)] then
                ccbDocumentControler.exnode1:setVisible(true)
                self:setone(self.passkillshop.exchanged[tostring((a1+1)*2-1)],ccbDocumentControler,1)
            else
                ccbDocumentControler.exnode1:setVisible(false)
            end

            if self.passkillshop.exchanged[tostring((a1+1)*2)] then
                ccbDocumentControler.exnode2:setVisible(true)
                self:setone(self.passkillshop.exchanged[tostring((a1+1)*2)],ccbDocumentControler,2)
            else
                ccbDocumentControler.exnode2:setVisible(false)
            end

            if self.rewardListTableView then
                cellCCB:setPosition(self.rewardCellSize.x/2, -8)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = math.ceil(table.getTableLength(self.passkillshop.exchanged)/2)
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
    self.rewardListTableView:setTouchPriority(-101)
    self.rootItems.rewardScroll:addChild(self.rewardListTableView)
end


function passkill_shop.setone(self,data,items,index)
    print("index==",index)
    -- printT(data)
    
    local key_Ex
    local icon_key
    if index == nil or index == 1 then
        key_Ex = ""
        icon_key = ""
    else
        key_Ex = "_2"
        icon_key = "_1"
    end


    if not data then
        -- print("notid===",data.id)
        return
    end

    local config = gamedata.config.through_shop[tostring(data.id)]

    local spenddata = ui.getIDandNUMs(config.prestige)

    print("i..config...:")
    -- printT(config)
    if not config  then
        print("notid===",data.id)
        return
    end
    -- printT(items,"items===")
    print(key_Ex)
    if (config.buttontype == 1) and (config.limit and config.limit > 0) then
        -- if data.status == -1 then
            items["desc"..key_Ex]:setString(gameConfig.strings:exchange_num(data.num))
        -- else
            -- items["desc"..key_Ex]:setString(gameConfig.strings:butStates(config.limit-data.status))
        -- end
        -- items.desc:setString("今日还可购买"..(config.limit-data.status).."次")
    else
        items["desc"..key_Ex]:setString("")
    end
    -- ui.setLabelString(items["desc"..key_Ex],nil,14)
    if config.buttontype == 1 then
        if config.rank == 0 then
            items["buynum"..key_Ex]:setVisible(false)
            items["buynumText"..key_Ex]:setVisible(false)
        end
        items["buynum"..key_Ex]:setString(config.rank)
        -- items.desc:setString(gameConfig.strings:string_common("sports",9))
        items["prestige"..key_Ex]:setString(spenddata[1].num)
        items["prestigeSprite"..key_Ex]:setVisible(true)
        setControlButtonFrame(items["exchange"..key_Ex],"b_s_button2","b_s_button2_h","b_s_button2")
    else
        -- items.desc:setString("需要达到排名")
        -- items.desc:setString(gameConfig.strings:string_common("sports",10))
        items["prestige"..key_Ex]:setString(config.rank)
        items["prestigeSprite"..key_Ex]:setVisible(false)
        setControlButtonFrame(items["exchange"..key_Ex],"b_s_button1","b_s_button1_h","b_s_button1")
    end
    ui.setLabelString(items["prestige"..key_Ex],nil,13)
    ui.setLabelString(items["prestigeText"..key_Ex],nil,13)
    

    local id,num = ui.getIDandNUM(config.reward)

    local propConfig = ui.IDconfig(id)

    items["propname"..key_Ex]:setString(config.name)
    ui.setLabelString(items["propname"..key_Ex],nil,(propConfig.quality>1 and propConfig.quality or 1)*2-1)

    ui.setNewIcon(items,{cid = id, num = num},index-1)
    --
    items["i_button"..icon_key]:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        if propConfig.staffType == "token_fragment" then
            ui.setPopwindowByCid(id,{cid = id})
        else
            ui.setPopwindowByCid(id)
        end
    end, CCControlEventTouchUpInside)
    items["i_button"..icon_key]:setTouchPriority(-102)
    --

    if config.buttontype == 1 then
        -- items.exchangeText:setString("兑换")
        items["exchangeText"..key_Ex]:setString(gameConfig.strings:string_common("sports",2))
    else
        -- items["exchangeText"..key_Ex]:setString("领取")
        items["exchangeText"..key_Ex]:setString(gameConfig.strings:string_common("sports",7))
    end
    ui.setLabelString(items["exchangeText"..key_Ex],nil,18)

    items["exchange"..key_Ex]:setTouchPriority(-102)
    items["exchange"..key_Ex]:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameTouch:clickprofbytime(0.5)

        if (config.buttontype == 1) and (self.passkillshop.killcoinnum < spenddata[1].num) then
            -- runGamePrompt({msg = "积分不足"})
            runGamePrompt({msg = "斩将币不足"})
        elseif (config.buttontype == 1) and (config.limit and config.limit > 0) and (data.num <= 0) then
            -- runGamePrompt({msg = "超出兑换次数限制"})
            runGamePrompt({msg = gameConfig.strings:string_common("sports",12)})
        -- elseif (config.buttontype == 2) and (data.status < 2) then
        elseif (config.buttontype == 2) then
            -- runGamePrompt({msg = "未达到领取条件"})
            runGamePrompt({msg = gameConfig.strings:string_common("sports",13)})
        else
            --UIRequest({type = 3823, id = data.id})
            function shopExchangeRequest(num)
                if (config.buttontype == 1) and (self.passkillshop.killcoinnum < spenddata[1].num*num) then
                    runGamePrompt({msg = "斩将币不足"})
                else
                    UIRequest({type = 3823, id = data.id,num = num})
                end
            end
            if data.num > 5 then
                gameWindows:openWindow("shopExchange",{cid = id,num = num,cost = spenddata,exchangeNum = data.num},shopExchangeRequest)
            else
                UIRequest({type = 3823, id = data.id,num = 1})
            end    
        end

    end, CCControlEventTouchUpInside)


    if (config.buttontype == 1) and (self.passkillshop.killcoinnum < spenddata[1].num) then
        ui.addGray("CCControlButton",items["exchange"..key_Ex])
        ui.addGray("CCLabelTTF",items["exchangeText"..key_Ex])
    elseif (config.buttontype == 1) and (config.limit and config.limit > 0) and (data.num <= 0) then
        ui.addGray("CCControlButton",items["exchange"..key_Ex])
        ui.addGray("CCLabelTTF",items["exchangeText"..key_Ex])
    -- elseif (config.buttontype == 2) and (data.status < 2) then
    elseif (config.buttontype == 2) then
        ui.addGray("CCControlButton",items["exchange"..key_Ex])
        ui.addGray("CCLabelTTF",items["exchangeText"..key_Ex])
    else
        ui.removeGray("CCControlButton",items["exchange"..key_Ex])
        ui.removeGray("CCLabelTTF",items["exchangeText"..key_Ex])
    end

end



function passkill_shop.clear(self)
    self.show = false

    self.passkillshop = nil

    self.rewardListTableView = nil

    if self.rootNode then
        self.rootNode:removeAllChildrenWithCleanup(true)
        self.rootNode:removeFromParentAndCleanup(true)
        self.rootNode = nil
        self.rootItems = nil
    end
    
end

function passkill_shop.UIUpdateData(self, isreset)
    if isreset then
        -- self:shiftPage(self.selectpage)
        UIRequest({type = 3822})
        
    end
end


return passkill_shop