local godCompetitionBattleStarRank = {
    rootNode = nil,
    rootItems = nil,
    cellSize = {width = 940, height = 100},
}

function godCompetitionBattleStarRank.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.listTableView = nil
    self.rootNode = nil
    self.rootItems = nil
end

function godCompetitionBattleStarRank.open(self, touchPriority, data, callback)

    self.data = data.rankdata
    self.myData = data.mydata

    self:initNode(touchPriority)
    self:initConfig()
    self:initEventBtn()
    self:initMyRank()

    if self.data and next(self.data) then
        if not self.listTableView then
            self:creatList()
        else
            self.listTableView:reloadData()
        end
    end

    return self.rootNode
end

function godCompetitionBattleStarRank.initNode(self, touchPriority)
    self.rootNode, self.rootItems = CCBReaderLoad("rongyaozhizhan/rongyaozhizhan_lijieguanjun", nil, true, "rongyaozhizhan_lijieguanjun")
    self.touchPriority = touchPriority
    self.rootItems.rankText:setString("排名")
    self.rootItems.playernameText:setString("玩家名称")
    self.rootItems.championnumText:setString("星级")
end

function godCompetitionBattleStarRank.initConfig(self)

end

function godCompetitionBattleStarRank.initEventBtn(self)
    self:initCloseBtn()
end

function godCompetitionBattleStarRank.initCloseBtn(self)
    local _cb = function()
        gameWindows:closeWindow("godCompetitionBattleStarRank")
    end

    self:commonBtn(self.rootItems, "closeButton", _cb)
end

function godCompetitionBattleStarRank.initMyRank(self)
    self.rootItems.c_bg:setVisible(false)
    self.rootItems.c_bg_self:setVisible(true)
    self:setRank(self.rootItems, self.myData.rank,self.myData.competition)
    self:setName(self.rootItems, self.myData.name)
    self:setChampionNum(self.rootItems, self.myData.star)
end

function godCompetitionBattleStarRank.setRank(self, item, rank,competition)
    if competition and competition == 0 then
        item.c_rank:setString("未报名")
        self:setRankIsShow(item, true)
    elseif rank == 0 then
        item.c_rank:setString(gameConfig.strings:string_common("honorBattle2", 24))
        self:setRankIsShow(item, true)
    elseif rank >= 1 and rank <= 3 then
        setSpriteFrameByName(item.c_rank_top, "b_n_zxt_"..rank)
        self:setRankIsShow(item, false)
    else
        item.c_rank:setString(rank)
        self:setRankIsShow(item, true)
    end
end

function godCompetitionBattleStarRank.setRankIsShow(self, item, isShow)
    item.c_rank:setVisible(isShow)
    item.c_rank_top:setVisible(not isShow)
end

function godCompetitionBattleStarRank.setName(self, item, name)
    item.c_name:setString(name)
end

function godCompetitionBattleStarRank.setChampionNum(self, item, championNum)
    item.c_point:setString(championNum)
end

function godCompetitionBattleStarRank.creatList(self)
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
                _cellCCB, _ccbDocumentControler = CCBReaderLoad("rongyaozhizhan/cell_rongyaozhizhanlijieguanjun", nil, true, "cell_rongyaozhizhanlijieguanjun")
                _celldict[a2] = {cellCCB = _cellCCB, ccbDocumentControler = _ccbDocumentControler }
            else
                _first = false
                _cellCCB = _celldict[a2].cellCCB
                _ccbDocumentControler = _celldict[a2].ccbDocumentControler
            end

            self:setCell(_ccbDocumentControler, self.data[tostring(a1 + 1)], a1 + 1)

            _cellCCB:setPosition(self.cellSize.width / 2, 0)

            if _first then
                a2:addChild(_cellCCB)
            end

            _r = a2
        elseif fn == "numberOfCells" then
            _r = table.getTableLength(self.data)
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

function godCompetitionBattleStarRank.setCell(self, item, data, index)
    self:setRank(item, data.rank)
    self:setName(item, data.name)
    self:setChampionNum(item, data.star)
end 

-- 通用按钮
function godCompetitionBattleStarRank.commonBtn(self, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)
    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(touchPriority or (self.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return godCompetitionBattleStarRank