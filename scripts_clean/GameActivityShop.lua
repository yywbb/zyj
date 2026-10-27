--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午7:10
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")

function UIActivityShopQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3615, "ActivityShop")
    local now = gamedata:time()
    if next(gamedata.cache.activityShop) and gamedata.cache.activityShop.reciveTime+ gamedata.cache.activityShop.time>=now and not uireq.update then
        gamedata.cache.activityShop.time = gamedata.cache.activityShop.time - (now-gamedata.cache.activityShop.reciveTime)
        gamedata.cache.activityShop.reciveTime = now
        return 0, 3615, { type = 3615, data = gamedata.cache.activityShop, }
    else
        return 1, 3615, nil
    end
end

function NetActivityShopQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3615, "ActivityShop")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata:ActivityShop(ids)

    return { type = 3615, data = gamedata.cache.activityShop, }
end



function UIActivityShopCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3616, "ActivityShop")
    local doData = ids_pb.Ids()


    -- local config = gamedata.config.limittime_shop
    local config = gamedata.dailyCpActivityConfig("limittime_shop",3)

    local configdata = config[tostring(uireq.id)]
    print("UIconfigdata=======",configdata["currency"])
    printT(configdata)

    if tonumber(configdata["currency"]) == 1001 and gamedata.cache.role.gold < configdata["discount"] then
        return  0, 503, {type = 503, msgtype = "shortgold"}
    elseif tonumber(configdata["currency"]) == 1000 and gamedata.cache.role.coin < configdata["discount"] then
        --return  0, 503, {type = 503, msg = "银币不足"}
        return  0, 503, {type = 503, msgtype = "shortcoin"}
    else
        table.insert(doData.ids,uireq.id)
        gamedata.ext.activityshopid = uireq.id

        return 1, 3616, doData:SerializeToString()
    end
end

function NetActivityShopCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3616, "ActivityShop")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)


    -- local config = gamedata.config.limittime_shop
    local config = gamedata.dailyCpActivityConfig("limittime_shop",3)
    
    local configdata = config[tostring(gamedata.ext.activityshopid)]
    print("Netconfigdata=======",configdata.discount)
    printT(configdata)

    if tonumber(configdata["currency"]) == 1001 then
        gamedata:updateRoleGold(0-configdata.discount,"限时商店"..gamedata.ext.activityshopid,1)
    else
        gamedata:updateRoleCoin(0-configdata.discount,"限时商店"..gamedata.ext.activityshopid,1)
    end

    return { type = 3616, reward = gamedata:SomethingProcess(getData)}
end

function UIActivityShopResetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3617, "ActivityShop")

    if gamedata.cache.activityShop.reset>=3 and gamedata.cache.role.gold < 5 then
        return  0, 503, {type = 503, msgtype = "shortgold"}
    else
        return 1, 3617, nil
    end

end

function NetActivityShopResetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3617, "ActivityShop")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata:ActivityShop(ids)

    if gamedata.cache.activityShop.reset >=4 then
        gamedata:updateRoleGold(-5,"限时商店刷新",1)
    end

    return { type = 3617, data = gamedata.cache.activityShop, }
end


--cp
local ActivityShop_cpnum = 0
local ActivityShop_cpday = 0
function UICPActivityShopQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5043, "ActivityShop")

    return 1, 5043, nil
end

function NetCPActivityShopQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5043, "ActivityShop")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    ActivityShop_cpnum = ids.ids[1] or 0
    ActivityShop_cpday = ids.ids[2] or 0

    local now = gamedata:time()

    gamedata.cache.cp_activityShop = {}

    gamedata.cache.cp_activityShop.reciveTime = now
    gamedata.cache.cp_activityShop.lucky = ids.ids[3] or 0
    gamedata.cache.cp_activityShop.reset = ids.ids[4] or 0
    gamedata.cache.cp_activityShop.time = ids.ids[5] or 0
    gamedata.cache.cp_activityShop.status = {}

    for i=6, 16 ,2  do
        table.insert(gamedata.cache.cp_activityShop.status,{id = ids.ids[i], status = ids.ids[i+1]})
    end

    return { type = 5043, data = gamedata.cache.cp_activityShop, cpnum = ActivityShop_cpnum, cpday = ActivityShop_cpday}
end



function UICPActivityShopCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5044, "ActivityShop")
    local doData = ids_pb.Ids()

    local configdata = gamedata.config["limittime_shop_"..ActivityShop_cpnum][tostring(uireq.id)]

    if tonumber(configdata["currency"]) == 1001 and gamedata.cache.role.gold < configdata["discount"] then
        return  0, 503, {type = 503, msgtype = "shortgold"}
    elseif tonumber(configdata["currency"]) == 1000 and gamedata.cache.role.coin < configdata["discount"] then
        --return  0, 503, {type = 503, msg = "银币不足"}
        return  0, 503, {type = 503, msgtype = "shortcoin"}
    else
        table.insert(doData.ids,uireq.id)
        gamedata.ext.cp_activityshopid = uireq.id

        return 1, 5044, doData:SerializeToString()
    end
end

function NetCPActivityShopCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5044, "ActivityShop")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    local configdata = gamedata.config["limittime_shop_"..ActivityShop_cpnum][tostring(gamedata.ext.cp_activityshopid)]

    if tonumber(configdata["currency"]) == 1001 then
        gamedata:updateRoleGold(0-configdata.discount,"限时商店"..gamedata.ext.cp_activityshopid,1)
    else
        gamedata:updateRoleCoin(0-configdata.discount,"限时商店"..gamedata.ext.cp_activityshopid,1)
    end

    return { type = 5044, reward = gamedata:SomethingProcess(getData)}
end

function UICPActivityShopResetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5045, "ActivityShop")

    if gamedata.cache.cp_activityShop.reset>=3 and gamedata.cache.role.gold < 5 then
        return  0, 503, {type = 503, msgtype = "shortgold"}
    else
        return 1, 5045, nil
    end

end

function NetCPActivityShopResetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5045, "ActivityShop")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local cpnum = ids.ids[1] or 0
    local cpday = ids.ids[2] or 0

    local now = gamedata:time()

    gamedata.cache.cp_activityShop = {}
    gamedata.cache.cp_activityShop.reciveTime = now
    gamedata.cache.cp_activityShop.lucky = ids.ids[3] or 0
    gamedata.cache.cp_activityShop.reset = ids.ids[4] or 0
    gamedata.cache.cp_activityShop.time = ids.ids[5] or 0
    gamedata.cache.cp_activityShop.status = {}

    for i=6, 16 ,2  do
        table.insert(gamedata.cache.cp_activityShop.status,{id = ids.ids[i], status = ids.ids[i+1]})
    end

    if gamedata.cache.cp_activityShop.reset >=4 then
        gamedata:updateRoleGold(-5,"限时商店刷新",1)
    end

    return { type = 5045, data = gamedata.cache.cp_activityShop, cpnum = cpnum, cpday = cpday}
end