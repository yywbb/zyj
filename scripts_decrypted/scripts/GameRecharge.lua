--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/1/21
-- Time: 下午3:40
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local result_pb = require("result_pb")

local params_pb = require("params_pb")

function UIUserBuyCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 301, "UserBuy")
    -- print("UIUserBuyCallBack===")
    -- printT(uireq)
    local UserBuyData = ids_pb.Ids()

    table.insert(UserBuyData.ids, uireq.cid)
    if uireq.count then
        table.insert(UserBuyData.ids, uireq.count)
    end

    gamedata.ext.UserBuyDatacid = uireq.cid
    gamedata.ext.UserBuyDatagold = uireq.gold or 0
    gamedata.ext.UserBuyDatacount = uireq.count or 1

    return 1, 301, UserBuyData:SerializeToString()
end

function NetUserBuyCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 301, "UserBuy")

    local Result = result_pb.Result()
    Result:ParseFromString(fd.rbuf)

    local name, amount = "", 0
    local stamina = tonumber(gamedata.config.global_kv.basic_buy_stamina.value)
    local energy = tonumber(gamedata.config.global_kv.basic_buy_energy.value)

    if gamedata.ext.UserBuyDatacid == 1 then
        gamedata.cache.vipstatus.b_athletics  = gamedata.cache.vipstatus.b_athletics +gamedata.ext.UserBuyDatacount
        name = "竞技场次数"
        amount = 1*gamedata.ext.UserBuyDatacount
    elseif gamedata.ext.UserBuyDatacid == 2 then
        gamedata:updateRoleStamina(stamina*gamedata.ext.UserBuyDatacount)
        gamedata.cache.vipstatus.b_physical  = gamedata.cache.vipstatus.b_physical +gamedata.ext.UserBuyDatacount
        name = "体力"
        amount = stamina*gamedata.ext.UserBuyDatacount
    elseif gamedata.ext.UserBuyDatacid == 3 then
        gamedata:updateRoleEnergy(energy*gamedata.ext.UserBuyDatacount)
        gamedata.cache.vipstatus.b_energy  = gamedata.cache.vipstatus.b_energy +gamedata.ext.UserBuyDatacount
        name = "精力"
        amount = energy*gamedata.ext.UserBuyDatacount
    elseif gamedata.ext.UserBuyDatacid == 4 then
        gamedata.cache.vipstatus.friendcopy_times  = gamedata.cache.vipstatus.friendcopy_times +gamedata.ext.UserBuyDatacount
        name = "好友副本挑战次数"
        amount = 1*gamedata.ext.UserBuyDatacount
    elseif gamedata.ext.UserBuyDatacid == 5 then
        gamedata.cache.vipstatus.bzxtrst  = gamedata.cache.vipstatus.bzxtrst +gamedata.ext.UserBuyDatacount
        name = "灭神殿重置次数"
        amount = 1*gamedata.ext.UserBuyDatacount
    elseif gamedata.ext.UserBuyDatacid == 6 then
        gamedata.cache.vipstatus.personalboss_times  = gamedata.cache.vipstatus.personalboss_times +gamedata.ext.UserBuyDatacount
        name = "王的男人挑战次数"
        amount = 1*gamedata.ext.UserBuyDatacount
    elseif gamedata.ext.UserBuyDatacid == 7 then
        gamedata.cache.vipstatus.coin_copy_times  = gamedata.cache.vipstatus.coin_copy_times +gamedata.ext.UserBuyDatacount
        name = "金币活动副本"
        amount = 1*gamedata.ext.UserBuyDatacount
    elseif gamedata.ext.UserBuyDatacid == 8 then
        gamedata.cache.vipstatus.exp_copy_times  = gamedata.cache.vipstatus.exp_copy_times +gamedata.ext.UserBuyDatacount
        name = "经验活动副本"
        amount = 1*gamedata.ext.UserBuyDatacount
    elseif gamedata.ext.UserBuyDatacid == 9 then
        gamedata.cache.vipstatus.stone_copy_times  = gamedata.cache.vipstatus.stone_copy_times +gamedata.ext.UserBuyDatacount        
        name = "锻造石活动副本"
        amount = 1*gamedata.ext.UserBuyDatacount        
    elseif gamedata.ext.UserBuyDatacid == 10 then
        gamedata.cache.vipstatus.through_times  = gamedata.cache.vipstatus.through_times +gamedata.ext.UserBuyDatacount        
        name = "过关斩将挑战次数"
        amount = 1*gamedata.ext.UserBuyDatacount
    elseif gamedata.ext.UserBuyDatacid == 11 then
        gamedata.cache.vipstatus.upstar_times  = gamedata.cache.vipstatus.upstar_times +gamedata.ext.UserBuyDatacount
        name = "升星石副本挑战次数"
        amount = 1*gamedata.ext.UserBuyDatacount
    elseif gamedata.ext.UserBuyDatacid == 12 then
        gamedata.cache.vipstatus.zhenfu_times  = gamedata.cache.vipstatus.zhenfu_times +gamedata.ext.UserBuyDatacount
        name = "阵符副本挑战次数"
        amount = 1*gamedata.ext.UserBuyDatacount
    elseif gamedata.ext.UserBuyDatacid == 13 then
        gamedata.cache.vipstatus.home_challenge_times  = gamedata.cache.vipstatus.home_challenge_times +gamedata.ext.UserBuyDatacount
        name = "藏经阁协助次数"
        amount = 1*gamedata.ext.UserBuyDatacount
    elseif gamedata.ext.UserBuyDatacid == 14 then
        gamedata.cache.vipstatus.sociaty_boss_order  = gamedata.cache.vipstatus.sociaty_boss_order +gamedata.ext.UserBuyDatacount
        name = "公会BOSS挑战次数"
        amount = 1*gamedata.ext.UserBuyDatacount
    elseif gamedata.ext.UserBuyDatacid == 15 then
        gamedata.cache.vipstatus.b_hall  = gamedata.cache.vipstatus.b_hall +gamedata.ext.UserBuyDatacount
        name = "道馆守卫参战次数"
        amount = 1*gamedata.ext.UserBuyDatacount
    elseif gamedata.ext.UserBuyDatacid == 16 then
        gamedata.cache.vipstatus.b_hero_boss  = gamedata.cache.vipstatus.b_hero_boss +gamedata.ext.UserBuyDatacount
        name = "英雄挑战参战次数"
        amount = 1*gamedata.ext.UserBuyDatacount
    elseif gamedata.ext.UserBuyDatacid == 17 then
        gamedata.cache.vipstatus.forging_copy_times  = gamedata.cache.vipstatus.forging_copy_times +gamedata.ext.UserBuyDatacount
        name = "注灵石副本挑战次数"
        amount = 1*gamedata.ext.UserBuyDatacount
    elseif gamedata.ext.UserBuyDatacid == 18 then
        gamedata.cache.vipstatus.xianku_cishu  = gamedata.cache.vipstatus.xianku_cishu +gamedata.ext.UserBuyDatacount
        name = "福祉仙宫副本挑战次数"
        amount = 1*gamedata.ext.UserBuyDatacount
    elseif gamedata.ext.UserBuyDatacid == 20 then
        gamedata.cache.vipstatus.game_2048_times = gamedata.cache.vipstatus.game_2048_times + gamedata.ext.UserBuyDatacount
        name = "作妖2048挑战次数"
        amount = 1*gamedata.ext.UserBuyDatacount

    end
    gamedata:updateRoleGold(-gamedata.ext.UserBuyDatagold,name,amount)

    return { type = 301, order = gamedata.ext.UserBuyDatacid, gold = gamedata.ext.UserBuyDatagold, count = gamedata.ext.UserBuyDatacount}
