--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/1/7
-- Time: 下午5:47
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local worldboss1_pb = require("worldboss1_pb")
local worldboss1realnotify_pb = require("worldboss1realnotify_pb")
local worldboss1rank_pb = require("worldboss1rank_pb")
require"PickBattleResultReport"

local bosstime = {
    [1] = {beginT = 12*3600,endT = 12.5*3600},
}

local function findstartCD(nowtimesec)

    for k,v in ipairs(bosstime) do
        if nowtimesec < v.beginT then
            return v.beginT - nowtimesec
        end
    end

    return 24*3600+bosstime[1].beginT - nowtimesec
end

function UIWorldBoss1QueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3400, "WorldBoss1Query")
    local nowtime = os.date("*t", gamedata:time())
    local nowtimesec = nowtime.hour*3600 + nowtime.min* 60 + nowtime.sec

    local isbegin =false
    local isRefresh = false
    for k,v in ipairs(bosstime) do
        if nowtimesec>=v.beginT and nowtimesec<=v.endT then
            isbegin = true
        end
    end

    if next(gamedata.cache.worldboss) then
        for k,v in ipairs(bosstime) do
            print("v.beginT==",v.beginT)
            print("v.endT==",v.endT)
            if gamedata.cache.worldboss.timestatusnum < v.beginT and nowtimesec< v.beginT then
                isRefresh = false
                print("isRefresh111111111111")
            elseif nowtimesec>=v.beginT and nowtimesec<=v.endT and gamedata.cache.worldboss.timestatusnum>=v.beginT and gamedata.cache.worldboss.timestatusnum<=v.endT  then
                isRefresh = false
                print("isRefresh22222222")
            elseif nowtimesec>v.endT and gamedata.cache.worldboss.timestatusnum>v.endT then
                isRefresh = false
                print("isRefresh33333333")
            else
                isRefresh = true
                print("isRefresh444444")
            end
        end
        
        print("gamedata.cache.worldboss.timestatusnum===",gamedata.cache.worldboss.timestatusnum)
        print("nowtimesec==",nowtimesec)

        gamedata.cache.worldboss.timestatusnum = nowtimesec
        print("gamedata.cache.worldboss.timestatusnum===",gamedata.cache.worldboss.timestatusnum)
    end

    print("UIWorldBoss1QueryCallBack===")
    -- printT(gamedata.cache.worldboss)
    if uireq.mainRequest and next(gamedata.cache.worldboss) then
        -- print("i...am...main...",nowtimesec,findstartCD(nowtimesec))
        -- printT(startCD)
        return 0, 3400, { type = 3400, worldboss = gamedata.cache.worldboss,startCD = findstartCD(nowtimesec)}
    elseif isRefresh or isbegin or not next(gamedata.cache.worldboss) or (not isbegin and gamedata.cache.worldboss.status == 1)then
        print("i..am...one..")
        return 1, 3400, nil
    else
        print("i..am...two..")
        return 0, 3400, { type = 3400, worldboss = gamedata.cache.worldboss,startCD = findstartCD(nowtimesec)}
    end

    -- if isRefresh or isbegin or not next(gamedata.cache.worldboss) or (not isbegin and gamedata.cache.worldboss.status == 1)then
    --     print("i..am...one..")
    --     return 1, 3400, nil
    -- else
    --     print("i..am...two..")
    --     return 0, 3400, { type = 3400, worldboss = gamedata.cache.worldboss,startCD = findstartCD(nowtimesec)}
    -- end
end

function NetWorldBoss1QueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3400, "WorldBoss1Query")
    local worldbossData = worldboss1_pb.WorldBoss1()
    worldbossData:ParseFromString(fd.rbuf)

    gamedata.cache.worldboss = gamedata:WorldBossData(worldbossData)

    local nowtime = os.date("*t", gamedata:time())
    local nowtimesec = nowtime.hour*3600 + nowtime.min* 60 + nowtime.sec
    return { type = 3400, worldboss = gamedata.cache.worldboss,startCD = findstartCD(nowtimesec) }
