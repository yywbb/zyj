--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-2
-- Time: 下午4:26
-- To change this template use File | Settings | File Templates.
--
local ids_pb = require("ids_pb")
local socket = require("socket")
local slots_pb = require("slots_pb")
local somethings_pb = require("somethings_pb")
local generals_pb = require("generals_pb")
local combmessages_pb = require("combmessages_pb")
local generalchangepos_pb = require"generalchangepos_pb"
local apex_slots_pb = require"apex_slots_pb"


local slotccbconfig = {1,2,3,4,5,6,7,8 }

local propconfig = {
    weapon = {20022,20023,20024,20025},
    armor = {20026,20027,20028,20029},
    head = {20034,20035,20036,20037},
    accessory = {20030,20031,20032,20033},
    horse = {20042,20043,20044,20045},
    treasure = {20038,20039,20040,20041},
}

local function addGeneralName(data,iid,generaliid)
    if iid and iid ~= 0 then
        data[iid].ison = 1
        if not gamedata.cache.generals[generaliid] or generaliid == gamedata.cache.protagonist.iid  then
            data[iid].generalcid = gamedata.cache.protagonist.general.cid
        else
            data[iid].generalcid = gamedata.cache.generals[generaliid].cid
        end

    end
end

local function Split(szFullString, szSeparator)
    local nFindStartIndex = 1
    local nSplitIndex = 1
    local nSplitArray = {}
    while true do
        local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)
        if not nFindLastIndex then
            if nFindStartIndex < string.len(szFullString) then
                nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
            end
            break
        end
        nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
        nFindStartIndex = nFindLastIndex + string.len(szSeparator)
        nSplitIndex = nSplitIndex + 1
    end
    return nSplitArray
end

local function EquipGeneral_related(equipcid,generalcid)
    local generalconfig = gamedata.config.general[tostring(generalcid)]
    local equipconfig = gamedata.config.equip[tostring(equipcid)]
    local idx = 1
    while true do
        local condids = generalconfig["cond"..idx.."ids"]
        if condids and condids ~= "" then
            for k,v in pairs(Split(condids,";")) do
                if tonumber(equipcid) == tonumber(v) then
                    return true
                end
                local relative1 = equipconfig.relative
                if tonumber(relative1) == tonumber(v) then
                    return true
                end
                local relative2 = equipconfig.treasure_relation
                if tonumber(relative2) == tonumber(v) then
                    return true
                end
            end            
        else
            break
        end
        idx = idx + 1
    end

    return false
end

function makeAllGeneralsTemp()
    local generalstemp = table.copy(gamedata.cache.generals)

    for k,v in pairs(gamedata.cache.slots) do
        if generalstemp[v.general] then
            generalstemp[v.general].ison = 2
            generalstemp[v.general].relation = v.relation
        end
    end

    for k,v in pairs(gamedata.cache.cheers) do
        generalstemp[v.general].ison = 1
    end
    return generalstemp
end

--选择上阵武将/助阵小伙伴, 3个阵容,在阵武将可以互相交换位置
--team_id 当前阵容id
--isGeneral 为true表示 ,筛选的是要上阵武将, false表示筛选的是要上助阵位
function makeAllGodCompetitionGeneralsTemp(team_id,isGeneral)
    local goddata = table.copy(gamedata.cache.godCompetionData)
    local generalstemp = table.copy(gamedata.cache.generals)

    -- printT(goddata,"makeAllGodCompetitionGeneralsTemp")
    -- printT(generalstemp,"generalstemp")

    for i=1,3 do
        local _general = goddata[i].slot_General.general
        local relationdata = goddata[i].slot_General.relation
        -- printT(_general,"_general")

        for k,v in pairs (_general) do
            if v and v.general  then
                printT(v.general,"v.general")
                if generalstemp[v.general.iid] then
                    generalstemp[v.general.iid].ison = 20+i 
                    print(v.general.iid,"general_iid")
                    if relationdata and relationdata[i] and relationdata[i][k] then
                        print(relationdata[i][k],"relationdata")
                        generalstemp[v.general.iid].relation = relationdata[i][k] 
                    else
                        generalstemp[v.general.iid].relation = {}
                    end    
                end    
            end    
        end 
        
        local _cheer = goddata[i].cheer_General
        for k,v in pairs(_cheer) do
            if v and v.general  then
                print(v.general.iid,"cheer_iid")
                generalstemp[v.general.iid].ison = 10
            end    
        end
    end    

    -- printT(generalstemp,"makeAllGodCompetitionGeneralsTemp return")

    return generalstemp
end


function makeAllGenerals(GeneralTemp)

    local allgenerals = {}
    for k,v in pairs(GeneralTemp or makeAllGeneralsTemp()) do
        v.fragmentnum = gamedata.cache.generalfragments[v.cid] and gamedata.cache.generalfragments[v.cid].num or 0
        table.insert(allgenerals,v)
    end
    gamedata.sortData(allgenerals, "ison", "quality", "level1", "level2","cid")

    return allgenerals
end

--
function makeGeneralHint()
    mekehintext(6,0)

    for k,v in pairs(gamedata.cache.slots) do
        v.hashint_tupo = nil
        if gamedata.cache.role.level < gamedata.config.build[tostring(52)].level then
            break
        end
        local data = gamedata.cache.generals[v.general]
        --突破
        if data then
            local configdata = gamedata.config.general[tostring(data.cid)]
            local redcid = (configdata.quality == 6) and data.cid or 0
            local goldcid = (configdata.quality >= 7) and data.cid or 0
            local ocid = gamedata.getOriginCid(data.cid)

            if configdata.red_id and configdata.red_id > 0 then
                redcid = configdata.red_id
            elseif configdata.break_id and configdata.break_id > 0 then
                redcid = configdata.break_id
            elseif (configdata.quality == 6) and configdata.partner_id and configdata.partner_id > 0 then
                redcid = configdata.partner_id
            end

            if configdata.gold_id and configdata.gold_id > 0 then
                goldcid = configdata.gold_id
            elseif (configdata.quality >= 7) and configdata.partner_id and configdata.partner_id > 0 then
                goldcid = configdata.partner_id     
            end

            local quality = configdata.quality or 5
            local nextnum = 0
            local nextlevel = 0
            local needprop,needcoin = 0,0
            local needredprop,needrednum,needredprop2 = 0,0
            local needawaken,needfavorate = 0,0
            local ismax = 0
            local needgoldprop = {}
            local hasgoldprop = 1
            local needsoaring = 0
            if data.level2+1 <= table.getTableLength(gamedata.config.general_awake) then
                if data.level2+1 <= 10 then
                    quality = configdata.quality or 5
                elseif data.level2+1 > 13 then
                    if goldcid > 0 then 
                        quality = 7
                    else
                        ismax = 1
                    end    
                elseif redcid > 0 then
                    quality = 6
                else
                    ismax = 1
                end

                nextnum = gamedata.config.general_awake[tostring(data.level2+1)][quality.."piece"] or 0
                nextlevel = gamedata.config.general_awake[tostring(data.level2+1)].level or 0
                needprop = gamedata.config.general_awake[tostring(data.level2+1)][tostring(quality).."prop"] or 0
                needcoin = gamedata.config.general_awake[tostring(data.level2+1)]["coin"..tostring(quality)] or 0
                needredprop = gamedata.config.general_awake[tostring(data.level2+1)]["red_cost"] or 0
                needredprop2 = gamedata.config.general_awake[tostring(data.level2+1)]["red_cost2"] or 0
                needrednum = gamedata.config.general_awake[tostring(data.level2+1)]["red_item"] or 0
                needawaken = gamedata.config.general_awake[tostring(data.level2+1)]["awaken_lv"] or 0
                needfavorate = gamedata.config.general_awake[tostring(data.level2+1)]["favorate_lv"] or 0               
                --
                if gamedata.config.general_awake[tostring(data.level2+1)] and gamedata.config.general_awake[tostring(data.level2+1)].soaring_limit and gamedata.config.general_awake[tostring(data.level2+1)].soaring_limit > 0 then
                    needsoaring = gamedata.config.general_awake[tostring(data.level2+1)].soaring_limit or 0
                end  
                hasgoldprop = 1
                needgoldprop = {}
                if gamedata.config.general_awake[tostring(data.level2+1)]["gold_cost"] and gamedata.config.general_awake[tostring(data.level2+1)]["gold_cost"] ~= "" then
                    needgoldprop = gamedata.getIDandNUMs(gamedata.config.general_awake[tostring(data.level2+1)]["gold_cost"]) or {}
                end 
                for k,v in pairs(needgoldprop) do
                    if (gamedata.getStaffNum(v.cid).num or 0) < (v.num or 0) then
                        hasgoldprop = 0
                    end    
                end  
                --
                local favoratecid = ocid --data.cid
                -- if configdata.generalid2 and configdata.generalid2 > 0 then
                --     favoratecid = configdata.generalid2
                -- end
                local favoratelv = 0
                if gamedata.cache.generalslove.alldata and gamedata.cache.generalslove.alldata[tostring(favoratecid)] and gamedata.cache.generalslove.alldata[tostring(favoratecid)].level then
                    favoratelv = gamedata.cache.generalslove.alldata[tostring(favoratecid)].level or 0
                end

                --
                if (ismax == 0) 
                and (hasgoldprop == 1)   
                and (needsoaring <= data.level8) 
                and (needawaken <= data.skilllevel) 
                and (favoratelv >= needfavorate) 
                and ((gamedata.cache.generalfragments[ocid] 
                and gamedata.cache.generalfragments[ocid].num or 0) >= nextnum) 
                and ((gamedata.cache.redfragment[redcid+8000] 
                and gamedata.cache.redfragment[redcid+8000].num or 0) >= needrednum) 
                and (configdata.quality >= 3) 
                and (data.level1 >= nextlevel) 
                and ((gamedata.cache.props[20017] and gamedata.cache.props[20017].num or 0) >= needprop) 
                and (gamedata.cache.role.coin >= needcoin) 
                and ((gamedata.cache.props[20354] and gamedata.cache.props[20354].num or 0) >= needredprop) 
                and ((gamedata.cache.props[20551] and gamedata.cache.props[20551].num or 0) >= needredprop2) then
                    mekehintext(6,1)
                    v.hashint_tupo = true
                end
            end
        end
    end

    for k,v in pairs(gamedata.cache.slots) do
        v.hashint_feisheng = nil
        if gamedata.cache.role.level < gamedata.config.build[tostring(449)].level then
            break
        end
        local data = gamedata.cache.generals[v.general]
        --飞升
        if data and gamedata.judgeFeiSheng(data.cid) then
            local active = 0
            local generalConfig = gamedata.config.general[tostring(data.cid)]
            local level = data.level8
            local curFeishengConfig = gamedata.config.partner_soaring[tostring(level)]
            local nextFeishengConfig = gamedata.config.partner_soaring[tostring(level + 1)]
            local originalBasic = generalConfig.basic
            if generalConfig.generalid2 > 0 then
                originalBasic = gamedata.config.general[tostring(generalConfig.generalid2)].basic
            end

            --最大级

            if nextFeishengConfig then
                --突破要求
                if nextFeishengConfig.breach and nextFeishengConfig.breach > 0 then
                    if data.level2 < nextFeishengConfig.breach then
                        active = 1
                    end
                end
                --进修要求
                if nextFeishengConfig.immortal and nextFeishengConfig.immortal > 0 then
                    --判断进修
                    if data.level6 < nextFeishengConfig.immortal or data.level7 < nextFeishengConfig.immortal then
                        active = 1
                    end
                end
                 --消耗
                local consume = gamedata.getIDandNUMs(nextFeishengConfig[originalBasic.."consume"])

                for _i,_v in ipairs(consume) do
                    local havePropNum = 0
                    if _v.cid == 1000 then
                        havePropNum = gamedata.cache.role.coin
                    elseif _v.cid == 1001 then
                        havePropNum = gamedata.cache.role.gold
                    else
                        havePropNum = (gamedata.cache.props[_v.cid] and gamedata.cache.props[_v.cid].num or 0)
                    end
                    local needPropNum = _v.num or 0
                    if needPropNum > havePropNum then
                        active = 1
                        break
                    end
                end
                if active == 0 then
                    mekehintext(6,1)
                    v.hashint_feisheng = true
                end
            end
        end
    end


    for k,v in pairs(gamedata.cache.slots) do
        --伙伴升星
        local hashint_upstar = nil
        local data = gamedata.cache.generals[v.general]

        if data and data.level2 > 13 and gamedata.config.build[tostring(572)].switch == 1 and gamedata.cache.role.level >= gamedata.config.build[tostring(572)].level then
            local nextConfig = gamedata.config.general_star[tostring(data.level5 + 1)]
            if nextConfig then
                hashint_upstar = true

                --判断飞升等级
                if data.level8 < nextConfig.limitlv then
                    hashint_upstar = nil
                end
                --判断消耗
                if hashint_upstar then
                    local consume = gamedata.getIDandNUMs(nextConfig.consume)
                    for i,v in ipairs(consume) do
                        if v.cid == 1000 then
                            if v.num > 0 and gamedata.cache.role.coin < v.num then
                                hashint_upstar = nil
                            end
                        elseif v.cid == 1001 then
                            if v.num > 0 and gamedata.cache.role.gold < v.num then
                                hashint_upstar = nil
                            end
                        else
                            if gamedata.getStaffNum(v.cid).num < v.num then
                                hashint_upstar = nil
                            end
                        end
                    end
                end
            end

            print("hashint_upstar",data.level5,hashint_upstar)
        end

        if hashint_upstar then
            mekehintext(6,1)
        end

        v.hashint_upstar = hashint_upstar
    end


    for k,v in pairs(gamedata.cache.slots) do
        local general = gamedata.cache.generals[v.general]
        if general then
            general.hashint_exclusive = nil
            --判断专属神器激活
            local hashint_exclusiveActive = CheckExclusiveActiveHint(general)
            general.hashint_exclusiveActive = hashint_exclusiveActive

            --专属神器强化
            local hashint_exclusiveIntensify = CheckExclusiveIntensifyHint(general)
            general.hashint_exclusiveIntensify = hashint_exclusiveIntensify

            --专属神器 镶嵌 更换红点
            local hashint_exclusiveQiling = CheckExclusiveQilingHint(general)
            general.hashint_exclusiveQiling = hashint_exclusiveQiling

            -- printT(general,"makeGeneralHint_exclusive")

            local hashint_qiling = nil
            for k2,v2 in pairs(hashint_exclusiveQiling) do
                if v2 > 0 then
                    hashint_qiling = true
                    break
                end
            end

            if hashint_exclusiveActive or hashint_exclusiveIntensify or hashint_qiling then
                general.hashint_exclusive = true
            end
        end
    end
    

end

function checkGeneralRelation(cid1,cid2)
    local relations = {}
    local generalconfig = gamedata.config.general[tostring(cid1)]
    for i=1,6 do
        if generalconfig["cond"..i.."type"] and generalconfig["cond"..i.."type"] == "person" then
            if generalconfig["cond"..i.."ids"] and generalconfig["cond"..i.."ids"] ~= "" then
                for k,v in pairs(Split(generalconfig["cond"..i.."ids"],";")) do
                    if tonumber(cid2) == tonumber(v) then
                        return generalconfig["cond"..i.."name"]
                    end
                end
            end
        end
    end
    return nil
end

local function addonegeneralrelation(relations,iid,exceptCID)

    if not gamedata.cache.generals[iid] or gamedata.cache.generals[iid].cid == exceptCID then return end
    local generalconfig = gamedata.config.general[tostring(gamedata.cache.generals[iid].cid)]

    for i=1,6 do
        if generalconfig["cond"..i.."type"] and generalconfig["cond"..i.."type"] == "person" then
            if generalconfig["cond"..i.."ids"] and generalconfig["cond"..i.."ids"] ~= "" then
                local relationdata = Split(generalconfig["cond"..i.."ids"],";")
                relations[generalconfig.name..i] = {name = generalconfig["cond"..i.."name"],has = 0,relationdata = relationdata }
            end
        end
    end
end

local function fillrelaition(relations,iid,exceptCID)
    if not gamedata.cache.generals[iid] or gamedata.cache.generals[iid].cid == exceptCID then return end
    local cid = gamedata.cache.generals[iid].cid
    local cid2 = gamedata.config.general[tostring(cid)].generalid2 or 0
    local cid3 = gamedata.config.general[tostring(cid)].partner_id or 0
    local cid4 = gamedata.config.general[tostring(cid)].orange_id or 0
    local cid5 = gamedata.config.general[tostring(cid)].red_id or 0
    for k,v in pairs(relations) do
        for k_,v_ in pairs(v.relationdata) do
            if (cid == tonumber(v_)) or (cid2 == tonumber(v_)) or (cid3 == tonumber(v_)) or (cid4 == tonumber(v_)) or (cid5 == tonumber(v_)) then
                v.has = v.has + 1
            end
        end
    end
