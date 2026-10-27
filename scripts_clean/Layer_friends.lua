--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-10-15
-- Time: 上午10:08
-- To change this template use File | Settings | File Templates.
--

local friends = {

    resource = nil,

    rootNode = nil,
    rootItems = nil,

    pageconfig = {"friend","recomend","req","shield"} ,
    -- pagename = {"当前好友","好友推荐","好友申请"},
    pagename = {gameConfig.strings:string_common("friends",0),gameConfig.strings:string_common("friends",1),
                gameConfig.strings:string_common("friends",2),gameConfig.strings:string_common("friends",27)},
    selectpage = "friend",


    friendListTableView = nil,
    reqListTableView = nil,
    recomendListTableView = nil,
    shieldListTableView = nil,

    data = nil,

    CellSize = {x=1080,y=242},
    detailCellSize = {x=1080,y=402},

    frinedData = nil,
    reqData = nil,
    recomendData = nil,
    shieldData = nil,

    shieldNetPause = nil, -- 动态刷新暂停

    shieldMaxNum = nil, -- 黑名单总数
    shieldIndexNow = nil, -- 下标判断刷新

    friendSelected = nil,

    unrecycleCell = {},

    hintconfig = {
        {
            name = "rootItems",
            type = "self",
            config = {
                title1 = {37},
                title3 = {127},
            },
        },
    }

}

function friends.shiftPage(self,type)
    self.selectpage = type
    self.rootItems.tipNode:setVisible(false)
    for k,v in ipairs(self.pageconfig) do
        if v == type then
            self.rootItems[v.."Node"]:setVisible(true)
            self.rootItems[v.."Node"]:setPosition(540,220)
        else
            self.rootItems[v.."Node"]:setVisible(false)
            self.rootItems[v.."Node"]:setPosition(9999,0)
        end
    end
    if self.selectpage == "friend" then
        if not self.frinedData or not next(self.frinedData) then
            UIRequest({type = 2300})
        elseif GameScene:checkhint(37) then
            UIRequest({type = 2300, param = 1})
        end
        self.rootItems.giftsTab:setVisible(true)  
        self.rootItems.sendtimes:setVisible(true)  
        self.rootItems.friendtips:setVisible(true)
        self.rootItems.shieldtips:setVisible(false)
        self.rootItems.friendNum:setVisible(true)
        self.rootItems.shieldNum:setVisible(false)
    elseif self.selectpage == "recomend" then
        if not self.recomendData or not next(self.recomendData) then
            UIRequest({type = 2301})
        end
        self.rootItems.giftsTab:setVisible(false)
        self.rootItems.sendtimes:setVisible(false)
        self.rootItems.friendtips:setVisible(true)
        self.rootItems.shieldtips:setVisible(false)
        self.rootItems.friendNum:setVisible(true)
        self.rootItems.shieldNum:setVisible(false)
    elseif self.selectpage == "req" then
        if not self.reqData or not next(self.reqData) or GameScene:checkhint(37) then
            UIRequest({type = 2303})
        end
        self.rootItems.giftsTab:setVisible(false)
        self.rootItems.sendtimes:setVisible(false)
        self.rootItems.friendtips:setVisible(true)
        self.rootItems.shieldtips:setVisible(false)
        self.rootItems.friendNum:setVisible(true)
        self.rootItems.shieldNum:setVisible(false)
    elseif self.selectpage == "shield" then
        if not self.shieldData or not next(self.shieldData) then
            UIRequest({type = 3002})
        end
        self.rootItems.giftsTab:setVisible(false)
        self.rootItems.sendtimes:setVisible(false)
        self.rootItems.friendtips:setVisible(false)
        self.rootItems.shieldtips:setVisible(true)
        self.rootItems.friendNum:setVisible(false)
        self.rootItems.shieldNum:setVisible(true)
    end

end

