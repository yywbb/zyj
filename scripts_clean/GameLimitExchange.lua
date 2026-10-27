--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/5/17
-- Time: 17:54
-- To change this template use File | Settings | File Templates.
--

local params_pb = require("params_pb")
local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local battleresult_pb = require("battleresult_pb")
local combmessages_pb = require("combmessages_pb")
require"PickBattleResultReport"

local function getItemArrayWithLimit(destIds,cpnum)
    local diff = 0
    local tmpReturnArray = {}
    local tmpVector = gamedata.config.limit_time_exchange
    if cpnum and cpnum > 0 then
        tmpVector = gamedata.config["limit_time_exchange_"..cpnum]
        diff = 2
    end
    for i=1,5 do
        local tmpId = tostring(destIds[i*2+diff])
        local tmpLost = destIds[i*2+1+diff]
        local tmpItmes = gamedata.getIDandNUMs(tmpVector[tmpId]["item"])
        local tmpItme = {_IdIndex = tmpId,
                         _level = tonumber(tmpVector[tmpId]["troop_lv"]),
                         _selfLevel = gamedata.cache.role.level,
                         _vip = tonumber(tmpVector[tmpId]["vip_lv"]),
                         _selfVip = gamedata.cache.role.vip,
                         _item = tmpItmes,
                         _exchange = {gamedata.getIDandNUM(tmpVector[tmpId]["exchange_item"])},
                         _once = tonumber(tmpVector[tmpId]["times"]) - tmpLost,
                         _max = tonumber(tmpVector[tmpId]["times"]),
                         _nums = {}}
        for j,v in ipairs(tmpItmes) do
            table.insert(tmpItme._nums,gamedata.getStaffNum(v.cid,true))
        end
        table.insert(tmpReturnArray,tmpItme)
    end
    return tmpReturnArray
end

function UILimitExchangeQuery(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3710, "LimitExchangeQuery")
    return 1, 3710, nil

end

function NetLimitExchangeQuery(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3710, "LimitExchangeQuery")
    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)
    local tmpFreshTimes = Result.ids[1]
    return { type = 3710,_freshTimes = tmpFreshTimes,_item = getItemArrayWithLimit(Result.ids)}
end

function UIUserLimitExchange(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3711, "UserLimitExchange")
    local FriendReqData = ids_pb.Ids()
    table.insert(FriendReqData.ids, tonumber(uireq._id))
    if uireq._num then
        table.insert(FriendReqData.ids, tonumber(uireq._num))
        gamedata.ext.limitex_num = uireq._num
    end
    if uireq._id then
        gamedata.ext.limitex_id = uireq._id
    end
    
    return 1, 3711, FriendReqData:SerializeToString()

end

function NetUserLimitExchange(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3711, "UserLimitExchange")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    local reward, used, ext = gamedata:SomethingProcess(SomeThings)
    local xprop = {}
    if gamedata.ext.limitex_id then
        local tmpVector = gamedata.config.limit_time_exchange
        local tmpItmes = gamedata.getIDandNUMs(tmpVector[gamedata.ext.limitex_id]["item"])
        xprop = tmpItmes
        for i,v in pairs(tmpItmes) do
            gamedata:updateStaff({cid = v.cid,num = -v.num * (gamedata.ext.limitex_num  or 1)})
        end
        gamedata.ext.limitex_id = nil
    end
    -- printT(reward,"==reward==")
    -- printT(used,"==used==")
    -- printT(ext,"==ext==")
    return { type = 3711 ,_reward = reward,_type = ext._type,xprop = xprop}
end

function UIUserLimitExchangeRefresh(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3712, "UserLimitExchangeRefresh")

    gamedata.ext.limitexgold = uireq.gold or 0
    if gamedata.ext.limitexgold > gamedata.cache.role.gold then
        return 0,503,{type = 503, msgtype = "shortgold" }
    end

    return 1, 3712, nil
end

function NetUserLimitExchangeRefresh(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3712, "UserLimitExchangeRefresh")

    gamedata:updateRoleGold(0-gamedata.ext.limitexgold,"限时兑换",1)
    gamedata.ext.limitexgold = 0

    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)
    local tmpFreshTimes = Result.ids[1]
    return { type = 3712 ,_freshTimes = tmpFreshTimes,_item = getItemArrayWithLimit(Result.ids)}
end

--
local LimitExchange_cpnum = 0
local LimitExchange_cpday = 0
function UICPLimitExchangeQuery(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5052, "LimitExchangeQuery")
    return 1, 5052, nil

end

function NetCPLimitExchangeQuery(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5052, "LimitExchangeQuery")
    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    LimitExchange_cpnum = Result.ids[1] or 0
    LimitExchange_cpday = Result.ids[2] or 0

    local tmpFreshTimes = Result.ids[3] or 0
    return { type = 5052,_freshTimes = tmpFreshTimes,_item = getItemArrayWithLimit(Result.ids,LimitExchange_cpnum), cpnum = LimitExchange_cpnum, cpday = LimitExchange_cpday}
end

function UICPUserLimitExchange(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5053, "UserLimitExchange")
    local FriendReqData = ids_pb.Ids()
    table.insert(FriendReqData.ids, tonumber(uireq._id))
    if uireq._num then
        table.insert(FriendReqData.ids, tonumber(uireq._num))
        gamedata.ext.limitex_num = uireq._num
    end
    if uireq._id then
        gamedata.ext.limitex_id = uireq._id
    end

    return 1, 5053, FriendReqData:SerializeToString()

end

function NetCPUserLimitExchange(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5053, "UserLimitExchange")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    local reward, used, ext = gamedata:SomethingProcess(SomeThings)
    local xprop = {}
    if gamedata.ext.limitex_id then
        local tmpVector = gamedata.config.limit_time_exchange
        if LimitExchange_cpnum and LimitExchange_cpnum > 0 then
            tmpVector = gamedata.config["limit_time_exchange_"..LimitExchange_cpnum]
        end
        local tmpItmes = gamedata.getIDandNUMs(tmpVector[gamedata.ext.limitex_id]["item"])
        xprop = tmpItmes
        for i,v in pairs(tmpItmes) do
            gamedata:updateStaff({cid = v.cid,num = -v.num * (gamedata.ext.limitex_num  or 1)})
        end
        gamedata.ext.limitex_id = nil
    end
    -- printT(reward,"==reward==")
    -- printT(used,"==used==")
    -- printT(ext,"==ext==")
    return { type = 5053 ,_reward = reward,_type = ext._type,xprop = xprop}
end

function UICPUserLimitExchangeRefresh(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5054, "UserLimitExchangeRefresh")

    gamedata.ext.limitexgold = uireq.gold or 0
    if gamedata.ext.limitexgold > gamedata.cache.role.gold then
        return 0,503,{type = 503, msgtype = "shortgold" }
    end

    return 1, 5054, nil
end

function NetCPUserLimitExchangeRefresh(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5054, "UserLimitExchangeRefresh")

    gamedata:updateRoleGold(0-gamedata.ext.limitexgold,"限时兑换",1)
    gamedata.ext.limitexgold = 0

    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)
    local tmpFreshTimes = Result.ids[3] or 0
    return { type = 5054 ,_freshTimes = tmpFreshTimes,_item = getItemArrayWithLimit(Result.ids,LimitExchange_cpnum), cpnum = LimitExchange_cpnum, cpday = LimitExchange_cpday}
end
