local honorBattleDivisionInfo = {
    cellDivisionSize = {width = 185, height = 154},
    cellInfoSize = {width = 960, height = 100},
    rootNode = nil,
    rootItems = nil,
    selectedDivision = 1,
}

function honorBattleDivisionInfo.close(self)
    self.divisionListTableView = nil

    for i = 1, 7 do
        self["listTableView"..i] = nil
    end

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function honorBattleDivisionInfo.open(self, touchPriority, data, callback)

    self.data = data.infodata
    self.myData = data.infodata.mydata
    self.selectedDivision = 1
    self:initNode(touchPriority)
    self:initConfig()
    self:initEventBtn()
    self:initActivityScroll()
    self:setMyShow()

    self:shiftDivison(self.selectedDivision)

    return self.rootNode
end

function honorBattleDivisionInfo.initNode(self, touchPriority)
    self.rootNode, self.rootItems = CCBReaderLoad("rongyaozhizhan/rongyaozhizhan_saiquinfo", nil, true, "rongyaozhizhan_saiquinfo")
    self.touchPriority = touchPriority

    ui.setLabelString(self.rootItems.titleTxt,"赛区详情",65)
end

function honorBattleDivisionInfo.initConfig(self)
    self.intervalConfig = gamedata.config.glory_battle_interval
end

function honorBattleDivisionInfo.initEventBtn(self)
    self:initCloseBtn()
end

function honorBattleDivisionInfo.initCloseBtn(self)
    local _cb = function()
        gameWindows:closeWindow("honorBattleDivisionInfo")
    end

    self:commonBtn(self.rootItems, "closeButton", _cb)
end

function honorBattleDivisionInfo.initActivityScroll(self)
    local function touchBegin(pos)
        self.isscrolltouched = false
        self.touchbegin = {x = pos.x, y = pos.y}
    end

    local function touchEnd(pos)
        if math.abs(pos.x - (self.touchbegin and self.touchbegin.x or pos.x)) > 20 or math.abs(pos.y - (self.touchbegin and self.touchbegin.y or pos.y)) > 20 then
            self.isscrolltouched = false
        else
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("begin", "battleSeasonReward", touchBegin)
    gameTouch:rigistFunc("end", "battleSeasonReward", touchEnd)
end

function honorBattleDivisionInfo.setMyShow(self)
    if next(self.myData) then
        self.rootItems.bg_1:setVisible(false)
        self.rootItems.bg_2:setVisible(true)
        self:setIcon(self.rootItems, self.myData.groupid)
        self:setServiceName(self.rootItems, self.myData)
    else
        self.rootItems.bg_1:setVisible(true)
        self.rootItems.bg_2:setVisible(false)
        self.rootItems.icon:setVisible(false)
        local serverdata = {
            serverid = gameWindows.windows["roleinfo"].module.SelectedServer.id,
            servername = gameWindows.windows["roleinfo"].module.SelectedServer.name,
        }
        self:setServiceName(self.rootItems, serverdata)
    end
end

function honorBattleDivisionInfo.setIcon(self, item, groupid, iconType)
    local _iconName = self.intervalConfig[tostring(groupid)].icon

    if iconType == "button" then
        setControlButtonFrame(item.divisionBtn, _iconName, _iconName, _iconName)
    else
        setSpriteFrameByName(item.icon, _iconName)
    end
end

function honorBattleDivisionInfo.setServiceName(self, item, data)
    item.name:setString("S"..data.serverid.." "..data.servername)
end

function honorBattleDivisionInfo.shiftDivison(self, index)
    self.selectedDivision = index
    print(self.selectedDivision)

    self:setNodePosition()
    self:reloadData()
end

function honorBattleDivisionInfo.setNodePosition(self)
    for i = 1, 7 do
        if i == self.selectedDivision then
            self.rootItems["listNode"..i]:setPositionX(0)
        else
            self.rootItems["listNode"..i]:setPositionX(9999)
        end
    end
end

function honorBattleDivisionInfo.reloadData(self)
    self.showData = self.data["group"..self.selectedDivision]
    self.rootItems.openServiceTimeLab:setString(self.intervalConfig[tostring(self.selectedDivision)].desc) 

    if not self.divisionListTableView then
        self:creatDivisionList()
    else
        self.divisionListTableView:reloadData()
    end

    if self.showData and next(self.showData) then
        if not self["listTableView"..self.selectedDivision] then
            self:creatInfoList()
        else
            self["listTableView"..self.selectedDivision]:reloadData()
        end
    end
end

