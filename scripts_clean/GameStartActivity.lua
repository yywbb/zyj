--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/6/12
-- Time: 11:15
-- To change this template use File | Settings | File Templates.
--

-- 海外版未开功能：十一活动，老玩家回归

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local combmessages_pb = require("combmessages_pb")

local purchases = 0

function UIBegin7DaysExtCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 36101, "Begin7Days")

    if gamedata.cache.stasrtactivityDay then
        return 0, 36101, {type = 36101, has = gamedata.cache.stasrtactivityDay<11}
    else
        return 1, 3610, nil
    end
end


function UIBegin7DaysCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3610, "Begin7Days")
    if uireq.ids then
        local ids = ids_pb.Ids()
        for k,v in ipairs(uireq.ids) do
            table.insert(ids.ids, v)
        end
        return 1, 3610, ids:SerializeToString()
    else
        return 1, 3610, nil
    end
end

function NetBegin7DaysCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3610, "Begin7Days")
    local datas = combmessages_pb.CombMessages()
    local ids = ids_pb.Ids()
    datas:ParseFromString(fd.rbuf)

    local data = {}
    local data1 = {}
    for k,v in ipairs(datas.messages) do
        data1 = {}
        ids:ParseFromString(v.data)
        for kk,vv in ipairs(ids.ids) do
            table.insert(data1, vv)
        end
        data[v.id] = data1
        if v.id == 0 then
            gamedata.cache.stasrtactivityDay = data1[1]
            if gamedata.cache.stasrtactivityDay>10 then
                break
            end
        end
    end

    return { type = 3610, data = data,}
end

local xgold = 0
function UIBegin7DaysRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3611, "Begin7DaysReward")
    if uireq.id then
        xgold = uireq.xgold or 0

        if gamedata.cache.role.gold < xgold+0 then
            return 0,503,{type = 503, msgtype = "shortgold"}
        end

        local ids = ids_pb.Ids()
        -- table.insert(ids.ids, uireq.id)
        if uireq.rewardData and next(uireq.rewardData) then
            for k,v in pairs(uireq.rewardData) do
                print("v = ",v)
                table.insert(ids.ids, v)
            end
        else
            table.insert(ids.ids, uireq.id)
        end
        
        if uireq.index and uireq.index > 0 then
            table.insert(ids.ids, uireq.index)
        end
        return 1, 3611, ids:SerializeToString()
    end
end

function NetBegin7DaysRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3611, "Begin7DaysReward")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    local reward = gamedata:SomethingProcess(getData)

    if next(reward) and (xgold+0 > 0) then
        gamedata:updateRoleGold(0-xgold,"开服活动购买",1)
    end

    return { type = 3611, reward = reward, xgold = xgold+0}
end


--
function UIOctober1stExtCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 37651, "October1st")

    if gamedata.cache.October1stDay then
        return 0, 37651, {type = 37651, has = gamedata.cache.October1stDay>0}
    else
        return 1, 3765, nil
    end
end


function UIOctober1stCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3765, "October1st")
    if uireq.ids then
        local ids = ids_pb.Ids()
        for k,v in ipairs(uireq.ids) do
            table.insert(ids.ids, v)
        end
        return 1, 3765, ids:SerializeToString()
    else
        return 1, 3765, nil
    end
end

function NetOctober1stCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3765, "October1st")
    local datas = combmessages_pb.CombMessages()
    local ids = ids_pb.Ids()
    datas:ParseFromString(fd.rbuf)

    local data = {}
    local data1 = {}
    for k,v in ipairs(datas.messages) do
        data1 = {}
        ids:ParseFromString(v.data)
        for kk,vv in ipairs(ids.ids) do
            table.insert(data1, vv)
        end
        data[v.id] = data1
        if v.id == 0 then
            gamedata.cache.October1stDay = data1[1]
        end
    end

    return { type = 3765, data = data,}
end