end

-------------------------------------------------------------------------------------------------------------

function UIAppStorePay( uireq )

    cclog("NET type:%d cmd:%s recv request from UI", 20000, "UIAppStorePay")
    local AppStorePayData = params_pb.ParamS()
    local paramdata = AppStorePayData.params:add()
    paramdata.s = uireq.appdata
    local paramdata2 = AppStorePayData.params:add()
    paramdata2.s = uireq.apporderId
    return 1, 20000, AppStorePayData:SerializeToString()
 end 




function UIRechargePreCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 115, "RechargePre")
    local RechargePreData = params_pb.ParamS()
    local paramdata = RechargePreData.params:add()
    paramdata.i = uireq.cid

    if uireq.bagid then
        local paramdata2 = RechargePreData.params:add()
        paramdata2.i = uireq.bagid
    end

    gamedata.ext.recahrgecid = uireq.cid

    return 1, 115, RechargePreData:SerializeToString()
end

function NetRechargePreCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 115, "RechargePre")

    local Result = params_pb.ParamS()
    Result:ParseFromString(fd.rbuf)


    local order = Result.params[1].i

    local rechargeData = {}

    for k,v in ipairs(Result.params) do
        rechargeData[k] = {i=v.i,s=v.s}
    end

    gamedata.ext.isrechare = true
    return {type = 115, rechargeData = rechargeData, cid = gamedata.ext.recahrgecid}


end


function UIRechageSuccessCallback(uireq)
    cclog("NET type:%d cmd:%s recv response from gameserver", 116, "UIRechageSuccess")

    local rechageSuccess = ids_pb.Ids()
    table.insert(rechageSuccess.ids, uireq.order)
   
    return 1, 116, rechageSuccess:SerializeToString()

