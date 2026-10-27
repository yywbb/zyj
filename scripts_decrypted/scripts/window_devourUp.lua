--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/9/15
-- Time: 19:24
-- To change this template use File | Settings | File Templates.
--

local devourup = {
    rootNode = nil,
    rootItems = nil,
}

function devourup.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("mochong2/mochong_jinjiechenggong", nil, true, "up")

    self.touchPriority = touchPriority

    self:reload(data,callback)

    return self.rootNode
end

function devourup.reload(self,data,callback)
    self.callback = callback

    local lv2str = {
        ["0"] = "零",
        ["1"] = "一",
        ["2"] = "二",
        ["3"] = "三",
        ["4"] = "四",
        ["5"] = "五",
        ["6"] = "六",
        ["7"] = "七",
        ["8"] = "八",
        ["9"] = "九",
        ["10"] = "十",
    }

    local config = gamedata.config.pet2_attr[tostring(data.cid)] or {}
    local skillconfig = gamedata.config.skill or {}
    local breakskillconfig = gamedata.config.breakskill or {}

    self.rootItems.okButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("devourup")
    end, CCControlEventTouchUpInside)
    self.rootItems.okButton:setSwallowsTouch(true)
    self.rootItems.okButton:setTouchPriority(self.touchPriority)

    self.rootItems.name1:setString(config[tostring(data.level2 > 0 and data.level2-1 or 0)].name.." ("..lv2str[tostring(data.level2-1)].."阶)" )
    self.rootItems.name2:setString(config[tostring(data.level2)].name.." ("..lv2str[tostring(data.level2)].."阶)" )

    ui.setLabelString(self.rootItems.okLab,nil,19)
    ui.setLabelString(self.rootItems.name1,nil, config[tostring(data.level2)].quality and 2*config[tostring(data.level2)].quality-1 or 1)
    ui.setLabelString(self.rootItems.name2,nil, config[tostring(data.level2)].quality and 2*config[tostring(data.level2)].quality-1 or 1)

    --[[
    self.rootItems.levelmax1:setString( config[tostring(data.level2 > 0 and data.level2-1 or 0)].level)
    self.rootItems.levelmax2:setString( config[tostring(data.level2)].level)

    self.rootItems.atk2:setString(config[tostring(data.level2)].atk + config[tostring(data.level2)].atk_grow*(data.level1-(data.level2 > 0 and config[tostring(data.level2-1)].level or 1)))
    self.rootItems.speed2:setString(config[tostring(data.level2)].speed )
    self.rootItems.anger2:setString(config[tostring(data.level2)].ap + config[tostring(data.level2)].ap_grow*(data.level1-(data.level2 > 0 and config[tostring(data.level2-1)].level or 1)))
    self.rootItems.back2:setString(config[tostring(data.level2)].ap_bout + config[tostring(data.level2)].ap_bout_grow*(data.level1-(data.level2 > 0 and config[tostring(data.level2-1)].level or 1)))

    self.rootItems.atk1:setString(config[tostring(data.level2 > 0 and data.level2-1 or 0)].atk + config[tostring(data.level2 > 0 and data.level2-1 or 0)].atk_grow*(data.level1-(data.level2-1 > 0 and config[tostring(data.level2-2)].level or 1)))
    self.rootItems.speed1:setString(config[tostring(data.level2 > 0 and data.level2-1 or 0)].speed )
    self.rootItems.anger1:setString(config[tostring(data.level2 > 0 and data.level2-1 or 0)].ap + config[tostring(data.level2 > 0 and data.level2-1 or 0)].ap_grow*(data.level1-(data.level2-1 > 0 and config[tostring(data.level2-2)].level or 1)))
    self.rootItems.back1:setString(config[tostring(data.level2 > 0 and data.level2-1 or 0)].ap_bout + config[tostring(data.level2 > 0 and data.level2-1 or 0)].ap_bout_grow*(data.level1-(data.level2-1 > 0 and config[tostring(data.level2-2)].level or 1)))
    ]]
    --
    if self.rootItems.generalnode1 then
        local mowang1 = gamedata.config.generalanimation[tostring(config[tostring(data.level2>0 and data.level2-1 or 0)].animationid)].name or "mowang_1"
        self.rootItems.generalnode1:removeAllChildrenWithCleanup(true)
        self.Gneral1 = CCSkeletonAnimation:create(mowang1.."/"..mowang1..".json",mowang1.."/"..mowang1..".atlas",1)
        if self.Gneral1 then
            self.Gneral1:setAnimation("stand",true,0)
            self.Gneral1:setScale(1.8*(config[tostring(data.level2)].scale or 1))
            self.Gneral1:setPosition(0,0)
            self.rootItems.generalnode1:addChild(self.Gneral1)
        end
    end
    if self.rootItems.generalnode2 then
        local mowang2 = gamedata.config.generalanimation[tostring(config[tostring(data.level2)].animationid)].name or "mowang_1"
        self.rootItems.generalnode2:removeAllChildrenWithCleanup(true)
        self.Gneral2 = CCSkeletonAnimation:create(mowang2.."/"..mowang2..".json",mowang2.."/"..mowang2..".atlas",1)
        if self.Gneral2 then
            self.Gneral2:setAnimation("stand",true,0)
            self.Gneral2:setScale(1.8*(config[tostring(data.level2)].scale or 1))
            self.Gneral2:setPosition(0,0)
            self.rootItems.generalnode2:addChild(self.Gneral2)
        end
    end

    --
    --[[
    --skill
    local breakup = {
        q_atk = 0,
        h_atk = 0,
        q_def = 0,
        h_def = 0,
        q_hp = 0,
        h_hp = 0,
    }
    ]]
    for i = 0,data.level2 do
        if config[tostring(i)].skillid and config[tostring(i)].skillid > 0 then
            self.rootItems.zdskill_name:setString(skillconfig[tostring(config[tostring(i)].skillid)]["name"]..": ")
            self.rootItems.zdskill2:setString(skillconfig[tostring(config[tostring(i)].skillid)]["effect-desc"])
        end
        --[[
        if config[tostring(i)].breakskillid and config[tostring(i)].breakskillid > 0 then
            if breakskillconfig[tostring(config[tostring(i)].breakskillid)].target == "6" then
                if breakup["q_"..breakskillconfig[tostring(config[tostring(i)].breakskillid)].attr] then
                    breakup["q_"..breakskillconfig[tostring(config[tostring(i)].breakskillid)].attr] = breakup["q_"..breakskillconfig[tostring(config[tostring(i)].breakskillid)].attr] + (breakskillconfig[tostring(config[tostring(i)].breakskillid)].value or 0)
                end
            elseif breakskillconfig[tostring(config[tostring(i)].breakskillid)].target == "7" then
                if breakup["h_"..breakskillconfig[tostring(config[tostring(i)].breakskillid)].attr] then
                    breakup["h_"..breakskillconfig[tostring(config[tostring(i)].breakskillid)].attr] = breakup["h_"..breakskillconfig[tostring(config[tostring(i)].breakskillid)].attr] + (breakskillconfig[tostring(config[tostring(i)].breakskillid)].value or 0)
                end
            elseif breakskillconfig[tostring(config[tostring(i)].breakskillid)].target == "1" then
                if breakup["q_"..breakskillconfig[tostring(config[tostring(i)].breakskillid)].attr] then
                    breakup["q_"..breakskillconfig[tostring(config[tostring(i)].breakskillid)].attr] = breakup["q_"..breakskillconfig[tostring(config[tostring(i)].breakskillid)].attr] + (breakskillconfig[tostring(config[tostring(i)].breakskillid)].value or 0)
                end
                if breakup["h_"..breakskillconfig[tostring(config[tostring(i)].breakskillid)].attr] then
                    breakup["h_"..breakskillconfig[tostring(config[tostring(i)].breakskillid)].attr] = breakup["h_"..breakskillconfig[tostring(config[tostring(i)].breakskillid)].attr] + (breakskillconfig[tostring(config[tostring(i)].breakskillid)].value or 0)
                end
            end
        end
        ]]
    end
    --[[
    local q_breakstr = ""
    local h_breakstr = ""
    -- if breakup.q_atk > 0 then q_breakstr = q_breakstr.."攻击+"..(breakup.q_atk*100).."%   " end
    -- if breakup.h_atk > 0 then h_breakstr = h_breakstr.."攻击+"..(breakup.h_atk*100).."%   " end
    -- if breakup.q_def > 0 then q_breakstr = q_breakstr.."防御+"..(breakup.q_def*100).."%   " end
    -- if breakup.h_def > 0 then h_breakstr = h_breakstr.."防御+"..(breakup.h_def*100).."%   " end
    -- if breakup.q_hp > 0 then q_breakstr = q_breakstr.."生命+"..(breakup.q_hp*100).."%   " end
    -- if breakup.h_hp > 0 then h_breakstr = h_breakstr.."生命+"..(breakup.h_hp*100).."%   " end
    if breakup.q_atk > 0 then q_breakstr = gameConfig.strings:breakeAtk(q_breakstr,breakup.q_atk) end
    if breakup.h_atk > 0 then h_breakstr = gameConfig.strings:breakeAtk(h_breakstr,breakup.h_atk) end
    if breakup.q_def > 0 then q_breakstr = gameConfig.strings:breakeDef(q_breakstr,breakup.q_def) end
    if breakup.h_def > 0 then h_breakstr = gameConfig.strings:breakeDef(h_breakstr,breakup.h_def) end
    if breakup.q_hp > 0 then q_breakstr = gameConfig.strings:breakeHp(q_breakstr,breakup.q_hp) end
    if breakup.h_hp > 0 then h_breakstr = gameConfig.strings:breakeHp(h_breakstr,breakup.h_hp) end

    if q_breakstr ~= "" then
        -- self.rootItems.bdskill1_type2:setString("前排伙伴：")
        self.rootItems.bdskill1_type2:setString(gameConfig.strings:string_common("layer_devour",3))
        self.rootItems.bdskill1_desc2:setString(q_breakstr)
        if h_breakstr ~= "" then
            -- self.rootItems.bdskill2_type2:setString("后排伙伴：")
            self.rootItems.bdskill2_type2:setString(gameConfig.strings:string_common("layer_devour",4))
            self.rootItems.bdskill2_desc2:setString(h_breakstr)
        else
            self.rootItems.bdskill2_type2:setString("")
            self.rootItems.bdskill2_desc2:setString("")
        end
    elseif h_breakstr ~= "" then
        -- self.rootItems.bdskill1_type2:setString("后排伙伴：")
        self.rootItems.bdskill1_type2:setString(gameConfig.strings:string_common("layer_devour",4))
        self.rootItems.bdskill1_desc2:setString(h_breakstr)
        self.rootItems.bdskill2_type2:setString("")
        self.rootItems.bdskill2_desc2:setString("")
    else
        self.rootItems.bdskill1_type2:setString("")
        self.rootItems.bdskill1_desc2:setString("")
        self.rootItems.bdskill2_type2:setString("")
        self.rootItems.bdskill2_desc2:setString("")
    end

    --]]

end

function devourup.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return devourup �'  