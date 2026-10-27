--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/31
-- Time: 上午10:58
-- To change this template use File | Settings | File Templates.
--

local gangrank2 = {
    root = nil,
    rootNode = nil,
    rootItems = nil,
    ListTableView = nil,
    ranklistdata = {},

}

function gangrank2.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority

    self.rootNode, self.rootItems = CCBReaderLoad("gonghui2/gonghui_bossrank2", nil, true, "gonghui_bossrank2")
    self.root:addChild(self.rootNode)

    UIRequest({type = 4842})
    return self.root
end




function gangrank2.reload(self,data)

    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindowDirect("gangrank2")
    end, CCControlEventTouchUpInside)

    self.ranklistdata = data

    if self.ListTableView then
        self.ListTableView:reloadData()
    else
        self:createrankList()
    end

end

function gangrank2.createrankList(self)
    print("createPropsList")
    printT(self.ranklistdata)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("gonghui2/cell_gonghuibossrank_3", nil, true, "cell_gonghuibossrank_3")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local itemdata = self.ranklistdata[tostring(a1+1)]

            printT(itemdata)

            ccbDocumentControler.rank:setString(a1+1)

            ui.setLabelString(ccbDocumentControler.name, itemdata.name or "", 7)

            ui.setNewIcon(ccbDocumentControler,{cid = itemdata.profile,title = itemdata.title,iconBox = itemdata.iconBox})

            ccbDocumentControler.lv_Label:setString(itemdata.level or 1)
            ccbDocumentControler.contribution_Label:setString(itemdata.contribution or 0)

            if ccbDocumentControler.vipnode then
                ccbDocumentControler.vipnode:setVisible(false)
                -- setSpriteFrameByName(ccbDocumentControler.vip,"b_n_vip_"..(itemdata.vip or 1))
            end

            cellCCB:setPosition(920/2,0)

            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.ranklistdata)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listScroll:getContentSize().width,
        viewheight = self.rootItems.listScroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.listScroll:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(self.touchPriority)
end

function gangrank2.close(self)
    self.ListTableView = nil
    self.ranklistdata = {}
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil

end

return gangrank2