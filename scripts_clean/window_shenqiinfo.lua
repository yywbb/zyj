--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/25
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--

local shenqi = {
    rootNode = nil,
    rootItems = nil,

}

function shenqi.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("shenqi/shenqi_info", nil, true, "shenqi_info")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function shenqi.reload(self,data,callback)
    self.callback = callback
    ui.setLabelString(self.rootItems.title,"神器详情",18)
    local shenqiconfig = gamedata.config.shenqi
    local stageconfig = gamedata.config.shenqi_evolve

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("shenqiinfo")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    ui.setShenqiIcon(self.rootItems,data.general)
    self.rootItems.level:setString(ui.getShenqiName(data.general))

    self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    self.rootItems.scrollnode:setTouchPriority(self.touchPriority)
    self.rootItems.container:setPositionY(-190)  

    local level = data.general.level4 or 0

    local evolveconfig = stageconfig[tostring(data.general.cid)]
    local levelconfig = shenqiconfig[tostring(level)]

    self.rootItems.desc:setString(evolveconfig.desc)

    if not shenqiconfig[tostring(level+1)] then
        self.rootItems.buttonnode:setVisible(false)
        self.rootItems.maxnode:setVisible(true)
    else
        self.rootItems.buttonnode:setVisible(true)
        self.rootItems.maxnode:setVisible(false)

        local nextlevelconfig = shenqiconfig[tostring(level+1)] 

        ui.setLabelString(self.rootItems.needlevel,
            "需要伙伴等级:"..data.general.level1.."/"..nextlevelconfig.general_lv,
            data.general.level1>=nextlevelconfig.general_lv and 22 or 24)

        if levelconfig.evolve_lv ~= nextlevelconfig.evolve_lv then
            ui.setLabelString(self.rootItems.doLab,"进阶",19)
        else
            ui.setLabelString(self.rootItems.doLab,"强化",19)
        end

        self.rootItems.doButton:addHandleOfControlEvent(function()
            GameScene:shiftLayer("shenqiup","up",{general = data.general,sid = data.sid})
        end, CCControlEventTouchUpInside)
        self.rootItems.doButton:setSwallowsTouch(true)
        self.rootItems.doButton:setTouchPriority(self.touchPriority)
    end

    local attrlist = {}
    for k,v in ipairs(ui.attrlist()) do
        if levelconfig[v] and levelconfig[v] > 0 then
            table.insert(attrlist,gameConfig.strings.attr_type[v].."+"..levelconfig[v])
        end
    end

    for i=1,4 do
        self.rootItems["attr"..i]:setString(attrlist[i] or "--")
    end

    local stage = levelconfig.evolve_lv

    local normalskill = evolveconfig["skillid"..stage]>0 
                            and evolveconfig["skillid"..stage] 
                            or (evolveconfig["passiveskillid"..stage]>0 and evolveconfig["passiveskillid"..stage] or 0)

    local combskill = evolveconfig["combskill"..stage]>0 and evolveconfig["combskill"..stage] or 0

    local skilldes,combskilldes = "",""
    if normalskill>0 then
        local skillconfig = gamedata.config.skill[tostring(normalskill)] or gamedata.config.combskill[tostring(normalskill)]
        skilldes = "技能: "..skillconfig["skill-desc"].."\n"
    else
        skilldes = "技能: 无\n"
    end
    if combskill>0 then
        local skillconfig = gamedata.config.combskill[tostring(combskill)] 
        combskilldes = "合体技:"..skillconfig["skill-desc"]
    else
        combskilldes = "合体技: 无"
    end

    self.rootItems.skilldes:setString(skilldes..combskilldes)
end

function shenqi.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return shenqi

