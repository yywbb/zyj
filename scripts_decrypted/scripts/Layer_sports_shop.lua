--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-23
-- Time: 下午3:17
-- To change this template use File | Settings | File Templates.
--

local sports = {
    rewardCellSize = {x=1080, y=280},

    resource = nil,

    rootNode = nil,
    rootItems = nil,
    rewardListTableView = nil,

    rewardData = nil,
    myData = nil,

}

-- function sports.init(self,parent,toppos)
function sports.init(self,size)
    self.contentsize = size
    self.show = true

    self.rootNode,self.rootItems = CCBReaderLoad("tanchuang/sports_shop", nil, true, "sports_shop")

    -- self.rootNode:setPosition(-540,0)
    -- parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(self.contentsize.y-180)

    self.rootItems.rewardScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-520-462))


    -- self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    -- self.rootItems.scrollnode:setTouchPriority(-103)
    -- -- self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,0),0)

    -- self.rootItems.scrollnode:setViewSize(CCSizeMake(gameConfig.originSize.width,toppos-180-500-180))

    -- self.rootItems.container:setContentSize(CCSize(1080,1000))

    -- self.scrollNode, self.scrollItems = CCBReaderLoad("tanchuang/map5", nil, true, "map5")
    -- self.scrollNode:setPosition(0,0)
    -- -- self.scrollNode:setVisible(false)
    -- self.rootItems.container:addChild(self.scrollNode)

    -- self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,toppos-180-500-180 - 1000),0)

    -- self.rootItems.scrollnode_touch:setContentSize(CCSize(gameConfig.originSize.width,toppos-180-500-180))

    -- UIRequest({type =1610})


    -- self:shiftPage(self.selectpage)


    -- ui.setLabelString(self.rootItems.descText,nil,13)
    -- ui.setLabelString(self.rootItems.ownprestigeText,nil,150)
    -- ui.setLabelString(self.rootItems.ownprestige,nil,150)

    --去竞技场链接
    
    ui.setLabelString(self.rootItems.gotoSportsText,nil,18)
    self.rootItems.gotoSportsBtn:setTouchPriority(-102)
    self.rootItems.gotoSportsBtn:setSwallowsTouch(true)
    self.rootItems.gotoSportsBtn:addHandleOfControlEvent(function()
        -- GameScene:shiftLayer("gang_main","up")
        GameScene:shiftLayerById(23)
    end,CCControlEventTouchUpInside)

    
    
    --
    --UIRequest({type = 1610})
--    UIRequest({type = 1607})

    return self.rootNode
end

function sports.reloadData(self, data)
    rankData = data.ranklist
    top10Data = data.top10
    myData = data.my
    athletics_boss = data.athletics_boss
    
    print("sports.reloadrank==")
    if not self.show then return end
    
    -- if rankData then
    --     self.rankData = rankData
    -- end
    -- if top10Data then
    --     self.top10Data = top10Data
    -- end
    if myData then
        self.myData = myData
    else
        return
    end
    -- if athletics_boss then
    --     self.athletics_boss = athletics_boss
    -- end
    --
    -- self.rootItems.ownprestige:setString(self.myData.prestige)
    -- ui.setLabelString(self.rootItems.ownprestige,self.myData.prestige,21)
    self.rootItems.ownprestige:setString(self.myData.prestige)

    UIRequest({type = 1613})
end

function sports.reloadRewards(self,rewardData)
    print("sports.reloadrank== not")
    if not self.show then return end
    print("sports.reloadrank== is")
    if rewardData then
        self.rewardData = {}
        local _count = 0

        for i = 1, table.getTableLength(rewardData) do
            if gamedata.config.athletics_rewards2[tostring(i)].display_level == 0 or GameScene.roleinfo.level >= gamedata.config.athletics_rewards2[tostring(i)].display_level then
                _count = _count + 1
                self.rewardData[_count] = rewardData[tostring(i)]
                self.rewardData[_count].priority = gamedata.config.athletics_rewards2[tostring(i)].priority
                local config = gamedata.config.athletics_rewards2[tostring(i)]

                if config.lv and config.lv > 0 then
                    if GameScene.roleinfo.level >= config.lv then
                        self.rewardData[_count].tempSort = 1000 +self.rewardData[_count].priority
                    else
                        self.rewardData[_count].tempSort = self.rewardData[_count].priority
                    end
                else
                    self.rewardData[_count].tempSort = 1000 + self.rewardData[_count].priority
                end
            end
        end

        local _sortTable = function(left, right)
            return left.tempSort > right.tempSort
        end

        table.sort(self.rewardData, _sortTable)
    end

    if not self.rewardListTableView then
        self:createRewardList()
    else
        if self.rewardListTableView:getLuaContentOffsetY() < self.rootItems.rewardScroll:getContentSize().height - table.getTableLength(self.rewardData)*self.rewardCellSize.y then
            self.rewardListTableView:setLuaContentOffset(0, self.rootItems.rewardScroll:getContentSize().height - table.getTableLength(self.rewardData)*self.rewardCellSize.y)
        end
        self.rewardListTableView:reloadData()
    end

    -- for i=1, 6 do
    --     self:setone(self.scrollItems, self.rewardData[tostring(i)], i)
    -- end
