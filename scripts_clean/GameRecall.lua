--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/9/28
-- Time: 16:28
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local params_pb = require"params_pb"

function UIRecallCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3770, "Recall")

    return 1, 3770, nil

end

function NetRecallCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3770, "Recall")

    local params = params_pb.ParamS()
    params:ParseFromString(fd.rbuf)

    local recall = {}
    recall.num = params.params[1].i or 0
    recall.code = params.params[1].s or ""
    recall.status = {}
    for i = 2,#params.params do
        table.insert(recall.status,params.params[i].i or 0)
    end
    return { type = 3770, recall = recall}

end


function UIRecallRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3771, "RecallReward")
    local recallData = ids_pb.Ids()

    table.insert(recallData.ids, uireq.id)

    gamedata.ext.recallDataid =  uireq.id

    return 1, 3771, recallData:SerializeToString()
end

function NetRecallRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3771, "RecallReward")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    return { type = 3771, reward = gamedata:SomethingProcess(SomeThings),}
end

local result_pb = require("result_pb")
function NetRecallChangeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3776, "RecallChange")

    local Result = result_pb.Result()
    Result:ParseFromString(fd.rbuf)


    return { type = 3776, result = Result.result}
end