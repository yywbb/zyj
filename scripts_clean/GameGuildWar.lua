--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/12
-- Time: 下午2:59
-- To change this template use File | Settings | File Templates.
--
require"PickBattleResultReport"

local ids_pb = require("ids_pb")
local combmessages_pb = require("combmessages_pb")
local params_pb = require("params_pb")
local battleresult_pb = require("battleresult_pb")
local somethings_pb = require("somethings_pb")

-- 帮派据点总体查询
function UIGuildWarPointCatalogueCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2130, "UserGang2DailyReward")
    print("UIGuildWarPointCatalogueCallBack==")

    gamedata.ext.GuildWarPointParam = uireq.param or ""

    return 1, 2130, nil
end


function NetGuildWarPointCatalogueCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2130, "UserGang2MSetName")
    print("NetGuildWarPointCatalogueCallBack==")
    local PointData = combmessages_pb.CombMessages()
    PointData:ParseFromString(fd.rbuf)


    for k,v in ipairs(PointData.messages) do
        print("messages==in=",v.id)

        if v.id == 0 then
            print("messages===0000")
            local  ids = ids_pb.Ids();
            ids:ParseFromString(v.data)
            gamedata:GuildWarTakeWarPointData(ids.ids)
        elseif v.id == 1 then
            local params = params_pb.ParamS()
            params:ParseFromString(v.data)
            gamedata:GuildWarAllPointData(params.params)   
        end
    end
    print("netguildwarend===")
    -- printT(gamedata.cache.guildwarmain)

    return { type = 2130, guildwarmain = gamedata.cache.guildwarmain, param = gamedata.ext.GuildWarPointParam }

end

--据点相信信息请求
function UIGuildWarPointQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2131, "UserGangPointQuery")
    print("UIGuildWarPointQueryCallBack=="..uireq.id)
    if not uireq.id then
        print("UIGuildWarPointQueryCallBack uireq.id == nil")
    end
    if uireq.id == 0 then
        return  0,503,{type = 503, msg = "请让公会会长或副会长前来报名参加"}
    elseif  uireq.id == -1 then
        return  0,503,{type = 503, msg = "已经报名2个了！"}
    end
    local GuildWarPointQueryData = ids_pb.Ids()
    table.insert(GuildWarPointQueryData.ids, uireq.id)
    gamedata.ext.guildwarpointquery = {id = uireq.id , isleader = uireq.isleader}
    return 1, 2131, GuildWarPointQueryData:SerializeToString()    
end
function NetGuildWarPointQueryCallBack( fd )
    cclog("NET type:%d cmd:%s recv response from gameserver", 2131, "UserGangPointQuery")
    print("NetGuildWarPointQueryCallBack==")
    local PointQueryData = params_pb.ParamS()
    PointQueryData:ParseFromString(fd.rbuf)
    gamedata:GuildWarPointQuery(PointQueryData.params)
    -- printT(gamedata.cache.guildwarpointquery)

    local treasureInfo = gamedata.cache.guildwarpointquery
    if treasureInfo.guildlevel == 0 then
        treasureInfo.guildlevel = gamedata.cache.gang2status.level
    end

    return {type = 2131, treasureInfo = gamedata.cache.guildwarpointquery,id = gamedata.ext.guildwarpointquery.id ,isleader = gamedata.ext.guildwarpointquery.isleader}
end

--据点相信信息请求
function UIGangPointJoinConfirmCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2132, "UIGangPointJoinConfirmCallBack")
    print("UIGangPointJoinConfirmCallBack=="..uireq.id)
    if not uireq.id then
        print("UIGangPointJoinConfirmCallBack uireq.id == nil")
    end
    local GuildWarPointQueryData = ids_pb.Ids()
    table.insert(GuildWarPointQueryData.ids, uireq.id)
    return 1, 2132, GuildWarPointQueryData:SerializeToString()    
end
function NetGangPointJoinConfirmCallBack( fd )
    cclog("NET type:%d cmd:%s recv response from gameserver", 2132, "NetGangPointJoinConfirmCallBack")
    print("NetGangPointJoinConfirmCallBack==")
    local  ids = ids_pb.Ids();
    ids:ParseFromString(fd.rbuf)
    gamedata:GangPointJoinConfirmData(ids.ids)
    if gamedata.cache.guildwarjionconfirm.isok ~= 0 then
        return  0,503,{type = 503, msg = "报名失败"}
    end
    return {type = 2132,state = gamedata.cache.guildwarjionconfirm}
