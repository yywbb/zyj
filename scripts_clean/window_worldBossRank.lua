--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/25
-- Time: 下午7:12
-- To change this template use File | Settings | File Templates.
--


local worldbossrank = {
    rootNode = nil,
    rootItems = nil,

    ListTableView = nil
}

function worldbossrank.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("worldboss/n_worldboss_zhankuang", nil, true, "n_worldboss_zhankuang")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function worldbossrank.reload(self,data,callback)
    self.data = data

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("worldbossrank")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(932, 170)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("worldboss/cell_n_worldboss_zhankuang", nil, true, "cell_n_worldboss_zhankuang")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local data = nil
            ccbDocumentControler.killerlab:setVisible(false)
            if self.data.time and self.data.time ~= 0 and self.data.kill and self.data.kill.name~="" then
                 if a1==0 then
                     setSpriteFrameByName(ccbDocumentControler.ranksprite, "obj_boss")
                     ccbDocumentControler.rank:setString("")
                     ccbDocumentControler.killerlab:setVisible(true)
                     data =  self.data.kill
                 else
                     setSpriteFrameByName(ccbDocumentControler.ranksprite, a1<=3 and "b_n_zxt_"..a1 or "alpha")
                     ccbDocumentControler.rank:setString(a1<=3 and "" or a1)
                     data =  self.data.ranks[tostring(a1)]
                 end
            else
                setSpriteFrameByName(ccbDocumentControler.ranksprite, a1+1<=3 and "b_n_zxt_"..(a1+1) or "alpha")
                ccbDocumentControler.rank:setString(a1+1<=3 and "" or a1+1)

                data =  self.data.ranks[tostring(a1+1)]
            end

            ccbDocumentControler.name:setString(data.name)
            ccbDocumentControler.level:setString(data.level)
            ccbDocumentControler.damage:setString(data.param)

            -- ui.setLabelString(ccbDocumentControler["buttontext"],"阵 容",18)
            ui.setLabelString(ccbDocumentControler["buttontext"],gameConfig.strings:string_common("popups","zhengrong"),18)
            ccbDocumentControler.button:setTouchPriority(self.touchPriority-1)
            ccbDocumentControler.button:addHandleOfControlEvent(function()
                if gameTouch.isScrollling then return end
                print("i..am..button1:")
                printT(data)
                GameScene:addtempLayers("other_slotinfo",data,nil,2)
            end, CCControlEventTouchUpInside)

            --todo
            --part
            if ccbDocumentControler.duanNode then
                ui.setWudaoPart(ccbDocumentControler,data.part_point or 0)
            end

            cellCCB:setPosition(932/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            if self.data.time and self.data.time ~= 0 and self.data.kill and self.data.kill.name~="" then
                r = table.getTableLength(self.data.ranks) +1
            else
                r = table.getTableLength(self.data.ranks)
            end
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listscroll:getContentSize().width,
        viewheight = self.rootItems.listscroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.listscroll:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(self.touchPriority)

end

function worldbossrank.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.ListTableView = nil

    if self.callback then
        self.callback()
    end
end

return worldbossrank