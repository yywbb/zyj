--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/21
-- Time: 14:40
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")



function sortLoginData(data)
    local stdata = gamedata.config.startgift or {}
    local showTable = {}
    local hasday = false
    for k,v in pairs(data) do

        if tonumber(k) > 1 then
            if v ~= 1 then
                table.insert(showTable,stdata[tostring(k-1)])
                hasday = true
            else
                stdata[tostring(k-1)].day = stdata[tostring(k-1)].day + 100
                table.insert(showTable,stdata[tostring(k-1)])
            end
        end

    end
    if not hasday then
        gamedata.cache.activitystatus[12].status = 0
    end

    local sortfunc = function(a,b)
        if a["day"] < b["day"] then
            return true
        else
            return false
        end
    end
    table.sort(showTable,sortfunc)
    for k,v in pairs(showTable) do
        if v.day > 35 then
            v.day = v.day - 100
        end
    end
    return showTable   
end

function UIActivityStartGiftQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2035, "ActivityStartGiftQuery")
    if next(gamedata.cache.startgift) and not uireq.param then
        return 0, 2035, { type = uireq.type, status = gamedata.cache.startgift, showTable = sortLoginData(gamedata.cache.startgift)}
        --return 0, 2035, { type = uireq.type, status = gamedata.cache.startgift}
    else
        return 1, 2035, nil
    end
end

function NetActivityStartGiftQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2035, "ActivityStartGiftQuery")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local status = {}
    for k,v in ipairs(ids.ids) do
        table.insert(status,v)
    end

    gamedata.cache.startgift = status

    return { type = 2035, status = gamedata.cache.startgift, showTable = sortLoginData(gamedata.cache.startgift)}

end



function UIActivityStartGiftCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2036, "ActivityStartGift")
    local doData = ids_pb.Ids()

    table.insert(doData.ids,uireq.id or 1)

    return 1, 2036, doData:SerializeToString()
end

function NetActivityStartGiftCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2036, "ActivityStartGift")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)


    return { type = 2036, reward = gamedata:SomethingProcess(getData),}
end



--
function UIContinue7QueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 212, "Continue7Query")
    if next(gamedata.cache.continue7) and not uireq.param then
        return 0, 212, { type = uireq.type, status = gamedata.cache.continue7}
    else
        return 1, 212, nil
    end
end

function NetContinue7QueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 212, "Continue7Query")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local status = {}
    for k,v in ipairs(ids.ids) do
        table.insert(status,v)
    end

    gamedata.cache.continue7 = status
    return { type = 212, status = gamedata.cache.continue7, }

end

function UIContinue7RewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 213, "Continue7Reward")

    return 1, 213, nil
end

function NetContinue7RewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 213, "Continue7Reward")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)


    return { type = 213, reward = gamedata:SomethingProcess(getData),}
end


function UIContinue7QueryCallBack1(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 214, "Continue7Query")
    if next(gamedata.cache.continueX1) and not uireq.param then
        return 0, 214, { type = uireq.type, status = gamedata.cache.continueX1}
    else
        return 1, 214, nil
    end
end

function NetContinue7QueryCallBack1(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 214, "Continue7Query")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local status = {}
    for k,v in ipairs(ids.ids) do
        table.insert(status,v)
    end

    gamedata.cache.continueX1 = status
    return { type = 214, status = gamedata.cache.continueX1, }

end

function UIContinue7RewardCallBack1(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 215, "Continue7Reward")

    return 1, 215, nil
end

function NetContinue7RewardCallBack1(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 215, "Continue7Reward")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)


    return { type = 215, reward = gamedata:SomethingProcess(getData),}
end


--
function UIDayDayGiftCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2022, "DayDayGift")

    return 1, 2022, nil
end

function NetDayDayGiftCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2022, "DayDayGift")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local status = {}
    local time,day,rmb = 0,1,0
    for k,v in ipairs(ids.ids) do
        if k == 1 then
            time = v
        elseif k == 2 then
            day = v
        elseif k ==3 then
            rmb = v
        else
            table.insert(status,v)
        end
    end

    return { type = 2022, time = time, day = day, rmb = rmb, status = status, }

end

function UIDayDayGiftRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2023, "DayDayGiftReward")
    local doData = ids_pb.Ids()

    table.insert(doData.ids,uireq.id or 1)

    return 1, 2023, doData:SerializeToString()
end

function NetDayDayGiftRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2023, "DayDayGiftReward")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)


    return { type = 2023, reward = gamedata:SomethingProcess(getData),}
end

function UIConsumeGiftCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2020, "ConsumeGift")

    return 1, 2020, nil
end

function NetConsumeGiftCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2020, "ConsumeGift")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local status = {}
    local time = 0
    local goldNum = 0
    -- local datarewards = gamedata.config.consumegift_reward

    local datarewards = gamedata.dailyCpActivityConfig("consumegift_reward",15)

    for k,v in ipairs(ids.ids) do
        if k == 1 then
            time = v
        elseif k == 2 then
            goldNum = v
        elseif k > 2 then
            -- if next(datarewards[tostring(k - 2)]) ~= nil then
            if (k-2) <= table.getTableLength(datarewards) then
                if v == 1 then
                   sorting = 0 +  datarewards[tostring(k-2)].id
                else
                    sorting = v * 100 + datarewards[tostring(k-2)].id + 100
                end                
                table.insert(status, {status = v, sorting = sorting, reward = datarewards[tostring(k-2)]})
            end
        end
        
    end
    -- gamedata.config.consumegift_reward
    table.sort(status, function(a, b)
        return a.sorting < b.sorting
    end)

    return { type = 2020, time = time, goldNum = goldNum, status = status, }

end

function UIConsumeGiftRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2021, "ConsumeGiftReward")
    local doData = ids_pb.Ids()

    table.insert(doData.ids,uireq.id or 1)
    print("进入2021")
    return 1, 2021, doData:SerializeToString()
end

function NetConsumeGiftRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2021, "ConsumeGiftReward")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)


    return { type = 2021, reward = gamedata:SomethingProcess(getData),}
end

--
--
function UIRechargeGiftCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2024, "RechargeGift")

    return 1, 2024, nil
end

function NetRechargeGiftCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2024, "RechargeGift")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    -- local status = {}
    local status = {}
    local rechargeGift = gamedata.dailyCpActivityConfig("recharge_gift",16)

    -- local rechargeGift = gamedata.config.recharge_gift
    local rechargeData = {}
    local rmb = 0
    for k,v in ipairs(ids.ids) do
        local sorting = 0
        if k == 1 then
            rmb = v
        elseif rechargeGift[tostring(k-1)] then
            if v == 1 then
               sorting = 0 +  rechargeGift[tostring(k-1)].id
            else
                sorting = v * 100 + rechargeGift[tostring(k-1)].id + 100
            end
            table.insert(status, {status = v, sorting = sorting, recharge = rechargeGift[tostring(k-1)]})
        end
    end
    -- 防止服务端传过来的数据跟读的表对不上报错
    if table.getTableLength(rechargeGift) > table.getTableLength(status) then 
        for k,v in pairs(rechargeGift) do
            local sorting = 0
            if tonumber(k) > table.getTableLength(status) then
                sorting = 0 * 100 + rechargeGift[tostring(k)].id + 100
                table.insert(status, {status = 0, sorting = sorting, recharge = rechargeGift[tostring(k)]})
            end
        end
    end
    
    table.sort(status, function(a, b)
        return a.sorting < b.sorting
    end)

    return { type = 2024, rmb = rmb, status = status, }

end

function UIRechargeGiftRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2025, "RechargeGiftReward")
    local doData = ids_pb.Ids()

    table.insert(doData.ids,uireq.id or 1)

    return 1, 2025, doData:SerializeToString()
end

function NetRechargeGiftRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2025, "RechargeGiftReward")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)


    return { type = 2025, reward = gamedata:SomethingProcess(getData),}
end


--
--
--
function UIDayDayGiftX1CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3310, "DayDayGiftX1")

    return 1, 3310, nil
end

function NetDayDayGiftX1CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3310, "DayDayGiftX1")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local status = {}
    local time,day,rmb = 0,1,0
    for k,v in ipairs(ids.ids) do
        if k == 1 then
            time = v
        elseif k == 2 then
            day = v
        elseif k ==3 then
            rmb = v
        else
            table.insert(status,v)
        end
    end

    return { type = 3310, time = time, day = day, rmb = rmb, status = status, }

end

function UIDayDayGiftX1RewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3311, "DayDayGiftRewardX1")
    local doData = ids_pb.Ids()

    table.insert(doData.ids,uireq.id or 1)

    return 1, 3311, doData:SerializeToString()
end

function NetDayDayGiftX1RewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3311, "DayDayGiftRewardX1")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)


    return { type = 3311, reward = gamedata:SomethingProcess(getData),}
end


--

function UISingleRechargeGiftCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3750, "SingleRechargeGift")

    return 1, 3750, nil
end

function NetSingleRechargeGiftCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3750, "SingleRechargeGift")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local status = {}
    local rechargeGift = gamedata.dailyCpActivityConfig("single_gift",55)

    for k,v in pairs(rechargeGift) do
        local sorting = v.id+100
        if ids.ids[2*(v.id)-1] and ids.ids[2*(v.id)-1] == 1 then
            sorting = sorting-100
        elseif ids.ids[2*(v.id)-1] and ids.ids[2*(v.id)-1] == 2 then
            sorting = sorting+100
        end
        table.insert(status, {status = ids.ids[2*(v.id)-1] or 0, rechargetimes = ids.ids[2*(v.id)] or 0, recharge = v, sorting = sorting})
    end

    table.sort(status, function(a, b)
        return a.sorting < b.sorting
    end)

    return { type = 3750, status = status, }

end

function UISingleRechargeGiftRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3751, "SingleRechargeGiftReward")
    local doData = ids_pb.Ids()

    table.insert(doData.ids,uireq.id or 1)

    return 1, 3751, doData:SerializeToString()
end

function NetSingleRechargeGiftRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3751, "SingleRechargeGiftReward")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)


    return { type = 3751, reward = gamedata:SomethingProcess(getData),}
end

--


function UISingleRechargeGiftX2CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3758, "SingleRechargeGift")

    return 1, 3758, nil
end

function NetSingleRechargeGiftX2CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3758, "SingleRechargeGift")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local status = {}


    local rechargeGift = gamedata.dailyCpActivityConfig("single_gift_X2",141)
    -- if gamedata.cache.dailyCpActivityTimeStatus[141] and gamedata.cache.dailyCpActivityTimeStatus[141].cpnum then
    --     print("rechargeGift",141)
    --     rechargeGift = gamedata.config["single_gift_X2".."_rc_"..gamedata.cache.dailyCpActivityTimeStatus[141].cpnum] or {}
    -- end


    for k,v in pairs(rechargeGift) do
        local sorting = v.id+100
        if ids.ids[2*(v.id)-1] and ids.ids[2*(v.id)-1] == 1 then
            sorting = sorting-100
        elseif ids.ids[2*(v.id)-1] and ids.ids[2*(v.id)-1] == 2 then
            sorting = sorting+100
        end
        table.insert(status, {status = ids.ids[2*(v.id)-1] or 0, rechargetimes = ids.ids[2*(v.id)] or 0, recharge = v, sorting = sorting})
    end

    table.sort(status, function(a, b)
        return a.sorting < b.sorting
    end)

    return { type = 3758, status = status, }

end

function UISingleRechargeGiftRewardX2CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3759, "SingleRechargeGiftReward")
    local doData = ids_pb.Ids()

    table.insert(doData.ids,uireq.id or 1)

    return 1, 3759, doData:SerializeToString()
end

function NetSingleRechargeGiftRewardX2CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3759, "SingleRechargeGiftReward")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)


    return { type = 3759, reward = gamedata:SomethingProcess(getData),}
end


function UIAchievementLimitTimeCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3760, "AchievementLimitTimeCallBack")

    return 1, 3760, nil
end

function NetAchievementLimitTimeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3760, "AchievementLimitTimeCallBack")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local status = {}
    -- local configreward = gamedata.config.time_achievement or {}
    local configreward = gamedata.dailyCpActivityConfig("time_achievement",56)

    for k,v in pairs(configreward) do
        local sorting = v.id+100
        if ids.ids[2*(v.id)-1] and ids.ids[2*(v.id)-1] == 1 then
            sorting = sorting-100
        elseif ids.ids[2*(v.id)-1] and ids.ids[2*(v.id)-1] == 2 then
            sorting = sorting+100
        end
        table.insert(status, {status = ids.ids[2*(v.id)-1] or 0, num = ids.ids[2*(v.id)] or 0, config = v, sorting = sorting})
    end

    table.sort(status, function(a, b)
        return a.sorting < b.sorting
    end)

    return { type = 3760, status = status, }

end

function UIAchievementLimitTimeRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3761, "AchievementLimitTimeReward")
    local doData = ids_pb.Ids()

    table.insert(doData.ids,uireq.id or 1)

    return 1, 3761, doData:SerializeToString()
end

function NetAchievementLimitTimeRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3761, "AchievementLimitTimeReward")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)


    return { type = 3761, reward = gamedata:SomethingProcess(getData),}
end


--
function UIVipWelfareExchangeCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4611, "VipWelfareExchange")
    printT(uireq,"uireq")
    local doData = ids_pb.Ids()

    if uireq.need and tonumber(uireq.need["cid"]) == 1001 and gamedata.cache.role.gold < tonumber(uireq.need["num"]) then
        return  0, 503, {type = 503, msgtype = "shortgold"}
    elseif uireq.need and tonumber(uireq.need["cid"]) == 1000 and gamedata.cache.role.coin < tonumber(uireq.need["num"]) then
        return  0, 503, {type = 503, msgtype = "shortcoin"}
    else
        table.insert(doData.ids,uireq.isfree or 1)
        table.insert(doData.ids,uireq.battle_lv)
        
        gamedata.ext.VipWelfareExchangeFree = uireq.isfree or 1
        gamedata.ext.VipWelfareExchangeNeed = uireq.need or {}
        return 1, 4611, doData:SerializeToString()
    end
end

function NetVipWelfareExchangeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4611, "VipWelfareExchange")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    if gamedata.ext.VipWelfareExchangeNeed and  next(gamedata.ext.VipWelfareExchangeNeed) then
        if tonumber(gamedata.ext.VipWelfareExchangeNeed["cid"]) == 1001 then
            gamedata:updateRoleGold(0-tonumber(gamedata.ext.VipWelfareExchangeNeed["num"]),"VIP每日福利购买",1)
        elseif tonumber(gamedata.ext.VipWelfareExchangeNeed["cid"]) == 1000 then
            gamedata:updateRoleCoin(0-tonumber(gamedata.ext.VipWelfareExchangeNeed["num"]))
        end
    end

    if gamedata.ext.VipWelfareExchangeFree and gamedata.ext.VipWelfareExchangeFree == 1 then
        gamedata.cache.vipstatus.vipexchange_free = 1
    else
        gamedata.cache.vipstatus.vipexchange_buy = 1
    end

    return { type = 4611, reward = gamedata:SomethingProcess(getData), vipstatus = gamedata.cache.vipstatus}
end

--
function UIVipWelfareExtCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 46111, "VipWelfareExt")
    if gamedata.cache.vipstatus then
        return 0, 46111, {type = 46111, vipstatus = gamedata.cache.vipstatus}
    else
        return 1, 300, nil
    end
end

--

function UITimeGiftCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4615, "UITimeGiftCallBack")

    return 1, 4615, nil
end

function NetTimeGiftCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4615, "NetTimeGiftCallBack")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata.cache.timegift = {}
    gamedata.cache.timegift.status1 = ids.ids[1] or 0
    gamedata.cache.timegift.reward1 = ids.ids[2] or 0
    gamedata.cache.timegift.status2 = ids.ids[3] or 0
    gamedata.cache.timegift.reward2 = ids.ids[4] or 0

    return { type = 4615, timegift = gamedata.cache.timegift, }

end
--
function UITimeGiftRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4616, "UITimeGiftRewardCallBack")
    local doData = ids_pb.Ids()

    if uireq.xnum and gamedata.cache.role.gold < tonumber(uireq.xnum) then
        return  0, 503, {type = 503, msgtype = "shortgold"}
    else
        table.insert(doData.ids,uireq.opt or 1)
        gamedata.ext.TimeGiftOpt = uireq.opt or 1
        gamedata.ext.TimeGiftGold = uireq.xnum or 0
        return 1, 4616, doData:SerializeToString()
    end
end

function NetTimeGiftRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4616, "NetTimeGiftRewardCallBack")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    if gamedata.ext.TimeGiftGold and gamedata.ext.TimeGiftGold>0 then
        gamedata:updateRoleGold(0-gamedata.ext.TimeGiftGold,"福利礼包购买",1)
    end

    if gamedata.ext.TimeGiftOpt and gamedata.ext.TimeGiftOpt == 2 then
        gamedata.cache.timegift.status2 = 1
    else
        gamedata.cache.timegift.status1 = 1
    end

    return { type = 4616, reward = gamedata:SomethingProcess(getData), timegift = gamedata.cache.timegift,}
end


--
function UITotalRechargeQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4860, "TotalRechargeQueryCallBack")

    return 1, 4860, nil
end

function NetTotalRechargeQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4860, "TotalRechargeQueryCallBack")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local data = {}
    data.status3 = {}
    data.now = ids.ids[1] or 1
    data.rmb = ids.ids[2] or 0
    data.day = ids.ids[3] or 0
    data.status1 = ids.ids[4] or 0
    data.status2 = ids.ids[5] or 0

    for i = 6,#ids.ids do
        data.status3[tostring(i-5)] = ids.ids[i] or 0
    end

    return { type = 4860, data = data, }

end

--
function UITotalRechargeGetRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4861, "TotalRechargeGetRewardCallBack")
    local doData = ids_pb.Ids()

    gamedata.ext.TotalRechargeCost = uireq.cost or {}

    for k,v in pairs(gamedata.ext.TotalRechargeCost) do
        if v.cid == 1001 then
            if gamedata.cache.role.gold < tonumber(v.num) then
                return  0, 503, {type = 503, msgtype = "shortgold"}
            end
        else
            if gamedata.getStaffNum(v.cid).num < v.num then
                return 0,503,{type = 503,msgtype = "shortprop",id = v.cid,num = v.num}
            end
        end
    end

    --
    table.insert(doData.ids,uireq.opt or 1)
    table.insert(doData.ids,uireq.index or 1)
    return 1, 4861, doData:SerializeToString()

end

function NetTotalRechargeGetRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4861, "TotalRechargeGetRewardCallBack")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    if gamedata.ext.TotalRechargeCost and next(gamedata.ext.TotalRechargeCost) then
        for k,v in pairs(gamedata.ext.TotalRechargeCost) do
            gamedata:updateStaff({cid = v.cid,num = 0-v.num})
        end
    end

    return { type = 4861, reward = gamedata:SomethingProcess(getData),}
end


--
function UITotalRechargeQueryX1CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5701, "TotalRechargeQueryX1CallBack")

    return 1, 5701, nil
end

function NetTotalRechargeQueryX1CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5701, "TotalRechargeQueryX1CallBack")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local data = {}
    data.status3 = {}
    data.now = ids.ids[1] or 1
    data.rmb = ids.ids[2] or 0
    data.day = ids.ids[3] or 0
    data.status1 = ids.ids[4] or 0
    data.status2 = ids.ids[5] or 0

    for i = 6,#ids.ids do
        data.status3[tostring(i-5)] = ids.ids[i] or 0
    end

    return { type = 5701, data = data, }

