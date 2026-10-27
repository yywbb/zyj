local somethings_pb = require("somethings_pb")
local ids_pb = require("ids_pb")

function UIUserADQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 8091, "UserADQuery")

    return 1, 8091, nil

end

function NetUserADQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8091, "UserADQuery")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata:setAdStatus(ids.ids)

    return { type = 8091, adStatus = gamedata.cache.adStatus }
end

function UIUserADRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 8092, "UserADReward")

    local Data = ids_pb.Ids()
    table.insert(Data.ids, uireq.index or 0)

    return 1, 8092, Data:SerializeToString()

end

function NetUserADRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8092, "UserADReward")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    local reward = gamedata:SomethingProcess(SomeThings)

    return { type = 8092, reward = reward, adStatus = gamedata.cache.adStatus }
end

function UIUserADChangsStatusCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 8093, "UserADChangsStatus")
    local Data = ids_pb.Ids()
    table.insert(Data.ids, uireq.index or 0)

    return 1, 8093, Data:SerializeToString()
end

function NetUserADChangsStatusCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8093, "UserADChangsStatus")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata:setAdStatus(ids.ids)

    return { type = 8093, adStatus = gamedata.cache.adStatus }
end