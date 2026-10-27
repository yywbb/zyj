--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/4/25
-- Time: 下午12:27
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")

function UIUserDataCollectCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 999901, "UserDataCollect")

    local UserDataCollect = ids_pb.Ids()
    table.insert(UserDataCollect.ids, uireq.id)

    return 1,999901,UserDataCollect:SerializeToString()
end