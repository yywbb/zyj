

local artifactSkillUp = {
    rootNode = nil,
    rootItems = nil,
    isCanLevelup = false,    
    data = {},
    curPos = 1,
}

function artifactSkillUp.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("shenqi_new/tc_skillup", nil, true, "tc_skillup")
    self.touchPriority = touchPriority

    self.rootItems.closeBtn:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("artifactSkillUp")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeBtn:setSwallowsTouch(true)
    self.rootItems.closeBtn:setTouchPriority(self.touchPriority)


    ui.setLabelString(self.rootItems.noLab,gameConfig.strings:string_common("popups","quxiao"),18)
    self.rootItems.noButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("artifactSkillUp")
    end, CCControlEventTouchUpInside)
    self.rootItems.noButton:setSwallowsTouch(true)
    self.rootItems.noButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.yesLab,gameConfig.strings:string_common("popups","queding"),18)
    self.rootItems.yesButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        if self.isCanLevelup == true then
            UIRequest({type = 5543,iid = self.data.iid,pos = self.curPos,xprops = self.castTable})
        else
            runGamePrompt({msg = "道具数量不足"})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.yesButton:setSwallowsTouch(true)
    self.rootItems.yesButton:setTouchPriority(self.touchPriority)

    self.curPos = data.pos
    self:reloadData(data.data);
    return self.rootNode;
end



function artifactSkillUp.reloadData( self,data)
    print(" artifactSkillUp.reloadListData ");
    printT(data)
    self.data = data
    local curSkillId = self.data["skill"..self.curPos]
    printT(curSkillId," curSkillId   ======    ")
    local skillConfig = gamedata.config.breakskill[tostring(curSkillId)]
    if skillConfig then
        ui.setLabelString(self.rootItems.skillName1,skillConfig.name,(skillConfig.quality > 0 and skillConfig.quality or 1) * 2)
        ui.setLabelString(self.rootItems.skill1,":"..skillConfig.desc,(skillConfig.quality > 0 and skillConfig.quality or 1) * 2)
    end

    local cof2 = gamedata.config.trump_skillRnd
    -- printT(cof2,"  cof2   ======    ")
    local nextSkillId = nil
    for k,targetData in pairs(cof2) do
        for index,v in pairs(targetData) do
            if tostring(v.skill5) == tostring(curSkillId) then
                nextSkillId = v.skill6
                break
            elseif tostring(v.skill6) == tostring(curSkillId) then
                if v.skill7 then
                    nextSkillId = v.skill7
                end
                break
            elseif tostring(v.skill7) == tostring(curSkillId) then
                if v.skill8 then
                    nextSkillId = v.skill8
                end
                break
            elseif tostring(v.skill8) == tostring(curSkillId) then
                nextSkillId = nil
                break
            end
        end
    end
    if nextSkillId then
        local nextCof = gamedata.config.breakskill[tostring(nextSkillId)]
        if nextCof then
            ui.setLabelString(self.rootItems.skillName2,nextCof.name,(nextCof.quality > 0 and nextCof.quality or 1) * 2)
            ui.setLabelString(self.rootItems.skill2,":"..nextCof.desc,(nextCof.quality > 0 and nextCof.quality or 1) * 2)
        else
            self.rootItems.skillName2:setString("无")
            self.rootItems.skill2:setString("无")
        end
    else
        print(" 技能 ID 不存在==========")
        self.rootItems.skillName2:setString("无")
        self.rootItems.skill2:setString("无")
    end
    local cofList = ui.getIDRandNums(gamedata.config.trump_config.skill_up_lv.value)
    printT(cofList," === = = = = = = ==")
    if skillConfig.quality == cofList[1][1] then
        self.castTable = ui.getIDandNUMs(gamedata.config.trump_config.skill_cost_5.value)
    elseif skillConfig.quality == cofList[2][1] then
        self.castTable = ui.getIDandNUMs(gamedata.config.trump_config.skill_cost_6.value)
    end
    printT(self.castTable," 道具消耗  ")
    local cids = {}
    table.insert(cids,self.castTable[1].cid)
    if self.castTable[2] then
        table.insert(cids,self.castTable[2].cid)
    end
    UIRequest({type = 12001, order = 32003, cids = cids})
end

-- 道具数量更新
function artifactSkillUp.setUpPropNum( self,data)
    printT(data," artifactSkillUp.setUpPropNum ")
    self.isCanLevelup = false
    ui.addGray("CCControlButton",self.rootItems.yesButton)
    self.rootItems.itemNode1:removeAllChildrenWithCleanup(true)
    self.rootItems.itemNode2:removeFromParentAndCleanup(true)
    local len = table.getTableLength(self.castTable)
    if len == 1 then
        local cid1 = self.castTable[1].cid
        self:onCreateIcon(self.rootItems.itemNode1,{cid = cid1,num = self.castTable[1].num..'/'..data[tostring(cid1)]},0.8)
        if data[tostring(cid1)] >= self.castTable[1].num then
            self.isCanLevelup = true
            ui.removeGray("CCControlButton",self.rootItems.yesButton)
        end
    elseif len == 2 then
        local cid1 = self.castTable[1].cid
        local cid2 = self.castTable[2].cid
        self:onCreateIcon(self.rootItems.itemNode1,{cid = cid1,num = self.castTable[1].num..'/'..data[tostring(cid1)]},0.8)
        self:onCreateIcon(self.rootItems.itemNode2,{cid = cid2,num = self.castTable[2].num..'/'..data[tostring(cid2)]},0.8)
        if data[tostring(cid1)] >= self.castTable[1].num and data[tostring(cid2)] >= self.castTable[2].num then
            self.isCanLevelup = true
            ui.removeGray("CCControlButton",self.rootItems.yesButton)
        end
    end
end


function artifactSkillUp.onCreateIcon( self,itemNode,data,curScale )
    -- body
   local curNode,curItems = CCBReaderLoad("icons/new_icon", nil, true, "shenqi_xilian")
    curNode:setPosition(0,0)
    curNode:setScale(curScale)
    itemNode:addChild(curNode)
    ui.setNewIcon(curItems,data)
    -- curItems
end

function artifactSkillUp.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    -- self.callback = nil
end

return artifactSkillUp