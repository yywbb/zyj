--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/25
-- Time: 上午9:29
-- To change this template use File | Settings | File Templates.
--

local copies_pb = require("copies_pb")
local copyattack_pb = require("copyattack_pb")
local battleresult_pb = require("battleresult_pb")
local copyAll3StarAwardPb = require("copyall3starreward_pb")
local copyAll3StarAwardResultPb = require("result_pb")
local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")

local function makeBraveCopyData()

    local copyConfig = gamedata.config.brave_map
    local sectionConfig = gamedata.config.section
    local pointConfig = gamedata.config.brave_copy

    local copy ={}
    for k,v in pairs(gamedata.cache.bravecopy) do
        local section = copyConfig[tostring(v.id)].section-40000
        if not copy[section]  then
            copy[section] = {
                name = sectionConfig[tostring(section+40000)].name,
                section = section,
                maps = {}
            }
        end

        local i=1
        while v.points[i] and pointConfig[tostring(v.id)][tostring(i)] do
            i=i+1
        end

        if i==1 or (pointConfig[tostring(v.id)][tostring(i)] and v.points[i-1] and v.points[i-1].star > 0) then
            v.points[i]={
                id = i,
                star = 0,
                kill = 0,
            }
        end

        v.star = 3
        v.totalstar = 0
        for km,vm in pairs(v.points) do
            if vm.star < v.star then
                v.star = vm.star
            end
            v.totalstar = v.totalstar + vm.star
        end
        for i=1,3 do
            if v.totalstar >= copyConfig[tostring(v.id)]["star"..i] and v["pa"..i]==1 then
                v["pa"..i] = 2
            end
        end

        v.config = copyConfig[tostring(v.id)]
        table.insert(copy[section].maps, v)

    end

    for k,v in pairs(copy) do
        local sortfunc = function(a,b) return a.id < b.id end
        table.sort(v.maps,sortfunc)
    end

    return copy
end


function UIBraveCopyQueryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1330, "Bravecopyquery")

    if next(gamedata.cache.bravecopy) then
        return 0, 1330, { type = uireq.type, bravecopy = makeBraveCopyData()}
    else
        return 1, 1330, nil
    end
end

function NetBraveCopyQueryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1330, "Bravecopyquery")
    local copyData = copies_pb.Copies()
    copyData:ParseFromString(fd.rbuf)

    gamedata:BraveCopies(copyData)

    return { type = 1330, bravecopy = makeBraveCopyData()}--, copywipetimer = gamedata.cache.copywipetimer}
end

------------------------------------------------------------------------------------------------------------------------------

function UIBraveCopyAttackCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1331, "Bravecopyattack")
    local CopyAttack = copyattack_pb.CopyAttack()
    CopyAttack.map = uireq.map
    CopyAttack.point = uireq.point
    print(uireq.map,uireq.point)

    gamedata.ext.bravecopyattack = {map = uireq.map, point = uireq.point }

    local config = gamedata.config.brave_copy
    local copy = gamedata.cache.bravecopy

    if gamedata.cache.role.stamina < config[tostring(uireq.map)][tostring(uireq.point)].physical then
        return  0, 503, {type = 503, msgtype = "shortphysical" , param = gamedata.cache.props }
    elseif copy[uireq.map].points[uireq.point] and copy[uireq.map].points[uireq.point].kill >=  config[tostring(uireq.map)][tostring(uireq.point)].challenge then
        return  0, 503, {type = 503, msgtype = "shortCopyChallenge" , msg = "挑战次数不足！" }
    else
        return 1, 1331, CopyAttack:SerializeToString()
    end

end

function NetBraveCopyAttackCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1331, "Bravecopyattack")
    local copyAttackResultPb = battleresult_pb.BattleResult()
    copyAttackResultPb:ParseFromString(fd.rbuf)

    local t = {
        type = 1331,
        result = copyAttackResultPb.result,
        reward = gamedata:SomethingProcess(copyAttackResultPb.reward),
        exp =  gamedata:updateRoleExp(copyAttackResultPb.exp),
    }

    local point = gamedata.ext.bravecopyattack.point
    local map = gamedata.ext.bravecopyattack.map


    local copy = gamedata.cache.bravecopy
    local config = gamedata.config.brave_copy

    if copy[map].points[point] and copy[map].points[point].star >=3 then
        t.passbattle = true
    end


    gamedata:updateRoleStamina(-config[tostring(map)][tostring(point)].physical)

    t.fightbg = gamedata.config.section[tostring(gamedata.config.brave_map[tostring(map)].section)].basemap

    if not copy[map].points[point] or copy[map].points[point].star <= 0 then
        UIResponse({type = 503, msgtype = "umeng", datatype = "startLevel", level = "brave_"..map.."_"..point })
    end


    if t.result == -1 then
    elseif t.result == 0 then
        ---t.battlereport = copyAttackResultPb.battlereport
        t.battlereport = PickBattleResultReport(copyAttackResultPb)
        t.layerTag = "map"
        if not copy[map].points[point] or copy[map].points[point].star <= 0 then
            UIResponse({type = 503, msgtype = "umeng", datatype = "failLevel", level = "brave_"..map.."_"..point })
        end
    elseif t.result == 1 then
        ---t.battlereport = copyAttackResultPb.battlereport
        t.battlereport = PickBattleResultReport(copyAttackResultPb)
        t.star = copyAttackResultPb.star
        if not copy[map].points[point] or copy[map].points[point].star <= 0 then
            UIResponse({type = 503, msgtype = "umeng", datatype = "finishLevel", level = "brave_"..map.."_"..point })
            copy[map].points[point] = {
                id = gamedata.ext.bravecopyattack.point,
                star = copyAttackResultPb.star,
                kill = 1,
            }
            t.layerTag = "map"
            if not config[tostring(map)][tostring(point+1)] then
                if not config[tostring(map+1)] then
                    print("已通关")
                else
                    copy[map + 1] = {
                        id = map + 1,
                        status = 0,
                        prestige = 0,
                        pa1 = 1,
                        pa2 = 1,
                        pa3 = 1,
                        points = {},
                    }

                end
                t.layerTag = "chapter"
                t.showpassreward = true
            end

        else
            if copy[map].points[point].star < copyAttackResultPb.star then
                copy[map].points[point].star = copyAttackResultPb.star
            end
            copy[map].points[point].kill = copy[map].points[point].kill + 1
            t.layerTag = "map"
        end

        if copyAttackResultPb.star == 3 then
            local isallstar = true
            for k,v in pairs(config[tostring(map)]) do
                if not copy[map].points[tonumber(k)] or copy[map].points[tonumber(k)].star < 3 then
                    isallstar = false
                    break
                end
            end
            if isallstar and copy[map].status < 3 then
                copy[map].status = 3
            end
        end

        gamedata:Generals(copyAttackResultPb.generals)

        t.generalexp = gamedata:GeneralsEXP(copyAttackResultPb.exp.generals)
    end

    makeGetCoin(t)
--    for k,v in ipairs(t.reward) do
--        if v.cid == 1000 then
--            t.coin = v.num
--            break
--        end
--    end
    t.bravecopy = makeBraveCopyData()
    t.map = map
    t.point = point

    return t
end

------------------------------------------------------------------------------------------------------------------------------

function UIBraveCopyAttack2Callback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1337, "Bravecopyattack2")
    local CopyAttack = ids_pb.Ids()
    CopyAttack:ParseFromString(fd.rbuf)

    table.insert(CopyAttack.ids,uireq.map)
    table.insert(CopyAttack.ids,uireq.point)

    gamedata.ext.bravecopyattack = {map = uireq.map, point = uireq.point }

    local config = gamedata.config.brave_copy
    local copy = gamedata.cache.bravecopy

    if gamedata.cache.role.stamina < config[tostring(uireq.map)][tostring(uireq.point)].physical then
        return  0, 503, {type = 503, msgtype = "shortphysical" , param = gamedata.cache.props }
    elseif copy[uireq.map].points[uireq.point] and copy[uireq.map].points[uireq.point].kill >=  config[tostring(uireq.map)][tostring(uireq.point)].challenge then
        return  0, 503, {type = 503, msgtype = "shortCopyChallenge" , msg = "挑战次数不足！" }
    else
        return 1, 1337, CopyAttack:SerializeToString()
    end

