--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/26
-- Time: 下午6:00
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")

local FIRSTTIME_HOUR24=12
local SECONDTIME_HOUR24=18
local THRIDTIME_HOUR24=21

local eatconfig = {
    [1] = {begin_t = 12*60*60, end_t = 14*60*60,},
    [2] = {begin_t = 18*60*60, end_t = 20*60*60,},
    [3] = {begin_t = 21*60*60, end_t = 24*60*60},
}

local function UIActivityEatChickenQueryResponse()

    local t = os.date("*t", gamedata:time())
    local nowsec = t.hour*60*60 + t.min*60 + t.sec
    local activity = gamedata.cache.chicken

    printT(gamedata.cache.chicken,"UIActivityEatChickenQueryResponse")
    for k,v in ipairs(activity) do
        if v ~= 2 then
            if nowsec > eatconfig[k].end_t then
                activity[k] = 3
            elseif nowsec < eatconfig[k].begin_t then
                activity[k] = 1
            else
                activity[k] = 0
            end
        end
    end
    printT(gamedata.cache.chicken,"UIActivityEatChickenQueryResponse")
    return gamedata.cache.chicken
end

local function UIActivityEatChickenStatus()

    local t = os.date("*t",gamedata:time())
    local nowsec = t.hour*60*60 + t.min*60 + t.sec
    local activity = gamedata.cache.chicken
    local status = 0
    for k,v in ipairs(eatconfig) do
            if nowsec > eatconfig[k].begin_t and nowsec < eatconfig[k].end_t then
                if activity[k] == 2 then
                    status = 2
                elseif activity[k] == 0 then
                    status = 0

                end
                break;
            else
                status = 1
            end
    end

    return status
end

function UIActivityEatChickenQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2010, "ActivityEatChickenQuery")

    if next(gamedata.cache.chicken) ~= nil then
        return 0, 2010, { type = 2010, status = UIActivityEatChickenQueryResponse(),nowstatus = UIActivityEatChickenStatus() }
    else
        return 1, 2010, nil
    end

end

function NetActivityEatChickenQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2010, "ActivityEatChickenQuery")
    local eatData = ids_pb.Ids()
    eatData:ParseFromString(fd.rbuf)

    gamedata:Chicken(eatData)
    --printT(gamedata.cache.chicken,"chicken-----------")

    return { type = 2010, status = UIActivityEatChickenQueryResponse(),nowstatus = UIActivityEatChickenStatus() }
end

function UIEatChickenCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2011, "ActivityEatChicken")
    gamedata.ext.eatChickenGold = uireq.gold
    return 1, 2011, nil
end

function NetEatChickenCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2011, "ActivityEatChicken")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    local t = os.date("*t", gamedata:time())
    local nowsec = t.hour*60*60 + t.min*60 + t.sec

    for k,v in ipairs(eatconfig) do
        if nowsec >= v.begin_t and nowsec <= v.end_t then
            gamedata.cache.chicken[k] = 2
        end
    end

    return {
        type = 2011,
        status = UIActivityEatChickenQueryResponse(),
        nowstatus = UIActivityEatChickenStatus(),
        reward = gamedata:SomethingProcess(SomeThings),
        isEatPeaceAni = 1, --提示是吃桃动画请求回的消息
        goldNum = gamedata.ext.eatChickenGold ,
    }
end