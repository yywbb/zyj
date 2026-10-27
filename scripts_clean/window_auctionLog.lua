--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/1/17
-- Time: 17:08
-- To change this template use File | Settings | File Templates.
--

local auctionLog = {
    rootNode = nil,
    rootItems = nil,

    pageconfig = {"myservice","allservice" },
    selectpage = "myservice",
}

function auctionLog.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("paimaihang/rizhi", nil, true, "rizhi")
    self.touchPriority = touchPriority

    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("auctionLog")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    --
    self.rootItems["myserviceBtn"]:addHandleOfControlEvent(function()
        self:shiftpage("myservice")
    end, CCControlEventTouchUpInside)
    self.rootItems["myserviceBtn"]:setSwallowsTouch(true)
    self.rootItems["myserviceBtn"]:setTouchPriority(self.touchPriority-2)

    self.rootItems["allserviceBtn"]:addHandleOfControlEvent(function()
        self:shiftpage("allservice")
    end, CCControlEventTouchUpInside)
    self.rootItems["allserviceBtn"]:setSwallowsTouch(true)
    self.rootItems["allserviceBtn"]:setTouchPriority(self.touchPriority-2)

    self:shiftpage(self.selectpage)

    UIRequest({type = 4813})
    return self.rootNode
end

function auctionLog.setMessage(self,data)
    local ss = ""
    if data then

        local _config = gamedata.config.auction_items
        local config = _config[tostring(data.s_id)] or {}
        ss = gameConfig.strings:auction_log(data.s_opt,config.name or "",config.num or 0,data.s_num,data.s_time)
    end
    return ss
end

function auctionLog.reload(self,data)

    local message1 = data.messages1 or {}
    local message2 = data.messages2 or {}

    for i = 1,table.getTableLength(data.messages1) do
        message1[tostring(i)] = self:setMessage(data.messages1[tostring(i)])
    end

    for i = 1,table.getTableLength(data.messages2) do
        message2[tostring(i)] = self:setMessage(data.messages2[tostring(i)])
    end
    --
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(920, 50)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("paimaihang/cell_paimaihang_message2", nil, true, "cell_paimaihang_message2")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            --

            ui.setLabelString(ccbDocumentControler.message,message1[tostring(a1+1)],14)

            cellCCB:setPosition(0, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(message1)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    local ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.myserviceNode:getContentSize().width,
        viewheight = self.rootItems.myserviceNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.myserviceNode:addChild(ListTableView)
    ListTableView:setTouchPriority(self.touchPriority)

    --

    --
    local celldict2 = {}
    local ListHandle2 = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(920, 50)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("paimaihang/cell_paimaihang_message2", nil, true, "cell_paimaihang_message2")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            --
            ui.setLabelString(ccbDocumentControler.message,message2[tostring(a1+1)],14)
            --
            cellCCB:setPosition(0, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(message2)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    local ListTableView2 = ui.createLuaTableView({
        handle = ListHandle2,
        viewwidth = self.rootItems.allserviceNode:getContentSize().width,
        viewheight = self.rootItems.allserviceNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.allserviceNode:addChild(ListTableView2)
    ListTableView2:setTouchPriority(self.touchPriority)



end

function auctionLog.shiftpage(self,page)

    self.selectpage = page

    if self.selectpage == "myservice" then
        self.rootItems.myserviceNode:setPositionX(0)
        self.rootItems.allserviceNode:setPositionX(9999)
        setSpriteFrameByName(self.rootItems.myserviceSprite, gameConfig.images.pageButtonON)
        setSpriteFrameByName(self.rootItems.allserviceSprite, gameConfig.images.pageButtonOFF)
    else
        self.rootItems.myserviceNode:setPositionX(9999)
        self.rootItems.allserviceNode:setPositionX(0)
        setSpriteFrameByName(self.rootItems.myserviceSprite, gameConfig.images.pageButtonOFF)
        setSpriteFrameByName(self.rootItems.allserviceSprite, gameConfig.images.pageButtonON)
    end
end

function auctionLog.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return auctionLog

