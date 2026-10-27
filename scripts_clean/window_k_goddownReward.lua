--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/7/6
-- Time: 10:21
-- To change this template use File | Settings | File Templates.
--


local k_goddownReward = {
    rootNode = nil,
    rootItems = nil,
}

function k_goddownReward.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("activitypig/pig_ewaijiangli", nil, true, "pig_ewaijiangli")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    self:initFixedString()
    return self.rootNode
end

function k_goddownReward.reload(self,data,callback)
    self.callback = callback
    --
    ui.setLabelString(self.rootItems.okLab,nil,18)
    --
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("k_goddownReward")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    --
    self.rootItems.okButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("k_goddownReward")
    end, CCControlEventTouchUpInside)
    self.rootItems.okButton:setSwallowsTouch(true)
    self.rootItems.okButton:setTouchPriority(self.touchPriority)
    --
    local config = gamedata.config.span_goddown_event and gamedata.config.span_goddown_event[tostring(data.id)] or {}

    self.rootItems.desc:setString(config.desc or "")

    local reward = ui.getIDandNUMs(config.reward)
    ui.setNewIconName(self.rootItems,reward[1])

end

function k_goddownReward.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

function k_goddownReward.initFixedString(self)
    self.rootItems.title:setString(gameConfig.strings:string_common("fixedString","goddown",10))

end

return k_goddownReward