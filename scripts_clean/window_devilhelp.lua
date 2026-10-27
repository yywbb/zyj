--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/25
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--

local devilhelp = {
    rootNode = nil,
    rootItems = nil,
}

function devilhelp.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("devil2/mochong_help", nil, true, "mochong_help")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function devilhelp.reload(self,data,callback)
    self.callback = callback

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("devilhelp")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

end

function devilhelp.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return devilhelp