end

function addGeneralRelation(offgenerals,exceptCID,type)
    exceptCID = exceptCID or 0

    local slotgeneral = {}
    local relations = {}

    for kk,slot in pairs(gamedata.cache.slots) do
        if slot.general and slot.general ~= 0 then
            addonegeneralrelation(relations,slot.general,exceptCID)
        end
    end

--    for kk,slot in pairs(gamedata.cache.cheers) do
--        if slot.general and slot.general ~= 0 then
--            addonegeneralrelation(relations,slot.general,exceptCID)
--        end
--    end





    for kk,vv in ipairs(offgenerals) do

        local relations_ = table.copy(relations)
        if type and type == "slot" then
            addonegeneralrelation(relations_,vv.iid)
        end


        for kk,slot in pairs(gamedata.cache.slots) do
            if slot.general and slot.general ~= 0 then
                fillrelaition(relations_,slot.general,exceptCID)
            end
        end

        for kk,cheer in pairs(gamedata.cache.cheers) do
            if cheer.general and cheer.general ~= 0 then
                fillrelaition(relations_,cheer.general,exceptCID)
            end
        end

        for k,v in pairs(relations_) do
            if v.has >= #v.relationdata then
                local checkstring = string.sub(k,1,-2)
                --if string.find(k,gamedata.config.general[tostring(vv.cid)].name) then
                if checkstring == gamedata.config.general[tostring(vv.cid)].name then
                else
                    relations_[k]=nil
                end
            end
        end

        fillrelaition(relations_,vv.iid)

        local activerelation = {}

        for k,v in pairs(relations_) do
            if v.has >= #v.relationdata then
                table.insert(activerelation,v.name)
            end
        end
        --printT(relations_,gamedata.config.general[tostring(vv.cid)].name.."relations_")

        vv.hasrelation = next(activerelation) and activerelation or nil
        vv.relationnum = #activerelation

    end


