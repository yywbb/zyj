--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/4/8
-- Time: 16:32
-- To change this template use File | Settings | File Templates.
--

local gangbossRule = {
    rootNode = nil,
    rootItems = nil,
}

function gangbossRule.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("gonghui2/gangboss_rule", nil, true, "gangboss_rule")
    self.touchPriority = touchPriority

    if self.rootItems.labelNode then
        ui.createRichLabel({
            {fontID = 905,content = gamedata.config.system_intro["49"].intro},
        },self.rootItems.labelNode,true,{min_line_dis = 1})
    end

    self:reload(data,callback)
    return self.rootNode
end

function gangbossRule.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("gangbossRule")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    -- --
    -- local needlevel = gamedata.config.global_kv.sociaty_boss_class and gamedata.config.global_kv.sociaty_boss_class.value or 0
    -- local needvip = 0
    -- for i = 1, table.getTableLength(gamedata.config.vip) do
    --     if gamedata.config.vip[tostring(i)] and gamedata.config.vip[tostring(i)].vip_inspire and tonumber(gamedata.config.vip[tostring(i)].vip_inspire) > 0 then
    --         needvip = i
    --         break
    --     end
    -- end
    -- --

    -- self.rootItems.str1:setString(gameConfig.strings:gangbossrule1(needlevel))
    -- self.rootItems.str2:setString(gameConfig.strings:gangbossrule2(needvip))
    -- self.rootItems.str3:setString(gameConfig.strings:string_common("guild_boss_rule",3))
    -- self.rootItems.str4:setString(gameConfig.strings:string_common("guild_boss_rule",4))
    -- self.rootItems.str5:setString(gameConfig.strings:string_common("guild_boss_rule",5))


end

function gangbossRule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return gangbossRule