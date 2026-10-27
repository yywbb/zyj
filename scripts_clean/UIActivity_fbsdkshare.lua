--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午7:42
-- To change this template use File | Settings | File Templates.
--

local fb_time = nil 

-------------主页面 分享／点赞／绑定状态获取
function UIMainfbSDKShareQuery(t)
    print("fb状态 30000，接受客户端数据")
    printT(t)
    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:facebookBtnShow(t.fbstatue.fblike ,t.fbstatue.fbshare ,t.fbstatue.fbbind)
    end
end
-------------主页面 分享成功
function UIMainfbSDKShareDataQuery(t)
    print("fb状态 30002，接受客户端数据")
   showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type =1001})
    end)
   if fb_time ~= nil then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(fb_time)
    fb_time = nil
   end
   printT(t)
end
-------------主页面 点赞成功
function UIMainfbSDKLikeDataQuery(t)
    print("fb状态 30001，接受客户端数据")
     showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type =1001})
    end)
    if fb_time ~= nil then
      CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(fb_time)
      fb_time = nil
   end
    printT(t)
end
-------------主页面 绑定成功
function UIMainfbSDKBindDataQuery(t)
    print("fb状态 30003，接受客户端数据")
     showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type =1001})
    end)
    if fb_time ~= nil then
      CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(fb_time)
      fb_time = nil
    end
    printT(t)
end

-------------活动页 分享状态查询
function UIActivityfbSDKShareDataQuery(t)
    print("fb状态 30010，接受客户端数据")
    printT(t)
   if  GameScene.layers["activity"].module.pageTable[98] then
        GameScene.layers["activity"].module.pageTable[98].module:reloaddata(t,false)
    end
end
-------------主页面 分享成功
function UIActivityfbSDKShareSuccess(t)
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
-------------主页面 分享获取奖励
function UIActivityfbSDKSharegetReward(t)
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

function UIActivityfbSDKInviteDataQuery(t)
    print("fb状态 30020，接受客户端数据")
    -- printT(t)
   if  GameScene.layers["activity"].module.pageTable[99] then
        GameScene.layers["activity"].module.pageTable[99].module:reloaddata(t,false)
    end
end

-------------
function UIActivityfbSDKInviteSuccess(t)
    print("fb状态 30201，接受客户端数据")
    printT(t)
   if  GameScene.layers["activity"].module.pageTable[99] then
        GameScene.layers["activity"].module.pageTable[99].module:reloaddata(t,false)
    end
     if fb_time ~= nil then
      CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(fb_time)
      fb_time = nil
   end
end

function UIActivityfbSDKInvitegetReward(t)
    print("fb状态 30202，接受客户端数据")
    printT(t)
    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type =1001})
    end)
    local rewardStatue =  { sharestutue = 1, getstatue = 1 } 
   if  GameScene.layers["activity"].module.pageTable[99] then
        GameScene.layers["activity"].module.pageTable[99].module:reloaddata(rewardStatue,true)
    end
end

function UIMainfbSDKStatue(t)
    print("fb状态 30004，接受客户端数据")
    printT(t)
    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:facebookBtnShow(t.fbstatue.fblike ,t.fbstatue.fbshare ,t.fbstatue.fbbind)
    end
end


function UIFBSDKStatueChange(t)
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
              if sdktype == "sharesuccess" then
                 UIRequest({type = 30002})
              elseif sdktype == "invitesuccess" then
                 UIRequest({type = 30201}) 
              elseif sdktype == "bangdingsuccess" then
                 UIRequest({type = 30003})
              elseif sdktype == "likesuccess"  then
                 UIRequest({type = 30001})
              elseif sdktype == "asharesuccess" then
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
