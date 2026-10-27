local honorBattleReward = {
    cellSize = {width = 980, height = 150},
    rootNode = nil,
    rootItems = nil,
}

function honorBattleReward.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.listTableView = nil
    self.rootNode = nil
    self.rootItems = nil
end

function honorBattleReward.open(self, touchPriority, data, callback)
    self:initNode(touchPriority)
    self:initConfig()
    self:initEventBtn()
    self:initActivityScroll()
    self:initFixedString()
    self:reloadData()

    return self.rootNode
end

function honorBattleReward.initNode(self, touchPriority)
    self.rootNode, self.rootItems = CCBReaderLoad("rongyaozhizhan/rongyaozhizhan_jiangli", nil, true, "rongyaozhizhan_jiangli")
    self.touchPriority = touchPriority

    self.rootItems.rankText:setString("排名")
    self.rootItems.rewardText:setString("奖励内容")
end

function honorBattleReward.initConfig(self)
    self.rewardConfig = gamedata.config.glory_battle_rankreward
end

function honorBattleReward.initEventBtn(self)
    self:initCloseBtn()
end

function honorBattleReward.initCloseBtn(self)
    local _cb = function()
        gameWindows:closeWindow("honorBattleReward")
    end

    self:commonBtn(self.rootItems, "closeButton", _cb)
end

function honorBattleReward.initActivityScroll(self)
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

function honorBattleReward.initFixedString(self)
    self.rootItems.descText:setString(gameConfig.strings:string_common("honorBattle2", 25))
end

function honorBattleReward.reloadData(self)
    if self.rewardConfig then
        if not self.listTableView then
            self:creatList()
        else
            self.listTableView:reloadData()
        end
    end
end

function honorBattleReward.creatList(self)
    local _celldict = {}
    local _listHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local _r

        if fn == "cellSize" then
            _r = CCSizeMake(self.cellSize.width, self.cellSize.height)
        elseif fn == "cellAtIndex" then
            local _cellCCB, _ccbDocumentControler = 0, 0
            local _first = true

            if not a2 then
                a2 = CCTableViewCell:create()
                _cellCCB, _ccbDocumentControler = CCBReaderLoad("rongyaozhizhan/cell_jiangli", nil, true, "cell_jiangli")
                _celldict[a2] = {cellCCB = _cellCCB, ccbDocumentControler = _ccbDocumentControler }
            else
                _first = false
                _cellCCB = _celldict[a2].cellCCB
                _ccbDocumentControler = _celldict[a2].ccbDocumentControler
            end

            self:setCell(_ccbDocumentControler, self.rewardConfig[tostring(a1 + 1)], a1 + 1)

            _cellCCB:setPosition(self.cellSize.width / 2, 0)

            if _first then
                a2:addChild(_cellCCB)
            end

            _r = a2
        elseif fn == "numberOfCells" then
            _r = table.getTableLength(self.rewardConfig)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end

        return _r
    end)

    self.listTableView = ui.createLuaTableView({
        handle = _listHandle,
        viewwidth = self.rootItems["scrollList"]:getContentSize().width,
        viewheight = self.rootItems["scrollList"]:getContentSize().height,
        dire = 1
    })
    self.rootItems["scrollList"]:addChild(self.listTableView)
    self.listTableView:setTouchPriority(self.touchPriority - 1)
end

function honorBattleReward.setCell(self, item, data, index)
    self:setRankName(item, data.name)
    self:setReward(item, data.win_reward)
end

function honorBattleReward.setRankName(self, item, name)
    item.rank:setString(name)
end

function honorBattleReward.setReward(self, item, rewards)
    local _t = ui.Split(rewards, ";")
    local _usedata = {}

    for k,v in pairs(_t) do
        if v ~= "" or v == nil then
            table.insert(_usedata, ui.Split(v, ","))
        end
    end

    local _len = table.getTableLength(_usedata)

    for i = 1, 5 do
        if i <= _len then
            local _key_Ex = ""
            
            if i == 1 then
                _key_Ex = ""
            else
                _key_Ex = "_"..(i-1)
            end

            item["reward"..i]:setVisible(true)
            ui.setNewIcon(item, {cid = _usedata[i][1], num = _usedata[i][2]}, i - 1)
            
            local _cb = function()
                if not self.isscrolltouched then return true end
                if gameTouch.isScrollling then return true end

                if _usedata[i][1] and _usedata[i][1] ~="" then
                    ui.setPopwindowByCid(_usedata[i][1])
                end
            end

            self:commonBtn(item, "i_button".._key_Ex, _cb, self.touchPriority - 2, false)
        else
            item["reward"..i]:setVisible(false)
        end
    end
end

-- 通用按钮
function honorBattleReward.commonBtn(self, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)
    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(touchPriority or (self.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return honorBattleReward