local war_about = {
    rootNode = nil,
    rootItems = nil,
}

function war_about.open(self,touchPriority,data,callback)
    self.touchPriority = touchPriority
    self.root = CCNode:create()

    if data and data.isnew then
        self.rootNode, self.rootItems = CCBReaderLoad("gonghuizhan/gonghuizhan_rule_new", nil, true, "rule")
        self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
        self.rootItems.scrollnode:setTouchPriority(self.touchPriority)
        self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,760-1780),0)
    else
        self.rootNode, self.rootItems = CCBReaderLoad("gonghuizhan/gonghuizhan_rule", nil, true, "rule")
    end
    print("gonghuizh ====war_about========")
    self:reload()

    self.root:addChild(self.rootNode)
    return self.root
end

function war_about.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end
-- {num = self.data.guildnum,name = self.data.guildnum.name,guildid =self.data.guildid }
function war_about.reload(self)
   
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("guildwarabout")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.rootItems.closeButton:setSwallowsTouch(true)
    
end

return war_about