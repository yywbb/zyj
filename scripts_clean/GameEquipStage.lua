--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-10-16
-- Time: 下午1:57
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local slots_pb = require("slots_pb")
local somethings_pb = require("somethings_pb")



-- 装备进阶
function UIEquipStageUpCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1122, "EquipStageUp")
    print("i...am...UIEquipStageUpCallBack")
    printT(uireq)
    gamedata.ext.equipStageUp = uireq
    gamedata.ext.equipQuality = gamedata.cache.equips[tonumber(uireq.iid)].quality
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.iid)

    return 1, 1122, idsData:SerializeToString()
end

function NetEquipStageUpCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1122, "EquipStageUp")
    print("i...am...NetEquipStageUpCallBack")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    gamedata:SomethingProcess(SomeThings)

    local equipdata = gamedata.cache.equips[tonumber(gamedata.ext.equipStageUp.iid)]
    local qualityUp = 0
    print("equipdata = ",equipdata.quality)
    print("equipQuality = ",gamedata.ext.equipQuality)
    if equipdata.quality > gamedata.ext.equipQuality then
        qualityUp = 1
    end
    print("qualityUp = ",qualityUp)

    -- printT(gamedata.cache.equips)
    -- local info = slots_pb.SlotS()
    -- info:ParseFromString(fd.rbuf)

    -- gamedata:SlotInfoProcess(info)
    return {
        type = 1122,
        props = gamedata.ext.equipStageUp.props,
        equipdata = equipdata,
        qualityUp = qualityUp,
    }
end