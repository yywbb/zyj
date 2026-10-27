--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-29
-- Time: 下午2:01
-- To change this template use File | Settings | File Templates.
--
local slotccbconfig = {1,2,3,4,5,6,7,8 }

local function Generals(generalsdata,protagonist)
    local generals = {}
    for k,v in ipairs(generalsdata) do
        generals[v.iid] = gamedata:generalData(v,v.iid==protagonist.iid)
    end
    return generals
end

local function Equips(equipsdata)
    local equips = {}
    for k,v in ipairs(equipsdata) do
        equips[v.ids[1]] = gamedata:equipData(v)
    end
    return equips
end

local function Souls(soulsdata)
    local souls = {}
    for k,v in ipairs(soulsdata) do
        souls[v.iid] = gamedata:soulData(v)
    end
    return souls
end

local function Slots(slotsdata)
    local slots = {}
    for k,v in ipairs(slotsdata) do
        slots[v.sid] = gamedata:slotData(v)
    end
    return slots
end

local function Artifacts(artifactData)
    local artifacts = {}
    for k,v in ipairs(artifactData) do
        artifacts[v.params[1].i] = gamedata:artifactData(v.params)
    end
    return artifacts
end

local function Cheers(cheersdata)
    local cheers = {}
    for k,v in ipairs(cheersdata) do
        cheers[v.sid] = gamedata:cheerData(v)
    end
    return cheers
end

local function Gems(data)
    local gems = {}
    for k,v in ipairs(data) do
        gems[v.ids[1]] = gamedata:gemData(v)
    end
    return gems
end

local function slotGems(data)
    local slotgems = {}
    for i=1,8 do
        if data["f"..i] and data["f"..i].ids and data["f"..i].ids[1] then
            slotgems[i] = gamedata:slotgemData(data["f"..i].ids)
        end
    end
    return slotgems
end

local function makeMofuSortInfo(data)
    local mofudata = {}
    for k,v in pairs(data) do
        table.insert(mofudata,v)
    end
    for i,v in ipairs(mofudata) do
        local mofuconfig = gamedata.config.sigil
        v.temp = gamedata.config.sigil[tostring(v.cid)]
    end

    local sortFunc = function( a, b )
        if  a["temp"]["order"] < b["temp"]["order"] then
            return true
        elseif a["temp"]["order"] > b["temp"]["order"] then
            return false
        else
            -- if a["exp"] < b["exp"] then
            --     return false
            -- else
            --     return true
            -- end
        end

    end
    table.sort(mofudata,sortFunc)

    return mofudata
end

local function Protagonist(protagonistdata)
    return gamedata:ProtagonistData(protagonistdata)
end

local function makeSlotInfo_(slots,generals,equips,souls,protagonist,artifacts)

    local slotconfig = gamedata.config.role_exp
    local opennum = slotconfig[tostring(gamedata.ext.otherlevel)] and slotconfig[tostring(gamedata.ext.otherlevel)].slotnum or 7

    local slots_ = {}

    for k=1,7 do

        if slots[k] and slots[k].general and slots[k].general ~= 0 then
            local v = table.copy(slots[k])
            v.power = generals[v.general].power
            v.general = generals[v.general]

            v.weapon = equips[v.weapon or {}]
            v.armor = equips[v.armor or {}]
            v.accessory = equips[v.accessory or {}]
            v.head = equips[v.head or {}]
            v.treasure = equips[v.treasure or {}]
            v.horse = equips[v.horse or {}]
            v.newartifact = artifacts[v.newartifact]
            for i = 1,8 do
                if v["s"..slotccbconfig[i]] and v["s"..slotccbconfig[i]] ~= 0 then
                    v["s"..i] = table.merge(souls[v["s"..slotccbconfig[i]]],{soulpos = slotccbconfig[i]})
                else
                    v["s"..i] = {soulpos = slotccbconfig[i]}
                end
            end
            table.insert(slots_,v)
        end
    end

    return slots_
end

local function makeCheerInfo(cheer,generals)

    local slotconfig_old = gamedata.config.general_cheer
    local slotconfig = gamedata.config.role_exp
    local opennum = slotconfig[tostring(gamedata.ext.otherlevel)] and slotconfig[tostring(gamedata.ext.otherlevel)].cheernum or 8
    for k=1,8 do
        if k <= opennum then
            if cheer[k]  then
                local v = cheer[k]
                cheer[k].general = generals[v.general]
            else
                cheer[k] = {sid = k,isopen = true}
            end
        else
            cheer[k] = {sid = k,openlevel = slotconfig_old[tostring(k)]}
        end
    end

    return cheer
end


