--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-10-16
-- Time: 下午3:43
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local fragment_cid = 0
function UIEquipFragmentCompoundCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1108, "EquipFragmentCompound")
    local EquipFragmentCompoundData = ids_pb.Ids()

    table.insert(EquipFragmentCompoundData.ids, uireq.ids["1"])
    if uireq.ids["2"] then
        table.insert(EquipFragmentCompoundData.ids, uireq.ids["2"])
    end

    if uireq.ids["3"] then 
        fragment_cid = uireq.ids["3"]
    end

    return 1, 1108, EquipFragmentCompoundData:SerializeToString()
end

local somethings_pb = require("somethings_pb")
function NetEquipFragmentCompoundCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1108, "EquipFragmentCompound")

    local equipData = somethings_pb.SomeThings()
    equipData:ParseFromString(fd.rbuf)

    local getequip = gamedata:SomethingProcess(equipData)
    local equiptype = "equip"

    for kk,vv in ipairs(getequip) do
        local equipConfig = gamedata.IDconfig(getequip[kk].cid)

        if equipConfig.staffType == "equip" then
            if equipConfig.type == "horse" or equipConfig.type == "treasure"  then
                equiptype = "treasure"
                for k, v in pairs(gamedata.config.treasure2_fragment) do
                    if v.equip == getequip[kk].cid then
                        gamedata:updateequipfragment({cid = v.id,num = 0-1})
                    end
                end
            else
                equiptype = "equip"
                for k, v in pairs(gamedata.config.equip_fragment) do
                    if v.equip == getequip[kk].cid then
                        gamedata:updateequipfragment({cid = v.id,num = 0-v.num})
                    end
                end
            end
        elseif equipConfig.staffType == "props" then
            equiptype = "meterial"
            for k, v in pairs(gamedata.config.treasure2_fragment) do
                if v.equip == getequip[kk].cid then
                    gamedata:updateequipfragment({cid = v.id,num = 0-getequip[kk].num})
                end
            end
        end
    end

    return { type = 1108, reward = getequip, equiptype = equiptype, cid = fragment_cid or 0,}
end