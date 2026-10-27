--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午7:10
-- To change this template use File | Settings | File Templates.
--20778

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")

-- 商店查询
function UIJinghuaShopQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6451, "jinghuaShop")

    return 1, 6451, nil
end

function NetJinghuaShopQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6451, "jinghuaShop")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
   
    local data = {} 
    local onerankdata = {}
    local tworankdata = {}
    local threerankdata = {}
    local fourrankdata = {}
    local notlimit = 0

    for i,v in ipairs(ids.ids) do
        if i > table.getTableLength(gamedata.config.essence_shop) then
            notlimit = v
            break
        end

        local tempconfig = gamedata.config.essence_shop
        local temp = {}
        temp.num = v
        temp.id = i

        if tempconfig[tostring(i)].page == 1 then
            temp.sort = tempconfig[tostring(i)].sort or 1
            table.insert(onerankdata,temp)
        elseif tempconfig[tostring(i)].page == 2 then
            temp.sort = tempconfig[tostring(i)].sort or 1
            table.insert(tworankdata,temp)
        elseif tempconfig[tostring(i)].page == 3 then
            temp.sort = tempconfig[tostring(i)].sort or 1
            table.insert(threerankdata,temp)
        elseif tempconfig[tostring(i)].page == 4 then
            temp.sort = tempconfig[tostring(i)].sort or 1
            table.insert(fourrankdata,temp)
        end
    end

    local sortfunc = function(a,b)
        if a["sort"] < b["sort"] then
            return true
        else
            return false
        end
    end
    table.sort(onerankdata,sortfunc)
    table.sort(tworankdata,sortfunc)
    table.sort(threerankdata,sortfunc)
    table.sort(fourrankdata,sortfunc)

    data.onerankdata = onerankdata
    data.tworankdata = tworankdata
    data.threerankdata = threerankdata
    data.fourrankdata = fourrankdata
   
    return { type = 6451, data = data, notlimit = notlimit or 0,propnum = gamedata.cache.props[20778] and gamedata.cache.props[20778].num or 0, propnum2 = gamedata.cache.props[20790] and gamedata.cache.props[20790].num or 0,}
end


-- 奖励兑换
function UIJinghuaShopRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6452, "ShopReward")
    local doData = ids_pb.Ids()

    table.insert(doData.ids,uireq.id)
    table.insert(doData.ids,uireq.num or 1)
    gamedata.ext.JinghuaShopRewardbuy = uireq.usenum or 0
    gamedata.ext.JinghuaShopRewardbuycid = uireq.usecid or 0

    return 1, 6452, doData:SerializeToString()
end

function NetJinghuaShopRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6452, "ShopReward")
    print("NetSafeMaskShopRewardCallBack")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    if gamedata.ext.JinghuaShopRewardbuycid and gamedata.ext.JinghuaShopRewardbuycid > 0 and gamedata.ext.JinghuaShopRewardbuy and gamedata.ext.JinghuaShopRewardbuy > 0 then
        gamedata:updateprops({cid = gamedata.ext.JinghuaShopRewardbuycid,num = 0-gamedata.ext.JinghuaShopRewardbuy})
    end    

    return { type = 6452, reward = gamedata:SomethingProcess(getData)}
end
