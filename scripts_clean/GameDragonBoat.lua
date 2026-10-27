--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/5/17
-- Time: 17:54
-- To change this template use File | Settings | File Templates.
--

local params_pb = require("params_pb")
local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local battleresult_pb = require("battleresult_pb")
local combmessages_pb = require("combmessages_pb")
require"PickBattleResultReport"

function UIDumplingSearchCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3306, "DumplingSearch")

    return 1, 3306, nil

end

function NetDumplingSearchCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3306, "DumplingSearch")
    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)
    return { type = 3306 ,num = Result.ids[1]}
end

function UIDumplingUsedCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3307, "DumplingUsed")

    return 1, 3307, nil

end

function NetDumplingUsedCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3307, "DumplingUsed")
    -- NET type:3307 cmd:DumplingUsed recv response from gameserver
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    local reward, used, ext = gamedata:SomethingProcess(SomeThings,"dumpling")
    -- printT(reward,"==reward==")
    -- printT(used,"==used==")
    -- printT(ext,"==ext==")
    return { type = 3307 , _reward = reward,_type = ext._type}
end

function UIDragonBoatSearchCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3901, "DragonBoatSearch")
    return 1, 3901, nil
end

function NetDragonBoatSearchCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3901, "DragonBoatSearch")
    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)
    local tmpArray = {}
    for i=1,7 do
        table.insert(tmpArray,Result.ids[i])
    end
    printT(tmpArray,"tmpArray====1")
    return { type = 3901,_ids = tmpArray}
end

function UIDragonBoatUsedCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3902, "DragonBoatUsed")
    local FriendReqData = ids_pb.Ids()
    for k,v in pairs(uireq.ids) do
        table.insert(FriendReqData.ids, v)
    end

    return 1, 3902, FriendReqData:SerializeToString()
end

function NetDragonBoatUsedCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3902, "DragonBoatUsed")
    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)
    local tmpArray = {}
    for i=1,7 do
        table.insert(tmpArray,Result.ids[i])
    end
    printT(tmpArray,"tmpArray====1")
    return { type = 3902,_ids = tmpArray}
end