--    for k,v in ipairs(offgenerals) do
--        local relations = {}
--        local relations2 = {}
--        local generalconfig = gamedata.config.general[tostring(v.cid)]
--        for i=1,6 do
--            if generalconfig["cond"..i.."type"] and generalconfig["cond"..i.."type"] == "person" then
--                if generalconfig["cond"..i.."ids"] and generalconfig["cond"..i.."ids"] ~= "" then
--                    local relationdata = Split(generalconfig["cond"..i.."ids"],";")
--
--                    relations2[i] = {name = generalconfig["cond"..i.."name"],has = 0,total = #relationdata}
--                    for k,v in pairs(relationdata) do
--                        if relations[tonumber(v)] then
--                            table.insert(relations[tonumber(v)],i)
--                        else
--                            relations[tonumber(v)] = {i}
--                        end
--
--                    end
--                end
--            end
--        end
--
--        for kk,slot in pairs(gamedata.cache.slots) do
--            if slot.general and slot.general ~= 0 then
--                local slotsgeneral = gamedata.cache.generals[slot.general]
--                if slotsgeneral and slotsgeneral.cid ~= (exceptCID or 0) then
--                    if relations[slotsgeneral.cid] then
--                        for k,v in ipairs(relations[slotsgeneral.cid]) do
--                            relations2[v].has = relations2[v].has+1
--                        end
--                    end
--                end
--            end
--        end
--
--        local relationnum = 0
--        local hasrelation = {}
--        for k,v in pairs(relations2) do
--            if v.has >= v.total then
--                relationnum = relationnum + v.total
--                table.insert(hasrelation,v.name)
--            end
--        end
--
--        v.hasrelation = next(hasrelation) and hasrelation or nil
--        v.relationnum = relationnum
--    end

    gamedata.sortData(offgenerals,"relationnum","quality","level2", "level1","cid")
end


function addGodCompetitionGeneralRelation(offgenerals,team_id,type,exceptCID)
    exceptCID = exceptCID or 0
    team_id = team_id or 1

    local slotgeneral = {}
    local relations = {}

    if gamedata.cache.godCompetionData then
        local cacheSlots = gamedata.cache.godCompetionData[tonumber(team_id)].slot_General.general
        printT(cacheSlots)
        for i=1,7 do
            local _general =  cacheSlots[i]
            if _general and _general.general then
                print("addGodCompetitionGeneralRelation 1")
                addonegeneralrelation(relations, _general.general.iid,exceptCID)
            end
        end    
        
        printT(relations,"relations_1")

        for kk,vv in ipairs(offgenerals) do

            local relations_ = table.copy(relations)
            if type and type == "slot" then
                addonegeneralrelation(relations_,vv.iid)
            end
    
            for i=1,7 do
                local _general =  cacheSlots[i]
                if _general and _general.general then
                    print("addGodCompetitionGeneralRelation 2")
                    fillrelaition(relations_,_general.general.iid,exceptCID)
                end
            end    
                

            local  cacheCheers = gamedata.cache.godCompetionData[tonumber(team_id)].cheer_General
            for kk,cheer in pairs(cacheCheers) do
                if cheer.general and cheer.general and  cheer.general.iid then
                    print("addGodCompetitionGeneralRelation 3")

                    fillrelaition(relations_,cheer.general.iid,exceptCID)
                end
            end
    
            for k,v in pairs(relations_) do
                if v.has >= #v.relationdata then
                    local checkstring = string.sub(k,1,-2)
                    --if string.find(k,gamedata.config.general[tostring(vv.cid)].name) then
                    if checkstring == gamedata.config.general[tostring(vv.cid)].name then
                    else
                        relations_[k]=nil
                    end
                end
            end
    
            fillrelaition(relations_,vv.iid)
    
            local activerelation = {}
    
            for k,v in pairs(relations_) do
                if v.has >= #v.relationdata then
                    table.insert(activerelation,v.name)
                end
            end
            -- printT(relations_,gamedata.config.general[tostring(vv.cid)].name.."relations_2")
    
            vv.hasrelation = next(activerelation) and activerelation or nil
            vv.relationnum = #activerelation
        end
    end   
    gamedata.sortData(offgenerals,"relationnum","quality","level2", "level1","cid")
end


function makeOffGenerals(GeneralTemp)

    local offgenerals = {}
    for k,v in pairs(GeneralTemp or makeAllGeneralsTemp()) do
        if  not v.ison or v.ison == 0 then
            table.insert(offgenerals,v)
        end
    end
    gamedata.sortData(offgenerals, "quality", "level1", "level2","cid")

    return offgenerals
end

function makeOnGenerals()
    local onGenerals = {}
    for k,v in pairs(makeAllGeneralsTemp()) do
        if v.ison and v.ison >= 1 then
            table.insert(onGenerals,v)
        end
    end
    return onGenerals
end


--选择上阵武将/助阵小伙伴, 3个阵容,在阵武将可以互相交换位置
--team_id 当前阵容id
--isGeneral 为true表示 ,筛选的是要上阵武将, false表示筛选的是要上助阵位
function makeOffGodCompetitionGeneralsWithoutExpGeneral(team_id,isGeneral)
    local offgenerals = {}
    for k,v in pairs(makeAllGodCompetitionGeneralsTemp(team_id,isGeneral)) do
        if  gamedata.config.general[tostring(v.cid)].battle and  gamedata.config.general[tostring(v.cid)].battle ==1  then
              --判断原角色是否在阵
            print("makeOffGodCompetitionGeneralsWithoutExpGeneral enter")
            local ison = false
            if isGeneral then
                if  v.ison and v.ison == 10 then --在助阵的
                    ison = true
                elseif  v.ison and v.ison == (20+tonumber(team_id))  then --在本阵容的   
                    ison = true  
                end    
            else
                if  v.ison and v.ison > 0 then --在阵位的所有
                    ison = true
                end      
            end    

              --有幻化关系 判断幻影是否与在阵的伙伴cid相同
            if v.illusionGeneralCid then
                local cacheSlots =  gamedata.cache.godCompetionData[tonumber(team_id)].slot_General.general
                for i=1,7 do
                    local _general =  cacheSlots[i]
                    if _general and _general.general then
                        if  gamedata.getOriginCid(_general.general.cid) == gamedata.getOriginCid(v.illusionGeneralCid) then
                            print("makeOffGodCompetitionGeneralsWithoutExpGeneral 幻化 1")
                            ison = true
                            break
                        end
                    end
                end    


                if not ison then
                    local  cacheCheers = gamedata.cache.godCompetionData[tonumber(team_id)].cheer_General
                    for kk,cheer in pairs(cacheCheers) do
                        if cheer.general and cheer.general and  cheer.general.iid then
                            print("makeOffGodCompetitionGeneralsWithoutExpGeneral 幻化 2")
                            if gamedata.getOriginCid(cheer.general.cid) == gamedata.getOriginCid(v.illusionGeneralCid) then
                                ison = true
                                break
                            end

                        end
                    end
                end

            else
                --没有幻化关系 判断在阵的伙伴cid是否有幻影cid 相同
                local cacheSlots =  gamedata.cache.godCompetionData[tonumber(team_id)].slot_General.general
                for i=1,7 do
                    local _general =  cacheSlots[i]
                    if _general and _general.general then
                        if _general and _general.general.illusionGeneralCid and gamedata.getOriginCid(v.cid) == gamedata.getOriginCid(_general.general.illusionGeneralCid) then
                            print("makeOffGodCompetitionGeneralsWithoutExpGeneral 幻化 3")
                            ison = true
                            break
                        end

                    end
                end    


                if not ison then
                    local  cacheCheers = gamedata.cache.godCompetionData[tonumber(team_id)].cheer_General
                    for kk,cheer in pairs(cacheCheers) do
                        if cheer.general and cheer.general and  cheer.general.iid then
                            print("makeOffGodCompetitionGeneralsWithoutExpGeneral 幻化 4")
                            if cheer.general and cheer.general.illusionGeneralCid and gamedata.getOriginCid(v.cid) == gamedata.getOriginCid(cheer.general.illusionGeneralCid) then
                                ison = true
                                break
                            end

                        end
                    end
                end

            end

            if not ison then
                table.insert(offgenerals,v)
            end
            
        end
    end
    gamedata.sortData(offgenerals, "quality", "basic","cid")

    return offgenerals
end



function makeOffGeneralsWithoutExpGeneral()

    local offgenerals = {}
    for k,v in pairs(makeAllGeneralsTemp()) do

        if (not v.ison or v.ison == 0)  and (gamedata.config.general[tostring(v.cid)].battle and  gamedata.config.general[tostring(v.cid)].battle ==1)  then
            --判断原角色是否在阵

            local ison = false
            --有幻化关系 判断幻影是否与在阵的伙伴cid相同
            if v.illusionGeneralCid then
                for k2,v2 in pairs(gamedata.cache.slots) do
                    local general = gamedata.cache.generals[v2.general]


                    if general and gamedata.getOriginCid(general.cid) == gamedata.getOriginCid(v.illusionGeneralCid) then
                        ison = true
                        break
                    end
                end

                if not ison then
                    for k2,v2 in pairs(gamedata.cache.cheers) do
                        local general = gamedata.cache.generals[v2.general]
                        if general and gamedata.getOriginCid(general.cid) == gamedata.getOriginCid(v.illusionGeneralCid) then
                            ison = true
                            break
                        end
                    end
                end
            else
                --没有幻化关系 判断在阵的伙伴cid是否有幻影cid 相同
                for k2,v2 in pairs(gamedata.cache.slots) do
                    local general = gamedata.cache.generals[v2.general]
                    if general and general.illusionGeneralCid and gamedata.getOriginCid(v.cid) == gamedata.getOriginCid(general.illusionGeneralCid) then
                        ison = true
                        break
                    end
                end

                if not ison then
                    for k2,v2 in pairs(gamedata.cache.cheers) do
                        local general = gamedata.cache.generals[v2.general]
                            if general and general.illusionGeneralCid and gamedata.getOriginCid(v.cid) == gamedata.getOriginCid(general.illusionGeneralCid) then
                            ison = true
                            break
                        end
                    end
                end
            end

            if not ison then
                table.insert(offgenerals,v)
            end
            
        end
    end
    gamedata.sortData(offgenerals, "quality", "basic","cid")

    return offgenerals
end

local function makeInheritSelectGenerals(iid)

    local generals = {}
    for k,v in pairs(makeAllGeneralsTemp()) do
        if (v.level1 > 1 or v.exp > 0) and v.iid ~= iid and (not v.ison or v.ison==0 )then
            table.insert(generals,v)
        end
    end
    gamedata.sortData(generals, "quality", "level1", "level2","cid")

    return generals
end

local function findSuit(equips,iids)
    local suits = {}
    for k,v in ipairs(iids) do
        if v~=0 then
            local config = gamedata.config.equip[tostring(equips[v].cid)]
            if config.suit and config.suit ~=0 then
                if not suits[config.suit] then
                    suits[config.suit] = {}
                end
                suits[config.suit][equips[v].cid] = v
            end
        end
    end
    printT(suits,"jkp-suits")
    for k,v in pairs(suits) do
        for kk,vv in pairs(v) do
            equips[vv].suit = v
        end
    end

    local suitstage = {}
    for k,v in ipairs(iids) do
        if v~=0 then
            local config = gamedata.config.equip[tostring(equips[v].cid)]
            if config.suit and config.suit ~=0 then
                if not suitstage[config.suit] then
                    suitstage[config.suit] = {}
                end
                suitstage[config.suit][v] = {cid = equips[v].cid,level2 = equips[v].level2,quality = equips[v].quality}
            end
        end
    end
    printT(suitstage,"jkp-suitstage")
    for k,v in pairs(suitstage) do
        for kk,vv in pairs(v) do
            -- printT(v)
            equips[kk].suitstage = v
            -- printT(equips[kk])
        end
    end

end

local function findTreasureRefineNeedNum(equips)
    -- printT(gamedata.cache.generals)
    -- print("checkaaa====")
    
    -- printT(gamedata.cache.protagonist)
    -- print("checkbbbb====")
    -- printT(gamedata.cache.slots)
    local allnums  = {}
    for k,v in pairs(equips) do
        if v.type == "treasure" or v.type == "horse" then
            if v.generalcid and v.generalcid ~= 0 then
                -- print("generalcid000===",v.generalcid)

                for ai,av in ipairs(gamedata.cache.slots) do
                    -- print("slots..iid==",av.general,gamedata.cache.protagonist.general.iid,v.generalcid,gamedata.cache.protagonist.general.cid)

                    if av.general == gamedata.cache.protagonist.general.iid then
                        -- print("i...am...general")
                        if v.generalcid == gamedata.cache.protagonist.general.cid then
                            if v.type == "treasure" then
                                local otherType = "horse"
                                local otheriid = av.horse
                                local othercid = 0
                                if otheriid ~= 0 then
                                    othercid = gamedata.cache.equips[tonumber(av.horse)]["cid"]
                                end
                                v.anotherTreasure = {type = otherType,iid = otheriid,cid = othercid}

                            else
                                local otherType = "treasure"
                                local otheriid = av.treasure
                                local othercid = 0
                                if otheriid ~= 0 then
                                    othercid = gamedata.cache.equips[tonumber(av.treasure)]["cid"]
                                end
                                v.anotherTreasure = {type = otherType,iid = otheriid,cid = othercid}
                            end
                            -- print("generalposition===")
                            -- printT(v)

                            break
                        end
                        
                    elseif tonumber(gamedata.cache.generals[tonumber(av.general)]["cid"]) == tonumber(v.generalcid) then
                        -- print("generalcid111===",v.generalcid)
                        if v.type == "treasure" then
                            local otherType = "horse"
                            local otheriid = av.horse
                            local othercid = 0
                            if otheriid ~= 0 then
                                othercid = gamedata.cache.equips[tonumber(av.horse)]["cid"]
                            end
                            v.anotherTreasure = {type = otherType,iid = otheriid,cid = othercid}

                        else
                            local otherType = "treasure"
                            local otheriid = av.treasure
                            local othercid = 0
                            if otheriid ~= 0 then
                                othercid = gamedata.cache.equips[tonumber(av.treasure)]["cid"]
                            end
                            v.anotherTreasure = {type = otherType,iid = otheriid,cid = othercid}
                        end
                        -- print("somesomesome000===")
                        -- printT(v)
                        break
                    end

                end
            else
                if not allnums[v.cid] then
                    allnums[v.cid] = {}
                end
                table.insert(allnums[v.cid],v.iid)
            end
        end
    end

    -- printT(equips)
    -- print("check====")

    for k,v in pairs(equips) do
        if v.type == "treasure" or v.type == "horse" then
            v.allnum =  allnums[v.cid]
        end
    end
end


function makeEquipsTemp()
    local equips = table.copy(gamedata.cache.equips)

    for k,v in pairs(gamedata.cache.slots) do
        addGeneralName(equips,v.weapon,v.general)
        addGeneralName(equips,v.armor,v.general)
        addGeneralName(equips,v.accessory,v.general)
        addGeneralName(equips,v.head,v.general)
        addGeneralName(equips,v.treasure,v.general)
        addGeneralName(equips,v.horse,v.general)

        findSuit(equips,{v.weapon,v.armor,v.accessory,v.head})
    end

    findTreasureRefineNeedNum(equips)
    return equips
end

local function makeEquipsByTypeAll(EquipTemp)
    local equips = {
        equips = {},
        weapon = {},
        armor = {},
        accessory = {},
        head = {},
        treasures = {},
        treasure = {},
        horse = {},
    }
    for k,v in pairs(EquipTemp or makeEquipsTemp()) do
        if v.type ~= "treasure" and v.type ~= "horse" then
            table.insert(equips.equips,v)
        else
            table.insert(equips.treasures,v)
        end
        table.insert(equips[v.type],v)
    end
    for k,v in pairs(equips) do
        gamedata.sortData(v, "ison", "quality", "level1", "level2", "level3", "cid")
    end
    return equips
end

local function makeEquipsAndTreasures()
    local equips = {}
    for k,v in pairs(makeEquipsTemp()) do
        table.insert(equips,v)
    end
    gamedata.sortData(equips, "quality", "level1", "level2", "level3", "cid")
    return equips
end

local function makeEquips()
    local equips = {}
    for k,v in pairs(makeEquipsTemp()) do
        if v.type ~= "treasure" and v.type ~= "horse" then
            table.insert(equips,v)
        end
    end
    gamedata.sortData(equips, "ison","quality", "level1", "level2", "level3", "cid")
    return equips
end

local function makeCanStageEquips()
    local equips = {}

    -- print("makeCanStageEquips")
    for k,v in pairs(makeEquipsTemp()) do
        local equipconfig = gamedata.config.equip[tostring(v.cid)]
        if tonumber(equipconfig.evolve) == 1 then
            table.insert(equips,v)
        end
    end
    -- printT(equips)
    gamedata.sortData(equips, "ison","quality", "level2", "level1", "level3", "cid")
    -- printT(equips)
    return equips
end

local function makeOnEquipsForSlot()
    local slots = table.copy(gamedata.cache.slots)
    local onSlotEquips = {}
    local _leaderSid = 1

    for k,v in pairs(slots) do
        if not gamedata.cache.generals[v.general] or v.general == gamedata.cache.protagonist.iid then 
            _leaderSid = v.sid
            break
        end
    end

    for k,v in pairs(slots) do
        --if not onSlotEquips[v.sid] then onSlotEquips[v.sid] = {} end
        local general = {}
        local equips = {}
        
        for k1, v1 in pairs(v) do
            if not gamedata.cache.generals[v.general] or v.general == gamedata.cache.protagonist.iid then 
                general.cid = gamedata.cache.protagonist.general.cid
            else
                general.cid = gamedata.cache.generals[v.general].cid
            end
            general.iid = v.general
            
            equips.weapon = makeEquipsWithIID(v.weapon)
            equips.head = makeEquipsWithIID(v.head)
            equips.armor = makeEquipsWithIID(v.armor)
            equips.accessory = makeEquipsWithIID(v.accessory)
        end

        if v.sid == _leaderSid then
            if not onSlotEquips[1] then onSlotEquips[1] = {} end
            onSlotEquips[1].general = general
            onSlotEquips[1].equips = equips
            onSlotEquips[1].sid = v.sid
        elseif v.sid < _leaderSid then
            if not onSlotEquips[v.sid + 1] then onSlotEquips[v.sid + 1] = {} end
            onSlotEquips[v.sid + 1].general = general
            onSlotEquips[v.sid + 1].equips = equips
            onSlotEquips[v.sid + 1].sid = v.sid
        else
            if not onSlotEquips[v.sid] then onSlotEquips[v.sid] = {} end
            onSlotEquips[v.sid].general = general
            onSlotEquips[v.sid].equips = equips
            onSlotEquips[v.sid].sid = v.sid
        end
    end

    printT(onSlotEquips, "yyz  阵容装备")

    return onSlotEquips
end

function makeEquipsWithIID(param)
    local data = {}

    if param ~= 0 then 
        data = gamedata.cache.equips[param]
    end
    
    return data
end

function makeTreasure()
    local Treasure = {}
    for k,v in pairs(makeEquipsTemp()) do
        if v.type == "treasure" or v.type == "horse" then
            table.insert(Treasure,v)
        end
    end
    gamedata.sortData(Treasure, "ison","quality", "level1", "level2", "level3", "cid")
    return Treasure
end

local function makeOffEquip(EquipTemp)
    local OffEquip = {}
    for k,v in pairs(EquipTemp or makeEquipsTemp()) do
        if v.type ~= "treasure" and v.type ~= "horse" then
            if not v.ison or v.ison == 0 then
                table.insert(OffEquip,v)
            end
        end
    end
    gamedata.sortData(OffEquip, "quality", "level1", "level2", "level3", "cid")
    return OffEquip
end

function makeSpendEquipByCid(cid)
    local num = 0
    for k,v in pairs(makeOffEquip()) do
        if tonumber(v.cid) == tonumber(cid) and tonumber(v.level1) == 1 and tonumber(v.level2) == 0 and tonumber(v.xcount) == 0 and tonumber(v.level3) == 0 then
            -- print("makeSpendEquipByCid==",cid)
            -- printT(v)
            num = num + 1
        end
    end
    return num
end


local function makeOffTreasure(EquipTemp)
    local OffTreasure = {}
    for k,v in pairs(EquipTemp or makeEquipsTemp()) do
        if v.type == "treasure" or v.type == "horse" then
            if not v.ison or v.ison == 0 then
                table.insert(OffTreasure,v)
            end
        end
    end
    gamedata.sortData(OffTreasure, "quality", "level1", "level2", "level3", "cid")
    return OffTreasure
end

local function makeEquipsByType(type)
    local equips = {}
    for k,v in pairs(makeEquipsTemp()) do
        if v.type == type then
            table.insert(equips,v)
        end
    end
    gamedata.sortData(equips, "ison", "quality", "level1", "level2", "level3", "cid")
    return equips
end


local function makeOffEquipByType(type)
    local OffEquip = {}
    for k,v in pairs(makeEquipsTemp()) do
        if gamedata.config.equip[tostring(v.cid)].type == type and (not v.ison or v.ison == 0) then
            table.insert(OffEquip,v)
        end
    end
    gamedata.sortData(OffEquip, "quality", "level1", "level2", "level3", "cid")
    return OffEquip
end

local function makeSelectEquipByType(type, param)
    local OffEquip = {}
    for k,v in pairs(makeEquipsTemp()) do
        if gamedata.config.equip[tostring(v.cid)].type == type and v.iid ~= param.equipiid then
            local cid = 0
            if not gamedata.cache.generals[gamedata.cache.slots[param.sid].general] or gamedata.cache.slots[param.sid].general == gamedata.cache.protagonist.iid then
                cid = gamedata.cache.protagonist.general.cid
            else
                cid = gamedata.cache.generals[gamedata.cache.slots[param.sid].general].cid
            end
            if EquipGeneral_related(v.cid,cid) then
                v.youyuan = 1
            end
            v.adorn = gamedata.config.equip[tostring(v.cid)].adorn
            table.insert(OffEquip,v)
        end
    end
    if type ~= "horse" and type ~= "treasure"  then
        gamedata.sortData(OffEquip, "quality","ison","youyuan", "level1",nil,nil,false,true,false,false,false)
    else
        local sortFunc = function(a,b)
            if  a.adorn > b.adorn  then
                return true
            elseif a.adorn < b.adorn  then
                return false
            elseif a.adorn ==  b.adorn  then
                if (a.quality or 0) > (b.quality or 0) then
                    return true
                elseif (a.quality or 0) < (b.quality or 0) then
                    return false
                elseif (a.quality or 0) == (b.quality or 0) then
                    if (a.ison or 0) > (b.ison or 0) then
                        return false
                    elseif (a.ison or 0) < (b.ison or 0) then
                        return true
                    elseif (a.ison  or 0) == (b.ison  or 0) then
                        if (a.youyuan or 0) > (b.youyuan or 0) then
                            return true
                        elseif (a.youyuan or 0) < (b.youyuan or 0) then
                            return false
                        elseif (a.youyuan or 0) == (b.youyuan or 0) then
                            if (a.level1 or 0) > (b.level1 or 0) then
                                return true
                            elseif (a.level1 or 0) < (b.level1 or 0) then
                                return false
                            elseif (a.level1 or 0) == (b.level1 or 0) then
                                if (a.level3 or 0) > (b.level3 or 0) then
                                    return true
                                elseif (a.level3 or 0) <= (b.level3 or 0) then
                                    return false
                                end
                            end
                        end
                    end
                end            
            end
        end 
        table.sort(OffEquip,sortFunc)       
    end
    return OffEquip
end

local function makeSoulsTemp()
    local souls = table.copy(gamedata.cache.souls)

    for k,v in pairs(gamedata.cache.slots) do
        addGeneralName(souls,v.s1,v.general)
        addGeneralName(souls,v.s2,v.general)
        addGeneralName(souls,v.s3,v.general)
        addGeneralName(souls,v.s4,v.general)
        addGeneralName(souls,v.s5,v.general)
        addGeneralName(souls,v.s6,v.general)
        addGeneralName(souls,v.s7,v.general)
        addGeneralName(souls,v.s8,v.general)
    end
    return souls
end

local function makeSouls()
    local souls = {}
    for k,v in pairs(makeSoulsTemp()) do
        local config = gamedata.config.soul[tostring(v.cid)] or {}
        table.insert(souls,v)
    end
    gamedata.sortData(souls, "ison","evaluate","cid")
    return souls
end

local function makeSoulsForNotice()
    local souls = {}
    for k,v in pairs(makeSoulsTemp()) do
        table.insert(souls,v)
    end
    gamedata.sortData(souls,"evaluate","cid")
    return souls
end

local function makeSoulsByQuality(quality)
    local souls = {}
    for k,v in pairs(makeSoulsTemp()) do
        if v.quality == quality then
            local config = gamedata.config.soul[tostring(v.cid)] or {}
            table.insert(souls,v)
        end
    end
    gamedata.sortData(souls, "ison","evaluate","cid")
    return souls
end

local function makeSoulsByQualityAll()
    local souls = {
        all = {},
        souls2 = {},
        souls3 = {},
        souls4 = {},
        souls5 = {},

    }
    for k,v in pairs(makeSoulsTemp()) do
        local config = gamedata.config.soul[tostring(v.cid)] or {}

        table.insert(souls.all,v)
        table.insert(souls["souls"..v.quality],v)
    end
    for k,v in pairs(souls) do
        gamedata.sortData(v, "ison","evaluate","cid")
    end

    return souls
end

local function makeOffSouls()
    local souls = {}
    for k,v in pairs(makeSoulsTemp()) do
        if not v.ison or v.ison == 0 then
            local config = gamedata.config.soul[tostring(v.cid)] or {}
            table.insert(souls,v)
        end
    end
    gamedata.sortData(souls, "evaluate","cid")
    return souls
end

local function findRelatedEquip(generalcid,equipiid,type,equipTemp)

    local has = nil
    for k,v in pairs(equipTemp) do
        if v.iid ~= (equipiid or 0) and gamedata.config.equip[tostring(v.cid)].type ==  type and (not v.ison or v.ison ~= 1) and EquipGeneral_related(v.cid,generalcid) then
            if not has then has = {} end
            table.insert(has,table.copy(v))
        end
    end

    if has then
        table.sort(has,function(a,b)
            return a.evaluate > b.evaluate
        end)
    end
    return has
end

local function checkTreasureNotice(equip,equipconfig,equipTemp)
    local refineconfig = gamedata.config.treasure2_refine
    local strengthenconfig = gamedata.config.treasure2_strengthen
    local maxlevel2 = gamedata.config.equip[tostring(equip.cid)].maxlevel2 or 9999

    if gamedata.cache.role.level >= gamedata.config.build[tostring(137)].level and equip.level2 < maxlevel2 then
        local xprops = gamedata.getIDandNUMs(refineconfig[tostring(equip.level2+1)]["num"..equipconfig.quality]) or {}
        local cando = true
        for k,v in pairs(xprops) do
            if v.cid == 1000 then
                if gamedata.cache.role.coin < v.num then
                    cando = false
                    break
                end
            else
                if not gamedata.cache.props[v.cid] or gamedata.cache.props[v.cid].num < v.num then
                    cando = false
                    break
                end
            end
        end

        if cando then
            local spendselfNum = refineconfig[tostring(equip.level2+1)]["oneself"..equipconfig.quality]
            if not equip.allnum or #equip.allnum < spendselfNum then
                cando = false
            end
        end

        if cando then return "up2" end
    end
    if gamedata.cache.role.level >= gamedata.config.build[tostring(142)].level and equip.level1 < table.getTableLength(strengthenconfig) and equip.level1 < gamedata.cache.role.level then
        
        local xprops = equip.type == "horse" and {26407,26408,26409,26413} or {26410,26411,26412,26414}
        for k,v in ipairs(xprops) do
            if gamedata.cache.props[v] and gamedata.cache.props[v].num>0 then
                local propconfig = gamedata.config.props[tostring(v)]
                if gamedata.cache.role.coin > tonumber(gamedata.config.global_kv["treasure_strengthen_coin"..propconfig.quality].value) then
                    return "up3"
                end
            end
        end

        for k,v in pairs(equipTemp) do
            local config = gamedata.config.equip[tostring(v.cid)]
            if config.adorn == 1 and v.quality >= 5 then
            elseif equip.type == v.type and (not v.ison or v.ison == 0) and v.level2==0 and gamedata.cache.role.coin > tonumber(gamedata.config.global_kv["treasure_strengthen_coin"..v.quality].value) then
                return "up3"
            end
        end
    end

    return nil
end

local function addEquipNoticeForHint(equip,equips)
    local equipconfig = gamedata.config.equip[tostring(equip.cid)]
    if equip.has then return true end
    if equip.notice then
        if equip.notice == "up3" then
            if equipconfig.type == "horse" or equipconfig.type == "treasure" then
                local expconfig = gamedata.config.treasure2_strengthen

                local expneed = expconfig[tostring(equip.level1+1)]["quality"..equipconfig.quality]
                local exphas = 0

                for k,v in pairs(equips) do
                    if (not v.ison or v.ison == 0) and v.level2==0 then
                        local exp = 0
                        for i = 1,v.level1 do
                            exp = exp + expconfig[tostring(i)]["quality"..v.quality]
                        end
                        exphas = exphas + (gamedata.config.equip[tostring(v.cid)].exp or 0) + exp
                    end

                end
                if exphas + (equip.exp or 0) >= expneed then
                    return true
                end

            else
                if gamedata.config.equip_strengthen[tostring(equip.level1)]["quality"..equip.quality]*10 <= gamedata.cache.role.coin then
                    return true
                end
            end
        elseif equip.notice == "up6" then
            if gamedata.cache.props[20222] and gamedata.cache.props[20222].num >=20 then
                return true
            end
        else
            return true
        end
    end

    return false
end

local function checkEquipNotice(equip,equipconfig)
    -------------进阶begin--------------
    --[[
    --进阶提示条件为等级大于配置等级 且品质有要求 TODO：：确认品质需求
    if gamedata.config.build[tostring(150)] and gamedata.cache.role.level >= gamedata.config.build[tostring(150)].level then
        local cando_ = true
        local info = gamedata.config.equip_evolveconsume[tostring(equip.cid)]
        local consume1 = info and info["consume"..(equip.level2 + 1)] or {}
        local consume = gamedata.getIDandNUMs(tostring(consume1))

        local needequip1 = info and info["equip"..(equip.level2 + 1)] or {}
        local needequip = gamedata.getIDandNUMs(tostring(needequip1))
        
        if table.getTableLength(consume) == 0 and table.getTableLength(needequip) == 0 then
            cando_ = false
        else
            --需要的材料
            for i,v in ipairs(consume) do
                if v.cid == 1000 then
                    if (tonumber(gamedata.cache.role.coin) < tonumber(v.num)) then
                        cando_ = false
                        break
                    end
                elseif v.cid == 1001 then
                    if gamedata.cache.role.gold < v.num then
                        cando_ = false
                        break
                    end
                elseif gamedata.cache.props[tonumber(v.cid)] == nil or (gamedata.cache.props[tonumber(v.cid)] and tonumber(gamedata.cache.props[tonumber(v.cid)].num) < tonumber(v.num)) then
                    cando_ = false
                    break
                end
            end
            --需要的装备
            for i,v in ipairs(needequip) do
                local num = 0
                local equip = makeOffEquip()
                for k1, v1 in pairs(equip) do
                    if (v1.cid == v.cid and v1.level1 == 1 and v1.level2 == 0 and v1.level3 == 0 and v1.level4 == 0) then
                        num = num + 1
                    end
                end
                if (num < v.num) then
                    cando_ = false
                    break
                end
            end
            if cando_ then
                return "gold"
            end 
        end
    end
    ]]
    -------------进阶end--------------
    if gamedata.config.build[tostring(199)] and gamedata.cache.role.level >= gamedata.config.build[tostring(199)].level and equipconfig.up_star and equip.level3 and equipconfig.up_star ~= 0 and equip.level3 < equipconfig.up_star then
        local equipstarconfig = gamedata.config.equip_star or {}
        local spenddata = equipstarconfig[tostring(equip.level3+1)]["cost_"..equip.quality] or {}
        local spengtemp = {}
        local cando_ = true
        spengtemp = gamedata.getIDandNUMs(spenddata)
        for i,v in ipairs(spengtemp) do
            if v.cid == 1000 then
                if (tonumber(gamedata.cache.role.coin) < tonumber(v.num)) then
                    
                    cando_ = false
                    break
                end
                
            elseif gamedata.cache.props[tonumber(v.cid)] == nil or (gamedata.cache.props[tonumber(v.cid)] and tonumber(gamedata.cache.props[tonumber(v.cid)].num) < tonumber(v.num)) then

                cando_ = false
                break
            end
        end
        if cando_ then
            return "up7"
        end
    end
    ---------------注灵begin------------------
    --[[
    --注灵条件为等级大于配置等级 且品质有要求 TODO：：确认品质需求
    if gamedata.config.build[tostring(384)] and gamedata.cache.role.level >= gamedata.config.build[tostring(384)].level then
        local cando_ = true
        local upconfig = gamedata.config.equip_forgingConsume[tostring(equip.level4 + 1)]
        local spenddata = upconfig and upconfig["quality"..equipconfig.quality] or {}
        local consume = gamedata.getIDandNUMs(spenddata)
        
        if table.getTableLength(consume) == 0 then
            cando_ = false
        else
            --需要的材料
            for i,v in ipairs(consume) do
                if v.cid == 1000 then
                    if (tonumber(gamedata.cache.role.coin) < tonumber(v.num)) then
                        cando_ = false
                        break
                    end
                elseif v.cid == 1001 then
                    if gamedata.cache.role.gold < v.num then
                        cando_ = false
                        break
                    end
                elseif gamedata.cache.props[tonumber(v.cid)] == nil or (gamedata.cache.props[tonumber(v.cid)] and tonumber(gamedata.cache.props[tonumber(v.cid)].num) < tonumber(v.num)) then
                    cando_ = false
                    break
                end
            end
        
            if cando_ then
                return "qian"
            end
        end
         
    end
    ]]
    -------------注灵end--------------
    if equip.level1 < gamedata.cache.role.level*tonumber(gamedata.config.global_kv.equip_level.value)
            and gamedata.config.equip_strengthen[tostring(equip.level1)]["quality"..equip.quality] <= gamedata.cache.role.coin
            and equip.level1 < (equipconfig.maxlevel and equipconfig.maxlevel+0 or 0)
    then
        return "up3"
    end

    if gamedata.cache.role.level >= gamedata.config.build[tostring(53)].level and equipconfig.quality >2 then
        local cando = false
        for i = 1,4 do
            if (equip["x"..equipconfig["baptize_attr"..i]] or 0) <equipconfig["attrlimitup_"..i]*(equip.level1-1)+equipconfig["attrlimit"..i] then
                cando = true
            end
        end
        if not cando then return nil end

        local cando = false
        for i = 1,3 do
            --
            local xprop = gamedata.getIDandNUMs(tostring(gamedata.config.global_kv["baptize_consume_"..i].value))
            local cando_ = true
            for k,v in pairs(xprop) do
                if v.cid == 1000 then
                    if gamedata.cache.role.coin < v.num then
                        cando_ = false
                        break
                    end
                elseif v.cid == 1001 then
                    if gamedata.cache.role.gold < v.num then
                        cando_ = false
                        break
                    end
                elseif v.cid == 20222 then
                    if not gamedata.cache.props[20222] or gamedata.cache.props[20222].num < v.num then
                        cando_ = false
                        break
                    end
                end
            end

            if cando_ then
                cando = true
                return "up6"
            end
        end
    end

    return nil
end


local function addEquipNotice(equipt,general,type, equipTemp,offequiptype)
    offequiptype = offequiptype or {}
    local equip = table.copy(equipt or {})
    local equipconfig = gamedata.config.equip[tostring(equip.cid)]

    equip.changeiid = nil

    if equip.iid then
        equip.suit = equipTemp[equip.iid].suit
        equip.suitstage = equipTemp[equip.iid].suitstage
        equip.allnum = equipTemp[equip.iid].allnum
    end

    local relatedEquip = findRelatedEquip(general.cid,equip.iid,type,offequiptype)    

    if not equipt then
        equip.has = #offequiptype > 0 and true or nil
        equip.changeiid = relatedEquip and relatedEquip[1].iid or (offequiptype[1] and offequiptype[1].iid or nil)
        return equip
    end


    if equipconfig.type == "horse" or equipconfig.type == "treasure" then
        if (not EquipGeneral_related(equip.cid,general.cid)) then
            if relatedEquip then
                equip.notice = "yuan"
                equip.changeiid = relatedEquip[1].iid
                return equip
            else
                if offequiptype[1] and offequiptype[1].evaluate>equip.evaluate then
                    equip.notice = "change"
                    equip.changeiid = offequiptype[1].iid
                    return equip 
                end
            end
        else
            if relatedEquip then
                if relatedEquip[1] and relatedEquip[1].evaluate>equip.evaluate then
                    equip.notice = "change"
                    equip.changeiid = relatedEquip[1].iid
                    return equip 
                end
            end
        end

        equip.notice = checkTreasureNotice(equip,equipconfig,offequiptype)
    else
        if (not EquipGeneral_related(equip.cid,general.cid)) then
            if relatedEquip then
                equip.notice = "yuan"
                equip.changeiid = relatedEquip[1].iid
                return equip
            else
                if offequiptype[1] and offequiptype[1].evaluate>equip.evaluate then
                    equip.notice = "change"
                    equip.changeiid = offequiptype[1].iid
                    return equip 
                end
            end
        else
            if relatedEquip then
                if relatedEquip[1] and relatedEquip[1].evaluate>equip.evaluate then
                    equip.notice = "change"
                    equip.changeiid = relatedEquip[1].iid
                    return equip 
                end
            end
        end

        equip.notice = checkEquipNotice(equip,equipconfig)

    end
    return equip
end

local function addEquipNoticeChange(equipTemp,slotdata)
    local notices = {}
    for k,v in pairs(equipTemp) do
         if equipTemp[slotdata[v.type]] and v.type == equipTemp[slotdata[v.type]].type and (not v.ison or v.ison ==0) and v.quality > equipTemp[slotdata[v.type]].quality and v.iid ~= slotdata[v.type] then
             notices[v.type] = true
         end
    end

    if equipTemp[slotdata.weapon] and table.getTableLength(equipTemp[slotdata.weapon].suit) >=4 then
        if  table.getTableLength(notices) >= 2 then
            return notices
        else
            return {}
        end
    else
        return notices
    end
end

local function findSoulTypeTbySid( sid,soulpos )
    local typet = {}

    for i= 1,8 do
        local souliid = gamedata.cache.slots[sid]["s"..i]
        if i~= soulpos and souliid and souliid~=0 then
            local cid =  gamedata.cache.souls[souliid].cid
            local config = gamedata.config.soul[tostring(cid)]
            typet[config.attr1..config.method1] = true
            if config.attr2 and config.attr2 ~= "" then
                typet[config.attr2..config.method2] = true
            end
        end
    end

    return typet
end

local function addSoulNotice(soul)
    local config = gamedata.config.soul[tostring(soul.cid)]

    if gamedata.cache.props[20099] and gamedata.cache.props[20099].num >= config.upexp*(2^(soul.level-1)) and soul.level< config.limit1 then
        return "up3"
    end
    return nil
end

local function addSkillNotice(generalt)
    local general = table.copy(generalt)

    local quality = tostring(gamedata.config.skill[tostring(gamedata.config.general[tostring(general.cid)].skillid)].quality)
    if general.skill.level < table.getTableLength(gamedata.config.skill_level) then
        if gamedata.cache.props[20046] and gamedata.cache.props[20046].num >= gamedata.config.skill_level[tostring(general.skill.level)][quality.."coin"] then
            general.skill.notice = "up4"
        end
    end
    return general
end

local function isPartOfsuit(equipCid)
    if gamedata.config.equip[tostring(equipCid)].suit and gamedata.config.equip[tostring(equipCid)].suit ~= 0 then
        return  gamedata.config.equip[tostring(equipCid)].suit
    end
    return false
end

function checkQuickStrength(iid)
    print("checkQuickStrength",iid)

    local effectnum = 0
    if gamedata.cache.guildWarProfit and gamedata.cache.guildWarProfit.effect and gamedata.cache.guildWarProfit.effect > 0 then
        effectnum = gamedata.cache.guildWarProfit.effect
    end

    local cando = false
    local des = {type = 503, msg = "所有装备已强化到上限"}

    local has = false
    for k,v in pairs(gamedata.cache.slots) do

        if v.general and v.general == iid then
             for kk,vv in pairs(propconfig) do
                  if kk ~= "horse" and kk ~= "treasure" then
                      if v[kk] and gamedata.cache.equips[v[kk]] then
                          has = true
                          local equip = gamedata.cache.equips[v[kk]]
                          local equipconfig = gamedata.config.equip[tostring(equip.cid)]

                          if equip.level1 < gamedata.cache.role.level*tonumber(gamedata.config.global_kv.equip_level.value) and math.ceil(gamedata.config.equip_strengthen[tostring(equip.level1)]["quality"..equip.quality]*(100-effectnum)/100) <= gamedata.cache.role.coin then
                              cando = true
                              break
                          elseif equip.level1 < gamedata.cache.role.level*tonumber(gamedata.config.global_kv.equip_level.value) then
                              des = {type = 503, msgtype = "shortcoin"}
                          end
                      end
                  end
             end
             break
        end
    end
    if not has then des = {type = 503, msg = "还没有穿戴装备"} end
    return cando, des
end

local function makeChangeSoul(param)
    local typet = findSoulTypeTbySid(param.sid,param.soulpos)

    local souls = {}
    for k,v in pairs(param.checknotice and makeOffSouls() or makeSoulsTemp()) do
        if not param.iid or v.iid~= param.iid then
            local config = gamedata.config.soul[tostring(v.cid)]

            if v.evaluate>0 and (not typet[config.attr1..config.method1]) and (not(config.attr2 and config.attr2 ~= "" and typet[config.attr2..config.method2])) then
                table.insert(souls,v)
            end
        end
    end

    --gamedata.sortData(souls, "quality", "level")

    local sortfunc = function (a,b)

        if  a.generalcid and not b.generalcid then
            return false
        elseif not a.generalcid and b.generalcid then
            return true

        elseif  a.evaluate > b.evaluate  then
            return true
        elseif a.evaluate < b.evaluate then
            return false

        elseif a.evaluate == b.evaluate then
            return a.cid < b.cid
        end

    end

    table.sort(souls,sortfunc)

    return souls
end

local function ishassoul( param,offsouls )
    local typet = findSoulTypeTbySid(param.sid,param.soulpos)
    offsouls = offsouls or makeOffSouls()

    local souls = {}
    for k,v in pairs(offsouls) do
        if not param.iid or v.iid~= param.iid then
            local config = gamedata.config.soul[tostring(v.cid)]
            if v.evaluate>0 and (not typet[config.attr1..config.method1]) and (not(config.attr2 and config.attr2 ~= "" and typet[config.attr2..config.method2])) then
                return true
            end
        end
    end
    return nil
end

local function makeSlotSoulNewIID( general,allsouls,slotdata )

    local sidtypet = {}
    local generalcid = general.cid

    local newlist = {}
    local index = 0
    local keeppos = {}
    for i,new in ipairs(allsouls) do
        if new.ison and new.generalcid ~= generalcid then
        else
            local config = gamedata.config.soul[tostring(new.cid)]

            if (not sidtypet[config.attr1..config.method1]) and (not(config.attr2 and config.attr2 ~= "" and sidtypet[config.attr2..config.method2])) then
                index = index + 1

                local hason = false

                for i=1,8 do
                    local slotiid = slotdata["s"..slotccbconfig[i]]
                    if slotiid == new.iid 
                        or (gamedata.cache.souls[slotiid] and gamedata.cache.souls[slotiid].evaluate == new.evaluate)  then
                        hason = true
                        keeppos["s"..slotccbconfig[i]] = true
                        break
                    end
                end

                if hason then
                else
                    table.insert( newlist, new.iid)
                end

                sidtypet[config.attr1..config.method1] = true
                if config.attr2 and config.attr2 ~= "" then
                    sidtypet[config.attr2..config.method2] = true
                end
            end
            if index>=8 then break end
        end
    end
    return newlist,keeppos
end

local function makeSlotSoul( newlist,keeppos,soulpos,iid,slotdata)


    local data = {soulpos=soulpos}
    if iid==0 then
        if not keeppos["s"..soulpos] and newlist[1] then

            local sidtypet2 = {}
            for i=1,8 do
                local slotiid = slotdata["s"..slotccbconfig[i]]
                if gamedata.cache.souls[slotiid] and gamedata.cache.souls[slotiid].cid and gamedata.cache.souls[slotiid].cid > 0 then
                    local config = gamedata.config:getConfigByName("soul")[tostring(gamedata.cache.souls[slotiid].cid)]
                    sidtypet2[config.attr1..config.method1] = true
                    if config.attr2 and config.attr2 ~= "" then
                        sidtypet2[config.attr2..config.method2] = true
                    end
                end
            end

            local s = gamedata.cache.souls[newlist[1]]
            local config = gamedata.config.soul[tostring(s.cid)]
            if (not sidtypet2[config.attr1..config.method1]) and (not(config.attr2 and config.attr2 ~= "" and sidtypet2[config.attr2..config.method2])) then
                data.has = true 
                data.changeiid = newlist[1]
                data.checknotice = true
            end
            table.remove(newlist,1)
        else
            data.has = nil 
            data.checknotice = true            
        end
    else
        if not keeppos["s"..soulpos] and newlist[1] then
            data.notice = "change"
            data.changeiid = newlist[1]  
            table.remove(newlist,1) 
        else
            data.notice = addSoulNotice(gamedata.cache.souls[iid])         
        end
    end

    local newdata = {}
    if iid ~= 0 then
        newdata = table.merge(gamedata.cache.souls[iid],data)
    else
        newdata = data
    end

    return newdata
end


local socket = require("socket")
local function makeoffequipforslot(temp)
    local offequips = {}


    for k,v in pairs(temp) do
        if not offequips[v.type] then offequips[v.type] = {} end
        if not v.ison or v.ison ==0 then
            table.insert(offequips[v.type],v)
        end
    end

    for k,v in pairs(offequips) do
        table.sort(v,function(a,b)
            return a.evaluate > b.evaluate
        end)
    end
--    printT(offequips)

    return offequips
end

function makeSlotInfo(equipTemp_,offgeneral_,equips_)
    --local t1 = socket.gettime()
    makeGeneralHint()
    local slots = table.copy(gamedata.cache.slots)
    local equipTemp = equipTemp_ or makeEquipsTemp()

    local slotconfig = gamedata.config.role_exp
    local opennum = slotconfig[tostring(gamedata.cache.role.level)].slotnum
    print("opennum",gamedata.cache.role.level,opennum)

    local slothint = false
    local safemaskFeiSheng_hint = false
    local tokenHint = false

    local soulslotconfig = gamedata.config.soulslot
    local offgeneral = offgeneral_ or makeOffGenerals()
    local offequips = makeoffequipforslot(equipTemp)

    local equips = equips_ or makeEquipsByTypeAll(equipTemp)

    local allsouls = makeSoulsForNotice()
    local soulnum = #allsouls
    local _tokenConfig = gamedata.config.token
	local _tokenSuitConfig = gamedata.config.token_suit
	local _tempTokenConfig = {}

	for k,v in pairs(gamedata.config.token) do
		local _id = v.suit
		local _location = v.location

		if not _tempTokenConfig[_id] then
			_tempTokenConfig[_id] = {}
		end

		if not _tempTokenConfig[_id][_location] then
			_tempTokenConfig[_id][_location] = {}
		end

		_tempTokenConfig[_id][_location].id = v.id
		_tempTokenConfig[_id][_location].name = v.name
		_tempTokenConfig[_id][_location].icon = v.icon
		_tempTokenConfig[_id][_location].desc = v.desc
		_tempTokenConfig[_id][_location].cost = gamedata.getIDandNUMs(v.cost)[1]
		_tempTokenConfig[_id][_location].label = v.label
		_tempTokenConfig[_id][_location].recover = v.recover
		_tempTokenConfig[_id][_location].quality = v.quality
		_tempTokenConfig[_id][_location].limit_level = v.limit_level
	end

    for k=1,7 do
        if k<= opennum then
            if slots[k] and slots[k].general and slots[k].general ~= 0 then
                local v = table.copy(slots[k])

                if not gamedata.cache.generals[v.general] or v.general == gamedata.cache.protagonist.iid then
                    slots[k].general = gamedata.cache.protagonist.general
                    slots[k].power =gamedata.cache.protagonist.general.power
                else
                    slots[k].general = gamedata.cache.generals[v.general]
                    slots[k].power = gamedata.cache.generals[v.general].power
                end

                slots[k].weapon = addEquipNotice(equipTemp[v.weapon or 0], slots[k].general, "weapon",equipTemp,offequips.weapon)
                slots[k].armor = addEquipNotice(equipTemp[v.armor or 0], slots[k].general, "armor",equipTemp,offequips.armor)
                slots[k].accessory = addEquipNotice(equipTemp[v.accessory or 0], slots[k].general, "accessory",equipTemp,offequips.accessory)
                slots[k].head = addEquipNotice(equipTemp[v.head or 0], slots[k].general, "head",equipTemp,offequips.head)
                slots[k].treasure = addEquipNotice(equipTemp[v.treasure or 0], slots[k].general, "treasure",equipTemp,offequips.treasure)
                slots[k].horse = addEquipNotice(equipTemp[v.horse or 0], slots[k].general, "horse",equipTemp,offequips.horse)

                local hashint_soul = nil
                local newlist,keeppos = makeSlotSoulNewIID(slots[k].general,allsouls,v)

                for i = 1,8 do
                    if  soulslotconfig[tostring(slotccbconfig[i])].level <= gamedata.cache.role.level then
                        slots[k]["s"..i] = makeSlotSoul(newlist,keeppos,slotccbconfig[i],v["s"..slotccbconfig[i]],v)

                        -- if v["s"..slotccbconfig[i]] and v["s"..slotccbconfig[i]] ~= 0 then
                        --     slots[k]["s"..i] = table.merge(gamedata.cache.souls[v["s"..slotccbconfig[i]]],{soulpos = slotccbconfig[i],notice = addSoulNotice(gamedata.cache.souls[v["s"..slotccbconfig[i]]])})
                        -- else
                        --     slots[k]["s"..i] = {soulpos = slotccbconfig[i], has = ishassoul({sid=k,soulpos = slotccbconfig[i],checknotice = true},offsouls)}
                        -- end
                    else
                        slots[k]["s"..i] = {openlevel = soulslotconfig[tostring(slotccbconfig[i])].level,soulpos = slotccbconfig[i]}
                    end

                    if (slots[k]["s"..i].has or slots[k]["s"..i].notice) and not hashint_soul then
                        hashint_soul = true
                    end
                end

                local hashint_equip = nil

                for kk,vv in pairs(propconfig) do
                    local bool = addEquipNoticeForHint(slots[k][kk],offequips[kk])
                    if bool and not hashint_equip then
                        hashint_equip = true
                        break
                    end
                end

                local hashint_stone = nil
                local propnum = gamedata.cache.props[20223] and gamedata.cache.props[20223].num or 0

                local select = 1
                for i=1,8 do
                    if slots[k]["g"..i] < slots[k]["g1"] then
                        select = i
                        break
                    end
                end
                local key = gamedata.config.godstone[tostring(select)].attribute
                local config = gamedata.config.godstonestrengthening
                if table.getTableLength(config) >= slots[k]["g"..select]+1 then
                    local  nextlevelconfig = config[tostring(slots[k]["g"..select]+1)]
                    if gamedata.cache.role.level >= nextlevelconfig.teamlv and propnum >= nextlevelconfig[key.."_number"] then
                        hashint_stone = true
                    end
                end

                --safemask
                local hashint_safemask = nil
                if gamedata.cache.safemask and gamedata.cache.safemask[tostring(k)] then
                    local safeconfig = gamedata.config.mozhao_break or {}
                    if gamedata.cache.safemask[tostring(k)].level < (table.getTableLength(safeconfig)-1) then
                        local coststr = safeconfig[tostring(gamedata.cache.safemask[tostring(k)].level)].lv_cost or nil
                        local cost = gamedata.getIDandNUMs(coststr)
                        if cost then
                            hashint_safemask = true
                            for k,v in pairs(cost) do
                                if v.cid == 1000 then
                                    if v.num > 0 and gamedata.cache.role.coin < v.num then
                                        hashint_safemask = nil
                                    end
                                elseif v.cid == 1001 then
                                    if v.num > 0 and gamedata.cache.role.gold < v.num then
                                        hashint_safemask = nil
                                    end
                                else
                                    if gamedata.getStaffNum(v.cid).num < v.num then
                                        hashint_safemask = nil
                                    end
                                end
                            end
                        end
                        if safeconfig[tostring(gamedata.cache.safemask[tostring(k)].level)].battle_lv and (safeconfig[tostring(gamedata.cache.safemask[tostring(k)].level)].battle_lv > gamedata.cache.role.level) then
                            hashint_safemask = nil
                        end    
                    end
                end
                --

                --判断魔罩飞升
                local hashint_safemaskFeiSheng = nil
                if gamedata.cache.safemask and gamedata.cache.safemask[tostring(k)] and gamedata.cache.role.level >= gamedata.config.build[tostring(462)].level then
                    local safeconfig = gamedata.config.mozhao_soaring or {}
                    local nextLevelConfig = safeconfig[tostring(gamedata.cache.safemask[tostring(k)].level3 + 1)]

                    if nextLevelConfig then
                        hashint_safemaskFeiSheng = true
                        local coststr = nextLevelConfig.consume
                        local cost = gamedata.getIDandNUMs(coststr)
                        if cost then
                            for k,v in pairs(cost) do
                                if v.cid == 1000 then
                                    if v.num > 0 and gamedata.cache.role.coin < v.num then
                                        hashint_safemaskFeiSheng = nil
                                    end
                                elseif v.cid == 1001 then
                                    if v.num > 0 and gamedata.cache.role.gold < v.num then
                                        hashint_safemaskFeiSheng = nil
                                    end
                                else
                                    if gamedata.getStaffNum(v.cid).num < v.num then
                                        hashint_safemaskFeiSheng = nil
                                    end
                                end
                            end
                        end

                        --进阶等级
                        if nextLevelConfig.advanced_level and nextLevelConfig.advanced_level > gamedata.cache.safemask[tostring(k)].level2 then
                            hashint_safemaskFeiSheng = nil
                        end

                        --全体伙伴魔罩等级

                        for k,v in pairs(gamedata.cache.safemask) do
                            if v.level3 < nextLevelConfig.all_soaring_level then
                                hashint_safemaskFeiSheng = nil
                                break
                            end
                        end

                    end
                end


                slots[k].hashint_equip = hashint_equip
                slots[k].hashint_soul = hashint_soul
                slots[k].hashint_stone = hashint_stone
                slots[k].hashint_safemask = hashint_safemask
                slots[k].hashint_safemaskFeiSheng = hashint_safemaskFeiSheng


                if hashint_safemaskFeiSheng then
                    slots[k].hashint_safemask = true
                end
                
                if slots[k].newartifact > 0 then
                    slots[k].newartifact = gamedata.cache.artifacts[slots[k].newartifact]
                    slots[k].newartifact.generalcid = slots[k].general.cid
                end

                --判断专属神器红点
                if slots[k].general.hashint_exclusive then
                    slothint = true
                end

                local hashint_artifact = CheckArtifactHint(k)
                slots[k].hashint_artifact = hashint_artifact
                if hashint_equip or hashint_soul or hashint_stone or hashint_safemask  or hashint_artifact then
                    slothint = true
                end

                if hashint_safemaskFeiSheng then
                    safemaskFeiSheng_hint = true
                end

                if slots[k].general.skill.hintUp == 1 or slots[k].general.combskill.hintUp == 1 then
                    slothint = true
                end
                
                
            else
                slots[k] = {sid = k,power = 0 }
                if next(offgeneral) then
                    slothint = true
                end
            end

            if slots[k] and slots[k].token then
                local _isTokenBreak = false
                slots[k].tokenHint = false

                for i,v in ipairs(slots[k].token) do
                    for _i,_v in ipairs(v) do
                        if _v == 0 then
                            local _num1 = gamedata.cache.props[_tempTokenConfig[i][_i].id] and gamedata.cache.props[_tempTokenConfig[i][_i].id].num or 0
                            local _num2 = gamedata.cache.props[_tempTokenConfig[i][_i].cost.cid] and gamedata.cache.props[_tempTokenConfig[i][_i].cost.cid].num or 0

                            if gamedata.cache.role.level >= _tempTokenConfig[i][_i].limit_level and
                               _num1 >= 1 and
                               _num2 >= _tempTokenConfig[i][_i].cost.num then
                                slots[k].tokenHint = true
                                _isTokenBreak = true
                                tokenHint = true
                                break
                            end
                        end
                    end

                    if _isTokenBreak then
                        break
                    end
                end
            end
        else
            slots[k] = nil
        end
    end

    if slothint then
        mekehintext(4,1)
    else
        mekehintext(4,0)
    end


    print("safemaskFeiSheng_hint-------",safemaskFeiSheng_hint)
    if safemaskFeiSheng_hint then
        mekehintext(462,1)
    else
        mekehintext(462,0)
    end
    -- printT(gamedata.cache.hint)

    if tokenHint then
        mekehintext(631,1)
    else
        mekehintext(631,0)
    end

    --print(socket.gettime() - t1, "makeSlotInfo time")
    return slots
end

--专属神器开启
local function CheckExclusiveSwitch(general)
    if gamedata.config.build[tostring(611)].switch == 1 and gamedata.cache.role.level >= gamedata.config.build[tostring(611)].level then
        local generalConfig = gamedata.config.general[tostring(general.cid)]
        if generalConfig.exclusive and generalConfig.exclusive > 0 and general.quality >= 7 then
            return true
        end
    end
    return false
end

--激活
function CheckExclusiveActiveHint(general)
    if not CheckExclusiveSwitch(general) then
        return nil
    end
    local generalConfig = gamedata.config.general[tostring(general.cid)]
    local hint = true
    if generalConfig.quality < 7 then
        --品质小于彩金
        hint = nil
    elseif gamedata.cache.exclusiveArtifact[general.iid] then
        --已激活
        hint = nil
    else
        local challengeTimes = gamedata.cache.exclusiveArtifactChallengeTimes[general.iid] or 0
        if challengeTimes >= gamedata.config.vip[tostring(gamedata.cache.role.vip)].exclusive_copy then
            --没有挑战次数
            hint = nil
        end
    end
    return hint
end

--强化
function CheckExclusiveIntensifyHint(general)
    if not CheckExclusiveSwitch(general) then
        return nil
    end

    if not gamedata.cache.exclusiveArtifact[general.iid] then
        return nil
    end

    local artifactData = gamedata.cache.exclusiveArtifact[general.iid]
    local exclusiveConfig = gamedata.config.exclusive[tostring(artifactData.cid)]
    local exclusiveIntensifyConfig = gamedata.config.exclusive_intensify[tostring(exclusiveConfig.intensify_type)][tostring(artifactData.level)]
    local nextExclusiveIntensifyConfig = gamedata.config.exclusive_intensify[tostring(exclusiveConfig.intensify_type)][tostring(artifactData.level + 1)]
    
    if not nextExclusiveIntensifyConfig  then
        --最大级
        return nil
    end

    local hint = true
    local spendPropInfo = {}
    if exclusiveIntensifyConfig and exclusiveIntensifyConfig.intensify_level == 0 then
        spendPropInfo = gamedata.getIDandNUMs(exclusiveIntensifyConfig.consumption)
    else
        spendPropInfo = gamedata.getIDandNUMs(nextExclusiveIntensifyConfig.consumption)
    end

    for i,v in ipairs(spendPropInfo) do
        if gamedata:getPropNum(v.cid) < v.num then
            hint = nil
            break
        end
    end
    
    return hint
end

function CheckExclusiveQilingHint(general)
    print("CheckExclusiveQilingHint",gamedata.config.general[tostring(general.cid)].name)
    local hints = {0,0,0,0,0,0}
    if not CheckExclusiveSwitch(general) then
        return hints
    end

    if not gamedata.cache.exclusiveArtifact[general.iid] then
        return hints
    end

    local artifactData = gamedata.cache.exclusiveArtifact[general.iid]
    local qilingDatas = makeAllQilingForLoction()

    -- printT(artifactData,"artifactData")
    -- printT(qilingDatas,"qilingDatas")
    --0没红点 1 可镶嵌 2可更换
    for i=1,6 do
        hints[i] = 0
        if artifactData["inlayId"..i] > 0 then
            local qiLingData = gamedata.cache.exclusiveArtifactQiLing[artifactData["inlayId"..i]]
            for i2,v2 in ipairs(qilingDatas[qiLingData.location]) do
                if v2.quality > qiLingData.quality then
                    if v2.ison == 0 then
                        hints[i] = 2
                        break
                    end
                else
                    break
                end
            end
        else
            for i2,v2 in ipairs(qilingDatas[i] or {}) do
                if v2.ison == 0 then
                    hints[i] = 1
                    break
                end
            end
        end
    end
    printT(hints)
    return hints
end

function CheckArtifactHint(sid)
    if gamedata.cache.slots[sid].newartifact <= 0 then
        for k,v in pairs(gamedata.cache.artifacts) do
            if not v.sid and v.isChecked > 0 then
                return true
            end
        end
        return nil
    end

    local artifact = gamedata.cache.artifacts[gamedata.cache.slots[sid].newartifact]
    local config = gamedata.config.trump[tostring(artifact.cid)]
    local useTypes = {}
    for i = 1,4 do
        if artifact["jewel"..i] > 0 then
            local jewelConfig = gamedata.config.trump_gem[tostring(artifact["jewel"..i])]
            useTypes[jewelConfig.type] = true
        end
    end
    for i = 1,4 do
        if artifact["jewel"..i] < 0 then
            local openLevel = config["hole_lv"..i]
            if gamedata.cache.role.level >= openLevel then
                local useTable = gamedata.getIDandNUMs(config["hole_cost"..i])
                local isenough,ret = true,nil
                for k,v in pairs(useTable) do
                    isenough, ret = gamedata.checkStaffEnough(v.cid,v.num,{})
                    if not isenough then
                        break
                    end
                end
                if isenough then
                    return true
                end
            end
        elseif artifact["jewel"..i] == 0 then
            for k,v in pairs(gamedata.cache.jewels) do
                if v.num > 0 then
                    local jewelConfig = gamedata.config.trump_gem[tostring(v.cid)]
                    if not useTypes[jewelConfig.type] and gamedata.cache.role.level >= jewelConfig.gem_lvbet then
                        return true
                    end
                end
            end
        else
            if CheckJewelCanUp(artifact["jewel"..i],1) then
                return true
            end
        end
    end
    
    return nil
end

function makeCheerInfo(offgenerals_)
    --local t1 = socket.gettime()
    local cheer = table.copy(gamedata.cache.cheers)

    local slotconfig_old = gamedata.config.general_cheer

    --printT(gamedata.config.general_cheer)

    local slotconfig = gamedata.config.role_exp
    local opennum = slotconfig[tostring(gamedata.cache.role.level)].cheernum

    --printT(slotconfig)
    mekehintext(2,0)

    print("makeCheerInfo",opennum)
    local offgenerals =  offgenerals_ or makeOffGenerals()
    for k=1,8 do
        if k<= opennum then
            if cheer[k]  then
                local v = cheer[k]
                cheer[k].general = gamedata.cache.generals[v.general]
            else
                cheer[k] = {sid = k,isopen = true }

                if next(offgenerals) then
                    mekehintext(2,1)
                end

            end
        else
            cheer[k] = {sid = k,openlevel = slotconfig_old[tostring(k)] }
        end
    end
    --print(socket.gettime() - t1, "makeCheerInfo time")
    return cheer
end

function makeGodCompetitionCheerInfo(cheers_)
    local cheer = cheers_
    local slotconfig_old = gamedata.config.general_cheer

    local slotconfig = gamedata.config.role_exp
    local opennum = slotconfig[tostring(gamedata.cache.role.level)].cheernum
    print("makeGodCompetitionCheerInfo",opennum)
    for k=1,8 do
        if k<= opennum then
            if cheer[k]  then
                local v = cheer[k]
                cheer[k].general = gamedata.cache.generals[v.general]
            else
                cheer[k] = {sid = k,isopen = true }
            end
        else
            cheer[k] = {sid = k,openlevel = slotconfig_old[tostring(k)] }
        end
    end
    return cheer
end


function makeMofutemp()
    -- printT(gamedata.cache.slotgems)

    local gems = table.copy(gamedata.cache.gems)
    for ak,av in pairs(gamedata.cache.slotgems) do
        for bk,bv in pairs(av) do
            if tonumber(bv) > 0 then
                gems[tonumber(bv)].ison = ak
            end
        end
    end
    for k,v in pairs(gems) do
        if v.ison == nil then
            v.ison = 0
        end
    end
    return gems
end

function getMofuCanLevelData(infodata)
    -- printT(infodata,"infodata===")
    local tempdata = {}

    local ison = 0
    for k,v in pairs(makeMofutemp()) do
        if v.iid == infodata.iid then
            ison = v.ison
        end
    end

    local canlevelup = 1
    if infodata.type == 6 and ison ~= 0 then
        print("info.ison==",ison)

        local slotmofudata = makeSlotGeminfo()
        -- printT(slotmofudata,"slotmofudata===")
        for k,v in pairs(slotmofudata[tonumber(ison)].data) do
            print("kkk=",k)
            -- printT(v,"v====")
            if v.iid ~= infodata.iid then
                if next(v.data) then
                    local levelconfig = gamedata.config.kingofmofu_lv
                    print("level===",v.data.level,levelconfig[tostring(infodata.level)]["limit_lv"])
                    if v.data.level >= levelconfig[tostring(infodata.level)]["limit_lv"] then
                        -- canlevelup = true
                    else
                        canlevelup = 0
                        break
                    end
                else
                    canlevelup = 0
                    break
                end
            end
            
            
        end
    end
    tempdata.ison = ison
    tempdata.canlevelup = canlevelup
    -- printT(tempdata,"tempdata===")
    return tempdata
end

function getSameMofuNum(cid)
    -- printT(gamedata.cache.slotgems)

    local gems = table.copy(gamedata.cache.gems)
    local samenum = 0
    for k,v in pairs(gems) do
        if tonumber(v.cid) == tonumber(cid) then
            samenum = samenum + 1
        end
    end
    return samenum
end


function makeMofulist()
    local mofudata = {}
    for i,v in pairs(makeMofutemp()) do
        table.insert(mofudata,v)
    end

    -- gamedata.sortData(mofudata, "ison","order",nil,nil,nil,false,true)


    local sortFunc = function( a, b )
        local mofuconfig =  gamedata.config.sigil
        if a["ison"] ~= 0 and b["ison"] ~= 0 then
            if mofuconfig[tostring(a.cid)]["order"] < mofuconfig[tostring(b.cid)]["order"] then
                return true
            elseif mofuconfig[tostring(a.cid)]["order"] >= mofuconfig[tostring(b.cid)]["order"] then
                return false
            end
        else
            if a["ison"] > b["ison"] then
                return true
            elseif a["ison"] < b["ison"] then
                return false
            else
                if mofuconfig[tostring(a.cid)]["order"] < mofuconfig[tostring(b.cid)]["order"] then
                    return true
                elseif mofuconfig[tostring(a.cid)]["order"] >= mofuconfig[tostring(b.cid)]["order"] then
                    return false

                end
            end
        end
    end
    table.sort(mofudata,sortFunc)

    return mofudata
end

function makeOffMofuBytype(type,iid,nolevelup)
    print("makeOffMofuBytype===",type,iid)
    -- printT(makeMofutemp(),"mofutemp")
    local mofudata = {}
    for i,v in pairs(makeMofutemp()) do
        if not v.ison or v.ison ==0 then
            if nolevelup then
                if v.type==type and v.iid ~= iid then
                    table.insert(mofudata,v)
                end
            else
                if v.type==type and v.iid ~= iid and gamedata.config.sigil[tostring(v.cid)]["nextid"] ~= 0 then
                    table.insert(mofudata,v)
                end
            end
        end
    end
    if nolevelup then
        gamedata.sortData(mofudata, "order",nil,nil,nil,nil,nil,true)
    else
        gamedata.sortData(mofudata, "order",nil,nil,nil,nil,nil,false)
    end
    
    return mofudata
end

function makeOffMofuBytypeAll()
    local alldata = {}
    for i,v in pairs(makeMofutemp()) do
        if not v.ison or v.ison ==0 then
            if not alldata[v.type] then alldata[v.type] = {} end
            table.insert(alldata[v.type],v)
        end
    end

    return alldata
end


function makeSlotGeminfo()

    local slotgems = table.copy(gamedata.cache.slotgems)
    local slotconfig_old = gamedata.config.general_cheer
    local slotconfig = gamedata.config.role_exp
    local opennum = slotconfig[tostring(gamedata.cache.role.level)].cheernum

    local allgemdata = makeOffMofuBytypeAll()

    mekehintext(158,0)

    for k=1,8 do
        if k<= opennum then
            if not slotgems[k] then
                slotgems[k] = {open = true,data = {0,0,0,0,0,-1}}
            else
                slotgems[k] = {open = true,data = table.copy(slotgems[k])}
            end

            for kk=1,6 do
                slotgems[k].data[kk] = {iid = slotgems[k].data[kk], data = {} }
                local config = nil
                if slotgems[k].data[kk].iid >0 then
                    slotgems[k].data[kk].data = gamedata.cache.gems[slotgems[k].data[kk].iid] or {}
                    config = gamedata.config.sigil[tostring(gamedata.cache.gems[slotgems[k].data[kk].iid].cid)]
                end


                if (not config or config.nextid ~=0) and allgemdata[gamedata.config.sigilposition[tostring(k)]["type"..kk]] and table.getTableLength(allgemdata[gamedata.config.sigilposition[tostring(k)]["type"..kk]]) >0 then
                    if slotgems[k].data[kk].iid == 0 then
                        slotgems[k].data[kk].has = true
                        if not slotgems[k].notice or slotgems[k].notice == "up3" then slotgems[k].notice = "up5" end
                    elseif slotgems[k].data[kk].iid > 0 then
                        for k_,v_ in pairs(allgemdata[gamedata.config.sigilposition[tostring(k)]["type"..kk]]) do
                            if v_.level <15 then
                                -- print(k,kk)
                                slotgems[k].data[kk].has = true
                                if not slotgems[k].notice then slotgems[k].notice = "up3" end
                                --break
                                if not slotgems[k]["up"..kk] then slotgems[k]["up"..kk] = 1 end
                            end
                        end
                    end
                end
            end

            if slotgems[k].notice then
                mekehintext(158,1)
            end

        else
            slotgems[k] = {open = false ,openlevel = slotconfig_old[tostring(k)] }
        end
    end

    return slotgems
end


function UIOffSoulsCallBack(uireq)
    print("请求武魂10027 接收UI请求")
    return 0, 10027, {type = 10027, souls = makeOffSouls()}
end

function UISoulsCallBack(uireq)
    print("请求武魂10026 接收UI请求")
    uireq.param = uireq.param or "all"
    if uireq.param == "all" then
        return 0, 10026, {type = 10026, param = uireq.param, souls = makeSouls()}
    elseif uireq.param == "star2" then
        return 0, 10026, {type = 10026, param = uireq.param, souls = makeSoulsByQuality(2)}
    elseif uireq.param == "star3" then
        return 0, 10026, {type = 10026, param = uireq.param, souls = makeSoulsByQuality(3)}
    elseif uireq.param == "star4" then
        return 0, 10026, {type = 10026, param = uireq.param, souls = makeSoulsByQuality(4)}
    elseif uireq.param == "star5" then
        return 0, 10026, {type = 10026, param = uireq.param, souls = makeSoulsByQuality(5)}
    end

end



function UIEquipsCallBack(uireq)
    print("请求装备10025 接收UI请求")
    uireq.param = uireq.param or "all"
    if uireq.param == "all" then
        return 0, 10025, {type = 10025, param = uireq.param, equips = makeEquipsAndTreasures() }    -- 所有装备和宝物
    elseif uireq.param == "equips" then
        return 0, 10025, {type = 10025, param = uireq.param, equips = makeEquips() }     --所有装备
    elseif uireq.param == "treasures" then
        return 0, 10025, {type = 10025, param = uireq.param, treasures = makeTreasure() }   --所有宝物
     elseif uireq.param == "slotequips" then
        return 0, 10025, {type = 10025, param = uireq.param, slotequips = makeOnEquipsForSlot() }   -- 当前阵容上的装备
    elseif uireq.param == "offequips" then
        return 0, 10025, {type = 10025, param = uireq.param, OffEquip = makeOffEquip() }    --所有未使用装备
    elseif uireq.param == "offtreasures" then
        return 0, 10025, {type = 10025, param = uireq.param, OffTreasure = makeOffTreasure() }   --所有未使用宝物
    elseif uireq.param == "equipstage" then
        return 0, 10025, {type = 10025, param = uireq.param, equipstage = makeCanStageEquips() }   --可进阶的套装装备
    else 
        return 0, 10025, {type = 10025, param = uireq.param, equips = makeEquipsByType(uireq.param), }
    end
end

function UIOffGeneralCallBack(uireq)
    print("请求不在阵武将10024 接收UI请求")
    return 0, 10024, {type = 10024, offgenerals = makeOffGenerals()}
end

function UIAllGeneralCallBack(uireq)
    print("请求所有武将10023 接收UI请求")
    return 0, 10023, {type = 10023, generals = makeAllGenerals()}
end

function UISlotsCallBack(uireq)
    print("请求阵容10021 接收UI请求")
    local param = uireq.param or 0
    if param == 0 then
        return 0, 10021, {type = 10021, param = param, slots = makeSlotInfo(), cheers = makeCheerInfo() }
    elseif param == 1 then
        return 0, 10021, {type = 10021, param = param, slots = makeSlotInfo()}
    elseif param == 2 then
        return 0, 10021, {type = 10021, param = param, cheers = makeCheerInfo()}
    end
end

function UISlotGemsCallBack(uireq)
    print("请求魔符阵容10022 接收UI请求")
    return 0, 10022, {type = 10022, slotgems = makeSlotGeminfo(), gems = makeMofulist(),}
end


function UIGemsCallBack(uireq)
    print("请求魔符10028 接收UI请求")
    return 0, 10028, {type = 10028, gems = makeMofulist(),}
end


function makeMofuSortInfo()
    local mofudata = {}
    for k,v in pairs(table.copy(gamedata.cache.gems)) do
        table.insert(mofudata,v)
    end

    -- printT(gamedata.cache.gems)
    for i,v in ipairs(mofudata) do
        local mofuconfig = gamedata.config.sigil
        v.temp = gamedata.config.sigil[tostring(v.cid)]

        local posNum = 0
        local isonTemp = false
        for ak,av in pairs(gamedata.cache.slotgems) do
            for bk,bv in pairs(av) do
                if tonumber(v.iid) == tonumber(bv) then
                    posNum = ak
                    isonTemp = true
                    break
                end
            end
            if isonTemp == true then
                break
            end
        end

        v.ison = posNum
        
    end
    -- print("makeMofuSortInfo===")
    -- printT(mofudata)
    

    local sortFunc = function( a, b )
        if a["ison"] ~= 0 and b["ison"] ~= 0 then
            if a["temp"]["order"] < b["temp"]["order"] then
                return true
            elseif a["temp"]["order"] >= b["temp"]["order"] then
                return false
            end
        else
            if a["ison"] > b["ison"] then
                return true
            elseif a["ison"] < b["ison"] then
                return false
            else
                if a["temp"]["order"] < b["temp"]["order"] then
                    return true
                elseif a["temp"]["order"] >= b["temp"]["order"] then
                    return false

                end
            end
        end


        

        -- if a["temp"]["order"] < b["temp"]["order"] then
        --     return true
        -- elseif a["temp"]["order"] > b["temp"]["order"] then
        --     return false
        -- else
        --     -- if a["exp"] < b["exp"] then
        --     --     return false
        --     -- else
        --     --     return true
        --     -- end
        -- end  
 
    end
    table.sort(mofudata,sortFunc)
    -- print("mofudata====")
    -- printT(mofudata)

    return mofudata
end

function UIEquipCanStageUpCallBack(uireq)
    print("请求可以晋级的装备 接收UI请求")
    return 0, 10030, {type = 10030, gems = makeMofulist(),}
end

function NetGeneralOnSlotCallBack(fd)
    print("在阵武将刷新1024 接收服务器返回数据")
    local info = slots_pb.SlotS()
    info:ParseFromString(fd.rbuf)

    gamedata:SlotInfoProcess(info)

    return {type = 1024}
end

--[[
    神器技能发生变化
]]
function NetGeneralSlotCallBack(fd)
    print("在阵武将刷新1027 接收服务器返回数据")
    local info = slots_pb.SlotS()
    info:ParseFromString(fd.rbuf)

    gamedata:Slots(info.slots)
    local generals = gamedata:Generals(info.generals,true)
    printT(generals)
    return {type = 1027}
end





function UISlotsAllInfoCallBack(uireq)
    print("请求阵容，装备等1002 接收UI请求")

    gamedata.ext.slotrequireparam = uireq.param

    if uireq.param and uireq.param == "devil" then
        return 1, 1002, nil
    elseif gamedata.cache.slots and next(gamedata.cache.slots) then
        local equips =  makeEquipsByTypeAll()
        local souls = makeSoulsByQualityAll()
        local t = {
            type= 1002,
            protagonist = gamedata.cache.protagonist,
            slots = makeSlotInfo(),
            cheers = makeCheerInfo(),
            offgenerals = makeOffGenerals(),
            generals = makeAllGenerals(),

            souls = souls.all,
            souls2 = souls.souls2,
            souls3 = souls.souls3,
            souls4 = souls.souls4,
            souls5 = souls.souls5,

            equips = equips.equips,
            treasures = equips.treasures,
            weapon= equips.weapon,
            head= equips.head,
            armor= equips.armor,
            accessory =equips.accessory,
            horse= equips.horse,
            treasure= equips.treasure,

            OffEquip = makeOffEquip(),
            OffTreasure = makeOffTreasure(),
            slotequips = makeOnEquipsForSlot(),

            slotgems = makeSlotGeminfo(),
            gems = makeMofulist(),--魔符列表
            artifacts = gamedata.cache.artifacts,
            -- equipstage = makeCanStageEquips(),--可进阶的装备
        }
        for k,v in pairs(t.treasures) do
            v.allnum = nil
        end

        for k,v in pairs(t.horse) do
            v.allnum = nil
        end

        for k,v in pairs(t.treasure) do
            v.allnum = nil
        end

        for k,v in pairs(t.OffTreasure) do
            v.allnum = nil
        end
        return 0, 1002, t
    else
        return 1, 1002, nil
    end
end


function NetSlotsAllInfoCallBack(fd)
    print("请求阵容，装备等1002 接收服务器返回数据")
    local info = slots_pb.SlotS()
    info:ParseFromString(fd.rbuf)

    gamedata:SlotInfoProcess(info)

    local EquipTemp = makeEquipsTemp()
    local GeneralTemp = makeAllGeneralsTemp()
    local offgenerals = makeOffGenerals(GeneralTemp)

    local equips =  makeEquipsByTypeAll(EquipTemp)
    local souls = makeSoulsByQualityAll()
    local t = {
        type= 1002,
        protagonist = gamedata.cache.protagonist,
        slots = makeSlotInfo(EquipTemp,offgenerals,equips),
        cheers = makeCheerInfo(offgenerals),
        offgenerals = offgenerals,
        generals = makeAllGenerals(GeneralTemp),

        souls = souls.all,
        souls2 = souls.souls2,
        souls3 = souls.souls3,
        souls4 = souls.souls4,
        souls5 = souls.souls5,

        equips = equips.equips,
        treasures = equips.treasures,
        weapon= equips.weapon,
        head= equips.head,
        armor= equips.armor,
        accessory =equips.accessory,
        horse= equips.horse,
        treasure= equips.treasure,

        OffEquip = makeOffEquip(EquipTemp),
        OffTreasure = makeOffTreasure(EquipTemp),
        slotequips = makeOnEquipsForSlot(),

        slotgems = makeSlotGeminfo(),
        gems = makeMofulist(),
        artifacts = gamedata.cache.artifacts,
        -- equipstage = makeCanStageEquips(),--可进阶的装备

        slotrequireparam = gamedata.ext.slotrequireparam
    }
    for k,v in pairs(t.treasures) do
        v.allnum = nil
    end

    for k,v in pairs(t.horse) do
        v.allnum = nil
    end

    for k,v in pairs(t.treasure) do
        v.allnum = nil
    end

    for k,v in pairs(t.OffTreasure) do
        v.allnum = nil
    end
    CheckArtifactAllHint(1)
    return t
end

function UIMagicstoneUpCallBack(uireq)
    print("神石升级1130 接收UI请求")

    local propnum = gamedata.cache.props[20223] and gamedata.cache.props[20223].num or 0
    local slots = gamedata.cache.slots[uireq.sid]
    local select = 1
    for i=1,8 do
        if slots["g"..i] < slots["g1"] then
            select = i
            break
        end
    end
    local key = gamedata.config.godstone[tostring(select)].attribute
    local config = gamedata.config.godstonestrengthening
    local nextlevelconfig = config[tostring(slots["g"..select]+1)]
    if slots["g"..select]+1 > table.getTableLength(config) then
        return  0, 503, {type = 503, msg = "已经强化到满级" }
    elseif propnum < nextlevelconfig[key.."_number"] then
        return  0, 503, {type = 503, msg = gamedata.config.props[tostring(20223)].name.."不足" }
    elseif gamedata.cache.role.level< nextlevelconfig["teamlv"] then
        return  0, 503, {type = 503, msg = "等级不足，"..nextlevelconfig["teamlv"].."级后可继续强化" }
    end

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids,uireq.sid)
    table.insert(idsData.ids,uireq.method)

    gamedata.ext.MagicstoneUp = {sid = uireq.sid,method = uireq.method}

    return 1, 1130, idsData:SerializeToString()
