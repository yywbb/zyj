--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 18/7/30
-- Time: 10:57
-- To change this template use File | Settings | File Templates.
--

local artifactWash = {
    touchPriority  = -101,
    data = nil,
    curSelectState = 1,
    props = {}
}

function artifactWash.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("shenqi_new/shenqi_xilian", nil, true, "shenqi_xilian")
    self:initFixedString()
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.toppos = toppos
    self.rootItems.topnode:setPositionY(toppos)


    self.rootItems.selectNode:setPositionY(-60 - (self.toppos - 1250)/2)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        GameScene:shiftLayer("artifact","up")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.addbutton:addHandleOfControlEvent(function()
        gameWindows:openWindow("artifactWashEffectList")
    end, CCControlEventTouchUpInside)
    self.rootItems.addbutton:setSwallowsTouch(true)
    self.rootItems.addbutton:setTouchPriority(self.touchPriority)
    

       -- 添加神器spine
    self.rootItems.addArtifact:addHandleOfControlEvent(function()
        if gameConfig:checkBuildOpen(366) and GameScene:checkopenlevelbyId(366) then
            gameWindows:openWindow("artifactSelect",{showType = "checked",isShowAll = true},function(artifact)
                if artifact then
                    gameTouch:clickprofbytime(1)
                    printT(artifact," 选择的神器 ")
                    self:reload({data =artifact })
                end
            end)
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.addArtifact:setSwallowsTouch(true)
    self.rootItems.addArtifact:setTouchPriority(self.touchPriority)
    

    self:setStatus()

    -- 普通洗练
    self.rootItems.autobutton1:addHandleOfControlEvent(function()
        
        if not self.data then
            runGamePrompt({msg = gameConfig.strings:string_common("artifact",20)})
            return
        end

        self.curSelectState = 1
        self:setStatus()
        self:getBoreData()
    end, CCControlEventTouchUpInside)
    self.rootItems.autobutton1:setSwallowsTouch(true)
    self.rootItems.autobutton1:setTouchPriority(self.touchPriority)

        -- 高级洗练
    self.rootItems.autobutton2:addHandleOfControlEvent(function()
        
        if not self.data then
            runGamePrompt({msg = gameConfig.strings:string_common("artifact",20)})
            return
        end

        self.curSelectState = 2
        self:setStatus()

        self:getBoreData()
    end, CCControlEventTouchUpInside)
    self.rootItems.autobutton2:setSwallowsTouch(true)
    self.rootItems.autobutton2:setTouchPriority(self.touchPriority)

        -- 共鸣洗练
    self.rootItems.autobutton3:addHandleOfControlEvent(function()
        if not self.data then
            runGamePrompt({msg = gameConfig.strings:string_common("artifact",20)})
            return
        end

        local checkresult = self:checkGongmingCondition()
        if checkresult == 1 then
            runGamePrompt({msg = "共鸣洗炼至少需要两个技能"})
            return
        elseif checkresult == 2 then
            runGamePrompt({msg = "没有可以触发共鸣的技能"})
            return
        end

        self.curSelectState = 3
        self:setStatus()

        self:getBoreData()
    end, CCControlEventTouchUpInside)
    self.rootItems.autobutton3:setSwallowsTouch(true)
    self.rootItems.autobutton3:setTouchPriority(self.touchPriority)

    -- guide.controller:addComplete(396,function()
    --     UIRequest({type = 2882,opt=1,sysID=396})
    -- end)
    print(" ----   param    ------")
    printT(param)
    self:initGongmingConfig()
    self:reload(param)
    guide.controller:addComplete(464,function()
        UIRequest({type = 2882,opt=1,sysID=464})
    end)
end


--1 共鸣洗炼至少需要两个技能
function artifactWash.checkGongmingCondition(self)
    if not self.data then
        return -1
    end

    local skillnum = 0
    local isExitGongmingSkill = false

    for i=1,3 do
        if self.data["skill"..i] and self.data["skill"..i] > 0 then
            skillnum = skillnum + 1


            if self.gongmingConfig[self.data["skill"..i]] then
                isExitGongmingSkill = true
            end
        end
    end

    if skillnum < 2 then
        return 1
    end

    if not isExitGongmingSkill then
        return 2
    end

    return 0
end

function artifactWash.initGongmingConfig(self)
    if not self.gongmingConfig then
        self.gongmingConfig = {}

        for k,v in pairs(gamedata.config.resonance_attribute["1"]) do
            if not self.gongmingConfig[v.skills1] then
                self.gongmingConfig[v.skills1] = {}
            end
            self.gongmingConfig[v.skills1][v.skills2] = true

            if not self.gongmingConfig[v.skills2] then
                self.gongmingConfig[v.skills2] = {}
            end
            self.gongmingConfig[v.skills2][v.skills1] = true
        end

    end

    printT(self.gongmingConfig,"initGongmingConfig")
end

function artifactWash.setStatus(self)
    self.rootItems.autosprite1:setVisible(self.curSelectState == 1)
    self.rootItems.autosprite2:setVisible(self.curSelectState == 2)
    self.rootItems.autosprite3:setVisible(self.curSelectState == 3)

    if self.curSelectState == 1 then
        self.rootItems.tip:setString("")
    elseif self.curSelectState == 2 then
        self.rootItems.tip:setString("高级洗炼必出一个红色技能")
    elseif self.curSelectState == 3 then
        self.rootItems.tip:setString("共鸣洗炼必出一组共鸣技能")
    end

end

function artifactWash.reload(self,data)
    print(" ----   artifactWash.reload    ------")
        --  添加道具的显示
    if not data then
        -- 没有数据显示默认状态
        self.rootItems.notSkillDoc:setVisible(false)
        self.rootItems.addSp:setVisible(true)

        ui.addGray("CCControlButton",self.rootItems.doButton2)
        ui.addGray("CCControlButton",self.rootItems.doButton1)

        for i=1,3 do
            self.rootItems["notSkillNode"..i]:setVisible(false)
            self.rootItems["skillInfo"..i]:setVisible(true)
            self.rootItems["suoBtn"..i]:setVisible(false)
            self.rootItems["curAttr"..i]:setString(string.format(gameConfig.strings:string_common("artifact",164), i))
            self.rootItems["curAttr"..i.."_Value"]:setString(gameConfig.strings:string_common("artifact",165))
            
            self.rootItems["nextAttr"..i]:setString(string.format(gameConfig.strings:string_common("artifact",164), i))
            self.rootItems["nextAttr"..i.."_Value"]:setString(gameConfig.strings:string_common("artifact",165))

            self.rootItems["proba"..i]:setString("0")
            self.rootItems["probaFail"..i]:setString("0")
            -- ui.addGray("CCControlButton",self.rootItems["kaiKong"..i])

            self.rootItems["gongmingAttr1"]:setString("")
            self.rootItems["gongmingButton1"]:setVisible(false)
            self.rootItems["gongmingAttr2"]:setString("")
            self.rootItems["gongmingButton2"]:setVisible(false)
        end
        self:getBoreData()
        return
    else
        self.rootItems.notSkillDoc:setVisible(false)
        for i=1,3 do
            self.rootItems["suoBtn"..i]:setVisible(true)
        end
    end


    self.data = data.data

    self:setJewelDesc()
    printT(self.data,"  self.data  === ")

    

    ui.removeGray("CCControlButton",self.rootItems.doButton2)
    ui.removeGray("CCControlButton",self.rootItems.doButton1)
    local artifactConfig = gamedata.config.trump[tostring(self.data.cid)]

    local nameStr = artifactConfig.goldTrump > 0 and gameConfig.strings:string_common("equips",8).."·"..artifactConfig.name or artifactConfig.name
    
    if self.data.level1 == 0 then
        ui.setLabelString(self.rootItems.artifactName,nameStr,65)
    else
        ui.setLabelString(self.rootItems.artifactName,nameStr.."+"..self.data.level1,65)
    end

    self:setShowSkillGongming(1)
    self:setShowSkillGongming(2)

    self:updateSkillinfo()

end

function artifactWash.updateReload(self,data )
    printT(data.artifactData,"updateReload")
    self.data = data.artifactData
    if data.pos and data.curType == 1 then
        if self.data["skillHole"..data.pos] == 1 then
            runGamePrompt({msg = gameConfig.strings:string_common("artifact",166)})
        else
            runGamePrompt({msg = gameConfig.strings:string_common("artifact",167)})
        end
    end
    self:updateSkillinfo();
        
end

function artifactWash.setWashButton(self)

    local isHaveWashSkill = false
    if self.data.skill1_cid_bk > 0 or self.data.skill2_cid_bk > 0 or self.data.skill3_cid_bk > 0 then
        isHaveWashSkill = true
    end

    -- local rich = {
    --         {fontID = 1,content = "当前有橙色或红色技能未锁定，是否洗炼？",},
    --     }
    -- gameWindows:openWindow("confirm",{rich = rich}, cb)

    

        --替换
    self.rootItems.doButton2:addHandleOfControlEvent(function()
        printT(self.data,"替换之前")
        if self.data then
            if isHaveWashSkill then
                local isPopConfirm = false
                for i=1,3 do
                    local skillId = self.data["skill"..i]
                    local curSkillHole = self.data["skillHole"..i]

                    if skillId and skillId > 0 and curSkillHole ~= 2 then
                        local skillConfig = gamedata.config.breakskill[tostring(self.data["skill"..i])]
                        if skillConfig.quality >= 5 then
                            isPopConfirm = true
                            break
                        end
                    end
                end

                if isPopConfirm and (not self.isShieldReplace) then
                    gameWindows:openWindow("confirmWithShield",{des = gameConfig.strings:string_common("artifact",169)}, function (isShield,isOk)
                        --有洗炼技能变成取消
                        if isShield then
                            self.isShieldReplace = true
                        end

                        if isOk then
                            UIRequest({type = 5542,iid = self.data.iid})
                        end
                        
                    end)
                else
                    UIRequest({type = 5542,iid = self.data.iid})
                end 
            else
                runGamePrompt({msg = "暂无可替换技能"})
            end
        else
            runGamePrompt({msg = gameConfig.strings:string_common("artifact",20)})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton2:setSwallowsTouch(true)
    self.rootItems.doButton2:setTouchPriority(self.touchPriority)


    if isHaveWashSkill then
        ui.setLabelString(self.rootItems.doLab1,gameConfig.strings:string_common("artifact",163),19)
    else
        ui.setLabelString(self.rootItems.doLab1,gameConfig.strings:string_common("artifact",159),19)
    end
        -- 洗练
    self.rootItems.doButton1:addHandleOfControlEvent(function()
        if self.data then
            if isHaveWashSkill then

                local isPopConfirm = false
                for i=1,3 do
                    local skillId = self.data["skill"..i.."_cid_bk"]
                    local curSkillHole = self.data["skillHole"..i]
                    if skillId and skillId > 0 and curSkillHole ~= 2 then
                        local skillConfig = gamedata.config.breakskill[tostring(self.data["skill"..i.."_cid_bk"])]
                        if skillConfig.quality >= 5 then
                            isPopConfirm = true
                            break
                        end
                    end
                end

                if isPopConfirm and (not self.isShieldCancel) then
                    gameWindows:openWindow("confirmWithShield",{des = gameConfig.strings:string_common("artifact",170)}, function (isShield,isOk)
                        --有洗炼技能变成取消
                        if isShield then
                            self.isShieldCancel = true
                        end

                        if isOk then
                            UIRequest({type = 5544,iid = self.data.iid})
                        end
                        
                    end)
                else
                    UIRequest({type = 5544,iid = self.data.iid})
                end

            else
                for k,v in pairs(self.castTable) do
                    if self.props[tostring(v.cid)] and v.num > self.props[tostring(v.cid)] then
                        runGamePrompt({msg = "材料不足"})
                        return
                    end
                end

                local suonum = 0
                local opennum = 0
                for i=1,3 do
                    if self.data["skillHole"..i] == 2 then
                        suonum = suonum + 1
                    end

                    if self.data["skillHole"..i] > 0 then
                        opennum = opennum + 1
                    end
                end

                if suonum >= opennum then
                    runGamePrompt({msg = "未有可替换技能"})
                    return
                end


                if self.curSelectState == 3 then

                    --判断石否有锁定可以共鸣的技能
                    local count = 0
                    local isExitGongmingSkill = false
                    for i=1,3 do
                        if self.data["skillHole"..i] == 2 then
                            count = count + 1
                            if self.gongmingConfig[self.data["skill"..i]] then
                                isExitGongmingSkill = true
                            end
                        end
                    end
                    if count == 0 or not isExitGongmingSkill then
                        runGamePrompt({msg = "请锁定至少一条可以触发共鸣的技能"})
                        return
                    end

                    --判断神器石否已拥有全部共鸣技能
                    local ishaveall = true
                    for i=1,3 do
                        if self.data["skill"..i] and self.data["skill"..i] > 0 and self.gongmingConfig[self.data["skill"..i]] then
                            local gongmingSkills = self.gongmingConfig[self.data["skill"..i]]

                            for k,v in pairs(gongmingSkills) do
                                if self.data["skill1"] ~= k or self.data["skill2"] ~= k or self.data["skill3"] ~= k then
                                    ishaveall = false
                                    break
                                end
                            end
                        end

                    end

                    if ishaveall then
                        runGamePrompt({msg = "没有共鸣技能可替换"})
                        return
                    end

                    local skills = {}
                    --共鸣技能池
                    for i=1,3 do
                        if self.data["skill"..i] and self.data["skill"..i] > 0 and self.data["skillHole"..i] == 2 and self.gongmingConfig[self.data["skill"..i]] then
                            for k,v in pairs(self.gongmingConfig[self.data["skill"..i]]) do
                                skills[k] = true
                            end
                        end
                    end

                    --共鸣技能池去重

                    for i=1,3 do
                        if self.data["skill"..i] and self.data["skill"..i] > 0 then
                            if skills[self.data["skill"..i]] then
                                skills[self.data["skill"..i]] = nil
                            end
                        end
                    end

                    --类型跟拥有的有重复 需去重
                    local deleteSkills = {}
                    for k,v in pairs(skills) do
                        local config1 = gamedata.config.breakskill[tostring(k)]
                        
                        for i=1,3 do
                           if self.data["skill"..i] and self.data["skill"..i] > 0 and self.data["skillHole"..i] == 2 then
                                local config2 = gamedata.config.breakskill[tostring(self.data["skill"..i])]
                                print("deleteSkills",config1.name,config2.name)
                                if string.sub(config1.name,1,6) == string.sub(config2.name,1,6) then
                                    table.insert(deleteSkills,k)
                                end
                            end
                        end
                    end
                    for i,v in ipairs(deleteSkills) do
                        skills[v] = nil
                    end


                    if next(skills) then
                        gameWindows:openWindow("artifactWashConfirm",skills,function (  )
                            UIRequest({type = 5541,iid = self.data.iid,curType=self.curSelectState, xprops = self.castTable})
                        end)
                    else
                        runGamePrompt({msg = "没有共鸣技能可替换"})
                    end
                    return
                end

                UIRequest({type = 5541,iid = self.data.iid,curType=self.curSelectState, xprops = self.castTable})
            end
            
        else
            runGamePrompt({msg = "请添加神器"})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton2:setSwallowsTouch(true)
    self.rootItems.doButton2:setTouchPriority(self.touchPriority)
end

function artifactWash.updateSkillinfo(self)
    printT(self.data,"  updateSkillinfo  ")

    if self.curSelectState == 3 then
        local checkresult = self:checkGongmingCondition()
        if checkresult == 1 then
            runGamePrompt({msg = "共鸣洗炼至少需要两个技能"})
            runGamePrompt({msg = "已自动切换至普通洗炼"})
            self.curSelectState = 1
            self:setStatus()
        elseif checkresult == 2 then
            runGamePrompt({msg = "没有可以触发共鸣的技能"})
            runGamePrompt({msg = "已自动切换至普通洗炼"})
            self.curSelectState = 1
            self:setStatus()
        end
    end

    self:setWashButton()
    self:getBoreData()
    for i = 1,3 do
        local curSkillHole = self.data["skillHole"..i]
        if curSkillHole == 2 then
            -- self.rootItems["skillLock"..i]:setVisible(true)
            -- self.rootItems["skillunLock"..i]:setVisible(false)

            setControlButtonFrame(self.rootItems["suoBtn"..i], "suo_suo", "suo_suo","suo_suo")
        else
            -- self.rootItems["skillLock"..i]:setVisible(false)
            -- self.rootItems["skillunLock"..i]:setVisible(true)

            setControlButtonFrame(self.rootItems["suoBtn"..i], "suo_kai", "suo_kai","suo_kai")
        end

        if  tonumber(curSkillHole) > 0 then
            self.rootItems["notSkillNode"..i]:setVisible(false)
            self.rootItems["skillInfo"..i]:setVisible(true)
            if tonumber(self.data["skill"..i]) > 0  then
                local skillConfig = gamedata.config.breakskill[tostring(self.data["skill"..i])]
                -- self.rootItems["curAttr"..i]:setString(skillConfig.name);
                -- self.rootItems["curAttr"..i.."_Value"]:setString(skillConfig.desc);

                ui.setLabQuality(self.rootItems["curAttr"..i],skillConfig.name,(skillConfig.quality > 0 and skillConfig.quality or 1),29)
                ui.setLabQuality(self.rootItems["curAttr"..i.."_Value"],":"..skillConfig.desc,(skillConfig.quality > 0 and skillConfig.quality or 1),29)
            else
                ui.removeLabelStroke(self.rootItems["curAttr"..i])
                ui.removeLabelStroke(self.rootItems["curAttr"..i.."_Value"])
                self.rootItems["curAttr"..i]:setString(string.format(gameConfig.strings:string_common("artifact",164), i))
                self.rootItems["curAttr"..i.."_Value"]:setString(gameConfig.strings:string_common("artifact",165))

            end


            local isHaveWashSkill = false
            if self.data.skill1_cid_bk > 0 or self.data.skill2_cid_bk > 0 or self.data.skill3_cid_bk > 0 then
                isHaveWashSkill = true
            end

            if not isHaveWashSkill then
                ui.removeGray("CCControlButton",self.rootItems["suoBtn"..i])
            else
                ui.addGray("CCControlButton",self.rootItems["suoBtn"..i])
            end

            self.rootItems["suoBtn"..i]:addHandleOfControlEvent(function()
                if self.data then

                    if isHaveWashSkill then
                        -- runGamePrompt({msg = "当前有未替换的洗炼技能！"})
                    else
                        -- 锁定
                        if self.data["skillHole"..i] == 2 then
                            UIRequest({type = 5540,iid = self.data.iid,pos=i,curType = 3})
                        elseif self.data["skillHole"..i] == 1 then
                            UIRequest({type = 5540,iid = self.data.iid,pos=i,curType = 2})
                        end
                    end
                    
                else
                    print("锁定神器失败")
                end
            end, CCControlEventTouchUpInside)
            self.rootItems["suoBtn"..i]:setSwallowsTouch(true)
            self.rootItems["suoBtn"..i]:setTouchPriority(self.touchPriority)
        else
            self.rootItems["notSkillNode"..i]:setVisible(true)
            self.rootItems["skillInfo"..i]:setVisible(false)
            self.rootItems["hint_artifact"..i]:setVisible(false)

            ui.removeLabelStroke(self.rootItems["curAttr"..i])
            ui.removeLabelStroke(self.rootItems["curAttr"..i.."_Value"])
                
            self.rootItems["curAttr"..i]:setString(string.format(gameConfig.strings:string_common("artifact",164), i))
            self.rootItems["curAttr"..i.."_Value"]:setString(gameConfig.strings:string_common("artifact",165))
            self.rootItems["proba"..i]:setString(self.data["skillHoleProbs"..i].."%")
            -- 失败成功率加成
            local cof = gamedata.config.trump_config
            self.rootItems["probaFail"..i]:setString(((tonumber(cof["skill_promote_"..i].value) or 0)*100).."%")
        end

        local arrbk = self.data["skill"..i.."_cid_bk"]
        if tonumber(arrbk) > 0 then
            local skillConfig = gamedata.config.breakskill[tostring(arrbk)]

            ui.setLabQuality(self.rootItems["nextAttr"..i],skillConfig.name,(skillConfig.quality > 0 and skillConfig.quality or 1),29)
            ui.setLabQuality(self.rootItems["nextAttr"..i.."_Value"],":"..skillConfig.desc,(skillConfig.quality > 0 and skillConfig.quality or 1),29)
            -- self.rootItems["nextAttr"..i]:setString(skillConfig.name);
            -- self.rootItems["nextAttr"..i.."_Value"]:setString(skillConfig.desc);

        else
            ui.removeLabelStroke(self.rootItems["nextAttr"..i])
            ui.removeLabelStroke(self.rootItems["nextAttr"..i.."_Value"])

            self.rootItems["nextAttr"..i]:setString(string.format(gameConfig.strings:string_common("artifact",164), i))
            self.rootItems["nextAttr"..i.."_Value"]:setString(gameConfig.strings:string_common("artifact",165))

            -- self.rootItems["nextAttr"..i]:setColor()
            self.rootItems["nextAttr"..i]:setColor(ccc3(255,241,159))
            self.rootItems["nextAttr"..i.."_Value"]:setColor(ccc3(255,241,159))
        end
    end

end

--[[
    设置神器共鸣属性显示
    type 1 当前技能 2洗练技能
]]
function artifactWash.setShowSkillGongming(self,type)
    if not self.data then
        return
    end
    local data = {}
    if type == 1 then
        data = self.data
    elseif type == 2 then
        local artifact = table.copy(self.data)
        artifact.skill1 = artifact.skill1_cid_bk
        artifact.skill2 = artifact.skill2_cid_bk
        artifact.skill3 = artifact.skill3_cid_bk

        local activate1,activate2,unActivate1,unActivate2 = gameWindows.windows["artifactGongming"].module:dealData(artifact)
        
        for i=1,3 do
            if activate1[i] then
                artifact["resonanceActiveId"..i] = activate1[i].data.id
            else
                artifact["resonanceActiveId"..i] = 0
            end
        end

        --数量取最大值
        artifact.resonanceSkillNum = 0
        for i,v in ipairs(activate2) do
            if v.data.id > artifact.resonanceSkillNum then
                artifact.resonanceSkillNum = v.data.id
            end
        end

        printT(artifact,"artifact")
        printT(self.data,"self.data")
        data = artifact
    end

    printT(data,"setShowSkillGongming_"..type)
    --0没有红不显示 1有红未激活显示 2有红激活

    local showStatus = gameWindows.windows["artifactInfo"].module.isActiveResonance(data)
    print("showStatus",showStatus)

    if showStatus == 0 then
        self.rootItems["gongmingAttr"..type]:setString("")
        self.rootItems["gongmingButton"..type]:setVisible(false)
    elseif showStatus == 1 then
        self.rootItems["gongmingAttr"..type]:setString(gameConfig.strings:string_common("artifact",192))
        self.rootItems["gongmingButton"..type]:setVisible(true)
    elseif showStatus == 2 then
        self.rootItems["gongmingAttr"..type]:setString(gameConfig.strings:artifactResonanceAttr(data))
        self.rootItems["gongmingButton"..type]:setVisible(true)
    end

    self.rootItems["gongmingButton"..type]:addHandleOfControlEvent(function()
        gameWindows:openWindow("artifactGongming",data)
    end, CCControlEventTouchUpInside)
    self.rootItems["gongmingButton"..type]:setSwallowsTouch(true)
    self.rootItems["gongmingButton"..type]:setTouchPriority(self.touchPriority)
end

function artifactWash.setJewelDesc(self)
    -- self.rootItems.artifactSpine:removeAllChildrenWithCleanup(true)
    -- local totalLevel = 0
    -- for i = 1, 4 do
    --     if self.data["jewel"..i] > 0 then
    --         local config = gamedata.config.trump_gem[tostring(self.data["jewel"..i])]
    --         totalLevel = totalLevel + config.lv
    --     end
    -- end
    self.rootItems.addSp:setVisible(false)
    ui.setNewIcon(self.rootItems,self.data)
    -- local config = gamedata.config.trump[tostring(self.data.cid)]
    -- local shenqiSkeletonMeta = require"SkeletonShenqi"
    -- local skeleton = shenqiSkeletonMeta:init(config,totalLevel)
    -- skeleton:setPosition(0,-80)
    -- skeleton:setScale(0.7)
    -- skeleton:setAnimation("stand",true,0)
    -- self.rootItems.artifactSpine:addChild(skeleton.root or skeleton)
end

-- 获取洗练消耗的道具数量
function artifactWash.getBoreData(self)
    local isHighLevel = false


    if not self.data then
        self.castTable = ui.getIDandNUMs(gamedata.config.trump_config["washing_"..self.curSelectState.."_0"].value)
    else
        local count = 0
        for i=1,3 do
            if self.data["skillHole"..i] == 2 then
                count = count + 1
            end
        end
        if count == 0 then
            self.castTable = ui.getIDandNUMs(gamedata.config.trump_config["washing_"..self.curSelectState.."_0"].value)            
        elseif count == 1 then
            self.castTable = ui.getIDandNUMs(gamedata.config.trump_config["washing_"..self.curSelectState.."_1"].value)            
        elseif count == 2 then
            self.castTable = ui.getIDandNUMs(gamedata.config.trump_config["washing_"..self.curSelectState.."_2"].value)
        else
            self.castTable = ui.getIDandNUMs(gamedata.config.trump_config["washing_"..self.curSelectState.."_2"].value)
        end
    end

    local cids = {}
    --洗练消耗
    for i,v in ipairs(self.castTable) do
        table.insert(cids,v.cid)
    end
    --开孔消耗
    for i=1,3 do
        local arr = ui.getIDandNUMs(gamedata.config.trump_config["skill_position_"..i].value)
        for _i,v in ipairs(arr) do
            table.insert(cids,v.cid)
        end
    end

    printT(cids,"神器洗炼消耗_开孔道具消耗")
    UIRequest({type = 12001, order = 32002, cids = cids})
end

-- 道具消耗显示
function artifactWash.setUpPropNum( self,t)
    printT(t," artifactWash.setUpPropNum ")
    self.props = t   

    self.rootItems.itemNode1:removeAllChildrenWithCleanup(true)
    self.rootItems.itemNode2:removeAllChildrenWithCleanup(true)

    if not self.data then
        if #self.castTable == 1 then
            local cid1 = self.castTable[1].cid
            self:onCreateIcon(self.rootItems.itemNode1,{cid = cid1},0.8)
        elseif #self.castTable == 2 then
            local cid1 = self.castTable[1].cid
            local cid2 = self.castTable[2].cid
            self:onCreateIcon(self.rootItems.itemNode1,{cid = cid1})
            self:onCreateIcon(self.rootItems.itemNode2,{cid = cid2})
        end
        return
    end

    --设置洗炼消耗
    if #self.castTable == 1 then
        local cid1 = self.castTable[1].cid
        self:onCreateIcon(self.rootItems.itemNode1,{cid = cid1,num = t[tostring(cid1)]..'/'..self.castTable[1].num},0.8, t[tostring(cid1)]>=self.castTable[1].num)
    elseif #self.castTable == 2 then
        local cid1 = self.castTable[1].cid
        local cid2 = self.castTable[2].cid
        self:onCreateIcon(self.rootItems.itemNode1,{cid = cid1,num = t[tostring(cid1)]..'/'..self.castTable[1].num},0.8,t[tostring(cid1)]>=self.castTable[1].num)
        self:onCreateIcon(self.rootItems.itemNode2,{cid = cid2,num = t[tostring(cid2)]..'/'..self.castTable[2].num},0.8,t[tostring(cid2)]>=self.castTable[2].num)
    end

    --开孔消耗
    for i = 1,3 do
        local curSkillHole = self.data["skillHole"..i]
        
        if  tonumber(curSkillHole) > 0 then
            
        else
            -- 失败成功率加成
            local cof = gamedata.config.trump_config
            local arr = ui.getIDandNUMs(cof["skill_position_"..i].value)

            local needPropCid = arr[1].cid
            local needPropNum = arr[1].num or 0
            local havePropNum = t[tostring(needPropCid)] or 0

            local isPropEnough = havePropNum >= needPropNum

            local curNode,curItems = self:onCreateIcon(self.rootItems["itemContent"..i],{cid=needPropCid,num = havePropNum.."/"..needPropNum},0.58,isPropEnough)
            curItems.i_icon:setScale(0.9)
            curItems.i_k_quality:setVisible(false)
            curItems.i_quality:setVisible(false)

            local isCanOpen = true
            if i > 1 then
                if self.data["skillHole"..(i-1)] and self.data["skillHole"..(i-1)] <= 0 then
                    isCanOpen = false
                end
            end

            local isHaveWashSkill = false
            if self.data.skill1_cid_bk > 0 or self.data.skill2_cid_bk > 0 or self.data.skill3_cid_bk > 0 then
                isHaveWashSkill = true
            end


            if isCanOpen and isPropEnough and (not isHaveWashSkill) then
                ui.removeGray("CCControlButton",self.rootItems["kaiKong"..i])
                self.rootItems["hint_artifact"..i]:setVisible(true)
            else
                ui.addGray("CCControlButton",self.rootItems["kaiKong"..i])
                self.rootItems["hint_artifact"..i]:setVisible(false)
            end

            self.rootItems["kaiKong"..i]:addHandleOfControlEvent(function()
                if self.data then
                    print(self.data.iid,"self.data.cid = ")
                    print("开孔 ",i)

                    if not isPropEnough then
                        runGamePrompt({msg = "材料不足"})
                        return
                    end

                    if isHaveWashSkill then
                        runGamePrompt({msg = "当前洗炼池内有未替换的技能，不可开孔"})
                        return
                    end

                    if not isCanOpen then
                        runGamePrompt({msg = string.format(gameConfig.strings:string_common("artifact",168), i-1)})
                        return
                    end

                    local function cb(  )
                        -- 传入 ids [神器id，孔位（1，2，3）,操作（1开孔，2锁孔, 3解锁）]
                        UIRequest({type = 5540,iid =self.data.iid,pos = i,curType = 1})
                    end

                    if needPropCid == 20807 then
                        local rich = {
                            {fontID = 1,content = "是否消耗 ",},
                            {fontID = 11,content = "高级开孔符 ",},
                            {fontID = 1,content = "，进行开孔操作？",},
                        }
                        gameWindows:openWindow("confirm",{rich = rich}, cb)
                    else
                        cb()
                    end
                    
                else
                    runGamePrompt({msg = gameConfig.strings:string_common("artifact",20)})
                end

            end, CCControlEventTouchUpInside)
            self.rootItems["kaiKong"..i]:setSwallowsTouch(true)
            self.rootItems["kaiKong"..i]:setTouchPriority(self.touchPriority)
        end
        
    end
    
    -- ui.setNewIcon(self.rootItems,{cid = cid1,num = self.castTable[1].num..'/'..t[tostring(cid1)]},0)
    -- ui.setNewIcon(self.rootItems,{cid = cid2,num = self.castTable[2].num..'/'..t[tostring(cid2)]},1)
end

function artifactWash.onCreateIcon( self,itemNode,data,curScale,isEnough)
    -- body
    itemNode:removeAllChildrenWithCleanup(true)
   local curNode,curItems = CCBReaderLoad("icons/new_icon", nil, true, "shenqi_xilian")
    curNode:setPosition(0,0)
    curNode:setScale(curScale)
    itemNode:addChild(curNode)
    ui.setNewIcon(curItems,data)
    ui.setLabelString(curItems.i_num,data.num or "",isEnough and 13 or 24)

    curItems.i_button:addHandleOfControlEvent(function()
        print(data.cid)
        ui.setPopwindowByCid(data.cid)
    end, CCControlEventTouchUpInside)


    
    if isEnough then
    end
    return curNode,curItems
end

function artifactWash.clear(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.curSelectState = 1
    self.props = {}
end

function artifactWash.initFixedString(self)
    ui.setLabelString(self.rootItems.doLab2,gameConfig.strings:string_common("artifact",158),19)
    ui.setLabelString(self.rootItems.doLab1,gameConfig.strings:string_common("artifact",159),19)
    ui.setLabelString(self.rootItems.kaiKongLab1,gameConfig.strings:string_common("artifact",190),19)
    ui.setLabelString(self.rootItems.kaiKongLab2,gameConfig.strings:string_common("artifact",190),19)
    ui.setLabelString(self.rootItems.kaiKongLab3,gameConfig.strings:string_common("artifact",190),19)
    
end


return artifactWash  ��  