--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 18/6/12
-- Time: 上午10:13
-- To change this template use File | Settings | File Templates.
--
-- =---------神器打造

local artifactCreate = {

    resource = nil,
    rootNode = nil,
    rootItems = nil,

    selectpage = "cast",
   
    touchPriority  = -101,
    castNeedChange = true,
    comppondNeedChange = true,
    propUse = true,
    autoSet = true,
    artifactSelect = {},
    propsSelect = {},
    spendPropsData = {},
    artifacts = nil,
    isCastTip = true,
    spendIsEnough = false,
}


function artifactCreate.shiftPage(self,type)
    self.selectpage = type or self.selectpage
    self.spendIsEnough = false
    if self.selectpage == "cast" then
        self:initCast()
    else
        self:initCommpond()
    end
    
end

function artifactCreate.initCast(self)
    setSpriteFrameByName(self.rootItems.title,"shenqidazaobiaoti")
    if not self.castNeedChange then
        return
    end
    
    if not self.spendPropsData or not next(self.spendPropsData) then
        self:getCastData()
        return
    end
    --
    self.rootItems["i_button".."_3"]:addHandleOfControlEvent(function()
        ui.setPopwindowByCid(self.castTable[4].cid)
    end, CCControlEventTouchUpInside)
    self.rootItems["i_button".."_3"]:setTouchPriority(self.touchPriority)
    self:setItem(4,4)
    --
    local isEnough = true
    for i = 1,3 do
        local isOk = self:setItem(i,self.autoSet and i or nil)
        isEnough = isEnough and isOk
    end
    if isEnough then
        ui.removeGray("CCControlButton",self.rootItems.startbutton)
        ui.removeGray("CCControlButton",self.rootItems.oncestartbutton)
    else
        ui.addGray("CCControlButton",self.rootItems.startbutton)
        ui.addGray("CCControlButton",self.rootItems.oncestartbutton)
    end
    self.castNeedChange = false
    self.rootItems.selectSp1:setVisible(self.autoSet)
end

function artifactCreate.getArtifactCount(self)
    -- body
    local numTab = {}
    for i = 1,3 do
        local curCid = tostring(self.castTable[i].cid)
        if curCid ~= "20630" then
            local count = math.floor(self.spendPropsData[tostring(self.castTable[i].cid)]/10)
            table.insert(numTab,count)
        end
    end
    table.sort(numTab);
    printT(numTab," ====   === ");
    return numTab[1];
end

function artifactCreate.setItem(self,pos,idPos)
    if not idPos then
        self:removeItem(pos)
        self.propsSelect[pos] = nil
        return false
    end
    for i = 1,3 do
        if i ~= pos then
            if self.propsSelect[i] == idPos then
                self:removeItem(i)
                self.propsSelect[i] = nil
                break
            end
        end
    end
    self.propsSelect[pos] = idPos
    if pos ~= 4 then
        self.rootItems["itemA"..pos]:setVisible(false)
        self.rootItems["item"..pos]:setVisible(true)
    end
    local key_Ex = pos == 1 and "" or "_"..(pos - 1)
    ui.setNewIcon(self.rootItems,{cid=self.castTable[idPos].cid},pos - 1)
    local labelStr = ""..self.spendPropsData[tostring(self.castTable[idPos].cid)].."/"..self.castTable[idPos].num
    local useLabel = 13
    if self.spendPropsData[tostring(self.castTable[idPos].cid)] < self.castTable[idPos].num then
        useLabel = 24
    end


    --道具不足 显示随身商店
    if (self.spendPropsData[tostring(self.castTable[idPos].cid)] < self.castTable[idPos].num) then
        -- 第四个道具是通过充钱获得不判断
        if self.castTable[idPos].cid ~= 20630 then
            self.spendIsEnough = true
        end
    end
    print(" ---------111-------",idPos);
    printT(self.spendPropsData)
    print(" ---------222-------");
    printT(self.castTable)
    print(" ---------333-------");
    print(self.spendIsEnough)
    -- ui.setMobileShopShow(self.rootItems.mobieshop,-103,11,self.spendIsEnough)

    ui.setLabelString(self.rootItems["item"..pos],labelStr,useLabel)



    return useLabel == 13
