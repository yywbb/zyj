--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/20
-- Time: 上午11:08
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local result_pb = require("result_pb")
local gangs_pb = require("gangs_pb")
local devilfotressbattlenotify_pb = require("devilfotressbattlenotify_pb")
local devilfotressgangdefense_pb = require("devilfotressgangdefense_pb")
local devilfotressstatus_pb = require("devilfotressstatus_pb")
local devilfotresstarget_pb = require("devilfotresstarget_pb")
local battleresult_pb = require("battleresult_pb")

function UIDevilFotressStatusCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2610, "DevilFotressStatus")

    if not gamedata.cache.gangstatus.id then
        return 0, 503, {type = 503, msg = "未加入任何公会"}
    else
        return 1, 2610, nil
    end
end

function NetDevilFotressStatusCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2610, "DevilFotressStatus")
    local DevilFotressStatusData = devilfotressstatus_pb.DevilFotressStatus()
    DevilFotressStatusData:ParseFromString(fd.rbuf)

    gamedata:DevilFotressStatus(DevilFotressStatusData)

    return { type = 2610, devilfotressftatus = gamedata.cache.devilfotressftatus,}
end

-------------------------------------------------------------------------------------------------

function UIDevilFotressGangDefCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2611, "DevilFotressGangDef")

    local DevilFotressGangDefData = ids_pb.Ids()
    table.insert(DevilFotressGangDefData.ids, uireq.id)

    return 1, 2611, DevilFotressGangDefData:SerializeToString()
end

function NetDevilFotressGangDefCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2611, "DevilFotressGangDef")

    local DevilFotressGangDefData = devilfotressgangdefense_pb.DevilFotressGangDefense()
    DevilFotressGangDefData:ParseFromString(fd.rbuf)

    local data = gamedata:DevilFotressGangDef(DevilFotressGangDefData)

    return { type = 2611, data = data,}
end

-------------------------------------------------------------------------------------------------

function UIDevilFotressGangDefSetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2612, "DevilFotressGangDefSet")

    local DevilFotressGangDefSetData = ids_pb.Ids()

    --printT(uireq.ids)
    for i = 1, uireq.ids["2"] do
        if i== uireq.ids["2"] then
            print(uireq.ids["1"])
            table.insert(DevilFotressGangDefSetData.ids, uireq.ids["1"])
        else
            table.insert(DevilFotressGangDefSetData.ids, 0)
        end
    end

    return 1, 2612, DevilFotressGangDefSetData:SerializeToString()
end

function NetDevilFotressGangDefSetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2612, "DevilFotressGangDefSet")

    local resultData = result_pb.Result()
    resultData:ParseFromString(fd.rbuf)

    return { type = 2612, result = resultData.result,}
end

-------------------------------------------------------------------------------------------------

function UIDevilFotressGangDefsCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2613, "DevilFotressGangDefs")

    gamedata.ext.fortgangselectpos = uireq.pos
    gamedata.ext.fortgangselectself = uireq.self

    return 1, 2613, nil
end

function NetDevilFotressGangDefsCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2613, "DevilFotressGangDefs")

    local GangsData = gangs_pb.Gangs()
    GangsData:ParseFromString(fd.rbuf)

    local gangs = {}
    for k,v in ipairs(GangsData.gangs) do
        if v.id ~= gamedata.ext.fortgangselectself then
            table.insert(gangs,gamedata:gangData(v))
        end
        for i=1, 3 do
            if gamedata.cache.devilfotressftatus["gang"..i].id and v.id == gamedata.cache.devilfotressftatus["gang"..i].id then
                gangs[#gangs].hasselect = true
            end
        end
    end

    gamedata.sortData(gangs, "level", "power")

    --可宣战公会

    return { type = 2613, gangs = gangs, pos = gamedata.ext.fortgangselectpos}
end

-------------------------------------------------------------------------------------------------

function UIDevilFotressGangProciamCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2614, "DevilFotressGangProciam")

    local DevilFotressGangProciamData = ids_pb.Ids()
    for i=1,3 do
        if  uireq.ids[tostring(i)] then
            table.insert(DevilFotressGangProciamData.ids, uireq.ids[tostring(i)])
        else
            table.insert(DevilFotressGangProciamData.ids, 0)
        end
    end

    return 1, 2614, DevilFotressGangProciamData:SerializeToString()
end

function NetDevilFotressGangProciamCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2614, "DevilFotressGangProciam")

    local resultData = result_pb.Result()
    resultData:ParseFromString(fd.rbuf)

    return { type = 2614, result = resultData.result,}
end

-------------------------------------------------------------------------------------------------

function UIDevilFtoressTargetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2616, "DevilFtoressTarget")

    return 1, 2616, nil
end

function NetDevilFtoressTargetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2616, "DevilFtoressTarget")

    local DevilFtoressTargetData = devilfotresstarget_pb.DevilFotressTarget()
    DevilFtoressTargetData:ParseFromString(fd.rbuf)

    local data = gamedata:DevilFtoressTarget(DevilFtoressTargetData)

    return { type = 2616, data = data,}
end

-------------------------------------------------------------------------------------------------

function UIDevilFotressAutoBattleCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2617, "DevilFotressAutoBattle")
    gamedata.ext.fortbattlegold = 0
    if uireq.gold then
        gamedata.ext.fortbattlegold = uireq.gold
    end

    return 1, 2617, nil
end

function NetDevilFotressAutoBattleCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2617, "DevilFotressAutoBattle")

    local BattleResultData = battleresult_pb.BattleResult()
    BattleResultData:ParseFromString(fd.rbuf)

    gamedata:updateRoleGold(0-gamedata.ext.fortbattlegold,"魔王堡垒自动战斗",1)

    return {
        type = 2617,
        result = BattleResultData.result,
        reward = gamedata:SomethingProcess(BattleResultData.reward),
        battlereport = BattleResultData.battlereport
    }
end

-------------------------------------------------------------------------------------------------

function UIDevilFotressTargetBattleCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2618, "DevilFotressTargetBattle")

    gamedata.ext.fortbattlegold = 0
    if uireq.gold then
        gamedata.ext.fortbattlegold = uireq.gold
    end


    local DevilFotressTargetBattleData = ids_pb.Ids()
    table.insert(DevilFotressTargetBattleData.ids, uireq.id)

    return 1, 2618, DevilFotressTargetBattleData:SerializeToString()
end

function NetDevilFotressTargetBattleCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2618, "DevilFotressTargetBattle")

    local BattleResultData = battleresult_pb.BattleResult()
    BattleResultData:ParseFromString(fd.rbuf)

    gamedata:updateRoleGold(0-gamedata.ext.fortbattlegold,"魔王堡垒选择战斗",1)

    return {
        type = 2618,
        result = BattleResultData.result,
        reward = gamedata:SomethingProcess(BattleResultData.reward),
        battlereport = BattleResultData.battlereport
    }
end

-------------------------------------------------------------------------------------------------

function NetDevilFotressBattleNotifyCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2600, "DevilFotressBattleNotify")

    local BattleResultData = devilfotressbattlenotify_pb.DevilFotressBattleNotify()
    BattleResultData:ParseFromString(fd.rbuf)

    return {
        type = 2600,
        gang = BattleResultData.gang,
        rid = BattleResultData.rid,
        pos = BattleResultData.pos,
        star = BattleResultData.star,
        hp = BattleResultData.hp,
        kill = BattleResultData.kill or 0,
        count = BattleResultData.count,
        --battlereport = BattleResultData.battlereport
    }
end  !  