--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/1/20
-- Time: 上午11:40
-- To change this template use File | Settings | File Templates.
--


local mysticalcave_pb = require("mysticalcave_pb")
local somethings_pb = require("somethings_pb")
local ids_pb = require("ids_pb")

function UIMysticalCaveCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2050, "MysticalCave")

    if next(gamedata.cache.cave) ~= nil then
        return 0, 2050, { type = 2050, status = gamedata.cache.cave }
    else
        return 1, 2050, nil
    end

end

function NetMysticalCaveCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2050, "MysticalCave")
    local CaveData = mysticalcave_pb.MysticalCave()
    CaveData:ParseFromString(fd.rbuf)

    gamedata:Cave(CaveData)

    return { type = 2050, status = gamedata.cache.cave }
end

----------------------------------------------------------------------------------------------------------------------------------------------------

function UIMysticalCaveForecastCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2051, "MysticalCaveForecast")

    return 1, 2051, nil
end

function NetMysticalCaveForecastCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2051, "MysticalCaveForecast")
    local CaveData = mysticalcave_pb.MysticalCave()
    CaveData:ParseFromString(fd.rbuf)

    gamedata:Cave(CaveData)

    return { type = 2051, status = gamedata.cache.cave }
end

----------------------------------------------------------------------------------------------------------------------------------------------------

function UIMysticalCaveReversionCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2052, "MysticalCaveReversion")

    return 1, 2052, nil
end

function NetMysticalCaveReversionCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2052, "MysticalCaveReversion")
    local CaveData = mysticalcave_pb.MysticalCave()
    CaveData:ParseFromString(fd.rbuf)

    if gamedata.cache.cave.reversion<= 0 then
        gamedata:updateRoleGold(-math.ldexp(5,math.abs(gamedata.cache.cave.reversion)),"仙洞逆转",1)
    end

    gamedata:Cave(CaveData)

    return { type = 2052, status = gamedata.cache.cave }
end


----------------------------------------------------------------------------------------------------------------------------------------------------

function UIMysticalCaveConfirmCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2053, "MysticalCaveConfirm")

    return 1, 2053, nil
end

function NetMysticalCaveConfirmCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2053, "MysticalCaveConfirm")
    local rewardData = somethings_pb.SomeThings()
    rewardData:ParseFromString(fd.rbuf)

    for i=1, #gamedata.cache.cave.position do
        gamedata.cache.cave.position[i] = 0
    end


    return { type = 2053, reward = gamedata:SomethingProcess(rewardData),status = gamedata.cache.cave }
end


----------------------------------------------------------------------------------------------------------------------------------------------------

function UIMysticalRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2054, "Reward")

    return 1, 2054, nil
end

function NetMysticalRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2054, "Reward")
    local rewardData = somethings_pb.SomeThings()
    rewardData:ParseFromString(fd.rbuf)

    gamedata.cache.cave.position2[#gamedata.cache.cave.position2] = 3

    return { type = 2054, reward = gamedata:SomethingProcess(rewardData),status = gamedata.cache.cave }
end


----------------------------------------------------------------------------------------------------------------------------------------------------
--new

function UIMysticalStargazingCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI",2062,"MysticalStargazing")
    return 1,2062,nil
end

function NetMysticalStargazingCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2062, "MysticalStargazing")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata:ActivityWatchStar(ids)

    return {type = 2062, data = gamedata.cache.activityWatchStar or {}}
end

----------------------------------------------------------------------------------------------------------------------------------------------------


function UIMysticalSwacthStarCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI",2063,"MysticalSwacthStar")
    return 1,2063,nil
end

function NetMysticalSwacthStarCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2063, "MysticalSwacthStar")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata:ActivityWatchStar(ids)

    return {type = 2063,data = gamedata.cache.activityWatchStar or {}}
end


----------------------------------------------------------------------------------------------------------------------------------------------------


function UIMysticalChangeSwacthStarCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI",2064,"MysticalChangeSwacthStar")

    gamedata.ext.watchstargold = uireq.xnum or 0

    if gamedata.ext.watchstargold > gamedata.cache.role.gold then
        return 0,503,{type = 503, msgtype = "shortgold" }
    end

    return 1,2064,nil
end

function NetMysticalChangeSwacthStarCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2064, "MysticalChangeSwacthStar")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata:ActivityWatchStar(ids)

    if gamedata.ext.watchstargold and gamedata.ext.watchstargold > 0 then
        gamedata:updateRoleGold(0-gamedata.ext.watchstargold,"观星",1)
    end

    return {type = 2064,data = gamedata.cache.activityWatchStar or {},gold = gamedata.cache.role.gold}
end


----------------------------------------------------------------------------------------------------------------------------------------------------


function UIGetWatchStartCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI",2065,"GetWatchStart")
    return 1,2065,nil
end

function NetGetWatchStartCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2065, "GetWatchStart")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata:ActivityWatchStar(ids)

    return {type = 2065,data = gamedata.cache.activityWatchStar or {}}
end


----------------------------------------------------------------------------------------------------------------------------------------------------


function UIWatchStarRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI",2066,"WatchStarReward")
    return 1,2066,nil
end

function NetWatchStarRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2066, "WatchStarReward")
    local rewardData = somethings_pb.SomeThings()
    rewardData:ParseFromString(fd.rbuf)


    return { type = 2066, reward = gamedata:SomethingProcess(rewardData),status = {} }
end

----------------------------------------------------------------------------------------------------------------------------------------------------

function UIWatchStarWatchExCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI",2067,"WatchStarWatchEx")

    gamedata.ext.watchstargold = uireq.xnum or 0

    if gamedata.ext.watchstargold > gamedata.cache.role.gold then
        return 0,503,{type = 503, msgtype = "shortgold" }
    end

    return 1,2067,nil
end

function NetWatchStarWatchExCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2067, "WatchStarWatchEx")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata:ActivityWatchStar(ids)

    if gamedata.ext.watchstargold and gamedata.ext.watchstargold > 0 then
        gamedata:updateRoleGold(0-gamedata.ext.watchstargold,"观星",1)
    end

    return {type = 2067,data = gamedata.cache.activityWatchStar or {}}
end


function UIWatchStarUpLevelCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI",2068,"WatchStarUpLevel")

    gamedata.ext.WatchStarUpLevelNeed = uireq.need or {}

    for k,v in pairs(gamedata.ext.WatchStarUpLevelNeed) do
        if v.cid == 1001 then
            if v.num > gamedata.cache.role.gold then
                return 0,503,{type = 503, msgtype = "shortgold" }
            end
        elseif v.cid == 1000 then
            if v.num > gamedata.cache.role.coin then
                return 0,503,{type = 503, msgtype = "shortcoin" }
            end
        else
            if gamedata.getStaffNum(v.cid).num < v.num then
                return 0,503,{type = 503,msgtype = "shortprop",id= v.cid,num= v.num}
            end
        end
    end

    return 1,2068,nil
end

function NetWatchStarUpLevelCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2068, "WatchStarUpLevel")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    if gamedata.cache.activityWatchStar and gamedata.cache.activityWatchStar.rewardlevel then
        gamedata.cache.activityWatchStar.rewardlevel = ids.ids[1] or 1
    end

    if gamedata.ext.WatchStarUpLevelNeed and next(gamedata.ext.WatchStarUpLevelNeed) then
        for k,v in pairs(gamedata.ext.WatchStarUpLevelNeed) do
            gamedata:updateStaff({cid = v.cid,num = 0-v.num})
        end
    end

    return {type = 2068,data = gamedata.cache.activityWatchStar or {}}
end
 [%  