local  gamedata = gamedata

local  devilSkillDetail = {
    rootNode = nil,
    rootItems = nil,
    opt = 0,
    skillIndex = 0,
    level = 1,
}

function devilSkillDetail.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority
    self.data = data.list
    self.haveSkill = data.skill
    self.level = data.level or 1

    self.nowskillpoint = data.nowskillpoint or 0
    self.nowskillpoint2 = data.nowskillpoint2 or 0
    self.nowskillpoint3 = data.nowskillpoint3 or 0

--    for k,v in ipairs(self.haveSkill) do
--        if v.cid == self.data.id then
--            self.skillIndex = tonumber(k)
--        end
--    end
    self.skillIndex = data.skillIndex or 1

    self.opt = data.opt or 0

    self.rootNode, self.rootItems = CCBReaderLoad("mochong3/mochongskill_info", nil, true, "mochongskill_info")
    self.root:addChild(self.rootNode)

    ui.setLabelString(self.rootItems.title,"技能详情",28)
    ui.setLabelString(self.rootItems.upLabel,nil,19)
    ui.setLabelString(self.rootItems.closeLabel,nil,19)

    ui.setLabelString(self.rootItems.point1,self.nowskillpoint or 0,3)
    if self.data.quality <= 5 then
        ui.setLabelString(self.rootItems.point2,"（"..self.nowskillpoint2.."）",11)
    else
        ui.setLabelString(self.rootItems.point2,"（"..self.nowskillpoint3.."）",213)
    end

    self:devilSkillDeatailInit(data.list)     
    return self.root  
end

function devilSkillDetail.close(self)
    self.level = 1
    self.skillIndex = 0
    self.opt = 0
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    --self.devilList = {}
end

function devilSkillDetail.devilSkillDeatailInit(self,data)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("devilSkillDetail")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.clockButton:addHandleOfControlEvent(function()
        self:onClock()
    end, CCControlEventTouchUpInside)
    self.rootItems.clockButton:setSwallowsTouch(true)
    self.rootItems.clockButton:setTouchPriority(self.touchPriority)

    local string = ""
    if data.attr == "critical" or data.attr == "resilience" or data.attr == "parry" or data.attr == "arp" or data.attr == "dodge" or data.attr == "hit" or data.attr == "criticaldmg" then
        string = gameConfig.strings:string_common("attr_type",data.attr).."+"..(tonumber(data.init+data.init_grow*(self.level-1))*100).."%" or {}
    else
        string = gameConfig.strings:string_common("attr_type",data.attr).."+"..(data.init+data.init_grow*(self.level-1)) or {}
    end

    self.rootItems.skillName:setString(string)
    self.rootItems.skillDetail:setString("上阵所有伙伴"..string)

    self.rootItems.i_soulsprite:setVisible(false)
    ui.setNewIcon(self.rootItems,{cid = data["id"]})
    setSpriteFrameByName(self.rootItems.i_icon,data.icon)

    if self.opt and self.opt == 1 then
        self:setClock()
        self.rootItems.doNode:setVisible(true)
        if data.red_skill and data.red_skill > 0 then
            self.rootItems.upNode:setVisible(true)
            self.rootItems.closeNode:setPositionX(760)
        else
            self.rootItems.upNode:setVisible(false)
            self.rootItems.closeNode:setPositionX(540)
        end
        --
        self.rootItems.upButton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            if self.data.quality <= 5 then
                if self.nowskillpoint2 and self.nowskillpoint2 > 0 then
                    local cb = function()
                        UIRequest({type = 1064,id = self.skillIndex})
                        gameWindows:closeWindowDirect("devilSkillDetail")
                    end
                    gameWindows:openWindow("confirm",{msg = "是否消耗1点红色技能点提升该技能品质？"},cb)
                else
                    runGamePrompt({msg = "红色技能点不足"})
                end
            else
                if self.nowskillpoint3 and self.nowskillpoint3 > 0 then
                    local cb = function()
                        UIRequest({type = 1064,id = self.skillIndex})
                        gameWindows:closeWindowDirect("devilSkillDetail")
                    end
                    gameWindows:openWindow("confirm",{msg = "是否消耗1点金色技能点提升该技能品质？"},cb)
                else
                    runGamePrompt({msg = "金色技能点不足"})
                end
            end
        end, CCControlEventTouchUpInside)
        self.rootItems.upButton:setSwallowsTouch(true)
        self.rootItems.upButton:setTouchPriority(self.touchPriority)
        --
        if self.data.quality <= 5 then
            if self.nowskillpoint2 and self.nowskillpoint2 > 0 then
                ui.removeGray("CCControlButton",self.rootItems.upButton)
            else
                ui.addGray("CCControlButton",self.rootItems.upButton)
            end
        else
            if self.nowskillpoint3 and self.nowskillpoint3 > 0 then
                ui.removeGray("CCControlButton",self.rootItems.upButton)
            else
                ui.addGray("CCControlButton",self.rootItems.upButton)
            end
        end
    else
        self.rootItems.doNode:setVisible(false)
        self.rootItems.upNode:setVisible(false)
        self.rootItems.closeNode:setPositionX(540)
    end

end
function devilSkillDetail.onClock(self)

    local nowlocknum = 0
    for i,v in ipairs(self.haveSkill) do
        if v.lock > 0 then
            nowlocknum = nowlocknum + 1
        end
    end

    local locknum = tonumber(gamedata.config.global_kv.pet3_passiveskill_lock.value)
    if self.haveSkill[self.skillIndex] and self.haveSkill[self.skillIndex].status ~= 0 and self.haveSkill[self.skillIndex].cid ~= 0  then
        if nowlocknum >= locknum and self.haveSkill[self.skillIndex].lock == 0 then
            print("锁定达到最大数")
            runGamePrompt({msg = "锁定达到最大数"})
        else
            --gameWindows:closeWindow("devilSkillDetail")
            gameTouch:clickprofbytime(0.5)
            UIRequest({type = 1060,id = self.skillIndex,lock = self.haveSkill[self.skillIndex].lock})

        end
    end
end

function devilSkillDetail.changelockData(self,aiData )
    self.haveSkill = {}
    for k,v in pairs(aiData.skill) do
        self.haveSkill[tonumber(k)]=v
    end

    self:setClock()
end

function devilSkillDetail.setClock(self)
    if self.haveSkill[self.skillIndex] and self.haveSkill[self.skillIndex].lock and self.haveSkill[self.skillIndex].lock == 0 then
        self.rootItems.isClock:setVisible(false)
    else
        self.rootItems.isClock:setVisible(true)
    end
end


return devilSkillDetail