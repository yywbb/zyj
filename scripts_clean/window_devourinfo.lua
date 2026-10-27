--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/9/15
-- Time: 19:24
-- To change this template use File | Settings | File Templates.
--

local devourinfo = {
    rootNode = nil,
    rootItems = nil,
    fragment = {},
}

function devourinfo.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("mochong2/mochong_info", nil, true, "info")

    self.touchPriority = touchPriority

    self:reload(data,callback)

    return self.rootNode
end

function devourinfo.reload(self,data,callback)
    self.callback = callback

    if not data.cid then return end
    if not data.level1 then data.level1 = 1 end
    if not data.level2 then data.level2 = 0 end

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

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("devourinfo")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.doButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("devourinfo")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:setTouchPriority(self.touchPriority)
    ui.setLabelString(self.rootItems.doLab,nil,19)
    --
    local config = gamedata.config.pet2_attr[tostring(data.cid)] or {}
    local skillconfig = gamedata.config.skill or {}
    local breakskillconfig = gamedata.config.breakskill or {}

    self.rootItems.name:setString((config[tostring(data.level2)].name.." ("..lv2str[tostring(data.level2)].."阶)") or "")
    ui.setLabelString(self.rootItems.name,nil, config[tostring(data.level2)].quality and 2*config[tostring(data.level2)].quality-1 or 1)

    --[[
    self.rootItems.power:setString("")
    self.rootItems.levelmax:setString(config[tostring(data.level2)].level)
    self.rootItems.atk:setString(config[tostring(data.level2)].atk + config[tostring(data.level2)].atk_grow*(data.level1-(data.level2 > 0 and config[tostring(data.level2-1)].level or 1)))
    self.rootItems.speed:setString(config[tostring(data.level2)].speed )
    self.rootItems.anger:setString(config[tostring(data.level2)].ap + config[tostring(data.level2)].ap_grow*(data.level1-(data.level2 > 0 and config[tostring(data.level2-1)].level or 1)))
    self.rootItems.back:setString(config[tostring(data.level2)].ap_bout + config[tostring(data.level2)].ap_bout_grow*(data.level1-(data.level2 > 0 and config[tostring(data.level2-1)].level or 1)))
    ]]
    if self.rootItems.generalnode then
        local mowang = gamedata.config.generalanimation[tostring(config[tostring(data.level2)].animationid)].name or "mowang_1"
        self.rootItems.generalnode:removeAllChildrenWithCleanup(true)
        self.Gneral1 = CCSkeletonAnimation:create(mowang.."/"..mowang..".json",mowang.."/"..mowang..".atlas",1)
        if self.Gneral1 then
            self.Gneral1:setAnimation("stand",true,0)
            self.Gneral1:setScale(1.8*(config[tostring(data.level2)].scale or 1))
            self.Gneral1:setPosition(0,0)
            self.rootItems.generalnode:addChild(self.Gneral1)
        end
    end
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
            self.rootItems.zdskill_type:setString(skillconfig[tostring(config[tostring(i)].skillid)]["name"]..":  ")
            self.rootItems.zdskill_desc:setString(skillconfig[tostring(config[tostring(i)].skillid)]["effect-desc"])
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
        -- self.rootItems.bdskill1_type:setString("前排伙伴：")
        self.rootItems.bdskill1_type:setString(gameConfig.strings:string_common("layer_devour",3))
        self.rootItems.bdskill1_desc:setString(q_breakstr)
        if h_breakstr ~= "" then
            -- self.rootItems.bdskill2_type:setString("后排伙伴：")
            self.rootItems.bdskill2_type:setString(gameConfig.strings:string_common("layer_devour",4))
            self.rootItems.bdskill2_desc:setString(h_breakstr)
        else
            self.rootItems.bdskill2_type:setString("")
            self.rootItems.bdskill2_desc:setString("")
        end
    elseif h_breakstr ~= "" then
        -- self.rootItems.bdskill1_type:setString("后排伙伴：")
        self.rootItems.bdskill1_type:setString(gameConfig.strings:string_common("layer_devour",4))
        self.rootItems.bdskill1_desc:setString(h_breakstr)
        self.rootItems.bdskill2_type:setString("")
        self.rootItems.bdskill2_desc:setString("")
    else
        self.rootItems.bdskill1_type:setString("")
        self.rootItems.bdskill1_desc:setString("")
        self.rootItems.bdskill2_type:setString("")
        self.rootItems.bdskill2_desc:setString("")
    end
    ]]
    --
    if self.rootItems.getBtn then
        ui.setLabelString(self.rootItems.getText,nil,18)
        self.rootItems.getBtn:setTouchPriority(self.touchPriority)
        self.rootItems.getBtn:addHandleOfControlEvent(function()
            print("goto")
            gameWindows:openWindow("dropTips",{cid = config["0"].debris, num = self.fragment[tostring(config["0"].debris)] and self.fragment[tostring(config["0"].debris)].num or 0 },nil)
        end, CCControlEventTouchUpInside)
    end

    UIRequest({type = 1044})
end

function devourinfo.setfragment(self,data)
    self.fragment = data.fragment or {}
end

function devourinfo.close(self)
    self.fragment = {}
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return devourinfo