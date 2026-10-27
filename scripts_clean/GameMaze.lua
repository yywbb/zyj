--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/2/29
-- Time: 14:29
-- To change this template use File | Settings | File Templates.
--

require"PickBattleResultReport"

local ids_pb = require("ids_pb")
local battleresult_pb = require("battleresult_pb")
local somethings_pb = require("somethings_pb")

function UIMazeQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3800, "MazeQuery")

    return 1, 3800, nil
end

function NetMazeQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3800, "MazeQuery")
    local mazedata = ids_pb.Ids()
    mazedata:ParseFromString(fd.rbuf)

    gamedata:MazeStatus(mazedata.ids)

    return {type = 3800, maze = gamedata.cache.maze,num =  gamedata.cache.props[20268] and gamedata.cache.props[20268].num or 0}
end


local ids_pb = require("ids_pb")
local somethings_pb = require("somethings_pb")

--迷宫商店查询
function UIMazeShopQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3086, "MazeShopQuery")
    print("UIMazeShopQueryCallBack===")

    return 1, 3806, nil
end

function NetMazeShopQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3086, "MazeShopQuery")
    print("NetMazeShopQueryCallBack===")
    local shopData = ids_pb.Ids()
    shopData:ParseFromString(fd.rbuf)

    gamedata:mazeShop(shopData.ids)


    return { type = 3806, data = gamedata.cache.mazeShop,num = gamedata.cache.props[20268] and gamedata.cache.props[20268].num or 0}
end
--迷宫商店刷新
function UIMazeShopRefreshCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3810, "MazeShopRefresh")
    gamedata.ext.mazeIsNeedGold = 0
    if gamedata.cache.mazeShop.refeshTimes <= 0 then
        gamedata.ext.mazeIsNeedGold = 1
        gamedata:updateRoleGold(-1 * uireq.refreshGold,"迷宫商店购买物品",1)
    end
    return 1, 3810, nil
end

function NetMazeShopRefreshCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3810, "MazeShopRefresh")

    local shopData = ids_pb.Ids()
    shopData:ParseFromString(fd.rbuf)

    gamedata:mazeShop(shopData.ids)

    return { type = 3810, data = gamedata.cache.mazeShop,isNeedGold = gamedata.ext.mazeIsNeedGold ,num = gamedata.cache.props[20268] and gamedata.cache.props[20268].num or 0}
end

--迷宫商店购买
function UIMazeShopBuyCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3807, "MazeShopBuy")
    printT(uireq.usedata)
    if tonumber(uireq.usedata[tostring(1)]) == 20268  then
        local  num = gamedata.cache.props[20268] and gamedata.cache.props[20268].num or 0
        if num  < tonumber(uireq.usedata[tostring(2)])  then
            return 0,503,{type = 503, msg = "材料不足" }
        end
    elseif gamedata.cache.role.gold < tonumber(uireq.usedata[tostring(2)]) then
        return 0,503,{type = 503, msgtype = "shortgold"}
    end
    local buy = ids_pb.Ids()
    buy:ParseFromString(fd.rbuf)
    table.insert(buy.ids,uireq.id)
    gamedata.ext.mazeShopBuyIndex = uireq.id
    gamedata.ext.mazeShopUsedata = uireq.usedata
    return 1, 3807, buy:SerializeToString()  
end

function NetMazeShopBuyCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3807, "MazeShopBuy")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)
    local isUpGold = false
    if tonumber(gamedata.ext.mazeShopUsedata[tostring(1)]) == 20268 then
        if gamedata.cache.props[20268] then
            gamedata.cache.props[20268].num  = gamedata.cache.props[20268].num - tonumber(gamedata.ext.mazeShopUsedata[tostring(2)])
        end        
    else
        gamedata:updateRoleGold(-1 * tonumber(gamedata.ext.mazeShopUsedata[tostring(2)]),"迷宫商店购买物品",1)
        isUpGold = true
    end
    print("?????==="..gamedata.ext.mazeShopBuyIndex)
    printT(gamedata.cache.mazeShop.items)
    gamedata.cache.mazeShop.items[gamedata.ext.mazeShopBuyIndex].buyTimes = gamedata.cache.mazeShop.items[gamedata.ext.mazeShopBuyIndex].buyTimes  + 1
    return { 
        type = 3807, 
        reward = gamedata:SomethingProcess(SomeThings) ,
        data = gamedata.cache.mazeShop ,
        num =  gamedata.cache.props[20268] and gamedata.cache.props[20268].num or 0,
        isUpGold = isUpGold,
    }
