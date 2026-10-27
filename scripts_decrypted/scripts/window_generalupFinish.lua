--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/11/5
-- Time: 下午4:16
-- To change this template use File | Settings | File Templates.
--

local generalupfinish = {
    rootNode = nil,
    rootItems = nil,
    scopetype = {
        [1] = "tian",
        [2] = "di",
        [3] = "ren",
    },
}

function generalupfinish.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("general_new/tupochenggong", nil, true, "tupochenggong")
    self.touchPriority = touchPriority
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("generalupfinish")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority-1)


    self:reload(data,callback)

    return self.rootNode,true
end

function generalupfinish.reload(self,data,callback)
    self.data = data.data
    --printT(self.data)
    local generalConfig = gamedata.config.general[tostring(self.data.general.cid)]
    local nextgeneralConfig = gamedata.config.general[tostring(self.data.nextGeneral.cid)]
    local generalName = gamedata.config.generalanimation[tostring(nextgeneralConfig.animationid)].name
    if nextgeneralConfig.fashion_id == 0 then --非时装
        if self.data.nextGeneral.illusionGeneralCid == nil then
            generalName = ui.getGeneralAnimationid(generalName, self.data.nextGeneral)
        end
    end
    
    self.General = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
    self.General:setAnimation("stand",true,0)
    self.General:setScale(2.6)
    self.rootItems.general:addChild(self.General)

    if nextgeneralConfig.quality and nextgeneralConfig.quality >= 7 then
        ui.setLabelString(self.rootItems.generalnamenext,nextgeneralConfig.name..(self.data.nextGeneral.level2>0 and " +"..self.data.nextGeneral.level2 or ""), 213)
    else
        ui.setLabelString(self.rootItems.generalnamenext,nextgeneralConfig.name..(self.data.nextGeneral.level2>0 and " +"..self.data.nextGeneral.level2 or ""), nextgeneralConfig.quality>0 and 2*nextgeneralConfig.quality-1 or 1)
    end
    if generalConfig.quality and generalConfig.quality >= 7 then
        ui.setLabelString(self.rootItems.generalname,generalConfig.name..(self.data.general.level2>0 and " +"..self.data.general.level2 or ""), 213)
    else
        ui.setLabelString(self.rootItems.generalname,generalConfig.name..(self.data.general.level2>0 and " +"..self.data.general.level2 or ""), generalConfig.quality>0 and 2*generalConfig.quality-1 or 1)
    end


