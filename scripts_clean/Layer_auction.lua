
--

local auction = {

    resource = nil,

    rootNode = nil,
    rootItems = nil,

    animationManager = nil,

    localListTableView = nil,
    serviceListTableView = nil,
    myListTableView = nil,

    messageListTableView = nil,

    auction = {},

    localData = {},
    serviceData = {},
    myData = {},

    messageData = {},

    pageconfig = {"local","service","my"},
    --pagename = {"本服拍卖","跨服拍卖","我的竞拍"},
    pagename = {gameConfig.strings:string_common("auction",1),gameConfig.strings:string_common("auction",2),gameConfig.strings:string_common("auction",3)},
    selectpage = "local",

    normalCellSize = {x=1080,y=210},
    messageCellSize = {x=990,y=50},

    messageopen = "close",

    buttontouch = -101,

    isscrolltouched = false,
    isauctiontime_less = false,
    isauctiontime_over = false,

    isfirst = false,

    showerr = true,
}

function auction.init(self,size)

    self.contentsize = size
    self.show = true

    self.rootNode,self.rootItems = CCBReaderLoad("paimaihang/paimaihang", nil, true, "paimaihang")
    self.animationManager = getAnimationManager(self.rootItems)

    self.rootNode:setPosition(0,0)

    self.rootItems.topnode:setPositionY(self.contentsize.y-180)

    self.rootItems.localNode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-gameConfig.maiscenebottomheight-550))
    self.rootItems.serviceNode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-gameConfig.maiscenebottomheight-550))
    self.rootItems.myNode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-gameConfig.maiscenebottomheight-550))

    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","paimaihang",touchbegin)
    local function touchend(pos)
        if self.rootItems.localNode and ui.isTouched(self.rootItems.localNode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
        if self.rootItems.serviceNode and ui.isTouched(self.rootItems.serviceNode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
        if self.rootItems.myNode and ui.isTouched(self.rootItems.myNode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
        if self.rootItems.messageNode and ui.isTouched(self.rootItems.messageNode,pos.x,pos.y) then
            self.isscrolltouched = false
        end
    end
    gameTouch:rigistFunc("end","paimaihang",touchend)

    --
    self.rootItems.backBtn:setSwallowsTouch(true)
    self.rootItems.backBtn:setTouchPriority(-103)
    self.rootItems.backBtn:addHandleOfControlEvent(function()
        print("backBtn===")
        if GameScene.layers["activity"].module.isContentScroll then  return end
        GameScene:shiftLayer("main","down")
    end, CCControlEventTouchUpInside)

    self.rootItems.ruleButton:setSwallowsTouch(true)
    self.rootItems.ruleButton:setTouchPriority(-103)
    self.rootItems.ruleButton:addHandleOfControlEvent(function()
        print("ruleButton===")
        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameWindows:openWindow("auctionRule",nil)
    end, CCControlEventTouchUpInside)

    self.rootItems.messageButton:setSwallowsTouch(true)
    self.rootItems.messageButton:setTouchPriority(-103)
    self.rootItems.messageButton:addHandleOfControlEvent(function()
        print("messageButton===")
        if GameScene.layers["activity"].module.isContentScroll then  return end
        self:openMessage()
    end, CCControlEventTouchUpInside)
    --
    ui.setLabelString(self.rootItems.listLab,nil,18)
    self.rootItems.listButton:setSwallowsTouch(true)
    self.rootItems.listButton:setTouchPriority(-103)
    self.rootItems.listButton:addHandleOfControlEvent(function()
        print("listButton===")
        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameWindows:openWindow("auctionLog",nil)
    end, CCControlEventTouchUpInside)
    --

    for k,v in ipairs(self.pageconfig) do
        self.rootItems["buttontext"..k]:setString(self.pagename[k])

        self.rootItems["button"..k]:setSwallowsTouch(true)
        self.rootItems["button"..k]:setTouchPriority(-103)
        self.rootItems["button"..k]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            self:shiftPage(self.pageconfig[k])
        end,CCControlEventTouchUpInside)
    end
    --
    self:shiftPage(self.selectpage)

    self:openMessage("close")
    --
    self.isfirst = true
    --
    return self.rootNode
end

function auction.clear(self)

    self.showerr = true

    self.isfirst = false
    self.show = false

    if gameTimer.times["auction_refresh"] then
        gameTimer:UnrigistTimeFunc("auction_refresh")
    end
    if gameTimer.times["auction_time"] then
        gameTimer:UnrigistTimeFunc("auction_time")
    end
    gameTouch:UnrigistFunc("begin","paimaihang")
    gameTouch:UnrigistFunc("end","paimaihang")

    self.auction = {}
    self.messageopen = "close"
    self.isscrolltouched = false
    self.isauctiontime_less = false
    self.isauctiontime_over = false
    self.animationManager = nil
    self.localListTableView = nil
    self.serviceListTableView = nil
    self.myListTableView = nil
    self.messageListTableView = nil
    self.selectpage = "local"

    self.rootNode = nil
    self.rootItems = nil
end




function auction.shiftPage(self,type)
    self.selectpage = type

    for k,v in ipairs(self.pageconfig) do
        if v == type then
            self.rootItems[v.."Node"]:setVisible(true)
            self.rootItems[v.."Node"]:setPositionX(0)
            setSpriteFrameByName(self.rootItems["buttonsprite"..k], gameConfig.images.pageButtonON)
        else
            self.rootItems[v.."Node"]:setVisible(false)
            self.rootItems[v.."Node"]:setPositionX(9999)
            setSpriteFrameByName(self.rootItems["buttonsprite"..k], gameConfig.images.pageButtonOFF)
        end
    end

    if self.selectpage == "local" then
        if not next(self.localData) then
            self.rootItems.timeLab:setVisible(false)
            self.rootItems.time:setVisible(false)
            self.rootItems.timeLab1:setVisible(true)
            self.rootItems.time1:setVisible(true)
            self.rootItems.timeLab2:setVisible(false)
            self.rootItems.time2:setVisible(false)
            if self.rootItems.noitem then
                self.rootItems.noitem:setVisible(true) 
            end    
        else
            self.rootItems.timeLab:setVisible(true)
            self.rootItems.time:setVisible(true)
            self.rootItems.timeLab1:setVisible(false)
            self.rootItems.time1:setVisible(false)
            self.rootItems.timeLab2:setVisible(false)
            self.rootItems.time2:setVisible(false)
            if self.rootItems.noitem then
                self.rootItems.noitem:setVisible(false) 
            end   
        end
    elseif self.selectpage == "service" then
        if not next(self.serviceData) then
            self.rootItems.timeLab:setVisible(false)
            self.rootItems.time:setVisible(false)
            self.rootItems.timeLab1:setVisible(false)
            self.rootItems.time1:setVisible(false)
            self.rootItems.timeLab2:setVisible(true)
            self.rootItems.time2:setVisible(true)
            if self.rootItems.noitem then
                self.rootItems.noitem:setVisible(true) 
            end   
        else
            self.rootItems.timeLab:setVisible(true)
            self.rootItems.time:setVisible(true)
            self.rootItems.timeLab1:setVisible(false)
            self.rootItems.time1:setVisible(false)
            self.rootItems.timeLab2:setVisible(false)
            self.rootItems.time2:setVisible(false)
            if self.rootItems.noitem then
                self.rootItems.noitem:setVisible(false) 
            end   
        end
    else
        if next(self.localData) or next(self.serviceData) then
            self.rootItems.timeLab:setVisible(true)
            self.rootItems.time:setVisible(true)
            self.rootItems.timeLab1:setVisible(false)
            self.rootItems.time1:setVisible(false)
            self.rootItems.timeLab2:setVisible(false)
            self.rootItems.time2:setVisible(false)
            if self.rootItems.noitem then
                self.rootItems.noitem:setVisible(false) 
            end   
        else
            self.rootItems.timeLab:setVisible(false)
            self.rootItems.time:setVisible(false)
            self.rootItems.timeLab1:setVisible(false)
            self.rootItems.time1:setVisible(false)
            self.rootItems.timeLab2:setVisible(false)
            self.rootItems.time2:setVisible(false)
            if self.rootItems.noitem then
                self.rootItems.noitem:setVisible(true) 
            end   
        end
    end

    if self[self.selectpage.."ListTableView"] then
        self[self.selectpage.."ListTableView"]:setLuaContentOffset(0,self.rootItems[self.selectpage.."Node"]:getContentSize().height - table.getTableLength(self[self.selectpage.."Data"])*self.normalCellSize.y)
    end

end




function auction.ReloadData(self,data)

    if data then
        self.auction = data
    end

    local nowtime = os.date("*t", gamedata:time())
    local wday = ((nowtime.wday-1) < 1) and 7 or (nowtime.wday-1)


    local config = gamedata.config["auction_pos_rc_"..self.auction.cpnum]
    local auction_pos = config and config[tostring(wday)] or {}


    if auction_pos.oneself and auction_pos.oneself ~= "" then
        self.localData = ui.getIDSFromStr(auction_pos.oneself)
    else
        self.localData = {}
    end

    if auction_pos.whole and auction_pos.whole ~= "" then
        self.serviceData = ui.getIDSFromStr(auction_pos.whole)
    else
        self.serviceData = {}
    end

    --
    local localTemp = {}
    local serviceTemp = {}


    local auction_items = gamedata.config.auction_items
    for k = #self.localData,1,-1  do
        if not auction_items[tostring(self.localData[k])] then
            table.remove(self.localData,k)
            if self.showerr then
                runGamePrompt({msg = "配置表异常1"})
            end
        elseif auction_items[tostring(self.localData[k])] and auction_items[tostring(self.localData[k])].level_limit and auction_items[tostring(self.localData[k])].level_limit > GameScene.roleinfo.level then
            table.remove(self.localData,k)
        elseif not (self.auction and self.auction.items and self.auction.items[tostring(self.localData[k])]) then
            table.remove(self.localData,k)
            if self.showerr then
                runGamePrompt({msg = "配置表异常3"})
            end
        elseif localTemp[tostring(self.localData[k])] then
            table.remove(self.localData,k)
            if self.showerr then
                runGamePrompt({msg = "配置表异常2"})
            end
        else
            localTemp[tostring(self.localData[k])] = 1  
        end
    end
    for k = #self.serviceData,1,-1  do
        if not auction_items[tostring(self.serviceData[k])] then
            table.remove(self.serviceData,k)
            if self.showerr then
                runGamePrompt({msg = "配置表异常1"})
            end
        elseif auction_items[tostring(self.serviceData[k])] and auction_items[tostring(self.serviceData[k])].level_limit and auction_items[tostring(self.serviceData[k])].level_limit > GameScene.roleinfo.level then
            table.remove(self.serviceData,k)
        elseif not (self.auction and self.auction.items and self.auction.items[tostring(self.serviceData[k])]) then
            table.remove(self.serviceData,k)
            if self.showerr then
                runGamePrompt({msg = "配置表异常3"})
            end
        elseif serviceTemp[tostring(self.serviceData[k])] then
            table.remove(self.serviceData,k)
            if self.showerr then
                runGamePrompt({msg = "配置表异常2"})
            end
        else
            serviceTemp[tostring(self.serviceData[k])] = 1  
        end
    end
    --
    self.showerr = false
    --

    self.myData = {}
    if self.auction and self.auction.items then
        for k,v in ipairs(self.localData) do
            if self.auction.items[tostring(v)] and self.auction.items[tostring(v)].my and self.auction.items[tostring(v)].my == 1 then
                table.insert(self.myData,v)
            end
        end
        for k,v in ipairs(self.serviceData) do
            if self.auction.items[tostring(v)] and self.auction.items[tostring(v)].my and self.auction.items[tostring(v)].my == 1 then
                table.insert(self.myData,v)
            end
        end
    end

    if self.show then
        if not self.localListTableView then
            self:createList("local")
        else
            self.localListTableView:reloadData()
        end
        if not self.serviceListTableView then
            self:createList("service")
        else
            self.serviceListTableView:reloadData()
        end
        if not self.myListTableView then
            self:createList("my")
        else
            self.myListTableView:reloadData()
        end
    else
        return
    end

    --
    UIRequest({type = 4814})
    --
    if self.auction.time and self.auction.time > 0 then
        gameTimer:rigistTime("auction_refresh", self.auction.time)
        gameTimer:rigistTimeFunc("auction_refresh",function()
            if gameTimer.times["auction_refresh"] <= 0 then
                if GameScene.layers["activity"].module.realPageTable[GameScene.layers["activity"].module.presentPage] and GameScene.layers["activity"].module.realPageTable[GameScene.layers["activity"].module.presentPage].id and GameScene.layers["activity"].module.realPageTable[GameScene.layers["activity"].module.presentPage].id == 65 then
                    UIRequest({type = 4810, update = true})
                end
                gameTimer:UnrigistTimeFunc("auction_refresh")
            end
        end)
    end

    if next(self.localData) or next(self.serviceData) then
        local auctiontime_open = gamedata.config.global_kv.auction_opentime and tostring(gamedata.config.global_kv.auction_opentime.value) or "0,0;"
        local auctiontime_over = gamedata.config.global_kv.auction_overtime and tostring(gamedata.config.global_kv.auction_overtime.value) or "24,0;"
        --
        local n_auctiontime_open = ui.getIDSFromStr(auctiontime_open)
        local n_auctiontime_over = ui.getIDSFromStr(auctiontime_over)

        if not self.show then return end

        if (nowtime.hour < n_auctiontime_open[1]) or ((nowtime.hour == n_auctiontime_open[1]) and (nowtime.min < n_auctiontime_open[2])) then
            self.isauctiontime_less = true
            self.isauctiontime_over = false
            self.rootItems.timeLab:setString(gameConfig.strings:string_common("auction",9))
            --
            local remaintime = n_auctiontime_open[1]*3600+n_auctiontime_open[2]*60-nowtime.hour*3600-nowtime.min*60-nowtime.sec+1
            gameTimer:rigistTime("auction_time", remaintime)
            gameTimer:rigistTimeFunc("auction_time",function()
                if gameTimer.times["auction_time"] >= 0 then
                    self.rootItems.time:setString(ui.makeTimeText(gameTimer.times["auction_time"],"hour"))
                end
                if gameTimer.times["auction_time"] <= 0 then
                    UIRequest({type = 4810})
                    gameTimer:UnrigistTimeFunc("auction_time")
                end
            end)
        elseif (nowtime.hour > n_auctiontime_over[1]) or ((nowtime.hour == n_auctiontime_over[1]) and (nowtime.min >= n_auctiontime_over[2])) then
            self.isauctiontime_less = false
            self.isauctiontime_over = true
            -- self.rootItems.timeLab:setString(gameConfig.strings:string_common("auction",8))
            -- self.rootItems.time:setString("")
            -- if gameTimer.times["auction_time"] then
            --     gameTimer:UnrigistTimeFunc("auction_time")
            -- end
            --
            self.rootItems.timeLab:setString(gameConfig.strings:string_common("auction",15))
            local remaintime = 24*3600-nowtime.hour*3600-nowtime.min*60-nowtime.sec
            gameTimer:rigistTime("auction_time", remaintime)
            gameTimer:rigistTimeFunc("auction_time",function()
                if gameTimer.times["auction_time"] >= 0 then
                    self.rootItems.time:setString(ui.makeTimeText(gameTimer.times["auction_time"],"hour"))
                end
                if gameTimer.times["auction_time"] <= 0 then
                    gameTimer:UnrigistTimeFunc("auction_time")
                end
            end)
        else
            self.isauctiontime_less = false
            self.isauctiontime_over = false
            self.rootItems.timeLab:setString(gameConfig.strings:string_common("auction",10))
            --
            local remaintime = n_auctiontime_over[1]*3600+n_auctiontime_over[2]*60-nowtime.hour*3600-nowtime.min*60-nowtime.sec
            gameTimer:rigistTime("auction_time", remaintime)
            gameTimer:rigistTimeFunc("auction_time",function()
                if gameTimer.times["auction_time"] >= 0 then
                    self.rootItems.time:setString(ui.makeTimeText(gameTimer.times["auction_time"],"hour"))
                end
                if gameTimer.times["auction_time"] <= 0 then
                    UIRequest({type = 4810})
                    gameTimer:UnrigistTimeFunc("auction_time")
                end
            end)
        end
    end

    if not next(self.localData) then
        for i = 1,7 do
            local nextwday = wday+i
            if nextwday > 7 then
                nextwday = nextwday-7
            end

            local config = gamedata.config["auction_pos_rc_"..self.auction.cpnum]
            local next_auction_pos = config and config[tostring(nextwday)] or {}
            if next_auction_pos.oneself and next_auction_pos.oneself ~= "" then
                if not self.show then return end
                self.rootItems.timeLab1:setString(gameConfig.strings:string_common("auction",7))
                self.rootItems.time1:setString(gameConfig.strings:string_common("auction",(nextwday <= wday) and 14 or 13)..gameConfig.strings:string_common("wdayNum",(nextwday > 6) and 1 or (nextwday+1)))
                break
            end
        end
    end

    if not next(self.serviceData) then
        for i = 1,7 do
            local nextwday = wday+i
            if nextwday > 7 then
                nextwday = nextwday-7
            end

            local config = gamedata.config["auction_pos_rc_"..self.auction.cpnum]
            local next_auction_pos = config and config[tostring(nextwday)] or {}
            if next_auction_pos.whole and next_auction_pos.whole ~= "" then
                if not self.show then return end
                self.rootItems.timeLab2:setString(gameConfig.strings:string_common("auction",7))
                self.rootItems.time2:setString(gameConfig.strings:string_common("auction",(nextwday <= wday) and 14 or 13)..gameConfig.strings:string_common("wdayNum",(nextwday > 6) and 1 or (nextwday+1)))
                break
            end
        end
    end

    if not self.show then return end
    --
    if self.isfirst then
        self.isfirst = false
        if next(self.serviceData) and not next(self.localData)  then
            self:shiftPage("service")
        else
            self:shiftPage(self.selectpage)
        end
    end
end


function auction.createList(self,listtype)

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
                cellCCB, ccbDocumentControler = CCBReaderLoad("paimaihang/cell_paimaihang", nil, true, "cell_paimaihang")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            --

            self:setAuction(ccbDocumentControler,self[listtype.."Data"][a1+1])
            --
            cellCCB:setPosition(self.normalCellSize.x/2, 0)

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self[listtype.."Data"])
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self[listtype.."ListTableView"] = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems[listtype.."Node"]:getContentSize().width,
        viewheight = self.rootItems[listtype.."Node"]:getContentSize().height,
        dire = 1
    })
    self.rootItems[listtype.."Node"]:addChild(self[listtype.."ListTableView"])
    self[listtype.."ListTableView"]:setTouchPriority(-101)
