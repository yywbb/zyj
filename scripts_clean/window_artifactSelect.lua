--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/6/14
-- Time: 14:33
-- To change this template use File | Settings | File Templates.
--


local artifactSelect = {
    rootNode = nil,
    rootItems = nil,
    cellNorSize = {x=980,y=220},
    cellDelSSize = {x = 980,y = 860},
    cellDelSize = {x = 980,y = 860},
    artifactSelect = nil,
    selectArtifact = nil,
    selectType = "checked",
    isShowAll = false,
    unrecycleCell = {},
    labelHeight = 40,
    labelDemention = 0,
    labelP = -40,
    textNum = 24,
    _consumeStatus = false,
}

function artifactSelect.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("shenqi_new/tc_shenqiselect", nil, true, "tc_shenqiselect")
    self:initFixedString()
    --
    self.touchPriority = touchPriority
    self.selectItem = nil
    self.callback = callback
    self._consumeStatus = data.consumeStatus
    self._noInfoLook = data.noInfoLook
    self._noLock = data.noLock


    if data.data then
        self.hasSelect = data.data.hasSelect or {}
    else
        self.hasSelect = {}
    end
    --
    self.rootItems.closeBtn:addHandleOfControlEvent(function()
        gameWindows:closeWindow("artifactSelect")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeBtn:setSwallowsTouch(true)
    self.rootItems.closeBtn:setTouchPriority(self.touchPriority)
    --
    self.selectType = data.showType and data.showType or self.selectType

   print("--------------------------------")

    --阵容打开更换 需要加卸载功能
    self.disboardArtifact = data.disboardArtifact

    self.isShowAll = data.isShowAll or false
    self:getArtifactDatas(data.data)
    return self.rootNode
end

function artifactSelect.getArtifactDatas(self,data)
    if data and data.artifacts then
        self:initData(data)
        return
    end
    if not GameScene.layers["artifactList"].module.artifactData then 
        GameScene:addUpdate(10032)
    end
    if GameScene:checkUpdate(10032) then
        return
    end

    self:reloadData()
end

function artifactSelect.reloadData(self,t)

    local artifactDatas 
    local artifacts = {}

    if self.disboardArtifact then

        printT(self.disboardArtifact,"disboardArtifact")
        artifacts[1] = self.disboardArtifact
    end

    if self.selectType == "checked" or self.selectType == "checked1" then
        artifactDatas = GameScene.layers["artifactList"].module.artifactData.checked

        for i = 1,#artifactDatas do
            -- 是否显示已经上阵的神器
            if self.isShowAll == false then
                if not artifactDatas[i].generalcid then
                    artifacts[#artifacts + 1] = artifactDatas[i]
                end
            else
                artifacts[#artifacts + 1] = artifactDatas[i]
            end
        end

    else
        artifactDatas = GameScene.layers["artifactList"].module.artifactData.unChecked
        artifacts = artifactDatas
    end
    
    

    printT(artifacts,"reloadData")
    self:initData({artifacts = artifacts,hasSelect = self.hasSelect})
end

function artifactSelect.lockCallback(self,t)
    --神器加锁数据 无需重新排序
    for i,v in ipairs(self.artifacts) do
        if v.iid == t.artifactSid then
            v.isLockState = t.isLock
            break
        end
    end
    self.ListTableView:reloadData()
end

function artifactSelect.initData(self,data)
    local addedIids = {}
    for i = 1,3 do
        if not self.hasSelect[i] then
           
        else
            addedIids[self.hasSelect[i].iid] = true
        end
    end

    printT(data,"artifactSelect.initData")

    local useArtifacts = {}

    for i = 1,#data.artifacts do
        local artifact = data.artifacts[i]
        if not addedIids[artifact.iid] then
            useArtifacts[#useArtifacts + 1] = artifact

            if self._consumeStatus then
                artifact.consumeStatus = artifactSelect.consumeStatus(artifact)
            end

        end
    end
  


   
    if self._consumeStatus then
        artifactSelect.consumeSort(useArtifacts)
    end

    printT(useArtifacts,"self.artifacts")
    self.artifacts = useArtifacts

    self.rootItems.noArtifactTip:setVisible(false)
    self.rootItems.noArtifactTip1:setVisible(false)
    self.rootItems.noArtifactTip2:setVisible(false)
    if #self.artifacts == 0 then
        self.rootItems.goToCast:setVisible(true)
        self.rootItems.goToCast:addHandleOfControlEvent(function()
            GameScene:shiftLayer("artifactCreate","up")
        end, CCControlEventTouchUpInside)
        self.rootItems.goToCast:setSwallowsTouch(true)
        self.rootItems.goToCast:setTouchPriority(self.touchPriority)

        if self.selectType == "checked" then
            self.rootItems.noArtifactTip:setVisible(true)
        elseif self.selectType == "checked1" then
            self.rootItems.noArtifactTip1:setVisible(true)
        else
            self.rootItems.noArtifactTip2:setVisible(true)
        end
    else

        self.rootItems.goToCast:setVisible(false)
        if self.ListTableView then
            self.ListTableView:reloadData()
        else
            self:createList()
        end
    end
end

function artifactSelect.initFixedString(self)
    ui.setLabelString(self.rootItems.title,gameConfig.strings:string_common("artifact",19),65)
end

function artifactSelect.setAttrStr(self,artifact,labN1,labN2,lab1,lab2)
    local config = gamedata.config:getConfigByName("trump")[tostring(artifact.cid)]
    local type1 = gameConfig.strings.attr_type[config.attr1]
    local type2 = gameConfig.strings.attr_type[config.attr2]

    local num1 = "+"..(artifact.attr1)*(config.attr1Type == "value" and 1 or 1)..(config.attr1Type == "value" and "" or "%")
    local num2 = "+"..(artifact.attr2)*(config.attr2Type == "value" and 1 or 1)..(config.attr2Type == "value" and "" or "%")
    labN1:setString(type1)
    labN2:setString(type2)
    lab1:setString(num1)
    lab2:setString(num2)
end

--消耗排序
function artifactSelect.consumeSort(artifacts,isstreng)
    local sortFunc = function (a,b)
        if a.consumeStatus ~= b.consumeStatus then
            return a.consumeStatus < b.consumeStatus
        end

        return a.score < b.score
    end

    local sortFunc2 = function (a,b)
        if a.consumeStatus ~= b.consumeStatus then
            return a.consumeStatus < b.consumeStatus
        end

        return a.level1 > b.level1
    end

    if not isstreng then
        table.sort(artifacts,sortFunc)
    else
        table.sort(artifacts,sortFunc2)
    end    
end

--0 可消耗 1 锁定 2 强化 3 点化 4 镶嵌有宝石 5 宝石孔>1
function artifactSelect.consumeStatus(artifact,isstreng)

    if artifact.isLockState == 1 then
        return 1
    end

    if isstreng then
        return 0
    end    


    if artifact.level1 > 0 then
        return 2
    end
    -- if "点化" then
    --     return 3
    -- end

    local isHaveJewel = false
    for i=1,4 do
        if artifact["jewel"..i] > 0 then
            isHaveJewel = true
        end
    end
    if isHaveJewel then
        return 4
    end

    local kongNum = 0
    for i=1,4 do
        if artifact["jewel"..i] >= 0 then
            kongNum = kongNum + 1
        end
    end

    if kongNum > 1 then
        return 5
    end

    return 0
end


function artifactSelect.setNormal(self,items,data,callFunc,isDetal,index,totalSize,listNode,notShowInfo,consumeFilter,isstreng)
    
    --设置神器技能等级显示
    ui.showArtifactSkillNum(items,data)

    local config = gamedata.config:getConfigByName("trump")[tostring(data.cid)]
    ui.setNewIcon(items,{cid = data.cid,ishigh = config.goldTrump},0)
    items["i_button"]:addHandleOfControlEvent(function()

        if (not notShowInfo) and (not self._noInfoLook) then
            if data.isChecked > 0 then
                gameWindows:openWindow("artifactInfo",{artifactData = data,fromLayer = self.layerName},nil)
            else
                gameWindows:openWindow("artifactSInfo",{title = gameConfig.strings:string_common("artifact",27),artifact = data},nil)
            end
        end
        
    end, CCControlEventTouchUpInside)
    items["i_button"]:setTouchPriority(self.touchPriority - 1)
    --
    local nameStr = config.goldTrump > 0 and gameConfig.strings:string_common("equips",8).."·"..config.name or config.name

    if data.level1 > 0 then

        nameStr = nameStr.."+"..data.level1

    end
    ui.setLabelString(items.name,nameStr,9)
    --
    local playerStr = config.goldTrump > 0 and data.name..gameConfig.strings:string_common("artifact",35) or data.name..gameConfig.strings:string_common("artifact",36)
    -- ui.setLabelString(items.playerName,playerStr,81)
    --
    items.playerName:setString("")
    if data.isChecked > 0 then
        artifactSelect:setAttrStr(data,items.attrName1,items.attrName2,items.attr1,items.attr2)
    end
    if data.generalcid then
        if gamedata.config:getConfigByName("general")[tostring(data.generalcid)].name == gameConfig.strings:string_common("soul",6) then
            items.generalname:setString(gameConfig.strings:equipName(GameScene.roleinfo.name))
        else
            items.generalname:setString(gameConfig.strings:equipName(gamedata.config:getConfigByName("general")[tostring(data.generalcid)].name))
        end
    else
        items.generalname:setString("")
    end
    --
    if items.lockIcon then
        if data.isLockState == 1 then
            items.lockIcon:setVisible(true)
        else
            items.lockIcon:setVisible(false)
        end
    end

    items.fixed3:setVisible(data.isChecked == 0)
    items.attrNode:setVisible(data.isChecked > 0)
    items.equipedSp:setVisible(not data.generalcid and data.isChecked > 0)
    --
    items.detailSp:setRotation(isDetal and 180 or 0)
    --
    items.doButton:addHandleOfControlEvent(function()
        if data.isLockState == 1 and GameScene.layers["artifactSkillSwop"].show then
            runGamePrompt({msg = gameConfig.strings:string_common("artifact",186)})
            return
        end

       callFunc(data)
    end, CCControlEventTouchUpInside)
    items.doButton:setSwallowsTouch(true)
    items.doButton:setTouchPriority(self.touchPriority - 1)
    --
    local isBig = false
    if data.skill1 > 0 or data.skill2 > 0 or data.skill3 > 0 then
        isBig = true
    end
    -- local useSize = isBig and self.cellDelSSize.y or self.cellDelSize.y
    local useSize = self.cellDelSize.y
    items.detalBtn:setTouchPriority(self.touchPriority - 1)
    items.detalBtn:setSwallowsTouch(true)
    items.detalBtn:addHandleOfControlEvent(function()
        local location
        self.artifactSelect,location = ui.tableviewLocation(
            self.ListTableView,
            totalSize,
            index,
            listNode,
            self.artifactSelect,
            useSize,
            self.cellNorSize.y
        )
        self.ListTableView:reloadData()
        self.ListTableView:setLuaContentOffset(0,location)
    end, CCControlEventTouchUpInside)


    items.gongmingAttr:setString(gameConfig.strings:artifactResonanceAttr(data))

    if consumeFilter then
        local state = artifactSelect.consumeStatus(data,isstreng)
        print("consumeFilter",state)
        printT(data)
        if state > 0 then
            local cn_index = 176
            if gameWindows.windows["onceRecoin"].show then
                cn_index = 171
            end
            items.consumeState:setString(gameConfig.strings:string_common("artifact",cn_index + state - 1))

            if items.selectbg then
                ui.addGray("CCSprite",items.selectbg)
            end

            if items.selectBtn then
                items.selectBtn:setVisible(false)
            end
            

            if items.doButton then
                ui.addGray("CCControlButton",items.doButton)
            end
        else
            if items.selectbg then
                ui.removeGray("CCSprite",items.selectbg)
            end

            if items.selectBtn then
                items.selectBtn:setVisible(true)
            end

            if items.doButton then
                ui.removeGray("CCControlButton",items.doButton)
            end

            items.consumeState:setString("")
        end
    end
end


-- [INFO]  1550546234 setDetail
-- {
--     "skill3_cid_bk" = 0
--     "skill2_cid_bk" = 0
--     "score"         = 25476
--     "iid"           = 6756
--     "skillHole3"    = -1
--     "jewel1"        = -1
--     "jewel3"        = -1
--     "skillHoleProbs3" = 20
--     "skill1_cid_bk" = 0
--     "skillHoleProbs1" = 0
--     "levelAttack"   = 0
--     "skill1"        = 9000465
--     "levelDef"      = 0
--     "generalcid"    = 10987
--     "cid"           = 110001
--     "attr2"         = 1
--     "skill3"        = 0
--     "jewel2"        = -1
--     "skillHole1"    = 1
--     "skillHoleProbs2" = 20
--     "jewel4"        = -1
--     "isLockState"   = 0
--     "levelHP"       = 0
--     "skillHole2"    = 1
--     "level1"        = 0
--     "name"          = "S3-utggh"
--     "attr1"         = 16
--     "levelProbs"    = 0
--     "skill2"        = 9000430
--     "isChecked"     = 1
--     "sid"           = 1
-- } --[Table end]
function artifactSelect.setDetail(self,items,data,isCallFunc,isShowLock)
    -- local isBig = false
    -- if data.skill1 > 0 or data.skill2 > 0 or data.skill3 > 0 then
    --     isBig = true
    -- end
    printT(data,"setDetail")
    local artifactConfig = gamedata.config:getConfigByName("trump")[tostring(data.cid)]
    local artifactStrengthenConfig = nil

    if data.level1 > 0 then
        if artifactConfig.goldTrump == 0 then
            artifactStrengthenConfig = gamedata.config:getConfigByName("trump_strengthen")[tostring(artifactConfig.type)][tostring(data.level1)]
        else
            artifactStrengthenConfig = gamedata.config:getConfigByName("trump_Godstrengthen")[tostring(artifactConfig.type)][tostring(data.level1)]
        end

        items["attrValue1"]:setString(gameConfig.strings.attr_type["atk"].."+"..tostring(data.levelAttack or 0).."%")
        items["attrValue2"]:setString(gameConfig.strings.attr_type["def"].."+"..tostring(data.levelDef or 0).."%")
        items["attrValue3"]:setString(gameConfig.strings.attr_type["hp"].."+"..tostring(data.levelHP or 0).."%")
        
        items.noattr:setVisible(false)
    else
        items.noattr:setVisible(true)
        items["attrValue1"]:setString("")
        items["attrValue2"]:setString("")
        items["attrValue3"]:setString("")
        -- gameConfig.strings:attributeValue(config.attr,config.attrType,config.attrValue)
        -- gameConfig.strings:attributeValue(config.attr,config.attrType,config.attrValue)
        -- gameConfig.strings:attributeValue(config.attr,config.attrType,config.attrValue)
    end

    local skills = {}
    for i = 1,3 do
        if data["skill"..i] > 0 then
            skills[#skills + 1] = data["skill"..i]
        end
    end

    local totalHeight = artifactSelect:setAddedDesc(skills,items)


    print("totalHeight",totalHeight)
    items.skillNode:setPositionY(260 + totalHeight)
    items.jewelNode:setPositionY(260 + items.skillNode:getPositionY())

    local contentSize = {width = 1000,height = items.jewelNode:getPositionY()+50}
    items.container:setContentSize(CCSize(contentSize.width,contentSize.height))

    local scrollnode = tolua.cast(items.scrollnode, "CCScrollView")
    scrollnode:setContentOffsetInDuration(ccp(0,560 - contentSize.height),0)
    -- if isBig then
    --     --items.skillNode:setVisible(true)
    --     items.skillNode:setPositionY(335)
    --     items.jewelNode:setPositionY(595)
    --     items.backSp:setContentSize(CCSizeMake(960,680))
    --     items.teXingNode:setPositionY(-298)
    --     local skills = {}
    --     for i = 1,3 do
    --         if data["skill"..i] > 0 then
    --             skills[#skills + 1] = data["skill"..i]
    --         end
    --     end
    --     artifactSelect:setAddedDesc(skills,items)
    -- else
    --     --items.skillNode:setVisible(false)
    --     items.skillNode:setPositionY(335 - 180)
    --     items.jewelNode:setPositionY(595 - 180)
    --     items.backSp:setContentSize(CCSizeMake(960,680 - 180))
    --     items.teXingNode:setPositionY(-298 + 180)
    --     for i = 1,3 do
    --         items["skillName"..i]:removeAllChildrenWithCleanup(true)
    --         items["skill"..i]:removeAllChildrenWithCleanup(true)
    --         if i == 1 then
    --             items["skillName"..i]:setString("")
    --             ui.setLabelString(items["skill"..i],"                         "..gameConfig.strings:string_common("skill_Effect","once"),28)
    --         else
    --             items["skillName"..i]:setString("")
    --             items["skill"..i]:setString("")
    --         end
    --     end
    -- end

    -- items.goToT:addHandleOfControlEvent(function()
    --     gameWindows:openWindow("artifactEffectList")
    -- end, CCControlEventTouchUpInside)
    -- items.goToT:setSwallowsTouch(true)
    -- items.goToT:setTouchPriority(self.touchPriority - 1)

    for i = 1,4 do
        artifactSelect:setJewelIcon(items,data["jewel"..i],i)
        if isCallFunc then
            local key_Ex = i <= 1 and "" or "_"..(i - 1)
            items["i_button"..key_Ex]:addHandleOfControlEvent(function()

                if gameTouch.isScrollling then
                    return
                end

                if data["jewel"..i] <= 0 then
                    GameScene:shiftLayer("artifactMount","up",{artifact = data,})
                end
            end, CCControlEventTouchUpInside)
            -- items["i_button"..key_Ex]:setSwallowsTouch(true)
            items["i_button"..key_Ex]:setTouchPriority(self.touchPriority - 10)
            if data["jewel"..i] <= 0 then
                items["goToMount"..key_Ex]:setVisible(true)
            end
        end
    end

    --加锁功能
    if isShowLock and (not self._noLock) then
        items.lockNode:setVisible(true)
        if data.isLockState == 1 then
            ui.setLabelString(items.lockLab,gameConfig.strings:string_common("artifact",191),19)
        else
            ui.setLabelString(items.lockLab,gameConfig.strings:string_common("artifact",155),19)
        end
        items["suoBtn"]:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then
                return
            end
            -- 神器锁定逻辑
            local curLockState = 0
            if data.isLockState == 0 then
                curLockState = 1
            end
            UIRequest({type = 5518,cid = data.iid,isLock = curLockState})

        end, CCControlEventTouchUpInside)
        items["suoBtn"]:setTouchPriority(self.touchPriority - 10)
    else
        items.lockNode:setVisible(false)
    end
    
    items.goToT:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then
            return
        end
        gameWindows:openWindow("artifactEffectList")
    end, CCControlEventTouchUpInside)
    items.goToT:setTouchPriority(self.touchPriority - 10)
end

function artifactSelect.setJewelIcon(self,items,jewelData,number)
    local key_Ex = number <= 1 and "" or "_"..(number - 1)
    items["toMount"..key_Ex]:setVisible(false)
    
    items["goToMount"..key_Ex]:setVisible(false)
    items["suo"..key_Ex]:setVisible(jewelData < 0)
    items["i_notice"..key_Ex]:setVisible(false)
    if jewelData > 0 then
        local config = gamedata.config:getConfigByName("trump_gem")[tostring(jewelData)]
        setSpriteFrameByName(items["i_k_quality"..key_Ex], "b_iconk"..(config.quality and config.quality>1 and config.quality or 1))
        setSpriteFrameByName(items["i_quality"..key_Ex], "b_iconbg"..(config.quality and config.quality>1 and config.quality or 1))
        setSpriteFrameByName(items["i_icon"..key_Ex], config.icon and config.icon or "alpha")
        ui.setSpriteTextureRect(items["i_icon"..key_Ex],0,0,150,150)
        if config.quality >= 7 then
            ui.setLabelString(items["in_name"..key_Ex],config.name,213)
        else
            ui.setLabelString(items["in_name"..key_Ex],config.name,((config.quality and config.quality ~= 0) and config.quality or 1)*2-1)
        end
    else
        setSpriteFrameByName(items["i_k_quality"..key_Ex], "b_s_iconk1")
        setSpriteFrameByName(items["i_quality"..key_Ex], "b_iconbg8")
        setSpriteFrameByName(items["i_icon"..key_Ex], "alpha")
        if jewelData == 0 then
            ui.setLabelString(items["in_name"..key_Ex],gameConfig.strings:string_common("fixedString","mofu",1),28)
        else
            ui.setLabelString(items["in_name"..key_Ex],gameConfig.strings:string_common("moreCommon","weikaiqi"),28)
        end
    end
end

function artifactSelect.setAddedDesc(self,skills,items)
    local totalHeight = 0
    for i = 1,3 do
        items["skillName"..i]:removeAllChildrenWithCleanup(true)
        items["skill"..i]:removeAllChildrenWithCleanup(true)
        if  skills[i] and skills[i] > 0 then
            local skillConfig = gamedata.config:getConfigByName("breakskill")[tostring(skills[i])]
            local count = ui.getTextLength(skillConfig.desc)
            local length = math.ceil(count/self.textNum)
            items["skillName"..i]:setPositionY(self.labelP - totalHeight)
            items["skill"..i]:setPositionY(self.labelP - totalHeight)
            items["skill"..i]:setDimensions(CCSizeMake(630,length * self.labelHeight))
            ui.setLabelString(items["skillName"..i],skillConfig.name,(skillConfig.quality > 0 and skillConfig.quality or 1) * 2)
            ui.setLabelString(items["skill"..i],":"..skillConfig.desc,(skillConfig.quality > 0 and skillConfig.quality or 1) * 2)
            totalHeight = totalHeight + length * self.labelHeight + self.labelDemention
        else
            items["skillName"..i]:setString("")
            items["skill"..i]:setString("")
        end
    end
    return totalHeight
    -- if self.totalHeight > 228 then
    --     items.teXingNode:setVisible(false)
    -- else
    --     items.teXingNode:setVisible(true)
    -- end
end



function artifactSelect.createList(self)

    printT(self.artifacts,"artifactSelect_artifacts")
    

    -- if self.unrecycleCell.detailCell then
    --     self.unrecycleCell.detailCell.cell:release()
    -- end
    -- self.unrecycleCell = {}

    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then

        elseif fn == "hasFixedCellSize" then
            r = false
        elseif fn == "cellSizeForIndex" then
            if self.artifactSelect and self.artifactSelect == a1+1 then
                if self.artifacts[a1 + 1].skill1 > 0 or self.artifacts[a1 + 1].skill2 > 0 or self.artifacts[a1 + 1].skill3 > 0 then
                    r = CCSizeMake(self.cellDelSSize.x, self.cellDelSSize.y)
                else
                    r = CCSizeMake(self.cellDelSize.x, self.cellDelSize.y)
                end
            else
                r = CCSizeMake(self.cellNorSize.x, self.cellNorSize.y)
            end
        elseif fn == "isRecycle" then
            for k,v in pairs (self.unrecycleCell) do
                if a2 == v.cell then
                    print("unrecycleCELL ")
                    return false
                end
            end
            return true
        elseif fn == "cellAtIndex" then
            if self.artifactSelect and self.artifactSelect == a1+1 then
                local ccb, items,ccb1, items1
                if self.unrecycleCell.detailCell == nil then
                    a2 = CCTableViewCell:create()
                    ccb, items =  CCBReaderLoad("shenqi_new/cell_shenqiselect", nil, true, "cell_shenqiselect")
                    self:initCellFixedString(items)


                    ccb1, items1 =  CCBReaderLoad("shenqi_new/cell_shenqiselect_content", nil, true, "cell_shenqiselect_content")

                    items1.touchBtn:addHandleOfControlEvent(function()
                        
                    end, CCControlEventTouchUpInside)
                    items1.touchBtn:setSwallowsTouch(true)
                    items1.touchBtn:setTouchPriority(self.touchPriority - 2)

                    local scrollnode = tolua.cast(items1.scrollnode, "CCScrollView")
                    scrollnode:setTouchPriority(self.touchPriority - 3)
                    
                    self:initCellDetalFixedString(items1)
                    if self.artifacts[a1 + 1].skill1 > 0 or self.artifacts[a1 + 1].skill2 > 0 or self.artifacts[a1 + 1].skill3 > 0 then
                        ccb1:setPosition(self.cellNorSize.x/2, -self.cellDelSSize.y)
                    else
                        ccb1:setPosition(self.cellNorSize.x/2, -self.cellDelSize.y)
                    end
                    a2:addChild(ccb1)
                    ccb:setPosition(self.cellNorSize.x/2, -self.cellNorSize.y)
                    a2:addChild(ccb)

                    self.unrecycleCell.detailCell={cell = a2, ccb =ccb, items=items,ccb1 =ccb1, items1=items1}
                    self.unrecycleCell.detailCell.cell:retain()
                else
                    a2 = self.unrecycleCell.detailCell.cell
                    ccb = self.unrecycleCell.detailCell.ccb
                    items = self.unrecycleCell.detailCell.items
                    ccb1 = self.unrecycleCell.detailCell.ccb1
                    if self.artifacts[a1 + 1].skill1 > 0 or self.artifacts[a1 + 1].skill2 > 0 or self.artifacts[a1 + 1].skill3 > 0 then
                        ccb1:setPosition(self.cellNorSize.x/2, -self.cellDelSSize.y)
                    else
                        ccb1:setPosition(self.cellNorSize.x/2, -self.cellDelSize.y)
                    end
                    items1 = self.unrecycleCell.detailCell.items1
                end
                self:setNormal(items,self.artifacts[a1+1],function(data)

                    if self._consumeStatus and data.consumeStatus ~= 0 then
                        return
                    end
                    self.selectArtifact = data
                    if self.callback then
                        self.callback(self.selectArtifact)
                    end
                    gameWindows:closeWindow("artifactSelect")
                end,true,a1 + 1,#self.artifacts,self.rootItems.listscroll,self._consumeStatus,self._consumeStatus)

                if self.disboardArtifact and a1 == 0 then
                    self:disboardArtifactCellShow(items)
                else
                    ui.setLabelString(items.doLab,gameConfig.strings:string_common("fixedString","nightclub",4),19)
                end

                self:setDetail(items1,self.artifacts[a1+1],false,not self._consumeStatus)
            else
                local cellCCB,ccbDocumentControler = 0,0
                local first = true
                if not a2 then
                    a2 = CCTableViewCell:create()
                    cellCCB, ccbDocumentControler = CCBReaderLoad("shenqi_new/cell_shenqiselect", nil, true, "cell_shenqiselect")
                    self:initCellFixedString(ccbDocumentControler)


                    celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                else
                    first = false
                    cellCCB = celldict[a2].cellCCB
                    ccbDocumentControler = celldict[a2].ccbDocumentControler
                end

                cellCCB:setPosition(self.cellNorSize.x/2, -self.cellNorSize.y)

                self:setNormal(ccbDocumentControler,self.artifacts[a1+1],function(data)

                    print("setNormal_dobutton",self.filterLock,"data.isLockState")
                    if self._consumeStatus and data.consumeStatus ~= 0 then
                        return
                    end

                    self.selectArtifact = data
                    if self.callback then
                        self.callback(self.selectArtifact)
                    end
                    gameWindows:closeWindow("artifactSelect")
                end,false,a1 + 1,#self.artifacts,self.rootItems.listscroll,self._consumeStatus,self._consumeStatus)

                if self.disboardArtifact and a1 == 0 then
                    self:disboardArtifactCellShow(ccbDocumentControler)
                else
                    ui.setLabelString(ccbDocumentControler.doLab,gameConfig.strings:string_common("fixedString","nightclub",4),19)
                end


                if first then
                    a2:addChild(cellCCB)
                end
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = #self.artifacts
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listscroll:getContentSize().width,
        viewheight = self.rootItems.listscroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.listscroll:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(self.touchPriority)
end

--阵容点更换 第一个cell 卸下神器
function artifactSelect.disboardArtifactCellShow(self,items,callFunc)
    ui.setLabelString(items.doLab,"卸 下",19)
    items.doButton:addHandleOfControlEvent(function()
       if self.callback then
            self.callback(nil)
        end
        gameWindows:closeWindow("artifactSelect")
    end, CCControlEventTouchUpInside)
    items.doButton:setSwallowsTouch(true)
    items.doButton:setTouchPriority(self.touchPriority - 1)
end

function artifactSelect.initCellFixedString(self,cellItems)
    cellItems.fixed1:setString(gameConfig.strings:string_common("fixedString","equip",14))
    cellItems.fixed3:setString(gameConfig.strings:string_common("artifact",31))
    cellItems.fixed2:setString(gameConfig.strings:string_common("fixedString","equip",4))
    ui.setLabelString(cellItems.doLab,gameConfig.strings:string_common("fixedString","nightclub",4),19)
end

function artifactSelect.initCellDetalFixedString(self,cellItems)
    ui.setLabelString(cellItems.title1,gameConfig.strings:string_common("artifact",40),65)
    ui.setLabelString(cellItems.title2,gameConfig.strings:string_common("artifact",41),65)
    ui.setLabelString(cellItems.title3,gameConfig.strings:string_common("artifact",162),65)
end


function artifactSelect.close(self)



    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self._consumeStatus = false

    self.selectType = "checked"

    self.callback = nil

    self.artifactSelect = nil
    self.selectArtifact = nil

    self.disboardArtifact = nil

    if self.unrecycleCell.detailCell then
        self.unrecycleCell.detailCell.cell:release()
    end
    self.unrecycleCell = {}
    self.ListTableView = nil

end

return artifactSelect