--专属神器升级
local exclusiveArtifactUP = {
    cellSize = {width = 180, height = 180},
    rootNode = nil,
    rootItems = nil,
    touchPriority = -104,
}

function exclusiveArtifactUP.clear(self)
    gameTouch:UnrigistFunc("begin", "exclusiveArtifactUP")
    gameTouch:UnrigistFunc("end", "exclusiveArtifactUP")

    self.listTableView = nil
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function exclusiveArtifactUP.init(self, parent, toppos, param)
    self.general = param.general
    self:initNode(parent, toppos)
    self:initConfig()
    self:initEventBtn()
    self:initActivityScroll()
    self:initFixedString()
    self:setGeneralData()

    self:shiftPage(self:getInitPage(param.sid))
end

function exclusiveArtifactUP.initNode(self, parent, toppos)
    self.rootNode,self.rootItems = CCBReaderLoad("zhuanshu/zhuanshu_up", nil, true, "zhuanshu_up")
    self.rootNode:setPosition(-540, 0)
    parent:addChild(self.rootNode)

    self.rootItems.topNode:setPositionY(toppos)
    self.rootItems.middleNode:setPositionY(990 - (2436 - gameConfig.topposY) * 0.3)
end

function exclusiveArtifactUP.initConfig(self)
    self.shenqiConfig = gamedata.config.shenqi
    self.shenqiEvolveConfig = gamedata.config.shenqi_evolve
    self.skillConfig = gamedata.config.skill
    self.combSkillConfig = gamedata.config.combskill
    self.generalConfig = gamedata.config.general
end

function exclusiveArtifactUP.initEventBtn(self)

end

function exclusiveArtifactUP.initActivityScroll(self)
    local function touchBegin(pos)
        self.isscrolltouched = false
        self.touchbegin = {x = pos.x, y = pos.y}
    end

    local function touchEnd(pos)
        if math.abs(pos.x - (self.touchbegin and self.touchbegin.x or pos.x)) > 20 or math.abs(pos.y - (self.touchbegin and self.touchbegin.y or pos.y)) > 20 then
            self.isscrolltouched = false
        elseif self.rootItems["listscroll"] and ui.isTouched(self.rootItems["listscroll"], pos.x, pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("begin", "exclusiveArtifactUP", touchBegin)
    gameTouch:rigistFunc("end", "exclusiveArtifactUP", touchEnd)
end

function exclusiveArtifactUP.initFixedString(self)
    ui.setLabelString(self.rootItems.advancedEffectTxt, gameConfig.strings:string_common("exclusiveArtifact", 18), 58)
    ui.setLabelString(self.rootItems.advancedCostTxt, gameConfig.strings:string_common("exclusiveArtifact", 19), 58)
    ui.setLabelString(self.rootItems.advancedTxt, gameConfig.strings:string_common("exclusiveArtifact", 14), 19)
end

function exclusiveArtifactUP.setGeneralData(self)
    table.sort(self.general, self.sortTable)
end

function exclusiveArtifactUP.sortTable(left, right)
    if left.quality == right.quality then
        return left.sid < right.sid
    else
        return left.quality > right.quality
    end
end

function exclusiveArtifactUP.getInitPage(self, sid)
    for i, v in ipairs(self.general) do
        if v.sid == sid then
            return i
        end
    end
end

function exclusiveArtifactUP.shiftPage(self, page)
    self.page = page
    self:reloadData()
end

function exclusiveArtifactUP.reloadGeneralData(self, data)
    local _general = {}

    for k, v in pairs(self.currentGeneral) do
        _general[k] = v
    end

    gameWindows:openWindow("exclusiveArtifactAdvanced", {general = _general})

    if data and next(data) then
        self:setNewGeneralData(data)
        self:reloadData()
    end
end

function exclusiveArtifactUP.setNewGeneralData(self, data)
    for k,v in pairs(data) do
        self.general[self.page][k] = v
    end
end

function exclusiveArtifactUP.reloadData(self)
    self.currentGeneral = self.general[self.page]
    self.currentShenqiConfig = self.shenqiConfig[tostring(self:getCurrentLevel())]
    self.currentShenqiEvolveConfig = ui.getExclusiveConfigByCid(self.currentGeneral.cid)
    self.currentGeneralConfig = self.generalConfig[tostring(self.currentGeneral.cid)]
    self.costTable = {}
    self.needCostTable = {}
    
    if not self.listTableView then
        self:createList()
    else
        self.listTableView:reloadData()
    end
    
    self:setExclusiveArtifactIcon()
    self:checkMaxNodeIsShow()
    self:setShowNode()
end

function exclusiveArtifactUP.createList(self)
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
                _cellCCB, _ccbDocumentControler = CCBReaderLoad("slotsInfo/generalIcon", nil, true, "generalIcon")
                _celldict[a2] = {cellCCB = _cellCCB, ccbDocumentControler = _ccbDocumentControler }

                -- ui.tableviewAnimationH(self._listHandle, _cellCCB, self.cellSize.width, self.cellSize.height, a1)
            else
                _first = false
                _cellCCB = _celldict[a2].cellCCB
                _ccbDocumentControler = _celldict[a2].ccbDocumentControler
            end
            
            self:setCell(_ccbDocumentControler, self.general[a1 + 1], a1 + 1)

            _cellCCB:setScale(0.89)
            _cellCCB:setPosition(self.cellSize.width / 2, self.cellSize.height / 2)

            if _first then
                a2:addChild(_cellCCB)
            end

            _r = a2
        elseif fn == "numberOfCells" then
            _r = table.getTableLength(self.general)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end

        return _r
    end)

    self.listTableView = ui.createLuaTableView({
        handle = _listHandle,
        viewwidth = self.rootItems["listscroll"]:getContentSize().width,
        viewheight = self.rootItems["listscroll"]:getContentSize().height,
        dire = 0
    })
    self.rootItems["listscroll"]:addChild(self.listTableView)
    self.listTableView:setTouchPriority(self.touchPriority - 1)
