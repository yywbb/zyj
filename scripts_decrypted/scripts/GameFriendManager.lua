--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-10-14
-- Time: 上午10:30
-- To change this template use File | Settings | File Templates.
--
local players_pb = require("players_pb")
local ids_pb = require("ids_pb")
local result_pb = require("result_pb")
local friends_pb = require("friends_pb")
local somethings_pb = require("somethings_pb")


function makePlayers(data)
    local palyers ={}
    for k,v in ipairs(data) do

         table.insert(palyers,gamedata:playerdata(v))
    end

    gamedata.sortData(palyers, "level","rid")

    return palyers
end

function makeRecommendPlayers(data)
    local palyers ={}
    for k,v in ipairs(data) do
        table.insert(palyers,gamedata:playerdata(v))
    end

    local sortfunc = function(a,b)
        if (a.param ==1 and b.param == 1) or (a.param ~=1 and b.param ~= 1) then
            if a.level ~= b.level  then
                return a.level >= b.level
            else
                return a.rid >= b.rid
            end
        else
            return b.param == 1
        end

    end
    table.sort(palyers,sortfunc)

    return palyers
end


function UIFriendRecommendCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2301, "FriendRecommend")

    if uireq.fresh then
        local idsData = ids_pb.Ids()
        table.insert(idsData.ids,uireq.fresh)
        return 1, 2301, idsData:SerializeToString()
    else
        return 1, 2301, nil
    end
end

function NetFriendRecommendCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2301, "FriendRecommend")
    local _combmessages = combmessages_pb.CombMessages()
    _combmessages:ParseFromString(fd.rbuf)
    local _isOnline = 0
    local _playersData = players_pb.Players()

    for k,v in ipairs(_combmessages.messages) do
        if v.id == 0 then
            local _ids = ids_pb.Ids()
            _ids:ParseFromString(v.data)
            _isOnline = _ids.ids[1]
        elseif v.id == 1 then
            _playersData:ParseFromString(v.data)
        end
    end
    
    return { type = 2301, isOnline = _isOnline, players = makeRecommendPlayers(_playersData.players) }
end



function UIFriendReqQueryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2303, "FriendReqQuery")

    return 1, 2303, nil
end

function NetFriendReqQueryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2303, "FriendReqQuery")
    local playersData = players_pb.Players()
    playersData:ParseFromString(fd.rbuf)

    return { type = 2303, players = makePlayers(playersData.players) }
end



function UIFriendReqCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2302, "FriendReq")
    local FriendReqData = ids_pb.Ids()
    for k,v in pairs(uireq.ids) do
        table.insert(FriendReqData.ids, v)
    end

    return 1, 2302, FriendReqData:SerializeToString()
end

function NetFriendReqCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2302, "FriendReq")
    local  Result = ids_pb.Ids();
    --local Result = result_pb.Result()
    Result:ParseFromString(fd.rbuf)
    -- return { type = 2302, Result = Result.result,}
    return { type = 2302, Result = Result.ids[1],}
end


function UIFriendRepCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2304, "FriendRep")
    local FriendRepData = ids_pb.Ids()
    for k,v in pairs(uireq.ids) do
        table.insert(FriendRepData.ids, v)
    end

    return 1, 2304, FriendRepData:SerializeToString()
end

function NetFriendRepCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2304, "FriendRep")
    local friendData = friends_pb.Friends()
    friendData:ParseFromString(fd.rbuf)

    --gamedata:Friends(friendData)

    return { type = 2304}--, friends = makeFriends(), max = gamedata.cache.friends.max }
end


function UIFriendSearchCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2307, "FriendSearch")
    local FriendRepData = ids_pb.Ids()
    for k,v in pairs(uireq.ids) do
        table.insert(FriendRepData.ids, v)
    end

    return 1, 2307, FriendRepData:SerializeToString()
end

function NetFriendSearchCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2307, "FriendSearch")
    local playersData = players_pb.Players()
    playersData:ParseFromString(fd.rbuf)
    if next(playersData.players) and playersData.players[1] then
        return { type = 2307, player = gamedata:playerdata(playersData.players[1]) }
    else
        return { type = 2307, player = nil }
    end
end

function UIFriendSendGiftCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2308, "FriendSendGift")
    local FriendRepData = ids_pb.Ids()
    for k,v in pairs(uireq.ids) do
        table.insert(FriendRepData.ids, v)
    end

    gamedata.ext.friendsendgift = uireq.ids

    return 1, 2308, FriendRepData:SerializeToString()
end

function NetFriendSendGiftCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2308, "FriendSendGift")
    local Result = result_pb.Result()
    Result:ParseFromString(fd.rbuf)

    if  Result.result then
        if next(gamedata.ext.friendsendgift) then
            gamedata.cache.friends.friends[gamedata.ext.friendsendgift["1"]].sendgift = 1
        else
            for k, v in pairs(gamedata.cache.friends.friends) do
                v.sendgift = 1
            end
        end
    end

    return { type = 2308, Result = Result.result}
end

function UIFriendRecvGiftCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2309, "FriendSendGift")
    local FriendRepData = ids_pb.Ids()
    for k,v in pairs(uireq.ids) do
        table.insert(FriendRepData.ids, v)
    end
    gamedata.ext.friendrecvgift = uireq.ids

    return 1, 2309, FriendRepData:SerializeToString()
end

function NetFriendRecvGiftCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2309, "FriendSendGift")
    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)


    if next(gamedata.ext.friendrecvgift) then
        gamedata.cache.friends.friends[gamedata.ext.friendrecvgift["1"]].recvgift = 2
        gamedata.cache.friends.max = gamedata.cache.friends.max + 1
    end

    local reward = gamedata:SomethingProcess(SomeThings)

    return { type = 2309, reward = reward,receiveids = gamedata.ext.friendrecvgift}
