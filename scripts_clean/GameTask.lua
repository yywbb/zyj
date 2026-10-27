--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/2
-- Time: 下午7:25
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local tasks_pb = require"tasks_pb"
local somethings_pb = require("somethings_pb")

function UITaskQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2400, "TaskQuery")
    print("UITaskQueryCallBack===")
--    if next(gamedata.cache.task) ~= nil then
--        return 0,2400,{type=2400,task=gamedata.cache.task}
--    else
        return 1,2400,nil
 --   end
end

function NetTaskQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2400, "TaskQuery")
    local taskResponse = tasks_pb.Tasks()
    taskResponse:ParseFromString(fd.rbuf)

    gamedata:Task(taskResponse)

    return {type=2400,task=gamedata.cache.task}
end

function UITaskCompleteCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2401, "TaskComplete")

    gamedata.ext.TaskCompleteid = nil

    if uireq.id then
        local TaskCompleteData = ids_pb.Ids()
        table.insert(TaskCompleteData.ids,uireq.id)
        gamedata.ext.TaskCompleteid = uireq.id
        return 1, 2401, TaskCompleteData:SerializeToString()
    else
        return 1, 2401, nil
    end
end

function NetTaskCompleteCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2401, "TaskComplete")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)


    if gamedata.ext.TaskCompleteid then
        gamedata.cache.task[gamedata.ext.TaskCompleteid] = nil
    else
        for k , v in pairs(gamedata.cache.task) do
            if v.status == 1 then
                gamedata.cache.task[k] = nil
            end
        end
    end

    return {
        type = 2401,
        task=gamedata.cache.task,
        reward = gamedata:SomethingProcess(SomeThings)
    }
end

function UIOnlineRewardQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2037, "OnlineReward")

    gamedata.config.OnlineRewardDataparam = uireq.param

    return 1,2037,nil
end

function NetOnlineRewardQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2037, "OnlineReward")
    local OnlineRewardData = ids_pb.Ids()
    OnlineRewardData:ParseFromString(fd.rbuf)

    local reward = {}
    if #OnlineRewardData.ids ~= 0 then
        reward.id = OnlineRewardData.ids[1]
        reward.time = OnlineRewardData.ids[2]
        reward.active = OnlineRewardData.ids[2] > 0 or nil
    end


    return {type=2037, reward = reward, param = gamedata.config.OnlineRewardDataparam}
end

function UIOnlineRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2038, "OnlineReward")

    return 1,2038,nil
end

function NetOnlineRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2038, "OnlineReward")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    return {type=2038, reward = gamedata:SomethingProcess(SomeThings)}
end

---------------------------------------------------------------------------------------

function UIOnlineRewardByTimeQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2039, "OnlineRewardByTime")

    gamedata.config.OnlineRewardByTimeDataparam = uireq.param

    return 1,2039,nil
end

function NetOnlineRewardByTimeQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2039, "OnlineRewardByTime")
    local OnlineRewardData = ids_pb.Ids()
    OnlineRewardData:ParseFromString(fd.rbuf)

    local reward = {}
    if #OnlineRewardData.ids ~= 0 then
        reward.id = OnlineRewardData.ids[1]
        reward.time = OnlineRewardData.ids[2]
        reward.active = OnlineRewardData.ids[2] > 0 or nil
    end


    return {type=2039, reward = reward, param = gamedata.config.OnlineRewardByTimeDataparam}
end

function UIOnlineRewardByTimeCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2040, "OnlineRewardByTime")

    return 1,2040,nil
end

function NetOnlineRewardByTimeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2040, "OnlineRewardByTime")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    return {type=2040, reward = gamedata:SomethingProcess(SomeThings)}
end