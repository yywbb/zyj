--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/12/21
-- Time: 17:54
-- To change this template use File | Settings | File Templates.
--



local shenlongxuyuan_rule = {
    rootNode = nil,
    rootItems = nil,
}

function shenlongxuyuan_rule.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("shenlongxuyuan/shenlongxuyuan_startRule", nil, true, "shenlongxuyuan_startRule")
    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function shenlongxuyuan_rule.reload(self,data,callback)
    self.callback = callback

    if self.rootItems.closeLab then
        ui.setLabelString(self.rootItems.closeLab,nil,19)
    end

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("shenlongxuyuan_rule")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end

function shenlongxuyuan_rule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end


return shenlongxuyuan_rule