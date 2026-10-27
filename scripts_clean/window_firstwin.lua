--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/27
-- Time: 上午11:34
-- To change this template use File | Settings | File Templates.
--


local firstwin = {
    rootNode = nil,
    rootItems = nil,

    root = nil,
    callback = nil,

}

function firstwin.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("windows/tc_firsthuode", nil, true, "tc_firsthuode")

    self.touchPriority = touchPriority

    ui.setLabelString(self.rootItems.lab1,nil,122)
    ui.setLabelString(self.rootItems.lab2,nil,19)

    if data and data.reward and data.reward["1"] then
       ui.setNewIconName(self.rootItems,data.reward["1"])
    end
    self.data = data

    self.callback = callback

    if  self.rootItems.closeButton then
        self.rootItems.closeButton:addHandleOfControlEvent(function()
            gameWindows:closeWindow("firstwin")
        end, CCControlEventTouchUpInside)
        self.rootItems.closeButton:setSwallowsTouch(true)
        self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    end

    return self.rootNode
end

function firstwin.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.data.reward["1"].cid == 1001 then
        GameScene:coin_effect(2,540,960,0.5)
    end
    if self.callback then
        self.callback()

    end
end

return firstwin