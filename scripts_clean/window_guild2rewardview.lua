--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/25
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--

local guildrewardview = {
    rootNode = nil,
    rootItems = nil,
}

function guildrewardview.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("gonghui2/gonghui_jiangliyulan", nil, true, "reward")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function guildrewardview.reload(self,data,callback)
    self.callback = callback

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("guildrewardview")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    --
    local rewarddata = gamedata.config.gang2_level or {}
    --
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(930, 200)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("gonghui2/cell_jiangliyulan", nil, true, "cell")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            --
            ccbDocumentControler.ganglevel:setString("公会"..rewarddata[tostring(a1+1)].level.."级")
            local reward = ui.getIDandNUMs( rewarddata[tostring(a1+1)].param )
            for i=1, 3 do
                if reward[i] and reward[i].cid > 0 then
                    ccbDocumentControler["ccbitem"..i]:setVisible(true)

                    local config = ui.IDconfig(reward[i].cid)
                    if config then
                        ui.setNewIcon(ccbDocumentControler,{cid = reward[i].cid, num = reward[i].num},i-1)
                        --
                        ccbDocumentControler["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
                            ui.setPopwindowByCid(reward[i].cid)
                        end, CCControlEventTouchUpInside)
                        ccbDocumentControler["i_button"..(i>1 and "_"..i-1 or "")]:setSwallowsTouch(true)
                        ccbDocumentControler["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(self.touchPriority)

                    end
                else
                    ccbDocumentControler["ccbitem"..i]:setVisible(false)
                end
            end

            --
            cellCCB:setPosition(930/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(rewarddata)
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

function guildrewardview.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return guildrewardview