function friends.init(self,parent,toppos,data)
    self.rootNode,self.rootItems = CCBReaderLoad("friends/haoyou", nil, true, "haoyou")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.friendScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,(GameScene.topposY-1620)+1030))
    self.rootItems.reqScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,(GameScene.topposY-1620)+1030))
    self.rootItems.recomendScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,(GameScene.topposY-1620)+1030))
    self.rootItems.shieldScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,(GameScene.topposY-1620)+1030))

    ui.setLabelString(self.rootItems.myid,GameScene.roleinfo.showid or GameScene.roleinfo.id,14)

    -- ui.setLabelString(self.rootItems.sendAlltext,"一键送礼",18)
    ui.setLabelString(self.rootItems.sendAlltext,gameConfig.strings:string_common("friends",3),18)
    self.rootItems.sendAll:setSwallowsTouch(true)
    self.rootItems.sendAll:setTouchPriority(-111)
    self.rootItems.sendAll:addHandleOfControlEvent(function()
        local hassend = true
        for k,v in pairs(self.frinedData) do
            if v.sendgift == 0 then
                hassend = false
            end
        end
        if hassend then
            if self.frinedData and table.getTableLength(self.frinedData) > 0 then
                -- runGamePrompt({msg = "已全部送完"})
                runGamePrompt({msg = gameConfig.strings:string_common("friends",4)})
            else
                -- runGamePrompt({msg = "添加好友后才可以送礼"})
                runGamePrompt({msg = gameConfig.strings:string_common("friends",5)})
            end
        else
            UIRequest({type = 2308, ids = {}})
        end

    end, CCControlEventTouchUpInside)

    -- ui.setLabelString(self.rootItems.reciveAlltext,"一键收礼",18)
    ui.setLabelString(self.rootItems.reciveAlltext,gameConfig.strings:string_common("friends",6),18)
    self.rootItems.reciveAll:setSwallowsTouch(true)
    self.rootItems.reciveAll:setTouchPriority(-111)
    self.rootItems.reciveAll:addHandleOfControlEvent(function()
        local hasrecv = true
        for k,v in pairs(self.frinedData) do
            if v.recvgift == 1 then
                hasrecv = false
            end
        end
        if hasrecv then
            -- runGamePrompt({msg = "没有可领取的礼物"})
            runGamePrompt({msg = gameConfig.strings:string_common("friends",7)})
        else
            UIRequest({type = 2309, ids = {}})
        end
    end, CCControlEventTouchUpInside)

    -- ui.setLabelString(self.rootItems.refreshtext,"刷新好友",18)
    ui.setLabelString(self.rootItems.refreshtext,gameConfig.strings:string_common("friends",8),18)
    self.rootItems.refresh:setSwallowsTouch(true)
    self.rootItems.refresh:setTouchPriority(-111)
    self.rootItems.refresh:addHandleOfControlEvent(function()
        if gameTimer.times.friendrefresh and gameTimer.times.friendrefresh >0 then
            -- runGamePrompt({msg = "刷新过于频繁，请"..gameTimer.times.friendrefresh.."后刷新"})
            runGamePrompt({msg = gameConfig.strings:refreshTime(gameTimer.times.friendrefresh)})
        else
            gameTimer:rigistTime("friendrefresh",20)
            UIRequest({type = 2300, param = 1})
            UIRequest({type = 2301})
            UIRequest({type = 2303})
        end
    end, CCControlEventTouchUpInside)

    --ui.setLabelString(self.rootItems.findtext,"精确查找",18)
    ui.setLabelString(self.rootItems.findtext,gameConfig.strings:string_common("friends",9),18)
    self.rootItems.find:setSwallowsTouch(true)
    self.rootItems.find:setTouchPriority(-111)
    self.rootItems.find:addHandleOfControlEvent(function()
        gameWindows:openWindow("friend",{type = "find"},nil)
    end, CCControlEventTouchUpInside)

    --
    ui.setLabelString(self.rootItems.AllYesText,nil,18)
    self.rootItems.AllYes:setSwallowsTouch(true)
    self.rootItems.AllYes:setTouchPriority(-111)
    self.rootItems.AllYes:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        if self.reqData and next(self.reqData) then
            if self.frinedData and (table.getTableLength(self.frinedData) >= gamedata.config.vip[tostring(GameScene.vip.vip)].friend) then
                runGamePrompt({msg = "好友已满"})
            else
                UIRequest({type = 2311, opt = 1})
            end
        else
            runGamePrompt({msg = "没有好友申请"})
        end
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.AllNoText,gameConfig.strings:string_common("fixedString","friends",4),18)
    self.rootItems.AllNo:setSwallowsTouch(true)
    self.rootItems.AllNo:setTouchPriority(-111)
    self.rootItems.AllNo:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        if self.reqData and next(self.reqData) then
            UIRequest({type = 2311, opt = 2})
        else
            runGamePrompt({msg = "没有好友申请"})
        end
    end, CCControlEventTouchUpInside)

    --
    if self.rootItems.reset_find and self.rootItems.reset_findtext then
        ui.setLabelString(self.rootItems.reset_findtext,"换一批",18)
        self.rootItems.reset_find:setSwallowsTouch(true)
        self.rootItems.reset_find:setTouchPriority(-111)
        self.rootItems.reset_find:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            UIRequest({type = 2301, fresh = 1})
        end, CCControlEventTouchUpInside)
    end

    ui.setLabelString(self.rootItems.allBtntext,"一键申请",18)
    self.rootItems.allBtn:setSwallowsTouch(true)
    self.rootItems.allBtn:setTouchPriority(-111)
    self.rootItems.allBtn:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        if (table.getTableLength(self.frinedData) or 0) >= gamedata.config.vip[tostring(GameScene.vip.vip)].friend then
            runGamePrompt({msg = gameConfig.strings:string_common("friends",23)})
        elseif self.recomendData == nil or next(self.recomendData) == nil then
            runGamePrompt({msg = gameConfig.strings:string_common("friends",40)})
        else
            UIRequest({type = 6038})
        end
        
    end, CCControlEventTouchUpInside)

    --
    --
    if data then
        self.selectpage = data.curType
    end

    self:shiftPage(self.selectpage)
