--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/3
-- Time: 下午5:38
-- To change this template use File | Settings | File Templates.
--

local function maleTechData()
    local data = {
        generals = {},
        generalfragments = {},
    }

    for k,v in pairs(makeAllGeneralsTemp()) do
        if  not v.ison or v.ison == 0 then
            table.insert(data.generals,{cid = v.cid, quality = v.quality,num = 1,iid = v.iid})
        end
    end

    for k,v in pairs(gamedata.cache.generalfragments) do
        table.insert(data.generalfragments, {cid = v.cid, quality = gamedata.config.general[tostring(v.cid)].quality,num = v.num})
    end

    local function sortbyquality(a,b)
         if  a.quality<b.quality then
            return true
         elseif  a.quality>b.quality then
            return false
         elseif  a.quality==b.quality then
             if not a.iid and b.iid then
                 return true
             elseif a.iid and not b.iid then
                 return false
             else
                 return false
             end
         end
    end

    table.sort(data.generals,sortbyquality)
    table.sort(data.generalfragments,sortbyquality)

    return data
end

function UITechGeneralListCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 18001, "TechList")

    return 0, 18001, { type = uireq.type, data = maleTechData(),}
end

function UITechListCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1800, "TechList")
    if next(gamedata.cache.technology) then
        return 0, 1800, { type = uireq.type, technology = gamedata.cache.technology,}
    else
        return 1, 1800, nil
    end
end

local technologys_pb = require("technologys_pb")
function NetTechListCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1800, "TechList")
    local TechnologysData = technologys_pb.Technologys()
    TechnologysData:ParseFromString(fd.rbuf)

    gamedata:Technology(TechnologysData.techs)

    return { type = 1800, technology = gamedata.cache.technology,}
end


local technologyupgraderequest_pb = require("technologyupgraderequest_pb")
function UITechUpgradeCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1801, "TechUpgrade")
    local TechUpgradeData = technologyupgraderequest_pb.TechnologyUpgradeRequest()

    printT(uireq)

    TechUpgradeData.cid = uireq.cid
    for k,v in pairs(uireq.generals) do
        local general = technologyupgraderequest_pb.TechnologyUpgradeRequest.SpendGeneral()
        general.iid = v.iid
        table.insert(TechUpgradeData.generals,general)
    end

    for k,v in pairs(uireq.fragments) do
        local fragment = technologyupgraderequest_pb.TechnologyUpgradeRequest.SpendGeneralFragment()
        fragment.cid = v.cid
        fragment.num = v.num
        table.insert(TechUpgradeData.fragments,fragment)
    end

    gamedata.ext.TechUpgradeSpends =  {generals = uireq.generals,fragments = uireq.fragments,cid = uireq.cid}

    return 1, 1801, TechUpgradeData:SerializeToString()
end

local technologyupgraderesponse_pb = require("technologyupgraderesponse_pb")
function NetTechUpgradeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1801, "TechUpgrade")

    local TechUpgradeData = technologyupgraderesponse_pb.TechnologyUpgradeResponse()
    TechUpgradeData:ParseFromString(fd.rbuf)

    gamedata:Generals(TechUpgradeData.generals)

    gamedata.cache.technology[TechUpgradeData.cid] = gamedata:techData(TechUpgradeData)

    local spends = gamedata.ext.TechUpgradeSpends

    for k,v in pairs(spends.generals) do
       if gamedata.cache.generals[v.iid] then
           local cid = gamedata.cache.generals[v.iid].id
           gamedata.cache.generals[v.iid] = nil
           gamedata:updategeneralfragmentbynum({cid = cid, num =0})
       end
    end

    for k,v in pairs(spends.fragments) do
        --printT(v)
       gamedata:updategeneralfragmentbynum({cid = v.cid, num =0-v.num})
    end

    return { type = 1801, technology = gamedata.cache.technology[spends.cid]}
end

--mowang

local ids_pb = require("ids_pb")
local idnums_pb = require("idnums_pb")

function UIDevilStatusCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1805, "DevilStatus")

    return 1, 1805, nil
end

function NetDevilStatusCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1805, "DevilStatus")
    local DevilData = ids_pb.Ids()
    DevilData:ParseFromString(fd.rbuf)

    gamedata:DevilStatus(DevilData.ids)

    return { type = 1805, devil = gamedata.cache.devil,}
end

function UIDevilExchangeFragmentCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1806, "DevilExchangeFragment")
    local IdNums = idnums_pb.IdNums()

    for k,v in pairs(uireq.generals) do
        local idnum = idnums_pb.IdNums.IdNum()
        idnum.id = v.iid
        idnum.num = 0
        table.insert(IdNums.idnums,idnum)
    end

    for k,v in pairs(uireq.fragments) do
        local idnum = idnums_pb.IdNums.IdNum()
        idnum.id = v.cid
        idnum.num = v.num
        table.insert(IdNums.idnums,idnum)
    end

    gamedata.ext.DevilExchange =  {generals = uireq.generals,fragments = uireq.fragments}

    return 1, 1806, IdNums:SerializeToString()
end


function NetDevilExchangeFragmentCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1806, "DevilExchangeFragment")
    local DevilData = ids_pb.Ids()
    DevilData:ParseFromString(fd.rbuf)

    gamedata:UpdateDevilNum(DevilData.ids)

    local spends = gamedata.ext.DevilExchange

    for k,v in pairs(spends.generals) do
        if gamedata.cache.generals[v.iid] then
            local cid = gamedata.cache.generals[v.iid].cid
            gamedata.cache.generals[v.iid] = nil
            gamedata:updategeneralfragmentbynum({cid = cid, num =0})
        end
    end

    for k,v in pairs(spends.fragments) do
        gamedata:updategeneralfragmentbynum({cid = v.cid, num =0-v.num})
    end


    return { type = 1806, devil = gamedata.cache.devil,}
end

--
function UIDevilUpCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1807, "DevilUp")
    local idsData = ids_pb.Ids()

    if uireq.opt then
        table.insert(idsData.ids, uireq.opt)
        return 1, 1807, idsData:SerializeToString()
    else
        return 0, 1807, nil
    end
end

function NetDevilUpCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1807, "DevilUp")
    local DevilData = ids_pb.Ids()
    DevilData:ParseFromString(fd.rbuf)

    gamedata:DevilStatus(DevilData.ids)

    return { type = 1807, devil = gamedata.cache.devil,}
end
--

--
function UIDevilStatus2Callback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1808, "DevilStatus")

    return 1, 1808, nil
end

function NetDevilStatus2Callback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1808, "DevilStatus")
    local DevilData = ids_pb.Ids()
    DevilData:ParseFromString(fd.rbuf)
    local devil = {}
    devil.exp = DevilData.ids[1] or 0
    devil.level1 = DevilData.ids[2] or 0
    devil.level2 = DevilData.ids[3] or 0
    devil.up = DevilData.ids[4] or 0
    devil.atk = DevilData.ids[5] or 0
    devil.def = DevilData.ids[6] or 0
    devil.hp = DevilData.ids[7] or 0
    devil.speed = DevilData.ids[8] or 0
    devil.critical = DevilData.ids[9] or 0
    devil.dodge = DevilData.ids[10] or 0
    devil.parry = DevilData.ids[11] or 0
    devil.power = DevilData.ids[12] or 0

    return { type = 1808, devil = devil,}
end
--

--
local xdata = {}
function UIDevilLevel1ExpCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1809, "Level1Exp")
    local doData = ids_pb.Ids()
    xdata = {}
    if uireq.data then
        xdata = uireq.data
       for k,v in pairs(uireq.data) do
           if v.iid and v.iid > 0 then
               table.insert(doData.ids,2)
               table.insert(doData.ids,v.iid)
               table.insert(doData.ids,v.num)
           else
               table.insert(doData.ids,1)
               table.insert(doData.ids,v.cid)
               table.insert(doData.ids,v.num)
           end
       end
    end

    return 1, 1809, doData:SerializeToString()
