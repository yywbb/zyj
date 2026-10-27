--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-24
-- Time: 上午10:32
-- To change this template use File | Settings | File Templates.
--
require"PickBattleResultReport"
local athleticsattack_pb = require("athleticsattack_pb")
function UIAthleticsAttackCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1601, "athleticsattack")
    local AthleticsAttack = athleticsattack_pb.AthleticsAttack()
    AthleticsAttack.rank = uireq.rank.rank

    gamedata.ext.athleticsattack = uireq.rank


    return 1, 1601, AthleticsAttack:SerializeToString()

end

local battleresult_pb = require("battleresult_pb")
function NetAthleticsAttackCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1601, "athleticsattack")
    local copyAttackResultPb = battleresult_pb.BattleResult()
    copyAttackResultPb:ParseFromString(fd.rbuf)

    local t = {
        type = 1601,
        result = copyAttackResultPb.result,
        reward = gamedata:SomethingProcess(copyAttackResultPb.reward),
        battlereport = PickBattleResultReport(copyAttackResultPb),

    }

    if copyAttackResultPb.result ==1 then
        for k,v in pairs(gamedata.cache.athletics.rewardlist) do
             if v.status == 1 and gamedata.ext.athleticsattack.rank <= gamedata.config.athletics_rewards2[tostring(v.id)].rank then
                 gamedata.cache.athletics.rewardlist[v.id].status = 2
             end
        end
    end

    t.vs_b = {
        name = gamedata.ext.athleticsattack.name,
        level = gamedata.ext.athleticsattack.level,
        profile = gamedata.ext.athleticsattack.icon,
        power = gamedata.ext.athleticsattack.power,
    }

    t.vs_a = {
        name = gamedata.cache.role.name,
        level = gamedata.cache.role.level,
        profile = gamedata.cache.role.profile,
        power = gamedata.cache.role.power,
    }

    return t
end

----------------------------------------------------------------------------------
---------------------------          BOSS           ------------------------------
----------------------------------------------------------------------------------

function UIAthleticsBossCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1606, "AthleticsBoss")

    if gamedata.cache.vipstatus.athletics_boss >=5 then
        return  0, 503, {type = 503, msg="今日次数已用完"}
    else
        return 1, 1606, nil
    end

end

local battleresult_pb = require("battleresult_pb")
function NetAthleticsBossCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1606, "AthleticsBoss")
    local copyAttackResultPb = battleresult_pb.BattleResult()
    copyAttackResultPb:ParseFromString(fd.rbuf)

    local t = {
        type = 1606,
        result = copyAttackResultPb.result,
        reward = gamedata:SomethingProcess(copyAttackResultPb.reward),
        battlereport = PickBattleResultReport(copyAttackResultPb),

    }

    gamedata.cache.vipstatus.athletics_boss = gamedata.cache.vipstatus.athletics_boss +1

    return t
end

----------------------------------------------------------------------------------
---------------------------          CHUMP           -----------------------------
----------------------------------------------------------------------------------


function UIAthleticsChumpCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1605, "AthleticsChump")

    return 1, 1605, nil
end

local battleresult_pb = require("battleresult_pb")
function NetAthleticsChumpCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1605, "AthleticsChump")
    local copyAttackResultPb = battleresult_pb.BattleResult()
    copyAttackResultPb:ParseFromString(fd.rbuf)

    local t = {
        type = 1605,
        result = copyAttackResultPb.result,
        reward = gamedata:SomethingProcess(copyAttackResultPb.reward),
        battlereport = PickBattleResultReport(copyAttackResultPb),

    }

    return t
end

----------------------------------------------------------------------------------
---------------------------          LIST           ------------------------------
----------------------------------------------------------------------------------

local function getPrestige(rank)
    local prestige = 0
    for k,v in pairs(gamedata.config.athletics_rewards) do
        if rank <= tonumber(v.rank) then
            if v.prestige > prestige then
                prestige = v.prestige
            end
        end
    end

    return prestige
end

