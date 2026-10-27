--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/6/12
-- Time: 18:11
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local params_pb = require("params_pb")
local generals_pb = require("generals_pb")
local somethings_pb = require("somethings_pb")
local combmessages_pb = require("combmessages_pb")

function UIFashionDressQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from UI", 1070, "FashionDressQuery")

    return 1, 1070, nil

    --[[
    local fashion = {}
    fashion.fashions = {}
    fashion.fashionid = 80002
    fashion.show = 1
    --fashion.fashions["80001"] = {id = 80001, level = 7}
    fashion.fashions["80002"] = {id = 80002, level = 15}

    return 0, 1070, {type = 1070, fashion = fashion, protagonist = gamedata.cache.protagonist or {},}
    ]]
end


function NetFashionDressQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from gameserver", 1070, "FashionDressQuery")
    local idsData = ids_pb.Ids()
    idsData:ParseFromString(fd.rbuf)

    local fashion = {}
    fashion.fashions = {}
    fashion.fashionid = idsData.ids[1] or 0
    fashion.show = idsData.ids[2] or 0
    for k = 3,#idsData.ids,2 do
        fashion.fashions[tostring(idsData.ids[k] or 0)] = {id = idsData.ids[k] or 0, level = idsData.ids[k+1] or 1}
    end


    return {type = 1070, fashion = fashion, protagonist = gamedata.cache.protagonist or {},}
end

--
function UIFashionDressHideCallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from UI", 1071, "FashionDressHide")

    return 1, 1071, nil
end

function NetFashionDressHideCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from gameserver", 1071, "FashionDressHide")
    local info = generals_pb.Generals()
    info:ParseFromString(fd.rbuf)
    gamedata:Generals(info.generals)

    return {type= 1071, protagonist = gamedata.cache.protagonist or {},}
end

--
function UIFashionDressStrangeCallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from UI", 1072, "FashionDressStrange")
    if uireq.id then
        local idData = ids_pb.Ids()
        table.insert(idData.ids,uireq.id)
        if uireq.curType then
            table.insert(idData.ids,uireq.curType)
        end
        gamedata.ext.fashion_num = uireq.curType or 1
        gamedata.ext.fashion_up_props =  uireq.xprops or {}
        gamedata.ext.fashion_up_coin =uireq.xcoin or 0

        if gamedata.ext.fashion_up_coin > gamedata.cache.role.coin then
            return 0,503,{type = 503, msgtype = "shortcoin" }
        end

        return 1, 1072, idData:SerializeToString()
    end
end

function NetFashionDressStrangeCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from gameserver", 1072, "FashionDressStrange")
    

    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)
    local itmeNum = 1
    for k,v in ipairs(datas.messages) do
        if v.id == 0 then
            local info = generals_pb.Generals()
            info:ParseFromString(v.data)
            gamedata:Generals(info.generals)
        elseif v.id == 1 then
            local Result = ids_pb.Ids()
            Result:ParseFromString(v.data)
            gamedata.ext.fashion_num = Result.ids[1] or 1
            gamedata.ext.fashion_up_coin = Result.ids[2]
            itmeNum = Result.ids[3]
        end
    end

    if gamedata.ext.fashion_up_coin and gamedata.ext.fashion_up_coin > 0 then
        gamedata:updateRoleCoin(0-gamedata.ext.fashion_up_coin)
    end
    for k,v in pairs(gamedata.ext.fashion_up_props) do
        cclog("NET type:%d cmd:%s recv ", gamedata.ext.fashion_num, "FashionDressStrange11111111")
        gamedata:updateprops({cid = v.cid,num = 0-itmeNum})
    end

    return {type= 1072}
end

--
function UIFashionDressChangeCallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from UI", 1073, "FashionDressChange")
    if uireq.id then
        local idData = ids_pb.Ids()
        table.insert(idData.ids,uireq.id)
        return 1, 1073, idData:SerializeToString()
    end
end

function NetFashionDressChangeCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from gameserver", 1073, "FashionDressChange")
    local info = generals_pb.Generals()
    info:ParseFromString(fd.rbuf)
    gamedata:Generals(info.generals)

    return {type= 1073}
