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


function UIChampionStatusCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2700, "ChampionStatus")

    gamedata.ext.championStatusParam = uireq.param or ""

    return 1, 2700, nil

end

function NetChampionStatusCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2700, "ChampionStatus")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:ChampionStatus(ids.ids)
        else
            local params = params_pb.ParamS()
            params:ParseFromString(v.data)
            gamedata:ChampionPoint(params.params,v.id)
        end
    end

    return { type = 2700, champion = gamedata.cache.champion, param = gamedata.ext.championStatusParam, }

end

--
function UIChampionBattleCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2701, "ChampionBattle")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id or 0)

    gamedata.ext.championBattleID = uireq.id or 0

    gamedata.ext.championBattleAuto = uireq.isauto or 0

    return 1, 2701, idsData:SerializeToString()
end


function NetChampionBattleCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2701, "ChampionBattle")
    local copyAttackResultPb = battleresult_pb.BattleResult()
    copyAttackResultPb:ParseFromString(fd.rbuf)

    return {
        type = 2701,
        result = copyAttackResultPb.result,
        reward = gamedata:SomethingProcess(copyAttackResultPb.reward),
        battlereport = PickBattleResultReport(copyAttackResultPb),
        battleid = gamedata.ext.championBattleID or 0,
        isauto = gamedata.ext.championBattleAuto or 0,
    }
end

--
function UIChampionNextCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2702, "ChampionNext")

    return 1, 2702, nil
end

function NetChampionNextCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2702, "ChampionNext")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:ChampionStatus(ids.ids)
        else
            local params = params_pb.ParamS()
            params:ParseFromString(v.data)
            gamedata:ChampionPoint(params.params,v.id)
        end
    end

    return { type = 2702, champion = gamedata.cache.champion, }

end

--
function UIChampionResetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2703, "ChampionReset")

    gamedata.ext.championResetGold = uireq.xgold or 0

    if gamedata.ext.championResetGold > gamedata.cache.role.gold then
        return 0,503,{type = 503, msgtype = "shortgold" }
    end

    return 1, 2703, nil
end

function NetChampionResetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2703, "ChampionReset")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:ChampionStatus(ids.ids)
        else
            local params = params_pb.ParamS()
            params:ParseFromString(v.data)
            gamedata:ChampionPoint(params.params,v.id)
        end
    end

    if gamedata.ext.championResetGold and gamedata.ext.championResetGold > 0 then
        gamedata:updateRoleGold(0-gamedata.ext.championResetGold,"冠军试炼重置",1)
    end

    return { type = 2703, champion = gamedata.cache.champion, }

end

--
function UIChampionBoxOpenCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2704, "ChampionBoxOpen")
    gamedata.ext.championBoxGold = uireq.xgold or 0

    if gamedata.ext.championBoxGold > gamedata.cache.role.gold then
        return 0,503,{type = 503, msgtype = "shortgold" }
    end

    return 1, 2704, nil
end

function NetChampionBoxOpenCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2704, "ChampionBoxOpen")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local reward = {}
    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:ChampionBox(ids.ids)
        elseif v.id == 1 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
        end
    end

    if gamedata.ext.championBoxGold and gamedata.ext.championBoxGold > 0 then
        gamedata:updateRoleGold(0-gamedata.ext.championBoxGold,"冠军试炼开宝箱",1)
    end

    return { type = 2704, champion = gamedata.cache.champion, reward = reward,}

end


--商店
function UIChampionShopQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2710, "ChampionShopQuery")

    return 1, 2710, nil
end

function NetChampionShopQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2710, "ChampionShopQuery")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata:ChampionShop(ids)

    return { type = 2710, data = gamedata.cache.championShop,}
end



function UIChampionShopCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2711, "ChampionShop")
    local doData = ids_pb.Ids()

    local configdata = gamedata.config.champion_goods[tostring(uireq.goodid)]
    local spenddata = gamedata.getIDandNUMs(configdata.consume)

    if tonumber(spenddata[1]["cid"]) == 1001 and gamedata.cache.role.gold < tonumber(spenddata[1]["num"])*uireq.num then
        return  0, 503, {type = 503, msgtype = "shortgold"}
    elseif tonumber(spenddata[1]["cid"]) == 1000 and gamedata.cache.role.coin < tonumber(spenddata[1]["num"])*uireq.num then
        --return  0, 503, {type = 503, msg = "银币不足"}
        return  0, 503, {type = 503, msgtype = "shortcoin" }
    elseif tonumber(spenddata[1]["cid"]) == 1009 and gamedata.cache.championShop.championpoint and gamedata.cache.championShop.championpoint < tonumber(spenddata[1]["num"])*uireq.num then
        return  0, 503, {type = 503, msg = 271101 }
    else
        table.insert(doData.ids,uireq.id)
        table.insert(doData.ids,uireq.num)
        gamedata.ext.championshopid = uireq.goodid
        gamedata.ext.championshopNum = uireq.num

        return 1, 2711, doData:SerializeToString()
    end
end

function NetChampionShopCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2711, "ChampionShop")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    local configdata = gamedata.config.champion_goods[tostring(gamedata.ext.championshopid)]
    local spenddata = gamedata.getIDandNUMs(configdata.consume)

    if tonumber(spenddata[1]["cid"]) == 1001 then
        gamedata:updateRoleGold(0-tonumber(spenddata[1]["num"])*gamedata.ext.championshopNum,"冠军试炼商店"..gamedata.ext.championshopid,1)
    elseif tonumber(spenddata[1]["cid"]) == 1000 then
        gamedata:updateRoleCoin(0-tonumber(spenddata[1]["num"])*gamedata.ext.championshopNum,"冠军试炼商店"..gamedata.ext.championshopid,1)
    elseif tonumber(spenddata[1]["cid"]) == 1009 and gamedata.cache.championShop.championpoint then
        gamedata.cache.championShop.championpoint = gamedata.cache.championShop.championpoint-tonumber(spenddata[1]["num"]*gamedata.ext.championshopNum)
    end

    return { type = 2711, reward = gamedata:SomethingProcess(getData)}
end

-- 刷新
function UIChampionShopResetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2712, "ChampionShopReset")

    gamedata.ext.championShopResetGoldnum = uireq.xgold or 0

    if gamedata.cache.role.gold < tonumber(gamedata.ext.championShopResetGoldnum) then
        return  0, 503, {type = 503, msgtype = "shortgold"}
    else
        return 1, 2712, nil
    end

end

function NetChampionShopResetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2712, "ChampionShopReset")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata:ChampionShop(ids)

    if gamedata.ext.championShopResetGoldnum and gamedata.ext.championShopResetGoldnum > 0 then
        gamedata:updateRoleGold(0-gamedata.ext.championShopResetGoldnum,"冠军试炼商店刷新",1)
    end

    return { type = 2712, data = gamedata.cache.championShop,}
end

function UIChampionCompleteCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2705, "UIChampionCompleteCallBack")
    local ids = ids_pb.Ids()
    table.insert(ids.ids,uireq.path)
    table.insert(ids.ids,uireq.times)
    gamedata.ext.championComplete = uireq
    return 1, 2705, ids:SerializeToString()
end

function NetChampionCompleteCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2705, "NetChampionCompleteCallBack")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local reward = {}
    local info = {}
    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            info.all = ids.ids[1]
            info.success = ids.ids[2]
            info.fail = ids.ids[3]
            info.total = ids.ids[4]
            info.times = ids.ids[5]
            info.gold = ids.ids[6]

            gamedata:updateRoleGold(-info.gold, gamedata.ext.championComplete.res, 1)
        elseif v.id == 1 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
        end
    end

    return { type = 2705, info = info, reward = reward}

end