end

function NetDevilLevel1ExpCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1809, "Level1Exp")
    local DevilData = ids_pb.Ids()
    DevilData:ParseFromString(fd.rbuf)
    local status = {}
    for k,v in ipairs(DevilData.ids) do
        status[k] = v
    end

    local xg = {}
    local xf = {}
    for k,v in ipairs(status) do
       if math.mod(k,3) == 0 then
           if v == 1 then
               xf[tostring(status[k+1])] = status[k+2]
           elseif v == 2 then
               xg[tostring(status[k+1])] = status[k+2]
           end
       end
    end

    for k,v in pairs(xdata) do
        if v.iid and v.iid > 0 then
            if gamedata.cache.generals[v.iid] and xg[tostring(v.iid)] and xg[tostring(v.iid)] == 0 then
                local cid = gamedata.cache.generals[v.iid].cid
                gamedata.cache.generals[v.iid] = nil
                gamedata:updategeneralfragmentbynum({cid = cid, num =0})
            end
        elseif xf[tostring(v.cid)] then
            gamedata:updategeneralfragmentbynum({cid = v.cid, num = xf[tostring(v.cid)] - v.num})
        end
    end
    xdata = {}
    return { type = 1809, status = status,}
end
--

--
local xnum = 0
local xid = 0
function UIDevilLevel2UpCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1810, "Level2Up")
    xnum = uireq.xnum or 0
    xid = uireq.xid or 0
    return 1, 1810, nil
end

function NetDevilLevel2UpCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1810, "Level2Up")
    local DevilData = ids_pb.Ids()
    DevilData:ParseFromString(fd.rbuf)
    local devil = {}
    devil.exp = DevilData.ids[1] or 0
    devil.level1 = DevilData.ids[2] or 0
    devil.level2 = DevilData.ids[3] or 0
    devil.up = DevilData.ids[4] or 0
    devil.atk = DevilData.ids[5] or 0
    devil.def = DevilData.ids[6] or 0
    devil.hp = DevilData.ids[7] or 0
    devil.speed = DevilData.ids[8] or 0
    devil.critical = DevilData.ids[9] or 0
    devil.dodge = DevilData.ids[10] or 0
    devil.parry = DevilData.ids[11] or 0

    if xid >0 and xnum > 0 then
        gamedata:updateprops({cid = xid, num = 0-xnum})
    end

    xnum = 0
    xid = 0

    return { type = 1810, devil = devil,}
end
--

---------
---------

-- function UIPetQueryCallback(uireq)
--     cclog("NET type:%d cmd:%s recv request from UI", 1040, "PetQuery")

--     return 1, 1040, nil
-- end


-- function NetPetQueryCallback(fd)
--     cclog("NET type:%d cmd:%s recv response from gameserver", 1040, "PetQuery")
--     local petData = ids_pb.Ids()
--     petData:ParseFromString(fd.rbuf)

--     gamedata:PetsData(petData.ids)

--     return { type = 1040, petsdata = gamedata.cache.petsdata,}
-- end


-- function UIPetFragmentCallback(uireq)
--     cclog("NET type:%d cmd:%s recv request from UI", 1044, "PetFragment")

--     if next(gamedata.cache.petsfragment) then
--         return 0, 1044, {type = 1044, fragment = gamedata.cache.petsfragment}
--     else
--         return 1, 1044, nil
--     end
-- end


-- function NetPetFragmentCallback(fd)
--     cclog("NET type:%d cmd:%s recv response from gameserver", 1044, "PetFragment")
--     local data = idnums_pb.IdNums()
--     data:ParseFromString(fd.rbuf)

--     gamedata:PetsFragments(data)

--     return { type = 1044, fragment = gamedata.cache.petsfragment,}
-- end

function UIPetCompoundCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1045, "PetCompound")

    local idsData = ids_pb.Ids()

    gamedata.ext.petCompoundCid = nil

    if uireq.cid then
        table.insert(idsData.ids, uireq.cid)
        gamedata.ext.petCompoundCid = uireq.cid
        return 1, 1045, idsData:SerializeToString()
    else
        return 0, 1045, nil
    end

end


function NetPetCompoundCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1045, "PetCompound")
    local petData = ids_pb.Ids()
    petData:ParseFromString(fd.rbuf)

    gamedata:setPetData(petData.ids)

    if gamedata.ext.petCompoundCid then
        for k,v in pairs(gamedata.config.pet2_fragment) do
            if v.petid == gamedata.ext.petCompoundCid then
                gamedata:updatePetsFragment({cid=v.debris,num = -v.number})
                break
            end
        end
    end

    return { type = 1045, petsdata = gamedata.cache.petsdata,}
end

-- function UIPetSetCallback(uireq)
--     cclog("NET type:%d cmd:%s recv request from UI", 1043, "PetSet")

--     local idsData = ids_pb.Ids()

--     if uireq.iid then
--         gamedata.ext.petsetiid = uireq.iid
--         table.insert(idsData.ids, uireq.iid)
--         return 1, 1043, idsData:SerializeToString()
--     else
--         return 0, 1043, nil
--     end

-- end

-- local result_pb = require("result_pb")
-- function NetPetSetCallback(fd)
--     cclog("NET type:%d cmd:%s recv response from gameserver", 1043, "PetSet")
--     local resultData = result_pb.Result()
--     resultData:ParseFromString(fd.rbuf)

--     if resultData.result then
--         gamedata.cache.petsdata.iid = gamedata.ext.petsetiid
--     end

--     return { type = 1043, petsdata = gamedata.cache.petsdata,}
-- end


local petxdata = {}
function UIPetLevel1UpCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1041, "PetLevel1Up")
    local doData = ids_pb.Ids()
    petxdata = {}
    if uireq.data then
        petxdata = uireq.data
        table.insert(doData.ids,uireq.iid)
        for k,v in pairs(uireq.data) do
            if v.iid and v.iid > 0 then
                table.insert(doData.ids,2)
                table.insert(doData.ids,v.iid)
                table.insert(doData.ids,v.num)
            else
                table.insert(doData.ids,1)
                table.insert(doData.ids,v.cid)
                table.insert(doData.ids,v.num)
            end
        end
    end


    return 1, 1041, doData:SerializeToString()
end

function NetPetLevel1UpCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1041, "PetLevel1Up")
    local DevilData = ids_pb.Ids()
    DevilData:ParseFromString(fd.rbuf)
    local status = {}
    for k,v in ipairs(DevilData.ids) do
        status[k] = v
    end

    local pet = {}
    local xg = {}
    local xf = {}
    for k,v in ipairs(status) do
        if k <= 5 then
            table.insert(pet,v)
        elseif math.mod(k,3) == 0 then
            if v == 1 then
                xf[tostring(status[k+1])] = status[k+2]
            elseif v == 2 then
                xg[tostring(status[k+1])] = status[k+2]
            end
        end
    end

    gamedata:setPetData(pet)


    for k,v in pairs(petxdata) do
        if v.iid and v.iid > 0 then
            if gamedata.cache.generals[v.iid] and xg[tostring(v.iid)] and xg[tostring(v.iid)] == 1 then
                local cid = gamedata.cache.generals[v.iid].cid
                gamedata.cache.generals[v.iid] = nil
                gamedata:updategeneralfragmentbynum({cid = cid, num =0})
            end
        elseif xf[tostring(v.cid)] then
            gamedata:updategeneralfragmentbynum({cid = v.cid, num = 0-xf[tostring(v.cid)]})
        end
    end
    petxdata = {}
    return { type = 1041, petsdata = gamedata.cache.petsdata,}
end


