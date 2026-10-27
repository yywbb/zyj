--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午7:10
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")


-- 端午嘉年华查询
function UIDuanWuQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3300, "ActivityBlackShop")
    print("UIDuanWuQueryCallBack...")
    -- local data = {100,2}
    -- gamedata:duanwunlunpanData(data)
        
    -- return 0, 3300, { type = 3300, maindata = gamedata.cache.duanwunlunpan.main, }

    return 1, 3300, nil
end

function NetDuanWuQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3300, "ActivityBlackShop")
    print("NetDuanWuQueryCallBack==")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata:duanwunlunpanData(ids.ids)

    
    return { type = 3300, maindata = gamedata.cache.duanwunlunpan.main,}
end


-- 端午嘉年华抽奖
function UIDuanWuLotteryQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3301, "ActivityShop")
    
    local isenough,ret = gamedata.checkStaffEnough(uireq.useId,uireq.useNum,{})
    if not isenough then
        return 0,503,ret
    end
    gamedata.ext.duanwanlunpanlotterycost = {cid=uireq.useId,num = -uireq.useNum,name = "端午嘉年华"}
    return 1, 3301, nil
end

function NetDuanWuLotteryQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3616, "ActivityShop")
    print("NetDuanWuLotteryQueryCallBack==")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    gamedata.cache.duanwunlunpan.main.pointScore = gamedata.cache.duanwunlunpan.main.pointScore + gamedata.config.global_kv.dragonboatfestival_number.value
    gamedata.cache.duanwunlunpan.main.lotteryNums = gamedata.cache.duanwunlunpan.main.lotteryNums + 1
    local toAdd = gamedata.ext.duanwanlunpanlotterycost.num == 0 and 1 or 0
    gamedata.cache.duanwunlunpan.main.lotteryFreeUsed = gamedata.cache.duanwunlunpan.main.lotteryFreeUsed + toAdd

    gamedata:updateStaff(gamedata.ext.duanwanlunpanlotterycost)
    return { type = 3301, reward = gamedata:SomethingProcess(getData), maindata = gamedata.cache.duanwunlunpan.main,}
end

-- 端午嘉年华兑换
function UIDuanWuDuihuanCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3302, "ActivityShop")
    -- printT(uireq)
    
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.id)
    if uireq.num then
        table.insert(idsData.ids, uireq.num)
        gamedata.ext.duanwuduihuanscore = uireq.spendscore * uireq.num
    else
        gamedata.ext.duanwuduihuanscore = uireq.spendscore
    end


    return 1, 3302, idsData:SerializeToString()
end

function NetDuanWuDuihuanCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3302, "ActivityShop")

    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)
    
    gamedata.cache.duanwunlunpan.main.pointScore = gamedata.cache.duanwunlunpan.main.pointScore - tonumber(gamedata.ext.duanwuduihuanscore)
    
    return { type = 3302, 
        reward = gamedata:SomethingProcess(getData),
        maindata = gamedata.cache.duanwunlunpan.main,}
end


--

function UITurntableQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4630, "TurntableQuery")

    return 1, 4630, nil
end

function NetTurntableQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4630, "TurntableQuery")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata:TurntableData(ids.ids)

    return { type = 4630, turntable = gamedata.cache.turntable,}
end

--
function UITurntableLotteryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4631, "TurntableLottery")

    gamedata.ext.TurntableLotteryNum = uireq.num or 1
    local isenough,ret = gamedata.checkStaffEnough(uireq.useId,uireq.useNum,{})
    if not isenough then
        return 0,503,ret
    end
    gamedata.ext.TurntableLotteryCost1 = {cid = uireq.useId,num = -uireq.useNum}
    
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.num or 1)
    return 1, 4631, idsData:SerializeToString()
    
end

local combmessages_pb = require("combmessages_pb")
function NetTurntableLotteryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4631, "TurntableLottery")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local reward = {}
    local rewardpos = 1

    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:TurntableData(ids.ids)
            rewardpos = ids.ids[4] or 1
        elseif v.id == 1 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
        end
    end

    gamedata:updateStaff(gamedata.ext.TurntableLotteryCost1)

    return { type = 4631, reward = reward, rewardpos = rewardpos, turntable = gamedata.cache.turntable,}
end


--

function UIDivideStallCarnivalQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4650, "DivideStallCarnivalQuery")

    return 1, 4650, nil
end

function NetDivideStallCarnivalQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4650, "DivideStallCarnivalQuery")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata:CarnivalData(ids.ids)

    return { type = 4650, carnival = gamedata.cache.carnival,}
end


function UIDivideStallCarnivalDrawCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4651, "DivideStallCarnivalDraw")

    local isenough,ret = gamedata.checkStaffEnough(uireq.useId,uireq.useNum,{})
    if not isenough then
        return 0,503,ret
    end
    gamedata.ext.CarnivalLotteryNum = uireq.num or 1
    gamedata.ext.CarnivalLotteryCost = {cid=uireq.useId,num = -uireq.useNum}

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.num or 1)
    return 1, 4651, idsData:SerializeToString()
end

function NetDivideStallCarnivalDrawCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4651, "DivideStallCarnivalDraw")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local reward = {}
    local rewardpos = 1

    for k,v in ipairs(datas.messages) do
        if v.id == 1 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:CarnivalData(ids.ids)
            rewardpos = ids.ids[3] or 1
        elseif v.id == 2 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
        end
    end

    gamedata:updateStaff(gamedata.ext.CarnivalLotteryCost)

    return { type = 4651, reward = reward, rewardpos = rewardpos, carnival = gamedata.cache.carnival,}
end


--

function UIIntegralTurntableQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4660, "IntegralTurntableQuery")

    return 1, 4660, nil
end

function NetIntegralTurntableQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4660, "IntegralTurntableQuery")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata:IntegralTurntableData(ids.ids)

    return { type = 4660, integralturntable = gamedata.cache.integralturntable,}
end


function UIIntegralTurntableLuckDrawCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4661, "IntegralTurntableLuckDraw")

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.num or 1)
    return 1, 4661, idsData:SerializeToString()

end

function NetIntegralTurntableLuckDrawCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4661, "IntegralTurntableLuckDraw")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local reward = {}
    local rewardpos = 1

    for k,v in ipairs(datas.messages) do
        if v.id == 1 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:IntegralTurntableData(ids.ids)
            rewardpos = ids.ids[3] or 1
        elseif v.id == 2 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
        end
    end

    return { type = 4661, reward = reward, rewardpos = rewardpos, integralturntable = gamedata.cache.integralturntable,}
end

--
function NetRechargeScoreCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 118, "RechargeScore")

    local reward = {}
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    reward = gamedata:SomethingProcess(SomeThings)

    return { type = 118, reward = reward}
end



-- todo
--
--[4635] = NetTurntableWorldQueryCallBack,
--[4636] = NetTurntableWorldDrawCallBack,

function UITurntableWorldQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4635, "TurntableWorldQueryCallBack")

    return 1, 4635, nil
end

function NetTurntableWorldQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4635, "TurntableWorldQueryCallBack")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata:k_TurntableData(ids.ids)

    return { type = 4635, turntable = gamedata.cache.k_turntable,}
end

--
function UITurntableWorldDrawCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4636, "TurntableWorldDrawCallBack")

    gamedata.ext.k_TurntableLotteryNum = uireq.num or 1
    local isenough,ret = gamedata.checkStaffEnough(uireq.useId,uireq.useNum,{})
    if not isenough then
        return 0,503,ret
    end
    gamedata.ext.k_TurntableLotteryCost = {cid=uireq.useId,num = -uireq.useNum}
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.num or 1)
    return 1, 4636, idsData:SerializeToString()
end

local combmessages_pb = require("combmessages_pb")
function NetTurntableWorldDrawCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4636, "TurntableWorldDrawCallBack")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local reward = {}
    local rewardpos = 1

    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:k_TurntableData(ids.ids)
            rewardpos = ids.ids[4] or 1
        elseif v.id == 1 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
        end
    end
    --local toAdd = gamedata.ext.k_TurntableLotteryCost.num == 0 and 1 or 0

    gamedata:updateStaff(gamedata.ext.k_TurntableLotteryCost)
    return { type = 4636, reward = reward, rewardpos = rewardpos, turntable = gamedata.cache.k_turntable,}
end



--     [4885] = UITurntableRecordCallBack,

local params_pb = require("params_pb")
function UITurntableRecordCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4885, "UITurntableRecordCallBack")

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.typeindex or 1)
    return 1, 4885, idsData:SerializeToString()

end

function NetTurntableRecordCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4885, "NetTurntableRecordCallBack")

    local messages = {}
    local params = params_pb.ParamS()
    params:ParseFromString(fd.rbuf)
    for i = 1,#params.params/2 do
        messages[tostring(i)] = {}
        messages[tostring(i)].num = params.params[2*i-1] and params.params[2*i-1].i or 0
        messages[tostring(i)].name = params.params[2*i-1] and params.params[2*i-1].s or ""
        messages[tostring(i)].service = params.params[2*i] and params.params[2*i].i or 0
        messages[tostring(i)].time = params.params[2*i] and params.params[2*i].s or ""
    end

    return { type = 4885, messages = messages or {}}
end

function UITurntableRecordCommonCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5346, "UITurntableRecordCommonCallBack")

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.systemId or 1)
    return 1, 5346, idsData:SerializeToString()
