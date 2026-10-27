--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午7:10
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")

function UIActivityBlackShopQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3630, "ActivityBlackShop")
    print("UIActivityBlackShopQueryCallBack...")
    -- printT(uireq)
    local nowtime = os.date("*t", gamedata:time())
    local freshtype = true

    if next(gamedata.cache.activityBlackShop) then
        if gamedata.cache.activityBlackShop.freshtime.yday ~= nowtime.yday then
            freshtype = true
        else
            local refreshconfig = gamedata.config.blackmarket_refresh
            local refreshArr = {}

            print("refreshconfig==ui==")
            -- printT(refreshconfig)
            -- local refreshtimestring = "00:00"
            for k,v in pairs(refreshconfig) do
                if v.hour == 0 then
                    v.hour = 24
                end
                print("refreshtimestring==",v.hour)
                table.insert(refreshArr,tonumber(v.hour))
            end

            local sortfunction = function( a, b )
                return a < b
            end
            table.sort( refreshArr, sortfunction )
            print("refreshArr====")
            -- printT(refreshArr)

            local nowhour = nowtime.hour

            local lasthour = gamedata.cache.activityBlackShop.freshtime.hour

            local addtime = 0

            for i,v in ipairs(refreshArr) do
                print(i,v)
                if v > lasthour and v < nowhour then
                    freshtype = true
                    break
                else    
                    freshtype = false
                end
            end

        end
    end
    print("freshtype=",freshtype)

    if next(gamedata.cache.activityBlackShop) and not uireq.update and not freshtype then
        local globalconfig = gamedata.config.global_kv
        local propdata = gamedata.getIDandNUMs(globalconfig.blackmarket_refreshprop.value)
        -- printT(propdata)
        local onGenerals = makeOnGenerals()
        local generalTab = {}
        for k,v in pairs(onGenerals) do -- 挑出上阵伙伴cid
            if v.ison == 2 then
                table.insert(generalTab, v.cid)
            end
        end
        
        return 0, 3630, { type = 3630, data = gamedata.cache.activityBlackShop,
                        heishiSton = gamedata.getStaffNum(tonumber(propdata[1].cid)).num,
                        onGenerals = generalTab,}
    else
        return 1, 3630, nil
    end
end

function NetActivityBlackShopQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3630, "ActivityBlackShop")
    print("NetActivityBlackShopQueryCallBack==")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata:ActivityBlackShop(ids)

    local globalconfig = gamedata.config.global_kv
    local propdata = gamedata.getIDandNUMs(globalconfig.blackmarket_refreshprop.value)
    -- printT(propdata)
    local onGenerals = makeOnGenerals()
    local generalTab = {} 
    for k,v in pairs(onGenerals) do -- 挑出上阵伙伴cid
        if v.ison == 2 then
            table.insert(generalTab, v.cid)
        end
    end
    return { type = 3630, 
    data = gamedata.cache.activityBlackShop,
    heishiSton = gamedata.getStaffNum(tonumber(propdata[1].cid)).num,
    onGenerals = generalTab,}
end



function UIActivityBlackShopCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3631, "ActivityShop")
    local doData = ids_pb.Ids()

    local configdata = gamedata.config.blackmarket_items[tostring(uireq.goodid)]
    -- printT(configdata)
    local spenddata = gamedata.getIDandNUMs(configdata.consume) 
    print("spenddata===ui====")
    -- printT(spenddata)

    if tonumber(spenddata[1]["cid"]) == 1001 and gamedata.cache.role.gold < tonumber(spenddata[1]["num"])*uireq.num then
        return  0, 503, {type = 503, msgtype = "shortgold"}
    elseif tonumber(spenddata[1]["cid"]) == 1000 and gamedata.cache.role.coin < tonumber(spenddata[1]["num"])*uireq.num then
        --return  0, 503, {type = 503, msg = "银币不足"}
        return  0, 503, {type = 503, msgtype = "shortcoin"}
    else
        table.insert(doData.ids,uireq.id)
        table.insert(doData.ids,uireq.num)
        gamedata.ext.activityshopid = uireq.goodid
        gamedata.ext.activityblackshopnum = uireq.num

        return 1, 3631, doData:SerializeToString()
    end
end

function NetActivityBlackShopCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3616, "ActivityShop")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    local configdata = gamedata.config.blackmarket_items[tostring(gamedata.ext.activityshopid)]
    -- printT(configdata)
    local spenddata = gamedata.getIDandNUMs(configdata.consume) 
    print("spenddata===net====")
    -- printT(spenddata)

    if tonumber(spenddata[1]["cid"]) == 1001 then
        gamedata:updateRoleGold(0-tonumber(spenddata[1]["num"]*gamedata.ext.activityblackshopnum),"黑市商店"..gamedata.ext.activityshopid,1)
    else
        gamedata:updateRoleCoin(0-tonumber(spenddata[1]["num"]*gamedata.ext.activityblackshopnum),"黑市商店"..gamedata.ext.activityshopid,1)
    end

    return { type = 3631, reward = gamedata:SomethingProcess(getData)}
end

-- 黑市商店刷新
function UIActivityBlackShopResetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3632, "ActivityShop")
    -- printT(uireq)
    gamedata.ext.blackmarketresetGoldnum = uireq.spendnum
    local globalconfig = gamedata.config.global_kv
    local propdata = gamedata.getIDandNUMs(globalconfig.blackmarket_refreshprop.value) 

    local heishiSton = gamedata.getStaffNum(tonumber(propdata[1].cid)).num

    gamedata.ext.activityblackshopheishi = gamedata.getStaffNum(tonumber(propdata[1].cid)).num
    print("UIActivityBlackShopResetCallBack",globalconfig.blackmarket_refreshgold.value)

    if gamedata.cache.role.gold < tonumber(gamedata.ext.blackmarketresetGoldnum) and heishiSton <= 0 then
        return  0, 503, {type = 503, msgtype = "shortgold"}
    else
        return 1, 3632, nil
    end

end

function NetActivityBlackShopResetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3632, "ActivityShop")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata:ActivityBlackShop(ids)

    local globalconfig = gamedata.config.global_kv
    local propdata = gamedata.getIDandNUMs(globalconfig.blackmarket_refreshprop.value) 
    -- print("NetActivityBlackShopResetCallBack",globalconfig.blackmarket_refreshgold.value,gamedata.getStaffNum(tonumber(propdata[1].cid)).num)


    if gamedata.ext.activityblackshopheishi > 0 then
        print("heishihas")
        gamedata.cache.props[tonumber(propdata[1].cid)].num = gamedata.cache.props[tonumber(propdata[1].cid)].num - 1;
    else  
        print("heishinot")  
        gamedata:updateRoleGold(0-gamedata.ext.blackmarketresetGoldnum,"黑石商店刷新",1)
    end

    local onGenerals = makeOnGenerals()
    local generalTab = {} 
    for k,v in pairs(onGenerals) do -- 挑出上阵伙伴cid
        if v.ison == 2 then
            table.insert(generalTab, v.cid)
        end
    end 
    return { type = 3632, 
        data = gamedata.cache.activityBlackShop,
        heishiSton = gamedata.getStaffNum(tonumber(propdata[1].cid)).num,
        onGenerals = generalTab,
        gold = gamedata.cache.role.gold,
    }
end