--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-10-14
-- Time: 下午2:42
-- To change this template use File | Settings | File Templates.
--

local idnums_pb = require("idnums_pb")
local shopquery_pb = require("shopquery_pb")
local ids_pb = require("ids_pb")


function UIshopQueryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3200, "propsQuery")
    if next(gamedata.cache.shop.props) then
        return 0, 3200, { type = uireq.type, props = gamedata.cache.shop.props }
    else
        return 1, 3200, nil
    end
end

function NetshopQueryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3200, "propsQuery")
    local shopData = ids_pb.Ids()
    shopData:ParseFromString(fd.rbuf)

    gamedata:ShopProps(shopData.ids)

    return { type = 3200, props = gamedata.cache.shop.props }
end


function UIGiftBagQueryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3210, "GiftBagQuery")
    if next(gamedata.cache.shop.giftbags) then
        return 0, 3210, { type = uireq.type, giftbags = gamedata.cache.shop.giftbags }
    else
        return 1, 3210, nil
    end
end

function NetGiftBagQueryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3210, "GiftBagQuery")
    local shopData = shopquery_pb.ShopQuery()
    shopData:ParseFromString(fd.rbuf)

    gamedata:GiftBags(shopData.items)

    return { type = 3210, giftbags = gamedata.cache.shop.giftbags }
end



function UIShopBuyCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3201, "ShopBuy")
    local config = gamedata.config.shop[tostring(uireq.id)]

    local price = (config.discount and config.discount >0) and config.discount or config.gold

    gamedata.ext.shopbuy = {id = uireq.id, num = uireq.num, gold = uireq.gold, cid = config.id, updatetable = uireq.updatetable}

    if gamedata.cache.shop.props and gamedata.cache.shop.props[gamedata.ext.shopbuy.id] +gamedata.ext.shopbuy.num > uireq.maxBuyNum then
        return 0,503,{type = 503, msg = "今日购买个数已达上限！" }
    elseif uireq.gold> gamedata.cache.role.gold then
        return 0,503,{type = 503, msgtype = "shortgold" }
    end

    local IdNums = idnums_pb.IdNums()
    local idnum = idnums_pb.IdNums.IdNum()
    idnum.id =  uireq.id
    idnum.num =  uireq.num

    table.insert(IdNums.idnums,idnum)
    return 1, 3201, IdNums:SerializeToString()
end

local result_pb = require("result_pb")
local somethings_pb = require("somethings_pb")
function NetShopBuyCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3201, "ShopBuy")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    local reward = gamedata:SomethingProcess(SomeThings)
    local gold = gamedata.ext.shopbuy.gold

    gamedata:updateRoleGold(0-gold,"商城"..gamedata.ext.shopbuy.id,gamedata.ext.shopbuy.num)
    gamedata.cache.shop.props[gamedata.ext.shopbuy.id] = gamedata.cache.shop.props[gamedata.ext.shopbuy.id]+ gamedata.ext.shopbuy.num


return { type = 3201, reward = reward, props = gamedata.cache.shop.props,id=gamedata.ext.shopbuy.id,}
end


function UIGiftBagBuyCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3211, "GiftBagBuy")
    local IdNums = idnums_pb.IdNums()
    local idnum = idnums_pb.IdNums.IdNum()
    idnum.id =  uireq.id
    idnum.num =  uireq.num

    table.insert(IdNums.idnums,idnum)

    gamedata.ext.shopbuy = {id = uireq.id, num = uireq.num }

    local propconfig = gamedata.config.props[tostring(gamedata.ext.shopbuy.id)]
    if propconfig.type == "vipbox" and propconfig.param1+0 > gamedata.cache.role.vip+0 then
        return 0, 503,{type = 503,msg = "贵族等级不够"}
    end

    local shopconfig = gamedata.config.gift_bag[tostring(gamedata.ext.shopbuy.id)]
    if shopconfig.discount > gamedata.cache.role.gold then
        return 0,503,{type = 503, msgtype = "shortgold"}
    end


    return 1, 3211, IdNums:SerializeToString()
end

