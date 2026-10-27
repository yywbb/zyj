local honorBattleDetail = {
    cellSize1 = {width = 920, height = 350},
    cellSize2 = {width = 920, height = 470},

    rootNode = nil,
    rootItems = nil,

    listTableView = nil,
}

function honorBattleDetail.close(self)
    gameTouch:UnrigistFunc("begin", "honorBattleDetail")
    gameTouch:UnrigistFunc("end", "honorBattleDetail")

    self.listTableView = nil

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)

    self.rootNode = nil
    self.rootItems = nil
end

function honorBattleDetail.open(self, touchPriority, data, callback)
    self.listTableView = nil
    self:initNode(touchPriority)
    self:initActivityScroll()
    self:initConfig()
    self:initEventBtn()
    self:initFixedString()

    local _data = {
        round = 1,
        info = {
            [1] = {
                winOrLose = 1,
                coolDown = 0,
                left = {
                    name = "aaaa1",
                    power = 1111,
                    formation = {
                        ["1"] = 10225,
                    },
                },
                right = {
                    name = "bbbb1",
                    power = 1112,
                    formation = {
                        ["1"] = 10226,
                    },
                },
            },
            [2] = {
                winOrLose = 0,
                coolDown = 1,
                left = {
                    name = "aaaa2",
                    power = 2221,
                    formation = {
                        ["1"] = 10227,
                        ["2"] = 10228,
                    },
                },
                right = {
                    name = "bbbb2",
                    power = 2222,
                    formation = {
                        ["1"] = 10229,
                        ["2"] = 0,
                    },
                },
            },
            [3] = {
                winOrLose = 0,
                coolDown = 0,
                left = {
                    name = "aaaa3",
                    power = 3331,
                    formation = {
                        ["1"] = 10227,
                        ["2"] = 10228,
                        ["3"] = 0,
                        ["4"] = 0,
                    },
                },
                right = {
                    name = "bbbb3",
                    power = 3332,
                    formation = {
                        ["1"] = 10227,
                        ["2"] = 10228,
                        ["3"] = 10229,
                        ["4"] = 0,
                    },
                },
            },
        },
    }

    self:reloadData(_data)

    --todo
    --UIRequest({type = })

    return self.rootNode
end

-- 初始化界面
function honorBattleDetail.initNode(self, touchPriority)
    self.rootNode, self.rootItems = CCBReaderLoad("rongyaozhizhan/tc_bisaiinfo", nil, true, "tc_bisaiinfo")
    self.touchPriority = touchPriority
    self.rootItems.oddsNode:setVisible(false)
end

function honorBattleDetail.initActivityScroll(self)
    local function touchBegin(pos)
        self.isscrolltouched = false
        self.touchbegin = {x = pos.x, y = pos.y}
    end

    local function touchEnd(pos)
        if math.abs(pos.x - (self.touchbegin and self.touchbegin.x or pos.x)) > 20 or
           math.abs(pos.y - (self.touchbegin and self.touchbegin.y or pos.y)) > 20 then
            self.isscrolltouched = false
        elseif self.rootItems["listScroll"] and ui.isTouched(self.rootItems["listScroll"], pos.x, pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("begin", "honorBattleDetail", touchBegin)
    gameTouch:rigistFunc("end", "honorBattleDetail", touchEnd)
end

-- 初始化配置表
function honorBattleDetail.initConfig(self)
    -- self.rewardTable = gamedata.config.king_reward
end

-- 初始化按钮点击事件
function honorBattleDetail.initEventBtn(self)
    self:initCloseBtn()
end

-- 初始化关闭按钮
function honorBattleDetail.initCloseBtn(self)
    local _cb = function()
        gameWindows:closeWindow("honorBattleDetail")
    end

    self:commonBtn(self.rootItems, "closeButton", _cb)
end

-- 固定文字
function honorBattleDetail.initFixedString(self)

end

-- 刷新数据
function honorBattleDetail.reloadData(self, data)
    self.data = data

    if self.data then
        if not self.listTableView then
            self:creatList()
        else
            self.listTableView:reloadData()
        end
    end
end

-- 初始化listTable
function honorBattleDetail.creatList(self)
    local _cellDict = {}
    local _listHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local _r
        if fn == "cellSize" then
        
        elseif fn == "hasFixedCellSize" then
            _r = false
        elseif fn == "cellSizeForIndex" then
            if a1 + 1 < table.getTableLength(self.data.info) then
                _r = CCSizeMake(self.cellSize1.width, self.cellSize1.height)
            else
                _r = CCSizeMake(self.cellSize2.width, self.cellSize2.height)
            end
        elseif fn == "isRecycle" then

            return false
        elseif fn == "cellAtIndex" then
            local _cellCCB, _ccbDocumentControler = 0, 0
            local _first = true

            if not a2 then
                a2 = CCTableViewCell:create()
                if a1 + 1 < table.getTableLength(self.data.info) then
                    _cellCCB, _ccbDocumentControler = CCBReaderLoad("rongyaozhizhan/cell_bisaiinfo1", nil, true, "cell_bisaiinfo1")
                else
                    _cellCCB, _ccbDocumentControler = CCBReaderLoad("rongyaozhizhan/cell_bisaiinfo2", nil, true, "cell_bisaiinfo2")
                end
                _cellDict[a2] = {cellCCB = _cellCCB, ccbDocumentControler = _ccbDocumentControler }
            else
                _first = false
                _cellCCB = _cellDict[a2].cellCCB
                _ccbDocumentControler = _cellDict[a2].ccbDocumentControler
            end

            self:setCell(_ccbDocumentControler, self.data.info[a1 + 1], a1 + 1)

            if a1 + 1 < table.getTableLength(self.data.info) then
                _cellCCB:setPosition(self.cellSize1.width / 2, -self.cellSize1.height)
            else
                _cellCCB:setPosition(self.cellSize2.width / 2, -self.cellSize2.height)
            end

            if _first then
                a2:addChild(_cellCCB)
            end

            _r = a2
        elseif fn == "numberOfCells" then
            _r = table.getTableLength(self.data.info)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end

        return _r
    end)

    self.listTableView = ui.createLuaTableView({
        handle = _listHandle,
        viewwidth = self.rootItems["listScroll"]:getContentSize().width,
        viewheight = self.rootItems["listScroll"]:getContentSize().height,
        dire = 1
    })
    self.rootItems["listScroll"]:addChild(self.listTableView)
    self.listTableView:setTouchPriority(self.touchPriority - 1)
