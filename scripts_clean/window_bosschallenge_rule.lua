--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 18/3/8
-- Time: 15:00
-- To change this template use File | Settings | File Templates.
--

local bosschallenge_rule = {
    rootNode = nil,
    rootItems = nil,
}

function bosschallenge_rule.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("bosschallenge/bosschallenge_rule", nil, true, "bosschallenge_rule")
    self.touchPriority = touchPriority
    self.callback = callback
    self:reload(data)
    return self.rootNode
end

function bosschallenge_rule.reload(self,data)

    local bossid = data and data.bossid or 0

    local desc = gamedata.config.heroboss[tostring(bossid)] and gamedata.config.heroboss[tostring(bossid)].regular or ""

    self.rootItems.desc:setString(desc)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("bosschallenge_rule")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end

function bosschallenge_rule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return bosschallenge_rule