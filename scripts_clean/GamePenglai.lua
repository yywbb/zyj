--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/4
-- Time: 上午10:37
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local penglai_pb = require("penglai_pb")
local penglairesult_pb = require("penglairesult_pb")
local players_pb = require("players_pb")
local battleresult_pb = require("battleresult_pb")

function UIPenglaiCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2040, "Penglai")

    if next(gamedata.cache.penglai) ~= nil then
        return 0, 2040, { type = 2040, penglai = gamedata.cache.penglai }
    else
        return 1, 2040, nil
    end
end

function NetPenglaiCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2040, "Penglai")
    local penglaiData = penglai_pb.Penglai()
    penglaiData:ParseFromString(fd.rbuf)

    gamedata:Penglai(penglaiData)

    return { type = 2040, penglai = gamedata.cache.penglai }
end

---------------------------------------------------------------------------------------

function UIPenglaiSelectDifficultyCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2041, "PenglaiSelectDifficulty")
    local PenglaiSelectDifficultyData = ids_pb.Ids()

    table.insert(PenglaiSelectDifficultyData.ids, uireq.difficulty)

    return 1, 2041, PenglaiSelectDifficultyData:SerializeToString()
end

function NetPenglaiSelectDifficultyCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2041, "PenglaiSelectDifficulty")

    local penglaiData = penglai_pb.Penglai()
    penglaiData:ParseFromString(fd.rbuf)

    gamedata:Penglai(penglaiData)

    return { type = 2041, penglai = gamedata.cache.penglai,}
end


---------------------------------------------------------------------------------------

function UIPenglaiSearchCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2042, "PenglaiSearch")
    local PenglaiSearchData = ids_pb.Ids()

    if uireq.method then
        table.insert(PenglaiSearchData.ids, uireq.method)
        return 1, 2042, PenglaiSearchData:SerializeToString()
    else
        return 1, 2042, nil
    end
end

function NetPenglaiSearchCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2042, "PenglaiSearch")

    local penglaiData = penglairesult_pb.PengLaiResult()
    penglaiData:ParseFromString(fd.rbuf)

    local result = {}

    result.dice = penglaiData.dice
    gamedata.cache.penglai.pos  = gamedata.cache.penglai.pos + penglaiData.dice

    result.point = penglaiData.point
    gamedata.cache.penglai.point  = gamedata.cache.penglai.point + penglaiData.point
    gamedata.cache.penglai.pointtotal  = gamedata.cache.penglai.pointtotal + penglaiData.point

    local needadd = false
    if penglaiData.next and penglaiData.next ~= 0 then
        needadd = true
        gamedata.cache.penglai.presection = gamedata.cache.penglai.nowsection
        gamedata.cache.penglai.nowsection = gamedata.cache.penglai.nextsection
        gamedata.cache.penglai.nextsection = penglaiData.next
    end

    if penglaiData.enemy and next(penglaiData.enemy) then
        result.enemy = gamedata:playerwithgeneralsdata(penglaiData.enemy)
    end

    if penglaiData.result and next(penglaiData.result) then
        result.reward = gamedata:SomethingProcess(penglaiData.result)
    end

    local posinsection = math.mod(gamedata.cache.penglai.pos,34)
    if gamedata.cache.penglai.pos>0 and posinsection == 0 then posinsection = 34 end

    local nowtype = gamedata.config.penglai[tostring(gamedata.cache.penglai.nowsection)][tostring(posinsection)].type

    if nowtype == "boss" or nowtype == "monster" or nowtype == "player" then
        gamedata.cache.penglai.status = false
    else
        gamedata.cache.penglai.status = true
    end

    return { type = 2042, penglai = gamedata.cache.penglai, result =result, needadd = needadd}
end

---------------------------------------------------------------------------------------

function UIPenglaiBattleCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2043, "PenglaiBattle")

    local PenglaiBattleData = ids_pb.Ids()
    table.insert(PenglaiBattleData.ids, uireq.method)

    return 1, 2043, PenglaiBattleData:SerializeToString()
end

function NetPenglaiBattleCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2043, "PenglaiBattle")

    local PenglaiBattleData = battleresult_pb.BattleResult()
    PenglaiBattleData:ParseFromString(fd.rbuf)

    if PenglaiBattleData.point and PenglaiBattleData.point ~= 0 then
        gamedata.cache.penglai.point  = gamedata.cache.penglai.point + PenglaiBattleData.point
        gamedata.cache.penglai.pointtotal  = gamedata.cache.penglai.pointtotal + PenglaiBattleData.point
    end



    local t = {
        type = 2043,
        penglai = gamedata.cache.penglai,
        result =PenglaiBattleData.result,
        reward = gamedata:SomethingProcess(PenglaiBattleData.reward),
    }
    gamedata.cache.penglai.status = true
    if PenglaiBattleData.result == -1 then

    elseif PenglaiBattleData.result == 0 then
        local posinsection = math.mod(gamedata.cache.penglai.pos,34)
        if gamedata.cache.penglai.pos>0 and posinsection == 0 then posinsection = 34 end
        local nowtype = gamedata.config.penglai[tostring(gamedata.cache.penglai.nowsection)][tostring(posinsection)].type

        if nowtype == "boss" or nowtype == "monster" then
            gamedata.cache.penglai.difficulty = 4
        end

        t.battlereport = PenglaiBattleData.battlereport
    elseif PenglaiBattleData.result == 1 then
        t.battlereport = PenglaiBattleData.battlereport
    end

    return t
end

---------------------------------------------------------------------------------------

function makePlayer(data)
    local palyers ={}
    for k,v in ipairs(data) do

        table.insert(palyers,gamedata:playerdata(v))
    end

    gamedata.sortData(palyers, "param")

    return palyers
end

function UIPenglaiRankCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2044, "PenglaiRank")

    return 1, 2044, nil
end

function NetPenglaiRankCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2044, "PenglaiRank")

    local PenglaiRankData = players_pb.Players()
    PenglaiRankData:ParseFromString(fd.rbuf)


    return {type = 2044,  players = makePlayer(PenglaiRankData.players)}
end

---------------------------------------------------------------------------------------

function UIPenglaiTodayRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2045, "PenglaiTodayReward")

    return 1, 2045, nil
end

function NetPenglaiTodayRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2045, "PenglaiTodayReward")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    gamedata.cache.penglai.difficulty = 5
    return {type = 2045,  reward = gamedata:SomethingProcess(SomeThings), penglai = gamedata.cache.penglai}
end

---------------------------------------------------------------------------------------

function UIPenglaiTotalCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2046, "PenglaiTotal")

    return 1, 2046, nil
end

function NetPenglaiTotalCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2046, "PenglaiTotal")
    local PenglaiTotalData = ids_pb.Ids()
    PenglaiTotalData:ParseFromString(fd.rbuf)

    local totalpoint = 0
    local status = {}
    for k, v in ipairs(PenglaiTotalData.ids) do
        if k == 1 then
            totalpoint = v
        else
            table.insert(status,v)
        end
    end

    return {type = 2046, totalpoint=totalpoint, status = status}
end

---------------------------------------------------------------------------------------

function UIPenglaiTotalRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2047, "PenglaiTotalReward")
    local PenglaiTotalRewardData = ids_pb.Ids()

    table.insert(PenglaiTotalRewardData.ids, uireq.id)
    gamedata.ext.penglaitotalrewardid = uireq.id

    return 1, 2047, PenglaiTotalRewardData:SerializeToString()
end

function NetPenglaiTotalRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2047, "PenglaiTotalReward")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    return { type = 2047, id= gamedata.ext.penglaitotalrewardid, reward = gamedata:SomethingProcess(SomeThings)}
end

---------------------------------------------------------------------------------------

function UIPenglaiTaskCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2048, "PenglaiTask")

    return 1, 2048, nil
end

function NetPenglaiTaskCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2048, "PenglaiTask")
    local PenglaiTotalData = ids_pb.Ids()
    PenglaiTotalData:ParseFromString(fd.rbuf)

    local status = {}
    for k,v in ipairs(PenglaiTotalData.ids) do
        if k<=6 then
            table.insert(status,{num = v})
        else
            status[k-6].status = v
        end
    end

    return {type = 2048, status = status }
end

---------------------------------------------------------------------------------------

function UIPenglaiTaskRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2049, "PenglaiTask")
    local PenglaiTotalRewardData = ids_pb.Ids()
    table.insert(PenglaiTotalRewardData.ids, uireq.id)

    gamedata.ext.penglaitotalrewardid = uireq.id
    gamedata.ext.penglaitaskrewardid = uireq.id

    return 1, 2049, PenglaiTotalRewardData:SerializeToString()
end

function NetPenglaiTaskRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2049, "PenglaiTask")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    return { type = 2049,id= gamedata.ext.penglaitaskrewardid, reward = gamedata:SomethingProcess(SomeThings)}
end