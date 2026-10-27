--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/4/21
-- Time: 10:42
-- To change this template use File | Settings | File Templates.
--

local somethings_pb = require("somethings_pb")
local ids_pb = require("ids_pb")

function UICornucopiaQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2031, "CornucopiaQuery")

    return 1, 2031, nil

end

function NetCornucopiaQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2031, "CornucopiaQuery")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata:Cornucopia(ids.ids)

    return { type = 2031, cornucopia = gamedata.cache.cornucopia }
end


function UICornucopiaCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2032, "Cornucopia")

    gamedata.ext.cornucopiaGold = uireq.xgold or 0
    if gamedata.ext.cornucopiaGold > gamedata.cache.role.gold then
        return 0,503,{type = 503, msgtype = "shortgold" }
    end

    local Data = ids_pb.Ids()
    table.insert(Data.ids, uireq.num or 1)
    table.insert(Data.ids, uireq.payType or 1)

    return 1, 2032, Data:SerializeToString()

end

function NetCornucopiaCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2032, "Cornucopia")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    local reward, used, ext = gamedata:SomethingProcess(SomeThings,"cornucopia")

    if gamedata.ext.cornucopiaGold and gamedata.ext.cornucopiaGold > 0 then
        gamedata:updateRoleGold(0-gamedata.ext.cornucopiaGold,"聚宝盆",1)
    end

    return { type = 2032, reward = reward, cornucopia = gamedata.cache.cornucopia, ext = ext or 1}
end

function UICornucopiaRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2033, "CornucopiaReward")

    local Data = ids_pb.Ids()
    table.insert(Data.ids, uireq.index or 1)

    return 1, 2033, Data:SerializeToString()

end

function NetCornucopiaRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2033, "CornucopiaReward")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    local reward = gamedata:SomethingProcess(SomeThings,"cornucopia")

    return { type = 2033, reward = reward, cornucopia = gamedata.cache.cornucopia }
end