end

-- 时装商店
local function getItemArrayWithLimit(destIds)
    local tmpReturnArray = {}
    -- local tmpVector = gamedata.config.activity_q_exchange

    local tmpVector = gamedata.dailyCpActivityConfig("activity_q_exchange",52)
    printT(tmpVector,"tmpVector===")
    for ak,av in pairs(tmpVector) do
        local i = av.id
        print("destIds===",destIds[i],destIds[i+1])
        local tmpId = tostring(i)
        local tmpLost = destIds[2*i-1]
        local tmpItmes = gamedata.getIDandNUMs(tmpVector[tmpId]["cost"])
        local tmpItme = {
                        -- _IdIndex = tmpId,
                         -- _level = tonumber(tmpVector[tmpId]["troop_lv"]),
                         -- _selfLevel = gamedata.cache.role.level,
                         -- _vip = tonumber(tmpVector[tmpId]["vip_lv"]),
                         -- _selfVip = gamedata.cache.role.vip,
                         _id = av.id,
                         _status = destIds[i*2],
                         _item = tmpItmes,
                         _exchange = {gamedata.getIDandNUM(tmpVector[tmpId]["item"])},
                         _once = tonumber(tmpVector[tmpId]["limit"]) - tmpLost,
                         _max = tonumber(tmpVector[tmpId]["limit"]),
                         _nums = {}}
        for j,v in ipairs(tmpItmes) do
            table.insert(tmpItme._nums,gamedata.getStaffNum(v.cid))
        end
        table.insert(tmpReturnArray,tmpItme)
    end

    local function sortfunc( a,b )
        return a._id < b._id
    end
        
    table.sort(tmpReturnArray,sortfunc)
    -- for i=1,table.getTableLength(tmpVector) do
    --     print("destIds===",destIds[i],destIds[i+1])
    --     local tmpId = tostring(i)
    --     local tmpLost = destIds[2*i-1]
    --     local tmpItmes = gamedata.getIDandNUMs(tmpVector[tmpId]["cost"])
    --     local tmpItme = {
    --                     -- _IdIndex = tmpId,
    --                      -- _level = tonumber(tmpVector[tmpId]["troop_lv"]),
    --                      -- _selfLevel = gamedata.cache.role.level,
    --                      -- _vip = tonumber(tmpVector[tmpId]["vip_lv"]),
    --                      -- _selfVip = gamedata.cache.role.vip,
    --                      _status = destIds[i*2],
    --                      _item = tmpItmes,
    --                      _exchange = {gamedata.getIDandNUM(tmpVector[tmpId]["item"])},
    --                      _once = tonumber(tmpVector[tmpId]["limit"]) - tmpLost,
    --                      _nums = {}}
    --     for j,v in ipairs(tmpItmes) do
    --         table.insert(tmpItme._nums,gamedata.getStaffNum(v.cid))
    --     end
    --     table.insert(tmpReturnArray,tmpItme)
    -- end
    return tmpReturnArray
end
-- 时装商店查询 Q
function UIActivityQShopQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4400, "LimitExchangeQuery")
    -- local tempdata = {1,0,0,0,1,0,0,0,1,0,0,1}
    -- return 0, 4400, {type = 4400, _item = getItemArrayWithLimit(tempdata)}
    return 1, 4400, nil
end

function NetActivityQShopQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4400, "LimitExchangeQuery")
    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)
    -- local tmpFreshTimes = Result.ids[1]
    -- return { type = 4400,_freshTimes = tmpFreshTimes,_item = getItemArrayWithLimit(Result.ids)}

    local showpropid = 20294
    if gamedata.config.activity_time["52"] and gamedata.config.activity_time["52"].param and gamedata.config.activity_time["52"].param > 0 then
        showpropid = gamedata.config.activity_time["52"].param
    end

    local scoredata = gamedata.getStaffNum(showpropid)
    return { type = 4400,_item = getItemArrayWithLimit(Result.ids),scoredata = scoredata}
