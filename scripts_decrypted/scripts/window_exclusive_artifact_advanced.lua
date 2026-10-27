local exclusiveArtifactAdvanced = {
    rootNode = nil,
    rootItems = nil,
}

function exclusiveArtifactAdvanced.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function exclusiveArtifactAdvanced.open(self, touchPriority, data, callback)
    self:initNode(touchPriority)
    self:initConfig()
    self:initEventBtn()
    self:reloadData(data)

    return self.rootNode
end

function exclusiveArtifactAdvanced.initNode(self, touchPriority)
    self.rootNode, self.rootItems = CCBReaderLoad("zhuanshu/zhuanshu_jinjie", nil, true, "zhuanshu_jinjie")
    self.touchPriority = touchPriority

    self.rootItems.titleNode:setVisible(false)
    self.rootItems.currentArtifactIconNode:setVisible(false)
    self.rootItems.nextArtifactIconNode:setVisible(false)
    self.rootItems.arrowNode:setVisible(false)
    self.rootItems.currentStepTxt:setString("")
    self.rootItems.nextStepTxt:setString("")
    self.rootItems.upStatusTxt:setString("")
    self.rootItems.nextStatus1:setString("")
    self.rootItems.nextStatus2:setString("")
    self.rootItems.nextStatus3:setString("")
    self.rootItems.skillIcon:setVisible(false)
    self.rootItems.skillName:setString("")
    -- self.rootItems.skillDesc:setString("")
end

function exclusiveArtifactAdvanced.initConfig(self)
    self.shenqiConfig = gamedata.config.shenqi
    self.shenqiEvolveConfig = gamedata.config.shenqi_evolve
    self.skillConfig = gamedata.config.skill
    self.combSkillConfig = gamedata.config.combskill
end

function exclusiveArtifactAdvanced.initEventBtn(self)
    self:initCloseBtn()
end

function exclusiveArtifactAdvanced.initCloseBtn(self)
    local _cb = function()
        gameWindows:closeWindow("exclusiveArtifactAdvanced")
    end

    self:commonBtn(self.rootItems, "closeBtn", _cb)
end

function exclusiveArtifactAdvanced.reloadData(self, data)
    self.currentGeneral = data.general
    self.currentShenqiConfig = self.shenqiConfig[tostring(self:getCurrentLevel())]
    self.nextShenqiConfig = self.shenqiConfig[tostring(self:getNextLevel())]
    self.currentShenqiEvolveConfig = ui.getExclusiveConfigByCid(self.currentGeneral.cid)

    self:getSkillOrCombSkillId()
    self.animationCount = 1
    -- self.animationTable = {
    --     [1] = self.showCurrentArtifactIconNode,
    --     [2] = self.setCurrentStepString,
    --     [3] = self.showArrowNode,
    --     [4] = self.showNextArtifactIconNode,
    --     [5] = self.setNextStepString,
    --     [6] = self.showTitleNode,
    --     [7] = self.setUpStatusString,
    --     [8] = self.setStatus1String,
    --     [9] = self.setStatus2String,
    --     [10] = self.setStatus3String,
    --     [11] = self.setNextSkillIcon,
    --     [12] = self.setSkillName,
    --     [13] = self.setSkillDesc,
    -- }

    self:showTitleNode()
    self:refreshAtifact()
    self:refreshStatus()
    self:refereshSkill()
    -- self:playAnimation()
end

function exclusiveArtifactAdvanced.refreshAtifact(self)
    self:showCurrentArtifactIconNode()
    self:setCurrentStepString()
    self:showArrowNode()
    self:showNextArtifactIconNode()
    self:setNextStepString()
end

function exclusiveArtifactAdvanced.refreshStatus(self)
    self:setUpStatusString()
    self:setStatus1String()
    self:setStatus2String()
    self:setStatus3String()
end

function exclusiveArtifactAdvanced.refereshSkill(self)
    self:setNextSkillIcon()
    self:setSkillName()
    self:setSkillDesc()
end

function exclusiveArtifactAdvanced.showCurrentArtifactIconNode(self)
    self.rootItems.currentArtifactIconNode:setVisible(true)
    local _iconName = self.currentShenqiEvolveConfig["icon"..self:getArtifactCurrentStep()]
    setSpriteFrameByName(self.rootItems.currentArtifactIcon, _iconName)
end

function exclusiveArtifactAdvanced.setCurrentStepString(self)
    ui.setLabelString(self.rootItems.currentStepTxt, self:getCurrentLevel()..gameConfig.strings:string_common("exclusiveArtifact", 12), 55)
