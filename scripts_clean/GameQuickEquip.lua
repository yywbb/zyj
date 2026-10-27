--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-10-11
-- Time: 下午3:38
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
function UIQuickEquipCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1007, "QuickEquip")
    local QuickEquipData = ids_pb.Ids()

    table.insert(QuickEquipData.ids, uireq.sid)
    gamedata.ext.quickequipsid = uireq.sid

    table.insert(QuickEquipData.ids, uireq.method)
    gamedata.ext.quickequipmethod = uireq.method

    for i=1,8 do
        if uireq.changeiids[tostring(i)] then
            table.insert(QuickEquipData.ids, uireq.changeiids[tostring(i)])
        end
    end

    printT(uireq)

    -- for k,v in pairs(uireq.ids) do
    --     table.insert(QuickEquipData.ids, v)
    --     gamedata.ext.quickequipsid = v
    -- end



    -- if uireq.method and  uireq.method == 1 then
    --     table.insert(QuickEquipData.ids, 1)
    --     gamedata.ext.quickequipmethod = 1
    -- elseif uireq.method and  uireq.method == 2 then
    --     table.insert(QuickEquipData.ids, 2)
    --     gamedata.ext.quickequipmethod = 2
    -- end
    --print(xxxx-1)
    return 1, 1007, QuickEquipData:SerializeToString()
end

local slots_pb = require("slots_pb")
function NetQuickEquipCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1007, "QuickEquip")
    local info = slots_pb.SlotS()
    info:ParseFromString(fd.rbuf)

    local oldslot = table.copy(gamedata.cache.slots[gamedata.ext.quickequipsid])

    gamedata:SlotInfoProcess(info)

    local newslot = table.copy(gamedata.cache.slots[gamedata.ext.quickequipsid])

    local haschange = gamedata.ext.quickequipmethod

    local changeTable ={}

    if gamedata.ext.quickequipmethod == 1 then
        if  oldslot.weapon ~= newslot.weapon then table.insert(changeTable,"weapon") end
        if  oldslot.armor ~= newslot.armor then table.insert(changeTable,"armor") end
        if  oldslot.accessory ~= newslot.accessory then table.insert(changeTable,"accessory") end
        if  oldslot.head ~= newslot.head then table.insert(changeTable,"head") end
        if  oldslot.treasure ~= newslot.treasure then table.insert(changeTable,"treasure") end
        if  oldslot.horse ~= newslot.horse then table.insert(changeTable,"horse") end
    elseif gamedata.ext.quickequipmethod == 2 then
        for i=1, 8 do
            if oldslot["s"..i] ~= newslot["s"..i] then
                if gamedata.cache.souls[oldslot["s"..i]] then
                   changeTable["all"] = true
                   changeTable["star"..gamedata.cache.souls[oldslot["s"..i]].quality] = true
                end
                if gamedata.cache.souls[newslot["s"..i]] then
                    changeTable["all"] = true
                    changeTable["star"..gamedata.cache.souls[newslot["s"..i]].quality] = true
                end
            end
        end
    end

    return {type= 1007, method = gamedata.ext.quickequipmethod, changeTable = changeTable}
end