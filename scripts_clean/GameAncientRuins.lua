--
-- Author: songyibo
-- Date: 2019-09-23 13:16:21
--

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local combmessages_pb = require("combmessages_pb")

function UIAncientRuinsQueryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 7080, "AncientRuinsQuery")
   	
    gamedata.ext.AncientRuinsQueryParam = uireq.param
   	if next(gamedata.cache.AncientRuinsData) then
        return 0, 7080, {type = 7080, AncientRuinsData = gamedata.cache.AncientRuinsData,param = gamedata.ext.AncientRuinsQueryParam}
    else
        return 1, 7080, nil
    end
end

function NetAncientRuinsQueryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7080, "AncientRuinsQuery")

    local AncientRuins = {map = {}}

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            
            AncientRuins.isopen = ids.ids[1]
            AncientRuins.yinghun = ids.ids[2]
            AncientRuins.challengeTime = ids.ids[3]
            AncientRuins.box1 = ids.ids[4]
            AncientRuins.box2 = ids.ids[5]
            AncientRuins.box3 = ids.ids[6]
            AncientRuins.box4 = ids.ids[7]
            AncientRuins.box5 = ids.ids[8]
            AncientRuins.box6 = ids.ids[9]

            AncientRuins.attackNum1 = ids.ids[10]
            AncientRuins.attackNum2 = ids.ids[11]
            AncientRuins.attackNum3 = ids.ids[12]
            AncientRuins.attackNum4 = ids.ids[13]
            AncientRuins.attackNum5 = ids.ids[14]

        else
        	local mapData = {}
        	local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            mapData.mapId = ids.ids[1]
            mapData.deadPos = {}
            for i=2,20 do
            	if ids.ids[i] then
                    mapData.deadPos[ids.ids[i]] = 1
            	else
            		break
            	end
            end

            AncientRuins.map[v.id] = mapData
        end
    end

    gamedata.cache.AncientRuinsData = AncientRuins

    return { type = 7080,AncientRuinsData = gamedata.cache.AncientRuinsData,param = gamedata.ext.AncientRuinsQueryParam}
end

function UIAncientRuinsAttackCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 7081, "AncientRuinsAttack")

    printT(uireq,"uireq")
    local ReqData = ids_pb.Ids()
    table.insert(ReqData.ids, uireq.mapId)
    table.insert(ReqData.ids, uireq.pos)

    gamedata.ext.AncientRuinsAttack = uireq

    return 1, 7081, ReqData:SerializeToString()
end

function NetAncientRuinsAttackCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7081, "AncientRuinsAttack")

    local copyAttackResultPb = battleresult_pb.BattleResult()
    copyAttackResultPb:ParseFromString(fd.rbuf)
    local battlereport = PickBattleResultReport(copyAttackResultPb)
    local result = copyAttackResultPb.result
    local battlereward = gamedata:SomethingProcess(copyAttackResultPb.reward)

    if result == 1 then
        if gamedata.cache.AncientRuinsData.map[gamedata.ext.AncientRuinsAttack.mapId] then
            gamedata.cache.AncientRuinsData.map[gamedata.ext.AncientRuinsAttack.mapId].deadPos[gamedata.ext.AncientRuinsAttack.pos] = 1
        end

        if gamedata.ext.AncientRuinsAttack.pos ~= 0 then
            --挑战次数
            gamedata.cache.AncientRuinsData.challengeTime = gamedata.cache.AncientRuinsData.challengeTime + 1
            --累计挑战次数
            gamedata.cache.AncientRuinsData["attackNum"..gamedata.ext.AncientRuinsAttack.mapId] = gamedata.cache.AncientRuinsData["attackNum"..gamedata.ext.AncientRuinsAttack.mapId] + 1
        end
    end

    --宝箱状态改变
    for k,v in pairs(gamedata.config.shanggu_reward) do
        if gamedata.cache.AncientRuinsData["box"..v.id] and gamedata.cache.AncientRuinsData["box"..v.id] == 0 and gamedata.cache.AncientRuinsData.yinghun >= v.need_num then
           gamedata.cache.AncientRuinsData["box"..v.id] = 1
        end
    end


    return { type = 7081,reward = battlereward,battlereport = battlereport,AncientRuinsData = gamedata.cache.AncientRuinsData,attackInfo = gamedata.ext.AncientRuinsAttack,result = result}
end


function UIAncientRuinsRewardCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 7082, "AncientRuinsReward")
    local ReqData = ids_pb.Ids()
    table.insert(ReqData.ids, uireq.id)

    gamedata.ext.AncientRuinsAwardId = uireq.id

    return 1, 7082, ReqData:SerializeToString()
end

function NetAncientRuinsRewardCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7082, "AncientRuinsReward")

    local reward = {}

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    reward = gamedata:SomethingProcess(SomeThings)

    gamedata.cache.AncientRuinsData["box"..gamedata.ext.AncientRuinsAwardId] = 2

    return { type = 7082,reward = reward,AncientRuinsData = gamedata.cache.AncientRuinsData}
end
