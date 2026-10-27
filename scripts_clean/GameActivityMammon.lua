--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/27
-- Time: 下午2:47
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local params_pb = require("params_pb")

function UIActivityMammonQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2015, "ActivityMammonQuery")

    if next(gamedata.cache.mammon) ~= nil then
        return 0, 2015, { type = 2015, status = gamedata.cache.mammon , gold = gamedata.cache.role.gold}
    else
        return 1, 2015, nil
    end

end

function NetActivityMammonQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2015, "ActivityMammonQuery")
    local mammonData = ids_pb.Ids()
    mammonData:ParseFromString(fd.rbuf)

    gamedata:Mammon(mammonData)

    return { type = 2015, status = gamedata.cache.mammon,gold = gamedata.cache.role.gold }
end

function UIActivityMammonCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2016, "ActivityMammon")

    if gamedata.cache.mammon[1] > table.getTableLength(gamedata.config.mammon) then
        return 0, 503, {type = 503, msg = "次数已用完" }
    elseif gamedata.cache.role.gold < gamedata.config.mammon[tostring(gamedata.cache.mammon[1])].gold then
        return 0, 503, {type = 503, msgtype = "shortgold" }
    else
        return 1, 2016, nil
    end

end

function NetActivityMammonCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2016, "ActivityMammon")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    local reward = gamedata:SomethingProcess(SomeThings)
    reward[1].num = reward[1].num + gamedata.config.mammon[tostring(gamedata.cache.mammon[1])].gold

    gamedata.cache.mammon[1] = gamedata.cache.mammon[1] +1

    return {
        type = 2016,
        status = gamedata.cache.mammon,
        reward =  reward,
        gold = gamedata.cache.role.gold
    }
end


function UIActivityMammonBroadCastCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2017, "ActivityMammonBroadCast")

    return 1, 2017, nil
end

function NetActivityMammonBroadCastCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2017, "ActivityMammonBroadCast")
    local broadcast = params_pb.ParamS()
    broadcast:ParseFromString(fd.rbuf)

    local data = {}
    for k,v in ipairs(broadcast.params) do
        table.insert(data,"恭喜"..v.s..",迎财神获得"..v.i.."元宝！")
    end


    return {
        type = 2017,
        data = data,
    }
end







function UIActivityMammonQueryCallBack2(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3790, "ActivityMammonQuery")

    --if next(gamedata.cache.mammon2) ~= nil then
    --    return 0, 3790, { type = 3790, status = gamedata.cache.mammon2 , gold = gamedata.cache.role.gold}
    --else
        return 1, 3790, nil
    --end

end

function NetActivityMammonQueryCallBack2(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3790, "ActivityMammonQuery")
    local mammonData2 = ids_pb.Ids()
    mammonData2:ParseFromString(fd.rbuf)

    gamedata:Mammon2(mammonData2)

    return { type = 3790, status = gamedata.cache.mammon2,gold = gamedata.cache.role.gold }
end

function UIActivityMammonCallBack2(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3791, "ActivityMammon")

    if gamedata.cache.mammon2[1] > table.getTableLength(gamedata.config.mammon1) then
        return 0, 503, {type = 503, msg = "次数已用完" }
    elseif gamedata.cache.role.gold < gamedata.config.mammon1[tostring(gamedata.cache.mammon2[1])].gold then
        return 0, 503, {type = 503, msgtype = "shortgold" }
    else
        return 1, 3791, nil
    end

end

function NetActivityMammonCallBack2(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3791, "ActivityMammon")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    local reward = gamedata:SomethingProcess(SomeThings)

    reward[1].num = reward[1].num + gamedata.config.mammon1[tostring(gamedata.cache.mammon2[1])].gold

    gamedata.cache.mammon2[1] = gamedata.cache.mammon2[1] +1

    return {
        type = 3791,
        status = gamedata.cache.mammon2,
        reward =  reward,
        gold = gamedata.cache.role.gold
    }
end


function UIActivityMammonBroadCastCallBack2(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3792, "ActivityMammonBroadCast")

    return 1, 3792, nil
end

function NetActivityMammonBroadCastCallBack2(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3792, "ActivityMammonBroadCast")
    local broadcast = params_pb.ParamS()
    broadcast:ParseFromString(fd.rbuf)

    local data = {}
    for k,v in ipairs(broadcast.params) do
        table.insert(data,"恭喜"..v.s..",迎财神获得"..v.i.."元宝！")
    end


    return {
        type = 3792,
        data = data,
    }
end