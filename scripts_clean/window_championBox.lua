--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/5/20
-- Time: 14:22
-- To change this template use File | Settings | File Templates.
--


local championbox = {
    rootNode = nil,
    rootItems = nil,

    data = {}
}

function championbox.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("chamipon/chamipon_boxinfo", nil, true, "box")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function championbox.reload(self,data,callback)
    self.data = data
    self.callback = callback

    if not self.data.status then return end

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("championbox")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    --
    self.rootItems.title:setString(gameConfig.strings:getLevelBig(self.data.status.pass)..gameConfig.strings:string_common("champion","box"))
    ui.setLabelString(self.rootItems.doLab,nil,19)
    --
    local c_config = gamedata.config.champion_produce or {}
    local championconfig = c_config[tostring(GameScene.roleinfo.level)] or {}
    local boxconfig = championconfig[tostring(self.data.status.pass)] or {}
    local maxnum = 0
    for i = 1,50 do
        if boxconfig["storehouse"..i] and boxconfig["storehouse"..i] ~= "" then
            maxnum = i
        end
    end

    --
    if self.data.status.boxopen >= maxnum then
        --
        local props = ui.getIDandNUMs(boxconfig["storehouse"..maxnum])
        for i = 1,4 do
            if props[i] then
                self.rootItems["prop"..i]:setVisible(true)
                ui.setNewIconName(self.rootItems,props[i],i-1)
            else
                self.rootItems["prop"..i]:setVisible(false)
            end
        end
        --
        self.rootItems.leftNumLabel:setString(gameConfig.strings:string_common("champion","boxall1"))
        self.rootItems.goldnode:setVisible(false)
        self.rootItems.freenode:setVisible(false)
        ui.addGray("CCControlButton",self.rootItems.doButton)
        --
        self.rootItems.doButton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            runGamePrompt({msg = gameConfig.strings:string_common("champion","boxall")})
        end, CCControlEventTouchUpInside)
        self.rootItems.doButton:setSwallowsTouch(true)
        self.rootItems.doButton:setTouchPriority(self.touchPriority)

    else
        --
        local props = ui.getIDandNUMs(boxconfig["storehouse"..(self.data.status.boxopen+1)])
        for i = 1,4 do
            if props[i] then
                self.rootItems["prop"..i]:setVisible(true)
                ui.setNewIconName(self.rootItems,props[i],i-1)
            else
                self.rootItems["prop"..i]:setVisible(false)
            end
        end
        --
        self.rootItems.leftNumLabel:setString(gameConfig.strings:championBoxOpen(maxnum-self.data.status.boxopen))
        ui.removeGray("CCControlButton",self.rootItems.doButton)
        --
        local xgold = 0
        if gamedata.config.buycount_price[tostring(self.data.status.boxopen+1)] and gamedata.config.buycount_price[tostring(self.data.status.boxopen+1)].championbox_cost and gamedata.config.buycount_price[tostring(self.data.status.boxopen+1)].championbox_cost > 0 then
            self.rootItems.goldnode:setVisible(true)
            self.rootItems.freenode:setVisible(false)
            ui.setLabelString(self.rootItems.goldnum,gamedata.config.buycount_price[tostring(self.data.status.boxopen+1)].championbox_cost,21)
            xgold = gamedata.config.buycount_price[tostring(self.data.status.boxopen+1)].championbox_cost+0
        else
            self.rootItems.goldnode:setVisible(false)
            self.rootItems.freenode:setVisible(true)
            xgold = 0
        end
        --
        self.rootItems.doButton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            UIRequest({type = 2704, xgold = xgold or 0})
        end, CCControlEventTouchUpInside)
        self.rootItems.doButton:setSwallowsTouch(true)
        self.rootItems.doButton:setTouchPriority(self.touchPriority)
    end

end

function championbox.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return championbox