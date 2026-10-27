--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-10-14
-- Time: 上午10:33
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local chats_pb = require("chats_pb")
local chatopt = 0
local gangchatopt = 0
local labaopt = 0

function UIUserChatQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3000, "ChatQuery")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, 0)

    if uireq.opt and uireq.opt == 1 then
        chatopt = 1
        return 1, 3000, idsData:SerializeToString()
    else
        chatopt = 0
        return 1, 3000, nil
    end
end

function NetUserChatQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3000, "ChatQuery")
    local ChatsData = chats_pb.Chats()
    ChatsData:ParseFromString(fd.rbuf)

--    local selfprofile = 0
--    for i = 1,7 do
--        local generalid = gamedata.cache.slots[i].general or 0
--        if generalid > 0 then
--            selfprofile = gamedata.cache.generals[generalid].cid
--            break
--        end
--    end

    local chat_propcid = gamedata.config.global_kv.chat_propcid and tonumber(gamedata.config.global_kv.chat_propcid.value) or 20010
    local propnum = 0
    if gamedata.cache.props[chat_propcid] then
        propnum = gamedata.cache.props[chat_propcid].num or 0
    end

    return {
        type = 3000,
        chats = gamedata:chats(ChatsData.chats),
        players = gamedata:players(ChatsData.players),
        selfdata = {rid = gamedata.cache.role.id,name = gamedata.cache.role.name,level = gamedata.cache.role.level,vip = gamedata.cache.role.vip,profile = gamedata.cache.role.profile, part_point = gamedata.cache.role.part_point, part_rank = gamedata.cache.role.part_rank,title = gamedata.cache.role.title,iconBox = gamedata.cache.role.iconBox},
        opt = chatopt,
        propnum = propnum,
        freenum = gamedata.cache.someids["chat_freenum"] or 0,
    }
end


function UIUserChatCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3001, "Chat")
    local chat = chats_pb.Chats()
    local content = chats_pb.Chats.Content()
    content.rid = gamedata.cache.role.id
    content.content = uireq.content
    table.insert(chat.chats,content)
    labaopt = uireq.labaopt or 0

    return 1, 3001, chat:SerializeToString()
end

function NetUserChatCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3001, "Chat")
    local ChatsData = chats_pb.Chats()
    ChatsData:ParseFromString(fd.rbuf)

--    local selfprofile = 0
--    for i = 1,7 do
--        local generalid = gamedata.cache.slots[i].general or 0
--        if generalid > 0 then
--            selfprofile = gamedata.cache.generals[generalid].cid
--            break
--        end
--    end
    local chat_propcid = gamedata.config.global_kv.chat_propcid and tonumber(gamedata.config.global_kv.chat_propcid.value) or 20010
    if labaopt and labaopt == 1 then
        gamedata:updateprops({cid = chat_propcid, num=-1})
    else
        gamedata:updateChatfreenum(-1)
    end

    local propnum = 0
    if gamedata.cache.props[chat_propcid] then
        propnum = gamedata.cache.props[chat_propcid].num or 0
    end

    return {
        type = 3001,
        chats = gamedata:chats(ChatsData.chats),
        players = gamedata:players(ChatsData.players),
        selfdata = {rid = gamedata.cache.role.id,name = gamedata.cache.role.name,level = gamedata.cache.role.level,vip = gamedata.cache.role.vip,profile = gamedata.cache.role.profile, part_point = gamedata.cache.role.part_point, part_rank = gamedata.cache.role.part_rank,title = gamedata.cache.role.title,iconBox = gamedata.cache.role.iconBox},
        opt = 1,
        propnum = propnum,
        freenum = gamedata.cache.someids["chat_freenum"] or 0,
    }
end

--
function UIUserGangChatQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3010, "ChatQuery")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, 0)
    if uireq.opt and uireq.opt == 1 then
        gangchatopt = 1
        return 1, 3010, idsData:SerializeToString()
    else
        gangchatopt = 0
        return 1, 3010, nil
    end
end

function NetUserGangChatQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3010, "ChatQuery")
    local ChatsData = chats_pb.Chats()
    ChatsData:ParseFromString(fd.rbuf)

--    local selfprofile = 0
--    for i = 1,7 do
--        local generalid = gamedata.cache.slots[i].general or 0
--        if generalid > 0 then
--            selfprofile = gamedata.cache.generals[generalid].cid
--            break
--        end
--    end
    return {
        type = 3010,
        gangid = gamedata.cache.gang2status.id or 0,
        chats = gamedata:chats(ChatsData.chats),
        players = gamedata:players(ChatsData.players),
        selfdata = {rid = gamedata.cache.role.id,name = gamedata.cache.role.name,level = gamedata.cache.role.level,vip = gamedata.cache.role.vip,profile = gamedata.cache.role.profile, part_point = gamedata.cache.role.part_point, part_rank = gamedata.cache.role.part_rank,title = gamedata.cache.role.title,iconBox = gamedata.cache.role.iconBox},
        opt = gangchatopt,
    }
