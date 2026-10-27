--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/30
-- Time: 上午10:10
-- To change this template use File | Settings | File Templates.
--

local zhuxiantairank = {
    rootNode = nil,
    rootItems = nil,
    isscrolltouched = false,
}

function zhuxiantairank.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("zhuxiantai2/zhuxiantai_paihang", nil, true, "rank")

    self.touchPriority = touchPriority

    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","zhuxiantairank",touchbegin)
    local function touchend(pos)
        if self.rootItems.listnode and ui.isTouched(self.rootItems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","zhuxiantairank",touchend)

    self:reload(data,callback)

    return self.rootNode
end

function zhuxiantairank.reload(self,data,callback)
    self.callback = callback

    --todo
    self.rootItems.myfloor:setVisible(false)
    self.rootItems.lab2:setVisible(false)
    --

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("zhuxiantairank")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    --

    if self.rootItems.lab1 then
        ui.setLabelString(self.rootItems.lab1,nil,46)
        ui.setLabelString(self.rootItems.lab2,nil,46)
    end

    local myrank = 0
    self.rootItems.myfloor:setString((data.mieshendian.maxfloor or 0))
    ui.setLabelString(self.rootItems.myfloor,nil,21)

    local players = {}
    for k,v in pairs(data.players) do
         v.rank = tonumber(k)
         table.insert(players,v)
        if v.rid == GameScene.roleinfo.id then
            myrank = tonumber(k)
        end
    end
    local sortBy = function(a,b) return a.rank < b.rank end
    table.sort(players, sortBy)
    if  myrank < 1 then
        -- self.rootItems.myrank:setString("未上榜")
        self.rootItems.myrank:setString(gameConfig.strings:string_common("popups","weishangbang"))
    else
        self.rootItems.myrank:setString(myrank)
    end
    ui.setLabelString(self.rootItems.myrank,nil,21)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("zhuxiantai2/cell_zhuxiantai_paihang", nil, true, "cell_zhuxiantai_paihang")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            --

            ccbDocumentControler.name:setString(players[a1+1].name or "")
            ccbDocumentControler.lv:setString(players[a1+1].level or "")
            ccbDocumentControler.floor:setString(players[a1+1]["params"]["1"].i or "")

            if ccbDocumentControler.floorLab then
                ui.setLabelString(ccbDocumentControler.name,nil,7)
                ui.setLabelString(ccbDocumentControler.lv,nil,21)
                ui.setLabelString(ccbDocumentControler.floorLab,nil,5)
                --ui.setLabelString(ccbDocumentControler.floorLab2,nil,121)
                --ui.setLabelString(ccbDocumentControler.floor,nil,121)
            end

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
            ui.setNewIcon(ccbDocumentControler,{cid = players[a1+1].profile,title = players[a1+1].title,iconBox = players[a1+1].iconBox})

            ccbDocumentControler["i_button"]:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                if gameTouch.isScrollling then return end                
                if players[a1+1].rid ~= GameScene.roleinfo.id then
                    --GameScene:addtempLayers("other_slotinfo",players[a1+1])
                    --gameWindows:closeWindowDirect("zhuxiantairank")
                    gameWindows:openWindow("chatpop",players[a1+1],nil)
                end
            end, CCControlEventTouchUpInside)
            --ccbDocumentControler["i_button"]:setSwallowsTouch(true)
            ccbDocumentControler["i_button"]:setTouchPriority(self.touchPriority)

            --
            cellCCB:setPosition(920/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(players)
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

function zhuxiantairank.close(self)
    gameTouch:UnrigistFunc("begin","zhuxiantairank")
    gameTouch:UnrigistFunc("end","zhuxiantairank")    
    self.isscrolltouched = false    
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return zhuxiantairank