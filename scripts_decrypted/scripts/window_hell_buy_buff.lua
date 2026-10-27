--地狱副本购买buff界面
local hellBuyBuff = {
    root = nil,
    rootNode = nil,
    rootItems = nil,
    touchPriority = -102,
    data = nil,
    bossNum = 3,
    disPosition = 100,
}

-- 打开界面
function hellBuyBuff.open(self, touchPriority, data, callback)
    self.root = CCNode:create()

    self.touchPriority = touchPriority
    self.priceConfig = gamedata.config.buycount_price
    self.playerBuffConfig = gamedata.config.hell_playerBuff
    self.globalConfig = gamedata.config.global_kv
	self:initNode()
    self:initFixedString()
    self:initEvent()

    UIRequest({type = 6113, param = 0, gold = 0})

    return self.root
end

-- 初始化界面
function hellBuyBuff.initNode(self)
	self.rootNode, self.rootItems = CCBReaderLoad("copyhell/copyhell_buff", nil, true, "copyhell_buff")
    self.rootNode:setPosition(0, 0)
	self.root:addChild(self.rootNode)
end

-- 初始化文本
function hellBuyBuff.initFixedString(self)
    ui.setLabelString(self.rootItems.titleTxt, gameConfig.strings:string_common("hell", 5), 72)
    ui.setLabelString(self.rootItems.okTxt1, gameConfig.strings:string_common("hell", 10), 18)
    ui.setLabelString(self.rootItems.okTxt2, gameConfig.strings:string_common("hell", 10), 18)
    ui.setLabelString(self.rootItems.okTxt, gameConfig.strings:string_common("hell", 32), 18)
    ui.setLabelString(self.rootItems.refreshTxt, gameConfig.strings:string_common("hell", 11), 18)
    ui.setLabelString(self.rootItems.costTxt1, gameConfig.strings:string_common("hell", 12), 65)
    ui.setLabelString(self.rootItems.infoTxt, gameConfig.strings:string_common("hell", 13), 73)
end

-- 初始化点击事件
function hellBuyBuff.initEvent(self)
    self:initOkBtn1()
    self:initOkBtn2()
    self:initOkBtn()
    self:initRefreshBtn()
end

-- 初始化选择按钮1
function hellBuyBuff.initOkBtn1(self)
    local _callback = function()
        UIRequest({type = 6115, param = 1})
    end

    self:commonBtn("okBtn1", _callback)
end

-- 初始化选择按钮2
function hellBuyBuff.initOkBtn2(self)
    local _callback = function()
        UIRequest({type = 6115, param = 2})
    end

    self:commonBtn("okBtn2", _callback)
end

-- 初始化确认按钮
function hellBuyBuff.initOkBtn(self)
    local _cb = function()
        gameWindows:closeWindow("hellBuyBuff")
    end

    self:commonBtn("okBtn", _cb)
end

-- 初始化刷新按钮
function hellBuyBuff.initRefreshBtn(self)
    local _callback = function()
        local _cost = self:getCost()

        if GameScene.roleinfo.gold >= _cost then
            gameWindows:openWindow("hellRefresh", _cost)
        else
            runGamePrompt({msg = gameConfig.strings:string_common("hell", 15)})
        end
    end

    self:commonBtn("refreshBtn", _callback)
end

-- 刷新数据
function hellBuyBuff.reloadData(self, data)
    self.data = data.playerBuff
    printT(self.data)

    self.choose = 0

    if self.data.currentBuff == 0 then
        self:refreshUI(false)
    else
        self:refreshUI(true)
    end
end

-- 刷新UI
function hellBuyBuff.refreshUI(self, isChoose)
    self:refreshCost()
    self:refreshBtn(isChoose)
    self:refreshBuff(isChoose)
end

-- 获取价格
function hellBuyBuff.getCost(self)
    local _count = self.data.refreshCount
    local _tableCount =  table.getTableLength(self.priceConfig)
    _count = _count > _tableCount and _tableCount or _count

    local _cost = tonumber(self.priceConfig[tostring(_count)].hell_playerbuff_cost)

    return _cost
end

-- 刷新价格
function hellBuyBuff.refreshCost(self)
    local _cost = self:getCost()
    ui.setLabelString(self.rootItems.costTxt2, _cost, 65)
end

-- 刷新按钮显示
function hellBuyBuff.refreshBtn(self, isChoose)
    self.rootItems.okNode1:setVisible(not isChoose)
    self.rootItems.okNode2:setVisible(not isChoose)
end

-- 刷新buff界面
function hellBuyBuff.refreshBuff(self, isChoose)
    self:refreshBuffShow(isChoose)
    self:refreshBuffInfos()
end

