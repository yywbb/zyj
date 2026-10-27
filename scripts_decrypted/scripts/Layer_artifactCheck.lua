--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 18/6/12
-- Time: 上午10:13
-- To change this template use File | Settings | File Templates.
--

local artifactCheck = {

    rootNode = nil,
    rootItems = nil,

    touchPriority  = -101,
    timeConfig = {"子","丑","寅","卯","辰","巳","午","未","申","酉","戌","亥"},
    timeSp = {"zi","chou","yin","mao","chen","si","wu","wei","shen","you","xu","hai"},
   
    artifactSelect = nil,
    artifacts = nil,
    propNeed = {},

    hintconfig = {
        {
            name = "rootItems",
            type = "self",
            config = {
                artifactCheck = {398},
            },
        },
    },
    isAttrB = false,
    scrollSize = {width = 820,height = 170},
    labelHeight = 40,
    labelDemention = 0,
    textNum = 24,
    nameLength = 110,
    beforeCheckId = nil,
    afterCheckId = nil,
    isShowTip = true,
    timeData = nil,
}

function artifactCheck.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("shenqi_new/shenqi_jianding", nil, true, "shenqi_jianding")

    self:initFixedString()
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)
    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.middlenode:setPositionY(160 + (toppos - 160)/2 + 50)
    self.rootItems.bottomnode:setPositionY(160 + 60 + 300)

    local effectNode,effectItems = CCBReaderLoad("UIEffect/shenqijianding/shenqijianding", nil, true, "shenqijianding")
    self.rootItems.lianhuaEN:addChild(effectNode)
    self.lianHuaEffect = getAnimationManager(effectItems)
    self.rootItems.lianhuaEN:setVisible(false)

    self.artifactSelect = param
    self:setBtnFuncs()
    if not self.beforeCheckId then
        self:setCheckId()
    end
    self:setArtifactData()
    self:setTime()
end

function artifactCheck.showOnceCheckedPanel(self)
    gameWindows:openWindow("onceCheckup",{artifacts=self.artifacts,itemNum1 = self.propNeed[tostring(self.beforeCheckId)],itemNum2 = self.propNeed[tostring(self.afterCheckId)]});
end