end

function friends.setfriendCell(self,data,items)
    printT(data,"setfriendCel====")
    --print(gamedata.config.general[tostring(data.profile)].icon)

    ui.setIconLv(items,{cid = data.profile,level = data.level,title = data.title,iconBox = data.iconBox})
    -- ui.setLabelString(items.name,data.name,48)
    
    -- 添加段位排名闪烁
    ui.setWudaoDuanweiRankEffect(items,data,0,37/34,48)


    items.power:setString(data.params["1"].i)
    -- items.gonghui:setString((data.params["2"].s and data.params["2"].s ~= "") and data.params["2"].s or "无")
    items.gonghui:setString((data.params["2"].s and data.params["2"].s ~= "") and data.params["2"].s or gameConfig.strings:string_common("moreCommon","wu"))

    --todo
    --part
    if items.duanNode then
        ui.setWudaoPart(items,data.part_point or 0)
    end

    if items.online then
        if data.params["3"].i then
            if  data.params["3"].i ==0 then
                -- items.online:setString("在线")
                items.online:setString(gameConfig.strings:string_common("friends",10))
            elseif  data.params["3"].i ==-1 then
                -- items.online:setString("很久未上线")
                items.online:setString(gameConfig.strings:string_common("friends",11))
            else
                items.online:setString( ui.makeTimeDes1(math.abs(data.params["3"].i)))
                -- items.online:setString(gameConfig.strings:lvTm(ui.makeTimeDes1(math.abs(data.params["3"].i))))
            end
        end
    end

end

function friends.setShieldCell(self,data,items)
    ui.setIconLv(items,{cid = data.profile or 0,level = data.level or 1,title = data.title or 0,iconBox = data.iconBox or 0})
    -- ui.setLabelString(items.name,data.name,48)
    -- printT(data,"setShieldCell===")

    items.power:setString(data.power or 0)
    items.gonghui:setString((data.gang_name and data.gang_name ~= "") and data.gang_name or gameConfig.strings:string_common("moreCommon","wu"))
    
    ui.setLabelString(items.buttontext,gameConfig.strings:string_common("friends",32),18)
    --todo
    --part
    -- if (data.rid < 1000000) or (math.floor(data.rid/1000000) == gameWindows.windows["roleinfo"].module.SelectedServer.id) then
        items.iscross:setVisible(false)
        items.duanNode:setVisible(true)
        -- 添加段位排名闪烁
        ui.setWudaoDuanweiRankEffect(items,data,0,37/34,48)
        ui.setWudaoPart(items,data.part_point or 0)
    -- else
    --     items.iscross:setVisible(true)
    --     items.duanNode:setVisible(false)
    --     -- 添加段位排名闪烁
    --     ui.setWudaoDuanweiRankEffect(items,data,0,37/34,48)
    --     ui.setWudaoPart(items,data.part_point or 0)
    -- end    
end

function friends.setfriendCellButton(self,data,items,index,isdetail)
    items.button2:setSwallowsTouch(true)
    items.button2:setTouchPriority(-102)
    items.button2:addHandleOfControlEvent(function() end, CCControlEventTouchUpInside)

    local send = data.sendgift
    local recv = data.recvgift
    items.buttonnode2:setVisible(true)

    if send == 0 then
        --ui.setLabelString(items.buttontext2,"送 礼",18)
        ui.setLabelString(items.buttontext2,gameConfig.strings:string_common("friends",14),18)
        items.button2:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            UIRequest({type = 2308, ids = {data.rid}})
        end, CCControlEventTouchUpInside)
    elseif recv == 1 then
        -- ui.setLabelString(items.buttontext2,"收 礼",18)
        ui.setLabelString(items.buttontext2,gameConfig.strings:string_common("friends",13),18)
        items.button2:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            UIRequest({type = 2309, ids = {data.rid}})
        end, CCControlEventTouchUpInside)
    else
        items.buttonnode2:setVisible(false)
    end

    items.showButton:setRotation(isdetail and 180 or 0)
    items.showButton:setTouchPriority(-104)
    items.showButton:setSwallowsTouch(true)
    items.showButton:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        local location
        self.friendSelected,location = ui.tableviewLocation(
            self.friendListTableView,
            table.getTableLength(self.frinedData),
            index,
            self.rootItems.friendScroll,
            self.friendSelected,
            self.detailCellSize.y,
            self.CellSize.y
        )
        self.friendListTableView:reloadData()
        self.friendListTableView:setLuaContentOffset(0,location)
    end, CCControlEventTouchUpInside)
end

