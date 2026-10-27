--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/25
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--

local confirm = {
    rootNode = nil,
    rootItems = nil,
}


function confirm.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("shenqi_new/tc_washconfirm", nil, true, "tc_washconfirm")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function confirm.reload(self,data,callback)

    local skills = data or {}
    local str = ""
    local len = table.getTableLength(skills)
    local i = 0
    for k,v in pairs(skills) do
        local config = gamedata.config.breakskill[tostring(k)]
        str = str..config.name
        i = i + 1
        if i < len then
            str = str.."   "
        end
    end

    self.rootItems.content:setString(str)

    ui.setLabelString(self.rootItems.conceltext,gameConfig.strings:string_common("popups","fanhui"),18)
    self.rootItems.concel:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("artifactWashConfirm")
    end, CCControlEventTouchUpInside)
    self.rootItems.concel:setSwallowsTouch(true)
    self.rootItems.concel:setTouchPriority(self.touchPriority)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("artifactWashConfirm")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.confirmtext,gameConfig.strings:string_common("popups","queding"),18)
    self.rootItems.confirm:addHandleOfControlEvent(function()
        self.callback = callback
        gameWindows:closeWindowDirect("artifactWashConfirm")
    end, CCControlEventTouchUpInside)
    self.rootItems.confirm:setSwallowsTouch(true)
    self.rootItems.confirm:setTouchPriority(self.touchPriority)
end

function confirm.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
        self.callback = nil
    end
end

return confirm

