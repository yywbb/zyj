--
-- Created by IntelliJ IDEA.
-- User: lichungeng
-- Date: 16/6/17
-- Time: 上午9:55
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")


local function tigerchickenData(ids)
    gamedata.cache.tigerchicken = {}
    gamedata.cache.tigerchicken.lucky = ids.ids[1]
    gamedata.cache.tigerchicken.points = ids.ids[2]
    gamedata.cache.tigerchicken.freetime = ids.ids[3]
end

-- 老虎机查询
function UITigerchickenQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1406, "Tigerchicken")

--    if gamedata.cache.tigerchicken and next(gamedata.cache.tigerchicken) then
--        return 0, 1406, { type = 1406, data = gamedata.cache.tigerchicken,}
--    else
        return 1, 1406, nil
--    end

end

function NetTigerchickenQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1406, "Tigerchicken")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    tigerchickenData(ids)

    return { type = 1406, data = gamedata.cache.tigerchicken,}
end


-- 老虎机抽奖
function UITigerchickenDoCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1407, "TigerchickenDo")
    local ids = ids_pb.Ids()
    local isenough,ret = gamedata.checkStaffEnough(uireq.useId,uireq.useNum,{})
    if not isenough then
        return 0,503,ret
    end
    gamedata.ext.laohujiconsum = {cid=uireq.useId,num = -uireq.useNum}
    
    table.insert(ids.ids,uireq.method)
    return 1, 1407, ids:SerializeToString()
end

local combmessages_pb = require("combmessages_pb")
function NetTigerchickenDoCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1407, "TigerchickenDo")
    local reps = combmessages_pb.CombMessages()
    reps:ParseFromString(fd.rbuf)

    local getindex = {}
    local reward = {}

    for k,v in ipairs(reps.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            for kk,vv in ipairs(ids.ids) do
                table.insert(getindex,vv)
            end
        elseif v.id == 1 then
            local getData = somethings_pb.SomeThings()
            getData:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(getData)
        elseif v.id == 2 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            tigerchickenData(ids)
        end
    end

    --gamedata:updateRoleGold(0-(gamedata.ext.laohujiconsum or 0))
    gamedata:updateStaff(gamedata.ext.laohujiconsum)

    return { type = 1407, reward = reward, getindex = getindex, data = gamedata.cache.tigerchicken}
end

local function tigerchickenshopData(ids)
    gamedata.cache.tigerchickenshop = {}
    for k,v in ipairs(ids.ids) do
        table.insert(gamedata.cache.tigerchickenshop,v)
    end
end

-- 老虎机商店查询
function UITigerchickenshopQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1408, "Tigerchickenshop")

--    if gamedata.cache.tigerchickenshop and next(gamedata.cache.tigerchickenshop) then
--        return 0, 1408, { type = 1408, data = gamedata.cache.tigerchickenshop,}
--    else
        return 1, 1408, nil
--    end

end

function NetTigerchickenshopQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1408, "Tigerchickenshop")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    tigerchickenshopData(ids)

    return { type = 1408, data = gamedata.cache.tigerchickenshop,}
end

-- 老虎机商店兑换
function UITigerchickenshopExchangeCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1409, "Tigerchickenshop")


    local _config = gamedata.dailyCpActivityConfig("new_generals_exchange",45)
    local config = _config[tostring(uireq.pos)]

    if config.limit and config.limit >0 and gamedata.cache.tigerchickenshop[uireq.pos] >= config.limit then
        return 0,503,{type = 503,msg = 987}
    elseif config.number and config.number ~= "" then
        local pointid,needpoints = gamedata.getIDandNUM(config.number)
        if (gamedata.cache.tigerchicken.points or 0) < needpoints then
           return 0,503,{type = 503,msgtype = "shortprop",id= pointid,num= needpoints}
        end
    elseif config.num and config.num ~= "" then
        local propid,propnum = gamedata.getIDandNUM(config.num)
        if gamedata.getStaffNum(propid).num < propnum then
            return 0,503,{type = 503,msgtype = "shortprop",id= propid,num= propnum}
        end
    end
    gamedata.ext.tigerchickenpos = uireq.pos

    local ids = ids_pb.Ids()
    table.insert(ids.ids,uireq.pos)
    print("uireq.num == "..uireq.num)
    if uireq.num then
        table.insert(ids.ids,uireq.num)
        gamedata.ext.tigerchickennum = uireq.num
    end
    return 1, 1409, ids:SerializeToString()
