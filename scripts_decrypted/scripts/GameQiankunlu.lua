--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/12/21
-- Time: 下午2:06
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local idnums_pb = require("idnums_pb")


--装备宝物炼化  传入iid
function UIEquipResolveCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1104, "EquipResolve")
    -- print("UIEquipResolveCallBack===")
    printT(uireq)
    gamedata.ext.equipResolveIds = {}
    gamedata.ext.equipResolveCid = uireq.cid
    gamedata.ext.equipResolveFragments = uireq.fragments

    local equipFragmentDataTotal = idnums_pb.IdNums()
    for k,v in pairs(uireq.fragments) do
        local fragment = equipFragmentDataTotal.idnums:add()
        fragment.id = v.cid
        fragment.num = v.num
    end

    for k,v in pairs(uireq.ids) do
        local fragment = equipFragmentDataTotal.idnums:add()
        fragment.id = v
        fragment.num = -1
    end


    for k,v in pairs(uireq.ids) do
        table.insert(gamedata.ext.equipResolveIds, v)
    end

    return 1, 1104, equipFragmentDataTotal:SerializeToString()
end

local somethings_pb = require("somethings_pb")
function NetEquipResolveCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1104, "EquipResolve")
    -- print("NetEquipResolveCallBack===")
    local EquipResolveData = somethings_pb.SomeThings()
    EquipResolveData:ParseFromString(fd.rbuf)

    local props = {}
    -- local type = gamedata.config.equip[tostring(gamedata.cache.equips[gamedata.ext.equipResolveIds[1]].cid)].type
    local num = table.getTableLength(gamedata.ext.equipResolveIds)
    props = gamedata:SomethingProcess(EquipResolveData)
    gamedata:removeEquips(gamedata.ext.equipResolveIds)

    for k,v in pairs(gamedata.ext.equipResolveFragments) do
        gamedata:updateStaff({cid = v.cid,num = -v.num})
    end

    printT(props,"props")
    printT(gamedata.ext.equipResolveCid,"equipResolveCid")
    print(num)

    return { type = 1104, reward = props, num = num, cid = gamedata.ext.equipResolveCid}
end


--武将碎片炼化  传入{cid,num}
function  UIGeneralFragmentResolveCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1036, "GeneralFragmentResolve")
    -- print("UIGeneralFragmentResolveCallBack===")
    -- printT(uireq)

    local GeneralFragmentData = idnums_pb.IdNums()

    for k,v in pairs(uireq.fragments) do
        local fragment = GeneralFragmentData.idnums:add()
        fragment.id = v.cid
        fragment.num = v.num
    end
    gamedata.ext.GeneralFragmentResolveData = uireq.fragments

    return 1,1036,GeneralFragmentData:SerializeToString()
end

function  NetGeneralFragmentResolveCallBack(fd)
    -- print("NetGeneralFragmentResolveCallBack===")
    local ResolveData = somethings_pb.SomeThings()
    ResolveData:ParseFromString(fd.rbuf)

    for k,v in pairs(gamedata.ext.GeneralFragmentResolveData) do
        v.num = 0-v.num
        gamedata:updategeneralfragmentbynum(v)
    end

    return { type = 1036, reward = gamedata:SomethingProcess(ResolveData), cid = gamedata.ext.GeneralFragmentResolveData}
end


--新炼化  传入{cid,num}
function UIGeneralResolveCallBack2(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1039, "UIGeneralResolveCallBack2")
    -- print("UIGeneralFragmentResolveCallBack===")
    printT(uireq)
    local GeneralFragmentDataTotal = idnums_pb.IdNums()
    for k,v in pairs(uireq.fragments) do
        local fragment = GeneralFragmentDataTotal.idnums:add()
        fragment.id = v.cid
        fragment.num = v.num
    end

    gamedata.ext.GeneralResolveData2 = uireq.ids
    gamedata.ext.GeneralFragmentResolveData2 = uireq.fragments
    gamedata.ext.GeneralResolveData3 = uireq.cid

    return 1,1039,GeneralFragmentDataTotal:SerializeToString()
end

