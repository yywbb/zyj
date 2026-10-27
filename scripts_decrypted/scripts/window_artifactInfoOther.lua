--
-- Author: songyibo
-- Date: 2019-03-11 15:41:01
--


local artifactInfo = {
    rootNode = nil,
    rootItems = nil,
    receiveData = nil,

    labelHeight = 40,
    labelDemention = 0,
    labelP = -40,
    textNum = 24,
    artifactLockState = 0,
    tableview = nil,
}

function artifactInfo.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("shenqi_new/shenqi_info", nil, true, "shenqi_info")
    --
    self.touchPriority = touchPriority
    --
    self.rootItems.closeBtn:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("artifactInfoOther")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeBtn:setSwallowsTouch(true)
    self.rootItems.closeBtn:setTouchPriority(self.touchPriority)
    --
    self.rootItems.buttonGroup1:setVisible(false)
    self.rootItems.buttonGroup2:setVisible(true)

    self.rootItems.doNode7:setVisible(false)
    self.rootItems.doNode8:setPositionX(580)

    self:initFixedString()
    self:reload(data,callback)
    self:setJewelDesc()
    return self.rootNode
end

function artifactInfo.setPropNum(self,t)
    --开孔消耗
    for i=1,3 do
        print("artifactInfo.setPropNum",i)
        self:setKongInfo(i,t)
    end
end

function artifactInfo.getBoreData(self)

    --开孔消耗
    local cids = {}
    for i=1,3 do
        local arr = ui.getIDandNUMs(gamedata.config.trump_config["skill_position_"..i].value)
        for _i,v in ipairs(arr) do
            table.insert(cids,v.cid)
        end
    end

    printT(cids,"神器详情开孔道具消耗")
    UIRequest({type = 12001, order = 32003, cids = cids})
end

function artifactInfo.initFixedString(self)
    ui.setLabelString(self.rootItems.titleTxt,gameConfig.strings:string_common("artifact",7),65)
    ui.setLabelString(self.rootItems.fixed1,gameConfig.strings:string_common("artifact",34),71)
    ui.setLabelString(self.rootItems.fixed2,gameConfig.strings:string_common("artifact",143),71)
    ui.setLabelString(self.rootItems.fixed3,gameConfig.strings:string_common("artifact",145),71)
    ui.setLabelString(self.rootItems.fixed4,gameConfig.strings:string_common("artifact",74),71)
    -- ui.setLabelString(self.rootItems.fixed5,gameConfig.strings:string_common("artifact",9),71)
    -- ui.setLabelString(self.rootItems.fixed6,gameConfig.strings:string_common("artifact",10),71)
    -- 更换
    ui.setLabelString(self.rootItems.doLab1,gameConfig.strings:string_common("artifact",75),19)
    -- 洗练
    ui.setLabelString(self.rootItems.doLab2,gameConfig.strings:string_common("artifact",76),19)
    -- 镶嵌
    ui.setLabelString(self.rootItems.doLab3,gameConfig.strings:string_common("artifact",6),19)
    -- 锁定
    ui.setLabelString(self.rootItems.doLab4,gameConfig.strings:string_common("artifact",155),19)
    -- 强化
    ui.setLabelString(self.rootItems.doLab5,gameConfig.strings:string_common("artifact",154),19)

    -- 锁定
    ui.setLabelString(self.rootItems.doLab7,gameConfig.strings:string_common("artifact",155),19)
    -- 确认
    ui.setLabelString(self.rootItems.doLab8,"确认",19)
    
end

--0没有红不显示 1有红未激活显示 2有红激活
function artifactInfo.isActiveResonance(data)

    local showStatus = 0
    for i=1,3 do
        if tonumber(data["skill"..i]) > 0 then
            local skillConfig = gamedata.config.breakskill[tostring(data["skill"..i])]
            if skillConfig.quality >= 6 then
                showStatus = 1
                break
            end
        end
    end

    if (data.resonanceActiveId1 > 0) or (data.resonanceActiveId2 > 0) or (data.resonanceActiveId3 > 0) or (data.resonanceSkillNum > 1) then
        showStatus = 2
    end
    return showStatus
