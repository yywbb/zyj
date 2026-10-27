--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/25
-- Time: 上午9:31
-- To change this template use File | Settings | File Templates.
--

--与海外版有差异，重置关卡消耗元宝数量，海外版走阶梯价格

local copies_pb = require("copies_pb")
local copyattack_pb = require("copyattack_pb")
local battleresult_pb = require("battleresult_pb")
local copyAll3StarAwardPb = require("copyall3starreward_pb")
local copyAll3StarAwardResultPb = require("result_pb")
local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")

require"PickBattleResultReport"

local function makeCopyData()

    local copyConfig = gamedata.config.map
    local sectionConfig = gamedata.config.section
    local pointConfig = gamedata.config.copy

    local copy ={}
    for k,v in pairs(table.copy(gamedata.cache.copy)) do
        local section = copyConfig[tostring(v.id)].section-40000
        if section<=table.getTableLength(sectionConfig) then
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
                    move = 0,
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
            table.insert(copy[section].maps, v)
        end
    end

    for k,v in pairs(copy) do
        local sortfunc = function(a,b) return a.id < b.id end
        table.sort(v.maps,sortfunc)
    end

    return copy
end


function makeGetCoin(t)
    for k,v in ipairs(t.reward) do
        if v.cid == 1000 then
            t.coin = v.num
            break
        end
    end
    t.coin = t.coin or 0

    if t.exp and next(t.exp) and t.exp.oldlevel< t.exp.newlevel then
        local newconfig = gamedata.config.role_exp[tostring(t.exp.newlevel)]
        gamedata.ext.roleextcoin = gamedata.cache.role.coin
        gamedata.ext.roleextgold = gamedata.cache.role.gold
        gamedata.cache.role.coin = gamedata.cache.role.coin - newconfig.c_reward
        t.coin =t.coin - newconfig.c_reward
    end
end

function makeBattleReward(t,coin)
    t.coin = coin

    if t.exp and next(t.exp) and t.exp.oldlevel< t.exp.newlevel then
        local newconfig = gamedata.config.role_exp[tostring(t.exp.newlevel)]
        t.exp.levelreward = {
            gold =  newconfig.g_reward,
            coin =  newconfig.c_reward,
        }
--        gamedata.ext.roleextcoin = gamedata.cache.role.coin
--        gamedata.ext.roleextgold = gamedata.cache.role.gold
--        gamedata.cache.role.coin = gamedata.cache.role.coin - newconfig.c_reward
--        gamedata.cache.role.gold = gamedata.cache.role.gold - newconfig.g_reward
    end
    local newreward = {}
    for k,v in ipairs(t.reward) do
        if v.cid == 1000 then
            v.num = v.num - coin*((v.double and v.double == 1) and 2 or 1) - (t.exp.levelreward and t.exp.levelreward.coin or 0)
        elseif v.cid == 1001 then
            v.num = v.num - (t.exp.levelreward and t.exp.levelreward.gold or 0)
        end
        if v.num >0 then
            table.insert(newreward,v)
        end
    end

    t.reward = newreward
end


function UICopyQueryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1300, "copyquery")

    if next(gamedata.cache.copy) then
        return 0, 1300, { type = uireq.type, copy = makeCopyData()}
    else
        return 1, 1300, nil
    end
end

function NetCopyQueryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1300, "copyquery")
    local copyData = copies_pb.Copies()
    copyData:ParseFromString(fd.rbuf)

    gamedata:Copies(copyData)

    return { type = 1300, copy = makeCopyData()}--, copywipetimer = gamedata.cache.copywipetimer}
end

------------------------------------------------------------------------------------------------------------------------------

function UICopyAttackCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1301, "copyattack")
    local CopyAttack = copyattack_pb.CopyAttack()
    CopyAttack.map = uireq.map
    CopyAttack.point = uireq.point

    gamedata.ext.copyattack = {map = uireq.map, point = uireq.point }

    local config = gamedata.config.copy
    local copy = gamedata.cache.copy

    if gamedata.cache.role.stamina < config[tostring(uireq.map)][tostring(uireq.point)].physical then
        return  0, 503, {type = 503, msgtype = "shortphysical", param = gamedata.cache.props }
    elseif copy[uireq.map].points[uireq.point] and copy[uireq.map].points[uireq.point].kill >=  config[tostring(uireq.map)][tostring(uireq.point)].challenge then
        return  0, 503, {type = 503, msgtype = "shortCopyChallenge" , msg = "挑战次数不足！" }
    else
        return 1, 1301, CopyAttack:SerializeToString()
    end