end

function exclusiveArtifactAdvanced.showArrowNode(self)
    self.rootItems.arrowNode:setVisible(true)
end

function exclusiveArtifactAdvanced.showNextArtifactIconNode(self)
    self.rootItems.nextArtifactIconNode:setVisible(true)
    local _iconName = self.currentShenqiEvolveConfig["icon"..self:getArtifactNextStep()]
    setSpriteFrameByName(self.rootItems.nextArtifactIcon, _iconName)
end

function exclusiveArtifactAdvanced.setNextStepString(self)
    ui.setLabelString(self.rootItems.nextStepTxt, self:getNextLevel()..gameConfig.strings:string_common("exclusiveArtifact", 12), 55)
end

function exclusiveArtifactAdvanced.showTitleNode(self)
    self.rootItems.titleNode:setVisible(true)

end

function exclusiveArtifactAdvanced.setUpStatusString(self)
    ui.setLabelString(self.rootItems.upStatusTxt, gameConfig.strings:string_common("exclusiveArtifact", 25), 59)
end

function exclusiveArtifactAdvanced.setStatus1String(self)
    self.rootItems.nextStatus1:setString(gameConfig.strings:string_common("exclusiveArtifact", 20).." + "..self.nextShenqiConfig.atk)
end

function exclusiveArtifactAdvanced.setStatus2String(self)
    self.rootItems.nextStatus2:setString(gameConfig.strings:string_common("exclusiveArtifact", 21).." + "..self.nextShenqiConfig.def)
end

function exclusiveArtifactAdvanced.setStatus3String(self)
    self.rootItems.nextStatus3:setString(gameConfig.strings:string_common("exclusiveArtifact", 26).." + "..self.nextShenqiConfig.hp)
end

function exclusiveArtifactAdvanced.setNextSkillIcon(self)
    if self.skillId > 0 then
        self.rootItems.skillIcon:setVisible(true)
        ui.setNewIcon(self.rootItems, {cid = self.skillId})
    end
end

function exclusiveArtifactAdvanced.setSkillName(self)
    if self.skillId > 0 then
        if self.skillType == "skill" then
            ui.setLabelString(self.rootItems.skillName, self.skillConfig[tostring(self.skillId)].name, 55)
        elseif self.skillType == "combSkill" then
            ui.setLabelString(self.rootItems.skillName, self.combSkillConfig[tostring(self.skillId)].name, 55)
        end
    end
end

function exclusiveArtifactAdvanced.setSkillDesc(self)
    local _desc = ""
    if self.skillId > 0 then
        if self.skillType == "skill" then
            _desc = self.skillConfig[tostring(self.skillId)].skill_desc
        elseif self.skillType == "combSkill" then
            _desc = self.combSkillConfig[tostring(self.skillId)].skill_desc
        end
    end

    ui.createRichLabel({{fontID = 62, content = _desc},}, self.rootItems.skillDescNode, true, {min_line_dis = 3})
end

function exclusiveArtifactAdvanced.playAnimation(self)
    self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.1), CCCallFunc:create(function()
        self.animationTable[self.animationCount](self)
        self.animationCount = self.animationCount + 1
        
        if self.animationCount <= #self.animationTable then
            self:playAnimation()
        end
    end)))
end

function exclusiveArtifactAdvanced.getCurrentLevel(self)
    return self.currentGeneral.level4 or 0
end

function exclusiveArtifactAdvanced.getNextLevel(self)
    return self:getCurrentLevel() + 1
end

function exclusiveArtifactAdvanced.getArtifactCurrentStep(self)
    return self.shenqiConfig[tostring(self:getCurrentLevel())].evolve_lv
end

function exclusiveArtifactAdvanced.getArtifactNextStep(self)
    return self.shenqiConfig[tostring(self:getNextLevel())].evolve_lv
end

function exclusiveArtifactAdvanced.getSkillOrCombSkillId(self)
    local _skillId = self.currentShenqiEvolveConfig["show"..self:getArtifactNextStep()]

    if self.skillConfig[tostring(_skillId)] then
        self.skillId = _skillId
        self.skillType = "skill"
    elseif self.combSkillConfig[tostring(_skillId)] then
        self.skillId = _skillId
        self.skillType = "combSkill"
    else
        self.skillId = 0
        self.skillType = 0
    end
end

-- 通用按钮
function exclusiveArtifactAdvanced.commonBtn(self, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)
    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(touchPriority or (self.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return exclusiveArtifactAdvanced !  