end

function NetTigerchickenshopExchangeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1409, "Tigerchickenshop")

    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    local _config = gamedata.dailyCpActivityConfig("new_generals_exchange",45)
    local config = _config[tostring(gamedata.ext.tigerchickenpos)]
    gamedata.cache.tigerchickenshop[gamedata.ext.tigerchickenpos] = gamedata.cache.tigerchickenshop[gamedata.ext.tigerchickenpos] + (gamedata.ext.tigerchickennum or 1)

    if config.number and config.number ~= "" then
        local pointid,needpoints = gamedata.getIDandNUM(config.number) 
        gamedata.cache.tigerchicken.points = gamedata.cache.tigerchicken.points - needpoints*(gamedata.ext.tigerchickennum or 1)
    end

    if config.num and config.num ~= "" then
        local propid,propnum = gamedata.getIDandNUM(config.num)
        gamedata:updateStaff({cid = propid,num = 0-propnum * (gamedata.ext.tigerchickennum or 1)})
    end


    return { type = 1409, reward = gamedata:SomethingProcess(getData),}
end


--
--[3860] = UIGamblingCallback,
--[3861] = UIGamblingRewardCallback,

function UIGamblingCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3860, "UIGamblingCallback")

    return 1, 3860, nil

end

function NetGamblingCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3860, "NetGamblingCallback")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local gambling = {}
    gambling.pointnum = ids.ids[1] or 0
    gambling.propid1 = ids.ids[2] or 0
    gambling.propid2 = ids.ids[3] or 0
    gambling.propid3 = ids.ids[4] or 0

    local costid = 1021
    local costone = 0
    if gamedata.config.global_kv["game_consoles_consume"] and tonumber(gamedata.config.global_kv["game_consoles_consume"].value) then
        costid = 1021
    else
        costid,costone = gamedata.getIDandNUM(gamedata.config.global_kv["game_consoles_consume"].value)
    end    

    return { type = 3860, gambling = gambling,hasnum = gamedata.getStaffNum(costid).num or 0}
end


function UIGamblingRewardCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3861, "UIGamblingRewardCallback")

    local ids = ids_pb.Ids()

    table.insert(ids.ids,uireq.num or 1)
    gamedata.ext.gamblingdonum = uireq.num or 1


    return 1, 3861, ids:SerializeToString()
end

function NetGamblingRewardCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3861, "NetGamblingRewardCallback")
    local reps = combmessages_pb.CombMessages()
    reps:ParseFromString(fd.rbuf)

    local reward = {}
    local gambling = {}
    for k,v in ipairs(reps.messages) do
        if v.id == 1 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gambling.pointnum = ids.ids[1] or 0
            gambling.propid1 = ids.ids[2] or 0
            gambling.propid2 = ids.ids[3] or 0
            gambling.propid3 = ids.ids[4] or 0
        elseif v.id == 2 then
            local getData = somethings_pb.SomeThings()
            getData:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(getData)
        end
    end

    local costid = 1021
    local costone = 0
    if gamedata.config.global_kv["game_consoles_consume"] and tonumber(gamedata.config.global_kv["game_consoles_consume"].value) then
        costid = 1021
        costone = tonumber(gamedata.config.global_kv["game_consoles_consume"].value) or 0
    else
        costid,costone = gamedata.getIDandNUM(gamedata.config.global_kv["game_consoles_consume"].value)
    end 
    if (costid > 0) and (costone > 0) then
        gamedata:updateStaff({cid = costid,num = 0-costone * (gamedata.ext.gamblingdonum or 1)})
    end

    return { type = 3861, reward = reward, gambling = gambling,hasnum = gamedata.getStaffNum(costid).num or 0}
end

-- 777老虎机商店查询
function UIGamblingShopCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3862, "UIGamblingShopCallback")


    return 1, 3862, nil

end

function NetGamblingShopCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3862, "UIGamblingShopCallback")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata.cache.gamblingshop = {}
    gamedata.cache.gamblingpoints = ids.ids[1] or 0

    for k,v in ipairs(ids.ids) do
        if k > 1 then
            table.insert(gamedata.cache.gamblingshop,v)
        end
    end

    local costid = 1021
    local costone = 0
    if gamedata.config.global_kv["game_consoles_consume"] and tonumber(gamedata.config.global_kv["game_consoles_consume"].value) then
        costid = 1021
    else
        costid,costone = gamedata.getIDandNUM(gamedata.config.global_kv["game_consoles_consume"].value)
    end    

    return { type = 3862, data = gamedata.cache.gamblingshop, points = gamedata.cache.gamblingpoints,hasnum = gamedata.getStaffNum(costid).num or 0}
end

-- 777老虎机商店兑换
function UIGamblingShopRewardCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3863, "UIGamblingRewardCallback")

    local config = gamedata.config.game_consoles_shop[tostring(uireq.pos)]

    if config.limit and config.limit >0 and gamedata.cache.gamblingshop[uireq.pos] >= config.limit then
        return 0,503,{type = 503,msg = 987}
    elseif config.number and config.number ~= "" then
        local pointid,needpoints = gamedata.getIDandNUM(config.number)
        if (gamedata.cache.gamblingpoints or 0) < needpoints then
            return 0,503,{type = 503,msgtype = "shortprop",id= pointid,num= needpoints}
        end
    elseif config.num and config.num ~= "" then
        local propid,propnum = gamedata.getIDandNUM(config.num)
        if gamedata.getStaffNum(propid).num < propnum then
            return 0,503,{type = 503,msgtype = "shortprop",id= propid,num= propnum}
        end
    end
    gamedata.ext.gamblingshoppos = uireq.pos

    local ids = ids_pb.Ids()
    table.insert(ids.ids,uireq.pos)
    print("uireq.num == "..uireq.num)
    if uireq.num then
        table.insert(ids.ids,uireq.num)
        gamedata.ext.gamblingshopnum = uireq.num
    end
    return 1, 3863, ids:SerializeToString()
end

function NetGamblingShopRewardCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3863, "UIGamblingRewardCallback")

    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    local config = gamedata.config.game_consoles_shop[tostring(gamedata.ext.gamblingshoppos)]
    gamedata.cache.gamblingshop[gamedata.ext.gamblingshoppos] = gamedata.cache.gamblingshop[gamedata.ext.gamblingshoppos] + (gamedata.ext.gamblingshopnum or 1)

    if config.number and config.number ~= "" then
        local pointid,needpoints = gamedata.getIDandNUM(config.number)
        gamedata.cache.gamblingpoints = gamedata.cache.gamblingpoints - needpoints*(gamedata.ext.gamblingshopnum or 1)
    end

    if config.num and config.num ~= "" then
        local propid,propnum = gamedata.getIDandNUM(config.num)
        gamedata:updateStaff({cid = propid,num = 0-propnum * (gamedata.ext.gamblingshopnum or 1)})
    end


    return { type = 3863, reward = gamedata:SomethingProcess(getData),}
end


--cp
-- 老虎机查询
function UICPTigerchickenQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5020, "CPTigerchicken")

    return 1, 5020, nil

end

function NetCPTigerchickenQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5020, "CPTigerchicken")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local cpnum = ids.ids[1] or 0
    local cpday = ids.ids[2] or 0

    gamedata.cache.tigerchicken = {}
    gamedata.cache.tigerchicken.lucky = ids.ids[3] or 0
    gamedata.cache.tigerchicken.points = ids.ids[4] or 0
    gamedata.cache.tigerchicken.freetime = ids.ids[5] or 0

    return { type = 5020, data = gamedata.cache.tigerchicken, cpnum = cpnum, cpday = cpday,}
end


-- 老虎机抽奖
function UICPTigerchickenDoCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5021, "CPTigerchickenDo")
    local ids = ids_pb.Ids()
    local isenough,ret = gamedata.checkStaffEnough(uireq.useId,uireq.useNum,{})
    if not isenough then
        return 0,503,ret
    end
    gamedata.ext.laohujicost = {cid=uireq.useId,num = -uireq.useNum}
    table.insert(ids.ids,uireq.method)
    return 1, 5021, ids:SerializeToString()

end

function NetCPTigerchickenDoCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5021, "CPTigerchickenDo")
    local reps = combmessages_pb.CombMessages()
    reps:ParseFromString(fd.rbuf)

    local getindex = {}
    local reward = {}

    for k,v in ipairs(reps.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            for kk,vv in ipairs(ids.ids) do
                table.insert(getindex,vv)
            end
        elseif v.id == 1 then
            local getData = somethings_pb.SomeThings()
            getData:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(getData)
        elseif v.id == 2 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            tigerchickenData(ids)
        end
    end
    gamedata:updateStaff(gamedata.ext.laohujicost)
    --gamedata:updateRoleGold(0-(gamedata.ext.laohujiconsum or 0))


    return { type = 5021, reward = reward, getindex = getindex, data = gamedata.cache.tigerchicken}
end


local Tigerchickenshop_cpnum = 0
local Tigerchickenshop_day = 0
-- 老虎机商店查询
function UICPTigerchickenshopQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5022, "CPTigerchickenshop")

    return 1, 5022, nil

end

function NetCPTigerchickenshopQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5022, "CPTigerchickenshop")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata.cache.tigerchickenshop = {}
    for k,v in ipairs(ids.ids) do
        if k == 1 then
            Tigerchickenshop_cpnum = v
        elseif k == 2 then
            Tigerchickenshop_day = v
        else
            table.insert(gamedata.cache.tigerchickenshop,v)
        end
    end

    return { type = 5022, data = gamedata.cache.tigerchickenshop,cpnum = Tigerchickenshop_cpnum,cpday = Tigerchickenshop_day}
end

-- 老虎机商店兑换
--
function UICPTigerchickenshopExchangeCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5023, "CPTigerchickenshop")

    local config = {}
    if Tigerchickenshop_cpnum and Tigerchickenshop_cpnum > 0 then
        config = gamedata.config["new_generals_exchange_"..Tigerchickenshop_cpnum][tostring(uireq.pos)]
    else
        config = gamedata.config.new_generals_exchange[tostring(uireq.pos)]
    end

    if config.limit and config.limit >0 and gamedata.cache.tigerchickenshop[uireq.pos] >= config.limit then
        return 0,503,{type = 503,msg = 987}
    elseif config.number and config.number ~= "" then
        local pointid,needpoints = gamedata.getIDandNUM(config.number)
        if (gamedata.cache.tigerchicken.points or 0) < needpoints then
            return 0,503,{type = 503,msgtype = "shortprop",id= pointid,num= needpoints}
        end
    elseif config.num and config.num ~= "" then
        local propid,propnum = gamedata.getIDandNUM(config.num)
        if gamedata.getStaffNum(propid).num < propnum then
            return 0,503,{type = 503,msgtype = "shortprop",id= propid,num= propnum}
        end
    end
    gamedata.ext.tigerchickenpos = uireq.pos

    local ids = ids_pb.Ids()
    table.insert(ids.ids,uireq.pos)
    print("uireq.num == "..uireq.num)
    if uireq.num then
        table.insert(ids.ids,uireq.num)
        gamedata.ext.tigerchickennum = uireq.num
    end
    return 1, 5023, ids:SerializeToString()
end

function NetCPTigerchickenshopExchangeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5023, "CPTigerchickenshop")

    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    local config = {}
    if Tigerchickenshop_cpnum and Tigerchickenshop_cpnum > 0 then
        config = gamedata.config["new_generals_exchange_"..Tigerchickenshop_cpnum][tostring(gamedata.ext.tigerchickenpos)]
    else
        config = gamedata.config.new_generals_exchange[tostring(gamedata.ext.tigerchickenpos)]
    end

    gamedata.cache.tigerchickenshop[gamedata.ext.tigerchickenpos] = gamedata.cache.tigerchickenshop[gamedata.ext.tigerchickenpos] + (gamedata.ext.tigerchickennum or 1)

    if config.number and config.number ~= "" then
        local pointid,needpoints = gamedata.getIDandNUM(config.number)
        gamedata.cache.tigerchicken.points = gamedata.cache.tigerchicken.points - needpoints*(gamedata.ext.tigerchickennum or 1)
    end

    if config.num and config.num ~= "" then
        local propid,propnum = gamedata.getIDandNUM(config.num)
        gamedata:updateStaff({cid = propid,num = 0-propnum * (gamedata.ext.tigerchickennum or 1)})
    end


    return { type = 5023, reward = gamedata:SomethingProcess(getData),}
end
   �F  