function friends.setfriendCellDetail(self,data,items)
    items.deleteButton:setSwallowsTouch(true)
    items.deleteButton:setTouchPriority(-102)
    -- ui.setLabelString(items.deleteButtontext,"删 除",18)
    ui.setLabelString(items.deleteButtontext,gameConfig.strings:string_common("friends",16),18)
    items.deleteButton:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        local cb = function()
            UIRequest({type = 2310, ids = {data.rid}})
        end
        -- gameWindows:openWindow("confirm",{msg = "是否确认删除好友:"..data.name.."？"},cb)
        gameWindows:openWindow("confirm",{msg = gameConfig.strings:delFr(data.name)},cb)
    end, CCControlEventTouchUpInside)

    items.button1:setSwallowsTouch(true)
    items.button1:setTouchPriority(-102)
    -- ui.setLabelString(items.buttontext1,"查 看",18)
    ui.setLabelString(items.buttontext1,gameConfig.strings:string_common("friends",15),18)
    items.button1:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        GameScene:addtempLayers("other_slotinfo",data)
    end, CCControlEventTouchUpInside)

    items.chuanshuButton:setSwallowsTouch(true)
    items.chuanshuButton:setTouchPriority(-102)
    -- ui.setLabelString(items.chuanshuButtontext,"传 书",18)
    ui.setLabelString(items.chuanshuButtontext,gameConfig.strings:string_common("friends",17),18)
    items.chuanshuButton:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
            -- if (GameScene.roleinfo.vip == 1 and GameScene.roleinfo.level >= 19 and GameScene.roleinfo.power >= 100000) or (GameScene.roleinfo.vip > 1) then
            --     UIRequest({type = 2305, rid = data.rid,new = 0})
            -- else
            --     runGamePrompt({msg = "等级达到19级且战力大于10万或者vip2可私聊"})
            -- end

        local function req()
            UIRequest({type = 2305, rid = data.rid,new = 0})
        end

        local chat_vip = gamedata.config.global_kv.private_chat_vip and tonumber(gamedata.config.global_kv.private_chat_vip.value) or 0

        local chat_level = gamedata.config.global_kv.private_chat_level and tonumber(gamedata.config.global_kv.private_chat_level.value) or 0

        local chat_power = gamedata.config.global_kv.private_chat_power and tonumber(gamedata.config.global_kv.private_chat_power.value) or 0

        if chat_vip ~= -1 then
            if GameScene.roleinfo.vip >= chat_vip then req() return end
        end


        if chat_level ~= -1 then
            if GameScene.roleinfo.level >= chat_level then req() return end
        end
        
        if chat_power ~= -1 then
            if GameScene.roleinfo.power >= chat_power then req() return end
        end
        
        if GameScene.roleinfo.level < chat_level then
            if chat_vip ~= -1 and GameScene.roleinfo.vip < chat_vip then
                runGamePrompt({msg = "等级"..chat_level.."级或vip"..chat_vip.."可私聊"})
            else
                runGamePrompt({msg = "等级"..chat_level.."级可私聊"})
            end
            return
        end

        if GameScene.roleinfo.vip < chat_vip then
            runGamePrompt({msg = "贵族"..chat_vip.."可私聊"})
            return
        end


        if GameScene.roleinfo.power < chat_power then
            runGamePrompt({msg = "战力达到"..chat_power.."可私聊"})
            return
        end

        req()
        
    end, CCControlEventTouchUpInside)

    -- 切磋按钮
    ui.setLabelString(items.comparedText,gameConfig.strings:string_common("friends",33),18)
    
    items.comparedBtn:setSwallowsTouch(true)
    items.comparedBtn:setTouchPriority(-102)
    items.comparedBtn:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        UIRequest({type = 1022, rid = data.rid})
    end, CCControlEventTouchUpInside)
end

