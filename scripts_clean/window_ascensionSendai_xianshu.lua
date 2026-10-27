
local ascension_xianshu = {
    rootNode = nil,
    rootItems = nil,

    listTableView = nil,
    buffCellSize = {x=1080, y=380},

    buffdata = {},

    buffconfig = {},
}

function ascension_xianshu.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("shengxiantai/shengxiantai_feishengxianshu", nil, true, "shengxiantai_feishengxianshu")
    self.touchPriority = touchPriority
    self.callback = callback

    local moveY = 0
    if GameScene.topposY > 1920 then
        moveY = (GameScene.topposY - 1920)/2
    end
    self.rootItems.topnode:setPositionY(data.toppos - moveY)
    self.rootItems.listview:setContentSize(CCSizeMake(gameConfig.originSize.width, data.toppos-330-85-moveY))

    --返回
    self.rootItems.common_back_btn:addHandleOfControlEvent(function()
        gameWindows:closeWindowDirect("ascension_xianshu")
    end, CCControlEventTouchUpInside)
    self.rootItems.common_back_btn:setSwallowsTouch(true)
    self.rootItems.common_back_btn:setTouchPriority(self.touchPriority)

    self.buffconfig = gamedata.config.breakskill or {}

    UIRequest({type = 8855})

    return self.rootNode
end

function ascension_xianshu.reloadData(self,data)
    if not data then
        return
    end

    self.buffdata = data.buffers
    if self.buffdata and next(self.buffdata) then
        self.rootItems.tishi2:setVisible(false)
        if not self.listTableView then
            self:createList()
        else
            self.listTableView:reloadData()
        end
    else
        self.rootItems.tishi2:setVisible(true)
    end

end

function ascension_xianshu.createList(self)
    local celldict = {}
    local rankListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.buffCellSize.x, self.buffCellSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("shengxiantai/cell_shengxiantai_xianshu", nil, true, "cell_shengxiantai_xianshu")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                --ui.tableviewAnimation(self.listTableView,cellCCB,self.buffCellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            for i=3,0,-1 do
                if self.buffdata[(a1+1)*4-i] or self.buffdata[tostring((a1+1)*4-i)] then
                    self:setCell(ccbDocumentControler, self.buffdata[(a1+1)*4-i] or self.buffdata[tostring((a1+1)*4-i)], 4-i)
                    ccbDocumentControler["xianshu"..(4-i)]:setVisible(true)
                else
                    ccbDocumentControler["xianshu"..(4-i)]:setVisible(false)
                end
            end

            cellCCB:setPosition(self.buffCellSize.x/2, 0)

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = math.ceil(table.getTableLength(self.buffdata)/4)
            -- r = 4
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.listTableView = ui.createLuaTableView({
        handle = rankListHandle,
        viewwidth = self.rootItems.listview:getContentSize().width,
        viewheight = self.rootItems.listview:getContentSize().height,
        dire = 1
    })
    self.listTableView:setTouchPriority(self.touchPriority - 1)
    self.rootItems.listview:addChild(self.listTableView)
end

function ascension_xianshu.setCell(self, itmes, data, index)
    local key_Ex = ""
    local id = index-1
    if id > 0 then
        key_Ex = "_"..id
    end

    local config = self.buffconfig[tostring(data.id)]
    printT(config, "jkp-config")

    local quality = ((tonumber(config.quality) >= 3) and config.quality or 3)
    if quality > 5 then
        quality = 5
    end
    setSpriteFrameByName(itmes["xianshu_bg"..key_Ex], "sxt_xianshu_"..quality)
    
    ui.setLabelString(itmes["xianshu_name"..key_Ex], config.name, ((config.quality and config.quality ~= 0) and config.quality or 1)*2-1, 28)
    ui.setLabelString(itmes["xianshu_des"..key_Ex], config.desc, 18, 21)

    if config.icon and config.quality then
        ui.setNewIcon(itmes, {icon = config.icon, quality = config.quality}, id)
    end

end

function ascension_xianshu.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.listTableView = nil
    self.buffdata = {}
    self.buffconfig = {}

    if self.callback then
        self.callback()
    end
end

return ascension_xianshu