end

function NetCopyAttackCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1301, "copyattack")
    local copyAttackResultPb = battleresult_pb.BattleResult()
    copyAttackResultPb:ParseFromString(fd.rbuf)

    local t = {
        type = 1301,
        result = copyAttackResultPb.result,
        reward = gamedata:SomethingProcess(copyAttackResultPb.reward),
        exp =  gamedata:updateRoleExp(copyAttackResultPb.exp),
    }

    local point = gamedata.ext.copyattack.point
    local map = gamedata.ext.copyattack.map

    local copy = gamedata.cache.copy
    local config = gamedata.config.copy
    gamedata:updateRoleStamina(-config[tostring(map)][tostring(point)].physical)

    if copy[map].points[point] and copy[map].points[point].star >=3 then
        t.passbattle = true
    elseif gamedata.config.global_kv.skip_the_battle_chapter and (map > tonumber(gamedata.config.global_kv.skip_the_battle_chapter.value)) then
        t.passbattle = true
    elseif gamedata.config.global_kv.skip_the_battle_chapter and copy[tonumber(gamedata.config.global_kv.skip_the_battle_chapter.value)] and copy[tonumber(gamedata.config.global_kv.skip_the_battle_chapter.value)].points and copy[tonumber(gamedata.config.global_kv.skip_the_battle_chapter.value)].points[10] and copy[tonumber(gamedata.config.global_kv.skip_the_battle_chapter.value)].points[10].star and copy[tonumber(gamedata.config.global_kv.skip_the_battle_chapter.value)].points[10].star > 0 then     
        t.passbattle = true
    end


    t.fightbg = gamedata.config.section[tostring(gamedata.config.map[tostring(map)].section)].basemap

    if t.result == -1 then
        t.encounters = gamedata:Encounters(copyAttackResultPb.encounters)

        if not copy[map].points[point] then
            copy[map].points[point] = {
                id = gamedata.ext.copyattack.point,
                move = 1,
                star = 0,
                kill = 0,
            }
            UIResponse({type = 503, msgtype = "umeng", datatype = "startLevel", level = "normal_"..map.."_"..point })
        else
            copy[map].points[point].move = copy[map].points[point].move +1
        end
        t.move = copy[map].points[point].move
    elseif t.result == 0 then
        t.battlereport = PickBattleResultReport(copyAttackResultPb)
        t.layerTag = "point"
        if not copy[map].points[point] or copy[map].points[point].star <= 0 then
            UIResponse({type = 503, msgtype = "umeng", datatype = "failLevel", level = "normal_"..map.."_"..point })
            t.palyprestory = true
            t.palybattlestory = true
        end

    elseif t.result == 1 then
        t.battlereport = PickBattleResultReport(copyAttackResultPb)
        t.star = copyAttackResultPb.star
        if not copy[map].points[point] or copy[map].points[point].star <= 0 then
            UIResponse({type = 503, msgtype = "umeng", datatype = "finishLevel", level = "normal_"..map.."_"..point })

            t.palyprestory = true
            t.palybattlestory = true
            t.palybackstory = true

            copy[map].points[point] = {
                id = gamedata.ext.copyattack.point,
                move = 0,
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
                        points = {

                        },
                    }

                end
                t.layerTag = "chapter"
                for i=1,3 do
                    if copy[map]["pa"..i] == 1 then
                        copy[map]["pa"..i] = 2
                    end
                end
                t.showpassreward = true
            end

        else
            if copy[map].points[point].star < copyAttackResultPb.star then
                copy[map].points[point].star = copyAttackResultPb.star
            end
            copy[map].points[point].move = 0
            copy[map].points[point].kill = copy[map].points[point].kill + 1
            t.layerTag = "point"
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


        if copy[map].points[point].kill == config[tostring(map)][tostring(point)].challenge then
            t.layerTag = "map"
            t.noupdate = true
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


    t.copy = makeCopyData()
    t.map = map
    t.point = point


    return t
end
------------------------------------------------------------------------------------------------------------------------------

function UICopyAttack2Callback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1306, "copyattack2。")
    local CopyAttack = ids_pb.Ids()

    table.insert(CopyAttack.ids,uireq.map)
    table.insert(CopyAttack.ids,uireq.point)

    gamedata.ext.copyattack = {map = uireq.map, point = uireq.point }

    local config = gamedata.config.copy
    local copy = gamedata.cache.copy

    if gamedata.cache.role.stamina < config[tostring(uireq.map)][tostring(uireq.point)].physical then
        return  0, 503, {type = 503, msgtype = "shortphysical", param = gamedata.cache.props }
    elseif copy[uireq.map].points[uireq.point] and copy[uireq.map].points[uireq.point].kill >=  config[tostring(uireq.map)][tostring(uireq.point)].challenge then
        return  0, 503, {type = 503, msgtype = "shortCopyChallenge" , msg = "挑战次数不足！" }
    else
        return 1, 1306, CopyAttack:SerializeToString()
    end

