
--与海外版有差异，国内版名将副本没有通关宝箱

local battleresult_pb = require("battleresult_pb")
local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local combmessages_pb = require("combmessages_pb")
require"PickBattleResultReport"

function UIGeneralCopyQueryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1350, "GeneralCopyQuery")
    return 1, 1350, nil
end

function NetGeneralCopyQueryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1350, "GeneralCopyQuery")
    local PointData = combmessages_pb.CombMessages()
    PointData:ParseFromString(fd.rbuf)

--    gamedata.cache.starcopy = {
--        attacknum = 0,
--        sections = {},
--    }

    for k,v in ipairs(PointData.messages) do

        if v.id == 0 then
            local  ids = ids_pb.Ids();
            ids:ParseFromString(v.data)
            gamedata.cache.starcopy.attacknum = ids.ids[1] or 0
        else
            local  ids = ids_pb.Ids();
            ids:ParseFromString(v.data)
            gamedata:StarCopyMapData(ids.ids)
        end
    end

    return { type = 1350, starcopy = gamedata.cache.starcopy,}
end

function UIGeneralCopyAttackCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1351, "GeneralCopyAttack")
    local Data = ids_pb.Ids()
    if uireq.mapid and uireq.pointid then
        table.insert(Data.ids,uireq.mapid)
        table.insert(Data.ids,uireq.pointid)
    end

    gamedata.ext.copystarPointstatus = uireq.pointstatus or 0

    return 1, 1351, Data:SerializeToString()
end

function NetGeneralCopyAttackCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1351, "GeneralCopyAttack")
    local ResultPb = battleresult_pb.BattleResult()
    ResultPb:ParseFromString(fd.rbuf)
    local reward = gamedata:SomethingProcess(ResultPb.reward)
    local reward1 = {}
    local reward2 = {}
    for k,v in pairs(reward) do
        if gamedata.ext.copystarPointstatus and gamedata.ext.copystarPointstatus == -1 and v.cid == 1001 then
            table.insert(reward2,v)
        else
            table.insert(reward1,v)
        end
    end

    local t = {
        type = 1351,
        reward = reward1,
        firstreward = reward2,
        battlereport = PickBattleResultReport(ResultPb),
        result = ResultPb.result,
    }
    return t
end

function UIGeneralCopyGetBoxCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1352, "GeneralCopyGetBox")
    if uireq.mapid and uireq.pointid then
        local Data = ids_pb.Ids()
        table.insert(Data.ids,uireq.mapid)
        table.insert(Data.ids,uireq.pointid)

        gamedata.ext.starcopybox = {}
        gamedata.ext.starcopybox.mapid = uireq.mapid
        gamedata.ext.starcopybox.pointid = uireq.pointid

        return 1, 1352, Data:SerializeToString()
    end
end

function NetGeneralCopyGetBoxCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1352, "GeneralCopyGetBox")
    local ResultPb = somethings_pb.SomeThings()
    ResultPb:ParseFromString(fd.rbuf)

    for k,v in pairs(gamedata.cache.starcopy.sections) do
        for k1,v1 in pairs(v) do
            if v1.mapid == gamedata.ext.starcopybox.mapid then
               if v1.points[tostring(gamedata.ext.starcopybox.pointid)] and v1.points[tostring(gamedata.ext.starcopybox.pointid)].boxstatus then
                   gamedata.cache.starcopy.sections[k][k1].points[tostring(gamedata.ext.starcopybox.pointid)].boxstatus = 2
               end
            end
        end
    end

    local t = {
        type = 1352,
        reward = gamedata:SomethingProcess(ResultPb),
        starcopy = gamedata.cache.starcopy,
    }
    return t
end


--hades
function UIHadesCopyQueryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1370, "HadesCopyQuery")
    return 1, 1370, nil
end

function NetHadesCopyQueryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1370, "HadesCopyQuery")
    local PointData = combmessages_pb.CombMessages()
    PointData:ParseFromString(fd.rbuf)

    for k,v in ipairs(PointData.messages) do

        if v.id == 0 then
            local  ids = ids_pb.Ids();
            ids:ParseFromString(v.data)
            gamedata.cache.hadescopy.attacknum = ids.ids[1] or 0
        else
            local  ids = ids_pb.Ids();
            ids:ParseFromString(v.data)
            gamedata:HadesCopyMapData(ids.ids)
        end
    end

    return { type = 1370, hadescopy = gamedata.cache.hadescopy,}
end

function UIHadesCopyAttackCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1371, "HadesCopyAttack")
    local Data = ids_pb.Ids()
    if uireq.mapid and uireq.pointid then
        table.insert(Data.ids,uireq.mapid)
        table.insert(Data.ids,uireq.pointid)
    end

    gamedata.ext.hadesCopyAttackParams = uireq
    gamedata.ext.copyhadesPointstatus = uireq.pointstatus or 0

    return 1, 1371, Data:SerializeToString()
end

function NetHadesCopyAttackCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1371, "HadesCopyAttack")
    local ResultPb = battleresult_pb.BattleResult()
    ResultPb:ParseFromString(fd.rbuf)
    local reward = gamedata:SomethingProcess(ResultPb.reward)

    local t = {
        type = 1371,
        reward = reward,
        battlereport = PickBattleResultReport(ResultPb),
        result = ResultPb.result,
        skip = 0,
        params = gamedata.ext.hadesCopyAttackParams,
    }

    local power = gamedata.config.hades_copy[tostring(gamedata.ext.hadesCopyAttackParams.mapid)][tostring(gamedata.ext.hadesCopyAttackParams.pointid)].power
    if power < gamedata.cache.role.power*0.75 then
        t.skip = 1
    end

    return t
end

function UIHadesCopyGetBoxCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1372, "HadesCopyGetBox")
    if uireq.mapid then
        local Data = ids_pb.Ids()
        table.insert(Data.ids,uireq.mapid)

        return 1, 1372, Data:SerializeToString()
    end
end

function NetHadesCopyGetBoxCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1372, "HadesCopyGetBox")
    local ResultPb = somethings_pb.SomeThings()
    ResultPb:ParseFromString(fd.rbuf)


    local t = {
        type = 1372,
        reward = gamedata:SomethingProcess(ResultPb),
    }
    return t
end


