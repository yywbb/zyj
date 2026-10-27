--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/10
-- Time: 下午3:35
-- To change this template use File | Settings | File Templates.
--
local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local liveness_pb = require("liveness_pb")

function UILivenessCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2410, "Liveness")

    -- if next(gamedata.cache.liveness) ~= nil then
    --     return 0, 2410, { type = 2410, liveness = gamedata.cache.liveness }
    -- else
        return 1, 2410, nil
    -- end
end

function NetLivenessCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2410, "Liveness")
    local LivenessData = liveness_pb.Liveness()
    LivenessData:ParseFromString(fd.rbuf)

    gamedata:Liveness(LivenessData)

    return { type = 2410, liveness = gamedata.cache.liveness }
end

function UILivenessRewardCallBack(uireq)
    -- cclog("NET type:%d cmd:%s recv request from UI", 2411, "LivenessReward")
    -- local LivenessRewardData = ids_pb.Ids()

    -- table.insert(LivenessRewardData.ids, uireq.id)
    -- gamedata.ext.LivenessRewardDataid = uireq.id

    -- return 1, 2411, LivenessRewardData:SerializeToString()
    cclog("NET type:%d cmd:%s recv request from UI", 2411, "LivenessReward")
    gamedata.ext.LivenessRewardDataid = nil
    if uireq.id then
        local LivenessRewardData = ids_pb.Ids()
        table.insert(LivenessRewardData.ids, uireq.id)
        gamedata.ext.LivenessRewardDataid = uireq.id
        return 1, 2411, LivenessRewardData:SerializeToString()
    else
        return 1, 2411, nil
    end
end

function NetLivenessRewardCallBack(fd)
    -- cclog("NET type:%d cmd:%s recv response from gameserver", 2411, "LivenessReward")
    -- local SomeThings = somethings_pb.SomeThings()
    -- SomeThings:ParseFromString(fd.rbuf)

    -- if gamedata.ext.LivenessRewardDataid > 100 then
    --     gamedata.cache.liveness.items[gamedata.ext.LivenessRewardDataid-100]["status"] = 2
    -- else
    --     gamedata.cache.liveness.reward[gamedata.ext.LivenessRewardDataid] = 2
    -- end

    -- return { type = 2411, reward = gamedata:SomethingProcess(SomeThings), liveness = gamedata.cache.liveness}
    cclog("NET type:%d cmd:%s recv response from gameserver", 2411, "LivenessReward")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    if gamedata.ext.LivenessRewardDataid then
        if gamedata.ext.LivenessRewardDataid > 100 then
            gamedata.cache.liveness.items[gamedata.ext.LivenessRewardDataid-100]["status"] = 2
        else
            gamedata.cache.liveness.reward[gamedata.ext.LivenessRewardDataid] = 2
        end
    else
        for k , v in pairs(gamedata.cache.liveness) do
            if v.status == 1 then
                gamedata.cache.liveness[k] = nil
            end
        end
    end
    return {
        type = 2411,
        liveness = gamedata.cache.liveness,
        reward = gamedata:SomethingProcess(SomeThings)
    }
end


function UITotalLivenessCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6517, "TotalLiveness")
    return 1, 6517, nil
end

function NetTotalLivenessCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6517, "TotalLiveness")
    gamedata.cache.zhoustatus = {}
    local data = ids_pb.Ids()
    data:ParseFromString(fd.rbuf)

    local huoyuedu = 0
    for i,v in ipairs(data.ids) do
        if i == 1 then
            huoyuedu = data.ids[1]
        else    
            table.insert(gamedata.cache.zhoustatus,data.ids[i])
        end    
    end

    return { type = 6517, huoyuedu = huoyuedu, weekstatus = gamedata.cache.zhoustatus or {} }
end



function UIWeekLivenessCallBack2(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6530, "WeekLiveness")

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id)

    print(uireq.id," uireq.id")

    return 1, 6530, idsData:SerializeToString()
end

function NetWeekLivenessCallBack2(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6530, "WeekLiveness")

    local reward = {}
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    reward = gamedata:SomethingProcess(SomeThings)


    return { type = 6530, reward = reward }
end

