--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午7:10
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")

function UIRobShopCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3660, "RobShop")
    print("UIRobShopCallBack...")

    if uireq.update or not next(gamedata.cache.activityRobShop) then
        print("netin....")
        return 1, 3660, nil
    else
        print("netout....")
        return 0, 3660, { type = 3660, 
                        data = gamedata.cache.activityRobShop,
                        diaobaoCoin = gamedata.getStaffNum(20255).num,}
    end 
    
end

function NetRobShopCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3660, "ActivityBlackShop")
    print("NetRobShopCallBack==")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata:ActivityRobShop(ids)


    return { type = 3660, 
    data = gamedata.cache.activityRobShop,
    diaobaoCoin = gamedata.getStaffNum(20255).num,}
end



function UIRobShopBuyCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3661, "RobShop")
    printT(uireq)

    local doData = ids_pb.Ids()
    local configdata = gamedata.config.rob_shop[tostring(uireq.id)]
    -- printT(configdata)
    local spenddata = gamedata.getIDandNUMs(configdata.consume) 
    print("spenddata===ui====")
    -- printT(spenddata)

    print("cid===",gamedata.cache.props[tonumber(spenddata[1]["cid"])])
    -- print("hundan===num",gamedata.cache.props[tonumber(spenddata[1]["cid"])]["num"])

    if tonumber(spenddata[1]["cid"]) == 1001 and gamedata.cache.role.gold < tonumber(spenddata[1]["num"]) then
        print("元宝不足")
        return  0, 503, {type = 503, msgtype = "shortgold"}
    elseif tonumber(spenddata[1]["cid"]) == 20255 and (not gamedata.cache.props[tonumber(spenddata[1]["cid"])] or gamedata.cache.props[tonumber(spenddata[1]["cid"])]["num"] < tonumber(spenddata[1]["num"])) then
        print("当前夺宝币不足")
        return  0, 503, {type = 503, msg = "当前夺宝币不足，请前往夺宝获得"}
    else
        table.insert(doData.ids,uireq.goodid)
        gamedata.ext.Robshopbuy = uireq.id
        print("请求～～～")
        return 1, 3661, doData:SerializeToString()
    end
end

function NetRobShopBuyCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3661, "RobShop")
    print("NetRobShopBuyCallBack")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    local configdata = gamedata.config.rob_shop[tostring(gamedata.ext.Robshopbuy)]
    -- printT(configdata)
    local spenddata = gamedata.getIDandNUMs(configdata.consume) 
    print("spenddata===net====")
    -- printT(spenddata)

    if tonumber(spenddata[1]["cid"]) == 1001 then
        gamedata:updateRoleGold(0-tonumber(spenddata[1]["num"]),"夺宝商店"..spenddata[1]["cid"],1)
    else
        print("duobaobi===net",spenddata[1]["cid"])
        print("num===",gamedata.cache.props[tonumber(spenddata[1]["cid"])].num)
        -- printT(gamedata.cache.props[tonumber(spenddata[1]["cid"])])
        gamedata.cache.props[tonumber(spenddata[1]["cid"])].num = gamedata.cache.props[tonumber(spenddata[1]["cid"])].num-spenddata[1]["num"]
        print("num===",gamedata.cache.props[tonumber(spenddata[1]["cid"])].num)
        
    end

    return { type = 3661, reward = gamedata:SomethingProcess(getData)}
end
