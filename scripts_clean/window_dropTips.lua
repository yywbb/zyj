--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/7/24
-- Time: 上午10:32
-- To change this template use File | Settings | File Templates.
--


local drop = {
    rootNode = nil,
    rootItems = nil,

    root = nil,

    listview = nil

}

function drop.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("tanchuang/tc_huodetujing", nil, true, "tc_huodetujing")

    self.touchPriority = touchPriority

    if  self.rootItems.closeButton then
        self.rootItems.closeButton:addHandleOfControlEvent(function()
            gameWindows:closeWindow("dropTips")
        end, CCControlEventTouchUpInside)
        self.rootItems.closeButton:setSwallowsTouch(true)
        self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    end

    self:reload(data,callback)
    return self.rootNode
end

function drop.createlist(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(920, 170)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("tanchuang/cell_huoqutujing", nil, true, "cell_huoqutujing")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local celldata = self.listdata[a1+1]
            local i = string.find(celldata.param,",")
            local map,point  = 0,0
            if i then
                map,point = ui.getIDandNUM(celldata.param)
            else
                map = tonumber(celldata.param)
            end

            print(map,point, self.mapmaxN, self.pointmaxN,celldata.systemid)

            local isopen = true
            if celldata.systemid == 13 then
                 if map > self.mapmaxN then
                     isopen = false
                 elseif map == self.mapmaxN then
                     if point> self.pointmaxN then
                         isopen = false
                     end
                 end
            elseif celldata.systemid == 16 then
                if map > self.mapmaxB then
                    isopen = false
                elseif map == self.mapmaxB then
                    if point> self.pointmaxB then
                        isopen = false
                    end
                end
            end

            -- ccbDocumentControler.type:setString(celldata.systemid == 13 and "普通" or "精英")
            ccbDocumentControler.type:setString(celldata.systemid == 13 and gameConfig.strings:string_common("popups","putong") or gameConfig.strings:string_common("popups","jingying"))
            ccbDocumentControler.in_goto:setVisible(isopen)
            ccbDocumentControler.des:setVisible(not isopen)
            if gamedata.config.copy[tostring(map)][tostring(point)] then
                ccbDocumentControler.point:setString(gamedata.config.copy[tostring(map)][tostring(point)].name)
            end

            ccbDocumentControler.in_button:setSwallowsTouch(true)
            ccbDocumentControler.in_button:setTouchPriority(self.touchPriority-1)
            ccbDocumentControler.in_button:addHandleOfControlEvent(function()
                GameScene:shiftLayerById(celldata.systemid,celldata.param)

            end, CCControlEventTouchUpInside)

            cellCCB:setPosition(920/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.listdata)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.listview = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listnode:getContentSize().width,
        viewheight = self.rootItems.listnode:getContentSize().height,
        dire = 1
    })
    self.rootItems.listnode:addChild(self.listview)
    self.listview:setTouchPriority(self.touchPriority)
end

function drop.reload(self,data,callback)
    self.callback = callback

    ui.setNewIconName(self.rootItems,{cid = data.cid})

    local config = gamedata.config.drop[tostring(data.cid)]

    -- ui.setLabelString(self.rootItems.has,"当前拥有: "..data.num,14)
    ui.setLabelString(self.rootItems.has,gameConfig.strings:colNum(data.num),14)
    ui.setLabelString(self.rootItems.get,nil,14)

    if config then
        local droplist = {}
        local index = 1
        while config["param"..index] and config["param"..index] ~= "" do
            table.insert(droplist,{systemid = config["systemid"..index],param = config["param"..index]})
            index=index+1
        end
        if droplist[1].systemid >=12 and droplist[1].systemid <=16 then
            self.rootItems.listnode:setPosition(540,365)
            self.rootItems.listnode:setVisible(true)
            self.rootItems.des:setPosition(9999,365)
            self.rootItems.des:setVisible(false)
            self.listdata = droplist
            self.mapmaxN,self.pointmaxN = getNormalCopyProcess()
            self.mapmaxB,self.pointmaxB = getBraveCopyProcess()
            if self.listview then
                self.listview:reloadData()
            else
                self:createlist()
            end
        else
            self.rootItems.des:setPosition(540,365)
            self.rootItems.des:setVisible(true)
            self.rootItems.listnode:setPosition(9999,365)
            self.rootItems.listnode:setVisible(false)
            ui.setLabelString(self.rootItems.des,droplist[1].param,18)
        end
    else
        -- runGamePrompt({msg = "掉落配置出错！"})
        runGamePrompt({msg = gameConfig.strings:string_common("popups","dlpp")})
    end

end

function drop.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.listview = nil

    if self.callback then
        self.callback()
    end
end

return drop