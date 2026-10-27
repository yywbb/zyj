--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/31
-- Time: 上午10:58
-- To change this template use File | Settings | File Templates.
--

local sdkfbshare = {

    rootNode = nil,
    rootItems = nil,
    buttontouch = -101,

    fbsharestatue =  nil,
    fbgetstatue =  nil,
}



function sdkfbshare.init(self,size)
    self.contentsize = size
    self.show = true

    self.rootNode,self.rootItems = CCBReaderLoad("activityfenxiang2/activityfenxiang_fenxiang", nil, true, "fbshare")
    self.rootItems.topnode1:setPositionY(self.contentsize.y-180)
  local fbdata = gamedata.config.global_kv.gat_fenxianghuodong_facebook.value
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
    for i=1, 3 do
        if rewaretable[i] and rewaretable[i].cid > 0 then
            ui.setNewIcon(self.rootItems,rewaretable[i],i-1)
            self.rootItems["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
                ui.setPopwindowByCid(fbsharedata[i].cid)
            end, CCControlEventTouchUpInside)
        end
    end   

    --fb分享
    self.rootItems.fbshareButton:addHandleOfControlEvent(function()
         if GameScene.layers["activity"].module.isContentScroll then  return end
          if self.fbsharestatue == 0 then
                sdk:fbSDK_ByType("aopenshare")
          elseif  self.fbgetstatue == 0 then
                UIRequest({type = 30102}) 
          end 
    end,CCControlEventTouchUpInside)
   
   self.rootItems.fbshareButton:setVisible(false)
   self.rootItems.fbshareText:setVisible(false)
    return self.rootNode
end


function sdkfbshare.reloaddata(self,data,islocal)
    if not self.show then return end
    if not data then return end
    if islocal  then 
          self.fbsharestatue = tonumber(data.sharestatue )
          self.fbgetstatue = tonumber(data.getstatue )
    else   
          self.fbsharestatue = tonumber(data.rewardStatue.sharestatue )
          self.fbgetstatue = tonumber(data.rewardStatue.getstatue )
    end    
    if self.fbsharestatue == 0 then
        self.rootItems.fbshareText:setString(gameConfig.strings:string_common("fixedString","activity_fbshare",1))
     else 
       if  self.fbgetstatue    == 0 then
           self.rootItems.fbshareText:setString(gameConfig.strings:string_common("fixedString","activity_fbshare",3))
       else    
           ui.addGray("CCControlButton",self.rootItems.fbshareButton)
           self.rootItems.fbshareText:setString(gameConfig.strings:string_common("fixedString","activity_fbshare",4))
       end
     end   
   self.rootItems.fbshareButton:setVisible(true)
    self.rootItems.fbshareText:setVisible(true)
end

function sdkfbshare.clear(self)
    self.show = false
    self.rootNode = nil
    self.rootItems = nil
    self.buttontouch = nil
    self.fbsharestatue =  nil
    self.fbgetstatue =  nil
end


function sdkfbshare.UIUpdateData(self, isget)

end

return sdkfbshare