end



function NetRechargeResultCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 116, "RechargeResult")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    local reward = gamedata:SomethingProcess(SomeThings)

    if next(reward) then
        gamedata.ext.isrechare = false
    end

    return { type = 116, reward = reward}
end

function UIVipCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 117, "Vip")

    if next(gamedata.cache.vip) and not uireq.update then
        return 0, 117, {type = 117, vip = gamedata.cache.vip}
    else
        return 1, 117, nil
    end
end

function NetVipCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 117, "vip")
    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    gamedata:Vip(Result.ids)

    return { type = 117, vip = gamedata.cache.vip,isup = fd.ser and fd.ser ==0 }
end

function UIVipStatusCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 300, "VipStatus")
    if next(gamedata.cache.vipstatus) and not uireq.update then
        return 0, 300, {type = 300, vipstatus = gamedata.cache.vipstatus}
    else
        return 1, 300, nil
    end

    return 1, 300, nil
end

function NetVipStatusCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 300, "VipStatus")

    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)
    gamedata:Vipstatus(Result.ids)

    return { type = 300, vipstatus = gamedata.cache.vipstatus}
end

------------------------------------------------------------------------------------------------------------------------------------------------------

function UIMonthCardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2090, "MonthCard")

    if not checkActivityStatus(5) then
        return  0, 503, {type = 503}
    end

    if next(gamedata.cache.monthcard) and not uireq.update then
        return 0, 2090, {type = 2090, monthcard = gamedata.cache.monthcard}
    else
        return 1, 2090, nil
    end

end

function NetMonthCardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2090, "MonthCard")

    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    gamedata:MonthCard(Result.ids)

    return { type = 2090, monthcard = gamedata.cache.monthcard}
end

function UIMonthCardGetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2091, "MonthCardGet")
    local MonthCardGetData = ids_pb.Ids()

    table.insert(MonthCardGetData.ids, uireq.cid)

    gamedata.ext.MonthCardGetid = uireq.cid

    return 1, 2091, MonthCardGetData:SerializeToString()
end

function NetMonthCardGetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2091, "MonthCardGet")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    gamedata.cache.monthcard[gamedata.ext.MonthCardGetid].status = 2

    return { type = 2091, monthcard = gamedata.cache.monthcard,reward = gamedata:SomethingProcess(SomeThings)}
end

------------------------------------------------------------------------------------------------------------------------------------------------------

function UIMonthCardRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2092, "MonthCardReward")

    if not checkActivityStatus(8) then
        return  0, 503, {type = 503}
    end

    if next(gamedata.cache.monthcardreward) and not uireq.update then
        return 0, 2092, {type = 2092, monthcardreward = gamedata.cache.monthcardreward}
    else
        return 1, 2092, nil
    end

end

function NetMonthCardRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2092, "MonthCardReward")

    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    gamedata:MonthCardReward(Result.ids)

    return { type = 2092, monthcardreward = gamedata.cache.monthcardreward}
end

function UIMonthCardRewardGetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2093, "MonthCardRewardGet")
    local MonthCardRewardGetData = ids_pb.Ids()

    table.insert(MonthCardRewardGetData.ids, uireq.cid)

    gamedata.ext.MonthCardrewardGetid = uireq.cid

    return 1, 2093, MonthCardRewardGetData:SerializeToString()
end

function NetMonthCardRewardGetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2093, "MonthCardRewardGet")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    gamedata.cache.monthcardreward[gamedata.ext.MonthCardrewardGetid] = 2

    return { type = 2093, monthcardreward = gamedata.cache.monthcardreward,reward = gamedata:SomethingProcess(SomeThings)}
end

------------------------------------------------------------------------------------------------------------------------------------------------------

local function makegrowplan()
    local ret = {
        hasbuy = #gamedata.cache.growplan,
        rewards = {}
    }
    for k,v in ipairs(gamedata.cache.growplan) do
        if v == 1 then
            table.insert(ret.rewards,{id=k,status = v,order = 3})
        elseif v == 2 then
            table.insert(ret.rewards,{id=k,status = v,order = 1})
        else
            table.insert(ret.rewards,{id=k,status = v,order = 2})
        end
    end
    if #gamedata.cache.growplan<=0 then
        for i=1,table.getTableLength(gamedata.config.growplan) do
            table.insert(ret.rewards,{id=i,status = 0,order = 2})
        end
    end

    local sortfunc = function(a,b)
        if a.order > b.order then
            return true
        elseif a.order < b.order then
            return false
        else
            return (a.id < b.id)
        end
    end

    table.sort(ret.rewards,sortfunc)

    return ret
end

function UIGrowPlanCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2094, "GrowPlan")

    if not checkActivityStatus(7) then
        return  0, 503, {type = 503}
    end

    if next(gamedata.cache.growplan) and not uireq.update then
        return 0, 2094, {type = 2094, growplan = makegrowplan()}
    else
        return 1, 2094, nil
    end

end

function NetGrowPlanCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2094, "GrowPlan")

    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    gamedata:GrowPlan(Result.ids)

    return { type = 2094, growplan = makegrowplan()}
end

function UIGrowPlanBuyCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2095, "GrowPlanBuy")

    return 1, 2095, nil
end

function NetGrowPlanBuyCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2095, "GrowPlanBuy")

    local Result = result_pb.Result()
    Result:ParseFromString(fd.rbuf)

    print(Result.result)
    if Result.result then
        gamedata:updateRoleGold(-1000,"成长计划",1)
    end

    return { type = 2095, Result = Result.result}
end

function UIGrowPlanRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2096, "GrowPlanReward")
    local MonthCardRewardGetData = ids_pb.Ids()

    table.insert(MonthCardRewardGetData.ids, uireq.cid)

    gamedata.ext.GrowPlanRewardid = uireq.cid

    return 1, 2096, MonthCardRewardGetData:SerializeToString()
end

function NetGrowPlanRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2096, "GrowPlanReward")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    gamedata.cache.growplan[gamedata.ext.GrowPlanRewardid] = 2

    return { type = 2096, growplan = makegrowplan(),reward = gamedata:SomethingProcess(SomeThings)}
end

---------
local function makegrowplanx1()
    local ret = {
        hasbuy = #gamedata.cache.growplanx1.status,
        rewards = {},
        stage = gamedata.cache.growplanx1.stage
    }

    local stage = gamedata.cache.growplanx1.stage

    for k,v in ipairs(gamedata.cache.growplanx1.status) do
        local id = gamedata.config.growplan_x1[tostring(stage)][tostring(k)].id
        if v == 1 then
            table.insert(ret.rewards,{id=id,status = v,order = 3})
        elseif v == 2 then
            table.insert(ret.rewards,{id=id,status = v,order = 1})
        else
            table.insert(ret.rewards,{id=id,status = v,order = 2})
        end
    end
    
    if #gamedata.cache.growplanx1.status<=0 then
        for i=1,table.getTableLength(gamedata.config.growplan_x1[tostring(stage)]) do
            table.insert(ret.rewards,{id=gamedata.config.growplan_x1[tostring(stage)][tostring(i)].id,status = 0,order = 2})
        end
    end

    local sortfunc = function(a,b)
        if a.order > b.order then
            return true
        elseif a.order < b.order then
            return false
        else
            return (a.id < b.id)
        end
    end

    table.sort(ret.rewards,sortfunc)

    return ret
end

function UIGrowPlan2CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 7091, "GrowPlan")

    if not checkActivityStatus(149) then
        return  0, 503, {type = 503}
    end

    if next(gamedata.cache.growplanx1) and not uireq.update then
        return 0, 7091, {type = 7091, growplan = makegrowplanx1()}
    else
        return 1, 7091, nil
    end

end

function NetGrowPlan2CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7091, "GrowPlan")

    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    gamedata:GrowPlanx1(Result.ids)

    return { type = 7091, growplan = makegrowplanx1()}
end

function UIGrowPlan2BuyCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 7092, "GrowPlanBuy")

    return 1, 7092, nil
end

function NetGrowPlan2BuyCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7092, "GrowPlanBuy")

    local Result = result_pb.Result()
    Result:ParseFromString(fd.rbuf)

    print(Result.result)
    if Result.result then
        gamedata:updateRoleGold(-1000,"成长计划",1)
    end

    return { type = 7092, Result = Result.result}
end

function UIGrowPlan2RewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 7093, "GrowPlanReward")
    local MonthCardRewardGetData = ids_pb.Ids()

    table.insert(MonthCardRewardGetData.ids, uireq.cid)

    gamedata.ext.GrowPlanRewardidx1 = uireq.cid

    return 1, 7093, MonthCardRewardGetData:SerializeToString()
end

function NetGrowPlan2RewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7093, "GrowPlanReward")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    gamedata.cache.growplanx1.status[gamedata.ext.GrowPlanRewardidx1] = 2

    return { type = 7093, growplan = makegrowplanx1(),reward = gamedata:SomethingProcess(SomeThings)}
end