function UIPetLevel2UpCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1042, "PetLevel2Up")

    local idsData = ids_pb.Ids()

    if uireq.iid then
        gamedata.ext.petupiid = uireq.iid
        gamedata.ext.petupxids = uireq.xids or {}
        table.insert(idsData.ids, uireq.iid)
        for k,v in pairs(gamedata.ext.petupxids) do
           if v.cid == 1000 then
              if gamedata.cache.role.coin < v.num then
                  --return 0,503,{type = 503, msg = "银币不足" }
                    return  0, 503, {type = 503, msgtype = "shortcoin"}
              end
           elseif gamedata.IDconfig(v.cid) and gamedata.IDconfig(v.cid).staffType and gamedata.IDconfig(v.cid).staffType == "pet_fragment" then
               if not gamedata.cache.petsfragment[v.cid] or gamedata.cache.petsfragment[v.cid].num < v.num then
                  return 0,503,{type = 503, msg = "进阶道具不足" }
               end
           elseif not gamedata.cache.props[v.cid] or gamedata.cache.props[v.cid].num < v.num then
               return 0,503,{type = 503, msg = "进阶道具不足" }
           end
        end
        return 1, 1042, idsData:SerializeToString()
    else
        return 0, 1042, nil
    end

end

function NetPetLevel2UpCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1042, "PetLevel2Up")

    local resultData = result_pb.Result()
    resultData:ParseFromString(fd.rbuf)

    if resultData.result then
        for k,v in pairs(gamedata.cache.petsdata.pets) do
            if v.iid == gamedata.ext.petupiid then
               v.level2 = v.level2+1
            end
        end
        for k,v in pairs(gamedata.ext.petupxids) do
            if v.cid == 1000 then
                gamedata.cache.role.coin = gamedata.cache.role.coin - v.num
            elseif gamedata.IDconfig(v.cid) and gamedata.IDconfig(v.cid).staffType and gamedata.IDconfig(v.cid).staffType == "pet_fragment" then
--                if gamedata.cache.petsfragment[v.cid] then
--                    gamedata.cache.petsfragment[v.cid].num = gamedata.cache.petsfragment[v.cid].num - v.num
--                end
                gamedata:updatePetsFragment({cid=v.cid,num = -v.num})
            elseif gamedata.cache.props[v.cid] then
                gamedata.cache.props[v.cid].num = gamedata.cache.props[v.cid].num - v.num
            end
        end
    end


    return { type = 1042, petsdata = gamedata.cache.petsdata,}
end


---------------------------------------新版接口---------------------------------------
---------------------------------------新版接口---------------------------------------
---------------------------------------新版接口---------------------------------------

-- 魔宠查询
function UIPetQueryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1040, "PetQuery")
    if uireq.param and uireq.param == "error" then  return 1, 1040, nil end

--    if next(gamedata.cache.petsdata) then
--        print("out1040")
--        return 0, 1040, {type = 1040, petsdata = gamedata.cache.petsdata,}
--    end
    -- print("in1040")
    return 1, 1040, nil
end

function NetPetQueryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1040, "PetQuery")
    local petData = ids_pb.Ids()
    petData:ParseFromString(fd.rbuf)

    gamedata:PetsData(petData.ids)

    return { type = 1040, petsdata = gamedata.cache.petsdata,}
end

-- 魔宠上阵
function UIPetSetCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1043, "PetSet")
    -- print("UIPetSetCallback==")
    -- printT(uireq)
    local idsData = ids_pb.Ids()

    if uireq.iid then
        gamedata.ext.petsetiid = uireq.iid
        table.insert(idsData.ids, uireq.iid)
        return 1, 1043, idsData:SerializeToString()
    -- else
    --     return 0, 1043, nil
    end

end

local result_pb = require("result_pb")
function NetPetSetCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1043, "PetSet")
    -- local resultData = result_pb.Result()
    -- resultData:ParseFromString(fd.rbuf)

    -- print("NetPetSetCallback==")

    local petData = ids_pb.Ids()
    petData:ParseFromString(fd.rbuf)
    gamedata:PetPassiveSkillData(petData.ids)

    gamedata.cache.petsdata.iid = gamedata.ext.petsetiid

    return { type = 1043, petsdata = gamedata.cache.petsdata, skilldata = gamedata.cache.petpassiveskill,}
