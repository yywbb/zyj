--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/10/22
-- Time: 下午3:32
-- To change this template use File | Settings | File Templates.
--

local soulhuntquery_pb = require("soulhuntquery_pb")
local ids_pb = require("ids_pb")
local result_pb = require("result_pb")
local somethings_pb = require("somethings_pb")
local souls_pb = require("souls_pb")
local slots_pb = require("slots_pb")
local combmessages_pb = require("combmessages_pb")
-------------------------------------------------------------------------------------

function UISoulHuntQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2501, "SoulHuntQuery")
--    if next(gamedata.cache.soulhunt) then
--        return 0, 2501, { type = uireq.type, soulhunt = gamedata.cache.soulhunt, }
--    else
        return 1, 2501, nil
--    end
end

function NetSoulHuntQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2501, "SoulHuntQuery")
    local huntData = soulhuntquery_pb.SoulHuntQuery()
    huntData:ParseFromString(fd.rbuf)

    gamedata:SoulHuntQuery(huntData,true)

    return { type = 2501, soulhunt = gamedata.cache.soulhunt}
end

-------------------------------------------------------------------------------------

function UISoulHuntCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2502, "SoulHunt")

    printT(uireq)
    gamedata.ext.soulhuntcost = nil
    if uireq.param == 1 then
        if uireq.isfree and uireq.isfree == 1 then

        elseif gamedata.config.soul_hunt[tostring(gamedata.cache.soulhunt.hunt)].coin > gamedata.cache.role.coin then
            --return 0, 503,{type = 503,msg = "银币不足！！"}
            return  0, 503, {type = 503, msgtype = "shortcoin"}
        end
    elseif uireq.param == 10 then
        if gamedata.config.soul_hunt[tostring(gamedata.cache.soulhunt.hunt)].coin*10 > gamedata.cache.role.coin then
            --return 0, 503,{type = 503,msg = "银币不足！！"}
            return  0, 503, {type = 503, msgtype = "shortcoin"}
        end
    elseif uireq.param == 100 then
        if gamedata.config.soul_hunt[tostring(gamedata.cache.soulhunt.hunt)].coin*100 > gamedata.cache.role.coin then
            --return 0, 503,{type = 503,msg = "银币不足！！"}
            return  0, 503, {type = 503, msgtype = "shortcoin"}
        end
    -- elseif uireq.param == 1000 then
    --     if gamedata.config.soul_hunt[tostring(gamedata.cache.soulhunt.hunt)].coin*1000 > gamedata.cache.role.coin then
    --         --return 0, 503,{type = 503,msg = "银币不足！！"}
    --         return  0, 503, {type = 503, msgtype = "shortcoin"}
    --     end
    elseif uireq.param == 6 then
        local isenough,ret = gamedata.checkStaffEnough(uireq.useId,uireq.useNum,{})
        if not isenough then
            return 0,503,ret
        end
        
        if gamedata.config.soul_hunt[tostring(6)].coin > gamedata.cache.role.coin then
            return  0, 503, {type = 503, msgtype = "shortcoin"}
        end
        gamedata.ext.soulhuntcost = {cid=uireq.useId,num = -uireq.useNum}
    elseif uireq.param == 60 or uireq.param == 600 or uireq.param == 6000 then
        local isenough,ret = gamedata.checkStaffEnough(uireq.useId,uireq.useNum,{})
        if not isenough then
            return 0,503,ret
        end
        gamedata.ext.soulhuntcost = {cid=uireq.useId,num = -uireq.useNum,name = "道具猎命"}
    end
    

    local SoulHuntData = ids_pb.Ids()

    table.insert(SoulHuntData.ids, uireq.param or 1)
    table.insert(SoulHuntData.ids, uireq.param1 or 0)
    table.insert(SoulHuntData.ids, uireq.param2 or 0)
    table.insert(SoulHuntData.ids, uireq.param3 or 0)

    gamedata.ext.soulhuntparam = uireq.param

    return 1, 2502, SoulHuntData:SerializeToString()
end

function NetSoulHuntCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2502, "SoulHunt")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local getsouls = {}
    local getnum = 0
    local reward = {}
    for k,v in ipairs(datas.messages) do
        if v.id==1 then
            local huntData = soulhuntquery_pb.SoulHuntQuery()
            huntData:ParseFromString(v.data)
            getsouls,getnum = gamedata:SoulHunt(huntData,gamedata.ext.soulhuntparam)
            gamedata:updateRoleCoin(0-huntData.coin)
        elseif v.id==2 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
        end
    end

    gamedata:updateStaff(gamedata.ext.soulhuntcost)


    return { type = 2502, soulhunt = gamedata.cache.soulhunt, getsouls =getsouls,getnum = getnum,reward = reward}
end

-------------------------------------------------------------------------------------

