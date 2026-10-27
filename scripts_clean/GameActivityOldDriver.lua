--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/5/29
-- Time: 17:21
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")

function UIOldDriverQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1404, "olddriver")

    return 1, 1404, nil
end

function NetOldDriverQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1404, "olddriver")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata:ActivityOldDriver(ids)

    return { type = 1404, data = gamedata.cache.activityOldDriver or {}}
end


function UIOldDriverOptCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1405, "OldDriver")
    local doData = ids_pb.Ids()

    if uireq.need and tonumber(uireq.need["cid"]) == 1001 and gamedata.cache.role.gold < tonumber(uireq.need["num"]) then
        return  0, 503, {type = 503, msgtype = "shortgold"}
    elseif uireq.need and tonumber(uireq.need["cid"]) == 1000 and gamedata.cache.role.coin < tonumber(uireq.need["num"]) then
        --return  0, 503, {type = 503, msg = "银币不足"}
        return  0, 503, {type = 503, msgtype = "shortcoin"}
    else
        table.insert(doData.ids,uireq.pos)
        gamedata.ext.oldDriverOpt = uireq

        return 1, 1405, doData:SerializeToString()
    end
end

function NetOldDriverOptCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1405, "OldDriver")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    if gamedata.ext.oldDriverOpt.need and tonumber(gamedata.ext.oldDriverOpt.need["cid"]) == 1001 then
        gamedata:updateRoleGold(0-tonumber(gamedata.ext.oldDriverOpt.need["num"]),"老司机购买"..gamedata.ext.oldDriverOpt.pos,1)
    elseif gamedata.ext.oldDriverOpt.need and tonumber(gamedata.ext.oldDriverOpt.need["cid"]) == 1000 then
        gamedata:updateRoleCoin(0-tonumber(gamedata.ext.oldDriverOpt.need["num"]))
    end

    return { type = 1405, reward = gamedata:SomethingProcess(getData), pos = gamedata.ext.oldDriverOpt.pos or 1}
end


--cp
function UICPOldDriverQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5032, "olddriver")

    return 1, 5032, nil
end

function NetCPOldDriverQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5032, "olddriver")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local cpnum = ids.ids[1] or 0
    local cpday = ids.ids[2] or 0

    gamedata.cache.activityOldDriver.itemsdata = {}
    gamedata.cache.activityOldDriver.buystatus = ids.ids[3] or 0
    for i=4,13,1 do
        local order = ids.ids[i] or 0
        if order == 1 then order = -1 end
        table.insert(gamedata.cache.activityOldDriver.itemsdata,{id = i-3, status = ids.ids[i] or 0, num = ids.ids[i+10] or 0, order = order})
    end
    gamedata.sortData(gamedata.cache.activityOldDriver.itemsdata, "order","id",nil,nil,nil,nil,true,true)

    return { type = 5032, data = gamedata.cache.activityOldDriver or {}, cpnum = cpnum, cpday = cpday}
end


function UICPOldDriverOptCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5033, "OldDriver")
    local doData = ids_pb.Ids()

    if uireq.need and tonumber(uireq.need["cid"]) == 1001 and gamedata.cache.role.gold < tonumber(uireq.need["num"]) then
        return  0, 503, {type = 503, msgtype = "shortgold"}
    elseif uireq.need and tonumber(uireq.need["cid"]) == 1000 and gamedata.cache.role.coin < tonumber(uireq.need["num"]) then
        --return  0, 503, {type = 503, msg = "银币不足"}
        return  0, 503, {type = 503, msgtype = "shortcoin"}
    else
        table.insert(doData.ids,uireq.pos)
        gamedata.ext.oldDriverOpt = uireq

        return 1, 5033, doData:SerializeToString()
    end
end

function NetCPOldDriverOptCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5033, "OldDriver")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    if gamedata.ext.oldDriverOpt.need and tonumber(gamedata.ext.oldDriverOpt.need["cid"]) == 1001 then
        gamedata:updateRoleGold(0-tonumber(gamedata.ext.oldDriverOpt.need["num"]),"老司机购买"..gamedata.ext.oldDriverOpt.pos,1)
    elseif gamedata.ext.oldDriverOpt.need and tonumber(gamedata.ext.oldDriverOpt.need["cid"]) == 1000 then
        gamedata:updateRoleCoin(0-tonumber(gamedata.ext.oldDriverOpt.need["num"]))
    end

    return { type = 5033, reward = gamedata:SomethingProcess(getData), pos = gamedata.ext.oldDriverOpt.pos or 1}
end