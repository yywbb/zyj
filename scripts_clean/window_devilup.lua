--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/25
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--

local devilup = {
    rootNode = nil,
    rootItems = nil,
}

function devilup.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("devil2/n_devil2_up", nil, true, "n_devil2_up")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function devilup.reload(self,datas,callback)
    self.callback = callback
    --ui.setLabelString(self.rootItems.confirmtext,"确 定",18)


    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("devilup")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    --
    local config = gamedata.config.protagonist_grow or {}
    local maxlv = table.getTableLength(config) or 1
    local data = GameScene.protagonist
    --
    ui.setNewIcon(self.rootItems,{cid = data.general.cid},1)
    if datas.oldcid and datas.oldcid > 0 then
        ui.setNewIcon(self.rootItems,{cid = datas.oldcid},0)
    else
        ui.setNewIcon(self.rootItems,{cid = data.general.cid},0)
    end
    --
    self.rootItems.atk:setString(data.general.atk-config[tostring(data.level2)]["atk_grow"] or 0)
    self.rootItems.def:setString(data.general.defense-config[tostring(data.level2)]["def_grow"] or 0)
    self.rootItems.hp:setString(data.general.hp-config[tostring(data.level2)]["hp_grow"] or 0)
    self.rootItems.speed:setString(data.general.speed-config[tostring(data.level2)]["speed_grow"] or 0)

    if data.level2 <= maxlv then
        self.rootItems.up_atk:setString((config[tostring(data.level2)]["atk_grow"] > 0) and ("+"..config[tostring(data.level2)]["atk_grow"]) or "")
        self.rootItems.up_def:setString((config[tostring(data.level2)]["def_grow"] > 0) and ("+"..config[tostring(data.level2)]["def_grow"]) or "")
        self.rootItems.up_hp:setString((config[tostring(data.level2)]["hp_grow"] > 0) and ("+"..config[tostring(data.level2)]["hp_grow"]) or "")
        self.rootItems.up_speed:setString((config[tostring(data.level2)]["speed_grow"] > 0) and ("+"..config[tostring(data.level2)]["speed_grow"]) or "")

        self.rootItems.next_atk:setString(data.general.atk) --(config[tostring(data.level2)]["atk_grow"] + data.general.atk)
        self.rootItems.next_def:setString(data.general.defense) --(config[tostring(data.level2)]["def_grow"] + data.general.defense)
        self.rootItems.next_hp:setString(data.general.hp) --(config[tostring(data.level2)]["hp_grow"] + data.general.hp)
        self.rootItems.next_speed:setString(data.general.speed) --(config[tostring(data.level2)]["speed_grow"] + data.general.speed)

        --
        self.rootItems["skill_zd1_node"]:setVisible(false)
        if data.level2 == 2 then
            if gamedata.config.general[tostring(data.general.cid)] and gamedata.config.general[tostring(data.general.cid)].combskillid and gamedata.config.general[tostring(data.general.cid)].combskillid > 0 then
                self.rootItems["skill_zd1_node"]:setVisible(true)
                self.rootItems["skill_desc_zd"]:setString(gamedata.config.combskill[tostring(gamedata.config.general[tostring(data.general.cid)].combskillid)].name or "")
            end
        end
        --
        self.rootItems["skill_bd_node"]:setVisible(true)
        self.rootItems["skill_zd_node"]:setVisible(true)
        -- self.rootItems["skill_desc_zd"]:setString(data.level2>4 and "攻击全体目标" or ("随机攻击"..(data.level2).."个目标"))
        self.rootItems["skill_desc_zd"]:setString(data.level2>4 and gameConfig.strings:string_common("popups","gongji") or (gameConfig.strings:staMu(data.level2)))
        local skillconfig = gamedata.config.breakskill
        self.rootItems["skill_desc_bd"]:setString(skillconfig[tostring(gamedata.config.protagonist_grow[tostring(data.level2)].skill_ext)].desc)
    else
        self.rootItems.up_atk:setString("")
        self.rootItems.up_def:setString("")
        self.rootItems.up_hp:setString("")
        self.rootItems.up_speed:setString("")

        self.rootItems.next_atk:setString(data.general.atk)
        self.rootItems.next_def:setString(data.general.defense)
        self.rootItems.next_hp:setString(data.general.hp)
        self.rootItems.next_speed:setString(data.general.speed)

        self.rootItems["skill_bd_node"]:setVisible(false)
        self.rootItems["skill_zd_node"]:setVisible(false)
    end

end

function devilup.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return devilup