end

function NetMagicstoneUpCallBack(fd)
    print("神石升级1130 接收服务器返回数据")
    local info = slots_pb.SlotS()
    info:ParseFromString(fd.rbuf)

    local propnum = 0
    local oldslots = table.copy(gamedata.cache.slots[gamedata.ext.MagicstoneUp.sid])
    gamedata:SlotInfoProcess(info)
    local newslots = table.copy(gamedata.cache.slots[gamedata.ext.MagicstoneUp.sid])

    local changedstone = {}
    for i=1,8 do
        if oldslots["g"..i] ~= newslots["g"..i] then
            local key = gamedata.config.godstone[tostring(i)].attribute
            local config = gamedata.config.godstonestrengthening
            local nextlevelconfig = config[tostring(newslots["g"..i])]
            propnum = propnum + nextlevelconfig[key.."_number"]
            changedstone[i] = true
        end
    end

    gamedata:updateprops({cid = 20223,num = -propnum})


    return {type= 1130, changedstone = changedstone}
end

function UIChangeSlotCallBack(uireq)
    print("布阵1003 接收UI请求")

    local GeneralChangePos = generalchangepos_pb.GeneralChangePos()
    gamedata.ext.changelslot = {}
    if uireq.pos1 then
        GeneralChangePos.pos1 = uireq.pos1
        print(uireq.pos1,"uireq.pos1")
    end
    if uireq.pos2 then
        GeneralChangePos.pos2 = uireq.pos2
        print(uireq.pos2,"uireq.pos2")
    end
    if uireq.iid then
        GeneralChangePos.iid = uireq.iid
        print(uireq.iid,"uireq.iid")
    end

    gamedata.ext.changelslot = {pos1 = uireq.pos1, pos2 = uireq.pos2, iid = uireq.iid}

    return 1, 1003, GeneralChangePos:SerializeToString()
