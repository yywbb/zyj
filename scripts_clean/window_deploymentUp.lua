--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/6/30
-- Time: 18:24
-- To change this template use File | Settings | File Templates.
--

local deploymentUp = {
    rootNode = nil,
    rootItems = nil,
}

function deploymentUp.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("soulzhen/soulzhen_add", nil, true, "soulzhen_add")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    self:initFixedString()
    return self.rootNode
end

function deploymentUp.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("deploymentUp")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    --
    if not data then return end
    ui.setLabelString(self.rootItems.addNum,data.add..(data.add>0 and "%" or ""),14)

    --
    local zhenfaadds = {}
    zhenfaadds = gamedata.config.lingzhentu_add or {}
    --
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(950, 230)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("soulzhen/cell_soulzhen", nil, true, "soulzhen")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            --
            ccbDocumentControler.lab1:setString(gameConfig.strings:string_common("fixedString","deployment",4))
            ccbDocumentControler.lab2:setString(gameConfig.strings:string_common("fixedString","deployment",7))
            ccbDocumentControler.lab3:setString(gameConfig.strings:string_common("fixedString","deployment",8))


            ccbDocumentControler.desc:setString(zhenfaadds[tostring(a1+1)].desc or "")
            ccbDocumentControler.num:setString((zhenfaadds[tostring(a1+1)].effect or "").."%")
            --
            ccbDocumentControler.has_yes:setVisible(false)
            ccbDocumentControler.has_no:setVisible(true)
            if data.activation then
                for k,v in pairs(data.activation) do
                    if tonumber(v) == tonumber(zhenfaadds[tostring(a1+1)].id) then
                        ccbDocumentControler.has_yes:setVisible(true)
                        ccbDocumentControler.has_no:setVisible(false)
                    end
                end
            end
            --

            cellCCB:setPosition(952/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then

            r = table.getTableLength(zhenfaadds)
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

function deploymentUp.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

function deploymentUp.initFixedString(self)
    self.rootItems.fixlab2:setString(gameConfig.strings:string_common("fixedString","deployment",4))
end

return deploymentUp

