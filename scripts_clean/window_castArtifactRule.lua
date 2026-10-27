--
-- Created by Lipurpose.
-- User: f
-- Date: 19/4/2018
-- Time: 18:26
-- To change this template use File | Settings | File Templates.
--

local castArtifactRule = {
    rootNode = nil,
    rootItems = nil,
}

function castArtifactRule.open(self,touchPriority,data,callback)
    
    self.rootNode, self.rootItems = CCBReaderLoad("duanzaoshenqi/duanzaoshenqi_rule", nil, true, "duanzaoshenqi_rule")
    ui.createRichLabel({
        {fontID = 905,content = gamedata.config.system_intro["31"].intro},
    },self.rootItems.labelNode,true,{min_line_dis = 1})
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function castArtifactRule.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("castArtifactRule")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end

function castArtifactRule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return castArtifactRule