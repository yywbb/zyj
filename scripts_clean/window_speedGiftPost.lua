
local speedGiftPost = {
    rootNode = nil,
    rootItems = nil,
    activityid = 0,

    cancelTip = "speedGift",
}

function speedGiftPost.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("MainScene/jiasulibaobg", nil, true, "jiasulibaobg")
    self.touchPriority = touchPriority
    self.activityid = data.activityId

    print("speedGiftPost data"..self.activityid)
    self:reload(data,callback)
    return self.rootNode
end

function speedGiftPost.reload(self,data,callback)

   local bgnames = "jiasulibaobg_new"
   local config = gamedata.config.speedup_gift_time_x1
   if self.activityid == 154 then
         config = gamedata.config.speedup_gift_time_x2
   elseif self.activityid == 155 then
         config = gamedata.config.speedup_gift_time_x3
   end 


    --找到对应轮数的奖励字符串和icon
    local rewardStr = ""
    local bgnames = ""
    local activitydata = GameScene.layers["activity"].module:getDailyCPActivityDataById(tonumber(self.activityid))
    printT(activitydata,"activitydata")
    self.status = {}
    for k,v in pairs(config) do
        if v.day and v.day ~= "" then
            table.insert(self.status,v)
        end
    end
    table.sort(self.status, function(a,b) return a.day < b.day end)
    printT(self.status)
    if activitydata and activitydata.cpday then
        local cpday = activitydata.cpday or 1
        for i=1 , table.getTableLength(self.status) do
            local currentday = self.status[i].day
            local afterday =  (self.status[i+1] ~=nil)  and (self.status[i+1].day) or  -1 
            printT(self.status[i],"--------")
            if cpday>=currentday and cpday<afterday then
                  rewardStr = self.status[i].reward
                  bgnames = self.status[i].picture
                  break
            end    
            if afterday == -1 and cpday>=currentday  then
                rewardStr = self.status[i].reward
                bgnames = self.status[i].picture
                break
            end    
        end
    end



   -- if config["1"] and config["1"].picture then
   --     bgnames = config["1"].picture 
   -- end 
    print("speedGiftPost bgnames:"..bgnames)

   if bgnames~= "" then
       setSpriteFrameByName( self.rootItems.picsprite,bgnames)
   end 

    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        --self.callback = nil
        gameWindows:closeWindowDirect("speedGiftPost")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.buyButton:addHandleOfControlEvent(function()
        --self.callback = nil
        gameWindows:closeWindowDirect("speedGiftPost")
         if self.activityid == 153 then
           GameScene:shiftLayerById(555)
        elseif self.activityid == 154 then
           GameScene:shiftLayerById(556)
        elseif self.activityid == 155 then
           GameScene:shiftLayerById(557)
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.buyButton:setSwallowsTouch(true)
    self.rootItems.buyButton:setTouchPriority(self.touchPriority-1)

    ui.setLabelString(self.rootItems.buyLab,nil,19)
    --

end

function speedGiftPost.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return speedGiftPost

