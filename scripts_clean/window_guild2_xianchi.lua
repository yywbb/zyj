--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/31
-- Time: 上午10:58
-- To change this template use File | Settings | File Templates.
--

local windowxianchi = {
    root = nil,
    rootNode = nil,
    rootItems = nil,
    ListTableView = nil,
    ranklistdata = {},

}

function windowxianchi.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority

    print("i...am...windowxianchi")
    if data.index == "rule" then
        self.rootNode, self.rootItems = CCBReaderLoad("gonghui2/zaotang_rule.ccbi", nil, true, "zaotang_rule")
        self:rulereload()
    elseif data.index == "rank" then
        self.rootNode, self.rootItems = CCBReaderLoad("gonghui2/zaotang_rank.ccbi", nil, true, "zaotang_rank")
        self:rankreload()
    end
    
    self.root:addChild(self.rootNode)
    return self.root
end

function windowxianchi.rulereload(self)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        print("i..am...closeButton..")
        
        gameWindows:closeWindowDirect("guildxianchirank")
    end, CCControlEventTouchUpInside)
    
end



function windowxianchi.rankreload(self)

    ui.setLabelString( self.rootItems.myrankText, nil, 46)
    ui.setLabelString( self.rootItems.mycontributionText, nil, 46)


    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        print("i..am...closeButton..")
        
        gameWindows:closeWindowDirect("guildxianchirank")
    end, CCControlEventTouchUpInside)



    UIRequest({type = 2261})
end



function windowxianchi.createRankList( self, data )
    self.ranklistdata = data

    print("createrankList")

    local rankstring = "0"
    local contributionstring = "0"

    for k,v in pairs(self.ranklistdata) do
        if GameScene.roleinfo.id == v.rid then
            rankstring = k
            contributionstring = v.param
            break
        end
    end


    ui.setLabelString(self.rootItems.myrank_Label, rankstring , 21)
    ui.setLabelString(self.rootItems.mycontribution_Label, contributionstring , 21)



    if ListTableView then
        ListTableView:reloadData()
    else
        self:createrankList()
    end
    
end

function windowxianchi.createrankList(self)
    print("createPropsList")
    printT(self.ranklistdata)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("gonghui2/cell_zaotangrank", nil, true, "cell_zaotangrank")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                -- ui.tableviewAnimation(self.ListTableView,cellCCB,920/2,0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local itemdata = self.ranklistdata[tostring(a1+1)]

            printT(itemdata)

            ccbDocumentControler.rank:setString(a1+1)

            -- ui.setLabelString(ccbDocumentControler.name, itemdata.name, 7)

            -- 添加段位排名闪烁
            ui.setWudaoDuanweiRankEffect(ccbDocumentControler,itemdata,0,38/34,7)

            ccbDocumentControler.lv_Label:setString(itemdata.level)
            ccbDocumentControler.contribution_Label:setString(itemdata.param)
            
            cellCCB:setPosition(920/2,0)

            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.ranklistdata)
        elseif fn == "cellTouched" then
            -- GameScene:shiftLayerById(self.config[tostring(a1:getIdx()+1)].systemid)
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

function windowxianchi.close(self)
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil

end

return windowxianchi