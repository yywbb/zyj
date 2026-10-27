--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/9/1
-- Time: 11:00
-- To change this template use File | Settings | File Templates.
--


local propid = 20346
local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local combmessages_pb = require("combmessages_pb")
local params_pb = require("params_pb")
local battleresult_pb = require("battleresult_pb")
local players_pb = require("players_pb")
local result_pb = require("result_pb")

require"PickBattleResultReport"

function UIWorldWarPrepareQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4700, "WorldWarPrepareQuery")

    return 1, 4700, nil
end

function NetWorldWarPrepareQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4700, "WorldWarPrepareQuery")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata:WorldWarPrepare(ids.ids)

    return { type = 4700, worldwarstatus = gamedata.cache.worldwarstatus or {}, worldwarprepare = gamedata.cache.worldwarprepare or {}, propnum = gamedata.cache.props[propid] and gamedata.cache.props[propid].num or 0}

end

--
function UIWorldWarGetItemCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4701, "WorldWarGetItem")
    local propnum = gamedata.cache.props[propid] and gamedata.cache.props[propid].num or 0
    if propnum < (gamedata.config.global_kv.cross_battle_book and tonumber(gamedata.config.global_kv.cross_battle_book.value) or 0) then
        return 0,503,{type = 503,msgtype = "shortprop",id = propid,num = tonumber(gamedata.config.global_kv.cross_battle_book.value)}
    end
    return 1, 4701, nil
end

function NetWorldWarGetItemCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4701, "WorldWarGetItem")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local reward = {}
    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:WorldWarPrepare(ids.ids)
        elseif v.id == 1 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
        end
    end

    if gamedata.config.global_kv.cross_battle_book and tonumber(gamedata.config.global_kv.cross_battle_book.value)>0 then
        gamedata:updateStaff({cid = propid,num = 0-tonumber(gamedata.config.global_kv.cross_battle_book.value)})
    end

    return { type = 4701, reward = reward, worldwarprepare = gamedata.cache.worldwarprepare or {}, propnum = gamedata.cache.props[propid] and gamedata.cache.props[propid].num or 0}

end

--
function UIWorldWarPrepareUpdateSlotCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4704, "WorldWarPrepareUpdateSlot")

    return 1, 4704, nil
end

function NetWorldWarPrepareUpdateSlotCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4704, "WorldWarPrepareUpdateSlot")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local result = ids.ids[1] or 0

    return { type = 4704, result = result}

end

--
function UIWorldWarQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4702, "WorldWarQuery")

    gamedata.ext.WorldWarQueryParam = uireq.param

    return 1, 4702, nil
end

function NetWorldWarQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4702, "WorldWarQuery")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata:WorldWarStatus(ids.ids)

    return { type = 4702, worldwarstatus = gamedata.cache.worldwarstatus or {}, param = gamedata.ext.WorldWarQueryParam}

end

--
function UIWorldWarRoleBattlesCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4703, "WorldWarRoleBattles")

    return 1, 4703, nil
end

function NetWorldWarRoleBattlesCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4703, "WorldWarRoleBattles")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    gamedata.cache.worldwarrolebattles = {}

    for k,v in ipairs(datas.messages) do
        local params = params_pb.ParamS()
        params:ParseFromString(v.data)

        if v.id > 0 then
            gamedata.cache.worldwarrolebattles[v.id] = gamedata.WorldWarRoleBattles(params.params)
        end
    end

    return { type = 4703, worldwarrolebattles = gamedata.cache.worldwarrolebattles or {}, worldwarstatus = gamedata.cache.worldwarstatus or {},}

end

--
function UIWorldWarBattlePlayCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4711, "WorldWarBattlePlay")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id)
    return 1, 4711, idsData:SerializeToString()
end


function NetWorldWarBattlePlayCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4711, "WorldWarBattlePlay")
    local copyAttackResultPb = battleresult_pb.BattleResult()
    copyAttackResultPb:ParseFromString(fd.rbuf)


    return {
        type = 4711,
        result = copyAttackResultPb.result,
        reward = gamedata:SomethingProcess(copyAttackResultPb.reward),
        battlereport = PickBattleResultReport(copyAttackResultPb),
        star = copyAttackResultPb.star
    }