end


function artifactInfo.reload(self,data,callback)
    printT(data,"    artifactInfo.reload  ")

    ui.showArtifactSkillNum(self.rootItems,data.artifactData)
    
    self.callback = callback
    self.data = data.artifactData
    self.receiveData = data
    self.hasHint = 0
    local config = gamedata.config.trump[tostring(self.data.cid)]



    local nameStr = config.goldTrump > 0 and gameConfig.strings:string_common("equips",8).."·"..config.name or config.name
    if self.data.level1 > 0 then
        nameStr = nameStr.."+"..self.data.level1
    end
    ui.setLabelString(self.rootItems.name,nameStr,9)
    
    if artifactInfo.isActiveResonance(self.data) == 2 then
        self.rootItems.gongmingAttr:setString(gameConfig.strings:artifactResonanceAttr(self.data))
        self.rootItems.gongmingButton:setVisible(true)
        self.rootItems.gongmingButton:addHandleOfControlEvent(function()
            gameWindows:openWindow("artifactGongming",self.data)
        end, CCControlEventTouchUpInside)
        self.rootItems.gongmingButton:setSwallowsTouch(true)
        self.rootItems.gongmingButton:setTouchPriority(self.touchPriority)

    elseif artifactInfo.isActiveResonance(self.data) == 1 then
        self.rootItems.gongmingAttr:setString(gameConfig.strings:string_common("artifact",192))
        self.rootItems.gongmingButton:setVisible(true)
        self.rootItems.gongmingButton:addHandleOfControlEvent(function()
            gameWindows:openWindow("artifactGongming",self.data)
        end, CCControlEventTouchUpInside)
        self.rootItems.gongmingButton:setSwallowsTouch(true)
        self.rootItems.gongmingButton:setTouchPriority(self.touchPriority)
    else
        self.rootItems.gongmingAttr:setString("")
        self.rootItems.gongmingButton:setVisible(false)
    end
    

    self.rootItems.score:setString(data.artifactData.score)

    local playerStr1 = data.artifactData.name
    local playerStr2 = (config.goldTrump > 0 and gameConfig.strings:string_common("artifact",154) or "")
    local playerStr3 = (config.goldTrump > 0 and gameConfig.strings:string_common("artifact",144) or gameConfig.strings:string_common("artifact",36))
    local rich = {
        {fontID = 88,content = playerStr1,},
        {fontID = 123,content = playerStr2,},
        {fontID = 88,content = playerStr3,},
    }
    ui.createRichLabel(rich,self.rootItems.playerName,false)

    self.rootItems.desc:setString(config.desc)

    rich = {
        {fontID = (config.type == 1 and 123 or 88),content = gameConfig.strings:string_common("artifact",77).."/",},
        {fontID = (config.type == 2 and 123 or 88),content = gameConfig.strings:string_common("artifact",78).."/",},
        {fontID = (config.type == 3 and 123 or 88),content = gameConfig.strings:string_common("artifact",79),},
    }
    ui.createRichLabel(rich,self.rootItems.artifactType,false)

    local type1 = gameConfig.strings.attr_type[config.attr1]
    local type2 = gameConfig.strings.attr_type[config.attr2]

    local num1 = "+"..(self.data.attr1)*(config.attr1Type == "value" and 1 or 1)..(config.attr1Type == "value" and "" or "%")
    local num2 = "+"..(self.data.attr2)*(config.attr2Type == "value" and 1 or 1)..(config.attr2Type == "value" and "" or "%")
    ui.setLabelString(self.rootItems.attrN1,type1,88)
    ui.setLabelString(self.rootItems.attrN2,type2,88)
    self.rootItems.attr1:setString(num1)
    self.rootItems.attr2:setString(num2)
    self.rootItems.attr1:setPositionX(self.rootItems.attrN1:getPositionX() + self.rootItems.attrN1:getContentSize().width)
    self.rootItems.attr2:setPositionX(self.rootItems.attrN2:getPositionX() + self.rootItems.attrN2:getContentSize().width)

    self.rootItems.doNode1:setVisible(data.isUp)
    self.rootItems.doNode3:setVisible(data.isUp)
    self.rootItems.doNode4:setVisible(data.isUp)
    if data.isUp then
        ui.sethint(self.rootItems.hint_artifact,false)
        print("  - - - -- - - - --  2222")
        self.rootItems.doButton3:addHandleOfControlEvent(function()
            print("  - - - -- - - - --  ")
            self.callback = nil
            GameScene:shiftLayer("artifactMount","up",{artifact = self.data,isFrom = "slotsInfo"})
        end, CCControlEventTouchUpInside)
        self.rootItems.doButton3:setSwallowsTouch(true)
        self.rootItems.doButton3:setTouchPriority(self.touchPriority)

        self.rootItems.doButton1:addHandleOfControlEvent(function()
            local curArtifact = nil
            local callbackTwo = function()
                if curArtifact then
                    gameTouch:clickprofbytime(1)
                    UIRequest({type = 5503,sid = data.sid,iid = curArtifact.iid,disboard = 1})
                else
                    UIRequest({type = 5503,sid = data.sid,iid = 0,disboard = 1})
                end
            end
            self.callback = nil
            gameWindows:closeWindowDirect("artifactInfo")
            gameWindows:openWindow("artifactSelect",{showType = "checked",disboardArtifact = self.data},function(artifact)
                curArtifact = artifact;
                local isgem = false;
                for i = 1, 4 do
                    if self.data["jewel"..i] > 0 then
                        isgem = true
                        break
                    end
                end

                if isgem == false then
                    callbackTwo();
                else
                    gameWindows:openWindow("confirm",{msg = "当前神器更换宝石会自动卸下"}, callbackTwo)
                end
            end)
        end, CCControlEventTouchUpInside)
        self.rootItems.doButton1:setSwallowsTouch(true)
        self.rootItems.doButton1:setTouchPriority(self.touchPriority - 1)

        self.rootItems.doButton4:addHandleOfControlEvent(function()
            -- 神器锁定逻辑
            local curLockState = 0
            if self.artifactLockState == 0 then
                curLockState = 1
            end
            -- printT(data," ----  111-1-1--")
            -- print(curLockState)
            if data.artifactData.isChecked == 1 then
                UIRequest({type = 5518,cid = data.artifactData.iid,isLock = curLockState})
            else
                print(" 装备未鉴定")
            end
        end, CCControlEventTouchUpInside)
        self.rootItems.doButton4:setSwallowsTouch(true)
        self.rootItems.doButton4:setTouchPriority(self.touchPriority - 1)

        self.rootItems.doButton2:addHandleOfControlEvent(function()
            -- 洗练
            GameScene:shiftLayer("artifactWash","up",{data = self.data})

        end, CCControlEventTouchUpInside)
        self.rootItems.doButton2:setSwallowsTouch(true)
        self.rootItems.doButton2:setTouchPriority(self.touchPriority - 1)
    end

    
    self.rootItems.doButton5:addHandleOfControlEvent(function()
        -- 强化
        GameScene:shiftLayer("artifactStrengthen","up",{data = self.data})
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton5:setSwallowsTouch(true)
    self.rootItems.doButton5:setTouchPriority(self.touchPriority - 1)

    
    self.rootItems.doButton7:addHandleOfControlEvent(function()
        -- 解锁 和锁定 
        -- 暂时没有锁定的消息协议
        local curLockState = 0
        if self.artifactLockState == 0 then
            curLockState = 1
        end
        printT(data," ----  22222222--")
        print(curLockState)
        if data.artifactData.isChecked == 1 then
            UIRequest({type = 5518,cid = data.artifactData.iid,isLock = curLockState})
        else
            print(" 装备未鉴定")
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton7:setSwallowsTouch(true)
    self.rootItems.doButton7:setTouchPriority(self.touchPriority - 1)


    self.rootItems.doButton8:addHandleOfControlEvent(function()
        -- 确定
        gameWindows:closeWindowDirect("artifactInfoOther")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton8:setSwallowsTouch(true)
    self.rootItems.doButton8:setTouchPriority(self.touchPriority - 1)

   
    self.rootItems.lockIcon:setVisible(false)

    self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")

    self.rootItems.scrollnode:setTouchPriority(self.touchPriority)

    self.rootItems.scrollnode:setViewSize(CCSizeMake(1000,680))


    -- self.rootItems.container:setContentSize(CCSize(1080,1000))

    self.scrollNode, self.scrollItems = CCBReaderLoad("shenqi_new/shenqicell_info", nil, true, "shenqicell_info")
    self.rootItems.container:addChild(self.scrollNode)


    ui.setLabelString(self.scrollItems.doLab1,gameConfig.strings:string_common("artifact",190),19)
    ui.setLabelString(self.scrollItems.doLab2,gameConfig.strings:string_common("artifact",190),19)
    ui.setLabelString(self.scrollItems.doLab3,gameConfig.strings:string_common("artifact",190),19)
    

    -- self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,-320),0)

    self.rootItems.scrollnode_touch:setContentSize(CCSize(1000,680))

    self:setcell(self.scrollItems)

end

function artifactInfo.setAddedDesc(self,skills,items)
    local totalHeight = 0
    for i = 1,3 do
        items["skillName"..i]:removeAllChildrenWithCleanup(true)
        items["skill"..i]:removeAllChildrenWithCleanup(true)
        if  skills[i] and skills[i] > 0 then
            local skillConfig = gamedata.config.breakskill[tostring(skills[i])]
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
end

function artifactInfo.setJewelDesc(self)
    local totalLevel = 0
    for i = 1, 4 do
        if self.data["jewel"..i] > 0 then
            local config = gamedata.config.trump_gem[tostring(self.data["jewel"..i])]
            totalLevel = totalLevel + config.lv
        end
    end
    local config = gamedata.config.trump[tostring(self.data.cid)]
    local shenqiSkeletonMeta = require"SkeletonShenqi"
    local skeleton = shenqiSkeletonMeta:init(config,totalLevel)
    skeleton:setPosition(0,0)
    skeleton:setScale(0.7)
    skeleton:setAnimation("stand",true,0)
    self.rootItems.artifactNode:addChild(skeleton.root or skeleton)

end


function artifactInfo.setJewelIcon(self,items,jewelData,number)
    local key_Ex = number <= 1 and "" or "_"..(number - 1)
    items["toMount"..key_Ex]:setVisible(false)
    
    items["goToMount"..key_Ex]:setVisible(false)
    items["suo"..key_Ex]:setVisible(jewelData < 0)
    items["i_notice"..key_Ex]:setVisible(false)
    --items["in_name"..key_Ex]:setVisible(false)
    if jewelData > 0 then
        local config = gamedata.config.trump_gem[tostring(jewelData)]
        setSpriteFrameByName(items["i_k_quality"..key_Ex], "b_iconk"..(config.quality and config.quality>1 and config.quality or 1))
        setSpriteFrameByName(items["i_quality"..key_Ex], "b_iconbg"..(config.quality and config.quality>1 and config.quality or 1))
        setSpriteFrameByName(items["i_icon"..key_Ex], config.icon and config.icon or "alpha")
        ui.setSpriteTextureRect(items["i_icon"..key_Ex],0,0,150,150)
        ui.setLabelString(items["in_name"..key_Ex],config.name,((config.quality and config.quality ~= 0) and config.quality or 1)*2-1)

        local type,num = "",""
        type = gameConfig.strings.attr_type[config.attr]
        num = "+"..(config.attrValue)*(config.attrType == "value" and 1 or 1)..(config.attrType == "value" and "" or "%")
        items["jewel"..number]:removeAllChildrenWithCleanup(true)
        items["jewel"..number]:setString(type..num)
        items["jewel"..number]:setColor(ccc3(115,66,25))
        items["jewel"..number]:setPositionY(-240)
    else
        setSpriteFrameByName(items["i_k_quality"..key_Ex], "b_s_iconk1")
        setSpriteFrameByName(items["i_quality"..key_Ex], "b_iconbg8")
        setSpriteFrameByName(items["i_icon"..key_Ex], "alpha")
        ui.setLabelString(items["in_name"..key_Ex],"",1)

        items["jewel"..number]:setString("未开启")
        items["jewel"..number]:setColor(ccc3(115,66,25))
        items["jewel"..number]:setPositionY(-210)

        if jewelData == 0 then
            ui.setLabelString(items["jewel"..number],gameConfig.strings:string_common("fixedString","mofu",1),29)
        end

        -- if not isOther then
        --     items["goToMount"..key_Ex]:setVisible(true)
        --     items["i_button"..key_Ex]:addHandleOfControlEvent(function()
        --         if jewelData <= 0 then
        --             GameScene:shiftLayer("artifactMount","up",{artifact = self.data,isFrom = self.receiveData.isUp and "slotsInfo" or self.receiveData.fromLayer})
        --         end
        --     end, CCControlEventTouchUpInside)
        --     items["i_button"..key_Ex]:setSwallowsTouch(true)
        --     items["i_button"..key_Ex]:setTouchPriority(self.touchPriority)
        -- end
    end
end


function artifactInfo.setcell( self,item )
    

    gameWindows.windows["artifactSelect"].module:initCellDetalFixedString(item)

    printT(self.data,"  artifactInfo.setcell  ")

    for i = 1, 4 do
        self:setJewelIcon(item,self.data["jewel"..i],i)
    end
    local skills = {}
    for i = 1,3 do
    	if self.data["skill"..i] > 0 then
            skills[#skills + 1] = self.data["skill"..i]
        end
    end

    local totalHeight = self:setAddedDesc(skills,item)

    print("totalHeight",totalHeight)
    item.skillNode:setPositionY(260 + totalHeight)
    item.jewelNode:setPositionY(320 + item.skillNode:getPositionY())

    local contentSize = {width = 1000,height = item.jewelNode:getPositionY()+50}
    self.rootItems.container:setContentSize(CCSize(contentSize.width,contentSize.height))

    self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,680 - contentSize.height),0)

    for i = 1, 3 do
    	item["skillinfo"..i]:setVisible(true)
        item["konginfo"..i]:setVisible(false)
        item["btnicon"..i]:setVisible(false)
        item["infobtn"..i]:setVisible(false)
    end

    local artifactConfig = gamedata.config.trump[tostring(self.data.cid)]
    local artifactStrengthenConfig = nil

    if self.data.level1 > 0 then
        if artifactConfig.goldTrump == 0 then
            artifactStrengthenConfig = gamedata.config.trump_strengthen[tostring(artifactConfig.type)][tostring(self.data.level1)]
        else
            artifactStrengthenConfig = gamedata.config.trump_Godstrengthen[tostring(artifactConfig.type)][tostring(self.data.level1)]
        end
        item["attrValue1"]:setString(gameConfig.strings.attr_type["atk"].."+"..tostring(self.data.levelAttack or 0).."%")
        item["attrValue2"]:setString(gameConfig.strings.attr_type["def"].."+"..tostring(self.data.levelDef or 0).."%")
        item["attrValue3"]:setString(gameConfig.strings.attr_type["hp"].."+"..tostring(self.data.levelHP or 0).."%")
        item.noattr:setVisible(false)
    else
        item.noattr:setVisible(true)
        item["attrValue1"]:setString("")
        item["attrValue2"]:setString("")
        item["attrValue3"]:setString("")
    end
