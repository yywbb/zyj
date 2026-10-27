--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 16/2/3
-- Time: 下午12:04
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local battleresult_pb = require("battleresult_pb")
require"PickBattleResultReport"
function UISingleBossQuaryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3700, "BossQuary")
    if uireq.param and uireq.param == "noupdate" and next(gamedata.cache.singleBoss) then
        return 0, 3700, {
            type = 3700,
            boss = gamedata.cache.singleBoss,
            isNextLevelOpen = 0,
        }
    else
        return 1, 3700, nil
    end

end

function NetSingleBossQuaryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3700, "BossQuary")
    local idsData = ids_pb.Ids()
    idsData:ParseFromString(fd.rbuf)

    gamedata:SingleBoss(idsData)

    return {
        type = 3700,
        boss = gamedata.cache.singleBoss,
        isNextLevelOpen = 0,
        rolelv = gamedata.cache.role.level,
        viplv = gamedata.cache.role.vip,
    }
end

function UISingleBossBattleCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3701, "BossBattle")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id)

    gamedata.ext.singleBossID = uireq.id or 0

    return 1, 3701, idsData:SerializeToString()
end


function NetSingleBossBattleCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3701, "BossBattle")
    local copyAttackResultPb = battleresult_pb.BattleResult()
    copyAttackResultPb:ParseFromString(fd.rbuf)
    local isNextLevelOpen = 0
    if copyAttackResultPb.result and copyAttackResultPb.result == 1 then
        gamedata.cache.singleBoss.battlenum = gamedata.cache.singleBoss.battlenum +1
        if gamedata.ext.singleBossID > gamedata.cache.singleBoss.openlevel then
            gamedata.cache.singleBoss.openlevel = gamedata.ext.singleBossID
            isNextLevelOpen = 1
        end
    end

    return {
        type = 3701,
        result = copyAttackResultPb.result,
        reward = gamedata:SomethingProcess(copyAttackResultPb.reward),
        battlereport = PickBattleResultReport(copyAttackResultPb),
        boss = gamedata.cache.singleBoss,
        isNextLevelOpen = isNextLevelOpen,
    }
end


function UIKingManOnekeyChallengeCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3705, "UIKingManOnekeyChallengeCallback")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.bossid) 
    table.insert(idsData.ids, uireq.times) 
    print("uireq.bossid:"..uireq.bossid.." uireq.times:"..uireq.times)

    return 1, 3705, idsData:SerializeToString()

end

function NetKingManOnekeyChallengeCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3705, "NetKingManOnekeyChallengeCallback")
    
   local t = {
        type = 3705,
    }

    local  getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    t.reward = gamedata:SomethingProcess(getData)

    return t

end


