--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 16/2/14
-- Time: 下午5:38
-- To change this template use File | Settings | File Templates.
--

local battleVs = {
    rootNode = nil,
    rootItems = nil,
}

function battleVs.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("backGround/sporst_battle.ccbi", nil, true, "sporst_battle")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode, true
end

function battleVs.reload(self,t,callback)

    self.callback = callback

    ui.setIconLv(self.rootItems,{cid  = t.vs_a.profile,level = t.vs_a.level})
    ui.setIconLv(self.rootItems,{cid  = t.vs_b.profile,level = t.vs_b.level},1)

    ui.setLabelString(self.rootItems.name_a,t.vs_a.name,21)
    ui.setLabelString(self.rootItems.name_b,t.vs_b.name,21)

    self.rootItems.power_a:setString(t.vs_a.power > 0 and t.vs_a.power or "?")
    self.rootItems.power_b:setString(t.vs_b.power > 0 and t.vs_b.power or "?")

    local animationManager = getAnimationManager(self.rootItems)
    animationManager:setAnimationCompletedCallback(function()
        gameWindows:closeWindowDirect("battleVs")
    end)
    animationManager:runAnimationsForSequenceNamed("start")
end

function battleVs.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
        self.callback = nil
    end
end

return battleVs