end

--
function UITotalRechargeGetRewardX1CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5702, "TotalRechargeGetRewardX1CallBack")
    local doData = ids_pb.Ids()

    gamedata.ext.TotalRechargeCostX1 = uireq.cost or {}

    for k,v in pairs(gamedata.ext.TotalRechargeCostX1) do
        if v.cid == 1001 then
            if gamedata.cache.role.gold < tonumber(v.num) then
                return  0, 503, {type = 503, msgtype = "shortgold"}
            end
        else
            if gamedata.getStaffNum(v.cid).num < v.num then
                return 0,503,{type = 503,msgtype = "shortprop",id = v.cid,num = v.num}
            end
        end
    end

    --
    table.insert(doData.ids,uireq.opt or 1)
    table.insert(doData.ids,uireq.index or 1)
    return 1, 5702, doData:SerializeToString()

end

function NetTotalRechargeGetRewardX1CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5702, "TotalRechargeGetRewardX1CallBack")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    if gamedata.ext.TotalRechargeCostX1 and next(gamedata.ext.TotalRechargeCostX1) then
        for k,v in pairs(gamedata.ext.TotalRechargeCostX1) do
            gamedata:updateStaff({cid = v.cid,num = 0-v.num})
        end
    end

    return { type = 5702, reward = gamedata:SomethingProcess(getData),}
end


--
--[4850] = UIRechargeRebateCallBack,
--[4851] = UIRechargeRebateGetCallBack,
--


function UIRechargeRebateCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4850, "RechargeRebateCallBack")

    return 1, 4850, nil
end

function NetRechargeRebateCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4850, "RechargeRebateCallBack")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local data = {}
    data.num = ids.ids[1] or 0
    data.rebate = ids.ids[2] or 0
    data.status1 = ids.ids[3] or 0
    data.status2 = ids.ids[4] or 0
    data.status3 = ids.ids[5] or 0

    return { type = 4850, data = data, }

end


--
function UIRechargeRebateGetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4851, "RechargeRebateGetCallBack")
    local doData = ids_pb.Ids()

    table.insert(doData.ids,uireq.index or 1)

    return 1, 4851, doData:SerializeToString()

end

function NetRechargeRebateGetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4851, "RechargeRebateGetCallBack")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)


    return { type = 4851, reward = gamedata:SomethingProcess(getData),}
end



--cp
--
function UICPRechargeGiftCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5000, "CPRechargeGift")

    return 1, 5000, nil
end

function NetCPRechargeGiftCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5000, "CPRechargeGift")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    -- local status = {}
    local status = {}

    local rechargeGift = gamedata.dailyCpActivityConfig("recharge_gift",16)
    -- local rechargeGift = gamedata.config.recharge_gift
    local rechargeData = {}
    local rmb = 0
    local cpnum = 0
    local cpday = 0
    for k,v in ipairs(ids.ids) do
        local sorting = 0
        if k == 1 then
            cpnum = v
            rechargeGift = gamedata.config["recharge_gift_"..cpnum]
        elseif k == 2 then
            cpday = v
        elseif k == 3 then
            rmb = v
        elseif rechargeGift[tostring(k-3)] then
            if v == 1 then
                sorting = 0 +  rechargeGift[tostring(k-3)].id
            else
                sorting = v * 100 + rechargeGift[tostring(k-3)].id + 100
            end
            table.insert(status, {status = v, sorting = sorting, recharge = rechargeGift[tostring(k-3)]})
        end
    end
    -- 防止服务端传过来的数据跟读的表对不上报错
    if table.getTableLength(rechargeGift) > table.getTableLength(status) then
        for k,v in pairs(rechargeGift) do
            local sorting = 0
            if tonumber(k) > table.getTableLength(status) then
                sorting = 0 * 100 + rechargeGift[tostring(k)].id + 100
                table.insert(status, {status = 0, sorting = sorting, recharge = rechargeGift[tostring(k)]})
            end
        end
    end

    table.sort(status, function(a, b)
        return a.sorting < b.sorting
    end)

    return { type = 5000, rmb = rmb, status = status, cpnum = cpnum, cpday = cpday,}

end

function UICPRechargeGiftRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5001, "RechargeGiftReward")
    local doData = ids_pb.Ids()

    table.insert(doData.ids,uireq.id or 1)

    return 1, 5001, doData:SerializeToString()
end

function NetCPRechargeGiftRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5001, "RechargeGiftReward")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)


    return { type = 5001, reward = gamedata:SomethingProcess(getData),}
end


--
--
function UICPDayDayGiftCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5002, "CPDayDayGift")

    return 1, 5002, nil
end

function NetCPDayDayGiftCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5002, "CPDayDayGift")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local cpnum = 0
    local cpday = 0
    local status = {}
    local time,day,rmb = 0,1,0
    for k,v in ipairs(ids.ids) do
        if k == 1 then
            cpnum = v
        elseif k == 2 then
            cpday = v
        elseif k == 3 then
            time = v
        elseif k == 4 then
            day = v
        elseif k == 5 then
            rmb = v
        else
            table.insert(status,v)
        end
    end

    return { type = 5002, time = time, day = day, rmb = rmb, status = status, cpnum = cpnum, cpday = cpday,}

end

function UICPDayDayGiftRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5003, "CPDayDayGiftReward")
    local doData = ids_pb.Ids()

    table.insert(doData.ids,uireq.id or 1)

    return 1, 5003, doData:SerializeToString()
end

function NetCPDayDayGiftRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5003, "CPDayDayGiftReward")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)


    return { type = 5003, reward = gamedata:SomethingProcess(getData),}
end


--
--

function UICPAchievementLimitTimeCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5025, "AchievementLimitTimeCallBack")

    return 1, 5025, nil
end

function NetCPAchievementLimitTimeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5025, "AchievementLimitTimeCallBack")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local cpnum = ids.ids[1] or 0
    local cpday = ids.ids[2] or 0

    local status = {}
    local configreward = gamedata.config["time_achievement"..(cpnum>0 and ("_"..cpnum) or "")] or {}

    for k,v in pairs(configreward) do
        local sorting = v.id+100
        if ids.ids[2*(v.id)+1] and ids.ids[2*(v.id)+1] == 1 then
            sorting = sorting-100
        elseif ids.ids[2*(v.id)+1] and ids.ids[2*(v.id)+1] == 2 then
            sorting = sorting+100
        end
        table.insert(status, {status = ids.ids[2*(v.id)+1] or 0, num = ids.ids[2*(v.id)+2] or 0, config = v, sorting = sorting})
    end

    table.sort(status, function(a, b)
        return a.sorting < b.sorting
    end)

    return { type = 5025, status = status, cpnum = cpnum, cpday = cpday}

end

function UICPAchievementLimitTimeRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5026, "AchievementLimitTimeReward")
    local doData = ids_pb.Ids()

    table.insert(doData.ids,uireq.id or 1)

    return 1, 5026, doData:SerializeToString()
end

function NetCPAchievementLimitTimeRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5026, "AchievementLimitTimeReward")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)


    return { type = 5026, reward = gamedata:SomethingProcess(getData),}
end


--
--  cp
function UICPContinue7QueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5046, "Continue7Query")

    return 1, 5046, nil
end

function NetCPContinue7QueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5046, "Continue7Query")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local cpnum = ids.ids[1] or 0
    local cpday = ids.ids[2] or 0

    local status = {}
    for k,v in ipairs(ids.ids) do
        if k >= 3 then
            table.insert(status,v)
        end
    end

    gamedata.cache.continue7 = status
    return { type = 5046, status = gamedata.cache.continue7, cpnum = cpnum, cpday = cpday}

end

function UICPContinue7RewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5047, "Continue7Reward")

    return 1, 5047, nil
end

function NetCPContinue7RewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5047, "Continue7Reward")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)


    return { type = 5047, reward = gamedata:SomethingProcess(getData),}
end

--
function UICPConsumeGiftCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5039, "ConsumeGift")

    return 1, 5039, nil
end

function NetCPConsumeGiftCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5039, "ConsumeGift")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local cpnum = ids.ids[1] or 0
    local cpday = ids.ids[2] or 0

    local status = {}
    local time = 0
    local goldNum = 0
    local datarewards = gamedata.config["consumegift_reward_"..cpnum]
    for k,v in ipairs(ids.ids) do
        if k == 1 then
            cpnum = v
        elseif k == 2 then
            cpday = v
        elseif k == 3 then
            time = v
        elseif k == 4 then
            goldNum = v
        elseif k > 4 then
            if (k-4) <= table.getTableLength(datarewards) then
                local sorting = 0
                if v == 1 then
                    sorting = 0 +  datarewards[tostring(k-4)].id
                else
                    sorting = v * 100 + datarewards[tostring(k-4)].id + 100
                end
                table.insert(status, {status = v, sorting = sorting, reward = datarewards[tostring(k-4)]})
            end
        end

    end

    table.sort(status, function(a, b)
        return a.sorting < b.sorting
    end)

    return { type = 5039, time = time, goldNum = goldNum, status = status, cpnum = cpnum, cpday = cpday}

end

function UICPConsumeGiftRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5040, "ConsumeGiftReward")
    local doData = ids_pb.Ids()

    table.insert(doData.ids,uireq.id or 1)

    return 1, 5040, doData:SerializeToString()
end

function NetCPConsumeGiftRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5040, "ConsumeGiftReward")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)


    return { type = 5040, reward = gamedata:SomethingProcess(getData),}
end


--
function UICPRechargeRebateCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5041, "RechargeRebateCallBack")

    return 1, 5041, nil
end

function NetCPRechargeRebateCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5041, "RechargeRebateCallBack")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local cpnum = ids.ids[1] or 0
    local cpday = ids.ids[2] or 0

    local data = {}
    data.num = ids.ids[3] or 0
    data.rebate = ids.ids[4] or 0
    data.status1 = ids.ids[5] or 0
    data.status2 = ids.ids[6] or 0
    data.status3 = ids.ids[7] or 0

    return { type = 5041, data = data, cpnum = cpnum, cpday = cpday}

end


--
function UICPRechargeRebateGetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5042, "RechargeRebateGetCallBack")
    local doData = ids_pb.Ids()

    table.insert(doData.ids,uireq.index or 1)

    return 1, 5042, doData:SerializeToString()

end

function NetCPRechargeRebateGetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5042, "RechargeRebateGetCallBack")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)


    return { type = 5042, reward = gamedata:SomethingProcess(getData),}
end

--
function UICPSingleRechargeGiftCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5050, "SingleRechargeGift")

    return 1, 5050, nil
end

function NetCPSingleRechargeGiftCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5050, "SingleRechargeGift")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local cpnum = ids.ids[1] or 0
    local cpday = ids.ids[2] or 0

    local status = {}
    local rechargeGift = gamedata.config["single_gift_"..cpnum] or {}

    for k,v in pairs(rechargeGift) do
        local sorting = v.id+100
        if ids.ids[2*(v.id)+1] and ids.ids[2*(v.id)+1] == 1 then
            sorting = sorting-100
        elseif ids.ids[2*(v.id)+1] and ids.ids[2*(v.id)+1] == 2 then
            sorting = sorting+100
        end
        table.insert(status, {status = ids.ids[2*(v.id)+1] or 0, rechargetimes = ids.ids[2*(v.id)+2] or 0, recharge = v, sorting = sorting})
    end

    table.sort(status, function(a, b)
        return a.sorting < b.sorting
    end)

    return { type = 5050, status = status, cpnum = cpnum, cpday = cpday}

end

function UICPSingleRechargeGiftRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5051, "SingleRechargeGiftReward")
    local doData = ids_pb.Ids()

    table.insert(doData.ids,uireq.id or 1)

    return 1, 5051, doData:SerializeToString()
end

function NetCPSingleRechargeGiftRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5051, "SingleRechargeGiftReward")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)


    return { type = 5051, reward = gamedata:SomethingProcess(getData),}
end

--

--
--
function UICPTotalRechargeQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5055, "TotalRechargeQueryCallBack")

    return 1, 5055, nil
end

function NetCPTotalRechargeQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5055, "TotalRechargeQueryCallBack")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local cpnum = ids.ids[1] or 0
    local cpday = ids.ids[2] or 0

    local data = {}
    data.status3 = {}
    data.now = ids.ids[2] or 1
    data.rmb = ids.ids[3] or 0
    data.day = ids.ids[4] or 0
    data.status1 = ids.ids[5] or 0
    data.status2 = ids.ids[6] or 0

    for i = 7,#ids.ids do
        data.status3[tostring(i-6)] = ids.ids[i] or 0
    end

    return { type = 5055, data = data, cpnum = cpnum, cpday = cpday}

end

--
function UICPTotalRechargeGetRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5056, "TotalRechargeGetRewardCallBack")
    local doData = ids_pb.Ids()

    gamedata.ext.TotalRechargeCost = uireq.cost or {}

    for k,v in pairs(gamedata.ext.TotalRechargeCost) do
        if v.cid == 1001 then
            if gamedata.cache.role.gold < tonumber(v.num) then
                return  0, 503, {type = 503, msgtype = "shortgold"}
            end
        else
            if gamedata.getStaffNum(v.cid).num < v.num then
                return 0,503,{type = 503,msgtype = "shortprop",id = v.cid,num = v.num}
            end
        end
    end

    --
    table.insert(doData.ids,uireq.opt or 1)
    table.insert(doData.ids,uireq.index or 1)
    return 1, 5056, doData:SerializeToString()

end

function NetCPTotalRechargeGetRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5056, "TotalRechargeGetRewardCallBack")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    if gamedata.ext.TotalRechargeCost and next(gamedata.ext.TotalRechargeCost) then
        for k,v in pairs(gamedata.ext.TotalRechargeCost) do
            gamedata:updateStaff({cid = v.cid,num = 0-v.num})
        end
    end

    return { type = 5056, reward = gamedata:SomethingProcess(getData),}
end


--
--
function UIWeekGiftCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5525, "WeekGiftCallBack")

    return 1, 5525, nil
end

function NetWeekGiftCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5525, "WeekGiftCallBack")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local status = {}
    local typeid = 1
    for k,v in ipairs(ids.ids) do
        if k == 1 then
            typeid = v
        else
            table.insert(status,v)
        end
    end

    return { type = 5525, typeid = typeid, status = status, }

end

function UIWeekGiftRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5526, "WeekGiftRewardCallBack")
    local doData = ids_pb.Ids()

    table.insert(doData.ids,uireq.id or 1)

    return 1, 5526, doData:SerializeToString()