end

function artifactInfo.setKongInfo(self,i,t)
    -- 成功率
    self.scrollItems["success"..i]:setString(self.data["skillHoleProbs"..i].."%")
    -- 失败成功率加成
    local cof = gamedata.config.trump_config
    self.scrollItems["fail"..i]:setString(((tonumber(cof["skill_promote_"..i].value) or 0)*100).."%")

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
        self:onCreateIcon(self.scrollItems["itemContent"..i],{cid=needPropCid,num = havePropNum.."/"..needPropNum},isPropEnough)

        local isCanOpen = true
        if i > 1 then
            if self.data["skillHole"..(i-1)] and self.data["skillHole"..(i-1)] <= 0 then
                isCanOpen = false
            end
        end

        if isCanOpen and isPropEnough then
            ui.removeGray("CCControlButton",self.scrollItems["doButton"..i])
            self.scrollItems["hint_artifact"..i]:setVisible(true)
        else
            ui.addGray("CCControlButton",self.scrollItems["doButton"..i])
            self.scrollItems["hint_artifact"..i]:setVisible(false)
        end

        self.scrollItems["doButton"..i]:addHandleOfControlEvent(function()
            if self.data then
                print(self.data.iid,"self.data.cid = ")
                print("开孔 ",i)
                if not isPropEnough then
                    runGamePrompt({msg = "材料不足！"})
                    return
                end

                if not isCanOpen then
                    runGamePrompt({msg = string.format(gameConfig.strings:string_common("artifact",168), i-1)})
                    return
                end

                -- 传入 ids [神器id，孔位（1，2，3）,操作（1开孔，2锁孔, 3解锁）]
                UIRequest({type = 5540,iid =self.data.iid,pos = i,curType = 1})
                
            else
                runGamePrompt({msg = gameConfig.strings:string_common("artifact",20)})
            end

        end, CCControlEventTouchUpInside)
        self.scrollItems["doButton"..i]:setSwallowsTouch(true)
        self.scrollItems["doButton"..i]:setTouchPriority(self.touchPriority)
    end
