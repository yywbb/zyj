--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-10-17
-- Time: 上午11:17
-- To change this template use File | Settings | File Templates.
--
require"PickBattleResultReport"

local combmessages_pb = require("combmessages_pb")
local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")

function UIFriendCopyQueryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1323, "FriendCopyQuery")

    return 1, 1323, nil

end

function NetFriendCopyQueryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1323, "FriendCopyQuery")
    local friendcopyData = ids_pb.Ids()
    friendcopyData:ParseFromString(fd.rbuf)

    gamedata:FriendCopies(friendcopyData)

    return { type = 1323, friendcopy = gamedata.cache.friendcopy}
end



local function makeFriendCopyGeneral()
    local friends = table.copy(gamedata.cache.friends.friends)

    local friends_ = {}
    for k,v in pairs(friends) do
        v.power = v.params[1].i
        v.use = v.use ==1 and 0 or 1
        table.insert(friends_,v)
    end

    gamedata.sortData(friends_, "use", "power")
    return friends_
end

function UIFriendCopyFriendSelectCallBack(uireq)
    print("请求好友助阵数据13201 接收UI请求")
    return 0, 13201, {type = 13201, data = makeFriendCopyGeneral()}
end



function UIFriendCopyAttackCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1324, "copyattack")
    local FriendCopyAttack = ids_pb.Ids()

    table.insert(FriendCopyAttack.ids,uireq.map)
    table.insert(FriendCopyAttack.ids,uireq.help)

    if gamedata.cache.friendcopy.kill <=0 then
        return 0,503,{type = 503, msgtype = "shortFriendKill"}
    end

    gamedata.ext.friendcopyattack = {map = uireq.map, help = uireq.help}


    return 1, 1324, FriendCopyAttack:SerializeToString()
end

local battleresult_pb = require("battleresult_pb")
function NetFriendCopyAttackCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1324, "copyattack")
    local copyAttackResultPb = battleresult_pb.BattleResult()
    copyAttackResultPb:ParseFromString(fd.rbuf)

    local t = {
        type = 1324,
        result = copyAttackResultPb.result,
        reward = gamedata:SomethingProcess(copyAttackResultPb.reward),
        ---battlereport = copyAttackResultPb.battlereport,
        battlereport1 = copyAttackResultPb.battlereport2, --PickBattleResultReportByKey(copyAttackResultPb,"battlereport2"),
        battlereport2 = copyAttackResultPb.battlereport3 --PickBattleResultReportByKey(copyAttackResultPb,"battlereport3")
    }

    gamedata.cache.friendcopy.kill= gamedata.cache.friendcopy.kill -1
    gamedata.cache.friends.friends[gamedata.ext.friendcopyattack.help].use = 1

    if copyAttackResultPb.result then
        for k,v in pairs(gamedata.cache.friendcopy.maps) do
             if v.id == gamedata.ext.friendcopyattack.map then
                 if v.kill <0 then
                     v.kill = 1
                 else
                    v.kill = v.kill +1
                 end
             end
        end
    end

    return t
end


function UIFriendCopyRankCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1322, "FriendCopyRank")
    if next(gamedata.cache.friendcopyrank) then
        return 0, 1322, { type = uireq.type, friendcopyrank = gamedata.cache.friendcopyrank,}
    else
        return 1, 1322, nil
    end
end


function NetFriendCopyRankCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1322, "FriendCopyRank")

    local FriendCopyRankData = combmessages_pb.CombMessages()
    FriendCopyRankData:ParseFromString(fd.rbuf)
    for k,v in ipairs(FriendCopyRankData.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata.cache.friendcopyrank.mynum = ids.ids[1] or 0
        else
            local playersData = players_pb.Players()
            playersData:ParseFromString(v.data)
            gamedata.cache.friendcopyrank.players = gamedata:players(playersData.players) or {}
        end
    end

    return { type = 1322, friendcopyrank = gamedata.cache.friendcopyrank,}
end



function UIFriendCopyOneFinishCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1325, "OneFinish")
    local FriendCopyAttack = ids_pb.Ids()

    table.insert(FriendCopyAttack.ids,uireq.id)
    table.insert(FriendCopyAttack.ids,uireq.num or 1)

    if gamedata.cache.friendcopy.kill < (uireq.num or 1) then
        return 0,503,{type = 503, msgtype = "shortFriendKill"}
    end

    return 1, 1325, FriendCopyAttack:SerializeToString()
end

function NetFriendCopyOneFinishCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1325, "OneFinish")

    local  getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)
    --
    return {type = 1325,reward = gamedata:SomethingProcess(getData)}
end
------------------------------------------------------------------------------------------------------------------------------------------------------
    -----------------------------------------------------------      old code     ---------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

