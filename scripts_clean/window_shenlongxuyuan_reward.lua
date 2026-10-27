--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/12/13
-- Time: 14:25
-- To change this template use File | Settings | File Templates.
--


local shenlongxuyuan_reward = {
    rootNode = nil,
    rootItems = nil,
    select = 1,
    callback = nil,
}

function shenlongxuyuan_reward.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("shenlongxuyuan/shenlongxuyuan_jiangliyulan", nil, true, "shenlongxuyuan_jiangliyulan")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function shenlongxuyuan_reward.reload(self,data,callback)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("shenlongxuyuan_reward")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    --
    ui.setLabelString(self.rootItems.conceltext,nil,19)
    self.rootItems.concel:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("shenlongxuyuan_reward")
    end, CCControlEventTouchUpInside)
    self.rootItems.concel:setSwallowsTouch(true)
    self.rootItems.concel:setTouchPriority(self.touchPriority)
    --
    ui.setLabelString(self.rootItems.confirmtext,nil,19)
    self.rootItems.confirm:addHandleOfControlEvent(function()
        self.callback = callback
        gameWindows:closeWindowDirect("shenlongxuyuan_reward")
    end, CCControlEventTouchUpInside)
    self.rootItems.confirm:setSwallowsTouch(true)
    self.rootItems.confirm:setTouchPriority(self.touchPriority)
    --

    self.select = data.select or 1

    local levelnow = GameScene.roleinfo.level or 0
    local level = 999
    for k,v in pairs(gamedata.config.shenlong_reward) do
        if (levelnow <= v.level) and (level > v.level) then
            level = v.level
        end
    end
    local levelreward = gamedata.config.shenlong_reward[tostring(level)] or {}

    local rewardconfig = levelreward["reward"..self.select] or {}
    local reward = ui.getTableFromStr(rewardconfig)

    for i = 1,5 do
        if reward[i] then
            self.rootItems["prop"..i]:setVisible(true)
            ui.setNewIcon(self.rootItems,reward[i],i-1)
            --
            self.rootItems["i_button"..(i>1 and ("_"..(i-1)) or "")]:addHandleOfControlEvent(function()
                ui.setPopwindowByCid(reward[i].cid)
            end, CCControlEventTouchUpInside)
            self.rootItems["i_button"..(i>1 and ("_"..(i-1)) or "")]:setSwallowsTouch(true)
            self.rootItems["i_button"..(i>1 and ("_"..(i-1)) or "")]:setTouchPriority(self.touchPriority-1)
            --
        else
            self.rootItems["prop"..i]:setVisible(false)
        end
    end

end

function shenlongxuyuan_reward.close(self)
    self.select = 1
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return shenlongxuyuan_reward