local xprop = {}
function UIOctober1stRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3766, "October1st")
    if uireq.id then
        xprop = uireq.xprop or {}
        local count = 0
        if uireq.rewardData and next(uireq.rewardData) then
            for i=1, table.getTableLength(uireq.rewardData) do
                count = count + 1
            end
        end
        if count == 0 then
            count = 1
        end
        purchases = count
        for k,v in pairs(xprop) do
            if gamedata.getStaffNum(v.cid).num < v.num*count then
                return 0,503,{type = 503,msgtype = "shortprop",id = v.cid,num = v.num*count}
            end
        end

        local ids = ids_pb.Ids()
        -- table.insert(ids.ids, uireq.id)
        if uireq.rewardData and next(uireq.rewardData) then
            for k,v in pairs(uireq.rewardData) do
                print("v = ",v)
                table.insert(ids.ids, v)
            end
        else
            table.insert(ids.ids, uireq.id)
        end
        return 1, 3766, ids:SerializeToString()
    end
end

function NetOctober1stRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3766, "October1st")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    local reward = gamedata:SomethingProcess(getData)

    if next(reward) and next(xprop) then
        for k,v in pairs(xprop) do
            gamedata:updateStaff({cid = v.cid,num = 0-(v.num*purchases)})
        end
    end

    return { type = 3766, reward = reward, xprop = xprop}
end



--
function UIReturnExtCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 37721, "ReturnExtCallBack")
    --
    local timelimit = 0
    if gamedata.config.global_kv.player_comeback_timelimit then
        timelimit = tonumber(gamedata.config.global_kv.player_comeback_timelimit.value)
    end

    if next(gamedata.cache.playerreturn) then
        return 0, 37721, {type = 37721, has = (gamedata.cache.playerreturn.playertype > 0) and (gamedata.cache.playerreturn.loginday <= timelimit)}
    else
        return 1, 3772, nil
    end
end


function UIReturnCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3772, "ReturnCallBack")

    return 1, 3772, nil
end

function NetReturnCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3772, "ReturnCallBack")
    local datas = combmessages_pb.CombMessages()
    local ids = ids_pb.Ids()
    datas:ParseFromString(fd.rbuf)

    for k,v in ipairs(datas.messages) do

        if v.id == 0 then
            ids:ParseFromString(v.data)
            gamedata.cache.playerreturn.playertype = ids.ids[1] or 0
            gamedata.cache.playerreturn.usecode = ids.ids[2] or 0
            gamedata.cache.playerreturn.loginday = ids.ids[3] or 0
            gamedata.cache.playerreturn.singlerecharge = ids.ids[4] or 0
            gamedata.cache.playerreturn.cumulativerecharge = ids.ids[5] or 0
        elseif v.id == 1 then
            ids:ParseFromString(v.data)
            gamedata.cache.playerreturn.status = {}
            for kk,vv in ipairs(ids.ids) do
                table.insert(gamedata.cache.playerreturn.status, vv)
            end
        elseif v.id == 2 then
            ids:ParseFromString(v.data)
            gamedata.cache.playerreturn.exchange = {}
            for kk,vv in ipairs(ids.ids) do
                table.insert(gamedata.cache.playerreturn.exchange, vv)
            end
        end

    end

    return { type = 3772, playerreturn = gamedata.cache.playerreturn,}
end

--
local ReturnXgold = 0
function UIReturnRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3773, "ReturnRewardCallBack")
    if uireq.id then

        ReturnXgold = uireq.xgold or 0
        if uireq.xgold and (uireq.xgold > gamedata.cache.role.gold) then
            return 0,503,{type = 503, msgtype = "shortgold"}
        end

        local ids = ids_pb.Ids()
        table.insert(ids.ids, uireq.id)
        return 1, 3773, ids:SerializeToString()
    end
end

function NetReturnRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3773, "ReturnRewardCallBack")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    local reward = gamedata:SomethingProcess(getData)

    if ReturnXgold and ReturnXgold > 0 then
        gamedata:updateRoleGold(0-ReturnXgold,"老玩家回归超值购买",1)
    end

    return { type = 3773, reward = reward}
end


local result_pb = require("result_pb")
local stringcontent_pb = require("stringcontent_pb")

function UIReturnCDKCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3774, "ReturnCDK")

    local codeData = stringcontent_pb.StringContent()
    codeData.content = uireq.code

    return 1, 3774, codeData:SerializeToString()
end

function NetReturnCDKCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3774, "ReturnCDK")

    local Result = result_pb.Result()
    Result:ParseFromString(fd.rbuf)


    return { type = 3774, result = Result.result}
