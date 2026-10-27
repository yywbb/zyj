--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-10-17
-- Time: 下午4:29
-- To change this template use File | Settings | File Templates.
--
require"PickBattleResultReport"
function makeGeneralRob()
    local generalstemp = table.copy(gamedata.cache.generals)
    local allgenerals = {
        all = {},
        star3 = {},
        star4 = {},
        star5 = {},
        star6 = {},
    }
    for k,v in pairs(generalstemp) do
        local data = {
            cid = v.cid,
            quality = gamedata.config.general[tostring(v.cid)].quality,
            num = gamedata.cache.generalfragments[v.cid] and gamedata.cache.generalfragments[v.cid].num or 0
        }
        if data.quality >=3 then
            if allgenerals["star"..data.quality] then
                table.insert(allgenerals["star"..data.quality],data)
            end
            table.insert(allgenerals["all"],data)
        end
    end

    for k,v in pairs(allgenerals) do
        gamedata.sortData(allgenerals[k], "quality","cid")
        allgenerals[k] = gamedata.groupdata(allgenerals[k],4)
    end

    return allgenerals --gamedata.groupdata(allgenerals,4)
end

local function changeToArray(datatable)
    local temp  ={}
    for k,v in pairs(datatable) do
        table.insert(temp,v)
    end

    return temp
end

local function makeTreasure(fragmentconfig,equipconfig,roddata,fragdata)
    if not roddata[equipconfig.id] then
        roddata[equipconfig.id] = {
            cid = equipconfig.id,
            quality = equipconfig.quality,
            icon = equipconfig.icon,
            name = equipconfig.name,
            fragments = {},
        }

        for k,v in pairs(gamedata.config.treasure2_fragment) do
            if v.equip == equipconfig.id then
                roddata[equipconfig.id].fragments[v.seq] = {cid = v.id, num = 0}
            end
        end
    end

    if fragdata then
        roddata[equipconfig.id].fragments[fragmentconfig.seq].num = fragdata.num
    end

end

local function makedefault(roddata,cid)
    local fragmentconfig = gamedata.config.treasure2_fragment[tostring(cid)]
    --printT(fragmentconfig)
    local equipconfig = gamedata.config[fragmentconfig.page == "meterial" and "props" or "equip"][tostring(fragmentconfig.equip)]
    makeTreasure(fragmentconfig,equipconfig,roddata)
end

local function checkenough(data)
    local hashint = 0
    for k,v in pairs(data) do
        local enough = true
        for kk,vv in pairs(v.fragments) do
             if vv.num <=0 then
                 enough = false
                 break
             end
        end
        v.enough =  enough
        if enough then hashint =hashint + 1 end
    end
    return hashint
end

function makeTreasureRob()
    local Fragmentstemp = table.copy(gamedata.cache.equipfragments)

    local treasures, horses,meterials ={},{},{}

    for k,v in pairs(gamedata.config.treasure2_fragment) do
        if v.default == 1 then
            if v.page == "meterial" then
                makedefault(meterials,v.id)
            elseif v.page == "horse" then
                makedefault(horses,v.id)
            elseif v.page == "treasure" then
                makedefault(treasures,v.id)
            end
        end
    end

    for k,v in pairs(Fragmentstemp) do
        if v.cid >= 28001 and v.cid <= 29000 then
            local fragmentconfig = gamedata.config.treasure2_fragment[tostring(v.cid)]
            local equipconfig = gamedata.config[fragmentconfig.page == "meterial" and "props" or "equip"][tostring(fragmentconfig.equip)]

            if fragmentconfig.page == "meterial" then
                makeTreasure(fragmentconfig,equipconfig,meterials,v)
            elseif equipconfig.type == "horse" then
                makeTreasure(fragmentconfig,equipconfig,horses,v)
            elseif equipconfig.type == "treasure" then
                makeTreasure(fragmentconfig,equipconfig,treasures,v)
            end
        end
    end

    mekehintext(25,checkenough(treasures))
    mekehintext(24,checkenough(horses))
    mekehintext(26,checkenough(meterials))

    local t,h,m = changeToArray(treasures),changeToArray(horses),changeToArray(meterials)

    gamedata.sortData(t, "quality","cid")
    gamedata.sortData(h, "quality","cid")
    gamedata.sortData(m, "quality","cid")

    return t,h,m  --gamedata.groupdata(t,4), gamedata.groupdata(h,4)
end

function UIGameRobEquipQueryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 11111, "GameRobQuery")
    local treasures, horses, meterials = makeTreasureRob()

    local energy1 = 0
    local energy2 = 0
    if gamedata.cache.props[20020] then
        energy1 = gamedata.cache.props[20020].num
    end   
    if gamedata.cache.props[20015] then
        energy2 = gamedata.cache.props[20015].num
    end    

    return 0, 11111, {type = 11111, treasures=treasures, horses=horses, meterials=meterials, energy1 = energy1 or 0, energy2 = energy2 or 0 }
end

function UIGameRobGeneralQueryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 11112, "GameRobQuery")

    return 0, 11112, {type = 11112, generals = makeGeneralRob() }
end

local players_pb = require("players_pb")
local ids_pb = require("ids_pb")
local battleresult_pb = require("battleresult_pb")
local somethings_pb = require("somethings_pb")
local combmessages_pb = require("combmessages_pb")


function UIGameGeneralFragmentRobQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1018, "GameeneralFragmentRobQuery")
    local GameRobData = ids_pb.Ids()

    table.insert(GameRobData.ids, uireq.cid)
    gamedata.ext.generalrobcid = uireq.cid

    return 1, 1018, GameRobData:SerializeToString()
end

function NetGameGeneralFragmentRobQueryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1018, "GameeneralFragmentRobQuery")
    local playersData = players_pb.Players()
    playersData:ParseFromString(fd.rbuf)

    return { type = 1018, cid =gamedata.ext.generalrobcid,  players = makePlayers(playersData.players), energy = gamedata.cache.role.energy or 0, mygangid = gamedata.cache.gang2status.id or 0 }
end


function UIGameGeneralFragmentRobCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1019, "GameeneralFragmentRob")
    local GameRobData = ids_pb.Ids()

    table.insert(GameRobData.ids, uireq.enemy.rid)
    gamedata.ext.robgeneralenemy = uireq.enemy

    if gamedata.cache.role.energy <= 0 then
        return  0, 503, {type = 503, msgtype = "shortenergy", param = gamedata.cache.props }
    else
        gamedata.ext.robrequest = uireq
        return 1, 1019, GameRobData:SerializeToString()
    end


end

function NetGameGeneralFragmentRobCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1019, "GameeneralFragmentRob")
    local copyAttackResultPb = battleresult_pb.BattleResult()
    copyAttackResultPb:ParseFromString(fd.rbuf)

    gamedata:updateRoleEnergy(-1)

    local t = {
        type = 1019,
        result = copyAttackResultPb.result,
        reward = gamedata:SomethingProcess(copyAttackResultPb.reward),
        ---battlereport = copyAttackResultPb.battlereport,
        battlereport = PickBattleResultReport(copyAttackResultPb),
        request = gamedata.ext.robrequest,
        enemy = gamedata.ext.robgeneralenemy
    }

    return t
end

function UIGameTreasureFragmentRobQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1110, "GameTreasureFragmentRobQuery")
    local TreasureRobData = ids_pb.Ids()

    if gamedata.cache.equipfragments[uireq.cid] and gamedata.cache.equipfragments[uireq.cid].num >0 then
        return 0, 503, {type = 503, msgtype = "", msg = "" }
    end

    table.insert(TreasureRobData.ids, uireq.cid)
    gamedata.ext.Treasurerobcid = uireq.cid

    return 1, 1110, TreasureRobData:SerializeToString()
end

function NetGameTreasureFragmentRobQueryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1110, "GameTreasureFragmentRobQuery")
    local playersData = players_pb.Players()
    playersData:ParseFromString(fd.rbuf)

    return { type = 1110, cid =gamedata.ext.Treasurerobcid, players = makePlayers(playersData.players), energy = gamedata.cache.role.energy or 0, mygangid = gamedata.cache.gang2status.id or 0 }
end


function UIGameTreasureFragmentRobCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1111, "TreasureFragmentRob")
    local TreasureRobData = ids_pb.Ids()

    table.insert(TreasureRobData.ids, uireq.enemy.rid)
    table.insert(TreasureRobData.ids, uireq.method ==1 and 999 or 0)
    gamedata.ext.robfragmentenemy = uireq.enemy

    if gamedata.cache.role.energy <= 0 then
        return  0, 503, {type = 503, msgtype = "shortenergy", param = gamedata.cache.props }
    else
        gamedata.ext.robrequest = uireq
        return 1, 1111, TreasureRobData:SerializeToString()
    end
