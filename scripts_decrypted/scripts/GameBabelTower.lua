--
-- Author: songyibo
-- Date: 2019-03-21 11:15:41
--

local ids_pb = require("ids_pb")
local combmessages_pb = require("combmessages_pb")
local battleresult_pb = require("battleresult_pb")
local somethings_pb = require("somethings_pb")


function UIXianBuyTimesCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 7010, "BabelTowerBuyQuery")
    printT(uireq,"uireq")

    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.sysId)
    table.insert(ids.ids, uireq.times)

    gamedata.ext.XianBuyInfo = uireq
    return 1, 7010, ids:SerializeToString()
end

function NetXianBuyTimesCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7010, "BabelTowerQuery")
    
    local t = {
        type = 7010,
        sysId = gamedata.ext.XianBuyInfo.sysId,
        buyTime = gamedata.ext.XianBuyInfo.times,
    }

    if gamedata.ext.XianBuyInfo.sysId == 450 then
        gamedata.cache.BabelTower.mapData.buyTime = gamedata.cache.BabelTower.mapData.buyTime + gamedata.ext.XianBuyInfo.times
        t.BabelTowerMapData = gamedata.cache.BabelTower.mapData
    end

    gamedata:updateRoleG_gold(-gamedata.ext.XianBuyInfo.spend)

    return t
end


function UIBabelTowerQueryCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 7011, "BabelTowerQuery")
    printT(uireq,"uireq")

    if not next(gamedata.cache.BabelTower.mapData) then
    	gamedata.cache.BabelTower.mapData = {}
    	return 1, 7011, nil
    else
    	return 0,7011,{ type = 7011,data = gamedata.cache.BabelTower.mapData}
    end
end

function NetBabelTowerQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7011, "BabelTowerQuery")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata.cache.BabelTower.mapData = {}
    gamedata.cache.BabelTower.mapData.maxPoint = ids.ids[1]
    gamedata.cache.BabelTower.mapData.curPoint = ids.ids[2]
    gamedata.cache.BabelTower.mapData.challengeTime = ids.ids[3]
    gamedata.cache.BabelTower.mapData.buyTime = ids.ids[4]

    gamedata.cache.BabelTower.mapData.awardStatus1 = ids.ids[5]
    gamedata.cache.BabelTower.mapData.awardStatus2 = ids.ids[6]
    gamedata.cache.BabelTower.mapData.awardStatus3 = ids.ids[7]
    gamedata.cache.BabelTower.mapData.awardStatus4 = ids.ids[8]
    gamedata.cache.BabelTower.mapData.awardStatus5 = ids.ids[9]
    gamedata.cache.BabelTower.mapData.awardStatus6 = ids.ids[10]

    return { type = 7011,data = gamedata.cache.BabelTower.mapData}
end

function UIBabelTowerLevelQueryCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 7012, "BabelTowerQuery")
    printT(uireq,"uireq")
    if next(gamedata.cache.BabelTower.levelData) then
        return 0,7012,{ type = 7012,mapId = uireq.mapId,mapData = gamedata.cache.BabelTower.mapData, data = gamedata.cache.BabelTower.levelData}
    else
        local ids = ids_pb.Ids()
        table.insert(ids.ids, uireq.mapId)

        gamedata.ext.mapQueryId = uireq.mapId
        return 1, 7012, ids:SerializeToString()
    end
end

function NetBabelTowerLevelQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7012, "BabelTowerQuery")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata.cache.BabelTower.mapData.curPoint = gamedata.ext.mapQueryId or 1
    gamedata.cache.BabelTower.levelData = {}
    local index = 0
    while ids.ids[index*7 + 1] do
        local _t = {
            challengeTime    = ids.ids[index*7 + 1],
            passStatus1      = ids.ids[index*7 + 2],
            passStatus2      = ids.ids[index*7 + 3],
            passStatus3      = ids.ids[index*7 + 4],
            dailyKillStatus  = ids.ids[index*7 + 5],
            firstKillStatus  = ids.ids[index*7 + 6],
            autoBattleStatus = ids.ids[index*7 + 7],
            level = index  + 1,
            mapId = gamedata.ext.mapQueryId
        }
        index = index + 1
        gamedata.cache.BabelTower.levelData[index] = _t
    end

    return { type = 7012,mapId = gamedata.ext.mapQueryId,mapData = gamedata.cache.BabelTower.mapData,data = gamedata.cache.BabelTower.levelData}
