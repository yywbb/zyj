--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/2/4
-- Time: 上午10:23
-- To change this template use File | Settings | File Templates.
--

local idnums_pb = require("idnums_pb")

function UIGeneralCollectCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1015, "GeneralCollect")

    return 1, 1015, nil
end

function NetGeneralCollectCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1015, "GeneralCollect")

    local data = idnums_pb.IdNums()
    data:ParseFromString(fd.rbuf)

    gamedata:GeneralCollect(data)

    return { type = 1015, generalcollect = gamedata.cache.generalcollect}
end


function UIEquipCollectCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1103, "EquipCollect")

    return 1, 1103, nil
end

function NetEquipCollectCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1103, "EquipCollect")

    local data = idnums_pb.IdNums()
    data:ParseFromString(fd.rbuf)

    gamedata:EquipCollect(data)

    return { type = 1103, equipcollect = gamedata.cache.equipcollect}
end

function UITeamRecomQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3910, "TeamRecomQuery")

    return 1, 3910, nil
end

function NetTeamRecomQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3910, "TeamRecomQuery")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata:TeamRecomQuery(ids)

    return { type = 3910, teamRecomQuery = gamedata.cache.teamRecomQuery}
end

function UITeamRecomRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3911, "TeamRecomReward")
    if uireq.id then -- 第几个箱子
        local SignInData = ids_pb.Ids()
        table.insert(SignInData.ids, uireq.id)
        gamedata.ext.teamRecomRewardId = uireq.id
        return 1,  3911, SignInData:SerializeToString()
    else
        return 0, 3911, nil
    end
end

function NetTeamRecomRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3911, "TeamRecomReward")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    for k,v in pairs(gamedata.cache.teamRecomQuery) do
        if tonumber(k) == gamedata.ext.teamRecomRewardId then
            gamedata.cache.teamRecomQuery[k] = 2
        end
    end

    return { type = 3911, reward = gamedata:SomethingProcess(SomeThings), teamRecomQuery = gamedata.cache.teamRecomQuery}
end