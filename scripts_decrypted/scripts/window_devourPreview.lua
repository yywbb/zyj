--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/9/15
-- Time: 19:24
-- To change this template use File | Settings | File Templates.
--

local devourpreview = {
    rootNode = nil,
    rootItems = nil,
}

function devourpreview.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("mochong2/mochong_jinjieyulan", nil, true, "up")

    self.touchPriority = touchPriority

    self:reload(data,callback)

    return self.rootNode
end

function devourpreview.reload(self,data,callback)
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

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("devourpreview")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    --
    local skilldata = {}
    local zdskilldata = {}
    local bdskilldata = {}

    local config = gamedata.config.pet2_attr[tostring(data.cid)] or {}
    local skillconfig = gamedata.config.skill or {}
    local breakskillconfig = gamedata.config.breakskill or {}

    for k,v in pairs(config)  do
       table.insert(skilldata,v)
       if v.skillid and v.skillid > 0 then
           -- table.insert(zdskilldata,{ phase = v.phase, title = "主动技能:" ,desc = skillconfig[tostring(config[tostring(v.phase)].skillid)].desc})
           table.insert(zdskilldata,{ phase = v.phase, title = gameConfig.strings:string_common("popups","zdskill"),desc = skillconfig[tostring(config[tostring(v.phase)].skillid)]["effect-desc"],name = skillconfig[tostring(config[tostring(v.phase)].skillid)]["name"]})
       end
    end

    local sortById = function(a,b) return a.phase < b.phase end
    table.sort(skilldata, sortById)
    table.sort(zdskilldata, sortById)

    local breakup = {
        q_atk = 0,
        h_atk = 0,
        q_def = 0,
        h_def = 0,
        q_hp = 0,
        h_hp = 0,
    }
    for k,v in ipairs(skilldata) do

        if v.breakskillid and v.breakskillid > 0 then
            if breakskillconfig[tostring(v.breakskillid)].target == "6" then
                if breakup["q_"..breakskillconfig[tostring(v.breakskillid)].attr] then
                    breakup["q_"..breakskillconfig[tostring(v.breakskillid)].attr] = breakup["q_"..breakskillconfig[tostring(v.breakskillid)].attr] + (breakskillconfig[tostring(v.breakskillid)].value or 0)
                end
            elseif breakskillconfig[tostring(v.breakskillid)].target == "7" then
                if breakup["h_"..breakskillconfig[tostring(v.breakskillid)].attr] then
                    breakup["h_"..breakskillconfig[tostring(v.breakskillid)].attr] = breakup["h_"..breakskillconfig[tostring(v.breakskillid)].attr] + (breakskillconfig[tostring(v.breakskillid)].value or 0)
                end
            elseif breakskillconfig[tostring(v.breakskillid)].target == "1" then
                if breakup["q_"..breakskillconfig[tostring(v.breakskillid)].attr] then
                    breakup["q_"..breakskillconfig[tostring(v.breakskillid)].attr] = breakup["q_"..breakskillconfig[tostring(v.breakskillid)].attr] + (breakskillconfig[tostring(v.breakskillid)].value or 0)
                end
                if breakup["h_"..breakskillconfig[tostring(v.breakskillid)].attr] then
                    breakup["h_"..breakskillconfig[tostring(v.breakskillid)].attr] = breakup["h_"..breakskillconfig[tostring(v.breakskillid)].attr] + (breakskillconfig[tostring(v.breakskillid)].value or 0)
                end
            end
        end

        local q_breakstr = ""
        local h_breakstr = ""
        -- if breakup.q_atk > 0 then q_breakstr = q_breakstr.."攻击+"..(breakup.q_atk*100).."%   " end
        -- if breakup.h_atk > 0 then h_breakstr = h_breakstr.."攻击+"..(breakup.h_atk*100).."%   " end
        -- if breakup.q_def > 0 then q_breakstr = q_breakstr.."防御+"..(breakup.q_def*100).."%   " end
        -- if breakup.h_def > 0 then h_breakstr = h_breakstr.."防御+"..(breakup.h_def*100).."%   " end
        -- if breakup.q_hp > 0 then q_breakstr = q_breakstr.."生命+"..(breakup.q_hp*100).."%   " end
        -- if breakup.h_hp > 0 then h_breakstr = h_breakstr.."生命+"..(breakup.h_hp*100).."%   " end

        -- table.insert(bdskilldata,{ phase = v.phase, title = "被动技能:",desc_q = q_breakstr,desc_h = h_breakstr})
        if breakup.q_atk > 0 then q_breakstr = gameConfig.strings:breakeAtk(q_breakstr,breakup.q_atk) end
        if breakup.h_atk > 0 then h_breakstr = gameConfig.strings:breakeAtk(h_breakstr,breakup.h_atk) end
        if breakup.q_def > 0 then q_breakstr = gameConfig.strings:breakeDef(q_breakstr,breakup.q_def) end
        if breakup.h_def > 0 then h_breakstr = gameConfig.strings:breakeDef(h_breakstr,breakup.h_def) end
        if breakup.q_hp > 0 then q_breakstr = gameConfig.strings:breakeHp(q_breakstr,breakup.q_hp) end
        if breakup.h_hp > 0 then h_breakstr = gameConfig.strings:breakeHp(h_breakstr,breakup.h_hp) end

        table.insert(bdskilldata,{ phase = v.phase, title = gameConfig.strings:string_common("popups","bdskill"),desc_q = q_breakstr,desc_h = h_breakstr})

    end

    table.sort(bdskilldata, sortById)


    --
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(920, 240)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("mochong2/cell_jinjieyulan", nil, true, "cell")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            --

            -- ccbDocumentControler.phase:setString(lv2str[tostring(bdskilldata[a1+1].phase)].."阶")
            ccbDocumentControler.phase:setString(gameConfig.strings:jieNum(lv2str[tostring(bdskilldata[a1+1].phase)]))
            -- ccbDocumentControler.desc_q:setString(bdskilldata[a1+1].desc_q ~= "" and bdskilldata[a1+1].desc_q or "无加成")
            -- ccbDocumentControler.desc_h:setString(bdskilldata[a1+1].desc_h ~= "" and bdskilldata[a1+1].desc_h or "无加成")
            ccbDocumentControler.desc_q:setString(bdskilldata[a1+1].desc_q ~= "" and bdskilldata[a1+1].desc_q or gameConfig.strings:string_common("popups","wujiacheng"))
            ccbDocumentControler.desc_h:setString(bdskilldata[a1+1].desc_h ~= "" and bdskilldata[a1+1].desc_h or gameConfig.strings:string_common("popups","wujiacheng"))
            for k,v in ipairs(zdskilldata) do
                if bdskilldata[a1+1].phase >= v.phase then
                    ccbDocumentControler.type_zd:setString(v.name..": ")
                    ccbDocumentControler.desc_zd:setString(v.desc)
                end
            end

            ui.setLabelString(ccbDocumentControler.phase,nil,21)

            --
            ccbDocumentControler.generalnode:removeAllChildrenWithCleanup(true)
            if bdskilldata[a1+1].phase == data.level2 then
                local mowang = gamedata.config.generalanimation[tostring(config[tostring(data.level2)].animationid)].name or "mowang_1"
                local Gneral1 = CCSkeletonAnimation:create(mowang.."/"..mowang..".json",mowang.."/"..mowang..".atlas",1)
                if Gneral1 then
                    Gneral1:setAnimation("stand",true,0)
                    Gneral1:setScale(0.5*(config[tostring(data.level2)].scale or 1))
                    Gneral1:setScaleX(-0.5*(config[tostring(data.level2)].scale or 1))
                    Gneral1:setPosition(0,0)
                    ccbDocumentControler.generalnode:addChild(Gneral1)
                end
            end
            --
            cellCCB:setPosition(920/2, 240/2)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(bdskilldata)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    local ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listnode:getContentSize().width,
        viewheight = self.rootItems.listnode:getContentSize().height,
        dire = 1
    })
    self.rootItems.listnode:addChild(ListTableView)
    ListTableView:setTouchPriority(self.touchPriority)



end

function devourpreview.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return devourpreview �$  