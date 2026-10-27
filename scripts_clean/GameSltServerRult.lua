--
-- Created by IntelliJ IDEA.
-- User: WangTao
-- Date: 13-5-20
-- Time: 上午10:19
-- To change this template use File | Settings | File Templates.
--

local selectserver_pb = require("selectserver_pb")
function UIGameSelectServerCallback(uireq)
    -- 发送用户登陆请求
    cclog("NET type:%d cmd:%s recv request from UI", 5, "UIGameSelectServerCallback")
    cclog("uireq_id: %s", uireq.id)
    local selectserver = selectserver_pb.SelectServer()
    gamedata.selectserver = tonumber(uireq.id, 10)
    selectserver.sid = tonumber(uireq.id, 10)
    local sltSer2bit = selectserver:SerializeToString()
    return 1, 5, sltSer2bit
end

--local selectserverresult_pb = require("selectserverresult_pb")
--function NetGameSltServerRultCallback(fd)
--    -- disable net progress
--    isParseProgress = false
--
--    print("---------------UINetGameSltServerRultCallback-----------------")
--    local sltresult = selectserverresult_pb.SelectServerResult()
--    sltresult:ParseFromString(fd.rbuf)
--    print("sltserverrelt_pb.sid=  ", sltresult.sid)
--    gamedata.role.uuid = sltresult.sid
--    print(gamedata.role.uuid)
--    return { type = 5, sid = sltresult.sid }
--end


local sectionsession_pb = require("sectionsession_pb")
function NetGameSltServerRultCallback(fd)
    cclog("NET type:%d cmd:%s recv request from NET", 5, "NetGameSltServerRultCallback")
    cclog("set isParseProgress false")
    isParseProgress = false
    local sltresult = sectionsession_pb.SectionSession()
    sltresult:ParseFromString(fd.rbuf)
    print("sltserverrelt_pb.sid=  ", sltresult.sid, "section=", sltresult.section)
    gamedata.section = sltresult.section
    gamedata.role.uuid = sltresult.sid
    return { type = 5, sid = sltresult.sid , section = sltresult.section}
end     