local share = {
    rootNode = nil,
    rootItems = nil,
}

function share.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("activityreward_new/tc_fenxiang", nil, true, "share")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function share.reload(self,data,callback)
    self.callback = callback    
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("share")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    -- setSpriteFrameByName(self.rootItems["i_soulsprite"..1], "fenxiang_weixin")
    -- setSpriteFrameByName(self.rootItems["i_soulsprite"..2], "fenxiang_xinlang")
    -- i_button
    local tab = {{cid = 1001}, {cid = 1001}}
   
    for k,v in pairs(tab) do
    	local key_Ex = ""
    	if k == 1 then
    		key_Ex = ""
    	else
    		key_Ex = "_" .. (k - 1)
    	end
        -- setSpriteFrameByName(self.rootItems["i_soulsprite_"..k], v.name)
        -- ui.setNewIcon(self.rootItems,{cid = tab[i]})
         self.rootItems["i_button"..key_Ex]:addHandleOfControlEvent(function()
         	print("分享啦", data.receiveId)
            UIRequest({type = 3691, receiveId = data.receiveId})
            gameWindows:closeWindow("share")
        end, CCControlEventTouchUpInside)
        self.rootItems["i_button"..key_Ex]:setTouchPriority(self.touchPriority) 
    end
end

function share.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return share