end

-- 魔宠碎片查询
function UIPetFragmentCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1044, "PetFragment")
    printT(gamedata.cache.petsfragment)

    if uireq.param and uireq.param == "error" then  return 1, 1044, nil end


    if next(gamedata.cache.petsfragment) then
        -- print("out1044")
        return 0, 1044, {type = 1044, fragment = gamedata.cache.petsfragment}
    else
        -- print("in1044")
        return 1, 1044, nil
    end
end


function NetPetFragmentCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1044, "PetFragment")
    local data = idnums_pb.IdNums()
    data:ParseFromString(fd.rbuf)

    gamedata:PetsFragments(data)

    return { type = 1044, fragment = gamedata.cache.petsfragment,}
end

-- 魔宠进阶
function UIPetStageUpCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1046, "PetFragment")
    -- print("UIPetStageUpCallback==")
    -- printT(uireq)
    local idsData = ids_pb.Ids()

    gamedata.ext.petstageup = uireq

    table.insert(idsData.ids, uireq.iid)

    return 1, 1046, idsData:SerializeToString()
   
end


function NetPetStageUpCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1046, "PetFragment")
    -- print("NetPetStageUpCallback111==")
    -- local resultData = result_pb.Result()
    -- resultData:ParseFromString(fd.rbuf)
    local petData = ids_pb.Ids()
    petData:ParseFromString(fd.rbuf)

    gamedata:PetPassiveSkillData(petData.ids)



    -- print("NetPetStageUpCallback==",resultData.result)
    -- if resultData.result then
        -- gamedata:SetPetStageUp()

        local petiid = gamedata.ext.petstageup.iid
        local spenddata = gamedata.ext.petstageup.spenddata
        -- printT(spenddata)

        for k,v in pairs(gamedata.cache.petsfragment) do
            if v.cid == spenddata[tostring(1)].cid then
                v.num = v.num - spenddata[tostring(1)].num
                break
            end
        end
        -- printT(gamedata.cache.petsdata["pets"])
        -- print("iid===,",gamedata.ext.petstageup.iid)
        -- printT(gamedata.cache.petsdata["pets"][tostring(gamedata.ext.petstageup.iid)])

        gamedata.cache.petsdata["pets"][tonumber(gamedata.ext.petstageup.iid)].level = gamedata.cache.petsdata["pets"][tonumber(gamedata.ext.petstageup.iid)].level + 1

        gamedata.cache.props[tonumber(spenddata[tostring(2)].cid)].num = gamedata.cache.props[tonumber(spenddata[tostring(2)].cid)].num - tonumber(spenddata[tostring(2)].num)
        
        gamedata:updateRoleCoin(0-tonumber(spenddata[tostring(3)].num),"进阶消耗",1)

        if spenddata[tostring(4)] and spenddata[tostring(4)].cid then
            gamedata.cache.props[tonumber(spenddata[tostring(4)].cid)].num = gamedata.cache.props[tonumber(spenddata[tostring(4)].cid)].num - tonumber(spenddata[tostring(4)].num)
        end

        local spend = {}
        -- print("spenddataadvance-===",spenddata[tostring(2)].cid,gamedata.cache.props[tonumber(spenddata[tostring(2)].cid)].num)
        spend[spenddata[tostring(2)].cid] = gamedata.cache.props[tonumber(spenddata[tostring(2)].cid)] and gamedata.cache.props[tonumber(spenddata[tostring(2)].cid)].num or 0
        -- printT(spend)
        if spenddata[tostring(4)] and spenddata[tostring(4)].cid then
            spend[spenddata[tostring(4)].cid] = gamedata.cache.props[tonumber(spenddata[tostring(4)].cid)] and gamedata.cache.props[tonumber(spenddata[tostring(4)].cid)].num or 0
        end
    return { type = 1046, fragment = gamedata.cache.petsfragment, petsdata = gamedata.cache.petsdata, skilldata = gamedata.cache.petpassiveskill,spendprops=spend}
