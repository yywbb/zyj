--公会打地鼠的说明

local guard_rule = {
    rootNode = nil,
    rootItems = nil,
}

function guard_rule.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("gonghui2/gonghui_shouwei_rule", nil, true, "gonghui_shouwei_rule")
    self.touchPriority = touchPriority

    ui.createRichLabel({
        {fontID = 905,content = gamedata.config.system_intro["1"].intro},
    },self.rootItems.labelNode,true,{min_line_dis = 10})

    self:reload(data,callback)

    return self.rootNode
end

function guard_rule.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("guard_rule")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end

function guard_rule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end


return guard_rule