end

function NetCopyAttack2Callback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1306, "copyattack2")
    local copyAttackResultPb = battleresult_pb.BattleResult()
    copyAttackResultPb:ParseFromString(fd.rbuf)
--
--    local checkresult = true
--    if copyAttackResultPb.reward.pext5 and copyAttackResultPb.reward.pext5[1] then
--        print("copyattack2")
--        print(copyAttackResultPb.reward.pext5[1].ids[1],copyAttackResultPb.reward.pext5[1].ids[2],"copyattack2")
--        if copyAttackResultPb.reward.pext5[1].ids[1] ~= gamedata.ext.copyattack.map or copyAttackResultPb.reward.pext5[1].ids[2] ~= gamedata.ext.copyattack.point then
--            checkresult = false
--        end
--    end
--    if not checkresult then
--        return  0, 503, {type = 503, msg = "操作失败，请重试" }
--    end
--


    local t = {
        type = 1306,
        result = copyAttackResultPb.result,
        reward = gamedata:SomethingProcess(copyAttackResultPb.reward),
        exp =  gamedata:updateRoleExp(copyAttackResultPb.exp),
        encounters = gamedata:Encounters(copyAttackResultPb.encounters)
    }
    local point = gamedata.ext.copyattack.point
    local map = gamedata.ext.copyattack.map

    local copy = gamedata.cache.copy
    local config = gamedata.config.copy
    gamedata:updateRoleStamina(-config[tostring(map)][tostring(point)].physical)

    if copy[map].points[point] and copy[map].points[point].star >=3 then
        t.passbattle = true
    elseif gamedata.config.global_kv.skip_the_battle_chapter and (map > tonumber(gamedata.config.global_kv.skip_the_battle_chapter.value)) then
        t.passbattle = true
    elseif gamedata.config.global_kv.skip_the_battle_chapter and copy[tonumber(gamedata.config.global_kv.skip_the_battle_chapter.value)] and copy[tonumber(gamedata.config.global_kv.skip_the_battle_chapter.value)].points and copy[tonumber(gamedata.config.global_kv.skip_the_battle_chapter.value)].points[10] and copy[tonumber(gamedata.config.global_kv.skip_the_battle_chapter.value)].points[10].star and copy[tonumber(gamedata.config.global_kv.skip_the_battle_chapter.value)].points[10].star > 0 then
        t.passbattle = true
    end


    local oldstar = copy[map].points[point] and copy[map].points[point].star or 0

    t.fightbg = gamedata.config.section[tostring(gamedata.config.map[tostring(map)].section)].basemap

    if t.result == 0 then
        t.battlereport = PickBattleResultReport(copyAttackResultPb)
        t.layerTag = "map"
        if not copy[map].points[point] or copy[map].points[point].star <= 0 then
            UIResponse({type = 503, msgtype = "umeng", datatype = "failLevel", level = "normal_"..map.."_"..point })
            t.palyprestory = true
            t.palybattlestory = true
        end

    elseif t.result == 1 then
        t.battlereport = PickBattleResultReport(copyAttackResultPb)
        t.star = copyAttackResultPb.star
        if not copy[map].points[point] or copy[map].points[point].star <= 0 then
            UIResponse({type = 503, msgtype = "umeng", datatype = "finishLevel", level = "normal_"..map.."_"..point })

            t.palyprestory = true
            t.palybattlestory = true
            t.palybackstory = true

            copy[map].points[point] = {
                id = gamedata.ext.copyattack.point,
                move = 0,
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
            copy[map].points[point].move = 0
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

    t.copy = makeCopyData()
    t.map = map
    t.point = point


    return t
end

------------------------------------------------------------------------------------------------------------------------------

function UICopyAll3StarRewardCallback(uireq)
    local copyAll3StarAwardReqquest = copyAll3StarAwardPb.CopyAll3StarReward()
    copyAll3StarAwardReqquest.map = uireq.map

    gamedata.ext.copyAll3StarAwardReqquest= uireq.map
    return 1,1303,copyAll3StarAwardReqquest:SerializeToString()
end


function NetCopyAll3StarRewardCallback(fd)
    local pbData = copyAll3StarAwardResultPb.Result()
    pbData:ParseFromString(fd.rbuf)
    cclog("Interface[%d] recieved data:\n%s", 1303, tostring(pbData))
    local mapId = gamedata.ext.copyAll3StarAwardReqquest
    local stamina = gamedata.config.map[tostring(mapId)] and gamedata.config.map[tostring(mapId)].stamina+0 or 0

    if pbData.result then
        gamedata.cache.copy[mapId].status = 4
        gamedata:updateRoleStamina(stamina)
    end

    return { type = 1303, result = pbData.result, copy = makeCopyData(), stamina = stamina, }
end

------------------------------------------------------------------------------------------------------------------------------

function UICopyWipeCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1302, "copyattack")
    local CopyAttack = copyattack_pb.CopyAttack()
    CopyAttack.map = uireq.map
    CopyAttack.point = uireq.point

    gamedata.ext.copyattackwipe = {map = uireq.map, point = uireq.point}

    local config = gamedata.config.copy

    if gamedata.cache.role.stamina < config[tostring(uireq.map)][tostring(uireq.point)].physical then
        return  0, 503, {type = 503, msgtype = "shortphysical",param = gamedata.cache.props }
    else
        return 1, 1302, CopyAttack:SerializeToString()
    end

