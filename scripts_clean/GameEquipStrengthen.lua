--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 14-10-9
-- Time: 15:43
-- To change this template use File | Settings | File Templates.
--
local xcoin = 0
local method = 0

local ids_pb = require("ids_pb")
local equipstrengthen_pb = require("equipstrengthen_pb")
function UIEquipStrengthenCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1101, "equipstrengthen")
    local equipstrengthenData = equipstrengthen_pb.EquipStrengthen()
    equipstrengthenData.iid = uireq.iid
    equipstrengthenData.method = uireq.method
    xcoin = uireq.xcoin or 0
    method = uireq.method or 0
    if gamedata.cache.role.coin< uireq.xcoin then
         return 0,503,{type = 503, msgtype = "shortcoin"}
    end

    gamedata.ext.equipstrengthenid = uireq.iid
    return 1, 1101, equipstrengthenData:SerializeToString()
end

local somethings_pb = require("somethings_pb")
function NetEquipStrengthenCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1101, "equipstrengthen")

    local equipstrengthenData = somethings_pb.SomeThings()
    equipstrengthenData:ParseFromString(fd.rbuf)

    local changeequips,ext,criticalnum = gamedata:SomethingProcess(equipstrengthenData,"equipstrengthen")

    if method == 0 then
        -- 已特殊处理 不需要再扣银币
        --gamedata:updateRoleCoin(0-xcoin)
    elseif method == 1 then
        --同上
    end


    return { 
        type = 1101, 
        ison = gamedata:isEquipOn(gamedata.ext.equipstrengthenid),
        equip = gamedata.cache.equips[gamedata.ext.equipstrengthenid],
        coin = gamedata.cache.role.coin,
        criticalnum = criticalnum,
    }
end


function UIQuickEquipStrengthenCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1109, "QuickEquipStrengthen")
    local QuickEquipData = ids_pb.Ids()



    for k,v in pairs(uireq.ids) do

        local cando, des = checkQuickStrength(v)
        if cando then
            table.insert(QuickEquipData.ids, v)
            gamedata.ext.quickequipstrengthen = v
        else
            return 0,503,des
        end
    end

    return 1, 1109, QuickEquipData:SerializeToString()
end

function NetQuickEquipStrengthenCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1109, "QuickEquipStrengthen")

    local equipstrengthenData = somethings_pb.SomeThings()
    equipstrengthenData:ParseFromString(fd.rbuf)

    local changeequips,ext,criticalnum = gamedata:SomethingProcess(equipstrengthenData,"equipstrengthen")

    return { type = 1109, changeequips = changeequips,criticalnum = criticalnum}
end

function UIEquipCastCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5521, "equipCast")
    local info = ids_pb.Ids()
    table.insert(info.ids,uireq.iid)
    table.insert(info.ids,uireq.count)
    
    gamedata.ext.equipCastIid = uireq.iid
    gamedata.ext.equipCastProps = uireq.props
    return 1,5521, info:SerializeToString()
end

function NetEquipCastCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5521, "equipCast")

    local info = somethings_pb.SomeThings()
    info:ParseFromString(fd.rbuf)

    gamedata:SomethingProcess(info)

    for k,v in pairs(gamedata.ext.equipCastProps) do
        gamedata:updateStaff({cid = v.cid,num = -v.num,name = "装备注灵"})
    end


    return { 
        type = 5521, 
        ison = gamedata:isEquipOn(gamedata.ext.equipCastIid),
        equip = gamedata.cache.equips[gamedata.ext.equipCastIid],
    }
end