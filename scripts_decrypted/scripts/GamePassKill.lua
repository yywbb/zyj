--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/12/21
-- Time: 下午2:06
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local combmessages_pb = require("combmessages_pb")
local params_pb = require("params_pb")
local battleresult_pb = require("battleresult_pb")
local players_pb = require("players_pb")

-- 查询
function UIOverPassQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3820, "OverPass")
    print("UIOverPassQueryCallBack===")
    -- printT(uireq)

    -- local generalstempdata = {{i=202},{i=10110,s="莫言修杰"},{i=1222200},{i=0},{i=203},{i=10115,s="独木桥上的饕"},{i=1122200},{i=0},{i=204},{i=10114,s="图门修杰"},{i=1522200},{i=0}}
    -- local basicdata = {0,1,2,2,2,2,8889,12000}
    

    -- gamedata:passKillGeneralsDate(generalstempdata)
    -- gamedata:passKillBasicDate(basicdata)
    
    -- return 0, 3820, { type = 3820, passkill = gamedata.cache.passkill}

    return 1, 3820, nil
end

function NetOverPassQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3820, "OverPass")
    print("NetOverPassQueryCallBack===")
    local UsePorp = combmessages_pb.CombMessages()
    UsePorp:ParseFromString(fd.rbuf)

    for k,v in ipairs(UsePorp.messages) do
        print("messages===",v.id)
        if v.id == 0 then
            print("messages==in==",v.id)
            local params = params_pb.ParamS()
            params:ParseFromString(v.data)
            gamedata:passKillGeneralsDate(params.params)

        end


        if v.id == 1 then
            print("messages==ni==",v.id)
            -- printT(v.data)
            local  ids = ids_pb.Ids();
            ids:ParseFromString(v.data)
            gamedata:passKillBasicDate(ids.ids)
        end
    end


    return { type = 3820, passkill = gamedata.cache.passkill}
end


-- 刷新
function UIOverPassChangeBossCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3826, "GeneralsLove")
    print("UIOverPassChangeBossCallBack",uireq.spend)

    gamedata.ext.passkillrestSpend = uireq.spend
    
    -- local generalstempdata = {{i=202},{i=10110,s="莫言修杰02"},{i=1222200},{i=0},{i=203},{i=10115,s="独木桥上的饕02"},{i=1122200},{i=0},{i=204},{i=10114,s="图门修杰02"},{i=1522200},{i=0}}
    -- local basicdata = {0,1,2,2,2,2,8889,12000}
    

    -- gamedata:passKillGeneralsDate(generalstempdata)
    -- gamedata:passKillBasicDate(basicdata)
    
    -- return 0, 3826, { type = 3826, passkill = gamedata.cache.passkill}
    if uireq.spend > gamedata.cache.role.gold then
        return 0,503,{type = 503, msgtype = "shortgold" }
    end


    return 1, 3826, nil
end

function NetOverPassChangeBossCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3826, "GeneralsLove")
    -- print("NetOverPassChangeBossCallBack")
    -- printT(makeAllGeneralsTemp())
    local UsePorp = combmessages_pb.CombMessages()
    UsePorp:ParseFromString(fd.rbuf)

    for k,v in ipairs(UsePorp.messages) do
        print("messages===",v.id)
        if v.id == 0 then
            print("messages==in==",v.id)
            local params = params_pb.ParamS()
            params:ParseFromString(v.data)
            gamedata:passKillGeneralsDate(params.params)

        end


        if v.id == 1 then
            print("messages==ni==",v.id)
            -- printT(v.data)
            local  ids = ids_pb.Ids();
            ids:ParseFromString(v.data)
            gamedata:passKillBasicDate(ids.ids)
        end
    end

    gamedata:updateRoleGold(0-tonumber(gamedata.ext.passkillrestSpend),"过关斩将刷新",1)


    return { type = 3826, passkill = gamedata.cache.passkill }
end

-- 宝箱领奖
function UIOverPassGetRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3827, "GeneralLoveUseProp")
    print("UIOverPassGetRewardCallBack==")
    printT(uireq)
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id)
    gamedata.ext.OverPassGetRewardid = uireq.id


    return 1, 3827, idsData:SerializeToString()
end

function NetOverPassGetRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3827, "GeneralLoveUseProp")
    local  getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    gamedata.cache.passkill.basic["boxstatus"..gamedata.ext.OverPassGetRewardid] = 2

    return { type = 3827, reward = gamedata:SomethingProcess(getData),passkill = gamedata.cache.passkill}
end


-- 积分赛战斗
function UIOverPassBattleCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3824, "GeneralLoveTask")
    print("UIOverPassBattleCallBack")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.rid)

    gamedata.ext.OverPassBattleAuto = uireq.isauto or 0

    return 1, 3824, idsData:SerializeToString()
end

function NetOverPassBattleCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3824, "GeneralLoveTask")
    print("NetOverPassBattleCallBack")

    local NetOverPassResultPb = battleresult_pb.BattleResult()
    NetOverPassResultPb:ParseFromString(fd.rbuf)


    -- gamedata.cache.vipstatus.athletics_boss = gamedata.cache.vipstatus.athletics_boss +1

    return {
        type = 3824,
        result = NetOverPassResultPb.result,
        reward = gamedata:SomethingProcess(NetOverPassResultPb.reward),
        battlereport = PickBattleResultReport(NetOverPassResultPb),
        isauto = gamedata.ext.OverPassBattleAuto or 0,
    }