local function rankdata(data)

    local rankdata = {
        rank = data.rank,
        name = data.name,
        level = data.level,
        status = data.status,
        rid = data.rid,
        icon = data.heads[1].icon,
        power = data.power or 0,
        prestige = getPrestige(data.rank),
        part_rank = 0,
        part_point = 0,
    }

    if data.params and data.params.params and next(data.params.params) then
        rankdata.params = {}
        for k,v in ipairs(data.params.params) do
            if tonumber(k) == 1 then
                rankdata.part_rank = v.i or 0
            elseif tonumber(k) == 2 then
                rankdata.part_point = v.i or 0
            elseif tonumber(k) == 3 then
                rankdata.iconBox = v.i or gameConfig.defautTitleId
            elseif tonumber(k) == 4 then
                rankdata.title = v.i or gameConfig.defautIconBoxId
            else
                table.insert(rankdata.params,{
                    i = v.i,
                    s = v.s
                })
            end
        end
    end

    return rankdata
end

local function myData(data)

    local myData = {
        prestige = data.my.prestige,
        rank = data.my.rank,
        level = data.my.level,
        athletics = data.my.athletics,
        addprestige = getPrestige(data.my.rank),
        part_rank = 0,
        part_point = 0,
    }

    if data.my.params and data.my.params.params and next(data.my.params.params) then
        myData.params = {}
        for k,v in ipairs(data.my.params.params) do
            if tonumber(k) == 1 then
                myData.part_rank = v.i or 0
            elseif tonumber(k) == 2 then
                myData.part_point = v.i or 0
            else
                table.insert(myData.params,{
                    i = v.i,
                    s = v.s
                })
            end
        end
    end

    return myData
end

local function Athletics(data)
    local myRank = data.my.rank

    local ranklist,top10 = {},{}
    for k,v in ipairs(data.ranks) do

        if v.rank<= 10 then
            table.insert(top10,rankdata(v))
        end
        if (v.rank<= 10 and v.rank >= myRank-5) or v.rank > 10 then
            table.insert(ranklist,rankdata(v))
        end
    end

    local sortByRank = function(a,b) return a.rank < b.rank end
    table.sort(ranklist, sortByRank)
    table.sort(top10, sortByRank)

    return ranklist,top10
end

function UIAthleticsListCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1600, "AthleticsList")

    return 1, 1600, nil

end

local athleticsquery_pb = require("athleticsquery_pb")
function NetAthleticsListCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1600, "AthleticsList")
    local athleticsData = athleticsquery_pb.AthleticsQuery()
    athleticsData:ParseFromString(fd.rbuf)

    --gamedata:Athletics(athleticsData)

    local ranklist,top10 = Athletics(athleticsData)

    return { type = 1600, my = myData(athleticsData),ranklist = ranklist, top10 =top10}
end

----------------------------------------------------------------------------------
---------------------------     RewardExchange      ------------------------------
----------------------------------------------------------------------------------

local athleticsrewardsexchange_pb = require("athleticsrewardsexchange_pb")
function UIAthleticsRewardExchangeCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1604, "athleticsrewardsexchange")
    local athleticsrewardsexchange = athleticsrewardsexchange_pb.AthleticsRewardExchange()
    athleticsrewardsexchange.id = uireq.id

    gamedata.ext.athleticsrewardsexchange = {id = uireq.id}

    return 1, 1604, athleticsrewardsexchange:SerializeToString()


end

local somethings_pb = require("somethings_pb")
function NetAthleticsRewardExchangeCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1604, "athleticsrewardsexchange")
    local athleticsrewardsexchangeresult = somethings_pb.SomeThings()
    athleticsrewardsexchangeresult:ParseFromString(fd.rbuf)

    local t = {
        type = 1604,
        reward = gamedata:SomethingProcess(athleticsrewardsexchangeresult),
    }

    if gamedata.config.athletics_rewards2[tostring(gamedata.ext.athleticsrewardsexchange.id)].buttontype == 2 then
        gamedata.cache.athletics.rewardlist[gamedata.ext.athleticsrewardsexchange.id]=nil
    end


    return t
end

--
--
function UIAthleticsRewardExchange2Callback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1608, "athleticsrewardsexchange")
    local athleticsrewardsexchange = athleticsrewardsexchange_pb.AthleticsRewardExchange()
    athleticsrewardsexchange.id = uireq.id

    return 1, 1608, athleticsrewardsexchange:SerializeToString()

end

function NetAthleticsRewardExchange2Callback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1608, "athleticsrewardsexchange")
    local athleticsrewardsexchangeresult = somethings_pb.SomeThings()
    athleticsrewardsexchangeresult:ParseFromString(fd.rbuf)

    local t = {
        type = 1608,
        reward = gamedata:SomethingProcess(athleticsrewardsexchangeresult),
    }

    return t