function friends.createFriendList(self)

    local celldict = {}
    --local unrecycleCell = {}
    local friendListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then

        elseif fn == "hasFixedCellSize" then
            r = false
        elseif fn == "cellSizeForIndex" then
            if self.friendSelected and self.friendSelected == a1+1 then
                r = CCSizeMake(self.detailCellSize.x, self.detailCellSize.y)
            else
                r = CCSizeMake(self.CellSize.x, self.CellSize.y)
            end
        elseif fn == "isRecycle" then
            for k,v in pairs (self.unrecycleCell) do
                if a2 == v.cell then
                    print("unrecycleCELL ")
                    return false
                end
            end
            return true
        elseif fn == "cellAtIndex" then

            if self.friendSelected and self.friendSelected == a1+1 then
                local ccb, items,ccb1, items1
                if self.unrecycleCell.detailCell == nil then
                    a2 = CCTableViewCell:create()
                    ccb, items =  CCBReaderLoad("friends/cell_haoyou_dangqian", nil, true, "cell_haoyou_dangqian")
                    ccb1, items1 =  CCBReaderLoad("friends/cell_haoyou_dangqian_pop", nil, true, "fcell_haoyou_dangqian_pop")

                    ccb1:setPosition(self.detailCellSize.x/2, -self.detailCellSize.y)
                    a2:addChild(ccb1)
                    ccb:setPosition(self.detailCellSize.x/2, -self.CellSize.y)
                    a2:addChild(ccb)

                    ui.tableviewAnimation(self.friendListTableView,ccb1,self.detailCellSize.x/2, -self.detailCellSize.y,a1)
                    ui.tableviewAnimation(self.friendListTableView,ccb,self.detailCellSize.x/2, -self.CellSize.y,a1)

                    self.unrecycleCell.detailCell={cell = a2, ccb =ccb, items=items,ccb1 =ccb1, items1=items1}
                    self.unrecycleCell.detailCell.cell:retain()
                else
                    a2 = self.unrecycleCell.detailCell.cell
                    ccb = self.unrecycleCell.detailCell.ccb
                    items = self.unrecycleCell.detailCell.items
                    ccb1 = self.unrecycleCell.detailCell.ccb1
                    items1 = self.unrecycleCell.detailCell.items1
                end

                self:setfriendCell(self.frinedData[tonumber(a1+1)],items)
                self:setfriendCellButton(self.frinedData[tonumber(a1+1)],items,a1+1,true)
                self:setfriendCellDetail(self.frinedData[tonumber(a1+1)],items1)
            else
                local cellCCB,ccbDocumentControler = 0,0
                local first = true
                if not a2 then
                    a2 = CCTableViewCell:create()
                    cellCCB, ccbDocumentControler = CCBReaderLoad("friends/cell_haoyou_dangqian", nil, true, "cell_haoyou_dangqian")
                    celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                    ui.tableviewAnimation(self.friendListTableView,cellCCB,self.CellSize.x/2, -self.CellSize.y,a1)
                else
                    first = false
                    cellCCB = celldict[a2].cellCCB
                    ccbDocumentControler = celldict[a2].ccbDocumentControler
                end

                self:setfriendCell(self.frinedData[tonumber(a1+1)],ccbDocumentControler)
                self:setfriendCellButton(self.frinedData[tonumber(a1+1)],ccbDocumentControler,a1+1)

                if self.friendListTableView then
                    cellCCB:setPosition(self.CellSize.x/2, -self.CellSize.y)
                end


                if first then
                    a2:addChild(cellCCB)
                end
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.frinedData)
        elseif fn == "cellTouched" then

--            local location
--            self.friendSelected,location = ui.tableviewLocation(
--                self.friendListTableView,
--                table.getTableLength(self.frinedData),
--                a1:getIdx()+1,
--                self.rootItems.friendScroll,
--                self.friendSelected,
--                self.detailCellSize.y,
--                self.CellSize.y
--            )
--            self.friendListTableView:reloadData()
--            self.friendListTableView:setLuaContentOffset(0,location)

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.friendListTableView = ui.createLuaTableView({
        handle = friendListHandle,
        viewwidth = self.rootItems.friendScroll:getContentSize().width,
        viewheight = self.rootItems.friendScroll:getContentSize().height,
        dire = 1
    })
    self.friendListTableView:setTouchPriority(-101)
    self.rootItems.friendScroll:addChild(self.friendListTableView)
end


function friends.reloadFriendList(self,data)
    self.max = data.max
    local oldnum = table.getTableLength(self.frinedData)
    local newnum = table.getTableLength(data.friends)

    self.frinedData = {}
    for k,v in pairs(data.friends) do
        if v.params["3"].i >= 0 then
            table.insert(self.frinedData,v)
        end
    end
    local sort = function(a,b)
        return a.params["3"].i < b.params["3"].i
    end
    table.sort(self.frinedData,sort)

    for k,v in pairs(data.friends) do
        if v.params["3"].i < 0 then
            table.insert(self.frinedData,v)
        end
    end

    if self.selectpage == "friend" and #self.frinedData == 0 then
        self.rootItems.tipNode:setVisible(true)
    end

    if not self.friendListTableView then
        self:createFriendList()

    else
        self.friendListTableView:reloadData()
        if  newnum ~= oldnum then
            self.friendListTableView:setLuaContentOffset(0, self.friendListTableView:getLuaContentOffsetY()+(oldnum-newnum)*self.CellSize.y+((oldnum>newnum and self.friendSelected and self.friendSelected >= oldnum) and 160 or 0))
            if (oldnum>newnum and self.friendSelected and self.friendSelected >= oldnum) then self.friendSelected = nil end
        end
    end

    ui.setLabelString(self.rootItems.friendNum,(table.getTableLength(self.frinedData) or 0).."/"..gamedata.config.vip[tostring(GameScene.vip.vip)].friend,14)

    ui.setLabelString(self.rootItems.sendtimes,self.max.."/"..tonumber(gamedata.config.global_kv.friend_reward_times.value),14)
end

