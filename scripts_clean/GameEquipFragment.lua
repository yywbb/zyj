--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-10-16
-- Time: 下午1:57
-- To change this template use File | Settings | File Templates.
--


local function makeEquipFragments()

    local Fragmentstemp = table.copy(gamedata.cache.equipfragments)

    local equipfragments ={}
    for k,v in pairs(Fragmentstemp) do
        if v.cid >= 27001 and v.cid <= 28000 then
            Fragmentstemp[k].quality = gamedata.config.equip[tostring(gamedata.config.equip_fragment[tostring(v.cid)].equip)].quality
            if Fragmentstemp[k].num >= gamedata.config.equip_fragment[tostring(v.cid)].num then
                Fragmentstemp[k].isenough = 1
            else
                Fragmentstemp[k].isenough = 0
            end
            table.insert(equipfragments,Fragmentstemp[k])
        end
    end

    gamedata.sortData(equipfragments, "isenough","quality","num","cid")

    return equipfragments

end

local function makeTreasureFragments()
    local Fragmentstemp = table.copy(gamedata.cache.equipfragments)

    local treasurefragments ={}
    for k,v in pairs(Fragmentstemp) do
        if v.cid >= 28001 and v.cid <= 29000 and gamedata.config.treasure2_fragment[tostring(v.cid)].page ~= "meterial" then
            Fragmentstemp[k].quality = gamedata.config.equip[tostring(gamedata.config.treasure2_fragment[tostring(v.cid)].equip)].quality
            table.insert(treasurefragments,Fragmentstemp[k])
        end
    end

    gamedata.sortData(treasurefragments, "quality","cid")

    return treasurefragments
end

local function makeMeterialFragments()
    local Fragmentstemp = table.copy(gamedata.cache.equipfragments)

    local meterialfragments ={}
    for k,v in pairs(Fragmentstemp) do
        if v.cid >= 28001 and v.cid <= 29000 and gamedata.config.treasure2_fragment[tostring(v.cid)].page == "meterial" then
            Fragmentstemp[k].quality = gamedata.config.props[tostring(gamedata.config.treasure2_fragment[tostring(v.cid)].equip)].quality
            table.insert(meterialfragments,Fragmentstemp[k])
        end
    end

    gamedata.sortData(meterialfragments, "quality","cid")

    return meterialfragments
end

local function makeFragments()
    local Fragmentstemp = table.copy(gamedata.cache.equipfragments)

    local equipfragments ={}
    local treasurefragments ={}
    local meterialfragments ={}

    for k,v in pairs(Fragmentstemp) do
        if v.cid >= 27001 and v.cid <= 28000 then
            Fragmentstemp[k].quality = gamedata.config.equip[tostring(gamedata.config.equip_fragment[tostring(v.cid)].equip)].quality
            if Fragmentstemp[k].num >= gamedata.config.equip_fragment[tostring(v.cid)].num then
                Fragmentstemp[k].isenough = 1
            else
                Fragmentstemp[k].isenough = 0
            end
            table.insert(equipfragments,Fragmentstemp[k])
        elseif v.cid >= 28001 and v.cid <= 29000 then
            if gamedata.config.treasure2_fragment[tostring(v.cid)].page == "meterial" then
                Fragmentstemp[k].quality = gamedata.config.props[tostring(gamedata.config.treasure2_fragment[tostring(v.cid)].equip)].quality
                table.insert(meterialfragments,Fragmentstemp[k])
            else
                Fragmentstemp[k].quality = gamedata.config.equip[tostring(gamedata.config.treasure2_fragment[tostring(v.cid)].equip)].quality
                table.insert(treasurefragments,Fragmentstemp[k])
            end
        end
    end

    gamedata.sortData(equipfragments, "isenough","quality","num","cid")
    gamedata.sortData(treasurefragments, "quality","cid")
    gamedata.sortData(meterialfragments, "quality","cid")

    return equipfragments,treasurefragments,meterialfragments
end

function UIEquipFragmentListCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 11071, "EquipFragment")

    if uireq.param then
        if uireq.param == "equip" then
            return 0, 11071, { type = uireq.type, equipfragments = makeEquipFragments(), }
        elseif uireq.param == "treasure" then
            return 0, 11071, { type = uireq.type, treasurefragments = makeTreasureFragments(), }
        else
            return 0, 11071, { type = uireq.type, meterialfragments = makeMeterialFragments(), }
        end
    else
        local equipfragments,treasurefragments,meterialfragments = makeFragments()
        return 0, 11071, { type = uireq.type, equipfragments = equipfragments, treasurefragments = treasurefragments, meterialfragments = meterialfragments }
    end
end


function UIEquipFragmentAllCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1107, "EquipFragment")
    if next(gamedata.cache.equipfragments) then
        local equipfragments,treasurefragments,meterialfragments = makeFragments()
        local treasures, horses, meterials = makeTreasureRob()
        return 0, 1107, {
            type = uireq.type,
            equipfragments = equipfragments,
            treasurefragments = treasurefragments,
            meterialfragments = meterialfragments,
            treasures=treasures,
            horses=horses,
            meterials = meterials,
        }
    else
        return 1, 1107, nil
    end
end

local idnums_pb = require("idnums_pb")
function NetEquipFragmentAllCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1107, "EquipFragment")
    local EquipFragmentData = idnums_pb.IdNums()
    EquipFragmentData:ParseFromString(fd.rbuf)

    local reset = true
    for k,v in ipairs(EquipFragmentData.idnums) do
        if v.num < 0 then
            reset = false
        end
    end 
    if reset then 
        gamedata.cache.equipfragments = {} 
    end
    
    gamedata:EquipFragments(EquipFragmentData.idnums)
    local equipfragments,treasurefragments,meterialfragments = makeFragments()
    local treasures, horses, meterials = makeTreasureRob()

    return {
        type = 1107,
        equipfragments = equipfragments,
        treasurefragments = treasurefragments,
        meterialfragments = meterialfragments,
        treasures=treasures,
        horses=horses,
        meterials = meterials,
    }
end