end

---------------------------------------------------------------------------------------

function UIWorldBoss1AttackCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3401, "WorldBoss1Attack")
    local WorldBoss1AttackData = ids_pb.Ids()

    table.insert(WorldBoss1AttackData.ids, uireq.method)
    table.insert(WorldBoss1AttackData.ids, uireq.isauto)

    gamedata.ext.WorldBoss1Attackmethod = uireq.method
    gamedata.ext.WorldBoss1Attackisauto = uireq.isauto

    if uireq.method and uireq.method == 10 and tonumber(gamedata.config.global_kv.worldboss_gold.value) > gamedata.cache.role.gold then
        return 0,503,{type = 503, msgtype = "shortgold" }
    end

    return 1, 3401, WorldBoss1AttackData:SerializeToString()
end

function NetWorldBoss1AttackCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3401, "WorldBoss1Attack")

    local WorldBoss1AttackData = worldboss1_pb.WorldBoss1()
    WorldBoss1AttackData:ParseFromString(fd.rbuf)

    if  gamedata.ext.WorldBoss1Attackmethod then
        if gamedata.ext.WorldBoss1Attackmethod == 10 then
            gamedata:updateRoleGold(0-tonumber(gamedata.config.global_kv.worldboss_gold.value),"群贤屠龙浴火重生",1)
        elseif gamedata.ext.WorldBoss1Attackmethod == 2 then
            gamedata:updateRoleGold(-5,"群贤屠龙立即重生",1)
        end
    end


    return {
        type = 3401,
        worldboss = gamedata:WorldBossData(WorldBoss1AttackData),
        result = WorldBoss1AttackData.battle.result,
        reward = gamedata:SomethingProcess(WorldBoss1AttackData.battle.reward),
        battlereport = PickBattleResultReport(WorldBoss1AttackData.battle),---WorldBoss1AttackData.battle.battlereport,
        star = WorldBoss1AttackData.battle.star,
        isauto = gamedata.ext.WorldBoss1Attackisauto
    }
end

---------------------------------------------------------------------------------------

function UIWorldBoss1RankCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3402, "WorldBoss1Rank")
    return 1, 3402, nil
end

function NetWorldBoss1RankCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3402, "WorldBoss1Rank")
    local worldbossrankData = worldboss1rank_pb.WorldBoss1Rank()
    worldbossrankData:ParseFromString(fd.rbuf)

    local ranks = {}

    for k,v in ipairs(worldbossrankData.ranks) do
        table.insert(ranks,gamedata:playerwithgeneralsdata(v))
    end

    return { type = 3402, ranks=ranks }
end

---------------------------------------------------------------------------------------

function UIWorldBoss1RealNotifyCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3403, "WorldBoss1RealNotify")
    return 1, 3403, nil
end

function NetWorldBoss1RealNotifyCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3403, "WorldBoss1RealNotify")
    local worldbossnotifyData = worldboss1realnotify_pb.WorldBoss1RealNotify()
    worldbossnotifyData:ParseFromString(fd.rbuf)

    local infos = {}
    for k,v in ipairs(worldbossnotifyData.infos) do
        table.insert(infos,{
            id = v.id,
            rid = v.rid,
            rname = v.rname,
            attackcount = v.attackcount,
            damage = v.damage,
            kill = v.kill,
            method = v.method,
        })
    end


    return { type = 3403, bosshp = worldbossnotifyData.bosshp, infos = infos }
end

---------------------------------------------------------------------------------------

local function findrankindex()
    local nowtime = os.date("*t", gamedata:time())
    local nowtimesec = nowtime.hour*3600 + nowtime.min* 60 + nowtime.sec

    for k,v in ipairs(bosstime) do
        if nowtimesec<= v.beginT then
            return k
        end
    end

    return #bosstime+1
