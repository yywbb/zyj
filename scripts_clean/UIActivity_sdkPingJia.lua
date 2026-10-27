--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午7:42
-- To change this template use File | Settings | File Templates.
--

local fb_time = nil 

-------------活动页 评价状态查询
function UIActivitySDKPingJiaDataQuery(t)
    print("fb状态 30010，接受客户端数据")
    printT(t)
   if  GameScene.layers["activity"].module.pageTable[98] then
        GameScene.layers["activity"].module.pageTable[98].module:reloaddata(t,false)
    end
end
-------------活动页 评价成功
function UIActivitySDKPingJiaSuccess(t)
    print("fb状态 30101，接受客户端数据")
    printT(t)
   if  GameScene.layers["activity"].module.pageTable[98] then
        GameScene.layers["activity"].module.pageTable[98].module:reloaddata(t,false)
    end
     if fb_time ~= nil then
      CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(fb_time)
      fb_time = nil
   end
end
-------------活动页 评价获取奖励
function UIActivitySDKPingJiagetReward(t)
    print("fb状态 30102，接受客户端数据")
    printT(t)
    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type =1001})
    end)
    local rewardStatue =  { sharestutue = 1, getstatue = 1 } 
   if  GameScene.layers["activity"].module.pageTable[98] then
        GameScene.layers["activity"].module.pageTable[98].module:reloaddata(rewardStatue,true)
    end
end

function UISDKPingJiaStatueChange(t)
    print("fb状态 30005，接受客户端数据")
    printT(t)
    
    if fb_time ~= nil then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(fb_time)
    else    
         local nowtime = 0
         fb_time = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function ()
         nowtime = nowtime + 1
         if nowtime%2==0 then
             local sdktype = t.sdktype
              if sdktype == "pingjiasuccess" then
                 UIRequest({type = 30101}) 
              end    
         end
         if nowtime == 60 then
            if fb_time ~= nil then
                CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(fb_time)
            end
         end   
       end,1,false)
    end    
end