end

function sports.createRewardList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("tanchuang/cell_sports_shop2.ccbi", nil, true, "cell_sports_shop")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                --ui.tableviewAnimation(self.rewardListTableView,cellCCB,self.rewardCellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            if self.rewardData[(a1+1)*2-1] then
                ccbDocumentControler.propnode1:setVisible(true)
                self:setone(self.rewardData[(a1+1)*2-1],ccbDocumentControler,1)
            else
                ccbDocumentControler.propnode1:setVisible(false)
            end
            if self.rewardData[(a1+1)*2] then
                ccbDocumentControler.propnode2:setVisible(true)
                self:setone(self.rewardData[(a1+1)*2],ccbDocumentControler,2)
            else
                ccbDocumentControler.propnode2:setVisible(false)
            end
            --if self.rewardListTableView then
                cellCCB:setPosition(self.rewardCellSize.x/2, -8)
            --end

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

    self.rewardListTableView = ui.createLuaTableView({
        handle = rankListHandle,
        viewwidth = self.rootItems.rewardScroll:getContentSize().width,
        viewheight = self.rootItems.rewardScroll:getContentSize().height,
        dire = 1
    })
    self.rewardListTableView:setTouchPriority(-101)
    self.rootItems.rewardScroll:addChild(self.rewardListTableView)
end


function sports.setone(self,data,items,index)
    print("sports.index==",index)
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

    local config = gamedata.config.athletics_rewards2[tostring(data.id)]
    print("i..config...:")
    -- printT(config)
    if not config  then
        print("notid===",data.id)
        return
    end
    -- printT(items,"items===")
    print(key_Ex)
    if (config.buttontype == 1) and (config.limit and config.limit > 0) then
        -- ui.setLabelString(items["desc"..key_Ex], gameConfig.strings:string_common("sports",22), 14)
        -- ui.setLabelString(items["desc2"..key_Ex], gameConfig.strings:string_common("sports",23), 14)
        
        if data.status == -1 then
            -- ui.setLabelString(items["desc1"..key_Ex], config.limit, 136)
            items["desc"..key_Ex]:setString(gameConfig.strings:string_common("sports",22)..config.limit)
        else
            if config.limit - data.status > 0 then
                -- ui.setLabelString(items["desc1"..key_Ex], config.limit-data.status, 136)
                items["desc"..key_Ex]:setString(gameConfig.strings:string_common("sports",22)..config.limit-data.status)
            else
                -- ui.setLabelString(items["desc1"..key_Ex], 0, 135)
                items["desc"..key_Ex]:setString(gameConfig.strings:string_common("sports",22).."0")
            end
        end
    else
        -- ui.setLabelString(items["desc"..key_Ex], "", 14)
        items["desc"..key_Ex]:setString("")
        ui.setLabelString(items["desc1"..key_Ex], "", 14)
        ui.setLabelString(items["desc2"..key_Ex], "", 14)
    end

    -- local _list = {}
    -- table.insert(_list, {node = items["desc"..key_Ex]})
    -- table.insert(_list, {node = items["desc1"..key_Ex]})
    -- table.insert(_list, {node = items["desc2"..key_Ex]})
    -- ui.setCCNodeListRight(_list)

    if config.lv and config.lv > 0 then

        -- ui.setLabelString(items["needlv"..key_Ex],gameConfig.strings:string_common("sports",20),13)
        items["needlv"..key_Ex]:setString(gameConfig.strings:string_common("sports",20))
        if GameScene.roleinfo.level >= config.lv then
            -- ui.setLabelString(items["needlv2"..key_Ex],config.lv,26)
            items["needlv2"..key_Ex]:setString(config.lv)
            items["shadowNode"..key_Ex]:setVisible(false)
        else
            -- ui.setLabelString(items["needlv2"..key_Ex],config.lv,24)
            items["needlv2"..key_Ex]:setString(config.lv)
            items["shadowNode"..key_Ex]:setVisible(true)
        end
    else
        -- ui.setLabelString(items["needlv"..key_Ex],"",13)
        -- ui.setLabelString(items["needlv2"..key_Ex],"",13)
        items["needlv"..key_Ex]:setString("")
        items["needlv2"..key_Ex]:setString("")
        items["shadowNode"..key_Ex]:setVisible(false)
    end
    --
    if config.buttontype == 1 then
        if config.rank == 0 then
            items["buynum"..key_Ex]:setVisible(false)
            items["buynumText"..key_Ex]:setVisible(false)
        else
            items["buynum"..key_Ex]:setVisible(true)
            items["buynumText"..key_Ex]:setVisible(true)
            items["buynum"..key_Ex]:setString(config.rank)
        end
        -- items.desc:setString(gameConfig.strings:string_common("sports",9))
        items["prestige"..key_Ex]:setString(config.prestige)
        items["prestigeSprite"..key_Ex]:setVisible(true)
        setControlButtonFrame(items["exchange"..key_Ex],"b_s_button2","b_s_button2_h","b_s_button2")

        if self.myData.prestige >= config.prestige then
            ui.setLabelString(items["prestige"..key_Ex],nil,26)
        else
            ui.setLabelString(items["prestige"..key_Ex],nil,12)
        end
    else
        -- items.desc:setString("需要达到排名")
        -- items.desc:setString(gameConfig.strings:string_common("sports",10))
        items["prestige"..key_Ex]:setString(config.rank)
        items["prestigeSprite"..key_Ex]:setVisible(false)
        setControlButtonFrame(items["exchange"..key_Ex],"b_s_button1","b_s_button1_h","b_s_button1")
        ui.setLabelString(items["prestige"..key_Ex],nil,13)
    end
    
    ui.setLabelString(items["prestigeText"..key_Ex],nil,13)
    

    local id,num = ui.getIDandNUM(config.reward)

    local propConfig =  ui.IDconfig(id)

    items["propname"..key_Ex]:setString(config.name)
    ui.setLabelString(items["propname"..key_Ex],nil,(propConfig.quality>1 and propConfig.quality or 1)*2-1)

    ui.setNewIcon(items,{cid = id, num = num},index-1)
    --
    items["i_button"..icon_key]:addHandleOfControlEvent(function()
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
        gameTouch:clickprofbytime(0.5)
        if config.lv and config.lv > GameScene.roleinfo.level then
            runGamePrompt({msg = config.lv..gameConfig.strings:string_common("sports",24)})
        elseif (config.buttontype == 1) and (config.limit and config.limit > 0) and (data.status >= config.limit) then
            -- runGamePrompt({msg = "超出兑换次数限制"})
            runGamePrompt({msg = gameConfig.strings:string_common("sports",12)})
        elseif (config.buttontype == 1) and (self.myData.prestige < config.prestige) then
            -- runGamePrompt({msg = "积分不足"})
            runGamePrompt({msg = gameConfig.strings:string_common("sports",11)})
        elseif (config.buttontype == 2) and (data.status < 2) then
            -- runGamePrompt({msg = "未达到领取条件"})
            runGamePrompt({msg = gameConfig.strings:string_common("sports",13)})
        else
            --UIRequest({type = 1614, id = data.id}
            function shopExchangeRequest(num)
                if (config.buttontype == 1) and (self.myData.prestige < config.prestige*num) then
                    runGamePrompt({msg = gameConfig.strings:string_common("sports",11)})
                else
                    UIRequest({type = 1614, id = data.id,num = num})
                end
            end
            local exchangeNum
            if data.status == -1 then
                exchangeNum = config.limit
            else
                exchangeNum = config.limit-data.status
            end
            local cost = {}
            cost[1] = {}
            cost[1].cid = 1005
            cost[1].num =config.prestige

            if exchangeNum > 5 then 
                gameWindows:openWindow("shopExchange",{cid = id,num = num,cost = cost,exchangeNum = exchangeNum},shopExchangeRequest)
            else
                UIRequest({type = 1614, id = data.id,num = 1})
            end
       
        end

    end, CCControlEventTouchUpInside)

    -- print("sportsnum===",config.buttontype,self.myData.prestige,config.prestige)
    -- printT(data,"data===sports")
    -- if (config.buttontype == 1) and (self.myData.prestige < config.prestige) then
    --     -- ui.addGray("CCControlButton",items["exchange"..key_Ex])
    --     -- ui.addGray("CCLabelTTF",items["exchangeText"..key_Ex])
    -- elseif (config.buttontype == 1) and (config.limit and config.limit > 0) and (data.status >= config.limit) then
    if (config.buttontype == 1) and (config.limit and config.limit > 0) and (data.status >= config.limit) then
        ui.addGray("CCControlButton",items["exchange"..key_Ex])
        ui.addGray("CCLabelTTF",items["exchangeText"..key_Ex])
    elseif (config.buttontype == 2) and (data.status < 2) then
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



function sports.clear(self)
    self.show = false

    self.rewardData = nil
    self.myData = nil

    self.rewardListTableView = nil

    if self.rootNode then
        self.rootNode:removeAllChildrenWithCleanup(true)
        self.rootNode:removeFromParentAndCleanup(true)
        self.rootNode = nil
        self.rootItems = nil
    end
    
end

function sports.UIUpdateData(self, isreset)
    if isreset then
        UIRequest({type = 1613})
        --self:shiftPage(self.selectpage)
    end
end


return sports C  