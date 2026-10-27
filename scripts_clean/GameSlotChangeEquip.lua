--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-10-11
-- Time: 下午3:26
-- To change this template use File | Settings | File Templates.
--

local slotchangeequip_pb = require("slotchangeequip_pb")
function UISlotChangeEquipCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1005, "SlotChangeEquip")
    local slotchangeequipData = slotchangeequip_pb.SlotChangeEquip()
    slotchangeequipData.slot = uireq.slot
    slotchangeequipData.equipeid = uireq.equipeid
    gamedata.ext.equipchangeslot = uireq.slot
    gamedata.ext.equipchangeIID = uireq.equipeid

    return 1, 1005, slotchangeequipData:SerializeToString()
end

local slots_pb = require("slots_pb")
function NetSlotChangeEquipCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1005, "SlotChangeEquip")
    local info = slots_pb.SlotS()
    info:ParseFromString(fd.rbuf)

    gamedata:SlotInfoProcess(info)

    return {type= 1005, equipCID = gamedata.cache.equips[gamedata.ext.equipchangeIID].cid}
end