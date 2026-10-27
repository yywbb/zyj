
local gamblingRule = {
    rootNode = nil,
    rootItems = nil,
}

function gamblingRule.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("activitylaohuji/laohuji_rule", nil, true, "laohuji_rule")
    self.touchPriority = touchPriority

    if self.rootItems.labelNode then
        ui.createRichLabel({
            {fontID = 905,content = gamedata.config.system_intro["32"].intro},
        },self.rootItems.labelNode,true,{min_line_dis = 2})
    end

    self:reload(data,callback)
    return self.rootNode
end

function gamblingRule.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("gamblingRule")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end

function gamblingRule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return gamblingRule