end

----------------------------------------------------------------------------------
---------------------------       ewardsQuery       ------------------------------
----------------------------------------------------------------------------------

local function rewarsData()
    local rewards = {}
    for k,v in pairs(gamedata.cache.athletics.rewardlist) do
        table.insert(rewards,v)
    end

    local sortById = function(a,b) return a.id < b.id end
    table.sort(rewards, sortById)
    return rewards
end

function UIAthleticsRewardsQueryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1603, "AthleticsRewardsQuery")
    if next(gamedata.cache.athletics.rewardlist) then
        return 0, 1603, { type = uireq.type, rewards = rewarsData()}
    else
        return 1, 1603, nil
    end

end

local athleticsrewardsquery_pb = require("athleticsrewardsquery_pb")
function NetAthleticsRewardsQueryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1603, "AthleticsRewardsQuery")
    local athleticsrewardData = athleticsrewardsquery_pb.AthleticsRewardQuery()
    athleticsrewardData:ParseFromString(fd.rbuf)

    gamedata:AthleticsRewards(athleticsrewardData)

    return { type = 1603, rewards = rewarsData()}
end

--
--
local status = {}
local function rewarsData2()
    local rewards = {}
    for k,v in pairs(gamedata.config.athletics_rewards2) do
        if v.id+0 < 100 then
            table.insert(rewards,{id = v.id,status = status[v.id+0] or 0,})
        elseif status[v.id-70] and status[v.id-70] > 0 then
            table.insert(rewards,{id = v.id,status = status[v.id-70] or 0,})
        end
    end

    local sortById = function(a,b) return a.id < b.id end
    table.sort(rewards, sortById)
    return rewards
end

function UIAthleticsRewardsQuery2Callback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1607, "AthleticsRewardsQuery")
    if next(gamedata.cache.athletics.rewards) and not uireq.param then
        return 0, 1607, { type = uireq.type, rewards = gamedata.cache.athletics.rewards}
    else
        return 1, 1607, nil
    end
end

local ids_pb = require("ids_pb")
function NetAthleticsRewardsQuery2Callback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1607, "AthleticsRewardsQuery")
    local statusData = ids_pb.Ids()
    statusData:ParseFromString(fd.rbuf)
    status = {}

    for k, v in ipairs(statusData.ids) do
        status[k] = v
    end

    gamedata.cache.athletics.rewards = rewarsData2()
    return { type = 1607, rewards = gamedata.cache.athletics.rewards}
end

-------------------------------1610---------------------------------

function UIAthleticsList2Callback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1610, "AthleticsList")

    return 1, 1610, nil

end

local athleticsquery_pb = require("athleticsquery_pb")
function NetAthleticsList2Callback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1610, "AthleticsList")
    local athleticsData = athleticsquery_pb.AthleticsQuery()
    athleticsData:ParseFromString(fd.rbuf)

    --gamedata:Athletics(athleticsData)

    local ranklist,top10 = Athletics(athleticsData)

    return { type = 1610, my = myData(athleticsData),ranklist = ranklist, top10 =top10, athletics_boss = gamedata.cache.vipstatus.athletics_boss or 0}
end

-------------------------------1611---------------------------------

local athleticsattack_pb = require("athleticsattack_pb")
function UIAthleticsAtta2ckCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1611, "athleticsattack")
    local AthleticsAttack = athleticsattack_pb.AthleticsAttack()
    AthleticsAttack.rank = uireq.rank.rank

    gamedata.ext.athleticsattack = uireq.rank
    gamedata.ext.isFight = uireq.isFight
    

    return 1, 1611, AthleticsAttack:SerializeToString()
end

local battleresult_pb = require("battleresult_pb")

