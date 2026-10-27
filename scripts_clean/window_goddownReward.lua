--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/7/6
-- Time: 10:21
-- To change this template use File | Settings | File Templates.
--


local goddownReward = {
    rootNode = nil,
    rootItems = nil,
}

function goddownReward.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("activitypig/pig_ewaijiangli", nil, true, "pig_ewaijiangli")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    self:initFixedString()
    return self.rootNode
end

function goddownReward.reload(self,data,callback)
    self.callback = callback
    --
    ui.setLabelString(self.rootItems.okLab,nil,18)
    --
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("goddownReward")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    --
    self.rootItems.okButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("goddownReward")
    end, CCControlEventTouchUpInside)
    self.rootItems.okButton:setSwallowsTouch(true)
    self.rootItems.okButton:setTouchPriority(self.touchPriority)
    --
    local config = gamedata.config.goddown_event and gamedata.config.goddown_event[tostring(data.id)] or {}

    self.rootItems.desc:setString(config.desc or "")

    local reward = ui.getIDandNUMs(config.reward)
    ui.setNewIconName(self.rootItems,reward[1])

end

function goddownReward.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

function goddownReward.initFixedString(self)
    self.rootItems.title:setString(gameConfig.strings:string_common("fixedString","goddown",10))

end

return goddownReward