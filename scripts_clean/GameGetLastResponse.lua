--
-- Created by IntelliJ IDEA.
-- User: jutian
-- Date: 15/2/14
-- Time: 上午7:51
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
function UIGetLastResponseCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 999989, "getlastresponse")
    cclog("get last response for msgtype:%d", uireq.msgtype)
    if uireq.msgtype == 1000 then
        return 0
    end
    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.msgtype)

    UIRequest({type=999988, msg="getlastresponse msgtype = "..uireq.msgtype, from="net", noneedfix = true})

    return 1, 999989, ids:SerializeToString()
end