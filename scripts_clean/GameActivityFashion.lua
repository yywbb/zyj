--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/6/17
-- Time: 15:41
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")

function UIFashionDressActQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1075, "FashionDressActQuery")

    return 1, 1075, nil
end

function NetFashionDressActQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1075, "FashionDressActQuery")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local status = ids.ids[1] or 0

    return { type = 1075, status = status}

end

--
function UIFashionDressGetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1074, "FashionDressGet")

    local doData = ids_pb.Ids()
    table.insert(doData.ids,uireq.id or 0)

    gamedata.ext.fashionbuygold = uireq.xgold or 0

    if gamedata.ext.fashionbuygold > gamedata.cache.role.gold then
        return 0,503,{type = 503, msgtype = "shortgold" }
    end

    return 1, 1074, doData:SerializeToString()

end

function NetFashionDressGetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1074, "FashionDressGet")

    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    if gamedata.ext.fashionbuygold and gamedata.ext.fashionbuygold > 0 then
        gamedata:updateRoleGold(0-gamedata.ext.fashionbuygold,"购买时装",1)
    end

    return { type = 1074, reward = gamedata:SomethingProcess(getData),}

end

--
function UIFashionDressShopQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1076, "FashionDressShopQuery")

    return 1, 1076, nil
end

function NetFashionDressShopQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1076, "FashionDressShopQuery")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local status = {}
    local priceid = ids.ids[1] or 0
    for i = 2,#ids.ids,2 do
        table.insert(status,{id = ids.ids[i] or 0 ,status = ids.ids[i+1] or 0})
    end

    return { type = 1076, priceid = priceid, status = status}

end