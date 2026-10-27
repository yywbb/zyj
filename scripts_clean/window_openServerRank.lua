--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/30
-- Time: 上午10:10
-- To change this template use File | Settings | File Templates.
--

local openServerRank = {
    rootNode = nil,
    rootItems = nil,
    isscrolltouched = false,
}

function openServerRank.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("activityreward_new/openServer_paihang", nil, true, "openServer_paihang")

    self.touchPriority = touchPriority

    self.rootItems.fixedMy:setString(gameConfig.strings:string_common("fixedString","copyFiend",4))
    self.rootItems.fixedMing:setString(gameConfig.strings:string_common("fixedString","rank",1))
    self.rootItems.norank:setString(gameConfig.strings:string_common("popups","weishangbang"))
    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","openServerRank",touchbegin)
    local function touchend(pos)
        if self.rootItems.listnode and ui.isTouched(self.rootItems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","openServerRank",touchend)

    self:reload(data,callback)

    return self.rootNode
end

function openServerRank.reload(self,data,callback)
    self.callback = callback

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("openServerRank")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    --
    if data.method == 12 then
        self.rootItems.fixedTitle:setString(gameConfig.strings:string_common("activity",8))
        self.rootItems.type1:setString(gameConfig.strings:string_common("activity",10))
    elseif data.method == 11 or data.method == 13 or data.method == 14 then
        self.rootItems.fixedTitle:setString(gameConfig.strings:string_common("activity",7))
        self.rootItems.type1:setString(gameConfig.strings:string_common("activity",9))
    end
   
    local myrank = 0
    local players = {}
    for k,v in pairs(data.players) do
         v.rank = tonumber(k)
         table.insert(players,v)
        if v.rid == GameScene.roleinfo.id and (myrank < 1 or myrank > tonumber(k)) then
            myrank = tonumber(k)
        end
    end
    local sortBy = function(a,b) return a.rank < b.rank end
    table.sort(players, sortBy)
    if myrank == #players then
        myrank = 0
    end
    
    self.rootItems.num1:setString(players[#players]["params"]["1"].i or "")
    ui.setLabelString(self.rootItems.num1,nil,21)
    if  myrank < 1 then
        self.rootItems.hasrank:setVisible(false)
        self.rootItems.norank:setVisible(true)
    else
        self.rootItems.hasrank:setVisible(true)
        self.rootItems.norank:setVisible(false)
        self.rootItems.rank:setString(myrank)
    end
    --ui.setLabelString(self.rootItems.rank,nil,21)
    --
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(920, 180)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_openServer_paihang2", nil, true, "cell_openServer_paihang2")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            --
            if data.method == 12 then
                ccbDocumentControler.floorLab2:setString(gameConfig.strings:string_common("activity",10))
            elseif data.method == 11  or data.method == 13 or data.method == 14 then
                ccbDocumentControler.floorLab2:setString(gameConfig.strings:string_common("activity",9))
            end
            ccbDocumentControler.name:setString(players[a1+1].name or "")
            ccbDocumentControler.lv:setString(players[a1+1].level or "")
            ccbDocumentControler.floor:setString(players[a1+1]["params"]["1"].i or "")

            ccbDocumentControler.rank1:setVisible(false)
            ccbDocumentControler.rank2:setVisible(false)
            ccbDocumentControler.rank3:setVisible(false)
            ccbDocumentControler.rankother:setVisible(false)

            if players[a1+1].rank == 1 then
                ccbDocumentControler.rank1:setVisible(true)
            elseif players[a1+1].rank == 2 then
                ccbDocumentControler.rank2:setVisible(true)
            elseif players[a1+1].rank == 3 then
                ccbDocumentControler.rank3:setVisible(true)
            else
                ccbDocumentControler.rankother:setVisible(true)
                ccbDocumentControler.rank:setString(players[a1+1].rank)
            end
            --
            ui.setNewIcon(ccbDocumentControler,{cid = players[a1+1].profile})

            ccbDocumentControler["i_button"]:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                if gameTouch.isScrollling then return end                
                if players[a1+1].rid ~= GameScene.roleinfo.id then
                    gameWindows:openWindow("chatpop",players[a1+1],nil)
                end
            end, CCControlEventTouchUpInside)
            ccbDocumentControler["i_button"]:setTouchPriority(self.touchPriority)

            --
            cellCCB:setPosition(920/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(players) - 1
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    local ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listnode:getContentSize().width,
        viewheight = self.rootItems.listnode:getContentSize().height,
        dire = 1
    })
    self.rootItems.listnode:addChild(ListTableView)
    ListTableView:setTouchPriority(self.touchPriority)



end

function openServerRank.close(self)
    gameTouch:UnrigistFunc("begin","openServerRank")
    gameTouch:UnrigistFunc("end","openServerRank")    
    self.isscrolltouched = false    
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return openServerRank