--公会地鼠排行榜

local guardRank = {

    rootNode = nil,
    rootItems = nil,
    guildListTableView = nil,
    zoneListTableView = nil,
    selectpage = "guild",

    normalCellSize = {x=1080,y=210},
    guildData = {},
    zoneData = {},
    myGuildData = nil,
    myZoneData = nil,
    pageconfig = {"guild","zone"} ,
    pagename = {gameConfig.strings:string_common("guild_guard",13),gameConfig.strings:string_common("guild_guard",14)},
}

function guardRank.init(self,parent,toppos)
    self.rootNode,self.rootItems = CCBReaderLoad("gonghui2/gonghui_shouweirank", nil, true, "gonghui_shouweirank")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)
    self:initFixedString(self.rootItems)

    self.rootItems.topnode:setPositionY(toppos)

    self.rootItems.guildNode:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-640))
    self.rootItems.zoneNode:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-640))

    --返回
    self.rootItems.backBtn:setTouchPriority(-103)
    self.rootItems.backBtn:setSwallowsTouch(true)
    self.rootItems.backBtn:addHandleOfControlEvent(function()
        print("backbutton=")    
        gamedata.music:PlayOptSound("tuichu")
        GameScene:shiftLayer("gang_guard","up")
    end, CCControlEventTouchUpInside)

    self:shiftPage(self.selectpage)
end

function guardRank.clear(self)  
    self.guildListTableView = nil
    self.zoneListTableView = nil
    self.selectpage = "guild"
    self.myGuildData = nil
    self.myZoneData = nil
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.guildData = {}
    self.zoneData = {}
end

function guardRank.shiftPage(self,type)

    self.selectpage = type
    for k,v in ipairs(self.pageconfig)  do
        if v == type then
            self.rootItems[v.."Node"]:setPosition(ccp(0,430))
            self.rootItems[v.."Node"]:setVisible(true)
        else
            self.rootItems[v.."Node"]:setPosition(ccp(99999,0))
            self.rootItems[v.."Node"]:setVisible(false)
        end
    end

    if self.selectpage == "guild" then
        if not next(self.guildData) then
            print("guildData====")
            UIRequest({type = 5155,id = 0})
        else
            self:ReloadGuildData()
        end
    else
        if not next(self.zoneData) then
            print("zoneData====")
            UIRequest({type = 5155,id = 1})
        else
            self:ReloadZoneData()
        end
    end

end

function guardRank.setMyGuildRank(self)

    self.myguildRank = nil
    if not self.myguildRank then
        self.myguildRank = 0
        for k,v in pairs(self.guildData or {}) do
            if v.rid == self.myGuildData.rid then
                if (self.myguildRank == 0) or (self.myguildRank > tonumber(k)) then
                    self.myguildRank = tonumber(k)
                end
            end
        end
    end

    if self.myguildRank > 0 and self.myguildRank < 4 then
        setSpriteFrameByName(self.rootItems.top_rank,"b_n_zxt_"..(self.myguildRank))
        self.rootItems.rank:setString("")
        self.rootItems.norankspr:setVisible(false)
    elseif self.myguildRank >= 4 then
        setSpriteFrameByName(self.rootItems.top_rank,"alpha")
        self.rootItems.rank:setString(self.myguildRank)
        self.rootItems.norankspr:setVisible(false)
    elseif self.myguildRank == 0 then
        setSpriteFrameByName(self.rootItems.top_rank,"alpha")
        self.rootItems.rank:setString("")
        self.rootItems.norankspr:setVisible(true)
    end

    if self.rootItems.vipnode then
        self.rootItems.vipnode:setVisible(false)
        -- setSpriteFrameByName(self.rootItems.vip,"b_n_vip_"..(self.myGuildData.vip or 1))
    end


    for i=1,3 do 
        self.rootItems["rankReward"..i]:setVisible(false)
    end
    
    --self.rootItems.playerName:setString(self.myGuildData.name)
    ui.setLabelString(self.rootItems.playerName,self.myGuildData.name,14)

    ui.setLabelString(self.rootItems.playerScore,self.myGuildData.params["1"].i,14)

    --local profile = (self.myGuildData.profile) > 10100 and self.myGuildData.profile or 10101
    --ui.setUserProfile(self.rootItems,{cid = profile})
    --ui.setIconKuang(self.rootItems.i_k_quality,self.myGuildData.profile_k)
    ui.setNewIcon(self.rootItems,{cid = self.myGuildData.profile,title = self.myGuildData.title,iconBox = self.myGuildData.iconBox})