local result_pb = require("result_pb")
function NetGiftBagBuyCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3211, "GiftBagBuy")
    local Result = result_pb.Result()
    Result:ParseFromString(fd.rbuf)

    local shopconfig = gamedata.config.gift_bag[tostring(gamedata.ext.shopbuy.id)]

    local gold = shopconfig.discount
    if not gold or gold ==0 or gold == "" then
        gold = shopconfig.gold
    end

    local reward = {{cid = shopconfig.id,num =gamedata.ext.shopbuy.num}}

    if Result.result then
        gamedata:updateRoleGold(0-gold,"商城礼包",1)
        gamedata:updateprops({cid = shopconfig.id,num =gamedata.ext.shopbuy.num})
        gamedata.cache.shop.giftbags[gamedata.ext.shopbuy.id] = nil
    end

    return { type = 3211, Result = Result.result,reward = reward, giftbags = gamedata.cache.shop.giftbags}
end


--
function UIVipWeekGiftCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4890, "VipWeekGift")
    return 1, 4890, nil
end

function NetVipWeekGiftCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4890, "VipWeekGift")
    local shopData = ids_pb.Ids()
    shopData:ParseFromString(fd.rbuf)

    local weekgift = {}
    for k,v in ipairs(shopData.ids) do
        weekgift[tostring(k)] = v
    end

    return { type = 4890, weekgift = weekgift }
end

--
function UIVipWeekGiftRewardCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4891, "VipWeekGiftReward")

    gamedata.ext.weekgiftgold = uireq.xgold or 0

    if gamedata.ext.weekgiftgold > gamedata.cache.role.gold then
        return 0, 503,{type = 503,msgtype = "shortgold"}
    end

    local buyData = ids_pb.Ids()
    table.insert(buyData.ids, uireq.vip)


    return 1, 4891, buyData:SerializeToString()
end

function NetVipWeekGiftRewardCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4891, "VipWeekGiftReward")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    local reward = gamedata:SomethingProcess(SomeThings)
    local gold = gamedata.ext.weekgiftgold or 0

    gamedata:updateRoleGold(0-gold,"VIP周礼包",1)

    return { type = 4891, reward = reward }
end

function UIActivityBuyItemCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5345, "ActivityBuyItem")
    -- if uireq.data.useId == 1001  then
    --     if gamedata.cache.role.gold < uireq.data.useNum then
    --         return  0, 503, {type = 503, msgtype = "shortgold"}
    --     end
    -- elseif uireq.data.useId == 1000  then
    --     if gamedata.cache.role.coin < uireq.data.useNum then
    --         return  0, 503, {type = 503, msgtype = "shortcoin"}
    --     end
    -- elseif not gamedata.cache.props[uireq.data.useId] or gamedata.cache.props[uireq.data.useId].num < uireq.data.useNum then
    --     return 0,503,{type = 503,msgtype = "shortprop",id = uireq.data.useId,num = uireq.data.useNum}
    -- end
    local isenough, ret = gamedata.checkStaffEnough(uireq.data.useId,uireq.data.useNum,{})
    local cost = {cid=uireq.data.useId,num = -uireq.data.useNum,name = "购买活动道具"}
    if not isenough then
        return 0,503,ret
    end
    gamedata.ext.activityItemBuyCost = cost 
    local buyData = ids_pb.Ids()
    table.insert(buyData.ids, uireq.data.id)
    table.insert(buyData.ids,uireq.data.num)
    print("lipurposes buy itemId ",uireq.data.id)
    return 1, 5345, buyData:SerializeToString()
end

function NetActivityBuyItemCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5345, "ActivityBuyItem")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    local reward = gamedata:SomethingProcess(SomeThings)
    printT(reward,"lipurposes")
    gamedata:updateStaff(gamedata.ext.activityItemBuyCost)
    return { type = 5345,reward = reward}
end

function UIShopAutoRefinQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 8060, "ShopAutoRefin")
    return 1, 8060, nil
end

function NetShopAutoRefinQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8060, "ShopAutoRefin")
    local autoData = ids_pb.Ids()
    autoData:ParseFromString(fd.rbuf)

    local data = {}
    for k,v in ipairs(autoData.ids) do
        data[tostring(k)] = v
    end

    return { type = 8060,data = data}
end

function UIShopAutoRefinSetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 8061, "ShopAutoRefin")

    printT(uireq)
    local setData = ids_pb.Ids()
    for i=1, 5 do
        if uireq.data[tostring(i)] then
            table.insert(setData.ids, uireq.data[tostring(i)])
        end
    end

    return 1, 8061, setData:SerializeToString()
end

function NetShopAutoRefinSetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 8061, "ShopAutoRefin")

    local setData = ids_pb.Ids()
    setData:ParseFromString(fd.rbuf)

    local data = {}
    for k,v in ipairs(setData.ids) do
        data[tostring(k)] = v
    end
    
    return { type = 8061,data = data}
end