end


function UIBabelTowerBattleCallback(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 7013, "BabelTowerQuery")
    printT(uireq,"uireq")

    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.levelId)
    gamedata.ext.BabelTowerBattleLevel = uireq.levelId
    return 1, 7013, ids:SerializeToString()
end

function NetBabelTowerBattleCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7013, "BabelTowerQuery")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local t = {
        type = 7013,
    }
    
    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            local _t = {
                challengeTime    = ids.ids[1],
                passStatus1      = ids.ids[2],
                passStatus2      = ids.ids[3],
                passStatus3      = ids.ids[4],
                dailyKillStatus  = ids.ids[5],
                firstKillStatus  = ids.ids[6],
                autoBattleStatus = ids.ids[7],
                level = gamedata.ext.BabelTowerBattleLevel,
                mapId = gamedata.cache.BabelTower.mapData.curPoint
            }
            --第一层最后一关打完播剧情首次通关时候拨一次 firstKillStatus判断从0到1
            if _t.mapId == 1 and _t.level == 20 then
                if _t.firstKillStatus == 1 then
                    if (not gamedata.cache.BabelTower.levelData[gamedata.ext.BabelTowerBattleLevel]) or (gamedata.cache.BabelTower.levelData[gamedata.ext.BabelTowerBattleLevel].firstKillStatus == 0)  then
                        t.palybackstory = true
                    end
                end
            end

            --是否是首通奖励
            if _t.firstKillStatus == 1 then
                if (not gamedata.cache.BabelTower.levelData[gamedata.ext.BabelTowerBattleLevel]) or (gamedata.cache.BabelTower.levelData[gamedata.ext.BabelTowerBattleLevel].firstKillStatus == 0)  then
                    t.firstKill = true
                end
            end

            if not gamedata.cache.BabelTower.levelData[gamedata.ext.BabelTowerBattleLevel] then
                gamedata.cache.BabelTower.levelData[gamedata.ext.BabelTowerBattleLevel] = _t
            else
                --战斗结果 如果星数不变 不更新关卡通关数据passStatus
                local old_stars = 0
                local new_stars = 0
                for i=1,3 do
                    if gamedata.cache.BabelTower.levelData[gamedata.ext.BabelTowerBattleLevel]["passStatus"..i] and gamedata.cache.BabelTower.levelData[gamedata.ext.BabelTowerBattleLevel]["passStatus"..i] == 1 then
                        old_stars = old_stars + 1
                    end

                    if _t["passStatus"..i] and _t["passStatus"..i] == 1 then
                        new_stars = new_stars + 1
                    end
                end

                if new_stars > old_stars then
                    gamedata.cache.BabelTower.levelData[gamedata.ext.BabelTowerBattleLevel] = _t
                else
                    gamedata.cache.BabelTower.levelData[gamedata.ext.BabelTowerBattleLevel].challengeTime    = _t.challengeTime
                    gamedata.cache.BabelTower.levelData[gamedata.ext.BabelTowerBattleLevel].dailyKillStatus  = _t.dailyKillStatus
                    gamedata.cache.BabelTower.levelData[gamedata.ext.BabelTowerBattleLevel].firstKillStatus  = _t.firstKillStatus
                end
            end
            
            t.levelData = _t
            t.totalLevelData = gamedata.cache.BabelTower.levelData

            --判断是否3星全通 重置领奖状态
            
            local awardStatus = gamedata.cache.BabelTower.mapData["awardStatus"..gamedata.cache.BabelTower.mapData.curPoint]
            
            --原来不是三星全通可领奖
            if awardStatus == 0  then
                local isSanXingPass = true
                for i=1,table.getTableLength(gamedata.config.tongtianta_guaiwu[tostring(gamedata.cache.BabelTower.mapData.curPoint)]) do
                    local levelData = gamedata.cache.BabelTower.levelData[i]
                    if levelData then
                        if levelData.passStatus1 ~= 1 or levelData.passStatus2 ~= 1 or levelData.passStatus3 ~= 1 then
                            isSanXingPass = false
                            break
                        end
                    else
                        isSanXingPass = false
                        break
                    end
                end
                --置为可领奖状态
                if isSanXingPass then
                    gamedata.cache.BabelTower.mapData["awardStatus"..gamedata.cache.BabelTower.mapData.curPoint] = 1
                end
            end
            t.mapData = gamedata.cache.BabelTower.mapData
        elseif v.id == 1 then
            local BattleResultPb = battleresult_pb.BattleResult()
            BattleResultPb:ParseFromString(v.data)
            t.battlereport = PickBattleResultReport(BattleResultPb)
            t.result = BattleResultPb.result
            t.reward = gamedata:SomethingProcess(BattleResultPb.reward)
        end
    end

    return t