end

function NetChangeSlotCallBack(fd)
    print("布阵1003 接收服务器返回数据")
    local info = slots_pb.SlotS()
    info:ParseFromString(fd.rbuf)

    gamedata:SlotInfoProcess(info)

    return {type= 1003, changelslot = gamedata.ext.changelslot}
end



function UIChangeCheerCallBack(uireq)
    print("布阵1004 接收UI请求")

    local GeneralChangePos = generalchangepos_pb.GeneralChangePos()
    gamedata.ext.changelslot = {}
    if uireq.pos1 then
        GeneralChangePos.pos1 = uireq.pos1
        print(uireq.pos1,"uireq.pos1")
    end
    if uireq.pos2 then
        GeneralChangePos.pos2 = uireq.pos2
        print(uireq.pos2,"uireq.pos2")
    end
    if uireq.iid then
        GeneralChangePos.iid = uireq.iid
        print(uireq.iid,"uireq.iid")
    end

    gamedata.ext.changelslot = {pos1 = uireq.pos1, pos2 = uireq.pos2, iid = uireq.iid}

    return 1, 1004, GeneralChangePos:SerializeToString()

end

function NetChangecheerCallBack(fd)
    print("布阵1004 接收服务器返回数据")
    local info = slots_pb.SlotS()
    info:ParseFromString(fd.rbuf)

    gamedata:SlotInfoProcess(info)

    return {type= 1004, changelslot = gamedata.ext.changelslot}