function friends.createReqList(self)

    local celldict = {}
    local reqListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.CellSize.x, self.CellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("friends/cell_haoyou_shenqing.ccbi", nil, true, "cell_haoyou_shenqing")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.reqListTableView,cellCCB,self.CellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setfriendCell(self.reqData[tostring(a1+1)],ccbDocumentControler)

            local param = self.reqData[tostring(a1+1)].param

            ccbDocumentControler.button2:setTouchPriority(-102)
            ccbDocumentControler.button1:setTouchPriority(-102)

            if param == 2 then
                -- ccbDocumentControler.status:setString("已通过")
                ccbDocumentControler.status:setString(gameConfig.strings:string_common("friends",18))
                ccbDocumentControler.statusnode:setVisible(true)
                ccbDocumentControler.buttonnode1:setVisible(false)
                ccbDocumentControler.buttonnode2:setVisible(false)
            elseif param == 3 then
                ccbDocumentControler.statusnode:setVisible(false)
                ccbDocumentControler.buttonnode1:setVisible(true)
                ccbDocumentControler.buttonnode2:setVisible(true)

                -- ui.setLabelString(ccbDocumentControler.buttontext2,"同 意",18)
                ui.setLabelString(ccbDocumentControler.buttontext2,gameConfig.strings:string_common("moreCommon","tongyi"),18)
                ccbDocumentControler.button2:addHandleOfControlEvent(function()
                    if gameTouch.isScrollling then return end
                    -- runGamePrompt({msg = "好友已满！！"})
                    runGamePrompt({msg = gameConfig.strings:string_common("friends",19)})
                end, CCControlEventTouchUpInside)

                -- ui.setLabelString(ccbDocumentControler.buttontext1,"拒 绝",18)
                ui.setLabelString(ccbDocumentControler.buttontext1,gameConfig.strings:string_common("moreCommon","jujue"),18)
                ccbDocumentControler.button1:addHandleOfControlEvent(function()
                    if gameTouch.isScrollling then return end
                    UIRequest({type = 2304, ids = {self.reqData[tostring(a1+1)].rid,2}})
                end, CCControlEventTouchUpInside)
            elseif param == 4 then
                ccbDocumentControler.statusnode:setVisible(false)
                ccbDocumentControler.buttonnode1:setVisible(true)
                ccbDocumentControler.buttonnode2:setVisible(true)

                -- ui.setLabelString(ccbDocumentControler.buttontext2,"同 意",18)
                ui.setLabelString(ccbDocumentControler.buttontext2,gameConfig.strings:string_common("moreCommon","tongyi"),18)
                ccbDocumentControler.button2:addHandleOfControlEvent(function()
                    if gameTouch.isScrollling then return end
                    runGamePrompt({msg = gameConfig.strings:string_common("friends",20)})
                end, CCControlEventTouchUpInside)

                -- ui.setLabelString(ccbDocumentControler.buttontext1,"拒 绝",18)
                ui.setLabelString(ccbDocumentControler.buttontext1,gameConfig.strings:string_common("moreCommon","jujue"),18)
                ccbDocumentControler.button1:addHandleOfControlEvent(function()
                    if gameTouch.isScrollling then return end
                    UIRequest({type = 2304, ids = {self.reqData[tostring(a1+1)].rid,2}})
                end, CCControlEventTouchUpInside)
            elseif param == 9 then
                -- ccbDocumentControler.status:setString("已拒绝")
                ccbDocumentControler.status:setString(gameConfig.strings:string_common("moreCommon","yijujue"))
                ccbDocumentControler.statusnode:setVisible(true)
                ccbDocumentControler.buttonnode1:setVisible(false)
                ccbDocumentControler.buttonnode2:setVisible(false)
            else
                ccbDocumentControler.statusnode:setVisible(false)
                ccbDocumentControler.buttonnode1:setVisible(true)
                ccbDocumentControler.buttonnode2:setVisible(true)

                -- ui.setLabelString(ccbDocumentControler.buttontext2,"同 意",18)
                ui.setLabelString(ccbDocumentControler.buttontext2,gameConfig.strings:string_common("moreCommon","tongyi"),18)
                ccbDocumentControler.button2:addHandleOfControlEvent(function()
                    if gameTouch.isScrollling then return end
                    UIRequest({type = 2304, ids = {self.reqData[tostring(a1+1)].rid,1}})
                end, CCControlEventTouchUpInside)


                -- ui.setLabelString(ccbDocumentControler.buttontext1,"拒 绝",18)
                ui.setLabelString(ccbDocumentControler.buttontext1,gameConfig.strings:string_common("moreCommon","jujue"),18)
                ccbDocumentControler.button1:addHandleOfControlEvent(function()
                    if gameTouch.isScrollling then return end
                    UIRequest({type = 2304, ids = {self.reqData[tostring(a1+1)].rid,2}})
                end, CCControlEventTouchUpInside)
            end

            if self.reqListTableView then
                cellCCB:setPosition(self.CellSize.x/2, 0)
            end


            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.reqData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.reqListTableView = ui.createLuaTableView({
        handle = reqListHandle,
        viewwidth = self.rootItems.reqScroll:getContentSize().width,
        viewheight = self.rootItems.reqScroll:getContentSize().height,
        dire = 1
    })
    self.reqListTableView:setTouchPriority(-101)
    self.rootItems.reqScroll:addChild(self.reqListTableView)
end

