--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/6
-- Time: 下午12:01
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local cupstatus_pb = require("cupstatus_pb")
local somethings_pb = require("somethings_pb")
local battleresult_pb = require("battleresult_pb")
local cuptops_pb = require("cuptops_pb") --CupTops
local result_pb = require("result_pb")
local combmessages_pb = require("combmessages_pb")

local function makeStatus()
    local status = table.copy(gamedata.cache.cup.status)
    local battles = {}
    for k,v in pairs(status.battles) do
        table.insert(battles,v)
    end
    gamedata.sortData(battles, "result", "reward", "round", nil,nil,nil,true,true)
    status.battles =  battles
    return status
end

function UICupStatusCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2100, "CupStatus")
    local CupStatusData = ids_pb.Ids()

    if gamedata.cache.cup.status.battles then
        table.insert(CupStatusData.ids, table.getTableLength(gamedata.cache.cup.status.battles))
    else
        table.insert(CupStatusData.ids, 0)
    end

    return 1, 2100, CupStatusData:SerializeToString()
end

function NetCupStatusCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2100, "CupStatus")

   local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)
    local reward = {}
    local rewardNum = 1
    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            rewardNum = ids.ids[1] or 1
        elseif v.id == 1 then
            local CupStatusData = cupstatus_pb.CupStatus()
            CupStatusData:ParseFromString(v.data)
            gamedata:CupStatus(CupStatusData)
        end
    end

    return { type = 2100,cupstatus = makeStatus(),rewardNum = rewardNum}
end

-------------------------------------------------------------------------------------------------

function UICupJoinTomorrowCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2101, "CupJoinTomorrow")

   local nowtime = os.date("*t",gamedata:time())
    if nowtime.hour < 9 then
        return 0,503,{type = 503, msg = "报名时间未到,请9点后再来"}
    end

    return 1, 2101, nil
end

function NetCupJoinTomorrowCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2101, "CupJoinTomorrow")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local reward = {}

    for k,v in ipairs(datas.messages) do
        if v.id == 1 then
            local CupJoinTomorrowData = result_pb.Result()
            CupJoinTomorrowData:ParseFromString(v.data)
            if  CupJoinTomorrowData.result then
                gamedata.cache.cup.status.tomorrow = 1
            end
        elseif v.id == 2 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
        end
    end


    return { type = 2101,cupstatus = makeStatus(),reward = reward}
end

-------------------------------------------------------------------------------------------------

local function maketopsdata()
    local data = {[8] = {}, [4]= {}, [2]= {} }

    local bet = 0

    local allsee8 = true
    local allsee4 = true

    for k,v in pairs(gamedata.cache.cup.topbattles) do
        print(v.round,v.see,"maketopsdata")
        if v.round == 10 then
            table.insert(data[8],v)
            if not v.see then
                allsee8 = false
            end
        elseif v.round == 11 then
            table.insert(data[4],v)
            if not v.see then
                allsee4 = false
            end
        elseif v.round == 12 then
            table.insert(data[2],v)
        end
        if v.bet ~= -1 then bet = bet +1 end
    end

    local sortbyID= function(a,b) return a.id < b.id end
    table.sort(data[8],sortbyID)

    if not allsee8 then data[4] = {} end
    if not allsee4 then data[2] = {} end

    return data,bet
end

local updatetime = {
    {hour= 12,min = 0, },
    {hour= 14,min = 0, },
    {hour= 16,min = 0, },
    {hour= 19,min = 0, },
}
local recivetime = {hour= 0,min = 0, }

local function findneedupdate(recivet,nowtime)
    if not gamedata.cache.cup.recivetime then gamedata.cache.cup.recivetime = {hour= 0,min = 0,} end

    local recivet = gamedata.cache.cup.recivetime
    for k,v in ipairs(updatetime) do
        if recivet.hour < v.hour and nowtime.hour>= v.hour then
            recivet.hour = nowtime.hour
            return true
        end
    end
    return false
end

function UICupTopCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2102, "CupTop")

    local nowtime = os.date("*t", gamedata:time())

    if nowtime.hour < 12 or not findneedupdate(recivetime,nowtime) then
        local cuptopbattles, betnum = maketopsdata()
        return 0,2102,{type = 2102, cuptopbattles = cuptopbattles,betnum = betnum }
    else
        print(nowtime.hour)
        local CupTopData = ids_pb.Ids()

--        if table.getTableLength(gamedata.cache.cup.topbattles) >=7 then
--            local cuptopbattles, betnum = maketopsdata()
--            return 0,2102,{type = 2102, cuptopbattles = cuptopbattles,betnum = betnum }
--        end

        --if table.getTableLength(gamedata.cache.cup.topbattles) <7 then
            table.insert(CupTopData.ids, 2)
        --end
        --if table.getTableLength(gamedata.cache.cup.topbattles) <6 then
            table.insert(CupTopData.ids, 4)
        --end
        --if table.getTableLength(gamedata.cache.cup.topbattles) <4 then
            table.insert(CupTopData.ids, 8)
        --end
        return 1, 2102, CupTopData:SerializeToString()
    end
end

function NetCupTopCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2102, "CupTop")

    local CupTopData = cuptops_pb.CupTops()
    CupTopData:ParseFromString(fd.rbuf)

    gamedata:CupTops(CupTopData)

    local cuptopbattles, betnum = maketopsdata()

    return { type = 2102,cuptopbattles = cuptopbattles,betnum = betnum}
end

function UICupTopSeeCallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from gameserver", 21021, "CupTopSee")
    if uireq.id then
        gamedata.cache.cup.topbattles[uireq.id].see = true
    elseif uireq.round then
        for k,v in pairs(gamedata.cache.cup.topbattles) do
            if v.round == uireq.round then
                v.see = true
            end
        end
    end

    local cuptopbattles, betnum = maketopsdata()

    return 0, 21021,{ type = 21021,cuptopbattles = cuptopbattles,betnum = betnum, onebattle = gamedata.cache.cup.topbattles[uireq.id or 0]}
end

-------------------------------------------------------------------------------------------------

function UICupBattlePlayCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2103, "CupBattlePlay")
    local CupBattlePlayData = ids_pb.Ids()
    table.insert(CupBattlePlayData.ids, uireq.round)
    table.insert(CupBattlePlayData.ids, uireq.id)

    gamedata.ext.CupBattlePlayround = uireq.round
    gamedata.ext.CupBattlePlayid = uireq.id
    gamedata.ext.CupBattlePlayisself = uireq.isself

    return 1, 2103, CupBattlePlayData:SerializeToString()
end

function NetCupBattlePlayCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2103, "CupBattlePlay")

    local CupBattlePlayData = battleresult_pb.BattleResult()
    CupBattlePlayData:ParseFromString(fd.rbuf)

    local t = {
        type = 2103,
        result = CupBattlePlayData.result,
        battlereport = CupBattlePlayData.battlereport,
        round = gamedata.ext.CupBattlePlayround
    }

    if gamedata.ext.CupBattlePlayisself then
        if gamedata.cache.cup.status.battles[gamedata.ext.CupBattlePlayround].result ==1 then
            t.winner = {name=gamedata.cache.role.name,level = gamedata.cache.role.level }
        else
            t.winner = {
                name = gamedata.cache.cup.status.battles[gamedata.ext.CupBattlePlayround].enemy.name,
                level = gamedata.cache.cup.status.battles[gamedata.ext.CupBattlePlayround].enemy.level
            }
        end
    else

        if gamedata.cache.cup.topbattles[gamedata.ext.CupBattlePlayid].status ==1 then
            t.winner = {
                name = gamedata.cache.cup.topbattles[gamedata.ext.CupBattlePlayid].a.name,
                level = gamedata.cache.cup.topbattles[gamedata.ext.CupBattlePlayid].a.level
            }
        else
            t.winner = {
                name = gamedata.cache.cup.topbattles[gamedata.ext.CupBattlePlayid].b.name,
                level = gamedata.cache.cup.topbattles[gamedata.ext.CupBattlePlayid].b.level
            }
        end
    end
    return t
