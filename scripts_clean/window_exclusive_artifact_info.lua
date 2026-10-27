local exclusiveArtifactInfo = {
    rootNode = nil,
    rootItems = nil,
}

function exclusiveArtifactInfo.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function exclusiveArtifactInfo.open(self, touchPriority, data, callback)
    self:initNode(touchPriority)
    self:initConfig()
    self:initEventBtn()
    self:initFixedString()
    self:reloadData(data)

    return self.rootNode
end

function exclusiveArtifactInfo.initNode(self, touchPriority)
    self.rootNode, self.rootItems = CCBReaderLoad("zhuanshu/zhuanshu_info", nil, true, "zhuanshu_info")
    self.touchPriority = touchPriority
end

function exclusiveArtifactInfo.initConfig(self)
    self.shenqiConfig = gamedata.config.shenqi
    self.shenqiEvolveConfig = gamedata.config.shenqi_evolve
    self.skillConfig = gamedata.config.skill
    self.combSkillConfig = gamedata.config.combskill
end

function exclusiveArtifactInfo.initEventBtn(self)
    self:initCloseBtn()
end

function exclusiveArtifactInfo.initCloseBtn(self)
    local _cb = function()
        gameWindows:closeWindow("exclusiveArtifact")
    end

    self:commonBtn(self.rootItems, "closeBtn", _cb)
end

function exclusiveArtifactInfo.refresLevelUpBtn(self)
    local _cb = function()
        if self:checkNextLevel() then
            if self.currentGeneral.level1 >= self:getNextLevelInfo().general_lv then
                GameScene:shiftLayer("exclusiveArtifactUp", "up", {general = self.general, sid = self.sid})
            else
                runGamePrompt({msg = gameConfig.strings:string_common("exclusiveArtifact", 17)})
            end
        else 
            runGamePrompt({msg = gameConfig.strings:string_common("exclusiveArtifact", 16)})
        end
    end

    self:commonBtn(self.rootItems, "levelUpBtn", _cb)
end

function exclusiveArtifactInfo.initFixedString(self)
    ui.setLabelString(self.rootItems.titleTxt, gameConfig.strings:string_common("exclusiveArtifact", 1), 60)
    ui.setLabelString(self.rootItems.artifactTxt, gameConfig.strings:string_common("exclusiveArtifact", 2), 55)
    ui.setLabelString(self.rootItems.currentStatusTxt, gameConfig.strings:string_common("exclusiveArtifact", 3), 54)
    ui.setLabelString(self.rootItems.nextStatus, gameConfig.strings:string_common("exclusiveArtifact", 7), 54)
end

function exclusiveArtifactInfo.reloadData(self, data)
    self:refreshData(data)
    self:refreshIcon()
    self:refreshString()
    self:refresLevelUpBtn()
end

function exclusiveArtifactInfo.refreshData(self, data)
    self.sid = data.sid
    self.general = data.general
    self.currentGeneral = self.general[data.index]
    self.currentShenqiConfig = self.shenqiConfig[tostring(self:getCurrentLevel())]
    self.currentShenqiEvolveConfig = ui.getExclusiveConfigByCid(self.currentGeneral.cid)
end

function exclusiveArtifactInfo.refreshIcon(self)
    setSpriteFrameByName(self.rootItems.artifactIcon, self.currentShenqiEvolveConfig["icon"..self:getArtifactStep()] or "alpha")
end

function exclusiveArtifactInfo.refreshString(self)
    ui.setLabelString(self.rootItems.currentLevelTxt, self:getCurrentLevel()..gameConfig.strings:string_common("exclusiveArtifact", 12), 54)
    self.rootItems.artifactDesc:setString(self.currentShenqiEvolveConfig.desc)
    self.rootItems.statusTxt1:setString(gameConfig.strings:string_common("exclusiveArtifact", 4)..self.currentShenqiConfig.atk)
    self.rootItems.statusTxt2:setString(gameConfig.strings:string_common("exclusiveArtifact", 5)..self.currentShenqiConfig.def)
    self.rootItems.statusTxt3:setString(gameConfig.strings:string_common("exclusiveArtifact", 6)..self.currentShenqiConfig.hp)
    self.rootItems.skillTxt:setString(gameConfig.strings:string_common("exclusiveArtifact", 8)..self:getSkill(self:getArtifactStep()))
    self.rootItems.combSkillTxt:setString(gameConfig.strings:string_common("exclusiveArtifact", 9)..self:getCombSkill(self:getArtifactStep()))

    if self:checkNextLevel() then
        self.rootItems.needLevel:setString(gameConfig.strings:string_common("exclusiveArtifact", 10)..self.currentGeneral.level1.."/"..self:getNextLevelInfo().general_lv)
        ui.setLabelString(self.rootItems.levelUpTxt,gameConfig.strings:string_common("exclusiveArtifact", 14),18)
    else
        self.rootItems.needLevel:setString("")
        ui.setLabelString(self.rootItems.levelUpTxt,gameConfig.strings:string_common("exclusiveArtifact", 15),18)
    end
end

function exclusiveArtifactInfo.getArtifactStep(self)
    return self.shenqiConfig[tostring(self:getCurrentLevel())].evolve_lv
end

function exclusiveArtifactInfo.getSkill(self, step)
    local _skillId = self.currentShenqiEvolveConfig["skillid"..step]

    if _skillId == 0 then
        return "--"
    else
        return self.skillConfig[tostring(_skillId)].name
    end
end

function exclusiveArtifactInfo.getCombSkill(self, step)
    local _combSkillId = self.currentShenqiEvolveConfig["combskill"..step]

    print(_combSkillId)
    if _combSkillId == 0 then
        return "--"
    else
        return self.combSkillConfig[tostring(_combSkillId)].name
    end
end

function exclusiveArtifactInfo.checkNextLevel(self)
    return (self.currentGeneral.level4 or 0) < table.getTableLength(self.shenqiConfig)
end

function exclusiveArtifactInfo.getNextLevelInfo(self)
    return self.shenqiConfig[tostring(self:getCurrentLevel() + 1)]
end

function exclusiveArtifactInfo.getCurrentLevel(self)
    return self.currentGeneral.level4 or 0
end

-- 通用按钮
function exclusiveArtifactInfo.commonBtn(self, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)
    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(touchPriority or (self.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return exclusiveArtifactInfo