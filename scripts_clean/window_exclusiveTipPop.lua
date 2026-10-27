--
-- Author: songyibo
-- Date: 2021-03-24 16:29:10
--
local tipPop = {
    rootNode = nil,
    rootItems = nil,
}

function tipPop.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("zhuanshushenqi/tip_pop", nil, true, "tip_pop")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function tipPop.reload(self,data,callback)
    self.callback = callback
    if data.method == "left" then
    	self.rootItems.labNode:setAnchorPoint(ccp(1,0))
    else
    	self.rootItems.labNode:setAnchorPoint(ccp(0,0))
    end
    self.rootItems.desc:setString(data.string)
    self.rootItems.labSp = tolua.cast(self.rootItems.labSp, "CCScale9Sprite")
    self.rootItems.labSp:setPreferredSize(CCSizeMake((self.rootItems.desc:getContentSize().width + 40)*2,140))
end

function tipPop.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return tipPop