--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午7:10
-- To change this template use File | Settings | File Templates.
--

-- 与海外版有差异，海外版刷新时间走配置表

local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")

function UIActivitySecretShopQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3650, "ActivitySecretShop")
    print("UIActivitySecretShopQueryCallBack...")
    -- printT(uireq)
    local nowtime = os.date("*t", gamedata:time())
    local nowtimesec = nowtime.hour*3600 + nowtime.min* 60 + nowtime.sec
    local freshtype = true

    if next(gamedata.cache.activitySecretShop) then
        if gamedata.cache.activitySecretShop.freshtime.yday ~= nowtime.yday then
            freshtype = true
        else
            local refreshArr = {2,4,6,8,10,12,14,16,18,20,22,24}

            print("refreshArr====")
            -- printT(refreshArr)

            local nowhour = nowtime.hour

            local lasthour = gamedata.cache.activitySecretShop.freshtime.hour

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

    if next(gamedata.cache.activitySecretShop) and not uireq.update and not freshtype then
        print("netout..")
        local globalconfig = gamedata.config.global_kv
        local propdata = gamedata.getIDandNUMs(globalconfig.mysteryshop_refreshprop.value)
        -- printT(propdata)
        local onGenerals = makeOnGenerals()
        local generalTab = {} 
        for k,v in pairs(onGenerals) do -- 挑出上阵伙伴cid
            if v.ison == 2 then
                table.insert(generalTab, v.cid)
            end
        end 

        return 0, 3650, { type = 3650, 
                        data = gamedata.cache.activitySecretShop,
                        lingpaiNum = gamedata.getStaffNum(tonumber(propdata[1].cid)).num,
                        hundanNum = gamedata.getStaffNum(20200).num,
                        onGenerals = generalTab,}
    else
        print("netin..")
        return 1, 3650, nil
    end
end

function NetActivitySecretShopQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3650, "ActivitySecretShop")
    print("NetActivitySecretShopQueryCallBack==")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)
    gamedata:ActivitySecretShop(ids)

    local globalconfig = gamedata.config.global_kv
    local propdata = gamedata.getIDandNUMs(globalconfig.mysteryshop_refreshprop.value)
    -- printT(propdata)
    local onGenerals = makeOnGenerals()
    local generalTab = {} 
    for k,v in pairs(onGenerals) do -- 挑出上阵伙伴cid
        if v.ison == 2 then
            table.insert(generalTab, v.cid)
        end
    end
    return { type = 3650, 
        data = gamedata.cache.activitySecretShop,
        lingpaiNum = gamedata.getStaffNum(tonumber(propdata[1].cid)).num,
        hundanNum = gamedata.getStaffNum(20200).num,
        onGenerals = generalTab,}
end



function UIActivitySecretShopCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3651, "ActivitySecretShop")
    local doData = ids_pb.Ids()
    -- printT(uireq)
    local configdata = gamedata.config.mystery_shop[tostring(uireq.goodid)]
    -- printT(configdata)
    local spenddata = gamedata.getIDandNUMs(configdata.consume) 
    print("spenddata===ui====")
    -- printT(spenddata)

    print("cid===",gamedata.cache.props[tonumber(spenddata[1]["cid"])])
    -- print("hundan===num",gamedata.cache.props[tonumber(spenddata[1]["cid"])]["num"])

    if tonumber(spenddata[1]["cid"]) == 1001 and gamedata.cache.role.gold < tonumber(spenddata[1]["num"])*uireq.num then
        return  0, 503, {type = 503, msgtype = "shortgold"}
    elseif tonumber(spenddata[1]["cid"]) == 1000 and gamedata.cache.role.coin < tonumber(spenddata[1]["num"])*uireq.num then
        --return  0, 503, {type = 503, msg = "银币不足"}
        return  0, 503, {type = 503, msgtype = "shortcoin"}
    elseif tonumber(spenddata[1]["cid"]) == 20200 and (not gamedata.cache.props[tonumber(spenddata[1]["cid"])] or gamedata.cache.props[tonumber(spenddata[1]["cid"])]["num"] < tonumber(spenddata[1]["num"])*uireq.num) then
        return  0, 503, {type = 503, msg = "当前魂蛋不足，请前往炼化获得"}
    else
        table.insert(doData.ids,uireq.id)
        table.insert(doData.ids,uireq.num)
        gamedata.ext.activitysecretshopbuy = uireq.goodid
        gamedata.ext.activitysecretshopbuynum = uireq.num

        return 1, 3651, doData:SerializeToString()
    end