end

function NetTurntableRecordCommonCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5346, "NetTurntableRecordCommonCallBack")

    local messages = {}
    local params = params_pb.ParamS()
    params:ParseFromString(fd.rbuf)
    for i = 1,#params.params/3 do
        messages[tostring(i)] = {}
        messages[tostring(i)].id = params.params[3*i-2] and params.params[3*i-2].i or 0
        messages[tostring(i)].name = params.params[3*i-2] and params.params[3*i-2].s or ""
        messages[tostring(i)].service = params.params[3*i - 1] and params.params[3*i - 1].i or 0
        messages[tostring(i)].time = params.params[3*i - 1] and params.params[3*i - 1].s or ""
        messages[tostring(i)].num = params.params[3*i] and params.params[3*i].i or 0
        messages[tostring(i)].type = params.params[3*i] and params.params[3*i].s or ""
    end
    return { type = 5346, messages = messages or {}}
end



-- cp
local Turntable_cpnum = 0
local Turntable_cpday = 0
function UICPTurntableQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5037, "TurntableQuery")

    return 1, 5037, nil
end

function NetCPTurntableQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5037, "TurntableQuery")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    Turntable_cpnum = ids.ids[1] or 0
    Turntable_cpday = ids.ids[2] or 0

    gamedata.cache.turntable = {}
    gamedata.cache.turntable.lotteryNums = ids.ids[3] or 0
    gamedata.cache.turntable.goldNums = ids.ids[4] or 0
    gamedata.cache.turntable.lotteryFreeUsed = ids.ids[5] or 0

    return { type = 5037, turntable = gamedata.cache.turntable,cpnum = Turntable_cpnum,cpday = Turntable_cpday}
end

--
function UICPTurntableLotteryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5038, "TurntableLottery")

    
    local isenough, ret = gamedata.checkStaffEnough(uireq.useId,uireq.useNum,{})

    if not isenough then
        return 0,503,ret
    end
    gamedata.ext.TurntableLotteryCost = {cid=uireq.useId,num = -uireq.useNum}
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.num or 1)
    return 1, 5038, idsData:SerializeToString()
    
end

function NetCPTurntableLotteryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5038, "TurntableLottery")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local reward = {}
    local rewardpos = 1

    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:TurntableData(ids.ids)
            rewardpos = ids.ids[4] or 1
        elseif v.id == 1 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
        end
    end
    --local toAdd = gamedata.ext.TurntableLotteryCost.num == 0 and 1 or 0
    --gamedata.cache.turntable.lotteryFreeUsed = toAdd + gamedata.cache.turntable.lotteryFreeUsed
    gamedata:updateStaff(gamedata.ext.TurntableLotteryCost)
    return { type = 5038, reward = reward, rewardpos = rewardpos, turntable = gamedata.cache.turntable,cpnum = Turntable_cpnum,cpday = Turntable_cpday}
end


--
local IntegralTurntable_cpnum = 0
local IntegralTurntable_cpday = 0

function UICPIntegralTurntableQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5057, "IntegralTurntableQuery")

    return 1, 5057, nil
end

function NetCPIntegralTurntableQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5057, "IntegralTurntableQuery")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    IntegralTurntable_cpnum = ids.ids[1] or 0
    IntegralTurntable_cpday = ids.ids[2] or 0

    gamedata.cache.integralturntable = {}
    gamedata.cache.integralturntable.lotteryScore = ids.ids[3] or 1
    gamedata.cache.integralturntable.lotteryNums = ids.ids[4] or 0

    return { type = 5057, integralturntable = gamedata.cache.integralturntable, cpnum = IntegralTurntable_cpnum, cpday = IntegralTurntable_cpday}
end


function UICPIntegralTurntableLuckDrawCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5058, "IntegralTurntableLuckDraw")

    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.num or 1)
    return 1, 5058, idsData:SerializeToString()

end

function NetCPIntegralTurntableLuckDrawCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5058, "IntegralTurntableLuckDraw")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local reward = {}
    local rewardpos = 1

    for k,v in ipairs(datas.messages) do
        if v.id == 1 then
            local ids = ids_pb.Ids()
            ids:ParseFromString(v.data)
            gamedata:IntegralTurntableData(ids.ids)
            rewardpos = ids.ids[3] or 1
        elseif v.id == 2 then
            local SomeThings = somethings_pb.SomeThings()
            SomeThings:ParseFromString(v.data)
            reward = gamedata:SomethingProcess(SomeThings)
        end
    end

    return { type = 5058, reward = reward, rewardpos = rewardpos, integralturntable = gamedata.cache.integralturntable,cpnum = IntegralTurntable_cpnum, cpday = IntegralTurntable_cpday}
end
