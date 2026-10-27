--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/12/5
-- Time: 11:39
-- To change this template use File | Settings | File Templates.
--
--[[
[4901] = UIDragonWishingQueryCallBack,
[4902] = UIDragonWishingGetCallBack,
[4903] = UIDragonWishingRewardCallBack,
[4904] = UIDragonWishingEventCallBack,
[4905] = UIDragonWishingEventCloseCallBack,
[4906] = UIDragonWishingShopCallBack,
]]

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local combmessages_pb = require("combmessages_pb")
local battleresult_pb = require("battleresult_pb")
require"PickBattleResultReport"


function UIDragonWishingQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4901, "DragonWishingQuery")
    gamedata.ext.dragonwishing_query_opt = uireq.opt or 0

    return 1, 4901, nil

end

function NetDragonWishingQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4901, "DragonWishingQuery")
    local DragonWishingData = ids_pb.Ids()
    DragonWishingData:ParseFromString(fd.rbuf)

    local dragonwishing = {}

    dragonwishing.map = DragonWishingData.ids[1] or 0
    dragonwishing.ballnum = DragonWishingData.ids[2] or 0
    dragonwishing.reward = DragonWishingData.ids[3] or 0
    dragonwishing.ballstatus = DragonWishingData.ids[4] or 0
    dragonwishing.dicenum = DragonWishingData.ids[5] or 0
    dragonwishing.dicestatus = DragonWishingData.ids[6] or 0
    dragonwishing.time = DragonWishingData.ids[7] or 0
    dragonwishing.dicebuy = DragonWishingData.ids[8] or 0
    dragonwishing.nowpoint = DragonWishingData.ids[9] or 0
    dragonwishing.eventid = DragonWishingData.ids[10] or 0
    dragonwishing.eventstatus = DragonWishingData.ids[11] or 0
    dragonwishing.shopnum1 = DragonWishingData.ids[12] or 0
    dragonwishing.shopnum2 = DragonWishingData.ids[13] or 0
    dragonwishing.shopnum3 = DragonWishingData.ids[14] or 0
    dragonwishing.shopnum4 = DragonWishingData.ids[15] or 0
    dragonwishing.pointstatus = {}
    for i = 1,139 do
        dragonwishing.pointstatus[tostring(i)] = DragonWishingData.ids[15+i] or 0
    end

    local dragonwishingStartSatus = DragonWishingData.ids[155] or 0

    return { type = 4901, dragonwishing = dragonwishing, opt = gamedata.ext.dragonwishing_query_opt or 0, startStaus = dragonwishingStartSatus}
end

--
function UIDragonWishingGetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4902, "DragonWishing")

    gamedata.ext.dragonwishing_roll_gold = uireq.xgold or 0

    if gamedata.ext.dragonwishing_roll_gold+0 > gamedata.cache.role.gold+0 then
        return 0,503,{type = 503, msgtype = "shortgold" }
    else
        return 1, 4902, nil
    end

end

function NetDragonWishingGetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4902, "DragonWishing")
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local dicestatus = {}
    local reward = {}
    local battlereward = {}
    local battlereport = nil
    local result = 0
    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            dicestatus.dice1 = ids.ids[1] or 0
            dicestatus.dice2 = ids.ids[2] or 0
            dicestatus.eventid = ids.ids[3] or 0
            dicestatus.route = {}
            for i = 4,#ids.ids do
                dicestatus.route[tostring(i-3)] = ids.ids[i] or 0
            end
        elseif v.id == 2 then
            local copyAttackResultPb = battleresult_pb.BattleResult()
            copyAttackResultPb:ParseFromString(v.data)
            result = copyAttackResultPb.result
            battlereward = gamedata:SomethingProcess(copyAttackResultPb.reward)
            battlereport = PickBattleResultReport(copyAttackResultPb)
        elseif v.id == 1 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
        end
    end

    if gamedata.ext.dragonwishing_roll_gold and gamedata.ext.dragonwishing_roll_gold+0 > 0 then
        gamedata:updateRoleGold(0-gamedata.ext.dragonwishing_roll_gold,"神龙许愿掷骰子",1)
    end


    return {type = 4902, dicestatus = dicestatus, reward = reward, battlereward = battlereward, battlereport = battlereport,result = result,}
