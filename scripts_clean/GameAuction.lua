--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/1/13
-- Time: 10:29
-- To change this template use File | Settings | File Templates.
--
 --[[
[4810] = UIAuctionHouseQueryCallBack,
[4811] = UIAuctionHouseAuctionCallBack,
[4812] = UIAuctionHouseGetCallBack,
[4813] = UIAuctionHouseLogCallBack,
[4814] = UIAuctionHouseOptsCallBack,
[4815] = NetAuctionHouseChangeCallBack,
]]

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local params_pb = require("params_pb")

function UIAuctionHouseQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4810, "AuctionHouseQuery")

    return 1, 4810, nil
end

function NetAuctionHouseQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4810, "AuctionHouseQuery")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata:AuctionData(ids.ids)

    return { type = 4810, auction = gamedata.cache.auction }

end

--
function UIAuctionHouseAuctionCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4811, "AuctionHouseAuction")

    gamedata.ext.auctionID = uireq.id or 0
    gamedata.ext.auctionNum = uireq.num or 0

    if gamedata.cache.role.gold < tonumber(gamedata.ext.auctionNum) then
        return  0, 503, {type = 503, msgtype = "shortgold"}
    else
        local idsData = ids_pb.Ids()
        table.insert(idsData.ids, uireq.id or 0)
        table.insert(idsData.ids, uireq.num or 0)
        return 1, 4811, idsData:SerializeToString()
    end
end

function NetAuctionHouseAuctionCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4811, "AuctionHouseAuction")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local result = 0
    if ids.ids[1] and ids.ids[1] == 1 then
        result = 1
        if gamedata.ext.auctionNum and gamedata.ext.auctionNum > 0 then
            gamedata:updateRoleGold(0-gamedata.ext.auctionNum,"拍卖行竞拍",1)
        end
    end

    return { type = 4811, result = result}
end

--
function UIAuctionHouseGetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4812, "AuctionHouseGet")

    gamedata.ext.auctionGetID = uireq.id or 0
    gamedata.ext.auctionGetNum = uireq.num or 0

    if gamedata.cache.role.gold < tonumber(gamedata.ext.auctionGetNum) then
        return  0, 503, {type = 503, msgtype = "shortgold"}
    else
        local idsData = ids_pb.Ids()
        table.insert(idsData.ids, uireq.id or 0)
        return 1, 4812, idsData:SerializeToString()
    end
end

function NetAuctionHouseGetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4812, "AuctionHouseGet")

    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    gamedata:updateRoleGold(0-gamedata.ext.auctionGetNum,"拍卖行一口价",1)

    return { type = 4812, reward = gamedata:SomethingProcess(getData), }
end


function UIAuctionHouseLogCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4813, "AuctionHouseLog")

    return 1, 4813, nil
end

function NetAuctionHouseLogCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4813, "AuctionHouseLog")
    --[[
    local broadcast = params_pb.ParamS()
    broadcast:ParseFromString(fd.rbuf)

    local data1 = {}
    local data2 = {}
    for k,v in ipairs(broadcast.params) do
        if v.i and v.i == 2 then
            table.insert(data2,v.s)
        else
            table.insert(data1,v.s)
        end
    end

    return { type = 4813, messages1 = data1, messages2 = data2 }
    ]]

    local data1 = {}
    local data2 = {}
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    for i = 1,#ids.ids,5 do
        local message = {}
        message.s_type = ids.ids[i] or 1
        message.s_opt = ids.ids[i+1] or 1
        message.s_id = ids.ids[i+2] or 0
        message.s_num = ids.ids[i+3] or 0
        message.s_time = ids.ids[i+4] or 0
        if message.s_type == 2 then
            table.insert(data2,message)
        else
            table.insert(data1,message)
        end
    end

    return { type = 4813, messages1 = data1, messages2 = data2 }
end

function UIAuctionHouseOptsCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4814, "AuctionHouseOpts")

    return 1, 4814, nil
end

function NetAuctionHouseOptsCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4814, "AuctionHouseOpts")

    --[[
    local broadcast = params_pb.ParamS()
    broadcast:ParseFromString(fd.rbuf)

    local data = {}
    for k,v in ipairs(broadcast.params) do
        table.insert(data,v.s)
    end

    return { type = 4814, messages = data }
    ]]


    local data = {}
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    for i = 1,#ids.ids,5 do
        local message = {}
        message.s_type = ids.ids[i] or 1
        message.s_opt = ids.ids[i+1] or 1
        message.s_id = ids.ids[i+2] or 0
        message.s_num = ids.ids[i+3] or 0
        message.s_time = ids.ids[i+4] or 0
        table.insert(data,message)
    end


    return { type = 4814, messages = data }

end

function NetAuctionHouseChangeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4815, "AuctionHouseChange")


    return { type = 4815 }

end