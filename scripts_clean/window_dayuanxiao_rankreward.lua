--
-- Created by IntelliJ IDEA.
-- User: jkp
-- Date: 22/9/19
-- Time: 下午7:12
-- To change this template use File | Settings | File Templates.
--

local dayuanxiao_rankreward = {
    rootNode = nil,
    rootItems = nil,

    rewardListTableView = nil,
    isscrolltouched = false,
    callback = nil,
}

function dayuanxiao_rankreward.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority

    self.rootNode, self.rootItems = CCBReaderLoad("activityzhongqiu/tc_jiangliyulan", nil, true, "tc_jiangliyulan")
    self.callback  = callback
    self:rewardReload()

    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","dayuanxiao_rankreward",touchbegin)
    local function touchend(pos)
        if self.rootItems.listscroll and ui.isTouched(self.rootItems.listscroll,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","dayuanxiao_rankreward",touchend) 

    self.root:addChild(self.rootNode)
    return self.root
end

function dayuanxiao_rankreward.rewardReload(self)
    --返回
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("dayuanxiao_rankreward")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    --预览列表
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(960, 180)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityzhongqiu/cell_rank_jiangli", nil, true, "cell_rank_jiangli")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCell(ccbDocumentControler,a1+1)

            cellCCB:setPosition(960/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
                r = table.getTableLength(gamedata.config.mystery_rank)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.rewardListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listscroll:getContentSize().width,
        viewheight = self.rootItems.listscroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.listscroll:addChild(self.rewardListTableView)
    self.rewardListTableView:setTouchPriority(self.touchPriority)
end

function dayuanxiao_rankreward.setCell(self,item,index)
    local configdata = gamedata.config.mystery_rank[tostring(index)]

    item.one:setVisible(false)
    item.two:setVisible(false)
    item.three:setVisible(false)
    item.otherRank:setVisible(false)
    if configdata.rank == 1 then
        item.one:setVisible(true)
    elseif configdata.rank == 2 then
        item.two:setVisible(true)
    elseif configdata.rank == 3 then
        item.three:setVisible(true)
    else
        local lastconfig = gamedata.config.mystery_rank[tostring(index-1)]
        item.otherRank:setString((tonumber(lastconfig.rank)+1).." ~ "..configdata.rank)
        item.otherRank:setVisible(true)
    end

    local itemdata = ui.getIDandNUMs(configdata.reward)
    for i=1,5 do
        if itemdata[i] then
            item["reward"..i]:setVisible(true)
            ui.setNewIcon(item,{cid=itemdata[i].cid,num=itemdata[i].num},i-1)
            item["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(self.touchPriority-1)
            item["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                ui.setPopwindowByCid(itemdata[i].cid)
            end, CCControlEventTouchUpInside)
        else
            item["reward"..i]:setVisible(false)
        end
    end

end

function dayuanxiao_rankreward.close(self)
    gameTouch:UnrigistFunc("begin","dayuanxiao_rankreward")
    gameTouch:UnrigistFunc("end","dayuanxiao_rankreward")    
    self.isscrolltouched = false    
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.rewardListTableView = nil

    if self.callback then
        self.callback()
    end
end

return dayuanxiao_rankreward