end

function NetBraveCopyAttack2Callback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1337, "Bravecopyattack2")
    local copyAttackResultPb = battleresult_pb.BattleResult()
    copyAttackResultPb:ParseFromString(fd.rbuf)

    local t = {
        type = 1337,
        result = copyAttackResultPb.result,
        reward = gamedata:SomethingProcess(copyAttackResultPb.reward),
        exp =  gamedata:updateRoleExp(copyAttackResultPb.exp),
        encounters = gamedata:Encounters(copyAttackResultPb.encounters)
    }

    local point = gamedata.ext.bravecopyattack.point
    local map = gamedata.ext.bravecopyattack.map

    local copy = gamedata.cache.bravecopy
    local config = gamedata.config.brave_copy
    gamedata:updateRoleStamina(-config[tostring(map)][tostring(point)].physical)

    local oldstar = copy[map].points[point] and copy[map].points[point].star or 0

    if copy[map].points[point] and copy[map].points[point].star >=3 then
        t.passbattle = true
    end


    t.fightbg = gamedata.config.section[tostring(gamedata.config.brave_map[tostring(map)].section)].basemap

    if not copy[map].points[point] or copy[map].points[point].star <= 0 then
        UIResponse({type = 503, msgtype = "umeng", datatype = "startLevel", level = "brave_"..map.."_"..point })
    end

    if t.result == 0 then
        ---t.battlereport = copyAttackResultPb.battlereport
        t.battlereport = PickBattleResultReport(copyAttackResultPb)
        t.layerTag = "map"
        if not copy[map].points[point] or copy[map].points[point].star <= 0 then
            UIResponse({type = 503, msgtype = "umeng", datatype = "failLevel", level = "brave_"..map.."_"..point })
        end
    elseif t.result == 1 then
        ---t.battlereport = copyAttackResultPb.battlereport
        t.battlereport = PickBattleResultReport(copyAttackResultPb)
        t.star = copyAttackResultPb.star
        if not copy[map].points[point] or copy[map].points[point].star <= 0 then
            UIResponse({type = 503, msgtype = "umeng", datatype = "finishLevel", level = "brave_"..map.."_"..point })
            copy[map].points[point] = {
                id = gamedata.ext.bravecopyattack.point,
                star = copyAttackResultPb.star,
                kill = 1,
            }
            t.layerTag = "map"
            if not config[tostring(map)][tostring(point+1)] then
                if not config[tostring(map+1)] then
                    print("已通关")
                else
                    copy[map + 1] = {
                        id = map + 1,
                        status = 0,
                        prestige = 0,
                        pa1 = 1,
                        pa2 = 1,
                        pa3 = 1,
                        points = {},
                    }

                end
                t.layerTag = "chapter"
            end
            t.update = true
        else
            if copy[map].points[point].star < copyAttackResultPb.star then
                copy[map].points[point].star = copyAttackResultPb.star
            end
            copy[map].points[point].kill = copy[map].points[point].kill + 1
            t.layerTag = "map"
        end

        if copyAttackResultPb.star == 3 then
            local isallstar = true
            for k,v in pairs(config[tostring(map)]) do
                if not copy[map].points[tonumber(k)] or copy[map].points[tonumber(k)].star < 3 then
                    isallstar = false
                    break
                end
            end
            if isallstar and copy[map].status < 3 then
                copy[map].status = 3
            end
        end

        gamedata:Generals(copyAttackResultPb.generals)

        t.generalexp = gamedata:GeneralsEXP(copyAttackResultPb.exp.generals)
    end

    makeBattleReward(t,config[tostring(map)][tostring(point)].coin*((oldstar ~= 3 and copy[map].points[point] and copy[map].points[point].star==3) and 3 or 1))

    t.bravecopy = makeBraveCopyData()
    t.map = map
    t.point = point

    return t
end

------------------------------------------------------------------------------------------------------------------------------

function UIBraveCopyAll3StarRewardCallback(uireq)
    local copyAll3StarAwardReqquest = copyAll3StarAwardPb.CopyAll3StarReward()
    copyAll3StarAwardReqquest.map = uireq.map

    gamedata.ext.bravecopyAll3StarAwardReqquest= uireq.map
    return 1,1333,copyAll3StarAwardReqquest:SerializeToString()