end

function NetWeekGiftRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5526, "WeekGiftRewardCallBack")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)


    return { type = 5526, reward = gamedata:SomethingProcess(getData),}
end

function UINewRankQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6117, "UINewRankQueryCallBack")
    local rankData = ids_pb.Ids()

    table.insert(rankData.ids,uireq.id or 1)

    return 1,6117,rankData:SerializeToString()
end

function NetNewRankQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6117, "NetNewRankQueryCallBack")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    local status = ids.ids[1] or 0

    return { type = 6117, status = status,}

end


--
--
--
function UISingleRechargeGiftX1CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3755, "SingleRechargeGiftX1")

    return 1, 3755, nil
end

function NetSingleRechargeGiftX1CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3755, "SingleRechargeGiftX1")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local status = {}
    local rechargeGift = gamedata.config.single_gift_X1 or {}

    for k,v in pairs(rechargeGift) do
        local sorting = v.id+100
        if ids.ids[2*(v.id)-1] and ids.ids[2*(v.id)-1] == 1 then
            sorting = sorting-100
        elseif ids.ids[2*(v.id)-1] and ids.ids[2*(v.id)-1] == 2 then
            sorting = sorting+100
        end
        table.insert(status, {status = ids.ids[2*(v.id)-1] or 0, rechargetimes = ids.ids[2*(v.id)] or 0, recharge = v, sorting = sorting})
    end

    table.sort(status, function(a, b)
        return a.sorting < b.sorting
    end)

    return { type = 3755, status = status, }

end

function UISingleRechargeGiftRewardX1CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3756, "SingleRechargeGiftRewardX1")
    local doData = ids_pb.Ids()

    table.insert(doData.ids,uireq.id or 1)

    return 1, 3756, doData:SerializeToString()
end

function NetSingleRechargeGiftRewardX1CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3756, "SingleRechargeGiftRewardX1")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)


    return { type = 3756, reward = gamedata:SomethingProcess(getData),}
end

--
--
function UICPSingleRechargeGiftX1CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5060, "SingleRechargeGiftX1")

    return 1, 5060, nil
end

function NetCPSingleRechargeGiftX1CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5060, "SingleRechargeGiftX1")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local cpnum = ids.ids[1] or 0
    local cpday = ids.ids[2] or 0

    local status = {}
    local rechargeGift = gamedata.config["single_gift_X1_"..cpnum] or {}

    for k,v in pairs(rechargeGift) do
        local sorting = v.id+100
        if ids.ids[2*(v.id)+1] and ids.ids[2*(v.id)+1] == 1 then
            sorting = sorting-100
        elseif ids.ids[2*(v.id)+1] and ids.ids[2*(v.id)+1] == 2 then
            sorting = sorting+100
        end
        table.insert(status, {status = ids.ids[2*(v.id)+1] or 0, rechargetimes = ids.ids[2*(v.id)+2] or 0, recharge = v, sorting = sorting})
    end

    table.sort(status, function(a, b)
        return a.sorting < b.sorting
    end)

    return { type = 5060, status = status, cpnum = cpnum, cpday = cpday}

end

function UICPSingleRechargeGiftRewardX1CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5061, "SingleRechargeGiftRewardX1")
    local doData = ids_pb.Ids()

    table.insert(doData.ids,uireq.id or 1)

    return 1, 5061, doData:SerializeToString()
end

function NetCPSingleRechargeGiftRewardX1CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5061, "SingleRechargeGiftRewardX1")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)


    return { type = 5061, reward = gamedata:SomethingProcess(getData),}
end

--

function UISingleRechargeGift_X2CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5062, "SingleRechargeGiftX1")

    return 1, 5062, nil
end

function NetSingleRechargeGift_X2CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5062, "SingleRechargeGiftX1")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local status = {}
    local rechargeGift = gamedata.config.single_gift_x3 or {}

    for k,v in pairs(rechargeGift) do
        local sorting = v.id+100
        if ids.ids[2*(v.id)-1] and ids.ids[2*(v.id)-1] == 1 then
            sorting = sorting-100
        elseif ids.ids[2*(v.id)-1] and ids.ids[2*(v.id)-1] == 2 then
            sorting = sorting+100
        end
        table.insert(status, {status = ids.ids[2*(v.id)-1] or 0, rechargetimes = ids.ids[2*(v.id)] or 0, recharge = v, sorting = sorting})
    end

    table.sort(status, function(a, b)
        return a.sorting < b.sorting
    end)

    return { type = 5062, status = status, }

end

function UISingleRechargeGiftReward_X2CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5063, "SingleRechargeGiftRewardX1")
    local doData = ids_pb.Ids()

    table.insert(doData.ids,uireq.id or 1)

    return 1, 5063, doData:SerializeToString()
end

function NetSingleRechargeGiftReward_X2CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5063, "SingleRechargeGiftRewardX1")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    return { type = 5063, reward = gamedata:SomethingProcess(getData) }
end