end


function UIBabelTowerQuitCallback(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 7014, "BabelTowerQuery")
    return 1, 7014, nil
end

function NetBabelTowerQuitCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7014, "BabelTowerQuery")
    
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata.cache.BabelTower.mapData = {}
    gamedata.cache.BabelTower.mapData.maxPoint = ids.ids[1]
    gamedata.cache.BabelTower.mapData.curPoint = ids.ids[2]
    gamedata.cache.BabelTower.mapData.challengeTime = ids.ids[3]
    gamedata.cache.BabelTower.mapData.buyTime = ids.ids[4]

    gamedata.cache.BabelTower.mapData.awardStatus1 = ids.ids[5]
    gamedata.cache.BabelTower.mapData.awardStatus2 = ids.ids[6]
    gamedata.cache.BabelTower.mapData.awardStatus3 = ids.ids[7]
    gamedata.cache.BabelTower.mapData.awardStatus4 = ids.ids[8]
    gamedata.cache.BabelTower.mapData.awardStatus5 = ids.ids[9]
    gamedata.cache.BabelTower.mapData.awardStatus6 = ids.ids[10]

    gamedata.cache.BabelTower.levelData = {}

    return { type = 7014,data = gamedata.cache.BabelTower.mapData}
end

function UIBabelTowerAwardCallback(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 7015, "BabelTowerQuery")
    printT(uireq,"uireq")

    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.mapId)
    gamedata.ext.BabelTowerAwardMapId = uireq.mapId
    return 1, 7015, ids:SerializeToString()

end

function NetBabelTowerAwardCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7015, "BabelTowerQuery")
    local  getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)
    gamedata.cache.BabelTower.mapData["awardStatus"..gamedata.ext.BabelTowerAwardMapId] = 2
    return {type = 7015,reward = gamedata:SomethingProcess(getData),mapData =gamedata.cache.BabelTower.mapData}
end

function UIBabelTowerAutoBattleCallback(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 7016, "BabelTowerAutoBattle")
    printT(uireq,"uireq")

    return 1, 7016, nil

end

function NetBabelTowerAutoBattleCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7016, "BabelTowerAutoBattle")
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)


    local maxChallengeLevel = 1
    for i,v in ipairs(gamedata.cache.BabelTower.levelData) do
        if v.dailyKillStatus == 1 then
            maxChallengeLevel = i
        else
            maxChallengeLevel = i
            break
        end
    end

    local index = maxChallengeLevel
    local rewards = {}
    for k,v in ipairs(datas.messages) do
        local  getData = somethings_pb.SomeThings()
        getData:ParseFromString(v.data)
        if index >= maxChallengeLevel then
            local reward = gamedata:SomethingProcess(getData)
            table.insert(rewards,{mapId = gamedata.cache.BabelTower.mapData.curPoint,level = index,reward = reward})
            index = index + 1
        end
    end
    --扫荡过后能扫荡的关每日挑战给置为1
    for i,v in ipairs(gamedata.cache.BabelTower.levelData) do
        if i >= maxChallengeLevel then
            if v.passStatus1 == 1 and v.passStatus2 == 1 and v.passStatus3 == 1 then
                v.dailyKillStatus = 1
            else
                break
            end
        end
    end

    --扫荡只判断第一关状态
    gamedata.cache.BabelTower.levelData[1].autoBattleStatus = 1

    return {type = 7016,rewards = rewards,totalLevelData = gamedata.cache.BabelTower.levelData}
