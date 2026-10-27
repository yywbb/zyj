--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/25
-- Time: 下午7:12
-- To change this template use File | Settings | File Templates.
--


local friendcopyrank = {
    rootNode = nil,
    rootItems = nil,

    ListTableView = nil,
    isscrolltouched = false,
}

function friendcopyrank.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("copyFriend/copyfriend_rank", nil, true, "rank")

    self.touchPriority = touchPriority
    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","friendcopyrank",touchbegin)
    local function touchend(pos)
        if self.rootItems.listworld and ui.isTouched(self.rootItems.listworld,pos.x,pos.y) then
            self.isscrolltouched = true
        end
        if self.rootItems.listguild and ui.isTouched(self.rootItems.listguild,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","friendcopyrank",touchend)    
    self:reload(data,callback)

    return self.rootNode
end

function friendcopyrank.reload(self,data,callback)
    self.data = data or {}

    if not self.data.mynum then self.data.mynum = 0 end
    if not self.data.players then self.data.players = {} end

    ui.setLabelString(self.rootItems.des1,nil,46)
    ui.setLabelString(self.rootItems.des2,nil,46)

    -- self.rootItems.rank:setString("未上榜")
    ui.setLabelString(self.rootItems.rank,gameConfig.strings:string_common("popups","weishangbang"),21)
    ui.setLabelString(self.rootItems.num,self.data.mynum or 0,21)
    for k,v in pairs(self.data.players) do
        if v.rid == GameScene.roleinfo.id then
            ui.setLabelString(self.rootItems.rank,k,21)
        end
    end

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("friendcopyrank")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    --
    local rewards = {}
    local config = gamedata.config.expedition_rank_reward or {}
    for k,v in pairs(config) do
        table.insert(rewards,v)
    end
    local sortById = function(a,b) return a.rank > b.rank end
    table.sort(rewards, sortById)
    --

    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(920, 190)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("copyFriend/cell_paihang", nil, true, "cell_rank")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            ui.setLabelString(ccbDocumentControler.name,self.data.players[tostring(a1+1)].name,1)
            ccbDocumentControler.rank:setString(a1+1)
            ui.setLabelString(ccbDocumentControler.num,self.data.players[tostring(a1+1)].params["1"].i or 0,49)
            ui.setLabelString(ccbDocumentControler.des,nil,49)
            ui.setNewIcon(ccbDocumentControler,{cid = self.data.players[tostring(a1+1)].profile})

            local reward = ""
            local icon = ""
            for k,v in ipairs(rewards) do
                if (a1+1) <= v.rank then
                    reward = v.awards or ""
                    icon = v.icon or ""
                end
            end

            setControlButtonFrame(ccbDocumentControler.viewButton,icon)
            ccbDocumentControler.viewButton:setTouchPriority(self.touchPriority-1)
            ccbDocumentControler.viewButton:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                if gameTouch.isScrollling then return end
                gameWindows:openWindow("getStaff",{data = ui.getIDandNUMs(reward),type = gameConfig.strings:string_common("popups","jiangli")},nil)
            end, CCControlEventTouchUpInside)

            cellCCB:setPosition(920/2, 10)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.data.players)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listnode:getContentSize().width,
        viewheight = self.rootItems.listnode:getContentSize().height,
        dire = 1
    })
    self.rootItems.listnode:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(self.touchPriority)

end

function friendcopyrank.close(self)
    gameTouch:UnrigistFunc("begin","friendcopyrank")
    gameTouch:UnrigistFunc("end","friendcopyrank")    
    self.isscrolltouched = false
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.ListTableView = nil

    if self.callback then
        self.callback()
    end
end

return friendcopyrank