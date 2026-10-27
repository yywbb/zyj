--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/2/4
-- Time: 14:31
-- To change this template use File | Settings | File Templates.
--

local gonglve = {

    resource = nil,

    rootNode = nil,
    rootItems = nil,


}

function gonglve.init(self,parent,toppos)
    self.rootNode,self.rootItems = CCBReaderLoad("gonglve/gonglve", nil, true, "gonglve")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)


    self.rootItems.topnode:setPositionY(toppos)
    --self.rootItems.container:setContentSize(CCSize(1080,6810))
    self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    self.rootItems.scrollnode:setViewSize(CCSize(1080,toppos-gameConfig.maiscenebottomheight-100))
    self.rootItems.scrollnode:setTouchPriority(-101)
    self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,toppos-gameConfig.maiscenebottomheight-100-self.rootItems.container:getContentSize().height),0)

    if self.rootItems.closeButton then
        self.rootItems.closeButton:setTouchPriority(-103)
        self.rootItems.closeButton:addHandleOfControlEvent(function()
            GameScene:shiftLayer("main","down")
        end, CCControlEventTouchUpInside)
    end

end

function gonglve.clear(self)
    self.rootItems = nil

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

return gonglve