end

function UISlotArrangeCallBack(uireq)
    print("布阵1009 接收UI请求")
    local idsData = ids_pb.Ids()

    for i=1,7 do
        if uireq.ids[tostring(i)] and uireq.ids[tostring(i)] ~= i then
             table.insert(idsData.ids,uireq.ids[tostring(i)])
        else
            table.insert(idsData.ids,0)
        end
    end

    return 1, 1009, idsData:SerializeToString()
end

function NetSlotArrangeCallBack(fd)
    print("布阵1009 接收服务器返回数据")
    local info = slots_pb.SlotS()
    info:ParseFromString(fd.rbuf)

    gamedata:SlotInfoProcess(info)

    return {type= 1009, slots = makeSlotInfo(),}
end


function UISomeIdsCallBack(uireq)
    print("请求额外信息 1031 接收UI请求")
    return 1, 1031, nil
end

function NetSomeIdsCallBack(fd)
    print("1031 接收服务器返回数据")
    local idsData = ids_pb.Ids()
    idsData:ParseFromString(fd.rbuf)

    gamedata:SomeIds(idsData)

    return {type= 1031, someids = gamedata.cache.someids,}
end

local function kickExpGeneral(data)
    for k,v in ipairs(data) do
        if not gamedata.config.general[tostring(v.cid)].battle or gamedata.config.general[tostring(v.cid)].battle ==0  then
            data[k] = nil
        end
    end