end

--
function UIDragonWishingRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4903, "DragonWishingRewardCallBack")

    local getData = ids_pb.Ids()

    if uireq and uireq.id then
        table.insert(getData.ids, uireq.id)
    end

    return 1, 4903, getData:SerializeToString()
end

function NetDragonWishingRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4903, "DragonWishingRewardCallBack")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    local reward = {}
    reward = gamedata:SomethingProcess(SomeThings)

    return {type = 4903, reward = reward,}
end

--
function UIDragonWishingEventCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4904, "DragonWishingEventCallBack")

    local eventData = ids_pb.Ids()

    gamedata.ext.dragonwishing_event_gold = uireq.xgold or 0

    if uireq and uireq.opt then
        table.insert(eventData.ids, uireq.opt)
    end

    if gamedata.ext.dragonwishing_event_gold+0 > gamedata.cache.role.gold+0 then
        return 0,503,{type = 503, msgtype = "shortgold" }
    else
        return 1, 4904, eventData:SerializeToString()
    end

end

function NetDragonWishingEventCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4904, "DragonWishing")
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local adddice = 0
    local reward = {}
    local battlereward = {}
    local battlereport = nil
    local result = 0
    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            adddice = ids.ids[1] or 0
        elseif v.id == 2 then
            local copyAttackResultPb = battleresult_pb.BattleResult()
            copyAttackResultPb:ParseFromString(v.data)
            result = copyAttackResultPb.result
            battlereward = gamedata:SomethingProcess(copyAttackResultPb.reward)
            battlereport = PickBattleResultReport(copyAttackResultPb)
        elseif v.id == 1 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
        end
    end

    if gamedata.ext.dragonwishing_event_gold and gamedata.ext.dragonwishing_event_gold+0 > 0 then
        gamedata:updateRoleGold(0-gamedata.ext.dragonwishing_event_gold,"神龙许愿事件",1)
    end


    return {type = 4904, adddice = adddice, reward = reward, battlereward = battlereward, battlereport = battlereport,result = result,}
end

--
function UIDragonWishingEventCloseCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4905, "DragonWishingEventCloseCallBack")

    return 1, 4905, nil
end

function NetDragonWishingEventCloseCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4905, "DragonWishingEventCloseCallBack")

    return {type = 4905,}
end


--
function UIDragonWishingShopCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4906, "DragonWishingShopCallBack")

    local getData = ids_pb.Ids()

    gamedata.ext.dragonwishing_shop_gold = uireq.xgold or 0
    if gamedata.ext.dragonwishing_shop_gold+0 > gamedata.cache.role.gold+0 then
        return 0,503,{type = 503, msgtype = "shortgold" }
    end

    if uireq and uireq.id then
        table.insert(getData.ids, uireq.id)
        table.insert(getData.ids, uireq.num or 1)
    end

    return 1, 4906, getData:SerializeToString()
end

function NetDragonWishingShopCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4906, "DragonWishingShopCallBack")
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local shop1,shop2,shop3,shop4 = 0,0,0,0
    local reward = {}
    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            shop1 = ids.ids[1] or 0
            shop2 = ids.ids[2] or 0
            shop3 = ids.ids[3] or 0
            shop4 = ids.ids[4] or 0
        elseif v.id == 1 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
        end
    end

    if gamedata.ext.dragonwishing_shop_gold and gamedata.ext.dragonwishing_shop_gold+0 > 0 then
        gamedata:updateRoleGold(0-gamedata.ext.dragonwishing_shop_gold,"神龙许愿商店",1)
    end

    return {type = 4906, reward = reward,shop1 = shop1,shop2 = shop2,shop3 = shop3,shop4 = shop4,}
end

function UIDragonWishingQueryMapCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4907, "UIDragonWishingQueryMapCallBack")

    return 1, 4907, nil
end

function NetDragonWishingQueryMapCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4907, "NetDragonWishingQueryMapCallBack")
    local _ids = ids_pb.Ids()
    _ids:ParseFromString(fd.rbuf)

    local _map = _ids.ids[1] or 1

    return {type = 4907, map = _map}
end #%  