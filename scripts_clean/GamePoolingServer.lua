local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")

function UIPoolingServerSignQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6101, "UIPoolingServerSignQueryCallBack")

    return 1, 6101, nil
end

function NetPoolingServerSignQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6101, "NetPoolingServerSignQueryCallBack")

    local _ids = ids_pb.Ids()
    _ids:ParseFromString(fd.rbuf)

    local _day = _ids.ids[1] - 1
    local _getRewardCount = _ids.ids[2]
    local _getRewardStatus = _ids.ids[3]

    return {type = 6101, data = {day = _day, getRewardCount = _getRewardCount, getRewardStatus = _getRewardStatus}}
end

function UIPoolingServerSignGetRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6102, "UIPoolingServerSignGetRewardCallBack")

    return 1, 6102, nil
end

function NetPoolingServerSignGetRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6102, "NetPoolingServerSignGetRewardCallBack")

    local _somethings_pb = somethings_pb.SomeThings()
    _somethings_pb:ParseFromString(fd.rbuf)
    local _reward = gamedata:SomethingProcess(_somethings_pb)

    return {type = 6102, reward = _reward }
end

function UIPoolingServerTaskQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6103, "UIPoolingServerTaskQueryCallBack")

    return 1, 6103, nil
end

function NetPoolingServerTaskQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6103, "NetPoolingServerTaskQueryCallBack")

    local _ids = ids_pb.Ids()
    _ids:ParseFromString(fd.rbuf)

    local _day = _ids.ids[1] - 1
    local _task = {}
    local _count = 1

    for i = 2, #_ids.ids do
        if math.mod(i, 2) == 0 then
            _task[_count] = {}
            _task[_count].id = _count
            _task[_count].num = _ids.ids[i]
        else
            _task[_count].status = _ids.ids[i]
            _count = _count + 1
        end
    end

    return {type = 6103, day = _day, task = _task}
end

function UIPoolingServerTaskGetRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6104, "UIPoolingServerTaskGetRewardCallBack")

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id or 0)

    return 1, 6104, idsData:SerializeToString()
end

function NetPoolingServerTaskGetRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6104, "NetPoolingServerTaskGetRewardCallBack")

    local _somethings_pb = somethings_pb.SomeThings()
    _somethings_pb:ParseFromString(fd.rbuf)
    local _reward = gamedata:SomethingProcess(_somethings_pb)

    return {type = 6104, reward = _reward}
end

function UIPoolingServerOnlineQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6105, "UIPoolingServerOnlineQueryCallBack")

    if uireq.param == "main" then
        gamedata.ext.hefuActivity = "main"
    else
        gamedata.ext.hefuActivity = nil
    end

    return 1, 6105, nil
end

function NetPoolingServerOnlineQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6105, "NetPoolingServerOnlineQueryCallBack")

    local _ids = ids_pb.Ids()
    _ids:ParseFromString(fd.rbuf)

    local _day = _ids.ids[1] - 1
    local _currentGift = _ids.ids[2]
    local _currentCoolDown = _ids.ids[3]
    local _totalGet = _ids.ids[4]
    local _totalReward = {}

    for i = 5, #_ids.ids do
        table.insert(_totalReward, _ids.ids[i])
    end

    return {type = 6105, 
            day = _day, 
            currentGift = _currentGift, 
            currentCoolDown = _currentCoolDown,
            totalGet = _totalGet,
            totalReward = _totalReward,
            param = gamedata.ext.hefuActivity}
end

function UIPoolingServerOnlineGetRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6106, "UIPoolingServerOnlineGetRewardCallBack")

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.rewardType or 0)
    if uireq.id then
        table.insert(idsData.ids, uireq.id or 0)
    end

    return 1, 6106, idsData:SerializeToString()
end

function NetPoolingServerOnlineGetRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6106, "NetPoolingServerOnlineGetRewardCallBack")

    local _somethings_pb = somethings_pb.SomeThings()
    _somethings_pb:ParseFromString(fd.rbuf)
    local _reward = gamedata:SomethingProcess(_somethings_pb)

    return {type = 6106, reward = _reward}
end