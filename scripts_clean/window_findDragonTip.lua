--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/18
-- Time: 下午2:45
-- To change this template use File | Settings | File Templates.
--

local findDragonTip = {
    rootNode = nil,
    rootItems = nil,
    root = nil,
    data = {},
    autoOpen = false,
}

function findDragonTip.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority
    self.callback = callback
    self.rootNode, self.rootItems = CCBReaderLoad("xunlongjue/xunlongjue_tips", nil, true, "xunlongjue_tips")
    self.root:addChild(self.rootNode)
    self:reload()
    return self.root
end

function findDragonTip.reload(self,data)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        if self.autoOpen then
            CCUserDefault:sharedUserDefault():setBoolForKey("findDragon"..GameScene.roleinfo.id..os.date("%Y-%m-%d"), self.autoOpen)
        end
        gameWindows:closeWindow("findDragonTip")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.autobutton:addHandleOfControlEvent(function()
        self.autoOpen = not self.autoOpen
        self.rootItems.autosprite:setVisible(self.autoOpen)
    end, CCControlEventTouchUpInside)
    self.rootItems.autobutton:setSwallowsTouch(true)
    self.rootItems.autobutton:setTouchPriority(self.touchPriority - 1)

    self.rootItems.gonow:addHandleOfControlEvent(function()
        if self.autoOpen then
            CCUserDefault:sharedUserDefault():setBoolForKey("findDragon"..GameScene.roleinfo.id..os.date("%Y-%m-%d"), self.autoOpen)
        end
        GameScene:shiftLayer("findDragon","up")
        gameWindows:closeWindow("findDragonTip")
    end, CCControlEventTouchUpInside)
    self.rootItems.gonow:setSwallowsTouch(true)
    self.rootItems.gonow:setTouchPriority(self.touchPriority - 1)

    local rewards = ui.getIDandNUMs(gamedata.config:getConfigByName("xunlong_config").xunlong_push_prop.value)
    for k, v in pairs(rewards) do
        ui.setNewIcon(self.rootItems, v, tonumber(k) - 1)
    end
    self.rootItems.autosprite:setVisible(self.autoOpen)
end

function findDragonTip.close(self)
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil
    if self.autoOpen then
        CCUserDefault:sharedUserDefault():setBoolForKey("findDragon"..GameScene.roleinfo.id..os.date("%Y-%m-%d"), self.autoOpen)
    end
    if self.callback then
        self.callback()
    end
end

return findDragonTip