end

--
function UIWorldWarRoleBattlesRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4714, "WorldWarRoleBattlesReward")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.phase)
    table.insert(idsData.ids, uireq.id)

    return 1, 4714, idsData:SerializeToString()
end


function NetWorldWarRoleBattlesRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4714, "WorldWarRoleBattlesReward")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    local reward = gamedata:SomethingProcess(SomeThings)

    return {type = 4714, reward = reward,}
end

--
function UIWorldWarTopUserInfoCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4712, "WorldWarTopUserInfo")
    printT(uireq)
    local idsData = ids_pb.Ids()
    if uireq.division then
        table.insert(idsData.ids, uireq.division)
    end

    gamedata.ext.WarTopUserDivision = uireq.division
    return 1, 4712, idsData:SerializeToString()
end

function NetWorldWarTopUserInfoCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4712, "WorldWarTopUserInfo")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    gamedata.cache.worldwarplayers = {}
    for k,v in ipairs(datas.messages) do

        local params = params_pb.ParamS()
        params:ParseFromString(v.data)
        if v.id > 0 then
            print("WorldWarTopUserInfo",v.id)
            local player = gamedata.WorldWarPlayers(params.params)
            gamedata.cache.worldwarplayers[player.id] = player
        end
    end


    return { type = 4712, worldwarplayers = gamedata.cache.worldwarplayers or {}}

end

--
function UIWorldWarTopCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4708, "WorldWarTopCallBack")

    local idsData = ids_pb.Ids()
    if uireq.division then
        table.insert(idsData.ids, uireq.division)
    end

    gamedata.ext.WorldWarTopDivision = uireq.division
    return 1, 4708, idsData:SerializeToString()
end

function NetWorldWarTopCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4708, "WorldWarTopCallBack")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    gamedata.cache.worldwartop = {}

    for k,v in ipairs(datas.messages) do
        local idsData = ids_pb.Ids()
        idsData:ParseFromString(v.data)
        gamedata:WorldWarTop(idsData.ids,v.id)
    end


    return { type = 4708, worldwartop = gamedata.cache.worldwartop or {}}

end


--
-- 跨服战海选阶段(本服)玩家积分排名
function UIWorldWarSignInfoQuerCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4705, "Wing")

    return 1, 4705, nil
end

function NetWorldWarSignInfoQuerCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4705, "Wing")

    local playerdata = {}

    local UsePorp = combmessages_pb.CombMessages()
    UsePorp:ParseFromString(fd.rbuf)
    local getData = {}
    for k,v in ipairs(UsePorp.messages) do
        print("messages===",v.id)
        if v.id == 0 then
            print("messages==in==",v.id)
            local ids = ids_pb.Ids();
            ids:ParseFromString(v.data)

            playerdata.myscore = ids.ids[1] and ids.ids[1] or 0
            playerdata.number = ids.ids[2] and ids.ids[2] or 16
        end


        if v.id == 1 then
            print("data===v.id===",v.data)
            printT(v.data)

            local tmpPlayer = players_pb.Players()
            tmpPlayer:ParseFromString(v.data)
            local palyers ={}
            for k,v in ipairs(tmpPlayer.players) do
                local playerdata = gamedata:playerdata(v)

                local temp = {}
                temp.rank = tonumber(k) or 1
                temp.name = playerdata.name
                temp.scorenum = playerdata.params[1] and playerdata.params[1].i or 1 -- 杯赛积分
                temp.id = playerdata.rid

                table.insert(palyers,temp)
            end

            playerdata.palyers = palyers
        end

    end


    return { type = 4705, playerdata = playerdata}
end

-- 跨服战历届冠军查询
function UIWorldWarChampionQuerCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4706, "Wing")

    return 1, 4706, nil
end

function NetWorldWarChampionQuerCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4706, "Wing")

    local params = params_pb.ParamS()
    params:ParseFromString(fd.rbuf)

    local infodata = gamedata:ServiceWarChampionData(params.params)


    return { type = 4706, infodata = infodata}