end
--迷宫成就奖励查询
function UIMazeTaskQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3808, "MazeTaskQuery")
    
    -- gamedata.cache.mazeReward = {

    --     [1] = {id  =  2,index = 1,state = 1},
    --     [2] = {id  =  3,index = 1,state = 1},
    --     [3] = {id  =  1,index = 2,state = 2},
    --     [4] = {id  =  3,index = 5,state = 0},
    --     [5] = {id  =  4,index = 2,state = 0},
    --     [6] = {id  =  5,index = 1,state = 0},
    -- }
    -- return 0,3808,{ type = 3808, data = gamedata.cache.mazeReward}
    return 1, 3808, nil
end

function NetMazeTaskQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3808, "MazeTaskQuery")
    local shopData = ids_pb.Ids()
    shopData:ParseFromString(fd.rbuf)

    gamedata:mazeReward(shopData.ids)


    return { type = 3808, data = gamedata.cache.mazeReward}
end
--迷宫成就奖励领取
function UIMazeTaskGetRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3809, "MazeTaskGetReward")
    
    local getReward = ids_pb.Ids()
    getReward:ParseFromString(fd.rbuf)
    table.insert(getReward.ids,uireq.index)
    table.insert(getReward.ids,uireq.id)
    gamedata.ext.mazeGetRewardIDAndIndex = {id = uireq.id,index = uireq.index}
  
    return 1, 3809, getReward:SerializeToString()
end

function NetMazeTaskGetRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3809, "MazeTaskGetReward")
    
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    for k,v in pairs(gamedata.cache.mazeReward) do
    	if v.id == gamedata.ext.mazeGetRewardIDAndIndex.id and v.type == gamedata.ext.mazeGetRewardIDAndIndex.index then
    		v.state = 2
    	end
    end
    table.sort(gamedata.cache.mazeReward,function(a,b)
        if a.state == 1 and b.state ~= 1 then
            return true
        elseif  a.state ~= 1 and b.state == 1  then
            return false
        elseif a.state == 0 and b.state == 2 then
            return true
        elseif a.state == 2 and b.state == 0 then
            return false
        elseif a.type > b.type then
            return false
        elseif a.type < b.type then
            return true
        elseif a.id >b.id then
            return false
        else
            return true
        end
    end) 
    return { type = 3809, reward =  gamedata:SomethingProcess(SomeThings),listData = gamedata.cache.mazeReward}
end

--
function UIMazeMoveCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3801, "MazeMove")

    return 1, 3801, nil
end

function NetMazeMoveCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3801, "MazeMove")
    local mazedata = ids_pb.Ids()
    mazedata:ParseFromString(fd.rbuf)

    gamedata:MazeStatus(mazedata.ids)

    return {type = 3801, maze = gamedata.cache.maze, ismove = 1}
end

--
function UIMazeRandomEventCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3802, "MazeRandomEvent")
    local event = ids_pb.Ids()
    table.insert(event.ids,uireq.eventtype)
    table.insert(event.ids,uireq.eventid)

    return 1, 3802, event:SerializeToString()
end

function NetMazeRandomEventCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3802, "MazeRandomEvent")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    return {type = 3802, reward = gamedata:SomethingProcess(SomeThings)}
end

--
function UIMazeBattleCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3803, "MazeBattle")
    local event = ids_pb.Ids()
    table.insert(event.ids,uireq.id)

    return 1, 3803, event:SerializeToString()
end

function NetMazeBattleCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3803, "MazeBattle")
    local battleResultPb = battleresult_pb.BattleResult()
    battleResultPb:ParseFromString(fd.rbuf)

    local result = battleResultPb.result
    local reward = gamedata:SomethingProcess(battleResultPb.reward)
    local battlereport = PickBattleResultReport(battleResultPb)

    return {type = 3803, result = result, reward = reward, battlereport = battlereport }
end

--
function UIMazeResetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3812, "MazeReset")
    gamedata.ext.mazeResetGold = uireq.xgold or 0

    if gamedata.ext.mazeResetGold+0 > gamedata.cache.role.gold then
        return 0,503,{type = 503, msgtype = "shortgold" }
    end

    return 1, 3812, nil
end

function NetMazeResetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3812, "MazeReset")
    local mazedata = ids_pb.Ids()
    mazedata:ParseFromString(fd.rbuf)

    gamedata:MazeStatus(mazedata.ids)

    if gamedata.ext.mazeResetGold and gamedata.ext.mazeResetGold+0 > 0 then
        gamedata:updateRoleGold(0-gamedata.ext.mazeResetGold,"迷宫重置",1)
    end

    return {type = 3812, maze = gamedata.cache.maze}
end