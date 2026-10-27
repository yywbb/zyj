--
-- Created by IntelliJ IDEA.
-- User: jkp
-- Date: 22/4/2
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--

local onekeyall = {
    rootNode = nil,
    rootItems = nil,

    allShow = true,
}

function onekeyall.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("start2/tc_onekeyall", nil, true, "tc_onekeyall")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function onekeyall.reload(self,data,callback)
    
    -- ui.setLabelString(self.rootItems.canceltext,"取 消",18)
    ui.setLabelString(self.rootItems.canceltext,gameConfig.strings:string_common("popups","quxiao"),18)
    self.rootItems.cancel:addHandleOfControlEvent(function()
        self.callback = callback(1)
        gameWindows:closeWindow("onekeyall")
    end, CCControlEventTouchUpInside)
    self.rootItems.cancel:setSwallowsTouch(true)
    self.rootItems.cancel:setTouchPriority(self.touchPriority)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("onekeyall")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.confirmtext,"一键领取",18)
    ui.setLabelString(self.rootItems.confirmtext,gameConfig.strings:string_common("task",9),18)
    self.rootItems.confirm:addHandleOfControlEvent(function()
        self.callback = callback(2)
        gameWindows:closeWindowDirect("onekeyall")
    end, CCControlEventTouchUpInside)
    self.rootItems.confirm:setSwallowsTouch(true)
    self.rootItems.confirm:setTouchPriority(self.touchPriority)

    --今日不在提示设置
    local isShow = true
    local onekeyStr = CCUserDefault:sharedUserDefault():getStringForKey("onekeyall_")
    if onekeyStr and onekeyStr ~= "" then
        local now = os.date("*t", gamedata:time())
        local _t = string.split(onekeyStr,"_")
        if tonumber(_t[1]) == 0 and tonumber(_t[2]) == now.year and tonumber(_t[3]) == now.month and tonumber(_t[4]) == now.day then
            isShow = false
        end
    end

    self.rootItems["selectSp"]:setVisible(not isShow)
    self.allShow = not isShow

    self.rootItems["selectUse"]:setSwallowsTouch(true)
    self.rootItems["selectUse"]:setTouchPriority(self.touchPriority)
    self.rootItems["selectUse"]:addHandleOfControlEvent(function()

        self.allShow = not self.allShow
        self.rootItems["selectSp"]:setVisible(self.allShow)

        local now = os.date("*t", gamedata:time())
        local _str = (self.allShow and "0_" or "1_")..now.year.."_"..now.month.."_"..now.day
        CCUserDefault:sharedUserDefault():setStringForKey("onekeyall_", _str)

    end, CCControlEventTouchUpInside)

end

function onekeyall.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
        self.callback = nil
    end
end

return onekeyall

