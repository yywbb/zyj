--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/4
-- Time: 下午7:48
-- To change this template use File | Settings | File Templates.
--

function UIHappinessPlaceQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2030, "HappinessPlace")

    return 1,2030,nil
end

local happinessplace_pb = require"happinessplace_pb"
function NetHappinessPlaceQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2030, "HappinessPlace")
    local HappinessPlaceResponse = happinessplace_pb.HappinessPlace()
    HappinessPlaceResponse:ParseFromString(fd.rbuf)

    gamedata:HappinessPlace(HappinessPlaceResponse)

    return {type=2030, happinessplace = gamedata.cache.happinessplace}
end



function UIHappinessPlaceUseCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2031, "HappinessPlaceUse")

    gamedata.ext.HappinessPlaceUse = uireq.method

    return 1, 2031, nil
end

local somethings_pb = require("somethings_pb")
function NetHappinessPlaceUseCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2031, "HappinessPlaceUse")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    local ischange = 0

    if gamedata.ext.HappinessPlaceUse == 1 then
        gamedata.cache.happinessplace.free = gamedata.cache.happinessplace.free -1
        --if  gamedata.cache.happinessplace.free == 0 then
        --    gamedata.cache.happinessplace.freetime = 0
        --else
            gamedata.cache.happinessplace.freetime = 7200
            ischange = 1
        --end
    else
        gamedata:updateRoleGold(-50,"琅嬛福地",1)
    end

    return { type = 2031, reward = gamedata:SomethingProcess(SomeThings),happinessplace = gamedata.cache.happinessplace,opt = gamedata.ext.HappinessPlaceUse,ischange = ischange,}
end

local function makeHappinessPlaceRankPlayers(data)
    local palyers ={}
    for k,v in ipairs(data) do
        table.insert(palyers,gamedata:playerdata(v))
    end

    local function sortByStone(a,b) return a.param > b.param  end
    table.sort(palyers,sortByStone)

    return palyers
end


function UIHappinessPlaceRankCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2032, "HappinessPlaceRank")

    return 1, 2032, nil
end

local players_pb = require("players_pb")
function NetHappinessPlaceRankCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2032, "HappinessPlaceRank")
    local playersData = players_pb.Players()
    playersData:ParseFromString(fd.rbuf)

    return { type = 2032, players = makeHappinessPlaceRankPlayers(playersData.players) }
end

local ids_pb = require("ids_pb")
function UIHappinessPlaceExchangeCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2033, "HappinessPlaceExchange")
    local HappinessPlaceUseData = ids_pb.Ids()

    table.insert(HappinessPlaceUseData.ids, uireq.id)

    gamedata.ext.HappinessPlaceExchange = uireq.id

    return 1, 2033, HappinessPlaceUseData:SerializeToString()
end

function NetHappinessPlaceExchangeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2033, "HappinessPlaceExchange")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    gamedata.cache.happinessplace.stone = gamedata.cache.happinessplace.stone - gamedata.config.happinessplace_exchange[tostring(gamedata.ext.HappinessPlaceExchange)].stone

    return { type = 2033, reward = gamedata:SomethingProcess(SomeThings), happinessplace = gamedata.cache.happinessplace}
end


local ids_pb = require("ids_pb")
function UIHappinessPlaceServerRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2034, "HappinessPlaceServerReward")
    local HappinessPlaceServerRewardData = ids_pb.Ids()

    table.insert(HappinessPlaceServerRewardData.ids, uireq.id)

    gamedata.ext.HappinessPlaceServerRewardid = uireq.id

    return 1, 2034, HappinessPlaceServerRewardData:SerializeToString()
end

function NetHappinessPlaceServerRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2034, "HappinessPlaceServerReward")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    gamedata.cache.happinessplace.rewards[gamedata.ext.HappinessPlaceServerRewardid] = 1

    return { type = 2034, reward = gamedata:SomethingProcess(SomeThings),happinessplace = gamedata.cache.happinessplace}
end