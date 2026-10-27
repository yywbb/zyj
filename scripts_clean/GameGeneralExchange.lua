--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/3
-- Time: 上午11:25
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
function UIGeneralExchangeCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1021, "GeneralExchange")
    local GeneralExchange = ids_pb.Ids()

    table.insert(GeneralExchange.ids, uireq.configid)

    gamedata.ext.generalexchangeid = uireq.configid

    return 1, 1021, GeneralExchange:SerializeToString()
end

local somethings_pb = require("somethings_pb")
function NetGeneralExchangeCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1021, "GeneralExchange")

    local GeneralsData = somethings_pb.SomeThings()
    GeneralsData:ParseFromString(fd.rbuf)

    local get, used = gamedata:SomethingProcess(GeneralsData)

    --printT(used)

    local config = gamedata.config.general_exchange[tostring(gamedata.ext.generalexchangeid)]
    if  config.gold > 0 then
        gamedata:updateRoleGold(0-config.gold,"武将兑换",1)
    elseif config.coin > 0 then
        gamedata:updateRoleCoin(0-config.coin)
    end

    return { type = 1021, gets = get }
end

function UIGeneralExchangeQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 10211, "GeneralExchangequery")

    local openids = {}
    for k,v in pairs(gamedata.config.general_exchange) do
        if v.level<= gamedata.cache.role.level and v.vip <= gamedata.cache.role.vip then
            if v.copy == 0 or gamedata.cache.copy[v.copy+1] then
                table.insert(openids,k)
            end
        end
    end
    return 0, 10211, {type = 10211, openids =openids, generals = makeOffGenerals(), coin = gamedata.cache.role.coin, gold = gamedata.cache.role.gold}
end