--


local gangbossrank = {

    resource = nil,

    rootNode = nil,
    rootItems = nil,

    rankListTableView = nil,
    rewardListTableView = nil,

    rankData = {},
    rewardData = {},

    myrank = {},

    pageconfig = {"rank","reward",},

    pagename = {gameConfig.strings:string_common("guild_boss",12),gameConfig.strings:string_common("guild_boss",13),},
    selectpage = "rank",

    normalCellSize = {x=1080,y=250},
    rewardCellSize = {x=1080,y=230},

    isscrolltouched = false,
}

function gangbossrank.init(self,parent,toppos)
    self.rootNode,self.rootItems = CCBReaderLoad("gonghui2/gonghui_bossrank", nil, true, "gonghui_bossrank")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)

    self.rootItems.rankNode:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-410))
    self.rootItems.rewardNode:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-410))

    self.rootItems.backbutton:setTouchPriority(-101)
    self.rootItems.backbutton:addHandleOfControlEvent(function()
        GameScene:shiftLayer("guildboss","up")
    end, CCControlEventTouchUpInside)


    --
    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","gangbossrank",touchbegin)
    local function touchend(pos)
        if self.rootItems.rankNode and ui.isTouched(self.rootItems.rankNode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
        if self.rootItems.rewardNode and ui.isTouched(self.rootItems.rewardNode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","gangbossrank",touchend)
    --

    --self:shiftPage(self.selectpage)
    UIRequest({type = 4841})
    --

end

function gangbossrank.clear(self)
    gameTouch:UnrigistFunc("begin","gangbossrank")
    gameTouch:UnrigistFunc("end","gangbossrank")
    self.isscrolltouched = false
    self.rootItems = nil
    self.rankListTableView = nil
    self.rewardListTableView = nil
    self.selectpage = "rank"

    self.rankData = {}
    self.rewardData = {}

    self.myrank = {}

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end




function gangbossrank.shiftPage(self,type)
    self.selectpage = type
    print("shifPage")

    for k,v in ipairs(self.pageconfig) do
        if v == type then
            self.rootItems[v.."Node"]:setVisible(true)
            self.rootItems[v.."Node"]:setPositionX(0)
        else
            self.rootItems[v.."Node"]:setVisible(false)
            self.rootItems[v.."Node"]:setPositionX(9999)
        end
    end

    self:setMyRank()
end


function gangbossrank.setMyRank(self)

    ui.setLabelString(self.rootItems.name,self.myrank.name or "",9)

    if self.myrank.rank and self.myrank.rank > 0 then
        self.rootItems.hasrank:setVisible(true)
        self.rootItems.norank:setVisible(false)
        self.rootItems.rank:setString(self.myrank.rank)
    else
        self.rootItems.hasrank:setVisible(false)
        self.rootItems.norank:setVisible(true)
    end

    self.rootItems.damage:setString(self.myrank.damage or "")

end


function gangbossrank.ReloadData(self,data)

    self.rankData = data.gangrank or {}
    self.myrank = data.myrank or {}
    self.rewardData = {}
    for k,v in pairs(gamedata.config.gang2_boss_reward or {}) do
        table.insert(self.rewardData,v)
    end
    local sortByK = function(a,b) return a.rank < b.rank end
    table.sort(self.rewardData, sortByK)

    if not self.rankListTableView then
        self:createRankList()
    else
        self.rankListTableView:reloadData()
    end

    if not self.rewardListTableView then
        self:createRewardList()
    else
        self.rewardListTableView:reloadData()
    end

    self:shiftPage(self.selectpage)
end


function gangbossrank.createRankList(self)
    print("createRankList")

    local celldict = {}
    local unrecycleCell = {}
    local rankListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("gonghui2/cell_gonghuibossrank_1", nil, true, "cell_gonghuibossrank_1")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            --
            --info
            if a1+1 < 4 then
                ccbDocumentControler.istop:setVisible(true)
                ccbDocumentControler.notop:setVisible(false)
                setSpriteFrameByName(ccbDocumentControler.top_rank,"b_n_zxt_"..(a1+1))
            else
                ccbDocumentControler.istop:setVisible(false)
                ccbDocumentControler.notop:setVisible(true)
                ccbDocumentControler.rank:setString(a1+1)
            end

            ui.setLabelString(ccbDocumentControler.name,self.rankData[tostring(a1+1)].name or "",21)
            ccbDocumentControler.president:setString(self.rankData[tostring(a1+1)].president)
            ccbDocumentControler.membersnum:setString(self.rankData[tostring(a1+1)].members)
            ccbDocumentControler.damage:setString(self.rankData[tostring(a1+1)].damage)
            ccbDocumentControler.desc:setString("")

            cellCCB:setPosition(self.normalCellSize.x/2, 0)

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.rankData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.rankListTableView = ui.createLuaTableView({
        handle = rankListHandle,
        viewwidth = self.rootItems.rankNode:getContentSize().width,
        viewheight = self.rootItems.rankNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.rankNode:addChild(self.rankListTableView)
    self.rankListTableView:setTouchPriority(-101)
end

function gangbossrank.createRewardList(self)
    print("createRankList")

    local celldict = {}
    local unrecycleCell = {}
    local rewardListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.rewardCellSize.x, self.rewardCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("gonghui2/cell_gonghui_bossreward", nil, true, "cell_gonghui_bossreward")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            --
            if self.rewardData[a1] and self.rewardData[a1].rank and self.rewardData[a1].rank+1 < self.rewardData[a1+1].rank then
                ccbDocumentControler.rank:setString((self.rewardData[a1].rank+1).."~"..self.rewardData[a1+1].rank)
            else
                ccbDocumentControler.rank:setString(self.rewardData[a1+1].rank)
            end
            --
            local reward = ui.getIDandNUMs(self.rewardData[a1+1].reward)
            for i = 1,4 do
                if reward[i] then
                    ccbDocumentControler["r"..i]:setVisible(true)
                    ui.setNewIcon(ccbDocumentControler,reward[i],i-1)
                    --
                    ccbDocumentControler["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
                        if not self.isscrolltouched then return end
                        if gameTouch.isScrollling then return end
                        ui.setPopwindowByCid(reward[i].cid)
                    end, CCControlEventTouchUpInside)
                    ccbDocumentControler["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(-103)
                else
                    ccbDocumentControler["r"..i]:setVisible(false)
                    --
                    ccbDocumentControler["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
                        if not self.isscrolltouched then return end
                        if gameTouch.isScrollling then return end
                    end, CCControlEventTouchUpInside)
                    ccbDocumentControler["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(-103)
                end
            end
            --
            cellCCB:setPosition(self.rewardCellSize.x/2, 0)

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.rewardData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.rewardListTableView = ui.createLuaTableView({
        handle = rewardListHandle,
        viewwidth = self.rootItems.rewardNode:getContentSize().width,
        viewheight = self.rootItems.rewardNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.rewardNode:addChild(self.rewardListTableView)
    self.rewardListTableView:setTouchPriority(-101)
end



return gangbossrank


  Š'  