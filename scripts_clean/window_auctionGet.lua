--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/1/13
-- Time: 17:01
-- To change this template use File | Settings | File Templates.
--

local auctionGet = {
    rootNode = nil,
    rootItems = nil,
}

function auctionGet.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("paimaihang/yikoujia", nil, true, "yikoujia")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function auctionGet.reload(self,data,callback)


    local _config = gamedata.config.auction_items
    local config = _config and _config[tostring(data.id)] or {}
    local reward = ui.getIDRandNum(config.reward)

    ui.setNewIconName(self.rootItems,{cid = reward[1], num = reward[2]})

    ui.setLabelString(self.rootItems.auction,data.auction,21)
    ui.setLabelString(self.rootItems.price,config.maximum,21)

    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("auctionGet")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    --
    ui.setLabelString(self.rootItems.doLab1,nil,19)
    self.rootItems.doButton1:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("auctionGet")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton1:setSwallowsTouch(true)
    self.rootItems.doButton1:setTouchPriority(self.touchPriority)

    --
    ui.setLabelString(self.rootItems.doLab2,nil,19)
    self.rootItems.doButton2:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        gameWindows:closeWindowDirect("auctionGet")
        UIRequest({type = 4812,id = data.id,num = config.maximum})
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton2:setSwallowsTouch(true)
    self.rootItems.doButton2:setTouchPriority(self.touchPriority)
    --

end

function auctionGet.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return auctionGet

