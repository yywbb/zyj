local poolingServersGift = {
    cellSize = {width = 1080, height = 228},
    rootItems = nil,
    rootNode = nil,
    ListTableView = nil,
    touchPriority = -101,
    activityId = 121,
}

--清空数据
function poolingServersGift.clear(self)
    gameTouch:UnrigistFunc("begin","poolingServersGift")
    gameTouch:UnrigistFunc("end","poolingServersGift")
    gameTimer:UnrigistTime("PoolingServersGift")
    gameTimer:UnrigistTimeFunc("PoolingServersGift")

    self.show = false

    if self.rootNode then
        self.listTableView = nil
        self.rootNode:removeAllChildrenWithCleanup(true)
        self.rootNode:removeFromParentAndCleanup(true)
        self.rootItems = nil
        self.rootNode = nil
    end
end

function poolingServersGift.init(self,size)
    self.contentsize = size
    self.show = true
    self:initNode()
    self:initTouch()
    self:initConfig()
    self:initEventBtn()
    self:initFixedString()
    self:createAnimation()

    UIRequest({type = 6103})

    return self.rootNode  
end

function poolingServersGift.initNode(self)
    self.rootNode, self.rootItems = CCBReaderLoad("activityhefu/hefuhaoli", nil, true, "hefuhaoli")
    self.rootItems.topnode:setPositionY(self.contentsize.y - 230)
    self.rootItems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width, self.contentsize.y - 180 - gameConfig.maiscenebottomheight - 450))
end

function poolingServersGift.initTouch(self)
    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin", "poolingServersGift", touchbegin)

    local function touchend(pos)
        if self.rootItems.listnode and ui.isTouched(self.rootItems.listnode, pos.x, pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end", "poolingServersGift", touchend)
end

function poolingServersGift.initConfig(self)
    self.activityTimeConfig = gamedata.config.activity_time[tostring(self.activityId)]
    self.suitGiftConfig = gamedata.config.suit_gift
end

function poolingServersGift.initEventBtn(self)

end

function poolingServersGift.initFixedString(self)
    self.rootItems.title:setString(gameConfig.strings:string_common("poolingServerGift", 1))
    ui.setLabelString(self.rootItems.desc1, gameConfig.strings:string_common("poolingServerGift", 6), 63)
    self.rootItems.descSpecial1:setString(gameConfig.strings:string_common("poolingServerGift", 7))
    ui.setLabelString(self.rootItems.desc2, gameConfig.strings:string_common("poolingServerGift", 8), 63)
    ui.setLabelString(self.rootItems.desc3, gameConfig.strings:string_common("poolingServerGift", 9), 63)
    self.rootItems.descSpecial2:setString(gameConfig.strings:string_common("poolingServerGift", 10))
    ui.setLabelString(self.rootItems.desc4, gameConfig.strings:string_common("poolingServerGift", 11), 63)
    ui.setLabelString(self.rootItems.desc5, gameConfig.strings:string_common("poolingServerGift", 12), 63)
    ui.setLabelString(self.rootItems.desc6, gameConfig.strings:string_common("poolingServerGift", 13), 63)

    local _list1 = {}
    table.insert(_list1, {node = self.rootItems.desc1})
    table.insert(_list1, {node = self.rootItems.descSpecial1})
    ui.setCCNodeListRight(_list1)

    local _list2 = {}
    table.insert(_list2, {node = self.rootItems.desc3})
    table.insert(_list2, {node = self.rootItems.descSpecial2})
    table.insert(_list2, {node = self.rootItems.desc4})
    ui.setCCNodeListRight(_list2)

    local _list3 = {}
    table.insert(_list3, {node = self.rootItems.desc6})
    table.insert(_list3, {node = self.rootItems.time})
    ui.setCCNodeListRight(_list3)
end

function poolingServersGift.createAnimation(self)
    local _spineName = gamedata.config.generalanimation[tostring(self.activityTimeConfig.generalanimation)].name

    self.rootItems.generalNode:removeAllChildrenWithCleanup(true)
    self.npcSpine = CCSkeletonAnimation:create(_spineName.."/".._spineName..".json", _spineName.."/".._spineName..".atlas", 1)
    self.npcSpine:setAnimation("stand", true, 0)
    self.npcSpine:setScale(2.0)
    self.npcSpine:setPosition(0,0)
    self.rootItems.generalNode:addChild(self.npcSpine)
end

function poolingServersGift.reloadData(self, data)
    self.day = data.day
    self.data = self:createTempData(data.task)
    self.data = self:sortData(self.data)

    self:createTimer()
    if self.data then
        if not self.listTableView then
            self:createList()
        else
            self.listTableView:reloadData()
        end
    end
end

function poolingServersGift.createTempData(self, data)
    local _tempTable = {}

    for i = 1, table.getTableLength(data) do
        table.insert(_tempTable, data[tostring(i)])
    end

    return _tempTable
end

function poolingServersGift.sortData(self, data)
    for i = 1, table.getTableLength(data) do

        if data[i].status == 0 then
            if data[i].id < self.day + 1 then 
                data[i].wight = 400 + data[i].id
            else
                data[i].wight = 200 + data[i].id
            end
        elseif data[i].status == 1 then
            data[i].wight = 100 + data[i].id
        elseif data[i].status == 2 then
            data[i].wight = 300 + data[i].id
        end
    end

    table.sort(data, self.sortTable)

    return data
end

-- 按奖励状态排序
function poolingServersGift.sortTable(left, right)
    return left.wight < right.wight
end


function poolingServersGift.createTimer(self)
    local _diffTime = self:getDiffTime()
    if _diffTime and _diffTime > 0 then
        gameTimer:rigistTime("PoolingServersGift", _diffTime)

        if gameTimer.times["PoolingServersGift"] and gameTimer.times["PoolingServersGift"] > 0 then
            gameTimer:rigistTimeFunc("PoolingServersGift", function()
                if gameTimer.times["PoolingServersGift"] <= 0 then
                    ui.setLabelString(self.rootItems.time, ui.makeTimeDayText(gameTimer.times["PoolingServersGift"], "day"), 63)
                    
                    if gameTimer.times["PoolingServersGift"] then
                        gameTimer:UnrigistTimeFunc("PoolingServersGift")
                    end
                else
                    ui.setLabelString(self.rootItems.time, ui.makeTimeDayText(gameTimer.times["PoolingServersGift"], "day"), 63)
                end
            end)
        end
    end
end

function poolingServersGift.getDiffTime(self)
    -- 活动时间
    local _timediff = 0
    local _activityId = tostring(self.activityId)
    local _nowTime = gamedata:time()

    if self.rootItems.time then
        if gamedata.config.activity_time[_activityId]["open_type"] and
           gamedata.config.activity_time[_activityId]["open_type"] == 6 then 
            local _temp = os.date("*t", _nowTime)
            _timediff = 86400 * (gamedata.config.activity_time[_activityId]["continued_time"] - self.day) - _temp.hour * 3600 - _temp.min * 60 - _temp.sec
        else
            self.rootItems.time:setString("")
            self.rootItems.desc1:setString("")
        end
    end
    
    return _timediff
end

function poolingServersGift.createList(self)
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
                _cellCCB, _ccbDocumentControler = CCBReaderLoad("activityreward_new/poolingServerGift", nil, true, "poolingServerGift")
                _celldict[a2] = {cellCCB = _cellCCB, ccbDocumentControler = _ccbDocumentControler }
            else
                _first = false
                _cellCCB = _celldict[a2].cellCCB
                _ccbDocumentControler = _celldict[a2].ccbDocumentControler
            end

            self:setCell(_ccbDocumentControler, self.data[a1 + 1], a1 + 1)

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
        viewwidth = self.rootItems["listnode"]:getContentSize().width,
        viewheight = self.rootItems["listnode"]:getContentSize().height,
        dire = 1
    })
    self.rootItems["listnode"]:addChild(self.listTableView)
    self.listTableView:setTouchPriority(self.touchPriority - 1)