--local function makeOldSlotGeneral(mapdata)
--
--    local slots = mapdata.generals
--    local slotconfig = gamedata.config.role_exp
--    local opennum = slotconfig[tostring(gamedata.cache.role.level)].slotnum
--
--    local slotGenerals = {}
--    for k=1,opennum do
--        if slots[k] and slots[k] ~= 0 then
--
--            local  general
--            if not gamedata.cache.generals[slots[k]] or slots[k] == gamedata.cache.protagonist.iid then
--                slotGenerals[k] = {
--                    iid = gamedata.cache.protagonist.general.iid,
--                    cid = gamedata.cache.protagonist.general.cid,
--                    level1 = gamedata.cache.protagonist.general.level1,
--                    level2 = 0,
--                    power = gamedata.cache.protagonist.general.power,
--                }
--            else
--                local general = gamedata.cache.generals[slots[k]]
--                slotGenerals[k] = {
--                    iid = general.iid,
--                    cid = general.cid,
--                    level1 = general.level1,
--                    level2 = general.level2,
--                    power = general.power,
--                }
--            end
--        else
--            slotGenerals[k] = {}
--        end
--    end
--    return slotGenerals
--end
--
--
--
--local function makeSlotGeneral()
--
--    local slots = table.copy(gamedata.cache.slots)
--    local slotconfig = gamedata.config.role_exp
--    local opennum = slotconfig[tostring(gamedata.cache.role.level)].slotnum
--
--    local slotGenerals = {}
--    for k=1,opennum do
--        if slots[k] and slots[k].general and slots[k].general ~= 0 then
--
--            local  general
--            if not gamedata.cache.generals[slots[k].general] or slots[k].general == gamedata.cache.protagonist.iid then
--                slotGenerals[k] = {
--                    iid = gamedata.cache.protagonist.general.iid,
--                    cid = gamedata.cache.protagonist.general.cid,
--                    level1 = gamedata.cache.protagonist.general.level1,
--                    level2 = 0,
--                    power = gamedata.cache.protagonist.general.power,
--                }
--            else
--                local general = gamedata.cache.generals[slots[k].general]
--                slotGenerals[k] = {
--                    iid = general.iid,
--                    cid = general.cid,
--                    level1 = general.level1,
--                    level2 = general.level2,
--                    power = general.power,
--                }
--            end
--        else
--            slotGenerals[k] = {}
--        end
--    end
--    return slotGenerals
--end
--
--local posConfig = {
--    ["2"] = 1,
--    ["8"] = 2,
--    ["10"] = 3,
--    ["4"] = 4,
--    ["12"] = 5,
--    ["6"] = 6,
--    ["14"] = 7,
--}
--
--
--local function makeHps(report)
--
--    local HPs = {}
--    local generals= {}
--
--    for k,v in pairs(report.battle.init.attack) do
--        if k ~= "0" then
--            HPs[tonumber(k)] = {}
--            HPs[tonumber(k)].fullhp = report.meta.attack.generals[tostring(v.id)].hp2
--            HPs[tonumber(k)].hp = report.meta.attack.generals[tostring(v.id)].hp
--            generals[posConfig[tostring(k)]] = v.id
--        end
--    end
--
--    for k,v in ipairs(report.battle.action) do
--        if v.type == "battle" then
--             for km,vm in ipairs(v.dest) do
--                 if vm.damage and next(vm.damage) and vm.direct then
--                     HPs[vm.pos].hp = HPs[vm.pos].hp-vm.damage.damage
--                     if  HPs[vm.pos].hp > HPs[vm.pos].fullhp then
--                         HPs[vm.pos].hp = HPs[vm.pos].fullhp
--                     elseif HPs[vm.pos].hp < 0 then
--                         HPs[vm.pos].hp = 0
--                     end
--                 end
--             end
--        end
--    end
--
--    local hps = {}
--    for k,v in pairs(HPs) do
--        hps[posConfig[tostring(k)]]= 100*v.hp/v.fullhp
--    end
--
--    return hps, generals
--end
--
--local function makeFriendCopyGeneral(pos)
--    local friends = table.copy(gamedata.cache.friends.friends)
--
--    local generals = {}
--    for k,v in pairs(friends) do
--
--        local general = v[pos==1 and "first" or "second"]
--        general.use =  v.use
--        general.friendname =  v.name
--        general.choose = 1
--        for k,v in pairs(gamedata.cache.slots) do
--            if pos ~= k  then
--                local selfgeneral
--                if v.general and v.general ~=0 then
--                    selfgeneral = gamedata.cache.generals[v.general] or gamedata.cache.protagonist.general
--                    if general.cid == selfgeneral.cid  or (general.cid>=10101 and general.cid<=10199 and selfgeneral.cid>=10101 and selfgeneral.cid<=10199) then
--                        general.hasON = true
--                        general.choose = 0
--
--                        break
--                    end
--                end
--            end
--        end
--
--
--        table.insert(generals, general)
--    end
--
--    gamedata.sortData(generals, "choose", "power")
--    return generals
--end
--
--
--local function findSlotGeneral()
--    for k,v in pairs(gamedata.cache.friendcopy) do
--        if v.friend and v.friendgeneral then
--            return  makeOldSlotGeneral(v)
--        end
--    end
--    return  makeSlotGeneral()
--end
--
--function UIFriendCopyFriendSelectCallBack(uireq)
--    print("请求好友助阵数据13201 接收UI请求")
--    return 0, 13201, {type = 13201, pos = uireq.pos,data = makeFriendCopyGeneral(uireq.pos)}
--end
--
--function UIFriendCopyQueryCallback(uireq)
--    cclog("NET type:%d cmd:%s recv request from UI", 1320, "FriendCopyQuery")
----    if next(gamedata.cache.friendcopy) then
----        return 0, 1320, { type = uireq.type, friendcopy = gamedata.cache.friendcopy, slotGenerals = findSlotGeneral()}
----    else
--        return 1, 1320, nil
--    --end
--end
--
--local expeditions_pb = require("expeditions_pb")
--function NetFriendCopyQueryCallback(fd)
--    cclog("NET type:%d cmd:%s recv response from gameserver", 1320, "FriendCopyQuery")
--    local friendcopyData = expeditions_pb.Expeditions()
--    friendcopyData:ParseFromString(fd.rbuf)
--
--    gamedata:FriendCopies(friendcopyData)
--
--    return { type = 1320, friendcopy = gamedata.cache.friendcopy, slotGenerals = findSlotGeneral()}
--end
--
--
--local expeditionattack_pb = require("expeditionattack_pb")
--function UIFriendCopyAttackCallback(uireq)
--    cclog("NET type:%d cmd:%s recv request from UI", 1321, "copyattack")
--    local FriendCopyAttack = expeditionattack_pb.ExpeditionAttack()
--    FriendCopyAttack.map = uireq.map
--    if  uireq.help then
--        FriendCopyAttack.help = uireq.help
--    end
--    --printT(uireq)
--
--    if gamedata.cache.friendcopy[uireq.map].kill > 0 and gamedata.cache.friendcopy[uireq.map].point <= 0 then
--        if gamedata.cache.vipstatus.b_expedition >= gamedata.config.vip[tostring(gamedata.cache.vip.vip)].b_expedition then
--            return 0,503,{type = 503, msgtype = "shortvip"}
--        elseif gamedata.cache.role.gold<50 then
--            return 0,503,{type = 503, msgtype = "shortgold"}
--        end
--    end
--
--    for i=1,7 do
--        local tool = expeditionattack_pb.ExpeditionAttack.Tool()
--        tool.revive = uireq.slot[tostring(i)].revive
--        tool.recove = uireq.slot[tostring(i)].recove
--        tool.strengthen = uireq.slot[tostring(i)].strengthen
--        table.insert(FriendCopyAttack.slot,tool)
--    end
--
--    gamedata.ext.friendcopyattack = {map = uireq.map, help = uireq.help, slot = uireq.slot }
--
--
--    return 1, 1321, FriendCopyAttack:SerializeToString()
--end
--
--local battleresult_pb = require("battleresult_pb")
--function NetFriendCopyAttackCallback(fd)
--    cclog("NET type:%d cmd:%s recv response from gameserver", 1321, "copyattack")
--    local copyAttackResultPb = battleresult_pb.BattleResult()
--    copyAttackResultPb:ParseFromString(fd.rbuf)
--
--    local t = {
--        type = 1321,
--        result = copyAttackResultPb.result,
--        reward = gamedata:SomethingProcess(copyAttackResultPb.reward),
--        ---battlereport = copyAttackResultPb.battlereport,
--        battlereport = PickBattleResultReport(copyAttackResultPb)
--    }
--    t.fightbg = gamedata.config.expedition_map[tostring(gamedata.ext.friendcopyattack.map)].basemap
--
--    local slot = gamedata.ext.friendcopyattack.slot
--    local map = gamedata.ext.friendcopyattack.map
--
--    local friendcopy_propcid_1 = gamedata.config.global_kv.friendcopy_tool_1_propcid and tonumber(gamedata.config.global_kv.friendcopy_tool_1_propcid.value) or 20048
--    local friendcopy_propcid_2 = gamedata.config.global_kv.friendcopy_tool_2_propcid and tonumber(gamedata.config.global_kv.friendcopy_tool_2_propcid.value) or 20049
--    local friendcopy_propcid_3 = gamedata.config.global_kv.friendcopy_tool_3_propcid and tonumber(gamedata.config.global_kv.friendcopy_tool_3_propcid.value) or 20050
--    for i=1,7 do
--        gamedata:updateprops({cid = friendcopy_propcid_1, num = 0-slot[tostring(i)].revive})
--        gamedata:updateprops({cid = friendcopy_propcid_2, num = 0-slot[tostring(i)].recove})
--        gamedata:updateprops({cid = friendcopy_propcid_3, num = 0-slot[tostring(i)].strengthen})
--    end
--
--    if gamedata.cache.friendcopy[map].kill > 0 and gamedata.cache.friendcopy[uireq.map].point <= 0 then
--        gamedata:updateRoleGold(-50,"好友副本攻打",1)
--    end
--
--    print("copyAttackResultPb.result",copyAttackResultPb.result)
--
--    if copyAttackResultPb.result ==1  then
--        if  gamedata.cache.friendcopy[map].point+1 >= table.getTableLength(gamedata.config.expedition[tostring(map)]) then
--            gamedata.cache.friendcopy[map].hps = {}
--            gamedata.cache.friendcopy[map].kill = 1
--            if gamedata.cache.friendcopy[map].friend then
--                gamedata.cache.friendcopy[map].friend = nil
--                gamedata.cache.friendcopy[map].friendgeneral = nil
--            end
--            if not gamedata.cache.friendcopy[map+1] then
--                gamedata.cache.friendcopy[map+1] = {map = map+1,kill=0,point=0,hps={},friend = 0}
--            end
--        else
--            gamedata.cache.friendcopy[map].point = gamedata.cache.friendcopy[gamedata.ext.friendcopyattack.map].point +1
--            ---gamedata.cache.friendcopy[map].hps,gamedata.cache.friendcopy[map].generals = makeHps(LoadJsonStringToTable(copyAttackResultPb.battlereport))
--            gamedata.cache.friendcopy[map].hps,gamedata.cache.friendcopy[map].generals = makeHps(LoadJsonStringToTable(PickBattleResultReport(copyAttackResultPb)))
--        end
--        if gamedata.ext.friendcopyattack.help then
--            for k,v in pairs(gamedata.cache.friends.friends) do
--                if v.first.iid == gamedata.ext.friendcopyattack.help or v.second.iid == gamedata.ext.friendcopyattack.help then
--                    gamedata.cache.friendcopy[map].friend = v.rid
--                    gamedata.cache.friendcopy[map].friendgeneral = (v.first.iid == gamedata.ext.friendcopyattack.help and v.first or v.second)
--                    v.use = 1
--                end
--            end
--        end
--    elseif copyAttackResultPb.result == 0 then
--        printT(gamedata.cache.friendcopy[map])
--
--        gamedata.cache.friendcopy[map].point = 0
--        gamedata.cache.friendcopy[map].kill = -1
--        gamedata.cache.friendcopy[map].hps = {}
--        if gamedata.cache.friendcopy[map].friend then
--            gamedata.cache.friendcopy[map].friend = nil
--            gamedata.cache.friendcopy[map].friendgeneral = nil
--        end
--        if gamedata.ext.friendcopyattack.help then
--            for k,v in pairs(gamedata.cache.friends.friends) do
--                if v.first.iid == gamedata.ext.friendcopyattack.help or v.second.iid == gamedata.ext.friendcopyattack.help then
--                    v.use = 1
--                end
--            end
--        end
--    end
--
--    return t
--end
--
----
--local combmessages_pb = require("combmessages_pb")
--local ids_pb = require("ids_pb")
--local players_pb = require("players_pb")
--
--function UIFriendCopyRankCallback(uireq)
--    cclog("NET type:%d cmd:%s recv request from UI", 1322, "FriendCopyRank")
--       if next(gamedata.cache.friendcopyrank) then
--            return 0, 1322, { type = uireq.type, friendcopyrank = gamedata.cache.friendcopyrank,}
--        else
--            return 1, 1322, nil
--       end
--end
--
--
--function NetFriendCopyRankCallback(fd)
--    cclog("NET type:%d cmd:%s recv response from gameserver", 1322, "FriendCopyRank")
--
--    local FriendCopyRankData = combmessages_pb.CombMessages()
--    FriendCopyRankData:ParseFromString(fd.rbuf)
--    for k,v in ipairs(FriendCopyRankData.messages) do
--        if v.id == 0 then
--            local ids = ids_pb.Ids()
--            ids:ParseFromString(v.data)
--            gamedata.cache.friendcopyrank.mynum = ids.ids[1] or 0
--        else
--            local playersData = players_pb.Players()
--            playersData:ParseFromString(v.data)
--            gamedata.cache.friendcopyrank.players = gamedata:players(playersData.players) or {}
--        end
--    end
--
--    return { type = 1322, friendcopyrank = gamedata.cache.friendcopyrank,}
--end