end

-- 设置cell
function honorBattleDetail.setCell(self, item, data, index)
    self:initFixedItems(item, data, index)
    self:setGeneralIcon(item, data, index)
    self:setLookBtn(item, round)
end

-- 设置cell文字
function honorBattleDetail.initFixedItems(self, item, data, round)
    item.roundTxt:setString(gameConfig.strings:string_common("honorBattle2", round))
    local _str = ""

    if round == 1 then
        _str = "1v1"
    elseif round == 2 then
        _str = "2v2"
    elseif round == 3 then
        _str = "3v3"
    end

    item.titleTxt:setString(_str)
    item.playerNameLeftTxt:setString(data.left.name)
    item.powerLeftTxt:setString(gameConfig.strings:string_common("honorBattle2", 6)..data.left.power)
    item.playerNameRightTxt:setString(data.right.name)
    item.powerRightTxt:setString(gameConfig.strings:string_common("honorBattle2", 6)..data.right.power)
    item.lookInfoTxt:setString(gameConfig.strings:string_common("honorBattle2", 7))

    item.sp_first_left:setVisible(data.power_a>data.power_b)
    item.sp_first_right:setVisible(data.power_a<data.power_b)

    if data.coolDown > 0 then
        self:iconOrButtonIsShow(item, false)
        item.winOrLoseTxt:setString("")
    else
        self:iconOrButtonIsShow(item, true)
        if data.winOrLose == 0 then
            item.winOrLoseTxt:setString("")--gameConfig.strings:string_common("honorBattle2", 4))
        elseif data.winOrLose == 1 then
            item.winOrLoseTxt:setString("")--gameConfig.strings:string_common("honorBattle2", 5))
        end
    end
end

-- function honorBattleDetail.createTimer(self, item, time, round)
--     local _timerName = "honorBattleDetailTimer"..round
--     if gameTimer.times[_timerName] == nil then
--         gameTimer:rigistTime(_timerName, tonumber(time + 1))
--         gameTimer:rigistTimeFunc(_timerName, function()
--             if gameTimer.times[_timerName] <= 0 then 
--                 self:reloadData(self.data)

--                 gameTimer:UnrigistTime(_timerName)
--                 gameTimer:UnrigistTimeFunc(_timerName)
--             else
--                 item.winOrLoseTxt:setString(ui.makeTimeText(gameTimer.times[_timerName]))
--             end
--         end)
--     end
-- end

function honorBattleDetail.iconOrButtonIsShow(self, item, isShow)
    item.vsIcon:setVisible(not isShow)
    item.lookNode:setVisible(isShow)
end

function honorBattleDetail.setGeneralIcon(self, item, data, round)
    if round == 1 then
        self:hideIcon(item, 2)
        self:setGeneralIcon2(item, data.left.formation, 1, 0)
        self:setGeneralIcon2(item, data.right.formation, 2, 1)
    elseif round == 2 then
        self:hideIcon(item, 2)
        self:setGeneralIcon2(item, data.left.formation, 1, 0)
        self:setGeneralIcon2(item, data.right.formation, 3, 1)
    elseif round == 3 then
        self:hideIcon(item, 4)
        self:setGeneralIcon2(item, data.left.formation, 1, 0)
        self:setGeneralIcon2(item, data.right.formation, 5, 1)
    end
end

function honorBattleDetail.hideIcon(self, item, max)
    for i = 1, max do
        item["formationLeft"..i]:setVisible(false)
        item["formationRight"..i]:setVisible(false)
    end
end

function honorBattleDetail.setGeneralIcon2(self, item, data, start, formationType)
    local _max = start - 1 + table.getTableLength(data)

    for i = start, _max do
        local _name = ""
        if formationType == 0 then
            _name = "formationLeft"..(i - (start - 1))
        elseif formationType == 1 then
            _name = "formationRight"..(i - (start - 1))
        end
        if data[tostring(i - (start - 1))] > 0 then
            item[_name]:setVisible(true)

            if start == 2 then
                ui.setNewIcon(item, {cid = data[tostring(i - (start - 1))]}, 2)
            else
                ui.setNewIcon(item, {cid = data[tostring(i - (start - 1))]}, i - 1)
            end
        end
    end
end

function honorBattleDetail.setLookBtn(self, item, round)
    local _cb = function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end

        --todo
        --UIRequest({type = , id = round})
    end

    self:commonBtn(item, "lookBtn", _cb, false)
end

-- 通用按钮
function honorBattleDetail.commonBtn(self, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)
    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(touchPriority or (self.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return honorBattleDetail