end


function UIUserGangChatCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3011, "Chat")
    local chat = chats_pb.Chats()
    local content = chats_pb.Chats.Content()
    content.rid = gamedata.cache.role.id
    content.content = uireq.content
    table.insert(chat.chats,content)


    return 1, 3011, chat:SerializeToString()
end

function NetUserGangChatCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3011, "Chat")
    local ChatsData = chats_pb.Chats()
    ChatsData:ParseFromString(fd.rbuf)
--
--    local selfprofile = 0
--    for i = 1,7 do
--        local generalid = gamedata.cache.slots[i].general or 0
--        if generalid > 0 then
--            selfprofile = gamedata.cache.generals[generalid].cid
--            break
--        end
--    end

    return {
        type = 3011,
        gangid = gamedata.cache.gang2status.id or 0,
        chats = gamedata:chats(ChatsData.chats),
        players = gamedata:players(ChatsData.players),
        selfdata = {rid = gamedata.cache.role.id,name = gamedata.cache.role.name,level = gamedata.cache.role.level,vip = gamedata.cache.role.vip, profile = gamedata.cache.role.profile, part_point = gamedata.cache.role.part_point, part_rank = gamedata.cache.role.part_rank,title = gamedata.cache.role.title,iconBox = gamedata.cache.role.iconBox},
        opt = 1,
    }
end

function UIUserChatNumResetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3012, "Chat")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.method)

    return 1, 3012, idsData:SerializeToString()
end

function NetUserChatNumResetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3012, "Chat")
    
    return {
        type = 3012
    }
end

--
local broadcastchatopt = 0
function UIBroadcastQueryCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3015, "BroadcastQuery")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, 0)
    if uireq.opt and uireq.opt == 1 then
        broadcastchatopt = 1
        return 1, 3015, idsData:SerializeToString()
    else
        broadcastchatopt = 0
        return 1, 3015, nil
    end
end

function NetBroadcastQueryCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3015, "BroadcastQuery")
    local ChatsData = chats_pb.Chats()
    ChatsData:ParseFromString(fd.rbuf)

    return {
        type = 3015,
        chats = gamedata:chats(ChatsData.chats),
        players = gamedata:players(ChatsData.players),
        selfdata = {rid = gamedata.cache.role.id,name = gamedata.cache.role.name,level = gamedata.cache.role.level,vip = gamedata.cache.role.vip,profile = gamedata.cache.role.profile, part_point = gamedata.cache.role.part_point, part_rank = gamedata.cache.role.part_rank,title = gamedata.cache.role.title,iconBox = gamedata.cache.role.iconBox},
        opt = broadcastchatopt,
    }
end

--
function UIUserCrossChatCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 30001, "CrossChat")

    gamedata:updateprops({cid = uireq.crosslabacid, num = 0-uireq.crosslabause})

    return 0, 30001, {type=30001}
end


function UISendBarrageCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2290, "UISendBarrageCallBack")
    local idsData = ids_pb.Ids()
    table.insert(idsData.ids, uireq.barrageType)
    table.insert(idsData.ids, uireq.talkId)
    if uireq.params then
        for i = 1, table.getTableLength(uireq.params) do
            table.insert(idsData.ids, uireq.params[tostring(i)])
        end
    end
    gamedata.ext.barrageType = uireq.barrageType

    return 1, 2290, idsData:SerializeToString()
end

function NetSendBarrageCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2290, "UISendBarrageCallBack")
    local ChatsData = chats_pb.Chats()
    ChatsData:ParseFromString(fd.rbuf)

    return {
        type = 2290,
        chats = gamedata:chats(ChatsData.chats),
        players = gamedata:players(ChatsData.players),
        barrageType = gamedata.ext.barrageType,
    }
end

function NetBarrageCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2291, "NetBarrageCallBack")
    local ChatsData = chats_pb.Chats()
    ChatsData:ParseFromString(fd.rbuf)

    return {
        type = 2291,
        chats = gamedata:chats(ChatsData.chats),
        players = gamedata:players(ChatsData.players),
        selfdata = {rid = gamedata.cache.role.id,name = gamedata.cache.role.name,level = gamedata.cache.role.level,vip = gamedata.cache.role.vip,profile = gamedata.cache.role.profile, part_point = gamedata.cache.role.part_point, part_rank = gamedata.cache.role.part_rank, profile_k = gamedata.cache.role.profile_k, degree = gamedata.cache.role.degree, government = gamedata.cache.role.government},
    }
end


