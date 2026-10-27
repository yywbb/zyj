--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 18/7/30
-- Time: 10:57
-- To change this template use File | Settings | File Templates.
--

local artifactStrengthen = {
    touchPriority  = -101,
    curArtifactData = {},
    artifactNum = 0,
    data = nil,
    artifactData = nil,
    selectAllListData = nil,
}

function artifactStrengthen.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("shenqi_new/shenqi_up", nil, true, "shenqi_up")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.toppos = toppos
    self.rootItems.topnode:setPositionY(toppos)


    self.rootItems.closeButton:addHandleOfControlEvent(function()
        GameScene:shiftLayer("artifact","up")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    -- 强化
    self.rootItems.doButton1:addHandleOfControlEvent(function()
        if self.data then

            local artifactConfig = gamedata.config.trump[tostring(self.data.cid)]
            local nextCof = gamedata.config.trump_strengthen[tostring(artifactConfig.type)][tostring(self.data.level1+1)]
            if artifactConfig.goldTrump == 1 then
                nextCof = gamedata.config.trump_Godstrengthen[tostring(artifactConfig.type)][tostring(self.data.level1+1)]
            end
            if not nextCof then
                runGamePrompt({msg = "当前神器强化已到最大等级"})
                return
            end

            local len = table.getTableLength(self.curArtifactData)
            if len >= self.artifactNum then
                printT(self.curArtifactData,"  强化材料列表")
                printT(self.data,"self.data")

                local executeFunc = function ( )

                    UIRequest({type = 5519,sid = self.data.sid,iid = self.data.iid,expendList = self.curArtifactData})
                end
                local result = self:consumeJudge()
                if result == 0 then
                    executeFunc()
                elseif result == 1 then
                    gameWindows:openWindow("confirm",{msg = gameConfig.strings:string_common("artifact",181)},executeFunc)
                elseif result == 2 then
                    gameWindows:openWindow("confirm",{msg = gameConfig.strings:string_common("artifact",182)},executeFunc)
                end
            else
                runGamePrompt({msg = "材料数量不足"})
            end
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton1:setSwallowsTouch(true)
    self.rootItems.doButton1:setTouchPriority(self.touchPriority)

    -- 一键添加
    self.rootItems.doButton2:addHandleOfControlEvent(function()
        if self.data then
            self.curArtifactData = {}
            local len = table.getTableLength(self.selectAllListData)
            if len >= self.artifactNum then
                len = self.artifactNum
            end
            for i=1,len do
                if self.selectAllListData[i].consumeStatus == 0 then
                    table.insert(self.curArtifactData,self.selectAllListData[i])
                end
            end

            if #self.curArtifactData >= self.artifactNum then
                self:onCreateIcon(self.rootItems.itemContent,{cid = self.data.cid})
            else
                runGamePrompt({msg = "无满足数量的道具！"})
            end
            self.rootItems.itemNum:setString(#self.curArtifactData.."/"..self.artifactNum)
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton2:setSwallowsTouch(true)
    self.rootItems.doButton2:setTouchPriority(self.touchPriority)

    -- 打开神器材料
    self.rootItems.addBtn:addHandleOfControlEvent(function()
        local len = table.getTableLength(self.selectAllListData)
        if self.data then
            gameWindows:openWindow("onceAddStrengthen",{num = self.artifactNum,data = self.selectAllListData,selectList = self.curArtifactData},function(artifact)
                if artifact then
                    gameTouch:clickprofbytime(1)
                    self:selectCallBack(artifact)
                end
            end)
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.addBtn:setSwallowsTouch(true)
    self.rootItems.addBtn:setTouchPriority(self.touchPriority)
    
    -- 添加神器spine
    self.rootItems.addArtifact:addHandleOfControlEvent(function()
        if gameConfig:checkBuildOpen(366) and GameScene:checkopenlevelbyId(366) then
            gameWindows:openWindow("artifactSelect",{showType = "checked",isShowAll = true},function(artifact)
                if artifact then
                    gameTouch:clickprofbytime(1)
                    -- printT(artifact," 选择的神器 ")
                    self:reload({data = artifact })
                end
            end)
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.addArtifact:setSwallowsTouch(true)
    self.rootItems.addArtifact:setTouchPriority(self.touchPriority)
    
    self:reload(param)
    self:initFixedString()
end

--[[
    0.无提示 
    1.有橙色或者红色技能的神器弹出二次确认框
    2.有2个或3个技能的神器弹出二次确认框
]]
function artifactStrengthen.consumeJudge(self)
    
    for i,v in ipairs(self.curArtifactData) do
        for k=1,3 do
            if v["skill"..k] > 0 then
                local config = gamedata.config.breakskill[tostring(v["skill"..k])]

                if config.quality > 4 then
                    return 1
                end
            end
        end
    end

    for i,v in ipairs(self.curArtifactData) do
        local skillnum = 0
        for k=1,3 do
            if v["skill"..k] > 0 then
                skillnum = skillnum + 1
            end
        end

        if skillnum >= 2 then
            return 2
        end
    end

    return 0
end

function artifactStrengthen.onCreateIcon( self,itemNode,data )

    if data == nil then
        self.rootItems.addSp2:setVisible(true)

        local key_Ex = ""
        setSpriteFrameByName(self.rootItems["i_icon"..key_Ex], "alpha")
        setSpriteFrameByName(self.rootItems["i_k_quality"..key_Ex], "b_iconk1")
        setSpriteFrameByName(self.rootItems["i_quality"..key_Ex], "b_iconbg1")
        self.rootItems["i_soulsprite"..key_Ex]:setVisible(false)
        self.rootItems["i_soulnode"..key_Ex]:removeAllChildrenWithCleanup(true)
        self.rootItems["i_suitNode"..key_Ex]:removeAllChildrenWithCleanup(true)
        ui.setLabelString(self.rootItems["i_num"..key_Ex],"",13)
        if self.rootItems["star_starnode"..key_Ex] then
            self.rootItems["star_starnode"..key_Ex]:setVisible(false)
        end

    else
        self.rootItems.addSp2:setVisible(false)
        ui.setNewIcon(self.rootItems,data)
    end

   --  self.rootItems.itemContent:removeAllChildrenWithCleanup(true)
   --  -- body
   -- local curNode,curItems = CCBReaderLoad("icons/new_icon", nil, true, "shenqi_xilian")
   --  curNode:setPosition(0,0)
   --  curNode:setScale(0.8)
   --  itemNode:addChild(curNode)
   --  if data then
   --      ui.setNewIcon(curItems,data)
   --  else
   --  end
end

function artifactStrengthen.updateArtifactData(self,data)
    -- body
    if data.artifacts then
        self.data = data.artifacts["1"]
        if self.data.levelProbs > 0 then
            runGamePrompt({msg = "强化失败"})
        else
            runGamePrompt({msg = "强化成功"})
        end
        ui.removeGray("CCControlButton",self.rootItems.doButton2)
        ui.removeGray("CCControlButton",self.rootItems.doButton1)
        self.curArtifactData = {}
        self:onCreateIcon(self.rootItems.itemContent,nil)

        self:updateContent()
    end
end


function artifactStrengthen.reload(self,data)
    if not data then
        -- 没有数据显示默认状态
        self.rootItems.upnextattnode:setVisible(false)
        self.rootItems.skillDoc:setVisible(false)
        self.rootItems.notSkillDoc:setVisible(true)
        self.rootItems.txtProbs1:setString("0")
        self.rootItems.txtProbs2:setString("0")
        self.rootItems.itemNum:setString("0")
        self.rootItems.cur_num1:setString("0")
        self.rootItems.cur_num2:setString("0")
        self.rootItems.cur_num3:setString("0")
        ui.addGray("CCControlButton",self.rootItems.doButton2)
        ui.addGray("CCControlButton",self.rootItems.doButton1)
        self:onCreateIcon(self.rootItems.itemContent,nil)
        self.rootItems.addnode:setVisible(true)
        return;
    end
    self.rootItems.addnode:setVisible(false)

    self.data = data.data
    GameScene:addUpdate(10032)
    if GameScene:checkUpdate(10032) then
    end

    --选择数据置空
    self.curArtifactData = {}
    self:onCreateIcon(self.rootItems.itemContent,nil)
    self:setJewelDesc()
    self.rootItems.upnextattnode:setVisible(true)
    -- self.rootItems.skillDoc:setVisible(true)
    self.rootItems.notSkillDoc:setVisible(false)
    ui.removeGray("CCControlButton",self.rootItems.doButton2)
    ui.removeGray("CCControlButton",self.rootItems.doButton1)

    self:updateContent()
end

function artifactStrengthen.updateContent( self )
    printT(self.data,"  self.data  === ")
    
    local artifactConfig = gamedata.config.trump[tostring(self.data.cid)]

    local nameStr = artifactConfig.goldTrump > 0 and gameConfig.strings:string_common("equips",8).."·"..artifactConfig.name or artifactConfig.name
    
    if self.data.level1 == 0 then
        ui.setLabelString(self.rootItems.artifactName,nameStr,65)
    else
        ui.setLabelString(self.rootItems.artifactName,nameStr.."+"..self.data.level1,65)
    end

    self.rootItems.cur_num1:setString("+"..tostring(self.data.levelAttack).."%")
    self.rootItems.cur_num2:setString("+"..tostring(self.data.levelDef).."%")
    self.rootItems.cur_num3:setString("+"..tostring(self.data.levelHP).."%")
    -- local curCof = gamedata.config.trump_strengthen[tostring(artifactConfig.type)][tostring(self.data.level1)]
    -- 设置道具的显示

    local nextCof = gamedata.config.trump_strengthen[tostring(artifactConfig.type)][tostring(self.data.level1+1)]

    if artifactConfig.goldTrump == 1 then
        nextCof = gamedata.config.trump_Godstrengthen[tostring(artifactConfig.type)][tostring(self.data.level1+1)]
    end


    if nextCof then
        self.rootItems.txtProbs1:setString(math.min(nextCof.basics_success/10+self.data.levelProbs/10,100).."%")
        

        self.rootItems.cur_next_num1:setString("+"..math.floor((nextCof.attr1Value * self.data.attr1)/100).."%")
        self.rootItems.cur_next_num2:setString("+"..math.floor((nextCof.attr2Value * self.data.attr1)/100).."%")
        self.rootItems.cur_next_num3:setString("+"..math.floor((nextCof.attr3Value * self.data.attr1)/100).."%")
        -- 特殊属性的显示暂未配好
        self.rootItems.attLevel:setString("强化+"..nextCof.preview.."开启特殊属性")

        self.rootItems.attr1Value:setString(tostring(nextCof.systlem))
        -- 失败成功率
        self.rootItems.txtProbs2:setString((nextCof.promote_success/10).."%")
        -- 消耗的数量
        self.artifactNum = nextCof.num
        self.rootItems.itemNum:setString("0/"..self.artifactNum)
    else
        print("配置不存在或者已经达到最大")
        self.rootItems.upnextattnode:setVisible(false)
        self.rootItems.skillDoc:setVisible(false)
        self.rootItems.notSkillDoc:setVisible(false)
        self.rootItems.txtProbs1:setString("0%")
        self.rootItems.txtProbs2:setString("0%")
        self.rootItems.itemNum:setString("")
    end

end

function artifactStrengthen.setJewelDesc(self)
    self.rootItems.artifactSpine:removeAllChildrenWithCleanup(true)
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
    skeleton:setPosition(0,-80)
    skeleton:setScale(0.7)
    skeleton:setAnimation("stand",true,0)
    self.rootItems.artifactSpine:addChild(skeleton.root or skeleton)
    self.rootItems.addnode:setVisible(false)

end

-- 选择列表回调
function artifactStrengthen.selectCallBack(self,artifact)
    printT(artifact," 选择的神器 ")
    self.curArtifactData = artifact
    local len = table.getTableLength(self.curArtifactData)
    if len > 0 then
        self:onCreateIcon(self.rootItems.itemContent,{cid = self.data.cid})
    else
        self:onCreateIcon(self.rootItems.itemContent,nil)
        -- self.rootItems.itemContent:removeAllChildrenWithCleanup(true)
    end
    self.rootItems.itemNum:setString(len.."/"..self.artifactNum)
end

function artifactStrengthen.lockCallback(self,t)
    --神器加锁数据 无需重新排序
    if self.selectAllListData then
        for i,v in ipairs(self.selectAllListData) do
            if v.iid == t.artifactSid then
                v.isLockState = t.isLock
                v.consumeStatus = gameWindows.windows["artifactSelect"].module.consumeStatus(v)
                break
            end
        end
    end

    --选择的消耗神器被锁定
    if self.curArtifactData and next(self.curArtifactData) then
        for k,v in pairs(self.curArtifactData) do
            if v.iid == t.artifactSid then
                if t.isLock == 1  then
                    table.remove(self.curArtifactData,k)
                    self:selectCallBack(self.curArtifactData)
                end
                break
            end
        end
    end

end

-- 设置神器数据
function artifactStrengthen.setArtifactData(self,t)
    -- self:orderArtifactData(t.data)
    -- printT(self.artifactData,"  artifactStrengthen.setArtifactData  ")
    if self.data then
        local listData = {}
        for k,v in pairs(t.data) do
            if v.isChecked == 1 and self.data.iid ~= v.iid and not v.generalcid then
                local config1 = gamedata.config.trump[tostring(self.data.cid)]
                local config2 = gamedata.config.trump[tostring(v.cid)]

                --相同神器 金光对金光
                if config1.goldTrump == config2.goldTrump then
                    if (v.cid == self.data.cid) or (v.cid == config1.consumption) then
                        v.consumeStatus = gameWindows.windows["artifactSelect"].module.consumeStatus(v)
                        table.insert(listData,v)
                    end
                end
            end
        end

        self.selectAllListData = listData
        gameWindows.windows["artifactSelect"].module.consumeSort(self.selectAllListData)
    end
end


function artifactStrengthen.orderArtifactData(self,artifactData)
    self.artifactData = {}
    self.artifactData.primeData = artifactData
    self.artifactData.all = {}
    self.artifactData.checked = {}
    self.artifactData.unChecked = {}
    for k,v in pairs(artifactData) do
        self.artifactData.all[#self.artifactData.all + 1] = v
        if v.isChecked > 0 then
            -- generalcid
            -- printT(v," ====== ")
           self.artifactData.checked[#self.artifactData.checked + 1] = v
        else
            self.artifactData.unChecked[#self.artifactData.unChecked + 1] = v
        end


    end
    local sortFunc = function (a,b)
        if a.isChecked ~= b.isChecked then
            return a.isChecked > b.isChecked
        end

        if a.generalcid and not b.generalcid then 
            return true
        end

        if b.generalcid and not a.generalcid then 
            return false
        end
        if a.score ~= b.score then
            return a.score > b.score
        end

        local total1,total2 = 0,0
        for i = 1,4 do
            total1 = a["jewel"..i] > 0 and a["jewel"..i]%100 + total1 or total1 + 0
            total2 = b["jewel"..i] > 0 and b["jewel"..i]%100 + total2 or total2 + 0
        end
        if total1 ~= total2 then
            return total1 > total2
        end

        local skillS1,skillS2 = 0,0
        for i = 1,3 do
            if a["skill"..i] > 0 then
                local integral = gamedata.config.breakskill[tostring(a["skill"..i])].integral
                skillS1 = skillS1 + integral
            end
            if b["skill"..i] > 0 then
                local integral = gamedata.config.breakskill[tostring(b["skill"..i])].integral
                skillS2 = skillS2 + integral
            end
        end
        if skillS1 ~= skillS2 then
            return skillS1 > skillS2
        end

        local config1 = gamedata.config.trump[tostring(a.cid)]
        local config2 = gamedata.config.trump[tostring(b.cid)]
        if config1.goldTrump ~= config2.goldTrump then
            return config1.goldTrump > config2.goldTrump
        end

        return a.cid < b.cid
    end
    table.sort(self.artifactData.all,sortFunc)
    table.sort(self.artifactData.checked,sortFunc)
    table.sort(self.artifactData.unChecked,sortFunc)
end

function artifactStrengthen.initFixedString(self)
    ui.setLabelString(self.rootItems.doLab2,gameConfig.strings:string_common("artifact",160),19)
    ui.setLabelString(self.rootItems.doLab1,gameConfig.strings:string_common("artifact",161),19)
end


function artifactStrengthen.clear(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.curArtifactData = {}
    self.data = nil
    self.artifactNum = 0
    self.artifactData = nil
    self.selectAllListData = nil
end


return artifactStrengthen



 �E  