--
-- Author: songyibo
-- Date: 2019-08-20 13:54:23
--

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
local combmessages_pb = require("combmessages_pb")


function UIXuanyueQueryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 7060, "XuanyueQuery")


    if uireq.param == "main" then
    	gamedata.ext.XuanyueQuery = "main"
    else
    	gamedata.ext.XuanyueQuery = nil
    end
   
    if next(gamedata.cache.xuanyueTreasures) then
        return 0, 7060, {type = 7060, data = gamedata.cache.xuanyueTreasures,param = gamedata.ext.XuanyueQuery}
    else
        return 1, 7060, nil
    end
end

function NetXuanyueQueryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7060, "XuanyueQuery")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local ids = ids_pb.Ids()
    ids:ParseFromString(datas.messages[1].data)
    gamedata.cache.xuanyueTreasures.day = gamedata:xuanyueTreasuresDay(ids.ids)

    if gamedata.cache.xuanyueTreasures.day.isopen == 1 then
    	local ids = ids_pb.Ids()
        ids:ParseFromString(datas.messages[2].data)
        gamedata.cache.xuanyueTreasures.data = gamedata:xuanyueTreasuresData(ids.ids)
    end

    return { type = 7060,data = gamedata.cache.xuanyueTreasures,param = gamedata.ext.XuanyueQuery}
end

function UIXuanyueAwardCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 7061, "XuanyueAward")
    local ReqData = ids_pb.Ids()
    table.insert(ReqData.ids, uireq.id)

    gamedata.ext.XuanyueAwardId = uireq.id

    return 1, 7061, ReqData:SerializeToString()
end

function NetXuanyueAwardCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7061, "XuanyueAward")

    local reward = {}

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    reward = gamedata:SomethingProcess(SomeThings)


    local id = gamedata.ext.XuanyueAwardId
    gamedata.ext.XuanyueAwardId = nil

    local status = 0
    if id then
        local data = gamedata.cache.xuanyueTreasures.data
        if data.isHight == 1 then
            data.status[id] = 2
        else
            data.status[id] = 3
        end
        status = data.status[id]
    else
        gamedata.cache.xuanyueTreasures = {}
    end

    return { type = 7061,reward = reward,awardId = id,data = status,xuanyueData = gamedata.cache.xuanyueTreasures}
end

function NetXuanyueActivateCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7062, "Xuanyuectivate")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local id = ids.ids[1]

    gamedata.cache.xuanyueTreasures = {}

    return { type = 7062,id = id}
end

----------------------玄月秘宝复制----------------------------
function UIXuanyueQuery2Callback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 7063, "XuanyueQuery")


    if uireq.param == "main" then
        gamedata.ext.XuanyueQuery2 = "main"
    else
        gamedata.ext.XuanyueQuery2 = nil
    end
   
    if next(gamedata.cache.xuanyueTreasures2) then
        return 0, 7063, {type = 7063, data = gamedata.cache.xuanyueTreasures2,param = gamedata.ext.XuanyueQuery2}
    else
        return 1, 7063, nil
    end
end

function NetXuanyueQuery2Callback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7063, "XuanyueQuery")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local ids = ids_pb.Ids()
    ids:ParseFromString(datas.messages[1].data)
    gamedata.cache.xuanyueTreasures2.day = gamedata:xuanyueTreasuresDay(ids.ids)

    if gamedata.cache.xuanyueTreasures2.day.isopen == 1 then
        local ids = ids_pb.Ids()
        ids:ParseFromString(datas.messages[2].data)
        gamedata.cache.xuanyueTreasures2.data = gamedata:xuanyueTreasuresData2(ids.ids)
    end

    return { type = 7063,data = gamedata.cache.xuanyueTreasures2,param = gamedata.ext.XuanyueQuery2}
end

function UIXuanyueAward2Callback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 7064, "XuanyueAward")
    local ReqData = ids_pb.Ids()
    table.insert(ReqData.ids, uireq.id)

    gamedata.ext.XuanyueAwardId2 = uireq.id

    return 1, 7064, ReqData:SerializeToString()
end

function NetXuanyueAward2Callback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7064, "XuanyueAward")

    local reward = {}

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    reward = gamedata:SomethingProcess(SomeThings)


    local id = gamedata.ext.XuanyueAwardId2
    gamedata.ext.XuanyueAwardId2 = nil

    local status = 0
    if id then
        local data = gamedata.cache.xuanyueTreasures2.data
        if data.isHight == 1 then
            data.status[id] = 2
        else
            data.status[id] = 3
        end
        status = data.status[id]
    else
        gamedata.cache.xuanyueTreasures2 = {}
    end

    return { type = 7064,reward = reward,awardId = id,data = status,xuanyueData = gamedata.cache.xuanyueTreasures2}
end

function NetXuanyueActivate2Callback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7067, "Xuanyuectivate")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local id = ids.ids[1]

    gamedata.cache.xuanyueTreasures2 = {}

    return { type = 7067,id = id}
end

----------------------玄月秘宝3----------------------------
function UIXuanyueQuery3Callback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 7072, "XuanyueQuery3")


    if uireq.param == "main" then
        gamedata.ext.XuanyueQuery3 = "main"
    else
        gamedata.ext.XuanyueQuery3 = nil
    end
   
    if next(gamedata.cache.xuanyueTreasures3) then
        return 0, 7072, {type = 7072, data = gamedata.cache.xuanyueTreasures3,param = gamedata.ext.XuanyueQuery3}
    else
        return 1, 7072, nil
    end
end

function NetXuanyueQuery3Callback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7072, "XuanyueQuery3")

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)

    local ids = ids_pb.Ids()
    ids:ParseFromString(datas.messages[1].data)
    gamedata.cache.xuanyueTreasures3.day = gamedata:xuanyueTreasuresDay(ids.ids)

    if gamedata.cache.xuanyueTreasures3.day.isopen == 1 then
        local ids = ids_pb.Ids()
        ids:ParseFromString(datas.messages[2].data)
        gamedata.cache.xuanyueTreasures3.data = gamedata:xuanyueTreasuresData3(ids.ids)
    end

    return { type = 7072,data = gamedata.cache.xuanyueTreasures3,param = gamedata.ext.XuanyueQuery3}
end

function UIXuanyueAward3Callback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 7073, "XuanyueAward3")
    local ReqData = ids_pb.Ids()
    table.insert(ReqData.ids, uireq.id)

    gamedata.ext.XuanyueAwardId3 = uireq.id

    return 1, 7073, ReqData:SerializeToString()
end

function NetXuanyueAward3Callback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7073, "XuanyueAward3")

    local reward = {}

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    reward = gamedata:SomethingProcess(SomeThings)


    local id = gamedata.ext.XuanyueAwardId3
    gamedata.ext.XuanyueAwardId3 = nil

    local status = 0
    if id then
        local data = gamedata.cache.xuanyueTreasures3.data
        if data.isHight == 1 then
            data.status[id] = 2
        else
            data.status[id] = 3
        end
        status = data.status[id]
    else
        gamedata.cache.xuanyueTreasures3 = {}
    end

    return { type = 7073,reward = reward,awardId = id,data = status,xuanyueData = gamedata.cache.xuanyueTreasures3}
end

function NetXuanyueActivate3Callback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7074, "Xuanyuectivate3")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local id = ids.ids[1]

    gamedata.cache.xuanyueTreasures3 = {}

    return { type = 7074,id = id}
end    