--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/1/7
-- Time: 下午5:47
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local slots_pb = require("slots_pb")



-- 魔符升级
function UISigilLevelUpCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1140, "SigilLevelUp")
    -- print("i...am...UISigilLevelUpCallBack")
    -- printT(uireq)
    gamedata.ext.mofulevelupid = uireq
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.iid)
    for k,v in pairs(uireq.choose) do
        table.insert(idsData.ids, v.iid)
    end

    return 1, 1140, idsData:SerializeToString()
end

function NetSigilLevelUpCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1140, "SigilLevelUp")
    -- print("i...am...NetSigilLevelUpCallBack")
    -- printT(gamedata.cache.gems)
    local info = slots_pb.SlotS()
    info:ParseFromString(fd.rbuf)

    gamedata:SlotInfoProcess(info)

    for k,v in pairs(gamedata.ext.mofulevelupid.choose) do
        gamedata.cache.gems[tonumber(v.iid)]=nil
        -- print("v======",v.iid)
        -- table.remove(gamedata.cache.gems,tonumber(v.iid))
    end
    -- print("v00000000000000")
    -- printT(gamedata.cache.gems)
    
    return {
        type= 1140,
        gems = makeMofulist(),
        iid = gamedata.ext.mofulevelupid.iid,
        propertytype = gamedata.ext.mofulevelupid.propertytype,
        slotmofudata = makeSlotGeminfo(),
    }
end

-- 魔符更换
function UISigilChangePosCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1141, "SigilChangePos")
    -- print("i...am...UISigilLevelUpCallBack")

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.pos)
    table.insert(idsData.ids, uireq.iid)

    return 1, 1141, idsData:SerializeToString()
end

function NetSigilChangePosCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1141, "SigilChangePos")
    -- print("i...am...NetWorldBoss2AttackCallBack")
    local info = slots_pb.SlotS()
    info:ParseFromString(fd.rbuf)

    gamedata:SlotInfoProcess(info)

    return {
        type= 1141,
        slotgems = makeSlotGeminfo(),
        gems = makeMofulist(),
    }
end

-- 魔符是否能升级数据获取
function UISigilCanLevelUpCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1142, "SigilChangePos")
    -- print("i...am...UISigilLevelUpCallBack")

    local data = getMofuCanLevelData(uireq.data)

    return 0, 1142, {type = 1142, data = data}
end