function artifactCheck.setCheckId(self)
    local configs = gamedata.config.trump_autweight
    local ids = {}
    for k,v in pairs(configs) do
        ids[#ids + 1] = v.itemID
    end
    self.beforeCheckId = ids[1] < ids[2] and ids[1] or ids[2]
    self.afterCheckId = ids[1] < ids[2] and ids[2] or ids[1]
end

function artifactCheck.setArtifactData(self,t)
    if not GameScene.layers["artifactList"].module.artifactData then 
        GameScene:addUpdate(10032)
    end
    if GameScene:checkUpdate(10032) then
        return
    end
    self.artifacts = GameScene.layers["artifactList"].module.artifactData.unChecked
    if not self.isAttrB then
        self:setAttrBeforeShow()
        self:setArtifactShow()
    end
end

function artifactCheck.setTime(self,t)
    if not t then
        return UIRequest({type = 5509})
    end
    local time = t.time
    if time < 1 or time > 12 then
        time = 1
    end
    local sec = t.sec
    self.timeData = {time = time,sec = sec}
    --ui.setLabelString(self.rootItems.timeShow,self.timeConfig[time],18)
    setSpriteFrameByName(self.rootItems.timeSp,"shenqitime_"..self.timeSp[time])
    setSpriteFrameByName(self.rootItems.timeL,"shichen_"..self.timeSp[time])
    gameTimer:rigistTime("artifactCheck",sec)
    gameTimer:rigistTimeFunc("artifactCheck", function()
        if gameTimer.times["artifactCheck"] <= 0 then
            self.timeData.sec = 0
            self.rootItems.leftTime:setString(ui.makeTimeDayText(0,"minute"))
            ui.setLabelString(self.rootItems.leftTime,nil,23)
        else
            self.timeData.sec = gameTimer.times["artifactCheck"]
            self.rootItems.leftTime:setString(ui.makeTimeDayText(gameTimer.times["artifactCheck"],"minute"))
            ui.setLabelString(self.rootItems.leftTime,nil,23)
        end
    end)
end

function artifactCheck.resetArtifactSelect(self)
    self.artifactSelect = nil
    self:setArtifactShow()
    self:setAttrBeforeShow()
end

function  artifactCheck.setBtnFuncs(self)

    self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    self.rootItems.scrollnode:setTouchPriority(self.touchPriority - 1)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        GameScene:shiftLayer("artifact","up")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.addbutton:addHandleOfControlEvent(function()
        gameWindows:openWindow("artifactEffectList")
    end, CCControlEventTouchUpInside)
    self.rootItems.addbutton:setSwallowsTouch(true)
    self.rootItems.addbutton:setTouchPriority(self.touchPriority)

    self.rootItems.timeBtn:addHandleOfControlEvent(function()
        if self.timeData then
            gameWindows:openWindow("checkTimeList",self.timeData)
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.timeBtn:setSwallowsTouch(true)
    self.rootItems.timeBtn:setTouchPriority(self.touchPriority)

    self.rootItems.artifactBtn:addHandleOfControlEvent(function()
        if not self.artifacts then
            return
        end
        
        gameWindows:openWindow("artifactSelect",{data= {artifacts = self.artifacts,hasSelect = {self.artifactSelect}},showType = "unChecked"},function (selectArtifact)
            print("lipurpose set selectArtifact call")
            if selectArtifact then
                self.artifactSelect = selectArtifact
                self:setArtifactShow()
                self:setAttrBeforeShow()
            end
        end)
    end, CCControlEventTouchUpInside)
    self.rootItems.artifactBtn:setSwallowsTouch(true)
    self.rootItems.artifactBtn:setTouchPriority(self.touchPriority)

    self.rootItems.doButton1:addHandleOfControlEvent(function()
        if not self.artifacts then
            return
        end
        if not self.artifactSelect then
            return runGamePrompt({msg = gameConfig.strings:string_common("artifact",63)})
        end
        if self.artifactSelect.isChecked > 0 then
            return runGamePrompt({msg = gameConfig.strings:string_common("artifact",64)})
        end
        local isOk,id = self:checkPropNums(nil,1)
        if isOk == 1 then
            return 
        end
        local config = ui.IDconfig(id)
        -- local rich = {
        --     {fontID = 48,content = gameConfig.strings:string_common("artifact",114),},
        --     {fontID = 9,content = " "..config.name.." ",},
        --     {fontID = 48,content = gameConfig.strings:string_common("artifact",115),},
        -- }
        if false and self.isShowTip then
            gameWindows:openWindow("artifactCreateTip",{showType = "check"},function (isSelect,isContinue)
                self.isShowTip = not isSelect
                if isContinue then
                    if isOk == 2 then
                        return runGamePrompt({msg = gameConfig.strings:string_format({"fixedStringA",82},{config.name})})
                    end
                    gameTouch:clickprofbytime(1)
                    UIRequest({type = 5508,iid = self.artifactSelect.iid,useId = id})
                else

                end
            end)
        else
            if isOk == 2 then
                return runGamePrompt({msg = gameConfig.strings:string_format({"fixedStringA",82},{config.name})})
            end
            gameTouch:clickprofbytime(1)
            UIRequest({type = 5508,iid = self.artifactSelect.iid,useId = id})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton1:setSwallowsTouch(true)
    self.rootItems.doButton1:setTouchPriority(self.touchPriority)

    self.rootItems.doButton2:addHandleOfControlEvent(function()
        if not self.artifactSelect then
            return runGamePrompt({msg = gameConfig.strings:string_common("artifact",63)})
        end
        if self.artifactSelect.isChecked > 0 then
            return runGamePrompt({msg = gameConfig.strings:string_common("artifact",64)})
        end
        local isOk,id = self:checkPropNums(nil,2)
        if isOk == 1 then
            return 
        end

        local config = ui.IDconfig(id)
        -- local rich = {
        --     {fontID = 48,content = gameConfig.strings:string_common("artifact",114),},
        --     {fontID = 9,content = " "..config.name.." ",},
        --     {fontID = 48,content = gameConfig.strings:string_common("artifact",115),},
        -- }
        --if self.isShowTip then
            --gameWindows:openWindow("artifactCreateTip",{showType = "check"},function (isSelect,isContinue)
                --self.isShowTip = not isSelect
                --if isContinue then
                    -- if isOk == 2 then
                    --     return runGamePrompt({msg = gameConfig.strings:string_format({"fixedStringA",82},{config.name})})
                    -- end
                    -- gameTouch:clickprofbytime(1)
                    -- UIRequest({type = 5508,iid = self.artifactSelect.iid,useId = id})
                --else

                --end
            --end)
        --else
            if isOk == 2 then
                return runGamePrompt({msg = gameConfig.strings:string_format({"fixedStringA",82},{config.name})})
            end
            gameTouch:clickprofbytime(1)
            UIRequest({type = 5508,iid = self.artifactSelect.iid,useId = id})
        --end
        
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton2:setSwallowsTouch(true)
    self.rootItems.doButton2:setTouchPriority(self.touchPriority)


    self.rootItems.doButton3:addHandleOfControlEvent(function()
        gameWindows:openWindow("onceCheckup",{artifacts=self.artifacts,itemNum1 = self.propNeed[tostring(self.beforeCheckId)],itemNum2 = self.propNeed[tostring(self.afterCheckId)]});

        -- if not self.artifactSelect then
        --     return runGamePrompt({msg = gameConfig.strings:string_common("artifact",63)})
        -- end
        -- if self.artifactSelect.isChecked > 0 then
        --     return runGamePrompt({msg = gameConfig.strings:string_common("artifact",64)})
        -- end
        -- local isOk,id = self:checkPropNums(nil,2)
        -- if isOk == 1 then
        --     return 
        -- end

        -- local config = ui.IDconfig(id)
        --     if isOk == 2 then
        --         return runGamePrompt({msg = gameConfig.strings:string_format({"fixedStringA",82},{config.name})})
        --     end
        --     gameTouch:clickprofbytime(1)
        --     UIRequest({type = 5508,iid = self.artifactSelect.iid,useId = id})
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton3:setSwallowsTouch(true)
    self.rootItems.doButton3:setTouchPriority(self.touchPriority)

    for i = 1,2 do
        self.rootItems["caiShiBtn"..i]:addHandleOfControlEvent(function()
            if not self.beforeCheckId then
                return
            end
            local setId = (i == 1 and self.beforeCheckId or self.afterCheckId) 
            gameWindows:openWindow("dropTips",{cid = setId},nil)
        end, CCControlEventTouchUpInside)
        self.rootItems["caiShiBtn"..i]:setSwallowsTouch(true)
        self.rootItems["caiShiBtn"..i]:setTouchPriority(self.touchPriority)
    end
end


function artifactCheck.checkPropNums(self,t,checkType)
    local config = gamedata.config.trump[tostring(self.artifactSelect.cid)]
    self.propNeed = t and t or self.propNeed
    local id,num
    if checkType then
        if checkType == 1 then
            id = tonumber(self.beforeCheckId)
        else
            id = tonumber(self.afterCheckId)
        end
    else
        id = self.beforeCheckId
    end
    num = gamedata.config.trump_autweight[tostring(id)].itemNum
    if not self.propNeed[tostring(id)] then
        return 1,UIRequest({type = 12001, order = 33013, cids = {self.beforeCheckId,self.afterCheckId}})
    end
    local isEnough = self.propNeed[tostring(id)] >= num 
    local labStr = isEnough and 13 or 24 
    local setType = checkType or 1 
    ui.setLabelString(self.rootItems["propNum"..setType],""..self.propNeed[tostring(id)].."/"..num,labStr)
    local config = ui.IDconfig(id)
    setSpriteFrameByName(self.rootItems["propSp"..setType],config.icon)
    self.rootItems["propSp"..setType]:setScale(0.4)

    if not checkType then
        id = self.afterCheckId
        num = gamedata.config.trump_autweight[tostring(id)].itemNum
        isEnough = self.propNeed[tostring(id)] >= num 
        labStr = isEnough and 13 or 24 
        setType = 2 
        ui.setLabelString(self.rootItems["propNum"..setType],""..self.propNeed[tostring(id)].."/"..num,labStr)
        config = ui.IDconfig(id)
        setSpriteFrameByName(self.rootItems["propSp"..setType],config.icon)
        self.rootItems["propSp"..setType]:setScale(0.4)
    end
    return isEnough and 0 or 2,id
end



function artifactCheck.setArtifactShow(self)

    self.rootItems.gongmingNode:removeAllChildrenWithCleanup(true)
    if not self.artifactSelect then
        self.rootItems.artifactNode:removeAllChildrenWithCleanup(true)
        return
    end
    local config = gamedata.config.trump[tostring(self.artifactSelect.cid)]
    local shenqiSkeletonMeta = require"SkeletonShenqi"
    local skeleton = shenqiSkeletonMeta:init(config,0)
    skeleton:setPosition(0,0)
    skeleton:setAnimation("stand",true,0)
    self.rootItems.artifactNode:removeAllChildrenWithCleanup(true)
    self.rootItems.artifactNode:addChild(skeleton.root or skeleton)
end

function artifactCheck.setAttrBeforeShow(self)
    self.isAttrB = true
    if self.artifactSelect then
        self.rootItems.nameNode:setVisible(true)
        self.rootItems.nameNode1:setVisible(true)
        self.rootItems.propNode1:setVisible(true)
        self.rootItems.propNode2:setVisible(true)
        ui.removeGray("CCControlButton",self.rootItems.doButton2)
        ui.removeGray("CCControlButton",self.rootItems.doButton1)
        self.rootItems.artifactAdd:setVisible(false)

        local config = gamedata.config.trump[tostring(self.artifactSelect.cid)]
        local nameStr = config.goldTrump > 0 and gameConfig.strings:string_common("equips",8).."·"..config.name or config.name
        ui.setLabelString(self.rootItems.name,nameStr,59)
        local playerStr = config.goldTrump > 0 and self.artifactSelect.name..gameConfig.strings:string_common("artifact",35) or self.artifactSelect.name..gameConfig.strings:string_common("artifact",36)
        ui.setLabelString(self.rootItems.playerName,playerStr,60)

        local type1 = gameConfig.strings.attr_type[config.attr1]
        local type2 = gameConfig.strings.attr_type[config.attr2]
    
        ui.setLabelString(self.rootItems.attrName1,type1..":",58)
        ui.setLabelString(self.rootItems.attrName2,type2..":",58)
        
        local idNums1 = ui.getIDandNUMs(config.attr1Value)
        local idNums2 = ui.getIDandNUMs(config.attr2Value)
        
        local setStr1,setStr2 = "",""
        setStr1 = "+"..(config.attr1Type == "percent" and idNums1[1].cid or idNums1[1].cid)..(config.attr1Type == "percent" and "%" or "")
        if idNums1[2] then
            setStr1 = setStr1.."-"..(config.attr1Type == "percent" and idNums1[#idNums1].cid or idNums1[#idNums1].cid)..(config.attr1Type == "percent" and "%" or "")
        end
        setStr2 = "+"..(config.attr2Type == "percent" and idNums2[1].cid  or idNums2[1].cid)..(config.attr2Type == "percent" and "%" or "")
        if idNums2[2] then
            setStr2 = setStr2.."—"..(config.attr2Type == "percent" and idNums2[#idNums2].cid  or idNums2[#idNums2].cid)..(config.attr2Type == "percent" and "%" or "")
        end
        self.rootItems.attrWrapN1:setString(type1)
        self.rootItems.attrWrapN2:setString(type2)
        self.rootItems.attrWrap1:setString(setStr1)
        self.rootItems.attrWrap2:setString(setStr2)
        
        
        self.propNeed = {}
        self:checkPropNums()
    else
        self.rootItems.nameNode:setVisible(false)
        self.rootItems.nameNode1:setVisible(false)
        self.rootItems.propNode1:setVisible(false)
        self.rootItems.propNode2:setVisible(false)
        ui.addGray("CCControlButton",self.rootItems.doButton2)
        ui.addGray("CCControlButton",self.rootItems.doButton1)
        self.rootItems.artifactAdd:setVisible(true)

        ui.setLabelString(self.rootItems.playerName,"",9)

        ui.setLabelString(self.rootItems.attrName1,gameConfig.strings:string_common("generalInfo",6)..":",58)
        ui.setLabelString(self.rootItems.attrName2,gameConfig.strings:string_common("generalInfo",6)..":",58)

        self.rootItems.attrWrapN1:setString("")
        self.rootItems.attrWrapN2:setString("")
        self.rootItems.attrWrap1:setString(gameConfig.strings:string_common("skill_Effect","once"))
        self.rootItems.attrWrap2:setString(gameConfig.strings:string_common("skill_Effect","once"))
    end

    local contentSize1 = self.rootItems.attrWrapN1:getContentSize().width
    local contentSize11 = self.rootItems.attrWrap1:getContentSize().width
    local total = contentSize1 + contentSize11
    self.rootItems.attrWrapN1:setPositionX(contentSize1 - total/2)
    self.rootItems.attrWrap1:setPositionX(total/2 - contentSize11)

    local contentSize2 = self.rootItems.attrWrapN2:getContentSize().width
    local contentSize21 = self.rootItems.attrWrap2:getContentSize().width
    local total2 = contentSize2 + contentSize21
    self.rootItems.attrWrapN2:setPositionX(contentSize2 - total2/2)
    self.rootItems.attrWrap2:setPositionX(total2/2 - contentSize21)
    
    self.rootItems.pingfengNode:removeAllChildrenWithCleanup(true)
    self.rootItems.attr1:setString(gameConfig.strings:string_common("skill_Effect","once"))
    self.rootItems.attr2:setString(gameConfig.strings:string_common("skill_Effect","once"))
    self.rootItems.attr1:setColor(ccc3(255,237,190))
    self.rootItems.attr2:setColor(ccc3(255,237,190))

    --ui.setLabelString(self.rootItems.skill1,gameConfig.strings:string_common("skill_Effect","once"),14)
    --ui.setLabelString(self.rootItems.skill2,gameConfig.strings:string_common("skill_Effect","once"),14)
    --ui.setLabelString(self.rootItems.skill3,gameConfig.strings:string_common("skill_Effect","once"),14)
    local skills = {}
    self:setSkillInfo(skills,true)
end

function artifactCheck.setSkillInfo(self,skills,isB)
    self.rootItems.container:removeAllChildrenWithCleanup(true)
    if #skills == 0 then
        self.rootItems.container:setContentSize(CCSizeMake(self.scrollSize.width,self.scrollSize.height))
        if isB then
            self.rootItems.texingWuB:setVisible(true)
            self.rootItems.texingWu:setVisible(false)
        else
            self.rootItems.texingWuB:setVisible(false)
            self.rootItems.texingWu:setVisible(true)
        end
        self.rootItems.container:setPositionY(0)
    else
        self.rootItems.texingWuB:setVisible(false)
        self.rootItems.texingWu:setVisible(false)
        local height = 0
        local heightNums = {}
        for i = 1,#skills do
            local skillConfig = gamedata.config.breakskill[tostring(skills[i])]
            local count = ui.getTextLength(skillConfig.desc)
            local length = math.ceil(count/self.textNum)
            height = height + length * self.labelHeight + self.labelDemention
            heightNums[i] = length
        end
        height = height > self.scrollSize.height and height or self.scrollSize.height
        self.rootItems.container:setContentSize(CCSizeMake(self.scrollSize.width,height))
        self.rootItems.container:setPositionY(-height + self.scrollSize.height)
        for i = 1,#skills do
            local skillConfig = gamedata.config.breakskill[tostring(skills[i])]
            local name = CCLabelTTF:create()
            name:setAnchorPoint(ccp(1,1))
            self.rootItems.container:addChild(name)
            ui.setLabelString(name,skillConfig.name,(skillConfig.quality > 0 and skillConfig.quality or 1) * 2)
            name:setPosition(self.nameLength,height)

            local desc = CCLabelTTF:create()
            desc:setAnchorPoint(ccp(0,1))
            self.rootItems.container:addChild(desc)
            ui.setLabelString(name,skillConfig.name,(skillConfig.quality > 0 and skillConfig.quality or 1) * 2)
            desc:setPosition(self.nameLength,height)
            desc:setDimensions(CCSizeMake(self.scrollSize.width - self.nameLength,heightNums[i] * self.labelHeight))
            ui.setLabelString(desc,":"..skillConfig.desc,(skillConfig.quality > 0 and skillConfig.quality or 1) * 2)
            height = height - heightNums[i] * self.labelHeight - self.labelDemention
        end
        
    end
    
end

function artifactCheck.setAttrAfterShow(self)
    self.rootItems.propNode1:setVisible(false)
    self.rootItems.propNode2:setVisible(false)
    ui.addGray("CCControlButton",self.rootItems.doButton2)
    ui.addGray("CCControlButton",self.rootItems.doButton1)

    local config = gamedata.config.trump[tostring(self.artifactSelect.cid)]
    local num1 = ""..(self.artifactSelect.attr1)*(config.attr1Type == "value" and 1 or 1)..(config.attr1Type == "value" and "" or "%")
    local num2 = ""..(self.artifactSelect.attr2)*(config.attr2Type == "value" and 1 or 1)..(config.attr2Type == "value" and "" or "%")
   
    self.rootItems.attr1:setString(num1)
    if gameWindows.windows["artifactInfo"].module.isActiveResonance(self.artifactSelect) == 2 then
        num2 = num2..gameConfig.strings:artifactResonanceAttr(self.artifactSelect)
    end
    self.rootItems.attr2:setString(num2)

    self.rootItems.attr1:setColor(ui.greenColor)
    self.rootItems.attr2:setColor(ui.greenColor)

    -- for i = 1,3 do
    --     if self.artifactSelect["skill"..i] > 0 then
    --         local skillConfig = gamedata.config.breakskill[tostring(self.artifactSelect["skill"..i])]
    --         ui.setLabelString(self.rootItems["skill"..i],skillConfig.name,skillConfig.quality * 2)
    --     end
    -- end
    local skills = {}
    for i = 1,3 do
        if self.artifactSelect["skill"..i] > 0 then
            skills[#skills + 1] = self.artifactSelect["skill"..i]
        end
    end
    self:setSkillInfo(skills)
end

function artifactCheck.checkSuccess(self,t)
    gameTouch:clickprofbytime(4)
    self.artifactSelect = t.rewardArtifact["1"]
    
    self.lianHuaEffect:setAnimationCompletedCallback(function ()
        self.rootItems.lianhuaEN:setVisible(false)
        local successNode,successItems = CCBReaderLoad("shenqi_new/jiandingchenggong", nil, true, "jiandingchenggong")
        self.rootItems.successNode:addChild(successNode)
        local animationManager = getAnimationManager(successItems)
        animationManager:setAnimationCompletedCallback(function()
            self.rootItems.successNode:removeAllChildrenWithCleanup(true)
            self:setArtifactData()
            self:setAttrAfterShow()
            local scoreNode,scoreItems = CCBReaderLoad("shenqi_new/shenqi_pingfen", nil, true, "shenqi_pingfen")
            --scoreItems.fixed1:setString(gameConfig.strings:string_common("artifact",141))
            -- scoreItems.score:setString(""..GetArtifctScore(self.artifactSelect))

            scoreItems.score:setString(self.artifactSelect.score)
            self.rootItems.pingfengNode:addChild(scoreNode)

            self:checkGongming()

        end)
        animationManager:runAnimationsForSequenceNamed("success")
    end)
    self.rootItems.lianhuaEN:setVisible(true)
    self.lianHuaEffect:runAnimationsForSequenceNamed("jianding")
end

function artifactCheck.checkGongming(self)

    local triggerGongming = false
    for i = 1,3 do
        if self.artifactSelect["skill"..i] > 0 then
            local skillConfig = gamedata.config.breakskill[tostring(self.artifactSelect["skill"..i])]

            if skillConfig.quality >= 6 then
                triggerGongming = true
            end
        end
    end

    if triggerGongming then
        --触发共鸣
        self.rootItems.gongmingNode:removeAllChildrenWithCleanup(true)
        local gongmingNode,gongmingItems = CCBReaderLoad("shenqi_new/shenjigongmingbt", nil, true, "shenjigongmingbt")
        self.rootItems.gongmingNode:addChild(gongmingNode)


        gongmingItems.gongmingButton:addHandleOfControlEvent(function()
            if self.artifactSelect then
                print("点击共鸣")
                gameWindows:openWindow("artifactGongming",self.artifactSelect)
            end
        end, CCControlEventTouchUpInside)
        gongmingItems.gongmingButton:setSwallowsTouch(true)
        gongmingItems.gongmingButton:setTouchPriority(self.touchPriority)


        local animationManager = getAnimationManager(gongmingItems)
        animationManager:setAnimationCompletedCallback(function()
            
        end)
        animationManager:runAnimationsForSequenceNamed("play")
    end
end

function artifactCheck.initFixedString(self)
    --ui.setLabelString(self.rootItems.fixed,gameConfig.strings:string_common("artifact",56),25)
    --ui.setLabelString(self.rootItems.fixed2,gameConfig.strings:string_common("artifact",57),58)
    ui.setLabelString(self.rootItems.fixed3,gameConfig.strings:string_common("artifact",58),58)
    ui.setLabelString(self.rootItems.fixed4,gameConfig.strings:string_common("artifact",58),58)
    --ui.setLabelString(self.rootItems.fixed5,gameConfig.strings:string_format({"artifact",59},{""}),8
    --ui.setLabelString(self.rootItems.fixed6,gameConfig.strings:string_format({"artifact",59},{2}),85)
    --ui.setLabelString(self.rootItems.fixed7,gameConfig.strings:string_format({"artifact",59},{3}),85)
    ui.setLabelString(self.rootItems.fixed8,gameConfig.strings:string_common("fixedString","soul",1),86)
    ui.setLabelString(self.rootItems.fixed9,gameConfig.strings:string_common("fixedString","soul",1),86)
    ui.setLabelString(self.rootItems.doLab1,gameConfig.strings:string_common("artifact",61),19)
    ui.setLabelString(self.rootItems.doLab2,gameConfig.strings:string_common("artifact",113),19)
    ui.setLabelString(self.rootItems.doLab3,gameConfig.strings:string_common("artifact",156),19)
end




function artifactCheck.clear(self)
    
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)

    if gameTimer.times["artifactCheck"] then
        gameTimer:UnrigistTime("artifactCheck")
        gameTimer:UnrigistTimeFunc("artifactCheck")
    end

    self.rootNode = nil
    self.rootItems = nil

    self.artifacts = nil
    self.artifactSelect = nil
    self.propNeed = {}
    self.isAttrB = false
    self.timeData = nil
end


return artifactCheck   Yh  