end

function UIWorldBoss1PreRankCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3404, "WorldBoss1PreRank")
    print(findrankindex())
    print("i...am...UIWorldBoss1PreRankCallBack")
    -- printT(uireq)
    -- printT(gamedata.cache.worldbossrank)

    local nowtime = os.date("*t", gamedata:time())
    local nowtimesec = nowtime.hour*3600 + nowtime.min* 60 + nowtime.sec


    local isRefresh = false
    local isbegin =false
    for k,v in ipairs(bosstime) do
        if nowtimesec>=v.beginT and nowtimesec<=v.endT then
            isbegin = true
            print("i...am...true=")
        end
    end

    
    if next(gamedata.cache.worldbossrank) then
        for k,v in ipairs(bosstime) do
            print("v.beginT2",v.beginT)
            print("v.endT2",v.endT)
            if gamedata.cache.worldbossrank.timestatusnum < v.beginT and nowtimesec< v.beginT then
                isRefresh = false
                print("isRefresh11111112")
            elseif nowtimesec>=v.beginT and nowtimesec<=v.endT and gamedata.cache.worldbossrank.timestatusnum>=v.beginT and gamedata.cache.worldbossrank.timestatusnum<=v.endT  then
                isRefresh = false
                print("isRefresh2222222222")
            elseif nowtimesec>v.endT and gamedata.cache.worldbossrank.timestatusnum>v.endT then
                isRefresh = false
                print("isRefresh333333332")
            else
                isRefresh = true
                print("isRefresh44444442")
            end
        end
        print("isRefresh2==",isRefresh)
        print("timestatusnum2==",gamedata.cache.worldboss.timestatusnum)
        print("nowtimesec2==",nowtimesec)

        gamedata.cache.worldbossrank.timestatusnum = nowtimesec
        print("timestatusnum2==",gamedata.cache.worldboss.timestatusnum)
    end


    if not next(gamedata.cache.worldbossrank) or (isbegin and next(gamedata.cache.worldboss) and gamedata.cache.worldboss.status==0) or findrankindex() ~= gamedata.cache.worldbossrank.index or isRefresh or uireq.killed then
        print("UIWorldBoss1PreRankCallBack..is1")
        return 1, 3404, nil
    else
        print("UIWorldBoss1PreRankCallBack..is2")
        return 0, 3404, {
            type = 3404,
            ranks = gamedata.cache.worldbossrank.ranks,
            kill = gamedata.cache.worldbossrank.kill,
            time = gamedata.cache.worldbossrank.time,
            timestatusnum = gamedata.cache.worldbossrank.timestatusnum
        }
    end
end

function NetWorldBoss1PreRankCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3404, "WorldBoss1PreRank")
    local worldbossrankData = worldboss1rank_pb.WorldBoss1Rank()
    worldbossrankData:ParseFromString(fd.rbuf)

    gamedata:WorldBossRankData(worldbossrankData)
    gamedata.cache.worldbossrank.index = findrankindex()
    return {
        type = 3404,
        ranks = gamedata.cache.worldbossrank.ranks,
        kill = gamedata.cache.worldbossrank.kill,
        time = gamedata.cache.worldbossrank.time,
        timestatusnum = gamedata.cache.worldbossrank.timestatusnum
    }
end


--－－－－－－－－－－－－－－－－－－－－－－－－－另外一条龙的数据－－－－－－－－－－－－－－－－－－－－－－－－－－
--－－－－－－－－－－－－－－－－－－－－－－－－－另外一条龙的数据－－－－－－－－－－－－－－－－－－－－－－－－－－
--－－－－－－－－－－－－－－－－－－－－－－－－－另外一条龙的数据－－－－－－－－－－－－－－－－－－－－－－－－－－
local bosstime2 = {
    [1] = {beginT = 21*3600,endT = 21.5*3600},
}
local function findstartCD2(nowtimesec)

    for k,v in ipairs(bosstime2) do
        if nowtimesec < v.beginT then
            return v.beginT - nowtimesec
        end
    end

    return 24*3600+bosstime2[1].beginT - nowtimesec