function friends.reloadReqList(self,data)
    self.reqData = data.players


    if self.selectpage == "req" and table.getTableLength(self.reqData) == 0 then
        self.rootItems.tipNode:setVisible(true)
    end

    if not self.reqListTableView then
        self:createReqList()
    else
        --if self.reqListTableView:getLuaContentOffsetY() < self.rootItems.reqScroll:getContentSize().height - table.getTableLength(self.reqData)*self.CellSize.y then
            self.reqListTableView:setLuaContentOffset(0, self.rootItems.reqScroll:getContentSize().height - table.getTableLength(self.reqData)*self.CellSize.y)
        --end
        self.reqListTableView:reloadData()
    end

    --
    if self.reqData and next(self.reqData) then
        ui.removeGray("CCControlButton",self.rootItems.AllNo)
        ui.removeGray("CCLabelTTF",self.rootItems.AllNoText)
        if self.frinedData and (table.getTableLength(self.frinedData) >= gamedata.config.vip[tostring(GameScene.vip.vip)].friend) then
            ui.addGray("CCControlButton",self.rootItems.AllYes)
            ui.addGray("CCLabelTTF",self.rootItems.AllYesText)
        else
            ui.removeGray("CCControlButton",self.rootItems.AllYes)
            ui.removeGray("CCLabelTTF",self.rootItems.AllYesText)
        end
    else
        ui.addGray("CCControlButton",self.rootItems.AllYes)
        ui.addGray("CCLabelTTF",self.rootItems.AllYesText)
        ui.addGray("CCControlButton",self.rootItems.AllNo)
        ui.addGray("CCLabelTTF",self.rootItems.AllNoText)
    end
    ui.setLabelString(self.rootItems.friendNum,(table.getTableLength(self.frinedData) or 0).."/"..gamedata.config.vip[tostring(GameScene.vip.vip)].friend,14)
end

function friends.createRecomendList(self)
    local celldict = {}
    local recomendListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.CellSize.x, self.CellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("friends/cell_haoyou_tuijian.ccbi", nil, true, "cell_haoyou_tuijian")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.recomendListTableView,cellCCB,self.CellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setfriendCell(self.recomendData[tostring(a1+1)],ccbDocumentControler)

            local param = self.recomendData[tostring(a1+1)].param
            ccbDocumentControler.button:setTouchPriority(-102)

            if param == 1 then
                -- ccbDocumentControler.status:setString("已申请")
                ccbDocumentControler.status:setString(gameConfig.strings:string_common("moreCommon","yishenqing"))
                ccbDocumentControler.hasreq:setVisible(true)
                ccbDocumentControler.buttonnode:setVisible(false)
            elseif param == 2 then
                -- ccbDocumentControler.status:setString("已通过")
                ccbDocumentControler.status:setString(gameConfig.strings:string_common("moreCommon","yitongguo"))
                ccbDocumentControler.hasreq:setVisible(true)
                ccbDocumentControler.buttonnode:setVisible(false)
            elseif param == 3 then
                ccbDocumentControler.hasreq:setVisible(false)
                ccbDocumentControler.buttonnode:setVisible(true)

                -- ui.setLabelString(ccbDocumentControler.buttontext,"申 请",18)
                ui.setLabelString(ccbDocumentControler.buttontext,gameConfig.strings:string_common("moreCommon","shenqing"),18)
                ccbDocumentControler.button:addHandleOfControlEvent(function()
                    if gameTouch.isScrollling then return end
                    -- runGamePrompt({msg = "好友已满！！"})
                    runGamePrompt({msg = gameConfig.strings:string_common("friends",19)})
                end, CCControlEventTouchUpInside)
            elseif param == 4 then
                ccbDocumentControler.hasreq:setVisible(false)
                ccbDocumentControler.buttonnode:setVisible(true)

                -- ui.setLabelString(ccbDocumentControler.buttontext,"申 请",18)
                ui.setLabelString(ccbDocumentControler.buttontext,gameConfig.strings:string_common("moreCommon","shenqing"),18)
                ccbDocumentControler.button:addHandleOfControlEvent(function()
                    if gameTouch.isScrollling then return end
                    -- runGamePrompt({msg = "对方好友已满！！"})
                    runGamePrompt({msg = gameConfig.strings:string_common("friends",20)})
                end, CCControlEventTouchUpInside)
            elseif param == 9 then
                -- ccbDocumentControler.status:setString("被拒绝")
                ccbDocumentControler.status:setString(gameConfig.strings:string_common("moreCommon","beijujue"))
                ccbDocumentControler.hasreq:setVisible(true)
                ccbDocumentControler.buttonnode:setVisible(false)
            else

                ccbDocumentControler.hasreq:setVisible(false)
                ccbDocumentControler.buttonnode:setVisible(true)
                -- ui.setLabelString(ccbDocumentControler.buttontext,"申 请",18)
                ui.setLabelString(ccbDocumentControler.buttontext,gameConfig.strings:string_common("moreCommon","shenqing"),18)
                ccbDocumentControler.button:addHandleOfControlEvent(function()
                    if gameTouch.isScrollling then return end
                    UIRequest({type = 2302, ids = {self.recomendData[tostring(a1+1)].rid}})
                end, CCControlEventTouchUpInside)
            end

            if self.recomendListTableView then
                cellCCB:setPosition(self.CellSize.x/2, 0)
            end
            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.recomendData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.recomendListTableView = ui.createLuaTableView({
        handle = recomendListHandle,
        viewwidth = self.rootItems.recomendScroll:getContentSize().width,
        viewheight = self.rootItems.recomendScroll:getContentSize().height,
        dire = 1
    })
    self.recomendListTableView:setTouchPriority(-101)
    self.rootItems.recomendScroll:addChild(self.recomendListTableView)
