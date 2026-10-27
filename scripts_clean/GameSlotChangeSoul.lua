--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/10/22
-- Time: 下午4:56
-- To change this template use File | Settings | File Templates.
--

local slotchangesoul_pb = require("slotchangesoul_pb")
function UISlotChangeSoulCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1006, "SlotChangeSoul")
    local slotchangesoulData = slotchangesoul_pb.SlotChangeSoul()
    slotchangesoulData.slot = uireq.slot
    slotchangesoulData.soulpos = uireq.soulpos
    slotchangesoulData.soulid = uireq.soulid

    gamedata.ext.slotchangesoulslot =  uireq.slot
    gamedata.ext.slotchangesoulpos =  uireq.soulpos
    gamedata.ext.slotchangesouliid =  uireq.soulid

    return 1, 1006, slotchangesoulData:SerializeToString()
end

local slots_pb = require("slots_pb")
function NetSlotChangeSoulCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1006, "SlotChangeSoul")
    local info = slots_pb.SlotS()
    info:ParseFromString(fd.rbuf)

    local changes = {}
    local oldiid = gamedata.cache.slots[gamedata.ext.slotchangesoulslot]["s"..gamedata.ext.slotchangesoulpos]
    if gamedata.cache.souls[oldiid] then
        changes["star"..gamedata.cache.souls[oldiid].quality] = true
    end

    gamedata:SlotInfoProcess(info)

    if gamedata.cache.souls[gamedata.ext.slotchangesouliid] then
        changes["star"..gamedata.cache.souls[gamedata.ext.slotchangesouliid].quality] = true
    end
    changes["all"] = true
    return {type= 1006, changes = changes}
end