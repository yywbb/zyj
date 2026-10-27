
--进阶弹窗

local devilsuccessUp = {
    rootNode = nil,
    rootItems = nil,
    skillchange = false,
    scopetype = {
        [1] = "tian",
        [2] = "di",
        [3] = "ren",
    },
}

function devilsuccessUp.open(self,touchPriority,data,callback)
    if data.data.newdata.general.cid ~= data.data.olddata.general.cid then
        self.skillchange = true
    end

    if gamedata.config.protagonist_grow[tostring(data.data.newdata.level2)].skill_ext and gamedata.config.protagonist_grow[tostring(data.data.newdata.level2)].skill_ext+0 > 0 then
        self.skillchange = true
    end

    if gamedata.config.protagonist_grow[tostring(data.data.newdata.level2)].gold_will_skills and gamedata.config.protagonist_grow[tostring(data.data.newdata.level2)].gold_will_skills ~= "" then
        self.skillchange = true
    end 

    self.rootNode, self.rootItems = CCBReaderLoad(self.skillchange and "devil/n_devil2_up" or "devil/n_devil2_up_d", nil, true, "n_devil2_up")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function devilsuccessUp.reload(self,data,callback)
    self.callback = callback

    --确定按钮
    self.rootItems.confirmbtn:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("devilsuccessUp")
    end,CCControlEventTouchUpInside)
    self.rootItems.confirmbtn:setSwallowsTouch(true)
    self.rootItems.confirmbtn:setTouchPriority(self.touchPriority)
    ui.setLabelString(self.rootItems.confirmtxt,nil,19)

    --name
    self.rootItems.name1:setString(ui.leadName(data.data.olddata.level2))
    if gamedata.config.general[tostring(data.data.olddata.general.cid)].quality and gamedata.config.general[tostring(data.data.olddata.general.cid)].quality >= 7 then
        ui.setLabelString(self.rootItems.name1,nil, 213)
    else
        ui.setLabelString(self.rootItems.name1,nil, gamedata.config.general[tostring(data.data.olddata.general.cid)].quality~=0 and 2*gamedata.config.general[tostring(data.data.olddata.general.cid)].quality-1 or 1)
    end

    self.rootItems.name2:setString(ui.leadName(data.data.newdata.level2))
    if gamedata.config.general[tostring(data.data.newdata.general.cid)].quality and gamedata.config.general[tostring(data.data.newdata.general.cid)].quality >= 7 then
        ui.setLabelString(self.rootItems.name2,nil, 213)
    else
        ui.setLabelString(self.rootItems.name2,nil, gamedata.config.general[tostring(data.data.newdata.general.cid)].quality~=0 and 2*gamedata.config.general[tostring(data.data.newdata.general.cid)].quality-1 or 1)
    end

    --攻击的属性
    self.rootItems.atk1:setString(data.data.olddata.general.atk or 0)
    self.rootItems.atk2:setString(data.data.newdata.general.atk or 0)
    --生命的属性
    self.rootItems.hp1:setString(data.data.olddata.general.hp or 0)
    self.rootItems.hp2:setString(data.data.newdata.general.hp or 0)
    --防御的属性
    self.rootItems.def1:setString(data.data.olddata.general.defense or 0)
    self.rootItems.def2:setString(data.data.newdata.general.defense or 0)
    --速度的属性
    self.rootItems.speed1:setString(data.data.olddata.general.speed or 0)
    self.rootItems.speed2:setString(data.data.newdata.general.speed or 0)
    --
    local growconfig = gamedata.config.protagonist_grow or {}
    --
    self.rootItems["generalNode1"]:removeAllChildrenWithCleanup(true)
    local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(data.data.olddata.general.cid)].animationid)].name

    local wing = {level = GameScene.protagonist.w_l, color = GameScene.protagonist.w_c }
    local Gneral1 = ui.itemcache:loadSkeleton(generalName,wing)
    --local Gneral1 = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
    Gneral1:setAnimation("stand",true,0)
    Gneral1:setScale(1)
    Gneral1:setPosition(0,0)
    self.rootItems["generalNode1"]:addChild(Gneral1.root or Gneral1)

    self.rootItems["levelEffectNode1"]:removeAllChildrenWithCleanup(true)
    local Node11,Item11 = CCBReaderLoad("UIEffect/renwushengjie/renwushengjie_"..(growconfig[tostring(data.data.olddata.level2+1)] and (math.mod(data.data.olddata.level2,5)+1) or 5), nil, true, "jie")
    Node11:setScale(0.7)
    self.rootItems.levelEffectNode1:addChild(Node11)
    --
    --
    self.rootItems["generalNode2"]:removeAllChildrenWithCleanup(true)
    local generalName2 = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(data.data.newdata.general.cid)].animationid)].name

    local Gneral2 = ui.itemcache:loadSkeleton(generalName2,wing)
    --local Gneral2 = CCSkeletonAnimation:create(generalName2.."/"..generalName2..".json",generalName2.."/"..generalName2..".atlas",1)
    Gneral2:setAnimation("stand",true,0)
    Gneral2:setScale(1)
    Gneral2:setPosition(0,0)
    self.rootItems["generalNode2"]:addChild(Gneral2.root or Gneral2)

    self.rootItems["levelEffectNode2"]:removeAllChildrenWithCleanup(true)
    local Node22,Item22 = CCBReaderLoad("UIEffect/renwushengjie/renwushengjie_"..(growconfig[tostring(data.data.newdata.level2+1)] and (math.mod(data.data.newdata.level2,5)+1) or 5), nil, true, "jie")
    Node22:setScale(0.7)
    self.rootItems.levelEffectNode2:addChild(Node22)
    --

    if data.data.olddata.general.scope and data.data.olddata.general.scope > 0 then
        setSpriteFrameByName(self.rootItems.goldtype_now,"tujin_"..self.scopetype[data.data.olddata.general.scope])
    else
        setSpriteFrameByName(self.rootItems.goldtype_now,"alpha")
    end

    if data.data.newdata.general.scope and data.data.newdata.general.scope > 0 then
        setSpriteFrameByName(self.rootItems.goldtype_next,"tujin_"..self.scopetype[data.data.newdata.general.scope])
    else
        setSpriteFrameByName(self.rootItems.goldtype_next,"alpha")
    end

    if self.rootItems.newattrnode then
        if data.data.newdata.level2 and data.data.newdata.level2 > 23 then
            self.rootItems.newattrnode:setVisible(true)
            self.rootItems.oldattrnode:setVisible(false)
            --
            self.rootItems.new_atk:setString(data.data.olddata.general.atk or 0)
            self.rootItems.new_atk_add:setString((data.data.newdata.general.atk - data.data.olddata.general.atk > 0) and ("+"..(data.data.newdata.general.atk - data.data.olddata.general.atk)) or "")
            self.rootItems.new_def:setString(data.data.olddata.general.defense or 0)
            self.rootItems.new_def_add:setString((data.data.newdata.general.defense - data.data.olddata.general.defense > 0) and ("+"..(data.data.newdata.general.defense - data.data.olddata.general.defense)) or "")
            self.rootItems.new_hp:setString(data.data.olddata.general.hp or 0)
            self.rootItems.new_hp_add:setString((data.data.newdata.general.hp - data.data.olddata.general.hp > 0) and ("+"..(data.data.newdata.general.hp - data.data.olddata.general.hp)) or "")
            self.rootItems.new_speed:setString(data.data.olddata.general.speed or 0)
            self.rootItems.new_speed_add:setString((data.data.newdata.general.speed - data.data.olddata.general.speed > 0) and ("+"..(data.data.newdata.general.speed - data.data.olddata.general.speed)) or "")
            self.rootItems.new_g_atk:setString(data.data.olddata.general.g_atk or 0)
            self.rootItems.new_g_atk_add:setString((data.data.newdata.general.g_atk - data.data.olddata.general.g_atk > 0) and ("+"..(data.data.newdata.general.g_atk - data.data.olddata.general.g_atk)) or "")
            self.rootItems.new_g_def:setString(data.data.olddata.general.g_defense or 0)
            self.rootItems.new_g_def_add:setString((data.data.newdata.general.g_defense - data.data.olddata.general.g_defense > 0) and ("+"..(data.data.newdata.general.g_defense - data.data.olddata.general.g_defense)) or "")
            self.rootItems.new_g_hp:setString(data.data.olddata.general.g_hp or 0)
            self.rootItems.new_g_hp_add:setString((data.data.newdata.general.g_hp - data.data.olddata.general.g_hp > 0) and ("+"..(data.data.newdata.general.g_hp - data.data.olddata.general.g_hp)) or "")

        else 
            self.rootItems.newattrnode:setVisible(false)
            self.rootItems.oldattrnode:setVisible(true)
        end
    end
    --
    --skill
    if self.skillchange then
        local bdNode,bdItems = CCBReaderLoad("devil/cell_skill2", nil, true, "skill")
        self.rootNode:addChild(bdNode)
        if data.data.newdata.general.cid ~= data.data.olddata.general.cid then
            local zdNode,zdItems = CCBReaderLoad("devil/cell_skill", nil, true, "skill")
            self.rootNode:addChild(zdNode)
            -- zdItems["skill_type"]:setString("主动技能提升: ")
            zdItems["skill_type"]:setString(gameConfig.strings:string_common("popups","skillSelf"))
            zdItems["skill_name"]:setString(gamedata.config.skill[tostring(gamedata.config.general[tostring(data.data.newdata.general.cid)].skillid)].name or "")
            ui.setLabelString(zdItems["skill_name"],nil, gamedata.config.skill[tostring(gamedata.config.general[tostring(data.data.newdata.general.cid)].skillid)].quality~=0 and 2*gamedata.config.skill[tostring(gamedata.config.general[tostring(data.data.newdata.general.cid)].skillid)].quality-1 or 1)
            zdItems["desc"]:setString(gamedata.config.skill[tostring(gamedata.config.general[tostring(data.data.newdata.general.cid)].skillid)]["skill-desc"] or "")
            ui.setNewIcon(zdItems,{cid = gamedata.config.general[tostring(data.data.newdata.general.cid)].skillid},0)
            if gamedata.config.general[tostring(data.data.newdata.general.cid)] and gamedata.config.general[tostring(data.data.newdata.general.cid)].combskillid and gamedata.config.general[tostring(data.data.newdata.general.cid)].combskillid > 0 then
                local zdNode1,zdItems1 = CCBReaderLoad("devil/cell_skill", nil, true, "skill")
                self.rootNode:addChild(zdNode1)
                if gamedata.config.general[tostring(data.data.olddata.general.cid)].combskillid and gamedata.config.general[tostring(data.data.olddata.general.cid)].combskillid > 0 then
                    -- zdItems1["skill_type"]:setString("主动技能提升: ")
                    zdItems1["skill_type"]:setString(gameConfig.strings:string_common("popups","skillSelf"))
                else
                    -- zdItems1["skill_type"]:setString("掌握主动技能: ")
                    zdItems1["skill_type"]:setString(gameConfig.strings:string_common("popups","handSkill"))
                end
                zdItems1["skill_name"]:setString(gamedata.config.combskill[tostring(gamedata.config.general[tostring(data.data.newdata.general.cid)].combskillid)].name or "")
                ui.setLabelString(zdItems1["skill_name"],nil, gamedata.config.combskill[tostring(gamedata.config.general[tostring(data.data.newdata.general.cid)].combskillid)].quality~=0 and 2*gamedata.config.combskill[tostring(gamedata.config.general[tostring(data.data.newdata.general.cid)].combskillid)].quality-1 or 1)
                zdItems1["desc"]:setString(gamedata.config.combskill[tostring(gamedata.config.general[tostring(data.data.newdata.general.cid)].combskillid)]["skill-desc"]or "")
                ui.setNewIcon(zdItems1,{cid = gamedata.config.general[tostring(data.data.newdata.general.cid)].combskillid},0)
                --
                zdNode1:setPosition(540,660)
                zdNode:setPosition(540,460)
                bdNode:setPosition(540,260)
            else
                zdNode:setPosition(540,660)
                bdNode:setPosition(540,460)
            end
        else
            bdNode:setPosition(540,660)
        end

        if gamedata.config.protagonist_grow[tostring(data.data.newdata.level2)].gold_will_skills and gamedata.config.protagonist_grow[tostring(data.data.newdata.level2)].gold_will_skills ~= "" then
            local goldlv = data.data.newdata.level2 - 23
            local breakskillid = 0
            local skilltmp = {}
            skilltmp = ui.getIDandNUMs(gamedata.config.protagonist_grow[tostring(data.data.newdata.level2)].gold_will_skills)
            for k,v in pairs(skilltmp) do
                if data.data.newdata.general["g_score"..goldlv] and data.data.newdata.general["g_score"..goldlv] == v.cid then
                    breakskillid = v.num
                end    
            end
            if breakskillid > 0 then
                bdNode:setVisible(true)
                local skillconfig = gamedata.config.breakskill
                bdItems["skill_name"]:setString(skillconfig[tostring(breakskillid)].name or "")
                ui.setLabelString(bdItems["skill_name"],nil,1)
                bdItems["desc"]:setString(skillconfig[tostring(breakskillid)].desc or "")
            else
                bdNode:setVisible(false)
            end    
        elseif gamedata.config.protagonist_grow[tostring(data.data.newdata.level2)].skill_ext and gamedata.config.protagonist_grow[tostring(data.data.newdata.level2)].skill_ext+0 > 0 then
            bdNode:setVisible(true)
            local skillconfig = gamedata.config.breakskill
            bdItems["skill_name"]:setString((gamedata.config.protagonist_grow[tostring(data.data.newdata.level2)].skill_ext and gamedata.config.protagonist_grow[tostring(data.data.newdata.level2)].skill_ext+0 > 0) and skillconfig[tostring(gamedata.config.protagonist_grow[tostring(data.data.newdata.level2)].skill_ext)].name or "")
            ui.setLabelString(bdItems["skill_name"],nil,1)
            bdItems["desc"]:setString((gamedata.config.protagonist_grow[tostring(data.data.newdata.level2)].skill_ext and gamedata.config.protagonist_grow[tostring(data.data.newdata.level2)].skill_ext+0 > 0) and skillconfig[tostring(gamedata.config.protagonist_grow[tostring(data.data.newdata.level2)].skill_ext)].desc or "")
        else
            bdNode:setVisible(false)
        end
    end
    --
end

function devilsuccessUp.close(self)
    self.skillchange = false
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end



return devilsuccessUp