local ids_pb = require("ids_pb")
function UICheckOtherSlotsInfoCallBack(uireq)
    print("请求其他人阵容，装备等1020 接收UI请求")

    local IDS = ids_pb.Ids()
    table.insert(IDS.ids, uireq.rid)
    gamedata.ext.otherlevel = uireq.level

   return 1, 1020, IDS:SerializeToString()
end

local slots_pb = require("slots_pb")
function NetCheckOtherSlotsInfoCallBack(fd)
    print("请求其他人阵容，装备等1020 接收服务器返回数据")
    local info = slots_pb.SlotS()
    info:ParseFromString(fd.rbuf)

    local generals = Generals(info.generals,info.protagonist)
    local equips = Equips(info.equips) --属于 阵位
    local souls = Souls(info.souls)--属于 阵位
    local slots = Slots(info.slots)-- 属于 阵位
    local cheers = Cheers(info.cheers)--属于 阵位
    local protagonist = Protagonist(info.protagonist)
    local gems = makeMofuSortInfo(Gems(info.gems))--魔zao
    local slotgems = slotGems(info)
    local artifacts = Artifacts(info.newartifacts or {})--神石、魔罩 属于阵容
    local exclusiveArtifactDatas = {}
    for i,v in ipairs(info.exclartifacts) do--幻化 属于武将
        local exclusiveArtifactData = gamedata:ExclusiveArtifactDatas(v.ids,true)
        for i2,v2 in ipairs(exclusiveArtifactData) do
            table.insert(exclusiveArtifactDatas,v2)
        end
    end
    local exclusiveArtifactQiLingDatas = {}
    for i,v in ipairs(info.qiling) do--
        local exclusiveArtifactQiLingData = gamedata:ExclusiveArtifactQiLingDatas(v.ids,true)
        for i2,v2 in ipairs(exclusiveArtifactQiLingData) do
            table.insert(exclusiveArtifactQiLingDatas,v2)
        end
    end

    gamedata:findcombskilllevel(generals,slots,cheers,protagonist.iid)

    return {type= 1020, slots = makeSlotInfo_(slots,generals,equips,souls,protagonist,artifacts), cheers = makeCheerInfo(cheers,generals), protagonist = protagonist, gems = gems, slotgems = slotgems,exclusiveArtifactDatas = exclusiveArtifactDatas,exclusiveArtifactQiLingDatas = exclusiveArtifactQiLingDatas}
end

--

function UIWorldWarChampionSlotInfoCallBack(uireq)
    print("4719 请求跨服战冠军阵容， 接收UI请求")

    local IDS = ids_pb.Ids()
    table.insert(IDS.ids, uireq.rid)
    gamedata.ext.otherlevel = uireq.level

    return 1, 4719, IDS:SerializeToString()
end

function NetWorldWarChampionSlotInfoCallBack(fd)
    print("4719 请求跨服战冠军阵容，接收服务器返回数据")
    local info = slots_pb.SlotS()
    info:ParseFromString(fd.rbuf)

    local generals = Generals(info.generals,info.protagonist)
    local equips = Equips(info.equips)
    local souls = Souls(info.souls)
    local slots = Slots(info.slots)
    local cheers = Cheers(info.cheers)
    local protagonist = Protagonist(info.protagonist)
    local gems = makeMofuSortInfo(Gems(info.gems))
    local slotgems = slotGems(info)
    local artifacts = Artifacts(info.newartifacts or {})
    local exclusiveArtifactDatas = {}
    for i,v in ipairs(info.exclartifacts) do
        local exclusiveArtifactData = gamedata:ExclusiveArtifactDatas(v.ids,true)
        for i2,v2 in ipairs(exclusiveArtifactData) do
            table.insert(exclusiveArtifactDatas,v2)
        end
    end


    local exclusiveArtifactQiLingDatas = {}
    for i,v in ipairs(info.qiling) do
        local exclusiveArtifactQiLingData = gamedata:ExclusiveArtifactQiLingDatas(v.ids,true)
        for i2,v2 in ipairs(exclusiveArtifactQiLingData) do
            table.insert(exclusiveArtifactQiLingDatas,v2)
        end
    end

    gamedata:findcombskilllevel(generals,slots,cheers,protagonist.iid)

    return {type= 4719, slots = makeSlotInfo_(slots,generals,equips,souls,protagonist,artifacts), cheers = makeCheerInfo(cheers,generals), protagonist = protagonist, gems = gems, slotgems = slotgems,exclusiveArtifactDatas = exclusiveArtifactDatas,exclusiveArtifactQiLingDatas = exclusiveArtifactQiLingDatas}
end