end

function NetCopyWipeCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1302, "copyattack")
    local copyAttackResultPb = battleresult_pb.BattleResult()
    copyAttackResultPb:ParseFromString(fd.rbuf)

    local t = {
        type = 1302,
        reward = gamedata:SomethingProcess(copyAttackResultPb.reward),
        exp =  gamedata:updateRoleExp(copyAttackResultPb.exp),
    }

    local point = gamedata.ext.copyattackwipe.point
    local map = gamedata.ext.copyattackwipe.map

    local copy = gamedata.cache.copy
    local config = gamedata.config.copy

    local battleTimes = 0
    local StaminaConsum = 0
    local challenge = math.min(5,config[tostring(map)][tostring(point)].challenge - copy[map].points[point].kill)

    while battleTimes < challenge and StaminaConsum+config[tostring(map)][tostring(point)].physical <= gamedata.cache.role.stamina do
        copy[map].points[point].move = copy[map].points[point].move +1
        StaminaConsum = StaminaConsum+ config[tostring(map)][tostring(point)].physical

        if copy[map].points[point].move == config[tostring(map)][tostring(point)].move+1 then
            battleTimes = battleTimes +1
            copy[map].points[point].move = 0
        end
    end

    copy[map].points[point].kill = copy[map].points[point].kill + battleTimes
--    copy[map].prestige =  copy[map].prestige + StaminaConsum
--    if copy[map].prestige >= gamedata.config.map[tostring(map)].prestige then
--        for i=1,3 do
--            if copy[map]["pa"..i] == 1 then
--                copy[map]["pa"..i] = 2
--            end
--        end
--        copy[map].prestige = gamedata.config.map[tostring(map)].prestige
--    end
    gamedata:updateRoleStamina(-StaminaConsum)


    gamedata:Generals(copyAttackResultPb.generals)

    t.encounters = gamedata:Encounters(copyAttackResultPb.encounters)

    t.generalexp = gamedata:GeneralsEXP(copyAttackResultPb.exp.generals)
    t.slots = gamedata.cache.slots

    t.copy = makeCopyData()
    t.map = map
    t.point = point

    makeBattleReward(t,config[tostring(map)][tostring(point)].coin*battleTimes)

    return t
end

------------------------------------------------------------------------------------------------------------------------------

function UICopyWipe2Callback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1307, "CopyWipe2")
    local CopyAttack = ids_pb.Ids()

    table.insert(CopyAttack.ids,uireq.map)
    table.insert(CopyAttack.ids,uireq.point)
    table.insert(CopyAttack.ids,uireq.method)
    table.insert(CopyAttack.ids,uireq.exchange or 0)


    gamedata.ext.copyattackwipe = uireq
    gamedata.ext.exchange = uireq.exchange or 0

    local config = gamedata.config:getConfigByName("copy")

    if gamedata.cache.role.stamina < config[tostring(uireq.map)][tostring(uireq.point)].physical then
        return  0, 503, {type = 503, msgtype = "shortphysical",param = gamedata.cache.props }
    else
        return 1, 1307, CopyAttack:SerializeToString()
    end

end

