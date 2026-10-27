--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 16/2/3
-- Time: 下午1:58
-- To change this template use File | Settings | File Templates.
--
local params_pb = require("params_pb")
local ids_pb = require("ids_pb")

function UISlotsArrangeQuaryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3702, "SlotsArrange")
    print("UISlotsArrangeQuaryCallback===")
    printT(uireq)
    gamedata.ext.slotarrangeparam = uireq.param2 or nil

    if gamedata.cache.commonSlots[uireq.id..uireq.param] then
        return 0, 3702, {
            type = 3702,
            slots = gamedata.cache.commonSlots[uireq.id..uireq.param],
            param = {id = uireq.id,param = uireq.param},
            slotarrangeparam = gamedata.ext.slotarrangeparam,
            generals = gamedata.cache.generals,
            protagonist = gamedata.cache.protagonist.general,
            pets = gamedata.cache.petsdata.pets or {},
        }
    end

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id)
    table.insert(idsData.ids, uireq.param or 0)

    return 1, 3702, idsData:SerializeToString()
end

function NetSlotsArrangeQuaryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3702, "SlotsArrange")
    local idsData = ids_pb.Ids()
    idsData:ParseFromString(fd.rbuf)

    local id,param = gamedata:CommonSlots(idsData)

    return {
        type = 3702,
        slots = gamedata.cache.commonSlots[id..param],
        param = {id=id,param=param},
        generals = gamedata.cache.generals,
        protagonist = gamedata.cache.protagonist.general,
        pets = gamedata.cache.petsdata.pets or {},
        slotarrangeparam = gamedata.ext.slotarrangeparam
    }
end

function UISlotsArrangeCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3703, "SlotsArrange")

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.param.id)
    table.insert(idsData.ids, uireq.param.param or 0)

    for i=1,table.getTableLength(uireq.generals) do
        table.insert(idsData.ids, uireq.generals[tostring(i)])
    end
    table.insert(idsData.ids, uireq.pet or 0)

    --gamedata.ext.slotarrangeparam =  {id = uireq.param.id,param = uireq.param.param or 0}

    return 1, 3703, idsData:SerializeToString()
end


function NetSlotsArrangeCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3703, "SlotsArrange")
    local idsData = ids_pb.Ids()
    idsData:ParseFromString(fd.rbuf)

    local id,param = gamedata:CommonSlots(idsData)

    return {
        type = 3703,
        slots = gamedata.cache.commonSlots[id..param],
        param = {id=id,param=param},
        generals = gamedata.cache.generals,
        protagonist = gamedata.cache.protagonist.general,
        pets = gamedata.cache.petsdata.pets or {},
    }
end


-- 乾坤炉化魂 需要排除的数据
function UISlotsExceptCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3704, "SlotsExcept")
    print("UISlotsExceptCallback===")
    gamedata.ext.GodSoulTemple = uireq.GodSoulTemple
    return 1, 3704, nil
end


function NetSlotsExceptCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3704, "SlotsExcept")
    print("NetSlotsExceptCallback==")
    local idsData = ids_pb.Ids()
    idsData:ParseFromString(fd.rbuf)

    
    -- printT("iids")
    if gamedata.ext.GodSoulTemple then
        gamedata.ext.GodSoulTemple = nil
        local iids = {}
        for k,v in ipairs(idsData.ids) do
            if gamedata.cache.generals[v] then

                printT(gamedata.cache.generals[v],"gamedata.cache.generals")
                iids[gamedata.cache.generals[v].cid] = true
            end
        end

        local slots = {}
        for k,v in pairs(gamedata.cache.slots) do
            if v.general and gamedata.cache.generals[v.general] then
                slots[gamedata.cache.generals[v.general].cid] = true
            end
        end

        local cheers = {}
        for k,v in pairs(gamedata.cache.cheers) do
            if v.general and gamedata.cache.generals[v.general] then
                cheers[gamedata.cache.generals[v.general].cid] = true
            end
        end

        return {
            type = 3704,
            slots = slots,
            cheers = cheers,
            iids = iids,
            generalfragments = gamedata.cache.generalfragments,
            GodSoulTemple = true
        }

    else
        local iids = {}
        for k,v in ipairs(idsData.ids) do
            print("idddsss",k,v)
            iids[v] = true
        end

        return {
            type = 3704,
            iids = iids
        }
    end
    
end


-- 敌方阵容查询
function UIEnemySlotsQuaryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3811, "SlotsEnemy")
    print("UISlotsArrangeQuaryCallback===")
    printT(uireq)
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id)
    gamedata.ext.enemyslotsspendnum = uireq.spendnum
    -- gamedata.ext.slotenemyid = uireq.id
    -- local enemySlotData = {140,0,28888,90001,8,10402,30,90,0,10403,31,91,2,10404,55,100,2,10409,50,20,7,10502,10,88,4,10511,1,22,3}
    -- gamedata:SetSlotsEnemy(enemySlotData)

    -- if gamedata.cache.commonSlots[gamedata.ext.slotarrangeparam.id..gamedata.ext.slotarrangeparam.param] then
        -- return 0, 3811, {
        --     type = 3811,
        --     slots = gamedata.cache.slotsEnemy,
            -- slotenemyid = gamedata.ext.slotenemyid,
            -- generals = gamedata.cache.generals,
            -- protagonist = gamedata.cache.protagonist.general,
            -- pets = gamedata.cache.petsdata.pets or {},
        -- }
    -- end

    -- local idsData = ids_pb.Ids()
    -- table.insert(idsData.ids, uireq.id)
    -- table.insert(idsData.ids, uireq.param or 0)

    return 1, 3811, idsData:SerializeToString()