end


--[[
[4880] = UISevenDayActivityCallBack,
[4881] = UISevenDayActivityRewardCallBack,
[48801] = UISevenDayActivityExtCallBack,
]]
--

--
function UISevenDayActivityExtCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 48801, "SevenDayActivity")

    if gamedata.cache.SevenDayActivityDay then
        return 0, 48801, {type = 48801, has = gamedata.cache.SevenDayActivityDay>0}
    else
        return 1, 4880, nil
    end
end


function UISevenDayActivityCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4880, "SevenDayActivity")
    if uireq.ids then
        local ids = ids_pb.Ids()
        for k,v in ipairs(uireq.ids) do
            table.insert(ids.ids, v)
        end
        return 1, 4880, ids:SerializeToString()
    else
        return 1, 4880, nil
    end
end

function NetSevenDayActivityCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4880, "SevenDayActivity")
    local datas = combmessages_pb.CombMessages()
    local ids = ids_pb.Ids()
    datas:ParseFromString(fd.rbuf)

    local data = {}
    local data1 = {}
    local data2 = {}
    for k,v in ipairs(datas.messages) do
        data1 = {}
        data2 = {}
        ids:ParseFromString(v.data)
        for kk,vv in ipairs(ids.ids) do
            table.insert(data1, vv)
        end

        if v.id == 1 then
            for i = 1,#data1/2 do
                data2[tostring(data1[2*i-1])] = data1[2*i]
            end
            data[v.id] = data2
        else
            data[v.id] = data1
        end

        if v.id == 0 then
            gamedata.cache.SevenDayActivityDay = data1[1]
        end
    end

    return { type = 4880, data = data,}
end

local n_xprop = {}
function UISevenDayActivityRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4881, "SevenDayActivity")
    if uireq.id then
        n_xprop = uireq.xprop or {}
        local count = 0
        if uireq.rewardData and next(uireq.rewardData) then
            for i=1, table.getTableLength(uireq.rewardData) do
                count = count + 1
            end
        end
        if count == 0 then
            count = 1
        end
        purchases = count
        for k,v in pairs(n_xprop) do
            if gamedata.getStaffNum(v.cid).num < v.num*count then
                return 0,503,{type = 503,msgtype = "shortprop",id = v.cid,num = v.num*count}
            end
        end

        local ids = ids_pb.Ids()
        table.insert(ids.ids, uireq.selectday or 1)
        table.insert(ids.ids, uireq.selectpage or 1)
        if uireq.rewardData and next(uireq.rewardData) then
            for k,v in pairs(uireq.rewardData) do
                print("v = ",v)
                table.insert(ids.ids, v)
            end
        else
            table.insert(ids.ids, uireq.id)
        end
        return 1, 4881, ids:SerializeToString()
    end
end

function NetSevenDayActivityRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4881, "SevenDayActivity")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    local reward = gamedata:SomethingProcess(getData)

    if next(reward) and next(n_xprop) then
        for k,v in pairs(n_xprop) do
            gamedata:updateStaff({cid = v.cid,num = 0-(v.num*purchases)})
        end
    end

    return { type = 4881, reward = reward, xprop = n_xprop}
end


--
--cp
--
function UICPSevenDayActivityExtCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 50481, "SevenDayActivity")

    if gamedata.cache.SevenDayActivityDay then
        return 0, 50481, {type = 50481, has = gamedata.cache.SevenDayActivityDay>0}
    else
        return 1, 5048, nil
    end
end


function UICPSevenDayActivityCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5048, "SevenDayActivity")
    if uireq.ids then
        local ids = ids_pb.Ids()
        for k,v in ipairs(uireq.ids) do
            table.insert(ids.ids, v)
        end
        return 1, 5048, ids:SerializeToString()
    else
        return 1, 5048, nil
    end
end

function NetCPSevenDayActivityCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5048, "SevenDayActivity")
    local datas = combmessages_pb.CombMessages()
    local ids = ids_pb.Ids()
    datas:ParseFromString(fd.rbuf)

    local data = {}
    local data1 = {}
    local data2 = {}
    for k,v in ipairs(datas.messages) do
        data1 = {}
        data2 = {}
        ids:ParseFromString(v.data)
        for kk,vv in ipairs(ids.ids) do
            table.insert(data1, vv)
        end

        if v.id == 1 then
            for i = 1,#data1/2 do
                data2[tostring(data1[2*i-1])] = data1[2*i]
            end
            data[v.id] = data2
        else
            data[v.id] = data1
        end

        if v.id == 0 then
            gamedata.cache.SevenDayActivityDay = data1[1]
        end
    end

    return { type = 5048, data = data,}
end

function UICPSevenDayActivityRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5049, "SevenDayActivity")
    if uireq.id then
        n_xprop = uireq.xprop or {}
        local count = 0
        if uireq.rewardData and next(uireq.rewardData) then
            for i=1, table.getTableLength(uireq.rewardData) do
                count = count + 1
            end
        end
        if count == 0 then
            count = 1
        end
        purchases = count
        for k,v in pairs(n_xprop) do
            if gamedata.getStaffNum(v.cid).num < v.num*count then
                return 0,503,{type = 503,msgtype = "shortprop",id = v.cid,num = v.num*count}
            end
        end

        local ids = ids_pb.Ids()
        table.insert(ids.ids, uireq.selectday or 1)
        table.insert(ids.ids, uireq.selectpage or 1)
        if uireq.rewardData and next(uireq.rewardData) then
            for k,v in pairs(uireq.rewardData) do
                print("v = ",v)
                table.insert(ids.ids, v)
            end
        else
            table.insert(ids.ids, uireq.id)
        end
        return 1, 5049, ids:SerializeToString()
    end
end

function NetCPSevenDayActivityRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5049, "SevenDayActivity")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    local reward = gamedata:SomethingProcess(getData)

    if next(reward) and next(n_xprop) then
        for k,v in pairs(n_xprop) do
            gamedata:updateStaff({cid = v.cid,num = 0-(v.num*purchases)})
        end
    end

    return { type = 5049, reward = reward, xprop = n_xprop}
end

--中秋
function UIZhongQiuActivityExtCallBack(uireq)
    if gamedata.cache.ZhongQiuActivityDay then
        return 0, 64011, {type = 64011, has = gamedata.cache.ZhongQiuActivityDay>0}
    else
        return 1, 6401, nil
    end
end

function UIZhongQiuActivityCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6401, "ZhongQiuActivity")
    if uireq.ids then
        local ids = ids_pb.Ids()
        for k,v in ipairs(uireq.ids) do
            table.insert(ids.ids, v)
        end
        return 1, 6401, ids:SerializeToString()
    else
        return 1, 6401, nil
    end
end

function NetZhongQiuActivityCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6401, "ZhongQiuActivity")
    local datas = combmessages_pb.CombMessages()
    local ids = ids_pb.Ids()
    datas:ParseFromString(fd.rbuf)

    local data = {}
    local data1 = {}
    local data2 = {}
    for k,v in ipairs(datas.messages) do
        data1 = {}
        data2 = {}
        ids:ParseFromString(v.data)
        for kk,vv in ipairs(ids.ids) do
            table.insert(data1, vv)
        end

        if v.id == 1 then
            for i = 1,#data1/2 do
                data2[tostring(data1[2*i-1])] = data1[2*i]
            end
            data[v.id] = data2
        else
            data[v.id] = data1
        end

        if v.id == 0 then
            gamedata.cache.ZhongQiuActivityDay = data1[1]
        end
    end

    return { type = 6401, data = data,}
end

local zhongqiu_xgold = 0
function UIZhongQiuActivityRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6402, "ZhongQiuReward")

    if uireq.id then
        zhongqiu_xgold = uireq.xgold or 0
        local count = 0
        if uireq.rewardData and next(uireq.rewardData) then
            for i=1, table.getTableLength(uireq.rewardData) do
                count = count + 1
            end
        end
        if count == 0 then
            count = 1
        end
        purchases = count
        if gamedata.cache.role.gold < zhongqiu_xgold*count then
            return 0,503,{type = 503, msgtype = "shortgold"}
        end

        local ids = ids_pb.Ids()
        -- table.insert(ids.ids, uireq.id)
        if uireq.rewardData and next(uireq.rewardData) then
            for k,v in pairs(uireq.rewardData) do
                print("v = ",v)
                table.insert(ids.ids, v)
            end
        else
            table.insert(ids.ids, uireq.id)
        end

        if uireq.index and uireq.index > 0 then
            table.insert(ids.ids, uireq.index)
        end
        return 1, 6402, ids:SerializeToString()
    end