end

function artifactCreate.removeItem(self,index)
    local key_Ex = index == 1 and "" or "_"..(index - 1)
    setSpriteFrameByName(self.rootItems["i_k_quality"..key_Ex], "b_iconk1")
    setSpriteFrameByName(self.rootItems["i_quality"..key_Ex], "b_iconbg1")
    setSpriteFrameByName(self.rootItems["i_icon"..key_Ex],"alpha")
    self.rootItems["i_soulsprite"..key_Ex]:setVisible(false)
    if self.rootItems["titleicon"..key_Ex] then 
        self.rootItems["titleicon"..key_Ex]:setVisible(false)
    end
    self.rootItems["i_soulnode"..key_Ex]:removeAllChildrenWithCleanup(true)
    self.rootItems["i_suitNode"..key_Ex]:removeAllChildrenWithCleanup(true)
    ui.setLabelString(self.rootItems["i_num"..key_Ex],"",13)
    local posA = index > 4 and index - 4 or index
    local fS = index > 4 and "itemCA" or "itemA"
    local lafS = index > 4 and "itemC" or "item"
    self.rootItems[fS..posA]:setVisible(true)
    self.rootItems[lafS..posA]:setVisible(false)
end

function artifactCreate.checkIsOk(self)
    for i = 1,3 do
        if not self.propsSelect[i] then
            return false
        end
    end
    for i = 1,3 do
        if self.spendPropsData[tostring(self.castTable[i].cid)] < self.castTable[i].num then
            return false
        end
    end
    return true
end

function artifactCreate.autoAddProps(self)
    local setIds = {}
    local num = 0
    for i = 1,3 do
        if self.propsSelect[i] then
            setIds[self.propsSelect[i]] = true
            num = num + 1
        end
    end
    if num >= 3 then
        return
    end
    local canUse = {}
    for i = 1,3 do
        if not setIds[i] then
            canUse[#canUse + 1] = i
        end
    end
    local setP = 1
    for i = 1,3 do
        if not self.propsSelect[i] then
            self:setItem(i,canUse[setP])
            setP = setP + 1
        end
    end
end


function artifactCreate.initCommpond(self)
    setSpriteFrameByName(self.rootItems.title,"shenqichongzhubiaoti")
    if not self.comppondNeedChange then
        return
    end
    if not self.artifacts then
        self:getArtifactDatas()
        return
    end
    self.artifactSelect = {}
    for i = 1,3 do
        self:setCommpondItem(i)
    end
    self.comppondNeedChange = false
end

function artifactCreate.setCommpondItem(self,pos,artifact)
    local key_Ex = "_"..(pos + 4 - 1)
    if artifact then
        local config = gamedata.config.trump[tostring(artifact.cid)]
        local ishigh = config.goldTrump
        ui.setNewIcon(self.rootItems,{cid = artifact.cid,ishigh = ishigh},pos + 4 - 1)
        self.rootItems["itemCA"..pos]:setVisible(false)
        self.rootItems["itemC"..pos]:setVisible(true)
        local nameStr = config.goldTrump > 0 and gameConfig.strings:string_common("equips",8).."·"..config.name or config.name
        ui.setLabelString(self.rootItems["itemC"..pos],nameStr,10)
    else
       self:removeItem(pos + 4)
    end
end


function artifactCreate.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("shenqi_new/shenqi_dazao", nil, true, "shenqi_dazao")

    self:initFixedString()
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)
    self.rootItems.topnode:setPositionY(toppos)
    self.animationManager = getAnimationManager(self.rootItems)
    
    self:setBtnFuncs()
    self.animationManager:setAnimationCompletedCallback(function()
        self:shiftPage(self.selectpage)
    end)
    self.animationManager:runAnimationsForSequenceNamed(self.selectpage)

    local animation = "shenqihecheng"
    local skeleton = CCSkeletonAnimation:create(animation.."/"..animation..".json",animation.."/"..animation..".atlas",1)
    skeleton:setAnimation("stand",true,0)
    skeleton:setScale(0.9)
    skeleton:setPosition(54,54)
    self.skeleton = skeleton
    self.rootItems.artifactNode:removeAllChildrenWithCleanup(true)
    self.rootItems.artifactNode:addChild(skeleton)

    self.rootItems.selectSp2:setVisible(self.propUse)

    UIRequest({type = 10323,ids = {366}})