end

function NetEnemySlotsQuaryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3811, "SlotsArrange")
    -- local idsData = ids_pb.Ids()
    -- idsData:ParseFromString(fd.rbuf)

    -- gamedata:SetSlotsEnemy(idsData.ids)


    local params = params_pb.ParamS()
    params:ParseFromString(fd.rbuf)
    gamedata:SetSlotsEnemy(params.params)


    local globle = gamedata.config.global_kv
    if gamedata.ext.enemyslotsspendnum and tonumber(gamedata.ext.enemyslotsspendnum) ~= 0 and  tonumber(gamedata.ext.enemyslotsspendnum) > 0 then
        print("迷宫扣费＝＝",tonumber(gamedata.ext.enemyslotsspendnum))
        gamedata:updateRoleGold(-tonumber(gamedata.ext.enemyslotsspendnum),"迷宫对方阵容刷新",1)
    end
    

    return {
        type = 3811,
        slots = gamedata.cache.slotsEnemy,
        -- slots = gamedata.cache.commonSlots[gamedata.ext.slotarrangeparam.id..gamedata.ext.slotarrangeparam.param],
        -- param = gamedata.ext.slotarrangeparam,
        -- generals = gamedata.cache.generals,
        -- protagonist = gamedata.cache.protagonist.general,
        -- pets = gamedata.cache.petsdata.pets or {},
    }
end

-- 带血条阵容查询
function UISlotsWithHpQuaryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3804, "SlotsArrange")
    print("UISlotsWithHpQuaryCallback===")
    -- printT(gamedata.cache.generals)
    printT(uireq)
    -- gamedata.ext.slotarrangeparam = {id = 140,param = 1 or 0 }
    -- local SlotData = {103888,140,21322,100,17405,20,14556,10,14560,80,14565,20,14520,90,18209,50,14695,50,15078,50,15079,50,19495,50}
    -- gamedata:CommonSlotsWithHp(SlotData)

    -- local generalTemp = table.copy(gamedata.cache.protagonist.general)
    -- generalTemp.hppercent = gamedata.cache.commonSlotsWithHp.slots.hpArr[tostring(generalTemp.iid)] or 0

    -- if gamedata.cache.commonSlots[gamedata.ext.slotarrangeparam.id..gamedata.ext.slotarrangeparam.param] then
        -- return 0, 3804, {
        --     type = 3804,
        --     slots = gamedata.cache.commonSlotsWithHp.slots,
        --     param = gamedata.ext.slotarrangeparam,
        --     generals = gamedata.cache.commonSlotsWithHp.generalsdata,
        --     protagonist = gamedata.cache.protagonist.general,
        --     pets = gamedata.cache.petsdata.pets or {},
        -- }
    -- end

    -- local idsData = ids_pb.Ids()
    -- table.insert(idsData.ids, uireq.id)
    -- table.insert(idsData.ids, uireq.param or 0)

    return 1, 3804, nil
end

function NetSlotsWithHpQuaryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3804, "SlotsArrange")
    print("NetSlotsWithHpQuaryCallback==")
    local idsData = ids_pb.Ids()
    idsData:ParseFromString(fd.rbuf)

    gamedata:CommonSlotsWithHp(idsData.ids)

    return {
        type = 3804,
        slots = gamedata.cache.commonSlotsWithHp.slots,
        param = gamedata.ext.slotarrangeparam,
        generals = gamedata.cache.commonSlotsWithHp.generalsdata,
        protagonist = gamedata.cache.protagonist.general,
        pets = gamedata.cache.petsdata.pets or {},
        slotid = gamedata.ext.slotArrangeId,
    }
end

-- 带血阵容修改
function UISlotsChangeWithHpCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3805, "SlotsArrange")
    print("UISlotsChangeWithHpCallback===")
    printT(uireq)
    local idsData = ids_pb.Ids()
    -- table.insert(idsData.ids, uireq.param.id)
    -- table.insert(idsData.ids, uireq.param.param or 0)

    for i=1,table.getTableLength(uireq.generals) do
        table.insert(idsData.ids, uireq.generals[tostring(i)])
    end
    table.insert(idsData.ids, uireq.pet or 0)

    -- gamedata.ext.slotarrangeparam =  {id = uireq.param.id,param = uireq.param.param or 0}

    return 1, 3805, idsData:SerializeToString()
end


function NetSlotsChangeWithHpCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3805, "SlotsArrange")
    print("NetSlotsWithHpQuaryCallback==")
    local idsData = ids_pb.Ids()
    idsData:ParseFromString(fd.rbuf)

    gamedata:CommonSlotsWithHp(idsData.ids)

    return {
        type = 3805,
        slots = gamedata.cache.commonSlotsWithHp.slots,
        param = gamedata.ext.slotarrangeparam,
        generals = gamedata.cache.commonSlotsWithHp.generalsdata,
        protagonist = gamedata.cache.protagonist.general,
        pets = gamedata.cache.petsdata.pets or {},
        slotid = gamedata.ext.slotArrangeId,
    }
end