end

function friends.reloadRecomendList(self,data)
    local oldCellNum = 0
    if self.recomendData ~= nil then
        oldCellNum = table.getTableLength(self.recomendData)
    end
    self.recomendData = data.players

    if self.selectpage == "recomend" and table.getTableLength(self.recomendData) == 0 then
        self.rootItems.tipNode:setVisible(true)
    end

    if not self.recomendListTableView then
        self:createRecomendList()
    else
        self.recomendListTableView:reloadData()
        if -1 * self.recomendListTableView:getLuaContentOffsetY() > self.recomendListTableView:getContentSize().height then
            self.recomendListTableView:setLuaContentOffset(0, self.recomendListTableView:getLuaContentOffsetY() - (table.getTableLength(self.recomendData) - oldCellNum )*self.CellSize.y)
        end
    end
    ui.setLabelString(self.rootItems.friendNum,(table.getTableLength(self.frinedData) or 0).."/"..gamedata.config.vip[tostring(GameScene.vip.vip)].friend,14)
end

function friends.createShieldList(self)
    local celldict = {}
    local shieldListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.CellSize.x, self.CellSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("friends/cell_haoyou_shield.ccbi", nil, true, "cell_haoyou_shield")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.shieldListTableView,cellCCB,self.CellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setShieldCell(self.shieldData[tostring(a1+1)],ccbDocumentControler)

            ccbDocumentControler.button:setTouchPriority(-102)
            ccbDocumentControler.button:addHandleOfControlEvent(function()
                    if gameTouch.isScrollling then return end
                    UIRequest({type = 3004, ids = {self.shieldData[tostring(a1+1)].rid}})
            end, CCControlEventTouchUpInside)

            if self.shieldListTableView then
                cellCCB:setPosition(self.CellSize.x/2, 0)
                local tmpDataLens = table.getTableLength(self.shieldData)
                if a1 == tmpDataLens - 1 and self.shieldMaxNum > tmpDataLens then
                    if not self.shieldNetPause then
                        self.shieldIndexNow = self.shieldListTableView:getLuaContentOffsetY()
                        self.shieldNetPause = true
                        UIRequest({type = 3002})
                    end
                end
            end
            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.shieldData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.shieldListTableView = ui.createLuaTableView({
        handle = shieldListHandle,
        viewwidth = self.rootItems.shieldScroll:getContentSize().width,
        viewheight = self.rootItems.shieldScroll:getContentSize().height,
        dire = 1
    })
    self.shieldListTableView:setTouchPriority(-101)
    self.rootItems.shieldScroll:addChild(self.shieldListTableView)
end

function friends.reloadShieldList(self,data)
    self.shieldData = data.players
    self.shieldMaxNum = data.max
    -- printT(data.players)

    if self.selectpage == "shield" and table.getTableLength(self.shieldData) == 0 then
        self.rootItems.tipNode:setVisible(true)
    end
    
    if not self.shieldListTableView then
        self:createShieldList()
    else
        local tmpOldHeight = self.shieldListTableView:getContainer():getContentSize().height 
        self.shieldListTableView:reloadData()
        if self.shieldNetPause then
            self.shieldNetPause = false
            local tmpHeight = self.shieldListTableView:getContainer():getContentSize().height 
            local tmpOffIndex = tmpHeight - tmpOldHeight - self.shieldIndexNow
            self.shieldListTableView:setLuaContentOffset(0,-tmpOffIndex )
        else
            local tmpOffY = self.shieldListTableView:getLuaContentOffsetY()
            local tmpHeight = self.shieldListTableView:getContentSize().height 
            self.shieldListTableView:setLuaContentOffset(0,tmpHeight - (table.getTableLength(self.shieldData) )*self.CellSize.y)
        end
    end
    ui.setLabelString(self.rootItems.shieldNum,(data.max or 0).."/".."9999",14)

end

function friends.clear(self)
    if self.unrecycleCell.detailCell then
        self.unrecycleCell.detailCell.cell:release()
    end
    self.unrecycleCell = {}
    self.frinedData = nil
    self.reqData = nil
    self.recomendData = nil
    self.shieldData = nil

    self.friendListTableView = nil
    self.reqListTableView = nil
    self.recomendListTableView = nil
    self.shieldListTableView = nil
    self.selectpage = "friend"
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function friends.setOnlineButtonIsShow(self,isShow )
    -- body
end

function friends.UIUpdateData(self, isreset)
    if isreset then
        self:shiftPage(self.selectpage)
    end
end


return friends