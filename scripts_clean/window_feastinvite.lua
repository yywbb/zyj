--
-- Created by IntelliJ IDEA.
-- User: dhope
-- Date: 19/11/8
-- Time: 上午10:58
--

local feastinvite = {
    rootNode = nil,
    rootItems = nil,
    talkId = 0,
    -- snatch = {},
}

function feastinvite.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("gonghui3/tc_gonghuizhaoji", nil, true, "tc_gonghuizhaoji")
    self.show = true
    self.touchPriority = touchPriority
    self.callback = nil
    self:reload(data,callback)
    return self.rootNode
end


function feastinvite.reload(self,data,callback)

    self.data = data

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("feastzhaoji")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.sure_lab,nil,19)
    self.rootItems.sure_btn:addHandleOfControlEvent(function()
        if gameTimer.times["BarrageSendTime"] and gameTimer.times["BarrageSendTime"] > 0 then
            return
        end
        self.callback = callback
        gameWindows:closeWindow("feastzhaoji")
        if self.data.params then
            UIRequest({type = 2290, barrageType = self.data.barrageType, talkId = self.talkId+1, params = self.data.params})
        else
            UIRequest({type = 2290, barrageType = self.data.barrageType, talkId = self.talkId+1})
        end
        print(self.data.barrageType.."=====feastinvite======="..self.talkId)
    end, CCControlEventTouchUpInside)
    self.rootItems.sure_btn:setSwallowsTouch(true)
    self.rootItems.sure_btn:setTouchPriority(self.touchPriority)

    if gameTimer.times["BarrageSendTime"] and gameTimer.times["BarrageSendTime"] > 0 then
        ui.setLabelString(self.rootItems.sure_lab,gameTimer.times["BarrageSendTime"].."S",19)
        ui.addGray("CCControlButton",self.rootItems.sure_btn)
        gameTimer:rigistTimeFunc("BarrageSendTime",function() 
            if gameTimer.times["BarrageSendTime"] > 0 then
                ui.setLabelString(self.rootItems.sure_lab,gameTimer.times["BarrageSendTime"].."S",19)
            else
                ui.removeGray("CCControlButton",self.rootItems.sure_btn)
                ui.setLabelString(self.rootItems.sure_lab,"发送",19)
            end
        end)
        
    else
        ui.removeGray("CCControlButton",self.rootItems.sure_btn)
        ui.setLabelString(self.rootItems.sure_lab,"发送",19)
    end
    
    if self.data then
        self.talkdata = gamedata.config.barrage[tostring(self.data.barrageType)]
        self:createTalkSelectList()
    end
end

function feastinvite.createTalkSelectList(self)

    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(910, 200)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("gonghui3/cell_banghuizhaoji", nil, true, "gonghui3/cell_banghuizhaoji")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            if self.talkId >= 0 and self.talkId == a1 then
                ccbDocumentControler.selimg:setVisible(true)
            else
                ccbDocumentControler.selimg:setVisible(false)
            end

            ccbDocumentControler.barragedesc:setString(self.talkdata[tostring(a1+1)].describe)
            ccbDocumentControler.selbtn:setTouchPriority(self.touchPriority)
            ccbDocumentControler.selbtn:setSwallowsTouch(true)
            ccbDocumentControler.selbtn:addHandleOfControlEvent(function()
                self.talkId = a1
                self.listTableView:reloadData()
            end, CCControlEventTouchUpInside)
            

            cellCCB:setPosition(910/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.talkdata)
        elseif fn == "cellTouched" then
            self.listTableView:reloadData()
        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.listTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listscroll:getContentSize().width,
        viewheight = self.rootItems.listscroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.listscroll:addChild(self.listTableView)
    self.listTableView:setTouchPriority(self.touchPriority)
end

function feastinvite.close(self)
    gameTimer:UnrigistTimeFunc("BarrageSendTime")
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.talkId = 0
    self.show = false
    if self.callback then
        self.callback()
    end
end

return feastinvite