local function makegrowplanGlobal()

    local ret = {
        totalnum= gamedata.cache.growplanGlobal.totalnum,
        rewards={}
    }
    for k,v in ipairs(gamedata.cache.growplanGlobal.rewards) do
        if v == 1 then
            table.insert(ret.rewards,{id=k,status = v,order = 3})
        elseif v == 2 then
            table.insert(ret.rewards,{id=k,status = v,order = 1})
        else
            table.insert(ret.rewards,{id=k,status = v,order = 2})
        end
    end
    if #gamedata.cache.growplanGlobal.rewards<=0 then
        for i=1,table.getTableLength(gamedata.config:getConfigByName("growplan_global")) do
            table.insert(ret.rewards,{id=i,status = 0,order = 2})
        end
    end

    local sortfunc = function(a,b)
        if a.order > b.order then
            return true
        elseif a.order < b.order then
            return false
        else
            return (a.id < b.id)
        end
    end

    table.sort(ret.rewards,sortfunc)

    return ret

end

local function makegrowplanGlobalx1()

    local ret = {
        totalnum= gamedata.cache.growplanGlobalx1.totalnum,
        stage = gamedata.cache.growplanGlobalx1.stage,
        rewards={}
    }
    for k,v in ipairs(gamedata.cache.growplanGlobalx1.rewards) do
        if v == 1 then
            table.insert(ret.rewards,{id=k,status = v,order = 3})
        elseif v == 2 then
            table.insert(ret.rewards,{id=k,status = v,order = 1})
        else
            table.insert(ret.rewards,{id=k,status = v,order = 2})
        end
    end
    if #gamedata.cache.growplanGlobalx1.rewards<=0 then
        for i=1,table.getTableLength(gamedata.config:getConfigByName("growplan_global_x1")) do
            table.insert(ret.rewards,{id=i,status = 0,order = 2})
        end
    end

    local sortfunc = function(a,b)
        if a.order > b.order then
            return true
        elseif a.order < b.order then
            return false
        else
            return (a.id < b.id)
        end
    end

    table.sort(ret.rewards,sortfunc)

    return ret

end

function UIGrowPlanGlobalCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4000, "GrowPlanGlobal")
    return 1,4000,nil
end

function NetGrowPlanGlobalCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4000, "GrowPlanGlobal")
    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)
    gamedata:GrowPlanGlobal(Result.ids)

    return {type = 4000, growplanGlobal = makegrowplanGlobal() }
end

function UIGrowPlanGlobalRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4001, "GrowPlanGlobalReward")
    local GrowPlanGlobalRewardData = ids_pb.Ids()

    table.insert(GrowPlanGlobalRewardData.ids, uireq.id)

    gamedata.ext.GrowPlanGlobalRewardDataid = uireq.id

    return 1, 4001, GrowPlanGlobalRewardData:SerializeToString()
end

function NetGrowPlanGlobalRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4001, "GrowPlanGlobalReward")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    gamedata.cache.growplanGlobal.rewards[gamedata.ext.GrowPlanGlobalRewardDataid] = 2

    return { type = 4001, growplanGlobal = makegrowplanGlobal(),reward = gamedata:SomethingProcess(SomeThings)}

end

function UIGrowPlan2GlobalCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 7094, "GrowPlanGlobal")
    return 1,7094,nil
end

function NetGrowPlan2GlobalCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7094, "GrowPlanGlobal")
    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)
    gamedata:GrowPlanGlobalx1(Result.ids)

    return {type = 7094, growplanGlobal = makegrowplanGlobalx1() }
end

function UIGrowPlan2GlobalRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 7095, "GrowPlanGlobalReward")
    local GrowPlanGlobalRewardData = ids_pb.Ids()

    table.insert(GrowPlanGlobalRewardData.ids, uireq.id)

    gamedata.ext.GrowPlanGlobalRewardDataid = uireq.id

    return 1, 7095, GrowPlanGlobalRewardData:SerializeToString()
end

function NetGrowPlan2GlobalRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7095, "GrowPlanGlobalReward")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    gamedata.cache.growplanGlobalx1.rewards[gamedata.ext.GrowPlanGlobalRewardDataid] = 2

    return { type = 7095, growplanGlobal = makegrowplanGlobalx1(),reward = gamedata:SomethingProcess(SomeThings)}

end


local function GrowPlan_common(data)
    local growplan = {
        status = {},
        stage = 1,
    }

    for k,v in ipairs(data) do
        if k==1 then
            growplan.stage = v
        else
            table.insert(growplan.status,v)
        end
    end
    return growplan
end

