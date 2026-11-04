-- 仅原配置开放的羽毛配方；读回包绑定页面，收费不能覆盖在途目标。
local exchange_comb = require("combmessages_pb")
local function exchangeStocks()
    for page, rows in pairs(gamedata.config.exchange_shop) do
        local cache = gamedata.cache.activityTreasureX3[tonumber(page)] or {}
        for id, row in pairs(rows) do
            local item = cache[tonumber(id)]
            if item and row.open == 1 then
                for _, cost in ipairs(gamedata.getIDandNUMs(row.generals)) do
                    item[cost.cid] = gamedata.getStaffNum(cost.cid, false).num
                end
            end
        end
    end
end

function UITitbitDiscountX3QuryCallBack(req)
    if gamedata.ext.localExchangeBusy then
        return 0,503,{type=503,msg="兑换正在结算，请等待回复；超时请重进游戏"}
    end
    local queue = gamedata.ext.localExchangeQueries or {}
    table.insert(queue, {view=req.exchangeView})
    gamedata.ext.localExchangeQueries = queue
    return 1,4016,nil
end

function NetTitbitDiscountX3QuryCallBack(fd)
    local req = table.remove(gamedata.ext.localExchangeQueries or {}, 1)
    if not req then return {type=4016,localExchangeIgnored=true} end
    local comb, data = exchange_comb.CombMessages(), {}
    comb:ParseFromString(fd.rbuf)
    for _, message in ipairs(comb.messages) do
        local values = ids_pb.Ids()
        values:ParseFromString(message.data)
        data[message.id] = values.ids
    end
    gamedata:ActivityTreasureX3(data)
    exchangeStocks()
    return {type=4016,activityTreasure=gamedata.cache.activityTreasureX3,exchangeView=req.view}
end

function UITitbitDiscountX3BuyCallBack(req)
    if gamedata.ext.localExchangeBusy or #(gamedata.ext.localExchangeQueries or {}) > 0 then
        return 0,503,{type=503,msg="兑换正在结算，请等待回复；超时请重进游戏"}
    end
    local page, id, num = tonumber(req.pageid), tonumber(req.id), tonumber(req.num or 1)
    local row = (gamedata.config.exchange_shop[tostring(page)] or {})[tostring(id)]
    local item = ((gamedata.cache.activityTreasureX3 or {})[page] or {})[id]
    if page ~= 1 or not row or row.open ~= 1 or not item or not num or num < 1 or num % 1 ~= 0 or num > row.count-item.num then
        return 0,503,{type=503,msg="兑换状态已变化，请重新打开商店"}
    end
    local values = ids_pb.Ids()
    for _, value in ipairs({page,id,num}) do table.insert(values.ids,value) end
    gamedata.ext.localExchangeBusy = {page=page,id=id,num=num,view=req.exchangeView}
    return 1,4017,values:SerializeToString()
end

function NetTitbitDiscountX3BuyCallBack(fd)
    local req = gamedata.ext.localExchangeBusy
    if not req then return {type=4017,localExchangeIgnored=true} end
    local reward = somethings_pb.SomeThings()
    reward:ParseFromString(fd.rbuf)
    local row = gamedata.config.exchange_shop[tostring(req.page)][tostring(req.id)]
    for _, cost in ipairs(gamedata.getIDandNUMs(row.generals)) do
        gamedata:updateStaff({cid=cost.cid,num=-cost.num*req.num})
    end
    local gets = gamedata:SomethingProcess(reward)
    local item = gamedata.cache.activityTreasureX3[req.page][req.id]
    item.num = item.num+req.num
    exchangeStocks()
    gamedata.ext.localExchangeBusy = nil
    return {type=4017,reward=gets,activityTreasure=gamedata.cache.activityTreasureX3,
        exchange=true,pageid=req.page,index=req.id,exchangeView=req.view}
end