end

function NetGameTreasureFragmentRobCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1111, "TreasureFragmentRob")
    local copyAttackResultPb = battleresult_pb.BattleResult()
    copyAttackResultPb:ParseFromString(fd.rbuf)

    gamedata:updateRoleEnergy(-1)

    local reward = gamedata:SomethingProcess(copyAttackResultPb.reward)
    local coin = nil
    local get = nil
    local otherreward = nil
    local rob = nil

    for k,v in pairs(reward) do
         if v.cid == 1000 then
             coin = v
         elseif v.cid == 20255 then
             rob = v
         elseif v.cid == gamedata.ext.robrequest.cid and #reward >2 then
             get = v
         else
             otherreward = {v}
         end
    end


    local energy1 = 0
    local energy2 = 0
    if gamedata.cache.props[20020] then
        energy1 = gamedata.cache.props[20020].num
    end   
    if gamedata.cache.props[20015] then
        energy2 = gamedata.cache.props[20015].num
    end    


    local t = {
        type = 1111,
        result = copyAttackResultPb.result,
        coin = coin,
        rob = rob,
        get = get,
        otherreward = otherreward,
        ---battlereport = copyAttackResultPb.battlereport,
        battlereport = PickBattleResultReport(copyAttackResultPb),
        energy = gamedata.cache.role.energy or 0,
        request = gamedata.ext.robrequest,
        enemy = gamedata.ext.robfragmentenemy,
        energy1 = energy1 or 0,
        energy2 = energy2 or 0,
    }
    return t
end

function UIGameTreasureFragmentRobTenCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1114, "TreasureFragmentRobTen")

    local TreasureRobData = ids_pb.Ids()

    table.insert(TreasureRobData.ids, uireq.enemy.rid)

    if gamedata.cache.role.energy <= 0 then
        return  0, 503, {type = 503, msgtype = "shortenergy", param = gamedata.cache.props }
    else
        gamedata.ext.robrequest = uireq
        return 1, 1114, TreasureRobData:SerializeToString()
    end
end

function NetGameTreasureFragmentRobTenCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1114, "TreasureFragmentRobTen")
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local reward = {}
    local energy = 0
    for k,v in ipairs(datas.messages) do
        if k==1 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            energy = ids.ids[1]
        else
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            local rewardone = gamedata:SomethingProcess(SomeThings)
            table.insert(reward,rewardone)
        end
    end

    local coin = {}
    local rob = {}
    local otherreward = {}
    local get = nil
    for k,v in ipairs(reward) do
        for kv,vv in ipairs(v) do
            if vv.cid == 1000 then
                table.insert(coin,vv)
            elseif vv.cid == 20255 then
                table.insert(rob,vv)
            else
                if vv.cid == gamedata.ext.robrequest.cid and not get and #v >2 then
                    get = vv
                else
                    table.insert(otherreward,vv)
                end
            end
        end
    end


    gamedata:updateRoleEnergy(-energy)

    local energy1 = 0
    local energy2 = 0
    if gamedata.cache.props[20020] then
        energy1 = gamedata.cache.props[20020].num
    end   
    if gamedata.cache.props[20015] then
        energy2 = gamedata.cache.props[20015].num
    end    

    local t = {
        type = 1114,
        coin = coin,
        rob = rob,
        otherreward = otherreward,
        get = get,
        energy = energy,
        request = gamedata.ext.robrequest,
        has_energy = gamedata.cache.role.energy,
        energy1 = energy1 or 0, 
        energy2 = energy2 or 0,
    }
    return t
end


function UIRobOneKeyTreasureCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1125, "UIRobOneKeyTreasureCallback")

    local TreasureRobData = ids_pb.Ids()
     
    local  isautoxh = uireq.isautoxh or 0
    table.insert(TreasureRobData.ids, isautoxh)
    local losscid = uireq.losscid or {}
    for i,v in pairs(losscid) do
        print("UIRobOneKeyTreasureCallback --")
        table.insert(TreasureRobData.ids, v)
    end

    printT(losscid,"losscid")
    if isautoxh == 0 and gamedata.cache.role.energy <= 0 then
        return  0, 503, {type = 503, msgtype = "shortenergy", param = gamedata.cache.props }
    else
        gamedata.ext.robrequest = uireq
        return 1, 1125, TreasureRobData:SerializeToString()
    end
end

function NetRobOneKeyTreasureCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1125, "NetRobOneKeyTreasureCallback")
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local reward = {}
    local energy = 0
    local energy1 = 0 --大杀气
    local energy2 = 0 --小杀气

    for k,v in ipairs(datas.messages) do
        if k==1 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            energy = ids.ids[1] or 0
            energy1 = ids.ids[2] or 0
            energy2 = ids.ids[3] or 0
        else
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            local rewardone = gamedata:SomethingProcess(SomeThings)
            table.insert(reward,rewardone)
        end
    end

    print("energy:"..energy)
    print("energy2:"..energy1)
    print("energy3:"..energy2)
    printT(reward,"reward")
    local coin = {}
    local rob = {}
    local otherreward = {}
    local get = {}

    local rewards = {}
    for k,v in ipairs(reward) do
        -- print("k-----------",k)
         -- table.insert(rewards[k],{})
       rewards[tostring(k)] = { coin = 0,rob = 0,get = {},otherreward = {}}
        for kv,vv in ipairs(v) do
            if vv.cid == 1000 then
                rewards[tostring(k)].coin = vv.num
                -- table.insert(rewards[tostring(k)],vv)--.coin
            elseif vv.cid == 20255 then
                rewards[tostring(k)].rob = vv.num
                -- table.insert(rewards[tostring(k)],vv)--.rob
            else
                local ishave =  false
                for q,p in pairs(gamedata.ext.robrequest.losscid) do
                    if vv.cid == p then
                        ishave = true
                        table.insert(get,vv)
                        table.insert(rewards[tostring(k)].get,vv)--.get
                    end    
                end
                if not ishave then
                    table.insert(rewards[tostring(k)].otherreward,vv)--.otherreward
                end   
                 
                if vv.num and tonumber(vv.num)>0 then
                    table.insert(otherreward,vv)
                end    
            end

        end
    end
    
    --杀气丹
    if gamedata.cache.props[20015] and gamedata.cache.props[20015].num > 0 then 
        if energy2> 0 then
            gamedata.cache.props[20015].num = gamedata.cache.props[20015].num -energy2
        end    
    --大杀气丹
    end
    if gamedata.cache.props[20020] and gamedata.cache.props[20020].num > 0 then
        if energy1> 0 then
            gamedata.cache.props[20020].num = gamedata.cache.props[20020].num -energy1
        end   
    end


    local currentenergy = gamedata.cache.role.energy
    local totalenergy = energy1*20 + energy2*10
    local lefteneryg = 0
    if totalenergy > 0 then
        lefteneryg = (totalenergy+currentenergy) - energy
        if lefteneryg <= currentenergy then
           lefteneryg = -(currentenergy-lefteneryg)
        else
           lefteneryg = lefteneryg-currentenergy
        end    
    else 
        lefteneryg = -energy
    end


    print(lefteneryg,"lefteneryg")
    gamedata:updateRoleEnergy(lefteneryg)


    local energy1 = 0
    local energy2 = 0
    if gamedata.cache.props[20020] then
        energy1 = gamedata.cache.props[20020].num
    end   
    if gamedata.cache.props[20015] then
        energy2 = gamedata.cache.props[20015].num
    end    


    local t = {
        type = 1125,
        otherreward = otherreward,
        get = get,
        energy = energy,
        energy1 = energy1 or 0,
        energy2 = energy2 or 0,
        rewards = rewards,
    }
    return t
end


function UIRobProfCDqueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1112, "RobProfCDquery")

    return 1, 1112, nil
end

function NetRobProfCDqueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1112, "RobProfCDquery")
    local RobProfCD = ids_pb.Ids()
    RobProfCD:ParseFromString(fd.rbuf)

    local energy1 = 0
    local energy2 = 0
    if gamedata.cache.props[20020] then
        energy1 = gamedata.cache.props[20020].num
    end   
    if gamedata.cache.props[20015] then
        energy2 = gamedata.cache.props[20015].num
    end    


    return {type = 1112, cd = RobProfCD.ids[1], energy1 = energy1 or 0,energy2 = energy2 or 0}
end

function UIRobProfCDAddCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1113, "RobProfCDAdd")

    return 1, 1113, nil
end

function NetRobProfCDAddCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1113, "RobProfCDAdd")
    local RobProfCD = ids_pb.Ids()
    RobProfCD:ParseFromString(fd.rbuf)

    gamedata:updateprops({cid = 20128, num = 0-1})

    return {type = 1113, cd = RobProfCD.ids[1]}
end