end

function UIWorldBoss2QueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3410, "WorldBoss2Query")
    local nowtime = os.date("*t", gamedata:time())
    local nowtimesec = nowtime.hour*3600 + nowtime.min* 60 + nowtime.sec

    local isRefresh = false
    local isbegin =false
    for k,v in ipairs(bosstime2) do
        if nowtimesec>=v.beginT and nowtimesec<=v.endT then
            isbegin = true
            print("i...am...true=")
        end
    end
    print("UIWorldBoss2QueryCallBack===")
    -- printT(gamedata.cache.worldboss2)

    
    if next(gamedata.cache.worldboss2) then
        for k,v in ipairs(bosstime2) do
            if gamedata.cache.worldboss2.timestatusnum < v.beginT and nowtimesec< v.beginT then
                isRefresh = false
            elseif nowtimesec>=v.beginT and nowtimesec<=v.endT and gamedata.cache.worldboss2.timestatusnum>=v.beginT and gamedata.cache.worldboss2.timestatusnum<=v.endT  then
                isRefresh = false
            elseif nowtimesec>v.endT and gamedata.cache.worldboss2.timestatusnum>v.endT then
                isRefresh = false
            else
                isRefresh = true
            end
        end
        gamedata.cache.worldboss2.timestatusnum = nowtimesec
    end

    if uireq.mainRequest and next(gamedata.cache.worldboss2) then
        return 0, 3410, { type = 3410, worldboss = gamedata.cache.worldboss2,startCD = findstartCD2(nowtimesec)}
    elseif isRefresh or isbegin or not next(gamedata.cache.worldboss2) or (not isbegin and gamedata.cache.worldboss2.status == 1) then
        return 1, 3410, nil
    else
        return 0, 3410, { type = 3410, worldboss = gamedata.cache.worldboss2,startCD = findstartCD2(nowtimesec)}
    end
end

function NetWorldBoss2QueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3410, "WorldBoss2Query")
    local worldbossData = worldboss1_pb.WorldBoss1()
    worldbossData:ParseFromString(fd.rbuf)
    print("NetWorldBoss2QueryCallBack===")
    gamedata.cache.worldboss2 = gamedata:WorldBossData(worldbossData)

    local nowtime = os.date("*t", gamedata:time())
    local nowtimesec = nowtime.hour*3600 + nowtime.min* 60 + nowtime.sec
    return { type = 3410, worldboss = gamedata.cache.worldboss2,startCD = findstartCD2(nowtimesec) }
end

---------------------------------------------------------------------------------------

function UIWorldBoss2AttackCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3411, "WorldBoss2Attack")
    local WorldBoss1AttackData = ids_pb.Ids()
    print("i...am...UIWorldBoss2AttackCallBack")
    table.insert(WorldBoss1AttackData.ids, uireq.method)
    table.insert(WorldBoss1AttackData.ids, uireq.isauto)

    gamedata.ext.WorldBoss2Attackmethod = uireq.method
    gamedata.ext.WorldBoss2Attackisauto = uireq.isauto

    if uireq.method and uireq.method == 10 and tonumber(gamedata.config.global_kv.worldboss_gold.value) > gamedata.cache.role.gold then
        return 0,503,{type = 503, msgtype = "shortgold" }
    end

    return 1, 3411, WorldBoss1AttackData:SerializeToString()
end

