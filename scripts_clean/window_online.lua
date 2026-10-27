--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午5:53
-- To change this template use File | Settings | File Templates.
--

local online = {
    rootNode = nil,
    rootItems = nil,
}

function online.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("reward/cell_online", nil, true, "cell_online")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function online.reload(self,data,callback)
    self.callback = callback

    self.data = data
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("online")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)


    local config = gamedata.config.online_reward[tostring(data.id)]

    local reward = ui.getIDandNUMs(config.reward)

    for i=1, 3 do
        if reward[i] and reward[i].cid > 0 then
            if self.rootItems["reward"..i] then
                self.rootItems["reward"..i]:setVisible(true)
            end
            ui.setNewIcon(self.rootItems,reward[i],i-1)
            self.rootItems["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
                ui.setPopwindowByCid(reward[i].cid)
            end, CCControlEventTouchUpInside)
            self.rootItems["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(self.touchPriority)
        else
            if self.rootItems["reward"..i] then
                self.rootItems["reward"..i]:setVisible(false)
            end
        end
    end

    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:setTouchPriority(self.touchPriority)

    if not data.active then
        self.rootItems.timeNode:setVisible(true)
        self.rootItems.doNode:setVisible(false)
        self.rootItems.doButton:addHandleOfControlEvent(function()
        end, CCControlEventTouchUpInside)
        if gameTimer.times["online_reward"] > 0 then
            self.rootItems.time:setString(ui.makeTimeText(gameTimer.times["online_reward"]))
        end
    else
        self.rootItems.timeNode:setVisible(false)
        self.rootItems.doNode:setVisible(true)
        -- ui.setLabelString(self.rootItems.dotext,"领 取",18)
        ui.setLabelString(self.rootItems.dotext,gameConfig.strings:string_common("moreCommon",6),18)
        self.rootItems.doButton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            gameWindows:closeWindowDirect("online")
            UIRequest({type = 2038})
        end, CCControlEventTouchUpInside)
    end
end

function online.reset(self,data,callback)
    if not self.rootItems then return end
    if data.active then
        self.rootItems.timeNode:setVisible(false)
        self.rootItems.doNode:setVisible(true)
        -- ui.setLabelString(self.rootItems.dotext,"领 取",18)
        ui.setLabelString(self.rootItems.dotext,gameConfig.strings:string_common("moreCommon",6),18)
        self.rootItems.doButton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            gameWindows:closeWindowDirect("online")
            UIRequest({type = 2038})
        end, CCControlEventTouchUpInside)
    end

    if data.time then
        self.rootItems.timeNode:setVisible(true)
        self.rootItems.doNode:setVisible(false)
        self.rootItems.time:setString(data.time)
    end
end

function online.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return online