--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-10-11
-- Time: 上午11:14
-- To change this template use File | Settings | File Templates.
--

local TreasureRefine_pb = require("treasurerefine_pb")
function UITreasureRefineCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1106, "TreasureRefine")
    local TreasurerefineData = TreasureRefine_pb.TreasureRefine()

    TreasurerefineData.iid = uireq.iid

    for k,v in pairs(uireq.ids) do
        table.insert(TreasurerefineData.ids,v)
    end

    gamedata.ext.TreasureRefineiid =  uireq.iid
    gamedata.ext.TreasureRefineids =  uireq.ids

    return 1, 1106, TreasurerefineData:SerializeToString()
end

local t_somethings_pb = require("somethings_pb")
function NetTreasureRefineCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1106, "TreasureRefine")

    local TreasureUpData = t_somethings_pb.SomeThings()
    TreasureUpData:ParseFromString(fd.rbuf)

    gamedata:SomethingProcess(TreasureUpData)

    for k,v in pairs(gamedata.ext.TreasureRefineids) do
        gamedata.cache.equips[v] = nil
    end

    local equip = makeEquipsTemp()
    return { type = 1106, equips = makeTreasure(),equip = equip[gamedata.ext.TreasureRefineiid],}
end