end

function exclusiveArtifactUP.setCell(self, item, data, index)
    self:setGeneralIcon(item, data, index)
    self:setGeneralIconGray(item, data)
    self:initGeneralBtn(item, data, index)
end

function exclusiveArtifactUP.setGeneralIcon(self, item, data, index)
    item.selectEffect:removeAllChildrenWithCleanup(true)
    self:setSlotGeneralIcon(data, item)
    self:setGeneralEffect(item, index)
end

function exclusiveArtifactUP.setGeneralIconGray(self, item, data)
    if self:checkHaveExclusiveArtifact(data.quality) then
        ui.removeGray("CCSprite", item.g_quality)
        ui.removeGray("CCSprite", item.g_k_quality)
        ui.removeGray("CCSprite", item.g_icon)
    else
        ui.addGray("CCSprite", item.g_quality)
        ui.addGray("CCSprite", item.g_k_quality)
        ui.addGray("CCSprite", item.g_icon)
    end
end

function exclusiveArtifactUP.setSlotGeneralIcon(self, data, item)
    local _config = ui.IDconfig(data.cid) or {}

    item["g_lock"]:stopAllActions()
    item["g_lock"]:setVisible(false)
    item["g_icon"]:setVisible(true)
    item["g_status"]:setVisible(false)

    if data.skilllevel and _config.basic then
        _config.basic = _config.basic > gamedata.config.general_awaken[tostring(data.skilllevel)].basic and
                        _config.basic or gamedata.config.general_awaken[tostring(data.skilllevel)].basic 
    end

    if _config.quality == 5 and _config.basic >= 20 then
        setSpriteFrameByName(item["g_k_quality"], "b_iconk5_".._config.basic)
    else
        setSpriteFrameByName(item["g_k_quality"], "b_iconk"..(_config.quality or 1))
    end

    setSpriteFrameByName(item["g_quality"], "b_iconbg"..(_config.quality or 1))
    setSpriteFrameByName(item["g_icon"], _config.icon or "alpha")
    ui.setSpriteTextureRect(item["g_icon"], 0, 0, 150, 150)

    if item["g_name"] then
        item["g_name"]:setVisible(true)
        ui.setLabelString(item["g_name"], _config.name or "", _config.quality and 2 * (_config.quality - 1) or 1)
    end

    if item["g_lv2"] then
        item["g_lv2"]:setVisible(true)
        ui.setLabelString(item["g_lv2"], "+"..data.level2, 13)
    end

    if item["g_lv3"] then
        item["g_lv3"]:setVisible(true)
        ui.setLabelString(item["g_lv3"], "等级:"..data.level1, 13)
    end
end