end

function artifactCreate.autoAdd(self)
    if not self.artifacts then
        return
    end
    local poss = {}
    local addedIids = {}
    for i = 1,3 do
        if not self.artifactSelect[i] then
            table.insert(poss,i)
        else
            addedIids[self.artifactSelect[i].iid] = true
        end
    end
    if #poss == 0 then
        runGamePrompt({msg = gameConfig.strings:string_common("artifact",94)})
        return
    end
    local useArtifacts = {}
    for i = 1,#self.artifacts do
        local artifact = self.artifacts[i]
        if gameWindows.windows["artifactSelect"].module.consumeStatus(artifact) == 0 and  (not addedIids[artifact.iid]) then
            useArtifacts[#useArtifacts + 1] = artifact
        end
    end
    if #useArtifacts == 0 then
        runGamePrompt({msg = gameConfig.strings:string_common("artifact",95)})
        return
    end
    for i = #useArtifacts,1,-1 do
        self.artifactSelect[poss[#poss]] = useArtifacts[i]
        self:setCommpondItem(poss[#poss],useArtifacts[i])
        poss[#poss] = nil
        if #poss == 0 then
            break
        end
    end
end

function  artifactCreate.setBtnFuncs(self)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        GameScene:shiftLayer("artifact","up")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.rulebutton:addHandleOfControlEvent(function()
        gameWindows:openWindow("castArtifactRule")
    end, CCControlEventTouchUpInside)
    self.rootItems.rulebutton:setSwallowsTouch(true)
    self.rootItems.rulebutton:setTouchPriority(self.touchPriority)

    self.rootItems.addbutton:addHandleOfControlEvent(function()
        gameWindows:openWindow("artifactEffectList")
    end, CCControlEventTouchUpInside)
    self.rootItems.addbutton:setSwallowsTouch(true)
    self.rootItems.addbutton:setTouchPriority(self.touchPriority)

    self.rootItems.bagBtn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("artifactList","up","artifact")
    end, CCControlEventTouchUpInside)
    self.rootItems.bagBtn:setSwallowsTouch(true)
    self.rootItems.bagBtn:setTouchPriority(self.touchPriority)

    self.rootItems.commondSelect:addHandleOfControlEvent(function()
        if self.selectpage ~= "commond" then
            self.animationManager:setAnimationCompletedCallback(function()
                self:shiftPage("commond")
            end)
            self.animationManager:runAnimationsForSequenceNamed("commond")
        end
    end,CCControlEventTouchUpInside)
    self.rootItems.commondSelect:setSwallowsTouch(true)
    self.rootItems.commondSelect:setTouchPriority(self.touchPriority)

    self.rootItems.castSelect:addHandleOfControlEvent(function()
        if self.selectpage ~= "cast" then
            self.animationManager:setAnimationCompletedCallback(function()
                self:shiftPage("cast")
            end)
            self.animationManager:runAnimationsForSequenceNamed("cast")
        end
    end,CCControlEventTouchUpInside)
    self.rootItems.castSelect:setSwallowsTouch(true)
    self.rootItems.castSelect:setTouchPriority(self.touchPriority)

    self.rootItems.selectUse:addHandleOfControlEvent(function()
        self.propUse = not self.propUse
        if self.propUse then
            runGamePrompt({msg = gameConfig.strings:string_common("artifact",116)})
        else
            runGamePrompt({msg = gameConfig.strings:string_common("artifact",117)})
        end
        self.rootItems.selectSp2:setVisible(self.propUse)
    end, CCControlEventTouchUpInside)
    self.rootItems.selectUse:setSwallowsTouch(true)
    self.rootItems.selectUse:setTouchPriority(self.touchPriority)

    self.rootItems.selectAuto:addHandleOfControlEvent(function()
        self.autoSet = not self.autoSet
        self.rootItems.selectSp1:setVisible(self.autoSet)
        if self.autoSet then
            runGamePrompt({msg = gameConfig.strings:string_common("artifact",84)})
            self:autoAddProps()
            local isOk = self:checkIsOk() 
            if isOk then
                ui.removeGray("CCControlButton",self.rootItems.startbutton)
                ui.removeGray("CCControlButton",self.rootItems.oncestartbutton)
                
            else
                ui.addGray("CCControlButton",self.rootItems.startbutton)
                ui.addGray("CCControlButton",self.rootItems.oncestartbutton)
            end
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.selectAuto:setSwallowsTouch(true)
    self.rootItems.selectAuto:setTouchPriority(self.touchPriority)

    self.rootItems.startbutton:addHandleOfControlEvent(function()
        for i = 1,3 do
            if not self.propsSelect[i] then
                return runGamePrompt({msg = gameConfig.strings:string_common("artifact",33)})
            end
        end
        for i = 1,3 do
            if self.spendPropsData[tostring(self.castTable[i].cid)] < self.castTable[i].num then
                local config = ui.IDconfig(self.castTable[i].cid)
                return runGamePrompt({msg = config.name..gameConfig.strings:string_common("cangjingge",10)})
            end
        end
        
        local useProps = table.copy(self.castTable)
        if not self.propUse or self.spendPropsData[tostring(self.castTable[4].cid)] < self.castTable[4].num then
            useProps[4] = nil
        end
        if not self.propUse then
            if self.isCastTip then
                gameWindows:openWindow("artifactCreateTip",{showType = "cast"},function (isNoShow,isContinue)
                    self.isCastTip = not isNoShow
                    if isContinue then
                        gameTouch:clickprofbytime(1)
                        UIRequest({type = 5501,isUse = self.propUse,props = useProps})
                    end
                end)
            else
                gameTouch:clickprofbytime(1)
                UIRequest({type = 5501,isUse = self.propUse,props = useProps})
            end
           
        else
            if self.spendPropsData[tostring(self.castTable[4].cid)] < self.castTable[4].num then
                runGamePrompt({msg = gameConfig.strings:string_common("artifact",26)})
            else
                if false and self.isCastTip then
                    gameWindows:openWindow("artifactCreateTip",{showType = "cast"},function (isNoShow,isContinue)
                        self.isCastTip = not isNoShow
                        if isContinue then
                            gameTouch:clickprofbytime(1)
                            UIRequest({type = 5501,isUse = self.propUse,props = useProps})
                        end
                    end)
                else
                    gameTouch:clickprofbytime(1)
                    UIRequest({type = 5501,isUse = self.propUse,props = useProps})
                end
            end
        end
        
    end, CCControlEventTouchUpInside)
    self.rootItems.startbutton:setSwallowsTouch(true)
    self.rootItems.startbutton:setTouchPriority(self.touchPriority)

    self.rootItems.oncestartbutton:addHandleOfControlEvent(function()
        -- 一键打造
        self:openOnecCreate()
    end, CCControlEventTouchUpInside)
    self.rootItems.oncestartbutton:setSwallowsTouch(true)
    self.rootItems.oncestartbutton:setTouchPriority(self.touchPriority)



    for i = 1,3 do
        local key_Ex = i == 1 and "" or "_"..(i - 1)
        self.rootItems["i_button"..key_Ex]:addHandleOfControlEvent(function()
            if not self.spendPropsData then
                return
            end
            gameWindows:openWindow("propSelect",{props = self.castTable,propNums = self.spendPropsData,propSelect = self.propsSelect},function (selectId)
                if selectId then
                    print("lipurpose set selectArtifact",selectId)
                    self:setItem(i,selectId)
                end
                local isOk = self:checkIsOk() 
                if isOk then
                    ui.removeGray("CCControlButton",self.rootItems.startbutton)
                    ui.removeGray("CCControlButton",self.rootItems.oncestartbutton)
                else
                    ui.addGray("CCControlButton",self.rootItems.startbutton)
                    ui.addGray("CCControlButton",self.rootItems.oncestartbutton)
                end
            end)
        end,CCControlEventTouchUpInside)
        self.rootItems["i_button"..key_Ex]:setSwallowsTouch(true)
        self.rootItems["i_button"..key_Ex]:setTouchPriority(self.touchPriority)
    end

    for i = 5,7 do
        local key_Ex = "_"..(i - 1)
        self.rootItems["i_button"..key_Ex]:addHandleOfControlEvent(function()
            if not self.artifacts then
                return
            end
            gameWindows:openWindow("artifactSelect",{data= {artifacts = self.artifacts,hasSelect = self.artifactSelect},consumeStatus = true},function (selectArtifact)
                print("lipurpose set selectArtifact call")
                if selectArtifact then
                    print("lipurpose set selectArtifact",selectArtifact.iid)
                    self.artifactSelect[i - 4] = selectArtifact
                    self:setCommpondItem(i - 4,selectArtifact)
                end
            end)
        end,CCControlEventTouchUpInside)
        self.rootItems["i_button"..key_Ex]:setSwallowsTouch(true)
        self.rootItems["i_button"..key_Ex]:setTouchPriority(self.touchPriority)
    end


    self.rootItems.combutton:addHandleOfControlEvent(function()
        local length = table.getTableLength(self.artifactSelect) 
        if length < 3 then
            return runGamePrompt({msg = gameConfig.strings:string_common("artifact",18)})
        end

        local executeFunc = function ( )
            gameTouch:clickprofbytime(1)
            UIRequest({type = 5502,uses = self.artifactSelect})
        end
        local result = gameWindows.windows["onceRecoin"].module.consumeJudge(self.artifactSelect)
        if result == 0 then
            executeFunc()
        elseif result == 1 then
            gameWindows:openWindow("confirm",{msg = gameConfig.strings:string_common("artifact",183)},executeFunc)
        elseif result == 2 then
            gameWindows:openWindow("confirm",{msg = gameConfig.strings:string_common("artifact",184)},executeFunc)
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.combutton:setSwallowsTouch(true)
    self.rootItems.combutton:setTouchPriority(self.touchPriority)

    self.rootItems.yiJianBtn:addHandleOfControlEvent(function()
        -- 一键重铸
        gameWindows:openWindow("onceRecoin");
    end, CCControlEventTouchUpInside)
    self.rootItems.yiJianBtn:setSwallowsTouch(true)
    self.rootItems.yiJianBtn:setTouchPriority(self.touchPriority - 1)

    self.rootItems.autoBtn:addHandleOfControlEvent(function()
        self:autoAdd()
    end, CCControlEventTouchUpInside)
    self.rootItems.autoBtn:setSwallowsTouch(true)
    self.rootItems.autoBtn:setTouchPriority(self.touchPriority - 1)
end

function artifactCreate.openOnecCreate(self)
    -- 一键打造
    local useProps = table.copy(self.castTable)
    local num = self:getArtifactCount()
    if num > 0 then
        gameWindows:openWindow("onceCreateArtifact",{exchangeNum=num,count = math.floor(self.spendPropsData["20630"]/10),props = useProps})
    else
        runGamePrompt({msg = "道具不足！"})
    end
end

function artifactCreate.setArtifactShow(self,artifact)
    local config = gamedata.config.trump[tostring(artifact.cid)]
    local shenqiSkeletonMeta = require"SkeletonShenqi"
    local skeleton = shenqiSkeletonMeta:init(config,0)
    skeleton:setAnimation("stand",true,0)
    self.rootItems.artifactShow:addChild(skeleton.root or skeleton)
end

function artifactCreate.getCastData(self)
    local castConfig = gamedata.config.global_kv
    self.castTable = ui.getIDandNUMs(castConfig.trump_forging_cost.value)
    local cid,num = ui.getIDandNUM(castConfig.godtrump_forging_cost.value)
    table.insert(self.castTable,{cid = cid,num = num})
    local cids = {}
    for i = 1, 4 do 
        cids[i] = self.castTable[i].cid
    end
    UIRequest({type = 12001, order = 33009, cids = cids})
end

function artifactCreate.getArtifactDatas(self)
    if not GameScene.layers["artifactList"].module.artifactData then 
        GameScene:addUpdate(10032)
    end
    if GameScene:checkUpdate(10032) then
        return
    end
    self:reloadData()
end

function artifactCreate.getData(self)
    
    UIRequest({type = 10032,exclude = true})
end

function artifactCreate.initFixedString(self)
    ui.setLabelString(self.rootItems.fixed3,gameConfig.strings:string_common("artifact",13),77)

    local rich = {
        {fontID = 77,content = gameConfig.strings:string_common("artifact",146),},
        {fontID = 124,content = gameConfig.strings:string_common("artifact",147),},
        {fontID = 77,content = gameConfig.strings:string_common("artifact",148),},
        {fontID = 124,content = gameConfig.strings:string_common("artifact",149),},
    }
    ui.createRichLabel(rich,self.rootItems.fixed4,false)

    local rich = {
        {fontID = 77,content = gameConfig.strings:string_common("artifact",150),},
        {fontID = 124,content = gameConfig.strings:string_common("artifact",151),},
        {fontID = 77,content = gameConfig.strings:string_common("artifact",152),},
        {fontID = 124,content = gameConfig.strings:string_common("artifact",153),},
    }
    ui.createRichLabel(rich,self.rootItems.fixed5,false)

    
    ui.setLabelString(self.rootItems.oncestarttext,gameConfig.strings:string_common("artifact",157),19)
    ui.setLabelString(self.rootItems.starttext,gameConfig.strings:string_common("artifact",12),19)
    self.rootItems.autoText1:setString(gameConfig.strings:string_common("artifact",32))
    ui.setLabelString(self.rootItems.comtxt,gameConfig.strings:string_common("buttontext","hecheng"),19)
    ui.setLabelString(self.rootItems.autoText2,gameConfig.strings:string_common("artifact",15),19)
    -- 一键重铸
    ui.setLabelString(self.rootItems.yiJianText,"一键重铸",19)
end

function artifactCreate.reloadData(self,t)
    local artifactDatas = GameScene.layers["artifactList"].module.artifactData.checked
    self.artifacts = {}
    for i = 1,#artifactDatas do
        if not artifactDatas[i].generalcid then
            local v = artifactDatas[i]
            self.artifacts[#self.artifacts + 1] = v
        end
    end
    if self.selectpage == "commond" then
        self:shiftPage()
    end
end

function artifactCreate.setUsePropNums(self,t)

    for k,v in pairs(t) do
        self.spendPropsData[k] = v
    end
    
    self.castNeedChange = true

    printT(self.spendPropsData,"self.spendPropsData")


    if self.selectpage == "cast" then
        self:shiftPage()
    end
end

function artifactCreate.commpondSuccess(self,t)
    self:getArtifactDatas()
    self.comppondNeedChange = true
    if self.selectpage == "commond" then
        gameTouch:clickprofbytime(4.1)
        self.skeleton:setAnimation("hecheng",false,0)
        self.skeleton:addAnimation("stand",true,0,0)

        local effectNode,items = CCBReaderLoad("UIEffect/shenqihecheng/shenqihecheng", nil, true, "shenqihecheng")
        self.rootItems.effectNode:removeAllChildrenWithCleanup(true)
        self.rootItems.effectNode:addChild(effectNode)

        self.rootItems.artifactNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1.2), CCCallFunc:create(function()
            self:setArtifactShow(t.rewardArtifact["1"])
            local successNode,successItems = CCBReaderLoad("shenqi_new/dazaochenggong", nil, true, "dazaochenggong")
            self.rootItems.successNode:addChild(successNode)
            local animationManager = getAnimationManager(successItems)
            animationManager:setAnimationCompletedCallback(function()
                self.rootItems.effectNode:removeAllChildrenWithCleanup(true)
                self.rootItems.successNode:removeAllChildrenWithCleanup(true)
                local config = gamedata.config.trump[tostring(t.rewardArtifact["1"].cid)]
                gameWindows:openWindow("artifactSInfo",{title = gameConfig.strings:string_common("artifact",39),artifact = t.rewardArtifact["1"]},function ()
                    self.rootItems.artifactShow:removeAllChildrenWithCleanup(true)
                end)
                self:shiftPage()
            end)
            animationManager:runAnimationsForSequenceNamed("success")
            
        end)))
    else
        self:shiftPage()
    end
end

function artifactCreate.castSuccess(self,t)
    --showRewardPopupWindow(t.rewardArtifact)
    self:getArtifactDatas()
    self.castNeedChange = true
    if self.selectpage == "cast" then
        gameTouch:clickprofbytime(4.1)
        self.skeleton:setAnimation("hecheng",false,0)
        local effectNode,items = CCBReaderLoad("UIEffect/shenqihecheng/shenqihecheng", nil, true, "shenqihecheng")
        self.rootItems.effectNode:removeAllChildrenWithCleanup(true)
        self.rootItems.effectNode:addChild(effectNode)
        self.skeleton:addAnimation("stand",true,0,0)

        self.rootItems.artifactNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1.2), CCCallFunc:create(function()
            
            --普通打造 只出一个
            if t.rewardArtifact and t.rewardArtifact["1"] then
                self:setArtifactShow(t.rewardArtifact["1"])
                local successNode,successItems = CCBReaderLoad("shenqi_new/dazaochenggong", nil, true, "dazaochenggong")
                self.rootItems.successNode:addChild(successNode)
                local animationManager = getAnimationManager(successItems)
                animationManager:setAnimationCompletedCallback(function()
                    self.rootItems.effectNode:removeAllChildrenWithCleanup(true)
                    self.rootItems.successNode:removeAllChildrenWithCleanup(true)
                    local config = gamedata.config.trump[tostring(t.rewardArtifact["1"].cid)]
                    gameWindows:openWindow("artifactSInfo",{title = gameConfig.strings:string_common("artifact",37),artifact = t.rewardArtifact["1"]},function ()
                        self.rootItems.artifactShow:removeAllChildrenWithCleanup(true)
                    end)
                end)
                animationManager:runAnimationsForSequenceNamed("success")
            else
            --一键打造 不做任何操作

            end

            --打造完刷新界面显示
            local cids = {}
            for i = 1, 4 do 
                cids[i] = self.castTable[i].cid
            end
            UIRequest({type = 12001, order = 33009, cids = cids})
            
        end)))
    else
        self:updateItem()
        self:shiftPage()
    end
    
end

function artifactCreate.updateItem ( self )
    printT(self.castTable,"self.castTable")
    local cids = {}
        for i = 1, 4 do
            if self.castTable[i] then
                table.insert(cids,self.castTable[i].cid)
            end
        end
    UIRequest({type = 12001, order = 33009, cids = cids})
end


function artifactCreate.clear(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)

    self.selectpage = "cast"
    self.rootNode = nil
    self.rootItems = nil
    self.skeleton = nil

    self.castTable = nil
    self.propUse = true
    self.autoSet = true
    self.artifactSelect = {}
    self.propsSelect = {}
    self.artifacts = nil
    self.castNeedChange = true
    self.comppondNeedChange = true

    self.animationManager = nil
    self.spendPropsData = {}

    self.spendIsEnough = false
end


return artifactCreate