local function makeGrowplan_common(growplanGlobal,activityid)

    local configName = ""
    if activityid == 178 then
        configName = "growplan_x2"
    elseif activityid == 179 then
        configName = "growplan_x3"
    end

    local ret = {
        hasbuy = #growplanGlobal.status,
        rewards = {},
        stage = growplanGlobal.stage
    }

    local stage = growplanGlobal.stage

    for k,v in ipairs(growplanGlobal.status) do
        local id = gamedata.config[configName][tostring(stage)][tostring(k)].id
        if v == 1 then
            table.insert(ret.rewards,{id=id,status = v,order = 3})
        elseif v == 2 then
            table.insert(ret.rewards,{id=id,status = v,order = 1})
        else
            table.insert(ret.rewards,{id=id,status = v,order = 2})
        end
    end
    
    if #growplanGlobal.status<=0 then
        for i=1,table.getTableLength(gamedata.config[configName][tostring(stage)]) do
            table.insert(ret.rewards,{id=gamedata.config[configName][tostring(stage)][tostring(i)].id,status = 0,order = 2})
        end
    end

    local sortfunc = function(a,b)
        if a.order > b.order then
            return true
        elseif a.order < b.order then
            return false
        else
            return (a.id < b.id)
        end
    end

    table.sort(ret.rewards,sortfunc)

    return ret
end

function UIGrowPlan4CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 8120, "GrowPlanGlobal")
    if not checkActivityStatus(178) then
        return  0, 503, {type = 503}
    end

    return 1,8120,nil
end

function NetGrowPlan4CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8120, "GrowPlanGlobal")
    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    for i,v in ipairs(Result.ids) do
        print(i,v)
    end
    gamedata.cache.growplan3 = GrowPlan_common(Result.ids)
    return {type = 8120, growplan = makeGrowplan_common(gamedata.cache.growplan3,178)}
end

function UIGrowPlan4RewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 8121, "GrowPlanGlobalReward")
    printT(uireq,"UIGrowPlan4RewardCallBack")
    local GrowPlanGlobalRewardData = ids_pb.Ids()
    table.insert(GrowPlanGlobalRewardData.ids, uireq.cid)
    gamedata.ext.GrowPlanRewardDataid3 = uireq.cid
    return 1, 8121, GrowPlanGlobalRewardData:SerializeToString()
end

function NetGrowPlan4RewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8121, "GrowPlanGlobalReward")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    gamedata.cache.growplan3.status[gamedata.ext.GrowPlanRewardDataid3] = 2

    return { type = 8121, growplan = makeGrowplan_common(gamedata.cache.growplan3,178),reward = gamedata:SomethingProcess(SomeThings)}
end


function UIGrowPlan5CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 8122, "GrowPlanGlobal")
    if not checkActivityStatus(179) then
        return  0, 503, {type = 503}
    end

    return 1,8122,nil
end

function NetGrowPlan5CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8122, "GrowPlanGlobal")
    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)
    gamedata.cache.growplan4 = GrowPlan_common(Result.ids)
    return {type = 8122, growplan = makeGrowplan_common(gamedata.cache.growplan4,179)}
end

function UIGrowPlan5RewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 8123, "GrowPlanGlobalReward")
    local GrowPlanGlobalRewardData = ids_pb.Ids()
    table.insert(GrowPlanGlobalRewardData.ids, uireq.cid)
    gamedata.ext.GrowPlanRewardDataid4 = uireq.cid
    return 1, 8123, GrowPlanGlobalRewardData:SerializeToString()
end

function NetGrowPlan5RewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8123, "GrowPlanGlobalReward")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    gamedata.cache.growplan4.status[gamedata.ext.GrowPlanRewardDataid4] = 2

    return { type = 8123, growplan = makeGrowplan_common(gamedata.cache.growplan4,179),reward = gamedata:SomethingProcess(SomeThings)}
end

------------------------------------------------------------------------------------------------------------------------------------------------------

function UIRechargeDoubleCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2097, "RechargeDouble")

    if not checkActivityStatus(6) then
        return  0, 503, {type = 503}
    end

    return 1, 2097, nil
end

function NetRechargeDoubleCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2097, "RechargeDouble")

    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    local rechargedouble = {}
    for k,v in ipairs(Result.ids) do
        table.insert(rechargedouble,v)
    end

    return { type = 2097, rechargedouble = rechargedouble}
end

---------------------------------------------------------------------------------------------------------------

function UIFirstRechargeRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2098, "FirstRechargeReward")

    return 1, 2098, nil
end

function NetFirstRechargeRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2098, "FirstRechargeReward")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    gamedata.cache.vip.firststatus = 2


    return { type = 2098, vip = gamedata.cache.vip, reward = gamedata:SomethingProcess(SomeThings)}
end

---------------------------------------------------------------------------------------------------------------

function UIFirstRechargeStatusCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2099, "FirstRechargeStatus")

    return 1, 2099, nil
end

function NetFirstRechargeStatusCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2099, "FirstRechargeStatus")

    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    local status = {}
    for k,v in ipairs(Result.ids) do
        table.insert(status,v)
    end

    return { type = 2099, status = status }
end


--
function UIRechargeDouble2CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4006, "RechargeDouble2")

    if not checkActivityStatus(76) then
        return  0, 503, {type = 503}
    end

    return 1, 4006, nil