end

function artifactInfo.onCreateIcon( self,itemNode,data,isEnough)
    -- body
   local curNode,curItems = CCBReaderLoad("icons/new_icon", nil, true, "shenqi_xilian")
    curNode:setPosition(0,0)
    curNode:setScale(0.75)
    itemNode:addChild(curNode)
    ui.setNewIcon(curItems,data)

    ui.setLabelString(curItems.i_num,data.num or "",isEnough and 13 or 24)
    curItems.i_icon:setScale(0.9)
    curItems.i_k_quality:setVisible(false)
    curItems.i_quality:setVisible(false)

    -- setSpriteFrameByName(item["i_k_quality"..key_Ex], "b_iconk1")
    -- setSpriteFrameByName(item["i_quality"..key_Ex], "b_iconbg1")

    curItems.i_button:addHandleOfControlEvent(function()
        ui.setPopwindowByCid(data.cid)
    end, CCControlEventTouchUpInside)
    curItems.i_button:setSwallowsTouch(true)
    curItems.i_button:setTouchPriority(self.touchPriority)
end

------------更新发回消息 ------------

-- 更新锁定状态
function artifactInfo.updateLockState(self,data)
    -- body
    printT(data,"  updateLockState  ")
    self.artifactLockState = data.isLock
    if self.artifactLockState == 1 then
        self.rootItems.lockIcon:setVisible(true)
        ui.setLabelString(self.rootItems.doLab4,gameConfig.strings:string_common("artifact",191),19)
        ui.setLabelString(self.rootItems.doLab7,gameConfig.strings:string_common("artifact",191),19)
    else
        self.rootItems.lockIcon:setVisible(false)
        ui.setLabelString(self.rootItems.doLab4,gameConfig.strings:string_common("artifact",155),19)
        ui.setLabelString(self.rootItems.doLab7,gameConfig.strings:string_common("artifact",155),19)
    end
end


    -- 开孔显示
function artifactInfo.updateArtifactState( self,data)
    -- body
    printT(data,"神器开孔返回数据")
    self.data = data
    self:setcell(self.scrollItems);
end



function artifactInfo.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.isUp = nil
    self.receiveData = nil

    self.tableview = nil
    if self.callback then
        self.callback()
    end
end

return artifactInfo�^  