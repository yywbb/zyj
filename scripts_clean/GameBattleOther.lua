--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/26
-- Time: 上午11:17
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
function UIBattleOtherCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1022, "BattleOther")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.rid)

    --if gamedata.cache.role.energy <= 0 then
    --    return  0, 503, {type = 503, msgtype = "shortenergy", param = gamedata.cache.props }
    --else
        return 1, 1022, idsData:SerializeToString()
    --end
end

local battleresult_pb = require("battleresult_pb")
require"PickBattleResultReport"
function NetBattleOtherCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1022, "BattleOther")
    local copyAttackResultPb = battleresult_pb.BattleResult()
    copyAttackResultPb:ParseFromString(fd.rbuf)

    --gamedata:updateRoleEnergy(-1)

    return {
        type = 1022,
        result = copyAttackResultPb.result,
        ---battlereport = copyAttackResultPb.battlereport,
        battlereport = PickBattleResultReport(copyAttackResultPb)
    }
end