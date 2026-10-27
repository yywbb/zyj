--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/25
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--

local buytrain = {
    rootNode = nil,
    rootItems = nil,
}

function buytrain.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("devil2/buytrain", nil, true, "buytrain")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function buytrain.reload(self,data,callback)
    self.callback = callback

    ui.setLabelString(self.rootItems.buyLab,nil,19)
    ui.setLabelString(self.rootItems.noLab,nil,19)
    --
    local xgold = 0
    if gamedata.config.buycount_price and gamedata.config.buycount_price[tostring(GameScene.vipstatus.b_train+1)] then
        xgold = gamedata.config.buycount_price[tostring(GameScene.vipstatus.b_train+1)].protagonist_train or 0
    end
    -- self.rootItems.desc:setString("是否花费 "..(xgold > 0 and xgold or "").." 元宝，恢复 "..gamedata.config.vip[tostring(GameScene.vip.vip)].n_train.." 培养点")
    -- self.rootItems.desc1:setString("(今日已购买"..GameScene.vipstatus.b_train.."次，还可购买"..(gamedata.config.vip[tostring(GameScene.vip.vip)].b_train-GameScene.vipstatus.b_train).."次)")
    self.rootItems.desc:setString(gameConfig.strings:costGold((xgold>0 and xgold or ""),gamedata.config.vip[tostring(GameScene.vip.vip)].n_train))
    self.rootItems.desc1:setString(gameConfig.strings:vipBuytr(GameScene.vipstatus.b_train,(gamedata.config.vip[tostring(GameScene.vip.vip)].b_train-GameScene.vipstatus.b_train)))
    self.rootItems.buyButton:addHandleOfControlEvent(function()
        UIRequest({type = 1053,xgold = xgold})
        self.callback = nil
        gameWindows:closeWindow("buytrain")
    end, CCControlEventTouchUpInside)
    self.rootItems.buyButton:setSwallowsTouch(true)
    self.rootItems.buyButton:setTouchPriority(self.touchPriority)

    self.rootItems.noButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("buytrain")
    end, CCControlEventTouchUpInside)
    self.rootItems.noButton:setSwallowsTouch(true)
    self.rootItems.noButton:setTouchPriority(self.touchPriority)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("buytrain")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end

function buytrain.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return buytrain

