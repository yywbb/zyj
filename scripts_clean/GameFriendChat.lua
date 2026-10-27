--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-10-14
-- Time: 上午10:33
-- To change this template use File | Settings | File Templates.
--
local chats_pb = require("chats_pb")
local friendchatquery_pb = require("friendchatquery_pb")

function UIFriendChatQueryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2305, "FriendChatQuery")
    local friendchat = friendchatquery_pb.FriendChatQuery()
    friendchat.rid = uireq.rid
    friendchat.new = uireq.new

    gamedata.ext.friendchat = {rid = uireq.rid, new = uireq.new }
    return 1, 2305, friendchat:SerializeToString()
end

function NetFriendChatQueryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2305, "FriendChatQuery")
    local ChatsData = chats_pb.Chats()
    ChatsData:ParseFromString(fd.rbuf)

    return {
        type = 2305,
        req = gamedata.ext.friendchat,
        chats = gamedata:chats(ChatsData.chats),
        friend = gamedata.cache.friends.friends[gamedata.ext.friendchat.rid],
        selfRid = gamedata.cache.role.id
    }
end

function UIFriendChatListCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2312, "ChatList")
    return 1, 2312, nil
end

function NetFriendChatListCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2312, "ChatList")
    local tmpPlayer = players_pb.Players()
    tmpPlayer:ParseFromString(fd.rbuf)
    local palyers ={}
    for k,v in ipairs(tmpPlayer.players) do

         table.insert(palyers,gamedata:playerdata(v))
    end
    return { type = 2312,players = palyers}
end

function UIFriendHasChatCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2313, "HasChat")
    return 1, 2313, nil
end

function NetFriendHasChatCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2313, "HasChat")
    local Result = ids_pb.Ids()
    Result:ParseFromString(fd.rbuf)
    return { type = 2313,result = Result.ids[1]}
end

function UIFriendChatCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2306, "FriendChat")
    local chat = chats_pb.Chats()
    local content = chats_pb.Chats.Content()
    content.rid = uireq.rid
    content.content = uireq.content
    table.insert(chat.chats,content)

    return 1, 2306, chat:SerializeToString()
end

function NetFriendChatCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2306, "FriendChat")
    local ChatsData = chats_pb.Chats()
    ChatsData:ParseFromString(fd.rbuf)

    return {
        type = 2306,
        req = {new = 1},
        chats = gamedata:chats(ChatsData.chats),
        selfRid = gamedata.cache.role.id
    }
end