function NetAthleticsAtta2ckCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1611, "athleticsattack")
    local copyAttackResultPb = battleresult_pb.BattleResult()
    copyAttackResultPb:ParseFromString(fd.rbuf)

    local t = {
        type = 1611,
        result = copyAttackResultPb.result,
        reward = gamedata:SomethingProcess(copyAttackResultPb.reward),
        battlereport = PickBattleResultReport(copyAttackResultPb),
        isFight = gamedata.ext.isFight,
    }

    if copyAttackResultPb.result ==1 then
        for k,v in pairs(gamedata.cache.athletics.rewardlist) do
             if v.status == 1 and gamedata.ext.athleticsattack.rank <= gamedata.config.athletics_rewards2[tostring(v.id)].rank then
                 gamedata.cache.athletics.rewardlist[v.id].status = 2
             end
        end
    end

    t.vs_b = {
        name = gamedata.ext.athleticsattack.name,
        level = gamedata.ext.athleticsattack.level,
        profile = gamedata.ext.athleticsattack.icon,
        power = gamedata.ext.athleticsattack.power,
    }

    t.vs_a = {
        name = gamedata.cache.role.name,
        level = gamedata.cache.role.level,
        profile = gamedata.cache.role.profile,
        power = gamedata.cache.role.f_power,
    }

    return t
end

-------------------------------1613---------------------------------

function UIAthleticsRewardsQuery3Callback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1613, "AthleticsRewardsQuery")
    if next(gamedata.cache.athletics.rewards) and not uireq.param then
        return 0, 1613, { type = uireq.type, rewards = gamedata.cache.athletics.rewards}
    else
        return 1, 1613, nil
    end
end

local ids_pb = require("ids_pb")
function NetAthleticsRewardsQuery3Callback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1613, "AthleticsRewardsQuery")
    local statusData = ids_pb.Ids()
    statusData:ParseFromString(fd.rbuf)
    status = {}

    for k, v in ipairs(statusData.ids) do
        status[k] = v
    end

    gamedata.cache.athletics.rewards = rewarsData2()
    return { type = 1613, rewards = gamedata.cache.athletics.rewards}
end

-------------------------------1614---------------------------------

function UIAthleticsRewardExchange3Callback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1614, "athleticsrewardsexchange")
    --local athleticsrewardsexchange = athleticsrewardsexchange_pb.AthleticsRewardExchange()

    --athleticsrewardsexchange.id = uireq.id


    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id)
    table.insert(idsData.ids, uireq.num or 1)

    return 1, 1614, idsData:SerializeToString()

    --return 1, 1614, athleticsrewardsexchange:SerializeToString()

end

function NetAthleticsRewardExchange3Callback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1614, "athleticsrewardsexchange")
    local athleticsrewardsexchangeresult = somethings_pb.SomeThings()
    athleticsrewardsexchangeresult:ParseFromString(fd.rbuf)

    local t = {
        type = 1614,
        reward = gamedata:SomethingProcess(athleticsrewardsexchangeresult),
    }

    return t
end

-------------------------------1615---------------------------------

function UIAthleticsRankRewardsStatusCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1615, "athleticsrewardsexchange")
    local athleticsrewardsexchange = athleticsrewardsexchange_pb.AthleticsRewardExchange()
    athleticsrewardsexchange.id = uireq.id

    return 1, 1615, athleticsrewardsexchange:SerializeToString()

end

function NetAthleticsRankRewardsStatusCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1615, "athleticsrewardsexchange")
    local athleticsrewardsexchangeresult = somethings_pb.SomeThings()
    athleticsrewardsexchangeresult:ParseFromString(fd.rbuf)

    local t = {
        type = 1615,
        reward = gamedata:SomethingProcess(athleticsrewardsexchangeresult),
    }

    return t
end

-------------------------------1616---------------------------------

function UIAthleticsBoss2Callback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1616, "AthleticsBoss")

    return 1, 1616, nil
end

local battleresult_pb = require("battleresult_pb")
function NetAthleticsBoss2Callback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1616, "AthleticsBoss")
    local copyAttackResultPb = battleresult_pb.BattleResult()
    copyAttackResultPb:ParseFromString(fd.rbuf)

    local t = {
        type = 1616,
        result = copyAttackResultPb.result,
        reward = gamedata:SomethingProcess(copyAttackResultPb.reward),
        battlereport = PickBattleResultReport(copyAttackResultPb),

    }

    gamedata.cache.vipstatus.athletics_boss = gamedata.cache.vipstatus.athletics_boss +1

    return t
end

-------------------------------1615---------------------------------

function UIAthleticsRankRewardsStatusCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1615, "AthleticsList")

    return 1, 1615, nil

end

local ids_pb = require("ids_pb")
function NetAthleticsRankRewardsStatusCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1615, "AthleticsList")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata:rankreward(ids.ids)

    return { type = 1615, rankstatus = gamedata.cache.athletics.rankRewardStatus}
end