end

function guardRank.setMyZoneRank(self)
    self.myzoneRank = nil
    if not self.myzoneRank then
        --self.myZoneData
        if self.myZoneData and self.myZoneData.params and self.myZoneData.params["2"] and self.myZoneData.params["2"].i then
            self.myzoneRank = self.myZoneData.params["2"].i
        else
            self.myzoneRank = 0 
        end
        --self.myzoneRank = 0
        -- for k,v in pairs(self.zoneData or {}) do
        --     if v.rid == self.myZoneData.rid then
        --         if (self.myzoneRank == 0) or (self.myzoneRank > tonumber(k)) then
        --             self.myzoneRank = tonumber(k)
        --         end
        --     end
        -- end
    end

    if self.myzoneRank > 0 and self.myzoneRank < 4 then
        setSpriteFrameByName(self.rootItems.top_rank,"b_n_zxt_"..(self.myzoneRank))
        self.rootItems.rank:setString("")
        self.rootItems.norankspr:setVisible(false)
    elseif self.myzoneRank >= 4 then
        setSpriteFrameByName(self.rootItems.top_rank,"alpha")
        self.rootItems.rank:setString(self.myzoneRank)
        self.rootItems.norankspr:setVisible(false)
    elseif self.myzoneRank == 0 then
        setSpriteFrameByName(self.rootItems.top_rank,"alpha")
        self.rootItems.rank:setString("")
        self.rootItems.norankspr:setVisible(true)
    end


    --奖励
    local rankrewardIndex = 0
    local rankConfig = gamedata.config.guild_rank

    for i=1,table.getTableLength(rankConfig) do
        if rankConfig[tostring(i)] and rankConfig[tostring(i)].rank == (self.myzoneRank) then
            rankrewardIndex = i
            break
        else
            if rankConfig[tostring(i)] and rankConfig[tostring(i-1)] then
                if self.myzoneRank > rankConfig[tostring(i-1)].rank and self.myzoneRank < rankConfig[tostring(i)].rank then
                    rankrewardIndex = i
                    break
                end
            end
        end
    end

    if rankConfig[tostring(rankrewardIndex)] then
        local rewardTab = ui.getIDandNUMs(rankConfig[tostring(rankrewardIndex)].reward)
        for i=1,3 do
            if rewardTab[i] then
                self.rootItems["rankReward"..i]:setVisible(true)
                ui.setNewIcon(self.rootItems,{cid = rewardTab[i].cid,num =rewardTab[i].num,numStr = 1},i)
            else
                self.rootItems["rankReward"..i]:setVisible(false)
            end
        end
    else
        for i=1,3 do
            self.rootItems["rankReward"..i]:setVisible(false)
        end
    end

    if self.rootItems.vipnode then
        self.rootItems.vipnode:setVisible(false)
        -- setSpriteFrameByName(self.rootItems.vip,"b_n_vip_"..(self.myZoneData.vip or 1))
    end
    
    ui.setLabelString(self.rootItems.playerName,self.myZoneData.name,14)
    ui.setLabelString(self.rootItems.playerScore,self.myZoneData.params["1"].i,14)