end

-- 跨服战赛区信息（人 天 神）查询
function UIWorldWarGroupInfoQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4707, "Wing")

    return 1, 4707, nil
end

function NetWorldWarGroupInfoQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4707, "Wing")

    local params = params_pb.ParamS()
    params:ParseFromString(fd.rbuf)

    local infodata = gamedata:ServiceWarGroupInfoData(params.params)


    return { type = 4707, infodata = infodata}
end

-- 跨服战淘汰赛观战／(观战)信息 查询
function UIWorldWarTopInfoCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4710, "WorldWar")
    printT(uireq,"UIWorldWarTopInfoCallBack==")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id)
    table.insert(idsData.ids, uireq.division or 0)
    return 1, 4710, idsData:SerializeToString()

end

function NetWorldWarTopInfoCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4710, "WorldWar")
    print("NetWorldWarTopInfoCallBack")
    local playerdata = {}

    local UsePorp = combmessages_pb.CombMessages()
    UsePorp:ParseFromString(fd.rbuf)
    local getData = {}
    for k,v in ipairs(UsePorp.messages) do
        print("messages===",v.id)
        if v.id == 1 then
            local ids = ids_pb.Ids();
            ids:ParseFromString(v.data)
            playerdata.basicdata = gamedata:ServiceWarWatchBasicData(ids.ids)
        end


        if v.id == 2 then
            local params = params_pb.ParamS()
            params:ParseFromString(v.data)
            playerdata.player1 = gamedata:ServiceWarWatchPlayerData(params.params)
        end

        if v.id == 3 then
            local params = params_pb.ParamS()
            params:ParseFromString(v.data)
            playerdata.player2 = gamedata:ServiceWarWatchPlayerData(params.params)
        end
    end


    return {
        type = 4710,
        playerdata = playerdata
    }
end

-- 跨服战淘汰赛观战／(下注)信息 查询
function UIWorldWarTopBetInfoCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4713, "WorldWar")
    printT(uireq,"UIWorldWarTopBetInfoCallBack==")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id)
    table.insert(idsData.ids, uireq.division)
    return 1, 4713, idsData:SerializeToString()

end

function NetWorldWarTopBetInfoCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4713, "WorldWar")
    print("NetWorldWarTopBetInfoCallBack")
    local servicedata = {}

    local UsePorp = combmessages_pb.CombMessages()
    UsePorp:ParseFromString(fd.rbuf)
    local getData = {}
    for k,v in ipairs(UsePorp.messages) do
        print("messages===",v.id)
        if v.id == 1 then
            print("messages==in==",v.id)
            local ids = ids_pb.Ids();
            ids:ParseFromString(v.data)
            servicedata.basicdata = gamedata:ServiceWarBetBasicData(ids.ids)
        end


        if v.id == 2 then
            print("data===v.id===",v.data)
            printT(v.data)
            local params = params_pb.ParamS()
            params:ParseFromString(v.data)
            servicedata.player1 = gamedata:ServiceWarBetPlayerData(params.params)
        end

        if v.id == 3 then
            local params = params_pb.ParamS()
            params:ParseFromString(v.data)
            servicedata.player2 = gamedata:ServiceWarBetPlayerData(params.params)
        end
    end


    return {
        type = 4713,
        servicedata = servicedata
    }
end

-- 跨服战海选阶段本服玩家积分排名(本服的排名 and 在全服的排名)
function UIWorldWarRankQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4715, "WorldWar")
    return 1, 4715, nil
end

function NetWorldWarRankQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4715, "WorldWar")

    local server_id = gamedata.cache.worldwarstatus.server_id and gamedata.cache.worldwarstatus.server_id or 0

    local tmpPlayer = players_pb.Players()
    tmpPlayer:ParseFromString(fd.rbuf)
    local rank1 ={}
    local rank2 ={}
    for k,v in ipairs(tmpPlayer.players) do
        local playerdata = gamedata:playerdata(v)

        local temp = {}
        temp.rank = playerdata.params[1] and playerdata.params[1].i or 1
        temp.name = playerdata.name
        temp.cupscorenum = playerdata.params[2] and playerdata.params[2].i or 1 -- 杯赛积分
        temp.servicescorenum = playerdata.params[3] and playerdata.params[3].i or 1 -- 跨服战积分
        temp.serverid = playerdata.params[4] and playerdata.params[4].i or 1
        temp.servicename = playerdata.params[5] and playerdata.params[5].s or ""
        temp.is_self = playerdata.params[6] and playerdata.params[6].i or 0

        if (server_id > 0 and server_id == temp.serverid) or (server_id == 0) then
            table.insert(rank1,temp)
        else
            table.insert(rank2,temp)
        end
        
    end
    -- printT(rank1,"palyers===xxx")
    -- printT(rank2,"palyers===xxx")

    local sortfunction1 = function( a,b )
        if a.cupscorenum == b.cupscorenum then
            return a.rank < b.rank
        else
            return a.cupscorenum > b.cupscorenum
        end
    end
    table.sort( rank1, sortfunction1 )

    for i,v in ipairs(rank1) do
        if i <= 16 then
            table.insert(rank2,table.copy(v))
        end
    end

    local sortfunction2 = function( a,b )
        return a.rank < b.rank
    end
    table.sort( rank2, sortfunction2 )

    local playersdata = {}
    playersdata.rank1 = rank1
    playersdata.rank2 = rank2


    return { type = 4715, playersdata = playersdata}
end


--  跨服战淘汰赛押注
function UIWorldWarWeedBetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4716, "WorldWar")
    printT(uireq,"UIWorldWarWeedBetCallBack==")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id)
    table.insert(idsData.ids, uireq.mark)
    table.insert(idsData.ids, uireq.money)
    table.insert(idsData.ids, uireq.division)
    gamedata.ext.worldwarWeedBet = uireq

    return 1, 4716, idsData:SerializeToString()

end

function NetWorldWarWeedBetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4716, "WorldWar")
    print("NetWorldWarWeedBetCallBack==")

    local Result = result_pb.Result()
    Result:ParseFromString(fd.rbuf)

    if gamedata.ext.worldwarWeedBet and gamedata.ext.worldwarWeedBet.money then
        gamedata:updateRoleCoin(0-gamedata.ext.worldwarWeedBet.money)
    end

    return {
        type = 4716,
        result = Result.result,
        id = gamedata.ext.worldwarWeedBet and gamedata.ext.worldwarWeedBet.id or 1
    }
end

--
function UIWorldWarCurrentChampionQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4717, "WorldWarCurrentChampionQuery")

    return 1, 4717, nil

end

function NetWorldWarCurrentChampionQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4717, "WorldWarCurrentChampionQuery")

    local params = params_pb.ParamS()
    params:ParseFromString(fd.rbuf)

    local infodata = gamedata:WorldWarCurrentChampion(params.params)


    return { type = 4717, worldwarchampion = infodata, worldwarstatus = gamedata.cache.worldwarstatus or {}}
end

--
--
function UIWorldWarWorshipCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4718, "WorldWarWorship")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.group)

    return 1, 4718, idsData:SerializeToString()
end


function NetWorldWarWorshipCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4718, "WorldWarWorship")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    local reward = gamedata:SomethingProcess(SomeThings)

    return {type = 4718, reward = reward,}
end


--
function NetWorldWarPreparePushCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4709, "WorldWarPreparePush")

    local params = params_pb.ParamS()
    params:ParseFromString(fd.rbuf)

    local infodata = {}
    infodata.time = params.params[1] and params.params[1].i or 0
    infodata.name = params.params[2] and params.params[2].s or ""
    infodata.num = params.params[3] and params.params[3].i or 0

    return { type = 4709, preparepushinfo = infodata}
end


-----------神榜冠军赛新加-----------

function UIWorldWarRoleBattlesShenbangCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4720, "WorldWarRoleBattlesShenbang")

    return 1, 4720, nil
end

function NetWorldWarRoleBattlesShenbangCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4720, "WorldWarRoleBattlesShenbang")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    gamedata.cache.worldwarrolebattlesShenbang = {}

    for k,v in ipairs(datas.messages) do
        local params = params_pb.ParamS()
        params:ParseFromString(v.data)
        if v.id > 0 then
            gamedata.cache.worldwarrolebattlesShenbang[v.id] = gamedata.WorldWarRoleBattles(params.params)
        end
    end

    return { type = 4720, worldwarrolebattlesShenbang = gamedata.cache.worldwarrolebattlesShenbang or {}, worldwarstatus = gamedata.cache.worldwarstatus or {},}

end

function UIWorldWarTopShenbangCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4721, "WorldWarTopShenbangCallBack")

    return 1, 4721, nil
end

function NetWorldWarTopShenbangCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4721, "WorldWarTopShenbangCallBack")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    gamedata.cache.worldwartopShenbang = {}

    for k,v in ipairs(datas.messages) do
        local idsData = ids_pb.Ids()
        idsData:ParseFromString(v.data)
        gamedata:WorldWarTopShenbang(idsData.ids,v.id)
    end


    return { type = 4721, worldwartopShenbang = gamedata.cache.worldwartopShenbang or {}}

end

--  跨服战淘汰赛押注
function UIWorldWarWeedBetShenbangCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4722, "WorldWarShenbang")
    printT(uireq,"UIWorldWarWeedBetCallBack==")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id)
    table.insert(idsData.ids, uireq.mark)
    table.insert(idsData.ids, uireq.money)

    gamedata.ext.worldwarWeedBetShenbang = uireq

    return 1, 4722, idsData:SerializeToString()

end

function NetWorldWarWeedBetShenbangCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4722, "WorldWarShenbang")
    print("NetWorldWarWeedBetCallBack==")

    local Result = result_pb.Result()
    Result:ParseFromString(fd.rbuf)

    if gamedata.ext.worldwarWeedBetShenbang and gamedata.ext.worldwarWeedBetShenbang.money then
        gamedata:updateRoleCoin(0-gamedata.ext.worldwarWeedBetShenbang.money)
    end

    return {
        type = 4722,
        result = Result.result,
        id = gamedata.ext.worldwarWeedBetShenbang and gamedata.ext.worldwarWeedBetShenbang.id or 1
    }
end

function UIWorldWarRoleBattlesRewardShenbangCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4723, "WorldWarRoleBattlesReward")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.phase)
    table.insert(idsData.ids, uireq.id)

    return 1, 4723, idsData:SerializeToString()
end


function NetWorldWarRoleBattlesRewardShenbangCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4723, "WorldWarRoleBattlesReward")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    local reward = gamedata:SomethingProcess(SomeThings)

    return {type = 4723, reward = reward,}
end

function UIWorldWarTopUserInfoShenbangCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4724, "WorldWarTopUserInfoShenbang")
    return 1, 4724, nil
end

function NetWorldWarTopUserInfoShenbangCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4724, "WorldWarTopUserInfoShenbang")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    gamedata.cache.worldwarplayersShenbang = {}
    for k,v in ipairs(datas.messages) do
        local params = params_pb.ParamS()
        params:ParseFromString(v.data)
        if v.id > 0 then
            local player = gamedata.WorldWarPlayers(params.params)
            gamedata.cache.worldwarplayersShenbang[player.id] = player
        end
    end


    return { type = 4724, worldwarplayersShenbang = gamedata.cache.worldwarplayersShenbang or {}}

end

-- 跨服战淘汰赛观战／(观战)信息 查询
function UIWorldWarTopInfoShenbangCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4725, "WorldWar")
    printT(uireq,"UIWorldWarTopInfoCallBack==")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id)

    return 1, 4725, idsData:SerializeToString()

end

function NetWorldWarTopInfoShenbangCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4725, "WorldWar")
    print("NetWorldWarTopInfoCallBack")
    local playerdata = {}

    local UsePorp = combmessages_pb.CombMessages()
    UsePorp:ParseFromString(fd.rbuf)
    local getData = {}
    for k,v in ipairs(UsePorp.messages) do
        print("messages===",v.id)
        if v.id == 1 then
            local ids = ids_pb.Ids();
            ids:ParseFromString(v.data)
            playerdata.basicdata = gamedata:ServiceWarWatchBasicData(ids.ids)
        end


        if v.id == 2 then
            local params = params_pb.ParamS()
            params:ParseFromString(v.data)
            playerdata.player1 = gamedata:ServiceWarWatchPlayerData(params.params)
        end

        if v.id == 3 then
            local params = params_pb.ParamS()
            params:ParseFromString(v.data)
            playerdata.player2 = gamedata:ServiceWarWatchPlayerData(params.params)
        end
    end


    return {
        type = 4725,
        playerdata = playerdata
    }
end


-- 跨服战淘汰赛观战／(下注)信息 查询
function UIWorldWarTopBetInfoShenbangCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4726, "WorldWar")
    printT(uireq,"UIWorldWarTopBetInfoCallBack==")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id)

    return 1, 4726, idsData:SerializeToString()

end

function NetWorldWarTopBetInfoShenbangCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4726, "WorldWar")
    print("NetWorldWarTopBetInfoCallBack")
    local servicedata = {}

    local UsePorp = combmessages_pb.CombMessages()
    UsePorp:ParseFromString(fd.rbuf)
    local getData = {}
    for k,v in ipairs(UsePorp.messages) do
        print("messages===",v.id)
        if v.id == 1 then
            print("messages==in==",v.id)
            local ids = ids_pb.Ids();
            ids:ParseFromString(v.data)
            servicedata.basicdata = gamedata:ServiceWarBetBasicData(ids.ids)
        end


        if v.id == 2 then
            print("data===v.id===",v.data)
            printT(v.data)
            local params = params_pb.ParamS()
            params:ParseFromString(v.data)
            servicedata.player1 = gamedata:ServiceWarBetPlayerData(params.params)
        end

        if v.id == 3 then
            local params = params_pb.ParamS()
            params:ParseFromString(v.data)
            servicedata.player2 = gamedata:ServiceWarBetPlayerData(params.params)
        end
    end


    return {
        type = 4726,
        servicedata = servicedata
    }
end

--
function UIWorldWarBattlePlayShenbangCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4727, "WorldWarBattlePlay")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id)

    return 1, 4727, idsData:SerializeToString()
end


function NetWorldWarBattlePlayShenbangCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4727, "WorldWarBattlePlay")
    local copyAttackResultPb = battleresult_pb.BattleResult()
    copyAttackResultPb:ParseFromString(fd.rbuf)


    return {
        type = 4727,
        result = copyAttackResultPb.result,
        reward = gamedata:SomethingProcess(copyAttackResultPb.reward),
        battlereport = PickBattleResultReport(copyAttackResultPb),
        star = copyAttackResultPb.star
    }
end

-- 跨服战海选阶段本服玩家积分排名(本服的排名 and 在全服的排名)
function UIWorldWarRankQueryShenbangCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4728, "WorldWar")
    return 1, 4728, nil
end

function NetWorldWarRankQueryShenbangCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4728, "WorldWar")

    local tmpPlayer = players_pb.Players()
    tmpPlayer:ParseFromString(fd.rbuf)
    local rank ={}
    for k,v in ipairs(tmpPlayer.players) do
        local playerdata = gamedata:playerdata(v)

        local temp = {}
        temp.rank = playerdata.params[1] and playerdata.params[1].i or 1
        temp.name = playerdata.name
        temp.cupscorenum = playerdata.params[2] and playerdata.params[2].i or 1 -- 杯赛积分
        temp.servicescorenum = playerdata.params[3] and playerdata.params[3].i or 1 -- 跨服战积分
        temp.serverid = playerdata.params[4] and playerdata.params[4].i or 1
        temp.servicename = playerdata.params[5] and playerdata.params[5].s or ""
        temp.is_self = playerdata.params[6] and playerdata.params[6].i or 0
        
        table.insert(rank,temp)
    end

    local sortfunction2 = function( a,b )
        return a.rank < b.rank
    end
    table.sort( rank, sortfunction2 )

    local playersdata = {}
    playersdata.rank1 = rank


    return { type = 4728, playersdata = playersdata}
end
  �p  