function  NetGeneralResolveCallBack2(fd)
    -- print("NetGeneralFragmentResolveCallBack===")
    local ResolveData = somethings_pb.SomeThings()
    ResolveData:ParseFromString(fd.rbuf)

    for k,v in pairs(gamedata.ext.GeneralFragmentResolveData2) do
        if (v.cid >= 10101 and v.cid <= 11000) or (v.cid >= 160001 and v.cid <= 161000) or (v.cid >= 170001 and v.cid <= 171000) or (v.cid >= 162001 and v.cid <= 163000) or (v.cid >= 164001 and v.cid <= 165000) or (v.cid >= 174001 and v.cid <= 175000) then
        else
            v.num = 0-v.num
            gamedata:updategeneralfragmentbynum(v)
        end
    end

    for k,v in pairs(gamedata.ext.GeneralResolveData2) do
        gamedata.cache.generals[v] = nil
    end

    return { type = 1039, reward = gamedata:SomethingProcess(ResolveData), cid = gamedata.ext.GeneralResolveData3}
end


--装备宝物重生 传入iid
function  UIEquipResetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1117, "EquipReset")
    local EquipResetData = ids_pb.Ids()
    -- print("UIEquipResetCallBack===")
    -- printT(uireq)
    for k,v in pairs(uireq.ids) do
        table.insert(EquipResetData.ids,v)
    end
    gamedata.ext.EquipResetData = uireq

    return 1,1117,EquipResetData:SerializeToString()
end

function  NetEquipResetCallBack(fd)
    -- print("NetEquipResetCallBack===")

    local ResetData = somethings_pb.SomeThings()
    ResetData:ParseFromString(fd.rbuf)

    gamedata:updateRoleGold(0-tonumber(gamedata.ext.EquipResetData.gold),"装备宝物重生消耗金币",1)

    return { type = 1117, reward = gamedata:SomethingProcess(ResetData), cid = gamedata.ext.EquipResetData.cid }
end


--武将重生 传入iid
function  UIGeneralResetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1035, "GeneralReset")
    local GeneralResetData = ids_pb.Ids()
    -- print("UIGeneralResetCallBack==")
    -- printT(uireq)

    for k,v in pairs(uireq.ids) do
        table.insert(GeneralResetData.ids,v)
    end
    gamedata.ext.GeneralResetData = uireq

    return 1,1035,GeneralResetData:SerializeToString()
end

function  NetGeneralResetCallBack(fd)
    -- print("NetGeneralResetCallBack==")
    local ResetData = somethings_pb.SomeThings()
    ResetData:ParseFromString(fd.rbuf)

    local updateExclusiveArtifact = nil
    gamedata:updateRoleGold(0-tonumber(gamedata.ext.GeneralResetData.gold),"武将重生消耗金币",1)
    local reward = gamedata:SomethingProcess(ResetData)

    for k,v in pairs(gamedata.ext.GeneralResetData.ids) do
        if v == gamedata.cache.protagonist.iid then
            gamedata.cache.protagonist.general.level6 = 0
            gamedata.cache.protagonist.general.level7 = 0
        else
            local general = gamedata.cache.generals[v]
            if general then

                if general.exclusiveArtifactCid and general.exclusiveArtifactCid > 0 then
                    updateExclusiveArtifact = true
                end
                general.level6 = 0
                general.level7 = 0
            end
        end
        if gamedata.cache.xiuLianData then
            gamedata.cache.xiuLianData[v] = nil
        end
    end

    return { type = 1035, reward = reward, cid = gamedata.ext.GeneralResetData.cid,updateExclusiveArtifact = updateExclusiveArtifact}
end

--时装重生 传入id
function  UIFashionDressResetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1077, "FashionReset")
    local FashionResetData = ids_pb.Ids()
    print("UIFashionDressResetCallBack==")
    printT(uireq)

    for k,v in pairs(uireq.ids) do
        table.insert(FashionResetData.ids,v)
    end
    gamedata.ext.FashionResetData = uireq

    return 1,1077,FashionResetData:SerializeToString()
end

function  NetFashionDressResetCallBack(fd)
    print("NetFashionDressResetCallBack==")
    local ResetData = somethings_pb.SomeThings()
    ResetData:ParseFromString(fd.rbuf)

    gamedata:updateRoleGold(0-tonumber(gamedata.ext.FashionResetData.gold),"时装重生消耗金币",1)

    return { type = 1077, reward = gamedata:SomethingProcess(ResetData), cid = gamedata.ext.FashionResetData.ids}