end

-- 时装商店兑换 Q
function UIActivityQShopRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4401, "QShopReward")
    local FriendReqData = ids_pb.Ids()
    table.insert(FriendReqData.ids, tonumber(uireq._id))
    if uireq._num then
        table.insert(FriendReqData.ids, tonumber(uireq._num))
        gamedata.ext.fashion_num = uireq._num
    end
    gamedata.ext.fashion_shopid = uireq._id

    return 1, 4401, FriendReqData:SerializeToString()

end

function NetActivityQShopRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4401, "QShopReward")
    local UsePorp = combmessages_pb.CombMessages()
    UsePorp:ParseFromString(fd.rbuf)

    local Resultdata = {}
    local SomeThingsdata = {}
    for k,v in ipairs(UsePorp.messages) do
        print("messages===",v.id)
        if v.id == 0 then
            print("messages==in==",v.id)
            Resultdata = ids_pb.Ids()
            Resultdata:ParseFromString(v.data)
        end


        if v.id == 1 then
            print("messages==ni==",v.id)
            -- printT(v.data)
            SomeThingsdata = somethings_pb.SomeThings()
            SomeThingsdata:ParseFromString(v.data)
        end
    end

    if gamedata.ext.fashion_shopid then
        -- local tmpVector = gamedata.config.activity_q_exchange

        local tmpVector = gamedata.dailyCpActivityConfig("activity_q_exchange",52)
        local tmpItmes = gamedata.getIDandNUMs(tmpVector[tostring(gamedata.ext.fashion_shopid)]["cost"])
        for i,v in pairs(tmpItmes) do
            gamedata:updateStaff({cid = v.cid,num = -v.num *(gamedata.ext.fashion_num or 1)})
        end
        gamedata.ext.fashion_shopid = nil
    end

    local reward = gamedata:SomethingProcess(SomeThingsdata)
    
    -- printT(reward,"==reward==")
    -- printT(used,"==used==")
    -- printT(ext,"==ext==")

    local showpropid = 20294
    if gamedata.config.activity_time["52"] and gamedata.config.activity_time["52"].param and gamedata.config.activity_time["52"].param > 0 then
        showpropid = gamedata.config.activity_time["52"].param
    end

    local scoredata = gamedata.getStaffNum(showpropid)
    
    return { type = 4401 ,_item = getItemArrayWithLimit(Resultdata.ids) ,_reward = reward ,scoredata = scoredata}
end


--