end

function NetActivitySecretShopCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3651, "ActivitySecretShop")
    print("NetActivitySecretShopCallBack")
    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    local configdata = gamedata.config.mystery_shop[tostring(gamedata.ext.activitysecretshopbuy)]
    -- printT(configdata)
    local spenddata = gamedata.getIDandNUMs(configdata.consume) 
    print("spenddata===net====")
    -- printT(spenddata)

    if tonumber(spenddata[1]["cid"]) == 1001 then
        gamedata:updateRoleGold(0-tonumber(spenddata[1]["num"])*gamedata.ext.activitysecretshopbuynum,"神秘商店"..spenddata[1]["cid"],1)
    else
        print("hundan===net",spenddata[1]["cid"])
        print("num===",gamedata.cache.props[tonumber(spenddata[1]["cid"])].num)
        -- printT(gamedata.cache.props[tonumber(spenddata[1]["cid"])])
        gamedata.cache.props[tonumber(spenddata[1]["cid"])].num = gamedata.cache.props[tonumber(spenddata[1]["cid"])].num-spenddata[1]["num"]*gamedata.ext.activitysecretshopbuynum
        print("num===",gamedata.cache.props[tonumber(spenddata[1]["cid"])].num)
        
    end

    return { type = 3651, reward = gamedata:SomethingProcess(getData)}
end

function UIActivitySecretShopResetCallBack(uireq)
    print("UIActivitySecretShopResetCallBack====")
    -- printT(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3652, "ActivitySecretShop")
    local globalconfig = gamedata.config.global_kv
    local propdata = gamedata.getIDandNUMs(globalconfig.mysteryshop_refreshprop.value) 

    local lingpaiNum = gamedata.getStaffNum(tonumber(propdata[1].cid)).num

    -- gamedata.ext.activitysecretshoplingpai = gamedata.getStaffNum(tonumber(propdata[1].cid)).num
    gamedata.ext.activitysecretshoplingpaispend = uireq.spend

    print("UIActivityBlackShopResetCallBack",globalconfig.mysteryshop_refreshgold.value)

    if gamedata.cache.role.gold < tonumber(globalconfig.mysteryshop_refreshgold.value) and gamedata.ext.activitysecretshoplingpaispend == "gold" then
        return  0, 503, {type = 503, msgtype = "shortgold"}
    else
        return 1, 3652, nil
    end

end

function NetActivitySecretShopResetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3652, "ActivitySecretShop")

    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    gamedata:ActivitySecretShop(ids)

    local globalconfig = gamedata.config.global_kv
    local propdata = gamedata.getIDandNUMs(globalconfig.mysteryshop_refreshprop.value) 
    print("NetActivitySecretShopResetCallBack",globalconfig.mysteryshop_refreshgold.value,gamedata.getStaffNum(tonumber(propdata[1].cid)).num)

    if gamedata.ext.activitysecretshoplingpaispend == "free" then

    elseif gamedata.ext.activitysecretshoplingpaispend == "lingpai" then
        gamedata.cache.props[tonumber(propdata[1].cid)].num = gamedata.cache.props[tonumber(propdata[1].cid)].num - propdata[1].num
    elseif gamedata.ext.activitysecretshoplingpaispend == "gold" then
        gamedata:updateRoleGold(0-globalconfig.mysteryshop_refreshgold.value,"神秘商店刷新",1)
    end 
    
    local onGenerals = makeOnGenerals()
    local generalTab = {} 
    for k,v in pairs(onGenerals) do -- 挑出上阵伙伴cid
        if v.ison == 2 then
            table.insert(generalTab, v.cid)
        end
    end     
    return { type = 3652, 
        data = gamedata.cache.activitySecretShop,
        lingpaiNum = gamedata.getStaffNum(tonumber(propdata[1].cid)).num,
        hundanNum = gamedata.getStaffNum(20200).num,
        onGenerals = generalTab,}
end