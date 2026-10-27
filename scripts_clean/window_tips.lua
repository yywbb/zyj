--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/27
-- Time: 上午11:34
-- To change this template use File | Settings | File Templates.
--


local tips = {
    rootNode = nil,
    rootItems = nil,

    root = nil,

    tipconfig = {
        activityshopTip = "tanchuang/xianshishangdian_xingyunzhi",
    },

}

function tips.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad(self.tipconfig[data.type], nil, true, self.tipconfig[data.type])

    self.touchPriority = touchPriority

    if  self.rootItems.closeButton then
        self.rootItems.closeButton:addHandleOfControlEvent(function()
            gameWindows:closeWindow("tips")
        end, CCControlEventTouchUpInside)
        self.rootItems.closeButton:setSwallowsTouch(true)
        self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    end

    return self.rootNode
end

function tips.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return tips