end


--查看报名
function UIGangPointJoinQueryCallBack( uireq )
    cclog("NET type:%d cmd:%s recv request from UI", 2133, "UIGangPointJoinQueryCallBack")
    print("UIGangPointJoinQueryCallBack=="..uireq.id)
    if not uireq.id then
        print("UIGangPointJoinQueryCallBack uireq.id == nil")
    end
    local GangPointJoinQueryData = ids_pb.Ids()
    table.insert(GangPointJoinQueryData.ids, uireq.id)
    gamedata.ext.guildchecklist = {id = uireq.id ,guildid = uireq.guildid}
    return 1, 2133, GangPointJoinQueryData:SerializeToString()  
end
function NetGangPointJoinQueryCallBack( fd )
    cclog("NET type:%d cmd:%s recv response from gameserver", 2131, "NetGangPointJoinQueryCallBack")
    print("NetGangPointJoinQueryCallBack==")
    local PointQueryData = params_pb.ParamS()
    PointQueryData:ParseFromString(fd.rbuf)
    gamedata:GangPointJoinQuery(PointQueryData.params)
    printT(gamedata.cache.guildchecklist)

    return {type = 2133,treasureChechList = gamedata.cache.guildchecklist,id =gamedata.ext.guildchecklist.id ,guildid =gamedata.ext.guildchecklist.guildid }    
end
--
-- 战场准备
function UIGangPointEnterBattlefieldCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2134, "GangPointEnterBattlefield")
    if uireq and uireq.id then
        local idData = ids_pb.Ids()
        table.insert(idData.ids, uireq.id)
        gamedata.ext.GangPointEnterPointId = uireq.id
        return 1, 2134, idData:SerializeToString()
    else
        return 0, 503,{type = 503, msg = "战场错误" }
    end
end


function NetGangPointEnterBattlefieldCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2134, "GangPointEnterBattlefield")

    local PointData = combmessages_pb.CombMessages()
    PointData:ParseFromString(fd.rbuf)

    for k,v in ipairs(PointData.messages) do

        if v.id == 0 then
            local  ids = ids_pb.Ids();
            ids:ParseFromString(v.data)
            gamedata:GuildWarInspire(ids.ids)
        elseif v.id == 1 then
            local params = params_pb.ParamS()
            params:ParseFromString(v.data)
            gamedata:GuildWarPrepare(params.params)
        elseif v.id == 2 then
            local params = params_pb.ParamS()
            params:ParseFromString(v.data)
            gamedata:GuildWarMembers(params.params)
        end
    end


    return { type = 2134, pointId = gamedata.ext.GangPointEnterPointId, GuildWarInspire = gamedata.cache.GuildWarInspire or {}, GuildWarPrepare = gamedata.cache.GuildWarPrepare or {}, GuildWarMembers = gamedata.cache.GuildWarMembers or {}, }

end

function UIGangPointInspireCoinCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2136, "GangPointInspireCoin")

    gamedata.ext.GuildWarInspireCoin = 0

    if uireq and uireq.coin then
        gamedata.ext.GuildWarInspireCoin = uireq.coin
    end

    if gamedata.ext.GuildWarInspireCoin > gamedata.cache.role.coin then
        return 0,503,{type = 503, msgtype = "shortcoin"}
    end

    return 1, 2136, nil
end


function NetGangPointInspireCoinCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2136, "GangPointInspireCoin")

    local  ids = ids_pb.Ids();
    ids:ParseFromString(fd.rbuf)

    if gamedata.cache.GuildWarInspire.coinInspireTimes and ids.ids[1] then
        gamedata.cache.GuildWarInspire.coinInspireTimes = ids.ids[1]
    end

    if gamedata.cache.GuildWarInspire.atkBuff and ids.ids[2] then
        gamedata.cache.GuildWarInspire.atkBuff = ids.ids[2]
    end

    if gamedata.cache.GuildWarInspire.defBuff and ids.ids[3] then
        gamedata.cache.GuildWarInspire.defBuff = ids.ids[3]
    end


    gamedata:updateRoleCoin(0-gamedata.ext.GuildWarInspireCoin)

    return { type = 2136, GuildWarInspire = gamedata.cache.GuildWarInspire or {},}

end

function UIGangPointInspireGoldCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2137, "GangPointInspireGold")

    gamedata.ext.GuildWarInspireGold = 0

    if uireq and uireq.gold then
        gamedata.ext.GuildWarInspireGold = uireq.gold
    end

    if gamedata.ext.GuildWarInspireGold > gamedata.cache.role.gold then
        return 0,503,{type = 503, msgtype = "shortgold"}
    end

    return 1, 2137, nil
end


function NetGangPointInspireGoldCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2137, "GangPointInspireGold")

    local  ids = ids_pb.Ids();
    ids:ParseFromString(fd.rbuf)

    if gamedata.cache.GuildWarInspire.goldInspireTimes and ids.ids[1] then
        gamedata.cache.GuildWarInspire.goldInspireTimes = ids.ids[1]
    end

    if gamedata.cache.GuildWarInspire.atkBuff and ids.ids[2] then
        gamedata.cache.GuildWarInspire.atkBuff = ids.ids[2]
    end

    if gamedata.cache.GuildWarInspire.defBuff and ids.ids[3] then
        gamedata.cache.GuildWarInspire.defBuff = ids.ids[3]
    end

    if gamedata.cache.GuildWarInspire.winMax and ids.ids[4] then
        gamedata.cache.GuildWarInspire.winMax = ids.ids[4]
    end

    gamedata:updateRoleGold(0-gamedata.ext.GuildWarInspireGold,"公会战元宝鼓舞",1)

    return { type = 2137, GuildWarInspire = gamedata.cache.GuildWarInspire or {},}

end

function UIGangPointJoinBattleCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2135, "GangPointJoinBattle")

    gamedata.ext.GuildWarJoinBattleId = -1
    gamedata.ext.GuildWarJoinBattleOpt = -1

    local idData = ids_pb.Ids()
    if uireq and uireq.id then
        table.insert(idData.ids, uireq.id)
        gamedata.ext.GuildWarJoinBattleId = uireq.id
    end
    if uireq and uireq.opt then
        table.insert(idData.ids, uireq.opt)
        gamedata.ext.GuildWarJoinBattleOpt = uireq.opt
    end

    return 1, 2135, idData:SerializeToString()
end


function NetGangPointJoinBattleCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2135, "GangPointJoinBattle")

    local  ids = ids_pb.Ids();
    ids:ParseFromString(fd.rbuf)

    if ids.ids[1] and ids.ids[1] == 0 then
        if gamedata.ext.GuildWarJoinBattleOpt and gamedata.ext.GuildWarJoinBattleOpt == 0 then
            if gamedata.cache.GuildWarInspire.status then
                gamedata.cache.GuildWarInspire.status = 0
            end
        elseif gamedata.ext.GuildWarJoinBattleOpt and gamedata.ext.GuildWarJoinBattleOpt > 0 then
            if gamedata.cache.GuildWarInspire.status and gamedata.ext.GuildWarJoinBattleId and gamedata.ext.GuildWarJoinBattleId > 0 then
                gamedata.cache.GuildWarInspire.status = gamedata.ext.GuildWarJoinBattleId
            end
        end
    end

    return { type = 2135, GuildWarInspire = gamedata.cache.GuildWarInspire or {}, }

end


function NetGangPointMembersCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2143, "GangPointMembers")

    local params = params_pb.ParamS()
    params:ParseFromString(fd.rbuf)
    gamedata:GuildWarMembers(params.params)

    return { type = 2143, GuildWarMembers = gamedata.cache.GuildWarMembers or {}, }

end

function UIGangPointBattleStatusQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2138, "GangPointBattleStatusQuery")
    -- gamedata.ext.Guild = 0

    if uireq and uireq.id then
        gamedata.ext.GangPointBattleStatus = uireq.id
    end
    local GangPointBattleStatusQuery = ids_pb.Ids()
    table.insert(GangPointBattleStatusQuery.ids, uireq.id)
    return 1, 2138, GangPointBattleStatusQuery:SerializeToString()   
end


function NetGangPointBattleStatusQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from UI", 2138, "GangPointBattleStatusQuery")
  
    local PointData = combmessages_pb.CombMessages()
    PointData:ParseFromString(fd.rbuf)

    gamedata.cache.GuildStandingsShow = {}
    for k,v in ipairs(PointData.messages) do

        if v.id == 0 then

        else
            local params = params_pb.ParamS()
            params:ParseFromString(v.data)
            gamedata:GuildStandingsShow(params.params,v.id)            
        end
    end
    local pointId = gamedata.ext.GangPointBattleStatus or 0
    return { type = 2138, GuildStandingsShow = gamedata.cache.GuildStandingsShow or {}, pointId = pointId,}