end

function poolingServersGift.setCell(self, item, data, index)
    local _suitGiftConfig = self.suitGiftConfig[tostring(data.id)]
    self:setReward(item, _suitGiftConfig.reward)
    self:setString(item, data, _suitGiftConfig)
    self:setBtn(item, data)
end

function poolingServersGift.setReward(self, item, rewards)
    local _t = ui.Split(rewards, ";")
    local _usedata = {}

    for k,v in pairs(_t) do
        if v ~= "" or v == nil then
            table.insert(_usedata, ui.Split(v, ","))
        end
    end

    local _len = table.getTableLength(_usedata)

    ui.setNewIcon(item, {cid = _usedata[1][1], num = _usedata[1][2]})
    
    local _cb = function()
        if self.cb and self:cb() then
            return
        end

        if _usedata[1][1] and _usedata[1][1] ~= "" then
            ui.setPopwindowByCid(_usedata[1][1])
        end
    end

    self:commonBtn(item, "i_button", _cb, self.touchPriority - 2, false)
end

function poolingServersGift.setString(self, item, data, config)
    local _title = config.title

    if data.id == (self.day + 1) then
        _title = _title.." "..gameConfig.strings:string_common("poolingServerGift", 14)
    end

    item.title:setString(_title)
    item.task:setString(config.task)

    if tonumber(data.num) > tonumber(config.condition) then
        data.num = tonumber(config.condition)
    end
    
    item.condition:setString(data.num.."/"..config.condition)
end

function poolingServersGift.setBtn(self, item, data)
    self:setBtnGray(item, data)
    self:setBtnString(item, data)
    self:setBtnEvent(item, data)
end

function poolingServersGift.setBtnGray(self, item, data)
    if data.status == 1 then
        ui.removeGray("CCControlButton", item.getbutton) 
    else
        ui.addGray("CCControlButton", item.getbutton) 
    end
end

function poolingServersGift.setBtnString(self, item, data)
    local _str = ""

    if data.status == 0 then
        if data.id < self.day + 1 then
            _str = gameConfig.strings:string_common("poolingServerGift", 15)
        else
            _str = gameConfig.strings:string_common("poolingServerGift", 3)
        end
    elseif data.status == 1 then
        _str = gameConfig.strings:string_common("poolingServerGift", 4)
    elseif data.status == 2 then
        _str = gameConfig.strings:string_common("poolingServerGift", 5)
    end

    ui.setLabelString(item.gettext, _str, 18)
end

function poolingServersGift.setBtnEvent(self, item, data)
    local _cb = function()
        if data.status == 1 then
            UIRequest({type = 6104, id = data.id})
        else

        end
    end

    self:commonBtn(item, "getbutton", _cb, self.touchPriority - 2, false)
end

-- 通用按钮
function poolingServersGift.commonBtn(self, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)
    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(touchPriority or (self.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return poolingServersGift