end

function NetRechargeDouble2CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4006, "RechargeDouble2")

    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    local rechargedouble = {}
    for k,v in ipairs(Result.ids) do
        table.insert(rechargedouble,v)
    end

    return { type = 4006, rechargedouble = rechargedouble}
end


--cp
function UICPRechargeDoubleCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5034, "RechargeDouble")

    if not checkActivityStatus(87) then
        return  0, 503, {type = 503}
    end

    return 1, 5034, nil

end

function NetCPRechargeDoubleCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5034, "RechargeDouble")

    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    local cpnum = Result.ids[1] or 0
    local cpday = Result.ids[2] or 0

    gamedata.cache.rechargedouble_cp = {}
    for k,v in ipairs(Result.ids) do
        if k >= 3 then
            table.insert(gamedata.cache.rechargedouble_cp,v)
        end
    end

    return { type = 5034, rechargedouble = gamedata.cache.rechargedouble_cp, cpnum = cpnum, cpday = cpday}
end

function UIForeverRechargeQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5319, "ForeverRechargeQuery")

    if gamedata.cache.foreverRechargeData and next(gamedata.cache.foreverRechargeData) then
        local nowrmb = gamedata.cache.vip.rmb 
        if gamedata.cache.foreverRechargeData.realrmb == nowrmb then
            return 0, 5319, { type = 5319, data = gamedata.cache.foreverRechargeData }
        end
    end
    
    return 1, 5319, nil
end

function NetForeverRechargeQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5319, "vip")
    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    local foreverRechargeData = {}
    foreverRechargeData.id = Result.ids[1] or 1
    foreverRechargeData.status = Result.ids[2] or 0
    foreverRechargeData.totalRmb = Result.ids[3] or 0
    foreverRechargeData.realrmb = gamedata.cache.vip.rmb or 0

    gamedata.cache.foreverRechargeData = foreverRechargeData

    return { type = 5319, data = foreverRechargeData }
end

function UIForeverRechargeRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5320, "ForeverRechargeReward")

    return 1, 5320, nil
end

function NetForeverRechargeRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5320, "ForeverRechargeReward")

    local SomeThings = somethings_pb.SomeThings()
    printT(fd.rbuf,"Lipurpose")
    SomeThings:ParseFromString(fd.rbuf)
    print("Lipurpose ".."come To")
    --printT(SomeThings,"Lipurpose")
    gamedata.cache.foreverRechargeData = nil
    print("Lipurpose ".."come end")
    return { type = 5320, reward = gamedata:SomethingProcess(SomeThings)}
end


-------------------------- 活动ID 167
function UIWeekFundQueryX1CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 8071, "WeekFundQuery")

    return 1, 8071, nil
end

function NetWeekFundQueryX1CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8071, "WeekFundQuery")

    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    local weekFundData = {}
    weekFundData.rechargeStatus = Result.ids[1] or 0
    weekFundData.status = {}
    for i=1,7 do
        weekFundData.status[i] = Result.ids[i + 1] or 0
    end

    printT(weekFundData,"weekFundData")
    return { type = 8071, weekFundData = weekFundData}
end

function UIWeekFundAwardX1CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 8072, "WeekFundAward")

    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.id)
    return 1, 8072, ids:SerializeToString()
end

function NetWeekFundAwardX1CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8072, "WeekFundAward")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    return { type = 8072, reward = gamedata:SomethingProcess(SomeThings)}
end


-------------------------- 活动ID 168
function UIWeekFundQueryX2CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 8073, "WeekFundQuery")

    return 1, 8073, nil
end

function NetWeekFundQueryX2CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8073, "WeekFundQuery")

    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    local weekFundData = {}
    weekFundData.rechargeStatus = Result.ids[1] or 0
    weekFundData.status = {}
    for i=1,7 do
        weekFundData.status[i] = Result.ids[i + 1] or 0
    end

    return { type = 8073, weekFundData = weekFundData}
end

function UIWeekFundAwardX2CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 8074, "WeekFundAward")

    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.id)
    return 1, 8074, ids:SerializeToString()
end

function NetWeekFundAwardX2CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8074, "WeekFundAward")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    return { type = 8074, reward = gamedata:SomethingProcess(SomeThings)}
end

-------------------------- 活动ID 169
function UICPWeekFundQueryX1CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 8075, "WeekFundQuery")

    return 1, 8075, nil
end

function NetCPWeekFundQueryX1CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8075, "WeekFundQuery")

    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    local weekFundData = {}
    weekFundData.rechargeStatus = Result.ids[1] or 0
    weekFundData.status = {}
    for i=1,7 do
        weekFundData.status[i] = Result.ids[i + 1] or 0
    end

    return { type = 8075, weekFundData = weekFundData}