end

function auction.setAuction(self,item,id)

    local _config = gamedata.config["auction_items"]
    local config = _config and _config[tostring(id)] or {}
    if not config.reward then return end
    local reward = ui.getIDRandNum(config.reward)

    ui.setNewIcon(item,{cid = reward[1]})
    item["i_button"]:setTouchPriority(-102)
    item["i_button"]:setSwallowsTouch(true)
    item["i_button"]:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        if not self.isscrolltouched then return end
        ui.setPopwindowByCid(reward[1])
    end, CCControlEventTouchUpInside)

    item.name:setString(ui.IDconfig(reward[1]).name)
    item.num:setString(gameConfig.strings:string_common("general",12)..reward[2])

    ui.setLabelString(item.priceNum,config.maximum,14)

    ui.setLabelString(item.priceLab,nil,18)
    ui.setLabelString(item.auctionLab,nil,18)

    if self.auction and self.auction.items and self.auction.items[tostring(id)] then

        local auctionnum = config.initial or 0
        if self.auction.items[tostring(id)].num > auctionnum then
            auctionnum = self.auction.items[tostring(id)].num
        end
        ui.setLabelString(item.auctionNum,auctionnum,14)
        --
        if self.auction.items[tostring(id)].status == 3 then
            item.auctionsuccess:setVisible(true)
            item.hasauction:setVisible(false)
            item.priceNode:setVisible(false)
            item.auctionNode:setVisible(false)
            item.over:setVisible(true)
            item.notauction:setVisible(false)
        elseif self.auction.items[tostring(id)].status == 4 then
            item.auctionsuccess:setVisible(false)
            item.hasauction:setVisible(false)
            item.priceNode:setVisible(false)
            item.auctionNode:setVisible(false)
            item.over:setVisible(true)
            item.notauction:setVisible(false)
        else
            item.auctionsuccess:setVisible(false)
            --item.priceNode:setVisible(true)
            item.auctionNode:setVisible(true)
            item.over:setVisible(false)
            item.notauction:setVisible(false)
            if self.auction.items[tostring(id)].status == 1 then
                item.hasauction:setVisible(true)
            else
                item.hasauction:setVisible(false)
                if self.auction.items[tostring(id)].my == 1 then
                    item.notauction:setVisible(true)
                end
            end
            --
            if config.maximum and config.maximum > 0 then
                item.priceNode:setVisible(true)
            else
                item.priceNode:setVisible(false)
            end
            --
            item["priceButton"]:setTouchPriority(-102)
            item["priceButton"]:setSwallowsTouch(true)
            item["priceButton"]:addHandleOfControlEvent(function()
                if GameScene.layers["activity"].module.isContentScroll then  return end
                if not self.isscrolltouched then return end
                if self.isauctiontime_over then
                    runGamePrompt({msg = gameConfig.strings:string_common("auction",11)})
                elseif self.isauctiontime_less then
                    runGamePrompt({msg = gameConfig.strings:string_common("auction",12)})
                else
                    gameWindows:openWindow("auctionGet",{id = id, auction = auctionnum})
                end
            end, CCControlEventTouchUpInside)
            --
            item["auctionButton"]:setTouchPriority(-102)
            item["auctionButton"]:setSwallowsTouch(true)
            item["auctionButton"]:addHandleOfControlEvent(function()
                if GameScene.layers["activity"].module.isContentScroll then  return end
                if not self.isscrolltouched then return end
                if self.isauctiontime_over then
                    runGamePrompt({msg = gameConfig.strings:string_common("auction",11)})
                elseif self.isauctiontime_less then
                    runGamePrompt({msg = gameConfig.strings:string_common("auction",12)})
                elseif self.auction.items[tostring(id)].status == 1 then
                    runGamePrompt({msg = gameConfig.strings:string_common("auction",16)})
                else
                    gameWindows:openWindow("auctionNum",{id = id, auction = auctionnum})
                end
            end, CCControlEventTouchUpInside)

        end
    else
            
    end

