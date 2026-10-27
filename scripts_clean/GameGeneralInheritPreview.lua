--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-10-11
-- Time: 上午11:37
-- To change this template use File | Settings | File Templates.
--

local function previewData(data)
    return{
        exp = data.exp,
        level = data.level,
        skilllevel = data.skilllevel,
        num = data.num,
    }

end

local inheritrequest_pb = require("inheritrequest_pb")
function UIGeneralInheritPreviewCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1010, "inheritrequest")
    local inheritrequestData = inheritrequest_pb.InheritRequest()
    inheritrequestData.fid = uireq.fid
    inheritrequestData.tid = uireq.tid
    inheritrequestData.method = uireq.method

    gamedata.ext.inheritrequest = {method = uireq.method, fid = uireq.fid, tid = uireq.tid}

    return 1, 1010, inheritrequestData:SerializeToString()
end

local inheritresponse_pb = require("inheritresponse_pb")
function NetGeneralInheritPreviewCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1010, "inheritresponse")

    local inheritresponseData = inheritresponse_pb.InheritResponse()
    inheritresponseData:ParseFromString(fd.rbuf)

    return { type = 1010, previewData = previewData(inheritresponseData),inheritrequest = gamedata.ext.inheritrequest}
end