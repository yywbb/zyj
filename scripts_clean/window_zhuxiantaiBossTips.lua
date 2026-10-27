--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/30
-- Time: 上午10:10
-- To change this template use File | Settings | File Templates.
--

local zhuxiantaibosstips = {
    rootNode = nil,
    rootItems = nil,
}

function zhuxiantaibosstips.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("zhuxiantai2/cell_bossinfo", nil, true, "bossinfo")

    self.touchPriority = touchPriority

    self:reload(data,callback)

    return self.rootNode
end

function zhuxiantaibosstips.reload(self,data,callback)
    self.callback = callback

    self.rootItems.lv:setString(data.level or "")

    if gamedata.config.copy_monster[tostring(data.cid)] and gamedata.config.skill[tostring(gamedata.config.copy_monster[tostring(data.cid)].skillid)] then
        -- self.rootItems.skill:setString("BOSS技能特殊效果:  "..gamedata.config.skill[tostring(gamedata.config.copy_monster[tostring(data.cid)].skillid)]["effect-desc"])
        self.rootItems.skill:setString(gameConfig.strings:boosSkill(gamedata.config.skill[tostring(gamedata.config.copy_monster[tostring(data.cid)].skillid)]["effect-desc"]))
    end
end

function zhuxiantaibosstips.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return zhuxiantaibosstips