-- 刷新buff显示自己的buff还是新buff
function hellBuyBuff.refreshBuffShow(self, isChoose)
    if isChoose then
        self.rootItems.buffNode1:setVisible(true)
        self.rootItems.buffNode2:setVisible(false)
        self.rootItems.buffNode1:setPositionX(0)
    else
        self.rootItems.buffNode1:setVisible(true)
        self.rootItems.buffNode2:setVisible(true)
        self.rootItems.buffNode1:setPositionX(-self.rootItems.buffNode2:getPositionX())
    end
end

-- 刷新buff信息
function hellBuyBuff.refreshBuffInfos(self)
    self:refreshBuffInfo(1)
    self:refreshBuffInfo(2)
end

-- 刷新buff信息
function hellBuyBuff.refreshBuffInfo(self, id)
    local _cid = self.data["buffCid"..id]
    if _cid > 0 then
        _cid = tostring(_cid)
        local _buffName = self.playerBuffConfig[_cid].desc
        local _buffValue = self.data["buffValue"..id]
        local _buffMaxValue = 0

        _buffMaxValue = self.playerBuffConfig[_cid]["maxValue"]

        -- if self.playerBuffConfig[_cid].showMethod == 0 then
            if self.playerBuffConfig[_cid].method == "percent" then
                _buffMaxValue = _buffMaxValue * 100
            elseif self.playerBuffConfig[_cid].method == "value" then
                _buffValue = _buffValue / 100
                _buffMaxValue = _buffMaxValue
            end
        -- elseif self.playerBuffConfig[_cid].showMethod == 1 then
        --     _buffValue = _buffValue / 100
        -- end

        _buffValue = math.floor(_buffValue + 0.5)
        _buffMaxValue = math.floor(_buffMaxValue + 0.5)
        setSpriteFrameByName(self.rootItems["buffImage"..id], self.playerBuffConfig[_cid].buffkind)

        if self.playerBuffConfig[_cid].kind == "0" then
            ui.setLabelString(self.rootItems["buffTxt"..id], _buffName.._buffValue.."%", 26)
            ui.setLabelString(self.rootItems["buffMaxTxt"..id], "("..gameConfig.strings:string_common("hell", 14).._buffMaxValue.."%)", 74)

            -- if self.playerBuffConfig[_cid].showMethod == 0 then
            --     ui.setLabelString(self.rootItems["buffTxt"..id], _buffName.._buffValue.."%", 26)
            --     ui.setLabelString(self.rootItems["buffMaxTxt"..id], "("..gameConfig.strings:string_common("hell", 14).._buffMaxValue.."%)", 74)
            -- elseif self.playerBuffConfig[_cid].showMethod == 1 then
            --     ui.setLabelString(self.rootItems["buffTxt"..id], _buffName.._buffValue, 26)
            --     ui.setLabelString(self.rootItems["buffMaxTxt"..id], "("..gameConfig.strings:string_common("hell", 14).._buffMaxValue..")", 74)
            -- end
        elseif self.playerBuffConfig[_cid].kind == "1" then
            ui.setLabelString(self.rootItems["buffTxt"..id], _buffName.._buffValue.."%", 27)
            ui.setLabelString(self.rootItems["buffMaxTxt"..id], "("..gameConfig.strings:string_common("hell", 14).._buffMaxValue.."%)", 74)
            
            -- if self.playerBuffConfig[_cid].showMethod == 0 then
            --     ui.setLabelString(self.rootItems["buffTxt"..id], _buffName.._buffValue.."%", 27)
            --     ui.setLabelString(self.rootItems["buffMaxTxt"..id], "("..gameConfig.strings:string_common("hell", 14).._buffMaxValue.."%)", 74)
            -- elseif self.playerBuffConfig[_cid].showMethod == 1 then
            --     ui.setLabelString(self.rootItems["buffTxt"..id], _buffName.._buffValue, 27)
            --     ui.setLabelString(self.rootItems["buffMaxTxt"..id], "("..gameConfig.strings:string_common("hell", 14).._buffMaxValue..")", 74)
            -- end
        end

        local _key_Ex = ""

        if id == 1 then
            _key_Ex = ""
        elseif id == 2 then
            _key_Ex = "_"..(id - 1)
        end

        self.rootItems["i_soulsprite".._key_Ex]:setVisible(false)
        self.rootItems["i_k_quality".._key_Ex]:setVisible(false)

        setSpriteFrameByName(self.rootItems["i_icon".._key_Ex], self.playerBuffConfig[_cid].icon)
        ui.setSpriteTextureRect(self.rootItems["i_icon".._key_Ex], 0, 0, 200, 200)
    end
end

function hellBuyBuff.close(self)
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil
end

function hellBuyBuff.commonBtn(self, btnName, callback)
    self.rootItems[btnName]:setSwallowsTouch(true)
    self.rootItems[btnName]:setTouchPriority(self.touchPriority - 1)
    self.rootItems[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return hellBuyBuff  6!  