end

function UIGangPointSumBattleListCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2140, "GangPointSumBattleList")
    gamedata.ext.Guild = 0

    if uireq and uireq.id then
        gamedata.ext.GangPointSumBattleList = uireq.id
        gamedata.ext.GangPointSumBattleListFightId = uireq.fightId
    end

    local GangPointSumBattleList = ids_pb.Ids()
    table.insert(GangPointSumBattleList.ids, uireq.id)
    table.insert(GangPointSumBattleList.ids, uireq.fightId)
    return 1, 2140, GangPointSumBattleList:SerializeToString()
end


function NetGangPointSumBattleListCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from UI", 2140, "GangPointSumBattleList")
  
    local PointData = combmessages_pb.CombMessages()
    PointData:ParseFromString(fd.rbuf)
    
    gamedata.cache.GuildStandingsRoleShow = {}
    for k,v in ipairs(PointData.messages) do
        local params = params_pb.ParamS()
        params:ParseFromString(v.data)
        gamedata:GuildStandingsRoleShow(params.params, v.id)
    end

    local fightId = gamedata.ext.GangPointSumBattleListFightId
    return { type = 2140, GuildStandingsRoleShow = gamedata.cache.GuildStandingsRoleShow or {}, fightId = fightId}
end

function UIGangPointSumBattlePlayCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2139, "GangPointSumBattlePlay")
    if uireq and uireq.id then
        gamedata.ext.GangPointBattleStatus = uireq.id
    end    
    local GangPointBattleStatusQuery = ids_pb.Ids()
    table.insert(GangPointBattleStatusQuery.ids, uireq.id)
    table.insert(GangPointBattleStatusQuery.ids, uireq.fightId)
    return 1, 2139, GangPointBattleStatusQuery:SerializeToString()  
end

function NetGangPointSumBattlePlayCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from UI", 2139, "GangPointSumBattlePlay")
    local ResultPb = battleresult_pb.BattleResult()
    ResultPb:ParseFromString(fd.rbuf)

    local t = {
        type = 2139,
        result = ResultPb.result,
        reward = gamedata:SomethingProcess(ResultPb.reward),
        battlereport = PickBattleResultReport(ResultPb),
    }

    return t
end

function UIGangPointBraBattlePlayCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2141, "GangPointBraBattlePlay")
    if uireq and uireq.id then
        gamedata.ext.GangPointBattleStatus = uireq.id
    end    
    local GangPointBattleStatusQuery = ids_pb.Ids()
    table.insert(GangPointBattleStatusQuery.ids, uireq.id) -- 据点id 
    table.insert(GangPointBattleStatusQuery.ids, uireq.fightId) -- 战斗Id
    table.insert(GangPointBattleStatusQuery.ids, uireq.fightRoundId) -- 回合id
    -- table.insert(GangPointSumBattleList.ids, uireq.fightId)
    return 1, 2141, GangPointBattleStatusQuery:SerializeToString()      
end

function NetGangPointBraBattlePlayCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from UI", 2141, "GangPointBraBattlePlay")
    local ResultPb = battleresult_pb.BattleResult()
    ResultPb:ParseFromString(fd.rbuf)

    local t = {
        type = 2141,
        result = ResultPb.result,
        reward = gamedata:SomethingProcess(ResultPb.reward),
        battlereport = PickBattleResultReport(ResultPb),
    }

    return t
end

-- 据点领奖
function UIGuildWarPointAwardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2142, "UIGuildWarPointAwardCallBack")
    print("UIGuildWarPointAwardCallBack==")
    -- printT(uireq)
    -- gamedata.ext.GuildWarPointAwardid = uireq.id
    if uireq and uireq.id then
        local idData = ids_pb.Ids()
        table.insert(idData.ids, uireq.id)

        return 1, 2142, idData:SerializeToString()
    end
end

function  NetGuildWarPointAwardCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from UI", 2142, "NetGuildWarPointAwardCallBack")
    print("NetGuildWarPointAwardCallBack===")

    local AwardData = somethings_pb.SomeThings()
    AwardData:ParseFromString(fd.rbuf)

    gamedata.cache.guildwarmain.takewardata.rewardstatus = 2

    -- gamedata.ext.GuildWarPointAwardid

    -- gamedata:updateRoleGold(0-tonumber(gamedata.ext.EquipAwardData.gold),"装备宝物重生消耗金币",1)

    return { type = 2142, reward = gamedata:SomethingProcess(AwardData), guildwarmain = gamedata.cache.guildwarmain }
end

-- 主界面获取公会 数据
function UIMainGetGangDataCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2149, "UIMainGetGangDataCallBack")
    print("UIMainGetGangDataCallBack==")
    -- printT(uireq)
    
    return 0, 2149, { type = 2149, gangstatus = gamedata.cache.gang2status}

end


-- 据点收益
function UIGuildWarProfitCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2144, "UIGuildWarProfitCallBack")

    return 1, 2144, nil
end

function  NetGuildWarProfitCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from UI", 2144, "NetGuildWarProfitCallBack")

    local  ids = ids_pb.Ids();
    ids:ParseFromString(fd.rbuf)

    gamedata.cache.guildWarProfit = {}
    gamedata.cache.guildWarProfit.id = ids.ids[1] or 0

    if gamedata.config.gang2battle_youhua_type and gamedata.config.gang2battle_youhua_type[tostring(gamedata.cache.guildWarProfit.id)] and gamedata.config.gang2battle_youhua_type[tostring(gamedata.cache.guildWarProfit.id)].add and gamedata.config.gang2battle_youhua_type[tostring(gamedata.cache.guildWarProfit.id)].add == 3 then
        gamedata.cache.guildWarProfit.effect =  tonumber(gamedata.config.gang2battle_youhua_type[tostring(gamedata.cache.guildWarProfit.id)].effect) or 0
    else
        gamedata.cache.guildWarProfit.effect = 0
    end

    return { type = 2144, guildWarProfit = gamedata.cache.guildWarProfit }
end

function  NetGuildWarProfitChangeCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from UI", 2145, "NetGuildWarProfitChangeCallBack")

    local  ids = ids_pb.Ids();
    ids:ParseFromString(fd.rbuf)

    gamedata.cache.guildWarProfit = {}
    gamedata.cache.guildWarProfit.id = ids.ids[1] or 0

    if gamedata.config.gang2battle_youhua_type and gamedata.config.gang2battle_youhua_type[tostring(gamedata.cache.guildWarProfit.id)] and gamedata.config.gang2battle_youhua_type[tostring(gamedata.cache.guildWarProfit.id)].add and gamedata.config.gang2battle_youhua_type[tostring(gamedata.cache.guildWarProfit.id)].add == 3 then
        gamedata.cache.guildWarProfit.effect =  tonumber(gamedata.config.gang2battle_youhua_type[tostring(gamedata.cache.guildWarProfit.id)].effect) or 0
    else
        gamedata.cache.guildWarProfit.effect = 0
    end

    return { type = 2145, guildWarProfit = gamedata.cache.guildWarProfit }
end

-- 一键鼓舞
function UIGuildWarOneInspireCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2146, "GuildWarOneInspire")
    --UIRequest({type = 2146,num = costData[1].num})
    gamedata.ext.guildWarInspireCostgold = uireq.num

    return 1, 2146, nil
end

function  NetGuildWarOneInspireCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from UI", 2146, "GuildWarOneInspire")

    local  ids = ids_pb.Ids();
    ids:ParseFromString(fd.rbuf)
    local result = ids.ids[1] or 0
    gamedata:updateRoleGold(0-gamedata.ext.guildWarInspireCostgold,"公会战元宝鼓舞",1)
    return { type = 2146, result = result }

end


-- 一键参战
function UIGuildWarOneBattleCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2147, "GuildWarOneBattle")
    gamedata.ext.guildWaroneBattleCostgold = uireq.num

    return 1, 2147, nil
end

function  NetGuildWarOneBattleCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from UI", 2147, "GuildWarOneBattle")

    local  ids = ids_pb.Ids();
    ids:ParseFromString(fd.rbuf)
    local result = ids.ids[1] or 0
    gamedata:updateRoleGold(0-gamedata.ext.guildWaroneBattleCostgold,"公会战元宝鼓舞",1)
    return { type = 2147, result = result }

end