end

function UICPWeekFundAwardX1CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 8076, "WeekFundAward")

    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.id)
    return 1, 8076, ids:SerializeToString()
end

function NetCPWeekFundAwardX1CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8076, "WeekFundAward")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    return { type = 8076, reward = gamedata:SomethingProcess(SomeThings)}
end

-------------------------- 活动ID 170
function UICPWeekFundQueryX2CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 8077, "WeekFundQuery")

    return 1, 8077, nil
end

function NetCPWeekFundQueryX2CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8077, "WeekFundQuery")

    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    local weekFundData = {}
    weekFundData.rechargeStatus = Result.ids[1] or 0
    weekFundData.status = {}
    for i=1,7 do
        weekFundData.status[i] = Result.ids[i + 1] or 0
    end

    return { type = 8077, weekFundData = weekFundData}
end

function UICPWeekFundAwardX2CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 8078, "WeekFundAward")

    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.id)
    return 1, 8078, ids:SerializeToString()
end

function NetCPWeekFundAwardX2CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8078, "WeekFundAward")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    return { type = 8078, reward = gamedata:SomethingProcess(SomeThings)}
end


-------------------------- 活动ID 171
function UIRCWeekFundQueryX1CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 8079, "WeekFundQuery")

    return 1, 8079, nil
end

function NetRCWeekFundQueryX1CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8079, "WeekFundQuery")

    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    local weekFundData = {}
    weekFundData.rechargeStatus = Result.ids[1] or 0
    weekFundData.status = {}
    for i=1,7 do
        weekFundData.status[i] = Result.ids[i + 1] or 0
    end

    return { type = 8079, weekFundData = weekFundData}
end

function UIRCWeekFundAwardX1CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 8080, "WeekFundAward")

    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.id)
    return 1, 8080, ids:SerializeToString()
end

function NetRCWeekFundAwardX1CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8080, "WeekFundAward")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    return { type = 8080, reward = gamedata:SomethingProcess(SomeThings)}
end

-------------------------- 活动ID 172
function UIRCWeekFundQueryX2CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 8081, "WeekFundQuery")

    return 1, 8081, nil
end

function NetRCWeekFundQueryX2CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8081, "WeekFundQuery")

    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    local weekFundData = {}
    weekFundData.rechargeStatus = Result.ids[1] or 0
    weekFundData.status = {}
    for i=1,7 do
        weekFundData.status[i] = Result.ids[i + 1] or 0
    end

    return { type = 8081, weekFundData = weekFundData}
end

function UIRCWeekFundAwardX2CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 8082, "WeekFundAward")

    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.id)
    return 1, 8082, ids:SerializeToString()
end

function NetRCWeekFundAwardX2CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8082, "WeekFundAward")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    return { type = 8082, reward = gamedata:SomethingProcess(SomeThings)}
end

-- --------------------
-- #活动id 167
-- #8071 WeekFundQuery

-- 传入 无
-- 传出 ids_pb
--     ids[购买状态、奖励状态1、奖励状态2...7] (购买状态 0/1 未购买/已购买 奖励状态 0/1/2 未激活/可领取/已领取)

-- #8072 WeekFundAward

-- 传入 ids_pb
--     ids[id] (id 1-7)
-- 传出 somethings_pb

-- --------------------
-- #活动id 168
-- #8073 WeekFundQuery

-- 传入 无
-- 传出 ids_pb
--     ids[购买状态、奖励状态1、奖励状态2...7] (购买状态 0/1 未购买/已购买 奖励状态 0/1/2 未激活/可领取/已领取)

-- #8074 WeekFundAward

-- 传入 ids_pb
--     ids[id] (id 1-7)
-- 传出 somethings_pb

-- --------------------
-- #活动id 169
-- #轮换 轮换信息需2000接口返回
-- #8075 WeekFundQuery

-- 传入 无
-- 传出 ids_pb
--     ids[购买状态、奖励状态1、奖励状态2...7] (购买状态 0/1 未购买/已购买 奖励状态 0/1/2 未激活/可领取/已领取)

-- #8076 WeekFundAward

-- 传入 ids_pb
--     ids[id] (id 1-7)
-- 传出 somethings_pb

-- --------------------
-- #活动id 170
-- #轮换 轮换信息需2000接口返回
-- #8077 WeekFundQuery

-- 传入 无
-- 传出 ids_pb
--     ids[购买状态、奖励状态1、奖励状态2...7] (购买状态 0/1 未购买/已购买 奖励状态 0/1/2 未激活/可领取/已领取)

-- #8078 WeekFundAward

-- 传入 ids_pb
--     ids[id] (id 1-7)
-- 传出 somethings_pb


 ��  