--    local profile = (self.myZoneData.profile) > 10100 and self.myZoneData.profile or 10101
--    ui.setUserProfile(self.rootItems,{cid = profile})
--    ui.setIconKuang(self.rootItems.i_k_quality,self.myZoneData.profile_k)

    ui.setNewIcon(self.rootItems,{cid = self.myZoneData.profile,title = self.myZoneData.title,iconBox = self.myZoneData.iconBox})

end

function guardRank.ReloadGuildData(self,data)
    print("ReloadGuildData")


    if data then
        self.guildData = data.players
        self.myGuildData = data.myrank
    end

    if not self.guildListTableView then
        self:createGuildList()
    else
        self.guildListTableView:reloadData()
        
    end

    if self.myGuildData then
        self:setMyGuildRank()
    end
end


function guardRank.ReloadZoneData(self,data)
    print("ReloadZoneData")


    if data then
        self.zoneData = data.players
        self.myZoneData = data.myrank
    end

    if not self.zoneListTableView then
        self:createZoneList()
    else
        self.zoneListTableView:reloadData()
        
    end

    if self.myZoneData then
        self:setMyZoneRank()
    end

end


function guardRank.createGuildList(self)
    print("createGuildList")

    local celldict = {}
    local guildListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("gonghui2/cell_shouweirank", nil, true, "cell_shouweirank")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.guildListTableView,cellCCB,self.normalCellSize.x/2,0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local celldata = self.guildData[tostring(a1+1)]

            if a1+1 < 4 then
                setSpriteFrameByName(ccbDocumentControler.top_rank,"b_n_zxt_"..(a1+1))
                ccbDocumentControler.rank:setString("")

            else
                setSpriteFrameByName(ccbDocumentControler.top_rank,"alpha")
                ccbDocumentControler.rank:setString(a1+1)
            end

            -- setSpriteFrameByName(ccbDocumentControler.typesprite,"rank_"..self.selectpage)
            -- ui.setLabelString(ccbDocumentControler.type1,self.rankconfig[self.selectpage].typeext,23)                      
                   
            if ccbDocumentControler.vipnode then
                ccbDocumentControler.vipnode:setVisible(false)
                -- setSpriteFrameByName(ccbDocumentControler.vip,"b_n_vip_"..(celldata.vip or 1))
            end

            for i=1,3 do
                if ccbDocumentControler["rankReward"..i] then
                    ccbDocumentControler["rankReward"..i]:setVisible(false)
                end
            end

            --ui.setPlayername(ccbDocumentControler,celldata,14)
            ui.setLabelString(ccbDocumentControler.playerName,celldata.name,14)
            --ccbDocumentControler.playerName:setString(celldata.name)
            ui.setLabelString(ccbDocumentControler.playerScore,celldata.params["1"].i,14)