local function getItemArrayMidAutumn(destIds)
    local tmpReturnArray = {}
    local tmpVector = gamedata.config.mid_autumn_exchange or {}
    print("destIds num = ",#destIds/2)
    print("tmpVector num = ",#tmpVector)
    for ak,av in pairs(tmpVector) do
        local i = av.id
        local tmpId = tostring(i)
        local tmpLost = destIds[2*i-1]
        local tmpItmes = gamedata.getIDandNUMs(tmpVector[tmpId]["cost"])
        local tmpItme = {
            _id = av.id,
            _status = destIds[i*2],
            _item = tmpItmes,
            _exchange = {gamedata.getIDandNUM(tmpVector[tmpId]["item"])},
            _once = tonumber(tmpVector[tmpId]["limit"]) - tmpLost,
            _max = tonumber(tmpVector[tmpId]["limit"]),
            _nums = {},
            _levelLimit = tmpVector[tmpId]["limit_level"]}
        for j,v in ipairs(tmpItmes) do
            table.insert(tmpItme._nums,gamedata.getStaffNum(v.cid))
        end
        table.insert(tmpReturnArray,tmpItme)
    end

    local function sortfunc( a,b )
        return a._id < b._id
    end

    table.sort(tmpReturnArray,sortfunc)

    return tmpReturnArray
end

local function getItemArrayMidAutumn_x1(destIds)
    local tmpReturnArray = {}
    local tmpVector = gamedata.config.mid_autumn_exchange_1 or {}
    print("destIds num = ",#destIds/2)
    print("tmpVector num = ",#tmpVector)
    for ak,av in pairs(tmpVector) do
        local i = av.id
        local tmpId = tostring(i)
        local tmpLost = destIds[2*i-1]
        local tmpItmes = gamedata.getIDandNUMs(tmpVector[tmpId]["cost"])
        local tmpItme = {
            _id = av.id,
            _status = destIds[i*2],
            _item = tmpItmes,
            _exchange = {gamedata.getIDandNUM(tmpVector[tmpId]["item"])},
            _once = tonumber(tmpVector[tmpId]["limit"]) - tmpLost,
            _max = tonumber(tmpVector[tmpId]["limit"]),
            _nums = {},
            _levelLimit = tmpVector[tmpId]["limit_level"]}
        for j,v in ipairs(tmpItmes) do
            table.insert(tmpItme._nums,gamedata.getStaffNum(v.cid))
        end
        table.insert(tmpReturnArray,tmpItme)
    end

    local function sortfunc( a,b )
        return a._id < b._id
    end

    table.sort(tmpReturnArray,sortfunc)

    return tmpReturnArray
end

function UIMidAutumnShopQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4600, "MidAutumnShopQuery")

    return 1, 4600, nil
end

function NetMidAutumnShopQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4600, "MidAutumnShopQuery")
    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)
    --
    local showpropid = 20360
    if gamedata.config.activity_time["54"] and gamedata.config.activity_time["54"].param and gamedata.config.activity_time["54"].param > 0 then
        showpropid = gamedata.config.activity_time["54"].param
    end
    local scoredata = gamedata.getStaffNum(showpropid)
    return { type = 4600,_item = getItemArrayMidAutumn(Result.ids),scoredata = scoredata}
end


function UIMidAutumnShopRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4601, "MidAutumnShopReward")
    local ReqData = ids_pb.Ids()
    table.insert(ReqData.ids, tonumber(uireq._id))
    if uireq._num then
       table.insert(ReqData.ids, tonumber(uireq._num)) 
       gamedata.ext.midautumn_shopNum = uireq._num
    end
    gamedata.ext.midautumn_shopid = uireq._id

    return 1, 4601, ReqData:SerializeToString()

end

function NetMidAutumnShopRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4601, "MidAutumnShopReward")
    local UsePorp = combmessages_pb.CombMessages()
    UsePorp:ParseFromString(fd.rbuf)

    local Resultdata = {}
    local SomeThingsdata = {}
    for k,v in ipairs(UsePorp.messages) do
        if v.id == 0 then
            Resultdata = ids_pb.Ids()
            Resultdata:ParseFromString(v.data)
        end

        if v.id == 1 then
            SomeThingsdata = somethings_pb.SomeThings()
            SomeThingsdata:ParseFromString(v.data)
        end
    end

    if gamedata.ext.midautumn_shopid then
        local tmpVector = gamedata.config.mid_autumn_exchange
        local tmpItmes = gamedata.getIDandNUMs(tmpVector[tostring(gamedata.ext.midautumn_shopid)]["cost"])
        for i,v in pairs(tmpItmes) do
            gamedata:updateStaff({cid = v.cid,num = -v.num * (gamedata.ext.midautumn_shopNum or 1) })
        end
        gamedata.ext.midautumn_shopid = nil
        gamedata.ext.midautumn_shopNum = nil
    end

    local reward = gamedata:SomethingProcess(SomeThingsdata)

    --
    local showpropid = 20360
    if gamedata.config.activity_time["54"] and gamedata.config.activity_time["54"].param and gamedata.config.activity_time["54"].param > 0 then
        showpropid = gamedata.config.activity_time["54"].param
    end
    local scoredata = gamedata.getStaffNum(showpropid)

    return { type = 4601 ,_item = getItemArrayMidAutumn(Resultdata.ids) ,_reward = reward ,scoredata = scoredata}
end

function UIMidAutumnShopQuery_x1CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4602, "UIMidAutumnShopQuery_x1CallBack")

    return 1, 4602, nil
end