end

function NetZhongQiuActivityRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6402, "ZhongQiuReward")

    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    local reward = gamedata:SomethingProcess(getData)

    if next(reward) and ((zhongqiu_xgold+0) > 0) then
        gamedata:updateRoleGold(0-(zhongqiu_xgold*purchases),"中秋活动购买",1)
    end

    return { type = 6402, reward = reward}
end


--    [6810] = UIPlayerBackTipsCallBack,
--    [6811] = UIPlayerBackQueryCallBack,
--    [6812] = UIPlayerBackRewardCallBack,
local PlayerBackTipsParam = ""
function UIPlayerBackTipsCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6810, "tips")

    PlayerBackTipsParam = uireq.param or ""

    return 1,6810,nil
end

function NetPlayerBackTipsCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6810, "tips")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    return {
        type = 6810,
        status = ids.ids[1] or 0,
        activity = ids.ids[2] or 0,
        param = PlayerBackTipsParam or "",
    }
end

function UIPlayerBackQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6811, "Query")

    return 1,6811,nil
end

function NetPlayerBackQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6811, "Query")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local playerback = {}
    playerback.status = ids.ids[1] or 0
    playerback.backday = ids.ids[2] or 0
    playerback.backlevel = ids.ids[3] or 0
    playerback.time = ids.ids[4] or 0
    playerback.rewardday = ids.ids[5] or 0
    playerback.rewardstatus = ids.ids[6] or 0
    playerback.reward = {}
    for k,v in ipairs(ids.ids) do
        if k > 6 then
            playerback.reward[tostring(k-6)] = v
        end            
    end    

    return {
        type=6811,
        playerback=playerback,
    }
end

function UIPlayerBackRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6812, "Reward")

    return 1,6812,nil
end


function NetPlayerBackRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6812, "Reward")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    local reward = gamedata:SomethingProcess(SomeThings)
    
    return {
        type=6812,
        reward = reward,
    }
end


------------日常轮换缔造神话
--
--cp
--
function UICPDiZaoShenHuaActivityExtCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 48861, "SevenDayActivity")

    if gamedata.cache.CPDiZaoShenHuaActivityDay then
        return 0, 48861, {type = 48861, has = gamedata.cache.CPDiZaoShenHuaActivityDay>0}
    else
        return 1, 4886, nil
    end
end


function UICPDiZaoShenHuaActivityCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4886, "SevenDayActivity")
    if uireq.ids then
        local ids = ids_pb.Ids()
        for k,v in ipairs(uireq.ids) do
            table.insert(ids.ids, v)
        end
        return 1, 4886, ids:SerializeToString()
    else
        return 1, 4886, nil
    end
end

function NetCPDiZaoShenHuaActivityCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4886, "SevenDayActivity")
    local datas = combmessages_pb.CombMessages()
    local ids = ids_pb.Ids()
    datas:ParseFromString(fd.rbuf)

    local data = {}
    local data1 = {}
    local data2 = {}
    for k,v in ipairs(datas.messages) do
        data1 = {}
        data2 = {}
        ids:ParseFromString(v.data)
        for kk,vv in ipairs(ids.ids) do
            table.insert(data1, vv)
        end

        if v.id == 1 then
            for i = 1,#data1/2 do
                data2[tostring(data1[2*i-1])] = data1[2*i]
            end
            data[v.id] = data2
        else
            data[v.id] = data1
        end

        if v.id == 0 then
            gamedata.cache.CPDiZaoShenHuaActivityDay = data1[1]
        end
    end

    return { type = 4886, data = data,}
end

function UICPDiZaoShenHuaActivityRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4887, "SevenDayActivity")
    if uireq.id then
        n_xprop = uireq.xprop or {}
        local count = 0
        if uireq.rewardData and next(uireq.rewardData) then
            for i=1, table.getTableLength(uireq.rewardData) do
                count = count + 1
            end
        end
        if count == 0 then
            count = 1
        end
        purchases = count
        for k,v in pairs(n_xprop) do
            if gamedata.getStaffNum(v.cid).num < v.num*count then
                return 0,503,{type = 503,msgtype = "shortprop",id = v.cid,num = v.num*count}
            end
        end

        local ids = ids_pb.Ids()
        table.insert(ids.ids, uireq.selectday or 1)
        table.insert(ids.ids, uireq.selectpage or 1)
        if uireq.rewardData and next(uireq.rewardData) then
            for k,v in pairs(uireq.rewardData) do
                print("v = ",v)
                table.insert(ids.ids, v)
            end
        else
            table.insert(ids.ids, uireq.id)
        end
        return 1, 4887, ids:SerializeToString()
    end
end

function NetCPDiZaoShenHuaActivityRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4887, "SevenDayActivity")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    local reward = gamedata:SomethingProcess(getData)

    if next(reward) and next(n_xprop) then
        for k,v in pairs(n_xprop) do
            gamedata:updateStaff({cid = v.cid,num = 0-(v.num*purchases)})
        end
    end

    return { type = 4887, reward = reward, xprop = n_xprop}
end



------------日常轮换天下无双
--
function UICPTianXiaWuShuangActivityExtCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 48881, "SevenDayActivity")

    if gamedata.cache.CPTianXiaWuShuangActivityDay then
        return 0, 48881, {type = 48881, has = gamedata.cache.CPTianXiaWuShuangActivityDay>0}
    else
        return 1, 4888, nil
    end
end


function UICPTianXiaWuShuangActivityCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4888, "SevenDayActivity")
    if uireq.ids then
        local ids = ids_pb.Ids()
        for k,v in ipairs(uireq.ids) do
            table.insert(ids.ids, v)
        end
        return 1, 4888, ids:SerializeToString()
    else
        return 1, 4888, nil
    end
end

function NetCPTianXiaWuShuangActivityCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4888, "SevenDayActivity")
    local datas = combmessages_pb.CombMessages()
    local ids = ids_pb.Ids()
    datas:ParseFromString(fd.rbuf)

    local data = {}
    local data1 = {}
    local data2 = {}
    for k,v in ipairs(datas.messages) do
        data1 = {}
        data2 = {}
        ids:ParseFromString(v.data)
        for kk,vv in ipairs(ids.ids) do
            table.insert(data1, vv)
        end

        if v.id == 1 then
            for i = 1,#data1/2 do
                data2[tostring(data1[2*i-1])] = data1[2*i]
            end
            data[v.id] = data2
        else
            data[v.id] = data1
        end

        if v.id == 0 then
            gamedata.cache.CPTianXiaWuShuangActivityDay = data1[1]
        end
    end

    return { type = 4888, data = data,}
end

function UICPTianXiaWuShuangActivityRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4889, "SevenDayActivity")
    if uireq.id then
        n_xprop = uireq.xprop or {}
        local count = 0
        if uireq.rewardData and next(uireq.rewardData) then
            for i=1, table.getTableLength(uireq.rewardData) do
                count = count + 1
            end
        end
        if count == 0 then
            count = 1
        end
        purchases = count
        for k,v in pairs(n_xprop) do
            if gamedata.getStaffNum(v.cid).num < v.num*count then
                return 0,503,{type = 503,msgtype = "shortprop",id = v.cid,num = v.num*count}
            end
        end

        local ids = ids_pb.Ids()
        table.insert(ids.ids, uireq.selectday or 1)
        table.insert(ids.ids, uireq.selectpage or 1)
        if uireq.rewardData and next(uireq.rewardData) then
            for k,v in pairs(uireq.rewardData) do
                print("v = ",v)
                table.insert(ids.ids, v)
            end
        else
            table.insert(ids.ids, uireq.id)
        end
        return 1, 4889, ids:SerializeToString()
    end
end

function NetCPTianXiaWuShuangActivityRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4889, "SevenDayActivity")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    local reward = gamedata:SomethingProcess(getData)

    if next(reward) and next(n_xprop) then
        for k,v in pairs(n_xprop) do
            gamedata:updateStaff({cid = v.cid,num = 0-(v.num*purchases)})
        end
    end

    return { type = 4889, reward = reward, xprop = n_xprop}
end

