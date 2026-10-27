--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/25
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--

local championResult = {
    rootNode = nil,
    rootItems = nil,
}

function championResult.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("chamipon/tc_complete", nil, true, "tc_complete")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function championResult.reload(self,data,callback)
  
    self.rootItems.label_des2:setString(string.format(gameConfig.strings:string_common("champion","res1"), data.info.all, data.info.success, data.info.fail))
    
    if data.info.total > 0 then
        self.rootItems.label_des3:setString(string.format(gameConfig.strings:string_common("champion","res2"), data.info.total, data.info.times))
    else
        self.rootItems.label_des3:setString(string.format(gameConfig.strings:string_common("champion","res3"), data.info.total))
    end
    
    self.rootItems.label_des4:setString(tostring(data.info.gold))
    local x, y = self.rootItems.reward:getPosition()
    local width = 120
    for i=0, table.getTableLength(data.reward) - 1 do
        local item, items = CCBReaderLoad("icons/new_iconName2", nil, true, "new_iconName2")
        ui.setNewIconName(items, data.reward[tostring(i + 1)])
        item:setScale(0.6)
        item:setPosition(width * i + x, y)
        self.rootNode:addChild(item)
    end

    self.rootItems.upBtn:addHandleOfControlEvent(function()
        if callback then
            callback()
        end
        gameWindows:closeWindow("championResult")
    end, CCControlEventTouchUpInside)
    self.rootItems.upBtn:setSwallowsTouch(true)
    self.rootItems.upBtn:setTouchPriority(self.touchPriority)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        if callback then
            callback()
        end
        gameWindows:closeWindow("championResult")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end

function championResult.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

return championResult