function exclusiveArtifactUP.setGeneralEffect(self, item, index)
    if self.page == index then
        local _ccb, _ccItem = CCBReaderLoad("UIEffect/zhenrongxuanzhong/zhenrongxuanzhong", nil, true, "zhenrongxuanzhong")
        item.selectEffect:addChild(_ccb)
    end
end

function exclusiveArtifactUP.initGeneralBtn(self, item, data, index)
    local _cb = function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end

        if self:checkHaveExclusiveArtifact(data.quality) then
            self:shiftPage(index)
        end
    end

    self:commonBtn(item, "g_button", _cb, self.touchPriority - 2, false)
end

function exclusiveArtifactUP.checkHaveExclusiveArtifact(self, quality)
    return quality >= 6 and gameConfig:checkBuildOpen(363)
end

function exclusiveArtifactUP.setExclusiveArtifactIcon(self)
    setSpriteFrameByName(self.rootItems.artifactIcon, self.currentShenqiEvolveConfig["icon"..self:getArtifactCurrentStep()] or "alpha")
end

function exclusiveArtifactUP.checkMaxNodeIsShow(self)
    -- 神器max时，特殊界面
    self:setMaxNodeIsShow(self:checkIsMax())
end

function exclusiveArtifactUP.setMaxNodeIsShow(self, isShow)
    self.rootItems.maxNode:setVisible(isShow)
    self.rootItems.maxEffectNode:setVisible(isShow)
    self.rootItems.maxCostNode:setVisible(isShow)
    self.rootItems.normalNode:setVisible(not isShow)
    self.rootItems.normalEffectNode:setVisible(not isShow)
    self.rootItems.normalCostNode:setVisible(not isShow)
end

function exclusiveArtifactUP.setShowNode(self)
    if self:checkIsMax() then
        self:setMaxNode()
        self:setMaxEffectNode()
    else
        self:setNormalNodeNode()
        self:setNormalEffectNode()
        self:setNormalCostNode()
    end
end

function exclusiveArtifactUP.setNormalNodeNode(self)
    local _nextShenqiConfig = self.shenqiConfig[tostring(self:getNextLevel())]
    ui.setLabelString(self.rootItems.currentStepTxt, self:getCurrentLevel()..gameConfig.strings:string_common("exclusiveArtifact", 12), 55)
    ui.setLabelString(self.rootItems.currentStatus1, gameConfig.strings:string_common("exclusiveArtifact", 20).." + "..self.currentShenqiConfig.atk, 61)
    ui.setLabelString(self.rootItems.currentStatus2, gameConfig.strings:string_common("exclusiveArtifact", 21).." + "..self.currentShenqiConfig.def, 61)
    ui.setLabelString(self.rootItems.currentStatus3, gameConfig.strings:string_common("exclusiveArtifact", 26).." + "..self.currentShenqiConfig.hp, 61)
    ui.setLabelString(self.rootItems.nextStepTxt, self:getNextLevel()..gameConfig.strings:string_common("exclusiveArtifact", 12), 55)
    ui.setLabelString(self.rootItems.nextStatus1, gameConfig.strings:string_common("exclusiveArtifact", 20).." + ".._nextShenqiConfig.atk, 61)
    ui.setLabelString(self.rootItems.nextStatus2, gameConfig.strings:string_common("exclusiveArtifact", 21).." + ".._nextShenqiConfig.def, 61)
    ui.setLabelString(self.rootItems.nextStatus3, gameConfig.strings:string_common("exclusiveArtifact", 26).." + ".._nextShenqiConfig.hp, 61)
    ui.setLabelString(self.rootItems.currentDescTxt, gameConfig.strings:string_common("exclusiveArtifact", 22), 56)
    ui.setLabelString(self.rootItems.finalNameTxt, gameConfig.strings:string_common("exclusiveArtifact", 23)..self.currentGeneralConfig.name, 57)

    self:setDescMiddle()
end

function exclusiveArtifactUP.setDescMiddle(self)
    local _widthLeft = self.rootItems.currentDescTxt:getContentSize().width
    local _widthRight = self.rootItems.finalNameTxt:getContentSize().width
    local _sum = _widthLeft + _widthRight
    local _currentPosition = _widthLeft - _sum / 2

    self.rootItems.currentDescTxt:setPositionX(_currentPosition)
    self.rootItems.finalNameTxt:setPositionX(_currentPosition)
end