end

local function getIllusionData(param)
    local illusionConfig = gamedata.config.illusion[tostring(param.cid)]
    local illusionGeneralConfig = gamedata.config.general[tostring(illusionConfig.general_id)]

    --判断幻影是否在阵(普通阵容)
    local ison = false
    local orange_id = gamedata.getOriginCid(illusionConfig.general_id)

    for k,v in pairs(gamedata.cache.slots) do
        local general = gamedata.cache.generals[v.general]
        if general and gamedata.getOriginCid(general.cid) == orange_id then
            ison = true
            break
        end 
    end

    if not ison then
        for k,v in pairs(gamedata.cache.cheers) do
            local general = gamedata.cache.generals[v.general]
            if general and gamedata.getOriginCid(general.cid) == orange_id then
                ison = true
                break
            end
        end
    end
    print("getIllusionData")
    print("ison",ison)

    --判断是否在封神赛 阵容
    local isOnGodCompetition = false
    -- local goddata = table.copy(gamedata.cache.godCompetionData)
    -- local generalstemp = table.copy(gamedata.cache.generals)
    -- for i=1,3 do
    --     if goddata and  goddata[i] then
    --         local _general = goddata[i].slot_General.general
    --         local relationdata = goddata[i].slot_General.relation
    --         for k,v in pairs (_general) do
    --             if v and v.general  then
    --                 if gamedata.getOriginCid(v.general.cid) == orange_id then
    --                     -- print("在阵"..i.."  iid:"..v.general.iid.." cid:"..v.general.cid)
    --                     isOnGodCompetition = true
    --                 end    
    --                 if v.general.iid and generalstemp[v.general.iid] then
    --                     generalstemp[v.general.iid].ison = 20+i 
    --                 end    
    --             end    
    --         end 
            
    --         local _cheer = goddata[i].cheer_General
    --         for k,v in pairs(_cheer) do
    --             if v and v.general and gamedata.getOriginCid(v.general.cid) == orange_id  then
    --                 -- print("助阵"..i.."  iid:"..v.general.iid.." cid:"..v.general.cid)
    --                 isOnGodCompetition = true
    --             end    
    --             if v.general.iid and generalstemp[v.general.iid] then
    --                 generalstemp[v.general.iid].ison = 1
    --             end    
    --         end
    --     end   
    -- end    

    local allgenerals = makeAllGeneralsTemp()
    --幻化伙伴列表
    local illusionGenerals = {}
    for k,v in pairs(allgenerals) do
        if v.illusionGeneralCid then
            illusionGenerals[gamedata.getOriginCid(v.illusionGeneralCid)] = true
            illusionGenerals[gamedata.getOriginCid(v.cid)] = true
        end
    end

    --可以幻化
    local _tempdata1 = {}
    --不能幻化
    local data2 = {}
    for k,v in pairs(allgenerals) do
        if illusionGenerals[gamedata.getOriginCid(v.cid)] or (v.illusionGeneralCid and illusionGenerals[gamedata.getOriginCid(v.illusionGeneralCid)]) then
            --已存在幻化关系 不能幻化
            v.illusionCond = 1
            table.insert(data2,v)
        elseif gamedata.getOriginCid(v.cid) == illusionConfig.general_id then
            --不能幻化自身
            v.illusionCond = 2
            table.insert(data2,v)
        elseif ison and v.ison then
            --山珍和助阵中不能出现相同的伙伴
            v.illusionCond = 3
            table.insert(data2,v)
        else
            v.illusionCond = 0
            table.insert(_tempdata1,v)
        end
    end
    
    local data1 = {}
    print(isOnGodCompetition,"isOnGodCompetition")
    if isOnGodCompetition then --封神赛在阵容,只能幻化不在阵容的
        for k,v in pairs(_tempdata1) do
            if generalstemp[v.iid] and generalstemp[v.iid].ison  then
                v.illusionCond = 3
                table.insert(data2,v)
            else
                table.insert(data1,v)
            end    
        end    
    else
        data1 = _tempdata1
    end    
   
    gamedata.sortData(data1,"power")
    gamedata.sortData(data2,"illusionCond","power",nil,nil,nil,nil,true)

    for i,v in ipairs(data2) do
        table.insert(data1,v)
    end

    return data1
end

function UISelectListCallBack(uireq)
    print("请求选择列表数据10029 接收UI请求")
    local data = {}

    if uireq.param == "change_weapon" then
        data = makeOffEquipByType("weapon")
    elseif uireq.param == "change_armor" then
        data = makeOffEquipByType("armor")
    elseif uireq.param == "change_accessory" then
        data = makeOffEquipByType("accessory")
    elseif uireq.param == "change_head" then
        data = makeOffEquipByType("head")
    elseif uireq.param == "change_horse" then
        data = makeOffEquipByType("horse")
    elseif uireq.param == "change_treasure" then
        data = makeOffEquipByType("treasure")
    elseif uireq.param == "inherit_selectgeneral" then
        data = makeInheritSelectGenerals(uireq.param2)
    elseif uireq.param == "changesoul" then
        data = makeChangeSoul(uireq.param2)
    elseif uireq.param == "change_weapon_all" then
        data = makeSelectEquipByType("weapon",uireq.param2 or 0)
    elseif uireq.param == "change_armor_all" then
        data = makeSelectEquipByType("armor",uireq.param2 or 0)
    elseif uireq.param == "change_accessory_all" then
        data = makeSelectEquipByType("accessory",uireq.param2 or 0)
    elseif uireq.param == "change_head_all" then
        data = makeSelectEquipByType("head",uireq.param2 or 0)
    elseif uireq.param == "change_horse_all" then
        data = makeSelectEquipByType("horse",uireq.param2 or 0)
    elseif uireq.param == "change_treasure_all" then
        data = makeSelectEquipByType("treasure",uireq.param2 or 0)
    elseif uireq.param == "changegeneral" then
        data = makeOffGeneralsWithoutExpGeneral()
        addGeneralRelation(data,uireq.param2,uireq.param3)
    elseif uireq.param == "changegeneral_godcompetition" then
        local isGeneral = true
        if uireq.param3 and uireq.param3 == "cheer" then
            isGeneral = false
        end    
        data = makeOffGodCompetitionGeneralsWithoutExpGeneral(uireq.param2,isGeneral)
        addGodCompetitionGeneralRelation(data,uireq.param2,uireq.param3,uireq.param4)
    elseif uireq.param == "change_equipstage_one" then
        print("change_equipstage_one=====")
        data = makeCanStageEquips()--可进阶的装备
    elseif uireq.param == "change_treasure_one" then
        data = makeTreasure()    --宝物强化
    elseif uireq.param == "change_gem_type" then
        data = makeOffMofuBytype(tonumber(uireq.param2),tonumber(uireq.param3),tonumber(uireq.param4))--获取不在阵 的魔符

    elseif uireq.param == "change_gemnum_type" then
        -- data = makeOffMofuBytype(tonumber(uireq.param2),tonumber(uireq.param3),tonumber(uireq.param4))--获取不在阵 的魔符
        data = getSameMofuNum(tonumber(uireq.param2)) --获取相同cid魔符的数量
    elseif uireq.param == "illusion" then
        data = getIllusionData(uireq.param2)
    end

    return 0, 10029, {type = 10029, data = data}
end

--灵阵图
function UISlotSpiritQueryCallBack(uireq)
    print("4200 接收UI请求")

    return 1, 4200, nil
end

function NetSlotSpiritQueryCallBack(fd)
    print("4200 接收服务器返回数据")
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:SlotSpiritData(ids.ids)
        elseif v.id == 1 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:SlotSpiritLevel(ids.ids)
        elseif v.id == 2 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:SlotSpiritActivation(ids.ids)
        end
    end

    return {type= 4200, slotSpirit = gamedata.cache.slotSpirit or {}}
end

function UISlotSpiritUseCallBack(uireq)
    print("4201 接收UI请求")
    local idsData = ids_pb.Ids()

    table.insert(idsData.ids,uireq.id or 1)

    return 1, 4201, idsData:SerializeToString()
end

function NetSlotSpiritUseCallBack(fd)
    print("4201 接收服务器返回数据")
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:SlotSpiritData(ids.ids)
        elseif v.id == 1 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:SlotSpiritLevel(ids.ids)
        elseif v.id == 2 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:SlotSpiritActivation(ids.ids)
        end
    end

    return {type= 4201, slotSpirit = gamedata.cache.slotSpirit or {}}
end

function NetSlotSpiritChangeCallBack(fd)
    print("4203 接收服务器返回数据")
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:SlotSpiritData(ids.ids)
        elseif v.id == 1 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:SlotSpiritLevel(ids.ids)
        elseif v.id == 2 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:SlotSpiritActivation(ids.ids)
        end
    end

    return {type= 4203, slotSpirit = gamedata.cache.slotSpirit or {}}
end


function UISlotSpiritAdditionQueryCallBack(uireq)
    print("4204 接收UI请求")
    gamedata.ext.SlotSpiritAddOpt = uireq.opt or ""
    return 1, 4204, nil
end

function NetSlotSpiritAdditionQueryCallBack(fd)
    print("4204 接收服务器返回数据")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    local data = {}
    data.activation = {}
    data.add = ids.ids[1] or 0
    for k,v in ipairs(ids.ids) do
        if tonumber(k)>1 then
            table.insert(data.activation,v)
        end
    end

    return {type= 4204, data = data, opt = gamedata.ext.SlotSpiritAddOpt}
end

function UISlotSpiritLevelupCallBack(uireq)
    print("4202 接收UI请求")
    gamedata.ext.SlotSpiritLevelupProps = uireq.props or nil
    if uireq.props then
        for k,v in pairs(uireq.props) do
            if v.cid == 1000 then
                if v.num > gamedata.cache.role.coin then
                    return 0,503,{type = 503, msgtype = "shortcoin" }
                end
            elseif v.cid == 1001 then
                if v.num > gamedata.cache.role.gold then
                    return 0,503,{type = 503, msgtype = "shortgold" }
                end
            elseif (not gamedata.cache.props[v.cid]) or (gamedata.cache.props[v.cid].num < v.num) then
                return 0,503,{type = 503,msgtype = "shortprop",id = v.cid,num = v.num,updatetable = {type = 12001, order = 42021, cids = {v.cid}} }
            end
        end
    end

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids,uireq.id or 1)

    return 1, 4202, idsData:SerializeToString()
end