end

-- 积分赛排行查询
function UIOverPassRankCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3821, "OverPassShopQuery")
    print("UIOverPassRankCallBack===")
    -- printT(uireq)

    return 1, 3821, nil
end

function NetOverPassRankCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3821, "OverPassShopQuery")
    print("NetOverPassRankCallBack===")

    local playersData = players_pb.Players()
    playersData:ParseFromString(fd.rbuf)
    
    gamedata.cache.passkill.rank = gamedata:players(playersData.players) or {}


   
    -- local config = gamedata.config.favorable_task
    -- gamedata.cache.role.maxstamina = gamedata.cache.role.maxstamina + config
    printT(gamedata.cache.passkill.rank,"rank====")
    local myrank = {}
    myrank.rid = gamedata.cache.role.id
    myrank.name = gamedata.cache.role.name  
    myrank.power = gamedata.cache.role.f_power
    if gamedata.cache.passkill.basic then
        myrank.score = gamedata.cache.passkill.basic.killscorenum
    end
    -- myrank.score = gamedata.cache.passkill.basic.killscorenum
    


    return { type = 3821, rank = gamedata.cache.passkill.rank,myrank = myrank}
end

-- 积分赛 排行刷新（服务端 自动推）
function NetOverPassRankRefreshCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3825, "OverPassShopQuery")
    print("NetOverPassRankRefreshCallBack===")

    -- local OverPassReqData = result_pb.Result()
    -- OverPassReqData:ParseFromString(fd.rbuf)

    return { type = 3825, result = 1}
end

-- 商店查询
function UIOverPassShopCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3822, "OverPass")
    print("UIOverPassShopCallBack===")
    -- printT(uireq)

    -- local generalstempdata = {{i=202},{i=10110,s="莫言修杰"},{i=1222200},{i=0},{i=203},{i=10115,s="独木桥上的饕"},{i=1122200},{i=0},{i=204},{i=10114,s="图门修杰"},{i=1522200},{i=0}}
    -- local basicdata = {0,1,2,2,2,2,8889,12000}
    

    -- gamedata:passKillGeneralsDate(generalstempdata)
    -- gamedata:passKillBasicDate(basicdata)
    
    -- return 0, 3820, { type = 3820, passkill = gamedata.cache.passkill}

    return 1, 3822, nil
end

function NetOverPassShopCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3822, "OverPass")
    print("NetOverPassShopCallBack===")


    local  ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata:passKillShopDate(ids.ids)


    return { type = 3822, passkillshop = gamedata.cache.passkillshop}
end

-- 商店兑换
function UIOverPassShopBuyCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3823, "OverPass")
    print("UIOverPassShopBuyCallBack===")
    -- printT(uireq)

    -- local generalstempdata = {{i=202},{i=10110,s="莫言修杰"},{i=1222200},{i=0},{i=203},{i=10115,s="独木桥上的饕"},{i=1122200},{i=0},{i=204},{i=10114,s="图门修杰"},{i=1522200},{i=0}}
    -- local basicdata = {0,1,2,2,2,2,8889,12000}
    

    -- gamedata:passKillGeneralsDate(generalstempdata)
    -- gamedata:passKillBasicDate(basicdata)
    
    -- return 0, 3820, { type = 3820, passkill = gamedata.cache.passkill}
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id)
    table.insert(idsData.ids, uireq.num)

    return 1, 3823, idsData:SerializeToString()
end

function NetOverPassShopBuyCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3823, "OverPass")
    print("NetOverPassShopBuyCallBack===")

    local  getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)


    return { type = 3823, reward = gamedata:SomethingProcess(getData)}
end


--

function UIOverPassRefreshCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3828, "OverPassRefresh")

    gamedata.ext.passkillRefreshGold = uireq.xgold or 0

    if gamedata.ext.passkillRefreshGold > gamedata.cache.role.gold then
        return 0,503,{type = 503, msgtype = "shortgold" }
    end

    return 1, 3828, nil
end

function NetOverPassRefreshCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3828, "OverPassRefresh")

    local  ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata:passKillShopDate(ids.ids)

    if gamedata.ext.passkillRefreshGold > 0 then
        gamedata:updateRoleGold(0-tonumber(gamedata.ext.passkillRefreshGold),"过关斩将商店刷新",1)
    end

    return { type = 3828, passkillshop = gamedata.cache.passkillshop }
end

function UIOverPassRecordQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3829, "OverPassRecordQuery")

    return 1, 3829, nil
end

function NetOverPassRecordQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3829, "OverPassRecordQuery")

    local playersData = players_pb.Players()
    playersData:ParseFromString(fd.rbuf)
    return { type = 3829, players = gamedata:players(playersData.players) }
end

function UIOverPassRecordPlayCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3830, "OverPassRecordPlay")

    print(uireq.id)
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id)
    return 1, 3830, idsData:SerializeToString()
end

function NetOverPassRecordPlayCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3830, "OverPassRecordPlay")
    local copyAttackResultPb = battleresult_pb.BattleResult()
    copyAttackResultPb:ParseFromString(fd.rbuf)

    local t = {
        type = 3830,
        result = copyAttackResultPb.result,
        battlereport = PickBattleResultReport(copyAttackResultPb),
    }

    return t
end

function NetOverPassRecordUpdateCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3831, "OverPassRecordUpdate")

    return { type = 3831}
end �-  