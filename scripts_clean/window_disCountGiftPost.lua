
local disCountGiftPost = {
    rootNode = nil,
    rootItems = nil,
    activityid = 0,

    cancelTip = "discountGift",
}

function disCountGiftPost.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("MainScene/tehuilibaobg", nil, true, "tehuilibaobg")
    self.touchPriority = touchPriority
    self.activityid = data or 0
    print("disCountGiftPost data"..self.activityid)
    self:reload(data,callback)

    return self.rootNode
end

function disCountGiftPost.reload(self,data,callback)

   local bgnames = "tehuilbaobg_new"
   local config = gamedata.config.special_gift_time_x1
   if self.activityid == 151 then
         config = gamedata.config.special_gift_time_x2
        if config["1"] and config["1"].picture then
            bgnames = config["1"].picture 
        end 
   elseif self.activityid == 152 then
         config = gamedata.config.special_gift_time_x3
        if config["1"] and config["1"].picture then
            bgnames = config["1"].picture 
        end 
   else
      if self.activityid == 150 and  GameScene.layers["activity"].module.dailyCpActivityTimeStatus[150] then
                local cpnum = GameScene.layers["activity"].module.dailyCpActivityTimeStatus[150].cpnum or 0
                local cpday = GameScene.layers["activity"].module.dailyCpActivityTimeStatus[150].cpday or 0

                local picture = "activity_huoying"
                local status = {}
                for k,v in pairs(gamedata.config.special_gift_time_x1) do
                    if v.day and v.day ~= "" then
                        table.insert(status,v)
                    end
                end
                table.sort(status, function(a,b) return a.day < b.day end)
                for i=1 , table.getTableLength(status) do
                    local currentday = status[i].day
                    local afterday =  (status[i+1] ~=nil)  and (status[i+1].day) or  -1
                    if cpday>=currentday and cpday<afterday then
                          picture = status[i].picture
                          break
                    end    
                    if afterday == -1 and cpday>=currentday  then
                        picture = status[i].picture
                        break
                    end    
                 end

                bgnames = picture

      end      
   end 
    print("disCountGiftPost bgnames:"..bgnames)
   if bgnames~= "" then
       setSpriteFrameByName( self.rootItems.picsprite,bgnames)
   end 


    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        --self.callback = nil
        gameWindows:closeWindowDirect("disCountGiftPost")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.buyButton:addHandleOfControlEvent(function()
        --self.callback = nil
        gameWindows:closeWindowDirect("disCountGiftPost")
        printT(GameScene.layers["activity"].module.pageTable,"pagetable")
        if self.activityid == 150 then
           GameScene:shiftLayerById(552)
        elseif self.activityid == 151 then
           GameScene:shiftLayerById(553)
        elseif self.activityid == 152 then
           GameScene:shiftLayerById(554)
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.buyButton:setSwallowsTouch(true)
    self.rootItems.buyButton:setTouchPriority(self.touchPriority-1)

    ui.setLabelString(self.rootItems.buyLab,nil,19)
    --

end

function disCountGiftPost.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return disCountGiftPost