end


--武将化魂 传入iid
function  UIGeneralResolveCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1037, "GeneralResolve")
    local GeneralResolveData = ids_pb.Ids()

    for k,v in pairs(uireq.ids) do
        table.insert(GeneralResolveData.ids,v)
    end
    gamedata.ext.GeneralResolveData = uireq

    return 1,1037,GeneralResolveData:SerializeToString()
end

function  NetGeneralResolveCallBack(fd)
    local ResetData = somethings_pb.SomeThings()
    ResetData:ParseFromString(fd.rbuf)

    for k,v in pairs(gamedata.ext.GeneralResolveData.ids) do
        gamedata.cache.generals[v] = nil
    end

    gamedata:updateRoleCoin(0-tonumber(gamedata.ext.GeneralResolveData.coin),"武将化魂消耗银币",1)

    return { type = 1037, reward = gamedata:SomethingProcess(ResetData),cid = gamedata.ext.GeneralResolveData.cid}
end


function  UIResolveQualityCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3850, "ResolveQuality")
    
    if uireq.quality then
        --gamedata.cache.ResolveQuality = uireq.quality
        --return 0,3850,{ type = 3850, quality = gamedata.cache.ResolveQuality}

        local ResolveQualityData = ids_pb.Ids()
        table.insert(ResolveQualityData.ids,uireq.quality)
        return 1,3850,ResolveQualityData:SerializeToString()
    else
        if gamedata.cache.ResolveQuality then
            return 0,3850,{ type = 3850, quality = gamedata.cache.ResolveQuality}
        else
            -- gamedata.cache.ResolveQuality = 4
            -- return 0,3850,{ type = 3850, quality = gamedata.cache.ResolveQuality}
            return 1,3850,nil
        end
    end
end

function  NetResolveQualityCallBack(fd)
    local ResolveQualityData = ids_pb.Ids()
    ResolveQualityData:ParseFromString(fd.rbuf)

    local quality = ResolveQualityData.ids[1] or 4
    gamedata.cache.ResolveQuality = quality
    return { type = 3850, quality = quality}
end


--pet重生 传入id
function  UIPetResetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1065, "UIPetResetCallBack")
    local ResetData = ids_pb.Ids()

    for k,v in pairs(uireq.ids) do
        table.insert(ResetData.ids,v)
    end
    gamedata.ext.PetResetData = uireq

    return 1,1065,ResetData:SerializeToString()
end

function  NetPetResetCallBack(fd)

    local ResetData = somethings_pb.SomeThings()
    ResetData:ParseFromString(fd.rbuf)

    gamedata:updateRoleGold(0-tonumber(gamedata.ext.PetResetData.gold),"魔宠重生消耗元宝",1)

    return { type = 1065, reward = gamedata:SomethingProcess(ResetData), cid = gamedata.ext.PetResetData.ids}
end

function  NetbagLimitTipCallBack(fd)
    local ResetData = ids_pb.Ids()
    ResetData:ParseFromString(fd.rbuf)
    
    return { type = 5555, kind = ResetData.ids[1], opt=1}
end

--
function UIRedfragmentResolveCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6901, "UIRedfragmentResolveCallBack")

    local GeneralFragmentDataTotal = idnums_pb.IdNums()
    for k,v in pairs(uireq.fragments) do
        local fragment = GeneralFragmentDataTotal.idnums:add()
        fragment.id = v.cid
        fragment.num = v.num
    end

    gamedata.ext.RedfragmentResolve = uireq.fragments or {}

    return 1,6901,GeneralFragmentDataTotal:SerializeToString()
end

function  NetRedfragmentResolveCallBack(fd)

    local ResolveData = somethings_pb.SomeThings()
    ResolveData:ParseFromString(fd.rbuf)

    for k,v in pairs(gamedata.ext.RedfragmentResolve) do
        if v.num > 0 then
            gamedata:UpdateRedFragment({cid = v.cid,num = 0-v.num})
        end
    end

    return { type = 6901, reward = gamedata:SomethingProcess(ResolveData),}
end

   �.  