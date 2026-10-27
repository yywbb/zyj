
local fashionPost = {
    rootNode = nil,
    rootItems = nil,

    cancelTip = "fashion",
}

function fashionPost.open(self,touchPriority,data,callback)
    if gamedata.config.activity_time["43"] and gamedata.config.activity_time["43"].param and gamedata.config.activity_time["43"].param == 80006 then
        self.rootNode, self.rootItems = CCBReaderLoad("shizhuang/shizhuang_post3", nil, true, "post")
    else
        self.rootNode, self.rootItems = CCBReaderLoad("shizhuang/shizhuang_post", nil, true, "post")
    end
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function fashionPost.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        --self.callback = nil
        gameWindows:closeWindowDirect("fashionPost")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.gotoButton:addHandleOfControlEvent(function()
        --self.callback = nil
        gameWindows:closeWindowDirect("fashionPost")
        GameScene:shiftLayerById(194)
    end, CCControlEventTouchUpInside)
    self.rootItems.gotoButton:setSwallowsTouch(true)
    self.rootItems.gotoButton:setTouchPriority(self.touchPriority-1)

    ui.setLabelString(self.rootItems.gotoLab,nil,19)
    --
    local activityConfig = gamedata.config.activity_time and gamedata.config.activity_time["43"] or {}
    local shopconfig = gamedata.config.fashion_gift_bag and gamedata.config.fashion_gift_bag[tostring(activityConfig.param)] or {}
    if self.rootItems.zhe then
        if shopconfig and shopconfig.rebate and shopconfig.rebate > 0 and shopconfig.rebate < 10 then
            self.rootItems.zhe:setString(gameConfig.strings.bigNum[shopconfig.rebate].."折")
        else
            self.rootItems.zhe:setString("")
        end
    end
end

function fashionPost.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return fashionPost