end

-------------------------------------------------------------------------------------------------

function UICupBattleRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2104, "CupBattleReward")
    local CupBattleRewardData = ids_pb.Ids()

    table.insert(CupBattleRewardData.ids, uireq.round)
    table.insert(CupBattleRewardData.ids, uireq.id)

    gamedata.ext.CupBattleRewardround = uireq.round

    return 1, 2104, CupBattleRewardData:SerializeToString()
end

function NetCupBattleRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2104, "CupBattleReward")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    gamedata.cache.cup.status.battles[gamedata.ext.CupBattleRewardround].reward = 1

    return { type = 2104, reward = gamedata:SomethingProcess(SomeThings),cupstatus = makeStatus(), }
end

-------------------------------------------------------------------------------------------------

function UICupBattleRewardallCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2106, "CupBattleRewardall")
    local CupBattleRewardData = ids_pb.Ids()

    return 1, 2106, nil
end

function NetCupBattleRewardallCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2106, "CupBattleRewardall")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    for k,v in pairs(gamedata.cache.cup.status.battles) do
        if v.result ==1 and v.reward == 0 then
            v.reward = 1
        end
    end

    return { type = 2106, reward = gamedata:SomethingProcess(SomeThings),cupstatus = makeStatus(), }
end

-------------------------------------------------------------------------------------------------

function UICupBattleBetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2105, "CupBattleBet")
    local CupBattleBetData = ids_pb.Ids()

    table.insert(CupBattleBetData.ids, uireq.round)
    table.insert(CupBattleBetData.ids, uireq.id)
    table.insert(CupBattleBetData.ids, uireq.bet)


    gamedata.ext.CupBattlebet = {round = uireq.round, id = uireq.id, bet = uireq.bet,curlevel =uireq.curLevel }

    return 1, 2105, CupBattleBetData:SerializeToString()
end

function NetCupBattleBetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2105, "CupBattleBet")

    local CupBattleBetData = result_pb.Result()
    CupBattleBetData:ParseFromString(fd.rbuf)

    if CupBattleBetData.result then
        gamedata.cache.cup.topbattles[gamedata.ext.CupBattlebet.id].bet = gamedata.ext.CupBattlebet.bet
    end

    if gamedata.config.cup_bet_consume and gamedata.config.cup_bet_consume[tostring(gamedata.ext.CupBattlebet.curlevel)]["consume"..(gamedata.ext.CupBattlebet.round-9)] then
        local cid,num = gamedata.getIDandNUM(gamedata.config.cup_bet_consume[tostring(gamedata.ext.CupBattlebet.curlevel)]["consume"..(gamedata.ext.CupBattlebet.round-9)])
        if cid == 1000 then
            gamedata:updateRoleCoin(0-num)
        elseif cid == 1001 then
            gamedata:updateRoleGold(0-num,"杯赛下注",1)
        else
            gamedata:updateprops({cid = cid, num=0-num})
        end
    end

    local cuptopbattles, betnum = maketopsdata()

    return { type = 2105,cuptopbattles = cuptopbattles,betnum = betnum,onebattle = gamedata.cache.cup.topbattles[gamedata.ext.CupBattlebet.id]}
end

--
local combmessages_pb = require("combmessages_pb")
local players_pb = require("players_pb")

function UICupRankCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2107, "CupRank")

    return 1, 2107, nil
end

function NetCupRankCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2107, "CupRank")
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)
    local mypoint = 0
    local number = 0
    local players = {}
    for k,v in ipairs(datas.messages) do
        if v.id==0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            mypoint = ids.ids[1] or 0
            number = ids.ids[2] or 0
        elseif v.id==1 then
            local playersData = players_pb.Players()
            playersData:ParseFromString(v.data)
            players = gamedata:players(playersData.players)
        end
    end

    return { type = 2107, rankdata = {mypoint = mypoint, number = number, ranks = players}}
end