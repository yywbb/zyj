--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/1/30
-- Time: 下午6:45
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local idnums_pb = require("idnums_pb")

local hintByClient = {
    [2] = true,
    [3] = true,
    [4] = true,
    [5] = true,
    [158] = true,
    [24] = true,
    [25] = true,
    [26] = true,

    [6] = true,
    [115] = true,
    [366] = true,
    [398] = true,
    [599] = true,
}

function mekehintext(index,status)
    print("mekehintext",index,status)
    gamedata.cache.hint[index] = status
end

local relativehint = {
    [379] = {356,357},
}

local function makehintrelative()
    for k,v in pairs(relativehint) do
        gamedata.cache.hint[k] = 0
        for kk,vv in ipairs(v) do
            if gamedata.cache.hint[vv] and gamedata.cache.hint[vv] > 0 then
                gamedata.cache.hint[k] = 1
                break
            end
        end
    end
end


local function mekehint(index,status)
    --    print(index)
    --    printT(gamedata.config.build[tostring(index)])
    --    printT(gamedata.cache.role)

    if gamedata.config.build[tostring(index)] and gamedata.config.build[tostring(index)].level > gamedata.cache.role.level then
        gamedata.cache.hint[index] = 0
    elseif gamedata.cache.stasrtactivityDay and index >=82 and index <= 109 and (index-81) > gamedata.cache.stasrtactivityDay*4 then
        gamedata.cache.hint[index] = 0
    elseif hintByClient[index] then
    elseif index == 212 then
        local servicewarday = gamedata.config.global_kv.cross_battle_openday and tonumber(gamedata.config.global_kv.cross_battle_openday.value) or 0
        if (gamedata:time() - gamedata.cache.role.servertime) > servicewarday*86400 then
            gamedata.cache.hint[index] = status
        else
            gamedata.cache.hint[index] = 0
        end
    else
        gamedata.cache.hint[index] = status
    end

    makehintrelative()
end

local hintupdatelist = {
    [38] = {type = 3100,update = true},
    [80] = {type = 3100,update = true},
    [81] = {type = 3100,update = true},

    [37] = {type = 2300,param = 1},
    [127] = {type = 2303},

    [39] = {type = 3000},
    [266] = {type = 3010},
    [267] = {type = 3015},

    [576] = {type = 2284, isNotOpen = true},  --篝火开始
    [575] = {type = 2274, isNotOpen = true},  --盛宴开始
}

function checkHintUpdate(id)
    print("checkHintUpdate",id)
    if gamedata.cache.hint[id] and gamedata.cache.hint[id] ~= 0 and hintupdatelist[id] then
        return  hintupdatelist[id]
    end
    return nil
end

function UIHintSlotCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 10322, "HintSlot")

    local hintsetfunc = {
        rob = makeTreasureRob,
        slotsinfo = makeSlotInfo,
        cheer = makeCheerInfo,
        gem = makeSlotGeminfo,
        generals = makeGeneralHint,
        protagonist = makeMogongHint,
        qiling = makeQilingHint,
        tokenBag = makeTokenBagHint,
    }
    if not uireq.param then
        for k,v in pairs(hintsetfunc) do
            v()
        end
    else
        for k,v in pairs(uireq.param) do
            hintsetfunc[v]()
        end
    end

    return 0,1032,{type = 1032, data =gamedata.cache.hint}
end

function UIHintArtifactCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 10323, "HintArtifact")
    if uireq.ids then
        for k,v in pairs(uireq.ids) do
            mekehintext(366,0)
        end
    end
    CheckArtifactAllHint(2)
    return 0,1032,{type = 1032, data =gamedata.cache.hint}
end

function UIHintResetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 10321, "HintReset")

    for k,v in pairs(uireq.ids) do
        if uireq.status then
            mekehint(v,tonumber(uireq.status))
        else    
            mekehint(v,0)
        end
        if gamedata.cache.hint_notupdate and uireq.notupdate and uireq.notupdate == 1 then
            gamedata.cache.hint_notupdate[tostring(v)] = 0
        end    
    end

    return 0,1032,{type = 1032, data =gamedata.cache.hint}
end

function UIHintCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1032, "Hint")

    printT("UIHintCallBack",uireq)
    gamedata.ext.hintids = {}
    if uireq.ids then
        local Hint = ids_pb.Ids()
        for k,v in pairs(uireq.ids) do
            table.insert(Hint.ids,v)
        end
        gamedata.ext.hintids = uireq.ids
        return 1, 1032, Hint:SerializeToString()
    else
        return 1, 1032, nil
    end
end

function NetHintCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1032, "Hint")
    local Hint = ids_pb.Ids()
    Hint:ParseFromString(fd.rbuf)

    if gamedata.ext.hintids and next(gamedata.ext.hintids) then
        for k=1,table.getTableLength(gamedata.ext.hintids) do
            if Hint.ids[k] then
                mekehint(gamedata.ext.hintids[tostring(k)],Hint.ids[k])
            end
        end
    else
        for k,v in ipairs(Hint.ids) do
            local id,num = math.floor(v/100),v%100
            if gamedata.cache.hint_notupdate and gamedata.cache.hint_notupdate[tostring(id)] then
                mekehint(id,gamedata.cache.hint_notupdate[tostring(id)])
            elseif id ~= 462 then
                mekehint(id,num)
            end
        end
    end
    gamedata.ext.hintids = nil
    return {type = 1032, data =gamedata.cache.hint}
end

function NetHintChangeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1034, "Hintchange")
    local Hint = idnums_pb.IdNums()
    Hint:ParseFromString(fd.rbuf)
    local hintChanges = {}
    if next(gamedata.cache.role) and gamedata.cache.role.level then
        local updatelist = {}
        for k,v in ipairs(Hint.idnums) do
            mekehint(v.id,v.num)
            hintChanges[v.id] = v.num
            updatelist[#updatelist+1] = checkHintUpdate(v.id)
        end
        return {type = 1032,hintChanges = hintChanges, data =gamedata.cache.hint, updatelist = updatelist}
    else
        return {type = 1032}
    end
end

function NetPowerchangeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 205, "Powerchange")
    local Powerchange = ids_pb.Ids()
    Powerchange:ParseFromString(fd.rbuf)

    local powerChange = Powerchange.ids[1]
    local power = Powerchange.ids[2]

    local g_powerChange = Powerchange.ids[3]
    local g_power = Powerchange.ids[4]

    local allPowerChange = Powerchange.ids[5]
    local allPower = Powerchange.ids[6]

    gamedata:updateRolePower(power,g_power,allPower)

    return {type = 205, powerChange = Powerchange.ids[5],f_power = gamedata.cache.role.f_power,g_power = gamedata.cache.role.g_power,power_all = allPower}
end
