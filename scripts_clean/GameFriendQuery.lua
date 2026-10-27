--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-10-14
-- Time: 上午10:29
-- To change this template use File | Settings | File Templates.
--

function makeFriends()

    local friends = {}
    for k,v in pairs(gamedata.cache.friends.friends) do
        table.insert(friends,v)
    end

    local sortfunc = function(a,b)
        if a.sendgift == 0 and b.sendgift == 1 then
            return true
        elseif a.sendgift == 1 and b.sendgift == 0 then
            return false
        elseif a.recvgift == 1 and b.recvgift == 0 then
            return true
        elseif a.recvgift == 0 and b.recvgift == 1 then
            return false
        elseif a.level > b.level then
            return true
        elseif a.level < b.level then
            return false
        else
            return (a.rid < b.rid)
        end
    end

    --gamedata.sortData(friends, "level","rid")

    table.sort(friends,sortfunc)

    return friends

end

function UIFriendQueryCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2300, "FriendQuery")
    if next(gamedata.cache.friends.friends) and not uireq.param then
        return 0, 2300, { type = uireq.type, friends = makeFriends(),max = gamedata.cache.friends.max }
    else
        return 1, 2300, nil
    end
end

local friends_pb = require("friends_pb")
function NetFriendQueryCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2300, "FriendQuery")
    local friendData = friends_pb.Friends()
    friendData:ParseFromString(fd.rbuf)

    gamedata:Friends(friendData)


    return { type = 2300, friends = makeFriends(),max = gamedata.cache.friends.max }
end