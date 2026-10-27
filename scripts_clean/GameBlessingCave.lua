--
-- Author: songyibo
-- Date: 2019-03-21 11:15:41
--

local ids_pb = require("ids_pb")
local combmessages_pb = require("combmessages_pb")
local battleresult_pb = require("battleresult_pb")
local somethings_pb = require("somethings_pb")


function UIBlessingCaveStatusCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 6520, "BlessingCaveyQuery")

    return 1, 6520, nil
end


function NetBlessingCaveStatusCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6520, "BlessingCaveQuery")

     local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    local battleTimes = Result.ids[1] or 0
    -- local copyInfo = Result.ids[2] or {}
    local status = {}
    for k,v in ipairs(Result.ids) do
        print(k,v)
        table.insert(status,v)
    end

    return { type = 6520, times = battleTimes, copyInfo = status , rolelv = gamedata.cache.role.level or 0 }
end



function UIBlessingCaveAttackCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 6521, "BlessingCaveyAttack")

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id)
    table.insert(idsData.ids, uireq.difficulty or 1)

    return 1, 6521, idsData:SerializeToString()
end


function NetBlessingCaveAttackCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6521, "BlessingCaveAttack")

    local t = {
        type = 6521,
    }

    local BattleResultPb = battleresult_pb.BattleResult()
    BattleResultPb:ParseFromString(fd.rbuf)

    print(BattleResultPb)  


    t.battlereport = PickBattleResultReport(BattleResultPb)
    t.result = BattleResultPb.result
    t.reward = gamedata:SomethingProcess(BattleResultPb.reward)

    return t
end



function UIBlessingCaveSweepCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 6522, "BlessingCaveySweep")

 local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id)
    table.insert(idsData.ids, uireq.difficulty or 1)

    return 1, 6522, idsData:SerializeToString()
end


function NetBlessingCaveSweepCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6522, "BlessingCaveSweep")

  
  
    local t = {
        type = 6522,
    }

    local  getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    t.reward = gamedata:SomethingProcess(getData)


    return t
end