function NetCopyWipe2Callback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1307, "CopyWipe2")
    local copyAttackResultPb = battleresult_pb.BattleResult()
    copyAttackResultPb:ParseFromString(fd.rbuf)

    local t = {
        type = 1307,
        reward = gamedata:SomethingProcess(copyAttackResultPb.reward),
        exp =  gamedata:updateRoleExp(copyAttackResultPb.exp),
        encounters = gamedata:Encounters(copyAttackResultPb.encounters),
        exchange = gamedata.ext.exchange or 0
    }
    local point = gamedata.ext.copyattackwipe.point
    local map = gamedata.ext.copyattackwipe.map

    local copy = gamedata.cache.copy
    local config = gamedata.config:getConfigByName("copy")

    local challenge = 1
    if gamedata.ext.copyattackwipe.method == 1 then
        challenge = config[tostring(map)][tostring(point)].challenge - copy[map].points[point].kill
        challenge = math.min(challenge,math.floor(gamedata.cache.role.stamina/config[tostring(map)][tostring(point)].physical))
    end
    copy[map].points[point].kill = copy[map].points[point].kill + challenge
    gamedata:updateRoleStamina(0-config[tostring(map)][tostring(point)].physical*challenge)

    gamedata:Generals(copyAttackResultPb.generals)

    t.generalexp = gamedata:GeneralsEXP(copyAttackResultPb.exp.generals)
    t.slots = gamedata.cache.slots

    t.copy = makeCopyData()
    t.map = map
    t.point = point

    makeBattleReward(t,config[tostring(map)][tostring(point)].coin*challenge)
    --    for k,v in ipairs(t.reward) do
    --        if v.cid == 1000 then
    --            t.coin = v.num
    --            break
    --        end
    --    end

    return t
end

------------------------------------------------------------------------------------------------------------------------------

function UICopyPrestigeRewardCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1304, "PrestigeReward")
    local PrestigeReward = ids_pb.Ids()

    table.insert(PrestigeReward.ids,uireq.map)
    table.insert(PrestigeReward.ids,uireq.method)

    gamedata.ext.copyPrestigeRewardmap = uireq.map
    gamedata.ext.copyPrestigeRewardmethod = uireq.method

    return 1, 1304, PrestigeReward:SerializeToString()
end

function NetCopyPrestigeRewardCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1304, "PrestigeReward")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    local key = ""
    if gamedata.ext.copyPrestigeRewardmethod == 0 then
        key = "pa1"
    elseif gamedata.ext.copyPrestigeRewardmethod == 3 then
        key = "pa2"
    elseif gamedata.ext.copyPrestigeRewardmethod == 6 then
        key = "pa3"
    end

    gamedata.cache.copy[gamedata.ext.copyPrestigeRewardmap][key] = 3

    return { type = 1304, reward = gamedata:SomethingProcess(SomeThings),copy = makeCopyData(), map = gamedata.ext.copyPrestigeRewardmap}
end

---------------------------------------------------------------------------------------------------------------------------
-- 消耗元宝数量与海外版有差异
function UICopyResetKillCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1305, "CopyResetKill")
    local CopyAttack = copyattack_pb.CopyAttack()
    CopyAttack.map = uireq.map
    CopyAttack.point = uireq.point

    gamedata.ext.copyattackResetKill = {map = uireq.map, point = uireq.point }

    return 1, 1305, CopyAttack:SerializeToString()
end
-- 消耗元宝数量与海外版有差异
function NetCopyResetKillCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1305, "CopyResetKill")
    local Result = result_pb.Result()
    Result:ParseFromString(fd.rbuf)

    local location = gamedata.ext.copyattackResetKill

    gamedata.cache.copy[location.map].points[location.point].kill = 0

    gamedata:updateRoleGold(-5*gamedata.config.copy[tostring(location.map)][tostring(location.point)].challenge,"副本挑战次数",gamedata.config.copy[tostring(location.map)][tostring(location.point)].challenge)

    return { type = 1305, copy = makeCopyData()}
end


---------------------------------------------------------------------------------------------------------------------------

function UICopyClearTimerCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1336, "ClearTimer")

    gamedata.ext.copyClearTimer = {datatype = uireq.datatype, gold = uireq.gold }

    return 1, 1336, nil
end

function NetCopyClearTimerCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1336, "ClearTimer")
    local Result = result_pb.Result()
    Result:ParseFromString(fd.rbuf)

    gamedata:updateRoleGold(-gamedata.ext.copyClearTimer.gold,"扫荡清CD",1)

    return { type = 1336, datatype = gamedata.ext.copyClearTimer.datatype }

end