function NetWorldBoss2AttackCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3411, "WorldBoss2Attack")
    print("i...am...NetWorldBoss2AttackCallBack")

    local WorldBoss1AttackData = worldboss1_pb.WorldBoss1()
    WorldBoss1AttackData:ParseFromString(fd.rbuf)

    if  gamedata.ext.WorldBoss2Attackmethod then
        if gamedata.ext.WorldBoss2Attackmethod == 10 then
            gamedata:updateRoleGold(0-tonumber(gamedata.config.global_kv.worldboss_gold.value),"群贤屠龙浴火重生",1)
        elseif gamedata.ext.WorldBoss2Attackmethod == 2 then
            gamedata:updateRoleGold(-5,"群贤屠龙立即重生",1)
        end
    end


    return {
        type = 3411,
        worldboss = gamedata:WorldBossData(WorldBoss1AttackData),
        result = WorldBoss1AttackData.battle.result,
        reward = gamedata:SomethingProcess(WorldBoss1AttackData.battle.reward),
        ---battlereport = WorldBoss1AttackData.battle.battlereport,
        battlereport = PickBattleResultReport(WorldBoss1AttackData.battle),
        star = WorldBoss1AttackData.battle.star,
        isauto = gamedata.ext.WorldBoss2Attackisauto
    }
end

---------------------------------------------------------------------------------------

function UIWorldBoss2RankCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3412, "WorldBoss2Rank")
    return 1, 3412, nil
end

function NetWorldBoss2RankCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3412, "WorldBoss2Rank")
    local worldbossrankData = worldboss1rank_pb.WorldBoss1Rank()
    worldbossrankData:ParseFromString(fd.rbuf)

    local ranks = {}

    for k,v in ipairs(worldbossrankData.ranks) do
        table.insert(ranks,gamedata:playerwithgeneralsdata(v))
    end

    return { type = 3412, ranks=ranks }
end

---------------------------------------------------------------------------------------

function UIWorldBoss2RealNotifyCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3413, "WorldBoss2RealNotify")
    return 1, 3413, nil
end

function NetWorldBoss2RealNotifyCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3413, "WorldBoss2RealNotify")
    local worldbossnotifyData = worldboss1realnotify_pb.WorldBoss1RealNotify()
    worldbossnotifyData:ParseFromString(fd.rbuf)

    local infos = {}
    for k,v in ipairs(worldbossnotifyData.infos) do
        table.insert(infos,{
            id = v.id,
            rid = v.rid,
            rname = v.rname,
            attackcount = v.attackcount,
            damage = v.damage,
            kill = v.kill,
            method = v.method,
        })
    end


    return { type = 3413, bosshp = worldbossnotifyData.bosshp, infos = infos }
end

---------------------------------------------------------------------------------------

local function findrankindex2()
    local nowtime = os.date("*t", gamedata:time())
    local nowtimesec = nowtime.hour*3600 + nowtime.min* 60 + nowtime.sec

    for k,v in ipairs(bosstime2) do
        if nowtimesec<= v.beginT then
            return k
        end
    end

    return #bosstime2+1
end

function UIWorldBoss2PreRankCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3414, "WorldBoss2PreRank")
    print("UIWorldBoss2PreRankCallBack")
    -- printT(uireq)
    -- printT(gamedata.cache.worldbossrank2)
    print(findrankindex2())
    local nowtime = os.date("*t", gamedata:time())
    local nowtimesec = nowtime.hour*3600 + nowtime.min* 60 + nowtime.sec

    local isRefresh = false
    local isbegin =false
    for k,v in ipairs(bosstime2) do
        if nowtimesec>=v.beginT and nowtimesec<=v.endT then
            isbegin = true
            print("i...am...true=")
        end
    end
    
    if next(gamedata.cache.worldbossrank2) then
        for k,v in ipairs(bosstime) do
            if gamedata.cache.worldbossrank2.timestatusnum < v.beginT and nowtimesec< v.beginT then
                isRefresh = false
            elseif nowtimesec>=v.beginT and nowtimesec<=v.endT and gamedata.cache.worldbossrank2.timestatusnum>=v.beginT and gamedata.cache.worldbossrank2.timestatusnum<=v.endT  then
                isRefresh = false
            elseif nowtimesec>v.endT and gamedata.cache.worldbossrank2.timestatusnum>v.endT then
                isRefresh = false
            else
                isRefresh = true
            end
        end

        gamedata.cache.worldbossrank2.timestatusnum = nowtimesec
    end


    if not next(gamedata.cache.worldbossrank2) or (isbegin and next(gamedata.cache.worldboss2) and gamedata.cache.worldboss2.status==0) or findrankindex2() ~= gamedata.cache.worldbossrank2.index or isRefresh or uireq.killed then
        print("UIWorldBoss2PreRankCallBack..is1")
        return 1, 3414, nil
    else
        print("UIWorldBoss2PreRankCallBack..is2")
        return 0, 3414, {
            type = 3414,
            ranks = gamedata.cache.worldbossrank2.ranks,
            kill = gamedata.cache.worldbossrank2.kill,
            time = gamedata.cache.worldbossrank2.time,
            timestatusnum = gamedata.cache.worldbossrank2.timestatusnum
        }
    end
