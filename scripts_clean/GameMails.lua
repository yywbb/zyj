--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/24
-- Time: 下午3:15
-- To change this template use File | Settings | File Templates.
--

local mails_pb = require("mails_pb")
local ids_pb = require("ids_pb")
local result_pb = require("result_pb")
local mailsend_pb = require("mailsend_pb")
local somethings_pb = require("somethings_pb")

local function makeMails()
    local mails = {
        system = {},
        battle = {},
        friend = {}
    }

    for k,v in pairs(gamedata.cache.mails) do
        if v.type == 0 then
            table.insert(mails.system,v)
        elseif v.type == 1 then
            table.insert(mails.battle,v)
        elseif v.type == 2 then
            table.insert(mails.friend,v)
        end
    end

    local sortbyid = function(a,b)
        if a.status == b.status then
            return a.second > b.second
        else
            return a.status<b.status
        end

    end

    table.sort(mails.system,sortbyid)
    table.sort(mails.battle,sortbyid)
    table.sort(mails.friend,sortbyid)

    return mails
end


function UIMailListCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3100, "MailList")

    if next(gamedata.cache.mails) and not uireq.update then
        return 0, 3100, {type = 3100, mails = makeMails(),}
    else
        return 1, 3100, nil
    end

end

function NetMailListCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3100, "MailList")
    local mailsData = mails_pb.Mails()
    mailsData:ParseFromString(fd.rbuf)

    gamedata:Mails(mailsData)
    return { type = 3100, mails = makeMails() }
end

----------------------------------------------------------------------

function UIMailReadCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3101, "FriendReq")
    local MailReadData = ids_pb.Ids()
    for k,v in pairs(uireq.ids) do
        table.insert(MailReadData.ids, v)
    end

    gamedata.ext.mailreadid = uireq.ids
    gamedata.ext.mailreadtype = uireq.typename

    return 1, 3101, MailReadData:SerializeToString()
end

function NetMailReadCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3101, "FriendReq")

    local SomeThings = somethings_pb.SomeThings()
    SomeThings:ParseFromString(fd.rbuf)

    for k,v in pairs(gamedata.ext.mailreadid) do
        if v <0 then
            for kk,vv in pairs(gamedata.cache.mails) do
                if v == -1 and vv.type == 0 then
                    gamedata.cache.mails[kk].status = 2
                elseif v == -2 and vv.type == 1 then
                    gamedata.cache.mails[kk].status = 1
                elseif v == -3 and vv.type == 2 then
                    gamedata.cache.mails[kk].status = 1
                end
            end
        else

            if  gamedata.ext.mailreadtype == "system" then
                gamedata.cache.mails[v].status = 2
            elseif  gamedata.ext.mailreadtype == "system" then
                gamedata.cache.mails[v].status = 1
            elseif  gamedata.ext.mailreadtype == "system" then
                gamedata.cache.mails[v].status = 1
            end
        end
    end

    return { type = 3101, mails = makeMails(),reward = gamedata:SomethingProcess(SomeThings)}
end

----------------------------------------------------------------------

function UIMailDeleteCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3102, "MailDelete")
    local MailDeleteData = ids_pb.Ids()
    for k,v in pairs(uireq.ids) do
        table.insert(MailDeleteData.ids, v)
    end

    gamedata.ext.maildeleteid = uireq.ids

    return 1, 3102, MailDeleteData:SerializeToString()
end

function NetMailDeleteCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3102, "MailDelete")

    local Result = result_pb.Result()
    Result:ParseFromString(fd.rbuf)

    for k,v in pairs(gamedata.ext.maildeleteid) do
        if v <0 then
            for kk,vv in pairs(gamedata.cache.mails) do
                if v == -1 and vv.type == 0 then
                    gamedata.cache.mails[kk] = nil
                elseif v == -2 and vv.type == 1 then
                    gamedata.cache.mails[kk] = nil
                elseif v == -3 and vv.type == 2 then
                    gamedata.cache.mails[kk] = nil
                end
            end
        else
            gamedata.cache.mails[v] = nil
        end
    end

    return { type = 3102, mails = makeMails(),}
end

----------------------------------------------------------------------

function UIMailSendCallBack(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 3103, "MailSend")
    local MailSendData = mailsend_pb.MailSend()
    MailSendData.target = uireq.target
    MailSendData.content = uireq.content

    return 1, 3103, MailSendData:SerializeToString()
end

function NetMailSendCallBack(fd)
    cclog("NET type:%d cmd:%s recv response from gameserver", 3103, "MailSend")

    local Result = result_pb.Result()
    Result:ParseFromString(fd.rbuf)

    return { type = 3103, result = Result.result,}
end
