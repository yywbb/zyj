--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/1/23
-- Time: 上午10:48
-- To change this template use File | Settings | File Templates.
--

local ids_pb = require("ids_pb")
local result_pb = require("result_pb")
local stringcontent_pb = require("stringcontent_pb")
local somethings_pb = require("somethings_pb")
local invitecode_pb = require("invitecode_pb")


function UIInviteCodeCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2080, "InviteCode")

    return 1, 2080, nil

end

function NetInviteCodeCallback(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2080, "InviteCode")
    if not fd.rbuf or fd.rbuf == "" then
        return { type = 2080 }
    else
        local inventData = invitecode_pb.InviteCode()
        inventData:ParseFromString(fd.rbuf)

        gamedata:Invent(inventData)

        return { type = 2080, invent = gamedata.cache.invent}
    end
end

-------------------------------------------------------------------------------------------------

function UIInviteCodeSetCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2081, "InviteCodeSet")

    local codeData = stringcontent_pb.StringContent()
    codeData.content = uireq.code

    return 1, 2081, codeData:SerializeToString()
end

function NetInviteCodeSetCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2081, "InviteCodeSet")

    local Result = result_pb.Result()
    Result:ParseFromString(fd.rbuf)


    return { type = 2081, result = Result.result}
end

-------------------------------------------------------------------------------------------------

function UIInviteCodeRewardCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 2082, "InviteCodeReward")
    local InviteData = ids_pb.Ids()

    table.insert(InviteData.ids, uireq.id)

    gamedata.ext.InviteDataid =  uireq.id

    return 1, 2082, InviteData:SerializeToString()
end

function NetInviteCodeRewardCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 2082, "InviteCodeReward")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    gamedata.cache.invent.status[gamedata.ext.InviteDataid] = 2

    return { type = 2082,reward = gamedata:SomethingProcess(SomeThings),invent = gamedata.cache.invent}
end