end

-- 魔宠被动技能查询
function UIPetPassiveSkillCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1047, "etPassiveSkill")
    -- print("UIPetPassiveSkillCallback")
--    if next(gamedata.cache.petpassiveskill) and uireq.updata == nil then
--        -- print("out1047")
--        return 0, 1047, {type = 1047, skilldata = gamedata.cache.petpassiveskill}
--    end
    -- print("in1047")
    return 1, 1047, nil
end

function NetPetPassiveSkillCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1047, "etPassiveSkill")
    -- print("NetPetPassiveSkillCallback")
    local petData = ids_pb.Ids()
    petData:ParseFromString(fd.rbuf)

    gamedata:PetPassiveSkillData(petData.ids)
    -- printT(gamedata.cache.petpassiveskill)

    return { type = 1047, skilldata = gamedata.cache.petpassiveskill,}
end

-- 魔宠被动技能学习升级
function UIPetPassiveSkillStudyCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1048, "etPassiveSkill")
    -- print("UIPetPassiveSkillStudyCallback")
    return 1, 1048, nil
end

function NetPetPassiveSkillStudyCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1048, "etPassiveSkill")
    -- print("NetPetPassiveSkillStudyCallback")
    local petData = ids_pb.Ids()
    petData:ParseFromString(fd.rbuf)

    gamedata:PetPassiveSkillData(petData.ids)
    -- printT(gamedata.cache.petpassiveskill)

    return { type = 1048, skilldata = gamedata.cache.petpassiveskill,}
end

-- 魔宠被动技能锁定
function UIPetPassiveSkillLockCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1060, "PetPassiveSkillLock")
    -- print("UIPetPassiveSkillLockCallback")
    -- printT(uireq)
    local petData = ids_pb.Ids()

    gamedata.ext.passiveSkillLock = uireq

    table.insert(petData.ids,uireq.id)

    return 1, 1060, petData:SerializeToString()
end

function NetPetPassiveSkillLockCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1060, "PetPassiveSkillLock")
    -- print("NetPetPassiveSkillLockCallback")
    local resultData = result_pb.Result()
    resultData:ParseFromString(fd.rbuf)

    -- print("NetPetPassiveSkillLockCallback==",resultData.result)
    -- print("locknum=",gamedata.ext.passiveSkillLock.lock)
    -- printT(gamedata.cache.petpassiveskill["skill"])
    if resultData.result then
        if tonumber(gamedata.ext.passiveSkillLock.lock) == 0 then
            gamedata.cache.petpassiveskill["skill"][tonumber(gamedata.ext.passiveSkillLock.id)].lock = 1
        else
            gamedata.cache.petpassiveskill["skill"][tonumber(gamedata.ext.passiveSkillLock.id)].lock = 0
        end
    end

    return { type = 1060, skilldata = gamedata.cache.petpassiveskill,}
end

-- 魔宠被动技能重置
function UIPetPassiveSkillResetCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1061, "etPassiveSkillReset")
    -- print("UIPetPassiveSkillResetCallback")
    -- printT(uireq)
    gamedata.ext.petPassiveSkillResetSpend = uireq.spend
    return 1, 1061, nil
end

function NetPetPassiveSkillResetCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1061, "etPassiveSkillReset")
    -- print("NetPetPassiveSkillResetCallback")
    local petData = ids_pb.Ids()
    petData:ParseFromString(fd.rbuf)

    gamedata:PetPassiveSkillData(petData.ids)
    -- printT(gamedata.cache.petpassiveskill)

    gamedata:updateRoleGold(0-tonumber(gamedata.ext.petPassiveSkillResetSpend),"魔宠被动技能重置",1)
    

    return { type = 1061, skilldata = gamedata.cache.petpassiveskill,}
end

