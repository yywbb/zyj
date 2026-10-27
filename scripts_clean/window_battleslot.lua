--
-- Created by IntelliJ IDEA.
-- User: lichungeng
-- Date: 16/7/7
-- Time: 下午5:45
-- To change this template use File | Settings | File Templates.
--


local battleSlot = {
    rootNode = nil,
    rootItems = nil,
}

function battleSlot.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("backGround/soulzhen_battle.ccbi", nil, true, "soulzhen_battle")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode, true
end

function battleSlot.reload(self,t,callback)

    self.callback = callback

    self.rootItems.atk:setString(t.slotnameatk == "" and gameConfig.strings:string_common("moreCommon","wu") or t.slotnameatk)
    self.rootItems.def:setString(t.slotnamedef == "" and gameConfig.strings:string_common("moreCommon","wu") or t.slotnamedef)


    local animationManager = getAnimationManager(self.rootItems)
    animationManager:setAnimationCompletedCallback(function()
        gameWindows:closeWindowDirect("battleSlot")
    end)
    animationManager:runAnimationsForSequenceNamed("start")
end

function battleSlot.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
        self.callback = nil
    end
end

return battleSlot