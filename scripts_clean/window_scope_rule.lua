--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/4/8
-- Time: 16:32
-- To change this template use File | Settings | File Templates.
--

local scope_rule = {
    rootNode = nil,
    rootItems = nil,
}

function scope_rule.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("general_new/tc_shuxingrule", nil, true, "tc_shuxingrule")
    self.touchPriority = touchPriority

    -- if self.rootItems.labelNode then
    --     ui.createRichLabel({
    --         {fontID = 905,content = gamedata.config.system_intro["54"].intro},
    --     },self.rootItems.labelNode,true,{min_line_dis = 1})
    -- end

    self:reload(data,callback)
    return self.rootNode
end

function scope_rule.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("scope_rule")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

end

function scope_rule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return scope_rule