end


function UIFriendDeleteCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2310, "FriendDelete")
    local FriendRepData = ids_pb.Ids()
    for k,v in pairs(uireq.ids) do
        table.insert(FriendRepData.ids, v)
    end
    gamedata.ext.frienddelegift = uireq.ids

    return 1, 2310, FriendRepData:SerializeToString()
end

function NetFriendDeleteCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2310, "FriendDelete")
    local Result = result_pb.Result()
    Result:ParseFromString(fd.rbuf)

    if Result.result then
        for k, v in pairs(gamedata.ext.frienddelegift) do
            gamedata.cache.friends.friends[v]=nil
        end
    end

    return { type = 2310, result = Result.result}
end

--
function UIFriendAllReqCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2311, "FriendAllReq")
    local FriendReqData = ids_pb.Ids()

    table.insert(FriendReqData.ids, uireq.opt or 2)

    return 1, 2311, FriendReqData:SerializeToString()
end

function NetFriendAllReqCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2311, "FriendAllReq")
    local friendData = friends_pb.Friends()
    friendData:ParseFromString(fd.rbuf)

    --gamedata:Friends(friendData)

    return { type = 2311}--, friends = makeFriends(), max = gamedata.cache.friends.max }
end

function UIFriendAllAddCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 6038, "UIFriendAllAddCallback")

    return 1, 6038, nil
end

function NetFriendAllAddCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 6038, "NetFriendAllAddCallback")
    local _ids = ids_pb.Ids()
    _ids:ParseFromString(fd.rbuf)
    local _stutus = _ids.ids[1]

    return { type = 6038, stutus = _stutus}
end


function UIFriendAllShieldCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3002, "AllShield")
    local tmpTotalNow = gamedata.cache.shield.index_now
    local tmpTotalMax = gamedata.cache.shield.max
    if tmpTotalMax == 0 or tmpTotalNow < tmpTotalMax then
        local FriendRepData = ids_pb.Ids()
        table.insert(FriendRepData.ids, tmpTotalNow)
        return 1, 3002, FriendRepData:SerializeToString()
    else
        return 0, 3002, { type = 3002,players = gamedata.cache.shield.friends,max = gamedata.cache.shield.max}
    end
end

function NetFriendAllShieldCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3002, "AllShield")
    local reps = combmessages_pb.CombMessages()
    reps:ParseFromString(fd.rbuf)
    for k,v in ipairs(reps.messages) do
        if v.id == 0 then
            local tmpShield = ids_pb.Ids()
            tmpShield:ParseFromString(v.data)
            gamedata:Shield(tmpShield)
        elseif v.id == 1 then
            local tmpPlayer = players_pb.Players()
            tmpPlayer:ParseFromString(v.data)
            for i,v in ipairs(tmpPlayer.players) do
                table.insert(gamedata.cache.shield.friends,gamedata:playerdata(v))
            end
        else
        end
    end
    return { type = 3002,players = gamedata.cache.shield.friends,max = gamedata.cache.shield.max}
    -- return { type = 3002,players = makeRecommendPlayers(tmpPlayer.players),max = gamedata.cache.shield.max}
    -- 
end

function UIFriendAddShieldCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3003, "AddShield")
    -- printT(uireq)
    if not gamedata.ext.m_tAddShield then
        gamedata.ext.m_tAddShield = {}
    end
    local tmpError = 1 -- 0为正常，1为是好友，2为已屏蔽玩家
    local FriendShieldData = ids_pb.Ids()
    for k,v in pairs(uireq.ids) do
        if gamedata.ext.m_tAddShield[tostring(v)] then
            tmpError = 2
            break
        else
            if not gamedata.cache.friends.friends[v] then
                tmpError = 0
                gamedata.ext.m_tAddShield[tostring(v)] = v
                table.insert(FriendShieldData.ids, v)
            end
        end
    end
    if tmpError == 0 then
        return 1, 3003, FriendShieldData:SerializeToString()
    elseif tmpError == 1 then
        return 0, 503 , {type = 503, msg = 100014}
    elseif tmpError == 2 then
        return 0, 503 , {type = 503, msg = 100015}
    end
end

function NetFriendAddShieldCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3003, "AddShield")
    print("NetFriendAddShieldCallBack")
    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)
    return {type = 3003,result = Result.ids[1]}
end

function UIFriendDeleteShieldCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3004, "DeleteShield")
    local FriendShieldData = ids_pb.Ids()
    gamedata.ext.m_tDeleteShield = {}
    for k,v in pairs(uireq.ids) do
        table.insert(FriendShieldData.ids, v)
        table.insert(gamedata.ext.m_tDeleteShield, v)
    end

    return 1, 3004, FriendShieldData:SerializeToString()
end

function NetFriendDeleteShieldCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3004, "DeleteShield")
    print("NetFriendDeleteShieldCallBack")
    local  Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)
    if Result.ids[1] == 0 then
        local tmpIds = gamedata.ext.m_tDeleteShield
        for i,v in ipairs(tmpIds) do
            if gamedata.ext.m_tAddShield then
                if gamedata.ext.m_tAddShield[tostring(v)] then
                    gamedata.ext.m_tAddShield[tostring(v)] = nil
                end
            end
            for j,k in ipairs(gamedata.cache.shield.friends) do
                if v == k.rid then
                    gamedata.cache.shield.max = gamedata.cache.shield.max - 1
                    table.remove(gamedata.cache.shield.friends,j)
                    break
                end
            end
        end
    end
    gamedata.ext.m_tDeleteShield = nil
    return { type = 3004, result = Result.ids[1]}
end   50  