--            local profile = (celldata.profile) > 10100 and celldata.profile or 10101
--            ui.setUserProfile(ccbDocumentControler,{cid = profile})
--
--            ui.setIconKuang(ccbDocumentControler.i_k_quality,celldata.profile_k)

            ui.setNewIcon(ccbDocumentControler,{cid = celldata.profile,title = celldata.title,iconBox = celldata.iconBox})
                
            if self.guildListTableView then
                cellCCB:setPosition(self.normalCellSize.x/2, 0)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.guildData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.guildListTableView = ui.createLuaTableView({
        handle = guildListHandle,
        viewwidth = self.rootItems.guildNode:getContentSize().width,
        viewheight = self.rootItems.guildNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.guildNode:addChild(self.guildListTableView)
    self.guildListTableView:setTouchPriority(-101)
end



function guardRank.createZoneList(self)
    print("createzoneList")

    local celldict = {}
    local zoneListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("gonghui2/cell_shouweirank", nil, true, "cell_shouweirank")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.zoneListTableView,cellCCB,self.normalCellSize.x/2,0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local celldata = self.zoneData[tostring(a1+1)]

            if a1+1 < 4 then
                setSpriteFrameByName(ccbDocumentControler.top_rank,"b_n_zxt_"..(a1+1))
                ccbDocumentControler.rank:setString("")
            else
                setSpriteFrameByName(ccbDocumentControler.top_rank,"alpha")
                ccbDocumentControler.rank:setString(a1+1)
            end

            -- setSpriteFrameByName(ccbDocumentControler.typesprite,"rank_"..self.selectpage)
            -- ui.setLabelString(ccbDocumentControler.type1,self.rankconfig[self.selectpage].typeext,23)                      
                   
            if ccbDocumentControler.vipnode then
                --ccbDocumentControler.vipnode:setVisible(gameConfig:checkBuildOpen(154))
                ccbDocumentControler.vipnode:setVisible(false)
                -- setSpriteFrameByName(ccbDocumentControler.vip,"b_n_vip_"..(celldata.vip or 1))
            end

            --ui.setPlayername(ccbDocumentControler,celldata,14)
            --ccbDocumentControler.playerName:setString(celldata.name)
            ui.setLabelString(ccbDocumentControler.playerName,celldata.name,14)
            ui.setLabelString(ccbDocumentControler.playerScore,celldata.params["1"] and celldata.params["1"].i or 0,14)
--            local profile = (celldata.profile) > 10100 and celldata.profile or 10101
--            ui.setUserProfile(ccbDocumentControler,{cid = profile})
--
--            ui.setIconKuang(ccbDocumentControler.i_k_quality,celldata.profile_k)

            ui.setNewIcon(ccbDocumentControler,{cid = celldata.profile,title = celldata.title,iconBox = celldata.iconBox})

            --奖励
            local rankrewardIndex = 0
            local rankConfig = gamedata.config.guild_rank

            for i=1,table.getTableLength(rankConfig) do
                if rankConfig[tostring(i)] and rankConfig[tostring(i)].rank == (a1+1) then
                    rankrewardIndex = i
                    break
                else
                    if rankConfig[tostring(i)] and rankConfig[tostring(i-1)] then
                        if a1+1 > rankConfig[tostring(i-1)].rank and a1+1 < rankConfig[tostring(i)].rank then
                            rankrewardIndex = i
                            break
                        end
                    end
                end
            end

            if rankConfig[tostring(rankrewardIndex)] then
                local rewardTab = ui.getIDandNUMs(rankConfig[tostring(rankrewardIndex)].reward)
                for i=1,3 do
                    if rewardTab[i] then
                        ccbDocumentControler["rankReward"..i]:setVisible(true)
                        ui.setNewIcon(ccbDocumentControler,{cid = rewardTab[i].cid,num =rewardTab[i].num,numStr = 1},i)
                    else
                        ccbDocumentControler["rankReward"..i]:setVisible(false)
                    end
                end
            else
                for i=1,3 do
                    ccbDocumentControler["rankReward"..i]:setVisible(false)
                end
            end
                
            if self.zoneListTableView then
                cellCCB:setPosition(self.normalCellSize.x/2, 0)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.zoneData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.zoneListTableView = ui.createLuaTableView({
        handle = zoneListHandle,
        viewwidth = self.rootItems.zoneNode:getContentSize().width,
        viewheight = self.rootItems.zoneNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.zoneNode:addChild(self.zoneListTableView)
    self.zoneListTableView:setTouchPriority(-101)
end

function guardRank.initFixedString( self )
    -- ui.setLabelString(self.rootItems.fixedTitle,gameConfig.strings:string_common("guild_guard",15),16)
    -- ui.setLabelString(self.rootItems.fixedback,gameConfig.strings:string_common("guild_guard",6),16)
    ui.setLabelString(self.rootItems.fixedStr1,"排行奖励次日通过邮件发放",14)
    --ui.setLabelString(self.rootItems.fixedStr1,"开启当日24:00通过邮箱发放奖励",47)
end

return guardRank


