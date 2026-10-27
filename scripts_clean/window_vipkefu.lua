--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 18/2/28
-- Time: 15:17
-- To change this template use File | Settings | File Templates.
--

local vipkefu = {
    rootNode = nil,
    rootItems = nil,

    weixin = "",
}

function vipkefu.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("vipkefu/vipkefu", nil, true, "vipkefu")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function vipkefu.reload(self,data,callback)
    self.callback = callback

    local viptype = data and data.viptype or 1
    local weixin = gamedata.config.vip_kefu and gamedata.config.vip_kefu[tostring(viptype)].weixin or ""
    self.rootItems.weixin:setString(weixin)

    self.weixin = weixin

    self.rootItems.copybutton:addHandleOfControlEvent(function()
        if ui.setStringToPasteBoard(self.weixin) then
            runGamePrompt({msg = "复制成功"})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.copybutton:setSwallowsTouch(true)
    self.rootItems.copybutton:setTouchPriority(self.touchPriority)

    if self.rootItems["vipdesc"] and gamedata.config.vip_kefu and gamedata.config.vip_kefu[tostring(viptype)].desc then
        self.rootItems.vipdesc:setString(gamedata.config.vip_kefu[tostring(viptype)].desc)
    end

    if self.rootItems["viptype1"] then
        for i = 1,3 do
            self.rootItems["viptype"..i]:setVisible(false)
        end

        if viptype == 2 then
            self.rootItems["viptype2"]:setVisible(true)
            self.rootItems.viptext:setString("超级VIP客服微信：")
        elseif viptype >= 3 then
            self.rootItems["viptype3"]:setVisible(true)
            self.rootItems.viptext:setString("特级VIP客服微信：")
        else
            self.rootItems["viptype1"]:setVisible(true)
            self.rootItems.viptext:setString("高级VIP客服微信：")
        end
    end

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("vipkefu")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end

function vipkefu.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return vipkefu