function NetSlotSpiritLevelupCallBack(fd)
    print("4202 接收服务器返回数据")
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:SlotSpiritData(ids.ids)
        elseif v.id == 1 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:SlotSpiritLevel(ids.ids)
        elseif v.id == 2 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:SlotSpiritActivation(ids.ids)
        end
    end

    --
    if gamedata.ext.SlotSpiritLevelupProps then
        for k,v in pairs(gamedata.ext.SlotSpiritLevelupProps) do
            if v.cid == 1000 then
                gamedata:updateRoleCoin(0-v.num)
            elseif v.cid == 1001 then
                gamedata:updateRoleGold(0-v.num,"灵阵图升级",1)
            else
                gamedata:updateprops({cid = v.cid,num = 0-v.num})
            end
        end
    end
    --

    return {type= 4202, slotSpirit = gamedata.cache.slotSpirit or {}}
end


--
function UISlotCoverQueryCallBack(uireq)
    print("3730 接收UI请求")

    return 1, 3730, nil
end

function NetSlotCoverQueryCallBack(fd)
    print("3730 接收服务器返回数据")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata:SafeMask(ids.ids)

    return {type= 3730, safemask = gamedata.cache.safemask or {}}
end

function UISlotCoverupCallBack(uireq)
    print("3731 接收UI请求")
    gamedata.ext.safemaskCost = uireq.cost
    if uireq.cost then
        for k,v in pairs(uireq.cost) do
            if v.cid == 1000 then
                if v.num > 0 and gamedata.cache.role.coin < v.num then
                    return 0, 503, {type = 503, msgtype = "shortcoin"}
                end
            elseif v.cid == 1001 then
                if v.num > 0 and gamedata.cache.role.gold < v.num then
                    return 0, 503, {type = 503, msgtype = "shortgold"}
                end
            else
                if gamedata.getStaffNum(v.cid).num < v.num then
                    return 0,503,{type = 503,msg = 999}
                end
            end
        end
    end

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids,uireq.sid or 1)

    return 1, 3731, idsData:SerializeToString()
end

function NetSlotCoverupCallBack(fd)
    print("3731 接收服务器返回数据")

    local info = generals_pb.Generals()
    info:ParseFromString(fd.rbuf)
    gamedata:Generals(info.generals)

    if gamedata.ext.safemaskCost then
        for k,v in pairs(gamedata.ext.safemaskCost) do
            gamedata:updateStaff({cid = v.cid, num = 0-v.num})
        end
    end

    return {type= 3731,}
end




function UIPureSlotsCallBack(uireq)
    printT(gamedata.cache.slots,"UIPureSlotsCallBack")
    local slots = table.copy(gamedata.cache.slots)

    for k,v in pairs(slots) do
        if v.general > 0 then
            if not gamedata.cache.generals[v.general] or v.general == gamedata.cache.protagonist.iid then
                v.general = gamedata.cache.protagonist.general
            else
                v.general = gamedata.cache.generals[v.general]
            end
        else
            v.general = nil
        end
    end
    return 0, 70110, {type = 70110, slots = slots}
end

--
function UISlotCoverMasterQueryCallBack(uireq)
    print("3732 接收UI请求")

    return 1, 3732, nil
end

function NetSlotCoverMasterQueryCallBack(fd)
    print("3732 接收服务器返回数据")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata:SafeMaskMaster(ids.ids)

    return {type= 3732, safemaskmaster = gamedata.cache.safemaskmaster or {}}
end


--    [3735] = UISlotCoverLevel2UpCallBack,

function UISlotCoverLevel2UpCallBack(uireq)
    print("3735 接收UI请求")
    gamedata.ext.safemaskCost2 = uireq.cost
    if uireq.cost then
        for k,v in pairs(uireq.cost) do
            if v.cid == 1000 then
                if v.num > 0 and gamedata.cache.role.coin < v.num then
                    return 0, 503, {type = 503, msgtype = "shortcoin"}
                end
            elseif v.cid == 1001 then
                if v.num > 0 and gamedata.cache.role.gold < v.num then
                    return 0, 503, {type = 503, msgtype = "shortgold"}
                end
            else
                if gamedata.getStaffNum(v.cid).num < v.num then
                    return 0,503,{type = 503,msg = 999}
                end
            end
        end
    end

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids,uireq.sid or 1)

    return 1, 3735, idsData:SerializeToString()
end

function NetSlotCoverLevel2UpCallBack(fd)
    print("3735 接收服务器返回数据")

    local info = generals_pb.Generals()
    info:ParseFromString(fd.rbuf)
    gamedata:Generals(info.generals)

    if gamedata.ext.safemaskCost2 then
        for k,v in pairs(gamedata.ext.safemaskCost2) do
            gamedata:updateStaff({cid = v.cid, num = 0-v.num})
        end
    end

    return {type= 3735,}
end



function UISlotCoverFeiShengCallBack(uireq)
    print("3736 接收UI请求")
    gamedata.ext.safemaskCost3 = uireq.cost
    if uireq.cost then
        for k,v in pairs(uireq.cost) do
            if v.cid == 1000 then
                if v.num > 0 and gamedata.cache.role.coin < v.num then
                    return 0, 503, {type = 503, msgtype = "shortcoin"}
                end
            elseif v.cid == 1001 then
                if v.num > 0 and gamedata.cache.role.gold < v.num then
                    return 0, 503, {type = 503, msgtype = "shortgold"}
                end
            else
                if gamedata.getStaffNum(v.cid).num < v.num then
                    return 0,503,{type = 503,msg = 999}
                end
            end
        end
    end

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids,uireq.sid or 1)

    return 1, 3736, idsData:SerializeToString()
end

function NetSlotCoverFeiShengCallBack(fd)
    print("3736 接收服务器返回数据")

    local info = generals_pb.Generals()
    info:ParseFromString(fd.rbuf)
    gamedata:Generals(info.generals)

    if gamedata.ext.safemaskCost3 then
        for k,v in pairs(gamedata.ext.safemaskCost3) do
            gamedata:updateStaff({cid = v.cid, num = 0-v.num})
        end
    end

    return {type= 3736}
end

function UIGeneralAwakenRebirthCallback(uireq)
    print("8096 接收UI请求")
    print("uireq == ", uireq.iid)

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids,uireq.iid)

    gamedata.ext.generalAwakenIid = uireq.iid

    gamedata.ext.generalAwakenData = {}
    gamedata.ext.generalAwakenData.itemid = uireq.itemid
    gamedata.ext.generalAwakenData.itemnum = uireq.itemnum

    return 1, 8096, idsData:SerializeToString()

end

function NetGeneralAwakenRebirthCallback(fd)
    print("8096 接收服务器返回数据")

    local SomeThingsdata = somethings_pb.SomeThings()
    SomeThingsdata:ParseFromString(fd.rbuf)

    local reward = gamedata:SomethingProcess(SomeThingsdata)

    if gamedata.ext.generalAwakenData.itemid and gamedata.ext.generalAwakenData.itemnum then
        gamedata:updateStaff({cid = tonumber(gamedata.ext.generalAwakenData.itemid), num = -gamedata.ext.generalAwakenData.itemnum})
    end

    gamedata.ext.generalAwakenData = nil

    return { type = 8096, reward = reward, iid = gamedata.ext.generalAwakenIid }
end

function UIQueryGeneralByIdCallback(uireq)
    print("8097 接收UI请求")
    print("uireq == ", uireq.iid)

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids,uireq.iid)

    return 1, 8097, idsData:SerializeToString()

end

function NetQueryGeneralByIdCallback(fd)
    print("8097 接收服务器返回数据")

    local GeneralsData = generals_pb.Generals()
    GeneralsData:ParseFromString(fd.rbuf)
    gamedata:Generals(GeneralsData.generals)

    return { type = 8097 }
end

function UIGeneralUpStarRebirthCallback(uireq)
    print("8301 接收UI请求")
    print("uireq == ", uireq.iid)

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids,uireq.iid)

    gamedata.ext.generalUpStarIid = uireq.iid

    gamedata.ext.generalUpStarData = {}
    gamedata.ext.generalUpStarData.itemid = uireq.itemid
    gamedata.ext.generalUpStarData.itemnum = uireq.itemnum

    return 1, 8301, idsData:SerializeToString()

end

function NetGeneralUpStarRebirthCallback(fd)
    print("8301 接收服务器返回数据")

    local SomeThingsdata = somethings_pb.SomeThings()
    SomeThingsdata:ParseFromString(fd.rbuf)

    local reward = gamedata:SomethingProcess(SomeThingsdata)

    if gamedata.ext.generalUpStarData.itemid and gamedata.ext.generalUpStarData.itemnum then
        gamedata:updateStaff({cid = tonumber(gamedata.ext.generalUpStarData.itemid), num = -gamedata.ext.generalUpStarData.itemnum})
    end

    gamedata.ext.generalUpStarData = nil

    return { type = 8301, reward = reward, iid = gamedata.ext.generalUpStarIid }
end



function UICompetitionSlotsIndexSave(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 825200, "UICompetitionSlotsIndexSave")
    if uireq and uireq.godCompetionSlotIndex then
        gamedata.ext.godcompetition_slotIndex = uireq.godCompetionSlotIndex or 1
    end    
    return 0, 825200, {godcompetition_slotIndex = gamedata.ext.godcompetition_slotIndex}
end
function UIGodCompetitionSlotsQueryCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8252, "GodCompetitionSlotsQueryCallBack")

    gamedata.ext.godcompetitionteam_id = 1

    if uireq.page and uireq.page == 1 then
        local idsData = ids_pb.Ids()
        table.insert(idsData.ids,uireq.page)
        return 1, 8252, idsData:SerializeToString()
    else
        return 1, 8252, nil
    end

end

function NetGodCompetitionSlotsQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8252, "GodCompetitionSlotsQueryCallBack")
    local datas = apex_slots_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    makeGodCompetitionSlotInfo(datas)

    -- printT(godCompetionData,"godCompetionData ");
    -- local EquipTemp = makeEquipsTemp()
    -- local GeneralTemp = makeAllGeneralsTemp()
    -- local offgenerals = makeOffGenerals(GeneralTemp)
    -- local equips =  makeEquipsByTypeAll(EquipTemp)
    local t = {
        protagonist = gamedata.cache.protagonist,--主角信息
        -- slots = makeSlotInfo(EquipTemp,offgenerals,equips), --阵容信息
        slotgems = makeSlotGeminfo(),
        gems = makeMofulist(),--魔符列表
    }
    --在阵武将信息 
    return { type = 8252,slots = {}, godCompetionData = gamedata.cache.godCompetionData, slotgems = t.slotgems, gems = t.gems, protagonist = t.protagonist, godcompetition_slotIndex = gamedata.ext.godcompetition_slotIndex}

end



function UIGodCompetitionChangeSlotsCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8253, "GodCompetitionChangeSlotsCallBack")

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids,uireq.team_id)
    table.insert(idsData.ids,uireq.change_type)
    table.insert(idsData.ids,uireq.pos)
    table.insert(idsData.ids,uireq.iid)

    print(uireq.team_id,uireq.change_type,uireq.pos,uireq.iid)
    gamedata.ext.godcompetitionteam_id = uireq.team_id

    return 1, 8253, idsData:SerializeToString()
end

function NetGodCompetitionChangeSlotsCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8253, "GodCompetitionChangeSlotsCallBack")
    local datas = apex_slots_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)
    
    makeGodCompetitionSlotInfo(datas)

    return { type = 8253,godCompetionData = gamedata.cache.godCompetionData,godcompetition_slotIndex = gamedata.ext.godcompetition_slotIndex }
end    


function UIGodCompetitionChangePetCallBack(uireq)
    cclog("UI type:%d cmd:%s recv request from UI", 8254, "GodCompetitionChangePetCallBack")

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids,uireq.team_id)
    table.insert(idsData.ids,uireq.iid)

    print(uireq.team_id,uireq.iid)
    gamedata.ext.godcompetitionteam_id = uireq.team_id
    return 1, 8254, idsData:SerializeToString()
end

function NetGodCompetitionChangePetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8254, "GodCompetitionChangePetCallBack")
    local datas = apex_slots_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    makeGodCompetitionSlotInfo(datas)

    return { type = 8254,godCompetionData = gamedata.cache.godCompetionData,godcompetition_slotIndex = gamedata.ext.godcompetition_slotIndex }

end    

function makeGodCompetitionSlotInfo(datas)
    godCompetionDataFirst = {}
    for k,v in ipairs(datas.messages) do
        if v.id == 1 or v.id == 2 or v.id == 3 then

            print(v.id,"makeGodCompetitionSlotInfo ---阵容")
            local _godCompetionData = { slot_General= {},cheer_General = {},pet = {}, god_power =nil}
           
             --助阵伙伴
             local Cheer_General = {}
             for k1,v1 in ipairs(v.cheers) do
                 local cheers = {sid = v1.sid,general = v1.general}
                 Cheer_General[k1] = cheers
             end 
             -- printT(Cheer_General, "-----NetGodCompetitionSlotsQueryCallBack Cheer_General")
             _godCompetionData.cheer_General =  makeGodCompetitionCheerInfo(Cheer_General)

            --阵容
            local Slot_General = { sid = {}, general = {}, relation = {}}
            for k1,v1 in ipairs(v.slots) do
                -- print(k1,"k1 slots")
                local info = generals_pb.Generals()
                info:ParseFromString(v1.general)
                local general  =  gamedata:SlotGodCompetitionGenerals(info.generals,true)
                if table.getTableLength(general) >0 then
                    if not general[1].general then
                        Slot_General.general[k1] = {general = general[1]}
                    else    
                        Slot_General.general[k1] = general[1]
                    end   
                else
                    Slot_General.general[k1] = {}
                end    
                Slot_General.sid[k1] =  v1.sid

                local _relation = {}
                local length  = table.getTableLength(v1.relation)
                for k11,v11 in ipairs(v1.relation) do
                   -- print(k11,"k11 relation----")
                   local idss = {}
                   for kk,vv in ipairs(v11.ids) do
                       idss[kk] = vv
                   end
                   _relation[k11] = {activate = v11.activate,ids = idss}
                   if tonumber(k11)+2 == length then
                       -- print("add relation"..k11)
                       Slot_General.relation[k1] = _relation                        
                       _relation = {}
                   end    
                end   
            end   
            printT(Slot_General.relation," Slot_General.relation-"..v.id)
            -- Slot_General.general = gamedata:finGodCompetitionCombskilllevel(Slot_General.general,_godCompetionData.cheer_General)
            -- printT(Slot_General, "-----NetGodCompetitionSlotsQueryCallBack Slot_General")
            --重置武将的 合体技信息
            _godCompetionData.slot_General = Slot_General
           
            --宠物
            local pet = {iid=v.pet,cid = 0,level=0}
            if pet.iid > 0 then
                if gamedata.cache.petsdata and gamedata.cache.petsdata["pets"] then
                    local  cachapet= gamedata.cache.petsdata["pets"][pet.iid] 
                    if cachapet and cachapet.cid then
                        pet.cid = cachapet.cid
                        pet.level = cachapet.level
                    end    
                end    
            end    
            _godCompetionData.pet = pet

            --战力
            _godCompetionData.god_power = v.god_power
            -- print(v.pet, "-----NetGodCompetitionSlotsQueryCallBack pet")
            gamedata:changeGodCompetitionPower(v.god_power,tonumber(v.id),tonumber(gamedata.ext.godcompetitionteam_id))
            if gamedata.cache.godCompetionData and gamedata.cache.godCompetionData[v.id] then
                -- print("godCompetionData already have")
                gamedata.cache.godCompetionData[tonumber(v.id)] = _godCompetionData
            else
                -- print("godCompetionData first add")
                table.insert(godCompetionDataFirst,_godCompetionData)
            end    
        end    
    end

    if godCompetionDataFirst and next(godCompetionDataFirst) then
        -- print("godCompetionData first addvalue")
        gamedata.cache.godCompetionData = godCompetionDataFirst
    end    

    --合体技重新计算
    gamedata:finGodCompetitionCombskilllevel()

    -- printT(gamedata.cache.godCompetionData,"gamedata.cache.godCompetionData 2")   


end   

function makeGodCompetitionCheerInfo(cheers_)
    -- printT(cheers_, "makeGodCompetitionCheerInfo enter")
    local cheer = {}
    local slotconfig_old = gamedata.config.general_cheer


    local slotconfig = gamedata.config.role_exp
    local opennum = slotconfig[tostring(gamedata.cache.role.level)].cheernum
    
    for k=1,8 do
        if k<= opennum then
            local data = cheers_[k]
            if data and data.general and data.general>0 then
                cheer[tostring(k)] = {sid = k,general = gamedata.cache.generals[data.general] } 
            else
                cheer[tostring(k)] = {sid = k,isopen = true }
            end
        else
            cheer[tostring(k)] = {sid = k,openlevel = slotconfig_old[tostring(k)] }
        end
    end
    -- printT(cheer, "makeGodCompetitionCheerInfo return")
    return cheer
end


  �H 