function exclusiveArtifactUP.setNormalEffectNode(self)
    local _skillId, _skillType = self:getSkillId()
    self:setSkillIcon(_skillId, _skillType)
    self:setUnlockSkillDesc(_skillId, _skillType)
    self:setNextSkillDesc(_skillId, _skillType)
end

function exclusiveArtifactUP.getSkillId(self)
    local _nextStep =  self:getArtifactNextStep()

    if _nextStep == 9999 then
        return 0, 0
    end

    local _skillId = self.currentShenqiEvolveConfig["show".._nextStep]

    if self.skillConfig[tostring(_skillId)] then
        return _skillId, "skill"
    elseif self.combSkillConfig[tostring(_skillId)] then
        return _combSkillId, "combSkill"
    else
        return 0, 0
    end
end

function exclusiveArtifactUP.setSkillIcon(self, _skillId, _skillType)
    ui.setNewIcon(self.rootItems, {cid = _skillId}, 2)
end

function exclusiveArtifactUP.setUnlockSkillDesc(self, _skillId, _skillType)
    local _skillName = ""

    if _skillType == "skill" then
        _skillName = self.skillConfig[tostring(_skillId)] and self.skillConfig[tostring(_skillId)].name or ""
    elseif _skillType == "combSkill" then
        _skillName = self.combSkillConfig[tostring(_skillId)] and self.combSkillConfig[tostring(_skillId)].name or ""
    end

    ui.setLabelString(self.rootItems.unlockSkillDesc, gameConfig.strings:exclusiveArtifactNextSkill(self:getArtifactNextStepLevel(), _skillName), 61)
end

function exclusiveArtifactUP.setNextSkillDesc(self, _skillId, _skillType)
    local _desc = ""

    if _skillType == "skill" then
        _desc = self.skillConfig[tostring(_skillId)] and self.skillConfig[tostring(_skillId)].skill_desc or ""
    elseif _skillType == "combSkill" then
        _desc = self.combSkillConfig[tostring(_skillId)] and self.combSkillConfig[tostring(_skillId)].skill_desc or ""
    end

    ui.createRichLabel({{fontID = 62, content = _desc},}, self.rootItems.skillUpDescNode, true, {min_line_dis = 3})

    -- self.rootItems.skillUpDesc:setString(_desc)
end

function exclusiveArtifactUP.setNormalCostNode(self)
    self:setCostIcon()
    self:setNeedGeneralLevel()
    self:setAdvancedBtn()
end

function exclusiveArtifactUP.setCostIcon(self)
    local _cost = self.shenqiConfig[tostring(self:getNextLevel())].lv_cost

    local _t = ui.Split(_cost, ";")
    local _usedata = {}
    local _costTable = {}

    for k,v in pairs(_t) do
        if v ~= "" or v == nil then
            table.insert(_usedata, ui.Split(v, ","))
        end
    end

    local _len = table.getTableLength(_usedata)

    for i = 1, _len do
        -- if _usedata[i][1] == "1000" then
        --     table.insert(self.costTable, GameScene.roleinfo.coin)
        -- elseif _usedata[i][1] == "1001" then
        --     table.insert(self.costTable, GameScene.roleinfo.gold)
        -- else
        --     table.insert(_costTable, _usedata[i][1])
        -- end
        table.insert(_costTable, tonumber(_usedata[i][1]))
        table.insert(self.needCostTable, {cid = _usedata[i][1], num = tonumber(_usedata[i][2])})
    end

    UIRequest({type = 12001, order = 10261, cids = _costTable})

    for i = 1, 2 do
        if i <= _len then
            local _key_Ex = ""
            
            if i == 1 then
                _key_Ex = ""
            else
                _key_Ex = "_"..(i-1)
            end

            self.rootItems["cost"..i]:setVisible(true)
            ui.setNewIcon(self.rootItems, {cid = _usedata[i][1], num = _usedata[i][2]}, i - 1)
            
            local _cb = function()
                if self.cb and self:cb() then
                    return
                end

                if _usedata[i][1] and _usedata[i][1] ~="" then
                    ui.setPopwindowByCid(_usedata[i][1])
                end
            end

            self:commonBtn(self.rootItems, "i_button".._key_Ex, _cb)
        else
            self.rootItems["cost"..i]:setVisible(false)
        end
    end
end

