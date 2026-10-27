--神器升级

local shenqiUp= {
	rootNode = nil,
	rootItems = nil,
}

function shenqiUp.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("shenqi/shenqi_up", nil, true, "shenqi_up")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)
    -- self.rootItems.bgNode:setPositionY(self.rootItems.bgNode:getPositionY() + self.bottomHight * toppos/1920)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        GameScene:shiftLayer(GameScene.priorLayer,"down",{selectpage = "equip", sid = param.sid or 1})
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(-104)  
	
	-- self.rootItems.upNode:setPositionY(self.rootItems.upNode:getPositionY() + self.bottomHight)
 --    self.rootItems.strengthenNode:setPositionY(self.rootItems.strengthenNode:getPositionY() + self.bottomHight)
	-- self.rootItems.shengxingNode:setPositionY(self.rootItems.shengxingNode:getPositionY() + self.bottomHight)

    print("shenqiUp.init param ==")
    printT(param)


    self:reload(param.general)
end

function shenqiUp.getSkillDes( self,evolveconfig,stage )

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
    return skilldes..combskilldes
end

function shenqiUp.reload(self,data )
    self.general = data

    local shenqiconfig = gamedata.config.shenqi
    local stageconfig = gamedata.config.shenqi_evolve

    local level = self.general.level4 or 0
    local evolveconfig = stageconfig[tostring(self.general.cid)]
    local levelconfig = shenqiconfig[tostring(level)]

    local nextlevel = level+1
    local nextlevelconfig = shenqiconfig[tostring(nextlevel)] 

    --当前级
    ui.setShenqiIcon(self.rootItems,self.general)
    ui.setLabelString(self.rootItems.name_now,ui.getShenqiName(self.general),11)

    if nextlevelconfig and levelconfig.evolve_lv ~= nextlevelconfig.evolve_lv then
        self.rootItems.skillnode_now:setVisible(true)
        self.rootItems.attrnode_now:setVisible(false)

        local stage = levelconfig.evolve_lv
        local skilldes = self:getSkillDes(evolveconfig,stage)
        self.rootItems.skilldes_now:setString(skilldes)
    else
        self.rootItems.skillnode_now:setVisible(false)
        self.rootItems.attrnode_now:setVisible(true)

        local attrlist = {}
        for k,v in ipairs(ui.attrlist()) do
            if levelconfig[v] and levelconfig[v] > 0 then
                table.insert(attrlist,gameConfig.strings.attr_type[v].."+"..levelconfig[v])
            end
        end

        for i=1,4 do
            ui.setLabelString(self.rootItems["attr_now_"..i],attrlist[i]or "--",14)
        end        
    end

    --下一级
    local nextgeneral = {cid = self.general.cid,level4 = nextlevel}
    ui.setShenqiIcon(self.rootItems,nextgeneral,1)
    ui.setLabelString(self.rootItems.name_next,ui.getShenqiName(nextgeneral),11)

    if nextlevelconfig and levelconfig.evolve_lv ~= nextlevelconfig.evolve_lv then
        self.rootItems.skillnode_next:setVisible(true)
        self.rootItems.attrnode_next:setVisible(false)

        local stage = nextlevelconfig.evolve_lv
        local skilldes = self:getSkillDes(evolveconfig,stage)
        self.rootItems.skilldes_next:setString(skilldes)
    else
        self.rootItems.skillnode_next:setVisible(false)
        self.rootItems.attrnode_next:setVisible(true)

        local attrlist = {}
        if nextlevelconfig then
            for k,v in ipairs(ui.attrlist()) do
                if nextlevelconfig[v] and nextlevelconfig[v] > 0 then
                    table.insert(attrlist,gameConfig.strings.attr_type[v].."+"..nextlevelconfig[v])
                end
            end
        end

        for i=1,4 do
            ui.setLabelString(self.rootItems["attr_next_"..i],attrlist[i]or "--",23)
        end        
    end

    --消耗
    if nextlevelconfig then
        self.rootItems.buttonnode:setVisible(true)
        self.rootItems.maxDescText:setVisible(false)

        ui.setLabelString(self.rootItems.needlevel,
            "需要伙伴等级:"..self.general.level1.."/"..nextlevelconfig.general_lv,
            self.general.level1>=nextlevelconfig.general_lv and 22 or 24)

        self.rootItems.coinNode:setVisible(false)

        local cost = ui.getIDandNUMs(nextlevelconfig.lv_cost)
        self.cost = cost

        local iconidx = 0
        local propcids = {}
        for k,v in ipairs(cost) do
            if v.cid == 1000 then
                self.rootItems.coinNode:setVisible(true)
                ui.setLabelString(self.rootItems.xcoin_lab,"消耗银币: ",13)
                ui.setLabelString(self.rootItems.xcoin,v.num,v.num<=GameScene.roleinfo.coin and 13 or 24)
            elseif iconidx+1<=2 then
                ui.setNewIcon(self.rootItems,{cid = v.cid},iconidx)
                iconidx = iconidx +1
                self.rootItems["refine_prop"..iconidx]:setVisible(true)
                table.insert(propcids,v.cid)
            end
        end
        UIRequest({type = 12001, order = 10261, cids = propcids})

        if iconidx<2 then
            for i=iconidx+1,2 do
                self.rootItems["refine_prop"..i]:setVisible(false)
            end
        end

        if levelconfig.evolve_lv ~= nextlevelconfig.evolve_lv then
            ui.setLabelString(self.rootItems.doLab,"进阶",19)
        else
            ui.setLabelString(self.rootItems.doLab,"强化",19)
        end

        self.rootItems.doButton:addHandleOfControlEvent(function()
            UIRequest({type = 1026,iid = self.general.iid})
        end, CCControlEventTouchUpInside)
        self.rootItems.doButton:setSwallowsTouch(true)
        self.rootItems.doButton:setTouchPriority(-104)  

    else
        self.rootItems.buttonnode:setVisible(false)
        self.rootItems.maxDescText:setVisible(true)
    end
end

function shenqiUp.setPropsData( self,data )
    local iconidx = 0
    for k,v in ipairs(self.cost) do
        if v.cid ~= 1000 and iconidx+1<=2 then
            local keyext = iconidx>0 and "_"..iconidx or ""
            local hasnum = data[tostring(v.cid)] or 0
            ui.setLabelString(self.rootItems["i_num"..keyext],
               hasnum.."/"..v.num,hasnum>=v.num and 13 or 24)
        end
    end
end

function shenqiUp.clear(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end


return shenqiUp
