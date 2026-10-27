--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午5:53
-- To change this template use File | Settings | File Templates.
--

local fbbind = {
    rootNode = nil,
    rootItems = nil,
    data = nil,
}

function fbbind.open(self,touchPriority,data,callback)
    cclog("window_bindReward open")
    self.rootNode, self.rootItems = CCBReaderLoad("activityfenxiang2/tc_bangding", nil, true, "fbbind")
    self:initFixedString()
    self.touchPriority = touchPriority
    self.rootItems.fbbangdingButton:setSwallowsTouch(true)
    self.rootItems.fbbangdingButton:setSwallowsTouch(true)
    self.rootItems.fbbangdingButton:setTouchPriority(self.touchPriority)
    self.rootItems.fbbangdingButton:addHandleOfControlEvent(function()
            sdk:fbSDK_ByType("openbangding")
            gameWindows:closeWindow("fbbind")
        end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("fbbind")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)    
    self:reload(self,data,callback)
    return self.rootNode
end

function fbbind.reload(self,data,callback)
    cclog("window_bindReward reload")
    self.data = data

      local fbdata = gamedata.config.global_kv.gat_bangdingzhanghao_facebook.value
      local rewaretable ={}
      local t1 = ui.Split(fbdata,";")
      for k,v in pairs(t1) do
          if v ~= nil and v ~= "" then
            local t = ui.Split(v,",")
              local rewardData ={}
              rewardData.cid = tonumber(t[1])
              rewardData.num = tonumber(t[2])
              table.insert(rewaretable,rewardData)
            end
      end 
    printT(rewaretable)
    for i=1, 1 do
        if rewaretable[i] and rewaretable[i].cid > 0 then
            ui.setNewIconName(self.rootItems,rewaretable[i],i-1)
            self.rootItems["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
                ui.setPopwindowByCid(fbsharedata[i].cid)
            end, CCControlEventTouchUpInside)
            self.rootItems["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(self.touchPriority)
        else
             self.rootItems["i_button"..(i>1 and "_"..i-1 or "")]:setVisible(false)
        end
    end   
end

function fbbind.reset(self,data,callback)
   cclog("window_bindReward reset")
end

function fbbind.close(self)
   cclog("window_bindReward close")
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function fbbind.initFixedString( self )
end

return fbbind