function NetMidAutumnShopQuery_x1CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4602, "NetMidAutumnShopQuery_x1CallBack")
    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)
    --
    local showpropid = 20360
    if gamedata.config.activity_time["208"] and gamedata.config.activity_time["208"].param and gamedata.config.activity_time["208"].param > 0 then
        showpropid = gamedata.config.activity_time["208"].param
    end
    local scoredata = gamedata.getStaffNum(showpropid)
    return { type = 4602,_item = getItemArrayMidAutumn_x1(Result.ids), scoredata = scoredata }
end


function UIMidAutumnShopReward_x1CallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4603, "UIMidAutumnShopReward_x1CallBack")
    local ReqData = ids_pb.Ids()
    table.insert(ReqData.ids, tonumber(uireq._id))
    if uireq._num then
       table.insert(ReqData.ids, tonumber(uireq._num)) 
       gamedata.ext.midautumn_shopNum = uireq._num
    end
    gamedata.ext.midautumn_shopid = uireq._id

    return 1, 4603, ReqData:SerializeToString()

end

function NetMidAutumnShopReward_x1CallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4603, "NetMidAutumnShopReward_x1CallBack")
    local UsePorp = combmessages_pb.CombMessages()
    UsePorp:ParseFromString(fd.rbuf)

    local Resultdata = {}
    local SomeThingsdata = {}
    for k,v in ipairs(UsePorp.messages) do
        if v.id == 0 then
            Resultdata = ids_pb.Ids()
            Resultdata:ParseFromString(v.data)
        end

        if v.id == 1 then
            SomeThingsdata = somethings_pb.SomeThings()
            SomeThingsdata:ParseFromString(v.data)
        end
    end

    if gamedata.ext.midautumn_shopid then
        local tmpVector = gamedata.config.mid_autumn_exchange_1
        local tmpItmes = gamedata.getIDandNUMs(tmpVector[tostring(gamedata.ext.midautumn_shopid)]["cost"])
        for i,v in pairs(tmpItmes) do
            gamedata:updateStaff({cid = v.cid,num = -v.num * (gamedata.ext.midautumn_shopNum or 1) })
        end
        gamedata.ext.midautumn_shopid = nil
        gamedata.ext.midautumn_shopNum = nil
    end

    local reward = gamedata:SomethingProcess(SomeThingsdata)

    --
    local showpropid = 20360
    if gamedata.config.activity_time["208"] and gamedata.config.activity_time["208"].param and gamedata.config.activity_time["208"].param > 0 then
        showpropid = gamedata.config.activity_time["208"].param
    end
    local scoredata = gamedata.getStaffNum(showpropid)

    return { type = 4603 ,_item = getItemArrayMidAutumn_x1(Resultdata.ids) ,_reward = reward ,scoredata = scoredata}
end

--
--
function UIChristmasShopQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4405, "ChristmasShopQuery")

    return 1, 4405, nil
end

function NetChristmasShopQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4405, "ChristmasShopQuery")
    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    local scoredata = gamedata.getStaffNum(20357)
    return { type = 4405,_item = getItemArrayWithLimit(Result.ids),scoredata = scoredata}
end

--
function UIChristmasShopRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 4406, "ChristmasShopReward")
    local FriendReqData = ids_pb.Ids()
    table.insert(FriendReqData.ids, tonumber(uireq._id))
    if uireq._num then
        table.insert(FriendReqData.ids, tonumber(uireq._num))
        gamedata.ext.christmasfashion_num = uireq._num
    end
    gamedata.ext.christmasfashion_shopid = uireq._id

    return 1, 4406, FriendReqData:SerializeToString()

end

function NetChristmasShopRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 4406, "ChristmasShopReward")
    local UsePorp = combmessages_pb.CombMessages()
    UsePorp:ParseFromString(fd.rbuf)

    local Resultdata = {}
    local SomeThingsdata = {}
    for k,v in ipairs(UsePorp.messages) do
        print("messages===",v.id)
        if v.id == 0 then
            print("messages==in==",v.id)
            Resultdata = ids_pb.Ids()
            Resultdata:ParseFromString(v.data)
        end


        if v.id == 1 then
            print("messages==ni==",v.id)
            -- printT(v.data)
            SomeThingsdata = somethings_pb.SomeThings()
            SomeThingsdata:ParseFromString(v.data)
        end
    end

    if gamedata.ext.christmasfashion_shopid then
        -- local tmpVector = gamedata.config.activity_q_exchange
        local tmpVector = gamedata.dailyCpActivityConfig("activity_q_exchange",52)
        local tmpItmes = gamedata.getIDandNUMs(tmpVector[tostring(gamedata.ext.christmasfashion_shopid)]["cost"])
        for i,v in pairs(tmpItmes) do
            gamedata:updateStaff({cid = v.cid,num = -v.num *(gamedata.ext.christmasfashion_num or 1)})
        end
        gamedata.ext.christmasfashion_shopid = nil
    end

    local reward = gamedata:SomethingProcess(SomeThingsdata)

    -- printT(reward,"==reward==")
    -- printT(used,"==used==")
    -- printT(ext,"==ext==")

    local scoredata = gamedata.getStaffNum(20357)

    return { type = 4406 ,_item = getItemArrayWithLimit(Resultdata.ids) ,_reward = reward ,scoredata = scoredata}
end


--


--
-- 时装商店查询
local cpnum = 0
local cpday = 0
function UICPActivityQShopQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5035, "LimitExchangeQuery")

    return 1, 5035, nil
end

function NetCPActivityQShopQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5035, "LimitExchangeQuery")
    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    cpnum = Result.ids[1] or 0
    cpday = Result.ids[2] or 0
    table.remove(Result.ids,2)
    table.remove(Result.ids,1)

    local showpropid = 20294
    if gamedata.config.activity_time["88"] and gamedata.config.activity_time["88"].param and gamedata.config.activity_time["88"].param > 0 then
        showpropid = gamedata.config.activity_time["88"].param
    end

    local scoredata = gamedata.getStaffNum(showpropid)
    return { type = 5035,_item = getItemArrayWithLimit(Result.ids),scoredata = scoredata,cpnum = cpnum,cpday = cpday}
end

-- 时装商店兑换
function UICPActivityQShopRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 5036, "QShopReward")
    local FriendReqData = ids_pb.Ids()
    table.insert(FriendReqData.ids, tonumber(uireq._id))
    if uireq._num then
        table.insert(FriendReqData.ids, tonumber(uireq._num))
        gamedata.ext.fashion_num = uireq._num
    end
    gamedata.ext.fashion_shopid = uireq._id

    return 1, 5036, FriendReqData:SerializeToString()

end

function NetCPActivityQShopRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 5036, "QShopReward")
    local UsePorp = combmessages_pb.CombMessages()
    UsePorp:ParseFromString(fd.rbuf)

    local Resultdata = {}
    local SomeThingsdata = {}
    for k,v in ipairs(UsePorp.messages) do
        print("messages===",v.id)
        if v.id == 0 then
            print("messages==in==",v.id)
            Resultdata = ids_pb.Ids()
            Resultdata:ParseFromString(v.data)
        end


        if v.id == 1 then
            print("messages==ni==",v.id)
            -- printT(v.data)
            SomeThingsdata = somethings_pb.SomeThings()
            SomeThingsdata:ParseFromString(v.data)
        end
    end

    if gamedata.ext.fashion_shopid then
        -- local tmpVector = gamedata.config.activity_q_exchange

        local tmpVector = gamedata.dailyCpActivityConfig("activity_q_exchange",52)
        
        local tmpItmes = gamedata.getIDandNUMs(tmpVector[tostring(gamedata.ext.fashion_shopid)]["cost"])
        for i,v in pairs(tmpItmes) do
            gamedata:updateStaff({cid = v.cid,num = -v.num *(gamedata.ext.fashion_num or 1)})
        end
        gamedata.ext.fashion_shopid = nil
    end

    local reward = gamedata:SomethingProcess(SomeThingsdata)

    -- printT(reward,"==reward==")
    -- printT(used,"==used==")
    -- printT(ext,"==ext==")

    local showpropid = 20294
    if gamedata.config.activity_time["88"] and gamedata.config.activity_time["88"].param and gamedata.config.activity_time["88"].param > 0 then
        showpropid = gamedata.config.activity_time["88"].param
    end

    local scoredata = gamedata.getStaffNum(showpropid)

    return { type = 5036 ,_item = getItemArrayWithLimit(Resultdata.ids) ,_reward = reward ,scoredata = scoredata,cpnum = cpnum,cpday = cpday}