end


function NetBraveCopyAll3StarRewardCallback(fd)
    local pbData = copyAll3StarAwardResultPb.Result()
    pbData:ParseFromString(fd.rbuf)
    cclog("Interface[%d] recieved data:\n%s", 1333, tostring(pbData))
    local mapId = gamedata.ext.bravecopyAll3StarAwardReqquest
    local stamina = gamedata.config.brave_map[tostring(mapId)] and gamedata.config.brave_map[tostring(mapId)].stamina+0 or 0

    if pbData.result then
        gamedata.cache.bravecopy[mapId].status = 4
        gamedata:updateRoleStamina(stamina)
    end

    return { type = 1333, result = pbData.result, bravecopy = makeBraveCopyData(), stamina = stamina, }
end

------------------------------------------------------------------------------------------------------------------------------

function UIBraveCopyWipeCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1332, "Bravecopyattack")
    local CopyAttack = copyattack_pb.CopyAttack()
    CopyAttack.map = uireq.map
    CopyAttack.point = uireq.point

    gamedata.ext.bravecopyattackwipe = {map = uireq.map, point = uireq.point}

    local config = gamedata.config.brave_copy
    if gamedata.cache.role.stamina < config[tostring(uireq.map)][tostring(uireq.point)].physical then
        return  0, 503, {type = 503, msgtype = "shortphysical", param = gamedata.cache.props  }
    else
        return 1, 1332, CopyAttack:SerializeToString()
    end

end

function NetBraveCopyWipeCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1332, "Bravecopyattack")
    local copyAttackResultPb = battleresult_pb.BattleResult()
    copyAttackResultPb:ParseFromString(fd.rbuf)

    local t = {
        type = 1332,
        reward = gamedata:SomethingProcess(copyAttackResultPb.reward),
        exp =  gamedata:updateRoleExp(copyAttackResultPb.exp),

    }

    local point = gamedata.ext.bravecopyattackwipe.point
    local map = gamedata.ext.bravecopyattackwipe.map

    local copy = gamedata.cache.bravecopy
    local config = gamedata.config.brave_copy

    local challenge = math.min(5,config[tostring(map)][tostring(point)].challenge - copy[map].points[point].kill)

    challenge = math.min(challenge,math.floor(gamedata.cache.role.stamina/config[tostring(map)][tostring(point)].physical))

    copy[map].points[point].kill = copy[map].points[point].kill + challenge
--    copy[map].prestige =  copy[map].prestige + challenge
--    if copy[map].prestige >= gamedata.config.brave_map[tostring(map)].prestige then
--        for i=1,3 do
--            if copy[map]["pa"..i] == 1 then
--                copy[map]["pa"..i] = 2
--            end
--        end
--        copy[map].prestige = gamedata.config.map[tostring(map)].prestige
--    end
    gamedata:updateRoleStamina(0-config[tostring(map)][tostring(point)].physical*challenge)

    gamedata:Generals(copyAttackResultPb.generals)

    t.bravecopy = makeBraveCopyData()
    t.map = map
    t.point = point

    makeGetCoin(t)
--    for k,v in ipairs(t.reward) do
--        if v.cid == 1000 then
--            t.coin = v.num
--            break
--        end
--    end
    t.generalexp = gamedata:GeneralsEXP(copyAttackResultPb.exp.generals)
    t.slots = gamedata.cache.slots

    return t
end
------------------------------------------------------------------------------------------------------------------------------

function UIBraveCopyWipe2Callback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1338, "BraveCopyWipe2")
    local CopyAttack = ids_pb.Ids()
    CopyAttack:ParseFromString(fd.rbuf)

    table.insert(CopyAttack.ids,uireq.map)
    table.insert(CopyAttack.ids,uireq.point)
    table.insert(CopyAttack.ids,uireq.method)

    gamedata.ext.bravecopyattackwipe = uireq

    local config = gamedata.config.brave_copy
    if gamedata.cache.role.stamina < config[tostring(uireq.map)][tostring(uireq.point)].physical then
        return  0, 503, {type = 503, msgtype = "shortphysical", param = gamedata.cache.props  }
    else
        return 1, 1338, CopyAttack:SerializeToString()
    end

