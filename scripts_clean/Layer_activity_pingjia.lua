--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/31
-- Time: 上午10:58
-- To change this template use File | Settings | File Templates.
--

local sdkgppingjia = {

    rootNode = nil,
    rootItems = nil,
    buttontouch = -101,

    fbsharestatue =  nil,
    fbgetstatue =  nil,
}



function sdkgppingjia.init(self,size)
    self.contentsize = size
    self.show = true

    self.rootNode,self.rootItems = CCBReaderLoad("activityfenxiang2/activityfenxiang_yaoqing", nil, true, "sdkpingjia")
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
                ui.setPopwindowByCid(rewaretable[i].cid)
            end, CCControlEventTouchUpInside)
        end
    end   

    --fb分享
    self.rootItems.fbInviteButton:addHandleOfControlEvent(function()
         if GameScene.layers["activity"].module.isContentScroll then  return end
          if self.fbsharestatue == 0 then
               if gamedata.sdk then
                  --打开评价 同时评价成功
                  gamedata.sdk:forceUpdate("https://play.google.com/store/apps/details?id=com.maingames.android.CGCN")
                  UIReponse({ type = 30005, sdktype = "pingjiasuccess"})
                end
          elseif  self.fbgetstatue == 0 then
                  --领取
                  UIRequest({type = 30102}) 
          end 
    end,CCControlEventTouchUpInside)
   
   self.rootItems.fbInviteButton:setVisible(true)
   self.rootItems.fbinviteText:setVisible(true)
    return self.rootNode
end


function sdkgppingjia.reloaddata(self,data,islocal)
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
        self.rootItems.fbinviteText:setString(gameConfig.strings:string_common("fixedString","activity_sdkpingjia",1))
     else 
       if  self.fbgetstatue    == 0 then
           self.rootItems.fbinviteText:setString(gameConfig.strings:string_common("fixedString","activity_sdkpingjia",2))
       else    
           ui.addGray("CCControlButton",self.rootItems.fbInviteButton)
           self.rootItems.fbinviteText:setString(gameConfig.strings:string_common("fixedString","activity_sdkpingjia",3))
       end
     end   
   self.rootItems.fbInviteButton:setVisible(true)
    self.rootItems.fbinviteText:setVisible(true)
end

function sdkgppingjia.clear(self)
    self.show = false
    self.rootNode = nil
    self.rootItems = nil
    self.buttontouch = nil
    self.fbsharestatue =  nil
    self.fbgetstatue =  nil
end


function sdkgppingjia.UIUpdateData(self, isget)

end

return sdkgppingjia