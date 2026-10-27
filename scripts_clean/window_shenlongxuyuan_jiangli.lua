--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/12/13
-- Time: 14:25
-- To change this template use File | Settings | File Templates.
--


local shenlongxuyuan_jiangli = {
    rootNode = nil,
    rootItems = nil,

}

function shenlongxuyuan_jiangli.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("shenlongxuyuan/shenlongxuyuan_jiangli", nil, true, "shenlongxuyuan_jiangli")
    self.touchPriority = touchPriority
    self.callback = callback
    self:reload(data)
    return self.rootNode
end

function shenlongxuyuan_jiangli.reload(self,data)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("shenlongxuyuan_jiangli")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    --

    local levelnow = GameScene.roleinfo.level or 0
    local level = 999
    for k,v in pairs(gamedata.config.shenlong_reward) do
        if (levelnow <= v.level) and (level > v.level) then
            level = v.level
        end
    end
    local levelreward = gamedata.config.shenlong_reward[tostring(level)] or {}


    for k = 1,3 do

        local rewardconfig = levelreward["reward"..k] or {}
        local reward = ui.getTableFromStr(rewardconfig)

        self.rootItems["propnode"..k]:removeAllChildrenWithCleanup(true)
        local Node,Items = CCBReaderLoad("shenlongxuyuan/cell_jingliyulan", nil, true, "cell_jingliyulan")
        Node:setPosition(0,0)
        self.rootItems["propnode"..k]:addChild(Node)

        for i = 1,5 do
            if reward[i] then
                Items["prop"..i]:setVisible(true)
                ui.setNewIcon(Items,reward[i],i-1)
                --
                Items["i_button"..(i>1 and ("_"..(i-1)) or "")]:addHandleOfControlEvent(function()
                    ui.setPopwindowByCid(reward[i].cid)
                end, CCControlEventTouchUpInside)
                Items["i_button"..(i>1 and ("_"..(i-1)) or "")]:setSwallowsTouch(true)
                Items["i_button"..(i>1 and ("_"..(i-1)) or "")]:setTouchPriority(self.touchPriority-1)
                --
            else
                Items["prop"..i]:setVisible(false)
            end
        end

    end

end

function shenlongxuyuan_jiangli.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return shenlongxuyuan_jiangli

