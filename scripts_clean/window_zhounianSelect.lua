--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/25
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--

local zhounianselect = {
    rootNode = nil,
    rootItems = nil,

    selectid = nil,
}

function zhounianselect.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("2zhounian/2zhounian_select", nil, true, "cdk")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function zhounianselect.reload(self,data,callback)
    self.callback = callback

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("zhounianSelect")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    local rewards = gamedata.config.Anniversary_reward

    for i=1,8 do 
        local onedata = rewards[tostring(i)]
        local reward = ui.getIDandNUMs(onedata.reward)[1]
        ui.setNewIconName(self.rootItems,{cid = reward.cid,num = reward.num},i-1)

        local buttonkey = "in_button"..(i==1 and "" or "_"..(i-1))

        self.rootItems[buttonkey]:addHandleOfControlEvent(function()
            self.selectid = reward.cid
            self:showSelect(i)
        end, CCControlEventTouchUpInside)
        self.rootItems[buttonkey]:setSwallowsTouch(true)
        self.rootItems[buttonkey]:setTouchPriority(self.touchPriority)
    end


    ui.setLabelString(self.rootItems.confirmtext,gameConfig.strings:string_common("activity_zhounian",12),18)
    self.rootItems.confirmButton:addHandleOfControlEvent(function()
        if not self.selectid then
            runGamePrompt({msg = gameConfig.strings:string_common("activity_zhounian",13)})
        else
            gameWindows:closeWindow("zhounianSelect")
            UIRequest({type = 5311,cid = self.selectid})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.confirmButton:setSwallowsTouch(true)
    self.rootItems.confirmButton:setTouchPriority(self.touchPriority-1)

    self:showSelect()
end

function zhounianselect.showSelect( self,idx )
    if self.selectid and idx then
        self.rootItems.select:setVisible(true)
        local i = math.mod(idx,4)
        if i==0 then i=4 end
        local j = math.ceil(idx/4)-1
        self.rootItems.select:setPosition(260+210*(i-1),380-220*j)
    else
        self.rootItems.select:setVisible(false)
    end

end

function zhounianselect.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.selectid = nil

    if self.callback then
        self.callback()
    end
end

return zhounianselect

