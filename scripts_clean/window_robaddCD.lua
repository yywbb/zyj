--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/10
-- Time: 下午3:50
-- To change this template use File | Settings | File Templates.
--

local robaddCD = {
    rootNode = nil,
    rootItems = nil,
}

function robaddCD.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("rub/qiangduo_mianzhan", nil, true, "qiangduo_mianzhan")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function robaddCD.reload(self,data,callback)
    self.callback = callback

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("robaddCD")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.doLab1,"使 用",19)
    ui.setLabelString(self.rootItems.doLab1,gameConfig.strings:string_common("popups","shiyong"),19)
    self.rootItems.doButton1:addHandleOfControlEvent(function()
        UIRequest({type = 1113})
        gameWindows:closeWindow("robaddCD")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton1:setSwallowsTouch(true)
    self.rootItems.doButton1:setTouchPriority(self.touchPriority)

    ui.setNewIcon(self.rootItems,{cid = 20128})
    ui.setLabelString(self.rootItems.time,nil,21)
end

function robaddCD.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return robaddCD