end

function UIBabelTowerShopQueryCallback(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 7017, "BabelTowerShopQuery")

    -- if next(gamedata.cache.BabelTowerShop) then
    --     return 0,7017,{ type = 7017,data = gamedata.cache.BabelTowerShop,maxMap = gamedata.cache.BabelTowerMaxMap,gold = math.max(gamedata.cache.props[20809] and gamedata.cache.props[20809].num or 0,0),g_gold = gamedata.cache.role.g_gold}
    -- end
    return 1, 7017, nil
end

function NetBabelTowerShopQueryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7017, "BabelTowerShopQuery")
    
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata.cache.BabelTowerShop = {}
    gamedata.cache.BabelTowerMaxMap = ids.ids[1]


    for i,v in ipairs(ids.ids) do
        if i > 1 then
            table.insert(gamedata.cache.BabelTowerShop,v)
        end
    end
    return {type = 7017,data = gamedata.cache.BabelTowerShop,maxMap = gamedata.cache.BabelTowerMaxMap,gold = math.max(gamedata.cache.props[20809] and gamedata.cache.props[20809].num or 0,0),g_gold = gamedata.cache.role.g_gold}
end

function UIBabelTowerShopBuyCallback(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 7018, "BabelTowerShopBuy")
    printT(uireq,"uireq")

    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.id)
    table.insert(ids.ids, uireq.num)

    gamedata.ext.BabelTowerShopBuyInfo = uireq
    return 1, 7018, ids:SerializeToString()

end

function NetBabelTowerShopBuyCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7018, "BabelTowerShopBuy")
    local  getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    gamedata.cache.BabelTowerShop[gamedata.ext.BabelTowerShopBuyInfo.id] = gamedata.cache.BabelTowerShop[gamedata.ext.BabelTowerShopBuyInfo.id] + gamedata.ext.BabelTowerShopBuyInfo.num

    local consume = gamedata.config.tongtianta_shangdian[tostring(gamedata.ext.BabelTowerShopBuyInfo.id)].num
    local props = gamedata.getIDandNUMs(consume)

    local cid = props[1].cid
    local num = props[1].num * gamedata.ext.BabelTowerShopBuyInfo.num
    gamedata:updateStaff({cid = cid,num = -num})

    return {type = 7018,reward = gamedata:SomethingProcess(getData),data = gamedata.cache.BabelTowerShop,gold = math.max(gamedata.cache.props[20809] and gamedata.cache.props[20809].num or 0,0),g_gold = gamedata.cache.role.g_gold}
end

function UIBabelTowerRankQueryCallback(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 7019, "TowerRankQuery")
    printT(uireq,"uireq")

    local ids = ids_pb.Ids()
    table.insert(ids.ids, uireq.id)
    gamedata.ext.BabelTowerRankId = uireq.id

    return 1, 7019, ids:SerializeToString()

end

function NetBabelTowerRankQueryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7019, "TowerRankQuery")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local t = {
        type = 7013,
    }
    
    local myRankData = {}
    local players = {}

    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            myRankData.point = ids.ids[1]
            myRankData.level = ids.ids[2]
        elseif v.id == 1 then
            local playersData = players_pb.Players()
            playersData:ParseFromString(v.data)
            players = gamedata:players(playersData.players)
        end
    end


    return {type = 7019,data = players,myRankData = myRankData,id = gamedata.ext.BabelTowerRankId}
end
  �@  