end

function NetBraveCopyWipe2Callback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1338, "BraveCopyWipe2")
    local copyAttackResultPb = battleresult_pb.BattleResult()
    copyAttackResultPb:ParseFromString(fd.rbuf)

    local t = {
        type = 1338,
        reward = gamedata:SomethingProcess(copyAttackResultPb.reward),
        exp =  gamedata:updateRoleExp(copyAttackResultPb.exp),
        encounters = gamedata:Encounters(copyAttackResultPb.encounters)
    }

    local point = gamedata.ext.bravecopyattackwipe.point
    local map = gamedata.ext.bravecopyattackwipe.map

    local copy = gamedata.cache.bravecopy
    local config = gamedata.config.brave_copy

    local challenge = 1
    if gamedata.ext.bravecopyattackwipe.method == 1 then
        challenge = config[tostring(map)][tostring(point)].challenge - copy[map].points[point].kill
        challenge = math.min(challenge,math.floor(gamedata.cache.role.stamina/config[tostring(map)][tostring(point)].physical))
    end

    copy[map].points[point].kill = copy[map].points[point].kill + challenge
    gamedata:updateRoleStamina(0-config[tostring(map)][tostring(point)].physical*challenge)

    gamedata:Generals(copyAttackResultPb.generals)

    t.bravecopy = makeBraveCopyData()
    t.map = map
    t.point = point

    makeBattleReward(t,config[tostring(map)][tostring(point)].coin*challenge)

    t.generalexp = gamedata:GeneralsEXP(copyAttackResultPb.exp.generals)
    t.slots = gamedata.cache.slots

    return t
end

------------------------------------------------------------------------------------------------------------------------------

function UIBraveCopyPrestigeRewardCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1334, "BravePrestigeReward")
    local PrestigeReward = ids_pb.Ids()

    table.insert(PrestigeReward.ids,uireq.map)
    table.insert(PrestigeReward.ids,uireq.method)

    gamedata.ext.bravecopyPrestigeRewardmap = uireq.map
    gamedata.ext.bravecopyPrestigeRewardmethod = uireq.method

    return 1, 1334, PrestigeReward:SerializeToString()
end

function NetBraveCopyPrestigeRewardCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1334, "BravePrestigeReward")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    local key = ""
    if gamedata.ext.bravecopyPrestigeRewardmethod == 0 then
        key = "pa1"
    elseif gamedata.ext.bravecopyPrestigeRewardmethod == 3 then
        key = "pa2"
    elseif gamedata.ext.bravecopyPrestigeRewardmethod == 6 then
        key = "pa3"
    end

    gamedata.cache.bravecopy[gamedata.ext.bravecopyPrestigeRewardmap][key] = 3

    return { type = 1334, reward = gamedata:SomethingProcess(SomeThings),bravecopy = makeBraveCopyData(),map = gamedata.ext.bravecopyPrestigeRewardmap}
end

---------------------------------------------------------------------------------------------------------------------------

function UIBraveCopyResetKillCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1335, "BraveCopyResetKill")
    local CopyAttack = copyattack_pb.CopyAttack()
    CopyAttack.map = uireq.map
    CopyAttack.point = uireq.point

    gamedata.ext.copyBraveattackResetKill = {map = uireq.map, point = uireq.point }

    return 1, 1335, CopyAttack:SerializeToString()
end

function NetBraveCopyResetKillCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1335, "BraveCopyResetKill")
    local Result = result_pb.Result()
    Result:ParseFromString(fd.rbuf)

    local location = gamedata.ext.copyBraveattackResetKill

    gamedata.cache.bravecopy[location.map].points[location.point].kill = 0

    gamedata:updateRoleGold(-5*gamedata.config.brave_copy[tostring(location.map)][tostring(location.point)].challenge,"精英副本挑战次数", gamedata.config.brave_copy[tostring(location.map)][tostring(location.point)].challenge)

    return { type = 1335, bravecopy = makeBraveCopyData()}
end

