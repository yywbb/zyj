--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/25
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--

local chatemoji = {
    rootNode = nil,
    rootItems = nil,
}

function chatemoji.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("chat/chat_emoji", nil, true, "chat_emoji")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function chatemoji.reload(self,data,callback)
    self.callback = callback

    -- ui.setLabelString(self.rootItems.closeLab,nil,18)
    -- ui.setLabelString(self.rootItems.slotLab,nil,18)
    -- ui.setLabelString(self.rootItems.friendLab,nil,18)

    for i=1,23 do
        self.rootItems["emoji"..i]:setTouchPriority(self.touchPriority)
        self.rootItems["emoji"..i]:setSwallowsTouch(true)
        self.rootItems["emoji"..i]:addHandleOfControlEvent(function()
            if self.callback ~= nil then
                self.callback(i)
                self.callback = nil
            end
            gameWindows:closeWindow("chatemoji")
        end, CCControlEventTouchUpInside)
    end
    -- self.rootItems.closeButton:addHandleOfControlEvent(function()
    --     self.callback = nil
    --     gameWindows:closeWindow("chatemoji")
    -- end, CCControlEventTouchUpInside)
    -- self.rootItems.closeButton:setSwallowsTouch(true)
    -- self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    -- self.rootItems.slotButton:addHandleOfControlEvent(function()
    --     self.callback = nil
    --     gameWindows:closeAllWindowDirect()
    --     if data.rid > 0 then
    --         GameScene:addtempLayers("other_slotinfo",data)
    --     end
    -- end, CCControlEventTouchUpInside)
    -- self.rootItems.slotButton:setSwallowsTouch(true)
    -- self.rootItems.slotButton:setTouchPriority(self.touchPriority)

    -- self.rootItems.friendButton:addHandleOfControlEvent(function()
    --     if data.rid > 0 then
    --         UIRequest({type = 2302, ids = {data.rid}})
    --     end
    -- end, CCControlEventTouchUpInside)
    -- self.rootItems.friendButton:setSwallowsTouch(true)
    -- self.rootItems.friendButton:setTouchPriority(self.touchPriority)

end

function chatemoji.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return chatemoji