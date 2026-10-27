
--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午7:10
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")

--  主页 图标状态获取，并缓存到本地
function UIMainfbSDKShareQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 30000, "fbSDKData")
    return 1, 30000, nil 
end

function NetMainfbSDKShareQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 30000, "fbSDKData")
    printT(fd)
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local dz1 = ids.ids[1]
    local dz2= ids.ids[2]
    local dz3 = ids.ids[3] 

    gamedata.cache.fbstatue = { fblike = dz1, fbshare = dz2 , fbbind = dz3 }
    
    cclog("NetActivityfbSDKShareQueryCallBack fblike:%s  fbshare:%s  fbbind:%s",dz1,dz2,dz3)

    return { type = 30000, fbstatue = gamedata.cache.fbstatue }
end

-- 主页获取缓存在gamedata的图标 显示状态
function UIMainfbSDKLocalStatue(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 30004, "fbSDKData")
    if gamedata.cache.fbstatue ~= nil then
        cclog("30004---------------nil 1")
        return 0, 30004,  { type = 30004, fbstatue = gamedata.cache.fbstatue }
    else
         cclog("30004---------------2 ")
        return 1, 30000, nil 
    end  
end

--  主页 分享成功
function UIMainfbSDKShareDataQueryCallBack(uireq)
     cclog("NET type:%d cmd:%s recv request from UI", 30002, "fbSDKShare")
    if gamedata.cache.fbstatue.fbshare == 0 then       
        return 1, 30002, nil
    else      
        return 0, 30002, nil
    end    
end


function NetMainfbSDKShareDataQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 30002, "fbSDKShare")
    -- printT(fd)
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)
    gamedata.cache.fbstatue.fbshare = 1 
    UIRequest({type = 30004})
    return { type = 30002,  reward = gamedata:SomethingProcess(getData) }
end

--  主页 点赞成功
function UIMainfbSDKLikeQueryCallBack(uireq)
     cclog("NET type:%d cmd:%s recv request from UI", 30001, "fbSDKLike")
    if gamedata.cache.fbstatue.fblike == 0 then       
        return 1, 30001, nil
    else      
        return 0, 30001, nil
    end    
end

function NetMainfbSDKLikeQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 30001, "fbSDKLike")
    -- printT(fd)
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)
    gamedata.cache.fbstatue.fblike = 1 
    UIRequest({type = 30004})
    return { type = 30001,  reward = gamedata:SomethingProcess(getData) }
end

--  主页 绑定账户成功
function UIMainfbSDKBindDataQueryCallBack(uireq)
        cclog("NET type:%d cmd:%s recv request from UI", 30003, "fbSDKBind")
    if gamedata.cache.fbstatue.fbbind == 0 then      
        return 1, 30003, nil
    else      
        return 0, 30003, nil
    end    
end

function NetMainfbSDKBindDataQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 30003, "fbSDKBind")
   -- printT(fd)
   local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)
    gamedata.cache.fbstatue.fbbind = 1 
    UIRequest({type = 30004})
    return { type = 30003,  reward = gamedata:SomethingProcess(getData)  }
end


--活动页 查询分享状态
function UIActivityfbSDKShareDataQueryCallBack(uireq)
        cclog("NET type:%d cmd:%s recv request from UI", 30100, "fbSDKBind")
      return 1, 30100, nil
end

function NetActivityfbSDKShareDataQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 30100, "fbSDKBind")
   local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local dz1 = ids.ids[1]
    local dz2 = ids.ids[2]
    return { type = 30100,  rewardStatue = { sharestatue = dz1, getstatue = dz2 } }
end


--活动页  分享成功
function UIActivityfbSDKShareSuccess(uireq)
        cclog("NET type:%d cmd:%s recv request from UI", 30101, "fbSDKActivityShare")
      return 1, 30101, nil
end


function NetActivityfbSDKShareSuccess(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 30101, "fbSDKActivityShare")
    return { type = 30101,  rewardStatue = { sharestutue = 1, getstatue = 0 }  }
end

--活动页 分享领取奖励
function UIActivityfbSDKSharegetReward(uireq)
        cclog("NET type:%d cmd:%s recv request from UI", 30102, "fbSDKActivityShare")
      return 1, 30102, nil
end


function NetActivityfbSDKSharegetReward(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 30102, "fbSDKActivityShare")
     local getData = somethings_pb.SomeThings()
     getData:ParseFromString(fd.rbuf)
    return { type = 30102,  reward = gamedata:SomethingProcess(getData) }
end


--活动页 查询邀请状态
function UIActivityfbSDKInviteDataQueryCallBack(uireq)
        cclog("NET type:%d cmd:%s recv request from UI", 30200, "fbActivitySDKInvite")
      return 1, 30200, nil
end

function NetActivityfbSDKInviteDataQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 30200, "fbActivitySDKInvite")
   local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local dz1 = ids.ids[1]
    local dz2 = ids.ids[2]
    return { type = 30200,  rewardStatue = { sharestatue = dz1, getstatue = dz2 } }
end


--活动页  邀请成功
function UIActivityfbSDKInviteSuccess(uireq)
        cclog("NET type:%d cmd:%s recv request from UI", 30201, "fbActivitySDKInvite")
      return 1, 30201, nil
end


function NetActivityfbSDKInviteSuccess(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 30201, "fbActivitySDKInvite")
    return { type = 30201,  rewardStatue = { sharestutue = 1, getstatue = 0 }  }
end


--活动页  邀请领取奖励
function UIActivityfbSDKInvitegetReward(uireq)
        cclog("NET type:%d cmd:%s recv request from UI", 30202, "fbSDKActivityShare")
      return 1, 30202, nil
end

function NetActivityfbSDKInvitegetReward(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 30202, "fbSDKActivityShare")
     local getData = somethings_pb.SomeThings()
     getData:ParseFromString(fd.rbuf)
    return { type = 30202,  reward = gamedata:SomethingProcess(getData) }
end



