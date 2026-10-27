-- 新技能详情
-- zhangzhixin

local generalSkill = {
    rootNode = nil,
    rootItems = nil,
}

function generalSkill.open(self,touchPriority,data,callback)
    print("generalSkill.open ============")
    -- printT(data)
    self.root = ui.createNode()
    self.touchPriority = touchPriority
    self.data = data.data
    self.sid = data.sid
    self.skilltype = data.skilltype
    self.fragmentConfig = gamedata.config.general_fragment

    self.rootNode, self.rootItems = CCBReaderLoad(self.skilltype == "combskill" and "general_new/skill_info_h" or "general_new/skill_info", nil, true, "skillinfo")
    self.root:removeAllChildrenWithCleanup(true)
    self.root:addChild(self.rootNode)

    self:load(data,callback)
    return self.root, true
end

function generalSkill.close(self)
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil
    self.data = nil
    self.sid = nil  
end

function generalSkill.load( self,aiData )
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("generalInfoSkill")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.rootItems.doButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("generalInfoSkill")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:setTouchPriority(self.touchPriority)
    self.rootItems.title:setString(gameConfig.strings:string_common("generalInfo",16))
    ui.setLabelString(self.rootItems.doLab,gameConfig.strings:string_common("generalInfo",13),19)
    if self.skilltype == "combskill" then
        self.rootItems.s_iscombskill:setVisible(true)
    else
        self.rootItems.s_iscombskill:setVisible(false)
    end

    if self.islead and self.islead == 1 then
        self.rootItems.s_skill_lv:setVisible(false)
    elseif self.skilltype == "skill" then
        --self.rootItems.doNode:setVisible(true)
    else
        --self.rootItems.doNode:setVisible(false)
    end
    --
    if self.opt == 2 then
        --self.rootItems.doNode:setVisible(false)
    end
    --

    local skill_str = "skill"
    local config_str = "skill"
    if self.skilltype == "combskill" or self.skilltype == "leadskill" then
        skill_str = "combskill"
        config_str = "combskill"
    elseif gamedata.config["combskill"][tostring(self.data.general["skill"].cid)] then
        skill_str = "skill"
        config_str = "combskill"
    end

    local skillconfig = gamedata.config[config_str][tostring(self.data.general[skill_str].cid)]
    ui.setNewIcon(self.rootItems,self.data.general[skill_str])

    ui.setLabelString(self.rootItems.s_skill_name,skillconfig.name,7)
    
    ui.setLabelString(self.rootItems.s_iscombskill,nil,7)
    self.rootItems.s_skill_lv:setVisible(false)
    -- ui.setLabelString(self.rootItems.s_skill_desc,skillconfig.desc,13)
    self.rootItems.s_skill_desc:setString(skillconfig.desc)
    ui.setLabelString(self.rootItems.s_skill_lv,nil,14)
    self.rootItems["xiaoguo"]:setString(skillconfig["effect-desc"] or "")
    if self.skilltype == "combskill" then
        local config1 = gamedata.config.general[tostring(skillconfig.cid1)]

        ui.setNewIconName(self.rootItems,{cid = config1.generalid})

        self.rootItems.i_button_1:addHandleOfControlEvent(function()
            print("rootItems.i_button_1..is")
            gameWindows:openWindow("dropTips",{cid = self:getFragmentID(self.fragmentConfig,config1.generalid)},nil)
        end, CCControlEventTouchUpInside)
        self.rootItems.i_button_1:setSwallowsTouch(true)
        self.rootItems.i_button_1:setTouchPriority(self.touchPriority)

        if skillconfig.cid2 and skillconfig.cid2>0 then
            self.rootItems.combNode2:setVisible(true)
            local config2 = gamedata.config.general[tostring(skillconfig.cid2)]
            ui.setNewIconName(self.rootItems,{cid = config2.generalid},1)
            self.rootItems.i_button_2:addHandleOfControlEvent(function()
                print("getBtn.i_button_2..is")
                gameWindows:openWindow("dropTips",{cid = self:getFragmentID(self.fragmentConfig,config2.generalid)},nil)
            end, CCControlEventTouchUpInside)
            self.rootItems.i_button_2:setSwallowsTouch(true)
            self.rootItems.i_button_2:setTouchPriority(self.touchPriority)
        else
            self.rootItems.combNode2:setVisible(false)
        end


        if skillconfig.cid3 and skillconfig.cid3>0 then
            self.rootItems.combNode3:setVisible(true)
            local config3 = gamedata.config.general[tostring(skillconfig.cid3)]
            ui.setNewIconName(self.rootItems,{cid = config3.generalid},2)
            self.rootItems.i_button_3:addHandleOfControlEvent(function()
                print("getBtn.i_button_3..is")
                gameWindows:openWindow("dropTips",{cid = self:getFragmentID(self.fragmentConfig,config3.generalid)},nil)
            end, CCControlEventTouchUpInside)
            self.rootItems.i_button_3:setSwallowsTouch(true)
            self.rootItems.i_button_3:setTouchPriority(self.touchPriority)
        else
            self.rootItems.combNode3:setVisible(false)
        end
    end

    if (self.islead and self.islead == 1) or gamedata.config.general[tostring(self.data.general.cid)].quality > 1 then
        self.rootItems.skillshowButton:setVisible(true)
    else
        self.rootItems.skillshowButton:setVisible(false)
    end
    self.rootItems.skillshowButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        if self.skilltype == "combskill" or self.skilltype == "leadskill" then
            ui.skillView(self.data.general.combskill.cid)
        else
            ui.skillView(self.data.general.skill.cid)
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.skillshowButton:setSwallowsTouch(true)
    self.rootItems.skillshowButton:setTouchPriority(self.touchPriority)		
end
--通过英雄id 获得 碎片id
function generalSkill.getFragmentID( self,aiFragmenCongfig,aiHeroID )
    local id = aiFragmenCongfig[tostring(aiHeroID + 1000)] and aiFragmenCongfig[tostring(aiHeroID + 1000)].general or 0
    if id ==   aiHeroID then
        return aiFragmenCongfig[tostring(aiHeroID + 1000)].id
    end
    for k,v in paris( aiFragmenCongfig) do
        if v.general == aiHeroID then
            return v.id
        end
    end
end

return generalSkill