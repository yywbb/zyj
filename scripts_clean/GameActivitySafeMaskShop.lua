--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午7:10
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")

-- 魔罩商店查询
function UISafeMaskShopQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3733, "ActivitySecretShop")
    print("UISafeMaskShopQueryCallBack...")
    -- printT(uireq)
    -- local tempdata = {}
    -- for k,v in pairs(gamedata.config.mozhao_shop) do
    --     table.insert(tempdata,0)
    -- end

    -- gamedata:ActivitySafeMaskShop(tempdata)

    -- return 0, 3733, { type = 3733, data = gamedata.cache.safemaskshop,gold = gamedata.cache.role.gold}
    return 1, 3733, nil
end

function NetSafeMaskShopQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3733, "ActivitySecretShop")
    print("NetSafeMaskShopQueryCallBack==")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata:ActivitySafeMaskShop(ids.ids)

   
    return { type = 3733, data = gamedata.cache.safemaskshop,gold = gamedata.cache.role.gold,}
end


-- 魔罩奖励兑换
function UISafeMaskShopRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3734, "SafeMaskShopReward")
    local doData = ids_pb.Ids()
    -- printT(uireq)
    table.insert(doData.ids,uireq.id)
    table.insert(doData.ids,uireq.num)
    gamedata.ext.SafeMaskShopRewardbuy = uireq.gold*uireq.num

    return 1, 3734, doData:SerializeToString()
end

function NetSafeMaskShopRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3734, "SafeMaskShopReward")
    print("NetSafeMaskShopRewardCallBack")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    -- printT(spenddata)
    gamedata:updateRoleGold(0-gamedata.ext.SafeMaskShopRewardbuy,"魔罩商店"..gamedata.ext.SafeMaskShopRewardbuy,1)
  

    return { type = 3734, reward = gamedata:SomethingProcess(getData)}
end