end

--[[武将时装
    [6910] = UIPartnerFashionBuyCallBack,
    [6911] = UIPartnerFashionQueryCallBack,
    [6912] = UIPartnerFashionUseCallBack,
    [6913] = UIPartnerFashionRecoveryCallBack,
    [6914] = UIPartnerFashionHasRecoveryCallBack,
--]]

function UIPartnerFashionBuyCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6910, "PartnerFashionBuyCallBack")

    local doData = ids_pb.Ids()
    local configdata = gamedata.config.partner_fashion_shop[tostring(uireq.id)]
    local spenddata = gamedata.getIDandNUMs(configdata.purchase_price) 

    if tonumber(spenddata[1]["cid"]) == 1001 and gamedata.cache.role.gold < tonumber(spenddata[1]["num"]) then
        print("元宝不足")
        return  0, 503, {type = 503, msgtype = "shortgold"}
    elseif tonumber(spenddata[1]["cid"]) == 20793 and (not gamedata.cache.props[tonumber(spenddata[1]["cid"])] or gamedata.cache.props[tonumber(spenddata[1]["cid"])]["num"] < tonumber(spenddata[1]["num"])) then
        print("道具不足")
        return  0, 503, {type = 503, msg = "道具不足"}
    else
        table.insert(doData.ids,uireq.id)
        gamedata.ext.shizhuangshopbuyid = uireq.id
        return 1, 6910, doData:SerializeToString()
    end
end

function NetPartnerFashionBuyCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6910, "PartnerFashionBuyCallBack")

    local getData = somethings_pb.SomeThings()
    getData:ParseFromString(fd.rbuf)

    local configdata = gamedata.config.partner_fashion_shop[tostring(gamedata.ext.shizhuangshopbuyid)]
    local spenddata = gamedata.getIDandNUMs(configdata.purchase_price) 

    if tonumber(spenddata[1]["cid"]) == 1001 then
        gamedata:updateRoleGold(0-tonumber(spenddata[1]["num"]),"时装商店",1)
    else
        gamedata:updateStaff({cid = spenddata[1]["cid"],num = 0-spenddata[1]["num"]}) 
    end

    return { type = 6910, reward = gamedata:SomethingProcess(getData)}
end


--
function UIPartnerFashionQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from UI", 6911, "UIPartnerFashionQueryCallBack")
    gamedata.ext.PartnerFashionQueryID = uireq.id or 0
    if uireq.id and uireq.id > 0 then
        local idData = ids_pb.Ids()
        table.insert(idData.ids,uireq.id)
        return 1, 6911, idData:SerializeToString()
    else
        return 1, 6911, nil
    end
end

function NetPartnerFashionQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from gameserver", 6911, "UIPartnerFashionQueryCallBack")
    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)
    if gamedata.ext.PartnerFashionQueryID > 0 then
        if not gamedata.cache.partnerfashion then
            gamedata.cache.partnerfashion = {}
        end    
    else    
        gamedata.cache.partnerfashion = {}
    end
    for i = 1,math.floor(#Result.ids/2) do
        if Result.ids[2*i-1] and Result.ids[2*i-1] > 0 then
            gamedata.cache.partnerfashion[tostring(Result.ids[2*i-1])] = {id = Result.ids[2*i-1], time = Result.ids[2*i]}
        end    
    end

    return {type= 6911, partnerfashion = gamedata.cache.partnerfashion or {}, partnerfashionQueryID = gamedata.ext.PartnerFashionQueryID or 0, propnum = gamedata.getStaffNum(20793).num or 0}
end


function UIPartnerFashionUseCallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from UI", 6912, "PartnerFashionUseCallBack")

    local idData = ids_pb.Ids()
    table.insert(idData.ids,uireq.iid)
    table.insert(idData.ids,uireq.id or 0)

    gamedata.ext.PartnerFashionUseIID = uireq.iid or 0

    return 1, 6912, idData:SerializeToString()

end

function NetPartnerFashionUseCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from gameserver", 6912, "PartnerFashionUseCallBack")
    local info = generals_pb.Generals()
    info:ParseFromString(fd.rbuf)
    gamedata:Generals(info.generals)

    local general = gamedata.cache.generals[gamedata.ext.PartnerFashionUseIID]

    return {type= 6912,general = general}
end


function UIPartnerFashionRecoveryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv response from UI", 6913, "PartnerFashionRecoveryCallBack")

    local idData = ids_pb.Ids()
    for k,v in pairs(uireq.cids) do
        table.insert(idData.ids,v)
    end

    return 1, 6913, idData:SerializeToString()

end

function NetPartnerFashionRecoveryCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from gameserver", 6913, "PartnerFashionRecoveryCallBack")
    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)

    return {type= 6913}
end


-- function UIPartnerFashionHasRecoveryCallBack(uireq)
--     cclog("NET type:%d cmd:%s recv response from UI", 6914, "PartnerFashionRecoveryCallBack")

--     return 1, 6914, nil

-- end

function NetPartnerFashionHasRecoveryCallBack(fd)
    cclog("NET type:%d cmd:%s recv request from gameserver", 6914, "PartnerFashionHasRecoveryCallBack")

    local RecoveryIDS = {}
    local generals = {}
    local datas = combmessages_pb.CombMessages()
    datas:ParseFromString(fd.rbuf)
    for k,v in ipairs(datas.messages) do
        if v.id == 1 then
            local info = generals_pb.Generals()
            info:ParseFromString(v.data)
            generals = gamedata:Generals(info.generals,true)
        elseif v.id == 0 then
            local Result = ids_pb.Ids()
            Result:ParseFromString(v.data)
            for k,v in ipairs(Result.ids) do
                table.insert(RecoveryIDS,v)
            end    
        end
    end

    return {type= 6914, ids = RecoveryIDS, generals = generals,}
end

--耐力密码
function UINaiLiCodeRankCallBack(uireq)
    print("request from UI", 8245,"NetNaiLiCodeRank")

    return 1, 8245, nil
end

function NetNaiLiCodeRankCallBack(fd)
    print("request from Net", 8245,"NetNaiLiCodeRank")

    local combmsg = combmessages_pb.CombMessages()
    combmsg:ParseFromString(fd.rbuf)

    local rankData = {}
    local myRank = {}
    for k,v in ipairs(combmsg.messages) do
        if v.id == 1 then
            local params = params_pb.ParamS()
            params:ParseFromString(v.data)
            for i=1,#params.params/3 do
                local data = {}
                data.id = i
                data.rank = params.params[(i-1)*3+1].i or 0
                data.server = params.params[(i-1)*3+2].i or 0
                data.name = params.params[(i-1)*3+2].s or ""
                data.maxpoint = params.params[(i-1)*3+3].i or 0
                table.insert(rankData,data)
            end
            
            local sortfunc = function (a,b)
                return a.id < b.id
            end
            table.sort(rankData,sortfunc)
  
        elseif v.id == 2 then
            local params = params_pb.ParamS()
            params:ParseFromString(v.data)
            myRank.rank = params.params[1].i or 0
            myRank.server = params.params[2].i or 0
            myRank.name = params.params[2].s or ""
            myRank.maxpoint = params.params[3].i or 0
        end
    end

    if next(myRank) then
        for k,v in pairs(rankData) do
            if v.name == gamedata.cache.role.name then
                myRank.rank = v.rank
                myRank.server = v.server
                myRank.name = v.name
                myRank.maxpoint = v.maxpoint
            end
        end
    end

    return { type = 8245, rankData = rankData, myRank = myRank}
end

