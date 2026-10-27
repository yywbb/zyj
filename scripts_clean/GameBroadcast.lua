--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/2
-- Time: 下午5:27
-- To change this template use File | Settings | File Templates.
--

local stringcontent_pb = require("stringcontent_pb")

function NetBroadcastCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1999, "Broadcast")

    local BroadcastData = stringcontent_pb.StringContent()
    BroadcastData:ParseFromString(fd.rbuf)

    return { type = 1999, BroadcastData = BroadcastData.content,}
end