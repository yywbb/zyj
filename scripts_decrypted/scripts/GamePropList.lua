--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-18
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--
local idnums_pb = require("idnums_pb")
local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")
--local countdowngifts_pb = require("countdowngifts_pb")

local function makeProps()
    local propsdata = {}
    for k, v in pairs( table.copy(gamedata.cache.props) ) do
        if v.num > 0  then
            local configdata =  gamedata.config.props[tostring(v.cid)]
            if not configdata then
                printT(v,"配置表无此id")
            else
                if configdata.backpack_display and configdata.backpack_display == 1 then
                else
                    v.priority = configdata.priority
                    table.insert(propsdata,v)
                end
            end
            
        end
    end

    gamedata.sortData(propsdata,"priority","quality",nil,nil,nil,nil,true)

    return propsdata
end

function UIPropListCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1200, "propquery")
    if next(gamedata.cache.props) then
        return 0, 1200, { type = uireq.type, props = makeProps(), }
    else
        return 1, 1200, nil
    end
end

function NetPropListCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1200, "propquery")
    local propData = idnums_pb.IdNums()
    propData:ParseFromString(fd.rbuf)

    gamedata:Props(propData.idnums)


    return { type = 1200, props = makeProps()}
end

function UIPropQueryByIdCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 12001, "propqueryBYID")
    local nums = {}
    for k,v in pairs(uireq.cids) do
        local num = 0
        if v == 1000 then
            num = gamedata.cache.role.coin
        elseif v == 1001 then
            num = gamedata.cache.role.gold
        elseif v == 1025 then
            num = gamedata.cache.role.g_gold
        elseif gamedata.IDconfig(v) and gamedata.IDconfig(v).staffType and gamedata.IDconfig(v).staffType == "pet_fragment" then
            num = gamedata.cache.petsfragment[v] and gamedata.cache.petsfragment[v].num or 0
        elseif gamedata.IDconfig(v) and gamedata.IDconfig(v).staffType and gamedata.IDconfig(v).staffType == "equip" then
            if uireq.order and uireq.order == 33090 then
                num = gamedata.getStaffNum(v).num
            else
                num = makeSpendEquipByCid(v)
            end
        elseif gamedata.IDconfig(v) and gamedata.IDconfig(v).staffType and gamedata.IDconfig(v).staffType == "general_fragment" then
            num = gamedata.getStaffNum(v).num
        elseif gamedata.IDconfig(v) and gamedata.IDconfig(v).staffType and gamedata.IDconfig(v).staffType == "red_fragment" then
            num = gamedata.getStaffNum(v).num
        elseif gamedata.IDconfig(v) and gamedata.IDconfig(v).staffType and gamedata.IDconfig(v).staffType == "countdownGift" then
            num = makeCountdownGiftByCid(v)
        elseif gamedata.IDconfig(v) and gamedata.IDconfig(v).staffType and gamedata.IDconfig(v).staffType == "equip_fragment" then
            num = gamedata.getStaffNum(v).num
        elseif gamedata.IDconfig(v) and gamedata.IDconfig(v).staffType and gamedata.IDconfig(v).staffType == "meterial_fragment" then
            num = gamedata.getStaffNum(v).num
        elseif gamedata.IDconfig(v) and gamedata.IDconfig(v).staffType and gamedata.IDconfig(v).staffType == "treasure_fragment" then
            num = gamedata.getStaffNum(v).num
        else
            num = gamedata.cache.props[v] and gamedata.cache.props[v].num or 0
        end
        nums[v] = num
    end

    return 0, 12001, { type = 12001, nums = nums, order = uireq.order }
end

function makeCountdownGiftByCid(cid)
    local num = 0
    for k,v in pairs(gamedata.cache.countdownGift) do
        if tonumber(v.cid) == tonumber(cid) then
            num = num + 1
        end
    end
    return num
end


function UIPropUseCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 1201, "PropUse")
    local propUseData = ids_pb.Ids()

    table.insert(propUseData.ids,uireq.cid)
    table.insert(propUseData.ids,uireq.num)

    if uireq.choose and uireq.choose > 0 then
        table.insert(propUseData.ids,uireq.choose)
    end

    gamedata.ext.propuseid = uireq.cid
    gamedata.ext.propusenum = uireq.num

    return 1, 1201, propUseData:SerializeToString()
end

function NetPropUseCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 1201, "PropUse")
    local propuseData = somethings_pb.SomeThings()
    propuseData:ParseFromString(fd.rbuf)

    --printT(gamedata.cache.props[gamedata.ext.propuseid])

    gamedata:updateprops({cid = gamedata.ext.propuseid, num = -gamedata.ext.propusenum})

    if gamedata.config.props[tostring(gamedata.ext.propuseid)].type == "keybox" then
        gamedata:updateprops({cid = tonumber(gamedata.config.props[tostring(gamedata.ext.propuseid)].param1), num = -gamedata.ext.propusenum})
    end
    print(gamedata.ext.propuseid,gamedata.ext.propusenum)
    --printT(gamedata.cache.props[gamedata.ext.propuseid])

    return { type = 1201, rewards = gamedata:SomethingProcess(propuseData), props = makeProps(),id = gamedata.ext.propuseid,propscachedata = gamedata.cache.props}