end

function NetWorldBoss2PreRankCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3414, "WorldBoss2PreRank")
    local worldbossrankData = worldboss1rank_pb.WorldBoss1Rank()
    worldbossrankData:ParseFromString(fd.rbuf)
    print("NetWorldBoss2PreRankCallBack..is")

    gamedata:WorldBossRankData2(worldbossrankData)
    gamedata.cache.worldbossrank2.index = findrankindex2()
    return {
        type = 3414,
        ranks = gamedata.cache.worldbossrank2.ranks,
        kill = gamedata.cache.worldbossrank2.kill,
        time = gamedata.cache.worldbossrank2.time,
        timestatusnum = gamedata.cache.worldbossrank2.timestatusnum
    }
end




--[[
[5201] = UIHeroBossQueryCallBack,
[5202] = UIHeroBossFollowCallBack,
[5203] = UIHeroBossEnterCallBack,
[5204] = UIHeroBossAttackCallBack,
[5205] = UIHeroBossCheerCallBack,
[5206] = UIHeroBossRankCallBack,
[5207] = UIHeroBossRealNotifyCallBack,
[5208] = UIHeroBossAwardRecordCallBack,
[5209] = UIHeroBossReviveCallBack,
[5210] = UIHeroBossDeadCallBack,
]]

local somethings_pb = require("somethings_pb")
local combmessages_pb = require("combmessages_pb")
local battleresult_pb = require("battleresult_pb")

function UIHeroBossQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5201, "HeroBossQuery")

    return 1, 5201, nil
end

function NetHeroBossQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5201, "HeroBossQuery")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local heroboss = {}
    heroboss.boss = {}
    heroboss.challengenum = 0
    heroboss.time = 0
    heroboss.enter = 0
    heroboss.double = 0

    for k,v in ipairs(datas.messages) do
        if v.id == 1 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            heroboss.challengenum = ids.ids[1] or 0
            heroboss.time = ids.ids[2] or 0
            heroboss.enter = ids.ids[3] or 0
            heroboss.double = ids.ids[4] or 0
        else
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            local boss = {}
            boss.id = ids.ids[1] or 0
            boss.follow = ids.ids[2] or 0
            boss.status = ids.ids[3] or 0
            boss.hp = ids.ids[4] or 0
            boss.totalhp = ids.ids[5] or 0
            boss.num = ids.ids[6] or 0
            boss.time = ids.ids[7] or 0
            heroboss.boss[tostring(boss.id)] = boss
        end
    end

    gamedata.cache.heroboss = heroboss

    --
    local minlv = 0
    if gamedata.cache.protagonist and gamedata.cache.protagonist.level1 and gamedata.cache.protagonist.level1 > 0 then
        minlv = gamedata.cache.protagonist.level1
    end

    for i = 1,7 do
        if gamedata.cache.slots[i] and gamedata.cache.slots[i].general and gamedata.cache.slots[i].general > 0 then
            if gamedata.cache.generals[gamedata.cache.slots[i].general] and gamedata.cache.generals[gamedata.cache.slots[i].general].level1 and gamedata.cache.generals[gamedata.cache.slots[i].general].level1 < minlv then
                minlv = gamedata.cache.generals[gamedata.cache.slots[i].general].level1
            end
        else
            minlv = 0
        end
    end

    return { type = 5201, heroboss = gamedata.cache.heroboss, minlv = minlv}

