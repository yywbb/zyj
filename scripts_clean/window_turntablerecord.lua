--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/1/17
-- Time: 17:08
-- To change this template use File | Settings | File Templates.
--

local turntablerecord = {
    rootNode = nil,
    rootItems = nil,
    systemId = nil,
    systemType = nil,
    typeindex = 1,
    messages = {},
}

function turntablerecord.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("activityduanwu/rizhi", nil, true, "rizhi")
    self.touchPriority = touchPriority
    self.typeindex = 1
    if data then
        if data.systemId then
            self.systemId = data.systemId
        end
        self.systemType = data.systemType or nil 
        if data.typeindex then
            self.systemId = nil
            self.typeindex = data.typeindex
        end
    end
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("turntablerecord")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    if self.systemId then
        UIRequest({type = 5346,systemId = self.systemId})
    else
        UIRequest({type = 4885,typeindex = self.typeindex})
    end
    self:createList()
    return self.rootNode
end

function turntablerecord.createList(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(940, 50)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityduanwu/cell_message", nil, true, "cell_message")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            --

            ui.setLabelString(ccbDocumentControler.message,self.messages[tostring(a1+1)],14)

            cellCCB:setPosition(0, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.messages)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    local ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listNode:getContentSize().width,
        viewheight = self.rootItems.listNode:getContentSize().height,
        dire = 1
    })

    self.rootItems.listNode:addChild(ListTableView)
    ListTableView:setTouchPriority(self.touchPriority)
    self.listTableView = ListTableView
end

function turntablerecord.setMessage(self,data)
    local ss = ""
    if data then
        if self.systemId then
            ss = gameConfig.strings:turntablerecordcommon(data.num,data.name,data.service,data.time,data.id)
        else
            ss = gameConfig.strings:turntablerecord(data.num,data.name,data.service,data.time)
        end
    end
    return ss
end

function turntablerecord.reload(self,data)

    local messages = {}
    local msgNums = table.getTableLength(data.messages)
    for i = 1,msgNums do
        local index = msgNums - i + 1
        if self.systemType and self.systemType ~= data.messages[tostring(index)].type then
        else
            messages[tostring(index)] = self:setMessage(data.messages[tostring(index)])
        end
    end
    printT(self.messages,"self.messages")
    self.messages = messages
    self.listTableView:reloadData()
    if table.getTableLength(self.messages)*50 > self.rootItems.listNode:getContentSize().height then
        self.listTableView:setLuaContentOffset(0, 0)
    else
        self.listTableView:setLuaContentOffset(0,self.rootItems.listNode:getContentSize().height - table.getTableLength(self.messages)*50)
    end
end


function turntablerecord.close(self)
    self.typeindex = 1
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.systemId = nil
    self.systemType = nil
    if self.callback then
        self.callback()
    end
end

return turntablerecord