function honorBattleDivisionInfo.creatDivisionList(self)
    local _celldict = {}
    local _listHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local _r

        if fn == "cellSize" then
            _r = CCSizeMake(self.cellDivisionSize.width, self.cellDivisionSize.height)
        elseif fn == "cellAtIndex" then
            local _cellCCB, _ccbDocumentControler = 0, 0
            local _first = true

            if not a2 then
                a2 = CCTableViewCell:create()
                _cellCCB, _ccbDocumentControler = CCBReaderLoad("rongyaozhizhan/cell_saiquinfo2", nil, true, "cell_saiquinfo2")
                _celldict[a2] = {cellCCB = _cellCCB, ccbDocumentControler = _ccbDocumentControler }
            else
                _first = false
                _cellCCB = _celldict[a2].cellCCB
                _ccbDocumentControler = _celldict[a2].ccbDocumentControler
            end

            self:setDivisionCell(_ccbDocumentControler, a1 + 1)

            _cellCCB:setPosition(self.cellDivisionSize.width / 2, self.cellDivisionSize.height / 2)

            if _first then
                a2:addChild(_cellCCB)
            end

            _r = a2
        elseif fn == "numberOfCells" then
            _r = table.getTableLength(self.intervalConfig)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end

        return _r
    end)

    self.divisionListTableView = ui.createLuaTableView({
        handle = _listHandle,
        viewwidth = self.rootItems["divisionlistNode"]:getContentSize().width,
        viewheight = self.rootItems["divisionlistNode"]:getContentSize().height,
        dire = 0
    })
    self.rootItems["divisionlistNode"]:addChild(self.divisionListTableView)
    self.divisionListTableView:setTouchPriority(self.touchPriority - 1)
end

function honorBattleDivisionInfo.creatInfoList(self)
    local _celldict = {}
    local _listHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local _r

        if fn == "cellSize" then
            _r = CCSizeMake(self.cellInfoSize.width, self.cellInfoSize.height)
        elseif fn == "cellAtIndex" then
            local _cellCCB, _ccbDocumentControler = 0, 0
            local _first = true

            if not a2 then
                a2 = CCTableViewCell:create()
                _cellCCB, _ccbDocumentControler = CCBReaderLoad("rongyaozhizhan/cell_saiquinfo", nil, true, "cell_saiquinfo")
                _celldict[a2] = {cellCCB = _cellCCB, ccbDocumentControler = _ccbDocumentControler }
            else
                _first = false
                _cellCCB = _celldict[a2].cellCCB
                _ccbDocumentControler = _celldict[a2].ccbDocumentControler
            end

            self:setInfoCell(_ccbDocumentControler, self.showData[tostring(a1 + 1)], a1 + 1)

            _cellCCB:setPosition(self.cellInfoSize.width / 2, 0)

            if _first then
                a2:addChild(_cellCCB)
            end

            _r = a2
        elseif fn == "numberOfCells" then
            _r = table.getTableLength(self.showData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end

        return _r
    end)

    self["listTableView"..self.selectedDivision] = ui.createLuaTableView({
        handle = _listHandle,
        viewwidth = self.rootItems["listNode"..self.selectedDivision]:getContentSize().width,
        viewheight = self.rootItems["listNode"..self.selectedDivision]:getContentSize().height,
        dire = 1
    })
    self.rootItems["listNode"..self.selectedDivision]:addChild(self["listTableView"..self.selectedDivision])
    self["listTableView"..self.selectedDivision]:setTouchPriority(self.touchPriority - 1)
end

function honorBattleDivisionInfo.setDivisionCell(self, item, index)
    self:setIcon(item, index, "button")
    self:setShadow(item, index)
    self:setDivisionBtn(item, index)
end

function honorBattleDivisionInfo.setShadow(self, item, index)
    if self.selectedDivision == index then
        item.shadowSprite:setVisible(false)
    else
        item.shadowSprite:setVisible(true)
    end
end

function honorBattleDivisionInfo.setInfoCell(self, item, data, index)
    self:setIcon(item, self.selectedDivision)
    self:setServiceName(item, data)
end

function honorBattleDivisionInfo.setDivisionBtn(self, item, index)
    local _cb = function()
        if not self.isscrolltouched then return true end
        if gameTouch.isScrollling then return true end

        self:shiftDivison(index)
    end

    self:commonBtn(item, "divisionBtn", _cb, self.touchPriority - 2, false)
end

-- 通用按钮
function honorBattleDivisionInfo.commonBtn(self, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)
    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(touchPriority or (self.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return honorBattleDivisionInfo