function UISoulHunt41CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2505, "SoulHunt41")

    if 100 > gamedata.cache.role.gold then
        return 0, 503,{type = 503, msgtype = "shortgold"}
    end
    return 1, 2505, nil
end

function NetSoulHunt41CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2505, "SoulHunt41")
    local ResultData = result_pb.Result()
    ResultData:ParseFromString(fd.rbuf)

    if ResultData.result then
        gamedata.cache.soulhunt.hunt = 4
    end
    gamedata:updateRoleGold(-100,"猎魂天人合一",1)

    return { type = 2505, soulhunt = gamedata.cache.soulhunt}
end

-------------------------------------------------------------------------------------

function UISoulExchangeCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2503, "SoulExchange")
    local SoulExchangeData = ids_pb.Ids()
    for k,v in pairs(uireq.ids) do
        table.insert(SoulExchangeData.ids, v)
    end

    return 1, 2503, SoulExchangeData:SerializeToString()
end

function NetSoulExchangeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2503, "SoulExchange")

    local soulData = souls_pb.Souls()
    soulData:ParseFromString(fd.rbuf)

    local getsoul = gamedata:Souls(soulData.souls)

    gamedata.cache.soulhunt.soul = gamedata.cache.soulhunt.soul - gamedata.config.soul_exchange[tostring(getsoul[1].cid)].num

    return { type = 2503, getsouls = getsoul, soulhunt = gamedata.cache.soulhunt }
end

-------------------------------------------------------------------------------------

function UISoulUpgradeCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2504, "SoulUpgrade")

    printT(gamedata.cache.props)

    if gamedata.cache.props[20099] and gamedata.cache.props[20099].num >= uireq.prop then
    else
        return 0, 503,{type = 503,msg = "灵元不足！！"}
    end
    local SoulUpgradeData = ids_pb.Ids()
    table.insert(SoulUpgradeData.ids, uireq.iid)


    gamedata.ext.SoulUpgrade = {iid = uireq.iid, prop = uireq.prop}

    return 1, 2504, SoulUpgradeData:SerializeToString()
end

function NetSoulUpgradeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2504, "SoulUpgrade")
    local info = slots_pb.SlotS()
    info:ParseFromString(fd.rbuf)

    gamedata:SlotInfoProcess(info)

    gamedata:updateprops({cid = 20099, num = 0-gamedata.ext.SoulUpgrade.prop})

    return {type= 2504, newsoul = gamedata.cache.souls[gamedata.ext.SoulUpgrade.iid]}
end

-------------------------------------------------------------------------------------

function UISoulResolveCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2506, "SoulResolve")
    local SoulResolveData = ids_pb.Ids()
    for k,v in pairs(uireq.ids) do
        table.insert(SoulResolveData.ids, v)
    end
    
    gamedata.ext.SoulResolveid = uireq.ids 

    return 1, 2506, SoulResolveData:SerializeToString()
end

function NetSoulResolveCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2506, "SoulResolve")
    local SoulResolveData = somethings_pb.SomeThings()
    SoulResolveData:ParseFromString(fd.rbuf)

    local reward = gamedata:SomethingProcess(SoulResolveData)


    local changes = {}
    for k,v in pairs(gamedata.ext.SoulResolveid) do
        changes["star"..gamedata.cache.souls[v].quality] = true
        gamedata.cache.souls[v] = nil
    end
    changes["all"] = true

    return { type = 2506, reward = reward, changes = changes}
end

--
function UISoulCompoundCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2507, "SoulUpgrade")

    local SoulCompound = ids_pb.Ids()
    table.insert(SoulCompound.ids, uireq.iid1 or 0)
    table.insert(SoulCompound.ids, uireq.iid2 or 0)

    gamedata.ext.SoulCompound_iid1 = uireq.iid1 or 0
    gamedata.ext.SoulCompound_iid2 = uireq.iid2 or 0

    return 1, 2507, SoulCompound:SerializeToString()
end

function NetSoulCompoundCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2507, "SoulUpgrade")

    local info = slots_pb.SlotS()
    info:ParseFromString(fd.rbuf)

    gamedata:SlotInfoProcess(info)

    if gamedata.ext.SoulCompound_iid1 and gamedata.ext.SoulCompound_iid1 > 0 and gamedata.cache.souls[gamedata.ext.SoulCompound_iid1] then
        gamedata.cache.souls[gamedata.ext.SoulCompound_iid1] = nil
    end
    if gamedata.ext.SoulCompound_iid2 and gamedata.ext.SoulCompound_iid2 > 0 and gamedata.cache.souls[gamedata.ext.SoulCompound_iid2] then
        gamedata.cache.souls[gamedata.ext.SoulCompound_iid2] = nil
    end

    return {type= 2507, souls = gamedata.cache.souls}
end