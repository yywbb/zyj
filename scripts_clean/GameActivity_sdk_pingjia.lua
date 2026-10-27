
--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午7:10
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
--活动页 查询评价状态
function UIActivityfbSDKPingJiaDataQueryCallBack(uireq)
        cclog("NET type:%d cmd:%s recv request from UI", 30100, "SDKPingJia")
      return 1, 30100, nil
end

function NetActivityfbSDKPingJiaDataQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 30100, "PingJia")
   local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local dz1 = ids.ids[1]
    local dz2 = ids.ids[2]
    return { type = 30100,  rewardStatue = { sharestatue = dz1, getstatue = dz2 } }
end


--活动页  评价成功
function UIActivityfbSDKPingJiaSuccess(uireq)
        cclog("NET type:%d cmd:%s recv request from UI", 30101, "SDKActivityPingJia")
      return 1, 30101, nil
end


function NetActivityfbSDKPingJiaSuccess(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 30101, "SDKActivityPingJia")
    return { type = 30101,  rewardStatue = { sharestutue = 1, getstatue = 0 }  }
end

--活动页 评价领取奖励
function UIActivityfbSDKPingJiagetReward(uireq)
        cclog("NET type:%d cmd:%s recv request from UI", 30102, "SDKActivityPingJia")
      return 1, 30102, nil
end


function NetActivityfbSDKPingJiagetReward(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 30102, "SDKActivityPingJia")
     local getData = somethings_pb.SomeThings()
     getData:ParseFromString(fd.rbuf)
    return { type = 30102,  reward = gamedata:SomethingProcess(getData) }
end




