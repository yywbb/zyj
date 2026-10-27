local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")

local function makeactivityExchange()
    local activityExchange = table.copy(gamedata.cache.activityExchange.items)
    for k,v in ipairs(activityExchange) do
        local config = gamedata.config.exchange_sys[tostring(v.id)]
        v.pay = gamedata.getIDandNUMs(config.generals)
        v.status = true
        for kk,vv in ipairs(v.pay) do
            vv.nownum = gamedata.getStaffNum(vv.cid).num
            if vv.nownum < vv.num then
                v.status = false
            end
        end
    end
    return activityExchange
end


function UIActivityExchangeCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI",2055,"ActivityExchange")
    return 1,2055,nil
end

function NetActivityExchangeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2055, "ActivityExchange")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata:ActivityExchange(ids)

    printT(gamedata.cache.activityExchange)
    return {
        type = 2055,
        resetTime = gamedata.cache.activityExchange.resetTime,
        data = makeactivityExchange(),
        refreshSton = gamedata.getStaffNum(20160).num,
    }
end

------------------------------------------------------------

function UIActivityExchangeEXCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI",2056,"ActivityExchangeEX")
    local doData = ids_pb.Ids()
    table.insert(doData.ids,uireq.id or 1)
    gamedata.ext.activityexchangeid = uireq.id or 1

    return 1,2056,doData:SerializeToString()
end


function NetActivityExchangeEXCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2056, "ActivityExchangeEX")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    local config = gamedata.config.exchange_sys[tostring(gamedata.cache.activityExchange.items[gamedata.ext.activityexchangeid].id)]
    local pay = gamedata.getIDandNUMs(config.generals)

    for k,v in ipairs(pay) do
        gamedata:updateStaff({cid = v.cid,num = -v.num})
    end

    gamedata.cache.activityExchange.items[gamedata.ext.activityexchangeid].num = gamedata.cache.activityExchange.items[gamedata.ext.activityexchangeid].num +1

    return {type = 2056,reward = gamedata:SomethingProcess(getData), data = makeactivityExchange(),refreshSton = gamedata.getStaffNum(20160).num}
end

------------------------------------------------------------

function UIActivityExchangeRefreshCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI",2057,"ActivityExchangeRefresh")
    return 1,2057,nil
end

function NetActivityExchangeRefreshCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2057, "ActivityExchangeRefresh")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata:ActivityExchange(ids)
    local refreshSton = 0
    --判断用什么刷新（刷新石，元宝）
    if gamedata.cache.props[20160] and gamedata.cache.props[20160].num > 0 then
        gamedata.cache.props[20160].num = gamedata.cache.props[20160].num - 1;
        refreshSton = gamedata.cache.props[20160].num;
    else
        --元宝刷新
        gamedata:updateRoleGold(0-20,"元宝刷新兑换",1)
    end

    return {
        type = 2057,
        resetTime = gamedata.cache.activityExchange.resetTime,
        data = makeactivityExchange(),
        refreshSton = gamedata.getStaffNum(20160).num,
    }

end



