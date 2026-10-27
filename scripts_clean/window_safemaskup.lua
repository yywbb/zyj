--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/6/30
-- Time: 18:24
-- To change this template use File | Settings | File Templates.
--

local safemaskup = {
    rootNode = nil,
    rootItems = nil,
}

function safemaskup.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("safemask/safemaskup", nil, true, "safemaskup")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    self:initFixedString()
    return self.rootNode
end

function safemaskup.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("safemaskup")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    --
    if not data then return end
    --
    local config = gamedata.config.mozhao_break or {}
    --
    ui.setLabelString(self.rootItems.num1,config[tostring(data.level)].value,13)
    ui.setLabelString(self.rootItems.num2,config[tostring(data.level)].percent.."%",13)
    ui.setLabelString(self.rootItems.next_num1,config[tostring(data.level+1)].value,13)
    ui.setLabelString(self.rootItems.next_num2,config[tostring(data.level+1)].percent.."%",13)
    if config[tostring(data.level+1)].value - config[tostring(data.level)].value > 0 then
        self.rootItems.upnode1:setVisible(true)
        ui.setLabelString(self.rootItems.upnum1,config[tostring(data.level+1)].value - config[tostring(data.level)].value,22)
    else
        self.rootItems.upnode1:setVisible(false)
    end
    if config[tostring(data.level+1)].percent - config[tostring(data.level)].percent > 0 then
        self.rootItems.upnode2:setVisible(true)
        ui.setLabelString(self.rootItems.upnum2,(config[tostring(data.level+1)].percent - config[tostring(data.level)].percent).."%",22)
    else
        self.rootItems.upnode2:setVisible(false)
    end
    --
    setSpriteFrameByName(self.rootItems["in_soulsprite"], "alpha")
    setSpriteFrameByName(self.rootItems["in_k_quality"], "b_iconk"..(config[tostring(data.level)].quality and config[tostring(data.level)].quality>1 and config[tostring(data.level)].quality or 1))
    setSpriteFrameByName(self.rootItems["in_quality"], "b_iconbg"..(config[tostring(data.level)].quality and config[tostring(data.level)].quality>1 and config[tostring(data.level)].quality or 1))
    ui.setLabelString(self.rootItems["in_name"],config[tostring(data.level)].name,((config[tostring(data.level)].quality and config[tostring(data.level)].quality ~= 0) and config[tostring(data.level)].quality or 1)*2-1)
    setSpriteFrameByName(self.rootItems["in_icon"], "mozhao"..(config[tostring(data.level)].quality-1))
    --
    setSpriteFrameByName(self.rootItems["in_soulsprite_1"], "alpha")
    setSpriteFrameByName(self.rootItems["in_k_quality_1"], "b_iconk"..(config[tostring(data.level+1)].quality and config[tostring(data.level+1)].quality>1 and config[tostring(data.level+1)].quality or 1))
    setSpriteFrameByName(self.rootItems["in_quality_1"], "b_iconbg"..(config[tostring(data.level+1)].quality and config[tostring(data.level+1)].quality>1 and config[tostring(data.level+1)].quality or 1))
    ui.setLabelString(self.rootItems["in_name_1"],config[tostring(data.level+1)].name,((config[tostring(data.level+1)].quality and config[tostring(data.level+1)].quality ~= 0) and config[tostring(data.level+1)].quality or 1)*2-1)
    setSpriteFrameByName(self.rootItems["in_icon_1"], "mozhao"..(config[tostring(data.level+1)].quality-1))
    --

end

function safemaskup.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

function safemaskup.initFixedString(self)
    ui.setLabelString(self.rootItems.lab1,gameConfig.strings:string_common("fixedString","safemask",1),111)
    ui.setLabelString(self.rootItems.lab2,gameConfig.strings:string_common("fixedString","safemask",2),111)
    self.rootItems.lab3:setString(gameConfig.strings:string_common("fixedString","general",23))
end

return safemaskup