end


-----

function UIPropRecoveryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4620, "PropRecovery")
    local propUseData = ids_pb.Ids()

    table.insert(propUseData.ids,uireq.cid)
    table.insert(propUseData.ids,uireq.num or 0)

    gamedata.ext.propRecoveryCid = uireq.cid
    gamedata.ext.propRecoveryNum = uireq.subnum or 0

    return 1, 4620, propUseData:SerializeToString()
end

function NetPropRecoveryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4620, "PropRecovery")
    local propuseData = somethings_pb.SomeThings()
    propuseData:ParseFromString(fd.rbuf)

    if gamedata.ext.propRecoveryCid and gamedata.ext.propRecoveryNum then
        gamedata:updateprops({cid = gamedata.ext.propRecoveryCid, num = 0-gamedata.ext.propRecoveryNum})
    end

    return { type = 4620, rewards = gamedata:SomethingProcess(propuseData)}
end

----


local function makeLimitProps()
    local limitPropsdata = {}

    for k, v in pairs( table.copy(gamedata.cache.countdownGift) ) do
        if v.iid > 0  then
            local configdata =  gamedata.config.props2[tostring(v.cid)]
            v.priority = configdata.priority
            if gamedata.ext["limitTime"..v.iid] then
                if gamedata.cache.countdownGift[v.iid].limitTime > 0 then
                    gamedata.cache.countdownGift[v.iid].limitTime = gamedata.cache.countdownGift[v.iid].limitTime - (gamedata:time() - gamedata.ext["limitTime"..v.iid])
                    if gamedata.cache.countdownGift[v.iid].limitTime <= 0 then
                        gamedata.cache.countdownGift[v.iid].limitTime = 0
                    end
                    v.limitTime = gamedata.cache.countdownGift[v.iid].limitTime
                end
            end

            gamedata.ext["limitTime"..v.iid] = gamedata:time()
            table.insert(limitPropsdata,v)
        end
    end

    gamedata.sortData(limitPropsdata,"priority","boxtype","quality",nil,nil,nil,true)

    return limitPropsdata
end


function UILimitPropListQueryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5901, "LimitPropListQuery")
    if next(gamedata.cache.countdownGift) then
        return 0, 5901, { type = uireq.type, countdownGift = makeLimitProps(), }
    else
        return 1, 5901, nil
    end
end

function NetLimitPropListQueryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5901, "LimitPropListQuery")

    local CountdowngiftsData = countdowngifts_pb.CountDownGifts()
    CountdowngiftsData:ParseFromString(fd.rbuf)
    gamedata:CountdownGift(CountdowngiftsData.countDownGifts)

    return { type = 5901, countdownGift = makeLimitProps()}
end


function UILimitPropUseCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5902, "LimitPropUse")
    local limitPropUseData = ids_pb.Ids()

    table.insert(limitPropUseData.ids,uireq.iid)
    table.insert(limitPropUseData.ids,uireq.cid)

    gamedata.ext.limitPropUseiid = uireq.iid
    gamedata.ext.limitPropUsecid = uireq.cid

    return 1, 5902, limitPropUseData:SerializeToString()
end

function NetLimitPropUseCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5902, "PropUse")
    local limitPropUseData = somethings_pb.SomeThings()
    limitPropUseData:ParseFromString(fd.rbuf)
    gamedata:updateCountdownGift({iid = gamedata.ext.limitPropUseiid,cid = gamedata.ext.limitPropUsecid})

    return { type = 5902, rewards = gamedata:SomethingProcess(limitPropUseData), countdownGift = gamedata.cache.countdownGift, cid = gamedata.ext.limitPropUsecid}

end

function UIPropBuyQueryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 7501, "PropRecovery")
    local idsData = ids_pb.Ids()

    if uireq.canBuy and uireq.canBuy == 0 then
        return 0,7501,{}
    end
    for i = 1, table.getTableLength(uireq.cids) do
        table.insert(idsData.ids, uireq.cids[tostring(i)])
    end
    gamedata.ext.propBuyQuery_cids = uireq.cids or {}

    return 1, 7501, idsData:SerializeToString()
end

function NetPropBuyQueryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 7501, "PropRecovery")
    local ids = ids_pb.Ids()
    ids:ParseFromString(fd.rbuf)

    local t = {}
    local cids = gamedata.ext.propBuyQuery_cids
    for i = 1, # ids.ids do
        t[cids[tostring(i)]] = ids.ids[i]
    end

    gamedata.ext.propBuyQuery_cids = nil

    return { type = 7501, data = t}
end
l'  