-- 魔宠碎片合成
function UIPetBagCompoundCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1049, "petBagCompound")
    print("UIPetBagCompoundCallback")
    printT(uireq)
    gamedata.ext.petBagCompound = uireq.petBagCompound
    local idsData = ids_pb.Ids()
    if uireq.cid then
        
        table.insert(idsData.ids, uireq.cid)
        return 1, 1049, idsData:SerializeToString()
    end
end

function NetPetBagCompoundCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1049, "petBagCompound")
    print("NetPetBagCompoundCallback===")
    printT(gamedata.cache.petsfragment)
    local petData = ids_pb.Ids()
    petData:ParseFromString(fd.rbuf)
    gamedata:PetBagCompoundData(petData.ids)
    gamedata.cache.petsdata["pets"][tonumber(gamedata.cache.petBagCompound.data.iid)] = gamedata.cache.petBagCompound.data
    
    for k,v in pairs(gamedata.cache.petsfragment) do
        print("petBagCompoundcid===",v.cid,gamedata.ext.petBagCompound.cid)
        if tonumber(v.cid) == tonumber(gamedata.ext.petBagCompound.cid) then
            print("inbagcom")
            printT(v)
            -- if tonumber(v.num) - tonumber(gamedata.ext.petBagCompound.useNum) <= 0 then
                -- table.remove(gamedata.cache.petsfragment,k) 
                -- print("kkkkkk==",k)
                -- printT(gamedata.cache.petsfragment[tonumber(k)])
                -- gamedata.cache.petsfragment[tonumber(k)]= nil
                -- v = nil
            -- else
                v.num = v.num - tonumber(gamedata.ext.petBagCompound.useNum)
            -- end
            printT(v)
            break
        end
    end
    print("NetPetBagCompoundCallback=end==")
    printT(gamedata.cache.petsfragment)
    return { type = 1049, compoundData = gamedata.cache.petBagCompound,}
end



function UIPetLevel1Up2Callback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1062, "Petup")
    local idsData = ids_pb.Ids()
    if uireq.iid then
        table.insert(idsData.ids, uireq.iid)

        gamedata.ext.petlvup_iid = uireq.iid or 0
        gamedata.ext.petlvup_need = uireq.need or {}

        for k,v in pairs(gamedata.ext.petlvup_need) do
            if v.cid == 1001 then
                if v.num > gamedata.cache.role.gold then
                    return 0,503,{type = 503, msgtype = "shortgold" }
                end
            elseif v.cid == 1000 then
                if v.num > gamedata.cache.role.coin then
                    return 0,503,{type = 503, msgtype = "shortcoin" }
                end
            else
                if gamedata.getStaffNum(v.cid).num < v.num then
                    return 0,503,{type = 503,msgtype = "shortprop",id= v.cid,num= v.num}
                end
            end
        end

        return 1, 1062, idsData:SerializeToString()
    end
end

function NetPetLevel1Up2Callback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1062, "Petup")
    local petData = ids_pb.Ids()
    petData:ParseFromString(fd.rbuf)

    gamedata:PetsData(petData.ids)

    if gamedata.ext.petlvup_need and next(gamedata.ext.petlvup_need) then
        for k,v in pairs(gamedata.ext.petlvup_need) do
            gamedata:updateStaff({cid = v.cid,num = 0-v.num})
        end
    end

    return { type = 1062, petsdata = gamedata.cache.petsdata, iid = gamedata.ext.petlvup_iid,}
end

--[1064] = UIPetPassiveSkillRedCallback,

function UIPetPassiveSkillRedCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1064, "UIPetPassiveSkillRedCallback")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id)
    return 1, 1064, idsData:SerializeToString()
end

function NetPetPassiveSkillRedCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1064, "NetPetPassiveSkillRedCallback")

    local petData = ids_pb.Ids()
    petData:ParseFromString(fd.rbuf)

    gamedata:PetPassiveSkillData(petData.ids)

    return { type = 1064, skilldata = gamedata.cache.petpassiveskill,}
end �y  