end

function auction.openMessage(self,opentype)

    if opentype then
        self.messageopen = opentype
    elseif self.messageopen == "close" then
        self.messageopen = "open"
    else
        self.messageopen = "close"
    end

    if self.messageopen == "open" then
        self.animationManager:runAnimationsForSequenceNamed("open")
    else
        self.animationManager:runAnimationsForSequenceNamed("close")
    end

end


function auction.setMessage(self,data)
    local ss = ""
    if data then

        local _config = gamedata.config["auction_items"]
        local config = _config[tostring(data.s_id)] or {}
        ss = gameConfig.strings:auction_message(data.s_opt,config.name or "",config.num or 0,data.s_num,data.s_time)
    end
    return ss
end

function auction.ReloadMessage(self,data)

    if not (data and data.messages) then return end

    self.messageData = {}

    for i = 1,table.getTableLength(data.messages) do
       self.messageData[tostring(i)] = self:setMessage(data.messages[tostring(i)])
    end


    if self.rootItems then
        if not self.messageListTableView then
            self:createMessageList()
        else
            self.messageListTableView:reloadData()
            if self.messageListTableView:isTouchMoved() then

            else
                self.messageListTableView:setLuaContentOffset(0, self.rootItems.messageNode:getContentSize().height - table.getTableLength(self.messageData)*self.messageCellSize.y)
            end
        end
    end

end


function auction.createMessageList(self)

    local celldict = {}
    local unrecycleCell = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.messageCellSize.x, self.messageCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("paimaihang/cell_paimaihang_message", nil, true, "cell_paimaihang_message")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            --

            ui.setLabelString(ccbDocumentControler.message,self.messageData[tostring(a1+1)],14)
            --
            cellCCB:setPosition(self.messageCellSize.x/2, 0)

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.messageData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.messageListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.messageNode:getContentSize().width,
        viewheight = self.rootItems.messageNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.messageNode:addChild(self.messageListTableView)
    self.messageListTableView:setTouchPriority(-102)
end



function auction.UIUpdateData(self, isreset)
    if isreset then
        UIRequest({type = 4810})
    end
end

return auction