function exclusiveArtifactUP.refreshCostTable(self, data)
    for i, v in ipairs(self.needCostTable) do
        -- if v.cid ~= "1000" and v.cid ~= "1001" then
        --     table.insert(self.costTable, data[v.cid])
        self.costTable[v.cid] = data[v.cid] or 0
    end
end

function exclusiveArtifactUP.setNeedGeneralLevel(self)
    local _needGeneralLevel = self.shenqiConfig[tostring(self:getNextLevel())].general_lv
    self.rootItems.needGeneralLevel:setString(gameConfig.strings:exclusiveArtifactNeedGeneralLevel(_needGeneralLevel))
end

function exclusiveArtifactUP.setAdvancedBtn(self)
    local _cb = function()
        if self:checkNeedCost() then
            -- local _general = {}

            -- for k, v in pairs(self.currentGeneral) do
            --     _general[k] = v
            -- end
            
            -- gameWindows:openWindow("exclusiveArtifactAdvanced", {general = _general})
            UIRequest({type = 1026, iid = self.currentGeneral.iid})
        else
            runGamePrompt({msg = gameConfig.strings:string_common("exclusiveArtifact", 24)})
        end
    end

    self:commonBtn(self.rootItems, "advancedBtn", _cb)
end

function exclusiveArtifactUP.checkNeedCost(self)
    for i, v in ipairs(self.needCostTable) do
        if v.num >= self.costTable[v.cid] then
            return false
        end
    end

    return true
end

function exclusiveArtifactUP.setMaxNode(self)
    self.rootItems.maxStepTxt:setString(self:getCurrentLevel()..gameConfig.strings:string_common("exclusiveArtifact", 12))
    ui.setLabelString(self.rootItems.maxStatus1, gameConfig.strings:string_common("exclusiveArtifact", 20).." + "..self.currentShenqiConfig.atk, 61)
    ui.setLabelString(self.rootItems.maxStatus2, gameConfig.strings:string_common("exclusiveArtifact", 21).." + "..self.currentShenqiConfig.def, 61)
    ui.setLabelString(self.rootItems.maxStatus3, gameConfig.strings:string_common("exclusiveArtifact", 26).." + "..self.currentShenqiConfig.hp, 61)
end

function exclusiveArtifactUP.setMaxEffectNode(self)
    local _finalSkills = self.currentShenqiEvolveConfig.show
    local _usedata = {}
    local _skillid = 0
    local _combSkillId = 0

    if _finalSkills ~= "" or _finalSkills == nil then
        table.insert(_usedata, ui.Split(_finalSkills, ","))
        _skillid = _usedata[1][1]
        _combSkillId = _usedata[1][2]
    end

    local _skillName = self.skillConfig[tostring(_skillid)] and self.skillConfig[tostring(_skillid)].name or ""
    local _combSkillName = self.combSkillConfig[tostring(_combSkillId)] and self.combSkillConfig[tostring(_combSkillId)].name or ""

    self.rootItems.finalSkillTxt:setString(gameConfig.strings:string_common("exclusiveArtifact", 8).._skillName)
    self.rootItems.finalCombSkillTxt:setString(gameConfig.strings:string_common("exclusiveArtifact", 9).._combSkillName)
end

function exclusiveArtifactUP.getArtifactCurrentStep(self)
    return self.shenqiConfig[tostring(self:getCurrentLevel())].evolve_lv
end

function exclusiveArtifactUP.getArtifactNextStep(self)
    local _nextStepLevel = self.shenqiConfig[tostring(self:getCurrentLevel())].next_evolve_lv

    if _nextStepLevel ~= 9999 then
        return self.shenqiConfig[tostring(_nextStepLevel)].evolve_lv
    else
        return 9999
    end
end

function exclusiveArtifactUP.getArtifactNextStepLevel(self)
    return self.shenqiConfig[tostring(self:getCurrentLevel())].next_evolve_lv
end

function exclusiveArtifactUP.getCurrentLevel(self)
    return self.currentGeneral.level4 or 0
end

function exclusiveArtifactUP.getNextLevel(self)
    return self:getCurrentLevel() + 1
end

function exclusiveArtifactUP.checkIsMax(self)
    return self:getCurrentLevel() == table.getTableLength(self.shenqiConfig)
end

-- 通用按钮
function exclusiveArtifactUP.commonBtn(self, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)
    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(touchPriority or (self.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return exclusiveArtifactUP