end

--
function UIHeroBossFollowCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5202, "HeroBossFollow")
    local StatusData = ids_pb.Ids()

    table.insert(StatusData.ids, uireq.id or 0)

    return 1, 5202, StatusData:SerializeToString()
end

function NetHeroBossFollowCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5202, "HeroBossFollow")

    local datas = ids_pb.Ids()
    datas:ParseFromString(fd.rbuf)

    local isfollow = 0
    isfollow = datas.ids[1] or 0

    return { type = 5202, isfollow = isfollow}

end


function UIHeroBossEnterCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5203, "HeroBossEnter")
    local StatusData = ids_pb.Ids()

    table.insert(StatusData.ids, uireq.id or 0)

    return 1, 5203, StatusData:SerializeToString()
end

function NetHeroBossEnterCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5203, "HeroBossEnter")
    local worldbossData = worldboss1_pb.WorldBoss1()
    worldbossData:ParseFromString(fd.rbuf)

    local heroboss = gamedata:WorldBossData(worldbossData)

    return { type = 5203, heroboss = heroboss}
end


function UIHeroBossAttackCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5204, "HeroBossAttack")
    local WorldBoss1AttackData = ids_pb.Ids()

    table.insert(WorldBoss1AttackData.ids, uireq.bossid)
    table.insert(WorldBoss1AttackData.ids, uireq.method)
    table.insert(WorldBoss1AttackData.ids, uireq.isauto)

    gamedata.ext.HeroBossAttackbossid = uireq.bossid
    gamedata.ext.HeroBossAttackmethod = uireq.method
    gamedata.ext.HeroBossAttackisauto = uireq.isauto


    return 1, 5204, WorldBoss1AttackData:SerializeToString()
end

function NetHeroBossAttackCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5204, "HeroBossAttack")

    local WorldBoss1AttackData = worldboss1_pb.WorldBoss1()
    WorldBoss1AttackData:ParseFromString(fd.rbuf)

    return {
        type = 5204,
        heroboss = gamedata:WorldBossData(WorldBoss1AttackData),
        result = WorldBoss1AttackData.battle.result,
        reward = gamedata:SomethingProcess(WorldBoss1AttackData.battle.reward),
        battlereport = PickBattleResultReport(WorldBoss1AttackData.battle),---WorldBoss1AttackData.battle.battlereport,
        star = WorldBoss1AttackData.battle.star,
        isauto = gamedata.ext.HeroBossAttackisauto
    }
end


function UIHeroBossRankCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5206, "HeroBossRankCallBack")
    local StatusData = ids_pb.Ids()

    table.insert(StatusData.ids, uireq.id or 0)

    return 1, 5206, StatusData:SerializeToString()
end

function NetHeroBossRankCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5206, "HeroBossRankCallBack")
    local bossrankData = worldboss1rank_pb.WorldBoss1Rank()
    bossrankData:ParseFromString(fd.rbuf)

    local ranks = {}

    for k,v in ipairs(bossrankData.ranks) do
        table.insert(ranks,gamedata:playerwithgeneralsdata(v))
    end

    return { type = 5206, ranks=ranks }
end


function UIHeroBossRealNotifyCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5207, "HeroBossRealNotify")
    return 1, 5207, nil
end

function NetHeroBossRealNotifyCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5207, "HeroBossRealNotify")
    local bossnotifyData = worldboss1realnotify_pb.WorldBoss1RealNotify()
    bossnotifyData:ParseFromString(fd.rbuf)

    local infos = {}
    for k,v in ipairs(bossnotifyData.infos) do
        table.insert(infos,{
            id = v.id,
            rid = v.rid,
            rname = v.rname,
            attackcount = v.attackcount,
            damage = v.damage,
            kill = v.kill,
            method = v.method,
        })
    end

    return { type = 5207, bosshp = bossnotifyData.bosshp, infos = infos }
end

--
function UIHeroBossCheerCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5205, "HeroBossCheer")
    local StatusData = ids_pb.Ids()

    table.insert(StatusData.ids, uireq.num or 1)

    gamedata.ext.HeroBossCheerGold = uireq.spendGlod or 0

    if uireq.spendGlod and (uireq.spendGlod > gamedata.cache.role.gold) then
        return 0, 503,{type = 503,msgtype = "shortgold"}
    end

    return 1, 5205, StatusData:SerializeToString()
end

function NetHeroBossCheerCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5205, "HeroBossCheer")

    local datas = ids_pb.Ids()
    datas:ParseFromString(fd.rbuf)

    if gamedata.ext.HeroBossCheerGold and gamedata.ext.HeroBossCheerGold > 0 then
        gamedata:updateRoleGold(0-gamedata.ext.HeroBossCheerGold,"英雄挑战助威",1)
    end

    local cheernum = 0
    cheernum = datas.ids[1] or 0

    return { type = 5205, cheernum = cheernum}

end


--
local players_pb = require("players_pb")
function UIHeroBossAwardRecordCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5208, "HeroBossAwardRecord")
    local StatusData = ids_pb.Ids()

    table.insert(StatusData.ids, uireq.id or 0)

    return 1, 5208, StatusData:SerializeToString()
end

function NetHeroBossAwardRecordCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5208, "HeroBossAwardRecord")

    local players = {}
    local playersData = players_pb.Players()
    playersData:ParseFromString(fd.rbuf)
    players = gamedata:players(playersData.players)

    return { type = 5208, list = players}

end


--
function UIHeroBossReviveCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5209, "HeroBossRevive")


    return 1, 5209, nil
end

function NetHeroBossReviveCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5209, "HeroBossRevive")

    local datas = ids_pb.Ids()
    datas:ParseFromString(fd.rbuf)

    local bosslist = {}
    for k,v in ipairs(datas.ids) do
        table.insert(bosslist,v)
    end

    return { type = 5209, bosslist = bosslist}

end

--
function UIHeroBossDeadCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5210, "HeroBossDeadCallBack")


    return 1, 5210, nil
end

function NetHeroBossDeadCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5210, "HeroBossDeadCallBack")

    local datas = ids_pb.Ids()
    datas:ParseFromString(fd.rbuf)

    local bosslist = {}
    for k,v in ipairs(datas.ids) do
        table.insert(bosslist,v)
    end

    return { type = 5210, bosslist = bosslist}

end

--
--
function UIHeroBossDoubleCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5211, "HeroBossDouble")

    local StatusData = ids_pb.Ids()

    table.insert(StatusData.ids, uireq.opt or 0)

    return 1, 5211, StatusData:SerializeToString()
end

function NetHeroBossDoubleCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5211, "HeroBossDouble")

    local datas = ids_pb.Ids()
    datas:ParseFromString(fd.rbuf)

    local result = datas.ids[1] or 0

    return { type = 5211, result = result}

end


--
function UIHeroBossChangeNumCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5212, "HeroBossChangeNumCallBack")


    return 1, 5212, nil
end

function NetHeroBossChangeNumCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5212, "HeroBossChangeNumCallBack")

    local datas = ids_pb.Ids()
    datas:ParseFromString(fd.rbuf)

    local bosslist = {}
    for k,v in ipairs(datas.ids) do
        table.insert(bosslist,v)
    end

    return { type = 5212, bosslist = bosslist}

end
  �x  