-- Append after the three native friend modules; only server replies change caches.
local ids_pb = require("ids_pb")
local friends_pb = require("friends_pb")
local players_pb = require("players_pb")
local comb_pb = require("combmessages_pb")
local result_pb = require("result_pb")
local things_pb = require("somethings_pb")
local chats_pb = require("chats_pb")
local chat_query_pb = require("friendchatquery_pb")
local mutations = {[2302]=true,[2304]=true,[2306]=true,[2308]=true,[2309]=true,
    [2310]=true,[2311]=true,[3003]=true,[3004]=true,[6038]=true}

local function send(opcode,req,raw)
    gamedata.ext.localFriendPending = gamedata.ext.localFriendPending or {}
    if mutations[opcode] and gamedata.ext.localFriendBusy then
        return 0,503,{type=503,msg="好友操作正在结算，请等待回复；超时请重进游戏"}
    end
    local queue=gamedata.ext.localFriendPending[opcode] or {}
    local previous=queue[#queue]
    if previous and previous.rid==req.rid and previous.view==req.view and previous.generation==req.generation
        and previous.new==req.new and previous.offset==req.offset then return 0,opcode,{type=opcode,localSkip=true} end
    table.insert(queue,req)
    gamedata.ext.localFriendPending[opcode] = queue
    if mutations[opcode] then gamedata.ext.localFriendBusy = opcode end
    return 1,opcode,raw
end

local function finish(opcode,reply)
    local pending = gamedata.ext.localFriendPending or {}
    local queue = pending[opcode] or {}
    local req = table.remove(queue,1) or {}
    if #queue==0 then pending[opcode] = nil end
    if gamedata.ext.localFriendBusy == opcode then gamedata.ext.localFriendBusy = nil end
    reply.type,reply.req,reply.view,reply.generation = opcode,req,req.view,req.generation
    reply.rid = req.rid
    return reply
end

local function ids(values)
    local data=ids_pb.Ids()
    values=values or {}
    for index=1,table.getTableLength(values) do table.insert(data.ids,values[index] or values[tostring(index)]) end
    return data:SerializeToString()
end

local function decode(mod,name,raw)
    local data=mod[name]()
    data:ParseFromString(raw)
    return data
end

local function players(data)
    local result={}
    for _,row in ipairs(data.players) do table.insert(result,gamedata:playerdata(row)) end
    return result
end

function UIFriendQueryCallback(req) return send(2300,req,nil) end
function NetFriendQueryCallback(fd)
    local data=decode(friends_pb,"Friends",fd.rbuf)
    gamedata:Friends(data)
    return finish(2300,{friends=makeFriends(),max=gamedata.cache.friends.max,publicRid=data.public_rid})
end
function UIFriendRecommendCallback(req) return send(2301,req,req.fresh and ids({1}) or nil) end
function NetFriendRecommendCallback(fd)
    local result={players={}}
    for _,message in ipairs(decode(comb_pb,"CombMessages",fd.rbuf).messages) do
        if message.id==0 then result.isOnline=decode(ids_pb,"Ids",message.data).ids[1]
        elseif message.id==1 then result.players=players(decode(players_pb,"Players",message.data)) end
    end
    return finish(2301,result)
end
function UIFriendReqQueryCallback(req) return send(2303,req,nil) end
function NetFriendReqQueryCallback(fd) return finish(2303,{players=players(decode(players_pb,"Players",fd.rbuf))}) end
function UIFriendReqCallBack(req) return send(2302,req,ids(req.ids)) end
function NetFriendReqCallBack(fd) return finish(2302,{Result=decode(ids_pb,"Ids",fd.rbuf).ids[1]}) end
function UIFriendRepCallBack(req) return send(2304,req,ids(req.ids)) end
function NetFriendRepCallBack(fd)
    gamedata:Friends(decode(friends_pb,"Friends",fd.rbuf))
    return finish(2304,{})
end
function UIFriendAllReqCallBack(req) return send(2311,req,ids({req.opt or 2})) end
function NetFriendAllReqCallBack(fd)
    gamedata:Friends(decode(friends_pb,"Friends",fd.rbuf))
    return finish(2311,{})
end
function UIFriendAllAddCallback(req) return send(6038,req,nil) end
function NetFriendAllAddCallback(fd) return finish(6038,{stutus=decode(ids_pb,"Ids",fd.rbuf).ids[1]}) end
function UIFriendSearchCallBack(req) return send(2307,req,ids(req.ids)) end
function NetFriendSearchCallBack(fd)
    local rows=players(decode(players_pb,"Players",fd.rbuf))
    return finish(2307,{player=rows[1]})
end
function UIFriendSendGiftCallBack(req) return send(2308,req,ids(req.ids)) end
function NetFriendSendGiftCallBack(fd) return finish(2308,{Result=decode(result_pb,"Result",fd.rbuf).result}) end
function UIFriendRecvGiftCallBack(req) return send(2309,req,ids(req.ids)) end
function NetFriendRecvGiftCallBack(fd)
    local result=finish(2309,{reward=gamedata:SomethingProcess(decode(things_pb,"SomeThings",fd.rbuf))})
    result.receiveids=result.req.ids
    return result
end
function UIFriendDeleteCallBack(req) return send(2310,req,ids(req.ids)) end
function NetFriendDeleteCallBack(fd) return finish(2310,{result=decode(result_pb,"Result",fd.rbuf).result}) end

function UIFriendAllShieldCallBack(req)
    req.offset=req.refresh and 0 or (gamedata.cache.shield.index_now or 0)
    return send(3002,req,ids({req.offset}))
end
function NetFriendAllShieldCallBack(fd)
    local queue=(gamedata.ext.localFriendPending or {})[3002] or {}
    local req=queue[1] or {offset=0}
    if req.offset==0 then gamedata.cache.shield.friends={} end
    for _,message in ipairs(decode(comb_pb,"CombMessages",fd.rbuf).messages) do
        if message.id==0 then gamedata:Shield(decode(ids_pb,"Ids",message.data))
        elseif message.id==1 then
            for _,row in ipairs(players(decode(players_pb,"Players",message.data))) do table.insert(gamedata.cache.shield.friends,row) end
        end
    end
    return finish(3002,{players=gamedata.cache.shield.friends,max=gamedata.cache.shield.max})
end
function UIFriendAddShieldCallBack(req) return send(3003,req,ids(req.ids)) end
function NetFriendAddShieldCallBack(fd) return finish(3003,{result=decode(ids_pb,"Ids",fd.rbuf).ids[1]}) end
function UIFriendDeleteShieldCallBack(req) return send(3004,req,ids(req.ids)) end
function NetFriendDeleteShieldCallBack(fd) return finish(3004,{result=decode(ids_pb,"Ids",fd.rbuf).ids[1]}) end

function UIFriendChatQueryCallback(req)
    local data=chat_query_pb.FriendChatQuery()
    data.rid,data.new=req.rid,req.new or 0
    return send(2305,req,data:SerializeToString())
end
local function chatReply(opcode,fd)
    local result=finish(opcode,{chats=gamedata:chats(decode(chats_pb,"Chats",fd.rbuf).chats),selfRid=gamedata.cache.role.id})
    result.friend=gamedata.cache.friends.friends[result.rid]
    return result
end
function NetFriendChatQueryCallback(fd) return chatReply(2305,fd) end
function UIFriendChatCallback(req)
    local data=chats_pb.Chats()
    local content=chats_pb.Chats.Content()
    content.rid,content.content=req.rid,req.content
    table.insert(data.chats,content)
    return send(2306,req,data:SerializeToString())
end
function NetFriendChatCallback(fd) return chatReply(2306,fd) end
function UIFriendChatListCallback(req) return send(2312,req,nil) end
function NetFriendChatListCallback(fd) return finish(2312,{players=players(decode(players_pb,"Players",fd.rbuf))}) end
function UIFriendHasChatCallback(req) return send(2313,req,nil) end
function NetFriendHasChatCallback(fd) return finish(2313,{result=decode(ids_pb,"Ids",fd.rbuf).ids[1]}) end
