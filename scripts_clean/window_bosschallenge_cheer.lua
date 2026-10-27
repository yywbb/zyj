--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 18/3/8
-- Time: 15:00
-- To change this template use File | Settings | File Templates.
--

local bosschallenge_cheer = {
    rootNode = nil,
    rootItems = nil,
}

function bosschallenge_cheer.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("bosschallenge/bosschallenge_zhuwei", nil, true, "bosschallenge_zhuwei")
    self.touchPriority = touchPriority
    self.callback = callback
    self:reload(data)
    return self.rootNode
end

function bosschallenge_cheer.reload(self,data)

    local upone = gamedata.config.global_kv["cheer"] and tonumber(gamedata.config.global_kv["cheer"].value) or 0
    local uplimit = gamedata.config.global_kv["cheer_limit"] and tonumber(gamedata.config.global_kv["cheer_limit"].value) or 0

    local upnow = data and data.cheernum or 0

    self.rootItems.desc1:setString((upone*100).."%")
    self.rootItems.desc2:setString((upone*100*uplimit).."%")
    ui.setLabelString(self.rootItems.desc3,(upone*100*upnow).."%",3)

    ui.setLabelString(self.rootItems.cheertext,nil,19)

    if upnow >= uplimit then
        self.rootItems.spendNode:setVisible(false)
        ui.addGray("CCControlButton", self.rootItems.cheerbutton)
        self.rootItems.cheerbutton:addHandleOfControlEvent(function()
            runGamePrompt({msg = "助威已达上限"})
        end, CCControlEventTouchUpInside)
        self.rootItems.cheerbutton:setSwallowsTouch(true)
        self.rootItems.cheerbutton:setTouchPriority(self.touchPriority)
    else
        self.rootItems.spendNode:setVisible(true)
        local spendGlod = gamedata.config.buycount_price[tostring(upnow+1)] and gamedata.config.buycount_price[tostring(upnow+1)]["cheer_consume"] or gamedata.config.buycount_price[tostring(table.getTableLength(gamedata.config.buycount_price))]["cheer_consume"]
        if GameScene.herobossdouble and GameScene.herobossdouble == 1 then
            spendGlod = spendGlod*2
        end
        ui.setLabelString(self.rootItems.spendText,spendGlod,14)
        ui.removeGray("CCControlButton", self.rootItems.cheerbutton)
        self.rootItems.cheerbutton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            UIRequest({type = 5205, spendGlod = spendGlod or 0 })
        end, CCControlEventTouchUpInside)
        self.rootItems.cheerbutton:setSwallowsTouch(true)
        self.rootItems.cheerbutton:setTouchPriority(self.touchPriority)

    end

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("bosschallenge_cheer")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end

function bosschallenge_cheer.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return bosschallenge_cheer