--    self.rootItems.atk:setString(self.data.general.atk)
--    self.rootItems.def:setString(self.data.general.defense)
--    self.rootItems.hp:setString(self.data.general.hp)
--    self.rootItems.speed:setString(self.data.general.speed)
--
--    self.rootItems.atknext:setString(self.data.nextGeneral.atk)
--    self.rootItems.defnext:setString(self.data.nextGeneral.defense)
--    self.rootItems.hpnext:setString(self.data.nextGeneral.hp)
--    self.rootItems.speednext:setString(self.data.nextGeneral.speed)

    if self.data.general.scope and self.data.general.scope > 0 then
        setSpriteFrameByName(self.rootItems.goldtype_now,"tujin_"..self.scopetype[self.data.general.scope])
    else
        setSpriteFrameByName(self.rootItems.goldtype_now,"alpha")
    end
    --    
    if self.data.nextGeneral.scope and self.data.nextGeneral.scope > 0 then
        setSpriteFrameByName(self.rootItems.goldtype_next,"tujin_"..self.scopetype[self.data.nextGeneral.scope])
    else
        setSpriteFrameByName(self.rootItems.goldtype_next,"alpha")
    end    


    if nextgeneralConfig.quality and nextgeneralConfig.quality >= 7 then

        self.rootItems.attr_atk:setString("仙攻")
        self.rootItems.attr_def:setString("仙防")
        self.rootItems.attr_hp:setString("仙命")

        ui.setLabelString(self.rootItems.atk,self.data.general.g_atk,14)
        ui.setLabelString(self.rootItems.def,self.data.general.g_defense,14)
        ui.setLabelString(self.rootItems.hp,self.data.general.g_hp,14)
        ui.setLabelString(self.rootItems.speed,self.data.general.speed,14)

        ui.setLabelString(self.rootItems.atknext,self.data.nextGeneral.g_atk,23)
        ui.setLabelString(self.rootItems.defnext,self.data.nextGeneral.g_defense,23)
        ui.setLabelString(self.rootItems.hpnext,self.data.nextGeneral.g_hp,23)
        ui.setLabelString(self.rootItems.speednext,self.data.nextGeneral.speed,23)

        if self.data.nextGeneral.g_atk > self.data.general.g_atk then
            self.rootItems.up_atk:setVisible(true)
        else
            self.rootItems.up_atk:setVisible(false)
        end    
        if self.data.nextGeneral.g_defense > self.data.general.g_defense then
            self.rootItems.up_def:setVisible(true)
        else
            self.rootItems.up_def:setVisible(false)
        end   
        if self.data.nextGeneral.g_hp > self.data.general.g_hp then
            self.rootItems.up_hp:setVisible(true)
        else
            self.rootItems.up_hp:setVisible(false)
        end   
        if self.data.nextGeneral.speed > self.data.general.speed then
            self.rootItems.up_speed:setVisible(true)
        else
            self.rootItems.up_speed:setVisible(false)
        end   

        local goldlv = (self.data.nextGeneral.level2)-(gamedata.config.global_kv.partner_breakthrough_limit and tonumber(gamedata.config.global_kv.partner_breakthrough_limit.value) or 13) 
        local scope = self.data.nextGeneral["g_score"..goldlv] or 0
        local newskillid = nextgeneralConfig["gold"..goldlv.."_will_skills_"..scope]
        if newskillid and newskillid ~= 0 then
            self.rootItems.newskillnode:setVisible(true)
            ui.setLabelString(self.rootItems.newskillname,"解锁技能: "..gamedata.config.breakskill[tostring(newskillid)].name,48)
            ui.setLabelString(self.rootItems.newskilldes,gamedata.config.breakskill[tostring(newskillid)].desc,14)
        else
            self.rootItems.newskillnode:setVisible(false)
        end
    else 

        self.rootItems.attr_atk:setString("攻击")
        self.rootItems.attr_def:setString("防御")
        self.rootItems.attr_hp:setString("生命")

        ui.setLabelString(self.rootItems.atk,self.data.general.atk,14)
        ui.setLabelString(self.rootItems.def,self.data.general.defense,14)
        ui.setLabelString(self.rootItems.hp,self.data.general.hp,14)
        ui.setLabelString(self.rootItems.speed,self.data.general.speed,14)

        ui.setLabelString(self.rootItems.atknext,self.data.nextGeneral.atk,23)
        ui.setLabelString(self.rootItems.defnext,self.data.nextGeneral.defense,23)
        ui.setLabelString(self.rootItems.hpnext,self.data.nextGeneral.hp,23)
        ui.setLabelString(self.rootItems.speednext,self.data.nextGeneral.speed,23)

        if self.data.nextGeneral.atk > self.data.general.atk then
            self.rootItems.up_atk:setVisible(true)
        else
            self.rootItems.up_atk:setVisible(false)
        end    
        if self.data.nextGeneral.defense > self.data.general.defense then
            self.rootItems.up_def:setVisible(true)
        else
            self.rootItems.up_def:setVisible(false)
        end   
        if self.data.nextGeneral.hp > self.data.general.hp then
            self.rootItems.up_hp:setVisible(true)
        else
            self.rootItems.up_hp:setVisible(false)
        end   
        if self.data.nextGeneral.speed > self.data.general.speed then
            self.rootItems.up_speed:setVisible(true)
        else
            self.rootItems.up_speed:setVisible(false)
        end   

        local newskillid = nextgeneralConfig["break"..(self.data.nextGeneral.level2)]
        if newskillid and newskillid ~= 0 then
            self.rootItems.newskillnode:setVisible(true)
            ui.setLabelString(self.rootItems.newskillname,"解锁技能: "..gamedata.config.breakskill[tostring(newskillid)].name,48)
            ui.setLabelString(self.rootItems.newskilldes,gamedata.config.breakskill[tostring(newskillid)].desc,14)
        else
            self.rootItems.newskillnode:setVisible(false)
        end
    end
    --
    if self.data.general.level2 == 10 then
        if guide.controller then
            guide.controller:NewSystem(607)
        end
        ui.setLabelString(self.rootItems.fashionname,"激活红"..generalConfig.name.."皮肤",11,38)
        savePartnerfashionOnceToSqlite(self.data.nextGeneral.cid,1)
    elseif self.data.general.level2 == 13 then
        if guide.controller then
            guide.controller:NewSystem(607)
        end
        ui.setLabelString(self.rootItems.fashionname,"激活彩金"..generalConfig.name.."皮肤",11,38)
        savePartnerfashionOnceToSqlite(self.data.nextGeneral.cid,1)
    end

end

function generalupfinish.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return generalupfinish

   �$  