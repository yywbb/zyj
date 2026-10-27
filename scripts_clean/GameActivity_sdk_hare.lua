
--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午7:10
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")


-- 查询
function UIActivitySDKShareQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2085, "SDKShare")

    return 1, 2085, nil
end

function NetActivitySDKShareQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2085, "SDKShare")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local rewardstatus = ids.ids[1] or 0
    
    return { type = 2085, rewardstatus = rewardstatus}
end

--
function UIActivitySDKShareDoCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2086, "SDKShare")

    return 1, 2086, nil
end

function NetActivitySDKShareDoCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2086, "SDKShare")

    return { type = 2086 }
end


--
function UIActivitySDKShareRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2087, "SDKShare")

    return 1, 2087, nil
end

function NetActivitySDKShareRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2087, "SDKShare")

    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    return { type = 2087, reward = gamedata:SomethingProcess(getData),}
end